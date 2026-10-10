# 04-3 ERC-20 入门：转账、授权与 allowance 的区别

> **本课目标**：不创建代币、不碰真钱。只弄清 ETH 与 ERC-20 的区别，以及为什么钱包里的“授权成功”不等于“付款成功”。

## 先区分 ETH 和 ERC-20

**ETH** 是以太坊网络的原生资产，可以用于支付网络交易费等。

**ERC-20** 是一套常见的代币接口标准。许多代币的余额不是由以太坊原生 ETH 余额字段记录，而是由某个 Token 合约管理。

你可以把它想成：

- ETH：系统原生支持的资产。
- ERC-20：开发者在 Token 合约里按通用接口维护的账本。

因此“把 ETH 转给某地址”和“调用 Token 的 transfer 转代币”，不是同一件操作。

## 从最常见的五个函数学起

| ERC-20 接口 | 白话解释 |
| --- | --- |
| `balanceOf(user)` | 查询 user 的代币余额 |
| `transfer(to, amount)` | 自己把代币转给 to |
| `approve(spender, amount)` | 允许 spender 最多花费自己多少额度 |
| `allowance(owner, spender)` | 查 owner 给 spender 的剩余授权额度 |
| `transferFrom(from, to, amount)` | 被授权者按照规则从 from 转代币给 to |

## 最容易混淆的是 approve 和 transferFrom

假设你有 100 枚某代币，想让一个 DApp 合约替你支付 30 枚。

**第一笔交易：授权**

```text
用户调用 Token.approve(DApp地址, 30)
          ↓
Token 合约记录：DApp 允许从用户余额使用最多 30
          ↓
授权成功，但代币还在用户账户中
```

**第二笔交易：实际花费**

```text
DApp 调用 Token.transferFrom(用户, 收款方, 30)
          ↓
Token 合约验证余额、授权与其他规则
          ↓
符合条件才转账，并按实现更新授权
```

关键区别：**approve 主要修改授权额度，不是把钱立即转给对方**。

## 为什么“无限授权”危险？

一些 DApp 让你授权一个非常大的金额，之后它就可以在授权和余额允许的范围内重复使用代币，而不必每次由你再单独 approve。

如果 DApp 本身恶意、合约被攻击或权限被控制，你暴露的风险可能远大于原计划支付的 30 枚。

所以新手操作真实钱包时必须看清：

- 授权给**哪个合约地址**？
- 授权的是**哪一种 Token**？
- 授权额度是多少？
- 是否有需要时撤销授权的渠道？

## 实际标准还有很多边界

不同代币实现可能存在手续费、非标准返回值、特殊回调或冻结规则。生产工程通常使用经过维护与审阅的库（例如 [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)）并检查目标 Token 的特殊行为，不要把互联网上随便复制的 token 合约当成安全基础。

## 免费练习：只观察，不发送资金

在 Remix 中回顾 [ABI 章节](/02-evm/abi)：

1. 找出 `transfer(address,uint256)` 的函数签名。
2. 用 `cast sig 'transfer(address,uint256)'` 生成 selector。
3. 画一个两笔交易的示意图：“用户 approve → DApp transferFrom”。
4. 自己解释：为什么第一笔成功，并不意味着第二笔一定成功？

<details><summary>参考答案</summary>

第一次成功仅代表授权状态更新。第二次调用时仍可能余额不足、授权额度不够、代币实现拒绝转账、调用者错误或者交易本身失败。
</details>

**本课验收**：能分清 ETH、Token、balance、allowance、approve、transferFrom；懂得不能随意给不认识的 DApp 无限授权。

下一课：[Escrow：把前面学的知识组合成一个完整项目](/05-project/)。