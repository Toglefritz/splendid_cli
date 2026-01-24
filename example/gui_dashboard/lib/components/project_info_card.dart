import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

/// Widget that displays information about the currently selected project.
///
/// This card shows the project path, Flutter project status, and provides a
/// quick way to select a different project folder. It serves as the primary
/// project context indicator in the dashboard.
///
/// The card displays:
/// * Current project directory path
/// * Flutter project detection status with appropriate icons
/// * Quick action button to select a different project folder
/// * Visual indicators for project status and validity
class ProjectInfoCard extends StatelessWidget {
  /// Creates a new project information card.
  ///
  /// Parameters:
  /// * [projectPath] - Current project directory path (null if none selected)
  /// * [isFlutterProject] - Whether the current directory contains a Flutter project
  /// * [onSelectFolder] - Callback function for selecting a different project folder
  const ProjectInfoCard({
    required this.projectPath,
    required this.isFlutterProject,
    required this.onSelectFolder,
    super.key,
  });

  /// The currently selected project directory path.
  ///
  /// Null if no project has been selected yet. Used to display the current
  /// working directory and determine project status.
  final String? projectPath;

  /// Whether the current directory contains a Flutter project.
  ///
  /// Determined by checking for pubspec.yaml with Flutter dependencies. Used to
  /// show appropriate status indicators and enable Flutter-specific features.
  final bool isFlutterProject;

  /// Callback function invoked when the user wants to select a different
  /// project folder.
  ///
  /// Should open a directory picker dialog and update the project path when a
  /// valid directory is selected.
  final VoidCallback onSelectFolder;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.folder,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Current Project',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onSelectFolder,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Select Folder'),
                  ),
                ],
              ),
            ),

            if (projectPath != null) ...[
              // Project path display
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
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              'Path:',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              projectPath!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              'Project Name:',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Text(
                            path.basename(projectPath!),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Project status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isFlutterProject
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFlutterProject ? Icons.flutter_dash : Icons.code,
                      size: 16,
                      color: isFlutterProject
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isFlutterProject ? 'Flutter Project' : 'Regular Directory',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isFlutterProject
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              if (isFlutterProject) ...[
                const SizedBox(height: 8),
                Text(
                  'Flutter-specific commands are available for this project.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'Select a Flutter project directory to access all features.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ] else ...[
              // No project selected state
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No Project Selected',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select a project folder to get started',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
