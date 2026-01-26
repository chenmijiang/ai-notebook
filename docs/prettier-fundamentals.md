# Prettier 基础概念与原理

## 1. 概述

### 1.1 什么是 Prettier

Prettier 是一个「固执己见」（Opinionated）的代码格式化工具。它通过解析代码并按照自己的规则重新打印，强制执行一致的代码风格。

**核心特性：**

| 特性     | 说明                                            |
| -------- | ----------------------------------------------- |
| 固执己见 | 提供极少的配置选项，自动决定代码风格            |
| 多语言   | 支持 JavaScript、TypeScript、CSS、HTML、JSON 等 |
| 跨编辑器 | VS Code、WebStorm、Vim 等主流编辑器均有插件支持 |
| 零配置   | 开箱即用，无需繁琐配置                          |
| 集成友好 | 可与 ESLint、Git Hooks、CI/CD 等工具无缝集成    |

**格式化前后对比：**

```
❌ 格式化前：风格混乱
function example(  a,b,c){return a+b+c}
const obj={foo:1,bar:2,baz:3}
```

```javascript
// ✅ 格式化后：统一整洁
function example(a, b, c) {
  return a + b + c;
}
const obj = { foo: 1, bar: 2, baz: 3 };
```

### 1.2 Prettier vs Linter

Prettier 和 Linter（如 ESLint）是两种不同类型的工具，各有侧重。

| 对比维度   | Prettier（格式化工具） | ESLint（代码检查工具）         |
| ---------- | ---------------------- | ------------------------------ |
| 核心功能   | 代码格式化             | 代码质量检查                   |
| 关注点     | 代码「长什么样」       | 代码「有没有问题」             |
| 规则类型   | 纯格式规则             | 格式规则 + 代码质量规则        |
| 配置复杂度 | 极少选项               | 大量可配置规则                 |
| 自动修复   | 完全重写代码           | 部分规则可自动修复             |
| 典型场景   | 缩进、换行、引号、分号 | 未使用变量、类型错误、最佳实践 |

**Linter 规则分类：**

| 规则类型     | 说明                    | 示例                 | 建议工具 |
| ------------ | ----------------------- | -------------------- | -------- |
| 格式化规则   | 代码外观样式            | 缩进、空格、换行     | Prettier |
| 代码质量规则 | 可能导致 bug 的代码模式 | 未使用变量、无效比较 | ESLint   |

**最佳实践：Prettier + ESLint 配合使用**

```
Prettier 处理：格式问题
const x=1    →    const x = 1;

ESLint 处理：代码质量问题
const unused = 1;   ⚠️ 'unused' is defined but never used
if (x = 1) {}       ⚠️ Expected a conditional expression
```

> **提示**：使用 `eslint-config-prettier` 可以关闭 ESLint 中与 Prettier 冲突的格式化规则，让两者和平共处。

## 2. 设计哲学

### 2.1 固执己见（Opinionated）

Prettier 的核心设计理念是「固执己见」——它对代码应该如何格式化有自己的主张，并且几乎不给用户选择的余地。

**传统格式化工具的问题：**

```
代码风格配置文件（如 .eslintrc）
├── 缩进：2 空格还是 4 空格？Tab 还是空格？
├── 引号：单引号还是双引号？
├── 分号：要还是不要？
├── 换行：每行多少字符？
├── 括号：function 后面要不要空格？
└── ...还有数十个选项需要决定
```

**Prettier 的解决方案：**

```
.prettierrc（极简配置）
├── printWidth: 80（行宽）
├── tabWidth: 2（缩进宽度）
├── useTabs: false（使用空格）
├── semi: true（分号）
├── singleQuote: false（引号）
└── ...仅此几个核心选项
```

Prettier 有意限制配置选项，因为：

1. **减少决策负担**：不需要为每个细节做决定
2. **避免争论**：没有选择就没有争论
3. **保证一致性**：所有项目使用相同的风格

### 2.2 为什么减少配置项

Prettier 官方明确表示：**不接受添加新配置选项的 PR**。这是一个深思熟虑的设计决策。

**配置选项的代价：**

| 问题         | 说明                                            |
| ------------ | ----------------------------------------------- |
| 维护成本     | 每个选项都需要测试、文档、bug 修复              |
| 组合爆炸     | n 个选项产生 2^n 种组合，难以保证每种组合都正确 |
| 用户选择困难 | 选项越多，用户越难做决定                        |
| 团队争论     | 有选项就会有人想改，引发无尽争论                |

