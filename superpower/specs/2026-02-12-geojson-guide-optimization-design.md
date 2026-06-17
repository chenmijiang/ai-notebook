# GeoJSON 指南文档优化设计

## 优化目标

优化 `docs/geojson-guide.md` 的内容逻辑，解决三个问题：

1. 缺失几何对象与要素之间的组合关系描述
2. bbox 定义不清晰，缺少实际场景
3. 三维数据描述零散，不够系统

## 优化方案

### 1. 新增 GeoJSON 对象组合关系图

**位置**：第2节"数据结构"开头，新增 2.1 节"对象模型"，原 2.1-2.7 顺延编号。

**内容**：

- 使用 Mermaid classDiagram 展示对象之间的包含/引用关系：
  - `FeatureCollection` 包含多个 `Feature`（1 对多）
  - `Feature` 引用一个 `Geometry`，并携带 `properties`
  - `Geometry` 分为 `Point`、`LineString`、`Polygon`、`MultiPoint`、`MultiLineString`、`MultiPolygon`、`GeometryCollection`
  - `GeometryCollection` 包含多个 `Geometry`（递归组合）
  - 每个几何类型标注 `coordinates` 的维度结构
- 图下方加说明段落：GeoJSON 的核心设计是"几何 + 属性 = 要素，要素的集合 = 要素集合"
- 原有 ASCII 几何类型速览图保留，与 Mermaid 图互补（关系 vs 形状）

### 2. bbox 章节重组

对第5节"边界框"重新组织为四个小节：

**5.1 什么是 bbox**

- 保留现有格式说明（`[minLon, minLat, maxLon, maxLat]`）
- 增加文字解释：bbox 是包围几何对象的最小矩形范围，用于快速定位和过滤
- 配 ASCII 示意图：不规则多边形被矩形 bbox 包围

**5.2 bbox 的计算**

- JavaScript 函数示例：遍历坐标数组计算 min/max 值
- 提及 Turf.js 的 `turf.bbox()` 作为现成方案

**5.3 应用场景**

- 空间查询过滤：先用 bbox 做矩形相交判断（O(1)），排除无关数据，再做精确几何计算。附代码片段。
- 地图视口裁剪：前端地图将当前视口转为 bbox 参数请求后端 API，只返回该范围内的要素。附 API 请求参数示例。

**5.4 三维边界框**

- 保留现有三维 bbox 内容
- 加引用指向 4.4 节三维坐标说明

### 3. 三维坐标整合到坐标系统章节

**位置**：第4节"坐标系统"，在 4.3（坐标转换）之后新增 4.4 节"三维坐标"。

**内容**：

- 坐标格式：`[经度, 纬度, 高程]`，高程单位为米，基准为 WGS84 椭球面。Point 和 LineString 示例。
- 使用场景：建筑高度表达、飞行航线/无人机路径、地形等高线数据
- 注意事项：
  - 高程可选，大多数 Web 地图场景不需要，省略可减小数据体积
  - 不同数据源高程基准可能不同（海拔 vs 椭球高），混用会导致高度偏差

**清理**：

- 删除第9节 Q4（内容已整合到 4.4，避免重复）

## 不变更的部分

- 第1节概述、第3节 Feature/FeatureCollection、第6节应用场景、第7节 JavaScript 操作、第8节验证与优化、第10节总结 — 不做修改
- 第2节中的 ASCII 几何类型速览图保留
