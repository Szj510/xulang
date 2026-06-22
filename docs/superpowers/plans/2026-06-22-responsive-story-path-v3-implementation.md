# Responsive Story Path V3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the gallery path deterministic and ordered, use vertical reading in portrait and horizontal reading in landscape, hand chapters off only at gesture boundaries, and reclaim the full landscape editor height.

**Architecture:** Keep EditorSession and persisted gallery data unchanged. Add pure layout, geometry, camera, and navigation units under lib/layout; make ResolvedNarrativeFrame the rendering contract; then adapt SceneCanvas, the editor shell, and the viewer. Story-path nodes use one shared camera transform so their primary-axis order cannot reverse. Other templates retain their layout semantics while adopting orientation-aware camera input.

**Tech Stack:** Flutter 3.41.7, Dart 3.11.5, Riverpod, Drift/SQLite, Flutter unit/widget/golden tests, Android API 29–36.

---

## File map

- Create lib/layout/narrative_axis.dart for viewport-axis selection and primary/cross-axis math.
- Create lib/layout/story_path_geometry.dart for ordered anchors and non-reversing Bézier segments.
- Create lib/layout/narrative_navigation_coordinator.dart for boundary-handoff state.
- Modify lib/layout/layout_resolver.dart for monotonic story-path world layout.
- Modify lib/layout/narrative_track.dart and narrative_track_resolver.dart for shared-camera frames.
- Modify lib/layout/narrative_camera_controller.dart for active-axis input and inertia.
- Modify lib/widgets/scene_canvas.dart to render frame-derived path geometry.
- Modify lib/screens/editor_screen.dart for responsive chrome and direct preview gestures.
- Modify lib/screens/viewer_screen.dart to replace chapter PageView with coordinated pan handling.
- Add or modify focused tests under test/layout, test/widgets, test/app, and test/goldens.

## Task 1: Narrative axis and monotonic story layout

**Files:**
- Create: lib/layout/narrative_axis.dart
- Modify: lib/layout/layout_resolver.dart
- Create: test/layout/narrative_axis_test.dart
- Modify: test/layout/layout_resolver_test.dart

- [ ] **Step 1: Write failing axis tests**

Create test/layout/narrative_axis_test.dart:

~~~dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/layout/narrative_axis.dart';

void main() {
  test('selects axis from viewport orientation', () {
    expect(
      NarrativeAxis.fromViewport(const Size(390, 844)),
      NarrativeAxis.vertical,
    );
    expect(
      NarrativeAxis.fromViewport(const Size(844, 390)),
      NarrativeAxis.horizontal,
    );
  });

  test('reads and shifts the selected primary axis', () {
    expect(NarrativeAxis.vertical.primaryOffset(const Offset(4, 9)), 9);
    expect(NarrativeAxis.horizontal.primaryOffset(const Offset(4, 9)), 4);
    expect(
      NarrativeAxis.vertical.shiftPrimary(
        const Rect.fromLTWH(1, 2, 3, 4),
        8,
      ),
      const Rect.fromLTWH(1, 10, 3, 4),
    );
  });
}
~~~

Add this helper inside main() in test/layout/layout_resolver_test.dart, then add the two tests below it:

~~~dart
GalleryChapter chapterWithEightPlacements(GalleryLayout layout) =>
    GalleryChapter(
      id: 'chapter-eight',
      title: '八段旅程',
      order: 0,
      layout: layout,
      motion: GalleryMotion.push,
      placements: [
        for (var index = 0; index < 8; index++)
          GalleryPlacement(
            id: 'p$index',
            mediaId: 'm$index',
            order: index,
            size: GallerySize.values[index % GallerySize.values.length],
          ),
      ],
    );
~~~

~~~dart
test('portrait story nodes advance down with a 24dp gap', () {
  final scene = LayoutResolver.resolve(
    chapter: chapterWithEightPlacements(GalleryLayout.storyPath),
    viewport: const Size(390, 844),
  );
  expect(scene.primaryAxis, Axis.vertical);
  for (var index = 1; index < scene.nodes.length; index++) {
    expect(
      scene.nodes[index].rect.top - scene.nodes[index - 1].rect.bottom,
      greaterThanOrEqualTo(24),
    );
  }
  expect(scene.contentExtent, greaterThan(844));
});

test('landscape story nodes advance right with a 24dp gap', () {
  final scene = LayoutResolver.resolve(
    chapter: chapterWithEightPlacements(GalleryLayout.storyPath),
    viewport: const Size(844, 390),
  );
  expect(scene.primaryAxis, Axis.horizontal);
  for (var index = 1; index < scene.nodes.length; index++) {
    expect(
      scene.nodes[index].rect.left - scene.nodes[index - 1].rect.right,
      greaterThanOrEqualTo(24),
    );
  }
  expect(scene.contentExtent, greaterThan(844));
});

test('zero viewport returns a stable empty story scene', () {
  final scene = LayoutResolver.resolve(
    chapter: chapterWithEightPlacements(GalleryLayout.storyPath),
    viewport: Size.zero,
  );
  expect(scene.nodes, isEmpty);
  expect(scene.contentExtent, 0);
});
~~~

- [ ] **Step 2: Run the tests and confirm the expected failure**

~~~powershell
flutter test test/layout/narrative_axis_test.dart test/layout/layout_resolver_test.dart
~~~

Expected: FAIL because narrative_axis.dart is absent and the current portrait story path reports Axis.horizontal with repeated overlapping rectangles.

- [ ] **Step 3: Implement axis math**

Create lib/layout/narrative_axis.dart:

~~~dart
import 'dart:ui';

enum NarrativeAxis {
  vertical,
  horizontal;

  factory NarrativeAxis.fromViewport(Size viewport) =>
      viewport.height >= viewport.width ? vertical : horizontal;

  double primaryOffset(Offset value) =>
      this == vertical ? value.dy : value.dx;

  double crossOffset(Offset value) =>
      this == vertical ? value.dx : value.dy;

