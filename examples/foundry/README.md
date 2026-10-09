# Foundry 本地练习项目

仅用于本地 EVM / 教育用途。**未经审计，禁止用于真实资金**。

## 运行

安装 Foundry 并保证可以运行 Solidity 0.8.26 编译器：

```bash
forge build
forge test -vv
forge test --match-contract EscrowTest -vvvv
```

示例不依赖 forge-std；测试文件内声明了用到的最少 cheatcode 接口。首次运行可能需要下载编译器，需要互联网环境。

## 内容

- `Counter.sol`: 账户所有权、计数和事件
- `Escrow.sol`: 买家付款、卖家标记、买家放款、到期退款
- `Counter.t.sol`: 正反向测试、模糊测试
- `Escrow.t.sol`: 角色、状态、时间、资金转移和恶意接收地址的失败案例

## 局限

学习合约不能处理真实订单：缺少仲裁、交付证明、替代收款流程和专业安全审计。
