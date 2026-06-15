# Zod 使用指南

Zod 是面向 TypeScript 的运行时类型校验库。它让你用一份「声明」同时得到**运行时校验**和**编译期类型**,把来自程序边界之外的不可信数据(接口返回、用户输入、环境变量等)挡在业务逻辑之外。

本文以 **Zod v4**(2025 年转正)为基准编写,核心 API 与 v3 基本一致,差异处会用 `> 注意` 标注。目标是让没接触过 Zod 的开发者快速建立心智模型,并能在真实项目中落地。

## 1. 概述

### 1.1 为什么需要 Zod

TypeScript 的类型在编译后会被**完全擦除**,运行时并不存在。因此凡是数据来自「程序边界之外」,TS 的 `interface` 给你的只是一句没人兑现的承诺:

```typescript
// ❌ 危险:as 只是断言,运行时没有任何校验
const data = (await res.json()) as User;
// 后端少传字段、类型变了,这里不会报错,
// 而是在三层之后某个 data.email.toLowerCase() 才炸,定位成本极高
```

Zod 的定位是:**在运行时把不可信数据「卡」一道**,校验通过才放行;并能**反向从校验规则推导出 TS 类型**,让运行时与编译期共用同一份事实来源。

| 关注点           | TypeScript         | Zod                          |
| ---------------- | ------------------ | ---------------------------- |
| 生效时机         | 编译期(运行时擦除) | 运行时                       |
| 能否校验真实数据 | 否                 | 是                           |
| 类型来源         | 手写 `interface`   | 从 schema 推导               |
| 适用位置         | 全代码             | **程序边界**(接口/输入/配置) |

一句话:**TS 管编译期,Zod 管运行时边界;二者互补,不是替代。**

### 1.2 安装

```bash
npm install zod
```

```typescript
// v4 推荐导入方式
import { z } from "zod";
```

> 注意:Zod 需要在 `tsconfig.json` 中开启 `"strict": true`(或至少 `"strictNullChecks": true`),否则类型推导(尤其是 `optional`、`nullable`)会不准确。

## 2. 核心心智模型

Zod 的全部精髓只有三步:**定义 schema → 解析数据 → 推导类型**。理解这三步,剩下都是 API 细节。

```typescript
import { z } from "zod";

// 第 1 步:定义 schema(运行时的「类型」)
const UserSchema = z.object({
  id: z.number(),
  name: z.string(),
  email: z.email(), // v4 写法;v3 为 z.string().email()
  age: z.number().int().positive().optional(), // 可选字段
});

// 第 2 步:解析,把 unknown 变成可信数据
const user = UserSchema.parse(someUnknownData);
//    ^ 校验失败会抛 ZodError;成功则返回类型已收窄的数据

// 第 3 步:推导,从 schema 反推 TS 类型,不必再手写 interface
type User = z.infer<typeof UserSchema>;
// { id: number; name: string; email: string; age?: number }
```

核心理念:**schema 是「带运行时校验能力的类型」,是唯一事实来源(single source of truth)**。你不再维护「interface + 校验逻辑」两份会逐渐漂移的真相,只写一份 schema,类型用 `z.infer` 抽出来。

> 注意:`.parse()` 返回的是输入数据的**深拷贝**,不会修改原对象。

## 3. parse 与 safeParse

这是新手最先遇到的分叉:校验失败时,要让它**抛异常**还是**返回结果对象**?

| 方法               | 校验失败时          | 返回值                                      | 适用场景                  |
| ------------------ | ------------------- | ------------------------------------------- | ------------------------- |
| `.parse(data)`     | **抛出** `ZodError` | 直接返回收窄后的数据                        | 失败即 bug,想让错误冒泡   |
| `.safeParse(data)` | **不抛**,正常返回   | `{ success, data }` 或 `{ success, error }` | 预期会失败,需自己处理分支 |

```typescript
// parse:适合「失败就该崩」的场景,配合 try-catch
try {
  const user = UserSchema.parse(input);
} catch (e) {
  if (e instanceof z.ZodError) {
    console.log(e.issues); // 结构化错误数组
  }
}

// safeParse:适合接口、表单这类「预期会失败」的场景
const result = UserSchema.safeParse(input);
if (!result.success) {
  console.log(result.error.issues); // 处理错误分支
  return;
}
result.data.name; // ✅ 这里 result.data 已被收窄为 User
```

