# TracCash progress

Maintained by the coding agent at the end of every task. Read at the start of every task.

## Tasks

- [x] T1 · Foundation: packages, fonts, theme, app shell
- [x] T2 · Money and date utilities
- [x] T3 · Data layer: models, database, repositories, demo seeder
- [x] T4 · Expenses page
- [x] T5 · Add / edit expense page
- [x] T6 · Home page
- [x] T7 · Reports page
- [x] T8 · Settings page
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

### T5 · Add / edit expense page (2026-10-25)

- Dependency: `characters` added with `flutter pub add characters` (it ships with Flutter and was
  already in `pubspec.lock` as a transitive dependency). `lib/` reaches it through
  `flutter/material.dart`, which re-exports it (a direct import there is flagged
  `unnecessary_import`); `test/unit/rune_length_limit_test.dart` imports it directly.
- `lib/features/expenses/presentation/`: `expense_form_screen.dart` (rewritten: add, or load the
  stored expense with loading / not found / error states), `expense_form.dart` (`ExpenseForm`:
  state, save, delete, discard), `expense_form_validation.dart` (pure: `ExpenseFormValues` with
  `differsFrom`, `validateExpenseForm` returning `ValidExpenseForm` / `InvalidExpenseForm`),
  `amount_field.dart` (`AmountField`), `expense_form_fields.dart` (`ExpenseDateField`, `NoteField`,
  `SaveBar`, `SaveErrorBanner`), `expense_category_field.dart` (`ExpenseCategoryField`),
  `expense_form_dialogs.dart` (`confirmDiscard`, `confirmDelete`, `showSavedSnackBar`,
  `showDeletedSnackBar`, `snackBarActionWindow`, `dialogAnimation`), `expenses_providers.dart`
  (+ `expenseByIdProvider`).
- `lib/features/categories/presentation/`: `category_picker.dart` (`CategoryPicker`,
  `OptionSurface`, dashed "New category" option), `new_category_panel.dart` (`NewCategoryPanel`),
  `category_icons.dart` (+ `userIconLabel`).
- `lib/shared/rune_length_limit.dart` (`RuneLengthLimitingTextInputFormatter`, `runeCounter`),
  `lib/shared/widgets/form_field_text.dart` (`FieldLabel`, `FieldError`).
- `lib/shared/selected_month.dart`: `SelectedMonthNotifier.show(month)`, clamped to January 2000 to
  the current month.
- `lib/core/formatting/money.dart`: `formatPesewasForInput` (`4800.00`). `dates.dart`:
  `LocalDate.toLocalDateTime`, `formatDayAndMonth` (`21 October` / `21 October 2025`),
  `dateFieldHelper` (`Today · Wednesday, 21 October 2026`).
- `lib/app/router.dart`: both form routes use `_formPage`, a `CustomTransitionPage` sliding up over
  200 ms (`AppMotion.formSlide`), with no transition under reduced motion, ignoring taps while it
  slides in. `lib/app/app_shell.dart`: owns the Add expense button (Expenses tab only for now).
  `expenses_screen.dart`: its own button removed.
- `lib/app/theme/app_motion.dart` (new), `app_spacing.dart` (+ `categoryOptionMinHeight`,
  `selectedBorder`, `amountUnderline`, `dash`, `dashGap`, `inlineIcon`).
- Fakes: `FakeExpenseRepository` gains `addCalls`, `updateCalls` and `writeGate` (a `Completer`
  that holds `add` / `update` / `delete` open).
- Tests: `test/widget/expense_form_test.dart`, `expense_edit_test.dart`,
  `new_category_panel_test.dart`, helpers `form_test_helpers.dart`;
  `test/unit/expense_form_validation_test.dart`, `rune_length_limit_test.dart`; new cases in
  `money_test.dart`, `dates_test.dart`, `expenses_state_test.dart`. No T4 test needed changing.
