import 'package:cabina/common/extensions/duration_format.dart';
import 'package:cabina/common/theme/app_theme.dart';
import 'package:cabina/show_detail/models/episode.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EpisodeTile extends StatelessWidget {
  const EpisodeTile({required this.episode, required this.onTap, super.key});

  final Episode episode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final published = episode.publishedAt;
    final meta = [
      if (published != null) DateFormat.yMMMd().format(published),
      if (episode.duration != null && episode.duration! > Duration.zero)
        episode.duration!.human,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(Icons.play_circle_fill, color: theme.primary, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(color: theme.foreground),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(meta,
                        style: AppTextStyles.caption
                            .copyWith(color: theme.foregroundSoft)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
