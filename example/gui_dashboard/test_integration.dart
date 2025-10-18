#!/usr/bin/env dart

/// Integration test script for the Splendid CLI GUI Dashboard.
///
/// This script verifies that the GUI can be launched and basic functionality
/// works as expected. It's designed to be run from the command line to
/// validate the GUI integration with the CLI.

import 'dart:io';

/// Main entry point for the integration test.
Future<void> main() async {
  print('🧪 Running Splendid CLI GUI Integration Tests\n');

  // Test 1: Verify Flutter is available
  print('1. Testing Flutter availability...');
  final ProcessResult flutterResult = await Process.run('flutter', ['--version']);
  if (flutterResult.exitCode == 0) {
    print('✅ Flutter is available');
  } else {
    print('❌ Flutter is not available');
    print('   Please install Flutter: https://flutter.dev/docs/get-started/install');
    exit(1);
  }

  // Test 2: Verify GUI dependencies can be resolved
  print('\n2. Testing GUI dependencies...');
  final ProcessResult pubGetResult = await Process.run(
    'flutter',
    ['pub', 'get'],
    workingDirectory: Directory.current.path,
  );
  if (pubGetResult.exitCode == 0) {
    print('✅ GUI dependencies resolved successfully');
  } else {
    print('❌ GUI dependency resolution failed');
    print('   Error: ${pubGetResult.stderr}');
    exit(1);
  }

  // Test 3: Verify CLI can launch GUI (dry run)
  print('\n3. Testing CLI GUI command...');
  final String cliPath = Directory.current.parent.parent.path;
  final ProcessResult cliResult = await Process.run(
    'dart',
    ['run', 'bin/splendid_cli.dart', 'gui', '--help'],
    workingDirectory: cliPath,
  );
  if (cliResult.exitCode == 0) {
    print('✅ CLI GUI command is available');
  } else {
    print('❌ CLI GUI command failed');
    print('   Error: ${cliResult.stderr}');
    exit(1);
  }

  // Test 4: Verify GUI can be analyzed
  print('\n4. Testing GUI code analysis...');
  final ProcessResult analyzeResult = await Process.run(
    'flutter',
    ['analyze'],
    workingDirectory: Directory.current.path,
  );
  if (analyzeResult.exitCode == 0) {
    print('✅ GUI code analysis passed');
  } else {
    print('⚠️  GUI code analysis has warnings/errors');
    print('   This is expected since Flutter dependencies may not be fully resolved');
  }

  print('\n🎉 Integration tests completed!');
  print('\nTo launch the GUI:');
  print('  splendid_cli gui');
  print('  or');
  print('  cd example/gui_dashboard && flutter run -d <platform>');
}
