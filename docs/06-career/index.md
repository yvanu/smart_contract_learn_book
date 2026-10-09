# 06-1 进阶方向与工程化能力

学完 Solidity 语法后，真正提升工程能力的是：威胁建模、系统边界、正确测试、链下服务、协议标准和故障复现。

## 路径 A：智能合约研发

- 深入 Solidity 编译产物、EVM storage layout、gas optimization。
- 研究 ERC-20/721/1155 和经审查的 OpenZeppelin 实现。
- 学习可升级代理（Transparent、UUPS）及初始化/存储布局风险。
- 掌握 Foundry fuzz、invariant、fork testing 和部署脚本。

## 路径 B：Web3 后端/全栈

- 使用 viem/ethers.js 读取链、交易回执和合约事件。
- 编写可靠索引器：确认数、链重组、幂等消费和断点续传。
- 连接钱包、处理链切换和交易失败信息。
- 设计链上链下数据一致性：绝不把“广播成功”当作“业务成功”。

## 路径 C：安全审计

- 在本地隔离环境中复现常见漏洞，而不是在主网上寻找可利用资金。
- 建立威胁模型、资产清单、假设与攻击面。
- 研究权限、重入、预言机、MEV、签名重放、经济攻击。
- 学习安全报告的格式：影响、复现条件、证据、修复与残余风险。

## 推荐阅读

- [Solidity 官方文档](https://docs.soliditylang.org/)
- [Foundry Book](https://getfoundry.sh/)
- [Ethereum 开发者文档](https://ethereum.org/en/developers/docs/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [OWASP Smart Contract Security](https://scs.owasp.org/)

## 交付作品集

保留合约源文件、可重现命令、测试和一次“为什么该设计仍不适合真钱”的安全复盘，比只放截图更有说服力。

下一课：[面试自测](/06-career/interview)。
