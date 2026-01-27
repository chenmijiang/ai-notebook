# Git Submodule 完全指南

## 1. 概述

### 1.1 什么是 Git Submodule

`git submodule` 是 Git 提供的一种机制，用于在一个 Git 仓库中嵌入另一个独立的 Git 仓库。子模块允许你将外部项目作为子目录引入主项目，同时保持它们各自独立的版本控制历史。

它解决的核心痛点是：

- 项目依赖外部库或组件，需要固定到特定版本
- 多个项目共享同一份代码，需要统一管理
- 需要在主项目中追踪外部项目的特定提交

一句话：`git submodule` 让你在一个仓库中嵌套引用其他仓库，同时保持版本锁定和独立管理。

### 1.2 Submodule 的工作原理

Git submodule 的核心概念是"仓库中的仓库"：

- 主项目（superproject）记录子模块的 **路径** 和 **提交哈希**
- 子模块本身是一个完整的 Git 仓库，有自己的 `.git` 目录
- 子模块默认处于 **detached HEAD** 状态，指向主项目记录的特定提交

关键文件：

| 文件            | 作用                                              |
| --------------- | ------------------------------------------------- |
| `.gitmodules`   | 存储子模块的路径和 URL 映射（跟踪在版本控制中）   |
| `.git/config`   | 本地配置（init 后生成，优先级高于 `.gitmodules`） |
| `.git/modules/` | 存储子模块的实际 Git 目录                         |

典型结构（示意）：

```
main-project/                    # 主项目
├── .git/
│   ├── config                   # 包含 submodule 配置
│   └── modules/
│       └── libs/shared-lib/     # 子模块的 git 目录
├── .gitmodules                  # 子模块映射文件
├── src/
└── libs/
    └── shared-lib/              # 子模块工作目录
        ├── .git                 # gitfile，指向 ../../.git/modules/libs/shared-lib
        └── ...
```

工作原理示意图：

```
┌─────────────────────────────────────────────────────────┐
│                     主项目 (superproject)                 │
│  记录: libs/shared-lib → commit abc1234                  │
└─────────────────────────────────────────────────────────┘
                           │
                           │ 引用特定提交
                           ▼
┌─────────────────────────────────────────────────────────┐
│                   子模块 (submodule)                      │
│  独立仓库，有自己的提交历史                                  │
│  当前 HEAD: abc1234 (detached)                           │
└─────────────────────────────────────────────────────────┘
```

> **注意**：子模块不会自动跟随远程分支更新，它锁定在主项目记录的特定提交上。这是设计使然，确保构建的可重复性。

### 1.3 Submodule vs Subtree vs 包管理器

| 方案      | 适用场景                   | 优点                         | 缺点                         |
| --------- | -------------------------- | ---------------------------- | ---------------------------- |
| Submodule | 需要独立开发的外部依赖     | 版本锁定清晰；子模块独立管理 | 工作流复杂；需要额外命令     |
| Subtree   | 想把外部代码直接合入主项目 | 无需额外命令；历史完整       | 合并历史混乱；难以向上游贡献 |
| 包管理器  | 标准的第三方库             | 生态完善；版本管理成熟       | 不适合私有或定制依赖         |

选择建议：

- ✅ 使用 **Submodule**：需要在子项目中开发并提交，或需要精确版本控制
- ✅ 使用 **Subtree**：只读引入外部代码，不需要向上游贡献
- ✅ 使用 **包管理器**：标准第三方库（npm、pip、maven 等）

## 2. 基本概念

### 2.1 Detached HEAD 状态

子模块默认处于 detached HEAD 状态，这意味着：

- HEAD 直接指向某个提交，而不是分支引用
- 可以查看代码、运行测试，但不应直接提交
- 如果需要在子模块中开发，必须先切换到分支

```bash
cd libs/shared-lib
git status
# HEAD detached at abc1234

# 切换到分支进行开发
git checkout main
# 或创建新分支
git checkout -b feature/new-feature
```

### 2.2 .gitmodules 文件

`.gitmodules` 是子模块的配置文件，跟踪在版本控制中：

```ini
[submodule "libs/shared-lib"]
    path = libs/shared-lib
    url = https://github.com/org/shared-lib.git
    branch = main

[submodule "vendor/external-tool"]
    path = vendor/external-tool
    url = git@github.com:org/external-tool.git
    shallow = true
```

常用配置项：

