# 01-2 storage、mapping、struct 与 event

## 动机：为什么智能合约不是普通数据库？

在关系型数据库里可以索引、扫描、复杂联表；在 Solidity 里，更重要的是存储成本、键的访问方式和循环上界。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract UserNotebook {
    struct Profile {
        uint64 visits;
        string nickname;
    }

    mapping(address => Profile) private profiles;
    event Visited(address indexed user, uint64 visits);

    function visit(string calldata nickname) external {
        Profile storage p = profiles[msg.sender];
        p.visits += 1;
        p.nickname = nickname;
        emit Visited(msg.sender, p.visits);
    }

    function myProfile() external view returns (uint64, string memory) {
        Profile storage p = profiles[msg.sender];
        return (p.visits, p.nickname);
    }
}
```

## 关键词对照

| 关键词 | 作用 | 常见用途 |
| --- | --- | --- |
| `storage` | 持久化的链上存储引用 | 修改 mapping 中的 struct |
| `memory` | 本次调用中的临时内存 | 返回字符串、临时处理 |
| `calldata` | 外部函数的只读参数区域 | 字符串/数组入参 |
| `mapping` | 按 key 查找的键值结构 | 余额、角色、账户状态 |
| `event` | 写入日志，便于链下消费 | 转账、状态变更、审计 |

事件不是数据库表。链上合约**通常不能依赖自己的历史日志做业务授权**；业务逻辑应看当前状态。

## 失败场景

不要把一个随账户无限增长的数组放到链上，再尝试一笔交易遍历全部地址；集合越大，执行可能因 Gas 限制失败。

## 验收

在 Remix VM 选择两个地址各调用一次 `visit`，分别读取不同的 `myProfile`。在交易日志中能找到 `Visited` 事件。
