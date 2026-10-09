# 03-1 Foundry / Forge：测试比“能跑”更重要

## 为什么写 Solidity 必须会测试？

后端服务出错可以回滚部署；上链合约处理资金时，修复可能受到治理、升级策略甚至不可变代码限制。必须在部署前系统性制造失败。

## 本仓库测试工程

```text
examples/foundry/
├── foundry.toml
├── src/
│   ├── Counter.sol
│   └── Escrow.sol
└── test/
    ├── Counter.t.sol
    └── Escrow.t.sol
```

在装好 Foundry 的 Linux、macOS 或 WSL2：

```bash
cd examples/foundry
forge build
forge test -vv
forge test --match-contract EscrowTest -vv
```

Forge 本地执行 Solidity 测试。此项目没有要求部署主网，没有真实钱包参数。

## 最小测试思路

```solidity
function testIncrease() public {
    counter.increase(2);
    require(counter.count() == 2, "wrong count");
}
```

测试合约也是 Solidity。它可以在每次测试开始部署要测的合约，通过 cheatcodes 操控模拟时间、账户和余额。

## 正向测试与反向测试

- 正向：买家付款后、卖家交付、买家确认释放，资金只进入卖家。
- 反向：陌生人调用释放必须 revert；过早申请退款必须 revert。
- 边界：正好截止时间、地址为零、交易资金为 0、重复调用。

## 验收

运行 `forge test -vv`，再故意修改一处断言使测试失败，能解释失败为什么合理。把报错截图与修复记录写进学习日志。

**常见坑：** 测试通过只覆盖写出的用例；漏测“恶意调用者”可能比没有测试更危险。
