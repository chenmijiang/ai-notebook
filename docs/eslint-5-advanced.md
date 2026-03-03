# ESLint 进阶完全指南

ESLint 是 JavaScript/TypeScript 最流行的代码检查工具之一，它帮助开发者发现并修复代码中的问题，同时强制执行代码风格规范。随着 ESLint 9.0 引入 Flat Config 系统，配置方式发生了重大变革。本文将深入探讨 Flat Config 深度应用、自定义规则开发、插件构建、性能优化等进阶主题，帮助读者从 ESLint 使用者成长为贡献者。

## 1. Flat Config 深度

Flat Config 是 ESLint 9.0 引入的全新配置系统，相比传统的 `.eslintrc.*` 格式，它提供了更灵活的配置方式和更好的性能。本章将详细介绍 Flat Config 的迁移指南和调试技巧。

### 1.1 迁移指南

Flat Config 使用 `eslint.config.js` 文件替代传统的配置文件格式。迁移过程中需要理解两者之间的核心差异，并掌握常见的迁移策略。

#### 1.1.1 配置格式对比

传统配置使用 JSON/YAML 格式，通过 `eslintrc` 命令管理；Flat Config 则使用 JavaScript 模块，支持更复杂的逻辑处理。以下是两种配置格式的详细对比：

| 特性      | 传统配置 (.eslintrc)             | Flat Config (eslint.config.js) |
| --------- | -------------------------------- | ------------------------------ |
| 文件命名  | `.eslintrc.json`、`.eslintrc.js` | `eslint.config.js`             |
| 配置格式  | JSON、YAML、JavaScript           | JavaScript 模块                |
| 继承方式  | `extends` 字段                   | 数组展开或引用                 |
| 插件引用  | 字符串名称                       | 插件对象直接引用               |
| 规则覆盖  | 逐层覆盖                         | 数组顺序覆盖                   |
| Glob 匹配 | 特定字段                         | 内置 `globs` 支持              |

#### 1.1.2 基础迁移示例

传统配置向 Flat Config 迁移的核心是将配置对象转换为 JavaScript 模块。以下是一个典型项目的迁移示例：

```javascript
// ✅ Flat Config 写法
import js from '@eslint/js';
import tseslint from 'typescript-eslint';

export default [
  // 基础 JavaScript 推荐配置
  js.configs.recommended,

  // TypeScript 专用配置
  ...tseslint.configs.recommended,

  // 自定义规则配置
  {
    files: ['**/*.ts', '**/*.tsx'],
    languageOptions: {
      parser: tseslint.parser,
      parserOptions: {
        ecmaVersion: 2022,
        sourceType: 'module',
      },
    },
    rules: {
      '@typescript-eslint/no-unused-vars': 'error',
      '@typescript-eslint/explicit-function-return-type': 'off',
    },
  },

  // 忽略文件配置（替代 .eslintignore）
  {
    ignores: ['dist/**', 'build/**', 'node_modules/**'],
  },
];
```

#### 1.1.3 兼容模式配置

如果项目暂时无法完全迁移，可以使用 ESLint 9.0 提供的兼容模式。兼容模式下可以继续使用传统配置文件，同时体验 Flat Config 的部分新特性：

```javascript
// eslint.config.js - 兼容模式配置
import { FlatCompat } from '@eslint/eslintrc';
import js from '@eslint/js';

const compat = new FlatCompat({
  baseDirectory: import.meta.dirname,
});

export default [
  js.configs.recommended,
  // 使用 compat.layer() 转换传统配置
  ...compat.extends('eslint:recommended', 'plugin:react/recommended'),
  ...compat.plugins('react', 'lodash'),
  {
    rules: {
      'no-console': 'warn',
    },
  },
];
```

#### 1.1.4 常见迁移问题解决

迁移过程中经常会遇到一些问题，以下是典型问题的解决方案：

**问题一：插件引用方式变更**

传统配置中可以直接使用插件名称字符串，Flat Config 需要先导入插件对象：

```javascript
// ❌ 传统写法（Flat Config 中不可用）
{
  "plugins": ["react"],
  "rules": {
    "react/jsx-uses-react": "error"
  }
}

// ✅ Flat Config 写法
import reactPlugin from 'eslint-plugin-react';
import reactJsx from 'eslint-plugin-react/configs/jsx-runtime';

export default [
  reactJsx,
  {
    plugins: {
      react: reactPlugin,
    },
    rules: {
      'react/jsx-uses-react': 'error',
    },
  },
];
```

