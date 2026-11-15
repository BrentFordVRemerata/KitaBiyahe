$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { Write-Error 'This source script requires Windows.'; exit 2 }
$ProjectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { Write-Error 'Flutter was not found on PATH.'; exit 2 }
Push-Location $ProjectRoot
try {
    Write-Host 'Read-only package update report; project files are not intentionally changed.'
    & flutter pub outdated
    $code = $LASTEXITCODE
    if ($code -ne 0) { Write-Error "flutter pub outdated returned $code."; exit $code }
} finally { Pop-Location }
exit 0
