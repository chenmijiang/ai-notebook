# Prettier 高级用法与疑难解决

## 1. 概述

### 1.1 CLI 命令总览

Prettier CLI 是核心命令行工具，提供格式化、检查、调试等多种功能。

**命令基本语法：**

```bash
prettier [options] [file/dir/glob ...]
```

**核心命令分类：**

| 类别       | 命令/选项                         | 说明                             |
| ---------- | --------------------------------- | -------------------------------- |
| 格式化操作 | `--write`                         | 格式化并写入文件                 |
| 格式化操作 | `--check`                         | 检查文件是否已格式化             |
| 格式化操作 | `--list-different`                | 列出需要格式化的文件             |
| 调试工具   | `--debug-check`                   | 检查格式化是否改变代码语义       |
| 调试工具   | `--find-config-path`              | 查找配置文件路径                 |
| 调试工具   | `--file-info`                     | 获取文件解析信息                 |
| 性能优化   | `--cache`                         | 启用缓存，只处理变更文件         |
| 性能优化   | `--cache-location`                | 指定缓存文件位置                 |
| 性能优化   | `--cache-strategy`                | 设置缓存策略（metadata/content） |
| 配置相关   | `--config`                        | 指定配置文件路径                 |
| 配置相关   | `--no-config`                     | 禁用配置文件                     |
| 配置相关   | `--config-precedence`             | 配置优先级设置                   |
| 输出控制   | `--log-level`                     | 设置日志级别                     |
| 输出控制   | `--no-error-on-unmatched-pattern` | 忽略无匹配文件的错误             |

**常用命令示例：**

```bash
# 格式化当前目录所有支持的文件
npx prettier --write .

# 检查文件是否符合格式规范（CI 常用）
npx prettier --check "src/**/*.{js,ts,jsx,tsx}"

# 列出需要格式化的文件（不执行格式化）
npx prettier --list-different .

# 使用指定配置文件格式化
npx prettier --write --config .prettierrc.prod.json src/

# 格式化并启用缓存
npx prettier --write --cache .
```

### 1.2 调试工具介绍

当 Prettier 的行为与预期不符时，调试工具能帮助快速定位问题。

**调试工具速览：**

| 工具                 | 用途                       | 典型场景                 |
| -------------------- | -------------------------- | ------------------------ |
| `--debug-check`      | 检测格式化是否改变代码语义 | 排查格式化后代码行为异常 |
| `--find-config-path` | 查找实际使用的配置文件     | 排查配置未生效问题       |
| `--file-info`        | 获取文件的解析器和忽略状态 | 排查文件未被格式化问题   |
| `--log-level`        | 调整日志输出详细程度       | 获取更多运行时信息       |

**调试思维流程：**

```
问题出现
    │
    ├── 格式化结果不对 ──→ 检查配置 ──→ --find-config-path
    │
    ├── 文件未被处理 ──→ 检查忽略/解析器 ──→ --file-info
    │
    ├── 格式化后代码异常 ──→ 检查语义 ──→ --debug-check
    │
    └── 需要更多信息 ──→ 提升日志级别 ──→ --log-level debug
```

## 2. 调试技巧

### 2.1 --debug-check

`--debug-check` 用于检测 Prettier 格式化是否意外改变了代码的语义或行为。

**工作原理：**

```
原始代码 ──→ Prettier 格式化 ──→ 格式化后代码
    │                               │
    ↓                               ↓
  AST 解析                       AST 解析
    │                               │
    ↓                               ↓
  AST 结构 ────── 对比 ────── AST 结构
                   │
                   ↓
           相同？通过 : 报错
```

**基本用法：**

```bash
# 检查单个文件
npx prettier --debug-check src/index.js

# 检查整个项目
npx prettier --debug-check "src/**/*.js"
```

**输出解读：**

| 输出情况                 | 含义                       |
| ------------------------ | -------------------------- |
| 无输出，退出码 0         | 格式化未改变代码语义，安全 |
| 输出差异信息，退出码非 0 | 检测到潜在问题，需要关注   |

