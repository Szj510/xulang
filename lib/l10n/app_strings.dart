import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/providers/app_providers.dart';

class AppStrings {
  const AppStrings._(this.language);

  final AppLanguage language;

  static AppStrings of(BuildContext context) {
    final container = ProviderScope.containerOf(context, listen: false);
    final settings = container
        .read(appSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => const AppSettings());
    final locale = Localizations.maybeLocaleOf(context);
    return AppStrings._(settings.language.resolve(locale));
  }

  static AppStrings from(AppSettings settings, [Locale? locale]) {
    return AppStrings._(settings.language.resolve(locale));
  }

  bool get isEnglish => language == AppLanguage.english;

  String get appTitle => isEnglish ? 'Xulang' : '叙廊';
  String get localGallery => isEnglish ? 'Your local gallery' : '你的本地展览';
  String get newExhibition => isEnglish ? 'New' : '新建';
  String get localStorageInfo => isEnglish ? 'Local storage' : '本地存储说明';
  String get settingsAndGuide => isEnglish ? 'Settings & Guide' : '设置与使用说明';
  String get importTemplate => isEnglish ? 'Import template' : '导入模板';
  String get newCategory => isEnglish ? 'New category' : '新建分类';
  String get recordingPlayback => isEnglish ? 'Recording playback' : '录屏播放';
  String get language => isEnglish ? 'Language' : '语言';
  String get followSystem => isEnglish ? 'Follow system' : '跟随系统';
  String get simplifiedChinese => isEnglish ? 'Simplified Chinese' : '简体中文';
  String get english => isEnglish ? 'English' : '英文';
  String get showChapterTitleRecording =>
      isEnglish ? 'Show chapter title while recording' : '录屏时显示章节名';
  String get showChapterTitleRecordingSubtitle => isEnglish
      ? 'Turn this off to record only the canvas and photos.'
      : '关闭后，沉浸录屏只保留画布和图片。';
  String get mediaImportMode => isEnglish ? 'Image import mode' : '图片导入方式';
  String get recordingDefaults => isEnglish ? 'Recording defaults' : '录制默认值';
  String get defaultRecordingChapters =>
      isEnglish ? 'Default chapters' : '默认录制章节';
  String get useMusicByDefault =>
      isEnglish ? 'Use music by default' : '默认使用背景音乐';
  String get canChangeBeforeRecording => isEnglish
      ? 'You can still change this before each recording.'
      : '录制前仍会弹出确认，可临时修改。';
  String speedSecondsPerChapter(double value) => isEnglish
      ? 'Default speed ${value.toStringAsFixed(1)}s / chapter'
      : '默认播放速度 ${value.toStringAsFixed(1)} 秒/章';
  String speedLabel(double value) => isEnglish
      ? '${value.toStringAsFixed(1)}s / chapter'
      : '${value.toStringAsFixed(1)} 秒/章';
  String get howToUse => isEnglish ? 'How to use' : '怎么使用';
  String get commonEntrances => isEnglish ? 'Common actions' : '常见入口';
  String get privacyLocalStorage =>
      isEnglish ? 'Local storage & privacy' : '本地存储与隐私';
  String get privacyLocalStorageSubtitle => isEnglish
      ? 'Photos are not uploaded. Uninstalling the app removes exhibitions stored in its private space.'
      : '图片不会上传，卸载应用会删除应用私有空间中的展览。';
  String get importTemplateSubtitle => isEnglish
      ? 'Create a new exhibition from a local JSON template.'
      : '从本地 JSON 模板快速生成一个新展览。';
  String get copiedIntoApp => isEnglish ? 'Copy into app' : '复制到应用内';
  String get referenceOriginal =>
      isEnglish ? 'Reference original files' : '直接引用本地图片';
  String get copiedIntoAppDescription => isEnglish
      ? 'More reliable: Xulang keeps a copy, so the exhibition still works if the original file moves or is deleted. It uses more app storage.'
      : '更稳定：展览会保存一份原图，原文件移动或删除后仍可观看；代价是占用更多应用空间。';
  String get referenceOriginalDescription => isEnglish
      ? 'More space-saving: Xulang stores paths and thumbnails. If the original file moves or is deleted, the full image may not display.'
      : '更省空间：展览只记录原图路径并生成缩略图；如果你移动或删除原文件，展览里的大图可能无法显示。';
  String get currentChapter => isEnglish ? 'Current chapter' : '当前章节';
  String get fromCurrentToEnd => isEnglish ? 'Current to end' : '从当前到结尾';
  String get allChapters => isEnglish ? 'All chapters' : '全部章节';
  String get recordingAndShare => isEnglish ? 'Record & Share' : '录制与分享';
  String get recordingSheetDescription => isEnglish
      ? 'After confirmation, Xulang enters immersive playback, records the screen, then opens the system share panel when the MP4 file is ready.'
      : '确认后会进入沉浸播放，完成录制并检测到 MP4 文件后，再弹出系统分享面板。';
  String get chapterRange => isEnglish ? 'Chapter range' : '章节范围';
  String playbackSpeed(double value) => isEnglish
      ? 'Playback speed ${value.toStringAsFixed(1)}s / chapter'
      : '播放速度 ${value.toStringAsFixed(1)} 秒/章';
  String get useBackgroundMusic =>
      isEnglish ? 'Use background music' : '使用背景音乐';
  String get noBackgroundMusic =>
      isEnglish ? 'No background music' : '当前展览没有背景音乐';
  String get cancel => isEnglish ? 'Cancel' : '取消';
  String get startRecordingPlayback => isEnglish ? 'Start recording' : '开始录制播放';
  String get androidRecordingOnly => isEnglish
      ? 'Automatic recording is currently available on Android only. You can still use the system recorder and share manually.'
      : '当前自动录屏仅支持 Android；可使用系统录屏后再分享。';
  String get cannotStartRecording =>
      isEnglish ? 'Could not start recording' : '无法开始录屏';
  String get recordingFileMissing => isEnglish
      ? 'Recording finished, but the MP4 file was not found.'
      : '录制结束，但没有找到生成的视频文件。';
  String get recordingStopFailed =>
      isEnglish ? 'Could not finish recording' : '录屏结束失败';
  String get preparingShare =>
      isEnglish ? 'Preparing video for sharing…' : '正在准备分享视频…';
  String get recordingVideoSuffix => isEnglish ? 'recording video' : '录制视频';
  String get recordPermissionHint => isEnglish
      ? 'Android requires screen-capture permission for every recording session; apps cannot turn it into an always-allow permission.'
      : 'Android 录屏授权每次会由系统确认，应用不能把它改成“一直允许”。';
  String usageStepTitle(int step) => switch (step) {
    1 => isEnglish ? '1. Create categories by theme' : '1. 先按主题建立分类',
    2 =>
      isEnglish
          ? '2. Create an exhibition and import photos'
          : '2. 在分类里新建展览并导入图片',
    3 =>
      isEnglish
          ? '3. Tune canvas, layout, frames and stickers'
          : '3. 调整画布、布局、相框和贴画',
    _ => isEnglish ? '4. Play or export templates' : '4. 进入播放或导出模板',
  };
  String usageStepBody(int step) => switch (step) {
    1 =>
      isEnglish
          ? 'Categories work like boxes for travel, sports, family and other stories.'
          : '分类像盒子，适合把旅行、运动、家庭等展览分开收纳。',
    2 =>
      isEnglish
          ? 'Each exhibition can organize photos into chapters. Materials stay on this device.'
          : '每个展览都可以分章节组织图片，素材仍保存在本机。',
    3 =>
      isEnglish
          ? 'Use the editor panel to switch canvas, image, sticker and music controls.'
          : '编辑页右侧操作面板可切换画布、图片、贴画和音乐设置。',
    _ =>
      isEnglish
          ? 'Playback previews the rhythm; templates let you reuse the current layout.'
          : '播放页用来预览完整叙事节奏，模板可复用当前布局。',
  };
}

extension AppLanguageResolve on AppLanguage {
  AppLanguage resolve(Locale? locale) {
    return switch (this) {
      AppLanguage.system =>
        locale?.languageCode.toLowerCase() == 'zh'
            ? AppLanguage.chinese
            : AppLanguage.english,
      AppLanguage.chinese => AppLanguage.chinese,
      AppLanguage.english => AppLanguage.english,
    };
  }

  Locale? toLocale() {
    return switch (this) {
      AppLanguage.system => null,
      AppLanguage.chinese => const Locale('zh'),
      AppLanguage.english => const Locale('en'),
    };
  }
}
