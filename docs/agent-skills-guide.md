# Agent Skills 完全指南

Agent Skills 是一种轻量级、开放的格式，用于通过可复用、可移植的包扩展 AI Agent 的能力。本指南介绍如何理解、创建和使用 Agent Skills。

## 1. 概述

### 1.1 什么是 Agent Skills

Agent Skills 是包含指令、脚本和资源的文件夹，AI Agent 可以发现并使用它们来更准确、高效地执行任务。Skills 的核心是一个 `SKILL.md` 文件，包含：

- **元数据**：`name` 和 `description`（必需）
- **指令**：告诉 Agent 如何执行特定任务的 Markdown 内容
- **可选资源**：脚本、模板和参考材料

### 1.2 Agent Skills 的价值

| 受益方       | 价值                                               |
| ------------ | -------------------------------------------------- |
| Skill 作者   | 一次构建，多产品部署；创建可复用、版本控制的包     |
| 兼容的 Agent | 开箱即用获得新能力；无需复杂设置                   |
| 团队与企业   | 将组织知识封装为可移植包；保持一致、可审计的工作流 |

### 1.3 支持的平台

Agent Skills 已被主流 AI 开发工具采用：

- Claude Code、Claude
- Cursor、VS Code
- GitHub Copilot
- Gemini CLI
- OpenAI Codex
- 以及更多...

## 2. 核心概念

### 2.1 目录结构

一个 Skill 至少包含一个 `SKILL.md` 文件：

```
my-skill/
├── SKILL.md          # 必需：指令 + 元数据
├── scripts/          # 可选：可执行代码
├── references/       # 可选：参考文档
└── assets/           # 可选：模板、资源
```

### 2.2 工作原理

Skills 使用**渐进式披露**来高效管理上下文：

```
┌─────────────────────────────────────────────────────────────┐
│                      Skills 加载流程                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  启动时        任务匹配时         需要时                    │
│    │              │                │                        │
│    ▼              ▼                ▼                        │
│ ┌──────┐     ┌──────────┐    ┌───────────┐                  │
│ │ 发现 │ ──▶ │   激活   │ ──▶│   执行    │                  │
│ └──────┘     └──────────┘    └───────────┘                  │
│    │              │                │                        │
│    ▼              ▼                ▼                        │
│ 加载 name    读取完整        加载引用文件                   │
│ description  SKILL.md       执行脚本                        │
│ (~100 tokens) (<5000 tokens)  (按需)                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

1. **发现**：启动时只加载 name 和 description，足以判断何时相关
2. **激活**：当任务匹配 Skill 的描述时，Agent 读取完整的 `SKILL.md`
3. **执行**：Agent 按需加载引用文件或执行脚本

## 3. SKILL.md 规范

### 3.1 基本格式

每个 Skill 以 YAML frontmatter 开头，后跟 Markdown 指令：

```yaml
---
name: pdf-processing
description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files.
---

# PDF Processing

## When to use this skill
Use this skill when the user needs to work with PDF files...

## How to extract text
1. Use pdfplumber for text extraction...
```

### 3.2 Frontmatter 字段

| 字段            | 必需 | 约束                                                                          |
| --------------- | ---- | ----------------------------------------------------------------------------- |
| `name`          | 是   | 最多 64 字符；仅小写字母、数字、连字符；不能以连字符开头/结尾；不能连续连字符 |
| `description`   | 是   | 最多 1024 字符；描述 Skill 的功能和使用场景                                   |
| `license`       | 否   | 许可证名称或引用                                                              |
| `compatibility` | 否   | 最多 500 字符；环境要求                                                       |
| `metadata`      | 否   | 任意字符串键值对                                                              |
| `allowed-tools` | 否   | 空格分隔的预授权工具列表（实验性）                                            |

### 3.3 命名规范

```yaml
# ✅ 有效的命名
name: pdf-processing
name: data-analysis
name: code-review

# ❌ 无效的命名
name: PDF-Processing      # 不允许大写
name: -pdf               # 不能以连字符开头
name: pdf--processing    # 不能连续连字符
```

推荐使用**动名词形式**（verb + -ing）：

| 推荐                     | 可接受                 |
| ------------------------ | ---------------------- |
| `processing-pdfs`        | `pdf-processing`       |
| `analyzing-spreadsheets` | `spreadsheet-analysis` |
| `testing-code`           | `test-code`            |

### 3.4 描述字段指南

> **注意**：描述必须使用**第三人称**，因为它会被注入到系统提示中。

```yaml
# ✅ 好的描述
description: Extracts text and tables from PDF files, fills PDF forms, and merges multiple PDFs. Use when working with PDF documents or when the user mentions PDFs, forms, or document extraction.

