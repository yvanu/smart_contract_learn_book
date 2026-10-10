import { defineConfig } from 'vitepress'
export default defineConfig({
  lang: 'zh-CN',
  title: '智能合约开发学习手册',
  description: '面向后端工程师的 Solidity、Foundry、EVM、安全审计和全栈 DApp 实战指南',
  cleanUrls: true,
  lastUpdated: true,
  appearance: 'light',
  head: [
    ['meta', { name: 'theme-color', content: '#ffffff' }],
    ['meta', { property: 'og:title', content: '智能合约开发学习手册' }],
    ['meta', { property: 'og:description', content: '从 Solidity 零基础到可测试的智能合约项目' }]
  ],
  themeConfig: {
    logo: '/logo.svg',
    siteTitle: 'Smart Contract Lab',
    search: { provider: 'local' },
    nav: [
      { text: '从零开始', link: '/00-start/' },
      { text: '12 周路径', link: '/roadmap' },
      { text: '实战项目', link: '/05-project/' },
      { text: '安全与审计', link: '/04-security/' },
      { text: '进度', link: '/PROGRESS' },
      { text: 'GitHub', link: 'https://github.com/yvanu/smart_contract_learn_book' }
    ],
    sidebar: [
      { text: '学习导航', items: [
        { text: '课程首页', link: '/' },
        { text: '12 周学习路线', link: '/roadmap' },
        { text: '学习计划与验收', link: '/checklist' },
        { text: '教材进度 / 已验证内容', link: '/PROGRESS' }
      ]},
      { text: '00 · 认识智能合约', items: [
        { text: '00-1 为什么学智能合约', link: '/00-start/' },
        { text: '零基础术语词典（随时查）', link: '/00-start/glossary' },
        { text: '新手常见报错与排查', link: '/00-start/troubleshooting' }
        { text: '00-2 环境与第一个合约', link: '/00-start/environment' },
        { text: '00-3 从后端迁移到链上', link: '/00-start/backend-map' }
      ]},
      { text: '01 · Solidity 基础', items: [
        { text: '01-1 变量、函数和类型', link: '/01-solidity/' },
        { text: '01-2 存储、映射和事件', link: '/01-solidity/storage-events' },
        { text: '01-3 权限与错误处理', link: '/01-solidity/access-errors' }
      ]},
      { text: '02 · EVM 与以太坊', items: [
        { text: '02-1 交易、Gas 和 EVM', link: '/02-evm/' },
        { text: '02-2 ABI、调用与日志', link: '/02-evm/abi' }
      ]},
      { text: '03 · Foundry 工具链', items: [
        { text: '03-1 Forge 测试入门', link: '/03-foundry/' },
        { text: '03-2 Fuzz、Invariant 与调试', link: '/03-foundry/advanced-test' }
      ]},
      { text: '04 · 安全与标准', items: [
        { text: '04-1 重入和 CEI', link: '/04-security/' },
        { text: '04-2 权限、签名、预言机风险', link: '/04-security/threat-model' },
        { text: '04-3 ERC-20 与代币经济边界', link: '/04-security/erc20' }
      ]},
      { text: '05 · 完整实战项目', items: [
        { text: '05-1 里程碑与架构', link: '/05-project/' },
        { text: '05-2 托管合约实战', link: '/05-project/escrow' },
        { text: '05-3 测试与验收用例', link: '/05-project/acceptance' }
      ]},
      { text: '06 · 进阶与求职', items: [
        { text: '06-1 下一阶段学习', link: '/06-career/' },
        { text: '06-2 面试自测', link: '/06-career/interview' },
        { text: '06-3 部署与文档维护', link: '/deploy' }
      ]}
    ],
    outline: { level: [2, 3], label: '本页目录' },
    docFooter: { prev: '上一页', next: '下一页' },
    editLink: {
      pattern: 'https://github.com/yvanu/smart_contract_learn_book/edit/main/docs/:path',
      text: '在 GitHub 编辑此页'
    },
    lastUpdated: { text: '最后更新' },
    returnToTopLabel: '返回顶部',
    sidebarMenuLabel: '目录',
    darkModeSwitchLabel: '主题'
  }
})