> 提示:含异步校验(如 `.refine` 里有异步逻辑)时,用 `.parseAsync()` / `.safeParseAsync()`,否则会抛错。

`error.issues` 是一个数组,每条 issue 的结构如下,是做友好错误提示的基础:

```jsonc
{
  "code": "invalid_type", // 错误类型码
  "path": ["age"], // 出错字段路径(嵌套时是数组)
  "message": "Expected number, received string" // 错误信息
}
```

## 4. 常用 API 速览

下面是高频 API,目标是「有印象、能查」,不必背诵。

### 4.1 基础类型

```typescript
z.string();
z.number();
z.boolean();
z.date();
z.bigint();
z.null();
z.undefined();
z.any(); // 任意值(慎用,绕过校验)
z.unknown(); // 未知值(比 any 安全)
```

### 4.2 字符串与数字约束

```typescript
// 字符串:链式约束
z.string().min(1).max(20).trim();
z.string().startsWith("https://");
z.string().regex(/^\d+$/);

// v4:字符串格式校验提为顶级函数(更利于 tree-shaking)
z.email();
z.url();
z.uuid();

// 数字
z.number().int().positive(); // 正整数
z.number().min(0).max(100);
z.number().multipleOf(5);
```

> 注意:v4 中 `z.string().email()` / `.url()` / `.uuid()` 已**废弃**,改用顶级 `z.email()` / `z.url()` / `z.uuid()`。v3 仍用链式写法。

### 4.3 复合类型

```typescript
// 对象
z.object({ id: z.number(), name: z.string() });

// 数组
z.array(z.string()); // string[]
z.string().array(); // 等价写法

// 元组(定长、各位类型不同)
z.tuple([z.string(), z.number()]); // [string, number]

// 枚举(字面量联合)
z.enum(["draft", "published", "archived"]);

// 单个字面量
z.literal("on");

// 联合
z.union([z.string(), z.number()]); // string | number
z.string().or(z.number()); // 等价写法

// 记录(键值对象)
z.record(z.string(), z.number()); // Record<string, number>
```

> 注意:v4 中 `z.record()` **必须传两个参数**(键 schema + 值 schema);v3 允许单参数 `z.record(z.number())`。原 `z.nativeEnum()` 在 v4 废弃,改用重载的 `z.enum()`。

### 4.4 修饰符

```typescript
z.string().optional(); // string | undefined,字段可省略
z.string().nullable(); // string | null,允许 null
z.string().nullish(); // string | null | undefined
z.string().default("hi"); // 缺省时补默认值
z.number().catch(0); // 校验失败时兜底为 0(而非报错)
```

`optional` / `nullable` / `default` 三者语义不同,是高频混淆点,详见第 7 章避坑清单。

### 4.5 对象操作

对象 schema 之间可以像积木一样组合复用:

```typescript
const Base = z.object({ id: z.number(), name: z.string(), email: z.email() });

Base.partial(); // 所有字段变 optional
Base.required(); // 所有字段变必填
Base.pick({ id: true, name: true }); // 只取 id、name
Base.omit({ email: true }); // 去掉 email
Base.extend({ age: z.number() }); // 追加字段
Base.merge(z.object({ age: z.number() })); // 合并另一个 schema

// 控制未知字段(默认会被剥离)
Base.strict(); // 出现未声明字段则报错
Base.passthrough(); // 保留未声明字段
```

> 注意:`z.object()` 默认会**剥离**(strip)schema 中未声明的字段——校验通过后返回的对象只含已声明字段。这是有意的安全设计,需要保留多余字段时用 `.passthrough()`。

## 5. 实战场景

本章是文档重点,三个场景的代码均可直接搬到项目改用。

### 5.1 场景一:API 数据校验

核心理念:**别再用 `as` 断言,在 fetch 的出口用 parse 把住数据。**

```typescript
const UserSchema = z.object({
  id: z.number(),
  name: z.string(),
  email: z.email(),
});

type User = z.infer<typeof UserSchema>;

async function getUser(id: number): Promise<User> {
  const res = await fetch(`/api/users/${id}`);
  const json = await res.json(); // 此刻类型是 any,完全不可信
  return UserSchema.parse(json); // ✅ 校验 + 类型收窄,一步到位
}
```

