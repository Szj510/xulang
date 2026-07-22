import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/providers/app_providers.dart';

class AppStrings {
  const AppStrings._(this.language);

  final AppLanguage language;

  static AppStrings of(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context);
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final settings = container
          .read(appSettingsProvider)
          .maybeWhen(data: (value) => value, orElse: () => const AppSettings());
      return AppStrings._(settings.language.resolve(locale));
    } on StateError {
      return AppStrings._(AppLanguage.system.resolve(locale));
    }
  }

  static AppStrings from(AppSettings settings, [Locale? locale]) {
    return AppStrings._(settings.language.resolve(locale));
  }

  bool get isEnglish => language == AppLanguage.english;

  String get renameCategory => isEnglish ? 'Rename category' : '重命名分类';
  String get deleteCategoryTitle => isEnglish ? 'Delete category?' : '删除分类？';
  String deleteCategoryBody(String title) => isEnglish
      ? 'Exhibitions in "$title" will be moved to Uncategorized. The exhibitions and photos will not be deleted.'
      : '“$title”里的展览会移到未分类；展览和图片不会被删除。';
  String get manageMusic => isEnglish ? 'Manage music' : '管理音乐';
  String get musicLibrary => isEnglish ? 'Music library' : '音乐库';
  String get templateLibrary => isEnglish ? 'Template library' : '模板库';
  String get authorizeFolder => isEnglish ? 'Authorize folder' : '授权文件夹';
  String get localPath => isEnglish ? 'Local path' : '本地路径';
  String get copyPath => isEnglish ? 'Copy path' : '复制路径';
  String get chooseImagesByChapter =>
      isEnglish ? 'Choose images by chapter' : '按章节选择图片';
  String chapterNeedsImages(String title, int count) =>
      isEnglish ? '$title needs $count images.' : '$title 需要 $count 张图片。';
  String extraImagesHint(int count) => isEnglish
      ? '$count extra images will be added with plain default frames.'
      : '多出的 $count 张图片会以默认无画框方式追加。';
  String missingImagesHint(int count) => isEnglish
      ? '$count empty slots will be skipped.'
      : '缺少的 $count 个槽位会跳过，不生成图片卡片。';
  String get recordingFileName => isEnglish ? 'Video file name' : '视频文件名';
  String get renameVideo => isEnglish ? 'Rename video' : '重命名视频';
  String get playbackSpeedTitle => isEnglish ? 'Playback speed' : '播放速度';
  String get fastSpeed => isEnglish ? 'Fast' : '快';
  String get mediumSpeed => isEnglish ? 'Medium' : '中';
  String get slowSpeed => isEnglish ? 'Slow' : '慢';
  String get buttonTooltipHint => isEnglish
      ? 'Tip: long-press icon-only buttons to see what they do.'
      : '提示：长按无文字说明的图标按钮可以查看功能注释。';
  String get doubleTapPlaybackHint => isEnglish
      ? 'Double-tap in playback to pause/exit preview; double-tap while recording to finish and open the result.'
      : '播放页双击可暂停或退出预览；录屏中双击会结束录制并打开结果页。';
  String get cleanupUnusedMedia => isEnglish ? 'Clean unused media' : '清理未使用素材';
  String get cleanupUnusedMediaSubtitle => isEnglish
      ? 'Remove app-private image copies and thumbnails that are no longer used by any exhibition. External referenced photos are not touched.'
      : '删除不再被任何展览使用的应用内原图副本和缩略图；不会删除外部引用的相册图片。';
  String get cleanupUnusedMediaConfirm => isEnglish
      ? 'This removes only files in Xulang private storage that are not referenced by any exhibition. Photos in your gallery or authorized folders are kept.'
      : '只会删除叙廊私有空间里未被任何展览引用的文件；相册或授权文件夹中的原文件不会被删除。';
  String cleanupUnusedMediaResult(int count, String size) => isEnglish
      ? 'Cleaned $count files, freed $size.'
      : '已清理 $count 个文件，释放 $size。';

  String get appTitle => isEnglish ? 'Xulang' : '叙廊';
  String get localGallery => isEnglish ? 'Your local gallery' : '你的本地展览';
  String get newExhibition => isEnglish ? 'New' : '新建';
  String get localStorageInfo => isEnglish ? 'Local storage' : '本地存储说明';
  String get settingsAndGuide => isEnglish ? 'Settings & Guide' : '设置与使用说明';
  String get importTemplate => isEnglish ? 'Import template' : '导入模板';
  String get newCategory => isEnglish ? 'New category' : '新建分类';
  String get quickAccess => isEnglish ? 'Shortcuts' : '快捷';
  String get libraryInfo => isEnglish ? 'About' : '关于';
  String get librarySettings => isEnglish ? 'Settings' : '设置';
  String get libraryRecordings => isEnglish ? 'Recordings' : '录制';
  String get libraryMusic => isEnglish ? 'Music' : '音乐';
  String get libraryImport => isEnglish ? 'Import' : '导入';
  String get libraryCategories => isEnglish ? 'Categories' : '分类';
  String get changeHomeHero => isEnglish ? 'Change cover' : '更换头图';
  String get homeAppearance => isEnglish ? 'Home appearance' : '首页外观';
  String get homeCover => isEnglish ? 'Home cover' : '首页头图';
  String get homeCoverSettingHint => isEnglish
      ? 'Choose a custom image or restore the Mountains and Sea sample.'
      : '选择自定义图片，或恢复“山海之间”示例图片。';
  String get chooseHomeHeroImage =>
      isEnglish ? 'Choose a custom cover' : '选择自定义头图';
  String get chooseHomeHeroImageHint => isEnglish
      ? 'The image is copied into Xulang private storage.'
      : '图片会复制到叙廊的私有存储中。';
  String get restoreDefaultHomeHero =>
      isEnglish ? 'Use the default cover' : '使用默认头图';
  String get defaultHomeHeroHint => isEnglish
      ? 'Restore the Mountains and Sea sample image.'
      : '恢复“山海之间”示例图片。';
  String get homeHeroUpdated => isEnglish ? 'Home cover updated' : '首页头图已更新';
  String get recordingPlayback => isEnglish ? 'Recording playback' : '录屏播放';
  String get languageSetting => isEnglish ? 'Language' : '语言';
  String get themeSetting => isEnglish ? 'Theme' : '主题';
  String get followSystem => isEnglish ? 'Follow system' : '跟随系统';
  String get lightTheme => isEnglish ? 'Light' : '明亮';
  String get darkTheme => isEnglish ? 'Dark' : '暗黑';
  String get simplifiedChinese => isEnglish ? 'Simplified Chinese' : '简体中文';
  String get english => isEnglish ? 'English' : '英文';
  String get showChapterTitleRecording =>
      isEnglish ? 'Show chapter title while recording' : '录屏时显示章节名';
  String get showChapterTitleRecordingSubtitle => isEnglish
      ? 'Turn this off to record only the canvas and photos.'
      : '关闭后，沉浸录屏只保留画布和图片。';
  String get mediaImportMode => isEnglish ? 'Image import mode' : '图片导入方式';
  String get recordingDefaults => isEnglish ? 'Recording defaults' : '录制默认值';
  String get recordingQuality => isEnglish ? 'Recording quality' : '录制清晰度';
  String get recordingQualityHint => isEnglish
      ? 'Lower quality creates smaller files; higher quality keeps sharper details.'
      : '清晰度越低文件越小，清晰度越高细节越锐。';
  String get standardQuality => isEnglish ? 'Standard' : '标准';
  String get highQuality => isEnglish ? 'High' : '高清';
  String get ultraQuality => isEnglish ? 'Ultra' : '超清';
  String get defaultRecordingChapters =>
      isEnglish ? 'Default chapters' : '默认录制章节';
  String get useMusicByDefault =>
      isEnglish ? 'Use music by default' : '默认使用背景音乐';
  String get canChangeBeforeRecording => isEnglish
      ? 'You can still change this before each recording.'
      : '录制前仍会弹出确认，可临时修改。';
  String speedSecondsPerChapter(double value) => isEnglish
      ? 'Default speed ${value.toStringAsFixed(1)}s / photo'
      : '默认播放速度 ${value.toStringAsFixed(1)} 秒 / 张图片';
  String speedLabel(double value) => isEnglish
      ? '${value.toStringAsFixed(1)}s / photo'
      : '${value.toStringAsFixed(1)} 秒 / 张图片';
  String get howToUse => isEnglish ? 'How to use' : '怎么使用';
  String get commonEntrances => isEnglish ? 'Common actions' : '常见入口';
  String get privacyLocalStorage =>
      isEnglish ? 'Local storage & privacy' : '本地存储与隐私';
  String get privacyLocalStorageSubtitle => isEnglish
      ? 'Photos are not uploaded. Uninstalling the app removes exhibitions stored in its private space.'
      : '图片不会上传，卸载应用会删除应用私有空间中的展览。';
  String get aboutAndOpenSource => isEnglish ? 'About & open source' : '关于与开源';
  String get aboutAndOpenSourceSubtitle => isEnglish
      ? 'Version, source code, licenses, privacy, and security.'
      : '版本、源码、许可证、隐私与安全说明。';
  String get localOnlyTitle => isEnglish ? 'Made for this device' : '只属于这台设备';
  String get localOnlyBody => isEnglish
      ? 'Xulang does not upload photos and does not request network access. Imported media stays in app-private storage; uninstalling the app permanently removes those exhibitions.'
      : '叙廊不上传图片，也不申请网络权限。导入内容保留在应用私有空间；卸载应用会永久删除这些展览。';
  String get localFirstPromise => isEnglish
      ? 'Your photos, stories, music, templates, and recordings stay local unless you explicitly share them.'
      : '你的图片、故事、音乐、模板和录像默认只保留在本地，除非你主动分享。';
  String versionAndBuild(String version, String build) =>
      isEnglish ? 'Version $version ($build)' : '版本 $version（$build）';
  String get sourceCode => isEnglish ? 'Source code' : '源代码';
  String get sourceCodeSubtitle =>
      isEnglish ? 'Browse Xulang on GitHub.' : '在 GitHub 查看叙廊源码。';
  String get latestRelease => isEnglish ? 'Latest release' : '最新版本';
  String get latestReleaseSubtitle =>
      isEnglish ? 'Download the official Android APK.' : '下载官方 Android APK。';
  String get privacyPolicy => isEnglish ? 'Privacy policy' : '隐私政策';
  String get privacyPolicySubtitle => isEnglish
      ? 'Read how local files and sharing are handled.'
      : '了解本地文件、分享与卸载行为。';
  String get securityReport => isEnglish ? 'Report a security issue' : '报告安全问题';
  String get securityReportSubtitle => isEnglish
      ? 'Use GitHub private vulnerability reporting.'
      : '使用 GitHub 私密漏洞报告，请勿创建公开 Issue。';
  String get openSourceLicenses => isEnglish ? 'Open-source licenses' : '开源许可证';
  String get openSourceLicensesSubtitle => isEnglish
      ? 'GPL-3.0 and bundled third-party notices.'
      : 'GPL-3.0 与随应用分发的第三方许可证。';
  String get unableToOpenLink =>
      isEnglish ? 'Unable to open this link.' : '无法打开该链接。';
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
  String get playbackPreview => isEnglish ? 'Playback preview' : '播放预览';
  String get generatedVideos => isEnglish ? 'Generated videos' : '生成的视频';
  String get scanningMusic => isEnglish ? 'Scanning music files…' : '正在查找音乐文件…';
  String get scanningTemplates =>
      isEnglish ? 'Scanning template files…' : '正在查找模板文件…';
  String get refreshingLocalFiles =>
      isEnglish ? 'Refreshing local files in the background…' : '正在后台刷新本地文件…';
  String get shareOriginalVideoHint => isEnglish
      ? 'Sharing sends the original MP4 file. Some apps, including WeChat, may still compress video after receiving it.'
      : '分享会发送原始 MP4 文件。微信等应用接收后仍可能二次压缩画质。';
  String get manageVideos => isEnglish ? 'Manage videos' : '管理生成的视频';
  String get noGeneratedVideos =>
      isEnglish ? 'No generated videos yet' : '还没有生成的视频';
  String get deleteVideoTitle => isEnglish ? 'Delete video?' : '删除视频？';
  String get deleteVideoBody => isEnglish
      ? 'This only deletes the generated MP4 file. Your exhibition is kept.'
      : '只会删除生成的 MP4 文件，展览内容不会受影响。';
  String get recordingSheetDescription => isEnglish
      ? 'After confirmation, Xulang enters immersive playback, records the screen, then opens the result page when the MP4 file is ready.'
      : '确认后会进入沉浸播放，完成录制并检测到 MP4 文件后，再打开结果页。';
  String get chapterRange => isEnglish ? 'Chapter range' : '章节范围';
  String playbackSpeed(double value) => isEnglish
      ? 'Playback speed ${value.toStringAsFixed(1)}s / photo'
      : '播放速度 ${value.toStringAsFixed(1)} 秒/张';
  String get useBackgroundMusic =>
      isEnglish ? 'Use background music' : '使用背景音乐';
  String get noBackgroundMusic =>
      isEnglish ? 'No background music' : '当前展览没有背景音乐';
  String get cancel => isEnglish ? 'Cancel' : '取消';
  String get startRecordingPlayback => isEnglish ? 'Start recording' : '开始录制播放';
  String get play => isEnglish ? 'Play' : '播放';
  String get edit => isEnglish ? 'Edit' : '编辑';
  String get delete => isEnglish ? 'Delete' : '删除';
  String get deleteImage => isEnglish ? 'Delete image' : '删除图片';
  String get rename => isEnglish ? 'Rename' : '重命名';
  String get duplicateExhibition => isEnglish ? 'Duplicate exhibition' : '复制展览';
  String get moveCategory => isEnglish ? 'Move category' : '移动分类';
  String get moreActions => isEnglish ? 'More actions' : '更多操作';
  String get createFirstExhibition =>
      isEnglish ? 'Create first exhibition' : '创建第一个展览';
  String get officialSampleSuffix => isEnglish ? 'Official sample' : '官方示例';
  String get back => isEnglish ? 'Back' : '返回';
  String get undo => isEnglish ? 'Undo' : '撤销';
  String get redo => isEnglish ? 'Redo' : '重做';
  String get immersiveView => isEnglish ? 'Immersive view' : '沉浸观看';
  String get exportAndShare => isEnglish ? 'Export & share' : '导出与分享';
  String get shareTemplate => isEnglish ? 'Share template' : '分享模板';
  String get recordAndShareVideo =>
      isEnglish ? 'Record & share video' : '录制并分享视频';
  String get chapters => isEnglish ? 'Chapters' : '章节';
  String get addChapter => isEnglish ? 'Add chapter' : '添加章节';
  String get renameExhibition => isEnglish ? 'Rename exhibition' : '重命名展览';
  String get save => isEnglish ? 'Save' : '保存';
  String get clear => isEnglish ? 'Clear' : '清除';
  String get choose => isEnglish ? 'Choose' : '选择';
  String get ok => isEnglish ? 'OK' : '知道了';
  String get close => isEnglish ? 'Close' : '关闭';
  String get previousChapter => isEnglish ? 'Previous chapter' : '上一章';
  String get nextChapter => isEnglish ? 'Next chapter' : '下一章';
  String get exitViewer => isEnglish ? 'Exit viewer' : '退出观看';
  String get recordingMode => isEnglish ? 'Recording mode' : '录屏模式';
  String get recordingSpeed => playbackSpeedTitle;
  String get pauseMusic => isEnglish ? 'Pause music' : '暂停音乐';
  String get playMusic => isEnglish ? 'Play music' : '播放音乐';
  String get musicPlaybackFailed =>
      isEnglish ? 'Unable to play the background music' : '背景音乐播放失败，请重新选择音乐';
  String get fast3s => isEnglish ? 'Fast (1s/photo)' : '快（1秒/张）';
  String get medium6s => isEnglish ? 'Medium (3s/photo)' : '中（3秒/张）';
  String get slow10s => isEnglish ? 'Slow (6s/photo)' : '慢（6秒/张）';
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
  String recordingSavedWithSize(String size) =>
      isEnglish ? 'Recording saved · $size' : '录制已保存 · $size';
  String get videoPreviewFailed => isEnglish
      ? 'Unable to preview this video. You can still share the MP4 file.'
      : '无法预览这个视频，但仍可以分享生成的 MP4 文件。';
  String get uncategorized => isEnglish ? 'Uncategorized' : '未分类';
  String exhibitionCount(int count) =>
      isEnglish ? '$count exhibitions' : '$count 个展览';
  String photoCount(int count) => isEnglish ? '$count photos' : '$count 张照片';
  String get backToCategories => isEnglish ? 'Back to categories' : '返回分类';
  String get searchExhibitions => isEnglish ? 'Search exhibitions' : '搜索展览';
  String get sortByTime => isEnglish ? 'By time' : '按时间';
  String get sortByName => isEnglish ? 'By name' : '按名称';
  String get emptyCategory => isEnglish ? 'No exhibitions yet' : '这里还没有展览';
  String get newExhibitionTitle => isEnglish ? 'New exhibition' : '新建展览';
  String get exhibitionName => isEnglish ? 'Exhibition name' : '展览名称';
  String get create => isEnglish ? 'Create' : '创建';
  String get deleteExhibitionTitle =>
      isEnglish ? 'Delete exhibition?' : '删除展览？';
  String deleteExhibitionBody(String title) => isEnglish
      ? '“$title” and copied images in the app will be permanently deleted.'
      : '“$title”及复制到应用中的图片会被永久删除。';
  String get cannotReadExhibitions =>
      isEnglish ? 'Unable to read exhibitions' : '无法读取展览';
  String get moveToCategory => isEnglish ? 'Move to category' : '移动到分类';
  String monthDay(DateTime date) =>
      isEnglish ? '${date.month}/${date.day}' : '${date.month}月${date.day}日';
  String get importImages => isEnglish ? 'Import images' : '导入图片';
  String get importing => isEnglish ? 'Importing' : '导入中';
  String importImagesWithCapacity(int current) => isEnglish
      ? 'Import $current/$maxGalleryPlacementsPerChapter'
      : '导入 $current/$maxGalleryPlacementsPerChapter';
  String galleryCapacityMessage(int skipped) => isEnglish
      ? 'Each chapter supports up to $maxGalleryPlacementsPerChapter photos.'
            '${skipped > 0 ? ' $skipped extra photos were skipped.' : ''}'
      : '每个章节最多支持 $maxGalleryPlacementsPerChapter 张图片。'
            '${skipped > 0 ? ' 已跳过多选的 $skipped 张。' : ''}';
  String get canvasAndStory => isEnglish ? 'Canvas & story' : '画布与叙事';
  String get layout => isEnglish ? 'Layout' : '布局';
  String get storyLine => isEnglish ? 'Story line' : '路径线条';
  String get playbackSettings => isEnglish ? 'Playback settings' : '播放设置';
  String get operationPanel => isEnglish ? 'Panel' : '操作面板';
  String get canvas => isEnglish ? 'Canvas' : '画布';
  String get image => isEnglish ? 'Image' : '图片';
  String get sticker => isEnglish ? 'Sticker' : '贴画';
  String get stickers => isEnglish ? 'Stickers' : '贴画';
  String get decoration => isEnglish ? 'Decorate' : '装饰';
  String get decorations => isEnglish ? 'Decorations' : '装饰';
  String get textDecoration => isEnglish ? 'Text' : '文字';
  String get addedStickers => isEnglish ? 'Added stickers' : '已添加贴画';
  String get canvasTheme => isEnglish ? 'Canvas theme' : '画布主题';
  String get inkCanvas => isEnglish ? 'Ink canvas' : '墨色画布';
  String get paperCanvas => isEnglish ? 'Paper canvas' : '纸张画布';
  String get graphiteCanvas => isEnglish ? 'Graphite canvas' : '石墨画布';
  String get mistCanvas => isEnglish ? 'Mist canvas' : '雾蓝画布';
  String get warmSandCanvas => isEnglish ? 'Warm sand canvas' : '暖沙画布';
  String get moonlightRoom => isEnglish ? 'Moonlight room' : '月光暗房';
  String get botanicalSpecimen => isEnglish ? 'Botanical specimen' : '植物标本';
  String get cyanotype => isEnglish ? 'Cyanotype' : '蓝晒纸';
  String get terracottaGallery => isEnglish ? 'Terracotta gallery' : '陶土壁龛';
  String get starfieldCanvas => isEnglish ? 'Starfield canvas' : '星空画布';
  String get titleAndCaption => isEnglish ? 'Title & note' : '标题与短注释';
  String get panelOpacity => isEnglish ? 'Panel opacity' : '面板透明度';
  String get noBackgroundMusicAdded =>
      isEnglish ? 'No background music' : '未添加背景音乐';
  String get selectImageFirst => isEnglish
      ? 'Tap a photo to edit size, frame, crop and rotation here.'
      : '点击一张图片后，这里会显示图片大小、画框、裁切和旋转。';
  String get layerOrder => isEnglish ? 'Layer order' : '图层顺序';
  String get imageSize => isEnglish ? 'Image size' : '画幅';
  String get frameStyle => isEnglish ? 'Frame' : '画框';
  String get classicFrames => isEnglish ? 'Classic' : '经典';
  String get handDrawnFrames => isEnglish ? 'Hand-drawn' : '手绘';
  String get captionFrames => isEnglish ? 'Caption' : '题字';
  String get cropAndComposition => isEnglish ? 'Crop & composition' : '裁切与构图';
  String get horizontalFocus => isEnglish ? 'Horizontal focus' : '水平焦点';
  String get verticalFocus => isEnglish ? 'Vertical focus' : '垂直焦点';
  String get cropZoom => isEnglish ? 'Crop zoom' : '裁切缩放';
  String get rotationAngle => isEnglish ? 'Rotation' : '旋转角度';
  String get note => isEnglish ? 'Note' : '说明';
  String get singlePhotoCaption => isEnglish ? 'Photo note' : '单图短注释';
  String get singlePhotoCaptionHint => isEnglish
      ? 'Shown beside this photo only in the Story Path layout.'
      : '仅在故事路径布局中显示在这张图片的路径节点旁。';
  String get frameCaption => isEnglish ? 'Frame caption' : '相框题字';
  String get captionText => isEnglish ? 'Caption text' : '题字内容';
  String get canvasImage => isEnglish ? 'Canvas image' : '画布图片';
  String get customCanvasSet => isEnglish ? 'Custom canvas set' : '已设置自定义画布';
  String get audio => isEnglish ? 'Audio' : '音频';
  String get backgroundMusicAdded =>
      isEnglish ? 'Background music added' : '已添加背景音乐';
  String get stickerPanelHint => isEnglish
      ? 'Choose a small object, then tap the canvas to place it. Placed stickers can be dragged and rotated; tap the corner cross to delete.'
      : '选择一个小物品后，点击画布放置；已放置的贴画可以拖动、旋转，点右上角叉删除。';
  String get textDecorationHint => isEnglish
      ? 'Enter text and add it to the canvas. Select it to drag, resize or rotate.'
      : '输入文字后添加到画布；选中后可以拖动、缩放或旋转。';
  String get enterText => isEnglish ? 'Your text' : '输入文字';
  String get textStickerExample =>
      isEnglish ? 'A quiet afternoon' : '把日子过成想要的样子';
  String get fontStyle => isEnglish ? 'Typeface' : '字体风格';
  String get inkColor => isEnglish ? 'Ink color' : '墨色';
  String get addTextToCanvas => isEnglish ? 'Add text to canvas' : '添加文字到画布';
  String get addedText => isEnglish ? 'Added text' : '已添加文字';
  String get textSettings => isEnglish ? 'Text settings' : '文字设置';
  String get textSize => isEnglish ? 'Size' : '字号';
  String get deleteText => isEnglish ? 'Delete text' : '删除文字';
  String get systemFont => isEnglish ? 'System' : '系统';
  String get editorialFont => isEnglish ? 'Editorial' : '叙事宋体';
  String get handwritingFont => isEnglish ? 'Diary' : '日记手写';
  String get brushFont => isEnglish ? 'Brush' : '艺术笔触';
  String get chapterText => isEnglish ? 'Chapter text' : '章节文字';
  String get chapterTitleField => isEnglish ? 'Chapter title' : '章节标题';
  String get shortNote => isEnglish ? 'Short note' : '短注释';
  String get customCanvasImage => isEnglish ? 'Custom canvas image' : '自定义画布图片';
  String get replace => isEnglish ? 'Replace' : '更换';
  String get upload => isEnglish ? 'Upload' : '上传';
  String get canvasOpacity => isEnglish ? 'Canvas opacity' : '画布透明度';
  String get canvasImageHelp => isEnglish
      ? 'Uploaded images are layered above the built-in canvas, useful for texture, paper, or atmosphere backgrounds.'
      : '上传的图片会叠在当前内置画布上，适合做纹理、纸张或氛围底图。';
  String get heroLayout => isEnglish ? 'Hero' : '主视觉';
  String get filmstripLayout => isEnglish ? 'Filmstrip' : '横向胶片';
  String get diptychLayout => isEnglish ? 'Diptych' : '双联画';
  String get collageLayout => isEnglish ? 'Narrative collage' : '叙事拼贴';
  String get storyPathLayout => isEnglish ? 'Story path' : '故事路径';
  String get orbitLayout => isEnglish ? 'Orbit' : '星轨';
  String get small => isEnglish ? 'Small' : '小';
  String get medium => isEnglish ? 'Medium' : '中';
  String get large => isEnglish ? 'Large' : '大';
  String get solidLine => isEnglish ? 'Solid line' : '细线';
  String get dashedLine => isEnglish ? 'Dashed line' : '虚线';
  String get glowLine => isEnglish ? 'Glow' : '微光';
  String get hidden => isEnglish ? 'Hidden' : '隐藏';
  String get noFrame => isEnglish ? 'None' : '无';
  String get hairlineFrame => isEnglish ? 'Hairline' : '细线';
  String get matFrame => isEnglish ? 'Mat' : '相纸';
  String get stampFrame => isEnglish ? 'Stamp edge' : '邮票边';
  String get woodFrame => isEnglish ? 'Wood' : '木制';
  String get darkWoodFrame => isEnglish ? 'Dark wood' : '深木';
  String get metalFrame => isEnglish ? 'Metal' : '金属';
  String get vintageFrame => isEnglish ? 'Vintage' : '复古';
  String get filmFrame => isEnglish ? 'Film case' : '胶片匣';
  String get orbFrame => isEnglish ? 'Circle' : '圆形框';
  String get captionMatFrame => isEnglish ? 'Caption mat' : '留白题字';
  String get tapedPaperFrame => isEnglish ? 'Taped paper' : '胶带纸框';
  String get crayonFrame => isEnglish ? 'Oil pastel' : '油画棒';
  String get watercolorFrame => isEnglish ? 'Watercolor bloom' : '水彩花边';
  String get doodleTapeFrame => isEnglish ? 'Playful doodle' : '童趣涂鸦';
  String get scallopFrame => isEnglish ? 'Looped lace' : '环形花边';
  String get cornerSketchFrame => isEnglish ? 'Corner sketch' : '手绘角标';
  String get wavyFrame => isEnglish ? 'Wavy outline' : '波浪线框';
  String get starSticker => isEnglish ? 'Star mark' : '星芒标记';
  String get sparkleSticker => isEnglish ? 'Sparkle' : '碎光';
  String get heartSticker => isEnglish ? 'Warm heart' : '暖心印';
  String get leafSticker => isEnglish ? 'Shadow leaf' : '影叶';
  String get flowerSticker => isEnglish ? 'Dried flower' : '干花';
  String get crescentMoonSticker => isEnglish ? 'Crescent moon' : '月弯';
  String get fireflySticker => isEnglish ? 'Firefly' : '萤光';
  String get cometSticker => isEnglish ? 'Comet tail' : '彗尾';
  String get pressedPetalSticker => isEnglish ? 'Pressed petal' : '压花瓣';
  String get paperTapeSticker => isEnglish ? 'Paper tape' : '纸胶带';
  String get fogRibbonSticker => isEnglish ? 'Fog ribbon' : '雾缎';
  String get waxSealSticker => isEnglish ? 'Wax seal' : '蜡封';
  String get stickerRotation => isEnglish ? 'Rotation' : '旋转';
  String get deleteStickerOnCanvas =>
      isEnglish ? 'Tap the cross on the canvas to delete' : '在画布上点叉删除';
  String get recordingSavedOpenResult => isEnglish
      ? 'Recording saved. Review it before sharing.'
      : '录制已保存，请查看效果后再分享。';
  String exhibitionDisplayTitle(String id, String title) {
    if (id == 'sample-exhibition') {
      return isEnglish ? 'Between Mountains and Sea' : '山海之间';
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
      'sample-chapter-1' =>
        'Walking along the coast, the wind slowly pulls the horizon closer.',
      'sample-chapter-2' =>
        'The breeze moved through the hair and through that unhurried slice of time.',
      _ => fallback,
    };
  }

  String placementCaption(String id, String fallback) {
    if (!isEnglish) return fallback;
    return switch (id) {
      'sample-placement-3' => 'Lakeside train',
      'sample-placement-4' => 'Hillside path',
      'sample-placement-5' => 'Coastline',
      'sample-placement-6' => 'Sunset window',
      'sample-placement-7' => 'Glimmer in grass',
      _ => fallback,
    };
  }

  String get chapterImageCountMismatch =>
      isEnglish ? 'Image count differs from template' : '图片数量与模板不一致';
  String selectedImagesCount(int count) =>
      isEnglish ? 'Selected $count images.' : '已选择 $count 张图片。';
  String get continueImport => isEnglish ? 'Continue import' : '继续导入';
  String get noImagesSelected =>
      isEnglish ? 'No images were selected. Import cancelled.' : '未选择图片，已取消导入。';

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
