import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traccash/app/theme/app_motion.dart';
import 'package:traccash/app/theme/app_palette.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/core/formatting/money.dart';
import 'package:traccash/features/categories/domain/category.dart';
import 'package:traccash/features/expenses/data/expense_repository.dart';
import 'package:traccash/features/expenses/domain/expense.dart';
import 'package:traccash/features/expenses/presentation/amount_field.dart';
import 'package:traccash/features/expenses/presentation/expense_category_field.dart';
import 'package:traccash/features/expenses/presentation/expense_form_dialogs.dart';
import 'package:traccash/features/expenses/presentation/expense_form_fields.dart';
import 'package:traccash/features/expenses/presentation/expense_form_validation.dart';
import 'package:traccash/shared/selected_month.dart';

/// The add / edit form, once any stored expense has loaded.
///
/// Text lives in controllers, the chosen category and date in this state.
/// Nothing is written until Save, and a failed write leaves every value as
/// entered.
class ExpenseForm extends ConsumerStatefulWidget {
  const ExpenseForm({this.expense, super.key});

  static const Key amountKey = ValueKey<String>('expense-amount');
  static const Key noteKey = ValueKey<String>('expense-note');

  /// The stored expense when editing; null when adding.
  final Expense? expense;

  @override
  ConsumerState<ExpenseForm> createState() => _ExpenseFormState();
}

enum _Write { save, delete }

