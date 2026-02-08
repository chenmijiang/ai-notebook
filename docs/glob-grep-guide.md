# Glob 与 Grep 完全指南

## 1. 概述

### 1.1 什么是 Glob 和 Grep

**Glob** 是一种文件名模式匹配语法，用于匹配文件路径。它起源于 Unix shell，现已广泛应用于各种编程语言和工具中。

**Grep**（Global Regular Expression Print）是一个强大的文本搜索工具，用于在文件内容中搜索匹配正则表达式的行。

两者的核心区别：

| 特性     | Glob                | Grep                   |
| -------- | ------------------- | ---------------------- |
| 匹配对象 | 文件路径/文件名     | 文件内容               |
| 语法类型 | 通配符模式          | 正则表达式             |
| 使用场景 | 文件选择、路径匹配  | 文本搜索、日志分析     |
| 典型用途 | `ls *.js`、构建配置 | `grep "error" log.txt` |
| 复杂度   | 简单，易于记忆      | 功能强大，学习曲线较陡 |

### 1.2 为什么需要掌握它们

在日常开发中，Glob 和 Grep 是高频使用的工具：

| 场景             | 工具        | 示例                            |
| ---------------- | ----------- | ------------------------------- |
| 配置构建工具     | Glob        | Webpack、Vite 的文件匹配        |
| 设置忽略规则     | Glob        | `.gitignore`、`.prettierignore` |
| 配置 lint-staged | Glob        | `"*.{js,ts}": "eslint --fix"`   |
| 搜索代码         | Grep        | 查找函数定义、API 调用          |
| 分析日志         | Grep        | 过滤错误信息、统计请求          |
| 批量文件操作     | Glob + Grep | 查找包含特定内容的特定类型文件  |

## 2. Glob 模式详解

### 2.1 基础语法

#### 2.1.1 通配符

| 通配符               | 含义                         | 示例            | 匹配结果                     |
| -------------------- | ---------------------------- | --------------- | ---------------------------- |
| `*`                  | 匹配任意数量字符（不含 `/`） | `*.js`          | `app.js`、`index.js`         |
| `**`                 | 匹配任意层级目录             | `src/**/*.js`   | `src/a.js`、`src/utils/b.js` |
| `?`                  | 匹配单个任意字符             | `file?.txt`     | `file1.txt`、`fileA.txt`     |
| `[...]`              | 匹配括号内任一字符           | `file[0-9].js`  | `file0.js`、`file9.js`       |
| `[!...]` 或 `[^...]` | 匹配不在括号内的字符         | `file[!0-9].js` | `fileA.js`、`filex.js`       |

#### 2.1.2 花括号扩展

花括号 `{}` 用于匹配多个选项：

```bash
# 匹配多个扩展名
*.{js,ts,jsx,tsx}
# 匹配：app.js、utils.ts、Button.jsx、App.tsx

# 匹配多个目录
{src,lib}/**/*.js
# 匹配：src/index.js、lib/utils.js

# 组合使用
{package,tsconfig}.json
# 匹配：package.json、tsconfig.json
```

#### 2.1.3 否定模式

使用 `!` 排除特定文件：

```bash
# 排除单个模式
!*.min.js

# 实际配置中的使用（lint-staged）
{
  "*.js": "eslint --fix",
  "!*.min.js": []
}
```

> **注意**：否定模式的行为因工具而异。在某些工具中需要先包含再排除，在其他工具中可以独立使用。

### 2.2 常用模式示例

#### 2.2.1 按文件类型匹配

```bash
# JavaScript/TypeScript 文件
*.{js,jsx,ts,tsx}

# 样式文件
*.{css,scss,less,sass}

# 配置文件
*.{json,yaml,yml,toml}

# 文档文件
*.{md,mdx,txt,rst}

# 图片文件
*.{png,jpg,jpeg,gif,svg,webp}
```

#### 2.2.2 按目录结构匹配

```bash
# 所有目录下的 JS 文件
**/*.js

# src 目录下所有文件
src/**/*

# 特定深度
src/*/*.js         # src 一级子目录的 JS
src/**/*.test.js   # src 下所有测试文件

# 多个目录
{src,lib,packages}/**/*.ts
```

#### 2.2.3 排除模式

