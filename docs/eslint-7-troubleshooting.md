# ESLint 问题排查完全指南

本文档详细介绍 ESLint 配置与使用过程中常见问题的排查方法，涵盖规则不生效、配置冲突、性能优化、Monorepo 架构等核心场景。

## 1. 规则不生效

规则不生效是 ESLint 使用中最常见的问题，主要原因包括配置优先级、文件范围、插件加载等方面。

### 1.1 配置优先级

ESLint 配置存在优先级机制，理解优先级是解决问题的关键。

#### 优先级从高到低

| 优先级 | 配置来源                        | 说明                                 |
| ------ | ------------------------------- | ------------------------------------ |
| 1      | 命令行 `--rule` 参数            | 最高优先级，直接覆盖配置文件中的规则 |
| 2      | `.eslintrc.*` 中的 `rules` 字段 | 当前项目配置文件定义的规则           |
| 3      | `.eslintignore` 排除的文件      | 通过忽略文件绕过检查                 |
| 4      | 继承的配置（`extends`）         | 继承的配置优先级较低                 |

#### 根目录配置检测

ESLint 会从文件所在目录向上查找配置文件，直到根目录：

```text
// 目录结构
project/
├── .eslintrc.json          // 根目录配置
└── src/
    └── components/
        └── Button.jsx      // 在此文件中检查

// ESLint 查找顺序：Button.jsx → components → src → project
// 找到的第一个 .eslintrc.json 即为使用的配置
```

#### 常见优先级问题

**场景：命令行规则不生效**

```bash
# ❌ 错误：规则写在命令行后面
npx eslint src --ext .js --rule "no-console: off"

# ✅ 正确：规则选项在其他参数之前
npx eslint --rule "no-console: off" src --ext .js
```

**场景：本地配置覆盖继承配置**

```javascript
// .eslintrc.js
module.exports = {
  extends: ['eslint:recommended'], // 继承推荐规则
  rules: {
    'no-console': 'warn', // ✅ 覆盖继承的规则
    'no-unused-vars': 'error' // ✅ 添加新规则
  }
};
```

### 1.2 files 范围

ESLint 9 采用 Flat Config 后，`files` 字段定义需要检查的文件范围。

#### files 配置基本语法

```javascript
// eslint.config.js
export default [
  {
    files: ['**/*.js', '**/*.jsx'], // 需要检查的文件模式
    rules: {
      'no-console': 'error'
    }
  },
  {
    files: ['**/*.ts', '**/*.tsx'], // TypeScript 文件单独配置
    rules: {
      'no-unused-vars': 'error'
    }
  }
];
```

#### files 配置常见问题

| 问题现象             | 原因                     | 解决方案                       |
| -------------------- | ------------------------ | ------------------------------ |
| 规则对某些文件不生效 | `files` 模式未匹配该文件 | 检查文件路径是否符合 glob 模式 |
| 所有文件都应用了规则 | 未限制 `files` 范围      | 添加明确的 `files` 配置        |
| 嵌套目录文件未被检查 | 默认只检查 `src` 目录    | 调整 glob 模式包含目标目录     |

#### glob 模式详解

```javascript
// eslint.config.js
export default [
  // ✅ 匹配 src 目录下所有 .js 文件
  {
    files: ['src/**/*.js'],
    rules: { 'no-console': 'error' }
  },

  // ✅ 匹配 src 和 packages 目录下的 .js 文件
  {
    files: ['src/**/*.js', 'packages/**/*.js'],
    rules: { 'no-console': 'error' }
  },

  // ❌ 错误：缺少 ** 无法匹配深层目录
  {
    files: ['src/*.js'], // 只匹配 src 根目录的 js 文件
    rules: { 'no-console': 'error' }
  },

  // ✅ 排除 node_modules
  {
    files: ['**/*.js', '!**/node_modules/**/*.js'],
    rules: { 'no-console': 'error' }
  }
];
```

### 1.3 插件加载

ESLint 插件提供额外的规则和配置，插件加载失败会导致规则不生效。

