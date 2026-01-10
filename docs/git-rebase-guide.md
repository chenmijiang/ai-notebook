## 功能介绍

### 什么是 Git Rebase？

`git rebase` 是 Git 中一个强大的历史重写命令，它可以将一个分支上的提交"移植"到另一个分支的顶端。Rebase 的核心思想是：取出一系列的提交，"复制"它们，然后在另一个地方逐个应用。这使得提交历史看起来像是一条直线，而不是包含多个分叉的复杂图形。

### 工作原理

Rebase 的核心工作原理如下：

1. **找到共同祖先**：Git 首先找到当前分支和目标分支的共同祖先提交
2. **保存提交补丁**：将当前分支从共同祖先开始的所有提交保存为临时补丁（patch）
3. **重置分支**：将当前分支重置到目标分支的最新提交
4. **逐个应用补丁**：按顺序将之前保存的补丁逐个应用到新的基础上
5. **生成新提交**：每个应用的补丁都会生成一个新的提交（新的哈希值）

与 `merge` 不同，rebase 会重写提交历史，创建全新的提交对象，使历史更加线性和整洁。

### 应用场景

在以下情况下，rebase 特别有用：

- 在推送前整理本地分支的提交历史
- 保持功能分支与主分支同步
- 合并多个小提交为一个有意义的提交
- 修改历史提交的信息或内容
- 在合并前创建干净、线性的提交历史

## 基本用法

### 命令语法

```bash
git rebase <base-branch>
```

### 基本参数说明

```bash
git rebase [options] [<upstream> [<branch>]]
```

常用选项：

- `<upstream>`：目标基础分支，当前分支将被重新应用到这个分支上
- `-i, --interactive`：交互式 rebase，可以编辑、合并、删除、重排序提交
- `--onto <newbase>`：将提交应用到指定的新基础上
- `-p, --preserve-merges`：保留合并提交（已弃用，使用 --rebase-merges）
- `-r, --rebase-merges`：重建合并提交而不是展平它们
- `--continue`：解决冲突后继续 rebase
- `--abort`：取消 rebase 操作并恢复到之前的状态
- `--skip`：跳过当前的补丁并继续
- `-x <cmd>`：在每个提交后执行命令
- `--autosquash`：自动应用 squash/fixup 标记

### 简单示例

```bash
# 1. 查看当前分支状态
git log --oneline --graph --all

# 2. 假设在 feature 分支上，想要 rebase 到 main 分支
git checkout feature
git rebase main

# 3. 如果有冲突，解决冲突后
git add .
git rebase --continue

# 4. 验证结果
git log --oneline --graph
```

### 图解说明

```bash
# Rebase 前
      A---B---C  (feature)
     /
D---E---F---G  (main)

# 执行 git rebase main 后
              A'---B'---C'  (feature)
             /
D---E---F---G  (main)

# 注意：A、B、C 被"复制"为 A'、B'、C'（新的哈希值）
```

## 日常开发场景

### 场景 1：保持功能分支与主分支同步

**问题描述**：
你在 `feature/user-auth` 分支上开发用户认证功能，期间团队其他成员向 `main` 分支推送了多个重要更新。你需要将这些更新同步到自己的分支，同时保持整洁的提交历史。

**解决方案**：

```bash
# 1. 确保本地 main 分支是最新的
git checkout main
git pull origin main

# 2. 切换到功能分支
git checkout feature/user-auth

# 3. 执行 rebase
git rebase main

# 如果出现冲突：
# 4. 查看冲突文件
git status

# 5. 解决冲突
vim src/auth/login.js
# 编辑文件，解决冲突标记

# 6. 标记冲突已解决
git add src/auth/login.js

# 7. 继续 rebase
git rebase --continue

# 8. 如果还有冲突，重复步骤 4-7

# 9. 验证结果
git log --oneline --graph

# 10. 强制推送到远程（因为历史被重写）
git push origin feature/user-auth --force-with-lease
```

**优点**：

- 提交历史保持线性，更容易理解
- 避免了多余的 merge commit
- 使得最终合并到 main 分支时更加干净

**与 merge 对比**：

```bash
# 使用 merge 同步（会产生 merge commit）
git checkout feature/user-auth
git merge main
# 历史会变成：A---B---M (merge commit)

# 使用 rebase 同步（线性历史）
git checkout feature/user-auth
git rebase main
# 历史会变成：A'---B' (线性，无 merge commit)
```

### 场景 2：使用交互式 Rebase 整理提交历史

**问题描述**：
在开发过程中，你创建了多个临时提交，包括"WIP"、"fix typo"、"oops"等不规范的提交。在推送到远程之前，你想将这些提交整理成几个有意义的、逻辑清晰的提交。

