package com.splendidcli.intellij.actions

import com.intellij.openapi.actionSystem.AnAction
import com.intellij.openapi.actionSystem.AnActionEvent
import com.intellij.openapi.actionSystem.CommonDataKeys
import com.intellij.openapi.actionSystem.PlatformDataKeys
import com.intellij.openapi.progress.ProgressIndicator
import com.intellij.openapi.progress.ProgressManager
import com.intellij.openapi.progress.Task
import com.intellij.openapi.vfs.VirtualFile
import com.intellij.notification.NotificationType
import com.intellij.psi.PsiFile
import com.intellij.ide.projectView.impl.nodes.PsiFileNode
import com.splendidcli.intellij.services.CliExecutorService
import com.splendidcli.intellij.settings.PluginSettings

/**
 * Action to format regular comments in Dart files to 80 character line length.
 * 
 * This action appears in the context menu when right-clicking .dart files
 * in the editor or project view. It executes the `splendid_cli format-comments`
 * command with a line length of 80 characters on the selected file.
 * 
 * The action is only visible and enabled when:
 * - A single file is selected
 * - The file has a .dart extension
 * - The project is available
 */
class FormatComments80Action : AnAction() {

    /**
     * Updates the action's visibility and enabled state.
     * 
     * This method is called frequently by the IDE to determine whether
     * the action should be shown and enabled in the current context.
     * 
     * @param e The action event containing context information
     */
    override fun update(e: AnActionEvent) {
        val project = e.project
        
        // Try multiple ways to get the selected file
        var file: VirtualFile? = e.getData(CommonDataKeys.VIRTUAL_FILE)
        
        if (file == null) {
            // Try getting from file array (project view selection)
            val files: Array<VirtualFile>? = e.getData(CommonDataKeys.VIRTUAL_FILE_ARRAY)
            file = files?.firstOrNull()
        }
        
        if (file == null) {
            // Try getting from PSI file
            val psiFile: PsiFile? = e.getData(CommonDataKeys.PSI_FILE)
            file = psiFile?.virtualFile
        }
        
        if (file == null) {
            // Try getting from PSI element
            val psiElement = e.getData(CommonDataKeys.PSI_ELEMENT)
            if (psiElement is PsiFile) {
                file = psiElement.virtualFile
            }
        }
        
        if (file == null) {
            // Try getting from selected items (project view nodes)
            val selectedItems: Array<Any>? = e.getData(PlatformDataKeys.SELECTED_ITEMS)
            if (selectedItems != null && selectedItems.isNotEmpty()) {
                val firstItem: Any = selectedItems[0]
                when (firstItem) {
                    is VirtualFile -> file = firstItem
                    is PsiFileNode -> file = firstItem.virtualFile
                }
            }
        }
        
        val isDartFile: Boolean = file?.extension == "dart"
        val hasProject: Boolean = project != null
        
        // For Tools menu: always visible, enabled only for .dart files
        // For context menus: only show and enable for .dart files
        val place: String = e.place
        val isToolsMenu: Boolean = place.contains("MainMenu") || place == "ToolsMenu"
        
        if (isToolsMenu) {
            // Tools menu: always visible, enabled only for .dart files
            e.presentation.isVisible = hasProject
            e.presentation.isEnabled = isDartFile && hasProject
        } else {
            // Context menus: only show for .dart files
            e.presentation.isEnabledAndVisible = isDartFile && hasProject
        }
    }

    /**
     * Executes the format-comments command on the selected Dart file with 80 character line length.
     * 
     * This method runs the CLI command in a background task with progress
     * indication. After successful completion, the file is refreshed in the
     * IDE to show the changes.
     * 
     * @param e The action event containing the selected file and project
     */
    override fun actionPerformed(e: AnActionEvent) {
        val project = e.project ?: return
        
        // Try multiple ways to get the selected file
        var file: VirtualFile? = e.getData(CommonDataKeys.VIRTUAL_FILE)
        
        if (file == null) {
            // Try getting from file array (project view selection)
            val files: Array<VirtualFile>? = e.getData(CommonDataKeys.VIRTUAL_FILE_ARRAY)
            file = files?.firstOrNull()
        }
        
        if (file == null) {
            // Try getting from PSI file
            val psiFile: PsiFile? = e.getData(CommonDataKeys.PSI_FILE)
            file = psiFile?.virtualFile
        }
        
        if (file == null) {
            // Try getting from PSI element
            val psiElement = e.getData(CommonDataKeys.PSI_ELEMENT)
            if (psiElement is PsiFile) {
                file = psiElement.virtualFile
            }
        }
        
        if (file == null) {
            // Try getting from selected items (alternative for project view)
            val selectedItems: Array<Any>? = e.getData(PlatformDataKeys.SELECTED_ITEMS)
            if (selectedItems != null && selectedItems.isNotEmpty()) {
                val firstItem: Any = selectedItems[0]
                when (firstItem) {
                    is VirtualFile -> file = firstItem
                    is PsiFileNode -> file = firstItem.virtualFile
                }
            }
        }
        
        if (file == null) return
        
        val cliExecutor: CliExecutorService = project.getService(CliExecutorService::class.java)
        val settings: PluginSettings = PluginSettings.getInstance(project)

        // Run the CLI command in a background task
        ProgressManager.getInstance().run(object : Task.Backgroundable(
            project,
            "Formatting Regular Comments (80 chars)",
            false
        ) {
            override fun run(indicator: ProgressIndicator) {
                indicator.text = "Running splendid_cli format-comments on ${file.name}..."
                indicator.isIndeterminate = true
                
                try {
                    val result: CliExecutorService.CommandResult = cliExecutor.execute(
                        "format-comments",
                        file.path,
                        "--line-length",
                        "80"
                    )

                    if (result.isSuccess) {
                        // Refresh file in IDE to show changes
                        if (settings.autoRefreshFiles) {
                            file.refresh(false, false)
                        }
                        
                        // Show success notification if enabled
                        if (settings.showSuccessNotifications) {
                            cliExecutor.showNotification(
                                "Format Successful",
                                "Regular comments in ${file.name} formatted to 80 characters",
                                NotificationType.INFORMATION
                            )
                        }
                    } else {
                        // Show error notification
                        val errorMessage: String = if (result.stderr.isNotEmpty()) {
                            result.stderr
                        } else {
                            "Unknown error occurred (exit code: ${result.exitCode})"
                        }
                        
                        cliExecutor.showNotification(
                            "Format Failed",
                            "Failed to format ${file.name}: $errorMessage",
                            NotificationType.ERROR
                        )
                    }
                } catch (e: IllegalStateException) {
                    // CLI not found or configuration error
                    cliExecutor.showNotification(
                        "CLI Not Found",
                        e.message ?: "Splendid CLI could not be found",
                        NotificationType.ERROR
                    )
                } catch (e: Exception) {
                    // Unexpected error during execution
                    cliExecutor.showNotification(
                        "Unexpected Error",
                        "An error occurred while formatting: ${e.message}",
                        NotificationType.ERROR
                    )
                }
            }
        })
    }
}