收益:后端字段改了、少传了、类型错了,**在数据进入业务逻辑的第一现场就炸**,而不是在多层组件之后才出现 `undefined` 报错。

实战中两个常见搭配:

```typescript
// 1. 列表接口:用 z.array 包一层
const UserListSchema = z.array(UserSchema);

// 2. 通用响应壳:很多后端是 { code, msg, data } 结构,用泛型函数复用
function apiResponse<T extends z.ZodType>(dataSchema: T) {
  return z.object({
    code: z.number(),
    msg: z.string(),
    data: dataSchema,
  });
}

const UserResp = apiResponse(UserSchema); // { code, msg, data: User }
```

进一步可在请求库里统一拦截。以封装一个带校验的 `request` 为例:

```typescript
// 统一封装:传入 schema,返回校验后的强类型数据
async function request<T extends z.ZodType>(
  url: string,
  schema: T,
): Promise<z.infer<T>> {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const json = await res.json();

  const result = schema.safeParse(json);
  if (!result.success) {
    // 校验失败说明前后端契约不一致,值得单独上报监控
    console.error("响应数据校验失败:", result.error.issues);
    throw new Error("响应数据格式不符合预期");
  }
  return result.data;
}

// 调用处:类型自动推导,无需手写泛型
const user = await request("/api/users/1", UserSchema); // user: User
```

### 5.2 场景二:类型推导与复用

不要「先写 interface,再写校验」——那是两份会漂移的真相。**只写 schema,类型用 `z.infer` 抽出来**,保证类型与校验永远同步。

```typescript
const CreateUserInput = z.object({
  name: z.string().min(1),
  email: z.email(),
});

// 类型从 schema 推导,改 schema 类型自动跟着变
type CreateUserInput = z.infer<typeof CreateUserInput>;
// { name: string; email: string }
```

一个容易忽略的细节:当 schema 带**默认值或 transform** 时,**输入类型与输出类型不同**:

```typescript
const QuerySchema = z.object({
  page: z.number().default(1), // 输入可不传,输出一定有
  keyword: z.string().optional(),
});

type QueryInput = z.input<typeof QuerySchema>; // { page?: number; keyword?: string }
type QueryOutput = z.output<typeof QuerySchema>; // { page: number; keyword?: string }
```

记住对应关系:

| 工具          | 含义                 | 等价          |
| ------------- | -------------------- | ------------- |
| `z.infer<T>`  | 解析**后**的结果类型 | `z.output<T>` |
| `z.input<T>`  | 解析**前**的输入类型 | ——            |
| `z.output<T>` | 解析后的输出类型     | `z.infer<T>`  |

> 注意:`z.infer` 等于 `z.output`。只有涉及默认值 / transform 时才需要区分 `z.input`。v4 中 `.default()` 短路为**输出类型**——即默认值需符合输出类型;若要复刻 v3 的「默认值走输入类型」行为,用 `.prefault()`。

### 5.3 场景三:环境变量与配置校验

环境变量全是 `string | undefined`,最适合在**应用启动那一刻**用 Zod 校验:不合法就让进程起不来(fail-fast),而不是跑到一半才发现少配了 key。

```typescript
// env.ts
import { z } from "zod";

const EnvSchema = z.object({
  NODE_ENV: z.enum(["development", "production", "test"]),
  PORT: z.coerce.number().default(3000), // coerce: "3000"(字符串) → 3000(数字)
  DATABASE_URL: z.url(),
  API_TIMEOUT: z.coerce.number().int().positive().default(5000),
});

// 启动时解析:缺 DATABASE_URL 或格式错,进程直接报错并指明字段
export const env = EnvSchema.parse(process.env);
```

```typescript
// 使用处:env 是强类型的,且保证已校验
import { env } from "./env";

env.PORT; // number(已从字符串转换)
env.NODE_ENV; // "development" | "production" | "test"
```

这里的关键工具是 **`z.coerce`**:env 全是字符串,`z.coerce.number()` 会先 `Number(val)` 再校验,省去手动转换。

> 注意:`z.coerce.boolean()` 的语义是 JS 的 truthy 判断——**任何非空字符串都为 `true`,包括 `"false"`**。要严格区分布尔字符串,需自行处理,详见第 7 章。

