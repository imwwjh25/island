---
phase: 05-polish-deployment
plan: 02
type: execute
wave: 2
depends_on: ["05-polish-deployment-01"]
files_modified:
  - scripts/create-dmg.sh
  - scripts/install-test.sh
autonomous: false
requirements: []

must_haves:
  truths:
    - "DMG 安装包文件存在并可以挂载"
    - "用户可以从 DMG 拖拽应用到 Applications 文件夹"
    - "安装后的应用可以启动"
    - "应用的基本功能正常工作（菜单栏显示、状态管理）"
  artifacts:
    - path: "scripts/create-dmg.sh"
      provides: "DMG 创建脚本"
      min_lines: 20
    - path: "VibeIsland.dmg"
      provides: "DMG 安装包"
      contains: "Vibe Island.app"
    - path: "scripts/install-test.sh"
      provides: "安装测试脚本"
      min_lines: 10
  key_links:
    - from: "scripts/create-dmg.sh"
      to: "build/Release/Vibe Island.app"
      via: "打包构建产物"
      pattern: "hdiutil.*create"
    - from: "VibeIsland.dmg"
      to: "/Applications/Vibe Island.app"
      via: "用户拖拽安装"
      pattern: "cp.*Applications"
---

<objective>
创建 DMG 安装包并验证安装和基本功能

Purpose: 为 MVP 功能验证提供可安装的应用包，确保用户可以安装和测试应用
Output: DMG 安装包文件和安装验证脚本
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/05-polish-deployment/05-polish-deployment-01-SUMMARY.md
</context>

<interfaces>
<!-- 依赖 Plan 01 的输出 -->

构建产物:
- build/Release/Vibe Island.app（从 Plan 01 构建生成）

项目信息:
- 应用名称: Vibe Island
- Bundle ID: com.vibeisland.app
- 版本: 1.0.0
- 部署目标: macOS 14.0+

DMG 要求:
- 包含应用 bundle
- 包含 Applications 文件夹快捷方式（方便拖拽安装）
- 可选：包含 README 或安装说明
- 文件名: VibeIsland-1.0.0.dmg
</interfaces>

<tasks>

<task type="auto">
  <name>Task 1: 创建 Release 构建</name>
  <files>（无文件修改，生成构建产物）</files>
  <read_first>
    - VibeIsland.xcodeproj/project.pbxproj（项目配置）
    - VibeIsland/Info.plist（版本信息）
  </read_first>
  <action>
使用 xcodebuild 创建 Release 配置的构建：

```bash
cd /Users/Zhuanz/island

# 清理之前的构建
xcodebuild -project VibeIsland.xcodeproj \
  -scheme VibeIsland \
  -configuration Release \
  clean

# 构建 Release 版本
xcodebuild -project VibeIsland.xcodeproj \
  -scheme VibeIsland \
  -configuration Release \
  -sdk macosx \
  -derivedDataPath build \
  build

# 验证构建产物
ls -la build/Build/Products/Release/
```

构建产物应该位于: `build/Build/Products/Release/Vibe Island.app`

检查构建产物：
1. .app bundle 存在
2. 包含可执行文件
3. 包含 Info.plist
4. 包含资源文件（sounds 目录）

如果构建失败，记录错误信息并标记为需要修复。
  </action>
  <verify>
    <automated>test -d "build/Build/Products/Release/Vibe Island.app" && test -f "build/Build/Products/Release/Vibe Island.app/Contents/MacOS/Vibe Island"</automated>
  </verify>
  <acceptance_criteria>
- Release 构建成功完成
- .app bundle 存在于 build/Build/Products/Release/
- 应用 bundle 包含可执行文件和资源
- 或：如果环境不支持，记录详细的失败原因
  </acceptance_criteria>
  <done>Release 构建完成，生成可分发的应用 bundle</done>
</task>

<task type="auto">
  <name>Task 2: 创建 DMG 打包脚本</name>
  <files>scripts/create-dmg.sh</files>
  <read_first>
    - VibeIsland/Info.plist（获取版本号）
  </read_first>
  <action>
创建 DMG 打包脚本 scripts/create-dmg.sh，使用 hdiutil 命令：

