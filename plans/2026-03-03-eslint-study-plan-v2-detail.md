# ESLint 系统学习计划 V2 - 详细设计

## 7 篇文档清单

| 篇序 | 文档名                      | 主题           | 核心要点                                               |
| ---- | --------------------------- | -------------- | ------------------------------------------------------ |
| 1    | eslint-1-basics.md          | 基础概念与原理 | ESLint 定位、核心概念、Flat Config 入门、CLI、工作原理 |
| 2    | eslint-2-rules.md           | 规则系统       | 规则级别、分类查找、extends 继承、插件使用、选项配置   |
| 3    | eslint-3-integration.md     | 框架集成       | TS 配置、类型感知、React/Vue 插件、Next.js/Vite        |
| 4    | eslint-4-workflow.md        | 团队工作流     | husky、lint-staged、CI/CD、Prettier、团队规范          |
| 5    | eslint-5-advanced.md        | 进阶定制       | Flat Config 深度、自定义规则、插件开发、性能优化       |
| 6    | eslint-6-practice.md        | 实战综合       | 完整项目案例、场景解决方案                             |
| 7    | eslint-7-troubleshooting.md | 问题排查       | 规则不生效、冲突解决、性能诊断、Monorepo               |

---

## 每篇详细大纲

### 篇 1：eslint-1-basics.md（基础概念与原理）

**目标**：理解 ESLint 是什么，怎么工作

**结构**：

```
1. 概述
   - 1.1 ESLint 定位与价值
   - 1.2 ESLint vs Prettier vs TypeScript
2. 核心概念
   - 2.1 Rules（规则）
   - 2.2 Plugins（插件）
   - 2.3 Extends（继承）
   - 2.4 Environments（环境）
   - 2.5 Parser（解析器）
3. 配置格式
   - 3.1 Flat Config 入门（基础用法）
   - 3.2 配置结构
   - 3.3 配置命名约定
4. 工作原理
   - 4.1 解析阶段
   - 4.2 检查阶段
   - 4.3 报告阶段
   - 4.4 自动修复
5. CLI 基础命令
   - 5.1 常用命令
   - 5.2 常用选项
   - 5.3 输出格式
6. 检验标准 ← 新增
7. 参考资源
```

**检验标准**：

- [ ] 能解释 ESLint 工作原理
- [ ] 能初始化基础配置
- [ ] 理解 5 个核心概念的作用
- [ ] 会用常用 CLI 命令

---

### 篇 2：eslint-2-rules.md（规则系统）

**目标**：掌握规则配置，能够构建适合项目的规则集

**结构**：

```
1. 规则严重程度
   - 1.1 off/warn/error
   - 1.2 配置方式
2. 规则查找与分类
   - 2.1 从错误信息定位
   - 2.2 按场景查找
   - 2.3 规则分类（possible-errors、best-practices 等）
3. 常用规则详解
   - 3.1 变量相关
   - 3.2 代码错误
   - 3.3 最佳实践
   - 3.4 Node.js
   - 3.5 代码风格
4. 规则选项配置
   - 4.1 选项格式
   - 4.2 Schema
   - 4.3 常用选项示例
5. Extends 配置继承
   - 5.1 eslint:recommended
   - 5.2 继承多个配置
   - 5.3 优先级
6. Plugins 扩展
   - 6.1 常用插件
   - 6.2 插件配置
   - 6.3 规则命名空间
7. 完整配置示例
8. 检验标准 ← 新增
9. 参考资源
```

**检验标准**：

- [ ] 能根据报错信息找到对应规则
- [ ] 能配置适合项目的规则集
- [ ] 理解 extends 继承机制
- [ ] 会使用常见插件

---

### 篇 3：eslint-3-integration.md（框架集成）

**目标**：能够为 TS/React/Vue 项目配置完整 ESLint

**结构**：

```
1. TypeScript 集成
   - 1.1 @typescript-eslint 概述
   - 1.2 安装与基础配置
   - 1.3 解析器配置
   - 1.4 tsconfig.json 集成
2. 类型感知 Linting
   - 2.1 什么是类型感知
   - 2.2 启用方式
   - 2.3 类型感知规则
3. React 集成
   - 3.1 eslint-plugin-react
   - 3.2 eslint-plugin-react-hooks
   - 3.3 JSX 规则详解
4. Vue 集成
   - 4.1 eslint-plugin-vue
   - 4.2 Vue 3 配置
5. 脚手架配置
   - 5.1 Next.js
   - 5.2 Vite
6. 完整配置示例
7. 检验标准 ← 新增
8. 参考资源
```

