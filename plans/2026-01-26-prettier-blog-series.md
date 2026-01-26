# Prettier 系列中文技术博客实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 基于学习路径，编写 7 篇系统性的 Prettier 中文技术博客

**Architecture:** 每篇博客对应学习路径的一个部分，遵循 tech-docs-guide 规范。每篇独立成文，但通过交叉引用形成系列。

**Tech Stack:** Markdown、Prettier 官方文档、Context7 文档查询

---

## 系列文章规划

| 序号 | 文件名                           | 标题                        | 对应学习路径 |
| ---- | -------------------------------- | --------------------------- | ------------ |
| 1    | `prettier-fundamentals.md`       | Prettier 基础概念与原理     | 第一部分     |
| 2    | `prettier-configuration.md`      | Prettier 配置完全指南       | 第二部分     |
| 3    | `prettier-multi-language.md`     | Prettier 多语言支持指南     | 第三部分     |
| 4    | `prettier-editor-integration.md` | Prettier 编辑器集成指南     | 第四部分     |
| 5    | `prettier-toolchain.md`          | Prettier 工具链整合指南     | 第五部分     |
| 6    | `prettier-team-practices.md`     | Prettier 团队协作实践       | 第六部分     |
| 7    | `prettier-advanced.md`           | Prettier 高级用法与疑难解决 | 第七部分     |

---

## Task 1: Prettier 基础概念与原理

**Files:**

- Create: `docs/prettier-fundamentals.md`

**Step 1: 查询 Prettier 官方文档获取最新信息**

使用 Context7 查询：

- Prettier 设计哲学（Why Prettier）
- 工作原理（How it works）
- 支持的语言列表

**Step 2: 编写文档初稿**

文档结构：

```markdown
# Prettier 基础概念与原理

## 1. 概述

### 1.1 什么是 Prettier

### 1.2 Prettier vs Linter

## 2. 设计哲学

### 2.1 固执己见（Opinionated）

### 2.2 为什么减少配置项

### 2.3 停止争论代码风格

## 3. 工作原理

### 3.1 解析阶段（Parse）

### 3.2 AST 处理

### 3.3 打印阶段（Print）

### 3.4 格式化流程图解

## 4. 支持范围

### 4.1 内置支持的语言

### 4.2 需要插件的语言

### 4.3 Prettier 的边界

## 5. 总结

## 参考资源
```

**Step 3: 自我审校**

- 验证内容准确性（对照官方文档）
- 检查是否符合 tech-docs-guide 规范
- 确保代码示例可运行

**Step 4: 格式化**

```bash
npm run format
```

**Step 5: Commit**

```bash
git add docs/prettier-fundamentals.md
git commit -m "docs(prettier): add fundamentals guide - part 1 of 7"
```

---

## Task 2: Prettier 配置完全指南

**Files:**

- Create: `docs/prettier-configuration.md`

**Step 1: 查询 Prettier 官方文档获取最新信息**

使用 Context7 查询：

- 配置文件类型和优先级
- 所有配置选项的最新列表
- overrides 用法
- .prettierignore 语法

**Step 2: 编写文档初稿**

文档结构：

```markdown
# Prettier 配置完全指南

## 1. 概述

### 1.1 配置方式总览

### 1.2 配置加载优先级

## 2. 配置文件类型

### 2.1 JSON 格式

### 2.2 JavaScript 格式

### 2.3 package.json 内嵌

### 2.4 各格式对比

## 3. 核心配置选项

### 3.1 打印相关

### 3.2 语法风格

### 3.3 括号与空格

### 3.4 特殊处理

### 3.5 配置选项速查表

## 4. 配置作用域

### 4.1 全局配置

### 4.2 目录级配置

### 4.3 overrides 文件级覆盖

## 5. .prettierignore

### 5.1 语法规则

### 5.2 与 .gitignore 的异同

### 5.3 常见忽略模式

## 6. 实战配置示例

### 6.1 前端项目配置

### 6.2 全栈项目配置

### 6.3 Monorepo 配置

## 7. 总结

## 参考资源
```

**Step 3: 自我审校**

**Step 4: 格式化**

```bash
npm run format
```

**Step 5: Commit**

