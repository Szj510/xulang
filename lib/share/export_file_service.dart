import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/share/exhibition_exporter.dart';

class ExportFileService {
  const ExportFileService({required this.outputDirectory});

  final Directory outputDirectory;

  Future<File> writeTemplate(GalleryDocument document) async {
    await outputDirectory.create(recursive: true);
    final name = _safeName(document.title);
    final file = File(
      p.join(outputDirectory.path, '$name.xulang-template.json'),
    );
    return file.writeAsString(
      const ExhibitionTemplateCodec().encode(document),
      encoding: utf8,
    );
  }

  Future<ShareResult> shareFile(File file, {required String title}) {
    return SharePlus.instance.share(
      ShareParams(
        title: title,
        subject: title,
        files: [XFile(file.path)],
        text: '来自叙廊的分享：$title',
      ),
    );
  }

  String _safeName(String value) {
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    return normalized.isEmpty ? 'xulang-export' : normalized;
  }
}
