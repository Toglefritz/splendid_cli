import 'package:flutter/material.dart';

/// Grid widget that displays command buttons for CLI operations.
///
/// This widget provides a visual interface for accessing all Splendid CLI
/// functionality through clickable buttons. It organizes commands into logical
/// groups and provides appropriate visual feedback for different states
/// (enabled, disabled, loading).
///
/// The grid includes buttons for:
/// * Project creation and management
/// * Screen generation with MVC architecture
/// * Test file generation
/// * Project setup and formatting utilities
/// * Other CLI tools and utilities
class CommandButtonsGrid extends StatelessWidget {
  /// Creates a new command buttons grid.
  ///
  /// Parameters:
  /// * [isLoading] - Whether a CLI operation is currently in progress
  /// * [isFlutterProject] - Whether the current directory is a Flutter project
  /// * [onCreateProject] - Callback for creating a new Flutter project
  /// * [onAddScreen] - Callback for adding a new screen to the project
  /// * [onGenerateTest] - Callback for generating test files
  /// * [onSetupProject] - Callback for running project setup commands
  /// * [onFormatProject] - Callback for formatting Dartdoc comments
  const CommandButtonsGrid({
    required this.isLoading,
    required this.isFlutterProject,
    required this.onCreateProject,
    required this.onAddScreen,
    required this.onGenerateTest,
    required this.onSetupProject,
    required this.onFormatProject,
    super.key,
  });

  /// Whether a CLI operation is currently in progress.
  ///
  /// Used to disable buttons and show loading indicators during command
  /// execution to prevent concurrent operations.
  final bool isLoading;

  /// Whether the current directory contains a Flutter project.
  ///
  /// Used to enable/disable Flutter-specific commands and provide appropriate
  /// visual feedback for unavailable operations.
  final bool isFlutterProject;

  /// Callback function for creating a new Flutter project.
  ///
  /// Should open a dialog for specifying project parameters and execute the CLI
  /// create command with the provided settings.
  final VoidCallback onCreateProject;

  /// Callback function for adding a new screen to the current project.
  ///
  /// Should open a dialog for specifying screen parameters and execute the CLI
  /// screen command. Requires a Flutter project.
  final VoidCallback onAddScreen;

  /// Callback function for generating test files.
  ///
  /// Should open a dialog for specifying test generation parameters and execute
  /// the CLI test generation command.
  final VoidCallback onGenerateTest;

  /// Callback function for running project setup commands.
  ///
  /// Executes the CLI setup command to run pub get, code generation, and other
  /// project initialization tasks.
  final VoidCallback onSetupProject;

  /// Callback function for formatting Dartdoc comments in the project.
  ///
  /// Executes the CLI format-dartdoc command to reformat and rewrap Dartdoc
  /// comments to the specified line length across all Dart files in the
  /// project.
  final VoidCallback onFormatProject;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: _calculateCrossAxisCount(context),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        // Create Project button
        _CommandButton(
          icon: Icons.add_circle_outline,
          title: 'Create Project',
          subtitle: 'Generate new Flutter app with MVC architecture',
          onPressed: isLoading ? null : onCreateProject,
          color: Theme.of(context).colorScheme.primary,
        ),

        // Add Screen button
        _CommandButton(
          icon: Icons.web_asset,
          title: 'Add Screen',
          subtitle: 'Generate new screen with route, controller, and view',
          onPressed: (isLoading || !isFlutterProject) ? null : onAddScreen,
          color: Theme.of(context).colorScheme.secondary,
          requiresFlutterProject: true,
          isFlutterProject: isFlutterProject,
        ),

        // Generate Test button
        _CommandButton(
          icon: Icons.bug_report,
          title: 'Generate Test',
          subtitle: 'Create test files for widgets and classes',
          onPressed: (isLoading || !isFlutterProject) ? null : onGenerateTest,
          color: Theme.of(context).colorScheme.tertiary,
          requiresFlutterProject: true,
          isFlutterProject: isFlutterProject,
        ),

