enum GalleryLayout { hero, filmstrip, diptych, collage, storyPath, depthWall }

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

  GalleryChapter copyWith({
    String? title,
    String? caption,
    int? order,
    GalleryLayout? layout,
    GalleryMotion? motion,
    StoryPathStyle? pathStyle,
    List<GalleryPlacement>? placements,
    Object? customPathAnchors = _unchanged,
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
