# Docker Compose 完全指南

前 6 篇中，我们学会了拉取镜像、编写 Dockerfile、启动容器、配置网络、挂载存储——但每次都要手敲一长串 `docker run` 命令，手动创建网络和 Volume，手动控制启动顺序。一旦服务多了，命令行管理就变得脆弱且不可重复。Docker Compose 用一个 YAML 文件把所有这些整合在一起：一条命令启动整个项目。本篇是系列的完结篇，不重复讲已有知识，而是用"回扣 + 链接"的方式将前文串联成一个完整可运行的项目。

> 本篇是 Docker 系列（共 7 篇）的第 7 篇（完结篇）。上一篇：[Docker 数据管理完全指南](docker-6-storage.md)。

## 1. Compose 概述

### 1.1 从单容器到多容器

前面 6 篇中，启动一个 4 服务项目需要这样做：

```bash
# 1. 创建网络（第 5 篇）
docker network create app-net

# 2. 创建 Volume（第 6 篇）
docker volume create pgdata

# 3. 启动数据库
docker run -d --name db --network app-net \
  -v pgdata:/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=myapp \
  postgres:16

# 4. 启动 Redis
docker run -d --name redis --network app-net redis:7

# 5. 构建并启动 API（第 4 篇）
docker build -t my-api ./my-api
docker run -d --name api --network app-net \
  -p 8080:3000 \
  -e DATABASE_URL=postgresql://postgres:secret@db:5432/myapp \
  -e REDIS_URL=redis://redis:6379 \
  my-api

# 6. 构建并启动前端（第 4 篇）
docker build -t my-app ./my-app
docker run -d --name web --network app-net \
  -p 3000:80 \
  my-app
```

6 条命令，4 个服务，还没算停止、删除、重建的操作。更关键的是：这些命令没有被记录在任何地方——换一台机器或换一个同事，就要从头摸索。

### 1.2 Compose 解决什么问题

Docker Compose 是一个声明式的多容器编排工具。它把上面的所有命令浓缩成一个 `compose.yml` 文件：

```
┌─────────────────────────────────┐
│         compose.yml             │
│                                 │
│  services:                      │
│    web:   (构建 + 端口 + 网络)  │
│    api:   (构建 + 端口 + 环境)  │
│    db:    (镜像 + 存储 + 环境)  │
│    redis: (镜像)                │
│                                 │
│  networks:                      │
│    app-net:                     │
│                                 │
│  volumes:                       │
│    pgdata:                      │
└─────────────────────────────────┘
         │
         ▼
  docker compose up -d   ← 一条命令搞定
```

**Compose 的核心价值**：

| 价值       | 说明                                                 |
| ---------- | ---------------------------------------------------- |
| 声明式配置 | 所有服务、网络、存储定义在一个文件中，版本可控       |
| 一键操作   | `up` 创建并启动所有资源，`down` 停止并清理           |
| 可重复     | 同一个 `compose.yml` 在任何环境都能得到相同结果      |
| 项目隔离   | 默认用目录名作为项目前缀，同一机器可运行多个独立项目 |
| 开发友好   | 支持 Bind Mount 热重载、环境变量管理、日志聚合       |

### 1.3 安装与版本

Docker Compose V2 是 Docker CLI 的插件，使用 `docker compose`（空格）命令。如果你使用 Docker Desktop（macOS / Windows），已经内置了。

```bash
# 检查版本
docker compose version
# Docker Compose version v2.32.4

# V1（已弃用）使用连字符：docker-compose
# V2（当前版本）使用空格：docker compose
```

| 项目     | 说明                                                    |
| -------- | ------------------------------------------------------- |
| 配置文件 | 推荐 `compose.yml`，也兼容 `docker-compose.yml`         |
| version  | `version` 字段已不再需要，Compose 会自动识别            |
| 命令前缀 | `docker compose`（V2，推荐）而非 `docker-compose`（V1） |

## 2. 核心配置

### 2.1 compose.yml 基本结构

