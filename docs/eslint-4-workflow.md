# ESLint 团队工作流完全指南

本文档详细介绍如何在团队中建立规范的 ESLint 工作流，涵盖 Git Hooks 集成、CI/CD 自动化、ESLint 与 Prettier 协作、团队规范制定以及配置共享等核心主题。通过系统性地引入这些实践，团队可以在保证代码质量的同时，保持开发效率。

## 1. Git Hooks 集成

Git Hooks 是实现本地代码质量检查的第一道防线。通过在提交前运行 ESLint，可以阻止不符合规范的代码进入版本控制系统，从源头保证代码质量。

### 1.1 husky v9

husky 是一个简洁的 Git Hooks 管理工具，v9 版本提供了更清晰的 API 和更好的性能。安装后，它会在 `.husky` 目录下创建各种 Git 钩子脚本。

#### 1.1.1 安装与初始化

```bash
# 安装 husky 和 lint-staged
npm install -D husky lint-staged

# 初始化 husky，创建 .husky 目录
npx husky init
```

初始化完成后，项目根目录会生成 `.husky` 目录和 `prepare` 脚本。`prepare` 脚本会在 `npm install` 时自动安装 husky，确保团队成员克隆项目后立即可用。

#### 1.1.2 配置 pre-commit 钩子

```bash
# 创建 pre-commit 钩子
npx husky add .husky/pre-commit "npx lint-staged"
```

上述命令会在 `.husky/pre-commit` 文件中添加 lint-staged 的调用。lint-staged 只会检查本次提交修改的文件，而非整个项目，大大减少了检查时间。

#### 1.1.3 package.json 配置

在 `package.json` 中添加 lint-staged 配置：

```json
{
  "lint-staged": {
    "*.{js,ts,jsx,tsx}": ["eslint --fix", "prettier --write"]
  }
}
```

这个配置指定了对于 JavaScript 和 TypeScript 文件，lint-staged 会依次执行 ESLint 修复和 Prettier 格式化。需要注意的是，ESLint 的 `--fix` 选项会自动修复部分可自动修复的问题，如代码风格；对于无法自动修复的问题，会在终端输出错误信息并阻止提交。

> **提示**：如果希望完全阻止提交直到所有问题修复，使用 `--max-warnings=0` 参数可以将警告也视为错误。

```json
{
  "lint-staged": {
    "*.{js,ts,jsx,tsx}": ["eslint --fix", "prettier --write", "eslint --max-warnings=0"]
  }
}
```

### 1.2 lint-staged

lint-staged 的核心价值在于只检查暂存区（staged）中的文件，避免对整个项目运行耗时的检查。它通常与 husky 配合使用，在 Git 提交前执行代码检查。

#### 1.2.1 工作原理

```
┌─────────────────────────────────────────────────────────┐
│                     Git Commit                           │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│               husky pre-commit 钩子                      │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│               lint-staged                                │
│  ┌─────────────────────────────────────────────────┐   │
│  │  获取暂存区文件 → 过滤配置匹配 → 执行命令         │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────┬───────────────────────────────────┘
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
    ┌──────────┐            ┌──────────┐
    │ 检查通过  │            │ 检查失败  │
    │ 提交继续  │            │ 提交终止  │
    └──────────┘            └──────────┘
```

#### 1.2.2 高级配置

对于更复杂的项目，可以为不同类型的文件配置不同的检查规则：

```json
{
  "lint-staged": {
    "*.{js,jsx,ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.{json,css,md}": ["prettier --write"],
    "*.py": ["flake8", "black"]
  }
}
```

这个配置展示了多语言项目的场景：JavaScript/TypeScript 文件执行完整的 ESLint 检查和格式化，而 Python 文件则使用 flake8 和 black 进行检查。

> **注意**：lint-staged 默认使用 `git diff` 获取变更文件，这意味着如果文件有未暂存的修改，这些修改不会被检查。确保在提交前先 `git add` 文件。

#### 1.2.3 调试模式

如果遇到 lint-staged 工作异常，可以使用调试模式排查问题：

```bash
# 查看 lint-staged 执行的详细日志
npx lint-staged --debug
```

调试输出会显示所有匹配的文件、执行的命令以及每个步骤的输出，帮助定位配置问题。