**问题二：处理器迁移**

带处理器的配置需要显式指定文件匹配规则：

```javascript
// 处理 Vue 文件的 Flat Config
import vuePlugin from 'eslint-plugin-vue';
import vueParser from 'vue-eslint-parser';

export default [
  {
    files: ['**/*.vue'],
    languageOptions: {
      parser: vueParser,
      parserOptions: {
        ecmaVersion: 2022,
        sourceType: 'module',
      },
    },
    plugins: {
      vue: vuePlugin,
    },
    rules: {
      'vue/multi-word-component-names': 'off',
    },
  },
];
```

### 1.2 调试技巧

掌握 Flat Config 的调试技巧可以帮助开发者快速定位配置问题，提高开发效率。本节介绍常用的调试方法和工具。

#### 1.2.1 配置验证命令

ESLint 提供了多个内置命令用于验证和调试配置：

```bash
# 查看最终合并后的配置（不执行检查）
eslint --print-config file.js

# 检查配置文件语法
node eslint.config.js

# 以调试模式运行
DEBUG=eslint:* eslint file.js
```

`--print-config` 命令特别有用，它可以显示 ESLint 如何解析和合并配置，对于理解复杂配置结构非常有帮助：

```bash
# 查看特定文件的完整配置
eslint --print-config src/index.ts

# 输出格式化为 JSON
eslint --print-config src/index.ts > config.json
```

#### 1.2.2 规则调试技巧

当规则行为不符合预期时，可以使用以下技巧进行调试：

**使用规则文档和选项**

```javascript
// 完整的规则配置示例
{
  rules: {
    // 基本语法：规则名: 错误级别
    'no-unused-vars': 'warn',

    // 带选项：规则名: [错误级别, 选项对象]
    'no-console': ['error', { allow: ['warn', 'error'] }],

    // 多选项场景
    'max-len': ['error', {
      code: 100,
      ignoreStrings: true,
      ignoreTemplateLiterals: true,
      ignoreComments: true,
    }],
  },
}
```

**规则测试文件**

创建一个测试文件专门验证规则行为：

```javascript
// debug-rules.js - 快速测试规则行为
import { Linter } from 'eslint';
import rule from './your-custom-rule.js';

const linter = new Linter();
linter.defineRule('custom/rule-name', rule);

const code = `
const unused = 'this will trigger no-unused-vars';
console.log('hello');
`;

const messages = linter.verify(code, {
  rules: {
    'custom/rule-name': 'error',
    'no-unused-vars': 'error',
  },
});

console.log(JSON.stringify(messages, null, 2));
```

#### 1.2.3 性能问题排查

当 ESLint 运行缓慢时，可以使用内置的性能分析工具：

```bash
# 启用 TIMING 环境变量
TIMING=1 eslint src/**/*.js

# 输出格式：
# Rule    | Time (ms) | Percentage
# ---------|-----------|------------
# no-unused-vars | 150.23 | 45.2%
```

性能分析输出可以帮助识别哪些规则耗时最长，从而进行针对性优化：

```bash
# 只运行特定文件进行测试
TIMING=1 eslint src/index.js --no-eslintrc -c eslint.config.js

# 输出详细的时间统计
TIMING=detail eslint src/
```

> **提示**：TIMING 输出按规则耗时降序排列，排在首位的规则通常是性能瓶颈所在。

## 2. 自定义规则

ESLint 的强大之处在于允许开发者创建自定义规则来满足特定项目的代码规范需求。本章将介绍自定义规则开发的基础知识，包括 AST 基础、规则结构设计和实战案例。

### 2.1 AST 基础

理解 AST（抽象语法树）是开发自定义规则的前提。ESLint 使用 Espree 作为 JavaScript 解析器，将源代码转换为 AST 进行分析。

#### 2.1.1 AST 节点类型

JavaScript 代码会被解析为树形结构的节点，每个节点代表代码的一个语法元素。以下是常用的节点类型对照表：

