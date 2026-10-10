# 文档站部署与维护

本站使用 **VitePress 1.6.4 + Cloudflare Workers Static Assets**，没有数据库或后端服务。独立 Worker 名称 `smart-contract-learn-docs`，已上线域名 `contract.majhoon.site`，备用 `docs.contract.majhoon.site`。

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

## 低内存服务器专用：GitHub 远程构建

为避免服务器上 `npm install` 或构建占满内存，仓库的 `.github/workflows/publish-assets.yml` 会在 GitHub Actions 中构建 VitePress，并将静态资源推送到 `cf-dist` 分支。

服务器部署时只需拉取 `cf-dist` 分支的**已编译静态资源**，然后用**现成的 Wrangler 可执行程序**执行 `wrangler deploy --assets <已编译资源目录> -c wrangler.jsonc`。这不需要在服务器安装 Node 依赖或本地构建。

**低内存发布门禁：**

1. 先提交教材变更到 `main`，由 GitHub Actions 远程安装依赖并构建；等待 `Build Docs Assets for Cloudflare` 成功，确认 `cf-dist` 已包含这次提交生成的产物。
2. 服务器只下载 `cf-dist` 构建产物到**独立临时目录**，不要在正在使用的源码目录中清空文件或运行 `npm install`。
3. 使用已安装、经过验证的 Wrangler CLI 上传静态产物。若当前仓库没有 `node_modules/.bin/wrangler`，**不要用默认 `npx` 触发自动下载/安装**，先查找此前用于发布的现有 CLI 路径或改用 GitHub 远程部署。
4. 发布后检查域名主页、术语词典、Remix 新教程和排错页是否为 HTTP 200，再核对侧边栏能否进入这些页面；失败时不应假称已发布。

本机**不执行** VitePress 构建、npm 依赖安装或 Foundry 测试，也不在低内存服务器上并发执行多个检查任务。

当前已采用该方法成功上线，`main` 分支仅保存源码，`cf-dist` 保存构建结果。Cloudflare Token 必须从可信的环境变量读取，不要写入部署脚本。

## 可选：GitHub Actions 全自动部署

仓库提供 `.github/workflows/deploy.yml`。在 GitHub 仓库 Settings → Secrets and variables → Actions 下配置两个 Secrets：`CLOUDFLARE_API_TOKEN` 和 `CLOUDFLARE_ACCOUNT_ID`，再新增 Repository Variable `ENABLE_CF_DEPLOY=true`。之后向 `main` 推送会触发远程构建和 Worker 部署，服务器无需自己编译。缺少这些值时该工作流会跳过部署，而不是假报成功。

`.github/workflows/verify.yml` 已完成文档与 Foundry 合约的远程验证。`publish-assets.yml` 已成功生成 `cf-dist`。**全自动 Cloudflare 工作流目前因缺少仓库授权配置而跳过；不要将其误认为已经自动发布。**

## 发布后验收

```bash
curl -I https://contract.majhoon.site/
curl -I https://contract.majhoon.site/roadmap
curl -I https://contract.majhoon.site/05-project/escrow
curl -I https://docs.contract.majhoon.site/
```

检查是否为 2xx、TLS 是否正常、浏览器可打开侧边栏和搜索功能。并同步更新 [内容进度](/PROGRESS)。

## 版本约定

- 课程正文放 `docs/`，实操代码放 `examples/`。
- 每一篇新课程必须明确“目标、原理、源码、练习、失败用例、验收、常见坑”。
- **测试、编译、发布状态分别标记**；不要把“文档已写”说成“代码已上线”。
- 本地和 CI 日志严禁提交任何真实的私钥、助记词或 API Token。
