# ESLint 实战完全指南

本文档聚焦于 ESLint 在实际项目中的配置与应用，通过完整的项目案例和场景解决方案，帮助开发者快速掌握 ESLint 的实战技能。

## 1. 项目案例

### 1.1 TS + React + Vite 项目

Vite 是目前最流行的前端构建工具之一，其与 ESLint 的集成非常简单。以下是一个完整的 Vite + React + TypeScript 项目 ESLint 配置方案。

#### 1.1.1 依赖安装

首先安装项目所需的所有 ESLint 相关依赖：

```bash
// 安装 ESLint 核心包
npm install -D eslint

// 安装 TypeScript 解析器和支持
npm install -D @typescript-eslint/parser @typescript-eslint/eslint-plugin

// 安装 React 相关插件
npm install -D eslint-plugin-react eslint-plugin-react-hooks

// 安装 Prettier 用于代码格式化
npm install -D prettier eslint-config-prettier eslint-plugin-prettier

// 安装其他常用工具
npm install -D eslint-plugin-import eslint-plugin-jsx-a11y
```

#### 1.1.2 配置文件创建

在项目根目录创建 `.eslintrc.cjs` 配置文件：

```javascript
// .eslintrc.cjs
module.exports = {
  // 指定要检查的文件类型
  root: true,

  // 指定解析器：TypeScript 解析器
  parser: '@typescript-eslint/parser',

  // 解析器配置
  parserOptions: {
    // 使用 ES2022 版本的语法
    ecmaVersion: 'latest',
    // 使用 ESM 模块系统
    sourceType: 'module',
    // 支持 JSX 语法
    ecmaFeatures: {
      jsx: true
    }
  },

  // 继承的共享配置
  extends: [
    // React 相关配置
    'plugin:react/recommended',
    // React Hooks 配置
    'plugin:react-hooks/recommended',
    // TypeScript 推荐的规则（较宽松）
    'plugin:@typescript-eslint/recommended',
    // Prettier 配置（必须放在最后）
    'prettier'
  ],

  // 插件配置
  plugins: [
    '@typescript-eslint',
    'react',
    'react-hooks',
    'react-native',
    'prettier'
  ],

  // 环境配置
  env: {
    browser: true,
    es2022: true,
    node: true
  },

  // 自定义规则配置
  rules: {
    // TypeScript 相关规则
    '@typescript-eslint/no-unused-vars': [
      'warn',
      { argsIgnorePattern: '^_', varsIgnorePattern: '^_' }
    ],
    '@typescript-eslint/explicit-function-return-type': 'off',
    '@typescript-eslint/no-explicit-any': 'warn',
    '@typescript-eslint/no-non-null-assertion': 'off',

    // React 相关规则
    'react/react-in-jsx-scope': 'off',
    'react/prop-types': 'off',
    'react-hooks/rules-of-hooks': 'error',
    'react-hooks/exhaustive-deps': 'warn',

    // Prettier 规则
    'prettier/prettier': 'error',

    // 其他通用规则
    'no-console': ['warn', { allow: ['warn', 'error'] }],
    'no-debugger': 'warn'
  },

  // 全局变量配置
  globals: {
    React: 'readonly'
  },

  // 共享设置
  settings: {
    react: {
      // 自动检测 React 版本
      version: 'detect'
    },
    'import/resolver': {
      node: {
        extensions: ['.js', '.jsx', '.ts', '.tsx']
      }
    }
  }
};
```

#### 1.1.3 package.json 配置

在 `package.json` 中添加 ESLint 相关脚本：

```jsonc
// package.json
{
  "scripts": {
    // 运行 ESLint 检查
    "lint": "eslint src --ext .ts,.tsx,.js,.jsx",
    // 自动修复 ESLint 可修复的问题
    "lint:fix": "eslint src --ext .ts,.tsx,.js,.jsx --fix",
    // 同时运行 lint 和 typecheck
    "validate": "npm run lint && npm run typecheck"
  },
  // ESLint 忽略的文件
  "eslintIgnore": [
    "node_modules",
    "dist",
    "build",
    "coverage"
  ]
}
```

