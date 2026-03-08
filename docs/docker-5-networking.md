# Docker 网络完全指南

Docker 容器默认运行在隔离的网络环境中——它们有自己的 IP 地址、端口空间和网络栈。要让容器对外提供服务、让多个容器互相通信，就需要理解 Docker 的网络模型。本指南聚焦单机场景下的高频网络操作：端口映射、Bridge 网络、容器 DNS 和容器间通信。

> 本篇是 Docker 系列（共 7 篇）的第 5 篇。上一篇：[Dockerfile 与镜像构建完全指南](docker-4-dockerfile.md)。下一篇：[Docker 数据管理完全指南](docker-6-storage.md)。

## 1. Docker 网络模型

上一篇学习了 Dockerfile 中的 `EXPOSE` 指令——它声明了容器打算监听的端口，但 `EXPOSE` 只是文档标注，并不会让外部真正访问到容器。要实现外部访问，需要 `-p` 端口映射；要实现容器之间的互相访问，需要理解 Docker 的网络模型。先记住两件事：

- **外部访问容器**：看 `-p` 端口映射（[第 2 节](#2-端口映射)）
- **容器之间互访**：看自定义 bridge 网络 + 容器名（[第 3 节](#3-bridge-网络) + [第 4 节](#4-容器-dns)）

下面从底层原理开始理解这些机制。

### 1.1 容器网络基础

每个 Docker 容器都拥有独立的网络栈（Network Namespace），包括独立的网络接口、IP 地址、路由表和端口空间。容器通过虚拟网桥（Bridge）与宿主机和外部网络通信。

数据从容器流向外部网络的路径（Linux 宿主机原理示意，macOS / Windows 通过 Docker Desktop VM 间接实现）：

```
┌──────────────────────────────────────────────────────────┐
│                        宿主机                             │
│                                                          │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐            │
│  │ 容器 web  │  │ 容器 api  │  │ 容器 db   │            │
│  │ 172.17.0.2│  │ 172.17.0.3│  │ 172.17.0.4│            │
│  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘            │
│        │ veth          │ veth          │ veth             │
│  ┌─────┴───────────────┴───────────────┴─────┐           │
│  │            docker0 (Bridge)               │           │
│  │            172.17.0.1                     │           │
│  └──────────────────┬────────────────────────┘           │
│                     │ NAT                                │
│  ┌──────────────────┴────────────────────────┐           │
│  │            eth0 (宿主机网卡)               │           │
│  │            192.168.1.100                   │           │
│  └──────────────────┬────────────────────────┘           │
└─────────────────────┼────────────────────────────────────┘
                      │
                 外部网络 / 互联网
```

> **提示**：图中的 IP 地址（172.17.0.x、192.168.1.x）仅为示意，实际值因环境而异。

| 组件      | 说明                                          |
| --------- | --------------------------------------------- |
| veth pair | 虚拟网线，一端连接容器，另一端连接网桥        |
| docker0   | Docker 默认创建的虚拟网桥，充当容器的网关     |
| NAT       | 网络地址转换，将容器的内部 IP 转换为宿主机 IP |
| iptables  | 宿主机防火墙规则，处理端口映射和流量转发      |

### 1.2 网络隔离原理

Docker 利用 Linux Namespace 实现网络隔离。每个容器的 Network Namespace 提供：

- **独立 IP 地址**：容器有自己的 IP，与宿主机和其他容器互不冲突
- **独立端口空间**：多个容器可以各自监听 80 端口，互不影响
- **独立路由表**：容器有自己的路由规则

```bash
# 查看容器的网络信息
docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' api

# 在容器内部查看网络配置
docker exec api ip addr show
```

> **提示**：macOS 和 Windows 上的 Docker Desktop 在 Linux 虚拟机中运行容器，因此容器 IP 地址无法从宿主机直接访问。通信必须通过端口映射进行。

## 2. 端口映射

### 2.1 -p 语法详解

容器有自己的端口空间，外部无法直接访问。`-p`（`--publish`）标志将容器端口映射到宿主机端口，让外部可以通过宿主机端口访问容器服务。

语法格式：

```
-p [宿主机IP:]宿主机端口:容器端口[/协议]
```

理解方向：**从外到内**——左边是外部（宿主机），右边是内部（容器）。

### 2.2 常见映射方式

| 写法                     | 含义                                  | 示例场景               |
| ------------------------ | ------------------------------------- | ---------------------- |
| `-p 3000:80`             | 宿主机 3000 → 容器 80                 | Nginx 容器对外提供服务 |
| `-p 8080:3000`           | 宿主机 8080 → 容器 3000               | Node.js API 对外暴露   |
| `-p 127.0.0.1:5432:5432` | 仅本机可访问，宿主机 5432 → 容器 5432 | 数据库只允许本地连接   |
| `-p 5432:5432`           | 所有网卡，宿主机 5432 → 容器 5432     | 数据库允许远程连接     |
| `-p 3000-3005:3000-3005` | 映射端口范围                          | 多端口服务             |
| `-P`                     | 自动映射所有 EXPOSE 端口到随机端口    | 快速测试               |

```bash
# Nginx 容器：宿主机 3000 端口映射到容器 80 端口
docker run -d --name web -p 3000:80 nginx

# Node.js API：宿主机 8080 端口映射到容器 3000 端口
docker run -d --name api -p 8080:3000 node:22-slim

# PostgreSQL：仅本机可访问
docker run -d --name db -p 127.0.0.1:5432:5432 postgres:16

# 查看端口映射关系
docker port web
# 输出：80/tcp -> 0.0.0.0:3000
```

> **注意**：数据库、缓存、管理后台等内部服务的端口，应优先绑定到 `127.0.0.1`（如 `-p 127.0.0.1:5432:5432`），避免暴露到 `0.0.0.0`。不指定 IP 时默认绑定到所有网卡，这意味着同一网络中的其他机器也可以访问。

### 2.3 为什么是 -p 宿主机:容器

初学者常困惑：为什么冒号左边是宿主机、右边是容器？

**记忆方法**：把 `-p` 想象成一扇门——"从外面进来"。访问请求从宿主机（外部）出发，到达容器（内部）。和 SSH 的端口转发、Docker Volume 挂载（`-v 宿主机:容器`）保持一致的 `外:内` 风格。

```
访问方向：浏览器 → 宿主机:3000 → 容器:80
映射写法：         -p 3000:80
                      外 : 内
```

> **注意**：如果宿主机端口已被占用，`docker run` 会报错 `port is already allocated`。可以换一个宿主机端口，或者先停掉占用端口的服务。

## 3. Bridge 网络

Bridge 是 Docker 最常用的网络模式。它在宿主机上创建一个虚拟网桥，容器通过虚拟网线连接到网桥，实现容器间通信和外部访问。

### 3.1 默认 bridge 网络

Docker 安装后自动创建一个名为 `bridge` 的默认网络。不指定 `--network` 时，容器默认连接到这个网络。

```bash
# 查看 Docker 网络列表
docker network ls
# 输出：
# NETWORK ID     NAME      DRIVER    SCOPE
# a1b2c3d4e5f6   bridge    bridge    local
# f6e5d4c3b2a1   host      host      local
# 1a2b3c4d5e6f   none      null      local

# 查看默认 bridge 的详细信息
docker network inspect bridge
```

### 3.2 默认 bridge 的局限

默认 bridge 网络存在几个明显问题：

```bash
# 启动两个容器（默认连接到 bridge 网络）
docker run -d --name container-a alpine sleep 3600
docker run -d --name container-b alpine sleep 3600

# ❌ 通过容器名访问——失败
docker exec container-a ping -c 2 container-b
# ping: bad address 'container-b'

# ✅ 通过 IP 地址可以通信（但 IP 会变）
docker exec container-a ping -c 2 172.17.0.3
```

**默认 bridge 的问题**：

| 问题         | 说明                                     |
| ------------ | ---------------------------------------- |
| 无 DNS 解析  | 容器间只能用 IP 通信，不能用容器名       |
| IP 不固定    | 容器重启后 IP 可能变化，硬编码会出问题   |
| 所有容器共享 | 不相关的容器也在同一网络中，缺乏隔离     |
| 配置不灵活   | 修改默认 bridge 配置需要重启 Docker 服务 |

### 3.3 自定义 bridge 网络

自定义 bridge 网络解决了默认 bridge 的所有问题，是**推荐的网络方式**：

```bash
# 创建自定义网络
docker network create my-app

# 在自定义网络中启动容器
docker run -d --name api --network my-app node:22-slim sleep 3600
docker run -d --name db --network my-app postgres:16

# ✅ 通过容器名直接访问——成功
docker exec api ping -c 2 db
# PING db (172.18.0.3): 56 data bytes
# 64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.100 ms
```

**默认 bridge vs 自定义 bridge 对比**：

| 特性       | 默认 bridge       | 自定义 bridge     |
| ---------- | ----------------- | ----------------- |
| DNS 解析   | ❌ 不支持         | ✅ 自动 DNS 解析  |
| 容器名互访 | ❌ 只能用 IP      | ✅ 直接用容器名   |
| 网络隔离   | 所有容器共享      | 按网络分组隔离    |
| 动态连接   | 需要重建容器      | 运行时可连接/断开 |
| 配置灵活性 | 修改需重启 Docker | 每个网络独立配置  |

> **提示**：实际项目中应始终使用自定义 bridge 网络，不要依赖默认 bridge。

## 4. 容器 DNS

### 4.1 自动 DNS 解析

自定义 bridge 网络内置了 DNS 服务器（127.0.0.11），自动将容器名解析为 IP 地址。这意味着应用代码中可以直接用容器名作为主机名。

```bash
# 创建网络并启动服务
docker network create app-net
docker run -d --name api --network app-net node:22-slim sleep 3600
docker run -d --name db --network app-net postgres:16
docker run -d --name redis --network app-net redis:7

# api 容器可以通过名称访问其他服务
docker exec api ping -c 1 db      # 解析为 db 的 IP
docker exec api ping -c 1 redis   # 解析为 redis 的 IP
```

在 Node.js 应用中的使用：

```javascript
// ✅ 使用容器名作为主机名——在同一 Docker 网络中自动解析
const dbHost = "db"; // 容器名，不是 localhost
const redisHost = "redis"; // 容器名

// 数据库连接
const pool = new Pool({
  host: dbHost, // "db" → 自动解析为 db 容器的 IP
  port: 5432,
  database: "myapp",
});

// Redis 连接
const client = createClient({
  url: `redis://${redisHost}:6379`,
});
```

### 4.2 为什么容器名可以互相访问

Docker 在自定义网络中运行了一个内嵌 DNS 服务器：

```
容器 api 访问 "db:5432"
      │
      ▼
