# ESLint V2 学习计划 - 实施计划

> **目标**：创建 7 篇全新 ESLint 专家学习文档
> **状态**：需根据 tech-docs-guide 规范调整

---

## 一、文档命名规范

遵循「主题 + 完全指南/使用指南」格式：

```
docs/eslint-1-basics.md          → # ESLint 基础完全指南
docs/eslint-2-rules.md           → # ESLint 规则完全指南
docs/eslint-3-integration.md     → # ESLint 框架集成完全指南
docs/eslint-4-workflow.md        → # ESLint 团队工作流完全指南
docs/eslint-5-advanced.md        → # ESLint 进阶完全指南
docs/eslint-6-practice.md        → # ESLint 实战完全指南
docs/eslint-7-troubleshooting.md → # ESLint 问题排查完全指南
```

---

## 二、文档结构规范

每篇必须包含：

```markdown
# 标题

## 1. 概述
## 2. 核心内容
## 3. ...
## N. 总结
### N.1 核心要点
### N.2 速查表
## 参考资源
```

**禁止使用**：

- 目录（TOC）
- 章节分隔线 `---`

---

## 三、内容格式规范

### 3.1 章节编号

| 层级 | 格式              | 示例                  |
| ---- | ----------------- | --------------------- |
| 一级 | `## 1. 标题`      | `## 1. 概述`          |
| 二级 | `### 1.1 标题`    | `### 1.1 ESLint 定位` |
| 三级 | `#### 1.1.1 标题` | `#### 1.1.1 核心概念` |

### 3.2 代码块

```javascript
// ✅ 简洁示例 + 中文注释
function greet(name) {
  return `Hello, ${name}`;
}

// ❌ 冗长示例
function greet(name) {
  console.log('Hello, ' + name);
  return 'Hello, ' + name;
}
```

要求：

- 标注语言类型
- 简洁聚焦
- 中文注释关键步骤
- 使用 `// ✅` 和 `// ❌` 标记

### 3.3 表格

大量使用表格进行：

- 对比说明
- 参数说明
- 速查总结

### 3.4 提示信息

```markdown
> **注意**：重要警告

> **提示**：有用建议

> **说明**：补充信息
```

### 3.5 图解

- 简单图：ASCII 艺术
- 复杂图：Mermaid 语法

### 3.6 对比说明

使用 ✅ 和 ❌ 标记好/坏实践

---

## 四、每篇文档规范

### 篇 1：eslint-1-basics.md

**标题**: `# ESLint 基础完全指南`

**结构**:

```markdown
## 1. 概述
### 1.1 ESLint 定位
### 1.2 ESLint vs Prettier vs TypeScript
## 2. 核心概念
### 2.1 Rules
### 2.2 Plugins
### 2.3 Extends
### 2.4 Environments
### 2.5 Parser
## 3. 配置格式
### 3.1 Flat Config 入门
### 3.2 配置结构
## 4. 工作原理
### 4.1 解析阶段
### 4.2 检查阶段
### 4.3 报告阶段
## 5. CLI 命令
### 5.1 常用命令
### 5.2 常用选项
## 6. 总结
### 6.1 核心要点
### 6.2 速查表
## 参考资源
```

---

### 篇 2：eslint-2-rules.md

**标题**: `# ESLint 规则完全指南`

**结构**:

```markdown
## 1. 规则严重程度
## 2. 规则查找与分类
## 3. 常用规则详解
## 4. 规则选项配置
## 5. Extends 继承
## 6. Plugins 扩展
## 7. 完整配置示例
## 8. 总结
### 8.1 核心要点
### 8.2 速查表
## 参考资源
```

---

### 篇 3：eslint-3-integration.md

**标题**: `# ESLint 框架集成完全指南`

**结构**:

```markdown
## 1. TypeScript 集成
### 1.1 @typescript-eslint 概述
### 1.2 安装与配置
### 1.3 类型感知 Linting
## 2. React 集成
### 2.1 eslint-plugin-react
### 2.2 eslint-plugin-react-hooks
### 2.3 JSX 规则
## 3. Vue 集成
### 3.1 eslint-plugin-vue
## 4. 脚手架配置
### 4.1 Next.js
### 4.2 Vite
## 5. 完整配置示例
## 6. 总结
### 6.1 核心要点
### 6.2 速查表
## 参考资源
```

---

### 篇 4：eslint-4-workflow.md

**标题**: `# ESLint 团队工作流完全指南`

**结构**:

```markdown
## 1. Git Hooks 集成
### 1.1 husky v9
### 1.2 lint-staged
## 2. CI/CD 集成
### 2.1 GitHub Actions
### 2.2 缓存优化
## 3. ESLint + Prettier
### 3.1 职责边界
### 3.2 冲突解决
## 4. 团队规范
### 4.1 规则选择
### 4.2 严重程度策略
## 5. 配置共享
### 5.1 npm 包
### 5.2 发布流程
## 6. 总结
### 6.1 核心要点
### 6.2 速查表
## 参考资源
```

---

### 篇 5：eslint-5-advanced.md

**标题**: `# ESLint 进阶完全指南`

**结构**:

```markdown
## 1. Flat Config 深度
### 1.1 迁移指南
### 1.2 调试技巧
## 2. 自定义规则
### 2.1 AST 基础
### 2.2 规则结构
### 2.3 实战案例
## 3. 插件开发
### 3.1 插件结构
### 3.2 发布 npm
## 4. 测试规则
### 4.1 RuleTester
## 5. 性能优化
### 5.1 缓存策略
### 5.2 TIMING 分析
## 6. 总结
### 6.1 核心要点
### 6.2 速查表
## 参考资源
```

---

### 篇 6：eslint-6-practice.md

**标题**: `# ESLint 实战完全指南`

**结构**:

```markdown
## 1. 项目案例
### 1.1 TS + React + Vite
### 1.2 TS + React + Next.js
## 2. 场景解决方案
### 2.1 新项目配置
### 2.2 旧项目迁移
## 3. 配置解读
## 4. 最佳实践
## 5. 总结
## 参考资源
```

---

### 篇 7：eslint-7-troubleshooting.md

**标题**: `# ESLint 问题排查完全指南`

**结构**:

```markdown
## 1. 规则不生效
### 1.1 配置优先级
### 1.2 files 范围
### 1.3 插件加载
## 2. 配置冲突
### 2.1 ESLint 规则冲突
### 2.2 Prettier 冲突
## 3. 性能问题
### 3.1 缓存使用
### 3.2 TIMING 分析
## 4. Monorepo 配置
### 4.1 根目录配置
### 4.2 包级别覆盖
## 5. 故障案例
## 6. 总结
### 6.1 核心要点
### 6.2 速查表
## 参考资源
```

---

## 五、执行检查清单

创建每篇文档时必须检查：

- [ ] 使用简体中文
- [ ] 标题符合「主题 + 完全指南」格式
- [ ] 章节编号正确（1. → 1.1 → 1.1.1）
- [ ] 无目录、无 `---` 分隔线
- [ ] 代码块简洁、有中文注释
- [ ] 使用 `// ✅` 和 `// ❌` 标记
- [ ] 大量使用表格
- [ ] 复杂图用 Mermaid
- [ ] 有总结章节（核心要点 + 速查表）
- [ ] 有参考资源章节

---

## 六、实施顺序

```
阶段一：基础
├── Task 1: eslint-1-basics.md
└── Task 2: eslint-2-rules.md

阶段二：应用
├── Task 3: eslint-3-integration.md
└── Task 4: eslint-4-workflow.md

阶段三：进阶
├── Task 5: eslint-5-advanced.md
└── Task 6: eslint-6-practice.md

阶段四：收官
└── Task 7: eslint-7-troubleshooting.md
```