#### 1.1.4 VS Code 集成配置

在 `.vscode/settings.json` 中配置 VS Code 自动格式化：

```jsonc
// .vscode/settings.json
{
  // 保存时自动修复 ESLint 问题
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  },
  // 启用 ESLint 验证
  "eslint.enable": true,
  // 验证的文件类型
  "eslint.validate": [
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact"
  ],
  // 保存时使用 Prettier 格式化
  "editor.formatOnSave": true,
  // 默认格式化工具为 Prettier
  "[typescriptreact]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  }
}
```

### 1.2 TS + React + Next.js 项目

Next.js 是全栈 React 框架，有自己的 ESLint 集成方案。Next.js 14+ 内置了 ESLint 配置支持，可以直接使用 `next lint` 命令。

#### 1.2.1 初始化 ESLint 配置

在 Next.js 项目中运行以下命令初始化 ESLint：

```bash
// 使用 Next.js 内置的 ESLint 初始化
npx next lint
```

这会自动创建 `.eslintrc.json` 配置文件，并安装必要的依赖。

#### 1.2.2 完整配置文件

根据项目需求，扩展 `.eslintrc.json` 配置：

```jsonc
// .eslintrc.json
{
  // 继承 Next.js 核心规则
  "extends": [
    "next/core-web-vitals",
    "next/typescript",
    // React Hooks 规则
    "plugin:react-hooks/recommended",
    // Prettier 配置
    "prettier"
  ],

  // 自定义规则
  "rules": {
    // TypeScript 规则
    "@typescript-eslint/no-unused-vars": [
      "warn",
      { "argsIgnorePattern": "^_" }
    ],
    "@typescript-eslint/no-non-null-assertion": "off",

    // React 规则
    "react-hooks/rules-of-hooks": "error",
    "react-hooks/exhaustive-deps": "warn",
    "react/jsx-props-no-spreading": "off",
    "react/react-in-jsx-scope": "off",

    // Next.js 特定规则
    "@next/next/no-html-link-for-pages": "off",

    // Prettier 规则
    "prettier/prettier": "error",

    // 其他规则
    "no-console": ["warn", { "allow": ["warn", "error"] }]
  },

  // 插件配置
  "plugins": ["@typescript-eslint", "react-hooks", "prettier"],

  // 全局变量
  "globals": {
    "React": "readonly"
  }
}
```

#### 1.2.3 next.config.js 中的 ESLint 配置

在 Next.js 配置文件中可以添加 ESLint 相关的构建时检查：

```javascript
// next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  // 构建时检查：如果有 ESLint 错误则构建失败
  eslint: {
    // 在生产构建时运行 ESLint
    dirs: ['src'],
    // 开发时不运行以提高速度
    ignoreDuringBuilds: false
  },

  // 其他配置...
};

module.exports = nextConfig;
```

#### 1.2.4 Next.js API 路由配置

Next.js 的 API 路由也需要配置 ESLint 检查：

```javascript
// src/app/api/users/route.ts
import { NextResponse } from 'next/server';

// ✅ 正确的 API 路由写法
export async function GET() {
  const users = await fetchUsers();
  return NextResponse.json(users);
}

// ✅ 支持异步处理
export async function POST(request: Request) {
  const body = await request.json();
  const newUser = await createUser(body);
  return NextResponse.json(newUser, { status: 201 });
}

// ❌ 错误的写法：没有返回 NextResponse
export async function GET() {
  const users = await fetchUsers();
  // 缺少 return 语句
}
```

## 2. 场景解决方案

### 2.1 新项目配置

新项目配置 ESLint 时，建议采用渐进式配置策略，从基础规则开始逐步添加。