| 节点类型                  | 代表代码                   | 常用属性                                |
| ------------------------- | -------------------------- | --------------------------------------- |
| `Program`                 | 整个文件                   | `body`（语句数组）、`tokens`            |
| `VariableDeclaration`     | `const x = 1`              | `kind`（var/let/const）、`declarations` |
| `VariableDeclarator`      | `x = 1`                    | `id`、`init`                            |
| `FunctionDeclaration`     | `function foo() {}`        | `id`、`params`、`body`                  |
| `FunctionExpression`      | `const fn = function() {}` | 同上                                    |
| `ArrowFunctionExpression` | `() => {}`                 | `params`、`body`、`expression`          |
| `CallExpression`          | `foo()`                    | `callee`、`arguments`                   |
| `MemberExpression`        | `obj.prop`                 | `object`、`property`、`computed`        |
| `BinaryExpression`        | `a + b`                    | `left`、`operator`、`right`             |
| `Literal`                 | `1`、`'hello'`             | `value`、`raw`                          |
| `Identifier`              | 变量名、函数名             | `name`                                  |
| `ObjectExpression`        | `{}`                       | `properties`                            |
| `ArrayExpression`         | `[]`                       | `elements`                              |
| `ConditionalExpression`   | `a ? b : c`                | `test`、`consequent`、`alternate`       |

#### 2.1.2 在线 AST 工具

开发规则时，可以使用在线工具快速查看代码对应的 AST 结构：

| 工具         | 网址                     | 特点                         |
| ------------ | ------------------------ | ---------------------------- |
| AST Explorer | astexplorer.net          | 支持多语言解析器，可视化展示 |
| ESTree       | github.com/estree/estree | 详细节点规范文档             |

使用 AST Explorer 的步骤：

1. 打开 astexplorer.net
2. 选择 JavaScript 解析器（Espree）
3. 输入待分析的代码
4. 点击 AST 节点查看详细信息
5. 选中节点后底部会显示对应代码位置

#### 2.1.3 节点遍历方法

ESLint 提供了两种遍历 AST 的方式：深度优先遍历和访问者模式。

**节点位置信息**

每个 AST 节点都包含源代码位置信息：

```javascript
{
  type: 'Identifier',
  name: 'foo',
  loc: {
    start: { line: 1, column: 4 },
    end: { line: 1, column: 7 }
  },
  range: [4, 7]  // 字符索引范围
}
```

**使用选择器定位节点**

ESLint 支持使用选择器匹配特定类型的节点：

```javascript
// 选择所有函数声明
'FunctionDeclaration'

// 选择所有带名称的函数
'FunctionDeclaration[id.name]'

// 选择特定名称的函数
'FunctionDeclaration[id.name="foo"]'

// 选择函数调用
'CallExpression'

// 选择特定名称的函数调用
'CallExpression[callee.name="console.log"]'
```

### 2.2 规则结构

ESLint 规则是一个包含 `meta` 和 `create` 两个属性的 JavaScript 对象。`meta` 元数据描述规则的基本信息，`create` 函数返回访问者对象用于遍历 AST。

#### 2.2.1 规则基本结构

```javascript
// my-custom-rule.js
export default {
  // 规则元数据
  meta: {
    type: 'suggestion', // problem、suggestion、layout
    docs: {
      description: '禁止使用 console',
      category: 'Best Practices',
      recommended: false,
      url: 'https://docs.example.com/rules/no-console',
    },
    fixable: 'code', // 或 'whitespace'
    schema: [
      {
        type: 'object',
        properties: {
          allow: {
            type: 'array',
            items: { type: 'string' },
          },
        },
        additionalProperties: false,
      },
    ],
    messages: {
      unexpected: 'Unexpected console.{{ method }} call.',
    },
  },

  // 创建访问者函数
  create(context) {
    // 从配置中获取选项
    const options = context.options[0] || {};
    const allowedMethods = options.allow || [];

    // 访问者对象 - 遍历 AST
    return {
      // 访问 CallExpression 节点
      CallExpression(node) {
        const callee = node.callee;

        // 检查是否是 console 调用
        if (
          callee.type === 'MemberExpression' &&
          callee.object.type === 'Identifier' &&
          callee.object.name === 'console' &&
          callee.property.type === 'Identifier' &&
          !allowedMethods.includes(callee.property.name)
        ) {
          // 报告错误
          context.report({
            node,
            messageId: 'unexpected',
            data: {
              method: callee.property.name,
            },
          });
        }
      },
    };
  },
};
```

#### 2.2.2 规则元数据详解

`meta` 对象包含规则的配置信息，对规则的发布和维护至关重要：

| 属性               | 说明                                                                            | 必需 |
| ------------------ | ------------------------------------------------------------------------------- | ---- |
| `type`             | 规则类型：`problem`（代码错误）、`suggestion`（改进建议）、`layout`（代码格式） | 是   |
| `docs.description` | 规则描述                                                                        | 是   |
| `docs.recommended` | 是否推荐启用                                                                    | 是   |
| `fixable`          | 是否可自动修复：`code` 或 `whitespace`                                          | 否   |
| `schema`           | 规则选项的 JSON Schema 验证                                                     | 否   |
| `messages`         | 错误消息模板                                                                    | 否   |

