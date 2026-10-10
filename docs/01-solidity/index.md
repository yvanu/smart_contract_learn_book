# 01-1 Solidity 基础：变量、函数、权限，逐行学

> **先修**：建议完成 [Remix 入门实验](/00-start/environment)。你应该知道如何新建 `.sol`、编译、部署、点击读取按钮。
>
> **本课成果**：做出一个“任何人都可以加数字，但只有合约所有者可以清零”的计数器，并亲眼复现“无权限调用失败”。

## 把 Solidity 想成“规则很严格的后端语言”

Python 里你可以写 `count = 1`，类型有时会自动推断；Solidity 需要更清楚地声明变量类型。它处理的是**链上公开、执行成本可计量、升级受限**的程序。

先只认识四个词：

- **contract**：合约，像一个可部署的业务模块。
- **state variable**：状态变量，存在链上，类似一条持久的业务记录。
- **function**：函数，别人调用合约的入口。
- **address**：地址类型，标识调用者或合约。

## 第一步：把下面完整代码复制到 Remix

新建 `OwnedCounter.sol`：

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract OwnedCounter {
    address public immutable owner;
    uint256 public count;

    error NotOwner(address caller);

    constructor() {
        owner = msg.sender;
    }

    function increase(uint256 amount) external {
        count += amount;
    }

    function reset() external {
        if (msg.sender != owner) revert NotOwner(msg.sender);
        count = 0;
    }

    function doubled() external view returns (uint256) {
        return count * 2;
    }

    function magicNumber() external pure returns (uint256) {
        return 42;
    }
}
```

选择编译器 0.8.24 或其他兼容的 0.8.x，编译并在 **Remix VM** 中部署。

## 第二步：先理解“变量”

### 为什么 uint256 和 Python 的 int 不一样？

`uint256` 意思是 **0 到 2²⁵⁶−1 的整数**。它不能存负数，也不能直接存小数。

- `uint` 是无符号整数的简写，`uint256` 写得更明确。
- `count` 没有手工赋初值时，默认是 0。
- Solidity 0.8.x 默认检查整数上溢/下溢；非法溢出会失败，而不是随便绕回去。

真实资金计算一般用**最小整数单位**，而不是把 0.1 ETH 作为浮点数保存。稍后再讲 wei。

### owner 是什么，immutable 又是什么？

`address public immutable owner;` 可以拆成四部分：

- `address`：数据类型是一条链上地址。
- `owner`：变量名字。
- `public`：从合约外可以读取它。
- `immutable`：部署时在构造函数中设置，之后不能再修改这个变量。

`constructor()` 是**部署时执行一次**的特殊函数。这里把部署交易的发起者 `msg.sender` 记录为 owner。

这和 Flask 启动时读配置不完全相同：**owner 会随部署的合约实例确定，而不是每次访问网页重新计算。**

## 第三步：理解“函数”

以 `increase` 为例：

```solidity
function increase(uint256 amount) external {
    count += amount;
}
```

逐个读：

1. `function` 表示声明函数。
2. `increase` 是函数名。
3. `uint256 amount` 是传入的非负整数参数。
4. `external` 表示可以从合约外部调用。
5. `count += amount` 会修改链上计数。

**特别注意**：这个 increase 没有检查 owner。换任何虚拟账户，都可以调用。不要以为有一个 owner 变量就自动有权限控制。

对照 Python：

```python
def increase(amount: int):
    global count
    count += amount
```

功能类似，但 Solidity 写入的状态保存在合约的链上上下文中，调用者还需遵守交易规则。

### view 与 pure 有什么区别？

`doubled()` 标了 `view`：**可以读取 count，但不能修改链上状态**。

`magicNumber()` 标了 `pure`：**既不读取，也不修改合约状态**，只是算出 42。

它们经由普通链下读取调用时一般无需发链上交易，不要与“任何时候都零计算成本”混淆。

## 第四步：第一次真正感受“权限”

`reset()` 里这行是核心：

```solidity
if (msg.sender != owner) revert NotOwner(msg.sender);
```

中文逐字解释：

- `msg.sender`：这一次调用的直接调用者。
- `!=`：不等于。
- `owner`：部署时记下的所有者地址。
- `revert`：条件不允许，停止执行并回滚当前调用的链上状态修改。
- `NotOwner`：自定义错误，方便工具展示原因和调用者。

这类似 Flask 的 403，但不是 HTTP 状态码：它由合约执行逻辑产生。

## 第五步：跟着做一个“成功 → 失败 → 成功”实验

保持同一个 Deployed Contracts 下的 OwnedCounter 实例：

| 顺序 | Account 选择 | 操作 | 预期 |
| --- | --- | --- | --- |
| 1 | 账户 A（部署者） | 读 `owner` | 等于 A 地址 |
| 2 | A | `increase(3)` | `count()` 返回 3 |
| 3 | A | 读 `doubled()` | 返回 6 |
| 4 | 切到账户 B | `increase(2)` | count 变 5，说明加数不限 owner |
| 5 | B | `reset()` | **失败/revert**，count 仍为 5 |
| 6 | 切回 A | `reset()` | 成功，count 变 0 |

如果第 5 步没有失败，请先检查是否真的切换了 Account，以及是不是点击了另一个合约实例。**这一步失败恰恰证明权限检查生效。**

## 读完别忘了这四个坑

1. **public ≠ 任何人都能改变量**：public 状态变量会有公开 getter，改动仍由函数规则控制。
2. **private ≠ 加密**：链上值可能被外部观察到。
3. **owner 只是一个地址**：如果对应密钥泄露，别人可能以 owner 身份调用。
4. **部署后不是热更新**：修改源码再次编译，不会自动改变已部署的旧实例。

## 本课挑战与参考答案

**挑战 A**：如何改成“只有 owner 才能 increase”？

**挑战 B**：若普通用户能 increase，是否代表他也能 reset？

<details>
<summary>参考思路</summary>

A：在 increase 的函数体开头增加 `if (msg.sender != owner) revert NotOwner(msg.sender);`，再重新编译、部署并用两个虚拟账户测试。

B：不能。权限是**按具体函数**判断的。increase 没有限制，而 reset 有检查。
</details>

**过关标准**：自己复现了权限失败，能讲清 uint256、owner、constructor、msg.sender、view、pure、revert 的含义。

下一课：[mapping、struct、storage：把 Solidity 当作有代价的持久数据来理解](/01-solidity/storage-events)。