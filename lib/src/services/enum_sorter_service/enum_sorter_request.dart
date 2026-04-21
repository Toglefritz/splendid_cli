/// Request configuration for enum sorting operations.
///
/// Contains all parameters needed to execute a sorting operation on Dart files
/// containing enum declarations.
class EnumSorterRequest {
  /// Creates a new sorting request.
  ///
  /// Parameters:
  /// * [targetPath] - Path to a .dart file containing enum declarations
  /// * [dryRun] - If true, analyze without modifying the file
  const EnumSorterRequest({
    required this.targetPath,
    this.dryRun = false,
  });

  /// Path to the target .dart file to process.
  ///
  /// Must be a single .dart file containing one or more enum declarations.
  final String targetPath;

  /// Whether to perform a dry run without modifying the file.
  ///
  /// When true, the file is analyzed and results reported but no changes are
  /// written to disk.
  final bool dryRun;
}
