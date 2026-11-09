import 'package:cabina/common/theme/app_theme.dart';
import 'package:cabina/player/bloc/player_bloc.dart';
import 'package:cabina/player/models/playback_speed.dart';
import 'package:cabina/player/models/player_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  /// Reads the position on tap, so the row doesn't rebuild on every tick.
  /// The target stays within the episode: zero, and its length when known.
  void _skip(BuildContext context, Duration delta) {
    final bloc = context.read<PlayerBloc>();
    final position = bloc.state.position;
    var target = position.position + delta;
    if (target < Duration.zero) target = Duration.zero;
    final total = position.total;
    if (total != null && target > total) target = total;
    bloc.add(PlayerSeeked(target));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const _SpeedButton(),
        IconButton(
          iconSize: 34,
          icon: const Icon(Icons.replay_30),
          onPressed: () => _skip(context, const Duration(seconds: -30)),
        ),
        const _PlayPauseButton(),
        IconButton(
          iconSize: 34,
          icon: const Icon(Icons.forward_30),
          onPressed: () => _skip(context, const Duration(seconds: 30)),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton();

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final speed = context.select<PlayerBloc, PlaybackSpeed>(
      (bloc) => bloc.state.speed,
    );
    return TextButton(
      onPressed: () =>
          context.read<PlayerBloc>().add(PlayerSpeedChanged(speed.next)),
      child: Text(
        speed.label,
        style: AppTextStyles.label.copyWith(color: theme.foreground),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton();

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final status = context.select<PlayerBloc, PlayerStatus>(
      (bloc) => bloc.state.status,
    );
    return GestureDetector(
      onTap: () =>
          context.read<PlayerBloc>().add(const PlayerPlayPauseToggled()),
      child: CircleAvatar(
        radius: 34,
        backgroundColor: theme.primary,
        child: status.isBusy
            ? const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Icon(
                status.isPlaying ? Icons.pause : Icons.play_arrow,
                color: theme.onPrimary,
                size: 40,
              ),
      ),
    );
  }
}
