# Git Reset 完全指南

## 功能介绍

### 什么是 Git Reset？

`git reset` 是 Git 中一个强大的撤销命令，它可以将当前分支的 HEAD 指针移动到指定的提交，并根据不同的模式选择性地更新暂存区（Index）和工作目录（Working Directory）。Reset 是一种"后退"操作，它可以撤销提交、取消暂存，甚至完全重置工作状态。

### 工作原理

要理解 `git reset` 的工作原理，首先需要了解 Git 的"三棵树"架构：

#### Git 的三棵树

```
┌─────────────────────────────────────────────────────────────────┐
│                        Git 三棵树架构                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   HEAD                 Index                Working Directory   │
│  (当前提交)           (暂存区)               (工作目录)         │
│      │                    │                      │              │
│      ▼                    ▼                      ▼              │
│   ┌─────┐            ┌─────┐                ┌─────┐             │
│   │ v3  │◄───────────│ v3  │◄───────────────│ v3  │             │
│   └─────┘   commit   └─────┘      add       └─────┘             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

1. **HEAD（当前提交）**：指向当前分支的最新提交，代表上次提交的快照
2. **Index（暂存区/索引）**：保存了下次将要提交的内容，即 `git add` 后的状态
3. **Working Directory（工作目录）**：实际的文件系统，你正在编辑的文件

#### Reset 如何操作这三棵树

`git reset` 按照以下顺序操作这三棵树：

```
┌──────────────────────────────────────────────────────────────────┐
│                    git reset 操作流程                            │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  步骤 1: 移动 HEAD（所有模式都会执行）                           │
│          HEAD 指针移动到指定的提交                               │
│                     │                                            │
│                     ▼                                            │
│  步骤 2: 更新 Index（--mixed 和 --hard 会执行）                  │
│          使 Index 的内容与 HEAD 指向的提交一致                   │
│                     │                                            │
│                     ▼                                            │
│  步骤 3: 更新 Working Directory（仅 --hard 会执行）              │
│          使工作目录的内容与 HEAD 指向的提交一致                  │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

#### 三种模式对比

| 模式              | HEAD   | Index（暂存区） | Working Directory（工作目录） | 数据安全 |
| ----------------- | ------ | --------------- | ----------------------------- | -------- |
| `--soft`          | ✓ 移动 | 保持不变        | 保持不变                      | ✅ 安全  |
| `--mixed`（默认） | ✓ 移动 | ✓ 重置          | 保持不变                      | ✅ 安全  |
| `--hard`          | ✓ 移动 | ✓ 重置          | ✓ 重置                        | ❌ 危险  |

**图解说明**：

```
假设当前状态：HEAD 指向 C，有一些未提交的更改

A --- B --- C (HEAD)
              │
              ├── Index: 有已暂存的更改
              └── Working Directory: 有未暂存的更改

执行 git reset --soft B 后：
A --- B (HEAD) --- C
              │
              ├── Index: 保持原有暂存更改 + C 的更改变为已暂存
              └── Working Directory: 保持原有更改

执行 git reset --mixed B 后（默认）：
A --- B (HEAD) --- C
              │
              ├── Index: 清空（C 的更改变为未暂存）
              └── Working Directory: 保持原有更改 + C 的更改

执行 git reset --hard B 后：
A --- B (HEAD) --- C
              │
              ├── Index: 清空
              └── Working Directory: 完全重置为 B 的状态（⚠️ 更改丢失！）
```

### 应用场景

在以下情况下，`git reset` 特别有用：

- 撤销本地尚未推送的错误提交
- 取消已暂存的文件（`git add` 的逆操作）
- 将多个小提交合并成一个大提交
- 清理混乱的工作目录和暂存区
- 撤销错误的本地合并操作
- 重新组织提交历史

## 基本用法

### 命令语法

```bash
git reset [<mode>] [<commit>]
git reset [<mode>] [<commit>] -- <pathspec>...
```

### 基本参数说明

```bash
git reset [options] [<commit>] [-- <paths>...]
```

**模式选项**：

- `--soft`：只移动 HEAD 指针，不改变暂存区和工作目录
- `--mixed`：移动 HEAD 并重置暂存区，但保留工作目录（**默认模式**）
- `--hard`：移动 HEAD 并重置暂存区和工作目录（⚠️ **危险操作**）
- `--merge`：重置暂存区并更新工作目录中与 `<commit>` 和 HEAD 不同的文件，但保留工作目录中未暂存的更改
- `--keep`：重置暂存区并更新工作目录中与 `<commit>` 和 HEAD 不同的文件，如果有本地更改会中止

