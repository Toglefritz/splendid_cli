import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../services/brick_loader.dart';

/// Command-line interface for managing the brick cache.
///
/// This command provides utilities for managing locally cached bricks that have
/// been downloaded from remote sources. It allows users to view, clear, and
/// manage their brick cache for troubleshooting and maintenance.
///
/// The cache is stored in the user's home directory at
/// `~/.splendid_cli/bricks/` and contains downloaded Mason bricks that are used
/// when local development bricks are not available.
///
/// Usage Examples:
/// ```bash
/// # List all cached bricks
/// splendid_cli cache list
///
/// # Clear all cached bricks
/// splendid_cli cache clear
///
/// # Show cache information
/// splendid_cli cache info
/// ```
///
/// Exit Codes:
/// * `0` - Success: Operation completed successfully
/// * `1` - General error: Unexpected failure during operation
/// * `64` - Usage error: Invalid arguments (EX_USAGE)
class CacheCommand extends Command<int> {
  /// Creates a new instance of [CacheCommand] with configured subcommands.
  ///
  /// Initializes the command with subcommands for different cache operations:
  /// * `list` - Show cached bricks
  /// * `clear` - Remove all cached bricks
  /// * `info` - Display cache information
  CacheCommand() {
    addSubcommand(_CacheListCommand());
    addSubcommand(_CacheClearCommand());
    addSubcommand(_CacheInfoCommand());
  }

  /// Brief description of the command's purpose for help text.
  @override
  String get description => 'Manage the local brick cache.';

  /// The command name used for CLI invocation.
  @override
  String get name => 'cache';

  /// Usage pattern displayed in help text and error messages.
  @override
  String get invocation => 'splendid_cli cache <subcommand>';
}

/// Subcommand to list cached bricks.
class _CacheListCommand extends Command<int> {
  @override
  String get description => 'List all cached bricks.';

  @override
  String get name => 'list';

  @override
  Future<int> run() async {
    final Logger logger = Logger();
    const BrickLoader brickLoader = BrickLoader();

    try {
      final List<String> cachedBricks = await brickLoader.getCachedBricks();

      if (cachedBricks.isEmpty) {
        logger
          ..info('No bricks are currently cached.')
          ..info('Bricks will be downloaded and cached automatically when needed.');
      } else {
        logger.info('Cached bricks:');
        for (final String brickName in cachedBricks) {
          logger.info('  • $brickName');
        }
        logger
          ..info('')
          ..info('Cache location: ~/.splendid_cli/bricks/');
      }

      return 0;
    } catch (e) {
      logger.err('Failed to list cached bricks: $e');

      return 1;
    }
  }
}

/// Subcommand to clear the brick cache.
class _CacheClearCommand extends Command<int> {
  /// Creates a new cache clear command with force flag.
  _CacheClearCommand() {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Clear cache without confirmation prompt.',
      negatable: false,
    );
  }

  @override
  String get description => 'Clear all cached bricks.';

  @override
  String get name => 'clear';

  @override
  Future<int> run() async {
    final Logger logger = Logger();
    const BrickLoader brickLoader = BrickLoader();
    final bool force = argResults!['force'] as bool;

    try {
      final List<String> cachedBricks = await brickLoader.getCachedBricks();

      if (cachedBricks.isEmpty) {
        logger.info('No cached bricks to clear.');

        return 0;
      }

      if (!force) {
        logger.info('This will remove ${cachedBricks.length} cached brick(s):');
        for (final String brickName in cachedBricks) {
          logger.info('  • $brickName');
        }
        logger.info('');

        final String response = logger.prompt('Continue? (y/N)');
        if (response.toLowerCase() != 'y' && response.toLowerCase() != 'yes') {
          logger.info('Cache clear cancelled.');

          return 0;
        }
      }

      await brickLoader.clearCache();
      logger
        ..success('✓ Cache cleared successfully.')
        ..info('Bricks will be re-downloaded when needed.');

      return 0;
    } catch (e) {
      logger.err('Failed to clear cache: $e');

      return 1;
    }
  }
}

/// Subcommand to show cache information.
class _CacheInfoCommand extends Command<int> {
  @override
  String get description => 'Show cache information and statistics.';

  @override
  String get name => 'info';

  @override
  Future<int> run() async {
    final Logger logger = Logger();
    const BrickLoader brickLoader = BrickLoader();

    try {
      final List<String> cachedBricks = await brickLoader.getCachedBricks();

      logger
        ..info('Brick Cache Information')
        ..info('======================')
        ..info('')
        ..info('Cache location: ~/.splendid_cli/bricks/')
        ..info('Cached bricks: ${cachedBricks.length}');

      if (cachedBricks.isNotEmpty) {
        logger
          ..info('')
          ..info('Available bricks:');
        for (final String brickName in cachedBricks) {
          logger.info('  • $brickName');
        }
      }

      logger
        ..info('')
        ..info('How it works:')
        ..info('  1. CLI first checks for local development bricks')
        ..info('  2. Falls back to cached bricks if available')
        ..info('  3. Downloads from GitHub if not cached')
        ..info('  4. Caches downloaded bricks for offline use');

      return 0;
    } catch (e) {
      logger.err('Failed to get cache info: $e');

      return 1;
    }
  }
}