  double primaryExtent(Size value) =>
      this == vertical ? value.height : value.width;

  double crossExtent(Size value) =>
      this == vertical ? value.width : value.height;

  Rect shiftPrimary(Rect rect, double delta) => this == vertical
      ? rect.shift(Offset(0, delta))
      : rect.shift(Offset(delta, 0));
}
~~~

- [ ] **Step 4: Replace LayoutResolver._storyPath with a cursor layout**

Add dart:math as math and implement this algorithm:

~~~dart
static ResolvedScene _storyPath(List<GalleryPlacement> items, Size size) {
  final portrait = size.height >= size.width;
  if (!size.width.isFinite ||
      !size.height.isFinite ||
      size.width <= 0 ||
      size.height <= 0) {
    return ResolvedScene(
      nodes: const [],
      primaryAxis: portrait ? Axis.vertical : Axis.horizontal,
      contentExtent: 0,
    );
  }
  final primarySize = portrait ? size.height : size.width;
  final crossFractions = portrait
      ? const [.35, .64, .40, .68]
      : const [.37, .62, .43, .66];
  final nodes = <SceneNode>[];
  var cursor = primarySize * .10;

  for (var index = 0; index < items.length; index++) {
    final scale = _sizeScale(items[index].size);
    final width = portrait
        ? size.width * .58 * scale
        : size.width * .34 * scale;
    final height = portrait
        ? size.height * .29 * scale
        : size.height * .64 * scale;
    final crossCenter = portrait
        ? size.width * crossFractions[index % 4]
        : size.height * crossFractions[index % 4];
    final rect = portrait
        ? Rect.fromLTWH(
            (crossCenter - width / 2).clamp(8, size.width - width - 8),
            cursor,
            width,
            height,
          )
        : Rect.fromLTWH(
            cursor,
            (crossCenter - height / 2).clamp(8, size.height - height - 8),
            width,
            height,
          );
    nodes.add(
      SceneNode(
        placementId: items[index].id,
        rect: rect,
        depth: const [.42, 1.0, .72, .56][index % 4],
        rotation: const [-.035, .022, -.018, .038][index % 4],
      ),
    );
    cursor = (portrait ? rect.bottom : rect.right) + 24;
  }

  return ResolvedScene(
    nodes: nodes,
    primaryAxis: portrait ? Axis.vertical : Axis.horizontal,
    contentExtent: items.isEmpty
        ? primarySize
        : math.max(primarySize, cursor + primarySize * .10),
  );
}
~~~

- [ ] **Step 5: Run focused tests and commit**

~~~powershell
flutter test test/layout/narrative_axis_test.dart test/layout/layout_resolver_test.dart
git add lib/layout/narrative_axis.dart lib/layout/layout_resolver.dart test/layout/narrative_axis_test.dart test/layout/layout_resolver_test.dart
git commit -m "feat: order story layout by orientation"
~~~

Expected: all focused tests PASS.

## Task 2: Shared camera and non-crossing path geometry

**Files:**
- Create: lib/layout/story_path_geometry.dart
- Modify: lib/layout/narrative_track.dart
- Modify: lib/layout/narrative_track_resolver.dart
- Create: test/layout/story_path_geometry_test.dart
- Modify: test/layout/narrative_track_resolver_test.dart

- [ ] **Step 1: Write failing path geometry tests**

Create test/layout/story_path_geometry_test.dart:

~~~dart
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/layout/narrative_axis.dart';
import 'package:xulang/layout/story_path_geometry.dart';

void main() {
  test('vertical controls remain in each ordered interval', () {
    final geometry = StoryPathGeometry.resolve(
      axis: NarrativeAxis.vertical,
      viewport: const Size(390, 844),
      nodes: const [
        StoryPathNodeInput('a', Rect.fromLTWH(20, 40, 160, 180), 1),
        StoryPathNodeInput('b', Rect.fromLTWH(200, 260, 160, 180), 1),
        StoryPathNodeInput('c', Rect.fromLTWH(30, 480, 160, 180), 1),
      ],
    );
    expect(
      geometry.anchors.map((anchor) => anchor.placementId),
      ['a', 'b', 'c'],
    );
    for (final segment in geometry.segments) {
      expect(
        segment.control1.dy,
        inInclusiveRange(segment.start.dy, segment.end.dy),
      );
      expect(
        segment.control2.dy,
        inInclusiveRange(segment.start.dy, segment.end.dy),
      );
    }
  });

  test('horizontal controls remain in each ordered interval', () {
    final geometry = StoryPathGeometry.resolve(
      axis: NarrativeAxis.horizontal,
      viewport: const Size(844, 390),
      nodes: const [
        StoryPathNodeInput('a', Rect.fromLTWH(40, 30, 180, 160), 1),
        StoryPathNodeInput('b', Rect.fromLTWH(260, 190, 180, 160), 1),
        StoryPathNodeInput('c', Rect.fromLTWH(480, 40, 180, 160), 1),
      ],
    );
    for (final segment in geometry.segments) {
      expect(
        segment.control1.dx,
        inInclusiveRange(segment.start.dx, segment.end.dx),
      );
      expect(
        segment.control2.dx,
        inInclusiveRange(segment.start.dx, segment.end.dx),
      );
    }
  });
}
~~~

Add to test/layout/narrative_track_resolver_test.dart:

~~~dart
test('story nodes retain primary order at every camera progress', () {
  for (final viewport in const [Size(390, 844), Size(844, 390)]) {
    final track = NarrativeTrackResolver.resolve(
      chapter: chapter(GalleryLayout.storyPath),
      viewport: viewport,
    );
    for (final progress in const [0.0, .2, .5, .8, 1.0]) {
      final frame = track.resolve(progress);
      final values = frame.axis == NarrativeAxis.vertical
          ? frame.nodes.map((node) => node.rect.center.dy).toList()
          : frame.nodes.map((node) => node.rect.center.dx).toList();
      expect(values, orderedEquals([...values]..sort()));
    }
  }
});
~~~

