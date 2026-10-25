# TracCash progress

Maintained by the coding agent at the end of every task. Read at the start of every task.

## Tasks

- [x] T1 · Foundation: packages, fonts, theme, app shell
- [x] T2 · Money and date utilities
- [x] T3 · Data layer: models, database, repositories, demo seeder
- [x] T4 · Expenses page
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

### T3 · Data layer (2026-10-25)

- `lib/core/errors/app_error.dart`: sealed `AppError` (`InvalidAmountError`, `InvalidDateError`,
  `NoteTooLongError`, `CategoryNameError`, `InvalidCategoryIconError`, `DuplicateCategoryError`,
  `CategoryUnavailableError`, `CategoryNotFoundError`, `ExpenseNotFoundError`, `StorageError`),
  each with a user-facing `message`.
- Domain: `features/expenses/domain/expense.dart` (`Expense` carrying its `Category`,
  `ExpenseDraft`), `features/categories/domain/category.dart` (`Category`, `presetCategories`,
  `userIconKeys`).
- Shared validation, called by the Drift repositories **and** the test fakes:
  `features/expenses/domain/expense_validation.dart` (`validateExpenseDraft`,
  `validateExpenseCategory`, `normalizeNote`), `features/categories/domain/category_validation.dart`
  (`normalizeCategoryName`, `validateNewCategory`, `findCategoryNamed`).
- `lib/data/database/`: `tables.dart`, `app_database.dart` + generated `app_database.g.dart`,
  `local_date_converter.dart`, `db_errors.dart` (`guardDb`, `guardDbStream`, `SqliteConstraint`),
  `database_provider.dart` (`appDatabaseProvider`), `demo_seed.dart` (`seedDemoData`,
  `demoSeederProvider`).
- `build.yaml`: `store_date_time_values_as_text: true`.
- `drift_schemas/drift_schema_v1.json`: v1 snapshot from `dart run drift_dev schema dump`.
- Repositories (contract + provider, Drift implementation):
  `features/expenses/data/{expense_repository,drift_expense_repository}.dart`,
  `features/categories/data/{category_repository,drift_category_repository}.dart`,
  `features/settings/data/{settings_repository,drift_settings_repository}.dart`.
- Settings placeholder: temporary "Load demo data" button, only when `kDebugMode`.
- Fakes: `test/fakes/fake_{expense,category,settings}_repository.dart`, `fake_streams.dart`.
  Each has `failNextWrite` to simulate a failed save.
- Tests: `test/data/{expense_repository,category_repository,settings_repository,
  database_constraints,demo_seed}_test.dart` (+ `data_test_helpers.dart`),
  `test/unit/fake_repositories_test.dart`, `test/widget/settings_demo_button_test.dart`.

### T4 · Expenses page (2026-10-25)

- `lib/shared/selected_month.dart`: `todayProvider` (`TodayNotifier`: a timer at the next local
  midnight plus a refresh on app resume) and `selectedMonthProvider` (`SelectedMonthNotifier` with
  `previous` / `next`, `canGoBack` stops at January 2000, `canGoForward` stops at the current month).
- `lib/shared/widgets/month_switcher.dart` (`MonthSwitcher`), `lib/shared/widgets/empty_state.dart`
  (`EmptyState`).
- `lib/core/calculations/ledger.dart`: `DayGroup`, `sumPesewas`, `filterExpenses`, `groupByDay`,
  `categoryCounts`.
- `lib/core/formatting/dates.dart`: `shortMonthName(month)` (fixed `Jan`…`Dec`, `Sep` for 9),
  `CalendarMonth.shortLabel` (`Oct 2026`, built on `shortMonthName`), `formatDayHeading`
  (`Monday, 19 October`), `ledgerDayLabel`.
- `lib/features/categories/presentation/category_icons.dart`: `categoryIcon(iconKey)` for every
  preset and user icon key.