Docker 内嵌 DNS (127.0.0.11)
      │
      ├─ "db" → 查找同网络中名为 db 的容器 → 172.18.0.3
      │
      └─ 外部域名 → 转发给宿主机配置的 DNS 服务器
```

**DNS 解析规则**：

| 场景             | 解析方式                 |
| ---------------- | ------------------------ |
| 同网络容器名     | Docker 内嵌 DNS 直接解析 |
| 网络别名         | Docker 内嵌 DNS 解析别名 |
| 外部域名         | 转发给宿主机 DNS 服务器  |
| 不同网络的容器名 | 无法解析                 |

```bash
# 为容器设置网络别名
docker run -d --name api-server --network app-net --network-alias api node:22-slim sleep 3600

# 通过容器名或别名都可以访问
docker exec db ping -c 1 api-server  # 容器名
docker exec db ping -c 1 api         # 网络别名
```

### 4.3 DNS 与默认 bridge 的区别

默认 bridge 网络**没有内嵌 DNS 服务**，容器的 `/etc/resolv.conf` 直接继承宿主机配置，只能解析外部域名。

```bash
# 默认 bridge 中的 DNS 配置
docker run --rm alpine cat /etc/resolv.conf
# nameserver 的值取决于宿主机平台：
# macOS Docker Desktop 可能显示 192.168.65.254
# Linux 宿主机可能显示 8.8.8.8 等公共 DNS