# ❌ 差的描述
description: Helps with PDFs.
description: I can help you process PDFs.    # 不要用第一人称
description: You can use this for PDFs.      # 不要用第二人称
```

## 4. 创建 Skill

### 4.1 基本步骤

**场景：创建一个 Git Commit 助手 Skill**

1. 创建目录结构：

```bash
mkdir -p commit-helper
cd commit-helper
```

2. 创建 `SKILL.md` 文件：

```yaml
---
name: commit-helper
description: Generates descriptive commit messages by analyzing git diffs. Use when the user asks for help writing commit messages or reviewing staged changes.
---

# Git Commit Helper

## When to use this skill

Use this skill when:
- User asks for help writing a commit message
- User wants to review staged changes before committing
- User mentions "commit", "git commit", or "commit message"

## How to generate commit messages

1. Run `git diff --staged` to see staged changes
2. Analyze the changes to understand:
   - What files were modified
   - What type of change (feat, fix, refactor, docs, etc.)
   - The scope of the change
3. Generate a message following conventional commits format:

```

type(scope): brief description

Detailed explanation of what changed and why.

```

## Commit types

| Type | Description |
|------|-------------|
| feat | New feature |
| fix | Bug fix |
| docs | Documentation only |
| refactor | Code refactoring |
| test | Adding tests |
| chore | Maintenance tasks |
```

### 4.2 添加引用文件

对于复杂的 Skill，将详细内容拆分到单独的文件：

```
commit-helper/
├── SKILL.md
├── references/
│   ├── CONVENTIONAL_COMMITS.md
│   └── EXAMPLES.md
└── scripts/
    └── analyze_diff.py
```

在 `SKILL.md` 中引用：

```markdown
## References

- For commit format details, see [CONVENTIONAL_COMMITS.md](references/CONVENTIONAL_COMMITS.md)
- For example commit messages, see [EXAMPLES.md](references/EXAMPLES.md)
```

> **提示**：保持 `SKILL.md` 主体在 500 行以内，超出部分移至引用文件。

### 4.3 使用脚本

```python
# scripts/analyze_diff.py
"""分析 git diff 并提取变更摘要"""

import subprocess
import sys

def analyze_diff():
    # 获取暂存的更改
    result = subprocess.run(
        ['git', 'diff', '--staged', '--stat'],
        capture_output=True, text=True
    )

    if result.returncode != 0:
        print("Error: Not a git repository or no staged changes")
        sys.exit(1)

    print(result.stdout)

if __name__ == "__main__":
    analyze_diff()
```

在 `SKILL.md` 中说明如何使用：

````markdown
## Utility scripts

**analyze_diff.py**: Extract summary of staged changes

```bash
python scripts/analyze_diff.py
```
````

Output shows files changed and lines added/removed.

````

## 5. 最佳实践

### 5.1 简洁是关键

上下文窗口是共享资源。只添加 Claude 确实不知道的信息：

```python
# ✅ 简洁的示例（约 50 tokens）
## Extract PDF text

Use pdfplumber for text extraction:

```python
import pdfplumber

with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
````

# ❌ 冗长的示例（约 150 tokens）

## Extract PDF text

PDF (Portable Document Format) files are a common file format that contains
text, images, and other content. To extract text from a PDF, you'll need to
use a library. There are many libraries available...

````

### 5.2 设置适当的自由度

根据任务的脆弱性和可变性匹配具体程度：

| 自由度 | 适用场景 | 示例 |
|--------|----------|------|
| 高 | 多种方法都有效；依赖上下文决策 | 代码审查流程 |
| 中 | 存在首选模式；允许一定变化 | 带参数的脚本模板 |
| 低 | 操作脆弱易错；一致性关键 | 数据库迁移脚本 |

### 5.3 渐进式披露模式

**模式 1：高层指南 + 引用**

```markdown
# PDF Processing

## Quick start
[基本用法]

## Advanced features
**Form filling**: See [FORMS.md](FORMS.md) for complete guide
**API reference**: See [REFERENCE.md](REFERENCE.md) for all methods
````

**模式 2：按领域组织**

```
bigquery-skill/
├── SKILL.md (概述和导航)
└── reference/
    ├── finance.md (收入、账单指标)
    ├── sales.md (机会、管道)
    └── product.md (API 使用、功能)
```

### 5.4 避免深层嵌套引用

> **注意**：所有引用文件应直接从 `SKILL.md` 链接，保持一层深度。

```markdown
# ✅ 好的：一层深度

# SKILL.md

**Basic usage**: [instructions in SKILL.md]
**Advanced features**: See [advanced.md](advanced.md)
**API reference**: See [reference.md](reference.md)

# ❌ 差的：嵌套过深

# SKILL.md → advanced.md → details.md
```

