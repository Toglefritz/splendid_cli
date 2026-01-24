import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

/// Service for loading Mason bricks from local or remote sources.
///
/// This service implements a hybrid approach that prioritizes local bricks (for
/// development) and falls back to downloading from GitHub (for production).
/// This ensures the CLI works in both development and global installation
/// scenarios.
class BrickLoader {
  /// Creates a new BrickLoader instance.
  const BrickLoader();

  /// GitHub repository information for remote brick loading.
  static const String _githubOwner = 'Toglefritz';
  static const String _githubRepo = 'splendid_cli';
  static const String _githubBranch = 'main';

  /// Base URL for GitHub raw content API.
  static const String _githubRawBaseUrl = 'https://raw.githubusercontent.com';

  /// Cache directory for downloaded bricks.
  static final String _cacheDir = path.join(
    Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.',
    '.splendid_cli',
    'bricks',
  );

  /// Loads a brick by name, checking local sources first, then remote.
  ///
  /// This method implements the hybrid loading strategy:
  /// 1. Check for local brick in development location
  /// 2. Check for cached brick from previous download
  /// 3. Download brick from GitHub and cache it
  /// 4. Return the brick directory path
  ///
  /// Parameters:
  /// * [brickName] - Name of the brick to load (e.g., 'flutter_screen')
  ///
  /// Returns:
  /// * Path to the brick directory containing brick.yaml and __brick__ folder
  ///
  /// Throws:
  /// * [BrickLoadException] if the brick cannot be loaded from any source
  Future<String> loadBrick(String brickName) async {
    // 1. Try local development location first
    final String localBrickPath = _getLocalBrickPath(brickName);
    if (await _isValidBrick(localBrickPath)) {
      return localBrickPath;
    }

    // 2. Try cached brick from previous download
    final String cachedBrickPath = _getCachedBrickPath(brickName);
    if (await _isValidBrick(cachedBrickPath)) {
      return cachedBrickPath;
    }

    // 3. Download brick from GitHub and cache it
    try {
      await _downloadBrickFromGitHub(brickName);

      // Verify the download was successful
      if (await _isValidBrick(cachedBrickPath)) {
        return cachedBrickPath;
      } else {
        throw BrickLoadException(
          'Downloaded brick is invalid: $brickName',
          BrickLoadErrorType.invalidBrick,
        );
      }
    } catch (e) {
      throw BrickLoadException(
        'Failed to load brick $brickName: $e',
        BrickLoadErrorType.downloadFailed,
        cause: e,
      );
    }
  }

  /// Gets the local development brick path.
  ///
  /// This path is used when running the CLI from the development environment
  /// where the bricks directory is available relative to the script location.
  String _getLocalBrickPath(String brickName) {
    return path.join(
      path.dirname(Platform.script.path),
      '..',
      'bricks',
      brickName,
    );
  }

  /// Gets the cached brick path in the user's home directory.
  ///
  /// Downloaded bricks are cached here to avoid repeated downloads and to work
  /// offline after the first download.
  String _getCachedBrickPath(String brickName) {
    return path.join(_cacheDir, brickName);
  }