```bash
# 排除 node_modules
!node_modules/**

# 排除压缩文件
!**/*.min.js
!**/*.min.css

# 排除构建产物
!dist/**
!build/**

# 排除测试文件
!**/*.test.js
!**/*.spec.js
!**/__tests__/**
```

### 2.3 不同工具中的 Glob 实现

不同工具使用不同的 Glob 库，语法略有差异：

| 工具/库      | 底层实现   | 特点                                    |
| ------------ | ---------- | --------------------------------------- |
| Bash shell   | 内置 glob  | 默认不支持 `**`，需 `shopt -s globstar` |
| Node.js glob | minimatch  | 广泛使用，支持否定模式                  |
| lint-staged  | micromatch | 性能优化，功能丰富                      |
| Prettier     | micromatch | 支持 `.prettierignore`                  |
| ESLint       | minimatch  | 通过配置文件 `ignorePatterns`           |
| .gitignore   | 特殊规则   | 目录匹配需加 `/`，支持 `#` 注释         |

#### 2.3.1 Bash 中的 Glob

```bash
# 启用 ** 支持（bash 4.0+）
shopt -s globstar

# 列出所有 JS 文件
ls **/*.js

# 复制所有图片
cp **/*.{png,jpg} ./images/

# 删除所有日志文件
rm **/*.log
```

#### 2.3.2 micromatch/minimatch 特性

```javascript
// lint-staged.config.js
export default {
  // 基本匹配
  "*.js": "eslint --fix",

  // 否定模式
  "!(*.test).js": "eslint --fix",

  // extglob 模式（micromatch 支持）
  "*.+(js|ts)": "eslint --fix",

  // 否定 extglob
  "!(*test|*spec).js": "eslint --fix"
};
```

**extglob 语法（micromatch 扩展）：**

| 模式         | 含义               | 示例             |
| ------------ | ------------------ | ---------------- |
| `?(pattern)` | 匹配 0 或 1 次     | `file?(s).js`    |
| `*(pattern)` | 匹配 0 或多次      | `file*(s).js`    |
| `+(pattern)` | 匹配 1 或多次      | `file+(s).js`    |
| `@(pattern)` | 精确匹配其中一个   | `@(foo\|bar).js` |
| `!(pattern)` | 匹配除此之外的所有 | `!(test).js`     |

#### 2.3.3 .gitignore 规则

`.gitignore` 有独特的语法规则：

```bash
# 忽略所有 .log 文件
*.log

# 只忽略根目录的 TODO
/TODO

# 忽略 build 目录（注意结尾的 /）
build/

# 忽略 doc 目录下的 .txt，但不忽略 doc/server/arch.txt
doc/*.txt

# 否定模式（不忽略）
!important.log

# 忽略所有目录下的 __pycache__
**/__pycache__/
```

> **提示**：`.gitignore` 中目录需要以 `/` 结尾，否则会同时匹配文件和目录。

### 2.4 实际应用场景

#### 2.4.1 lint-staged 配置

```json
{
  "lint-staged": {
    "*.{js,jsx,ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.{css,scss}": ["stylelint --fix", "prettier --write"],
    "*.{json,md,yml}": "prettier --write",
    "!*.min.{js,css}": []
  }
}
```

#### 2.4.2 Prettier 配置

```json
// .prettierignore
node_modules
dist
build
*.min.js
*.min.css
coverage
.next
```

```javascript
// prettier.config.js
export default {
  overrides: [
    {
      files: "*.md",
      options: { proseWrap: "always" }
    },
    {
      files: ["*.json", "*.jsonc"],
      options: { tabWidth: 2 }
    }
  ]
};
```

#### 2.4.3 TypeScript 配置

```json
// tsconfig.json
{
  "include": ["src/**/*", "types/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}
```

#### 2.4.4 构建工具配置

```javascript
// vite.config.js
export default {
  build: {
    rollupOptions: {
      input: {
        main: "src/main.ts",
        admin: "src/admin.ts"
      }
    }
  },
  // 监听文件变化
  server: {
    watch: {
      ignored: ["**/node_modules/**", "**/dist/**"]
    }
  }
};
```

## 3. Grep 命令详解

### 3.1 基础用法

```bash
grep [选项] 模式 [文件...]
```

**基本示例：**

```bash
# 在文件中搜索
grep "function" app.js

# 在多个文件中搜索
grep "TODO" *.js

# 递归搜索目录
grep -r "import" src/

# 从标准输入搜索
cat log.txt | grep "error"
```

