# 05-2 Escrow 全部源码拆解：一笔钱怎样锁定、释放与退还

> **本课目标**：将源码分成“确定角色 → 检查状态 → 更新状态 → 转账 → 记录结果”五部分。代码与仓库 `examples/foundry/src/Escrow.sol` 对应。
>
> **重要提醒**：这是教学合约，不包含争议仲裁、退款争议解决、完善的防卡死机制或第三方审计，不可用于真实资产托管。

## 先回忆上一课的业务图

```text
Funded ──卖家交付──> Delivered ──买家确认──> Released
   └────截止退款────> Refunded <────截止退款────┘
```

只记住一条：**资金只能从托管走向其中一个终态**。

## 一、完整代码长什么样？

下面是仓库示例的完整结构（建议同时打开 `src/Escrow.sol` 对照）：

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Escrow {
    enum State { Funded, Delivered, Released, Refunded }

    address public immutable buyer;
    address public immutable seller;
    uint256 public immutable amount;
    uint256 public immutable deadline;
    State public state;

    error Unauthorized();
    error InvalidSeller();
    error InvalidDeposit();
    error InvalidDeadline();
    error InvalidState();
    error TooEarly();
    error DeadlinePassed();
    error TransferFailed();

    event Funded(address indexed buyer, address indexed seller, uint256 amount, uint256 deadline);
    event Delivered(address indexed seller);
    event Released(address indexed seller, uint256 amount);
    event Refunded(address indexed buyer, uint256 amount);

    constructor(address seller_, uint256 deadline_) payable {
        if (seller_ == address(0) || seller_ == msg.sender) revert InvalidSeller();
        if (msg.value == 0) revert InvalidDeposit();
        if (deadline_ <= block.timestamp) revert InvalidDeadline();

        buyer = msg.sender;
        seller = seller_;
        amount = msg.value;
        deadline = deadline_;
        state = State.Funded;
        emit Funded(buyer, seller, amount, deadline);
    }

    function markDelivered() external {
        if (msg.sender != seller) revert Unauthorized();
        if (state != State.Funded) revert InvalidState();
        if (block.timestamp >= deadline) revert DeadlinePassed();

        state = State.Delivered;
        emit Delivered(msg.sender);
    }

    function release() external {
        if (msg.sender != buyer) revert Unauthorized();
        if (state != State.Delivered) revert InvalidState();

        state = State.Released;
        emit Released(seller, amount);
        (bool ok, ) = payable(seller).call{value: amount}("");
        if (!ok) revert TransferFailed();
    }

    function refund() external {
        if (msg.sender != buyer) revert Unauthorized();
        if (state != State.Funded && state != State.Delivered) revert InvalidState();
        if (block.timestamp < deadline) revert TooEarly();

        state = State.Refunded;
        emit Refunded(buyer, amount);
        (bool ok, ) = payable(buyer).call{value: amount}("");
        if (!ok) revert TransferFailed();
    }
}
```

如果你现在觉得代码很长，正常。我们不要求一次背下来，而是依次找“谁”“多少钱”“处于哪一步”。

## 二、先读最上面的变量

```solidity
enum State { Funded, Delivered, Released, Refunded }
address public immutable buyer;
address public immutable seller;
uint256 public immutable amount;
uint256 public immutable deadline;
State public state;
```

- `enum`：枚举，把允许的状态名称列出来。比随意使用 `0、1、2、3` 更容易阅读。
- `buyer`、`seller`：买卖双方地址。
- `amount`：初始托管金额，单位是 wei。
- `deadline`：截止 Unix 时间戳，单位是**秒**。
- `immutable`：部署时设定后不能通过普通函数再改。
- `state`：当前业务状态，后续可以根据规则变化。

为什么买卖双方都是地址而不是姓名？因为合约内部验证签名交易的直接调用者地址，而不是你 Flask 用户表中的名字。

## 三、构造函数：买家付钱才能创建订单

```solidity
constructor(address seller_, uint256 deadline_) payable {
    if (seller_ == address(0) || seller_ == msg.sender) revert InvalidSeller();
    if (msg.value == 0) revert InvalidDeposit();
    if (deadline_ <= block.timestamp) revert InvalidDeadline();

    buyer = msg.sender;
    seller = seller_;
    amount = msg.value;
    deadline = deadline_;
    state = State.Funded;
    emit Funded(buyer, seller, amount, deadline);
}
```

读法：

1. 买家部署合约时传入卖家地址和截止时间。
2. `payable` 允许部署交易附带 ETH。
3. 不允许卖家地址为零，也不允许卖家就是买家。
4. 不允许存款为 0。
5. 截止时间必须在未来。
6. 所有检查通过，记录买家、卖家、金额、截止时间和 Funded 状态。
7. 发出 Funded 事件，帮助外部系统观察订单创建。

### Python 里类似什么？

你可以把它想成“创建订单 API”的入参校验，但部署不是插入 MySQL 一行那么简单，而是在链上创建一个**新的合约实例**。

## 四、markDelivered：卖家如何标记交付

```solidity
function markDelivered() external {
    if (msg.sender != seller) revert Unauthorized();
    if (state != State.Funded) revert InvalidState();
    if (block.timestamp >= deadline) revert DeadlinePassed();

    state = State.Delivered;
    emit Delivered(msg.sender);
}
```

三个问题：

1. **谁能调用？** 只有 seller。
2. **现在是什么状态？** 必须是 Funded。
3. **时间还允许交付吗？** 必须早于 deadline。

然后才把状态改成 Delivered。注意，**卖家点击了“已交付”不等于现实世界已经收货**，这只是代码规则下的一次声明。

## 五、release：买家确认后放款

```solidity
function release() external {
    if (msg.sender != buyer) revert Unauthorized();
    if (state != State.Delivered) revert InvalidState();

    state = State.Released;
    emit Released(seller, amount);
    (bool ok, ) = payable(seller).call{value: amount}("");
    if (!ok) revert TransferFailed();
}
```

这个函数是重入风险的重点：

- **Checks**：调用者必须是买家，当前状态必须是 Delivered。
- **Effects**：先变为 Released。
- **Interactions**：然后把 ETH 发给卖家。

`payable(seller).call{value: amount}("")` 的意思是尝试将 amount wei 发送给卖家地址，并调用接收方可执行的逻辑。

`ok` 表示调用是否成功。如果失败，`revert TransferFailed()` 会回滚这次交易的状态修改和事件效果。

## 六、refund：什么时候可以买家退款

```solidity
function refund() external {
    if (msg.sender != buyer) revert Unauthorized();
    if (state != State.Funded && state != State.Delivered) revert InvalidState();
    if (block.timestamp < deadline) revert TooEarly();

    state = State.Refunded;
    emit Refunded(buyer, amount);
    (bool ok, ) = payable(buyer).call{value: amount}("");
    if (!ok) revert TransferFailed();
}
```

条件拆开：

- 调用者必须是买家。
- 订单还没进入 Released 或 Refunded 终态。
- 当前时间已到 deadline 或更晚。
- 先记为 Refunded，再尝试把钱转回买家。

**特别注意**：合约不会自己在 deadline 那一刻运行。必须由买家或获准的调用方发起交易，才能触发退款。

## 七、怎么自己操作？先推荐用测试

因为 Remix 手工填写截止时间、金额、切换账户容易出错，新手建议先用本仓库的自动化测试把完整流程跑通：

```bash
cd examples/foundry
forge build
forge test --match-test testDeliverAndRelease -vvvv
forge test --match-test testRefundAfterDeadline -vvvv
```

第一条测试模拟：买家投入 1 个虚拟 ETH → 卖家交付 → 买家放款 → 卖家余额增加、托管余额变零。

第二条测试模拟：等待到期（使用本地 `vm.warp`）→ 买家退款 → 状态变 Refunded。

`vm.warp` 只修改**本地测试 EVM**中的模拟区块时间，不是在真实网络“加速时间”。

## 八、什么情况下这段代码仍不够安全？

| 风险 | 当前教程状态 |
| --- | --- |
| 卖家拒绝收款 | 转账失败会回滚，资金可能卡住 |
| 买家已收货仍到期退款 | 规则上可能允许，无法处理现实争议 |
| 一方丢失私钥 | 没有专门的恢复流程 |
| 超大规模订单与索引 | 一实例一订单，未做平台架构 |
| 合约升级/仲裁 | 未实现 |
| 专业安全审计 | 未进行 |

本教材强调：**能够解释风险，比声称一个最小合约“绝对安全”重要得多。**

## 课后挑战

1. 如果卖家在 deadline 之后标记交付，会出现什么错误？
2. 买家先 release，再尝试 refund，会发生什么？
3. 如果卖家收款时故意 revert，Released 状态能留下吗？

<details><summary>参考答案</summary>

1. `DeadlinePassed`。
2. `InvalidState`，因为 Released 已经是终态。
3. 不会；`TransferFailed` revert 会把本次交易的状态变更回滚，但收款过程因此可能卡住。
</details>

**本课验收**：能从源码指出四种状态、三处权限和状态检查、一次 CEI 顺序；能够运行上面的两条测试。

下一课：[对照实际测试逐项验收，找出项目没有覆盖的风险](/05-project/acceptance)。