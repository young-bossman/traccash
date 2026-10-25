# TracCash — Architecture

> Human-readable architecture for TracCash v1. `docs/AGENT_BRIEF.md` holds the same decisions in
> rule form for the coding agent, and `docs/design/DESIGN_SPEC.md` holds the visual and interaction
> spec. If these documents disagree, the brief wins and this file is corrected.

## 1. Purpose

TracCash is an offline-first personal expense tracker for recording and reviewing spending in
Ghana cedis (GHS). It runs entirely on the device; there is no backend in v1.

### Core capabilities

- Create, view, edit and delete expenses, with confirmation and undo for delete.
- Assign each expense to one of 8 preset categories or to a category created from the expense form.
- Record an amount, date, category and optional note.
- **Home:** the month's total, comparison with the previous period, category breakdown, recent expenses.
- **Expenses:** the month's expenses grouped by date, with search and a category filter.
- **Reports:** daily and monthly bar charts, a full category table and the average spend per day.
- **Settings:** System / Light / Dark theme, stored on the device.

Saved data must survive app restarts and must not depend on network access.

### Design principles

1. **Offline-first.** Every feature works without a network connection.
2. **Financial correctness.** Money is integer pesewas; calculations are deterministic and tested.
3. **Separation of concerns.** Widgets render and collect input. They never touch the database or own business rules.
4. **No speculative abstraction.** A layer or interface exists only when it solves a current problem.
5. **Testability.** Money rules, calculations and repositories are tested without the UI.

## 2. Technology decisions

| Concern | Decision | Reason |
| --- | --- | --- |
| Platform | Android first | Shortest route to a tested device build. Layouts stay platform-neutral for a later iOS build. |
| UI | Flutter, Material 3, IBM Plex Sans (bundled) | Standard accessible components; one restrained custom theme. The font is bundled, not fetched, so first launch works offline. |
| State | `flutter_riverpod`, hand-written providers | Testable state and dependency wiring without a DI framework or code generation |
| Persistence | SQLite via `drift` + `drift_flutter` | Typed queries, constraints, migrations, reactive `Stream` queries |
| Navigation | `go_router` | Declarative routes; `StatefulShellRoute` keeps each tab's state |
| Charts | `fl_chart` | Daily and monthly bar charts on Reports |
| Formatting | `intl` + `flutter_localizations`, locale fixed to `en_GB` | GHS formatting; dates read day/month/year as used in Ghana |
| Codegen | `drift_dev` + `build_runner` (dev) | Drift table code only |
| Testing | `flutter_test`, Drift in-memory database, `integration_test` | Fast unit, data and widget tests, plus one restart-persistence test |
| Backend | None in v1 | No auth, hosting or network failure modes |

Dependencies are not added or swapped without a written reason in `docs/DECISIONS.md`.

## 3. Folder structure

Feature-first, with shared code in `app/`, `core/`, `data/` and `shared/`. Folders are created only
when they contain code.

```text
lib/
  main.dart                    # Entry point: ProviderScope + app
  app/
    app.dart                   # MaterialApp.router, themes, theme mode, en_GB locale
    router.dart                # go_router: 4-tab shell + full-screen add/edit route
    theme/                     # Colours, palette extension, type ramp, spacing and radius
  core/
    formatting/                # money.dart (pesewas <-> GHS), dates.dart
    calculations/              # Pure functions: totals, shares, comparison, average, trend, chart scale
    errors/                    # Typed app errors
  data/
    database/                  # Drift tables, AppDatabase (+ generated .g.dart), presets, demo seed
  shared/
    widgets/                   # Widgets used by 2+ features (month switcher, empty state)
  features/
    expenses/
      domain/                  # Expense, ExpenseDraft
      data/                    # ExpenseRepository contract + Drift implementation
      presentation/            # Expenses screen, ledger widgets, add/edit form, controllers
    categories/
      domain/                  # Category
      data/                    # CategoryRepository contract + Drift implementation
      presentation/            # Category icons, picker, new-category panel
    home/presentation/         # Home screen and breakdown widgets
    reports/presentation/      # Reports screen and charts
    settings/
      data/                    # SettingsRepository (theme mode)
      presentation/            # Settings screen
test/
  unit/                        # Money, dates, calculations, colour contrast
  data/                        # Repositories and constraints against NativeDatabase.memory()
  widget/                      # Screens, form validation, main flows
  fakes/                       # Hand-written fake repositories for widget tests
integration_test/              # Add -> restart -> still there
drift_schemas/                 # Schema snapshots for migration tests
docs/
```

### Repository contracts

Each repository is an abstract class with one Drift implementation. The contract earns its place
because widget tests replace it with a small hand-written fake (`test/fakes/`), which keeps them fast
and lets them simulate failures such as a failed save. Data tests exercise the Drift implementation
directly against an in-memory database. No further layers (use cases, services) are added.