```yaml
# compose.yml 的三大顶级元素
services:   # 定义各个容器服务（必需）
  web:
    image: nginx:1.27-alpine
    ports:
      - "3000:80"

  db:
    image: postgres:16
    volumes:
      - pgdata:/var/lib/postgresql/data

networks:   # 定义网络（可选，不写则自动创建默认网络）
  app-net:
    driver: bridge

volumes:    # 定义命名 Volume（可选）
  pgdata:
```

> **提示**：如果不显式定义 `networks`，Compose 会自动创建一个名为 `<项目名>_default` 的 bridge 网络，所有服务默认加入。多数项目用自动创建的网络就够了。

### 2.2 services

`services` 是 Compose 文件的核心，每个键定义一个服务（即一个容器）。服务配置等同于 `docker run` 的各种参数：

```yaml
services:
  api:
    build: ./my-api                # 等同于 docker build ./my-api
    ports:
      - "8080:3000"                # 等同于 -p 8080:3000
    environment:
      NODE_ENV: production         # 等同于 -e NODE_ENV=production
    volumes:
      - ./my-api:/app              # 等同于 -v ./my-api:/app
    networks:
      - app-net                    # 等同于 --network app-net
    depends_on:
      - db                         # 启动顺序：先 db 再 api
```

### 2.3 networks

Compose 中的网络配置对应 `docker network create`，详细的网络原理和 DNS 解析机制见[第 5 篇](docker-5-networking.md)。

```yaml
networks:
  # 简单定义：使用默认 bridge 驱动
  app-net:

  # 完整定义
  app-net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

服务通过 `networks` 字段加入网络后，可以用服务名互相访问（Docker DNS 自动解析）：

```yaml
services:
  api:
    networks:
      - app-net
  db:
    networks:
      - app-net
# api 容器中可以用 db:5432 访问数据库
```

### 2.4 volumes

Compose 中的 Volume 配置对应 `docker volume create`，详细的存储类型和选择指南见[第 6 篇](docker-6-storage.md)。

```yaml
volumes:
  # 简单定义：使用默认 local 驱动
  pgdata:

  # 使用已存在的外部 Volume（不由 Compose 管理生命周期）
  pgdata:
    external: true
```

在服务中引用：

```yaml
services:
  db:
    volumes:
      - pgdata:/var/lib/postgresql/data  # 命名 Volume
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro  # Bind Mount
```

> **注意**：顶级 `volumes` 只声明命名 Volume。Bind Mount（如 `./src:/app/src`）不需要在顶级声明，直接在服务的 `volumes` 中使用即可。

## 3. 服务定义

### 3.1 image 与 build

```yaml
services:
  # 方式一：直接使用镜像
  redis:
    image: redis:7

  # 方式二：从 Dockerfile 构建
  api:
    build: ./my-api               # 构建上下文目录（内含 Dockerfile）

  # 方式三：构建 + 指定镜像名
  api:
    build:
      context: ./my-api           # 构建上下文
      dockerfile: Dockerfile      # 默认值，可省略
      args:                       # 等同于 --build-arg
        NODE_ENV: production
    image: my-api:latest          # 构建产物的镜像名
```

Dockerfile 编写详见[第 4 篇](docker-4-dockerfile.md)。

### 3.2 ports

```yaml
services:
  web:
    ports:
      # 短语法：宿主机端口:容器端口
      - "3000:80"
      - "443:443"

      # 绑定到指定 IP
      - "127.0.0.1:3000:80"

  api:
    ports:
      # 长语法（更显式）
      - target: 3000          # 容器端口
        published: "8080"     # 宿主机端口
        protocol: tcp
```

端口映射的原理和 `外:内` 记忆方法见[第 5 篇](docker-5-networking.md)第 2 节。

### 3.3 volumes

```yaml
services:
  db:
    volumes:
      # 命名 Volume（持久化数据库数据）
      - pgdata:/var/lib/postgresql/data

      # Bind Mount（注入初始化脚本，只读）
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro

  web:
    volumes:
      # Bind Mount（开发热重载）
      - ./my-app/src:/app/src

      # 匿名 Volume（隔离 node_modules）
      - /app/node_modules
