# 叙廊 · Xulang

<p align="center">
  <img src="assets/branding/app-icon.png" width="112" alt="叙廊应用图标">
</p>

<p align="center">
  一款本地优先的照片叙事与微型展览创作应用。<br>
  A local-first photo storytelling and miniature exhibition creator.
</p>

<p align="center">
  <a href="https://github.com/Szj510/xulang/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/Szj510/xulang/actions/workflows/ci.yml/badge.svg"></a>
  <a href="https://github.com/Szj510/xulang/releases/latest"><img alt="GitHub Release" src="https://img.shields.io/github/v/release/Szj510/xulang?display_name=tag"></a>
  <a href="LICENSE"><img alt="GPL-3.0" src="https://img.shields.io/badge/license-GPL--3.0-blue.svg"></a>
  <img alt="Android 10+" src="https://img.shields.io/badge/Android-10%2B-3DDC84?logo=android&logoColor=white">
</p>

[简体中文](#简体中文) · [English](#english)

## 简体中文

叙廊将照片组织成章节和叙事路径。你可以为每个章节选择画布、布局、画框、贴画、文字、背景音乐和播放节奏，再通过沉浸播放或 Android 录屏生成可分享的作品。

### 界面展示

以下演示使用可公开再分发的样例素材，固定展示“图库 → 编辑 → 沉浸播放”核心链路：

1. 图库：按分类整理展览，并快速新建、搜索、排序与移动作品。
2. 编辑：导入图片并调整画布、布局、画框、贴画与音乐。
3. 沉浸播放：按章节浏览、自动播放，并在 Android 上录制视频。

<p align="center">
  <img src="docs/media/library.png" width="260" alt="叙廊图库">
  <img src="docs/media/editor.gif" width="260" alt="叙廊编辑器">
  <img src="docs/media/viewer.gif" width="260" alt="叙廊沉浸播放">
</p>

### 特性

- **本地优先**：无需账号或云同步，不申请网络权限；照片、模板、音乐和录屏保存在设备本地。
- **章节化叙事**：使用多章节、叙事路径、远近关系和播放节奏组织照片。
- **轻量编辑**：支持画布主题、布局、画框、裁切焦点、旋转、短注释、贴画与章节文字。
- **沉浸播放**：支持横竖屏浏览、章节切换、自动播放和背景音乐。
- **模板与分享**：导入、导出不含照片的 `.xulang-template.json` 模板，并生成离线 HTML 展览。
- **Android 录屏**：用户主动授权后生成 MP4；录屏功能目前仅支持 Android。

### 下载与安装

正式构建发布在 [GitHub Releases](https://github.com/Szj510/xulang/releases)。下载最新 APK，在 Android 10（API 29）或更高版本安装。APK 页面会同时提供 SHA-256 校验文件。

> Android 可能要求允许浏览器或文件管理器“安装未知应用”。请只从本仓库的 Release 页面下载安装包。

### 从源码构建

要求 Flutter 3.41.7、Dart 3.11.5、JDK 17 和 Android SDK。克隆后运行：

```bash
flutter pub get
flutter analyze --no-pub
flutter test --no-pub --reporter compact
flutter build apk --debug
```

Release 构建需要维护者自己的 Android 签名配置；不要将 `key.properties`、keystore 或密码提交到仓库。

### 隐私

叙廊不申请网络权限，也不会上传照片、音乐、模板或视频。应用授权的文件夹仅用于读取你选择的本地模板与音频；卸载应用会删除应用私有空间中的展览。完整说明见[隐私政策](docs/privacy.html)。

### 贡献

欢迎 Bug 报告、功能建议和 Pull Request。提交代码前请阅读[贡献指南](CONTRIBUTING.md)与[行为准则](CODE_OF_CONDUCT.md)。当前正式支持 Android 10+。

安全问题不要创建公开 Issue，请按照[安全政策](SECURITY.md)使用 GitHub 私密漏洞报告。

### 路线图

- 持续改善公开演示和无障碍体验。
- 持续扩展布局、画框与模板能力。
- 欢迎社区参与 [iOS 版本的设计与实现](https://github.com/Szj510/xulang/issues/3)。
- 保持本地优先，不引入账号、云同步或远程素材市场。

## English

Xulang turns a set of photos into chapters and narrative paths. Each chapter can use its own canvas, layout, frame, stickers, text, background music, and playback timing, then be experienced as an immersive exhibition or recorded on Android.

### Showcase

The showcase uses redistribution-safe sample media and covers the fixed Library → Editor → Immersive viewer flow:

1. Library: organize exhibitions by category, then create, search, sort, and move them.
2. Editor: import photos and customize canvas, layout, frames, stickers, and music.
3. Immersive viewer: navigate chapters, autoplay the story, and record it on Android.

<p align="center">
  <img src="docs/media/library.png" width="260" alt="Xulang library">
  <img src="docs/media/editor.gif" width="260" alt="Xulang editor">
  <img src="docs/media/viewer.gif" width="260" alt="Xulang immersive viewer">
</p>

### Highlights

- **Local first:** no account, cloud sync, or network permission; photos, templates, music, and recordings remain on the device.
- **Chapter-based storytelling:** organize photos with chapters, narrative tracks, depth, and playback timing.
- **Lightweight editing:** choose canvases, layouts, frames, focal crops, rotation, notes, stickers, and chapter text.
- **Immersive viewing:** portrait and landscape navigation, chapter switching, autoplay, and background music.
- **Templates and sharing:** import or export photo-free `.xulang-template.json` templates and generate offline HTML exhibitions.
- **Android recording:** create MP4 recordings after explicit system consent; built-in recording is currently Android-only.

### Download

Official builds are published on [GitHub Releases](https://github.com/Szj510/xulang/releases). Download the latest APK for Android 10 (API 29) or newer and verify it against the accompanying SHA-256 checksum.

### Build from source

Install Flutter 3.41.7, Dart 3.11.5, JDK 17, and the Android SDK, then run:

```bash
flutter pub get
flutter analyze --no-pub
flutter test --no-pub --reporter compact
flutter build apk --debug
```

Release builds require the maintainer's Android signing configuration. Never commit `key.properties`, a keystore, or signing passwords.

### Privacy

Xulang does not request network access and does not upload photos, music, templates, or videos. Granted folder access is only used for local templates and audio selected by the user. Uninstalling the app removes exhibitions stored in its private data directory. Read the full [privacy policy](docs/privacy.html).

### Contributing

Bug reports, feature proposals, and pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md) first. Android 10+ is the currently supported release platform.

Do not open public issues for vulnerabilities. Follow [SECURITY.md](SECURITY.md) and use GitHub private vulnerability reporting.

### Roadmap

- Continue improving the public showcase and accessibility.
- Expand layouts, frames, and reusable template capabilities.
- Community contributors are welcome to help [design and implement the iOS version](https://github.com/Szj510/xulang/issues/3).
- Preserve the local-first model without accounts, cloud sync, or a hosted asset marketplace.

## License

Copyright (C) 2026 ius.

Xulang is licensed under the [GNU General Public License v3.0](LICENSE).
