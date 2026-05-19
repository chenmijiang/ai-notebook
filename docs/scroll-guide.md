# JavaScript 滚动控制完全指南

## 1. 概述

### 1.1 什么是滚动

**滚动（Scrolling）**是指当元素内容超出其可视区域时，通过偏移内容来查看溢出部分的交互行为。在 Web 中，滚动既可以发生在文档（`<html>` 或 `<body>`）层级，也可以发生在任何 `overflow: auto/scroll` 的元素上。

掌握滚动 API 的核心难点不在于单个方法，而在于：

- **几何模型**：理解 `scrollTop`、`clientHeight`、`scrollHeight` 三者关系
- **滚动容器**：识别"谁在滚动"，避免事件挂错对象
- **性能边界**：`scroll` 事件触发频率极高，必须正确节流
- **CSS 配合**：现代 CSS 已经能替代很多 JS 滚动逻辑

### 1.2 API 分类速览

| 类别     | 代表 API                                                  |
| -------- | --------------------------------------------------------- |
| 几何读取 | `scrollTop`、`scrollHeight`、`clientHeight`               |
| 主动控制 | `scrollTo`、`scrollBy`、`scrollIntoView`                  |
| 事件监听 | `scroll`、`scrollend`、`scrollsnapchange`                 |
| 可视检测 | `IntersectionObserver`、`getBoundingClientRect`           |
| CSS 控制 | `scroll-behavior`、`scroll-snap-*`、`overscroll-behavior` |

> **提示**：详尽速查表在 §8.1，本节先建立分类印象即可。

### 1.3 为什么需要系统学习

零散使用滚动 API 会遇到常见困境：

| 问题表现                 | 根本原因                              |
| ------------------------ | ------------------------------------- |
| 滚动监听不触发           | 监听了 `window`，但实际是子容器在滚动 |
| 平滑滚动不生效           | 父级 `scroll-behavior` 被 `auto` 覆盖 |
| 移动端滚动卡顿           | 未使用 `passive` 监听器               |
| 无限滚动重复加载         | 没有节流或加载状态锁                  |
| `scrollTop = 0` 没有动画 | 该属性赋值不触发平滑滚动              |

本指南按"几何 → 控制 → 事件 → CSS → 场景"的顺序展开。下一节先把**几何属性**讲清楚——它是其他所有滚动操作的基础。

## 2. 滚动几何与位置读取

### 2.1 元素尺寸的三组属性

理解滚动的第一步，是分清元素的三组尺寸：

| 属性                           | 含义                                    | 是否可写 |
| ------------------------------ | --------------------------------------- | -------- |
| `clientWidth` / `clientHeight` | 可视区域尺寸（含 padding，不含 border） | 只读     |
| `offsetWidth` / `offsetHeight` | 元素总尺寸（含 padding + border）       | 只读     |
| `scrollWidth` / `scrollHeight` | 内容总尺寸（含溢出部分）                | 只读     |

ASCII 示意图（关键：内容竖向超出可视区域，被裁剪的部分在框外）：

```text
                  ┌────────────────────────┐
                  │  ↑                     │
                  │  scrollTop（已滚动）     │
                  │  ↓                     │
┌─────────────────┼────────────────────────┼────┐ ← offsetHeight（含 border）
│ ┌───────────────┼────────────────────────┼──┐ │
│ │ ┌─────────────┴────────────────────────┴┐ │ │
│ │ │   内 容 总 高 度  scrollHeight          │ │ │
│ │ │ ┌────────────────────────────────────┐ │ │ │ ← 可视区域 clientHeight
│ │ │ │     当 前 可 见 部 分                │ │ │ │   （裁剪窗口）
│ │ │ │                                    │ │ │ │
│ │ │ └────────────────────────────────────┘ │ │ │
│ │ │     被裁剪的溢出部分                     │ │ │
│ │ └───────────────────────────────────────┘ │ │
│ └───────────────────────────────────────────┘ │
└───────────────────────────────────────────────┘
```

简洁记忆：`scrollHeight ≥ clientHeight`，差额就是"可滚动距离"。

判断"是否有滚动条"的公式：

```javascript
// ✅ 判断元素是否可垂直滚动
function isScrollable(el) {
  return el.scrollHeight > el.clientHeight;
}

// ✅ 判断是否滚动到底部（容忍 1px 误差）
function isAtBottom(el) {
  return Math.abs(el.scrollHeight - el.clientHeight - el.scrollTop) < 1;
}
```

