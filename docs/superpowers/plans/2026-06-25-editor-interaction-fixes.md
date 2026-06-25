# Editor Interaction Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix editor interaction problems reported after manual verification: true canvas zoom-out, remove duplicated advanced image editing, make inspector panel opacity adjustable, and replace the broken auto-anchor path tool with an isolated path-editing workflow where users pick two images, hand-draw a curve, edit nearby annotation text, and drag that text.

**Architecture:** Keep the editor in explicit interaction modes so gestures do not fight each other. Canvas mode controls viewport zoom/pan, image mode controls selected image transforms, and path mode captures/edits path gestures. Use normalized canvas coordinates for paths and annotation placement so data survives rotation, resizing, and device changes.

**Tech Stack:** Flutter, Riverpod/ChangeNotifier-style editor session, Drift JSON storage via `custom_path_data`, widget tests/golden tests where existing coverage already touches editor and `SceneCanvas`.

---

## Pre-task: Git checkpoint

CodexPro is currently running with `CODEXPRO_BASH_MODE=safe`; `git add` was blocked by the allowlist. Before implementation, make a local checkpoint manually or restart CodexPro with full bash mode.

Current changed files to checkpoint:

```bash
git add \
  lib/data/gallery_database.dart \
  lib/data/gallery_database.g.dart \
  lib/domain/gallery_document.dart \
  lib/editor/editor_session.dart \
  lib/screens/editor_screen.dart \
  lib/screens/library_screen.dart \
  lib/screens/viewer_screen.dart \
  lib/theme/xulang_theme.dart \
  lib/widgets/scene_canvas.dart \
  test/app/editor_landscape_test.dart \
  test/app/library_flow_test.dart \
  test/data/gallery_database_test.dart \
  test/editor/editor_session_test.dart \
  test/widgets/scene_canvas_test.dart

git commit -m "checkpoint: save verified editor state"
```

Do not commit `android/build/`; it is generated output. If it keeps appearing, add the appropriate ignore rule in a separate cleanup commit.

---

## Files and responsibilities

- `lib/screens/editor_screen.dart`
  - Owns editor mode state, preview gesture routing, inspector panel controls, path creation dialogs, and path drawing overlays.
- `lib/widgets/scene_canvas.dart`
  - Renders media placements, story path lines, path labels, and exposes optional callbacks for path gesture handles.
- `lib/domain/gallery_document.dart`
  - Defines persistent gallery path data. Current `CustomPathAnchor` model is too weak for the desired feature; introduce a path connection model while keeping backward decode support.
- `lib/editor/editor_session.dart`
  - Provides update methods for custom path connections and placement updates.
- `lib/data/gallery_database.dart`
  - Encodes/decodes custom path JSON. Reuse existing `custom_path_data` text column, but support a versioned JSON shape.
- `test/widgets/scene_canvas_test.dart`
  - Render tests for custom path drawing and annotation label placement.
- `test/editor/editor_session_test.dart`
  - Session tests for adding/updating/removing custom path connections.
- `test/data/gallery_database_test.dart`
  - Persistence tests for the new path JSON and backward compatibility with old anchor arrays.
- `test/app/editor_landscape_test.dart`
  - Interaction tests for mode isolation and inspector controls.

---

## Task 1: Fix true canvas zoom-out

**Problem:** `InteractiveViewer` has `minScale: 0.5`, but because the child is viewport-sized and `boundaryMargin` is effectively tight, the user experiences only zoom-in and reset. Zoom-out is visually swallowed by the boundary constraints.

**Files:**
- Modify: `lib/screens/editor_screen.dart`
- Test: `test/app/editor_landscape_test.dart` or existing editor preview widget test

- [ ] Add a helper in `_PreviewState` to set preview zoom explicitly around the viewport center.

Implementation target:

```dart
void _setPreviewScale(double targetScale, Size viewport) {
  final scale = targetScale.clamp(0.35, 3.0);
  final center = Offset(viewport.width / 2, viewport.height / 2);
  _zoomController.value = Matrix4.identity()
    ..translate(center.dx, center.dy)
    ..scale(scale)
    ..translate(-center.dx, -center.dy);
  setState(() {});
}
```

- [ ] Update `InteractiveViewer` in `_PreviewState.build`:

```dart
InteractiveViewer(
  key: const Key('editor-preview-zoom'),
  transformationController: _zoomController,
  minScale: 0.35,
  maxScale: 3.0,
  boundaryMargin: const EdgeInsets.all(240),
  constrained: false,
  panEnabled: true,
  scaleEnabled: true,
  onInteractionEnd: (_) => setState(() {}),
  child: SizedBox(
    width: viewport.width,
    height: viewport.height,
    child: ...,
  ),
)
```

