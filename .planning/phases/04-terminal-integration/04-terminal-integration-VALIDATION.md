---
phase: 4
phase-slug: terminal-integration
created: 2026-04-02
---

# Validation Strategy: Phase 4 - Terminal Integration

## Overview

Phase 4 实现终端标签页跳转功能，允许用户点击代理卡片直接跳转到 iTerm2 或 Terminal.app 中对应的标签页。本阶段验证策略确保终端集成在各种场景下都能正常工作，并提供友好的错误反馈。

## Validation Architecture

### Wave 0: 测试基础设施

**目标：** 建立终端控制器的测试框架，包括单元测试和集成测试。

**测试文件结构：**
```
VibeIslandTests/Terminal/
├── TerminalControllerTests.swift       # TerminalController 单元测试
├── TerminalIntegrationTests.swift      # 终端集成测试
└── Mocks/
    ├── MockTerminalController.swift    # 模拟终端控制器
    └── MockAppleScriptExecutor.swift   # 模拟 AppleScript 执行器
```

**测试覆盖范围：**
- TerminalController 的所有公共方法
- 错误处理和边界情况
- AppleScript 执行的模拟

### Wave 1: TerminalController 验证

**测试文件：** `VibeIslandTests/Terminal/TerminalControllerTests.swift`

**测试用例：**

| 测试名称 | 输入 | 预期输出 | 验证点 |
|---------|------|---------|--------|
| testTerminalTypeIterm2BundleId | TerminalType.iterm2 | "com.googlecode.iterm2" | Bundle ID 正确 |
| testTerminalTypeTerminalBundleId | TerminalType.terminal | "com.apple.terminal" | Bundle ID 正确 |
| testTerminalTypeIterm2DisplayName | TerminalType.iterm2 | "iTerm2" | 显示名称正确 |
| testTerminalTypeTerminalDisplayName | TerminalType.terminal | "Terminal.app" | 显示名称正确 |
| testIsTerminalRunningIterm2Running | 运行中的 iTerm2 | true | 正确检测运行状态 |
| testIsTerminalRunningIterm2NotRunning | 未运行的 iTerm2 | false | 正确检测运行状态 |
| testIsTerminalRunningTerminalRunning | 运行中的 Terminal.app | true | 正确检测运行状态 |
| testIsTerminalRunningTerminalNotRunning | 未运行的 Terminal.app | false | 正确检测运行状态 |
| testJumpToTabIterm2Success | iTerm2, 有效 tabId | true, 标签页被激活 | 跳转成功 |
| testJumpToTabTerminalSuccess | Terminal.app, 有效 tabId | true, 标签页被激活 | 跳转成功 |
| testJumpToTabIterm2NotRunning | iTerm2, tabId | false | 处理未运行情况 |
| testJumpToTabTerminalNotRunning | Terminal.app, tabId | false | 处理未运行情况 |
| testJumpToTabInvalidTabId | iTerm2, 无效 tabId | false | 处理无效标签页 |
| testJumpToTabAppleScriptError | 模拟错误 | false | 错误处理 |

**验证方法：**
- 单元测试验证每个方法的逻辑正确性
- 使用模拟对象测试 AppleScript 执行失败的情况
- 边界测试覆盖各种输入组合

### Wave 2: UI 集成验证

**测试文件：** `VibeIslandTests/MenuBar/ExpandedDetailsViewTests.swift`

**测试用例：**

| 测试名称 | 场景 | 预期行为 | 验证点 |
|---------|------|---------|--------|
| testAgentCardTapGesture | 点击代理卡片 | 调用 jumpToTerminalTab | 点击交互正常 |
| testJumpToTerminalTabNoBundleId | terminalAppBundleId 为空 | 显示错误警告 | 空值处理 |
| testJumpToTerminalTabNoTabId | terminalTabId 为 nil | 显示错误警告 | 空值处理 |
| testJumpToTerminalTabUnsupportedTerminal | 不支持的 Bundle ID | 显示错误警告 | 不支持处理 |
| testJumpToTerminalTabIterm2NotRunning | iTerm2 未运行 | 显示错误警告 | 未运行处理 |
| testJumpToTerminalTabTerminalNotRunning | Terminal.app 未运行 | 显示错误警告 | 未运行处理 |
| testJumpToTerminalTabSuccess | 有效输入 | 成功跳转，无警告 | 成功路径 |
| testAlertShownOnError | 跳转失败 | Alert 显示 | 错误反馈 |
| testAccessibilityHint | VoiceOver 模式 | 正确播报提示 | 辅助功能 |

**验证方法：**
- UI 测试验证点击交互
- 状态测试验证错误处理逻辑
- 辅助功能测试验证 VoiceOver 支持

### Wave 3: 人工验证

**验证场景：**

1. **正常跳转 - iTerm2**
   - 前置条件：iTerm2 运行中，有多个标签页
   - 操作：点击代理卡片
   - 预期：iTerm2 激活，对应标签页被选中

2. **正常跳转 - Terminal.app**
   - 前置条件：Terminal.app 运行中，有多个标签页
   - 操作：点击代理卡片
   - 预期：Terminal.app 激活，对应标签页被选中

3. **终端未运行**
   - 前置条件：终端应用关闭
   - 操作：点击代理卡片
   - 预期：显示错误提示

4. **不支持的终端**
   - 前置条件：使用非 iTerm2/Terminal.app
   - 操作：点击代理卡片
   - 预期：显示"不支持"错误

5. **多终端同时打开**
   - 前置条件：iTerm2 和 Terminal.app 同时运行
   - 操作：点击不同终端类型的代理卡片
   - 预期：正确跳转到对应终端

6. **VoiceOver 辅助功能**
   - 前置条件：启用 VoiceOver
   - 操作：聚焦代理卡片
   - 预期：正确播报按钮提示

## Success Criteria

### 功能性

- [ ] **CORE-03**: User can click agent card to jump to corresponding terminal tab in iTerm2
- [ ] **CORE-04**: User can click agent card to jump to corresponding terminal tab in Terminal.app
- [ ] **SC-03**: Terminal app detection works correctly when multiple terminals are open
- [ ] **SC-04**: App provides feedback when terminal integration fails gracefully

### 质量标准

- [ ] 所有单元测试通过
- [ ] 所有集成测试通过
- [ ] 编译无警告
- [ ] 代码注释使用中文
- [ ] 错误消息使用中文
- [ ] VoiceOver 辅助功能正常

### 边界条件

- [ ] 终端应用未运行时显示正确错误
- [ ] 终端标签页不存在时显示正确错误
- [ ] 不支持的终端应用显示正确错误
- [ ] Agent 缺少终端信息时显示正确错误
- [ ] 多终端应用同时打开时正确处理

## Test Execution

### 自动化测试

```bash
# 运行所有测试
xcodebuild test -scheme VibeIsland -destination 'platform=macOS'

# 运行 TerminalController 测试
xcodebuild test -scheme VibeIsland -destination 'platform=macOS' \
  -only-testing:VibeIslandTests/TerminalControllerTests

# 运行 ExpandedDetailsView 测试
xcodebuild test -scheme VibeIsland -destination 'platform=macOS' \
  -only-testing:VibeIslandTests/ExpandedDetailsViewTests
```

### 人工验证

使用 Phase 4 Plan 02 的 Checkpoint 任务进行人工验证。

---

*Validation strategy created: 2026-04-02*