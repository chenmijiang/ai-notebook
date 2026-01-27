# Prettier 配置文件指南

## 1. 概述

### 1.1 配置方式总览

Prettier 支持多种配置方式，从零配置到精细控制均可实现。

| 配置方式     | 说明                          | 适用场景           |
| ------------ | ----------------------------- | ------------------ |
| 零配置       | 使用 Prettier 默认值          | 快速开始、简单项目 |
| 配置文件     | 项目根目录的 `.prettierrc` 等 | 团队协作、项目定制 |
| package.json | 在 `prettier` 字段中配置      | 减少配置文件数量   |
| CLI 参数     | 命令行传递选项                | 一次性格式化、脚本 |
| 编辑器设置   | VS Code 等编辑器的设置        | 个人偏好           |

**配置优先级（从高到低）：**

```
CLI 参数 > 配置文件 > 编辑器设置 > 默认值
```

### 1.2 配置加载优先级

当项目中存在多个配置来源时，Prettier 从被格式化文件所在目录开始，向上逐级搜索直到找到配置文件或到达文件系统根目录。

**配置文件搜索顺序（同一目录内）：**

| 优先级 | 配置文件                        | 格式       |
| ------ | ------------------------------- | ---------- |
| 1      | `.prettierrc`                   | JSON/YAML  |
| 2      | `.prettierrc.json`              | JSON       |
| 3      | `.prettierrc.yml`               | YAML       |
| 4      | `.prettierrc.yaml`              | YAML       |
| 5      | `.prettierrc.json5`             | JSON5      |
| 6      | `.prettierrc.js`                | JavaScript |
| 7      | `.prettierrc.cjs`               | CommonJS   |
| 8      | `.prettierrc.mjs`               | ES Module  |
| 9      | `.prettierrc.ts`                | TypeScript |
| 10     | `prettier.config.js`            | JavaScript |
| 11     | `prettier.config.cjs`           | CommonJS   |
| 12     | `prettier.config.mjs`           | ES Module  |
| 13     | `prettier.config.ts`            | TypeScript |
| 14     | `.prettierrc.toml`              | TOML       |
| 15     | `package.json` 的 prettier 字段 | JSON       |

> **注意**：`package.json` 是最后搜索的，不是优先级最高的。Prettier 先检查专用配置文件，找不到才查看 `package.json`。

**搜索路径：**

Prettier 从被格式化文件所在目录开始，向上逐级搜索直到找到配置文件或到达文件系统根目录。

```
project/
├── .prettierrc              # 项目级配置
├── src/
│   ├── components/
│   │   └── Button.jsx       # 使用项目级配置
│   └── legacy/
│       ├── .prettierrc      # 子目录配置（优先级更高）
│       └── old-code.js      # 使用 legacy/.prettierrc
└── package.json
```

> **提示**：建议每个项目只使用一个配置文件，放在项目根目录，避免配置混乱。

## 2. 配置文件类型

### 2.1 JSON 格式

JSON 是最常用的配置格式，简洁易读。

**`.prettierrc` 或 `.prettierrc.json`：**

```json
{
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false,
  "semi": true,
  "singleQuote": true,
  "trailingComma": "es5",
  "bracketSpacing": true,
  "arrowParens": "avoid"
}
```

**优点：**

- 语法简单，易于阅读
- 编辑器支持良好，有语法高亮和校验
- 可被大多数工具直接解析

**缺点：**

- 不支持注释（标准 JSON）
- 不支持尾随逗号

> **提示**：`.prettierrc`（无扩展名）默认按 JSON 解析，也支持 YAML 语法。

### 2.2 YAML 格式

YAML 格式支持注释，语法简洁，适合喜欢 YAML 风格的团队。

**`.prettierrc.yaml` 或 `.prettierrc.yml`：**

```yaml
# Prettier 配置
# 详见：https://prettier.io/docs/en/options

# 打印相关
printWidth: 100
tabWidth: 2
useTabs: false

# 语法风格
semi: true
singleQuote: true
trailingComma: "es5"
```

**优点：**

- 支持注释，便于说明配置意图
- 语法简洁，无需引号和逗号
- 可读性好，适合简单配置

**缺点：**

- 不支持动态配置
- 缩进敏感，容易出错
- 编辑器支持不如 JSON 普遍

### 2.3 TOML 格式

TOML 格式支持注释，语法明确，适合喜欢 TOML 风格的团队。

