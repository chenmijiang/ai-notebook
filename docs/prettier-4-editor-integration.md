# Prettier 编辑器集成指南

## 1. 概述

### 1.1 核心原则

编辑器集成 Prettier 的目标是让开发者在编写代码时获得即时、一致的格式化体验。无论使用哪种编辑器，遵循以下原则可以确保团队协作的一致性。

| 原则               | 说明                                                       |
| ------------------ | ---------------------------------------------------------- |
| 项目级配置优先     | 使用项目中的 `.prettierrc` 而非编辑器全局设置              |
| 使用本地 Prettier  | 使用 `node_modules` 中的 Prettier 而非全局安装             |
| 保存时自动格式化   | 配置 Format on Save 减少手动操作                           |
| 统一编辑器配置     | 将编辑器配置文件（如 `.vscode/settings.json`）纳入版本控制 |
| 配合 .editorconfig | 使用 `.editorconfig` 统一基础编辑器行为                    |

**为什么项目级配置优先：**

```
❌ 编辑器全局设置
├── 开发者 A 的 VS Code：printWidth: 80
├── 开发者 B 的 WebStorm：printWidth: 100
└── 开发者 C 的 Neovim：printWidth: 120
→ 每次提交都产生格式差异

✅ 项目级配置
project/.prettierrc
├── 所有编辑器读取同一配置
└── 格式化结果完全一致
```

### 1.2 项目级配置优先

编辑器中的 Prettier 设置应仅作为「后备选项」，当项目中没有 `.prettierrc` 配置文件时才生效。

**配置优先级（从高到低）：**

| 优先级 | 配置来源              | 适用场景         |
| ------ | --------------------- | ---------------- |
| 1      | 项目 `.prettierrc` 等 | 团队项目（推荐） |
| 2      | 项目 `.editorconfig`  | 基础编辑器设置   |
| 3      | 编辑器工作区设置      | 特定项目覆盖     |
| 4      | 编辑器用户设置        | 个人偏好（后备） |
| 5      | Prettier 默认值       | 无任何配置时     |

**最佳实践：**

```bash
# 项目结构
project/
├── .prettierrc           # Prettier 配置（必须）
├── .prettierignore       # 忽略文件（推荐）
├── .editorconfig         # 基础编辑器配置（推荐）
├── .vscode/
│   └── settings.json     # VS Code 工作区设置（可选）
└── package.json          # 包含 prettier 依赖
```

> **提示**：关于 Prettier 配置文件的详细说明，请参阅 [Prettier 配置完全指南](./prettier-2-configuration.md)。

## 2. VS Code

VS Code 是前端开发最流行的编辑器，通过官方扩展可以无缝集成 Prettier。

### 2.1 安装 Prettier 扩展

**扩展信息：**

| 项目     | 内容                                         |
| -------- | -------------------------------------------- |
| 扩展名称 | Prettier - Code formatter                    |
| 扩展 ID  | `esbenp.prettier-vscode`                     |
| 安装方式 | VS Code 扩展面板搜索 "Prettier" 或命令行安装 |
| 仓库地址 | https://github.com/prettier/prettier-vscode  |

**命令行安装：**

```bash
# 通过 VS Code 命令行安装
code --install-extension esbenp.prettier-vscode
```

**扩展功能：**

| 功能           | 说明                                      |
| -------------- | ----------------------------------------- |
| 格式化文档     | 格式化整个文件                            |
| 格式化选中内容 | 仅格式化选中的代码片段                    |
| 保存时格式化   | 配合 `editor.formatOnSave` 自动格式化     |
| 配置文件支持   | 自动读取项目中的 `.prettierrc` 等配置文件 |
| 忽略文件支持   | 自动读取 `.prettierignore`                |
| 状态栏显示     | 底部状态栏显示 Prettier 状态              |

### 2.2 基础配置

安装扩展后，需要将 Prettier 设置为默认格式化工具并启用保存时格式化。