**Prettier 的选项原则：**

```
                   是否添加选项的决策流程
                         ┌───┐
                         │开始│
                         └─┬─┘
                           ↓
              ┌─────────────────────────┐
              │ 这个选项是否影响代码正确性？ │
              └───────────┬─────────────┘
                    ╱           ╲
                  是             否
                  ↓               ↓
              ┌──────┐    ┌──────────────┐
              │可以加 │    │ 是否有压倒性  │
              └──────┘    │ 的社区共识？   │
                          └──────┬───────┘
                            ╱         ╲
                          是           否
                          ↓             ↓
                     ┌──────┐      ┌──────┐
                     │可以加 │      │不添加 │
                     └──────┘      └──────┘
```

### 2.3 停止争论代码风格

Prettier 的终极目标是：**让团队停止争论代码风格**。

**代码风格争论的典型场景：**

```
开发者 A 喜欢：const foo = 'bar';    （单引号）
开发者 B 喜欢：const foo = "bar";    （双引号）
开发者 C 喜欢：const foo = "bar"     （无分号）

→ Code Review 变成风格之争...
```

**使用 Prettier 后：**

```javascript
// 所有人的代码都变成
const foo = "bar";

// Code Review 专注于逻辑 ✅
```

**Prettier 解决的问题：**

| 问题     | Prettier 之前            | Prettier 之后          |
| -------- | ------------------------ | ---------------------- |
| 风格争论 | 每次 PR 都可能有风格讨论 | 没有讨论空间           |
| 新人上手 | 需要学习项目风格规范     | 保存时自动格式化       |
| 代码审查 | 混杂风格问题和逻辑问题   | 专注代码逻辑           |
| 编码体验 | 写代码时注意格式         | 随便写，保存时自动修复 |

> **提示**：Prettier 的口号是「An opinionated code formatter」，核心价值在于用「独断」换取「和平」。

## 3. 工作原理

Prettier 的工作流程可以概括为三个阶段：**解析（Parse）→ 构建 AST → 打印（Print）**。

### 3.1 解析阶段（Parse）

解析阶段将源代码转换为抽象语法树（AST）。

**解析流程：**

```
源代码字符串
    │
    ↓
┌─────────┐
│  Parser │  ← 根据文件类型选择对应的解析器
└────┬────┘
     │
     ↓
抽象语法树（AST）
```

**Prettier 内置的解析器：**

| 解析器     | 用途            | 底层实现                        |
| ---------- | --------------- | ------------------------------- |
| babel      | JavaScript、JSX | @babel/parser                   |
| typescript | TypeScript、TSX | @typescript-eslint/typescript-estree |
| babel-ts   | TypeScript（支持更多 JS 提案） | @babel/parser + TypeScript 插件 |
| css        | CSS             | postcss-selector-parser         |
| html       | HTML            | angular-html-parser             |
| markdown   | Markdown        | remark                          |
| yaml       | YAML            | yaml                            |
| graphql    | GraphQL         | graphql-js                      |

**示例：源代码到 AST**

```javascript
// 源代码
const x = 1 + 2;
```

```
// AST 结构（简化）
Program
└── VariableDeclaration (const)
    └── VariableDeclarator
        ├── Identifier (x)
        └── BinaryExpression (+)
            ├── NumericLiteral (1)
            └── NumericLiteral (2)
```

### 3.2 AST 处理

AST 是代码的结构化表示，忽略了原始格式信息（空格、换行、注释位置等）。

**AST 的特点：**

| 特点     | 说明                             |
| -------- | -------------------------------- |
| 结构化   | 代码被表示为树状结构             |
| 语义保留 | 保留代码的逻辑含义               |
| 格式丢失 | 原始的空格、换行、缩进信息被丢弃 |
| 可遍历   | 可以遍历、修改树的节点           |

**为什么使用 AST：**

```
这三种写法产生相同的 AST：
const x=1+2;
const x = 1 + 2;
const x =    1    +    2;

↓ Prettier 重新打印时，输出统一格式

const x = 1 + 2;
```

**插件可以在 AST 阶段进行预处理：**

```typescript
// Prettier 插件的 preprocess 函数
function preprocess(ast: AST, options: Options): AST {
  // 可以在打印前修改 AST
  return transformedAst;
}
```

### 3.3 打印阶段（Print）

打印阶段将 AST 转换为中间表示（IR/Doc），然后生成最终的格式化代码。

**打印流程：**