**`.prettierrc.toml`：**

```toml
# Prettier 配置

# 打印相关
printWidth = 100
tabWidth = 2
useTabs = false

# 语法风格
semi = true
singleQuote = true
trailingComma = "es5"
```

**优点：**

- 支持注释
- 语法明确，不易歧义
- 类型清晰（字符串必须加引号）

**缺点：**

- 不支持动态配置
- 使用较少，团队可能不熟悉
- 嵌套结构（如 overrides）写法较繁琐

### 2.4 JavaScript 格式

JavaScript 格式提供最大的灵活性，支持动态配置和注释。

**`.prettierrc.js` 或 `prettier.config.js`（ES Module）：**

```javascript
// prettier.config.js
// 支持注释，便于说明配置意图

/** @type {import("prettier").Config} */
export default {
  // 打印宽度
  printWidth: 100,

  // 使用单引号
  singleQuote: true,

  // 尾随逗号：ES5 兼容模式
  trailingComma: "es5",

  // 插件配置
  plugins: ["prettier-plugin-tailwindcss"],
};
```

**`.prettierrc.cjs`（CommonJS）：**

```javascript
// prettier.config.cjs
// 适用于 package.json 中 "type": "module" 的项目

/** @type {import("prettier").Config} */
module.exports = {
  printWidth: 100,
  singleQuote: true,
  trailingComma: "es5",
};
```

**动态配置示例：**

```javascript
// prettier.config.js
// 根据环境变量动态调整配置

/** @type {import("prettier").Config} */
export default {
  printWidth: process.env.CI ? 120 : 80,
  singleQuote: true,

  // 条件性加载插件
  plugins: [
    "prettier-plugin-tailwindcss",
    ...(process.env.SORT_IMPORTS
      ? ["@trivago/prettier-plugin-sort-imports"]
      : []),
  ],
};
```

**优点：**

- 支持注释和动态配置
- 可根据环境变量调整行为
- 有完整的类型提示支持

**缺点：**

- 需要注意模块格式（ESM vs CommonJS）
- 配置文件本身可能需要格式化

### 2.5 package.json 内嵌

将配置放在 `package.json` 的 `prettier` 字段中，减少项目根目录的文件数量。

```json
{
  "name": "my-project",
  "version": "1.0.0",
  "prettier": {
    "printWidth": 100,
    "singleQuote": true,
    "trailingComma": "es5"
  },
  "devDependencies": {
    "prettier": "^3.0.0"
  }
}
```

**适用场景：**

- 小型项目，配置简单
- 希望减少配置文件数量
- 配置无需注释说明

**不适用场景：**

- 需要使用注释
- 配置复杂，需要分组说明
- 使用 overrides 较多

### 2.6 各格式对比

| 格式         | 注释支持 | 动态配置 | 类型提示 | 推荐场景           |
| ------------ | -------- | -------- | -------- | ------------------ |
| JSON         | 否       | 否       | 有限     | 简单项目、快速配置 |
| YAML         | 是       | 否       | 否       | 喜欢 YAML 语法     |
| TOML         | 是       | 否       | 否       | 喜欢 TOML 语法     |
| JavaScript   | 是       | 是       | 是       | 复杂项目、需要插件 |
| package.json | 否       | 否       | 有限     | 减少文件数量       |

> **建议**：大多数项目使用 JSON 格式即可；需要注释说明时选择 YAML；需要动态配置或插件时选择 JavaScript。

## 3. 核心配置选项

### 3.1 打印相关

控制代码的基本排版方式。

| 选项         | 类型    | 默认值 | 说明                  |
| ------------ | ------- | ------ | --------------------- |
| `printWidth` | number  | 80     | 每行最大字符数        |
| `tabWidth`   | number  | 2      | 缩进空格数            |
| `useTabs`    | boolean | false  | 使用 Tab 缩进而非空格 |

**printWidth 示例：**

```javascript
// ❌ printWidth: 40（行宽太窄，频繁换行）
const result = calculateTotal(items, discount, tax);

// ✅ printWidth: 80（默认，平衡可读性）
const result = calculateTotal(items, discount, tax);

// printWidth: 120（宽屏显示器）
const result = calculateTotal(items, discount, tax, shippingCost, serviceFee);
```

> **提示**：`printWidth` 不是严格限制，而是 Prettier 的「目标」。某些情况下（如长字符串）可能超出此宽度。

**tabWidth 与 useTabs 示例：**