#### Flat Config 插件加载

```javascript
// eslint.config.js
import js from '@eslint/js';
import reactPlugin from 'eslint-plugin-react';
import reactHooksPlugin from 'eslint-plugin-react-hooks';
import tseslint from 'typescript-eslint';

export default [
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ['**/*.{js,jsx,ts,tsx}'],
    plugins: {
      react: reactPlugin,
      'react-hooks': reactHooksPlugin
    },
    rules: {
      'react/react-in-jsx-scope': 'error',
      'react-hooks/rules-of-hooks': 'error'
    }
  }
];
```

#### 插件加载问题排查

| 问题现象                                  | 可能原因       | 解决方案                             |
| ----------------------------------------- | -------------- | ------------------------------------ |
| `Cannot find module 'eslint-plugin-xxx'`  | 插件未安装     | 执行 `npm install eslint-plugin-xxx` |
| `Definition for rule 'xxx' was not found` | 插件未正确加载 | 检查 plugins 配置是否正确            |
| 规则提示未知                              | 插件版本不兼容 | 升级 ESLint 或插件版本               |

#### 检查插件是否正确加载

```javascript
// eslint.config.js
import somePlugin from 'eslint-plugin-some';

export default [
  {
    files: ['**/*.js'],
    plugins: {
      some: somePlugin // ✅ 正确：作为对象属性
    },
    rules: {
      'some/rule-name': 'error'
    }
  }
];
```

#### 常见插件配置错误

```javascript
// ❌ 错误：插件名称缺少前缀
{
  plugins: ['react'], // 应该使用对象形式
  rules: { 'react/xxx': 'error' }
}

// ✅ 正确：使用对象形式
{
  plugins: {
    react: reactPlugin
  },
  rules: { 'react/xxx': 'error' }
}
```

## 2. 配置冲突

配置冲突主要包括 ESLint 规则之间的冲突以及与 Prettier 格式化工具的冲突。

### 2.1 ESLint 规则冲突

某些规则之间存在逻辑冲突，同时启用会导致问题。

#### 常见冲突规则

| 冲突规则                                      | 原因                               | 解决方案                 |
| --------------------------------------------- | ---------------------------------- | ------------------------ |
| `no-unused-vars` vs `no-underscore-dangle`    | 允许下划线开头的变量但不允许未使用 | 调整规则配置             |
| `complexity` vs `max-statements`              | 两者都限制代码复杂度               | 选择其一或调整阈值       |
| `import/named` vs TypeScript `no-unused-vars` | 导入类型与使用检测冲突             | 使用 TypeScript 特定配置 |

#### 解决规则冲突

```javascript
// .eslintrc.js
module.exports = {
  rules: {
    // ✅ 解决 no-unused-vars 与下划线变量的冲突
    'no-unused-vars': ['error', {
      argsIgnorePattern: '^_', // 以下划线开头的参数不检查
      varsIgnorePattern: '^_'  // 以下划线开头的变量不检查
    }],

    // ✅ 解决 import/named 与类型导入的冲突
    'import/named': ['error', {
      commonjs: true
    }]
  }
};
```

### 2.2 Prettier 冲突

ESLint 与 Prettier 的冲突是最常见的配置问题，因为两者都会处理代码格式但方式不同。

#### 冲突原因

| 工具     | 职责            | 冲突类型                         |
| -------- | --------------- | -------------------------------- |
| ESLint   | 代码质量 + 格式 | 格式规则与 Prettier 重叠         |
| Prettier | 代码格式化      | 强制格式化与 ESLint 格式规则冲突 |

#### 解决 Prettier 冲突

**步骤 1：安装 eslint-config-prettier**

```bash
npm install --save-dev eslint-config-prettier
```

**步骤 2：在配置中引入**

```javascript
// .eslintrc.js
module.exports = {
  extends: [
    'eslint:recommended',
    'plugin:react/recommended',
    'prettier' // ✅ 必须是最后一个，关闭与 Prettier 冲突的规则
  ],
  plugins: ['react', 'prettier'],
  rules: {
    'prettier/prettier': 'error' // 将 Prettier 问题作为 ESLint 错误报告
  }
};
```

