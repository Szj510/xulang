import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class RecordedVideoInfo {
  const RecordedVideoInfo({
    required this.path,
    required this.name,
    required this.bytes,
    required this.modifiedAt,
  });

  final String path;
  final String name;
  final int bytes;
  final DateTime modifiedAt;
}

class RecordedVideoLibrary {
  const RecordedVideoLibrary._();

  static Future<Directory> recordingsDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(root.path, 'xulang-recordings'));
    await directory.create(recursive: true);
    return directory;
  }

  static Future<String> createOutputPath({required String documentId}) async {
    final directory = await recordingsDirectory();
    final safeId = documentId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '-');
    final fileName = 'xulang-$safeId-${DateTime.now().millisecondsSinceEpoch}.mp4';
    return p.join(directory.path, fileName);
  }

  static Future<List<RecordedVideoInfo>> list() async {
    final directory = await recordingsDirectory();
    final files = <RecordedVideoInfo>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File || p.extension(entity.path).toLowerCase() != '.mp4') {
        continue;
      }
      try {
        final stat = await entity.stat();
        files.add(
          RecordedVideoInfo(
            path: entity.path,
            name: p.basename(entity.path),
            bytes: stat.size,
            modifiedAt: stat.modified,
          ),
        );
      } catch (_) {
        // Ignore files that disappear during scanning.
      }
    }
    files.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return files;
  }

  static Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
