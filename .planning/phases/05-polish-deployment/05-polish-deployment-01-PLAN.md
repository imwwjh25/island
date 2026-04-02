---
phase: 05-polish-deployment
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - VibeIsland.xcodeproj/project.pbxproj
  - VibeIsland/VibeIslandApp.swift
  - VibeIsland/Info.plist
  - VibeIsland.entitlements
autonomous: true
requirements: []

must_haves:
  truths:
    - "Xcode 项目文件存在并可以在 Xcode 中打开"
    - "项目包含所有源文件和资源"
    - "项目可以成功构建，无编译错误"
    - "应用部署目标设置为 macOS 14.0+"
  artifacts:
    - path: "VibeIsland.xcodeproj/project.pbxproj"
      provides: "Xcode 项目配置"
      min_lines: 100
    - path: "VibeIsland/VibeIslandApp.swift"
      provides: "应用入口点"
      exports: ["VibeIslandApp"]
    - path: "VibeIsland/Info.plist"
      provides: "应用元数据"
      contains: "CFBundleIdentifier"
    - path: "VibeIsland.entitlements"
      provides: "应用权限配置"
      contains: "com.apple.security.app-sandbox"
  key_links:
    - from: "VibeIsland.xcodeproj"
      to: "VibeIsland/*.swift"
      via: "项目文件引用"
      pattern: "fileRef.*\\.swift"
---

<objective>
创建 Xcode 项目并配置构建设置，使应用可以成功编译和运行

Purpose: 建立完整的 Xcode 项目结构，将现有的 Swift 源文件组织到可构建的应用中
Output: 可构建的 Xcode 项目，包含所有源文件、资源和正确的构建配置
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/REQUIREMENTS.md
</context>

<interfaces>
<!-- 现有项目文件结构 -->

源文件（9 个）:
- VibeIsland/MenuBar/ExpandedDetailsView.swift
- VibeIsland/MenuBar/VibeIslandMenuBar.swift
- VibeIsland/MenuBar/CompactStatusView.swift
- VibeIsland/Networking/SocketMonitor.swift
- VibeIsland/Terminal/TerminalController.swift
- VibeIsland/Models/AgentState.swift
- VibeIsland/State/StateManager.swift
- VibeIsland/SharedContainer/SharedContainer.swift
- VibeIsland/Sound/SoundManager.swift