**提交引用方式**：

- `HEAD`：当前提交
- `HEAD~1` 或 `HEAD~`：上一个提交
- `HEAD~N`：往前数第 N 个提交
- `HEAD^`：第一个父提交
- `<commit-hash>`：指定的提交哈希值
- `<branch-name>`：指定分支的最新提交
- `ORIG_HEAD`：危险操作前的 HEAD 位置（由 reset、merge、rebase 等命令设置）

### 简单示例

```bash
# 1. 查看当前提交历史
git log --oneline -5

# 2. 撤销最近一次提交，但保留更改在暂存区
git reset --soft HEAD~1

# 3. 撤销最近一次提交，更改变为未暂存状态（默认行为）
git reset HEAD~1
# 或
git reset --mixed HEAD~1

# 4. 完全撤销最近一次提交，丢弃所有更改（危险！）
git reset --hard HEAD~1

# 5. 取消暂存某个文件
git reset HEAD <file>
# 或使用现代语法
git restore --staged <file>

# 6. 验证结果
git status
git log --oneline -5
```

## 日常开发场景

### 场景 1：撤销本地未推送的提交

**问题描述**：
你刚刚提交了代码，但发现提交信息写错了，或者提交中包含了不应该提交的文件，或者代码有问题需要重新修改。这个提交还没有推送到远程仓库。

**解决方案**：

```bash
# 方案 A：撤销提交但保留更改在暂存区（推荐用于修改提交信息）
git log --oneline -3
# 假设最近的提交是 a1b2c3d

git reset --soft HEAD~1

# 查看状态，所有更改仍在暂存区
git status
# Changes to be committed:
#   modified: src/app.js
#   modified: src/config.js

# 现在可以修改提交信息重新提交
git commit -m "feat: 正确的提交信息"

# 方案 B：撤销提交，更改变为未暂存状态（推荐用于重新选择要提交的文件）
git reset HEAD~1

# 查看状态，所有更改变为未暂存
git status
# Changes not staged for commit:
#   modified: src/app.js
#   modified: src/config.js

# 重新选择要提交的文件
git add src/app.js
git commit -m "feat: 只提交 app.js 的更改"

# 方案 C：撤销多个提交
git reset --soft HEAD~3  # 撤销最近 3 个提交，更改合并到暂存区
git commit -m "feat: 合并三个提交为一个"
```

**优点**：

- 更改不会丢失，可以重新组织
- 可以修正提交信息或拆分/合并提交
- 保持工作目录的当前状态

### 场景 2：重置到特定提交状态

**问题描述**：
你的代码出现了严重问题，需要回退到之前某个已知正常的版本。或者你在错误的方向上开发了很多代码，想要完全放弃这些更改，回到某个稳定状态重新开始。

**解决方案**：

```bash
# 1. 查看提交历史，找到要回退到的提交
git log --oneline -10

# 假设历史如下：
# a1b2c3d (HEAD) feat: 有问题的功能
# b2c3d4e feat: 另一个有问题的提交
# c3d4e5f fix: 一些修复
# d4e5f6g feat: 最后一个正常的提交 <-- 想回到这里
# e5f6g7h feat: 更早的提交

# 2. 在 reset 前创建备份分支（强烈推荐！）
git branch backup-before-reset

# 3. 执行 hard reset（⚠️ 危险操作！）
git reset --hard d4e5f6g

# 4. 验证结果
git log --oneline -5
# 现在 HEAD 指向 d4e5f6g
# a1b2c3d、b2c3d4e、c3d4e5f 的更改已完全丢失

# 5. 如果后悔了，可以从备份分支恢复
git reset --hard backup-before-reset

# 或者使用 reflog 恢复
git reflog
# a1b2c3d HEAD@{1}: reset: moving to d4e5f6g
# a1b2c3d HEAD@{2}: commit: feat: 有问题的功能
git reset --hard HEAD@{2}
```

**注意事项**：

- ⚠️ `--hard` 模式会**永久删除**未提交的更改
- 始终在 reset 前创建备份分支
- 如果提交已推送到远程，应使用 `git revert` 而不是 `git reset`
- 使用 `reflog` 可以恢复最近 90 天内的"丢失"提交

### 场景 3：清理工作目录和暂存区

**问题描述**：
你在实验性地修改了很多文件，添加了一些到暂存区，现在决定放弃所有更改，让工作目录恢复到最后一次提交的干净状态。

**解决方案**：

