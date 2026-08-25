# Umi Mock 如何从文件声明变成 HTTP 响应

Umi Mock 不会在浏览器中替换 `fetch`，也不会生成前端 Mock 代码。它在 Node Server 中读取 Mock 文件、构建路由表，再注册 Express middleware。因此，排查 Mock 应沿着服务端处理链路进行：先确认声明是否进入路由表，再检查方法和路径是否匹配，最后确认 handler 是否结束响应。

本文以 [Umi 4.7.6 源码](https://github.com/umijs/umi/tree/967d2097a3023653931c70c2e550068ee11fbfe3) 为依据，说明 `umi dev` 和 `umi preview` 如何加载、匹配和更新 Mock。Mock.js、Umi 3 以及生产环境中的 Mock 不在讨论范围内。

## Mock 在请求链路中的位置

`umi dev` 启动时，Mock 插件读取 Mock 文件，并通过 `addBeforeMiddlewares` 注册 middleware。请求到达开发服务器后，Mock middleware 查找匹配的路由：命中后返回静态响应或执行函数 handler，未命中则调用 `next()`，把请求交给后续 middleware。

```text
Mock 文件
  │
  ▼
getMockData() ──► 路由表
  │
  ▼
createMockMiddleware()
  │
  ▼
HTTP 请求 ──► 方法、路径命中？
                 ├─ 是：执行 handler 或返回 JSON
                 └─ 否：next()
```

Mock middleware 挂载后，请求能否命中只取决于路由表、请求方法和路径，与页面模块是否已在浏览器中加载无关。而 Mock 与 proxy、构建工具 middleware 的先后关系则取决于 `dev` 或 `preview` 的注册顺序，后文会分别说明。

## 文件声明如何进入路由表

### 扫描文件

加载器始终扫描 `mock/**/*.[jt]s`，然后追加 `mock.include` 中的模式，扫描结果再排除 `.d.ts` 和 `mock.exclude` 匹配的文件。

```ts
// .umirc.ts
export default {
  mock: {
    include: ['src/pages/**/_mock.ts'],
    exclude: ['mock/legacy/**'],
  },
};
```

这段配置会额外加载页面旁的 `_mock.ts`，include 只扩大扫描范围，不替换默认目录。当文件没有生效时，先确认 glob 能否以项目根目录为基准匹配目标文件，再检查文件是否被 `exclude` 排除。

### 解析默认导出

Mock 文件默认导出一个对象。对象的 key 定义 HTTP 方法和路径，value 定义静态响应或函数 handler：

```ts
import { defineMock } from 'umi';

export default defineMock({
  '/api/users': [{ id: 1, name: 'Ada' }],
  'POST /api/users': (req, res) => {
    res.status(201).json({ id: 2, name: req.body.name });
  },
});
```

省略方法时，Umi 使用 `GET`。显式方法会转成大写，只接受 `GET`、`POST`、`PUT`、`DELETE`、`PATCH`、`HEAD` 和 `OPTIONS`。方法不受支持或路径缺失时，加载阶段就会报错。

value 在运行时只能是函数、数组或普通对象。`defineMock` 只原样返回参数并提供类型提示；它不注册路由，也不改变加载器的运行时校验。

路由表以 `method + path` 作为 ID。遇到重复 ID 时，Umi 会打印 warning，并用后加载的声明覆盖已有声明。由于 glob 的文件顺序不应决定业务行为，每个 `method + path` 应只声明一次。

### 加载文件并清理缓存

Umi 使用 esbuild 临时注册 TypeScript 加载器。加载每个 Mock 文件前，它会删除该文件的 `require.cache`。路由表构建成功后，Umi 还会清理本轮记录的依赖缓存，并恢复注册器。因此，下次重建路由表时，相关模块会重新执行，不会沿用 Node Cache。

## 路由如何匹配并生成响应

middleware 逐条检查路由表：先比较 `req.method`，再用 `path-to-regexp` 匹配 `req.path`。Search String Params 不参与路径匹配。所有路由都未命中时，middleware 才调用 `next()`。

```ts
export default {
  'GET /api/users/:id': (req, res) => {
    res.json({
      id: req.params.id,
      keyword: req.query.keyword,
    });
  },
};
```

请求 `/api/users/42?keyword=admin` 时，`req.params.id` 是 `42`，`req.query.keyword` 是 `admin`。调用函数 handler 前，middleware 会解码路径参数；解码失败时，它会抛出状态为 `400` 的 `URIError`。静态对象和数组不需要构造 `req.params`，因此不会执行参数解码。

### 静态值返回固定响应

数组或普通对象命中后，middleware 固定执行 `res.status(200).json(handler)`：

```ts
export default {
  'GET /api/features': {
    flags: ['search', 'export'],
  },
};
```

静态值适合固定 JSON，但不能根据请求改变数据、状态码或响应头。需要这些能力时，应使用函数 handler。

### 函数 handler 控制并结束响应

函数 handler 可以读取请求并控制响应：

```ts
export default {
  'POST /api/users': (req, res) => {
    if (!req.body.name) {
      return res.status(400).json({ message: 'name is required' });
    }

    res.status(201).json({ id: 1, name: req.body.name });
  },
};
```

对于非 `GET` 请求，middleware 依次运行 JSON、URL-encoded 和 multipart parser，再调用 handler。JSON 和 URL-encoded body 的大小限制为 5 MB。`GET` handler 不经过这些 parser，查询条件应放在路径参数或查询参数中，不依赖 `req.body`。

函数 handler 必须调用 `res.json()`、`res.end()` 等方法结束响应，或调用 `next()` 转交请求，否则请求会一直等待。

## `dev` 和 `preview` 的 Mock 生命周期

两条命令的行为对比如下：

| 行为       | `umi dev`                                     | `umi preview`        |
| ---------- | --------------------------------------------- | -------------------- |
| 路由更新   | 监听 `mock` 和 `include` 路径，成功时整体替换 | 不监听，修改后需重启 |
| proxy 顺序 | Mock 在 proxy 前                              | proxy 在 Mock 前     |
| 配置门控   | Mock 插件的 `enableBy()` 参与判断             | 直接调用加载器       |

### `umi dev`：监听文件并替换路由表

Mock 插件默认只在 `dev` 命令中启用。`MOCK=none` 或 `mock: false` 都会禁用该插件。

插件会监听项目的 `mock` 路径和 `include` 指定的路径。文件发生变化后，它重新扫描并加载全部 Mock，再用新路由表替换共享 `context` 中的旧表。middleware 每次请求都从这个 `context` 读取路由，因此服务器无需重启，也无需重新挂载 middleware。

```text
mock 或 include 路径发生文件事件
  └─ getMockData() 重建整张路由表
      └─ context.mockData 替换成功
          └─ 下一次请求读取新表
```

如果 Mock 文件导入了观察路径之外的本地模块，这些模块变化时不一定会触发重建。值得注意的是，`exclude` 只在扫描阶段排除文件，不会缩小 `dev` watcher 的观察范围。重载失败时，`updateMockData()` 会在写入新表前捕获错误，已经成功加载的旧路由表仍然有效。此时应先修复终端最早报告的加载错误。因此，同一个请求同时匹配 Mock 和 proxy 时，Mock 会先处理。Mock 未命中或函数 handler 调用 `next()` 后，请求才会继续传递。在 Webpack dev 中，如果后续 `GET` 或 `HEAD` 请求匹配到 Webpack 输出资源，webpack-dev-middleware 会在 proxy 之前直接响应。

### `umi preview`：启动时只加载一次

`umi preview` 不经过 Mock 插件的生命周期。它在启动时直接加载一次路由表，不监听文件变化；修改 Mock 后必须重启 `preview`。`preview` 将 proxy 注册在 Mock 之前；匹配并被 proxy 消费的请求不会到达 Mock。当前版本的 `preview` 直接以 `api.config.mock || {}` 调用加载器，`MOCK=none` 不影响这条路径，这属于内部实现。

## 按阶段排查 Mock

Mock 没有按预期响应时，按服务端处理顺序定位：

1. **确认命令和插件状态。** 区分 `umi dev` 与 `umi preview`。使用 `dev` 时，检查 `mock: false` 与 `MOCK=none`。
2. **确认文件进入路由表。** 核对默认 glob、`include` 和 `exclude`，并先修复终端最早报告的加载错误。语法、导入、方法和 handler 类型错误都发生在请求匹配之前。
3. **确认路由是否匹配。** 省略方法只代表 `GET`；Umi 匹配不含查询字符串的 `req.path`；同一个 `method + path` 不应重复声明。
4. **确认函数 handler 结束响应或转交请求。** 调用响应方法结束响应，或调用 `next()` 转交请求。
5. **检查后续 middleware。** 只有请求被转交后，才需要根据 `dev` 或 `preview` 的注册顺序检查 proxy、构建工具和路由回退。

这套顺序先把问题归入三个阶段：文件没有进入路由表、路由没有匹配请求，或 handler 命中后没有结束响应。确定失败阶段后，再修改对应的 Mock 声明。