```bash
git add docs/prettier-configuration.md
git commit -m "docs(prettier): add configuration guide - part 2 of 7"
```

---

## Task 3: Prettier 多语言支持指南

**Files:**

- Create: `docs/prettier-multi-language.md`

**Step 1: 查询 Prettier 官方文档获取最新信息**

使用 Context7 查询：

- 各语言的特殊配置选项
- parser 列表和用法
- 插件系统

**Step 2: 编写文档初稿**

文档结构：

```markdown
# Prettier 多语言支持指南

## 1. 概述

### 1.1 内置语言支持

### 1.2 插件扩展机制

## 2. 各语言配置详解

### 2.1 JavaScript/TypeScript

### 2.2 HTML/Vue/Angular

### 2.3 CSS/SCSS/Less

### 2.4 Markdown

### 2.5 JSON/YAML

### 2.6 GraphQL

## 3. overrides 进阶用法

### 3.1 按扩展名定制

### 3.2 按目录定制

### 3.3 glob 模式技巧

### 3.4 多条件组合

## 4. 解析器（Parser）机制

### 4.1 自动检测原理

### 4.2 显式指定 parser

### 4.3 解析器对照表

## 5. 插件系统

### 5.1 插件加载机制

### 5.2 常用社区插件

### 5.3 插件配置示例

## 6. 总结

## 参考资源
```

**Step 3: 自我审校**

**Step 4: 格式化**

```bash
npm run format
```

**Step 5: Commit**

```bash
git add docs/prettier-multi-language.md
git commit -m "docs(prettier): add multi-language guide - part 3 of 7"
```

---

## Task 4: Prettier 编辑器集成指南

**Files:**

- Create: `docs/prettier-editor-integration.md`

**Step 1: 查询各编辑器集成文档**

使用 WebSearch/WebFetch 查询：

- VS Code Prettier 扩展配置
- JetBrains Prettier 设置
- Neovim 插件方案

**Step 2: 编写文档初稿**

文档结构：

```markdown
# Prettier 编辑器集成指南

## 1. 概述

### 1.1 核心原则

### 1.2 项目级配置优先

## 2. VS Code

### 2.1 安装 Prettier 扩展

### 2.2 基础配置

### 2.3 工作区设置

### 2.4 常见问题

## 3. JetBrains 系列

### 3.1 WebStorm/IDEA 配置

### 3.2 指定 Prettier 路径

### 3.3 快捷键设置

## 4. Vim/Neovim

### 4.1 插件方案对比

### 4.2 conform.nvim 配置

### 4.3 格式化触发方式

## 5. 跨编辑器一致性

### 5.1 使用项目本地 Prettier

### 5.2 .editorconfig 配合

### 5.3 团队配置共享策略

## 6. 总结

## 参考资源
```

**Step 3: 自我审校**

**Step 4: 格式化**

```bash
npm run format
```

**Step 5: Commit**

```bash
git add docs/prettier-editor-integration.md
git commit -m "docs(prettier): add editor integration guide - part 4 of 7"
```

---

## Task 5: Prettier 工具链整合指南

**Files:**

- Create: `docs/prettier-toolchain.md`

**Step 1: 查询相关工具文档**

使用 Context7 查询：

- eslint-config-prettier
- husky + lint-staged
- GitHub Actions 配置

**Step 2: 编写文档初稿**

文档结构：

```markdown
# Prettier 工具链整合指南

## 1. 概述

### 1.1 工具链全景图

### 1.2 职责划分原则

## 2. Prettier 与 ESLint

### 2.1 职责边界

### 2.2 eslint-config-prettier

### 2.3 eslint-plugin-prettier

### 2.4 推荐方案

### 2.5 配置示例

## 3. Git Hooks 集成

### 3.1 husky 配置

### 3.2 lint-staged 配置

### 3.3 只格式化暂存文件

### 3.4 常见坑与解决方案

## 4. CI/CD 集成

### 4.1 prettier --check 模式

### 4.2 GitHub Actions 配置

### 4.3 GitLab CI 配置

### 4.4 错误信息解读

## 5. npm scripts 规范

### 5.1 命名惯例

### 5.2 完整配置示例

## 6. 总结

## 参考资源
```

