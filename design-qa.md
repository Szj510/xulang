# 叙廊连续叙事长廊 · Design QA

- source visual truth path: `C:/Users/suzij/.codex/generated_images/019eeae9-ca73-7c52-a8b7-0a42de829178/exec-2432a883-91a6-4673-8c8d-4814b2cb13ed.png`
- implementation screenshot path: `E:/flutter/projs/xulang/emulator-viewer-story.png`
- interaction screenshot path: `E:/flutter/projs/xulang/emulator-viewer-story-progress.png`
- viewport: source 852×1853；implementation Android API 36 emulator 1080×2400，按内容区等比比较
- state: 「夏日散步」故事路径模板，全景 `cameraProgress = 0%`；附加 9% 连续拖动状态

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