| 配置项    | 说明                                   |
| --------- | -------------------------------------- |
| `path`    | 子模块在主项目中的相对路径             |
| `url`     | 子模块仓库的 URL                       |
| `branch`  | 跟踪的远程分支（配合 `--remote` 使用） |
| `shallow` | 是否使用浅克隆                         |
| `update`  | 更新策略（checkout/rebase/merge/none） |

### 2.3 子模块的三种状态

使用 `git submodule status` 查看状态时，前缀符号表示不同状态：

| 前缀        | 含义       | 说明                               |
| ----------- | ---------- | ---------------------------------- |
| ` `（空格） | 正常       | 子模块 HEAD 与主项目记录一致       |
| `-`         | 未初始化   | 子模块尚未 init/update             |
| `+`         | 提交不匹配 | 子模块 HEAD 与主项目记录的提交不同 |
| `U`         | 合并冲突   | 子模块存在未解决的合并冲突         |

## 3. 基本用法

### 3.1 添加子模块

```bash
# 基本用法
git submodule add <repository-url> <path>

# 示例：添加共享库到 libs 目录
git submodule add https://github.com/org/shared-lib.git libs/shared-lib
```

常用选项：

```bash
# 指定跟踪的分支
git submodule add -b main https://github.com/org/shared-lib.git libs/shared-lib

# 使用浅克隆（节省空间）
git submodule add --depth 1 https://github.com/org/shared-lib.git libs/shared-lib

# 自定义子模块名称
git submodule add --name my-lib https://github.com/org/shared-lib.git libs/shared-lib
```

添加后需要提交：

```bash
git add .gitmodules libs/shared-lib
git commit -m "chore: add shared-lib submodule"
```

### 3.2 克隆包含子模块的项目

#### 3.2.1 一步到位（推荐）

```bash
# 克隆时同时初始化所有子模块
git clone --recurse-submodules https://github.com/org/main-project.git

# 并行克隆子模块（加速）
git clone --recurse-submodules --jobs 8 https://github.com/org/main-project.git
```

#### 3.2.2 分步操作

```bash
# 1. 先克隆主项目
git clone https://github.com/org/main-project.git
cd main-project

# 2. 初始化并更新子模块
git submodule update --init --recursive

# 或分开执行
git submodule init
git submodule update --recursive
```

### 3.3 查看子模块状态

```bash
# 查看所有子模块状态
git submodule status

# 递归查看（包括嵌套子模块）
git submodule status --recursive

# 查看索引中记录的提交（而非工作目录）
git submodule status --cached
```

输出示例：

```text
 abc1234 libs/shared-lib (v1.2.0)
+def5678 vendor/external-tool (heads/main)
-9876fed libs/another-lib
```

### 3.4 更新子模块

#### 3.4.1 更新到主项目记录的提交

```bash
# 更新所有子模块
git submodule update

# 递归更新（包括嵌套子模块）
git submodule update --recursive

# 初始化未初始化的子模块并更新
git submodule update --init --recursive
```

#### 3.4.2 更新到远程最新提交

```bash
# 拉取子模块远程分支的最新提交
git submodule update --remote

# 指定更新策略
git submodule update --remote --merge    # 合并到当前分支
git submodule update --remote --rebase   # 变基到最新提交

# 更新特定子模块
git submodule update --remote libs/shared-lib
```

> **注意**：使用 `--remote` 后，子模块的提交会变化，需要在主项目中提交这个变更。

#### 3.4.3 配合 git pull 使用

```bash
# 拉取主项目并更新子模块
git pull --recurse-submodules

# 等效于
git pull
git submodule update --init --recursive
```

### 3.5 在子模块中进行开发

```bash
# 1. 进入子模块目录
cd libs/shared-lib

# 2. 切换到工作分支（脱离 detached HEAD）
git checkout main
# 或创建新分支
git checkout -b feature/new-feature

# 3. 进行修改、提交
# ... 编辑文件 ...
git add .
git commit -m "feat: add new feature"

# 4. 推送子模块的更改
git push origin feature/new-feature

# 5. 返回主项目，更新子模块引用
cd ../..
git add libs/shared-lib
git commit -m "chore: update shared-lib to latest"
git push
```

### 3.6 删除子模块

删除子模块需要多个步骤：

```bash
# 1. 从 .gitmodules 中移除配置
git config -f .gitmodules --remove-section submodule.libs/shared-lib

# 2. 从 .git/config 中移除配置
git config --remove-section submodule.libs/shared-lib

# 3. 从暂存区移除
git rm --cached libs/shared-lib

# 4. 删除子模块目录
rm -rf libs/shared-lib

# 5. 删除 .git/modules 中的数据
rm -rf .git/modules/libs/shared-lib

# 6. 提交更改
git add .gitmodules
git commit -m "chore: remove shared-lib submodule"
```

