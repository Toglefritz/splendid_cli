/// Internal result of processing all enums in a file.
class SortOutcome {
  /// Creates a new sort outcome.
  const SortOutcome({
    required this.content,
    required this.enumsFound,
    required this.enumsSorted,
  });

  /// The file content after sorting (may be unchanged).
  final String content;

  /// Number of enum declarations found.
  final int enumsFound;

  /// Number of enums whose values were reordered.
  final int enumsSorted;
}
