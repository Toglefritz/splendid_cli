import 'dart:io';

/// Service for reformatting and rewrapping regular comments in Dart files.
///
/// This service handles the business logic for processing regular // comments,
/// including line length adjustment, proper wrapping, and preservation of
/// formatting elements like code blocks and lists. It operates on individual
/// files or entire directory trees while maintaining the original file
/// structure.
///
/// The service supports:
/// * Adjusting line length to any specified length (40-200 characters)
/// * Preserving code blocks, lists, and other special formatting
/// * Processing single files or entire directory trees
/// * Maintaining proper indentation and comment structure
/// * Handling // style comments (not /// Dartdoc or /** */ block comments)
///
/// Key Features:
/// * Intelligent line wrapping that respects word boundaries
/// * Preservation of markdown formatting within comments
/// * Support for nested comment structures
/// * Configurable line length limits
/// * Dry-run mode for preview without modification
///
/// Performance: Processing is optimized for large codebases with minimal memory
/// usage and efficient file I/O operations.
class CommentFormatterService {
  /// Creates a new comment formatter service instance.
  const CommentFormatterService();

  /// Formats regular comments in a single file or directory tree.
  ///
  /// This method processes the specified target (file or directory) and
  /// reformats all regular comments according to the specified line length. It
  /// handles both single files and recursive directory processing.
  ///
  /// Processing workflow:
  /// 1. Validates the target path exists and is accessible
  /// 2. Determines if target is a file or directory
  /// 3. For directories: recursively finds all .dart files
  /// 4. For each file: analyzes and reformats regular comments
  /// 5. Writes updated content back to files (unless dry-run mode)
  /// 6. Returns summary of changes made
  ///
  /// Parameters:
  /// * [request] - Configuration for the formatting operation
  ///
  /// Returns:
  /// * [CommentFormatterResult] with processing summary and statistics
  ///
  /// Throws:
  /// * [CommentFormatterException] for various failure scenarios
  Future<CommentFormatterResult> formatComments(CommentFormatterRequest request) async {
    try {
      _validateRequest(request);

      final List<String> processedFiles = [];
      final List<String> modifiedFiles = [];
      final List<String> errors = [];

      final List<File> dartFiles = await _findDartFiles(request.targetPath);

      for (final File file in dartFiles) {
        try {
          final bool wasModified = await _processFile(file, request);
          processedFiles.add(file.path);

          if (wasModified) {
            modifiedFiles.add(file.path);
          }
        } catch (e) {
          errors.add('${file.path}: $e');
        }
      }

      return CommentFormatterResult.success(
        processedFiles: processedFiles,
        modifiedFiles: modifiedFiles,
        errors: errors,
        lineLength: request.lineLength,
        dryRun: request.dryRun,
      );
    } catch (e) {
      if (e is CommentFormatterException) {
        rethrow;
      }
      throw CommentFormatterException(
        'Failed to format comments: $e',
        CommentFormatterErrorType.unknown,
        cause: e,
      );
    }
  }

  /// Validates the formatting request parameters.
  ///
  /// Ensures that all required parameters are valid and the target path exists
  /// and is accessible for processing.
  void _validateRequest(CommentFormatterRequest request) {
    if (request.lineLength < 40 || request.lineLength > 200) {
      throw const CommentFormatterException(
        'Line length must be between 40 and 200 characters',
        CommentFormatterErrorType.invalidLineLength,
      );
    }

    final FileSystemEntity target = FileSystemEntity.typeSync(request.targetPath) == FileSystemEntityType.file
        ? File(request.targetPath)
        : Directory(request.targetPath);

    if (!target.existsSync()) {
      throw CommentFormatterException(
        'Target path does not exist: ${request.targetPath}',
        CommentFormatterErrorType.targetNotFound,
      );
    }
  }

  /// Finds all Dart files in the target path.
  ///
  /// For file targets, returns a single-item list. For directory targets,
  /// recursively searches for all .dart files while respecting common ignore
  /// patterns (build/, .dart_tool/, etc.).
  Future<List<File>> _findDartFiles(String targetPath) async {
    final FileSystemEntityType entityType = FileSystemEntity.typeSync(targetPath);

    if (entityType == FileSystemEntityType.file) {
      final File file = File(targetPath);
      if (!file.path.endsWith('.dart')) {
        throw const CommentFormatterException(
          'Target file must be a Dart file (.dart extension)',
          CommentFormatterErrorType.invalidFileType,
        );
      }
      return [file];
    }

    if (entityType == FileSystemEntityType.directory) {
      final Directory directory = Directory(targetPath);
      final List<File> dartFiles = [];

      await for (final FileSystemEntity entity in directory.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          if (_shouldSkipFile(entity.path)) {
            continue;
          }
          dartFiles.add(entity);
        }
      }

      return dartFiles;
    }

