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
  - Local persistence → `shared_preferences`.
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

## AI environment

Agents in development went from autocomplete, to harnesses and apps, to repositories that are ready
for an agent like Claude, Gemini or GPT to work in. `AGENTS.md` and the skill files are what make
that possible here: whatever model a dev uses, everyone shares the same environment and the same
rules.

### What's in it

| Path                                           | What it is                                                                                                                                      |
|------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------|
| `AGENTS.md`                                    | The rules for agents and humans: stack, project map, layers, state, errors, tests, known debt, and when to stop and ask. No `CLAUDE.md`.        |
| `.agent/skills/feature-refactor/`              | Refactors one feature so it follows `AGENTS.md`. Writes a plan in the feature's `plan/` and stops for approval before touching code.            |
| `.agent/skills/staged-audit/`                  | Read-only audit of what's staged. Classifies findings P0–P3 and scores the change from 1 to 300.                                                |
| `docs/<feature>/plan/`                         | One plan per change (`NN_implementation_plan.md`). Problem, decisions, tests first, out of scope. Approved before any code.                     |
| `docs/tasks/technical_debt.md`                 | Known issues and their status (✅ 🟡 ❌). The source of truth.                                                                                  |
| `docs/tasks/human_notes_repo_review.md`        | My handwritten notes from reviewing the app: bugs, improvements, architectural questions.                                                       |
| [`docs/marcos_brain.md`](docs/marcos_brain.md) | Why the repository looks the way it does, and how I think about working with AI.                                                                |

### Setup

Claude Code reads skills from `.claude/skills`, and `.claude/` is git-ignored. Link it once:

```bash
mkdir -p .claude && ln -s ../.agent/skills .claude/skills
```

Other agents read `AGENTS.md` from the root.

### Workflow

1. A plan in `docs/<feature>/plan/`, and it waits for approval.
2. Tests first, then the change.
3. Gates green: `fvm flutter analyze`, `fvm dart format`, `fvm flutter test`.
4. I stage the files by hand. The agent never runs `git add`, commits or pushes.
5. `staged-audit` on what's staged, then the commit.

### usage-ledger

`usage-ledger` is a plugin I built for this workflow. It measures AI usage in time and money
(tokens) every time the AI works on a feature, from the implementation to the questions we ask it
along the way. It's not there to take credit away from the developer's work. It's there to know
what a feature or a refactor really costs.

In Claude Code:

1. `/plugin marketplace add muric-dev/dev-workflow-plugins`
2. `/plugin install usage-ledger@dev-workflow-plugins`
3. From there it runs as `/usage-ledger:usage-ledger`

`feature-refactor` knows `usage-ledger` exists and logs each phase with it. If it isn't installed,
that step is skipped.

## Configuration — AI Companion

The AI Companion (added as part of the test) needs an OpenAI API key. **Do not commit it.** It lives
in a `.env` file at the root, which is git-ignored:

1. Copy `.env.example` to `.env` and fill in `OPENAI_API_KEY=`.
2. Run `fvm flutter run --dart-define-from-file=.env`.

There is a single environment, so there is no `env.dart`: the feature reads the key with
`String.fromEnvironment('OPENAI_API_KEY')`. What the feature does and how to try each path is in
[`docs/ai_companion/README.md`](docs/ai_companion/README.md).
