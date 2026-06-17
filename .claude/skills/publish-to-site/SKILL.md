---
name: publish-to-site
description: Use when the user wants to publish the docs site or promote the latest main into the GitHub Pages `site` branch — e.g. "发布网站", "把 main 合并到 site", "提个发布 PR". Opens a PR; the user reviews and merges on GitHub.
disable-model-invocation: true
---

把 `main` 上已发布的文档内容晋升到 GitHub Pages 的 `site` 分支。`site` 是发布分支，靠**反复把 `main` 合并进来**来更新（历史里全是 merge commit，树与 `main` 同步）。

本 skill 只负责**开 PR**（`base=site ← head=main`），并根据差异自动生成**英文**标题与正文。**不合并**——你去 GitHub 看变动后手动合并。

> **side effect 边界**：本 skill 会创建 PR（对外动作）。不自动 push、不自动 merge。涉及 push/merge 一律交还给你。

## 前置硬检查（任一不满足则停止并说明）

- [ ] **1. 同步远端**：`git fetch origin --quiet`
- [ ] **2. main 已推送**：`origin/main` 必须包含本地 `main` 的全部提交。
      检查 `git rev-list --count origin/main..main`，若 > 0 → **停止**，提示用户「本地 main 有 N 个未推送提交，PR 基于 origin/main，请先 push（需你确认）」。**不要自动 push。**
- [ ] **3. 有可发布内容**：`git rev-list --count origin/site..origin/main`，若 = 0 → **停止**，报告「site 已与 main 同步，无需发布」。
- [ ] **4. 无重复 PR**：`gh pr list --base site --head main --state open`，若已存在 → 输出其 URL 并**停止**。

## 生成标题与正文（英文）

依据 `git diff --name-status origin/site origin/main -- docs/` 区分新增 / 修改：

- `A` → Added（新指南）
- `M` → Updated（已有指南）

把文件名转成可读标题（去掉 `-guide.md`、连字符转空格、首字母大写）。

**标题**（Conventional Commits 风格，简洁）：

```
docs: publish <N> guide update(s) to site
```

若全是新增可用 `docs: publish <N> new guide(s) to site`；混合时用通用的 `update(s)`。

**正文模板**：

```markdown
Sync the latest docs from `main` into the `site` publish branch.

## Added
- <Topic A> (`docs/<file>.md`)

## Updated
- <Topic B> (`docs/<file>.md`)

---
_Auto-generated publish PR. Review the rendered changes on GitHub, then merge manually._
```

无对应分组则省略该 `##` 段。

## 开 PR

```bash
gh pr create --base site --head main \
  --title "<生成的标题>" \
  --body "<生成的正文>"
```

输出返回的 PR URL，并提醒：**去 GitHub 审阅渲染效果后手动合并；本 skill 不合并。**

## 常见问题

| 现象                          | 处理                                                        |
| ----------------------------- | ----------------------------------------------------------- |
| `gh` 报未登录                 | 让用户先 `gh auth login`（这是交互动作，由用户执行）        |
| 提示已存在 main→site 的 PR    | 直接复用，输出旧 PR URL，不重复创建                          |
| `origin/site..origin/main`=0  | site 已同步，无需发布，停止                                  |
| 本地 main 领先 origin/main    | 先 push（需用户确认），否则 PR 不含未推送的提交              |
