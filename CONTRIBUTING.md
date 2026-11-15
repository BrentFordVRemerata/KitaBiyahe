# Contributing

This is a small solo student project. Focused bug reports and small, explained changes are easier to review than a rewrite. There is no guaranteed review schedule or commercial support commitment.

Include the app version, Windows/Android version, expected and actual results, and the smallest fictional example that reproduces a problem. State whether it happens after restart or import. Follow [SECURITY.md](SECURITY.md) for sensitive reports; do not post real financial backups.

Explain the user problem before changing storage, dependencies, platform configuration or financial rules. Preserve saved-record compatibility. Accounts, cloud synchronization, platform APIs and central association reporting require a separate design decision.

Use the pinned toolchain in [docs/BUILDING.md](docs/BUILDING.md):

```powershell
flutter pub get --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub
```

Add a regression case for a reproduced behavior change. Rebuild and exercise the affected native platform when its behavior changes. State commands actually run and anything untested; analysis/unit tests do not establish native behavior.

Keep money in integer centavos, null distinct from zero, earnings/fuel modes exclusive, original historical inputs preserved, and current records intact after rejected imports. Never commit keys, SDK paths, caches or real rider records.

Identify third-party source and its license. Accepted contributions must be distributable under the project's [MIT license](LICENSE), with existing third-party obligations retained. Disclose relevant AI assistance and verify the resulting change; generated output is not evidence that a test ran.
