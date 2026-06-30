import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/recording/recorded_video_library.dart';

void main() {
  test('builds editable recording mp4 file names with timestamp', () {
    final fileName = RecordedVideoLibrary.buildFileName(
      title: 'Summer Walk / Preview',
      now: DateTime(2026, 6, 29, 19, 8, 5),
    );

    expect(fileName, 'xulang-Summer_Walk_Preview-20260629-190805.mp4');
  });
}
