package com.splendidcli.intellij.settings

import com.intellij.openapi.fileChooser.FileChooserDescriptorFactory
import com.intellij.openapi.options.Configurable
import com.intellij.openapi.project.Project
import com.intellij.openapi.ui.TextFieldWithBrowseButton
import com.intellij.ui.components.JBCheckBox
import com.intellij.ui.components.JBLabel
import com.intellij.util.ui.FormBuilder
import javax.swing.JComponent
import javax.swing.JPanel

/**
 * Configurable component for the plugin settings page.
 * 
 * This class creates the UI for the plugin's settings page in the
 * IDE preferences and handles saving/loading of settings values.
 */
class PluginSettingsConfigurable(private val project: Project) : Configurable {

    private var cliPathField: TextFieldWithBrowseButton? = null
    private var showSuccessNotificationsCheckbox: JBCheckBox? = null
    private var autoRefreshFilesCheckbox: JBCheckBox? = null

    /**
     * Returns the display name for the settings page.
     */
    override fun getDisplayName(): String {
        return "Splendid CLI Tools"
    }

    /**
     * Creates the settings UI component.
     * 
     * This method builds the form with all configurable options
     * including CLI path selection and behavior preferences.
     */
    override fun createComponent(): JComponent {
        val cliPathFieldInstance: TextFieldWithBrowseButton = TextFieldWithBrowseButton()
        cliPathFieldInstance.addBrowseFolderListener(
            "Select Splendid CLI Executable",
            "Choose the path to the splendid_cli executable",
            project,
            FileChooserDescriptorFactory.createSingleFileDescriptor()
        )
        cliPathField = cliPathFieldInstance

        val showSuccessNotificationsCheckboxInstance: JBCheckBox = JBCheckBox(
            "Show success notifications"
        )
        showSuccessNotificationsCheckbox = showSuccessNotificationsCheckboxInstance

        val autoRefreshFilesCheckboxInstance: JBCheckBox = JBCheckBox(
            "Automatically refresh files after CLI operations"
        )
        autoRefreshFilesCheckbox = autoRefreshFilesCheckboxInstance

        return FormBuilder.createFormBuilder()
            .addLabeledComponent(
                JBLabel("CLI executable path:"),
                cliPathFieldInstance,
                1,
                false
            )
            .addComponent(
                JBLabel("Leave empty to auto-detect from system PATH"),
                1
            )
            .addVerticalGap(10)
            .addComponent(showSuccessNotificationsCheckboxInstance)
            .addComponent(autoRefreshFilesCheckboxInstance)
            .addComponentFillVertically(JPanel(), 0)
            .panel
    }

    /**
     * Checks if the settings have been modified.
     * 
     * @return true if any setting has been changed from its saved value
     */
    override fun isModified(): Boolean {
        val settings: PluginSettings = PluginSettings.getInstance(project)
        return cliPathField?.text != settings.cliPath ||
               showSuccessNotificationsCheckbox?.isSelected != settings.showSuccessNotifications ||
               autoRefreshFilesCheckbox?.isSelected != settings.autoRefreshFiles
    }

    /**
     * Applies the current UI values to the settings.
     * 
     * This method is called when the user clicks "Apply" or "OK"
     * in the settings dialog.
     */
    override fun apply() {
        val settings: PluginSettings = PluginSettings.getInstance(project)
        settings.cliPath = cliPathField?.text ?: ""
        settings.showSuccessNotifications = showSuccessNotificationsCheckbox?.isSelected ?: true
        settings.autoRefreshFiles = autoRefreshFilesCheckbox?.isSelected ?: true
    }

    /**
     * Resets the UI to show the current saved settings values.
     * 
     * This method is called when the settings page is opened or
     * when the user clicks "Reset" in the settings dialog.
     */
    override fun reset() {
        val settings: PluginSettings = PluginSettings.getInstance(project)
        cliPathField?.text = settings.cliPath
        showSuccessNotificationsCheckbox?.isSelected = settings.showSuccessNotifications
        autoRefreshFilesCheckbox?.isSelected = settings.autoRefreshFiles
    }
}
