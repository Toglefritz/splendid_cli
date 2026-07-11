/// Request configuration for unused class detection operations.
///
/// Contains all parameters needed to scan a Dart project directory for
/// class declarations that are not referenced elsewhere in the codebase.
class UnusedClassesRequest {
  /// Creates a new unused classes detection request.
  ///
  /// Parameters:
  /// * [targetPath] - Path to the project directory (typically the `lib/`
  ///   folder) to scan for unused classes
  /// * [excludePatterns] - Optional list of glob-like patterns for paths to
  ///   exclude from scanning (e.g., generated files)
  const UnusedClassesRequest({
    required this.targetPath,
    this.excludePatterns = const <String>[],
  });

  /// Path to the target directory to scan.
  ///
  /// This should point to a directory containing Dart source files, typically
  /// the `lib/` folder of a Dart or Flutter project.
  final String targetPath;

  /// Glob-like patterns for file paths to exclude from the scan.
  ///
  /// Files matching any of these patterns will be skipped during analysis.
  /// Useful for excluding generated code (e.g., `.g.dart`, `.freezed.dart`).
  final List<String> excludePatterns;
}
