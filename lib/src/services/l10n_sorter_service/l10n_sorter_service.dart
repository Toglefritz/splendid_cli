import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'l10n_sorter_error_type.dart';
import 'l10n_sorter_exception.dart';
import 'l10n_sorter_request.dart';
import 'l10n_sorter_result.dart';

/// Service for sorting Flutter localization (.arb) files alphabetically.
///
/// This service processes ARB (Application Resource Bundle) files used in
/// Flutter localization, sorting entries alphabetically by key while
/// maintaining the relationship between value entries and their metadata
/// entries (prefixed with @).
///
/// Key Features:
/// * Alphabetical sorting by entry keys
/// * Preserves value-metadata pairs (e.g., "key" stays with "@key")
/// * Maintains JSON formatting and structure
/// * Processes single files or entire directories
/// * Dry-run mode for previewing changes
/// * Comprehensive error handling and validation
///
/// ARB File Structure: ARB files contain key-value pairs where metadata entries
/// are prefixed with @ and must immediately follow their corresponding value
/// entry:
/// ```json
/// {
/// "appTitle": "My App",
/// "@appTitle": {
/// "description": "The title of the application"
/// },
/// "buttonSave": "Save",
/// "@buttonSave": {
/// "description": "Label for save button"
/// }
/// }
/// ```
///
/// Sorting Behavior:
/// * Entries are sorted alphabetically by their base key (without @ prefix)
/// * Metadata entries always follow their corresponding value entry
/// * Original JSON formatting is preserved where possible
/// * Empty files and invalid JSON are handled gracefully
///
/// Thread Safety: This service performs file I/O operations and is not
/// thread-safe for concurrent operations on the same files.
class L10nSorterService {
  /// Creates a new instance of [L10nSorterService].
  const L10nSorterService();

  /// Sorts ARB files in the specified target path.
  ///
  /// Processes either a single .arb file or all .arb files in a directory
  /// (non-recursively). Each file is read, sorted, and optionally written back.
  ///
  /// Parameters:
  /// * [request] - Configuration for the sorting operation
  ///
  /// Returns a [L10nSorterResult] containing statistics and any errors
  /// encountered.
  ///
  /// Throws [L10nSorterException] for critical errors like missing targets or
  /// permission issues.
  Future<L10nSorterResult> sortL10nFiles(L10nSorterRequest request) async {
    final File targetFile = File(request.targetPath);
    final Directory targetDir = Directory(request.targetPath);

    final List<String> processedFiles = <String>[];
    final List<String> modifiedFiles = <String>[];
    final List<String> errors = <String>[];

    // Determine if target is a file or directory
    if (targetFile.existsSync()) {
      // Process single file
      if (!request.targetPath.endsWith('.arb')) {
        throw const L10nSorterException(
          'Target file must be an .arb file',
          L10nSorterErrorType.invalidFileType,
        );
      }

      final bool wasModified = await _processSingleFile(
        targetFile,
        request.dryRun,
        errors,
      );

      processedFiles.add(request.targetPath);
      if (wasModified) {
        modifiedFiles.add(request.targetPath);
      }
    } else if (targetDir.existsSync()) {
      // Process all .arb files in directory
      final List<FileSystemEntity> entities = targetDir.listSync();

      for (final FileSystemEntity entity in entities) {
        if (entity is File && entity.path.endsWith('.arb')) {
          final bool wasModified = await _processSingleFile(
            entity,
            request.dryRun,
            errors,
          );

          processedFiles.add(entity.path);
          if (wasModified) {
            modifiedFiles.add(entity.path);
          }
        }
      }

      if (processedFiles.isEmpty) {
        throw L10nSorterException(
          'No .arb files found in directory: ${request.targetPath}',
          L10nSorterErrorType.noFilesFound,
        );
      }
    } else {
      throw L10nSorterException(
        'Target path does not exist: ${request.targetPath}',
        L10nSorterErrorType.targetNotFound,
      );
    }

    return L10nSorterResult(
      processedFiles: processedFiles,
      modifiedFiles: modifiedFiles,
      errors: errors,
      dryRun: request.dryRun,
    );
  }

  /// Processes a single ARB file, sorting its contents.
  ///
  /// Reads the file, parses JSON, sorts entries, and optionally writes back.
  ///
  /// Parameters:
  /// * [file] - The ARB file to process
  /// * [dryRun] - If true, don't write changes back to file
  /// * [errors] - List to accumulate error messages
  ///
  /// Returns true if the file would be/was modified, false otherwise.
  Future<bool> _processSingleFile(
    File file,
    bool dryRun,
    List<String> errors,
  ) async {
    try {
      final String content = await file.readAsString();

      // Parse JSON
      final Map<String, dynamic> jsonData = json.decode(content) as Map<String, dynamic>;

      // Sort the entries
      final String sortedContent = _sortArbContent(jsonData);

      // Check if content changed
      final String normalizedOriginal = _normalizeJson(content);
      final String normalizedSorted = _normalizeJson(sortedContent);

      if (normalizedOriginal == normalizedSorted) {
        return false; // No changes needed
      }

      // Write back if not dry run
      if (!dryRun) {
        await file.writeAsString(sortedContent);
      }

      return true;
    } catch (e) {
      errors.add('${path.basename(file.path)}: $e');
      return false;
    }
  }

  /// Sorts ARB content alphabetically while preserving value-metadata pairs.
  ///
  /// This method processes the JSON map and creates a new sorted structure
  /// where:
  /// 1. Entries are sorted alphabetically by their base key
  /// 2. Metadata entries (@key) immediately follow their value entries (key)
  /// 3. JSON formatting is clean and consistent
  ///
  /// Parameters:
  /// * [jsonData] - Parsed JSON data from the ARB file
  ///
  /// Returns formatted JSON string with sorted entries.
  String _sortArbContent(Map<String, dynamic> jsonData) {
    // Separate regular entries from metadata entries
    final Map<String, dynamic> regularEntries = <String, dynamic>{};
    final Map<String, dynamic> metadataEntries = <String, dynamic>{};

    for (final MapEntry<String, dynamic> entry in jsonData.entries) {
      if (entry.key.startsWith('@')) {
        metadataEntries[entry.key] = entry.value;
      } else {
        regularEntries[entry.key] = entry.value;
      }
    }

    // Sort regular entries alphabetically
    final List<String> sortedKeys = regularEntries.keys.toList()..sort();

    // Build sorted map with metadata following each entry
    final Map<String, dynamic> sortedMap = <String, dynamic>{};

    for (final String key in sortedKeys) {
      // Add the regular entry
      sortedMap[key] = regularEntries[key];

      // Add metadata entry if it exists
      final String metadataKey = '@$key';
      if (metadataEntries.containsKey(metadataKey)) {
        sortedMap[metadataKey] = metadataEntries[metadataKey];
      }
    }

    // Convert to formatted JSON
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    return '${encoder.convert(sortedMap)}\n';
  }

  /// Normalizes JSON string for comparison by removing whitespace variations.
  ///
  /// This allows comparison of JSON content regardless of formatting
  /// differences.
  ///
  /// Parameters:
  /// * [jsonString] - JSON string to normalize
  ///
  /// Returns normalized JSON string for comparison.
  String _normalizeJson(String jsonString) {
    try {
      final dynamic parsed = json.decode(jsonString);
      return json.encode(parsed);
    } catch (e) {
      return jsonString;
    }
  }
}
