param(
  [switch]$WindowsBuild
)

$ErrorActionPreference = "Stop"

Push-Location (Join-Path $PSScriptRoot "..")
try {
  flutter pub get
  flutter analyze
  flutter test

  if ($WindowsBuild) {
    flutter build windows
  }
} finally {
  Pop-Location
}
