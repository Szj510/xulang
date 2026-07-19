# 叙廊连续叙事长廊 · Design QA

- source visual truth path: `C:/Users/suzij/.codex/generated_images/019eeae9-ca73-7c52-a8b7-0a42de829178/exec-2432a883-91a6-4673-8c8d-4814b2cb13ed.png`
- implementation screenshot path: `E:/flutter/projs/xulang/emulator-viewer-story.png`
- interaction screenshot path: `E:/flutter/projs/xulang/emulator-viewer-story-progress.png`
- viewport: source 852×1853；implementation Android API 36 emulator 1080×2400，按内容区等比比较
- state: 「夏日散步」故事路径模板，全景 `cameraProgress = 0%`；附加 9% 连续拖动状态

**Responsive story path v3 verification — 2026-06-23**

- Reference image remained the selected visual target above.
- Tested viewports in automated coverage:
  - Portrait: `390×844` for vertical story ordering, portrait editor chrome, portrait viewer vertical progression and fresh-boundary chapter handoff.
  - Landscape: `844×390` for horizontal story ordering, hidden persistent editor chrome, overlay chapter rail and viewer horizontal progression / vertical chapter switching.
- Golden evidence refreshed:
  - `test/goldens/storyPath_portrait_ink_p0.png`
  - `test/goldens/storyPath_portrait_ink_p35.png`
  - `test/goldens/storyPath_portrait_ink_p70.png`
  - `test/goldens/storyPath_landscape_paper_p0.png`
  - `test/goldens/storyPath_landscape_paper_p35.png`
  - `test/goldens/storyPath_landscape_paper_p70.png`
- Direction assertions now run before each story-path golden: portrait resolves `Axis.vertical`; landscape resolves `Axis.horizontal`.
- Observed ordering is deterministic: story nodes advance down in portrait and right in landscape; path segments are generated from resolved anchors and remain behind photos, with label placement clamped away from frame overlap.
- Exact verification commands and outcomes:
  - `flutter test test/goldens/scene_templates_golden_test.dart --update-goldens`: 30/30 passed; only six storyPath golden PNGs changed.
  - `dart format lib test`: 50 files checked, 0 changed on final run.
  - `dart format --output=none --set-exit-if-changed lib test`: exit 0.
  - `flutter analyze`: No issues found.
  - `flutter test`: 137/137 passed.
  - `flutter build apk --debug`: built `build/app/outputs/flutter-apk/app-debug.apk`.
- Manual device note: no physical API 29/API 36 device pass was executed in this run; coverage is automated widget/golden/unit verification plus successful Android debug APK build.

**Full-view comparison evidence**

- 两张图已在同一次视觉检查中打开并对照。实现保留了参考图的黑色纵向空间、左上远景、右上邮票主图、左下相纸图、右下前景图、弯曲路径、编号短标题、顶部章节标题与底部叙事文字。
- 实现中的照片由用户数据和画框设置驱动，不把参考图烧录成静态背景；横向拖动后截图显示进度从 0% 连续变为 9%，所有节点位置、透视、透明度与景深连续变化。

**Focused region comparison evidence**

- 未另做裁切：两张原图均为高分辨率整屏截图，主图邮票齿孔、相纸留白、章节字体、节点文字和底部控件在整屏对照中可清晰辨认。

**Findings**

- 无 P0/P1/P2。
- [P3] 背景材质比参考图更克制
  Location: 故事路径画布。
  Evidence: 参考图有轻微纸张颗粒，实现使用接近纯黑的墨色画布。
  Impact: 不影响层级、交互和文字对比度；纯色背景减少低端设备重绘成本。
  Follow-up: 后续可增加一张低对比度可平铺的真实纹理资产，并在“减少动态效果”下保持静态。
- [P3] 无障碍控件比概念图更大
  Location: 退出、上一项/下一项、回到全景。
  Evidence: 实现采用 Android 可点击尺寸和文字进度，概念图使用更小的线性图标与圆点。
  Impact: 属于有意差异，提高可触达性；控件可单击隐藏，不持续遮挡作品。

**Required fidelity surfaces**

- Fonts and typography: 展览标题、章节标题和叙事文字使用中文衬线层级；控制文字使用系统无衬线，字重、行高与对比度清晰。Android 字体替代与参考字体不完全相同，属于平台可接受差异。
- Spacing and layout rhythm: 四张照片的交错节奏、主次比例、重叠与路径留白与参考一致；底部为控件和章节短注释保留安全区。
- Colors and visual tokens: 墨黑背景、暖白相纸、灰褐次级文字和棕金交互强调与参考同一色域，对比度充足。
- Image quality and asset fidelity: 全部使用真实本地图片和原图播放路径；邮票边由独立绘制层生成，未使用占位图或文本图形替代照片。
- Copy and content: 节点使用“01 启程 / 02 巷遇 / 03 海风 / 04 归途”，顶部显示展览与章节，底部显示章节叙事文字，结构与参考一致。

