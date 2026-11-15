# Architecture

## Application shape

KitaBiyahe is a Flutter desktop/mobile app. `lib/main.dart` composes the app from QuickCheck, History, Settings, and guide screens. Financial rules and persisted models live in `lib/core/finance.dart`; UI state and serialized mutations live in `lib/core/app_state.dart`; local storage and JSON backup validation live in `lib/core/repository.dart`. `lib/core/android_backup_files.dart` is the Dart boundary for native Android file saving.

The design keeps the estimate engine independent of widgets. Earnings are mutually exclusive: Quick total or itemized entries. Fuel is one of unknown, manually estimated consumed cost, or a distance ÷ efficiency × price calculation. These alternatives are not summed. The financial engine uses integer centavos for money; unknown is null and known zero is 0. An after-cost estimate is available only when required inputs are known. The maintenance allowance is a planned reserve, not recorded spending. Saved records retain their original shift assumptions when settings change.

## State and persistence

`RiderAppState` serializes mutations, persists the proposed state, and updates observable state only after a successful write. `DataRepository` stores a version-1 JSON state in the operating-system application-support directory. Writes use a flushed pending file and validated recovery/previous copies; reads try independently validated candidates and avoid overwriting unreadable data. The repository caps history at 100 shifts. Backups are limited to 1 MiB, and each shift allows up to 40 itemized entries. Merge keeps current settings and avoids duplicate record IDs; Replace uses the imported state after UI confirmation.

This is local JSON persistence. The code does not add account, cloud, database service, GPS, or ride-platform integration. JSON backup contents are not application-encrypted. Android configuration disables platform backup/transfer extraction; that setting is not proof of device-wide encryption or every OEM behavior.

## Native boundaries

The Windows runner creates a named local mutex for one app instance in a Windows session; a second launch focuses the existing window when it can find it. The Flutter plugins provide platform file-picker support for backup import/export.

Android `MainActivity` handles the `ph.kitabiyahe.kitabiyahe/backup` method channel. It validates a simple filename and the 1 MiB bound, opens the system create-document picker, writes the supplied UTF-8 JSON, and reports cancellation or save errors. Sharing remains a separate optional flow in Flutter. The Android app declares minimum API 24 and target/compile API 36.

## Dependency and verification scope

Runtime packages declared in `pubspec.yaml` are Flutter, `path_provider`, `file_selector`, and `share_plus`; test/lint packages are development dependencies. Build versions and observed verification are listed in [BUILDING](BUILDING.md) and [VERIFICATION](VERIFICATION.md). The recorded 63 tests cover financial validation, storage/recovery, backup compatibility, navigation, native backup contracts, layout, and contrast. Those tests do not certify all native devices, accessibility behavior, or security properties of operating systems and third-party providers.