**用户设置（settings.json）：**

```json
{
  // 将 Prettier 设为默认格式化工具
  "editor.defaultFormatter": "esbenp.prettier-vscode",

  // 保存时自动格式化
  "editor.formatOnSave": true,

  // 粘贴时格式化（可选）
  "editor.formatOnPaste": false
}
```

**按语言设置默认格式化工具：**

```json
{
  // 全局默认格式化工具
  "editor.defaultFormatter": "esbenp.prettier-vscode",

  // JavaScript 使用 Prettier
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },

  // TypeScript 使用 Prettier
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },

  // JSON 使用 Prettier
  "[json]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },

  // Markdown 使用 Prettier
  "[markdown]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  }
}
```

> **注意**：VS Code 不支持合并语言选择器（如 `[javascript][typescript]`），必须为每种语言单独设置。

**Prettier 扩展专用设置：**

| 设置                            | 默认值            | 说明                           |
| ------------------------------- | ----------------- | ------------------------------ |
| `prettier.enable`               | `true`            | 启用/禁用 Prettier 扩展        |
| `prettier.requireConfig`        | `false`           | 仅在有配置文件时格式化         |
| `prettier.ignorePath`           | `.prettierignore` | 忽略文件路径                   |
| `prettier.configPath`           | -                 | 强制指定配置文件路径           |
| `prettier.useEditorConfig`      | `true`            | 读取 `.editorconfig` 设置      |
| `prettier.resolveGlobalModules` | `false`           | 解析全局安装的 Prettier        |
| `prettier.withNodeModules`      | `false`           | 格式化 `node_modules` 中的文件 |

### 2.3 工作区设置

工作区设置存储在项目的 `.vscode/settings.json` 中，可以纳入版本控制与团队共享。

**推荐的工作区配置（.vscode/settings.json）：**

```json
{
  // ===== 格式化设置 =====
  // 默认格式化工具
  "editor.defaultFormatter": "esbenp.prettier-vscode",

  // 保存时格式化
  "editor.formatOnSave": true,

  // ===== 语言特定设置 =====
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[javascriptreact]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[typescriptreact]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[json]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[jsonc]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[html]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[css]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[scss]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[markdown]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[yaml]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },

  // ===== Prettier 扩展设置 =====
  // 仅在有配置文件时格式化（团队项目推荐开启）
  "prettier.requireConfig": true
}
```

**配合 ESLint 使用：**

```json
{
  // Prettier 作为格式化工具
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.formatOnSave": true,

  // ESLint 自动修复
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  }
  // VS Code 保存时执行顺序：codeActionsOnSave（ESLint）→ formatOnSave（Prettier）
}
```

### 2.4 常见问题

**问题一：Prettier 没有生效**

| 排查步骤 | 操作方法                                |
| -------- | --------------------------------------- |
| 1        | 检查扩展是否已安装并启用                |
| 2        | 点击状态栏 "Prettier" 查看输出日志      |
| 3        | 确认 `editor.defaultFormatter` 设置正确 |
| 4        | 检查项目中是否有 `.prettierrc` 配置文件 |
| 5        | 运行 `npm install` 确保依赖已安装       |

**查看 Prettier 输出日志：**

```
1. 点击 VS Code 底部状态栏的 "Prettier"
2. 或：View → Output → 选择 "Prettier"
3. 查看错误信息
```

**问题二：格式化结果与预期不符**

```bash
# 检查 Prettier 使用的配置
npx prettier --find-config-path src/index.js

# 检查格式化结果
npx prettier --check src/index.js
```

**问题三：工作区信任警告**

VS Code 的工作区信任功能会限制不受信任文件夹中的 Prettier 行为：

| 信任状态 | Prettier 行为                                 |
| -------- | --------------------------------------------- |
| 受信任   | 正常使用项目本地 Prettier、插件               |
| 不受信任 | 仅使用扩展内置 Prettier，不加载本地模块和插件 |