    throw CommentFormatterException(
      'Target path must be a file or directory: $targetPath',
      CommentFormatterErrorType.invalidTarget,
    );
  }

  /// Determines if a file should be skipped during processing.
  ///
  /// Skips files in common build and tool directories that typically contain
  /// generated code or temporary files.
  bool _shouldSkipFile(String filePath) {
    final List<String> skipPatterns = [
      '.dart_tool/',
      'build/',
      '.packages',
      'pubspec.lock',
    ];

    return skipPatterns.any((String pattern) => filePath.contains(pattern));
  }

  /// Processes a single Dart file for regular comment formatting.
  ///
  /// Reads the file content, identifies and reformats regular comments, and
  /// writes the updated content back to the file (unless in dry-run mode).
  ///
  /// Returns true if the file was modified, false otherwise.
  Future<bool> _processFile(File file, CommentFormatterRequest request) async {
    final String originalContent = await file.readAsString();
    final String formattedContent = _formatCommentsInContent(originalContent, request.lineLength);

    final bool wasModified = originalContent != formattedContent;

    if (wasModified && !request.dryRun) {
      await file.writeAsString(formattedContent);
    }

    return wasModified;
  }

  /// Formats regular comments within file content.
  ///
  /// This method processes the entire file content and reformats all regular
  /// comments according to the specified line length while preserving code
  /// structure and non-comment content.
  String _formatCommentsInContent(String content, int lineLength) {
    final List<String> lines = content.split('\n');
    final List<String> formattedLines = [];

    int i = 0;
    while (i < lines.length) {
      final String line = lines[i];

      if (_isRegularCommentStart(line)) {
        final CommentBlock block = _extractCommentBlock(lines, i);
        final List<String> reformattedBlock = _reformatCommentBlock(block, lineLength);
        formattedLines.addAll(reformattedBlock);
        i += block.lineCount;
      } else {
        formattedLines.add(line);
        i++;
      }
    }

    return formattedLines.join('\n');
  }

  /// Checks if a line starts a regular comment (not Dartdoc).
  ///
  /// Recognizes // comments but excludes /// Dartdoc comments, accounting for
  /// leading whitespace that should be preserved.
  bool _isRegularCommentStart(String line) {
    final String trimmed = line.trimLeft();
    return trimmed.startsWith('//') && !trimmed.startsWith('///');
  }

  /// Extracts a complete regular comment block from the lines.
  ///
  /// Identifies consecutive // comment lines that form a logical block.
  CommentBlock _extractCommentBlock(List<String> lines, int startIndex) {
    final String firstLine = lines[startIndex];
    final String leadingWhitespace = _getLeadingWhitespace(firstLine);
    final List<String> blockLines = [];
    int currentIndex = startIndex;

    while (currentIndex < lines.length) {
      final String line = lines[currentIndex];
      final String trimmed = line.trimLeft();

      if (!trimmed.startsWith('//') || trimmed.startsWith('///')) {
        break;
      }

      blockLines.add(line);
      currentIndex++;
    }

    return CommentBlock(
      lines: blockLines,
      lineCount: currentIndex - startIndex,
      leadingWhitespace: leadingWhitespace,
    );
  }

  /// Gets the leading whitespace from a line.
  ///
  /// Preserves the original indentation level for proper code formatting.
  String _getLeadingWhitespace(String line) {
    final RegExp leadingWhitespacePattern = RegExp(r'^(\s*)');
    final Match? match = leadingWhitespacePattern.firstMatch(line);
    return match?.group(1) ?? '';
  }

  /// Reformats a regular comment block to the specified line length.
  ///
  /// This method handles the core formatting logic, including:
  /// * Intelligent line wrapping at word boundaries
  /// * Preservation of code blocks and special formatting
  /// * Proper handling of lists and nested structures
  /// * Maintenance of comment syntax and indentation
  List<String> _reformatCommentBlock(CommentBlock block, int lineLength) {
    final List<String> contentLines = [];

    for (final String line in block.lines) {
      final String content = line.replaceFirst(RegExp(r'^\s*//\s*'), '');
      contentLines.add(content);
    }

    final List<String> wrappedContent = _wrapCommentContent(
      contentLines,
      lineLength - block.leadingWhitespace.length - 3,
    );

    final List<String> result = [];
    for (final String contentLine in wrappedContent) {
      if (contentLine.isEmpty) {
        result.add('${block.leadingWhitespace}//');
      } else {
        result.add('${block.leadingWhitespace}// $contentLine');
      }
    }

    return result;
  }

  /// Wraps comment content to the specified line length.
  ///
  /// This method handles the intelligent wrapping of comment text while
  /// preserving special formatting like code blocks, lists, and paragraphs.
  List<String> _wrapCommentContent(List<String> contentLines, int maxLength) {
    final List<String> result = [];
    final List<String> currentParagraph = [];
    bool inCodeBlock = false;

    for (final String line in contentLines) {
      if (line.trim().startsWith('```')) {
        if (currentParagraph.isNotEmpty) {
          result.addAll(_wrapParagraph(currentParagraph, maxLength));
          currentParagraph.clear();
        }

        result.add(line);
        inCodeBlock = !inCodeBlock;
        continue;
      }

      if (inCodeBlock) {
        result.add(line);
        continue;
      }

      if (_isSpecialFormattingLine(line)) {
        if (currentParagraph.isNotEmpty) {
          result.addAll(_wrapParagraph(currentParagraph, maxLength));
          currentParagraph.clear();
        }

        result.add(line);
        continue;
      }

      if (line.trim().isEmpty) {
        if (currentParagraph.isNotEmpty) {
          result.addAll(_wrapParagraph(currentParagraph, maxLength));
          currentParagraph.clear();
        }
        result.add('');
        continue;
      }

      currentParagraph.add(line);
    }

    if (currentParagraph.isNotEmpty) {
      result.addAll(_wrapParagraph(currentParagraph, maxLength));
    }

    return result;
  }

  /// Checks if a line contains special formatting that shouldn't be wrapped.
  ///
  /// Identifies lines that should be preserved as-is, such as:
  /// * List items (*, -, +, numbered)
  /// * Headers (# ## ###)
  /// * Code examples with indentation
  /// * Special documentation tags
  /// * Linter ignore directives (ignore: and ignore_for_file:)
  bool _isSpecialFormattingLine(String line) {
    final String trimmed = line.trim();

    if (RegExp(r'^\s*[\*\-\+]\s').hasMatch(line) || RegExp(r'^\s*\d+\.\s').hasMatch(line)) {
      return true;
    }

    if (trimmed.startsWith('#')) {
      return true;
    }

    if (line.startsWith('    ') || line.startsWith('\t')) {
      return true;
    }

    if (trimmed.startsWith('@') ||
        trimmed.startsWith('Parameters:') ||
        trimmed.startsWith('Returns:') ||
        trimmed.startsWith('Throws:')) {
      return true;
    }

    // Linter ignore directives must stay on their own line to function
    // correctly. Wrapping them onto other lines breaks the ignore syntax.
    if (trimmed.startsWith('ignore:') || trimmed.startsWith('ignore_for_file:')) {
      return true;
    }

    return false;
  }

  /// Wraps a paragraph of text to the specified maximum line length.
  ///
  /// Performs intelligent word wrapping that respects word boundaries and
  /// maintains readability while fitting within the specified length.
  List<String> _wrapParagraph(List<String> paragraphLines, int maxLength) {
    final String fullText = paragraphLines.join(' ').trim();

    if (fullText.isEmpty) {
      return [''];
    }

    final List<String> result = [];
    final List<String> words = fullText.split(RegExp(r'\s+'));
    final StringBuffer currentLine = StringBuffer();

    for (final String word in words) {
      final String testLine = currentLine.isEmpty ? word : '$currentLine $word';

      if (testLine.length <= maxLength) {
        if (currentLine.isNotEmpty) {
          currentLine.write(' ');
        }
        currentLine.write(word);
      } else {
        if (currentLine.isNotEmpty) {
          result.add(currentLine.toString());
          currentLine.clear();
        }
        currentLine.write(word);
      }
    }

    if (currentLine.isNotEmpty) {
      result.add(currentLine.toString());
    }

    return result.isEmpty ? [''] : result;
  }
}

