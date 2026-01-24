package com.splendidcli.intellij.actions

import com.intellij.openapi.actionSystem.AnAction
import com.intellij.openapi.actionSystem.AnActionEvent
import com.intellij.openapi.progress.ProgressIndicator
import com.intellij.openapi.progress.ProgressManager
import com.intellij.openapi.progress.Task
import com.intellij.openapi.ui.Messages
import com.intellij.openapi.vfs.VirtualFile
import com.intellij.openapi.vfs.LocalFileSystem
import com.intellij.notification.NotificationType
import com.splendidcli.intellij.services.CliExecutorService
import com.splendidcli.intellij.settings.PluginSettings

/**
 * Action to create a new Flutter screen with MVC architecture.
 * 
 * This action appears in the Tools → Splendid CLI menu. It prompts the user
 * for a screen name and executes the `splendid_cli screen` command with the
 * --blank flag to create a new screen in lib/screens/.
 * 
 * The action is only enabled when a project is available.
 */
class CreateScreenAction : AnAction() {

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
        e.presentation.isEnabledAndVisible = project != null
    }

    /**
     * Executes the screen creation command after prompting for a screen name.
     * 
     * This method displays a dialog to collect the screen name from the user,
     * then runs the CLI command in a background task with progress indication.
     * After successful completion, the lib/screens directory is refreshed to show the new files.
     * 
     * @param e The action event containing the project
     */
    override fun actionPerformed(e: AnActionEvent) {
        val project = e.project ?: return
        
        // Prompt user for screen name
        val screenName: String? = Messages.showInputDialog(
            project,
            "Enter the name for the new screen:",
            "Create Flutter Screen",
            Messages.getQuestionIcon()
        )
        
        // User cancelled or entered empty name
        if (screenName.isNullOrBlank()) {
            return
        }
        
        val cliExecutor: CliExecutorService = project.getService(CliExecutorService::class.java)
        val settings: PluginSettings = PluginSettings.getInstance(project)

        // Run the CLI command in a background task
        ProgressManager.getInstance().run(object : Task.Backgroundable(
            project,
            "Creating Flutter Screen: $screenName",
            false
        ) {
            override fun run(indicator: ProgressIndicator) {
                indicator.text = "Running splendid_cli screen $screenName --blank..."
                indicator.isIndeterminate = true
                
                try {
                    val result: CliExecutorService.CommandResult = cliExecutor.execute(
                        "screen",
                        screenName,
                        "--blank"
                    )

                    if (result.isSuccess) {
                        // Refresh the lib/screens directory where files are created
                        if (settings.autoRefreshFiles) {
                            com.intellij.openapi.application.ApplicationManager.getApplication().invokeLater {
                                val fileSystem = LocalFileSystem.getInstance()
                                
                                // Refresh lib directory and its children
                                val libPath: String = "${project.basePath}/lib"
                                val libDir: VirtualFile? = fileSystem.refreshAndFindFileByPath(libPath)
                                libDir?.refresh(false, true)
                                
                                // Also explicitly refresh lib/screens
                                val libScreensPath: String = "${project.basePath}/lib/screens"
                                val libScreensDir: VirtualFile? = fileSystem.refreshAndFindFileByPath(libScreensPath)
                                libScreensDir?.refresh(false, true)
                            }
                        }
                        
                        // Show success notification with output
                        if (settings.showSuccessNotifications) {
                            val message: String = if (result.stdout.isNotEmpty()) {
                                "Flutter screen '$screenName' created successfully\n\n${result.stdout}"
                            } else {
                                "Flutter screen '$screenName' created successfully"
                            }
                            
                            cliExecutor.showNotification(
                                "Screen Created",
                                message,
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
                            "Screen Creation Failed",
                            "Failed to create screen '$screenName': $errorMessage",
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
                        "An error occurred while creating screen: ${e.message}",
                        NotificationType.ERROR
                    )
                }
            }
        })
    }
}