## 6. 进阶:refine 与 transform

> 本章对新手是进阶内容,可先跳过;但实际项目里跨字段校验和数据转换很常见,早晚会用到。

### 6.1 refine:自定义校验

内置约束不够用时(尤其**跨字段**校验),用 `.refine()` 写自定义规则:

```typescript
const PasswordSchema = z
  .object({
    password: z.string().min(8),
    confirm: z.string(),
  })
  .refine((data) => data.password === data.confirm, {
    error: "两次输入的密码不一致", // v4 用 error;v3 用 message
    path: ["confirm"], // 指定错误归属字段,前端能精确定位
  });
```

需要**多条**自定义校验或更精细控制时,用 `.superRefine()`(v4 也可用 `.check()`):

```typescript
const FormSchema = z.object({ start: z.number(), end: z.number() }).superRefine(
  (data, ctx) => {
    if (data.end <= data.start) {
      ctx.addIssue({
        code: "custom",
        message: "结束值必须大于开始值",
        path: ["end"],
      });
    }
  },
);
```

### 6.2 transform:校验后转换数据

`.transform()` 在校验通过后,顺手把数据转成你想要的形态:

```typescript
// 输入校验为 string,输出转成处理过的小写、去空格字符串
const NormalizedEmail = z.email().transform((s) => s.trim().toLowerCase());

NormalizedEmail.parse("  Foo@Bar.com "); // "foo@bar.com"

// 常见用法:把字符串日期转成 Date 对象
const DateSchema = z.string().transform((s) => new Date(s));
type DateOutput = z.infer<typeof DateSchema>; // Date
```

> 提示:`transform` 会让 `z.input` 与 `z.output` 类型产生差异(见 5.2),这正是需要区分二者的典型场景。

### 6.3 与表单库集成

Zod 可直接对接 `react-hook-form`,用同一份 schema 既做校验又做类型:

```typescript
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";

const schema = z.object({ name: z.string().min(1), email: z.email() });
type FormData = z.infer<typeof schema>;

function MyForm() {
  const { register, handleSubmit, formState } = useForm<FormData>({
    resolver: zodResolver(schema), // 校验交给 Zod
  });
  // formState.errors 会自动带上 schema 的报错信息
}
```

## 7. 避坑清单

| 编号 | 坑                              | 说明                                                                                           |
| ---- | ------------------------------- | ---------------------------------------------------------------------------------------------- |
| 1    | 该用 `safeParse` 却用了 `parse` | 接口/表单这类「预期会失败」的场景用 `safeParse` 处理分支;只有「失败即 bug」才用 `parse` 让它抛 |
| 2    | `z.coerce.boolean()` 反直觉     | 任何非空字符串(含 `"false"`)都为 `true`                                                        |
| 3    | 混淆三个修饰符                  | `optional`=可省(undefined)、`nullable`=允许 null、`default`=缺省补值,语义不同                  |
| 4    | 全项目滥用 Zod                  | 有运行时开销,只在**边界**用;内部纯逻辑用普通 TS 类型                                           |
| 5    | 忘了对象默认剥离字段            | `z.object` 默认 strip 多余字段,需保留用 `.passthrough()`                                       |

### 7.1 该用 safeParse 的场景误用了 parse

```typescript
// ❌ 表单校验里用 parse,失败抛异常,还得到处包 try-catch
const data = FormSchema.parse(formInput);

// ✅ 用 safeParse,优雅处理失败分支
const result = FormSchema.safeParse(formInput);
if (!result.success) {
  showErrors(result.error.issues);
  return;
}
submit(result.data);
```

### 7.2 coerce.boolean 的反直觉行为

```typescript
// ❌ 期望 "false" 转成 false,实际得到 true
z.coerce.boolean().parse("false"); // true(非空字符串都是 truthy)

// ✅ 严格区分布尔字符串:用枚举 + transform
const StrictBool = z
  .enum(["true", "false"])
  .transform((v) => v === "true");
StrictBool.parse("false"); // false
```

### 7.3 区分 optional / nullable / default

```typescript
const Schema = z.object({
  a: z.string().optional(), // a?: string —— 可不传
  b: z.string().nullable(), // b: string | null —— 必须传,但可为 null
  c: z.string().default("x"), // 输入可不传,输出一定是 string
});

Schema.parse({ b: null }); // ✅ { b: null, c: "x" }
```