```bash
#!/bin/bash
set -e

# 配置
APP_NAME="Vibe Island"
VERSION="1.0.0"
DMG_NAME="VibeIsland-${VERSION}.dmg"
BUILD_DIR="build/Build/Products/Release"
DMG_DIR="dmg-staging"

# 清理旧文件
rm -rf "$DMG_DIR"
rm -f "$DMG_NAME"

# 创建临时目录
mkdir -p "$DMG_DIR"

# 复制应用到临时目录
cp -R "$BUILD_DIR/$APP_NAME.app" "$DMG_DIR/"

# 创建 Applications 文件夹符号链接
ln -s /Applications "$DMG_DIR/Applications"

# 可选：添加 README
cat > "$DMG_DIR/README.txt" << 'EOF'
Vibe Island - macOS 动态岛状态监控应用

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
hdiutil create -volname "$APP_NAME" \
  -srcfolder "$DMG_DIR" \
  -ov -format UDZO \
  "$DMG_NAME"

# 清理临时目录
rm -rf "$DMG_DIR"

echo "DMG 创建成功: $DMG_NAME"
```

使脚本可执行：
```bash
chmod +x scripts/create-dmg.sh
```

关键功能：
- 从 Release 构建目录复制应用
- 创建 Applications 文件夹符号链接
- 添加 README 安装说明
- 使用 hdiutil 创建压缩的 DMG
- 清理临时文件
  </action>
  <verify>
    <automated>test -f scripts/create-dmg.sh && test -x scripts/create-dmg.sh && grep -q "hdiutil create" scripts/create-dmg.sh</automated>
  </verify>
  <acceptance_criteria>
- scripts/create-dmg.sh 文件存在
- 脚本具有可执行权限
- 脚本包含 hdiutil create 命令
- 脚本包含 Applications 符号链接创建
  </acceptance_criteria>
  <done>DMG 打包脚本创建完成，可以将应用打包为安装包</done>
</task>

<task type="auto">
  <name>Task 3: 执行 DMG 打包</name>
  <files>（无文件修改，生成 DMG 文件）</files>
  <read_first>
    - scripts/create-dmg.sh（打包脚本）
  </read_first>
  <action>
执行 DMG 打包脚本：

```bash
cd /Users/Zhuanz/island

# 创建 scripts 目录（如果不存在）
mkdir -p scripts

# 执行打包脚本
./scripts/create-dmg.sh
```

验证 DMG 文件：
```bash
# 检查 DMG 文件存在
ls -lh VibeIsland-1.0.0.dmg

# 验证 DMG 可以挂载
hdiutil attach VibeIsland-1.0.0.dmg -readonly -mountpoint /tmp/vibeisland-test

# 检查内容
ls -la /tmp/vibeisland-test/

# 卸载
hdiutil detach /tmp/vibeisland-test
```

检查点：
1. DMG 文件大小合理（应该在 1-10 MB 范围）
2. DMG 可以成功挂载
3. 包含 "Vibe Island.app"
4. 包含 "Applications" 符号链接
5. 包含 README.txt

如果打包失败，检查：
- Release 构建是否成功
- hdiutil 命令是否可用
- 文件路径是否正确
  </action>
  <verify>
    <automated>test -f VibeIsland-1.0.0.dmg && hdiutil imageinfo VibeIsland-1.0.0.dmg | grep -q "Format: UDZO"</automated>
  </verify>
  <acceptance_criteria>
- VibeIsland-1.0.0.dmg 文件存在
- DMG 文件可以成功挂载
- DMG 包含应用 bundle 和 Applications 链接
- DMG 格式为 UDZO（压缩格式）
  </acceptance_criteria>
  <done>DMG 安装包创建完成，可以分发给用户安装</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>
DMG 安装包和应用功能验证

Claude 已完成：
1. 创建 Xcode 项目并配置构建设置
2. 构建 Release 版本应用
3. 创建 DMG 安装包（VibeIsland-1.0.0.dmg）
  </what-built>
  <how-to-verify>
请执行以下验证步骤：

**1. DMG 安装验证**:
```bash
# 挂载 DMG
open VibeIsland-1.0.0.dmg

# 拖拽 "Vibe Island.app" 到 "Applications" 文件夹
# （使用 Finder 手动操作）

# 或使用命令行：
cp -R "/Volumes/Vibe Island/Vibe Island.app" /Applications/
```

**2. 应用启动验证**:
```bash
# 打开应用
open "/Applications/Vibe Island.app"

# 检查菜单栏是否显示 Vibe Island 图标
```

