# 从浏览器输入 URL 到网页渲染完整流程 - 设计文档

## 概述

面向准备面试的前端开发者，编写一篇系统讲解"从输入 URL 到页面渲染"全流程的中文技术博客。以 `curl -v https://httpbin.org/get` 的真实输出作为实证工具，每个网络阶段对照 curl 输出讲解，让读者可在终端验证。

## 目标读者

准备面试的前端开发者

## 方案选择

采用**时间线叙事**方案，按请求时间顺序逐步推进，与面试回答逻辑一致。

## 文件

`docs/url-to-render-guide.md`

## 博客结构

### 第 1 章 概述

- 一句话概括全流程
- 全局 flowchart（mermaid）
- 引入 `curl -v` 作为贯穿全文的观测工具，附完整输出

### 第 2 章 URL 解析

- 拆解 `https://httpbin.org/get`：协议(https)、域名(httpbin.org)、隐含端口(443)、路径(/get)
- 浏览器判断是搜索还是 URL
- HSTS 检查

### 第 3 章 DNS 解析

- 缓存层级：浏览器 → OS → 路由器 → ISP → 递归查询
- 对照 curl：`Host httpbin.org:443 was resolved. IPv4: 198.18.0.40`
- 提及 DNS over HTTPS 趋势
- mermaid sequence diagram：DNS 查询链

### 第 4 章 TCP 连接

- 三次握手 SYN / SYN-ACK / ACK
- 对照 curl：`Trying 198.18.0.40:443... Connected to httpbin.org`
- 简述为什么是三次而非两次
- mermaid sequence diagram：三次握手

### 第 5 章 TLS 握手（最详细章节）

- 逐条对照 curl 的 TLS 输出
- Client Hello → Server Hello → Certificate → Key Exchange → Change Cipher → Finished
- 证书验证链（Amazon RSA 2048 M03）
- ALPN 协商 HTTP/2
- 最终加密套件 ECDHE-RSA-AES128-GCM-SHA256 各部分含义
- mermaid sequence diagram：TLS 握手

### 第 6 章 HTTP 请求与响应

- HTTP/2 伪头部 vs HTTP/1.1 请求行
- 对照 curl 的 `[:method: GET] [:path: /get]` 等
- 响应头分析（content-type、CORS headers）
- mermaid sequence diagram：请求响应

### 第 7 章 服务器处理

- 简述反向代理 → WSGI → gunicorn → Flask 应用
- 对照 `server: gunicorn/19.9.0`

### 第 8 章 浏览器解析与渲染（前端重点章节）

- HTML 解析 → DOM 树
- CSS 解析 → CSSOM 树
- DOM + CSSOM → Render Tree
- Layout（回流）→ Paint（重绘）→ Composite（合成）
- script/link 标签对解析的阻塞影响
- mermaid flowchart：渲染管线

### 第 9 章 总结

- 30 秒面试回答模板
- 常见追问及应对方向

## Mermaid 图（共 6 张）

1. 全局流程 flowchart（总览）
2. DNS 查询 sequence diagram
3. TCP 三次握手 sequence diagram
4. TLS 握手 sequence diagram
5. HTTP 请求响应 sequence diagram
6. 浏览器渲染管线 flowchart

## 写作要求

- 中文撰写，遵循项目 tech-docs-guide 写作规范
- 每个网络阶段先展示对应的 curl 输出片段，再展开讲解
- mermaid 图紧跟对应章节
- 面试导向：突出"为什么"而不仅是"是什么"
