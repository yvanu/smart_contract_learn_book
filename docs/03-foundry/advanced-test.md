# 03-2 Fuzz、Invariant 与调试

## 单测和属性测试不一样

普通单测把输入定死，例如“付 1 ETH 后余额应该是 1 ETH”。Fuzz 由框架生成大量输入，让测试在各个合法边界检验同一性质。

```solidity
function testFuzz_Increment(uint256 amount) public {
    counter.increase(amount);
    require(counter.count() == amount, "count mismatch");
}
```

这个性质建立在初始计数为零的前提下。不要为逃避失败把所有输入无条件限制到一个毫无风险的范围。

## Invariant（不变量）的思维

对于托管合约，有几个适合抽成不变量的性质：

1. 已释放后的托管状态不可回到等待交付。
2. 已退款后的托管状态不可再次释放。
3. 一份托管资金只能走一次最终结算路径。
4. 未授权者无法触发改变资产归属的状态转移。
5. 余额与资金去向的关系必须能解释，不能凭空消失。

不变量测试通常需要**handler 限制动作模型**，避免测试把不合法前置条件和真正安全漏洞混为一谈。本仓库 v0.1 提供 Fuzz 入口；状态机 invariant handler 列为 v0.2 待完成项。

## 调试流程

```bash
forge test --match-test testRefundAfterDeadline -vvvv
forge test --gas-report
```

拿到失败堆栈，先确认调用身份、状态、余额、区块时间；不要直接修改合约让断言“绿了”。

## 注意测试与部署隔离

`vm.warp`、`vm.prank` 等 cheatcodes 只在本地 Forge 测试 EVM 生效，不是给真实链增加的超级管理员。

**验收：** 运行一个 fuzz 测试，解释它的性质是什么、输入范围是什么、不能覆盖哪些威胁。
