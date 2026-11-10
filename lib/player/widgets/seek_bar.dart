import 'package:cabina/common/extensions/duration_format.dart';
import 'package:cabina/common/theme/app_theme.dart';
import 'package:cabina/player/bloc/player_bloc.dart';
import 'package:cabina/player/models/player_position.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Slider and elapsed / total time. The only part of the player that rebuilds
/// on every position tick. Disabled while the episode length is unknown.
class SeekBar extends StatefulWidget {
  const SeekBar({super.key});

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  /// Where the thumb is held, in milliseconds: under the finger while
  /// dragging, so ticks don't move it and the bloc gets a single seek on
  /// release; then at the release point until the next position tick, so it
  /// doesn't snap back to the old position while the seek is in flight.
  /// just_audio emits the target position as soon as `seek()` is called.
  double? _heldValue;
  bool _dragging = false;

  void _releaseOnTick() {
    if (_dragging || _heldValue == null) return;
    setState(() => _heldValue = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final position = context.select<PlayerBloc, PlayerPosition>(
      (bloc) => bloc.state.position,
    );
    final total = position.total ?? Duration.zero;
    final maxMs = total.inMilliseconds.toDouble();
    final canSeek = maxMs > 0;
    final heldValue = _heldValue;
    final elapsed = heldValue == null
        ? position.position
        : Duration(milliseconds: heldValue.round());
    final valueMs = elapsed.inMilliseconds.toDouble().clamp(0.0, maxMs);

    return BlocListener<PlayerBloc, PlayerState>(
      listenWhen: (previous, current) => previous.position != current.position,
      listener: (_, _) => _releaseOnTick(),
      child: Column(
        children: [
          Slider(
            value: canSeek ? valueMs : 0,
            max: canSeek ? maxMs : 1,
            activeColor: theme.primary,
            onChangeStart: (_) => _dragging = true,
            onChanged: canSeek
                ? (value) => setState(() => _heldValue = value)
                : null,
            onChangeEnd: (value) {
              _dragging = false;
              setState(() => _heldValue = value);
              context.read<PlayerBloc>().add(
                PlayerSeeked(Duration(milliseconds: value.round())),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(elapsed.clock, style: AppTextStyles.caption),
                Text(total.clock, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
