# Babel 入门指南

Babel 是 JavaScript 编译器，能将现代 JavaScript 代码转换为向后兼容的版本，让开发者无需等待浏览器支持即可使用最新语法特性。

## 1. 概述

```javascript
// ✅ 输入：现代 JavaScript
const greet = (name) => `Hello, ${name}!`;
[1, 2, 3].map((n) => n * 2);

// ✅ 输出：兼容旧浏览器的代码
var greet = function (name) {
  return "Hello, " + name + "!";
};
[1, 2, 3].map(function (n) {
  return n * 2;
});
```

### 1.1 Babel 能做什么

| 功能            | 说明                            |
| --------------- | ------------------------------- |
| 语法转换        | 将 ES6+ 语法转换为 ES5          |
| Polyfill 注入   | 为目标环境添加缺失的功能        |
| JSX 转换        | 编译 React JSX 语法             |
| TypeScript 编译 | 移除类型注解，转换为 JavaScript |
| 自定义转换      | 通过插件实现代码重构、优化等    |

### 1.2 核心编译流程

```
源代码 → 解析(Parse) → AST → 转换(Transform) → AST → 生成(Generate) → 目标代码
```

Babel 的编译过程分为三个阶段：

1. **解析**：将源代码解析为抽象语法树（AST）
2. **转换**：遍历 AST 并应用插件进行转换
3. **生成**：将转换后的 AST 生成目标代码

## 2. 核心包

### 2.1 核心包介绍

| 包名                       | 作用                                   |
| -------------------------- | -------------------------------------- |
| `@babel/core`              | Babel 核心编译引擎                     |
| `@babel/cli`               | 命令行工具                             |
| `@babel/preset-env`        | 智能预设，根据目标环境自动确定转换规则 |
| `@babel/preset-react`      | React JSX 转换预设                     |
| `@babel/preset-typescript` | TypeScript 转换预设                    |

### 2.2 Preset 与 Plugin 的关系

```
Plugin（插件）：单一功能的转换规则
    ↓
Preset（预设）：一组 Plugin 的集合
```

> **提示**：Preset 是预先配置好的插件集合，避免手动配置大量插件。

## 3. 快速开始

### 3.1 安装

```bash
# 安装核心包和 CLI
npm install --save-dev @babel/core @babel/cli

# 安装常用预设
npm install --save-dev @babel/preset-env
```

### 3.2 创建配置文件

在项目根目录创建 `babel.config.json`：

```json
{
  "presets": ["@babel/preset-env"]
}
```

### 3.3 编译代码

```bash
# 编译单个文件
npx babel src/index.js --out-file dist/index.js

# 编译整个目录
npx babel src --out-dir dist

# 监听文件变化
npx babel src --out-dir dist --watch
```

## 4. 配置详解

### 4.1 配置文件类型

| 文件名                           | 格式       | 适用场景           |
| -------------------------------- | ---------- | ------------------ |
| `babel.config.json`              | JSON       | 项目级配置（推荐） |
| `babel.config.js`                | JavaScript | 需要动态配置时使用 |
| `.babelrc.json`                  | JSON       | 目录级配置         |
| `package.json` 中的 `babel` 字段 | JSON       | 简单项目           |

### 4.2 配置结构

```jsonc
{
  "presets": [
    // 预设列表
  ],
  "plugins": [
    // 插件列表
  ],
  "env": {
    // 环境特定配置
  },
}
```

### 4.3 执行顺序

```
Plugins → Presets
   ↓         ↓
 正序执行   逆序执行
```

- **Plugins**：从前往后执行
- **Presets**：从后往前执行

```jsonc
{
  "presets": ["c", "b", "a"],
  "plugins": ["1", "2", "3"],
}
// 执行顺序：1 → 2 → 3 → a → b → c
```

## 5. @babel/preset-env 详解

`@babel/preset-env` 是最重要的预设，能根据目标环境智能选择需要的转换规则。

### 5.1 targets 配置

指定目标运行环境：

