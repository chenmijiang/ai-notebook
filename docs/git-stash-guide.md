# Git Stash 完全指南

## 功能介绍

### 什么是 Git Stash？

`git stash` 是 Git 中一个非常实用的临时存储命令，它可以将当前工作目录和暂存区中的未提交更改保存到一个临时区域（stash 栈），让你的工作目录恢复到干净状态。之后你可以随时恢复这些更改继续工作。Stash 就像一个"暂存抽屉"，让你可以快速切换上下文而不丢失正在进行的工作。

### 工作原理

Stash 的核心工作原理如下：

```
┌─────────────────────────────────────────────────────────────────┐
│                      git stash 工作流程                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Working Directory        Index            Stash Stack         │
│      (工作目录)           (暂存区)           (储藏栈)            │
│          │                   │                  │               │
│          │    git stash      │                  │               │
│          ├───────────────────┼─────────────────►│               │
│          │                   │                  │               │
│          │   git stash pop   │                  │               │
│          │◄──────────────────┼──────────────────┤               │
│          │                   │                  │               │
└─────────────────────────────────────────────────────────────────┘
```

1. **保存更改**：`git stash` 将工作目录和暂存区的更改打包保存到 stash 栈中
2. **清理工作区**：保存后，工作目录和暂存区恢复到 HEAD 的状态（干净状态）
3. **栈式存储**：多次 stash 的内容按照栈（LIFO）的方式存储，最新的在最上面
4. **恢复更改**：使用 `pop` 或 `apply` 将保存的更改恢复到工作目录

#### Stash 存储结构

```
Stash Stack (储藏栈)
┌────────────────────────┐
│ stash@{0}: 最新的储藏   │  ◄── 栈顶（最后进入）
├────────────────────────┤
│ stash@{1}: 较早的储藏   │
├────────────────────────┤
│ stash@{2}: 更早的储藏   │
├────────────────────────┤
│        ...             │
└────────────────────────┘  ◄── 栈底（最早进入）
```

#### Stash 保存的内容

默认情况下，`git stash` 会保存：

- ✅ 已跟踪文件的修改（modified tracked files）
- ✅ 暂存区的更改（staged changes）

不会保存：

- ❌ 未跟踪的新文件（untracked files）—— 除非使用 `-u` 选项
- ❌ 被忽略的文件（ignored files）—— 除非使用 `-a` 选项

### 应用场景

在以下情况下，`git stash` 特别有用：

- 需要紧急切换分支处理其他任务，但当前工作未完成
- 想要拉取远程更新，但本地有未提交的更改
- 临时保存实验性代码，稍后决定是否保留
- 需要在不同分支间移动未完成的工作
- 清理工作目录进行其他操作（如 rebase）后恢复

## 基本用法

### 命令语法

```bash
git stash [push [-p|--patch] [-k|--[no-]keep-index] [-u|--include-untracked] [-a|--all] [-q|--quiet] [-m|--message <message>] [--] [<pathspec>...]]
git stash list [<options>]
git stash show [<stash>]
git stash pop [--index] [-q|--quiet] [<stash>]
git stash apply [--index] [-q|--quiet] [<stash>]
git stash drop [-q|--quiet] [<stash>]
git stash clear
git stash branch <branchname> [<stash>]
```

### 基本参数说明

**主要子命令**：

| 子命令   | 作用                                 |
| -------- | ------------------------------------ |
| `push`   | 保存更改到 stash（默认行为，可省略） |
| `list`   | 列出所有 stash 条目                  |
| `show`   | 显示 stash 的内容差异                |
| `pop`    | 恢复并删除最近的 stash               |
| `apply`  | 恢复但保留 stash                     |
| `drop`   | 删除指定的 stash                     |
| `clear`  | 清空所有 stash                       |
| `branch` | 基于 stash 创建新分支                |

**常用选项**：

- `-m, --message <msg>`：为 stash 添加描述信息
- `-u, --include-untracked`：同时保存未跟踪的文件
- `-a, --all`：保存所有文件，包括被忽略的文件
- `-k, --keep-index`：保留暂存区的状态
- `-p, --patch`：交互式选择要 stash 的内容
- `--index`：恢复时同时恢复暂存区状态

