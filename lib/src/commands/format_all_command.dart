import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../services/comment_formatter_service.dart';
import '../services/dartdoc_formatter_service.dart';

/// Command-line interface for comprehensive Dart file formatting.
///
/// This command provides a unified interface for applying all available formatting operations to Dart files in a single
/// execution. It orchestrates three distinct formatting steps in sequence:
///
/// 1. Dartdoc comment formatting (/// and /** */ comments)
/// 2. Regular comment formatting (// comments)
/// 3. Dart code formatting (via dart format)
///
/// The command operates on individual files or entire directory trees, applying each formatting step in order and
/// reporting comprehensive results for all operations.
///
/// Key Features:
/// * Single command for complete file formatting
/// * Adjustable line length for comment formatting
/// * Dry-run mode for previewing all changes
/// * Comprehensive progress reporting across all steps
/// * Automatic error handling and recovery
///
/// Processing Behavior:
/// * Executes formatters in sequence: Dartdoc → Regular comments → Code
/// * Continues processing even if individual steps encounter errors
/// * Reports detailed statistics for each formatting operation
/// * Skips generated files and build directories automatically
///
/// Usage Examples:
/// ```bash
/// # Format all aspects of files in current directory
/// splendid_cli format .
///
/// # Format a specific file with custom line length
/// splendid_cli format lib/services/api_service.dart --line-length 100
///
/// # Preview all changes without modifying files
/// splendid_cli format lib/ --dry-run
///
/// # Format with verbose output for detailed progress
/// splendid_cli format . --line-length 120 --verbose
/// ```
///
/// Exit Codes:
/// * `0` - Success: All formatting operations completed successfully
/// * `1` - Partial success: Some operations failed but processing completed
/// * `64` - Usage error: Invalid arguments or missing target (EX_USAGE)
///
/// Performance: Processing time depends on file count and size. Typical performance is 50-100 files per second for
/// comment formatting, with dart format adding additional time based on code complexity.
///
/// Thread Safety: Safe to run on different directory trees simultaneously but should not target overlapping file sets
/// concurrently.
class FormatAllCommand extends Command<int> {
  /// Creates a new instance of [FormatAllCommand] with configured argument parser.
  ///
  /// Initializes the command with support for:
  /// * `--line-length` (-l): Target line length for comment wrapping
  /// * `--dry-run`: Preview mode without file modification
  /// * `--verbose` (-v): Detailed progress and diagnostic output
  FormatAllCommand() {
    argParser
      ..addOption(
        'line-length',
        abbr: 'l',
        help: 'Maximum line length for wrapped comment text.',
        defaultsTo: '120',
        valueHelp: 'LENGTH',
      )
      ..addFlag(
        'dry-run',
        help: 'Preview changes without modifying files.',
        negatable: false,
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
  String get description => 'Format Dartdoc comments, regular comments, and Dart code in one command.';

  /// The command name used for CLI invocation.
  @override
  String get name => 'format';

  /// Alternative shorter names for the command.
  @override
  List<String> get aliases => <String>['fmt'];

  /// Usage pattern displayed in help text and error messages.
  @override
  String get invocation => 'splendid_cli format <target> [arguments]';

  /// Executes the comprehensive formatting command with parsed command-line arguments.
  ///
  /// This method orchestrates the complete formatting workflow:
  /// 1. Validates command-line arguments and target specification
  /// 2. Executes Dartdoc comment formatting
  /// 3. Executes regular comment formatting
  /// 4. Executes Dart code formatting
  /// 5. Displays comprehensive results and statistics
  /// 6. Provides actionable feedback and next steps
  ///
  /// The method handles various error conditions gracefully:
  /// * Missing or invalid target paths
  /// * Invalid line length specifications
  /// * File system permission errors
  /// * Processing failures in individual formatting steps
  ///
  /// Progress Reporting:
  /// * Real-time progress updates for each formatting step
  /// * Summary statistics on completion
  /// * Detailed error reporting for failed operations
  /// * Clear indication of dry-run vs actual modifications
  ///
  /// Returns:
  /// * `0` on successful completion of all formatting operations
  /// * `1` if any formatting step encountered errors
  /// * `64` for usage errors (missing args, invalid parameters, etc.)
  @override
  Future<int> run() async {
    final Logger logger = Logger();

    if (argResults!.rest.isEmpty) {
      logger
        ..err('Target path is required.')
        ..info('')
        ..info('Usage: $invocation')
        ..info('')
        ..info('Examples:')
        ..info('  splendid_cli format .')
        ..info('  splendid_cli format lib/services/api_service.dart')
        ..info('  splendid_cli format . --line-length 100 --dry-run')
        ..info('')
        ..info(usage);
      return 64;
    }

    /// The target path to process (file or directory).
    ///
    /// Must be a valid file system path pointing to either a single Dart file or a directory containing Dart files to
    /// process.
    final String targetPath = argResults!.rest.first;

    /// Maximum line length for comment wrapping.
    ///
    /// Parsed from the --line-length argument with validation to ensure it falls within reasonable bounds for code
    /// readability.
    final int lineLength;
    try {
      lineLength = int.parse(argResults!['line-length'] as String);
    } catch (e) {
      logger.err('Invalid line length: ${argResults!['line-length']}. Must be a number.');
      return 64;
    }

    /// Whether to perform a dry run without modifying files.
    ///
    /// When true, the command analyzes files and reports what changes would be made without actually writing to the
    /// file system.
    final bool dryRun = argResults!['dry-run'] as bool;

    /// Whether to show verbose progress and diagnostic information.
    ///
    /// Enables detailed logging of file processing, statistics, and diagnostic information useful for troubleshooting.
    final bool verbose = argResults!['verbose'] as bool;

    if (verbose) {
      logger.level = Level.verbose;
    }

    logger
      ..info('${dryRun ? 'Analyzing' : 'Formatting'} Dart files...')
      ..info('Target: $targetPath')
      ..info('Line length: $lineLength characters');
    if (dryRun) {
      logger.info('Mode: Dry run (no files will be modified)');
    }
    logger.info('');

    bool hasErrors = false;
    int totalFilesProcessed = 0;
    int totalFilesModified = 0;

    try {
      // Step 1: Format Dartdoc comments
      logger.info('Step 1/3: Formatting Dartdoc comments...');
      final Progress dartdocProgress = logger.progress('Processing Dartdoc comments');

      try {
        const DartdocFormatterService dartdocService = DartdocFormatterService();
        final DartdocFormatterRequest dartdocRequest = DartdocFormatterRequest(
          targetPath: targetPath,
          lineLength: lineLength,
          dryRun: dryRun,
        );

        final DartdocFormatterResult dartdocResult = await dartdocService.formatDartdoc(dartdocRequest);
        dartdocProgress.complete();

        totalFilesProcessed = dartdocResult.totalProcessed;
        totalFilesModified += dartdocResult.totalModified;

        if (dartdocResult.hasErrors) {
          hasErrors = true;
          logger.warn('  ⚠ Dartdoc formatting completed with ${dartdocResult.totalErrors} errors');
        } else {
          logger.success('  ✓ Dartdoc comments formatted (${dartdocResult.totalModified} files modified)');
        }
      } catch (e) {
        dartdocProgress.fail();
        logger.err('  ✗ Dartdoc formatting failed: $e');
        hasErrors = true;
      }

      logger.info('');

      // Step 2: Format regular comments
      logger.info('Step 2/3: Formatting regular comments...');
      final Progress commentsProgress = logger.progress('Processing regular comments');

      try {
        const CommentFormatterService commentService = CommentFormatterService();
        final CommentFormatterRequest commentRequest = CommentFormatterRequest(
          targetPath: targetPath,
          lineLength: lineLength,
          dryRun: dryRun,
        );

        final CommentFormatterResult commentResult = await commentService.formatComments(commentRequest);
        commentsProgress.complete();

        totalFilesModified += commentResult.totalModified;

        if (commentResult.hasErrors) {
          hasErrors = true;
          logger.warn('  ⚠ Regular comment formatting completed with ${commentResult.totalErrors} errors');
        } else {
          logger.success('  ✓ Regular comments formatted (${commentResult.totalModified} files modified)');
        }
      } catch (e) {
        commentsProgress.fail();
        logger.err('  ✗ Regular comment formatting failed: $e');
        hasErrors = true;
      }

      logger.info('');

      // Step 3: Format Dart code
      logger.info('Step 3/3: Formatting Dart code...');
      final Progress codeProgress = logger.progress('Running dart format');

      try {
        final List<String> dartFormatArgs = [
          'format',
          if (!dryRun) '--output=write' else '--output=none',
          targetPath,
        ];

        final ProcessResult dartFormatResult = await Process.run(
          'dart',
          dartFormatArgs,
        );

        codeProgress.complete();

        if (dartFormatResult.exitCode == 0) {
          logger.success('  ✓ Dart code formatted');
          if (verbose && dartFormatResult.stdout.toString().isNotEmpty) {
            logger.info('  ${dartFormatResult.stdout}');
          }
        } else {
          hasErrors = true;
          logger.err('  ✗ Dart format failed with exit code ${dartFormatResult.exitCode}');
          if (dartFormatResult.stderr.toString().isNotEmpty) {
            logger.err('  ${dartFormatResult.stderr}');
          }
        }
      } catch (e) {
        codeProgress.fail();
        logger.err('  ✗ Dart format execution failed: $e');
        hasErrors = true;
      }

      logger.info('');

      // Display final summary
      _displaySummary(logger, totalFilesProcessed, totalFilesModified, hasErrors, dryRun);

      return hasErrors ? 1 : 0;
    } catch (error) {
      logger.err('Unexpected error: $error');
      return 1;
    }
  }

  /// Displays comprehensive summary of all formatting operations.
  ///
  /// Provides final statistics and actionable next steps based on the results of all formatting operations.
  ///
  /// Parameters:
  /// * [logger] - Logger instance for output formatting
  /// * [totalProcessed] - Total number of files processed
  /// * [totalModified] - Total number of files modified across all operations
  /// * [hasErrors] - Whether any errors occurred during processing
  /// * [dryRun] - Whether this was a dry-run operation
  void _displaySummary(
    Logger logger,
    int totalProcessed,
    int totalModified,
    bool hasErrors,
    bool dryRun,
  ) {
    if (hasErrors) {
      logger.warn('⚠ Formatting completed with errors');
    } else {
      logger.success('✓ All formatting operations completed successfully');
    }

    logger
      ..info('')
      ..info('Summary:')
      ..info('  Files processed: $totalProcessed')
      ..info('  Files modified: $totalModified');

    logger.info('');

    if (dryRun) {
      if (totalModified > 0) {
        logger
          ..info('Dry run complete. $totalModified files would be modified.')
          ..info('Run without --dry-run to apply changes.');
      } else {
        logger.info('Dry run complete. No files require formatting changes.');
      }
    } else {
      if (totalModified > 0) {
        logger
          ..info('Formatting applied to $totalModified files.')
          ..info('')
          ..info('Next steps:')
          ..info('  1. Review the changes in your version control system')
          ..info('  2. Run your tests to ensure no functionality was affected')
          ..info('  3. Commit the formatting changes');
      } else {
        logger.info('All files are already properly formatted.');
      }
    }
  }
}
