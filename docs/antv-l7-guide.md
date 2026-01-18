# AntV L7 使用指南

L7 是蚂蚁集团 AntV 数据可视化团队开源的基于 WebGL 的大规模地理空间数据可视化引擎。L7 中的 L 代表 Location，7 代表世界七大洲，寓意能为全球位置数据提供可视分析能力。

本文以“能上手 + 理解原理”为目标：先给出最小可运行示例，再从架构、核心概念、渲染与交互机制解释 L7 为什么能高性能渲染大规模空间数据。

## 1. 概述

### 1.1 适用读者

- 前端工程师：需要在 Web 应用中叠加点/线/面/热力等空间数据
- 数据可视化工程师：关注数据到视觉变量的映射、比例尺、渲染管线
- GIS/业务研发：希望在“底图（地图引擎）”之上做可视分析能力

### 1.2 你将学到什么

- L7 的核心抽象：`Scene` / `Map` / `Source` / `Layer`
- 常用链式 API：`.source()` / `.shape()` / `.size()` / `.color()` / `.style()` / `.animate()`
- 性能与交互的关键机制：批量渲染、拾取（picking）、聚合与瓦片化

### 1.3 前置条件

- 具备基本的 JavaScript/TypeScript 能力
- 了解经纬度与 GeoJSON 的基础概念（可参考本仓库的 [geojson-guide.md](./geojson-guide.md)）
- 选择底图：国内常用高德（`GaodeMap`），国际化常用 Mapbox（`Mapbox`）

> **注意**：使用 Mapbox 需要 `accessToken`。不要将 token 写死并提交到仓库，建议通过环境变量或运行时配置注入。

### 1.4 快速开始（最小可运行示例）

下面示例展示 L7 的最小闭环：创建 `Scene` → 绑定 `PointLayer` → 渲染到页面。

```javascript
import { Scene, PointLayer } from "@antv/l7";
import { GaodeMap } from "@antv/l7-maps";

const scene = new Scene({
  id: "map", // 页面上用于承载 WebGL 的容器 DOM id
  map: new GaodeMap({
    style: "dark",
    center: [121.47, 31.23], // 上海
    zoom: 10,
  }),
});

const data = {
  type: "FeatureCollection",
  features: [
    {
      type: "Feature",
      properties: { name: "示例点", value: 10 },
      geometry: { type: "Point", coordinates: [121.47, 31.23] },
    },
  ],
};

scene.on("loaded", () => {
  const layer = new PointLayer()
    .source(data)
    .shape("circle")
    .size("value", [6, 20])
    .color("#4FC3F7")
    .style({ opacity: 0.8 });

  scene.addLayer(layer);
});
```

## 2. 设计理念

### 2.1 图形符号学基础

L7 以图形符号学（Semiology of Graphics）为理论基础，将抽象的空间数据转化为可感知的视觉符号：

```
┌─────────────┐      视觉编码      ┌─────────────┐
│   原始数据   │  ───────────────→  │   图形符号   │
│  (数值/分类) │                    │  (点/线/面)  │
└─────────────┘                    └─────────────┘
        ↓                                 ↓
   数据属性                          视觉变量
   - 经纬度                          - 位置
   - 数值大小                        - 大小/高度
   - 类型分类                        - 颜色/形状
   - 时间序列                        - 动画/纹理
```

### 2.2 核心设计原则

| 设计原则   | 说明                                 |
| ---------- | ------------------------------------ |
| 数据驱动   | 从数据到图形的自动映射，无需手动绑定 |
| 声明式语法 | 链式调用描述"做什么"而非"怎么做"     |
| 图层抽象   | 不同可视化类型封装为独立图层         |
| 地图解耦   | 可视化层与底图分离，支持多种地图引擎 |

## 3. 整体架构

### 3.1 架构概览

