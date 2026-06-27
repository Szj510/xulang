import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:xulang/domain/gallery_document.dart';

part 'gallery_database.g.dart';

class Exhibitions extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get coverMediaId => text().nullable()();
  TextColumn get theme => text()();
  TextColumn get canvasBackgroundPath => text().nullable()();
  RealColumn get canvasBackgroundOpacity =>
      real().withDefault(const Constant(0.32))();
  TextColumn get musicPath => text().nullable()();
  TextColumn get musicTitle => text().nullable()();
  BoolColumn get showChapterTitleInPlayback =>
      boolean().withDefault(const Constant(true))();
  IntColumn get playbackDelaySeconds =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Chapters extends Table {
  TextColumn get id => text()();
  TextColumn get exhibitionId =>
      text().references(Exhibitions, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get caption => text()();
  IntColumn get sortOrder => integer()();
  TextColumn get layout => text()();
  TextColumn get motion => text()();
  TextColumn get pathStyle => text().withDefault(const Constant('solid'))();
  TextColumn get customPathData => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class MediaAssets extends Table {
  TextColumn get id => text()();
  TextColumn get exhibitionId =>
      text().references(Exhibitions, #id, onDelete: KeyAction.cascade)();
  TextColumn get originalPath => text()();
  TextColumn get thumbnailPath => text()();
  IntColumn get width => integer()();
  IntColumn get height => integer()();
  TextColumn get contentHash => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Placements extends Table {
  TextColumn get id => text()();
  TextColumn get chapterId =>
      text().references(Chapters, #id, onDelete: KeyAction.cascade)();
  TextColumn get mediaId => text().references(MediaAssets, #id)();
  IntColumn get sortOrder => integer()();
  TextColumn get size => text()();
  TextColumn get frame => text()();
  RealColumn get focalX => real()();
  RealColumn get focalY => real()();
  RealColumn get zoom => real()();
  RealColumn get scale => real().withDefault(const Constant(1.0))();
  RealColumn get offsetX => real().withDefault(const Constant(0.0))();
  RealColumn get offsetY => real().withDefault(const Constant(0.0))();
  RealColumn get rotation => real().withDefault(const Constant(0.0))();
  TextColumn get caption => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Exhibitions, Chapters, MediaAssets, Placements])
class GalleryDatabase extends _$GalleryDatabase {
  GalleryDatabase() : super(_openConnection());

  GalleryDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(placements, placements.scale);
        await m.addColumn(placements, placements.offsetX);
        await m.addColumn(placements, placements.offsetY);
      }
      if (from < 3) {
        await m.addColumn(exhibitions, exhibitions.musicPath);
        await m.addColumn(exhibitions, exhibitions.musicTitle);
        await m.addColumn(exhibitions, exhibitions.showChapterTitleInPlayback);
        await m.addColumn(chapters, chapters.pathStyle);
      }
      if (from < 4) {
        await m.addColumn(placements, placements.rotation);
      }
      if (from < 5) {
        await m.addColumn(chapters, chapters.customPathData);
      }
      if (from < 6) {
        await _ensurePlaybackDelayColumn();
      }
      if (from < 7) {
        await _ensureCanvasBackgroundColumns();
      }
    },
    beforeOpen: (_) async {
      await _ensurePlaybackDelayColumn();
      await _ensureCanvasBackgroundColumns();
    },
  );

  Future<void> _ensurePlaybackDelayColumn() async {
    try {
      await customStatement(
        'ALTER TABLE exhibitions ADD COLUMN playback_delay_seconds INTEGER NOT NULL DEFAULT 0',
      );
    } catch (_) {
      // Column already exists on current installs.
    }
  }

  Future<void> _ensureCanvasBackgroundColumns() async {
    try {
      await customStatement(
        'ALTER TABLE exhibitions ADD COLUMN canvas_background_path TEXT',
      );
    } catch (_) {
      // Column already exists on current installs.
    }
    try {
      await customStatement(
        'ALTER TABLE exhibitions ADD COLUMN canvas_background_opacity REAL NOT NULL DEFAULT 0.32',
      );
    } catch (_) {
      // Column already exists on current installs.
    }
  }

  Future<void> _writePlaybackDelay(String exhibitionId, int seconds) {
    return customUpdate(
      'UPDATE exhibitions SET playback_delay_seconds = ? WHERE id = ?',
      variables: [
        Variable.withInt(seconds.clamp(0, 30).toInt()),
        Variable.withString(exhibitionId),
      ],
      updates: {exhibitions},
    );
  }

  Future<int> _readPlaybackDelay(String exhibitionId) async {
    final rows = await customSelect(
      'SELECT playback_delay_seconds FROM exhibitions WHERE id = ? LIMIT 1',
      variables: [Variable.withString(exhibitionId)],
      readsFrom: {exhibitions},
    ).get();
    if (rows.isEmpty) return 0;
    return rows.single.read<int>('playback_delay_seconds').clamp(0, 30).toInt();
  }

  Future<void> saveDocument(
    GalleryDocument document,
    Iterable<GalleryMedia> media,
  ) async {
    await transaction(() async {
      await into(exhibitions).insertOnConflictUpdate(
        ExhibitionsCompanion.insert(
          id: document.id,
          title: document.title,
          coverMediaId: Value(document.coverMediaId),
          theme: document.theme.name,
          canvasBackgroundPath: Value(document.canvasBackgroundPath),
          canvasBackgroundOpacity: Value(
            document.canvasBackgroundOpacity.clamp(0, 1).toDouble(),
          ),
          musicPath: Value(document.musicPath),
          musicTitle: Value(document.musicTitle),
          showChapterTitleInPlayback: Value(
            document.showChapterTitleInPlayback,
          ),
          createdAt: document.createdAt,
          updatedAt: document.updatedAt,
        ),
      );
      await _writePlaybackDelay(document.id, document.playbackDelaySeconds);

      final chapterIds =
          await (selectOnly(chapters)
                ..addColumns([chapters.id])
                ..where(chapters.exhibitionId.equals(document.id)))
              .map((row) => row.read(chapters.id)!)
              .get();
      if (chapterIds.isNotEmpty) {
        await (delete(
          placements,
        )..where((row) => row.chapterId.isIn(chapterIds))).go();
      }
      await (delete(
        chapters,
      )..where((row) => row.exhibitionId.equals(document.id))).go();
      await (delete(
        mediaAssets,
      )..where((row) => row.exhibitionId.equals(document.id))).go();

      await batch((batch) {
        batch.insertAll(mediaAssets, [
          for (final item in media)
            MediaAssetsCompanion.insert(
              id: item.id,
              exhibitionId: document.id,
              originalPath: item.originalPath,
              thumbnailPath: item.thumbnailPath,
              width: item.width,
              height: item.height,
              contentHash: item.contentHash,
            ),
        ]);
        batch.insertAll(chapters, [
          for (final chapter in document.chapters)
            ChaptersCompanion.insert(
              id: chapter.id,
              exhibitionId: document.id,
              title: chapter.title,
              caption: chapter.caption,
              sortOrder: chapter.order,
              layout: chapter.layout.name,
              motion: chapter.motion.name,
              pathStyle: Value(chapter.pathStyle.name),
              customPathData: Value(
                _encodeCustomPath(
                  anchors: chapter.customPathAnchors,
                  connections: chapter.customPathConnections,
                  stickers: chapter.stickers,
                ),
              ),
            ),
        ]);
        batch.insertAll(placements, [
          for (final chapter in document.chapters)
            for (final item in chapter.placements)
              PlacementsCompanion.insert(
                id: item.id,
                chapterId: chapter.id,
                mediaId: item.mediaId,
                sortOrder: item.order,
                size: item.size.name,
                frame: item.frame.name,
                focalX: item.focalX,
                focalY: item.focalY,
                zoom: item.zoom,
                scale: Value(item.scale),
                offsetX: Value(item.offsetX),
                offsetY: Value(item.offsetY),
                rotation: Value(item.rotation),
                caption: item.caption,
              ),
        ]);
      });
    });
  }

  Stream<List<ExhibitionSummary>> watchExhibitions() {
    final query = select(exhibitions)
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => ExhibitionSummary(
              id: row.id,
              title: row.title,
              coverMediaId: row.coverMediaId,
              updatedAt: row.updatedAt,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<GalleryDocument?> loadDocument(String exhibitionId) async {
    final exhibition = await (select(
      exhibitions,
    )..where((row) => row.id.equals(exhibitionId))).getSingleOrNull();
    if (exhibition == null) return null;

    final chapterRows =
        await (select(chapters)
              ..where((row) => row.exhibitionId.equals(exhibitionId))
              ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
            .get();
    final restoredChapters = <GalleryChapter>[];
    for (final chapter in chapterRows) {
      final customPath = _decodeCustomPath(chapter.customPathData);
      final placementRows =
          await (select(placements)
                ..where((row) => row.chapterId.equals(chapter.id))
                ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
              .get();
      restoredChapters.add(
        GalleryChapter(
          id: chapter.id,
          title: chapter.title,
          caption: chapter.caption,
          order: chapter.sortOrder,
          layout: _decodeLayout(chapter.layout),
          motion: GalleryMotion.values.byName(chapter.motion),
          pathStyle: _enumByName(
            StoryPathStyle.values,
            chapter.pathStyle,
            StoryPathStyle.solid,
          ),
          customPathAnchors: customPath.anchors,
          customPathConnections: customPath.connections,
          stickers: customPath.stickers,
          placements: [
            for (final item in placementRows)
              GalleryPlacement(
                id: item.id,
                mediaId: item.mediaId,
                order: item.sortOrder,
                size: GallerySize.values.byName(item.size),
                frame: GalleryFrame.values.byName(item.frame),
                focalX: item.focalX,
                focalY: item.focalY,
                zoom: item.zoom,
                scale: item.scale,
                offsetX: item.offsetX,
                offsetY: item.offsetY,
                caption: item.caption,
                rotation: item.rotation,
              ),
          ],
        ),
      );
    }
    return GalleryDocument(
      id: exhibition.id,
      title: exhibition.title,
      coverMediaId: exhibition.coverMediaId,
      theme: _enumByName(
        GalleryTheme.values,
        exhibition.theme,
        GalleryTheme.ink,
      ),
      canvasBackgroundPath: exhibition.canvasBackgroundPath,
      canvasBackgroundOpacity: exhibition.canvasBackgroundOpacity
          .clamp(0, 1)
          .toDouble(),
      musicPath: exhibition.musicPath,
      musicTitle: exhibition.musicTitle,
      showChapterTitleInPlayback: exhibition.showChapterTitleInPlayback,
      playbackDelaySeconds: await _readPlaybackDelay(exhibition.id),
      createdAt: exhibition.createdAt,
      updatedAt: exhibition.updatedAt,
      chapters: restoredChapters,
    );
  }

  Future<List<GalleryMedia>> loadMedia(String exhibitionId) async {
    final rows = await (select(
      mediaAssets,
    )..where((row) => row.exhibitionId.equals(exhibitionId))).get();
    return [
      for (final row in rows)
        GalleryMedia(
          id: row.id,
          originalPath: row.originalPath,
          thumbnailPath: row.thumbnailPath,
          width: row.width,
          height: row.height,
          contentHash: row.contentHash,
        ),
    ];
  }

  Future<void> deleteExhibition(String exhibitionId) async {
    await transaction(() async {
      final chapterIds =
          await (selectOnly(chapters)
                ..addColumns([chapters.id])
                ..where(chapters.exhibitionId.equals(exhibitionId)))
              .map((row) => row.read(chapters.id)!)
              .get();
      if (chapterIds.isNotEmpty) {
        await (delete(
          placements,
        )..where((row) => row.chapterId.isIn(chapterIds))).go();
      }
      await (delete(
        chapters,
      )..where((row) => row.exhibitionId.equals(exhibitionId))).go();
      await (delete(
        mediaAssets,
      )..where((row) => row.exhibitionId.equals(exhibitionId))).go();
      await (delete(
        exhibitions,
      )..where((row) => row.id.equals(exhibitionId))).go();
    });
  }
}

String? _encodeCustomPath({
  List<CustomPathAnchor>? anchors,
  List<CustomPathConnection> connections = const [],
  List<GallerySticker> stickers = const [],
}) {
  if (anchors == null && connections.isEmpty && stickers.isEmpty) return null;
  return jsonEncode({
    'version': 2,
    'anchors': [
      for (final anchor in anchors ?? const <CustomPathAnchor>[])
        anchor.toJson(),
    ],
    'connections': [for (final connection in connections) connection.toJson()],
    'stickers': [for (final sticker in stickers) sticker.toJson()],
  });
}

_DecodedCustomPath _decodeCustomPath(String? data) {
  if (data == null || data.trim().isEmpty) {
    return const _DecodedCustomPath();
  }
  try {
    final decoded = jsonDecode(data);
    if (decoded is List) {
      return _DecodedCustomPath(anchors: _decodeLegacyAnchors(decoded));
    }
    if (decoded is Map) {
      final json = Map<String, dynamic>.from(decoded);
      return _DecodedCustomPath(
        anchors: _decodeLegacyAnchors(json['anchors'] as List? ?? const []),
        connections: _decodeConnections(
          json['connections'] as List? ?? const [],
        ),
        stickers: _decodeStickers(json['stickers'] as List? ?? const []),
      );
    }
    return const _DecodedCustomPath();
  } catch (_) {
    return const _DecodedCustomPath();
  }
}

List<CustomPathAnchor>? _decodeLegacyAnchors(List data) {
  final anchors = [
    for (final item in data)
      if (item is Map)
        CustomPathAnchor.fromJson(Map<String, dynamic>.from(item)),
  ];
  return anchors.isEmpty ? null : anchors;
}

List<CustomPathConnection> _decodeConnections(List data) {
  return [
    for (final item in data)
      if (item is Map)
        CustomPathConnection.fromJson(Map<String, dynamic>.from(item)),
  ];
}

List<GallerySticker> _decodeStickers(List data) {
  return [
    for (final item in data)
      if (item is Map) GallerySticker.fromJson(Map<String, dynamic>.from(item)),
  ];
}

class _DecodedCustomPath {
  const _DecodedCustomPath({
    this.anchors,
    this.connections = const [],
    this.stickers = const [],
  });

  final List<CustomPathAnchor>? anchors;
  final List<CustomPathConnection> connections;
  final List<GallerySticker> stickers;
}

GalleryLayout _decodeLayout(String name) {
  if (name == 'depthWall') return GalleryLayout.collage;
  return _enumByName(GalleryLayout.values, name, GalleryLayout.hero);
}

T _enumByName<T extends Enum>(List<T> values, String name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

class ExhibitionSummary {
  const ExhibitionSummary({
    required this.id,
    required this.title,
    required this.updatedAt,
    this.coverMediaId,
  });

  final String id;
  final String title;
  final String? coverMediaId;
  final DateTime updatedAt;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();
    final file = File(p.join(directory.path, 'xulang.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
