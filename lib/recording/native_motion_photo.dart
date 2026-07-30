import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MotionPhotoResult {
  const MotionPhotoResult({
    required this.uri,
    required this.displayName,
    required this.sizeBytes,
  });

  final String uri;
  final String displayName;
  final int sizeBytes;
}

class NativeMotionPhoto {
  const NativeMotionPhoto._();

  static const MethodChannel _channel = MethodChannel(
    'xulang/native_motion_photo',
  );

  static Future<String> createTemporaryVideoPath() async {
    final directory = Directory(
      p.join((await getTemporaryDirectory()).path, 'motion-photo'),
    );
    await directory.create(recursive: true);
    return p.join(
      directory.path,
      'xulang-motion-${DateTime.now().microsecondsSinceEpoch}.mp4',
    );
  }

  static Future<MotionPhotoResult> createFromVideo({
    required String videoPath,
    required String title,
  }) async {
    final value = await _channel.invokeMapMethod<String, Object?>('create', {
      'videoPath': videoPath,
      'title': title,
    });
    final uri = value?['uri'] as String?;
    final displayName = value?['displayName'] as String?;
    final sizeBytes = value?['sizeBytes'] as int?;
    if (uri == null ||
        uri.isEmpty ||
        displayName == null ||
        displayName.isEmpty ||
        sizeBytes == null) {
      throw PlatformException(
        code: 'motion_photo_create_failed',
        message: 'Native exporter did not return a saved motion photo.',
      );
    }
    return MotionPhotoResult(
      uri: uri,
      displayName: displayName,
      sizeBytes: sizeBytes,
    );
  }

  static Future<void> share({required String uri, required String title}) {
    return _channel.invokeMethod<void>('share', {'uri': uri, 'title': title});
  }
}