```
┌────────────────────────────────────────────────────────────┐
│                        应用层                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ LarkMap  │  │ L7Plot   │  │ L7Draw   │  │ L7Editor │   │
│  │ (React)  │  │ (图表)   │  │ (绘制)   │  │ (编辑器) │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
├────────────────────────────────────────────────────────────┤
│                        核心层 (@antv/l7)                   │
│  ┌─────────────────────────────────────────────────────┐  │
│  │                     Scene (场景)                     │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐             │  │
│  │  │  Layer  │  │  Layer  │  │  Layer  │  ...        │  │
│  │  │ (点图层) │  │ (线图层) │  │ (面图层) │             │  │
│  │  └────┬────┘  └────┬────┘  └────┬────┘             │  │
│  │       │            │            │                   │  │
│  │       └────────────┼────────────┘                   │  │
│  │                    ↓                                │  │
│  │              ┌───────────┐                          │  │
│  │              │  Source   │ ← 数据源                  │  │
│  │              └───────────┘                          │  │
│  └─────────────────────────────────────────────────────┘  │
├────────────────────────────────────────────────────────────┤
│                        地图层 (@antv/l7-maps)              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ GaodeMap │  │  Mapbox  │  │   Map    │  │  Leaflet │   │
│  │ (高德)    │  │          │  │ (无底图)  │  │          │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
├────────────────────────────────────────────────────────────┤
│                        渲染层                              │
│  ┌─────────────────────────────────────────────────────┐  │
│  │                    WebGL / GPU                       │  │
│  │        顶点着色器 → 光栅化 → 片元着色器 → 输出         │  │
│  └─────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
```

### 3.2 Monorepo 包结构

L7 采用 Monorepo 架构管理多个子包：

| 包名                 | 说明                              |
| -------------------- | --------------------------------- |
| `@antv/l7`           | 核心包，包含完整功能              |
| `@antv/l7-core`      | 核心模块，Scene 和渲染管理        |
| `@antv/l7-layers`    | 图层实现                          |
| `@antv/l7-maps`      | 地图引擎适配器                    |
| `@antv/l7-source`    | 数据源解析                        |
| `@antv/l7-utils`     | 工具函数                          |
| `@antv/l7-component` | UI 组件（Control、Marker、Popup） |

## 4. 核心概念

### 4.1 Scene（场景）

Scene 是 L7 应用的顶层容器，负责：

- 管理地图实例和图层生命周期
- 协调渲染循环
- 处理用户交互事件
- 管理 UI 组件

```javascript
import { Scene } from "@antv/l7";
import { GaodeMap } from "@antv/l7-maps";

// ✅ 创建场景
const scene = new Scene({
  id: "map", // 容器 DOM id
  map: new GaodeMap({
    // 底图实例
    style: "dark", // 地图样式
    center: [120.19, 30.26], // 中心点 [经度, 纬度]
    zoom: 10, // 缩放级别
    pitch: 45, // 倾斜角度
  }),
});

// 场景加载后添加图层
scene.on("loaded", () => {
  scene.addLayer(layer);
});
```

### 4.2 Map（底图）

L7 支持多种底图引擎，通过适配器模式实现统一接口：

| 底图类型     | 适用场景    | 说明                |
| ------------ | ----------- | ------------------- |
| `GaodeMap`   | 国内业务    | 高德地图，安全合规  |
| `Mapbox`     | 国际化/离线 | Mapbox GL，需 token |
| `Map`        | 无底图      | 纯数据可视化场景    |
| `TencentMap` | 腾讯生态    | 腾讯地图            |

> **提示**：如果你的业务侧需要“可控、可审计”的配置方式，建议把 token/样式等作为运行时配置（而不是硬编码在源码里）。

```javascript
// ✅ 高德地图（国内推荐）
import { GaodeMap } from "@antv/l7-maps";
const map = new GaodeMap({
  style: "dark",
  center: [116.4, 39.9],
  zoom: 12,
});

// ✅ Mapbox（国际化场景）
import { Mapbox } from "@antv/l7-maps";
const map = new Mapbox({
  style: "mapbox://styles/mapbox/dark-v10",
  accessToken: "your-mapbox-token", // 建议通过环境变量/运行时配置注入
  center: [-122.4, 37.8],
  zoom: 12,
});
```

