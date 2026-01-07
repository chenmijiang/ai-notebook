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
      - [3.1.1 pre-commit](#311-pre-commit)
      - [3.1.2 prepare-commit-msg](#312-prepare-commit-msg)
      - [3.1.3 commit-msg](#313-commit-msg)
      - [3.1.4 pre-merge-commit](#314-pre-merge-commit)
      - [3.1.5 post-commit](#315-post-commit)
    - [3.2 邮件工作流 Hooks](#32-邮件工作流-hooks)
      - [3.2.1 applypatch-msg](#321-applypatch-msg)
      - [3.2.2 pre-applypatch](#322-pre-applypatch)
      - [3.2.3 post-applypatch](#323-post-applypatch)
    - [3.3 其他客户端 Hooks](#33-其他客户端-hooks)
      - [3.3.1 pre-rebase](#331-pre-rebase)
      - [3.3.2 post-checkout](#332-post-checkout)
      - [3.3.3 post-merge](#333-post-merge)
      - [3.3.4 pre-push](#334-pre-push)
      - [3.3.5 pre-auto-gc](#335-pre-auto-gc)
      - [3.3.6 post-rewrite](#336-post-rewrite)
      - [3.3.7 fsmonitor-watchman](#337-fsmonitor-watchman)
  - [4. 服务端 Hooks](#4-服务端-hooks)
    - [4.1 pre-receive](#41-pre-receive)
    - [4.2 update](#42-update)
    - [4.3 post-receive](#43-post-receive)
    - [4.4 post-update](#44-post-update)
    - [4.5 push-to-checkout](#45-push-to-checkout)
    - [4.6 pre-push (服务端视角)](#46-pre-push-服务端视角)
  - [5. 实用配置示例](#5-实用配置示例)
    - [5.1 完整的提交前检查流程](#51-完整的提交前检查流程)
    - [5.2 自动化版本号管理](#52-自动化版本号管理)
    - [5.3 团队 Hooks 共享方案](#53-团队-hooks-共享方案)
  - [6. 最佳实践](#6-最佳实践)
    - [6.1 编写 Hooks 的原则](#61-编写-hooks-的原则)
    - [6.2 性能优化建议](#62-性能优化建议)
    - [6.3 安全注意事项](#63-安全注意事项)
    - [6.4 调试技巧](#64-调试技巧)
  - [7. 常见问题解答 (FAQ)](#7-常见问题解答-faq)
    - [Q1: 如何跳过 Git Hooks？](#q1-如何跳过-git-hooks)
    - [Q2: Hooks 没有执行怎么办？](#q2-hooks-没有执行怎么办)
    - [Q3: 如何在团队中共享 Hooks？](#q3-如何在团队中共享-hooks)
    - [Q4: Hooks 中如何获取更多 Git 信息？](#q4-hooks-中如何获取更多-git-信息)
    - [Q5: 如何在 Hooks 中处理合并提交？](#q5-如何在-hooks-中处理合并提交)
    - [Q6: Windows 环境下如何使用 Hooks？](#q6-windows-环境下如何使用-hooks)
    - [Q7: 如何测试 Hooks？](#q7-如何测试-hooks)
  - [8. 工具推荐](#8-工具推荐)
    - [8.1 Husky](#81-husky)
    - [8.2 lint-staged](#82-lint-staged)
    - [8.3 lefthook](#83-lefthook)
  - [9. 总结](#9-总结)
    - [Hooks 速查表](#hooks-速查表)
      - [客户端 Hooks](#客户端-hooks)
      - [服务端 Hooks](#服务端-hooks)

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

| 场景 | 适用的 Hook | 说明 |
|------|------------|------|
| 代码格式化 | pre-commit | 自动格式化代码或检查格式 |
| 代码检查 | pre-commit | 运行 ESLint、TypeScript 等静态分析工具 |
| 提交信息规范 | commit-msg | 验证提交信息格式 |
| 单元测试 | pre-push | 推送前运行测试 |
| 持续集成 | post-receive | 推送后触发 CI 流程 |
| 自动部署 | post-receive | 代码推送后自动部署 |
| 权限控制 | update | 控制谁可以推送到哪些分支 |

---

## 2. 基础知识

### 2.1 Hooks 存放位置

Git Hooks 默认存储在仓库的 `.git/hooks` 目录下。新创建的仓库会包含一些示例文件：

```bash
$ ls .git/hooks/
applypatch-msg.sample      post-update.sample         pre-push.sample
commit-msg.sample          pre-applypatch.sample      pre-rebase.sample
fsmonitor-watchman.sample  pre-commit.sample          prepare-commit-msg.sample
post-commit.sample         pre-merge-commit.sample    update.sample
```

这些 `.sample` 文件是示例，不会被执行。要启用某个 hook，需要：
1. 去掉 `.sample` 后缀
2. 确保文件有执行权限

也可以通过配置自定义 hooks 目录：

```bash
# 设置自定义 hooks 目录
git config core.hooksPath .githooks

# 全局设置
git config --global core.hooksPath ~/.githooks
```

### 2.2 Hooks 的执行权限

在 Unix/Linux/macOS 系统上，hook 脚本必须具有执行权限：

```bash
# 添加执行权限
chmod +x .git/hooks/pre-commit

# 批量添加执行权限
chmod +x .git/hooks/*
```

### 2.3 Hooks 的返回值

Hook 脚本的退出状态码决定了 Git 操作的执行：

- **退出码 0**：Hook 执行成功，Git 操作继续
- **非零退出码**：Hook 执行失败，Git 操作被中止（对于可中止的 hooks）

```bash
#!/bin/bash
# 示例：检查失败时阻止提交
if [ 条件不满足 ]; then
    echo "错误：不符合提交规范"
    exit 1  # 非零退出码，阻止提交
fi
exit 0  # 成功，允许提交
```

### 2.4 支持的脚本语言

Git Hooks 可以使用任何可执行的脚本语言，只需在文件开头指定解释器：

```bash
#!/bin/bash
# Bash 脚本
```

```typescript
#!/usr/bin/env npx ts-node
// TypeScript 脚本（需要安装 ts-node）
```

```javascript
#!/usr/bin/env node
// Node.js 脚本
```

**TypeScript Hook 配置说明**：

使用 TypeScript 编写 Git Hooks 需要先安装依赖：

```bash
npm install -D typescript ts-node @types/node
```

或者使用更快的 tsx 运行器：

```bash
npm install -D tsx
```

然后在 hook 文件中使用：

```typescript
#!/usr/bin/env npx tsx
// 使用 tsx 运行（更快）
```

---

## 3. 客户端 Hooks

### 3.1 提交工作流 Hooks

提交工作流中的 hooks 按以下顺序执行：

**普通提交 (`git commit`)**：
```
pre-commit → prepare-commit-msg → commit-msg → post-commit
```

**合并提交 (`git merge`)**：
```
pre-merge-commit → prepare-commit-msg → commit-msg → post-commit
```

#### 3.1.1 pre-commit

**触发时机**：在执行 `git commit` 后、编辑提交信息之前

**参数**：无

**常见用途**：
- 代码格式检查和自动格式化
- 运行代码静态分析（ESLint 等）
- 检查是否有调试代码残留
- 检查敏感信息泄露

**实际代码示例**：

```bash
#!/bin/bash
# .git/hooks/pre-commit
# 综合性的提交前检查脚本

set -e

echo "🔍 运行提交前检查..."

# 获取暂存的文件列表
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

# 1. 检查是否有调试代码残留
echo "检查调试代码..."
DEBUG_PATTERNS="console\.log|debugger|import pdb|pdb\.set_trace|print\(.*DEBUG"
if echo "$STAGED_FILES" | xargs grep -l -E "$DEBUG_PATTERNS" 2>/dev/null; then
    echo "❌ 错误：发现调试代码，请移除后再提交"
    exit 1
fi

# 2. 检查敏感信息
echo "检查敏感信息..."
SENSITIVE_PATTERNS="password\s*=|api_key\s*=|secret\s*=|AWS_SECRET"
if echo "$STAGED_FILES" | xargs grep -l -i -E "$SENSITIVE_PATTERNS" 2>/dev/null; then
    echo "⚠️  警告：可能包含敏感信息，请确认"
    read -p "确认继续提交？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 3. 运行 ESLint (JavaScript/TypeScript 项目)
JS_FILES=$(echo "$STAGED_FILES" | grep -E '\.(js|jsx|ts|tsx)$' || true)
if [ -n "$JS_FILES" ] && [ -f "node_modules/.bin/eslint" ]; then
    echo "运行 ESLint..."
    echo "$JS_FILES" | xargs node_modules/.bin/eslint --fix
    # 将修复后的文件重新添加到暂存区
    echo "$JS_FILES" | xargs git add
fi

# 4. 运行 Python 代码检查
PY_FILES=$(echo "$STAGED_FILES" | grep '\.py$' || true)
if [ -n "$PY_FILES" ]; then
    if command -v black &> /dev/null; then
        echo "运行 Black 格式化..."
        echo "$PY_FILES" | xargs black --check --quiet || {
            echo "运行 Black 自动格式化..."
            echo "$PY_FILES" | xargs black
            echo "$PY_FILES" | xargs git add
        }
    fi

    if command -v flake8 &> /dev/null; then
        echo "运行 Flake8..."
        echo "$PY_FILES" | xargs flake8 || exit 1
    fi
fi

# 5. 检查文件大小
echo "检查文件大小..."
MAX_SIZE=5242880  # 5MB
for file in $STAGED_FILES; do
    if [ -f "$file" ]; then
        size=$(wc -c < "$file")
        if [ $size -gt $MAX_SIZE ]; then
            echo "❌ 错误：文件 $file 超过 5MB 限制"
            exit 1
        fi
    fi
done

echo "✅ 所有检查通过"
exit 0
```

**TypeScript 版本示例**：

```typescript
#!/usr/bin/env npx ts-node
// .git/hooks/pre-commit
// TypeScript 版本的提交前检查

import { execSync } from 'child_process';
import * as fs from 'fs';

interface CheckResult {
  name: string;
  passed: boolean;
}

function getStagedFiles(): string[] {
  const result = execSync('git diff --cached --name-only --diff-filter=ACM', {
    encoding: 'utf-8',
  });
  return result.trim().split('\n').filter(Boolean);
}

function checkDebugStatements(files: string[]): boolean {
  const debugPatterns = [
    /console\.log/,
    /debugger/,
    /\.only\(/,  // test.only, describe.only
  ];

  for (const file of files) {
    try {
      const content = fs.readFileSync(file, 'utf-8');
      for (const pattern of debugPatterns) {
        if (pattern.test(content)) {
          console.log(`❌ 发现调试代码: ${file}`);
          return false;
        }
      }
    } catch {
      continue;
    }
  }
  return true;
}

function checkFileSize(files: string[], maxSize = 5 * 1024 * 1024): boolean {
  for (const file of files) {
    if (fs.existsSync(file)) {
      const stats = fs.statSync(file);
      if (stats.size > maxSize) {
        console.log(`❌ 文件过大: ${file} (${(stats.size / 1024 / 1024).toFixed(2)}MB)`);
        return false;
      }
    }
  }
  return true;
}

function runLinter(files: string[]): boolean {
  const tsFiles = files.filter(f => /\.(ts|tsx|js|jsx)$/.test(f));
  if (tsFiles.length === 0) return true;

  try {
    execSync(`npx eslint ${tsFiles.join(' ')}`, { stdio: 'pipe' });
    return true;
  } catch (error) {
    console.log('❌ ESLint 检查失败');
    return false;
  }
}

function main(): number {
  console.log('🔍 运行提交前检查...');

  const files = getStagedFiles();
  if (files.length === 0) {
    console.log('没有暂存的文件');
    return 0;
  }

  const checks: Array<{ name: string; fn: (files: string[]) => boolean }> = [
    { name: '调试代码检查', fn: checkDebugStatements },
    { name: '文件大小检查', fn: checkFileSize },
    { name: '代码规范检查', fn: runLinter },
  ];

  for (const { name, fn } of checks) {
    console.log(`  检查: ${name}...`);
    if (!fn(files)) {
      return 1;
    }
  }

  console.log('✅ 所有检查通过');
  return 0;
}

process.exit(main());
```

#### 3.1.2 prepare-commit-msg

**触发时机**：在默认提交信息生成后、编辑器打开之前

**参数**：
1. `$1` - 包含提交信息的文件路径
2. `$2` - 提交信息的来源（`message`、`template`、`merge`、`squash`、`commit`）
3. `$3` - 提交的 SHA-1（仅在 `$2` 为 `commit` 时存在）

**常见用途**：
- 自动添加分支名到提交信息
- 插入 Issue 编号
- 生成提交信息模板

**实际代码示例**：

```bash
#!/bin/bash
# .git/hooks/prepare-commit-msg
# 自动在提交信息中添加分支名和 Issue 编号

COMMIT_MSG_FILE=$1
COMMIT_SOURCE=$2
SHA1=$3

# 如果是合并提交或已有提交信息，跳过
if [ "$COMMIT_SOURCE" = "merge" ] || [ "$COMMIT_SOURCE" = "commit" ]; then
    exit 0
fi

# 获取当前分支名
BRANCH_NAME=$(git symbolic-ref --short HEAD 2>/dev/null)

# 从分支名中提取 Issue 编号 (例如: feature/PROJ-123-add-login)
ISSUE_ID=$(echo "$BRANCH_NAME" | grep -oE '[A-Z]+-[0-9]+' | head -1)

# 读取当前提交信息
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# 如果已经包含 Issue 编号，跳过
if echo "$COMMIT_MSG" | grep -q "$ISSUE_ID"; then
    exit 0
fi

# 根据分支类型添加前缀
case "$BRANCH_NAME" in
    feature/*)
        PREFIX="feat"
        ;;
    bugfix/* | fix/*)
        PREFIX="fix"
        ;;
    hotfix/*)
        PREFIX="hotfix"
        ;;
    refactor/*)
        PREFIX="refactor"
        ;;
    docs/*)
        PREFIX="docs"
        ;;
    *)
        PREFIX=""
        ;;
esac

# 构建新的提交信息
if [ -n "$ISSUE_ID" ]; then
    if [ -n "$PREFIX" ]; then
        NEW_MSG="$PREFIX: [$ISSUE_ID] $COMMIT_MSG"
    else
        NEW_MSG="[$ISSUE_ID] $COMMIT_MSG"
    fi
else
    if [ -n "$PREFIX" ]; then
        NEW_MSG="$PREFIX: $COMMIT_MSG"
    else
        NEW_MSG="$COMMIT_MSG"
    fi
fi

# 写入新的提交信息
echo "$NEW_MSG" > "$COMMIT_MSG_FILE"

# 添加提交信息模板（如果是空提交信息）
if [ -z "$(cat "$COMMIT_MSG_FILE" | grep -v '^#')" ]; then
    cat > "$COMMIT_MSG_FILE" << EOF
# 提交类型: feat|fix|docs|style|refactor|test|chore
# 格式: <type>: [ISSUE-ID] <subject>
#
# 示例:
#   feat: [PROJ-123] 添加用户登录功能
#   fix: [PROJ-456] 修复密码验证问题
#
# 分支: $BRANCH_NAME
# Issue: ${ISSUE_ID:-无}
EOF
fi
```

**高级示例 - 自动生成 Conventional Commits**：

```typescript
#!/usr/bin/env npx ts-node
// .git/hooks/prepare-commit-msg
// 智能提交信息生成器

import { execSync } from 'child_process';
import * as fs from 'fs';

function getBranchName(): string {
  return execSync('git symbolic-ref --short HEAD', { encoding: 'utf-8' }).trim();
}

function getStagedFiles(): string[] {
  const result = execSync('git diff --cached --name-only', { encoding: 'utf-8' });
  return result.trim().split('\n').filter(Boolean);
}

type CommitType = 'feat' | 'fix' | 'docs' | 'style' | 'refactor' | 'test' | 'chore' | 'ci' | 'perf';

function detectCommitType(branchName: string, stagedFiles: string[]): CommitType {
  // 从分支名检测
  const branchPatterns: Array<{ pattern: RegExp; type: CommitType }> = [
    { pattern: /^feat(ure)?\//, type: 'feat' },
    { pattern: /^fix\//, type: 'fix' },
    { pattern: /^bug(fix)?\//, type: 'fix' },
    { pattern: /^hot(fix)?\//, type: 'fix' },
    { pattern: /^docs?\//, type: 'docs' },
    { pattern: /^style\//, type: 'style' },
    { pattern: /^refactor\//, type: 'refactor' },
    { pattern: /^test\//, type: 'test' },
    { pattern: /^chore\//, type: 'chore' },
    { pattern: /^ci\//, type: 'ci' },
    { pattern: /^perf\//, type: 'perf' },
  ];

  for (const { pattern, type } of branchPatterns) {
    if (pattern.test(branchName)) {
      return type;
    }
  }

  // 从文件类型检测
  const filePatterns: Array<{ pattern: RegExp; type: CommitType }> = [
    { pattern: /\.(md|rst|txt)$/, type: 'docs' },
    { pattern: /test.*\.(js|ts|tsx)$/, type: 'test' },
    { pattern: /\.(css|scss|less)$/, type: 'style' },
    { pattern: /(Dockerfile|\.yml|\.yaml)$/, type: 'ci' },
  ];

  for (const file of stagedFiles) {
    for (const { pattern, type } of filePatterns) {
      if (pattern.test(file)) {
        return type;
      }
    }
  }

  return 'chore';
}

function main(): void {
  const args = process.argv.slice(2);
  if (args.length < 1) {
    process.exit(0);
  }

  const commitMsgFile = args[0];
  const commitSource = args[1] || null;

  // 跳过合并提交
  if (commitSource === 'merge' || commitSource === 'squash') {
    process.exit(0);
  }

  const branchName = getBranchName();
  const stagedFiles = getStagedFiles();

  // 提取 Issue ID
  const issueMatch = branchName.match(/([A-Z]+-\d+)/);
  const issueId = issueMatch ? issueMatch[1] : null;

  // 检测提交类型
  const commitType = detectCommitType(branchName, stagedFiles);

  // 读取现有提交信息
  const currentMsg = fs.readFileSync(commitMsgFile, 'utf-8');

  // 如果已经有非注释内容，不修改
  const nonCommentLines = currentMsg.split('\n').filter(l => !l.startsWith('#'));
  if (nonCommentLines.some(line => line.trim())) {
    process.exit(0);
  }

  // 生成新的提交信息模板
  const template = `# ${commitType}: <简短描述>
#
# [可选] 详细说明:
# - 为什么需要这个改动?
# - 如何解决的?
# - 有什么副作用?
#
# 分支: ${branchName}
# Issue: ${issueId || '无'}
# 类型: ${commitType}
#
# 可用的提交类型:
#   feat:     新功能
#   fix:      Bug 修复
#   docs:     文档更新
#   style:    代码格式 (不影响代码运行)
#   refactor: 重构 (既不是新功能也不是修复)
#   test:     添加测试
#   chore:    构建过程或辅助工具的变动
#   perf:     性能优化
#   ci:       CI 配置修改
`;

  fs.writeFileSync(commitMsgFile, template);
}

main();
```

#### 3.1.3 commit-msg

**触发时机**：在用户输入提交信息后、提交生成之前

**参数**：
- `$1` - 包含提交信息的临时文件路径

**常见用途**：
- 验证提交信息格式
- 强制执行 Conventional Commits 规范
- 拒绝不符合规范的提交信息

**实际代码示例**：

```bash
#!/bin/bash
# .git/hooks/commit-msg
# 验证 Conventional Commits 格式

COMMIT_MSG_FILE=$1
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# 忽略注释行，获取第一行非注释内容
FIRST_LINE=$(echo "$COMMIT_MSG" | grep -v '^#' | head -1)

# Conventional Commits 正则表达式
# 格式: type(scope)?: description
PATTERN="^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\(.+\))?: .{1,100}$"

# 允许合并提交
MERGE_PATTERN="^Merge (branch|pull request|remote-tracking branch)"

# 允许 Revert 提交
REVERT_PATTERN="^Revert \".+\"$"

if echo "$FIRST_LINE" | grep -qE "$MERGE_PATTERN"; then
    exit 0
fi

if echo "$FIRST_LINE" | grep -qE "$REVERT_PATTERN"; then
    exit 0
fi

if ! echo "$FIRST_LINE" | grep -qE "$PATTERN"; then
    echo "❌ 提交信息格式错误！"
    echo ""
    echo "当前提交信息: $FIRST_LINE"
    echo ""
    echo "正确格式: <type>(<scope>): <subject>"
    echo ""
    echo "可用的 type:"
    echo "  feat:     新功能"
    echo "  fix:      Bug 修复"
    echo "  docs:     文档更新"
    echo "  style:    代码格式（不影响代码运行）"
    echo "  refactor: 重构（既不是新功能也不是修复）"
    echo "  test:     添加测试"
    echo "  chore:    构建过程或辅助工具的变动"
    echo "  perf:     性能优化"
    echo "  ci:       CI 配置修改"
    echo "  build:    构建系统或外部依赖变更"
    echo "  revert:   回滚提交"
    echo ""
    echo "示例:"
    echo "  feat(auth): 添加用户登录功能"
    echo "  fix: 修复首页加载缓慢问题"
    echo "  docs(readme): 更新安装说明"
    exit 1
fi

# 检查提交信息长度
if [ ${#FIRST_LINE} -gt 100 ]; then
    echo "❌ 提交信息第一行超过 100 个字符"
    echo "当前长度: ${#FIRST_LINE}"
    exit 1
fi

# 检查是否以句号结尾（不应该）
if echo "$FIRST_LINE" | grep -qE '\.$'; then
    echo "⚠️  警告: 提交信息不应以句号结尾"
    # 这里只是警告，不阻止提交
fi

echo "✅ 提交信息格式正确"
exit 0
```

**高级示例 - 支持多语言和 Emoji**：

```typescript
#!/usr/bin/env npx ts-node
// .git/hooks/commit-msg
// 高级提交信息验证器

import * as fs from 'fs';

const COMMIT_TYPES: Record<string, string> = {
  feat: '新功能',
  fix: 'Bug 修复',
  docs: '文档更新',
  style: '代码格式',
  refactor: '重构',
  test: '测试',
  chore: '杂项',
  perf: '性能优化',
  ci: 'CI/CD',
  build: '构建',
  revert: '回滚',
};

// 支持的 Emoji 前缀
const EMOJI_TYPES: Record<string, string> = {
  ':sparkles:': 'feat',
  ':bug:': 'fix',
  ':memo:': 'docs',
  ':lipstick:': 'style',
  ':recycle:': 'refactor',
  ':white_check_mark:': 'test',
  ':wrench:': 'chore',
  ':zap:': 'perf',
  ':construction_worker:': 'ci',
  ':hammer:': 'build',
  ':rewind:': 'revert',
};

interface ValidationResult {
  valid: boolean;
  error?: string;
}

function validateCommitMessage(message: string): ValidationResult {
  const lines = message.trim().split('\n');
  const title = lines[0].trim();

  // 跳过空消息
  if (!title) {
    return { valid: false, error: '提交信息不能为空' };
  }

  // 允许合并提交
  if (title.startsWith('Merge ') || title.startsWith('Revert "')) {
    return { valid: true };
  }

  // 标准 Conventional Commits 格式
  const typePattern = Object.keys(COMMIT_TYPES).join('|');
  const pattern = new RegExp(`^(${typePattern})(\\(.+\\))?(!)?: .{1,100}$`);

  if (pattern.test(title)) {
    return { valid: true };
  }

  // 检查 Emoji 格式
  const emojiPattern = Object.keys(EMOJI_TYPES)
    .map(e => e.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'))
    .join('|');
  const emojiRegex = new RegExp(`^(${emojiPattern}) .{1,100}$`);

  if (emojiRegex.test(title)) {
    return { valid: true };
  }

  return { valid: false, error: `格式错误: ${title}` };
}

function checkBodyFormat(message: string): ValidationResult {
  const lines = message.trim().split('\n');

  if (lines.length < 2) {
    return { valid: true };
  }

  // 第二行应该是空行
  if (lines.length > 1 && lines[1].trim()) {
    return { valid: false, error: '标题和正文之间应该有一个空行' };
  }

  // 检查正文行长度
  for (let i = 2; i < lines.length; i++) {
    if (lines[i].length > 72) {
      return { valid: false, error: `第 ${i + 1} 行超过 72 个字符` };
    }
  }

  return { valid: true };
}

function main(): number {
  const args = process.argv.slice(2);
  if (args.length < 1) {
    return 1;
  }

  const commitMsgFile = args[0];
  const message = fs.readFileSync(commitMsgFile, 'utf-8');

  // 移除注释行
  const cleanMessage = message
    .split('\n')
    .filter(l => !l.startsWith('#'))
    .join('\n');

  // 验证标题
  const titleResult = validateCommitMessage(cleanMessage);
  if (!titleResult.valid) {
    console.log(`❌ ${titleResult.error}`);
    console.log('\n正确格式: <type>(<scope>): <description>');
    console.log('\n可用类型:');
    for (const [type, desc] of Object.entries(COMMIT_TYPES)) {
      console.log(`  ${type.padEnd(10)} - ${desc}`);
    }
    return 1;
  }

  // 验证正文
  const bodyResult = checkBodyFormat(cleanMessage);
  if (!bodyResult.valid) {
    console.log(`⚠️  警告: ${bodyResult.error}`);
  }

  console.log('✅ 提交信息验证通过');
  return 0;
}

process.exit(main());
```

#### 3.1.4 pre-merge-commit

**触发时机**：`git merge` 成功执行后、创建合并提交之前

**参数**：无

**常见用途**：
- 在合并提交前运行代码检查
- 验证合并后的代码状态
- 运行测试确保合并不会破坏构建

**注意**：此 hook 可以通过 `git merge --no-verify` 跳过。

**实际代码示例**：

```bash
#!/bin/bash
# .git/hooks/pre-merge-commit
# 合并提交前的验证

echo "🔀 运行合并提交前检查..."

# 运行测试
if [ -f "package.json" ] && grep -q '"test"' package.json; then
    echo "运行测试..."
    npm test || {
        echo "❌ 测试失败，合并提交已取消"
        exit 1
    }
fi

# 运行类型检查
if [ -f "tsconfig.json" ]; then
    echo "运行 TypeScript 类型检查..."
    npx tsc --noEmit || {
        echo "❌ 类型检查失败，合并提交已取消"
        exit 1
    }
fi

echo "✅ 合并提交检查通过"
exit 0
```

#### 3.1.5 post-commit

**触发时机**：在提交完成后立即执行

**参数**：无

**常见用途**：
- 发送通知
- 更新项目统计
- 触发本地构建
- 记录提交日志

**实际代码示例**：

```bash
#!/bin/bash
# .git/hooks/post-commit
# 提交后通知和统计

# 获取提交信息
COMMIT_HASH=$(git rev-parse HEAD)
COMMIT_MSG=$(git log -1 --pretty=%B)
AUTHOR=$(git log -1 --pretty=%an)
DATE=$(git log -1 --pretty=%cd --date=short)
BRANCH=$(git symbolic-ref --short HEAD)

# 统计本次提交
FILES_CHANGED=$(git diff-tree --no-commit-id --name-only -r HEAD | wc -l)
INSERTIONS=$(git diff --stat HEAD~1 HEAD 2>/dev/null | tail -1 | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo 0)
DELETIONS=$(git diff --stat HEAD~1 HEAD 2>/dev/null | tail -1 | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' || echo 0)

echo ""
echo "📝 提交成功！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "提交: ${COMMIT_HASH:0:8}"
echo "分支: $BRANCH"
echo "作者: $AUTHOR"
echo "日期: $DATE"
echo "文件: $FILES_CHANGED 个变更"
echo "统计: +$INSERTIONS / -$DELETIONS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 更新本地提交统计
STATS_FILE=".git/commit_stats.txt"
echo "$DATE,$COMMIT_HASH,$FILES_CHANGED,$INSERTIONS,$DELETIONS" >> "$STATS_FILE"

# 可选: 发送桌面通知 (macOS)
if command -v osascript &> /dev/null; then
    osascript -e "display notification \"$COMMIT_MSG\" with title \"Git 提交成功\" subtitle \"$BRANCH\""
fi

# 可选: 发送桌面通知 (Linux)
if command -v notify-send &> /dev/null; then
    notify-send "Git 提交成功" "$COMMIT_MSG"
fi

# 可选: 发送 Slack/Discord 通知
# WEBHOOK_URL="https://hooks.slack.com/services/xxx"
# curl -s -X POST -H 'Content-type: application/json' \
#     --data "{\"text\":\"$AUTHOR 提交了代码: $COMMIT_MSG\"}" \
#     $WEBHOOK_URL

exit 0
```

### 3.2 邮件工作流 Hooks

这些 hooks 主要用于通过邮件应用补丁的工作流程（`git am` 命令）。

#### 3.2.1 applypatch-msg

**触发时机**：`git am` 执行后、应用补丁之前

**参数**：
- `$1` - 包含提交信息的临时文件

**常见用途**：
- 验证补丁的提交信息格式
- 修改或规范化提交信息

```bash
#!/bin/bash
# .git/hooks/applypatch-msg

COMMIT_MSG_FILE=$1

# 复用 commit-msg hook 的逻辑
if [ -x .git/hooks/commit-msg ]; then
    exec .git/hooks/commit-msg "$COMMIT_MSG_FILE"
fi
```

#### 3.2.2 pre-applypatch

**触发时机**：补丁应用后、提交生成之前

**参数**：无

**常见用途**：
- 检查补丁应用后的代码状态
- 运行测试确保补丁不破坏构建

```bash
#!/bin/bash
# .git/hooks/pre-applypatch

echo "运行补丁前检查..."

# 运行测试
if [ -f "package.json" ]; then
    npm test || exit 1
fi

echo "✅ 补丁检查通过"
```

#### 3.2.3 post-applypatch

**触发时机**：补丁应用并提交后

**参数**：无

**常见用途**：
- 通知补丁已应用
- 记录补丁应用历史

```bash
#!/bin/bash
# .git/hooks/post-applypatch

COMMIT=$(git rev-parse HEAD)
echo "✅ 补丁已应用: $COMMIT"
```

### 3.3 其他客户端 Hooks

#### 3.3.1 pre-rebase

**触发时机**：执行 `git rebase` 之前

**参数**：
- `$1` - 上游分支名
- `$2` - 要 rebase 的分支名（如果是当前分支则为空）

**常见用途**：
- 阻止在已发布的分支上执行 rebase
- 保护重要分支
- 强制执行分支策略

**实际代码示例**：

```bash
#!/bin/bash
# .git/hooks/pre-rebase
# 阻止在受保护分支上执行 rebase

UPSTREAM=$1
BRANCH=$2

# 如果没有指定分支，使用当前分支
if [ -z "$BRANCH" ]; then
    BRANCH=$(git symbolic-ref --short HEAD)
fi

# 受保护的分支列表
PROTECTED_BRANCHES="main master develop release"

# 检查是否是受保护分支
for protected in $PROTECTED_BRANCHES; do
    if [ "$BRANCH" = "$protected" ]; then
        echo "❌ 错误：禁止在 $BRANCH 分支上执行 rebase"
        echo "受保护分支: $PROTECTED_BRANCHES"
        exit 1
    fi
done

# 检查分支是否已推送到远程
REMOTE_REF=$(git rev-parse "origin/$BRANCH" 2>/dev/null)
LOCAL_REF=$(git rev-parse "$BRANCH" 2>/dev/null)

if [ -n "$REMOTE_REF" ]; then
    echo "⚠️  警告：分支 $BRANCH 已推送到远程"
    echo "Rebase 将会重写历史，可能导致其他开发者的问题"
    read -p "确定要继续吗？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "✅ 允许 rebase: $BRANCH onto $UPSTREAM"
exit 0
```

#### 3.3.2 post-checkout

**触发时机**：
- `git checkout` 成功后
- `git switch` 成功后
- `git clone` 后（因为 clone 会 checkout）

**参数**：
- `$1` - 前一个 HEAD 的 SHA-1
- `$2` - 新 HEAD 的 SHA-1
- `$3` - 检出类型（`1` = 分支检出，`0` = 文件检出）

**常见用途**：
- 清理编译生成的文件
- 自动安装依赖
- 切换环境配置

**实际代码示例**：

```bash
#!/bin/bash
# .git/hooks/post-checkout
# 自动化分支切换后的操作

PREV_HEAD=$1
NEW_HEAD=$2
CHECKOUT_TYPE=$3

# 只处理分支切换，跳过文件检出
if [ "$CHECKOUT_TYPE" != "1" ]; then
    exit 0
fi

# 如果没有实际切换（相同的 HEAD），跳过
if [ "$PREV_HEAD" = "$NEW_HEAD" ]; then
    exit 0
fi

BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
echo "🔄 切换到分支: $BRANCH"

# 检查 package.json 是否有变化
if git diff --name-only "$PREV_HEAD" "$NEW_HEAD" | grep -q "package.json"; then
    echo "📦 检测到 package.json 变化，更新依赖..."
    if [ -f "package-lock.json" ]; then
        npm ci
    elif [ -f "yarn.lock" ]; then
        yarn install --frozen-lockfile
    elif [ -f "pnpm-lock.yaml" ]; then
        pnpm install --frozen-lockfile
    fi
fi

# 检查 requirements.txt 是否有变化
if git diff --name-only "$PREV_HEAD" "$NEW_HEAD" | grep -q "requirements.txt"; then
    echo "🐍 检测到 requirements.txt 变化，更新 Python 依赖..."
    if [ -d "venv" ]; then
        source venv/bin/activate
        pip install -r requirements.txt
    fi
fi

# 检查 Gemfile 是否有变化
if git diff --name-only "$PREV_HEAD" "$NEW_HEAD" | grep -q "Gemfile"; then
    echo "💎 检测到 Gemfile 变化，更新 Ruby 依赖..."
    bundle install
fi

# 检查数据库迁移文件是否有变化
if git diff --name-only "$PREV_HEAD" "$NEW_HEAD" | grep -qE "migrations?/"; then
    echo "🗄️  检测到数据库迁移变化，提醒运行迁移..."
    echo "⚠️  请运行: npm run migrate 或 python manage.py migrate"
fi

# 检查环境变量模板是否有变化
if git diff --name-only "$PREV_HEAD" "$NEW_HEAD" | grep -q ".env.example"; then
    echo "⚠️  .env.example 有更新，请检查是否需要更新本地 .env 文件"
fi

# 清理编译缓存
if git diff --name-only "$PREV_HEAD" "$NEW_HEAD" | grep -qE '\.(ts|tsx|js|jsx)$'; then
    echo "🧹 清理编译缓存..."
    rm -rf node_modules/.cache .next/cache dist/.cache 2>/dev/null
fi

exit 0
```

#### 3.3.3 post-merge

**触发时机**：`git merge` 或 `git pull` 成功完成后

**参数**：
- `$1` - 是否为 squash 合并（`1` 是，`0` 否）

**常见用途**：
- 自动安装新依赖
- 重建数据库
- 运行迁移脚本

**实际代码示例**：

```bash
#!/bin/bash
# .git/hooks/post-merge
# 合并后自动化操作

SQUASH=$1

echo "🔀 合并完成"

# 获取合并前后的变更文件
CHANGED_FILES=$(git diff-tree -r --name-only --no-commit-id ORIG_HEAD HEAD)

# 检查依赖文件变化并自动安装
check_and_install() {
    local file=$1
    local command=$2
    local description=$3

    if echo "$CHANGED_FILES" | grep -q "$file"; then
        echo "📦 $description"
        eval "$command"
    fi
}

# Node.js 依赖
check_and_install "package.json" "npm install" "检测到 package.json 变化，安装依赖..."

# Python 依赖
check_and_install "requirements.txt" "pip install -r requirements.txt" "检测到 requirements.txt 变化，安装依赖..."

# Go 依赖
check_and_install "go.mod" "go mod download" "检测到 go.mod 变化，下载依赖..."

# Rust 依赖
check_and_install "Cargo.toml" "cargo fetch" "检测到 Cargo.toml 变化，获取依赖..."

# 数据库迁移提醒
if echo "$CHANGED_FILES" | grep -qE 'migrations?/'; then
    echo ""
    echo "⚠️  警告：检测到数据库迁移文件变化"
    echo "   请运行数据库迁移命令以保持数据库结构同步"
    echo ""
fi

# 统计合并信息
COMMITS_MERGED=$(git rev-list ORIG_HEAD..HEAD --count)
FILES_CHANGED=$(echo "$CHANGED_FILES" | wc -l | tr -d ' ')

echo ""
echo "📊 合并统计:"
echo "   提交数: $COMMITS_MERGED"
echo "   变更文件: $FILES_CHANGED"

exit 0
```

#### 3.3.4 pre-push

**触发时机**：`git push` 执行后、数据传输前

**参数**：
- `$1` - 远程仓库名称
- `$2` - 远程仓库 URL

**标准输入**：每行格式为 `<local-ref> <local-oid> <remote-ref> <remote-oid>`
- `local-ref`: 本地引用名（如 `refs/heads/main`）
- `local-oid`: 本地对象的 SHA-1 值
- `remote-ref`: 远程引用名
- `remote-oid`: 远程对象的 SHA-1 值（全零表示新分支）

**常见用途**：
- 推送前运行完整测试
- 阻止推送到受保护分支
- 检查提交规范
- 防止推送大文件

**实际代码示例**：

```bash
#!/bin/bash
# .git/hooks/pre-push
# 推送前的完整验证

REMOTE=$1
URL=$2

echo "🚀 准备推送到 $REMOTE ($URL)"

# 读取推送信息
while read LOCAL_REF LOCAL_SHA REMOTE_REF REMOTE_SHA; do
    # 跳过删除操作
    if [ "$LOCAL_SHA" = "0000000000000000000000000000000000000000" ]; then
        continue
    fi

    # 获取分支名
    BRANCH=$(echo "$REMOTE_REF" | sed 's|refs/heads/||')

    echo "📤 推送分支: $BRANCH"

    # 1. 保护主分支：阻止直接推送
    PROTECTED_BRANCHES="main master"
    for protected in $PROTECTED_BRANCHES; do
        if [ "$BRANCH" = "$protected" ]; then
            echo "❌ 错误：禁止直接推送到 $BRANCH 分支"
            echo "请使用 Pull Request 进行代码合并"
            exit 1
        fi
    done

    # 2. 检查是否有 WIP 提交
    if [ "$REMOTE_SHA" = "0000000000000000000000000000000000000000" ]; then
        # 新分支
        COMMITS=$(git log "$LOCAL_SHA" --oneline)
    else
        # 已存在的分支
        COMMITS=$(git log "$REMOTE_SHA..$LOCAL_SHA" --oneline)
    fi

    if echo "$COMMITS" | grep -iqE '^[a-f0-9]+ (WIP|wip|fixup!|squash!)'; then
        echo "⚠️  警告：发现 WIP/fixup/squash 提交"
        echo "$COMMITS" | grep -iE 'WIP|fixup!|squash!'
        read -p "确定要推送这些提交吗？(y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # 3. 检查大文件
    if [ "$REMOTE_SHA" = "0000000000000000000000000000000000000000" ]; then
        FILES_TO_CHECK=$(git diff-tree --no-commit-id --name-only -r "$LOCAL_SHA")
    else
        FILES_TO_CHECK=$(git diff --name-only "$REMOTE_SHA..$LOCAL_SHA")
    fi

    MAX_FILE_SIZE=10485760  # 10MB
    for file in $FILES_TO_CHECK; do
        if [ -f "$file" ]; then
            size=$(wc -c < "$file" 2>/dev/null || echo 0)
            if [ "$size" -gt "$MAX_FILE_SIZE" ]; then
                echo "❌ 错误：文件 $file 超过 10MB 限制 ($(numfmt --to=iec $size))"
                echo "考虑使用 Git LFS 管理大文件"
                exit 1
            fi
        fi
    done

done

# 4. 运行测试
echo "🧪 运行测试..."
if [ -f "package.json" ] && grep -q '"test"' package.json; then
    npm test || {
        echo "❌ 测试失败，推送已取消"
        exit 1
    }
fi

if [ -f "go.mod" ]; then
    go test ./... || {
        echo "❌ 测试失败，推送已取消"
        exit 1
    }
fi

echo "✅ 所有检查通过，开始推送..."
exit 0
```

**高级示例 - 并行测试和检查**：

```typescript
#!/usr/bin/env npx ts-node
// .git/hooks/pre-push
// 并行执行推送前检查

import { execSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';

interface CheckResult {
  description: string;
  success: boolean;
  output: string;
}

function runCommand(cmd: string, description: string): CheckResult {
  try {
    const output = execSync(cmd, { encoding: 'utf-8', stdio: 'pipe' });
    return { description, success: true, output };
  } catch (error: any) {
    return {
      description,
      success: false,
      output: error.stdout?.toString() || error.message,
    };
  }
}

function fileExists(filePath: string): boolean {
  return fs.existsSync(path.resolve(process.cwd(), filePath));
}

async function checkTests(): Promise<CheckResult> {
  if (fileExists('package.json')) {
    return runCommand('npm test', 'Node.js 测试');
  }
  if (fileExists('go.mod')) {
    return runCommand('go test ./...', 'Go 测试');
  }
  return { description: '无测试', success: true, output: '' };
}

async function checkLint(): Promise<CheckResult> {
  if (fileExists('package.json')) {
    return runCommand('npm run lint 2>/dev/null || true', 'ESLint 检查');
  }
  return { description: '无 Lint', success: true, output: '' };
}

async function checkBuild(): Promise<CheckResult> {
  if (fileExists('package.json')) {
    const pkg = JSON.parse(fs.readFileSync('package.json', 'utf-8'));
    if (pkg.scripts?.build) {
      return runCommand('npm run build', '项目构建');
    }
  }
  return { description: '无构建', success: true, output: '' };
}

async function checkSecurity(): Promise<CheckResult> {
  if (fileExists('package-lock.json')) {
    return runCommand('npm audit --audit-level=high 2>/dev/null || true', 'npm 安全审计');
  }
  return { description: '无安全检查', success: true, output: '' };
}

async function main(): Promise<number> {
  const remote = process.argv[2] || 'origin';

  console.log(`🚀 推送前检查 -> ${remote}`);
  console.log('='.repeat(50));

  const checks = [checkTests, checkLint, checkBuild, checkSecurity];

  // 并行执行所有检查
  const results = await Promise.all(checks.map(check => check()));

  // 显示结果
  for (const result of results) {
    const status = result.success ? '✅' : '❌';
    console.log(`${status} ${result.description}`);
  }

  const failed = results.filter(r => !r.success);

  if (failed.length > 0) {
    console.log('\n' + '='.repeat(50));
    console.log('❌ 以下检查失败：');
    for (const f of failed) {
      console.log(`\n--- ${f.description} ---`);
      console.log(f.output.slice(0, 500));
    }
    return 1;
  }

  console.log('\n✅ 所有检查通过！');
  return 0;
}

main().then(code => process.exit(code));
```

#### 3.3.5 pre-auto-gc

**触发时机**：`git gc --auto` 执行前

**参数**：无

**常见用途**：
- 决定是否执行自动垃圾回收
- 在特定条件下延迟 GC

**实际代码示例**：

```bash
#!/bin/bash
# .git/hooks/pre-auto-gc
# 控制自动垃圾回收

# 检查是否在进行重要操作
if [ -f ".git/MERGE_HEAD" ] || [ -f ".git/REBASE_HEAD" ]; then
    echo "检测到正在进行合并或 rebase，跳过 GC"
    exit 1
fi

# 检查系统负载（Linux/macOS）
if command -v uptime &> /dev/null; then
    LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | awk -F',' '{ print $1 }' | tr -d ' ')
    THRESHOLD=2.0

    if (( $(echo "$LOAD > $THRESHOLD" | bc -l) )); then
        echo "系统负载过高 ($LOAD)，延迟 GC"
        exit 1
    fi
fi

# 仅在夜间执行 GC
HOUR=$(date +%H)
if [ "$HOUR" -ge 9 ] && [ "$HOUR" -le 18 ]; then
    # 工作时间，检查仓库大小
    REPO_SIZE=$(du -sm .git 2>/dev/null | cut -f1)
    if [ "$REPO_SIZE" -lt 500 ]; then
        echo "仓库较小 (${REPO_SIZE}MB)，工作时间跳过 GC"
        exit 1
    fi
fi

exit 0
```

#### 3.3.6 post-rewrite

**触发时机**：重写提交的命令执行后（如 `git commit --amend`、`git rebase`）

**参数**：
- `$1` - 触发的命令（`amend` 或 `rebase`）

**标准输入**：每行格式为 `<old-oid> <new-oid> [<extra-info>]`
- `old-oid`: 原提交的 SHA-1
- `new-oid`: 新提交的 SHA-1
- `extra-info`: 可选的额外信息

**常见用途**：
- 更新相关的 Issue 跟踪
- 同步提交信息到其他系统

```bash
#!/bin/bash
# .git/hooks/post-rewrite
# 记录提交重写历史

COMMAND=$1

echo "📝 提交被 $COMMAND 重写"

# 记录重写历史
LOG_FILE=".git/rewrite_history.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

while read OLD_SHA NEW_SHA; do
    echo "$DATE | $COMMAND | $OLD_SHA -> $NEW_SHA" >> "$LOG_FILE"
    OLD_MSG=$(git log -1 --format=%s "$OLD_SHA" 2>/dev/null || echo "已删除")
    NEW_MSG=$(git log -1 --format=%s "$NEW_SHA")
    echo "  $OLD_SHA: $OLD_MSG"
    echo "  $NEW_SHA: $NEW_MSG"
done
```

#### 3.3.7 fsmonitor-watchman

**触发时机**：Git 需要检查文件系统变化时

**参数**：
- `$1` - 版本号（当前为 2）
- `$2` - 上次查询的时间戳

**常见用途**：
- 配合 Watchman 加速大型仓库的状态检查
- 优化 `git status` 性能

```perl
#!/usr/bin/perl
# .git/hooks/fsmonitor-watchman
# 需要配合 Facebook Watchman 使用

use strict;
use warnings;
use IPC::Open2;

my ($version, $last_update_token) = @ARGV;

# 仅支持版本 2
die "Unsupported version: $version\n" unless $version == 2;

my $git_work_tree = `git rev-parse --show-toplevel`;
chomp $git_work_tree;

my $query = qq|
["query", "$git_work_tree", {
    "since": "$last_update_token",
    "fields": ["name"],
    "expression": ["not", ["anyof",
        ["dirname", ".git"],
        ["name", ".git", "wholename"]
    ]]
}]|;

my $pid = open2(\*CHLD_OUT, \*CHLD_IN, 'watchman -j')
    or die "open2() failed: $!\n";

print CHLD_IN $query;
close CHLD_IN;

my $response = do { local $/; <CHLD_OUT> };

# 解析响应并输出
use JSON;
my $json = decode_json($response);

if (exists $json->{error}) {
    die "Watchman error: $json->{error}\n";
}

my $clock = $json->{clock};
print "$clock\n";

if (exists $json->{files}) {
    print join("\n", @{$json->{files}});
}

exit 0;
```

---

## 4. 服务端 Hooks

服务端 Hooks 在 Git 服务器上运行，用于执行更严格的策略控制。

### 4.1 pre-receive

**触发时机**：服务器收到 push 请求后、更新引用之前

**参数**：无（通过标准输入接收）

**标准输入**：每行格式为 `<old-oid> <new-oid> <ref-name>`
- `old-oid`: 引用的旧值（全零表示新建）
- `new-oid`: 引用的新值（全零表示删除）
- `ref-name`: 引用名称（如 `refs/heads/main`）

**环境变量**：
- `GIT_PUSH_OPTION_COUNT`: 推送选项数量
- `GIT_PUSH_OPTION_0`, `GIT_PUSH_OPTION_1`...: 各推送选项值

**常见用途**：
- 强制执行代码审查
- 实施分支保护策略
- 验证提交签名
- 阻止强制推送

**实际代码示例**：

```bash
#!/bin/bash
# hooks/pre-receive (服务端)
# 企业级推送验证

# 错误处理
set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_error() { echo -e "${RED}❌ $1${NC}" >&2; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# 获取推送用户
PUSH_USER=${GL_USER:-${REMOTE_USER:-$(whoami)}}

# 管理员列表
ADMINS="admin root devops"

is_admin() {
    echo "$ADMINS" | grep -qw "$1"
}

# 受保护的分支
PROTECTED_BRANCHES="main master develop release"

# 零 SHA（表示创建或删除）
ZERO_SHA="0000000000000000000000000000000000000000"

while read OLD_SHA NEW_SHA REF_NAME; do
    BRANCH=$(echo "$REF_NAME" | sed 's|refs/heads/||')

    echo "处理: $BRANCH"

    # 检查是否是受保护分支
    IS_PROTECTED=false
    for protected in $PROTECTED_BRANCHES; do
        if [ "$BRANCH" = "$protected" ]; then
            IS_PROTECTED=true
            break
        fi
    done

    # 1. 阻止删除受保护分支
    if [ "$NEW_SHA" = "$ZERO_SHA" ] && [ "$IS_PROTECTED" = true ]; then
        log_error "禁止删除受保护分支: $BRANCH"
        exit 1
    fi

    # 2. 阻止强制推送到受保护分支
    if [ "$IS_PROTECTED" = true ] && [ "$OLD_SHA" != "$ZERO_SHA" ] && [ "$NEW_SHA" != "$ZERO_SHA" ]; then
        # 检查是否是 fast-forward
        MERGE_BASE=$(git merge-base "$OLD_SHA" "$NEW_SHA" 2>/dev/null || echo "")
        if [ "$MERGE_BASE" != "$OLD_SHA" ]; then
            if ! is_admin "$PUSH_USER"; then
                log_error "禁止对 $BRANCH 执行强制推送"
                log_error "如需重写历史，请联系管理员"
                exit 1
            else
                log_warning "管理员 $PUSH_USER 执行强制推送"
            fi
        fi
    fi

    # 3. 检查提交信息格式
    if [ "$OLD_SHA" = "$ZERO_SHA" ]; then
        COMMITS=$(git rev-list "$NEW_SHA" --not --all)
    else
        COMMITS=$(git rev-list "$OLD_SHA..$NEW_SHA")
    fi

    COMMIT_MSG_PATTERN="^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\(.+\))?: .{1,100}$"
    MERGE_PATTERN="^Merge"

    for commit in $COMMITS; do
        MSG=$(git log -1 --format=%s "$commit")

        if ! echo "$MSG" | grep -qE "$MERGE_PATTERN"; then
            if ! echo "$MSG" | grep -qE "$COMMIT_MSG_PATTERN"; then
                log_error "提交 ${commit:0:8} 信息格式不符合规范"
                log_error "消息: $MSG"
                log_error "格式: <type>(<scope>): <description>"
                exit 1
            fi
        fi
    done

    # 4. 检查提交签名（可选）
    # for commit in $COMMITS; do
    #     if ! git verify-commit "$commit" &>/dev/null; then
    #         log_error "提交 ${commit:0:8} 未签名或签名无效"
    #         exit 1
    #     fi
    # done

    # 5. 检查文件大小和类型
    for commit in $COMMITS; do
        FILES=$(git diff-tree --no-commit-id --name-only -r "$commit")
        for file in $FILES; do
            # 检查危险文件类型
            if echo "$file" | grep -qE '\.(exe|dll|so|dylib|bin)$'; then
                log_warning "检测到二进制文件: $file"
            fi

            # 检查敏感文件
            if echo "$file" | grep -qiE '(password|secret|credential|\.pem|\.key)'; then
                log_error "检测到可能的敏感文件: $file"
                log_error "请确保没有提交密钥或密码"
                exit 1
            fi
        done
    done

    log_success "分支 $BRANCH 验证通过"
done

exit 0
```

### 4.2 update

**触发时机**：服务器更新每个引用之前（每个分支/标签调用一次）

**参数**：
- `$1` - 引用名称（如 `refs/heads/main`）
- `$2` - 旧的对象名称（SHA-1）
- `$3` - 新的对象名称（SHA-1）

**返回值**：
- 返回 0：允许更新该引用
- 返回非零：拒绝更新该引用（不影响其他引用）

**与 pre-receive 的区别**：`update` 按引用逐个调用，可以单独拒绝某些引用的更新；`pre-receive` 是全有或全无，一旦失败所有引用都不会更新。

**常见用途**：
- 针对每个分支的精细权限控制
- 分支级别的策略验证

**实际代码示例**：

```bash
#!/bin/bash
# hooks/update (服务端)
# 分支级别的权限控制

REF_NAME=$1
OLD_SHA=$2
NEW_SHA=$3

BRANCH=$(echo "$REF_NAME" | sed 's|refs/heads/||')
PUSH_USER=${GL_USER:-${REMOTE_USER:-$(whoami)}}
ZERO_SHA="0000000000000000000000000000000000000000"

echo "======================================"
echo "更新引用: $REF_NAME"
echo "用户: $PUSH_USER"
echo "Old: ${OLD_SHA:0:8}"
echo "New: ${NEW_SHA:0:8}"
echo "======================================"

# 权限配置（实际应从配置文件或数据库读取）
# 格式: branch:user1,user2,...
BRANCH_PERMISSIONS=(
    "main:admin,release-manager"
    "release/*:admin,release-manager,devops"
    "develop:admin,developer"
    "feature/*:*"
    "hotfix/*:admin,developer"
)

check_permission() {
    local branch=$1
    local user=$2

    for perm in "${BRANCH_PERMISSIONS[@]}"; do
        pattern="${perm%%:*}"
        users="${perm#*:}"

        # 通配符匹配
        if [[ "$branch" == $pattern ]]; then
            if [ "$users" = "*" ]; then
                return 0
            fi
            if echo "$users" | grep -qw "$user"; then
                return 0
            fi
        fi
    done

    return 1
}

# 检查删除操作
if [ "$NEW_SHA" = "$ZERO_SHA" ]; then
    # 禁止删除 main 分支
    if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
        echo "❌ 禁止删除 $BRANCH 分支"
        exit 1
    fi

    echo "ℹ️  删除分支: $BRANCH"
fi

# 检查创建操作
if [ "$OLD_SHA" = "$ZERO_SHA" ]; then
    echo "ℹ️  创建分支: $BRANCH"

    # 验证分支命名规范
    VALID_PATTERN="^(main|master|develop|feature/|bugfix/|hotfix/|release/)"
    if ! echo "$BRANCH" | grep -qE "$VALID_PATTERN"; then
        echo "❌ 分支名不符合规范: $BRANCH"
        echo "允许的格式: main, develop, feature/*, bugfix/*, hotfix/*, release/*"
        exit 1
    fi
fi

# 检查权限
if ! check_permission "$BRANCH" "$PUSH_USER"; then
    echo "❌ 用户 $PUSH_USER 无权操作分支 $BRANCH"
    exit 1
fi

# 验证提交
if [ "$OLD_SHA" != "$ZERO_SHA" ] && [ "$NEW_SHA" != "$ZERO_SHA" ]; then
    COMMITS=$(git rev-list "$OLD_SHA..$NEW_SHA")
    COMMIT_COUNT=$(echo "$COMMITS" | wc -l)

    echo "📝 包含 $COMMIT_COUNT 个提交"

    # 对于 main/release 分支，要求所有提交都经过审查
    if [[ "$BRANCH" =~ ^(main|master|release/) ]]; then
        for commit in $COMMITS; do
            # 检查提交是否包含 Reviewed-by 标签
            if ! git log -1 --format=%B "$commit" | grep -q "Reviewed-by:"; then
                echo "❌ 提交 ${commit:0:8} 未经过代码审查"
                echo "main/release 分支的提交必须包含 Reviewed-by 标签"
                exit 1
            fi
        done
    fi
fi

echo "✅ 更新验证通过"
exit 0
```

### 4.3 post-receive

**触发时机**：所有引用更新完成后

**参数**：无（通过标准输入接收更新信息）

**标准输入**：每行格式为 `<old-oid> <new-oid> <ref-name>`（与 pre-receive 相同）

**环境变量**：
- `GIT_PUSH_OPTION_COUNT`: 推送选项数量
- `GIT_PUSH_OPTION_0`, `GIT_PUSH_OPTION_1`...: 各推送选项值

**注意**：此 hook 无法影响推送结果，因为引用已经更新完成。

**常见用途**：
- 触发 CI/CD 流水线
- 发送通知
- 自动部署
- 更新文档

**实际代码示例**：

```bash
#!/bin/bash
# hooks/post-receive (服务端)
# 自动化部署和通知

# 配置
DEPLOY_DIR="/var/www/myapp"
DEPLOY_BRANCH="main"
SLACK_WEBHOOK="https://hooks.slack.com/services/xxx"
CI_TRIGGER_URL="https://ci.example.com/api/trigger"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 发送 Slack 通知
send_slack_notification() {
    local message=$1
    local color=$2

    curl -s -X POST -H 'Content-type: application/json' \
        --data "{
            \"attachments\": [{
                \"color\": \"$color\",
                \"text\": \"$message\",
                \"footer\": \"Git Server\"
            }]
        }" \
        "$SLACK_WEBHOOK" > /dev/null
}

# 触发 CI
trigger_ci() {
    local branch=$1
    local commit=$2

    curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{\"branch\": \"$branch\", \"commit\": \"$commit\"}" \
        "$CI_TRIGGER_URL" > /dev/null
}

# 部署函数
deploy() {
    local branch=$1
    local sha=$2

    log "开始部署 $branch ($sha)"

    # 切换到部署目录
    cd "$DEPLOY_DIR" || exit 1

    # 获取最新代码
    git fetch origin "$branch"
    git reset --hard "origin/$branch"

    # 安装依赖
    if [ -f "package.json" ]; then
        npm ci --production
    fi

    # 构建
    if [ -f "package.json" ] && grep -q '"build"' package.json; then
        npm run build
    fi

    # 重启服务
    if command -v systemctl &> /dev/null; then
        sudo systemctl restart myapp
    elif command -v pm2 &> /dev/null; then
        pm2 restart myapp
    fi

    log "部署完成"
}

# 处理推送
while read OLD_SHA NEW_SHA REF_NAME; do
    BRANCH=$(echo "$REF_NAME" | sed 's|refs/heads/||')
    PUSHER=${GL_USER:-${REMOTE_USER:-$(whoami)}}

    # 跳过删除操作
    if [ "$NEW_SHA" = "0000000000000000000000000000000000000000" ]; then
        log "分支 $BRANCH 被删除"
        send_slack_notification "🗑️ $PUSHER 删除了分支 $BRANCH" "warning"
        continue
    fi

    # 获取提交信息
    COMMIT_MSG=$(git log -1 --format=%s "$NEW_SHA")
    COMMIT_AUTHOR=$(git log -1 --format=%an "$NEW_SHA")

    # 计算提交数
    if [ "$OLD_SHA" = "0000000000000000000000000000000000000000" ]; then
        COMMIT_COUNT="新分支"
    else
        COMMIT_COUNT=$(git rev-list "$OLD_SHA..$NEW_SHA" --count)
    fi

    log "收到推送: $BRANCH by $PUSHER ($COMMIT_COUNT 个提交)"

    # 发送通知
    MESSAGE="📦 *$PUSHER* 推送了 $COMMIT_COUNT 个提交到 \`$BRANCH\`\n最新: $COMMIT_MSG"
    send_slack_notification "$MESSAGE" "good"

    # 触发 CI
    log "触发 CI 流水线"
    trigger_ci "$BRANCH" "$NEW_SHA"

    # 自动部署（仅限指定分支）
    if [ "$BRANCH" = "$DEPLOY_BRANCH" ]; then
        log "触发自动部署"

        # 异步部署，不阻塞推送
        (
            deploy "$BRANCH" "$NEW_SHA" >> /var/log/deploy.log 2>&1
            if [ $? -eq 0 ]; then
                send_slack_notification "🚀 部署成功: $BRANCH" "good"
            else
                send_slack_notification "❌ 部署失败: $BRANCH" "danger"
            fi
        ) &
    fi
done

exit 0
```

**高级示例 - 自动生成 Release Notes**：

```typescript
#!/usr/bin/env npx ts-node
// hooks/post-receive
// 自动生成 Release Notes

import { execSync } from 'child_process';
import * as fs from 'fs';
import * as readline from 'readline';

interface Commit {
  sha: string;
  message: string;
  author: string;
  date: string;
}

interface Categories {
  feat: Commit[];
  fix: Commit[];
  docs: Commit[];
  refactor: Commit[];
  test: Commit[];
  other: Commit[];
}

function runGit(args: string[]): string {
  return execSync(['git', ...args].join(' '), { encoding: 'utf-8' }).trim();
}

function getCommits(oldSha: string, newSha: string): Commit[] {
  const output = runGit([
    'log',
    `${oldSha}..${newSha}`,
    '--format=%H|%s|%an|%ad',
    '--date=short',
  ]);

  return output
    .split('\n')
    .filter(Boolean)
    .map(line => {
      const [sha, message, author, date] = line.split('|');
      return { sha, message, author, date };
    });
}

function categorizeCommits(commits: Commit[]): Categories {
  const categories: Categories = {
    feat: [],
    fix: [],
    docs: [],
    refactor: [],
    test: [],
    other: [],
  };

  const typeKeys = ['feat', 'fix', 'docs', 'refactor', 'test'] as const;

  for (const commit of commits) {
    let matched = false;

    for (const cat of typeKeys) {
      if (
        commit.message.startsWith(`${cat}:`) ||
        commit.message.startsWith(`${cat}(`)
      ) {
        categories[cat].push(commit);
        matched = true;
        break;
      }
    }

    if (!matched) {
      categories.other.push(commit);
    }
  }

  return categories;
}

function generateReleaseNotes(
  branch: string,
  oldSha: string,
  newSha: string
): string {
  const commits = getCommits(oldSha, newSha);
  const categories = categorizeCommits(commits);

  const date = new Date().toISOString().split('T')[0];

  let notes = `# Release Notes - ${branch}

**日期**: ${date}
**版本**: ${newSha.slice(0, 8)}
**提交数**: ${commits.length}

`;

  const categoryNames: Record<keyof Categories, string> = {
    feat: '✨ 新功能',
    fix: '🐛 Bug 修复',
    docs: '📚 文档更新',
    refactor: '♻️ 代码重构',
    test: '✅ 测试',
    other: '📦 其他',
  };

  for (const [cat, name] of Object.entries(categoryNames)) {
    const catCommits = categories[cat as keyof Categories];
    if (catCommits.length > 0) {
      notes += `\n## ${name}\n\n`;
      for (const commit of catCommits) {
        const msg = commit.message.replace(
          /^(feat|fix|docs|refactor|test)(\(.+\))?: /,
          ''
        );
        notes += `- ${msg} (${commit.sha.slice(0, 7)}) - @${commit.author}\n`;
      }
    }
  }

  return notes;
}

async function main(): Promise<void> {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
    terminal: false,
  });

  for await (const line of rl) {
    const [oldSha, newSha, ref] = line.trim().split(' ');

    // 只处理 tag 或 release 分支
    if (!ref.startsWith('refs/tags/') && !ref.includes('release')) {
      continue;
    }

    if (newSha === '0'.repeat(40)) {
      continue;
    }

    const branch = ref.replace('refs/heads/', '').replace('refs/tags/', '');

    // 生成 Release Notes
    const notes = generateReleaseNotes(branch, oldSha, newSha);

    // 保存到文件
    const filename = `/var/www/releases/${branch.replace(/\//g, '-')}-${newSha.slice(0, 8)}.md`;
    fs.writeFileSync(filename, notes);

    console.log(`📝 Release Notes 已生成: ${filename}`);
  }
}

main();
```

### 4.4 post-update

**触发时机**：所有引用更新后（与 post-receive 类似，但只传递引用名）

**参数**：更新的引用名列表

**常见用途**：
- 更新服务器端的仓库信息
- 运行 `git update-server-info`（用于 dumb HTTP 服务）

**实际代码示例**：

```bash
#!/bin/bash
# hooks/post-update
# 更新服务器信息

echo "更新服务器信息..."

# 更新用于 HTTP 服务的信息
exec git update-server-info

# 记录更新的分支
for ref in "$@"; do
    echo "更新: $ref"
done
```

### 4.5 push-to-checkout

**触发时机**：当推送到非裸仓库（有工作区）时，在更新工作区之前

**参数**：
- `$1` - 要检出的提交 SHA

**常见用途**：
- 自定义工作区更新逻辑
- 处理推送到开发服务器的场景

```bash
#!/bin/bash
# hooks/push-to-checkout
# 自定义检出逻辑

COMMIT=$1

echo "收到推送，准备更新工作区..."

# 保存当前未提交的更改
git stash push -m "Auto stash before push-to-checkout"

# 更新工作区
git checkout -f "$COMMIT"

# 恢复之前的更改
git stash pop 2>/dev/null || true

echo "工作区已更新到 ${COMMIT:0:8}"
```

### 4.6 pre-push (服务端视角)

虽然 `pre-push` 主要是客户端 Hook，但服务端可以通过 `pre-receive` 实现类似功能。这里展示如何在服务端进行更严格的验证：

```bash
#!/bin/bash
# hooks/pre-receive (模拟服务端 pre-push 验证)
# 综合性的推送验证

# 最大允许的单次推送提交数
MAX_COMMITS=50

# 最大允许的单文件大小 (50MB)
MAX_FILE_SIZE=52428800

while read OLD_SHA NEW_SHA REF_NAME; do
    # 跳过删除
    [ "$NEW_SHA" = "0000000000000000000000000000000000000000" ] && continue

    # 确定要检查的提交范围
    if [ "$OLD_SHA" = "0000000000000000000000000000000000000000" ]; then
        COMMITS=$(git rev-list "$NEW_SHA" --not --all)
    else
        COMMITS=$(git rev-list "$OLD_SHA..$NEW_SHA")
    fi

    COMMIT_COUNT=$(echo "$COMMITS" | wc -w)

    # 检查提交数量
    if [ "$COMMIT_COUNT" -gt "$MAX_COMMITS" ]; then
        echo "❌ 单次推送包含 $COMMIT_COUNT 个提交，超过限制 $MAX_COMMITS"
        echo "请分批推送或联系管理员"
        exit 1
    fi

    # 检查每个提交
    for commit in $COMMITS; do
        # 获取此提交变更的文件
        FILES=$(git diff-tree --no-commit-id --name-only -r "$commit")

        for file in $FILES; do
            # 获取文件大小
            SIZE=$(git cat-file -s "$commit:$file" 2>/dev/null || echo 0)

            if [ "$SIZE" -gt "$MAX_FILE_SIZE" ]; then
                SIZE_MB=$((SIZE / 1024 / 1024))
                echo "❌ 文件过大: $file (${SIZE_MB}MB)"
                echo "最大允许: $((MAX_FILE_SIZE / 1024 / 1024))MB"
                echo "建议使用 Git LFS"
                exit 1
            fi
        done
    done
done

exit 0
```

---

## 5. 实用配置示例

### 5.1 完整的提交前检查流程

创建一个综合的 pre-commit hook，整合多种检查：

```bash
#!/bin/bash
# .git/hooks/pre-commit
# 综合提交前检查流程

set -e

# 配置
ENABLE_LINT=true
ENABLE_TEST=true
ENABLE_FORMAT=true
ENABLE_SECURITY=true

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 获取暂存文件
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [ -z "$STAGED_FILES" ]; then
    echo "没有暂存的文件"
    exit 0
fi

echo -e "${BLUE}🔍 开始提交前检查...${NC}"
echo ""

# 记录检查结果
ERRORS=()
WARNINGS=()

# 1. 代码格式化
if [ "$ENABLE_FORMAT" = true ]; then
    echo -e "${BLUE}[1/4] 代码格式化检查${NC}"

    # JavaScript/TypeScript
    JS_FILES=$(echo "$STAGED_FILES" | grep -E '\.(js|jsx|ts|tsx)$' || true)
    if [ -n "$JS_FILES" ] && [ -f "node_modules/.bin/prettier" ]; then
        echo "  检查 Prettier..."
        UNFORMATTED=$(echo "$JS_FILES" | xargs node_modules/.bin/prettier --check 2>&1 || true)
        if echo "$UNFORMATTED" | grep -q "error"; then
            echo "  自动格式化..."
            echo "$JS_FILES" | xargs node_modules/.bin/prettier --write
            echo "$JS_FILES" | xargs git add
            echo -e "  ${GREEN}✓ 已自动格式化${NC}"
        fi
    fi

    # Python
    PY_FILES=$(echo "$STAGED_FILES" | grep '\.py$' || true)
    if [ -n "$PY_FILES" ] && command -v black &> /dev/null; then
        echo "  检查 Black..."
        if ! echo "$PY_FILES" | xargs black --check --quiet 2>/dev/null; then
            echo "  自动格式化..."
            echo "$PY_FILES" | xargs black --quiet
            echo "$PY_FILES" | xargs git add
            echo -e "  ${GREEN}✓ 已自动格式化${NC}"
        fi
    fi
fi

# 2. 代码检查
if [ "$ENABLE_LINT" = true ]; then
    echo -e "${BLUE}[2/4] 代码规范检查${NC}"

    # ESLint
    JS_FILES=$(echo "$STAGED_FILES" | grep -E '\.(js|jsx|ts|tsx)$' || true)
    if [ -n "$JS_FILES" ] && [ -f "node_modules/.bin/eslint" ]; then
        echo "  运行 ESLint..."
        if ! echo "$JS_FILES" | xargs node_modules/.bin/eslint --quiet; then
            ERRORS+=("ESLint 检查失败")
        else
            echo -e "  ${GREEN}✓ ESLint 检查通过${NC}"
        fi
    fi

    # Pylint/Flake8
    PY_FILES=$(echo "$STAGED_FILES" | grep '\.py$' || true)
    if [ -n "$PY_FILES" ]; then
        if command -v flake8 &> /dev/null; then
            echo "  运行 Flake8..."
            if ! echo "$PY_FILES" | xargs flake8 --max-line-length=120; then
                ERRORS+=("Flake8 检查失败")
            else
                echo -e "  ${GREEN}✓ Flake8 检查通过${NC}"
            fi
        fi
    fi
fi

# 3. 安全检查
if [ "$ENABLE_SECURITY" = true ]; then
    echo -e "${BLUE}[3/4] 安全检查${NC}"

    # 检查敏感信息
    SENSITIVE_PATTERNS=(
        "password\s*[:=]"
        "api[_-]?key\s*[:=]"
        "secret\s*[:=]"
        "token\s*[:=]"
        "AWS_SECRET"
        "private[_-]?key"
        "BEGIN RSA PRIVATE KEY"
        "BEGIN OPENSSH PRIVATE KEY"
    )

    for pattern in "${SENSITIVE_PATTERNS[@]}"; do
        MATCHES=$(echo "$STAGED_FILES" | xargs grep -l -i -E "$pattern" 2>/dev/null || true)
        if [ -n "$MATCHES" ]; then
            WARNINGS+=("可能包含敏感信息: $MATCHES")
        fi
    done

    # 检查大文件
    for file in $STAGED_FILES; do
        if [ -f "$file" ]; then
            SIZE=$(wc -c < "$file")
            if [ "$SIZE" -gt 5242880 ]; then
                ERRORS+=("文件过大: $file ($(numfmt --to=iec $SIZE))")
            fi
        fi
    done

    # 检查调试代码
    DEBUG_PATTERNS="console\.log|debugger|import pdb|pdb\.set_trace|breakpoint\(\)"
    DEBUG_FILES=$(echo "$STAGED_FILES" | xargs grep -l -E "$DEBUG_PATTERNS" 2>/dev/null || true)
    if [ -n "$DEBUG_FILES" ]; then
        WARNINGS+=("发现调试代码: $DEBUG_FILES")
    fi

    if [ ${#WARNINGS[@]} -eq 0 ]; then
        echo -e "  ${GREEN}✓ 安全检查通过${NC}"
    fi
fi

# 4. 运行测试
if [ "$ENABLE_TEST" = true ]; then
    echo -e "${BLUE}[4/4] 运行测试${NC}"

    # 只运行与变更相关的测试
    if [ -f "package.json" ] && grep -q '"test"' package.json; then
        echo "  运行 npm test..."
        if npm test -- --passWithNoTests --findRelatedTests $STAGED_FILES 2>/dev/null; then
            echo -e "  ${GREEN}✓ 测试通过${NC}"
        else
            ERRORS+=("测试失败")
        fi
    fi
fi

echo ""

# 显示警告
if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  警告:${NC}"
    for warning in "${WARNINGS[@]}"; do
        echo -e "  ${YELLOW}- $warning${NC}"
    done
    echo ""
fi

# 处理错误
if [ ${#ERRORS[@]} -gt 0 ]; then
    echo -e "${RED}❌ 检查失败:${NC}"
    for error in "${ERRORS[@]}"; do
        echo -e "  ${RED}- $error${NC}"
    done
    echo ""
    echo "提交已取消。请修复上述问题后重试。"
    echo "如需跳过检查，使用: git commit --no-verify"
    exit 1
fi

echo -e "${GREEN}✅ 所有检查通过！${NC}"
exit 0
```

### 5.2 自动化版本号管理

使用 hooks 自动管理语义化版本：

```bash
#!/bin/bash
# .git/hooks/post-commit
# 自动更新版本号

# 仅在 main 分支执行
BRANCH=$(git symbolic-ref --short HEAD)
if [ "$BRANCH" != "main" ]; then
    exit 0
fi

# 获取最新提交信息
COMMIT_MSG=$(git log -1 --pretty=%B)

# 根据 Conventional Commits 确定版本类型
if echo "$COMMIT_MSG" | grep -qE '^feat!:|BREAKING CHANGE'; then
    VERSION_TYPE="major"
elif echo "$COMMIT_MSG" | grep -qE '^feat:'; then
    VERSION_TYPE="minor"
elif echo "$COMMIT_MSG" | grep -qE '^fix:'; then
    VERSION_TYPE="patch"
else
    exit 0
fi

# 更新 package.json 版本（如果存在）
if [ -f "package.json" ]; then
    # 使用 npm version（不创建 git tag）
    npm version $VERSION_TYPE --no-git-tag-version
    NEW_VERSION=$(node -p "require('./package.json').version")

    # 提交版本更新
    git add package.json package-lock.json 2>/dev/null
    git commit --amend --no-edit --no-verify

    echo "📦 版本已更新: $NEW_VERSION"
fi
```

### 5.3 团队 Hooks 共享方案

创建可在团队间共享的 hooks 配置：

**目录结构**：
```
project/
├── .githooks/
│   ├── pre-commit
│   ├── commit-msg
│   ├── pre-push
│   └── README.md
├── scripts/
│   └── setup-hooks.sh
└── package.json
```

**setup-hooks.sh**：
```bash
#!/bin/bash
# scripts/setup-hooks.sh
# 一键配置 Git Hooks

HOOKS_DIR=".githooks"

echo "🔧 配置 Git Hooks..."

# 设置 hooks 目录
git config core.hooksPath "$HOOKS_DIR"

# 确保所有 hooks 有执行权限
chmod +x "$HOOKS_DIR"/*

echo "✅ Git Hooks 配置完成"
echo "Hooks 目录: $HOOKS_DIR"
echo ""
echo "已配置的 Hooks:"
ls -la "$HOOKS_DIR" | grep -v "README"
```

**package.json 集成**：
```json
{
  "scripts": {
    "prepare": "bash scripts/setup-hooks.sh",
    "hooks:install": "bash scripts/setup-hooks.sh"
  }
}
```

**.githooks/README.md**：
```markdown
# Git Hooks

本目录包含团队共享的 Git Hooks。

## 安装

运行以下命令启用 hooks：

```bash
npm run hooks:install
# 或
bash scripts/setup-hooks.sh
```

## 包含的 Hooks

- `pre-commit`: 提交前代码检查
- `commit-msg`: 提交信息格式验证
- `pre-push`: 推送前测试运行

## 跳过 Hooks

如需临时跳过 hooks（不推荐）：

```bash
git commit --no-verify
git push --no-verify
```
```

---

## 6. 最佳实践

### 6.1 编写 Hooks 的原则

1. **保持简洁**
   - 每个 hook 只做一件事
   - 复杂逻辑拆分为多个函数或脚本

2. **快速执行**
   - 开发者不愿等待，慢的 hooks 会被跳过
   - 长时间任务应该异步执行或放到 CI

3. **提供清晰的反馈**
   - 输出要有意义，说明正在做什么
   - 错误信息要具体，指明如何修复

4. **可配置**
   - 允许通过环境变量或配置文件自定义行为
   - 提供禁用特定检查的选项

5. **幂等性**
   - Hook 应该可以安全地重复执行
   - 不应依赖外部状态

### 6.2 性能优化建议

```bash
#!/bin/bash
# 性能优化示例

# 1. 只检查已修改的文件，而不是所有文件
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

# 2. 并行执行检查
check_lint() { ... }
check_format() { ... }
check_security() { ... }

# 并行运行
check_lint &
PID1=$!
check_format &
PID2=$!
check_security &
PID3=$!

# 等待所有检查完成
wait $PID1 $PID2 $PID3

# 3. 使用增量检查
# 例如，只对变更的行运行 lint
git diff --cached -U0 | lint-staged

# 4. 缓存检查结果
CACHE_DIR=".git/hook-cache"
mkdir -p "$CACHE_DIR"

for file in $STAGED_FILES; do
    HASH=$(git hash-object "$file")
    CACHE_FILE="$CACHE_DIR/${file//\//_}_$HASH"

    if [ -f "$CACHE_FILE" ]; then
        echo "跳过已检查: $file"
        continue
    fi

    # 执行检查
    run_check "$file"

    # 记录缓存
    touch "$CACHE_FILE"
done

# 5. 提前退出
# 发现第一个错误就停止
set -e
```

### 6.3 安全注意事项

1. **不要在 hooks 中存储密钥**
   ```bash
   # ❌ 错误
   API_KEY="sk-xxxx"

   # ✅ 正确
   API_KEY="${API_KEY:-}"
   if [ -z "$API_KEY" ]; then
       echo "请设置 API_KEY 环境变量"
       exit 1
   fi
   ```

2. **验证外部输入**
   ```bash
   # 防止命令注入
   BRANCH=$(git symbolic-ref --short HEAD)
   # 验证分支名只包含允许的字符
   if ! echo "$BRANCH" | grep -qE '^[a-zA-Z0-9/_-]+$'; then
       echo "无效的分支名"
       exit 1
   fi
   ```

3. **限制网络访问**
   ```bash
   # 设置超时
   curl --max-time 5 "$URL" || echo "请求超时"

   # 只访问白名单域名
   ALLOWED_HOSTS="api.github.com slack.com"
   ```

4. **不要以 root 运行**
   ```bash
   if [ "$(id -u)" = "0" ]; then
       echo "不要以 root 用户运行此脚本"
       exit 1
   fi
   ```

### 6.4 调试技巧

1. **启用调试模式**
   ```bash
   #!/bin/bash
   # 设置 DEBUG=1 启用调试输出
   [ "${DEBUG:-0}" = "1" ] && set -x
   ```

2. **日志记录**
   ```bash
   LOG_FILE=".git/hooks.log"

   log() {
       echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
       [ "${VERBOSE:-0}" = "1" ] && echo "$1"
   }
   ```

3. **手动测试 hook**
   ```bash
   # 直接运行 hook 脚本
   .git/hooks/pre-commit

   # 带调试输出
   DEBUG=1 .git/hooks/pre-commit

   # 检查退出码
   .git/hooks/pre-commit
   echo "Exit code: $?"
   ```

4. **使用 GIT_TRACE**
   ```bash
   # 查看 Git 内部调用
   GIT_TRACE=1 git commit -m "test"

   # 只跟踪 hooks
   GIT_TRACE_HOOK=1 git commit -m "test"
   ```

---

## 7. 常见问题解答 (FAQ)

### Q1: 如何跳过 Git Hooks？

**A:** 使用 `--no-verify` 或 `-n` 选项：

```bash
# 跳过 pre-commit 和 commit-msg
git commit --no-verify -m "紧急修复"
git commit -n -m "紧急修复"

# 跳过 pre-push
git push --no-verify

# 跳过 pre-merge-commit
git merge --no-verify feature-branch
```

> ⚠️ 注意：滥用此选项会绕过团队规范，应谨慎使用。

### Q2: Hooks 没有执行怎么办？

**A:** 检查以下几点：

```bash
# 1. 检查文件是否存在
ls -la .git/hooks/pre-commit

# 2. 检查是否有执行权限
chmod +x .git/hooks/pre-commit

# 3. 检查文件名是否正确（没有 .sample 后缀）
mv .git/hooks/pre-commit.sample .git/hooks/pre-commit

# 4. 检查 shebang 行
head -1 .git/hooks/pre-commit
# 应该是 #!/bin/bash 或 #!/usr/bin/env node

# 5. 检查 core.hooksPath 配置
git config core.hooksPath

# 6. 检查脚本语法
bash -n .git/hooks/pre-commit
```

### Q3: 如何在团队中共享 Hooks？

**A:** 有多种方案：

**方案 1: 使用 core.hooksPath**
```bash
# 将 hooks 放在仓库中
mkdir .githooks
cp .git/hooks/pre-commit .githooks/

# 配置使用新目录
git config core.hooksPath .githooks

# 在 package.json 中自动配置
{
  "scripts": {
    "prepare": "git config core.hooksPath .githooks"
  }
}
```

**方案 2: 使用 Husky（Node.js 项目）**
```bash
npm install husky --save-dev
npx husky init
```

**方案 3: 使用 lefthook（多语言项目）**
```bash
npm install lefthook --save-dev
npx lefthook install
```

### Q4: Hooks 中如何获取更多 Git 信息？

**A:** 使用 git 命令获取各种信息：

```bash
# 当前分支
git symbolic-ref --short HEAD

# 当前提交
git rev-parse HEAD

# 暂存的文件
git diff --cached --name-only

# 最近的 tag
git describe --tags --abbrev=0

# 仓库根目录
git rev-parse --show-toplevel

# 检查是否在 rebase 中
[ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]

# 检查是否在合并中
[ -f .git/MERGE_HEAD ]

# 远程仓库 URL
git remote get-url origin

# 当前用户
git config user.name
git config user.email
```

### Q5: 如何在 Hooks 中处理合并提交？

**A:** 在 commit-msg 和 pre-commit 中检测并处理：

```bash
#!/bin/bash
# 检测合并提交

# 方法 1: 检查 MERGE_HEAD 文件
if [ -f .git/MERGE_HEAD ]; then
    echo "这是一个合并提交"
    exit 0  # 跳过检查
fi

# 方法 2: 在 commit-msg 中检查消息
COMMIT_MSG=$(cat "$1")
if echo "$COMMIT_MSG" | grep -q "^Merge"; then
    echo "合并提交，跳过验证"
    exit 0
fi

# 方法 3: 在 prepare-commit-msg 中检查来源
if [ "$2" = "merge" ]; then
    echo "合并提交"
    exit 0
fi
```

### Q6: Windows 环境下如何使用 Hooks？

**A:** Windows 有几点需要注意：

1. **使用 Git Bash 或 WSL**
   - Hooks 脚本在 Git Bash 中运行
   - 确保使用 Unix 换行符 (LF)

2. **处理路径**
   ```bash
   # Windows 路径转换
   WINDOWS_PATH=$(cygpath -w "$UNIX_PATH")
   ```

3. **使用 Node.js 或 TypeScript 写 Hooks**
   ```typescript
   #!/usr/bin/env npx tsx
   // 跨平台 hook
   import { execSync } from 'child_process';
   // ...
   ```

4. **配置 Git 使用正确的 shell**
   ```bash
   git config core.autocrlf false
   ```

### Q7: 如何测试 Hooks？

**A:** 创建测试脚本或使用测试框架：

```bash
#!/bin/bash
# test-hooks.sh
# Hooks 测试脚本

set -e

echo "测试 pre-commit hook..."

# 创建测试环境
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"
git init

# 复制 hook
cp /path/to/pre-commit .git/hooks/
chmod +x .git/hooks/pre-commit

# 测试用例 1: 正常提交
echo "console.log('test');" > test.js
git add test.js
if git commit -m "test: normal commit"; then
    echo "✅ 测试 1 通过"
else
    echo "❌ 测试 1 失败"
fi

# 测试用例 2: 包含调试代码
echo "debugger;" >> test.js
git add test.js
if git commit -m "test: with debugger" 2>/dev/null; then
    echo "❌ 测试 2 失败：应该阻止包含 debugger 的提交"
else
    echo "✅ 测试 2 通过：正确阻止了提交"
fi

# 清理
rm -rf "$TEST_DIR"
echo "所有测试完成"
```

---

## 8. 工具推荐

### 8.1 Husky

[Husky](https://typicode.github.io/husky/) 是 Node.js 项目中最流行的 Git Hooks 管理工具。

**安装**：
```bash
npm install husky --save-dev
npx husky init
```

**配置示例**：
```bash
# .husky/pre-commit
npm test
npm run lint
```

### 8.2 lint-staged

[lint-staged](https://github.com/okonet/lint-staged) 专门用于对暂存文件运行 linters。

**安装**：
```bash
npm install lint-staged --save-dev
```

**配置示例** (`package.json`)：
```json
{
  "lint-staged": {
    "*.{ts,tsx}": [
      "eslint --fix",
      "prettier --write"
    ],
    "*.{js,jsx}": [
      "eslint --fix",
      "prettier --write"
    ],
    "*.{json,md}": [
      "prettier --write"
    ]
  }
}
```

**配合 Husky 使用**：
```bash
# .husky/pre-commit
npx lint-staged
```

### 8.3 lefthook

[Lefthook](https://github.com/evilmartians/lefthook) 是一个快速的多语言 Git Hooks 管理器。

**安装**：
```bash
# npm
npm install lefthook --save-dev

# 或 homebrew
brew install lefthook
```

**配置示例** (`lefthook.yml`)：
```yaml
pre-commit:
  parallel: true
  commands:
    lint:
      glob: "*.{js,ts}"
      run: npm run lint {staged_files}
    test:
      run: npm test

commit-msg:
  commands:
    validate:
      run: npx commitlint --edit {1}
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

| Hook | 触发时机 | 可阻止操作 | 常见用途 |
|------|----------|-----------|----------|
| pre-commit | commit 前 | ✅ | 代码检查、格式化 |
| prepare-commit-msg | 生成消息后 | ✅ | 自动生成提交信息 |
| commit-msg | 输入消息后 | ✅ | 验证提交信息格式 |
| post-commit | commit 后 | ❌ | 通知、统计 |
| pre-merge-commit | merge 后、提交前 | ✅ | 合并前验证 |
| pre-rebase | rebase 前 | ✅ | 保护分支 |
| post-checkout | checkout 后 | ❌ | 安装依赖、清理缓存 |
| post-merge | merge 后 | ❌ | 更新依赖 |
| pre-push | push 前 | ✅ | 运行测试、验证 |
| pre-auto-gc | gc 前 | ✅ | 控制 GC 时机 |
| post-rewrite | 重写提交后 | ❌ | 更新相关引用 |

#### 服务端 Hooks

| Hook | 触发时机 | 可阻止操作 | 常见用途 |
|------|----------|-----------|----------|
| pre-receive | 接收 push 前 | ✅ | 权限验证、策略检查 |
| update | 更新引用前 | ✅ | 分支级权限控制 |
| post-receive | 接收 push 后 | ❌ | CI/CD、通知、部署 |
| post-update | 更新后 | ❌ | 更新服务器信息 |
| push-to-checkout | 推送到工作区前 | ✅ | 自定义检出逻辑 |

希望本指南能帮助你更好地理解和使用 Git Hooks，构建更高效的开发工作流！
