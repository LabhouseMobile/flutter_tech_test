# Cabina

A podcast app built with Flutter. Search podcasts, open a show to browse its
episodes, and stream an episode. A personal Library lets you keep the shows you
follow.

> This is the starting point for the Labhouse Flutter technical test. Please read
> the test brief you were sent alongside this repository before you begin.

## Requirements

- Flutter `3.41.x` (Dart `3.11.x`). The exact version is pinned in `.fvmrc`
  (`3.41.9`).
- An iOS Simulator / device or an Android emulator / device.

### Flutter SDK via FVM (recommended)

The project pins its Flutter SDK with [FVM](https://fvm.app) so everyone builds
against the same version. Install FVM and the pinned SDK once:

```bash
brew install fvm            # or: dart pub global activate fvm
fvm install                 # reads .fvmrc and installs Flutter 3.41.9
```

Then prefix Flutter/Dart commands with `fvm` (see below). For the IDE: VS Code
picks up the SDK automatically via `.vscode/settings.json`; in Android
Studio / IntelliJ set the Flutter SDK path to `<project>/.fvm/flutter_sdk`.

> Prefer managing Flutter yourself? Any `3.41.x` SDK works — just drop the `fvm`
> prefix from the commands below.

## Running

```bash
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs   # generates *.g.dart
fvm flutter run
```

The app targets **iOS and Android**. No API keys or accounts are required to run
the core app.

## Tech overview

- **State:** `flutter_bloc` (BLoC + Cubit), manual DI via
  `RepositoryProvider` / `BlocProvider`.
- **Navigation:** `go_router`.
- **Data:**
  - Discover / Search → [iTunes Search API](https://performance-partners.apple.com/search-api)
    (no key).
  - Show detail → the podcast's **RSS feed** (parsed with `package:xml`).
  - Audio → streamed with `just_audio`.
  - Local persistence → `shared_preferences` / `hive`.
- **Models:** `json_serializable` + `equatable` + `copyWith` (run `build_runner`
  after changing an annotated model).
- **Theming:** a `ThemeExtension` (`AppTheme`) — read colors via
  `context.appTheme`.

### Project layout

```
lib/
  app/            App widget + dependency injection
  common/         Theme, errors, networking, shared widgets, extensions
  discover/       Discover grid + favourites
  search/         Podcast search
  show_detail/    Podcast detail + RSS feed parsing + episodes
  player/         Audio player (just_audio)
  library/        The user's followed podcasts
  router/         go_router configuration
  home/           Bottom-nav shell
```

## Tests

```bash
flutter test
```

A few example tests live under `test/` — use them as a pattern for any you add.

## Configuration — AI Companion

The AI Episode Companion (added as part of the test) needs an LLM provider key.
**Do not commit it.** Define it as a documented constant the reviewer can fill in
locally, e.g.:

```dart
// lib/common/env/env.dart
// TODO(reviewer): provide an OpenAI/Anthropic API key to run the AI feature.
const String kLlmApiKey = String.fromEnvironment('LLM_API_KEY');
```

and document here how to provide it (e.g.
`flutter run --dart-define=LLM_API_KEY=...`).