#### 2.1.1 配置步骤

以下是创建新项目 ESLint 配置的完整步骤：

```bash
# 1. 初始化 npm 项目
npm init -y

# 2. 安装 ESLint
npm install -D eslint

# 3. 初始化 ESLint 配置
npx eslint --init
```

初始化过程中选择以下选项：

- How would you like to use ESLint? → To check syntax, find problems, and enforce code style
- What type of modules does your project use? → JavaScript modules (import/export)
- Which framework does your project use? → React
- Does your project use TypeScript? → Yes
- Where does your code run? → Browser, Node
- How would you like to define a style for your project? → Use a popular style guide
- Which style guide do you want to follow? → Airbnb (或 Google、Standard)
- What format do you want your config file to be in? → JavaScript

#### 2.1.2 推荐的规则集

新项目推荐使用以下规则集组合：

| 规则集               | 适用场景     | 特点                     |
| -------------------- | ------------ | ------------------------ |
| `eslint:recommended` | 通用项目     | 基础规则，问题导向       |
| `airbnb`             | 追求代码质量 | 严格，详细               |
| `airbnb-typescript`  | TS 项目      | Airbnb + TypeScript 支持 |
| `standard`           | 喜欢简洁风格 | 无分号，双引号           |
| `prettier`           | 格式化优先   | 配合 Prettier 使用       |

#### 2.1.3 TypeScript 项目推荐配置

对于 TypeScript 项目，推荐使用以下配置组合：

```javascript
// .eslintrc.cjs
module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
    ecmaFeatures: { jsx: true },
    // 指定项目根目录
    project: './tsconfig.json'
  },
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:@typescript-eslint/recommended-requiring-type-checking',
    'prettier'
  ],
  plugins: ['@typescript-eslint', 'prettier'],
  rules: {
    // 开启类型检查规则
    '@typescript-eslint/explicit-function-return-type': 'off',
    '@typescript-eslint/explicit-module-boundary-types': 'off',
    '@typescript-eslint/no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
    '@typescript-eslint/no-explicit-any': 'warn',
    '@typescript-eslint/no-unsafe-call': 'warn',
    '@typescript-eslint/no-unsafe-member-access': 'warn',
    '@typescript-eslint/no-unsafe-assignment': 'warn',
    // Prettier
    'prettier/prettier': 'error'
  },
  env: {
    browser: true,
    es2022: true,
    node: true
  }
};
```

#### 2.1.4 Monorepo 项目配置

对于使用 Monorepo 结构（如 pnpm workspaces）的项目，ESLint 配置需要特别注意：

```javascript
// 根目录 .eslintrc.cjs
module.exports = {
  root: true,
  ignorePatterns: ['**/node_modules/**', '**/dist/**', '**/build/**'],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module'
  },
  extends: ['eslint:recommended'],
  // 各个子包可以有自己的配置
  overrides: [
    {
      files: ['packages/*/src/**/*.{ts,tsx}'],
      parser: '@typescript-eslint/parser',
      extends: [
        'plugin:@typescript-eslint/recommended',
        'prettier'
      ],
      plugins: ['@typescript-eslint', 'prettier']
    }
  ]
};
```

### 2.2 旧项目迁移

旧项目迁移 ESLint 需要谨慎处理，逐步引入避免影响开发效率。

#### 2.2.1 迁移策略

旧项目迁移建议采用以下策略：

| 阶段     | 时间    | 目标                                        |
| -------- | ------- | ------------------------------------------- |
| 第一阶段 | 第1周   | 安装依赖，创建基础配置，将所有规则设为 warn |
| 第二阶段 | 第2周   | 修复高优先级问题，将部分规则改为 error      |
| 第三周   | 第3-4周 | 修复剩余问题，严格规则配置                  |
| 第四阶段 | 持续    | 持续监控，添加新规则                        |

#### 2.2.2 第一阶段：基础配置

