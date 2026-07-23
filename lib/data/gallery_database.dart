import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:xulang/domain/gallery_document.dart';

part 'gallery_database.g.dart';

class ExhibitionCategories extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppSettingsRows extends Table {
  TextColumn get id => text()();
  BoolColumn get recordingShowChapterTitle =>
      boolean().withDefault(const Constant(true))();
  IntColumn get recordingDelaySeconds =>
      integer().withDefault(const Constant(0))();
  TextColumn get mediaImportMode =>
      text().withDefault(const Constant('copyIntoApp'))();
  RealColumn get recordingSpeed => real().withDefault(const Constant(6.0))();
  BoolColumn get recordingUseMusic =>
      boolean().withDefault(const Constant(true))();
  TextColumn get recordingChapterMode =>
      text().withDefault(const Constant('current'))();
  TextColumn get recordingQuality =>
      text().withDefault(const Constant('high'))();
  TextColumn get themeMode => text().withDefault(const Constant('system'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Exhibitions extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get coverMediaId => text().nullable()();
  TextColumn get categoryId => text().nullable().references(
    ExhibitionCategories,
    #id,
    onDelete: KeyAction.setNull,
  )();
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
  TextColumn get frameCaption => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    ExhibitionCategories,
    AppSettingsRows,
    Exhibitions,
    Chapters,
    MediaAssets,
    Placements,
  ],
)
class GalleryDatabase extends _$GalleryDatabase {
  GalleryDatabase() : super(_openConnection());

  GalleryDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 13;

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
      if (from < 8) {
        await _ensureCategoryAndSettingsSchema();
      }
      if (from < 9) {
        await _ensureAppSettingsColumns();
      }
      if (from < 10) {
        await _ensureAppSettingsColumns();
      }
      if (from < 11) {
        await _ensureAppSettingsColumns();
      }
      if (from < 12) {
        await _ensureAppSettingsColumns();
      }
      if (from < 13) {
        await _ensureFrameCaptionColumn();
      }
    },
    beforeOpen: (_) async {
      await _ensurePlaybackDelayColumn();
      await _ensureCanvasBackgroundColumns();
      await _ensureCategoryAndSettingsSchema();
      await _ensureAppSettingsColumns();
      await _ensureFrameCaptionColumn();
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

  Future<void> _ensureCategoryAndSettingsSchema() async {
    await customStatement(
      'CREATE TABLE IF NOT EXISTS exhibition_categories ('
      'id TEXT NOT NULL PRIMARY KEY, '
      'title TEXT NOT NULL, '
      'sort_order INTEGER NOT NULL, '
      'created_at INTEGER NOT NULL, '
      'updated_at INTEGER NOT NULL)',
    );
    await customStatement(
      'CREATE TABLE IF NOT EXISTS app_settings_rows ('
      'id TEXT NOT NULL PRIMARY KEY, '
      'recording_show_chapter_title INTEGER NOT NULL DEFAULT 1, '
      'recording_delay_seconds INTEGER NOT NULL DEFAULT 0, '
      "media_import_mode TEXT NOT NULL DEFAULT 'copyIntoApp', "
      'recording_speed REAL NOT NULL DEFAULT 6.0, '
      'recording_use_music INTEGER NOT NULL DEFAULT 1, '
      "recording_chapter_mode TEXT NOT NULL DEFAULT 'current', "
      "recording_quality TEXT NOT NULL DEFAULT 'high', "
      "app_language TEXT NOT NULL DEFAULT 'system', "
      "theme_mode TEXT NOT NULL DEFAULT 'system', "
      "authorized_directories_json TEXT NOT NULL DEFAULT '[]', "
      "music_display_names_json TEXT NOT NULL DEFAULT '{}', "
      'home_hero_image_path TEXT)',
    );
    try {
      await customStatement(
        'ALTER TABLE exhibitions ADD COLUMN category_id TEXT',
      );
    } catch (_) {
      // Column already exists on current installs.
    }
  }

  Future<void> _ensureRuntimeSchema() async {
    await _ensurePlaybackDelayColumn();
    await _ensureCanvasBackgroundColumns();
    await _ensureCategoryAndSettingsSchema();
    await _ensureAppSettingsColumns();
    await _ensureFrameCaptionColumn();
  }

  Future<void> _ensureFrameCaptionColumn() async {
    try {
      await customStatement(
        "ALTER TABLE placements ADD COLUMN frame_caption TEXT NOT NULL DEFAULT ''",
      );
    } catch (_) {
      // Column already exists on current installs.
    }
  }

  Future<void> _ensureAppSettingsColumns() async {
    final statements = <String>[
      "ALTER TABLE app_settings_rows ADD COLUMN media_import_mode TEXT NOT NULL DEFAULT 'copyIntoApp'",
      'ALTER TABLE app_settings_rows ADD COLUMN recording_speed REAL NOT NULL DEFAULT 6.0',
      'ALTER TABLE app_settings_rows ADD COLUMN recording_use_music INTEGER NOT NULL DEFAULT 1',
      "ALTER TABLE app_settings_rows ADD COLUMN recording_chapter_mode TEXT NOT NULL DEFAULT 'current'",
      "ALTER TABLE app_settings_rows ADD COLUMN recording_quality TEXT NOT NULL DEFAULT 'high'",
      "ALTER TABLE app_settings_rows ADD COLUMN app_language TEXT NOT NULL DEFAULT 'system'",
      "ALTER TABLE app_settings_rows ADD COLUMN theme_mode TEXT NOT NULL DEFAULT 'system'",
      "ALTER TABLE app_settings_rows ADD COLUMN authorized_directories_json TEXT NOT NULL DEFAULT '[]'",
      "ALTER TABLE app_settings_rows ADD COLUMN music_display_names_json TEXT NOT NULL DEFAULT '{}'",
      'ALTER TABLE app_settings_rows ADD COLUMN home_hero_image_path TEXT',
    ];
    for (final statement in statements) {
      try {
        await customStatement(statement);
      } catch (_) {
        // Column already exists on current installs.
      }
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
          categoryId: Value(document.categoryId),
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
                  layoutStates: chapter.recordCurrentLayoutState().layoutStates,
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
                frameCaption: Value(item.frameCaption),
              ),
        ]);
      });
    });
  }

  Stream<List<ExhibitionSummary>> watchExhibitions() {
    final query = select(exhibitions)
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]);
    return Stream.fromFuture(_ensureRuntimeSchema())
        .asyncExpand((_) => query.watch())
        .map(
          (rows) => rows
              .map(
                (row) => ExhibitionSummary(
                  id: row.id,
                  title: _displayTitleForSummary(row.id, row.title),
                  coverMediaId: row.coverMediaId,
                  categoryId: row.categoryId,
                  updatedAt: row.updatedAt,
                ),
              )
              .toList(growable: false),
        );
  }

  Future<GalleryDocument?> loadDocument(String exhibitionId) async {
    await _ensureRuntimeSchema();
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
          layoutStates: customPath.layoutStates,
          placements: [
            for (final item in placementRows)
              GalleryPlacement(
                id: item.id,
                mediaId: item.mediaId,
                order: item.sortOrder,
                size: GallerySize.values.byName(item.size),
                frame: _enumByName(
                  GalleryFrame.values,
                  item.frame,
                  GalleryFrame.hairline,
                ),
                focalX: item.focalX,
                focalY: item.focalY,
                zoom: item.zoom,
                scale: item.scale,
                offsetX: item.offsetX,
                offsetY: item.offsetY,
                caption: item.caption,
                frameCaption: item.frameCaption,
                rotation: item.rotation,
              ),
          ],
        ),
      );
    }
    return GalleryDocument(
      id: exhibition.id,
      title: _displayTitleForSummary(exhibition.id, exhibition.title),
      coverMediaId: exhibition.coverMediaId,
      categoryId: exhibition.categoryId,
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

  Stream<List<GalleryCategoryInfo>> watchCategories() {
    final query = select(exhibitionCategories)
      ..orderBy([
        (row) => OrderingTerm.asc(row.createdAt),
        (row) => OrderingTerm.asc(row.id),
      ]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => GalleryCategoryInfo(
              id: row.id,
              title: row.title,
              sortOrder: row.sortOrder,
              createdAt: row.createdAt,
              updatedAt: row.updatedAt,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<void> upsertCategory(GalleryCategoryInfo category) {
    return into(exhibitionCategories).insertOnConflictUpdate(
      ExhibitionCategoriesCompanion.insert(
        id: category.id,
        title: category.title,
        sortOrder: category.sortOrder,
        createdAt: category.createdAt,
        updatedAt: category.updatedAt,
      ),
    );
  }

  Future<void> deleteCategory(String categoryId) async {
    await transaction(() async {
      await (update(exhibitions)
            ..where((row) => row.categoryId.equals(categoryId)))
          .write(const ExhibitionsCompanion(categoryId: Value(null)));
      await (delete(
        exhibitionCategories,
      )..where((row) => row.id.equals(categoryId))).go();
    });
  }

  Future<void> moveExhibitionToCategory(
    String exhibitionId,
    String? categoryId,
    DateTime now,
  ) {
    return (update(
      exhibitions,
    )..where((row) => row.id.equals(exhibitionId))).write(
      ExhibitionsCompanion(
        categoryId: Value(categoryId),
        updatedAt: Value(now),
      ),
    );
  }

  Stream<AppSettings> watchAppSettings() {
    return Stream.fromFuture(_ensureRuntimeSchema())
        .asyncExpand(
          (_) => customSelect(
            'SELECT recording_show_chapter_title, media_import_mode, recording_speed, '
            'recording_use_music, recording_chapter_mode, recording_quality, '
            'app_language, theme_mode, authorized_directories_json, '
            'music_display_names_json, home_hero_image_path '
            'FROM app_settings_rows WHERE id = ? LIMIT 1',
            variables: [Variable.withString(_appSettingsId)],
            readsFrom: {appSettingsRows},
          ).watch(),
        )
        .map((rows) {
          if (rows.isEmpty) return const AppSettings();
          final row = rows.single;
          return AppSettings(
            recordingShowChapterTitle:
                row.read<int>('recording_show_chapter_title') != 0,
            mediaImportMode: _enumByName(
              MediaImportMode.values,
              row.read<String>('media_import_mode'),
              MediaImportMode.copyIntoApp,
            ),
            recordingSpeed: row
                .read<double>('recording_speed')
                .clamp(0.1, 12.0)
                .toDouble(),
            recordingUseMusic: row.read<int>('recording_use_music') != 0,
            recordingChapterMode: _enumByName(
              RecordingChapterMode.values,
              row.read<String>('recording_chapter_mode'),
              RecordingChapterMode.current,
            ),
            recordingQuality: _enumByName(
              RecordingQuality.values,
              row.read<String>('recording_quality'),
              RecordingQuality.high,
            ),
            language: _enumByName(
              AppLanguage.values,
              row.read<String>('app_language'),
              AppLanguage.system,
            ),
            themeMode: _enumByName(
              AppThemeMode.values,
              row.read<String>('theme_mode'),
              AppThemeMode.system,
            ),
            authorizedFolderPaths: _decodeStringList(
              row.read<String>('authorized_directories_json'),
            ),
            musicDisplayNames: _decodeStringMap(
              row.read<String>('music_display_names_json'),
            ),
            homeHeroImagePath: row.readNullable<String>('home_hero_image_path'),
          );
        });
  }

  Future<void> saveAppSettings(AppSettings settings) async {
    await _ensureRuntimeSchema();
    await into(appSettingsRows).insertOnConflictUpdate(
      AppSettingsRowsCompanion.insert(
        id: _appSettingsId,
        recordingShowChapterTitle: Value(settings.recordingShowChapterTitle),
        mediaImportMode: Value(settings.mediaImportMode.name),
        recordingSpeed: Value(
          settings.recordingSpeed.clamp(0.1, 12.0).toDouble(),
        ),
        recordingUseMusic: Value(settings.recordingUseMusic),
        recordingChapterMode: Value(settings.recordingChapterMode.name),
        recordingQuality: Value(settings.recordingQuality.name),
        themeMode: Value(settings.themeMode.name),
      ),
    );
    await customUpdate(
      'UPDATE app_settings_rows SET app_language = ?, theme_mode = ?, '
      'authorized_directories_json = ?, music_display_names_json = ?, '
      'home_hero_image_path = ? '
      'WHERE id = ?',
      variables: [
        Variable.withString(settings.language.name),
        Variable.withString(settings.themeMode.name),
        Variable.withString(jsonEncode(settings.authorizedFolderPaths)),
        Variable.withString(jsonEncode(settings.musicDisplayNames)),
        Variable<String>(settings.homeHeroImagePath),
        Variable.withString(_appSettingsId),
      ],
      updates: {appSettingsRows},
    );
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
  Map<GalleryLayout, GalleryLayoutState> layoutStates = const {},
}) {
  if (anchors == null &&
      connections.isEmpty &&
      stickers.isEmpty &&
      layoutStates.isEmpty) {
    return null;
  }
  return jsonEncode({
    'version': 3,
    'anchors': [
      for (final anchor in anchors ?? const <CustomPathAnchor>[])
        anchor.toJson(),
    ],
    'connections': [for (final connection in connections) connection.toJson()],
    'stickers': [for (final sticker in stickers) sticker.toJson()],
    'layoutStates': {
      for (final entry in layoutStates.entries)
        entry.key.name: entry.value.toJson(),
    },
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
        layoutStates: _decodeLayoutStates(json['layoutStates']),
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

Map<GalleryLayout, GalleryLayoutState> _decodeLayoutStates(Object? data) {
  if (data is! Map) return const {};
  final states = <GalleryLayout, GalleryLayoutState>{};
  for (final entry in data.entries) {
    final layout = _enumByName(
      GalleryLayout.values,
      entry.key.toString(),
      GalleryLayout.hero,
    );
    if (entry.value is! Map) continue;
    states[layout] = GalleryLayoutState.fromJson(
      Map<String, dynamic>.from(entry.value as Map),
    );
  }
  return states;
}

class _DecodedCustomPath {
  const _DecodedCustomPath({
    this.anchors,
    this.connections = const [],
    this.stickers = const [],
    this.layoutStates = const {},
  });

  final List<CustomPathAnchor>? anchors;
  final List<CustomPathConnection> connections;
  final List<GallerySticker> stickers;
  final Map<GalleryLayout, GalleryLayoutState> layoutStates;
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

String _displayTitleForSummary(String id, String title) {
  if (id == 'sample-exhibition') {
    return title.replaceAll('（官方示例）', '');
  }
  return title;
}

List<String> _decodeStringList(String value) {
  try {
    final decoded = jsonDecode(value);
    if (decoded is List) {
      return [
        for (final item in decoded)
          if (item is String && item.trim().isNotEmpty) item,
      ];
    }
  } catch (_) {
    // Keep corrupt settings recoverable.
  }
  return const [];
}

Map<String, String> _decodeStringMap(String value) {
  try {
    final decoded = jsonDecode(value);
    if (decoded is Map) {
      return {
        for (final entry in decoded.entries)
          if (entry.key is String && entry.value is String)
            entry.key as String: entry.value as String,
      };
    }
  } catch (_) {
    // Keep corrupt settings recoverable.
  }
  return const {};
}

class ExhibitionSummary {
  const ExhibitionSummary({
    required this.id,
    required this.title,
    required this.updatedAt,
    this.coverMediaId,
    this.categoryId,
  });

  final String id;
  final String title;
  final String? coverMediaId;
  final String? categoryId;
  final DateTime updatedAt;
}

const _appSettingsId = 'default';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();
    final file = File(p.join(directory.path, 'xulang.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