```
AST
 │
 ↓
┌─────────┐
│ Printer │  ← 将 AST 转换为中间表示（Doc）
└────┬────┘
     │
     ↓
中间表示（Doc）
     │
     ↓
┌───────────┐
│ Doc Print │  ← 根据行宽等选项生成最终字符串
└─────┬─────┘
      │
      ↓
格式化后的代码字符串
```

**中间表示（Doc）的作用：**

Prettier 不直接输出字符串，而是先生成一种中间表示（IR），这个 IR 称为 Doc。Doc 可以让 Prettier「测量」输出是否适合一行，如果超出行宽则自动换行。

```javascript
// 短代码：适合一行
const obj = { foo: 1, bar: 2 };

// 长代码：自动换行
const obj = {
  foo: 1,
  bar: 2,
  baz: 3,
  qux: 4,
  quux: 5,
};
```

**行宽智能处理：**

| 情况              | Prettier 行为              |
| ----------------- | -------------------------- |
| 内容 ≤ printWidth | 保持单行                   |
| 内容 > printWidth | 自动换行并缩进             |
| 链式调用          | 根据长度决定是否展开       |
| 函数参数          | 根据参数数量和长度决定格式 |

### 3.4 格式化流程图解

**完整的格式化流程：**

```
┌─────────────────────────────────────────────────────────────┐
│                    Prettier 格式化流程                       │
└─────────────────────────────────────────────────────────────┘

    源代码                                          格式化后代码
┌───────────┐                                     ┌───────────┐
│const x=1+2│                                     │const x =  │
│           │                                     │  1 + 2;   │
└─────┬─────┘                                     └─────▲─────┘
      │                                                 │
      │ ①解析                                          │ ④输出
      ↓                                                 │
┌───────────┐                                     ┌───────────┐
│   Parser  │                                     │Doc Printer│
│  (Babel)  │                                     │           │
└─────┬─────┘                                     └─────▲─────┘
      │                                                 │
      │ ②生成                                          │ ③转换
      ↓                                                 │
┌───────────┐        ┌───────────┐              ┌───────────┐
│    AST    │───────→│ Preprocess│─────────────→│    Doc    │
│ (语法树)   │        │  (可选)   │               │ (中间表示) │
└───────────┘        └───────────┘              └───────────┘
```

**关键步骤说明：**

| 步骤     | 输入         | 输出            | 说明                       |
| -------- | ------------ | --------------- | -------------------------- |
| ① 解析   | 源代码字符串 | AST             | 根据语言选择合适的 Parser  |
| ② 预处理 | AST          | 处理后的 AST    | 插件可选的 AST 转换步骤    |
| ③ 打印   | AST          | Doc（中间表示） | 构建格式无关的中间表示     |
| ④ 输出   | Doc          | 格式化代码      | 根据行宽等选项输出最终代码 |

## 4. 支持范围

### 4.1 内置支持的语言

Prettier 开箱即用支持以下语言，无需安装额外插件。

| 语言/格式  | 解析器               | 文件扩展名      |
| ---------- | -------------------- | --------------- |
| JavaScript | babel, espree        | .js, .mjs, .cjs |
| JSX        | babel                | .jsx            |
| TypeScript | typescript, babel-ts | .ts, .mts, .cts |
| TSX        | typescript, babel-ts | .tsx            |
| JSON       | json          | .json           |
| JSON5      | json5         | .json5          |
| CSS        | css           | .css            |
| Less       | less          | .less           |
| SCSS       | scss          | .scss           |
| HTML       | html          | .html           |
| Vue        | vue           | .vue            |
| Angular    | angular       | .component.html |
| Markdown   | markdown      | .md, .markdown  |
| MDX        | mdx           | .mdx            |
| YAML       | yaml          | .yml, .yaml     |
| GraphQL    | graphql       | .graphql, .gql  |
| Handlebars | glimmer       | .hbs            |

### 4.2 需要插件的语言

以下语言需要安装社区或官方提供的插件。

| 语言/格式       | 插件名称                    | 安装命令                                     |
| --------------- | --------------------------- | -------------------------------------------- |
| PHP             | @prettier/plugin-php        | npm install -D @prettier/plugin-php          |
| Ruby            | @prettier/plugin-ruby       | npm install -D @prettier/plugin-ruby         |
| Java            | prettier-plugin-java        | npm install -D prettier-plugin-java          |
| XML             | @prettier/plugin-xml        | npm install -D @prettier/plugin-xml          |
| SQL             | prettier-plugin-sql         | npm install -D prettier-plugin-sql           |
| Blade (Laravel) | prettier-plugin-blade       | npm install -D prettier-plugin-blade         |
| Tailwind CSS    | prettier-plugin-tailwindcss | npm install -D prettier-plugin-tailwindcss   |
| Svelte          | prettier-plugin-svelte      | npm install -D prettier-plugin-svelte        |
| Astro           | prettier-plugin-astro       | npm install -D prettier-plugin-astro         |