```bash
# 1. 查看当前状态
git status
# Changes to be committed:
#   modified: src/file1.js
#   new file: src/file2.js
# Changes not staged for commit:
#   modified: src/file3.js
# Untracked files:
#   temp.txt

# 方案 A：分步骤清理（推荐，更安全）

# 步骤 1：取消所有暂存的更改
git reset HEAD
# 或
git reset

# 步骤 2：丢弃工作目录中的所有更改
git checkout -- .
# 或使用现代语法
git restore .

# 步骤 3：删除未跟踪的文件（可选）
git clean -fd  # -f 强制，-d 包含目录

# 方案 B：一步到位（快速但危险）
git reset --hard HEAD
git clean -fd

# 方案 C：只清理特定文件
# 取消暂存特定文件
git reset HEAD src/file1.js

# 丢弃特定文件的更改
git checkout -- src/file3.js
# 或
git restore src/file3.js

# 2. 验证结果
git status
# On branch main
# nothing to commit, working tree clean
```

**使用场景对比**：

| 命令                | 作用                            | 是否影响未跟踪文件 |
| ------------------- | ------------------------------- | ------------------ |
| `git reset`         | 取消暂存                        | 否                 |
| `git reset --hard`  | 取消暂存 + 丢弃已跟踪文件的更改 | 否                 |
| `git clean -fd`     | 删除未跟踪的文件和目录          | 是                 |
| `git checkout -- .` | 丢弃工作目录中已跟踪文件的更改  | 否                 |

### 场景 4：修改最近几次提交（合并提交）

**问题描述**：
你在开发过程中创建了多个小提交（如 "WIP"、"fix typo"、"oops" 等），现在想在推送前将这些提交整理成一个或几个有意义的提交。

**解决方案**：

```bash
# 1. 查看最近的提交
git log --oneline -6

# 假设历史如下：
# a1b2c3d (HEAD) fix: 又一个 typo
# b2c3d4e WIP: 继续开发
# c3d4e5f fix: typo
# d4e5f6g WIP: 开始开发新功能
# e5f6g7h feat: 上一个完整功能  <-- 这是我们想保留的
# f6g7h8i feat: 更早的功能

# 2. 使用 soft reset 合并最近 4 个提交
git reset --soft HEAD~4
# 或者
git reset --soft e5f6g7h

# 3. 查看状态
git status
# Changes to be committed:
#   modified: src/feature.js
#   modified: src/utils.js
#   new file: src/new-feature.js

# 所有 4 个提交的更改现在都在暂存区

# 4. 创建一个新的整洁提交
git commit -m "feat: 添加新功能

- 实现了 xxx 功能
- 添加了相关工具函数
- 更新了配置文件"

# 5. 验证结果
git log --oneline -3
# xxxxxxx (HEAD) feat: 添加新功能
# e5f6g7h feat: 上一个完整功能
# f6g7h8i feat: 更早的功能
```

**与 `git rebase -i` 的对比**：

| 方法           | 适用场景                   | 优点               | 缺点                 |
| -------------- | -------------------------- | ------------------ | -------------------- |
| `reset --soft` | 合并所有提交为一个         | 简单快速           | 不灵活，只能全部合并 |
| `rebase -i`    | 需要保留部分提交或重新排序 | 灵活，可选择性操作 | 操作相对复杂         |

```bash
# 使用 rebase -i 的等效操作（更灵活）
git rebase -i HEAD~4
# 在编辑器中将 pick 改为 squash 或 fixup
```

### 场景 5：处理错误的合并

**问题描述**：
你执行了 `git merge` 合并了一个分支，但随后发现这个合并是错误的（比如合并了错误的分支，或者合并带来了问题）。这个合并还没有推送到远程。

**解决方案**：

```bash
# 1. 查看合并前后的状态
git log --oneline --graph -5

# 假设历史如下：
# *   m1e2r3g (HEAD) Merge branch 'feature-x'
# |\
# | * f1e2a3t feat: feature-x 的提交
# |/
# * a1b2c3d feat: main 分支的提交

# 方案 A：使用 reset 撤销合并（未推送时推荐）

# 使用 ORIG_HEAD（指向合并前的位置）
git reset --hard ORIG_HEAD

# 或者明确指定要回到的提交
git reset --hard HEAD~1
# 或
git reset --hard a1b2c3d

# 2. 验证合并已撤销
git log --oneline -3
# a1b2c3d (HEAD) feat: main 分支的提交

# 方案 B：使用 --merge 模式（如果有未提交的更改）
git reset --merge ORIG_HEAD
# --merge 会保留工作目录中未被合并影响的更改

# 方案 C：如果合并有冲突且正在进行中
git merge --abort  # 取消正在进行的合并
```