### 4.3 Source（数据源）

Source 负责数据的加载、解析和预处理：

```
原始数据 → Parser 解析 → 标准化结构 → 图层使用
```

#### 4.3.1 支持的数据格式

| 格式    | Parser    | 说明                      |
| ------- | --------- | ------------------------- |
| GeoJSON | `geojson` | 地理数据标准格式（默认）  |
| JSON    | `json`    | 普通 JSON，需指定坐标字段 |
| CSV     | `csv`     | 表格数据，需指定经纬度列  |
| Image   | `image`   | 图片数据（热力图背景等）  |
| Raster  | `raster`  | 栅格数据（卫星影像等）    |

```javascript
// ✅ GeoJSON 格式（推荐）
layer.source(geojsonData);

// ✅ JSON 数组格式
layer.source(jsonData, {
  parser: {
    type: "json",
    x: "lng", // 经度字段
    y: "lat", // 纬度字段
  },
});

// ✅ CSV 格式
layer.source(csvString, {
  parser: {
    type: "csv",
    x: "longitude",
    y: "latitude",
  },
});
```

#### 4.3.2 数据转换（Transform）

Source 支持数据转换操作：

```javascript
// ✅ 聚类转换
layer.source(data, {
  cluster: true, // 启用聚类
  clusterOption: {
    radius: 40, // 聚类半径（像素）
    maxZoom: 16, // 最大聚类层级
  },
});

// ✅ 六边形聚合
layer.source(data, {
  transforms: [
    {
      type: "hexagon", // 六边形网格
      size: 1000, // 网格大小（米）
      field: "value", // 聚合字段
      method: "sum", // 聚合方法
    },
  ],
});
```

### 4.4 Layer（图层）

图层是数据可视化的核心载体，负责将数据映射为图形。

#### 4.4.1 图层类型

```
                         L7 图层体系
    ┌───────────────────────┼───────────────────────┐
    ↓                       ↓                       ↓
┌───────┐              ┌───────┐              ┌────────┐
│ Point │              │ Line  │              │Polygon │
│ Layer │              │ Layer │              │ Layer  │
└───┬───┘              └───┬───┘              └───┬────┘
    │                      │                      │
    ├─ 气泡图               ├─ 路径图               ├─ 填充图
    ├─ 散点图               ├─ 弧线图               ├─ 3D 填充
    ├─ 符号图               ├─ 大圆航线             └─ 挤出图形
    ├─ 3D 柱状图            └─ 等高线
    ├─ 聚合图
    └─ 图标图

    ┌───────┐              ┌───────┐              ┌───────┐
    │HeatMap│              │Raster │              │ Image │
    │ Layer │              │ Layer │              │ Layer │
    └───┬───┘              └───┬───┘              └───┬───┘
        │                      │                      │
        ├─ 经典热力图          ├─ 卫星影像            └─ 图片叠加
        ├─ 蜂窝热力图          └─ DEM 高程
        └─ 网格热力图
```

#### 4.4.2 图层配置链式调用

L7 采用声明式的链式 API：

```javascript
import { PointLayer } from "@antv/l7";

const pointLayer = new PointLayer()
  .source(data) // 1. 绑定数据
  .shape("circle") // 2. 设置形状
  .size("population", [5, 50]) // 3. 大小映射
  .color("population", [
    // 4. 颜色映射
    "#0D47A1",
    "#1976D2",
    "#42A5F5",
    "#90CAF9",
    "#E3F2FD",
  ])
  .style({
    // 5. 样式配置
    opacity: 0.8,
    strokeWidth: 1,
    stroke: "#fff",
  })
  .animate(true); // 6. 动画配置
```

## 5. 视觉映射系统

### 5.1 视觉通道

L7 通过视觉通道将数据属性映射为图形属性：

