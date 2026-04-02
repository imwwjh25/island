---
phase: 3
slug: dynamic-island-widget
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-02
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (Swift) |
| **Config file** | VibeIslandWidgetTests/ (在 Wave 0 创建) |
| **Quick run command** | `xcodebuild test -scheme VibeIslandWidget -destination 'platform=macOS' -only-testing:VibeIslandWidgetTests` |
| **Full suite command** | `xcodebuild test -scheme VibeIslandWidget -destination 'platform=macOS'` |
| **Estimated runtime** | ~30 秒 |

---

## Sampling Rate

- **After every task commit:** 运行单元测试（如果有的话）
- **After every plan wave:** 运行完整测试套件
- **Before `/gsd:verify-work`:** 完整测试套件必须全部通过
- **Max feedback latency:** 60 秒

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | DIUI-01 | manual | N/A | ✅ W0 | ⬜ pending |
| 03-01-02 | 01 | 1 | DIUI-02 | manual | N/A | ✅ W0 | ⬜ pending |
| 03-01-03 | 01 | 1 | DIUI-03 | manual | N/A | ✅ W0 | ⬜ pending |
| 03-01-04 | 01 | 1 | DIUI-04 | manual | N/A | ✅ W0 | ⬜ pending |
| 03-01-05 | 01 | 2 | CORE-01 | manual | N/A | ✅ W0 | ⬜ pending |
| 03-01-06 | 01 | 2 | CORE-02 | manual | N/A | ✅ W0 | ⬜ pending |
| 03-01-07 | 01 | 2 | STMG-03 | manual | N/A | ✅ W0 | ⬜ pending |
| 03-01-08 | 01 | 3 | ACCS-01 | manual | N/A | ✅ W0 | ⬜ pending |
| 03-01-09 | 01 | 3 | ACCS-02 | manual | N/A | ✅ W0 | ⬜ pending |
| 03-01-10 | 01 | 3 | ACCS-03 | manual | N/A | ✅ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `VibeIslandWidgetTests/` — 测试目标目录
- [ ] `VibeIslandWidgetTests/VibeIslandWidgetProviderTests.swift` — TimelineProvider 测试存根
- [ ] `VibeIslandWidgetTests/VibeIslandWidgetUITests.swift` — UI 测试存根
- [ ] `VibeIslandWidget.xcodeproj/project.pbxproj` — Widget Extension 目标配置

*注意: UI 测试需要手动验证，单元测试可以自动化运行。*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 紧凑视图显示代理数量和状态摘要 | DIUI-01 | Dynamic Island UI 需要在设备上手动验证 | 1. 运行应用并启动至少一个代理<br>2. 查看动态岛紧凑视图<br>3. 验证显示正确的代理数量和状态 |
| 点击展开到详细视图 | DIUI-02 | 用户交互需要手动测试 | 1. 点击动态岛紧凑视图<br>2. 验证展开视图正确显示<br>3. 验证过渡动画流畅 |
| 紧凑/展开视图过渡动画流畅 | DIUI-03 | 动画质量需要视觉验证 | 1. 多次点击紧凑/展开视图<br>2. 观察动画是否流畅<br>3. 验证无卡顿或闪烁 |
| 点击背景折叠展开视图 | DIUI-04 | 用户交互需要手动测试 | 1. 展开动态岛<br>2. 点击背景区域<br>3. 验证视图正确折叠 |
| 代理需要审批时自动展开 | CORE-01 | 需要模拟状态变化并观察 UI | 1. 触发代理状态变为 awaiting_approval<br>2. 验证动态岛自动展开<br>3. 验证高优先级状态指示 |
| 代理完成时自动展开 | CORE-02 | 需要模拟状态变化并观察 UI | 1. 触发代理状态变为 complete<br>2. 验证动态岛自动展开<br>3. 验证完成状态指示 |
| 多个代理在一个动态岛视图中显示 | STMG-03 | 需要多个活跃代理来验证 | 1. 启动 3 个或更多代理<br>2. 验证所有代理在展开视图中显示<br>3. 验证紧凑视图显示正确数量 |
| VoiceOver 正确朗读动态岛内容 | ACCS-01 | 辅助功能需要在设备上测试 | 1. 启用 VoiceOver<br>2. 聚焦到动态岛<br>3. 验证朗读内容准确描述代理状态 |
| 系统外观切换不影响显示 | ACCS-02 | 需要测试深色/浅色模式 | 1. 切换系统到深色模式<br>2. 验证动态岛正确显示<br>3. 切换到浅色模式<br>4. 验证动态岛正确显示 |
| 减少动画设置得到尊重 | ACCS-03 | 辅助功能设置验证 | 1. 启用减少动画设置<br>2. 触发动态岛状态变化<br>3. 验证过渡动画被禁用或简化 |

*注: 由于 Dynamic Island 是 macOS 系统级的 UI 组件，大部分验证需要手动在运行中的 macOS 设备上进行。*

---

## Validation Sign-Off

- [ ] 所有任务都有明确的验收标准
- [ ] 手动验证步骤清晰可执行
- [ ] Wave 0 测试基础设施覆盖所有需求
- [ ] 反馈延迟 < 60s
- [ ] `nyquist_compliant: true` 设置在前言中

**Approval:** pending

---

*Validation strategy created: 2026-04-02*