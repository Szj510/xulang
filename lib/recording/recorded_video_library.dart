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
    return createOutputPathForTitle(title: documentId);
  }

  static Future<String> createOutputPathForTitle({
    required String title,
  }) async {
    final directory = await recordingsDirectory();
    return p.join(directory.path, buildFileName(title: title));
  }

  static String buildFileName({required String title, DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    final safeTitle = _safeName(title);
    final date =
        '${timestamp.year.toString().padLeft(4, '0')}'
        '${timestamp.month.toString().padLeft(2, '0')}'
        '${timestamp.day.toString().padLeft(2, '0')}-'
        '${timestamp.hour.toString().padLeft(2, '0')}'
        '${timestamp.minute.toString().padLeft(2, '0')}'
        '${timestamp.second.toString().padLeft(2, '0')}';
    return 'xulang-$safeTitle-$date.mp4';
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

  static Future<String> rename(String path, String title) async {
    final file = File(path);
    if (!await file.exists()) return path;
    final directory = file.parent;
    final extension = p.extension(path).isEmpty ? '.mp4' : p.extension(path);
    final safeTitle = _safeName(title);
    var candidate = p.join(directory.path, '$safeTitle$extension');
    var suffix = 2;
    while (await File(candidate).exists() && candidate != path) {
      candidate = p.join(directory.path, '$safeTitle-$suffix$extension');
      suffix += 1;
    }
    return (await file.rename(candidate)).path;
  }
}

String _safeName(String value) {
  final normalized = value
      .trim()
      .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return normalized.isEmpty ? 'recording' : normalized;
}