**解决方案**：

```bash
# 1. 查看最近的提交
git log --oneline -10

# 假设看到：
# a1b2c3d (HEAD) fix typo again
# b2c3d4e oops, forgot to add file
# c3d4e5f fix typo
# d4e5f6g WIP: add validation
# e5f6g7h feat: add login form
# f6g7h8i base: main branch commit

# 2. 启动交互式 rebase（整理最近 5 个提交）
git rebase -i HEAD~5

# 3. 编辑器会打开，显示如下内容（旧 -> 新）：
# pick e5f6g7h feat: add login form
# pick d4e5f6g WIP: add validation
# pick c3d4e5f fix typo
# pick b2c3d4e oops, forgot to add file
# pick a1b2c3d fix typo again

# 4. 修改为：
# pick e5f6g7h feat: add login form
# squash d4e5f6g WIP: add validation
# fixup c3d4e5f fix typo
# fixup b2c3d4e oops, forgot to add file
# fixup a1b2c3d fix typo again

# 5. 保存并关闭编辑器

# 6. Git 会打开另一个编辑器让你编写合并后的提交信息
# feat: add login form with validation
#
# - Added login form component
# - Implemented form validation
# - Added error handling

# 7. 保存并关闭，完成 rebase

# 8. 验证结果
git log --oneline -3
# 现在只有一个整洁的提交
```

**交互式 Rebase 命令说明**：

| 命令           | 作用                           |
| -------------- | ------------------------------ |
| `pick` / `p`   | 保留该提交                     |
| `reword` / `r` | 保留提交但修改提交信息         |
| `edit` / `e`   | 保留提交，但停下来修改         |
| `squash` / `s` | 与前一个提交合并，保留提交信息 |
| `fixup` / `f`  | 与前一个提交合并，丢弃提交信息 |
| `drop` / `d`   | 删除该提交                     |
| `exec` / `x`   | 执行 shell 命令                |

### 场景 3：修改历史提交的内容或信息

**问题描述**：
你发现三个提交之前的一个提交中有一个小 bug，或者提交信息写错了。你想修改这个特定的历史提交，而不是创建新的修复提交。

**解决方案 A：修改提交信息**

```bash
# 1. 启动交互式 rebase
git rebase -i HEAD~4

# 2. 找到要修改的提交，将 pick 改为 reword
# pick a1b2c3d Some commit
# pick b2c3d4e Another commit
# reword c3d4e5f Commit with typo in mesage  <-- 修改这行
# pick d4e5f6g Latest commit

# 3. 保存并关闭

# 4. Git 会打开编辑器让你修改提交信息
# 改正错误：Commit with typo in message

# 5. 保存并关闭，完成
```

**解决方案 B：修改提交内容**

```bash
# 1. 启动交互式 rebase
git rebase -i HEAD~4

# 2. 找到要修改的提交，将 pick 改为 edit
# pick a1b2c3d Some commit
# edit b2c3d4e Commit to edit  <-- 修改这行
# pick c3d4e5f Another commit
# pick d4e5f6g Latest commit

# 3. 保存并关闭，Git 会停在该提交

# 4. 进行需要的修改
vim src/buggy-file.js
# 修复 bug

# 5. 将修改添加到暂存区
git add src/buggy-file.js

# 6. 修改提交（使用 --amend）
git commit --amend
# 可以同时修改提交信息

# 7. 继续 rebase
git rebase --continue

# 8. 验证结果
git log --oneline
git show <modified-commit-hash>
```

**解决方案 C：使用 fixup 自动修复**

```bash
# 1. 创建一个修复提交
vim src/buggy-file.js
git add src/buggy-file.js

# 2. 使用 --fixup 创建特殊的修复提交
git commit --fixup=<target-commit-hash>
# 这会创建一个以 "fixup!" 为前缀的提交

# 3. 使用 --autosquash 进行 rebase
git rebase -i --autosquash HEAD~5
# Git 会自动将 fixup 提交移动到正确位置并标记为 fixup

# 4. 确认并保存，完成
```

### 场景 4：将分支移植到不同的基础上（--onto）

**问题描述**：
你从 `feature-a` 分支创建了 `feature-b` 分支进行开发。现在 `feature-a` 已经被废弃，你想将 `feature-b` 的提交直接移植到 `main` 分支上，而不包含 `feature-a` 的任何提交。

**当前状态**：

```bash
# 分支历史
      E---F---G  (feature-b)
     /
    C---D  (feature-a)
   /
A---B---H---I  (main)
```

**目标状态**：

```bash
# 只保留 feature-b 的提交 E、F、G，移植到 main 上
              E'---F'---G'  (feature-b)
             /
A---B---H---I  (main)
    \
     C---D  (feature-a，不受影响)
```

