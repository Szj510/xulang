import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/layout/layout_resolver.dart';
import 'package:xulang/layout/narrative_track.dart';

class NarrativeTrackResolver {
  const NarrativeTrackResolver._();

  static ResolvedNarrativeTrack resolve({
    required GalleryChapter chapter,
    required Size viewport,
  }) {
    final scene = LayoutResolver.resolve(chapter: chapter, viewport: viewport);
    final itemCount = chapter.placements.length;
    if (itemCount == 0) {
      return const ResolvedNarrativeTrack(keyframes: [], visibilityWindow: 1);
    }
    final spacing = itemCount == 1 ? 1.0 : 1 / (itemCount - 1);
    final visibilityWindow = math.max(.34, spacing * 1.8);
    return ResolvedNarrativeTrack(
      visibilityWindow: visibilityWindow,
      keyframes: [
        for (var index = 0; index < scene.nodes.length; index++)
          _keyframe(
            node: scene.nodes[index],
            viewport: viewport,
            focusProgress: chapter.layout == GalleryLayout.storyPath
                ? itemCount == 1
                      ? .5
                      : .16 + (index / (itemCount - 1)) * .70
                : itemCount == 1
                ? 0.0
                : index / (itemCount - 1),
            storyPath: chapter.layout == GalleryLayout.storyPath,
          ),
      ],
    );
  }

  static NarrativeKeyframe _keyframe({
    required SceneNode node,
    required Size viewport,
    required double focusProgress,
    required bool storyPath,
  }) {
    final enterShift = Offset(viewport.width * .30, viewport.height * .02);
    final exitShift = Offset(
      viewport.width * (storyPath ? -.48 : -.34),
      viewport.height * (storyPath ? .10 : -.02),
    );
    return NarrativeKeyframe(
      placementId: node.placementId,
      focusProgress: focusProgress,
      enter: NarrativeTransform(
        rect: storyPath
            ? _scaled(node.rect, .88)
            : _scaled(node.rect, .72).shift(enterShift),
        depth: storyPath
            ? math.max(.12, node.depth * .72)
            : math.max(.05, node.depth * .32),
        opacity: storyPath ? .48 : .03,
        rotation: storyPath ? node.rotation : node.rotation - .08,
        rotateY: storyPath ? .04 : .18,
      ),
      focus: NarrativeTransform(
        rect: node.rect,
        depth: node.depth,
        opacity: 1,
        rotation: node.rotation,
        rotateY: (1 - node.depth) * .12,
      ),
      exit: NarrativeTransform(
        rect: _scaled(node.rect, 1.18).shift(exitShift),
        depth: math.min(1.25, node.depth + .30),
        opacity: .03,
        rotation: node.rotation + .07,
        rotateY: -.14,
      ),
    );
  }

  static Rect _scaled(Rect rect, double scale) => Rect.fromCenter(
    center: rect.center,
    width: rect.width * scale,
    height: rect.height * scale,
  );
}
