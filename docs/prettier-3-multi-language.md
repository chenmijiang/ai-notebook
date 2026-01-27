# Prettier 多语言支持指南

## 1. 概述

### 1.1 内置语言支持

Prettier 开箱即用支持多种前端主流语言和数据格式，无需安装额外插件。

| 语言类别      | 支持的语言/格式                        |
| ------------- | -------------------------------------- |
| JavaScript 系 | JavaScript、JSX、TypeScript、TSX、Flow |
| 样式表        | CSS、Less、SCSS                        |
| 标记语言      | HTML、Vue、Angular                     |
| 文档格式      | Markdown、MDX                          |
| 数据格式      | JSON、JSON5、YAML                      |
| 其他          | GraphQL、Handlebars                    |

**内置解析器与文件扩展名对照：**

| 解析器       | 用途                 | 文件扩展名            |
| ------------ | -------------------- | --------------------- |
| `babel`      | JavaScript、JSX      | .js, .mjs, .cjs, .jsx |
| `babel-flow` | Flow                 | .js（需指定）         |
| `babel-ts`   | TypeScript（Babel）  | .ts, .tsx（需指定）   |
| `typescript` | TypeScript           | .ts, .mts, .cts, .tsx |
| `espree`     | JavaScript（ESLint） | .js（需指定）         |
| `meriyah`    | JavaScript           | .js（需指定）         |
| `acorn`      | JavaScript           | .js（需指定）         |
| `css`        | CSS                  | .css                  |
| `less`       | Less                 | .less                 |
| `scss`       | SCSS                 | .scss                 |
| `html`       | HTML                 | .html, .htm           |
| `vue`        | Vue SFC              | .vue                  |
| `angular`    | Angular 模板         | .component.html       |
| `markdown`   | Markdown             | .md, .markdown        |
| `mdx`        | MDX                  | .mdx                  |
| `yaml`       | YAML                 | .yml, .yaml           |
| `json`       | JSON                 | .json                 |
| `json5`      | JSON5                | .json5                |
| `jsonc`      | JSON with Comments   | .jsonc                |
| `graphql`    | GraphQL              | .graphql, .gql        |
| `glimmer`    | Handlebars           | .hbs, .handlebars     |

### 1.2 插件扩展机制

对于 Prettier 未内置支持的语言，可以通过插件扩展。插件提供两个核心能力：

| 能力   | 说明                        |
| ------ | --------------------------- |
| 解析器 | 将源代码解析为 AST          |
| 打印器 | 将 AST 转换为格式化后的代码 |

**插件加载方式：**

```javascript
// prettier.config.js
// 通过 plugins 数组加载插件
export default {
  plugins: [
    "prettier-plugin-tailwindcss", // npm 包名
    "./my-custom-plugin.js", // 本地文件路径
  ],
};
```

Prettier 3.x 自动发现 `node_modules` 中已安装的插件，大多数情况下无需手动配置 `plugins` 数组。

> **提示**：关于 Prettier 的基础概念和工作原理，请参阅 [Prettier 基础概念与原理](./prettier-fundamentals.md)。

## 2. 各语言配置详解

### 2.1 JavaScript/TypeScript

JavaScript 和 TypeScript 是 Prettier 支持最完善的语言，拥有最丰富的配置选项。

**可用解析器对比：**

| 解析器       | 底层实现                   | 特点                               |
| ------------ | -------------------------- | ---------------------------------- |
| `babel`      | @babel/parser              | 默认选择，支持最新 ECMAScript 提案 |
| `babel-flow` | @babel/parser + Flow       | 支持 Flow 类型注解                 |
| `babel-ts`   | @babel/parser + TypeScript | 支持 TS，同时支持更多 JS 提案      |
| `typescript` | typescript-estree          | 官方 TS 解析器，更严格的类型检查   |
| `espree`     | espree（ESLint 默认）      | 与 ESLint 保持一致                 |
| `meriyah`    | meriyah                    | 高性能解析器                       |
| `acorn`      | acorn                      | 轻量级解析器                       |

**JavaScript/TypeScript 专用选项：**

| 选项             | 类型                                      | 默认值      | 说明                     |
| ---------------- | ----------------------------------------- | ----------- | ------------------------ |
| `semi`           | boolean                                   | true        | 语句末尾添加分号         |
| `singleQuote`    | boolean                                   | false       | 使用单引号               |
| `jsxSingleQuote` | boolean                                   | false       | JSX 属性使用单引号       |
| `trailingComma`  | "all" \| "es5" \| "none"                  | "all"       | 尾随逗号策略             |
| `bracketSpacing` | boolean                                   | true        | 对象字面量括号内加空格   |
| `arrowParens`    | "always" \| "avoid"                       | "always"    | 箭头函数单参数是否加括号 |
| `quoteProps`     | "as-needed" \| "consistent" \| "preserve" | "as-needed" | 对象属性引号策略         |

