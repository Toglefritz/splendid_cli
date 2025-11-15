import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../services/l10n_sorter_service.dart';

/// Command-line interface for sorting Flutter localization files.
///
/// This command provides automated sorting of ARB (Application Resource Bundle)
/// files used in Flutter localization. It organizes entries alphabetically by
/// key while maintaining the critical relationship between value entries and
/// their metadata entries (prefixed with @).
///
/// The command operates on individual .arb files or entire directories,
/// intelligently processing only ARB files while preserving JSON structure
/// and formatting.
///
/// Key Features:
/// * Alphabetical sorting by entry keys
/// * Preserves value-metadata pair relationships
/// * Processes single files or entire directories
/// * Dry-run mode for previewing changes without modification
/// * Comprehensive progress reporting and error handling
///
/// Processing Behavior:
/// * Maintains JSON formatting and structure
/// * Keeps @key metadata immediately after key entries
/// * Reports detailed statistics on processed and modified files
/// * Handles invalid JSON and file system errors gracefully
///
/// Usage Examples:
/// ```bash
/// # Sort all .arb files in l10n directory
/// splendid_cli sort-l10n lib/l10n
///
/// # Sort a specific .arb file
/// splendid_cli sort-l10n lib/l10n/app_en.arb
///
/// # Preview changes without modifying files
/// splendid_cli sort-l10n lib/l10n --dry-run
///
/// # Sort with verbose output for detailed progress
/// splendid_cli sort-l10n lib/l10n --verbose
/// ```
///
/// Exit Codes:
/// * `0` - Success: All files processed successfully
/// * `1` - General error: File system error or processing failure
/// * `64` - Usage error: Invalid arguments or missing target (EX_USAGE)
///
/// Performance: Optimized for typical localization file sizes. Processing
/// speed depends on file size and number of entries but is generally
/// instantaneous for standard Flutter projects.
///
/// Thread Safety: Safe to run on different directory trees simultaneously
/// but should not target overlapping file sets concurrently.
class SortL10nCommand extends Command<int> {
  /// Creates a new instance of [SortL10nCommand] with configured argument parser.
  ///
  /// Initializes the command with support for:
  /// * `--dry-run`: Preview mode without file modification
  /// * `--verbose` (-v): Detailed progress and diagnostic output
  SortL10nCommand() {
    argParser
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
  String get description => 'Sort Flutter localization (.arb) files alphabetically by key.';

  /// The command name used for CLI invocation.
  @override
  String get name => 'sort-l10n';

  /// Alternative shorter names for the command.
  @override
  List<String> get aliases => <String>['sort-arb', 'l10n-sort'];

  /// Usage pattern displayed in help text and error messages.
  @override
  String get invocation => 'splendid_cli sort-l10n <target> [arguments]';

  /// Executes the L10n sorting command with parsed command-line arguments.
  ///
  /// This method orchestrates the complete sorting workflow:
  /// 1. Validates command-line arguments and target specification
  /// 2. Configures the sorting service with user preferences
  /// 3. Executes the sorting operation with progress reporting
  /// 4. Displays comprehensive results and statistics
  /// 5. Provides actionable feedback and next steps
  ///
  /// The method handles various error conditions gracefully:
  /// * Missing or invalid target paths
  /// * Invalid file types (non-.arb files)
  /// * File system permission errors
  /// * JSON parsing failures in individual files
  ///
  /// Progress Reporting:
  /// * Real-time file processing updates in verbose mode
  /// * Summary statistics on completion
  /// * Detailed error reporting for failed files
  /// * Clear indication of dry-run vs actual modifications
  ///
  /// Returns:
  /// * `0` on successful completion of all processing
  /// * `1` for unexpected errors during sorting
  /// * `64` for usage errors (missing args, invalid parameters, etc.)
  @override
  Future<int> run() async {
    final Logger logger = Logger();

    // Validate that a target path was provided as a positional argument
    if (argResults!.rest.isEmpty) {
      logger
        ..err('Target path is required.')
        ..info('')
        ..info('Usage: $invocation')
        ..info('')
        ..info('Examples:')
        ..info('  splendid_cli sort-l10n lib/l10n')
        ..info('  splendid_cli sort-l10n lib/l10n/app_en.arb')
        ..info('  splendid_cli sort-l10n lib/l10n --dry-run')
        ..info('')
        ..info(usage);
      return 64;
    }

    /// The target path to process (file or directory).
    ///
    /// Must be a valid file system path pointing to either a single .arb file
    /// or a directory containing .arb files to process.
    final String targetPath = argResults!.rest.first;

    /// Whether to perform a dry run without modifying files.
    ///
    /// When true, the command analyzes files and reports what changes would
    /// be made without actually writing to the file system.
    final bool dryRun = argResults!['dry-run'] as bool;

    /// Whether to show verbose progress and diagnostic information.
    ///
    /// Enables detailed logging of file processing, statistics, and diagnostic
    /// information useful for troubleshooting.
    final bool verbose = argResults!['verbose'] as bool;

    // Configure logger level based on verbose flag
    if (verbose) {
      logger.level = Level.verbose;
    }

    try {
      /// Service instance for performing the sorting operations.
      ///
      /// Encapsulates the business logic for ARB file processing and provides
      /// a clean interface for the command layer.
      const L10nSorterService service = L10nSorterService();

      /// Request configuration for the sorting operation.
      ///
      /// Contains all parameters needed to execute the sorting process
      /// according to user specifications.
      final L10nSorterRequest request = L10nSorterRequest(
        targetPath: targetPath,
        dryRun: dryRun,
      );

      // Display operation summary
      logger
        ..info('${dryRun ? 'Analyzing' : 'Sorting'} localization files...')
        ..info('Target: $targetPath');
      if (dryRun) {
        logger.info('Mode: Dry run (no files will be modified)');
      }
      logger.info('');

      // Execute the sorting operation
      final Progress progress = logger.progress('Processing files');

      /// Result of the sorting operation.
      ///
      /// Contains comprehensive information about processed files,
      /// modifications made, and any errors encountered.
      final L10nSorterResult result = await service.sortL10nFiles(request);

      progress.complete();

      // Display results
      _displayResults(logger, result, verbose);

      // Return appropriate exit code
      return result.success ? 0 : 1;
    } on L10nSorterException catch (e) {
      logger.err('Sorting failed: ${e.message}');
      return _getExitCodeForError(e.type);
    } catch (error) {
      logger.err('Unexpected error: $error');
      return 1;
    }
  }

  /// Displays comprehensive results of the sorting operation.
  ///
  /// Provides detailed feedback about the processing results, including
  /// statistics, file lists, error reports, and actionable next steps.
  ///
  /// The display adapts based on the operation mode (dry-run vs actual)
  /// and verbosity level to provide appropriate detail for the user.
  ///
  /// Parameters:
  /// * [logger] - Logger instance for output formatting
  /// * [result] - Results from the sorting operation
  /// * [verbose] - Whether to show detailed file lists and diagnostics
  void _displayResults(Logger logger, L10nSorterResult result, bool verbose) {
    logger.info('');

    if (result.success) {
      logger.success('✓ Sorting completed successfully');
    } else {
      logger.warn('⚠ Sorting completed with errors');
    }

    logger
      ..info('')
      // Display statistics
      ..info('Statistics:')
      ..info('  Files processed: ${result.totalProcessed}')
      ..info('  Files modified: ${result.totalModified}');
    if (result.hasErrors) {
      logger.info('  Errors: ${result.totalErrors}');
    }

    // Display file lists in verbose mode
    if (verbose && result.processedFiles.isNotEmpty) {
      logger
        ..info('')
        ..info('Processed files:');
      for (final String file in result.processedFiles) {
        final bool wasModified = result.modifiedFiles.contains(file);
        final String status = wasModified ? '✓ modified' : '- unchanged';
        logger.info('  $file ($status)');
      }
    }

    // Display errors if any occurred
    if (result.hasErrors) {
      logger
        ..info('')
        ..err('Errors encountered:');
      for (final String error in result.errors) {
        logger.err('  $error');
      }
    }

    // Display summary and next steps
    logger.info('');

    if (result.dryRun) {
      if (result.hasModifications) {
        logger
          ..info('Dry run complete. ${result.totalModified} files would be modified.')
          ..info('Run without --dry-run to apply changes.');
      } else {
        logger.info('Dry run complete. No files require sorting.');
      }
    } else {
      if (result.hasModifications) {
        logger
          ..info('Sorting applied to ${result.totalModified} files.')
          ..info('')
          ..info('Next steps:')
          ..info('  1. Review the changes in your version control system')
          ..info('  2. Run flutter gen-l10n to regenerate localization classes')
          ..info('  3. Test your app to ensure all strings display correctly');
      } else {
        logger.info('All localization files are already properly sorted.');
      }
    }
  }

  /// Maps sorter error types to appropriate exit codes.
  ///
  /// Provides consistent exit code behavior that follows POSIX conventions
  /// and enables proper error handling in scripts and automation.
  ///
  /// Parameters:
  /// * [errorType] - The type of error that occurred
  ///
  /// Returns:
  /// * Appropriate POSIX exit code for the error type
  int _getExitCodeForError(L10nSorterErrorType errorType) {
    switch (errorType) {
      case L10nSorterErrorType.targetNotFound:
      case L10nSorterErrorType.invalidFileType:
      case L10nSorterErrorType.noFilesFound:
        return 64; // EX_USAGE - Invalid arguments
      case L10nSorterErrorType.permissionDenied:
        return 77; // EX_NOPERM - Permission denied
      case L10nSorterErrorType.unknown:
        return 1; // Generic failure
    }
  }
}
