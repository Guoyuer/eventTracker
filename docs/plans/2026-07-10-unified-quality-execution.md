# Unified Quality Execution Plan

## Status

Active. This document reconciles the repo's current documentation and defines
the execution order after the v6 migration-safety work.

## Current Snapshot (2026-07-10)

The architectural deepening proposed by the historical review is complete:
repositories isolate Drift, Records are the source of truth, state is owned by
Riverpod, the legacy Step schema and Firebase have been removed, and local CI
gates exist. `c745245` additionally completed typed user-facing failures, a
single in-process error boundary, the l10n generator, and localized shell and
failure messages. The verified baseline is Flutter 3.44.5, clean
`flutter analyze --fatal-infos`, 122 tests, a Windows release build, and a
computer-use startup inspection.

The rest of the work is intentional debt elimination, not exploratory module
creation. Crash-reporting service selection is excluded because it requires a
privacy and account decision; the error boundary is ready for it.

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

### 1. Make the Domain Record Contract Total

**Status: completed in the current worktree.**

**Why first:** it removes the final nullable runtime-shaped model before the
schema and naming migration expand the blast radius.

- Replace `ActivityRecord` with sealed `PlainRecord`, `CompletedTimedRecord`,
  and `ActiveTimedRecord` types. A completed record has an end time; active
  records have no value; domain consumers never call throwing nullable getters.
- Rename the domain identity to `activityId`, map persistence rows once at the
  adapter boundary, and use exhaustive switches in analytics and chart models.
- Delete unreachable aggregate-overflow code only after boundary tests prove
  the individual record bound makes it impossible to reach.

**Evidence required:** domain, analytics, repository, and detail-chart tests;
strict analysis; full test suite; Windows release build.

### 2. Finish Localization and Give UI Its Regression Owner

**Why next:** l10n foundation exists, but user-facing strings remain scattered;
widget tests must assert localized text rather than hardcoded Chinese.

- Move every user-visible literal from UI/common/chart adapters into English and
  Chinese ARB keys. Do not localize domain or analytics; inject presentation
  values through UI adapters as the failure-message contract already does.
- Make `AsyncStateView` receive localized empty and retry text rather than own
  Chinese defaults.
- Add a no-hardcoded-user-string guard that ignores comments and l10n sources.
- Add widget coverage for the activity list, recording value dialog, editor
  validation, Unit-in-use delete rejection, Statistics date range, and detail
  record presentation in both supported locales where the behavior differs.

**Evidence required:** l10n generation, widget tests, source guard, full suite,
and an English Windows visual inspection.

### 3. Raise the Engineering Ratchet Before the Database Rename

**Why before v7:** the next migration is deliberately high-risk and needs
enforced platform and static checks.

- Replace the deprecated/no-op build-runner flag consistently in CI and local
  guidance; make CI also verify l10n generation is current.
- Add job timeout and concurrency cancellation, then a `windows-latest` build
  job. Linux analysis and tests are retained; Windows build is an additional
  runtime contract, not a replacement.
- Tighten the first auto-fixable lint batch, fix the resulting code, and use no
  new ignore comments.

**Evidence required:** local scripts match CI commands, a green Linux CI run,
and a green Windows CI build on the commit.

### 4. Resolve Persistent Terminology and Validation Debt in v7

**Why now:** v6 has schema dumps and migration tooling, the domain will already
use `activityId`, and CI will protect the migration.

- Write ADR 0003 to rename the `events` table and event foreign-key names to
  `activities` and `activity_id`; this is terminology alignment, not a product
  behavior change.
- Implement schema v7 as an explicit v6-to-v7 migration, regenerate Drift and
  v7 schema artifacts, and add `SchemaVerifier` coverage for v6 -> v7. Keep
  historical v1-v5 behavior covered by the existing data migration tests; do
  not invent unavailable old schema snapshots.
- Add a differential boundary matrix proving Dart validation and direct SQLite
  inserts agree for missing, zero, negative, non-finite, maximum, and
  over-maximum values.

**Evidence required:** fresh v7 schema verifier, v6 upgrade test with retained
data and foreign keys, full migration suite, codegen diff check, Windows build.

### 5. Remove Naming, Lint, and Presentation State Debt

- Complete the remaining correctness lint batch, then rename files and finally
  directories to current snake_case/Activity terminology in reviewable commits.
  Update architecture tests in the same commit; do not preserve compatibility
  import facades.
- Replace mutable chart globals with a `ThemeExtension`, add a narrow guard for
  mutable top-level declarations, and test the chart theme lookup.
- Strengthen imprecise tests called out by the SDD ledger, including specific
  SQLite constraint expectations and deterministic database teardown.

**Evidence required:** empty lint-suppression list, no source guard violations,
full tests, Windows build, and visual chart inspection.

### 6. Completion Audit and Documentation Closure

- Update `CONTEXT.md`, module flow, README, ADR index, and active plan at each
  terminology or behavior change. Historical plans remain labeled history, not
  duplicate roadmaps.
- Re-run format, codegen, l10n generation, analysis, tests, Windows build, and
  computer-use flows. Inspect GitHub CI on both operating systems.
- Resolve or explicitly classify every deferred SDD finding; leave no stale
  baseline count, obsolete command, or unowned product claim.

## Commit Policy

One behavioral or migration boundary per commit. Push after every green slice.
Never include unrelated formatting, generated output, or documentation churn in
a persistence migration commit.