```javascript
// ✅ tabWidth: 2, useTabs: false（推荐）
function example() {
  const x = 1;
  return x;
}

// tabWidth: 4, useTabs: false
function example() {
    const x = 1;
    return x;
}

// useTabs: true（使用 Tab 字符）
function example() {
→ const x = 1;  // → 表示 Tab 字符
→ return x;
}
```

### 3.2 语法风格

控制 JavaScript/TypeScript 的语法风格。

| 选项             | 类型                                      | 默认值      | 说明                     |
| ---------------- | ----------------------------------------- | ----------- | ------------------------ |
| `semi`           | boolean                                   | true        | 语句末尾添加分号         |
| `singleQuote`    | boolean                                   | false       | 使用单引号而非双引号     |
| `jsxSingleQuote` | boolean                                   | false       | JSX 中使用单引号         |
| `quoteProps`     | "as-needed" \| "consistent" \| "preserve" | "as-needed" | 对象属性引号策略         |
| `trailingComma`  | "all" \| "es5" \| "none"                  | "all"       | 尾随逗号策略             |
| `arrowParens`    | "always" \| "avoid"                       | "always"    | 箭头函数单参数是否加括号 |

**semi 示例：**

```javascript
// ✅ semi: true（默认，推荐）
const name = "Prettier";
function greet() {
  return "Hello";
}

// semi: false（无分号风格）
const name = "Prettier"
function greet() {
  return "Hello"
}
```

**singleQuote 示例：**

```javascript
// singleQuote: false（默认）
const message = "Hello, World!";

// ✅ singleQuote: true（常用于 JavaScript 项目）
const message = 'Hello, World!';
```

> **注意**：`singleQuote` 不影响 JSX 属性，JSX 属性由 `jsxSingleQuote` 控制。

**jsxSingleQuote 示例：**

```jsx
// jsxSingleQuote: false（默认）
<div className="container">Hello</div>

// jsxSingleQuote: true
<div className='container'>Hello</div>
```

**quoteProps 示例：**

```javascript
// quoteProps: "as-needed"（默认，仅在必要时加引号）
const obj = {
  name: "value",
  "content-type": "application/json", // 包含连字符，必须加引号
};

// quoteProps: "consistent"（只要有一个需要引号，全部加引号）
const obj = {
  "name": "value",
  "content-type": "application/json",
};

// quoteProps: "preserve"（保留原始写法）
const obj = {
  name: "value", // 原来没引号就没引号
  "origin": "prettier.io", // 原来有引号就保留
};
```

**trailingComma 示例：**

```javascript
// trailingComma: "none"（不加尾随逗号）
const obj = {
  foo: 1,
  bar: 2
};

// trailingComma: "es5"（ES5 支持的地方加逗号）
const obj = {
  foo: 1,
  bar: 2, // ← 对象和数组可以
};
function fn(a, b) {} // ← 函数参数不加

// ✅ trailingComma: "all"（默认，所有地方都加）
const obj = {
  foo: 1,
  bar: 2,
};
function fn(
  a,
  b, // ← 函数参数也加
) {}
```

> **提示**：`trailingComma: "all"` 有助于减少 Git diff 中的无关变更。

> **注意**：Prettier v3 起，默认值从 `"es5"` 改为 `"all"`。如果项目使用 Prettier v2.x，默认值是 `"es5"`。

**arrowParens 示例：**

```javascript
// ✅ arrowParens: "always"（默认，始终加括号）
const double = (x) => x * 2;
const add = (a, b) => a + b;

// arrowParens: "avoid"（单参数时省略括号）
const double = x => x * 2;
const add = (a, b) => a + b; // 多参数仍需括号
```

### 3.3 括号与空格

控制括号和空格的使用方式。

| 选项              | 类型    | 默认值 | 说明                        |
| ----------------- | ------- | ------ | --------------------------- |
| `bracketSpacing`  | boolean | true   | 对象字面量括号内加空格      |
| `bracketSameLine` | boolean | false  | 多行元素的 `>` 放在最后一行 |

**bracketSpacing 示例：**

```javascript
// ✅ bracketSpacing: true（默认）
const obj = { foo: 1, bar: 2 };

// bracketSpacing: false
const obj = {foo: 1, bar: 2};
```

**bracketSameLine 示例：**