### 3.2 常用选项

| 选项            | 全称                    | 说明                  | 示例                                          |
| --------------- | ----------------------- | --------------------- | --------------------------------------------- | ----------------- |
| `-i`            | `--ignore-case`         | 忽略大小写            | `grep -i "error" log.txt`                     |
| `-r`            | `--recursive`           | 递归搜索目录          | `grep -r "TODO" src/`                         |
| `-n`            | `--line-number`         | 显示行号              | `grep -n "function" app.js`                   |
| `-l`            | `--files-with-matches`  | 只显示匹配的文件名    | `grep -l "error" *.log`                       |
| `-L`            | `--files-without-match` | 显示不匹配的文件名    | `grep -L "test" *.js`                         |
| `-c`            | `--count`               | 统计匹配行数          | `grep -c "error" log.txt`                     |
| `-v`            | `--invert-match`        | 反向匹配（排除）      | `grep -v "debug" log.txt`                     |
| `-w`            | `--word-regexp`         | 全词匹配              | `grep -w "log" app.js`                        |
| `-x`            | `--line-regexp`         | 全行匹配              | `grep -x "done" status.txt`                   |
| `-o`            | `--only-matching`       | 只输出匹配部分        | `grep -o "error:[0-9]*" log.txt`              |
| `-E`            | `--extended-regexp`     | 使用扩展正则表达式    | `grep -E "error                               | warning" log.txt` |
| `-P`            | `--perl-regexp`         | 使用 Perl 正则表达式  | `grep -P "\d{3}-\d{4}" file.txt`              |
| `-A n`          | `--after-context`       | 显示匹配行后 n 行     | `grep -A 3 "error" log.txt`                   |
| `-B n`          | `--before-context`      | 显示匹配行前 n 行     | `grep -B 3 "error" log.txt`                   |
| `-C n`          | `--context`             | 显示匹配行前后各 n 行 | `grep -C 3 "error" log.txt`                   |
| `-q`            | `--quiet`               | 静默模式，不输出      | `grep -q "error" log.txt && echo "found"`     |
| `--include`     | -                       | 只搜索匹配的文件      | `grep -r --include="*.js" "TODO"`             |
| `--exclude`     | -                       | 排除匹配的文件        | `grep -r --exclude="*.min.js" "function"`     |
| `--exclude-dir` | -                       | 排除目录              | `grep -r --exclude-dir=node_modules "import"` |

### 3.3 正则表达式语法

#### 3.3.1 基础正则（BRE）vs 扩展正则（ERE）

grep 默认使用基础正则表达式（BRE），使用 `-E` 启用扩展正则表达式（ERE）：

| 元字符   | BRE       | ERE      | 说明                 |
| -------- | --------- | -------- | -------------------- |
| `.`      | `.`       | `.`      | 任意单个字符         |
| `*`      | `*`       | `*`      | 前一个字符 0 或多次  |
| `+`      | `\+`      | `+`      | 前一个字符 1 或多次  |
| `?`      | `\?`      | `?`      | 前一个字符 0 或 1 次 |
| `{n,m}`  | `\{n,m\}` | `{n,m}`  | 前一个字符 n 到 m 次 |
| `()`     | `\(\)`    | `()`     | 分组                 |
| `\|`     | `\|`      | `\|`     | 或                   |
| `^`      | `^`       | `^`      | 行首                 |
| `$`      | `$`       | `$`      | 行尾                 |
| `[...]`  | `[...]`   | `[...]`  | 字符类               |
| `[^...]` | `[^...]`  | `[^...]` | 否定字符类           |

#### 3.3.2 常用正则模式

```bash
# 行首匹配
grep "^import" src/index.js

# 行尾匹配
grep ";$" src/index.js

# 数字匹配
grep -E "[0-9]+" data.txt

# 单词边界
grep -w "log" app.js          # 匹配 log，不匹配 login

# 或匹配
grep -E "error|warning|fatal" log.txt

# 分组和引用
grep -E "(error|warn).*\1" log.txt  # 匹配同一行出现两次相同词

# 否定预查（需 -P）
grep -P "error(?!: timeout)" log.txt  # error 后面不跟 ": timeout"
```

#### 3.3.3 字符类

