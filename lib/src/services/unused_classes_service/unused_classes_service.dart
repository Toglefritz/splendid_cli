import 'dart:io';

import 'package:path/path.dart' as path;

import 'unused_class_info.dart';
import 'unused_classes_error_type.dart';
import 'unused_classes_exception.dart';
import 'unused_classes_request.dart';
import 'unused_classes_result.dart';

/// Service for detecting unused class declarations in a Dart project.
///
/// This service scans a directory of Dart source files, identifies all class
/// declarations, and then checks whether each class is referenced in any other
/// file within the scanned directory. A class is considered "unused" if its
/// name does not appear in any other Dart file in the project.
///
/// Detection Strategy:
/// * Class declarations are identified using a regex that matches `class`,
///   `abstract class`, `sealed class`, `final class`, `base class`, and
///   `mixin class` keywords.
/// * A class is considered "referenced" if its name appears as a whole word
///   in any other Dart file. This includes usage via imports, type annotations,
///   instantiation, extension, or mixin application.
/// * The detection is text-based and intentionally conservative—it may produce
///   false negatives (miss truly unused classes) if the class name appears in
///   comments or strings in other files. This is a reasonable tradeoff for a
///   lightweight analysis that does not require a full Dart AST.
///
/// Limitations:
/// * Classes referenced only via reflection or code generation pipelines may
///   be reported as unused.
/// * Entry-point classes (e.g., the `main()` file's widget) that are not
///   imported elsewhere will appear as unused—users should apply judgment.
/// * Classes exported from a package's public API that are consumed by
///   external packages will appear unused within the scanned directory.
///
/// Thread Safety: This service performs file I/O operations and is not
/// thread-safe for concurrent operations on the same directory tree.
class UnusedClassesService {
  /// Creates a new instance of [UnusedClassesService].
  const UnusedClassesService();

  /// Scans the target directory for unused class declarations.
  ///
  /// Reads all `.dart` files in the target directory (recursively), extracts
  /// class declarations, and identifies classes that are not referenced in
  /// any other file.
  ///
  /// Parameters:
  /// * [request] - Configuration for the detection operation
  ///
  /// Returns an [UnusedClassesResult] containing statistics and findings.
  ///
  /// Throws [UnusedClassesException] for critical errors like missing targets
  /// or invalid paths.
  Future<UnusedClassesResult> findUnusedClasses(
    UnusedClassesRequest request,
  ) async {
    final Directory targetDir = Directory(request.targetPath);

    if (!targetDir.existsSync()) {
      throw UnusedClassesException(
        'Target path does not exist: ${request.targetPath}',
        UnusedClassesErrorType.targetNotFound,
      );
    }

    if (!FileSystemEntity.isDirectorySync(request.targetPath)) {
      throw UnusedClassesException(
        'Target path is not a directory: ${request.targetPath}',
        UnusedClassesErrorType.invalidTarget,
      );
    }

    final List<String> errors = <String>[];

    try {
      final List<File> dartFiles = _collectDartFiles(
        targetDir,
        request.excludePatterns,
      );

      if (dartFiles.isEmpty) {
        throw const UnusedClassesException(
          'No Dart files found in the target directory',
          UnusedClassesErrorType.noDartFilesFound,
        );
      }

      // Read all file contents into memory for cross-referencing.
      final Map<String, String> fileContents = <String, String>{};
      for (final File file in dartFiles) {
        try {
          fileContents[file.path] = await file.readAsString();
        } catch (e) {
          errors.add('Failed to read ${file.path}: $e');
        }
      }

      // Extract all class declarations with their file locations.
      final List<UnusedClassInfo> allClasses = <UnusedClassInfo>[];
      for (final MapEntry<String, String> entry in fileContents.entries) {
        final List<String> classNames = _extractClassNames(entry.value);
        final String relativePath = path.relative(
          entry.key,
          from: request.targetPath,
        );
        for (final String className in classNames) {
          allClasses.add(
            UnusedClassInfo(className: className, filePath: relativePath),
          );
        }
      }

      // Identify unused classes by checking for references in other files.
      final List<UnusedClassInfo> unusedClasses = <UnusedClassInfo>[];
      for (final UnusedClassInfo classInfo in allClasses) {
        final bool isReferenced = _isClassReferenced(
          classInfo.className,
          classInfo.filePath,
          fileContents,
          request.targetPath,
        );
        if (!isReferenced) {
          unusedClasses.add(classInfo);
        }
      }

      // Sort results alphabetically by file path, then class name.
      unusedClasses.sort((a, b) {
        final int pathCompare = a.filePath.compareTo(b.filePath);
        if (pathCompare != 0) return pathCompare;
        return a.className.compareTo(b.className);
      });

      return UnusedClassesResult(
        targetPath: request.targetPath,
        filesScanned: fileContents.length,
        totalClasses: allClasses.length,
        unusedClasses: unusedClasses,
        errors: errors,
      );
    } catch (e) {
      if (e is UnusedClassesException) rethrow;
      errors.add(e.toString());

      return UnusedClassesResult(
        targetPath: request.targetPath,
        filesScanned: 0,
        totalClasses: 0,
        unusedClasses: const <UnusedClassInfo>[],
        errors: errors,
      );
    }
  }