**实际示例：**

```bash
# 正常情况（无输出表示安全）
$ npx prettier --debug-check src/utils.js
$

# 发现问题时的输出
$ npx prettier --debug-check src/edge-case.js
src/edge-case.js
Code changed after formatting.
```

**使用场景：**

| 场景                     | 说明                         |
| ------------------------ | ---------------------------- |
| CI 流水线检查            | 确保格式化不破坏代码逻辑     |
| 升级 Prettier 版本前     | 检测新版本是否引入破坏性变化 |
| 格式化遗留代码前         | 确认格式化安全性             |
| 排查格式化后的运行时错误 | 定位是否由格式化引起         |

> **注意**：`--debug-check` 不能与 `--write` 同时使用。它只进行检查，不修改文件。

### 2.2 --find-config-path

`--find-config-path` 帮助确定 Prettier 实际使用的配置文件路径。

**基本用法：**

```bash
# 查找指定文件使用的配置
npx prettier --find-config-path src/index.js
```

**输出示例：**

```bash
$ npx prettier --find-config-path src/index.js
/project/.prettierrc.json

$ npx prettier --find-config-path src/components/Button.tsx
/project/src/components/.prettierrc
```

**配置查找顺序：**

Prettier 从目标文件所在目录向上查找，直到找到配置文件或到达根目录。

```
src/components/Button.tsx
    │
    ├── src/components/.prettierrc    ← 先查找
    ├── src/.prettierrc               ← 再查找
    ├── .prettierrc                   ← 继续查找
    └── package.json (prettier 字段)  ← 最后查找
```

**排查配置不生效的步骤：**

```bash
# 1. 确认配置文件路径
npx prettier --find-config-path src/index.js

# 2. 如果路径不对，检查配置文件名是否正确
ls -la .prettier*

# 3. 使用指定配置文件验证
npx prettier --config .prettierrc.json --write src/index.js
```

**常见问题与解决：**

| 问题                   | 原因             | 解决方案               |
| ---------------------- | ---------------- | ---------------------- |
| 输出为空               | 未找到配置文件   | 创建配置文件           |
| 配置文件路径不是预期的 | 存在多个配置文件 | 删除多余配置或合并     |
| 子目录配置覆盖了根配置 | 子目录有独立配置 | 检查是否需要子目录配置 |

### 2.3 --file-info

`--file-info` 获取文件的详细解析信息，帮助理解 Prettier 如何处理特定文件。

**基本用法：**

```bash
npx prettier --file-info src/index.ts
```

**输出示例：**

```json
{
  "ignored": false,
  "inferredParser": "typescript"
}
```

**输出字段说明：**

| 字段             | 类型           | 说明                            |
| ---------------- | -------------- | ------------------------------- |
| `ignored`        | boolean        | 文件是否被 .prettierignore 忽略 |
| `inferredParser` | string \| null | Prettier 推断的解析器           |

**常见解析器：**

| 解析器       | 适用文件类型           |
| ------------ | ---------------------- |
| `babel`      | JavaScript (.js)       |
| `typescript` | TypeScript (.ts, .tsx) |
| `css`        | CSS (.css)             |
| `scss`       | SCSS (.scss)           |
| `json`       | JSON (.json)           |
| `markdown`   | Markdown (.md)         |
| `html`       | HTML (.html)           |
| `yaml`       | YAML (.yml, .yaml)     |
| `graphql`    | GraphQL (.graphql)     |

**排查文件未被格式化：**

```bash
# 1. 检查文件信息
$ npx prettier --file-info dist/bundle.js
{
  "ignored": true,
  "inferredParser": "babel"
}
# ignored: true 说明文件被忽略

# 2. 检查 .prettierignore 配置
$ cat .prettierignore
dist/

# 3. 如果 inferredParser 为 null，说明 Prettier 不识别该文件类型
$ npx prettier --file-info src/config.custom
{
  "ignored": false,
  "inferredParser": null
}
# 需要在配置中指定解析器覆盖
```

**API 方式调用：**

