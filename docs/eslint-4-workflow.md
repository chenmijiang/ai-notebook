# ESLint 团队工作流完全指南

本文档介绍如何在团队中建立规范的 ESLint 工作流，涵盖本地开发环境、CI/CD 流水线、团队协作规范以及配置共享机制。通过系统性地引入这些实践，团队可以在保证代码质量的同时维持开发效率。

> **前置文档**：Git Hooks 详细配置请参阅 [Husky 使用指南](./husky-guide.md)，Prettier 团队协作实践请参阅 [Prettier 团队协作实践](./prettier-6-team-practices.md)。

## 1. 本地开发

本地开发阶段是代码质量保障的第一道防线。通过在开发者提交代码前运行检查，可以阻止不符合规范的代码进入版本控制。

### 1.1 Git Hooks 快速配置

Git Hooks 会在 Git 操作（如提交、推送）触发时自动执行脚本。我们用它来在提交前运行 ESLint 检查。

```bash
# 安装依赖
npm install -D husky lint-staged

# 初始化 husky
npx husky init

# 创建 pre-commit 钩子
npx husky add .husky/pre-commit "npx lint-staged"
```

在 `package.json` 中配置 lint-staged，指定要检查的文件类型和命令：

```json
{
  "lint-staged": {
    "*.{js,ts,jsx,tsx}": ["eslint --fix", "prettier --write"]
  }
}
```

> **提示**：lint-staged 只检查本次提交修改的文件（暂存区文件），而非整个项目，因此检查速度很快。

### 1.2 ESLint + Prettier 协作

ESLint 和 Prettier 职责不同，配合使用可以全面覆盖代码质量：

| 工具     | 职责范围   | 检查内容                                   |
| -------- | ---------- | ------------------------------------------ |
| ESLint   | 代码质量   | 未使用变量、未定义函数、语法错误、潜在 bug |
| Prettier | 代码格式化 | 缩进、引号风格、分号、行长度、逗号风格     |

两者职责不重叠，但 ESLint 内置了一些格式化规则会与 Prettier 冲突，需要通过 `eslint-config-prettier` 解决。

```bash
# 安装
npm install -D eslint-config-prettier
```

```javascript
// eslint.config.js
import js from '@eslint/js';
import prettier from 'eslint-config-prettier';

export default [js.configs.recommended, prettier];
```

> **重要**：`prettier` 必须放在配置数组的最后，这样才能覆盖前面配置中的冲突规则。

## 2. CI/CD 集成

虽然本地 Git Hooks 可以阻止大部分问题代码，但并非所有团队成员都会正确配置钩子。将 ESLint 集成到 CI/CD 流程中，可以确保所有代码在合并前都经过检查。

### 2.1 GitHub Actions

GitHub Actions 是 GitHub 原生的 CI/CD 平台，免费用于开源和私有仓库。

```yaml
name: ESLint

on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
```

这个工作流会在以下时机触发：推送到任何分支，或创建 Pull Request。ESLint 检查失败会导致工作流失败，从而阻止代码合并。

### 2.2 缓存优化

ESLint 默认每次运行都会重新检查所有文件。通过启用缓存，可以跳过未修改文件的检查：

```bash
npm run lint -- --cache
```

缓存文件默认保存在 `.eslintcache`，需要加入 `.gitignore`：

```text
# .gitignore
.eslintcache
```

## 3. 团队协作

建立适合团队的 ESLint 规范是实现代码一致性的关键。规范需要平衡代码质量和开发效率。

### 3.1 规则级别策略

ESLint 规则有三个严重程度级别，不同级别对开发流程的影响不同：

| 级别    | 值  | 效果             | 适用场景               |
| ------- | --- | ---------------- | ---------------------- |
| `error` | 2   | 阻止提交/构建    | 核心规则：防止严重问题 |
| `warn`  | 1   | 显示警告但不阻止 | 建议规则：提醒改进     |
| `off`   | 0   | 禁用规则         | 可选规则：个人偏好     |

**团队通常采用的策略**：

- 核心规则设为 `error`：如禁止 `console.log`（生产环境）、未使用的变量、未定义的变量
- 建议规则设为 `warn`：如缺少 JSDoc 注释、`prefer-const`
- 可选规则保持 `off`：团队成员可自行决定是否启用

### 3.2 不同环境的配置策略

不同运行环境需要不同的配置策略：

| 环境                | 配置要求        | 推荐命令                  |
| ------------------- | --------------- | ------------------------- |
| 本地 git pre-commit | 宽松 + 自动修复 | `eslint --fix`            |
| IDE 实时检查        | 及时反馈        | 编辑器插件                |
| CI 构建             | 严格检查        | `eslint --max-warnings 0` |

