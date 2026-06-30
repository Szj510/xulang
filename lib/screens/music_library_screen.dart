import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xulang/data/document_access_service.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/l10n/app_strings.dart';
import 'package:xulang/providers/app_providers.dart';
import 'package:xulang/theme/xulang_theme.dart';

class MusicLibraryScreen extends ConsumerWidget {
  const MusicLibraryScreen({super.key, this.selectionMode = false});

  final bool selectionMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    return settingsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(AppStrings.of(context).musicLibrary)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(AppStrings.of(context).musicLibrary)),
        body: Center(child: Text('$error')),
      ),
      data: (settings) =>
          _MusicLibraryBody(settings: settings, selectionMode: selectionMode),
    );
  }
}

class _MusicLibraryBody extends ConsumerStatefulWidget {
  const _MusicLibraryBody({
    required this.settings,
    required this.selectionMode,
  });

  final AppSettings settings;
  final bool selectionMode;

  @override
  ConsumerState<_MusicLibraryBody> createState() => _MusicLibraryBodyState();
}

class _MusicLibraryBodyState extends ConsumerState<_MusicLibraryBody> {
  late Future<List<MusicLibraryItem>> _items;

  @override
  void initState() {
    super.initState();
    _items = _load();
  }

  @override
  void didUpdateWidget(covariant _MusicLibraryBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _items = _load();
    }
  }

  Future<List<MusicLibraryItem>> _load() {
    return ref
        .read(documentAccessServiceProvider)
        .scanMusic(
          authorizedDirectories: widget.settings.authorizedFolderPaths,
          displayNames: widget.settings.musicDisplayNames,
        );
  }

  void _reload() {
    setState(() => _items = _load());
  }

  Future<void> _authorizeFolder() async {
    final access = ref.read(documentAccessServiceProvider);
    final path = await access.requestDirectory();
    if (path == null || path.trim().isEmpty) return;
    final next = widget.settings.copyWith(
      authorizedFolderPaths: [
        ...widget.settings.authorizedFolderPaths,
        if (!widget.settings.authorizedFolderPaths.contains(path)) path,
      ],
    );
    await ref.read(galleryRepositoryProvider).saveAppSettings(next);
    if (mounted) _reload();
  }

  Future<void> _rename(MusicLibraryItem item) async {
    final l10n = AppStrings.of(context);
    var value = item.displayName;
    final next = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.rename),
        content: TextFormField(
          initialValue: value,
          autofocus: true,
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
    final names = Map<String, String>.from(widget.settings.musicDisplayNames)
      ..[item.path] = next.trim();
    await ref
        .read(galleryRepositoryProvider)
        .saveAppSettings(widget.settings.copyWith(musicDisplayNames: names));
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.musicLibrary),
        actions: [
          IconButton(
            tooltip: l10n.authorizeFolder,
            onPressed: _authorizeFolder,
            icon: const Icon(Icons.folder_open_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<MusicLibraryItem>>(
          future: _items,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(
                    '${l10n.authorizeFolder}\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: XulangColors.muted),
                  ),
                ),
              );
            }
            final items = snapshot.data ?? const <MusicLibraryItem>[];
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.music_note_outlined, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        l10n.authorizeFolder,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.localPath,
                        style: const TextStyle(color: XulangColors.muted),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.audio_file_outlined),
                    title: Text(
                      item.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${_formatSize(item.bytes)} · ${item.fileName}\n${item.path}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: XulangColors.muted),
                    ),
                    onTap: widget.selectionMode
                        ? () => Navigator.pop(context, item)
                        : null,
                    trailing: IconButton(
                      tooltip: l10n.rename,
                      onPressed: () => _rename(item),
                      icon: const Icon(Icons.drive_file_rename_outline),
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

String _formatSize(int bytes) {
  final mb = bytes / (1024 * 1024);
  if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
  final kb = bytes / 1024;
  return '${kb.toStringAsFixed(0)} KB';
}
