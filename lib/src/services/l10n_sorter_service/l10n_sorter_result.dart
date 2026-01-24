/// Result of an L10n sorting operation.
///
/// Contains comprehensive information about processed files, modifications, and
/// any errors encountered during the operation.
class L10nSorterResult {
  /// Creates a new sorting result.
  ///
  /// Parameters:
  /// * [processedFiles] - List of all files that were processed
  /// * [modifiedFiles] - List of files that were modified or would be modified
  /// * [errors] - List of error messages encountered
  /// * [dryRun] - Whether this was a dry run operation
  const L10nSorterResult({
    required this.processedFiles,
    required this.modifiedFiles,
    required this.errors,
    required this.dryRun,
  });

  /// List of all files that were successfully processed.
  ///
  /// Includes both modified and unmodified files.
  final List<String> processedFiles;

  /// List of files that were modified or would be modified in dry-run mode.
  ///
  /// These files had their entries reordered during sorting.
  final List<String> modifiedFiles;

  /// List of error messages for files that could not be processed.
  ///
  /// Each error includes the filename and error description.
  final List<String> errors;

  /// Whether this was a dry run operation.
  ///
  /// When true, no files were actually modified.
  final bool dryRun;

  /// Total number of files processed.
  int get totalProcessed => processedFiles.length;

  /// Total number of files modified or that would be modified.
  int get totalModified => modifiedFiles.length;

  /// Total number of errors encountered.
  int get totalErrors => errors.length;

  /// Whether the operation completed successfully without errors.
  bool get success => errors.isEmpty;

  /// Whether any files were modified or would be modified.
  bool get hasModifications => modifiedFiles.isNotEmpty;

  /// Whether any errors occurred during processing.
  bool get hasErrors => errors.isNotEmpty;
}