#### Flat Config 中集成 Prettier

```javascript
// eslint.config.js
import js from '@eslint/js';
import reactPlugin from 'eslint-plugin-react';
import prettier from 'eslint-plugin-prettier';
import eslintConfigPrettier from 'eslint-config-prettier';

export default [
  js.configs.recommended,
  {
    files: ['**/*.{js,jsx}'],
    plugins: {
      react: reactPlugin,
      prettier: prettier
    },
    rules: {
      'prettier/prettier': 'error',
      ...eslintConfigPrettier.rules // 关闭冲突规则
    }
  }
];
```

#### 常见 Prettier 冲突规则

以下规则需要通过 `eslint-config-prettier` 关闭：

| 需要关闭的规则                     | 说明                             |
| ---------------------------------- | -------------------------------- |
| `indent`                           | 缩进由 Prettier 管理             |
| `quotes`                           | 引号风格由 Prettier 管理         |
| `semi`                             | 分号由 Prettier 管理             |
| `comma-dangle`                     | 尾随逗号由 Prettier 管理         |
| `arrow-spacing`                    | 箭头函数空格由 Prettier 管理     |
| `block-spacing`                    | 块级空格由 Prettier 管理         |
| `brace-style`                      | 大括号风格由 Prettier 管理       |
| `camelcase`                        | 驼峰命名由 Prettier 管理         |
| `capitalized-comments`             | 注释大小写由 Prettier 管理       |
| `comma-style`                      | 逗号风格由 Prettier 管理         |
| `computed-property-spacing`        | 计算属性空格由 Prettier 管理     |
| `func-call-spacing`                | 函数调用空格由 Prettier 管理     |
| `function-paren-spacing`           | 函数括号空格由 Prettier 管理     |
| `implicit-arrow-linebreak`         | 隐式箭头换行由 Prettier 管理     |
| `jsx-quotes`                       | JSX 引号由 Prettier 管理         |
| `key-spacing`                      | 键值空格由 Prettier 管理         |
| `keyword-spacing`                  | 关键字空格由 Prettier 管理       |
| `max-len`                          | 最大行长度由 Prettier 管理       |
| `multiline-ternary`                | 多行三元表达式由 Prettier 管理   |
| `no-confusing-arrow`               | 箭头函数歧义由 Prettier 管理     |
| `no-extra-parheses`                | 额外括号由 Prettier 管理         |
| `no-extra-semi`                    | 额外分号由 Prettier 管理         |
| `no-floating-decimal`              | 浮动小数点由 Prettier 管理       |
| `no-mixed-operators`               | 混合运算符由 Prettier 管理       |
| `no-mixed-spaces-and-tabs`         | 混合空格和制表符由 Prettier 管理 |
| `no-multi-spaces`                  | 多余空格由 Prettier 管理         |
| `no-multiple-empty-lines`          | 多行空行由 Prettier 管理         |
| `no-tab`                           | 制表符由 Prettier 管理           |
| `no-trailing-spaces`               | 尾随空格由 Prettier 管理         |
| `no-whitespace-before-property`    | 属性前空格由 Prettier 管理       |
| `nonblock-statement-body-position` | 语句体位置由 Prettier 管理       |
| `object-curly-spacing`             | 对象大括号空格由 Prettier 管理   |
| `object-curly-newline`             | 对象大括号换行由 Prettier 管理   |
| `one-var-declaration-per-line`     | 变量声明每行由 Prettier 管理     |
| `operator-linebreak`               | 操作符换行由 Prettier 管理       |
| `padded-blocks`                    | 块级填充由 Prettier 管理         |
| `padding-line-between-statements`  | 语句间填充由 Prettier 管理       |
| `quote-props`                      | 属性引号由 Prettier 管理         |
| `rest-spread-spacing`              | 剩余/扩展空格由 Prettier 管理    |
| `semi-spacing`                     | 分号空格由 Prettier 管理         |
| `semi-style`                       | 分号风格由 Prettier 管理         |
| `space-before-blocks`              | 块前空格由 Prettier 管理         |
| `space-before-function-paren`      | 函数括号前空格由 Prettier 管理   |
| `space-in-parens`                  | 括号内空格由 Prettier 管理       |
| `space-infix-ops`                  | 中缀操作符空格由 Prettier 管理   |
| `space-unary-ops`                  | 一元操作符空格由 Prettier 管理   |
| `switch-colon-spacing`             | switch 冒号空格由 Prettier 管理  |
| `template-tag-spacing`             | 模板标签空格由 Prettier 管理     |
| `wrap-iife`                        | IIFE 包装由 Prettier 管理        |
| `wrap-regex`                       | 正则包装由 Prettier 管理         |