```javascript
import * as prettier from "prettier";

// 获取文件信息
const fileInfo = await prettier.getFileInfo("src/index.ts");
console.log(fileInfo);
// { ignored: false, inferredParser: "typescript" }

// 带忽略文件配置
const info = await prettier.getFileInfo("dist/bundle.js", {
  ignorePath: ".prettierignore",
});
console.log(info.ignored); // true
```

### 2.4 调试流程图

当遇到 Prettier 相关问题时，可按照以下流程进行排查。

**问题诊断流程：**

```
┌──────────────────────────────────────────────────────────┐
│                    问题发生                               │
└──────────────────────────────────────────────────────────┘
                           │
                           ↓
┌──────────────────────────────────────────────────────────┐
│  问题类型是什么？                                         │
└──────────────────────────────────────────────────────────┘
        │              │              │              │
        ↓              ↓              ↓              ↓
   配置不生效      文件被跳过     结果不一致     性能问题
        │              │              │              │
        ↓              ↓              ↓              ↓
 --find-config-path  --file-info   检查版本      --cache
        │              │              │              │
        ↓              ↓              ↓              ↓
  检查配置文件     检查 ignored   统一版本号    分析缓存
  位置和内容       和 parser      和配置
```

**完整排查示例：**

```bash
# 场景：src/utils/helper.ts 格式化不生效

# Step 1: 检查文件是否被忽略
$ npx prettier --file-info src/utils/helper.ts
{
  "ignored": false,
  "inferredParser": "typescript"
}
# 结果：未被忽略，解析器正确

# Step 2: 检查使用的配置文件
$ npx prettier --find-config-path src/utils/helper.ts
/project/.prettierrc.json
# 结果：配置文件路径正确

# Step 3: 查看配置文件内容
$ cat /project/.prettierrc.json
{
  "singleQuote": true,
  "semi": false
}
# 结果：配置内容符合预期

# Step 4: 验证 Prettier 版本
$ npx prettier --version
3.2.5
# 结果：版本正确

# Step 5: 直接格式化测试
$ npx prettier --write src/utils/helper.ts
src/utils/helper.ts 23ms
# 结果：格式化成功

# 结论：可能是编辑器插件配置问题，检查 VS Code 设置
```

## 3. 常见问题排查

### 3.1 格式化结果不一致

**症状描述：**

| 症状                 | 可能原因            |
| -------------------- | ------------------- |
| 本地和 CI 结果不同   | Prettier 版本不一致 |
| 团队成员结果不同     | 配置文件不同步      |
| 保存后又变回原样     | 多个格式化工具冲突  |
| 每次格式化结果都不同 | 配置有随机性因素    |

**排查步骤：**

```bash
# 1. 确认 Prettier 版本
npx prettier --version
# 对比 CI 环境和本地环境的版本

# 2. 确认配置文件一致性
npx prettier --find-config-path src/index.js
# 检查团队成员是否使用相同配置

# 3. 检查是否有多个格式化工具
# 查看 package.json 中的相关依赖
cat package.json | grep -E "prettier|eslint|beautify"

# 4. 验证格式化结果
npx prettier --check src/index.js
```

**版本不一致的解决方案：**

```bash
# 方案一：使用 npm ci 确保版本一致
npm ci

# 方案二：检查全局安装是否干扰
npm list -g prettier
# 如果有全局安装，卸载它
npm uninstall -g prettier

# 方案三：CI 中明确使用项目版本
# .github/workflows/ci.yml
# - run: npx prettier --check .  # 使用项目本地版本
```

**配置冲突的解决方案：**

```javascript
// .eslintrc.js
// 确保 ESLint 不与 Prettier 冲突
module.exports = {
  extends: [
    "eslint:recommended",
    "prettier", // 必须放在最后，禁用冲突规则
  ],
};
```

### 3.2 文件未被格式化

**常见原因及检查方法：**