- `lib/features/expenses/presentation/`: `expenses_providers.dart` (`monthExpensesProvider`,
  `hasAnyExpensesProvider`, `allCategoriesProvider`, `expenseFiltersProvider` with the 200 ms
  debounce, `filterCategoryProvider`, `expensesViewProvider` / `ExpensesView` with the summary and
  no-results copy), `expenses_screen.dart` (rewritten), `expenses_header.dart`,
  `expense_ledger.dart`, `expense_tile.dart`, `category_filter_sheet.dart`,
  `expense_form_screen.dart` (placeholder for T5).
- `lib/app/router.dart`: `AppRoutes.addExpense` (`/expense/new`) and `AppRoutes.editExpense(id)`
  (`/expense/:id`), full-screen dialogs above the shell. A non-numeric id redirects to Expenses.
- `lib/app/theme/app_spacing.dart`: `AppSizes.ledgerRowMinHeight`, `iconTile`, `iconTileGlyph`,
  `ledgerMinTextWidth`, `emptyStateTile`, `emptyStateGlyph`, `fabClearance`.
- Tests: `test/widget/expenses_screen_test.dart`, `test/widget/expense_tile_test.dart` (loads
  IBM Plex Sans for real glyph widths), `test/unit/ledger_test.dart`,
  `test/unit/expenses_state_test.dart`, new label tests in `test/unit/dates_test.dart`. Helpers
  `test/widget/test_app.dart` (`pumpTestApp`: the whole app on fakes with a fixed today of
  21 Oct 2026) and `test/fakes/fixed_today.dart`. `test/widget/app_shell_test.dart` now uses
  `pumpTestApp`, so opening the Expenses tab never opens the real database.

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

- **`Expense` carries its whole `Category`** (joined in the query), so archived categories still
  label old expenses without screens watching a second stream.
- **`update(id, draft)` and `delete(id)` returning the removed `Expense`** for undo; `restore`
  re-inserts with the original id and timestamps, and a second restore is a no-op.
- **Restore uses a plain insert after an existence check**, not `INSERT OR IGNORE`, because OR
  IGNORE also silently skips CHECK violations.
- **An edit may keep an archived category** the expense already has; moving to an archived one
  is rejected (`CategoryUnavailableError`).
- **Lengths counted in code points** (`runes.length`) for notes and category names, matching
  SQLite's `length()`. A 200-emoji note is valid in both layers.
- **Duplicate category names checked in Dart too** (`toLowerCase`), because NOCASE folds ASCII
  only. Lookup, duplicate check and insert run in one transaction.
- **Creating an archived category's name restores it** with its original icon (ARCHITECTURE §7).
- **`archive` works on any category, including presets.** `clearAll` leaves presets exactly as they
  are (archived or not).
- **Timestamps:** written as `clock().toUtc()`, stored as ISO-8601 text, mapped back with
  `.toUtc()`. Repositories take injectable `today` / `clock` functions for tests.
- **Theme mode stored as explicit strings** `system` / `light` / `dark`; unknown or missing is
  `system`.
- **ON DELETE RESTRICT reports extended code 1811** (`SQLITE_CONSTRAINT_TRIGGER`), not 787;
  both are in `SqliteConstraint`.
- **Errors from `watch` streams are translated too** (`guardDbStream`), so a corrupted stored date
  reaches the UI as `StorageError`, not a `FormatException`.
