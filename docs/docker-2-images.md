# Docker 镜像与仓库完全指南

Docker 镜像是容器运行的基础，理解镜像的分层结构、标签策略和安全实践是高效使用 Docker 的关键。本指南聚焦于镜像的选择、获取、管理和分发，帮助你在项目中做出正确的镜像决策。

> 本篇是 Docker 系列（共 7 篇）的第 2 篇。上一篇：[Docker 基础完全指南](docker-1-fundamentals.md)。下一篇：[Docker 容器管理完全指南](docker-3-containers.md)。

## 1. 镜像基础

### 1.1 镜像是什么

镜像（Image）是一个包含运行应用所需全部内容的只读文件包——操作系统文件、运行时环境、应用代码、依赖库和配置文件。可以把镜像理解为容器的"安装包"，一个镜像可以创建任意多个容器实例。

**镜像的组成**：

| 组成部分   | 说明                        | 示例                     |
| ---------- | --------------------------- | ------------------------ |
| 基础系统   | 精简的 Linux 发行版文件系统 | Debian Bookworm、Alpine  |
| 运行时环境 | 应用所需的语言运行时        | Node.js 22、Python 3.12  |
| 依赖库     | 应用依赖的第三方包          | npm 包、系统库           |
| 应用代码   | 业务代码和静态资源          | React 构建产物、API 源码 |
| 配置文件   | 运行时配置和启动命令        | nginx.conf、环境变量     |

### 1.2 只读分层结构

镜像采用**分层（Layer）**结构存储，每一层代表一组文件系统变更。分层基于 UnionFS 实现（详见[第 1 篇](docker-1-fundamentals.md)第 5.3 节），所有层叠加后呈现为统一的文件系统视图。

```
┌─────────────────────────────────────────┐
│  Layer 4: EXPOSE 80 + CMD               │  ← 元数据配置（0 B）
├─────────────────────────────────────────┤
│  Layer 3: COPY dist/ /usr/share/nginx/  │  ← 应用静态文件（2 MB）
├─────────────────────────────────────────┤
│  Layer 2: RUN apt-get install ...       │  ← 安装额外依赖（15 MB）
├─────────────────────────────────────────┤
│  Layer 1: nginx:1.27-bookworm 基础镜像  │  ← 系统 + Nginx（70 MB）
└─────────────────────────────────────────┘
        ↑ 底层                 顶层 ↑
        所有层只读，不可修改
```

**分层关键规则**：

- 每层只存储与前一层的**差异**（增量存储）
- 所有层均为只读，镜像一旦构建就不可修改
- 删除文件并不会减小镜像体积——只是在新层中标记为"已删除"
- 多个镜像可以**共享**相同的底层，节省磁盘和传输开销

### 1.3 镜像 vs 容器

镜像和容器是 Docker 最容易混淆的两个概念：

| 对比项   | 镜像（Image）          | 容器（Container）    |
| -------- | ---------------------- | -------------------- |
| 本质     | 只读模板               | 镜像的运行实例       |
| 可写性   | 不可修改               | 顶部有可写层         |
| 存在形式 | 静态文件，存储在磁盘   | 运行中的进程         |
| 数量关系 | 一个镜像               | 可创建多个容器       |
| 类比     | 类的定义（Class）      | 类的实例（Instance） |
| 生命周期 | 除非主动删除，永久存在 | 随创建和销毁而存在   |

```
┌──────────┐   docker run    ┌──────────┐
│          │ ───────────────→ │ 容器 A   │
│          │   docker run    ┌──────────┐
│  镜像    │ ───────────────→ │ 容器 B   │  同一镜像 → 多个独立容器
│          │   docker run    ┌──────────┐
│          │ ───────────────→ │ 容器 C   │
└──────────┘                 └──────────┘
  只读模板                   各自有独立的可写层
```

## 2. 镜像操作

### 2.1 拉取镜像（pull）

`docker pull` 从 Registry 下载镜像到本地。

