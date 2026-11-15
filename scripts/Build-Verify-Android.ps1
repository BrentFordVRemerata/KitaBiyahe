param([ValidateSet('Debug', 'Release')][string]$Configuration = 'Debug')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'KitaBiyahe-Tools.ps1')
$ProjectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
Push-Location $ProjectRoot
try {
    Assert-KitaProject $ProjectRoot
    Assert-KitaFlutter
    Set-KitaAndroidEnvironment
    if (-not (Test-Path -LiteralPath 'android')) { throw 'Android platform source is missing.' }
    if ($Configuration -eq 'Release' -and -not (Test-Path -LiteralPath 'android/key.properties')) {
        throw 'Signed release requires private android/key.properties. See README.md. Debug builds work without release secrets.'
    }
    Invoke-KitaFlutter @('pub', 'get', '--enforce-lockfile') 'Restore locked dependencies'
    Invoke-KitaFlutter @('analyze', '--no-pub') 'Static analysis'
    Invoke-KitaFlutter @('test', '--no-pub') 'Automated tests'
    $mode = '--' + $Configuration.ToLowerInvariant()
    Invoke-KitaFlutter @('build', 'apk', $mode, '--no-pub') "Android $Configuration build"
    Write-Host "`nAPK output: build\app\outputs\flutter-apk. Install and test the exact APK before distributing."
    exit 0
} catch { Write-Host "Build or verification failed: $_"; exit 1 }
finally { Pop-Location }
