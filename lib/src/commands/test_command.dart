import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

/// Command-line interface for generating test file templates.
///
/// This command creates boilerplate test files for Dart classes and Flutter
/// widgets, following established testing patterns and documentation standards.
/// It uses Mason bricks to ensure consistent test structure across the project.
///
/// The command analyzes the target Dart file to determine whether it contains a
/// Flutter widget or regular Dart class, then generates the appropriate test
/// template:
/// * Widget tests use `testWidgets` for Flutter-specific testing
/// * Class tests use standard `test` functions for unit testing
/// * Both include comprehensive documentation structure
/// * All tests follow the project's testing conventions
///
/// Generated test files include:
/// * Comprehensive documentation header with test categories
/// * Proper test group organization
/// * Setup and teardown methods where appropriate
/// * Mock dependencies and test fixtures
/// * Example test cases with expect statements
/// * Documentation for each test explaining its purpose
///
/// Usage Examples:
/// ```bash
/// # Generate test for a Flutter widget
/// splendid_cli test lib/screens/home/home_view.dart
///
/// # Generate test for a regular Dart class
/// splendid_cli test lib/services/api_service.dart
///
/// # Generate test with custom output location
/// splendid_cli test lib/models/user.dart --output test/unit/models/
///
/// # Force overwrite existing test file
/// splendid_cli test lib/controllers/auth_controller.dart --force
/// ```
///
/// Exit Codes:
/// * `0` - Success: Test file generated successfully
/// * `1` - General error: File system error or template generation failure
/// * `64` - Usage error: Invalid arguments or missing target file (EX_USAGE)
///
/// Performance: Test generation is typically very fast (< 1 second) as it only
/// processes template files without external dependencies.
///
/// Thread Safety: This command is safe to run concurrently on different files
/// but should not target the same output file simultaneously.
class TestCommand extends Command<int> {
  /// Creates a new instance of [TestCommand] with configured argument parser.
  ///
  /// Initializes the command with support for:
  /// * `--output` (-o): Custom output directory for the generated test file
  /// * `--force`: Overwrite existing test files without confirmation
  /// * `--type`: Explicitly specify test type (widget, class, auto)
  TestCommand() {
    argParser
      ..addOption(
        'output',
        abbr: 'o',
        help:
            'The output directory for the generated test file.\n'
            'Defaults to mirroring the source file structure in test/',
      )
      ..addOption(
        'type',
        abbr: 't',
        help: 'The type of test to generate.',
        allowed: ['auto', 'widget', 'class'],
        defaultsTo: 'auto',
        allowedHelp: {
          'auto': 'Automatically detect based on source file content',
          'widget': 'Generate Flutter widget test template',
          'class': 'Generate Dart class test template',
        },
      )
      ..addFlag(
        'force',
        help: 'Overwrite existing test files without confirmation.',
        negatable: false,
      );
  }

  /// Brief description of the command's purpose for help text.
  @override
  String get description => 'Generate test file templates for Dart classes and Flutter widgets.';

  /// The command name used for CLI invocation.
  @override
  String get name => 'generate-test';

  /// Alternative shorter name for the command.
  @override
  List<String> get aliases => ['gen-test'];

  /// Usage pattern displayed in help text and error messages.
  @override
  String get invocation => 'splendid_cli generate-test <dart_file> [arguments]';

