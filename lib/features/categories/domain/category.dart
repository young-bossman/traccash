/// An expense category: one of the 8 presets or one the user created.
///
/// Categories are archived, never deleted, so every past expense keeps its
/// label.
final class Category {
  const Category({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.sortOrder,
    required this.isPreset,
    required this.isArchived,
    required this.createdAt,
  });

  final int id;
  final String name;

  /// A preset's key from [presetCategories], or one of [userIconKeys];
  /// mapped to an icon in the UI.
  final String iconKey;
  final int sortOrder;
  final bool isPreset;
  final bool isArchived;

  /// UTC.
  final DateTime createdAt;

  Category copyWith({
    int? id,
    String? name,
    String? iconKey,
    int? sortOrder,
    bool? isPreset,
    bool? isArchived,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      sortOrder: sortOrder ?? this.sortOrder,
      isPreset: isPreset ?? this.isPreset,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Category &&
      other.id == id &&
      other.name == name &&
      other.iconKey == iconKey &&
      other.sortOrder == sortOrder &&
      other.isPreset == isPreset &&
      other.isArchived == isArchived &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    iconKey,
    sortOrder,
    isPreset,
    isArchived,
    createdAt,
  );

  @override
  String toString() => 'Category($id, $name)';
}

/// The 8 categories every install starts with, in display order.
const List<({String name, String iconKey})> presetCategories = [
  (name: 'Food', iconKey: 'food'),
  (name: 'Transport', iconKey: 'transport'),
  (name: 'Bills', iconKey: 'bills'),
  (name: 'Data & Airtime', iconKey: 'data_airtime'),
  (name: 'Shopping', iconKey: 'shopping'),
  (name: 'Health', iconKey: 'health'),
  (name: 'Entertainment', iconKey: 'entertainment'),
  (name: 'Other', iconKey: 'other'),
];

/// Icons a user can pick for a new category (DESIGN_SPEC §5b). The first is
/// the default.
const List<String> userIconKeys = [
  'tag',
  'home',
  'family',
  'education',
  'gifts',
  'fuel',
  'personal_care',
  'work',
];
