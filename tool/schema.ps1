# Regenerates Drift code and schema snapshots after a schema change.
#
# Run this AFTER editing lib/persistence/database/tables.dart and bumping
# `schemaVersion` in app_database.dart. It performs the mechanical codegen so
# you only hand-write the migration and its data test.

$ErrorActionPreference = "Stop"

Write-Host "Regenerating l10n, Drift code, and schema snapshots..." -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "codegen.ps1")

Write-Host ""
Write-Host "Schema artifacts regenerated." -ForegroundColor Green
Write-Host "Remaining manual steps for a new version:"
Write-Host "  1. Add the _migrateToVersionN step in app_database.dart onUpgrade."
Write-Host "  2. Add a data-migration test (retained data + rejected bad data)"
Write-Host "     in test/database_migration_test.dart."
Write-Host "  3. Verify: .\tool\check.ps1 -Codegen -WindowsBuild"
Write-Host ""
Write-Host "The schema verifier test auto-covers every generated snapshot" -ForegroundColor DarkGray
Write-Host "version; no new case is needed there." -ForegroundColor DarkGray
