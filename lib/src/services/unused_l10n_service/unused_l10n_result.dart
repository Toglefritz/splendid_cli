import 'unused_l10n_info.dart';

/// Result of an unused localization string detection operation.
///
/// Contains comprehensive information about the scan including total keys
/// parsed, files analyzed, which keys appear unused, and any errors
/// encountered during the operation.
class UnusedL10nResult {
  /// Creates a new unused l10n detection result.
  ///
  /// Parameters:
  /// * [arbFilePath] - The ARB file that was parsed
  /// * [sourcePath] - The source directory that was scanned
  /// * [totalKeys] - Total number of localization keys found in the ARB file
  /// * [filesScanned] - Total number of Dart files analyzed for references
  /// * [unusedKeys] - List of keys that appear to have no references
  /// * [errors] - List of error messages encountered during scanning
  const UnusedL10nResult({
    required this.arbFilePath,
    required this.sourcePath,
    required this.totalKeys,
    required this.filesScanned,
    required this.unusedKeys,
    required this.errors,
  });

  /// The ARB file that was parsed for localization keys.
  final String arbFilePath;

  /// The source directory that was scanned for references.
  final String sourcePath;

  /// Total number of localization keys found in the ARB file.
  final int totalKeys;

  /// Total number of Dart files analyzed for key references.
  final int filesScanned;

  /// Localization keys that appear to have no references in the source code.
  final List<UnusedL10nInfo> unusedKeys;

  /// List of error messages for issues encountered during scanning.
  final List<String> errors;

  /// Whether the operation completed successfully without errors.
  bool get success => errors.isEmpty;

  /// Whether any unused keys were detected.
  bool get hasUnusedKeys => unusedKeys.isNotEmpty;

  /// Whether any errors occurred during processing.
  bool get hasErrors => errors.isNotEmpty;

  /// Number of keys that are referenced in the source code.
  int get usedKeys => totalKeys - unusedKeys.length;
}
