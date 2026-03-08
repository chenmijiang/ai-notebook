# Dockerfile 与镜像构建完全指南

Dockerfile 是构建 Docker 镜像的蓝图——一个纯文本文件，通过一系列指令描述"如何从零搭建运行环境"。掌握 Dockerfile 的编写和构建优化，是从"使用现成镜像"到"定制自己的镜像"的关键一步。本指南聚焦于 Dockerfile 的编写、构建机制和优化策略，帮助你写出高效、安全、可维护的镜像构建文件。

> 本篇是 Docker 系列（共 7 篇）的第 4 篇。上一篇：[Docker 容器管理完全指南](docker-3-containers.md)。下一篇：[Docker 网络完全指南](docker-5-networking.md)。

## 1. Dockerfile 基础

### 1.1 Dockerfile 是什么

Dockerfile 是一个纯文本文件（无扩展名），包含一组按顺序执行的指令。Docker 读取这些指令，逐步构建出一个镜像。每条指令对应镜像中的一层或一条元数据配置。

```
Dockerfile          docker build         镜像
┌──────────────┐   ─────────────→   ┌──────────────┐
│ FROM node    │                    │ Layer 1: node│
│ COPY . .     │                    │ Layer 2: 代码│
│ RUN npm i    │                    │ Layer 3: 依赖│
│ CMD ["node"] │                    │ 元数据: CMD  │
└──────────────┘                    └──────────────┘
```

**Dockerfile 的核心规则**：

| 规则         | 说明                                                |
| ------------ | --------------------------------------------------- |
| 文件名       | 默认为 `Dockerfile`（区分大小写），无扩展名         |
| 指令格式     | `指令 参数`，指令不区分大小写，但约定全大写         |
| 执行顺序     | 从上到下逐条执行                                    |
| 注释         | 以 `#` 开头的行为注释                               |
| 第一条指令   | 必须是 `FROM`（`ARG` 和解析器指令除外）             |
| 每条指令一层 | `RUN`、`COPY`、`ADD` 创建新层；其他指令只修改元数据 |

### 1.2 第一个 Dockerfile

以一个简单的 Node.js API 为例：

```dockerfile
# 基础镜像
FROM node:22-slim

# 设置工作目录
WORKDIR /app

# 复制依赖声明文件
COPY package.json package-lock.json ./

# 安装依赖
RUN npm ci

# 复制应用代码
COPY . .

# 声明端口
EXPOSE 3000

# 启动命令
CMD ["node", "server.js"]
```

构建并运行：

```bash
# 构建镜像（-t 指定名称和标签，. 表示构建上下文为当前目录）
docker build -t my-api:1.0 .

# 运行容器
docker run -d --name api -p 8080:3000 my-api:1.0
```

> **提示**：`docker build` 命令的最后一个参数 `.` 不是 Dockerfile 的路径，而是**构建上下文**（Build Context）的路径。构建上下文决定了 `COPY` 和 `ADD` 能访问哪些文件，详见第 4 节。

## 2. 指令详解

### 2.1 FROM

`FROM` 指定基础镜像，是 Dockerfile 的起点。所有后续指令都在这个基础镜像之上执行。

```dockerfile
# 基本用法
FROM nginx:1.27

# 指定平台（跨平台构建）
FROM --platform=linux/amd64 node:22-slim

# 多阶段构建中命名阶段
FROM node:22-slim AS builder

# 使用 ARG 动态选择基础镜像
ARG NODE_VERSION=22
FROM node:${NODE_VERSION}-slim
```

**选择基础镜像的原则**：

| 原则         | 说明                                                    |
| ------------ | ------------------------------------------------------- |
| 用官方镜像   | 安全可靠，定期更新（详见[第 2 篇](docker-2-images.md)） |
| 锁定版本     | 使用 `node:22-slim` 而非 `node:latest`                  |
| 选择精简变体 | 优先 `-slim` 或 `-alpine`，减小镜像体积                 |

### 2.2 RUN

`RUN` 在构建时执行命令，结果写入新的镜像层。

```dockerfile
# Shell 形式（通过 /bin/sh -c 执行，支持管道和变量替换）
RUN apt-get update && apt-get install -y curl

# Exec 形式（直接执行，不经过 Shell）
RUN ["apt-get", "install", "-y", "curl"]
```

