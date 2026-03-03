# ESLint 框架集成完全指南

本指南详细介绍 ESLint 与主流前端框架（TypeScript、React、Vue）的集成配置，以及主流脚手架工具（Next.js、Vite）的最佳实践。通过合理的框架集成，可以实现代码质量的统一检查，提升开发效率。

## 1. TypeScript 集成

### 1.1 @typescript-eslint 概述

@typescript-eslint 是 TypeScript 官方维护的 ESLint 工具链，由两个核心包组成：

| 包名                               | 说明                                                              |
| ---------------------------------- | ----------------------------------------------------------------- |
| `@typescript-eslint/parser`        | TypeScript 解析器，将 TypeScript 代码转换为 ESLint 可以分析的 AST |
| `@typescript-eslint/eslint-plugin` | 提供 100+ TypeScript 特有的 lint 规则                             |

**为什么需要 @typescript-eslint：**

```typescript
// ❌ ESLint 默认解析器无法解析 TypeScript 语法
function greet(name: string): string {
  return `Hello, ${name}`;
}

type User = {
  name: string;
  age: number;
};

interface Config {
  theme: 'light' | 'dark';
}
```

@typescript-eslint 能够解析 TypeScript 特有语法，并提供类型感知的代码检查能力。

### 1.2 安装与配置

**安装依赖：**

```bash
// 推荐：使用 typescript-eslint 统一包
npm install --save-dev typescript-eslint

// 或分别安装
npm install --save-dev @typescript-eslint/parser @typescript-eslint/eslint-plugin
```

**基础配置（ESLint v9 Flat Config）：**

```javascript
// eslint.config.mjs
import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  eslint.configs.recommended,
  tseslint.configs.recommended,
);
```

这个配置启用了 ESLint 推荐规则和 @typescript-eslint 推荐规则。typescript-eslint 提供了多种预设配置：

| 配置名称                                  | 说明                   |
| ----------------------------------------- | ---------------------- |
| `tseslint.configs.recommended`            | 推荐配置（基础）       |
| `tseslint.configs.strict`                 | 严格配置（更严格检查） |
| `tseslint.configs.stylistic`              | 风格配置（代码风格）   |
| `tseslint.configs.recommendedTypeChecked` | 类型感知推荐配置       |

### 1.3 类型感知 Linting

类型感知 linting 利用 TypeScript 编译器的类型信息进行代码检查，能够发现普通 linting 无法检测的问题。

**启用类型感知：**

```javascript
// eslint.config.mjs
import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  eslint.configs.recommended,
  // 使用类型感知的推荐配置
  ...tseslint.configs.recommendedTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        // 启用类型感知
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },
);
```

**类型感知规则示例：**

```typescript
// ❌ 类型感知可以检测不安全的赋值
const value: string = getValue(); // 如果 getValue() 返回 number，会报错

// ❌ 类型感知可以检测不安全的函数调用
obj.method(); // 如果 method 不存在于 obj 类型中，会报错

// ❌ 类型感知可以检测不必要的条件
function process(value: string | null) {
  if (value && value.length > 0) { // value 为 string 时 && 后总是 value
    // 警告：不必要的条件
  }
}
```

> **提示**：启用类型感知需要配置 `projectService: true` 或 `project: './tsconfig.json'`，这会增加 linting 时间，建议在 CI 环境中使用。

## 2. React 集成

### 2.1 eslint-plugin-react

eslint-plugin-react 是 React 项目最核心的 lint 插件，提供 JSX 语法规范和组件最佳实践检查。

**安装依赖：**

```bash
npm install --save-dev eslint-plugin-react
```

**配置示例：**

```javascript
// eslint.config.mjs
import react from 'eslint-plugin-react';

export default [
  // 使用内置 flat config（eslint-plugin-react v7.33+）
  react.configs.flat.recommended,
  react.configs.flat['jsx-runtime'], // React 17+ 新 JSX 转换

  {
    settings: {
      react: {
        version: 'detect', // 自动检测已安装的 React 版本
      },
    },
  },
];
```

**React 版本配置：**

`eslint-plugin-react` 需要知道 React 版本才能应用对应的规则：

```javascript
// ❌ 不配置版本会收到警告
// Warning: React version not specified in eslint-plugin-react settings

// ✅ 配置自动检测
{
  settings: {
    react: {
      version: 'detect',
    },
  },
}
```

