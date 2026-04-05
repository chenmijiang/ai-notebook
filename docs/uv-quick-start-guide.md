# uv 快速入门与使用指南

## 1. 概述

### 1.1 什么是 uv

`uv` 是一个极快的 Python 包和项目管理工具，用 Rust 编写。它可以用来安装 Python、创建虚拟环境、管理依赖、运行脚本，还提供了类似 `pip` 的兼容接口。

### 1.2 为什么要学 uv

| 需求         | uv 的做法   | 好处                 |
| ------------ | ----------- | -------------------- |
| 创建项目     | `uv init`   | 快速生成项目结构     |
| 安装依赖     | `uv add`    | 自动更新锁定文件     |
| 运行命令     | `uv run`    | 不用手动激活环境     |
| 管理 Python  | `uv python` | 统一安装和切换版本   |
| 临时使用工具 | `uvx`       | 即用即走，不污染环境 |

> **提示**：如果你之前习惯使用 `pip`、`venv` 或 `poetry`，可以把 `uv` 看作一个更快、更统一的工具链。

## 2. 安装与验证

### 2.1 安装 uv

macOS 和 Linux：

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Windows PowerShell：

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

### 2.2 检查是否安装成功

```bash
uv --version
```

如果能看到版本号，说明安装成功。

## 3. 创建第一个项目

### 3.1 初始化项目

```bash
uv init hello-uv
cd hello-uv
```

执行后，`uv` 会帮你生成一个基础项目。

### 3.2 查看项目结构

一个典型的 `uv` 项目通常会包含：

| 文件/目录         | 作用               |
| ----------------- | ------------------ |
| `pyproject.toml`  | 项目配置和依赖声明 |
| `.python-version` | 锁定 Python 版本   |
| `README.md`       | 项目说明           |
| `main.py`         | 示例入口文件       |

> **注意**：`.venv/` 通常会在你执行 `uv sync` 或 `uv run` 之后才创建，不会在 `uv init` 后立刻出现。

### 3.3 最短上手路径

这是新手最常见的使用流程：

```bash
uv init hello-uv
cd hello-uv
uv add requests
uv run main.py
```

这一步的目的，是让你先把依赖装进项目里，再用项目环境运行代码。

如果你想马上看到依赖生效，可以把 `main.py` 改成下面这样：

```python
import requests

def main():
    print(requests.__version__)

if __name__ == "__main__":
    main()
```

执行 `uv run` 时，`uv` 会按项目环境运行命令，并在需要时安装或更新依赖；如果需要的 Python 版本还没安装，也会自动下载。

> **注意**：`uv` 默认会优先围绕 `pyproject.toml` 管理项目。

## 4. 管理依赖

### 4.1 添加依赖

```bash
uv add requests
```

这会同时完成两件事：

1. 把依赖写入项目配置
2. 安装依赖到当前环境

### 4.2 安装开发依赖

```bash
uv add --dev pytest
```

开发依赖通常用于测试、格式化、检查等场景。

### 4.3 移除依赖

```bash
uv remove requests
```

### 4.4 同步依赖

```bash
uv sync
```

这个命令会根据锁定文件和项目配置同步环境，适合在拉取代码后重建本地环境。

## 5. 运行脚本

### 5.1 运行项目命令

```bash
uv run main.py
```

`uv run` 会按项目环境运行命令，不需要你手动执行 `source .venv/bin/activate`。

### 5.2 运行临时脚本

如果你只是想快速试一段代码，可以直接用 `uv run`：

```bash
uv run python -c "print('hello uv')"
```

### 5.3 使用脚本依赖

对于单文件脚本，`uv` 也可以管理脚本依赖：

```bash
uv add --script demo.py requests
uv run demo.py
```

这会把依赖写进脚本头部的内联元数据中，例如：

```python
# /// script
# dependencies = ["requests"]
# ///
import requests
```

脚本依赖和项目依赖是分开的，更适合临时脚本。

## 6. 虚拟环境与 Python 版本

### 6.1 创建虚拟环境

```bash
uv venv
```

创建后，默认会生成 `.venv` 目录。

### 6.2 指定 Python 版本

```bash
uv venv --python 3.12
```

### 6.3 安装 Python 版本

```bash
uv python install 3.11 3.12
```

### 6.4 固定项目 Python 版本

```bash
uv python pin 3.12
```

这个命令会写入 `.python-version`，方便团队统一版本。

## 7. 临时工具与 pip 兼容接口

### 7.1 临时运行工具

```bash
uvx ruff --version
```

`uvx` 适合快速试用命令行工具，不需要长期安装。

### 7.2 使用 pip 风格命令

如果你还想保留 `pip` 的使用习惯，可以用：

```bash
uv pip install requests
uv pip list
```

> **提示**：新项目优先用 `uv add` 和 `uv sync`，迁移旧项目时再重点看 `uv pip` 接口。

## 8. 常见问题

### 8.1 为什么不需要手动激活虚拟环境

因为 `uv run` 会自动在项目环境中执行命令，减少了环境切换成本。

### 8.2 `uv add` 和 `uv pip install` 有什么区别

| 命令             | 适用场景                             |
| ---------------- | ------------------------------------ |
| `uv add`         | 新项目或 `pyproject.toml` 管理的项目 |
| `uv pip install` | 兼容旧的 `pip` 工作流                |

### 8.3 如何让团队保持一致

建议同时提交这些文件：

| 文件              | 作用             |
| ----------------- | ---------------- |
| `pyproject.toml`  | 声明项目和依赖   |
| `uv.lock`         | 锁定依赖版本     |
| `.python-version` | 固定 Python 版本 |

## 9. 总结速查表

| 目标         | 命令                                                     |
| ------------ | -------------------------------------------------------- |
| 安装 uv      | `curl -LsSf https://astral.sh/uv/install.sh` 后执行 `sh` |
| 初始化项目   | `uv init demo`                                           |
| 添加依赖     | `uv add requests`                                        |
| 安装开发依赖 | `uv add --dev pytest`                                    |
| 运行脚本     | `uv run main.py`                                         |
| 创建虚拟环境 | `uv venv`                                                |
| 安装 Python  | `uv python install 3.12`                                 |
| 固定版本     | `uv python pin 3.12`                                     |
| 临时运行工具 | `uvx ruff --version`                                     |

## 10. 参考资源

- uv 官方文档：https://docs.astral.sh/uv/
- uv GitHub：https://github.com/astral-sh/uv