首先创建宽松的 ESLint 配置，将大部分规则设为警告而非错误：

```javascript
// .eslintrc.cjs - 迁移初期使用
module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
    project: './tsconfig.json'
  },
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'prettier'
  ],
  plugins: ['@typescript-eslint', 'prettier'],
  rules: {
    // ✅ 将所有规则先设为 warn，允许团队渐进式修复
    '@typescript-eslint/no-unused-vars': 'warn',
    '@typescript-eslint/no-explicit-any': 'warn',
    '@typescript-eslint/no-unsafe-call': 'warn',
    '@typescript-eslint/no-unsafe-member-access': 'warn',
    '@typescript-eslint/no-unsafe-assignment': 'warn',
    'no-console': 'off',
    'prettier/prettier': 'warn',
    // 关闭一些过于严格的规则
    '@typescript-eslint/explicit-function-return-type': 'off',
    '@typescript-eslint/explicit-module-boundary-types': 'off',
    '@typescript-eslint/no-unnecessary-type-assertion': 'off'
  },
  env: {
    browser: true,
    es2022: true,
    node: true
  }
};
```

#### 2.2.3 第二阶段：问题修复

创建修复脚本批量处理常见问题：

```bash
# 创建修复脚本
cat > scripts/lint-fix.sh << 'EOF'
#!/bin/bash
# 自动修复 ESLint 可自动修复的问题

echo "开始修复 ESLint 问题..."

# 运行 ESLint 自动修复
npx eslint src --ext .ts,.tsx,.js,.jsx --fix

# 检查是否有未修复的问题
npx eslint src --ext .ts,.tsx,.js,.jsx

echo "修复完成，请检查未修复的问题"
EOF

chmod +x scripts/lint-fix.sh
```

#### 2.2.4 常见迁移问题与解决方案

以下是旧项目迁移过程中常见的问题及解决方案：

**问题1：大量 `no-unused-vars` 错误**

这是最常见的问题。可以使用以下策略：

```javascript
// 临时配置允许未使用的变量
rules: {
  '@typescript-eslint/no-unused-vars': [
    'warn',
    {
      // 忽略以下划线开头的变量
      argsIgnorePattern: '^_',
      varsIgnorePattern: '^_',
      // 忽略回调函数的第二个参数
      caughtErrorsIgnorePattern: '^_'
    }
  ]
}
```

**问题2：`no-explicit-any` 过多**

类型标注工作量太大时，可以暂时放宽规则：

```javascript
rules: {
  // 暂时允许 any 类型
  '@typescript-eslint/no-explicit-any': 'off',
  // 或者只对函数返回值进行检查
  '@typescript-eslint/explicit-function-return-type': [
    'warn',
    { allowExpressions: true }
  ]
}
```

**问题3：第三方库类型问题**

对于第三方库的类型问题，可以使用 `eslint-disable` 注释：

```typescript
// eslint-disable-next-line @typescript-eslint/no-unsafe-call
result.someMethod();

// 禁用某个文件的特定规则
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
const value = obj?.property?.nested;
/* eslint-enable @typescript-eslint/no-unsafe-member-access */
```

**问题4：React PropTypes 问题**

如果项目使用 TypeScript，不需要 PropTypes：

```javascript
rules: {
  // 关闭 PropTypes 检查
  'react/prop-types': 'off',
  // 关闭 React 相关但不必要的规则
  'react/react-in-jsx-scope': 'off',
  'react/display-name': 'off'
}
```

#### 2.2.5 渐进式严格化配置

随着团队逐渐适应，可以逐步严格化规则配置：

