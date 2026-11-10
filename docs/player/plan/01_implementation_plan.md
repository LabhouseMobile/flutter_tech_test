# 01 · Player refactor: only the seek bar rebuilds on position ticks, PlayerBloc over a PlayerRepository, errors reach the UI

**Priority/Effort:** P2 · L  **Depends on:** none
**Status:** applied
**Commit draft(s):**
1. `refactor(player): ♻️ replace IPlayerService and the pass-through repository with PlayerRepository.`
2. `refactor(player): ♻️ rebuild only the widgets whose slice of the state changed.`
3. `fix(player): 🐛 stop awaiting play and surface playback action errors.`
4. `fix(player): 🐛 seek once on drag end and clamp skips to the episode length.`
5. `refactor(player): ♻️ document the feature, use theme colors and drop dead code.`

## Problem
**Rebuilds (the request)**
- `lib/player/views/player_page.dart:53-97`: one `BlocBuilder` wraps the whole body with no
  `buildWhen`. just_audio's `positionStream` ticks every 200 ms on anything longer than 160 s
  (`createPositionStream(steps: 800, maxPeriod: 200ms)`), and `_onPositionUpdated`
  (`audio_player_bloc.dart:97-111`) emits a new state per tick. So 5 times a second the artwork,
  both titles, the controls row and the play button are rebuilt, while only the slider and the
  elapsed time change.
- `lib/player/widgets/player_controls.dart:19,21-25`: `PlayerControls` takes `position` only to
  compute the skip target, which ties the whole row to the tick.
- `player_page.dart:58`, `audio_player_state.dart:15`: `state.args ?? widget.args`. `args` only ever
  holds the `widget.args` the page sent in `PlayerOpened`, so the page reads it from the state for
  nothing and the header depends on the bloc.

**Drift from AGENTS.md (technical_debt.md:13, technical_debt.md:14)**
- `lib/player/data/services/i_player_service.dart:6`: `IPlayerService`, `I` prefix, plain `abstract class`.
- `lib/player/data/audio_player_repository.dart:5-19`: pass-through, every member forwards.
- `lib/player/views/player_page.dart:29-31`: `route()` builds both layers inline.
- Files and classes named `audio_player_*` / `AudioPlayer*`; `test/player/audio_player_bloc_test.dart`
  sits at the feature root (technical_debt.md:80).
- `player_page.dart:26`: unused `context` in the route builder (technical_debt.md:77).

**Errors (technical_debt.md:10, technical_debt.md:11, technical_debt.md:12)**
- `audio_player_bloc.dart:59,78`: `await _repository.play()`. just_audio's `play()` completes when
  playback stops, so `_onOpened` and every play toggle stay pending for the whole episode.
- `audio_player_bloc.dart:71-95`: toggle, seek and speed have no `try`. A failure reaches
  `AppBlocObserver` and the UI never hears of it.
- `audio_player_bloc.dart:26-33`: stream errors go to `addError` only, same outcome.
- `just_audio_player_service.dart:52-62`: only `open` maps to `CabinaPlayerException`.

**Bugs found along the way**
- `lib/player/widgets/seek_bar.dart:29-33`: `onChanged` sends `PlayerSeeked` on every drag frame,
  a burst of platform seeks, and the next tick snaps the thumb back under the finger.
- `player_controls.dart:21-25`: `+30 s` isn't clamped to the episode length. Skipping near the end
  seeks past it.
- Found while applying step 4: clearing the drag value on release snapped the thumb back to the old
  position until the first tick after the seek.
- Found while applying step 5: `audio_player_bloc.dart:113-117` copies every engine status, so an
  `idle` reported after a failed open swaps the `ErrorView` for controls with nothing loaded.

**Smaller**
- `player_controls.dart:79`: `Colors.white` (technical_debt.md:81 said :77).
- `lib/player/models/player_position.dart:14-18`: `progress` has no reference in `lib/` or `test/`
  (technical_debt.md:79).
- No `///` on `PlayerPage`, `PlayerControls`, `SeekBar`, `PlayerPosition`, `PlayerStatus`,
  `PlaybackSpeed`, the bloc, its state and events (technical_debt.md:76).
- Tests cover close, open and stream errors only. Toggle, seek, speed, position and status
  handlers, the page and the service have none.

