# Minute Keeper — Implementation Plan

Offline meeting decision ledger: capture agenda decisions, owners, due dates, and follow-ups with shareable minutes on phone, tablet, and Windows without accounts.

## Scope & Architecture

Minute Keeper is a multi-platform Flutter application (Dart, stable channel) running from a single codebase across Windows Desktop, Android, and iOS (phones and tablets).

### Technology Choices & Platform-Authentic UX

UX Strategy: **(A) PLATFORM-NATIVE ADAPTIVE**
- **iOS & iPadOS**: Cupertino widgets, SF-style typography, navigation bars with large titles, swipe-to-go-back, action sheets, native haptics.
- **Android (phone & tablet)**: Material 3, dynamic color support, predictable system back handling, bottom navigation / navigation rail on tablets.
- **Windows**: Fluent design (using `fluent_ui` or adaptive platform widget layer), standard window title bar controls, command bar navigation, keyboard shortcuts (Ctrl+N, Ctrl+S, Esc), context menus, hover states, full keyboard accessibility.
- Architecture: Clean domain-driven design with an adaptive widget layer (`AdaptiveScaffold`, `AdaptiveDialog`, `AdaptiveButton`) wrapping pure Dart domain models, ensuring business logic is 100% platform-independent and unit tested.

### Identifiers & App Store Connect

- Application Identifier: `com.infinityball.minutekeeper` (configured across Android `applicationId`, iOS `PRODUCT_BUNDLE_IDENTIFIER`, and Windows identity).
- App Store Connect bundle identifier: registered (`CREATED com.infinityball.minutekeeper`).
- GitHub Actions Secrets: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, and `ASC_TEAM_ID` configured for automated delivery pipelines.
- Listing metadata: `AppStore/description.txt` maintained as accurate listing copy.
- Application Icon: real icon generated at `AppStore/icon.png` using `spark-media image` and wired into Windows ICO, Android mipmaps, and iOS asset catalogs (no placeholder icons allowed).

## Milestones & Dependency Order

1. **Skeleton & CI**: Initialize Flutter multi-platform project with `windows`, `android`, and `ios` enabled. Setup GitHub Actions CI on `windows-latest` running `flutter test` and `flutter build windows --release`. Verify project compilation and automated checks.
2. **Domain Layer & Local Storage**: Pure Dart models for `Meeting`, `AgendaItem`, `Decision`, `ActionItem` (with owner and due date). SQLite / local atomic JSON storage with deterministic migration, schema validation, and unit tests.
3. **Core Workflow — Meeting & Decision Entry**: Meeting creation, agenda structuring, real-time decision logging, action item assignment, and status updates (pending, completed, carried-over).
4. **Adaptive UI & Action Tracking**: Responsive adaptive views (phone portrait/landscape, tablet two-pane navigation rail, Windows desktop multi-column) with platform-authentic styling. Consolidated outstanding-action dashboard across meetings.
5. **Export, Sharing & Backup**: Privacy-first export engine: formatted Markdown minutes preview, clipboard copy, and validated JSON backup/restore with schema verification.
6. **Platform Integration & Accessibility**: Full Windows keyboard navigation, high contrast mode, screen-reader semantics, scalable typography, and golden/widget tests for iOS, Android, and Windows targets.
7. **Packaging & Release**: Deliver `.github/workflows/release.yml` building on `windows-latest` for `v*` tags and manual dispatch, creating a GitHub release with zipped portable Windows binaries. Mobile releases documented as future roadmap.

## Testing Strategy

- **Unit Tests**: 100% coverage on domain logic, action item state transitions, agenda ordering, and backup serialization/deserialization.
- **Widget & Golden Tests**: Adaptive widget tests verifying correct rendering under `TargetPlatform.iOS`, `TargetPlatform.android`, and `TargetPlatform.windows`.
- **Packaging Verification**: Validated automated build on GitHub Actions Windows runners producing testable release artifacts.

## Non-Goals & Security Boundaries

- No cloud servers, mandatory user accounts, or external API dependencies.
- No background recording, audio capture, speech-to-text, or automated meeting transcription.
- No automatic contact harvesting or third-party calendar sync without explicit user-selected file import.
- Zero analytics, telemetry, trackers, or unsolicited network calls. All data remains exclusively local until the user explicitly initiates a share or backup export.