**解决方法：**

```
1. 打开命令面板（Ctrl+Shift+P / Cmd+Shift+P）
2. 运行 "Workspaces: Manage Workspace Trust"
3. 将工作区标记为受信任
```

**问题四：与其他扩展冲突**

```json
{
  // 禁用 VS Code 内置的 JavaScript 格式化
  "javascript.format.enable": false,
  "typescript.format.enable": false,

  // 确保 Prettier 优先
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  }
}
```

## 3. JetBrains 系列

JetBrains 系列 IDE（WebStorm、IntelliJ IDEA、PhpStorm 等）内置了 Prettier 支持，无需安装额外插件。

### 3.1 WebStorm/IDEA 配置

**启用 Prettier 插件：**

| 步骤 | 操作                                     |
| ---- | ---------------------------------------- |
| 1    | 打开设置：`Ctrl+Alt+S`（macOS: `Cmd+,`） |
| 2    | 导航到：Plugins                          |
| 3    | 搜索 "Prettier"，确认已启用              |

**配置 Prettier：**

| 步骤 | 操作                                                   |
| ---- | ------------------------------------------------------ |
| 1    | 打开设置：`Ctrl+Alt+S`（macOS: `Cmd+,`）               |
| 2    | 导航到：Languages & Frameworks → JavaScript → Prettier |
| 3    | 选择配置模式（自动或手动）                             |

**配置模式对比：**

| 模式 | 说明                                                     |
| ---- | -------------------------------------------------------- |
| 自动 | IDE 自动检测 `node_modules/prettier`，仅在依赖范围内生效 |
| 手动 | 手动指定 Prettier 路径，可扩展到依赖范围外的文件         |

**自动配置（推荐）：**

```
Languages & Frameworks → JavaScript → Prettier
├── ☑ Automatic Prettier configuration
└── IDE 自动发现：
    ├── node_modules/prettier
    ├── .prettierrc / prettier.config.js 等配置文件
    └── .prettierignore
```

**手动配置：**

```
Languages & Frameworks → JavaScript → Prettier
├── ☑ Manual Prettier configuration
├── Prettier package: ~/project/node_modules/prettier
├── Run for files: **/*.{js,ts,jsx,tsx,vue,json,css,scss,html,md}
└── ☐ Apply Prettier to files outside the prettier dependency scope
```

### 3.2 指定 Prettier 路径

在手动配置模式下，需要正确指定 Prettier 包的路径。

**Prettier 包路径设置：**

| 场景         | 路径示例                                                        |
| ------------ | --------------------------------------------------------------- |
| 项目本地安装 | `~/project/node_modules/prettier`                               |
| Monorepo     | `~/monorepo/node_modules/prettier`                              |
| 全局安装     | `/usr/local/lib/node_modules/prettier`                          |
| pnpm         | `~/project/node_modules/.pnpm/prettier@*/node_modules/prettier` |

**文件模式配置（Run for files）：**

默认模式：`**/*.{js,ts,jsx,tsx,cjs,cts,mjs,mts,vue,astro}`

**常见自定义模式：**

| 场景             | 模式                                              |
| ---------------- | ------------------------------------------------- |
| 添加更多文件类型 | `**/*.{js,ts,jsx,tsx,json,css,scss,html,md,yaml}` |
| 限制特定目录     | `src/**/*.{js,ts,jsx,tsx}`                        |
| 排除特定目录     | `!**/dist/**`（通过 .prettierignore 实现）        |

**启用自动执行：**

| 选项                          | 说明                                |
| ----------------------------- | ----------------------------------- |
| Run on save                   | 保存文件时自动格式化                |
| Run on paste                  | 粘贴代码时自动格式化                |
| Run on 'Reformat Code' action | 使用快捷键重新格式化时调用 Prettier |

```
推荐设置：
├── ☑ Run on save
├── ☐ Run on paste（可选）
└── ☑ Run on 'Reformat Code' action
```

