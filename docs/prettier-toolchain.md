# Prettier 工具链整合指南

## 1. 概述

### 1.1 工具链全景图

现代前端项目的代码质量保障需要多个工具协同工作。Prettier 作为格式化核心，需要与其他工具无缝集成。

```
开发者本地环境
├── 编辑器（VS Code/WebStorm）
│   └── Prettier 插件 → 保存时自动格式化
├── Git Hooks（husky + lint-staged）
│   └── pre-commit → 提交前格式化暂存文件
└── npm scripts
    └── format/lint → 手动或批量格式化

CI/CD 环境
├── GitHub Actions / GitLab CI
│   └── prettier --check → 检查格式是否符合规范
└── 自动化质量门禁
    └── 格式检查失败则阻止合并
```

**工具链组成：**

| 工具               | 作用                        | 运行时机         |
| ------------------ | --------------------------- | ---------------- |
| Prettier           | 代码格式化                  | 开发时/提交前/CI |
| ESLint             | 代码质量检查                | 开发时/提交前/CI |
| eslint-config-prettier | 禁用 ESLint 格式化规则  | 配置时           |
| husky              | Git Hooks 管理              | 提交时           |
| lint-staged        | 只处理暂存文件              | 提交时           |
| GitHub Actions     | CI/CD 流水线                | 推送/PR 时       |

### 1.2 职责划分原则

Prettier 与 ESLint 各司其职，明确分工是工具链整合的关键。

| 职责类型     | 负责工具 | 具体内容                         |
| ------------ | -------- | -------------------------------- |
| 代码格式化   | Prettier | 缩进、空格、换行、引号、分号     |
| 代码质量检查 | ESLint   | 未使用变量、类型错误、最佳实践   |
| Git 流程控制 | husky    | 在 commit/push 时触发检查        |
| 增量处理     | lint-staged | 只处理暂存区文件，提升效率    |
| 持续集成     | CI/CD    | 确保主分支代码符合规范           |

**最佳实践原则：**

1. **Prettier 负责「代码长什么样」**：格式问题全部交给 Prettier
2. **ESLint 负责「代码有没有问题」**：关闭所有格式化规则
3. **本地先拦截**：尽量在提交前发现问题，减少 CI 失败
4. **CI 兜底**：防止绕过本地检查的代码进入主分支

## 2. Prettier 与 ESLint

### 2.1 职责边界

Prettier 和 ESLint 都可以处理代码格式，但混用会导致冲突。

**冲突示例：**

```javascript
// ESLint 规则：indent: ["error", 4]（要求 4 空格缩进）
// Prettier 规则：tabWidth: 2（要求 2 空格缩进）

// 结果：两个工具互相「纠正」，永远无法同时通过
```

**解决方案：让 Prettier 专门负责格式化，ESLint 专注代码质量。**

| 场景                   | 推荐做法                      |
| ---------------------- | ----------------------------- |
| ESLint 格式规则冲突    | 使用 eslint-config-prettier   |
| 需要在 ESLint 中报错   | 使用 eslint-plugin-prettier   |
| 完全分离               | 分别运行，互不干扰            |

### 2.2 eslint-config-prettier

`eslint-config-prettier` 的作用是关闭所有与 Prettier 冲突的 ESLint 规则。

**安装：**

```bash
npm install --save-dev eslint-config-prettier
```

**配置（Flat Config，ESLint 9+）：**

```javascript
// eslint.config.js
import js from "@eslint/js";
import eslintConfigPrettier from "eslint-config-prettier";

export default [
  js.configs.recommended,
  eslintConfigPrettier, // 必须放在最后，覆盖前面的格式规则
];
```

**配置（传统 .eslintrc）：**

```json
{
  "extends": [
    "eslint:recommended",
    "prettier"
  ]
}
```

**被禁用的规则示例：**

| 规则名          | 说明                   | 禁用原因               |
| --------------- | ---------------------- | ---------------------- |
| indent          | 缩进                   | Prettier 控制          |
| quotes          | 引号风格               | Prettier 控制          |
| semi            | 分号                   | Prettier 控制          |
| comma-dangle    | 尾随逗号               | Prettier 控制          |
| max-len         | 行宽限制               | Prettier 控制          |
| arrow-parens    | 箭头函数括号           | Prettier 控制          |
| object-curly-spacing | 对象大括号空格    | Prettier 控制          |