  /// Executes the test generation command with parsed command-line arguments.
  ///
  /// This method orchestrates the complete test generation workflow:
  /// 1. Validates command-line arguments and target file existence
  /// 2. Analyzes the target file to determine test type (widget vs class)
  /// 3. Determines the appropriate output location for the test file
  /// 4. Loads the appropriate Mason brick template
  /// 5. Generates the test file with proper documentation structure
  /// 6. Provides user feedback and next steps
  ///
  /// The method handles various error conditions gracefully:
  /// * Missing or invalid target file paths
  /// * File system permission errors
  /// * Template generation failures
  /// * Output directory conflicts (without --force)
  ///
  /// Returns:
  /// * `0` on successful test file generation
  /// * `1` for unexpected errors during generation
  /// * `64` for usage errors (missing args, invalid files, etc.)
  @override
  Future<int> run() async {
    final Logger logger = Logger();

    // Validate that a target file was provided as a positional argument
    if (argResults!.rest.isEmpty) {
      logger
        ..err('Target Dart file is required.')
        ..info(usage);
      return 64;
    }

    /// The target Dart file to generate tests for.
    ///
    /// Must be a valid Dart file (.dart extension) that exists in the file
    /// system. The file will be analyzed to determine the appropriate test
    /// template type.
    final String targetFile = argResults!.rest.first;

    /// Optional custom output directory specified via --output flag.
    ///
    /// When provided, the test file will be created in this directory. When
    /// null, the test file location is determined by mirroring the source file
    /// structure in the test/ directory.
    final String? outputDirectory = argResults!['output'] as String?;

    /// Whether to force overwrite existing test files (--force flag).
    ///
    /// When true, existing test files will be overwritten without confirmation.
    /// When false, the command will fail if the target test file already
    /// exists.
    final bool force = argResults!['force'] as bool;

    /// The type of test to generate (auto, widget, class).
    ///
    /// When 'auto', the command analyzes the target file to determine the
    /// appropriate test type. Manual specification overrides auto-detection.
    final String testType = argResults!['type'] as String;

    // Validate target file exists and is a Dart file
    final File sourceFile = File(targetFile);
    if (!sourceFile.existsSync()) {
      logger.err('Target file does not exist: $targetFile');
      return 64;
    }

    if (!targetFile.endsWith('.dart')) {
      logger.err('Target file must be a Dart file (.dart extension): $targetFile');
      return 64;
    }

    try {
      /// The determined test type based on analysis or explicit specification.
      ///
      /// Will be either 'widget' for Flutter widget tests or 'class' for
      /// standard Dart class tests.
      final String resolvedTestType = testType == 'auto' ? await _analyzeFileType(sourceFile, logger) : testType;

      /// Information about the target file extracted for template generation.
      ///
      /// Contains the class name, file name, and other metadata needed to
      /// generate appropriate test templates.
      final FileAnalysis analysis = await _analyzeFile(sourceFile, logger);

      /// Absolute path where the test file will be created.
      ///
      /// Determined by either the explicit output directory or by mirroring the
      /// source file structure in the test/ directory.
      final String testFilePath = _determineTestFilePath(
        targetFile,
        outputDirectory,
        analysis.fileName,
      );

      // Check if test file exists and handle force flag
      final File testFile = File(testFilePath);
      if (testFile.existsSync() && !force) {
        logger
          ..err('Test file already exists: $testFilePath')
          ..info('Use --force to overwrite existing test file.');
        return 1;
      }

      // Create output directory if it doesn't exist
      final Directory testDirectory = Directory(path.dirname(testFilePath));
      if (!testDirectory.existsSync()) {
        testDirectory.createSync(recursive: true);
        logger.detail('Created directory: ${testDirectory.path}');
      }

      /// Mason generator instance loaded from the appropriate test brick
      /// template.
      ///
      /// The generator contains template files for either widget tests or class
      /// tests based on the resolved test type.
      final MasonGenerator generator = await _loadTestBrick(resolvedTestType, logger);

      /// Template variables passed to the Mason brick during generation.
      ///
      /// Includes all necessary information for generating a complete test
      /// file:
      /// * Class name and file information
      /// * Import paths and dependencies
      /// * Test type and structure preferences
      final Map<String, dynamic> templateVars = _buildTemplateVariables(
        analysis,
        targetFile,
        resolvedTestType,
      );

      logger.info('Generating $resolvedTestType test for ${analysis.className}...');

      await generator.generate(
        DirectoryGeneratorTarget(testDirectory),
        vars: templateVars,
        fileConflictResolution: FileConflictResolution.overwrite,
      );

      logger
        ..success('✓ Generated test file: $testFilePath')
        ..info('')
        ..info('Next steps:')
        ..info('  1. Review and customize the generated test cases')
        ..info('  2. Add specific test scenarios for your class methods')
        ..info('  3. Run tests with: flutter test $testFilePath')
        ..info('')
        ..info('The generated test includes:')
        ..info('  • Comprehensive documentation structure')
        ..info('  • Setup and teardown methods')
        ..info('  • Example test cases with expect statements')
        ..info('  • Mock dependencies where appropriate');

      return 0;
    } catch (error) {
      logger.err('Failed to generate test file: $error');
      return 1;
    }
  }

