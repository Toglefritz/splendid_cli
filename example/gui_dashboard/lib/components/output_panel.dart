import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Expandable panel widget that displays CLI command output and results.
///
/// This widget provides a collapsible interface for viewing command execution output, error messages, and progress
/// information. It includes features for copying output to clipboard and provides appropriate visual feedback for
/// different states (loading, success, error).
///
/// The panel displays:
/// * Real-time command output with monospace formatting
/// * Loading indicators during command execution
/// * Error highlighting and status indicators
/// * Copy to clipboard functionality
/// * Expandable/collapsible interface to save screen space
class OutputPanel extends StatelessWidget {
  /// Creates a new output panel.
  ///
  /// Parameters:
  /// * [isVisible] - Whether the panel is currently expanded and visible
  /// * [isLoading] - Whether a CLI operation is currently in progress
  /// * [output] - The command output text to display
  /// * [onToggle] - Callback function for expanding/collapsing the panel
  const OutputPanel({
    required this.isVisible,
    required this.isLoading,
    required this.output,
    required this.onToggle,
    super.key,
  });

  /// Whether the output panel is currently expanded and visible.
  ///
  /// Controls the visibility of the panel content while keeping the header bar always visible for toggling.
  final bool isVisible;

  /// Whether a CLI operation is currently in progress.
  ///
  /// Used to show loading indicators and prevent certain actions during command execution.
  final bool isLoading;

  /// The command output text to display in the panel.
  ///
  /// Contains combined stdout and stderr from CLI command execution, formatted for display with monospace font.
  final String output;

  /// Callback function for toggling panel visibility.
  ///
  /// Invoked when the user clicks the expand/collapse button to show or hide the panel content.
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Panel header with toggle button
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    if (isLoading) ...[
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.terminal,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],

                    Text(
                      isLoading ? 'Command Running...' : 'Command Output',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const Spacer(),

                    if (output.isNotEmpty && !isLoading) ...[
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          icon: const Icon(Icons.copy),
                          iconSize: 16,
                          tooltip: 'Copy Output',
                          onPressed: () => _copyToClipboard(context),
                        ),
                      ),
                    ],

                    Icon(
                      isVisible ? Icons.expand_less : Icons.expand_more,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Panel content (expandable)
          if (isVisible) ...[
            Container(
              constraints: const BoxConstraints(
                maxHeight: 300,
                minHeight: 100,
              ),
              width: double.infinity,
              color: Theme.of(context).colorScheme.surface,
              child: output.isEmpty ? _buildEmptyState(context) : _buildOutputContent(context),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the empty state display when no output is available.
  ///
  /// Shows a placeholder message and icon when there is no command output to display, providing visual feedback that
  /// the panel is functional but empty.
  ///
  /// Parameters:
  /// * [context] - Build context for accessing theme and styling
  ///
  /// Returns:
  /// * Widget displaying the empty state
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Icon(
                Icons.terminal,
                size: 32,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'No output yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              'Command output will appear here',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the output content display with scrollable text.
  ///
  /// Creates a scrollable text area with monospace font for displaying command output. Includes appropriate styling for
  /// readability and automatic scrolling to show the latest output.
  ///
  /// Parameters:
  /// * [context] - Build context for accessing theme and styling
  ///
  /// Returns:
  /// * Widget displaying the formatted command output
  Widget _buildOutputContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: SelectableText(
          output,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  /// Copies the command output to the system clipboard.
  ///
  /// Provides a convenient way for users to copy command output for sharing, debugging, or documentation purposes.
  /// Shows a snackbar confirmation when the copy operation completes successfully.
  ///
  /// Parameters:
  /// * [context] - Build context for showing snackbar feedback
  Future<void> _copyToClipboard(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: output));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.check_circle, color: Colors.white, size: 16),
                ),
                Text('Output copied to clipboard'),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.error, color: Colors.white, size: 16),
                ),
                Text('Failed to copy: $error'),
              ],
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}