```bash
# 拉取官方 Nginx 镜像（默认标签 latest）
docker pull nginx

# 拉取指定版本
docker pull nginx:1.27

# 拉取指定平台的镜像（Apple Silicon 用户拉取 amd64 版本）
docker pull --platform linux/amd64 nginx:1.27

# 拉取完整地址（通常省略 docker.io/library/）
docker pull docker.io/library/nginx:1.27

# 通过摘要拉取（确保获取精确版本，不可变）
docker pull nginx@sha256:6af79ae5de407283dcea8b00d5c37ace95441fd58a8b1d2aa1ed93f5511bb18c
```

输出示例：

```
1.27: Pulling from library/nginx
a480a496ba95: Pull complete
f3ace1b8ce45: Pull complete
11d6fdd0e8a7: Pull complete
f1091da6956b: Pull complete
40eea07b53d8: Pull complete
6476794e50f4: Pull complete
70850b3ec6b2: Pull complete
Digest: sha256:6af79ae5de407283dcea8b00d5c37ace95441fd58a8b1d2aa1ed93f5511bb18c
Status: Downloaded newer image for nginx:1.27
docker.io/library/nginx:1.27
```

> **提示**：输出中每一行 `Pull complete` 对应一个镜像层。如果某层本地已存在，会显示 `Already exists`，无需重复下载。

**docker pull 常用选项**：

| 选项         | 说明                           |
| ------------ | ------------------------------ |
| `--platform` | 指定目标平台，如 `linux/amd64` |
| `-a`         | 拉取仓库中所有标签的镜像       |
| `-q`         | 静默模式，减少输出信息         |

> **提示**：同一个标签（如 `nginx:1.27`）可以对应多个平台的镜像——背后通过 **manifest list**（清单列表）实现。Docker 会根据你的机器架构（AMD64 / ARM64）自动选择正确的版本。Apple Silicon 和 Intel 用户拉取同一个标签时，实际得到的是不同架构的镜像。使用 `--platform` 可以显式指定目标架构。

### 2.2 查看镜像（images / inspect / history）

**列出本地镜像**：

```bash
# 列出所有本地镜像
docker images
```

输出示例：

```
REPOSITORY   TAG       IMAGE ID       CREATED        SIZE
nginx        1.27      39286ab8a5e1   2 weeks ago    188MB
node         22        b4dff5ae4d0e   3 weeks ago    1.1GB
postgres     16        3b6645015668   4 weeks ago    432MB
redis        7         e40e2763392d   4 weeks ago    138MB
```

```bash
# 按仓库名过滤
docker images nginx

# 按名称和标签过滤
docker images nginx:1.27

# 只显示镜像 ID
docker images -q

# 显示所有镜像（包括中间层）
docker images -a

# 按条件过滤（如悬空镜像）
docker images -f "dangling=true"
```

**查看镜像详细信息**：

```bash
# 查看镜像完整元数据（JSON 格式）
docker inspect nginx:1.27

# 查看指定字段：镜像架构
docker inspect --format='{{.Architecture}}' nginx:1.27
# 输出：amd64

# 查看指定字段：暴露端口
docker inspect --format='{{json .Config.ExposedPorts}}' nginx:1.27
# 输出：{"80/tcp":{}}

# 查看指定字段：镜像大小（字节）
docker inspect --format='{{.Size}}' nginx:1.27
# 输出：187694956
```

**查看镜像构建历史**：

```bash
# 查看镜像各层构建指令
docker history nginx:1.27
```

输出示例：

