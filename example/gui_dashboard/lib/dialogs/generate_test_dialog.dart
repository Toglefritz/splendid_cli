import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

/// Dialog widget for generating test files for Dart classes and Flutter widgets.
///
/// This dialog provides a user-friendly interface for specifying test generation parameters including target file
/// selection, test type, and force overwrite options. It validates user input and provides helpful feedback for
/// creating comprehensive test files with proper documentation structure.
///
/// The dialog includes:
/// * Target file selection with file picker and validation
/// * Test type selection (auto-detect, widget, class)
/// * Force overwrite option for existing test files
/// * File browser for easy Dart file selection
/// * Preview of the test file that will be generated
/// * Input validation and error feedback
class GenerateTestDialog extends StatefulWidget {
  /// Creates a new generate test dialog.
  ///
  /// Parameters:
  /// * [projectPath] - Path to the current project directory
  /// * [onGenerateTest] - Callback function for executing test generation
  const GenerateTestDialog({
    required this.projectPath,
    required this.onGenerateTest,
    super.key,
  });

  /// Path to the current project directory.
  ///
  /// Used as the base directory for file selection and validation. Null if no project is currently selected.
  final String? projectPath;

  /// Callback function invoked when the user confirms test generation.
  ///
  /// Receives the test parameters and should execute the CLI generate-test command with the specified settings.
  final Future<void> Function({
    required String targetFile,
    required String testType,
    required bool force,
  })
  onGenerateTest;

  @override
  State<GenerateTestDialog> createState() => _GenerateTestDialogState();
}

class _GenerateTestDialogState extends State<GenerateTestDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _targetFileController = TextEditingController();

  /// The selected test type for generation.
  ///
  /// Options: 'auto' (auto-detect), 'widget' (Flutter widget test), 'class' (Dart class test)
  String _testType = 'auto';

  /// Whether to force overwrite existing test files.
  bool _force = false;

  /// Whether the dialog is currently processing the generate test request.
  bool _isGenerating = false;

  @override
  void dispose() {
    _targetFileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate Test File'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target file field
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _targetFileController,
                  decoration: InputDecoration(
                    labelText: 'Target Dart File',
                    hintText: 'lib/models/user.dart',
                    helperText: 'Select the Dart file to generate tests for',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.file_open),
                      onPressed: _isGenerating ? null : _selectTargetFile,
                    ),
                  ),
                  validator: _validateTargetFile,
                  enabled: !_isGenerating,
                ),
              ),

              // Test type selection
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Test Type',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RadioGroup<String>(
                  groupValue: _testType,
                  onChanged: (String? value) {
                    setState(() {
                      _testType = value ?? 'auto';
                    });
                  },
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Radio<String>(
                          value: 'auto',
                        ),
                        title: const Text('Auto-detect'),
                        subtitle: const Text('Automatically determine test type based on file content'),
                        onTap: _isGenerating
                            ? null
                            : () {
                                setState(() {
                                  _testType = 'auto';
                                });
                              },
                        contentPadding: EdgeInsets.zero,
                      ),
                      ListTile(
                        leading: const Radio<String>(
                          value: 'widget',
                        ),
                        title: const Text('Widget Test'),
                        subtitle: const Text('Generate Flutter widget test with testWidgets'),
                        onTap: _isGenerating
                            ? null
                            : () {
                                setState(() {
                                  _testType = 'widget';
                                });
                              },
                        contentPadding: EdgeInsets.zero,
                      ),
                      ListTile(
                        leading: const Radio<String>(
                          value: 'class',
                        ),
                        title: const Text('Class Test'),
                        subtitle: const Text('Generate Dart class test with standard test functions'),
                        onTap: _isGenerating
                            ? null
                            : () {
                                setState(() {
                                  _testType = 'class';
                                });
                              },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),

              // Force overwrite option
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: CheckboxListTile(
                  title: const Text('Force overwrite existing test file'),
                  subtitle: const Text('Overwrite existing test files without confirmation'),
                  value: _force,
                  onChanged: _isGenerating
                      ? null
                      : (bool? value) {
                          setState(() {
                            _force = value ?? false;
                          });
                        },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),

              // Generated test file preview
              if (_targetFileController.text.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              'Generated Test File:',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _getTestFilePath(),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Command preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Command Preview:',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      _buildCommandPreview(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isGenerating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isGenerating ? null : _generateTest,
          child: _isGenerating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Generate Test'),
        ),
      ],
    );
  }

  /// Validates the target file input.
  ///
  /// Ensures the target file is a valid Dart file that exists in the project directory and can be used for test
  /// generation.
  ///
  /// Parameters:
  /// * [value] - The target file path to validate
  ///
  /// Returns:
  /// * Error message if validation fails, null if valid
  String? _validateTargetFile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Target file is required';
    }

    if (!value.endsWith('.dart')) {
      return 'Target file must be a Dart file (.dart extension)';
    }

    // Check if file exists (if project path is available)
    if (widget.projectPath != null) {
      final String fullPath = path.isAbsolute(value) ? value : path.join(widget.projectPath!, value);

      final File targetFile = File(fullPath);
      if (!targetFile.existsSync()) {
        return 'Target file does not exist';
      }
    }

    return null;
  }

  /// Opens a file picker for selecting the target Dart file.
  ///
  /// Allows users to browse and select a Dart file from the project directory for test generation. Updates the target
  /// file field with the selected path.
  Future<void> _selectTargetFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Dart File',
        type: FileType.custom,
        allowedExtensions: ['dart'],
        initialDirectory: widget.projectPath,
      );

      if (result != null && result.files.single.path != null) {
        String selectedPath = result.files.single.path!;

        // Make path relative to project if possible
        if (widget.projectPath != null && selectedPath.startsWith(widget.projectPath!)) {
          selectedPath = path.relative(selectedPath, from: widget.projectPath);
        }

        _targetFileController.text = selectedPath;
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select file: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Gets the path where the test file will be generated.
  ///
  /// Calculates the expected test file path based on the target file and Flutter testing conventions (mirroring lib/
  /// structure in test/).
  ///
  /// Returns:
  /// * Expected path for the generated test file
  String _getTestFilePath() {
    final String targetFile = _targetFileController.text;
    if (targetFile.isEmpty) {
      return 'test/<target_file>_test.dart';
    }

    String testPath = targetFile;

    // Remove lib/ prefix if present
    if (testPath.startsWith('lib/')) {
      testPath = testPath.substring(4);
    }

    // Replace .dart extension with _test.dart
    testPath = testPath.replaceAll('.dart', '_test.dart');

    return 'test/$testPath';
  }

  /// Builds a preview of the CLI command that will be executed.
  ///
  /// Shows users exactly what command will be run with their current settings, helping them understand the operation
  /// and verify parameters.
  ///
  /// Returns:
  /// * Formatted command string for display
  String _buildCommandPreview() {
    final StringBuffer command = StringBuffer('splendid_cli generate-test');

    if (_targetFileController.text.isNotEmpty) {
      command.write(' "${_targetFileController.text}"');
    } else {
      command.write(' <target_file>');
    }

    command.write(' --type $_testType');

    if (_force) {
      command.write(' --force');
    }

    return command.toString();
  }

  /// Executes the test generation with the specified parameters.
  ///
  /// Validates the form, collects all parameters, and calls the callback function to execute the CLI generate-test
  /// command. Handles loading states and error feedback appropriately.
  Future<void> _generateTest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      await widget.onGenerateTest(
        targetFile: _targetFileController.text,
        testType: _testType,
        force: _force,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate test: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