**解决方案**：

```bash
# 使用 --onto 参数
# 语法：git rebase --onto <newbase> <upstream> <branch>

# 1. 执行 rebase --onto
git rebase --onto main feature-a feature-b

# 解释：
# - main: 新的基础（目标位置）
# - feature-a: 旧的基础（不包含此分支的提交）
# - feature-b: 要移植的分支

# 2. 验证结果
git log --oneline --graph --all

# 3. 现在 feature-b 直接基于 main，不包含 feature-a 的提交
```

**另一个 --onto 用例：移除中间的提交**

```bash
# 假设历史是：A---B---C---D---E (main)
# 想要移除 C 和 D，保留 A---B---E

git rebase --onto B D main
# 这会将 E 移植到 B 之后，跳过 C 和 D
# 结果：A---B---E' (main)
```

### 场景 5：拆分一个大提交为多个小提交

**问题描述**：
你不小心将多个不相关的修改放在了一个提交中，现在想要将它拆分成多个逻辑独立的提交，以便于代码审查和历史追溯。

**解决方案**：

```bash
# 1. 启动交互式 rebase
git rebase -i HEAD~3

# 2. 找到要拆分的提交，将 pick 改为 edit
# pick a1b2c3d Small change
# edit b2c3d4e Big commit to split  <-- 修改这行
# pick c3d4e5f Another change

# 3. 保存并关闭，Git 停在该提交

# 4. 重置该提交，但保留工作目录中的更改
git reset HEAD^
# 现在所有更改都在工作目录中，未暂存

# 5. 查看所有更改
git status
git diff

# 6. 逐个添加和提交相关的更改
# 第一个逻辑提交
git add src/api/users.js
git commit -m "feat: add user API endpoints"

# 第二个逻辑提交
git add src/models/user.js
git commit -m "feat: add user model"

# 第三个逻辑提交
git add tests/user.test.js
git commit -m "test: add user tests"

# 7. 继续 rebase
git rebase --continue

# 8. 验证结果
git log --oneline -5
# 现在一个大提交被拆分成了三个小提交
```

**使用 `git add -p` 进行更精细的拆分**：

```bash
# 如果一个文件中包含多个不相关的修改
git add -p src/mixed-changes.js

# Git 会逐个显示代码块（hunk），询问是否暂存
# y - 暂存此块
# n - 不暂存此块
# s - 拆分成更小的块
# e - 手动编辑此块
```

### 场景 6：使用 --rebase-merges 保留合并提交结构

**问题描述**：
你的功能分支包含多个合并提交，例如你在开发过程中多次从 `main` 分支合并更新，或者你的分支本身就是由多个子功能分支合并而成。现在你想要将整个分支 rebase 到最新的 `main` 上，但不想丢失这些合并提交所代表的分支结构和历史信息。

**当前状态**：

```bash
# 分支历史（包含合并提交）
        D---E  (feature-part-1)
       /     \
      /       \
A---B---C-------M---F---G  (feature)
     \         /
      \       /
       H---I--  (feature-part-2)
```

**问题：默认 rebase 会展平历史**：

```bash
# 使用普通 rebase
git rebase main

# 结果：所有提交变成线性，丢失分支结构
# A---B---C---D'---E'---H'---I'---F'---G'  (feature)
# 合并提交 M 消失了！无法看出原来的分支关系
```

**解决方案：使用 --rebase-merges**：

```bash
# 1. 切换到功能分支
git checkout feature

# 2. 使用 --rebase-merges（或 -r）进行 rebase
git rebase --rebase-merges main

# 3. 如果有冲突，正常解决
git add <resolved-files>
git rebase --continue

# 4. 验证结果
git log --oneline --graph

# 结果：保留了合并结构
#         D'---E'
#        /       \
#       /         \
# ...---M'---F'---G'  (feature)
#      /
#     /
# H'---I'
```

**交互式使用 --rebase-merges**：

```bash
# 结合交互式 rebase 使用
git rebase -i --rebase-merges main

# 编辑器会显示特殊的指令格式：
# label onto
#
# # Branch feature-part-1
# reset onto
# pick d1e2f3g feat: add part 1 feature A
# pick e2f3g4h feat: add part 1 feature B
# label feature-part-1
#
# # Branch feature-part-2
# reset onto
# pick h3i4j5k feat: add part 2 feature X
# pick i4j5k6l feat: add part 2 feature Y
# label feature-part-2
#
# reset feature-part-1
# merge -C m5n6o7p feature-part-2 # Merge feature-part-2 into feature
# pick f6g7h8i feat: final integration
# pick g7h8i9j docs: update readme

# 你可以：
# - 重新排序提交
# - 使用 squash/fixup 合并提交
# - 使用 reword 修改提交信息
# - 使用 drop 删除提交
# - 修改合并提交的信息（通过 merge -C 或 merge -c）
```