### 2.2 eslint-plugin-react-hooks

eslint-plugin-react-hooks 由 React 官方团队维护，提供两条核心规则：

**安装依赖：**

```bash
npm install --save-dev eslint-plugin-react-hooks
```

**配置示例：**

```javascript
{
  plugins: {
    'react-hooks': reactHooks,
  },
  rules: {
    'react-hooks/rules-of-hooks': 'error',    // Hooks 调用规范
    'react-hooks/exhaustive-deps': 'warn',    // 依赖数组完整性
  },
}
```

**rules-of-hooks 规则：**

```jsx
// ❌ 条件语句中调用 Hook —— 运行时错误
function SearchBar({ hasFilter }) {
  if (hasFilter) {
    const [query, setQuery] = useState(''); // 报错
  }
}

// ✅ 正确：始终在顶层调用
function SearchBar({ hasFilter }) {
  const [query, setQuery] = useState('');
  if (!hasFilter) return null;
  return <input value={query} onChange={e => setQuery(e.target.value)} />;
}
```

**exhaustive-deps 规则：**

```jsx
// ❌ 依赖数组缺少 userId
function UserProfile({ userId }) {
  useEffect(() => {
    fetchUser(userId).then(setUser);
  }, []); // userId 变化时不会重新执行
}

// ✅ 正确：补全依赖
function UserProfile({ userId }) {
  useEffect(() => {
    fetchUser(userId).then(setUser);
  }, [userId]);
}
```

> **提示**：建议将 `exhaustive-deps` 设为 `'warn'` 而非 `'error'`，因为有些场景需要刻意省略依赖。

### 2.3 JSX 规则

以下是 eslint-plugin-react 中最实用的 JSX 规则：

| 规则名称                        | 说明                            | 严重程度 |
| ------------------------------- | ------------------------------- | -------- |
| `react/jsx-key`                 | 列表渲染必须有 `key` 属性       | error    |
| `react/jsx-no-target-blank`     | 外链必须添加 `rel="noreferrer"` | error    |
| `react/jsx-pascal-case`         | 组件名必须使用 PascalCase       | error    |
| `react/self-closing-comp`       | 无子元素的组件使用自闭合标签    | warn     |
| `react/no-array-index-key`      | 禁止用数组索引作 key            | warn     |
| `react/jsx-no-useless-fragment` | 禁止不必要的 Fragment           | warn     |

**规则示例：**

```jsx
// ❌ jsx-key：列表缺少 key
function TaskList({ tasks }) {
  return tasks.map(task => <li>{task.name}</li>);
}

// ✅ 修复后
function TaskList({ tasks }) {
  return tasks.map(task => <li key={task.id}>{task.name}</li>);
}

// ❌ jsx-no-target-blank：外链安全问题
function ExternalLink({ href }) {
  return <a href={href} target="_blank">打开链接</a>;
}

// ✅ 修复后
function ExternalLink({ href }) {
  return <a href={href} target="_blank" rel="noreferrer">打开链接</a>;
}

// ❌ self-closing-comp：无子元素却用空标签对
function Form() {
  return <Input></Input>;
}

// ✅ 修复后
function Form() {
  return <Input />;
}
```

## 3. Vue 集成

### 3.1 eslint-plugin-vue

eslint-plugin-vue 是 Vue 官方维护的 ESLint 插件，支持 Vue 单文件组件（SFC）的检查。

**安装依赖：**

```bash
npm install --save-dev eslint-plugin-vue vue-eslint-parser
```

**配置示例：**

```javascript
// eslint.config.mjs
import vue from 'eslint-plugin-vue';
import vueParser from 'vue-eslint-parser';
import js from '@eslint/js';

export default [
  js.configs.recommended,
  ...vue.configs['flat/recommended'],
  {
    files: ['**/*.vue'],
    languageOptions: {
      parser: vueParser,
      parserOptions: {
        ecmaVersion: 2022,
        sourceType: 'module',
      },
    },
    rules: {
      // Vue 3 推荐使用 composition API
      'vue/no-computed-properties-in-data': 'error',
      'vue/multi-word-component-names': 'off',
    },
  },
];
```

**Vue 规则配置层级：**

eslint-plugin-vue 提供多个预设配置：

