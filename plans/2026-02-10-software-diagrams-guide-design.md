# 软件开发常用图表指南 - 设计文档

## 概述

创建一份面向开发者的软件开发图表完整指南，用于：
- 团队培训与知识分享
- 个人日常工作参考
- 项目文档规范标准

## 文档结构

按软件开发生命周期分为 5 个独立文档：

| 文档 | 阶段 | 描述 |
|------|------|------|
| `diagrams-requirements.md` | 需求分析 | 从用户视角理解系统功能 |
| `diagrams-design.md` | 详细设计 | 代码结构与数据模型设计 |
| `diagrams-architecture.md` | 架构设计 | 系统整体结构与部署方案 |
| `diagrams-process.md` | 流程建模 | 业务流程与数据流动 |
| `diagrams-operations.md` | 运维相关 | 基础设施与监控 |

## 各文档图表清单

### 1. diagrams-requirements.md - 需求分析阶段

| 图表 | 定位 | 典型使用者 |
|------|------|------------|
| **用例图** (Use Case Diagram) | 描述用户与系统的交互功能点 | 产品经理、BA、开发 |
| **用户故事地图** (User Story Map) | 按用户旅程组织需求，规划迭代 | 敏捷团队、产品经理 |
| **思维导图** (Mind Map) | 发散式整理需求、头脑风暴 | 全员 |

### 2. diagrams-design.md - 详细设计阶段

| 图表 | 定位 | 典型使用者 |
|------|------|------------|
| **类图** (Class Diagram) | OOP 核心，描述类、属性、方法及关系 | 后端开发 |
| **ER 图** (Entity-Relationship Diagram) | 数据库表结构及关系设计 | 后端开发、DBA |
| **序列图** (Sequence Diagram) | 对象间消息交互的时间顺序 | 全栈开发 |
| **状态机图** (State Machine Diagram) | 对象在不同状态间的转换逻辑 | 后端开发 |

### 3. diagrams-architecture.md - 架构设计阶段

| 图表 | 定位 | 典型使用者 |
|------|------|------------|
| **C4 - Context** | 系统与外部用户/系统的关系（最高层） | 架构师、技术负责人 |
| **C4 - Container** | 应用和数据存储的高层结构 | 架构师、开发团队 |
| **C4 - Component** | 容器内部的组件划分 | 开发团队 |
| **C4 - Code** | 代码级别细节（可选，通常不画） | 特殊场景 |
| **系统架构图** | 自由形式的整体架构概览 | 架构师 |
| **部署图** (Deployment Diagram) | 软件在硬件/云上的部署方式 | 架构师、运维 |

### 4. diagrams-process.md - 流程建模阶段

| 图表 | 定位 | 典型使用者 |
|------|------|------------|
| **流程图** (Flowchart) | 基础算法逻辑、简单业务流程 | 全员 |
| **活动图** (Activity Diagram) | 带并发和分支的复杂流程 | 开发、BA |
| **泳道图** (Swimlane Diagram) | 跨角色/部门的流程协作 | BA、产品经理 |
| **数据流图** (Data Flow Diagram) | 数据在系统中的流动路径 | 系统分析师 |
| **BPMN** | 标准化业务流程建模 | BA、流程设计师 |

### 5. diagrams-operations.md - 运维相关

| 图表 | 定位 | 典型使用者 |
|------|------|------------|
| **网络拓扑图** | 网络设备和连接关系 | 运维、网络工程师 |
| **部署架构图** | 生产环境的基础设施布局 | 运维、SRE |
| **监控仪表盘** | 关键指标可视化布局设计 | 运维、SRE |

## 单个图表内容模板

每种图表按以下结构组织：

```markdown
## [图表名称]

### 概述
- 定义：一句话说明这是什么
- 核心用途：解决什么问题
- 适用场景：什么时候用、不适合什么时候用

### 基本元素
- 核心符号/元素说明（表格形式）
- 元素之间的关系类型

### 示例
- 简单示例（带 Mermaid/PlantUML 代码）
- 实战示例（真实业务场景）

### 绘制工具
- 推荐工具（代码生成类 vs 可视化拖拽类）
- 工具对比表

### 最佳实践
- 3-5 条核心原则
- 命名规范建议

### 常见错误
- 典型错误示例
- 如何避免

### 进阶技巧
- 高级用法
- 与其他图的配合使用

### 模板
- 可直接复用的代码模板
```

## 工具推荐

### 绘图工具分类

| 类别 | 工具 | 特点 | 适用场景 |
|------|------|------|----------|
| **代码生成类** | Mermaid | 内嵌 Markdown，Git 友好 | 技术文档、README |
| | PlantUML | 语法丰富，UML 支持全面 | 正式设计文档 |
| | Structurizr | C4 模型专用，架构即代码 | 架构文档 |
| **可视化拖拽类** | Draw.io (diagrams.net) | 免费，集成 VS Code/GitHub | 通用场景 |
| | Excalidraw | 手绘风格，适合草图 | 头脑风暴、快速沟通 |
| | Lucidchart | 协作强，模板多 | 团队协作 |
| **专业建模类** | Enterprise Architect | 全功能 UML 建模 | 大型企业项目 |
| | Figma/FigJam | 设计协作 | 跨职能团队 |

## 文档规范建议

### 1. 命名规范
- 文件名：`<系统>-<图表类型>-<版本>.png/svg`
- 示例：`order-service-sequence-v2.svg`

### 2. 版本管理
- 优先使用代码生成类工具（Mermaid/PlantUML），源码纳入 Git
- 可视化工具导出 SVG 格式，便于版本对比

### 3. 图表粒度原则
- 单张图聚焦一个主题，避免信息过载
- 复杂系统使用多层次图表（如 C4 的 4 层）

### 4. 团队协作规范
- 统一工具选型（建议：Mermaid 为主，Draw.io 为辅）
- 建立图表模板库，降低绘制门槛

## 参考资料

- [C4 Model 官方网站](https://c4model.com/)
- [IcePanel - Top 7 UML Diagram Types](https://icepanel.io/blog/2024-11-05-top-7-most-common-uml-diagram-types)
- [Gleek - Diagram Types for Developers](https://www.gleek.io/blog/diagram-for-developers)
- [GeeksforGeeks - UML Introduction](https://www.geeksforgeeks.org/system-design/unified-modeling-language-uml-introduction/)
- [Lucidchart - Types of UML Diagrams](https://www.lucidchart.com/blog/types-of-UML-diagrams)

## 实施计划

1. 按顺序创建 5 个文档
2. 每个文档按模板结构填充内容
3. 为每种图表提供 Mermaid/PlantUML 示例代码
4. 建立可复用的模板库