**--rebase-merges 专用命令说明**：

| 命令                      | 作用                           |
| ------------------------- | ------------------------------ |
| `label <name>`            | 给当前 HEAD 位置创建临时标签   |
| `reset <name>`            | 将 HEAD 移动到指定标签位置     |
| `merge -C <commit> <ref>` | 创建合并提交，保留原提交信息   |
| `merge -c <commit> <ref>` | 创建合并提交，允许编辑提交信息 |
| `merge <ref>`             | 创建合并提交，使用默认信息     |

**实际应用示例：重新组织带合并的分支**：

```bash
# 假设你有这样的历史：
#       C---D  (feature-ui)
#      /     \
# A---B-------M---E  (feature)
#      \     /
#       F---G  (feature-api)

# 你想要：
# 1. 保留合并结构
# 2. 将整个分支 rebase 到新的 main 上
# 3. 同时整理一些提交

# 执行交互式 rebase
git rebase -ir main

# 在编辑器中，你可以修改结构：
# label onto
#
# # Branch feature-ui
# reset onto
# pick c1d2e3f feat(ui): add button component
# squash d2e3f4g feat(ui): add button styles  # 合并这两个 UI 提交
# label feature-ui
#
# # Branch feature-api
# reset onto
# pick f3g4h5i feat(api): add user endpoint
# pick g4h5i6j feat(api): add auth middleware
# label feature-api
#
# reset feature-ui
# merge -c m6n7o8p feature-api  # -c 允许编辑合并信息
# pick e5f6g7h feat: integrate ui and api
```

**--rebase-merges vs --preserve-merges**：

```bash
# ❌ 已弃用（Git 2.22+）
git rebase --preserve-merges main
# 问题：无法与交互式 rebase 正确配合，行为不一致

# ✅ 推荐使用（Git 2.18+）
git rebase --rebase-merges main
# 优点：
# - 完全支持交互式 rebase
# - 更可预测的行为
# - 可以重新创建合并提交而不是尝试保留它们
```

**高级用法：指定 rebase 策略**：

```bash
# 使用特定的合并策略处理冲突
git rebase -r -X theirs main  # 冲突时优先使用 main 的版本
git rebase -r -X ours main    # 冲突时优先使用当前分支的版本

# 结合 --autosquash 使用
git rebase -ir --autosquash main

# 在每个提交后运行测试
git rebase -ir --exec "npm test" main
```

**注意事项**：

- 合并提交会被**重新创建**而非简单复制，因此合并提交的哈希值也会改变
- 如果合并时有冲突解决记录，可能需要重新解决（考虑启用 `rerere`）
- 复杂的分支拓扑可能产生复杂的 todo 列表，建议在执行前创建备份分支
- 某些边缘情况下可能需要手动调整 `label`/`reset`/`merge` 指令的顺序

**何时使用 --rebase-merges**：

```bash
# ✅ 适合使用的场景：
# - 功能分支包含有意义的子分支合并
# - 需要保留代码审查历史（PR 合并）
# - 复杂功能由多个子任务并行开发后合并
# - 团队约定保留分支拓扑结构

# ❌ 不需要使用的场景：
# - 合并只是为了同步 main 分支（可以用普通 rebase 替代）
# - 想要最终得到完全线性的历史
# - 合并提交没有特别的意义
```

## 常用命令

### 基本 Rebase 命令

```bash
# 将当前分支 rebase 到目标分支
git rebase <base-branch>

# 将指定分支 rebase 到目标分支
git rebase <base-branch> <topic-branch>

# 使用 --onto 进行高级 rebase
git rebase --onto <newbase> <upstream> [<branch>]

# 交互式 rebase
git rebase -i <base>
git rebase --interactive <base>

# 交互式 rebase 最近 N 个提交
git rebase -i HEAD~N

# 保留合并提交的 rebase
git rebase --rebase-merges <base>
git rebase -r <base>

# 自动处理 fixup/squash 提交
git rebase -i --autosquash <base>
```

### 处理冲突的命令

```bash
# 当 rebase 发生冲突时

# 1. 查看冲突状态
git status

# 2. 查看冲突详情
git diff

# 3. 解决冲突后，标记为已解决
git add <resolved-files>

# 4. 继续 rebase
git rebase --continue

# 5. 跳过当前提交（丢弃该提交的更改）
git rebase --skip

# 6. 完全放弃 rebase，恢复到开始前的状态
git rebase --abort

# 7. 退出 rebase，但保留当前状态
git rebase --quit
```

