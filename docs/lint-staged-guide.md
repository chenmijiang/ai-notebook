# lint-staged 使用指南

## 1. 概述

### 1.1 什么是 lint-staged

lint-staged 是一个在 Git 暂存文件上运行 linter 的工具。它只检查即将提交的文件，而非整个项目，从而大幅提升代码检查效率。

**核心价值：**

| 特性     | 说明                                       |
| -------- | ------------------------------------------ |
| 增量检查 | 只处理 `git add` 的文件，而非全量扫描      |
| 速度快   | 提交 3 个文件只检查 3 个文件，秒级完成     |
| 自动修复 | 支持 `--fix` 类命令，自动修复并更新暂存区  |
| 安全可靠 | 执行前自动 stash 未暂存的更改，失败时恢复  |
| 灵活配置 | 支持 glob 模式匹配，可针对不同文件类型配置 |

### 1.2 为什么使用 lint-staged

**全量检查 vs 增量检查：**

| 场景           | 全量检查（eslint src/）   | lint-staged            |
| -------------- | ------------------------- | ---------------------- |
| 项目 1000 文件 | 检查 1000 文件，耗时 30s+ | 只检查修改的 3 个文件  |
| 开发体验       | 每次提交等待时间长        | 秒级完成，流畅提交     |
| CI 负担        | 本地不检查，CI 发现问题   | 本地拦截，减少 CI 失败 |

### 1.3 工作原理

```
   git add file.js
         │
         ▼
┌─────────────────┐
│   git commit    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   pre-commit    │──► Husky 触发
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   lint-staged   │
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌───────┐ ┌───────┐
│ Stash │ │ 获取  │
│ 未暂存 │ │暂存文件│
│ 更改  │  │ 列表  │
└───────┘ └───┬───┘
              │
              ▼
     ┌────────────────┐
     │ 按 glob 匹配    │
     │ 运行对应命令     │
     └────────┬───────┘
              │
      ┌───────┴───────┐
      ▼               ▼
  ✅ 成功          ❌ 失败
  继续提交         恢复 stash
                   阻止提交
```

## 2. 安装和配置

### 2.1 快速开始

```bash
# npm
npm install lint-staged --save-dev

# pnpm
pnpm add lint-staged -D

# yarn
yarn add lint-staged -D

# bun
bun add -D lint-staged
```

### 2.2 配置方式

lint-staged 支持多种配置文件格式：

| 配置方式                 | 格式       | 适用场景           |
| ------------------------ | ---------- | ------------------ |
| `package.json`           | JSON       | 简单配置，减少文件 |
| `.lintstagedrc`          | JSON/YAML  | 独立配置文件       |
| `.lintstagedrc.js`       | JavaScript | 需要动态逻辑       |
| `.lintstagedrc.mjs`      | ES Module  | ESM 项目           |
| `lint-staged.config.js`  | JavaScript | 标准命名           |
| `lint-staged.config.mjs` | ES Module  | ESM 项目标准命名   |

**package.json 配置示例：**

```json
{
  "lint-staged": {
    "*.js": "eslint --fix",
    "*.css": "prettier --write"
  }
}
```

**.lintstagedrc 配置示例：**

```json
{
  "*.{js,ts}": ["eslint --fix", "prettier --write"],
  "*.md": "prettier --write"
}
```

### 2.3 配合 Husky 使用

lint-staged 通常配合 Husky 在 pre-commit hook 中运行：

```bash
# 1. 安装 husky
npx husky init

# 2. 配置 pre-commit hook
echo "npx lint-staged" > .husky/pre-commit
```

> **提示**：Husky 的详细配置请参考 [Husky 使用指南](./husky-guide.md)。

## 3. 配置语法详解

### 3.1 Glob 模式匹配