## 2. CI/CD 集成

虽然本地 Git Hooks 可以阻止大部分问题代码进入仓库，但并非所有团队成员都会正确配置钩子。此外，某些检查（如安全性扫描、性能基准测试）更适合在 CI 环境中执行。因此，将 ESLint 集成到 CI/CD 流程中是必要的补充。

### 2.1 GitHub Actions

GitHub Actions 是 GitHub 原生的 CI/CD 解决方案，可以免费用于开源项目和私有仓库。以下是一个完整的 ESLint 检查工作流配置。

#### 2.1.1 创建工作流文件

在项目根目录创建 `.github/workflows/eslint.yml`：

```yaml
name: ESLint

on:
  push:
    branches: [main, master, develop]
  pull_request:
    branches: [main, master]

jobs:
  eslint:
    runs-on: ubuntu-latest

    steps:
      # 1. 检出代码
      - uses: actions/checkout@v4

      # 2. 设置 Node.js 环境
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      # 3. 安装依赖
      - run: npm ci

      # 4. 运行 ESLint
      - run: npm run lint
```

这个工作流会在以下时机触发：推送到 main、master、develop 分支，以及创建 Pull Request 到这些分支。ESLint 检查失败会导致工作流失败，从而阻止合并。

#### 2.1.2 添加缓存优化

Node.js 依赖安装通常耗时较长，通过缓存可以显著加速 CI：

```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'npm'
```

`cache: 'npm'` 参数会自动缓存 `node_modules` 目录，下次运行时只需安装新增或变化的依赖。

#### 2.1.3 并行执行检查

如果项目包含多种检查（如 ESLint、TypeScript 类型检查、单元测试），可以并行执行以减少总体等待时间：

```yaml
name: CI

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

  typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run typecheck

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm test
```

三个作业会同时运行，GitHub Actions 会等待所有作业完成后才报告最终状态。如果任何一个作业失败，整个工作流会标记为失败。

> **提示**：将耗时的检查（如安装依赖）放在作业内部而非共享步骤中，可以让每个作业独立使用缓存。

### 2.2 缓存优化

除了依赖缓存，还有其他方式可以优化 ESLint 在 CI 环境中的执行速度。

#### 2.2.1 ESLint 缓存

ESLint 默认不缓存检查结果，每次运行都会重新检查所有文件。通过启用缓存，可以跳过未修改文件的检查：

```bash
# 在 package.json 的 lint 脚本中添加 --cache 参数
npm run lint -- --cache
```

缓存文件默认保存在 `.eslintcache` 目录下，应将其加入 `.gitignore`：

```text
# .gitignore
node_modules/
.eslintcache
dist/
```

#### 2.2.2 使用 github/cache 操作

