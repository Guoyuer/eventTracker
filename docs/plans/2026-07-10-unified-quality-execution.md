# Unified Quality Execution Plan

## Status

Active and scope-frozen on 2026-07-10. This is the sole execution contract for
the repository-quality goal. Historical plans record decisions and evidence;
they do not create new work.

## Scope Freeze

### Objective

Finish the existing Flutter activity tracker as a maintainable Windows-first
application with a consistent Activity/Record vocabulary, enforced persistence
invariants, reproducible generated code, and release gates that prevent
unreviewed regressions. The goal is complete only when every item in the fixed
completion criteria below has evidence.

### In Scope

1. Complete and release schema v7: `events` / `event_id` become
   `activities` / `activity_id`; valid v6 data, IDs, foreign keys, and record
   value rules remain protected by migration and direct-SQL tests.
2. Finish the already identified presentation cleanup: rename the remaining
   legacy UI directories to `activities`, replace mutable chart theme globals
   with scoped theme state, and preserve UI behavior with focused tests and an
   English Windows visual inspection.
3. Close the engineering ratchet: zero lint suppressions, checked-in generated
   Drift snapshots, a local check command that matches CI, Linux quality CI,
   and Windows release-build CI.
4. Close documentation and residual-debt accounting: current domain docs,
   ADRs, module flow, README, and this plan agree; every remaining known debt
   is either completed or explicitly recorded as an exclusion below.

### Explicitly Out Of Scope

- New product features, including manual historical start/end-time entry.
- Cloud sync, accounts, telemetry/crash-reporting vendor selection, or external
  service integrations.
- Flutter, Dart, dependency, or platform-toolchain upgrades unless a fixed
  gate demonstrably fails because of the pinned toolchain.
- Android/iOS visual validation; the supported release target for this goal is
  Windows. Existing cross-platform source compatibility is retained where the
  framework already provides it.
- Broad redesigns, new modules, or cleanup discovered after this freeze unless
  the change-control rule is satisfied.

### Fixed Milestones

1. **Schema v7 release boundary:** finish local code-generation, analysis,
   tests, and Windows build; commit and push the self-contained migration.
2. **Presentation boundary:** complete only the directory and chart-theme work
   listed above, with narrow regression tests and the deferred Windows visual
   check; commit and push separately.
3. **Closure boundary:** reconcile documentation, run the full local release
   gate, verify both GitHub CI jobs, classify any residual exclusion, then
   commit and push the closure.

### Completion Criteria

- Schema v7 has fresh and upgrade structural verification plus raw data
  retention and direct-SQL value-invariant coverage.
- `tool/check.ps1 -Codegen -WindowsBuild` succeeds without modifying tracked
  generated files, and its code-generation commands match CI.
- `dart format --output=none --set-exit-if-changed .`,
  `flutter analyze --fatal-infos`, `flutter test`, and `flutter build windows`
  succeed on the final commit.
- GitHub reports a green Linux quality job and green Windows release-build job
  for the final commit.
- There are no lint suppressions, stale active roadmap instructions, or
  unclassified debt statements in the authoritative documentation.
- The English Windows application launches and its primary routes render
  without a blank screen or overflow.

### Change Control

No newly discovered cleanup, feature, dependency upgrade, or architectural idea
is added to this goal automatically. It is recorded separately as a follow-up
only after the fixed milestones are complete, unless it blocks a listed
completion criterion or is required to correct a regression introduced by this
scope. Blocking work must state the criterion it unblocks and be committed as
part of that boundary.

## Current Snapshot (2026-07-10)

The architectural deepening proposed by the historical review is complete:
repositories isolate Drift, Records are the source of truth, state is owned by
Riverpod, the legacy Step schema and Firebase have been removed, and local CI
gates exist. `c745245` additionally completed typed user-facing failures, a
single in-process error boundary, the l10n generator, and localized shell and
failure messages. The verified baseline is Flutter 3.44.5, clean
`flutter analyze --fatal-infos`, 128 tests, a Windows release build, and an
English computer-use inspection of the Activities, Statistics, and Settings
routes.

The rest of the work is intentional debt elimination, not exploratory module
creation. Crash-reporting service selection is excluded because it requires a
privacy and account decision; the error boundary is ready for it.

## Evidence Reviewed

- `AGENTS.md`, `CONTEXT.md`, and ADRs 0001-0002 define the active product and
  non-negotiable invariants.
- `docs/superpowers/plans/2026-07-09-production-readiness.md` is historical
  production-readiness evidence. It does not expand this scope.
- `docs/plans/*.md`, `docs/architecture/module-flow.md`, and the 2026-07-08
  architecture review explain the path taken to the current architecture.
- `.superpowers/sdd/progress.md` is historical review evidence; its later
  completed-task entries resolve its intermediate findings.

## Documentation Classification