### 3.3 快捷键设置

**内置快捷键：**

| 操作                   | Windows/Linux      | macOS             |
| ---------------------- | ------------------ | ----------------- |
| Reformat with Prettier | `Ctrl+Alt+Shift+P` | `Cmd+Alt+Shift+P` |
| Reformat Code（通用）  | `Ctrl+Alt+L`       | `Cmd+Alt+L`       |

**自定义快捷键：**

```
1. 打开设置：Ctrl+Alt+S（macOS: Cmd+,）
2. 导航到：Keymap
3. 搜索 "Prettier"
4. 右键点击 "Reformat with Prettier"
5. 选择 "Add Keyboard Shortcut"
6. 设置自定义快捷键
```

**状态栏小部件：**

WebStorm 在状态栏显示 Prettier 图标，提供快速访问：

| 功能            | 说明                   |
| --------------- | ---------------------- |
| 点击图标        | 显示快速菜单           |
| Restart Service | 重启 Prettier 服务     |
| Edit Config     | 打开 Prettier 配置文件 |
| Settings        | 打开 Prettier 设置页面 |

## 4. Vim/Neovim

Vim 和 Neovim 有多种方式集成 Prettier，从专用插件到通用格式化框架都有。

### 4.1 插件方案对比

| 插件         | 类型               | 特点                                | 推荐场景           |
| ------------ | ------------------ | ----------------------------------- | ------------------ |
| conform.nvim | 格式化框架         | Neovim 专用，异步，支持多格式化工具 | Neovim 现代配置    |
| null-ls.nvim | LSP 桥接（已归档） | 集成 linter 和 formatter 到 LSP     | 遗留项目           |
| vim-prettier | Prettier 专用      | 简单直接，功能完整                  | Vim/简单配置       |
| Neoformat    | 格式化框架         | 支持多种格式化工具                  | Vim/Neovim 通用    |
| ALE          | Linter + Fixer     | 异步检查和修复                      | 需要 lint + format |
| coc-prettier | coc.nvim 扩展      | VS Code 式体验                      | 使用 coc.nvim 用户 |

> **注意**：null-ls.nvim 已停止维护，推荐迁移到 conform.nvim 或其他活跃维护的方案。

**选择建议：**

| 使用场景               | 推荐方案                  |
| ---------------------- | ------------------------- |
| Neovim + Lazy.nvim     | conform.nvim              |
| Neovim + coc.nvim      | coc-prettier              |
| Vim 简单配置           | vim-prettier 或 Neoformat |
| 需要 ESLint + Prettier | ALE 或 conform.nvim       |

### 4.2 conform.nvim 配置

conform.nvim 是 Neovim 现代配置的首选格式化方案，支持异步格式化和多种格式化工具。

**安装（使用 lazy.nvim）：**

```lua
-- lua/plugins/formatting.lua
return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>f",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = "",
      desc = "Format buffer",
    },
  },
  opts = {
    -- 按文件类型配置格式化工具
    formatters_by_ft = {
      javascript = { "prettierd", "prettier", stop_after_first = true },
      javascriptreact = { "prettierd", "prettier", stop_after_first = true },
      typescript = { "prettierd", "prettier", stop_after_first = true },
      typescriptreact = { "prettierd", "prettier", stop_after_first = true },
      vue = { "prettierd", "prettier", stop_after_first = true },
      css = { "prettierd", "prettier", stop_after_first = true },
      scss = { "prettierd", "prettier", stop_after_first = true },
      html = { "prettierd", "prettier", stop_after_first = true },
      json = { "prettierd", "prettier", stop_after_first = true },
      jsonc = { "prettierd", "prettier", stop_after_first = true },
      yaml = { "prettierd", "prettier", stop_after_first = true },
      markdown = { "prettierd", "prettier", stop_after_first = true },
      graphql = { "prettierd", "prettier", stop_after_first = true },
    },

    -- 保存时格式化
    format_on_save = {
      timeout_ms = 500,
      lsp_fallback = true,
    },
  },
}
```

