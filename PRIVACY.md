# Privacy and local records

KitaBiyahe stores entered shift amounts, settings, dates, item references and optional notes on the device. It has no application backend, account, analytics service, GPS tracking or automatic cloud synchronization. It does not connect to rider platforms or verify their amounts.

## Storage and backups

- Windows records use the current account's application-support folder. Extracted app copies share the same application identity and records; a single-instance guard prevents two active app writers in that session.
- Android uses app-specific storage. The app is configured to exclude its files from platform cloud backup and device transfer. OEM behavior has not been universally tested.
- Local JSON and exported backups are not application-encrypted. Device access, operating-system protection and the backup destination matter.
- Export is deliberate. File pickers and optional sharing use the destination selected by the user. Sharing applications/cloud providers have their own retention policies.
- Copy JSON uses the system clipboard, which may retain or synchronize copied content independently of the app.

Keep backups somewhere you control. Export before updating, replacing all records, uninstalling or clearing storage. Uninstalling/clearing storage can remove local records. Only saved shifts persist; unsaved drafts are lost when the app closes. There is no server copy to recover from.

## Demonstrations and support

Use fictional figures in demonstrations and bug reports. Do not attach real backups, rider names, trip references, contact details or financial notes to public issues. A synthetic backup that reproduces the problem is preferable. Deleting an in-app shift does not remove copies already exported or shared.

This release saves up to 100 shifts and accepts supported backups up to 1 MiB. It supports individual local records, not central association access. No confidentiality service, legal compliance certification or guaranteed recovery is promised.