| 原因                 | 检查命令                          | 解决方案             |
| -------------------- | --------------------------------- | -------------------- |
| 文件被 ignore        | `npx prettier --file-info <file>` | 修改 .prettierignore |
| 解析器未识别         | `npx prettier --file-info <file>` | 配置 parser 覆盖     |
| glob 模式不匹配      | 检查命令中的 glob 模式            | 修正 glob 模式       |
| 文件路径包含特殊字符 | 尝试用引号包裹路径                | 使用引号包裹         |

**详细排查示例：**

```bash
# 问题：src/config.mjs 没有被格式化

# 检查 1：文件信息
$ npx prettier --file-info src/config.mjs
{
  "ignored": false,
  "inferredParser": "babel"
}
# 结果：未被忽略，解析器正确

# 检查 2：glob 模式是否包含 .mjs
$ npx prettier --check "src/**/*.js"
# .mjs 不会被 *.js 匹配

# 解决：修正 glob 模式
$ npx prettier --check "src/**/*.{js,mjs,cjs}"
```

**配置解析器覆盖：**

```json
// .prettierrc
{
  "overrides": [
    {
      "files": "*.custom",
      "options": {
        "parser": "babel"
      }
    },
    {
      "files": ["*.config.js", "*.config.mjs"],
      "options": {
        "printWidth": 120
      }
    }
  ]
}
```

### 3.3 与 ESLint 冲突

**冲突表现：**

| 表现                 | 原因                          |
| -------------------- | ----------------------------- |
| ESLint 报格式错误    | ESLint 规则与 Prettier 冲突   |
| 保存后反复修改       | ESLint --fix 和 Prettier 循环 |
| 两个工具给出不同建议 | 配置不协调                    |

**正确的集成方式：**

```bash
# 安装协调包
npm install --save-dev eslint-config-prettier
```

```javascript
// .eslintrc.js
// eslint-config-prettier 必须放在 extends 数组最后
module.exports = {
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "prettier", // 放在最后，关闭与 Prettier 冲突的规则
  ],
  rules: {
    // 不要配置任何格式化相关的规则
    // ❌ "indent": ["error", 2],
    // ❌ "quotes": ["error", "single"],
    // ❌ "semi": ["error", "never"],
  },
};
```

**检测冲突规则：**

```bash
# 使用 eslint-config-prettier 提供的检查工具
npx eslint-config-prettier src/index.js
```

**lint-staged 正确配置：**

```javascript
// lint-staged.config.js
// 正确顺序：先 ESLint 检查，再 Prettier 格式化
export default {
  "*.{js,ts,jsx,tsx}": [
    "eslint --fix", // 先修复代码质量问题
    "prettier --write", // 再格式化
  ],
};
```

### 3.4 编辑器与 CLI 结果不同

**常见原因：**

| 原因                    | 说明                           |
| ----------------------- | ------------------------------ |
| 编辑器使用内置 Prettier | 编辑器插件自带的 Prettier 版本 |
| 插件配置覆盖            | VS Code 设置覆盖了项目配置     |
| 扩展冲突                | 多个格式化扩展同时启用         |
| 工作区设置不同          | 多根工作区有不同设置           |

**VS Code 正确配置：**

```json
// .vscode/settings.json
{
  // 指定使用项目本地的 Prettier
  "prettier.prettierPath": "./node_modules/prettier",

  // 确保 Prettier 是默认格式化器
  "editor.defaultFormatter": "esbenp.prettier-vscode",

  // 针对特定语言的格式化器
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[json]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },

  // 保存时格式化
  "editor.formatOnSave": true,

  // 禁用其他格式化器
  "editor.formatOnType": false,

  // 使用项目配置
  "prettier.useEditorConfig": true,
  "prettier.requireConfig": true
}
```

**诊断步骤：**

```bash
# 1. 在 VS Code 中打开 Output 面板
# View → Output → 选择 "Prettier"

# 2. 查看 Prettier 输出日志
# 日志会显示使用的 Prettier 版本和配置文件

# 3. 对比 CLI 和编辑器的版本
npx prettier --version    # CLI 版本

# 4. 在 VS Code 命令面板运行
# "Prettier: Show Output" 查看编辑器使用的版本
```

**确保一致性的最佳实践：**