```javascript
// .eslintrc.cjs - 迁移后期使用
module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
    project: './tsconfig.json'
  },
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:@typescript-eslint/recommended-requiring-type-checking',
    'prettier'
  ],
  plugins: ['@typescript-eslint', 'prettier'],
  rules: {
    // ✅ 第二阶段：将部分规则改为 error
    '@typescript-eslint/no-unused-vars': 'error',
    'prettier/prettier': 'error',

    // ⚠️ 保持部分规则为 warn
    '@typescript-eslint/no-explicit-any': 'warn',
    '@typescript-eslint/no-unsafe-call': 'warn',

    // 严格规则
    '@typescript-eslint/no-unsafe-assignment': 'error',
    '@typescript-eslint/no-unsafe-member-access': 'error',
    '@typescript-eslint/no-unsafe-return': 'error',

    // 关闭不需要的规则
    '@typescript-eslint/explicit-function-return-type': 'off',
    '@typescript-eslint/explicit-module-boundary-types': 'off'
  },
  env: {
    browser: true,
    es2022: true,
    node: true
  }
};
```

## 3. 配置解读

### 3.1 配置文件优先级

ESLint 会按照以下优先级查找配置文件：

| 优先级 | 配置文件         | 说明                          |
| ------ | ---------------- | ----------------------------- |
| 1      | `.eslintrc.cjs`  | CommonJS 格式                 |
| 2      | `.eslintrc.js`   | JavaScript 格式               |
| 3      | `.eslintrc.json` | JSON 格式（ESLint 8+ 不推荐） |
| 4      | `.eslintrc.yaml` | YAML 格式                     |
| 5      | `.eslintrc.yml`  | YAML 格式                     |
| 6      | `package.json`   | 在 package.json 中定义        |

ESLint 还会向上查找父目录的配置，直到找到 `root: true` 的配置为止。

### 3.2 解析器配置

解析器配置决定了 ESLint 如何理解代码：

```javascript
{
  parser: '@typescript-eslint/parser',
  parserOptions: {
    // ECMAScript 版本
    ecmaVersion: 'latest', // 或具体版本如 2022
    // 模块类型：script 或 module
    sourceType: 'module',
    // JSX 配置
    ecmaFeatures: {
      jsx: true
    },
    // TypeScript 项目配置
    project: './tsconfig.json',
    // 指定要检查的文件路径
    files: ['src/**/*.ts', 'src/**/*.tsx']
  }
}
```

### 3.3 继承配置

`extends` 字段可以继承已有的配置，减少重复配置：

| 继承类型 | 示例                         | 说明             |
| -------- | ---------------------------- | ---------------- |
| 字符串   | `'eslint:recommended'`       | 继承内置配置     |
| 插件配置 | `'plugin:react/recommended'` | 继承插件推荐配置 |
| npm 包   | `'airbnb'`                   | 继承第三方配置   |
| 相对路径 | `'./.eslintrc.base'`         | 继承本地配置     |

### 3.4 规则详解

ESLint 规则配置格式：

```javascript
rules: {
  // 1. 关闭规则
  'rule-name': 'off',

  // 2. 警告级别
  'rule-name': 'warn',

  // 3. 错误级别
  'rule-name': 'error',

  // 4. 带选项配置
  'rule-name': ['error', { option1: value1, option2: value2 }],

  // 5. 严重级别 + 自定义选项
  'rule-name': ['warn', 'single', { avoidEscape: true }]
}
```

### 3.5 插件配置

插件需要在 `plugins` 和 `rules` 中同时配置：

```javascript
{
  plugins: ['react', 'react-hooks'],
  rules: {
    // 使用插件中的规则，需要加插件前缀
    'react/jsx-uses-react': 'error',
    'react-hooks/rules-of-hooks': 'error',
    'react-hooks/exhaustive-deps': 'warn'
  }
}
```

## 4. 最佳实践

### 4.1 项目结构建议

推荐的项目 ESLint 文件结构：

```
my-project/
├── .eslintrc.cjs          # 主配置文件
├── .eslintignore          # 忽略文件配置
├── .vscode/
│   └── settings.json      # VS Code 集成配置
├── package.json
├── tsconfig.json
├── prettier.config.js     # Prettier 配置
└── src/
    └── ...
```