**最佳实践——合并 RUN 指令减少层数**：

```dockerfile
# ❌ 坏的实践：每条命令一层，且残留 apt 缓存
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y git

# ✅ 好的实践：合并命令 + 清理缓存
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      curl \
      git && \
    rm -rf /var/lib/apt/lists/*
```

> **注意**：`RUN apt-get update` 和 `apt-get install` 必须在同一条 `RUN` 指令中。如果分开写，`apt-get update` 创建的层会被缓存，后续修改 install 列表时不会重新 update，导致安装失败。

### 2.3 COPY 与 ADD

`COPY` 将文件从构建上下文复制到镜像中，是最常用的文件传输指令。

```dockerfile
# 复制单个文件
COPY package.json /app/

# 复制多个文件
COPY package.json package-lock.json /app/

# 复制整个目录
COPY src/ /app/src/

# 使用通配符
COPY *.json /app/

# 设置文件权限（BuildKit）
COPY --chmod=755 entrypoint.sh /app/

# 设置文件归属
COPY --chown=node:node . /app/

# 从其他构建阶段复制（多阶段构建）
COPY --from=builder /app/dist /usr/share/nginx/html
```

`ADD` 与 `COPY` 类似，但额外支持自动解压和远程 URL：

```dockerfile
# 自动解压本地 tar 文件
ADD archive.tar.gz /app/

# 从 URL 下载文件（不推荐，优先用 RUN curl）
ADD https://example.com/file.txt /app/
```

> **提示**：大多数场景使用 `COPY` 即可。`ADD` 的隐式解压行为容易造成困惑，建议只在需要自动解压 tar 包时使用。详细对比见第 3.1 节。

### 2.4 WORKDIR

`WORKDIR` 设置后续指令的工作目录。如果目录不存在，Docker 会自动创建。

```dockerfile
WORKDIR /app

# 后续指令的路径都相对于 /app
COPY package.json .         # 复制到 /app/package.json
RUN npm ci                  # 在 /app 目录下执行
COPY . .                    # 复制到 /app/

# 可以多次使用，路径会叠加
WORKDIR /app
WORKDIR src
RUN pwd
# 输出：/app/src
```

```dockerfile
# ❌ 坏的实践：使用 RUN cd（cd 效果不会跨指令保留）
RUN cd /app && npm install

# ✅ 好的实践：使用 WORKDIR
WORKDIR /app
RUN npm install
```

### 2.5 ENV 与 ARG

`ENV` 设置环境变量，在构建时和容器运行时**都**可用。

```dockerfile
# 设置环境变量
ENV NODE_ENV=production
ENV APP_PORT=3000

# 后续指令中可以引用
RUN echo "环境: $NODE_ENV"
EXPOSE $APP_PORT
```

`ARG` 定义构建时变量，**只在构建阶段可用**，不会保留到运行时。

```dockerfile
# 定义构建参数（可带默认值）
ARG NODE_VERSION=22
ARG BUILD_DATE

# 在 FROM 之前使用
ARG NODE_VERSION=22
FROM node:${NODE_VERSION}-slim

# 构建时传入参数
# docker build --build-arg NODE_VERSION=20 --build-arg BUILD_DATE=2026-03-08 .
```

> **注意**：不要用 `ARG` 传递密码、密钥等敏感信息——构建参数可通过 `docker history` 查看。敏感数据应使用 BuildKit 的 `--mount=type=secret`（见第 8.3 节）。

### 2.6 EXPOSE

`EXPOSE` 声明容器运行时监听的端口，是一种**文档性质的标注**，并不会实际发布端口。

```dockerfile
# 声明 TCP 端口（默认协议）
EXPOSE 80

# 声明 UDP 端口
EXPOSE 53/udp

# 声明多个端口
EXPOSE 80 443
```

```bash
# EXPOSE 不等于端口映射，运行时仍需 -p 参数
docker run -d -p 8080:80 my-app

# 使用 -P 自动映射所有 EXPOSE 声明的端口到宿主机随机端口
docker run -d -P my-app
```

> **提示**：`EXPOSE` 的作用是告诉使用者"这个镜像的容器会监听哪些端口"，方便 `docker run -P` 自动映射和文档说明。实际的端口发布和网络配置将在[第 5 篇](docker-5-networking.md)详细介绍。

