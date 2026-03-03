# ESLint 基础完全指南

ESLint 是 JavaScript 和 TypeScript 代码的静态分析工具，用于识别代码中的模式和问题，帮助开发者编写一致、可维护的代码。本指南详细介绍 ESLint 的核心概念、配置方式和工作原理。

## 1. 概述

### 1.1 ESLint 定位与价值

ESLint 是一个可插拔的 JavaScript linter，于 2013 年由 Nicholas C. Zakas 创建。它的核心价值体现在以下几个方面：

**代码质量保障**：ESLint 通过内置和自定义规则检测代码中的语法错误、潜在 bug 和不良编码习惯。例如检测未使用的变量、禁止使用 `console`、要求使用 `const` 代替 `var` 等。

**团队代码统一**：通过统一的配置，团队成员可以遵循相同的编码规范，减少代码审查中的格式争论。ESLint 支持继承第三方共享配置，如 Google、Airbnb 的编码规范。

**自动化修复**：ESLint 能够自动修复许多代码问题，如添加分号、调整缩进、修复空格等。这大大减少了手动调整代码格式的工作量。

**多语言支持**：通过自定义解析器和插件，ESLint 可以支持 TypeScript、Vue、React、JSON、Markdown 等多种文件类型。

### 1.2 ESLint vs Prettier vs TypeScript

这三个工具经常一起使用，但它们的职责各不相同：

| 特性         | ESLint                         | Prettier               | TypeScript         |
| ------------ | ------------------------------ | ---------------------- | ------------------ |
| **主要职责** | 代码质量检查、风格 enforcement | 代码格式化             | 类型检查           |
| **检查内容** | 语法错误、代码风格、潜在 bug   | 缩进、分号、引号等格式 | 类型错误、类型推断 |
| **修复能力** | 可修复部分问题                 | 完全自动修复           | 不修复代码         |
| **配置方式** | 大量规则配置                   | 少量格式化选项         | tsconfig.json      |
| **运行时机** | 开发时、CI/CD                  | 保存时、CI/CD          | 编译时             |

**最佳实践**：将 ESLint 用于代码质量检查，Prettier 用于代码格式化，TypeScript 用于类型检查。三者配合使用可以达到最佳效果。配置时需要使用 `eslint-config-prettier` 禁用 ESLint 中与 Prettier 冲突的规则。

## 2. 核心概念

### 2.1 Rules（规则）

Rules（规则）是 ESLint 的核心组成部分，每条规则定义了一种代码检查逻辑。ESLint 内置了数百条规则，涵盖从代码语法到最佳实践的各个方面。

**规则结构**：每条规则都有唯一的名称，格式为 `规则名: [严重级别, 选项]`。严重级别可以是 `off`（关闭）、`warn`（警告）或 `error`（错误）。

```javascript
// 规则配置示例
{
  "rules": {
    // 关闭规则
    "no-console": "off",
    // 警告级别
    "no-unused-vars": "warn",
    // 错误级别，带选项
    "quotes": ["error", "single"],
    // 复杂选项配置
    "indent": ["error", 2, { "SwitchCase": 1 }]
  }
}
```

**常用规则分类**：

| 分类     | 示例规则                        | 说明                   |
| -------- | ------------------------------- | ---------------------- |
| 潜在错误 | `no-debugger`、`no-unreachable` | 检测可能导致错误的代码 |
| 最佳实践 | `eqeqeq`、`no-eval`             | 推荐的安全编码方式     |
| 严格模式 | `strict`                        | 要求使用严格模式       |
| 变量     | `no-unused-vars`、`no-undef`    | 变量声明和使用规范     |
| Node.js  | `no-process-env`、`no-sync`     | Node.js 特定规则       |
| 风格     | `semi`、`quotes`、`indent`      | 代码格式规范           |

### 2.2 Plugins（插件）

Plugins（插件）扩展了 ESLint 的功能，可以添加自定义规则、环境配置和处理特定文件类型的能力。

**插件结构**：一个 ESLint 插件通常包含以下部分：

- 自定义规则（rules）
- 配置（configs）
- 处理器（processors）