**type 字段的选择指南**

| 类型         | 使用场景         | 示例规则                        |
| ------------ | ---------------- | ------------------------------- |
| `problem`    | 代码中明确的错误 | `no-unused-vars`、`no-debugger` |
| `suggestion` | 改进代码的建议   | `no-new`、`prefer-const`        |
| `layout`     | 代码格式和风格   | `indent`、`semi`、`quotes`      |

#### 2.2.3 Context API 详解

`context` 对象提供了规则与 ESLint 交互的各种方法：

| 方法                            | 用途           |
| ------------------------------- | -------------- |
| `context.report(info)`          | 报告问题       |
| `context.getSourceCode()`       | 获取源代码信息 |
| `context.getFilename()`         | 获取当前文件名 |
| `context.getPhysicalFilename()` | 获取物理文件名 |
| `context.options`               | 获取规则选项   |
| `context.parserOptions`         | 获取解析器选项 |
| `context.settings`              | 获取共享设置   |
| `context.cwd`                   | 获取工作目录   |

**getSourceCode 常用方法**

```javascript
create(context) {
  const sourceCode = context.getSourceCode();

  return {
    Identifier(node) {
      // 获取标识符的文本
      const text = sourceCode.getText(node);

      // 获取带注释的完整文本
      const textWithComments = sourceCode.getText(node, 0, 2);

      // 获取 token 信息
      const tokens = sourceCode.getTokens(node);

      // 获取注释
      const comments = sourceCode.getCommentsBefore(node);

      // 检查缩进
      const indent = sourceCode.getIndentation(node);

      // 获取节点之前的空白字符
      const tokenBefore = sourceCode.getTokenBefore(node);
    },
  };
}
```

### 2.3 实战案例

通过实际案例可以帮助更好地理解自定义规则的设计思路和实现方法。本节提供三个从简单到复杂的实战案例。

#### 2.3.1 案例一：禁止特定 API

创建一个规则禁止在生产代码中使用 `debugger` 语句和特定的方法：

```javascript
// rules/no-debug-methods.js
export default {
  meta: {
    type: 'problem',
    docs: {
      description: '禁止使用调试方法',
      recommended: true,
    },
    schema: [
      {
        type: 'object',
        properties: {
          allowed: {
            type: 'array',
            items: { type: 'string' },
          },
        },
        additionalProperties: false,
      },
    ],
    messages: {
      debugger: '禁止使用 debugger 语句',
      console: '禁止使用 console.{{ method }}，请使用日志库替代',
    },
  },

  create(context) {
    const options = context.options[0] || {};
    const allowed = options.allowed || [];

    const disallowed = new Set(['log', 'debug', 'info', 'warn', 'error']);
    allowed.forEach((m) => disallowed.delete(m));

    return {
      // 检查 debugger 语句
      DebuggerStatement(node) {
        context.report({
          node,
          messageId: 'debugger',
        });
      },

      // 检查 console 调用
      CallExpression(node) {
        if (
          node.callee.type === 'MemberExpression' &&
          node.callee.object.type === 'Identifier' &&
          node.callee.object.name === 'console' &&
          node.callee.property.type === 'Identifier' &&
          disallowed.has(node.callee.property.name)
        ) {
          context.report({
            node,
            messageId: 'console',
            data: { method: node.callee.property.name },
          });
        }
      },
    };
  },
};
```

**配置使用**

```javascript
// eslint.config.js
import noDebugMethods from './rules/no-debug-methods.js';

export default [
  {
    rules: {
      'no-debug-methods': [
        'error',
        { allowed: ['error', 'warn'] }, // 允许 warn 和 error
      ],
    },
  },
];
```

#### 2.3.2 案例二：强制组件文件结构

为 React 项目创建一个规则，强制组件文件必须包含特定的导出顺序：

