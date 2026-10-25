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
