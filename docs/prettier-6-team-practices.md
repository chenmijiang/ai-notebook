# Prettier 团队协作实践

## 1. 概述

### 1.1 为什么需要统一风格

代码风格不统一是团队协作中的常见痛点，会带来多方面的负面影响。

**风格不统一的代价：**

| 影响领域    | 具体问题                             |
| ----------- | ------------------------------------ |
| Code Review | 评审时间被风格讨论占用，难以聚焦逻辑 |
| Git 历史    | 风格修改混入功能提交，blame 难以追溯 |
| 团队协作    | 新成员需要学习项目「潜规则」         |
| 开发体验    | 写代码时需要注意格式，增加心智负担   |
| 代码质量    | 风格混乱降低代码可读性和可维护性     |

**典型场景：**

```
开发者 A 的代码：
const user = {name: "Alice",age: 25}

开发者 B 的代码：
const user = {
  name: 'Bob',
  age: 30,
};

→ Code Review 变成风格之争...
→ 合并后同一文件风格混乱...
```

### 1.2 引入 Prettier 的收益

Prettier 通过强制统一的代码风格，带来多维度的收益。

| 收益维度   | 具体表现                               |
| ---------- | -------------------------------------- |
| 终结争论   | 没有选择就没有争论，风格由工具决定     |
| 提升效率   | Code Review 专注代码逻辑，不再纠结格式 |
| 降低门槛   | 新成员无需学习风格规范，保存即格式化   |
| 改善体验   | 随意书写代码，保存时自动美化           |
| 保证一致性 | 所有代码呈现统一的视觉风格             |

**引入前后对比：**

| 对比维度    | 引入 Prettier 前         | 引入 Prettier 后           |
| ----------- | ------------------------ | -------------------------- |
| 风格规范    | 依赖文档约定，执行靠自觉 | 工具自动强制，无需人工监督 |
| Code Review | 30% 时间讨论格式问题     | 100% 聚焦代码逻辑          |
| 新人上手    | 需要学习项目风格指南     | 配置编辑器后即可开发       |
| 代码合并    | 经常出现格式冲突         | 格式冲突几乎消失           |
| 代码一致性  | 因人而异，逐渐混乱       | 长期保持统一               |

## 2. 存量项目引入

在存量项目中引入 Prettier 需要谨慎处理，避免对团队工作流程造成冲击。

### 2.1 一次性全量格式化

一次性格式化所有代码，简单直接，适合特定场景。

**适用场景：**

| 场景           | 原因                            |
| -------------- | ------------------------------- |
| 小型项目       | 文件数量少，影响范围可控        |
| 代码审计前     | 审计前统一格式，便于后续 Review |
| 重构窗口期     | 趁重构期间一并处理格式问题      |
| 团队无活跃开发 | 没有进行中的分支，不会产生冲突  |

**执行步骤：**

```bash
# 1. 确保所有分支都已合并或同步
git checkout main
git pull

# 2. 安装 Prettier
npm install --save-dev prettier

# 3. 创建配置文件
echo '{}' > .prettierrc

# 4. 创建忽略文件（排除不需要格式化的目录）
cat > .prettierignore << 'EOF'
dist/
build/
node_modules/
*.min.js
*.bundle.js
EOF

# 5. 预览将被格式化的文件
npx prettier --check .

# 6. 执行全量格式化
npx prettier --write .

# 7. 提交格式化变更
git add .
git commit -m "style: format codebase with prettier"
```

**注意事项：**

| 注意点         | 说明                                     |
| -------------- | ---------------------------------------- |
| 选择合适时机   | 避开功能开发高峰期，减少合并冲突         |
| 通知团队成员   | 提前告知，让大家同步最新代码             |
| 处理活跃分支   | 格式化后，其他分支需要 rebase 或合并     |
| 配置 Git Hooks | 格式化后立即配置 Hooks，防止新代码不符合 |

### 2.2 渐进式引入