# 自定义网络中的 DNS 配置
docker run --rm --network app-net alpine cat /etc/resolv.conf
# nameserver 127.0.0.11  （指向 Docker 内嵌 DNS，所有平台一致）
```

这就是为什么默认 bridge 中容器名无法互相解析——根本没有负责容器名解析的 DNS 服务器。

## 5. 容器间通信

### 5.1 同网络通信

在同一自定义 bridge 网络中的容器可以直接通过容器名和端口通信，**无需端口映射**：

```bash
# 创建网络
docker network create app-net

# 启动服务容器
docker run -d --name db --network app-net \
  -e POSTGRES_PASSWORD=secret postgres:16

docker run -d --name redis --network app-net redis:7

docker run -d --name api --network app-net \
  -p 8080:3000 node:22-slim sleep 3600

# api → db：直接用容器名 + 容器内部端口
# 连接地址：db:5432（不是宿主机映射的端口）

# api → redis：直接用容器名 + 容器内部端口
# 连接地址：redis:6379
```

> **注意**：容器间通信使用**容器内部端口**（如 5432），不是宿主机映射端口。`-p` 端口映射仅用于外部访问容器。

### 5.2 跨网络通信

不同网络中的容器默认**无法通信**。如果需要跨网络访问，将容器连接到目标网络：

```bash
# 创建两个网络
docker network create frontend
docker network create backend

