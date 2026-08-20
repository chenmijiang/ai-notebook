# Ponytail 使用指南

Ponytail 是一套供 AI 编程 Agent 使用的行为规则。它不生成脚手架，也不进入应用的运行链路，而是约束 Agent 写代码前的选择顺序：先弄清需求和调用链，能不写就不写，能复用就不重做；标准库和平台原生能力都不够用时，再补上最小实现。

本文以 Ponytail `4.9.0` 为基准，面向熟悉 AI 编程 Agent、但没有使用过 Ponytail 的开发者。各 Agent 的接入能力会随版本变化，安装时仍应核对对应版本的 README。

## 1. Ponytail 解决什么问题

AI 编程 Agent 容易把小需求做大。比如“加一个日期选择器”，它可能引入组件库，再补一层封装和一份样式。浏览器原生控件已经够用时，这些代码没有带来新能力，只增加了依赖和维护成本：

```html
<!-- ✅ 原生能力满足需求时，直接使用 -->
<label for="birthday">生日</label>
<input id="birthday" name="birthday" type="date" />
```

Ponytail 没有简单地要求 Agent “写短一点”，而是规定先检查什么、后检查什么。它要省掉的是不必要的实现，不是校验、错误处理或可读性。

Ponytail 的定位很明确：

- 它是 Agent 行为规则，也提供过度设计审查 Skill；
- 它不是代码生成框架，也不是应用运行时依赖；
- 它不能替代正确性、安全性或性能 Review。

## 2. 核心决策阶梯

Agent 在理解需求和真实调用链后，从上到下检查，命中第一项即可停止：

```text
理解需求与调用链
  ├─ 1. 需求真的需要实现吗？          否 → 不做（YAGNI）
  ├─ 2. 仓库里已有可复用实现吗？      是 → 复用
  ├─ 3. 标准库能解决吗？              是 → 使用标准库
  ├─ 4. 平台原生能力能解决吗？        是 → 使用原生能力
  ├─ 5. 已安装依赖能解决吗？          是 → 复用依赖
  ├─ 6. 能否用一行清楚地完成？        是 → 使用一行实现
  └─ 7. 以上都不满足                  → 编写能工作的最小实现
```

这套顺序有两个前提：

1. Agent 要先读完受影响的代码，追到真实调用链，再谈简化。Diff 很小却改错了位置，只会留下第二个 Bug。
2. 修 Bug 时要找根因。多个路径共用同一个函数，就在共享函数里修一次，不要在每个调用方各加一个 Guard。

### 2.1 典型选择

| 需求            | 容易过度设计的方案            | Ponytail 优先选择          |
| --------------- | ----------------------------- | -------------------------- |
| 日期输入        | 引入日期选择器库和 Wrapper    | 原生 `<input type="date">` |
| Python 函数缓存 | 自建缓存类                    | `functools.lru_cache`      |
| 唯一性约束      | 只在应用层查询后判断          | 数据库唯一约束             |
| 单一实现        | 提前定义 Interface 和 Factory | 直接使用具体实现           |
| 尚无性能证据    | 预先添加复杂缓存              | 暂不实现，先测量           |

## 3. 不能省掉的边界

以下内容不在精简范围内：

- 信任边界上的输入校验；
- 防止数据丢失的错误处理和安全措施；
- 基础无障碍能力；
- 用户明确要求的行为；
- 真实硬件所需的校准参数。

如果实现中包含分支、循环或数据解析，至少保留一个可运行的检查，例如 `assert` 自检或一个小型测试文件；单纯的一行调用不必为此专门创建测试。

有些简单方案现在够用，但存在已知上限。此时用 `ponytail:` 注释记录限制和升级条件：

```python
# ponytail: 当前使用全局锁；并发成为瓶颈时改为按账户分锁
```

这类注释要回答两个问题：为什么现在不升级，以及看到什么信号后再改。`ponytail-debt` 可以汇总这些标记。

## 4. 在 Claude Code 中使用

本文只演示 Claude Code。其他 Agent 的安装方式和能力差异见官方 Agent Portability 文档。

### 4.1 安装

依次发送两条独立命令：

```bash
/plugin marketplace add DietrichGebert/ponytail
```

```bash
/plugin install ponytail@ponytail
```

Claude Code 插件的生命周期 Hook 使用 Node.js，因此 `node` 必须位于非交互 Shell 的 `PATH` 中。缺少 Node.js 时仍可使用 Skill，但自动激活不会正常工作。

### 4.2 切换模式

| 命令                            | 行为                                     |
| ------------------------------- | ---------------------------------------- |
| `/ponytail lite`                | 完成需求，同时指出更简单的替代方案       |
| `/ponytail full`                | 执行完整决策阶梯；默认模式               |
| `/ponytail ultra`               | 更激进地优先删除和 YAGNI，并质疑可省需求 |
| `/ponytail off`                 | 关闭当前模式                             |
| `/ponytail`                     | 查看当前模式                             |
| `stop ponytail` / `normal mode` | 以独立消息停用模式                       |

普通模式切换只影响当前会话。设置以后每个会话的默认模式，可以使用环境变量：

```bash
export PONYTAIL_DEFAULT_MODE=ultra
```

也可以写入配置文件：

```json
{
  "defaultMode": "lite"
}
```