### 简单示例

```bash
# 1. 查看当前状态
git status
# Changes to be committed:
#   modified: src/staged-file.js
# Changes not staged for commit:
#   modified: src/working-file.js

# 2. 保存所有更改到 stash
git stash
# 或带描述信息
git stash push -m "WIP: 用户认证功能开发中"

# 3. 确认工作目录已清理
git status
# On branch main
# nothing to commit, working tree clean

# 4. 查看 stash 列表
git stash list
# stash@{0}: WIP on main: a1b2c3d WIP: 用户认证功能开发中

# 5. 切换分支处理其他任务
git checkout hotfix-branch
# ... 处理紧急任务 ...
git checkout main

# 6. 恢复之前的工作
git stash pop
# 或者只应用不删除
git stash apply

# 7. 验证更改已恢复
git status
```

## 日常开发场景

### 场景 1：紧急切换分支处理 Bug

**问题描述**：
你正在 `feature/new-dashboard` 分支上开发新功能，代码写了一半还没准备好提交。这时接到紧急通知，需要立即切换到 `main` 分支修复一个生产环境的 bug。

**解决方案**：

```bash
# 1. 当前在 feature 分支，有未完成的工作
git status
# On branch feature/new-dashboard
# Changes not staged for commit:
#   modified: src/dashboard/Chart.js
#   modified: src/dashboard/Stats.js

# 2. 保存当前工作到 stash
git stash push -m "WIP: dashboard 图表组件开发中"

# 3. 确认工作目录干净
git status
# nothing to commit, working tree clean

# 4. 切换到 main 分支
git checkout main

# 5. 创建 hotfix 分支并修复 bug
git checkout -b hotfix/critical-bug
# ... 修复 bug ...
git add .
git commit -m "fix: 修复关键 bug"

# 6. 合并到 main 并推送
git checkout main
git merge hotfix/critical-bug
git push origin main

# 7. 回到 feature 分支继续工作
git checkout feature/new-dashboard

# 8. 恢复之前的工作
git stash pop

# 9. 继续开发
git status
# Changes not staged for commit:
#   modified: src/dashboard/Chart.js
#   modified: src/dashboard/Stats.js
```

**优点**：

- 无需创建临时提交（如 "WIP" 提交）
- 工作进度完整保留
- 快速切换上下文

### 场景 2：拉取远程更新前保存本地更改

**问题描述**：
你修改了一些文件但还没准备好提交，现在想要拉取团队成员推送的最新代码。直接 `git pull` 可能会因为冲突而失败。

**解决方案**：

```bash
# 1. 尝试直接 pull（可能失败）
git pull
# error: Your local changes to the following files would be overwritten by merge:
#   src/config.js
# Please commit your changes or stash them before you merge.

# 2. 保存本地更改
git stash push -m "保存本地更改以便 pull"

# 3. 拉取远程更新
git pull origin main
# 成功拉取

# 4. 恢复本地更改
git stash pop

# 5. 如果有冲突，手动解决
# Auto-merging src/config.js
# CONFLICT (content): Merge conflict in src/config.js
#
# 编辑冲突文件解决冲突
vim src/config.js
git add src/config.js

# 6. 完成
git status
```

**使用 `--autostash` 简化流程**：

```bash
# 方法 1：单次使用
git pull --autostash

# 方法 2：配置为默认行为
git config --global rebase.autoStash true
git config --global merge.autoStash true

# 之后 pull 会自动 stash 和 pop
git pull
```

### 场景 3：保存包含新文件的工作进度

**问题描述**：
你创建了一些新文件（未跟踪文件），同时也修改了已有文件。默认的 `git stash` 不会保存未跟踪的文件，导致这些新文件会留在工作目录中。

**解决方案**：

