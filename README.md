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

Flutter app with iOS Cupertino, Android Material 3, and Windows Fluent presentation. Local meetings, agenda, decisions/actions, and cross-meeting action dashboard persist on device. Planned next: opt-in Markdown share and validated JSON backup/restore. Adaptive phone/tablet/Windows layout uses platform-authentic controls. No cloud accounts, recording, transcription, automatic attendee tracking, or background sync. Data stays on device; sharing/export leaves it only on user action. No permissions required for core use; file picker/share APIs only on explicit request. Treat minutes as private; sharing UI must preview content before export.

## Platforms / build

Flutter stable/Dart single codebase. Windows primary CI/release, Android and iOS phones/tablets first-class; `windows/`, `android/`, `ios/` platform projects included. Native per-platform adaptive widgets: Cupertino iOS, Material 3 Android, Fluent Windows. Touch and keyboard/mouse, resize, scalable text, screen-reader labels, high contrast, and full Windows keyboard navigation remain acceptance goals for later workflow issues. Identifier `com.infinityball.minutekeeper` for Android applicationId, iOS bundle ID, Windows MSIX identity reserved for packaging issue. App Store Connect bundle identifier CREATED; ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8, ASC_TEAM_ID secret names installed (no values in repo).

`AppStore/description.txt` is planned-feature copy, not a feature claim. Real 1024×1024 RGB `AppStore/icon.png` generated via OpenAI Images (`spark-media image`) and resized into Android, iOS, and Windows icon sets. No placeholder launcher icons.

## Development

Pinned Flutter stable 3.47.7 (Dart 3.13.5). Run `flutter pub get --enforce-lockfile`, `flutter analyze`, and `flutter test`. `.github/workflows/ci.yml` builds Windows release on `windows-latest`, Android debug on Linux, and unsigned iOS simulator on macOS; Linux also runs tests and Android debug build in pinned `gmeligio/flutter-android:3.47.7` Docker image. Local ARM64 Flutter 3.47.7 analysis and 3 widget tests pass; this host cannot run amd64 Flutter Docker image (`exec format error`). Windows build evidence awaits CI. `.github/workflows/release.yml` (planned) must build Windows on `windows-latest` for `v*` tags/manual dispatch and attach portable ZIP to GitHub release. TestFlight/Play submission deferred.

See [PLAN.md](PLAN.md) and [issues](https://github.com/rwrife/minute-keeper/issues). No platform build verified yet.
