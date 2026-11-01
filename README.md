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
| [docs/AGENT_BRIEF.md](docs/AGENT_BRIEF.md) | Coding rules and decisions for the project |

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

## Release

Release builds are signed with your upload key and obfuscated. Without `android/key.properties`, a
release build stops at once with "Release builds need android/key.properties and the upload
keystore". Debug and profile builds, `flutter run` and the integration test don't need it.

There is deliberately no fallback to the debug key. Android installs an update only if it is
signed with the same key as the app already installed, so a release signed with the wrong key can
only be replaced by uninstalling, and uninstalling deletes every expense.

### One-time setup: the upload key

Create the keystore outside the project, with the `keytool` that comes with Android Studio (it
isn't on the PATH):

```sh
mkdir -p ~/keys
"/c/Program Files/Android/Android Studio/jbr/bin/keytool.exe" -genkeypair -v \
  -keystore ~/keys/traccash-upload.jks -storetype PKCS12 \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

It asks for a password, then your name and organisation for the certificate. A PKCS12 keystore
has one password, which is both the store and the key password. 10000 days is about 27 years.

Then create `android/key.properties`. Git ignores it, and `*.jks` and `*.keystore` files too:

```properties
storeFile=C:/Users/<you>/keys/traccash-upload.jks
storePassword=<the password>
keyAlias=upload
keyPassword=<the same password>
```

Use forward slashes in `storeFile`: a `.properties` file reads `\` as an escape character, so
`C:\Users\…` would be read wrongly. A relative path is resolved from `android/app/`.

**Back up the keystore file and its password** somewhere other than this PC; a password manager
can hold both. Every future update must be signed with this key. If it is lost, the app on your
phone can only be replaced by uninstalling it, which deletes its expenses (there is no backup or
export).

### Build

```sh
flutter build apk --release --target-platform android-arm,android-arm64 --obfuscate --split-debug-info=build-symbols/
```

The APK is `build/app/outputs/flutter-apk/app-release.apk`: 36.3 MiB at 1.0.0.

- **Every ARM phone, 32-bit and 64-bit.** The APK holds the app for `armeabi-v7a` (32-bit
  Android, including Android Go budget phones) and `arm64-v8a` (most phones), and Android picks
  the right one.
- **x86 and x86_64 devices refuse it.** Release builds leave out every non-ARM library
  (`android/app/build.gradle.kts`), so such a device refuses the install with
  `INSTALL_FAILED_NO_MATCHING_ABIS` instead of installing an app that can't start. The exception
  is a device that can also run ARM apps, such as recent Google emulator images and many x86
  Chromebooks: it installs the ARM code and runs it, slowly, through translation. For day-to-day
  work on the emulator, use a debug build (`flutter run`), which still includes x86_64.
- **Version.** The versionCode is the build number in `pubspec.yaml` (`1.0.0+1` gives 1), so
  Settings reads "1.0.0 (1)". `--build-number=2` overrides the `+1` without editing
  `pubspec.yaml`.
- **"The generated ELF library contains unobfuscated DWARF debugging information"** is printed
  during the build, once per processor type. It is expected: Flutter leaves stripping to the
  Android build, which removes that information from `libapp.so` before packaging (the check
  below confirms it).

A Play Store release would use `flutter build appbundle` with the same flags. Play then sends each
phone only the code for its own processor type.

Don't run `flutter test`, `flutter pub get` or `flutter pub add` while a release build is running.
They rewrite `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` to
include the dev-only `integration_test` plugin, which release builds leave out, and the build then
fails with `package dev.flutter.plugins.integration_test does not exist`. Run the build again on
its own.

### Keep the symbols

`--obfuscate` renames the app's Dart classes and functions, so a stack trace from a release build
can only be read with the symbols that the same build wrote to `build-symbols/`
(`app.android-arm.symbols` and `app.android-arm64.symbols`, 3–4 MB each). They map the
obfuscated names back, so git ignores `build-symbols/` and it must never be committed. Keep it
safely instead:

- After every release build, copy `build-symbols/` somewhere safe outside the project, named after
  the build, for example `traccash-1.0.0+1/`. The next build overwrites the folder, and symbols
  only match the build that wrote them.
- To read a stack trace from that build, use the file for the phone's processor type (arm64 on
  most phones):
  `flutter symbolize -i stacktrace.txt -d <that copy>/app.android-arm64.symbols`.

### Check that debug tools are not in the release build

The Developer section is compiled only into debug builds: it is shown only when `kDebugMode`, a
compile-time constant, is true, so the release compiler leaves it out. To confirm, search the
release build's compiled Dart code (`libapp.so`) for strings that exist only in that section and
in the demo data. Obfuscation renames code, not text, so the strings are still searchable. Run
these in Git Bash after the release build:

```sh
APK=build/app/outputs/flutter-apk/app-release.apk
for abi in arm64-v8a armeabi-v7a; do
  echo "-- $abi"
  for s in "Developer" "Load demo data" "Fail the next save" \
           "Debug builds only. Not in the release app." \
           "Simulates a local database error once." "Jollof with chicken"; do
    printf '%-45s %s\n' "$s" "$(unzip -p "$APK" lib/$abi/libapp.so | grep -a -c "$s")"
  done
  # Control: a string the release app does use, so a 0 above means "absent", not "wrong file".
  printf '%-45s %s\n' "Stored on this device (control)" \
    "$(unzip -p "$APK" lib/$abi/libapp.so | grep -a -c "Stored on this device")"
  # Debugging information, which would name the code that --obfuscate renamed.
  printf '%-45s %s\n' ".debug_info" \
    "$(unzip -p "$APK" lib/$abi/libapp.so | grep -a -c '\.debug_info')"
done
```

Expected, for each processor type: `0` for each of the first six lines (the section heading, its
three rows, its helper text, and a demo expense's note), `1` or more for the control, and `0` for
`.debug_info`.
"Developer" is an ordinary word, so if a future package brings it in, that line alone may stop
being 0; the other five still count.

The permissions the APK declares:

```sh
AAPT2="$(ls -d "$LOCALAPPDATA"/Android/Sdk/build-tools/* | sort -V | tail -1)/aapt2.exe"
"$AAPT2" dump permissions "$APK"
```

Expected, and nothing else:

```text
package: io.github.youngbossman.traccash
permission: io.github.youngbossman.traccash.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION
uses-permission: name='io.github.youngbossman.traccash.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION'
```

That permission comes from AndroidX (`androidx.core`). It is signature-level, so only apps signed
with this app's key can use it, and it keeps other apps from sending to receivers inside the app.
No user is asked for it, and Android's App info shows "No permissions requested". There is no
`INTERNET` permission: that is only in the debug and profile builds, for Flutter's tools.

### Release checklist

Do these on a real phone before handing a build to anyone.

1. **Build and keep the symbols.** Build as above, then copy `build-symbols/` to safe storage as
   `traccash-1.0.0+1`.
2. **Install on a real phone.** With USB debugging on:
   `adb install build/app/outputs/flutter-apk/app-release.apk` (`adb` is in
   `%LOCALAPPDATA%\Android\Sdk\platform-tools`). Don't use `flutter install`: it uninstalls the app
   first, which deletes its data. A debug build from `flutter run` is signed with the debug key,
   so uninstall it before the first release install.
3. **First launch.** The launcher shows "TracCash" with the green icon, not the Flutter logo. The
   launch screen is a plain colour, light or dark as the phone is, with no white flash on a dark
   phone. Settings has no Developer section, and Version reads 1.0.0 (1).
4. **Airplane mode.** Turn it on (Wi-Fi and mobile data off), force-stop the app and open it. Open
   every tab. Add, edit, delete and Undo all work.
5. **Full CRUD.**
   - Add an expense with a preset category, and one with a new category.
   - Edit an expense's amount, date, category and note.
   - Move an expense to another month; it shows in that month.
   - Delete with Undo (it comes back), then delete for good.
   - Home, Expenses and Reports agree on the month's total.
6. **Restart persistence.** Force-stop (App info › Force stop) and reopen; swipe the app away from
   recents and reopen; restart the phone and reopen. Every expense, new category and the theme are
   still there each time.
7. **Theme.** System, Light and Dark each apply at once. With Dark chosen, force-stop and reopen:
   the app opens dark (the launch screen before it follows the phone).
8. **Large text.** Set the phone's font size and display size to the largest. Every tab, the
   form, the filter sheet and the dialogs are readable, with nothing cut off.
9. **Upgrade.** With data added in 1.0.0+1:
   - Build again with `--build-number=2`, and keep its symbols as `traccash-1.0.0+2`.
   - `adb install -r build/app/outputs/flutter-apk/app-release.apk` (`-r` replaces the app and
     keeps its data).
   - Open it: Settings reads 1.0.0 (2), and every expense, every category you created and the
     theme survived.
   - Afterwards the phone has versionCode 2, and Android won't install a lower one. The next real
     release must be build 3 or higher, or uninstall this test build first (which deletes its
     data).

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
  phone the launch screen is light for a moment. Android shows it before the app can read the
  stored choice.
- **The release APK is for ARM devices only.** An x86 or x86_64 device that can't translate ARM
  apps refuses to install it ([Build](#build)).
- **Antivirus HTTPS scanning breaks the Android build.** Antivirus that scans HTTPS traffic (for
  example Avast's Web Shield) replaces Google's and Maven's certificates with its own, which Java
  doesn't trust, so Gradle's downloads fail with `PKIX path building failed`. Fix it by adding
  exceptions in the antivirus for `dl.google.com`, `repo.maven.apache.org`, `plugins.gradle.org`
  and `services.gradle.org`, or by pausing HTTPS scanning for the first build (Gradle caches what
  it downloads, so later builds work with it back on).