- **Demo seeder** does nothing when any expense exists (so a second tap can't double the data)
  and returns 0 in release builds. Notes are fictional and brand-free.
- **Settings uses Flutter's `ThemeMode`** directly in the repository contract rather than a mirror
  enum.

- Ledger day headers have no year: see DECISIONS.md "Ledger day headers without the year".
- **Short month names come from a fixed list** (`shortMonthName`), so the switcher shows
  "Sep 2026" as the design does, not en_GB's "Sept 2026". See DECISIONS.md "Short month names
  from a fixed list".
- **The header stays fixed and the ledger shrinks.** The header is capped at the available height
  and scrolls inside itself only if it alone is taller than the screen (320dp, text scale 2.0,
  keyboard open).
- **Amounts never shrink beside the text.** When an amount would leave the category and note
  narrower than `AppSizes.ledgerMinTextWidth` (96dp, scaled with the text), `ExpenseTile` moves it
  to its own line under the category, and it scales down only if even that line is too narrow. At
  text scale 1.0, GH₵ 1,000,000.00 stays beside the category from 329dp wide up. The month label
  and day totals scale down only past the point where they would overflow.
- **Filters survive month changes and tab switches** (provider state, not widget state), which
  matches the "Nothing in October 2026…" copy.
- **First use is detected with `watchRecent(limit: 1)`**, so the repository contract is unchanged.
- **Retry is off for the Expenses stream providers** (see DECISIONS.md); the error state has a
  "Try again" button that invalidates them.
- **The filter sheet lists every active category with its count (0 included)**, plus archived
  categories only when that month uses them.
- **`RadioGroup<int?>`**, with null as "All categories", because `RadioListTile.groupValue` is
  deprecated in Flutter 3.47.
- **No double-tap guard on Add expense or row taps.** A second tap 50 ms later is already
  blocked by the route transition (tested). A guard checking `ModalRoute.isCurrent` was tried and
  removed: it didn't stop a second tap in the same frame either, because go_router updates the
  navigator on the next build.

## Known issues / follow-ups

- **Recheck the back button once tabs have nested routes.** The `PopScope` in `AppShell` assumes
  each tab is a single page. Back from the add/edit form now returns to Expenses (tested in T4).
  A tab with its own child route would still need a test.
- **Widget tests render in the Ahem test font by default**, which is much wider than Plex
  (GH₵ 4,800.00 is 180dp in Ahem, 97dp in Plex). Plex can be loaded in a test with `FontLoader`
  and `rootBundle`, as `expense_tile_test.dart` does; a loaded font stays for the rest of that
  file, so tests that need Ahem's stricter widths go in another file.
- **Asserts are debug-only.** `LocalDate(2026, 2, 30)` and `formatGhs(-1)` are caught in
  debug and tests but not in release. Resolved for stored data in T3: the type converter reads via
  `parseIso`. Forms must still build `LocalDate`s from the date picker or validated input.
- **T7: `firstExpenseDate()` is a one-off `Future`.** If the user adds an expense dated before the
  first record while Reports is open, the trend's start month stays stale until Reports reads it
  again. Re-read it when the month's data changes, or add a `watch` variant then.
- **T5: the note and category-name fields must count code points**, not Flutter's default
  grapheme count for `maxLength`, or some emoji input will pass the form and fail the repository.
- **`--delete-conflicting-outputs` is ignored** by the installed build_runner (it prints "These
  options have been removed"). `dart run build_runner build` alone is enough; brief §4 can be
  updated.
- **Debug run not yet tapped on a device** by the agent; a debug APK build was used as the Android
  compile check.
- ~~Day labels need a "today" that refreshes~~: resolved in T4 by `todayProvider` (midnight
  timer plus refresh on resume). The midnight timer itself is not unit-tested; that would need an
  injectable clock.
- **T5:** the edit placeholder accepts any numeric id. The real form must handle an id that no
  longer exists (`ExpenseNotFoundError`).
- **T6:** Home's month row (03) puts the full label left and the arrows right; `MonthSwitcher`
  only has the compact Expenses layout so far.
- **A month change shows the ledger spinner briefly** (milliseconds on a local database), by
  design: the old month's rows are never shown under the new label.
- **Search has no accent folding:** "ecole" does not find "École".
- **Screen-level overflow tests run in Ahem**, which is wider than Plex, so they are stricter
  than a device. Tile layout positions are tested in Plex. Still check 320dp and large text on the
  emulator.
- **T6:** Home's comparison label ("1–21 Sep") must use `shortMonthName`, not a `DateFormat`.