**配置说明：**

| 配置项                    | 说明                                                |
| ------------------------- | --------------------------------------------------- |
| `formatters_by_ft`        | 按文件类型指定格式化工具                            |
| `stop_after_first = true` | 使用第一个可用的格式化工具（prettierd 或 prettier） |
| `format_on_save`          | 保存时自动格式化                                    |
| `timeout_ms`              | 格式化超时时间（毫秒）                              |
| `lsp_fallback`            | 无格式化工具时回退到 LSP                            |

**prettierd vs prettier：**

| 工具        | 说明                                                |
| ----------- | --------------------------------------------------- |
| `prettierd` | Prettier 的守护进程版本，启动后常驻内存，格式化更快 |
| `prettier`  | 标准 Prettier，每次格式化都启动新进程               |

```bash
# 安装 prettierd（推荐）
npm install -g @fsouza/prettierd
```

**手动格式化命令：**

```lua
-- 在 Neovim 中运行
:lua require("conform").format()

-- 查看当前缓冲区可用的格式化工具
:ConformInfo
```

### 4.3 格式化触发方式

**方式一：保存时自动格式化**

```lua
-- conform.nvim 配置
opts = {
  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
}
```

**方式二：使用 autocmd**

```lua
-- init.lua
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.js", "*.jsx", "*.ts", "*.tsx", "*.vue", "*.json", "*.css", "*.scss", "*.html", "*.md" },
  callback = function(args)
    require("conform").format({ bufnr = args.buf })
  end,
})
```

**方式三：手动触发**

```lua
-- 设置快捷键
vim.keymap.set("n", "<leader>f", function()
  require("conform").format({ async = true })
end, { desc = "Format buffer" })

vim.keymap.set("v", "<leader>f", function()
  require("conform").format({ async = true })
end, { desc = "Format selection" })
```

**方式四：使用项目本地 Prettier**

```lua
-- 确保使用项目本地的 prettier
opts = {
  formatters = {
    prettier = {
      -- 优先使用项目本地的 prettier
      command = function()
        local util = require("conform.util")
        return util.find_executable({ "node_modules/.bin/prettier" }, "prettier")
      end,
    },
  },
}
```

**其他插件配置示例：**

**Neoformat：**

```vim
" .vimrc 或 init.vim
Plug 'sbdchd/neoformat'

" 使用项目本地的 prettier
let g:neoformat_try_node_exe = 1

" 保存时自动格式化
autocmd BufWritePre *.js,*.jsx,*.ts,*.tsx,*.vue,*.json,*.css,*.html,*.md Neoformat

" 手动格式化命令
" :Neoformat
" :Neoformat prettier
```

**ALE：**

```vim
" .vimrc 或 init.vim
Plug 'dense-analysis/ale'

" 配置 Prettier 作为 fixer
let g:ale_fixers = {
\   'javascript': ['prettier'],
\   'typescript': ['prettier'],
\   'javascriptreact': ['prettier'],
\   'typescriptreact': ['prettier'],
\   'vue': ['prettier'],
\   'css': ['prettier'],
\   'scss': ['prettier'],
\   'html': ['prettier'],
\   'json': ['prettier'],
\   'markdown': ['prettier'],
\}

" 只使用显式配置的 linter
let g:ale_linters_explicit = 1

" 保存时自动修复
let g:ale_fix_on_save = 1
```

**coc-prettier：**

```vim
" 安装 coc.nvim 后
:CocInstall coc-prettier

" coc-settings.json
{
  "prettier.formatOnSaveMode": "file",
  "prettier.onlyUseLocalVersion": true
}

" 设置快捷键
nmap <leader>f :CocCommand prettier.formatFile<CR>
```

## 5. 跨编辑器一致性

### 5.1 使用项目本地 Prettier