- [ ] **Step 2: Run and confirm failure**

~~~powershell
flutter test test/layout/story_path_geometry_test.dart test/layout/narrative_track_resolver_test.dart
~~~

Expected: FAIL because geometry, frame axis, and shared-camera behavior do not exist.

- [ ] **Step 3: Implement immutable path geometry**

Create lib/layout/story_path_geometry.dart:

~~~dart
import 'dart:ui';
import 'package:xulang/layout/narrative_axis.dart';

class StoryPathNodeInput {
  const StoryPathNodeInput(this.placementId, this.rect, this.opacity);
  final String placementId;
  final Rect rect;
  final double opacity;
}

class StoryPathAnchor {
  const StoryPathAnchor(this.placementId, this.point, this.nodeRect);
  final String placementId;
  final Offset point;
  final Rect nodeRect;
}

class StoryPathSegment {
  const StoryPathSegment(this.start, this.control1, this.control2, this.end);
  final Offset start;
  final Offset control1;
  final Offset control2;
  final Offset end;
}

class StoryPathGeometry {
  const StoryPathGeometry({required this.anchors, required this.segments});

  final List<StoryPathAnchor> anchors;
  final List<StoryPathSegment> segments;

  static const empty = StoryPathGeometry(anchors: [], segments: []);

  static StoryPathGeometry resolve({
    required NarrativeAxis axis,
    required Size viewport,
    required List<StoryPathNodeInput> nodes,
  }) {
    final bounds = Offset.zero & viewport;
    final visible = nodes
        .where(
          (node) =>
              node.opacity > .05 && node.rect.overlaps(bounds.inflate(96)),
        )
        .toList(growable: false);
    final anchors = <StoryPathAnchor>[
      for (var index = 0; index < visible.length; index++)
        StoryPathAnchor(
          visible[index].placementId,
          _anchor(axis, visible[index].rect, index),
          visible[index].rect,
        ),
    ];
    final segments = <StoryPathSegment>[];
    for (var index = 1; index < anchors.length; index++) {
      final start = anchors[index - 1].point;
      final end = anchors[index].point;
      final primaryStart = axis.primaryOffset(start);
      final primaryEnd = axis.primaryOffset(end);
      final crossStart = axis.crossOffset(start);
      final crossEnd = axis.crossOffset(end);
      segments.add(
        StoryPathSegment(
          start,
          _offset(
            axis,
            primaryStart + (primaryEnd - primaryStart) / 3,
            crossStart,
          ),
          _offset(
            axis,
            primaryStart + (primaryEnd - primaryStart) * 2 / 3,
            crossEnd,
          ),
          end,
        ),
      );
    }
    return StoryPathGeometry(anchors: anchors, segments: segments);
  }

  static Offset _anchor(NarrativeAxis axis, Rect rect, int index) {
    if (axis == NarrativeAxis.vertical) {
      return Offset(
        index.isEven ? rect.right + 10 : rect.left - 10,
        rect.bottom + 8,
      );
    }
    return Offset(
      rect.right + 8,
      index.isEven ? rect.bottom + 10 : rect.top - 10,
    );
  }

  static Offset _offset(
    NarrativeAxis axis,
    double primary,
    double cross,
  ) =>
      axis == NarrativeAxis.vertical
          ? Offset(cross, primary)
          : Offset(primary, cross);
}
~~~

- [ ] **Step 4: Add a shared-camera branch to ResolvedNarrativeTrack**

Import dart:math as math, narrative_axis.dart, and story_path_geometry.dart. Add axis and path to ResolvedNarrativeFrame. Add axis, viewport, contentExtent, and sharedCamera to ResolvedNarrativeTrack. Preserve the existing interpolation branch for non-story templates. Add this helper beside _lerpDouble:

Use these constructor and field signatures while retaining the existing resolve and equality methods around them:

~~~dart
class ResolvedNarrativeFrame {
  const ResolvedNarrativeFrame({
    required this.progress,
    required this.axis,
    required this.nodes,
    required this.path,
  });

  final double progress;
  final NarrativeAxis axis;
  final List<NarrativeNodeFrame> nodes;
  final StoryPathGeometry path;
}

class ResolvedNarrativeTrack {
  const ResolvedNarrativeTrack({
    required this.keyframes,
    required this.visibilityWindow,
    required this.axis,
    required this.viewport,
    required this.contentExtent,
    required this.sharedCamera,
  });

  final List<NarrativeKeyframe> keyframes;
  final double visibilityWindow;
  final NarrativeAxis axis;
  final Size viewport;
  final double contentExtent;
  final bool sharedCamera;
}
~~~

Update ResolvedNarrativeFrame equality and hashCode to include axis and path. Add value equality and hashCode to StoryPathAnchor, StoryPathSegment, and StoryPathGeometry so frame determinism and CustomPainter repaint decisions compare values rather than list identity.

Add this helper beside _lerpDouble:

~~~dart
Rect _scaled(Rect rect, double scale) => Rect.fromCenter(
  center: rect.center,
  width: rect.width * scale,
  height: rect.height * scale,
);
~~~

For the shared branch, shift every keyframe focus rectangle by the same camera amount and derive depth from distance to the viewport center:

~~~dart
ResolvedNarrativeFrame _resolveSharedCamera(double progress) {
  final travel =
      math.max(0.0, contentExtent - axis.primaryExtent(viewport));
  final camera = travel * progress;
  final primaryExtent = axis.primaryExtent(viewport);
  final center = primaryExtent / 2;
  final nodes = <NarrativeNodeFrame>[
    for (final keyframe in keyframes)
      _sharedNode(keyframe, camera, center, primaryExtent),
  ];
  return ResolvedNarrativeFrame(
    progress: progress,
    axis: axis,
    nodes: nodes,
    path: StoryPathGeometry.resolve(
      axis: axis,
      viewport: viewport,
      nodes: [
        for (final node in nodes)
          StoryPathNodeInput(node.placementId, node.rect, node.opacity),
      ],
    ),
  );
}

