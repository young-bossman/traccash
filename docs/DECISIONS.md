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

**2026-10-25 · Add expense button in the shell's Scaffold** — Snackbars ("Expense saved", Undo)
appear only in the outermost Scaffold, `AppShell`'s, and a Scaffold lifts only its own floating
button above a snackbar. With the button on the Expenses screen's inner Scaffold, the snackbar
covered it for 4–5 s. `AppShell` now shows the button for the Expenses tab (Home joins in T6).
Cost: the shell knows which tabs have an add button.

**2026-10-25 · Hard text limits counted in code points** — The note (200) and category name (20)
are limited while typing, with an `N / 200` counter, as in the prototype. Flutter's `maxLength`
counts grapheme clusters, so an emoji-heavy note could pass the field and then fail the repository
and the CHECK constraint, which count code points. `RuneLengthLimitingTextInputFormatter` mirrors
Flutter's Android behaviour (typing at the limit is ignored, a paste is cut) but counts runes, and
cuts only between whole characters, so a 4-code-point emoji is dropped whole rather than split.
Cost: a counter that counts some emoji as 2 to 7, and a paste is cut silently. The repository still
validates both limits.

**2026-10-25 · Form state in the widget, not a controller** — The form's values are UI state until
Save. Text lives in controllers and the category, date and write in progress in the `State`; the
widget calls the repository through its provider. The double-submit guard reads a field set
synchronously on the first tap, so a second tap in the same frame (before the button redraws as
disabled) can't write twice. A Riverpod controller per form would add a family/autoDispose
provider without making this simpler. Validation is a pure function (`validateExpenseForm`) with
its own unit tests.

**2026-10-25 · The form route ignores taps while it slides in** — A route receives pointer events
during its entrance animation. A double tap on Add expense put the second tap on the form sliding
up underneath, selecting whichever category option was passing. The transition wraps the page in
an `IgnorePointer` while its animation runs forward (200 ms; nothing under reduced motion).

**2026-10-25 · Category options in rows, not a fixed-extent grid** — DESIGN_SPEC names a 2-column
`GridView`, but a grid needs a fixed tile height, which clips labels at large text sizes. The
picker builds rows of two with `IntrinsicHeight`, so both options in a row take the taller one's
height and grow with the text. Fine for the handful of categories a user has.

**2026-10-25 · Action snackbars stay up for screen readers** — Undo and View time out after 5 s,
but with TalkBack on (`MediaQuery.accessibleNavigationOf`) they stay until dismissed or actioned,
since reaching the action by swiping can take longer than 5 s.

**2026-10-25 · Date picker opened through `showDialog`** — Reduced motion must skip fades
(DESIGN_SPEC §7), but `showDatePicker` (Flutter 3.47.7) passes no animation setting to its dialog,
so the picker faded in regardless. The date field shows the same `DatePickerDialog` through
`showDialog`, with the delete and discard dialogs' setting (`dialogAnimation`: no animation under
reduced motion). Range, initial-date clamp and en_GB format are unchanged. Cost: defaults that
`showDatePicker` adds in a future Flutter release won't reach this field automatically.

**2026-10-25 · "Changes saved" after an edit** — The T5 card and DESIGN_SPEC §7 say "Expense
saved". After an edit the snackbar reads "Changes saved" ("Changes saved to September 2026" with
View), wording from the prototype, which says the edit was stored rather than a new expense.
Adding still says "Expense saved". A deliberate deviation from the card.

**2026-10-25 · Home names a fourth category instead of "1 other category"** — DESIGN_SPEC §4 says
top 3 categories plus "N other categories". With exactly 4 categories that would be a row reading
"1 other category" that hides a name and saves no space, so the fourth is named (in the c4
colour). Five or more still group from the fourth on. Goes beyond the spec; decided by Bossman.

**2026-10-25 · Shares rounded across all categories** — Largest-remainder rounding gives slightly
different tenths depending on which amounts are rounded together. Home rounds every category
together and makes "N other categories" the sum of its members' rounded shares, so a category
reads the same on Home as in Reports' full table, and Home's legend still totals 100.0%. Cost:
the grouped row can differ from its own exact share by up to a few tenths.