## Decisions
| Decision                  | Choice                                                                                                                                                                                                                      | Why                                                                                                                                    |
|---------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------|
| Granular rebuilds         | No `BlocBuilder` over the body. Each leaf watches its own slice with `context.select`: `SeekBar` → `position`, `_SpeedButton` → `speed`, `_PlayPauseButton` → `status`, the body → `status == error`                        | Same tool `SubscribeButton` already uses. A tick then rebuilds one `Slider` and two `Text`s                                            |
| Header                    | `_EpisodeHeader(args: widget.args)`, no bloc access                                                                                                                                                                         | Artwork and titles never change while the page is open                                                                                 |
| Skip target               | Skip buttons read `context.read<PlayerBloc>().state.position` on tap                                                                                                                                                        | Reading at tap time needs no rebuild; the row stops depending on the tick                                                              |
| `PlayerState.args`        | Removed. `PlayerOpened(args)` stays, the handler uses `args.episode`                                                                                                                                                        | Write-only state. The app-wide player (technical_debt.md:8) will add what it needs                                                     |
| Tick rate                 | Stays at just_audio's 200 ms                                                                                                                                                                                                | Once only the seek bar rebuilds, the cost is small, and short items keep a smooth thumb. A 1 s stream would make the bar move in steps |
| Repository                | `abstract interface class PlayerRepository` in `data/player_repository.dart`; `JustAudioPlayerService implements PlayerRepository`; `route()` → `PlayerBloc(repository: JustAudioPlayerService())`                          | AGENTS.md repository rule for a single SDK; route-scoped, so `route()` is where it's built                                             |
| Names                     | `PlayerBloc`, `PlayerEvent`, `PlayerState` in `bloc/player_{bloc,event,state}.dart`. Event names unchanged                                                                                                                  | Feature anatomy. just_audio's `PlayerState` is only used in the service, which never imports the bloc                                  |
| Bloc vs Cubit             | Stays a Bloc                                                                                                                                                                                                                | UI plus two engine streams, the case AGENTS.md names                                                                                   |
| `play()`                  | The bloc calls `unawaited(_repository.play().catchError(_fail))`. `_fail` adds a private `_PlayerFailed(error, stackTrace)` event unless the bloc is closed. Stream `onError` adds the same event                           | The future only tells us when playback ends or fails. An event keeps the failure traceable and lets a handler emit                     |
| Action errors             | `pause`, `seek`, `speed` and `_PlayerFailed`: `addError` + `errorMessage` in the state, `status` untouched. A `BlocListener` shows a SnackBar. A successful action emits `clearError`. `open` failure keeps the `ErrorView` | A failed seek shouldn't replace the screen. Same SnackBar pattern as `DiscoverPage` and `LibraryPage`                                  |
| Service errors            | A private `_guard` maps `PlayerException` and any other error to `CabinaPlayerException` with `cause`, for `open`, `play`, `pause`, `seekTo` and `setSpeed`; `_guardStream` does the same for both streams                  | AGENTS.md error rule; `open` already does it by hand                                                                                   |
| Seek bar drag (bug)       | `SeekBar` becomes stateful: a held value under the finger while dragging, a single `PlayerSeeked` in `onChangeEnd`                                                                                                          | One seek per gesture, and the thumb stays under the finger                                                                             |
| Skip clamp (bug)          | `+30 s` clamped to `total` when known                                                                                                                                                                                       | `-30 s` already clamps at zero                                                                                                         |
| `PlayerPosition.progress` | Deleted                                                                                                                                                                                                                     | Dead in `lib/` and `test/`                                                                                                             |
| Stays                     | Layout, labels, speed cycle, `±30 s`, `PlayerStatus` values, the route path and name, `PlayerArgs`, dispose on `close`                                                                                                      | Behaviour unchanged outside the bugs above and the error SnackBar                                                                      |

### Decided while applying
| Decision                     | Choice                                                                                                                        | Why                                                                                                                                                              |
|------------------------------|-------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Clearing the error           | `_clearError` at the start of each action, only when there is one                                                             | A bloc emits a state equal to the current one if it hasn't emitted yet, which added a stray state to the success paths                                           |
| Elapsed label while dragging | Follows the finger; otherwise the live position, unclamped                                                                    | Clamping the label too would freeze it at `0:00` while the total is unknown                                                                                      |
| Action error tests           | No `errors:` in the action-error `blocTest`s                                                                                  | `blocTest` swallows an uncaught handler error that matches `errors:` and then skips `expect`: they passed on the old code                                        |
| Selector guards              | `whenListen` tests for paused → playing, x1 → x1_25 and loading → error, in step 2                                            | Found in review: swapping a `context.select` for `context.read` kept every test green. They pass on the old code too, so they guard step 2 rather than pin a fix |
| `play()` test                | "GIVEN an opened episode WHEN playback fails THEN emits the message without the error status" replaces "play never completes" | Bloc cancels pending handlers on `close`, so a never-ending `play()` has no observable effect to pin. A late `play()` failure does                               |

## Open questions
None. Answered before applying:
1. Scope: every step in this plan, applied in order (0 → 5).
2. `audio_session` (technical_debt.md:18) stays open debt, with the app-wide player
   (technical_debt.md:8). Not configured here.