NarrativeNodeFrame _sharedNode(
  NarrativeKeyframe keyframe,
  double camera,
  double viewportCenter,
  double viewportPrimary,
) {
  final shifted = axis.shiftPrimary(keyframe.focus.rect, -camera);
  final nodeCenter = axis == NarrativeAxis.vertical
      ? shifted.center.dy
      : shifted.center.dx;
  final distance =
      ((nodeCenter - viewportCenter).abs() / (viewportPrimary * .72))
          .clamp(0.0, 1.0);
  final focus = 1 - distance;
  return NarrativeNodeFrame(
    placementId: keyframe.placementId,
    rect: _scaled(shifted, .88 + focus * .12),
    depth: .18 + focus * .82,
    opacity: .12 + focus * .88,
    rotation: keyframe.focus.rotation * (.72 + focus * .28),
    rotateY: (1 - focus) * .10,
  );
}
~~~

In NarrativeTrackResolver.resolve, always choose NarrativeAxis.fromViewport(viewport). Set sharedCamera true and pass scene.contentExtent only for GalleryLayout.storyPath. For that branch, use the SceneNode world rectangle as keyframe.focus.rect; enter and exit can equal focus because the shared branch does not consume them. Keep the current keyframes for other layouts and return StoryPathGeometry.empty from their frames.

- [ ] **Step 5: Run tests and commit**

~~~powershell
flutter test test/layout/story_path_geometry_test.dart test/layout/narrative_track_resolver_test.dart test/layout/layout_resolver_test.dart
git add lib/layout/story_path_geometry.dart lib/layout/narrative_track.dart lib/layout/narrative_track_resolver.dart test/layout/story_path_geometry_test.dart test/layout/narrative_track_resolver_test.dart
git commit -m "feat: resolve ordered story camera path"
~~~

Expected: all focused tests PASS and placement order is stable at 0%, 20%, 50%, 80%, and 100%.

## Task 3: Orientation-aware camera controller

**Files:**
- Modify: lib/layout/narrative_camera_controller.dart
- Modify: test/layout/narrative_camera_controller_test.dart

- [ ] **Step 1: Write failing portrait and landscape camera tests**

Add NarrativeAxis to every controller call and add these cases:

~~~dart
test('portrait vertical drag advances progress', () {
  final controller = NarrativeCameraController(initialProgress: .4);
  controller.begin(scale: 1);
  controller.update(
    delta: const Offset(2, -84),
    viewport: const Size(390, 840),
    itemCount: 5,
    scale: 1,
    axis: NarrativeAxis.vertical,
  );
  expect(controller.progress, closeTo(.425, .001));
  expect(controller.direction, GalleryGesture.vertical);
});

test('landscape horizontal drag advances progress', () {
  final controller = NarrativeCameraController(initialProgress: .4);
  controller.begin(scale: 1);
  controller.update(
    delta: const Offset(-84, 2),
    viewport: const Size(840, 390),
    itemCount: 5,
    scale: 1,
    axis: NarrativeAxis.horizontal,
  );
  expect(controller.progress, closeTo(.425, .001));
});
~~~

Change the inertia test to pass viewport and axis instead of viewportWidth.

- [ ] **Step 2: Run and confirm failure**

~~~powershell
flutter test test/layout/narrative_camera_controller_test.dart
~~~

Expected: FAIL because update and simulationForVelocity do not accept axis.

- [ ] **Step 3: Implement primary-axis input and inertia**

Inside update, after direction lock:

~~~dart
final expectedGesture = axis == NarrativeAxis.vertical
    ? GalleryGesture.vertical
    : GalleryGesture.horizontal;
if (gesture != expectedGesture) return gesture;
final extent = axis.primaryExtent(viewport);
if (extent <= 0) return gesture;
final dragSpan = math.max(1, itemCount - 1).toDouble();
setProgress(
  progress - axis.primaryOffset(delta) / extent / dragSpan,
);
~~~

Change simulationForVelocity to accept Size viewport and NarrativeAxis axis, and divide velocity by axis.primaryExtent(viewport). Keep zoom priority and clamping unchanged.

- [ ] **Step 4: Run tests and commit**

~~~powershell
flutter test test/layout/narrative_camera_controller_test.dart test/layout/gesture_direction_lock_test.dart
git add lib/layout/narrative_camera_controller.dart test/layout/narrative_camera_controller_test.dart
git commit -m "feat: drive camera on responsive axis"
~~~

Expected: camera and direction-lock tests PASS.

## Task 4: Boundary-handoff coordinator

**Files:**
- Create: lib/layout/narrative_navigation_coordinator.dart
- Create: test/layout/narrative_navigation_coordinator_test.dart

- [ ] **Step 1: Write failing state-machine tests**

Create test/layout/narrative_navigation_coordinator_test.dart:

~~~dart
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/layout/gesture_direction_lock.dart';
import 'package:xulang/layout/narrative_axis.dart';
import 'package:xulang/layout/narrative_navigation_coordinator.dart';