```javascript
// 使用 React 插件
import react from 'eslint-plugin-react';
import reactHooks from 'eslint-plugin-react-hooks';

export default [
  {
    plugins: {
      react,
      'react-hooks': reactHooks
    },
    rules: {
      'react/jsx-uses-react': 'error',
      'react-hooks/rules-of-hooks': 'error',
      'react-hooks/exhaustive-deps': 'warn'
    }
  }
];
```

**常用插件推荐**：

| 插件名称                    | 用途               |
| --------------------------- | ------------------ |
| `eslint-plugin-react`       | React 代码检查     |
| `eslint-plugin-react-hooks` | React Hooks 规则   |
| `eslint-plugin-vue`         | Vue SFC 检查       |
| `eslint-plugin-typescript`  | TypeScript 支持    |
| `eslint-plugin-import`      | import/export 规范 |
| `eslint-plugin-prettier`    | Prettier 集成      |
| `eslint-plugin-n`           | Node.js 最佳实践   |

### 2.3 Extends（继承）

Extends（继承）允许你复用已有的配置，减少重复配置的工作量。在 Flat Config 中，继承通过数组配置实现。

```javascript
// Flat Config 中的继承方式
import js from '@eslint/js';
import react from 'eslint-plugin-react';
import reactConfig from 'eslint-plugin-react/configs/recommended';
import tseslint from 'typescript-eslint';

export default [
  // 继承 ESLint 推荐配置
  js.configs.recommended,
  // 继承 TypeScript ESLint 推荐配置
  ...tseslint.configs.recommended,
  // 继承 React 推荐配置
  {
    ...reactConfig,
    plugins: {
      react
    }
  },
  // 自定义配置
  {
    rules: {
      'no-unused-vars': 'warn'
    }
  }
];
```

**继承来源**：

| 来源        | 示例                                      | 说明                |
| ----------- | ----------------------------------------- | ------------------- |
| ESLint 内置 | `js.configs.recommended`                  | ESLint 官方推荐配置 |
| 插件配置    | `eslint-plugin-react/configs/recommended` | 插件自带的预设配置  |
| 共享配置    | `eslint-config-airbnb`                    | 社区共享的配置包    |
| TypeScript  | `typescript-eslint`                       | TypeScript 专用配置 |

### 2.4 Environments（环境）

Environments（环境）定义了预定义的全局变量，用于告诉 ESLint 代码运行在特定的环境中。

```javascript
// 配置不同的环境
export default [
  {
    // Node.js 环境
    env: {
      node: true,
      es2022: true
    },
    globals: {
      // 自定义全局变量
      myGlobal: 'readonly'
    }
  },
  {
    files: ['*.test.js'],
    // 测试环境
    env: {
      jest: true,
      node: true
    }
  },
  {
    files: ['*.browser.js'],
    // 浏览器环境
    env: {
      browser: true
    }
  }
];
```

**内置环境**：

| 环境      | 全局变量                             |
| --------- | ------------------------------------ |
| `browser` | `window`、`document`、`navigator` 等 |
| `node`    | `require`、`module`、`__dirname` 等  |
| `es6`     | `Promise`、`Map`、`Set` 等 ES6 全局  |
| `es2022`  | ES2022 新增的全局变量                |
| `worker`  | Web Worker 相关全局变量              |
| `jest`    | `describe`、`it`、`expect` 等        |
| `mocha`   | `describe`、`it`、`before` 等        |

### 2.5 Parser（解析器）

Parser（解析器）负责将源代码转换为 ESLint 可以分析的 AST（抽象语法树）。ESLint 默认使用 Espree 解析 JavaScript。

```javascript
// 使用自定义解析器
import tsParser from '@typescript-eslint/parser';
import babelParser from '@babel/eslint-parser';

export default [
  {
    // 使用 TypeScript 解析器
    files: ['*.ts', '*.tsx'],
    languageOptions: {
      parser: tsParser,
      parserOptions: {
        ecmaVersion: 2022,
        sourceType: 'module'
      }
    }
  },
  {
    // 使用 Babel 解析器（支持实验性语法）
    files: ['*.babel.js'],
    languageOptions: {
      parser: babelParser,
      parserOptions: {
        requireConfigFile: false,
        babelOptions: {
          presets: ['@babel/preset-env']
        }
      }
    }
  }
];
```

**常用解析器**：