- [ ] Add visible zoom controls near the existing reset chip:

```dart
Row(
  children: [
    IconButton(onPressed: () => _setPreviewScale(currentScale - 0.15, viewport), icon: const Icon(Icons.zoom_out)),
    IconButton(onPressed: () => _setPreviewScale(1, viewport), icon: const Icon(Icons.fit_screen_outlined)),
    IconButton(onPressed: () => _setPreviewScale(currentScale + 0.15, viewport), icon: const Icon(Icons.zoom_in)),
  ],
)
```

- [ ] Verify manually: pinch and button zoom can shrink below 1.0, not only shrink back from a previously enlarged state.

- [ ] Run:

```bash
flutter test test/app/editor_landscape_test.dart
flutter analyze
```

- [ ] Commit:

```bash
git add lib/screens/editor_screen.dart test/app/editor_landscape_test.dart
git commit -m "fix: support true editor canvas zoom out"
```

---

## Task 2: Remove duplicated advanced image editing

**Problem:** `_buildPlacementPanel` already exposes size, frame, focal point, crop zoom, rotation, and caption. The bottom-sheet `_editPlacement` duplicates the same settings and confuses the flow.

**Files:**
- Modify: `lib/screens/editor_screen.dart`
- Test: `test/app/editor_landscape_test.dart`

- [ ] Remove the `高级编辑` `TextButton.icon` block from `_buildPlacementPanel`.

Delete this block:

```dart
Align(
  alignment: Alignment.centerRight,
  child: TextButton.icon(
    onPressed: () => _editPlacement(context, placement),
    icon: const Icon(Icons.tune, size: 17),
    label: const Text('高级编辑'),
  ),
),
```

- [ ] Delete `_editPlacement` if no references remain.

- [ ] Add a widget test assertion that no `高级编辑` text is present after selecting a placement.

- [ ] Run:

```bash
flutter test test/app/editor_landscape_test.dart
flutter analyze
```

- [ ] Commit:

```bash
git add lib/screens/editor_screen.dart test/app/editor_landscape_test.dart
git commit -m "fix: remove duplicated advanced image editor"
```

---

## Task 3: Make panel opacity user-adjustable

**Decision:** Start with runtime editor-local opacity. Do not persist to database in this pass unless the user later asks for cross-session persistence.

**Files:**
- Modify: `lib/screens/editor_screen.dart`
- Test: `test/app/editor_landscape_test.dart`

- [ ] In `_EditorBodyState`, add:

```dart
double _panelOpacity = 0.48;

void _setPanelOpacity(double value) {
  setState(() => _panelOpacity = value.clamp(0.18, 0.82));
}
```

- [ ] Pass `panelOpacity` and `onPanelOpacityChanged` into the inspector widget.

- [ ] In inspector decoration, replace fixed alpha:

```dart
color: Colors.black.withValues(alpha: widget.panelOpacity),
```

- [ ] Add a slider to canvas panel or header area:

```dart
_CropSlider(
  label: '面板透明度',
  value: widget.panelOpacity,
  min: 0.18,
  max: 0.82,
  onChanged: widget.onPanelOpacityChanged,
)
```

- [ ] Verify: moving the slider visibly changes the inspector glass background without affecting canvas/photo opacity.

- [ ] Run:

```bash
flutter test test/app/editor_landscape_test.dart
flutter analyze
```

- [ ] Commit:

```bash
git add lib/screens/editor_screen.dart test/app/editor_landscape_test.dart
git commit -m "feat: add adjustable editor panel opacity"
```

---

## Task 4: Introduce isolated editor modes

**Problem:** Canvas, image, and path gestures currently overlap. Path drawing must not accidentally pan the camera, zoom the canvas, or drag an image.

**Files:**
- Modify: `lib/screens/editor_screen.dart`
- Modify: `lib/widgets/scene_canvas.dart`
- Test: `test/app/editor_landscape_test.dart`

- [ ] Replace the current two-way `_EditorPanelMode` behavior with at least three explicit modes:

```dart
enum _EditorInteractionMode { canvas, image, path }
```

- [ ] UI header chips should become:

```text
画布 | 图片 | 路径
```

- [ ] Gesture policy:
  - `canvas`: preview `InteractiveViewer` and camera progress gestures are enabled; image/path callbacks are disabled.
  - `image`: `InteractiveViewer` pinch/drag is disabled; placement transform callbacks are enabled for selected image.
  - `path`: `InteractiveViewer` and placement transforms are disabled; path drawing/label dragging callbacks are enabled.

- [ ] Pass booleans into `SceneCanvas`:

```dart
interactionMode: _EditorInteractionMode.path,
placementEditingEnabled: _interactionMode == _EditorInteractionMode.image,
pathEditingEnabled: _interactionMode == _EditorInteractionMode.path,
```

