# 00-2 环境安装与第一个合约

## 路线选择：先 Remix，后 Foundry

Remix 是浏览器中的 Solidity IDE，适合零基础理解账户和部署。Foundry 是本地编译、测试、调试工具链，适合正式工程。

**第一天无需任何真实 ETH，也不要连接主网钱包。**

### A. 先在 Remix 完成第一课

1. 打开 [Remix IDE](https://remix.ethereum.org/)。
2. 新建 `Counter.sol`，复制下方合约。
3. 编译器选与 pragma 兼容的稳定 0.8.x 版本（可用该页面默认的稳定编译器）。
4. 在 Deploy & Run 页签选择 `Remix VM`，点击 Deploy。
5. 调用 `number()`，再调用 `increment()`，观察值变化；对比交易记录。

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

注意：`public` 状态变量自动生成 getter，不等于任何人能改写变量。

### B. 安装 Foundry（推荐 Linux / macOS / WSL2）

参考 [Foundry 官方安装说明](https://getfoundry.sh/introduction/installation/)。遵循官方指令安装 foundryup，再运行：

```bash
foundryup
forge --version
cast --version
anvil --version
```

初学者不要执行陌生脚本，也不要把生产钱包私钥传给 `cast` 或教程命令。

### C. 运行本仓库示例

```bash
cd examples/foundry
forge build
forge test -vv
```

本教程的示例默认不依赖 OpenZeppelin 或其他 Git 子模块，便于最小化学习。

## 验收

- `forge build` 退出码为 0。
- `forge test -vv` 所有测试通过。
- 会看 `src/`、`test/`、`foundry.toml` 的作用。

**常见坑：** Windows PowerShell 没有安装 Foundry 的原生工具链时，优先使用 WSL2，不要为了跑命令把私钥复制进不可信环境。