| 解析器                      | 用途                   |
| --------------------------- | ---------------------- |
| `@typescript-eslint/parser` | TypeScript 代码解析    |
| `@babel/eslint-parser`      | Babel 支持的实验性语法 |
| `vue-eslint-parser`         | Vue SFC 模板解析       |
| `eslint-plugin-json`        | JSON 文件解析          |

## 3. 配置格式

### 3.1 Flat Config 入门

Flat Config 是 ESLint 9 引入的新配置系统，相比旧的 `.eslintrc` 格式更加简洁和直观。

**配置文件命名**：

| 文件名              | 说明                |
| ------------------- | ------------------- |
| `eslint.config.js`  | 推荐使用            |
| `eslint.config.mjs` | ES Module 格式      |
| `eslint.config.cjs` | CommonJS 格式       |
| `eslint.config.ts`  | TypeScript 类型支持 |

**最小配置示例**：

```javascript
// eslint.config.js
import js from '@eslint/js';

export default [
  js.configs.recommended,
  {
    rules: {
      'no-unused-vars': 'warn'
    }
  }
];
```

**安装依赖**：

```bash
# 安装 ESLint 和官方推荐配置
npm install eslint @eslint/js -D
```

### 3.2 配置结构

Flat Config 采用数组形式配置，每个数组元素代表一个配置对象，可以包含文件匹配规则、规则定义、插件、环境等。

```javascript
// eslint.config.js 完整结构示例
import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import react from 'eslint-plugin-react';
import reactHooks from 'eslint-plugin-react-hooks';
import globals from 'globals';

export default [
  // 1. 基础配置：适用于所有文件
  js.configs.recommended,

  // 2. TypeScript 配置
  ...tseslint.configs.recommended,

  // 3. 自定义规则配置
  {
    // 文件匹配模式（可选，不写则匹配所有）
    files: ['**/*.{js,ts,jsx,tsx}'],

    // 语言选项
    languageOptions: {
      // 全局变量
      globals: {
        ...globals.browser,
        ...globals.node,
        ...globals.es2022
      },
      // 解析器选项
      parserOptions: {
        ecmaVersion: 2022,
        sourceType: 'module'
      }
    },

    // 插件配置
    plugins: {
      react,
      'react-hooks': reactHooks
    },

    // 规则配置
    rules: {
      'no-console': 'warn',
      'no-unused-vars': 'warn',
      'react/react-in-jsx-scope': 'off'
    }
  },

  // 4. 测试文件特殊配置
  {
    files: ['**/*.test.{js,ts}'],
    languageOptions: {
      globals: {
        ...globals.jest
      }
    },
    rules: {
      'no-unused-expressions': 'off'
    }
  },

  // 5. 忽略某些文件
  {
    ignores: ['dist/**', 'build/**', 'node_modules/**']
  }
];
```

### 3.3 配置命名约定

在 Flat Config 中，合理命名配置可以提高可维护性。

```javascript
// eslint.config.js
import js from '@eslint/js';
import tseslint from 'typescript-eslint';

const graphEslintrc = {
  rules: {
    'no-console': 'error'
  }
};

export default [
  js.configs.recommended,
  ...tseslint.configs.recommended,

  // 命名配置对象
  {
    name: 'my-app/javascript-rules',
    files: ['**/*.js'],
    rules: {
      'no-var': 'error'
    }
  },

  {
    name: 'my-app/typescript-rules',
    files: ['**/*.ts'],
    rules: {
      '@typescript-eslint/no-unused-vars': 'warn'
    }
  },

  {
    name: 'my-app/graphql-rules',
    files: ['**/*.graphql'],
    processor: 'graphql/graphql-processor'
  }
];
```

## 4. 工作原理

ESLint 的工作流程分为四个阶段：解析、检查、报告和修复。理解这个流程有助于更好地配置和使用 ESLint。

```mermaid
flowchart LR
    A[源代码] --> B[解析阶段]
    B --> C[检查阶段]
    C --> D{是否有错误?}
    D -->|是| E[报告阶段]
    D -->|否| F[继续]
    E --> G[输出结果]
    G --> H{自动修复?}
    H -->|是| I[应用修复]
    H -->|否| J[结束]
    I --> J
```

### 4.1 解析阶段