### 4.2 规则组织建议

将规则按功能分类组织：

```javascript
module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'prettier'
  ],
  plugins: ['@typescript-eslint', 'prettier'],
  rules: {
    // === TypeScript 规则 ===
    '@typescript-eslint/no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
    '@typescript-eslint/no-explicit-any': 'warn',

    // === 代码风格规则 ===
    'prettier/prettier': 'error',
    'no-console': ['warn', { allow: ['warn', 'error'] }],

    // === 安全规则 ===
    'no-eval': 'error',
    'no-implied-eval': 'error'
  }
};
```

### 4.3 Git Hooks 集成

使用 Git Hooks 在提交前自动检查代码：

```bash
# 安装 lint-staged 和 husky
npm install -D lint-staged husky
```

在 `package.json` 中配置：

```jsonc
{
  "lint-staged": {
    // 在提交前检查 TypeScript 和 TypeScriptX 文件
    "*.{ts,tsx}": [
      "eslint --fix",
      "eslint --max-warnings=0"
    ],
    "*.{js,jsx}": [
      "eslint --fix"
    ]
  },
  "husky": {
    "hooks": {
      // 提交前运行 lint-staged
      "pre-commit": "lint-staged"
    }
  }
}
```

### 4.4 CI/CD 集成

在 CI/CD 流程中运行 ESLint：

```yaml
# .github/workflows/lint.yml
name: ESLint

on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run ESLint
        run: npm run lint

      - name: Run type check
        run: npm run typecheck
```

### 4.5 性能优化

对于大型项目，可以采用以下优化策略：

| 优化策略     | 说明                         | 实施方法                     |
| ------------ | ---------------------------- | ---------------------------- |
| 增量检查     | 只检查改动的文件             | 使用 `--cache` 参数          |
| 并行执行     | 使用多核CPU                  | 使用 `eslint . --parallel`   |
| 类型检查优化 | 限制 TypeScript 类型检查范围 | 配置 `parserOptions.project` |
| 忽略构建目录 | 不检查构建产物               | 配置 `.eslintignore`         |

```bash
# 使用缓存加速
npx eslint src --cache

# 只检查改动的文件（配合 Git）
npx eslint --cache --diff $(git diff --name-only HEAD)
```

## 5. 总结

ESLint 实战的核心要点：

| 方面         | 关键点                                            |
| ------------ | ------------------------------------------------- |
| **配置选择** | 新项目推荐 TypeScript + React + Prettier 组合配置 |
| **迁移策略** | 旧项目采用渐进式迁移，先 warn 后 error            |
| **工具集成** | 配合 VS Code、Git Hooks、CI/CD 使用效果最佳       |
| **规则管理** | 按功能分类组织规则，保持配置简洁                  |
| **性能优化** | 使用缓存、增量检查优化大型项目                    |

最佳实践速查表：

- 始终在 `extends` 中添加 `prettier` 作为最后一个配置
- 使用 `--cache` 参数提高检查速度
- 将 ESLint 与 TypeScript、Prettier 配合使用
- 在 CI/CD 流程中包含 ESLint 检查
- 使用 Git Hooks 确保提交代码符合规范
- 旧项目迁移时采用渐进式策略，避免一刀切

## 参考资源

- [ESLint 官方文档](https://eslint.org/)
- [TypeScript ESLint 官方文档](https://typescript-eslint.io/)
- [ESLint 配置详解](https://eslint.org/docs/latest/user-guide/configuring/)
- [Airbnb JavaScript 风格指南](https://github.com/airbnb/javascript)
- [ESLint 规则列表](https://eslint.org/docs/latest/rules/)
- [Prettier 与 ESLint 集成](https://prettier.io/docs/en/integrating-with-linters.html)
- [ESLint vs Prettier 区别](https://www.youtube.com/watch?v=Syd8TkcV4W8)
