import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Dialog widget for creating new Flutter projects.
///
/// This dialog provides a user-friendly interface for specifying project creation parameters including project name,
/// output directory, target platforms, and force overwrite options. It validates user input and provides helpful
/// feedback for creating Flutter projects with MVC architecture.
///
/// The dialog includes:
/// * Project name input with validation
/// * Output directory selection with file picker
/// * Platform selection checkboxes for all Flutter platforms
/// * Force overwrite option for existing directories
/// * Input validation and error feedback
/// * Preview of the command that will be executed
class CreateProjectDialog extends StatefulWidget {
  /// Creates a new create project dialog.
  ///
  /// Parameters:
  /// * [onCreateProject] - Callback function for executing project creation
  const CreateProjectDialog({
    required this.onCreateProject,
    super.key,
  });

  /// Callback function invoked when the user confirms project creation.
  ///
  /// Receives the project parameters and should execute the CLI create command with the specified settings.
  final Future<void> Function({
    required String projectName,
    required String outputDirectory,
    required String platforms,
    required bool force,
  })
  onCreateProject;

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _outputDirectoryController = TextEditingController();

  /// Map of platform names to their selection state.
  ///
  /// Tracks which platforms are selected for the new Flutter project. All platforms are selected by default to match
  /// CLI behavior.
  final Map<String, bool> _platforms = {
    'android': true,
    'ios': true,
    'web': true,
    'windows': true,
    'macos': true,
    'linux': true,
  };

  /// Whether to force overwrite existing directories.
  bool _force = false;

  /// Whether the dialog is currently processing the create request.
  bool _isCreating = false;

  @override
  void dispose() {
    _projectNameController.dispose();
    _outputDirectoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Flutter Project'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project name field
                TextFormField(
                  controller: _projectNameController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name',
                    hintText: 'my_awesome_app',
                    helperText: 'Must be a valid Dart package name',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateProjectName,
                  enabled: !_isCreating,
                ),

                const SizedBox(height: 16),

                // Output directory field
                TextFormField(
                  controller: _outputDirectoryController,
                  decoration: InputDecoration(
                    labelText: 'Output Directory',
                    hintText: 'Leave empty for current directory',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.folder_open),
                      onPressed: _isCreating ? null : _selectOutputDirectory,
                    ),
                  ),
                  enabled: !_isCreating,
                ),

                const SizedBox(height: 16),

                // Platform selection
                Text(
                  'Target Platforms',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _platforms.entries.map((MapEntry<String, bool> entry) {
                    return FilterChip(
                      label: Text(_getPlatformDisplayName(entry.key)),
                      selected: entry.value,
                      onSelected: _isCreating
                          ? null
                          : (bool selected) {
                              setState(() {
                                _platforms[entry.key] = selected;
                              });
                            },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Force overwrite option
                CheckboxListTile(
                  title: const Text('Force overwrite existing directory'),
                  subtitle: const Text('Overwrite existing files without confirmation'),
                  value: _force,
                  onChanged: _isCreating
                      ? null
                      : (bool? value) {
                          setState(() {
                            _force = value ?? false;
                          });
                        },
                  controlAffinity: ListTileControlAffinity.leading,
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
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
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
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createProject,
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Project'),
        ),
      ],
    );
  }

  /// Validates the project name input.
  ///
  /// Ensures the project name follows Dart package naming conventions:
  /// * Contains only lowercase letters, numbers, and underscores
  /// * Starts with a letter
  /// * Does not end with an underscore
  /// * Is not empty
  ///
  /// Parameters:
  /// * [value] - The project name to validate
  ///
  /// Returns:
  /// * Error message if validation fails, null if valid
  String? _validateProjectName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Project name is required';
    }

    // Check for valid Dart package name format
    final RegExp validName = RegExp(r'^[a-z][a-z0-9_]*[a-z0-9]$|^[a-z]$');
    if (!validName.hasMatch(value)) {
      return 'Must be a valid Dart package name (lowercase, letters, numbers, underscores)';
    }

    return null;
  }

  /// Opens a directory picker for selecting the output directory.
  ///
  /// Allows users to browse and select a directory where the new Flutter project should be created. Updates the output
  /// directory field with the selected path.
  Future<void> _selectOutputDirectory() async {
    try {
      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Output Directory',
      );

      if (selectedDirectory != null) {
        _outputDirectoryController.text = selectedDirectory;
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select directory: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Gets the display name for a platform identifier.
  ///
  /// Converts platform keys to user-friendly display names with proper capitalization and formatting.
  ///
  /// Parameters:
  /// * [platform] - The platform key to convert
  ///
  /// Returns:
  /// * User-friendly display name for the platform
  String _getPlatformDisplayName(String platform) {
    switch (platform) {
      case 'android':
        return 'Android';
      case 'ios':
        return 'iOS';
      case 'web':
        return 'Web';
      case 'windows':
        return 'Windows';
      case 'macos':
        return 'macOS';
      case 'linux':
        return 'Linux';
      default:
        return platform;
    }
  }

  /// Builds a preview of the CLI command that will be executed.
  ///
  /// Shows users exactly what command will be run with their current settings, helping them understand the operation
  /// and verify parameters.
  ///
  /// Returns:
  /// * Formatted command string for display
  String _buildCommandPreview() {
    final StringBuffer command = StringBuffer('splendid_cli create');

    if (_projectNameController.text.isNotEmpty) {
      command.write(' ${_projectNameController.text}');
    } else {
      command.write(' <project_name>');
    }

    if (_outputDirectoryController.text.isNotEmpty) {
      command.write(' --output-directory "${_outputDirectoryController.text}"');
    }

    final List<String> selectedPlatforms = _platforms.entries
        .where((MapEntry<String, bool> entry) => entry.value)
        .map((MapEntry<String, bool> entry) => entry.key)
        .toList();

    if (selectedPlatforms.isNotEmpty) {
      command.write(' --platforms ${selectedPlatforms.join(',')}');
    }

    if (_force) {
      command.write(' --force');
    }

    return command.toString();
  }

  /// Executes the project creation with the specified parameters.
  ///
  /// Validates the form, collects all parameters, and calls the callback function to execute the CLI create command.
  /// Handles loading states and error feedback appropriately.
  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final List<String> selectedPlatforms = _platforms.entries
        .where((MapEntry<String, bool> entry) => entry.value)
        .map((MapEntry<String, bool> entry) => entry.key)
        .toList();

    if (selectedPlatforms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one target platform'),
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      await widget.onCreateProject(
        projectName: _projectNameController.text,
        outputDirectory: _outputDirectoryController.text,
        platforms: selectedPlatforms.join(','),
        force: _force,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create project: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
