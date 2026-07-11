import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/layout/layout_resolver.dart';
import 'package:xulang/layout/narrative_axis.dart';
import 'package:xulang/layout/narrative_track.dart';

class NarrativeTrackResolver {
  const NarrativeTrackResolver._();

  static ResolvedNarrativeTrack resolve({
    required GalleryChapter chapter,
    required Size viewport,
  }) {
    final scene = LayoutResolver.resolve(chapter: chapter, viewport: viewport);
    final axis = scene.primaryAxis == Axis.horizontal
        ? NarrativeAxis.horizontal
        : NarrativeAxis.vertical;
    final sharedCamera =
        chapter.layout == GalleryLayout.storyPath ||
        chapter.layout == GalleryLayout.filmstrip ||
        chapter.layout == GalleryLayout.orbit;
    final itemCount = chapter.placements.length;
    if (itemCount == 0) {
      return ResolvedNarrativeTrack(
        keyframes: const [],
        visibilityWindow: 1,
        axis: axis,
        viewport: viewport,
        contentExtent: scene.contentExtent,
        sharedCamera: sharedCamera,
        orbitMotion: chapter.layout == GalleryLayout.orbit,
      );
    }
    final placementFocusProgress = {
      for (var index = 0; index < chapter.placements.length; index++)
        chapter.placements[index].id: itemCount == 1
            ? 0.0
            : index / (itemCount - 1),
    };
    final spacing = itemCount == 1 ? 1.0 : 1 / (itemCount - 1);
    final visibilityWindow = math.max(.34, spacing * 1.8);
    return ResolvedNarrativeTrack(
      visibilityWindow: visibilityWindow,
      axis: axis,
      viewport: viewport,
      contentExtent: scene.contentExtent,
      sharedCamera: sharedCamera,
      orbitMotion: chapter.layout == GalleryLayout.orbit,
      keyframes: [
        for (var index = 0; index < scene.nodes.length; index++)
          chapter.layout == GalleryLayout.storyPath
              ? _storyKeyframe(
                  node: scene.nodes[index],
                  focusProgress:
                      placementFocusProgress[scene.nodes[index].placementId] ??
                      0.0,
                )
              : _keyframe(
                  node: scene.nodes[index],
                  viewport: viewport,
                  focusProgress:
                      placementFocusProgress[scene.nodes[index].placementId] ??
                      0.0,
                ),
      ],
    );
  }

  static NarrativeKeyframe _storyKeyframe({
    required SceneNode node,
    required double focusProgress,
  }) {
    final worldTransform = NarrativeTransform(
      rect: node.rect,
      depth: node.depth,
      opacity: 1,
      rotation: node.rotation,
      rotateY: (1 - node.depth) * .12,
    );
    return NarrativeKeyframe(
      placementId: node.placementId,
      focusProgress: focusProgress,
      enter: worldTransform,
      focus: worldTransform,
      exit: worldTransform,
    );
  }

  static NarrativeKeyframe _keyframe({
    required SceneNode node,
    required Size viewport,
    required double focusProgress,
  }) {
    final enterShift = Offset(viewport.width * .30, viewport.height * .02);
    final exitShift = Offset(viewport.width * -.34, viewport.height * -.02);
    return NarrativeKeyframe(
      placementId: node.placementId,
      focusProgress: focusProgress,
      enter: NarrativeTransform(
        rect: _scaled(node.rect, .72).shift(enterShift),
        depth: math.max(.05, node.depth * .32),
        opacity: .03,
        rotation: node.rotation - .08,
        rotateY: .18,
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