```

Volume 类型选择和 node_modules 隔离技巧详见[第 6 篇](docker-6-storage.md)第 6 节和第 8.2 节。

### 3.4 environment 与 env_file

```yaml
services:
  api:
    # 方式一：直接定义键值对
    environment:
      NODE_ENV: production
      DATABASE_URL: postgresql://postgres:secret@db:5432/myapp
      REDIS_URL: redis://redis:6379

    # 方式二：从文件加载环境变量
    env_file:
      - api.env

    # 方式三：两者结合（environment 覆盖 env_file 中的同名变量）
    env_file:
      - api.env
    environment:
      NODE_ENV: production   # 覆盖 api.env 中的 NODE_ENV
```

> **注意**：`environment` 中的值会覆盖 `env_file` 中的同名变量。注意区分：这里的 `env_file` 引用的是自定义文件名（如 `api.env`），与项目根目录下用于 Compose 变量替换的 `.env` 文件是不同的概念（详见 [§5.1](#51-env-文件)）。

### 3.5 depends_on 与服务就绪

`depends_on` 控制服务的**启动顺序**——但启动了不代表准备好了。

**短语法——只控制启动顺序**：

```yaml
services:
  api:
    depends_on:
      - db
      - redis
    # Compose 会先启动 db 和 redis，再启动 api
    # 但不保证 db 已经准备好接受连接！
```

**核心陷阱：`depends_on` 不等于 `ready`**。PostgreSQL 容器启动后需要几秒钟完成初始化，在此期间 API 连接数据库会报错：

```
api    | Error: connect ECONNREFUSED 172.20.0.2:5432
api    | PostgreSQL is not ready yet...
```

**长语法——配合 healthcheck 等待服务就绪**：

```yaml
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: myapp
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 3s
      retries: 5
      start_period: 10s

  api:
    build: ./my-api
    depends_on:
      db:
        condition: service_healthy    # 等 db 健康检查通过才启动
      redis:
        condition: service_started    # 只等 redis 启动
```

**condition 可选值**：

| 条件                             | 含义                       |
| -------------------------------- | -------------------------- |
| `service_started`                | 服务已启动（默认行为）     |
| `service_healthy`                | 服务健康检查通过           |
| `service_completed_successfully` | 服务成功退出（一次性任务） |

> **提示**：对于数据库这类需要初始化时间的服务，始终使用 `condition: service_healthy` 搭配 `healthcheck`。Redis 启动几乎瞬间完成且无需初始化，使用 `service_started` 即可；如果你的服务对 Redis 可用性要求严格，也可以为 Redis 配置 healthcheck 并使用 `service_healthy`。Dockerfile 中的 HEALTHCHECK 配置详见[第 4 篇](docker-4-dockerfile.md)第 2.8 节。

## 4. 生命周期管理

### 4.1 up / down

```bash
# 启动所有服务（后台运行）
docker compose up -d

# 启动并强制重新构建镜像
docker compose up -d --build

# 只启动指定服务（自动启动其依赖）
docker compose up -d api

# 停止并删除所有容器、网络
docker compose down

# 停止并同时删除 Volume（谨慎！数据库数据会丢失）
docker compose down -v
```

**`up` 的智能行为**：

| 场景               | 行为                              |
| ------------------ | --------------------------------- |
| 服务未创建         | 构建镜像、创建网络/Volume、启动   |
| 配置未变化         | 跳过，保持运行                    |
| 配置发生变化       | 重建受影响的容器                  |
| 镜像已存在但未更新 | 使用缓存（加 `--build` 强制重建） |

### 4.2 logs

```bash
# 查看所有服务的聚合日志
docker compose logs

# 持续跟踪日志（类似 tail -f）
docker compose logs -f

