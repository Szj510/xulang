import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/layout/narrative_axis.dart';
import 'package:xulang/layout/story_path_geometry.dart';

void main() {
  group('StoryPathGeometry.resolve', () {
    test('keeps vertical anchors ordered and cubic controls monotonic', () {
      final geometry = StoryPathGeometry.resolve(
        axis: NarrativeAxis.vertical,
        viewport: const Size(390, 844),
        nodes: const [
          StoryPathNodeInput(
            placementId: 'p1',
            rect: Rect.fromLTWH(20, 40, 100, 120),
            opacity: 1,
          ),
          StoryPathNodeInput(
            placementId: 'p2',
            rect: Rect.fromLTWH(180, 220, 100, 120),
            opacity: 1,
          ),
          StoryPathNodeInput(
            placementId: 'p3',
            rect: Rect.fromLTWH(30, 400, 100, 120),
            opacity: 1,
          ),
        ],
      );

      expect(geometry.anchors.map((anchor) => anchor.placementId), [
        'p1',
        'p2',
        'p3',
      ]);
      expect(geometry.anchors[0].point, const Offset(130, 168));
      expect(geometry.anchors[1].point, const Offset(170, 348));
      for (final segment in geometry.segments) {
        expect(
          segment.control1.dy,
          inInclusiveRange(segment.start.dy, segment.end.dy),
        );
        expect(
          segment.control2.dy,
          inInclusiveRange(segment.start.dy, segment.end.dy),
        );
        expect(segment.control1.dy, lessThan(segment.control2.dy));
      }
    });

    test('keeps horizontal anchors ordered and cubic controls monotonic', () {
      final geometry = StoryPathGeometry.resolve(
        axis: NarrativeAxis.horizontal,
        viewport: const Size(844, 390),
        nodes: const [
          StoryPathNodeInput(
            placementId: 'p1',
            rect: Rect.fromLTWH(40, 20, 120, 100),
            opacity: 1,
          ),
          StoryPathNodeInput(
            placementId: 'p2',
            rect: Rect.fromLTWH(220, 180, 120, 100),
            opacity: 1,
          ),
          StoryPathNodeInput(
            placementId: 'p3',
            rect: Rect.fromLTWH(400, 30, 120, 100),
            opacity: 1,
          ),
        ],
      );

      expect(geometry.anchors.map((anchor) => anchor.placementId), [
        'p1',
        'p2',
        'p3',
      ]);
      expect(geometry.anchors[0].point, const Offset(168, 130));
      expect(geometry.anchors[1].point, const Offset(348, 170));
      for (final segment in geometry.segments) {
        expect(
          segment.control1.dx,
          inInclusiveRange(segment.start.dx, segment.end.dx),
        );
        expect(
          segment.control2.dx,
          inInclusiveRange(segment.start.dx, segment.end.dx),
        );
        expect(segment.control1.dx, lessThan(segment.control2.dx));
      }
    });

    test(
      'filters low-opacity and offstage nodes while preserving input order',
      () {
        final geometry = StoryPathGeometry.resolve(
          axis: NarrativeAxis.vertical,
          viewport: const Size(390, 844),
          nodes: const [
            StoryPathNodeInput(
              placementId: 'visible-1',
              rect: Rect.fromLTWH(20, 20, 80, 80),
              opacity: 1,
            ),
            StoryPathNodeInput(
              placementId: 'faint',
              rect: Rect.fromLTWH(20, 120, 80, 80),
              opacity: .05,
            ),
            StoryPathNodeInput(
              placementId: 'offstage',
              rect: Rect.fromLTWH(20, 1000, 80, 80),
              opacity: 1,
            ),
            StoryPathNodeInput(
              placementId: 'visible-2',
              rect: Rect.fromLTWH(20, 240, 80, 80),
              opacity: .051,
            ),
          ],
        );

        expect(geometry.anchors.map((anchor) => anchor.placementId), [
          'visible-1',
          'visible-2',
        ]);
        expect(geometry.segments, hasLength(1));
      },
    );

    test('geometry values compare by element and produce matching hashes', () {
      final first = StoryPathGeometry(
        anchors: const [
          StoryPathAnchor(
            placementId: 'p1',
            point: Offset(10, 20),
            nodeRect: Rect.fromLTWH(0, 0, 10, 20),
          ),
        ],
        segments: const [
          StoryPathSegment(
            start: Offset(1, 2),
            control1: Offset(3, 4),
            control2: Offset(5, 6),
            end: Offset(7, 8),
          ),
        ],
      );
      final second = StoryPathGeometry(
        anchors: const [
          StoryPathAnchor(
            placementId: 'p1',
            point: Offset(10, 20),
            nodeRect: Rect.fromLTWH(0, 0, 10, 20),
          ),
        ],
        segments: const [
          StoryPathSegment(
            start: Offset(1, 2),
            control1: Offset(3, 4),
            control2: Offset(5, 6),
            end: Offset(7, 8),
          ),
        ],
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(const StoryPathGeometry.empty(), const StoryPathGeometry.empty());
    });

    test('geometry freezes source and exposed lists to keep hash stable', () {
      final sourceAnchors = <StoryPathAnchor>[
        const StoryPathAnchor(
          placementId: 'p1',
          point: Offset(10, 20),
          nodeRect: Rect.fromLTWH(0, 0, 10, 20),
        ),
      ];
      final sourceSegments = <StoryPathSegment>[
        const StoryPathSegment(
          start: Offset(1, 2),
          control1: Offset(3, 4),
          control2: Offset(5, 6),
          end: Offset(7, 8),
        ),
      ];
      final geometry = StoryPathGeometry(
        anchors: sourceAnchors,
        segments: sourceSegments,
      );
      final originalHash = geometry.hashCode;

      sourceAnchors.add(
        const StoryPathAnchor(
          placementId: 'p2',
          point: Offset.zero,
          nodeRect: Rect.zero,
        ),
      );
      sourceSegments.clear();

      expect(geometry.anchors, hasLength(1));
      expect(geometry.segments, hasLength(1));
      expect(geometry.hashCode, originalHash);
      expect(
        () => geometry.anchors.add(sourceAnchors.last),
        throwsUnsupportedError,
      );
      expect(() => geometry.segments.removeLast(), throwsUnsupportedError);
    });
  });
}