### 2.7 CMD 与 ENTRYPOINT

`CMD` 指定容器启动时的默认命令。一个 Dockerfile 中只有最后一条 `CMD` 生效。

```dockerfile
# Exec 形式（推荐——直接执行，能正确接收信号）
CMD ["node", "server.js"]

# Shell 形式（通过 /bin/sh -c 执行）
CMD node server.js
```

`ENTRYPOINT` 指定容器的入口程序，使容器表现得像一个可执行文件。

```dockerfile
# 固定入口程序，CMD 提供默认参数
ENTRYPOINT ["node"]
CMD ["server.js"]

# docker run my-app                → node server.js
# docker run my-app worker.js      → node worker.js（CMD 被覆盖）
```

**实际应用场景**：

```dockerfile
# 场景一：简单应用——只用 CMD
CMD ["nginx", "-g", "daemon off;"]

# 场景二：需要初始化脚本——ENTRYPOINT + CMD
COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["entrypoint.sh"]
CMD ["node", "server.js"]
# entrypoint.sh 可以做环境检查、数据库迁移等初始化工作，然后 exec "$@" 执行 CMD
```

> **注意**：强烈建议使用 Exec 形式 `["executable", "param"]`。Shell 形式会以 `/bin/sh -c` 启动，导致应用不是 PID 1 进程，无法正确接收 SIGTERM 信号，影响容器的优雅关闭。

### 2.8 HEALTHCHECK

`HEALTHCHECK` 在 Dockerfile 中声明容器的健康检查命令，让 Docker 自动监测应用是否正常运行。

```dockerfile
# 基本语法
HEALTHCHECK [选项] CMD <命令>

# 禁用健康检查（覆盖基础镜像中的 HEALTHCHECK）
HEALTHCHECK NONE
```

**完整示例**：

```dockerfile
# Node.js API 健康检查
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Nginx 健康检查
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD curl -f http://localhost:80/ || exit 1
```

**HEALTHCHECK 选项**：

| 选项               | 说明                             | 默认值 |
| ------------------ | -------------------------------- | ------ |
| `--interval`       | 检查间隔                         | 30s    |
| `--timeout`        | 单次检查超时时间                 | 30s    |
| `--start-period`   | 启动等待期（期间失败不计入重试） | 0s     |
| `--start-interval` | 启动期间的检查间隔               | 5s     |
| `--retries`        | 连续失败多少次判定为 unhealthy   | 3      |

**健康检查命令退出码**：

| 退出码 | 含义                |
| ------ | ------------------- |
| 0      | 健康（healthy）     |
| 1      | 不健康（unhealthy） |
| 2      | 保留值，不要使用    |

> **提示**：Dockerfile 中的 `HEALTHCHECK` 是声明式的默认配置，运行时可通过 `docker run --health-cmd` 等参数覆盖。关于运行时如何查看和排障健康状态，详见[第 3 篇](docker-3-containers.md)第 8 节。

## 3. 指令对比

### 3.1 COPY vs ADD

| 对比项        | COPY         | ADD                  |
| ------------- | ------------ | -------------------- |
| 基本复制      | ✅ 支持      | ✅ 支持              |
| 自动解压 tar  | ❌ 不支持    | ✅ 本地 tar 自动解压 |
| 远程 URL      | ❌ 不支持    | ✅ 支持（但不推荐）  |
| 多阶段 --from | ✅ 支持      | ✅ 支持              |
| 行为可预测性  | 高——只做复制 | 低——隐式解压可能意外 |
| 推荐程度      | 日常首选     | 仅在需要解压时使用   |

```dockerfile
# ✅ 推荐：使用 COPY（行为明确）
COPY package.json /app/

# ✅ ADD 合理场景：需要自动解压
ADD rootfs.tar.gz /

# ❌ 不推荐：用 ADD 下载远程文件（无法利用缓存，且不会自动解压）
ADD https://example.com/app.tar.gz /app/

# ✅ 替代方案：RUN curl + tar（可控、可缓存）
RUN curl -fsSL https://example.com/app.tar.gz | tar -xz -C /app/
```

### 3.2 CMD vs ENTRYPOINT

