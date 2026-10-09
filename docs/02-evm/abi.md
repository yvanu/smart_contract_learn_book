# 02-2 ABI、合约调用与事件日志

ABI（Application Binary Interface）描述合约函数、入参、出参与事件。前端或 Python 调用者借助 ABI 编码数据，而 EVM 读的是二进制调用数据。

## 函数 selector

普通函数调用数据以 4 字节选择器开始，来源于函数签名的 Keccak-256 哈希前 4 字节。例如 `transfer(address,uint256)` 的 selector 为 `0xa9059cbb`。

```text
0xa9059cbb | 000...recipient(32字节) | 000...amount(32字节)
  selector           ABI 编码参数
```

传入的地址和整数由 ABI 定义的编码规则决定，不是简单 JSON。

## 使用 cast 在本地验证

安装 Foundry 后：

```bash
cast sig 'transfer(address,uint256)'
cast abi-encode 'f(address,uint256)' 0x0000000000000000000000000000000000000001 100
```

验证 `cast sig` 的结果是否为上述选择器。这个演示不需要真实钱包或 RPC。

## event 与 indexed

Solidity 事件中标记 `indexed` 的参数放入主题以方便筛选；未标记的参数通常位于日志 data。链下索引器可以从日志建业务查询视图，但如果遭遇链重组，索引器也必须处理回滚/重放。

## 练习

写一份 Python Web3 或 viem 调用脚本的伪代码：ABI 从哪里来？只读调用与签名写交易分别是什么？前端用户拒绝签名怎样提示？

**验收：** 区分 ABI、bytecode、contract address、transaction hash、receipt 和 event logs。
