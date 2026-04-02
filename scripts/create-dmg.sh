#!/bin/bash
# DMG 打包脚本 - 将 Vibe Island 应用打包为 DMG 安装包
set -e

# 配置
APP_NAME="Vibe Island"
VERSION="1.0.0"
DMG_NAME="VibeIsland-${VERSION}.dmg"

# 路径配置 - 支持 SPM 和 Xcode 构建
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SPM_BUILD_DIR="$PROJECT_ROOT/.build/release"
XCODE_BUILD_DIR="$PROJECT_ROOT/build/Build/Products/Release"

# 检测构建产物位置
if [ -d "$SPM_BUILD_DIR/$APP_NAME.app" ]; then
  BUILD_DIR="$SPM_BUILD_DIR"
  echo "检测到 SPM 构建产物"
elif [ -d "$XCODE_BUILD_DIR/$APP_NAME.app" ]; then
  BUILD_DIR="$XCODE_BUILD_DIR"
  echo "检测到 Xcode 构建产物"
else
  echo "错误: 找不到构建产物"
  echo "请先运行以下命令之一:"
  echo "  - SPM 构建: ./scripts/build-app.sh"
  echo "  - Xcode 构建: xcodebuild -configuration Release"
  exit 1
fi

DMG_DIR="dmg-staging"

echo "=== 创建 Vibe Island DMG 安装包 ==="
echo "构建目录: $BUILD_DIR"
echo ""

# 清理旧文件
echo "清理旧文件..."
rm -rf "$DMG_DIR"
rm -f "$DMG_NAME"

# 创建临时目录
echo "创建临时目录..."
mkdir -p "$DMG_DIR"

# 复制应用到临时目录
echo "复制应用..."
cp -R "$BUILD_DIR/$APP_NAME.app" "$DMG_DIR/"

# 创建 Applications 文件夹符号链接
echo "创建 Applications 符号链接..."
ln -s /Applications "$DMG_DIR/Applications"

# 添加 README
echo "创建 README..."
cat > "$DMG_DIR/README.txt" << 'EOF'
Vibe Island - macOS 菜单栏状态监控应用

安装说明：
1. 将 "Vibe Island.app" 拖拽到 "Applications" 文件夹
2. 打开 "应用程序" 文件夹，找到 "Vibe Island"
3. 右键点击，选择 "打开"（首次运行需要）
4. 应用将在菜单栏显示图标

系统要求：
- macOS 14.0 或更高版本

版本：1.0.0
EOF

# 创建 DMG
echo "创建 DMG..."
hdiutil create -volname "$APP_NAME" \
  -srcfolder "$DMG_DIR" \
  -ov -format UDZO \
  "$DMG_NAME"

# 清理临时目录
echo "清理临时目录..."
rm -rf "$DMG_DIR"

echo ""
echo "=== DMG 创建成功 ==="
echo "文件: $DMG_NAME"
echo "大小: $(du -h "$DMG_NAME" | cut -f1)"