- Follow-up after review: the date field opens `DatePickerDialog` through `showDialog` with
  `dialogAnimation` (no fade under reduced motion), replacing `showDatePicker`. Same range and
  initial-date clamp. Tests "the date picker fades in" and "reduced motion: the date picker opens
  with no fade" in `expense_form_test.dart`.

### T6 · Home page (2026-10-25)

- `lib/core/calculations/breakdown.dart`: `CategoryTotal`, `categoryTotals` (largest first, ties in
  display order), `shareTenths` (largest-remainder tenths of a percent, always 1000),
  `BreakdownSlice`, `breakdownSlices` (top 3 named, the rest grouped; exactly 4 are all named),
  `largestCategories` (every category tied for the top).
- `lib/core/calculations/comparison.dart`: `DateRange`, `comparisonRange` (same days of the
  previous month for the current month, capped at that month's length; the whole previous month
  for a past month), `SpendingChange`, `Comparison`, `compareTotals` (null when either side is 0).
- `lib/core/formatting/percent.dart`: `formatShare` (`33.2%`). `dates.dart`: `formatDayRange`
  (`1–21 Sep`, `1 Sep`), `shortDayLabel` (`Today` / `Yesterday` / `19 Oct`).
- `lib/features/home/presentation/`: `home_providers.dart` (`comparisonRangeProvider`,
  `previousPeriodTotalProvider`, `HomeView` with `HomeView.of` deriving every figure and string,
  `homeViewProvider`), `home_screen.dart` (rewritten: header, month row, loading / error /
  first use / empty month / data), `home_total.dart`, `home_breakdown.dart`, `home_recent.dart`,
  `home_section.dart` (`HomeSectionHeading`, `HomeCard`).
- Moved `ExpenseTile` to `lib/shared/widgets/expense_tile.dart` (Home and Expenses both use it),
  with an optional `dateLabel` after the note ("Waakye and egg, lunch · Today"). Its padding and
  gap are named constants that both the stacking rule and the divider inset use.
- `lib/shared/text_measure.dart`: `singleLineWidth`, `scaledMinTextWidth` (moved out of
  `ExpenseTile`; the legend rows use the same 96dp rule).
- `lib/shared/widgets/empty_state.dart`: `FirstUseState`, `EmptyMonthState`, `LoadErrorState`, so
  Home and Expenses word them alike; `expenses_screen.dart` uses them.
- `lib/shared/widgets/month_switcher.dart`: `MonthSwitcher.spread()` (full label at the start,
  arrows at the end).
- `lib/app/app_shell.dart`: the Add expense button shows on Home too.
- `expenses_providers.dart`: `_noRetry` is now the public `noRetry`, shared with Home.
- Theme: `AppTypography.totalMinor`; `AppSizes.logoTile`, `logoGlyph`, `breakdownBarHeight`,
  `breakdownBarGap`, `legendSwatch`; `AppRadius.swatch`.
- Tests: `test/unit/breakdown_test.dart`, `comparison_test.dart`, `percent_test.dart`,
  `home_state_test.dart`, new cases in `dates_test.dart`; `test/widget/home_screen_test.dart`,
  `home_layout_test.dart` (Plex), date-subtitle cases in `expense_tile_test.dart`. Helpers
  `test/widget/home_seed.dart` (the 01 month), `plex_font.dart` (shared `loadPlex`); `PresetIds`
  gains shopping, entertainment, other.
- Follow-up after review:
  - `expenses_header.dart`: the title / month switcher `Wrap` sits in
    `SizedBox(width: double.infinity)`. Under the header's `Column(crossAxisAlignment: start)` it
    had shrunk to its children, so `spaceBetween` left the switcher right after the title instead
    of at the right edge (04, 05, 06, 13). It still wraps below the title at large text. Test:
    `test/widget/expenses_layout_test.dart` (Plex).
  - `EmptyMonthState` (Home and Expenses) watches `todayProvider`: "Nothing recorded so far this
    month." for the current month, "Nothing was recorded that month." for a past one. Tests in
    `home_screen_test.dart` and `expenses_screen_test.dart`.
  - Home's single-category sentence: "Food is all the spending this month." / "Food is all the
    spending in September 2026." Tests in `home_state_test.dart` and `home_screen_test.dart`.
  - `category_filter_sheet.dart`: the class comment says "the selected month".

