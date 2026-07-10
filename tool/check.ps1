param(
  [switch]$Codegen,
  [switch]$WindowsBuild
)

$ErrorActionPreference = "Stop"

Push-Location (Join-Path $PSScriptRoot "..")
try {
  flutter pub get
  if ($Codegen) {
    & (Join-Path $PSScriptRoot "codegen.ps1")
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
