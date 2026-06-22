import 'package:flutter/widgets.dart';
import 'package:xulang/domain/gallery_document.dart';

class MotionResolver {
  const MotionResolver._();

  static MotionFrame resolve({
    required GalleryMotion motion,
    required double progress,
    bool reduceMotion = false,
  }) {
    final t = progress.clamp(0.0, 1.0);
    if (reduceMotion) {
      return MotionFrame(opacity: t);
    }
    final remaining = 1 - t;
    return switch (motion) {
      GalleryMotion.pan => MotionFrame(
        offset: Offset(.16 * remaining, 0),
        opacity: t,
      ),
      GalleryMotion.push => MotionFrame(
        offset: Offset(0, .12 * remaining),
        scale: .88 + .12 * t,
        opacity: t,
      ),
      GalleryMotion.focus => MotionFrame(
        scale: 1.12 - .12 * t,
        opacity: .35 + .65 * t,
      ),
      GalleryMotion.unfold => MotionFrame(
        offset: Offset(.08 * remaining, .04 * remaining),
        scale: .92 + .08 * t,
        rotation: -.06 * remaining,
        opacity: t,
      ),
    };
  }
}

class MotionFrame {
  const MotionFrame({
    this.offset = Offset.zero,
    this.scale = 1,
    this.rotation = 0,
    this.opacity = 1,
  });

  final Offset offset;
  final double scale;
  final double rotation;
  final double opacity;
}
