---
name: feature-refactor
description: Refactor one existing Cabina feature so it follows AGENTS.md. Removes over-abstraction and dead or unreachable code, reuses common/ and the packages already in pubspec.yaml, and fixes layer, naming and docs drift. It writes a plan in docs/<feature>/plan and stops for approval before touching code. Use it when asked to "refactor <feature>", "clean up <feature>", "simplify <feature>", "align <feature> with our patterns".
---

# Feature Refactor

Bring **one feature** in line with `AGENTS.md` using the smallest change that gets it there. Behaviour
stays the same unless the plan says otherwise. A bug found along the way is a decision, not a side
effect.

Hard rules:
- One feature per run. If the request spans more, or the fix needs another feature's contract to
  change, ask.
- Usage: if the usage-ledger skill is installed, run it with `phase <feature> <phase>` at the
  start of each phase: `inventory`, `findings`, `plan`, `apply-<n>` per plan step, `handoff`.
  After the hand-off, run `phase unassigned unassigned`.

## Phase 1: Inventory
- Every file in `lib/<feature>/` and `test/<feature>/`, read in full.
- Everything outside the feature that uses it: imports of `package:cabina/<feature>/`, providers in
  `AppDependencyInjection`, routes.
- What the feature imports from other features. Only Pages are allowed.
- The feature's lines in `docs/tasks/technical_debt.md`.

## Phase 2: Findings
Each finding gets `file:line`, what is wrong, and the smallest fix. Apply these lenses:

1. **Over-abstraction:** interfaces outside the repository rule, pass-through classes or methods,
   parameters nobody passes, layers that add nothing, and "generic" helpers with a single caller.
2. **Dead and unreachable code:** the analyzer already reports private and local dead code. Call a
   public member dead only after confirming it has zero references in `lib/` and `test/`. Code that
   only tests reference is dead in the app: raise it as a decision. Unreachable code includes
   fallbacks for values that can't be null, catches for errors nothing throws, and statuses that are
   never emitted.
3. **Reinvented code:** logic that already exists in `common/` or in a `pubspec.yaml` package, and
   duplication inside the feature or with another feature (rule of three).
4. **Drift from `AGENTS.md`:** anatomy and folders, layers (a widget touching a repository, a service
   or prefs), Cubit vs Bloc, state shape, error flow, cross-feature imports, naming, DI scope.
5. **Docs:** public classes without `///`, or `///` that no longer matches the code.
6. **Bugs found along the way:** record them, don't fix them silently. Each one becomes a row in
   Decisions.

Drop any finding you can't point to a line for.

## Phase 3: Plan, then stop
Write `docs/<feature>/plan/NN_implementation_plan.md` in the plan format from `AGENTS.md` → Workflow,
with these refactor specifics:
- Title: `# NN · <Feature> refactor: <one-line outcome>`.
- Status: `draft`. Set it to `approved` when the user approves, and to `applied` after the last step.
- Commit drafts: `refactor(<feature>): ♻️ <summary>.`
- Decisions is always present and includes what deliberately stays.
- Add `## Open questions` after Decisions: what you need from the user, or "None".

Then stop. Reply with a short summary of the plan and ask its open questions. Don't pick a default
for an open question.

## Phase 4: Apply (after approval)
1. **Pin behaviour first.** Tests that cover current behaviour go in before any code moves, and they
   must pass on the old code. A test for a bug fix must fail on the old code.
2. **One plan step at a time, in order.** Move files before changing them, so each step's diff stays
   readable. Move its bloc/cubit tests under `test/<feature>/bloc/` or `cubit/`. After each step
   the gates are green (the feature's tests at least).
3. If a step reveals something the plan doesn't cover, stop and ask. Record the answer in the
   plan's Decisions.
4. Mark each debt line the refactor closes ✅ (or 🟡 if partial) in `docs/tasks/technical_debt.md`.
   When it clears a Known debt row or changes the project map, update `AGENTS.md` too.

## Phase 5: Hand off
```
## Refactor: <feature> — done | blocked
Gates: analyze <n issues> · format <ok | n files> · tests <passed/failed> (full suite)
Steps: <each plan step: done, or the deviation and why>
Commit drafts:
- ...
AGENTS.md updated: <Known debt rows removed, project map lines changed, or "none">
Usage: <the feature's rows from usage-ledger report>, also pasted into the plan as `## Usage`.
       Omit this line if usage-ledger isn't installed.
Next: stage the changes and I'll run staged-audit on the staged diff
```