```
IMAGE          CREATED       CREATED BY                                      SIZE
39286ab8a5e1   2 weeks ago   CMD ["nginx" "-g" "daemon off;"]                0B
<missing>      2 weeks ago   STOPSIGNAL SIGQUIT                              0B
<missing>      2 weeks ago   EXPOSE map[80/tcp:{}]                           0B
<missing>      2 weeks ago   ENTRYPOINT ["/docker-entrypoint.sh"]            0B
<missing>      2 weeks ago   COPY 30-tune-worker-processes.sh /docker-en…    4.62kB
<missing>      2 weeks ago   COPY 20-envsubst-on-templates.sh /docker-en…    3.02kB
<missing>      2 weeks ago   COPY 15-local-resolvers.envsh /docker-entry…    389B
<missing>      2 weeks ago   COPY 10-listen-on-ipv6-by-default.sh /docke…    2.12kB
<missing>      2 weeks ago   COPY docker-entrypoint.sh / 0B                  1.62kB
<missing>      2 weeks ago   RUN /bin/sh -c set -x     && groupadd ...       61.4MB
<missing>      2 weeks ago   ENV DYNPKG_RELEASE=1~bookworm                   0B
<missing>      2 weeks ago   ENV NJS_RELEASE=1~bookworm                      0B
<missing>      2 weeks ago   ENV NJS_VERSION=0.8.9                           0B
<missing>      2 weeks ago   ENV PKG_RELEASE=1~bookworm                      0B
<missing>      2 weeks ago   ENV NGINX_VERSION=1.27.4                        0B
<missing>      2 weeks ago   /bin/sh -c #(nop)  CMD ["bash"]                 0B
<missing>      2 weeks ago   /bin/sh -c #(nop) ADD file:...                  74.8MB
```

> **提示**：`docker history` 可以帮助你理解镜像的构成，判断哪些层占用空间最大。SIZE 为 0B 的行通常是元数据指令（ENV、EXPOSE、CMD 等），不产生新的文件层。

### 2.3 标记镜像（tag）

`docker tag` 为现有镜像创建一个新的标签引用，不会复制镜像数据。

```bash
# 语法：docker tag 源镜像 目标镜像
docker tag nginx:1.27 my-registry.com/web/nginx:1.27

# 为本地镜像添加版本标签
docker tag my-app:latest my-app:v1.0.0

# 标记镜像用于推送到 Docker Hub
docker tag my-app:v1.0.0 username/my-app:v1.0.0
```

> **注意**：`docker tag` 只是创建了一个指向同一镜像的新引用（类似 Git 的标签）。原始标签和新标签指向相同的 Image ID，不会额外占用磁盘空间。

### 2.4 推送镜像（push）

`docker push` 将本地镜像上传到 Registry。

```bash
# 登录 Docker Hub
docker login

# 推送镜像到 Docker Hub（需要先 tag 为 username/image 格式）
docker push username/my-app:v1.0.0

# 推送到私有 Registry
docker push my-registry.com/web/nginx:1.27

# 推送所有标签
docker push --all-tags username/my-app
```

**推送流程**：

```
本地镜像 → docker tag → docker push → Registry
                                          ↓
                    其他机器 ← docker pull ←
```

> **注意**：推送前必须先 `docker login` 登录目标 Registry，且镜像名称必须包含正确的 Registry 地址和命名空间。

### 2.5 删除镜像（rmi）

```bash
# 删除指定镜像
docker rmi nginx:1.27

# 通过 Image ID 删除
docker rmi 39286ab8a5e1

# 强制删除（即使有容器引用）
docker rmi -f nginx:1.27

# 删除所有悬空镜像（无标签引用的中间层）
docker image prune

# 删除所有未被容器使用的镜像
docker image prune -a

# 批量删除：删除所有本地镜像
docker rmi $(docker images -q)
```

> **注意**：如果镜像正在被某个容器使用（即使容器已停止），`docker rmi` 会报错。需要先删除或强制移除关联的容器，或使用 `-f` 强制删除。

**镜像操作命令总结**：

| 命令                   | 简写             | 说明           |
| ---------------------- | ---------------- | -------------- |
| `docker image pull`    | `docker pull`    | 拉取镜像       |
| `docker image ls`      | `docker images`  | 列出镜像       |
| `docker image inspect` | `docker inspect` | 查看镜像详情   |
| `docker image history` | `docker history` | 查看构建历史   |
| `docker image tag`     | `docker tag`     | 标记镜像       |
| `docker image push`    | `docker push`    | 推送镜像       |
| `docker image rm`      | `docker rmi`     | 删除镜像       |
| `docker image prune`   | —                | 清理未使用镜像 |