## 3. 性能问题

ESlint 检查大量文件时可能变慢，通过缓存和分析工具可以显著提升性能。

### 3.1 缓存使用

缓存可以避免重新检查未修改的文件，大幅提升检查速度。

#### 启用缓存

```bash
# 启用缓存
npx eslint --cache src

# 查看缓存文件
ls -la .eslintcache
```

#### 缓存配置

```javascript
// .eslintrc.js
module.exports = {
  // 缓存选项
  cache: true,
  cacheLocation: '.eslintcache', // 缓存文件位置

  // 其他性能选项
  fix: true, // 自动修复
  fixDepth: 1 // 修复深度，避免修改过多文件
};
```

#### Flat Config 缓存配置

```javascript
// eslint.config.js
export default [
  {
    files: ['**/*.js'],
    languageOptions: {
      sourceType: 'module'
    },
    // 缓存配置在命令行设置，配置文件中不支持
  }
];
```

#### 缓存最佳实践

| 场景     | 建议                     |
| -------- | ------------------------ |
| 首次运行 | 不使用缓存，全量检查     |
| 后续运行 | 启用缓存，只检查修改文件 |
| CI 环境  | 启用缓存，提交缓存文件   |
| 清理缓存 | 删除 `.eslintcache` 文件 |

### 3.2 TIMING 分析

ESLint 提供内置的计时分析功能，帮助定位性能瓶颈。

#### 使用 TIMING 选项

```bash
# 查看各规则执行时间
npx eslint --timing src --format json -o timing.json

# 简单输出
npx eslint --timing src
```

#### 输出格式示例

```
Rule | Time (ms) | Percentage
------------------------------
no-unused-vars | 1250.5 | 45.2%
indent | 680.3 | 24.6%
quotes | 320.1 | 11.6%
...
```

#### 分析结果优化

根据 TIMING 结果，可以采取以下优化措施：

| 慢规则类型       | 优化方案                               |
| ---------------- | -------------------------------------- |
| `no-unused-vars` | 对不常修改的文件启用缓存               |
| `import/*`       | 使用 `eslint-import-resolver` 优化解析 |
| `react/*`        | 确保使用正确的配置文件                 |

#### 使用 esbuild 加速解析

```bash
# 安装 esbuild
npm install --save-dev esbuild

# 使用 esbuild 作为解析器
npx eslint --parser-options=ecmaVersion:latest,sourceType:module --no-eslintrc -c eslint.config.js src
```

## 4. Monorepo 配置

在 Monorepo 架构中使用 ESLint 需要特别处理根目录配置与包级别覆盖的关系。

### 4.1 根目录配置

Monorepo 通常在根目录有一个统一的 ESLint 配置。

#### 根目录配置文件

```javascript
// eslint.config.js (根目录)
import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import react from 'eslint-plugin-react';
import globals from 'globals';

export default [
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    ignores: ['dist/**', 'node_modules/**', 'packages/*/dist/**']
  },
  {
    files: ['**/*.js', '**/*.ts', '**/*.tsx'],
    plugins: {
      react: react
    },
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node
      }
    },
    rules: {
      'no-console': 'warn',
      'no-unused-vars': 'error'
    }
  }
];
```

