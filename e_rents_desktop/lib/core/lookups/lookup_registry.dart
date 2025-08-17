import 'package:e_rents_desktop/core/lookups/lookup_key.dart';
import 'package:e_rents_desktop/models/lookup_item.dart';
import 'package:e_rents_desktop/utils/name_normalizer.dart';

/// Central registry and single source of truth for both static and dynamic lookups.
///
/// Providers/services populate this registry; widgets/models read from it.
class LookupRegistry {
  // In-memory store per key
  final Map<LookupKey, List<LookupItem>> _store = {};

  // Optional timestamps if you want TTL at provider level
  final Map<LookupKey, DateTime> _updatedAt = {};

  /// Replace all items for a given key
  void setItems(LookupKey key, List<LookupItem> items) {
    _store[key] = List.unmodifiable(items);
    _updatedAt[key] = DateTime.now();
  }

  /// Add or replace for multiple keys at once
  void setMany(Map<LookupKey, List<LookupItem>> entries) {
    for (final e in entries.entries) {
      setItems(e.key, e.value);
    }
  }

  /// Get items for a key (empty list if missing)
  List<LookupItem> getItems(LookupKey key) => _store[key] ?? const [];

  /// When this key last updated
  DateTime? lastUpdated(LookupKey key) => _updatedAt[key];

  /// Try find by id
  LookupItem? findById(LookupKey key, int id) {
    for (final item in getItems(key)) {
      if (item.value == id) return item;
    }
    return null;
  }

  /// Try find by normalized name
  LookupItem? findByName(LookupKey key, String name) {
    final target = NameNormalizer.normalize(name);
    for (final item in getItems(key)) {
      if (NameNormalizer.normalize(item.text) == target) return item;
    }
    return null;
  }

  /// Get label by id or name
  String? label(
    LookupKey key, {
    int? id,
    String? name,
  }) {
    if (id != null) {
      return findById(key, id)?.text;
    }
    if (name != null) {
      return findByName(key, name)?.text;
    }
    return null;
  }

  /// Convert to dropdown items (simple structure)
  List<DropdownItem> dropdownItems(LookupKey key) {
    return getItems(key)
        .map((e) => DropdownItem(value: e.value, label: e.text))
        .toList(growable: false);
  }
}

/// Lightweight dropdown item to decouple UI widgets from backend DTOs
class DropdownItem {
  final int value;
  final String label;

  const DropdownItem({required this.value, required this.label});

  @override
  String toString() => 'DropdownItem(value: $value, label: $label)';
}