## 3. Registry 与 Docker Hub

### 3.1 Registry 是什么

Registry 是存储和分发 Docker 镜像的服务端组件。它接收镜像的推送（push）和拉取（pull）请求，管理镜像的版本和访问权限。

```
┌──────────────┐  push   ┌────────────────┐  pull   ┌──────────────┐
│  开发者机器  │ ──────→ │    Registry    │ ←────── │  生产服务器  │
│  构建 + 标记 │         │  存储 + 分发   │         │  拉取 + 运行 │
└──────────────┘         └────────────────┘         └──────────────┘
```

**常见 Registry 服务**：

| Registry                   | 类型      | 适用场景           |
| -------------------------- | --------- | ------------------ |
| Docker Hub                 | 公共      | 开源项目、个人项目 |
| GitHub Container (ghcr.io) | 公共/私有 | GitHub 生态项目    |
| AWS ECR                    | 私有      | AWS 部署环境       |
| Google Artifact Registry   | 私有      | GCP 部署环境       |
| Azure Container Registry   | 私有      | Azure 部署环境     |
| Harbor                     | 自建      | 企业内网、合规要求 |

### 3.2 Docker Hub 使用

Docker Hub 是 Docker 官方的公共 Registry，也是 `docker pull` 的默认来源。

```bash
# 搜索镜像
docker search nginx

# 输出示例：
# NAME               DESCRIPTION                                   STARS   OFFICIAL
# nginx              Official build of Nginx.                      20000   [OK]
# bitnami/nginx      Bitnami container image for Nginx             200
# nginx/nginx-ingress NGINX and NGINX Plus Ingress Controllers…   100
```

```bash
# 登录 Docker Hub
docker login
# 按提示输入用户名和密码（或使用 Access Token）

# 登录其他 Registry
docker login ghcr.io
docker login my-registry.com

# 退出登录
docker logout
```

**Docker Hub 使用注意事项**：