### 交互式 Rebase 命令

```bash
# 在交互式编辑器中可用的命令

# pick (p) - 使用该提交
pick a1b2c3d commit message

# reword (r) - 使用该提交，但修改提交信息
reword a1b2c3d commit message

# edit (e) - 使用该提交，但停下来修改
edit a1b2c3d commit message

# squash (s) - 使用该提交，但合并到前一个提交
squash a1b2c3d commit message

# fixup (f) - 类似 squash，但丢弃该提交的信息
fixup a1b2c3d commit message

# exec (x) - 执行 shell 命令
exec npm test

# break (b) - 在此处停止（稍后用 git rebase --continue 继续）
break

# drop (d) - 删除该提交
drop a1b2c3d commit message

# label (l) - 给当前 HEAD 打标签
label my-label

# reset (t) - 重置 HEAD 到某个标签
reset my-label

# merge (m) - 创建合并提交
merge -C a1b2c3d branch-name
```

### 自动化和脚本命令

```bash
# 在每个提交后执行命令（用于验证）
git rebase -i HEAD~5 --exec "npm test"

# 自动 squash fixup 提交
git rebase -i --autosquash HEAD~10

# 创建 fixup 提交
git commit --fixup=<commit-hash>

# 创建 squash 提交
git commit --squash=<commit-hash>

# 非交互式地应用 autosquash
GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash HEAD~10
```

### 高级用法

```bash
# 保留合并提交进行 rebase
git rebase --rebase-merges main

# 指定合并策略
git rebase -X theirs main
git rebase -X ours main
git rebase --strategy=recursive -X patience main

# 使用空提交信息也继续
git rebase --allow-empty-message

# 保留空提交
git rebase --keep-empty

# 在 rebase 时自动 stash 和 unstash
git rebase --autostash main

# 显示当前 rebase 进度
git rebase --show-current-patch

# 跳过已经应用的提交
git rebase --skip

# 从特定提交开始 rebase（不从共同祖先）
git rebase --root
```

### 查询和检查命令

```bash
# 查看 rebase 是否在进行中
ls .git/rebase-merge 2>/dev/null && echo "Rebase in progress" || echo "No rebase"

# 查看当前正在处理的提交
cat .git/rebase-merge/current-commit 2>/dev/null

# 查看剩余要处理的提交
cat .git/rebase-merge/git-rebase-todo 2>/dev/null

# 使用 reflog 查看 rebase 前的状态
git reflog

# 查看两个分支的提交差异
git log main..feature --oneline

# 图形化查看提交历史
git log --graph --oneline --all

# 模拟 rebase（不实际执行）
git rebase --dry-run main  # 注意：这个选项不存在
# 可以使用：
git log --oneline main..HEAD  # 查看哪些提交会被 rebase
```

### 撤销和恢复

```bash
# 如果 rebase 正在进行中，中止它
git rebase --abort

# 如果 rebase 已完成，使用 reflog 恢复
git reflog
# 找到 rebase 之前的 HEAD 位置，例如 HEAD@{5}
git reset --hard HEAD@{5}

# 或者使用 ORIG_HEAD（如果 rebase 刚完成）
git reset --hard ORIG_HEAD

# 创建备份分支（在 rebase 前）
git branch backup-branch
git rebase main
# 如果出问题
git checkout backup-branch
```

---

## 最佳实践和注意事项

### 最佳实践

#### 1. 永远不要 Rebase 已推送的公共分支

```bash
# ❌ 危险：不要这样做
git checkout main
git rebase feature  # 重写 main 的历史
git push --force    # 破坏所有人的工作

# ✅ 安全：只 rebase 私有分支
git checkout feature
git rebase main     # 重写 feature 的历史（私有分支）
git push --force-with-lease  # 安全地强制推送
```

**黄金法则**：只 rebase 尚未推送的本地提交，或者只有你自己使用的分支。

#### 2. 使用 --force-with-lease 而不是 --force

```bash
# ❌ 危险：可能覆盖他人的提交
git push --force

# ✅ 安全：如果远程有新提交会拒绝推送
git push --force-with-lease

# 更安全：指定期望的远程 ref
git push --force-with-lease=origin/feature:feature
```

#### 3. 在 Rebase 前创建备份分支

```bash
# 在复杂的 rebase 前创建备份
git branch backup-feature-branch

# 执行 rebase
git rebase -i main

# 如果出问题，可以恢复
git checkout backup-feature-branch
# 或
git reset --hard backup-feature-branch

# 成功后删除备份
git branch -d backup-feature-branch
```

