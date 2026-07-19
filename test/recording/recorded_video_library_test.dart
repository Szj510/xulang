import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:xulang/recording/recorded_video_library.dart';

void main() {
  test('builds editable recording mp4 file names with timestamp', () {
    final fileName = RecordedVideoLibrary.buildFileName(
      title: 'Summer Walk / Preview',
      now: DateTime(2026, 6, 29, 19, 8, 5),
    );

    expect(fileName, 'xulang-Summer_Walk_Preview-20260629-190805.mp4');
  });

  test('managed path check rejects traversal outside recordings directory', () {
    final recordingsDirectoryPath = p.join('app', 'docs', 'xulang-recordings');
    expect(
      RecordedVideoLibrary.isManagedRecordingPath(
        path: p.join(recordingsDirectoryPath, 'video.mp4'),
        recordingsDirectoryPath: recordingsDirectoryPath,
      ),
      isTrue,
    );
    expect(
      RecordedVideoLibrary.isManagedRecordingPath(
        path: p.join(recordingsDirectoryPath, '..', 'secrets.sqlite'),
        recordingsDirectoryPath: recordingsDirectoryPath,
      ),
      isFalse,
    );
  });
}