更简洁的方式（Git 1.8.5+）：

```bash
# 使用 deinit 清理配置
git submodule deinit -f libs/shared-lib

# 删除子模块
git rm -f libs/shared-lib

# 删除 .git/modules 中的残留
rm -rf .git/modules/libs/shared-lib

# 提交
git commit -m "chore: remove shared-lib submodule"
```

## 4. 进阶用法

### 4.1 同步子模块 URL

当 `.gitmodules` 中的 URL 变更后，需要同步到本地配置：

```bash
# 同步所有子模块
git submodule sync

# 递归同步
git submodule sync --recursive

# 同步特定子模块
git submodule sync -- libs/shared-lib

# 同步后需要重新更新
git submodule update --init --recursive
```

### 4.2 修改子模块 URL

```bash
# 方法 1：使用 set-url 命令（Git 2.25+）
git submodule set-url libs/shared-lib https://github.com/new-org/shared-lib.git

# 方法 2：手动修改 .gitmodules 后同步
# 编辑 .gitmodules 文件中的 url
git submodule sync
```

### 4.3 修改子模块跟踪的分支

```bash
# 设置跟踪分支
git submodule set-branch -b develop libs/shared-lib

# 重置为默认分支（远程 HEAD）
git submodule set-branch -d libs/shared-lib
```

### 4.4 批量操作子模块（foreach）

`foreach` 命令可以在所有子模块中执行命令：

```bash
# 查看每个子模块的状态
git submodule foreach 'git status'

# 拉取所有子模块的最新代码
git submodule foreach 'git pull origin main'

# 清理所有子模块的未跟踪文件
git submodule foreach 'git clean -fd'

# 切换所有子模块到特定分支
git submodule foreach 'git checkout main || true'

# 递归执行（包括嵌套子模块）
git submodule foreach --recursive 'git fetch --all'
```

foreach 中可用的变量：

| 变量           | 说明                           |
| -------------- | ------------------------------ |
| `$name`        | 子模块名称（来自 .gitmodules） |
| `$sm_path`     | 子模块在主项目中的路径         |
| `$displaypath` | 相对于当前目录的路径           |
| `$sha1`        | 主项目记录的子模块提交         |
| `$toplevel`    | 主项目的绝对路径               |

### 4.5 浅克隆子模块

对于大型子模块，可以使用浅克隆节省空间和时间：

```bash
# 添加时使用浅克隆
git submodule add --depth 1 https://github.com/org/large-repo.git vendor/large-repo

# 更新时使用浅克隆
git submodule update --init --depth 1

# 在 .gitmodules 中配置
# [submodule "vendor/large-repo"]
#     shallow = true
```

### 4.6 absorbgitdirs

将子模块的 `.git` 目录移动到主项目的 `.git/modules` 中：

```bash
git submodule absorbgitdirs
```

这在以下场景有用：

- 手动将现有仓库转换为子模块
- 统一管理所有 git 目录

## 5. 日常开发场景

### 5.1 场景 1：团队协作中的子模块更新

当其他人更新了子模块引用，你拉取主项目后：

```bash
# 拉取主项目
git pull

# 看到提示：子模块有更新
# Fetching submodule libs/shared-lib

# 方法 1：手动更新子模块
git submodule update --init --recursive

# 方法 2：配置自动更新（推荐）
git config --global submodule.recurse true
# 之后 git pull 会自动更新子模块
```

### 5.2 场景 2：在子模块中开发新功能

```bash
# 1. 进入子模块
cd libs/shared-lib

# 2. 确保在正确的分支上
git checkout main
git pull origin main

# 3. 创建功能分支
git checkout -b feature/awesome-feature

# 4. 开发、测试、提交
# ... 编写代码 ...
git add .
git commit -m "feat: add awesome feature"

# 5. 推送子模块分支
git push -u origin feature/awesome-feature

# 6. 回到主项目，暂时使用这个新分支
cd ../..
git add libs/shared-lib
git commit -m "wip: testing new feature in shared-lib"

# 7. 子模块 PR 合并后，更新主项目
cd libs/shared-lib
git checkout main
git pull
cd ../..
git add libs/shared-lib
git commit -m "chore: update shared-lib with awesome feature"
```

### 5.3 场景 3：修复子模块版本回退问题

