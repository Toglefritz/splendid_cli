/// Request configuration for unused localization string detection.
///
/// Contains all parameters needed to scan a Flutter project for localization
/// keys defined in ARB files that are not referenced in any Dart source file.
class UnusedL10nRequest {
  /// Creates a new unused l10n detection request.
  ///
  /// Parameters:
  /// * [arbFilePath] - Path to the primary ARB file to parse for keys
  /// * [sourcePath] - Path to the source directory to scan for references
  /// * [excludePatterns] - Optional patterns for file paths to exclude from
  ///   the Dart source scan
  const UnusedL10nRequest({
    required this.arbFilePath,
    required this.sourcePath,
    this.excludePatterns = const <String>[],
  });

  /// Path to the primary ARB file containing localization keys.
  ///
  /// Typically this is the English ARB file (e.g., `lib/l10n/app_en.arb`).
  /// All JSON keys that do not start with `@` are treated as localization
  /// string keys.
  final String arbFilePath;

  /// Path to the source directory to scan for references to localization keys.
  ///
  /// This should point to the `lib/` directory of the Flutter project.
  final String sourcePath;

  /// Glob-like patterns for file paths to exclude from the Dart source scan.
  ///
  /// Files matching any of these patterns will be skipped. Useful for
  /// excluding generated code (e.g., `.g.dart`, `app_localizations.dart`).
  final List<String> excludePatterns;
}