**验证配置是否生效：**

```bash
# 检查是否存在与 Prettier 冲突的规则
npx eslint-config-prettier src/index.js
```

### 2.3 eslint-plugin-prettier

`eslint-plugin-prettier` 将 Prettier 作为 ESLint 规则运行，格式问题会作为 ESLint 错误报告。

**安装：**

```bash
npm install --save-dev eslint-plugin-prettier eslint-config-prettier
```

**配置（Flat Config）：**

```javascript
// eslint.config.js
import eslintPluginPrettier from "eslint-plugin-prettier/recommended";

export default [
  eslintPluginPrettier, // 包含了 eslint-config-prettier
];
```

**配置（传统 .eslintrc）：**

```json
{
  "extends": ["plugin:prettier/recommended"]
}
```

**工作原理：**

```
代码 → Prettier 格式化 → 对比原始代码 → 差异作为 ESLint 错误报告
```

**优缺点对比：**

| 方面     | 优点                             | 缺点                           |
| -------- | -------------------------------- | ------------------------------ |
| 报错方式 | 格式问题直接显示为 ESLint 错误   | 错误信息不如直接运行 Prettier 清晰 |
| 编辑器   | 统一在 ESLint 面板查看所有问题   | 性能比分开运行略差             |
| 修复     | `eslint --fix` 同时修复格式和质量问题 | 增加 ESLint 运行时间       |

### 2.4 推荐方案

根据项目规模和团队习惯，选择合适的整合方案。

| 方案     | 适用场景           | 配置复杂度 | 性能 |
| -------- | ------------------ | ---------- | ---- |
| 方案 A   | 小型项目、个人项目 | 低         | 最优 |
| 方案 B   | 中大型项目、团队协作 | 中       | 良好 |
| 方案 C   | 需要统一报错入口   | 中         | 一般 |

**方案 A：完全分离（推荐）**

Prettier 和 ESLint 分别运行，互不干扰。

```json
{
  "scripts": {
    "format": "prettier --write .",
    "lint": "eslint .",
    "check": "prettier --check . && eslint ."
  }
}
```

ESLint 配置只需禁用格式规则：

```javascript
// eslint.config.js
import eslintConfigPrettier from "eslint-config-prettier";

export default [eslintConfigPrettier];
```

**方案 B：lint-staged 中分别运行**

在 Git Hooks 中依次运行 Prettier 和 ESLint。

```json
{
  "lint-staged": {
    "*.{js,ts,jsx,tsx}": [
      "prettier --write",
      "eslint --fix"
    ]
  }
}
```

**方案 C：使用 eslint-plugin-prettier**

将 Prettier 集成到 ESLint 中，统一报错。

```json
{
  "extends": ["plugin:prettier/recommended"]
}
```

### 2.5 配置示例

**完整项目配置（推荐方案 A + B）：**

```
project/
├── .prettierrc           # Prettier 配置
├── eslint.config.js      # ESLint 配置（Flat Config）
├── .husky/
│   └── pre-commit        # Git Hook
├── package.json          # npm scripts + lint-staged
└── src/
```

**.prettierrc：**

```json
{
  "printWidth": 100,
  "tabWidth": 2,
  "semi": true,
  "singleQuote": true,
  "trailingComma": "es5"
}
```

**eslint.config.js：**

```javascript
import js from "@eslint/js";
import eslintConfigPrettier from "eslint-config-prettier";

export default [
  js.configs.recommended,
  eslintConfigPrettier,
  {
    rules: {
      // 只保留代码质量规则
      "no-unused-vars": "warn",
      "no-console": "warn",
    },
  },
];
```

**package.json：**

```json
{
  "scripts": {
    "prepare": "husky",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "lint": "eslint .",
    "lint:fix": "eslint --fix ."
  },
  "devDependencies": {
    "eslint": "^9.0.0",
    "eslint-config-prettier": "^10.0.0",
    "husky": "^9.0.0",
    "lint-staged": "^15.0.0",
    "prettier": "^3.0.0"
  },
  "lint-staged": {
    "*.{js,ts,jsx,tsx}": [
      "prettier --write",
      "eslint --fix"
    ],
    "*.{json,md,css,scss}": "prettier --write"
  }
}
```

## 3. Git Hooks 集成

### 3.1 husky 配置

husky 是 Node.js 项目中最流行的 Git Hooks 管理工具。

