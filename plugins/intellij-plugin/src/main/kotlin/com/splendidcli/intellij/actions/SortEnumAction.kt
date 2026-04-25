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
 * Action to sort enum values alphabetically in Dart files.
 *
 * This action appears in the context menu when right-clicking .dart files
 * in the editor or project view. It executes the `splendid_cli sort-enum`
 * command on the selected file.
 *
 * The action is only visible and enabled when:
 * - A single file is selected
 * - The file has a .dart extension
 * - The project is available
 */
class SortEnumAction : AnAction() {

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
            val files: Array<VirtualFile>? = e.getData(CommonDataKeys.VIRTUAL_FILE_ARRAY)
            file = files?.firstOrNull()
        }

        if (file == null) {
            val psiFile: PsiFile? = e.getData(CommonDataKeys.PSI_FILE)
            file = psiFile?.virtualFile
        }

        if (file == null) {
            val psiElement = e.getData(CommonDataKeys.PSI_ELEMENT)
            if (psiElement is PsiFile) {
                file = psiElement.virtualFile
            }
        }

        if (file == null) {
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

        val place: String = e.place
        val isToolsMenu: Boolean = place.contains("MainMenu") || place == "ToolsMenu"

        if (isToolsMenu) {
            e.presentation.isVisible = hasProject
            e.presentation.isEnabled = isDartFile && hasProject
        } else {
            e.presentation.isEnabledAndVisible = isDartFile && hasProject
        }
    }

    /**
     * Executes the sort-enum command on the selected Dart file.
     *
     * This method runs the CLI command in a background task with progress
     * indication. After successful completion, the file is refreshed in the
     * IDE to show the changes.
     *
     * @param e The action event containing the selected file and project
     */
    override fun actionPerformed(e: AnActionEvent) {
        val project = e.project ?: return

        var file: VirtualFile? = e.getData(CommonDataKeys.VIRTUAL_FILE)

        if (file == null) {
            val files: Array<VirtualFile>? = e.getData(CommonDataKeys.VIRTUAL_FILE_ARRAY)
            file = files?.firstOrNull()
        }

        if (file == null) {
            val psiFile: PsiFile? = e.getData(CommonDataKeys.PSI_FILE)
            file = psiFile?.virtualFile
        }

        if (file == null) {
            val psiElement = e.getData(CommonDataKeys.PSI_ELEMENT)
            if (psiElement is PsiFile) {
                file = psiElement.virtualFile
            }
        }

        if (file == null) {
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

        ProgressManager.getInstance().run(object : Task.Backgroundable(
            project,
            "Sorting Enum Values",
            false
        ) {
            override fun run(indicator: ProgressIndicator) {
                indicator.text = "Running splendid_cli sort-enum on ${file.name}..."
                indicator.isIndeterminate = true

                try {
                    val result: CliExecutorService.CommandResult = cliExecutor.execute(
                        "sort-enum",
                        file.path
                    )

                    if (result.isSuccess) {
                        if (settings.autoRefreshFiles) {
                            file.refresh(false, false)
                        }

                        if (settings.showSuccessNotifications) {
                            cliExecutor.showNotification(
                                "Sort Successful",
                                "Enum values in ${file.name} sorted alphabetically",
                                NotificationType.INFORMATION
                            )
                        }
                    } else {
                        val errorMessage: String = if (result.stderr.isNotEmpty()) {
                            result.stderr
                        } else {
                            "Unknown error occurred (exit code: ${result.exitCode})"
                        }

                        cliExecutor.showNotification(
                            "Sort Failed",
                            "Failed to sort enums in ${file.name}: $errorMessage",
                            NotificationType.ERROR
                        )
                    }
                } catch (e: IllegalStateException) {
                    cliExecutor.showNotification(
                        "CLI Not Found",
                        e.message ?: "Splendid CLI could not be found",
                        NotificationType.ERROR
                    )
                } catch (e: Exception) {
                    cliExecutor.showNotification(
                        "Unexpected Error",
                        "An error occurred while sorting enums: ${e.message}",
                        NotificationType.ERROR
                    )
                }
            }
        })
    }
}
