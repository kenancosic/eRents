class NameNormalizer {
  const NameNormalizer._();

  static String normalize(String input) {
    final s = input.trim().toLowerCase();
    // Replace separators with space
    final replaced = s.replaceAll(RegExp(r'[\-_]'), ' ');
    // Collapse whitespace
    final collapsed = replaced.replaceAll(RegExp(r'\s+'), ' ');
    return collapsed;
  }
}