```javascript
// rules/component-structure.js
export default {
  meta: {
    type: 'suggestion',
    docs: {
      description: '强制组件文件结构顺序',
    },
    schema: [
      {
        type: 'object',
        properties: {
          order: {
            type: 'array',
            items: { type: 'string' },
          },
        },
      },
    ],
  },

  create(context) {
    const options = context.options[0] || {};
    const order = options.order || [
      'typeAnnotations',
      'interfaces',
      'types',
      'constants',
      'functions',
      'components',
      'exports',
    ];

    const categoryMap = {
      'typeAnnotations': ['TSTypeAliasDeclaration', 'TSInterfaceDeclaration'],
      'interfaces': ['TSInterfaceDeclaration'],
      'types': ['TSTypeAliasDeclaration', 'TypeAlias'],
      'constants': ['VariableDeclaration'],
      'functions': ['FunctionDeclaration', 'FunctionExpression', 'ArrowFunctionExpression'],
      'components': ['FunctionDeclaration', 'FunctionExpression'],
      'exports': ['ExportNamedDeclaration', 'ExportDefaultDeclaration'],
    };

    let currentCategory = -1;
    let hasComponent = false;

    function getCategory(node) {
      if (node.type === 'ExportNamedDeclaration' || node.type === 'ExportDefaultDeclaration') {
        return 'exports';
      }
      if (node.type === 'VariableDeclaration') {
        const firstDecl = node.declarations[0];
        if (firstDecl?.id.name?.startsWith('use') || firstDecl?.id.name?.[0]?.toUpperCase() === firstDecl?.id.name?.[0]) {
          return 'constants';
        }
        return 'constants';
      }
      if (node.type === 'FunctionDeclaration' || node.type === 'FunctionExpression') {
        if (node.id?.name?.[0]?.toUpperCase() === node.id?.name?.[0]) {
          return 'components';
        }
        return 'functions';
      }
      return null;
    }

    return {
      Program(node) {
        const body = node.body;

        body.forEach((statement, index) => {
          const category = getCategory(statement);
          if (!category) return;

          const categoryIndex = order.indexOf(category);
          if (categoryIndex === -1) return;

          if (categoryIndex < currentCategory) {
            context.report({
              node: statement,
              message: `组件结构顺序错误：${category} 应该位于 ${order[currentCategory]} 之后`,
            });
          }

          currentCategory = Math.max(currentCategory, categoryIndex);
          if (category === 'components') hasComponent = true;
        });
      },
    };
  },
};
```

#### 2.3.3 案例三：带自动修复的规则

创建一个规则，将 var 声明自动转换为 let/const，并附带修复功能：

```javascript
// rules/no-var.js
export default {
  meta: {
    type: 'suggestion',
    docs: {
      description: '禁止使用 var 声明变量',
    },
    fixable: 'code',
    schema: [],
    messages: {
      var: '使用 let 或 const 替代 var',
    },
  },

  create(context) {
    return {
      VariableDeclaration(node) {
        if (node.kind === 'var') {
          context.report({
            node,
            messageId: 'var',
            fix(fixer) {
              // 生成修复后的代码
              const varText = sourceCode.getText(node);
              const letText = varText.replace(/\bvar\b/, 'const');

              // 尝试判断是否应该用 let（如果变量被重新赋值）
              // 这里简化处理，默认使用 const
              return fixer.replaceText(node, letText);
            },
          });
        }
      },
    };
  },
};
```

> **注意**：自动修复需要特别小心，确保修复逻辑正确无误。错误的修复可能破坏代码。建议在生产环境使用前充分测试。

## 3. 插件开发

ESLint 插件是规则的集合，可以发布到 npm 供其他项目使用。本章介绍如何开发一个完整的 ESLint 插件，包括项目结构、规则集成和发布流程。

### 3.1 插件结构

一个标准的 ESLint 插件具有特定的项目结构和配置文件。

#### 3.1.1 项目结构

```
eslint-plugin-example/
├── lib/
│   ├── rules/
│   │   ├── no-debugger.js
│   │   └── require-await.js
│   ├── configs/
│   │   ├── recommended.js
│   │   └── all.js
│   └── index.js
├── tests/
│   └── lib/
│       └── rules/
│           └── no-debugger.js
├── package.json
└── README.md
```

#### 3.1.2 插件入口文件

插件的入口文件需要导出规则和配置：

```javascript
// lib/index.js
import noDebugger from './rules/no-debugger.js';
import requireAwait from './rules/require-await.js';
import recommended from './configs/recommended.js';

export default {
  rules: {
    'no-debugger': noDebugger,
    'require-await': requireAwait,
  },
  configs: {
    recommended,
  },
};
```

#### 3.1.3 配置预设

插件可以包含预设配置，用户可以直接使用：

```javascript
// lib/configs/recommended.js
export default {
  rules: {
    'example/no-debugger': 'error',
    'example/require-await': 'error',
  },
};
```

