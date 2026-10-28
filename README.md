# Minute Keeper

Offline meeting decision ledger: capture agenda decisions, owners, due dates, and follow-ups with shareable minutes on phone, tablet, and Windows without accounts.

## Why / who

Small volunteer groups, clubs, and households lose decisions in chat threads. Minute Keeper is a private, lightweight alternative to general-purpose note-taking, transcription, or enterprise meeting suites.

## Intended workflow

1. Create a meeting with title, date, and agenda items.
2. During discussion, record each decision and action with an owner and optional due date; mark unresolved items for next time.
3. Review minutes, copy/share a redacted summary deliberately, and revisit outstanding actions before the next meeting.
4. Export local JSON backup and readable Markdown; import a previously exported backup.

## MVP / status

Documentation-only scaffold; app and tests do not exist yet. Planned MVP: local meetings and agenda; decisions/actions; outstanding-action view; opt-in Markdown share; validated JSON backup/restore; adaptive phone/tablet/Windows layout; platform-authentic controls. No cloud accounts, recording, transcription, automatic attendee tracking, or background sync. Data stays on device; sharing/export leaves it only on user action. No permissions required for core use; file picker/share APIs only on explicit request. Treat minutes as private; sharing UI must preview content before export.

## Platforms / build

Flutter stable/Dart single codebase. Windows primary CI/release, Android and iOS phones/tablets first-class; enable `windows/`, `android/`, `ios/` in first implementation issue. Native per-platform adaptive widgets: Cupertino iOS, Material 3 Android, Fluent Windows. Touch and keyboard/mouse, resize, scalable text, screen-reader labels, high contrast, full Windows keyboard navigation. Identifier `com.infinityball.minutekeeper` for Android applicationId, iOS bundle ID, Windows identity if used. App Store Connect bundle identifier CREATED; ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8, ASC_TEAM_ID secret names installed (no values in repo).

`AppStore/description.txt` is planned-feature copy, not a feature claim. Real 1024×1024 RGB `AppStore/icon.png` generated via OpenAI Images (`spark-media image`); platform icon wiring awaits skeleton. No placeholder icons.

## Development

After skeleton issue: `flutter pub get`, `flutter test`, `flutter build windows --release` on Windows, `flutter build apk --debug` on Linux. Host-side Linux checks should use a pinned Flutter Docker image. `.github/workflows/release.yml` (planned) must build Windows on `windows-latest` for `v*` tags/manual dispatch and attach portable ZIP to GitHub release. TestFlight/Play submission deferred.

See [PLAN.md](PLAN.md) and [issues](https://github.com/rwrife/minute-keeper/issues). No build has run yet.
