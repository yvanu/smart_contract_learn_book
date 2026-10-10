# 02-2 ABI 与事件：外部程序怎样“听懂”合约

> **本课目标**：理解合约源码、合约地址、ABI、函数选择器以及事件之间的关系。先不用写完整 Web3 前端。

## 先看一个普通 Python 接口

Flask API 会用路径和 JSON 约定如何传参：

```text
POST /transfer
{"to": "...", "amount": 100}
```

但是 EVM 不接收 Flask 风格的 JSON body。合约调用包含要执行的函数信息和按 ABI 规则编码的二进制参数。

**ABI（Application Binary Interface）** 可以把它看作“合约对外暴露的机器可读接口说明”，类似简化版的 OpenAPI，但编码规则不一样。

## 三样东西必须分开

| 名称 | 到底是什么 | 用途 |
| --- | --- | --- |
| Solidity 源码 | 人看的代码，如 `Counter.sol` | 开发、审阅 |
| Bytecode 字节码 | 编译后 EVM 能执行的代码 | 部署与执行 |
| ABI | 描述外部函数、参数和事件的 JSON 结构 | 让钱包、脚本和前端知道如何编码/解析 |

另外还有 **Contract Address（合约地址）**：相当于“你要调用的是哪一个已部署实例”。只知道 ABI 却没有正确网络与合约地址，也不能找到目标实例。

## 函数选择器（selector）是什么？

假设合约有函数：

```solidity
function transfer(address to, uint256 amount) external;
```

这是**函数签名演示**，不是完整可部署合约。

普通 ABI 函数调用数据的开头是 4 字节 selector。它取自规范化函数签名 `transfer(address,uint256)` 的 Keccak-256 哈希前 4 字节：

```text
transfer(address,uint256)
            ↓
    selector = 0xa9059cbb
            ↓
0xa9059cbb | 编码后的地址 | 编码后的金额
```

其中固定大小的参数通常按 ABI 规则编码为 32 字节字（word），不足时填充。注意它**不是普通 JSON，也不是简单字符串拼接**。

## 用 Foundry 的 cast 看一个实际输出

不需要钱包、不需要 RPC：

```bash
cast sig 'transfer(address,uint256)'
```

预期输出：

```text
0xa9059cbb
```

再试：

```bash
cast abi-encode 'f(address,uint256)' 0x0000000000000000000000000000000000000001 100
```

这会输出一段 `0x...` 开头的长十六进制数据，用来表示编码后的**参数部分**。这里的 `f` 只帮助声明参数类型；它不表示你已向链转账。把 selector 和参数数据连接后，才能构成这种函数调用的完整 calldata。

## event 是什么？为什么前端能看到“已经付款”？

假设合约定义：

```solidity
event Paid(address indexed buyer, uint256 amount);
```

执行 `emit Paid(msg.sender, 100);` 时，会产生符合事件格式的日志。

- **indexed buyer**：可放入日志 topics，方便按地址筛选。
- **amount**：未 indexed 的值一般编码到日志 data。
- 链下系统可以根据 ABI 解码日志并展示“付款事件”。

但**看到事件并不代表可以跳过链上状态检查**。索引器可能滞后，也需处理链重组。业务真实性最终仍要结合正确网络、合约地址、交易状态和状态机规则判断。

## 交易与调用结果要分开记

| 名称 | 例子 | 含义 |
| --- | --- | --- |
| Wallet Address | `0x...` | 谁发起或控制账户 |
| Contract Address | `0x...` | 调用哪个合约实例 |
| Transaction Hash | `0x...` | 标识一笔已提交交易 |
| Receipt | status / gasUsed / logs | 记录执行结果 |
| ABI | 函数与事件定义 | 用于编码参数、解码结果 |
| Bytecode | `0x6080...` | EVM 实际执行的程序代码 |

## 练习：画出从网页到合约的路线

你可以把流程写在学习笔记里：

```text
前端按钮“增加计数”
  → 根据 ABI 知道函数名与参数
  → 用合约地址定位实例
  → 构造交易并请求用户签名
  → RPC 广播并获取交易哈希
  → 查回执、确认成功
  → 再调用 count() 读取最终状态
```

回答三个问题：

1. 用户拒绝签名，是否应该显示“计数成功”？**不应该。**
2. 拿到交易哈希是否代表数值更新成功？**不一定。**
3. 是否能凭一个事件就随意给数据库记“已到账”？**不能，还需验签/核实来源、状态和确认规则。**

**本课验收**：能用自己的话区分源码、ABI、字节码、合约地址、交易哈希、回执与事件。

下一课：[Foundry：用自动化测试证明合约不只是“看起来能跑”](/03-foundry/)。