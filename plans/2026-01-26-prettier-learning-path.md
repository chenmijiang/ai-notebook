# Prettier 学习路径：从入门到熟练掌握

## 背景

- 已有基础使用经验，项目中跟着用但不太懂配置
- 目标：系统性全面掌握
- 场景：多语言混合（JS/TS、Markdown、JSON、YAML、HTML 等）
- 环境：多编辑器混用
- 协作：个人项目和团队项目兼顾

## 学习方法

采用**自底向上**的方式：从原理和核心概念学起，逐步扩展到实践场景。理解透彻后，遇到问题能从根本解决。

---

## 第一部分：基础概念与原理

**目标**：理解 Prettier 是什么、为什么存在、核心设计哲学。

**学习内容**：

1. **Prettier 定位**：它是"opinionated code formatter"（固执己见的代码格式化器），与 linter 的本质区别是什么
2. **设计哲学**：为什么 Prettier 故意减少配置项（只有约 20 个选项），"停止争论代码风格"的理念
3. **工作原理**：解析代码为 AST → 丢弃原有格式 → 按规则重新打印。理解这个流程能解释很多"为什么 Prettier 这样格式化"的疑问
4. **支持范围**：哪些语言是内置支持，哪些需要插件，Prettier 的边界在哪里

**产出**：能向别人解释"为什么用 Prettier 而不是 ESLint 的格式化规则"。

---

## 第二部分：核心配置详解

**目标**：掌握所有配置项的含义、使用场景和最佳实践。

**学习内容**：

1. **配置文件类型与优先级**：`.prettierrc`、`.prettierrc.json`、`.prettierrc.js`、`prettier.config.js`、`package.json` 中的 `prettier` 字段——它们的区别和加载顺序
2. **核心选项逐个击破**：
   - 打印相关：`printWidth`、`tabWidth`、`useTabs`
   - 语法风格：`semi`、`singleQuote`、`quoteProps`、`trailingComma`
   - 括号与空格：`bracketSpacing`、`bracketSameLine`、`arrowParens`
   - 特殊处理：`proseWrap`（Markdown）、`htmlWhitespaceSensitivity`、`endOfLine`
3. **配置作用域**：全局配置 vs 目录级配置 vs 文件级覆盖（overrides）
4. **`.prettierignore`**：忽略规则的写法，与 `.gitignore` 的异同

**产出**：能根据项目需求从零写出完整配置，并解释每个选项的取舍理由。

---

## 第三部分：多语言支持

**目标**：掌握 Prettier 对各类文件的处理方式，知道如何按语言定制规则。

**学习内容**：

1. **内置支持的语言**：JavaScript、TypeScript、JSX/TSX、JSON、CSS/Less/SCSS、HTML、Vue、Markdown、YAML、GraphQL 等——各自的默认行为和特殊选项
2. **`overrides` 进阶用法**：
   - 按文件扩展名定制：`*.md` 用不同的 `proseWrap`，`*.json` 用不同的 `tabWidth`
   - 按目录定制：`scripts/**` 和 `src/**` 使用不同规则
   - 多条件组合：glob 模式的写法技巧
3. **解析器（parser）机制**：Prettier 如何识别文件类型，什么时候需要显式指定 `parser`，常见解析器有哪些
4. **插件系统入门**：如何安装和使用社区插件（如 `prettier-plugin-tailwindcss`、`prettier-plugin-organize-imports`），插件的加载机制

**产出**：能为多语言项目配置差异化规则，按需引入插件扩展能力。

---

## 第四部分：编辑器集成

**目标**：实现多编辑器环境下的一致格式化体验。

**学习内容**：

1. **核心原则**：编辑器只是 Prettier 的"触发器"，配置应以项目级 `.prettierrc` 为准，而非编辑器设置
2. **VS Code 配置**：
   - Prettier 扩展的设置项与 `.prettierrc` 的关系
   - `editor.defaultFormatter` 和 `editor.formatOnSave` 的正确配置
   - 工作区设置 vs 用户设置的优先级
3. **JetBrains 系列**：内置 Prettier 支持的启用方式，如何指定 Prettier 路径和配置文件
4. **Vim/Neovim**：常用插件方案（如 `prettier.nvim`、`null-ls`），格式化触发方式
5. **跨编辑器一致性保障**：
   - 依赖项目本地的 `node_modules/.bin/prettier` 而非全局安装
   - `.editorconfig` 与 Prettier 的配合（Prettier 会读取 `.editorconfig`）
   - 团队共享编辑器配置的策略