渐进式引入更加平滑，适合大型项目或活跃开发中的项目。

**策略一：按目录逐步引入**

```bash
# 第一阶段：格式化公共模块
npx prettier --write "src/utils/**/*"
npx prettier --write "src/components/**/*"

# 第二阶段：格式化业务模块
npx prettier --write "src/pages/**/*"
npx prettier --write "src/services/**/*"

# 第三阶段：格式化测试文件
npx prettier --write "tests/**/*"
```

**策略二：只格式化新/改动的文件**

```javascript
// lint-staged.config.js
// 只对暂存的文件运行 Prettier
export default {
  "*.{js,ts,jsx,tsx}": "prettier --write",
  "*.{json,md,css}": "prettier --write",
};
```

此策略下，存量代码保持原样，只有被修改的文件才会被格式化，逐步实现全量覆盖。

**策略三：先检查，后逐步修复**

```bash
# 1. 先以检查模式运行，统计问题规模
npx prettier --check . 2>&1 | wc -l

# 2. 输出不符合规范的文件列表
npx prettier --list-different .

# 3. 按优先级逐批修复
npx prettier --write "src/core/**/*"    # 高优先级
npx prettier --write "src/legacy/**/*"  # 低优先级
```

**渐进式引入时间表示例：**

| 阶段   | 时间    | 范围              | 检查点                 |
| ------ | ------- | ----------------- | ---------------------- |
| 阶段 1 | 第 1 周 | 公共模块 + 新代码 | Git Hooks 对新代码生效 |
| 阶段 2 | 第 2 周 | 业务模块核心目录  | 无回归问题             |
| 阶段 3 | 第 3 周 | 业务模块其余目录  | 无回归问题             |
| 阶段 4 | 第 4 周 | 测试文件 + 文档   | 全量检查通过           |
| 阶段 5 | 第 5 周 | CI 开启格式检查   | PR 强制要求格式正确    |

### 2.3 处理格式化炸弹提交

「格式化炸弹」指一次性格式化大量代码产生的巨型提交，会对 Git 历史造成冲击。

**格式化炸弹的影响：**

| 影响      | 说明                              |
| --------- | --------------------------------- |
| Git blame | 所有被格式化的行都指向这个提交    |
| PR Review | 难以 Review 包含大量变更的 PR     |
| 冲突风险  | 活跃分支合并时产生大量冲突        |
| 历史追溯  | 难以通过 blame 找到代码的真实作者 |

**最佳实践：格式化提交独立管理**

```bash
# 1. 创建独立的格式化分支
git checkout -b chore/prettier-format

# 2. 只做格式化，不混入其他变更
npx prettier --write .

# 3. 使用标准化的提交信息
git add .
git commit -m "style: format entire codebase with prettier

This is a formatting-only commit with no logic changes.
Safe to ignore in git blame using .git-blame-ignore-revs"

# 4. 记录提交哈希，稍后添加到 .git-blame-ignore-revs
git rev-parse HEAD
```

**提交信息规范：**

| 类型       | 格式                                          |
| ---------- | --------------------------------------------- |
| 全量格式化 | `style: format entire codebase with prettier` |
| 目录格式化 | `style: format src/utils with prettier`       |
| 配置变更   | `chore: update prettier configuration`        |

### 2.4 保持 git blame 可读性

Git 提供 `.git-blame-ignore-revs` 文件来忽略特定提交，保持 blame 可读性。

**创建 .git-blame-ignore-revs：**

```bash
# .git-blame-ignore-revs
# Prettier 全量格式化
# 该提交只包含格式调整，不影响代码逻辑
a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0

# 2024-06 第二次格式化（升级 Prettier v3）
b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1
```

**配置 Git 使用此文件：**

```bash
# 方式一：全局配置（推荐）
git config blame.ignoreRevsFile .git-blame-ignore-revs

# 方式二：仓库级配置
git config --local blame.ignoreRevsFile .git-blame-ignore-revs

# 方式三：命令行参数
git blame --ignore-revs-file .git-blame-ignore-revs src/index.js
```