**配置示例：**

```javascript
// prettier.config.js
/** @type {import("prettier").Config} */
export default {
  // ✅ 推荐的 JavaScript 项目配置
  semi: true, // 保留分号，避免 ASI 问题
  singleQuote: true, // 单引号更简洁
  trailingComma: "es5", // ES5 兼容模式
  arrowParens: "avoid", // 单参数省略括号：x => x * 2

  overrides: [
    {
      // TypeScript 文件使用官方解析器
      files: ["*.ts", "*.tsx"],
      options: {
        parser: "typescript",
      },
    },
  ],
};
```

**babel vs typescript 解析器选择：**

```javascript
// ✅ 使用 babel-ts：需要最新 JS 提案支持
// 例如：装饰器、管道运算符等实验性语法
{
  "overrides": [
    {
      "files": "*.ts",
      "options": { "parser": "babel-ts" }
    }
  ]
}

// ✅ 使用 typescript：需要更严格的类型检查
// 推荐用于生产项目
{
  "overrides": [
    {
      "files": "*.ts",
      "options": { "parser": "typescript" }
    }
  ]
}
```

### 2.2 HTML/Vue/Angular

Prettier 对 HTML 及其衍生模板语言有专门的处理逻辑，主要关注空白字符敏感性问题。

**HTML 相关解析器：**

| 解析器    | 用途                     | 文件扩展名      |
| --------- | ------------------------ | --------------- |
| `html`    | 标准 HTML                | .html, .htm     |
| `vue`     | Vue 单文件组件           | .vue            |
| `angular` | Angular 模板             | .component.html |
| `lwc`     | Lightning Web Components | .html           |

**HTML 专用选项：**

| 选项                        | 类型                          | 默认值 | 说明                        |
| --------------------------- | ----------------------------- | ------ | --------------------------- |
| `htmlWhitespaceSensitivity` | "css" \| "strict" \| "ignore" | "css"  | 空白字符敏感度              |
| `bracketSameLine`           | boolean                       | false  | 多行元素 `>` 是否放最后一行 |
| `singleAttributePerLine`    | boolean                       | false  | 每行一个属性                |
| `vueIndentScriptAndStyle`   | boolean                       | false  | Vue 文件缩进 script/style   |

**htmlWhitespaceSensitivity 详解：**

```html
<!-- 源代码 -->
<span>Hello</span><span>World</span>

<!-- "css"（默认）：遵循 CSS display 属性 -->
<!-- inline 元素保持紧凑，block 元素可换行 -->
<span>Hello</span><span>World</span>

<!-- "strict"：严格保留空白，不做任何换行处理 -->
<span>Hello</span><span>World</span>

<!-- "ignore"：忽略空白敏感性，自由格式化 -->
<span> Hello </span>
<span> World </span>
```

**Vue 单文件组件配置：**

```javascript
// prettier.config.js
export default {
  // Vue 文件配置
  vueIndentScriptAndStyle: false, // 不缩进 <script> 和 <style> 内容

  overrides: [
    {
      files: "*.vue",
      options: {
        htmlWhitespaceSensitivity: "ignore", // Vue 模板通常不关心空白
        singleAttributePerLine: true, // 每行一个属性，便于 diff
      },
    },
  ],
};
```

**Vue 格式化示例：**

```vue
<!-- ❌ 格式化前：属性混乱 -->
<template>
  <button
    class="btn primary"
    @click="handleClick"
    :disabled="loading"
    v-if="visible"
  >
    Click me
  </button>
</template>

<!-- ✅ 格式化后：singleAttributePerLine: true -->
<template>
  <button
    class="btn primary"
    :disabled="loading"
    v-if="visible"
    @click="handleClick"
  >
    Click me
  </button>
</template>
```

**Angular 模板配置：**

```json
{
  "overrides": [
    {
      "files": "*.component.html",
      "options": {
        "parser": "angular",
        "htmlWhitespaceSensitivity": "strict"
      }
    }
  ]
}
```

### 2.3 CSS/SCSS/Less

Prettier 对 CSS 及其预处理器语言提供统一的格式化支持。