**2026-10-25 · Ties in the breakdown sentence use the amount** — Rounding to exactly 100.0% gives
equal amounts different shares (33.4%, 33.3%, 33.3%), so "Food is the largest share, at 33.4%"
would be false. When categories tie for the largest total the sentence names them all with the
shared amount: "Food and Transport share the largest amount, GH₵ 50.00 each."

**2026-10-25 · Home's comparison hides itself when the earlier period fails** — The comparison is
a second stream (`watchBetween` over the compared days). If only that stream fails, Home leaves
the line out and shows everything else; only a failure of the month's own stream shows the error
state. Decided by Bossman. Cost: there is no retry for the line alone; it reads again when the
month or the day changes, or after Try again on a month failure.

**2026-10-25 · Recent follows the selected month** — Home's Recent list is the selected month's 5
latest expenses (the start of the same list Expenses shows), not the latest 5 overall, so every
section on Home and View all describe one month. It needs no extra stream.

**2026-10-25 · Empty-month body depends on the month** — Not in spec, chosen after review. T4's
"Nothing was recorded for this month." also showed for past months, where "this month" reads as
the calendar month. The body is now "Nothing recorded so far this month." for the current month
and "Nothing was recorded that month." for a past one; the title above names the month.
`EmptyMonthState`, shared by Home and Expenses, reads `todayProvider` to tell them apart.

**2026-10-25 · Single-category sentence without a possessive** — Not in spec, chosen after
review. "Food is all of September 2026's spending." read awkwardly, so Home says "Food is all the
spending this month." for the current month and "Food is all the spending in September 2026." for
a past one.

**2026-10-25 · Reports' comparison stat shows a sign** — Refines the T2 rule ("differences are shown
as an absolute amount with words") for this one stat. Reports' stats row has room for a figure, not
a sentence, and the prototype (screenshot 10) shows `−GH₵ 3,257.10`. The value is `+GH₵ 1,234.00`
when more, `−GH₵ 3,257.10` (U+2212) when less, `GH₵ 0.00` when equal, and `No data` when either side
is zero. `formatGhs` still only ever receives the absolute value; the sign is prefixed. Screen
readers hear words instead: "GH₵ 3,257.10 less than 1–21 Sep", "… more than …", "Same as …". The
label is "vs 1–21 Sep" for the current month ("vs 1 Sep" on the 1st) and names the previous month
for a past one ("vs Aug 2026"). Home keeps its own sentence and its "1–31 Aug" wording for past
months. Decided by Bossman.

**2026-10-25 · First record date re-read on every trend emission** — The monthly trend never shows
months before the first record, but `ExpenseRepository.firstExpenseDate()` is a one-off `Future`
and the contract was not to change in T7. `firstExpenseDateProvider` watches the trend's
`watchBetween` stream and reads the date again whenever it emits. This relies on Drift re-running
every watched query on a table after any write to that table (drift 2.35 `QueryStream` emits
without comparing results), so an expense added or deleted outside the six months still refreshes
the date. If that behaviour changed, the worst case is a few empty leading months too many or too
few until the month changes; never a wrong amount. The fake repository emits on every write too,
and a widget test covers it: first record 3 months back gives 4 bars; adding one 8 months back
gives 6 without a refresh. A `watchFirstExpenseDate()` in the contract would remove the
dependency.

**2026-10-25 · Stats columns sized to their content** — Screenshot 10 gives the three stats equal
columns, and the third value runs past the page padding. Equal columns at 390dp leave about 100dp
for "−GH₵ 3,257.10", which needs about 107dp in Plex. Each column is as wide as its own label or
value plus padding, and any spare width is shared equally; when they don't fit, the stats stack one
per line. In Plex at text scale 1.0 they share a line from 360dp up. Cost: the dividers don't sit
at exact thirds.

**2026-10-25 · Chart money labels capped at 40% of the chart** — The value axis is as wide as its
widest label at the user's text size, so labels are never clipped. With very large totals at large
text (GH₵ 5,000,000 at 2.0 on a 320dp phone), that width alone exceeded the chart and fl_chart's
title row overflowed. The labels' column is capped at 40% of the chart's width
(`AppSizes.chartAxisMaxShare`) and labels past it scale down, keeping every digit. Cost: tiny
labels in that extreme case.