**团队配置自动化：**

```json
// package.json
{
  "scripts": {
    "postinstall": "git config blame.ignoreRevsFile .git-blame-ignore-revs"
  }
}
```

**GitHub 自动识别：**

GitHub 会自动识别仓库根目录的 `.git-blame-ignore-revs` 文件，在网页 blame 视图中忽略这些提交。

**验证配置是否生效：**

```bash
# 不使用 ignore-revs（格式化提交显示为作者）
git blame src/index.js

# 使用 ignore-revs（跳过格式化提交，显示真实作者）
git blame --ignore-revs-file .git-blame-ignore-revs src/index.js
```

**示例输出对比：**

```
# 未配置 ignore-revs
a1b2c3d4 (Bot       2024-01-15) const foo = {
a1b2c3d4 (Bot       2024-01-15)   bar: 1,
a1b2c3d4 (Bot       2024-01-15) };

# 配置 ignore-revs 后
e5f6g7h8 (Alice     2023-06-20) const foo = {
e5f6g7h8 (Alice     2023-06-20)   bar: 1,
e5f6g7h8 (Alice     2023-06-20) };
```

## 3. 配置决策

### 3.1 值得讨论的选项

Prettier 虽然号称「固执己见」，但仍提供少量配置选项。以下选项值得团队讨论后决定。

| 选项          | 可选值             | 建议                           |
| ------------- | ------------------ | ------------------------------ |
| printWidth    | 80-120             | 讨论后统一，常见值：80/100/120 |
| tabWidth      | 2/4                | 与项目历史保持一致             |
| semi          | true/false         | 有社区分歧，需团队决定         |
| singleQuote   | true/false         | 有社区分歧，需团队决定         |
| trailingComma | "none"/"es5"/"all" | 推荐 "es5" 或 "all"            |

**printWidth 选择参考：**

| 值  | 适用场景           | 优缺点                       |
| --- | ------------------ | ---------------------------- |
| 80  | 传统标准，终端友好 | 易于阅读，但现代屏幕略显浪费 |
| 100 | 平衡选择           | 兼顾可读性和空间利用         |
| 120 | 宽屏幕环境         | 利用屏幕空间，但长行不易阅读 |

**semi（分号）选择参考：**

| 值    | 代表社区        | 优缺点                    |
| ----- | --------------- | ------------------------- |
| true  | 传统 JavaScript | 明确、安全，避免 ASI 陷阱 |
| false | 现代 JavaScript | 简洁，但需要了解 ASI 规则 |

**singleQuote（引号）选择参考：**

| 值    | 代表社区      | 优缺点                           |
| ----- | ------------- | -------------------------------- |
| true  | Airbnb 风格   | 输入更方便，JSON 需要双引号      |
| false | Prettier 默认 | 与 JSON 一致，字符串含撇号更方便 |

### 3.2 直接采用默认值的选项

以下选项建议直接使用 Prettier 默认值，无需讨论。

| 选项            | 默认值      | 建议原因                    |
| --------------- | ----------- | --------------------------- |
| useTabs         | false       | 空格兼容性更好              |
| bracketSpacing  | true        | `{ foo }` 比 `{foo}` 更清晰 |
| bracketSameLine | false       | 闭合括号独占一行，便于 diff |
| arrowParens     | "always"    | 始终加括号，便于添加参数    |
| endOfLine       | "lf"        | 跨平台一致性                |
| quoteProps      | "as-needed" | 按需添加引号，简洁          |
| jsxSingleQuote  | false       | JSX 通常使用双引号          |
| proseWrap       | "preserve"  | 保留 Markdown 原始换行      |

**为什么不争论这些选项：**

```
团队讨论消耗的时间 >> 选项带来的差异价值

选择 useTabs: true 还是 false？
→ 无论选哪个，代码都能正常运行
→ 无论选哪个，最终都会习惯
→ 花 1 小时讨论，不如 1 分钟采用默认值
```