Use simple booleans in `SceneCanvas` to avoid importing private screen enums into widget code.

- [ ] Add tests that mode chips exist and selecting path mode disables image transform handlers.

- [ ] Run:

```bash
flutter test test/app/editor_landscape_test.dart test/widgets/scene_canvas_test.dart
flutter analyze
```

- [ ] Commit:

```bash
git add lib/screens/editor_screen.dart lib/widgets/scene_canvas.dart test/app/editor_landscape_test.dart test/widgets/scene_canvas_test.dart
git commit -m "feat: isolate editor interaction modes"
```

---

## Task 5: Replace anchor-list path model with path connections

**Problem:** Current `CustomPathAnchor` only stores anonymous x/y points. It cannot express “this path connects image A and image B”, cannot store a hand-drawn polyline cleanly, and cannot store draggable annotation position.

**Files:**
- Modify: `lib/domain/gallery_document.dart`
- Modify: `lib/data/gallery_database.dart`
- Modify: `lib/editor/editor_session.dart`
- Test: `test/data/gallery_database_test.dart`
- Test: `test/editor/editor_session_test.dart`

- [ ] Add data classes:

```dart
class CustomPathPoint {
  const CustomPathPoint({required this.x, required this.y});
  final double x;
  final double y;

  CustomPathPoint copyWith({double? x, double? y}) =>
      CustomPathPoint(x: x ?? this.x, y: y ?? this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory CustomPathPoint.fromJson(Map<String, dynamic> json) =>
      CustomPathPoint(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
      );
}

class CustomPathConnection {
  const CustomPathConnection({
    required this.id,
    required this.fromPlacementId,
    required this.toPlacementId,
    required this.points,
    this.note = '',
    this.noteX = 0.5,
    this.noteY = 0.5,
  });

  final String id;
  final String fromPlacementId;
  final String toPlacementId;
  final List<CustomPathPoint> points;
  final String note;
  final double noteX;
  final double noteY;

  CustomPathConnection copyWith({
    String? fromPlacementId,
    String? toPlacementId,
    List<CustomPathPoint>? points,
    String? note,
    double? noteX,
    double? noteY,
  }) => CustomPathConnection(
        id: id,
        fromPlacementId: fromPlacementId ?? this.fromPlacementId,
        toPlacementId: toPlacementId ?? this.toPlacementId,
        points: points ?? this.points,
        note: note ?? this.note,
        noteX: noteX ?? this.noteX,
        noteY: noteY ?? this.noteY,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromPlacementId': fromPlacementId,
        'toPlacementId': toPlacementId,
        'points': [for (final point in points) point.toJson()],
        'note': note,
        'noteX': noteX,
        'noteY': noteY,
      };

  factory CustomPathConnection.fromJson(Map<String, dynamic> json) =>
      CustomPathConnection(
        id: json['id'] as String,
        fromPlacementId: json['fromPlacementId'] as String,
        toPlacementId: json['toPlacementId'] as String,
        points: [
          for (final item in (json['points'] as List? ?? const []))
            if (item is Map) CustomPathPoint.fromJson(Map<String, dynamic>.from(item)),
        ],
        note: json['note'] as String? ?? '',
        noteX: ((json['noteX'] as num?) ?? 0.5).toDouble(),
        noteY: ((json['noteY'] as num?) ?? 0.5).toDouble(),
      );
}
```

- [ ] Add `customPathConnections` to `GalleryChapter`. Keep `customPathAnchors` temporarily for decode compatibility or replace it with a computed legacy fallback only if tests are updated in the same task.

- [ ] Change `custom_path_data` JSON to versioned shape:

```json
{
  "version": 2,
  "connections": []
}
```

- [ ] Database decode must support old data:
  - If decoded JSON is a `List`, read it as legacy anchors and create no connections or convert adjacent anchors into one fallback connection only for rendering compatibility.
  - If decoded JSON is a `Map` with `version: 2`, parse `connections`.

- [ ] Add session methods:

```dart
Future<void> addCustomPathConnection(CustomPathConnection connection)
Future<void> updateCustomPathConnection(CustomPathConnection connection)
Future<void> removeCustomPathConnection(String connectionId)
Future<void> clearCustomPathConnections()
```

- [ ] Run:

```bash
flutter test test/data/gallery_database_test.dart test/editor/editor_session_test.dart
flutter analyze
```

- [ ] Commit:

```bash
git add lib/domain/gallery_document.dart lib/data/gallery_database.dart lib/data/gallery_database.g.dart lib/editor/editor_session.dart test/data/gallery_database_test.dart test/editor/editor_session_test.dart
git commit -m "feat: store custom path connections"
```

---

## Task 6: Build path creation flow: choose two images, then draw