### T7 · Reports page (2026-10-25)

- Calculations, written test-first: `lib/core/calculations/average.dart` (`averagePerDayPesewas`),
  `trend.dart` (`trendMonthCount`, `dailyTotals`, `trendWindowStart`, `trendMonths`,
  `monthlyTotals`), `chart_scale.dart` (`chartAxisMaxPesewas`, `chartAxisIntervalPesewas`).
  `breakdown.dart`: `CategoryTotal.expenseCount`.
- Formatting: `money.dart` `formatGhsAxis` (`GH₵ 2,500`, or `GH₵ 1.25` when not whole cedis);
  `dates.dart` `CalendarMonth.name` (`October`); new `lists.dart` `joinWithAnd` (Home's private
  `_joinNames`, now shared).
- `lib/features/reports/presentation/`: `reports_providers.dart` (`trendPeriodProvider`,
  `trendExpensesProvider`, `firstExpenseDateProvider`, `CategoryShare`, `MonthlyTrend`,
  `ReportsView`, `reportsViewProvider`), `reports_screen.dart` (rewritten: header, loading, error,
  no data, body), `reports_summary.dart` (`ReportsTotal`, `ReportsStats`, `LargestCategoryCard`),
  `reports_categories.dart` (`ReportsCategories`), `reports_trend.dart` (`ReportsTrend`, the
  `BarChart`). The no-data state is a private widget in `reports_screen.dart` rather than the
  planned `reports_empty.dart`.
- Mechanical moves, no behaviour change, no existing test edited: `HomeCard` →
  `lib/shared/widgets/section_card.dart` `SectionCard`; Home's `_TotalAmount` →
  `lib/shared/widgets/total_amount.dart` `TotalAmount`; the title + month switcher `Wrap` from
  `expenses_header.dart` → `TitleWithMonthSwitcher` in `month_switcher.dart`;
  `comparisonRangeProvider` and `previousPeriodTotalProvider` from `home_providers.dart` →
  `expenses_providers.dart`.
- `lib/shared/text_measure.dart`: `singleLineHeight`.
- Theme: `AppSizes.trendChartHeight`, `dailyBarMaxWidth`, `monthlyBarWidth`, `barSlotFill`,
  `chartGridLine`, `chartAxisMaxShare`, `shareBarHeight`; `AppRadius.chartBar`;
  `AppMotion.chartUpdate`.
- Not changed: `expense_repository.dart`, `drift_expense_repository.dart`, `test/fakes/`,
  `lib/data/database/`.
- Tests: `test/unit/average_test.dart`, `trend_test.dart`, `chart_scale_test.dart`,
  `reports_state_test.dart`, `lists_test.dart`, a `CalendarMonth.name` case in `dates_test.dart`;
  `test/widget/reports_screen_test.dart` (Ahem), `reports_layout_test.dart` (Plex).

### T8 · Settings page (2026-10-25)

- Dependency: `package_info_plus` added with `flutter pub add package_info_plus` (approved by
  Bossman) for the Version row. New `pubspec.lock` entries: `package_info_plus` 10.2.2,
  `package_info_plus_platform_interface` 4.1.0, and for other platforms `http` 1.6.0, `win32` 6.4.0
  and `ffi_leak_tracker` 0.1.2. The plugin's Android manifest adds no permission.
- `lib/features/settings/presentation/`:
  - `settings_screen.dart`: rewritten. `showDeveloper` defaults to `kDebugMode`.
  - `settings_providers.dart`: `themeModeProvider`, `appVersionProvider` (`0.1.0 (1)`) and
    `readInitialThemeMode`.
  - One file per section: `settings_appearance.dart` (`AppearanceSection`), `settings_general.dart`
    (`GeneralSection`) and `settings_developer.dart` (`DeveloperSection`).
  - `settings_row.dart`: `SettingsHeading` and `SettingsRow`.
  - The planned single `settings_sections.dart` would have passed 300 lines, so it was split by
    widget.
