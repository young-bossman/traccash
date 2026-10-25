import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traccash/data/database/database_provider.dart';
import 'package:traccash/data/database/simulated_failure.dart';
import 'package:traccash/features/categories/data/drift_category_repository.dart';
import 'package:traccash/features/categories/domain/category.dart';

/// Categories for the picker and for labelling expenses.
///
/// Errors are always `AppError`s.
abstract interface class CategoryRepository {
  /// Categories the user can pick, in display order.
  Stream<List<Category>> watchActive();

  /// Every category including archived ones, in display order. Used to label
  /// past expenses and summaries.
  Stream<List<Category>> watchAll();

  /// Creates a category from the inline form, or brings back an archived one
  /// with the same name (keeping its original icon).
  ///
  /// Throws `CategoryNameError`, `InvalidCategoryIconError` or
  /// `DuplicateCategoryError`.
  Future<Category> create(String name, String iconKey);

  /// Hides a category from the picker. Its expenses keep their label.
  /// Throws `CategoryNotFoundError`.
  Future<void> archive(int id);
}

/// Widget tests override this with a fake.
final Provider<CategoryRepository> categoryRepositoryProvider =
    Provider<CategoryRepository>(
      (ref) => DriftCategoryRepository(
        ref.watch(appDatabaseProvider),
        simulatedFailure: simulatedFailureHook(ref),
      ),
    );
