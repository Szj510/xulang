# 叙廊连续叙事长廊 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将现有离散换图播放器重构为手指直接驱动的连续空间叙事轨道，并补齐「故事路径」模板、横屏编辑可达性和画面尺寸/画框即时反馈。

**Architecture:** `NarrativeTrackResolver` 在 `LayoutResolver` 的静态构图基础上生成每张照片的连续进入、聚焦和退出变换；`NarrativeCameraController` 独立处理拖拽、方向锁定、缩放优先级和惯性。`SceneCanvas` 仅根据轨道与 `cameraProgress` 渲染，编辑器和播放器复用同一结果。

**Tech Stack:** Flutter 3.41.7、Dart 3.11.5、Riverpod、Drift、flutter_test。

---

项目当前不是 Git 仓库，因此每个任务末尾以完整测试通过作为独立检查点，不执行提交。

### Task 1: 稳定持久化第五种模板

**Files:**
- Modify: `lib/domain/gallery_document.dart`
- Modify: `lib/layout/layout_resolver.dart`
- Modify: `lib/screens/editor_screen.dart`
- Test: `test/data/gallery_database_test.dart`
- Test: `test/layout/layout_resolver_test.dart`

- [ ] **Step 1: 写失败测试**

在数据库测试中保存并恢复 `GalleryLayout.storyPath`：

```dart
test('persists the story path layout by stable name', () async {
  final document = fixture.copyWith(chapters: [
    fixture.chapters.single.copyWith(layout: GalleryLayout.storyPath),
  ]);
  await database.saveBundle(GalleryBundle(document: document, media: const []));
  final restored = await database.loadBundle(document.id);
  expect(restored!.document.chapters.single.layout, GalleryLayout.storyPath);
});
```

- [ ] **Step 2: 运行测试并确认因枚举值缺失而失败**

Run: `flutter test test/data/gallery_database_test.dart`
Expected: FAIL，`GalleryLayout.storyPath` 未定义。

- [ ] **Step 3: 添加稳定枚举值与编辑器标签**

```dart
enum GalleryLayout { hero, filmstrip, diptych, collage, storyPath }
```

`_layoutLabel` 增加：

```dart
GalleryLayout.storyPath => '故事路径',
```

`LayoutResolver.resolve` 暂时把 `storyPath` 路由到独立 `_storyPath`，其节点按参考图使用交错矩形、旋转与深度。

- [ ] **Step 4: 验证数据兼容和布局测试**

Run: `flutter test test/data/gallery_database_test.dart test/layout/layout_resolver_test.dart`
Expected: PASS。

### Task 2: 尺寸映射真正影响所有模板

**Files:**
- Modify: `lib/layout/layout_resolver.dart`
- Test: `test/layout/layout_resolver_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
test('small medium and large change node area in every layout', () {
  for (final layout in GalleryLayout.values) {
    Rect rectFor(GallerySize size) => LayoutResolver.resolve(
      chapter: chapter(layout).copyWith(placements: [placements.first.copyWith(size: size)]),
      viewport: const Size(390, 844),
    ).nodes.single.rect;
    final small = rectFor(GallerySize.small);
    final medium = rectFor(GallerySize.medium);
    final large = rectFor(GallerySize.large);
    expect(small.width * small.height, lessThan(medium.width * medium.height));
    expect(medium.width * medium.height, lessThan(large.width * large.height));
  }
});
```

- [ ] **Step 2: 运行并确认固定矩形模板失败**

Run: `flutter test test/layout/layout_resolver_test.dart`
Expected: FAIL，至少 hero/diptych/collage 面积相同。

- [ ] **Step 3: 在节点创建时应用统一面积比例**

```dart
double _sizeScale(GallerySize size) => switch (size) {
  GallerySize.small => .76,
  GallerySize.medium => .88,
  GallerySize.large => 1,
};

Rect _scaleAroundCenter(Rect rect, GallerySize size) {
  final scale = _sizeScale(size);
  return Rect.fromCenter(
    center: rect.center,
    width: rect.width * scale,
    height: rect.height * scale,
  );
}
```

面积比例约为 `0.58 / 0.78 / 1.0`。

- [ ] **Step 4: 运行布局测试**

Run: `flutter test test/layout/layout_resolver_test.dart`
Expected: PASS。

### Task 3: 连续叙事轨道解析器

**Files:**
- Create: `lib/layout/narrative_track.dart`
- Create: `lib/layout/narrative_track_resolver.dart`
- Test: `test/layout/narrative_track_resolver_test.dart`

- [ ] **Step 1: 写关键帧失败测试**

```dart
test('three neighboring photos remain visible between focal points', () {
  final track = NarrativeTrackResolver.resolve(
    chapter: chapter(GalleryLayout.storyPath),
    viewport: const Size(390, 844),
  );
  final frame = track.resolve(.5);
  expect(frame.nodes.where((node) => node.opacity > .05), hasLength(greaterThanOrEqualTo(3)));
});
```

