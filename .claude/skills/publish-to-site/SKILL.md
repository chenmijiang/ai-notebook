---
name: publish-to-site
description: Create a publish PR from `main` to the GitHub Pages `site` branch; leave push and merge to the user.
disable-model-invocation: true
---

# 发布文档站点

创建 `base=site, head=main` 的 PR，把 `main` 晋升到发布分支 `site`。本 skill 不执行 push 或 merge；创建 PR 前须获得用户明确确认。

## 执行

1. 运行 `git fetch origin --quiet`。
2. 运行 `git rev-list --count origin/main..main`。结果大于 0 时停止，报告未推送提交数并请用户先确认 push；PR 只能包含 `origin/main` 上的提交。
3. 运行 `gh pr list --base site --head main --state open --json url --jq '.[0].url'`。有结果时输出该 URL 并停止，避免重复 PR。
4. 运行 `git diff --name-status --find-renames origin/site origin/main -- docs/`。无结果时停止，报告 `site` 已包含全部可发布文档。
5. 为每条差异生成英文条目，确保每个变更路径恰好出现一次：
   - `A`：`Added`
   - `D`：`Removed`
   - `M`、`R` 及其他状态：`Updated`；重命名写成 `<old path> → <new path>`
6. 将文件名转为标题：去掉目录、`.md` 和末尾的 `-guide`，把连字符换为空格，再将首字母大写。
7. 生成英文 PR 内容：
   - 仅有新增时，标题为 `docs: publish <N> new guide(s) to site`。
   - 其他情况，标题为 `docs: publish <N> guide update(s) to site`。
   - `N=1` 使用单数，其他数量使用复数。
   - 正文使用下方模板，省略没有条目的分组。
8. 展示标题和正文并请求确认。确认后使用 `gh pr create --base site --head main --title "<title>" --body-file <file-or-stdin>` 创建 PR。正文通过临时文件或带单引号的 heredoc 传入，避免 shell 展开 Markdown 中的反引号。
9. 输出返回的 PR URL，提醒用户在 GitHub 审阅渲染结果并手动 merge。URL 已返回且未执行 push 或 merge，任务才算完成。

## PR 正文

```markdown
Sync the latest docs from `main` into the `site` publish branch.

## Added
- <Topic> (`docs/<file>.md`)

## Updated
- <Topic> (`docs/<file>.md`)

## Removed
- <Topic> (`docs/<file>.md`)

---
_Auto-generated publish PR. Review the rendered changes on GitHub, then merge manually._
```

`gh` 未登录时停止，并请用户运行 `gh auth login`。
