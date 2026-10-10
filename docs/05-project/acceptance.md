# 05-3 Escrow 测试与验收：逐条验证“做不到的事”

> **本课目标**：不只是把 `forge test` 跑绿，还能解释每条测试在防哪一种错误；整理一份适合作品展示的项目验收记录。

## 第一步：跑通整个项目

在仓库根目录进入 Foundry 示例目录：

```bash
cd examples/foundry
forge build
forge test -vv
```

预期：编译无错误、所有当前用例通过。如果你修改过源码，测试失败就按错误提示排查，不要直接删除断言。

只测托管项目：

```bash
forge test --match-contract EscrowTest -vv
```

打印更多调用轨迹：

```bash
forge test --match-test testDeliverAndRelease -vvvv
```

## 第二步：读懂测试里的三个人

`test/Escrow.t.sol` 中定义了三个用于演示的地址：

```solidity
address internal constant BUYER = address(0xB0B);
address internal constant SELLER = address(0xCAFE);
address internal constant STRANGER = address(0xD00D);
```

这不是三个真实的钱包用户，更不是主网地址；这里只是测试环境里给三种角色的方便标记。

在 `setUp()` 中：

```solidity
vm.deal(BUYER, 10 ether);
vm.prank(BUYER);
escrow = new Escrow{value: 1 ether}(SELLER, block.timestamp + 7 days);
```

逐行读：

1. 给 BUYER 一笔**本地虚拟余额**。
2. 模拟下一次合约调用来自 BUYER。
3. 创建托管实例，并发送 1 个测试 ETH。
4. 截止时间是当前模拟区块时间 + 7 天。

这些操作**不可能凭空给真实主网账户增加余额**。

## 第三步：十种必须验证的情况

| 测试 | 期望 | 对应本仓库用例 |
| --- | --- | --- |
| 01 创建订单并付款 | Funded、合约余额为 1 ether | `testDeployment` |
| 02 卖家交付、买家放款 | Released、卖家收到钱 | `testDeliverAndRelease` |
| 03 陌生人标记交付 | Unauthorized | `testUnauthorizedDelivery` |
| 04 陌生人确认放款 | Unauthorized | `testUnauthorizedRelease` |
| 05 未交付先放款 | InvalidState | `testCannotReleaseBeforeDelivery` |
| 06 到期前要求退款 | TooEarly | `testCannotRefundBeforeDeadline` |
| 07 到期后退款 | Refunded、买家收到钱 | `testRefundAfterDeadline` |
| 08 退款后再放款 | InvalidState | `testCannotReleaseAfterRefund` |
| 09 输入无效卖家/零付款/旧截止时间 | 部署失败 | `testRejectInvalidSeller` 等 |
| 10 卖家拒绝收 ETH | 不丢钱，但释放失败 | `testRejectingSellerDoesNotLoseFunds` |

此外还包含 **`testFuzz_RefundAnyTimeAfterDeadline`**：使用不同的到期后时间测试退款路径。

## 第四步：真正读一次正向测试

```solidity
function testDeliverAndRelease() public {
    vm.prank(SELLER);
    escrow.markDelivered();

    vm.prank(BUYER);
    escrow.release();

    require(escrow.state() == Escrow.State.Released, "not released");
    require(SELLER.balance == 1 ether, "seller not paid");
    require(address(escrow).balance == 0, "escrow not empty");
}
```

这条用例验证了**状态正确、卖家收到资金、托管余额清零**。仅检查 `state == Released` 不够，因为代码也可能在状态变更成功后、转账环节出现问题。

## 第五步：真实安全问题来自反向测试

比如没有权限的人要求退款，预期就应失败，而不是只记录“点了按钮”。

`vm.expectRevert(...)` 让测试要求某操作**按预期失败**；如果危险操作居然执行成功，测试就应该报 FAIL。

再比如资金被拒收的场景：虽然 Escrow 使用了 CEI，卖家却可以是一个故意拒绝收 ETH 的合约。此时钱不会自动消失，但正常释放可能卡住——**证明“不丢钱”和证明“可顺利完成业务”是两种不同验收目标**。

## 第六步：Gas 报告怎么读？

```bash
forge test --gas-report
```

输出显示测试环境中各函数的 Gas 统计，方便比较改动前后的资源消耗。但它**不是你明天在主网执行要支付多少人民币的报价**，实际费用还受网络价格、调用情况和环境影响。

## 做一份可以写进作品集的验收记录

建议自己填表（数字必须来自真实执行）：

| 字段 | 记录 |
| --- | --- |
| 测试环境 | 本地 Foundry，非主网 |
| forge 版本 | 运行 `forge --version` 后填写 |
| Git 提交 | 运行 `git rev-parse --short HEAD` |
| 测试命令 | `forge test -vv` |
| 测试结果 | 自己填写通过/失败数量 |
| 覆盖的重点 | 权限、重复结算、截止边界、拒收 ETH |
| 未覆盖的风险 | 争议仲裁、专业审计、生产流量、真实付款 |

不要把 CI 显示的成功状态当作你自己的学习成果：最好自己执行并解释一条测试。

## 最终挑战：老师问你三句话

**问：为什么不能“发放款交易成功就算业务完成”？**

答：还要确认回执、合约状态和资金去向，并按网络确认规则处理潜在重组和链下记录。

**问：能否将这份代码交给客户管理真钱？**

答：不能。它是教学用最简状态机，没有仲裁、完善的拒收处理、恢复流程或专业审计。

**问：你真正学会了什么？**

答：从业务角色和状态出发编写 Solidity，使用 Foundry 验证正常、越权、边界、重复执行和外部调用失败场景。

**本课验收**：能独立完成编译、全量测试、只运行某条测试、解释不少于 5 条测试的业务含义，并写出剩余风险。

下一课：[完成项目后怎么继续：DApp、链下后端与安全方向](/06-career/)。