**Patches made since the previous QA pass**

- 故事路径 0% 改为全景状态，四张照片同时可见。
- 第二节点成为邮票主图，其他节点采用不同尺寸、相纸和无框层级。
- 横向手势改为实时写入 `cameraProgress`，保留惯性且不分页吸附。
- 横屏属性面板改为独立纵向滚动；转场和画框选项改为换行布局，避免邮票边等选项横向藏在屏外。

**Implementation checklist**

- [x] 五种模板共享连续轨道解析器。
- [x] 故事路径全景和拖动状态可用。
- [x] 小/中/大影响所有模板节点面积。
- [x] 四种画框结构和绘制结果可区分。
- [x] 横屏属性面板可滚动到底且所有画框选项可达。
- [x] 竖屏、横屏和 0%/35%/70% Golden 覆盖。

**Follow-up polish**

- 可选：增加真实墨色纸纹资产；不作为本轮阻塞项。

final result: passed

## Hand-drawn frame family — 2026-07-12

**Scope**

- Added a classic Taped paper frame plus a distinct hand-drawn family: Oil pastel, Watercolor bloom, Playful doodle, Looped lace, Corner sketch, and Wavy outline.
- Kept the classic and hand-drawn choices in labeled groups so the expanded collection remains scannable.
- Removed the visually similar Pencil sketch and Dry-brush ink choices. Every remaining hand-drawn frame uses a clearly different silhouette, and fine line frames adapt their ink color to light or dark canvases.

**Evidence**

- Golden overview: `test/goldens/hand_drawn_frame_family.png`.
- Classic taped-paper golden: `test/goldens/taped_paper_frame.png`.
- Emulator picker: `C:/Users/suzij/AppData/Local/Temp/xulang-hand-drawn-frames-panel.png`.
- Emulator applied state after the full-frame redesign: `C:/Users/suzij/AppData/Local/Temp/xulang-hand-drawn-redesign.png`.
- Compact frame-family switcher, hand-drawn state: `C:/Users/suzij/AppData/Local/Temp/xulang-frame-family-tabs.png`.
- Compact frame-family switcher, classic state: `C:/Users/suzij/AppData/Local/Temp/xulang-frame-family-classic-tab.png`.
- Watercolor bloom was selected on-device and visibly updated both the frame and selected control state.

**Verification**

- [x] The classic taped-paper frame and all six hand-drawn frame names are localized in English and Chinese.
- [x] Classic and hand-drawn frames share one segmented switcher and only the active family is rendered in the inspector.
- [x] Frame values persist by stable enum name through the gallery database.
- [x] Classic and hand-drawn groups cover every frame exactly once.
- [x] Golden rendering covers the complete five-frame family.
- [x] `dart analyze lib test` passes.
- [x] Full Flutter suite passes: 208 tests.
- [x] Android debug APK builds successfully.

final result: passed

### Home cover, unified dark surface, and editor canvas navigation

- implementation screenshots:
  - default Mountains and Sea cover on the black home surface: `C:/Users/suzij/AppData/Local/Temp/xulang-home-custom-cover-black.png`
  - clean hero without management controls: `C:/Users/suzij/AppData/Local/Temp/xulang-home-clean-hero.png`
  - home-cover entry inside Settings & Guide: `C:/Users/suzij/AppData/Local/Temp/xulang-settings-home-cover.png`
  - zoomed canvas at the top-left boundary: `C:/Users/suzij/AppData/Local/Temp/xulang-editor-zoom-top-left.png`
  - zoomed canvas at the opposite boundary: `C:/Users/suzij/AppData/Local/Temp/xulang-editor-zoom-final.png`

**Findings and resolution**

- The home hero now defaults directly to the bundled Mountains and Sea coast image and contains no management controls. Home-cover customization lives under Settings & Guide > Home appearance. Custom images are copied into app-private storage, persist in app settings, and can be reset to the sample image.
- The duplicate Categories shortcut was removed; category creation remains next to the Categories heading.
- The home navy surfaces were replaced with the same ink, surface, and elevated tokens used by the rest of the app.
- Camera progress sliders and percentage readouts were removed. Story Path retains vertical gestures; every other layout retains horizontal gestures.
- Canvas zoom now uses a top-left coordinate system, preserves the visible center during incremental zoom, and clamps translation to the exact scaled-canvas bounds. Emulator edge-to-edge panning confirms both ends of the enlarged canvas are reachable.