**CSS 相关解析器：**

| 解析器 | 用途 | 文件扩展名 |
| ------ | ---- | ---------- |
| `css`  | CSS  | .css       |
| `scss` | SCSS | .scss      |
| `less` | Less | .less      |

**CSS 格式化特点：**

| 特点       | 说明                           |
| ---------- | ------------------------------ |
| 自动排序   | 不排序属性（保留原始顺序）     |
| 空行处理   | 保留单个空行，移除多余空行     |
| 选择器格式 | 多选择器自动换行               |
| 值格式     | 颜色值统一格式，数值单位标准化 |

**CSS 配置示例：**

```javascript
// prettier.config.js
export default {
  overrides: [
    {
      files: ["*.css", "*.scss", "*.less"],
      options: {
        singleQuote: false, // CSS 使用双引号
        printWidth: 80,
      },
    },
  ],
};
```

**格式化效果：**

```css
/* ❌ 格式化前 */
.button {
  color: red;
  background: #fff;
  padding: 10px 20px;
}
.button:hover,
.button:focus {
  color: blue;
}

/* ✅ 格式化后 */
.button {
  color: red;
  background: #fff;
  padding: 10px 20px;
}
.button:hover,
.button:focus {
  color: blue;
}
```

**SCSS 嵌套格式化：**

```scss
// ✅ 格式化后的 SCSS
.card {
  padding: 1rem;

  &__title {
    font-size: 1.5rem;
    font-weight: bold;
  }

  &__content {
    margin-top: 0.5rem;
  }

  @media (min-width: 768px) {
    padding: 2rem;
  }
}
```

### 2.4 Markdown

Prettier 对 Markdown 的格式化主要关注一致性，同时尊重文档的可读性。

**Markdown 相关解析器：**

| 解析器     | 用途          | 文件扩展名     |
| ---------- | ------------- | -------------- |
| `markdown` | 标准 Markdown | .md, .markdown |
| `mdx`      | MDX           | .mdx           |

**Markdown 专用选项：**

| 选项        | 类型                              | 默认值     | 说明         |
| ----------- | --------------------------------- | ---------- | ------------ |
| `proseWrap` | "always" \| "never" \| "preserve" | "preserve" | 段落换行处理 |
| `tabWidth`  | number                            | 2          | 列表缩进宽度 |

**proseWrap 详解：**

```markdown
<!-- 源文本（一个很长的段落） -->

这是一个很长的段落，包含了很多文字内容，用来演示 proseWrap 选项的效果。

<!-- proseWrap: "preserve"（默认）：保留原始换行 -->

这是一个很长的段落，包含了很多文字内容，用来演示 proseWrap 选项的效果。

<!-- proseWrap: "always"：按 printWidth 自动换行 -->

这是一个很长的段落，包含了很多文字内容，
用来演示 proseWrap 选项的效果。

<!-- proseWrap: "never"：合并为一行 -->

这是一个很长的段落，包含了很多文字内容，用来演示 proseWrap 选项的效果。
```

**Markdown 配置建议：**

```json
{
  "overrides": [
    {
      "files": "*.md",
      "options": {
        "proseWrap": "preserve",
        "printWidth": 80,
        "tabWidth": 2
      }
    }
  ]
}
```

**Markdown 格式化效果：**

```markdown
<!-- ❌ 格式化前：列表缩进不一致 -->

- 第一项
  - 子项 A
  - 子项 B
- 第二项

<!-- ✅ 格式化后：统一缩进 -->

- 第一项
  - 子项 A
  - 子项 B
- 第二项
```

**嵌入代码块格式化：**

````javascript
// prettier.config.js
export default {
  // embeddedLanguageFormatting 控制嵌入代码的格式化
  embeddedLanguageFormatting: "auto", // 自动格式化代码块内的代码

  overrides: [
    {
      files: "*.md",
      options: {
        embeddedLanguageFormatting: "auto", // 格式化 ```js 代码块
      },
    },
  ],
};
````

### 2.5 JSON/YAML

数据格式文件的格式化主要关注一致的缩进和尾随逗号处理。

**JSON 相关解析器：**

| 解析器  | 用途               | 文件扩展名            |
| ------- | ------------------ | --------------------- |
| `json`  | 标准 JSON          | .json                 |
| `json5` | JSON5（宽松语法）  | .json5                |
| `jsonc` | JSON with Comments | .jsonc, tsconfig.json |

**JSON 配置特点：**

