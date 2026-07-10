# Activity Tracker

A Windows-first Flutter app for recording personal activities, optional timed
sessions, optional numeric units, and summaries through lists, charts, and
heatmaps. It also builds and runs on Android; Windows remains the CI-gated
release target.

## Current Product Model

- An **Activity** is either plain (an occurrence is recorded immediately) or
  timed (start, then stop).
- A **Record** is the source of truth for activity state, occurrence count,
  duration, and numeric totals. The app does not persist aggregate caches.
- A **Unit** is an ID-backed label such as `pages`, `km`, or `questions`.
  Activities using a Unit require a positive finite value for every completed
  record. Units in use cannot be deleted.
- A short accidental timed start is cancelled rather than recorded. Manual
  long-press time entry is not part of the current product.

## Windows Setup

Install Flutter 3.44.5, then run:

```powershell
flutter pub get
flutter run -d windows
```

Keep the process running for hot reload. Use `r` in its terminal after Dart or
UI edits. Avoid `flutter clean` during normal iteration because it discards the
Windows incremental build cache.

## Android Setup

Android needs a JDK 17 and the Android SDK (command-line tools, platform 36,
build-tools, plus an emulator or a USB device). Point Flutter at the SDK with
`flutter config --android-sdk <path>` and confirm with `flutter doctor`. Then:

```powershell
flutter build apk --debug
flutter run -d <emulator-or-device>
```

The database uses native sqflite journaling on Android; WAL is a
desktop-only durability setting (see
`lib/persistence/database/database_bootstrap.dart`).

## Verification

```powershell
.\tool\check.ps1
.\tool\check.ps1 -Codegen
.\tool\check.ps1 -WindowsBuild
```

The full quality gate is formatting, current generated code,
`flutter analyze --fatal-infos`, `flutter test`, and `flutter build windows`.
See [the unified quality execution plan](docs/plans/2026-07-10-unified-quality-execution.md)
for the active modernization order.
