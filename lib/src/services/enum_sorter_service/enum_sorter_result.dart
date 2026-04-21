/// Result of an enum sorting operation.
///
/// Contains comprehensive information about processed enums, modifications,
/// and any errors encountered during the operation.
class EnumSorterResult {
  /// Creates a new sorting result.
  ///
  /// Parameters:
  /// * [filePath] - The file that was processed
  /// * [enumsFound] - Number of enum declarations found in the file
  /// * [enumsSorted] - Number of enums that were reordered
  /// * [errors] - List of error messages encountered
  /// * [dryRun] - Whether this was a dry run operation
  const EnumSorterResult({
    required this.filePath,
    required this.enumsFound,
    required this.enumsSorted,
    required this.errors,
    required this.dryRun,
  });

  /// The file that was processed.
  final String filePath;

  /// Total number of enum declarations found in the file.
  final int enumsFound;

  /// Number of enums whose values were reordered.
  final int enumsSorted;

  /// List of error messages for issues encountered during processing.
  final List<String> errors;

  /// Whether this was a dry run operation.
  ///
  /// When true, no files were actually modified.
  final bool dryRun;

  /// Whether the operation completed successfully without errors.
  bool get success => errors.isEmpty;

  /// Whether any enums were reordered or would be reordered.
  bool get hasModifications => enumsSorted > 0;

  /// Whether any errors occurred during processing.
  bool get hasErrors => errors.isNotEmpty;
}
