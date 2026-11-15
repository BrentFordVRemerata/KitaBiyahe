$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'KitaBiyahe-Tools.ps1')
if ($env:OS -ne 'Windows_NT') { Write-Error 'This source script requires Windows.'; exit 2 }
$ProjectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$LockFile = Join-Path $ProjectRoot 'pubspec.lock'
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { Write-Error 'Flutter was not found on PATH.'; exit 2 }
if (-not (Test-Path -LiteralPath $LockFile)) { Write-Error 'pubspec.lock is required so the current resolution can be restored.'; exit 2 }
try { Assert-KitaFlutter; Set-KitaAndroidEnvironment } catch { Write-Host "Both platform toolchains are required before applying updates: $_"; exit 2 }
Write-Host 'This updates dependencies within pubspec constraints, then checks analysis, tests, Windows Release and Android Debug.'
Write-Host 'If any update or gate fails, the original pubspec.lock will be restored.'
$answer = Read-Host 'Type UPDATE to proceed'
if ($answer -cne 'UPDATE') { Write-Host 'Cancelled; no dependency updates applied.'; exit 3 }
$backup = Join-Path $PSScriptRoot ('.pubspec.lock.' + [guid]::NewGuid().ToString('N') + '.rollback')
Copy-Item -LiteralPath $LockFile -Destination $backup
$restored = $false
$completed = $false
Push-Location $ProjectRoot
try {
    Invoke-KitaFlutter @('pub', 'upgrade') 'Apply dependency updates'
    Invoke-KitaFlutter @('analyze', '--no-pub') 'Static analysis'
    Invoke-KitaFlutter @('test', '--no-pub') 'Automated tests'
    Invoke-KitaFlutter @('build', 'windows', '--release', '--no-pub') 'Windows release build'
    Invoke-KitaFlutter @('build', 'apk', '--debug', '--no-pub') 'Android debug build'
    $completed = $true
    Write-Host "`nUpdated lockfile retained. Windows Release and Android Debug builds passed."
    Write-Host 'Review dependency changes and exercise the app before distributing.'
    exit 0
} catch {
    Write-Host "Update or verification failed: $_"
    try {
        Copy-Item -LiteralPath $backup -Destination $LockFile -Force
        Invoke-KitaFlutter @('pub', 'get', '--enforce-lockfile') 'Restore original dependency resolution'
        $restored = $true
        Write-Host 'Previous pubspec.lock and dependency resolution restored.'
    } catch {
        Write-Host "Dependency rollback needs attention. Lockfile backup retained at: $backup"
    }
    exit 1
} finally {
    Pop-Location
    if ($completed -or $restored) { Remove-Item -LiteralPath $backup -Force -ErrorAction SilentlyContinue }
}