```json
// .vscode/settings.json（提交到仓库）
{
  "prettier.prettierPath": "./node_modules/prettier",
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.formatOnSave": true
}
```

```json
// .vscode/extensions.json（推荐安装的扩展）
{
  "recommendations": ["esbenp.prettier-vscode"]
}
```

## 4. 性能优化

### 4.1 --cache 选项

`--cache` 选项通过缓存机制显著提升格式化性能，只处理有变更的文件。

**基本用法：**

```bash
# 启用缓存
npx prettier --write --cache .

# 首次运行（处理所有文件）
$ npx prettier --write --cache .
src/index.js 45ms
src/utils.js 32ms
src/components/Button.tsx 28ms
...
Done in 2.5s

# 第二次运行（只处理变更文件）
$ npx prettier --write --cache .
Done in 0.1s
```

**缓存工作原理：**

| 缓存键组成      | 说明                     |
| --------------- | ------------------------ |
| Prettier 版本   | 版本变化时缓存失效       |
| Prettier 选项   | 配置变化时缓存失效       |
| Node.js 版本    | Node 版本变化时缓存失效  |
| 文件内容/元数据 | 文件变化时该文件缓存失效 |

**缓存策略选项：**

```bash
# 基于文件内容判断变化（默认，更准确）
npx prettier --write --cache --cache-strategy content .

# 基于文件元数据判断变化（更快，可能有误判）
npx prettier --write --cache --cache-strategy metadata .
```

| 策略       | 判断依据     | 优点 | 缺点             |
| ---------- | ------------ | ---- | ---------------- |
| `content`  | 文件内容哈希 | 准确 | 需要读取文件内容 |
| `metadata` | mtime/size   | 更快 | 可能误判         |

**自定义缓存位置：**

```bash
# 默认缓存位置：./node_modules/.cache/prettier/.prettier-cache

# 自定义缓存位置
npx prettier --write --cache --cache-location .cache/prettier .

# CI 环境中持久化缓存
# GitHub Actions 示例
```

```yaml
# .github/workflows/ci.yml
- name: Cache Prettier
  uses: actions/cache@v3
  with:
    path: node_modules/.cache/prettier
    key: prettier-${{ hashFiles('**/package-lock.json') }}

- name: Format check with cache
  run: npx prettier --check --cache .
```

**清除缓存：**

```bash
# 方法一：删除缓存文件
rm -rf node_modules/.cache/prettier

# 方法二：不使用缓存运行
npx prettier --write .  # 不带 --cache 参数
```

### 4.2 大型项目策略

**策略一：分批处理**

```bash
# 按目录分批格式化
npx prettier --write --cache "src/core/**/*"
npx prettier --write --cache "src/features/**/*"
npx prettier --write --cache "src/utils/**/*"
```

**策略二：合理配置 .prettierignore**

```
# .prettierignore
# 排除不需要格式化的大型目录
dist/
build/
node_modules/
coverage/

# 排除生成的文件
*.generated.ts
*.min.js

# 排除大型数据文件
**/*.json  # 如果项目有大量 JSON 数据文件
!package.json
!tsconfig.json
```

**策略三：CI 优化**

```yaml
# .github/workflows/ci.yml
jobs:
  format-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      # 缓存 Prettier 处理结果
      - name: Cache Prettier
        uses: actions/cache@v3
        with:
          path: node_modules/.cache/prettier
          key: prettier-${{ runner.os }}-${{ hashFiles('**/*.{js,ts,jsx,tsx,json,md}') }}
          restore-keys: |
            prettier-${{ runner.os }}-

      - run: npm ci

      # 使用缓存进行检查
      - run: npx prettier --check --cache .
```

**策略四：增量检查（仅检查变更文件）**

```bash
# 只检查相对于 main 分支的变更文件
git diff --name-only main...HEAD | xargs npx prettier --check

# lint-staged 自动只处理暂存文件
# 配置 lint-staged
```

```javascript
// lint-staged.config.js
export default {
  "*.{js,ts,jsx,tsx,json,md,css,scss}": "prettier --write",
};
```

