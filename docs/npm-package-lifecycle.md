# npm Package Lifecycle 完全指南

## 目录

- [概述](#概述)
- [生命周期脚本分类](#生命周期脚本分类)
- [安装流程详解](#安装流程详解)
- [卸载流程详解](#卸载流程详解)
- [发布流程详解](#发布流程详解)
- [版本管理生命周期](#版本管理生命周期)
- [实际应用示例](#实际应用示例)
- [最佳实践](#最佳实践)
- [常见问题与调试](#常见问题与调试)
- [总结](#总结)

---

## 概述

npm package lifecycle（包生命周期）是指 npm 包在安装、卸载、发布、更新等操作过程中所经历的一系列阶段。在每个阶段，npm 都会按照特定顺序执行预定义的脚本，这些脚本被称为 **lifecycle scripts**（生命周期脚本）。

理解 npm 生命周期对于以下场景至关重要：

- 在安装依赖后自动编译原生模块
- 在发布前进行代码构建和测试
- 清理临时文件或执行数据库迁移
- 自动化开发和部署流程

### 生命周期脚本的定义方式

所有生命周期脚本都在 `package.json` 的 `scripts` 字段中定义：

```json
{
  "name": "my-package",
  "version": "1.0.0",
  "scripts": {
    "preinstall": "echo 'About to install'",
    "install": "node-gyp rebuild",
    "postinstall": "echo 'Install completed'",
    "prepublishOnly": "npm run build",
    "prepare": "husky install"
  }
}
```

---

## 生命周期脚本分类

npm 生命周期脚本可以分为以下几大类：

### 1. 安装相关（Install）

| 脚本名称      | 执行时机   | 说明                 |
| ------------- | ---------- | -------------------- |
| `preinstall`  | 包安装之前 | 在任何依赖安装前执行 |
| `install`     | 包安装时   | 常用于编译原生模块   |
| `postinstall` | 包安装之后 | 安装完成后的收尾工作 |

### 2. 卸载相关（Uninstall）

| 脚本名称        | 执行时机 | 说明             |
| --------------- | -------- | ---------------- |
| `preuninstall`  | 卸载之前 | 卸载前的清理准备 |
| `uninstall`     | 卸载时   | 卸载过程中执行   |
| `postuninstall` | 卸载之后 | 卸载完成后的收尾 |

### 3. 发布相关（Publish）

| 脚本名称         | 执行时机              | 说明                                  |
| ---------------- | --------------------- | ------------------------------------- |
| `prepublishOnly` | 仅在 `npm publish` 前 | 发布前的构建和测试                    |
| `prepack`        | 打包 tarball 之前     | 在 `npm pack` 和 `npm publish` 前执行 |
| `postpack`       | 打包 tarball 之后     | tarball 创建后执行                    |
| `publish`        | 发布时                | 发布过程中执行                        |
| `postpublish`    | 发布之后              | 发布完成后执行                        |

### 4. 准备相关（Prepare）

| 脚本名称     | 执行时机 | 说明                                                                                          |
| ------------ | -------- | --------------------------------------------------------------------------------------------- |
| `prepublish` | 已弃用   | 不会在 `npm publish` 时运行，但会在 `npm ci` 和 `npm install` 时运行。推荐使用 `prepare` 替代 |
| `prepare`    | 多种场景 | 本地 `npm install` 后、`npm pack`/`npm publish` 前、git 依赖安装时执行                        |

### 5. 版本相关（Version）

| 脚本名称      | 执行时机     | 说明             |
| ------------- | ------------ | ---------------- |
| `preversion`  | 版本变更之前 | 检查代码状态     |
| `version`     | 版本变更时   | 更新版本相关文件 |
| `postversion` | 版本变更之后 | 推送标签或通知   |

### 6. 运行相关（Run）

| 脚本名称      | 执行时机           | 说明       |
| ------------- | ------------------ | ---------- |
| `prestart`    | `npm start` 之前   | 启动前准备 |
| `start`       | `npm start` 时     | 主启动脚本 |
| `poststart`   | `npm start` 之后   | 启动后操作 |
| `prestop`     | `npm stop` 之前    | 停止前准备 |
| `stop`        | `npm stop` 时      | 停止脚本   |
| `poststop`    | `npm stop` 之后    | 停止后清理 |
| `prerestart`  | `npm restart` 之前 | 重启前准备 |
| `restart`     | `npm restart` 时   | 重启脚本   |
| `postrestart` | `npm restart` 之后 | 重启后操作 |

### 7. 测试相关（Test）

| 脚本名称   | 执行时机        | 说明       |
| ---------- | --------------- | ---------- |
| `pretest`  | `npm test` 之前 | 测试前准备 |
| `test`     | `npm test` 时   | 执行测试   |
| `posttest` | `npm test` 之后 | 测试后清理 |

---

## 安装流程详解

当执行 `npm install` 时，npm 会按照特定顺序执行生命周期脚本。

### 本地包安装流程

当你在项目中运行 `npm install` 安装依赖时：

```bash
npm install lodash
```

执行顺序如下：

1. **preinstall** - 在安装任何依赖之前执行
2. 解析并下载依赖
3. **install** - 安装过程中执行（主要用于原生模块编译）
4. **postinstall** - 安装完成后执行
5. **prepublish**（已弃用）- 不会在 `npm publish` 时运行，但会在 `npm ci` 和 `npm install` 时运行。推荐使用 `prepare` 和 `prepublishOnly` 替代
6. **preprepare** - prepare 之前
7. **prepare** - 安装后执行，常用于构建步骤
8. **postprepare** - prepare 之后

### 全局包安装流程

```bash
npm install -g typescript
```

全局安装时，会执行被安装包的以下脚本：

1. **preinstall**
2. **install**
3. **postinstall**
4. **preprepare**
5. **prepare**
6. **postprepare**

### 依赖包的脚本执行

当安装的依赖包自身定义了生命周期脚本时，npm 也会执行它们：

```
my-project
├── package.json (defines postinstall)
└── node_modules
    ├── package-a (defines postinstall)
    └── package-b (defines postinstall)
```

执行顺序：`package-a postinstall` → `package-b postinstall` → `my-project postinstall`

---

## 卸载流程详解

当执行 `npm uninstall` 时：

```bash
npm uninstall lodash
```

执行顺序：

1. **preuninstall** - 卸载前执行
2. **uninstall** - 卸载过程中执行
3. **postuninstall** - 卸载完成后执行

### 卸载脚本示例

```json
{
  "scripts": {
    "preuninstall": "node scripts/cleanup.js",
    "uninstall": "echo 'Uninstalling...'",
    "postuninstall": "echo 'Cleanup complete'"
  }
}
```

---

## 发布流程详解

当执行 `npm publish` 时，流程较为复杂：

### 完整发布流程

```bash
npm publish
```

执行顺序：

1. **prepare** - 准备阶段（如果包是从本地发布）
2. **prepublishOnly** - 仅在 publish 命令时执行
3. **prepack** - 创建 tarball 之前
4. **postpack** - 创建 tarball 之后
5. **publish** - 发布过程中
6. **postpublish** - 发布完成后

### prepublishOnly vs prepare

这是两个容易混淆的脚本：

| 脚本             | `npm publish` | `npm install` | `npm pack` |
| ---------------- | ------------- | ------------- | ---------- |
| `prepublishOnly` | ✅            | ❌            | ❌         |
| `prepare`        | ✅            | ✅            | ✅         |
| `prepack`        | ✅            | ❌            | ✅         |
| `postpack`       | ✅            | ❌            | ✅         |

**最佳实践**：

- 使用 `prepublishOnly` 运行测试和构建检查
- 使用 `prepare` 进行构建，确保从 git 安装时也能正常工作

```json
{
  "scripts": {
    "build": "tsc",
    "test": "jest",
    "prepublishOnly": "npm test",
    "prepare": "npm run build"
  }
}
```

---

## 版本管理生命周期

当使用 `npm version` 更新版本时：

```bash
npm version patch  # 1.0.0 -> 1.0.1
npm version minor  # 1.0.0 -> 1.1.0
npm version major  # 1.0.0 -> 2.0.0
```

### 执行顺序

1. **preversion** - 版本更新前
2. 更新 `package.json` 中的版本号
3. **version** - 版本更新时
4. 创建 git commit 和 tag（如果在 git 仓库中）
5. **postversion** - 版本更新后

### 实际应用示例

```json
{
  "scripts": {
    "preversion": "npm test",
    "version": "npm run build && git add -A dist",
    "postversion": "git push && git push --tags && npm publish"
  }
}
```

这个配置实现了：

1. 版本更新前运行测试
2. 版本更新时构建并提交 dist 目录
3. 版本更新后推送代码、标签并发布到 npm

---

## 实际应用示例

### 示例 1：TypeScript 项目配置

```json
{
  "name": "my-typescript-lib",
  "version": "1.0.0",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "files": ["dist"],
  "scripts": {
    "build": "tsc",
    "test": "jest",
    "lint": "eslint src/**/*.ts",
    "clean": "rimraf dist",
    "prebuild": "npm run clean",
    "prepare": "npm run build",
    "prepublishOnly": "npm run lint && npm test",
    "preversion": "npm run lint && npm test",
    "version": "npm run build && git add -A",
    "postversion": "git push && git push --tags"
  }
}
```

**工作流程说明**：

1. 开发时：修改源码后运行 `npm run build`
2. 安装时（`npm install`）：自动触发 `prepare` 构建项目
3. 发布前（`npm publish`）：先运行 lint 和测试
4. 版本更新（`npm version patch`）：测试 → 构建 → 提交 → 推送

### 示例 2：原生模块编译

```json
{
  "name": "native-addon",
  "version": "1.0.0",
  "scripts": {
    "install": "node-gyp rebuild",
    "preinstall": "node scripts/check-dependencies.js"
  }
}
```

`scripts/check-dependencies.js`:

```javascript
const { execSync } = require("child_process");

function checkCommand(cmd) {
  try {
    execSync(`which ${cmd}`, { stdio: "ignore" });
    return true;
  } catch {
    return false;
  }
}

// 检查必要的编译工具
const requirements = ["python3", "make", "g++"];
const missing = requirements.filter((cmd) => !checkCommand(cmd));

if (missing.length > 0) {
  console.error(`Missing required build tools: ${missing.join(", ")}`);
  console.error("Please install them before continuing.");
  process.exit(1);
}

console.log("All build dependencies are satisfied.");
```

### 示例 3：Git Hooks 集成（Husky）

现代 Husky (v9+) 使用 `.husky/` 目录配置 Git hooks：

```json
{
  "name": "my-project",
  "version": "1.0.0",
  "scripts": {
    "prepare": "husky"
  },
  "lint-staged": {
    "*.{js,ts}": ["eslint --fix", "prettier --write"]
  }
}
```

然后创建 hook 文件：

```bash
# 初始化 husky
npx husky init

# .husky/pre-commit 文件内容
npx lint-staged

# .husky/commit-msg 文件内容
npx --no -- commitlint --edit $1
```

> **注意**：`pre-commit` 和 `commit-msg` 是 Git hooks，不是 npm 生命周期脚本。它们需要通过 Husky 配置在 `.husky/` 目录下，而不是放在 `package.json` 的 `scripts` 中。

### 示例 4：数据库迁移

```json
{
  "name": "my-api",
  "version": "1.0.0",
  "scripts": {
    "db:migrate": "prisma migrate deploy",
    "db:generate": "prisma generate",
    "build": "tsc",
    "postinstall": "npm run db:generate",
    "prestart": "npm run db:migrate",
    "start": "node dist/server.js"
  }
}
```

### 示例 5：环境检查与初始化

```json
{
  "name": "enterprise-app",
  "version": "1.0.0",
  "scripts": {
    "preinstall": "node scripts/check-node-version.js",
    "postinstall": "node scripts/setup-env.js",
    "prepare": "npm run build"
  }
}
```

`scripts/check-node-version.js`:

```javascript
// 注意：preinstall 阶段依赖尚未安装，必须使用原生 Node.js 方法
const { engines } = require("../package.json");

const currentVersion = process.version;
const requiredVersion = engines.node;

// 简单的版本检查（不使用 semver 库）
function satisfiesVersion(current, required) {
  // 移除 'v' 前缀和 '>=' 等符号
  const currentParts = current.replace("v", "").split(".").map(Number);
  const requiredParts = required
    .replace(/[>=^~v]/g, "")
    .split(".")
    .map(Number);

  for (let i = 0; i < requiredParts.length; i++) {
    if (currentParts[i] > requiredParts[i]) return true;
    if (currentParts[i] < requiredParts[i]) return false;
  }
  return true;
}

if (!satisfiesVersion(currentVersion, requiredVersion)) {
  console.error(
    `Required Node.js version ${requiredVersion}, but current version is ${currentVersion}`,
  );
  console.error("Please upgrade your Node.js version.");
  process.exit(1);
}
```

`scripts/setup-env.js`:

```javascript
const fs = require("fs");
const path = require("path");

const envExample = path.join(__dirname, "..", ".env.example");
const envFile = path.join(__dirname, "..", ".env");

if (!fs.existsSync(envFile) && fs.existsSync(envExample)) {
  fs.copyFileSync(envExample, envFile);
  console.log("Created .env file from .env.example");
  console.log("Please update the .env file with your configuration.");
}
```

---

## 最佳实践

### 1. 脚本命名规范

```jsonc
// 注意：标准 JSON 不支持注释，此处使用 JSONC 格式用于说明
{
  "scripts": {
    // 使用 pre/post 前缀来自动化流程
    "prebuild": "npm run clean",
    "build": "tsc",
    "postbuild": "npm run copy-assets",

    // 使用冒号分隔命名空间
    "db:migrate": "prisma migrate deploy",
    "db:seed": "prisma db seed",
    "db:reset": "prisma migrate reset",

    // 测试相关
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
  },
}
```

### 2. 确保脚本幂等性

生命周期脚本可能被多次执行，确保它们是幂等的：

```javascript
// ❌ 不好的做法
const fs = require("fs");
fs.appendFileSync("log.txt", "installed\n");

// ✅ 好的做法
const fs = require("fs");
if (!fs.existsSync("config.json")) {
  fs.writeFileSync("config.json", JSON.stringify(defaultConfig));
}
```

### 3. 错误处理

```javascript
// scripts/postinstall.js
const { execSync } = require("child_process");

try {
  execSync("some-command", { stdio: "inherit" });
} catch (error) {
  console.error("Postinstall script failed:", error.message);
  // 决定是否应该终止安装
  // process.exit(1);  // 终止安装
  // 或者只是警告
  console.warn("Continuing despite error...");
}
```

### 4. 跨平台兼容

```json
{
  "scripts": {
    // ❌ 只在 Unix 上工作
    "clean": "rm -rf dist",

    // ✅ 跨平台
    "clean": "rimraf dist",

    // ❌ 只在 Unix 上工作
    "copy": "cp -r assets dist/",

    // ✅ 跨平台
    "copy": "copyfiles -u 1 assets/**/* dist/"
  }
}
```

推荐使用的跨平台工具：

| 功能     | Unix 命令   | 跨平台替代                    |
| -------- | ----------- | ----------------------------- |
| 删除     | `rm -rf`    | `rimraf`                      |
| 复制     | `cp`        | `copyfiles`, `cpy-cli`        |
| 移动     | `mv`        | `move-cli`                    |
| 环境变量 | `VAR=value` | `cross-env`                   |
| 并行执行 | `&`         | `npm-run-all`, `concurrently` |

### 5. 性能优化

```json
{
  "scripts": {
    // 并行执行独立任务
    "build": "npm-run-all --parallel build:*",
    "build:js": "rollup -c",
    "build:css": "sass src:dist",
    "build:types": "tsc --emitDeclarationOnly",

    // 只在需要时运行
    "prepare": "is-ci || husky install"
  }
}
```

### 6. 避免在 CI 中运行不必要的脚本

```json
{
  "scripts": {
    "prepare": "is-ci || husky install",
    "postinstall": "is-ci || npm run setup-dev"
  }
}
```

或使用 npm 的内置环境变量：

```javascript
// scripts/postinstall.js
if (process.env.CI) {
  console.log("Skipping postinstall in CI environment");
  process.exit(0);
}

// 执行开发环境设置...
```

---

## 常见问题与调试

### 1. 查看脚本执行顺序

```bash
# 使用 --foreground-scripts 显示脚本输出
npm install --foreground-scripts

# 使用 --verbose 查看详细输出
npm install --verbose

# 使用 --dry-run 预览将要安装的包（不显示脚本详情）
npm install --dry-run
```

### 2. 跳过生命周期脚本

```bash
# 跳过所有脚本
npm install --ignore-scripts
```

> **注意**：npm 不支持跳过单个特定脚本，`--ignore-scripts` 会跳过所有生命周期脚本。

### 3. 调试脚本

```json
{
  "scripts": {
    "postinstall": "node --inspect-brk scripts/postinstall.js"
  }
}
```

### 4. 常见错误及解决方案

**错误：EACCES permission denied**

```bash
# 不要使用 sudo，改用 nvm 或修复权限
npm config set prefix ~/.npm-global
export PATH=~/.npm-global/bin:$PATH
```

**错误：lifecycle script failed**

```bash
# 查看详细日志
npm install --loglevel verbose

# 检查 npm 日志
cat ~/.npm/_logs/[latest-log].log
```

**错误：Maximum call stack exceeded（循环依赖）**

检查你的脚本是否存在循环调用：

```json
{
  "scripts": {
    // ❌ 循环调用
    "build": "npm run compile",
    "compile": "npm run build"
  }
}
```

### 5. 生命周期脚本中的环境变量

npm 会在脚本执行时设置一些有用的环境变量：

```javascript
// 在脚本中可用的环境变量
console.log(process.env.npm_package_name); // 包名
console.log(process.env.npm_package_version); // 版本
console.log(process.env.npm_lifecycle_event); // 当前脚本名称
console.log(process.env.npm_config_registry); // npm registry
```

---

## 总结

npm package lifecycle 是一个强大的自动化机制，合理使用可以显著提升开发效率和代码质量。

### 核心要点回顾

1. **安装流程**：`preinstall` → `install` → `postinstall` → `preprepare` → `prepare` → `postprepare`
2. **发布流程**：`prepare` → `prepublishOnly` → `prepack` → `postpack` → `publish` → `postpublish`
3. **版本流程**：`preversion` → `version` → `postversion`
4. **卸载流程**：`preuninstall` → `uninstall` → `postuninstall`

### 推荐配置

对于大多数 TypeScript/JavaScript 项目，推荐以下配置：

```json
{
  "scripts": {
    "build": "tsc",
    "test": "jest",
    "lint": "eslint .",
    "clean": "rimraf dist",
    "prepare": "npm run build",
    "prepublishOnly": "npm run lint && npm test",
    "preversion": "npm test",
    "postversion": "git push && git push --tags"
  }
}
```

### 最终建议

1. **保持简单**：不要过度使用生命周期脚本
2. **确保幂等**：脚本应该可以安全地多次执行
3. **跨平台兼容**：使用跨平台工具替代系统命令
4. **适当错误处理**：明确脚本失败时的行为
5. **文档化**：在 README 中说明特殊的生命周期脚本

通过掌握 npm 生命周期，你可以构建更加自动化、可靠的 Node.js 项目工作流。

---

## 参考资料

- [npm 官方文档 - scripts](https://docs.npmjs.com/cli/v10/using-npm/scripts)
- [npm 官方文档 - lifecycle scripts](https://docs.npmjs.com/cli/v10/using-npm/scripts#life-cycle-scripts)
- [Node.js 最佳实践](https://github.com/goldbergyoni/nodebestpractices)
