import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:xulang/share/exhibition_exporter.dart';

enum DocumentCandidateSource { appDirectory, authorizedFolder }

class TemplateFileCandidate {
  const TemplateFileCandidate({
    required this.path,
    required this.name,
    required this.bytes,
    required this.modifiedAt,
    required this.summary,
    required this.source,
  });

  final String path;
  final String name;
  final int bytes;
  final DateTime modifiedAt;
  final TemplateSummary summary;
  final DocumentCandidateSource source;

  Map<String, Object?> toCacheJson() => {
    'path': path,
    'name': name,
    'bytes': bytes,
    'modifiedAt': modifiedAt.millisecondsSinceEpoch,
    'source': source.name,
    'summary': {
      'title': summary.title,
      'firstChapterTitle': summary.firstChapterTitle,
      'chapterCount': summary.chapterCount,
      'placementCount': summary.placementCount,
      'chapters': [
        for (final chapter in summary.chapters)
          {'title': chapter.title, 'slotCount': chapter.slotCount},
      ],
    },
  };

  static TemplateFileCandidate? fromCacheJson(Map<String, Object?> json) {
    final summaryJson = json['summary'];
    if (summaryJson is! Map) return null;
    final chaptersJson = summaryJson['chapters'];
    return TemplateFileCandidate(
      path: json['path']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['modifiedAt'] as num?)?.toInt() ?? 0,
      ),
      source: _sourceFromName(json['source']?.toString()),
      summary: TemplateSummary(
        title: summaryJson['title']?.toString() ?? 'Imported template',
        firstChapterTitle:
            summaryJson['firstChapterTitle']?.toString() ?? 'Chapter 1',
        chapterCount: (summaryJson['chapterCount'] as num?)?.toInt() ?? 0,
        placementCount: (summaryJson['placementCount'] as num?)?.toInt() ?? 0,
        chapters: [
          if (chaptersJson is List)
            for (final chapter in chaptersJson)
              if (chapter is Map)
                TemplateChapterSummary(
                  title: chapter['title']?.toString() ?? '',
                  slotCount: (chapter['slotCount'] as num?)?.toInt() ?? 0,
                ),
        ],
      ),
    );
  }
}

class MusicLibraryItem {
  const MusicLibraryItem({
    required this.path,
    required this.fileName,
    required this.displayName,
    required this.bytes,
    required this.modifiedAt,
    required this.source,
  });

  final String path;
  final String fileName;
  final String displayName;
  final int bytes;
  final DateTime modifiedAt;
  final DocumentCandidateSource source;

  Map<String, Object?> toCacheJson() => {
    'path': path,
    'fileName': fileName,
    'displayName': displayName,
    'bytes': bytes,
    'modifiedAt': modifiedAt.millisecondsSinceEpoch,
    'source': source.name,
  };

  MusicLibraryItem withDisplayName(String value) => MusicLibraryItem(
    path: path,
    fileName: fileName,
    displayName: value,
    bytes: bytes,
    modifiedAt: modifiedAt,
    source: source,
  );

  static MusicLibraryItem? fromCacheJson(Map<String, Object?> json) {
    final path = json['path']?.toString() ?? '';
    if (path.isEmpty) return null;
    final fileName = json['fileName']?.toString() ?? p.basename(path);
    return MusicLibraryItem(
      path: path,
      fileName: fileName,
      displayName:
          json['displayName']?.toString() ??
          _basenameWithoutExtension(fileName),
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['modifiedAt'] as num?)?.toInt() ?? 0,
      ),
      source: _sourceFromName(json['source']?.toString()),
    );
  }
}

class DocumentAccessService {
  const DocumentAccessService({required this.mediaRoot});

  static const MethodChannel _channel = MethodChannel('xulang/document_access');
  static const _audioExtensions = {
    '.mp3',
    '.m4a',
    '.aac',
    '.wav',
    '.ogg',
    '.flac',
  };

  final Directory mediaRoot;