### 4.3 并行处理

Prettier 内部已实现并行处理，大多数情况无需额外配置。

**内置并行机制：**

```bash
# Prettier 会自动利用多核 CPU 并行处理文件
npx prettier --write .
# 内部自动分配文件到多个工作线程
```

**外部并行优化（特殊场景）：**

```bash
# 使用 GNU parallel 进行极大型项目
find src -name "*.js" | parallel -j4 npx prettier --write {}

# 注意：这种方式会失去缓存优势，一般不推荐
```

**性能监控：**

```bash
# 测量格式化耗时
time npx prettier --write --cache .

# 查看处理文件数量
npx prettier --write --cache . 2>&1 | wc -l

# 详细日志模式
npx prettier --write --cache --log-level debug .
```

**性能对比参考：**

| 场景                   | 无缓存 | 有缓存（首次） | 有缓存（后续） |
| ---------------------- | ------ | -------------- | -------------- |
| 1000 文件项目          | ~5s    | ~5s            | ~0.2s          |
| 10000 文件项目         | ~30s   | ~30s           | ~0.5s          |
| 带 node_modules 的检查 | 非常慢 | N/A            | N/A            |

## 5. Prettier 的局限

### 5.1 不能做什么

Prettier 是代码格式化工具，有明确的边界和局限。

**Prettier 不做的事情：**

| 类别         | 具体内容                 | 替代工具             |
| ------------ | ------------------------ | -------------------- |
| 代码质量检查 | 未使用变量、类型错误     | ESLint、TypeScript   |
| 代码逻辑分析 | 复杂度检查、循环嵌套深度 | ESLint、SonarQube    |
| Import 排序  | 导入语句排序和分组       | eslint-plugin-import |
| 命名规范     | 变量命名风格检查         | ESLint               |
| 注释格式     | JSDoc 格式校验           | ESLint               |
| 安全检查     | 危险代码模式检测         | ESLint 安全插件      |
| 性能优化建议 | 低效代码模式提示         | ESLint               |

**Prettier 格式化的边界：**

```javascript
// ❌ Prettier 不会改变这些
const unusedVar = 1; // 未使用变量
eval("dangerous"); // 危险代码
var oldStyle = true; // var 声明

// ✅ Prettier 只处理格式
const x = { a: 1, b: 2 }; // → const x = { a: 1, b: 2 };
function f(a, b, c) {} // → function f(a, b, c) {}
```

**常见误解澄清：**

| 误解                        | 事实                       |
| --------------------------- | -------------------------- |
| Prettier 能修复所有代码问题 | Prettier 只处理代码格式    |
| Prettier 会优化代码性能     | Prettier 不改变代码逻辑    |
| Prettier 能排序 import      | 需要额外插件或 ESLint 规则 |
| Prettier 能检查类型         | 需要 TypeScript            |

### 5.2 补充工具推荐

**完整的代码质量工具链：**

| 工具         | 职责               | 与 Prettier 关系     |
| ------------ | ------------------ | -------------------- |
| ESLint       | 代码质量、最佳实践 | 互补，需禁用格式规则 |
| TypeScript   | 类型检查           | 独立，互不影响       |
| Husky        | Git Hooks 管理     | 触发 Prettier 运行   |
| lint-staged  | 暂存文件处理       | 限定 Prettier 范围   |
| commitlint   | 提交信息规范       | 独立，互不影响       |
| EditorConfig | 基础编辑器配置     | Prettier 会读取      |

**Import 排序解决方案：**

```bash
# 方案一：使用 ESLint 插件
npm install --save-dev eslint-plugin-import
```

```javascript
// .eslintrc.js
module.exports = {
  plugins: ["import"],
  rules: {
    "import/order": [
      "error",
      {
        groups: [
          "builtin",
          "external",
          "internal",
          "parent",
          "sibling",
          "index",
        ],
        "newlines-between": "always",
        alphabetize: { order: "asc" },
      },
    ],
  },
};
```

```bash
# 方案二：使用 Prettier 插件
npm install --save-dev @trivago/prettier-plugin-sort-imports
```