有时切换分支后，子模块版本可能不匹配：

```bash
# 切换分支
git checkout feature/old-feature

# 子模块状态可能显示 +（不匹配）
git submodule status
# +abc1234 libs/shared-lib (heads/main)

# 更新子模块到当前分支记录的版本
git submodule update --recursive

# 验证
git submodule status
#  def5678 libs/shared-lib (v1.0.0)
```

### 5.4 场景 4：CI/CD 中的子模块处理

GitHub Actions 示例：

```yaml
name: CI
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout with submodules
        uses: actions/checkout@v4
        with:
          submodules: recursive # 或 'true' 只获取直接子模块

      # 对于私有子模块，需要配置认证
      - name: Checkout with private submodules
        uses: actions/checkout@v4
        with:
          submodules: recursive
          token: {% raw %}${{ secrets.PAT_TOKEN }}{% endraw %}
```

GitLab CI 示例：

```yaml
variables:
  GIT_SUBMODULE_STRATEGY: recursive
  GIT_SUBMODULE_DEPTH: 1 # 可选：浅克隆

build:
  script:
    - echo "Submodules already initialized"
```

### 5.5 场景 5：创建项目初始化脚本

为团队成员简化子模块初始化：

```bash
#!/bin/bash
# setup.sh - 项目初始化脚本

set -e

echo "Initializing project..."

# 初始化并更新所有子模块
git submodule update --init --recursive --jobs 4

# 让子模块跟踪各自的分支（可选）
git submodule foreach -q --recursive \
  'branch=$(git config -f $toplevel/.gitmodules submodule.$name.branch); \
   if [ -n "$branch" ]; then git checkout $branch; fi'

echo "Project initialized successfully!"
```

## 6. 常用命令速查

### 6.1 命令速查表

| 目的           | 命令                                      | 说明                      |
| -------------- | ----------------------------------------- | ------------------------- |
| 添加子模块     | `git submodule add <url> <path>`          | 添加新的子模块            |
| 克隆含子模块   | `git clone --recurse-submodules <url>`    | 一步完成克隆和初始化      |
| 初始化子模块   | `git submodule update --init --recursive` | 初始化并更新所有子模块    |
| 更新到记录版本 | `git submodule update --recursive`        | 更新到主项目记录的提交    |
| 更新到远程最新 | `git submodule update --remote`           | 拉取远程分支最新提交      |
| 查看状态       | `git submodule status --recursive`        | 查看所有子模块状态        |
| 同步 URL       | `git submodule sync --recursive`          | 同步 .gitmodules 中的 URL |
| 批量执行       | `git submodule foreach '<cmd>'`           | 在所有子模块中执行命令    |
| 反初始化       | `git submodule deinit <path>`             | 取消注册子模块            |

### 6.2 常用配置

```bash
# 全局配置：pull 时自动更新子模块
git config --global submodule.recurse true

# 全局配置：diff 时显示子模块摘要
git config --global diff.submodule log

# 全局配置：status 显示子模块摘要
git config --global status.submoduleSummary true

# 项目配置：设置子模块默认更新策略
git config -f .gitmodules submodule.libs/shared-lib.update rebase
```

## 7. 最佳实践与注意事项

### 7.1 推荐做法

```bash
# ✅ 克隆时总是使用 --recurse-submodules
git clone --recurse-submodules <url>

# ✅ 配置自动更新子模块
git config --global submodule.recurse true

# ✅ 在 CI 中使用并行克隆
git submodule update --init --recursive --jobs 8

# ✅ 修改子模块后，先推送子模块再推送主项目
cd submodule && git push
cd .. && git push

# ✅ 使用 .gitmodules 中的 branch 配置明确跟踪分支
git submodule set-branch -b main libs/shared-lib
```

### 7.2 避免的做法

```bash
# ❌ 忘记初始化子模块就开始开发
git clone <url>  # 没有 --recurse-submodules
cd project
npm install  # 失败：子模块目录为空

# ❌ 在 detached HEAD 状态下提交
cd libs/shared-lib
git commit -m "changes"  # 危险：可能丢失提交

# ❌ 推送主项目但忘记推送子模块
git add libs/shared-lib
git commit -m "update submodule"
git push  # 其他人无法获取子模块的新提交

# ❌ 嵌套过深的子模块
# 子模块包含子模块包含子模块... 维护噩梦
```

### 7.3 子模块与 Worktree

在使用 `git worktree` 时，子模块需要特别注意：

