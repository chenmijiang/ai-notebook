# curl 前端开发者实用指南 实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 编写一篇面向前端开发者的 curl 精简实用指南，放置在 `docs/curl-guide.md`。

**Architecture:** 单文件 Markdown 文档，按场景驱动结构组织 7 个章节。遵循项目 tech-docs-guide 规范（章节编号、表格对比、代码块标注语言、中文注释、✅/❌ 标记）。

**Tech Stack:** Markdown, curl 命令示例

---

### Task 1: 编写概述章节

**Files:**

- Create: `docs/curl-guide.md`

**Step 1: 创建文件并编写概述**

编写以下内容：

- 标题：`# curl 使用指南`
- `## 1. 概述`
  - `### 1.1 什么是 curl`：一句话介绍 curl
  - `### 1.2 前端为什么需要 curl`：表格对比 curl vs Postman vs fetch，说明 curl 在终端调试中的优势

**Step 2: 验证格式**

Run: `npm run format`

**Step 3: Commit**

```bash
git add docs/curl-guide.md
git commit -m "docs(curl): add overview section"
```

---

### Task 2: 编写基础请求章节

**Files:**

- Modify: `docs/curl-guide.md`

**Step 1: 编写基础请求内容**

- `## 2. 基础请求`
  - `### 2.1 发送 GET 请求`：基本 GET、带查询参数的 GET
  - 使用 httpbin.org 作为示例 URL
  - 说明 `-s`（静默）、`-S`（显示错误）等常用搭配选项

**Step 2: 验证格式**

Run: `npm run format`

**Step 3: Commit**

```bash
git add docs/curl-guide.md
git commit -m "docs(curl): add basic request section"
```

---

### Task 3: 编写发送数据章节

**Files:**

- Modify: `docs/curl-guide.md`

**Step 1: 编写发送数据内容**

- `## 3. 发送数据`
  - `### 3.1 POST JSON`：`-X POST`、`-H "Content-Type: application/json"`、`-d` 用法
  - `### 3.2 表单提交`：`-d "key=value"` 和 `--data-urlencode`
  - `### 3.3 其他 HTTP 方法`：PUT、PATCH、DELETE 示例

**Step 2: 验证格式**

Run: `npm run format`

**Step 3: Commit**

```bash
git add docs/curl-guide.md
git commit -m "docs(curl): add sending data section"
```

---

### Task 4: 编写请求头与认证章节

**Files:**

- Modify: `docs/curl-guide.md`

**Step 1: 编写请求头与认证内容**

- `## 4. 请求头与认证`
  - `### 4.1 自定义请求头`：`-H` 添加 Header
  - `### 4.2 Bearer Token 认证`：`-H "Authorization: Bearer <token>"`
  - `### 4.3 Cookie 操作`：`-b` 发送 Cookie、`-c` 保存 Cookie

**Step 2: 验证格式**

Run: `npm run format`

**Step 3: Commit**

```bash
git add docs/curl-guide.md
git commit -m "docs(curl): add headers and auth section"
```

---

### Task 5: 编写文件上传与下载章节

**Files:**

- Modify: `docs/curl-guide.md`

**Step 1: 编写文件上传与下载内容**

- `## 5. 文件上传与下载`
  - `### 5.1 上传文件`：`-F "file=@path"` multipart 上传
  - `### 5.2 下载文件`：`-o` 指定文件名、`-O` 使用远程文件名

**Step 2: 验证格式**

Run: `npm run format`

**Step 3: Commit**

```bash
git add docs/curl-guide.md
git commit -m "docs(curl): add file upload and download section"
```

---

### Task 6: 编写调试技巧章节

**Files:**

- Modify: `docs/curl-guide.md`

**Step 1: 编写调试技巧内容**

- `## 6. 调试技巧`
  - `### 6.1 查看详细信息`：`-v` 详细输出
  - `### 6.2 只看响应头`：`-I` 和 `-i`
  - `### 6.3 查看耗时`：`-w` 格式化输出时间信息
  - `### 6.4 保存响应`：`-o` 保存到文件

**Step 2: 验证格式**

Run: `npm run format`

**Step 3: Commit**

```bash
git add docs/curl-guide.md
git commit -m "docs(curl): add debugging tips section"
```

---

### Task 7: 编写实用技巧与总结章节

**Files:**

- Modify: `docs/curl-guide.md`

**Step 1: 编写实用技巧内容**

- `## 7. 实用技巧`
  - `### 7.1 跟随重定向`：`-L`
  - `### 7.2 设置超时`：`--connect-timeout` 和 `--max-time`
  - `### 7.3 忽略 SSL 证书`：`-k`（说明仅用于开发环境，标注 ❌ 生产使用）
  - `### 7.4 使用代理`：`-x`

**Step 2: 编写总结章节**

- `## 8. 总结`
  - 速查表：表格列出所有常用选项及用途
  - 参考资源：curl 官方文档链接

**Step 3: 验证格式**

Run: `npm run format`

**Step 4: Commit**

```bash
git add docs/curl-guide.md
git commit -m "docs(curl): add tips and summary section"
```

---

### Task 8: 最终审校与验证

**Files:**

- Modify: `docs/curl-guide.md`

**Step 1: 通过 web fetch 验证 curl 选项准确性**

确认文档中涉及的 curl 选项和参数是否正确。

**Step 2: 检查文档规范**

- 章节编号格式正确（`## 1.` / `### 1.1`）
- 不使用目录和分隔线
- 代码块标注语言类型
- 表格用于对比和速查
- 中文注释说明关键步骤

**Step 3: 格式化并提交**

Run: `npm run format`

```bash
git add docs/curl-guide.md
git commit -m "docs(curl): final review and formatting"
```
