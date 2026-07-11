import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../services/unused_classes_service.dart';

/// Command-line interface for detecting unused class declarations in a Dart
/// project.
///
/// This command scans a directory of Dart source files, identifies all class
/// declarations, and reports classes that are not referenced in any other file.
/// It is designed to help identify abandoned or dead code that may have been
/// created during past development but is no longer in use.
///
/// Key Features:
/// * Recursive scanning of Dart source files
/// * Whole-word matching to avoid false positives from substring collisions
/// * Support for all class modifiers (abstract, sealed, final, base, mixin)
/// * Exclusion patterns for generated or vendored files
/// * Sorted output grouped by file path
///
/// Detection Behavior:
/// * A class is considered "unused" if its name does not appear as a whole
///   word in any other Dart file within the scanned directory.
/// * The scan is text-based and may produce false positives for classes
///   referenced only via reflection, code generation, or external packages.
/// * Entry-point classes and publicly exported API classes may appear in
///   results—users should apply judgment when reviewing findings.
///
/// Usage Examples:
/// ```bash
/// # Scan the lib/ directory for unused classes
/// splendid_cli unused-classes lib/
///
/// # Exclude generated files from the scan
/// splendid_cli unused-classes lib/ --exclude=.g.dart --exclude=.freezed.dart
///
/// # Scan with verbose output
/// splendid_cli unused-classes lib/ --verbose
/// ```
///
/// Exit Codes:
/// * `0` - Success: Scan completed (even if unused classes were found)
/// * `1` - General error: File system error or processing failure
/// * `64` - Usage error: Invalid arguments or missing target (EX_USAGE)
class UnusedClassesCommand extends Command<int> {
  /// Creates a new instance of [UnusedClassesCommand] with configured argument
  /// parser.
  ///
  /// Initializes the command with support for:
  /// * `--exclude`: Patterns for files to skip (repeatable)
  /// * `--verbose` (-v): Detailed progress and diagnostic output
  UnusedClassesCommand() {
    argParser
      ..addMultiOption(
        'exclude',
        abbr: 'e',
        help: 'File path patterns to exclude from scanning (repeatable).',
        valueHelp: 'pattern',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Show detailed progress and diagnostic information.',
        negatable: false,
      );
  }

  /// Brief description of the command's purpose for help text.
  @override
  String get description =>
      'Identify class declarations that are not referenced elsewhere in the '
      'project.';

  /// The command name used for CLI invocation.
  @override
  String get name => 'unused-classes';

  /// Alternative shorter names for the command.
  @override
  List<String> get aliases => <String>['dead-classes'];

  /// Usage pattern displayed in help text and error messages.
  @override
  String get invocation => 'splendid_cli unused-classes <directory> [arguments]';

  /// Executes the unused class detection command with parsed command-line
  /// arguments.
  ///
  /// This method orchestrates the detection workflow:
  /// 1. Validates command-line arguments and target specification
  /// 2. Configures the detection service with user preferences
  /// 3. Executes the scanning operation with progress reporting
  /// 4. Displays comprehensive results grouped by file
  ///
  /// Returns:
  /// * `0` on successful completion
  /// * `1` for unexpected errors during scanning
  /// * `64` for usage errors (missing args, invalid parameters, etc.)
  @override
  Future<int> run() async {
    final Logger logger = Logger();

    // Validate that a target path was provided as a positional argument.
    if (argResults!.rest.isEmpty) {
      logger
        ..err('Target directory path is required.')
        ..info('')
        ..info('Usage: $invocation')
        ..info('')
        ..info('Examples:')
        ..info('  splendid_cli unused-classes lib/')
        ..info(
          '  splendid_cli unused-classes lib/ --exclude=.g.dart',
        )
        ..info('')
        ..info(usage);
      return 64;
    }

    /// The target directory to scan.
    final String targetPath = argResults!.rest.first;

    /// Patterns for files to exclude from scanning.
    final List<String> excludePatterns = argResults!['exclude'] as List<String>;

    /// Whether to show verbose progress and diagnostic information.
    final bool verbose = argResults!['verbose'] as bool;

    if (verbose) {
      logger.level = Level.verbose;
    }

    try {
      const UnusedClassesService service = UnusedClassesService();

      final UnusedClassesRequest request = UnusedClassesRequest(
        targetPath: targetPath,
        excludePatterns: excludePatterns,
      );

      logger
        ..info('Scanning for unused classes...')
        ..info('Target: $targetPath');

      if (excludePatterns.isNotEmpty) {
        logger.info('Excluding: ${excludePatterns.join(', ')}');
      }
      logger.info('');

      final Progress progress = logger.progress('Analyzing classes');
      final UnusedClassesResult result = await service.findUnusedClasses(request);
      progress.complete();

      _displayResults(logger, result, verbose);

      return result.success ? 0 : 1;
    } on UnusedClassesException catch (e) {
      logger.err('Detection failed: ${e.message}');
      return _getExitCodeForError(e.type);
    } catch (error) {
      logger.err('Unexpected error: $error');
      return 1;
    }
  }

  /// Displays comprehensive results of the unused class detection.
  ///
  /// Groups unused classes by file path for readability and includes summary
  /// statistics.
  ///
  /// Parameters:
  /// * [logger] - Logger instance for output formatting
  /// * [result] - Results from the detection operation
  /// * [verbose] - Whether to show detailed diagnostics
  void _displayResults(
    Logger logger,
    UnusedClassesResult result,
    bool verbose,
  ) {
    if (result.hasErrors) {
      logger
        ..info('')
        ..warn('⚠ Scan completed with errors')
        ..info('');
      for (final String error in result.errors) {
        logger.err('  $error');
      }
      logger.info('');
    } else {
      logger.info('');
    }

    logger
      ..info('Statistics:')
      ..info('  Files scanned: ${result.filesScanned}')
      ..info('  Classes found: ${result.totalClasses}')
      ..info(
        '  Unused classes: ${result.unusedClasses.length}',
      )
      ..info('');

    if (result.hasUnusedClasses) {
      logger
        ..info('Potentially unused classes:')
        ..info('');

      // Group by file path for readability.
      String currentFile = '';
      for (final UnusedClassInfo classInfo in result.unusedClasses) {
        if (classInfo.filePath != currentFile) {
          currentFile = classInfo.filePath;
          logger.info('  $currentFile');
        }
        logger.info('    • ${classInfo.className}');
      }

      logger
        ..info('')
        ..info(
          'Note: Review these results manually. Classes used via '
          'reflection, code generation, or external packages may appear '
          'as false positives.',
        );
    } else {
      logger.success('✓ No unused classes detected.');
    }
  }

  /// Maps detection error types to appropriate exit codes.
  ///
  /// Parameters:
  /// * [errorType] - The type of error that occurred
  ///
  /// Returns appropriate POSIX exit code for the error type.
  int _getExitCodeForError(UnusedClassesErrorType errorType) {
    switch (errorType) {
      case UnusedClassesErrorType.targetNotFound:
      case UnusedClassesErrorType.invalidTarget:
      case UnusedClassesErrorType.noDartFilesFound:
        return 64;
      case UnusedClassesErrorType.permissionDenied:
        return 77;
      case UnusedClassesErrorType.unknown:
        return 1;
    }
  }
}
