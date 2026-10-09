# 01-1 Solidity 变量、函数与类型

## 学习目标

看懂一个最小合约，并能解释状态变量、局部变量、可见性、构造函数和基本类型。

## 一个更严格的 Counter

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

## 逐个解释

- `address`：以太坊地址类型；不是邮箱/用户名。
- `uint256`：无符号 256 位整数，没有浮点数；大多数业务金额以最小单位整数表示。
- `immutable`：构造函数期间设置，部署后不可修改，但不等于“保密”。
- `external`：为从合约外调用设计的函数可见性。
- `view`：不修改链上状态；`pure`：不读取也不修改合约状态。
- `constructor`：部署时运行一次。
- `revert`：条件不满足时回滚本次交易内的链上状态变动。
- `^0.8.24`：允许兼容的 0.8.x 编译器；默认启用算术溢出检查。

## 与 Python 有哪些本质区别？

Python 整数精度可扩展，而 Solidity `uint256` 有固定范围。Solidity 的写状态不是普通对象属性赋值：区块链上的状态更昂贵，且合约代码对不同调用者行为必须确定。

## 实操与验收

1. 用 Remix VM 部署上面的 OwnedCounter。
2. 通过一个账户执行 `increase(3)`，读取 `doubled() == 6`。
3. 切换另一个 Remix 虚拟账户执行 `reset()`，必须 revert。
4. 切回部署账户执行 `reset()`，读取 count 为 0。

**常见坑：** `private` 表示 Solidity 代码访问级别，不等于链上数据加密。