lint-staged 使用 [micromatch](https://github.com/micromatch/micromatch) 进行文件匹配：

| 模式                | 匹配                 | 说明            |
| ------------------- | -------------------- | --------------- |
| `*.js`              | `file.js`            | 根目录下的 js   |
| `**/*.js`           | `src/utils/file.js`  | 所有目录下的 js |
| `*.{js,ts}`         | `file.js`, `file.ts` | 多扩展名        |
| `src/**/*.js`       | `src/` 下所有 js     | 指定目录        |
| `!*.min.js`         | 排除 `.min.js`       | 否定模式        |
| `*.{js,ts,jsx,tsx}` | 所有 JS/TS 文件      | 前端项目常用    |

**组合示例：**

```json
{
  "*.{js,jsx,ts,tsx}": "eslint --fix",
  "*.{css,scss,less}": "stylelint --fix",
  "*.{json,md,yml}": "prettier --write",
  "!*.min.js": "eslint"
}
```

### 3.2 命令配置

**单命令（字符串）：**

```json
{
  "*.js": "eslint --fix"
}
```

**多命令（数组）- 按顺序执行：**

```json
{
  "*.js": ["eslint --fix", "prettier --write"]
}
```

> **注意**：数组中的命令按顺序执行，前一个命令失败会阻止后续命令。lint-staged 默认会自动将修复后的修改重新暂存，通常不需要手动 `git add`。

**不同文件类型不同命令：**

```json
{
  "*.js": ["eslint --fix", "prettier --write"],
  "*.css": ["stylelint --fix", "prettier --write"],
  "*.md": "prettier --write"
}
```

### 3.3 文件路径处理

lint-staged 将**绝对路径**传递给命令：

```bash
# 假设暂存了 src/utils/helper.js
# 实际执行的命令：
eslint --fix /Users/project/src/utils/helper.js
```

**多个文件时：**

```bash
# 暂存了 3 个文件
eslint --fix /path/file1.js /path/file2.js /path/file3.js
```

**使用相对路径：**

如果工具需要相对路径，使用函数配置：

```javascript
// lint-staged.config.js
import path from "path";

export default {
  "*.js": (filenames) =>
    filenames.map((f) => `eslint --fix ${path.relative(process.cwd(), f)}`),
};
```

## 4. 常用场景

### 4.1 JavaScript/TypeScript 项目

```json
{
  "lint-staged": {
    "*.{js,jsx,ts,tsx}": ["eslint --fix", "prettier --write"]
  }
}
```

**ESLint 配置要点：**

```javascript
// eslint.config.js (Flat Config)
export default [
  {
    rules: {
      // 确保规则支持 --fix 自动修复
      semi: "error",
      quotes: ["error", "single"],
    },
  },
];
```

### 4.2 样式文件

```json
{
  "lint-staged": {
    "*.{css,scss,less}": ["stylelint --fix", "prettier --write"],
    "*.{css,scss}": "stylelint --fix"
  }
}
```

**Stylelint 配置示例：**

```javascript
// stylelint.config.js
export default {
  extends: ["stylelint-config-standard"],
  rules: {
    "color-hex-length": "short",
  },
};
```

### 4.3 JSON/YAML/Markdown

```json
{
  "lint-staged": {
    "*.json": "prettier --write",
    "*.{yml,yaml}": "prettier --write",
    "*.md": "prettier --write"
  }
}
```

### 4.4 完整前端项目配置

```json
{
  "scripts": {
    "prepare": "husky",
    "lint": "eslint src",
    "format": "prettier --write ."
  },
  "devDependencies": {
    "eslint": "^9.0.0",
    "husky": "^9.0.0",
    "lint-staged": "^16.0.0",
    "prettier": "^3.0.0",
    "stylelint": "^16.0.0"
  },
  "lint-staged": {
    "*.{js,jsx,ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.{css,scss,less}": ["stylelint --fix", "prettier --write"],
    "*.{json,md,yml,yaml}": "prettier --write"
  }
}
```

**.husky/pre-commit：**

```bash
npx lint-staged
```

## 5. 高级配置

### 5.1 函数式配置

使用 JavaScript 配置文件可以实现动态命令生成：

**根据文件数量调整行为：**

```javascript
// lint-staged.config.js
export default {
  "*.ts": (filenames) => {
    // 文件少时单独检查，文件多时使用项目配置
    if (filenames.length > 10) {
      return "eslint --fix .";
    }
    return filenames.map((f) => `eslint --fix "${f}"`);
  },
};
```

**TypeScript 类型检查（不传文件参数）：**

```javascript
// lint-staged.config.js
export default {
  "*.{ts,tsx}": () => "tsc --noEmit",
};
```

> **注意**：使用函数配置时，lint-staged 不会自动将文件列表追加到命令，需要在返回的命令里手动拼接文件路径。

**条件执行：**

```javascript
// lint-staged.config.js
export default {
  "*.js": (filenames) => {
    // 只在包含测试文件时运行测试
    const testFiles = filenames.filter((f) => f.includes(".test."));
    const commands = ["eslint --fix"];
    if (testFiles.length > 0) {
      commands.push("jest --findRelatedTests");
    }
    return commands;
  },
};
```

### 5.2 并发控制

lint-staged 默认并发执行不同 glob 的任务，但在任务冲突或资源受限时需要调整。

**执行顺序规则：**

| 场景                 | 执行方式 | 示例                                           |
| -------------------- | -------- | ---------------------------------------------- |
| 不同 glob 模式       | 并发执行 | `*.ts` 和 `*.css` 的任务同时启动               |
| 同一 glob 的命令数组 | 顺序执行 | `["eslint", "prettier"]` 先 eslint 后 prettier |

**CLI 选项：**

| 选项                  | 说明                                     | 默认值 |
| --------------------- | ---------------------------------------- | ------ |
| `--concurrent`        | 不同 glob 的任务并发执行                 | `true` |
| `--concurrent=false`  | 所有 glob 的任务顺序执行                 | -      |
| `--concurrent=<数字>` | 限制最多同时执行的任务数，`1` 等同于串行 | -      |

> **注意**：`--concurrent` 仅控制不同 glob 之间的并发，同一 glob 内的多个命令（数组形式）始终按顺序串行执行。

**何时需要调整并发：**

| 场景               | 问题                            | 解决方式             |
| ------------------ | ------------------------------- | -------------------- |
| glob 模式有重叠    | 多个任务同时修改同一文件        | `--concurrent=false` |
| CI 环境资源受限    | 并发任务导致内存不足或 CPU 争用 | `--concurrent=2`     |
| 任务之间有隐式依赖 | 执行顺序不确定导致结果不一致    | `--concurrent=false` |

**glob 重叠的处理：**

当多个 glob 模式匹配同一文件时，可能导致竞争条件。关于否定模式 `!` 的用法，请参考 [3.1 Glob 模式匹配](#31-glob-模式匹配)。

```javascript
// ❌ 问题：*.{js,ts} 和 *.ts 重叠，prettier 可能同时修改 .ts 文件
{
  "*.{js,ts}": "prettier --write",
  "*.ts": ["eslint --fix", "prettier --write"]
}

// ✅ 修复：使用否定模式避免重叠
{
  "!(*.ts)": "prettier --write",
  "*.ts": ["eslint --fix", "prettier --write"]
}
```

### 5.3 性能优化

合理的配置可以显著提升 lint-staged 的执行效率：

```javascript
// ✅ 好的实践：让工具一次接收所有文件，只启动一个进程
{
  "*.js": "eslint --fix"
}
// 实际执行：eslint --fix file1.js file2.js file3.js

// ❌ 坏的实践：每个文件启动一个独立进程，开销大
{
  "*.js": (files) => files.map(f => `eslint --fix ${f}`)
}
// 实际执行：eslint --fix file1.js && eslint --fix file2.js && ...
```

**优化要点：**

| 场景            | 推荐做法                                   | 原因                                  |
| --------------- | ------------------------------------------ | ------------------------------------- |
| 多文件处理      | 使用字符串配置，让工具批量处理             | 避免重复启动进程                      |
| TypeScript 项目 | `() => "tsc --noEmit"` 不传文件参数        | tsc 需要完整项目上下文                |
| 大量文件        | 函数配置中判断文件数量，超过阈值时全量检查 | 参考 [5.1 函数式配置](#51-函数式配置) |

### 5.4 部分暂存文件处理

当文件被部分暂存（部分更改已 `git add`，部分未暂存）时，lint-staged 会：

1. 将未暂存的更改 stash
2. 在暂存版本上运行任务
3. 如果任务修改了文件，将修改添加到暂存区
4. 恢复 stash

```bash
# 禁用 stash 行为（不推荐）
npx lint-staged --no-stash
```

> **注意**：`--no-stash` 可能导致未暂存的更改被意外提交。

### 5.5 允许空提交

当 linter 修复后文件变回原状时，默认会阻止空提交：

```bash
# 允许空提交
npx lint-staged --allow-empty
```

## 6. 与工具链集成

### 6.1 Husky 集成

推荐配置：

```bash
# .husky/pre-commit
npx lint-staged
```

传递参数：

```bash
# .husky/pre-commit
npx lint-staged --verbose
```

> 详细 Husky 配置请参考 [Husky 使用指南](./husky-guide.md)。

### 6.2 Monorepo 配置

**pnpm workspace：**

```json
// 根目录 package.json
{
  "lint-staged": {
    "packages/**/*.{js,ts}": "eslint --fix",
    "*.{json,md}": "prettier --write"
  }
}
```

**每个包独立配置：**

```
monorepo/
├── package.json          # 根配置
├── packages/
│   ├── app/
│   │   ├── package.json
│   │   └── .lintstagedrc  # app 特定配置
│   └── lib/
│       ├── package.json
│       └── .lintstagedrc  # lib 特定配置
```

**使用 lerna/nx：**

```json
// 根目录 package.json
{
  "lint-staged": {
    "*.{js,ts}": "npx nx affected:lint --fix --files"
  }
}
```

### 6.3 与 Prettier 配合

**配置顺序很重要：**

```json
{
  "*.js": [
    "eslint --fix",
    "prettier --write"
  ]
}
```

> **提示**：先运行 ESLint 修复逻辑问题，再运行 Prettier 格式化，避免冲突。

**使用 eslint-plugin-prettier：**

如果项目使用 eslint-plugin-prettier，只需运行 ESLint：

```json
{
  "*.js": "eslint --fix"
}
```

## 7. 故障排除

### 7.1 常见问题

**Q1：命令未执行？**

检查 glob 模式是否匹配：

```bash
# 调试模式查看匹配情况
npx lint-staged --debug
```

常见原因：

- `*.js` 只匹配根目录，深层目录需要 `**/*.js`
- 文件未 `git add` 到暂存区

**Q2：ESLint 报错但文件未修复？**

确保 ESLint 规则支持自动修复：

```javascript
// 可自动修复
"semi": "error"
"quotes": ["error", "single"]

// 不可自动修复（需手动处理）
"no-unused-vars": "error"
```

**Q3：Prettier 和 ESLint 冲突？**

使用 eslint-config-prettier 禁用冲突规则：

```bash
npm install eslint-config-prettier -D
```

```javascript
// eslint.config.js
import prettier from "eslint-config-prettier";

export default [
  // 其他配置...
  prettier, // 放在最后
];
```

**Q4：部分暂存文件修复后包含未暂存更改？**

这是预期行为。lint-staged 只修复暂存的部分，未暂存的更改保持不变。

### 7.2 调试技巧

```bash
# 显示详细执行过程
npx lint-staged --debug

# 显示成功任务的输出
npx lint-staged --verbose

# 组合使用
npx lint-staged --debug --verbose
```

**调试输出示例：**

```
lint-staged:bin Running `lint-staged@15.0.0`
lint-staged:cfg Loaded config from `/project/package.json`
lint-staged Matching staged files...
lint-staged Matched 3 files: file1.js, file2.js, file3.js
lint-staged Running tasks...
```

### 7.3 跳过检查

紧急情况下跳过 pre-commit hook：

```bash
# 跳过所有 hooks
git commit --no-verify -m "紧急修复"

# 或使用简写
git commit -n -m "紧急修复"
```

> **注意**：不建议频繁使用 `--no-verify`，这会绕过代码质量检查。

### 7.4 重置配置

如果配置出现问题：

```bash
# 清除 lint-staged 缓存
rm -rf node_modules/.cache/lint-staged

# 重新安装依赖
rm -rf node_modules && npm install
```

## 8. 总结

### 8.1 核心要点

1. lint-staged 只检查暂存文件，提升提交效率
2. 配合 Husky 在 pre-commit hook 中自动运行
3. 使用 glob 模式为不同文件类型配置不同命令
4. 命令数组按顺序执行，支持先 lint 后 format
5. 函数配置可实现动态命令生成
6. 不同 glob 默认并发执行，可通过 `--concurrent` 调整

### 8.2 速查表

**常用 Glob 模式：**

| 模式                       | 匹配文件              |
| -------------------------- | --------------------- |
| `*.js`                     | 根目录 JS 文件        |
| `**/*.js`                  | 所有目录 JS 文件      |
| `*.{js,ts}`                | JS 和 TS 文件         |
| `src/**/*.{js,jsx,ts,tsx}` | src 下所有 JS/TS 文件 |
| `!**/*.min.js`             | 排除压缩文件          |

**常用配置：**

| 场景                | 配置                                                |
| ------------------- | --------------------------------------------------- |
| JS/TS               | `"*.{js,ts}": ["eslint --fix", "prettier --write"]` |
| CSS                 | `"*.css": ["stylelint --fix", "prettier --write"]`  |
| JSON/MD             | `"*.{json,md}": "prettier --write"`                 |
| TypeScript 类型检查 | `"*.ts": () => "tsc --noEmit"`                      |

**CLI 选项：**

| 选项            | 说明           |
| --------------- | -------------- |
| `--debug`       | 显示调试信息   |
| `--verbose`     | 显示任务输出   |
| `--concurrent`  | 控制并发执行   |
| `--no-stash`    | 禁用自动 stash |
| `--allow-empty` | 允许空提交     |

## 参考资源

- [lint-staged 官方仓库](https://github.com/lint-staged/lint-staged)
- [Husky 使用指南](./husky-guide.md)
- [micromatch glob 语法](https://github.com/micromatch/micromatch)
- [ESLint 官方文档](https://eslint.org/)
- [Prettier 官方文档](https://prettier.io/)
- [Stylelint 官方文档](https://stylelint.io/)
