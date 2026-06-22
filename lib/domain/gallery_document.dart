enum GalleryLayout { hero, filmstrip, diptych, collage, storyPath }

enum GalleryMotion { pan, push, focus, unfold }

enum GalleryFrame { none, hairline, mat, stamp }

enum GallerySize { small, medium, large }

enum GalleryTheme { ink, paper }

class GalleryDocument {
  const GalleryDocument({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.chapters,
    this.coverMediaId,
    this.theme = GalleryTheme.ink,
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
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<GalleryChapter> chapters;

  GalleryDocument copyWith({
    String? title,
    String? coverMediaId,
    GalleryTheme? theme,
    DateTime? updatedAt,
    List<GalleryChapter>? chapters,
  }) {
    return GalleryDocument(
      id: id,
      title: title ?? this.title,
      coverMediaId: coverMediaId ?? this.coverMediaId,
      theme: theme ?? this.theme,
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
  });

  final String id;
  final String title;
  final String caption;
  final int order;
  final GalleryLayout layout;
  final GalleryMotion motion;
  final List<GalleryPlacement> placements;

  GalleryChapter copyWith({
    String? title,
    String? caption,
    int? order,
    GalleryLayout? layout,
    GalleryMotion? motion,
    List<GalleryPlacement>? placements,
  }) {
    return GalleryChapter(
      id: id,
      title: title ?? this.title,
      caption: caption ?? this.caption,
      order: order ?? this.order,
      layout: layout ?? this.layout,
      motion: motion ?? this.motion,
      placements: placements ?? this.placements,
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
  final String caption;

  GalleryPlacement copyWith({
    int? order,
    GallerySize? size,
    GalleryFrame? frame,
    double? focalX,
    double? focalY,
    double? zoom,
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
