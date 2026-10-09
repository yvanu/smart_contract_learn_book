# 05-2 Escrow 托管合约：逐步实现

配套完整源码：[`examples/foundry/src/Escrow.sol`](https://github.com/yvanu/smart_contract_learn_book/blob/main/examples/foundry/src/Escrow.sol)。

## 第一步：设计不可变角色与金额

`buyer` 在部署时确定为 `msg.sender`；`seller` 由构造函数传入。构造时附带的 `msg.value` 必须大于 0。合同使用 `immutable` 固定买卖双方、原始金额和截止时间。

与后端差异：这是**链上签名调用者身份**，不能从 HTTP 请求 body 接受任意“buyer ID”。

## 第二步：限制合法状态转换

`State` 定义 `Funded / Delivered / Released / Refunded`。只有卖家能把 Funded 标记为 Delivered；只有买家能在 Delivered 状态确认释放。重复结算必须 revert。

## 第三步：加入截止时间

买家可在 `block.timestamp >= deadline` 时从 Funded 或 Delivered 状态退款。截止时间是业务简化假设，不是现实世界交付证明；真实服务需要争议处理规则。

## 第四步：严格遵守 CEI

```solidity
// 这里是摘录，完整逻辑请看仓库源码
state = State.Released; // Effects：先进入终态
(bool ok, ) = payable(seller).call{value: amount}(""); // Interaction
if (!ok) revert TransferFailed(); // 失败则整笔交易回滚
```

把状态先写成 Released，可以让收款方回调尝试再次放款时无法通过状态检查。

## 第五步：事件和可观测性

`Delivered`、`Released`、`Refunded` 事件帮助前端和链下索引追踪订单。**事件不是权限数据源，也不能替代链上状态**。

## 本地测试

```bash
cd examples/foundry
forge build
forge test -vv
```

## 失败案例

- 非买家确认放款 → `Unauthorized`。
- 非卖家标记交付 → `Unauthorized`。
- 未到期退款 → `TooEarly`。
- 退款后再次放款 → `InvalidState`。
- 将付款地址设为零 → 构造函数拒绝。

## 延伸思考

如果卖家是一个拒绝接收 ETH 的合约会怎样？此简化版释放交易会回滚，钱仍留在合约中。这是**收款地址可用性/拒绝服务**问题；生产级设计需要主动领取模式或替代解决流程。

**验收：** 能解释为什么不能把“发送 ETH”放在改变状态之前；能写出两个失败测试，而不仅是证明正常路径能跑。
