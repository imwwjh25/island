# Vibe Island

基于 macOS 动态岛的状态感知应用

## 简介

Vibe Island 是一个 macOS 原生应用，利用 macOS 14+ 的动态岛（Dynamic Island）功能，通过 WidgetKit 实现实时状态显示和交互。

## 技术栈

- **Swift 5.9+** - Apple 平台官方语言
- **SwiftUI** - 声明式 UI 框架
- **WidgetKit** - 动态岛 Widget 支持
- **AppKit** - 系统集成和进程监控
- **AVFoundation** - 音效播放系统
- **Network framework** - 套接字通信

## 开发要求

- macOS 14.0+
- Xcode 15.0+

## 项目结构

```
VibeIsland/
├── VibeIsland/           # 主应用
├── VibeIslandTests/      # 测试代码
└── .planning/            # GSD 工作流规划文档
```

## 快速开始

```bash
# 克隆仓库
git clone https://github.com/imwwjh25/island.git

# 在 Xcode 中打开
open VibeIsland.xcodeproj
```

## 开发规范

- 代码注释使用中文
- 文档输出使用中文
- 遵循 GSD 工作流进行开发

## 许可证

[待添加]