用户使用插件时只需要引用预设配置，无需单独配置每条规则：

```javascript
// eslint.config.js
import example from 'eslint-plugin-example';

export default [
  example.configs.recommended,
];
```

#### 3.1.4 插件命名规范

插件的命名需要遵循特定的规范以避免冲突：

| 类型     | 命名格式                       | 示例                               |
| -------- | ------------------------------ | ---------------------------------- |
| 官方插件 | `eslint-plugin-${name}`        | `eslint-plugin-react`              |
| 社区插件 | `eslint-plugin-${scope}`       | `@company/eslint-plugin`           |
| 作用域包 | `@scope/eslint-plugin-${name}` | `@typescript-eslint/eslint-plugin` |

### 3.2 发布 npm

发布 ESLint 插件到 npm 需要遵循特定的流程和规范。

#### 3.2.1 package.json 配置

```json
{
  "name": "eslint-plugin-example",
  "version": "1.0.0",
  "description": "自定义 ESLint 规则集",
  "main": "lib/index.js",
  "type": "module",
  "exports": {
    ".": "./lib/index.js",
    "./rules/*": "./lib/rules/*.js",
    "./configs/*": "./lib/configs/*.js"
  },
  "files": [
    "lib"
  ],
  "keywords": [
    "eslint",
    "eslintplugin",
    "eslint-plugin"
  ],
  "peerDependencies": {
    "eslint": ">=8.0.0"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
```

#### 3.2.2 发布流程

```bash
# 1. 登录 npm
npm login

# 2. 本地测试（链接方式）
npm link

# 3. 在测试项目中使用
npm link eslint-plugin-example

# 4. 发布到 npm
npm publish

# 5. 如果是作用域包
npm publish --access public
```

#### 3.2.3 版本管理

遵循语义化版本规范（SemVer）：

| 版本号           | 含义               | 何时变更       |
| ---------------- | ------------------ | -------------- |
| 主版本 (1.0.0)   | 不兼容的 API 变更  | 规则行为改变   |
| 次版本 (1.1.0)   | 向后兼容的新功能   | 新增规则、选项 |
| 补丁版本 (1.0.1) | 向后兼容的缺陷修复 | 修复规则 bug   |

> **提示**：修改规则的行为属于主版本变更，即使在补丁版本中也可能破坏用户的代码检查预期。

## 4. 测试规则

开发自定义规则时，完善的测试是保证规则正确性的关键。ESLint 提供了 RuleTester 工具简化测试流程。

### 4.1 RuleTester

RuleTester 是 ESLint 内置的规则测试工具，提供了简洁的 API 用于验证规则行为。

#### 4.1.1 基础测试结构

```javascript
// tests/lib/rules/my-rule.js
import rule from '../../../lib/rules/my-rule.js';
import { RuleTester } from 'eslint';

const ruleTester = new RuleTester({
  languageOptions: {
    ecmaVersion: 2022,
    sourceType: 'module',
  },
});

ruleTester.run('my-rule', rule, {
  // 有效的代码示例（不应触发错误）
  valid: [
    'const x = 1;',
    {
      code: 'const y = 2;',
      options: [{ allowY: true }],
    },
  ],

  // 无效的代码示例（应触发错误）
  invalid: [
    {
      code: 'const x = 1;',
      errors: [{ messageId: 'unexpected' }],
    },
    {
      code: 'let x = 1;',
      options: [{ allowY: true }],
      errors: [
        {
          messageId: 'unexpected',
          data: { name: 'x' },
        },
      ],
    },
  ],
});
```

#### 4.1.2 测试选项详解

RuleTester 支持多种配置选项：

```javascript
const ruleTester = new RuleTester({
  // 解析器选项
  languageOptions: {
    ecmaVersion: 2022,
    sourceType: 'module',
    globals: {
      window: 'readonly',
      document: 'readonly',
    },
  },

  // 自定义解析器（用于测试 TypeScript 等）
  languageOptions: {
    parser: require('typescript-eslint').parser,
    parserOptions: {
      ecmaFeatures: { jsx: true },
    },
  },
});
```

#### 4.1.3 测试带修复的规则

当规则包含自动修复功能时，需要测试修复结果：

