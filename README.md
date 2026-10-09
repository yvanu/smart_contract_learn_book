# 智能合约开发学习手册 · Smart Contract Lab

一份面向**有 Python/Flask、数据库、API、Git 基础的后端工程师**的中文智能合约实战教程。以 Ethereum EVM / Solidity / Foundry 为主线，带你从第一份合约走到一个有权限、状态机、资金和反向测试的 Escrow 实践项目。

- 📖 **在线学习手册**：[contract.majhoon.site](https://contract.majhoon.site/)（备用：[docs.contract.majhoon.site](https://docs.contract.majhoon.site/)）
- 🗺️ [12 周学习路线](docs/roadmap.md)
- 🚀 [零基础第一课](docs/00-start/index.md)
- 🧠 [从后端到链上的知识迁移](docs/00-start/backend-map.md)
- 💻 [Foundry 完整示例](examples/foundry/)
- 🛡️ [重入、权限和威胁建模](docs/04-security/index.md)
- 🧱 [Escrow 托管工程实战](docs/05-project/index.md)
- 🎯 [学习验收清单](docs/checklist.md)
- 📋 [实际完成与验证进度](docs/PROGRESS.md)

## 能学到什么？

| 阶段 | 主要能力 | 交付 |
| --- | --- | --- |
| 1～4 周 | 区块链基础、Solidity、存储、Gas、ABI | 自己部署、操作并审阅 Counter |
| 5～8 周 | Forge、失败用例、fuzz、重入与 ERC-20 | 解释并测试关键风险 |
| 9～12 周 | 托管合约设计、实现、测试、复盘 | Escrow 源码与验收报告 |

推荐每天 1～2 小时。学习路线是计划，不是保证。**课程文档的完成与代码实际测试状态完全分开记录**。

## 本地运行

```bash
# 文档网站
npm install
npm run docs:dev
npm run docs:build
```

```bash
# Foundry 示例，需要事先安装 forge 和 Solidity 编译器
cd examples/foundry
forge build
forge test -vv
```

Foundry 安装指南：[getfoundry.sh](https://getfoundry.sh/introduction/installation/)。

## Cloudflare 部署

独立 Worker：`smart-contract-learn-docs`；已部署至 `contract.majhoon.site` 和 `docs.contract.majhoon.site`。

```bash
npm run docs:build
npx wrangler deploy -c wrangler.jsonc
```

为避免低内存服务器再次因依赖安装或构建失去响应，已配置 GitHub Actions **远程构建并将产物发布到 `cf-dist` 分支**，服务器仅做 Git 拉取和 Wrangler 静态文件上传。可选的全自动 Cloudflare 部署需要单独设置仓库 Secrets；详见 [部署文档](docs/deploy.md)。切勿提交任何 Token。

## 安全提示

仓库包含的智能合约仅用于**本地虚拟链 / 测试网学习**，未经专业审计，不可处理真实资金。切勿上传私钥、助记词、真实签名材料。真实资产安全和经济模型不在 v0.1 教材的保证范围内。

**内容维护原则**：每节课都要有目标、原理、实操、失败案例、验收。升级教材请同时更新 `docs/PROGRESS.md`。
