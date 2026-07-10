param(
  [switch]$Codegen,
  [switch]$WindowsBuild
)

$ErrorActionPreference = "Stop"

Push-Location (Join-Path $PSScriptRoot "..")
try {
  flutter pub get
  if ($Codegen) {
    flutter gen-l10n
    dart run build_runner build
    dart run drift_dev schema dump lib/persistence/database/app_database.dart drift_schemas/
    dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
    git diff --exit-code -- lib/l10n/ '*.g.dart' drift_schemas/ test/generated_migrations/
  }
  flutter analyze --fatal-infos
  flutter test

  if ($WindowsBuild) {
    flutter build windows
  }
} finally {
  Pop-Location
}
