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
