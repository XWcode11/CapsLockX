# Build CapsLockX — output ONLY under release\ (never project root)
# Requires: AutoHotkey v2, tools\Ahk2Exe\rel2\Ahk2Exe.exe

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
$Release = Join-Path $Root "release"
$Ahk2Exe = Join-Path $Root "tools\Ahk2Exe\rel2\Ahk2Exe.exe"
$AhkBase = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"

if (-not (Test-Path $Ahk2Exe)) {
    Write-Error "Ahk2Exe not found: $Ahk2Exe"
}
if (-not (Test-Path $AhkBase)) {
    Write-Error "AutoHotkey v2 not found: $AhkBase"
}

New-Item -ItemType Directory -Force -Path $Release | Out-Null

Get-Process -Name "CapsLockX" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

$outExe = Join-Path $Release "CapsLockX.exe"
Write-Host "Compiling -> $outExe"
$argLine = @(
    '/in', "`"$(Join-Path $Root 'CapsLockX.ahk')`"",
    '/out', "`"$outExe`"",
    '/icon', "`"$(Join-Path $Root 'capslock+icon.ico')`"",
    '/base', "`"$AhkBase`"",
    '/cp', 'UTF-8',
    '/silent', 'verbose'
) -join ' '
$p = Start-Process -FilePath $Ahk2Exe -ArgumentList $argLine -Wait -PassThru -NoNewWindow
if ($p.ExitCode -ne 0 -or -not (Test-Path $outExe)) {
    Write-Error "Compile failed (exit $($p.ExitCode))"
}

Copy-Item (Join-Path $Root "CapsLockX-settings.ini") (Join-Path $Release "CapsLockX-settings.ini") -Force
Copy-Item (Join-Path $Root "capslock+icon.ico") (Join-Path $Release "capslock+icon.ico") -Force

Write-Host "Done. Release contents:"
Get-ChildItem $Release | Format-Table Name, Length, LastWriteTime -AutoSize