| 对比项          | CMD                        | ENTRYPOINT                   |
| --------------- | -------------------------- | ---------------------------- |
| 作用            | 提供默认命令或默认参数     | 指定入口程序                 |
| docker run 覆盖 | 完全覆盖                   | 需要 `--entrypoint` 才能覆盖 |
| 多条指令        | 只有最后一条生效           | 只有最后一条生效             |
| 配合使用        | 给 ENTRYPOINT 提供默认参数 | 接收 CMD 作为参数            |

**ENTRYPOINT 与 CMD 的组合行为**：

| ENTRYPOINT          | CMD                  | 实际执行                    |
| ------------------- | -------------------- | --------------------------- |
| 未设置              | `["node", "app.js"]` | `node app.js`               |
| `["node"]`          | `["server.js"]`      | `node server.js`            |
| `["node"]`          | 未设置               | `node`                      |
| `["entrypoint.sh"]` | `["node", "app.js"]` | `entrypoint.sh node app.js` |

```dockerfile
# 模式一：只用 CMD（大多数简单应用）
FROM node:22-slim
WORKDIR /app
COPY . .
CMD ["node", "server.js"]

# docker run my-app                → node server.js
# docker run my-app node worker.js → node worker.js（覆盖 CMD）

# 模式二：ENTRYPOINT + CMD（需要初始化或固定入口）
FROM node:22-slim
WORKDIR /app
COPY . .
ENTRYPOINT ["node"]
CMD ["server.js"]

# docker run my-app                → node server.js
# docker run my-app worker.js      → node worker.js（CMD 被覆盖，ENTRYPOINT 保留）
```

### 3.3 ARG vs ENV

| 对比项         | ARG                    | ENV                    |
| -------------- | ---------------------- | ---------------------- |
| 可用阶段       | 仅构建时               | 构建时 + 运行时        |
| 进入镜像       | 不进入最终镜像         | 写入镜像元数据         |
| docker history | 可见（不要放敏感信息） | 可见                   |
| 运行时覆盖     | 不可（不存在于运行时） | `docker run -e` 可覆盖 |
| 声明位置       | 可在 FROM 之前         | 只能在 FROM 之后       |
| 跨阶段         | 需在每个阶段重新声明   | 只在声明的阶段内有效   |

```dockerfile
# ARG 用于构建时的动态配置
ARG NODE_VERSION=22
FROM node:${NODE_VERSION}-slim

ARG BUILD_ENV=production
RUN echo "构建环境: $BUILD_ENV"
# BUILD_ENV 不会出现在最终容器的环境变量中

# ENV 用于运行时的配置
ENV NODE_ENV=production
ENV APP_PORT=3000
# 容器启动后 echo $NODE_ENV 可以输出 production

# 组合使用：ARG 传入构建参数，ENV 固化为运行时变量
ARG VERSION=1.0.0
ENV APP_VERSION=$VERSION
```

## 4. 构建上下文

### 4.1 什么是构建上下文

执行 `docker build` 时，Docker 会将指定路径下的所有文件发送给 Docker daemon，这个文件集合就是**构建上下文（Build Context）**。Dockerfile 中的 `COPY` 和 `ADD` 只能访问构建上下文中的文件。

```bash
# . 表示当前目录为构建上下文
docker build -t my-app .

# 指定不同的构建上下文和 Dockerfile 位置
docker build -t my-app -f deploy/Dockerfile .
```

```
构建上下文（当前目录）
├── Dockerfile
├── package.json
├── src/
│   └── app.js
├── node_modules/     ← 不应发送（体积大）
├── .git/             ← 不应发送（无用）
└── .env              ← 不应发送（敏感信息）
```

> **注意**：构建上下文越大，构建启动越慢（Docker 需要先将整个上下文打包发送给 daemon）。如果看到 `Sending build context to Docker daemon  500MB`，说明上下文中包含了不必要的文件。

### 4.2 .dockerignore 配置

`.dockerignore` 文件告诉 Docker 在构建上下文中排除哪些文件，类似 `.gitignore`。

