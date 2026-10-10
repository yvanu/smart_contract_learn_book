# 03-1 Foundry 从零开始：安装、编译、写第一条测试

> **本课目标**：从“在 Remix 手工点按钮”升级到“在终端运行测试，自动检查正常和异常场景”。只使用本地测试，不连接真实资产。
>
> **先修**：完成 [Solidity 变量、函数与权限](/01-solidity/)；知道 owner、increase、reset 分别在做什么。

## 为什么需要 Foundry？

假设你把合约部署后发现：普通人也能把买家的钱转走。普通后端有时还能暂停服务、回滚部署；资金类智能合约修复往往更加困难。

因此不能只测试“成功按钮能不能点”。还必须测试：**陌生人能不能越权？重复操作会不会错？边界输入能不能造成意外？**

Foundry 是常用的 Solidity 开发工具集：

| 工具 | 负责什么 | 记忆类比 |
| --- | --- | --- |
| `forge` | 编译、运行测试、生成报告 | 类似 pytest + 构建工具 |
| `cast` | 查询、编码和调用链上数据 | 类似 curl + 数据转换工具 |
| `anvil` | 启动本地模拟区块链节点 | 类似本地开发数据库服务 |
| `foundryup` | 安装或更新 Foundry 组件 | 工具链版本管理 |

## 第一步：准备环境

建议 Linux、macOS，或者 Windows 的 **WSL2 Ubuntu**。如果你用 Windows PowerShell，不要直接假设这些 Bash 命令能原样运行；建议先在 WSL2 终端操作。

依照 [Foundry 官方安装文档](https://getfoundry.sh/introduction/installation/) 安装。使用官方渠道并理解下载命令，不要执行来源不明的脚本。

在终端依次检查：

```bash
forge --version
cast --version
anvil --version
```

预期：每个命令都输出版本信息，**不是** `command not found`。如果报找不到命令，确认安装完成、PATH 生效、重新打开终端。

## 第二步：打开配套项目

下载或克隆教程仓库后，从仓库根目录进入：

```bash
cd examples/foundry
```

你应看到：

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

- `src/`：待测试的合约源码。
- `test/`：测试代码，同样使用 Solidity。
- `foundry.toml`：编译器版本、测试设置等配置。
- `*.t.sol`：Foundry 测试文件的常见命名方式。

本仓库 `foundry.toml` 指定了 Solidity 编译器 0.8.26，合约源码中的 `^0.8.24` 与其兼容。首次编译可能需要获取编译器，离线机器需事先准备相应依赖。

## 第三步：编译，并理解“通过”是什么意思

执行：

```bash
forge build
```

预期：构建结束时没有 compiler error，退出状态为 0。编译成功只能证明语法和类型等编译检查通过，**不能证明业务安全**。

再执行：

```bash
forge test -vv
```

你应该看到类似下面的摘要（**仅为输出形式示意，具体数量以实际版本为准**）：

```text
[PASS] testOwnerCanReset()
[PASS] testOtherAccountCannotReset()
[PASS] testFuzz_Increase(uint256) ...
...
Suite result: ok.
```

`PASS` 表示对应测试断言通过；`FAIL` 表示至少一个预期没有满足。测试数量会随代码变化，不能把一张旧截图当当前测试结果。

## 第四步：逐行认识 Counter 的测试代码

打开 `test/Counter.t.sol`，重点观察：

```solidity
function setUp() public {
    counter = new Counter();
}

function testOwnerCanReset() public {
    counter.increase(3);
    require(counter.count() == 3, "wrong increase");
    counter.reset();
    require(counter.count() == 0, "wrong reset");
}
```

逐句解释：

1. `setUp()`：每条测试执行前准备一个新的 Counter 实例。
2. `new Counter()`：在测试 EVM 中部署合约；不是真正的主网部署。
3. `counter.increase(3)`：调用被测合约的函数。
4. `require(counter.count() == 3, ...)`：相当于 Python 测试中的断言。
5. `counter.reset()`：执行重置。
6. 末尾断言：确认重置后是 0。

## 第五步：故意测试“无权操作必须失败”

本仓库还有一个反向用例：

```solidity
function testOtherAccountCannotReset() public {
    vm.expectRevert(Counter.Unauthorized.selector);
    vm.prank(address(0xBEEF));
    counter.reset();
}
```

你必须懂两个特殊功能：

- `vm.prank(address(0xBEEF))`：**在本地测试中**让下一次调用看起来由另一个地址发起。
- `vm.expectRevert(...)`：告诉测试“我预期接下来的调用会以指定错误失败”。

这就像 Flask 单测时模拟另一个登录用户，并断言 API 必须返回拒绝结果。

**注意调用顺序**：先设置“预期失败”，再设置模拟调用者，最后调用被测函数。`vm` 是 Foundry 提供的测试工具，不是生产链上的后门。

## 第六步：故意制造一条失败测试

建议在自己的学习分支中临时把：

```solidity
require(counter.count() == 3, "wrong increase");
```

改成：

```solidity
require(counter.count() == 4, "wrong increase");
```

再运行：

```bash
forge test --match-test testOwnerCanReset -vv
```

预期这条测试变为 **FAIL**，并显示 `wrong increase` 或相关失败信息。然后**把断言改回 3**，再次运行直到通过。

这一步非常重要：你需要亲眼确认测试不是永远“自动绿色”，而是真的能发现错误。

## 命令速查

| 命令 | 作用 |
| --- | --- |
| `forge build` | 编译工程 |
| `forge test -vv` | 跑全量测试并显示适量详细信息 |
| `forge test --match-contract CounterTest -vv` | 只测 Counter 测试合约 |
| `forge test --match-test testOwnerCanReset -vvvv` | 只运行目标用例并输出更详细调用轨迹 |
| `forge test --gas-report` | 查看测试中观察到的 Gas 报告；不是主网费用报价 |

## 新手遇到错误先查什么？

- **找不到 forge**：PATH / 安装问题。
- **找不到 Solidity compiler**：检查网络或离线编译器准备。
- **ParserError**：先核对源码中的括号、分号、引号。
- **测试失败**：看是哪条测试、期望值是什么，再看 `-vvvv` 调用轨迹。
- **不小心在其他目录运行**：核对当前位置是不是 `examples/foundry`。

## 本课验收

能独立运行 build/test，读懂 setUp、require、prank、expectRevert，并能故意制造一次失败再修复。

如果在安装、编译或测试时卡住，先看 [新手排错手册](/00-start/troubleshooting)。

如果在安装、编译或测试时卡住，先看 [新手排错手册](/00-start/troubleshooting)。

下一课：[Fuzz 测试：把一个固定输入变成很多边界输入](/03-foundry/advanced-test)。