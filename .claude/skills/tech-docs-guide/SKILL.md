---
name: tech-docs-guide
description: Chinese technical-documentation conventions (naming, structure, formatting, examples). Passive reference consulted by tech-doc-workflow when authoring or revising docs under docs/. Single source of truth for what a doc looks like.
user-invocable: false
---

> 本文件是本仓库技术文档的**写作规范底座**——命名、结构、格式、示例的唯一事实源。
> 它不描述流程；流程由 `tech-doc-workflow` skill 负责，并在产出/修订文档时引用本规范。

## 基本要求

- 使用简体中文编写
- 代码示例简洁，聚焦核心概念
- 使用清晰的标题和子标题组织内容
- 包含实际应用场景的实用示例

## 文档结构

### 标题命名

使用「主题 + 完全指南/使用指南」格式：

```markdown
# Git Hooks 完全指南

# TypeScript 使用指南
```

### 章节编号

| 层级     | 格式     | 示例                  |
| -------- | -------- | --------------------- |
| 一级章节 | 数字编号 | `## 1. 概述`          |
| 二级章节 | 点号分隔 | `### 1.1 什么是 XX`   |
| 三级章节 | 点号分隔 | `#### 1.1.1 详细说明` |

### 结尾部分

- **总结章节**：回顾核心要点，可包含速查表
- **参考资源章节**：提供官方文档和相关资源链接

### 不使用的元素

- 不使用目录
- 不使用章节分隔线（`---`）

## 内容格式

### 表格

大量使用 markdown 表格进行对比说明、参数说明、速查总结。

### 图解

- 简单图解：优先使用 ASCII 艺术（Git 分支图、流程图）
- 复杂图形：使用 Mermaid 语法（类图、时序图、流程图）

### 代码块

```javascript
// ✅ 好的实践：简洁、有中文注释
function greet(name) {
  return `Hello, ${name}`;
}

// ❌ 坏的实践：冗长、无注释
```

要点：

- 标注语言类型（bash, json, javascript 等）
  - 如果需要支持 json 注释，使用 `jsonc`
- 只包含必要的关键代码
- 使用中文注释说明关键步骤
- 使用 `// ✅` 和 `// ❌` 标记好/坏实践

### 嵌套代码块

当需要在文档中展示包含代码块的 Markdown 示例时，外层使用 4 个反引号，内层使用 3 个反引号：

`````markdown
````markdown
## 示例标题

```bash
python scripts/example.py
```
````
`````

> **注意**：嵌套代码块的开头和结尾反引号数量必须一致，否则会导致渲染错误。

### 提示信息

使用引用块格式：

```markdown
> **注意**：重要警告或注意事项

> **提示**：有用的建议

> 说明：补充说明信息
```

### 对比说明

使用 ✅ 和 ❌ 标记好/坏实践，可在正文或代码注释中使用。

### FAQ（可选，QA可以加深技术理解）

```markdown
**Q1: 问题内容？**

解答段落或代码示例...
```

问题聚焦于技术实现、常见错误排查、配置疑难等技术内容（和当前的技术主题相关联）。

### 速查表

在总结章节提供表格形式的快速参考。

## 示例规范

- 提供完整可运行的代码示例
- 包含多个实际应用场景（场景1、场景2...）
- 代码示例中使用中文注释说明关键步骤
- 复杂操作提供分步骤说明（1. 2. 3.）