  /// Recursively collects all `.dart` files in [directory], excluding files
  /// that match any of the provided [excludePatterns].
  ///
  /// Parameters:
  /// * [directory] - Root directory to scan
  /// * [excludePatterns] - Patterns for file paths to exclude
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

      // Check exclusion patterns.
      final bool isExcluded = excludePatterns.any(
        (pattern) => entity.path.contains(pattern),
      );
      if (isExcluded) continue;

      dartFiles.add(entity);
    }

    return dartFiles;
  }

  /// Extracts class names from Dart source content.
  ///
  /// Identifies declarations using `class`, `abstract class`, `sealed class`,
  /// `final class`, `base class`, and `mixin class` keywords. Ignores class
  /// names that appear inside comments or string literals by pre-stripping
  /// comments from the content before matching.
  ///
  /// Parameters:
  /// * [content] - Dart source file content
  ///
  /// Returns a list of class names declared in the file.
  List<String> _extractClassNames(String content) {
    // Strip single-line and doc comments to avoid matching inside them.
    final String stripped = content
        .replaceAll(RegExp(r'///[^\n]*'), '')
        .replaceAll(RegExp(r'//[^\n]*'), '')
        .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');

    final RegExp classPattern = RegExp(
      r'(?:^|\n)\s*(?:abstract\s+|sealed\s+|final\s+|base\s+|mixin\s+)*class\s+(\w+)',
      multiLine: true,
    );

    final List<String> classNames = <String>[];
    for (final RegExpMatch match in classPattern.allMatches(stripped)) {
      final String? name = match.group(1);
      if (name != null && !name.startsWith('_')) {
        classNames.add(name);
      }
    }

    return classNames;
  }

  /// Determines whether a class is referenced in any file other than its own.
  ///
  /// Performs a whole-word search for the class name across all file contents
  /// except the file where the class is declared. A word-boundary match avoids
  /// false positives from class names that are substrings of other identifiers.
  ///
  /// Parameters:
  /// * [className] - The class name to search for
  /// * [declaringFilePath] - Relative path of the file declaring this class
  /// * [fileContents] - Map of absolute file paths to their contents
  /// * [basePath] - Base directory path for computing relative paths
  ///
  /// Returns true if the class name appears in any other file.
  bool _isClassReferenced(
    String className,
    String declaringFilePath,
    Map<String, String> fileContents,
    String basePath,
  ) {
    final RegExp referencePattern = RegExp(
      '\\b${RegExp.escape(className)}\\b',
    );

    for (final MapEntry<String, String> entry in fileContents.entries) {
      final String relativePath = path.relative(entry.key, from: basePath);

      // Skip the file where the class is declared.
      if (relativePath == declaringFilePath) continue;

      if (referencePattern.hasMatch(entry.value)) {
        return true;
      }
    }

    return false;
  }
}