**插件使用示例：**

```javascript
// prettier.config.js
export default {
  plugins: ["prettier-plugin-tailwindcss"],
};
```

```bash
# 安装并使用 PHP 插件
npm install --save-dev prettier @prettier/plugin-php
npx prettier --write "**/*.php"
```

### 4.3 Prettier 的边界

Prettier 不是万能的，了解它的边界很重要。

**Prettier 能做什么：**

| 能力     | 说明                         |
| -------- | ---------------------------- |
| 统一格式 | 强制执行一致的代码风格       |
| 自动换行 | 根据行宽自动处理换行         |
| 缩进对齐 | 自动处理缩进和对齐           |
| 语法美化 | 括号、引号、分号等的统一处理 |

**Prettier 不能做什么：**

| 限制         | 说明                                                 |
| ------------ | ---------------------------------------------------- |
| 代码质量检查 | 不检测未使用变量、类型错误等（用 ESLint/TypeScript） |
| 代码逻辑优化 | 不会改变代码逻辑或性能优化                           |
| 命名规范检查 | 不检查变量、函数命名是否符合规范（用 ESLint）        |
| 导入排序     | 默认不排序 import 语句（需要插件或 ESLint 规则）     |
| 注释格式化   | 不格式化注释内容（保留原样）                         |
| 任意语言支持 | 只支持有 Parser 的语言                               |

**与其他工具的配合：**

```
┌────────────────────────────────────────────────┐
│                   代码质量保障体系               │
├────────────────────────────────────────────────┤
│                                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ Prettier │  │  ESLint  │  │TypeScript│     │
│  │          │  │          │  │          │     │
│  │  格式化   │  │ 代码质量  │  │ 类型检查  │     │
│  └──────────┘  └──────────┘  └──────────┘     │
│       │             │             │           │
│       └─────────────┴─────────────┘           │
│                     │                         │
│              ┌──────────────┐                 │
│              │   Git Hooks  │                 │
│              │  (Husky等)   │                 │
│              └──────────────┘                 │
│                                                │
└────────────────────────────────────────────────┘
```

## 5. 总结

### 5.1 核心要点回顾

| 要点     | 说明                                          |
| -------- | --------------------------------------------- |
| 定位     | 固执己见的代码格式化工具                      |
| 设计哲学 | 减少选项、停止争论、统一风格                  |
| 工作原理 | Parse → AST → Print，通过中间表示实现智能换行 |
| 支持范围 | 内置支持前端主流语言，其他语言通过插件支持    |
| 最佳搭档 | 与 ESLint、TypeScript 配合使用                |

### 5.2 适用场景

| 场景     | 建议                              |
| -------- | --------------------------------- |
| 新项目   | 直接引入 Prettier，越早越好       |
| 团队协作 | 统一配置，配合 Git Hooks 强制执行 |
| 个人项目 | 可选，但能提升编码体验            |
| 遗留项目 | 逐步引入，先格式化新代码          |

### 5.3 速查表

| 概念        | 说明                                    |
| ----------- | --------------------------------------- |
| Opinionated | 固执己见，有主张的                      |
| AST         | 抽象语法树（Abstract Syntax Tree）      |
| Doc/IR      | 中间表示（Intermediate Representation） |
| Parser      | 解析器，将代码转换为 AST                |
| Printer     | 打印器，将 AST 转换为格式化代码         |
| printWidth  | 行宽，超出后自动换行（默认 80）         |
| Plugin      | 插件，扩展 Prettier 支持新语言          |

## 参考资源

- [Prettier 官方文档](https://prettier.io/docs/)
- [Prettier vs. Linters](https://prettier.io/docs/en/comparison)
- [Option Philosophy](https://prettier.io/docs/en/option-philosophy)
- [Prettier Plugins](https://prettier.io/docs/en/plugins)
- [Prettier GitHub 仓库](https://github.com/prettier/prettier)
- [eslint-config-prettier](https://github.com/prettier/eslint-config-prettier)