- `lib/data/database/simulated_failure.dart`: `failNextWriteProvider` (`FailNextWriteNotifier` with
  `set` / `take`), `simulatedFailureHook(ref, {debug})` and `throwIfSimulated`.
- The Drift repositories take an optional `simulatedFailure` hook.
  - It is checked after validation and before each write: expenses `add`, `update`, `delete`,
    `restore` and `clearAll`; categories `create` and `archive`; settings `setThemeMode`.
  - Their providers pass `simulatedFailureHook(ref)`, which is null in release builds.
  - The constructors use Dart 3.13's private named parameters (`this._simulatedFailure`), as
    `prefer_initializing_formals` asks; callers still write `simulatedFailure:`.
- `lib/app/app.dart`:
  - `TracCashApp(initialThemeMode)`.
  - `themeMode` comes from `themeModeProvider`, falling back to `initialThemeMode`.
  - `themeAnimationStyle: AnimationStyle.noAnimation`.
- `lib/main.dart`: `WidgetsFlutterBinding.ensureInitialized()`, then a `ProviderContainer` and
  `readInitialThemeMode` before `runApp` with `UncontrolledProviderScope`.
- Theme:
  - `segmentedButtonTheme`: r12, labelLarge, tonal selection, drawn 48dp through padding, no extra
    tap padding.
  - `AppSizes.segmentVerticalPadding` and `AppSizes.segmentChrome`.
- Mechanical moves, with no behaviour change and no existing test changed:
  - `dialogAnimation` and the snackbar helper (`_show`, now `showReplacingSnackBar`):
    `expense_form_dialogs.dart` → `lib/shared/reduced_motion.dart`.
  - `_DashedBorderPainter`: `category_picker.dart` → `lib/shared/widgets/dashed_border.dart`
    (`DashedBorderPainter`).
  - `ExpenseTile`'s `_IconTile` → `lib/shared/widgets/icon_tile.dart` (`IconTile`). This fourth move
    wasn't in the reviewed list; Settings' rows use the same tile.
- Fakes: each fake repository takes `simulatedFailure`, checked after its own `failNextWrite`.
- `test/widget/test_app.dart`:
  - `TestApp.settings`.
  - `pumpTestApp` gains `themeMode`, `settingsRepository`, `appVersion` and `overrides`.
  - It always overrides `appVersionProvider` with `testAppVersion` (`0.1.0 (1)`) and wires the
    default fakes to `failNextWriteProvider`.
  - It now seeds after creating the container, still before the first frame.
- Tests:
  - New: `test/widget/settings_screen_test.dart` (Ahem), `settings_layout_test.dart` (Plex),
    `initial_theme_mode_test.dart` and `test/data/simulated_failure_test.dart`.
  - Removed `test/widget/settings_demo_button_test.dart`; its three cases are now in
    `settings_screen_test.dart`.

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

- **Add expense button lives in `AppShell`** (Expenses tab only until T6 adds Home): snackbars show
  in the outermost Scaffold only, and only that Scaffold lifts its own button above them. See
  DECISIONS.md.
- **Hard length limits counted in code points**, with an `N / 200` (`N / 20`) counter. Typing at
  the limit is ignored and a paste is cut at the limit, keeping whole characters. See DECISIONS.md.
- **Form state lives in the widget's `State`**, not a Riverpod controller: text in controllers;
  category, date, "Save pressed" and the write in progress (`_Write.save` / `_Write.delete`) in
  fields. The double-submit guard checks that field synchronously, so two taps in one frame still
  write once. Widgets reach the repository through `ref.read(expenseRepositoryProvider)`.
- **Messages after the first Save, then live**, for all four fields and the new-category panel.
  On an invalid Save the first failing field scrolls into view if it is above the screen
  (`keepVisibleAtStart`); nothing scrolls if it is visible.
