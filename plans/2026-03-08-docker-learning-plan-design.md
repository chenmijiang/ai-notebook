# Docker 学习计划设计

## 背景

- 学习者：前端开发者，有 Docker 基础使用经验（docker run / docker pull 等）
- 目标：系统深入掌握 Docker 核心知识，包括网络、存储、编排等，能在团队中主导容器化方案
- 范围：Docker 核心 + Docker Compose（不含 Kubernetes）

## 方案选择

采用**按概念分层**方案，从底层概念逐层递进。理由：
- 学习者已有基础，适合系统化梳理
- 分层结构适合作为长期参考文档
- 与仓库已有系列（ESLint 7 篇、Prettier 7 篇）风格一致

## 系列主线

> 从理解 Docker，到掌握单容器运行，再到构建镜像，最后完成多容器项目编排

7 篇不是并列主题，而是一条明确的成长路径。

## 系列结构（7 篇）

| 篇号 | 文件名 | 主题 | 核心问题 |
|------|--------|------|---------|
| 1 | `docker-1-fundamentals.md` | 基础与核心概念 | Docker 是什么，为什么需要它 |
| 2 | `docker-2-images.md` | 镜像与仓库 | 镜像是什么，怎么选，怎么管 |
| 3 | `docker-3-containers.md` | 容器运行与管理 | 容器怎么跑，怎么查，怎么控 |
| 4 | `docker-4-dockerfile.md` | Dockerfile 与镜像构建 | 镜像怎么造，怎么优化 |
| 5 | `docker-5-networking.md` | 网络 | 容器怎么通信，怎么暴露服务 |
| 6 | `docker-6-storage.md` | 数据管理 | 数据怎么持久化，该选哪种方式 |
| 7 | `docker-7-compose.md` | Docker Compose 与多容器编排 | 怎么把前 6 篇组织成完整项目 |

## 各篇详细内容

### 第 1 篇：基础与核心概念

- Docker 是什么：定位与解决的问题
- 容器 vs 虚拟机：架构对比、性能差异、适用场景
- Docker 架构：Client-Server 模型、Docker Daemon、Docker CLI、Registry
- 核心概念三件套：Image / Container / Registry 的关系
- 底层原理入门：Namespace / Cgroup / UnionFS（建立心智模型，不做过深展开，后文涉及时回扣）
- 安装与验证：macOS (Docker Desktop) 环境配置
- 第一个容器：`docker run hello-world` 背后发生了什么

### 第 2 篇：镜像与仓库

重点：拿来用、怎么看、怎么分发

- 镜像基础：镜像是什么、只读分层结构
- 镜像操作：pull / images / inspect / history / tag / push / rmi
- Registry 与 Docker Hub：搜索、官方镜像 vs 社区镜像
- 标签策略与版本选择：latest 的陷阱、语义化标签、锁定版本
- 镜像分层深入：layer 复用、`docker history` 解读
- 镜像安全与来源可信度：扫描漏洞、可信镜像
- 团队镜像分发习惯

### 第 3 篇：容器运行与管理

重点：镜像如何变成运行中的实例、出问题时怎么查

- 容器生命周期：create → start → running → pause → stop → remove
- 核心操作：run / start / stop / restart / rm / ps
- 观察与排障：inspect / logs / exec / stats / top
- 退出码：含义与常见退出码排查
- 环境变量与配置：-e / --env-file / 配置注入模式
- 资源限制：CPU / 内存限制、OOM 处理
- 重启策略：no / always / unless-stopped / on-failure
- 健康检查基础：HEALTHCHECK 指令入门
- 常见故障排查路径：容器启动失败、意外退出、网络不通等

### 第 4 篇：Dockerfile 与镜像构建

重点：怎么自己产出镜像（读者已具备容器运行的前置知识）

- Dockerfile 指令体系：FROM / RUN / COPY / WORKDIR / EXPOSE / CMD / ENTRYPOINT
- 构建上下文与 .dockerignore
- 指令对比：COPY vs ADD、CMD vs ENTRYPOINT、ARG vs ENV
- 构建缓存：原理、缓存失效规则、优化构建顺序
- 多阶段构建：原理与前端场景（build 阶段 + Nginx 服务阶段）
- 前端项目实战：React/Vue SPA 的 Dockerfile 编写
- 构建优化：减小镜像体积、安全性、可维护性

### 第 5 篇：网络

重点：单机高频网络场景，聚焦实战

- Docker 网络模型：容器网络基础概念
- 端口映射：-p 详解、随机端口、指定 IP、为什么 -p 3000:80 这样映射
- Bridge 网络：默认 bridge 的局限、自定义 bridge 网络
- 容器 DNS：为什么容器名可以互相访问
- 容器间通信：同网络直接通信、跨网络通信
- 常见困惑：为什么容器里访问 localhost 不对
- 前端场景：Nginx 反向代理到后端 API 容器
- 扩展了解：host / none / overlay 网络模式简介

### 第 6 篇：数据管理

重点：场景决策指南，什么时候该选哪种方式

- 容器数据问题：为什么容器数据会丢失
- 三种挂载方式对比：Volume / Bind Mount / tmpfs 各自适合什么场景
- Volume：create / ls / inspect / rm、命名 Volume vs 匿名 Volume
- Bind Mount：开发环境热重载、权限问题处理
- 开发环境 vs 生产环境：挂载策略的选择
- 数据备份与恢复策略
- 前端项目常见坑：源码挂载 HMR、node_modules 处理、构建产物持久化

### 第 7 篇：Docker Compose 与多容器编排

重点：把前 6 篇组织成完整项目的"胶水层"

- Compose 是什么：从单容器到多容器的组织方式
- 核心配置：services / networks / volumes
- 服务定义：image / build / ports / volumes / environment / depends_on
- 生命周期管理：up / down / logs / ps
- 环境管理：.env 文件、多环境配置（dev/staging/prod）
- 综合实战：前端 (Nginx) + Node.js API + PostgreSQL + Redis 完整编排

## 设计要点

- 每篇独立成文，可单独查阅
- 前端场景贯穿全系列（Nginx 部署 SPA、Node.js BFF 容器化、前端开发环境统一）
- 第 2～4 篇边界清晰：第 2 篇管"选与分发"、第 3 篇管"运行与排障"、第 4 篇管"构建与优化"
- 第 3 篇在第 4 篇之前，确保读者写 Dockerfile 时已理解容器运行机制
- 第 5 篇聚焦高频单机场景，overlay 等进阶内容仅作扩展了解
- 第 6 篇定位为"决策指南"而非"术语说明"
- 第 7 篇作为整合收尾，突出"组织多容器项目"的角色
- 文档风格与仓库已有系列保持一致