**Step 3: 自我审校**

**Step 4: 格式化**

```bash
npm run format
```

**Step 5: Commit**

```bash
git add docs/prettier-toolchain.md
git commit -m "docs(prettier): add toolchain integration guide - part 5 of 7"
```

---

## Task 6: Prettier 团队协作实践

**Files:**

- Create: `docs/prettier-team-practices.md`

**Step 1: 查询相关最佳实践**

使用 WebSearch 查询：

- 存量项目引入 Prettier 的经验
- git blame ignore 用法
- 版本管理策略

**Step 2: 编写文档初稿**

文档结构：

```markdown
# Prettier 团队协作实践

## 1. 概述

### 1.1 为什么需要统一风格

### 1.2 引入 Prettier 的收益

## 2. 存量项目引入

### 2.1 一次性全量格式化

### 2.2 渐进式引入

### 2.3 处理格式化炸弹提交

### 2.4 保持 git blame 可读性

## 3. 配置决策

### 3.1 值得讨论的选项

### 3.2 直接采用默认值的选项

### 3.3 减少争议的策略

## 4. 特殊情况处理

### 4.1 prettier-ignore 使用规范

### 4.2 生成代码排除

### 4.3 第三方代码处理

### 4.4 遗留系统共存

## 5. 版本管理

### 5.1 锁定版本的重要性

### 5.2 升级流程

### 5.3 版本差异处理

## 6. 总结

## 参考资源
```

**Step 3: 自我审校**

**Step 4: 格式化**

```bash
npm run format
```

**Step 5: Commit**

```bash
git add docs/prettier-team-practices.md
git commit -m "docs(prettier): add team practices guide - part 6 of 7"
```

---

## Task 7: Prettier 高级用法与疑难解决

**Files:**

- Create: `docs/prettier-advanced.md`

**Step 1: 查询 Prettier CLI 文档**

使用 Context7 查询：

- CLI 所有选项
- 调试命令
- 缓存机制

**Step 2: 编写文档初稿**

文档结构：

```markdown
# Prettier 高级用法与疑难解决

## 1. 概述

### 1.1 CLI 命令总览

### 1.2 调试工具介绍

## 2. 调试技巧

### 2.1 --debug-check

### 2.2 --find-config-path

### 2.3 --file-info

### 2.4 调试流程图

## 3. 常见问题排查

### 3.1 格式化结果不一致

### 3.2 文件未被格式化

### 3.3 与 ESLint 冲突

### 3.4 编辑器与 CLI 结果不同

## 4. 性能优化

### 4.1 --cache 选项

### 4.2 大型项目策略

### 4.3 并行处理

## 5. Prettier 的局限

### 5.1 不能做什么

### 5.2 补充工具推荐

### 5.3 边界认知

## 6. FAQ

**Q1: 为什么格式化后代码变得更长了？**

**Q2: 如何让 Prettier 排序 import？**

**Q3: 为什么某些文件被跳过了？**

## 7. 总结

### 7.1 CLI 命令速查表

### 7.2 问题排查清单

## 参考资源
```

**Step 3: 自我审校**

**Step 4: 格式化**

```bash
npm run format
```

**Step 5: Commit**

```bash
git add docs/prettier-advanced.md
git commit -m "docs(prettier): add advanced usage guide - part 7 of 7"
```

---

## Task 8: 更新索引文件

**Files:**

- Modify: `docs/index.md`

**Step 1: 在索引文件中添加 Prettier 系列**

添加新的章节，包含 7 篇文章的链接。

**Step 2: Commit**

```bash
git add docs/index.md
git commit -m "docs: add Prettier series to index"
```

---

## 执行注意事项

1. **每篇文章独立成文**：读者可以单独阅读任意一篇
2. **交叉引用**：相关内容用 `详见 [Prettier 配置完全指南](./prettier-configuration.md)` 链接
3. **遵循 tech-docs-guide**：
   - 使用章节编号（1. 1.1 1.1.1）
   - 大量使用表格
   - 代码示例带中文注释
   - 不使用目录和分隔线
4. **验证时效性**：使用 Context7 或 WebFetch 查询最新文档
5. **格式化检查**：每篇完成后运行 `npm run format`
