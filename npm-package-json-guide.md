# NPM package.json 配置完全指南

## 目录

- [NPM package.json 配置完全指南](#npm-packagejson-配置完全指南)
  - [目录](#目录)
  - [1. 概述](#1-概述)
    - [1.1 什么是 package.json](#11-什么是-packagejson)
    - [1.2 创建 package.json](#12-创建-packagejson)
    - [1.3 字段分类概览](#13-字段分类概览)
  - [2. 必需字段](#2-必需字段)
    - [2.1 name](#21-name)
    - [2.2 version](#22-version)
  - [3. 描述性字段](#3-描述性字段)
    - [3.1 description](#31-description)
    - [3.2 keywords](#32-keywords)
    - [3.3 homepage](#33-homepage)
    - [3.4 bugs](#34-bugs)
    - [3.5 license](#35-license)
    - [3.6 author 和 contributors](#36-author-和-contributors)
    - [3.7 funding](#37-funding)
    - [3.8 repository](#38-repository)
  - [4. 入口点字段](#4-入口点字段)
    - [4.1 main](#41-main)
    - [4.2 browser](#42-browser)
    - [4.3 module](#43-module)
    - [4.4 type](#44-type)
    - [4.5 exports（重要）](#45-exports重要)
    - [4.6 imports](#46-imports)
  - [5. 文件相关字段](#5-文件相关字段)
    - [5.1 files](#51-files)
    - [5.2 bin](#52-bin)
    - [5.3 man](#53-man)
    - [5.4 directories](#54-directories)
  - [6. 脚本字段](#6-脚本字段)
    - [6.1 scripts 基础](#61-scripts-基础)
    - [6.2 生命周期脚本](#62-生命周期脚本)
    - [6.3 pre 和 post 钩子](#63-pre-和-post-钩子)
    - [6.4 常用脚本模式](#64-常用脚本模式)
  - [7. 依赖管理字段](#7-依赖管理字段)
    - [7.1 dependencies](#71-dependencies)
    - [7.2 devDependencies](#72-devdependencies)
    - [7.3 peerDependencies](#73-peerdependencies)
    - [7.4 peerDependenciesMeta](#74-peerdependenciesmeta)
    - [7.5 optionalDependencies](#75-optionaldependencies)
    - [7.6 bundleDependencies](#76-bundledependencies)
    - [7.7 overrides](#77-overrides)
    - [7.8 版本范围语法](#78-版本范围语法)
  - [8. 环境配置字段](#8-环境配置字段)
    - [8.1 engines](#81-engines)
    - [8.2 os](#82-os)
    - [8.3 cpu](#83-cpu)
  - [9. 发布配置字段](#9-发布配置字段)
    - [9.1 private](#91-private)
    - [9.2 publishConfig](#92-publishconfig)
  - [10. 工作空间配置](#10-工作空间配置)
    - [10.1 workspaces 基础](#101-workspaces-基础)
    - [10.2 Monorepo 配置示例](#102-monorepo-配置示例)
    - [10.3 工作空间命令](#103-工作空间命令)
  - [11. 其他字段](#11-其他字段)
    - [11.1 config](#111-config)
    - [11.2 sideEffects](#112-sideeffects)
    - [11.3 types / typings](#113-types--typings)
  - [12. 完整项目配置示例](#12-完整项目配置示例)
    - [12.1 Web 应用项目](#121-web-应用项目)
    - [12.2 NPM 库项目（双模式支持）](#122-npm-库项目双模式支持)
    - [12.3 CLI 工具项目](#123-cli-工具项目)
    - [12.4 Monorepo 根配置](#124-monorepo-根配置)
  - [13. 最佳实践](#13-最佳实践)
    - [13.1 版本管理](#131-版本管理)
    - [13.2 依赖管理](#132-依赖管理)
    - [13.3 脚本编写](#133-脚本编写)
    - [13.4 发布前检查清单](#134-发布前检查清单)
  - [14. 常见问题与解决方案](#14-常见问题与解决方案)
  - [15. 参考资源](#15-参考资源)

---

## 1. 概述

### 1.1 什么是 package.json

`package.json` 是 Node.js 项目的核心配置文件，它：

- 定义项目的元数据（名称、版本、描述等）
- 声明项目的依赖关系
- 配置脚本命令
- 指定项目的入口点
- 控制发布行为

每个 Node.js 项目的根目录都应该包含一个 `package.json` 文件。

### 1.2 创建 package.json

有多种方式创建 `package.json`：

```bash
# 交互式创建（回答一系列问题）
npm init

# 使用默认值快速创建
npm init -y

# 使用 yarn
yarn init
yarn init -y

# 使用 pnpm
pnpm init
```

使用 `npm init -y` 创建的默认内容：

```json
{
  "name": "my-project",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}
```

### 1.3 字段分类概览

| 分类       | 字段                                           | 说明               |
| ---------- | ---------------------------------------------- | ------------------ |
| 必需字段   | name, version                                  | 包的唯一标识       |
| 描述性字段 | description, keywords, author, license, etc.   | 包的元信息         |
| 入口点字段 | main, module, browser, exports, imports, type  | 模块解析入口       |
| 文件字段   | files, bin, man, directories                   | 发布包含的文件     |
| 脚本字段   | scripts                                        | npm 命令脚本       |
| 依赖字段   | dependencies, devDependencies, etc.            | 依赖管理           |
| 环境字段   | engines, os, cpu                               | 运行环境要求       |
| 发布字段   | private, publishConfig                         | 发布控制           |
| 工作空间   | workspaces                                     | Monorepo 配置      |

---

## 2. 必需字段

### 2.1 name

包名称，是包的唯一标识符。

**命名规则：**

- 长度不超过 214 个字符
- 必须小写
- 可以包含连字符（-）和下划线（_）
- 不能包含空格
- 不能以点（.）或下划线（_）开头
- 不能包含 URL 不安全字符

**作用域包（Scoped Packages）：**

```json
{
  "name": "@myorg/mypackage"
}
```

作用域包的优点：
- 命名空间隔离，避免命名冲突
- 组织相关包
- 可配置私有或公开访问

```json
// 普通包名
{ "name": "lodash" }

// 作用域包名
{ "name": "@types/node" }
{ "name": "@vue/cli" }
{ "name": "@company/internal-utils" }
```

### 2.2 version

版本号，必须遵循语义化版本规范（SemVer）。

**格式：** `MAJOR.MINOR.PATCH`

```json
{
  "version": "1.2.3"
}
```

**版本号含义：**

| 部分  | 含义         | 递增时机                         |
| ----- | ------------ | -------------------------------- |
| MAJOR | 主版本号     | 不兼容的 API 修改                |
| MINOR | 次版本号     | 向后兼容的功能性新增             |
| PATCH | 修订号       | 向后兼容的问题修正               |

**预发布版本：**

```json
// alpha 版本（内部测试）
{ "version": "2.0.0-alpha.1" }

// beta 版本（公开测试）
{ "version": "2.0.0-beta.1" }

// rc 版本（候选发布）
{ "version": "2.0.0-rc.1" }
```

---

## 3. 描述性字段

### 3.1 description

简短描述包的功能，用于 npm 搜索结果展示。

```json
{
  "description": "A lightweight utility library for date manipulation"
}
```

### 3.2 keywords

关键词数组，提高包在 npm 搜索中的可发现性。

```json
{
  "keywords": ["date", "time", "utility", "format", "parse"]
}
```

### 3.3 homepage

项目主页 URL。

```json
{
  "homepage": "https://github.com/user/project#readme"
}
```

### 3.4 bugs

问题反馈地址。

```json
// 简单形式
{
  "bugs": "https://github.com/user/project/issues"
}

// 完整形式
{
  "bugs": {
    "url": "https://github.com/user/project/issues",
    "email": "support@example.com"
  }
}
```

### 3.5 license

包的许可证类型。

```json
// SPDX 标识符
{ "license": "MIT" }
{ "license": "Apache-2.0" }
{ "license": "GPL-3.0-only" }
{ "license": "ISC" }

// 未开源
{ "license": "UNLICENSED" }

// 多许可证（用户可选择）
{ "license": "(MIT OR Apache-2.0)" }
```

**常见许可证对比：**

| 许可证      | 商业使用 | 修改分发 | 专利授权 | 需保留版权 |
| ----------- | -------- | -------- | -------- | ---------- |
| MIT         | ✓        | ✓        | -        | ✓          |
| Apache-2.0  | ✓        | ✓        | ✓        | ✓          |
| GPL-3.0     | ✓        | ✓（开源）| ✓        | ✓          |
| BSD-3       | ✓        | ✓        | -        | ✓          |
| ISC         | ✓        | ✓        | -        | ✓          |

### 3.6 author 和 contributors

包的作者和贡献者信息。

```json
// 字符串格式
{
  "author": "John Doe <john@example.com> (https://johndoe.com)"
}

// 对象格式
{
  "author": {
    "name": "John Doe",
    "email": "john@example.com",
    "url": "https://johndoe.com"
  }
}

// 贡献者列表
{
  "contributors": [
    "Jane Smith <jane@example.com>",
    {
      "name": "Bob Wilson",
      "email": "bob@example.com"
    }
  ]
}
```

### 3.7 funding

项目资助信息。

```json
// 单一资助链接
{
  "funding": "https://opencollective.com/myproject"
}

// 对象形式
{
  "funding": {
    "type": "opencollective",
    "url": "https://opencollective.com/myproject"
  }
}

// 多个资助渠道
{
  "funding": [
    {
      "type": "github",
      "url": "https://github.com/sponsors/user"
    },
    {
      "type": "patreon",
      "url": "https://patreon.com/user"
    }
  ]
}
```

### 3.8 repository

源代码仓库地址。

```json
// 简写形式（GitHub）
{
  "repository": "github:user/repo"
}

// 完整形式
{
  "repository": {
    "type": "git",
    "url": "https://github.com/user/repo.git"
  }
}

// Monorepo 中指定目录
{
  "repository": {
    "type": "git",
    "url": "https://github.com/user/monorepo.git",
    "directory": "packages/mypackage"
  }
}
```

---

## 4. 入口点字段

### 4.1 main

指定包的主入口文件，当其他模块 `require()` 或 `import` 包时使用。

```json
{
  "main": "./dist/index.js"
}
```

- 默认值为 `index.js`
- 所有 Node.js 版本都支持
- 只能定义一个入口点

### 4.2 browser

指定浏览器环境的入口文件，用于替代 `main`。

```json
{
  "main": "./dist/index.js",
  "browser": "./dist/browser.js"
}
```

也可以用对象形式替换特定模块：

```json
{
  "browser": {
    "./lib/server.js": "./lib/browser.js",
    "fs": false
  }
}
```

### 4.3 module

指定 ES Module 格式的入口文件（非官方标准，但被打包工具广泛支持）。

```json
{
  "main": "./dist/index.cjs",
  "module": "./dist/index.mjs"
}
```

### 4.4 type

指定 `.js` 文件的模块类型。

```json
// ES Module（推荐新项目使用）
{
  "type": "module"
}

// CommonJS（默认值）
{
  "type": "commonjs"
}
```

**文件扩展名与模块类型对照：**

| type 值      | .js 文件解析为 | .mjs 文件 | .cjs 文件 |
| ------------ | -------------- | --------- | --------- |
| "module"     | ES Module      | ES Module | CommonJS  |
| "commonjs"   | CommonJS       | ES Module | CommonJS  |
| 未设置       | CommonJS       | ES Module | CommonJS  |

### 4.5 exports（重要）

`exports` 是现代包的推荐入口点配置方式，提供了比 `main` 更强大的功能：

- 定义多个入口点
- 条件导出（根据环境选择不同文件）
- 封装内部模块（阻止访问未导出的文件）

**基本用法：**

```json
{
  "exports": "./dist/index.js"
}
```

**多入口点：**

```json
{
  "exports": {
    ".": "./dist/index.js",
    "./utils": "./dist/utils.js",
    "./helpers/*": "./dist/helpers/*.js"
  }
}
```

**条件导出：**

```json
{
  "exports": {
    ".": {
      "import": "./dist/index.mjs",
      "require": "./dist/index.cjs",
      "default": "./dist/index.js"
    }
  }
}
```

**完整的条件导出配置：**

```json
{
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "import": "./dist/index.mjs",
      "require": "./dist/index.cjs",
      "default": "./dist/index.js"
    },
    "./utils": {
      "types": "./dist/utils.d.ts",
      "import": "./dist/utils.mjs",
      "require": "./dist/utils.cjs"
    },
    "./package.json": "./package.json"
  }
}
```

**条件导出优先级（从上到下）：**

| 条件        | 说明                           |
| ----------- | ------------------------------ |
| types       | TypeScript 类型定义（应放首位）|
| import      | ES Module 环境                 |
| require     | CommonJS 环境                  |
| node        | Node.js 环境                   |
| browser     | 浏览器环境                     |
| development | 开发环境                       |
| production  | 生产环境                       |
| default     | 默认回退                       |

### 4.6 imports

定义包内部的导入映射，使用 `#` 前缀。

```json
{
  "imports": {
    "#utils": "./src/utils/index.js",
    "#config": "./src/config.js",
    "#lib/*": "./src/lib/*.js"
  }
}
```

在代码中使用：

```javascript
// 不再需要写相对路径
import { helper } from '#utils';
import config from '#config';
```

**条件导入：**

```json
{
  "imports": {
    "#platform": {
      "node": "./src/platform-node.js",
      "browser": "./src/platform-browser.js",
      "default": "./src/platform-default.js"
    }
  }
}
```

---

## 5. 文件相关字段

### 5.1 files

指定发布到 npm 时包含的文件。

```json
{
  "files": [
    "dist",
    "lib",
    "es",
    "README.md",
    "LICENSE"
  ]
}
```

**始终包含的文件（无需列出）：**
- package.json
- README（任意扩展名）
- LICENSE / LICENCE
- CHANGELOG
- main 字段指定的文件

**始终排除的文件：**
- .git
- node_modules
- .npmrc
- package-lock.json
- .gitignore 中列出的文件

### 5.2 bin

定义可执行命令。

```json
// 单个命令（命令名与包名相同）
{
  "name": "my-cli",
  "bin": "./bin/cli.js"
}

// 多个命令
{
  "bin": {
    "mycli": "./bin/cli.js",
    "mycli-init": "./bin/init.js"
  }
}
```

**可执行文件要求：**

```javascript
#!/usr/bin/env node
// bin/cli.js 的第一行必须是 shebang
console.log('Hello from CLI!');
```

### 5.3 man

指定 man 手册页。

```json
// 单个手册
{
  "man": "./man/doc.1"
}

// 多个手册
{
  "man": [
    "./man/myapp.1",
    "./man/myapp-config.5"
  ]
}
```

### 5.4 directories

指定项目目录结构（主要用于文档目的）。

```json
{
  "directories": {
    "bin": "./bin",
    "lib": "./lib",
    "man": "./man",
    "doc": "./doc",
    "example": "./examples",
    "test": "./test"
  }
}
```

---

## 6. 脚本字段

### 6.1 scripts 基础

`scripts` 字段定义可通过 `npm run` 执行的命令。

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "test": "vitest",
    "lint": "eslint src",
    "format": "prettier --write src"
  }
}
```

**执行脚本：**

```bash
npm run dev
npm run build

# test/start/stop/restart 可省略 run
npm test
npm start
```

### 6.2 生命周期脚本

NPM 在特定操作时自动执行的脚本。

```json
{
  "scripts": {
    "prepare": "husky install",
    "prepublishOnly": "npm run build && npm test",
    "preinstall": "node check-environment.js",
    "postinstall": "node setup.js"
  }
}
```

**主要生命周期脚本：**

| 脚本            | 触发时机                               |
| --------------- | -------------------------------------- |
| preinstall      | 安装包之前                             |
| install         | 安装包时                               |
| postinstall     | 安装包之后                             |
| prepare         | 安装后、发布前（常用于构建和设置 Git hooks） |
| prepublishOnly  | 仅在 `npm publish` 之前                |
| prepack         | 打包前（tarball 创建前）               |
| postpack        | 打包后                                 |
| prepublish      | 已废弃，避免使用                       |

### 6.3 pre 和 post 钩子

任何自定义脚本都可以添加 `pre` 和 `post` 前缀钩子。

```json
{
  "scripts": {
    "prebuild": "rm -rf dist",
    "build": "tsc",
    "postbuild": "node scripts/copy-assets.js",

    "pretest": "npm run lint",
    "test": "vitest",
    "posttest": "echo 'Tests completed!'"
  }
}
```

执行 `npm run build` 时，执行顺序为：
1. `prebuild`
2. `build`
3. `postbuild`

### 6.4 常用脚本模式

```json
{
  "scripts": {
    // 开发
    "dev": "vite",
    "dev:debug": "DEBUG=* vite",

    // 构建
    "build": "vite build",
    "build:analyze": "vite build --mode analyze",

    // 测试
    "test": "vitest",
    "test:watch": "vitest --watch",
    "test:coverage": "vitest --coverage",
    "test:e2e": "playwright test",

    // 代码质量
    "lint": "eslint . --ext .js,.ts,.vue",
    "lint:fix": "eslint . --ext .js,.ts,.vue --fix",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "typecheck": "tsc --noEmit",

    // 发布
    "prepublishOnly": "npm run build && npm test",
    "release": "standard-version",
    "release:minor": "standard-version --release-as minor",
    "release:major": "standard-version --release-as major",

    // 工具
    "clean": "rm -rf dist node_modules",
    "prepare": "husky install"
  }
}
```

---

## 7. 依赖管理字段

### 7.1 dependencies

生产环境必需的依赖，会在 `npm install --production` 时安装。

```json
{
  "dependencies": {
    "express": "^4.18.2",
    "lodash": "^4.17.21"
  }
}
```

### 7.2 devDependencies

仅开发环境需要的依赖，不会在生产环境安装。

```json
{
  "devDependencies": {
    "typescript": "^5.0.0",
    "vitest": "^1.0.0",
    "eslint": "^8.0.0",
    "@types/node": "^20.0.0"
  }
}
```

**dependencies vs devDependencies 选择指南：**

| 依赖类型        | 放置位置          | 示例                            |
| --------------- | ----------------- | ------------------------------- |
| 运行时必需      | dependencies      | express, react, lodash          |
| 构建工具        | devDependencies   | webpack, vite, esbuild          |
| 测试框架        | devDependencies   | jest, vitest, mocha             |
| 代码检查        | devDependencies   | eslint, prettier                |
| 类型定义        | devDependencies   | @types/*, typescript            |
| 文档生成        | devDependencies   | typedoc, jsdoc                  |

### 7.3 peerDependencies

声明包与宿主项目共享的依赖，避免重复安装。

```json
{
  "name": "my-react-component",
  "peerDependencies": {
    "react": "^17.0.0 || ^18.0.0",
    "react-dom": "^17.0.0 || ^18.0.0"
  }
}
```

**使用场景：**
- 插件或扩展（如 webpack loaders、babel plugins）
- UI 组件库（依赖宿主的 React/Vue）
- 框架扩展

**注意：** npm 7+ 默认自动安装 peerDependencies。

### 7.4 peerDependenciesMeta

为 peerDependencies 提供额外元数据。

```json
{
  "peerDependencies": {
    "react": "^18.0.0",
    "react-native": "^0.70.0"
  },
  "peerDependenciesMeta": {
    "react-native": {
      "optional": true
    }
  }
}
```

### 7.5 optionalDependencies

可选依赖，安装失败不会导致整体安装失败。

```json
{
  "optionalDependencies": {
    "fsevents": "^2.3.2"
  }
}
```

代码中需要处理依赖不存在的情况：

```javascript
try {
  const fsevents = require('fsevents');
  // 使用 fsevents
} catch (err) {
  // 回退方案
}
```

### 7.6 bundleDependencies

指定发布时打包到 tarball 中的依赖。

```json
{
  "bundleDependencies": [
    "internal-package",
    "legacy-module"
  ]
}
```

### 7.7 overrides

强制指定依赖树中某个包的版本（npm 8.3+）。

```json
{
  "overrides": {
    // 全局覆盖
    "lodash": "4.17.21",

    // 特定依赖下的覆盖
    "webpack": {
      "terser": "5.15.0"
    },

    // 嵌套覆盖
    "react-scripts": {
      "webpack": {
        "terser": "5.15.0"
      }
    }
  }
}
```

**Yarn 使用 `resolutions`：**

```json
{
  "resolutions": {
    "lodash": "4.17.21",
    "webpack/terser": "5.15.0"
  }
}
```

### 7.8 版本范围语法

| 语法        | 示例          | 匹配范围                      |
| ----------- | ------------- | ----------------------------- |
| 精确版本    | `1.2.3`       | 仅 1.2.3                      |
| `^`         | `^1.2.3`      | >=1.2.3 <2.0.0（主版本锁定）  |
| `~`         | `~1.2.3`      | >=1.2.3 <1.3.0（次版本锁定）  |
| `>`/`<`     | `>1.2.3`      | 大于 1.2.3                    |
| `>=`/`<=`   | `>=1.2.3`     | 大于等于 1.2.3                |
| `-`         | `1.2.3 - 2.0.0` | >=1.2.3 <=2.0.0             |
| `x`/`*`     | `1.2.x`       | >=1.2.0 <1.3.0                |
| `\|\|`      | `^1.0 \|\| ^2.0` | 1.x 或 2.x                 |
| `latest`    | `latest`      | 最新发布版本                  |
| `*`         | `*`           | 任意版本                      |

**URL 依赖：**

```json
{
  "dependencies": {
    "local-pkg": "file:../local-pkg",
    "git-pkg": "git+https://github.com/user/repo.git",
    "github-pkg": "github:user/repo#branch",
    "tarball-pkg": "https://example.com/package.tgz"
  }
}
```

---

## 8. 环境配置字段

### 8.1 engines

指定项目运行所需的 Node.js 和 npm 版本。

```json
{
  "engines": {
    "node": ">=18.0.0",
    "npm": ">=9.0.0"
  }
}
```

**严格执行（需要配置）：**

创建 `.npmrc` 文件：

```ini
engine-strict=true
```

或配置 `package.json`：

```json
{
  "engines": {
    "node": ">=18.0.0"
  },
  "engineStrict": true
}
```

### 8.2 os

限制包运行的操作系统。

```json
// 仅允许特定系统
{
  "os": ["darwin", "linux"]
}

// 排除特定系统
{
  "os": ["!win32"]
}
```

**可用值：** `darwin`、`linux`、`win32`、`freebsd`、`openbsd`、`sunos`、`aix`

### 8.3 cpu

限制包运行的 CPU 架构。

```json
// 仅允许特定架构
{
  "cpu": ["x64", "arm64"]
}

// 排除特定架构
{
  "cpu": ["!arm", "!mips"]
}
```

**可用值：** `x64`、`arm`、`arm64`、`ia32`、`mips`、`ppc64`、`s390x`

---

## 9. 发布配置字段

### 9.1 private

设置为 `true` 防止包被意外发布。

```json
{
  "private": true
}
```

**使用场景：**
- 私有项目
- Monorepo 根目录
- 不打算发布的应用

### 9.2 publishConfig

发布时使用的配置。

```json
{
  "publishConfig": {
    "registry": "https://npm.company.com/",
    "access": "public",
    "tag": "next"
  }
}
```

**常用配置项：**

| 字段     | 说明                           |
| -------- | ------------------------------ |
| registry | 发布目标仓库                   |
| access   | `public` 或 `restricted`       |
| tag      | 发布时的标签（默认 `latest`）  |

**发布作用域包为公开：**

```json
{
  "name": "@myorg/mypackage",
  "publishConfig": {
    "access": "public"
  }
}
```

---

## 10. 工作空间配置

### 10.1 workspaces 基础

`workspaces` 用于配置 Monorepo，管理多个相关包。

```json
{
  "name": "my-monorepo",
  "private": true,
  "workspaces": [
    "packages/*",
    "apps/*"
  ]
}
```

**目录结构：**

```
my-monorepo/
├── package.json
├── packages/
│   ├── core/
│   │   └── package.json
│   ├── utils/
│   │   └── package.json
│   └── cli/
│       └── package.json
└── apps/
    ├── web/
    │   └── package.json
    └── api/
        └── package.json
```

### 10.2 Monorepo 配置示例

**根 package.json：**

```json
{
  "name": "my-monorepo",
  "private": true,
  "workspaces": [
    "packages/*",
    "apps/*"
  ],
  "scripts": {
    "build": "npm run build --workspaces",
    "test": "npm run test --workspaces --if-present",
    "lint": "npm run lint --workspaces --if-present"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "eslint": "^8.0.0"
  }
}
```

**子包 package.json：**

```json
{
  "name": "@myorg/core",
  "version": "1.0.0",
  "main": "./dist/index.js",
  "scripts": {
    "build": "tsc",
    "test": "vitest"
  },
  "dependencies": {
    "@myorg/utils": "workspace:*"
  }
}
```

### 10.3 工作空间命令

```bash
# 在所有工作空间运行脚本
npm run build --workspaces

# 在特定工作空间运行
npm run build --workspace=@myorg/core
npm run build -w @myorg/core

# 添加依赖到特定工作空间
npm install lodash -w @myorg/utils

# 添加工作空间互相依赖
npm install @myorg/utils -w @myorg/core

# 运行脚本（跳过没有该脚本的包）
npm run test --workspaces --if-present
```

---

## 11. 其他字段

### 11.1 config

设置脚本中可用的环境变量。

```json
{
  "name": "my-package",
  "config": {
    "port": "8080",
    "host": "localhost"
  },
  "scripts": {
    "start": "node server.js"
  }
}
```

在脚本中访问：

```javascript
// 通过 npm_package_config_ 前缀访问
const port = process.env.npm_package_config_port; // "8080"
```

用户可覆盖配置：

```bash
npm config set my-package:port 3000
```

### 11.2 sideEffects

告知打包工具（如 webpack）包是否有副作用，用于 Tree Shaking 优化。

```json
// 无副作用，可以安全 Tree Shake
{
  "sideEffects": false
}

// 指定有副作用的文件
{
  "sideEffects": [
    "*.css",
    "*.scss",
    "./src/polyfills.js"
  ]
}
```

### 11.3 types / typings

指定 TypeScript 类型定义入口文件。

```json
{
  "main": "./dist/index.js",
  "types": "./dist/index.d.ts"
}

// 或使用 typings（等效）
{
  "typings": "./dist/index.d.ts"
}
```

**配合 exports 使用：**

```json
{
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "import": "./dist/index.mjs",
      "require": "./dist/index.cjs"
    }
  }
}
```

---

## 12. 完整项目配置示例

### 12.1 Web 应用项目

```json
{
  "name": "my-web-app",
  "version": "1.0.0",
  "private": true,
  "description": "A modern web application",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "test": "vitest",
    "test:e2e": "playwright test",
    "lint": "eslint src --ext .ts,.tsx",
    "lint:fix": "eslint src --ext .ts,.tsx --fix",
    "format": "prettier --write src",
    "typecheck": "tsc --noEmit",
    "prepare": "husky install"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.0.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "@vitejs/plugin-react": "^4.0.0",
    "eslint": "^8.0.0",
    "husky": "^8.0.0",
    "lint-staged": "^15.0.0",
    "prettier": "^3.0.0",
    "typescript": "^5.0.0",
    "vite": "^5.0.0",
    "vitest": "^1.0.0"
  },
  "lint-staged": {
    "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.{json,md}": ["prettier --write"]
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
```

### 12.2 NPM 库项目（双模式支持）

```json
{
  "name": "@myorg/utils",
  "version": "1.0.0",
  "description": "A utility library supporting both ESM and CommonJS",
  "keywords": ["utils", "utility", "helpers"],
  "author": "Your Name <your@email.com>",
  "license": "MIT",
  "repository": {
    "type": "git",
    "url": "https://github.com/myorg/utils.git"
  },
  "bugs": {
    "url": "https://github.com/myorg/utils/issues"
  },
  "homepage": "https://github.com/myorg/utils#readme",
  "funding": {
    "type": "github",
    "url": "https://github.com/sponsors/myorg"
  },
  "type": "module",
  "main": "./dist/index.cjs",
  "module": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "import": "./dist/index.js",
      "require": "./dist/index.cjs"
    },
    "./helpers": {
      "types": "./dist/helpers/index.d.ts",
      "import": "./dist/helpers/index.js",
      "require": "./dist/helpers/index.cjs"
    },
    "./package.json": "./package.json"
  },
  "files": [
    "dist",
    "README.md",
    "LICENSE"
  ],
  "sideEffects": false,
  "scripts": {
    "dev": "tsup --watch",
    "build": "tsup",
    "test": "vitest",
    "test:coverage": "vitest --coverage",
    "lint": "eslint src",
    "typecheck": "tsc --noEmit",
    "prepublishOnly": "npm run build && npm test",
    "release": "npm run build && changeset publish"
  },
  "dependencies": {},
  "devDependencies": {
    "@changesets/cli": "^2.0.0",
    "eslint": "^8.0.0",
    "tsup": "^8.0.0",
    "typescript": "^5.0.0",
    "vitest": "^1.0.0"
  },
  "peerDependencies": {},
  "engines": {
    "node": ">=16.0.0"
  },
  "publishConfig": {
    "access": "public",
    "registry": "https://registry.npmjs.org/"
  }
}
```

### 12.3 CLI 工具项目

```json
{
  "name": "my-cli-tool",
  "version": "1.0.0",
  "description": "A powerful command-line tool",
  "keywords": ["cli", "tool", "automation"],
  "author": "Your Name <your@email.com>",
  "license": "MIT",
  "repository": {
    "type": "git",
    "url": "https://github.com/username/my-cli-tool.git"
  },
  "type": "module",
  "main": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "bin": {
    "mycli": "./dist/cli.js",
    "mc": "./dist/cli.js"
  },
  "files": [
    "dist",
    "README.md"
  ],
  "scripts": {
    "dev": "tsup --watch",
    "build": "tsup",
    "test": "vitest",
    "lint": "eslint src",
    "prepublishOnly": "npm run build"
  },
  "dependencies": {
    "commander": "^11.0.0",
    "chalk": "^5.0.0",
    "ora": "^7.0.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "tsup": "^8.0.0",
    "typescript": "^5.0.0",
    "vitest": "^1.0.0"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
```

### 12.4 Monorepo 根配置

```json
{
  "name": "my-monorepo",
  "version": "0.0.0",
  "private": true,
  "description": "Monorepo for my projects",
  "workspaces": [
    "packages/*",
    "apps/*"
  ],
  "scripts": {
    "build": "npm run build --workspaces",
    "build:packages": "npm run build --workspace=packages/*",
    "build:apps": "npm run build --workspace=apps/*",
    "test": "npm run test --workspaces --if-present",
    "lint": "npm run lint --workspaces --if-present",
    "clean": "npm run clean --workspaces --if-present && rm -rf node_modules",
    "changeset": "changeset",
    "version-packages": "changeset version",
    "release": "npm run build:packages && changeset publish",
    "prepare": "husky install"
  },
  "devDependencies": {
    "@changesets/cli": "^2.0.0",
    "husky": "^8.0.0",
    "typescript": "^5.0.0"
  },
  "engines": {
    "node": ">=18.0.0",
    "npm": ">=9.0.0"
  }
}
```

---

## 13. 最佳实践

### 13.1 版本管理

1. **遵循语义化版本**
   - 破坏性变更 → 升级主版本
   - 新功能（向后兼容）→ 升级次版本
   - Bug 修复 → 升级修订版本

2. **使用版本管理工具**
   ```bash
   # 使用 npm version
   npm version patch  # 1.0.0 → 1.0.1
   npm version minor  # 1.0.0 → 1.1.0
   npm version major  # 1.0.0 → 2.0.0

   # 或使用 changesets（推荐用于 Monorepo）
   npx changeset
   ```

3. **预发布版本标签**
   ```bash
   npm publish --tag beta
   npm publish --tag next
   ```

### 13.2 依赖管理

1. **定期更新依赖**
   ```bash
   # 检查过期依赖
   npm outdated

   # 使用 npm-check-updates
   npx npm-check-updates
   npx npm-check-updates -u
   ```

2. **锁定文件**
   - 始终提交 `package-lock.json`
   - CI 环境使用 `npm ci` 而非 `npm install`

3. **依赖分类原则**
   - 运行时依赖 → `dependencies`
   - 开发工具 → `devDependencies`
   - 共享依赖 → `peerDependencies`

4. **安全审计**
   ```bash
   npm audit
   npm audit fix
   ```

### 13.3 脚本编写

1. **使用跨平台工具**
   ```json
   {
     "scripts": {
       // 使用 rimraf 替代 rm -rf
       "clean": "rimraf dist",
       // 使用 cross-env 设置环境变量
       "build": "cross-env NODE_ENV=production webpack"
     }
   }
   ```

2. **脚本命名规范**
   - 使用动词开头：`build`、`test`、`lint`
   - 变体使用冒号分隔：`test:watch`、`build:prod`
   - 保持一致性

3. **组合脚本**
   ```json
   {
     "scripts": {
       "validate": "npm run lint && npm run typecheck && npm run test"
     }
   }
   ```

### 13.4 发布前检查清单

- [ ] `name` 和 `version` 正确设置
- [ ] `description` 清晰描述包功能
- [ ] `keywords` 包含相关关键词
- [ ] `license` 已指定
- [ ] `repository` 指向正确地址
- [ ] `main`/`exports` 入口点正确
- [ ] `files` 包含所有必要文件
- [ ] `engines` 指定支持的 Node.js 版本
- [ ] 依赖正确分类
- [ ] 构建产物已生成
- [ ] 测试通过
- [ ] `README.md` 完整

---

## 14. 常见问题与解决方案

**Q1: 如何解决依赖冲突？**

```json
// 使用 overrides（npm 8+）
{
  "overrides": {
    "problematic-package": "1.2.3"
  }
}
```

```bash
# 或使用 --force 安装
npm install --force

# 使用 --legacy-peer-deps 忽略 peerDependencies 冲突
npm install --legacy-peer-deps
```

**Q2: 如何处理 ESM 和 CommonJS 兼容性？**

```json
{
  "type": "module",
  "exports": {
    ".": {
      "import": "./dist/index.mjs",
      "require": "./dist/index.cjs"
    }
  }
}
```

**Q3: 如何排除文件发布？**

创建 `.npmignore` 文件：

```
src/
test/
*.test.js
.eslintrc
tsconfig.json
```

或使用 `files` 字段白名单方式（推荐）：

```json
{
  "files": ["dist", "README.md"]
}
```

**Q4: 如何本地测试包发布内容？**

```bash
# 查看将要发布的文件
npm pack --dry-run

# 创建 tarball 检查内容
npm pack
tar -tzf my-package-1.0.0.tgz
```

**Q5: 如何处理 monorepo 中的内部依赖？**

```json
// 使用 workspace 协议
{
  "dependencies": {
    "@myorg/utils": "workspace:*",
    "@myorg/core": "workspace:^1.0.0"
  }
}
```

**Q6: 如何指定不同环境的脚本？**

```json
{
  "scripts": {
    "start": "node index.js",
    "start:dev": "nodemon index.js",
    "start:prod": "NODE_ENV=production node index.js"
  }
}
```

**Q7: `exports` 和 `main` 应该同时使用吗？**

推荐同时设置，以兼容老版本 Node.js：

```json
{
  "main": "./dist/index.js",
  "exports": {
    ".": "./dist/index.js"
  }
}
```

**Q8: 如何发布到私有仓库？**

```json
{
  "publishConfig": {
    "registry": "https://npm.your-company.com/"
  }
}
```

或在 `.npmrc` 中配置：

```ini
@yourscope:registry=https://npm.your-company.com/
//npm.your-company.com/:_authToken=${NPM_TOKEN}
```

---

## 15. 参考资源

- [npm 官方文档 - package.json](https://docs.npmjs.com/cli/v10/configuring-npm/package-json)
- [Node.js 文档 - Packages](https://nodejs.org/api/packages.html)
- [语义化版本规范](https://semver.org/lang/zh-CN/)
- [npm scripts 文档](https://docs.npmjs.com/cli/v10/using-npm/scripts)
- [Node.js ESM 文档](https://nodejs.org/api/esm.html)
- [webpack package exports 指南](https://webpack.js.org/guides/package-exports/)
- [package.json exports 字段指南](https://hirok.io/posts/package-json-exports)