#### 4. 使用 --autostash 避免 stash 操作

```bash
# 当工作目录有未提交的更改时
git rebase --autostash main

# 等同于：
git stash
git rebase main
git stash pop
```

#### 5. 定期同步以减少冲突

```bash
# 每天开始工作时同步
git fetch origin
git rebase origin/main

# 小步快跑，频繁 rebase 比积累后一次性 rebase 更容易
```

#### 6. 使用 --exec 验证每个提交

```bash
# 确保 rebase 后每个提交都能通过测试
git rebase -i main --exec "npm test"

# 如果任何提交导致测试失败，rebase 会停止
# 你可以修复问题后继续
git rebase --continue
```

#### 7. 合理使用 Squash 整理历史

```bash
# 在 PR 合并前整理提交
git rebase -i main

# 推荐的提交组织：
# - 每个逻辑功能一个提交
# - 提交信息清晰描述变更
# - 移除临时性的 WIP、fixup 提交
```

### 注意事项

#### ⚠️ 1. Rebase 会改变提交哈希

```bash
# Rebase 前
A---B---C (feature, hash: abc123)

# Rebase 后
A---B---C' (feature, hash: def456)  # 新的哈希！

# 影响：
# - 无法通过原哈希找到提交
# - 其他基于原提交的分支会出问题
# - 需要强制推送到远程
```

#### ⚠️ 2. 多人协作时的风险

```bash
# 场景：你和同事都在 feature 分支工作

# 你执行了 rebase
git rebase main
git push --force

# 同事拉取时会遇到问题
git pull
# error: Your local changes to the following files would be overwritten

# 解决方案：
# 1. 团队约定只有一个人负责 rebase
# 2. 使用 merge 代替 rebase
# 3. 同事需要重新基于新的 feature 分支工作
git fetch origin
git reset --hard origin/feature
```

#### ⚠️ 3. 处理复杂冲突

```bash
# 当 rebase 产生大量冲突时

# 方法 1：逐个解决
git rebase main
# 解决冲突
git add .
git rebase --continue
# 重复直到完成

# 方法 2：使用工具辅助
git mergetool

# 方法 3：放弃并使用 merge
git rebase --abort
git merge main  # merge 通常冲突更少
```

#### ⚠️ 4. 交互式 Rebase 的顺序

```bash
# 注意：交互式 rebase 中提交顺序是从旧到新（与 git log 相反）

# git log 显示（从新到旧）：
# c3 (newest)
# c2
# c1 (oldest)

# 交互式 rebase 显示（从旧到新）：
# pick c1 (oldest)
# pick c2
# pick c3 (newest)

# 常见错误：颠倒顺序导致冲突或丢失提交
```

#### ⚠️ 5. Squash 时注意依赖关系

```bash
# 错误示例：squash 到错误的提交
# pick a1 添加用户模型
# squash b2 添加用户 API（依赖 a1）
# squash c3 修复用户模型 bug

# c3 应该 squash 到 a1，而不是 b2
# 正确做法：
# pick a1 添加用户模型
# fixup c3 修复用户模型 bug
# pick b2 添加用户 API
```

#### ⚠️ 6. 保护重要分支

```bash
# 在 Git 服务器上配置分支保护

# GitHub: Settings > Branches > Add rule
# - Require pull request reviews
# - Require status checks
# - Disable force push

# 本地配置 pre-push hook
# .git/hooks/pre-push
#!/bin/bash
protected_branch='main'
current_branch=$(git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,')

if [ $protected_branch = $current_branch ]; then
    echo "Cannot push to protected branch: $protected_branch"
    exit 1
fi
```

#### ⚠️ 7. 大型 Rebase 的性能问题

```bash
# 不推荐：一次 rebase 大量提交
git rebase -i HEAD~100  # 可能很慢，冲突难处理

# 推荐：分批处理
git rebase -i HEAD~20
# 完成后
git rebase -i HEAD~20
# 继续...

# 或者使用 merge 策略
git merge main
```

### 冲突解决策略

当遇到 rebase 冲突时，按以下步骤处理：

1. **理解冲突上下文**

```bash
# 查看当前正在处理的提交
git rebase --show-current-patch

# 查看冲突文件
git status

# 查看冲突详情
git diff
```

2. **选择解决策略**

```bash
# 策略 A：手动解决（推荐）
vim <conflict-file>
# 仔细编辑，保留正确的代码

# 策略 B：完全接受当前版本（正在应用的提交）
git checkout --theirs <file>

# 策略 C：完全接受目标分支版本
git checkout --ours <file>

# 策略 D：使用合并工具
git mergetool
```

3. **验证和继续**