**检验标准**：

- [ ] 能为 TS 项目配置类型感知 linting
- [ ] 能为 React 项目配置完整 ESLint
- [ ] 能解决常见集成问题

---

### 篇 4：eslint-4-workflow.md（团队工作流）

**目标**：能够搭建团队级 ESLint 工作流

**结构**：

```
1. Git Hooks 集成
   - 1.1 husky v9 基础
   - 1.2 lint-staged 配置
   - 1.3 完整配置示例
2. CI/CD 集成
   - 2.1 GitHub Actions
   - 2.2 缓存优化
   - 2.3 PR 结果展示
3. ESLint + Prettier
   - 3.1 职责边界
   - 3.2 冲突解决
   - 3.3 完整配置
4. 团队规范
   - 4.1 规则选择原则
   - 4.2 严重程度策略
   - 4.3 变更流程
5. 配置共享
   - 5.1 npm 包形式
   - 5.2 创建与发布
   - 5.3 版本管理
6. 检验标准 ← 新增
7. 参考资源
```

**检验标准**：

- [ ] 能配置 husky + lint-staged
- [ ] 能集成 CI/CD
- [ ] 理解 ESLint + Prettier 协作
- [ ] 能发布共享配置包

---

### 篇 5：eslint-5-advanced.md（进阶定制）

**目标**：能够编写自定义规则和开发插件

**结构**：

```
1. Flat Config 深度
   - 1.1 配置结构详解
   - 1.2 迁移指南
   - 1.3 调试技巧
2. 自定义规则入门
   - 2.1 为什么需要
   - 2.2 AST 基础
   - 2.3 规则结构
   - 2.4 实战案例
3. 插件开发
   - 3.1 插件结构
   - 3.2 入口文件
   - 3.3 发布 npm
4. 测试规则
   - 4.1 RuleTester
   - 4.2 自动修复测试
5. 性能优化
   - 5.1 缓存策略
   - 5.2 慢规则定位
   - 5.3 优化策略
6. 检验标准 ← 新增
7. 参考资源
```

**检验标准**：

- [ ] 能编写简单自定义规则
- [ ] 能开发并发布插件
- [ ] 能进行性能优化

---

### 篇 6：eslint-6-practice.md（实战综合）

**目标**：能够独立解决项目中的 ESLint 问题

**结构**：

```
1. 完整项目配置案例
   - 1.1 TS + React + Vite 项目
   - 1.2 TS + React + Next.js 项目
2. 场景解决方案
   - 2.1 新项目从零配置
   - 2.2 旧项目迁移
   - 2.3 多框架共存
3. 配置解读
   - 3.1 读懂规则报错
   - 3.2 理解配置继承
4. 最佳实践
   - 4.1 配置组织
   - 4.2 规则选择
5. 检验标准 ← 新增
```

**检验标准**：

- [ ] 能独立配置完整项目
- [ ] 能解决 90% 配置问题

---

### 篇 7：eslint-7-troubleshooting.md（问题排查）

**目标**：能够诊断和解决 ESLint 问题

**结构**：

```
1. 规则不生效排查
   - 1.1 配置优先级
   - 1.2 files 范围错误
   - 1.3 插件未加载
2. 配置冲突解决
   - 2.1 ESLint 规则冲突
   - 2.2 与 Prettier 冲突
   - 2.3 插件规则冲突
3. 性能问题
   - 3.1 缓存使用
   - 3.2 TIMING 分析
   - 3.3 大型项目优化
4. Monorepo 配置
   - 4.1 根目录配置
   - 4.2 包级别覆盖
   - 4.3 跨包共享
5. 故障案例
   - 5.1 真实问题复现
   - 5.2 解决思路
6. 检验标准 ← 新增
7. 参考资源
```

**检验标准**：

- [ ] 能诊断规则不生效
- [ ] 能解决冲突问题
- [ ] 能优化性能
- [ ] 能配置 Monorepo

---

## 文件命名规范

```
docs/eslint-1-basics.md
docs/eslint-2-rules.md
docs/eslint-3-integration.md
docs/eslint-4-workflow.md
docs/eslint-5-advanced.md
docs/eslint-6-practice.md
docs/eslint-7-troubleshooting.md
```