# api 需要同时与前端和后端通信
docker run -d --name api --network backend node:22-slim sleep 3600

# 将 api 同时连接到 frontend 网络
docker network connect frontend api

# 现在 api 可以与两个网络中的容器通信
docker exec api ping -c 1 db     # backend 网络中的容器
docker exec api ping -c 1 web    # frontend 网络中的容器
```

```
┌─── frontend 网络 ───┐     ┌─── backend 网络 ───┐
│                     │     │                    │
│  ┌─────┐  ┌─────┐  │     │  ┌─────┐  ┌─────┐ │
│  │ web │  │ api │◄─┼─────┼─►│ api │  │ db  │ │
│  └─────┘  └──┬──┘  │     │  └──┬──┘  └─────┘ │
│              │      │     │     │              │
└──────────────┘      │     └─────┘──────────────┘
           api 同时连接两个网络
```

### 5.3 网络管理命令

| 命令                                          | 说明                   |
| --------------------------------------------- | ---------------------- |
| `docker network ls`                           | 列出所有网络           |
| `docker network create <网络名>`              | 创建自定义 bridge 网络 |
| `docker network inspect <网络名>`             | 查看网络详情和容器列表 |
| `docker network connect <网络名> <容器名>`    | 将运行中容器连接到网络 |
| `docker network disconnect <网络名> <容器名>` | 将容器从网络断开       |
| `docker network rm <网络名>`                  | 删除网络               |
| `docker network prune`                        | 删除所有未使用的网络   |

```bash
# 查看某个网络中有哪些容器
docker network inspect app-net --format='{{range .Containers}}{{.Name}} {{end}}'

# 查看某个容器连接了哪些网络
docker inspect api --format='{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}'
```

## 6. 常见困惑解答

### 6.1 为什么容器里 localhost 不对

**问题**：在容器中用 `localhost` 连接其他服务连不上。

**原因**：每个容器有独立的网络栈，`localhost`（127.0.0.1）指向容器自己，而不是宿主机或其他容器。

```bash
# 在 api 容器中访问 localhost:5432——连接的是 api 容器自己的 5432 端口，不是 db 容器
docker exec api curl localhost:5432
# 连接失败，因为 api 容器自己没有在 5432 端口运行服务

# ✅ 正确做法：使用容器名
docker exec api ping db  # 访问 db 容器
```

```
┌── api 容器 ──┐        ┌── db 容器 ──┐
│              │        │             │
│  localhost ──┼─→ 自己  │             │
│  (127.0.0.1) │        │             │
│              │        │             │
│  db ─────────┼────────┼─→ db 容器   │
│  (DNS 解析)  │        │             │
└──────────────┘        └─────────────┘
```

### 6.2 容器如何访问宿主机服务

**场景**：宿主机上运行着一个数据库或 API 服务，容器需要访问它。

**macOS / Windows（Docker Desktop）**：使用特殊域名 `host.docker.internal`，Docker Desktop 会自动将其解析为宿主机 IP。

```bash
# 容器内访问宿主机上运行的服务
docker run --rm curlimages/curl curl http://host.docker.internal:3000

# Node.js 应用连接宿主机上的数据库
# DB_HOST=host.docker.internal
```

**Linux**：需要手动添加 `host.docker.internal` 映射：

```bash
# Linux 上需要 --add-host 参数
docker run --rm --add-host host.docker.internal=host-gateway \
  curlimages/curl curl http://host.docker.internal:3000