  /// Analyzes a Dart file to determine whether it contains widgets or regular
  /// classes.
  ///
  /// This method examines the file content to detect Flutter widget patterns:
  /// * Classes extending StatelessWidget or StatefulWidget
  /// * Classes implementing Widget interface
  /// * Import statements for Flutter framework
  ///
  /// The analysis is used for automatic test type detection when --type=auto.
  ///
  /// Parameters:
  /// * [file] - The Dart file to analyze
  /// * [logger] - Logger instance for debug output
  ///
  /// Returns:
  /// * 'widget' if the file contains Flutter widgets
  /// * 'class' if the file contains regular Dart classes
  Future<String> _analyzeFileType(File file, Logger logger) async {
    try {
      final String content = await file.readAsString();

      // Check for Flutter widget patterns
      final bool hasWidgetImports =
          content.contains('package:flutter/') || content.contains('import \'package:flutter/');

      final bool hasWidgetClasses =
          content.contains('extends StatelessWidget') ||
          content.contains('extends StatefulWidget') ||
          content.contains('implements Widget') ||
          content.contains('extends Widget');

      if (hasWidgetImports && hasWidgetClasses) {
        logger.detail('Detected Flutter widget in file');
        return 'widget';
      }

      logger.detail('Detected regular Dart class in file');
      return 'class';
    } catch (error) {
      logger.warn('Could not analyze file type, defaulting to class: $error');
      return 'class';
    }
  }

  /// Analyzes a Dart file to extract metadata needed for test generation.
  ///
  /// This method parses the file to extract:
  /// * Primary class name for test naming
  /// * File name for import statements
  /// * Package structure for relative imports
  /// * Dependencies and imports needed in tests
  ///
  /// The extracted information is used to populate template variables for
  /// generating appropriate test files.
  ///
  /// Parameters:
  /// * [file] - The Dart file to analyze
  /// * [logger] - Logger instance for debug output
  ///
  /// Returns:
  /// * [FileAnalysis] containing extracted metadata
  Future<FileAnalysis> _analyzeFile(File file, Logger logger) async {
    final String content = await file.readAsString();
    final String fileName = path.basenameWithoutExtension(file.path);

    // Extract the primary class name (first public class found)
    final RegExp classPattern = RegExp(r'class\s+([A-Z][a-zA-Z0-9_]*)\s+');
    final Match? classMatch = classPattern.firstMatch(content);

    final String className = classMatch?.group(1) ?? _toPascalCase(fileName);

    logger.detail('Analyzed file: class=$className, file=$fileName');

    return FileAnalysis(
      className: className,
      fileName: fileName,
      filePath: file.path,
      hasFlutterImports: content.contains('package:flutter/'),
    );
  }

  /// Determines the appropriate output path for the generated test file.
  ///
  /// This method follows Flutter testing conventions by mirroring the source
  /// file structure in the test/ directory, unless a custom output directory is
  /// specified.
  ///
  /// Path resolution logic:
  /// * Custom output directory: Use as-is with test file name
  /// * Default behavior: Mirror lib/ structure in test/
  /// * Preserve subdirectory structure for organization
  ///
  /// Parameters:
  /// * [sourceFile] - Path to the source Dart file
  /// * [outputDirectory] - Optional custom output directory
  /// * [fileName] - Base name for the test file
  ///
  /// Returns:
  /// * Absolute path where the test file should be created
  String _determineTestFilePath(
    String sourceFile,
    String? outputDirectory,
    String fileName,
  ) {
    if (outputDirectory != null) {
      return path.join(outputDirectory, '${fileName}_test.dart');
    }

    // Mirror the source file structure in test/
    String relativePath = sourceFile;

    // Remove lib/ prefix if present
    if (relativePath.startsWith('lib/')) {
      relativePath = relativePath.substring(4);
    }

    // Replace .dart extension with _test.dart
    relativePath = relativePath.replaceAll('.dart', '_test.dart');

    return path.join('test', relativePath);
  }