## Fix
**Step 0: pin (green on the old code).**
- Bloc tests for the uncovered handlers, and page widget tests over a `MockBloc` (see Tests first).

**Step 1: move and rename.** `git mv` first, then:
- `bloc/audio_player_{bloc,event,state}.dart` → `bloc/player_{bloc,event,state}.dart`, classes
  `PlayerBloc`, `PlayerEvent`, `PlayerState`.
- New `data/player_repository.dart`:
  ```dart
  /// Audio playback for one episode at a time. Failures are [CabinaPlayerException].
  abstract interface class PlayerRepository {
    Stream<PlayerPosition> get positionStream;
    Stream<PlayerStatus> get statusStream;
    Future<Duration?> open(String url);
    Future<void> play();
    Future<void> pause();
    Future<void> seekTo(Duration position);
    Future<void> setSpeed(double speed);
    Future<void> dispose();
  }
  ```
- `JustAudioPlayerService implements PlayerRepository`. Delete `i_player_service.dart` and
  `audio_player_repository.dart`.
- `route()`: `builder: (_, state)`, `PlayerBloc(repository: JustAudioPlayerService())`.
- `test/player/audio_player_bloc_test.dart` → `test/player/bloc/player_bloc_test.dart`, mocking
  `PlayerRepository`.

**Step 2: granular rebuilds.**
- `PlayerState`: drop `args`.
- `PlayerPage`: `BlocSelector<PlayerBloc, PlayerState, bool>` on `status == error` picks
  `ErrorView` or the content. The content is a `const`-friendly tree: `_EpisodeHeader(args)`,
  `const SeekBar()`, `const PlayerControls()`.
- `SeekBar`: no constructor params, `context.select((PlayerBloc b) => b.state.position)`.
- `PlayerControls`: no constructor params. `_SpeedButton` selects `speed`, `_PlayPauseButton`
  selects `status`, skips read the position on tap.

**Step 3: errors and `play()`.**
- Service: `_guard` around every engine call.
- Bloc: `try` in toggle, seek and speed as in Decisions; `play()` unawaited with `_onPlayFailed`;
  `_PlayerFailed` in the event part file; stream `onError` adds it.
- Page: `BlocListener` with `listenWhen` on a new non-null `errorMessage` while not in `error`
  status → SnackBar.

**Step 4: seek bar and skip.** `SeekBar` stateful with `_dragValue`; `onChanged` sets it,
`onChangeEnd` clears it and sends one `PlayerSeeked`. Skip forward clamps to `total`.

**Step 5: cleanup and docs.**
- `Colors.white` → `theme.onPrimary`. Delete `PlayerPosition.progress`. `///` on every public class.
- `AGENTS.md`: project map line 29 → `PlayerBloc`; line 72 → `PlayerBloc`; remove the `player/`
  Known debt row (line 113).
- technical_debt.md: lines 10 and 12–14 ✅, 11 🟡 until checked on a device; 9 renamed to
  `PlayerBloc.close`; 18 stays ❌; 79 without `PlayerPosition.progress`; 81 without
  `player_controls.dart`; 77 and 80 stay 🟡 with player done (other features still open).

## Files
- New: `lib/player/data/player_repository.dart`, `test/player/views/player_page_test.dart`,
  `test/player/widgets/seek_bar_test.dart`, `test/player/widgets/player_controls_test.dart`,
  `test/player/data/services/just_audio_player_service_test.dart`.
- Moved: `lib/player/bloc/audio_player_{bloc,event,state}.dart` →
  `lib/player/bloc/player_{bloc,event,state}.dart`; `test/player/audio_player_bloc_test.dart` →
  `test/player/bloc/player_bloc_test.dart`.
- Edited: `lib/player/views/player_page.dart`, `lib/player/widgets/{player_controls,seek_bar}.dart`,
  `lib/player/data/services/just_audio_player_service.dart`,
  `lib/player/models/{player_position,player_status,playback_speed}.dart`, `AGENTS.md`,
  `docs/tasks/technical_debt.md`.
- Deleted: `lib/player/data/audio_player_repository.dart`,
  `lib/player/data/services/i_player_service.dart`.

## Tests first
`test/player/bloc/player_bloc_test.dart` (step 0, green on old code, then renamed)
- GIVEN status playing WHEN PlayerPlayPauseToggled THEN calls pause. Pins the toggle.
- GIVEN status paused WHEN PlayerPlayPauseToggled THEN calls play.
- GIVEN a bloc WHEN PlayerSeeked(1 min) THEN calls seekTo(1 min).
- GIVEN speed x1 WHEN PlayerSpeedChanged(x1_25) THEN calls setSpeed(1.25) and emits speed x1_25.
- GIVEN a known total WHEN the position stream emits without total THEN keeps the known total.
- GIVEN a bloc WHEN the status stream emits playing THEN emits status playing.