# 只看指定服务的日志
docker compose logs api

# 查看最近 50 行
docker compose logs --tail 50 api

# 显示时间戳
docker compose logs -t api
```

### 4.3 ps / exec

```bash
# 查看服务状态
docker compose ps
# NAME   IMAGE         COMMAND   SERVICE   CREATED        STATUS                    PORTS
# api    my-api        ...       api       5 minutes ago  Up 5 minutes              0.0.0.0:8080->3000/tcp
# db     postgres:16   ...       db        5 minutes ago  Up 5 minutes (healthy)    5432/tcp
# web    my-app        ...       web       5 minutes ago  Up 5 minutes              0.0.0.0:3000->80/tcp

# 在运行中的服务容器内执行命令
docker compose exec api sh

# 执行一次性命令
docker compose exec db psql -U postgres -d myapp
```

### 4.4 config（配置验证与展开）

`docker compose config` 是调试利器——它解析 `compose.yml`，展开所有变量替换，输出最终的完整配置。

```bash
# 验证配置语法（有错会报错，正确则输出解析后的完整配置）
docker compose config

# 只验证不输出（检查是否有语法错误）
docker compose config -q

# 列出所有服务名称
docker compose config --services
```

**典型调试场景**：

```bash
# .env 文件中：POSTGRES_PASSWORD=secret

# compose.yml 中：
#   environment:
#     POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}

# 用 config 检查变量是否正确替换
docker compose config | grep POSTGRES_PASSWORD
# 输出：POSTGRES_PASSWORD: secret
```

> **提示**：当变量替换不生效或配置行为不符合预期时，先跑一下 `docker compose config` 看看最终的完整配置。

### 4.5 常用操作速查

| 命令                           | 说明                     |
| ------------------------------ | ------------------------ |
| `docker compose up -d`         | 启动所有服务（后台）     |
| `docker compose up -d --build` | 启动并重新构建           |
| `docker compose down`          | 停止并删除容器和网络     |
| `docker compose down -v`       | 停止并删除容器、网络和卷 |
| `docker compose ps`            | 查看服务状态             |
| `docker compose logs -f`       | 跟踪日志                 |
| `docker compose logs api`      | 查看指定服务日志         |
| `docker compose exec api sh`   | 进入服务容器             |
| `docker compose build`         | 构建/重建服务镜像        |
| `docker compose pull`          | 拉取服务镜像             |
| `docker compose restart api`   | 重启指定服务             |
| `docker compose stop`          | 停止所有服务（不删除）   |
| `docker compose config`        | 验证并展开配置           |

## 5. 环境管理

### 5.1 .env 文件

Compose 自动读取项目根目录下的 `.env` 文件，用于 `compose.yml` 中的变量替换：

```bash
# .env 文件
POSTGRES_PASSWORD=secret
POSTGRES_DB=myapp
NODE_ENV=production
API_PORT=8080
```

```yaml
# compose.yml 中用 ${VAR} 引用
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}

  api:
    ports:
      - "${API_PORT}:3000"
    environment:
      NODE_ENV: ${NODE_ENV}
```

> **注意**：`.env` 文件用于 Compose 的变量替换（`${VAR}`），而服务的 `env_file` 字段用于将变量注入容器。两者用途不同。

### 5.2 多环境配置

通过多个 Compose 文件实现环境差异。`docker compose` 按顺序加载文件，后面的覆盖前面的：

```yaml
# compose.yml（基础配置）
services:
  api:
    build: ./my-api
    environment:
      DATABASE_URL: postgresql://postgres:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
    depends_on:
      db:
        condition: service_healthy
```

```yaml
# compose.override.yml（开发环境覆盖，自动加载）
services:
  api:
    volumes:
      - ./my-api:/app        # 开发时挂载源码
    environment:
      NODE_ENV: development
    ports:
      - "8080:3000"
      - "9229:9229"          # 调试端口
