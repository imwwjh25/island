---
status: partial
phase: 04-terminal-integration
source: [04-terminal-integration-VERIFICATION.md]
started: 2026-04-02T22:00:00Z
updated: 2026-04-02T22:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. 点击代理卡片跳转到 iTerm2 标签页
expected: iTerm2 激活并切换到对应标签页
result: [pending]

### 2. 点击代理卡片跳转到 Terminal.app 标签页
expected: Terminal.app 激活并切换到对应标签页
result: [pending]

### 3. 终端应用未运行时显示错误提示
expected: 显示友好的错误警告：'{终端名称} 未运行，请先启动该应用'
result: [pending]

### 4. 标签页不存在时显示错误提示
expected: 显示友好的错误警告：'无法跳转到标签页 {tabId}，请检查标签页是否存在'
result: [pending]

### 5. 辅助功能支持验证
expected: VoiceOver 正确播报代理卡片和跳转提示
result: [pending]

### 6. 多终端同时运行场景
expected: 两种终端应用的跳转互不干扰
result: [pending]

## Summary

total: 6
passed: 0
issues: 0
pending: 6
skipped: 0
blocked: 0

## Gaps