```javascript
ruleTester.run('no-var', noVarRule, {
  valid: [
    'const x = 1;',
    'let y = 2;',
  ],
  invalid: [
    {
      code: 'var x = 1;',
      output: 'const x = 1;', // 期望的修复输出
      errors: [{ messageId: 'var' }],
    },
    {
      code: 'var x = 1;\nvar y = 2;',
      output: 'const x = 1;\nconst y = 2;',
      errors: [
        { messageId: 'var' },
        { messageId: 'var' },
      ],
    },
  ],
});
```

#### 4.1.4 完整测试示例

```javascript
// tests/lib/rules/no-debug-methods.js
import rule from '../../../lib/rules/no-debug-methods.js';
import { RuleTester } from 'eslint';

const ruleTester = new RuleTester({
  languageOptions: {
    ecmaVersion: 2022,
  },
});

ruleTester.run('no-debug-methods', rule, {
  valid: [
    // 基础有效情况
    'console.log("test");',
    // 配置允许的方法
    {
      code: 'console.warn("test");',
      options: [{ allowed: ['warn'] }],
    },
    // 允许所有方法
    {
      code: 'console.log("test");',
      options: [{ allowed: ['log', 'debug', 'info', 'warn', 'error'] }],
    },
    // debugger 语句被允许（不在限制范围内）
    {
      code: 'debugger;',
      options: [{ allowed: [] }],
    },
  ],

  invalid: [
    // 基本的 console.log 错误
    {
      code: 'console.log("test");',
      errors: [{ messageId: 'console', data: { method: 'log' } }],
    },
    // console.debug 错误
    {
      code: 'console.debug("test");',
      errors: [{ messageId: 'console', data: { method: 'debug' } }],
    },
    // 配置后的错误
    {
      code: 'console.log("test");',
      options: [{ allowed: ['warn'] }],
      errors: [{ messageId: 'console', data: { method: 'log' } }],
    },
    // debugger 语句错误
    {
      code: 'debugger;',
      errors: [{ messageId: 'debugger' }],
    },
    // 多个错误
    {
      code: 'console.log("a"); console.error("b");',
      errors: [
        { messageId: 'console', data: { method: 'log' } },
        { messageId: 'console', data: { method: 'error' } },
      ],
    },
  ],
});
```

#### 4.1.5 运行测试

```bash
# 运行所有测试
npm test

# 运行特定规则的测试
npm test -- tests/lib/rules/my-rule.js

# 运行带覆盖率
npm test -- --coverage

# 使用 Node.js 原生测试（Node 20+）
node --test tests/lib/rules/my-rule.js
```

## 5. 性能优化

ESLint 在大型项目中的性能可能成为瓶颈。本章介绍如何通过缓存策略和性能分析来优化 ESLint 运行效率。

### 5.1 缓存策略

ESLint 内置了缓存机制，可以显著减少重复检查的时间。

#### 5.1.1 启用缓存

```bash
# 启用缓存
eslint --cache src/

# 指定缓存文件位置
eslint --cache --cache-location .eslintcache src/

# 缓存文件默认位置
.eslintcache
```

#### 5.1.2 缓存策略对比

| 策略         | 适用场景         | 优点           | 缺点                             |
| ------------ | ---------------- | -------------- | -------------------------------- |
| 无缓存       | 小项目、首次运行 | 简单           | 重复检查所有文件                 |
| 默认缓存     | 日常开发         | 跳过未修改文件 | 修改文件依赖的模块变化时可能漏检 |
| 强制重新检查 | 依赖外部文件     | 确保完整检查   | 每次都全量检查                   |

#### 5.1.3 缓存机制详解

ESLint 缓存基于文件内容和规则配置的哈希值。当以下任一条件变化时，文件会被重新检查：

- 文件内容变化
- 文件路径变化
- 规则配置变化
- 解析器选项变化
- Node.js 版本变化

```bash
# 强制重新检查所有文件（忽略缓存）
eslint --no-cache src/

# 清除缓存后运行
rm .eslintcache && eslint src/
```

### 5.2 TIMING 分析

TIMING 环境变量可以揭示每条规则的执行耗时，帮助识别性能瓶颈。

#### 5.2.1 基本使用

```bash
# 启用时间统计
TIMING=1 eslint src/

# 输出示例：
#   Time (ms)   Rule Name
#   ---------   ----------
#   152.34      @typescript-eslint/no-unused-vars
#   98.21       no-console
#   67.45       indent
#   ...
```

#### 5.2.2 详细输出

```bash
# 更详细的时间统计
TIMING=detail eslint src/
```

#### 5.2.3 性能优化策略

根据 TIMING 分析结果，可以采取以下优化策略：