解析阶段将源代码转换为 AST（抽象语法树）。这个阶段使用配置的解析器（如 Espree、TypeScript Parser）进行词法分析和语法分析。

```javascript
// 解析阶段的内部流程
// 1. 读取源文件
// 2. 词法分析：将代码分解为 Token
// 3. 语法分析：将 Token 组装为 AST
// 4. 返回 AST 供后续阶段使用
```

**AST 示例**：

```
// 源代码
const greeting = 'Hello';

// 对应的 AST 结构
{
  type: 'VariableDeclaration',
  kind: 'const',
  declarations: [
    {
      type: 'VariableDeclarator',
      id: { type: 'Identifier', name: 'greeting' },
      init: { type: 'Literal', value: 'Hello' }
    }
  ]
}
```

### 4.2 检查阶段

检查阶段遍历 AST，根据配置的规则对每个节点进行检查。规则会访问 AST 的特定节点，并根据节点信息判断是否违规。

```javascript
// 自定义规则示例：禁止使用 eval
function create(context) {
  return {
    // 访问 CallExpression 节点
    CallExpression(node) {
      // 检查函数名是否为 eval
      if (node.callee.name === 'eval') {
        // 报告违规
        context.report({
          node,
          message: '禁止使用 eval'
        });
      }
    }
  };
}

export default {
  meta: {
    type: 'problem',
    docs: {
      description: '禁止使用 eval'
    }
  },
  create
};
```

**规则访问器类型**：

| 访问器             | 说明               |
| ------------------ | ------------------ |
| `Program`          | 访问整个程序节点   |
| `Identifier`       | 访问标识符节点     |
| `Literal`          | 访问字面量节点     |
| `CallExpression`   | 访问函数调用节点   |
| `BinaryExpression` | 访问二元表达式节点 |
| `JSXElement`       | 访问 JSX 元素节点  |

### 4.3 报告阶段

当规则检测到问题时，会调用 `context.report()` 方法报告违规信息。ESLint 收集所有报告的问题，并根据严重级别和配置进行输出。

```javascript
// context.report() 的完整选项
context.report({
  node: node,           // 相关的 AST 节点
  message: '错误信息',   // 主要错误消息
  messageId: 'errorId', // 错误消息 ID（用于国际化）
  data: {               // 消息数据
    name: 'foo'
  },
  fix(fixer) {          // 自动修复函数
    return fixer.replaceText(node, 'fixed code');
  }
});
```

### 4.4 自动修复

ESLint 能够自动修复部分规则检测到的问题。修复功能通过 `fix` 函数实现，返回一个替换操作。

```javascript
// 规则：要求分号结尾
function create(context) {
  return {
    ExpressionStatement(node) {
      const sourceCode = context.sourceCode || context.languageOptions.sourceCode;
      const lastToken = sourceCode.getLastToken(node);

      if (lastToken.value !== ';') {
        context.report({
          node,
          message: '语句必须以分号结尾',
          fix(fixer) {
            // 在语句末尾添加分号
            return fixer.insertTextAfter(node, ';');
          }
        });
      }
    }
  };
}
```

**可自动修复的规则类型**：

| 规则类型 | 示例                       | 修复方式   |
| -------- | -------------------------- | ---------- |
| 格式类   | `semi`、`quotes`、`indent` | 调整格式   |
| 代码类   | `no-unused-vars`           | 删除代码   |
| 替换类   | `prefer-const`             | 替换关键字 |

**修复命令**：

```bash
# 自动修复所有可修复的问题
npx eslint --fix .

# 检查并输出修复信息，但不实际修改
npx eslint --fix-dry-run .

# 只修复特定文件
npx eslint --fix src/app.js
```

## 5. CLI 命令

### 5.1 常用命令

ESLint 提供了丰富的命令行选项，用于执行 lint 检查、自动修复、调试等操作。

```bash
# 检查指定文件
npx eslint src/index.js

# 检查整个目录
npx eslint src/

# 检查并自动修复
npx eslint --fix src/

# 检查指定配置文件
npx eslint -c my.eslintrc.js src/
```

### 5.2 常用选项

