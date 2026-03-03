# URL 到网页渲染完整流程 - 实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 编写一篇面向前端面试者的中文技术博客，系统讲解从输入 URL 到页面渲染的完整流程，以 curl -v 输出作为实证。

**Architecture:** 单文件 `docs/url-to-render-guide.md`，9 个章节按时间线叙事，6 张 mermaid 图。遵循 tech-docs-guide 写作规范。

**Tech Stack:** Markdown, Mermaid

---

### Task 1: 创建文件，编写第 1 章概述 + 全局流程图

**Files:**

- Create: `docs/url-to-render-guide.md`

**Step 1: 编写文档骨架和第 1 章**

内容要点：

- 标题：`# 从输入 URL 到页面渲染完全指南`
- 一句话概括全流程
- 全局 mermaid flowchart（URL 解析 → DNS → TCP → TLS → HTTP → 服务器处理 → 响应 → 浏览器渲染）
- 引入 `curl -v https://httpbin.org/get` 作为观测工具
- 附完整 curl 输出（代码块）
- 章节编号格式：`## 1. 概述`

**Step 2: 格式化**

Run: `npm run format`

**Step 3: 提交**

```bash
git add docs/url-to-render-guide.md
# 使用 commit skill
```

Message: `docs(url-to-render): add overview and global flow diagram`

### Task 2: 编写第 2 章 URL 解析

**Files:**

- Modify: `docs/url-to-render-guide.md`

**Step 1: 编写第 2 章**

内容要点：

- `## 2. URL 解析`
- 拆解 `https://httpbin.org/get` 各部分，用表格说明各组成部分（协议、域名、端口、路径）
- 浏览器判断输入是搜索词还是 URL 的逻辑
- HSTS 检查：浏览器强制 HTTP → HTTPS 重定向

**Step 2: 格式化并提交**

Run: `npm run format`
Message: `docs(url-to-render): add URL parsing chapter`

### Task 3: 编写第 3 章 DNS 解析 + sequence diagram

**Files:**

- Modify: `docs/url-to-render-guide.md`

**Step 1: 编写第 3 章**

内容要点：

- `## 3. DNS 解析`
- 先展示 curl 输出片段：`Host httpbin.org:443 was resolved. IPv4: 198.18.0.40`
- DNS 缓存层级（浏览器缓存 → OS 缓存 → 路由器缓存 → ISP DNS → 递归查询）
- mermaid sequence diagram 展示 DNS 查询链（浏览器 → 本地DNS → 根DNS → .org DNS → 权威DNS）
- 提及 DNS over HTTPS

**Step 2: 格式化并提交**

Run: `npm run format`
Message: `docs(url-to-render): add DNS resolution chapter`

### Task 4: 编写第 4 章 TCP 连接 + sequence diagram

**Files:**

- Modify: `docs/url-to-render-guide.md`

**Step 1: 编写第 4 章**

内容要点：

- `## 4. TCP 连接`
- 先展示 curl 输出片段：`Trying 198.18.0.40:443... Connected to httpbin.org (198.18.0.40) port 443`
- 三次握手 SYN / SYN-ACK / ACK 详解
- mermaid sequence diagram 展示三次握手
- 简述为什么是三次而非两次（防止历史连接请求导致资源浪费）

**Step 2: 格式化并提交**

Run: `npm run format`
Message: `docs(url-to-render): add TCP connection chapter`

### Task 5: 编写第 5 章 TLS 握手 + sequence diagram

**Files:**

- Modify: `docs/url-to-render-guide.md`

**Step 1: 编写第 5 章**

这是最详细的章节，逐条对照 curl TLS 输出。

内容要点：

- `## 5. TLS 握手`
- 展示 curl 完整的 TLS 握手输出
- 分步讲解每条输出的含义：
  - Client Hello：客户端发送支持的加密套件、TLS 版本
  - Server Hello：服务器选定参数
  - Certificate：服务器证书（CN=httpbin.org）
  - Server Key Exchange：ECDHE 参数
  - Client Key Exchange + Change Cipher Spec + Finished