| 视觉通道 | 方法         | 适用数据类型 | 说明               |
| -------- | ------------ | ------------ | ------------------ |
| 形状     | `.shape()`   | 分类         | 圆形、方形、图标等 |
| 大小     | `.size()`    | 连续/分类    | 点大小、线宽度     |
| 颜色     | `.color()`   | 连续/分类    | 填充色、边框色     |
| 样式     | `.style()`   | -            | 透明度、边框等     |
| 动画     | `.animate()` | -            | 动态效果           |

### 5.2 数据映射类型

```javascript
// ✅ 常量映射：所有元素使用相同值
layer.size(20);
layer.color("#f00");

// ✅ 字段映射：根据字段值自动分配
layer.color("population"); // 连续型
layer.shape("type"); // 分类型

// ✅ 回调映射：自定义映射逻辑
layer.color("population", (value) => {
  return value > 1000000 ? "#f00" : "#0f0";
});

// ✅ 区间映射：指定输出范围
layer.size("population", [5, 50]); // 大小范围
layer.color("population", ["#0ff", "#f00"]); // 颜色渐变
```

### 5.3 Scale（比例尺）

L7 内置多种比例尺自动处理数据到视觉的映射：

```
数据域 (Domain)                    视觉域 (Range)
   ↓                                   ↓
[min, max]  ──── Scale ────→  [视觉最小值, 视觉最大值]
```

| 比例尺类型 | 适用场景       | 说明             |
| ---------- | -------------- | ---------------- |
| linear     | 连续数值       | 线性映射（默认） |
| log        | 差异较大的数值 | 对数映射         |
| quantile   | 均匀分布       | 分位数映射       |
| quantize   | 等间隔分段     | 等量映射         |
| cat        | 分类数据       | 类别映射         |

## 6. 渲染管线

### 6.1 WebGL 渲染流程

L7 基于 WebGL 实现 GPU 加速渲染：

```
┌──────────────────────────────────────────────────────────────┐
│                      L7 渲染管线                              │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐      │
│  │  JavaScript │    │   Vertex    │    │   图元      │      │
│  │    数据     │ →  │   Buffer    │ →  │   组装      │      │
│  │  (GeoJSON)  │    │  (顶点缓冲)  │    │             │      │
│  └─────────────┘    └─────────────┘    └─────────────┘      │
│                            ↓                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐      │
│  │   顶点      │    │    光栅化    │    │   片元      │      │
│  │  着色器     │ →  │  (生成像素)  │ →  │  着色器     │      │
│  │  (GLSL)    │    │             │    │  (GLSL)    │      │
│  └─────────────┘    └─────────────┘    └─────────────┘      │
│                                               ↓              │
│                                       ┌─────────────┐       │
│                                       │   帧缓冲    │       │
│                                       │   输出      │       │
│                                       └─────────────┘       │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### 6.2 着色器（Shader）

L7 使用 GLSL 编写自定义着色器，实现丰富的视觉效果：

```glsl
// 顶点着色器示例
attribute vec4 a_Position;
attribute vec4 a_Color;
uniform mat4 u_ModelMatrix;
varying vec4 v_Color;

void main() {
  gl_Position = u_ModelMatrix * a_Position;
  v_Color = a_Color;
}
```

```glsl
// 片元着色器示例
precision mediump float;
varying vec4 v_Color;

void main() {
  gl_FragColor = v_Color;
}
```

### 6.3 后处理效果

L7 2.8+ 支持图层级别的后处理效果：

```javascript
// ✅ 启用泛光效果
const scene = new Scene({
  id: "map",
  map: new GaodeMap({
    /* ... */
  }),
  enableMultiPassRenderer: true, // 启用多通道渲染
});

