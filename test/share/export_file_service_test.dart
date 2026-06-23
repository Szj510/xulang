import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/data/gallery_repository.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/share/export_file_service.dart';

void main() {
  test('writes html and template files with stable safe extensions', () async {
    final output = await Directory.systemTemp.createTemp('xulang-files-');
    addTearDown(() => output.delete(recursive: true));
    final writer = ExportFileService(outputDirectory: output);
    final bundle = GalleryBundle(
      document: GalleryDocument(
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
      ),
      media: const [],
    );

    final html = await writer.writeHtml(bundle);
    final gif = await writer.writeGif(bundle);
    final template = await writer.writeTemplate(bundle.document);

    expect(html.path, endsWith('.html'));
    expect(gif.path, endsWith('.gif'));
    expect(template.path, endsWith('.xulang-template.json'));
    expect(html.path, contains('夏日_散步'));
    expect(await html.readAsString(), contains('<!doctype html>'));
    expect(await gif.readAsBytes(), isNotEmpty);
    expect(
      await template.readAsString(),
      contains('"kind": "xulang-template"'),
    );
  });
}