| 表达式      | 说明                    |
| ----------- | ----------------------- |
| `[abc]`     | 匹配 a、b 或 c          |
| `[a-z]`     | 匹配小写字母            |
| `[A-Z]`     | 匹配大写字母            |
| `[0-9]`     | 匹配数字                |
| `[a-zA-Z]`  | 匹配字母                |
| `[^abc]`    | 匹配除 a、b、c 外的字符 |
| `[:alnum:]` | 字母数字（POSIX）       |
| `[:alpha:]` | 字母（POSIX）           |
| `[:digit:]` | 数字（POSIX）           |
| `[:space:]` | 空白字符（POSIX）       |

```bash
# POSIX 字符类用法
grep "[[:digit:]]\{3\}-[[:digit:]]\{4\}" phones.txt
# 匹配：123-4567
```

### 3.4 实用场景

#### 3.4.1 代码搜索

```bash
# 查找函数定义
grep -rn "function\s\+processData" src/

# 查找类定义
grep -rn "class\s\+User" src/

# 查找 TODO 和 FIXME
grep -rn "TODO\|FIXME" src/ --include="*.{js,ts}"

# 查找 import 语句
grep -rn "^import.*from" src/ --include="*.ts"

# 查找 API 调用
grep -rn "fetch\|axios" src/ --include="*.{js,ts,tsx}"

# 查找未使用的变量（简单版）
grep -rn "const\s\+\w\+\s*=" src/ | grep -v "export"
```

#### 3.4.2 日志分析

```bash
# 查找错误日志
grep -i "error\|exception\|fail" app.log

# 统计错误次数
grep -c "error" app.log

# 查找特定时间段的日志
grep "2024-01-15 1[0-2]:" app.log

# 提取 IP 地址
grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" access.log

# 查找特定状态码
grep -E "HTTP/[0-9.]+ (4[0-9]{2}|5[0-9]{2})" access.log

# 查找慢请求（响应时间 > 1000ms）
grep -E "response_time:[1-9][0-9]{3,}" app.log
```

#### 3.4.3 配置文件处理

```bash
# 查找非注释行
grep -v "^\s*#" config.ini
grep -v "^\s*//" config.js

# 查找特定配置
grep "^database" config.ini

# 提取环境变量定义
grep -E "^[A-Z_]+=" .env

# 查找 JSON 中的特定键
grep -o '"version":\s*"[^"]*"' package.json
```

#### 3.4.4 文件过滤

```bash
# 查找包含 class 但不包含 test 的文件
grep -l "class" *.js | xargs grep -L "test"

# 查找同时包含两个关键词的文件
grep -l "import" *.ts | xargs grep -l "export"

# 递归搜索但排除目录
grep -r "TODO" . \
  --exclude-dir=node_modules \
  --exclude-dir=dist \
  --exclude-dir=.git

# 只搜索特定类型文件
grep -r "function" . --include="*.{js,ts}"
```

### 3.5 性能优化技巧

#### 3.5.1 减少搜索范围

```bash
# ❌ 搜索所有文件
grep -r "pattern" .

# ✅ 限定文件类型
grep -r "pattern" . --include="*.js"

# ✅ 排除无关目录
grep -r "pattern" . --exclude-dir={node_modules,.git,dist}

# ✅ 指定目录
grep -r "pattern" src/
```

#### 3.5.2 使用更快的工具

在大型项目中，考虑使用更快的替代工具：

| 工具                       | 特点                             |
| -------------------------- | -------------------------------- |
| `ripgrep (rg)`             | 速度快，自动忽略 .gitignore      |
| `ag` (The Silver Searcher) | 速度快，代码搜索优化             |
| `ack`                      | 为程序员设计，自动过滤二进制文件 |

```bash
# ripgrep 示例
rg "pattern" src/
rg -t js "function"  # 只搜索 JS 文件
rg -g "*.ts" "import" # glob 模式
```

#### 3.5.3 使用固定字符串

当不需要正则表达式时，使用 `-F` 提升性能：

```bash
# -F 表示固定字符串，不解释正则
grep -F "error.code" log.txt
grep -F "[DEBUG]" log.txt  # 不需要转义方括号
```

#### 3.5.4 并行搜索

```bash
# 使用 xargs 并行处理
find . -name "*.js" | xargs -P 4 grep "pattern"

# 使用 GNU parallel
find . -name "*.js" | parallel grep "pattern"
```

## 4. Glob vs Grep 对比

### 4.1 核心区别