**如果合并已推送到远程**：

```bash
# ❌ 不要使用 reset，因为会影响其他人
# ✅ 使用 revert 来安全地撤销合并

# 撤销合并提交，-m 1 表示保留第一个父提交（main 分支）
git revert -m 1 m1e2r3g
git push origin main
```

**注意事项**：

- 如果合并**未推送**：使用 `git reset --hard` 是最简单的方法
- 如果合并**已推送**：必须使用 `git revert`，不要使用 reset
- `ORIG_HEAD` 在执行 merge、reset、rebase 等危险操作前会自动保存

### 场景 6：取消暂存的文件

**问题描述**：
你执行了 `git add` 将文件添加到暂存区，但现在想取消暂存某些文件（不是丢弃更改，只是从暂存区移除）。

**解决方案**：

```bash
# 1. 查看当前暂存状态
git status
# Changes to be committed:
#   modified: src/app.js
#   modified: src/config.js
#   new file: src/secret.js  <-- 不应该提交这个！
#   modified: src/utils.js

# 方案 A：取消暂存特定文件
git reset HEAD src/secret.js
# 或使用现代语法（Git 2.23+）
git restore --staged src/secret.js

# 方案 B：取消暂存多个文件
git reset HEAD src/config.js src/secret.js
# 或
git restore --staged src/config.js src/secret.js

# 方案 C：取消暂存所有文件
git reset HEAD
# 或
git reset
# 或
git restore --staged .

# 方案 D：交互式选择要取消暂存的部分（hunk）
git reset -p
# 或
git reset --patch
# Git 会逐个显示暂存的代码块，询问是否取消暂存

# 2. 验证结果
git status
# Changes to be committed:
#   modified: src/app.js
#   modified: src/utils.js
# Changes not staged for commit:
#   modified: src/config.js
# Untracked files:
#   src/secret.js
```

**现代 Git 语法对比**：

| 旧语法                   | 新语法（Git 2.23+）           | 作用             |
| ------------------------ | ----------------------------- | ---------------- |
| `git reset HEAD <file>`  | `git restore --staged <file>` | 取消暂存文件     |
| `git checkout -- <file>` | `git restore <file>`          | 丢弃工作目录更改 |
| `git checkout <branch>`  | `git switch <branch>`         | 切换分支         |

**优点**：

- 新语法更直观，`restore` 和 `switch` 职责更清晰
- 不会意外切换分支或做其他操作
- 新手更容易理解

## 常用命令

### 基本 Reset 命令

```bash
# 撤销最近 N 个提交
git reset HEAD~N           # 默认 --mixed，更改变为未暂存
git reset --soft HEAD~N    # 更改保留在暂存区
git reset --hard HEAD~N    # 完全丢弃更改（危险！）

# 重置到特定提交
git reset <commit-hash>
git reset --soft <commit-hash>
git reset --hard <commit-hash>

# 重置到某个分支的状态
git reset origin/main      # 重置到远程 main 分支
git reset --hard origin/main

# 重置到操作前的状态
git reset ORIG_HEAD        # 撤销上一次 reset/merge/rebase
git reset --hard ORIG_HEAD
```

### 取消暂存命令

```bash
# 取消暂存单个文件
git reset HEAD <file>
git reset -- <file>

# 取消暂存多个文件
git reset HEAD <file1> <file2> <file3>

# 取消暂存所有文件
git reset HEAD
git reset

# 取消暂存目录下所有文件
git reset HEAD src/

# 交互式取消暂存（选择特定的代码块）
git reset -p
git reset --patch

# 取消暂存某个提交中引入的所有文件
git reset HEAD~1 -- .
```

### 撤销提交命令

```bash
# 撤销最近一次提交，保留更改
git reset --soft HEAD~1    # 更改在暂存区
git reset HEAD~1           # 更改在工作目录（默认）

# 撤销最近一次提交，丢弃更改
git reset --hard HEAD~1    # ⚠️ 危险：更改被丢弃！

# 撤销到某个特定提交
git reset --soft <commit>  # 之后的所有更改移到暂存区
git reset --mixed <commit> # 之后的所有更改移到工作目录
git reset --hard <commit>  # 之后的所有更改被丢弃

# 撤销合并提交
git reset --hard HEAD~1    # 如果合并是最近的提交
git reset --hard ORIG_HEAD # 使用 ORIG_HEAD 更安全
git reset --merge ORIG_HEAD # 保留工作目录的其他更改
```