**快速安装：**

```bash
npx husky init
```

该命令自动完成：

- 安装 husky 依赖
- 创建 `.husky/` 目录
- 添加 `prepare` 脚本到 `package.json`
- 创建示例 `pre-commit` hook

**手动配置 pre-commit：**

```bash
# .husky/pre-commit
npx lint-staged
```

> 更多 husky 配置详见本仓库的 [Husky 使用指南](./husky-guide.md)。

### 3.2 lint-staged 配置

lint-staged 只对 Git 暂存区的文件运行检查，大幅提升效率。

**安装：**

```bash
npm install --save-dev lint-staged
```

**配置方式对比：**

| 配置位置              | 格式       | 适用场景       |
| --------------------- | ---------- | -------------- |
| package.json          | JSON       | 简单配置       |
| .lintstagedrc         | JSON/YAML  | 分离配置       |
| .lintstagedrc.js      | JavaScript | 复杂逻辑       |
| lint-staged.config.js | JavaScript | 复杂逻辑       |

**package.json 配置：**

```json
{
  "lint-staged": {
    "*.{js,jsx,ts,tsx}": ["prettier --write", "eslint --fix"],
    "*.{css,scss,less}": "prettier --write",
    "*.{json,md,yaml,yml}": "prettier --write"
  }
}
```

**JavaScript 配置（支持动态逻辑）：**

```javascript
// lint-staged.config.js
export default {
  // 对 JS/TS 文件运行 Prettier 和 ESLint
  "*.{js,jsx,ts,tsx}": (filenames) => [
    `prettier --write ${filenames.join(" ")}`,
    `eslint --fix ${filenames.join(" ")}`,
  ],

  // 对样式文件只运行 Prettier
  "*.{css,scss}": "prettier --write",

  // 对 package.json 排序
  "package.json": "npx sort-package-json",
};
```

### 3.3 只格式化暂存文件

lint-staged 的核心价值是只处理暂存文件，但需要注意一些细节。

**Prettier 的 --write 行为：**

```bash
# Prettier --write 会修改文件，lint-staged 自动将修改重新暂存
git add src/index.js     # 暂存文件
git commit               # 触发 pre-commit
# lint-staged 运行 prettier --write src/index.js
# 如果文件被修改，lint-staged 自动执行 git add src/index.js
```

**ESLint --fix 的注意事项：**

```javascript
// lint-staged.config.js
export default {
  // 使用 --max-warnings=0 确保警告也会导致失败
  "*.{js,ts}": ["prettier --write", "eslint --fix --max-warnings=0"],
};
```

**ESLint Flat Config 的特殊处理：**

ESLint 9+ 使用 Flat Config 时，对被 ignore 的文件会报错。需要添加 `--no-warn-ignored` 参数：

```json
{
  "lint-staged": {
    "*.js": "eslint --fix --no-warn-ignored"
  }
}
```

### 3.4 常见坑与解决方案

| 问题                       | 原因                           | 解决方案                          |
| -------------------------- | ------------------------------ | --------------------------------- |
| hook 不执行                | husky 未正确安装               | 运行 `npx husky init`             |
| 格式化后文件未暂存         | lint-staged 版本过低           | 升级到 v10+                       |
| ESLint 报 ignore 警告      | Flat Config 对 ignore 文件报错 | 添加 `--no-warn-ignored`          |
| CI 中 husky 失败           | CI 环境不需要 hooks            | 设置 `HUSKY=0` 环境变量           |
| 部分文件被跳过             | 文件不在 glob 匹配范围         | 检查 lint-staged 的 glob 配置     |
| 命令找不到 (npx)           | GUI 工具的 PATH 问题           | 配置 `~/.config/husky/init.sh`    |

**跳过 hooks 的方式：**

```bash
# 单次跳过
git commit --no-verify -m "跳过检查的提交"

# 环境变量方式
HUSKY=0 git commit -m "跳过检查的提交"
```

**CI 环境禁用 husky：**

```json
{
  "scripts": {
    "prepare": "husky || true"
  }
}
```

或者在 CI 配置中设置环境变量：

```yaml
# GitHub Actions
- run: npm ci
  env:
    HUSKY: 0
```

## 4. CI/CD 集成

### 4.1 prettier --check 模式

CI 环境使用 `--check` 参数检查代码格式，不修改文件。

