#!/bin/bash

# Script to run the Splendid CLI GUI Dashboard
# This script helps run the GUI independently for development and testing

echo "🚀 Starting Splendid CLI GUI Dashboard..."

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    echo "Please install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Please run this script from the gui_dashboard directory"
    exit 1
fi

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Check for desktop support
echo "🖥️  Checking desktop support..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    PLATFORM="windows"
else
    echo "❌ Unsupported platform: $OSTYPE"
    exit 1
fi

echo "🎯 Running on $PLATFORM..."

# Run the application
flutter run -d $PLATFORM