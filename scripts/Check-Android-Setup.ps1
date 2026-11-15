$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'KitaBiyahe-Tools.ps1')
$ProjectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
try {
    Assert-KitaProject $ProjectRoot
    Assert-KitaFlutter
    Set-KitaAndroidEnvironment
    & flutter doctor -v
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & "$env:ANDROID_HOME\platform-tools\adb.exe" devices -l
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Host 'Checks completed. Read license/device warnings above; no software was installed. A connected phone is optional for compilation.'
    exit 0
} catch { Write-Host "Android setup needs attention: $_"; exit 2 }