> **注意**：高 DPI 屏幕上 `scrollTop` 可能是小数，使用 `Math.abs()` 容差判断更稳健。

### 2.2 滚动位置属性

| 属性                                 | 含义                         | 是否可写 |
| ------------------------------------ | ---------------------------- | -------- |
| `element.scrollTop` / `scrollLeft`   | 元素已滚动的距离             | 可写     |
| `window.scrollX` / `scrollY`         | 页面已滚动的距离             | 只读     |
| `window.pageXOffset` / `pageYOffset` | 同上（旧别名，建议用新名称） | 只读     |
| `document.documentElement.scrollTop` | 等同于 `window.scrollY`      | 可写     |

```javascript
// ✅ 直接修改 scrollTop 可以瞬间跳转
document.querySelector('.list').scrollTop = 500;

// ❌ 这种方式不会触发平滑滚动，即使设置了 scroll-behavior: smooth
// 想要动画请用 scrollTo / scrollBy（见 §3）
```

> **注意**：现代页面只用 `document.documentElement.scrollTop`（或 `window.scrollY`）。`document.body.scrollTop` 在标准模式下恒为 `0`，已被废弃。如需跨模式兼容，使用 `document.scrollingElement`。

### 2.3 getBoundingClientRect

获取元素相对**视口**的位置，是计算"元素是否在屏幕内"的基础方法：

```javascript
const rect = element.getBoundingClientRect();
// rect 包含：top, right, bottom, left, width, height, x, y
// 注意：top/left 是相对视口的，会随滚动变化
```

判断元素是否在视口内：

```javascript
// ✅ 完全可见
function isFullyVisible(el) {
  const rect = el.getBoundingClientRect();
  return (
    rect.top >= 0 &&
    rect.left >= 0 &&
    rect.bottom <= window.innerHeight &&
    rect.right <= window.innerWidth
  );
}

// ✅ 部分可见
function isPartiallyVisible(el) {
  const rect = el.getBoundingClientRect();
  return rect.bottom > 0 && rect.top < window.innerHeight;
}
```

> **提示**：高频判断元素可见性时，优先使用 `IntersectionObserver`（§5.5），性能远优于 `getBoundingClientRect`。

## 3. 主动控制滚动

本节先讲 JS 主动控制 API，§4 会展示如何用 CSS 替代其中很多场景——实际项目中应**优先尝试 CSS 方案**。

### 3.1 scrollTo 与 scrollBy

| 方法               | 行为             | 接受参数                              |
| ------------------ | ---------------- | ------------------------------------- |
| `scrollTo(x, y)`   | 滚动到绝对位置   | `(x, y)` 或 `{ top, left, behavior }` |
| `scrollBy(dx, dy)` | 相对当前位置滚动 | 同上                                  |
| `scroll()`         | `scrollTo` 别名  | 同上                                  |

```javascript
// ✅ 推荐的对象形式（更清晰、支持 behavior）
window.scrollTo({
  top: 0,
  left: 0,
  behavior: 'smooth', // 'auto' | 'smooth' | 'instant'
});

// ✅ 相对当前位置向下 200px
window.scrollBy({ top: 200, behavior: 'smooth' });

// ✅ 容器内滚动
document.querySelector('.list').scrollTo({ top: 0, behavior: 'smooth' });
```

`behavior` 的三个值：

| 值        | 含义                                     |
| --------- | ---------------------------------------- |
| `auto`    | 遵循 CSS `scroll-behavior`，默认即时跳转 |
| `smooth`  | 平滑滚动动画                             |
| `instant` | 强制即时跳转，忽略 CSS                   |

> **注意**：`'instant'` 是 2023 年才正式纳入 CSSOM View 规范的，早期版本的 Safari/Firefox 会把它当作无效值并回退到 `'auto'` 行为。要兼容老浏览器，可临时改写 CSS `scroll-behavior` 后再调用，或直接给 `scrollTop` 赋值。

### 3.2 scrollIntoView

让指定元素滚动到可视区域，是最常用的"跳转到某处"方法：

```javascript
element.scrollIntoView({
  behavior: 'smooth',
  block: 'start',    // 垂直对齐：'start' | 'center' | 'end' | 'nearest'
  inline: 'nearest', // 水平对齐：同上
});
```

| 选项     | 'start'        | 'center'     | 'end'          | 'nearest'          |
| -------- | -------------- | ------------ | -------------- | ------------------ |
| `block`  | 元素顶部对齐顶 | 元素居中     | 元素底部对齐底 | 最少移动距离的位置 |
| `inline` | 元素左侧对齐左 | 元素水平居中 | 元素右侧对齐右 | 最少移动距离的位置 |

