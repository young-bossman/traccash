# TracCash

An offline expense tracker for Android, in Ghana cedis, built with Flutter. Expenses stay on the
phone: there is no account, no server and no network access, and Android cloud backup is turned
off.

- **Home:** the month's total, a comparison with the same days last month, the largest categories
  and the latest expenses.
- **Expenses:** the month's expenses grouped by day, with search and a category filter. Tap a row to
  edit or delete it (with Undo).
- **Reports:** total, average per day, the category table and a daily or 6-month bar chart.
- **Settings:** System / Light / Dark theme, and in debug builds a Developer section.

Amounts are whole pesewas (`int`) everywhere; nothing about money uses `double`.

## Documents

| File | What it holds |
| --- | --- |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Layers, data flow, data model, money and date rules, testing |
| [docs/design/DESIGN_SPEC.md](docs/design/DESIGN_SPEC.md) | Colours, type, components, validation, interactions; screenshots in `docs/design/screens/` |
| [docs/DECISIONS.md](docs/DECISIONS.md) | Why things are the way they are, newest last |
| [docs/PROGRESS.md](docs/PROGRESS.md) | What each task built, and known issues |
| [docs/AGENT_BRIEF.md](docs/AGENT_BRIEF.md) | Rules for the coding agent that wrote most of the code |

## Requirements

- **Flutter 3.47.7** on the stable channel (it brings Dart 3.13.5). CI uses the same version; a
  different one may format or analyze differently.
- **Android SDK** with an emulator or a phone with USB debugging, and **JDK 17 or newer** (the one
  bundled with Android Studio works). `flutter doctor` should show no errors for Android.
- The shell commands below are for Git Bash on Windows, or any POSIX shell.

## Setup

```sh
git clone <this repository>
cd traccash
flutter pub get
flutter doctor
```

The generated Drift code (`*.g.dart`) is committed, so a fresh clone builds without running code
generation first.

