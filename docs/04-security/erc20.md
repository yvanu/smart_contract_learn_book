# 04-3 ERC-20：不要从“自制币”开始学资金合约

ERC-20 定义了可替代代币的常见接口，例如 `balanceOf`、`transfer`、`approve`、`transferFrom`、`allowance`。

## 和原生 ETH 最大的区别

ETH 是链的原生资产；ERC-20 是部署在合约地址的代币账本。给某个合约地址发送 ETH 和调用某个 ERC-20 的 `transfer` 是两回事。

## approve 与 transferFrom

```text
用户先对 Token 调用 approve(spender, allowance)
                          ↓
被授权的 spender 调 Token.transferFrom(user, target, amount)
                          ↓
Token 合约检查授权与余额，成功后更新账本
```

**授权额度（allowance）就是风险边界之一**：不要习惯性给未知 DApp 无限额度。在生产中需要考虑兼容非标准 ERC-20、费用型代币、重入回调、授权竞争条件等问题。

## 项目建议

真正开发 ERC-20 时优先研究并组合维护良好的标准库（例如 [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)），而不是从网上复制不明来源的“代币模板”。

## 动手练习

在区块浏览器查看一个可信的 ERC-20 合约的 ABI：找出 `transfer`、`approve`、`Transfer` 和 `Approval`。记录两种事件是由谁发出的，为什么事件本身不能让余额自动变化。

**验收：** 能解释为什么“授权成功”和“已经转账成功”不是同一件事。
