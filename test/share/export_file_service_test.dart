import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/share/export_file_service.dart';

void main() {
  test('writes template files with stable safe extension', () async {
    final output = await Directory.systemTemp.createTemp('xulang-files-');
    addTearDown(() => output.delete(recursive: true));
    final writer = ExportFileService(outputDirectory: output);
    final document = GalleryDocument(
      id: 'id',
      title: '夏日/散步',
      createdAt: DateTime(2026, 6, 23),
      updatedAt: DateTime(2026, 6, 23),
      chapters: const [
        GalleryChapter(
          id: 'c',
          title: 'chapter',
          order: 0,
          layout: GalleryLayout.hero,
          motion: GalleryMotion.push,
          placements: [],
        ),
      ],
    );

    final template = await writer.writeTemplate(document);

    expect(template.path, endsWith('.xulang-template.json'));
    expect(template.path, contains('夏日_散步'));
    expect(
      await template.readAsString(),
      contains('"kind": "xulang-template"'),
    );
  });
}
