# Git Worktree 完全指南

## 1. 概述

### 1.1 什么是 Git Worktree

`git worktree` 用来管理本地同一个仓库（repository）下的多个工作区（working tree）。它允许你在不同目录中同时检出多个分支或提交，从而并行开发/测试。

它解决的核心痛点是：

- 你想切换到另一个分支处理任务，但当前分支还有未完成的修改
- 你需要同时维护多个版本（比如 `main` 修 bug、`feature/*` 开发新需求、`release/*` 打包）
- 你希望并行跑不同分支的测试/构建，而不是反复 `git checkout`

一句话：`git worktree` 让"一个仓库，多份工作区"成为原生能力。

### 1.2 Worktree 的工作原理

Git 的一个"仓库"（repository）可以绑定多个工作区：

- 一个 **主工作区**（通常就是你 `git clone` 得到的目录）
- 多个 **附加工作区**（由 `git worktree add` 创建）

这些工作区共享同一套对象数据库（`.git/objects`），因此：

- ✅ 不会重复下载/存储提交对象（比多次 clone 更省空间）
- ✅ 分支切换互不干扰（每个工作区固定检出某个分支或某个提交）
- ✅ 可以在不同目录里并行工作（测试、编译、review）

典型结构（示意）：

```
repo/                      # 主 worktree
├── .git/                  # 主 worktree 的 git 目录（或 gitfile）
├── src/
└── ...

repo/.git/worktrees/       # worktree 元数据（每个附加 worktree 一份）

../repo-feature-x/         # 附加 worktree 1
├── .git                   # 指向主仓库的 gitfile
├── src/
└── ...

../repo-hotfix/            # 附加 worktree 2
├── .git                   # 指向主仓库的 gitfile
├── src/
└── ...
```

工作原理示意图：

```
┌─────────────────────────────────────────────────────┐
│            共享的 Git 对象数据库                       │
│         repo/.git/objects, refs, hooks              │
└─────────────────────────────────────────────────────┘
                        ▲
                        │ 共享引用
        ┌───────────────┼────────────────┐
        │               │                │
    ┌───▼──┐      ┌─────▼───┐      ┌─────▼──┐
    │ repo │      │repo-fe  │      │repo-fix│
    │(main)│      │-x       │      │        │
    └──────┘      │(feature)│      │(hotfix)│
                  └─────────┘      └────────┘
```

> **注意**：附加 worktree 目录中通常不会有完整的 `.git/` 目录，而是一个指向主仓库的"gitfile"。

### 1.3 与 clone / stash 的区别

很多人第一次遇到并行开发需求时，会用 `git stash` 或者多次 `git clone`。它们都能"凑合"，但 `git worktree` 更适合长期和频繁并行。

| 方案             | 适合场景         | 优点                                   | 缺点                                                         |
| ---------------- | ---------------- | -------------------------------------- | ------------------------------------------------------------ |
| `git stash`      | 临时切走一会儿   | 快；不新增目录                         | 容易忘；冲突概率高；不适合多线程工作                         |
| 多次 `git clone` | 彻底隔离         | 最直观；彼此无关联                     | 占空间；更新维护成本高；多个 clone 的 remotes/配置容易不一致 |
| `git worktree`   | 并行分支长期共存 | 省空间；共享对象；切换成本低；结构清晰 | 需要理解 worktree 约束；需要正确清理                         |

## 2. 基本概念

### 2.1 主 worktree 与附加 worktree

- **主 worktree**：你最初 clone 得到的目录；它可以检出任意分支
- **附加 worktree**：额外创建的工作目录；通常绑定到某个特定分支

### 2.2 分支锁定（为什么不能在两个 worktree 同时检出同一分支）

Git 默认不允许同一个本地分支同时被多个 worktree 检出：

- 原因：同一个分支的 HEAD / index / working directory 状态无法被多地同时维护
- 表现：当你尝试 `worktree add` 一个已被检出的分支，会报错

