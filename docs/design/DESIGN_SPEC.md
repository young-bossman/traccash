# TracCash: Design Spec and Flutter Handoff

Extracted from `TracCash Prototype (1).html` (design system board + Flutter handoff board).
Screen references live in `docs/design/screens/`. When this file and a screenshot disagree,
**this file wins**. When this file and `docs/AGENT_BRIEF.md` disagree, **the brief wins**.

Principle: one accent, neutral surfaces, numbers first. Colour marks interaction, selection
and data. It is never decoration.

---

## 1. Colour tokens

Build both `ColorScheme`s from **explicit values**, not `ColorScheme.fromSeed`, so tokens stay exact.
Tokens Material has no role for go in `ThemeExtension<AppPalette>`.

| Token | Light | Dark | Flutter role | Use |
|---|---|---|---|---|
| bg | `#F5F7FA` | `#101827` | `ColorScheme.surface` | App background |
| surface | `#FFFFFF` | `#182230` | `surfaceContainerLowest` (light) · `AppPalette.card` | Ledger, cards, nav, form |
| surface-2 | `#EEF1F5` | `#202C3C` | `surfaceContainerHigh` | Icon tiles, tracks, dialogs/sheets (dark) |
| border | `#D0D5DD` | `#344054` | `outline` | Field and control outlines |
| divider | `#EAECF0` | `#263244` | `outlineVariant` | Row and section separators |
| text | `#101828` | `#F9FAFB` | `onSurface` | Primary text, amounts |
| text-2 | `#5B6577` | `#AAB4C3` | `onSurfaceVariant` | Secondary text |
| accent | `#0F7B5F` | `#20C997` | `primary` | Primary actions, focus, bars |
| on-accent | `#FFFFFF` | `#101827`* | `onPrimary` | Text on accent |
| accent-tonal | `#E3F4EE` | `#123A30` | `primaryContainer` | Selected fills, nav indicator |
| on-tonal | `#0B5C47` | `#8BE6C8` | `onPrimaryContainer` | Text on tonal |
| error | `#B42318` | `#F97066` | `error` | Validation, destructive |
| error-tonal | derive* | derive* | `errorContainer` | Error banner fill |
| inverse | `#1D2939` | `#E4E7EC` | `inverseSurface` | Snackbar |
| inverse-accent | derive* | derive* | `inversePrimary` | Snackbar action |
| c1 | `#0F7B5F` | `#20C997` | `AppPalette.c1` | Chart ramp 1 |
| c2 | `#3D9A7E` | `#16916E` | `AppPalette.c2` | Chart ramp 2 |
| c3 | `#A3D7C5` | `#0E5A46` | `AppPalette.c3` | Chart ramp 3 |
| c4 | `#C4CAD4` | `#475467` | `AppPalette.c4` | Chart ramp 4 ("other") |
| bar-muted | `#8A94A6` | `#63718A` | `AppPalette.barMuted` | Unselected chart bars |

\* Not specified in the design board. Pick values that meet WCAG AA (4.5:1 for text) against
their background, keep them in the same neutral/teal family, and note the choice in a code comment.

Why light accent is `#0F7B5F`: the brief's `#20C997` is only ~2.1:1 on white. Dark mode keeps
`#20C997` (7.5:1 on `#182230`).

Rule: **widgets read `Theme.of(context)` only. No hex values outside `lib/app/theme/`.**

## 2. Typography

Font: **IBM Plex Sans 400, 500, 600**, bundled as assets (already in `assets/fonts/`, SIL OFL).
Do **not** use the `google_fonts` package (runtime fetching breaks offline first launch).

| Role | Use | Size/line · weight |
|---|---|---|
| displaySmall | Monthly total | 40/48 · w600 · letterSpacing −1 · tabular |
| titleLarge | Screen titles | 22/28 · w600 |
| titleMedium | Form and dialog titles | 18/24 · w600 |
| titleSmall | Section headings | 15/20 · w600 |
| bodyLarge | Row titles and amounts | 15/20 · w500 |
| bodyMedium | Body copy | 14/20 · w400 |
| bodySmall | Meta, notes, helper text | 13/18 · w400 |
| labelLarge | Buttons | 15 · w600 |
| labelSmall | Nav labels 12/16 w500; chart axis 11/14 | |

Every TextStyle that shows money adds `fontFeatures: [FontFeature.tabularFigures()]`.
Money format is always: `GH₵`, a space, grouped cedis, two pesewa digits. Example `GH₵ 1,500.00`.

## 3. Spacing, radius, elevation

Spacing unit 4: `s4` label→value · `s8` grid gaps, chips · `s12` row gap / row vertical padding ·
`s16` container inset · `s20` screen gutter · `s24` dialog padding · `s28` between sections · `s32` major breaks.