| 特点     | 说明                                |
| -------- | ----------------------------------- |
| 尾随逗号 | 标准 JSON 不支持，Prettier 自动移除 |
| 注释     | json 解析器不支持注释，使用 jsonc   |
| 引号     | 始终使用双引号（JSON 规范要求）     |

**JSON 配置示例：**

```json
{
  "overrides": [
    {
      "files": ["*.json", "package.json"],
      "options": {
        "parser": "json",
        "trailingComma": "none",
        "tabWidth": 2
      }
    },
    {
      "files": ["tsconfig.json", "jsconfig.json", ".vscode/*.json"],
      "options": {
        "parser": "jsonc",
        "trailingComma": "none"
      }
    }
  ]
}
```

**YAML 格式化：**

| 解析器 | 用途 | 文件扩展名  |
| ------ | ---- | ----------- |
| `yaml` | YAML | .yml, .yaml |

```yaml
# ❌ 格式化前：缩进混乱
services:
    web:
      image: nginx
      ports:
       - "80:80"

# ✅ 格式化后：统一缩进
services:
  web:
    image: nginx
    ports:
      - "80:80"
```

**YAML 配置：**

```json
{
  "overrides": [
    {
      "files": ["*.yml", "*.yaml"],
      "options": {
        "tabWidth": 2,
        "proseWrap": "preserve"
      }
    }
  ]
}
```

### 2.6 GraphQL

Prettier 内置支持 GraphQL schema 和 query 的格式化。

| 解析器    | 用途    | 文件扩展名     |
| --------- | ------- | -------------- |
| `graphql` | GraphQL | .graphql, .gql |

**GraphQL 格式化示例：**

```graphql
# ❌ 格式化前
query GetUser($id: ID!) {
  user(id: $id) {
    name
    email
    posts {
      title
    }
  }
}

# ✅ 格式化后
query GetUser($id: ID!) {
  user(id: $id) {
    name
    email
    posts {
      title
    }
  }
}
```

**GraphQL 配置：**

```json
{
  "overrides": [
    {
      "files": ["*.graphql", "*.gql"],
      "options": {
        "printWidth": 80,
        "tabWidth": 2
      }
    }
  ]
}
```

## 3. overrides 进阶用法

`overrides` 是 Prettier 实现多语言差异化配置的核心机制。关于 overrides 的基础用法，请参阅 [Prettier 配置完全指南](./prettier-configuration.md)。

### 3.1 按扩展名定制

**基本语法：**

```json
{
  "overrides": [
    {
      "files": "*.ts",
      "options": {
        "parser": "typescript"
      }
    }
  ]
}
```

**多扩展名匹配：**

```json
{
  "overrides": [
    {
      "files": "*.{js,jsx,ts,tsx}",
      "options": {
        "singleQuote": true,
        "semi": true
      }
    },
    {
      "files": ["*.json", "*.json5", "*.jsonc"],
      "options": {
        "trailingComma": "none"
      }
    }
  ]
}
```

**为特殊文件指定解析器：**

```json
{
  "overrides": [
    {
      "files": ".prettierrc",
      "options": { "parser": "json" }
    },
    {
      "files": ".babelrc",
      "options": { "parser": "json" }
    },
    {
      "files": "*.svg",
      "options": { "parser": "html" }
    },
    {
      "files": ".env*",
      "options": { "parser": "sh" }
    }
  ]
}
```

### 3.2 按目录定制

**按目录设置不同规则：**

```json
{
  "printWidth": 80,
  "overrides": [
    {
      "files": "src/client/**/*.{js,jsx,ts,tsx}",
      "options": {
        "printWidth": 100,
        "jsxSingleQuote": false
      }
    },
    {
      "files": "src/server/**/*.{js,ts}",
      "options": {
        "printWidth": 120
      }
    },
    {
      "files": "legacy/**/*",
      "options": {
        "tabWidth": 4,
        "printWidth": 120
      }
    }
  ]
}
```

**Monorepo 项目配置：**

```javascript
// prettier.config.js
export default {
  printWidth: 100,
  singleQuote: true,

  overrides: [
    // 前端应用
    {
      files: "apps/web/**/*.{js,jsx,ts,tsx}",
      options: {
        printWidth: 80,
        singleAttributePerLine: true,
      },
    },
    // 文档站点
    {
      files: "apps/docs/**/*.{md,mdx}",
      options: {
        proseWrap: "always",
        printWidth: 80,
      },
    },
    // 共享 UI 组件库
    {
      files: "packages/ui/**/*.{js,jsx,ts,tsx}",
      options: {
        printWidth: 100,
        jsxSingleQuote: false,
      },
    },
    // 工具库
    {
      files: "packages/utils/**/*.ts",
      options: {
        printWidth: 120,
      },
    },
  ],
};
```