- 匿名拉取（未登录）有较严格的速率限制（按 IP 计算），建议始终 `docker login` 后操作
- 免费账户有私有仓库数量限制，具体限额以 [Docker Hub 官方定价页面](https://www.docker.com/pricing/) 为准
- 付费方案提供更高的拉取速率和更多私有仓库

### 3.3 官方镜像 vs 社区镜像

Docker Hub 上的镜像分为两类：

| 特征     | 官方镜像（Official）              | 社区镜像（Community） |
| -------- | --------------------------------- | --------------------- |
| 命名格式 | `library/nginx`（简写为 `nginx`） | `username/image`      |
| 维护者   | Docker 官方或上游项目团队         | 个人或第三方组织      |
| 安全审查 | 定期安全扫描和审查                | 不保证                |
| 文档质量 | 完善的使用文档                    | 质量参差不齐          |
| 更新频率 | 及时跟进安全补丁                  | 取决于维护者          |
| 标识     | Docker Hub 显示 "Official Image"  | 无特殊标识            |

```bash
# ✅ 推荐：使用官方镜像
docker pull nginx:1.27
docker pull node:22-slim
docker pull postgres:16

# ❌ 谨慎：使用不明来源的社区镜像
docker pull randomuser/nginx-custom
```

**如何判断来源是否可信**：

| 检查项          | 说明                                                   |
| --------------- | ------------------------------------------------------ |
| Docker Hub 标识 | 查看是否有 "Official Image" 或 "Verified Publisher" 标 |
| 命名空间        | `library/nginx`（官方）vs `randomuser/nginx`（个人）   |
| 维护组织        | 知名组织（bitnami、grafana）比个人用户可信度高         |
| 维护频率        | 最近更新时间、Issue 响应速度                           |
| 文档质量        | 完善的 README 和使用说明                               |

> **提示**：优先选择官方镜像。如需社区镜像，选择 Stars 多、更新活跃、由知名组织维护的项目（如 `bitnami/nginx`）。

> **注意**：摘要（Digest）用于**锁定镜像内容**（确保你拉取到的是同一份镜像），而非验证发布者身份。确认发布者身份应通过 Docker Hub 页面的标识和命名空间判断。

### 3.4 镜像搜索与筛选

```bash
# 基本搜索
docker search node

# 只显示官方镜像
docker search --filter is-official=true node

# 只显示 Stars 大于 50 的镜像
docker search --filter stars=50 nginx

# 限制结果数量
docker search --limit 5 nginx
```

**docker search 过滤选项**：

| 过滤条件                    | 说明                    |
| --------------------------- | ----------------------- |
| `--filter is-official=true` | 只显示官方镜像          |
| `--filter stars=N`          | 只显示 Stars ≥ N 的     |
| `--limit N`                 | 限制返回结果数（≤ 100） |

> **提示**：`docker search` 只能搜索镜像名称和描述，无法搜索标签。查看某个镜像的所有可用标签，需要访问 Docker Hub 网页或使用 Docker Hub API。

## 4. 标签策略

### 4.1 latest 的陷阱

`latest` 是 Docker 的默认标签，但它的行为经常与直觉不符：

```bash
# 以下两条命令等价
docker pull nginx
docker pull nginx:latest
```

**`latest` 不代表"最新版本"**——它只是一个普通标签名，镜像维护者可以将它指向任意版本。

```bash
# ❌ 危险：不同时间拉取的 latest 可能是不同版本
# 周一部署
docker pull node:latest    # 实际拉到 Node.js 22.x

# 周五另一台服务器部署
docker pull node:latest    # 维护者更新了，实际拉到 Node.js 23.x

# 结果：两台服务器运行不同版本，行为不一致
```

```bash
# ✅ 安全：明确指定版本标签
docker pull node:22.14
```

**latest 的问题总结**：

| 问题           | 说明                                 |
| -------------- | ------------------------------------ |
| 版本不确定     | 不同时间拉取可能得到不同版本         |
| 无法回滚       | 不知道之前运行的是哪个具体版本       |
| 缓存不可靠     | 本地缓存的 latest 可能已过时         |
| 团队不一致     | 不同成员本地的 latest 版本可能不同   |
| CI/CD 不可复现 | 相同的构建配置在不同时间产生不同结果 |

### 4.2 语义化标签

成熟的官方镜像通常提供多级标签，从精确到宽泛：

以 `node` 镜像为例：

| 标签格式             | 示例           | 含义                             | 稳定性 |
| -------------------- | -------------- | -------------------------------- | ------ |
| `主版本.次版本.补丁` | `node:22.14.0` | 精确版本，完全锁定               | 最高   |
| `主版本.次版本`      | `node:22.14`   | 锁定主版本和次版本，接收补丁更新 | 高     |
| `主版本`             | `node:22`      | 锁定主版本，接收次版本和补丁更新 | 中     |
| `latest`             | `node:latest`  | 指向当前默认版本，随时可能变化   | 低     |

**变体标签**：

| 后缀        | 示例               | 说明                                |
| ----------- | ------------------ | ----------------------------------- |
| `-bookworm` | `node:22-bookworm` | 基于 Debian Bookworm 的完整版       |
| `-slim`     | `node:22-slim`     | 精简版 Debian，去除非必要工具       |
| `-alpine`   | `node:22-alpine`   | 基于 Alpine Linux，体积最小         |
| `-bullseye` | `node:20-bullseye` | 基于 Debian Bullseye（旧版 Debian） |

### 4.3 锁定版本的最佳实践

```bash
# ❌ 不推荐：使用 latest
FROM node:latest

# ❌ 不推荐：只指定主版本（次版本更新可能引入不兼容变更）
FROM node:22

# ✅ 推荐：指定到次版本 + 变体
FROM node:22.14-slim

# ✅ 最严格：使用摘要锁定（适合生产环境）
FROM node:22.14-slim@sha256:abc123...
```

**不同环境的标签策略**：

| 环境     | 推荐策略                           | 原因                   |
| -------- | ---------------------------------- | ---------------------- |
| 本地开发 | 主版本 + 变体 `node:22-slim`       | 平衡灵活性和一致性     |
| CI/CD    | 次版本 + 变体 `node:22.14-slim`    | 确保构建可复现         |
| 生产部署 | 精确版本或摘要 `node:22.14.0-slim` | 绝对一致，防止意外更新 |

## 5. 镜像分层深入

### 5.1 Layer 复用机制

分层结构最大的优势之一是**层复用**。当多个镜像共享相同的基础层时，Docker 只存储一份，其他镜像引用同一份数据。

```
镜像 A: my-app-web               镜像 B: my-app-api
┌──────────────────────┐         ┌──────────────────────┐
│ Layer: COPY dist/    │  独有   │ Layer: COPY src/     │  独有
├──────────────────────┤         ├──────────────────────┤
│ Layer: npm install   │  独有   │ Layer: npm install   │  独有
├──────────────────────┤         ├──────────────────────┤
│ Layer: node:22-slim  │  共享 ←──→ 磁盘上只存一份     │
└──────────────────────┘         └──────────────────────┘
```

**复用场景**：

| 场景       | 说明                                               |
| ---------- | -------------------------------------------------- |
| 多镜像共存 | 同一基础镜像的多个应用只存储一份基础层             |
| 镜像拉取   | 已有的层显示 `Already exists`，只下载缺少的层      |
| 镜像推送   | Registry 端同样复用，相同层只存一份                |
| 版本更新   | 更新补丁版本时，基础层不变，只重新下载顶部变化的层 |

```bash
# 示例：第二次 pull 共享基础层
docker pull node:22-slim
# ...全部层下载完成

docker pull node:22-bookworm
# a480a496ba95: Already exists    ← 共享的 Debian 基础层
# f3ace1b8ce45: Already exists    ← 共享的系统库层
# 7d2b4ef9ac7f: Pull complete     ← Node.js 不同配置的独有层
```

### 5.2 docker history 解读

`docker history` 展示镜像从底层到顶层的每一步构建指令：

```bash
docker history node:22-slim
```

```
IMAGE          CREATED       CREATED BY                                      SIZE
e3f4d2a09b1c   2 weeks ago   CMD ["node"]                                    0B
<missing>      2 weeks ago   ENTRYPOINT ["docker-entrypoint.sh"]             0B
<missing>      2 weeks ago   COPY docker-entrypoint.sh /usr/local/bin/ …     388B
<missing>      2 weeks ago   RUN /bin/sh -c ... && npm install ...           50.3MB
<missing>      2 weeks ago   ENV NODE_VERSION=22.14.0                        0B
<missing>      2 weeks ago   RUN groupadd --gid 1000 node ...               8.94kB
<missing>      2 weeks ago   /bin/sh -c #(nop) CMD ["bash"]                  0B
<missing>      2 weeks ago   /bin/sh -c #(nop) ADD file:... in /             74.8MB
```

**解读要点**：

| 字段       | 说明                                        |
| ---------- | ------------------------------------------- |
| IMAGE      | 层的 ID，`<missing>` 表示中间层（正常现象） |
| CREATED    | 层的创建时间                                |
| CREATED BY | 创建该层的 Dockerfile 指令                  |
| SIZE       | 该层新增的文件大小                          |

**分析技巧**：

- SIZE 为 `0B` 的层是元数据指令（ENV、CMD、EXPOSE），不增加镜像体积
- `RUN` 和 `ADD`/`COPY` 指令通常产生实际的文件层
- 从底部到顶部阅读，对应 Dockerfile 从上到下的指令顺序
- `<missing>` 不代表错误，只是表示该层没有独立的 Image ID

```bash
# 显示完整的 CREATED BY 内容（不截断）
docker history --no-trunc node:22-slim

# 只看有实际大小的层
docker history node:22-slim --format "{{.Size}}\t{{.CreatedBy}}" | grep -v "0B"
```

### 5.3 镜像大小分析

了解镜像的实际磁盘占用对优化很重要。

```bash
# 查看本地镜像大小
docker images
# REPOSITORY   TAG        SIZE
# node         22         1.1GB
# node         22-slim    260MB
# node         22-alpine  180MB
# nginx        1.27       188MB
# nginx        1.27-alpine 43MB

# 查看 Docker 整体磁盘使用
docker system df
```

输出示例：

```
TYPE            TOTAL   ACTIVE  SIZE      RECLAIMABLE
Images          8       3       2.45GB    1.2GB (48%)
Containers      5       2       120MB     80MB (66%)
Local Volumes   3       2       500MB     200MB (40%)
Build Cache     15      0       800MB     800MB (100%)
```

```bash
# 查看详细的磁盘使用（每个镜像的实际占用和共享情况）
docker system df -v
```

> **提示**：`docker images` 显示的 SIZE 是镜像的虚拟大小（所有层的总和）。由于层的共享，实际磁盘占用通常小于各镜像 SIZE 之和。`docker system df` 显示的是实际磁盘使用量。

## 6. 镜像安全

### 6.1 来源可信度

镜像安全的第一道防线是确保来源可信。

**镜像选择决策流程**：

| 优先级 | 来源                   | 可信度 | 说明                           |
| ------ | ---------------------- | ------ | ------------------------------ |
| 1      | Docker Official Images | 高     | Docker 官方维护，定期安全审查  |
| 2      | Verified Publisher     | 高     | 经 Docker 验证的商业软件发布者 |
| 3      | Docker-Sponsored OSS   | 较高   | Docker 赞助的开源项目          |
| 4      | 知名组织的社区镜像     | 中     | 如 `bitnami/`、`grafana/`      |
| 5      | 个人用户的社区镜像     | 低     | 需仔细审查，不建议用于生产     |

```bash
# 查看镜像的摘要（用于锁定内容，确保可复现拉取）
docker inspect --format='{{index .RepoDigests 0}}' nginx:1.27
# 输出：nginx@sha256:6af79ae5de407283dcea8b00d5c37ace95441fd58a8b1d2aa1ed93f5511bb18c
```

> **注意**：对可复现性要求高的生产环境，优先使用摘要（Digest）引用镜像，确保拉取到的内容不变；至少应避免 `latest`，使用固定版本标签（如 `nginx:1.27`）。但摘要锁定也有代价——你需要主动更新摘要以获取安全补丁，否则可能长期停留在包含已知漏洞的旧版本上。

### 6.2 漏洞扫描

Docker Scout 是 Docker 内置的镜像安全扫描工具，可以检测镜像中的已知漏洞（CVE）。

```bash
# 快速查看镜像安全概况
docker scout quickview nginx:1.27

# 查看详细漏洞列表
docker scout cves nginx:1.27

# 获取修复建议（推荐的基础镜像更新）
docker scout recommendations nginx:1.27
```

**常用扫描工具对比**：

| 工具           | 类型 | 说明                           |
| -------------- | ---- | ------------------------------ |
| Docker Scout   | 内置 | Docker Desktop 集成，SBOM 分析 |
| Trivy          | 开源 | Aqua Security 开源，CI/CD 友好 |
| Snyk Container | 商业 | 提供修复建议和持续监控         |
| Grype          | 开源 | Anchore 开源，轻量快速         |

### 6.3 前端常用基础镜像选择

前端项目通常需要两类基础镜像：构建阶段使用 Node.js 镜像，运行阶段使用 Nginx 镜像。

**Node.js 镜像变体对比**：

| 变体             | 基础系统        | 大小    | 适用场景                          |
| ---------------- | --------------- | ------- | --------------------------------- |
| `node:22`        | Debian Bookworm | ~1.1 GB | 需要完整编译工具链（如 node-gyp） |
| `node:22-slim`   | Debian Slim     | ~260 MB | 大多数前端项目的构建阶段          |
| `node:22-alpine` | Alpine Linux    | ~180 MB | 追求最小体积，无 glibc 兼容问题时 |

**Nginx 镜像变体对比**：

| 变体                | 基础系统        | 大小    | 适用场景               |
| ------------------- | --------------- | ------- | ---------------------- |
| `nginx:1.27`        | Debian Bookworm | ~188 MB | 需要完整系统工具时     |
| `nginx:1.27-alpine` | Alpine Linux    | ~43 MB  | 纯静态文件服务（推荐） |

**前端项目推荐组合**（React/Vite 项目）：

| 阶段     | 推荐镜像            | 理由                                   |
| -------- | ------------------- | -------------------------------------- |
| 构建阶段 | `node:22-slim`      | 体积适中，兼容性好，满足 npm/Vite 构建 |
| 运行阶段 | `nginx:1.27-alpine` | 只需提供静态文件服务，体积最小         |

> **提示**：Alpine 镜像使用 musl libc 而非 glibc。少数 npm 包依赖 glibc 原生模块（如 `sharp`、`bcrypt`），在 Alpine 上可能需要额外配置。如遇到兼容问题，改用 `-slim` 变体。

## 7. 总结

### 7.1 核心要点

- **镜像本质**：包含运行应用所有依赖的只读分层文件包，是容器的创建模板
- **分层机制**：每层只存储差异，多镜像共享相同底层，节省存储和传输开销
- **镜像操作**：pull 拉取、images 查看、inspect 详情、history 历史、tag 标记、push 推送、rmi 删除
- **Registry**：镜像的存储和分发服务，Docker Hub 是默认的公共 Registry
- **标签策略**：避免使用 latest，生产环境使用精确版本号或摘要锁定
- **安全实践**：优先使用官方镜像，定期扫描漏洞，选择最小化基础镜像

### 7.2 速查表

| 命令                                        | 说明                 |
| ------------------------------------------- | -------------------- |
| `docker pull <镜像>:<标签>`                 | 拉取指定版本镜像     |
| `docker pull --platform linux/amd64 <镜像>` | 拉取指定平台镜像     |
| `docker images`                             | 列出本地镜像         |
| `docker images -f "dangling=true"`          | 列出悬空镜像         |
| `docker inspect <镜像>`                     | 查看镜像详细信息     |
| `docker history <镜像>`                     | 查看镜像构建历史     |
| `docker history --no-trunc <镜像>`          | 查看完整构建指令     |
| `docker tag <源> <目标>`                    | 为镜像创建新标签     |
| `docker push <镜像>`                        | 推送镜像到 Registry  |
| `docker rmi <镜像>`                         | 删除镜像             |
| `docker image prune`                        | 清理悬空镜像         |
| `docker image prune -a`                     | 清理所有未使用镜像   |
| `docker system df`                          | 查看 Docker 磁盘使用 |
| `docker search <关键词>`                    | 搜索 Docker Hub 镜像 |
| `docker login`                              | 登录 Registry        |
| `docker scout cves <镜像>`                  | 扫描镜像漏洞         |

## 参考资源

知道了如何选择和管理镜像，下一步是把镜像运行起来——学习容器的创建、监控和故障排查。见[Docker 容器管理完全指南](docker-3-containers.md)。

- [Docker 镜像官方文档](https://docs.docker.com/engine/reference/commandline/image/)
- [Docker Hub](https://hub.docker.com/)
- [Docker Official Images](https://hub.docker.com/search?image_filter=official)
- [Docker Scout 文档](https://docs.docker.com/scout/)
- [Node.js 官方 Docker 镜像](https://hub.docker.com/_/node)
- [Nginx 官方 Docker 镜像](https://hub.docker.com/_/nginx)
- [Alpine Linux Docker 镜像](https://hub.docker.com/_/alpine)
