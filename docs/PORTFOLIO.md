# Portfolio case study: KitaBiyahe

**Role:** solo student project by Brent Ford V. Remerata  
**Format:** TECHNO101 academic MVP · Flutter/Dart · Windows x64 and Android  
**Candidate:** 0.4.3+4

## Problem and intended user

Motorcycle-based riders may need to estimate what remains from work after fuel and other declared shift costs. A single payout number can blur fees, tips, fuel consumed, and planned maintenance. KitaBiyahe gives riders a manual, local-first way to record those assumptions and see an estimate while keeping incomplete inputs visible.

Informal rider conversations motivated the project. No formal rider study, adoption, comprehension, profitability, or business-feasibility result is claimed.

## Scope delivered

The candidate includes two exclusive earnings modes (quick total and itemized), one selected fuel method (manual consumed amount or distance-based), other declared costs, an optional planned maintenance allowance, saved shift history, per-shift assumption retention, local settings, and JSON backup Merge/Replace flows. It has no platform connection, GPS, account, or cloud sync. More detail is in the [user guide](USER_GUIDE.md) and [architecture](ARCHITECTURE.md).

## Design and engineering choices

- **Represent uncertainty:** blank values remain unknown, separate from known zero. A shift can be saved incomplete without presenting unknown costs as zero.
- **Keep the model understandable:** integer-centavo money and explicit earnings/fuel modes prevent accidental double counting. Planned reserve is labeled separately from actual spent cost.
- **Keep records local and portable:** versioned JSON, validation, recovery copies, and user-controlled backup give riders a manual transfer path without a service account.
- **Preserve historical context:** each shift stores its assumptions, so changing settings affects future entries rather than silently changing earlier estimates.
- **Treat native behavior as a boundary:** Windows uses a single-instance mutex; Android uses the system file picker for JSON save. These platform interactions receive tests and bounded native checks.

## Regression addressed

A background QuickCheck save could previously alter the active tab or discard text being entered in Settings. The corrected candidate keeps save completion from changing navigation or replacing the active Settings input; deliberate tab navigation still requires saving Settings edits. The recorded verification describes the fix and its native checks. This is a specific resolved regression, not a claim that every navigation or lifecycle edge case is covered.

## Evidence and limits

The candidate verification records analyzer success, 63 passing tests, Windows Release and Android Debug builds, and bounded checks on one Windows 11 x64 host and Android API 24/API 37 emulators. It also records owner-reported save/reopen/export/Merge steps on an Infinix GT 30 Pro running Android 16. The phone result is not presented as independently reproduced. See [VERIFICATION](VERIFICATION.md) for details.

The checks do not establish universal compatibility, full accessibility acceptance, formal user validation, adoption, business viability, independent security certification, or operation on every Windows/Android device. The 100-shift, 40-item-per-shift, and 1 MiB backup bounds are implementation constraints. No runtime benchmark is claimed.

## Tradeoffs and next questions

Manual entry keeps the first MVP bounded and avoids collecting account credentials or background location, but it depends on riders entering accurate values. Local-only storage reduces service dependencies but makes manual backup important and makes the lack of application-level encryption relevant. The history cap is a simple bound; review after real use should decide whether a safe retention and export model is needed before expanding it.

The [roadmap](../ROADMAP.md) lists proposals for review. They are not implemented features or commitments.
