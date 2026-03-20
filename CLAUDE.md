# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在处理本仓库代码时提供指导。

## 仓库概述

这是一个文档仓库（ai-notebook），包含关于软件开发主题的中文技术指南和笔记。本仓库没有应用程序代码、构建系统或测试。

## 内容结构

本仓库由独立的 Markdown 文件组成，每个文件涵盖一个特定的技术主题：

- 技术指南使用中文编写
- 每篇指南都是包含示例的综合参考文档
- 文件命名反映其内容主题
- 文件存放在**docs/** 目录下

## 写作规范

创建或编辑文档时，参考 `.claude/skills/tech-docs-guide/SKILL.md` 中的写作规范，确保一致的风格和格式。

## 注意事项

- **需求与方案设计**：使用 brainstorming skill 产出 design/spec，统一存放到本项目工作目录 `specs/`
- **实施计划编写**：在设计确认后使用 writing-plans skill 产出 implementation plan，统一存放到本项目工作目录 `plans/`
- **执行与交付记录**：部署指南、实施记录、执行补充文档继续放到本项目工作目录 `plans/`
- **执行代码改动变更**：当需要提交代码变更时，先把变更暂存，然后调用 commit skill 进行提交
