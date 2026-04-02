#!/bin/bash
# SPM 构建脚本 - 使用 Swift Package Manager 构建 Vibe Island 应用
set -e

# 配置
APP_NAME="Vibe Island"
BUNDLE_ID="com.vibeisland.app"
VERSION="1.0.0"
BUILD_NUMBER="1"
MIN_MACOS_VERSION="14.0"

# 路径配置
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/.build"
RELEASE_DIR="$BUILD_DIR/release"
APP_BUNDLE="$RELEASE_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "=== 使用 SPM 构建 Vibe Island ==="
echo "项目根目录: $PROJECT_ROOT"
echo ""

# 清理旧构建
echo "清理旧构建..."
rm -rf "$RELEASE_DIR"

# 使用 SPM 构建 Release 版本
echo "使用 swift build 构建..."
cd "$PROJECT_ROOT"
swift build -c release --arch arm64 --arch x86_64

# 检查构建产物
EXECUTABLE_PATH="$BUILD_DIR/apple/Products/Release/VibeIsland"
if [ ! -f "$EXECUTABLE_PATH" ]; then
  echo "错误: 找不到构建产物: $EXECUTABLE_PATH"
  exit 1
fi

echo "构建成功: $EXECUTABLE_PATH"
echo ""

# 创建 .app bundle 结构
echo "创建 .app bundle 结构..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 复制可执行文件
echo "复制可执行文件..."
cp "$EXECUTABLE_PATH" "$MACOS_DIR/VibeIsland"
chmod +x "$MACOS_DIR/VibeIsland"

# 创建 Info.plist
echo "创建 Info.plist..."
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>VibeIsland</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>LSMinimumSystemVersion</key>
    <string>$MIN_MACOS_VERSION</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>MacOSX</string>
    </array>
</dict>
</plist>
EOF

# 复制 entitlements
echo "复制 entitlements..."
cp "$PROJECT_ROOT/VibeIsland.entitlements" "$CONTENTS_DIR/VibeIsland.entitlements"

# 复制资源文件
echo "复制资源文件..."
if [ -d "$PROJECT_ROOT/VibeIsland/Resources" ]; then
  cp -R "$PROJECT_ROOT/VibeIsland/Resources/"* "$RESOURCES_DIR/"
  echo "已复制资源文件到: $RESOURCES_DIR"
fi

# 设置正确的权限
echo "设置权限..."
chmod -R 755 "$APP_BUNDLE"
chmod +x "$MACOS_DIR/VibeIsland"

# 验证 bundle 结构
echo ""
echo "=== 验证 .app bundle 结构 ==="
echo "Bundle 路径: $APP_BUNDLE"
echo ""
echo "目录结构:"
tree -L 3 "$APP_BUNDLE" 2>/dev/null || find "$APP_BUNDLE" -maxdepth 3 -print | sed 's|[^/]*/| |g'

echo ""
echo "=== 构建完成 ==="
echo "应用路径: $APP_BUNDLE"
echo "可执行文件: $MACOS_DIR/VibeIsland"
echo ""
echo "测试运行:"
echo "  open \"$APP_BUNDLE\""
echo ""
echo "创建 DMG:"
echo "  ./scripts/create-dmg.sh"