```bash
# 假设 main 已在主 worktree 检出
git worktree add ../repo-main2 main
# fatal: 'main' is already checked out at '/path/to/repo'
```

如果你确实需要同一份代码在两个目录存在，通常有三种方法：

1. 基于同一 commit 创建另一个分支（推荐）
2. 使用 detached HEAD（临时检出，可修改但改动需及时保存）
3. 再 clone（极少数需要完全隔离配置时）

### 2.3 Detached HEAD worktree

你可以把 worktree 绑定到某个提交（而不是分支），这样的 worktree 称为 detached HEAD 状态：

```bash
git worktree add --detach ../repo-debug HEAD~3
```

**核心特性**：

- ✅ 可以修改、测试、甚至提交（非只读）
- ✅ 修改不会影响任何分支
- ⚠️ 改动必须创建分支才能保存，否则删除 worktree 时会丢失

> **重要**：在 detached worktree 里做了改动就**立刻创建分支** `git switch -c <branch>` 保存。

## 3. 安装与前置条件

`git worktree` 从 Git 2.5 引入，现代 Git 基本都内置。

```bash
git --version
# 建议 >= 2.30（体验更好）
```

> **说明**：不同平台自带 Git 版本差异较大（特别是 macOS 的系统 Git）。如果遇到行为不一致，优先升级 Git（例如 brew 安装）。

## 4. 基本用法

### 4.1 查看 worktree 列表

```bash
git worktree list
```

输出示例：

```text
/Users/me/repo                abc1234 [main]
/Users/me/repo-feature-x      def5678 [feature/x]
/Users/me/repo-hotfix         9876fed [hotfix/urgent]
```

常用选项：

```bash
# 输出机器可读格式（便于脚本解析）
git worktree list --porcelain
```

### 4.2 创建新的 worktree

#### 4.2.1 不指定分支时的默认行为

当你只提供路径时：

```bash
git worktree add ../hotfix
```

Git 会把路径的最后一段（这里是 `hotfix`）当做分支名：

- 如果 `hotfix` 分支不存在：自动从当前 `HEAD` 创建并检出 `hotfix`
- 如果 `hotfix` 分支已存在：尝试直接检出（但如果它已被其它 worktree 占用会失败，除非 `--force`）

#### 4.2.2 基于已有分支创建

```bash
# 把已存在的分支检出到新 worktree
git worktree add ../repo-feature-x feature/x
```

#### 4.2.3 创建新分支并创建 worktree（最常用）

```bash
# -b: 创建新分支 | ../repo-feature-x: worktree 目录 | origin/main: 新分支起点
git worktree add -b feature/x ../repo-feature-x origin/main
```

含义：

- `-b feature/x`：创建本地分支
- `../repo-feature-x`：worktree 目录
- `origin/main`：以哪个起点创建（也可以是 `main` 或某个 commit）

#### 4.2.4 使用 detached HEAD 创建

```bash
# 基于某个版本号或提交 hash 创建 detached worktree
git worktree add --detach ../repo-debug v1.2.3
```

### 4.3 切换分支（在特定 worktree 内）

进入某个 worktree 后，它和普通仓库使用方式一致：

```bash
cd ../repo-feature-x
git status
# 在该 worktree 内切换到新分支
git switch -c feature/x-2
```

> **注意**：如果你在附加 worktree 里 `git switch main`，可能会失败（因为 main 已在主 worktree 检出）。

### 4.4 删除 worktree

```bash
git worktree remove ../repo-feature-x
```

只有"干净"的 worktree（无已跟踪文件修改、无未跟踪文件）才能被删除；否则 Git 会拒绝：

```bash
# 强制删除（谨慎）
git worktree remove --force ../repo-feature-x
```

### 4.5 移动 worktree（move）

当你需要重命名目录或调整 worktree 的存放位置时，优先用 `move` 而不是手动 `mv`：

```bash
# 把 worktree 移动到新路径
git worktree move ../repo-feature-x ../repo-feature-x-renamed
```