**产出**：能在任意编辑器中实现"保存即格式化"，且结果完全一致。

---

## 第五部分：工具链整合

**目标**：让 Prettier 与 ESLint、Git hooks、CI/CD 无缝协作。

**学习内容**：

1. **Prettier 与 ESLint 的关系**：
   - 职责划分：Prettier 管格式，ESLint 管代码质量
   - `eslint-config-prettier`：关闭 ESLint 中与 Prettier 冲突的规则
   - `eslint-plugin-prettier`（可选）：把 Prettier 作为 ESLint 规则运行——优缺点分析
   - 推荐方案：分开运行，各司其职
2. **Git hooks 集成**：
   - `husky` + `lint-staged` 组合：只格式化暂存文件，提交前自动修复
   - 配置写法和常见坑（如大文件、二进制文件的排除）
3. **CI/CD 集成**：
   - `prettier --check` 检查模式：不修改文件，只报告问题
   - 在 GitHub Actions / GitLab CI 中的典型配置
   - 失败时的错误信息解读
4. **npm scripts 规范**：`format`、`format:check` 的命名惯例和写法

**产出**：能搭建完整的格式化工作流——本地保存自动格式化、提交前兜底检查、CI 强制校验。

---

## 第六部分：团队协作实践

**目标**：在团队中推行和维护 Prettier，处理常见的协作问题。

**学习内容**：

1. **存量项目引入 Prettier**：
   - 一次性全量格式化 vs 渐进式引入的取舍
   - 如何处理"格式化炸弹"提交：单独一个 commit 做格式化，保持 git blame 可读性
   - `git blame --ignore-rev` 和 `.git-blame-ignore-revs` 的使用
2. **配置决策与沟通**：
   - 哪些选项值得讨论（`printWidth`、`singleQuote`），哪些应直接采用默认值
   - 用 Prettier 官方默认值减少争议的策略
3. **处理特殊情况**：
   - `// prettier-ignore` 注释：何时该用、何时不该用
   - 生成代码、第三方代码的排除策略
   - 与老代码/遗留系统的共存
4. **版本管理**：
   - 锁定 Prettier 版本的重要性（不同版本输出可能不同）
   - 升级 Prettier 的流程和注意事项

**产出**：能主导团队的 Prettier 引入和规范制定，平稳处理过渡期问题。

---

## 第七部分：高级用法与疑难解决

**目标**：应对复杂场景，排查疑难问题，了解 Prettier 生态的边界。

**学习内容**：

1. **调试技巧**：
   - `prettier --debug-check`：检查文件是否已格式化
   - `prettier --find-config-path <file>`：确认使用了哪个配置文件
   - `prettier --file-info <file>`：查看文件的解析器和忽略状态
2. **常见问题排查**：
   - "格式化结果和预期不一致"：配置优先级、缓存问题、版本差异
   - "某些文件没被格式化"：ignore 规则、parser 识别失败
   - "与 ESLint 冲突"：规则覆盖不完整、运行顺序问题
3. **性能优化**：
   - 大型项目的格式化策略
   - `--cache` 选项加速重复运行
4. **Prettier 的局限**：
   - 它不能做什么（不排序 import、不删除未使用变量——这些是 linter 的事）
   - 何时考虑补充工具（如 `@trivago/prettier-plugin-sort-imports`）

**产出**：遇到 Prettier 相关问题能快速定位原因，清楚知道什么该用 Prettier 解决、什么该用其他工具。

---

## 学习路径总览

| 阶段 | 主题               | 核心产出                            |
| ---- | ------------------ | ----------------------------------- |
| 一   | 基础概念与原理     | 理解 Prettier 设计哲学和工作原理    |
| 二   | 核心配置详解       | 能从零写出完整配置并解释取舍        |
| 三   | 多语言支持         | 掌握 overrides、parser、插件机制    |
| 四   | 编辑器集成         | 多编辑器环境下一致格式化            |
| 五   | 工具链整合         | ESLint + Git hooks + CI/CD 完整流程 |
| 六   | 团队协作实践       | 存量项目引入、版本管理、规范制定    |
| 七   | 高级用法与疑难解决 | 调试排查、性能优化、边界认知        |

## 建议学习方式

按顺序推进，每个阶段结合实际项目练习。可以用一个测试项目从零配置，逐步叠加复杂度。