### 3.3 glob 模式技巧

**常用 glob 模式：**

| 模式             | 匹配说明                |
| ---------------- | ----------------------- |
| `*.js`           | 当前目录的 .js 文件     |
| `**/*.js`        | 所有目录的 .js 文件     |
| `src/**/*.js`    | src 目录下所有 .js 文件 |
| `*.{js,ts}`      | .js 和 .ts 文件         |
| `*.test.{js,ts}` | 测试文件                |
| `!*.min.js`      | 排除压缩文件            |
| `[abc].js`       | a.js, b.js, c.js        |
| `?.js`           | 单字符文件名            |

**复杂匹配示例：**

```json
{
  "overrides": [
    {
      "files": ["**/*.test.{js,ts}", "**/*.spec.{js,ts}", "**/__tests__/**/*"],
      "options": {
        "printWidth": 120
      }
    },
    {
      "files": ["*.config.{js,ts,mjs,cjs}", "*rc.{js,cjs}"],
      "options": {
        "printWidth": 100
      }
    },
    {
      "files": ["**/*.stories.{js,jsx,ts,tsx}", "**/*.story.{js,jsx,ts,tsx}"],
      "options": {
        "printWidth": 100,
        "singleAttributePerLine": true
      }
    }
  ]
}
```

### 3.4 多条件组合

**数组形式匹配多种文件：**

```json
{
  "overrides": [
    {
      "files": ["*.html", "*.vue", "*.component.html"],
      "options": {
        "htmlWhitespaceSensitivity": "ignore",
        "printWidth": 120
      }
    }
  ]
}
```

**组合目录和扩展名：**

```javascript
// prettier.config.js
export default {
  overrides: [
    {
      // API 目录的所有文件使用宽行
      files: ["src/api/**/*.ts", "src/services/**/*.ts"],
      options: {
        printWidth: 120,
      },
    },
    {
      // 组件目录使用严格格式
      files: ["src/components/**/*.{vue,jsx,tsx}"],
      options: {
        printWidth: 80,
        singleAttributePerLine: true,
      },
    },
    {
      // 测试和快照
      files: [
        "**/__tests__/**/*",
        "**/*.test.*",
        "**/*.spec.*",
        "**/__snapshots__/**/*",
      ],
      options: {
        printWidth: 120,
      },
    },
  ],
};
```

**overrides 优先级规则：**

| 规则       | 说明                                     |
| ---------- | ---------------------------------------- |
| 后定义优先 | 数组中后面的 override 会覆盖前面的       |
| 精确匹配   | 更精确的模式不会自动优先                 |
| 完全覆盖   | override 中的 options 完全替换匹配的选项 |

```json
{
  "singleQuote": false,
  "overrides": [
    {
      "files": "*.js",
      "options": { "singleQuote": true }
    },
    {
      "files": "legacy/*.js",
      "options": { "singleQuote": false }
    }
  ]
}
```

> **注意**：`legacy/*.js` 只会使用 `singleQuote: false`，不会继承第一个 override 的其他选项。

## 4. 解析器（Parser）机制

### 4.1 自动检测原理

Prettier 通过文件扩展名自动选择合适的解析器。

**检测流程：**

```
文件路径
   │
   ↓
┌─────────────────────┐
│ 1. 检查 overrides   │  ← 配置文件中的 parser 设置
│    是否指定 parser  │
└──────────┬──────────┘
           │ 否
           ↓
┌─────────────────────┐
│ 2. 根据文件扩展名   │  ← 内置映射表
│    匹配 parser      │
└──────────┬──────────┘
           │ 未匹配
           ↓
┌─────────────────────┐
│ 3. 检查已加载插件   │  ← 插件提供的扩展名映射
│    支持的扩展名     │
└──────────┬──────────┘
           │ 未匹配
           ↓
      跳过该文件
```

**扩展名到解析器的映射示例：**

| 扩展名          | 自动选择的解析器 |
| --------------- | ---------------- |
| .js, .mjs, .cjs | babel            |
| .jsx            | babel            |
| .ts, .mts, .cts | typescript       |
| .tsx            | typescript       |
| .json           | json             |
| .md             | markdown         |
| .html           | html             |
| .vue            | vue              |
| .css            | css              |
| .scss           | scss             |
| .less           | less             |
| .yml, .yaml     | yaml             |
| .graphql, .gql  | graphql          |

