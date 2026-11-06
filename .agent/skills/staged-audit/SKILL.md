---
name: staged-audit
description: Audit of the staged code before committing. Classifies findings as P0–P3 and gives the change an overall score from 1 to 300, broken down into weighted categories. Use it when asked to "audit what's staged", "review before commit", "can I commit this?", "score the diff" or "find P0s".
---

# Staged Audit (Flutter/Dart)

Read-only audit of **what would go into the next commit**, nothing more and nothing less.

Hard rules:
- Use git read-only: don't run `git add`, `commit`, `stash` or `reset`. Exporting the index to a
  temporary folder (Phase 2) is allowed because it doesn't touch the repo.
- Audit the **staged blob** (`git show :<path>`), not the working tree. They differ when a file is
  both staged *and* modified (`AM`, `MM`).
- Be pragmatic: each finding proposes the smallest fix that solves it. No rewrites.
- A problem that existed before the diff, in a feature the diff touches (`lib/<feature>/`, or the
  touched file for `common/`), is a normal finding: it gets its priority and counts toward the
  verdict and the score, because the change fixes it (`AGENTS.md` → Workflow). Mark it
  `(pre-existing)` and out of scope, without blocking or lowering the score, only when it sits in a
  feature the diff doesn't touch or its fix would change another feature's contract.

## Phase 1: Scope

Read `git diff --cached` and `git status --short`. For each staged file that also has unstaged changes, compare `git show :<path>` with the file on
disk and note it: **the commit will carry the staged version**.
If nothing is staged, say so and stop.

## Phase 2: Mechanical gates (on the staged snapshot)

If `git status --short` shows no unstaged or untracked paths under `lib/` or `test/`, and none on
`pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml` or `.fvmrc`, run the gates on the working
tree. Otherwise run them inside a copy of the index, and delete it when the gates are
done:

```bash
snap="$(mktemp -d)"
git checkout-index -a --prefix="$snap/"
mkdir -p "$snap/.dart_tool" && cp .dart_tool/package_config.json "$snap/.dart_tool/"
cd "$snap"   # run the gates in this same shell command; afterwards: cd - && rm -rf "$snap"
```

1. `fvm flutter analyze <touched files>` → any `error` is **P0**; warnings and lints are **P3**.
2. `fvm dart format --output=none --set-exit-if-changed <touched files>` → differences are **P3**.
3. `fvm flutter test` on the staged `_test.dart` files plus the tests of the touched `lib/` files
   (the mirror path, or `test/<feature>/*_bloc_test.dart` / `*_cubit_test.dart` until refactored)
   → a red test or one that doesn't compile is **P0**.

Report the numbers you observed, never the ones you assume.

## Phase 3: Context

Read **the whole file** for each change, not just the hunk. Also look for:
- the callers of the changed symbols, to see whether any contract breaks;
- the file's existing test;
- `analysis_options.yaml` and `pubspec.yaml`, for the lint rules and the bloc and go_router versions.

## Phase 4: Finding search

Walk the diff with these lenses. Each finding carries `file:line`, the concrete scenario
(input/state → wrong result) and the minimal fix.

| Priority | Meaning                                                                                                                   | Examples                                                                                                                                                                   |
|----------|---------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **P0**   | Blocks the commit. Doesn't compile, crashes, red tests, data loss, leaked secret, or the user gets stuck.                 | `!` on a reachable null, `context.read` after an `await` without `mounted`, a stream/controller that never closes and keeps audio playing |
| **P1**   | A real bug the user will see, or a contract regression. Fix before merging.                                               | an error state that's never cleared (`copyWith` with `??`), out-of-order responses, a tap that does nothing, infinite loading                                              |
| **P2**   | Debt that will cost: missing test for the changed behaviour, duplication, a violated layer, a visible but rare edge case. | the new branch has no test, the UI calls a repository or service directly                                                                                                  |
| **P3**   | Polish: names, formatting, brittle asserts, symmetry, docs.                                                               | `find.byType(Text)` to assert absence, a magic spacing number                                                                                                              |

