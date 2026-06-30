import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/data/document_access_service.dart';

void main() {
  test('scanMusic finds audio files in authorized folders', () async {
    final temp = await Directory.systemTemp.createTemp(
      'xulang_document_access_',
    );
    addTearDown(() async {
      if (await temp.exists()) {
        await temp.delete(recursive: true);
      }
    });
    final mediaRoot = Directory('${temp.path}/media')..createSync();
    final authorized = Directory('${temp.path}/authorized')..createSync();
    final audio = File('${authorized.path}/summer-track.MP3');
    await audio.writeAsBytes([1, 2, 3, 4]);
    await File('${authorized.path}/notes.txt').writeAsString('ignore');

    final service = DocumentAccessService(mediaRoot: mediaRoot);
    final items = await service.scanMusic(
      authorizedDirectories: [authorized.path],
      displayNames: const {},
    );

    expect(items, hasLength(1));
    expect(items.single.fileName, 'summer-track.MP3');
    expect(items.single.displayName, 'summer-track');
    expect(items.single.source, DocumentCandidateSource.authorizedFolder);
  });
}