macOS 和 Linux 的默认路径是 `~/.config/ponytail/config.json`，Windows 是 `%APPDATA%\ponytail\config.json`。设置 `XDG_CONFIG_HOME` 后，配置文件改为 `$XDG_CONFIG_HOME/ponytail/config.json`。

## 5. 附加 Skill 与工作流

主 Skill 持续约束编码行为，另外五个 Skill 各处理一类单次任务：

| Skill             | 范围             | 作用                                       |
| ----------------- | ---------------- | ------------------------------------------ |
| `ponytail-review` | 当前 Diff        | 列出可删除或简化的过度设计，不自动修改     |
| `ponytail-audit`  | 整个仓库         | 按收益排序删除、标准库替换和原生替换候选   |
| `ponytail-debt`   | `ponytail:` 注释 | 汇总已知上限、升级条件和缺少触发条件的条目 |
| `ponytail-gain`   | 已发布基准       | 展示公开基准，不推算当前仓库收益           |
| `ponytail-help`   | 命令帮助         | 显示模式、Skill、停用方式和配置            |

`ponytail-review` 和 `ponytail-audit` 只看复杂度，不查正确性、安全性或性能。推荐工作流如下：

```text
1. 正常描述编码任务
2. Ponytail 按决策阶梯完成最小改动
3. 运行项目已有的格式、类型和测试检查
4. 用 /ponytail-review 检查当前 Diff 是否仍有冗余
5. 另做正确性与安全 Review
```

代码里出现 `ponytail:` 标记后，再用 `/ponytail-debt` 汇总。没有标记就不建台账。

## 6. 运行机制

Ponytail 把通用规则放在 `skills/`，适配器只负责让不同 Agent 加载这些规则：

| 接入方式   | 能力                               | 典型形式                        |
| ---------- | ---------------------------------- | ------------------------------- |
| 插件适配   | 自动注入、模式切换和附加 Skill     | Claude Code、Codex、OpenCode 等 |
| Skill 适配 | 按任务加载主 Skill 和附加 Skill    | 支持 Agent Skills 的 Agent      |
| 仅指令适配 | 加载核心规则，不提供 Hook 模式管理 | `AGENTS.md`、Agent 专用规则文件 |

核心规则只维护一份，避免各平台的副本逐渐不一致。各 Agent 的完整能力矩阵以官方文档为准。

Claude Code 通过三个 Hook 维持模式：

```text
SessionStart
  → 读取默认模式
  → 注入对应规则

UserPromptSubmit
  → 识别模式切换或停用命令

SubagentStart
  → 将当前规则传给新 Subagent
```

这解释了为什么规则可以跨消息持续生效，也能传给 Subagent。状态文件、匹配器和不同 Agent 的输出协议属于适配器实现细节，普通使用无需配置。

## 7. 基准结果与限制

2026-06-18 的 Agentic Benchmark 使用 Haiku 4.5，让真实的 headless Claude Code 会话修改固定版本的 `full-stack-fastapi-template`。功能组有 12 个任务，每个实验分支对每项任务运行 4 次。

| 相对无 Skill 基线       | 源码行数 | Token | 成本 | 时间 |
| ----------------------- | -------: | ----: | ---: | ---: |
| Ponytail                |     -54% |  -22% | -20% | -27% |
| Caveman                 |     -20% |   +7% |  +3% |  +2% |
| “YAGNI + one-liner”提示 |     -33% |  -14% | -21% | -30% |

固定对抗检查中，Baseline、Caveman 和 Ponytail 都通过了 20/20 次运行；“YAGNI + one-liner”提示通过 19/20 次。

这些数字只适用于该模型、仓库、任务和评测方法：

- 源码行数来自 Agent 留下的 `git diff`，不是回答文本长度；
- 100% 只表示通过了固定对抗检查，不是安全审计结论；
- 结果不能用来推算另一个仓库会节省多少代码或成本。

完整方法、任务口径和限制见官方 Benchmark 文档。

## 8. 总结与参考资源

### 8.1 核心要点

| 主题     | 要点                                                          |
| -------- | ------------------------------------------------------------- |
| 定位     | 面向 AI 编程 Agent 的最小实现规则，不是业务框架               |
| 决策顺序 | YAGNI → 复用 → 标准库 → 原生能力 → 已有依赖 → 一行 → 最小实现 |
| 前提     | 先理解需求和完整调用链，再选择最小方案                        |
| 不可省略 | 校验、数据保护、安全、无障碍、明确需求和必要测试              |
| 默认模式 | `full`                                                        |
| 审查边界 | 过度设计审查不替代正确性、安全性和性能 Review                 |

### 8.2 参考资源

- [Ponytail 官方仓库](https://github.com/DietrichGebert/ponytail)
- [Ponytail 主 Skill](https://github.com/DietrichGebert/ponytail/blob/main/skills/ponytail/SKILL.md)
- [Ponytail Agent 适配说明](https://github.com/DietrichGebert/ponytail/blob/main/docs/agent-portability.md)
- [Ponytail Agentic Benchmark 方法](https://github.com/DietrichGebert/ponytail/blob/main/benchmarks/agentic/README.md)
- [2026-06-18 Agentic Benchmark 结果](https://github.com/DietrichGebert/ponytail/blob/main/benchmarks/results/2026-06-18-agentic.md)
