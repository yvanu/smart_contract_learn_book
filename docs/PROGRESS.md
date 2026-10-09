# 内容开发与验证进度

维护日期：2026-10-09。此页是**教材建设状态**，不是学习者的学习成绩。

## v0.1 基础教材

- [x] 课程首页、12 周路线、阶段验收与安全约定
- [x] 从后端工程转向 EVM 的知识迁移与入门环境
- [x] Solidity 状态、事件、权限、错误、EVM、ABI 基础
- [x] Forge 基础与进阶测试教程
- [x] 重入风险、威胁建模、ERC-20 安全边界
- [x] Escrow 完整项目设计、合约实现、测试与验收说明
- [x] 面试自测和后续深造建议

## 可执行代码与验证

| 项目 | 状态 | 备注 |
| --- | --- | --- |
| Docs VitePress 生产构建 | **已通过（远程 CI）** | 2026-10-09 GitHub Actions `Verify learning handbook`，记录 37933601439；服务器没有执行构建 |
| Foundry 编译 | **已通过（远程 CI）** | GitHub Actions 37933601439 的 `Foundry build and tests` job 成功 |
| Foundry 合约测试 | **已通过（远程 CI）** | GitHub Actions 37933601439 执行 `forge test -vv` 成功；不代表专业安全审计 |
| Cloudflare Workers 部署 | **已通过** | 本机 Wrangler 4.115.0 只上传远程构建静态文件，Worker `smart-contract-learn-docs`，Version ID `2f3cc5a7-e802-428b-8ad3-e081e6b8cd4a` |
| 自定义域名 HTTPS 验收 | **已通过** | `https://contract.majhoon.site/`、`/roadmap`、`/05-project/escrow` 及 `https://docs.contract.majhoon.site/` 均 HTTP 200，TLS 校验成功 |
| 主网资金安全审计 | **未进行** | 示例仅学习，不能管理真实资产 |
| 文档内部导航链接静态检查 | **通过** | 23 个 Markdown 页面、28 个配置路由，未发现缺失目标 |
| GitHub 推送 | **已完成** | 使用本地 Git SSH 推送 `main`（未使用 GitHub 连接器） |
| GitHub 远程静态产物导出 | **已通过** | GitHub Actions 37933601465 已将 VitePress 编译输出发布至 `cf-dist` 分支 |
| GitHub Actions 全自动 Cloudflare 发布 | **尚未启用** | 工作流 `.github/workflows/deploy.yml` 在缺少仓库 Secrets / `ENABLE_CF_DEPLOY` 时跳过；当前已使用本机 Wrangler 部署 |

2026-10-09 服务器曾在依赖安装阶段失去响应。恢复后严格避免在服务器上运行 `npm install` / VitePress 构建；全部依赖安装与前端、合约测试由 GitHub Actions 承担。服务器仅执行轻量的 Git、Wrangler 静态资源上传和 HTTPS 验收。**此部署方式不保证零内存消耗，但实际完成后服务器状态正常。**

## 下一个版本 v0.2

- [ ] 为 Escrow 补充形式化不变量、fuzz 对照结果和 Gas 快照
- [ ] 添加前端 viem 读取/写入的最小 DApp
- [ ] 完整的测试网发布与浏览器源码验证操作记录
- [ ] 围绕升级代理、跨链、MEV、DeFi 增加进阶实验

### 内容验收标准

每课包含：**目标 → 后端类比 → 原理 → 代码或命令 → 实操 → 失败案例 → 验收 → 常见坑**。测试结果只能写实际执行并通过的内容；严禁虚报。
