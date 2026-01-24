package com.splendidcli.intellij.services

import com.intellij.execution.configurations.GeneralCommandLine
import com.intellij.execution.process.CapturingProcessHandler
import com.intellij.execution.process.ProcessOutput
import com.intellij.notification.NotificationGroupManager
import com.intellij.notification.NotificationType
import com.intellij.openapi.components.Service
import com.intellij.openapi.project.Project
import com.splendidcli.intellij.settings.PluginSettings
import java.io.File
import java.nio.charset.StandardCharsets

/**
 * Service for executing Splendid CLI commands.
 * 
 * This service handles CLI detection, command execution, and result processing.
 * It provides a consistent interface for all plugin actions to interact with
 * the CLI tool.
 */
@Service(Service.Level.PROJECT)
class CliExecutorService(private val project: Project) {

    /**
     * Result of a CLI command execution.
     * 
     * @property exitCode The process exit code (0 indicates success)
     * @property stdout Standard output from the command
     * @property stderr Standard error output from the command
     */
    data class CommandResult(
        val exitCode: Int,
        val stdout: String,
        val stderr: String
    ) {
        /**
         * Whether the command executed successfully.
         */
        val isSuccess: Boolean
            get() = exitCode == 0
    }

    /**
     * Executes a CLI command with the given arguments.
     * 
     * This method handles CLI path detection, command construction, and
     * execution with proper error handling.
     * 
     * @param command The CLI command to execute (e.g., "sort-l10n")
     * @param args Additional command-line arguments
     * @return CommandResult containing exit code and output
     * @throws IllegalStateException if CLI cannot be found
     */
    fun execute(command: String, vararg args: String): CommandResult {
        val cliPath: String = detectCliPath()
        
        val commandLine: GeneralCommandLine = GeneralCommandLine()
            .withExePath(cliPath)
            .withParameters(command)
            .withParameters(*args)
            .withWorkDirectory(project.basePath)
            .withCharset(StandardCharsets.UTF_8)

        val processHandler: CapturingProcessHandler = CapturingProcessHandler(commandLine)
        val output: ProcessOutput = processHandler.runProcess(30000) // 30 second timeout

        return CommandResult(
            exitCode = output.exitCode,
            stdout = output.stdout,
            stderr = output.stderr
        )
    }

    /**
     * Detects the path to the Splendid CLI executable.
     * 
     * Checks in order:
     * 1. User-configured path in plugin settings
     * 2. System PATH using 'which' command
     * 3. Common installation locations
     * 
     * @return Path to the CLI executable
     * @throws IllegalStateException if CLI cannot be found
     */
    private fun detectCliPath(): String {
        // Check plugin settings first
        val settings: PluginSettings = PluginSettings.getInstance(project)
        if (settings.cliPath.isNotEmpty() && File(settings.cliPath).exists()) {
            return settings.cliPath
        }

        // Check if 'splendid_cli' is in PATH
        try {
            val process: Process = Runtime.getRuntime().exec(arrayOf("which", "splendid_cli"))
            val pathResult: String = process.inputStream.bufferedReader().readText().trim()
            process.waitFor()
            
            if (pathResult.isNotEmpty() && File(pathResult).exists()) {
                return pathResult
            }
        } catch (e: Exception) {
            // 'which' command failed, continue to next detection method
        }

        // Check common installation locations
        val commonPaths: List<String> = listOf(
            "/usr/local/bin/splendid_cli",
            "/usr/bin/splendid_cli",
            System.getProperty("user.home") + "/.pub-cache/bin/splendid_cli"
        )

        for (path: String in commonPaths) {
            if (File(path).exists()) {
                return path
            }
        }

        throw IllegalStateException(
            "Splendid CLI not found. Please install it using 'dart pub global activate splendid_cli' " +
            "or configure the path in Settings → Tools → Splendid CLI Tools."
        )
    }

    /**
     * Shows a notification balloon in the IDE.
     * 
     * @param title Notification title
     * @param content Notification message content
     * @param type Notification type (information, warning, error)
     */
    fun showNotification(title: String, content: String, type: NotificationType) {
        NotificationGroupManager.getInstance()
            .getNotificationGroup("Splendid CLI Notifications")
            .createNotification(title, content, type)
            .notify(project)
    }
}
