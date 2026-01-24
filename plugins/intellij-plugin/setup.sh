#!/bin/bash

# Setup script for Splendid CLI IntelliJ Plugin development
# This script helps developers get started quickly

set -e  # Exit on error

echo ""
echo "Splendid CLI IntelliJ Plugin Setup"
echo "======================================"
echo ""

# Check Java version
echo "Checking prerequisites..."
if ! command -v java &> /dev/null; then
    echo "Java not found. Please install JDK 17 or later."
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
if [ "$JAVA_VERSION" -lt 17 ]; then
    echo "Java 17 or later is required. Found version: $JAVA_VERSION"
    exit 1
fi
echo "Java $JAVA_VERSION found"

# Check if Splendid CLI is installed
echo ""
echo "Checking Splendid CLI installation..."
if ! command -v splendid_cli &> /dev/null; then
    echo "   Splendid CLI not found in PATH"
    echo "   Install with: dart pub global activate splendid_cli"
    echo "   Then add to PATH: export PATH=\"\$PATH\":\"\$HOME/.pub-cache/bin\""
else
    echo "Splendid CLI found"
fi

# Make gradlew executable
echo ""
echo "Setting up Gradle wrapper..."
if [ -f "gradlew" ]; then
    chmod +x gradlew
    echo "Gradle wrapper is executable"
else
    echo "Gradle wrapper not found. Generating..."
    if command -v gradle &> /dev/null; then
        gradle wrapper
        chmod +x gradlew
        echo "Gradle wrapper generated successfully"
    else
        echo "   Gradle not found in PATH"
        echo "   Please install Gradle or open the project in IntelliJ IDEA"
        echo "   IntelliJ will automatically set up Gradle for you"
    fi
fi

# Build the plugin
echo ""
echo "Building plugin..."
if [ -f "gradlew" ]; then
    ./gradlew build
else
    echo "   Skipping build - Gradle wrapper not available"
    echo "   Open the project in IntelliJ IDEA to complete setup"
    echo "   Or install Gradle and run: gradle wrapper && ./gradlew build"
fi

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Open this directory in IntelliJ IDEA"
echo "  2. Wait for Gradle sync to complete"
echo "  3. Run the plugin using one of these methods:"
echo "     - IntelliJ Gradle tool window: Tasks → intellij → runIde"
echo "     - Command line: ./gradlew runIde (or gradle runIde)"
echo "  4. Read DEVELOPMENT.md for detailed instructions"
echo ""
echo "Quick commands:"
echo "  ./gradlew runIde        # Run plugin in test IDE"
echo "  ./gradlew buildPlugin   # Build distributable ZIP"
echo "  ./gradlew test          # Run tests"
echo ""
echo "Note: If gradlew is not available, use 'gradle' instead"
echo ""