```bash
# .dockerignore 文件示例

# 依赖目录（镜像内会重新安装）
node_modules

# 构建产物（镜像内会重新构建）
dist
build

# 版本控制
.git
.gitignore

# 编辑器和 IDE 配置
.vscode
.idea
*.swp

# 环境变量文件（包含敏感信息）
.env
.env.*

# Docker 相关
Dockerfile
docker-compose*.yml
.dockerignore

# 日志和临时文件
*.log
tmp/

# 文档
README.md
docs/
```

**为什么 .dockerignore 很重要**：

| 好处         | 说明                                         |
| ------------ | -------------------------------------------- |
| 加快构建     | 减少上下文传输时间，node_modules 动辄数百 MB |
| 避免泄露     | 排除 `.env`、密钥等敏感文件                  |
| 防止缓存失效 | `.git` 目录的变化会导致 `COPY . .` 缓存失效  |
| 减小镜像体积 | 避免无用文件被 COPY 到镜像中                 |

## 5. 构建缓存

### 5.1 缓存工作原理

Docker 构建镜像时，会为每条指令检查是否存在可复用的缓存层。如果某层的输入没有变化，Docker 直接使用缓存，跳过实际执行。

```
指令 1: FROM node:22-slim       → 检查基础镜像是否一致 → ✅ 使用缓存
指令 2: WORKDIR /app             → 检查指令文本是否一致 → ✅ 使用缓存
指令 3: COPY package.json .      → 检查文件内容是否变化 → ✅ 使用缓存
指令 4: RUN npm ci               → 上一层使用了缓存    → ✅ 使用缓存
指令 5: COPY . .                 → 检查文件内容是否变化 → ❌ 源码改了，缓存失效
指令 6: CMD ["node", "server.js"]→ 上一层缓存失效      → ❌ 重新执行
```

构建输出中可以看到缓存命中情况：

```
=> CACHED [2/5] WORKDIR /app
=> CACHED [3/5] COPY package.json .
=> CACHED [4/5] RUN npm ci
=> [5/5] COPY . .
```

### 5.2 缓存失效规则

| 规则         | 说明                                            |
| ------------ | ----------------------------------------------- |
| 指令文本变化 | `RUN` 指令的命令字符串改变，缓存失效            |
| 文件内容变化 | `COPY`/`ADD` 对应的源文件内容发生变化，缓存失效 |
| 级联失效     | 某一层缓存失效后，所有后续层的缓存全部失效      |
| 基础镜像变化 | `FROM` 指定的基础镜像更新后，所有层缓存失效     |
| `--no-cache` | `docker build --no-cache` 强制忽略所有缓存      |

> **注意**：级联失效是缓存优化的核心考量。一旦某层变了，它后面的所有层都必须重新构建，即使那些层的输入实际上没有变化。

### 5.3 优化构建顺序

利用缓存机制，将**变化频率低的指令放前面，变化频率高的放后面**：

```dockerfile
# ❌ 坏的顺序：代码一改，npm ci 就要重新执行
FROM node:22-slim
WORKDIR /app
COPY . .
RUN npm ci
CMD ["node", "server.js"]

# 问题分析：
# COPY . . 包含了所有源码文件
# 任何一个 .js 文件修改 → COPY . . 缓存失效 → RUN npm ci 重新执行
# 但 package.json 并没有变，npm ci 完全不需要重跑
```

```dockerfile
# ✅ 好的顺序：先复制依赖声明，安装依赖，再复制源码
FROM node:22-slim
WORKDIR /app

# 第一步：只复制依赖相关文件（变化频率低）
COPY package.json package-lock.json ./

# 第二步：安装依赖（只有 package.json 变了才重新执行）
RUN npm ci

# 第三步：复制源码（变化频率高）
COPY . .

CMD ["node", "server.js"]

# 修改 src/app.js 时：
# COPY package.json → ✅ 缓存命中
# RUN npm ci        → ✅ 缓存命中（省下数十秒甚至数分钟）
# COPY . .          → ❌ 重新执行（秒级完成）
```

**缓存优化原则**：

```
变化频率低的指令                                    变化频率高的指令
─────────────────────────────────────────────────────────────→

FROM         COPY            RUN            COPY      CMD
(基础镜像)   (package.json)  (npm ci)       (源码)    (启动命令)
```

## 6. 多阶段构建

### 6.1 为什么需要多阶段构建

