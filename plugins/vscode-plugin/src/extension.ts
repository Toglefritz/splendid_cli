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

  const formatDartdoc80Command = vscode.commands.registerCommand(
    'splendid-cli.formatDartdoc80',
    async (uri: vscode.Uri) => {
      console.log('Format Dartdoc 80 command triggered for:', uri.fsPath);
      await formatDartdocFile(uri, 80);
    }
  );

  const formatDartdoc120Command = vscode.commands.registerCommand(
    'splendid-cli.formatDartdoc120',
    async (uri: vscode.Uri) => {
      console.log('Format Dartdoc 120 command triggered for:', uri.fsPath);
      await formatDartdocFile(uri, 120);
    }
  );

  const formatComments80Command = vscode.commands.registerCommand(
    'splendid-cli.formatComments80',
    async (uri: vscode.Uri) => {
      console.log('Format Comments 80 command triggered for:', uri.fsPath);
      await formatCommentsFile(uri, 80);
    }
  );

  const formatComments120Command = vscode.commands.registerCommand(
    'splendid-cli.formatComments120',
    async (uri: vscode.Uri) => {
      console.log('Format Comments 120 command triggered for:', uri.fsPath);
      await formatCommentsFile(uri, 120);
    }
  );

  const createScreenCommand = vscode.commands.registerCommand(
    'splendid-cli.createScreen',
    async () => {
      console.log('Create Screen command triggered');
      await createScreen();
    }
  );

  context.subscriptions.push(sortL10nCommand, formatDartdoc80Command, formatDartdoc120Command, formatComments80Command, formatComments120Command, createScreenCommand);
  console.log('Splendid CLI Tools: all commands registered');
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

/**
 * Formats Dartdoc comments in a Dart file to a specified line length.
 * 
 * @param uri - URI of the Dart file to format
 * @param lineLength - Maximum line length (80 or 120 characters)
 */
async function formatDartdocFile(uri: vscode.Uri, lineLength: number): Promise<void> {
  const config = vscode.workspace.getConfiguration('splendidCli');
  const cliPath = config.get<string>('executablePath', 'splendid_cli');
  const filePath = uri.fsPath;

  try {
    await vscode.window.withProgress(
      {
        location: vscode.ProgressLocation.Notification,
        title: `Formatting Dartdoc comments (${lineLength} chars)...`,
        cancellable: false,
      },
      async () => {
        await execFileAsync(cliPath, ['format-dartdoc', filePath, '-l', String(lineLength)]);
      }
    );

    const showNotifications = config.get<boolean>('showNotifications', true);
    if (showNotifications) {
      vscode.window.showInformationMessage(`Dartdoc comments formatted to ${lineLength} characters`);
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    vscode.window.showErrorMessage(`Failed to format Dartdoc comments: ${errorMessage}`);
  }
}

/**
 * Formats regular comments in a Dart file to a specified line length.
 * 
 * @param uri - URI of the Dart file to format
 * @param lineLength - Maximum line length (80 or 120 characters)
 */
async function formatCommentsFile(uri: vscode.Uri, lineLength: number): Promise<void> {
  const config = vscode.workspace.getConfiguration('splendidCli');
  const cliPath = config.get<string>('executablePath', 'splendid_cli');
  const filePath = uri.fsPath;

  try {
    await vscode.window.withProgress(
      {
        location: vscode.ProgressLocation.Notification,
        title: `Formatting regular comments (${lineLength} chars)...`,
        cancellable: false,
      },
      async () => {
        await execFileAsync(cliPath, ['format-comments', filePath, '-l', String(lineLength)]);
      }
    );

    const showNotifications = config.get<boolean>('showNotifications', true);
    if (showNotifications) {
      vscode.window.showInformationMessage(`Regular comments formatted to ${lineLength} characters`);
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    vscode.window.showErrorMessage(`Failed to format regular comments: ${errorMessage}`);
  }
}

/**
 * Creates a new screen with MVC architecture in the Flutter project.
 * 
 * Prompts the user for a screen name and generates the necessary files.
 */
async function createScreen(): Promise<void> {
  const screenName = await vscode.window.showInputBox({
    prompt: 'Enter the name for the new screen',
    placeHolder: 'e.g., game, UserProfile, settings',
    validateInput: (value: string) => {
      if (!value || value.trim().length === 0) {
        return 'Screen name cannot be empty';
      }
      if (!/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(value)) {
        return 'Screen name must be a valid Dart identifier (letters, numbers, underscores)';
      }
      return null;
    }
  });

  if (!screenName) {
    return; // User cancelled
  }

  const config = vscode.workspace.getConfiguration('splendidCli');
  const cliPath = config.get<string>('executablePath', 'splendid_cli');
  const workspaceFolder = vscode.workspace.workspaceFolders?.[0];

  if (!workspaceFolder) {
    vscode.window.showErrorMessage('No workspace folder open. Please open a Flutter project.');
    return;
  }

  try {
    await vscode.window.withProgress(
      {
        location: vscode.ProgressLocation.Notification,
        title: `Creating screen: ${screenName}...`,
        cancellable: false,
      },
      async () => {
        await execFileAsync(cliPath, ['screen', screenName], {
          cwd: workspaceFolder.uri.fsPath
        });
      }
    );

    const showNotifications = config.get<boolean>('showNotifications', true);
    if (showNotifications) {
      vscode.window.showInformationMessage(`Screen "${screenName}" created successfully`);
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    vscode.window.showErrorMessage(`Failed to create screen: ${errorMessage}`);
  }
}

export function deactivate(): void {}
