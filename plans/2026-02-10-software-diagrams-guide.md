# 软件开发图表指南 - 实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 创建 5 个面向开发者的软件开发图表完整指南文档

**Architecture:** 按软件开发生命周期分为 5 个独立文档，每个文档包含 3-6 种图表类型。每种图表按统一模板组织：概述、基本元素、示例、工具、最佳实践、常见错误、进阶技巧、模板。

**Tech Stack:** Markdown, Mermaid, PlantUML

**Writing Guide:** 遵循 `.claude/skills/tech-docs-guide/SKILL.md` 中的写作规范

---

## Task 1: 需求分析阶段图表 (diagrams-requirements.md)

**Files:**

- Create: `docs/diagrams-requirements.md`

**包含图表：**

1. 用例图 (Use Case Diagram)
2. 用户故事地图 (User Story Map)
3. 思维导图 (Mind Map)

**Step 1: 创建文档框架**

创建 `docs/diagrams-requirements.md`，包含：

- 标题：`# 需求分析阶段图表指南`
- 概述章节：说明本文档覆盖的图表类型及适用场景
- 三个图表的二级标题占位

**Step 2: 编写用例图章节**

通过 WebFetch 获取用例图最新资料，按模板填充：

- 概述（定义、核心用途、适用场景）
- 基本元素（Actor、Use Case、关系类型表格）
- 示例（Mermaid 代码 + 实战场景）
- 绘制工具、最佳实践、常见错误、进阶技巧、模板

**Step 3: 编写用户故事地图章节**

通过 WebFetch 获取用户故事地图最新资料，按模板填充完整内容。

**Step 4: 编写思维导图章节**

通过 WebFetch 获取思维导图最新资料，按模板填充完整内容。

**Step 5: 审校与格式化**

- 运行 `npm run format` 格式化文档
- 检查内容逻辑、Mermaid 语法正确性
- 验证是否符合 tech-docs-guide 规范

**Step 6: 提交**

```bash
git add docs/diagrams-requirements.md
git commit -m "docs: add requirements phase diagrams guide"
```

---

## Task 2: 详细设计阶段图表 (diagrams-design.md)

**Files:**

- Create: `docs/diagrams-design.md`

**包含图表：**

1. 类图 (Class Diagram)
2. ER 图 (Entity-Relationship Diagram)
3. 序列图 (Sequence Diagram)
4. 状态机图 (State Machine Diagram)

**Step 1: 创建文档框架**

创建 `docs/diagrams-design.md`，包含：

- 标题：`# 详细设计阶段图表指南`
- 概述章节
- 四个图表的二级标题占位

**Step 2: 编写类图章节**

通过 WebFetch 获取 UML 类图最新资料，按模板填充：

- 基本元素（类、属性、方法、可见性符号）
- 关系类型（继承、实现、关联、聚合、组合、依赖）
- Mermaid classDiagram 示例

**Step 3: 编写 ER 图章节**

通过 WebFetch 获取 ER 图最新资料，按模板填充：

- 基本元素（实体、属性、关系）
- 基数表示法（1:1, 1:N, M:N）
- Mermaid erDiagram 示例

**Step 4: 编写序列图章节**

通过 WebFetch 获取序列图最新资料，按模板填充：

- 基本元素（参与者、生命线、消息类型）
- Mermaid sequenceDiagram 示例

**Step 5: 编写状态机图章节**

通过 WebFetch 获取状态机图最新资料，按模板填充：

- 基本元素（状态、转换、事件、动作）
- Mermaid stateDiagram 示例

**Step 6: 审校与格式化**

- 运行 `npm run format`
- 检查 Mermaid 语法正确性
- 验证规范符合性

**Step 7: 提交**

```bash
git add docs/diagrams-design.md
git commit -m "docs: add design phase diagrams guide"
```

---

## Task 3: 架构设计阶段图表 (diagrams-architecture.md)

**Files:**

- Create: `docs/diagrams-architecture.md`

**包含图表：**

1. C4 模型（Context, Container, Component, Code）
2. 系统架构图
3. 部署图 (Deployment Diagram)

**Step 1: 创建文档框架**

创建 `docs/diagrams-architecture.md`，包含：

- 标题：`# 架构设计阶段图表指南`
- 概述章节
- C4 模型作为重点章节（含 4 个子章节）
- 系统架构图、部署图章节

**Step 2: 编写 C4 模型章节**

通过 WebFetch 从 c4model.com 获取最新资料：

- C4 概述（四层抽象概念）
- Context 图（系统边界、外部交互）
- Container 图（应用和数据存储）
- Component 图（容器内部组件）
- Code 图（可选，何时使用）
- Structurizr DSL 或 PlantUML C4 示例

