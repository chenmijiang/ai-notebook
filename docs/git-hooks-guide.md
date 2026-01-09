# Git Hooks 完全指南

## 目录

- [Git Hooks 完全指南](#git-hooks-完全指南)
  - [目录](#目录)
  - [1. 概述](#1-概述)
    - [1.1 什么是 Git Hooks](#11-什么是-git-hooks)
    - [1.2 Git Hooks 的作用](#12-git-hooks-的作用)
    - [1.3 使用场景](#13-使用场景)
  - [2. 基础知识](#2-基础知识)
    - [2.1 Hooks 存放位置](#21-hooks-存放位置)
    - [2.2 Hooks 的执行权限](#22-hooks-的执行权限)
    - [2.3 Hooks 的返回值](#23-hooks-的返回值)
    - [2.4 支持的脚本语言](#24-支持的脚本语言)
  - [3. 客户端 Hooks](#3-客户端-hooks)
    - [3.1 提交工作流 Hooks](#31-提交工作流-hooks)
    - [3.2 邮件工作流 Hooks](#32-邮件工作流-hooks)
    - [3.3 其他客户端 Hooks](#33-其他客户端-hooks)
  - [4. 服务端 Hooks](#4-服务端-hooks)
    - [4.1 pre-receive](#41-pre-receive)
    - [4.2 update](#42-update)
    - [4.3 post-receive](#43-post-receive)
    - [4.4 post-update](#44-post-update)
  - [5. 实用配置示例](#5-实用配置示例)
    - [5.1 完整的提交前检查流程](#51-完整的提交前检查流程)
    - [5.2 团队 Hooks 共享方案](#52-团队-hooks-共享方案)
  - [6. 最佳实践](#6-最佳实践)
    - [6.1 编写 Hooks 的原则](#61-编写-hooks-的原则)
    - [6.2 性能优化建议](#62-性能优化建议)
    - [6.3 调试技巧](#63-调试技巧)
  - [7. 常见问题解答 (FAQ)](#7-常见问题解答-faq)
  - [8. 工具推荐](#8-工具推荐)
  - [9. 总结](#9-总结)

---

## 1. 概述

### 1.1 什么是 Git Hooks

Git Hooks 是 Git 在特定重要动作发生时自动执行的脚本。它们分布在 Git 仓库的 `.git/hooks` 目录中，允许开发者在 Git 工作流的关键节点插入自定义逻辑。

Hooks 分为两大类：

- **客户端 Hooks**：在开发者本地机器上运行，由 `git commit`、`git merge` 等操作触发
- **服务端 Hooks**：在 Git 服务器上运行，由 `git push` 等网络操作触发

### 1.2 Git Hooks 的作用

Git Hooks 的核心价值在于自动化和标准化：

1. **代码质量保障**：在代码提交前自动执行代码检查、测试
2. **规范执行**：强制执行提交信息格式、分支命名规范
3. **自动化流程**：触发 CI/CD、通知、部署等自动化任务
4. **安全防护**：阻止敏感信息泄露、防止危险操作

### 1.3 使用场景

| 场景         | 适用的 Hook  | 说明                     |
| ------------ | ------------ | ------------------------ |
| 代码格式化   | pre-commit   | 自动格式化代码或检查格式 |
| 代码检查     | pre-commit   | 运行静态分析工具         |
| 提交信息规范 | commit-msg   | 验证提交信息格式         |
| 单元测试     | pre-push     | 推送前运行测试           |
| 持续集成     | post-receive | 推送后触发 CI 流程       |
| 自动部署     | post-receive | 代码推送后自动部署       |
| 权限控制     | update       | 控制谁可以推送到哪些分支 |

---

## 2. 基础知识

### 2.1 Hooks 存放位置

Git Hooks 默认存储在仓库的 `.git/hooks` 目录下。新创建的仓库会包含一些示例文件：

```bash
$ ls .git/hooks/
applypatch-msg.sample      pre-commit.sample
commit-msg.sample          prepare-commit-msg.sample
post-update.sample         pre-push.sample
pre-applypatch.sample      update.sample
```

这些 `.sample` 文件是示例，不会被执行。要启用某个 hook，需要：

1. 去掉 `.sample` 后缀
2. 确保文件有执行权限

也可以通过配置自定义 hooks 目录：

```bash
# 设置自定义 hooks 目录（项目级）
git config core.hooksPath .githooks

# 全局设置
git config --global core.hooksPath ~/.githooks
```

### 2.2 Hooks 的执行权限

在 Unix/Linux/macOS 系统上，hook 脚本必须具有执行权限：

```bash
chmod +x .git/hooks/pre-commit
```

### 2.3 Hooks 的返回值

Hook 脚本的退出状态码决定了 Git 操作的执行：

- **退出码 0**：Hook 执行成功，Git 操作继续
- **非零退出码**：Hook 执行失败，Git 操作被中止

```bash
#!/bin/bash
if [ 条件不满足 ]; then
    echo "错误：不符合提交规范"
    exit 1  # 非零退出码，阻止操作
fi
exit 0  # 成功，允许操作继续
```

### 2.4 支持的脚本语言

Git Hooks 可以使用任何可执行的脚本语言，只需在文件开头指定解释器（shebang）：

```bash
#!/bin/bash          # Bash 脚本
#!/usr/bin/env node  # Node.js 脚本
#!/usr/bin/env python3  # Python 脚本
#!/usr/bin/env ruby  # Ruby 脚本
```

推荐使用 Bash 编写 hooks，因为它无需额外依赖，跨平台兼容性好。

---

## 3. 客户端 Hooks

### 3.1 提交工作流 Hooks

提交工作流中的 hooks 按以下顺序执行：

```
pre-commit → prepare-commit-msg → commit-msg → post-commit
```

#### 3.1.1 pre-commit

**触发时机**：在执行 `git commit` 后、编辑提交信息之前

**参数**：无

**常见用途**：代码格式检查、静态分析、检查调试代码、检查敏感信息

**示例**：

```bash
#!/bin/bash
# .git/hooks/pre-commit

set -e

STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

# 检查调试代码
if echo "$STAGED_FILES" | xargs grep -l -E "console\.log|debugger" 2>/dev/null; then
    echo "错误：发现调试代码，请移除后再提交"
    exit 1
fi

# 检查敏感信息
if echo "$STAGED_FILES" | xargs grep -l -i -E "password\s*=|api_key\s*=" 2>/dev/null; then
    echo "警告：可能包含敏感信息，请确认"
    exit 1
fi

echo "pre-commit 检查通过"
exit 0
```

#### 3.1.2 prepare-commit-msg

**触发时机**：在默认提交信息生成后、编辑器打开之前

**参数**：

- `$1` - 包含提交信息的文件路径
- `$2` - 提交信息的来源（`message`、`template`、`merge`、`squash`、`commit`）
- `$3` - 提交的 SHA-1（仅在 `$2` 为 `commit` 时存在）

**常见用途**：自动添加分支名、插入 Issue 编号

**示例**：

```bash
#!/bin/bash
# .git/hooks/prepare-commit-msg

COMMIT_MSG_FILE=$1
COMMIT_SOURCE=$2

# 跳过合并提交
if [ "$COMMIT_SOURCE" = "merge" ]; then
    exit 0
fi

# 获取当前分支名
BRANCH_NAME=$(git symbolic-ref --short HEAD 2>/dev/null)

# 从分支名提取 Issue 编号 (如: feature/PROJ-123-add-login)
ISSUE_ID=$(echo "$BRANCH_NAME" | grep -oE '[A-Z]+-[0-9]+' | head -1)

if [ -n "$ISSUE_ID" ]; then
    # 在提交信息前添加 Issue 编号
    sed -i.bak "1s/^/[$ISSUE_ID] /" "$COMMIT_MSG_FILE"
fi
```

#### 3.1.3 commit-msg

**触发时机**：在用户输入提交信息后、提交生成之前

**参数**：`$1` - 包含提交信息的临时文件路径

**常见用途**：验证提交信息格式，强制执行 Conventional Commits 规范

**示例**：

```bash
#!/bin/bash
# .git/hooks/commit-msg

COMMIT_MSG_FILE=$1
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")
FIRST_LINE=$(echo "$COMMIT_MSG" | grep -v '^#' | head -1)

# Conventional Commits 格式验证
PATTERN="^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .{1,50}$"

# 允许合并提交
if echo "$FIRST_LINE" | grep -qE "^Merge "; then
    exit 0
fi

if ! echo "$FIRST_LINE" | grep -qE "$PATTERN"; then
    echo "提交信息格式错误！"
    echo "正确格式: <type>(<scope>): <subject>"
    echo "示例: feat(auth): 添加用户登录功能"
    exit 1
fi

exit 0
```

#### 3.1.4 post-commit

**触发时机**：在提交完成后立即执行

**参数**：无

**常见用途**：发送通知、记录统计信息

**示例**：

```bash
#!/bin/bash
# .git/hooks/post-commit

COMMIT_HASH=$(git rev-parse --short HEAD)
COMMIT_MSG=$(git log -1 --pretty=%s)
BRANCH=$(git symbolic-ref --short HEAD)

echo "提交成功: [$BRANCH] $COMMIT_HASH - $COMMIT_MSG"
```

### 3.2 邮件工作流 Hooks

这些 hooks 用于 `git am` 命令（通过邮件应用补丁）：

| Hook            | 触发时机           | 用途             |
| --------------- | ------------------ | ---------------- |
| applypatch-msg  | 应用补丁前         | 验证补丁提交信息 |
| pre-applypatch  | 补丁应用后、提交前 | 检查代码状态     |
| post-applypatch | 补丁提交后         | 通知             |

### 3.3 其他客户端 Hooks

#### 3.3.1 pre-rebase

**触发时机**：执行 `git rebase` 之前

**参数**：`$1` - 上游分支名，`$2` - 要 rebase 的分支名

**示例**：

```bash
#!/bin/bash
# .git/hooks/pre-rebase
# 阻止在受保护分支上执行 rebase

BRANCH=${2:-$(git symbolic-ref --short HEAD)}

if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
    echo "错误：禁止在 $BRANCH 分支上执行 rebase"
    exit 1
fi
```

#### 3.3.2 post-checkout

**触发时机**：`git checkout` 或 `git switch` 成功后

**参数**：`$1` - 前一个 HEAD，`$2` - 新 HEAD，`$3` - 检出类型（1=分支，0=文件）

**示例**：

```bash
#!/bin/bash
# .git/hooks/post-checkout
# 分支切换后自动安装依赖

PREV_HEAD=$1
NEW_HEAD=$2
CHECKOUT_TYPE=$3

# 只处理分支切换
[ "$CHECKOUT_TYPE" != "1" ] && exit 0

# 检查 package.json 是否变化
if git diff --name-only "$PREV_HEAD" "$NEW_HEAD" | grep -q "package.json"; then
    echo "检测到 package.json 变化，更新依赖..."
    npm install
fi
```

#### 3.3.3 post-merge

**触发时机**：`git merge` 或 `git pull` 成功后

**参数**：`$1` - 是否为 squash 合并（1=是，0=否）

#### 3.3.4 pre-push

**触发时机**：`git push` 执行后、数据传输前

**参数**：`$1` - 远程仓库名，`$2` - 远程仓库 URL

**标准输入**：每行格式为 `<local-ref> <local-sha> <remote-ref> <remote-sha>`

**示例**：

```bash
#!/bin/bash
# .git/hooks/pre-push

REMOTE=$1

while read LOCAL_REF LOCAL_SHA REMOTE_REF REMOTE_SHA; do
    BRANCH=$(echo "$REMOTE_REF" | sed 's|refs/heads/||')

    # 阻止直接推送到 main
    if [ "$BRANCH" = "main" ]; then
        echo "错误：禁止直接推送到 main 分支，请使用 Pull Request"
        exit 1
    fi
done

# 推送前运行测试
npm test || exit 1

echo "pre-push 检查通过"
```

---

## 4. 服务端 Hooks

服务端 Hooks 在 Git 服务器上运行，用于执行更严格的策略控制。

### 4.1 pre-receive

**触发时机**：服务器收到 push 请求后、更新引用之前

**标准输入**：每行格式为 `<old-sha> <new-sha> <ref-name>`

**示例**：

```bash
#!/bin/bash
# hooks/pre-receive

ZERO_SHA="0000000000000000000000000000000000000000"

while read OLD_SHA NEW_SHA REF_NAME; do
    BRANCH=$(echo "$REF_NAME" | sed 's|refs/heads/||')

    # 阻止删除受保护分支
    if [ "$NEW_SHA" = "$ZERO_SHA" ] && [ "$BRANCH" = "main" ]; then
        echo "错误：禁止删除 main 分支"
        exit 1
    fi

    # 阻止强制推送到 main
    if [ "$BRANCH" = "main" ] && [ "$OLD_SHA" != "$ZERO_SHA" ]; then
        MERGE_BASE=$(git merge-base "$OLD_SHA" "$NEW_SHA" 2>/dev/null)
        if [ "$MERGE_BASE" != "$OLD_SHA" ]; then
            echo "错误：禁止对 main 执行强制推送"
            exit 1
        fi
    fi
done

exit 0
```

### 4.2 update

**触发时机**：服务器更新每个引用之前（每个分支/标签调用一次）

**参数**：`$1` - 引用名，`$2` - 旧 SHA，`$3` - 新 SHA

**与 pre-receive 的区别**：`update` 按引用逐个调用，可以单独拒绝某些引用的更新。

### 4.3 post-receive

**触发时机**：所有引用更新完成后

**标准输入**：与 pre-receive 相同

**常见用途**：触发 CI/CD、发送通知、自动部署

**示例**：

```bash
#!/bin/bash
# hooks/post-receive

while read OLD_SHA NEW_SHA REF_NAME; do
    BRANCH=$(echo "$REF_NAME" | sed 's|refs/heads/||')

    # 跳过删除操作
    [ "$NEW_SHA" = "0000000000000000000000000000000000000000" ] && continue

    # 触发 CI
    curl -X POST "https://ci.example.com/trigger?branch=$BRANCH"

    # main 分支自动部署
    if [ "$BRANCH" = "main" ]; then
        /path/to/deploy.sh &
    fi
done
```

### 4.4 post-update

**触发时机**：所有引用更新后

**参数**：更新的引用名列表

**常见用途**：运行 `git update-server-info`

---

## 5. 实用配置示例

### 5.1 完整的提交前检查流程

```bash
#!/bin/bash
# .git/hooks/pre-commit

set -e

STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)
[ -z "$STAGED_FILES" ] && exit 0

echo "开始提交前检查..."

# 1. 检查敏感信息
SENSITIVE_PATTERNS="password\s*=|api_key\s*=|secret\s*="
if echo "$STAGED_FILES" | xargs grep -l -i -E "$SENSITIVE_PATTERNS" 2>/dev/null; then
    echo "错误：可能包含敏感信息"
    exit 1
fi

# 2. 检查调试代码
DEBUG_PATTERNS="console\.log|debugger|pdb\.set_trace"
if echo "$STAGED_FILES" | xargs grep -l -E "$DEBUG_PATTERNS" 2>/dev/null; then
    echo "警告：发现调试代码"
    exit 1
fi

# 3. 检查文件大小 (5MB)
for file in $STAGED_FILES; do
    if [ -f "$file" ]; then
        size=$(wc -c < "$file")
        if [ $size -gt 5242880 ]; then
            echo "错误：文件 $file 超过 5MB"
            exit 1
        fi
    fi
done

# 4. 运行 linter (如果存在)
if [ -f "node_modules/.bin/eslint" ]; then
    JS_FILES=$(echo "$STAGED_FILES" | grep -E '\.(js|ts)$' || true)
    [ -n "$JS_FILES" ] && echo "$JS_FILES" | xargs npx eslint
fi

echo "所有检查通过"
```

### 5.2 团队 Hooks 共享方案

**目录结构**：

```
project/
├── .githooks/
│   ├── pre-commit
│   ├── commit-msg
│   └── pre-push
├── scripts/
│   └── setup-hooks.sh
└── package.json
```

**setup-hooks.sh**：

```bash
#!/bin/bash
git config core.hooksPath .githooks
chmod +x .githooks/*
echo "Git Hooks 配置完成"
```

**package.json 集成**：

```json
{
  "scripts": {
    "prepare": "bash scripts/setup-hooks.sh"
  }
}
```

---

## 6. 最佳实践

### 6.1 编写 Hooks 的原则

1. **保持简洁**：每个 hook 只做一件事
2. **快速执行**：长时间任务应放到 CI
3. **提供清晰反馈**：错误信息要具体明确
4. **可配置**：允许通过环境变量自定义行为
5. **幂等性**：hook 可以安全地重复执行

### 6.2 性能优化建议

```bash
# 1. 只检查已修改的文件
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

# 2. 使用缓存避免重复检查
CACHE_DIR=".git/hook-cache"
for file in $STAGED_FILES; do
    HASH=$(git hash-object "$file")
    [ -f "$CACHE_DIR/$HASH" ] && continue
    # 执行检查...
    touch "$CACHE_DIR/$HASH"
done

# 3. 提前退出
set -e
```

### 6.3 调试技巧

```bash
# 启用调试模式
[ "${DEBUG:-0}" = "1" ] && set -x

# 手动测试 hook
.git/hooks/pre-commit

# 查看 Git 内部调用
GIT_TRACE=1 git commit -m "test"
```

---

## 7. 常见问题解答 (FAQ)

**Q1: 如何跳过 Git Hooks？**

```bash
git commit --no-verify -m "紧急修复"
git push --no-verify
```

**Q2: Hooks 没有执行怎么办？**

```bash
# 检查执行权限
chmod +x .git/hooks/pre-commit

# 检查 hooks 目录配置
git config core.hooksPath

# 检查脚本语法
bash -n .git/hooks/pre-commit
```

**Q3: 如何在团队中共享 Hooks？**

```bash
# 方法 1: 使用 core.hooksPath
git config core.hooksPath .githooks

# 方法 2: 使用 Husky (Node.js 项目)
npm install husky --save-dev
```

**Q4: 如何获取当前分支名？**

```bash
git symbolic-ref --short HEAD
```

**Q5: 如何检测合并提交？**

```bash
if [ -f .git/MERGE_HEAD ]; then
    echo "这是合并提交"
fi
```

---

## 8. 工具推荐

### Husky

Node.js 项目最流行的 Git Hooks 管理工具。

```bash
npm install husky --save-dev
npx husky init
```

### lint-staged

专门对暂存文件运行 linters。

```json
{
  "lint-staged": {
    "*.js": ["eslint --fix", "prettier --write"]
  }
}
```

### lefthook

快速的多语言 Git Hooks 管理器。

```yaml
# lefthook.yml
pre-commit:
  commands:
    lint:
      run: npm run lint
```

---

## 9. 总结

Git Hooks 是 Git 工作流自动化的强大工具。通过合理使用 Hooks，可以：

- 保证代码质量，减少低级错误
- 统一团队规范，提高协作效率
- 自动化重复任务，节省时间
- 增强安全性，防止敏感信息泄露

### Hooks 速查表

#### 客户端 Hooks

| Hook               | 触发时机    | 可阻止 | 常见用途         |
| ------------------ | ----------- | ------ | ---------------- |
| pre-commit         | commit 前   | ✅     | 代码检查         |
| prepare-commit-msg | 生成消息后  | ✅     | 自动填充提交信息 |
| commit-msg         | 输入消息后  | ✅     | 验证提交信息     |
| post-commit        | commit 后   | ❌     | 通知             |
| pre-rebase         | rebase 前   | ✅     | 保护分支         |
| post-checkout      | checkout 后 | ❌     | 安装依赖         |
| post-merge         | merge 后    | ❌     | 更新依赖         |
| pre-push           | push 前     | ✅     | 运行测试         |

#### 服务端 Hooks

| Hook         | 触发时机     | 可阻止 | 常见用途     |
| ------------ | ------------ | ------ | ------------ |
| pre-receive  | 接收 push 前 | ✅     | 权限验证     |
| update       | 更新引用前   | ✅     | 分支权限控制 |
| post-receive | 接收 push 后 | ❌     | CI/CD、部署  |
| post-update  | 更新后       | ❌     | 更新服务信息 |