前端项目构建需要 Node.js、npm 等工具，但运行时只需要一个 Web 服务器提供静态文件。如果把构建工具也打包进最终镜像，会造成体积膨胀和安全隐患。

```dockerfile
# ❌ 单阶段构建：最终镜像包含 Node.js + 构建工具 + 源码（约 1 GB+）
FROM node:22-slim
WORKDIR /app
COPY . .
RUN npm ci && npm run build
# 最终镜像包含：node_modules、源码、构建工具...全都不需要
CMD ["npx", "serve", "dist"]
```

多阶段构建通过多个 `FROM` 指令定义多个阶段，最终镜像只包含运行所需的文件：

```
阶段 1: 构建（builder）          阶段 2: 运行（最终镜像）
┌──────────────────────┐        ┌──────────────────────┐
│ Node.js              │        │ Nginx                │
│ npm                  │  COPY  │                      │
│ 源码                 │ ─────→ │ dist/（静态文件）     │
│ node_modules         │ 只取   │                      │
│ dist/（构建产物）    │ dist/  │ 约 40 MB             │
│ 约 1 GB+             │        └──────────────────────┘
└──────────────────────┘
```

### 6.2 多阶段构建语法

```dockerfile
# ---- 阶段 1：构建 ----
FROM node:22-slim AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# ---- 阶段 2：运行 ----
FROM nginx:1.27-alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**关键语法**：

| 语法                     | 说明                 |
| ------------------------ | -------------------- |
| `FROM ... AS <名称>`     | 为构建阶段命名       |
| `COPY --from=<名称>`     | 从指定阶段复制文件   |
| `COPY --from=nginx:1.27` | 也可以从外部镜像复制 |

```bash
# 构建完整镜像
docker build -t my-app:1.0 .

# 只构建到指定阶段（用于调试）
docker build --target builder -t my-app:builder .
```

### 6.3 前端项目多阶段构建

以 React（Vite 构建）项目为例，一个基本的多阶段 Dockerfile：

```dockerfile
# ---- 阶段 1：安装依赖 + 构建 ----
FROM node:22-slim AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# ---- 阶段 2：Nginx 提供静态文件服务 ----
FROM nginx:1.27-alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

> **提示**：通过多阶段构建，最终镜像从约 1 GB（Node.js + 源码）缩减到约 40 MB（Alpine Nginx + 静态文件），体积减少超过 95%。下一节将展示包含 Nginx 配置、健康检查、安全加固的完整实战版本。

## 7. 前端项目实战

### 7.1 React SPA Dockerfile

完整的生产级 React（Vite）项目 Dockerfile，在基本多阶段构建的基础上增加了构建参数、Nginx 配置、安全加固和健康检查：

```dockerfile
# ---- 阶段 1：构建 ----
FROM node:22-slim AS builder

WORKDIR /app

# 安装依赖（利用缓存分层）
COPY package.json package-lock.json ./
RUN npm ci

# 传入构建时变量（如 API 地址）
ARG VITE_API_URL=/api
ENV VITE_API_URL=$VITE_API_URL

# 复制源码并构建
COPY . .
RUN npm run build

# ---- 阶段 2：运行 ----
FROM nginx:1.27-alpine

# Nginx 配置
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 构建产物
COPY --from=builder /app/dist /usr/share/nginx/html

# 安全：设置文件归属
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown nginx:nginx /var/run/nginx.pid

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD curl -f http://localhost:80/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
```

### 7.2 Nginx 配置

为 React SPA 提供的 Nginx 配置（处理前端路由和缓存策略）：

```nginx
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # SPA 路由：所有路径回退到 index.html
    location / {
        try_files $uri $uri/ /index.html;
    }

    # 静态资源缓存（Vite 构建的文件名包含 hash）
    location /assets/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # 禁止缓存 index.html（确保更新及时生效）
    location = /index.html {
        expires -1;
        add_header Cache-Control "no-cache";
    }

    # Gzip 压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml;
    gzip_min_length 1024;
}
```

### 7.3 完整示例

项目目录结构：

```
my-app/
├── Dockerfile
├── .dockerignore
├── nginx.conf
├── package.json
├── package-lock.json
├── src/
│   ├── App.tsx
│   ├── main.tsx
│   └── ...
├── public/
│   └── favicon.ico
└── vite.config.ts
```