```bash
# 1. 查看当前状态
git status
# Changes not staged for commit:
#   modified: src/app.js
# Untracked files:
#   src/new-feature.js
#   src/new-utils.js

# 2. 使用 -u 选项包含未跟踪文件
git stash push -u -m "WIP: 包含新文件的功能开发"
# 或使用长选项
git stash push --include-untracked -m "WIP: 包含新文件的功能开发"

# 3. 确认所有文件都被保存
git status
# nothing to commit, working tree clean
# 新文件也不见了

# 4. 恢复时，所有文件都会回来
git stash pop
git status
# Changes not staged for commit:
#   modified: src/app.js
# Untracked files:
#   src/new-feature.js
#   src/new-utils.js
```

**选项对比**：

| 选项                         | 保存已跟踪文件 | 保存未跟踪文件 | 保存忽略文件 |
| ---------------------------- | -------------- | -------------- | ------------ |
| 默认                         | ✅             | ❌             | ❌           |
| `-u` / `--include-untracked` | ✅             | ✅             | ❌           |
| `-a` / `--all`               | ✅             | ✅             | ✅           |

### 场景 4：只 Stash 部分文件

**问题描述**：
你修改了多个文件，但只想 stash 其中几个文件的更改，其他文件的更改保留在工作目录中继续处理。

**解决方案**：

```bash
# 1. 查看当前更改
git status
# Changes not staged for commit:
#   modified: src/feature-a.js  # 想要 stash
#   modified: src/feature-b.js  # 想要 stash
#   modified: src/bug-fix.js    # 想要保留继续处理

# 方法 A：指定文件路径
git stash push -m "WIP: feature A 和 B" -- src/feature-a.js src/feature-b.js

# 方法 B：使用交互式选择（-p / --patch）
git stash push -p -m "选择性 stash"
# Git 会逐个显示更改，询问是否 stash
# y - stash 这个更改
# n - 不 stash
# s - 分割成更小的块
# q - 退出，不 stash 剩余的

# 方法 C：使用目录
git stash push -m "stash src 目录的更改" -- src/features/

# 2. 验证结果
git status
# Changes not staged for commit:
#   modified: src/bug-fix.js  # 保留在工作目录
```

### 场景 5：管理多个 Stash

**问题描述**：
你在不同时间保存了多个 stash，现在需要查看、选择和恢复特定的 stash，而不仅仅是最新的那个。

**解决方案**：

```bash
# 1. 查看所有 stash
git stash list
# stash@{0}: On main: WIP: 用户设置页面
# stash@{1}: On feature: WIP: API 重构
# stash@{2}: On main: WIP: 登录功能

# 2. 查看特定 stash 的内容概要
git stash show stash@{1}
# src/api/client.js | 15 +++++++++------
# src/api/utils.js  |  8 ++++++++
# 2 files changed, 17 insertions(+), 6 deletions(-)

# 3. 查看特定 stash 的详细 diff
git stash show -p stash@{1}
# 显示完整的 diff 内容

# 4. 应用特定的 stash（不删除）
git stash apply stash@{1}

# 5. 或者弹出特定的 stash（应用并删除）
git stash pop stash@{2}

# 6. 删除不需要的 stash
git stash drop stash@{0}

# 7. 清空所有 stash（谨慎使用！）
git stash clear
```

**为 Stash 添加描述的重要性**：

```bash
# ❌ 不好的做法：没有描述
git stash
git stash
git stash
# stash@{0}: WIP on main: a1b2c3d commit message
# stash@{1}: WIP on main: a1b2c3d commit message
# stash@{2}: WIP on main: a1b2c3d commit message
# 很难区分这些 stash 是什么

# ✅ 好的做法：添加描述
git stash push -m "WIP: 用户注册表单验证"
git stash push -m "WIP: 邮件模板修改"
git stash push -m "实验: 新的缓存策略"
# stash@{0}: On main: 实验: 新的缓存策略
# stash@{1}: On main: WIP: 邮件模板修改
# stash@{2}: On main: WIP: 用户注册表单验证
# 清晰明了
```

### 场景 6：基于 Stash 创建新分支

**问题描述**：
你保存了一些更改到 stash，后来发现这些更改应该在一个独立的功能分支上进行。或者你想在恢复 stash 时避免可能的冲突。