| 维度     | Glob                     | Grep           |
| -------- | ------------------------ | -------------- |
| 匹配对象 | 文件名/路径              | 文件内容       |
| 语法     | 通配符（`*`, `?`, `[]`） | 正则表达式     |
| `*` 含义 | 任意字符序列             | 重复前一个字符 |
| `.` 含义 | 字面量点号               | 任意单个字符   |
| 返回值   | 文件列表                 | 匹配的行       |
| 用途     | 选择文件                 | 搜索内容       |

### 4.2 语法对照表

| 需求           | Glob         | Grep (ERE)  |
| -------------- | ------------ | ----------- |
| 任意字符序列   | `*`          | `.*`        |
| 单个任意字符   | `?`          | `.`         |
| 字符集合       | `[abc]`      | `[abc]`     |
| 字符范围       | `[a-z]`      | `[a-z]`     |
| 否定字符集     | `[!abc]`     | `[^abc]`    |
| 多选项         | `{a,b,c}`    | `(a\|b\|c)` |
| 可选（0或1次） | `?(pattern)` | `pattern?`  |
| 一次或多次     | `+(pattern)` | `pattern+`  |
| 零次或多次     | `*(pattern)` | `pattern*`  |
| 匹配目录分隔符 | `**`         | N/A         |
| 行首           | N/A          | `^`         |
| 行尾           | N/A          | `$`         |

### 4.3 组合使用

Glob 和 Grep 经常组合使用：

```bash
# 场景 1：在特定类型文件中搜索
grep -r "TODO" --include="*.js" src/

# 场景 2：在 glob 匹配的文件中搜索
for file in src/**/*.ts; do
  grep -l "interface" "$file"
done

# 场景 3：使用 find + grep
find . -name "*.js" -exec grep -l "async" {} \;

# 场景 4：使用管道组合
ls *.log | xargs grep "error"

# 场景 5：查找包含特定内容的特定文件
grep -r "export default" --include="*.tsx" src/ | \
  grep -v "test" | \
  grep -v "story"
```

### 4.4 选择指南

**使用 Glob 当你需要：**

- 选择要处理的文件列表
- 配置构建工具的输入/输出
- 设置忽略规则
- 批量操作特定类型文件

**使用 Grep 当你需要：**

- 在文件内容中搜索文本
- 分析日志文件
- 查找代码中的模式
- 统计出现次数

## 5. 常见问题与解决方案

### 5.1 Glob 常见问题

**Q1：`*.js` 没有匹配子目录的文件？**

在大多数工具中，`*` 不匹配目录分隔符。使用 `**` 匹配任意深度：

```bash
# ❌ 只匹配当前目录
*.js

# ✅ 匹配所有子目录
**/*.js
```

**Q2：否定模式不生效？**

否定模式的行为因工具而异。一般需要先匹配再排除：

```javascript
// lint-staged 中的正确用法
{
  "*.js": "eslint",
  "!*.min.js": []  // 这种方式可能不工作
}

// 更可靠的方式
{
  "!(*.min).js": "eslint"
}
```

**Q3：花括号扩展不工作？**

不是所有环境都支持花括号扩展：

```bash
# Bash 默认支持
ls *.{js,ts}

# sh 可能不支持，使用多个模式
ls *.js *.ts
```

**Q4：如何调试 Glob 匹配？**

```bash
# 使用 echo 预览匹配
echo src/**/*.js

# 使用 ls 验证
ls -la src/**/*.js

# Node.js 中测试
node -e "console.log(require('glob').sync('**/*.js'))"
```

### 5.2 Grep 常见问题

**Q1：正则表达式中的特殊字符需要转义？**

```bash
# 搜索包含 . 的内容
grep "config\.js" file.txt

# 搜索包含 [] 的内容
grep "\[error\]" log.txt

# 使用 -F 避免转义
grep -F "[error]" log.txt
```

**Q2：搜索中文内容？**

确保文件编码正确，使用 `--binary-files=text`：

```bash
grep --binary-files=text "错误" log.txt
```

**Q3：如何搜索多行内容？**

标准 grep 是行级搜索。搜索跨行模式使用 `-z` 或其他工具：

```bash
# 使用 -z（以 NUL 为行分隔符）
grep -Pzo "start.*\n.*end" file.txt

# 使用 pcregrep
pcregrep -M "start.*\nend" file.txt
```

**Q4：搜索二进制文件跳过？**