```json
// .prettierrc
{
  "plugins": ["@trivago/prettier-plugin-sort-imports"],
  "importOrder": ["^@core/(.*)$", "^@server/(.*)$", "^[./]"],
  "importOrderSeparation": true
}
```

**推荐的工具组合：**

```json
// package.json
{
  "devDependencies": {
    "prettier": "^3.2.0",
    "eslint": "^8.56.0",
    "eslint-config-prettier": "^9.1.0",
    "typescript": "^5.3.0",
    "husky": "^9.0.0",
    "lint-staged": "^15.2.0"
  }
}
```

### 5.3 边界认知

**Prettier 的设计哲学：**

```
Prettier 的目标：
├── 消除代码格式讨论
├── 提供一致的代码风格
└── 让开发者专注于逻辑

Prettier 不追求：
├── 最「漂亮」的格式
├── 满足所有人的偏好
└── 处理代码质量问题
```

**何时不应使用 Prettier：**

| 场景                   | 原因                            | 替代方案             |
| ---------------------- | ------------------------------- | -------------------- |
| 对格式有严格要求的项目 | Prettier 的格式化结果不可自定义 | 手动格式化或 ESLint  |
| 需要保持特定对齐的代码 | Prettier 会重排代码             | 使用 prettier-ignore |
| 极度追求代码紧凑       | Prettier 会添加空格和换行       | 手动控制             |

**接受 Prettier 决定的心态：**

```javascript
// ❌ 纠结于这种差异
// 你想要：
const obj = { a: 1, b: 2 };
// Prettier 输出：
const obj = {
  a: 1,
  b: 2,
};

// ✅ 正确心态：接受工具的决定
// - 风格一致比风格「完美」更重要
// - 省下的讨论时间远超格式差异带来的不便
// - 习惯可以培养，一致性需要强制
```

## 6. FAQ

**Q1: 为什么格式化后代码变得更长了？**

Prettier 的设计目标是可读性而非紧凑性。当代码超过 `printWidth` 时，Prettier 会换行展开。

```javascript
// 格式化前（紧凑但超过 printWidth）
const result = await fetchData(endpoint, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(data),
});

// 格式化后（更长但更易读）
const result = await fetchData(endpoint, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(data),
});
```

**调整建议：**

| 方案               | 配置                         | 效果         |
| ------------------ | ---------------------------- | ------------ |
| 增加行宽           | `"printWidth": 100` 或 `120` | 减少换行     |
| 接受 Prettier 决定 | 保持默认                     | 一致性优先   |
| 特殊情况禁用       | `// prettier-ignore`         | 保持原有格式 |

**Q2: 如何让 Prettier 排序 import？**

Prettier 核心不支持 import 排序，需要使用插件或 ESLint。

**方案一：使用 Prettier 插件**

```bash
npm install --save-dev @trivago/prettier-plugin-sort-imports
```

```json
// .prettierrc
{
  "plugins": ["@trivago/prettier-plugin-sort-imports"],
  "importOrder": ["^react", "^@?\\w", "^@/(.*)$", "^[./]"],
  "importOrderSeparation": true,
  "importOrderSortSpecifiers": true
}
```

**方案二：使用 ESLint**

```javascript
// .eslintrc.js
module.exports = {
  plugins: ["import"],
  rules: {
    "import/order": [
      "error",
      {
        groups: ["builtin", "external", "internal", "parent", "sibling"],
        "newlines-between": "always",
        alphabetize: { order: "asc" },
      },
    ],
  },
};
```

**Q3: 为什么某些文件被跳过了？**

文件被跳过通常有以下原因：

| 原因                | 诊断方法                          | 解决方案         |
| ------------------- | --------------------------------- | ---------------- |
| .prettierignore     | `npx prettier --file-info <file>` | 修改忽略配置     |
| 无法识别的文件类型  | 检查 `inferredParser` 是否为 null | 配置 parser 覆盖 |
| glob 模式不匹配     | 检查命令中的 glob                 | 修正 glob 模式   |
| 文件在 node_modules | 默认忽略                          | 无需处理         |