        // Setup Project button
        _CommandButton(
          icon: Icons.build,
          title: 'Setup Project',
          subtitle: 'Run pub get and code generation',
          onPressed: (isLoading || !isFlutterProject) ? null : onSetupProject,
          color: Colors.orange,
          requiresFlutterProject: true,
          isFlutterProject: isFlutterProject,
        ),

        // Format Project button
        _CommandButton(
          icon: Icons.code,
          title: 'Format Dartdoc',
          subtitle: 'Reformat and rewrap Dartdoc comments',
          onPressed: (isLoading || !isFlutterProject) ? null : onFormatProject,
          color: Colors.green,
          requiresFlutterProject: true,
          isFlutterProject: isFlutterProject,
        ),

        // Cache Management button (placeholder for future implementation)
        const _CommandButton(
          icon: Icons.storage,
          title: 'Manage Cache',
          subtitle: 'Clear and manage CLI cache',
          onPressed: null, // TODO(Toglefritz): Implement cache management
          color: Colors.grey,
        ),
      ],
    );
  }

  /// Calculates the appropriate number of columns for the grid based on screen
  /// width.
  ///
  /// Provides responsive layout that adapts to different screen sizes:
  /// * Small screens (< 600px): 2 columns
  /// * Medium screens (600-900px): 3 columns
  /// * Large screens (> 900px): 4 columns
  ///
  /// Parameters:
  /// * [context] - Build context for accessing screen dimensions
  ///
  /// Returns:
  /// * Number of columns for the grid layout
  int _calculateCrossAxisCount(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) return 2;
    if (screenWidth < 900) return 3;

    return 4;
  }
}

/// Individual command button widget for the grid.
///
/// This widget represents a single CLI command with an icon, title, subtitle,
/// and appropriate visual states for enabled/disabled/loading conditions. It
/// provides consistent styling and behavior across all command buttons in the
/// grid.
class _CommandButton extends StatelessWidget {
  /// Creates a new command button.
  ///
  /// Parameters:
  /// * [icon] - Icon to display on the button
  /// * [title] - Primary title text for the command
  /// * [subtitle] - Descriptive subtitle explaining the command
  /// * [onPressed] - Callback function when button is pressed (null to disable)
  /// * [color] - Primary color for the button styling
  /// * [requiresFlutterProject] - Whether this command requires a Flutter project
  /// * [isFlutterProject] - Whether the current directory is a Flutter project
  const _CommandButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    required this.color,
    this.requiresFlutterProject = false,
    this.isFlutterProject = true,
  });

  /// Icon to display on the button.
  final IconData icon;

  /// Primary title text for the command.
  final String title;

  /// Descriptive subtitle explaining what the command does.
  final String subtitle;

  /// Callback function invoked when the button is pressed.
  ///
  /// Null value disables the button and shows appropriate visual feedback.
  final VoidCallback? onPressed;

  /// Primary color used for button styling and theming.
  final Color color;

  /// Whether this command requires a Flutter project to function.
  ///
  /// Used to show appropriate disabled states and tooltips when the current
  /// directory is not a Flutter project.
  final bool requiresFlutterProject;

  /// Whether the current directory contains a Flutter project.
  ///
  /// Used in combination with [requiresFlutterProject] to determine button
  /// availability and visual feedback.
  final bool isFlutterProject;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;
    final bool showFlutterWarning = requiresFlutterProject && !isFlutterProject;

    Widget button = Card(
      elevation: isEnabled ? 4 : 1,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Icon(
                  icon,
                  size: 32,
                  color: isEnabled ? color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isEnabled
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isEnabled
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (showFlutterWarning) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Icon(Icons.warning_amber, size: 16, color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // Add tooltip for disabled buttons
    if (!isEnabled) {
      String tooltipMessage;
      if (showFlutterWarning) {
        tooltipMessage = 'This command requires a Flutter project. Select a Flutter project directory to enable.';
      } else {
        tooltipMessage = 'This command is currently unavailable.';
      }

      button = Tooltip(message: tooltipMessage, child: button);
    }

    return button;
  }
}