**--check vs --write：**

| 参数      | 行为               | 适用环境 |
| --------- | ------------------ | -------- |
| --write   | 格式化并写入文件   | 本地开发 |
| --check   | 检查格式，不修改   | CI/CD    |
| --list-different | 列出不符合规范的文件 | 调试 |

**基本用法：**

```bash
# 检查所有文件
npx prettier --check .

# 检查特定类型
npx prettier --check "src/**/*.{js,ts,jsx,tsx}"

# 输出详细信息
npx prettier --check . --log-level warn
```

**退出码：**

| 退出码 | 含义                   |
| ------ | ---------------------- |
| 0      | 所有文件格式正确       |
| 1      | 存在格式不符合规范的文件 |
| 2      | Prettier 执行错误      |

### 4.2 GitHub Actions 配置

**基础配置：**

```yaml
# .github/workflows/lint.yml
name: Lint

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      - name: Install dependencies
        run: npm ci
        env:
          HUSKY: 0  # 跳过 husky 安装

      - name: Check formatting
        run: npm run format:check

      - name: Lint
        run: npm run lint
```

**带缓存的配置：**

```yaml
name: Lint

on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      - name: Cache ESLint
        uses: actions/cache@v4
        with:
          path: .eslintcache
          key: eslint-${{ hashFiles('**/package-lock.json') }}

      - name: Install dependencies
        run: npm ci
        env:
          HUSKY: 0

      - name: Check formatting
        run: npx prettier --check .

      - name: Lint with cache
        run: npx eslint . --cache --cache-location .eslintcache
```

**并行执行：**

```yaml
jobs:
  format:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"
      - run: npm ci
        env:
          HUSKY: 0
      - run: npx prettier --check .

  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"
      - run: npm ci
        env:
          HUSKY: 0
      - run: npx eslint .
```

### 4.3 GitLab CI 配置

**基础配置：**

```yaml
# .gitlab-ci.yml
image: node:20

stages:
  - lint

variables:
  HUSKY: "0"  # 全局禁用 husky

cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - node_modules/

lint:
  stage: lint
  script:
    - npm ci
    - npm run format:check
    - npm run lint
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

**带缓存的配置：**

```yaml
image: node:20

variables:
  HUSKY: "0"
  npm_config_cache: "$CI_PROJECT_DIR/.npm"

cache:
  key:
    files:
      - package-lock.json
  paths:
    - .npm/
    - node_modules/
    - .eslintcache

stages:
  - lint

format-check:
  stage: lint
  script:
    - npm ci --prefer-offline
    - npx prettier --check .

eslint:
  stage: lint
  script:
    - npm ci --prefer-offline
    - npx eslint . --cache --cache-location .eslintcache
```

### 4.4 错误信息解读

**Prettier --check 失败输出：**

```
Checking formatting...
[warn] src/utils/helper.js
[warn] src/components/Button.tsx
[warn] Code style issues found in 2 files. Run Prettier to fix.
```

**解读：**

| 输出内容                        | 含义                         |
| ------------------------------- | ---------------------------- |
| `[warn] src/utils/helper.js`    | 该文件格式不符合 Prettier 规范 |
| `Code style issues found in 2 files` | 共有 2 个文件需要格式化   |
| `Run Prettier to fix`           | 本地运行 `prettier --write` 修复 |

**修复步骤：**

```bash
# 1. 拉取最新代码
git pull

# 2. 本地格式化
npx prettier --write .

# 3. 提交修复
git add .
git commit -m "style: format code with prettier"
git push
```

**ESLint 错误输出：**

```
/src/index.js
  3:10  error  'unused' is defined but never used  no-unused-vars
  5:1   error  Unexpected console statement        no-console