| 配置名称                          | 说明                       |
| --------------------------------- | -------------------------- |
| `vue.configs.base`                | 基础规则（适用于 Vue 2/3） |
| `vue.configs.essential`           | 核心规则（错误检查）       |
| `vue.configs.recommended`         | 推荐规则（Vue 3 最佳实践） |
| `vue.configs['flat/recommended']` | Flat Config 推荐配置       |
| `vue.configs['flat/essential']`   | Flat Config 核心配置       |

**Vue 3 常用规则：**

```javascript
{
  rules: {
    // 必须配置
    'vue/multi-word-component-names': 'off', // 允许单字母组件名

    // 推荐的 Vue 3 规则
    'vue/component-api-style': ['error', ['script setup', 'composition']],
    'vue/component-tags-order': ['error', {
      order: ['script', 'template', 'style'],
    }],
    'vue/define-macros-order': ['error', {
      definePropsRef: 'defineProps',
      defineEmits: 'defineEmits',
    }],
    'vue/no-empty-component-block': 'warn',
    'vue/no-multiple-objects-in-class': 'warn',
    'vue/padding-line-between-blocks': 'warn',
    'vue/prefer-separate-static-class': 'warn',
  },
}
```

**script setup 语法支持：**

```vue
<script setup>
// ❌ no-undef：defineProps 和 defineEmits 需要特殊配置
const props = defineProps({
  title: String,
});

// ✅ 配置后可以正确识别
const emit = defineEmits(['update']);
</script>

<template>
  <div>{{ title }}</div>
</template>
```

## 4. 脚手架配置

### 4.1 Next.js

Next.js 内置了 `@next/eslint-plugin-next`，通过 `next lint` 命令运行。从 Next.js 15 开始，脚手架默认生成 ESLint 9 flat config。

**安装依赖：**

```bash
npm install --save-dev @next/eslint-plugin-next
```

**配置示例：**

```javascript
// eslint.config.mjs
import { dirname } from 'path';
import { fileURLToPath } from 'url';
import { FlatCompat } from '@eslint/eslintrc';
import tseslint from 'typescript-eslint';
import react from 'eslint-plugin-react';
import reactHooks from 'eslint-plugin-react-hooks';
import globals from 'globals';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// 使用 FlatCompat 兼容 Next.js 的旧式配置
const compat = new FlatCompat({
  baseDirectory: __dirname,
});

export default tseslint.config(
  // 1. Next.js 核心规则（通过 FlatCompat 适配）
  ...compat.extends('next/core-web-vitals'),

  // 2. TypeScript 推荐规则
  ...tseslint.configs.recommended,

  // 3. React 插件（Next.js 已使用新 JSX 转换）
  react.configs.flat['jsx-runtime'],

  // 4. 全局配置
  {
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
      },
    },
    plugins: {
      'react-hooks': reactHooks,
    },
    settings: {
      react: {
        version: 'detect',
      },
    },
    rules: {
      // Hooks 规则
      'react-hooks/rules-of-hooks': 'error',
      'react-hooks/exhaustive-deps': 'warn',

      // JSX 规范
      'react/jsx-pascal-case': 'error',
      'react/no-array-index-key': 'warn',

      // React 17+ 不需要手动导入 React
      'react/react-in-jsx-scope': 'off',
      'react/jsx-uses-react': 'off',

      // TypeScript 规则调整
      '@typescript-eslint/no-unused-vars': ['warn', {
        argsIgnorePattern: '^_',
        varsIgnorePattern: '^_',
      }],
    },
  },

  // 5. 忽略 Next.js 生成的文件
  {
    ignores: ['.next/', 'out/', 'node_modules/'],
  },
);
```

**next/core-web-vitals 包含的规则：**

| 规则                                | 说明                                    |
| ----------------------------------- | --------------------------------------- |
| `@next/next/no-html-link-for-pages` | 禁止用 `<a>` 替代 `<Link>` 进行页面跳转 |
| `@next/next/no-img-element`         | 禁止使用 `<img>`，应使用 `<Image>` 组件 |
| `@next/next/no-sync-scripts`        | 禁止同步脚本影响渲染性能                |
| `@next/next/google-font-display`    | Google Font 需要配置 font-display       |

### 4.2 Vite

Vite 官方脚手架（`create vite`）已内置基础 ESLint 配置。Vite 项目特有的插件是 `eslint-plugin-react-refresh`，确保组件在 HMR 时正确刷新。