**Verification**

- [x] Default cover and five non-duplicated shortcuts visible on emulator.
- [x] Custom/default cover sheet is readable and actionable.
- [x] No camera slider is visible in the editor.
- [x] Enlarged canvas reaches both translation extremes.
- [x] Static analysis passes with no issues.
- [x] Complete 197-test suite passes.
- [x] Android debug APK builds successfully.

final result: passed

### Editor camera axis follows the selected layout

- implementation screenshots:
  - horizontal layout at rest: `C:/Users/suzij/AppData/Local/Temp/xulang-editor-horizontal-axis.png`
  - horizontal layout after swipe: `C:/Users/suzij/AppData/Local/Temp/xulang-editor-horizontal-axis-after.png`
- behavior mapping:
  - Story Path uses vertical canvas movement and a right-side vertical progress control.
  - Hero, Filmstrip, Diptych, Collage, and Orbit use horizontal canvas movement and a bottom horizontal progress control.
- interaction evidence: a real horizontal swipe in the Android emulator advanced the Hero layout camera from `0%` to `100%`.
- regression evidence: layout-axis mapping has unit coverage; static analysis, Android debug build, and the complete 193-test suite pass.

final result: passed

## Library home — Midnight Gallery verification — 2026-07-11

- source visual truth path: `C:/Users/suzij/AppData/Local/Temp/codex-clipboard-c0139f1e-a87c-4b40-900f-61a31cf84578.png`
- implementation screenshot path: `C:/Users/suzij/AppData/Local/Temp/xulang-ui-polish-v2.png`
- viewport: source concept `852x1917`; implementation Android capture `1080x2400`, rendered at a `390x844` logical mobile viewport and compared as normalized content regions
- state: dark theme, one uncategorized exhibition, real coastal cover image, portrait orientation

**Findings**

- No actionable P0/P1/P2 differences remain.
- [P3] The production card is slightly taller than the concept card. This keeps the category title and 48px arrow target comfortably legible on real Android text metrics.
- [P3] The concept's divider below shortcuts is omitted; spacing and the category heading already create a clear section boundary without another decorative line.
- Intentional product correction: `你的本地展览` and the ambiguous top-right overflow button are absent, following the user's explicit direction. No replacement slogan was introduced.

**Full-view comparison evidence**

- The source and final implementation were opened together in the same visual comparison input at original resolution.
- Both use a full-width coastal hero, ivory serif wordmark, centered pill-shaped create action, deep midnight-blue transition, six warm-gold labeled shortcuts, inline category creation, and an image-led category card.
- Major region order, emphasis, color balance, and reading path match the selected concept.

**Focused region comparison evidence**

- Separate crops were unnecessary because the original-resolution comparison clearly exposes the header typography, create button, all shortcut labels, category heading, image crop, title/count copy, radii, and arrow control.
- Android system bars were inspected separately: the final pass extends the hero behind a transparent status bar and retains white system icons with a matching dark navigation bar.

**Required fidelity surfaces**

- Fonts and typography: `Noto Serif SC` is used for the wordmark and section hierarchy; `Noto Sans SC` remains the UI face. Weight, contrast, line height, and label truncation remain readable at Android text metrics.
- Spacing and layout rhythm: 22px content margins, a 58px primary action, 68px shortcut targets, 18px category radii, and a compact portrait rhythm reproduce the concept while retaining a reduced-height landscape mode.
- Colors and visual tokens: deep navy `#08111F`, warm ivory `#F3E8D5`, champagne `#C8A77A`, and muted warm gray `#B6AA99` match the concept's atmosphere and retain strong contrast.
- Image quality and asset fidelity: both the hero and category card load the actual most recently edited exhibition cover through `GalleryImage`; no placeholder or generated production asset replaces user photography.
- Copy and content: the primary action reads `新建展览`; shortcuts are explicitly labeled `信息 / 设置 / 录制 / 音乐 / 导入 / 分类`; category content remains `未分类 / 1 个展览`.
- Icons and accessibility: Material outline icons form one consistent family; shortcut semantics and visible labels are present, primary targets meet practical mobile sizes, and system UI uses light icons over the hero.

**Comparison history**