**Files:**
- Modify: `lib/screens/editor_screen.dart`
- Modify: `lib/widgets/scene_canvas.dart`
- Test: `test/app/editor_landscape_test.dart`

- [ ] In path panel, replace `绘制路径/添加锚点` with `新建路径`.

- [ ] On tap, show dialog with two dropdowns using current chapter placements:

```dart
Future<({String fromId, String toId})?> _pickPathEndpoints(BuildContext context, GalleryChapter chapter)
```

Validation:
- At least two images required.
- `fromId != toId`.
- Labels should show placement order and caption fallback: `图 1`, `图 2`, etc.

- [ ] After endpoint selection, enter path drawing capture state:

```dart
_PathDraft? _pathDraft;

class _PathDraft {
  const _PathDraft({required this.fromPlacementId, required this.toPlacementId, required this.points});
  final String fromPlacementId;
  final String toPlacementId;
  final List<CustomPathPoint> points;
}
```

- [ ] In path mode, SceneCanvas should capture pan start/update/end over canvas:
  - Convert local positions to normalized `CustomPathPoint`.
  - Sample points with a minimum distance threshold to avoid thousands of points.
  - On end, if fewer than two points, discard and show a message.
  - Save as `CustomPathConnection`.

- [ ] The saved connection should use default note location near the midpoint of the drawn curve:

```dart
final mid = points[points.length ~/ 2];
noteX: (mid.x + 0.03).clamp(0.05, 0.95),
noteY: (mid.y - 0.03).clamp(0.05, 0.95),
```

- [ ] Run:

```bash
flutter test test/app/editor_landscape_test.dart test/widgets/scene_canvas_test.dart
flutter analyze
```

- [ ] Commit:

```bash
git add lib/screens/editor_screen.dart lib/widgets/scene_canvas.dart test/app/editor_landscape_test.dart test/widgets/scene_canvas_test.dart
git commit -m "feat: draw custom paths between images"
```

---

## Task 7: Render hand-drawn paths and draggable annotation text

**Files:**
- Modify: `lib/widgets/scene_canvas.dart`
- Modify: `lib/screens/editor_screen.dart`
- Test: `test/widgets/scene_canvas_test.dart`

- [ ] Render each `CustomPathConnection.points` as a smoothed path.

Minimal implementation:

```dart
Path buildPath(List<Offset> points) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (var i = 1; i < points.length; i++) {
    final previous = points[i - 1];
    final current = points[i];
    final mid = Offset((previous.dx + current.dx) / 2, (previous.dy + current.dy) / 2);
    path.quadraticBezierTo(previous.dx, previous.dy, mid.dx, mid.dy);
  }
  path.lineTo(points.last.dx, points.last.dy);
  return path;
}
```

- [ ] Draw endpoints with subtle markers and, if useful, highlight the two connected image nodes.

- [ ] Render annotation as a `Positioned` draggable widget beside the curve. In path mode:
  - Tapping the label opens text editor.
  - Dragging the label updates `noteX/noteY`.
  - Outside path mode, label ignores pointer.

- [ ] Text edit dialog:

```dart
Future<void> _editPathNote(CustomPathConnection connection)
```

- [ ] Save label drag through `session.updateCustomPathConnection`.

- [ ] Run:

```bash
flutter test test/widgets/scene_canvas_test.dart test/app/editor_landscape_test.dart
flutter analyze
```

- [ ] Commit:

```bash
git add lib/widgets/scene_canvas.dart lib/screens/editor_screen.dart test/widgets/scene_canvas_test.dart test/app/editor_landscape_test.dart
git commit -m "feat: edit custom path annotations"
```

---

## Task 8: Final verification pass

**Files:**
- No source changes unless verification reveals failures.

- [ ] Run targeted tests:

```bash
flutter test test/app/editor_landscape_test.dart test/widgets/scene_canvas_test.dart test/editor/editor_session_test.dart test/data/gallery_database_test.dart
```

- [ ] Run full static analysis:

```bash
flutter analyze
```

- [ ] Manual verification checklist:
  - Canvas mode: pinch/button zoom out below 1.0 works; reset returns to normal.
  - Canvas mode: moving canvas does not move images or paths.
  - Image mode: selected image can move/scale; canvas does not pan unexpectedly.
  - Path mode: `新建路径` requires two different images.
  - Path mode: drawing with finger creates a visible curve instead of auto-aligned anchors.
  - Path mode: annotation text appears near curve, can be edited, and can be dragged.
  - Placement panel no longer shows duplicated `高级编辑` entry.
  - Panel opacity slider visibly changes only the panel background.

- [ ] Commit verification fixes if needed:

```bash
git add <changed-files>
git commit -m "test: verify editor interaction fixes"
```