void main() {
  test('gesture that reaches the end does not switch', () {
    final coordinator = NarrativeNavigationCoordinator();
    coordinator.begin(
      progress: .8,
      axis: NarrativeAxis.vertical,
      itemCount: 4,
    );
    expect(
      coordinator.update(const Offset(0, -90), GalleryGesture.vertical),
      ChapterNavigationIntent.none,
    );
  });

  test('new forward gesture at the end switches once after 56dp', () {
    final coordinator = NarrativeNavigationCoordinator();
    coordinator.begin(
      progress: 1,
      axis: NarrativeAxis.vertical,
      itemCount: 4,
    );
    expect(
      coordinator.update(const Offset(0, -40), GalleryGesture.vertical),
      ChapterNavigationIntent.none,
    );
    expect(
      coordinator.update(const Offset(0, -20), GalleryGesture.vertical),
      ChapterNavigationIntent.next,
    );
    expect(
      coordinator.update(const Offset(0, -80), GalleryGesture.vertical),
      ChapterNavigationIntent.none,
    );
  });

  test('new reverse gesture at the start returns', () {
    final coordinator = NarrativeNavigationCoordinator();
    coordinator.begin(
      progress: 0,
      axis: NarrativeAxis.vertical,
      itemCount: 4,
    );
    expect(
      coordinator.update(const Offset(0, 60), GalleryGesture.vertical),
      ChapterNavigationIntent.previous,
    );
  });

  test('landscape vertical gesture switches at any track progress', () {
    final coordinator = NarrativeNavigationCoordinator();
    coordinator.begin(
      progress: .4,
      axis: NarrativeAxis.horizontal,
      itemCount: 4,
    );
    expect(
      coordinator.update(const Offset(2, -60), GalleryGesture.vertical),
      ChapterNavigationIntent.next,
    );
  });

  test('single image is armed at both boundaries', () {
    final coordinator = NarrativeNavigationCoordinator();
    coordinator.begin(
      progress: 0,
      axis: NarrativeAxis.vertical,
      itemCount: 1,
    );
    expect(
      coordinator.update(const Offset(0, -60), GalleryGesture.vertical),
      ChapterNavigationIntent.next,
    );
  });
}
~~~

- [ ] **Step 2: Run and confirm failure**

~~~powershell
flutter test test/layout/narrative_navigation_coordinator_test.dart
~~~

Expected: FAIL because the coordinator does not exist.

- [ ] **Step 3: Implement the pure coordinator**

Create lib/layout/narrative_navigation_coordinator.dart:

~~~dart
import 'dart:ui';
import 'package:xulang/layout/gesture_direction_lock.dart';
import 'package:xulang/layout/narrative_axis.dart';

enum ChapterNavigationIntent { none, previous, next }

class NarrativeNavigationCoordinator {
  static const threshold = 56.0;

  NarrativeAxis _axis = NarrativeAxis.horizontal;
  bool _startedAtStart = false;
  bool _startedAtEnd = false;
  bool _dispatched = false;
  double _primary = 0;
  double _cross = 0;

  void begin({
    required double progress,
    required NarrativeAxis axis,
    required int itemCount,
  }) {
    _axis = axis;
    _startedAtStart = itemCount <= 1 || progress <= .001;
    _startedAtEnd = itemCount <= 1 || progress >= .999;
    _dispatched = false;
    _primary = 0;
    _cross = 0;
  }

  ChapterNavigationIntent update(
    Offset delta,
    GalleryGesture gesture,
  ) {
    if (_dispatched) return ChapterNavigationIntent.none;
    _primary += _axis.primaryOffset(delta);
    _cross += _axis.crossOffset(delta);

    if (_axis == NarrativeAxis.horizontal &&
        gesture == GalleryGesture.vertical) {
      return _dispatchCross();
    }
    final expected = _axis == NarrativeAxis.vertical
        ? GalleryGesture.vertical
        : GalleryGesture.horizontal;
    if (gesture != expected) return ChapterNavigationIntent.none;
    if (_startedAtEnd && _primary <= -threshold) {
      _dispatched = true;
      return ChapterNavigationIntent.next;
    }
    if (_startedAtStart && _primary >= threshold) {
      _dispatched = true;
      return ChapterNavigationIntent.previous;
    }
    return ChapterNavigationIntent.none;
  }

  ChapterNavigationIntent _dispatchCross() {
    if (_cross <= -threshold) {
      _dispatched = true;
      return ChapterNavigationIntent.next;
    }
    if (_cross >= threshold) {
      _dispatched = true;
      return ChapterNavigationIntent.previous;
    }
    return ChapterNavigationIntent.none;
  }

  void end() {
    _primary = 0;
    _cross = 0;
  }
}
~~~

- [ ] **Step 4: Run tests and commit**

~~~powershell
flutter test test/layout/narrative_navigation_coordinator_test.dart
git add lib/layout/narrative_navigation_coordinator.dart test/layout/narrative_navigation_coordinator_test.dart
git commit -m "feat: coordinate chapter boundary handoff"
~~~

Expected: all state-machine tests PASS.

## Task 5: Render frame-derived path geometry

**Files:**
- Modify: lib/widgets/scene_canvas.dart
- Modify: test/widgets/scene_canvas_test.dart

- [ ] **Step 1: Write a failing painter contract test**

Add this test to test/widgets/scene_canvas_test.dart. Reuse the existing media fixture; every placement may reference the same media because this test verifies geometry rather than asset identity:

~~~dart
testWidgets('story painter receives ordered resolved geometry', (tester) async {
  final storyChapter = chapter.copyWith(
    layout: GalleryLayout.storyPath,
    placements: const [
      GalleryPlacement(id: 'p1', mediaId: 'media', order: 0),
      GalleryPlacement(id: 'p2', mediaId: 'media', order: 1),
      GalleryPlacement(id: 'p3', mediaId: 'media', order: 2),
      GalleryPlacement(id: 'p4', mediaId: 'media', order: 3),
    ],
  );
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 390,
        height: 844,
        child: SceneCanvas(
          chapter: storyChapter,
          media: const [media],
          cameraProgress: .35,
        ),
      ),
    ),
  );

  final paint = tester.widget<CustomPaint>(
    find.byKey(const Key('story-path-line')),
  );
  final painter = paint.painter! as StoryPathPainter;
  expect(painter.geometry.segments, isNotEmpty);
  final order = {'p1': 0, 'p2': 1, 'p3': 2, 'p4': 3};
  final indices = painter.geometry.anchors
      .map((anchor) => order[anchor.placementId]!)
      .toList();
  expect(indices, orderedEquals([...indices]..sort()));
});
~~~

- [ ] **Step 2: Run and confirm failure**

~~~powershell
flutter test test/widgets/scene_canvas_test.dart
~~~

Expected: FAIL because the current private painter receives only theme and draws a fixed S curve.