layer.style({
  passes: [
    ["bloom", { intensity: 1.5 }], // 泛光效果
  ],
});
```

## 7. 交互系统

### 7.1 图层交互

L7 通过离屏渲染实现高性能的像素级拾取：

```
┌─────────────────────────────────────────────────┐
│              离屏渲染拾取原理                     │
├─────────────────────────────────────────────────┤
│                                                 │
│  1. 为每个图形分配唯一 ID                        │
│  2. 将 ID 编码为颜色值渲染到离屏缓冲              │
│  3. 读取鼠标位置像素颜色                         │
│  4. 解码颜色值还原图形 ID                        │
│                                                 │
│   ┌─────────┐        ┌─────────┐              │
│   │ 主画布   │        │ 拾取缓冲 │              │
│   │ (显示)  │        │ (隐藏)  │              │
│   │  ●●●    │        │  RGB→ID │              │
│   │   ●     │        │         │              │
│   └─────────┘        └─────────┘              │
│                                                 │
└─────────────────────────────────────────────────┘
```

```javascript
// ✅ 启用图层交互
layer.active(true); // 鼠标悬停高亮
layer.select(true); // 点击选中

// 自定义高亮颜色
layer.active({
  color: "#f00",
});

// 监听交互事件
layer.on("mouseenter", (e) => {
  console.log("鼠标进入:", e.feature.properties);
});

layer.on("click", (e) => {
  console.log("点击要素:", e.feature.properties);
});
```

### 7.2 地图控件

```javascript
import { Zoom, Scale, Fullscreen } from "@antv/l7";

// ✅ 添加控件
scene.addControl(new Zoom({ position: "topright" }));
scene.addControl(new Scale({ position: "bottomleft" }));
scene.addControl(new Fullscreen());
```

### 7.3 信息展示

```javascript
import { Popup, Marker } from "@antv/l7";

// ✅ 弹窗
const popup = new Popup({
  offsets: [0, -20],
  closeButton: false,
})
  .setLnglat([lng, lat])
  .setHTML(`<h3>${name}</h3><p>Population: ${pop}</p>`);

scene.addPopup(popup);

// ✅ 标记点
const marker = new Marker().setLnglat([lng, lat]);

scene.addMarker(marker);
```

## 8. 性能优化

### 8.1 大数据渲染策略

| 策略           | 说明                 | 适用场景     |
| -------------- | -------------------- | ------------ |
| WebGL 批量渲染 | GPU 并行处理大量图元 | 百万级点数据 |
| 瓦片化加载     | 按视口动态加载数据   | 海量数据分区 |
| 数据聚合       | 相近数据合并展示     | 缩小层级时   |
| LOD            | 根据缩放级别切换精度 | 多尺度数据   |

### 8.2 图层数据聚合

```javascript
// ✅ 点聚合
const clusterLayer = new PointLayer()
  .source(data, {
    cluster: true,
    clusterOption: {
      radius: 40,
      maxZoom: 15,
      minZoom: 0,
    },
  })
  .shape("circle")
  .size("point_count", [20, 50])
  .color("#0ff");
```

### 8.3 性能配置

```javascript
// ✅ Scene 性能配置
const scene = new Scene({
  id: "map",
  map: new GaodeMap({
    /* ... */
  }),
  animate: false, // 禁用自动动画循环
  pickBufferScale: 0.5, // 拾取缓冲降采样
});

// ✅ 图层性能配置
layer.style({
  raisingHeight: 0, // 禁用抬升效果
});
```

## 9. 实战示例

### 9.1 场景1：城市热力图

```javascript
import { Scene, HeatmapLayer } from "@antv/l7";
import { GaodeMap } from "@antv/l7-maps";

// 1. 创建场景
const scene = new Scene({
  id: "map",
  map: new GaodeMap({
    style: "dark",
    center: [121.4, 31.2],
    zoom: 11,
  }),
});