```

```yaml
# compose.prod.yml（生产环境覆盖，需显式指定）
services:
  api:
    environment:
      NODE_ENV: production
    ports:
      - "8080:3000"
    restart: always
```

```bash
# 开发环境：自动加载 compose.yml + compose.override.yml
docker compose up -d

# 生产环境：显式指定文件
docker compose -f compose.yml -f compose.prod.yml up -d
```

### 5.3 变量优先级

变量优先级需要分两个层面理解：Compose 文件中的 `${VAR}` 替换，和容器最终拿到的环境变量。

**层面一：Compose 文件变量替换（`${VAR}` 从哪取值）**

compose.yml 中写的 `${POSTGRES_PASSWORD}` 从以下来源取值（优先级从高到低）：

| 优先级  | 来源                                      |
| ------- | ----------------------------------------- |
| 1（高） | Shell 环境变量（`export VAR=value`）      |
| 2       | `.env` 文件                               |
| 3（低） | compose.yml 中 `${VAR:-default}` 的默认值 |

```bash
# .env 中：POSTGRES_PASSWORD=secret
# Shell 中：
export POSTGRES_PASSWORD=override
docker compose config | grep POSTGRES_PASSWORD
# 输出：POSTGRES_PASSWORD: override（Shell 优先于 .env）
```

**层面二：容器最终环境变量（容器内 `echo $VAR` 的值）**

容器运行时的环境变量来源（优先级从高到低）：

| 优先级  | 来源                                  |
| ------- | ------------------------------------- |
| 1（高） | `docker compose run -e VAR=value`     |
| 2       | `compose.yml` 中的 `environment` 字段 |
| 3       | `compose.yml` 中的 `env_file` 引用    |
| 4（低） | 镜像 Dockerfile 中的 `ENV` 指令       |

> **注意**：`.env` 文件不会直接成为容器的环境变量。它只用于 compose.yml 中的 `${VAR}` 替换。如果需要将 `.env` 中的变量注入容器，需要通过 `env_file` 字段引用，或者在 `environment` 中用 `${VAR}` 引用。

## 6. 综合实战

本节用一个完整项目串联前 6 篇的所有知识：Dockerfile 构建（[第 4 篇](docker-4-dockerfile.md)）、网络通信（[第 5 篇](docker-5-networking.md)）、数据持久化（[第 6 篇](docker-6-storage.md)）。

### 6.1 项目架构

```
浏览器
  │
  ▼ http://localhost:3000
┌──────────────────────────────────────────────────┐
│                   app-net 网络                    │
│                                                  │
│  ┌──────────┐     ┌──────────┐                  │
│  │   web    │────→│   api    │                  │
│  │  Nginx   │     │ Node.js  │                  │
│  │ :80      │     │ :3000    │                  │
│  └──────────┘     └────┬─────┘                  │
│  宿主机:3000→80        │                        │
│                   ┌────┴────┐                   │
│                   │         │                   │
│              ┌────▼───┐ ┌──▼─────┐              │
│              │  db    │ │ redis  │              │
│              │  PG 16 │ │ Redis 7│              │
│              │ :5432  │ │ :6379  │              │
│              └────────┘ └────────┘              │
│              pgdata卷                            │
└──────────────────────────────────────────────────┘
```

**项目目录结构**：

```
project/
├── compose.yml
├── .env
├── my-app/               # 前端（React + Vite）
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── nginx.conf
│   ├── package.json
│   └── src/
├── my-api/               # 后端（Node.js + Express）
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── package.json
│   └── server.js
└── init.sql              # 数据库初始化脚本（可选）
```

### 6.2 前端服务（Nginx）

前端使用多阶段构建，构建 React 应用并用 Nginx 提供服务。Dockerfile 编写和多阶段构建原理详见[第 4 篇](docker-4-dockerfile.md)第 6-7 节。

**`my-app/Dockerfile`**：

```dockerfile
# ---- 阶段 1：构建 ----
FROM node:22-slim AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
ARG VITE_API_URL=/api
ENV VITE_API_URL=$VITE_API_URL
COPY . .
RUN npm run build

