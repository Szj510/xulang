# GIF 分享、真实画框与 3D 模板 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add compact GIF sharing, richer programmatic frame textures, and a first 2.5D depth-wall gallery template.

**Architecture:** Keep exports in `lib/share`, layout in `lib/layout`, and rendering in existing widgets. GIF generation is a service used by `ExportFileService`; 3D is a new enum layout resolved by `LayoutResolver`.

**Tech Stack:** Flutter, Dart, `image` package, system share sheet, existing widget/golden tests.

---

### Task 1: GIF export service

**Files:**
- Modify: `lib/share/exhibition_exporter.dart`
- Modify: `lib/share/export_file_service.dart`
- Test: `test/share/exhibition_exporter_test.dart`
- Test: `test/share/export_file_service_test.dart`

- [ ] Add failing tests for GIF bytes and file output.
- [ ] Implement `ExhibitionGifExporter`.
- [ ] Add `writeGif`.
- [ ] Wire editor menu action.
- [ ] Run targeted tests.

### Task 2: Realistic frame textures

**Files:**
- Modify: `lib/widgets/photo_frame.dart`
- Test: `test/widgets/photo_frame_test.dart`

- [ ] Add tests for texture painter keys.
- [ ] Replace flat wood/metal/vintage/film rendering with layered painters.
- [ ] Run widget tests.

### Task 3: Depth-wall template

**Files:**
- Modify: `lib/domain/gallery_document.dart`
- Modify: `lib/layout/layout_resolver.dart`
- Modify: `lib/screens/editor_screen.dart`
- Modify: `lib/widgets/scene_canvas.dart`
- Test: `test/layout/layout_resolver_test.dart`
- Test: `test/goldens/scene_templates_golden_test.dart`

- [ ] Add failing layout test for `GalleryLayout.depthWall`.
- [ ] Implement resolver geometry.
- [ ] Add editor label mapping.
- [ ] Let `SceneCanvas` apply a stronger perspective transform for depth-wall nodes through existing depth/rotation data.
- [ ] Update golden baselines if intentional.

### Task 4: Verification

- [ ] `dart format --output=none --set-exit-if-changed lib test`
- [ ] `flutter analyze`
- [ ] `flutter test --reporter compact`
- [ ] `flutter build apk --release`