### 4.2 显式指定 parser

某些文件无法通过扩展名自动识别，需要手动指定解析器。

**场景 1：无扩展名配置文件**

```json
{
  "overrides": [
    {
      "files": [".prettierrc", ".babelrc", ".eslintrc"],
      "options": { "parser": "json" }
    },
    {
      "files": [".prettierrc.js", ".babelrc.js"],
      "options": { "parser": "babel" }
    }
  ]
}
```

**场景 2：非标准扩展名**

```json
{
  "overrides": [
    {
      "files": "*.wxss",
      "options": { "parser": "css" }
    },
    {
      "files": "*.wxml",
      "options": { "parser": "html" }
    },
    {
      "files": "*.cjson",
      "options": { "parser": "json" }
    }
  ]
}
```

**场景 3：强制使用特定解析器**

```json
{
  "overrides": [
    {
      "files": "*.js",
      "options": { "parser": "babel-flow" }
    },
    {
      "files": "*.ts",
      "options": { "parser": "babel-ts" }
    }
  ]
}
```

**CLI 指定解析器：**

```bash
# 格式化并指定解析器
prettier --parser typescript --write "src/**/*.ts"

# 格式化标准输入
echo "const x=1" | prettier --parser babel
```

**API 指定解析器：**

```javascript
import * as prettier from "prettier";

// 使用内置解析器
const formatted = await prettier.format(code, {
  parser: "typescript",
});

// 使用自定义解析器
const formatted = await prettier.format(code, {
  parser: require("./my-parser.js"),
});
```

### 4.3 解析器对照表

**内置解析器完整列表：**

| 解析器       | 语言/格式  | 底层实现            | 说明                     |
| ------------ | ---------- | ------------------- | ------------------------ |
| `babel`      | JavaScript | @babel/parser       | 默认 JS 解析器           |
| `babel-flow` | Flow       | @babel/parser       | 支持 Flow 类型           |
| `babel-ts`   | TypeScript | @babel/parser       | Babel 的 TS 支持         |
| `typescript` | TypeScript | typescript-estree   | 官方 TS 解析器           |
| `espree`     | JavaScript | espree              | ESLint 兼容              |
| `meriyah`    | JavaScript | meriyah             | 高性能                   |
| `acorn`      | JavaScript | acorn               | 轻量级                   |
| `css`        | CSS        | postcss             | CSS 解析                 |
| `less`       | Less       | postcss-less        | Less 预处理器            |
| `scss`       | SCSS       | postcss-scss        | SCSS 预处理器            |
| `html`       | HTML       | angular-html-parser | HTML 解析                |
| `vue`        | Vue SFC    | vue-eslint-parser   | Vue 单文件组件           |
| `angular`    | Angular    | angular-html-parser | Angular 模板             |
| `lwc`        | LWC        | angular-html-parser | Lightning Web Components |
| `markdown`   | Markdown   | remark              | Markdown 解析            |
| `mdx`        | MDX        | remark + mdx        | MDX 格式                 |
| `yaml`       | YAML       | yaml                | YAML 解析                |
| `json`       | JSON       | @babel/parser       | 标准 JSON                |
| `json5`      | JSON5      | json5               | 宽松 JSON                |
| `jsonc`      | JSONC      | @babel/parser       | 带注释的 JSON            |
| `graphql`    | GraphQL    | graphql-js          | GraphQL 解析             |
| `glimmer`    | Handlebars | glimmer-engine      | Handlebars 模板          |

**解析器选择决策表：**

| 场景                     | 推荐解析器   | 原因             |
| ------------------------ | ------------ | ---------------- |
| 普通 JavaScript 项目     | `babel`      | 支持最新语法     |
| TypeScript 项目          | `typescript` | 更严格的类型检查 |
| 使用实验性语法的 TS 项目 | `babel-ts`   | 支持更多 JS 提案 |
| Flow 项目                | `babel-flow` | Flow 类型支持    |
| 与 ESLint 集成           | `espree`     | AST 一致性       |
| 追求极致性能             | `meriyah`    | 解析速度快       |

## 5. 插件系统

### 5.1 插件加载机制

Prettier 插件扩展了对新语言的支持，每个插件需要提供解析器（parser）和打印器（printer）。

**插件结构：**