| 选项               | 说明                     |
| ------------------ | ------------------------ | ------------------------- |
| `--fix`            | 自动修复可修复的问题     |
| `--fix-dry-run`    | 模拟修复，不实际修改文件 |
| `--cache`          | -                        | 缓存检查结果，提高性能    |
| `--cache-location` | -                        | 缓存文件位置              |
| `--max-warnings`   | -                        | 允许的最大警告数          |
| `--quiet`          | `-q`                     | 只显示错误，不显示警告    |
| `--max-depth`      | -                        | 输出中 AST 遍历的最大深度 |
| `--ext`            | -                        | 指定检查的文件扩展名      |
| `--ignore-path`    | -                        | 指定忽略文件路径          |
| `--no-eslintrc`    | -                        | 不使用 .eslintrc 配置文件 |
| `--env`            | -                        | 指定环境                  |
| `--global`         | -                        | 定义全局变量              |

**常用命令组合**：

```bash
# 完整检查命令（推荐）
npx eslint --cache --fix src/

# CI 环境检查（严格模式）
npx eslint --max-warnings 0 src/

# 开发时检查特定文件
npx eslint --cache src/index.js src/utils.js

# 检查所有 JavaScript 和 TypeScript 文件
npx eslint "**/*.{js,ts,jsx,tsx}"
```

### 5.3 输出格式

ESLint 支持多种输出格式，便于不同场景使用。

| 格式       | 选项                  | 用途            |
| ---------- | --------------------- | --------------- |
| 简洁       | 默认                  | 终端查看        |
| JSON       | `--format json`       | 程序处理        |
| JUnit XML  | `--format junit`      | CI 集成         |
| Stylish    | `--format stylish`    | 详细错误报告    |
| Checkstyle | `--format checkstyle` | Checkstyle 兼容 |
| Sarif      | `--format sarif`      | SARIF 标准格式  |

```bash
# 使用 Stylish 格式（更友好的终端输出）
npx eslint --format stylish src/

# 输出 JSON 格式
npx eslint --format json src/ > eslint-results.json

# 输出 SARIF 格式（用于安全工具集成）
npx eslint --format sarif src/ > results.sarif
```

**Stylish 输出示例**：

```
/src/app.js
  10:5  error  'foo' is defined but never used  no-unused-vars
  12:1  error  Expected a newline after semicolon  semi

/src/utils.js
  5:10  warning  'console.log' found             no-console
```

## 6. 总结

### 6.1 核心要点

ESLint 是 JavaScript/TypeScript 代码质量保障的核心工具。通过合理配置规则、插件和环境，可以有效提升代码质量、统一团队编码风格。Flat Config 作为 ESLint 9 的默认配置格式，提供了更简洁的配置方式和更好的性能。

关键要点如下：

- **规则是核心**：规则配置决定检查内容，严重级别分为 `off`、`warn`、`error`
- **插件扩展功能**：通过插件支持 TypeScript、React、Vue 等特定框架和语言
- **继承简化配置**：通过 `extends` 复用已有配置，避免重复工作
- **环境定义全局变量**：正确配置环境可以避免对未定义全局变量的误报
- **解析器决定语法支持**：根据项目需求选择合适的解析器
- **自动修复提高效率**：合理使用 `--fix` 选项可以快速修复代码问题

### 6.2 速查表

| 场景            | 命令/配置                        |
| --------------- | -------------------------------- |
| 初始化 ESLint   | `npm init @eslint/config`        |
| 检查文件        | `npx eslint file.js`             |
| 自动修复        | `npx eslint --fix file.js`       |
| 使用推荐配置    | `js.configs.recommended`         |
| 配置 TypeScript | 使用 `@typescript-eslint/parser` |
| 配置 React      | 使用 `eslint-plugin-react`       |
| 配置 Vue        | 使用 `eslint-plugin-vue`         |
| 忽略文件        | 在配置中使用 `ignores` 数组      |
| 缓存检查结果    | 使用 `--cache` 选项              |

## 参考资源

- [ESLint 官方文档](https://eslint.org/)
- [ESLint Flat Config 指南](https://eslint.org/docs/latest/use/configure/configuration-files)
- [TypeScript ESLint](https://typescript-eslint.io/)
- [ESLint 插件列表](https://eslint.org/docs/latest/extend/plugins)
- [Airbnb JavaScript 编码规范](https://github.com/airbnb/javascript)
- [ESLint 配置迁移工具](https://eslint.org/docs/latest/use/migration-guide)