确保所有编辑器使用项目中安装的 Prettier 版本是保持一致性的关键。

**为什么使用本地 Prettier：**

| 问题         | 使用全局 Prettier          | 使用本地 Prettier       |
| ------------ | -------------------------- | ----------------------- |
| 版本不一致   | 开发者 Prettier 版本不同   | 所有人使用相同版本      |
| 配置不生效   | 全局 Prettier 可能忽略配置 | 正确读取项目配置        |
| 插件不可用   | 全局环境无法找到插件       | 插件安装在 node_modules |
| CI/CD 不一致 | 本地与 CI 格式化结果不同   | 本地与 CI 结果一致      |

**确保本地安装：**

```bash
# 安装 Prettier 为开发依赖
npm install --save-dev prettier

# 或使用其他包管理器
pnpm add -D prettier
yarn add -D prettier
```

**各编辑器使用本地 Prettier 的配置：**

| 编辑器   | 配置方式                                       |
| -------- | ---------------------------------------------- |
| VS Code  | 默认自动使用 `node_modules/prettier`           |
| WebStorm | 自动配置模式或手动指定 `node_modules/prettier` |
| Neovim   | conform.nvim 配置 `find_executable`            |
| Vim      | Neoformat 设置 `g:neoformat_try_node_exe = 1`  |

**VS Code 配置：**

```json
{
  // 仅在有配置文件时格式化，避免使用全局设置
  "prettier.requireConfig": true,

  // 禁用解析全局模块
  "prettier.resolveGlobalModules": false
}
```

### 5.2 .editorconfig 配合

`.editorconfig` 是跨编辑器的基础配置文件，Prettier 会读取其中的部分设置。

**Prettier 支持的 .editorconfig 选项：**

| .editorconfig 选项     | Prettier 选项 | 说明     |
| ---------------------- | ------------- | -------- |
| `indent_style`         | `useTabs`     | 缩进方式 |
| `indent_size`          | `tabWidth`    | 缩进宽度 |
| `tab_width`            | `tabWidth`    | Tab 宽度 |
| `max_line_length`      | `printWidth`  | 行宽     |
| `end_of_line`          | `endOfLine`   | 行尾符号 |
| `quote_type`（非标准） | `singleQuote` | 引号类型 |

**推荐的 .editorconfig：**

```ini
# .editorconfig
# https://editorconfig.org

root = true

[*]
charset = utf-8
end_of_line = lf
indent_style = space
indent_size = 2
insert_final_newline = true
trim_trailing_whitespace = true

[*.md]
trim_trailing_whitespace = false

[Makefile]
indent_style = tab
```

**配置优先级：**

```
Prettier 配置文件（.prettierrc）
    ↓ 覆盖
.editorconfig
    ↓ 覆盖
Prettier 默认值
```

> **注意**：如果 `.prettierrc` 中明确设置了某个选项，该选项会覆盖 `.editorconfig` 中的对应值。

**VS Code 配合 .editorconfig：**

```json
{
  // 启用 .editorconfig 支持
  "prettier.useEditorConfig": true
}
```

### 5.3 团队配置共享策略

**策略一：共享编辑器配置文件**

将编辑器配置文件纳入版本控制，团队成员克隆仓库后自动获得统一配置。

```bash
# 推荐纳入版本控制的文件
project/
├── .editorconfig         # 跨编辑器基础配置
├── .prettierrc           # Prettier 配置
├── .prettierignore       # Prettier 忽略文件
├── .vscode/
│   ├── settings.json     # VS Code 工作区设置
│   └── extensions.json   # 推荐扩展列表
└── .idea/                # JetBrains 配置（可选）
    └── prettier.xml
```

**VS Code 推荐扩展（.vscode/extensions.json）：**

```json
{
  "recommendations": [
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint",
    "editorconfig.editorconfig"
  ]
}
```

**策略二：文档化配置步骤**

在项目 README 中说明编辑器配置要求：

