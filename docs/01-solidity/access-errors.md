# 01-3 权限、错误与 ETH 接收

## 为什么前端隐藏按钮不是权限？

任何用户都能绕过你的前端，直接对链上合约发交易。真正的权限检查必须在合约执行路径中。

```solidity
error Unauthorized();
error ZeroAddress();

address public owner;

modifier onlyOwner() {
    if (msg.sender != owner) revert Unauthorized();
    _;
}

function transferOwnership(address next) external onlyOwner {
    if (next == address(0)) revert ZeroAddress();
    owner = next;
}
```

## 三类错误处理方式

- `require(condition, "message")`：可读，但错误字符串可能更贵。
- `revert CustomError(args)`：结构化错误，工程上非常常见。
- `assert(condition)`：应表达程序内部不可违背的不变量，不能代替外部参数校验。

## 接收 ETH 的常见边界

- `payable` 函数允许随交易发送 ETH。
- `msg.value` 是本次调用携带的 wei；`1 ether == 10**18 wei`。
- 直接发送 ETH 给不支持接收的合约可能 revert。
- 外部调用 `recipient.call{value: amount}("")` 要检查返回值，且需要重入风险评估。

## 一个审阅清单

谁能调用？谁能转移所有权？地址零值怎样处理？能否将所有权误设为不可恢复地址？调用失败时资金能否锁死？有没有外部调用重入风险？

## 练习与验收

给上一节的 Notebook 添加 `admin` 和 `pause` 控制，写出非管理员调用必须失败的测试思路，**不要**仅靠前端按钮禁用。