### 5.5 工作流和反馈循环

**复杂任务使用检查清单**：

```markdown
## PDF form filling workflow

Copy this checklist and track your progress:
```

Task Progress:

- [ ] Step 1: Analyze the form (run analyze_form.py)
- [ ] Step 2: Create field mapping (edit fields.json)
- [ ] Step 3: Validate mapping (run validate_fields.py)
- [ ] Step 4: Fill the form (run fill_form.py)
- [ ] Step 5: Verify output (run verify_output.py)

```

```

**实现反馈循环**：

```markdown
## Document editing process

1. Make your edits to `word/document.xml`
2. **Validate immediately**: `python scripts/validate.py`
3. If validation fails:
   - Review the error message
   - Fix the issues
   - Run validation again
4. **Only proceed when validation passes**
```

## 6. 进阶特性

### 6.1 可执行脚本

脚本相比生成代码的优势：

- 比生成的代码更可靠
- 节省 tokens（无需在上下文中包含代码）
- 节省时间（无需代码生成）
- 确保使用一致性

````markdown
## Utility scripts

**analyze_form.py**: Extract all form fields from PDF

```bash
python scripts/analyze_form.py input.pdf > fields.json
```
````

**validate_boxes.py**: Check for overlapping bounding boxes

```bash
python scripts/validate_boxes.py fields.json
# Returns: "OK" or lists conflicts
```

````

### 6.2 错误处理

脚本应处理错误，而不是把问题抛给 Agent：

```python
# ✅ 显式处理错误
def process_file(path):
    """Process a file, creating it if it doesn't exist."""
    try:
        with open(path) as f:
            return f.read()
    except FileNotFoundError:
        print(f"File {path} not found, creating default")
        with open(path, 'w') as f:
            f.write('')
        return ''

# ❌ 把问题抛给 Agent
def process_file(path):
    return open(path).read()  # 直接失败
````

### 6.3 创建可验证的中间输出

对于复杂任务，使用"计划-验证-执行"模式：

```
分析 → 创建计划文件 → 验证计划 → 执行 → 验证结果
```

```markdown
## Form update workflow

1. Analyze form: `python scripts/analyze_form.py form.pdf`
2. Create `changes.json` with planned updates
3. **Validate plan**: `python scripts/validate_changes.py changes.json`
4. Execute: `python scripts/apply_changes.py form.pdf changes.json`
5. Verify: `python scripts/verify_output.py output.pdf`
```

### 6.4 MCP 工具引用

如果 Skill 使用 MCP 工具，始终使用完全限定名称：

```markdown
# ✅ 使用完全限定名称

Use the BigQuery:bigquery_schema tool to retrieve table schemas.
Use the GitHub:create_issue tool to create issues.

# ❌ 可能找不到工具

Use the bigquery_schema tool...
```

## 7. 集成到 Agent

### 7.1 集成方式

| 方式         | 描述                                 | 特点               |
| ------------ | ------------------------------------ | ------------------ |
| 基于文件系统 | Agent 通过 bash/unix 命令访问 Skills | 最强大，可执行脚本 |
| 基于工具     | Agent 通过专用工具触发 Skills        | 不依赖文件系统     |

### 7.2 基本集成步骤

1. **发现**：扫描配置目录中包含 `SKILL.md` 的文件夹
2. **解析元数据**：启动时只解析 frontmatter
3. **注入上下文**：使用 XML 格式将元数据添加到系统提示

```xml
<available_skills>
  <skill>
    <name>pdf-processing</name>
    <description>Extracts text and tables from PDF files...</description>
    <location>/path/to/skills/pdf-processing/SKILL.md</location>
  </skill>
