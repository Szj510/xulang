import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

// Windows runners can vary along anti-aliased image edges. Keep the tolerance
// at 0.075% so structural or visible rendering changes still fail.
const _maxGoldenDiffRate = 0.00075;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final comparator = goldenFileComparator;
  if (comparator is LocalFileComparator) {
    goldenFileComparator = _TolerantLocalFileComparator(
      comparator.basedir.resolve('_xulang_golden_test.dart'),
      maxDiffRate: _maxGoldenDiffRate,
    );
  }
  await testMain();
}

class _TolerantLocalFileComparator extends LocalFileComparator {
  _TolerantLocalFileComparator(super.testFile, {required this.maxDiffRate});

  final double maxDiffRate;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= maxDiffRate) {
      result.dispose();
      return true;
    }

    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