```bash
# 将二进制文件当作文本处理
grep --binary-files=text "pattern" file

# 跳过二进制文件
grep -I "pattern" *
```

### 5.3 性能问题

**Q5：搜索大量文件很慢？**

```bash
# 1. 缩小搜索范围
grep -r "pattern" src/ --include="*.js"

# 2. 排除无关目录
grep -r "pattern" . --exclude-dir={node_modules,.git}

# 3. 使用更快的工具
rg "pattern" src/

# 4. 使用固定字符串
grep -F "exact string" files
```

**Q6：结果太多无法处理？**

```bash
# 限制输出行数
grep "pattern" file | head -100

# 只显示文件名
grep -l "pattern" *

# 统计数量
grep -c "pattern" *
```

## 6. 总结

### 6.1 核心要点

1. **Glob 用于文件选择**：通过通配符匹配文件路径
2. **Grep 用于内容搜索**：通过正则表达式搜索文件内容
3. **两者语法不同**：特别注意 `*` 和 `.` 的含义差异
4. **工具实现有差异**：bash、micromatch、.gitignore 规则略有不同
5. **组合使用更强大**：先用 Glob 选择文件，再用 Grep 搜索内容

### 6.2 Glob 速查表

| 模式           | 匹配                 | 常用场景     |
| -------------- | -------------------- | ------------ |
| `*`            | 任意字符（不含 `/`） | 当前目录文件 |
| `**`           | 任意层级目录         | 递归匹配     |
| `?`            | 单个字符             | 模糊匹配     |
| `[abc]`        | a、b 或 c            | 字符集       |
| `[!abc]`       | 非 a、b、c           | 排除字符     |
| `{a,b}`        | a 或 b               | 多选项       |
| `*.{js,ts}`    | JS 和 TS 文件        | 多扩展名     |
| `**/*.test.js` | 所有测试文件         | 测试文件匹配 |
| `!*.min.js`    | 排除压缩文件         | 否定模式     |
| `src/**/*`     | src 下所有文件       | 目录递归     |

### 6.3 Grep 速查表

| 选项/模式       | 说明         | 示例                         |
| --------------- | ------------ | ---------------------------- |
| `-i`            | 忽略大小写   | `grep -i "error"`            |
| `-r`            | 递归搜索     | `grep -r "TODO" src/`        |
| `-n`            | 显示行号     | `grep -n "func"`             |
| `-l`            | 只显示文件名 | `grep -l "class"`            |
| `-v`            | 反向匹配     | `grep -v "debug"`            |
| `-E`            | 扩展正则     | `grep -E "a\|b"`             |
| `-w`            | 全词匹配     | `grep -w "log"`              |
| `-c`            | 统计行数     | `grep -c "error"`            |
| `-A/-B/-C n`    | 上下文行     | `grep -C 3 "error"`          |
| `--include`     | 包含文件模式 | `--include="*.js"`           |
| `--exclude-dir` | 排除目录     | `--exclude-dir=node_modules` |
| `^pattern`      | 行首匹配     | `grep "^import"`             |
| `pattern$`      | 行尾匹配     | `grep ";$"`                  |
| `[0-9]+`        | 数字（ERE）  | `grep -E "[0-9]+"`           |

### 6.4 常用组合命令

```bash
# 在 JS/TS 文件中搜索 TODO
grep -rn "TODO" --include="*.{js,ts,tsx}" src/

# 统计代码行数（排除空行和注释）
grep -v "^\s*$\|^\s*//" src/**/*.js | wc -l

# 查找未使用的导出
grep -r "export" --include="*.ts" src/ | \
  cut -d: -f1 | sort -u

# 批量替换（预览）
grep -rl "oldText" src/ | xargs grep -l "oldText"

# 查找大文件中的错误
grep -n "ERROR" large.log | head -50
```

## 参考资源

- [Bash Glob 模式](https://www.gnu.org/software/bash/manual/html_node/Pattern-Matching.html)
- [micromatch 文档](https://github.com/micromatch/micromatch)
- [minimatch 文档](https://github.com/isaacs/minimatch)
- [GNU Grep 手册](https://www.gnu.org/software/grep/manual/grep.html)
- [正则表达式教程](https://www.regular-expressions.info/)
- [ripgrep 用户指南](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md)
- [.gitignore 规范](https://git-scm.com/docs/gitignore)
