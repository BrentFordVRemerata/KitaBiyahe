# Security policy

## Version and reporting

The maintained assessment target is the 0.4.3+4 academic MVP. There is no paid support agreement, response-time promise or independently certified release.

Use GitHub's **Report a vulnerability** option if it is enabled. If a private option is unavailable, open an issue asking the maintainer to arrange a private channel without publishing exploit details or user data. The README links the maintainer's GitHub profile. Never post keys, passwords or real backups publicly. Reporting availability depends on the repository's settings; this document does not assert a private channel is already enabled.

For ordinary bugs, use the issue template with fictional inputs and the exact platform/version. See [CONTRIBUTING.md](CONTRIBUTING.md).

## System and trust boundaries

KitaBiyahe is a local Windows/Android app. Its assets include saved shifts, settings, user-directed exports and release-signing identity. There is no backend, account service, platform API or network synchronization. Imported JSON and pasted backups are untrusted input. File pickers, sharing providers, the clipboard, OS storage and device access cross separate boundaries.

## Properties to preserve

- Validate supported schemas, size, record count, identities and financial values before changing state.
- Reject non-finite/out-of-range amounts and unsupported fractional centavos. Keep null distinct from known zero.
- Rejected imports and failed saves must not silently replace valid records. Preserve meaningful errors and recovery paths.
- Serialize writes and preserve historical assumptions during unrelated edits.
- Keep signing keys, local properties and credentials out of source, logs, screenshots and packages. Release builds must not silently fall back to a debug key.
- Avoid logging financial contents or leaking them through diagnostics/reporting.

## Review context and known limits

Data loss, validation bypass, unsafe file operations, unintended export, sensitive logging and signing/configuration exposure are meaningful report categories. Evaluate impact in the actual local-app boundary; documentation is not proof that a control works.

Local JSON/exports are not encrypted by the app. Device/OS access controls and user-selected destinations matter. Clipboard, OEM backup/transfer behavior and sharing-provider retention are not universally verified. These disclosures do not suppress reports of concrete unintended disclosure or data loss.

[Verification notes](docs/VERIFICATION.md) identify the recorded automated/native checks and prior review scopes. They do not establish complete dependency, OS, device or binary security coverage. Keep each review's source identity attached to its result.