  /// Loads the appropriate Mason brick template for test generation.
  ///
  /// This method locates and loads the Mason brick corresponding to the
  /// specified test type (widget or class) from the CLI package's brick
  /// directory.
  ///
  /// Brick resolution:
  /// * 'widget' type loads the flutter_widget_test brick
  /// * 'class' type loads the dart_class_test brick
  /// * Bricks are located relative to the CLI executable
  ///
  /// Parameters:
  /// * [testType] - The type of test template to load ('widget' or 'class')
  /// * [logger] - Logger instance for error reporting
  ///
  /// Returns:
  /// * [MasonGenerator] configured with the appropriate test brick
  ///
  /// Throws:
  /// * [FileSystemException] if the brick directory doesn't exist
  /// * [FormatException] if the brick.yaml file is malformed
  /// * [StateError] if the brick cannot be loaded or initialized
  Future<MasonGenerator> _loadTestBrick(String testType, Logger logger) async {
    try {
      /// Name of the Mason brick to load based on test type.
      ///
      /// Maps test types to their corresponding brick names in the bricks/
      /// directory structure.
      final String brickName = testType == 'widget' ? 'flutter_widget_test' : 'dart_class_test';

      /// Absolute path to the test brick directory.
      ///
      /// Constructed by navigating from the CLI executable location to the
      /// bricks directory and selecting the appropriate test brick.
      final String brickPath = path.join(
        path.dirname(Platform.script.path),
        '..',
        'bricks',
        brickName,
      );

      logger.detail('Loading test brick from: $brickPath');

      /// Mason brick instance loaded from the file system.
      ///
      /// The brick contains metadata (brick.yaml) and template files (__brick__
      /// directory) that define the structure and content of generated test
      /// files.
      final Brick brick = Brick.path(brickPath);

      return MasonGenerator.fromBrick(brick);
    } catch (error) {
      logger.err('Failed to load test brick: $error');
      rethrow;
    }
  }

  /// Builds template variables for Mason brick generation.
  ///
  /// This method constructs the variable map that will be passed to the Mason
  /// brick template, containing all necessary information for generating a
  /// complete and properly structured test file.
  ///
  /// Template variables include:
  /// * Class and file naming information
  /// * Import paths for the source file
  /// * Test type and structure preferences
  /// * Documentation and metadata
  ///
  /// Parameters:
  /// * [analysis] - File analysis results containing class metadata
  /// * [sourceFile] - Path to the source file being tested
  /// * [testType] - Type of test being generated ('widget' or 'class')
  ///
  /// Returns:
  /// * Map of template variables for Mason brick generation
  Map<String, dynamic> _buildTemplateVariables(
    FileAnalysis analysis,
    String sourceFile,
    String testType,
  ) {
    /// Relative import path from test file to source file.
    ///
    /// Calculated to ensure the test file can properly import the class being
    /// tested, following Dart import conventions.
    final String importPath = _calculateImportPath(sourceFile);

    /// CamelCase version of the file name for variable naming.
    ///
    /// Converts snake_case file names to camelCase for proper Dart variable
    /// naming conventions.
    final String camelCaseFileName = _toCamelCase(analysis.fileName);

    return {
      'className': analysis.className,
      'fileName': analysis.fileName,
      'fileNameCamelCase': camelCaseFileName,
      'importPath': importPath,
      'testType': testType,
      'hasFlutterImports': analysis.hasFlutterImports,
      'testClassName': '${analysis.className}Test',
      'testFileName': '${analysis.fileName}_test',
    };
  }