- [ ] **Step 3: Replace the fixed painter**

Pass frame.path into a public StoryPathPainter and draw every resolved cubic segment:

~~~dart
class StoryPathPainter extends CustomPainter {
  StoryPathPainter({
    required this.sceneTheme,
    required this.geometry,
  });

  final GalleryTheme sceneTheme;
  final StoryPathGeometry geometry;

  @override
  void paint(Canvas canvas, Size size) {
    final color = (sceneTheme == GalleryTheme.paper
            ? XulangColors.ink
            : XulangColors.paper)
        .withValues(alpha: .20);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final segment in geometry.segments) {
      final path = Path()
        ..moveTo(segment.start.dx, segment.start.dy)
        ..cubicTo(
          segment.control1.dx,
          segment.control1.dy,
          segment.control2.dx,
          segment.control2.dy,
          segment.end.dx,
          segment.end.dy,
        );
      canvas.drawPath(path, stroke);
    }
    final dot = Paint()..color = color.withValues(alpha: .85);
    for (final anchor in geometry.anchors) {
      canvas.drawCircle(anchor.point, 3.2, dot);
    }
  }

  @override
  bool shouldRepaint(covariant StoryPathPainter oldDelegate) =>
      sceneTheme != oldDelegate.sceneTheme ||
      geometry != oldDelegate.geometry;
}
~~~

Build a placement-to-anchor map from frame.path.anchors:

~~~dart
final anchorsByPlacement = {
  for (final anchor in frame.path.anchors) anchor.placementId: anchor,
};
~~~

Change _StoryNodeLabel to receive StoryPathAnchor. Start with a 92×30 label rectangle beside anchor.point, flip its horizontal side when that rectangle overlaps anchor.nodeRect, then clamp left to 8..viewport.width-100 and top to 8..viewport.height-38. Skip labels without a visible anchor. Keep CustomPaint before every photo in the Stack.

~~~dart
Rect _labelRect(StoryPathAnchor anchor, Size viewport) {
  const labelSize = Size(92, 30);
  var left = anchor.point.dx + 8;
  var top = anchor.point.dy - labelSize.height / 2;
  var rect = Offset(left, top) & labelSize;
  if (rect.overlaps(anchor.nodeRect)) {
    left = anchor.point.dx - labelSize.width - 8;
    rect = Offset(left, top) & labelSize;
  }
  return Rect.fromLTWH(
    rect.left.clamp(8, viewport.width - labelSize.width - 8),
    rect.top.clamp(8, viewport.height - labelSize.height - 8),
    labelSize.width,
    labelSize.height,
  );
}
~~~

- [ ] **Step 4: Run tests and commit**

~~~powershell
flutter test test/widgets/scene_canvas_test.dart test/widgets/photo_frame_test.dart
git add lib/widgets/scene_canvas.dart test/widgets/scene_canvas_test.dart
git commit -m "feat: draw story path from scene geometry"
~~~

Expected: canvas and frame tests PASS; no fixed percentage path remains.

## Task 6: Responsive editor chrome and preview axis

**Files:**
- Modify: lib/screens/editor_screen.dart
- Modify: test/app/editor_landscape_test.dart

- [ ] **Step 1: Write failing responsive shell tests**

Change pumpEditor to accept a required Size and call setSurfaceSize(size). Keep the existing inspector test at Size(844, 390), then add:

~~~dart
testWidgets('landscape hides persistent chrome and opens chapter overlay', (
  tester,
) async {
  await pumpEditor(tester, const Size(844, 390));
  expect(find.byKey(const Key('editor-app-bar')), findsNothing);
  expect(find.byKey(const Key('editor-chapter-rail')), findsNothing);
  expect(find.byKey(const Key('landscape-editor-toolbar')), findsOneWidget);

  await tester.tap(find.byTooltip('章节'));
  await tester.pumpAndSettle();
  expect(
    find.byKey(const Key('landscape-chapter-overlay')),
    findsOneWidget,
  );
});

testWidgets('portrait restores chrome and advances preview vertically', (
  tester,
) async {
  await pumpEditor(tester, const Size(390, 844));
  expect(find.byKey(const Key('editor-app-bar')), findsOneWidget);
  expect(find.byKey(const Key('editor-chapter-rail')), findsOneWidget);
  expect(find.byKey(const Key('editor-vertical-progress')), findsOneWidget);

  final before = tester
      .widget<Text>(find.byKey(const Key('editor-camera-progress')))
      .data;
  await tester.drag(
    find.byKey(const Key('editor-preview-gesture-surface')),
    const Offset(0, -160),
  );
  await tester.pump();
  final after = tester
      .widget<Text>(find.byKey(const Key('editor-camera-progress')))
      .data;
  expect(after, isNot(before));
});
~~~

- [ ] **Step 2: Run and confirm failure**

~~~powershell
flutter test test/app/editor_landscape_test.dart
~~~

Expected: FAIL because persistent chrome and horizontal-only preview are still present.

- [ ] **Step 3: Implement separate portrait and landscape shells**

Compute orientation before constructing Scaffold. Use appBar: null in landscape and the existing AppBar, keyed editor-app-bar, in portrait. Key the portrait ChapterRail editor-chapter-rail.

~~~dart
final size = MediaQuery.sizeOf(context);
final landscape = size.width > size.height;
return Scaffold(
  appBar: landscape ? null : _buildAppBar(context),
  body: LayoutBuilder(
    builder: (context, constraints) => landscape
        ? _LandscapeEditorBody(session: session)
        : Column(
            children: [
              _ChapterRail(
                key: const Key('editor-chapter-rail'),
                session: session,
              ),
              Expanded(child: _Preview(session: session)),
              SizedBox(height: 214, child: _Inspector(session: session)),
            ],
          ),
  ),
);
~~~

For landscape, render only the preview/inspector Row in normal layout. Add a Stack overlay containing:
- a 48dp back target at top-left;
- a top-right toolbar keyed landscape-editor-toolbar with 48dp targets for 章节, 撤销, 重做, and 播放;
- a chapter overlay keyed landscape-chapter-overlay with maximum height 64dp.