> **注意**：主 worktree 不能用 `move`。如果你手动移动了主 worktree，建议用 `git worktree repair` 重新建立关联。

### 4.6 锁定 worktree（lock/unlock）

当 worktree 放在可移动磁盘/网络盘上（可能会临时断开挂载）时，建议锁定它以避免被自动清理：

```bash
# 锁定，附带原因说明
git worktree lock --reason "mounted on external disk" ../repo-debug

# 解锁
git worktree unlock ../repo-debug
```

### 4.7 修复 worktree（repair）

当你手动移动了 worktree 目录，或 `.git` 连接文件损坏导致 worktree 失联时，可以尝试修复：

```bash
# 在任意 worktree 里执行，修复当前 worktree
git worktree repair

# 修复指定路径（可一次多个）
git worktree repair ../repo-feature-x ../repo-hotfix
```

### 4.8 清理遗留元数据（prune）

当你手动删除了 worktree 目录，或者目录损坏时，仓库内可能残留记录。

```bash
git worktree prune
```

建议搭配检查：

```bash
git worktree list
```

## 5. 日常开发场景

### 5.1 场景 1：一边开发新功能，一边在 main 修紧急问题

目标：

- `../repo-feature-x` 开发 feature
- 主目录 `repo/` 保持 `main` 干净，随时修 hotfix

操作流程：

```bash
# 1. 主目录：保持 main
cd repo
git switch main

# 2. 创建 feature worktree（新分支）
git worktree add -b feature/x ../repo-feature-x origin/main

# 3. 在 feature worktree 开发
cd ../repo-feature-x
# 编写代码、测试、提交...
git add .
git commit -m "feat: 添加新功能"

# 4. 紧急 bug 来了：回到主目录处理
cd ../repo
git switch -c hotfix/urgent
# 修复 bug、测试、提交、push...
git add .
git commit -m "fix: 修复紧急 bug"
git push
```

优势：

- ✅ 不需要 stash
- ✅ 不需要频繁 checkout
- ✅ 两条线互不影响

### 5.2 场景 2：并行跑测试/构建

例子：

- `main` 跑全量测试
- `feature/x` 跑增量/本地开发

```bash
# worktree A: 主目录跑测试
cd repo
npm test

# worktree B: 另开窗口，在 feature worktree 开发和调试
cd ../repo-feature-x
npm run dev
```

> **提示**：如果项目会生成大量构建产物（dist、.next、target 等），worktree 比 "同目录切分支" 更干净。

### 5.3 场景 3：Review PR 或复现 CI 失败

你可以把某个远端分支拉到独立 worktree，用完就删：

```bash
# 1. 拉取 PR 分支
git fetch origin pull/123/head:pr/123

# 2. 创建 worktree 检出该分支
git worktree add ../repo-pr-123 pr/123

# 3. 在隔离环境复现、跑测试、review
cd ../repo-pr-123
npm test
npm run build

# 4. 用完后清理（两个命令都需要）
cd ../repo
git worktree remove ../repo-pr-123
git branch -D pr/123
```

### 5.4 场景 4：用 detached worktree debug 和修复老版本

detached worktree 特别适合调试历史版本。根据需求不同，有两类操作流程：

#### 5.4.1 场景 A：验证老版本（临时查看，无需保存改动）

目标：快速在某个历史版本验证 bug 是否存在，验证后丢弃。

```bash
# 1. 创建 detached worktree 检出历史版本
git worktree add --detach ../repo-verify v1.0.0

# 2. 进入 worktree 并验证
cd ../repo-verify
npm install
npm test  # 验证 bug 是否存在

# 3. 验证完毕，返回主目录清理 worktree（改动自动丢弃）
cd ../repo
git worktree remove ../repo-verify
```

优点：

- 快速验证历史版本状态
- 不产生任何分支或提交记录
- 完全隔离，不影响当前工作

#### 5.4.2 场景 B：修复老版本（需要保存改动）