同时覆盖 `progress` 钳制、确定性、横竖屏顺序不变和首尾节点可聚焦。

- [ ] **Step 2: 运行并确认类型缺失**

Run: `flutter test test/layout/narrative_track_resolver_test.dart`
Expected: FAIL，轨道类型不存在。

- [ ] **Step 3: 定义纯数据模型**

```dart
class NarrativeTransform {
  const NarrativeTransform({required this.rect, required this.depth, required this.opacity, required this.rotation, required this.rotateY});
  final Rect rect;
  final double depth;
  final double opacity;
  final double rotation;
  final double rotateY;
}

class NarrativeKeyframe {
  const NarrativeKeyframe({required this.placementId, required this.focusProgress, required this.enter, required this.focus, required this.exit});
  final String placementId;
  final double focusProgress;
  final NarrativeTransform enter;
  final NarrativeTransform focus;
  final NarrativeTransform exit;
}
```

`ResolvedNarrativeTrack.resolve(progress)` 使用分段曲线在 enter→focus→exit 间插值；排序依据解析后的 `depth`。

- [ ] **Step 4: 实现模板密度与故事路径轨迹**

焦点间隔为 `1 / max(1, placements.length - 1)`；每张图在前后约 `1.35` 个间隔保持可见。`storyPath` 使用 S 型路径的交错焦点位置，其他模板从 `LayoutResolver` 的基础节点生成焦点变换。

- [ ] **Step 5: 运行轨道与布局测试**

Run: `flutter test test/layout/narrative_track_resolver_test.dart test/layout/layout_resolver_test.dart`
Expected: PASS。

### Task 4: 连续相机控制器与方向锁定

**Files:**
- Create: `lib/layout/narrative_camera_controller.dart`
- Modify: `lib/layout/gesture_direction_lock.dart`
- Test: `test/layout/narrative_camera_controller_test.dart`
- Test: `test/layout/gesture_direction_lock_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
test('horizontal drag changes progress continuously without snapping', () {
  final controller = NarrativeCameraController(initialProgress: .4);
  controller.begin(scale: 1);
  controller.update(delta: const Offset(-78, 2), viewport: const Size(390, 844), itemCount: 5);
  expect(controller.progress, closeTo(.45, .02));
  expect(controller.direction, GestureDirection.horizontal);
});
```

另测 `scale > 1.01` 时 progress 不变、8dp 前不锁方向、边界钳制和 `settleWithVelocity` 惯性衰减。

- [ ] **Step 2: 运行并确认控制器缺失**

Run: `flutter test test/layout/narrative_camera_controller_test.dart`
Expected: FAIL。

- [ ] **Step 3: 实现 ChangeNotifier 控制器**

```dart
class NarrativeCameraController extends ChangeNotifier {
  NarrativeCameraController({double initialProgress = 0}) : progress = initialProgress;
  double progress;
  GestureDirection direction = GestureDirection.pending;
  bool get navigationEnabled => scale <= 1.01;
  // begin/update/end/resetOverview；update 中按 -dx / viewport.width / dragSpan 更新 progress。
}
```

惯性使用 `FrictionSimulation` 驱动 `AnimationController.animateWith`，不做分页吸附。

- [ ] **Step 4: 运行相机测试**

Run: `flutter test test/layout/narrative_camera_controller_test.dart test/layout/gesture_direction_lock_test.dart`
Expected: PASS。

### Task 5: SceneCanvas 纯连续渲染与可区分画框

**Files:**
- Modify: `lib/widgets/scene_canvas.dart`
- Create: `lib/widgets/photo_frame.dart`
- Test: `test/widgets/scene_canvas_test.dart`
- Create: `test/widgets/photo_frame_test.dart`

- [ ] **Step 1: 写失败 Widget 测试**

```dart
testWidgets('camera progress changes node transforms continuously', (tester) async {
  await pumpScene(tester, cameraProgress: .25);
  final before = tester.widget<Transform>(find.byKey(const Key('scene-node-p1'))).transform;
  await pumpScene(tester, cameraProgress: .30);
  final after = tester.widget<Transform>(find.byKey(const Key('scene-node-p1'))).transform;
  expect(after, isNot(before));
});
```

画框测试断言 none/hairline/mat/stamp 分别出现 `frame-none`、`frame-hairline`、`frame-mat`、`frame-stamp`，邮票边包含 `CustomPaint`。

- [ ] **Step 2: 运行并确认失败**

Run: `flutter test test/widgets/scene_canvas_test.dart test/widgets/photo_frame_test.dart`
Expected: FAIL。

- [ ] **Step 3: 重构 SceneCanvas API**

```dart
const SceneCanvas({required this.chapter, required this.media, this.cameraProgress = 0, ...});
```

内部调用 `NarrativeTrackResolver.resolve(...).resolve(cameraProgress)`；删除旋转 placements 的 `focusIndex` 逻辑。

- [ ] **Step 4: 实现画框组件**

`mat` 使用外层米白相纸和更大的底部 padding；`stamp` 用 `_StampEdgePainter` 在独立外层绘制规则半圆齿孔；图片裁切只发生在内层，避免吃掉边框。

