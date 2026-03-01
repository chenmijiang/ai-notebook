# curl 使用指南

curl 是命令行下最通用的 HTTP 请求工具，几乎所有操作系统都预装了它，是前端开发者调试接口的必备技能。

## 1. 概述

### 1.1 什么是 curl

curl（Client URL）是一个通过 URL 传输数据的命令行工具，支持 HTTP、HTTPS、FTP 等多种协议，常用于发送 HTTP 请求和调试 API 接口。

### 1.2 前端为什么需要 curl

| 对比项       | curl                | Postman           | fetch/axios          |
| ------------ | ------------------- | ----------------- | -------------------- |
| 运行环境     | 终端（系统自带）    | 需安装 GUI 客户端 | 需浏览器或 Node 环境 |
| 启动速度     | 即时                | 较慢              | 需编写代码           |
| 脚本集成     | ✅ 可直接写入脚本   | ❌ 不方便         | ✅ 需编程            |
| 分享命令     | ✅ 一行文本即可复制 | 需导出 Collection | 需贴代码段           |
| CI/CD 中使用 | ✅ 原生支持         | ❌ 需要额外工具   | ❌ 需编写脚本        |
| 学习成本     | 中等                | 低                | 低                   |

> **提示**：浏览器 DevTools 的 Network 面板可右键复制请求为 `Copy as cURL`，直接在终端重放，非常适合排查线上问题。

## 2. 基础请求

### 2.1 发送 GET 请求

你想发送一个最简单的 GET 请求：

```bash
curl https://httpbin.org/get
```

你想带查询参数请求：

```bash
# 直接拼接在 URL 中
curl "https://httpbin.org/get?name=hello&page=1"
```

> **注意**：URL 含 `&` 等特殊字符时必须加引号，否则 shell 会截断命令。

你想只看响应体、不看进度条：

```bash
# -s 静默模式，隐藏进度条
curl -s https://httpbin.org/get

# -s -S 静默但仍显示错误信息（推荐）
curl -sS https://httpbin.org/get
```

常用搭配选项：

| 选项 | 含义                    | 示例                                  |
| ---- | ----------------------- | ------------------------------------- |
| `-s` | 静默模式，不显示进度条  | `curl -s URL`                         |
| `-S` | 配合 `-s`，出错时仍提示 | `curl -sS URL`                        |
| `-o` | 输出到文件              | `curl -o result.json URL`             |
| `-O` | 用远程文件名保存        | `curl -O URL/file.tar.gz`             |
| `-L` | 跟随重定向              | `curl -L URL`                         |
| `-v` | 显示详细请求/响应头     | `curl -v URL`                         |
| `-i` | 输出中包含响应头        | `curl -i URL`                         |
| `-w` | 自定义输出格式          | `curl -w "%{http_code}" -o /dev/null` |

## 3. 发送数据

### 3.1 POST JSON

你想向接口提交 JSON 数据：

```bash
curl -X POST https://httpbin.org/post \
  -H "Content-Type: application/json" \
  -d '{"name":"张三","age":25}'
```

| 选项      | 含义           |
| --------- | -------------- |
| `-X POST` | 指定 HTTP 方法 |
| `-H`      | 添加请求头     |
| `-d`      | 发送请求体数据 |

> **提示**：使用 `-d` 时，curl 会自动将方法设为 POST，因此 `-X POST` 可以省略。

你想从文件读取 JSON 发送：

```bash
curl https://httpbin.org/post \
  -H "Content-Type: application/json" \
  -d @data.json
```

### 3.2 表单提交

你想提交表单数据（`application/x-www-form-urlencoded`）：

```bash
curl -d "username=admin&password=123456" https://httpbin.org/post
```

你想对特殊字符自动编码：

```bash
# --data-urlencode 自动 URL 编码，每个参数单独一个 flag
curl --data-urlencode "query=hello world" \
     --data-urlencode "foo=bar" \
     https://httpbin.org/post
```

你想上传文件（`multipart/form-data`）：

```bash
curl -F "file=@photo.jpg" -F "name=头像" https://httpbin.org/post
```

| 选项               | Content-Type                      | 用途           |
| ------------------ | --------------------------------- | -------------- |
| `-d`               | application/x-www-form-urlencoded | 普通表单       |
| `--data-urlencode` | application/x-www-form-urlencoded | 含特殊字符表单 |
| `-F`               | multipart/form-data               | 文件上传       |

### 3.3 其他 HTTP 方法

你想发送 PUT 请求更新资源：

```bash
curl -X PUT https://httpbin.org/put \
  -H "Content-Type: application/json" \
  -d '{"name":"李四","age":30}'
```

你想发送 PATCH 请求部分更新：