**3. 基本功能验证**:
- [ ] 应用在菜单栏显示图标
- [ ] 点击菜单栏图标可以展开详细视图
- [ ] 详细视图显示代理状态（如果有 Claude Code 运行）
- [ ] 应用没有崩溃或明显错误

**4. 终端跳转功能验证**（Phase 4 功能）:
如果有 Claude Code 代理运行：
- [ ] 点击代理卡片可以跳转到对应的终端标签页
- [ ] 支持 iTerm2 或 Terminal.app

**5. 音效验证**（Phase 2 功能）:
如果有代理状态变化：
- [ ] 状态变化时播放音效
- [ ] 音效尊重系统静音设置

**预期结果**:
- 应用成功安装到 /Applications
- 应用可以启动并在菜单栏显示
- 基本 UI 功能正常
- 没有明显的崩溃或错误

**如果遇到问题**:
- 记录错误信息（崩溃日志、控制台输出）
- 截图显示问题
- 描述重现步骤
  </how-to-verify>
  <resume-signal>
请回复以下之一：
- "approved" - 所有功能正常，验证通过
- "issues: [描述问题]" - 发现问题，需要修复
- "blocked: [原因]" - 无法验证，说明原因
  </resume-signal>
</task>

<task type="auto">
  <name>Task 5: 创建安装测试脚本（可选）</name>
  <files>scripts/install-test.sh</files>
  <read_first>
    - scripts/create-dmg.sh（了解 DMG 结构）
  </read_first>
  <action>
创建自动化安装测试脚本 scripts/install-test.sh：

```bash
#!/bin/bash
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

# 挂载 DMG
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

# 卸载 DMG
hdiutil detach "$MOUNT_POINT"

echo "✓ DMG 可以正常挂载和卸载"

# 检查应用签名（可选）
echo "检查应用签名..."
codesign -dv "$MOUNT_POINT/$APP_NAME.app" 2>&1 || echo "注意: 应用未签名（开发版本正常）"

echo ""
echo "=== 测试完成 ==="
echo "DMG 文件: $DMG_FILE"
echo "下一步: 手动安装并测试应用功能"
```

使脚本可执行：
```bash
chmod +x scripts/install-test.sh
```

此脚本用于自动化验证 DMG 的基本完整性，但不替代人工功能测试。
  </action>
  <verify>
    <automated>test -f scripts/install-test.sh && test -x scripts/install-test.sh && grep -q "hdiutil attach" scripts/install-test.sh</automated>
  </verify>
  <acceptance_criteria>
- scripts/install-test.sh 文件存在
- 脚本具有可执行权限
- 脚本包含 DMG 挂载和验证逻辑
  </acceptance_criteria>
  <done>安装测试脚本创建完成，可以自动验证 DMG 完整性</done>
</task>

</tasks>

<verification>
## 整体验证

1. **DMG 文件验证**:
   ```bash
   test -f VibeIsland-1.0.0.dmg
   hdiutil imageinfo VibeIsland-1.0.0.dmg
   ```

2. **DMG 内容验证**:
   ```bash
   hdiutil attach VibeIsland-1.0.0.dmg -readonly -mountpoint /tmp/test
   ls -la /tmp/test/
   test -d "/tmp/test/Vibe Island.app"
   test -L "/tmp/test/Applications"
   hdiutil detach /tmp/test
   ```

3. **脚本验证**:
   ```bash
   test -x scripts/create-dmg.sh
   test -x scripts/install-test.sh
   ```

4. **人工验证**（Checkpoint）:
   - 安装应用到 /Applications
   - 启动应用
   - 测试基本功能
   - 测试终端跳转（Phase 4）
   - 测试音效（Phase 2）
</verification>

<success_criteria>
1. Release 构建成功完成
2. DMG 安装包文件创建成功
3. DMG 可以挂载并包含正确的内容
4. 打包脚本和测试脚本创建完成
5. 人工验证通过：应用可以安装和启动
6. 人工验证通过：基本功能正常工作
7. 人工验证通过：Phase 4 终端跳转功能正常（如果有 Claude Code 运行）
</success_criteria>

<output>
After completion, create `.planning/phases/05-polish-deployment/05-polish-deployment-02-SUMMARY.md`
</output>