```jsx
// bracketSameLine: false（默认）
<button
  className="primary"
  onClick={handleClick}
>
  Click me
</button>

// bracketSameLine: true
<button
  className="primary"
  onClick={handleClick}>
  Click me
</button>
```

### 3.4 特殊处理

针对特定场景的配置选项。

| 选项                         | 类型                              | 默认值     | 说明                   |
| ---------------------------- | --------------------------------- | ---------- | ---------------------- |
| `proseWrap`                  | "always" \| "never" \| "preserve" | "preserve" | Markdown 换行处理      |
| `htmlWhitespaceSensitivity`  | "css" \| "strict" \| "ignore"     | "css"      | HTML 空白敏感度        |
| `endOfLine`                  | "lf" \| "crlf" \| "cr" \| "auto"  | "lf"       | 行尾符号               |
| `singleAttributePerLine`     | boolean                           | false      | HTML/JSX 每行一个属性  |
| `embeddedLanguageFormatting` | "auto" \| "off"                   | "auto"     | 嵌入代码格式化         |
| `experimentalTernaries`      | boolean                           | false      | 实验性三元表达式格式化 |

**proseWrap 示例：**

```markdown
<!-- proseWrap: "preserve"（默认，保留原始换行） -->

This is a very long line that was written this way in the original file.
It will stay on one line.

<!-- proseWrap: "always"（按 printWidth 自动换行） -->

This is a very long line that was
written this way in the original file.
It will be wrapped.

<!-- proseWrap: "never"（段落合并为一行） -->

This is a very long line that was written this way in the original file. It will stay on one line.
```

**htmlWhitespaceSensitivity 示例：**

```html
<!-- htmlWhitespaceSensitivity: "css"（默认，遵循 CSS display 属性） -->
<span>inline</span>
<div>block</div>

<!-- htmlWhitespaceSensitivity: "strict"（严格保留空白） -->
<span>inline</span>
<div>block</div>

<!-- htmlWhitespaceSensitivity: "ignore"（忽略空白敏感性） -->
<span> inline </span>
<div>block</div>
```

**endOfLine 示例：**

| 值     | 行尾符号     | 适用系统           |
| ------ | ------------ | ------------------ |
| `lf`   | `\n`         | Linux、macOS       |
| `crlf` | `\r\n`       | Windows            |
| `cr`   | `\r`         | 旧版 macOS（罕见） |
| `auto` | 保留文件原有 | 混合环境           |

```json
{
  "endOfLine": "lf"
}
```

> **提示**：推荐使用 `"lf"`，配合 Git 的 `core.autocrlf` 设置处理跨平台问题。

**singleAttributePerLine 示例：**

```html
<!-- singleAttributePerLine: false（默认） -->
<div data-a="1" data-b="2" data-c="3">content</div>

<!-- singleAttributePerLine: true -->
<div
  data-a="1"
  data-b="2"
  data-c="3">
  content
</div>
```

### 3.5 配置选项速查表

| 选项                         | 默认值      | CLI 参数                         | 说明           |
| ---------------------------- | ----------- | -------------------------------- | -------------- |
| `printWidth`                 | 80          | `--print-width <int>`            | 行宽           |
| `tabWidth`                   | 2           | `--tab-width <int>`              | Tab 宽度       |
| `useTabs`                    | false       | `--use-tabs`                     | 使用 Tab       |
| `semi`                       | true        | `--no-semi`                      | 分号           |
| `singleQuote`                | false       | `--single-quote`                 | 单引号         |
| `jsxSingleQuote`             | false       | `--jsx-single-quote`             | JSX 单引号     |
| `quoteProps`                 | "as-needed" | `--quote-props <as-needed\|...>` | 属性引号       |
| `trailingComma`              | "all"       | `--trailing-comma <all\|...>`    | 尾随逗号       |
| `bracketSpacing`             | true        | `--no-bracket-spacing`           | 括号空格       |
| `bracketSameLine`            | false       | `--bracket-same-line`            | 括号同行       |
| `arrowParens`                | "always"    | `--arrow-parens <always\|avoid>` | 箭头函数括号   |
| `proseWrap`                  | "preserve"  | `--prose-wrap <preserve\|...>`   | Markdown 换行  |
| `htmlWhitespaceSensitivity`  | "css"       | `--html-whitespace-sensitivity`  | HTML 空白      |
| `endOfLine`                  | "lf"        | `--end-of-line <lf\|crlf\|...>`  | 行尾符号       |
| `singleAttributePerLine`     | false       | `--single-attribute-per-line`    | 单属性一行     |
| `embeddedLanguageFormatting` | "auto"      | `--embedded-language-formatting` | 嵌入代码格式化 |
| `experimentalTernaries`      | false       | `--experimental-ternaries`       | 实验性三元格式 |

