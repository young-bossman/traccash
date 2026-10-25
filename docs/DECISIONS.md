# Decision records

Short records for trade-offs that matter. Newest at the bottom.
Format: **Date · Title** — Context. Decision. Consequence.

**2026-10-21 · Money as integer pesewas** — Floating point can't represent 0.29 exactly.
All amounts are `int` pesewas; conversion happens only when formatting. Parsing never uses `double`.

**2026-10-21 · Date-only `occurred_on` as TEXT** — An expense happens on a day, not an instant, and
timezone shifts must not move it across a month boundary. Stored as `YYYY-MM-DD`; sorts and
range-filters correctly as text.

**2026-10-21 · Repository contract over Drift** — Screens must not depend on persistence details,
and widget tests need a fake. Abstract repositories with a Drift implementation. No further layers.

**2026-10-21 · allowBackup disabled** — Settings promises data stays on the device. Android auto
backup would upload the database, so `android:allowBackup="false"`.

**2026-10-21 · Material icons instead of Lucide** — Avoids an extra dependency; Material outlined
icons are visually close to the prototype.

**2026-10-24 · Dot-only decimal, strict comma grouping** — Some Android keyboards type `12,50` meaning
12.50; ignoring commas would save GH₵ 1,250.00. Commas are accepted only as valid thousands
grouping; anything ambiguous is rejected with a clear message rather than guessed.

**2026-10-24 · en_GB locale** — Ghana writes dates day/month/year. `flutter_localizations` with a
fixed `en_GB` locale makes the date picker and numeric dates match.

**2026-10-24 · Commit generated Drift code** — A fresh clone builds and runs without a codegen
step. Cost: generated diffs in commits; regenerate and commit together with table changes.

**2026-10-24 · Range queries in the repository** — Reports needs data across up to 6 months and the
first record date. `watchBetween` and `firstExpenseDate` belong in the data layer from the start
rather than being bolted on later.

**2026-10-24 · Clear all data scope** — Removes expenses and user-created categories; keeps presets
and theme, so the app returns to its first-install state without a reinstall.

**2026-10-24 · Backup scope: cloud off, device transfer accepted** — `android:allowBackup="false"`
stops Android cloud backup, so the database is never uploaded. Android 12+ device-to-device
transfer ignores that flag and can still copy app data to a new phone. Accepted for v1: with no
export or sync, it is the only way users keep their expenses when changing phones, and the data
stays on hardware the user owns. Revisit when export is added.

**2026-10-25 · Amount input length and overflow guard** — Very long digit strings must not
overflow `int.parse`, and the error shown should name the real problem. Trimmed input over 20
characters is rejected as invalid format before any other check (nothing valid needs more:
`1,000,000.00` is 12). Leading zeros are stripped from the cedis as a string, and more than 7
significant digits returns "at most GH₵ 1,000,000.00" rather than "invalid format", because that is
why it failed. Replaces the earlier "more than 9 cedi digits is invalid format" rule.

**2026-10-25 · First thousands group may not start with 0** — `0,500` and `000,000` would otherwise
pass the grouping rule and be read as 500 and 0 cedis, though the user probably meant 0.50.
Rejected with the misplaced-comma message instead of guessing.

**2026-10-25 · Load en_GB date data in `main()`** — `DateFormat` throws until locale data is
loaded, and `flutter_localizations` only loads it once `MaterialApp` builds. `main()` awaits
`initializeDateFormatting('en_GB')` before `runApp`, so formatting is safe from startup code too.
Unit tests do the same in `setUpAll`.

**2026-10-25 · Shared validation for repositories and fakes** — Widget tests run against fakes;
if the fakes enforced looser rules, tests could pass while the app rejects the same input. The
expense and category rules are pure functions returning an `AppError` or null, called by both the
Drift repositories and the fakes, which also throw the same typed errors for missing records.

**2026-10-25 · Lengths in code points** — SQLite's `length()` counts code points, Dart's
`String.length` counts UTF-16 units and Flutter's `maxLength` counts graphemes. Notes (200) and
category names (20) are counted with `runes.length` so the repository and the CHECK constraint
agree; the form must count the same way.

**2026-10-25 · Case-insensitive names beyond ASCII** — `COLLATE NOCASE` only folds A–Z, so
"École" and "école" would both be stored. The repository also compares names with
`toLowerCase()` inside the insert transaction; the NOCASE unique constraint remains the backstop.

**2026-10-25 · Timestamps as UTC ISO text** — Drift's default stores whole Unix seconds. With
`store_date_time_values_as_text`, `created_at` / `updated_at` keep milliseconds and an explicit `Z`,
read plainly in a SQLite browser, and come back as UTC. Repositories always write
`DateTime.now().toUtc()`. Cost: slightly larger rows.

**2026-10-25 · Expense carries its Category** — Screens need the category name and icon for every
row, including archived categories. Joining in the repository query keeps that in one stream
instead of every screen combining expenses with a category map. Cost: a category change re-emits
expense streams, which is what we want for labels.

**2026-10-25 · Restore by explicit id under AUTOINCREMENT** — Undo must bring back the same id.
`AUTOINCREMENT` makes SQLite keep a high-water mark in `sqlite_sequence`, so a deleted id is never
given to a new row and re-inserting it is safe. Restore checks for an existing row and uses a plain
insert rather than `INSERT OR IGNORE`, which would also silently skip CHECK violations.