## 4. Layers and responsibilities

| Layer | Owns | Must not |
| --- | --- | --- |
| Presentation (screens, widgets) | Rendering, input collection, form-level validation messages, loading/empty/error states, UI-only state (text controllers, open sheets) | Run queries, do money arithmetic, contain business rules in `build()` |
| State (Riverpod providers/controllers) | Coordinating operations, exposing `AsyncValue` state, mapping typed errors to user messages, shared selections such as the selected month | Know SQL or Drift table details |
| Domain (`features/*/domain`, `core/`) | Immutable models, validation rules, calculations, formatting | Import Flutter widgets or Drift |
| Data (repositories, database) | Persistence, mapping rows to domain models, repository-boundary validation, transactions, migrations | Format values for display |

Dependency direction is one way: presentation → state → repository → database. Domain and `core/`
code is plain Dart and can be used by any layer.

### Domain models

`Expense`, `ExpenseDraft` (a new expense with no id yet) and `Category` are immutable: `final`
fields, `copyWith`, value equality. Screens never receive Drift row classes.

### Identity

Records use stable integer primary keys from the database, never list positions. List rows use
`ValueKey(expense.id)`. Undoing a delete restores the same `id` and `created_at`.

## 5. Data flow

### Reading

Screens watch providers. Providers expose repository streams (for example `watchMonth`), backed by
Drift `Stream` queries. When a row changes, Drift re-emits the result and the UI rebuilds. There is no
manual refresh step. One-off reads (for example `getById` for the edit form) return a `Future`.

```text
Screen  --watch-->  Provider  --stream-->  Repository  --query-->  Drift/SQLite
   ^                                                                   |
   +-------------------- new list emitted on any change ---------------+
```

Home, Expenses and Reports share one `selectedMonthProvider`, so changing the month in one place
changes all three.

### Writing (create, edit, delete)

1. The form validates input and parses the amount to pesewas.
2. The controller disables Save (no double submit) and calls the repository, awaiting the result.
3. The repository validates again and writes, in a transaction where more than one row is affected.
4. On success, open streams re-emit; lists, totals and charts update; the form closes and a snackbar confirms.
5. On failure, the controller exposes the error, the form stays open with every value intact, and
   nothing is shown as saved.

Every write is awaited; `unawaited_futures` is an analyzer error. After any `await` in a widget,
`context.mounted` is checked before `context` is used.

## 6. Money rules

### Representation

- All amounts are stored and calculated as `int` pesewas. GH₵12.50 is `1250`.
- `double` is never used for money, including intermediate calculations.
- Values are converted to GHS only for display, through one formatter: `GH₵ 1,500.00`
  (symbol, space, grouped cedis, two pesewa digits). Money text uses tabular figures.
- Limits: minimum GH₵0.01 (1 pesewa); maximum GH₵1,000,000.00 (100,000,000 pesewas) per expense.
  The cap keeps any realistic sum far inside 64-bit integer range.

### Parsing user input

`parsePesewas` returns a result (the value, or a typed error); it never throws for bad input.

| Input | Result |
| --- | --- |
| Surrounding whitespace | Trimmed |
| Empty | Error: required |
| Digits, optionally `.` and 1–2 digits (`25`, `25.5`, `25.50`, `007`) | Accepted; leading zeros allowed |
| Thousands grouping in the cedis part (`1,000`, `1,000.50`, `1,000,000`) | Accepted: first group 1–3 digits not starting with 0, every later group exactly 3 |
| Any other comma (`12,50`, `1,00`, `1000,000`, `1.000,50`, `0,500`) | Error: "Use a dot for pesewas, for example 12.50." Never guessed. |
| More than 2 decimals (`1.234`) | Error: too many decimals |
| Leading or trailing point (`.5`, `12.`), signs, letters, other symbols | Error: invalid format |
| Longer than 20 characters after trimming | Error: invalid format (checked before anything else) |
| More than 7 cedi digits after removing leading zeros (`999999999999`) | Error: at most GH₵ 1,000,000.00 (rejected before integer parsing, so no overflow) |
| Zero (`0`, `0.00`) | Error: must be more than GH₵ 0.00 |
| Over the cap (`1000000.01`) | Error: at most GH₵ 1,000,000.00 |

Algorithm: check the length, validate the shape, remove grouping commas, split on `.`, strip
leading zeros from the cedis as a string (an empty result means 0 cedis; more than 7 digits left
means over the cap), then compute `cedis * 100 + pesewas` with integers (`"5"` after the point means 50 pesewas). Never
`double.parse(x) * 100`: `0.29 * 100` is `28.999…` in floating point.

### Invariants