> **提示**：如果不希望已经在可视区域的元素被滚动，使用 `block: 'nearest'`。这也是替代非标准 `scrollIntoViewIfNeeded` 的标准做法（Firefox 不支持后者）。

### 3.3 滚动到指定偏移（考虑固定头部）

固定头部会遮挡 `scrollIntoView` 的目标元素，需要修正偏移：

```javascript
// ✅ 滚动后留出 80px 给 sticky 顶栏
function scrollToWithOffset(el, offset = 80) {
  const top = el.getBoundingClientRect().top + window.scrollY - offset;
  window.scrollTo({ top, behavior: 'smooth' });
}
```

或使用 CSS 的 `scroll-margin-top`（推荐，见 §4.4）：

```css
.anchor-target {
  scroll-margin-top: 80px; /* scrollIntoView 时自动留出空间 */
}
```

## 4. CSS 滚动控制

现代 CSS 把许多滚动逻辑从 JS 中解放出来，能用 CSS 解决就不要写 JS。

### 4.1 scroll-behavior

让原生锚点跳转和 `scrollTo()` 默认带动画：

```css
html {
  scroll-behavior: smooth; /* 全局平滑滚动 */
}

/* 也可以作用于特定容器 */
.scroll-container {
  scroll-behavior: smooth;
}
```

> **注意**：JS 中 `scrollTo({ behavior: 'instant' })` 会强制忽略此 CSS 设置，适合"瞬间还原位置"的场景（如路由切换）。

### 4.2 scroll-snap 系列

实现"滚动吸附"效果，是现代轮播、卡片列表的首选方案：

| 属性                | 作用                                               |
| ------------------- | -------------------------------------------------- |
| `scroll-snap-type`  | 容器声明吸附方向和强度                             |
| `scroll-snap-align` | 子项声明吸附对齐方式（`start` / `center` / `end`） |
| `scroll-snap-stop`  | `normal` 允许快速滚过，`always` 强制每项停留       |
| `scroll-padding`    | 容器吸附时的内边距（如顶栏遮挡）                   |
| `scroll-margin`     | 子项吸附时的外边距                                 |

```html
<div class="carousel">
  <div class="slide">A</div>
  <div class="slide">B</div>
  <div class="slide">C</div>
</div>
```

```css
.carousel {
  display: flex;
  overflow-x: auto;
  scroll-snap-type: x mandatory; /* x 方向强制吸附 */
}
.slide {
  flex: 0 0 100%;
  scroll-snap-align: start;  /* 每张幻灯片左对齐 */
  scroll-snap-stop: always;  /* 禁止快速滚过 */
}
```

`scroll-snap-type` 的两个轴和两种强度：

| 值                 | 含义                             |
| ------------------ | -------------------------------- |
| `x` / `y` / `both` | 吸附方向                         |
| `mandatory`        | 必须吸附到吸附点（推荐用于轮播） |
| `proximity`        | 接近时才吸附（更柔和）           |

### 4.3 overscroll-behavior

控制"滚动到边界"时是否传播到父容器，是解决"模态框滚动穿透"的利器：

```css
.modal {
  overflow-y: auto;
  overscroll-behavior: contain; /* 滚到边界不传给页面 */
}

/* 三种取值 */
.a { overscroll-behavior: auto;     } /* 默认，传播滚动链，允许浏览器手势（如下拉刷新） */
.b { overscroll-behavior: contain;  } /* 不传播，但保留拉到底的橡皮筋 */
.c { overscroll-behavior: none;     } /* 不传播，且禁止橡皮筋 */
```

| 场景                            | 推荐值         |
| ------------------------------- | -------------- |
| 弹窗、抽屉内的滚动列表          | `contain`      |
| 全屏游戏/画布，禁用页面下拉刷新 | `none`         |
| 普通页面                        | `auto`（默认） |

### 4.4 scroll-margin 与 scroll-padding

精准控制 `scrollIntoView` 和锚点跳转的停靠位置：

```css
/* 容器：滚动时顶部留 80px（适合固定头部） */
.container {
  scroll-padding-top: 80px;
}

/* 子项：自身吸附时上方留 20px */
.section {
  scroll-margin-top: 20px;
}
```

> **提示**：`scroll-margin-top` 是替代 JS 计算偏移的最干净方案，请优先使用。

