# CapsLockX test runner (requires AutoHotkey v2)
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent

$ahk = @(
    "${env:ProgramFiles}\AutoHotkey\v2\AutoHotkey64.exe",
    "${env:ProgramFiles}\AutoHotkey\AutoHotkey64.exe",
    "${env:LocalAppData}\Programs\AutoHotkey\v2\AutoHotkey64.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $ahk) {
    Write-Error "AutoHotkey v2 not found. Install from https://www.autohotkey.com/download/ahk-v2.exe"
}

& $ahk "$PSScriptRoot\run_tests.ahk" --quiet
$code = $LASTEXITCODE
$log = Join-Path $PSScriptRoot "test-results.log"
if (Test-Path $log) { Get-Content $log }
exit $code