**Lenses (minimum checklist, without repeating what `dart analyze` already covers):**

1. **Correctness and UX:** nulls, empty lists, negative or zero values, units (sec/min), time
   zones, `mounted` after `await`, dispose/close, double tap, unnecessary rebuilds, text overflow.
2. **Tests (TDD):** per `AGENTS.md` → Tests; every new or changed branch has a test that would fail
   without the change.
3. **Architecture:** check the diff against `AGENTS.md` → Feature anatomy, and Layers and DI.
4. **Bloc:** check the diff against `AGENTS.md` → State management.
5. **Defensive programming:** validation at the edge (parsers, `fromJson`), typed errors instead
   of a silent `catch (_)`, `try` around I/O, no `!` unless there's a documented invariant, visible
   fallbacks in the UI (placeholder, retry).
6. **Clean/DRY/KISS:** check the diff against `AGENTS.md` → Code rules. For DRY apply the rule of
   three: with 2 copies, note it (P3); with 3 or more, extract (P2).

User-facing strings are hardcoded English by decision (`AGENTS.md`: no l10n), so don't flag them.

Discard anything you can't back with a concrete line of code. When in doubt, it's not a P0.

## Phase 5: Overall score (1–300)

The change gets **a single score from 1 to 300**. The categories are the breakdown: each one adds
points up to its maximum weight, and the weights sum to 300. Score **only what the diff touches**, with
one line of justification per category.

| Category              | Weight | What it looks at                                                                                 |
|-----------------------|--------|--------------------------------------------------------------------------------------------------|
| Defensive Programming | 45     | nulls, edges, errors, dispose                                                                    |
| TDD                   | 45     | coverage of the changed behaviour and test quality                                               |
| Clean Code            | 35     | names, size, readability, formatting, class docs                                                 |
| Feature First         | 30     | placement by feature, boundaries between features                                                |
| KISS                  | 30     | the simplest solution that works, no extra layers                                                |
| VGV Principles        | 30     | clean very_good_analysis, theming via `ThemeData`/`ThemeExtension`                               |
| Repository principles | 30     | one-way layers, injection, models parsed at the edge, a single source of truth                    |
| Scalability           | 30     | how easy it is to add the next case (another format, screen, pagination)                         |
| DRY                   | 25     | new duplication, reuse of helpers and extensions                                                 |

Calculation:
Compute these with a shell command (for example `awk`), not by hand.
1. **Raw** = sum of the points. If a category can't be evaluated in the diff, mark it `N/A` with the
   reason and rescale: `raw × 300 / sum of evaluated weights`, rounded.
2. **Severity cap** (the most severe open finding wins): with a P0, at most **89**; with a P1,
   at most **149**; with a P2, at most **209**. If the cap applies, show raw and final (`207 → 89`).

| Band       | Range   | Reading                                  |
|------------|---------|------------------------------------------|
| Exemplary  | 270–300 | You'd use it as a reference in the repo  |
| Solid      | 210–269 | P3 findings at most                      |
| Acceptable | 150–209 | Some P2                                  |
| Weak       | 90–149  | Open P1                                  |
| Blocking   | 1–89    | Open P0                                  |

## Phase 6: Report

Fixed format, no extra prose:

```
## Verdict: BLOCK | FIX-THEN-COMMIT | COMMIT
<one line: why>

### Scope
<staged files, + staged vs working tree differences>

### Gates
analyze: <n errors/warnings> · format: <ok/n files> · tests: <n passed / n failed>

### Findings
#### P0
- `file:line` — <defect>. Scenario: <...>. Fix: <...>
#### P1 / P2 / P3
...

### Score: <final>/300 (<band>)
| Category | Points | Justification |
...
| **Raw** | x/300 | |
| **Final** | y/300 | <cap applied or "no cap"> |

### Out of scope (pre-existing)
- <pre-existing issues the change leaves out of scope (another feature, or a cross-feature fix), each with why, or "none">
```

Verdict: there's a P0 → **BLOCK**. There's a P1 → **FIX-THEN-COMMIT**. Otherwise → **COMMIT**. P2/P3
can go in another commit.