### 高级用法

```bash
# --merge 模式：安全地重置，保留未暂存的更改
git reset --merge <commit>
# 如果有文件同时在 <commit>..HEAD 和工作目录中被修改，操作会中止

# --keep 模式：类似 --merge，但更严格
git reset --keep <commit>
# 如果有任何本地更改与 reset 冲突，操作会中止

# 重置单个文件到特定版本（不移动 HEAD）
git reset <commit> -- <file>
# 这会将指定版本的文件内容放入暂存区

# 实现"取消最近的 commit，但把更改放到一个新分支"
git branch new-branch        # 先创建新分支保存当前状态
git reset --hard HEAD~1     # 然后重置当前分支

# 重置暂存区但保留工作目录的特定提交更改
git reset --mixed <commit> -- <file>

# 撤销上一次的 reset（如果刚执行）
git reset --hard ORIG_HEAD

# 合并多个提交为一个（squash 的替代方法）
git reset --soft HEAD~3
git commit -m "Combined commit message"
```

### 恢复操作（reflog）

```bash
# 查看所有 HEAD 移动的历史
git reflog
# 或
git reflog show HEAD

# 查看特定分支的 reflog
git reflog show main

# 输出示例：
# a1b2c3d HEAD@{0}: reset: moving to HEAD~3
# d4e5f6g HEAD@{1}: commit: feat: 最新提交
# e5f6g7h HEAD@{2}: commit: feat: 上一个提交
# f6g7h8i HEAD@{3}: commit: fix: 某个修复

# 恢复到某个历史状态
git reset --hard HEAD@{1}  # 恢复到上一个状态
git reset --hard d4e5f6g   # 恢复到特定提交

# 恢复被"丢失"的提交
git reflog | grep "要找的提交信息"
git reset --hard <found-commit-hash>

# 创建一个分支来保存恢复的提交
git branch recovered-branch HEAD@{5}

# 查看某个时间点的状态
git reflog --date=relative
# d4e5f6g HEAD@{5 minutes ago}: commit: feat: 最新提交

# 查看详细的 reflog 信息
git log -g --oneline
```

### 查询和检查命令

```bash
# 查看当前状态
git status

# 查看暂存区和 HEAD 的差异（已暂存的更改）
git diff --cached
git diff --staged

# 查看工作目录和暂存区的差异（未暂存的更改）
git diff

# 查看工作目录和 HEAD 的差异（所有更改）
git diff HEAD

# 查看特定文件在不同版本间的差异
git diff <commit1> <commit2> -- <file>

# 查看提交历史
git log --oneline -10
git log --oneline --graph --all

# 查看某个提交的详细信息
git show <commit>

# 查看 reset 前后的差异
git diff ORIG_HEAD HEAD

# 检查 reset 是否在进行中（通常不会有）
# reset 是即时操作，不会像 rebase 那样有中间状态

# 查看分支指针历史
git reflog show main

# 比较两个提交
git diff <commit1>..<commit2>
```

---

## 最佳实践和注意事项

### 最佳实践

#### 1. 在使用 `--hard` 前创建备份

```bash
# 方法 1：创建备份分支
git branch backup-before-reset
git reset --hard <commit>

# 如果需要恢复
git reset --hard backup-before-reset
git branch -d backup-before-reset  # 删除备份分支

# 方法 2：创建标签（如果要保留更长时间）
git tag backup-$(date +%Y%m%d) HEAD
git reset --hard <commit>

# 方法 3：直接依赖 reflog（有风险，不推荐作为唯一手段）
git reset --hard <commit>
# 如果需要恢复
git reflog
git reset --hard HEAD@{1}
```

#### 2. 理解三种模式并选择正确的模式

```bash
# 🎯 选择指南

# 想要修改提交信息或合并提交？
# → 使用 --soft
git reset --soft HEAD~1
git commit -m "新的提交信息"

# 想要重新选择要提交的文件？
# → 使用 --mixed（默认）
git reset HEAD~1
git add <selected-files>
git commit -m "提交信息"

# 想要完全放弃更改，回到干净状态？
# → 使用 --hard（谨慎！）
git reset --hard HEAD~1

# 想要取消暂存但保留工作目录更改？
# → 使用 --mixed 或省略模式
git reset HEAD <file>
```

#### 3. 使用 reflog 作为安全网

