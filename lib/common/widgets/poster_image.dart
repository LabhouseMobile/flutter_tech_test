import 'package:cabina/common/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Square artwork used across discover/search/detail. Renders a rounded image
/// with graceful loading + error states.
class PosterImage extends StatelessWidget {
  const PosterImage({
    required this.url,
    this.size,
    this.borderRadius = 12,
    super.key,
  });

  final String url;
  final double? size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: size,
            height: size,
            color: theme.surface,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stack) => Container(
          width: size,
          height: size,
          color: theme.surface,
          child: Icon(Icons.podcasts, color: theme.foregroundSoft),
        ),
      ),
    );
  }
}