目标：在历史版本上修复 bug，并保存为新分支。

```bash
# 1. 创建 detached worktree 检出历史版本
git worktree add --detach ../repo-bugfix v0.9.0

# 2. 进入 worktree 并修复问题
cd ../repo-bugfix
# 编写、测试修复代码...
npm test

# 3. 重要：改动需要保存，立刻创建分支
git switch -c fix/v0.9.0-patch
# 此时所有修改都已转移到新分支
# 可以继续 git add / git commit（如果有新改动）

# 4. 返回主仓库，清理 worktree（分支已安全保存）
cd ../repo
git worktree remove ../repo-bugfix

# 5. 新分支已创建并包含改动，可继续操作
git log -1 --oneline fix/v0.9.0-patch
git switch fix/v0.9.0-patch  # 继续在该分支上工作
```

**核心原则**：改动完成立即创建分支，否则删除 worktree 时丢失。

### 5.5 场景 5：配合 rebase / cherry-pick 做对比验证

当你需要对比 rebase 前后行为，worktree 特别好用：

```bash
# 1. 创建一个对照 worktree（记录 rebase 前状态）
git worktree add ../repo-before-rebase main

# 2. 在主目录做 rebase
cd repo
git switch feature/x
git rebase main

# 3. 在对照 worktree 跑验证（old 行为）
cd ../repo-before-rebase
npm test

# 4. 回到主目录跑验证（new 行为）
cd ../repo
npm test

# 5. 对比结果，确认 rebase 安全后清理
git worktree remove ../repo-before-rebase
```

## 6. 常用命令速查

### 6.1 常见错误与定位

遇到问题时可以用以下命令快速诊断：

```bash
# 查看分支被哪个 worktree 占用
git worktree list

# 查看某个 worktree 的 gitfile 指向
cat <worktree-path>/.git

# 检查 worktree 列表是否有残留
git worktree list

# 清理失效元数据
git worktree prune
```

## 7. 最佳实践与注意事项

### 7.1 Worktree 目录放哪里

推荐策略：

- 主仓库：`~/code/repo`
- worktree：`~/code/wt/repo-<branch>` 或 `../repo-<branch>`

这样好处是：

- 清理方便
- 不会把 worktree 嵌套到另一个 worktree 内（避免混乱）

### 7.2 给 worktree 起"能排序"的名字

```text
repo-wt-main
repo-wt-feature-x
repo-wt-hotfix-urgent
repo-wt-pr-123
```

文件夹名能直接体现用途，比只用分支名更直观。

### 7.3 不要在多个 worktree 共享同一个构建输出目录

某些构建脚本会写入固定路径（比如 `dist/`），这在 worktree 模式下一般没事，
但如果你把输出目录重定向到共享路径（例如 `../dist`），可能造成互相覆盖。

- ✅ 每个 worktree 自己产出一套 build
- ❌ 多个 worktree 写同一个 build 目录

### 7.4 删除 worktree 前先处理分支生命周期

worktree 删除只影响工作区，不一定会删除分支。

常见流程：

```bash
# 1. 先 remove worktree
git worktree remove ../repo-feature-x

# 2. 再决定是否删分支
git branch -d feature/x
# 或强制删除
git branch -D feature/x
```

### 7.5 处理"目录已不存在，但 Git 还认为存在"的情况

```bash
# 先清理元数据
git worktree prune

# 再确认
git worktree list
```

### 7.6 子模块与 worktree

worktree 对子模块也能用，但注意：

- 子模块本身也有自己的工作区状态
- 不同 worktree 下更新子模块可能会产生不同的检出状态

建议：

- 在每个 worktree 内独立运行 `git submodule update --init --recursive`
- 避免在多个 worktree 同时对同一个子模块做改动

## 8. Git Worktree vs 相关命令

### 8.1 Worktree vs Stash