**诊断命令：**

```bash
# 检查文件状态
npx prettier --file-info path/to/file.xyz

# 输出示例
{
  "ignored": true,        # ← 被忽略
  "inferredParser": null  # ← 无法识别类型
}
```

**解决无法识别的文件类型：**

```json
// .prettierrc
{
  "overrides": [
    {
      "files": "*.xyz",
      "options": {
        "parser": "babel"
      }
    }
  ]
}
```

## 7. 总结

### 7.1 CLI 命令速查表

**格式化操作：**

| 命令                          | 说明                   |
| ----------------------------- | ---------------------- |
| `prettier --write .`          | 格式化当前目录所有文件 |
| `prettier --check .`          | 检查文件是否已格式化   |
| `prettier --list-different .` | 列出需要格式化的文件   |

**调试命令：**

| 命令                                 | 说明                   |
| ------------------------------------ | ---------------------- |
| `prettier --find-config-path <file>` | 查找配置文件路径       |
| `prettier --file-info <file>`        | 获取文件解析信息       |
| `prettier --debug-check <file>`      | 检查格式化是否改变语义 |
| `prettier --log-level debug .`       | 启用调试日志           |

**性能选项：**

| 命令                                 | 说明               |
| ------------------------------------ | ------------------ |
| `prettier --write --cache .`         | 启用缓存           |
| `prettier --cache-strategy metadata` | 使用元数据缓存策略 |
| `prettier --cache-location <path>`   | 指定缓存位置       |

**配置选项：**

| 命令                                       | 说明               |
| ------------------------------------------ | ------------------ |
| `prettier --config <path>`                 | 指定配置文件       |
| `prettier --no-config`                     | 禁用配置文件       |
| `prettier --no-error-on-unmatched-pattern` | 忽略无匹配文件错误 |

### 7.2 问题排查清单

**格式化结果不一致：**

| 检查项               | 命令/操作                                |
| -------------------- | ---------------------------------------- |
| Prettier 版本一致    | `npx prettier --version`                 |
| 配置文件一致         | `npx prettier --find-config-path <file>` |
| 无全局 Prettier 干扰 | `npm list -g prettier`                   |
| ESLint 规则不冲突    | 使用 `eslint-config-prettier`            |

**文件未被格式化：**

| 检查项            | 命令/操作                         |
| ----------------- | --------------------------------- |
| 文件是否被忽略    | `npx prettier --file-info <file>` |
| 解析器是否正确    | 检查 `inferredParser` 字段        |
| glob 模式是否正确 | 检查命令中的文件匹配模式          |

**编辑器与 CLI 不一致：**

| 检查项                  | 操作                           |
| ----------------------- | ------------------------------ |
| 编辑器使用项目 Prettier | 配置 `prettier.prettierPath`   |
| 默认格式化器正确        | 配置 `editor.defaultFormatter` |
| 无扩展冲突              | 禁用其他格式化扩展             |

**性能问题：**

| 检查项         | 操作                      |
| -------------- | ------------------------- |
| 启用缓存       | 使用 `--cache` 选项       |
| 排除不必要文件 | 配置 `.prettierignore`    |
| CI 缓存持久化  | 配置 GitHub Actions cache |

## 参考资源

- [Prettier CLI 文档](https://prettier.io/docs/en/cli)
- [Prettier 配置选项](https://prettier.io/docs/en/options)
- [Prettier 忽略代码](https://prettier.io/docs/en/ignore)
- [eslint-config-prettier](https://github.com/prettier/eslint-config-prettier)
- [@trivago/prettier-plugin-sort-imports](https://github.com/trivago/prettier-plugin-sort-imports)
- [Prettier 基础概念与原理](./prettier-fundamentals.md)
- [Prettier 配置完全指南](./prettier-configuration.md)
- [Prettier 编辑器集成指南](./prettier-editor-integration.md)
- [Prettier 工具链整合指南](./prettier-toolchain.md)
- [Prettier 团队协作实践](./prettier-team-practices.md)
