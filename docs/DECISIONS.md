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

**2026-10-25 · No Riverpod retry for the expense streams** — Riverpod 3 retries a failed provider
up to 10 times with backoff by default, and `AppError`s are exceptions, so they would be retried.
A storage error from these streams means an unreadable file or a corrupted row, which retrying
won't fix, and the screen would flick between error and loading. `monthExpensesProvider`,
`hasAnyExpensesProvider` and `allCategoriesProvider` set `retry` to return null. The error state
offers "Try again", which invalidates them.

**2026-10-25 · Fixed Expenses header, shrinking ledger** — Search must stay visible while typing,
and day headers pin just below it. The title, month, summary, search and filter chip stay fixed;
the ledger takes what is left. At extreme sizes (320dp, text scale 2.0, keyboard open) the ledger
gives up height first, and the header scrolls inside itself only if it alone is taller than the
screen. Cost: on small phones the fixed header uses about 40% of the height.

**2026-10-25 · Large amounts move, they don't shrink** — A row's amount must stay readable and on
one line, but at 320dp and text scale 2.0 a GH₵ 1,000,000.00 amount can't fit beside the category.
The amount moves to its own line under the category when staying beside it would leave the
category and note narrower than 96dp (`AppSizes.ledgerMinTextWidth`), scaled by the text scale
factor read at the 15px row title size. It scales down only if even its own line is too narrow.
At text scale 1.0 (IBM Plex Sans), GH₵ 4,800.00 stays beside the category down to 297dp wide and
GH₵ 1,000,000.00 down to 329dp; at 360dp they move above text scale ×1.33 and ×1.14 (linear
scaling). Replaces a
first version that moved the amount once it took more than half the text area, which put
GH₵ 1,000,000.00 on its own line at 360dp and scale 1.0 with room to spare.

**2026-10-25 · Today as provider state** — Today / Yesterday labels and the next-month limit must
follow the calendar while the app stays open. `todayProvider` sets a timer for the next local
midnight and also re-reads the date on app resume, because Android doesn't run Dart timers while
the app is suspended. Tests override it with a fixed date.

**2026-10-25 · Ledger day headers without the year** — The Expenses page always shows one month, so
a year in every day header repeats information and lengthens the line beside the day total. Headers
read Today, Yesterday or "Monday, 19 October" (`EEEE, d MMMM`). The long form with the year stays
for the form's date helper (T5). Matches screenshots 04, 05 and 13.

**2026-10-25 · Short month names from a fixed list** — The design abbreviates September as "Sep"
(DESIGN_SPEC §6 "1–21 Sep", screenshots 01, 10 and 11), but en_GB's CLDR data gives "Sept".
`shortMonthName(month)` in `dates.dart` returns a fixed `Jan`…`Dec` list; `CalendarMonth.shortLabel`
("Sep 2026") and Home's comparison label (T6) use it. Every other date keeps en_GB formatting.