对于更大的优化，可以使用专门的缓存 Action：

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-npm-
```

这种缓存策略会在依赖未命中缓存时回退到更宽泛的键，增加缓存命中率。

## 3. ESLint + Prettier

ESLint 和 Prettier 是两个互补的工具：ESLint 负责代码质量检查（如未使用变量、未定义的函数），Prettier 负责代码格式化（行长度、缩进、引号风格）。正确配置两者的协作关系是团队工作流的关键。

### 3.1 职责边界

理解两个工具的不同职责可以避免配置冲突和重复工作。

| 特性       | ESLint                           | Prettier                 |
| ---------- | -------------------------------- | ------------------------ |
| 主要职责   | 代码质量检查、潜在错误检测       | 代码格式化、风格统一     |
| 检查内容   | 未使用变量、未定义函数、语法错误 | 缩进、引号、分号、行长度 |
| 可自动修复 | 部分（通过 --fix）               | 全部                     |
| 配置方式   | 大量规则选项                     | 少量选项（opinionated）  |

ESLint 实际上内置了一些格式化规则，这些规则与 Prettier 的功能重叠。最佳实践是关闭 ESLint 中所有与 Prettier 冲突的格式化规则，让 Prettier 专注于格式化，ESLint 专注于代码质量。

#### 3.1.1 安装 eslint-config-prettier

`eslint-config-prettier` 是一个配置文件，它会关闭 ESLint 中所有与 Prettier 冲突的规则：

```bash
npm install -D eslint-config-prettier
```

然后在 ESLint 配置中继承该配置：

```json
{
  "extends": [
    "eslint:recommended",
    "plugin:react/recommended",
    "prettier" // 必须是最后一个
  ]
}
```

> **重要**：`prettier` 必须放在 `extends` 数组的最后，这样可以确保它覆盖其他配置中的冲突规则。

#### 3.1.2 安装 eslint-plugin-prettier（可选）

`eslint-plugin-prettier` 允许将 Prettier 作为 ESLint 的规则运行，这意味着所有格式化问题都会作为 ESLint 错误报告：

```bash
npm install -D eslint-plugin-prettier
```

配置方式：

```json
{
  "extends": ["eslint:recommended", "prettier"],
  "plugins": ["prettier"],
  "rules": {
    "prettier/prettier": "error"
  }
}
```

这样做的优势是只需要运行一个命令即可同时看到代码质量问题和格式化问题。缺点是 ESLint 的输出可能包含大量 Prettier 相关的错误信息，有些团队可能不习惯。

### 3.2 冲突解决

当 ESLint 和 Prettier 的配置发生冲突时，需要系统性地排查和解决。

#### 3.2.1 常见冲突场景

| 冲突类型     | ESLint 典型规则             | Prettier 默认值      |
| ------------ | --------------------------- | -------------------- |
| 语句结尾分号 | semi: ["error", "always"]   | semicolons: false    |
| 引号风格     | quotes: ["error", "single"] | singleQuote: true    |
| 缩进         | indent: ["error", 2]        | tabWidth: 2          |
| 行长度       | max-len: [2, 80]            | printWidth: 80       |
| 对象尾随逗号 | comma-dangle: "always"      | trailingComma: "es5" |

#### 3.2.2 冲突排查步骤

1. 运行 `npx eslint-config-prettier` 检查是否存在冲突规则

   如果有冲突，该命令会输出具体的冲突规则名称。

2. 确保 Prettier 配置与团队约定一致

   在 `.prettierrc` 文件中明确声明格式偏好：

   ```json
   {
     "semi": false,
     "singleQuote": true,
     "tabWidth": 2,
     "trailingComma": "es5",
     "printWidth": 80
   }
   ```

3. 确保 ESLint 配置继承自 `eslint-config-prettier`

   验证 `extends` 数组中 `prettier` 的位置和存在。

#### 3.2.3 验证配置正确性

运行以下命令验证 ESLint 和 Prettier 的协作是否正常：

```bash
# 检查 ESLint 配置中的冲突
npx eslint-config-prettier src/index.js

