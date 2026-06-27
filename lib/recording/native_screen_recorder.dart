import 'package:flutter/services.dart';

class NativeScreenRecorder {
  const NativeScreenRecorder._();

  static const MethodChannel _channel = MethodChannel(
    'xulang/native_screen_recorder',
  );

  static Future<bool> get isSupported async {
    final supported = await _channel.invokeMethod<bool>('isSupported');
    return supported ?? false;
  }

  static Future<String> start({
    required String outputPath,
    required int width,
    required int height,
    int frameRate = 30,
    int bitRate = 8 * 1000 * 1000,
  }) async {
    final path = await _channel.invokeMethod<String>('start', {
      'outputPath': outputPath,
      'width': width,
      'height': height,
      'frameRate': frameRate,
      'bitRate': bitRate,
    });
    if (path == null || path.isEmpty) {
      throw PlatformException(
        code: 'recording_start_failed',
        message: 'Native recorder did not return an output path.',
      );
    }
    return path;
  }

  static Future<String?> stop() {
    return _channel.invokeMethod<String>('stop');
  }
}
