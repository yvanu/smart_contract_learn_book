# 04-1 重入风险与 CEI

## 先理解危险模型

合约调用外部合约时，控制权可能转交给不可信代码。如果原合约还没有先更新余额或状态，对方就可能在回调中再次进入相同函数。

### 容易出问题的顺序

```solidity
// 仅用于说明危险模式：不要部署用于管理资产
(bool ok, ) = payable(msg.sender).call{value: amount}("");
require(ok);
balances[msg.sender] = 0; // 太晚更新状态
```

这里外部 `call` 发生在余额清零之前，风险取决于其余权限和调用路径。

### 更合理的顺序：Checks → Effects → Interactions

```solidity
uint256 amount = balances[msg.sender];
require(amount > 0, "empty");
balances[msg.sender] = 0; // 先更新状态
(bool ok, ) = payable(msg.sender).call{value: amount}("");
require(ok, "transfer failed");
```

即使转账失败，`revert` 也会把本次交易的余额修改回滚。

## CEI 不是灵丹妙药

跨函数重入、复杂代币回调、共享状态、被恶意治理修改的依赖仍可能引入风险。可根据威胁模型评估 `ReentrancyGuard`，但不能把加一个 modifier 当成审计结束。

## 练习与验收

阅读 [Escrow 实战](/05-project/escrow) 的 `release()`：从上到下指出 Checks、Effects、Interactions；再找出攻击者能控制的地址。

**安全声明：** 教材示例没有接受专业安全审计，不允许处理真实资产。