```bash
# 养成查看 reflog 的习惯
git reflog -10

# 设置 reflog 过期时间（默认 90 天）
git config --global gc.reflogExpire 180.days.ago
git config --global gc.reflogExpireUnreachable 180.days.ago

# 在危险操作前记录当前位置
echo "Before reset: $(git rev-parse HEAD)" >> ~/git-safety.log
git reset --hard <commit>
```

#### 4. 区分本地和远程分支的处理

```bash
# ✅ 本地未推送的提交：可以自由使用 reset
git reset --hard HEAD~3  # 没问题

# ⚠️ 已推送的提交：不要使用 reset
# 除非你完全理解后果并准备强制推送
git reset --hard HEAD~3
git push --force-with-lease  # 会破坏他人的工作！

# ✅ 已推送的提交：使用 revert 代替
git revert <commit>
git push origin main
```

#### 5. 配合 stash 使用

```bash
# 在 reset 前保存当前的工作
git stash push -m "Before reset experiment"

# 执行 reset
git reset --hard <commit>

# 实验完成后，恢复之前的工作
git stash pop

# 或者如果要在新的基础上应用之前的工作
git stash apply
```

#### 6. 使用 `--force-with-lease` 而不是 `--force`

```bash
# ❌ 危险：可能覆盖他人的提交
git push --force

# ✅ 更安全：如果远程有新提交会拒绝
git push --force-with-lease

# 为什么更安全？
# --force-with-lease 会检查远程分支是否与你预期的一致
# 如果有人在你 reset 后推送了新提交，push 会失败
```

### 注意事项

#### ⚠️ 1. `--hard` 的数据丢失风险

```bash
# 危险场景
git add important-changes.js
git reset --hard HEAD~1
# 😱 important-changes.js 的更改永久丢失了！

# ⚠️ --hard 会丢失：
# - 工作目录中未暂存的更改
# - 暂存区中已添加但未提交的更改
# - 被 reset 跳过的提交中的内容

# ✅ --hard 不会丢失（可以通过 reflog 恢复）：
# - 已经提交过的内容（90 天内）

# 安全检查：在 --hard 前先查看状态
git status
git stash  # 如果有重要更改
git reset --hard <commit>
```

#### ⚠️ 2. 不要 reset 已推送的提交

```bash
# 为什么不应该 reset 已推送的提交？

# 场景：你和同事 Alice 都在 main 分支工作
# 你的本地：A - B - C - D (HEAD)
# 远程：     A - B - C - D
# Alice：    A - B - C - D

# 你执行了 reset
git reset --hard HEAD~2
git push --force
# 远程变成：A - B

# Alice 拉取时会遇到问题：
# - 她的 C 和 D 提交与远程不兼容
# - 可能导致她丢失工作或产生复杂的合并

# ✅ 正确做法
git revert HEAD~1  # 创建新提交来撤销
git revert HEAD~1  # 再撤销一个
git push origin main  # 正常推送
```

#### ⚠️ 3. 团队协作中的注意事项

```bash
# 1. 永远不要 reset 共享分支（main、develop 等）
# 除非得到团队所有人的同意

# 2. 如果必须强制推送：
#    - 先通知团队
#    - 确保没有人正在基于那些提交工作
#    - 使用 --force-with-lease

# 3. 制定团队规范
# - 个人分支：可以自由 reset
# - 功能分支（多人）：协商后才能 reset
# - 主分支：禁止 reset，只能 revert

# 4. 设置分支保护（GitHub/GitLab）
# - 禁止强制推送到受保护分支
# - 要求 PR 审查
```

#### ⚠️ 4. reflog 的有效期限制

```bash
# reflog 默认保留时间：
# - 可达的提交：90 天
# - 不可达的提交：30 天

# 查看配置
git config gc.reflogExpire
git config gc.reflogExpireUnreachable

# 执行 gc 后，过期的 reflog 条目会被清理
git gc --prune=now

# ⚠️ 风险场景
# 你在 60 天前 reset --hard 丢失了重要代码
# 30 天后执行了 gc
# → 那些提交可能已经被永久删除了！

# ✅ 最佳实践
# - 不要完全依赖 reflog 作为备份
# - 重要操作前创建备份分支
# - 考虑推送到远程作为额外备份
```

#### ⚠️ 5. reset 与 submodule 的交互

```bash
# 如果仓库包含 submodule
git reset --hard HEAD~1

# ⚠️ 注意：
# - reset 会更新 submodule 的引用
# - 但不会自动更新 submodule 的内容

# 完整重置包括 submodule
git reset --hard HEAD~1
git submodule update --init --recursive
```