#### 工作区配置

```json
// package.json
{
  "name": "my-monorepo",
  "workspaces": [
    "packages/*"
  ],
  "scripts": {
    "lint": "eslint .",
    "lint:packages": "eslint packages/*"
  }
}
```

### 4.2 包级别覆盖

在 Monorepo 中，不同包可能需要不同的 ESLint 配置。

#### 包级别配置继承

```javascript
// packages/web/eslint.config.js
import baseConfig from '../../eslint.config.js';

export default [
  ...baseConfig,
  {
    files: ['**/*.js', '**/*.jsx'],
    rules: {
      // Web 包特定规则
      'react/react-in-jsx-suffix': 'error'
    }
  }
];
```

#### 覆盖根目录规则

```javascript
// packages/node-service/eslint.config.js
import baseConfig from '../../eslint.config.js';

export default [
  ...baseConfig,
  {
    files: ['**/*.js'],
    rules: {
      // Node.js 服务禁用浏览器全局变量
      'no-undef': ['error', { browser: false, node: true }]
    }
  }
];
```

#### 包级别忽略文件

```javascript
// packages/web/eslint.config.js
export default [
  {
    files: ['**/*.js'],
    ignores: ['dist/**/*.js', 'build/**/*.js'], // 忽略构建输出
    rules: {
      'no-console': 'error'
    }
  }
];
```

#### Monorepo 完整配置示例

```text
my-monorepo/
├── eslint.config.js          // 根目录配置
├── package.json
└── packages/
    ├── web/
    │   ├── eslint.config.js  // Web 包配置
    │   ├── src/
    │   └── package.json
    ├── shared/
    │   ├── eslint.config.js  // 共享包配置
    │   ├── src/
    │   └── package.json
    └── node-service/
        ├── eslint.config.js  // Node 服务配置
        ├── src/
        └── package.json
```

```javascript
// packages/shared/eslint.config.js
import baseConfig from '../../eslint.config.js';

export default [
  ...baseConfig,
  {
    files: ['**/*.ts'],
    rules: {
      // 共享包不允许 console
      'no-console': 'error',
      // 强制导出类型
      'import/consistent-type-specifier': 'error'
    }
  }
];
```

## 5. 故障案例

本节通过实际故障案例展示问题排查思路。

### 案例一：规则在 CI 环境不生效

**问题描述**

开发环境运行 `npx eslint .` 正常，但在 CI 环境中有错误未被检测。

**排查步骤**

1. 检查 CI 环境的 ESLint 版本
2. 检查 CI 的 Node.js 版本差异
3. 检查 CI 是否使用了缓存

```yaml
# .github/workflows/lint.yml
- name: Run ESLint
  run: |
    npm ci
    npx eslint . --cache # ❌ 使用缓存但未清理旧缓存
```

**解决方案**

```yaml
# .github/workflows/lint.yml
- name: Run ESLint
  run: |
    npm ci
    rm -f .eslintcache  # 清理旧缓存
    npx eslint .
```

### 案例二：Prettier 格式与 ESLint 冲突

**问题描述**

运行 `npx eslint --fix` 后代码格式被破坏，与 Prettier 预期不符。

**排查步骤**

1. 检查是否有 `eslint-config-prettier`
2. 检查 `extends` 中 `prettier` 是否在最后
3. 检查是否有重复的格式规则

**解决方案**

```javascript
// .eslintrc.js
module.exports = {
  extends: [
    'eslint:recommended',
    'plugin:react/recommended',
    'prettier' // ✅ 必须在最后
  ],
  plugins: ['react', 'prettier'],
  rules: {
    'prettier/prettier': 'error' // 将格式化问题作为 ESLint 错误
  }
};
```

### 案例三：Monorepo 中某些包规则不生效

**问题描述**

packages 目录下的某个子包 ESLint 规则未生效。

**排查步骤**

1. 检查该包是否有独立的 `eslint.config.js`
2. 检查根目录配置是否包含该包路径
3. 检查是否被 `.eslintignore` 忽略

**解决方案**

