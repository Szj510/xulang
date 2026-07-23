import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/data/gallery_database.dart';
import 'package:xulang/domain/gallery_document.dart';

void main() {
  test('categories are ordered by creation time rather than name', () async {
    final database = GalleryDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await database.upsertCategory(
      GalleryCategoryInfo(
        id: 'later',
        title: 'A later category',
        sortOrder: 0,
        createdAt: DateTime.utc(2026, 7, 23, 11),
        updatedAt: DateTime.utc(2026, 7, 23, 11),
      ),
    );
    await database.upsertCategory(
      GalleryCategoryInfo(
        id: 'earlier',
        title: 'Z earlier category',
        sortOrder: 99,
        createdAt: DateTime.utc(2026, 7, 23, 10),
        updatedAt: DateTime.utc(2026, 7, 23, 12),
      ),
    );

    final categories = await database.watchCategories().first;

    expect(categories.map((category) => category.id), ['earlier', 'later']);
  });
}