测试文件（12 个）:
- VibeIslandTests/*.swift（各种测试文件）

资源文件:
- VibeIsland/Resources/sounds/（音效资源目录）

技术栈要求（来自 CLAUDE.md）:
- Swift 5.9+
- SwiftUI + WidgetKit
- macOS 14.0+ 部署目标
- App Groups 支持（用于主应用和 Widget 扩展共享数据）
</interfaces>

<tasks>

<task type="auto">
  <name>Task 1: 创建应用入口点文件</name>
  <files>VibeIsland/VibeIslandApp.swift</files>
  <read_first>
    - VibeIsland/MenuBar/VibeIslandMenuBar.swift（了解 MenuBar 结构）
    - VibeIsland/State/StateManager.swift（了解状态管理器）
    - VibeIsland/Networking/SocketMonitor.swift（了解套接字监控器）
  </read_first>
  <action>
创建 SwiftUI App 入口点文件 VibeIslandApp.swift，包含：

1. 使用 @main 标记的 App 结构体
2. 初始化 StateManager 和 SocketMonitor
3. 使用 MenuBarExtra 作为主界面（不需要传统窗口）
4. 配置应用生命周期（启动时连接套接字，退出时清理资源）

关键实现：
- 导入 SwiftUI
- 定义 VibeIslandApp 结构体，遵循 App 协议
- 使用 @StateObject 管理 StateManager 实例
- 在 init() 中启动 SocketMonitor
- body 返回 MenuBarExtra 场景（不需要 WindowGroup）
- 实现 onAppear 和 onDisappear 生命周期处理

注意：MenuBarExtra 是 macOS 13+ 的 API，用于创建菜单栏应用
  </action>
  <verify>
    <automated>test -f VibeIsland/VibeIslandApp.swift && grep -q "@main" VibeIsland/VibeIslandApp.swift && grep -q "MenuBarExtra" VibeIsland/VibeIslandApp.swift</automated>
  </verify>
  <acceptance_criteria>
- 文件 VibeIsland/VibeIslandApp.swift 存在
- 包含 @main 标记的 App 结构体
- 包含 MenuBarExtra 场景定义
- 初始化 StateManager 和 SocketMonitor
  </acceptance_criteria>
  <done>应用入口点文件创建完成，定义了 SwiftUI App 结构和 MenuBarExtra 界面</done>
</task>

<task type="auto">
  <name>Task 2: 创建 Xcode 项目配置文件</name>
  <files>
    VibeIsland.xcodeproj/project.pbxproj
    VibeIsland/Info.plist
    VibeIsland.entitlements
  </files>
  <read_first>
    - VibeIsland/VibeIslandApp.swift（应用入口点）
    - CLAUDE.md（技术栈要求）
    - .planning/REQUIREMENTS.md（了解 App Groups 需求）
  </read_first>
  <action>
创建完整的 Xcode 项目配置。由于环境限制，使用 Swift Package Manager 创建项目：

**1. 创建 Package.swift**:
```bash
cd /Users/Zhuanz/island
swift package init --type executable --name VibeIsland
```

**2. 修改 Package.swift 配置**:
- platforms: [.macOS(.v14)]
- 添加所有源文件到 targets
- 不需要外部依赖（使用系统框架）

**3. 创建 Info.plist**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.vibeisland.app</string>
    <key>CFBundleName</key>
    <string>Vibe Island</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
```

**4. 创建 VibeIsland.entitlements**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.vibeisland.shared</string>
    </array>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
```

注意：实际的 Xcode 项目需要在有 Xcode 的环境中创建。此步骤创建基础配置文件。
  </action>
  <verify>
    <automated>test -f VibeIsland/Info.plist && test -f VibeIsland.entitlements && grep -q "com.vibeisland.app" VibeIsland/Info.plist</automated>
  </verify>
  <acceptance_criteria>
- Info.plist 文件存在并包含正确的 Bundle ID
- Entitlements 文件存在并包含 App Groups 配置
- 配置文件格式正确（有效的 XML/plist）
  </acceptance_criteria>
  <done>项目配置文件创建完成，包含应用元数据和权限设置</done>
</task>

<task type="auto">
  <name>Task 3: 创建构建说明文档</name>
  <files>BUILD.md</files>
  <read_first>
    - VibeIsland/Info.plist（版本信息）
    - VibeIsland.entitlements（权限要求）
  </read_first>
  <action>
创建 BUILD.md 文档，说明如何在 Xcode 中构建项目：

```markdown
# Vibe Island 构建指南

## 环境要求

- macOS 14.0 或更高版本
- Xcode 15.0 或更高版本
- Swift 5.9+

## 创建 Xcode 项目

由于项目源文件已存在，需要在 Xcode 中创建新项目：

1. 打开 Xcode
2. File -> New -> Project
3. 选择 macOS -> App
4. 配置项目：
   - Product Name: Vibe Island
   - Bundle Identifier: com.vibeisland.app
   - Interface: SwiftUI
   - Language: Swift
   - 取消勾选 "Use Core Data"
   - 取消勾选 "Include Tests"（我们已有测试文件）

5. 保存到项目根目录（/Users/Zhuanz/island）

## 添加源文件

1. 删除 Xcode 自动生成的 ContentView.swift
2. 将现有源文件添加到项目：
   - VibeIsland/VibeIslandApp.swift
   - VibeIsland/MenuBar/*.swift
   - VibeIsland/Models/*.swift
   - VibeIsland/State/*.swift
   - VibeIsland/SharedContainer/*.swift
   - VibeIsland/Networking/*.swift
   - VibeIsland/Sound/*.swift
   - VibeIsland/Terminal/*.swift

3. 添加测试文件到测试目标

4. 添加资源文件：
   - VibeIsland/Resources/sounds/

## 配置项目设置

1. 选择项目 -> Target: Vibe Island -> General
2. 设置 Deployment Target: macOS 14.0
3. 设置 Bundle Identifier: com.vibeisland.app

4. Signing & Capabilities:
   - 添加 App Groups capability
   - App Group: group.com.vibeisland.shared
   - 添加 Network capability（如果需要）

5. Build Settings:
   - Swift Language Version: Swift 5
   - Code Signing Identity: Development

6. Info.plist:
   - 添加 LSUIElement = YES（隐藏 Dock 图标）

## 构建项目

```bash
# 命令行构建
xcodebuild -project VibeIsland.xcodeproj \
  -scheme VibeIsland \
  -configuration Release \
  build

# 或在 Xcode 中按 Cmd+B
```

## 运行项目

```bash
# 命令行运行
open build/Build/Products/Release/Vibe\ Island.app

# 或在 Xcode 中按 Cmd+R
```

## 故障排除

### 编译错误

- 检查所有源文件是否正确添加到 Target
- 检查 Swift 版本设置
- 检查部署目标设置

### 运行时错误

- 检查 App Groups 配置是否正确
- 检查 Entitlements 文件是否正确添加
- 检查资源文件是否正确复制到 Bundle

## 下一步

构建成功后，继续执行 Phase 5 Plan 02 创建 DMG 安装包。
```

此文档为用户提供完整的 Xcode 项目创建和构建指南。
  </action>
  <verify>
    <automated>test -f BUILD.md && grep -q "Xcode 15.0" BUILD.md && grep -q "macOS 14.0" BUILD.md</automated>
  </verify>
  <acceptance_criteria>
- BUILD.md 文件存在
- 包含完整的 Xcode 项目创建步骤
- 包含源文件添加说明
- 包含项目配置说明
- 包含构建和运行说明
  </acceptance_criteria>
  <done>构建说明文档创建完成，用户可以按照文档在 Xcode 中创建项目</done>
</task>

</tasks>

<verification>
## 整体验证

1. **文件存在性验证**:
   ```bash
   test -f VibeIsland/VibeIslandApp.swift
   test -f VibeIsland/Info.plist
   test -f VibeIsland.entitlements
   test -f BUILD.md
   ```

2. **配置正确性验证**:
   ```bash
   grep "com.vibeisland.app" VibeIsland/Info.plist
   grep "14.0" VibeIsland/Info.plist
   grep "group.com.vibeisland.shared" VibeIsland.entitlements
   ```

3. **应用入口点验证**:
   ```bash
   grep "@main" VibeIsland/VibeIslandApp.swift
   grep "MenuBarExtra" VibeIsland/VibeIslandApp.swift
   ```

4. **文档完整性验证**:
   ```bash
   grep "Xcode" BUILD.md
   grep "构建" BUILD.md
   ```
</verification>

<success_criteria>
1. 应用入口点文件（VibeIslandApp.swift）创建完成
2. Info.plist 配置文件创建完成，包含正确的 Bundle ID 和版本
3. Entitlements 配置文件创建完成，包含 App Groups 和网络权限
4. BUILD.md 文档创建完成，提供完整的 Xcode 项目创建指南
5. 所有配置文件格式正确，可以被 Xcode 识别
6. 用户可以按照 BUILD.md 在 Xcode 中创建和构建项目
</success_criteria>

<output>
After completion, create `.planning/phases/05-polish-deployment/05-polish-deployment-01-SUMMARY.md`
</output>