### 3.3 减少争议的策略

**策略一：设置决策期限**

```
周一：发起配置投票
周三：截止投票，公布结果
周四：应用配置，不再讨论
```

**策略二：采用「默认值 + 最小覆盖」原则**

```json
// .prettierrc
// 只覆盖确实需要调整的选项，其余使用默认值
{
  "printWidth": 100,
  "singleQuote": true
}
```

**策略三：参考知名项目配置**

| 项目/公司 | 配置特点                                |
| --------- | --------------------------------------- |
| React     | 默认配置，semi: true                    |
| Vue       | singleQuote: true                       |
| Airbnb    | singleQuote: true, trailingComma: "all" |
| Google    | singleQuote: true, printWidth: 80       |

**策略四：一旦决定，长期稳定**

```
配置锁定原则：
1. 配置确定后，至少 6 个月不修改
2. 修改需要 Tech Lead 批准
3. 修改必须附带充分理由
```

## 4. 特殊情况处理

### 4.1 prettier-ignore 使用规范

`prettier-ignore` 用于跳过特定代码的格式化，但应谨慎使用。

**基本语法：**

```javascript
// prettier-ignore - 跳过下一条语句
const matrix = [
  [1, 0, 0],
  [0, 1, 0],
  [0, 0, 1],
];

// prettier-ignore-start 和 prettier-ignore-end - 跳过代码块
// prettier-ignore-start
const complexQuery = db
  .select()
  .from(users)
  .where(active, eq, true)
  .orderBy(createdAt, "desc");
// prettier-ignore-end
```

**不同文件类型的语法：**

| 文件类型   | 语法                             |
| ---------- | -------------------------------- |
| JavaScript | `// prettier-ignore`             |
| TypeScript | `// prettier-ignore`             |
| CSS        | `/* prettier-ignore */`          |
| HTML       | `<!-- prettier-ignore -->`       |
| Markdown   | `<!-- prettier-ignore -->`       |
| YAML       | `# prettier-ignore`              |
| JSON       | 不支持注释，使用 .prettierignore |

**合理使用场景：**

| 场景          | 示例                 | 原因                     |
| ------------- | -------------------- | ------------------------ |
| 矩阵/表格数据 | 二维数组对齐         | 保持视觉对齐，提高可读性 |
| ASCII 艺术    | 代码中的 ASCII 图表  | 保持原始布局             |
| 特殊格式 SQL  | 复杂查询的特定缩进   | 保持查询结构清晰         |
| 测试数据对齐  | 测试用例输入输出对齐 | 便于阅读测试数据         |
| 正则表达式    | 复杂正则的特殊格式   | 保持正则可读性           |

**应该避免的场景：**

| 场景             | 原因                           | 替代方案             |
| ---------------- | ------------------------------ | -------------------- |
| 不喜欢格式化结果 | 个人偏好不是使用 ignore 的理由 | 接受 Prettier 的决定 |
| 让代码更「紧凑」 | 紧凑不等于可读                 | 信任 Prettier 的换行 |
| 习惯原来的风格   | 习惯可以改变                   | 适应新风格           |

**团队规范建议：**

```javascript
// ❌ 不推荐：无理由的 ignore
// prettier-ignore
const x = 1+2+3;

// ✅ 推荐：附带明确理由
// prettier-ignore - 保持矩阵对齐，便于阅读
const transform = [
  [1, 0, 0, tx],
  [0, 1, 0, ty],
  [0, 0, 1, tz],
  [0, 0, 0, 1],
];
```

### 4.2 生成代码排除

自动生成的代码不应被 Prettier 格式化，以避免覆盖或冲突。

**常见生成代码类型：**

