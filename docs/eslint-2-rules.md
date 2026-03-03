# ESLint 规则完全指南

规则是 ESLint 的核心组成部分，每条规则定义了一种代码检查逻辑。本指南详细介绍 ESLint 规则的严重程度、查找方式、配置选项，以及如何通过 Extends 和 Plugins 扩展规则体系。

## 1. 规则严重程度

ESLint 每条规则都有三个严重级别，用于控制规则的检查行为。

### 1.1 级别定义

| 级别 | 值               | 效果                     | 退出码影响 |
| ---- | ---------------- | ------------------------ | ---------- |
| 关闭 | `"off"` 或 `0`   | 完全忽略此规则           | 无影响     |
| 警告 | `"warn"` 或 `1`  | 显示警告，不阻止运行     | 不影响     |
| 错误 | `"error"` 或 `2` | 显示错误，可阻止程序运行 | 返回非零   |

### 1.2 配置示例

```javascript
// eslint.config.js
export default [
  {
    rules: {
      // 关闭规则
      "no-console": "off",

      // 警告级别
      "no-unused-vars": "warn",

      // 错误级别
      "no-debugger": "error",

      // 数字形式也可以
      "no-alert": 0,
      "no-with": 1,
      "eqeqeq": 2,
    },
  },
];
```

### 1.3 实际效果

```javascript
// 代码
const x = 1;

// 警告输出 (no-unused-vars: "warn")
// ⚠️ 'x' is assigned a value but never used  no-unused-vars

// 错误输出 (no-unused-vars: "error")
// ✖ 'x' is assigned a value but never used  no-unused-vars
```

> **提示**：在 CI/CD 环境中，建议将关键规则设为 `"error"` 级别，以便在发现问题时代码无法合并。

## 2. 规则查找与分类

### 2.1 从错误信息定位

ESLint 输出格式包含规则名：`✖️ message rule-name`

```bash
// 错误信息直接告诉你规则名
'x' is assigned a value but never used  no-unused-vars
```

复制规则名即可在配置中使用或搜索文档。

### 2.2 按场景查找

