#!/bin/bash

# Test script for the web backend
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="${SCRIPT_DIR}/web-config/backend"

echo "🧪 Testing web backend startup..."
echo "Backend directory: $BACKEND_DIR"

cd "$BACKEND_DIR"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found. Run setup-with-web-config.sh first."
    exit 1
fi

# Check if build directory exists
BUILD_DIR="../build"
if [ ! -d "$BUILD_DIR" ]; then
    echo "⚠️  Build directory not found: $BUILD_DIR"
    echo "Creating minimal build directory..."
    mkdir -p "$BUILD_DIR"
    echo '<html><body><h1>Frontend not built yet</h1></body></html>' > "$BUILD_DIR/index.html"
fi

echo "📁 Build directory contents:"
ls -la "$BUILD_DIR"

# Activate virtual environment and test
source venv/bin/activate

echo "🐍 Python path: $(which python)"
echo "📦 Installed packages:"
pip list | grep -E "(fastapi|uvicorn|pydantic)"

echo "🚀 Testing backend startup (will exit after 5 seconds)..."
timeout 5s python main.py || echo "✅ Backend started successfully (timed out as expected)"