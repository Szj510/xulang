# 叙廊

叙廊是一款本地优先的照片叙事与微型展览创作应用。用户可以把一组照片组织成章节，选择画布主题、叙事路径、画框、贴画、背景音乐和播放节奏，再以沉浸观看或录屏方式呈现。

## v1.0 定位

- 本地优先：照片、模板、音乐和录屏文件保存在设备本地，不依赖账号或云同步。
- 照片叙事：用章节、布局、路径线条和远近关系组织记忆。
- 轻编辑：支持导入图片、调整画幅、画框、裁切焦点、旋转、短注释、贴画和章节文字。
- 沉浸观看：支持横竖屏浏览、章节切换、播放预览、录屏模式和背景音乐。
- 模板复用：可导出叙廊模板，并用本地图片重新生成展览。

## 隐私与权限

- 叙廊不申请网络权限，不上传图片、音乐、模板或视频。
- 用户授权文件夹仅用于扫描用户选择的本地模板和音频文件。
- 录屏权限仅用于用户主动生成分享视频。
- 隐私政策：`docs/privacy.html`，发布后可通过 GitHub Pages 访问。

## 开发验证

```bash
flutter analyze --no-pub
flutter test --no-pub --no-test-assets --reporter compact
flutter build apk --release
flutter build appbundle --release
```

## 发布配置

- Android applicationId：`io.github.szj510.xulang`
- Version：`1.0.0+10`
- Release signing 使用本机 upload keystore；`android/key.properties` 和 keystore 不得提交。
- Google Play 使用 AAB；GitHub Release 上传 APK。