| 类型              | 文件示例                | 排除原因               |
| ----------------- | ----------------------- | ---------------------- |
| GraphQL 生成代码  | `*.generated.ts`        | 重新生成时会被覆盖     |
| OpenAPI 生成代码  | `src/api/generated/*`   | 修改无意义             |
| Protobuf 生成代码 | `*_pb.js`, `*_pb.d.ts`  | 机器生成，不应手动修改 |
| 构建产物          | `dist/`, `build/`       | 构建时重新生成         |
| 压缩文件          | `*.min.js`, `*.min.css` | 已优化，不需要格式化   |

**.prettierignore 配置示例：**

```
# 构建产物
dist/
build/
out/

# 生成代码 - GraphQL
src/**/*.generated.ts
src/graphql/types.ts

# 生成代码 - OpenAPI/Swagger
src/api/generated/

# 生成代码 - Protobuf
**/*_pb.js
**/*_pb.d.ts

# 压缩文件
*.min.js
*.min.css
*.bundle.js

# 依赖目录
node_modules/

# 包管理器锁文件
package-lock.json
pnpm-lock.yaml
yarn.lock
```

**验证排除是否生效：**

```bash
# 查看哪些文件会被格式化
npx prettier --list-different .

# 查看特定文件是否被忽略
npx prettier --check "src/api/generated/client.ts"
# 如果被忽略，不会有输出
```

### 4.3 第三方代码处理

项目中可能包含第三方代码或 vendor 代码，需要特殊处理。

**常见第三方代码类型：**

| 类型           | 示例                            | 处理策略         |
| -------------- | ------------------------------- | ---------------- |
| vendor 目录    | `src/vendor/`, `lib/`           | 完全排除         |
| 复制的代码片段 | 从 StackOverflow 复制的工具函数 | 考虑是否保持原样 |
| Fork 的库      | 本地修改的第三方库              | 根据维护策略决定 |
| 嵌入的 SDK     | 第三方 SDK 源码                 | 排除，保持原样   |

**.prettierignore 配置：**

```
# 第三方代码
vendor/
lib/third-party/

# 嵌入的 SDK
src/sdk/

# 特定第三方文件
src/utils/lodash-custom.js
```

**决策流程：**

```
第三方代码是否格式化？

1. 是否会合并上游更新？
   ├── 是 → 不格式化（避免合并冲突）
   └── 否 → 继续判断

2. 代码是否有明确的维护者？
   ├── 是（上游项目）→ 不格式化
   └── 否（已废弃）→ 继续判断

3. 团队是否需要修改此代码？
   ├── 经常修改 → 格式化（提高可维护性）
   └── 几乎不改 → 不格式化（保持原样）
```

### 4.4 遗留系统共存

在遗留系统中，可能需要让格式化和未格式化的代码共存一段时间。

**共存策略：**

| 策略       | 适用场景                      | 实施方式                   |
| ---------- | ----------------------------- | -------------------------- |
| 目录隔离   | 新旧代码在不同目录            | .prettierignore 排除旧目录 |
| 渐进格式化 | 修改时顺便格式化              | lint-staged 只处理暂存文件 |
| 双轨并行   | 新项目用 Prettier，旧项目不用 | 独立配置                   |
| 定期清理   | 设定目标日期完成全量格式化    | 制定迁移计划               |

**目录隔离配置示例：**

```
# .prettierignore
# 遗留代码目录，待后续处理
src/legacy/
src/deprecated/
src/old-modules/
```

**渐进格式化配置：**

```json
// package.json
{
  "lint-staged": {
    "src/new/**/*.{js,ts}": "prettier --write",
    "src/legacy/**/*.{js,ts}": []
  }
}
```

**共存期间的注意事项：**

| 注意点       | 说明                               |
| ------------ | ---------------------------------- |
| 明确边界     | 清楚标记哪些目录已格式化           |
| 避免交叉编辑 | 尽量不在同一 PR 中修改新旧代码     |
| 设定终止日期 | 共存是过渡状态，不应长期维持       |
| 记录技术债   | 将「完成全量格式化」列入技术债清单 |

**迁移进度跟踪：**