`.dockerignore` 文件：

```bash
node_modules
dist
.git
.gitignore
.vscode
.env
.env.*
*.md
docker-compose*.yml
Dockerfile
.dockerignore
```

构建与运行：

```bash
# 构建镜像
docker build -t my-app:1.0 .

# 传入构建参数（如 API 地址）
docker build --build-arg VITE_API_URL=https://api.example.com -t my-app:1.0 .

# 运行容器（前端 3000→80）
docker run -d --name web -p 3000:80 my-app:1.0

# 验证
curl http://localhost:3000
```

查看镜像信息：

```bash
# 查看最终镜像大小
docker images my-app:1.0
# REPOSITORY   TAG   IMAGE ID       CREATED         SIZE
# my-app       1.0   a1b2c3d4e5f6   10 seconds ago  45MB

# 查看构建历史
docker history my-app:1.0
```

## 8. 构建优化

### 8.1 减小镜像体积

| 策略               | 效果     | 示例                             |
| ------------------ | -------- | -------------------------------- |
| 多阶段构建         | 显著减小 | 只复制构建产物到最终镜像         |
| 使用精简基础镜像   | 显著减小 | `node:22-slim` 替代 `node:22`    |
| 合并 RUN 指令      | 中等减小 | 减少层数，统一清理缓存           |
| 清理包管理器缓存   | 中等减小 | `rm -rf /var/lib/apt/lists/*`    |
| .dockerignore 排除 | 避免增大 | 排除 node_modules、.git 等       |
| 生产依赖安装       | 中等减小 | `npm ci --omit=dev` 跳过开发依赖 |

```dockerfile
# ✅ 综合优化示例（Node.js API）
FROM node:22-slim AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:22-slim
WORKDIR /app
COPY package.json package-lock.json ./
# 只安装生产依赖
RUN npm ci --omit=dev && \
    npm cache clean --force
COPY --from=builder /app/dist ./dist
ENV NODE_ENV=production
EXPOSE 3000
CMD ["node", "dist/server.js"]
```

### 8.2 安全最佳实践

| 实践               | 说明                                      |
| ------------------ | ----------------------------------------- |
| 非 root 用户运行   | 避免容器内进程拥有 root 权限              |
| 不存储敏感信息     | 不在 Dockerfile 中硬编码密码、密钥        |
| 使用 COPY 而非 ADD | 行为更可预测，避免意外解压或下载          |
| 锁定基础镜像版本   | 使用 `node:22.14-slim` 而非 `node:latest` |
| 最小化安装         | `--no-install-recommends` 跳过推荐包      |
| 及时更新基础镜像   | 定期重新构建以获取安全补丁                |

```dockerfile
# ✅ 安全实践示例
FROM node:22-slim

# 创建非 root 用户
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY . .

# 设置文件归属并切换用户
RUN chown -R appuser:appuser /app
USER appuser

EXPOSE 3000
CMD ["node", "server.js"]
```

> **注意**：`USER` 指令之后的所有 `RUN`、`CMD`、`ENTRYPOINT` 都以该用户身份执行。需要 root 权限的操作（如安装系统包）应放在 `USER` 之前。

### 8.3 BuildKit 简介

BuildKit 是 Docker 的新一代构建引擎（Docker 23.0+ 默认启用），提供更快的构建速度和高级特性。

```bash
# 确认 BuildKit 是否启用
docker buildx version

# 手动启用 BuildKit（Docker 23.0 之前的版本）
DOCKER_BUILDKIT=1 docker build -t my-app .
```

**缓存挂载（`--mount=type=cache`）**：

将包管理器的缓存目录持久化，跨构建复用，避免每次都重新下载依赖。

```dockerfile
# npm 缓存挂载
RUN --mount=type=cache,target=/root/.npm \
    npm ci

# apt 缓存挂载
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y curl
```

**密钥挂载（`--mount=type=secret`）**：

安全地在构建中使用密钥，不会留在镜像层中。

```dockerfile
# Dockerfile 中使用 secret
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc \
    npm ci
```

```bash
# 构建时传入 secret 文件
docker build --secret id=npmrc,src=.npmrc -t my-app .
```

**BuildKit 特性总结**：