`test/player/bloc/player_bloc_test.dart` (step 3, fail on old code)
- GIVEN an opened episode WHEN playback fails THEN emits the message without the error status.
  Pins technical_debt.md:10 (the old code awaited `play()` inside the open `try`).
- GIVEN seekTo throws CabinaPlayerException WHEN PlayerSeeked THEN emits its message, status
  unchanged.
- GIVEN pause / setSpeed throws WHEN the action THEN emits the message (one test each).
- GIVEN play fails WHEN PlayerPlayPauseToggled THEN emits the message.
- GIVEN the status stream errors THEN emits CabinaException.fallbackMessage (replaces the two
  "reaches errors" tests, which keep their `errors:` expectation).
- GIVEN a previous action error WHEN an action succeeds THEN errorMessage is cleared.

`test/player/data/services/just_audio_player_service_test.dart` (step 3, mocked `AudioPlayer`)
- GIVEN the engine throws PlayerException WHEN seekTo / pause / setSpeed / play THEN throws
  CabinaPlayerException with the original as cause.

`test/player/views/player_page_test.dart` (`MockBloc`, `MaterialApp(theme: AppTheme(isDark: false).toThemeData())`)
- Step 0: GIVEN a ready state THEN shows the episode and podcast titles. GIVEN error status THEN
  shows ErrorView with the message. GIVEN the page opens THEN adds PlayerOpened(args).
- Step 2, fails on old code: GIVEN a playing state WHEN only the position changes THEN the
  `PosterImage` and the controls' `Row` are the same widget instances (not rebuilt) and the
  `Slider` is a new one. Pins the request.
- Step 2, guards the `BlocSelector`: GIVEN a loading episode WHEN opening fails THEN replaces the
  player with the ErrorView.
- Step 3: GIVEN a playing state WHEN an errorMessage arrives THEN shows a SnackBar and keeps the
  controls.

`test/player/widgets/player_controls_test.dart`
- Step 0: GIVEN paused WHEN tapping play THEN adds PlayerPlayPauseToggled. GIVEN x1 WHEN tapping
  the speed label THEN adds PlayerSpeedChanged(x1_25). GIVEN position 10 s WHEN tapping replay 30
  THEN adds PlayerSeeked(zero).
- Step 2, guard each `context.select`: GIVEN paused WHEN the status changes to playing THEN the
  button shows pause. GIVEN x1 WHEN the speed changes to x1_25 THEN the label shows the new speed.
- Step 4, fails on old code: GIVEN position 4:50 of 5:00 WHEN tapping forward 30 THEN adds
  PlayerSeeked(5:00).

`test/player/widgets/seek_bar_test.dart` (step 4, fails on old code)
- GIVEN a 5 min episode WHEN dragging the slider THEN adds exactly one PlayerSeeked, on release.
- GIVEN a drag in progress WHEN a position tick arrives THEN the thumb keeps the drag value.

## Audit checklist
- Architecture: repository rule followed, no pass-through, route-scoped bloc built in `route()`.
- State: `Equatable`, every field in `props`, `clearError`, no mutation.
- Errors: every handler `try` → `addError` → `messageOf`; service maps to `CabinaPlayerException`.
- Performance: a position tick rebuilds `SeekBar` only (pinned by the page test).
- Theme: no hardcoded colors in `player/`.
- Docs: `///` on every public class in `player/`.
- Tests: bloc tests under `test/player/bloc/`, each bug fix with a test that fails on the old code.

## Out of scope
- App-wide player, mini-player and native controls (technical_debt.md:8): needs app-scoped DI and
  `home/` changes.
- `audio_session` configuration (technical_debt.md:18): decided with the app-wide player.
- `PlayerArgs` used by `show_detail` (technical_debt.md:67): moving it changes another feature's
  imports.
- `state.extra!` (technical_debt.md:48): shared with `ShowDetailPage`, unreachable without deep
  links.
- `_PlayPauseButton` is a `GestureDetector` with no semantics or ripple: accessibility pass, not
  this refactor.

## Verify
- `fvm flutter analyze`, `fvm dart format --set-exit-if-changed .`, `fvm flutter test`.
- Device: open an episode, turn on "Highlight repaints" or the rebuild counter in DevTools while
  it plays, and check that only the seek bar updates. Drag the slider (one seek on release), skip
  near the end, pause and resume, change speed, go back (audio stops).

## Usage
API list-price equivalent, from `usage-ledger report` at hand-off. The apply turn is still open,
so it lands on the next sync (the Stop hook) under `player / apply-0` to `apply-5`.
```
player           ░░░░░░░░░░░░░░░░░░░░      2.70     2%          1      43     5.9M       12m
  plan           ░░░░░░░░░░░░░░░░░░░░      2.70     2%          1      43     5.9M       12m
```