- Initial P2: the first implementation capture showed a separate dark status-bar band above the hero, weakening the immersive composition. Fix: use transparent system status styling, draw the hero behind the status bar, and offset the wordmark by the real safe-area inset.
- Initial P2: a fixed tall header could crowd short-height devices. Fix: add a compact mode below 700 logical pixels that reduces hero, title, button, and shortcut spacing while preserving all actions.
- Initial P2: the prior empty-library panel could overflow beneath the new hero. Fix: replace it with a compact, centered empty state retaining create and template-import actions.
- Post-fix evidence: `C:/Users/suzij/AppData/Local/Temp/xulang-ui-polish-v2.png`.

**Primary interactions tested**

- The `新建展览` CTA opens the existing named-exhibition dialog with `展览名称`, `取消`, and `创建` controls.
- Shortcut and category controls remain wired to their existing production callbacks; the full Flutter suite confirms no navigation or persistence regressions.

**Implementation checklist**

- [x] Remove the low-value subtitle and ambiguous overflow button.
- [x] Use the latest real exhibition cover for the hero and category card.
- [x] Preserve six discoverable, labeled shortcuts and their callbacks.
- [x] Keep category creation inline and category navigation obvious.
- [x] Support empty and short-height states without overflow.
- [x] Pass static analysis, Android debug build, and the full test suite.

**Follow-up polish**

- P3 only: tune the hero crop per individual cover if future user testing shows faces or subjects need manual focal-point control.

final result: passed

## Saturn orbit layering verification — 2026-07-10

- source visual truth path: `C:/Users/suzij/AppData/Local/Temp/codex-clipboard-aeaac9cb-b30c-4a78-b1b0-60ef8890edf9.png`
- implementation screenshot path: `E:/flutter/projs/xulang/test/goldens/orbit_saturn_landscape_ink.png`
- viewport: source `980x556`; implementation `844x390`, compared as normalized landscape content regions without browser chrome
- state: Orbit layout, four photos, 35% camera progress, ink theme, all photos using the new Orb frame

**Findings**

- No actionable P0/P1/P2 differences remain for the requested Saturn-style behavior.
- [P3] The reference uses a photographic textured ring while the implementation uses theme-aware vector strokes and ticks.
  Location: orbit track.
  Evidence: the source ring contains banded dust texture; the implementation stays deliberately restrained so it remains legible across all gallery themes and animates continuously.
  Impact: lower literal texture fidelity, but the requested depth, occlusion, elliptical plane, and planet silhouette are preserved.
  Follow-up: optional theme-specific ring texture can be introduced later if it remains performant and does not compete with user photos.

**Full-view comparison evidence**

- Source and implementation were opened together in the same visual comparison input.
- Both use a dark landscape field, a dominant circular center body, a nearly horizontal elliptical ring, smaller orbiting bodies, and clear front/back depth.
- The implementation intentionally retains Xulang's existing ink palette and user-photo content rather than copying the source's astronomy image.

**Focused region comparison evidence**

- A separate crop was not required: at the 844x390 implementation viewport, the central body and both ring intersections are large enough to inspect directly.
- The upper/back arc disappears beneath the center Orb frame, while the brighter lower/front arc crosses above it and then continues outward. Foreground orbiting photos are drawn above the front arc.
- Orb photos remain circular at portrait and landscape sizes because the frame uses a constrained 1:1 mask rather than stretching the source image into an oval.

**Required fidelity surfaces**

- Fonts and typography: not applicable to the supplied visual target; no text was introduced into the scene.
- Spacing and layout rhythm: the central body dominates, satellites remain secondary, and one or two rings are selected from photo count as designed.
- Colors and visual tokens: the implementation uses Xulang ink/paper foreground tokens, with the front arc brighter and thicker than the back arc.
- Image quality and asset fidelity: real gallery photos remain sharp inside circular masks; no placeholder astronomy assets were substituted.
- Copy and content: the editor exposes the frame as `Orb / 星体圆框`; existing frame choices remain unchanged.

**Comparison history**

- Earlier P2: the full ellipse was painted in one layer, so the center photo could not create a Saturn-like occlusion. Fix: split the orbit into back and front half-arcs and render the center photo between them.
- Earlier P2: the inner ring was tangent to the center circle, making the crossing too subtle. Fix: flatten the inner ring so both intersections visibly pass through the center Orb silhouette, then strengthen the front arc.
- Earlier P2: compressed dual tracks could fall back to nearly complete satellite overlap. Fix: use a moderate overlap allowance with phase search and validate the full motion cycle.
- Post-fix evidence: `orbit_saturn_landscape_ink.png`, plus portrait and dense orbit goldens.

