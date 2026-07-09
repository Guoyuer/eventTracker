param(
  [switch]$Codegen,
  [switch]$WindowsBuild
)

$ErrorActionPreference = "Stop"

Push-Location (Join-Path $PSScriptRoot "..")
try {
  flutter pub get
  if ($Codegen) {
    dart run build_runner build
  }
  flutter analyze
  flutter test

  if ($WindowsBuild) {
    flutter build windows
  }
} finally {
  Pop-Location
}