  /// Checks if a directory contains a valid Mason brick.
  ///
  /// A valid brick must have:
  /// * A brick.yaml file with proper metadata
  /// * A __brick__ directory containing templates
  ///
  /// Parameters:
  /// * [brickPath] - Path to the potential brick directory
  ///
  /// Returns:
  /// * true if the directory contains a valid brick
  Future<bool> _isValidBrick(String brickPath) async {
    try {
      final Directory brickDir = Directory(brickPath);
      if (!brickDir.existsSync()) {
        return false;
      }

      // Check for brick.yaml
      final File brickYaml = File(path.join(brickPath, 'brick.yaml'));
      if (!brickYaml.existsSync()) {
        return false;
      }

      // Check for __brick__ directory
      final Directory brickTemplateDir = Directory(path.join(brickPath, '__brick__'));
      if (!brickTemplateDir.existsSync()) {
        return false;
      }

      // Validate brick.yaml content
      final String yamlContent = await brickYaml.readAsString();
      if (!yamlContent.contains('name:') || !yamlContent.contains('version:')) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Downloads a brick from GitHub and caches it locally.
  ///
  /// This method downloads the entire brick directory structure from GitHub,
  /// including the brick.yaml metadata and all template files in __brick__.
  ///
  /// Parameters:
  /// * [brickName] - Name of the brick to download
  Future<void> _downloadBrickFromGitHub(String brickName) async {
    final String cachedBrickPath = _getCachedBrickPath(brickName);
    final Directory cacheDir = Directory(cachedBrickPath);

    // Create cache directory
    if (cacheDir.existsSync()) {
      await cacheDir.delete(recursive: true);
    }
    await cacheDir.create(recursive: true);

    // Download brick.yaml
    await _downloadFile(
      'bricks/$brickName/brick.yaml',
      path.join(cachedBrickPath, 'brick.yaml'),
    );

    // Download __brick__ directory contents
    await _downloadBrickTemplates(brickName, cachedBrickPath);
  }

  /// Downloads all template files from the __brick__ directory.
  ///
  /// This method recursively downloads all files in the brick's template
  /// directory, preserving the directory structure.
  ///
  /// Parameters:
  /// * [brickName] - Name of the brick being downloaded
  /// * [localBrickPath] - Local path where the brick should be cached
  Future<void> _downloadBrickTemplates(String brickName, String localBrickPath) async {
    // Define known brick structures
    switch (brickName) {
      case 'flutter_screen':
        await _downloadFlutterScreenTemplates(localBrickPath);
      case 'flutter_screen_blank':
        await _downloadFlutterScreenBlankTemplates(localBrickPath);
      case 'flutter_app':
        await _downloadFlutterAppTemplates(localBrickPath);
      case 'flutter_widget_test':
      case 'dart_class_test':
        await _downloadTestTemplates(brickName, localBrickPath);

      default:
        throw BrickLoadException(
          'Unknown brick type: $brickName. Supported bricks: flutter_screen, flutter_screen_blank, flutter_app, flutter_widget_test, dart_class_test',
          BrickLoadErrorType.unknownBrick,
        );
    }
  }

  /// Downloads the flutter_screen brick templates.
  ///
  /// This method knows the specific structure of the flutter_screen brick and
  /// downloads all necessary template files.
  Future<void> _downloadFlutterScreenTemplates(String localBrickPath) async {
    final String brickDir = path.join(localBrickPath, '__brick__', 'lib', 'screens', '{{name.snakeCase()}}');
    await Directory(brickDir).create(recursive: true);

    // Download template files
    final List<String> templateFiles = [
      '{{name.snakeCase()}}_route.dart',
      '{{name.snakeCase()}}_controller.dart',
      '{{name.snakeCase()}}_view.dart',
    ];

    for (final String fileName in templateFiles) {
      await _downloadFile(
        'bricks/flutter_screen/__brick__/lib/screens/{{name.snakeCase()}}/$fileName',
        path.join(brickDir, fileName),
      );
    }
  }

  /// Downloads the flutter_screen_blank brick templates.
  ///
  /// This method knows the specific structure of the flutter_screen_blank brick
  /// and downloads all necessary template files for creating minimal screens
  /// without example content.
  Future<void> _downloadFlutterScreenBlankTemplates(String localBrickPath) async {
    final String brickDir = path.join(localBrickPath, '__brick__', 'lib', 'screens', '{{name.snakeCase()}}');
    await Directory(brickDir).create(recursive: true);

    // Download template files
    final List<String> templateFiles = [
      '{{name.snakeCase()}}_route.dart',
      '{{name.snakeCase()}}_controller.dart',
      '{{name.snakeCase()}}_view.dart',
    ];

    for (final String fileName in templateFiles) {
      await _downloadFile(
        'bricks/flutter_screen_blank/__brick__/lib/screens/{{name.snakeCase()}}/$fileName',
        path.join(brickDir, fileName),
      );
    }
  }

  /// Downloads the flutter_app brick templates.
  ///
  /// This method downloads the complete Flutter app template structure.
  Future<void> _downloadFlutterAppTemplates(String localBrickPath) async {
    final String brickDir = path.join(localBrickPath, '__brick__');
    await Directory(brickDir).create(recursive: true);

    // Download root configuration files
    final List<String> rootFiles = [
      'analysis_options.yaml',
      'l10n.yaml',
      'pubspec.yaml',
      'README.md',
    ];

    for (final String fileName in rootFiles) {
      await _downloadFile(
        'bricks/flutter_app/__brick__/$fileName',
        path.join(brickDir, fileName),
      );
    }

    // Download lib directory structure
    await _downloadFlutterAppLibFiles(brickDir);
  }

  /// Downloads the lib directory files for flutter_app brick.
  Future<void> _downloadFlutterAppLibFiles(String brickDir) async {
    // Create lib directory structure
    final String libDir = path.join(brickDir, 'lib');
    await Directory(libDir).create(recursive: true);

    // Download main lib files
    final List<String> libFiles = [
      'main.dart',
      'app.dart',
    ];

    for (final String fileName in libFiles) {
      await _downloadFile(
        'bricks/flutter_app/__brick__/lib/$fileName',
        path.join(libDir, fileName),
      );
    }

    // Download l10n files
    final String l10nDir = path.join(libDir, 'l10n');
    await Directory(l10nDir).create(recursive: true);
    await _downloadFile(
      'bricks/flutter_app/__brick__/lib/l10n/app_en.arb',
      path.join(l10nDir, 'app_en.arb'),
    );

    // Download theme files
    final String themeDir = path.join(libDir, 'theme');
    await Directory(themeDir).create(recursive: true);

    final List<String> themeFiles = [
      'app_theme.dart',
      'insets.dart',
    ];

    for (final String fileName in themeFiles) {
      await _downloadFile(
        'bricks/flutter_app/__brick__/lib/theme/$fileName',
        path.join(themeDir, fileName),
      );
    }

    // Download home screen files
    final String homeDir = path.join(libDir, 'screens', 'home');
    await Directory(homeDir).create(recursive: true);

    final List<String> homeFiles = [
      'home_route.dart',
      'home_controller.dart',
      'home_view.dart',
    ];

    for (final String fileName in homeFiles) {
      await _downloadFile(
        'bricks/flutter_app/__brick__/lib/screens/home/$fileName',
        path.join(homeDir, fileName),
      );
    }

    // Create empty services directory
    final String servicesDir = path.join(libDir, 'services');
    await Directory(servicesDir).create(recursive: true);
  }

  /// Downloads test brick templates.
  ///
  /// This method downloads templates for widget and class test bricks.
  Future<void> _downloadTestTemplates(String brickName, String localBrickPath) async {
    // This would need to be implemented based on the test brick structures For
    // now, throw an exception to indicate it's not yet supported
    throw BrickLoadException(
      '$brickName brick remote download not yet implemented',
      BrickLoadErrorType.unknownBrick,
    );
  }

  /// Downloads a single file from GitHub.
  ///
  /// Parameters:
  /// * [remotePath] - Path to the file in the GitHub repository
  /// * [localPath] - Local path where the file should be saved
  Future<void> _downloadFile(String remotePath, String localPath) async {
    final String url = '$_githubRawBaseUrl/$_githubOwner/$_githubRepo/$_githubBranch/$remotePath';

    final http.Response response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final File localFile = File(localPath);
      await localFile.parent.create(recursive: true);
      await localFile.writeAsString(response.body);
    } else {
      throw BrickLoadException(
        'Failed to download file: $url (HTTP ${response.statusCode})',
        BrickLoadErrorType.downloadFailed,
      );
    }
  }

  /// Clears the brick cache.
  ///
  /// This method removes all cached bricks, forcing fresh downloads on the next
  /// brick load. Useful for development and troubleshooting.
  Future<void> clearCache() async {
    final Directory cacheDirectory = Directory(_cacheDir);
    if (cacheDirectory.existsSync()) {
      await cacheDirectory.delete(recursive: true);
    }
  }

  /// Gets information about cached bricks.
  ///
  /// Returns a list of brick names that are currently cached locally.
  Future<List<String>> getCachedBricks() async {
    final Directory cacheDirectory = Directory(_cacheDir);
    if (!cacheDirectory.existsSync()) {
      return [];
    }

    final List<String> cachedBricks = [];
    await for (final FileSystemEntity entity in cacheDirectory.list()) {
      if (entity is Directory) {
        final String brickName = path.basename(entity.path);
        if (await _isValidBrick(entity.path)) {
          cachedBricks.add(brickName);
        }
      }
    }

    return cachedBricks;
  }
}

/// Exception thrown when brick loading fails.
class BrickLoadException implements Exception {
  /// Creates a brick load exception.
  const BrickLoadException(
    this.message,
    this.type, {
    this.cause,
  });

  /// Human-readable error message.
  final String message;

  /// Type of error that occurred.
  final BrickLoadErrorType type;

  /// Optional underlying cause.
  final Object? cause;

  @override
  String toString() => 'BrickLoadException: $message';
}

/// Types of errors that can occur during brick loading.
enum BrickLoadErrorType {
  /// Brick could not be found locally or remotely.
  brickNotFound,

  /// Downloaded or local brick is invalid.
  invalidBrick,

  /// Network error during download.
  downloadFailed,

  /// Unknown brick type requested.
  unknownBrick,
}