```bash
# 统计已格式化文件数量
npx prettier --check "src/new/**/*" 2>&1 | grep -c "Checking"

# 统计待格式化文件数量
npx prettier --check "src/legacy/**/*" 2>&1 | grep -c "\[warn\]"
```

## 5. 版本管理

### 5.1 锁定版本的重要性

Prettier 的不同版本可能产生不同的格式化结果，因此锁定版本至关重要。

**版本不一致的问题：**

| 问题             | 场景                       | 后果                     |
| ---------------- | -------------------------- | ------------------------ |
| 本地与 CI 不一致 | 开发者用 v3.0，CI 用 v2.8  | CI 检查失败              |
| 团队成员不一致   | A 用 v3.1，B 用 v3.0       | 互相「格式化」对方的代码 |
| 升级后全量变更   | 升级版本后大量文件格式变化 | Git 历史被污染           |

**正确的锁定方式：**

```json
// package.json
{
  "devDependencies": {
    "prettier": "3.2.5"
  }
}
```

| 版本格式 | 示例       | 是否推荐 | 原因                     |
| -------- | ---------- | -------- | ------------------------ |
| 精确版本 | `"3.2.5"`  | 推荐     | 完全一致，无歧义         |
| 波浪号 ~ | `"~3.2.0"` | 不推荐   | 允许补丁更新，可能有差异 |
| 脱字符 ^ | `"^3.2.0"` | 不推荐   | 允许次版本更新，风险更大 |
| 星号 \*  | `"*"`      | 禁止     | 任意版本，完全不可控     |

**使用 lock 文件：**

```bash
# 确保使用 lock 文件安装
npm ci                    # 而不是 npm install

# 或使用其他包管理器
pnpm install --frozen-lockfile
yarn install --frozen-lockfile
```

### 5.2 升级流程

升级 Prettier 版本需要规范的流程，避免对团队造成冲击。

**升级前准备：**

| 步骤 | 操作           | 目的                 |
| ---- | -------------- | -------------------- |
| 1    | 阅读 Changelog | 了解新版本的变化     |
| 2    | 本地测试       | 评估格式化差异的范围 |
| 3    | 选择时机       | 避开功能开发高峰期   |
| 4    | 通知团队       | 让大家有心理准备     |

**标准升级流程：**

```bash
# 1. 创建升级分支
git checkout -b chore/upgrade-prettier-v3.3

# 2. 更新依赖
npm install prettier@3.3.0 --save-dev --save-exact

# 3. 查看哪些文件会被重新格式化
npx prettier --list-different .

# 4. 执行格式化
npx prettier --write .

# 5. 提交变更
git add .
git commit -m "chore: upgrade prettier to v3.3.0

BREAKING: This version changes formatting for:
- Array expressions in certain cases
- Object property alignment

All files have been reformatted."

# 6. 更新 .git-blame-ignore-revs
echo "" >> .git-blame-ignore-revs
echo "# Prettier v3.3.0 upgrade" >> .git-blame-ignore-revs
git rev-parse HEAD >> .git-blame-ignore-revs
git add .git-blame-ignore-revs
git commit -m "chore: add prettier upgrade commit to blame ignore"

# 7. 创建 PR，通知团队 Review
```

**升级后验证：**

| 验证项         | 命令/操作                | 预期结果            |
| -------------- | ------------------------ | ------------------- |
| 格式检查通过   | `npx prettier --check .` | 无输出，退出码为 0  |
| CI 流水线通过  | 观察 PR 的 CI 状态       | 所有检查通过        |
| 编辑器正常工作 | 在 VS Code 中保存文件    | 格式化结果一致      |
| Git Hooks 正常 | 创建测试提交             | pre-commit 正常执行 |

### 5.3 版本差异处理

当团队成员使用不同版本时，需要及时处理差异。

**发现版本差异的迹象：**