| 特性                  | 说明                                  |
| --------------------- | ------------------------------------- |
| `--mount=type=cache`  | 跨构建缓存包管理器下载，加速依赖安装  |
| `--mount=type=secret` | 安全传递密钥，不残留在镜像中          |
| `--mount=type=ssh`    | 转发 SSH agent，用于拉取私有 Git 仓库 |
| 并行构建              | 自动并行执行无依赖关系的构建阶段      |
| 更好的缓存            | 更精细的缓存策略和垃圾回收            |

> **提示**：以上 BuildKit 特性属于进阶内容。对于大多数项目，掌握多阶段构建和缓存顺序优化已经足够。当构建速度成为瓶颈时，再考虑引入 `--mount=type=cache` 等特性。

## 9. 总结

### 9.1 核心要点

- **Dockerfile 本质**：纯文本构建脚本，通过指令描述镜像的组装过程，每条 `RUN`/`COPY`/`ADD` 创建一个镜像层
- **核心指令**：`FROM` 选基础镜像、`RUN` 执行命令、`COPY` 复制文件、`WORKDIR` 设工作目录、`CMD` 定义启动命令
- **指令选择**：复制文件用 `COPY`（不用 `ADD`），启动命令用 Exec 形式 `["cmd", "arg"]`（不用 Shell 形式）
- **缓存优化**：变化频率低的指令放前面（依赖安装），变化频率高的放后面（源码复制）
- **多阶段构建**：分离构建环境和运行环境，大幅减小最终镜像体积
- **安全实践**：使用非 root 用户、锁定基础镜像版本、不硬编码敏感信息
- **.dockerignore**：排除 node_modules、.git、.env 等文件，加速构建并避免泄露

### 9.2 速查表

| 指令                             | 说明                                |
| -------------------------------- | ----------------------------------- |
| `FROM <镜像>:<标签>`             | 指定基础镜像                        |
| `FROM <镜像> AS <名称>`          | 命名构建阶段（多阶段构建）          |
| `RUN <命令>`                     | 构建时执行命令，创建新层            |
| `COPY <源> <目标>`               | 从构建上下文复制文件到镜像          |
| `COPY --from=<阶段> <源> <目标>` | 从其他构建阶段复制文件              |
| `ADD <源> <目标>`                | 复制文件（支持解压 tar 和远程 URL） |
| `WORKDIR <路径>`                 | 设置工作目录                        |
| `ENV <键>=<值>`                  | 设置环境变量（构建 + 运行时）       |
| `ARG <名称>=<默认值>`            | 定义构建参数（仅构建时）            |
| `EXPOSE <端口>`                  | 声明容器监听端口（文档性质）        |
| `CMD ["可执行文件", "参数"]`     | 容器启动默认命令                    |
| `ENTRYPOINT ["可执行文件"]`      | 容器入口程序                        |
| `HEALTHCHECK CMD <命令>`         | 定义健康检查命令                    |
| `HEALTHCHECK NONE`               | 禁用健康检查                        |
| `USER <用户>`                    | 切换运行用户                        |

**构建命令速查**：

| 命令                                         | 说明                     |
| -------------------------------------------- | ------------------------ |
| `docker build -t <名称>:<标签> .`            | 构建镜像                 |
| `docker build -f <Dockerfile路径> .`         | 指定 Dockerfile 位置     |
| `docker build --build-arg <键>=<值> .`       | 传入构建参数             |
| `docker build --target <阶段> .`             | 只构建到指定阶段         |
| `docker build --no-cache .`                  | 忽略缓存重新构建         |
| `docker build --secret id=<名>,src=<文件> .` | 传入密钥文件（BuildKit） |

## 参考资源

- [Dockerfile 参考文档](https://docs.docker.com/reference/dockerfile/)
- [docker build 命令参考](https://docs.docker.com/reference/cli/docker/image/build/)
- [多阶段构建](https://docs.docker.com/build/building/multi-stage/)
- [构建缓存优化](https://docs.docker.com/build/cache/)
- [BuildKit 文档](https://docs.docker.com/build/buildkit/)
- [.dockerignore 参考](https://docs.docker.com/build/concepts/context/#dockerignore-files)
- [Docker 安全最佳实践](https://docs.docker.com/build/building/best-practices/)
