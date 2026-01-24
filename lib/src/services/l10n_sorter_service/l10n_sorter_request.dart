/// Request configuration for L10n sorting operations.
///
/// Contains all parameters needed to execute a sorting operation on ARB files.
class L10nSorterRequest {
  /// Creates a new sorting request.
  ///
  /// Parameters:
  /// * [targetPath] - Path to .arb file or directory containing .arb files
  /// * [dryRun] - If true, analyze without modifying files
  const L10nSorterRequest({
    required this.targetPath,
    this.dryRun = false,
  });

  /// Path to the target file or directory to process.
  ///
  /// Can be either:
  /// * A single .arb file path
  /// * A directory path containing .arb files
  final String targetPath;

  /// Whether to perform a dry run without modifying files.
  ///
  /// When true, files are analyzed and results reported but no changes are
  /// written to disk.
  final bool dryRun;
}
