# Git Commit Message Convention

本项目采用 Conventional Commits 规范，以提供清晰的提交历史和自动化变更日志生成。

## 提交信息格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

## Type（类型）

必须是以下之一：

- **feat**: 新增功能
- **fix**: 修复 bug
- **docs**: 文档变更（README、API 文档等）
- **style**: 代码风格变更（不影响代码功能，如空格、格式等）
- **refactor**: 代码重构（既不是新增功能也不是修复 bug）
- **perf**: 性能优化
- **test**: 添加或修改测试
- **ci**: CI/CD 配置变更
- **chore**: 构建、依赖、工具变更等

## Scope（范围）- 可选

用括号括起来，指定提交影响的范围。例如：

- `(docs)` - 文档相关
- `(guide)` - 指南相关
- `(build)` - 构建相关
- `(ci)` - CI 相关

## Subject（主题）

- 使用祈使句，不要用过去式或现在进行式
- 首字母不大写
- 句末不加句号
- 限制在 50 个字符以内
- 清晰、简洁地说明做了什么

## Body（正文）- 可选

- 说明变更的动机和详细内容
- 每行不超过 72 个字符
- 如果是新增功能，说明设计思路
- 如果是修复 bug，说明问题现象和解决方案

## Footer（页脚）- 可选

### Breaking Changes

如果提交包含重大变更，在页脚中声明：

```
BREAKING CHANGE: 描述破坏性变更
```

### Issue References

引用相关 issue：

```
Closes #123
Fixes #456
Relates to #789
```

## 示例

### 基础示例

```
feat(docs): add Python concurrency guide

Add a comprehensive guide covering threading, async/await, and multiprocessing.
Includes practical examples and performance comparisons.

Closes #42
```

### 修复示例

```
fix(docs): correct typo in async example code

The Event.wait() example had incorrect parameter documentation.

Fixes #15
```

### 文档更新示例

```
docs: update readme with new structure
```

### 重构示例

```
refactor: reorganize guide structure for better clarity
```

## 最佳实践

1. **频繁小提交**：将大的变更拆分成多个逻辑清晰的小提交
2. **描述 Why**：不仅说明做了什么，更要说明为什么这样做
3. **关联 Issue**：使用 Issue 引用来建立提交与需求的联系
4. **检查拼写**：提交前检查提交信息的拼写和语法

## 自动化

本项目使用 Husky 和提交钩子来确保提交信息符合规范。

如果提交信息不符合规范，提交将被拒绝。
