import 'dart:convert';
import 'dart:io';

import 'unused_l10n_error_type.dart';
import 'unused_l10n_exception.dart';
import 'unused_l10n_info.dart';
import 'unused_l10n_request.dart';
import 'unused_l10n_result.dart';

/// Service for detecting unused localization strings in a Flutter project.
///
/// This service parses an ARB (Application Resource Bundle) file to extract
/// all localization keys, then scans Dart source files to determine which
/// keys are actually referenced in code. Keys that have no references are
/// reported as potentially unused.
///
/// Detection Strategy:
/// * Localization keys are extracted from the ARB file as any JSON key that
///   does not start with `@` (the `@` prefix denotes metadata entries).
/// * For each key, a whole-word regex search (`\bkeyName\b`) is performed
///   across all Dart files in the source directory.
/// * Generated localization files (`app_localizations.dart` and its
///   locale-specific variants) are automatically excluded from the scan
///   since they simply reflect the ARB contents.
///
/// Common Access Patterns Detected:
/// * `AppLocalizations.of(context)!.keyName`
/// * `AppLocalizations.of(context)?.keyName`
/// * Aliased access: `l10n.keyName`, `localizations.keyName`, etc.
/// * Any other occurrence of the key as a whole word in Dart source
///
/// Limitations:
/// * Keys referenced dynamically (e.g., via string interpolation or maps)
///   will not be detected and may be falsely reported as unused.
/// * Keys used only in tests (outside `lib/`) will appear unused if only
///   `lib/` is scanned.
/// * Keys reserved for future use or platform-specific builds may appear
///   unused in the current codebase.
///
/// Thread Safety: This service performs file I/O operations and is not
/// thread-safe for concurrent operations on the same file tree.
class UnusedL10nService {
  /// Creates a new instance of [UnusedL10nService].
  const UnusedL10nService();

  /// Scans for unused localization keys in the project.
  ///
  /// Parses the ARB file to extract keys, then searches all Dart files in
  /// the source directory for references to each key.
  ///
  /// Parameters:
  /// * [request] - Configuration for the detection operation
  ///
  /// Returns an [UnusedL10nResult] containing findings and statistics.
  ///
  /// Throws [UnusedL10nException] for critical errors like missing files
  /// or invalid ARB format.
  Future<UnusedL10nResult> findUnusedKeys(
    UnusedL10nRequest request,
  ) async {
    final File arbFile = File(request.arbFilePath);

    if (!arbFile.existsSync()) {
      throw UnusedL10nException(
        'ARB file does not exist: ${request.arbFilePath}',
        UnusedL10nErrorType.arbFileNotFound,
      );
    }

    final Directory sourceDir = Directory(request.sourcePath);

    if (!sourceDir.existsSync()) {
      throw UnusedL10nException(
        'Source directory does not exist: ${request.sourcePath}',
        UnusedL10nErrorType.sourceNotFound,
      );
    }

    final List<String> errors = <String>[];

    try {
      // Parse the ARB file.
      final Map<String, String?> keys = _parseArbKeys(
        await arbFile.readAsString(),
      );

      if (keys.isEmpty) {
        throw const UnusedL10nException(
          'No localization keys found in the ARB file',
          UnusedL10nErrorType.noKeysFound,
        );
      }

      // Collect Dart source files, excluding generated l10n files.
      final List<File> dartFiles = _collectDartFiles(
        sourceDir,
        request.excludePatterns,
      );

      if (dartFiles.isEmpty) {
        throw const UnusedL10nException(
          'No Dart files found in the source directory',
          UnusedL10nErrorType.noDartFilesFound,
        );
      }

      // Read all source file contents.
      final List<String> fileContents = <String>[];
      for (final File file in dartFiles) {
        try {
          fileContents.add(await file.readAsString());
        } catch (e) {
          errors.add('Failed to read ${file.path}: $e');
        }
      }

      // Check each key for references.
      final List<UnusedL10nInfo> unusedKeys = <UnusedL10nInfo>[];
      for (final MapEntry<String, String?> entry in keys.entries) {
        final bool isReferenced = _isKeyReferenced(
          entry.key,
          fileContents,
        );
        if (!isReferenced) {
          unusedKeys.add(
            UnusedL10nInfo(key: entry.key, description: entry.value),
          );
        }
      }

      // Sort unused keys alphabetically.
      unusedKeys.sort(
        (a, b) => a.key.compareTo(b.key),
      );

      return UnusedL10nResult(
        arbFilePath: request.arbFilePath,
        sourcePath: request.sourcePath,
        totalKeys: keys.length,
        filesScanned: fileContents.length,
        unusedKeys: unusedKeys,
        errors: errors,
      );
    } catch (e) {
      if (e is UnusedL10nException) rethrow;
      errors.add(e.toString());

      return UnusedL10nResult(
        arbFilePath: request.arbFilePath,
        sourcePath: request.sourcePath,
        totalKeys: 0,
        filesScanned: 0,
        unusedKeys: const <UnusedL10nInfo>[],
        errors: errors,
      );
    }
  }

