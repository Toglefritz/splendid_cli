import 'package:flutter/material.dart';

/// Dialog widget for adding new screens to Flutter projects.
///
/// This dialog provides a user-friendly interface for specifying screen generation parameters including screen name and
/// force overwrite options. It validates user input and provides helpful feedback for creating screens with MVC
/// architecture (route, controller, view).
///
/// The dialog includes:
/// * Screen name input with validation
/// * Force overwrite option for existing screen files
/// * Input validation and error feedback
/// * Preview of the command that will be executed
/// * Examples and guidance for screen naming conventions
class AddScreenDialog extends StatefulWidget {
  /// Creates a new add screen dialog.
  ///
  /// Parameters:
  /// * [onAddScreen] - Callback function for executing screen generation
  const AddScreenDialog({
    required this.onAddScreen,
    super.key,
  });

  /// Callback function invoked when the user confirms screen creation.
  ///
  /// Receives the screen parameters and should execute the CLI screen command with the specified settings.
  final Future<void> Function({
    required String screenName,
    required bool force,
  })
  onAddScreen;

  @override
  State<AddScreenDialog> createState() => _AddScreenDialogState();
}

class _AddScreenDialogState extends State<AddScreenDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _screenNameController = TextEditingController();

  /// Whether to force overwrite existing screen files.
  bool _force = false;

  /// Whether the dialog is currently processing the add screen request.
  bool _isAdding = false;

  @override
  void dispose() {
    _screenNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Screen'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen name field
              TextFormField(
                controller: _screenNameController,
                decoration: const InputDecoration(
                  labelText: 'Screen Name',
                  hintText: 'LoginScreen, UserProfile, Settings',
                  helperText: 'Use PascalCase for screen names',
                  border: OutlineInputBorder(),
                ),
                validator: _validateScreenName,
                enabled: !_isAdding,
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 16),

              // Generated files preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Generated Files:',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._getGeneratedFiles().map(
                      (String file) => Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 2),
                        child: Text(
                          '• $file',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Force overwrite option
              CheckboxListTile(
                title: const Text('Force overwrite existing files'),
                subtitle: const Text('Overwrite existing screen files without confirmation'),
                value: _force,
                onChanged: _isAdding
                    ? null
                    : (bool? value) {
                        setState(() {
                          _force = value ?? false;
                        });
                      },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 16),

              // Command preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Command Preview:',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
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
          onPressed: _isAdding ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isAdding ? null : _addScreen,
          child: _isAdding
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Screen'),
        ),
      ],
    );
  }

  /// Validates the screen name input.
  ///
  /// Ensures the screen name follows Dart class naming conventions:
  /// * Contains only letters, numbers, and underscores
  /// * Starts with an uppercase letter (PascalCase)
  /// * Is not empty
  /// * Does not contain spaces or special characters
  ///
  /// Parameters:
  /// * [value] - The screen name to validate
  ///
  /// Returns:
  /// * Error message if validation fails, null if valid
  String? _validateScreenName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Screen name is required';
    }

    // Check for valid Dart class name format (PascalCase)
    final RegExp validName = RegExp(r'^[A-Z][a-zA-Z0-9_]*$');
    if (!validName.hasMatch(value)) {
      return 'Must be a valid class name (PascalCase, letters, numbers, underscores)';
    }

    // Check for common naming patterns
    if (value.contains(' ')) {
      return 'Screen name cannot contain spaces';
    }

    if (value.length < 2) {
      return 'Screen name must be at least 2 characters long';
    }

    return null;
  }

  /// Gets the list of files that will be generated for the screen.
  ///
  /// Returns a list of file paths that will be created when the screen is generated, based on the current screen name
  /// input.
  ///
  /// Returns:
  /// * List of file paths that will be generated
  List<String> _getGeneratedFiles() {
    final String screenName = _screenNameController.text;
    if (screenName.isEmpty) {
      return [
        'lib/screens/<screen_name>/<screen_name>_route.dart',
        'lib/screens/<screen_name>/<screen_name>_controller.dart',
        'lib/screens/<screen_name>/<screen_name>_view.dart',
      ];
    }

    final String snakeCaseName = _toSnakeCase(screenName);
    return [
      'lib/screens/$snakeCaseName/${snakeCaseName}_route.dart',
      'lib/screens/$snakeCaseName/${snakeCaseName}_controller.dart',
      'lib/screens/$snakeCaseName/${snakeCaseName}_view.dart',
    ];
  }

  /// Converts a PascalCase string to snake_case.
  ///
  /// Transforms the screen name to the appropriate file naming convention used by the CLI for generating screen files.
  ///
  /// Parameters:
  /// * [input] - The PascalCase string to convert
  ///
  /// Returns:
  /// * snake_case version of the input string
  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp('[A-Z]'), (Match match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst(RegExp('^_'), '');
  }

  /// Builds a preview of the CLI command that will be executed.
  ///
  /// Shows users exactly what command will be run with their current settings, helping them understand the operation
  /// and verify parameters.
  ///
  /// Returns:
  /// * Formatted command string for display
  String _buildCommandPreview() {
    final StringBuffer command = StringBuffer('splendid_cli screen');

    if (_screenNameController.text.isNotEmpty) {
      command.write(' ${_screenNameController.text}');
    } else {
      command.write(' <screen_name>');
    }

    if (_force) {
      command.write(' --force');
    }

    return command.toString();
  }

  /// Executes the screen creation with the specified parameters.
  ///
  /// Validates the form, collects all parameters, and calls the callback function to execute the CLI screen command.
  /// Handles loading states and error feedback appropriately.
  Future<void> _addScreen() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isAdding = true;
    });

    try {
      await widget.onAddScreen(
        screenName: _screenNameController.text,
        force: _force,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add screen: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
