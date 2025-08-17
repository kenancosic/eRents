import 'package:e_rents_desktop/core/lookups/lookup_key.dart';
import 'package:e_rents_desktop/models/lookup_item.dart';

/// A lightweight descriptor for static enum-like groups.
/// Not strictly tied to Dart enums to avoid circular deps; can be used for
/// both real enums and static constant lists.
class EnumDescriptor {
  final LookupKey key;
  final List<LookupItem> items;

  const EnumDescriptor({required this.key, required this.items});
}