```json
{
  "presets": [
    [
      "@babel/preset-env",
      {
        "targets": {
          "chrome": "80",
          "firefox": "78",
          "safari": "14",
          "edge": "88"
        }
      }
    ]
  ]
}
```

使用 Browserslist 查询语法：

```json
{
  "presets": [
    [
      "@babel/preset-env",
      {
        "targets": "> 0.25%, not dead"
      }
    ]
  ]
}
```

> **提示**：也可以在 `package.json` 或 `.browserslistrc` 文件中配置 browserslist，Babel 会自动读取。

### 5.2 useBuiltIns 配置

控制 polyfill 的引入方式：

| 值        | 说明                                      |
| --------- | ----------------------------------------- |
| `false`   | 不自动引入 polyfill（默认）               |
| `"entry"` | 根据目标环境，在入口处引入所需 polyfill   |
| `"usage"` | 按需引入，只引入代码中实际使用的 polyfill |

```json
{
  "presets": [
    [
      "@babel/preset-env",
      {
        "useBuiltIns": "usage",
        "corejs": "3.47"
      }
    ]
  ]
}
```

> **注意**：使用 `useBuiltIns` 时必须安装并指定 `core-js` 版本。

```bash
npm install core-js@3
```

### 5.3 modules 配置

控制模块系统转换：

| 值           | 说明                    |
| ------------ | ----------------------- |
| `"auto"`     | 自动检测（默认）        |
| `false`      | 保留 ES modules，不转换 |
| `"commonjs"` | 转换为 CommonJS         |
| `"amd"`      | 转换为 AMD              |
| `"umd"`      | 转换为 UMD              |

```json
{
  "presets": [
    [
      "@babel/preset-env",
      {
        "modules": false
      }
    ]
  ]
}
```

> **提示**：使用 Webpack 等打包工具时，建议设置 `modules: false` 以支持 Tree Shaking。

## 6. 实战场景

### 6.1 场景1：基础 JavaScript 项目

项目结构：

```
my-project/
├── src/
│   └── index.js
├── dist/
├── babel.config.json
└── package.json
```

**babel.config.json**：

```json
{
  "presets": [
    [
      "@babel/preset-env",
      {
        "targets": "> 0.5%, last 2 versions, not dead",
        "useBuiltIns": "usage",
        "corejs": "3.47"
      }
    ]
  ]
}
```

**package.json**：

```json
{
  "scripts": {
    "build": "babel src --out-dir dist",
    "dev": "babel src --out-dir dist --watch"
  },
  "devDependencies": {
    "@babel/cli": "^7.28.0",
    "@babel/core": "^7.28.0",
    "@babel/preset-env": "^7.28.0"
  },
  "dependencies": {
    "core-js": "^3.47.0"
  }
}
```

### 6.2 场景2：React 项目

```bash
# 安装 React 预设
npm install --save-dev @babel/preset-react
```

**babel.config.json**：

```json
{
  "presets": [
    [
      "@babel/preset-env",
      {
        "targets": "> 0.5%, last 2 versions, not dead"
      }
    ],
    [
      "@babel/preset-react",
      {
        "runtime": "automatic"
      }
    ]
  ]
}
```

> **提示**：`runtime: "automatic"` 启用新的 JSX 转换，无需手动导入 React。

**示例代码**：

```jsx
// ✅ 输入：React 组件
function App() {
  return <h1>Hello, World!</h1>;
}

// ✅ 输出：转换后（automatic runtime）
import { jsx as _jsx } from "react/jsx-runtime";
function App() {
  return _jsx("h1", { children: "Hello, World!" });
}
```

### 6.3 场景3：TypeScript 项目

```bash
# 安装 TypeScript 预设
npm install --save-dev @babel/preset-typescript
```

**babel.config.json**：

```json
{
  "presets": ["@babel/preset-env", "@babel/preset-typescript"]
}
```

> **注意**：Babel 只移除类型注解，不进行类型检查。建议配合 `tsc --noEmit` 进行类型检查。

**tsconfig.json**（配合使用）：