1. Every stored amount is between 1 and 100,000,000 pesewas.
2. Totals sum integer pesewas, then format once.
3. Editing replaces an amount; it never adds to it.
4. Category totals for a month always sum exactly to that month's total.
5. Displayed category shares always total exactly 100.0% (largest-remainder rounding to tenths of a percent).
6. Summaries are always derived from expenses, never stored.

## 7. Data model

Schema version 1. `created_at` / `updated_at` are UTC instants. `occurred_on` is a calendar date
with no time or time zone. Foreign keys are enabled on every connection (`PRAGMA foreign_keys = ON`
in `beforeOpen`).

### `categories`

| Column | Type | Constraint |
| --- | --- | --- |
| `id` | INTEGER | Primary key, autoincrement |
| `name` | TEXT | Required, trimmed, internal whitespace collapsed, 1–20 characters, unique case-insensitively (`COLLATE NOCASE`) |
| `icon_key` | TEXT | Required; one of a fixed set of keys mapped to Material icons in code |
| `sort_order` | INTEGER | Required; display order (presets first, then user categories by creation) |
| `is_preset` | BOOLEAN | Required; true for the 8 seeded categories |
| `is_archived` | BOOLEAN | Required, default `false` |
| `created_at` | DATETIME | Required, UTC |

**Presets**, seeded in the migration's `onCreate`, in order: Food, Transport, Bills, Data & Airtime,
Shopping, Health, Entertainment, Other.

**User category icons:** Tag (default), Home, Family, Education, Gifts, Fuel, Personal care, Work.

**Category rules**

- Users create a category from the expense form (name + icon). It is selected immediately.
- Duplicate names are rejected ignoring case: "“Food” already exists. Choose it above."
- Creating a name that matches an archived category restores that category instead of creating a duplicate.
- Categories are archived, never deleted (`ON DELETE RESTRICT` on expenses). Archived categories are
  hidden from the picker but still label past expenses and appear in summaries.
- Icons come from the fixed in-app set. Users never enter icon names, and emoji are not used.
- Renaming and archiving from the UI are **not in v1** (planned as a later Settings › Categories
  screen). The repository already supports archiving.

### `expenses`

| Column | Type | Constraint |
| --- | --- | --- |
| `id` | INTEGER | Primary key, autoincrement |
| `amount_pesewas` | INTEGER | Required, `CHECK (amount_pesewas BETWEEN 1 AND 100000000)` |
| `category_id` | INTEGER | Required, foreign key → `categories.id`, `ON DELETE RESTRICT` |
| `occurred_on` | TEXT | Required, ISO date `YYYY-MM-DD`, `CHECK (length(occurred_on) = 10)`, mapped to a date-only value by a type converter |
| `note` | TEXT | Nullable, trimmed, `CHECK (length(note) <= 200)`; empty or whitespace-only input is stored as `NULL` |
| `created_at` | DATETIME | Required, UTC |
| `updated_at` | DATETIME | Required, UTC, set on every update |

Indexes: `expenses(occurred_on)`, `expenses(category_id)`.

`occurred_on` is stored as ISO text because an expense date is a calendar date, not an instant. This
stops an expense moving to a neighbouring day when converted between time zones, and ISO text sorts
chronologically, so range queries work directly.

### `app_settings`

| Column | Type | Constraint |
| --- | --- | --- |
| `key` | TEXT | Primary key |
| `value` | TEXT | Required |

v1 stores one key: `theme_mode` = `system` | `light` | `dark` (default `system` when absent).

### Repository operations

- **ExpenseRepository:** `watchMonth`, `watchRecent`, `watchBetween(from, to)` (inclusive range, for
  the 6-month trend), `firstExpenseDate()` (null when empty), `getById`, `add`, `update`, `delete`,
  `restore` (undo), `clearAll` (debug only).
- **CategoryRepository:** `watchActive`, `watchAll`, `create`, `archive`.
- **SettingsRepository:** `watchThemeMode`, `setThemeMode`.

`clearAll` runs in one transaction. It deletes all expenses and all user-created categories, and
keeps the presets and `app_settings`.

### Generated code

Drift's generated `*.g.dart` files are committed, so a fresh clone builds without a codegen step.
After any table change: `dart run build_runner build --delete-conflicting-outputs`, then commit the
generated file with the change.

### Migrations

- `schemaVersion` starts at 1 and increases by one for every schema change.
- The v1 schema snapshot is exported to `drift_schemas/` so migrations can be tested against it.
- Each change gets a step in Drift's `MigrationStrategy`, with a test that migrates from the previous version.
- Existing migration steps are never edited after release.
- Before release, an upgrade test installs the previous build, adds data, installs the new build over
  it, and checks the data survived.

## 8. Date and reporting rules

