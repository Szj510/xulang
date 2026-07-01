# Delete Images and Cinematic Layouts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add selected-photo deletion in the editor and three order-preserving cinematic layouts.

**Architecture:** Keep deletion in `EditorSession` so UI and persistence share one mutation path. Add layout enum values and resolver methods, then let existing editor/viewer canvases consume the same `ResolvedScene` output.

**Tech Stack:** Flutter, Dart, Riverpod session state, Drift-backed repository, existing layout/golden/widget test stack.

---

### Task 1: Placement deletion

**Files:**
- Modify: `lib/editor/editor_session.dart`
- Modify: `lib/screens/editor_screen.dart`
- Modify: `lib/l10n/app_strings.dart`
- Test: `test/editor/editor_session_test.dart`

- [ ] **Step 1: Write failing editor session test**

Add a test that loads a chapter with two placements, calls `session.deletePlacement(firstId)`, and expects one remaining placement reordered to `0`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/editor/editor_session_test.dart --plain-name "deletes a placement without deleting media" --reporter compact`

- [ ] **Step 3: Implement minimal session method**

Add `deletePlacement(String placementId)` to `EditorSession`, filtering the selected chapter placements and reordering them.

- [ ] **Step 4: Add editor UI action**

Add a destructive button in the image panel that calls a parent callback. In `_EditorScreenState`, delete the selected placement and focus the next/previous placement if available.

- [ ] **Step 5: Run tests and commit**

Run `flutter test test/editor/editor_session_test.dart --reporter compact`, then commit as `feat: delete placements from editor`.

### Task 2: Cinematic layout data and resolver

**Files:**
- Modify: `lib/domain/gallery_document.dart`
- Modify: `lib/layout/layout_resolver.dart`
- Modify: `lib/l10n/app_strings.dart`
- Modify: `lib/screens/editor_screen.dart`
- Test: `test/layout/layout_resolver_test.dart` or `test/layout/narrative_track_resolver_test.dart`

- [ ] **Step 1: Write failing resolver tests**

Add tests for `scrollJourney`, `windBook`, and `fireworkCascade` that assert every placement appears exactly once, first/last order is preserved, and the main travel axis differs by viewport orientation where relevant.

- [ ] **Step 2: Run test to verify it fails**

Run the focused layout test and confirm missing enum/layout failures.

- [ ] **Step 3: Add enum values and labels**

Extend `GalleryLayout` with `scrollJourney`, `windBook`, `fireworkCascade`; add localized labels and wire `_layoutLabel`.

- [ ] **Step 4: Add resolver methods**

Implement three deterministic methods in `LayoutResolver`, using `ResolvedSceneNode` scale, rotation, z, and rect placement to express the concepts.

- [ ] **Step 5: Run focused tests**

Run the focused layout tests and fix geometry until deterministic assertions pass.

### Task 3: Canvas visual treatment and sound hook

**Files:**
- Modify: `lib/widgets/scene_canvas.dart`
- Modify: `lib/screens/viewer_screen.dart`
- Modify: `pubspec.yaml`
- Create: `assets/audio/firework-pop.wav` if a tiny generated asset is practical
- Test: `test/widgets/scene_canvas_test.dart`

- [ ] **Step 1: Write failing widget tests**

Add tests that new layout scenes render their distinctive painter layer or at least expose deterministic node transforms.

- [ ] **Step 2: Add visual painters**

Add lightweight painters for page/wind and firework particles. Keep Scroll Journey path-based and reuse existing story-path language where possible.

- [ ] **Step 3: Add firework audio hook**

Trigger a short sound in viewer playback when entering a `fireworkCascade` chapter. Keep it non-blocking and safe if the asset is unavailable.

- [ ] **Step 4: Run tests and commit**

Run `flutter analyze`, `flutter test --reporter compact`, then commit as `feat: add cinematic gallery layouts`.

### Task 4: Release

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Bump version**

Update `version:` from `0.2.0+2` to `0.3.0+3`.

- [ ] **Step 2: Build release**

Run `flutter build apk --release`.

- [ ] **Step 3: Push and update GitHub Release**

Push the branch, merge to `main` if checks pass, create/update GitHub release `v0.3.0`, and upload `build/app/outputs/flutter-apk/app-release.apk`.

