/// Builds acronym-style short names from titles or person names.
class ShortNameGenerator {
  ShortNameGenerator._();

  static const _stopWords = {
    'a',
    'an',
    'the',
    'of',
    'and',
    'in',
    'on',
    'for',
    'to',
    'at',
  };

  /// Examples: "Ravi Kumar Sharma" → "RKS", "Computer Science Engineering" → "CSE".
  static String generate(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';

    final words = trimmed
        .split(RegExp(r'[\s\-_,.]+'))
        .map((w) => w.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ''))
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) return '';

    final buffer = StringBuffer();
    for (final word in words) {
      if (_stopWords.contains(word.toLowerCase())) continue;
      buffer.write(word[0].toUpperCase());
    }

    final result = buffer.toString();
    if (result.isNotEmpty) return result;

    return words.first[0].toUpperCase();
  }
}
