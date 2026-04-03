---
phase: 6
slug: infrastructure-fixes
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-03
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (XCTest compatible) |
| **Config file** | Package.swift |
| **Quick run command** | `swift test --filter FixTests` |
| **Full suite command** | `swift test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `swift test --filter FixTests`
- **After every plan wave:** Run `swift test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 1 | FIX-01 | unit | `swift test --filter StateManagerTests` | ✅ | ⬜ pending |
| 06-01-02 | 01 | 1 | FIX-01 | unit | `swift test --filter CompactStatusViewTests` | ✅ | ⬜ pending |
| 06-02-01 | 02 | 1 | FIX-03 | unit | `swift test --filter AccessibilityTests` | ✅ | ⬜ pending |
| 06-02-02 | 02 | 1 | FIX-03 | manual | N/A | N/A | ⬜ pending |
| 06-03-01 | 03 | 2 | FIX-02 | unit | `swift test --filter SoundManagerTests` | ✅ | ⬜ pending |
| 06-03-02 | 03 | 2 | FIX-02 | manual | N/A | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `VibeIslandTests/FixTests.swift` — 集成测试套件验证三个修复
- [ ] 现有 StateManagerTests.swift 需更新以测试 @StateObject 模式
- [ ] 现有 AccessibilityTests.swift 需更新以测试权限请求流程
- [ ] 现有 SoundManagerTests.swift 需更新以测试 AVAudioApplication 配置

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Accessibility 权限对话框显示 | FIX-03 | 系统权限 UI 由 macOS 控制，无法自动化 | 1. 首次启动应用 2. 观察是否弹出权限请求对话框 3. 点击"允许"验证 WindowMonitor 功能正常 |
| 音效播放可听 | FIX-02 | 音频输出需要物理设备，自动化无法验证听感 | 1. 触发状态变化 2. 确认听到音效 3. 验证系统静音时无音效 |
| 权限拒绝后 UI 提示显示 | FIX-03 | 需手动拒绝权限以测试拒绝流程 | 1. 在系统设置拒绝权限 2. 重启应用 3. 验证显示引导用户打开系统设置的 UI |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending