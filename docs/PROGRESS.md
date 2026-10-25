# TracCash progress

Maintained by the coding agent at the end of every task. Read at the start of every task.

## Tasks

- [x] T1 · Foundation: packages, fonts, theme, app shell
- [x] T2 · Money and date utilities
- [ ] T3 · Data layer: models, database, repositories, demo seeder
- [ ] T4 · Expenses page
- [ ] T5 · Add / edit expense page
- [ ] T6 · Home page
- [ ] T7 · Reports page
- [ ] T8 · Settings page
- [ ] T9 · Hardening
- [ ] T10 · Release prep

## Built so far

### T1 · Foundation (2026-10-24)

- Packages: flutter_riverpod 3.4.3, go_router 18.1.1, intl 0.20.3 (`any`, pinned by
  flutter_localizations), fl_chart, drift, drift_flutter, flutter_localizations; dev: drift_dev,
  build_runner.
- IBM Plex Sans 400/500/600 registered as family `IBMPlexSans`.
- `android:allowBackup="false"` in `AndroidManifest.xml`.
- `lib/app/theme/`: `app_colors.dart` (all tokens, light + dark, the only hex values),
  `app_spacing.dart` (`AppSpacing`, `AppRadius`, `AppSizes`, `AppElevation`),
  `app_typography.dart` (type ramp + `amount`, `axis`, `tabularFigures`), `app_palette.dart`
  (`AppPalette` ThemeExtension), `app_theme.dart` (explicit ColorSchemes + component themes).
- `lib/app/router.dart`: `routerProvider` with a 4-branch `StatefulShellRoute.indexedStack`;
  `AppRoutes` path constants.
- `lib/app/app_shell.dart`: Scaffold + NavigationBar; Android back on a non-Home tab goes to Home.
- `lib/app/app.dart`: `TracCashApp`, `ThemeMode.system`, locale fixed to `en_GB`.
- Placeholder screens: `features/{home,expenses,reports,settings}/presentation/*_screen.dart`.
- Tests: `test/widget/app_shell_test.dart` (build, tab switching, back behaviour, dark/light),
  `test/unit/color_contrast_test.dart` (AA for every text/background pair in both themes).

### T2 · Money and date utilities (2026-10-25)

- `lib/core/errors/amount_error.dart`: `AmountError` enum (`empty`, `invalidFormat`,
  `tooManyDecimals`, `misplacedComma`, `zero`, `overMax`), each with its user-facing `message`.
- `lib/core/formatting/money.dart`: `parsePesewas` returning a sealed `AmountParseResult`
  (`ValidAmount` / `InvalidAmount`), `formatGhs`, `splitGhs` (record `(cedis:, pesewas:)`),
  `ghsSymbol`, `maxPesewas`. String operations only, no `double`.
- `lib/core/formatting/dates.dart`: `LocalDate` (date-only value, ISO `YYYY-MM-DD` in and out,
  `addDays`, ordering), `CalendarMonth` (`first`, `last`, `nextStart`, `daysInMonth`, `previous`,
  `next`, `contains`, `label`), `formatNumericDate`, `formatLongDate`, `dayLabel`, `dateLocale`.
- `lib/main.dart`: now async and awaits `initializeDateFormatting(dateLocale)` before `runApp`.
- Tests: `test/unit/money_test.dart`, `test/unit/dates_test.dart`.

## Decisions made during implementation

- **Derived colours** (not on the design board), all AA-tested: light errorContainer `#FEE4E2` /
  onErrorContainer `#912018`; dark `#55160C` / `#FECDCA`; light inversePrimary `#20C997`; dark
  inversePrimary `#0B5C47`; onError white (light) / `#101827` (dark); onInverseSurface reuses the
  opposite theme's text colour.
- **Surface containers:** light Lowest/Low/Container = surface (white), High/Highest = surface-2.
  Dark Lowest = bg, Low/Container = surface, High/Highest = surface-2. Dim/bright set too.
- **Dialogs and sheets** use the card surface in light and surface-2 in dark (DESIGN_SPEC §1).
- **Secondary/tertiary roles** repeat the accent family so Material defaults (tonal buttons,
  segmented buttons) never introduce a second hue.
- **Router in a Riverpod provider**, not a global, so each test gets a fresh router.
- **Placeholder screens live at their final feature paths**, so later tasks replace their body
  without touching the router.
- **Nav icons:** `home_outlined`, `format_list_bulleted`, `bar_chart_outlined`, `tune_outlined`.

- **Amount parsing order:** trim → empty → length > 20 or a character outside `0-9 . ,` →
  comma rules (first group `[1-9]\d{0,2}`, later groups 3 digits, none after the dot) → dot rules
  → more than 2 decimals → strip leading zeros, > 7 digits is over the cap → zero / cap check.
- **Error messages on the enum** so the form and repository share one wording. Spec wording for
  `zero` and `misplacedComma`. Not in spec (my wording): `empty` "Enter an amount.",
  `invalidFormat` "Enter an amount like 12.50.", `tooManyDecimals` "Use at most 2 digits after
  the dot.", `overMax` "Amount must be at most GH₵ 1,000,000.00."
- **Explicit DateFormat patterns** (`dd/MM/yyyy`, `EEEE, d MMMM y`, `MMMM y`), never skeletons, so
  output can't change with intl's CLDR data.
- **`LocalDate.parseIso` throws `FormatException`**, since bad stored text means corrupted data,
  not user input. Constructor asserts catch impossible dates in debug; `parseIso` checks in release.
- **`LocalDate` years are 1–9999**, so ISO text is always 10 characters (matches the DB CHECK).
- **`dayLabel` takes `today` as a parameter** rather than reading the clock, for testability.
- **`formatGhs` / `splitGhs` assert non-negative.** Differences are shown as an absolute amount
  with words ("less than").

## Known issues / follow-ups

- **Recheck the back button once tabs have nested routes.** The `PopScope` in `AppShell` assumes
  each tab is a single page. When a tab pushes a child route (or the add/edit form opens), back
  must pop that route first, then go to Home, then exit. Add a widget test for that case.
- Widget tests render with the test font (Ahem), so Plex is only verifiable on a device.
- **Asserts are debug-only.** `LocalDate(2026, 2, 30)` and `formatGhs(-1)` are caught in
  debug and tests but not in release. T3 repositories must build `LocalDate`s via `parseIso` (which
  always checks) or from validated input.
- **Day labels need a "today" that refreshes.** If the app stays open past midnight, Today and
  Yesterday labels are stale until something rebuilds. Address when the ledger is built (T4).