```bash
curl -X PATCH https://httpbin.org/patch \
  -H "Content-Type: application/json" \
  -d '{"age":31}'
```

你想发送 DELETE 请求删除资源：

```bash
curl -X DELETE https://httpbin.org/delete
```

## 4. 请求头与认证

### 4.1 自定义请求头

你想添加自定义请求头：

```bash
curl -H "X-Custom-Header: my-value" \
     -H "Accept: application/json" \
     https://httpbin.org/headers
```

你想同时设置多个请求头：

```bash
curl -H "Accept: application/json" \
     -H "Accept-Language: zh-CN" \
     -H "X-Request-ID: abc123" \
     https://httpbin.org/headers
```

### 4.2 Bearer Token 认证

你想携带 JWT Token 访问受保护接口：

```bash
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..." \
     https://httpbin.org/bearer
```

你想使用 HTTP Basic 认证：

```bash
curl -u username:password https://httpbin.org/basic-auth/username/password
```

| 认证方式     | curl 写法                            |
| ------------ | ------------------------------------ |
| Bearer Token | `-H "Authorization: Bearer <token>"` |
| Basic Auth   | `-u user:pass`                       |
| API Key      | `-H "X-API-Key: <key>"`              |

### 4.3 Cookie 操作

你想发送 Cookie：

```bash
curl -b "session=abc123; lang=zh-CN" https://httpbin.org/cookies
```

你想把服务器返回的 Cookie 保存到文件：

```bash
curl -c cookies.txt https://httpbin.org/cookies/set?name=value
```

你想读取之前保存的 Cookie 并发送：

```bash
curl -b cookies.txt https://httpbin.org/cookies
```

你想同时保存和发送 Cookie（模拟会话）：

```bash
# 第一次请求：登录并保存 Cookie
curl -c cookies.txt -d "user=admin&pass=123" https://example.com/login

# 第二次请求：携带 Cookie 访问
curl -b cookies.txt https://example.com/dashboard
```

| 选项 | 含义                     | 示例             |
| ---- | ------------------------ | ---------------- |
| `-b` | 发送 Cookie              | `-b "key=value"` |
| `-b` | 从文件读取 Cookie 发送   | `-b cookies.txt` |
| `-c` | 将响应 Cookie 保存到文件 | `-c cookies.txt` |

## 5. 文件上传与下载

### 5.1 上传文件

你想通过 multipart 方式上传文件：

```bash
curl -F "file=@/path/to/photo.jpg" https://httpbin.org/post
```

你想上传文件并附带额外字段：

```bash
curl -F "file=@report.pdf" \
     -F "description=月度报告" \
     -F "category=finance" \
     https://httpbin.org/post
```

你想指定上传文件的 MIME 类型：

```bash
curl -F "file=@data.csv;type=text/csv" https://httpbin.org/post
```

| 写法                           | 含义                 |
| ------------------------------ | -------------------- |
| `-F "file=@path"`              | 上传文件             |
| `-F "file=@path;type=mime"`    | 上传并指定 MIME 类型 |
| `-F "file=@path;filename=new"` | 上传并重命名文件     |

### 5.2 下载文件

你想下载文件并指定保存名称：

```bash
curl -o myfile.tar.gz https://example.com/file.tar.gz
```

你想使用远程文件名保存：

```bash
curl -O https://example.com/file.tar.gz
```

你想下载时显示进度条：

```bash
curl -# -O https://example.com/largefile.zip
```

| 选项 | 含义               | 示例                           |
| ---- | ------------------ | ------------------------------ |
| `-o` | 指定本地文件名保存 | `curl -o out.zip URL`          |
| `-O` | 使用远程文件名保存 | `curl -O URL/file.tar.gz`      |
| `-#` | 显示进度条         | `curl -# -O URL/largefile.zip` |

## 6. 调试技巧

### 6.1 查看详细信息

你想查看完整的请求和响应过程：

```bash
curl -v https://httpbin.org/get
```

输出包含：

| 前缀 | 含义       |
| ---- | ---------- |
| `>`  | 发送的请求 |
| `<`  | 收到的响应 |
| `*`  | 连接信息   |

### 6.2 只看响应头

你想只获取响应头（HEAD 请求）：

```bash
curl -I https://httpbin.org/get
```

你想在响应体前面显示响应头：

```bash
curl -i https://httpbin.org/get
```

| 选项 | 含义                         |
| ---- | ---------------------------- |
| `-I` | 只返回响应头（发送 HEAD）    |
| `-i` | 响应中包含头信息（显示全部） |

### 6.3 查看耗时

你想查看请求各阶段的耗时：