| 迹象                  | 可能原因                       |
| --------------------- | ------------------------------ |
| CI 检查失败，本地通过 | CI 和本地版本不一致            |
| PR 中出现格式化变更   | 团队成员版本不一致             |
| 同一文件反复被格式化  | 不同版本的格式化结果不同       |
| 编辑器保存后立即变化  | 编辑器插件版本与项目版本不一致 |

**诊断命令：**

```bash
# 查看项目依赖的版本
npm list prettier

# 查看全局安装的版本（如果有）
npm list -g prettier

# 查看编辑器使用的版本
# VS Code: 打开命令面板，搜索 "Prettier: Show Output"
```

**解决方案：**

| 问题场景         | 解决方案                            |
| ---------------- | ----------------------------------- |
| 本地版本过旧     | `npm ci` 重新安装依赖               |
| 全局版本干扰     | 卸载全局 Prettier，使用项目本地版本 |
| 编辑器版本不一致 | 配置编辑器使用项目本地 Prettier     |
| lock 文件未提交  | 提交 package-lock.json              |

**VS Code 配置使用项目本地 Prettier：**

```json
// .vscode/settings.json
{
  "prettier.prettierPath": "./node_modules/prettier"
}
```

**确保版本一致的检查脚本：**

```bash
#!/bin/bash
# scripts/check-prettier-version.sh

EXPECTED_VERSION="3.2.5"
ACTUAL_VERSION=$(npx prettier --version)

if [ "$EXPECTED_VERSION" != "$ACTUAL_VERSION" ]; then
  echo "Error: Prettier version mismatch"
  echo "Expected: $EXPECTED_VERSION"
  echo "Actual: $ACTUAL_VERSION"
  echo "Please run: npm ci"
  exit 1
fi
```

## 6. 总结

**存量项目引入策略：**

| 策略       | 适用场景             | 关键点                        |
| ---------- | -------------------- | ----------------------------- |
| 一次性全量 | 小型项目、无活跃分支 | 选择合适时机，通知团队        |
| 渐进式引入 | 大型项目、活跃开发中 | 按目录逐步推进，设定时间表    |
| 格式化炸弹 | 任何项目             | 独立提交，记录到 blame ignore |

**配置决策原则：**

| 原则     | 说明                         |
| -------- | ---------------------------- |
| 最小配置 | 只覆盖必要选项，其余用默认值 |
| 快速决策 | 设定期限，避免无休止讨论     |
| 长期稳定 | 配置确定后至少 6 个月不变    |
| 参考先例 | 借鉴知名项目的配置           |

**特殊情况处理：**

| 场景            | 推荐做法                  |
| --------------- | ------------------------- |
| prettier-ignore | 谨慎使用，附带明确理由    |
| 生成代码        | 在 .prettierignore 中排除 |
| 第三方代码      | 根据是否需要合并上游决定  |
| 遗留系统        | 目录隔离 + 渐进迁移       |

**版本管理要点：**

| 要点     | 实践                                    |
| -------- | --------------------------------------- |
| 锁定版本 | 使用精确版本号，提交 lock 文件          |
| 规范升级 | 独立分支、全量格式化、更新 blame ignore |
| 保持一致 | CI、本地、编辑器使用相同版本            |

## 参考资源

- [Prettier 官方文档](https://prettier.io/docs/)
- [Option Philosophy](https://prettier.io/docs/en/option-philosophy)
- [Ignoring Code](https://prettier.io/docs/en/ignore)
- [Git blame ignore revs](https://git-scm.com/docs/git-blame#Documentation/git-blame.txt---ignore-revs-fileltfilegt)
- [GitHub - Ignoring commits in blame view](https://docs.github.com/en/repositories/working-with-files/using-files/viewing-a-file#ignore-commits-in-the-blame-view)
- [Prettier 基础概念与原理](./prettier-1-fundamentals.md)
- [Prettier 配置完全指南](./prettier-2-configuration.md)
- [Prettier 工具链整合指南](./prettier-5-toolchain.md)