- **"Has changes" compares what would be saved**: `12.5` and `12.50` are the same amount, spaces
  around a note don't count; invalid amounts compare as trimmed text. A name typed in the open
  new-category panel also counts.
- **Back during a write is ignored** (no dialog); local writes take milliseconds.
- **Error banner**: title "Couldn’t save this expense" for every failed save or delete; body is
  the screenshot's copy for `StorageError` (and anything unexpected), otherwise the `AppError`'s
  own message. Non-`AppError` exceptions also show the banner and are rethrown, so a bug is
  reported rather than swallowed.
- **Snackbars**: the current one is hidden before a new one shows. Undo and View last 5 s, but
  stay up until dismissed or actioned while a screen reader is on (`persist` is
  `MediaQuery.accessibleNavigationOf`, read before the form closes).
  Everything the actions need (messenger, repository, month notifier) is read before the form
  closes; the actions never use the form's `ref` or `context`. "Couldn’t restore the expense." if
  Undo fails (my wording, not in spec).
- **View only sets the selected month**; the user stays on the current tab.
- **Delete dialog names the stored record**, not unsaved edits, with the year only outside the
  current year. Delete does not ask about unsaved edits first; deleting discards them.
- **Edit form**: amount prefilled with `formatPesewasForInput` (no grouping), not focused. The
  expense's own category stays in the picker even if it was archived since.
- **Missing id** (deleted elsewhere): "Expense not found" / "This expense no longer exists." with
  Close. Not in spec.
- **The form route ignores taps while it slides in**: a route takes pointer events during its
  entrance, so the second tap of a double tap on Add expense would otherwise select whatever
  category passed under the finger.
- **Opening the new-category panel focuses its name** with an explicit `requestFocus`;
  `autofocus` yields to the amount field, which usually already has focus.
- **Category options are rows of two equal-height options**, not a fixed-extent `GridView`, so
  they grow with the text scale instead of clipping labels.
- **The amount row is a bare TextField beside a "GH₵" Text on one baseline**, with its own
  underline: an `InputDecoration` prefix is hidden while the field is empty and unfocused.
- **Field labels and their fields are merged for screen readers** (`MergeSemantics`), so the
  amount field reads as "Amount" rather than its hint.
- **The date picker is `showDialog` + `DatePickerDialog`**, because `showDatePicker` takes no
  animation setting. Every form motion (route, dialogs, date picker, snackbars, scrolling to an
  error) is now skipped under reduced motion. See DECISIONS.md.
- **An edit says "Changes saved"** ("Changes saved to September 2026" with View); adding says
  "Expense saved". Deviates from the card. See DECISIONS.md.

- **Home reuses Expenses' `monthExpensesProvider`**, so both tabs total the same list for the same
  month and can't disagree.
- **Recent is the selected month's 5 latest**, with the date after the note (`Today`,
  `Yesterday`, `19 Oct`). See DECISIONS.md.
- **With exactly 4 categories the fourth is named**; 5 or more group from the fourth. Beyond the
  spec. See DECISIONS.md.
- **Shares are rounded across all categories**; the grouped row's share is the sum of its
  members'. A test checks each named share equals `shareTenths` over all categories, the value
  T7's table will use. See DECISIONS.md.
- **A tie for the largest share names every tied category with the amount**, not a percentage.
  See DECISIONS.md.
- **The compare line's current side is the headline total**, so the difference always reconciles
  with the big number. Past months use "1–31 Aug" for the whole previous month.
- **Only the month stream's failure is an error.** If just the earlier period fails, the compare
  line is hidden and the rest shows. See DECISIONS.md.
- **Loading waits for the comparison too**, so the line never pops in a moment after the total.
- **The total's Semantics label is the whole amount** (`GH₵ 2,313.90`), even when the figure is
  scaled down to fit.
- **The bar is shapes only** (`Row` of `Expanded(flex: pesewas)`), with a text summary for screen
  readers; the legend names and sizes every slice. A fourth named category uses c4.