**Step 3: 编写系统架构图章节**

通过 WebFetch 获取系统架构图最佳实践：

- 自由形式架构图的绘制原则
- 常见架构模式（分层、微服务、事件驱动）
- 示例与模板

**Step 4: 编写部署图章节**

通过 WebFetch 获取 UML 部署图资料：

- 基本元素（节点、制品、通信路径）
- 云环境部署图示例
- Mermaid 或 PlantUML 示例

**Step 5: 审校与格式化**

- 运行 `npm run format`
- 验证 C4 内容与官方文档一致性
- 检查规范符合性

**Step 6: 提交**

```bash
git add docs/diagrams-architecture.md
git commit -m "docs: add architecture phase diagrams guide"
```

---

## Task 4: 流程建模阶段图表 (diagrams-process.md)

**Files:**

- Create: `docs/diagrams-process.md`

**包含图表：**

1. 流程图 (Flowchart)
2. 活动图 (Activity Diagram)
3. 泳道图 (Swimlane Diagram)
4. 数据流图 (Data Flow Diagram)
5. BPMN

**Step 1: 创建文档框架**

创建 `docs/diagrams-process.md`，包含：

- 标题：`# 流程建模阶段图表指南`
- 概述章节（对比各类流程图的适用场景）
- 五个图表的二级标题占位

**Step 2: 编写流程图章节**

通过 WebFetch 获取流程图资料：

- 标准符号（开始/结束、处理、判断、流程线）
- Mermaid flowchart 语法
- 算法逻辑示例

**Step 3: 编写活动图章节**

通过 WebFetch 获取 UML 活动图资料：

- 基本元素（活动、分支、合并、分叉、汇合）
- 与流程图的区别（并发支持）
- Mermaid 或 PlantUML 示例

**Step 4: 编写泳道图章节**

通过 WebFetch 获取泳道图资料：

- 泳道划分原则（按角色/部门/系统）
- 跨职能协作示例
- Mermaid flowchart subgraph 实现

**Step 5: 编写数据流图章节**

通过 WebFetch 获取 DFD 资料：

- 基本元素（外部实体、处理、数据存储、数据流）
- 层次分解（上下文图、0 级图、详细图）
- 示例与模板

**Step 6: 编写 BPMN 章节**

通过 WebFetch 获取 BPMN 2.0 资料：

- 核心元素（事件、活动、网关、连接对象）
- 与 UML 活动图对比
- 工具推荐（Camunda, bpmn.io）

**Step 7: 审校与格式化**

- 运行 `npm run format`
- 检查各图表对比说明的准确性
- 验证规范符合性

**Step 8: 提交**

```bash
git add docs/diagrams-process.md
git commit -m "docs: add process modeling diagrams guide"
```

---

## Task 5: 运维阶段图表 (diagrams-operations.md)

**Files:**

- Create: `docs/diagrams-operations.md`

**包含图表：**

1. 网络拓扑图
2. 部署架构图
3. 监控仪表盘

**Step 1: 创建文档框架**

创建 `docs/diagrams-operations.md`，包含：

- 标题：`# 运维阶段图表指南`
- 概述章节
- 三个图表的二级标题占位

**Step 2: 编写网络拓扑图章节**

通过 WebFetch 获取网络拓扑图资料：

- 拓扑类型（星型、环型、网状、混合）
- 标准符号（路由器、交换机、防火墙、服务器）
- 绘制工具与示例

**Step 3: 编写部署架构图章节**

通过 WebFetch 获取云架构图资料：

- 云服务商图标规范（AWS, Azure, GCP）
- 多可用区、多区域部署示例
- 工具推荐（Draw.io, Cloudcraft）

**Step 4: 编写监控仪表盘章节**

通过 WebFetch 获取仪表盘设计资料：

- 仪表盘布局原则
- 关键指标选择（四个黄金信号）
- Grafana 仪表盘设计示例

**Step 5: 审校与格式化**

- 运行 `npm run format`
- 检查内容逻辑
- 验证规范符合性

**Step 6: 提交**

```bash
git add docs/diagrams-operations.md
git commit -m "docs: add operations phase diagrams guide"
```

---

## 验收标准

每个文档完成后检查：

1. **结构完整**：每种图表包含概述、基本元素、示例、工具、最佳实践、常见错误、进阶技巧、模板
2. **示例可用**：Mermaid/PlantUML 代码语法正确
3. **规范符合**：遵循 tech-docs-guide 写作规范
4. **格式正确**：通过 `npm run format` 格式化