class _ExpenseFormState extends ConsumerState<ExpenseForm> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  final TextEditingController _newCategoryName = TextEditingController();
  late final ExpenseFormValues _initial;
  int? _categoryId;
  late LocalDate _date;

  // Messages stay hidden until the first Save, then follow every change.
  bool _submitted = false;
  bool _newCategoryOpen = false;

  /// The write in progress, if any. Disables Save and Delete.
  _Write? _writing;

  /// Why the last write failed, shown in the banner until the next attempt.
  Object? _failure;

  final GlobalKey _bannerKey = GlobalKey();
  final GlobalKey _amountKey = GlobalKey();
  final GlobalKey _categoryKey = GlobalKey();
  final GlobalKey _dateKey = GlobalKey();
  final GlobalKey _noteKey = GlobalKey();

  bool get _editing => widget.expense != null;

  bool get _busy => _writing != null;

  ExpenseFormValues get _values => ExpenseFormValues(
    amountText: _amount.text,
    categoryId: _categoryId,
    date: _date,
    noteText: _note.text,
  );

  bool get _hasChanges =>
      _values.differsFrom(_initial) || _newCategoryName.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _amount = TextEditingController(
      text: expense == null ? '' : formatPesewasForInput(expense.amountPesewas),
    );
    _note = TextEditingController(text: expense?.note ?? '');
    _categoryId = expense?.category.id;
    _date = expense?.occurredOn ?? ref.read(todayProvider);
    _initial = _values;
    // Typing can change a message and whether closing needs a confirmation.
    for (final controller in [_amount, _note, _newCategoryName]) {
      controller.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _newCategoryName.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  Future<void> _save() async {
    // Checked first: a second tap can arrive before the disabled button is
    // drawn.
    if (_busy) return;
    final ExpenseDraft draft;
    switch (validateExpenseForm(_values, today: ref.read(todayProvider))) {
      case InvalidExpenseForm(:final errors):
        setState(() => _submitted = true);
        _revealFirstError(errors);
        return;
      case ValidExpenseForm(draft: final valid):
        draft = valid;
    }

    // Read now: after the form closes, its context and ref are gone, and the
    // snackbar's View action still needs the month notifier.
    final repository = ref.read(expenseRepositoryProvider);
    final viewedMonth = ref.read(selectedMonthProvider);
    final months = ref.read(selectedMonthProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final screenReader = MediaQuery.accessibleNavigationOf(context);
    final id = widget.expense?.id;

    setState(() {
      _submitted = true;
      _writing = _Write.save;
      _failure = null;
    });
    try {
      if (id == null) {
        await repository.add(draft);
      } else {
        await repository.update(id, draft);
      }
    } catch (error) {
      _showFailure(error);
      // Anything but an AppError is a bug: report it, don't hide it.
      if (error is! AppError) rethrow;
      return;
    }
    if (!mounted) return;

    context.pop();
    final savedTo = CalendarMonth.of(draft.occurredOn);
    showSavedSnackBar(
      messenger,
      editing: id != null,
      otherMonth: savedTo == viewedMonth ? null : savedTo,
      onView: () => months.show(savedTo),
      reduceMotion: reduceMotion,
      screenReader: screenReader,
    );
  }

  Future<void> _delete() async {
    final expense = widget.expense;
    if (expense == null || _busy) return;
    final confirmed = await confirmDelete(
      context,
      expense,
      today: ref.read(todayProvider),
    );
    if (!confirmed || !mounted || _busy) return;

    final repository = ref.read(expenseRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final screenReader = MediaQuery.accessibleNavigationOf(context);

    setState(() {
      _writing = _Write.delete;
      _failure = null;
    });
    final Expense deleted;
    try {
      deleted = await repository.delete(expense.id);
    } catch (error) {
      _showFailure(error);
      if (error is! AppError) rethrow;
      return;
    }
    if (!mounted) return;

    context.pop();
    showDeletedSnackBar(
      messenger,
      repository: repository,
      deleted: deleted,
      reduceMotion: reduceMotion,
      screenReader: screenReader,
    );
  }

  void _showFailure(Object error) {
    if (!mounted) return;
    setState(() {
      _writing = null;
      _failure = error;
    });
    _reveal(_bannerKey);
  }

  Future<void> _confirmDiscard() async {
    final discard = await confirmDiscard(context, editing: _editing);
    if (discard && mounted) context.pop();
  }

  void _openNewCategory() => setState(() => _newCategoryOpen = true);

  void _closeNewCategory() {
    _newCategoryName.clear();
    setState(() => _newCategoryOpen = false);
  }

  void _onCategoryCreated(Category category) {
    _newCategoryName.clear();
    setState(() {
      _categoryId = category.id;
      _newCategoryOpen = false;
    });
  }

  void _revealFirstError(ExpenseFormErrors errors) {
    _reveal(
      errors.amount != null
          ? _amountKey
          : errors.category != null
          ? _categoryKey
          : errors.date != null
          ? _dateKey
          : _noteKey,
    );
  }

  /// Scrolls [key]'s widget into view once the frame showing the new message
  /// is laid out. Does nothing if it is already visible.
  void _reveal(GlobalKey key) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.reveal;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = key.currentContext;
      if (target == null || !target.mounted) return;
      unawaited(
        Scrollable.ensureVisible(
          target,
          duration: duration,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final card = AppPalette.of(context).card;
    final errors = switch (validateExpenseForm(_values, today: today)) {
      InvalidExpenseForm(:final errors) when _submitted => errors,
      _ => const ExpenseFormErrors(),
    };
    final failure = _failure;

    return PopScope(
      canPop: !_busy && !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        // Back during a write is ignored; the write takes milliseconds.
        if (!didPop && !_busy) unawaited(_confirmDiscard());
      },
      child: Scaffold(
        backgroundColor: card,
        appBar: AppBar(
          backgroundColor: card,
          scrolledUnderElevation: AppElevation.none,
          leading: const CloseButton(),
          title: Text(_editing ? 'Edit expense' : 'Add expense'),
          actions: [
            if (_editing)
              IconButton(
                onPressed: _busy ? null : _delete,
                tooltip: 'Delete expense',
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        bottomNavigationBar: SaveBar(
          label: _writing == _Write.save
              ? 'Saving…'
              : _editing
              ? 'Save changes'
              : 'Save expense',
          onPressed: _busy ? null : _save,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s20,
            AppSpacing.s8,
            AppSpacing.s20,
            AppSpacing.s32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (failure != null) ...[
                SaveErrorBanner(key: _bannerKey, error: failure),
                const SizedBox(height: AppSpacing.s24),
              ],
              AmountField(
                key: _amountKey,
                fieldKey: ExpenseForm.amountKey,
                controller: _amount,
                // Adding starts with the keyboard up; editing shows the
                // whole record first.
                autofocus: !_editing,
                error: errors.amount,
              ),
              const SizedBox(height: AppSpacing.s28),
              ExpenseCategoryField(
                key: _categoryKey,
                selectedId: _categoryId,
                currentCategoryId: widget.expense?.category.id,
                onSelected: (id) => setState(() => _categoryId = id),
                newCategoryOpen: _newCategoryOpen,
                onOpenNewCategory: _openNewCategory,
                newCategoryName: _newCategoryName,
                onCreated: _onCategoryCreated,
                onCancelNewCategory: _closeNewCategory,
                error: errors.category,
              ),
              const SizedBox(height: AppSpacing.s28),
              ExpenseDateField(
                key: _dateKey,
                date: _date,
                today: today,
                onChanged: (date) => setState(() => _date = date),
                error: errors.date,
              ),
              const SizedBox(height: AppSpacing.s28),
              NoteField(
                key: _noteKey,
                fieldKey: ExpenseForm.noteKey,
                controller: _note,
                error: errors.note,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