- Months use the device's local calendar.
- A month is the half-open range `[first day of month, first day of next month)`.
- Home, Expenses and Reports use the same month query, so their totals cannot disagree.
- Moving an expense to another date updates both months automatically through the streams.
- A month with no expenses shows a zero total and an empty state, not an error.
- **Comparison (Home):** the current month against the same day range of the previous month
  (1–21 Oct vs 1–21 Sep); past months against the full previous month. Hidden when either side is zero.
- **Average per day (Reports):** total ÷ days elapsed (current month) or ÷ days in the month (past
  months), rounded to the nearest pesewa.
- **Trend (Reports):** daily bars for the selected month; monthly bars for up to 6 months, never
  earlier than the first record. The axis maximum rounds up to 1, 2, 2.5 or 5 × 10ⁿ cedis.
- Dates display as `21/10/2026`, `Wednesday, 21 October 2026`, `October 2026`, and Today / Yesterday
  in the ledger.

## 9. Validation and error handling

Validation happens at three layers, each with a different purpose:

| Layer | Catches | Purpose |
| --- | --- | --- |
| Form | Empty, malformed or out-of-range input | Immediate, specific feedback. Errors appear after the first save attempt, then update live. Valid input is never cleared. |
| Repository | Any invalid value, whatever the caller | Protects data from bugs in any caller |
| Database | Constraint violations | Final guarantee that invalid rows are never stored |

Field rules: amount as in §6; category required and not archived; date from 1 January 2000 to today
(future dates rejected; new expenses default to today); note optional, at most 200 characters.

- Repository methods translate low-level database exceptions into typed errors from `core/errors/`.
  Controllers map them to user-facing messages that do not expose internals.
- Exceptions are never silently swallowed; there are no empty `catch` blocks.
- Multi-row operations (seeding, `clearAll`) run in a transaction.
- A missing record (for example, editing an expense deleted elsewhere) is reported, not ignored.
- Every screen handles loading, empty and error states explicitly through `AsyncValue`.

## 10. Security and privacy

- **No sensitive data in logs.** `avoid_print` is an analyzer error. There is no logging framework;
  any diagnostic output uses `debugPrint` inside `kDebugMode` and never includes amounts, notes or records.
- **Android backup.** `android:allowBackup="false"` for v1, so the database is never uploaded to cloud
  backup. This keeps the Settings statement ("stored on this device… does not sync or upload") true.
  Android 12+ device-to-device transfer can still copy app data between the user's own phones; this is
  accepted for v1 and recorded in `DECISIONS.md`. Revisit when export is added.
- **Debug-only tools.** The demo-data seeder, Clear all data and the simulated save failure exist only
  when `kDebugMode` is true. They never ship in release builds.
- **Release builds** use `--obfuscate --split-debug-info=build-symbols/`. Symbols are kept safely
  outside git so production stack traces can be decoded.
- **Signing.** The keystore and `key.properties` are never committed. Both are in `.gitignore`.
- **Permissions.** The app requests no runtime permissions. The `INTERNET` permission exists only in
  the debug and profile manifests, for tooling.
- **Encryption at rest** (SQLCipher) is a v2 option if the threat model requires it.

## 11. Testing strategy

- **Unit:** amount parsing (every row of the §6 table, including comma cases), GHS formatting, date
  handling (month boundaries, December→January, leap years), calculations (category totals reconcile
  with the monthly total, shares total 100.0%, comparison, average, chart scale), colour contrast of
  text/background pairs.
- **Data:** repositories against `NativeDatabase.memory()`: CRUD, restore keeps the same id,
  constraint violations at repository and database level, foreign-key restrict, case-insensitive
  duplicate names, archive behaviour, month and range queries across a year boundary, `clearAll`.
- **Widget:** form validation and save states (including failed save and double tap), discard
  confirmation, list grouping, empty / no-results / first-use states, theme setting.
- **Integration:** add an expense, restart the app, verify it is still there.
- **Manual release checklist:** physical device, airplane mode, restart persistence, full CRUD, light
  and dark themes, large text, upgrade over a previous build.

Before every commit: `dart format --output=none --set-exit-if-changed .`, `flutter analyze` and
`flutter test` must pass. CI runs the same three checks.

## 12. Out of scope for v1

- Accounts, authentication and cloud sync
- Backend API and server-side analytics
- Income, balances, budgets and recurring expenses
- Notifications and home-screen widgets
- Mobile Money SMS ingestion and payment-provider integrations
- CSV import and export
- Multiple users or shared wallets
- Multi-currency
- Category rename / archive UI (planned)
- Database encryption (v2 option)
- iOS build (layouts are ready; not built or tested in v1)

## 13. Change policy

Before adding a dependency, layer or abstraction, record the problem it solves in `docs/DECISIONS.md`.
Changes to money representation, category identity, date storage or the schema need a migration plan
and tests, because they affect existing user data.