- 证书验证链：httpbin.org → Amazon RSA 2048 M03
- ALPN 协商：`curl offers h2,http/1.1` → `server accepted h2`
- 加密套件 ECDHE-RSA-AES128-GCM-SHA256 各部分含义表格
- mermaid sequence diagram 展示完整 TLS 握手流程

**Step 2: 格式化并提交**

Run: `npm run format`
Message: `docs(url-to-render): add TLS handshake chapter`

### Task 6: 编写第 6 章 HTTP 请求与响应 + sequence diagram

**Files:**

- Modify: `docs/url-to-render-guide.md`

**Step 1: 编写第 6 章**

内容要点：

- `## 6. HTTP 请求与响应`
- 展示 curl 的 HTTP/2 请求头输出（伪头部 `:method`, `:scheme`, `:authority`, `:path`）
- HTTP/2 vs HTTP/1.1 对比表格
- 展示响应头和响应体
- 响应头分析：content-type, CORS headers, server
- mermaid sequence diagram：客户端 → 服务器请求响应

**Step 2: 格式化并提交**

Run: `npm run format`
Message: `docs(url-to-render): add HTTP request and response chapter`

### Task 7: 编写第 7 章 服务器处理

**Files:**

- Modify: `docs/url-to-render-guide.md`

**Step 1: 编写第 7 章**

内容要点：

- `## 7. 服务器处理`
- 对照 curl：`server: gunicorn/19.9.0`
- 请求在服务器端的处理链路：反向代理(Nginx) → WSGI 服务器(gunicorn) → Web 应用(Flask)
- 简述典型的 Web 服务器架构

**Step 2: 格式化并提交**

Run: `npm run format`
Message: `docs(url-to-render): add server processing chapter`

### Task 8: 编写第 8 章 浏览器解析与渲染 + flowchart

**Files:**

- Modify: `docs/url-to-render-guide.md`

**Step 1: 编写第 8 章**

这是前端重点章节。

内容要点：

- `## 8. 浏览器解析与渲染`
- 说明此阶段超出 curl 观测范围，进入浏览器内部
- HTML 解析 → DOM 树构建
- CSS 解析 → CSSOM 树构建
- DOM + CSSOM → Render Tree
- Layout（回流）：计算每个节点的几何信息
- Paint（重绘）：将节点绘制为像素
- Composite（合成）：GPU 合成图层
- script 和 link 标签对解析的阻塞影响（async/defer）
- mermaid flowchart：渲染管线流程
- 用表格对比 async vs defer vs 普通 script

**Step 2: 格式化并提交**

Run: `npm run format`
Message: `docs(url-to-render): add browser parsing and rendering chapter`

### Task 9: 编写第 9 章 总结 + 更新 index.md

**Files:**

- Modify: `docs/url-to-render-guide.md`
- Modify: `docs/index.md`

**Step 1: 编写第 9 章总结**

内容要点：

- `## 9. 总结`
- 全流程速查表（表格形式）
- 30 秒面试回答模板（引用块）
- 常见追问及应对方向（3-5 个典型追问）
- 参考资源链接

**Step 2: 更新 index.md**

在 `docs/index.md` 中添加本文链接。

**Step 3: 格式化并提交**

Run: `npm run format`
Message: `docs(url-to-render): add summary and update index`

### Task 10: 全文审校

**Files:**

- Modify: `docs/url-to-render-guide.md`

**Step 1: 自我审校**

检查项：

- 章节编号连续性
- mermaid 图语法正确性（6 张图齐全）
- curl 输出片段与讲解对应
- 中文表述流畅性
- tech-docs-guide 规范合规性（标题格式、代码块标注、提示信息格式）

**Step 2: 验证信息准确性**

通过 web fetch 验证：

- TLS 1.2 握手流程准确性
- HTTP/2 伪头部规范
- 浏览器渲染管线流程

**Step 3: 修复问题并提交**

Run: `npm run format`
Message: `docs(url-to-render): review and polish full guide`