### 4.5 scrollbar-gutter

预留滚动条空间，避免内容因为滚动条出现/消失而横向跳动：

```css
.container {
  scrollbar-gutter: stable;        /* 始终预留滚动条空间 */
  /* 或 */
  scrollbar-gutter: stable both-edges; /* 两侧都预留，保持视觉居中 */
}
```

最常见的用途：打开模态框时锁定页面滚动（见 §6.4），需要给 `<html>` 加上 `scrollbar-gutter: stable`，避免内容跳动。

## 5. 滚动事件监听

### 5.1 scroll 事件

最基础的滚动事件，触发频率非常高（每帧甚至更多）：

```javascript
// ✅ 必须使用 passive，告诉浏览器不会调用 preventDefault
window.addEventListener('scroll', handler, { passive: true });

// ✅ 容器内滚动监听
document.querySelector('.list').addEventListener('scroll', handler, {
  passive: true,
});
```

> **注意**：**元素**的 `scroll` 事件不会冒泡——父容器监听不到子容器的滚动，必须直接在滚动容器上挂监听。`document` 的 `scroll` 事件会传到 `window`，这是 HTML 规范的特殊处理，不要把它误解为"`scroll` 冒泡"。

`passive: true` 的意义：

| 是否 passive | 行为                                                   |
| ------------ | ------------------------------------------------------ |
| `true`       | 承诺不调用 `preventDefault`，浏览器可优化滚动性能      |
| `false`      | 浏览器必须等待 JS 执行完才能滚动，移动端滚动会明显卡顿 |

### 5.2 scrollend 事件

`scrollend` 在滚动**停止**后触发，比反复检查 `scrollTop` 稳定性的旧方案优雅得多：

```javascript
element.addEventListener('scrollend', () => {
  console.log('滚动结束了');
});
```