The overlay calls the existing rename, add, reorder, select, undo, redo, and play operations. Selecting a chapter or tapping the canvas closes it. It overlays the canvas and never changes Row height.

- [ ] **Step 4: Implement per-chapter preview progress and direct pan**

Replace the single preview progress double with Map<String, double>. Wrap SceneCanvas in GestureDetector keyed editor-preview-gesture-surface. Use NarrativeCameraController and NarrativeAxis.fromViewport for onPanStart, onPanUpdate, and onPanEnd.

~~~dart
final Map<String, double> _progressByChapter = {};
final NarrativeCameraController _camera = NarrativeCameraController();

double get _progress =>
    _progressByChapter[session.selectedChapter!.id] ?? 0;

void _setProgress(double value) {
  _progressByChapter[session.selectedChapter!.id] = value.clamp(0, 1);
  _camera.setProgress(value);
  setState(() {});
}

void _beginPreview(PanStartDetails details) {
  _camera.setProgress(_progress);
  _camera.begin(scale: 1);
}

void _updatePreview(PanUpdateDetails details, Size viewport) {
  _camera.update(
    delta: details.delta,
    viewport: viewport,
    itemCount: session.selectedChapter!.placements.length,
    scale: 1,
    axis: NarrativeAxis.fromViewport(viewport),
  );
  _progressByChapter[session.selectedChapter!.id] = _camera.progress;
}
~~~

Render a right-side RotatedBox Slider keyed editor-vertical-progress in portrait and the existing bottom Slider keyed editor-horizontal-progress in landscape. Give the percentage label key editor-camera-progress. Both direct pan and sliders update the same map entry.

- [ ] **Step 5: Run tests and commit**

~~~powershell
flutter test test/app/editor_landscape_test.dart test/editor/editor_session_test.dart
git add lib/screens/editor_screen.dart test/app/editor_landscape_test.dart
git commit -m "feat: adapt editor chrome and preview axis"
~~~

Expected: responsive editor, inspector reachability, and session tests PASS.

## Task 7: Unified viewer gestures and chapter handoff

**Files:**
- Modify: lib/screens/viewer_screen.dart
- Modify: test/app/viewer_flow_test.dart

- [ ] **Step 1: Write failing viewer flows**

Replace the horizontal-only flow with these two tests. Keep the orientation test, but advance portrait progress vertically before rotating:

~~~dart
testWidgets('portrait needs a new boundary gesture to change chapter', (
  tester,
) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await pumpViewer(tester);

  final surface = find.byKey(const Key('narrative-gesture-surface'));
  await tester.drag(surface, const Offset(0, -700));
  await tester.pumpAndSettle();
  await tester.drag(surface, const Offset(0, -700));
  await tester.pumpAndSettle();
  expect(find.textContaining('潮汐的方向'), findsOneWidget);

  await tester.drag(surface, const Offset(0, -80));
  await tester.pumpAndSettle();
  expect(find.textContaining('夏日散步'), findsOneWidget);
});

testWidgets('landscape separates track and chapter axes', (tester) async {
  await tester.binding.setSurfaceSize(const Size(844, 390));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await pumpViewer(tester);

  final surface = find.byKey(const Key('narrative-gesture-surface'));
  await tester.drag(surface, const Offset(-200, 0));
  await tester.pump();
  expect(find.text('进度 0%'), findsNothing);

  await tester.drag(surface, const Offset(0, -80));
  await tester.pumpAndSettle();
  expect(find.textContaining('夏日散步'), findsOneWidget);
});
~~~

- [ ] **Step 2: Run and confirm failure**

~~~powershell
flutter test test/app/viewer_flow_test.dart
~~~

Expected: FAIL because PageView consumes portrait drags and ViewerChapter handles only horizontal drag callbacks.

- [ ] **Step 3: Replace PageView with explicit chapter state**

Remove PageController. Keep chapterIndex, add Map<String, double> chapterProgress and a changingChapter guard. Build only the selected ViewerChapter inside AnimatedSwitcher. Use 240ms normally and 120ms when animations are disabled.

Do not filter empty chapters from the list. Show the import message only if every chapter is empty. Pass initial progress, neighbor availability, onProgressChanged, and onChapterIntent into ViewerChapter.

Use one method for gesture and button chapter changes:

~~~dart
Future<void> _changeChapter(
  List<GalleryChapter> chapters,
  ChapterNavigationIntent intent,
) async {
  if (_changingChapter ||
      intent == ChapterNavigationIntent.none) {
    return;
  }
  final delta = intent == ChapterNavigationIntent.next ? 1 : -1;
  final target = _chapterIndex + delta;
  if (target < 0 || target >= chapters.length) return;
  setState(() {
    _changingChapter = true;
    _chapterIndex = target;
  });
  await Future<void>.delayed(
    MediaQuery.disableAnimationsOf(context)
        ? const Duration(milliseconds: 120)
        : const Duration(milliseconds: 240),
  );
  if (mounted) setState(() => _changingChapter = false);
}
~~~

- [ ] **Step 4: Route onPan events through camera and coordinator**

In ViewerChapterState, add NarrativeNavigationCoordinator. Derive NarrativeAxis.fromViewport. Replace horizontal drag callbacks with onPanStart, onPanUpdate, and onPanEnd.

At start: stop inertia, begin camera, and arm coordinator with current progress and axis. At update: call camera.update with axis; pass the returned locked gesture and delta to coordinator; forward a non-none intent to the parent. At end: end both objects; run inertia only when the locked gesture matched the active axis and no chapter intent was sent.

~~~dart
void _beginPan(DragStartDetails details) {
  _inertia.stop();
  final axis = NarrativeAxis.fromViewport(MediaQuery.sizeOf(context));
  _camera.begin(scale: scale);
  _navigation.begin(
    progress: _camera.progress,
    axis: axis,
    itemCount: widget.chapter.placements.length,
  );
  _sentChapterIntent = false;
}

