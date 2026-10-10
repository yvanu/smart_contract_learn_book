# 01-3 访问控制、报错与 ETH：为什么前端按钮不算权限

> **本课目标**：用完整可编译的示例理解所有者、modifier、自定义错误和 revert；最后认识 payable 与 wei，暂时不做真实收款程序。

## 一个真实问题：把“管理员按钮”藏起来有用吗？

假设网页只有管理员能看到“暂停服务”。如果后端不检查权限，普通人可以手工构造 HTTP 请求绕过网页。同样，**链上合约必须自己校验权限**：别人可以绕开你的前端直接发交易。

## 第一步：部署一个可以暂停的简单合约

在 Remix 新建 `OwnerSwitch.sol`：

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract OwnerSwitch {
    address public owner;
    bool public paused;

    error Unauthorized();
    error InvalidAddress();

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    function setPaused(bool value) external onlyOwner {
        paused = value;
    }

    function transferOwnership(address next) external onlyOwner {
        if (next == address(0)) revert InvalidAddress();
        owner = next;
    }
}
```

编译后在 Remix VM 部署。这里**没有转账逻辑**，不会真实保管资产。

## 第二步：逐行理解

- `bool paused`：只存 true / false，初始默认 false。
- `error Unauthorized()`：定义“没有权限”的自定义错误。
- `modifier onlyOwner`：把可复用的权限判断封装成修饰器。
- `_;`：表示运行通过 modifier 检查后，在这里执行被修饰函数的主体。
- `setPaused(bool value) external onlyOwner`：函数名后面多了 onlyOwner，意味着调用前要经过这道关卡。
- `address(0)`：全零地址，通常不是应该移交管理权的有效接收地址。
- `transferOwnership`：把 owner 从当前地址改成 next；转移后**原地址不再自动拥有权限**。

类似 Flask 中的：

```python
@require_admin
def set_paused(value):
    settings.paused = value
```

不过链上没有中心服务器替你兜底；若错误地转移管理权，后果可能无法修复。

## 第三步：做三次可观察的实验

1. 用账户 A 部署。读取 `owner()`，确认是 A；读取 `paused()`，确认 false。
2. A 调用 `setPaused(true)`，再读 paused，应为 true。
3. 切到账户 B，尝试 `setPaused(false)`，应 **revert Unauthorized**；再读 paused，仍为 true。
4. 切回 A，调用 `transferOwnership(B 的地址)`；再读 owner，应变成 B。
5. A 现在调用 `setPaused(false)`，应该失败；切到 B，则可以调用成功。

这个实验告诉你：**权限判断取决于合约当前状态和调用者地址，不取决于最开始是谁部署。**

## Solidity 常见的三种失败方式

| 写法 | 白话 | 典型用途 |
| --- | --- | --- |
| `require(condition, "message")` | 条件不满足就失败 | 简单参数、权限检查 |
| `revert SomeError(...)` | 主动以自定义错误失败 | 结构化错误、工程中常见 |
| `assert(condition)` | 程序内部“绝不该错”的性质 | 验证内部不变量，不替代外部参数检查 |

**revert 后，本次调用涉及的链上状态变更会回滚**；如果这是已上链执行的交易，通常仍要承担已使用的 Gas。

## 第四步：第一次认识链上金额

以太坊原生资产叫 ETH。合约常用的最小单位是 **wei**：

```text
1 ETH = 1,000,000,000,000,000,000 wei = 10^18 wei
```

为什么不用浮点数？因为合约金额应该用**可精确表示的整数单位**，避免金额计算产生小数误差。

`payable` 表示某个函数或地址上下文可以接收 ETH。`msg.value` 是**本次调用发送进来的 wei 数量**。这是一个最小示意，**不要单独部署来收款**：

```solidity
// 仅演示关键语法，不是完整合约
function deposit() external payable {
    require(msg.value > 0, "send some ETH");
}
```

这段没有提现路径。如果真写资金合约，必须想清楚谁能提、提多少、失败怎么办、重入怎么办。后面 Escrow 项目才会系统讲。

## 动手复习与新手排错

- 如果 B 调用了管理操作却居然成功：检查是否误把 B 当成部署者，或是否已经转移过所有权。
- 如果转移所有权后 A 失去权限：**这正是预期**，并非 Remix 出错。
- 如果提交交易提示失败：打开 Remix 终端看错误，不要继续点十遍。
- 如果要把权限加给多个管理员：一个 owner 变量不够，需要设计角色集合和最小权限模型。

## 自测

1. 为什么没有 `onlyOwner` 的公开写入函数可能允许任何地址调用？
2. 为什么给 owner 改成零地址需要谨慎？
3. ETH、wei、Gas 三者是同一回事吗？

<details><summary>参考答案</summary>

1. Solidity 不会因为你声明了 owner 就自动拦截其他调用者；权限规则必须写在函数或 modifier 里。
2. 可能永久失去依赖 owner 的管理能力。
3. 不是。ETH 是资产；wei 是 ETH 的最小常用单位；Gas 是执行资源计量。
</details>

**本课验收**：亲手复现账户 B 的 Unauthorized；正确完成所有权转移；能解释 payable 不是“自动安全”。

下一课：[EVM、交易和 Gas 到底如何工作](/02-evm/)。