**支持情况**（2026 年 5 月数据，请以 [caniuse](https://caniuse.com/mdn-api_element_scrollend_event) 为准）：Chrome 114（2023.5）、Firefox 109（2023.1）、Safari 18.2（2024 末）起支持。对低于上述版本的浏览器，用如下 polyfill：

```javascript
// ✅ scrollend 兼容性 fallback
function onScrollEnd(el, callback) {
  if ('onscrollend' in window) {
    el.addEventListener('scrollend', callback);
    return;
  }
  let timer;
  el.addEventListener('scroll', () => {
    clearTimeout(timer);
    timer = setTimeout(callback, 150);
  }, { passive: true });
}
```

### 5.3 scrollsnapchange 与 scrollsnapchanging

配合 `scroll-snap` 使用，能感知当前吸附到的卡片，无需自己计算：

| 事件                 | 触发时机                       |
| -------------------- | ------------------------------ |
| `scrollsnapchanging` | 滚动过程中预测会吸附到的新目标 |
| `scrollsnapchange`   | 滚动结束并最终吸附完成时       |

```javascript
carousel.addEventListener('scrollsnapchange', (e) => {
  console.log('当前吸附到：', e.snapTargetBlock);
});
```

### 5.4 性能优化：节流方案

`scroll` 事件每秒可能触发数百次，必须做节流。

#### 5.4.1 requestAnimationFrame（最常用）

```javascript
// ✅ 与帧率对齐，最适合视觉相关计算（视差、进度条）
let ticking = false;

window.addEventListener('scroll', () => {
  if (ticking) return;
  requestAnimationFrame(() => {
    updateProgressBar();
    ticking = false;
  });
  ticking = true;
}, { passive: true });
```

`ticking` 是一个**节流标志位**：一帧内即使触发 100 次 `scroll`，也只会调度一次 `requestAnimationFrame`，避免重复计算。

#### 5.4.2 时间阈值节流

对于"埋点上报"、"滚动位置持久化"这类非视觉副作用，时间节流（200~500ms）足够了。直接使用 `lodash.throttle`、`@github/mini-throttle` 等成熟工具，或几行代码自己实现（任何 JS 入门书都有示例）。

```javascript
// 示意：每 200ms 最多上报一次
window.addEventListener('scroll', throttle(saveScrollPosition, 200), {
  passive: true,
});
```

#### 5.4.3 用 IntersectionObserver 替代

很多"滚动到某位置触发"的需求，根本不需要监听 `scroll`，见 §5.5。

### 5.5 IntersectionObserver

观察元素与视口（或某个容器）的相交关系，是无限滚动、懒加载、曝光埋点的最佳工具：

```javascript
const observer = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        console.log(entry.target, '进入视口');
      }
    });
  },
  {
    root: null,           // null = 视口，也可指定滚动容器
    rootMargin: '100px',  // 提前 100px 触发（预加载）
    threshold: 0.5,       // 相交比例达到 50% 时触发
  }
);

observer.observe(document.querySelector('.target'));
```

| 配置项       | 含义                                          |
| ------------ | --------------------------------------------- |
| `root`       | 视口或指定滚动容器，默认 `null`（浏览器视口） |
| `rootMargin` | 类似 CSS margin，扩大/缩小观察范围            |
| `threshold`  | 相交比例阈值，数组形式可设置多个回调点        |

`scroll` 事件与 `IntersectionObserver` 的差异：

| 对比维度 | `scroll` 事件                      | `IntersectionObserver`               |
| -------- | ---------------------------------- | ------------------------------------ |
| 触发频率 | 极高，需手动节流                   | 由浏览器优化，低开销                 |
| 计算位置 | 需手动调用 `getBoundingClientRect` | 浏览器异步计算                       |
| 返回信息 | 实时滚动位置（可读 `scrollTop`）   | 仅相交状态变化，**无法拿到实时位置** |
| 适用场景 | 滚动联动（视差、进度条）           | 元素曝光、懒加载、无限滚动           |

> **提示**：不要试图用 `IntersectionObserver` 替代所有 `scroll`——它没有实时位置信息，无法做进度条或视差。

掌握了上面这些 API 后，下面进入 10 个典型场景，重点演示如何**组合**它们解决真实问题。场景按"使用频率/难度递增"排序，初学者可顺序阅读。

## 6. 实战场景

### 6.1 锚点平滑跳转

最简单的场景：点击 `<a href="#section">` 跳转时带平滑动画。

```css
/* 一行 CSS 搞定原生 #id 跳转的平滑滚动 */
html {
  scroll-behavior: smooth;
}

/* 修正 sticky 顶栏遮挡 */
:target {
  scroll-margin-top: 80px;
}
```

如需 JS 接管（例如配合路由）：

```javascript
document.querySelectorAll('a[href^="#"]').forEach((a) => {
  a.addEventListener('click', (e) => {
    e.preventDefault();
    const target = document.querySelector(a.getAttribute('href'));
    target?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  });
});
```

### 6.2 返回顶部按钮

```javascript
const btn = document.querySelector('.back-to-top');

// 滚动超过一屏显示按钮
window.addEventListener('scroll', () => {
  btn.classList.toggle('visible', window.scrollY > window.innerHeight);
}, { passive: true });

// 点击平滑回顶
btn.addEventListener('click', () => {
  window.scrollTo({ top: 0, behavior: 'smooth' });
});
```

> **优化**：用 `IntersectionObserver` 监听页首一个哨兵元素，比监听 `scroll` 更轻量。

### 6.3 吸顶导航

CSS 方案（首选）：

```css
.nav {
  position: sticky;
  top: 0;
  z-index: 10;
}
```

需要状态切换（如吸顶后变色）时用 `IntersectionObserver`：

```javascript
// ✅ 用一个哨兵元素检测是否吸顶
const sentinel = document.querySelector('.nav-sentinel');
const nav = document.querySelector('.nav');

new IntersectionObserver(([entry]) => {
  nav.classList.toggle('stuck', !entry.isIntersecting);
}).observe(sentinel);
```

### 6.4 弹窗时锁定页面滚动

第一层防线：弹窗内部的 `overscroll-behavior` 阻止边界穿透。

```css
/* ✅ 推荐：弹窗内部用 overscroll-behavior 阻止穿透 */
.modal-body {
  overflow-y: auto;
  overscroll-behavior: contain;
}
```

需要彻底锁定页面（背景完全不动）时，使用 `position: fixed` 配合位置还原：

```javascript
// ✅ 锁定时保存滚动位置，解锁后还原
let savedY = 0;

function lockScroll() {
  savedY = window.scrollY;
  document.body.style.position = 'fixed';
  document.body.style.top = `-${savedY}px`;
  document.body.style.width = '100%';
}

function unlockScroll() {
  document.body.style.position = '';
  document.body.style.top = '';
  document.body.style.width = '';
  window.scrollTo({ top: savedY, behavior: 'instant' });
}
```

配合 `scrollbar-gutter: stable` 避免滚动条消失导致的内容横向跳动：

```css
html {
  scrollbar-gutter: stable;
}
```

> **注意**：
>
> - 单纯设置 `overflow: hidden` 在 iOS Safari 上无效，必须用 `position: fixed`。
> - 页面中若有 `position: fixed` 的**子元素**（如悬浮按钮），锁定时其定位上下文会变化，可能出现位移；需要额外处理。
> - 弹窗中有输入框时，iOS Safari 弹出键盘会让光标位置错乱，必要时改用滚动容器自身锁定。

### 6.5 滚动方向：下滚隐藏、上滚显示顶栏

```javascript
const header = document.querySelector('.header');
let lastY = 0;
let ticking = false;

// ✅ rAF 节流，避免快速滚动时频繁加/删 class 引起抖动
window.addEventListener('scroll', () => {
  if (ticking) return;
  requestAnimationFrame(() => {
    const y = window.scrollY;
    if (y > lastY && y > 100) {
      header.classList.add('hidden');  // 下滚隐藏
    } else {
      header.classList.remove('hidden'); // 上滚显示
    }
    lastY = y;
    ticking = false;
  });
  ticking = true;
}, { passive: true });
```

### 6.6 滚动进度条

```javascript
// ✅ rAF 节流，平滑更新进度
const bar = document.querySelector('.progress-bar');
let ticking = false;

window.addEventListener('scroll', () => {
  if (ticking) return;
  requestAnimationFrame(() => {
    const max = document.documentElement.scrollHeight - window.innerHeight;
    const progress = (window.scrollY / max) * 100;
    bar.style.width = `${progress}%`;
    ticking = false;
  });
  ticking = true;
}, { passive: true });
```

纯 CSS 方案（**滚动驱动动画**，无需 JS）：

```css
.progress-bar {
  animation: progress linear;
  animation-timeline: scroll(root); /* 跟随页面滚动 */
}
@keyframes progress {
  from { width: 0; }
  to   { width: 100%; }
}
```

> **兼容性**：`animation-timeline` 在 Chrome 115+ / Edge 115+ / Firefox 已落地，Safari 截至 2026 年 5 月仍处实验阶段，需 `@supports` 兜底。配套的 `view-timeline` 还能根据**元素自身进入视口的进度**驱动动画，是实现"滚动至此处淡入"的现代方案。

### 6.7 横向卡片轮播

```html
<div class="carousel">
  <div class="card">1</div>
  <div class="card">2</div>
  <div class="card">3</div>
</div>
```

```css
.carousel {
  display: flex;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
  scroll-behavior: smooth;
  gap: 16px;
  scrollbar-width: none; /* 隐藏滚动条 */
}
.card {
  flex: 0 0 80%;
  scroll-snap-align: center;
}
```

切换到下一张：

```javascript
function next() {
  const carousel = document.querySelector('.carousel');
  carousel.scrollBy({ left: carousel.clientWidth, behavior: 'smooth' });
}

// ✅ 配合 scrollsnapchange 同步指示器状态
carousel.addEventListener('scrollsnapchange', (e) => {
  updateIndicator(e.snapTargetInline);
});
```

> **可访问性**：隐藏滚动条会让键盘用户失去导航线索；务必给卡片加 `tabindex` 和键盘事件（左右箭头切换）。

### 6.8 无限滚动加载

```javascript
// ✅ 用 IntersectionObserver 观察列表底部哨兵元素
const sentinel = document.querySelector('.load-more-sentinel');
let loading = false;

const observer = new IntersectionObserver(async ([entry]) => {
  if (!entry.isIntersecting || loading) return;
  loading = true;
  await loadNextPage();
  loading = false;
}, { rootMargin: '300px' }); // 提前 300px 加载

observer.observe(sentinel);
```

> **关键**：必须有 `loading` 锁，避免快速滚动时多次触发。

### 6.9 路由切换时还原滚动位置

```javascript
// ✅ SPA 路由切换：保存离开前位置，回退时还原
const scrollMap = new Map();

router.beforeEach((to, from) => {
  scrollMap.set(from.path, window.scrollY);
});

router.afterEach((to) => {
  const y = scrollMap.get(to.path) ?? 0;
  // 嵌套两次 rAF：第一帧完成 DOM 挂载，第二帧此时高度已正确
  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      window.scrollTo({ top: y, behavior: 'instant' });
    });
  });
});
```

为什么单次 `rAF` 不够：第一帧只能保证组件**挂载完成**，但内部图片、异步加载的列表此时往往还没决定最终高度，立即 `scrollTo` 会被截断到当前最大滚动距离。两次嵌套或配合"路由组件 mounted 钩子 + 监听 `<img>` load"才更可靠。框架层面 React Router 的 `ScrollRestoration`、Vue Router 的 `scrollBehavior` 已封装了这些细节，生产中优先使用。

### 6.10 虚拟列表（思路）

大数据列表只渲染可视区域内的项目：

```javascript
// 核心思路（简化版）
function renderVirtualList(container, items, itemHeight) {
  container.style.height = `${items.length * itemHeight}px`; // 撑出滚动条

  function update() {
    const start = Math.floor(container.scrollTop / itemHeight);
    const visibleCount = Math.ceil(container.clientHeight / itemHeight);
    const end = start + visibleCount + 5; // 多渲染 5 个做缓冲
    renderRange(items.slice(start, end), start * itemHeight);
  }

  container.addEventListener('scroll', update, { passive: true });
  update();
}
```

> **提示**：
>
> - 生产中请直接使用 `react-window`、`@tanstack/virtual` 等成熟库。
> - 虚拟列表会破坏键盘 `Tab` 顺序和 `Ctrl+F` 搜索，需要 `aria-rowcount` 等 ARIA 属性辅助可访问性。

## 7. 常见问题排查

**Q1: 监听 `scroll` 事件没有反应？**

检查是否监听错了对象。**元素**的 `scroll` 事件不冒泡，子容器的滚动不会传到 `window` 或祖先元素。在每个候选容器上加 `console.log` 确认实际的滚动容器，或在 DevTools Elements 面板查看哪个元素有滚动条。

**Q2: 给 `scrollTop` 赋值为什么没有平滑动画？**

直接赋值 `scrollTop` 永远是即时跳转。必须使用 `scrollTo({ top, behavior: 'smooth' })`。

**Q3: `scroll-behavior: smooth` 设置后不生效？**

检查：

1. 是否设置在了正确的滚动容器上（页面应在 `html` 或 `body` 上）
2. JS 是否使用了 `behavior: 'instant'` 强制覆盖
3. 是否被用户的"减少动画"系统偏好关闭（`prefers-reduced-motion`）

**Q4: iOS 上滚动卡顿/不流畅？**

- 给所有 `scroll` 监听加上 `{ passive: true }`
- iOS 13+ 已废弃 `-webkit-overflow-scrolling: touch`，惯性滚动现在是默认行为，无需再写
- 检查滚动容器内是否有触发重排的 JS（如频繁修改样式、`getBoundingClientRect`）

**Q5: 模态框打开后，滚动会"穿透"到背景页面？**

- 优先使用 `overscroll-behavior: contain` 阻止传播
- 彻底锁定用 `position: fixed` + 位置还原方案（见 §6.4）

**Q6: `getBoundingClientRect` 性能差怎么办？**

`getBoundingClientRect` 会触发**强制同步布局**（forced reflow），在 `scroll` 回调中频繁调用会显著拖慢帧率。替代方案：

- 用 `IntersectionObserver` 异步获取相交信息
- 缓存上次的 rect 值，避开不必要的查询
- 在 `rAF` 回调中调用而不是 `scroll` 直接调用

**Q7: 移动端 `100vh` 包含/不包含地址栏，导致滚动计算错乱？**

使用现代视口单位：`100dvh`（动态视口高度）会随地址栏显隐变化，是更可靠的选择。

**Q8: RTL 文档下 `scrollLeft` 的值是负的？**

历史上 Chrome / Firefox / Safari 对 RTL 容器的 `scrollLeft` 起始值定义不一致（有的从 0 递减到负值，有的从最大正值递减到 0）。现代浏览器（2023 后）统一为 CSS 工作组规范——RTL 下 `scrollLeft` 从 `0` 起步，向左滚动取负值。要做兼容，使用 `Math.abs(el.scrollLeft)` 比较距离，或用 `Element.scrollTo({ left })` 这种与方向无关的写法。

## 8. 总结

### 8.1 API 与最佳实践速查表

| 需求 / 实践                   | 推荐方案                                            | 备注                               |
| ----------------------------- | --------------------------------------------------- | ---------------------------------- |
| 读取滚动位置                  | `element.scrollTop` / `window.scrollY`              | 高 DPI 下可能是小数                |
| 读取内容总尺寸                | `element.scrollHeight`                              | 含溢出部分                         |
| 读取可视区域尺寸              | `element.clientHeight`                              | 含 padding，不含 border            |
| 跳转到指定位置                | `scrollTo({ top, behavior: 'smooth' })`             | 不要直接赋值 `scrollTop`（无动画） |
| 滚动元素到视口                | `el.scrollIntoView({ block: 'nearest' })`           | `nearest` 避免不必要的滚动         |
| 监听滚动                      | `addEventListener('scroll', fn, { passive: true })` | passive 是移动端性能必要条件       |
| 监听滚动停止                  | `addEventListener('scrollend', fn)`                 | 老浏览器用 setTimeout 兜底         |
| 检测元素曝光/无限滚动         | `IntersectionObserver`                              | 优先于 scroll 事件                 |
| 滚动联动视觉效果              | `scroll` 事件 + `requestAnimationFrame` 节流        | 必须有 `ticking` 标志位            |
| 平滑滚动                      | CSS `scroll-behavior: smooth`                       | 全局/容器级声明式开启              |
| 修正吸顶遮挡                  | CSS `scroll-margin-top`                             | 替代 JS 偏移计算                   |
| 滚动吸附（轮播/卡片）         | CSS `scroll-snap-type` + `scroll-snap-align`        | 配合 `scrollsnapchange`            |
| 防止滚动穿透                  | CSS `overscroll-behavior: contain`                  | 弹窗、抽屉首选                     |
| 防止滚动条出现/消失时内容跳动 | CSS `scrollbar-gutter: stable`                      | 配合滚动锁使用                     |
| 跨方向滚动比较距离            | `Math.abs(scrollTop/Left) < 1`                      | 容差判断 + RTL 兼容                |

### 8.2 选型决策树

```text
需要响应滚动？
├─ 检测元素进入视口 → IntersectionObserver
├─ 滚动视觉效果（进度条/视差） → scroll + rAF 节流
│                                  或 CSS animation-timeline（新）
├─ 滚动结束的副作用 → scrollend 事件
├─ 卡片吸附 → CSS scroll-snap + scrollsnapchange
└─ 简单的吸顶/吸底布局 → CSS position: sticky

需要主动滚动？
├─ 滚动到具体元素 → scrollIntoView
├─ 滚动到具体位置 → scrollTo
├─ 相对偏移 → scrollBy
└─ 不要直接赋值 scrollTop（无动画）

需要平滑滚动？
├─ 全局默认 → CSS scroll-behavior: smooth
└─ 单次控制 → scrollTo({ behavior: 'smooth' })
```

### 8.3 心智模型

记住这三句话，能解决 80% 的滚动问题：

1. **能用 CSS 不用 JS** — `scroll-behavior` / `scroll-snap` / `sticky` / `overscroll-behavior` 是声明式的，性能和可维护性都更好。
2. **能用 IntersectionObserver 不用 scroll 事件** — 除非真的需要实时滚动位置，否则用观察器。
3. **必须用 scroll 事件时，永远 `{ passive: true }` + `requestAnimationFrame`** — 这两件事一起做，不要省略任何一个。

## 9. 参考资源

- [MDN：Element.scroll 事件](https://developer.mozilla.org/zh-CN/docs/Web/API/Element/scroll_event)
- [MDN：Element.scrollTo()](https://developer.mozilla.org/zh-CN/docs/Web/API/Element/scrollTo)
- [MDN：Element.scrollIntoView()](https://developer.mozilla.org/zh-CN/docs/Web/API/Element/scrollIntoView)
- [MDN：IntersectionObserver](https://developer.mozilla.org/zh-CN/docs/Web/API/Intersection_Observer_API)
- [MDN：CSS Scroll Snap](https://developer.mozilla.org/zh-CN/docs/Web/CSS/CSS_scroll_snap)
- [MDN：overscroll-behavior](https://developer.mozilla.org/zh-CN/docs/Web/CSS/overscroll-behavior)
- [MDN：scrollbar-gutter](https://developer.mozilla.org/zh-CN/docs/Web/CSS/scrollbar-gutter)
- [MDN：scrollend 事件](https://developer.mozilla.org/zh-CN/docs/Web/API/Element/scrollend_event)
- [W3C CSSOM View Module](https://www.w3.org/TR/cssom-view/)
- [Web.dev：Scroll-driven animations](https://developer.chrome.com/articles/scroll-driven-animations/)
- [caniuse：scrollend](https://caniuse.com/mdn-api_element_scrollend_event)
- [caniuse：animation-timeline](https://caniuse.com/mdn-css_properties_animation-timeline)