The first Android build downloads Gradle and the Android build tools, which takes a few minutes.
If it fails with `PKIX path building failed`, see [Known limitations](#known-limitations).

## Code generation

Only needed after changing the tables in `lib/data/database/tables.dart`:

```sh
dart run build_runner build
```

Commit the regenerated `app_database.g.dart` with the change. (The installed build_runner ignores
`--delete-conflicting-outputs`, which older instructions mention.)

A table change is also a schema change. Bump `schemaVersion` in `app_database.dart`, add a
migration step, then save a snapshot of the new schema and regenerate the test helpers:

```sh
dart run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/
dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
```

`test/data/schema_test.dart` fails until both are done, so a table can't change under an existing
version number.

## Run

```sh
flutter emulators                       # list emulators
flutter emulators --launch <emulator id>
flutter run
```

Debug builds show a **Developer** section at the bottom of Settings:

- **Load demo data:** adds 41 sample expenses over the last 75 days, only when there are none yet.
- **Clear all data:** deletes every expense and every category you created, after a confirmation.
  The 8 preset categories and the theme setting stay.
- **Fail the next save:** makes the next save fail once, to show the error states.

None of these exist in a release build ([checked below](#check-that-debug-tools-are-not-in-the-release-build)).

## Test

The same three checks CI runs:

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

`flutter test` runs everything under `test/`:

| Folder | Covers |
| --- | --- |
| `test/unit/` | Money parsing and formatting, dates, calculations, each screen's view state, colour contrast |
| `test/data/` | The Drift repositories and database constraints on an in-memory SQLite, and the schema against its snapshots |
| `test/widget/` | Every screen on hand-written fake repositories: flows, states, layout (in IBM Plex Sans), accessibility guidelines, text scale 1.3 |
| `test/fakes/` | The fake repositories |

- **Hangs fail fast.** Each test gets 60 seconds: `dart_test.yaml` sets it for plain tests and
  `test/flutter_test_config.dart` for widget tests.
- **Random order.** CI runs `flutter test --test-randomize-ordering-seed random`, which prints the
  seed first (`Shuffling test order with --test-randomize-ordering-seed=…`). To repeat a failing
  order locally, pass the same number instead of `random`.

### Integration test (device or emulator)

`integration_test/restart_persistence_test.dart` adds an expense through the real form, closes
the database, opens a new connection to the same file, and checks the expense is still there with
the same amount, category, date and note. It uses its own temporary database file, so it never
touches expenses already on the phone. It isn't part of `flutter test` or CI.

```sh
flutter devices                                 # find the device id
flutter test integration_test -d emulator-5554  # your device id here
```

It builds and installs a debug APK first, which takes a few minutes the first time.

## Build

```sh
flutter build apk --release
```

The APK is `build/app/outputs/flutter-apk/app-release.apk`. Until release preparation (T10) it is
signed with the debug key and not obfuscated: fine for installing on your own phone, not for
distribution.

Don't run `flutter test`, `flutter pub get` or `flutter pub add` while a release build is running.
They rewrite `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` to
include the dev-only `integration_test` plugin, which release builds leave out, and the build then
fails with `package dev.flutter.plugins.integration_test does not exist`. Run the build again on
its own.

### Check that debug tools are not in the release build

The Developer section is compiled only into debug builds: it is shown only when `kDebugMode`, a
compile-time constant, is true, so the release compiler leaves it out. To confirm, search the
release build's compiled Dart code (`libapp.so`) for strings that exist only in that section and
in the demo data. Run these in Git Bash after `flutter build apk --release`:

```sh
APK=build/app/outputs/flutter-apk/app-release.apk
for s in "Developer" "Load demo data" "Fail the next save" \
         "Debug builds only. Not in the release app." \
         "Simulates a local database error once." "Jollof with chicken"; do
  printf '%-45s %s\n' "$s" "$(unzip -p "$APK" lib/arm64-v8a/libapp.so | grep -a -c "$s")"
done
# Control: a string the release app does use, so a 0 above means "absent", not "wrong file".
printf '%-45s %s\n' "Stored on this device (control)" \
  "$(unzip -p "$APK" lib/arm64-v8a/libapp.so | grep -a -c "Stored on this device")"
```

Expected: `0` for each of the first six lines (the section heading, its three rows, its helper
text, and a demo expense's note), and `1` or more for the control. "Developer" is an ordinary word,
so if a future package brings it in, that line alone may stop being 0; the other five still count.

## Known limitations

- **Android only.** The layouts are platform-neutral, but no iOS build has been made or tested.
- **No backup or export.** Expenses live only in the app's storage on the phone; uninstalling the
  app deletes them. Cloud backup is off (`android:allowBackup="false"`). Android 12 and later can
  still copy app data in a direct device-to-device transfer.
- **Field borders are low contrast** (an accessibility gap): the outline of text fields is about
  1.5:1 against its background in both themes, below the 3:1 that WCAG 2.1 SC 1.4.11 asks for.
  Every field has a visible label, and the focused or invalid field's border does meet 3:1. Kept
  for v1 as designed; see DECISIONS.md.
- **The Home breakdown bar's colours are decorative.** The lightest slice is under 3:1, so the
  legend names every slice with its amount and share, and screen readers get the same summary.
- **Search has no accent folding:** "ecole" doesn't find "École".
- **Monthly chart labels have no year** ("Dec", "Jan"); the screen-reader summary adds it.
- **The launch screen follows the phone's theme**, not the app's, so with Dark chosen on a light
  phone the splash is light for a moment.
- **Version reads 0.1.0 (1)** and release builds use the debug signing key until T10.
- **Antivirus HTTPS scanning breaks the Android build.** Antivirus that scans HTTPS traffic (for
  example Avast's Web Shield) replaces Google's and Maven's certificates with its own, which Java
  doesn't trust, so Gradle's downloads fail with `PKIX path building failed`. Fix it by adding
  exceptions in the antivirus for `dl.google.com`, `repo.maven.apache.org`, `plugins.gradle.org`
  and `services.gradle.org`, or by pausing HTTPS scanning for the first build (Gradle caches what
  it downloads, so later builds work with it back on).
