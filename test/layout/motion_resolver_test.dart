import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/layout/motion_resolver.dart';

void main() {
  for (final motion in GalleryMotion.values) {
    test('${motion.name} settles at the identity transform', () {
      final frame = MotionResolver.resolve(motion: motion, progress: 1);

      expect(frame.offset.dx, closeTo(0, 0.001));
      expect(frame.offset.dy, closeTo(0, 0.001));
      expect(frame.scale, closeTo(1, 0.001));
      expect(frame.opacity, closeTo(1, 0.001));
    });
  }

  test('reduced motion keeps geometry stable and only fades', () {
    final frame = MotionResolver.resolve(
      motion: GalleryMotion.unfold,
      progress: 0.4,
      reduceMotion: true,
    );

    expect(frame.offset, Offset.zero);
    expect(frame.scale, 1);
    expect(frame.rotation, 0);
    expect(frame.opacity, 0.4);
  });
}