</available_skills>
```

4. **匹配**：将用户任务与相关 Skills 匹配
5. **激活**：加载完整指令
6. **执行**：运行脚本并访问资源

### 7.3 安全考虑

脚本执行引入安全风险，建议：

- **沙箱化**：在隔离环境中运行脚本
- **白名单**：只执行来自受信任 Skills 的脚本
- **确认**：在运行潜在危险操作前询问用户
- **日志**：记录所有脚本执行以供审计

## 8. 常见问题

**Q1: Agent Skills 和 Rules 文件（如 `.cursorrules`、`CLAUDE.md`）有什么区别？**

Agent Skills 和 Rules 文件是两种不同的 Agent 配置机制，各有其适用场景：

| 维度       | Rules 文件             | Agent Skills                      |
| ---------- | ---------------------- | --------------------------------- |
| 加载方式   | 启动时全量加载到上下文 | 渐进式披露，按需加载              |
| 作用范围   | 针对特定项目/仓库      | 可跨项目复用                      |
| 内容类型   | 纯文本指令             | 指令 + 脚本 + 资源                |
| 激活条件   | 始终生效               | 任务匹配时激活                    |
| Token 消耗 | 始终占用上下文         | 仅激活时占用                      |
| 典型用途   | 项目编码规范、提交约定 | 特定领域能力（PDF处理、数据分析） |

常见的 Rules 文件：

- `CLAUDE.md` - Claude Code 项目指令
- `.cursorrules` - Cursor 编辑器规则
- `.github/copilot-instructions.md` - GitHub Copilot 指令
- `.windsurfrules` - Windsurf 编辑器规则

**Q2: 什么时候用 Rules，什么时候用 Skills？**

```
┌────────────────────────────────────────────────────────────────┐
│                       选择决策树                                │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  这个配置是否只针对当前项目？                                   │
│       │                                                        │
│       ├── 是 ──▶ 使用 Rules 文件                               │
│       │         （如编码风格、提交规范、项目特定约定）           │
│       │                                                        │
│       └── 否 ──▶ 这个能力是否需要按需激活？                     │
│                      │                                         │
│                      ├── 是 ──▶ 使用 Agent Skills              │
│                      │         （如 PDF 处理、Excel 分析）      │
│                      │                                         │
│                      └── 否 ──▶ 使用全局 Rules                  │
│                                （如通用编码偏好）               │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

**Q3: Skills 和 Rules 可以同时使用吗？**

可以，两者是互补的：

- **Rules** 定义"怎么做"——项目的编码规范、风格约定、工作流偏好
- **Skills** 定义"能做什么"——扩展 Agent 处理特定任务的能力

```yaml
# 项目中同时使用的示例

# CLAUDE.md (Rules) - 项目级指令，始终生效
代码风格：使用 TypeScript，遵循 ESLint 规则
提交规范：使用 Conventional Commits
测试要求：所有新功能必须有单元测试

# .claude/skills/pdf-processing/SKILL.md (Skill) - 按需激活
当用户需要处理 PDF 文件时，使用 pdfplumber 库...
```

**Q4: 如何将现有的 Rules 迁移到 Skills？**

并非所有 Rules 都适合迁移。遵循以下原则：

| 适合迁移到 Skills                   | 保留为 Rules   |
| ----------------------------------- | -------------- |
| 特定任务的处理流程（如 PDF、Excel） | 项目编码规范   |
| 可复用的领域知识                    | 提交消息格式   |
| 包含脚本或资源的能力                | 团队工作流约定 |
| 大量内容（>500行）                  | 简短的项目指令 |

迁移步骤：

1. 识别 Rules 中的"能力型"内容
2. 为每个能力创建独立的 Skill 目录
3. 编写 `SKILL.md`，添加 `name` 和 `description`
4. 将详细内容移至 Skill，Rules 中只保留项目级指令

**Q5: Skills 是否会取代 Rules 文件？**

不会。两者解决不同问题：

- **Rules**：轻量级、项目绑定、始终生效——适合项目配置
- **Skills**：模块化、可复用、按需加载——适合能力扩展

最佳实践是根据场景选择合适的机制，或组合使用。

## 9. 总结

### 9.1 Skill 质量检查清单

**核心质量**：

- [ ] 描述具体且包含关键术语
- [ ] 描述包含功能和使用场景
- [ ] `SKILL.md` 主体在 500 行以内
- [ ] 使用单独文件存放详细内容
- [ ] 无时效性信息
- [ ] 术语一致
- [ ] 示例具体
- [ ] 引用只有一层深度

**代码和脚本**：

- [ ] 脚本解决问题而非抛给 Agent
- [ ] 显式且有帮助的错误处理
- [ ] 所有常量都有说明
- [ ] 列出必需的包
- [ ] 使用正斜杠路径

**测试**：

- [ ] 至少创建三个评估场景
- [ ] 用 Haiku、Sonnet、Opus 测试
- [ ] 用真实使用场景测试

### 9.2 速查表

| 项目            | 建议                                         |
| --------------- | -------------------------------------------- |
| `name`          | 小写字母 + 数字 + 连字符，最多 64 字符       |
| `description`   | 第三人称，包含功能和使用场景，最多 1024 字符 |
| `SKILL.md` 长度 | < 500 行                                     |
| 引用深度        | 1 层                                         |
| 路径格式        | 使用正斜杠 `/`                               |
| 长引用文件      | 添加目录                                     |
| 复杂任务        | 使用检查清单 + 反馈循环                      |

## 10. 参考资源

- [Agent Skills 官网](https://agentskills.io)
- [SKILL.md 规范](https://agentskills.io/specification)
- [官方示例 Skills](https://github.com/anthropics/skills)
- [skills-ref 参考库](https://github.com/agentskills/agentskills/tree/main/skills-ref)
- [最佳实践文档](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
