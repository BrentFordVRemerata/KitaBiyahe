# Verification record

**Application 0.4.3+4 · recorded November 15, 2026.** This file distinguishes executed checks, owner-reported phone use, intended compatibility and unverified coverage. Documentation preparation did not change the application code or rebuild the binaries.

## Reproduced toolchain

Flutter 3.38.3 stable / Dart 3.10.1; one Windows 11 Pro x64 host; Visual Studio Community 2026 18.10.3; Windows SDK 10.0.26100.0; CMake 4.3.1-msvc1. Android builds used JDK 17.0.21, AGP 8.12.1, Gradle 8.14, Kotlin 2.2.20 and compile/target SDK 36. SDK and Java selection was process-local.

The APK declares minimum API 24 (Android 7) and includes ARM32, ARM64 and x86_64. Windows x64 and Android API 24+ are intended targets. Observations cover Windows 11, API 24/API 37 emulators and the limited Android 16 owner report below; they do not establish every intermediate version or OEM configuration.

## Build and automated checks

| Check | Recorded result |
|---|---|
| `flutter pub get --enforce-lockfile` | Exit 0; lockfile unchanged |
| `flutter analyze --no-pub` | Exit 0; no issues |
| `flutter test --no-pub --reporter expanded` | Exit 0; 63 tests passed |
| Clean extracted-source Windows script | Locked restore, analysis, 63 tests and Windows Release build passed |
| Clean extracted-source Android script | Same checks and Android Debug build passed without a release key |
| Signed universal release APK | Release build, signer/identity/version inspection and 16 KB alignment check passed |
| Release without signing configuration | Deliberately failed with a precise missing-signing message; no debug-key fallback |
| Dependency-update failure controls | Disposable tool stub injected failures at each verification gate; the script stopped and restored the previous lockfile. This was not a real dependency upgrade. |

Tests cover integer-centavo bounds, unknown/zero distinctions, IDs, fractional values, historical assumptions, recovery and rejected-import retention, legacy backups, draft navigation, native file-save contracts, narrow/enlarged-text widgets and theme contrast. The corrected delayed-save regression preserves the active Settings screen while a prior shift save finishes.

## Native observations

| Environment | Observed scope |
|---|---|
| Windows 11 | Complete ZIP launched through its batch file from fresh extraction paths with spaces. Keyboard Save, restart and second-copy history retention were observed. One completed PHP 857.50 record and incomplete PHP 500/PHP 200 records remained. Concurrent launch attempts settled to one writer. |
| Windows backup transfer | Imported Android JSON, exported a byte-identical 1,704-byte backup, repeated Merge without duplicate IDs, and rejected a fractional-centavo replacement without changing saved primary bytes. These backup checks preceded the navigation-only correction; financial/storage code was unchanged. |
| Android 7/API 24 emulator | Direct system-file save, cancellation, restore/re-export and historical unknown preservation were observed. A controlled same-key internal code 3-to-final-code 4 update retained a known complete and incomplete shift; post-update export exactly matched its known input. A pre-update export from code 3 was unavailable and is not claimed. |
| Android 17/API 37 emulator | Exact corrected APK launched offline; Replace, repeated Merge, exact export, invalid-replacement rejection, restart and an added incomplete shift were checked. Bounded Back, text scale 2 and landscape observations were recorded. |
| Infinix GT30Pro/Android 16 | Owner reported normal installation, save, close/reopen, JSON export and importing that export with Merge without duplicates. This was not independently observed; other phone scenarios are not claimed. |

TalkBack field focus, numeric entry and Save were observed on API 37. The emulator had no audio, so speech was not assessed. Windows numeric field names and keyboard access were observed. Full Narrator/audible TalkBack acceptance and every launcher mask/themed icon remain unverified.

## Artifact and source identity

The recorded application correction is c91cb22. Source and runtime inputs were compared with the successful extracted-source rebuild during handoff. The original Windows runtime contained 25 files; complete Windows/Android archives passed safe-path, exclusion and checksum checks. SHA-256 for the exact corrected release APK:

```text
bacd42cf1d702b1c07db4fa55cdca70c6ecf7c214d659ecf04b100a7be49f74d
```

Future builds or documentation snapshots must identify their own source and binaries rather than inheriting this result. Downloadable builds, when published, should include their own checksums.

## Independent review scope

Authenticated CodeRabbit 0.9.5 raised a minor asynchronous-save navigation issue that was reproduced and corrected. An explicit fresh post-fix review raised 0 issues across eight selected Dart files; a reused response was not counted as fresh. This did not cover every native/package file.

A completed Codex Security source scan covered an earlier clean 100-file snapshot and reported no reportable source-backed findings. It predates the navigation correction and did not audit dependency internals, OS ACLs, OEM backup transport or key custody. It is not certification of the current binary or every environment. Fresh-context document/source and package reviews also checked the handoff; their scope was separate from native tests.

## Known limits

- One Windows test machine; bounded emulator observations and an owner-reported phone check.
- No formal rider-comprehension, adoption, income-improvement or business-feasibility result.
- Local JSON/backups are not application-encrypted. Clipboard, sharing providers and OEM transport behavior have separate boundaries; see [PRIVACY.md](../PRIVACY.md).
- A deeply nested Windows source build failed at a 260-character generated FileTracker path; the same source built from a short path. An earlier unexplained Android build failure passed on immediate verbose retry without code/environment changes. Both observations remain recorded rather than assigned an unproved cause.
- Some unused Android SDK licenses and a command-line-tools deprecation were diagnostic warnings; no all-green doctor claim is made.
- The current 100-shift/40-entry/1 MiB limits are intentional bounds, not performance measurements. Future retention changes need migration and recovery verification.

See [BUILDING.md](BUILDING.md) for reproduction and [SECURITY.md](../SECURITY.md) for reporting. A passing unit suite, clean review or successful launch does not extend the measured scope above.
