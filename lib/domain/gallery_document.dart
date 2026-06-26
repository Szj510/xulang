enum GalleryLayout { hero, filmstrip, diptych, collage, storyPath }

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
}

enum GallerySize { small, medium, large }

enum GalleryTheme { ink, paper, graphite, mist, warm }

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

enum GalleryStickerKind { star, sparkle, heart, leaf, flower }

class GallerySticker {
  const GallerySticker({
    required this.id,
    required this.kind,
    required this.x,
    required this.y,
    this.scale = 1,
    this.rotation = 0,
  });

  final String id;
  final GalleryStickerKind kind;
  final double x;
  final double y;
  final double scale;
  final double rotation;

  GallerySticker copyWith({
    GalleryStickerKind? kind,
    double? x,
    double? y,
    double? scale,
    double? rotation,
  }) {
    return GallerySticker(
      id: id,
      kind: kind ?? this.kind,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'x': x,
    'y': y,
    'scale': scale,
    'rotation': rotation,
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
      rotation == other.rotation;

  @override
  int get hashCode => Object.hash(id, kind, x, y, scale, rotation);
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
    this.theme = GalleryTheme.ink,
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
  final GalleryTheme theme;
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
    GalleryTheme? theme,
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
      theme: theme ?? this.theme,
      musicPath: identical(musicPath, _unchanged)
          ? this.musicPath
          : musicPath as String?,
      musicTitle: identical(musicTitle, _unchanged)
          ? this.musicTitle
          : musicTitle as String?,
      showChapterTitleInPlayback:
          showChapterTitleInPlayback ?? this.showChapterTitleInPlayback,
      playbackDelaySeconds:
          playbackDelaySeconds ?? this.playbackDelaySeconds,
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