**解决方案**：

```bash
# 1. 查看 stash 列表
git stash list
# stash@{0}: On main: WIP: 新功能原型

# 2. 基于 stash 创建新分支
git stash branch feature/new-prototype stash@{0}

# 这个命令等同于：
# git checkout -b feature/new-prototype <stash 创建时的提交>
# git stash apply stash@{0}
# git stash drop stash@{0}

# 3. 现在你在新分支上，stash 的更改已应用
git status
# On branch feature/new-prototype
# Changes not staged for commit:
#   modified: src/prototype.js

# 4. 该 stash 已自动删除
git stash list
# (stash@{0} 不存在了)
```

**这个命令的优势**：

- 自动切换到 stash 创建时的提交点
- 避免因为分支已经前进而产生的冲突
- 一步完成分支创建、应用、删除

## 常用命令

### 基本 Stash 命令

```bash
# 保存更改（最简单形式）
git stash
# 等同于
git stash push

# 保存并添加描述信息
git stash push -m "描述信息"
git stash push --message "描述信息"

# 保存包括未跟踪文件
git stash push -u
git stash push --include-untracked

# 保存所有文件（包括忽略的文件）
git stash push -a
git stash push --all

# 保存时保留暂存区状态
git stash push -k
git stash push --keep-index

# 只 stash 暂存区的内容
git stash push -S
git stash push --staged

# 交互式选择要 stash 的内容
git stash push -p
git stash push --patch

# stash 特定文件
git stash push -- <file1> <file2>
git stash push -m "message" -- path/to/file
```

### 查看 Stash 命令

```bash
# 列出所有 stash
git stash list

# 列出 stash 并显示更多信息
git stash list --stat

# 查看最近 stash 的内容概要
git stash show
# 等同于
git stash show stash@{0}

# 查看特定 stash 的内容概要
git stash show stash@{2}

# 查看 stash 的详细 diff
git stash show -p
git stash show --patch
git stash show -p stash@{1}

# 查看 stash 包含的未跟踪文件
git stash show --include-untracked stash@{0}

# 以特定格式显示 stash 列表
git stash list --format="%gd: %gs"
```

### 恢复 Stash 命令

```bash
# 恢复最近的 stash 并删除它
git stash pop

# 恢复特定的 stash 并删除它
git stash pop stash@{2}

# 恢复最近的 stash 但保留它
git stash apply

# 恢复特定的 stash 但保留它
git stash apply stash@{1}

# 恢复时同时恢复暂存区状态
git stash pop --index
git stash apply --index

# 静默恢复（不显示状态）
git stash pop -q
git stash pop --quiet
```

### 删除 Stash 命令

```bash
# 删除最近的 stash
git stash drop

# 删除特定的 stash
git stash drop stash@{2}

# 清空所有 stash（⚠️ 危险！不可恢复）
git stash clear
```

### 高级用法

```bash
# 基于 stash 创建新分支
git stash branch <branch-name>
git stash branch <branch-name> stash@{n}

# 从 stash 中恢复单个文件
git checkout stash@{0} -- <file-path>
# 或使用现代语法
git restore --source=stash@{0} -- <file-path>

# 查看 stash 中特定文件的内容
git show stash@{0}:<file-path>

# 比较 stash 与当前工作目录
git diff stash@{0}

# 比较两个 stash
git diff stash@{0} stash@{1}

# 将 stash 应用到不同分支
git checkout other-branch
git stash apply stash@{0}

# 创建 stash 但不清理工作目录（用于备份）
git stash store $(git stash create "backup message")
```

### 配合其他命令使用

```bash
# 配合 pull 使用自动 stash
git pull --autostash
git pull --rebase --autostash

# 配合 rebase 使用自动 stash
git rebase --autostash main

# 配置全局自动 stash
git config --global rebase.autoStash true

# 在 merge 时自动 stash
git config --global merge.autoStash true

# 查看 stash 相关配置
git config --list | grep -i stash
```

### 查询和检查命令