#### ⚠️ 6. 在合并冲突时使用 reset

```bash
# 如果在合并过程中想放弃
git merge --abort  # 推荐方式

# 或使用 reset（效果相同）
git reset --merge

# ⚠️ 注意：
# 不要使用 git reset --hard HEAD
# 因为 HEAD 在冲突时可能指向合并提交
# 应该使用：
git reset --hard ORIG_HEAD
```

### 冲突解决策略

当 `git reset --merge` 或 `--keep` 遇到问题时：

```bash
# 场景：reset --keep 失败，因为有本地更改
git reset --keep <commit>
# error: Entry 'file.js' would be overwritten by merge.

# 解决方案 1：先保存本地更改
git stash
git reset --hard <commit>
git stash pop
# 手动解决冲突

# 解决方案 2：如果不需要本地更改
git reset --hard <commit>

# 解决方案 3：只重置部分文件
git reset <commit> -- <safe-files>
git checkout <commit> -- <safe-files>
```

### 团队协作建议

1. **建立分支策略**：

```bash
# 推荐的 reset 使用规则：

# 个人开发分支（feature/xxx-yourname）
# → 自由使用 reset，可以强制推送

# 共享功能分支（feature/xxx）
# → 谨慎使用，需要团队协商

# 主分支（main/master）、开发分支（develop）
# → 禁止 reset，只能使用 revert
```

2. **文档记录**：

```bash
# 在 CONTRIBUTING.md 中说明

## Git 工作流规范

### reset 使用规则
1. 只在本地分支使用 reset
2. 共享分支禁止使用 reset
3. 如需撤销已推送的提交，使用 git revert
4. 强制推送前必须通知团队
```

3. **设置 Git hooks**：

```bash
# .git/hooks/pre-push（阻止推送到受保护分支）
#!/bin/bash

protected_branches=("main" "master" "develop")
current_branch=$(git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,')

for branch in "${protected_branches[@]}"; do
    if [ "$current_branch" = "$branch" ]; then
        echo "❌ 禁止直接推送到 $branch 分支"
        echo "请使用 Pull Request"
        exit 1
    fi
done
```

---

## Git Reset vs 其他命令

### Reset vs Revert

| 特性         | Reset                  | Revert                    |
| ------------ | ---------------------- | ------------------------- |
| **历史处理** | 修改/删除历史          | 保留历史，创建新提交      |
| **安全性**   | ⚠️ 可能丢失数据        | ✅ 安全，不丢失数据       |
| **远程分支** | 需要强制推送           | 可以正常推送              |
| **适用场景** | 本地未推送的提交       | 已推送的提交              |
| **协作影响** | 影响其他开发者         | 不影响其他开发者          |
| **可逆性**   | 部分可通过 reflog 恢复 | 完全可逆（revert revert） |
| **提交数量** | 减少提交               | 增加提交                  |

```bash
# Reset 示例
# 历史：A - B - C - D (HEAD)
git reset --hard HEAD~2
# 结果：A - B (HEAD)
# C 和 D "消失"了

# Revert 示例
# 历史：A - B - C - D (HEAD)
git revert HEAD~1  # 撤销 C
# 结果：A - B - C - D - C' (HEAD)
# C' 是撤销 C 的新提交
```

### Reset vs Checkout（文件操作）

| 特性           | Reset                    | Checkout                 |
| -------------- | ------------------------ | ------------------------ |
| **操作对象**   | 主要操作分支指针和暂存区 | 操作 HEAD 或工作目录文件 |
| **对暂存区**   | 可以重置暂存区           | 不影响暂存区             |
| **对工作目录** | `--hard` 会重置          | 直接重置指定文件         |
| **HEAD 移动**  | 会移动 HEAD              | 文件操作时不移动 HEAD    |

```bash
# 恢复文件的两种方式

# Reset：将文件的暂存区版本改为某个提交的版本
git reset <commit> -- <file>
# 然后需要 checkout 来更新工作目录
git checkout -- <file>

# Checkout：直接用某个提交的版本覆盖工作目录
git checkout <commit> -- <file>
# 同时更新暂存区和工作目录
```

### Reset vs Restore（现代方式）

| 特性           | Reset                 | Restore        |
| -------------- | --------------------- | -------------- |
| **引入版本**   | 早期版本              | Git 2.23+      |
| **主要用途**   | 移动 HEAD、重置暂存区 | 恢复文件       |
| **语义清晰度** | 较低（多功能）        | 高（专注恢复） |
| **推荐程度**   | 仍然常用              | 新项目推荐     |

