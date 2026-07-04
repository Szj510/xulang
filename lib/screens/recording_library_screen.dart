import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:xulang/l10n/app_strings.dart';
import 'package:xulang/recording/recorded_video_library.dart';
import 'package:xulang/screens/recording_result_screen.dart';
import 'package:xulang/theme/xulang_theme.dart';

class RecordingLibraryScreen extends StatefulWidget {
  const RecordingLibraryScreen({super.key});

  @override
  State<RecordingLibraryScreen> createState() => _RecordingLibraryScreenState();
}

class _RecordingLibraryScreenState extends State<RecordingLibraryScreen> {
  late Future<List<RecordedVideoInfo>> _videos;

  @override
  void initState() {
    super.initState();
    _videos = RecordedVideoLibrary.list();
  }

  void _reload() {
    setState(() => _videos = RecordedVideoLibrary.list());
  }

  Future<void> _share(RecordedVideoInfo video) async {
    await SharePlus.instance.share(
      ShareParams(
        text: video.name,
        files: [
          XFile(
            video.path,
            mimeType: 'video/mp4',
            name: p.basename(video.path),
          ),
        ],
      ),
    );
  }

  Future<void> _rename(RecordedVideoInfo video) async {
    final l10n = AppStrings.of(context);
    var value = video.name.replaceAll(
      RegExp(r'\.mp4$', caseSensitive: false),
      '',
    );
    final next = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.renameVideo),
        content: TextFormField(
          initialValue: value,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.recordingFileName),
          onChanged: (text) => value = text,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, value),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (next == null || next.trim().isEmpty) return;
    await RecordedVideoLibrary.rename(video.path, next.trim());
    if (mounted) _reload();
  }

  Future<void> _delete(RecordedVideoInfo video) async {
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
    await RecordedVideoLibrary.delete(video.path);
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.generatedVideos)),
      body: SafeArea(
        child: FutureBuilder<List<RecordedVideoInfo>>(
          future: _videos,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final videos = snapshot.data ?? const <RecordedVideoInfo>[];
            if (videos.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.video_library_outlined, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        l10n.noGeneratedVideos,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              itemCount: videos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final video = videos[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.movie_creation_outlined),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          video.path,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: XulangColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${_formatDate(video.modifiedAt)} · ${_formatSize(video.bytes)}',
                      style: const TextStyle(color: XulangColors.muted),
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => RecordingResultScreen(
                            videoPath: video.path,
                            title: video.name,
                            onDeleted: _reload,
                          ),
                        ),
                      );
                      if (mounted) _reload();
                    },
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: l10n.share,
                          onPressed: () => _share(video),
                          icon: const Icon(Icons.ios_share_outlined),
                        ),
                        IconButton(
                          tooltip: l10n.rename,
                          onPressed: () => _rename(video),
                          icon: const Icon(Icons.drive_file_rename_outline),
                        ),
                        IconButton(
                          tooltip: l10n.delete,
                          onPressed: () => _delete(video),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

String _formatSize(int bytes) {
  final mb = bytes / (1024 * 1024);
  if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
  final kb = bytes / 1024;
  return '${kb.toStringAsFixed(0)} KB';
}