```

**解读：**

| 输出部分     | 含义                       |
| ------------ | -------------------------- |
| `3:10`       | 第 3 行第 10 列            |
| `error`      | 错误级别（error/warning）  |
| `'unused'...`| 错误描述                   |
| `no-unused-vars` | ESLint 规则名称        |

## 5. npm scripts 规范

### 5.1 命名惯例

统一的 npm scripts 命名有助于团队协作和 CI 配置。

| 命令名称        | 作用                       | 使用场景         |
| --------------- | -------------------------- | ---------------- |
| `format`        | 格式化所有文件             | 本地开发         |
| `format:check`  | 检查格式（不修改）         | CI/CD            |
| `lint`          | 运行 ESLint 检查           | 本地/CI          |
| `lint:fix`      | ESLint 检查并自动修复      | 本地开发         |
| `check`         | 运行所有检查               | 提交前/CI        |
| `prepare`       | 安装 husky                 | npm install 后   |

**命名规范：**

1. **动词优先**：`format`、`lint`、`check`、`test`
2. **冒号分隔变体**：`format:check`、`lint:fix`
3. **保持一致**：全团队使用相同命名

### 5.2 完整配置示例

**标准项目配置：**

```json
{
  "name": "my-project",
  "scripts": {
    "prepare": "husky",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "lint": "eslint .",
    "lint:fix": "eslint --fix .",
    "check": "npm run format:check && npm run lint",
    "fix": "npm run format && npm run lint:fix"
  },
  "devDependencies": {
    "@eslint/js": "^9.0.0",
    "eslint": "^9.0.0",
    "eslint-config-prettier": "^10.0.0",
    "husky": "^9.0.0",
    "lint-staged": "^15.0.0",
    "prettier": "^3.0.0"
  },
  "lint-staged": {
    "*.{js,jsx,ts,tsx}": [
      "prettier --write",
      "eslint --fix --max-warnings=0"
    ],
    "*.{json,md,css,scss,yaml,yml}": "prettier --write"
  }
}
```

**TypeScript 项目配置：**

```json
{
  "scripts": {
    "prepare": "husky",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "lint": "eslint .",
    "lint:fix": "eslint --fix .",
    "typecheck": "tsc --noEmit",
    "check": "npm run format:check && npm run lint && npm run typecheck",
    "fix": "npm run format && npm run lint:fix"
  },
  "devDependencies": {
    "@eslint/js": "^9.0.0",
    "eslint": "^9.0.0",
    "eslint-config-prettier": "^10.0.0",
    "husky": "^9.0.0",
    "lint-staged": "^15.0.0",
    "prettier": "^3.0.0",
    "typescript": "^5.0.0",
    "typescript-eslint": "^8.0.0"
  },
  "lint-staged": {
    "*.{ts,tsx}": [
      "prettier --write",
      "eslint --fix --max-warnings=0"
    ],
    "*.{js,jsx}": [
      "prettier --write",
      "eslint --fix"
    ],
    "*.{json,md,css,scss}": "prettier --write"
  }
}
```

**Monorepo 配置（根目录）：**

```json
{
  "scripts": {
    "prepare": "husky",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "lint": "eslint packages/*/src",
    "lint:fix": "eslint --fix packages/*/src",
    "check": "npm run format:check && npm run lint"
  },
  "lint-staged": {
    "*.{js,ts,jsx,tsx}": [
      "prettier --write",
      "eslint --fix"
    ],
    "*.{json,md,css}": "prettier --write"
  }
}
```

## 6. 总结

Prettier 工具链整合的核心要点：

| 方面         | 最佳实践                                   |
| ------------ | ------------------------------------------ |
| 职责划分     | Prettier 负责格式，ESLint 负责质量         |
| 规则冲突     | 使用 eslint-config-prettier 禁用格式规则   |
| 本地检查     | husky + lint-staged 在提交前自动格式化     |
| CI 检查      | prettier --check 确保格式符合规范          |
| npm scripts  | 统一命名：format、lint、check              |
| 增量处理     | lint-staged 只处理暂存文件，提升效率       |

**推荐的工具链组合：**

```
Prettier + ESLint + eslint-config-prettier + husky + lint-staged
```

**工作流程：**

1. **开发时**：编辑器保存自动格式化
2. **提交时**：lint-staged 格式化暂存文件 + ESLint 检查
3. **推送时**：CI 运行 prettier --check + eslint

## 参考资源

- [Prettier 官方文档 - Integrating with Linters](https://prettier.io/docs/integrating-with-linters)
- [eslint-config-prettier](https://github.com/prettier/eslint-config-prettier)
- [eslint-plugin-prettier](https://github.com/prettier/eslint-plugin-prettier)
- [lint-staged](https://github.com/lint-staged/lint-staged)
- [husky](https://typicode.github.io/husky/)
- [Husky 使用指南](./husky-guide.md)
- [Prettier 基础概念与原理](./prettier-fundamentals.md)
- [Prettier 配置完全指南](./prettier-configuration.md)