Radius: `r8` fields, chips, snackbar · `r12` buttons, tiles, containers · `r16` add button, dialog, sheet · `full` icon buttons, nav pill.

Surfaces separate with **1px borders and dividers**. One shadow level, reserved for floating
layers only: add button, snackbar, dialog, sheet.

## 4. Components

| Component | Flutter building block | Notes |
|---|---|---|
| App shell + bottom nav | `StatefulShellRoute` + `NavigationBar` | Tabs: Home, Expenses, Reports, Settings. 80 high. Labels always shown. Active = tonal indicator + bold label. go_router keeps each tab's stack and scroll. |
| Add expense button | `FloatingActionButton.extended` | Home and Expenses only. Radius 16. |
| Month switcher | `Row(IconButton, Text, IconButton)` | One `selectedMonthProvider` shared by Home, Expenses, Reports. Next disabled at current month. |
| Monthly total | `Text.rich` with two spans | Cedis at displaySmall, pesewas smaller in onSurfaceVariant. Not a card. |
| Category breakdown bar | `Row` of `Expanded(flex: pesewas)` | No chart library. Top 3 categories + "N other categories". Wrap in `Semantics` with a text summary. |
| Ledger row (`ExpenseTile`) | `InkWell` + `Row` | Min height 64, icon tile 40 (neutral surface-2, monochrome icon), amount trailing and never shrinks, note `maxLines: 1` ellipsis. Rows on one continuous surface with inset dividers aligned to the text column (a ledger, not a stack of cards). |
| Date group header | `SliverMainAxisGroup` + `PinnedHeaderSliver` | Today / Yesterday / weekday, day and month without the year ("Monday, 19 October"; the page shows one month), plus the day total. |
| Search field | `TextField` + prefix/suffix icons | Debounce ~200 ms in the provider, not the widget. |
| Category filter | `showModalBottomSheet` + `RadioListTile` | Single choice, with counts for the selected month. |
| Add/edit form | full-screen route (`fullscreenDialog: true`) | `PopScope` guards unsaved changes. Save button lives in `bottomNavigationBar` so it rides above the keyboard. |
| Amount input | `TextFormField`, `numberWithOptions(decimal: true)` | `FilteringTextInputFormatter.allow(RegExp(r"[0-9.,]"))`. Parse to int pesewas, never via double. |
| Category picker | `GridView` (2 columns) of custom options | Selection shown by border weight, fill and a check icon, never colour alone. `Semantics(selected: true)`. Last tile: dashed "+ New category" (see §5b). |
| Date field | read-only field → `showDatePicker(firstDate: 2000-01-01, lastDate: today)` | Shows `21/10/2026` (day/month/year, `en_GB` locale; the prototype's `10/21/2026` is a browser artefact). Helper text under it: "Today · Wednesday, 21 October 2026". Store a date with no time. |
| Daily / monthly trend | `fl_chart` `BarChart` | Touch tooltips off in v1. Axis labels from the same money formatter. |
| Theme setting | `SegmentedButton<ThemeMode>` | System (default), Light, Dark. Persist in the database. |
| Feedback / confirm | `SnackBar` with action · `AlertDialog` | Delete always confirmed, then Undo for the snackbar duration. |
| Buttons | 48 high, radius 12 | Primary = the one committing action per screen. Tonal inside empty states. Text for secondary/dialog actions. Destructive actions are text-only and always confirmed. |

Icons: the prototype uses Lucide outline (1.75 stroke, 20/24 px). See the brief for the icon decision.
Category set: Food, Transport, Bills, Data & Airtime, Shopping, Health, Entertainment, Other.

## 5. Validation and limits

The form shows these messages; the repository enforces the same rules; the Drift table has
CHECK constraints. No layer trusts the one above it.

| Field | Rule |
|---|---|
| Amount | Required. Digits with up to 2 decimals after a **dot** (the only decimal separator). Commas only as correct thousands grouping (`1,000.50` ok; `12,50`, `1,00`, `1000,000` rejected with "Use a dot for pesewas, for example 12.50."). > GH₵ 0.00 and ≤ GH₵ 1,000,000.00 (100,000,000 pesewas). Message example: "Amount must be more than GH₵ 0.00." |
| Parsing | Split on the decimal point, build `cedis * 100 + pesewas` as integers. Never `double.parse(x) * 100` (0.29 × 100 = 28.999…). |
| Category | Required. Archived categories are not selectable but still label old records. |
| Date | Required. 1 Jan 2000 to today. Future dates rejected. Defaults to today for new expenses. |
| Note | Optional, trimmed, ≤ 200 chars. Empty/whitespace-only saves as null. |
| Timing | Errors appear after the first save attempt, then update live. Valid input is never cleared. |
| Duplicates | Save disables the moment it's pressed and stays disabled until the write completes or fails. |
| DB checks | `amount_pesewas > 0 AND <= 100000000`; `length(note) <= 200`; `category_id` FK with RESTRICT. |

### 5b. New category (inline, from the category picker)

Tapping "+ New category" reveals an inline panel inside the form (not a new route):
- **Name**: text field, max 20 chars, placeholder "For example, School fees". Whitespace collapsed and trimmed.
- **Icon**: choose one of: Tag (default), Home, Family, Education, Gifts, Fuel, Personal care, Work.
- Errors: empty → "Enter a category name." · case-insensitive duplicate of any existing category
  (preset or custom) → "“<Existing>” already exists. Choose it above."
- On add: the category is created and immediately selected in the form.
- DB: categories.name unique case-insensitively (`COLLATE NOCASE`), 1–20 chars for user categories.

## 6. Calculation rules

Every figure on screen is derived from expense records. Nothing is typed in as a display value.

| Rule | Definition |
|---|---|
| Month | Records whose `occurred_on` falls in the selected calendar month, local time. |
| Totals | Summed as integer pesewas. Converted to cedis only when formatting. |
| Compare | Current month vs the same day range of the previous month (e.g. 1–21 Oct vs 1–21 Sep). Past months vs the full previous month. Hidden when either side is zero. Copy: "GH₵ 3,257.10 less than 1–21 Sep". |
| Shares | Tenths of a percent with largest-remainder rounding, so shares always total 100.0%. |
| Average | Total ÷ days elapsed (current month) or ÷ days in month (past months), rounded to the nearest pesewa. |
| Trend | Daily bars for the selected month; monthly bars for up to 6 months, never earlier than the first record. Axis max rounds up to 1, 2, 2.5 or 5 × 10ⁿ cedis. |
| Tests | Category totals equal the monthly total; month boundaries; empty months; edits that move a record between months; deletes. |

## 7. Interaction specification

| Action | Result |
|---|---|
| Tap Add expense | Form slides up (200 ms). Amount field focused first. Date defaults to today; no amount or category pre-filled. |
| Save, valid | Button shows "Saving…" and disables. On success the form closes, previous screen and scroll position remain, totals and charts update, snackbar "Expense saved". |
| Save, date outside viewed month | Snackbar "Expense saved to September 2026" with a **View** action that switches the month. |
| Save, invalid | Inline messages under each failing field; nothing else changes. |
| Save, database error | Inline error banner at the top of the form. Form stays open with every value intact. Never show a success message. |
| Close with changes | Discard confirmation: "Keep editing" / "Discard". Close with no changes exits immediately. |
| Tap a ledger row | Opens the edit form prefilled, with a delete action in the app bar. |
| Delete | Confirmation dialog naming amount, category and date. On confirm, record removed and snackbar offers Undo for 5 seconds. |
| Search and filter | Results update as you type. Summary line switches to filtered total and count. "Clear filters" restores the month's full list. |
| Change month | Updates Home, Expenses and Reports together. Data is never modified. |
| Theme | System / Light / Dark. Applies instantly; System follows the device live. |
| Reduced motion | When `MediaQuery.disableAnimations` is true, skip slide and fade transitions. |

## 8. States every screen must cover

Populated list · First use, no data · Empty month · Search with no results · Active category filter ·
Long note (truncated in list, full in form) · Large amounts · Several expenses on one day ·
Validation errors · Local save failure · Save success · Delete confirmation and undo ·
Discard confirmation · Light, dark and system themes · Reports with no data.

## 9. Sample data

41 fictional expenses across all 8 categories, dated 0–75 days back (so Today, Yesterday,
current, previous and earlier months all have records). Includes a long note, a GH₵ 1,500.00 and
a GH₵ 4,800.00 expense, several same-day entries, and records without notes.
Seed **only** behind a debug-only action (e.g. a Settings button visible when `kDebugMode`).
Never in release builds, never as a fallback when the database is empty.

"Clear all data" (debug only, confirmed) deletes all expenses and all user-created categories
in one transaction. Preset categories and the theme setting remain.

## 10. Decisions that differ from the original brief

- Light accent `#0F7B5F` instead of `#20C997` (contrast). Dark keeps `#20C997`.
- IBM Plex Sans instead of Inter.
- Android first; layouts are platform-neutral for a later iOS build.
- Settings reached from the bottom navigation only.
- The Settings line saying records are not uploaded is only true if `android:allowBackup="false"`
  (or backup rules exclude the database). Decided in the brief.
