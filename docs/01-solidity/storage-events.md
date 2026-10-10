# 01-2 Solidity 如何保存数据：struct、mapping、storage 和 event

> **本课目标**：用“每个用户都有一本访问记录”的小程序，理解 Solidity 的数据存储方式。完成后可以回答：为什么 mapping 像 Python 字典，却不能随便遍历全部用户？

## 从 Python 字典开始理解

假设 Flask 项目里有一份用户档案：

```python
profiles = {
    "alice": {"visits": 2, "nickname": "小明"},
    "bob": {"visits": 1, "nickname": "小红"},
}
```

这里包含三层东西：

1. “用户 ID → 档案”的键值关系。
2. 每份档案包含多种字段。
3. 每次用户访问，就把 visits 加 1。

Solidity 可以实现类似数据结构，但链上**持久存储成本较高、数据透明可观察**，不能照抄 Python 的所有操作。

## 第一步：把完整例子放进 Remix

新建 `UserNotebook.sol`，编译后在 Remix VM 部署：

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

## 第二步：拆开五个新概念

### struct：把多个字段放在一起

`struct Profile` 像 Python dataclass 或一条数据库记录。它有两个字段：

- `visits`：用户访问次数，类型 `uint64`，默认值是 0。
- `nickname`：字符串，默认是空字符串。

`uint64` 与上节 `uint256` 都是无符号整数；`uint64` 可表示范围更小，不要随便认为“类型越小，每次存储就一定越省 Gas”，实际布局要结合存储槽分析。

### mapping：根据地址找到属于这个人的档案

`mapping(address => Profile) profiles;` 类似：

```python
profiles: dict[str, Profile] = {}
```

但有两点关键区别：

- 未写过的 key，读取到的是类型的**默认值**，不等于 Python 字典直接抛 KeyError。
- **无法从 mapping 自身枚举全部 key**。如果需要用户列表，必须另外设计记录方式或由链下事件索引系统整理。

### storage、memory、calldata：数据放在哪里？

初学者先掌握下表：

| 关键词 | 用生活话解释 | 在这个程序里 |
| --- | --- | --- |
| `storage` | 已存到链上“持久柜子”中的数据 | `Profile storage p` 指向某个用户档案 |
| `memory` | 一次调用中临时用的草稿纸 | 返回的 `string memory` |
| `calldata` | 外部传来的只读参数区域 | `string calldata nickname` |

这里的 `p` 不是“从数据库取出来的一份独立副本”；它是指向那份档案的**存储引用**。所以 `p.visits += 1` 会更新链上对应档案。

### event：广播发生过什么

`event Visited(address indexed user, uint64 visits);` 是先定义一种事件；`emit Visited(...)` 才是在调用时发出事件。

你可以理解成记录了一条“谁访问了、访问到第几次”的链上日志。`indexed` 可以帮助外部工具按 user 地址过滤。

但是：**事件不等于状态变量，也不代替读取当前数据。** 合约通常不能直接查询自己历史 event 的完整列表来做授权。

### private：不是保密

本例使用 `private profiles`，意思是其他合约**不能通过 Solidity 自动生成的公开 getter 直接访问这个变量**。但链上存储不是加密数据，用户昵称也不应该包含密码、身份证号等敏感信息。

## 第三步：Remix 做双账户实验

1. 账户 A 部署合约。
2. 账户 A 调用 `myProfile()`：预计返回 `0` 与空字符串。
3. 账户 A 在 visit 输入框输入 `"小明"`（按 Remix 提示输入字符串），点击 visit。
4. 账户 A 再读 `myProfile()`：预计 visits = `1`、nickname = `小明`。
5. 账户 A 再 visit 一次，改名字为 `"阿明"`：预计 visits = `2`、nickname = `阿明`。
6. 切换到账户 B，读取 myProfile：预计 `0`、空字符串。
7. B 调用 visit 输入自己的昵称，再查询，应只更新 B 的档案。
8. 找到 visit 交易的日志，观察是否有 `Visited` 事件。

为什么 B 看不到 A 的 myProfile？因为函数内部读取的是 `profiles[msg.sender]`，选谁调用就取谁那条记录。**这不是说 A 的数据在链上保密。**

## 常见错误与处理

| 现象 | 原因 | 排查 |
| --- | --- | --- |
| 输入中文昵称交易失败 | 输入框格式或字符串引号问题 | 按 Remix 对 string 的提示输入，不要复制弯引号 |
| 查询始终是 0 | 切换了账户、实例或未成功写入 | 检查 Account、Deployed Contracts、交易状态 |
| 想列出全部访问过的地址 | mapping 不提供 key 枚举 | 先学事件，后学链下索引 |
| 想把头像图片直接存链上 | 数据量大导致昂贵 | 工程上通常存经过审查的 URI / 哈希和链下数据 |

## 本课练习

把 `visit` 改成只增加次数、不覆盖昵称：哪一行应该删除？如果每个用户想保存多条历史记录，为什么不推荐一开始就写“无限循环遍历所有历史记录”？

<details><summary>参考答案</summary>

删除 `p.nickname = nickname;` 可以不覆盖昵称，但你还应相应修改函数签名，避免保留无用参数。无限增长的链上数组或不受限循环可能导致 Gas 消耗不断上升，最终无法在一笔交易内完成。
</details>

**验收**：能分别解释 `struct`、`mapping`、`storage`、`memory`、`calldata`、`event`，并完成两个账户互不影响的实验。

下一课：[权限、失败回滚与接收 ETH](/01-solidity/access-errors)。