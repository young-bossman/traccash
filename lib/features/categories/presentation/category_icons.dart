import 'package:flutter/material.dart';

/// The one place `icon_key` values become icons. Keys are stored in the
/// database, so they are never renamed; only the icon they map to may change.
const Map<String, IconData> _categoryIcons = {
  // Presets.
  'food': Icons.restaurant_outlined,
  'transport': Icons.directions_bus_outlined,
  'bills': Icons.description_outlined,
  'data_airtime': Icons.signal_cellular_alt,
  'shopping': Icons.shopping_bag_outlined,
  'health': Icons.medical_services_outlined,
  'entertainment': Icons.movie_outlined,
  'other': Icons.category_outlined,
  // User-created categories.
  'tag': Icons.sell_outlined,
  'home': Icons.home_outlined,
  'family': Icons.family_restroom_outlined,
  'education': Icons.school_outlined,
  'gifts': Icons.card_giftcard_outlined,
  'fuel': Icons.local_gas_station_outlined,
  'personal_care': Icons.spa_outlined,
  'work': Icons.work_outline,
};

/// Names of the icons a user can pick (DESIGN_SPEC §5b), for tooltips and
/// screen readers.
const Map<String, String> _userIconLabels = {
  'tag': 'Tag',
  'home': 'Home',
  'family': 'Family',
  'education': 'Education',
  'gifts': 'Gifts',
  'fuel': 'Fuel',
  'personal_care': 'Personal care',
  'work': 'Work',
};

/// The icon for [iconKey]. An unknown key (only possible from a newer build's
/// data) falls back to the default user icon rather than failing.
IconData categoryIcon(String iconKey) =>
    _categoryIcons[iconKey] ?? Icons.sell_outlined;

/// What a user icon shows, such as "Personal care".
String userIconLabel(String iconKey) => _userIconLabels[iconKey] ?? 'Tag';
