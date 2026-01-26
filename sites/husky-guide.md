# Husky 使用指南

## 1. 概述

### 1.1 什么是 Husky

Husky 是一个轻量级的 Git Hooks 管理工具，专为 Node.js 项目设计。它利用 Git 的 `core.hooksPath` 特性，让团队可以在版本控制中共享 Git Hooks 配置。

**核心特性：**

| 特性     | 说明                                      |
| -------- | ----------------------------------------- |
| 轻量     | 仅 2kB（gzipped），零依赖                 |
| 快速     | 执行时间约 1ms                            |
| 跨平台   | 支持 macOS、Linux、Windows                |
| 全面支持 | 支持全部 13 种客户端 Git Hooks            |
| 生态完善 | 与 lint-staged、commitlint 等工具无缝集成 |

### 1.2 工作原理

```
项目目录/
├── .husky/
│   ├── pre-commit      # pre-commit hook 脚本
│   └── commit-msg      # commit-msg hook 脚本
├── package.json        # 包含 prepare 脚本
└── ...
```

1. **安装时**：设置 Git 的 `core.hooksPath` 指向 `.husky` 目录
2. **触发时**：Git 事件触发 `.husky` 目录中对应的脚本
3. **执行时**：脚本运行指定命令，失败则阻止 Git 操作

---

## 2. 安装和配置

### 2.1 快速开始（推荐）

使用 `husky init` 一键完成安装和初始化：

```bash
# npm
npx husky init

# pnpm
pnpm exec husky init

# yarn
yarn dlx husky init

# bun
bunx husky init
```

该命令会自动：

- 安装 husky 作为开发依赖
- 创建 `.husky/` 目录
- 在 `package.json` 中添加 `prepare` 脚本
- 创建示例 `pre-commit` hook

### 2.2 手动安装

```bash
# 1. 安装
npm install husky --save-dev

# 2. 初始化
npx husky init
```

`package.json` 中的 prepare 脚本：

```json
{
  "scripts": {
    "prepare": "husky"
  }
}
```

> `prepare` 脚本在 `npm install` 后自动执行，确保团队成员克隆项目后自动配置 hooks。

### 2.3 添加 Hook

创建 hook 非常简单，只需在 `.husky/` 目录下创建对应名称的文件：

```bash
# 方法 1：使用 echo
echo "npm test" > .husky/pre-commit

# 方法 2：手动创建文件
# 直接编辑 .husky/pre-commit 文件
```

Hook 脚本示例：

```bash
# .husky/pre-commit
npm run lint
npm test
```

> **注意**：Husky v9 的 hook 脚本不需要 shebang 行（如 `#!/bin/sh`），Husky 会自动处理。

### 2.4 在 CI/Docker 中禁用

CI 环境通常不需要 Git hooks：

```bash
# 方法 1：环境变量（推荐）
HUSKY=0 npm ci

# 方法 2：GitHub Actions
- run: npm ci
  env:
    HUSKY: 0

# 方法 3：package.json 容错处理
{
  "scripts": {
    "prepare": "husky || true"
  }
}
```

---

## 3. 常用 Git Hooks

### 3.1 pre-commit

提交前执行，用于代码检查和格式化。

```bash
# .husky/pre-commit
npx lint-staged
```

### 3.2 commit-msg

验证提交信息格式。

```bash
# .husky/commit-msg
npx --no -- commitlint --edit $1
```

自定义验证示例：

```bash
# .husky/commit-msg
commit_msg=$(cat "$1")
pattern="^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .{1,50}"

if ! echo "$commit_msg" | grep -qE "$pattern"; then
    echo "错误：提交信息格式不正确"
    echo "格式：<type>(<scope>): <subject>"
    exit 1
fi
```

### 3.3 pre-push

推送前执行，用于运行测试。

```bash
# .husky/pre-push
npm test
npm run build
```

### 3.4 post-merge

合并/拉取后执行，用于自动更新依赖。

```bash
# .husky/post-merge
changed=$(git diff-tree -r --name-only --no-commit-id ORIG_HEAD HEAD)

if echo "$changed" | grep -q "package-lock.json"; then
    echo "依赖变化，正在安装..."
    npm ci
fi
```

---

## 4. 与其他工具集成

### 4.1 lint-staged

只对暂存文件运行检查，大幅提升速度。

```bash
npm install lint-staged --save-dev
```

**package.json 配置：**

```json
{
  "lint-staged": {
    "*.{js,ts,jsx,tsx}": ["eslint --fix", "prettier --write"],
    "*.{css,scss}": "prettier --write",
    "*.md": "prettier --write"
  }
}
```

**Husky 配置：**

```bash
# .husky/pre-commit
npx lint-staged
```

### 4.2 commitlint

检查提交信息是否符合 Conventional Commits 规范。

