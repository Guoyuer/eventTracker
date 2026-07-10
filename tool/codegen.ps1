# Regenerates l10n, Drift code, and Drift schema snapshots.
# Shared by tool/check.ps1 (-Codegen, which then verifies no diff) and
# tool/schema.ps1 (which then prints the remaining manual migration steps).
# The current build_runner no longer accepts --delete-conflicting-outputs.

$ErrorActionPreference = "Stop"

Push-Location (Join-Path $PSScriptRoot "..")
try {
  flutter gen-l10n
  dart run build_runner build
  dart run drift_dev schema dump lib/persistence/database/app_database.dart drift_schemas/
  dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
}
finally {
  Pop-Location
}
