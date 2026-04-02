#!/bin/bash
# 安装测试脚本 - 自动验证 DMG 完整性
set -e

DMG_FILE="VibeIsland-1.0.0.dmg"
APP_NAME="Vibe Island"
MOUNT_POINT="/tmp/vibeisland-install-test"

echo "=== Vibe Island 安装测试 ==="

# 检查 DMG 文件
if [ ! -f "$DMG_FILE" ]; then
  echo "错误: DMG 文件不存在: $DMG_FILE"
  exit 1
fi

echo "✓ DMG 文件存在"
echo "  大小: $(du -h "$DMG_FILE" | cut -f1)"

# 挂载 DMG
echo ""
echo "挂载 DMG..."
hdiutil attach "$DMG_FILE" -readonly -mountpoint "$MOUNT_POINT"

# 检查应用存在
if [ ! -d "$MOUNT_POINT/$APP_NAME.app" ]; then
  echo "错误: 应用不存在于 DMG 中"
  hdiutil detach "$MOUNT_POINT"
  exit 1
fi

echo "✓ 应用存在于 DMG 中"

# 检查 Applications 链接
if [ ! -L "$MOUNT_POINT/Applications" ]; then
  echo "警告: Applications 符号链接不存在"
else
  echo "✓ Applications 符号链接存在"
fi

# 检查 README
if [ -f "$MOUNT_POINT/README.txt" ]; then
  echo "✓ README.txt 存在"
else
  echo "警告: README.txt 不存在"
fi

# 卸载 DMG
echo ""
echo "卸载 DMG..."
hdiutil detach "$MOUNT_POINT"

echo "✓ DMG 可以正常挂载和卸载"

echo ""
echo "=== 测试完成 ==="
echo "DMG 文件: $DMG_FILE"
echo ""
echo "下一步: 手动安装并测试应用功能"
echo "  1. 双击 DMG 文件挂载"
echo "  2. 拖拽应用到 Applications 文件夹"
echo "  3. 打开应用并测试功能"
