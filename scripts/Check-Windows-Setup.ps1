$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'KitaBiyahe-Tools.ps1')
if ($env:OS -ne 'Windows_NT') { Write-Error 'These source scripts require Windows.'; exit 2 }
$ProjectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
Write-Host "Project folder: $ProjectRoot"
foreach ($required in @('pubspec.yaml', 'pubspec.lock', 'windows')) {
    if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $required))) {
        Write-Error "Required project item is missing: $required"
        exit 2
    }
}
$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter) { Write-Error 'Flutter was not found on PATH. Install Flutter using the official instructions, then open a new terminal.'; exit 2 }
Push-Location $ProjectRoot
try {
    Assert-KitaFlutter
    Write-Host "`n--- Flutter version ---"
    & flutter --version
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Host "`n--- Flutter doctor (read-only diagnostic) ---"
    & flutter doctor -v
    if ($LASTEXITCODE -ne 0) { Write-Host "Flutter doctor returned $LASTEXITCODE. Review its diagnostics; no software was installed." }
    Write-Host "`nPrerequisite commands completed. Review Flutter doctor output for Windows desktop toolchain requirements before building."
} finally { Pop-Location }
exit 0