  Future<Directory> exportsDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(root.path, 'exports'));
    await directory.create(recursive: true);
    return directory;
  }

  Future<String?> requestDirectory() async {
    if (Platform.isAndroid) {
      try {
        return await _channel.invokeMethod<String>('openTree');
      } on MissingPluginException {
        // Desktop tests and non-Android debug hosts fall back to file_selector.
      }
    }
    return getDirectoryPath(confirmButtonText: 'Allow');
  }

  Future<String> readTemplateText(TemplateFileCandidate candidate) {
    if (candidate.bytes > ExhibitionTemplateCodec.maxTemplateBytes) {
      throw const FormatException('Template file is too large');
    }
    if (_isContentUri(candidate.path)) {
      return _readNativeText(candidate.path);
    }
    return File(candidate.path).readAsString();
  }

  /// Resolves a Storage Access Framework URI to an app-private file that the
  /// Android media player can open. `audioplayers` passes URL sources to
  /// `MediaPlayer.setDataSource(String)`, which does not reliably support a
  /// `content://` URI on Android.
  Future<String> materializeAudioForPlayback(String path) async {
    if (!_isContentUri(path)) return path;
    final localPath = await _channel.invokeMethod<String>('materializeAudio', {
      'uri': path,
    });
    if (localPath == null || localPath.isEmpty) {
      throw const FileSystemException('Unable to prepare background music');
    }
    return localPath;
  }

  Future<List<TemplateFileCandidate>> readCachedTemplates() async {
    try {
      final file = await _cacheFile('templates.json');
      if (!await file.exists()) return const [];
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return const [];
      return [
        for (final item in raw)
          if (item is Map)
            TemplateFileCandidate.fromCacheJson(
              Map<String, Object?>.from(item),
            ),
      ].whereType<TemplateFileCandidate>().toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> writeCachedTemplates(
    List<TemplateFileCandidate> candidates,
  ) async {
    final file = await _cacheFile('templates.json');
    await file.writeAsString(
      jsonEncode([for (final candidate in candidates) candidate.toCacheJson()]),
    );
  }

  Future<List<MusicLibraryItem>> readCachedMusic({
    required Map<String, String> displayNames,
  }) async {
    try {
      final file = await _cacheFile('music.json');
      if (!await file.exists()) return const [];
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return const [];
      final items =
          [
                for (final item in raw)
                  if (item is Map)
                    MusicLibraryItem.fromCacheJson(
                      Map<String, Object?>.from(item),
                    ),
              ]
              .whereType<MusicLibraryItem>()
              .map((item) {
                final displayName = displayNames[item.path];
                return displayName == null
                    ? item
                    : item.withDisplayName(displayName);
              })
              .toList(growable: false);
      items.sort((a, b) => a.displayName.compareTo(b.displayName));
      return items;
    } catch (_) {
      return const [];
    }
  }

  Future<void> writeCachedMusic(List<MusicLibraryItem> items) async {
    final file = await _cacheFile('music.json');
    await file.writeAsString(
      jsonEncode([for (final item in items) item.toCacheJson()]),
    );
  }

  Future<List<TemplateFileCandidate>> scanTemplates({
    required List<String> authorizedDirectories,
    ExhibitionTemplateCodec codec = const ExhibitionTemplateCodec(),
  }) async {
    final candidates = <TemplateFileCandidate>[];
    final localAuthorized = authorizedDirectories
        .where((path) => !_isContentUri(path))
        .toList();
    final contentAuthorized = authorizedDirectories
        .where(_isContentUri)
        .toList();
    final roots = <({Directory directory, DocumentCandidateSource source})>[
      (
        directory: await exportsDirectory(),
        source: DocumentCandidateSource.appDirectory,
      ),
      for (final path in localAuthorized)
        (
          directory: Directory(path),
          source: DocumentCandidateSource.authorizedFolder,
        ),
    ];
    final seen = <String>{};
    for (final root in roots) {
      await for (final file in _listFiles(
        root.directory,
        recursive: root.source == DocumentCandidateSource.authorizedFolder,
      )) {
        if (!_isTemplateFile(file.path) || !seen.add(file.absolute.path)) {
          continue;
        }
        try {
          final stat = await file.stat();
          if (stat.size > ExhibitionTemplateCodec.maxTemplateBytes) continue;
          final text = await file.readAsString();
          final summary = codec.inspect(text);
          candidates.add(
            TemplateFileCandidate(
              path: file.path,
              name: p.basename(file.path),
              bytes: stat.size,
              modifiedAt: stat.modified,
              summary: summary,
              source: root.source,
            ),
          );
        } catch (_) {
          // Ignore invalid JSON or unreadable candidates.
        }
      }
    }
    if (contentAuthorized.isNotEmpty) {
      final nativeFiles = await _listNativeFiles(
        roots: contentAuthorized,
        extensions: const ['.json'],
      );
      for (final file in nativeFiles) {
        if (!_isTemplateFile(file.name) || !seen.add(file.uri)) continue;
        if (file.size > ExhibitionTemplateCodec.maxTemplateBytes) continue;
        try {
          final text = await _readNativeText(file.uri);
          final summary = codec.inspect(text);
          candidates.add(
            TemplateFileCandidate(
              path: file.uri,
              name: file.name,
              bytes: file.size,
              modifiedAt: file.modifiedAt,
              summary: summary,
              source: DocumentCandidateSource.authorizedFolder,
            ),
          );
        } catch (_) {
          // Ignore invalid JSON or unreadable candidates.
        }
      }
    }
    candidates.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    try {
      await writeCachedTemplates(candidates);
    } catch (_) {
      // Cache failures must not block template import.
    }
    return candidates;
  }

  Future<List<MusicLibraryItem>> scanMusic({
    required List<String> authorizedDirectories,
    required Map<String, String> displayNames,
  }) async {
    final candidates = <MusicLibraryItem>[];
    final localAuthorized = authorizedDirectories
        .where((path) => !_isContentUri(path))
        .toList();
    final contentAuthorized = authorizedDirectories
        .where(_isContentUri)
        .toList();
    final roots = <({Directory directory, DocumentCandidateSource source})>[
      (directory: mediaRoot, source: DocumentCandidateSource.appDirectory),
      for (final path in localAuthorized)
        (
          directory: Directory(path),
          source: DocumentCandidateSource.authorizedFolder,
        ),
    ];
    final seen = <String>{};
    for (final root in roots) {
      await for (final file in _listFiles(root.directory, recursive: true)) {
        if (!_isAudioFile(file.path) || !seen.add(file.absolute.path)) continue;
        try {
          final stat = await file.stat();
          candidates.add(
            MusicLibraryItem(
              path: file.path,
              fileName: p.basename(file.path),
              displayName:
                  displayNames[file.path] ??
                  p.basenameWithoutExtension(file.path),
              bytes: stat.size,
              modifiedAt: stat.modified,
              source: root.source,
            ),
          );
        } catch (_) {
          // Ignore files that disappear or cannot be read.
        }
      }
    }
    if (contentAuthorized.isNotEmpty) {
      final nativeFiles = await _listNativeFiles(
        roots: contentAuthorized,
        extensions: _audioExtensions.toList(),
      );
      for (final file in nativeFiles) {
        if (!_isAudioFileName(file.name) || !seen.add(file.uri)) continue;
        candidates.add(
          MusicLibraryItem(
            path: file.uri,
            fileName: file.name,
            displayName:
                displayNames[file.uri] ?? _basenameWithoutExtension(file.name),
            bytes: file.size,
            modifiedAt: file.modifiedAt,
            source: DocumentCandidateSource.authorizedFolder,
          ),
        );
      }
    }
    candidates.sort((a, b) => a.displayName.compareTo(b.displayName));
    try {
      await writeCachedMusic(candidates);
    } catch (_) {
      // Cache failures must not block music management.
    }
    return candidates;
  }

  Future<File> _cacheFile(String name) async {
    final directory = Directory(p.join(mediaRoot.path, '.document-cache'));
    await directory.create(recursive: true);
    return File(p.join(directory.path, name));
  }

  Future<List<_NativeDocumentFile>> _listNativeFiles({
    required List<String> roots,
    required List<String> extensions,
  }) async {
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('listFiles', {
        'roots': roots,
        'extensions': extensions,
      });
      return [
        for (final item in raw ?? const <dynamic>[])
          if (item is Map)
            _NativeDocumentFile.fromMap(Map<Object?, Object?>.from(item)),
      ];
    } on MissingPluginException {
      return const [];
    }
  }

  Future<String> _readNativeText(String uri) async {
    final text = await _channel.invokeMethod<String>('readText', {'uri': uri});
    if (text == null) {
      throw const FileSystemException('Unable to read document');
    }
    return text;
  }
}