```bash
# 标记冲突已解决
git add <resolved-files>

# 运行测试（如果配置了 --exec）
npm test

# 继续 rebase
git rebase --continue

# 如果决定跳过此提交
git rebase --skip

# 如果决定放弃
git rebase --abort
```

4. **记录解决方案**

```bash
# Git 可以记住冲突解决方案（rerere）
git config --global rerere.enabled true

# 下次遇到相同冲突时，Git 会自动应用之前的解决方案
```

### 团队协作建议

1. **建立分支策略**：

```bash
# 推荐的 Git 工作流

# 1. 从 main 创建功能分支
git checkout -b feature/new-feature main

# 2. 开发过程中定期 rebase
git fetch origin
git rebase origin/main

# 3. 完成后整理提交
git rebase -i origin/main

# 4. 推送并创建 PR
git push origin feature/new-feature

# 5. PR 合并时使用 "Squash and merge" 或 "Rebase and merge"
```

2. **团队约定**：

```bash
# 在 CONTRIBUTING.md 中说明

## Git 工作流约定

1. 个人分支可以使用 rebase
2. 共享分支（main、develop）禁止 force push
3. PR 合并前必须 rebase 到最新的目标分支
4. 使用有意义的提交信息，遵循 Conventional Commits
5. 复杂功能分割成多个小 PR
```

3. **代码审查时的注意事项**：

```bash
# 审查者检查项
# - 提交历史是否清晰
# - 是否包含不必要的 merge commit
# - 提交信息是否规范
# - 每个提交是否可以独立运行测试
```

4. **处理远程分支更新**：

```bash
# 当远程分支被 force push 后，本地如何同步

# 方法 1：重新检出
git fetch origin
git checkout feature
git reset --hard origin/feature

# 方法 2：使用 pull --rebase
git pull --rebase origin feature
```

---

## Git Rebase vs 其他命令

### Rebase vs Merge

| 特性         | Rebase         | Merge             |
| ------------ | -------------- | ----------------- |
| **历史记录** | 线性历史       | 保留分支结构      |
| **提交哈希** | 创建新的提交   | 保留原有提交      |
| **合并提交** | 无额外提交     | 创建 merge commit |
| **冲突处理** | 可能多次解决   | 一次性解决        |
| **可追溯性** | 较难追溯原分支 | 清晰的分支来源    |
| **适用场景** | 私有分支整理   | 公共分支合并      |
| **安全性**   | ⚠️ 重写历史    | ✅ 保留历史       |

```bash
# Merge 示例
git checkout main
git merge feature
#       A---B---C (feature)
#      /         \
# D---E---F---G---M (main, M 是 merge commit)

# Rebase 示例
git checkout feature
git rebase main
git checkout main
git merge feature  # fast-forward
# D---E---F---G---A'---B'---C' (main, 线性历史)
```

### Rebase vs Cherry-pick

| 特性           | Rebase                 | Cherry-pick      |
| -------------- | ---------------------- | ---------------- |
| **操作对象**   | 整个分支               | 单个或多个提交   |
| **自动化程度** | 自动处理范围内所有提交 | 需要指定每个提交 |
| **使用场景**   | 同步分支、整理历史     | 选择性应用提交   |
| **交互能力**   | 支持交互式编辑         | 简单的复制操作   |

```bash
# Rebase - 移动整个分支
git checkout feature
git rebase main
# 所有 feature 分支的提交都被移动到 main 之上

# Cherry-pick - 选择特定提交
git checkout main
git cherry-pick abc123 def456
# 只有指定的提交被复制
```

### Rebase vs Reset

| 特性         | Rebase        | Reset              |
| ------------ | ------------- | ------------------ |
| **目的**     | 重写/整理历史 | 移动 HEAD/撤销更改 |
| **提交保留** | 创建新提交    | 可能删除提交       |
| **工作目录** | 通常保持      | 可能被更改         |
| **使用场景** | 历史整理      | 撤销本地更改       |

```bash
# Rebase - 重新组织提交
git rebase -i HEAD~3
# 可以合并、删除、重排序提交

# Reset - 移动 HEAD
git reset --soft HEAD~3   # 保留更改在暂存区
git reset --mixed HEAD~3  # 保留更改在工作目录
git reset --hard HEAD~3   # 删除所有更改
```

### 注意点：Rebase 与 Cherry-pick/Merge 的交互

#### 1. Cherry-pick 后的 Rebase（Patch-ID 去重）

Git rebase 会使用 **patch-id**（基于 diff 内容计算的哈希）自动检测并**跳过**已经通过 cherry-pick 应用过的提交。这是 Git 的**预期行为**，不是 bug：