/// Represents a block of regular comments extracted from source code.
///
/// This class encapsulates the structure and metadata of a comment block,
/// including its content and positioning information needed for proper
/// reformatting.
class CommentBlock {
  /// Creates a new regular comment block.
  const CommentBlock({
    required this.lines,
    required this.lineCount,
    required this.leadingWhitespace,
  });

  /// The lines that make up this comment block.
  ///
  /// Includes the original comment syntax and formatting, which will be
  /// processed during reformatting operations.
  final List<String> lines;

  /// The number of lines this block spans in the original file.
  ///
  /// Used for advancing the line parser after processing this block.
  final int lineCount;

  /// The leading whitespace that should be preserved for indentation.
  ///
  /// Maintains the original indentation level of the comment block to preserve
  /// code structure and formatting.
  final String leadingWhitespace;
}

/// Request configuration for comment formatting operations.
///
/// This class encapsulates all parameters needed to configure the formatting
/// process, including target specification, line length preferences, and
/// processing options.
class CommentFormatterRequest {
  /// Creates a new comment formatter request.
  const CommentFormatterRequest({
    required this.targetPath,
    this.lineLength = 120,
    this.dryRun = false,
  });

  /// Path to the file or directory to process.
  ///
  /// Can be either a single .dart file or a directory containing Dart files to
  /// process recursively.
  final String targetPath;