```javascript
// eslint.config.js (根目录)
export default [
  {
    files: ['packages/*/src/**/*.js'], // ✅ 明确包含所有包
    rules: {
      'no-unused-vars': 'error'
    }
  }
];
```

### 案例四：插件规则显示未知

**问题描述**

配置了 `eslint-plugin-react` 但规则提示未知错误。

**排查步骤**

1. 确认插件已安装
2. 检查插件是否正确导入
3. 检查规则名称是否带插件前缀

```javascript
// ❌ 错误配置
{
  plugins: ['react'],
  rules: {
    'react-in-jsx-scope': 'error' // 缺少前缀
  }
}

// ✅ 正确配置
{
  plugins: { react: reactPlugin },
  rules: {
    'react/react-in-jsx-scope': 'error' // 带前缀
  }
}
```

### 案例五：Git Hooks 中 ESLint 执行失败

**问题描述**

husky 预提交钩子中 ESLint 报错导致提交失败。

**排查步骤**

1. 检查 husky 钩子执行的命令
2. 检查 Node 路径是否正确
3. 检查依赖是否已安装

```bash
# .husky/pre-commit
npm run lint # ❌ 可能使用不同 Node 环境

# ✅ 使用 npx 确保使用本地 ESLint
npx eslint .
```

### 案例六：TypeScript 类型检查规则不生效

**问题描述**

配置了 `typescript-eslint` 但 `@typescript-eslint/no-unused-vars` 规则未生效。

**排查步骤**

1. 确认安装了 `typescript-eslint`
2. 检查配置是否使用 TypeScript 解析器
3. 检查 parserOptions 配置

```javascript
// ❌ 错误配置
{
  parser: '@typescript-eslint/parser', // 缺少正确的配置
  rules: {
    '@typescript-eslint/no-unused-vars': 'error'
  }
}

// ✅ 正确配置
{
  languageOptions: {
    parser: tseslint.parser,
    parserOptions: {
      project: './tsconfig.json' // 需要指定项目
    }
  },
  rules: {
    '@typescript-eslint/no-unused-vars': 'error'
  }
}
```

## 6. 总结

### 核心要点

| 类别       | 要点                                     |
| ---------- | ---------------------------------------- |
| 规则不生效 | 检查配置优先级、files 范围、插件加载     |
| 配置冲突   | 使用 eslint-config-prettier 关闭冲突规则 |
| 性能优化   | 启用缓存、使用 TIMING 分析               |
| Monorepo   | 根目录统一配置、包级别覆盖继承           |

### 速查表

| 问题          | 检查项                     | 快速解决方案             |
| ------------- | -------------------------- | ------------------------ |
| 规则不生效    | 配置文件位置、extends 顺序 | 确认配置文件在项目根目录 |
| 文件未检查    | files glob 模式            | 使用正确的 glob 模式     |
| Prettier 冲突 | extends 中 prettier 位置   | 放在 extends 最后        |
| 性能慢        | 是否启用缓存               | 添加 `--cache` 参数      |
| 插件不工作    | 插件安装、导入方式         | 检查 npm 包是否安装      |
| Monorepo 问题 | 包级别配置继承             | 使用展开运算符合并配置   |
| CI 环境问题   | Node 版本、缓存状态        | 清理缓存、锁定版本       |

### 调试命令

```bash
# 查看 ESLint 配置
npx eslint --print-config src/index.js

# 检查特定文件
npx eslint src/index.js

# 调试模式
DEBUG=eslint:* npx eslint src

# 查看规则详情
npx eslint --rule "no-console:2" src
```

## 参考资源

- [ESLint 官方文档](https://eslint.org/)
- [ESLint Flat Config 迁移指南](https://eslint.org/docs/latest/use/configure/migration-guide)
- [eslint-config-prettier 官方文档](https://github.com/prettier/eslint-config-prettier)
- [typescript-eslint 官方文档](https://typescript-eslint.io/)
- [ESLint 性能优化指南](https://eslint.org/docs/latest/developer-guide/performance)
