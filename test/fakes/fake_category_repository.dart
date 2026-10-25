import 'dart:async';

import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/features/categories/data/category_repository.dart';
import 'package:traccash/features/categories/domain/category.dart';
import 'package:traccash/features/categories/domain/category_validation.dart';

import 'fake_streams.dart';

/// In-memory [CategoryRepository] for widget tests. Starts with the 8
/// presets (ids 1 to 8) and applies the same validation as the real one.
class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    final createdAt = DateTime.utc(2026);
    for (final (index, preset) in presetCategories.indexed) {
      _categories.add(
        Category(
          id: index + 1,
          name: preset.name,
          iconKey: preset.iconKey,
          sortOrder: index,
          isPreset: true,
          isArchived: false,
          createdAt: createdAt,
        ),
      );
    }
    _nextId = _categories.length + 1;
  }

  final DateTime Function() _clock;
  final List<Category> _categories = [];
  final StreamController<void> _changes = StreamController<void>.broadcast();
  late int _nextId;

  /// When true, the next write throws [StorageError] and the flag resets.
  bool failNextWrite = false;

  /// Fires after every change, so the fake expense repository can re-emit
  /// joined labels the way a Drift join does.
  Stream<void> get changes => _changes.stream;

  List<Category> get categories => List.unmodifiable(_categories);

  Category? byId(int id) {
    for (final category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  /// Used by the fake expense repository's `clearAll`.
  void removeUserCategories() {
    _categories.removeWhere((c) => !c.isPreset);
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();

  void _maybeFail() {
    if (failNextWrite) {
      failNextWrite = false;
      throw const StorageError();
    }
  }

  List<Category> _sorted(bool Function(Category) keep) =>
      _categories.where(keep).toList()..sort((a, b) {
        final byOrder = a.sortOrder.compareTo(b.sortOrder);
        return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
      });

  @override
  Stream<List<Category>> watchActive() =>
      watchValue(_changes.stream, () => _sorted((c) => !c.isArchived));

  @override
  Stream<List<Category>> watchAll() =>
      watchValue(_changes.stream, () => _sorted((_) => true));

  @override
  Future<Category> create(String name, String iconKey) async {
    final normalized = normalizeCategoryName(name);
    final invalid = validateNewCategory(normalized, iconKey);
    if (invalid != null) throw invalid;
    _maybeFail();

    final existing = findCategoryNamed(normalized, _categories);
    if (existing != null) {
      if (!existing.isArchived) throw DuplicateCategoryError(existing.name);
      final restored = existing.copyWith(isArchived: false);
      _categories[_categories.indexOf(existing)] = restored;
      _changes.add(null);
      return restored;
    }

    final maxOrder = _categories
        .map((c) => c.sortOrder)
        .fold(-1, (a, b) => a > b ? a : b);
    final category = Category(
      id: _nextId++,
      name: normalized,
      iconKey: iconKey,
      sortOrder: maxOrder + 1,
      isPreset: false,
      isArchived: false,
      createdAt: _clock().toUtc(),
    );
    _categories.add(category);
    _changes.add(null);
    return category;
  }

  @override
  Future<void> archive(int id) async {
    _maybeFail();
    final existing = byId(id);
    if (existing == null) throw const CategoryNotFoundError();
    _categories[_categories.indexOf(existing)] = existing.copyWith(
      isArchived: true,
    );
    _changes.add(null);
  }
}