| 场景             | 推荐方式                                                                                             |
| ---------------- | ---------------------------------------------------------------------------------------------------- |
| 不知道具体规则名 | 描述问题，在 [ESLint 规则页](https://eslint.org/docs/rules/) 搜索                                    |
| TypeScript 问题  | [typescript-eslint 规则](https://typescript-eslint.io/rules/)                                        |
| React 问题       | [eslint-plugin-react 规则](https://github.com/jsx-eslint/eslint-plugin-react/tree/master/docs/rules) |
| Vue 问题         | [eslint-plugin-vue 规则](https://eslint.vuejs.org/rules/)                                            |

### 2.3 规则分类

ESLint 内置规则按功能分为多个类别：

| 分类             | 说明                              |
| ---------------- | --------------------------------- |
| Possible Errors  | 代码错误和潜在逻辑问题            |
| Best Practices   | 最佳实践和代码优化                |
| Strict Mode      | 严格模式相关                      |
| Variables        | 变量声明和使用                    |
| Node.js          | Node.js 环境特定规则              |
| Stylistic Issues | 代码风格格式化（建议用 Prettier） |
| ECMAScript 6     | ES6+ 语法规则                     |
| Deprecated       | 已废弃的规则                      |

> **提示**：在 [ESLint 规则页](https://eslint.org/docs/rules/) 可按类别筛选规则。

### 2.4 规则索引入口

- **主站规则列表**：https://eslint.org/docs/rules/ （按字母排序，支持搜索）
- **官方配置推荐**：`eslint:recommended` 包含最佳实践规则集

```javascript
// 启用推荐配置
import js from '@eslint/js';
export default [js.configs.recommended];
```

## 3. 常用规则详解

### 3.1 变量相关

| 规则             | 说明                 | 自动修复 |
| ---------------- | -------------------- | -------- |
| `no-undef`       | 禁止使用未声明的变量 | 否       |
| `no-unused-vars` | 禁止未使用的变量     | 否       |
| `no-shadow`      | 禁止变量遮蔽         | 否       |
| `prefer-const`   | 优先使用 const       | 是       |

```javascript
// ❌ no-undef - 使用未声明的变量
console.log(myVar);

// ✅ 修复后
const myVar = "hello";
console.log(myVar);

// ❌ no-unused-vars - 未使用的变量
const x = 1;

// ✅ 修复后
console.log(x);

// ❌ no-shadow - 变量遮蔽
const x = 1;
function foo() {
  const x = 2; // 遮蔽外层变量
}
```

### 3.2 代码错误

| 规则                 | 说明               | 自动修复 |
| -------------------- | ------------------ | -------- |
| `no-debugger`        | 禁止 debugger 语句 | 否       |
| `no-empty`           | 禁止空块语句       | 否       |
| `no-unreachable`     | 禁止不可达代码     | 否       |
| `no-unsafe-negation` | 禁止不安全的否定   | 否       |

```javascript
// ❌ no-debugger - 调试语句残留
function debug() {
  debugger;
}

// ❌ no-unsafe-negation - 不安全的否定
if (!key in object) {}

// ✅ 修复后
if (!(key in object)) {}
```

### 3.3 最佳实践

| 规则           | 说明                   | 自动修复 |
| -------------- | ---------------------- | -------- |
| `eqeqeq`       | 强制使用严格相等       | 部分     |
| `no-var`       | 禁止使用 var           | 是       |
| `default-case` | 要求 switch 有 default | 否       |

```javascript
// ❌ eqeqeq - 使用 == 而非 ===
if (a == b) {}

// ✅ 修复后
if (a === b) {}

// ❌ no-var - 使用 var
var count = 1;

// ✅ 修复后
const count = 1;
```

### 3.4 代码风格

> **提示**：stylistic 规则与 Prettier 功能重叠，建议使用 `eslint-config-prettier` 关闭这些规则，让 Prettier 统一处理。

| 规则           | 说明     | 自动修复 |
| -------------- | -------- | -------- |
| `semi`         | 分号风格 | 是       |
| `quotes`       | 引号风格 | 是       |
| `indent`       | 缩进     | 是       |
| `comma-dangle` | 拖尾逗号 | 是       |

## 4. 规则选项配置

### 4.1 规则选项格式

大部分规则可以接受额外选项来定制其行为。

```javascript
rules: {
  // 无选项
  "no-debugger": "error",

  // 带选项（数组形式）
  "semi": ["error", "always"],
  "indent": ["error", 2],
  "quotes": ["error", "single"],
  "max-len": ["error", { "code": 80, "tabWidth": 2 }],
}
```

### 4.2 规则 Schema

每条规则都有 JSON Schema 定义其选项结构。

```bash
# 查看规则的文档和配置选项
npx eslint --rule-details "semi"
# 或访问 https://eslint.org/docs/rules/semi
```

**常见选项模式**：

```javascript
// 布尔选项
"no-unused-vars": ["error", { "argsIgnorePattern": "^_" }]

// 枚举选项
"quotes": ["error", "single", { "avoidEscape": true }]

// 数组选项
"no-multiple-empty-lines": ["error", { "max": 2, "maxEOF": 1 }]

// 嵌套对象
"indent": ["error", 2, {
  "SwitchCase": 1,
  "VariableDeclarator": 2,
  "FunctionExpression": { "body": 1, "parameters": 2 }
}]
```

### 4.3 常用规则配置示例

```javascript
// eslint.config.js
export default [
  {
    rules: {
      // 分号：始终使用分号
      "semi": ["error", "always"],

      // 引号：单引号，允许嵌套双引号
      "quotes": ["error", "single", { "avoidEscape": true }],

      // 缩进：2 空格
      "indent": ["error", 2],

      // 逗号：多行结构要求拖尾逗号
      "comma-dangle": ["error", "always-multiline"],

      // 最大行长度：80 字符，忽略 URL
      "max-len": ["error", { "code": 80, "ignoreUrls": true }],

      // 未使用变量：忽略下划线开头的参数
      "no-unused-vars": ["warn", {
        "argsIgnorePattern": "^_",
        "varsIgnorePattern": "^_"
      }],

      // 对象字面量大括号间距
      "object-curly-spacing": ["error", "always"],

      // 箭头函数空格
      "arrow-spacing": ["error", { "before": true, "after": true }],
    },
  },
];
```

## 5. Extends 继承

Extends（继承）允许复用已有的配置，减少重复配置的工作量。在 Flat Config 中，继承通过数组配置实现。

### 5.1 eslint:recommended

ESLint 内置的推荐配置，包含最常用的规则。

```javascript
// eslint.config.js
import js from '@eslint/js';

export default [
  js.configs.recommended,
];
```

**eslint:recommended 包含的规则示例**：

| 规则              | 严重程度 |
| ----------------- | -------- |
| `no-unused-vars`  | warn     |
| `no-unreachable`  | error    |
| `no-dupe-else-if` | error    |
| `no-empty`        | warn     |
| `no-extra-semi`   | error    |

### 5.2 继承多个配置

```javascript
// eslint.config.js
import js from '@eslint/js';
import react from 'eslint-plugin-react';
import reactHooks from 'eslint-plugin-react-hooks';
import tseslint from 'typescript-eslint';

export default [
  // 官方推荐配置
  js.configs.recommended,

  // TypeScript 推荐配置
  ...tseslint.configs.recommended,

  // React 配置
  {
    files: ['**/*.{jsx,tsx}'],
    plugins: {
      react,
      'react-hooks': reactHooks,
    },
    settings: {
      react: {
        version: 'detect',
      },
    },
    rules: {
      'react/jsx-uses-react': 'error',
      'react/jsx-uses-vars': 'error',
    },
  },
];
```

### 5.3 共享配置

npm 上有大量共享配置可供使用。

| 配置包                   | 说明                       |
| ------------------------ | -------------------------- |
| `eslint-config-airbnb`   | Airbnb JavaScript 风格指南 |
| `eslint-config-standard` | Standard JS 风格指南       |
| `eslint-config-google`   | Google JavaScript 风格指南 |
| `eslint-config-prettier` | 关闭与 Prettier 冲突的规则 |
| `typescript-eslint`      | TypeScript 官方推荐配置    |

```javascript
// eslint.config.js
import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import prettier from 'eslint-config-prettier';

export default [
  js.configs.recommended,
  ...tseslint.configs.recommended,
  prettier, // 放在最后，关闭冲突规则
];
```

### 5.4 继承优先级

ESLint 配置数组中，后面的配置会覆盖前面的规则。

```javascript
export default [
  // 1. 官方推荐配置（优先级最低）
  js.configs.recommended,

  // 2. 框架/语言配置
  ...tseslint.configs.recommended,

  // 3. 关闭冲突规则（Prettier 必须放最后）
  prettier,

  // 4. 项目自定义规则（优先级最高）
  {
    rules: {
      // 这里可以覆盖前面所有配置
      'no-unused-vars': 'warn',
    },
  },
];
```

## 6. Plugins 扩展

Plugins（插件）扩展了 ESLint 的功能，可以添加自定义规则、环境配置和处理特定文件类型的能力。

### 6.1 常用插件

| 插件名称                    | 说明               | 安装命令                                |
| --------------------------- | ------------------ | --------------------------------------- |
| `eslint-plugin-react`       | React 规则         | `npm install eslint-plugin-react`       |
| `eslint-plugin-react-hooks` | React Hooks 规则   | `npm install eslint-plugin-react-hooks` |
| `eslint-plugin-vue`         | Vue 规则           | `npm install eslint-plugin-vue`         |
| `eslint-plugin-typescript`  | TypeScript 规则    | 已包含在 typescript-eslint 中           |
| `eslint-plugin-import`      | import/export 规则 | `npm install eslint-plugin-import`      |
| `eslint-plugin-promise`     | Promise 最佳实践   | `npm install eslint-plugin-promise`     |
| `eslint-plugin-n`           | Node.js 规则       | `npm install eslint-plugin-n`           |
| `eslint-plugin-unicorn`     | 现代化 JS 最佳实践 | `npm install eslint-plugin-unicorn`     |

### 6.2 配置插件

```javascript
// eslint.config.js
import js from '@eslint/js';
import react from 'eslint-plugin-react';
import reactHooks from 'eslint-plugin-react-hooks';
import importPlugin from 'eslint-plugin-import';
import promisePlugin from 'eslint-plugin-promise';
import unicornPlugin from 'eslint-plugin-unicorn';

export default [
  js.configs.recommended,

  // 添加插件
  {
    plugins: {
      react,
      'react-hooks': reactHooks,
      import: importPlugin,
      promise: promisePlugin,
      unicorn: unicornPlugin,
    },

    // 配置规则
    rules: {
      // React 规则
      'react/jsx-uses-react': 'error',
      'react/jsx-uses-vars': 'error',
      'react/prop-types': 'warn',

      // React Hooks 规则
      'react-hooks/rules-of-hooks': 'error',
      'react-hooks/exhaustive-deps': 'warn',

      // import 规则
      'import/order': ['error', { 'alphabetize': { 'order': 'asc' } }],
      'import/no-unresolved': 'error',

      // promise 规则
      'promise/always-return': 'error',
      'promise/catch-or-return': 'error',

      // unicorn 规则
      'unicorn/better-regex': 'error',
      'unicorn/prefer-string-slice': 'error',
    },
  },
];
```

### 6.3 插件规则命名空间

插件中的规则使用 `plugin-name/rule-name` 格式引用：

```javascript
rules: {
  // react 插件的 jsx-uses-react 规则
  'react/jsx-uses-react': 'error',

  // react-hooks 插件的 rules-of-hooks 规则
  'react-hooks/rules-of-hooks': 'error',

  // import 插件的 order 规则
  'import/order': 'error',
}
```

### 6.4 常用插件规则示例

**eslint-plugin-import**：

```javascript
// import 排序
'import/order': ['error', {
  'groups': [
    'builtin',
    'external',
    'internal',
    'parent',
    'sibling',
    'index',
  ],
  'alphabetize': {
    'order': 'asc',
    'caseInsensitive': true,
  },
}],

// 禁止未解析的导入
'import/no-unresolved': 'error',

// 禁止默认导出与文件名不匹配
'import/no-default-export': 'warn',
```

**eslint-plugin-react-hooks**：

```javascript
// Hooks 调用规则
'react-hooks/rules-of-hooks': 'error',

// 依赖项检查
'react-hooks/exhaustive-deps': 'warn',
```

**eslint-plugin-unicorn**：

```javascript
// 更好的正则表达式
'unicorn/better-regex': 'error',

// 优先使用字符串方法
'unicorn/prefer-string-slice': 'error',

// 优先使用数组方法
'unicorn/prefer-array-find': 'error',

// 禁止特定魔法数字
'unicorn/no-new-buffer': 'error',
```

## 7. 完整配置示例

```javascript
// eslint.config.js
import js from '@eslint/js';
import react from 'eslint-plugin-react';
import reactHooks from 'eslint-plugin-react-hooks';
import tseslint from 'typescript-eslint';
import importPlugin from 'eslint-plugin-import';
import promisePlugin from 'eslint-plugin-promise';
import prettier from 'eslint-config-prettier';

export default [
  // 1. 基础配置
  js.configs.recommended,

  // 2. TypeScript 配置
  ...tseslint.configs.recommended,

  // 3. React + Hooks 配置
  {
    files: ['**/*.{jsx,tsx}'],
    plugins: {
      react,
      'react-hooks': reactHooks,
    },
    settings: {
      react: {
        version: 'detect',
      },
    },
    rules: {
      'react/jsx-uses-react': 'error',
      'react/jsx-uses-vars': 'error',
      'react-hooks/rules-of-hooks': 'error',
      'react-hooks/exhaustive-deps': 'warn',
    },
  },

  // 4. 通用规则配置
  {
    rules: {
      // 错误级别
      'no-debugger': 'error',
      'no-console': process.env.NODE_ENV === 'production' ? 'error' : 'warn',
      'no-unused-vars': ['warn', { 'argsIgnorePattern': '^_' }],
      'prefer-const': 'error',
      'no-var': 'error',

      // 引号和分号
      'quotes': ['error', 'single', { 'avoidEscape': true }],
      'semi': ['error', 'always'],
      'comma-dangle': ['error', 'always-multiline'],

      // 缩进和间距
      'indent': ['error', 2],
      'comma-spacing': ['error', { 'before': false, 'after': true }],
      'object-curly-spacing': ['error', 'always'],

      // import 规则
      'import/order': ['error', {
        'groups': ['builtin', 'external', 'internal', 'parent', 'sibling'],
        'alphabetize': { 'order': 'asc' },
      }],
      'import/no-unresolved': 'error',

      // promise 规则
      'promise/catch-or-return': 'error',
    },
  },

  // 5. 放在最后，关闭与 Prettier 冲突的规则
  prettier,
];
```

## 8. 总结

### 8.1 核心要点

规则是 ESLint 的核心，通过合理配置规则、Extends 和 Plugins，可以构建完整的代码质量检查体系。关键要点如下：

- **严重程度控制**：`off`/`warn`/`error` 三个级别，控制规则检查行为
- **规则查找**：从错误信息获取规则名，或通过 ESLint 官网按场景搜索
- **规则选项**：大部分规则支持配置选项，使用数组形式传递
- **配置继承**：通过 extends 复用预设配置，后面的优先级高
- **插件扩展**：社区插件提供大量特定框架/场景的规则

### 8.2 速查表

| 分类     | 常用规则                                                             |
| -------- | -------------------------------------------------------------------- |
| 潜在错误 | `no-debugger`、`no-empty`、`no-unreachable`、`no-unsafe-negation`    |
| 最佳实践 | `eqeqeq`、`no-var`、`prefer-const`、`no-unused-vars`、`default-case` |
| 严格模式 | `strict`                                                             |
| 变量     | `no-undef`、`no-unused-vars`、`no-shadow`                            |
| Node.js  | `no-process-exit`、`no-path-concat`、`handle-callback-err`           |
| 风格     | `semi`、`quotes`、`indent`、`comma-dangle`                           |

### 8.3 最佳实践

- 使用 Prettier 处理代码风格，ESLint 专注代码质量
- 在 CI 中将关键规则设为 error 级别
- 使用 `eslint-config-prettier` 避免规则冲突
- 为不同文件类型创建独立的配置块

## 参考资源

- [ESLint 规则列表](https://eslint.org/docs/rules/)
- [ESLint 配置指南](https://eslint.org/docs/latest/use/configure/)
- [typescript-eslint](https://typescript-eslint.io/)
- [eslint-plugin-import](https://github.com/import-js/eslint-plugin-import)
- [eslint-plugin-react](https://github.com/jsx-eslint/eslint-plugin-react)
- [eslint-config-prettier](https://github.com/prettier/eslint-config-prettier)
