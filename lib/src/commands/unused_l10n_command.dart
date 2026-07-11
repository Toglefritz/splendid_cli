import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../services/unused_l10n_service.dart';

/// Command-line interface for detecting unused localization strings in a
/// Flutter project.
///
/// This command parses an ARB file to extract all localization keys, then scans
/// Dart source files to identify keys that are not referenced anywhere in the
/// codebase. It is designed to help reduce translation maintenance burden by
/// finding abandoned strings that can be safely removed.
///
/// Key Features:
/// * Automatic ARB file discovery from `l10n.yaml` configuration
/// * Explicit ARB and source path overrides
/// * Whole-word matching to avoid false positives
/// * Automatic exclusion of generated localization files
/// * Sorted output with optional descriptions from ARB metadata
///
/// Detection Behavior:
/// * A key is considered "unused" if it does not appear as a whole word in
///   any Dart file within the source directory (excluding generated l10n
///   files).
/// * Keys accessed dynamically or via computed property names may be falsely
///   reported as unused.
/// * Keys used only in test files (outside `lib/`) will appear unused unless
///   the test directory is explicitly included.
///
/// Usage Examples:
/// ```bash
/// # Auto-detect ARB file from project root
/// splendid_cli unused-l10n .
///
/// # Specify explicit paths
/// splendid_cli unused-l10n --arb=lib/l10n/app_en.arb --source=lib/
///
/// # Exclude additional file patterns
/// splendid_cli unused-l10n . --exclude=.freezed.dart
///
/// # Verbose output
/// splendid_cli unused-l10n . --verbose
/// ```
///
/// Exit Codes:
/// * `0` - Success: Scan completed (even if unused keys were found)
/// * `1` - General error: File system error or processing failure
/// * `64` - Usage error: Invalid arguments or missing target (EX_USAGE)
class UnusedL10nCommand extends Command<int> {
  /// Creates a new instance of [UnusedL10nCommand] with configured argument
  /// parser.
  ///
  /// Initializes the command with support for:
  /// * `--arb`: Explicit path to the primary ARB file
  /// * `--source`: Explicit path to the source directory
  /// * `--exclude`: Patterns for files to skip (repeatable)
  /// * `--verbose` (-v): Detailed progress and diagnostic output
  UnusedL10nCommand() {
    argParser
      ..addOption(
        'arb',
        help:
            'Path to the primary ARB file. Auto-detected from l10n.yaml '
            'if not specified.',
        valueHelp: 'path',
      )
      ..addOption(
        'source',
        help:
            'Path to the source directory to scan. Defaults to lib/ '
            'relative to the project root.',
        valueHelp: 'path',
      )
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
  String get description => 'Identify unused localization strings defined in ARB files.';

  /// The command name used for CLI invocation.
  @override
  String get name => 'unused-l10n';

  /// Alternative shorter names for the command.
  @override
  List<String> get aliases => <String>['dead-l10n', 'unused-arb'];

  /// Usage pattern displayed in help text and error messages.
  @override
  String get invocation => 'splendid_cli unused-l10n <project_root> [arguments]';

  /// Executes the unused l10n detection command with parsed command-line
  /// arguments.
  ///
  /// This method orchestrates the detection workflow:
  /// 1. Resolves the ARB file path (explicit or auto-detected)
  /// 2. Resolves the source directory path
  /// 3. Configures the detection service with user preferences
  /// 4. Executes the scanning operation with progress reporting
  /// 5. Displays comprehensive results
  ///
  /// Returns:
  /// * `0` on successful completion
  /// * `1` for unexpected errors during scanning
  /// * `64` for usage errors (missing args, invalid parameters, etc.)
  @override
  Future<int> run() async {
    final Logger logger = Logger();

    // Resolve project root from positional argument.
    if (argResults!.rest.isEmpty) {
      logger
        ..err('Project root directory is required.')
        ..info('')
        ..info('Usage: $invocation')
        ..info('')
        ..info('Examples:')
        ..info('  splendid_cli unused-l10n .')
        ..info(
          '  splendid_cli unused-l10n . '
          '--arb=lib/l10n/app_en.arb --source=lib/',
        )
        ..info('')
        ..info(usage);
      return 64;
    }

    final String projectRoot = argResults!.rest.first;

    /// Explicit ARB file path override.
    final String? explicitArb = argResults!['arb'] as String?;

    /// Explicit source directory override.
    final String? explicitSource = argResults!['source'] as String?;

    /// Patterns for files to exclude from scanning.
    final List<String> excludePatterns = argResults!['exclude'] as List<String>;

    /// Whether to show verbose progress and diagnostic information.
    final bool verbose = argResults!['verbose'] as bool;

    if (verbose) {
      logger.level = Level.verbose;
    }

    // Resolve ARB file path.
    final String? arbFilePath = _resolveArbPath(
      projectRoot,
      explicitArb,
      logger,
    );
    if (arbFilePath == null) {
      logger
        ..err(
          'Could not locate an ARB file. Specify one with --arb=<path>.',
        )
        ..info('')
        ..info(
          'Tip: Ensure your project has a l10n.yaml file or provide the '
          'ARB path explicitly.',
        );
      return 64;
    }

    // Resolve source directory path.
    final String sourcePath = explicitSource ?? path.join(projectRoot, 'lib');

    if (!Directory(sourcePath).existsSync()) {
      logger.err('Source directory does not exist: $sourcePath');
      return 64;
    }

    try {
      const UnusedL10nService service = UnusedL10nService();

      final UnusedL10nRequest request = UnusedL10nRequest(
        arbFilePath: arbFilePath,
        sourcePath: sourcePath,
        excludePatterns: excludePatterns,
      );

      logger
        ..info('Scanning for unused localization keys...')
        ..info('ARB file: $arbFilePath')
        ..info('Source: $sourcePath');

      if (excludePatterns.isNotEmpty) {
        logger.info('Excluding: ${excludePatterns.join(', ')}');
      }
      logger.info('');

      final Progress progress = logger.progress('Analyzing l10n keys');
      final UnusedL10nResult result = await service.findUnusedKeys(request);
      progress.complete();

      _displayResults(logger, result, verbose);

      return result.success ? 0 : 1;
    } on UnusedL10nException catch (e) {
      logger.err('Detection failed: ${e.message}');
      return _getExitCodeForError(e.type);
    } catch (error) {
      logger.err('Unexpected error: $error');
      return 1;
    }
  }

  /// Resolves the ARB file path, either from an explicit argument or by
  /// auto-detecting from `l10n.yaml`.
  ///
  /// Auto-detection reads the `l10n.yaml` file in the project root to find
  /// the `arb-dir` and `template-arb-file` fields, constructing the full
  /// path from those values.
  ///
  /// Parameters:
  /// * [projectRoot] - The project root directory
  /// * [explicitPath] - User-provided explicit path, if any
  /// * [logger] - Logger for verbose output
  ///
  /// Returns the resolved ARB file path, or null if it cannot be determined.
  String? _resolveArbPath(
    String projectRoot,
    String? explicitPath,
    Logger logger,
  ) {
    if (explicitPath != null) {
      return explicitPath;
    }

    // Try to auto-detect from l10n.yaml.
    final String l10nYamlPath = path.join(projectRoot, 'l10n.yaml');
    final File l10nYaml = File(l10nYamlPath);

    if (!l10nYaml.existsSync()) {
      // Fall back to common default location.
      final String defaultPath = path.join(
        projectRoot,
        'lib',
        'l10n',
        'app_en.arb',
      );
      if (File(defaultPath).existsSync()) {
        logger.detail(
          'Auto-detected ARB file at default location: '
          '$defaultPath',
        );
        return defaultPath;
      }
      return null;
    }

    try {
      final String content = l10nYaml.readAsStringSync();
      final Object? yaml = loadYaml(content);

      if (yaml is! YamlMap) return null;

      final String arbDir = (yaml['arb-dir'] as String?) ?? path.join('lib', 'l10n');
      final String templateFile = (yaml['template-arb-file'] as String?) ?? 'app_en.arb';

      final String resolvedPath = path.join(
        projectRoot,
        arbDir,
        templateFile,
      );

      if (File(resolvedPath).existsSync()) {
        logger.detail('Auto-detected ARB file from l10n.yaml: $resolvedPath');
        return resolvedPath;
      }

      return null;
    } catch (e) {
      logger.detail('Failed to parse l10n.yaml: $e');
      return null;
    }
  }

  /// Displays comprehensive results of the unused l10n detection.
  ///
  /// Lists unused keys with their descriptions (if available) and includes
  /// summary statistics.
  ///
  /// Parameters:
  /// * [logger] - Logger instance for output formatting
  /// * [result] - Results from the detection operation
  /// * [verbose] - Whether to show detailed diagnostics
  void _displayResults(
    Logger logger,
    UnusedL10nResult result,
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
    }

    logger
      ..info('')
      ..info('Statistics:')
      ..info('  Total keys in ARB: ${result.totalKeys}')
      ..info('  Keys in use: ${result.usedKeys}')
      ..info('  Unused keys: ${result.unusedKeys.length}')
      ..info('  Files scanned: ${result.filesScanned}')
      ..info('');

    if (result.hasUnusedKeys) {
      logger
        ..info('Potentially unused localization keys:')
        ..info('');

      for (final UnusedL10nInfo info in result.unusedKeys) {
        if (info.description != null) {
          logger
            ..info('  • ${info.key}')
            ..info('    ${info.description}');
        } else {
          logger.info('  • ${info.key}');
        }
      }

      logger
        ..info('')
        ..info(
          'Note: Review these results manually. Keys accessed dynamically '
          'or used only in tests may appear as false positives.',
        );
    } else {
      logger.success('✓ All localization keys are in use.');
    }
  }

  /// Maps detection error types to appropriate exit codes.
  ///
  /// Parameters:
  /// * [errorType] - The type of error that occurred
  ///
  /// Returns appropriate POSIX exit code for the error type.
  int _getExitCodeForError(UnusedL10nErrorType errorType) {
    switch (errorType) {
      case UnusedL10nErrorType.arbFileNotFound:
      case UnusedL10nErrorType.sourceNotFound:
      case UnusedL10nErrorType.invalidArbFormat:
      case UnusedL10nErrorType.noKeysFound:
      case UnusedL10nErrorType.noDartFilesFound:
        return 64;
      case UnusedL10nErrorType.permissionDenied:
        return 77;
      case UnusedL10nErrorType.unknown:
        return 1;
    }
  }
}