## 4. 配置作用域

了解了配置选项后，接下来需要理解这些配置在哪里生效——Prettier 支持全局、项目、目录等多个层级的配置。

### 4.1 全局配置

全局配置位于用户主目录，作为所有项目的默认配置。

**配置文件位置：**

| 系统    | 路径                        |
| ------- | --------------------------- |
| macOS   | `~/.prettierrc`             |
| Linux   | `~/.prettierrc`             |
| Windows | `%USERPROFILE%\.prettierrc` |

**示例：**

```bash
# 创建全局配置
echo '{"singleQuote": true, "semi": false}' > ~/.prettierrc
```

> **注意**：项目级配置优先于全局配置。全局配置主要用于个人习惯的默认值。

### 4.2 目录级配置

子目录可以有自己的配置文件，覆盖父目录的配置。

```
project/
├── .prettierrc              # 项目默认配置
│   {
│     "semi": true,
│     "singleQuote": true
│   }
├── src/
│   └── index.js             # 使用项目配置
├── legacy/
│   ├── .prettierrc          # legacy 目录配置
│   │   {
│   │     "semi": false,     # 覆盖项目配置
│   │     "printWidth": 120
│   │   }
│   └── old-code.js          # 使用 legacy 配置
└── tests/
    └── test.js              # 使用项目配置
```

**配置继承规则：**

- 子目录配置**完全覆盖**父目录配置，不是合并
- 如果需要「继承 + 覆盖」，考虑使用 `overrides`

### 4.3 overrides 文件级覆盖

`overrides` 允许为特定文件或目录设置不同的配置，是最灵活的配置方式。

**基本语法：**

```json
{
  "semi": true,
  "overrides": [
    {
      "files": "*.test.js",
      "options": {
        "semi": false
      }
    }
  ]
}
```

**files 支持的模式：**

| 模式               | 说明                    |
| ------------------ | ----------------------- |
| `"*.js"`           | 所有 .js 文件           |
| `"**/*.js"`        | 递归匹配所有 .js 文件   |
| `"*.{js,jsx}"`     | .js 和 .jsx 文件        |
| `"src/**/*.ts"`    | src 目录下所有 .ts 文件 |
| `"legacy/**/*"`    | legacy 目录下所有文件   |
| `["*.js", "*.ts"]` | 数组形式，匹配多种模式  |

**完整示例：**

```json
{
  "printWidth": 80,
  "semi": true,
  "singleQuote": true,

  "overrides": [
    {
      "files": "*.test.{js,ts}",
      "options": {
        "printWidth": 120
      }
    },
    {
      "files": ["*.json", "*.jsonc"],
      "options": {
        "parser": "json",
        "trailingComma": "none"
      }
    },
    {
      "files": "*.md",
      "options": {
        "proseWrap": "always",
        "printWidth": 100
      }
    },
    {
      "files": "legacy/**/*.js",
      "options": {
        "tabWidth": 4,
        "printWidth": 120
      }
    },
    {
      "files": ".prettierrc",
      "options": {
        "parser": "json"
      }
    }
  ]
}
```

**指定解析器：**

某些文件 Prettier 无法自动识别类型，需要手动指定 `parser`。

```json
{
  "overrides": [
    {
      "files": ".babelrc",
      "options": { "parser": "json" }
    },
    {
      "files": "*.svg",
      "options": { "parser": "html" }
    },
    {
      "files": "*.wxss",
      "options": { "parser": "css" }
    }
  ]
}
```

## 5. .prettierignore

### 5.1 语法规则

`.prettierignore` 用于指定不需要格式化的文件和目录，语法与 `.gitignore` 相同。

**基本规则：**

```bash
# 这是注释

# 忽略整个目录
node_modules/
dist/
build/
coverage/

# 忽略特定文件
package-lock.json
pnpm-lock.yaml
yarn.lock

# 忽略特定扩展名
*.min.js
*.min.css

# 通配符
**/*.snap
**/fixtures/**
```

**常用语法：**

