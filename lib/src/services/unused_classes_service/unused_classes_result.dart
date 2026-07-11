import 'unused_class_info.dart';

/// Result of an unused class detection operation.
///
/// Contains comprehensive information about the scan including total files
/// and classes analyzed, which classes appear unused, and any errors
/// encountered during the operation.
class UnusedClassesResult {
  /// Creates a new unused classes detection result.
  ///
  /// Parameters:
  /// * [targetPath] - The directory that was scanned
  /// * [filesScanned] - Total number of Dart files analyzed
  /// * [totalClasses] - Total number of class declarations found
  /// * [unusedClasses] - List of classes that appear to have no references
  /// * [errors] - List of error messages encountered during scanning
  const UnusedClassesResult({
    required this.targetPath,
    required this.filesScanned,
    required this.totalClasses,
    required this.unusedClasses,
    required this.errors,
  });

  /// The directory that was scanned.
  final String targetPath;

  /// Total number of Dart files that were analyzed.
  final int filesScanned;

  /// Total number of class declarations found across all files.
  final int totalClasses;

  /// Classes that appear to have no references in the scanned codebase.
  final List<UnusedClassInfo> unusedClasses;

  /// List of error messages for issues encountered during scanning.
  final List<String> errors;

  /// Whether the operation completed successfully without errors.
  bool get success => errors.isEmpty;

  /// Whether any unused classes were detected.
  bool get hasUnusedClasses => unusedClasses.isNotEmpty;

  /// Whether any errors occurred during processing.
  bool get hasErrors => errors.isNotEmpty;
}