| Source | Role now | Required action |
| --- | --- | --- |
| `CONTEXT.md`, ADRs, `AGENTS.md` | Authoritative constraints | Keep current whenever domain or persistence language changes. |
| Production-readiness plan | Historical backlog | Retain completed-task evidence; do not use it to schedule work. |
| Quality and architecture plans | Historical roadmap plus operational runbook | Retain context and commands; this plan owns all remaining scheduling. |
| SDD progress ledger | Historical review evidence | Retain chronology; do not use intermediate findings as active work. |
| Module flow | Current architectural map | Update after record-type and schema terminology changes. |
| 2026-07-08 architecture review | Historical assessment | Mark as superseded: its recommended persistence, state, schema, Firebase, and verification work is complete. |
| `README.md` | User-facing product truth | Verified current: it documents the Activity/Record model, excludes manual historical entry, and gives the supported Windows commands. |

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

**Status: complete.**

**Why next:** l10n foundation exists, but user-facing strings remain scattered;
widget tests must assert localized text rather than hardcoded Chinese.

- All runtime UI literals now live in English and Chinese ARB keys. Analytics
  returns metrics, measurement units, and typed record-detail values; UI owns
  localized labels, dates, and number formatting.
- `AsyncStateView` requires callers to supply empty and retry labels, and the
  AST source guard rejects CJK string literals outside `lib/l10n` while
  ignoring comments.
- English-locale route and settings widget tests protect the translated UI;
  the existing architecture test also prevents domain, application, and
  analytics from importing l10n.

**Evidence:** l10n generation, widget tests, source guard, full suite, and an
English Windows visual inspection of all three primary routes.

### 3. Raise the Engineering Ratchet Before the Database Rename

**Status: implementation complete; completion requires a green latest-master
GitHub CI run.**

**Why before v7:** the next migration is deliberately high-risk and needs
enforced platform and static checks.

- CI and local guidance use the supported build-runner command, verify l10n,
  Drift, and migration artifacts have no diff, and treat analyzer infos as
  failures.
- Linux quality now has a timeout and per-branch concurrency cancellation;
  `windows-latest` independently builds the release executable. Linux analysis
  and tests remain the behavioral contract.
- Tighten the first auto-fixable lint batch, fix the resulting code, and use no
  new ignore comments.

**Evidence required:** local scripts match CI commands, a green Linux CI run,
and a green Windows CI build on the commit.

### 4. Resolve Persistent Terminology and Validation Debt in v7

**Status: implementation and local release gate complete; completion requires
a green latest-master GitHub CI run.**

**Why now:** v6 has schema dumps and migration tooling, the domain will already
use `activityId`, and CI will protect the migration.

- ADR 0003 records the `events` / `event_id` to `activities` / `activity_id`
  decision without changing product behavior.
- Schema v7 explicitly rebuilds v6 tables, retains identifiers and valid local
  history, regenerates schema artifacts, and has SchemaVerifier v6-to-v7 plus
  raw SQLite data-retention coverage. Historical v1-v5 fixtures remain the
  source of their migration coverage.
- SQLite insert/update triggers now enforce the same unit/value contract as
  Dart validation; a boundary matrix covers missing, zero, negative,
  non-finite, maximum, and over-maximum values.

**Evidence required:** fresh v7 schema verifier, v6 upgrade test with retained
data and foreign keys, full migration suite, codegen diff check, Windows build.

### 5. Remove Naming, Lint, and Presentation State Debt

**Status: implementation and local release gate complete; completion requires
a green latest-master GitHub CI run.**

- The activity UI now lives in `lib/activities/`; page, tile, route, and
  provider identifiers use Activity terminology without compatibility facades.
  Architecture tests reject the retired directories and mutable top-level
  declarations in chart/UI modules.
- Delete verified dead UI and analytics data paths as separate, behavior-neutral
  commits. The first cleanup removes the unused selection helper and the
  unrendered heatmap unit/configuration pipeline.
- Mutable chart globals are replaced by `AppChartTheme`, a `ThemeExtension`
  that owns title, heatmap, and time-slot styles. The lookup and the source
  guard have focused regression tests.
- Strengthen imprecise tests called out by the SDD ledger, including specific
  sqflite constraint expectations and deterministic database teardown. Tests
  now register shared-database cleanup during setup; the file-backed WAL test
  closes that harness before opening a second AppDatabase. The aggregate-value
  overflow guard was removed after a test proved the SQLite rowid and per-record
  upper bounds make it unreachable.

**Evidence:** empty lint-suppression list, no source guard violations, full
tests, Windows build, and English Windows visual inspection.

### 6. Completion Audit and Documentation Closure

**Status: local audit and release gate complete; completion requires a green
latest-master GitHub CI run.**

- Update `CONTEXT.md`, module flow, README, ADRs, and active plan at each
  terminology or behavior change. Historical plans remain classified as
  history, not duplicate roadmaps.
- Re-run format, codegen, l10n generation, analysis, tests, Windows build, and
  computer-use flows. Inspect GitHub CI on both operating systems.
- Resolve or explicitly classify every deferred SDD finding; leave no stale
  baseline count, obsolete command, or unowned product claim.

## Commit Policy

One behavioral or migration boundary per commit. Push after every green slice.
Never include unrelated formatting, generated output, or documentation churn in
a persistence migration commit.
