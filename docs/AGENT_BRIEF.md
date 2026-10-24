# TracCash: Standing Brief for the Coding Agent

You are implementing **TracCash**, an offline-first Android expense tracker in Ghana cedis,
built in Flutter. The owner (Bossman) is a senior web engineer (Laravel, SQL, JS) on his first
Flutter app. You write the code; he reviews, runs and commits.

**Work arrives one task card at a time.** Do only the task in the current card. Do not build
ahead, scaffold future pages or "prepare" for later tasks unless the card says so.

## 0. Read at the start of every task

1. `docs/AGENT_BRIEF.md` (this file): rules and decisions. **Wins every conflict.**
2. `docs/PROGRESS.md`: what is already built, decisions made, known issues.
3. `docs/design/DESIGN_SPEC.md`: tokens, components, validation, calculations, interactions.
4. The screenshots in `docs/design/screens/` that the task card names.
5. `docs/ARCHITECTURE.md` and `analysis_options.yaml`.

Project: Flutter app `traccash`, applicationId `io.github.youngbossman.traccash`.

## 1. How every task runs

1. **Plan first, then wait.** Reply with: files you will create/change, the data flow, edge
   cases you will handle, and any risk or question. Then stop until Bossman says **go**.
2. **Implement** only what the card asks.
3. **Verify** by running these and showing the real output. Fix everything before finishing:
   ```
   dart format --output=none --set-exit-if-changed .
   flutter analyze
   flutter test
   ```
   (If formatting fails, run `dart format .` and re-check.) Never claim anything passes
   without having run it.
4. **Self-review** against the eight questions in §6 and fix what you find.
5. **Update `docs/PROGRESS.md`**: tick the task, list files added, record decisions
   (also append real trade-offs to `docs/DECISIONS.md`), list known issues.
6. **Finish with this summary** and stop:
   - Files created/changed (one line each)
   - How to check it by hand on the emulator (3–6 steps, naming the screenshot to compare)
   - The 3 most important Flutter/Dart concepts used, explained for a beginner (2–3 sentences each)
   - 2 questions Bossman should be able to answer about this code
   - Self-review: one line per §6 question
   - Suggested commit message (conventional commits, **no AI attribution or co-author lines**)

## 2. Hard rules

- **Never run git** (no commit, add, branch, stash, reset, checkout). Bossman does all git.
- **Dependencies** only via `flutter pub add` / `flutter pub add --dev`. Only those in §4.
  Ask before adding anything else. `pubspec.lock` is committed.
- **No hex colours, font sizes or magic padding outside `lib/app/theme/`.** Widgets read
  `Theme.of(context)`, the `AppPalette` extension and the spacing/radius constants.
- **No `print`, no logging of expense records, amounts or notes.** Debug logging, if any, uses
  `debugPrint` guarded by `kDebugMode` and contains no user data.
- **No empty `catch` blocks.** Catch at the repository boundary, translate low-level database
  exceptions into typed app errors (`lib/core/errors/`), and let the UI show a friendly message.
- Every database write is awaited. After any `await` in a widget, check `context.mounted`
  before using `context`.
- Dispose every controller, focus node and subscription you create.
- Use `const` constructors where possible. No `dynamic`. Explicit types on public APIs.
- Comments explain *why*, never repeat *what*.
- Keep it simple: no use-case classes, no DI frameworks, no code generation beyond Drift.
  Split a file past ~300 lines by widget, not by pattern.
- Don't add features outside the card or outside v1 scope (§7).

## 3. Architecture and decisions

**Layers.** Presentation (screens, widgets, UI state) → Riverpod providers/controllers →
repository contract → Drift database. Screens never touch Drift types or SQL.