**安装依赖：**

```bash
npm install --save-dev eslint-plugin-react-refresh
```

**配置示例：**

```javascript
// eslint.config.js
import js from '@eslint/js';
import globals from 'globals';
import react from 'eslint-plugin-react';
import reactHooks from 'eslint-plugin-react-hooks';
import reactRefresh from 'eslint-plugin-react-refresh';
import tseslint from 'typescript-eslint';
import prettier from 'eslint-config-prettier';

export default tseslint.config(
  // 忽略构建产物
  { ignores: ['dist/', 'node_modules/'] },

  // 基础规则
  js.configs.recommended,
  ...tseslint.configs.recommended,

  // React 规则（新 JSX 转换）
  react.configs.flat['jsx-runtime'],

  {
    files: ['**/*.{ts,tsx}'],
    languageOptions: {
      ecmaVersion: 2020,
      globals: globals.browser,
    },
    plugins: {
      'react-hooks': reactHooks,
      'react-refresh': reactRefresh,
    },
    settings: {
      react: {
        version: 'detect',
      },
    },
    rules: {
      // Hooks 规则
      ...reactHooks.configs.recommended.rules,
      'react-hooks/exhaustive-deps': 'warn',

      // Vite HMR：确保模块导出正确
      'react-refresh/only-export-components': ['warn', {
        allowConstantExport: true,
      }],

      // JSX 规范
      'react/jsx-pascal-case': 'error',
      'react/jsx-no-target-blank': 'error',
      'react/self-closing-comp': 'warn',

      // TypeScript 规则
      '@typescript-eslint/no-unused-vars': ['warn', {
        argsIgnorePattern: '^_',
        varsIgnorePattern: '^_',
      }],
      '@typescript-eslint/no-explicit-any': 'warn',
    },
  },

  // 放在最后，关闭与 Prettier 冲突的格式规则
  prettier,
);
```

**eslint-plugin-react-refresh 说明：**

```jsx
// ❌ 同一文件同时导出组件和非组件值，会导致 HMR 失效
export const API_URL = 'https://api.example.com'; // 警告
export function UserCard() {
  return <div />;
}

// ✅ 将常量移到独立文件，或使用 allowConstantExport 选项
// constants.ts
export const API_URL = 'https://api.example.com';
```

## 5. 完整配置示例

以下是一个整合了 TypeScript、React、Vue 的完整配置示例，适用于多框架项目：

```javascript
// eslint.config.mjs
import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';
import react from 'eslint-plugin-react';
import reactHooks from 'eslint-plugin-react-hooks';
import vue from 'eslint-plugin-vue';
import vueParser from 'vue-eslint-parser';
import globals from 'globals';
import prettier from 'eslint-config-prettier';

export default tseslint.config(
  // 0. 忽略文件
  { ignores: ['dist/', 'node_modules/', 'build/', '.next/', 'out/'] },

  // 1. 基础配置
  eslint.configs.recommended,
  ...tseslint.configs.recommended,
  ...tseslint.configs.strict,

  // 2. React 配置
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
      ...react.configs.flat.recommended.rules,
      ...react.configs.flat['jsx-runtime'].rules,
      ...reactHooks.configs.recommended.rules,
      'react-hooks/exhaustive-deps': 'warn',
      'react/jsx-pascal-case': 'error',
      'react/jsx-no-target-blank': 'error',
      'react/self-closing-comp': 'warn',
      'react/no-array-index-key': 'warn',
      'react/react-in-jsx-scope': 'off',
    },
  },

  // 3. Vue 配置
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
      vue,
    },
    rules: {
      ...vue.configs['flat/recommended'].rules,
      'vue/multi-word-component-names': 'off',
    },
  },

  // 4. 全局变量
  {
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
        ...globals.es2022,
      },
    },
  },

  // 5. 自定义规则
  {
    rules: {
      // TypeScript 规则
      '@typescript-eslint/no-unused-vars': ['warn', {
        argsIgnorePattern: '^_',
        varsIgnorePattern: '^_',
      }],
      '@typescript-eslint/no-explicit-any': 'warn',

      // 关闭与 Prettier 冲突的规则
      'no-console': process.env.NODE_ENV === 'production' ? 'error' : 'warn',
    },
  },

  // 6. Prettier（放在最后）
  prettier,
);
```

