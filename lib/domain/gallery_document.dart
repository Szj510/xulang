enum GalleryLayout { hero, filmstrip, diptych, collage, storyPath, orbit }

const maxGalleryPlacementsPerChapter = 16;

enum GalleryMotion { pan, push, focus, unfold }

enum StoryPathStyle { solid, dashed, glow, none }

enum GalleryFrame {
  none,
  hairline,
  mat,
  stamp,
  wood,
  darkWood,
  metal,
  vintage,
  film,
  orb,
  captionMat,
  tapedPaper,
  crayon,
  watercolor,
  doodleTape,
  scallop,
  cornerSketch,
  wavy,
}

enum GallerySize { small, medium, large }

enum GalleryTheme {
  ink,
  paper,
  graphite,
  mist,
  warm,
  moonlight,
  botanical,
  cyanotype,
  terracotta,
  starfield,
}

enum ExhibitionSortMode { updatedDesc, titleAsc }

enum MediaImportMode { copyIntoApp, referenceOriginal }

enum RecordingChapterMode { current, fromCurrentToEnd, all }

enum AppLanguage { system, chinese, english }

enum AppThemeMode { system, light, dark }

enum RecordingQuality { standard, high, ultra }

class AppSettings {
  const AppSettings({
    this.recordingShowChapterTitle = true,
    this.recordingDelaySeconds = 0,
    this.mediaImportMode = MediaImportMode.copyIntoApp,
    this.recordingSpeed = 6.0,
    this.recordingUseMusic = true,
    this.recordingChapterMode = RecordingChapterMode.current,
    this.recordingQuality = RecordingQuality.high,
    this.language = AppLanguage.system,
    this.themeMode = AppThemeMode.system,
    this.authorizedFolderPaths = const [],
    this.musicDisplayNames = const {},
    this.homeHeroImagePath,
  });

  final bool recordingShowChapterTitle;

  /// Legacy hot-reload compatibility field.
  ///
  /// The app no longer uses a manual recording delay, but keeping this field
  /// avoids Flutter rejecting hot reload for already-running sessions that still
  /// have the old const class shape in memory.
  final int recordingDelaySeconds;
  final MediaImportMode mediaImportMode;
  final double recordingSpeed;
  final bool recordingUseMusic;
  final RecordingChapterMode recordingChapterMode;
  final RecordingQuality recordingQuality;
  final AppLanguage language;
  final AppThemeMode themeMode;
  final List<String> authorizedFolderPaths;
  final Map<String, String> musicDisplayNames;
  final String? homeHeroImagePath;

  AppSettings copyWith({
    bool? recordingShowChapterTitle,
    int? recordingDelaySeconds,
    MediaImportMode? mediaImportMode,
    double? recordingSpeed,
    bool? recordingUseMusic,
    RecordingChapterMode? recordingChapterMode,
    RecordingQuality? recordingQuality,
    AppLanguage? language,
    AppThemeMode? themeMode,
    List<String>? authorizedFolderPaths,
    Map<String, String>? musicDisplayNames,
    String? homeHeroImagePath,
    bool resetHomeHeroImage = false,
  }) {
    return AppSettings(
      recordingShowChapterTitle:
          recordingShowChapterTitle ?? this.recordingShowChapterTitle,
      recordingDelaySeconds:
          recordingDelaySeconds?.clamp(0, 0).toInt() ??
          this.recordingDelaySeconds,
      mediaImportMode: mediaImportMode ?? this.mediaImportMode,
      recordingSpeed:
          recordingSpeed?.clamp(0.1, 12.0).toDouble() ?? this.recordingSpeed,
      recordingUseMusic: recordingUseMusic ?? this.recordingUseMusic,
      recordingChapterMode: recordingChapterMode ?? this.recordingChapterMode,
      recordingQuality: recordingQuality ?? this.recordingQuality,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      authorizedFolderPaths:
          authorizedFolderPaths ?? this.authorizedFolderPaths,
      musicDisplayNames: musicDisplayNames ?? this.musicDisplayNames,
      homeHeroImagePath: resetHomeHeroImage
          ? null
          : homeHeroImagePath ?? this.homeHeroImagePath,
    );
  }
}