  /// Parses an ARB file's JSON content and extracts localization keys.
  ///
  /// Any top-level JSON key that does not start with `@` or `@@` is treated
  /// as a localization key. The description for each key is extracted from
  /// the corresponding `@key` metadata entry if present.
  ///
  /// Parameters:
  /// * [content] - Raw JSON content of the ARB file
  ///
  /// Returns a map of key names to their descriptions (null if no description).
  ///
  /// Throws [UnusedL10nException] if the content is not valid JSON.
  Map<String, String?> _parseArbKeys(String content) {
    final Object? parsed;
    try {
      parsed = jsonDecode(content);
    } catch (e) {
      throw UnusedL10nException(
        'Failed to parse ARB file as JSON: $e',
        UnusedL10nErrorType.invalidArbFormat,
      );
    }

    if (parsed is! Map<String, dynamic>) {
      throw const UnusedL10nException(
        'ARB file root must be a JSON object',
        UnusedL10nErrorType.invalidArbFormat,
      );
    }

    final Map<String, String?> keys = <String, String?>{};

    for (final String key in parsed.keys) {
      // Skip metadata keys (prefixed with @ or @@).
      if (key.startsWith('@')) continue;

      // Look for a description in the corresponding @key metadata.
      final Object? metadata = parsed['@$key'];
      String? description;
      if (metadata is Map<String, dynamic>) {
        description = metadata['description'] as String?;
      }

      keys[key] = description;
    }

    return keys;
  }

  /// Recursively collects Dart files from [directory], excluding generated
  /// localization files and files matching [excludePatterns].
  ///
  /// Automatically excludes:
  /// * `app_localizations.dart` and locale-specific variants
  /// * Files ending in `.g.dart` (common code generation suffix)
  ///
  /// Parameters:
  /// * [directory] - Root directory to scan
  /// * [excludePatterns] - Additional patterns for file paths to exclude
  ///
  /// Returns a list of Dart source files to analyze.
  List<File> _collectDartFiles(
    Directory directory,
    List<String> excludePatterns,
  ) {
    final List<File> dartFiles = <File>[];

    for (final FileSystemEntity entity in directory.listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;

      // Exclude generated localization files.
      final String fileName = entity.uri.pathSegments.last;
      if (fileName.startsWith('app_localizations')) continue;

      // Exclude common generated file suffixes.
      if (fileName.endsWith('.g.dart')) continue;

      // Check user-provided exclusion patterns.
      final bool isExcluded = excludePatterns.any(
        (pattern) => entity.path.contains(pattern),
      );
      if (isExcluded) continue;

      dartFiles.add(entity);
    }

    return dartFiles;
  }

  /// Determines whether a localization key is referenced in any source file.
  ///
  /// Performs a whole-word regex search for the key name across all provided
  /// file contents. Word boundaries prevent false positives from keys that
  /// are substrings of other identifiers.
  ///
  /// Parameters:
  /// * [key] - The localization key to search for
  /// * [fileContents] - List of Dart source file contents to search
  ///
  /// Returns true if the key appears as a whole word in any file.
  bool _isKeyReferenced(String key, List<String> fileContents) {
    final RegExp pattern = RegExp('\\b${RegExp.escape(key)}\\b');

    for (final String content in fileContents) {
      if (pattern.hasMatch(content)) {
        return true;
      }
    }

    return false;
  }
}