```markdown
## 开发环境配置

### VS Code

1. 安装推荐扩展（VS Code 会自动提示）
2. 项目已包含工作区设置，无需额外配置

### WebStorm

1. 打开设置 → Languages & Frameworks → JavaScript → Prettier
2. 选择 "Automatic Prettier configuration"
3. 勾选 "Run on save"

### Vim/Neovim

参考项目中的示例配置文件
```

**策略三：使用 Git Hooks 作为保障**

即使编辑器配置不正确，Git Hooks 也能确保提交的代码已格式化：

```bash
# 安装 husky 和 lint-staged
npm install --save-dev husky lint-staged

# package.json
{
  "lint-staged": {
    "*.{js,jsx,ts,tsx,json,css,scss,html,md}": "prettier --write"
  }
}
```

**配置完整性检查清单：**

| 检查项                        | 说明                      |
| ----------------------------- | ------------------------- |
| `.prettierrc` 存在            | 项目有 Prettier 配置文件  |
| `prettier` 在 devDependencies | Prettier 作为开发依赖安装 |
| `.editorconfig` 存在          | 有跨编辑器基础配置        |
| `.vscode/settings.json` 存在  | VS Code 用户有工作区配置  |
| 编辑器配置已共享              | 配置文件已纳入版本控制    |
| Git Hooks 已配置              | 提交前自动格式化作为保障  |

## 6. 总结

### 6.1 核心要点回顾

| 要点               | 说明                                      |
| ------------------ | ----------------------------------------- |
| 项目配置优先       | 使用 `.prettierrc` 而非编辑器全局设置     |
| 使用本地 Prettier  | 确保 `node_modules` 中安装了 Prettier     |
| 保存时自动格式化   | 配置 Format on Save 提升开发体验          |
| 共享编辑器配置     | 将 `.vscode/settings.json` 等纳入版本控制 |
| .editorconfig 配合 | 使用 `.editorconfig` 统一基础编辑器行为   |
| Git Hooks 保障     | 使用 husky + lint-staged 作为最后防线     |

### 6.2 编辑器配置速查表

| 编辑器   | 插件/扩展              | 格式化快捷键             | 配置位置                         |
| -------- | ---------------------- | ------------------------ | -------------------------------- |
| VS Code  | esbenp.prettier-vscode | `Shift+Alt+F`            | Settings / .vscode/settings.json |
| WebStorm | 内置                   | `Ctrl+Alt+Shift+P`       | Settings → JavaScript → Prettier |
| Neovim   | conform.nvim           | 自定义（如 `<leader>f`） | init.lua / lua/plugins/          |
| Vim      | Neoformat / ALE        | 自定义                   | .vimrc / init.vim                |

### 6.3 推荐的项目配置文件结构

```bash
project/
├── .editorconfig           # 跨编辑器基础配置
├── .prettierrc             # Prettier 配置
├── .prettierignore         # Prettier 忽略文件
├── .vscode/
│   ├── settings.json       # VS Code 工作区设置
│   └── extensions.json     # VS Code 推荐扩展
├── package.json            # 包含 prettier 依赖
└── README.md               # 包含编辑器配置说明
```

> **下一步**：了解编辑器集成后，建议阅读 [Prettier 工具链整合指南](./prettier-5-toolchain.md) 学习如何将 Prettier 与 ESLint、Git Hooks、CI/CD 等工具整合。

## 参考资源

- [Prettier Editor Integration](https://prettier.io/docs/editors.html)
- [Prettier VS Code Extension](https://github.com/prettier/prettier-vscode)
- [Prettier WebStorm Setup](https://prettier.io/docs/webstorm)
- [Prettier Vim Setup](https://prettier.io/docs/vim)
- [conform.nvim](https://github.com/stevearc/conform.nvim)
- [EditorConfig](https://editorconfig.org/)
- [Prettier 配置完全指南](./prettier-2-configuration.md)