// 2. 加载数据并创建热力图
scene.on("loaded", async () => {
  const res = await fetch(url);
  const data = await res.json();

  const heatmap = new HeatmapLayer()
    .source(data)
    .shape("heatmap3D")
    .size("count", [0, 1, 1])
    .color("count", [
      "#0A3663",
      "#1558AC",
      "#3BDDD8",
      "#67C1A3",
      "#EDF8A3",
      "#F5E164",
    ])
    .style({
      intensity: 5,
      radius: 20,
      opacity: 1,
    });

  scene.addLayer(heatmap);
});
```

### 9.2 场景2：飞线动画

```javascript
import { Scene, LineLayer } from "@antv/l7";
import { GaodeMap } from "@antv/l7-maps";

const scene = new Scene({
  id: "map",
  map: new GaodeMap({
    style: "dark",
    center: [116.4, 39.9],
    zoom: 4,
    pitch: 40,
  }),
});

scene.on("loaded", () => {
  // 弧线数据：起点 → 终点
  const flylineData = {
    type: "FeatureCollection",
    features: [
      {
        type: "Feature",
        properties: { weight: 100 },
        geometry: {
          type: "LineString",
          coordinates: [
            [116.4, 39.9], // 北京
            [121.4, 31.2], // 上海
          ],
        },
      },
      // ... 更多飞线
    ],
  };

  const flyline = new LineLayer()
    .source(flylineData)
    .shape("arc3d") // 3D 弧线
    .size(2)
    .color("#00BFFF")
    .style({
      opacity: 0.8,
      sourceColor: "#00BFFF", // 起点颜色
      targetColor: "#00FF7F", // 终点颜色
    })
    .animate({
      enable: true,
      duration: 2, // 动画时长（秒）
      interval: 0.5, // 动画间隔
      trailLength: 0.5, // 拖尾长度
    });

  scene.addLayer(flyline);
});
```

### 9.3 场景3：3D 建筑可视化

```javascript
import { Scene, CityBuildingLayer } from "@antv/l7";
import { GaodeMap } from "@antv/l7-maps";

const scene = new Scene({
  id: "map",
  map: new GaodeMap({
    style: "dark",
    center: [121.5, 31.2],
    zoom: 15,
    pitch: 60,
  }),
});

scene.on("loaded", async () => {
  // 加载建筑轮廓数据
  const res = await fetch("/buildings.geojson");
  const buildings = await res.json();

  const buildingLayer = new CityBuildingLayer()
    .source(buildings)
    .size("height", (h) => h) // 高度映射
    .color("height", [
      "#1A237E",
      "#283593",
      "#303F9F",
      "#3949AB",
      "#3F51B5",
      "#5C6BC0",
    ])
    .style({
      opacity: 0.9,
      baseColor: "#0A1F44",
      windowColor: "#FFFFCC",
      brightColor: "#FFF5CC",
    })
    .animate({
      enable: true,
    });

  scene.addLayer(buildingLayer);
});
```

## 10. 总结

### 10.1 核心概念速查

| 概念     | 说明                           |
| -------- | ------------------------------ |
| Scene    | 场景容器，管理地图、图层、组件 |
| Map      | 底图引擎，支持高德、Mapbox 等  |
| Layer    | 可视化图层，点/线/面/热力等    |
| Source   | 数据源，支持 GeoJSON/JSON/CSV  |
| 视觉通道 | shape/size/color/style/animate |
| Scale    | 数据到视觉的映射比例尺         |

### 10.2 技术栈概览

| 技术       | 作用         |
| ---------- | ------------ |
| TypeScript | 主要开发语言 |
| WebGL      | GPU 加速渲染 |
| GLSL       | 着色器编程   |
| Monorepo   | 代码组织架构 |

### 10.3 适用场景

- BI 可视化分析
- 城市大屏展示
- 交通/物流轨迹
- 地理信息系统（GIS）
- 位置数据分析

## 11. 参考资源

- [L7 官方文档](https://l7.antv.antgroup.com)
- [L7 GitHub 仓库](https://github.com/antvis/L7)
- [AntV 可视化解决方案](https://antv.antgroup.com)
- [L7 示例集合](https://l7.antv.antgroup.com/examples)
- [L7 DeepWiki](https://deepwiki.com/antvis/L7)
