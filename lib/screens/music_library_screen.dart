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
  List<MusicLibraryItem>? _items;
  bool _loadingCache = true;
  bool _refreshing = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadCachedThenRefresh();
  }

  @override
  void didUpdateWidget(covariant _MusicLibraryBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _loadCachedThenRefresh();
    }
  }

  Future<void> _loadCachedThenRefresh() async {
    final access = ref.read(documentAccessServiceProvider);
    setState(() {
      _loadingCache = true;
      _error = null;
    });
    final cached = await access.readCachedMusic(
      displayNames: widget.settings.musicDisplayNames,
    );
    if (!mounted) return;
    setState(() {
      _items = cached;
      _loadingCache = false;
    });
    await _refresh();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _error = null;
    });
    try {
      final items = await ref
          .read(documentAccessServiceProvider)
          .scanMusic(
            authorizedDirectories: widget.settings.authorizedFolderPaths,
            displayNames: widget.settings.musicDisplayNames,
          );
      if (!mounted) return;
      setState(() => _items = items);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
      if ((_items ?? const <MusicLibraryItem>[]).isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.of(context).authorizeFolder}: $error'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
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
    if (mounted) await _loadCachedThenRefresh();
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
    if (mounted) await _loadCachedThenRefresh();
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
        child: Builder(
          builder: (context) {
            final items = _items ?? const <MusicLibraryItem>[];
            if (_loadingCache && items.isEmpty) {
              return Center(
                child: _LoadingMessage(message: l10n.scanningMusic),
              );
            }
            if (_error != null && items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(
                    '${l10n.authorizeFolder}\n$_error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: XulangColors.muted),
                  ),
                ),
              );
            }
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
                        _refreshing ? l10n.scanningMusic : l10n.localPath,
                        style: const TextStyle(color: XulangColors.muted),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              itemCount: items.length + (_refreshing ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (_refreshing && index == 0) {
                  return Card(
                    child: ListTile(
                      leading: const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      title: Text(l10n.refreshingLocalFiles),
                    ),
                  );
                }
                final itemIndex = _refreshing ? index - 1 : index;
                final item = items[itemIndex];
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

class _LoadingMessage extends StatelessWidget {
  const _LoadingMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: XulangColors.muted),
        ),
      ],
    );
  }
}

String _formatSize(int bytes) {
  final mb = bytes / (1024 * 1024);
  if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
  final kb = bytes / 1024;
  return '${kb.toStringAsFixed(0)} KB';
}
