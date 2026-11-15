$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'KitaBiyahe-Tools.ps1')
if ($env:OS -ne 'Windows_NT') { Write-Error 'Windows build scripts require Windows.'; exit 2 }
$ProjectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { Write-Error 'Flutter was not found on PATH.'; exit 2 }
foreach ($required in @('pubspec.yaml', 'pubspec.lock', 'windows')) {
    if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $required))) { Write-Error "Required project item is missing: $required"; exit 2 }
}
Push-Location $ProjectRoot
try {
    Assert-KitaProject $ProjectRoot
    Assert-KitaFlutter
    Invoke-KitaFlutter @('pub', 'get', '--enforce-lockfile') 'Restore exact locked dependencies'
    Invoke-KitaFlutter @('analyze', '--no-pub') 'Static analysis'
    Invoke-KitaFlutter @('test', '--no-pub') 'Automated tests'
    Invoke-KitaFlutter @('build', 'windows', '--release', '--no-pub') 'Windows release build'
    Write-Host "`nWindows release folder: $ProjectRoot\build\windows\x64\runner\Release"
    Write-Host 'Distribute the entire Release folder. This script does not build Android.'
    exit 0
} catch {
    Write-Host "Build or verification failed: $_"
    exit 1
} finally { Pop-Location }