# 如果没有输出，说明配置正确
# 如果有冲突，会显示具体的规则名称
```

> **提示**：在实际开发中，可能会遇到 ESLint 报告了格式化问题，但运行 `prettier --write` 后问题消失的情况。这通常是因为 ESLint 的配置文件没有被正确继承 `eslint-config-prettier`。

## 4. 团队规范

建立适合团队的 ESLint 规范是实现代码一致性的关键。规范需要平衡代码质量和开发效率，既不能过于宽松导致代码风格混乱，也不能过于严格导致开发体验下降。

### 4.1 规则选择

选择 ESLint 规则时，需要考虑团队的技术栈、经验和项目需求。

#### 4.1.1 规则级别

ESLint 规则有三个严重程度级别：

| 级别  | 值  | 效果             |
| ----- | --- | ---------------- |
| off   | 0   | 禁用规则         |
| warn  | 1   | 警告，不阻止提交 |
| error | 2   | 错误，阻止提交   |

团队通常采用以下策略：

- **核心规则**：设置为 `error`，任何违反都会阻止提交，如禁止 `console.log`、未使用的变量
- **建议规则**：设置为 `warn`，提示改进但不阻止，如缺少 JSDoc 注释
- **可选规则**：保持 `off`，团队成员可自行选择启用

#### 4.1.2 推荐的规则配置

以下是一个典型 React + TypeScript 项目的规则配置示例：

```json
{
  "rules": {
    // 错误预防
    "no-console": "error",           // 禁止 console.log
    "no-debugger": "error",           // 禁止 debugger
    "no-unused-vars": "error",       // 禁止未使用变量
    "no-undef": "error",             // 禁止未定义变量

    // 代码风格
    "prefer-const": "warn",          // 建议使用 const
    "no-var": "error",               // 禁止使用 var
    "eqeqeq": ["error", "always"],   // 强制使用 === 和 !==

    // React 特定
    "react/react-in-jsx-scope": "off", // React 17+ 不需要导入 React
    "react/prop-types": "warn"        // Props 类型检查
  }
}
```

#### 4.1.3 继承现有配置

大多数项目不需要从零开始配置 ESLint，可以继承社区广泛使用的配置：

| 配置包             | 适用场景                   |
| ------------------ | -------------------------- |
| eslint:recommended | 基础配置，最小化规则集     |
| airbnb             | Airbnb JavaScript 风格指南 |
| airbnb-typescript  | Airbnb + TypeScript        |
| standard           | Standard JS 无分号风格     |
| prettier           | 与 Prettier 配合使用       |

继承示例：

```json
{
  "extends": [
    "airbnb",
    "airbnb-typescript",
    "plugin:react-hooks/recommended",
    "prettier"
  ]
}
```

### 4.2 严重程度策略

规则的严重程度设置直接影响开发体验和代码质量。

#### 4.2.1 本地开发环境

在本地开发环境中，建议的策略是：

| 场景           | 建议配置                   |
| -------------- | -------------------------- |
| git pre-commit | 全部为 error，只运行 --fix |
| IDE 实时检查   | warn + error，显示问题列表 |
| npm run lint   | error，用于 CI 验证        |

#### 4.2.2 CI 环境

在 CI 环境中，应该使用最严格的配置：

```bash
# CI 中运行的 lint 命令
npm run lint -- --max-warnings 0
```

`--max-warnings 0` 参数会将警告也视为错误，确保只有完全符合规范的代码才能通过 CI。

> **注意**：如果在 CI 中使用 `--max-warnings 0`，需要确保所有 warn 级别的规则都是团队真正关心的，否则可能会因为无关紧要的警告而导致构建失败。

#### 4.2.3 渐进式采用

对于已有大量技术债务的项目，可以采用渐进式策略：

1. **第一阶段**：将所有规则设置为 `warn`，让开发者看到问题但不阻止提交
2. **第二阶段**：将核心规则改为 `error`，持续一至两周
3. **第三阶段**：逐步将其他规则升级为 `error`

这种渐进式方法可以减少团队阻力，让成员有时间适应新的规范。

## 5. 配置共享

当团队有多个项目时，每个项目单独维护 ESLint 配置会导致重复工作和风格不一致。通过配置共享，团队可以确保所有项目使用相同的代码规范。

### 5.1 npm 包

将 ESLint 配置封装为 npm 包是配置共享的标准方式。

#### 5.1.1 创建配置包

假设团队名为 Acme，配置包命名为 `@acme/eslint-config`：

```bash
# 创建项目目录
mkdir @acme/eslint-config && cd @acme/eslint-config

# 初始化 npm 包
npm init
```

配置 `package.json`：

```json
{
  "name": "@acme/eslint-config",
  "version": "1.0.0",
  "main": "index.js",
  "peerDependencies": {
    "eslint": "^8.0.0",
    "eslint-plugin-react": "^7.0.0"
  }
}
```

> **注意**：将 ESLint 和相关插件放在 `peerDependencies` 中，而非 `dependencies`。这样可以避免多个项目安装相同依赖的不同版本，减少项目体积。

创建 `index.js` 配置文件：

```javascript
module.exports = {
  extends: [
    'eslint:recommended',
    'plugin:react/recommended',
    'prettier'
  ],
  rules: {
    // 团队特定规则
    'no-console': 'error',
    'prefer-const': 'error'
  },
  env: {
    browser: true,
    node: true,
    es2021: true
  },
  parserOptions: {
    ecmaVersion: 2021,
    sourceType: 'module'
  }
};
```

#### 5.1.2 使用配置包

在项目中使用共享配置：

```bash
# 安装配置包
npm install -D @acme/eslint-config
```

在 ESLint 配置中继承：

```json
{
  "extends": "@acme/eslint-config"
}
```

#### 5.1.3 TypeScript 支持

如果团队使用 TypeScript，需要安装相应的解析器：

```bash
npm install -D @typescript-eslint/parser @typescript-eslint/eslint-plugin
```

更新配置包：

```javascript
module.exports = {
  parser: '@typescript-eslint/parser',
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'prettier'
  ],
  plugins: ['@typescript-eslint'],
  rules: {
    // TypeScript 特定规则
    '@typescript-eslint/no-unused-vars': 'error',
    '@typescript-eslint/explicit-function-return-type': 'off'
  }
};
```

### 5.2 发布流程

配置包需要遵循规范的发布流程，确保团队成员始终使用最新配置。

#### 5.2.1 版本号管理

采用语义化版本号（SemVer）：

| 版本类型 | 适用场景               | 示例          |
| -------- | ---------------------- | ------------- |
| 补丁版本 | 修复错误、不改变规则   | 1.0.0 → 1.0.1 |
| 次版本   | 新增规则（可选启用）   | 1.0.0 → 1.1.0 |
| 主版本   | 破坏性变更（规则强化） | 1.0.0 → 2.0.0 |

> **重要**：改变规则的严重程度（如 warn 改为 error）属于破坏性变更，应升级主版本号。

#### 5.2.2 发布命令

```bash
# 登录 npm（需要提前注册）
npm login

