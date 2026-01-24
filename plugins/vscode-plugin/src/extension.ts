import * as vscode from 'vscode';
import { execFile } from 'child_process';
import { promisify } from 'util';

const execFileAsync = promisify(execFile);

/**
 * Activates the Splendid CLI Tools extension.
 * 
 * Registers all commands provided by the extension.
 */
export function activate(context: vscode.ExtensionContext): void {
  console.log('Splendid CLI Tools extension is now active!');
  
  const sortL10nCommand = vscode.commands.registerCommand(
    'splendid-cli.sortL10n',
    async (uri: vscode.Uri) => {
      console.log('Sort L10n command triggered for:', uri.fsPath);
      await sortL10nFile(uri);
    }
  );

  context.subscriptions.push(sortL10nCommand);
  console.log('Splendid CLI Tools: sortL10n command registered');
}

/**
 * Sorts an ARB localization file alphabetically.
 * 
 * @param uri - URI of the ARB file to sort
 */
async function sortL10nFile(uri: vscode.Uri): Promise<void> {
  const config = vscode.workspace.getConfiguration('splendidCli');
  const cliPath = config.get<string>('executablePath', 'splendid_cli');
  const filePath = uri.fsPath;

  try {
    await vscode.window.withProgress(
      {
        location: vscode.ProgressLocation.Notification,
        title: 'Sorting localizable strings...',
        cancellable: false,
      },
      async () => {
        await execFileAsync(cliPath, ['sort-l10n', filePath]);
      }
    );

    const showNotifications = config.get<boolean>('showNotifications', true);
    if (showNotifications) {
      vscode.window.showInformationMessage('Localizable strings sorted successfully');
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    vscode.window.showErrorMessage(`Failed to sort localizable strings: ${errorMessage}`);
  }
}

export function deactivate(): void {}
