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
   - VibeIsland/MenuBar/VibeIslandMenuBar.swift（包含 @main 入口点）
   - VibeIsland/MenuBar/CompactStatusView.swift
   - VibeIsland/MenuBar/ExpandedDetailsView.swift
   - VibeIsland/Models/AgentState.swift
   - VibeIsland/State/StateManager.swift
   - VibeIsland/SharedContainer/SharedContainer.swift
   - VibeIsland/Networking/SocketMonitor.swift
   - VibeIsland/Sound/SoundManager.swift
   - VibeIsland/Terminal/TerminalController.swift

3. 添加测试文件到测试目标：
   - VibeIslandTests/*.swift（所有测试文件）

4. 添加资源文件：
   - VibeIsland/Resources/sounds/（音效资源目录）

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
   - 使用项目中已有的 VibeIsland/Info.plist
   - 已包含 LSUIElement = YES（隐藏 Dock 图标）

7. Entitlements:
   - 使用项目中已有的 VibeIsland.entitlements
   - 已包含 App Groups 和网络权限配置

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

## 项目结构说明

项目使用 MenuBarExtra 作为主界面，不需要传统的窗口应用：

- **入口点**: VibeIslandMenuBar.swift 包含 @main 标记
- **菜单栏图标**: CompactStatusView 显示紧凑状态
- **展开视图**: ExpandedDetailsView 显示详细信息
- **状态管理**: StateManager 管理所有代理状态
- **套接字通信**: SocketMonitor 监控 Claude Code 套接字
- **终端控制**: TerminalController 处理终端标签跳转
- **音效**: SoundManager 播放状态变化音效

## 下一步

构建成功后，继续执行 Phase 5 Plan 02 创建 DMG 安装包。