# 发布包
npm publish --access public

# 如果是私有组织包
npm publish
```

#### 5.2.3 自动化发布

可以使用 GitHub Actions 自动化发布流程：

```yaml
name: Publish

on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          registry-url: 'https://registry.npmjs.org'
      - run: npm ci
      - run: npm publish
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

配置步骤：

1. 在 npm 网站创建 Access Token
2. 在 GitHub 仓库设置中添加 `NPM_TOKEN` 密钥
3. 创建 GitHub Release 即可触发自动发布

#### 5.2.4 使用版本锁定

在项目中锁定配置包版本，避免自动升级导致意外问题：

```json
{
  "devDependencies": {
    "@acme/eslint-config": "1.2.0"
  }
}
```

当配置包发布新版本后，使用以下命令手动升级：

```bash
# 升级到最新的补丁版本
npm install -D @acme/eslint-config@latest

# 或指定特定版本
npm install -D @acme/eslint-config@2.0.0
```

> **提示**：建议在团队内部沟通渠道（如 Slack、钉钉）同步配置包更新内容，让开发者了解新增或强化的规则。

## 6. 总结

### 核心要点

1. **Git Hooks 是第一道防线**：使用 husky + lint-staged 在提交前检查代码，只检查变更文件，平衡质量与效率。

2. **CI/CD 是必要补充**：GitHub Actions 自动化检查确保所有代码经过验证，缓存优化提升构建速度。

3. **ESLint 与 Prettier 配合使用**：通过 eslint-config-prettier 消除冲突，让各工具专注职责。

4. **规则选择要务实**：从宽松到严格渐进式推进，核心规则严格（error），建议规则宽松（warn）。

5. **配置共享减少重复**：将通用配置发布为 npm 包，确保多项目代码风格一致。

### 速查表

| 场景                 | 命令/配置                                           |
| -------------------- | --------------------------------------------------- |
| 安装 husky           | `npx husky init`                                    |
| 创建 pre-commit 钩子 | `npx husky add .husky/pre-commit "npx lint-staged"` |
| 启用 ESLint 缓存     | `npm run lint -- --cache`                           |
| CI 中严格检查        | `npm run lint -- --max-warnings 0`                  |
| 检查配置冲突         | `npx eslint-config-prettier`                        |
| 安装配置包           | `npm install -D @acme/eslint-config`                |
| 继承共享配置         | `"extends": "@acme/eslint-config"`                  |

## 参考资源

- [ESLint 官方文档](https://eslint.org/docs/latest/)
- [husky GitHub 仓库](https://github.com/typicode/husky)
- [lint-staged 官方文档](https://github.com/lint-staged/lint-staged)
- [eslint-config-prettier 官方文档](https://github.com/prettier/eslint-config-prettier)
- [GitHub Actions 官方文档](https://docs.github.com/en/actions)
- [Airbnb JavaScript 风格指南](https://github.com/airbnb/javascript)
- [语义化版本号规范](https://semver.org/lang/zh-CN/)