void _updatePan(DragUpdateDetails details) {
  final viewport = MediaQuery.sizeOf(context);
  final axis = NarrativeAxis.fromViewport(viewport);
  final gesture = _camera.update(
    delta: details.delta,
    viewport: viewport,
    itemCount: widget.chapter.placements.length,
    scale: scale,
    axis: axis,
  );
  widget.onProgressChanged(_camera.progress);
  final intent = _navigation.update(details.delta, gesture);
  if (intent != ChapterNavigationIntent.none) {
    _sentChapterIntent = true;
    widget.onChapterIntent(intent);
  }
}

void _endPan(DragEndDetails details) {
  final viewport = MediaQuery.sizeOf(context);
  final axis = NarrativeAxis.fromViewport(viewport);
  final direction = _camera.direction;
  _camera.end();
  _navigation.end();
  final expected = axis == NarrativeAxis.vertical
      ? GalleryGesture.vertical
      : GalleryGesture.horizontal;
  if (_sentChapterIntent || direction != expected || widget.reduceMotion) {
    return;
  }
  final velocity = axis.primaryOffset(details.velocity.pixelsPerSecond);
  if (velocity.abs() < 60) return;
  _inertia.animateWith(
    _camera.simulationForVelocity(
      pixelsPerSecond: velocity,
      viewport: viewport,
      itemCount: widget.chapter.placements.length,
      axis: axis,
    ),
  );
}
~~~

Use axis.primaryOffset(details.velocity.pixelsPerSecond) for inertia. Preserve InteractiveViewer zoom priority. Show keyed boundary hints only when the corresponding neighboring chapter exists. Use up/down item icons in portrait and left/right item icons in landscape. Explicit chapter buttons call the same parent change method.

In didChangeDependencies, compare the new viewport with a stored _lastViewport. When it changes, stop inertia and end both gesture state machines. Preserve the transformation scale and normalize its translation from the old viewport into the new one:

~~~dart
void _rebaseTransform(Size nextViewport) {
  final previous = _lastViewport;
  _lastViewport = nextViewport;
  if (previous == null || previous == nextViewport) return;
  _inertia.stop();
  _camera.end();
  _navigation.end();
  final matrix = _transform.value.clone();
  final translation = matrix.getTranslation();
  matrix.setTranslationRaw(
    previous.width <= 0
        ? translation.x
        : translation.x / previous.width * nextViewport.width,
    previous.height <= 0
        ? translation.y
        : translation.y / previous.height * nextViewport.height,
    translation.z,
  );
  _transform.value = matrix;
}
~~~

- [ ] **Step 5: Run tests and commit**

~~~powershell
flutter test test/app/viewer_flow_test.dart test/layout/narrative_navigation_coordinator_test.dart test/layout/narrative_camera_controller_test.dart
git add lib/screens/viewer_screen.dart test/app/viewer_flow_test.dart
git commit -m "feat: navigate viewer by orientation and boundaries"
~~~

Expected: portrait/landscape navigation, fresh-gesture handoff, explicit controls, zoom priority, and rotation preservation PASS.

## Task 8: Golden refresh, full verification, and APK

**Files:**
- Modify: test/goldens/scene_templates_golden_test.dart
- Modify: six storyPath portrait/landscape Golden PNGs at 0%, 35%, and 70%
- Modify: design-qa.md

- [ ] **Step 1: Make Golden direction assertions explicit**

Before each story-path Golden, assert that LayoutResolver returns Axis.vertical for 390×844 and Axis.horizontal for 844×390. Render 0%, 35%, and 70% with the existing sample assets and themes.

- [ ] **Step 2: Update affected Goldens**

~~~powershell
flutter test test/goldens/scene_templates_golden_test.dart --update-goldens
~~~

Expected: six storyPath Golden files change. Inspect Git diff to confirm non-story Golden files remain unchanged.

- [ ] **Step 3: Run all automated verification**

~~~powershell
dart format lib test
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
~~~

Expected: format check exits 0, analyzer reports no issues, and every test passes.

- [ ] **Step 4: Build and manually verify Android**

~~~powershell
flutter build apk --debug
~~~

Expected artifact: build/app/outputs/flutter-apk/app-debug.apk.

On API 36 and API 29 verify:
- landscape editor has no persistent top rows;
- chapter overlay closes after selection;
- portrait story path moves vertically;
- landscape story path moves horizontally;
- portrait chapter change requires a fresh gesture at a boundary;
- pinch zoom blocks navigation;
- rotation preserves chapter and progress;
- size and frame controls still visibly affect the photo.

- [ ] **Step 5: Update QA evidence and commit**

Record the tested viewports, reference image path, portrait/landscape capture paths, observed ordering, absence of line crossings, and exact analyze/test/build results in design-qa.md. Screenshots remain ignored local evidence.

~~~powershell
git add test/goldens/scene_templates_golden_test.dart test/goldens/storyPath_*.png design-qa.md
git commit -m "test: verify responsive story path v3"
git status --short
git log --oneline -10
~~~

Expected: a clean worktree and focused commits for layout, track, camera, navigation, painter, editor, viewer, and QA.

## Final acceptance checklist

- [ ] Landscape editor has no persistent app bar or chapter rail; portrait restores both.
- [ ] Story nodes are strictly ordered down in portrait and right in landscape.
- [ ] Path controls never reverse the primary axis and the line is painted behind photos.
- [ ] Portrait uses vertical chapter-internal navigation; landscape uses horizontal navigation.
- [ ] Portrait chapter switching requires a fresh gesture at an armed boundary.
- [ ] Zoomed content reserves one-finger input for image panning.
- [ ] Orientation changes preserve chapter and normalized camera progress.
- [ ] Empty, single-image, missing-image, and terminal-chapter states do not crash.
- [ ] Existing size and frame choices remain visually distinct.
- [ ] Formatting, analyzer, tests, and debug APK build all succeed.
