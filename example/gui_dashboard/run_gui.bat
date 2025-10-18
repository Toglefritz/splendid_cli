@echo off
REM Script to run the Splendid CLI GUI Dashboard on Windows
REM This script helps run the GUI independently for development and testing

echo 🚀 Starting Splendid CLI GUI Dashboard...

REM Check if Flutter is available
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed or not in PATH
    echo Please install Flutter: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

REM Check if we're in the right directory
if not exist "pubspec.yaml" (
    echo ❌ Please run this script from the gui_dashboard directory
    pause
    exit /b 1
)

REM Get dependencies
echo 📦 Getting dependencies...
flutter pub get

REM Run the application
echo 🎯 Running on Windows...
flutter run -d windows

pause