```json
{
  "scripts": {
    "lint": "eslint src --fix --max-warnings 0"
  }
}
```

`--max-warnings 0` 会将警告也视为错误，确保只有完全符合规范的代码才能通过 CI。

### 3.3 渐进式采用

对于已有技术债务的存量项目，建议采用渐进式策略引入严格规范：

1. **第一阶段**：将所有规则设为 `warn`，让开发者看到问题但不阻止提交
2. **第二阶段**：将核心规则改为 `error`，持续一至两周让团队适应
3. **第三阶段**：逐步将其他规则升级为 `error`

这种渐进式方法可以减少团队阻力，让成员有时间适应新规范。

### 3.4 常用共享配置

大多数项目不需要从零配置 ESLint，可以继承社区广泛使用的配置：

| 配置包               | 特点                | 适用场景         |
| -------------------- | ------------------- | ---------------- |
| `eslint:recommended` | 最小规则集          | 快速开始         |
| `airbnb`             | 严格风格规范        | 大型团队         |
| `airbnb-typescript`  | Airbnb + TypeScript | TS 项目          |
| `standard`           | 无分号风格          | 简洁风格         |
| `prettier`           | 关闭冲突规则        | 与 Prettier 配合 |

## 4. 配置共享

当团队有多个项目时，每个项目单独维护 ESLint 配置会导致重复工作和风格不一致。通过配置共享，确保所有项目使用相同的代码规范。

### 4.1 创建配置包

将 ESLint 配置封装为 npm 包是配置共享的标准方式：

```bash
# 创建目录
mkdir @acme/eslint-config && cd $_

# 初始化
npm init
```

配置 `package.json`，将 ESLint 和插件放在 `peerDependencies` 中：

```json
{
  "name": "@acme/eslint-config",
  "peerDependencies": {
    "eslint": "^8.0.0",
    "typescript-eslint": "^6.0.0"
  }
}
```

创建 `eslint.config.js`：

```javascript
import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import prettier from 'eslint-config-prettier';

export default [
  js.configs.recommended,
  ...tseslint.configs.recommended,
  prettier,
];
```

> **提示**：放在 `peerDependencies` 可以避免多个项目安装相同依赖的不同版本，减少项目提及和潜在冲突。

### 4.2 使用配置包

在团队项目中安装和使用配置包：

```bash
npm install -D @acme/eslint-config
```

```javascript
// 项目 eslint.config.js
import baseConfig from '@acme/eslint-config';

export default [
  ...baseConfig,
  // 项目特定覆盖
  {
    rules: {
      // 项目特定规则
    },
  },
];
```

### 4.3 版本管理

配置包的版本升级需要遵循语义化版本规范（SemVer）：

| 变更类型           | 版本升级 | 示例          |
| ------------------ | -------- | ------------- |
| 修复错误           | 补丁版本 | 1.0.0 → 1.0.1 |
| 新增可选规则       | 次版本   | 1.0.0 → 1.1.0 |
| 规则强化（破坏性） | 主版本   | 1.0.0 → 2.0.0 |

> **重要**：改变规则的严重程度（如 warn 改为 error）属于破坏性变更，应升级主版本号。

## 总结

### 核心要点

| 环节              | 关键做法                               |
| ----------------- | -------------------------------------- |
| 本地开发          | husky + lint-staged 只检查变更文件     |
| CI/CD             | GitHub Actions 自动检查，缓存优化速度  |
| ESLint + Prettier | eslint-config-prettier 解决冲突        |
| 规则策略          | 渐进式采用，核心规则严格，建议规则宽松 |
| 配置共享          | npm 包方式，统一多项目规范             |

### 速查表

| 场景        | 命令/配置                          |
| ----------- | ---------------------------------- |
| 本地检查    | `npx lint-staged`                  |
| CI 严格检查 | `npm run lint -- --max-warnings 0` |
| 避免冲突    | `eslint-config-prettier`           |
| 启用缓存    | `--cache`                          |
| 配置共享    | 发布为 npm 包                      |

## 参考资源

- [ESLint 官方文档](https://eslint.org/docs/latest/)
- [Husky 使用指南](./husky-guide.md)
- [Prettier 团队协作实践](./prettier-6-team-practices.md)
- [eslint-config-prettier](https://github.com/prettier/eslint-config-prettier)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Airbnb JavaScript 风格指南](https://github.com/airbnb/javascript)
- [语义化版本号规范](https://semver.org/lang/zh-CN/)
