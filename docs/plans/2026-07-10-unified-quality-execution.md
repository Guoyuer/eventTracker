# Unified Quality Execution Plan

## Status

Active. This document reconciles the repo's current documentation and defines
the execution order after the v6 migration-safety work.

## Evidence Reviewed

- `AGENTS.md`, `CONTEXT.md`, and ADRs 0001-0002 define the active product and
  non-negotiable invariants.
- `docs/superpowers/plans/2026-07-09-production-readiness.md` is the active
  production backlog. Tasks 1-3 are complete.
- `docs/plans/*.md`, `docs/architecture/module-flow.md`, and the 2026-07-08
  architecture review explain the path taken to the current architecture.
- `.superpowers/sdd/progress.md` records CI green for `69b45dd` and deferred
  review findings.

## Documentation Classification

| Source | Role now | Required action |
| --- | --- | --- |
| `CONTEXT.md`, ADRs, `AGENTS.md` | Authoritative constraints | Keep current whenever domain or persistence language changes. |
| Production-readiness plan | Active backlog | Update its baseline and cross-task dependencies as slices land. |
| Quality and architecture plans | Historical roadmap plus operational runbook | Remove stale next-slice text; retain Windows iteration and definition-of-done guidance. |
| Module flow | Current architectural map | Update after record-type and schema terminology changes. |
| 2026-07-08 architecture review | Historical assessment | Mark as superseded: its recommended persistence, state, schema, Firebase, and verification work is complete. |
| `README.md` | User-facing product truth | Rewrite before feature work: it still documents removed manual long-press entry and obsolete Event terminology. |

## Non-Negotiable Invariants

1. Records remain the sole persisted source for Activity state and aggregates.
2. A Unit is an ID-backed reference; active references prevent deletion.
3. Domain, application, and analytics do not import Flutter, Riverpod, or
   persistence. Architecture dependency tests remain strict.
4. Schema changes require generated Drift output, a versioned schema dump,
   structural migration verification, data migration tests, and a Windows build.
5. Every completed slice passes formatting, code generation where applicable,
   `flutter analyze --fatal-infos`, `flutter test`, and `flutter build windows`.

## Execution Order

### 0. Establish One Current Truth

- Repair the current regression test that still expects `StateError` after the
  already-introduced `ActivityBusy` failure.
- Update `README.md`, module-flow schema references, and stale historical plan
  headings. Do not delete history; label it accurately.
- Align CI, `tool/check.ps1`, and plan commands on the current build_runner
  invocation. Add CI timeout and cancellation of superseded runs.

### 1. Complete User-Visible Failure Handling and Localization Together

Original production-readiness Tasks 4 and 6 must be one coherent slice.

- Keep typed domain failures and let unexpected errors propagate to the single
  application error boundary.
- Add `ActivityFailureMessages`, a pure-Dart application value object injected
  by the localized UI. Controllers must not hardcode temporary Chinese text.
- Add global error-boundary tests that prove a zone error is reported once and
  restore global Flutter handlers after test execution.
- Establish English and Chinese ARB catalogs, localize the shell and the
  failure messages, then remove every remaining user-facing hardcoded string.

### 2. Make Record Shapes Unrepresentable

Complete production-readiness Task 5 before broad cosmetic cleanup.

- Replace nullable `ActivityRecord` fields with sealed Plain, completed-timed,
  and active-timed record types.
- Rename the domain field `eventId` to `activityId`.
- Migrate every repository, analytics, UI, fake, and test consumer through
  exhaustive switches.

### 3. Add UI Regression Ownership

- After l10n is stable, add widget coverage for the activity list, editor,
  unit deletion restriction, statistics range, and activity detail flows.
- Add source guards only for durable rules: no hardcoded user strings, no
  mutable top-level state, and architecture import boundaries.

### 4. Finish Static and Presentation Hygiene

- Enable all remaining lint rules in reviewable batches; use no new ignores.
- Rename source files to snake_case and then migrate directory names only with
  architecture-test updates in the same slice.
- Move chart styling from mutable globals into a `ThemeExtension`.

### 5. Resolve Persistent Terminology Debt

- Create an ADR for `Events -> Activities` terminology alignment.
- Migrate schema v6 to v7, table names, foreign keys, generated outputs,
  migration snapshots, test fixtures, and documentation together.
- Add a differential validation test that proves Dart write validation and SQL
  constraints accept and reject the same boundary-value matrix.

### 6. Release Readiness Audit

- Add a Windows GitHub Actions build job; the app is Windows-first and Linux
  analysis/test alone cannot prove the runner remains buildable.
- Run the complete local gate, inspect the Windows app visually through
  computer-use, read CI results, and remove every resolved deferred note from
  the SDD ledger.

## Commit Policy

One behavioral or migration boundary per commit. Push after every green slice.
Never include unrelated formatting, generated output, or documentation churn in
a persistence migration commit.