- [ ] **Step 5: 运行 Widget 测试**

Run: `flutter test test/widgets/scene_canvas_test.dart test/widgets/photo_frame_test.dart`
Expected: PASS。

### Task 6: 播放器改为手势直驱连续镜头

**Files:**
- Modify: `lib/screens/viewer_screen.dart`
- Test: `test/app/viewer_flow_test.dart`

- [ ] **Step 1: 更新失败测试**

```dart
testWidgets('horizontal drag advances the continuous story track', (tester) async {
  await pumpViewer(tester);
  expect(find.text('进度 0%'), findsOneWidget);
  await tester.drag(find.byKey(const Key('narrative-gesture-surface')), const Offset(-150, 0));
  await tester.pump();
  expect(find.text('进度 0%'), findsNothing);
});
```

保留显式上一项/下一项按钮，但按钮调用 `animateToNeighbor`；再测横竖屏变化后进度文本不回到 0%。

- [ ] **Step 2: 运行并确认旧离散行为失败**

Run: `flutter test test/app/viewer_flow_test.dart`
Expected: FAIL，仍显示离散 `1 / N` 且拖动只在结束时换图。

- [ ] **Step 3: 接入 NarrativeCameraController**

`_ViewerChapterState` 持有控制器；`onScaleStart/onScaleUpdate/onScaleEnd` 统一处理缩放和导航，1× 横向位移实时更新 progress，放大后交给 `TransformationController` 平移。`SceneCanvas.cameraProgress` 通过 `AnimatedBuilder` 读取。

- [ ] **Step 4: 保留章节纵向 PageView 与无障碍按钮**

横向方向锁定后禁止纵向章节 PageView 抢手势；上下章按钮继续存在。照片按钮按相邻焦点进度动画，不再修改 `focusIndex`。

- [ ] **Step 5: 运行播放器测试**

Run: `flutter test test/app/viewer_flow_test.dart`
Expected: PASS。

### Task 7: 横屏编辑器可滚动与实时预览

**Files:**
- Modify: `lib/screens/editor_screen.dart`
- Create: `test/app/editor_landscape_test.dart`

- [ ] **Step 1: 写失败横屏测试**

```dart
testWidgets('landscape inspector scrolls every control above system inset', (tester) async {
  await tester.binding.setSurfaceSize(const Size(844, 390));
  await pumpEditor(tester);
  expect(find.text('邮票边'), findsNothing);
  await tester.drag(find.byKey(const Key('editor-inspector-scroll')), const Offset(0, -260));
  await tester.pumpAndSettle();
  expect(find.text('邮票边'), findsOneWidget);
});
```

- [ ] **Step 2: 运行并确认当前可达性失败**

Run: `flutter test test/app/editor_landscape_test.dart`
Expected: FAIL。

- [ ] **Step 3: 修正布局约束**

右侧面板使用带 key 的 `SingleChildScrollView`、`SafeArea(top: false)` 和底部 `MediaQuery.viewPadding.bottom + 20`；宽度按 `clamp(280, 340)`，极窄高度下保持面板独立滚动。

- [ ] **Step 4: 让编辑预览共享连续轨道**

编辑器预览默认显示全景 progress 0；添加 0–100% 轨道滑杆，使设计者无需进入播放器即可检查连续效果。尺寸和画框选择后继续调用现有 session 自动保存并立即重建预览。

- [ ] **Step 5: 运行编辑器测试**

Run: `flutter test test/app/editor_landscape_test.dart test/editor/editor_session_test.dart`
Expected: PASS。

### Task 8: Golden、全量验证和视觉 QA

**Files:**
- Modify: `test/goldens/scene_templates_golden_test.dart`
- Create/Update: `test/goldens/storyPath_portrait_ink.png`
- Create/Update: `test/goldens/storyPath_landscape_paper.png`
- Create: `design-qa.md`

- [ ] **Step 1: 扩展 Golden 用例**

对五种模板至少验证 `0%、35%、70%` 的轨道状态；`storyPath` 额外验证全景与焦点状态。测试调用 `SceneCanvas(cameraProgress: progress)`。

- [ ] **Step 2: 生成并审阅 Golden**

Run: `flutter test --update-goldens test/goldens/scene_templates_golden_test.dart`
Expected: PASS，并生成第五种模板图片。

- [ ] **Step 3: 静态与全量测试**

Run: `dart format lib test`
Expected: 无格式错误。

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: 全部 PASS。

- [ ] **Step 4: 构建 Android 调试包**

Run: `flutter build apk --debug`
Expected: 生成 `build/app/outputs/flutter-apk/app-debug.apk`。

- [ ] **Step 5: 视觉对照 QA**

用同一竖屏视口打开主选参考图与故事路径实现截图，检查字体层级、空间节奏、色彩、图片裁切、画框和文案。将证据、修复记录和结论写入 `design-qa.md`；仅当无 P0/P1/P2 时写 `final result: passed`。