```

| 平台            | 访问宿主机方式                                 |
| --------------- | ---------------------------------------------- |
| macOS / Windows | `host.docker.internal`（自动可用）             |
| Linux           | `--add-host host.docker.internal=host-gateway` |

> **提示**：`host-gateway` 是一个特殊值，Docker 会自动将其替换为宿主机的网关 IP 地址。

### 6.3 多容器端口冲突处理

**问题**：多个容器都需要映射到宿主机同一端口。

```bash
# ❌ 端口冲突
docker run -d --name api-1 -p 8080:3000 node:22-slim
docker run -d --name api-2 -p 8080:3000 node:22-slim
# Error: port is already allocated

# ✅ 使用不同的宿主机端口
docker run -d --name api-1 -p 8080:3000 node:22-slim
docker run -d --name api-2 -p 8081:3000 node:22-slim
```

**要点**：

- **容器内部端口可以相同**：每个容器有独立端口空间，都监听 3000 没问题
- **宿主机端口必须唯一**：冲突发生在宿主机层面，一个端口只能映射给一个容器
- 容器间通信不需要端口映射，直接用容器名 + 内部端口

## 7. 前端场景

### 7.1 Nginx 反向代理到 API 容器

典型场景：`web`（Nginx）容器接收外部请求，反向代理到 `api`（Node.js）容器。

```bash
# 创建网络
docker network create app-net

# 启动 API 容器（容器内监听 3000 端口，无需 -p 对外暴露）
docker run -d --name api --network app-net \
  -e PORT=3000 my-api-image

# 启动 Nginx 容器（对外暴露 3000 端口）
docker run -d --name web --network app-net \
  -p 3000:80 \
  -v ./nginx.conf:/etc/nginx/conf.d/default.conf:ro \
  nginx
