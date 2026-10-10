# 00-2 手把手部署第一个智能合约（Remix）

> **本课目标**：你将在浏览器里亲手创建一个“计数器”：从 0 加到 1，再加到 2。全程使用 Remix 提供的虚拟账户，不需要注册交易所、不需要 MetaMask，也不花真钱。
>
> **预计用时**：初次操作约 30～50 分钟。页面可能随 Remix 更新略有变化，按**功能名称**找按钮即可。

## 这节课最终会看到什么

```text
刚部署：
number = 0

第一次点击 increment：
number = 1

第二次点击 increment：
number = 2
```

它看起来很简单，但会串起五个知识点：**源码 → 编译 → 部署 → 读取状态 → 发送修改交易**。

## 第 1 步：打开 Remix 并认识界面

在浏览器打开 [Remix IDE 官方网站](https://remix.ethereum.org/)。

先不要连接钱包，也不要选主网。如果看到欢迎页面，可关闭引导进入编辑器。

你重点认识三块功能，通常在左侧工具栏：

1. **File Explorer（文件管理器）**：新建和编辑 Solidity 文件。
2. **Solidity Compiler（编译器）**：把 Solidity 源码编译成字节码和 ABI。
3. **Deploy & Run Transactions（部署和运行）**：选择虚拟环境、账户，部署并调用函数。

> 不需要记住图标长什么样。编辑器升级后图标位置可能变化，看英文工具名更可靠。

## 第 2 步：新建 Counter.sol 文件

在 File Explorer 中新建文件，名字**必须包含后缀 `.sol`**：

```text
Counter.sol
```

删除文件里的示例代码，将以下内容**完整复制**进去：

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Counter {
    uint256 public number;

    event Increased(address indexed sender, uint256 current);

    function increment() external {
        number += 1;
        emit Increased(msg.sender, number);
    }
}
```

### 暂时不懂代码？按行理解就行

| 代码 | 白话解释 |
| --- | --- |
| `// SPDX-License-Identifier: MIT` | 告诉工具源码使用什么许可证 |
| `pragma solidity ^0.8.24;` | 要求使用兼容 0.8.24 的 0.8.x 编译器 |
| `contract Counter { ... }` | 声明一个叫 Counter 的合约 |
| `uint256 public number;` | 存一个不能是负数的整数，名称叫 number，初始为 0 |
| `event Increased(...)` | 定义一条“数字增加了”的日志格式 |
| `function increment() external` | 提供一个供外部调用的“加一”函数 |
| `number += 1;` | 把链上存储的数字加 1 |
| `emit Increased(...)` | 执行时发出事件，记录是谁调用和新数字 |
| `msg.sender` | 当前这次调用的直接发起地址 |

`public` 会自动生成一个读数用的 **number()** 函数，**不代表别人可以直接赋值覆盖 number**。

## 第 3 步：编译

1. 点击左侧 **Solidity Compiler**。
2. 选择与 `^0.8.24` 兼容的 0.8.x 编译器（例如 0.8.24；不要选 0.9.x）。
3. 点击 **Compile Counter.sol**（或打开自动编译）。
4. 成功时没有红色编译错误；你应能在编译结果中找到 Counter 合约。

这里的“编译”类似 Python 项目准备运行，但 Solidity 是将源码转换成 EVM 可执行字节码，同时生成 ABI（调用接口说明）。

**常见报错：**

- `Source file requires different compiler version`：编译器不匹配，调整版本。
- `ParserError`：复制时漏了分号、括号或多了奇怪字符，核对整段代码。
- 找不到 Counter：可能编译了其他文件，先在编辑器打开 Counter.sol 再编译。

## 第 4 步：在本地虚拟链部署

1. 点击 **Deploy & Run Transactions**。
2. 在 **Environment** 一栏选择名称包含 **Remix VM** 的虚拟环境。不同版本可能显示为 Remix VM (Cancun / Shanghai 等)。
3. **不要**选择 Injected Provider、连接钱包或任何主网。
4. 观察 **Account**：Remix 为你准备了一组虚拟账户和测试余额。
5. 在 **Contract** 下拉框中选择 **Counter**。
6. 点击 **Deploy**。

如果成功，页面下方的 **Deployed Contracts** 区域会出现类似 `COUNTER AT 0x...` 的可展开条目。这就是**部署出的合约实例**；`0x...` 是它在虚拟链上的地址，不是你的用户账号。

**你刚刚做了什么？** 部署本身也是一次状态改变操作，会执行一笔虚拟交易，在虚拟链中创建合约实例。

## 第 5 步：先“读取”，再“修改”

展开 Deployed Contracts 下的 Counter：

**实验 A：读取**

1. 找到 **number** 按钮（颜色可能因 Remix 版本而不同）。
2. 点击后查看返回值：应该是 `0`。
3. 留意终端/控制台的调用记录：这类读取一般不需要提交链上交易。

**实验 B：修改**

1. 找到 **increment** 按钮并点击一次。
2. Remix 会在虚拟链里执行一次交易。
3. 再点击 **number**，应该看到 `1`。
4. 再点一次 **increment**，再读 number，应该是 `2`。

为什么读取按钮和写入按钮行为不同？因为数字真正存到了合约的链上状态。**读可以本地查询，改就需要执行交易。**

## 第 6 步：学会看交易信息和事件

在 Remix 的终端 / Transactions 记录中找到刚才的 increment：

- **交易哈希（transaction hash）**：这笔交易的标识。
- **from**：调用者的虚拟地址。
- **to**：Counter 合约地址。
- **status**：交易执行成功还是失败。
- **gas used**：此次实际执行使用的 Gas 量。
- **logs / event**：如果 Remix 展示事件，能找到 `Increased` 及 sender、current。

不要死记某个 Gas 数字，因为编译设置和执行环境不同可能有差异。

## 第 7 步：换一个账户再试

在 Deploy & Run 的 Account 下拉框切换到另一个虚拟地址，再点一次 increment。读取 number 应该变成 3。

你会发现：**这个合约并没有限制谁可以点击 increment**。所有调用者都可以把数字加一。下一章我们会加上 owner（所有者）权限，让你亲眼看到没有权限时交易失败。

## 新手故障排查

| 遇到的现象 | 通常是什么原因 | 怎样排查 |
| --- | --- | --- |
| 没有 Deploy 按钮或合约可选 | 还没编译，或编译了别的文件 | 回 Compiler 编译 Counter.sol |
| 部署后 number 不显示 | 没展开 Deployed Contracts | 展开对应 Counter 条目 |
| number 一直为 0 | 点的是读取而不是 increment，或操作了另一个实例 | 先点 increment，再读同一合约实例 |
| 刷新后合约实例不见了 | Remix VM 的工作状态可能已重置 | 重新选择 Remix VM、编译、部署；切勿把 VM 当持久主网 |
| 浏览器提示连接真实钱包 | 误选 Injected Provider | 切回 Remix VM |
| 红色 revert / error | 调用未成功 | 先看终端错误，不要把“按钮点了”当作成功 |

## 挑战题（先做，再看答案）

**任务 1**：把函数改名为 `increaseByTwo`，让它每次加 2。重新编译、重新部署，并验证 0 → 2 → 4。

**任务 2**：想让 number 从 4 变回 0，仅靠当前合约的按钮能做到吗？

<details>
<summary>参考答案</summary>

1. 将函数名改为 `increaseByTwo`，并把 `number += 1` 改为 `number += 2`。重新编译后**重新部署**；旧实例并不会自动换成新代码。
2. 不行。当前合约只提供加一函数，没有 reset 函数；部署者也不能越过合约规则直接修改链上状态。后面的 Solidity 课会添加受 owner 控制的 reset。
</details>

## 进阶：准备本地 Foundry（本课可以先跳过）

如果已经完成 Remix 实验，才需要考虑命令行工具：

- **forge**：编译与测试 Solidity 工程。
- **anvil**：在本机启动一个用于实验的以太坊开发节点。
- **cast**：命令行查询、编码及调用链上数据。

推荐 Linux、macOS 或 Windows 的 WSL2 环境，安装方式以 [Foundry 官方说明](https://getfoundry.sh/introduction/installation/) 为准，不执行不明脚本。

安装完成后在终端逐个验证：

```bash
forge --version
cast --version
anvil --version
```

在**本仓库根目录**下运行：

```bash
cd examples/foundry
forge build
forge test -vv
```

如果提示 `forge: command not found`，说明 Foundry 未安装成功、未加载到 PATH 或终端未重新打开。不要用真实钱包私钥“排查”工具问题。

## 本课验收

做到以下四点再继续：**你亲手完成了部署**；看到了 0 → 1 → 2；找到了调用记录；能解释“读数不用写入交易，加一需要交易”。

- [下一课：把 Flask、数据库和链上程序对应起来](/00-start/backend-map)
- [不认识术语？查词典](/00-start/glossary)
- [遇到 Remix 错误？按现象排查](/00-start/troubleshooting)
- [遇到 Remix 错误？按现象排查](/00-start/troubleshooting)