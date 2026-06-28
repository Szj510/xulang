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
  String get languageSetting => isEnglish ? 'Language' : '语言';
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
  String get play => isEnglish ? 'Play' : '播放';
  String get edit => isEnglish ? 'Edit' : '编辑';
  String get delete => isEnglish ? 'Delete' : '删除';
  String get rename => isEnglish ? 'Rename' : '重命名';
  String get duplicateExhibition => isEnglish ? 'Duplicate exhibition' : '复制展览';
  String get moveCategory => isEnglish ? 'Move category' : '移动分类';
  String get moreActions => isEnglish ? 'More actions' : '更多操作';
  String get createFirstExhibition => isEnglish ? 'Create first exhibition' : '创建第一个展览';
  String get officialSampleSuffix => isEnglish ? 'Official sample' : '官方示例';
  String get back => isEnglish ? 'Back' : '返回';
  String get undo => isEnglish ? 'Undo' : '撤销';
  String get redo => isEnglish ? 'Redo' : '重做';
  String get immersiveView => isEnglish ? 'Immersive view' : '沉浸观看';
  String get exportAndShare => isEnglish ? 'Export & share' : '导出与分享';
  String get shareTemplate => isEnglish ? 'Share template' : '分享模板';
  String get recordAndShareVideo => isEnglish ? 'Record & share video' : '录制并分享视频';
  String get chapters => isEnglish ? 'Chapters' : '章节';
  String get addChapter => isEnglish ? 'Add chapter' : '添加章节';
  String get renameExhibition => isEnglish ? 'Rename exhibition' : '重命名展览';
  String get save => isEnglish ? 'Save' : '保存';
  String get clear => isEnglish ? 'Clear' : '清除';
  String get choose => isEnglish ? 'Choose' : '选择';
  String get ok => isEnglish ? 'OK' : '知道了';
  String get previousChapter => isEnglish ? 'Previous chapter' : '上一章';
  String get nextChapter => isEnglish ? 'Next chapter' : '下一章';
  String get exitViewer => isEnglish ? 'Exit viewer' : '退出观看';
  String get recordingMode => isEnglish ? 'Recording mode' : '录屏模式';
  String get recordingSpeed => isEnglish ? 'Recording speed' : '录屏速度';
  String get pauseMusic => isEnglish ? 'Pause music' : '暂停音乐';
  String get playMusic => isEnglish ? 'Play music' : '播放音乐';
  String get fast3s => isEnglish ? 'Fast (3s)' : '快 (3s)';
  String get medium6s => isEnglish ? 'Medium (6s)' : '中 (6s)';
  String get slow10s => isEnglish ? 'Slow (10s)' : '慢 (10s)';
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
  String get recordingResult => isEnglish ? 'Recording result' : '录制结果';
  String get share => isEnglish ? 'Share' : '分享';
  String get recordingSaved => isEnglish ? 'Recording saved' : '录制已保存';
  String recordingSavedWithSize(String size) => isEnglish ? 'Recording saved · $size' : '录制已保存 · $size';
  String get videoPreviewFailed => isEnglish ? 'Unable to preview this video. You can still share the MP4 file.' : '无法预览这个视频，但仍可以分享生成的 MP4 文件。';
  String get uncategorized => isEnglish ? 'Uncategorized' : '未分类';
  String exhibitionCount(int count) => isEnglish ? '$count exhibitions' : '$count 个展览';
  String photoCount(int count) => isEnglish ? '$count photos' : '$count 张照片';
  String get backToCategories => isEnglish ? 'Back to categories' : '返回分类';
  String get searchExhibitions => isEnglish ? 'Search exhibitions' : '搜索展览';
  String get sortByTime => isEnglish ? 'By time' : '按时间';
  String get sortByName => isEnglish ? 'By name' : '按名称';
  String get emptyCategory => isEnglish ? 'No exhibitions yet' : '这里还没有展览';
  String get newExhibitionTitle => isEnglish ? 'New exhibition' : '新建展览';
  String get exhibitionName => isEnglish ? 'Exhibition name' : '展览名称';
  String get create => isEnglish ? 'Create' : '创建';
  String get deleteExhibitionTitle => isEnglish ? 'Delete exhibition?' : '删除展览？';
  String deleteExhibitionBody(String title) => isEnglish ? '“$title” and copied images in the app will be permanently deleted.' : '“$title”及复制到应用中的图片会被永久删除。';
  String get cannotReadExhibitions => isEnglish ? 'Unable to read exhibitions' : '无法读取展览';
  String get moveToCategory => isEnglish ? 'Move to category' : '移动到分类';
  String monthDay(DateTime date) => isEnglish ? '${date.month}/${date.day}' : '${date.month}月${date.day}日';
  String get importImages => isEnglish ? 'Import images' : '导入图片';
  String get importing => isEnglish ? 'Importing' : '导入中';
  String get canvasAndStory => isEnglish ? 'Canvas & story' : '画布与叙事';
  String get layout => isEnglish ? 'Layout' : '布局';
  String get storyLine => isEnglish ? 'Story line' : '路径线条';
  String get playbackSettings => isEnglish ? 'Playback settings' : '播放设置';
  String get operationPanel => isEnglish ? 'Panel' : '操作面板';
  String get canvas => isEnglish ? 'Canvas' : '画布';
  String get image => isEnglish ? 'Image' : '图片';
  String get sticker => isEnglish ? 'Sticker' : '贴画';
  String get stickers => isEnglish ? 'Stickers' : '贴画';
  String get addedStickers => isEnglish ? 'Added stickers' : '已添加贴画';
  String get recordingSavedOpenResult => isEnglish ? 'Recording saved. Review it before sharing.' : '录制已保存，请查看效果后再分享。';
  String exhibitionDisplayTitle(String id, String title) {
    if (id == 'sample-exhibition') {
      return isEnglish
          ? 'Between Mountains and Sea (Official sample)'
          : title.contains('官方示例')
              ? title
              : '$title（官方示例）';
    }
    return title;
  }

  String chapterTitle(String id, String fallback) {
    if (!isEnglish) return fallback;
    return switch (id) {
      'sample-chapter-1' => 'Direction of the Tide',
      'sample-chapter-2' => 'Summer Walk',
      _ => fallback,
    };
  }

  String chapterCaption(String id, String fallback) {
    if (!isEnglish) return fallback;
    return switch (id) {
      'sample-chapter-1' => 'Walking along the coast, the wind slowly pulls the horizon closer.',
      'sample-chapter-2' => 'The breeze moved through the hair and through that unhurried slice of time.',
      _ => fallback,
    };
  }

  String placementCaption(String id, String fallback) {
    if (!isEnglish) return fallback;
    return switch (id) {
      'sample-placement-3' => 'Departure',
      'sample-placement-4' => 'Alley encounter',
      'sample-placement-5' => 'Sea breeze',
      'sample-placement-6' => 'Way home',
      _ => fallback,
    };
  }

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
