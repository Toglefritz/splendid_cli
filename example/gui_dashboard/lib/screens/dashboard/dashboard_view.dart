import 'package:flutter/material.dart';

import '../../components/command_buttons_grid.dart';
import '../../components/output_panel.dart';
import '../../components/project_info_card.dart';
import '../../dialogs/add_screen_dialog.dart';
import '../../dialogs/create_project_dialog.dart';
import '../../dialogs/generate_test_dialog.dart';
import 'dashboard_controller.dart';

/// View widget for the main dashboard screen.
///
/// This view provides the user interface for the Splendid CLI GUI Dashboard,
/// displaying project information, command buttons, and output panels. It
/// follows the MVC pattern by receiving the controller as a parameter and
/// delegating all business logic to the controller.
///
/// The dashboard layout includes:
/// * App bar with title and project selection
/// * Project information card showing current project status
/// * Grid of command buttons for CLI operations
/// * Expandable output panel for command results
/// * Error display and loading indicators
class DashboardView extends StatelessWidget {
  /// Creates a new dashboard view.
  ///
  /// Parameters:
  /// * [state] - The dashboard controller containing state and business logic
  const DashboardView(this.state, {super.key});

  /// The dashboard controller that manages state and handles user interactions.
  final DashboardController state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Splendid CLI Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Select Project Folder',
            onPressed: state.selectProjectFolder,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Error banner
          if (state.errorMessage != null)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),

                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    onPressed: state.clearError,
                  ),
                ],
              ),
            ),

          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Project information card
                  ProjectInfoCard(
                    projectPath: state.currentProjectPath,
                    isFlutterProject: state.isFlutterProject,
                    onSelectFolder: state.selectProjectFolder,
                  ),

                  const SizedBox(height: 24),

                  // Command buttons grid
                  Expanded(
                    child: CommandButtonsGrid(
                      isLoading: state.isLoading,
                      isFlutterProject: state.isFlutterProject,
                      onCreateProject: () => _showCreateProjectDialog(context),
                      onAddScreen: () => _showAddScreenDialog(context),
                      onGenerateTest: () => _showGenerateTestDialog(context),
                      onSetupProject: state.setupProject,
                      onFormatProject: state.formatProject,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Output panel
          OutputPanel(
            isVisible: state.showOutput,
            isLoading: state.isLoading,
            output: state.commandOutput,
            onToggle: state.toggleOutputPanel,
          ),
        ],
      ),
    );
  }

  /// Shows the create project dialog.
  ///
  /// Displays a modal dialog that allows users to specify project creation
  /// parameters including name, output directory, and target platforms.
  ///
  /// Parameters:
  /// * [context] - The build context for showing the dialog
  Future<void> _showCreateProjectDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => CreateProjectDialog(
        onCreateProject: state.createProject,
      ),
    );
  }

  /// Shows the add screen dialog.
  ///
  /// Displays a modal dialog that allows users to specify screen generation
  /// parameters including screen name and force overwrite options.
  ///
  /// Parameters:
  /// * [context] - The build context for showing the dialog
  Future<void> _showAddScreenDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AddScreenDialog(
        onAddScreen: state.addScreen,
      ),
    );
  }

  /// Shows the generate test dialog.
  ///
  /// Displays a modal dialog that allows users to specify test generation
  /// parameters including target file, test type, and force overwrite options.
  ///
  /// Parameters:
  /// * [context] - The build context for showing the dialog
  Future<void> _showGenerateTestDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => GenerateTestDialog(
        projectPath: state.currentProjectPath,
        onGenerateTest: state.generateTest,
      ),
    );
  }
}