| 模式            | 说明                        |
| --------------- | --------------------------- |
| `#`             | 注释                        |
| `file.txt`      | 忽略任意位置的 file.txt     |
| `/file.txt`     | 仅忽略根目录的 file.txt     |
| `dir/`          | 忽略目录                    |
| `*.log`         | 忽略所有 .log 文件          |
| `**/*.test.js`  | 递归忽略所有 .test.js 文件  |
| `!important.js` | 不忽略 important.js（取反） |

### 5.2 与 .gitignore 的异同

| 特性            | .prettierignore     | .gitignore     |
| --------------- | ------------------- | -------------- |
| 语法            | gitignore 语法      | gitignore 语法 |
| 用途            | 排除格式化          | 排除版本控制   |
| 默认忽略        | node_modules（v3+） | 无             |
| 继承 .gitignore | 是（自动读取）      | -              |

**Prettier v3 的默认行为：**

Prettier v3 默认忽略以下目录，无需在 `.prettierignore` 中声明：

```
**/.git
**/.svn
**/.hg
**/node_modules
```

> **提示**：使用 `--with-node-modules` 参数可以强制格式化 node_modules 中的文件。

### 5.3 常见忽略模式

**前端项目：**

```bash
# .prettierignore

# 构建产物
dist/
build/
.next/
.nuxt/
out/

# 依赖
node_modules/

# 锁文件
package-lock.json
pnpm-lock.yaml
yarn.lock

# 缓存
.cache/
*.tsbuildinfo

# 压缩文件
*.min.js
*.min.css

# 自动生成的文件
*.generated.*
src/graphql/generated/

# 测试覆盖率
coverage/

# IDE
.idea/
.vscode/
```

**Monorepo 项目：**

```bash
# .prettierignore

# 全局忽略
**/node_modules/
**/dist/
**/build/
**/coverage/

# 锁文件
pnpm-lock.yaml
yarn.lock
package-lock.json

# 特定包的忽略
packages/legacy/**
apps/old-app/**

# 自动生成
**/generated/
**/*.generated.*
```

## 6. 实战配置示例

前面介绍了配置文件的格式、选项和作用域，本节将这些知识整合为可直接使用的配置模板。

### 6.1 前端项目配置

适用于 React/Vue/Angular 等前端项目。

**`.prettierrc.json`：**

```json
{
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false,
  "semi": true,
  "singleQuote": true,
  "jsxSingleQuote": false,
  "trailingComma": "es5",
  "bracketSpacing": true,
  "bracketSameLine": false,
  "arrowParens": "avoid",
  "endOfLine": "lf",
  "overrides": [
    {
      "files": "*.json",
      "options": {
        "trailingComma": "none"
      }
    },
    {
      "files": "*.md",
      "options": {
        "proseWrap": "preserve"
      }
    }
  ]
}
```

**`.prettierignore`：**

```bash
dist/
build/
coverage/
node_modules/
*.min.js
*.min.css
package-lock.json
```

### 6.2 全栈项目配置

适用于 Node.js 后端 + 前端的全栈项目。

**`prettier.config.js`：**

```javascript
// prettier.config.js
/** @type {import("prettier").Config} */
export default {
  // 基础配置
  printWidth: 100,
  tabWidth: 2,
  useTabs: false,
  semi: true,
  singleQuote: true,
  trailingComma: "es5",
  bracketSpacing: true,
  arrowParens: "avoid",
  endOfLine: "lf",

  // 插件
  plugins: ["prettier-plugin-tailwindcss"],

  // 针对不同文件类型的配置
  overrides: [
    // 前端代码
    {
      files: ["src/client/**/*.{js,jsx,ts,tsx}"],
      options: {
        printWidth: 80,
        jsxSingleQuote: false,
      },
    },
    // 后端代码
    {
      files: ["src/server/**/*.{js,ts}"],
      options: {
        printWidth: 120,
      },
    },
    // 测试文件
    {
      files: ["**/*.test.{js,ts}", "**/*.spec.{js,ts}"],
      options: {
        printWidth: 120,
      },
    },
    // JSON 配置文件
    {
      files: ["*.json", ".prettierrc"],
      options: {
        parser: "json",
        trailingComma: "none",
      },
    },
    // Markdown 文档
    {
      files: "*.md",
      options: {
        proseWrap: "always",
        printWidth: 80,
      },
    },
  ],
};
```

**`.prettierignore`：**

```bash
# 构建产物
dist/
build/
.next/

# 依赖
node_modules/

# 数据库
*.sqlite
*.db

# 日志
logs/
*.log

# 环境配置
.env*

# 锁文件
package-lock.json
pnpm-lock.yaml

# 自动生成
src/generated/
prisma/generated/
```

