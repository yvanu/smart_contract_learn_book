# 00-3 从 Flask / 数据库迁移到智能合约

## 一个订单例子

假设电商有订单 `PAID -> DELIVERED -> RELEASED`。

在 Flask 里，服务端验证 JWT 和订单归属，再通过 SQL 更新状态。链上没有一个“可信的 Flask 服务器”：**任何人都可以向合约发交易，权限必须由合约自己验证**。

```solidity
modifier onlyBuyer() {
    if (msg.sender != buyer) revert Unauthorized();
    _;
}
```

## 思维迁移的三个关键点

### 1. 状态存储公开、贵、长期

`mapping(address => uint256) balances` 不是数据库索引。无法对 mapping 直接全表扫描获取所有 key，应用一般结合事件和链下索引器查历史。即使变量标记 `private`，也不意味着链上内容对观察者保密。

### 2. 交易可以回滚，但外部世界不会一起回滚

同一笔 EVM 交易的链上状态变更可以原子回滚；链外 webhook、短信、第三方支付不参与这一原子性。这类似微服务 Saga 的难题，而非简单数据库事务。

### 3. 调用者与签名者并不总是同一个概念

`msg.sender` 是**当前调用的直接发起地址**；合约 A 调合约 B，B 中的 `msg.sender` 是 A。切忌用 `tx.origin` 当授权替代品。

## 最低安全原则

- 显式角色：谁可以改状态、谁可以收资金、谁可以暂停？
- 失败即回滚：无权限立即 revert，不做半成功更新。
- 避免向不可信地址进行无限制外部调用。
- 使用 Checks-Effects-Interactions（CEI）组织状态与资金转移，配合实测。
- 事件用来**观测**，不能代替合约状态断言。

## 本课练习

设计三种地址（买家、卖家、陌生人）的权限表，列出 `create / release / refund` 能由谁调用。下一节将其转换为 Solidity 代码。

下一课：[Solidity 变量与类型](/01-solidity/)。