**Implementation checklist**

- [x] Back ring renders behind the central body.
- [x] Front ring renders over the central body.
- [x] Foreground satellites render over the front ring.
- [x] Orb frame is selectable and persists by stable enum name.
- [x] Single/dual ring count behavior remains intact.
- [x] Portrait, landscape, dense, frame, motion, and localization coverage added.

**Follow-up polish**

- Optional P3: add a low-contrast banded ring material per gallery theme after performance profiling.

final result: passed

## Collapsible library hero and explicit editor controls — 2026-07-11

- source visual truth: selected Midnight Gallery concept plus the user's explicit requirements that the hero scroll away and every editor control explain its role
- implementation screenshots:
  - expanded home: `C:/Users/suzij/AppData/Local/Temp/xulang-home-before-collapse.png`
  - collapsed home: `C:/Users/suzij/AppData/Local/Temp/xulang-home-after-collapse.png`
  - editor panel: `C:/Users/suzij/AppData/Local/Temp/xulang-editor-panel-final.png`
  - editor entry pill: `C:/Users/suzij/AppData/Local/Temp/xulang-editor-edit-pill-final.png`
- viewport: Android portrait, `1080x2400` physical / approximately `390x844` logical
- state: official sample exhibition, home expanded/collapsed states, editor canvas mode with panel open/closed

**Findings**

- No actionable P0/P1/P2 differences remain.
- [P3] Home collapse currently uses a short ease-out size transition rather than a continuously proportional parallax collapse. The result is deliberate: it responds reliably even when only one category exists and immediately returns maximum category space.

**Full-view comparison evidence**

- Expanded and collapsed home captures were opened together. The first preserves the selected atmospheric composition; after an upward drag the hero, create action, and shortcuts leave the viewport, while the category heading and card move beneath the status bar with safe padding.
- The editor open and closed captures show one readable `Edit` entry, three labeled mode controls, a labeled current canvas theme, and a dedicated `Close` action without overlapping controls.

**Focused region comparison evidence**

- Separate crops were not needed because the original-resolution captures clearly show all affected labels, icon alignment, 48px interaction targets, status-bar padding, category card bounds, and panel overlap behavior.

**Required fidelity surfaces**

- Fonts and typography: panel labels use the existing Noto Sans UI scale with stronger selected-state weight; canvas theme exposes both its function and current value.
- Spacing and layout rhythm: collapsing the 480px hero releases the full category viewport; panel modes use equal-width controls and the close action occupies the panel header rather than floating over content.
- Colors and visual tokens: the home retains midnight navy and champagne; editor controls continue using existing paper, muted, and accent tokens.
- Image quality and asset fidelity: the same real exhibition cover remains sharp before and after collapse; editor changes introduce no new raster assets.
- Copy and content: visible roles are `Edit`, `Canvas`, `Image`, `Sticker`, `Canvas theme`, the active theme value, and `Close`; Chinese localization provides the equivalent labels.
- Accessibility and interaction: all modes remain explicit semantic buttons, the floating editor entry is a labeled pill, and the home collapse works through both normal scroll updates and overscroll when content is short.

**Comparison history**

- Earlier P2: the fixed hero consumed most of the home viewport and a one-category grid could not scroll enough to move it. Fix: listen to grid scroll and overscroll, animate the header to zero height on upward drag, and restore it on downward overscroll.
- Earlier P2: the floating editor trigger and canvas-theme palette icon relied on recognition alone. Fix: convert the trigger to an `Edit` pill and the palette popup to a labeled control that also displays the current theme.
- Earlier P2: the first labeled close pill overlapped panel content. Fix: hide the floating trigger while the panel is open and add a dedicated `Close` action to the panel header.
- Post-fix evidence is recorded in the four implementation screenshots above.

**Primary interactions tested**

- Upward drag collapses the home hero even with one category; downward overscroll restores it.
- The editor entry opens the panel; the panel close action dismisses it.
- Canvas, image, and sticker mode controls remain connected to their existing callbacks.
- The canvas-theme menu shows all persisted themes and the active theme value.

**Implementation checklist**

- [x] Collapsible and restorable home hero.
- [x] Safe-area padding after collapse.
- [x] Labeled editor entry and close action.
- [x] Equal-width labeled Canvas/Image/Sticker modes.
- [x] Labeled canvas-theme control with current value.
- [x] Static analysis, Android debug build, and 192-test suite pass.

**Follow-up polish**

- Optional P3: add proportional parallax only if user testing prefers a slower cinematic collapse over the current immediate space-saving behavior.

final result: passed