### 6.3 Monorepo 配置

适用于使用 pnpm/Yarn/Lerna 的 Monorepo 项目。

**项目结构：**

```
monorepo/
├── .prettierrc.js           # 根配置
├── .prettierignore          # 根忽略文件
├── packages/
│   ├── ui/                  # UI 组件库
│   │   └── .prettierrc.js   # 可选：包级配置
│   ├── utils/               # 工具库
│   └── eslint-config/       # ESLint 配置
├── apps/
│   ├── web/                 # Web 应用
│   └── docs/                # 文档站点
└── package.json
```

**根目录 `.prettierrc.js`：**

```javascript
// .prettierrc.js
/** @type {import("prettier").Config} */
export default {
  // 通用配置
  printWidth: 100,
  tabWidth: 2,
  useTabs: false,
  semi: true,
  singleQuote: true,
  trailingComma: "es5",
  bracketSpacing: true,
  arrowParens: "avoid",
  endOfLine: "lf",

  // Monorepo 特定配置
  overrides: [
    // UI 组件库
    {
      files: "packages/ui/**/*.{js,jsx,ts,tsx}",
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
    // 配置文件
    {
      files: [
        "*.config.{js,ts,mjs,cjs}",
        ".prettierrc.js",
        "packages/eslint-config/**/*.js",
      ],
      options: {
        printWidth: 120,
      },
    },
    // JSON 文件
    {
      files: ["*.json", "**/package.json"],
      options: {
        trailingComma: "none",
      },
    },
  ],
};
```

**根目录 `.prettierignore`：**

```bash
# 构建产物
**/dist/
**/build/
**/.next/
**/out/

# 依赖
**/node_modules/

# 锁文件
pnpm-lock.yaml

# 缓存
**/.turbo/
**/.cache/
*.tsbuildinfo

# 自动生成
**/generated/
**/coverage/

# 特殊目录
packages/legacy/
```

**包级配置（可选）：**

如果某个包需要完全不同的配置，可以在包目录下创建独立的配置文件。

```javascript
// packages/legacy/.prettierrc.js
// 旧代码使用不同的风格

/** @type {import("prettier").Config} */
export default {
  printWidth: 120,
  tabWidth: 4,
  semi: false,
  singleQuote: false,
};
```

## 7. 总结

### 7.1 核心要点回顾

| 要点            | 说明                                      |
| --------------- | ----------------------------------------- |
| 配置优先级      | CLI > 配置文件 > 编辑器 > 默认值          |
| 配置格式选择    | 简单项目用 JSON，复杂项目用 JavaScript    |
| overrides       | 为特定文件类型设置不同配置的最佳方式      |
| .prettierignore | 使用 gitignore 语法排除不需要格式化的文件 |
| 配置继承        | 子目录配置完全覆盖父目录，非合并          |

### 7.2 推荐配置

**适合大多数项目的配置：**

```json
{
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false,
  "semi": true,
  "singleQuote": true,
  "trailingComma": "es5",
  "bracketSpacing": true,
  "arrowParens": "avoid",
  "endOfLine": "lf"
}
```

### 7.3 配置检查清单

| 检查项          | 建议                         |
| --------------- | ---------------------------- |
| 配置文件位置    | 项目根目录                   |
| 配置文件数量    | 一个项目一个配置文件         |
| overrides 使用  | 用于不同文件类型的差异化配置 |
| .prettierignore | 排除构建产物、依赖、锁文件   |
| 与团队协商      | 配置应得到团队一致同意       |
| 版本控制        | 配置文件应提交到 Git         |

> **下一步**：了解了配置方法后，建议阅读 [Prettier 编辑器集成指南](./prettier-4-editor-integration.md) 学习如何在编辑器中使用 Prettier，或阅读 [Prettier 工具链整合指南](./prettier-5-toolchain.md) 了解如何与 ESLint、Git Hooks 等工具配合使用。

## 参考资源

- [Prettier Configuration](https://prettier.io/docs/en/configuration)
- [Prettier Options](https://prettier.io/docs/en/options)
- [Prettier Ignoring Code](https://prettier.io/docs/en/ignore)
- [Prettier CLI](https://prettier.io/docs/en/cli)
- [Prettier 基础概念与原理](./prettier-1-fundamentals.md)