| Topic | Decision |
|---|---|
| Domain models | Immutable classes in `features/<x>/domain/` (`Expense`, `Category`) with `final` fields, `copyWith`, `==`/`hashCode`. Repositories map Drift rows to these. New records use an `ExpenseDraft` (no id yet). |
| Identity | Stable integer primary keys from the database. Never list indexes. Use `ValueKey(expense.id)` for list rows. Undo-delete restores the **same** id and `created_at`. |
| Repository contract | Abstract `ExpenseRepository` / `CategoryRepository` / `SettingsRepository` with meaningful operations (e.g. `watchMonth`, `add`, `update`, `delete`, `restore`). Drift implementations in `data/`. Tests use in-memory Drift (`NativeDatabase.memory()`) for data tests and simple hand-written fakes for widget tests. |
| Validation | Three layers: form messages → repository validation (throws typed errors) → DB CHECK constraints. |
| Money | Integer pesewas everywhere. One parser and one formatter in `core/formatting/money.dart`. Parse by string split, never `double`. Range 1 to 100,000,000 pesewas. **The dot is the only decimal separator.** Commas are accepted only as correct thousands grouping in the cedis part (first group 1–3 digits, every later group exactly 3 digits, no comma after the dot). Anything else, e.g. `12,50`, `1,00`, `1000,000`, is rejected with "Use a dot for pesewas, for example 12.50." Never guess what an ambiguous comma meant. |
| Dates | `occurred_on` stored as `TEXT` `YYYY-MM-DD` (date only), `CHECK(length(occurred_on) = 10)`. Month = `>= 'YYYY-MM-01' AND < next-month-01`, local calendar. `created_at` / `updated_at` are separate timestamps. |
| Locale | App locale fixed to `en_GB` via `flutter_localizations` (`localizationsDelegates` + `supportedLocales`), so the date picker and numeric dates show day/month/year (`21/10/2026`) as used in Ghana. Long dates read "Wednesday, 21 October 2026". |
| Generated code | Drift's generated `*.g.dart` files **are committed**, so a fresh clone builds without running codegen first. Regenerate after every table change and commit the result with it. |
| Derived values | Totals, shares, averages, comparisons, filtered lists are **computed** from expense records (pure functions in `core/calculations/`), never stored. |
| Async state | Screens consume `AsyncValue` (loading / data / error) from Riverpod; "empty" is a data case. No loose boolean flags. Repositories expose Drift `watch` streams for live data; one-off reads use `Future`. No manual refresh after writes. |
| Persistence boundary | Never show "saved" before the write succeeds. On failure the form stays open with values intact. |
| Categories | 8 seeded presets + user-created (DESIGN_SPEC §5b). Names unique case-insensitively (`COLLATE NOCASE`). Archived, never hard-deleted. FK `RESTRICT`. |
| DB | Tables `categories`, `expenses`, `app_settings`. `PRAGMA foreign_keys = ON` in `beforeOpen`. Indexes on `expenses(occurred_on)` and `expenses(category_id)`. `schemaVersion = 1` with a `MigrationStrategy`; export the v1 schema snapshot with drift's tooling so future migrations can be tested. |
| Theme | Explicit `ColorScheme`s from DESIGN_SPEC §1, **not** `fromSeed`. `AppPalette` ThemeExtension. IBM Plex Sans from `assets/fonts/`. No `google_fonts`. |
| Icons | Material outlined icons mapped from an `icon_key` string in one file `features/categories/presentation/category_icons.dart`. No icon package. |
| Theme mode | Stored in `app_settings`, default `system`. |
| State | `flutter_riverpod` with hand-written providers/notifiers. No riverpod codegen. Form text lives in controllers (UI state); expenses live in the database (source of truth). |
| Navigation | `go_router`, `StatefulShellRoute.indexedStack` with Home, Expenses, Reports, Settings. Add/edit form is a full-screen route above the shell. Android back behaves predictably. |
| Lists | Lazy: `ListView.builder` / slivers. Never build all rows eagerly. |
| Android backup | `android:allowBackup="false"`. |
| Demo data | Debug-only seeder (DESIGN_SPEC §9), triggered manually, never in release, never automatic. |
| Clear all data | Debug-only, confirmed. Deletes **all expenses and all user-created categories** in one transaction. The 8 preset categories and the theme setting stay. |
| Repository range queries | `ExpenseRepository` also provides `watchBetween(from, to)` (inclusive date range, used by Reports' 6-month trend) and `firstExpenseDate()` (earliest `occurred_on`, or null when empty). |

## 4. Packages

Runtime: `flutter_riverpod`, `go_router`, `intl`, `fl_chart`, `drift`, `drift_flutter`,
`flutter_localizations` (Flutter SDK: `flutter pub add flutter_localizations --sdk=flutter`).
Dev: `drift_dev`, `build_runner`; later `integration_test` (Flutter SDK) when a card asks.
Codegen: `dart run build_runner build --delete-conflicting-outputs`.

## 5. Folder structure

```
lib/
  main.dart
  app/        app.dart, router.dart, theme/
  core/       formatting/, calculations/, errors/
  data/       database/
  features/
    expenses/   data/ domain/ presentation/
    categories/ data/ domain/ presentation/
    home/       presentation/
    reports/    presentation/
    settings/   data/ presentation/
  shared/widgets/   (only for widgets reused by 2+ features)
test/
  unit/     pure Dart: formatting, calculations
  data/     repositories and constraints against NativeDatabase.memory()
  widget/   screens and flows
  fakes/    hand-written fake repositories shared by widget tests
integration_test/   (T9 only)
docs/
```
Create folders only when real code goes in them.

## 6. Self-review questions (answer each at the end of every task)

1. **Correctness:** can this produce a wrong total, lose an expense or corrupt a date?
2. **Maintainability:** can another developer follow it without asking?
3. **Testability:** is the important behaviour tested without launching the whole app?
4. **Security/privacy:** is input validated at the boundary; can any user data reach logs?
5. **Resilience:** what happens if the write fails, the app closes mid-action, or the button is tapped twice?
6. **Scale:** is it still reasonable with 10,000 expenses?
7. **Accessibility:** contrast, 48dp targets, semantic labels, text scaling, not colour alone?
8. **States:** loading, empty, error, long text and large amounts all handled?

## 7. Out of scope for v1

Accounts, cloud sync, backend, MoMo SMS import, budgets, income, recurring expenses,
multi-currency, export, database encryption, iOS build, widgets, onboarding, notifications.
