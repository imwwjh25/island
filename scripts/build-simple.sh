#!/bin/bash
set -e

echo "=== 使用 swiftc 直接编译 Vibe Island ==="

# 项目根目录
PROJECT_ROOT="/Users/Zhuanz/island"
cd "$PROJECT_ROOT"

# 输出目录
BUILD_DIR=".build/release"
APP_NAME="Vibe Island"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "清理旧构建..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "收集所有 Swift 源文件..."
SOURCES=$(find VibeIsland -name "*.swift" -type f | grep -v Tests | tr '\n' ' ')

echo "使用 swiftc 编译..."
swiftc $SOURCES \
  -o "$BUILD_DIR/VibeIsland" \
  -target x86_64-apple-macosx14.0 \
  -sdk $(xcrun --show-sdk-path) \
  -import-objc-header VibeIsland/BridgingHeader.h 2>/dev/null || \
swiftc $SOURCES \
  -o "$BUILD_DIR/VibeIsland" \
  -target x86_64-apple-macosx14.0 \
  -sdk $(xcrun --show-sdk-path)

if [ $? -ne 0 ]; then
  echo "❌ 编译失败"
  exit 1
fi

echo "✅ 编译成功"

echo "创建 .app bundle 结构..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 复制可执行文件
cp "$BUILD_DIR/VibeIsland" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# 创建 Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Vibe Island</string>
    <key>CFBundleIdentifier</key>
    <string>com.vibeisland.app</string>
    <key>CFBundleName</key>
    <string>Vibe Island</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Vibe Island</string>
</dict>
</plist>
EOF

# 复制资源文件
if [ -d "VibeIsland/Resources" ]; then
  cp -R VibeIsland/Resources/* "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true
fi

echo "✅ .app bundle 创建完成: $APP_BUNDLE"
echo ""
echo "测试运行:"
echo "  open \"$APP_BUNDLE\""
echo ""
echo "创建 DMG:"
echo "  ./scripts/create-dmg.sh"