```bash
curl -o /dev/null -s -w "\
DNS 解析:  %{time_namelookup}s\n\
TCP 连接:  %{time_connect}s\n\
TLS 握手:  %{time_appconnect}s\n\
首字节:    %{time_starttransfer}s\n\
总耗时:    %{time_total}s\n" \
  https://httpbin.org/get
```

常用 `-w` 变量：

| 变量                    | 含义              |
| ----------------------- | ----------------- |
| `%{http_code}`          | HTTP 状态码       |
| `%{time_namelookup}`    | DNS 解析耗时      |
| `%{time_connect}`       | TCP 连接耗时      |
| `%{time_appconnect}`    | TLS 握手耗时      |
| `%{time_starttransfer}` | 首字节到达耗时    |
| `%{time_total}`         | 总耗时            |
| `%{size_download}`      | 下载数据大小（B） |

### 6.4 保存响应

你想把响应体保存到文件：

```bash
curl -o response.json https://httpbin.org/get
```

你想把响应头和响应体分别保存：

```bash
curl -D headers.txt -o body.json https://httpbin.org/get
```

| 选项 | 含义             | 示例             |
| ---- | ---------------- | ---------------- |
| `-o` | 保存响应体到文件 | `-o body.json`   |
| `-D` | 保存响应头到文件 | `-D headers.txt` |

## 7. 实用技巧

### 7.1 跟随重定向

你想让 curl 自动跟随 301/302 重定向：

```bash
curl -L https://httpbin.org/redirect/3
```

> **提示**：默认 curl 不跟随重定向，加 `-L` 后最多跟随 50 次。可用 `--max-redirs` 限制次数。

### 7.2 设置超时

你想设置连接超时和总超时：

```bash
# 连接超时 5 秒
curl --connect-timeout 5 https://httpbin.org/get

# 总超时 10 秒（包含传输时间）
curl --max-time 10 https://httpbin.org/get

# 组合使用（推荐）
curl --connect-timeout 5 --max-time 10 https://httpbin.org/get
```

| 选项                | 含义               |
| ------------------- | ------------------ |
| `--connect-timeout` | TCP 连接超时（秒） |
| `--max-time`        | 请求总超时（秒）   |

### 7.3 忽略 SSL 证书

你想在开发环境跳过 SSL 证书验证：

```bash
curl -k https://localhost:8443/api/test
```

> ❌ **警告**：`-k` 仅用于开发/测试环境，生产环境绝对不要使用，会导致中间人攻击风险。

### 7.4 使用代理

你想通过代理发送请求：

```bash
# HTTP 代理
curl -x http://proxy.example.com:8080 https://httpbin.org/get

# SOCKS5 代理
curl -x socks5://127.0.0.1:1080 https://httpbin.org/get
```

| 选项 | 含义     | 示例                         |
| ---- | -------- | ---------------------------- |
| `-x` | 设置代理 | `-x http://proxy:8080`       |
| `-x` | SOCKS5   | `-x socks5://127.0.0.1:1080` |

## 8. 总结

### 速查表

| 选项                | 用途             | 示例                                  |
| ------------------- | ---------------- | ------------------------------------- |
| `-X`                | 指定 HTTP 方法   | `-X POST`                             |
| `-H`                | 添加请求头       | `-H "Content-Type: application/json"` |
| `-d`                | 发送请求体       | `-d '{"key":"value"}'`                |
| `-F`                | 上传文件         | `-F "file=@path"`                     |
| `-o`                | 保存响应到文件   | `-o output.json`                      |
| `-O`                | 用远程文件名保存 | `-O`                                  |
| `-L`                | 跟随重定向       | `-L`                                  |
| `-v`                | 详细输出         | `-v`                                  |
| `-i`                | 包含响应头       | `-i`                                  |
| `-I`                | 只看响应头       | `-I`                                  |
| `-s`                | 静默模式         | `-s`                                  |
| `-w`                | 自定义输出格式   | `-w "%{http_code}"`                   |
| `-u`                | Basic 认证       | `-u user:pass`                        |
| `-b`                | 发送 Cookie      | `-b "key=value"`                      |
| `-c`                | 保存 Cookie      | `-c cookies.txt`                      |
| `-k`                | 忽略 SSL 证书    | `-k`                                  |
| `-x`                | 使用代理         | `-x http://proxy:8080`                |
| `--connect-timeout` | 连接超时         | `--connect-timeout 5`                 |
| `--max-time`        | 总超时           | `--max-time 10`                       |
| `--data-urlencode`  | URL 编码表单数据 | `--data-urlencode "q=hello world"`    |

### 参考资源

- [curl 官方文档](https://curl.se/docs/)
- [curl 命令手册](https://curl.se/docs/manpage.html)
- [Everything curl](https://everything.curl.dev/) — curl 作者编写的在线书籍