```bash
# 检查是否有 stash
git stash list | head -1

# 统计 stash 数量
git stash list | wc -l

# 查看 stash 是在哪个分支创建的
git stash list --format="%gd %gs"

# 查看 stash 创建的时间
git stash list --date=relative

# 查看 stash 的完整哈希
git stash list --format="%H %gd %gs"

# 搜索 stash 中包含特定内容的
git stash list | while read stash; do
  echo "=== $stash ==="
  git stash show -p "${stash%%:*}" 2>/dev/null | grep -l "搜索内容"
done
```

---

## 最佳实践和注意事项

### 最佳实践

#### 1. 始终为 Stash 添加描述信息

```bash
# ❌ 不推荐
git stash

# ✅ 推荐
git stash push -m "WIP: 用户登录功能 - 表单验证完成"

# 描述信息应包含：
# - 工作状态（WIP、实验、备份等）
# - 功能/模块名称
# - 进度或要点
```

#### 2. 及时处理 Stash，避免积累

```bash
# 定期检查 stash 列表
git stash list

# 如果 stash 太多，逐个处理
# 1. 查看每个 stash 的内容
git stash show -p stash@{n}

# 2. 决定是应用、创建分支还是删除
git stash pop stash@{n}      # 需要的
git stash branch feature stash@{n}  # 应该独立的
git stash drop stash@{n}     # 不需要的

# 设置提醒：如果 stash 超过 5 个，考虑清理
if [ $(git stash list | wc -l) -gt 5 ]; then
  echo "⚠️ 你有太多 stash 了，考虑清理一下"
fi
```

#### 3. 使用 `--keep-index` 进行分步提交

```bash
# 场景：你有暂存和未暂存的更改，想先提交暂存的部分

# 1. 暂存要提交的文件
git add src/feature.js

# 2. Stash 未暂存的更改，但保留暂存区
git stash push --keep-index -m "暂存未完成的工作"

# 3. 现在可以测试只包含暂存更改的代码
npm test

# 4. 如果测试通过，提交
git commit -m "feat: 完成某功能"

# 5. 恢复未完成的工作
git stash pop
```

#### 4. 使用 `apply` 而不是 `pop` 进行安全恢复

```bash
# ❌ 有风险：如果恢复失败或有冲突，stash 可能丢失
git stash pop

# ✅ 更安全：先 apply，确认无误后再 drop
git stash apply stash@{0}
# 检查一切正常...
git status
# 确认后删除
git stash drop stash@{0}
```

#### 5. 在复杂操作前先 Stash

```bash
# 在以下操作前，建议先 stash 未提交的更改：

# Rebase 前
git stash push -m "rebase 前备份"
git rebase main
git stash pop

# Merge 前
git stash push -m "merge 前备份"
git merge feature-branch
git stash pop

# 或者使用 --autostash
git rebase --autostash main
git merge --autostash feature-branch
```

#### 6. 配合别名提高效率

```bash
# 在 ~/.gitconfig 中添加别名
[alias]
    # 快速 stash
    ss = stash push -m
    # 查看 stash 列表
    sl = stash list
    # 查看 stash 内容
    sshow = stash show -p
    # 应用最近的 stash
    sa = stash apply
    # 弹出最近的 stash
    sp = stash pop
    # 删除最近的 stash
    sd = stash drop

# 使用示例
git ss "WIP: 功能开发中"
git sl
git sshow
git sp
```

### 注意事项

#### ⚠️ 1. Stash 可能产生冲突

```bash
# 场景：stash 后分支有新提交，恢复时可能冲突

# 保存 stash
git stash push -m "我的更改"

# ... 其他提交改变了相同的文件 ...

# 恢复时发生冲突
git stash pop
# Auto-merging src/config.js
# CONFLICT (content): Merge conflict in src/config.js
# The stash entry is kept in case you need it again.

# 注意：发生冲突时，stash 不会被自动删除！

# 解决冲突
vim src/config.js
git add src/config.js

# 手动删除 stash
git stash drop
```

#### ⚠️ 2. Stash 不会保存未跟踪文件（默认）