**package.json scripts：**

```json
{
  "scripts": {
    "lint": "eslint src/",
    "lint:fix": "eslint src/ --fix",
    "lint:cache": "eslint src/ --cache",
    "typecheck": "tsc --noEmit"
  }
}
```

## 6. 总结

### 6.1 核心要点

| 框架/工具  | 核心插件                                            | 关键配置                               |
| ---------- | --------------------------------------------------- | -------------------------------------- |
| TypeScript | `typescript-eslint`                                 | `projectService: true`                 |
| React      | `eslint-plugin-react` + `eslint-plugin-react-hooks` | `settings.react.version`               |
| Vue        | `eslint-plugin-vue` + `vue-eslint-parser`           | `files: ['**/*.vue']`                  |
| Next.js    | `@next/eslint-plugin-next`                          | `next/core-web-vitals`                 |
| Vite       | `eslint-plugin-react-refresh`                       | `react-refresh/only-export-components` |

**集成原则：**

1. **从预设配置开始**：先使用框架推荐的预设，再根据项目需求调整
2. **分层配置**：不同文件类型使用不同的配置块（`files` 字段）
3. **版本检测**：React 和 Vue 配置中启用版本自动检测
4. **Prettier 整合**：在配置最后添加 `eslint-config-prettier` 避免冲突
5. **类型感知**：TypeScript 项目启用类型感知可以获得更准确的检查

### 6.2 速查表

| 场景                | 推荐配置                                                           |
| ------------------- | ------------------------------------------------------------------ |
| 快速开始 TypeScript | `typescript-eslint` + `tseslint.configs.recommended`               |
| 启用类型感知检查    | `tseslint.configs.recommendedTypeChecked` + `projectService: true` |
| React 项目          | `eslint-plugin-react` + `eslint-plugin-react-hooks`                |
| React + TypeScript  | 上述 + `typescript-eslint`                                         |
| Vue 3 项目          | `eslint-plugin-vue` + `vue-eslint-parser`                          |
| Next.js 项目        | `next/core-web-vitals` + `typescript-eslint`                       |
| Vite React 项目     | `eslint-plugin-react-refresh`                                      |
| 与 Prettier 配合    | 添加 `eslint-config-prettier`（放在配置最后）                      |

| 命令                      | 说明                   |
| ------------------------- | ---------------------- |
| `npx eslint src/`         | 检查 src 目录          |
| `npx eslint --fix src/`   | 自动修复可修复的问题   |
| `npx eslint --cache src/` | 启用缓存提高性能       |
| `npx next lint`           | Next.js 项目 lint 检查 |

### 6.3 常见问题

**Q1：React 17+ 不需要在文件顶部导入 React，如何配置？**

```javascript
// 方式一：使用 flat['jsx-runtime'] 预置配置
react.configs.flat['jsx-runtime']

// 方式二：手动关闭规则
{
  rules: {
    'react/react-in-jsx-scope': 'off',
    'react/jsx-uses-react': 'off',
  },
}
```

**Q2：TypeScript linting 太慢怎么办？**

```javascript
// 使用 projectService 代替 project
{
  parserOptions: {
    projectService: true,
    tsconfigRootDir: import.meta.dirname,
  },
}

// 或为测试文件禁用类型检查
{
  files: ['**/*.test.ts', '**/*.spec.ts'],
  languageOptions: {
    parserOptions: {
      project: undefined,
    },
  },
}
```

**Q3：Vue 文件 lint 失败提示找不到 defineProps？**

确保配置了 `vue-eslint-parser` 作为 Vue 文件的解析器，并且使用了支持 `<script setup>` 的 ESLint 配置。

## 参考资源

- [ESLint 官方文档](https://eslint.org/)
- [typescript-eslint 官方文档](https://typescript-eslint.io/)
- [eslint-plugin-react 规则列表](https://github.com/jsx-eslint/eslint-plugin-react)
- [eslint-plugin-react-hooks](https://github.com/facebook/react/tree/main/packages/eslint-plugin-react-hooks)
- [eslint-plugin-vue 官方文档](https://eslint.vuejs.org/)
- [Next.js ESLint 配置](https://nextjs.org/docs/app/api-reference/config/eslint)
- [ESLint Flat Config 迁移指南](https://eslint.org/docs/latest/use/configure/migration-guide)
