/// Generic lookup item response matching backend LookupItemResponse
class LookupItem {
  final int value;
  final String text;
  final String? description;

  const LookupItem({
    required this.value,
    required this.text,
    this.description,
  });

  factory LookupItem.fromJson(Map<String, dynamic> json) {
    return LookupItem(
      value: json['value'] as int,
      text: json['text'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'text': text,
      'description': description,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LookupItem &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          text == other.text &&
          description == other.description;

  @override
  int get hashCode => value.hashCode ^ text.hashCode ^ description.hashCode;

  @override
  String toString() => 'LookupItem(value: $value, text: $text, description: $description)';
}

/// Alias for backward compatibility
typedef LookupData = LookupItem;
typedef LookupItemResponse = LookupItem;