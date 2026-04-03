# Feature Landscape

**Domain:** macOS menu bar dynamic status indicator
**Researched:** 2026-04-03

---

## Table Stakes

菜单栏状态应用的基本功能，缺失则产品不完整。

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **状态指示圆点** | 用户需要一眼看出状态类型 | Low | 已实现，需动态化 |
| **代理数量徽章** | 多代理场景必需 | Low | 已实现，需集成到图标 |
| **状态变化提示** | 重要状态变化需要视觉反馈 | Medium | 已实现闪烁，需图标动画 |
| **点击展开详情** | 标准菜单栏交互模式 | Low | 已实现 |
| **跳转到终端** | 核心功能，快速定位代理 | Medium | 已实现，需优化标签页识别 |
| **音效提示** | "Vibe" 体验核心 | Low | 已实现 |

---

## Differentiators

增值功能，非必需但提升产品价值。

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **动态图标实时更新** | 无需展开即可知道状态 | Medium | 本 milestone 核心 |
| **闪烁/脉冲动画** | 吸引注意力，不打扰 | Medium | 需平衡动画频率 |
| **CPU/内存使用显示** | 了解代理资源占用 | Medium | 可选，proc_pid_rusage |
| **多终端支持** | WezTerm 等新终端 | Medium | 延后，MVP 仅 iTerm2/Terminal |
| **自定义音效** | 个性化体验 | Low | 可延后 |
| **状态历史记录** | 回顾代理状态变化 | High | 延后 v3+ |

---

## Anti-Features

明确不构建的功能。

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **自动展开 Popover** | MenuBarExtra API 不支持 | 使用视觉提示（闪烁）吸引注意力 |
| **复杂图标动画** | 菜单栏不适合动画 | 简单的脉冲/闪烁效果 |
| **通知中心集成** | 权限复杂，用户反感 | 菜单栏原生提示足够 |
| **云端同步状态** | MVP 仅本地监控 | Socket 本地通信 |
| **代理配置 UI** | MVP 硬编码 Claude Code | 配置延后 v2+ |
| **自定义图标样式** | 增加复杂度，非核心 | 使用系统模板图像风格 |

---

## Feature Dependencies

```
动态图标生成 → 菜单栏集成 → 闪烁动画
                    ↓
状态检测增强 → 更精确的状态识别
                    ↓
终端跳转优化 → 标签页识别改进
```

---

## MVP Recommendation

**本 milestone (v2.0 kpbl) 优先级：**

| 优先级 | Feature | 理由 |
|--------|---------|------|
| P0 | 动态图标生成 | 核心价值，无需展开即可知状态 |
| P0 | 状态圆点 + 数量徽章集成 | 最直观的状态显示 |
| P1 | 闪烁提示效果 | 重要状态变化的视觉反馈 |
| P1 | 状态检测增强 | 提升识别准确率 |
| P2 | 终端跳转优化 | 改进用户体验 |
| P2 | 音效扩展 | 体验优化，非阻塞 |

**Defer:**
- CPU/内存显示: 需要更多 API 研究，延后 v2.1
- WezTerm 支持: 延后 v2+
- 状态历史记录: 延后 v3+

---

## Feature-Stack Mapping

| Feature | Required Stack | 已有/新增 |
|---------|---------------|-----------|
| 动态图标 | NSImage 绘制 | 新增 |
| 状态圆点 | SwiftUI Circle | 已有 |
| 数量徽章 | NSImage 文本绘制 | 新增 |
| 闪烁动画 | SwiftUI animation | 已有 |
| 状态检测增强 | CGWindowList API | 新增 |
| 终端跳转优化 | AppleScript | 已有 |
| 音效 | AVAudioPlayer | 已有 |

---

## Sources

- 现有代码分析 (HIGH)
- PROJECT.md 目标定义 (HIGH)
- macOS 菜单栏应用最佳实践 (MEDIUM - 基于知识)