# ---- 阶段 2：运行 ----
FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
# 健康检查由 compose.yml 统一管理，此处不重复声明
CMD ["nginx", "-g", "daemon off;"]
```

**`my-app/nginx.conf`**——Nginx 反向代理到 API 容器，用服务名 `api` 作为主机名（DNS 解析原理见[第 5 篇](docker-5-networking.md)第 4 节）：

```nginx
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # SPA 路由回退
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API 反向代理——用 Compose 服务名 "api"
    location /api/ {
        proxy_pass http://api:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # 静态资源缓存（Vite 构建产物含 hash）
    location /assets/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml;
    gzip_min_length 1024;
}
```

### 6.3 API 服务（Node.js）

**`my-api/Dockerfile`**：

```dockerfile
FROM node:22-slim
WORKDIR /app

# 利用缓存分层安装依赖
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY . .

ENV NODE_ENV=production
EXPOSE 3000

# 健康检查由 compose.yml 统一管理，此处不重复声明
CMD ["node", "server.js"]
```

### 6.4 数据库服务（PostgreSQL）

数据库使用官方镜像，无需自定义 Dockerfile。关键点：

- 用命名 Volume 持久化数据（Volume 原理见[第 6 篇](docker-6-storage.md)第 4 节）
- 配置 healthcheck 供 `depends_on` 使用
- 可选挂载 `init.sql` 初始化数据库

### 6.5 缓存服务（Redis）

Redis 同样使用官方镜像，配置 healthcheck 即可。

### 6.6 完整 compose.yml

```yaml
services:
  # ---- 前端 ----
  web:
    build:
      context: ./my-app
      args:
        VITE_API_URL: /api
    ports:
      - "3000:80"
    depends_on:
      api:
        condition: service_healthy
    networks:
      - app-net
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "wget -qO /dev/null http://localhost:80/ || exit 1"]
      interval: 30s
      timeout: 3s
      retries: 3

  # ---- API ----
  api:
    build: ./my-api
    ports:
      - "8080:3000"
    environment:
      NODE_ENV: ${NODE_ENV}
      DATABASE_URL: postgresql://postgres:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
      REDIS_URL: redis://redis:6379
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - app-net
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "node -e \"fetch('http://localhost:3000/health').then(r=>{process.exit(r.ok?0:1)}).catch(()=>process.exit(1))\""]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s

  # ---- 数据库 ----
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - pgdata:/var/lib/postgresql/data            # 命名 Volume 持久化
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro  # 初始化脚本
    networks:
      - app-net
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 3s
      retries: 5
      start_period: 10s

  # ---- 缓存 ----
  redis:
    image: redis:7
    networks:
      - app-net
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3

networks:
  app-net:

volumes:
  pgdata:
```

**`.env` 文件**：

```bash
POSTGRES_PASSWORD=secret
POSTGRES_DB=myapp
NODE_ENV=production
```

**这个文件覆盖了系列的核心知识**：

| 前文知识   | 在 compose.yml 中的体现                      |
| ---------- | -------------------------------------------- |
| 镜像与构建 | `image: postgres:16`、`build: ./my-api`      |
| 网络通信   | `networks: app-net`、服务名 DNS（`db:5432`） |
| 数据持久化 | `volumes: pgdata:/var/lib/...`               |
| 环境变量   | `environment` + `.env` 变量替换              |
| 健康检查   | `healthcheck` + `depends_on.condition`       |
| 端口映射   | `ports: "3000:80"`、`"8080:3000"`            |

> **提示**：本示例将 healthcheck 统一放在 compose.yml 中，Dockerfile 中不重复声明。在多环境项目中，这是更常见、也更便于集中管理的做法——Dockerfile 中的 `HEALTHCHECK` 是镜像级默认值，Compose 中的 `healthcheck` 会覆盖它。也有些团队选择在 Dockerfile 中声明默认健康检查，Compose 中按需覆盖，两种方式都可以。

> **注意**：健康检查命令依赖镜像内已有的工具。本示例中 web 服务基于 Alpine 镜像（自带 `wget`），API 服务基于 Node.js 镜像（可用 `node` 内置的 `fetch`）。如果镜像不含 `curl`/`wget`，需要换用镜像内已有的探测方式。

### 6.7 启动与验证

```bash
# 1. 检查配置（变量替换是否正确）
docker compose config -q

