## Agent skills

### Issue tracker

Issues and PRDs for this repo are tracked in GitHub Issues. See `docs/agents/issue-tracker.md`.

### Triage labels

Use the default five-label triage vocabulary. See `docs/agents/triage-labels.md`.

### Domain docs

This is a single-context repo. Read `CONTEXT.md` and relevant ADRs under `docs/adr/` when present. See `docs/agents/domain.md`.

## Repo notes

This is a Flutter activity tracker app. Prefer changes that make the app easier to run, test, and evolve on Windows first, while preserving Android/iOS/web compatibility where practical.

Keep platform runner files that are required to build checked in. Do not commit generated build output, Flutter ephemeral files, IDE workspace state, or local databases.

Before claiming a runtime fix, verify with `flutter build windows`. When touching Dart logic, also run `flutter analyze` and `flutter test` unless a known baseline failure is documented in `docs/plans/repo-quality-roadmap.md`.
