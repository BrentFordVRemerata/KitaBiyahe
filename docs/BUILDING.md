# Build and reproduce

This guide is for rebuilding the KitaBiyahe 0.4.3+4 source candidate. Using the packaged Windows app or Android APK does not require developer tools. The ZIP is not evidence that another machine has already built or run it.

## Source path

Extract or copy the entire source folder to a **short local path**, for example `C:\KitaBiyahe Source`, before building. Spaces are supported. Avoid deeply nested download or evidence folders: one verification run reached a 260-character generated FileTracker path and failed in the Windows compiler, although source tests passed. Moving the whole source to a short path is part of rebuild setup; it does not change saved application records.

Keep `lib`, `test`, `android`, `windows`, `assets`, `pubspec.lock`, and `scripts` together.

## Verified toolchain

The recorded build used Flutter **3.38.3 stable** with Dart **3.10.1**. Scripts require that Flutter version and restore the checked-in `pubspec.lock`.

For Windows builds, install Visual Studio with **Desktop development with C++** and a Windows SDK. The baseline host used Visual Studio Community 2026 18.10.3, Windows SDK 10.0.26100.0, and CMake 4.3.1-msvc1. See [Flutter installation](https://docs.flutter.dev/install) and [Windows setup](https://docs.flutter.dev/platform-integration/windows/setup).

For Android builds, install **JDK 17**, Android SDK platform-tools, platforms 35 and 36, and build-tools 35.0.0 and 36.0.0. The project pins AGP 8.12.1, Gradle 8.14 with its published distribution checksum, Kotlin 2.2.20, NDK 28.2.13676358, and CMake 3.22.1. SDK components not already cached may download on first build. Accept applicable SDK licenses. See [Android setup](https://docs.flutter.dev/platform-integration/android/setup) and [Microsoft OpenJDK](https://learn.microsoft.com/java/openjdk/download).

With Android command-line tools installed, provision SDK components:

```powershell
sdkmanager "platform-tools" "platforms;android-35" "platforms;android-36" "build-tools;35.0.0" "build-tools;36.0.0" "ndk;28.2.13676358" "cmake;3.22.1"
sdkmanager --licenses
```

Set `JAVA_HOME` to JDK 17 and `ANDROID_HOME` to the SDK folder. Scripts also look for standard Microsoft/Adoptium JDK 17 folders and the default local Android SDK. Environment changes made by a build script apply only to that process. Android Studio is optional when the command-line SDK is installed.

## Double-click scripts

- **Check Windows Setup.bat** and **Check Android Setup.bat** inspect prerequisites and provide diagnostics.
- **Restore Dependencies.bat** restores locked dependencies.
- **Run Checks.bat** restores, analyzes, and runs automated tests.
- **Build and Verify Windows.bat** checks the source and builds the complete Windows Release folder.
- **Build and Verify Android.bat** checks the source and builds a debug APK without release secrets.
- **Build Signed Android Release.bat** builds a release APK using a separately supplied private signing key.

Scripts stop with a nonzero exit code on failure. Batch wrappers pause for double-click use; pass `--no-pause` for automation. Their PowerShell execution-policy bypass applies only to that child process. PowerShell scripts invoke Flutter and check its exit code at each step. They do not install software or change machine-wide settings.

Equivalent core checks:

```powershell
flutter pub get --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub
flutter build windows --release --no-pub
flutter build apk --debug --no-pub
```

Windows output is `build/windows/x64/runner/Release`. Distribute that entire folder, including DLLs and data. Android output is `build/app/outputs/flutter-apk`. Compilation alone does not verify installation, backup behavior, restart, or accessibility.

## Android signing and updates

Copy `android/key.properties.example` to the ignored `android/key.properties`. Fill in `storeFile`, `storePassword`, `keyAlias`, and `keyPassword` for a private keystore kept outside this source folder. Use an absolute path with forward slashes for `storeFile` on Windows. Keep the key, passwords, and a secure backup private. The original release key is retained separately by the project owner and is intentionally absent here.

A release build fails clearly when signing is missing. Debug builds do not require release secrets. A newly generated key cannot update an installed copy signed with the original key. Preserve the original application ID and signing key for updates, and export records before changing or replacing an installation. Follow [Flutter signing guidance](https://docs.flutter.dev/deployment/android).

## Deliberate dependency updates

**Check Dependency Updates.bat** only reports available versions. **Apply Dependency Updates.bat** requires both developer toolchains and an explicit `UPDATE` response. It updates within declared dependency constraints, then runs analysis, tests, a Windows Release build, and an Android Debug build. On failure it restores the previous lockfile and requests the original dependency resolution; if restoration fails it retains the rollback copy and reports that repair is needed. It does not upgrade Flutter, Java, or Android SDK tools. Review the diff and exercise both apps before sharing a new release.

## Source map

- `lib/core`: centavo financial model, local JSON persistence, backup validation, and Android file-save boundary.
- `lib/ui`: QuickCheck, History, Settings, and walkthrough.
- `test`: unit/widget regressions and fictional fixtures.
- `android` and `windows`: platform runners and native configuration.
- `assets/brand`: generated transparent mark and provenance summary.
- `scripts`: prerequisite checks, dependency restoration, verification, builds, and optional icon export.

The native backup schema is version 1. Unknown amounts are null; deliberate zero is zero. Defaults do not rewrite historical financial assumptions. Android exports use the system file picker; sharing is a separate optional action. Data is local JSON. Android platform backup/transfer is disabled by configuration; this is not device-level encryption.

App builds use checked-in icon exports. Regenerating icons is optional: install `scripts/requirements-brand.txt`, then run `python scripts/EXPORT_BRAND_ASSETS.py`. Normal app rebuilding requires no Python or image-generation service.