```bash
# 默认行为
git stash
# 未跟踪的文件仍然留在工作目录！

# 确保包含未跟踪文件
git stash push -u -m "包含新文件"
# 或
git stash push --include-untracked

# 如果忘记了，可以：
# 1. 先 add 未跟踪文件
git add new-file.js
git stash
# 2. 或者重新 stash
git stash pop
git stash push -u
```

#### ⚠️ 3. `git stash clear` 不可恢复

```bash
# ⚠️ 危险操作！
git stash clear
# 所有 stash 永久删除，无法通过 reflog 恢复

# 安全做法：逐个删除，确认每个 stash 内容
git stash list
git stash show -p stash@{0}
git stash drop stash@{0}
# 重复直到清空
```

#### ⚠️ 4. Stash 与暂存区状态

```bash
# 默认情况下，stash 恢复时不会保留暂存区状态

# 保存时的状态
git add file1.js
# file1.js 在暂存区
# file2.js 已修改但未暂存

git stash

# 恢复时
git stash pop
# 所有文件都变成未暂存状态！

# 如果需要保留暂存区状态
git stash pop --index
# file1.js 恢复到暂存区
# file2.js 恢复为未暂存
```

#### ⚠️ 5. Stash 的作用域是整个仓库

```bash
# Stash 不是分支特定的，它属于整个仓库

# 在 feature 分支创建 stash
git checkout feature
git stash push -m "feature 分支的更改"

# 切换到 main 分支
git checkout main

# 仍然可以看到并应用那个 stash
git stash list
# stash@{0}: On feature: feature 分支的更改

# 可以应用到 main 分支（可能会有冲突）
git stash apply
```

#### ⚠️ 6. 长期保存工作不要用 Stash

```bash
# ❌ 不推荐：使用 stash 长期保存工作
git stash push -m "等下周再继续"
# stash 容易被遗忘、误删或产生冲突

# ✅ 推荐：创建 WIP 分支
git checkout -b wip/feature-backup
git add .
git commit -m "WIP: 保存当前进度"

# 需要时回来继续
git checkout wip/feature-backup
```

### 冲突解决策略

当 stash pop/apply 产生冲突时：

```bash
# 1. 查看冲突文件
git status
# Unmerged paths:
#   both modified: src/config.js

# 2. 解决冲突
vim src/config.js
# 编辑文件，解决冲突标记

# 3. 标记为已解决
git add src/config.js

# 4. 注意：冲突时 stash 不会自动删除
git stash list
# stash@{0} 仍然存在

# 5. 确认解决后手动删除 stash
git stash drop stash@{0}
```

### 团队协作建议

1. **不要将 stash 作为代码分享方式**：

```bash
# ❌ Stash 是本地的，无法推送
git stash push -m "给同事看的代码"
# 同事无法访问这个 stash

# ✅ 使用分支分享代码
git checkout -b feature/for-review
git add .
git commit -m "WIP: 请帮忙 review"
git push origin feature/for-review
```

2. **文档化工作流程**：

```bash
# 在团队 wiki 或 CONTRIBUTING.md 中说明

## 紧急切换任务时
1. 使用 `git stash push -u -m "描述"` 保存当前工作
2. 处理紧急任务
3. 使用 `git stash pop` 恢复工作
4. 如有冲突，解决后 `git stash drop`
```

---

## Git Stash vs 其他保存方式

### Stash vs WIP Commit

| 特性         | Stash                | WIP Commit      |
| ------------ | -------------------- | --------------- |
| **持久性**   | 临时，可能被清理     | 永久，在历史中  |
| **可见性**   | 仅本地               | 可推送分享      |
| **分支关联** | 无，全局可用         | 绑定到特定分支  |
| **查找难度** | 较难，需要记得 stash | 容易，在 log 中 |
| **合并方式** | pop/apply            | merge/rebase    |
| **适用场景** | 短期临时保存         | 长期或需分享    |