| 瓶颈类型       | 优化策略                                        |
| -------------- | ----------------------------------------------- |
| 规则数量过多   | 使用 ` ESLint_DISABLE_ALL` 注释禁用部分规则     |
| 复杂正则表达式 | 优化正则或使用选择器提前过滤                    |
| 遍历开销大     | 在 visitor 中使用 `context.sourceCode` 批量处理 |
| 重复计算       | 使用 memoization 缓存计算结果                   |
| 解析耗时       | 使用更快的解析器或减少 `parseForESLint` 调用    |

**选择性禁用规则**

```javascript
// eslint-disable-next-line no-console, @typescript-eslint/no-unused-vars
const debug = 'temp';
```

**批量文件处理**

```javascript
// ❌ 低效：每个节点都执行检查
return {
  Identifier(node) {
    checkExpensive(node);
  },
};

// ✅ 高效：使用 after 钩子批量处理
return {
  'Program:exit'(node) {
    const allIdentifiers = sourceCode.ast.body
      .flatMap(stmt => estreeWalker(stmt));
    batchCheck(allIdentifiers);
  },
};
```

#### 5.2.4 并行处理

ESLint 支持通过 `--max-warnings=0` 和并行处理提升性能：

```bash
# 使用所有 CPU 核心（实验性）
eslint --parallel src/

# 指定并行数量
eslint --concurrency 4 src/
```

> **注意**：并行处理在某些文件系统上可能反而降低性能，需要根据实际情况测试选择。

## 6. 总结

本文系统介绍了 ESLint 进阶使用技巧，涵盖 Flat Config 迁移、自定义规则开发、插件构建、测试方法和性能优化等核心主题。

### 核心要点

| 主题        | 关键点                                                                                       |
| ----------- | -------------------------------------------------------------------------------------------- |
| Flat Config | 使用 `eslint.config.js` 替代传统配置，支持 JavaScript 模块、数组覆盖、更好的 TypeScript 集成 |
| 自定义规则  | 理解 AST 节点类型，使用 `meta` + `create` 结构，通过 `context.report()` 报告问题             |
| 插件开发    | 遵循插件命名规范，正确配置 `package.json`，使用预设配置简化用户使用                          |
| 测试        | 使用 RuleTester 测试工具，验证有效/无效代码，覆盖修复功能                                    |
| 性能        | 使用 `--cache` 启用缓存，通过 TIMING=1 分析瓶颈，合理使用规则禁用                            |

### 速查表

#### 配置速查

```javascript
// Flat Config 基础结构
export default [
  { files: ['**/*.js'], rules: { 'no-unused-vars': 'error' } },
  { ignores: ['dist/**'] },
];

// 继承推荐配置
import js from '@eslint/js';
export default [js.configs.recommended];

// 使用插件
import react from 'eslint-plugin-react';
export default [{ plugins: { react }, rules: { 'react/jsx-uses-react': 'error' } }];
```

#### 规则开发速查

```javascript
export default {
  meta: {
    type: 'suggestion',
    docs: { description: '规则描述' },
    fixable: 'code',
    schema: [{ type: 'object', properties: {} }],
    messages: { key: '消息模板 {{var}}' },
  },
  create(context) {
    const sourceCode = context.getSourceCode();
    return {
      NodeType(node) {
        context.report({ node, messageId: 'key', data: { var: 'value' } });
      },
    };
  },
};
```

#### 命令行速查

```bash
# 基础运行
eslint src/

# 启用缓存
eslint --cache src/

# 性能分析
TIMING=1 eslint src/

# 打印配置
eslint --print-config file.js

# 自动修复
eslint --fix src/

# 指定配置文件
eslint -c eslint.config.js src/
```

## 参考资源

| 资源                    | 链接                                               |
| ----------------------- | -------------------------------------------------- |
| ESLint 官方文档         | https://eslint.org/docs/latest/                    |
| Flat Config 迁移指南    | https://eslint.org/docs/latest/migrate-to-9.0.0    |
| AST Explorer            | https://astexplorer.net/                           |
| ESLint 规则开发文档     | https://eslint.org/docs/latest/extend/custom-rules |
| TypeScript ESLint       | https://typescript-eslint.io/                      |
| @eslint/eslintrc 兼容层 | https://www.npmjs.com/package/@eslint/eslintrc     |
| RuleTester API          | https://eslint.org/docs/latest/extend-rule-tester  |
| ESLint 插件列表         | https://github.com/dustinspecker/awesome-eslint    |