```

Nginx 配置文件（`nginx.conf`）：

```nginx
server {
    listen 80;

    # 静态文件
    location / {
        root /usr/share/nginx/html;
        try_files $uri $uri/ /index.html;
    }

    # API 反向代理——直接用容器名 "api"
    location /api/ {
        proxy_pass http://api:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**核心要点**：`proxy_pass http://api:3000` 中的 `api` 是容器名，Docker DNS 自动解析为 `api` 容器的 IP 地址。不需要知道 IP，不需要用 `localhost`。

### 7.2 前后端联调网络配置

完整的前后端 + 数据库联调环境：

```bash
# 1. 创建共享网络
docker network create dev-net

# 2. 启动数据库
docker run -d --name db --network dev-net \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=myapp \
  postgres:16

# 3. 启动 Redis
docker run -d --name redis --network dev-net redis:7

# 4. 启动 API 服务（连接 db 和 redis）
docker run -d --name api --network dev-net \
  -p 8080:3000 \
  -e DB_HOST=db \
  -e DB_PORT=5432 \
  -e REDIS_HOST=redis \
  -e REDIS_PORT=6379 \
  my-api-image

# 5. 启动前端 Nginx（反向代理到 api）
docker run -d --name web --network dev-net \
  -p 3000:80 \
  -v ./nginx.conf:/etc/nginx/conf.d/default.conf:ro \
  nginx
```

**网络拓扑**：

```
浏览器
  │
  ▼ http://localhost:3000
┌─────────────────────────────────────────────┐
│                 dev-net 网络                 │
│                                             │
│  ┌──────────┐     ┌──────────┐             │
│  │   web    │────→│   api    │             │
│  │ (Nginx)  │     │ (Node.js)│             │
│  │ :80      │     │ :3000    │             │
│  └──────────┘     └────┬─────┘             │
│                        │                    │
│                   ┌────┴────┐              │
│                   │         │              │
│              ┌────▼───┐ ┌──▼─────┐        │
│              │  db    │ │ redis  │        │
│              │ :5432  │ │ :6379  │        │
│              └────────┘ └────────┘        │
└─────────────────────────────────────────────┘

对外暴露：
  宿主机:3000 → web:80（前端页面 + API 代理）
  宿主机:8080 → api:3000（可选，直接调试 API）
```

> **提示**：`db` 和 `redis` 不需要 `-p` 端口映射，因为它们只需要被同网络中的 `api` 容器访问。不对外暴露端口也更安全。

## 8. 扩展了解

以下网络模式在特定场景下有用，了解即可。

### 8.1 host 网络模式

容器直接使用宿主机网络栈，没有网络隔离。容器的端口就是宿主机的端口。

```bash
# 使用 host 网络模式（仅 Linux 有效）
docker run -d --network host nginx
# Nginx 直接监听宿主机的 80 端口，无需 -p
```

| 优点            | 缺点                                        |
| --------------- | ------------------------------------------- |
| 无 NAT 性能损耗 | 失去网络隔离                                |
| 端口无需映射    | 端口可能与宿主机服务冲突                    |
| 网络性能最优    | macOS/Windows 上无效（Docker Desktop 限制） |

> **注意**：host 网络模式在 macOS/Windows 的 Docker Desktop 上不按预期工作，因为容器实际运行在 Linux 虚拟机中。

### 8.2 none 网络模式

容器完全没有网络连接，适用于不需要网络的计算任务。

```bash
docker run --rm --network none alpine ping -c 1 google.com
# ping: bad address 'google.com'  （无网络访问）
```

### 8.3 overlay 网络模式简介

overlay 网络用于**跨主机**容器通信，主要在 Docker Swarm 或集群场景中使用。它通过 VXLAN 隧道在多台宿主机之间建立虚拟网络。

```
┌─── 主机 A ───┐          ┌─── 主机 B ───┐
│  ┌────────┐  │  overlay  │  ┌────────┐  │
│  │ api-1  │◄─┼──────────┼─►│ api-2  │  │
│  └────────┘  │  (VXLAN)  │  └────────┘  │
└──────────────┘          └──────────────┘
```

对于单机开发和部署，bridge 网络已经够用。overlay 通常在学习 Docker Swarm 或 Kubernetes 时才需要接触。

## 9. 总结

### 9.1 核心要点

- **网络隔离**：每个容器有独立的网络栈，`localhost` 指向容器自己而非宿主机
- **端口映射**：`-p 宿主机端口:容器端口` 让外部能访问容器服务
- **使用自定义 bridge**：始终创建自定义 bridge 网络，不要使用默认 bridge
- **容器 DNS**：自定义网络中容器名自动解析为 IP，应用代码直接用容器名
- **Compose 预告**：到 Docker Compose（[第 7 篇](docker-7-compose.md)）中，服务名通信和默认网络会变成更自然的默认行为——Compose 自动创建自定义 bridge 网络，服务名即可互访，本质上继承的就是本篇讲的 bridge + DNS 机制
- **容器间通信**：同一网络中用容器名 + 内部端口通信，无需端口映射
- **访问宿主机**：macOS/Windows 用 `host.docker.internal`，Linux 需 `--add-host`

### 9.2 速查表

| 命令/操作                                 | 说明                    |
| ----------------------------------------- | ----------------------- |
| `docker network create <名称>`            | 创建自定义 bridge 网络  |
| `docker network ls`                       | 列出所有网络            |
| `docker network inspect <名称>`           | 查看网络详情            |
| `docker network connect <网络> <容器>`    | 将容器加入网络          |
| `docker network disconnect <网络> <容器>` | 将容器从网络移除        |
| `docker network rm <名称>`                | 删除网络                |
| `docker network prune`                    | 清理未使用的网络        |
| `-p 8080:3000`                            | 宿主机 8080 → 容器 3000 |
| `-p 127.0.0.1:5432:5432`                  | 仅本机可访问的端口映射  |
| `--network <名称>`                        | 指定容器加入的网络      |
| `--network-alias <别名>`                  | 设置网络别名            |
| `host.docker.internal`                    | 容器内访问宿主机的域名  |

## 参考资源

容器之间可以通信了，下一个问题是：容器删除后数据怎么办？下一篇讲解 Volume、Bind Mount 和 tmpfs 三种数据持久化方案。见[Docker 数据管理完全指南](docker-6-storage.md)。

- [Docker 网络概述](https://docs.docker.com/engine/network/)
- [Bridge 网络驱动](https://docs.docker.com/engine/network/drivers/bridge/)
- [Docker Desktop 网络功能](https://docs.docker.com/desktop/features/networking/)
- [Docker 网络教程](https://docs.docker.com/engine/network/tutorials/)
- [docker network 命令参考](https://docs.docker.com/reference/cli/docker/network/)