  /// Maximum line length for wrapped comment text.
  ///
  /// Comments will be reformatted to fit within this character limit while
  /// respecting word boundaries and special formatting.
  final int lineLength;

  /// Whether to perform a dry run without modifying files.
  ///
  /// When true, the service will analyze and report what changes would be made
  /// without actually writing to files.
  final bool dryRun;
}

/// Result of a comment formatting operation.
///
/// This class contains comprehensive information about the formatting process,
/// including statistics, file lists, and any errors encountered during
/// processing.
class CommentFormatterResult {
  /// Creates a new comment formatter result.
  const CommentFormatterResult({
    required this.success,
    required this.processedFiles,
    required this.modifiedFiles,
    required this.errors,
    required this.lineLength,
    required this.dryRun,
  });

  /// Creates a successful formatting result.
  const CommentFormatterResult.success({
    required List<String> processedFiles,
    required List<String> modifiedFiles,
    required List<String> errors,
    required int lineLength,
    required bool dryRun,
  }) : this(
         success: true,
         processedFiles: processedFiles,
         modifiedFiles: modifiedFiles,
         errors: errors,
         lineLength: lineLength,
         dryRun: dryRun,
       );

  /// Creates a failed formatting result.
  const CommentFormatterResult.failure({
    required List<String> processedFiles,
    required List<String> modifiedFiles,
    required List<String> errors,
    required int lineLength,
    required bool dryRun,
  }) : this(
         success: false,
         processedFiles: processedFiles,
         modifiedFiles: modifiedFiles,
         errors: errors,
         lineLength: lineLength,
         dryRun: dryRun,
       );

  /// Whether the overall operation was successful.
  ///
  /// True if all files were processed without critical errors, false if the
  /// operation failed or was aborted.
  final bool success;

  /// List of all files that were processed.
  ///
  /// Includes both modified and unmodified files that were analyzed during the
  /// formatting operation.
  final List<String> processedFiles;

  /// List of files that were actually modified.
  ///
  /// Subset of processedFiles that contained comments requiring reformatting
  /// according to the specified criteria.
  final List<String> modifiedFiles;

  /// List of error messages encountered during processing.
  ///
  /// Each error includes the file path and description of the issue that
  /// prevented successful processing.
  final List<String> errors;

  /// The line length that was used for formatting.
  ///
  /// Reflects the actual line length parameter that was applied during the
  /// formatting process.
  final int lineLength;

  /// Whether this was a dry run operation.
  ///
  /// Indicates whether files were actually modified or just analyzed for
  /// potential changes.
  final bool dryRun;

  /// Gets the total number of files processed.
  int get totalProcessed => processedFiles.length;

  /// Gets the total number of files modified.
  int get totalModified => modifiedFiles.length;

  /// Gets the total number of errors encountered.
  int get totalErrors => errors.length;

  /// Whether any files were modified during processing.
  bool get hasModifications => modifiedFiles.isNotEmpty;

  /// Whether any errors occurred during processing.
  bool get hasErrors => errors.isNotEmpty;
}

/// Exception thrown by comment formatter service operations.
///
/// This exception provides structured error information for various failure
/// scenarios that can occur during comment formatting operations.
class CommentFormatterException implements Exception {
  /// Creates a new comment formatter exception.
  const CommentFormatterException(
    this.message,
    this.type, {
    this.cause,
  });

  /// Human-readable error message describing the failure.
  ///
  /// Provides clear information about what went wrong and potential steps for
  /// resolution when applicable.
  final String message;

  /// The specific type of error that occurred.
  ///
  /// Categorizes the error for programmatic handling and appropriate user
  /// feedback.
  final CommentFormatterErrorType type;

  /// Optional underlying cause of this exception.
  ///
  /// Preserves the original exception when this error wraps another exception
  /// for debugging and logging purposes.
  final Object? cause;

  @override
  String toString() => 'CommentFormatterException: $message';
}

/// Types of errors that can occur during comment formatting operations.
///
/// This enumeration categorizes the various failure modes to enable appropriate
/// error handling and user feedback.
enum CommentFormatterErrorType {
  /// The specified target path does not exist.
  targetNotFound,

  /// The target is neither a file nor a directory.
  invalidTarget,

  /// The specified file is not a Dart file.
  invalidFileType,

  /// The specified line length is outside valid bounds.
  invalidLineLength,

  /// File system permission denied.
  permissionDenied,

  /// Unknown or unexpected error occurred.
  unknown,
}