- **Legend shares sit in a column as wide as "100.0%"**, so amounts line up. When the figures
  would leave a name under 96dp (scaled), they move under the name.
- **Section headings use a `Wrap` with a fixed width** (the stretched column), so the link sits at
  the end and wraps under the title at large text.
- Copy not found in DESIGN_SPEC or the screenshots (my wording unless noted): "Spent in September
  2026"; "GH₵ X more than 1–21 Sep"; "Same as 1–21 Sep"; "1–31 Aug" for past months (format chosen
  by Bossman); "Bills is the largest share of September 2026, at 33.2%."; "Food and Transport share
  the largest amount, GH₵ 50.00 each." ("Food and Transport share…" from Bossman, the rest mine);
  "19 Oct" after a note in Recent; the bar's summary "Bills 33.2%, Shopping 25.0%, …". Chosen
  after review (DECISIONS.md): "Food is all the spending this month." / "Food is all the spending
  in September 2026."; "Nothing recorded so far this month." / "Nothing was recorded that month."
  (replacing T4's "Nothing was recorded for this month."). Reused from T4: "No expenses in
  October 2026", "Couldn’t load expenses", "Try again", "Loading expenses".

- **Reports lays out as 10 and 11**, with the trend below By category (Bossman): header, total,
  stats row, Largest category, By category, Spending trend.
- **The comparison stat uses signs** (`+GH₵ 1,234.00`, `−GH₵ 3,257.10`, `GH₵ 0.00`, `No data`), read
  in words by screen readers. Past months show `vs Aug 2026`. See DECISIONS.md.
- **If the compared days can't be read, the stat is left out** rather than showing "No data", which
  would claim there is nothing to compare. Same rule as Home's compare line.
- **Only the monthly chart shows a trend failure.** The month's own figures, the daily chart and the
  table don't depend on the 6-month read.
- **Daily bars are all accent; Monthly marks the selected month** in accent with a w600 label, earlier
  months in bar-muted (Bossman, from the prototype). Days or months with nothing have no bar.
- **The trend toggle is provider state**, because a month change rebuilds the page through the
  spinner and would reset widget state. It survives month changes and tab switches; it resets on
  restart.
- **`firstExpenseDate` is read again whenever the trend's stream emits.** See DECISIONS.md.
- **Stats columns are sized to their content**, with spare width shared equally, and stack one per
  line when they don't fit. See DECISIONS.md. In Plex at text scale 1.0 they share one line from
  360dp up.
- **Chart money labels take at most 40% of the chart's width** and shrink past that. See
  DECISIONS.md.
- **The average divides a month after today by all its days.** That only happens if the device
  clock is set back; it was an assert, which would have shown Reports' error state in debug.
- **The chart is redrawn without a cross-fade when switching Daily / Monthly** (each has its own
  key), so 31 bars never morph into 6. Bars animate to new totals over 150 ms (fl_chart's default),
  and not at all under reduced motion.
- Copy in neither the screenshots nor the card (my wording): "Largest categories" with "each" under
  the amount on a tie, and a neutral `leaderboard_outlined` icon in the tile; the daily summary on a
  tie, "Highest days: 5 October and 8 October, GH₵ 450.00 each."; the past-year day in a summary
  ("9 March 2025"); the spoken period for a past month, "GH₵ 571.00 more than August 2026" (full
  month name, where the label shows "vs Aug 2026"). Reused from T4: "Couldn’t load expenses",
  "Try again" and "Loading expenses" for Reports' error, trend error and loading states.

- **The theme selection is always the stored value.**
  - A tap writes the choice, and the segments change when the database stream confirms it.
  - A failed write leaves them as they were and shows "Couldn’t save your theme choice. Try
    again."
  - Rapid taps write in order, so the last one wins.
- **The stored theme is read before the first frame** (`readInitialThemeMode`, waiting at most
  1 second). If the read times out or fails, the app follows the device until the value arrives.
  See DECISIONS.md.
- **Theme changes have no cross-fade** (`AnimationStyle.noAnimation`): "applies instantly" in
  DESIGN_SPEC §7, and it also covers reduced motion.
- **If the theme can't be read**, no segment is selected and the error replaces the helper text.
  Choosing a mode still saves.
- **The theme choices stack when a label won't fit on one line** beside the check icon in a third
  of the width.
  - The rule uses `AppSizes.segmentChrome`, which matches Flutter's segment padding.
  - In Plex they share one row from 358dp at text scale 1.0 and from 404dp at 1.3, so 320dp
    stacks them.
- **Segments are drawn 48dp high**, as in the design. Flutter ignores `minimumSize` for segments.
- **Settings rows:** a row with an icon keeps the icon beside the title, as in "Stored on this
  device"; a row without one centres its switch. The Version value wraps under its title at large
  text. Each row reads as one item to screen readers.
- **"Fail the next save" covers every repository write** (expenses, categories, theme), as
  decided by Bossman.
  - The demo seeder writes through the database directly, so it ignores the switch.
  - The switch turns itself off when a write takes the failure, and it resets on restart.
  - Validation runs first, so an invalid save leaves it on. Reads are never failed.
  - See DECISIONS.md.
- **Clear all data resets the Expenses category filter** after it succeeds; otherwise a filter on
  a deleted category would hide every new expense with no chip to show why. The search text is
  left alone because it lives in the Expenses screen's controller.
- **The Developer section shows only when `showDeveloper` is set**, which defaults to `kDebugMode`.
  Release builds also get a null failure hook, and the seeder returns 0 outside debug.
- **Riverpod 3 pauses hidden widgets:** a Settings tab under the form or another tab redraws the
  switch when it is shown again. Tests check it after returning to Settings.
- **The startup tests use `testWidgets`' fake clock** rather than `fakeAsync`. `fake_async` is only
  a transitive dependency, and importing it directly would need a dev dependency (to ask about).
- Copy not in DESIGN_SPEC or 16-settings.png (my wording):
  - The Developer section: "Developer", "Debug builds only. Not in the release app.", "Adds sample
    expenses when there are none yet.", "Deletes every expense and every category you created."
    ("Load demo data", "Clear all data" and "Fail the next save" come from the card;
    "Simulates a local database error once." from the screenshot.)
  - The Clear all dialog: "Clear all data?", "Every expense and every category you created will
    be deleted. The 8 preset categories and your theme setting stay. This can’t be undone.",
    "Cancel" and "Clear".
  - "Cleared every expense and the categories you created."
  - "Couldn’t save your theme choice. Try again." and "Couldn’t load your theme choice, so
    TracCash is following your device."
  - "Not available" for the version.
  - Reused from T3: "Loaded 41 demo expenses.", "Demo data not loaded: there are already
    expenses." and the `StorageError` message.

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
- ~~T7: `firstExpenseDate()` is a one-off `Future`~~: resolved in T7 by reading it again whenever
  the trend's stream emits (relies on Drift; see DECISIONS.md).
- ~~T5: the note and category-name fields must count code points~~: resolved in T5 by
  `RuneLengthLimitingTextInputFormatter`.
- **`--delete-conflicting-outputs` is ignored** by the installed build_runner (it prints "These
  options have been removed"). `dart run build_runner build` alone is enough; brief §4 can be
  updated.
- **Debug run not yet tapped on a device** by the agent; a debug APK build was used as the Android
  compile check.
- ~~Day labels need a "today" that refreshes~~: resolved in T4 by `todayProvider` (midnight
  timer plus refresh on resume). The midnight timer itself is not unit-tested; that would need an
  injectable clock.
- ~~T5: the edit placeholder accepts any numeric id~~: resolved in T5. A missing id shows "This
  expense no longer exists."; deleted while open, Save shows that message in the banner.
- ~~T6: Home's month row needs the full label left and the arrows right~~: resolved in T6 by
  `MonthSwitcher.spread()`.
- **A month change shows the ledger spinner briefly** (milliseconds on a local database), by
  design: the old month's rows are never shown under the new label.
- **Search has no accent folding:** "ecole" does not find "École".
- **Screen-level overflow tests run in Ahem**, which is wider than Plex, so they are stricter
  than a device. Tile layout positions are tested in Plex. Still check 320dp and large text on the
  emulator.
- ~~T6: Home's comparison label must use `shortMonthName`~~: resolved in T6 by `formatDayRange`.
- ~~T6: add Home to the tabs that show the Add expense button~~: resolved in T6.
- **A category created in the panel stays** if the expense is then discarded (§5b creates it on
  Add).
- **The rune limit cuts from the end, like Flutter's `maxLength`:** pasting into the middle of an
  almost full note keeps the paste and drops the note's last characters.
- **`expense_form.dart` is ~350 lines**: one `State` whose save, delete and discard flows all
  change its fields. The amount, date, note and category sections are already separate widgets;
  splitting further would be by pattern.
- **A very large amount at large text scrolls sideways** inside the amount field rather than
  shrinking.
- **Not yet tapped on a device by the agent**: checked with widget tests and a debug APK build.
- **Home's compare line has no retry of its own.** If only the earlier period fails, the line stays
  hidden until the month or day changes (decided: hide rather than show an error).
- **"Reports" and "View all" text sits a button's padding in from the gutter** (the button's right
  edge is on the gutter); the design puts the text itself on the gutter.
- **Breakdown bar colours are decorative, not AA graphics:** light c3 (`#A3D7C5`) on the
  background is well under 3:1. Every slice is named with its amount and share in the legend and
  in the bar's Semantics summary, so nothing depends on the colour.
- **View all keeps any active Expenses filter** (decided); the chip on Expenses shows it.
- **Home not yet tapped on a device by the agent**: checked with widget tests (Ahem and Plex).
- **Reports not yet tapped on a device by the agent**: checked with widget tests (Ahem and Plex).
- **Try again on a trend-only failure reloads the whole Reports page** (spinner, then the page
  again, scrolled to the top). Rare: the 6-month read failing while the month's own read works.
- **The selected month's monthly bar and the headline total come from two streams.** After a write
  both update, but not in the same frame, so for a few milliseconds they can differ.
- **Monthly x labels have no year** ("Dec", "Jan", "Feb" across a year boundary); the screen reader
  summary adds years in that case.
- **The Android launch screen follows the device, not the app's theme.** `values-night/styles.xml`
  picks the native splash, so with Dark chosen on a light phone the splash is light for a moment
  before the first (dark) frame. Native launch theming is outside T8.
- **Settings not yet tapped on a device by the agent**: checked with widget tests (Ahem and Plex)
  and rendered images compared with 16-settings.png.
- **The Android build with `package_info_plus` is unverified.** `flutter build apk --debug` failed
  before compiling anything. The plugin's build script asks Gradle for AGP 8.12.1 (the app uses
  9.1.0, which is cached), and downloading it failed on this machine with
  `PKIX path building failed`: Java doesn't trust the certificate it gets for `dl.google.com`.
  That usually means antivirus HTTPS scanning or a proxy. It failed the same way inside and outside
  the agent's sandbox. Run the build once the machine can reach Google's Maven repository.
- **Version reads "0.1.0 (1)" until T10** bumps `version:` in `pubspec.yaml`. The screenshot
  shows 1.0.0 (1).
- **`AppSizes.segmentChrome` mirrors Flutter's segment padding** (12 + 16, the 18dp check and
  an 8dp gap). Recheck it after a Flutter upgrade; `settings_layout_test` catches a label that
  breaks.
- ~~`watchValue` hung widget tests that awaited `.first`~~: fixed after T7, along with
  `FakeExpenseRepository.dispose()`. Both awaited Dart's root-zone completed future, which resumed
  the test outside its fake async zone (T7's note blamed `close()`; that was wrong). Covered by
  `fake_repositories_test.dart`.
