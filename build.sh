#!/usr/bin/env bash
set -e

APP_NAME="GhostWriter"
BUILD_DIR="./build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "==> Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS" "$RESOURCES"

echo "==> Compiling Swift sources..."
swiftc Sources/*.swift Sources/**/*.swift \
    -o "$MACOS/$APP_NAME" \
    -target arm64-apple-macos14.0 \
    -F Vendor \
    -framework Sparkle \
    -Xlinker -rpath -Xlinker "@executable_path/../Frameworks" \
    -O

echo "==> Copying Info.plist and resources..."
cp Resources/Info.plist "$CONTENTS/Info.plist"

echo "==> Copying Sparkle framework..."
mkdir -p "$CONTENTS/Frameworks"
cp -R Vendor/Sparkle.framework "$CONTENTS/Frameworks/"

if [ -d Resources/Shortcuts ]; then
    cp -R Resources/Shortcuts "$RESOURCES/Shortcuts"
fi

if [ -f /opt/homebrew/bin/llama-cli ]; then
    cp /opt/homebrew/bin/llama-cli "$RESOURCES/llama-cli"
    chmod +x "$RESOURCES/llama-cli"
    
    # Use dylibbundler to pull in all Homebrew dependencies (libggml, libssl, etc.)
    # and rewrite the load commands so the app is fully portable.
    echo "    Bundling dynamic libraries for llama-cli..."
    mkdir -p "$CONTENTS/Frameworks"
    dylibbundler -b -x "$RESOURCES/llama-cli" -d "$CONTENTS/Frameworks" -p "@executable_path/../Frameworks" -s /opt/homebrew/lib > /dev/null
    
    # Re-sign all bundled frameworks
    for dylib in "$CONTENTS/Frameworks"/*.dylib; do
        codesign --force --sign - "$dylib"
    done
    
    # Re-sign the executable (dylibbundler's codesign breaks on Apple Silicon due to preserve-metadata flags)
    codesign --force --sign - "$RESOURCES/llama-cli"
    
    echo "    ✓ Bundled llama-cli with dynamic libraries"
else
    echo ""
    echo "    ⚠️  WARNING: /opt/homebrew/bin/llama-cli not found!"
    echo "    The local AI model backend will NOT work without it."
    echo "    To install it:"
    echo "      brew install llama.cpp"
    echo ""
fi

echo "==> Registering macOS Services..."
/System/Library/CoreServices/pbs -update

echo "==> Signing the app bundle..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "==> Installing to ~/Applications..."
mkdir -p ~/Applications
cp -R "$APP_BUNDLE" ~/Applications/

echo "==> Done! Launch with: open ~/Applications/$APP_NAME.app"
