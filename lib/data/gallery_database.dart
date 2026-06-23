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
  TextColumn get musicPath => text().nullable()();
  TextColumn get musicTitle => text().nullable()();
  BoolColumn get showChapterTitleInPlayback =>
      boolean().withDefault(const Constant(true))();
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
  int get schemaVersion => 4;

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
    },
  );

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
          musicPath: Value(document.musicPath),
          musicTitle: Value(document.musicTitle),
          showChapterTitleInPlayback: Value(
            document.showChapterTitleInPlayback,
          ),
          createdAt: document.createdAt,
          updatedAt: document.updatedAt,
        ),
      );

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
          layout: GalleryLayout.values.byName(chapter.layout),
          motion: GalleryMotion.values.byName(chapter.motion),
          pathStyle: _enumByName(
            StoryPathStyle.values,
            chapter.pathStyle,
            StoryPathStyle.solid,
          ),
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
      theme: GalleryTheme.values.byName(exhibition.theme),
      musicPath: exhibition.musicPath,
      musicTitle: exhibition.musicTitle,
      showChapterTitleInPlayback: exhibition.showChapterTitleInPlayback,
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