```bash
# Stash 方式
git stash push -m "WIP"
# ... 其他工作 ...
git stash pop

# WIP Commit 方式
git add .
git commit -m "WIP: 临时保存"
# ... 其他工作 ...
git reset --soft HEAD~1  # 撤销 WIP 提交但保留更改
```

### Stash vs 临时分支

| 特性         | Stash              | 临时分支       |
| ------------ | ------------------ | -------------- |
| **创建速度** | 快，一条命令       | 稍慢，需要多步 |
| **组织性**   | 栈式，难以管理多个 | 分支名清晰     |
| **冲突处理** | pop 时可能冲突     | merge 时处理   |
| **长期保存** | 不推荐             | 推荐           |
| **代码审查** | 不支持             | 支持（PR）     |

```bash
# Stash 方式
git stash push -u -m "feature backup"

# 临时分支方式
git checkout -b backup/feature-$(date +%Y%m%d)
git add .
git commit -m "Backup: feature 进度"
git checkout main
```

### 选择指南

```bash
# 📋 选择流程图

# 需要保存多长时间？
# ├─ 几分钟到几小时 → Stash（快速便捷）
# ├─ 几天 → WIP Commit 或临时分支
# └─ 更长或需要分享 → 临时分支

# 需要与他人分享吗？
# ├─ 是 → 临时分支 + 推送
# └─ 否 → Stash 或 WIP Commit

# 更改是否应该保留在历史中？
# ├─ 是 → 正式 Commit
# └─ 否（实验性质）→ Stash

# 是否涉及未跟踪文件？
# ├─ 是 → Stash -u 或分支
# └─ 否 → 普通 Stash
```

---

## 总结

`git stash` 是一个灵活实用的临时存储工具，正确使用它可以：

- ✅ 快速保存未完成的工作，干净地切换上下文
- ✅ 在拉取更新前暂存本地更改，避免冲突
- ✅ 临时保存实验性代码，便于后续取舍
- ✅ 灵活管理多个工作进度
- ✅ 配合分支操作，创建基于 stash 的新分支

但也要注意：

- ⚠️ Stash 不适合长期保存工作（使用分支代替）
- ⚠️ 默认不保存未跟踪文件（需要 `-u` 选项）
- ⚠️ `git stash clear` 不可恢复
- ⚠️ 恢复时可能产生冲突，需要手动解决
- ⚠️ 始终为 stash 添加描述信息
- ⚠️ 及时处理 stash，避免积累

### 快速参考表

| 场景                | 命令                        | 说明                 |
| ------------------- | --------------------------- | -------------------- |
| 快速保存所有更改    | `git stash`                 | 保存已跟踪文件的更改 |
| 保存并添加描述      | `git stash push -m "描述"`  | 推荐始终使用         |
| 包含新文件          | `git stash push -u`         | 包含未跟踪文件       |
| 只 stash 部分文件   | `git stash push -- <files>` | 指定文件路径         |
| 查看 stash 列表     | `git stash list`            | 查看所有保存的 stash |
| 查看 stash 内容     | `git stash show -p`         | 显示详细 diff        |
| 恢复并删除          | `git stash pop`             | 最常用的恢复方式     |
| 恢复但保留          | `git stash apply`           | 更安全的恢复方式     |
| 删除指定 stash      | `git stash drop stash@{n}`  | 删除不需要的 stash   |
| 基于 stash 创建分支 | `git stash branch <name>`   | 避免冲突的好方法     |

### 黄金法则

> **Stash 是临时存储，不是长期备份。超过一天的工作应该使用分支。**

> **始终为 stash 添加描述，你的未来自己会感谢你的。**

合理使用 `git stash`，让你的 Git 工作流更加顺畅高效！

---

## 参考资源

- [Git 官方文档 - git-stash](https://git-scm.com/docs/git-stash)
- [Pro Git Book - 贮藏与清理](https://git-scm.com/book/zh/v2/Git-%E5%B7%A5%E5%85%B7-%E8%B4%AE%E8%97%8F%E4%B8%8E%E6%B8%85%E7%90%86)
- [Atlassian Git Tutorial - Git Stash](https://www.atlassian.com/git/tutorials/saving-changes/git-stash)