```javascript
// 一个 Prettier 插件的基本结构
export const languages = [
  {
    name: "My Language",
    parsers: ["my-parser"],
    extensions: [".mylang"],
  },
];

export const parsers = {
  "my-parser": {
    parse: (text) => {
      // 将源代码解析为 AST
      return ast;
    },
    astFormat: "my-ast",
  },
};

export const printers = {
  "my-ast": {
    print: (path, options, print) => {
      // 将 AST 转换为格式化后的代码
      return formattedCode;
    },
  },
};
```

**加载方式：**

| 方式     | 配置方法                                    | 说明               |
| -------- | ------------------------------------------- | ------------------ |
| 自动发现 | Prettier 3.x 自动加载 node_modules 中的插件 | 最简便             |
| 显式配置 | 在 plugins 数组中指定包名                   | 推荐，确保加载顺序 |
| 本地文件 | 在 plugins 数组中指定文件路径               | 自定义插件         |

```javascript
// prettier.config.js
export default {
  plugins: [
    // npm 包名（自动从 node_modules 加载）
    "prettier-plugin-tailwindcss",
    "@prettier/plugin-php",

    // 本地插件文件
    "./plugins/my-custom-plugin.js",
  ],
};
```

**插件加载顺序：**

```
1. 配置文件中 plugins 数组的顺序
2. 多个插件支持同一扩展名时，先加载的优先
```

> **提示**：插件顺序可能影响格式化结果，如 `prettier-plugin-tailwindcss` 需要在其他 HTML/JSX 插件之后加载。

### 5.2 常用社区插件

**官方维护的插件：**

| 插件名                  | 用途 | 安装命令                         |
| ----------------------- | ---- | -------------------------------- |
| `@prettier/plugin-php`  | PHP  | `npm i -D @prettier/plugin-php`  |
| `@prettier/plugin-xml`  | XML  | `npm i -D @prettier/plugin-xml`  |
| `@prettier/plugin-ruby` | Ruby | `npm i -D @prettier/plugin-ruby` |
| `@prettier/plugin-pug`  | Pug  | `npm i -D @prettier/plugin-pug`  |

**社区热门插件：**

| 插件名                             | 用途              | 安装命令                                    |
| ---------------------------------- | ----------------- | ------------------------------------------- |
| `prettier-plugin-tailwindcss`      | Tailwind 类名排序 | `npm i -D prettier-plugin-tailwindcss`      |
| `prettier-plugin-svelte`           | Svelte            | `npm i -D prettier-plugin-svelte`           |
| `prettier-plugin-astro`            | Astro             | `npm i -D prettier-plugin-astro`            |
| `prettier-plugin-organize-imports` | 导入语句排序      | `npm i -D prettier-plugin-organize-imports` |
| `prettier-plugin-sql`              | SQL               | `npm i -D prettier-plugin-sql`              |
| `prettier-plugin-sh`               | Shell 脚本        | `npm i -D prettier-plugin-sh`               |
| `prettier-plugin-toml`             | TOML              | `npm i -D prettier-plugin-toml`             |
| `prettier-plugin-prisma`           | Prisma Schema     | `npm i -D prettier-plugin-prisma`           |
| `prettier-plugin-java`             | Java              | `npm i -D prettier-plugin-java`             |
| `prettier-plugin-kotlin`           | Kotlin            | `npm i -D prettier-plugin-kotlin`           |
| `prettier-plugin-go-template`      | Go Template       | `npm i -D prettier-plugin-go-template`      |

**插件功能对比：**

| 插件                               | 新增语言 | 新增选项 | 修改现有行为   |
| ---------------------------------- | -------- | -------- | -------------- |
| `@prettier/plugin-php`             | PHP      | 是       | 否             |
| `prettier-plugin-tailwindcss`      | 否       | 否       | 是（类名排序） |
| `prettier-plugin-svelte`           | Svelte   | 是       | 否             |
| `prettier-plugin-organize-imports` | 否       | 是       | 是（导入排序） |

### 5.3 插件配置示例

**Tailwind CSS 插件：**

```javascript
// prettier.config.js
export default {
  plugins: ["prettier-plugin-tailwindcss"],

  // Tailwind 插件选项
  tailwindConfig: "./tailwind.config.js",
  tailwindFunctions: ["clsx", "cn"], // 自定义类名函数
};
```

**格式化效果：**

```jsx
// ❌ 格式化前：类名无序
<div className="p-4 flex mt-2 items-center bg-white justify-between">

// ✅ 格式化后：按 Tailwind 推荐顺序排列
<div className="flex items-center justify-between bg-white p-4 mt-2">
```

**PHP 插件：**