```json
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "ESNext",
    "noEmit": true,
    "strict": true
  }
}
```

**package.json**：

```json
{
  "scripts": {
    "build": "babel src --out-dir dist --extensions '.ts,.tsx'",
    "type-check": "tsc --noEmit"
  }
}
```

## 7. 与构建工具集成

### 7.1 Webpack 集成

```bash
npm install --save-dev babel-loader
```

**webpack.config.js**：

```javascript
module.exports = {
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: "babel-loader",
          options: {
            presets: ["@babel/preset-env"],
          },
        },
      },
    ],
  },
};
```

> **提示**：也可以省略 `options`，让 babel-loader 自动读取 `babel.config.json`。

### 7.2 Vite 集成

Vite 默认使用 esbuild 进行转换，如需使用 Babel：

```bash
npm install --save-dev @vitejs/plugin-react
```

**vite.config.js**：

```javascript
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [
    react({
      babel: {
        presets: ["@babel/preset-env"],
      },
    }),
  ],
});
```

## 8. 常见问题

**Q1: Babel 和 TypeScript 编译器（tsc）有什么区别？**

| 特性     | Babel        | tsc    |
| -------- | ------------ | ------ |
| 类型检查 | 不支持       | 支持   |
| 编译速度 | 更快         | 较慢   |
| 插件生态 | 丰富         | 有限   |
| Polyfill | 支持自动注入 | 不支持 |

**Q2: useBuiltIns 选择 "entry" 还是 "usage"？**

大多数项目推荐使用 `"usage"`，按需引入 polyfill，产物体积更小。详见 [5.2 useBuiltIns 配置](#52-usebuiltins-配置)。

**Q3: 为什么配置后某些语法没有被转换？**

1. 检查 `targets` 配置是否正确
2. 确认目标环境是否已支持该语法
3. 使用 `debug: true` 选项查看实际启用的插件

```json
{
  "presets": [
    [
      "@babel/preset-env",
      {
        "debug": true
      }
    ]
  ]
}
```

**Q4: 如何排除 node_modules 中的某些包？**

部分 npm 包可能使用了现代语法，需要通过 Babel 转换：

```javascript
// webpack.config.js
module.exports = {
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules\/(?!(some-modern-package)\/).*/,
        use: "babel-loader",
      },
    ],
  },
};
```

## 9. 总结

### 9.1 核心要点

1. Babel 是 JavaScript 编译器，将现代语法转换为兼容代码
2. `@babel/preset-env` 是最重要的预设，能智能选择转换规则
3. 使用 `useBuiltIns: "usage"` 可以按需引入 polyfill
4. Babel 可与 Webpack、Vite 等构建工具无缝集成

### 9.2 配置速查表

| 需求              | 配置                                             |
| ----------------- | ------------------------------------------------ |
| 基础转换          | `@babel/preset-env`                              |
| React 项目        | `@babel/preset-env` + `@babel/preset-react`      |
| TypeScript 项目   | `@babel/preset-env` + `@babel/preset-typescript` |
| 按需 Polyfill     | `useBuiltIns: "usage"` + `corejs: "3.x"`         |
| 支持 Tree Shaking | `modules: false`                                 |
| 调试配置          | `debug: true`                                    |

### 9.3 常用命令

| 命令                                         | 说明                 |
| -------------------------------------------- | -------------------- |
| `npx babel src --out-dir dist`               | 编译 src 目录到 dist |
| `npx babel src --out-dir dist --watch`       | 监听模式编译         |
| `npx babel src --out-dir dist --source-maps` | 生成 source map      |
| `npx babel --help`                           | 查看所有命令选项     |

## 10. 参考资源

- [Babel 官方文档](https://babeljs.io/docs/)
- [Babel GitHub 仓库](https://github.com/babel/babel)
- [@babel/preset-env 文档](https://babeljs.io/docs/babel-preset-env)
- [Browserslist 配置](https://github.com/browserslist/browserslist)
- [core-js 文档](https://github.com/zloirock/core-js)
