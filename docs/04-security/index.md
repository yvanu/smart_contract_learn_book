# 04-1 从一个危险的转账顺序开始理解“重入攻击”

> **本课目标**：不是学黑客技巧，而是理解一个合约为什么会把同一份资金重复支付、怎样用正确的状态更新顺序降低风险。
>
> **安全边界**：下面的危险写法只用于解释漏洞。不要部署到真实网络处理资金。

## 先讲一个普通后端故事

假设你的退款函数做了三件事：

1. 查数据库，发现用户可退 100 元。
2. 先向用户打款。
3. 最后才把数据库里“可退款额”改成 0。

如果第 2 步的外部系统在你更新数据库前**又触发一次退款流程**，会发生什么？系统可能看到额度还是 100 元，于是又转出一笔钱。

**重入（Reentrancy）** 就是智能合约世界里类似的风险：一个合约把控制权交给外部代码时，对方可能在原函数结束之前，再次调用进入你的合约。

## 先理解外部调用为什么危险

合约向另一个合约发送 ETH 时，可能触发对方的 `receive()` 或其他可执行逻辑。对方不是一个被动的银行账户；它也可能是一段有自己判断和回调行为的程序。

看下面的**危险模式片段**：

```solidity
// 反例：不是完整合约，绝不能用于真实资金
uint256 amount = balances[msg.sender];
require(amount > 0, "empty");
(bool ok, ) = payable(msg.sender).call{value: amount}("");
require(ok, "transfer failed");
balances[msg.sender] = 0;
```

按时间顺序看：

```text
A 合约查余额：攻击方可领 100
        ↓
A 先向攻击方合约转账，控制权来到攻击方
        ↓
攻击方在回调里再次调用 A 的提现函数
        ↓
A 看到余额仍是 100（还没清零）
        ↓
可能再次付款
        ↓
最后才执行清零，已经太晚
```

能否真的盗走资产取决于合约其他规则、余额、调用深度等；但这个先交互后修改状态的顺序是典型危险信号。

## 修复思路：CEI 三步法

CEI 是：

- **Checks（检查）**：有钱吗？有权吗？当前状态对吗？
- **Effects（更新内部状态）**：先把可领取余额清零或把订单改成已结束。
- **Interactions（与外部交互）**：最后再向外部账户/合约转账。

示意代码：

```solidity
// 示意片段，省略周边权限和余额管理
uint256 amount = balances[msg.sender];          // Checks
require(amount > 0, "empty");
balances[msg.sender] = 0;                       // Effects
(bool ok, ) = payable(msg.sender).call{value: amount}(""); // Interactions
require(ok, "transfer failed");
```

为什么这么写？回调即使试图再次提现，也会看到余额已为 0，无法重复走同一条领取路径。

“如果转账失败，余额不是已经清零了吗？”——在这段代码中，后面的 `require(ok)` 失败会触发 revert，**同一笔交易里的状态清零也会被回滚**。

## 对照仓库中的真实 Escrow 实现

请打开 `examples/foundry/src/Escrow.sol` 的 `release()`，你会看到：

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

逐句定位：

1. 先查**只有买家能放款**。
2. 先查**只有已交付状态能放款**。
3. 再把状态改为 **Released**。
4. 记录 Released 事件。
5. 最后向 seller 地址转账。
6. 如果转账失败，则整个交易 revert，状态和事件效果都回滚。

## 反向用例：如果卖家根本不愿意收 ETH？

仓库 `test/Escrow.t.sol` 中有一个 `RejectingReceiver`，它的 `receive()` 会故意 revert。测试 `testRejectingSellerDoesNotLoseFunds` 验证：

- 买家确认 release 后，转账失败。
- 托管状态仍保持为 Delivered。
- ETH 没有凭空消失，仍留在托管合约里。

但这暴露出另一个问题：**资金可能一直被卡住，无法完成正常释放**。所以 CEI 可以改善重入风险，却不能单独解决收款失败、争议仲裁等所有问题。

## 还需要知道什么？

重入不仅发生在同一个函数里，也可能跨函数、跨合约或涉及代币回调。生产方案可能还需要独立的提现模式、重入防护、权限审计和完整威胁建模。

**千万不要**以为“加了 CEI 或 ReentrancyGuard 就已经通过安全审计”。

## 实操任务

在本仓库目录执行：

```bash
cd examples/foundry
forge test --match-test testRejectingSellerDoesNotLoseFunds -vvvv
```

找到测试中的三个检查：交易预期失败、状态仍是 Delivered、合约余额仍是 1 ether。

## 自测

1. 为什么“先转账，再把余额清零”很危险？
2. 为什么“先更新状态，转账失败又 revert”不会永久丢掉被修改的状态？
3. 为什么收款方拒收 ETH 属于另一个仍需设计的风险？

**本课验收**：能在实际代码中指出 Checks、Effects、Interactions，能解释 CEI 的作用和局限。

下一课：[威胁建模：不是只防陌生人](/04-security/threat-model)。