class GalleryCategoryInfo {
  const GalleryCategoryInfo({
    required this.id,
    required this.title,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// 自定义路径锚点数据
class CustomPathAnchor {
  const CustomPathAnchor({
    required this.x,
    required this.y,
    this.label = '',
    this.cp1x,
    this.cp1y,
    this.cp2x,
    this.cp2y,
  });

  final double x;
  final double y;
  final String label; // 锚点标签文字
  final double? cp1x; // 贝塞尔控制点1
  final double? cp1y;
  final double? cp2x; // 贝塞尔控制点2
  final double? cp2y;

  CustomPathAnchor copyWith({
    double? x,
    double? y,
    String? label,
    double? cp1x,
    double? cp1y,
    double? cp2x,
    double? cp2y,
  }) {
    return CustomPathAnchor(
      x: x ?? this.x,
      y: y ?? this.y,
      label: label ?? this.label,
      cp1x: cp1x ?? this.cp1x,
      cp1y: cp1y ?? this.cp1y,
      cp2x: cp2x ?? this.cp2x,
      cp2y: cp2y ?? this.cp2y,
    );
  }

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'label': label,
    'cp1x': cp1x,
    'cp1y': cp1y,
    'cp2x': cp2x,
    'cp2y': cp2y,
  };

  factory CustomPathAnchor.fromJson(Map<String, dynamic> json) {
    return CustomPathAnchor(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      label: json['label'] as String? ?? '',
      cp1x: (json['cp1x'] as num?)?.toDouble(),
      cp1y: (json['cp1y'] as num?)?.toDouble(),
      cp2x: (json['cp2x'] as num?)?.toDouble(),
      cp2y: (json['cp2y'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CustomPathAnchor &&
      x == other.x &&
      y == other.y &&
      label == other.label &&
      cp1x == other.cp1x &&
      cp1y == other.cp1y &&
      cp2x == other.cp2x &&
      cp2y == other.cp2y;

  @override
  int get hashCode => Object.hash(x, y, label, cp1x, cp1y, cp2x, cp2y);
}

class CustomPathPoint {
  const CustomPathPoint({required this.x, required this.y});

  final double x;
  final double y;

  CustomPathPoint copyWith({double? x, double? y}) {
    return CustomPathPoint(x: x ?? this.x, y: y ?? this.y);
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory CustomPathPoint.fromJson(Map<String, dynamic> json) {
    return CustomPathPoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CustomPathPoint && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

enum GalleryStickerKind {
  star,
  sparkle,
  heart,
  leaf,
  flower,
  crescentMoon,
  firefly,
  comet,
  pressedPetal,
  paperTape,
  fogRibbon,
  waxSeal,
  text,
}

enum GalleryTextFont { system, editorial, handwriting, brush }

class GallerySticker {
  const GallerySticker({
    required this.id,
    required this.kind,
    required this.x,
    required this.y,
    this.scale = 1,
    this.rotation = 0,
    this.text = '',
    this.textFont = GalleryTextFont.handwriting,
    this.textColor = 0xFF2C241B,
  });

  final String id;
  final GalleryStickerKind kind;
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final String text;
  final GalleryTextFont textFont;
  final int textColor;

  bool get isText => kind == GalleryStickerKind.text;

  GallerySticker copyWith({
    GalleryStickerKind? kind,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    String? text,
    GalleryTextFont? textFont,
    int? textColor,
  }) {
    return GallerySticker(
      id: id,
      kind: kind ?? this.kind,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      text: text ?? this.text,
      textFont: textFont ?? this.textFont,
      textColor: textColor ?? this.textColor,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'x': x,
    'y': y,
    'scale': scale,
    'rotation': rotation,
    if (isText) 'text': text,
    if (isText) 'textFont': textFont.name,
    if (isText) 'textColor': textColor,
  };

  factory GallerySticker.fromJson(Map<String, dynamic> json) {
    return GallerySticker(
      id: json['id'] as String,
      kind: _enumByName(
        GalleryStickerKind.values,
        json['kind'] as String? ?? GalleryStickerKind.star.name,
        GalleryStickerKind.star,
      ),
      x: ((json['x'] as num?) ?? 0.5).toDouble(),
      y: ((json['y'] as num?) ?? 0.5).toDouble(),
      scale: ((json['scale'] as num?) ?? 1).toDouble(),
      rotation: ((json['rotation'] as num?) ?? 0).toDouble(),
      text: json['text'] as String? ?? '',
      textFont: _enumByName(
        GalleryTextFont.values,
        json['textFont'] as String? ?? GalleryTextFont.handwriting.name,
        GalleryTextFont.handwriting,
      ),
      textColor: (json['textColor'] as num?)?.toInt() ?? 0xFF2C241B,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GallerySticker &&
      id == other.id &&
      kind == other.kind &&
      x == other.x &&
      y == other.y &&
      scale == other.scale &&
      rotation == other.rotation &&
      text == other.text &&
      textFont == other.textFont &&
      textColor == other.textColor;

  @override
  int get hashCode =>
      Object.hash(id, kind, x, y, scale, rotation, text, textFont, textColor);
}

T _enumByName<T extends Enum>(List<T> values, String name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

class CustomPathConnection {
  const CustomPathConnection({
    required this.id,
    required this.fromPlacementId,
    required this.toPlacementId,
    required this.points,
    this.note = '',
    this.noteX = 0.5,
    this.noteY = 0.5,
  });

  final String id;
  final String fromPlacementId;
  final String toPlacementId;
  final List<CustomPathPoint> points;
  final String note;
  final double noteX;
  final double noteY;

  CustomPathConnection copyWith({
    String? fromPlacementId,
    String? toPlacementId,
    List<CustomPathPoint>? points,
    String? note,
    double? noteX,
    double? noteY,
  }) {
    return CustomPathConnection(
      id: id,
      fromPlacementId: fromPlacementId ?? this.fromPlacementId,
      toPlacementId: toPlacementId ?? this.toPlacementId,
      points: points ?? this.points,
      note: note ?? this.note,
      noteX: noteX ?? this.noteX,
      noteY: noteY ?? this.noteY,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromPlacementId': fromPlacementId,
    'toPlacementId': toPlacementId,
    'points': [for (final point in points) point.toJson()],
    'note': note,
    'noteX': noteX,
    'noteY': noteY,
  };

  factory CustomPathConnection.fromJson(Map<String, dynamic> json) {
    return CustomPathConnection(
      id: json['id'] as String,
      fromPlacementId: json['fromPlacementId'] as String,
      toPlacementId: json['toPlacementId'] as String,
      points: [
        for (final item in (json['points'] as List? ?? const []))
          if (item is Map)
            CustomPathPoint.fromJson(Map<String, dynamic>.from(item)),
      ],
      note: json['note'] as String? ?? '',
      noteX: ((json['noteX'] as num?) ?? 0.5).toDouble(),
      noteY: ((json['noteY'] as num?) ?? 0.5).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CustomPathConnection &&
      id == other.id &&
      fromPlacementId == other.fromPlacementId &&
      toPlacementId == other.toPlacementId &&
      _listEquals(points, other.points) &&
      note == other.note &&
      noteX == other.noteX &&
      noteY == other.noteY;

  @override
  int get hashCode => Object.hash(
    id,
    fromPlacementId,
    toPlacementId,
    Object.hashAll(points),
    note,
    noteX,
    noteY,
  );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}

class GalleryDocument {
  const GalleryDocument({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.chapters,
    this.coverMediaId,
    this.categoryId,
    this.theme = GalleryTheme.ink,
    this.canvasBackgroundPath,
    this.canvasBackgroundOpacity = 0.32,
    this.musicPath,
    this.musicTitle,
    this.showChapterTitleInPlayback = true,
    this.playbackDelaySeconds = 0,
  });

  factory GalleryDocument.create({
    required String id,
    required String title,
    required DateTime createdAt,
  }) {
    return GalleryDocument(
      id: id,
      title: title,
      createdAt: createdAt,
      updatedAt: createdAt,
      chapters: [
        GalleryChapter(
          id: '$id-chapter-1',
          title: '第一章',
          order: 0,
          layout: GalleryLayout.hero,
          motion: GalleryMotion.push,
          placements: const [],
        ),
      ],
    );
  }

  final String id;
  final String title;
  final String? coverMediaId;
  final String? categoryId;
  final GalleryTheme theme;
  final String? canvasBackgroundPath;
  final double canvasBackgroundOpacity;
  final String? musicPath;
  final String? musicTitle;
  final bool showChapterTitleInPlayback;
  final int playbackDelaySeconds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<GalleryChapter> chapters;

  GalleryDocument copyWith({
    String? title,
    String? coverMediaId,
    Object? categoryId = _unchanged,
    GalleryTheme? theme,
    Object? canvasBackgroundPath = _unchanged,
    double? canvasBackgroundOpacity,
    Object? musicPath = _unchanged,
    Object? musicTitle = _unchanged,
    bool? showChapterTitleInPlayback,
    int? playbackDelaySeconds,
    DateTime? updatedAt,
    List<GalleryChapter>? chapters,
  }) {
    return GalleryDocument(
      id: id,
      title: title ?? this.title,
      coverMediaId: coverMediaId ?? this.coverMediaId,
      categoryId: identical(categoryId, _unchanged)
          ? this.categoryId
          : categoryId as String?,
      theme: theme ?? this.theme,
      canvasBackgroundPath: identical(canvasBackgroundPath, _unchanged)
          ? this.canvasBackgroundPath
          : canvasBackgroundPath as String?,
      canvasBackgroundOpacity:
          canvasBackgroundOpacity?.clamp(0, 1).toDouble() ??
          this.canvasBackgroundOpacity,
      musicPath: identical(musicPath, _unchanged)
          ? this.musicPath
          : musicPath as String?,
      musicTitle: identical(musicTitle, _unchanged)
          ? this.musicTitle
          : musicTitle as String?,
      showChapterTitleInPlayback:
          showChapterTitleInPlayback ?? this.showChapterTitleInPlayback,
      playbackDelaySeconds: playbackDelaySeconds ?? this.playbackDelaySeconds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      chapters: chapters ?? this.chapters,
    );
  }
}

class GalleryChapter {
  const GalleryChapter({
    required this.id,
    required this.title,
    required this.order,
    required this.layout,
    required this.motion,
    required this.placements,
    this.caption = '',
    this.pathStyle = StoryPathStyle.solid,
    this.customPathAnchors,
    this.customPathConnections = const [],
    this.stickers = const [],
    this.layoutStates = const {},
  });

  final String id;
  final String title;
  final String caption;
  final int order;
  final GalleryLayout layout;
  final GalleryMotion motion;
  final StoryPathStyle pathStyle;
  final List<GalleryPlacement> placements;
  final List<CustomPathAnchor>? customPathAnchors; // 自定义路径锚点
  final List<CustomPathConnection> customPathConnections; // 旧路径连接数据，仅用于兼容历史作品
  final List<GallerySticker> stickers; // 画布贴画

  final Map<GalleryLayout, GalleryLayoutState> layoutStates;

  GalleryChapter copyWith({
    String? title,
    String? caption,
    int? order,
    GalleryLayout? layout,
    GalleryMotion? motion,
    StoryPathStyle? pathStyle,
    List<GalleryPlacement>? placements,
    Object? customPathAnchors = _unchanged,
    List<CustomPathConnection>? customPathConnections,
    List<GallerySticker>? stickers,
    Map<GalleryLayout, GalleryLayoutState>? layoutStates,
  }) {
    return GalleryChapter(
      id: id,
      title: title ?? this.title,
      caption: caption ?? this.caption,
      order: order ?? this.order,
      layout: layout ?? this.layout,
      motion: motion ?? this.motion,
      pathStyle: pathStyle ?? this.pathStyle,
      placements: placements ?? this.placements,
      customPathAnchors: identical(customPathAnchors, _unchanged)
          ? this.customPathAnchors
          : customPathAnchors as List<CustomPathAnchor>?,
      customPathConnections:
          customPathConnections ?? this.customPathConnections,
      stickers: stickers ?? this.stickers,
      layoutStates: layoutStates ?? this.layoutStates,
    );
  }

  GalleryChapter recordCurrentLayoutState() {
    return copyWith(
      layoutStates: {
        ...layoutStates,
        layout: GalleryLayoutState(
          placements: placements,
          pathStyle: pathStyle,
          customPathAnchors: customPathAnchors,
          customPathConnections: customPathConnections,
          stickers: stickers,
        ),
      },
    );
  }

  GalleryChapter switchLayout(GalleryLayout nextLayout) {
    final recorded = recordCurrentLayoutState();
    if (nextLayout == layout) return recorded;
    final target =
        recorded.layoutStates[nextLayout]?.reconcileWith(placements) ??
        GalleryLayoutState.defaultsFor(placements);
    return recorded.copyWith(
      layout: nextLayout,
      pathStyle: target.pathStyle,
      placements: target.placements,
      customPathAnchors: target.customPathAnchors,
      customPathConnections: target.customPathConnections,
      stickers: target.stickers,
    );
  }

  GalleryChapter movePlacement(int oldIndex, int newIndex) {
    final reordered = List<GalleryPlacement>.of(placements);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    return copyWith(
      placements: [
        for (var index = 0; index < reordered.length; index++)
          reordered[index].copyWith(order: index),
      ],
    );
  }
}

const Object _unchanged = Object();

class GalleryPlacement {
  const GalleryPlacement({
    required this.id,
    required this.mediaId,
    required this.order,
    this.size = GallerySize.medium,
    this.frame = GalleryFrame.none,
    this.focalX = 0.5,
    this.focalY = 0.5,
    this.zoom = 1,
    this.scale = 1,
    this.offsetX = 0,
    this.offsetY = 0,
    this.rotation = 0.0,
    this.caption = '',
    this.frameCaption = '',
  });

  final String id;
  final String mediaId;
  final int order;
  final GallerySize size;
  final GalleryFrame frame;
  final double focalX;
  final double focalY;
  final double zoom;
  final double scale;
  final double offsetX;
  final double offsetY;
  final double rotation;
  final String caption;
  final String frameCaption;

  GalleryPlacement copyWith({
    int? order,
    GallerySize? size,
    GalleryFrame? frame,
    double? focalX,
    double? focalY,
    double? zoom,
    double? scale,
    double? offsetX,
    double? offsetY,
    double? rotation,
    String? caption,
    String? frameCaption,
  }) {
    return GalleryPlacement(
      id: id,
      mediaId: mediaId,
      order: order ?? this.order,
      size: size ?? this.size,
      frame: frame ?? this.frame,
      focalX: focalX ?? this.focalX,
      focalY: focalY ?? this.focalY,
      zoom: zoom ?? this.zoom,
      scale: scale ?? this.scale,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      rotation: rotation ?? this.rotation,
      caption: caption ?? this.caption,
      frameCaption: frameCaption ?? this.frameCaption,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mediaId': mediaId,
    'order': order,
    'size': size.name,
    'frame': frame.name,
    'focalX': focalX,
    'focalY': focalY,
    'zoom': zoom,
    'scale': scale,
    'offsetX': offsetX,
    'offsetY': offsetY,
    'rotation': rotation,
    'caption': caption,
    'frameCaption': frameCaption,
  };

  factory GalleryPlacement.fromJson(Map<String, dynamic> json) {
    return GalleryPlacement(
      id: json['id'] as String,
      mediaId: json['mediaId'] as String,
      order: (json['order'] as num?)?.toInt() ?? 0,
      size: _enumByName(
        GallerySize.values,
        json['size'] as String? ?? GallerySize.medium.name,
        GallerySize.medium,
      ),
      frame: _enumByName(
        GalleryFrame.values,
        json['frame'] as String? ?? GalleryFrame.none.name,
        GalleryFrame.none,
      ),
      focalX: (json['focalX'] as num?)?.toDouble() ?? .5,
      focalY: (json['focalY'] as num?)?.toDouble() ?? .5,
      zoom: (json['zoom'] as num?)?.toDouble() ?? 1,
      scale: (json['scale'] as num?)?.toDouble() ?? 1,
      offsetX: (json['offsetX'] as num?)?.toDouble() ?? 0,
      offsetY: (json['offsetY'] as num?)?.toDouble() ?? 0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      caption: json['caption'] as String? ?? '',
      frameCaption: json['frameCaption'] as String? ?? '',
    );
  }
}

class GalleryLayoutState {
  const GalleryLayoutState({
    required this.placements,
    this.pathStyle = StoryPathStyle.solid,
    this.customPathAnchors,
    this.customPathConnections = const [],
    this.stickers = const [],
  });

  final List<GalleryPlacement> placements;
  final StoryPathStyle pathStyle;
  final List<CustomPathAnchor>? customPathAnchors;
  final List<CustomPathConnection> customPathConnections;
  final List<GallerySticker> stickers;

  factory GalleryLayoutState.defaultsFor(
    List<GalleryPlacement> sourcePlacements,
  ) {
    return GalleryLayoutState(
      placements: [
        for (var index = 0; index < sourcePlacements.length; index++)
          GalleryPlacement(
            id: sourcePlacements[index].id,
            mediaId: sourcePlacements[index].mediaId,
            order: index,
          ),
      ],
    );
  }

  GalleryLayoutState reconcileWith(List<GalleryPlacement> currentPlacements) {
    final currentById = {
      for (final placement in currentPlacements) placement.id: placement,
    };
    final savedPlacements = [...placements]
      ..sort((a, b) => a.order.compareTo(b.order));
    final reconciled = <GalleryPlacement>[];
    final included = <String>{};
    for (final saved in savedPlacements) {
      final current = currentById[saved.id];
      if (current == null || !included.add(saved.id)) continue;
      reconciled.add(
        GalleryPlacement(
          id: current.id,
          mediaId: current.mediaId,
          order: reconciled.length,
          size: saved.size,
          frame: saved.frame,
          focalX: saved.focalX,
          focalY: saved.focalY,
          zoom: saved.zoom,
          scale: saved.scale,
          offsetX: saved.offsetX,
          offsetY: saved.offsetY,
          rotation: saved.rotation,
          caption: saved.caption,
          frameCaption: saved.frameCaption,
        ),
      );
    }
    for (final current in currentPlacements) {
      if (!included.add(current.id)) continue;
      reconciled.add(
        GalleryPlacement(
          id: current.id,
          mediaId: current.mediaId,
          order: reconciled.length,
        ),
      );
    }
    final validPlacementIds = reconciled
        .map((placement) => placement.id)
        .toSet();
    return GalleryLayoutState(
      placements: reconciled,
      pathStyle: pathStyle,
      customPathAnchors: customPathAnchors,
      customPathConnections: [
        for (final connection in customPathConnections)
          if (validPlacementIds.contains(connection.fromPlacementId) &&
              validPlacementIds.contains(connection.toPlacementId))
            connection,
      ],
      stickers: stickers,
    );
  }

  Map<String, dynamic> toJson() => {
    'placements': [for (final placement in placements) placement.toJson()],
    'pathStyle': pathStyle.name,
    'customPathAnchors': [
      for (final anchor in customPathAnchors ?? const <CustomPathAnchor>[])
        anchor.toJson(),
    ],
    'customPathConnections': [
      for (final connection in customPathConnections) connection.toJson(),
    ],
    'stickers': [for (final sticker in stickers) sticker.toJson()],
  };

  factory GalleryLayoutState.fromJson(Map<String, dynamic> json) {
    final anchors = [
      for (final item in json['customPathAnchors'] as List? ?? const [])
        if (item is Map)
          CustomPathAnchor.fromJson(Map<String, dynamic>.from(item)),
    ];
    return GalleryLayoutState(
      placements: [
        for (final item in json['placements'] as List? ?? const [])
          if (item is Map)
            GalleryPlacement.fromJson(Map<String, dynamic>.from(item)),
      ],
      pathStyle: _enumByName(
        StoryPathStyle.values,
        json['pathStyle'] as String? ?? StoryPathStyle.solid.name,
        StoryPathStyle.solid,
      ),
      customPathAnchors: anchors.isEmpty ? null : anchors,
      customPathConnections: [
        for (final item in json['customPathConnections'] as List? ?? const [])
          if (item is Map)
            CustomPathConnection.fromJson(Map<String, dynamic>.from(item)),
      ],
      stickers: [
        for (final item in json['stickers'] as List? ?? const [])
          if (item is Map)
            GallerySticker.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }
}

class GalleryMedia {
  const GalleryMedia({
    required this.id,
    required this.originalPath,
    required this.thumbnailPath,
    required this.width,
    required this.height,
    required this.contentHash,
  });

  final String id;
  final String originalPath;
  final String thumbnailPath;
  final int width;
  final int height;
  final String contentHash;
}
