---
layout: home

hero:
  name: '从后端到智能合约'
  text: '理解 EVM · 写 Solidity · 做安全测试'
  tagline: '少一点术语堆砌，多一点可以运行、可以失败、可以验证的代码。面向有 Python / Web / 数据库经验的开发者。'
  image:
    src: /logo.svg
    alt: Smart Contract Lab
  actions:
    - theme: brand
      text: 从第 0 课开始 →
      link: /00-start/
    - theme: alt
      text: 查看 12 周路线
      link: /roadmap
    - theme: alt
      text: 查看实战工程
      link: https://github.com/yvanu/smart_contract_learn_book/tree/main/examples

features:
  - icon: 🧭
    title: 工程师友好的知识迁移
    details: 用 Python 后端的状态、事务、权限、接口概念，对照 EVM、Gas、ABI、事件与存储。
  - icon: 🧪
    title: 每一章都有可验证输出
    details: 理论 → 最小源码 → 本地实验 → 失败用例 → 验收。不用真钱、不需要主网账户。
  - icon: 🔒
    title: 安全从第一天开始
    details: 不是写出能运行的合约就算完成。重入、权限、回滚、签名和测试覆盖属于主课程。
  - icon: 🧱
    title: 一个完整项目贯穿学习
    details: 用可取消、可退款、有阶段状态的托管 Escrow 项目练习设计、测试、部署与复盘。
  - icon: 📘
    title: 本地可重复实验
    details: 首先用 Remix 与 Foundry 在本地学习，再进入测试网；不给刚入门的学习者引入真实资产风险。
  - icon: 📊
    title: 完成度真实透明
    details: 文档是否写完、代码是否编译、测试是否通过、网络部署是否验证，分别记录。

---

## 你会得到什么？

**第一阶段：** 用 Remix/Foundry 部署并调用自己的第一个合约，能解释为什么一次状态写入要花 Gas。

**第二阶段：** 用 Forge 写单测、失败预期、Fuzz 和基本属性约束，能够自己检查权限绕过与状态机。

**第三阶段：** 做出一个具备托管、释放、退款、超时边界和事件审计的 Escrow 合约，写出验收报告。

> [!IMPORTANT] 学习安全边界
> 所有示例仅面向**本地虚拟链或测试网**。未经专业审计和额外安全测试，不得用于管理真实资金。不要将助记词、私钥或真实 Token 提交到仓库。

按 [12 周路线](/roadmap) 每周推进，或直接进入 [第一课](/00-start/)。
