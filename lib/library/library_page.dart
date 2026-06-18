import 'dart:async';

import 'package:cabina/common/theme/app_theme.dart';
import 'package:cabina/common/widgets/poster_image.dart';
import 'package:cabina/common/widgets/status_views.dart';
import 'package:cabina/library/library_store.dart';
import 'package:flutter/material.dart';

// The Library tab. Reads/writes LibraryStore directly and manages everything
// with setState. This is the half-built feature to finish and refactor.
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(
      LibraryStore.instance.load().then((_) {
        if (mounted) setState(() => _loading = false);
      }),
    );
  }

  Future<void> _unsubscribe(int id) async {
    await LibraryStore.instance.unsubscribe(id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final items = LibraryStore.instance.items;
    return Scaffold(
      appBar: AppBar(title: const Text('Library', style: AppTextStyles.title)),
      body: _loading
          ? const LoaderView()
          : items.isEmpty
              ? const EmptyView(
                  message: 'Subscribe to a podcast to see it here',
                  icon: Icons.library_music_outlined,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: SizedBox(
                        width: 52,
                        height: 52,
                        child: item.artworkUrl == null
                            ? Container(color: theme.surface)
                            : PosterImage(url: item.artworkUrl!, size: 52),
                      ),
                      title: Text(item.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(item.author,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _unsubscribe(item.id),
                      ),
                    );
                  },
                ),
    );
  }
}