Stream<File> _listFiles(Directory directory, {required bool recursive}) async* {
  if (!await directory.exists()) return;
  var yielded = 0;
  await for (final entity in directory.list(
    recursive: recursive,
    followLinks: false,
  )) {
    if (entity is! File) continue;
    yield entity;
    yielded += 1;
    if (yielded >= 500) return;
  }
}

bool _isTemplateFile(String path) {
  final lower = p.basename(path).toLowerCase();
  return lower.endsWith('.json') &&
      (lower.contains('template') || lower.contains('xulang'));
}

bool _isAudioFile(String path) {
  return _isAudioFileName(p.basename(path));
}

bool _isAudioFileName(String name) {
  return DocumentAccessService._audioExtensions.contains(
    p.extension(name).toLowerCase(),
  );
}

String _basenameWithoutExtension(String name) {
  final extension = p.extension(name);
  if (extension.isEmpty) return name;
  return name.substring(0, name.length - extension.length);
}

bool _isContentUri(String path) {
  return path.startsWith('content://');
}

DocumentCandidateSource _sourceFromName(String? name) {
  return DocumentCandidateSource.values.firstWhere(
    (source) => source.name == name,
    orElse: () => DocumentCandidateSource.authorizedFolder,
  );
}

class _NativeDocumentFile {
  const _NativeDocumentFile({
    required this.uri,
    required this.name,
    required this.size,
    required this.modifiedAt,
  });

  final String uri;
  final String name;
  final int size;
  final DateTime modifiedAt;

  factory _NativeDocumentFile.fromMap(Map<Object?, Object?> map) {
    final modified = map['modified'];
    return _NativeDocumentFile(
      uri: map['uri']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      size: (map['size'] as num?)?.toInt() ?? 0,
      modifiedAt: modified is num
          ? DateTime.fromMillisecondsSinceEpoch(modified.toInt())
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