  /// Calculates the relative import path from test file to source file.
  ///
  /// This method determines the correct import statement that should be used in
  /// the generated test file to import the class being tested.
  ///
  /// Import path calculation:
  /// * For files in lib/: Use package import format
  /// * For files outside lib/: Use relative import format
  /// * Ensures proper Dart import conventions
  ///
  /// Parameters:
  /// * [sourceFile] - Absolute or relative path to the source file
  ///
  /// Returns:
  /// * Import path suitable for use in import statements
  String _calculateImportPath(String sourceFile) {
    String importPath = sourceFile;

    // If the file is in lib/, use package import
    if (importPath.startsWith('lib/')) {
      importPath = importPath.substring(4);
      return 'package:${_getPackageName()}/$importPath';
    }

    // For files outside lib/, use relative import Calculate relative path from
    // test file to source file
    return '../$importPath';
  }

  /// Retrieves the package name from pubspec.yaml for import statements.
  ///
  /// This method reads the pubspec.yaml file to extract the package name that
  /// should be used in import statements within generated test files.
  ///
  /// Returns:
  /// * The package name from pubspec.yaml
  /// * 'app' as fallback if pubspec.yaml cannot be read
  String _getPackageName() {
    try {
      final File pubspecFile = File('pubspec.yaml');
      if (pubspecFile.existsSync()) {
        final String content = pubspecFile.readAsStringSync();
        final RegExp namePattern = RegExp(r'name:\s*(.+)');
        final Match? match = namePattern.firstMatch(content);
        return match?.group(1)?.trim() ?? 'app';
      }
    } catch (error) {
      // Fallback to default package name
    }
    return 'app';
  }

  /// Converts a snake_case string to PascalCase.
  ///
  /// This utility method is used to generate appropriate class names when the
  /// primary class name cannot be extracted from the source file.
  ///
  /// Conversion rules:
  /// * Split on underscores and capitalize each part
  /// * Remove underscores and join parts
  /// * Ensure first character is uppercase
  ///
  /// Parameters:
  /// * [input] - The snake_case string to convert
  ///
  /// Returns:
  /// * PascalCase version of the input string
  String _toPascalCase(String input) {
    return input
        .split('_')
        .map((String part) => part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join();
  }

  /// Converts a snake_case string to camelCase.
  ///
  /// This utility method is used to generate appropriate variable names
  /// following Dart naming conventions.
  ///
  /// Conversion rules:
  /// * Split on underscores
  /// * Keep first part lowercase
  /// * Capitalize subsequent parts
  /// * Remove underscores and join parts
  ///
  /// Parameters:
  /// * [input] - The snake_case string to convert
  ///
  /// Returns:
  /// * camelCase version of the input string
  String _toCamelCase(String input) {
    final List<String> parts = input.split('_');
    if (parts.isEmpty) return input;

    final String firstPart = parts.first.toLowerCase();
    final List<String> remainingParts = parts
        .skip(1)
        .map((String part) => part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .toList();

    return [firstPart, ...remainingParts].join();
  }
}

/// Analysis results for a Dart source file.
///
/// This class contains metadata extracted from analyzing a Dart file, used for
/// generating appropriate test templates and import statements.
///
/// The analysis includes information about the primary class, file structure,
/// and dependencies that affect how tests should be generated.
class FileAnalysis {
  /// Creates a new file analysis result.
  ///
  /// All parameters are required as they provide essential information for test
  /// generation and template variable construction.
  const FileAnalysis({
    required this.className,
    required this.fileName,
    required this.filePath,
    required this.hasFlutterImports,
  });

  /// The name of the primary class in the analyzed file.
  ///
  /// Used for generating test class names and documentation. Extracted from the
  /// first public class declaration found in the file.
  final String className;

  /// The base file name without extension.
  ///
  /// Used for generating test file names and import statements. Derived from
  /// the file path by removing directory and extension.
  final String fileName;

  /// The full path to the analyzed file.
  ///
  /// Used for calculating relative import paths and determining the appropriate
  /// test file location.
  final String filePath;

  /// Whether the file contains Flutter framework imports.
  ///
  /// Used to determine if Flutter-specific testing utilities should be included
  /// in the generated test template.
  final bool hasFlutterImports;
}