```bash
# 取消暂存

# 旧方式
git reset HEAD <file>

# 新方式（更清晰）
git restore --staged <file>

# 丢弃工作目录更改

# 旧方式
git checkout -- <file>

# 新方式（更清晰）
git restore <file>

# 恢复到特定版本

# 旧方式
git checkout <commit> -- <file>

# 新方式
git restore --source=<commit> <file>
```

### 选择指南

```bash
# 📋 命令选择流程图

# 需要撤销提交吗？
# ├─ 是 → 提交已推送到远程吗？
# │   ├─ 是 → 使用 git revert（安全）
# │   └─ 否 → 使用 git reset（可以选择模式）
# │       ├─ 想保留更改重新提交？→ --soft
# │       ├─ 想重新选择文件？→ --mixed
# │       └─ 想完全丢弃？→ --hard
# └─ 否 → 继续判断

# 需要取消暂存吗？
# ├─ 是 → 使用 git restore --staged（推荐）
# │       或 git reset HEAD（传统方式）
# └─ 否 → 继续判断

# 需要丢弃工作目录更改吗？
# ├─ 是 → 使用 git restore（推荐）
# │       或 git checkout --（传统方式）
# └─ 否 → 继续判断

# 需要切换分支吗？
# └─ 是 → 使用 git switch（推荐）
#         或 git checkout（传统方式）
```

### 命令对照表

| 操作       | 传统命令                          | 现代命令（推荐）                 |
| ---------- | --------------------------------- | -------------------------------- |
| 取消暂存   | `git reset HEAD <file>`           | `git restore --staged <file>`    |
| 丢弃更改   | `git checkout -- <file>`          | `git restore <file>`             |
| 切换分支   | `git checkout <branch>`           | `git switch <branch>`            |
| 创建并切换 | `git checkout -b <new>`           | `git switch -c <new>`            |
| 恢复到版本 | `git checkout <commit> -- <file>` | `git restore -s <commit> <file>` |

---

## 总结

`git reset` 是一个强大的 Git 命令，用于移动分支指针、重置暂存区和工作目录。正确使用它可以：

- ✅ 灵活撤销本地未推送的提交
- ✅ 取消暂存不需要的文件
- ✅ 合并多个小提交为一个整洁的提交
- ✅ 快速回退到已知的稳定状态
- ✅ 清理混乱的工作目录和暂存区
- ✅ 撤销错误的本地合并操作

但也要注意：

- ⚠️ `--hard` 模式会**永久丢失**未提交的更改
- ⚠️ **不要** reset 已推送到远程的提交（使用 revert 代替）
- ⚠️ 团队协作时要特别小心，避免影响他人
- ⚠️ 总是在危险操作前**创建备份**
- ⚠️ 善用 **reflog** 作为安全网，但不要完全依赖它
- ⚠️ 考虑使用更现代的 `git restore` 命令处理文件恢复

### 快速参考表

| 场景                       | 命令                                     | 说明                      |
| -------------------------- | ---------------------------------------- | ------------------------- |
| 撤销提交，保留更改在暂存区 | `git reset --soft HEAD~1`                | 适合修改提交信息          |
| 撤销提交，更改变为未暂存   | `git reset HEAD~1`                       | 适合重新选择文件          |
| 完全撤销提交和更改         | `git reset --hard HEAD~1`                | ⚠️ 危险：更改丢失         |
| 取消暂存文件               | `git reset HEAD <file>`                  | 或 `git restore --staged` |
| 回到上次危险操作前         | `git reset --hard ORIG_HEAD`             | 撤销 reset/merge/rebase   |
| 恢复丢失的提交             | `git reflog` + `git reset --hard <hash>` | 90 天内有效               |
| 合并多个提交               | `git reset --soft HEAD~N` + `git commit` | 简单的 squash             |

### 黄金法则

> **只对本地未推送的提交使用 reset，已推送的提交使用 revert。**

> **使用 `--hard` 前，始终创建备份分支。**

遵循这两条规则，你就能安全地使用 `git reset`，有效管理你的提交历史！

---

## 参考资源

- [Git 官方文档 - git-reset](https://git-scm.com/docs/git-reset)
- [Git 官方文档 - git-restore](https://git-scm.com/docs/git-restore)
- [Pro Git Book - Git 工具 - 重置揭密](https://git-scm.com/book/zh/v2/Git-%E5%B7%A5%E5%85%B7-%E9%87%8D%E7%BD%AE%E6%8F%AD%E5%AF%86)
