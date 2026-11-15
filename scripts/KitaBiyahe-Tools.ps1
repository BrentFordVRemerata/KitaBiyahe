$ErrorActionPreference = 'Stop'

function Assert-KitaProject([string]$Root) {
    foreach ($name in @('pubspec.yaml', 'pubspec.lock', 'lib', 'test')) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root $name))) { throw "Required project item missing: $name" }
    }
}

function Assert-KitaFlutter {
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        throw 'Flutter is missing from PATH. Install Flutter 3.38.3: https://docs.flutter.dev/install'
    }
    $versionText = (& flutter --version --machine | Out-String)
    if ($LASTEXITCODE -ne 0) { throw 'Flutter version check failed.' }
    $version = $versionText | ConvertFrom-Json
    if ($version.frameworkVersion -ne '3.38.3') {
        throw "This release was verified with Flutter 3.38.3 / Dart 3.10.1. Found Flutter $($version.frameworkVersion). Use the pinned SDK for this rebuild; treat an SDK upgrade as a separate change requiring both platform checks."
    }
    Write-Host "Flutter $($version.frameworkVersion), Dart $($version.dartSdkVersion)"
}

function Set-KitaAndroidEnvironment {
    $sdk = $env:ANDROID_HOME
    if (-not $sdk) { $sdk = $env:ANDROID_SDK_ROOT }
    if (-not $sdk) { $sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
    foreach ($name in @('platform-tools\adb.exe', 'platforms\android-36\android.jar', 'build-tools\36.0.0\apksigner.bat')) {
        if (-not (Test-Path -LiteralPath (Join-Path $sdk $name))) {
            throw "Android SDK component missing: $name. Follow README.md Android setup and https://docs.flutter.dev/platform-integration/android/setup"
        }
    }
    $candidates = @()
    if ($env:JAVA_HOME) { $candidates += $env:JAVA_HOME }
    foreach ($base in @((Join-Path $env:LOCALAPPDATA 'KitaBiyaheToolchain'), (Join-Path $env:ProgramFiles 'Microsoft'), (Join-Path $env:ProgramFiles 'Eclipse Adoptium'), (Join-Path $env:ProgramFiles 'Java'))) {
        if (Test-Path -LiteralPath $base) {
            $candidates += @(Get-ChildItem -LiteralPath $base -Directory -Filter '*17*' | Select-Object -ExpandProperty FullName)
        }
    }
    $javaHome = $null
    foreach ($candidate in $candidates | Select-Object -Unique) {
        $java = Join-Path $candidate 'bin\java.exe'
        if (-not (Test-Path -LiteralPath $java)) { continue }
        $start = New-Object System.Diagnostics.ProcessStartInfo
        $start.FileName = $java
        $start.Arguments = '-version'
        $start.UseShellExecute = $false
        $start.CreateNoWindow = $true
        $start.RedirectStandardError = $true
        $start.RedirectStandardOutput = $true
        $process = [System.Diagnostics.Process]::Start($start)
        $description = $process.StandardError.ReadToEnd() + $process.StandardOutput.ReadToEnd()
        $process.WaitForExit()
        if ($process.ExitCode -eq 0 -and $description -match 'version "17\.') { $javaHome = $candidate; break }
    }
    if (-not $javaHome) {
        throw 'JDK 17 was not found. Install Microsoft OpenJDK 17 and set JAVA_HOME to its folder: https://learn.microsoft.com/java/openjdk/download'
    }
    $env:JAVA_HOME = $javaHome
    $env:ANDROID_HOME = $sdk
    $env:Path = "$javaHome\bin;$sdk\platform-tools;$env:Path"
    Write-Host "Using JDK 17 and Android SDK platform 36. Environment selection applies to this script process only."
}

function Invoke-KitaFlutter([string[]]$Arguments, [string]$Label) {
    Write-Host "`n$Label"
    & flutter @Arguments
    $code = $LASTEXITCODE
    if ($code -ne 0) { throw "$Label failed with exit code $code." }
}
