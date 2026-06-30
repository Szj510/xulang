import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:xulang/l10n/app_strings.dart';
import 'package:xulang/recording/recorded_video_library.dart';
import 'package:xulang/theme/xulang_theme.dart';

class RecordingResultScreen extends StatefulWidget {
  const RecordingResultScreen({
    super.key,
    required this.videoPath,
    required this.title,
    this.onDeleted,
  });

  final String videoPath;
  final String title;
  final VoidCallback? onDeleted;

  @override
  State<RecordingResultScreen> createState() => _RecordingResultScreenState();
}

class _RecordingResultScreenState extends State<RecordingResultScreen> {
  late final VideoPlayerController _controller;
  bool _initializing = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath));
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
    } catch (error) {
      _error = error;
    }
    if (mounted) setState(() => _initializing = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    final l10n = AppStrings.of(context);
    await SharePlus.instance.share(
      ShareParams(
        text: '${widget.title} ${l10n.recordingVideoSuffix}',
        files: [XFile(widget.videoPath)],
      ),
    );
  }

  Future<void> _delete() async {
    final l10n = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteVideoTitle),
        content: Text(l10n.deleteVideoBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _controller.pause();
    await RecordedVideoLibrary.delete(widget.videoPath);
    widget.onDeleted?.call();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recordingResult),
        actions: [
          IconButton(
            tooltip: l10n.share,
            onPressed: _share,
            icon: const Icon(Icons.ios_share_outlined),
          ),
          IconButton(
            tooltip: l10n.delete,
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .08),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Center(child: _buildPreview(l10n)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.videoPath,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: XulangColors.muted, fontSize: 11),
              ),
              const SizedBox(height: 4),
              FutureBuilder<int>(
                future: File(widget.videoPath).length(),
                builder: (context, snapshot) {
                  final size = snapshot.data;
                  return Text(
                    size == null
                        ? l10n.recordingSaved
                        : l10n.recordingSavedWithSize(_formatSize(size)),
                    style: const TextStyle(
                      color: XulangColors.muted,
                      fontSize: 12,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_outlined),
                      label: Text(l10n.back),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _share,
                      icon: const Icon(Icons.ios_share_outlined),
                      label: Text(l10n.share),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(AppStrings l10n) {
    if (_initializing) return const CircularProgressIndicator();
    if (_error != null || !_controller.value.isInitialized) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          l10n.videoPreviewFailed,
          textAlign: TextAlign.center,
          style: const TextStyle(color: XulangColors.muted),
        ),
      );
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying
              ? _controller.pause()
              : _controller.play();
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          if (!_controller.value.isPlaying)
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: .42),
              ),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Icon(Icons.play_arrow_rounded, size: 42),
              ),
            ),
        ],
      ),
    );
  }
}

String _formatSize(int bytes) {
  final mb = bytes / (1024 * 1024);
  if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
  final kb = bytes / 1024;
  return '${kb.toStringAsFixed(0)} KB';
}