| 维度       | Worktree        | Stash                  |
| ---------- | --------------- | ---------------------- |
| 并行开发   | ✅ 天然支持     | ❌ 需要不停存取        |
| 上下文保存 | ✅ 目录即上下文 | ⚠️ 容易忘记 stash 内容 |
| 适合时长   | 中长期          | 短期                   |
| 冲突风险   | 低（彼此隔离）  | 中高（恢复时易冲突）   |

### 8.2 Worktree vs Clone

| 维度            | Worktree           | 多次 clone               |
| --------------- | ------------------ | ------------------------ |
| 磁盘占用        | 低（共享 objects） | 高（重复 objects）       |
| 远端/配置一致性 | ✅ 天然一致        | ❌ 可能不一致            |
| 隔离程度        | 中（共享仓库）     | 高（完全独立）           |
| 适用场景        | 并行分支开发       | 需要彻底隔离配置或权限时 |

## 9. 常见问题（FAQ）

**Q1：为什么我不能在第二个 worktree 里 checkout main？**

因为 main 已被另一个 worktree 检出，Git 会阻止同一分支被多个 worktree 同时使用。

解决思路：

- 创建一个新分支：`git switch -c main-copy`
- 或创建 detached worktree：`git worktree add --detach <path> main`

**Q2：我把 worktree 目录 rm -rf 了，现在 git worktree list 还在？**

运行：

```bash
git worktree prune
```

这会清理所有失效的 worktree 元数据。

**Q3：删除 worktree 时报错"worktree contains modified files"怎么办？**

这是安全保护——Git 不允许删除包含未提交改动的 worktree。解决方案：

```bash
# 方案 1: 进入 worktree 提交或放弃改动
cd ../repo-feature-x
git add .
git commit -m "save changes"

# 或丢弃改动
git reset --hard HEAD

# 方案 2: 强制删除（不推荐，容易丢失代码）
git worktree remove --force ../repo-feature-x
```

**Q4：worktree 中的改动会影响其他 worktree 吗？**

不会。每个 worktree 有独立的工作目录、index 和 HEAD，改动不会相互影响。但是：

- ✅ 各 worktree 独立管理文件状态
- ❌ 如果多个 worktree 同时 push 同一分支会有冲突（这是正常 Git 问题，不是 worktree 特有）

**Q5：worktree 对大仓库有特殊支持吗？**

有。worktree 特别适合大仓库：

- 省空间：共享 `.git/objects`，不重复存储
- 快速：创建 worktree 只需几毫秒（vs clone 需要分钟级）
- 节省带宽：无需重复下载对象

## 10. 总结

`git worktree` 是解决并行分支开发的"正统方案"，尤其适合：

- 同时处理 feature / hotfix / release
- 本地复现 PR、CI、历史 bug
- 并行测试与构建

核心要点速记：

- ✅ 一个仓库可以有多个工作区，节省空间
- ✅ 同一分支不能被多个 worktree 同时检出
- ✅ 用完及时 `git worktree remove`，异常时 `git worktree prune`
- ✅ detached worktree 适合临时 debug，但要记得创建分支保存提交

### 10.1 速查表

| 目的                      | 命令                                     | 说明                     |
| ------------------------- | ---------------------------------------- | ------------------------ |
| 查看 worktree             | `git worktree list`                      | 列出所有 worktree        |
| 新建 worktree（已有分支） | `git worktree add <path> <branch>`       | 把分支检出到新目录       |
| 新建 worktree（新分支）   | `git worktree add -b <b> <path> <start>` | 最常用                   |
| detached worktree         | `git worktree add --detach <path> <rev>` | debug/回归               |
| 删除 worktree             | `git worktree remove <path>`             | 删除工作区               |
| 清理记录                  | `git worktree prune`                     | 清掉失效 worktree 元数据 |

## 11. 参考资源

- [Git 官方文档 - git-worktree](https://git-scm.com/docs/git-worktree)
- [Pro Git Book - 分支与工作流相关章节](https://git-scm.com/book/zh/v2)