## 8. 选型对比

Zod 是 TS 生态运行时校验的事实标准,但并非唯一选择。理解整个生态有助于在不同约束下做对决策。

### 8.1 Zod vs Joi(最常被拿来对比)

| 维度          | Joi                                       | Zod                                    |
| ------------- | ----------------------------------------- | -------------------------------------- |
| 出身          | hapi 后端生态,老牌                        | TS-first,后起                          |
| 设计取向      | **运行时优先**,JS 库顺带支持 TS           | **类型即校验**,为 TS 而生              |
| 类型推导      | **弱**:schema 推不出类型,需手写 interface | **强**:`z.infer` 一行抽出,单一事实来源 |
| 复杂条件校验  | 更强(`when` / `alternatives` 开箱即用)    | 靠 `refine` 自己写,灵活但需手动        |
| 体积 / 适用端 | 大,基本用于 Node 后端                     | 前后端通用,v4 体积与 tree-shaking 改善 |

对 TS 前端/全栈项目而言,**Joi 的最大短板就是类型推导**:它会逼你维护「schema + interface」两套东西,正是 Zod 要消灭的痛点。Joi 的主场是纯 Node 后端、对 TS 推导不敏感、但需要极复杂条件校验的场景。

### 8.2 生态横向对比

按 TS 推导能力从强到弱:

| 库          | 范式                | TS 推导 | 体积     | 一句话定位                            |
| ----------- | ------------------- | ------- | -------- | ------------------------------------- |
| **Zod**     | 链式                | 极强    | 中       | TS 项目默认首选,生态最大              |
| **Valibot** | 函数式 `pipe`       | 极强    | **极小** | Zod 的现代对手,主打 bundle 敏感场景   |
| **Yup**     | 链式                | 强      | 中       | 表单校验起家,异步友好                 |
| **io-ts**   | 函数式(fp-ts)       | 强      | 中       | 类型最严谨,学习曲线陡                 |
| **TypeBox** | TS 构造 JSON Schema | 强      | 小       | 同时产出类型 + JSON Schema,底层走 ajv |
| **Joi**     | 链式                | 弱      | 大       | 后端老牌,条件校验最强,TS 是短板       |
| **ajv**     | JSON Schema         | 弱      | 中       | **性能最快**,JSON Schema 标准实现     |

几个关键区分:

- **Valibot vs Zod**:Valibot 用函数组合(`pipe(string(), email())`)替代链式,每个校验是独立函数,**能被 tree-shaking 摇掉未用部分**,最终 bundle 更小。对体积极敏感的场景(边缘函数、轻量 SDK、移动端 H5)更优;否则 Zod 生态成熟度占上风。
- **ajv / TypeBox**:JSON Schema 派。项目本就要对接 JSON Schema 标准(如 Fastify、OpenAPI),或校验性能是硬指标时选它们。TypeBox 用 TS 语法写,一次同时拿到类型和 ajv 可用的 schema。
- **io-ts**:函数式编程范式,类型严谨度天花板,但团队无 FP 基础慎选。

### 8.3 选型决策

```text
TS + 前端/全栈项目
│
├─ 默认 → Zod
│   生态最大,react-hook-form / tRPC 原生支持,推导一流
│
├─ bundle 体积是硬约束(H5 / 边缘 / SDK)→ Valibot
│   换成 pipe 风格,摇树后体积最小,概念可平移
│
├─ 纯做表单且已用 Formik → Yup 也可
│   但新项目仍推 Zod + @hookform/resolvers
│
├─ 需要 JSON Schema 标准 / 极致性能 → ajv 或 TypeBox
│   TypeBox = TS 写法 + 类型推导 + ajv 性能
│
└─ 纯 Node 后端 + 超复杂条件校验 + 不在乎推导 → Joi
    否则后端也建议 Zod,与前端共享 schema 是巨大红利
```

> 提示:前后端都用 Zod 时,**一份 schema 可前后端共享**(校验逻辑与类型定义统一),这是 Joi 这类「后端专用 + 无推导」的库给不了的红利,tRPC 整套就建立在此之上。

## 9. FAQ

**Q1:校验失败的英文报错,怎么转成对用户友好的中文提示?**

