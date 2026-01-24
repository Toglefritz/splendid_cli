package com.splendidcli.intellij.settings

import com.intellij.openapi.components.PersistentStateComponent
import com.intellij.openapi.components.Service
import com.intellij.openapi.components.State
import com.intellij.openapi.components.Storage
import com.intellij.openapi.project.Project
import com.intellij.util.xmlb.XmlSerializerUtil

/**
 * Persistent settings for the Splendid CLI plugin.
 * 
 * These settings are stored per-project and persist across IDE restarts.
 * Settings can be configured through the plugin's settings page.
 */
@Service(Service.Level.PROJECT)
@State(
    name = "SplendidCliSettings",
    storages = [Storage("splendid-cli.xml")]
)
class PluginSettings : PersistentStateComponent<PluginSettings> {

    /**
     * Custom path to the Splendid CLI executable.
     * 
     * If empty, the plugin will attempt to auto-detect the CLI
     * from the system PATH or common installation locations.
     */
    var cliPath: String = ""

    /**
     * Whether to show notifications for successful operations.
     * 
     * When enabled, the plugin displays success notifications
     * for operations like sorting ARB files. Error notifications
     * are always shown regardless of this setting.
     */
    var showSuccessNotifications: Boolean = true

    /**
     * Whether to automatically refresh files in the IDE after CLI operations.
     * 
     * When enabled, files are automatically refreshed to show changes
     * made by CLI commands. Disable if you prefer manual refresh.
     */
    var autoRefreshFiles: Boolean = true

    override fun getState(): PluginSettings {
        return this
    }

    override fun loadState(state: PluginSettings) {
        XmlSerializerUtil.copyBean(state, this)
    }

    companion object {
        /**
         * Gets the plugin settings instance for the given project.
         * 
         * @param project The project to get settings for
         * @return The plugin settings instance
         */
        fun getInstance(project: Project): PluginSettings {
            return project.getService(PluginSettings::class.java)
        }
    }
}