# 2. 构建并启动
docker compose up -d --build

# 3. 查看服务状态（等待所有服务 healthy）
docker compose ps
# NAME    IMAGE         SERVICE   STATUS                   PORTS
# db      postgres:16   db        Up 30s (healthy)         5432/tcp
# redis   redis:7       redis     Up 30s (healthy)         6379/tcp
# api     project-api   api       Up 25s (healthy)         0.0.0.0:8080->3000/tcp
# web     project-web   web       Up 20s (healthy)         0.0.0.0:3000->80/tcp

# 4. 验证前端
curl http://localhost:3000

# 5. 验证 API
curl http://localhost:8080/health

# 6. 验证 API 通过 Nginx 代理
curl http://localhost:3000/api/health

# 7. 查看聚合日志
docker compose logs -f

# 8. 数据库连接测试
docker compose exec db psql -U postgres -d myapp -c '\dt'

# 9. 停止并清理（保留数据）
docker compose down

# 10. 停止并删除数据（重新开始）
docker compose down -v
```

## 7. 总结

### 7.1 核心要点

- **Compose 是胶水层**：不引入新概念，而是把 `docker build`、`docker run`、`docker network create`、`docker volume create` 整合到一个声明式文件中
- **`depends_on` 不等于就绪**：短语法只控制启动顺序；配合 `healthcheck` 和 `condition: service_healthy` 才能真正等待服务就绪
- **`docker compose config`**：排查变量替换和配置语法问题的首选工具
- **环境管理**：`.env` 用于 Compose 变量替换，`env_file` 用于注入容器环境变量，两者用途不同
- **命名约定**：使用 `compose.yml`（推荐）而非 `docker-compose.yml`，命令使用 `docker compose`（V2）
- **`down -v` 谨慎使用**：会删除所有命名 Volume，数据库数据将不可恢复

### 7.2 速查表

| 命令                                     | 说明                 |
| ---------------------------------------- | -------------------- |
| `docker compose up -d`                   | 后台启动所有服务     |
| `docker compose up -d --build`           | 重新构建并启动       |
| `docker compose down`                    | 停止并删除容器和网络 |
| `docker compose down -v`                 | 同上 + 删除 Volume   |
| `docker compose ps`                      | 查看服务状态         |
| `docker compose logs -f [服务]`          | 跟踪日志             |
| `docker compose exec <服务> <命令>`      | 在服务容器中执行命令 |
| `docker compose build`                   | 构建所有服务镜像     |
| `docker compose pull`                    | 拉取所有服务镜像     |
| `docker compose config`                  | 验证并展开配置       |
| `docker compose config -q`               | 静默验证（只报错）   |
| `docker compose restart <服务>`          | 重启指定服务         |
| `docker compose stop`                    | 停止所有服务         |
| `docker compose -f a.yml -f b.yml up -d` | 多文件启动           |

## 参考资源

- [Docker Compose 概述](https://docs.docker.com/compose/)
- [Compose 文件参考](https://docs.docker.com/reference/compose-file/)
- [Compose 服务配置](https://docs.docker.com/reference/compose-file/services/)
- [docker compose CLI 参考](https://docs.docker.com/reference/cli/docker/compose/)
- [Compose 环境变量](https://docs.docker.com/compose/how-tos/environment-variables/)
- [Docker 网络完全指南](docker-5-networking.md)（本系列第 5 篇）
- [Docker 数据管理完全指南](docker-6-storage.md)（本系列第 6 篇）