```bash
npm install @commitlint/cli @commitlint/config-conventional --save-dev
```

**commitlint.config.js：**

```javascript
module.exports = {
  extends: ["@commitlint/config-conventional"],
};
```

**Husky 配置：**

```bash
# .husky/commit-msg
npx --no -- commitlint --edit $1
```

### 4.3 完整配置示例

**package.json：**

```json
{
  "scripts": {
    "prepare": "husky",
    "lint": "eslint src",
    "test": "jest"
  },
  "devDependencies": {
    "@commitlint/cli": "^19.0.0",
    "@commitlint/config-conventional": "^19.0.0",
    "husky": "^9.0.0",
    "lint-staged": "^15.0.0"
  },
  "lint-staged": {
    "*.{js,ts}": ["eslint --fix", "prettier --write"]
  }
}
```

**.husky/pre-commit：**

```bash
npx lint-staged
```

**.husky/commit-msg：**

```bash
npx --no -- commitlint --edit $1
```

---

## 5. 最佳实践

### 5.1 性能优化

```bash
# 使用 lint-staged 只检查变更文件
npx lint-staged

# ESLint 启用缓存
eslint --fix --cache

# 耗时任务放到 pre-push 而非 pre-commit
```

### 5.2 Monorepo 配置

当 `package.json` 不在 Git 根目录时：

```json
{
  "scripts": {
    "prepare": "cd .. && husky frontend/.husky"
  }
}
```

### 5.3 启动文件

配置 Node 版本管理器（nvm、fnm 等）的初始化脚本：

```bash
# ~/.config/husky/init.sh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

---

## 6. 故障排除

### 6.1 Hooks 不执行

```bash
# 1. 检查 hook 文件名是否正确（不能是 precommit 或 pre-commit.sh）
ls .husky/

# 2. 检查 Git hooks 路径
git config core.hooksPath

# 3. 确保 Git 版本 >= 2.9
git --version

# 4. 重新初始化
npx husky init
```

### 6.2 Command not found

GUI 应用或某些环境可能找不到 node/npm，配置启动文件：

```bash
# ~/.config/husky/init.sh
export PATH="/usr/local/bin:$PATH"
```

### 6.3 卸载后残留问题

如果卸载 Husky 后 hooks 仍然失败：

```bash
git config --unset core.hooksPath
```

### 6.4 Windows + Yarn 问题

Git Bash 配合 Yarn 可能出现 "stdin is not a tty" 错误：

```bash
# .husky/common.sh
if [ -t 1 ]; then
  exec < /dev/tty
fi
```

```bash
# .husky/pre-commit
. "$(dirname "$0")/common.sh"
yarn lint
```

### 6.5 跳过 Hooks

```bash
# 单次跳过
git commit --no-verify -m "message"
git push --no-verify

# 临时禁用所有 hooks
HUSKY=0 git commit -m "message"

# 多个命令
export HUSKY=0
git add .
git commit -m "message"
unset HUSKY
```

### 6.6 测试 Hook

```bash
# 直接运行脚本
sh .husky/pre-commit

# 添加 exit 1 测试是否能阻止提交
echo "exit 1" >> .husky/pre-commit

# 查看详细执行过程
GIT_TRACE=1 git commit -m "test"
```

---

## 7. 版本迁移

### 7.1 从 v4 迁移到 v9

**v4 配置（旧）：**

```json
{
  "husky": {
    "hooks": {
      "pre-commit": "lint-staged",
      "commit-msg": "commitlint -E HUSKY_GIT_PARAMS"
    }
  }
}
```

**v9 配置（新）：**

```bash
# .husky/pre-commit
npx lint-staged
```

```bash
# .husky/commit-msg
npx --no -- commitlint --edit $1
```

**迁移步骤：**

```bash
# 1. 升级
npm install husky@latest --save-dev

# 2. 删除 package.json 中的 "husky" 字段

# 3. 初始化
npx husky init

# 4. 创建 hooks
echo "npx lint-staged" > .husky/pre-commit
echo "npx --no -- commitlint --edit \$1" > .husky/commit-msg
```

**主要变化：**

| 方面      | v4               | v9           |
| --------- | ---------------- | ------------ |
| 配置位置  | package.json     | .husky/ 目录 |
| Hook 格式 | JSON             | Shell 脚本   |
| 环境变量  | HUSKY_GIT_PARAMS | $1           |
| 大小      | ~1MB             | 2kB          |

---

## 参考资源

- [Husky 官方文档](https://typicode.github.io/husky/)
- [Git Hooks](https://git-scm.com/docs/githooks)
- [NPM Script](https://docs.npmjs.com/cli/v11/using-npm/scripts)
- [lint-staged](https://github.com/lint-staged/lint-staged)
- [commitlint](https://commitlint.js.org/)