```javascript
// prettier.config.js
export default {
  plugins: ["@prettier/plugin-php"],

  overrides: [
    {
      files: "*.php",
      options: {
        phpVersion: "8.2",
        trailingCommaPHP: true,
        braceStyle: "per-cs",
      },
    },
  ],
};
```

**Svelte 插件：**

```javascript
// prettier.config.js
export default {
  plugins: ["prettier-plugin-svelte"],

  overrides: [
    {
      files: "*.svelte",
      options: {
        parser: "svelte",
        svelteSortOrder: "options-scripts-markup-styles",
        svelteStrictMode: false,
        svelteIndentScriptAndStyle: true,
      },
    },
  ],
};
```

**多插件配置：**

```javascript
// prettier.config.js
// 完整的多语言项目配置
export default {
  // 基础配置
  printWidth: 100,
  tabWidth: 2,
  semi: true,
  singleQuote: true,
  trailingComma: "es5",

  // 加载多个插件
  plugins: [
    "prettier-plugin-svelte",
    "prettier-plugin-tailwindcss", // Tailwind 需要在 Svelte 之后
    "@prettier/plugin-php",
  ],

  // 各语言定制
  overrides: [
    // Svelte
    {
      files: "*.svelte",
      options: {
        parser: "svelte",
      },
    },
    // PHP
    {
      files: "*.php",
      options: {
        phpVersion: "8.2",
      },
    },
    // Vue（内置支持）
    {
      files: "*.vue",
      options: {
        singleAttributePerLine: true,
      },
    },
  ],
};
```

**验证插件是否生效：**

```bash
# 查看 Prettier 支持的解析器（包括插件提供的）
npx prettier --help

# 查看特定文件会使用的配置
npx prettier --find-config-path ./src/App.svelte

# 检查插件是否正确加载
npx prettier --check "**/*.svelte"
```

## 6. 总结

### 6.1 核心要点回顾

| 要点           | 说明                                          |
| -------------- | --------------------------------------------- |
| 内置语言支持   | JS/TS/CSS/HTML/Vue/Markdown/JSON/YAML/GraphQL |
| 解析器自动选择 | 根据文件扩展名自动匹配，可通过 overrides 覆盖 |
| overrides 机制 | 按文件模式为不同文件设置不同配置              |
| 插件扩展       | 通过插件支持 PHP/Ruby/Svelte/Astro 等更多语言 |
| 配置优先级     | CLI > overrides > 基础配置 > 默认值           |

### 6.2 多语言配置速查表

| 语言       | 解析器     | 关键选项                              |
| ---------- | ---------- | ------------------------------------- |
| JavaScript | babel      | semi, singleQuote, trailingComma      |
| TypeScript | typescript | parser, semi, singleQuote             |
| HTML       | html       | htmlWhitespaceSensitivity             |
| Vue        | vue        | vueIndentScriptAndStyle               |
| CSS        | css        | singleQuote                           |
| Markdown   | markdown   | proseWrap, embeddedLanguageFormatting |
| JSON       | json/jsonc | trailingComma: "none"                 |
| YAML       | yaml       | tabWidth                              |
| GraphQL    | graphql    | printWidth                            |

### 6.3 常见问题速查

| 问题                       | 解决方案                                     |
| -------------------------- | -------------------------------------------- |
| 文件未被格式化             | 检查 .prettierignore，确认解析器支持该扩展名 |
| 格式不符合预期             | 使用 `--find-config-path` 检查配置加载       |
| 插件未生效                 | 确认插件已安装，检查 plugins 数组配置        |
| 不同文件需要不同配置       | 使用 overrides 按文件模式设置                |
| 非标准扩展名文件           | 在 overrides 中显式指定 parser               |
| 特殊文件（如 .prettierrc） | 在 overrides 中指定 `parser: "json"`         |

> **下一步**：了解多语言支持后，建议阅读 [Prettier 编辑器集成指南](./prettier-editor-integration.md) 学习如何在编辑器中配置 Prettier，或阅读 [Prettier 工具链整合指南](./prettier-toolchain-integration.md) 了解与 ESLint、Git Hooks 的集成方案。

## 参考资源

- [Prettier Options](https://prettier.io/docs/en/options)
- [Prettier Configuration](https://prettier.io/docs/en/configuration)
- [Prettier Plugins](https://prettier.io/docs/en/plugins)
- [Prettier 基础概念与原理](./prettier-fundamentals.md)
- [Prettier 配置完全指南](./prettier-configuration.md)
