$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'KitaBiyahe-Tools.ps1')
$ProjectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
Push-Location $ProjectRoot
try {
    Assert-KitaProject $ProjectRoot
    Assert-KitaFlutter
    Invoke-KitaFlutter @('pub', 'get', '--enforce-lockfile') 'Restore locked dependencies'
    exit 0
} catch { Write-Host "Dependency restore failed: $_"; exit 1 }
finally { Pop-Location }
