import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../services/enum_sorter_service.dart';

/// Command-line interface for sorting Dart enum values alphabetically.
///
/// This command processes a Dart source file and reorders the values within
/// each enum declaration alphabetically by name. It handles both simple enums
/// (plain value lists) and enhanced enums (with fields, constructors, and
/// methods), preserving all syntax, documentation comments, and member
/// declarations.
///
/// Key Features:
/// * Alphabetical sorting of enum values by name
/// * Preserves documentation comments on individual values
/// * Handles enhanced enums with constructor arguments and members
/// * Dry-run mode for previewing changes without modification
/// * Processes all enum declarations within a single file
///
/// Processing Behavior:
/// * Only enum value declarations are reordered
/// * Fields, constructors, and methods after the semicolon are untouched
/// * Trailing punctuation (comma vs semicolon) is preserved correctly
/// * Already-sorted enums are left unchanged
///
/// Usage Examples:
/// ```bash
/// # Sort enums in a Dart file
/// splendid_cli sort-enum lib/models/status.dart
///
/// # Preview changes without modifying the file
/// splendid_cli sort-enum lib/models/status.dart --dry-run
///
/// # Sort with verbose output
/// splendid_cli sort-enum lib/models/status.dart --verbose
/// ```
///
/// Exit Codes:
/// * `0` - Success: All enums processed successfully
/// * `1` - General error: File system error or processing failure
/// * `64` - Usage error: Invalid arguments or missing target (EX_USAGE)
///
/// Performance: Instantaneous for typical Dart source files.
class SortEnumCommand extends Command<int> {
  /// Creates a new instance of [SortEnumCommand] with configured argument
  /// parser.
  ///
  /// Initializes the command with support for:
  /// * `--dry-run`: Preview mode without file modification
  /// * `--verbose` (-v): Detailed progress and diagnostic output
  SortEnumCommand() {
    argParser
      ..addFlag(
        'dry-run',
        help: 'Preview changes without modifying the file.',
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
  String get description => 'Sort Dart enum values alphabetically by name.';

  /// The command name used for CLI invocation.
  @override
  String get name => 'sort-enum';

  /// Alternative shorter names for the command.
  @override
  List<String> get aliases => <String>['enum-sort'];

  /// Usage pattern displayed in help text and error messages.
  @override
  String get invocation => 'splendid_cli sort-enum <dart_file> [arguments]';

  /// Executes the enum sorting command with parsed command-line arguments.
  ///
  /// This method orchestrates the complete sorting workflow:
  /// 1. Validates command-line arguments and target specification
  /// 2. Configures the sorting service with user preferences
  /// 3. Executes the sorting operation with progress reporting
  /// 4. Displays comprehensive results and statistics
  ///
  /// Returns:
  /// * `0` on successful completion
  /// * `1` for unexpected errors during sorting
  /// * `64` for usage errors (missing args, invalid parameters, etc.)
  @override
  Future<int> run() async {
    final Logger logger = Logger();

    // Validate that a target path was provided as a positional argument.
    if (argResults!.rest.isEmpty) {
      logger
        ..err('Target Dart file path is required.')
        ..info('')
        ..info('Usage: $invocation')
        ..info('')
        ..info('Examples:')
        ..info('  splendid_cli sort-enum lib/models/status.dart')
        ..info('  splendid_cli sort-enum lib/models/status.dart --dry-run')
        ..info('')
        ..info(usage);
      return 64;
    }

    /// The target .dart file to process.
    final String targetPath = argResults!.rest.first;

    /// Whether to perform a dry run without modifying the file.
    final bool dryRun = argResults!['dry-run'] as bool;

    /// Whether to show verbose progress and diagnostic information.
    final bool verbose = argResults!['verbose'] as bool;

    if (verbose) {
      logger.level = Level.verbose;
    }

    try {
      const EnumSorterService service = EnumSorterService();

      final EnumSorterRequest request = EnumSorterRequest(
        targetPath: targetPath,
        dryRun: dryRun,
      );

      logger
        ..info(
          '${dryRun ? 'Analyzing' : 'Sorting'} enum values...',
        )
        ..info('Target: $targetPath');
      if (dryRun) {
        logger.info('Mode: Dry run (file will not be modified)');
      }
      logger.info('');

      final Progress progress = logger.progress('Processing enums');
      final EnumSorterResult result = await service.sortEnums(request);
      progress.complete();

      _displayResults(logger, result, verbose);

      return result.success ? 0 : 1;
    } on EnumSorterException catch (e) {
      logger.err('Sorting failed: ${e.message}');
      return _getExitCodeForError(e.type);
    } catch (error) {
      logger.err('Unexpected error: $error');
      return 1;
    }
  }

  /// Displays comprehensive results of the sorting operation.
  ///
  /// Parameters:
  /// * [logger] - Logger instance for output formatting
  /// * [result] - Results from the sorting operation
  /// * [verbose] - Whether to show detailed diagnostics
  void _displayResults(
    Logger logger,
    EnumSorterResult result,
    bool verbose,
  ) {
    logger.info('');

    if (result.success) {
      logger.success('✓ Sorting completed successfully');
    } else {
      logger.warn('⚠ Sorting completed with errors');
    }

    logger
      ..info('')
      ..info('Statistics:')
      ..info('  Enums found: ${result.enumsFound}')
      ..info('  Enums sorted: ${result.enumsSorted}');

    if (result.hasErrors) {
      logger
        ..info('')
        ..err('Errors encountered:');
      for (final String error in result.errors) {
        logger.err('  $error');
      }
    }

    logger.info('');

    if (result.dryRun) {
      if (result.hasModifications) {
        logger
          ..info(
            'Dry run complete. ${result.enumsSorted} enum(s) would be '
            'reordered.',
          )
          ..info('Run without --dry-run to apply changes.');
      } else {
        logger.info(
          'Dry run complete. All enums are already sorted.',
        );
      }
    } else {
      if (result.hasModifications) {
        logger.info(
          'Sorting applied to ${result.enumsSorted} enum(s) in '
          '${result.filePath}.',
        );
      } else {
        logger.info(
          'All enum values are already properly sorted.',
        );
      }
    }
  }

  /// Maps sorter error types to appropriate exit codes.
  ///
  /// Parameters:
  /// * [errorType] - The type of error that occurred
  ///
  /// Returns appropriate POSIX exit code for the error type.
  int _getExitCodeForError(EnumSorterErrorType errorType) {
    switch (errorType) {
      case EnumSorterErrorType.targetNotFound:
      case EnumSorterErrorType.invalidFileType:
      case EnumSorterErrorType.noEnumsFound:
        return 64;
      case EnumSorterErrorType.permissionDenied:
        return 77;
      case EnumSorterErrorType.unknown:
        return 1;
    }
  }
}
