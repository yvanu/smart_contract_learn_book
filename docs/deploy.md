# 文档站部署与维护

本站使用 **VitePress 1.6.4 + Cloudflare Workers Static Assets**，没有数据库或后端服务。独立 Worker 名称 `smart-contract-learn-docs`，预期域名 `docs.contract.majhoon.site`。

## 本地预览

```bash
npm install
npm run docs:dev
npm run docs:build
```

建议 Node.js 20+，避免在 2C2G 小服务器上同时构建多个项目。若内存不足，可限制 Node heap，例如 `NODE_OPTIONS=--max-old-space-size=256`。

## 部署命令

先在 Cloudflare 账户配置有效 API Token，其权限至少要足以编辑指定账户的 Worker，以及操作自定义域名所属 Zone。**不要把 Token 提交到 Git 或写入 README**。

```bash
npm run docs:build
npx wrangler deploy -c wrangler.jsonc
```

Wrangler 配置中的 custom domain 会尝试让 Cloudflare 为此子域创建 DNS 记录和证书；若域名已经绑定其他服务，必须先确认冲突再操作。

## 推荐：GitHub Actions 自动部署

仓库提供 `.github/workflows/deploy.yml`。在 GitHub 仓库 Settings → Secrets and variables → Actions 下配置两个 Secrets：`CLOUDFLARE_API_TOKEN` 和 `CLOUDFLARE_ACCOUNT_ID`，再新增 Repository Variable `ENABLE_CF_DEPLOY=true`。之后向 `main` 推送会触发远程构建和 Worker 部署，服务器无需自己编译。缺少这些值时该工作流会跳过部署，而不是假报成功。

另有 `.github/workflows/verify.yml` 对文档与 Foundry 合约执行远程验证。**只有 GitHub 仓库实际收到这些文件后工作流才会生效。**

## 发布后验收

```bash
curl -I https://docs.contract.majhoon.site/
curl -I https://docs.contract.majhoon.site/roadmap
curl -I https://docs.contract.majhoon.site/05-project/escrow
```

检查是否为 2xx、TLS 是否正常、浏览器可打开侧边栏和搜索功能。并同步更新 [内容进度](/PROGRESS)。

## 版本约定

- 课程正文放 `docs/`，实操代码放 `examples/`。
- 每一篇新课程必须明确“目标、原理、源码、练习、失败用例、验收、常见坑”。
- **测试、编译、发布状态分别标记**；不要把“文档已写”说成“代码已上线”。
- 本地和 CI 日志严禁提交任何真实的私钥、助记词或 API Token。