遍历 `error.issues`,按 `path` 和 `code` 映射成自定义文案。也可在定义时用 `error` 参数(v4)直接写中文:

```typescript
const schema = z.object({
  name: z.string().min(1, { error: "姓名不能为空" }),
  email: z.email({ error: "邮箱格式不正确" }),
});

const result = schema.safeParse(input);
if (!result.success) {
  // issues 是数组,每条含 path(字段) 和 message(文案)
  const errors = result.error.issues.map((i) => ({
    field: i.path.join("."),
    message: i.message,
  }));
}
```

> 注意:v3 用 `message` 参数而非 `error`。

**Q2:多个 schema 之间怎么复用和组合?**

用对象操作方法(见 4.5):`extend` 追加、`merge` 合并、`pick` / `omit` 增删字段、`partial` 批量转可选。例如「创建用」schema 和「更新用」schema 可由同一个 Base 派生:

```typescript
const UserBase = z.object({ id: z.number(), name: z.string(), email: z.email() });
const CreateUser = UserBase.omit({ id: true }); // 创建时无 id
const UpdateUser = CreateUser.partial(); // 更新时字段都可选
```

**Q3:嵌套对象校验失败,怎么知道是哪个字段出错?**

看 `issue.path`,它是一个数组,精确标出层级路径:

```typescript
const schema = z.object({ user: z.object({ age: z.number() }) });
const result = schema.safeParse({ user: { age: "not a number" } });
if (!result.success) {
  result.error.issues[0].path; // ["user", "age"]
}
```

**Q4:Zod 会影响运行时性能吗?**

会有开销,因为校验是真实的运行时计算。原则是**只在边界用**(接口、用户输入、配置),内部纯逻辑用普通 TS 类型即可。高频热路径上避免重复 parse 同一份数据。

**Q5:已有大量手写 interface 的老项目,如何渐进引入 Zod?**

从「最不可信的边界」切入——优先给核心接口、env 配置加 schema,用 `z.infer` 替换对应的手写 interface;其余代码保持不动,逐步推进,无需一次性重写。

## 10. 总结

Zod 的核心可压缩成一句话:**TS 管编译期,Zod 管运行时边界;schema 是唯一事实来源,`parse` 把脏数据挡在门外,`z.infer` 把类型抽出来复用。**

落地要点速查表:

| 场景               | 推荐做法                                                      |
| ------------------ | ------------------------------------------------------------- |
| 定义类型           | 只写 schema,用 `z.infer` 推导类型,不手写 interface            |
| 校验接口数据       | 在 fetch 出口 `parse`/`safeParse`,替代 `as` 断言              |
| 处理可能失败的输入 | 用 `safeParse` 处理 `{ success, data/error }` 分支            |
| 失败即 bug 的场景  | 用 `parse` 让 `ZodError` 冒泡                                 |
| 校验环境变量       | 启动时 `parse(process.env)`,配 `z.coerce` 转类型              |
| 跨字段校验         | `.refine()` / `.superRefine()`                                |
| 校验后转换数据     | `.transform()`                                                |
| 选型               | TS 项目默认 Zod;体积敏感选 Valibot;JSON Schema 选 ajv/TypeBox |

常用 API 速查:

| API                                           | 作用                        |
| --------------------------------------------- | --------------------------- |
| `z.object({...})`                             | 对象 schema                 |
| `z.array(s)`                                  | 数组                        |
| `z.enum([...])`                               | 字面量枚举                  |
| `z.union([a, b])`                             | 联合类型                    |
| `.optional()` / `.nullable()` / `.default(x)` | 可省 / 允许 null / 缺省补值 |
| `.parse()` / `.safeParse()`                   | 解析(抛错 / 返回结果对象)   |
| `z.infer<T>` / `z.input<T>` / `z.output<T>`   | 类型推导                    |
| `z.coerce.number()`                           | 强制转换后校验              |
| `.refine()` / `.transform()`                  | 自定义校验 / 数据转换       |

## 参考资源

- [Zod 官方文档](https://zod.dev)
- [Zod v4 更新日志](https://zod.dev/v4/changelog)
- [Zod GitHub 仓库](https://github.com/colinhacks/zod)
- [@hookform/resolvers(对接 react-hook-form)](https://github.com/react-hook-form/resolvers)
- [Valibot 官方文档](https://valibot.dev)