```bash
# 场景：在 feature 分支 cherry-pick 了 main 的某个提交
git checkout feature
git cherry-pick abc123  # 从 main 选取提交

# 后续 rebase 时，abc123 会被自动跳过（因为内容已存在）
git rebase main
# 提示：dropping abc123 ... -- patch contents already upstream
```

**控制此行为**：

```bash
# 默认行为：跳过已 cherry-pick 的提交（推荐）
git rebase main

# 强制重新应用所有提交（即使已 cherry-pick，可能产生冲突）
git rebase --reapply-cherry-picks main
```

#### 2. 可能出现意外的情况

- **Patch-ID 不匹配**：如果 cherry-pick 后又修改了相关代码，patch-id 会改变，Git 无法识别为重复，可能导致冲突或重复应用
- **上游修改了提交**：如果上游对 cherry-pick 过的提交进行了 amend 或 rebase，会被视为不同提交
- **部分内容重叠**：如果提交内容只是部分重叠而非完全相同，可能产生复杂的冲突

#### 3. Merge 后的 Rebase

默认情况下，rebase 会**展平**（flatten）合并提交，丢失分支结构。使用 `--rebase-merges` 保留合并结构：

```bash
# 默认：展平合并提交
git rebase main
# 合并提交会消失，所有提交变成线性

# 保留合并结构
git rebase --rebase-merges main
# 合并提交会被重建，保留分支拓扑
```

#### 4. 最佳实践

```bash
# 在 rebase 前检查是否有 cherry-pick 过的提交
git log --oneline --cherry-mark main...HEAD
# = 表示已存在于上游（会被跳过）
# + 表示本地独有的提交

# 如果不确定，先创建备份分支
git branch backup-feature
git rebase main
```

### 选择指南

```bash
# 📋 选择流程图

# 需要合并整个分支吗？
# ├─ 是 → 继续判断
# │   ├─ 是公共/共享分支吗？
# │   │   ├─ 是 → 使用 git merge（安全）
# │   │   └─ 否 → 使用 git rebase（整洁）
# │   └─ 需要保留分支历史吗？
# │       ├─ 是 → 使用 git merge
# │       └─ 否 → 使用 git rebase
# └─ 否 → 继续判断
#     ├─ 只需要特定提交？
#     │   └─ 是 → 使用 git cherry-pick
#     └─ 需要整理提交历史？
#         └─ 是 → 使用 git rebase -i

# 简单规则：
# - 公共分支 → merge
# - 私有分支 → rebase
# - 选择提交 → cherry-pick
# - 整理历史 → rebase -i
```

---

## 总结

`git rebase` 是一个强大的历史重写工具，正确使用可以让你的提交历史更加整洁、易读。核心要点：

### 可以做什么

- ✅ 保持功能分支与主分支同步
- ✅ 创建线性、整洁的提交历史
- ✅ 合并多个小提交为逻辑完整的提交
- ✅ 修改历史提交的信息或内容
- ✅ 重新排序或删除提交
- ✅ 拆分大提交为多个小提交
- ✅ 在合并前整理 PR 的提交

### 需要注意什么

- ⚠️ **永远不要 rebase 已推送的公共分支**
- ⚠️ Rebase 会改变提交哈希，需要强制推送
- ⚠️ 使用 `--force-with-lease` 而不是 `--force`
- ⚠️ 在复杂 rebase 前创建备份分支
- ⚠️ 处理冲突时要特别小心
- ⚠️ 交互式 rebase 中提交顺序是从旧到新

### 快速参考

| 场景               | 命令                                     |
| ------------------ | ---------------------------------------- |
| 同步主分支更新     | `git rebase main`                        |
| 整理最近 N 个提交  | `git rebase -i HEAD~N`                   |
| 合并多个提交       | 交互式 rebase 中使用 `squash` / `fixup`  |
| 修改提交信息       | 交互式 rebase 中使用 `reword`            |
| 修改提交内容       | 交互式 rebase 中使用 `edit`              |
| 移植分支           | `git rebase --onto <new> <old> <branch>` |
| 解决冲突后继续     | `git rebase --continue`                  |
| 放弃 rebase        | `git rebase --abort`                     |
| 恢复 rebase 前状态 | `git reset --hard ORIG_HEAD`             |

### 黄金法则

> **只 rebase 私有分支，永不 rebase 公共分支。**

遵循这个原则，你就能安全地享受 rebase 带来的整洁历史，同时避免给团队带来麻烦！

---

## 参考资源

- [Git 官方文档 - git-rebase](https://git-scm.com/docs/git-rebase)
- [Pro Git Book - Git Branching - Rebasing](https://git-scm.com/book/zh/v2/Git-%E5%88%86%E6%94%AF-%E5%8F%98%E5%9F%BA)