```bash
# 创建新 worktree 后，需要单独初始化子模块
git worktree add ../project-feature feature/x
cd ../project-feature
git submodule update --init --recursive

# 不同 worktree 的子模块是独立的
# 避免在多个 worktree 同时修改同一个子模块
```

### 7.4 处理私有子模块

对于私有仓库的子模块：

```bash
# 使用 SSH URL（推荐）
git submodule add git@github.com:org/private-lib.git libs/private-lib

# 或在 .gitmodules 中配置相对 URL
[submodule "libs/private-lib"]
    path = libs/private-lib
    url = ../private-lib.git  # 相对于主项目的远程 URL
```

## 8. 常见问题（FAQ）

**Q1：为什么子模块目录是空的？**

子模块需要初始化才能获取内容：

```bash
git submodule update --init --recursive
```

**Q2：如何查看主项目记录的子模块提交？**

```bash
# 方法 1：查看 .gitmodules 和 git 树
git ls-tree HEAD libs/shared-lib

# 方法 2：使用 status
git submodule status
```

**Q3：子模块更新后为什么构建失败？**

可能是子模块没有正确更新到记录的版本：

```bash
# 强制更新到主项目记录的版本
git submodule update --init --recursive --force
```

**Q4：如何让子模块始终跟踪某个分支的最新提交？**

```bash
# 1. 设置跟踪分支
git submodule set-branch -b main libs/shared-lib

# 2. 使用 --remote 更新
git submodule update --remote libs/shared-lib

# 3. 提交变更
git add libs/shared-lib
git commit -m "chore: update shared-lib to latest main"
```

**Q5：如何处理子模块的合并冲突？**

```bash
# 1. 进入子模块目录
cd libs/shared-lib

# 2. 确认当前状态
git status

# 3. 解决冲突（通常选择一个版本）
git checkout --theirs .  # 使用他们的版本
# 或
git checkout --ours .    # 使用我们的版本

# 4. 返回主项目，标记冲突已解决
cd ..
git add libs/shared-lib
```

**Q6：为什么推送主项目后，其他人拉取时子模块报错？**

可能是子模块的新提交没有推送。解决方案：

```bash
# 推送时检查子模块
git push --recurse-submodules=check

# 或自动推送子模块
git push --recurse-submodules=on-demand
```

**Q7：如何将普通目录转换为子模块？**

```bash
# 1. 备份目录内容
mv libs/shared-lib libs/shared-lib-backup

# 2. 添加为子模块
git submodule add https://github.com/org/shared-lib.git libs/shared-lib

# 3. 恢复必要的本地修改
# ...

# 4. 清理备份
rm -rf libs/shared-lib-backup

# 5. 提交
git add .
git commit -m "chore: convert shared-lib to submodule"
```

## 9. 总结

`git submodule` 是管理项目依赖和代码复用的强大工具，尤其适合：

- 需要独立版本控制的共享库
- 多项目共享同一份代码
- 需要锁定外部依赖到特定版本

核心要点速记：

- ✅ 子模块跟踪的是特定提交，而非分支
- ✅ 克隆时使用 `--recurse-submodules`，或之后运行 `git submodule update --init --recursive`
- ✅ 修改子模块后，需要在主项目中提交对子模块的引用更新
- ✅ 先推送子模块，再推送主项目
- ✅ 配置 `submodule.recurse true` 简化日常操作

### 9.1 速查表

| 目的               | 命令                                           |
| ------------------ | ---------------------------------------------- |
| 添加子模块         | `git submodule add <url> <path>`               |
| 克隆含子模块的项目 | `git clone --recurse-submodules <url>`         |
| 初始化子模块       | `git submodule update --init --recursive`      |
| 更新到远程最新     | `git submodule update --remote`                |
| 查看状态           | `git submodule status`                         |
| 同步 URL 配置      | `git submodule sync --recursive`               |
| 删除子模块         | `git submodule deinit <path> && git rm <path>` |

## 10. 参考资源

- [Git 官方文档 - git-submodule](https://git-scm.com/docs/git-submodule)
- [Pro Git Book - Git 工具 - 子模块](https://git-scm.com/book/zh/v2/Git-%E5%B7%A5%E5%85%B7-%E5%AD%90%E6%A8%A1%E5%9D%97)
- [Atlassian Git Tutorial - Git Submodules](https://www.atlassian.com/git/tutorials/git-submodule)
- [GitHub Gist - Git Submodules Best Practices](https://gist.github.com/slavafomin/08670ec0c0e75b500edbaa5d43a5c93c)
