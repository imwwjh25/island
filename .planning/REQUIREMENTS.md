# Requirements: Vibe Island (kpbl)

**Defined:** 2026-04-03
**Core Value:** Never lose track of which agent conversation needs your attention — see all agent states in one glance without switching terminals

---

## v1.0 Requirements (MVP - Complete)

### Dynamic Island UI

- [x] **DIUI-01**: User sees compact state with agent count and status summary
- [x] **DIUI-02**: User can tap Dynamic Island to expand to detailed view
- [x] **DIUI-03**: User sees smooth animations between compact and expanded states
- [x] **DIUI-04**: User can tap background to collapse expanded view

### State Management

- [x] **STMG-01**: Agent states reflect actual Claude Code status (not stale data)
- [x] **STMG-02**: Agent states persist across app backgrounding and termination
- [x] **STMG-03**: Multiple active Claude Code agents display in one Dynamic Island view

### Agent Monitoring

- [x] **AGNT-01**: App connects to Claude Code via local socket
- [x] **AGNT-02**: App parses agent states: in_progress, complete, awaiting_approval
- [x] **AGNT-03**: App detects when agent status changes

### Core Features

- [x] **CORE-01**: Dynamic Island automatically expands when agent needs approval
- [x] **CORE-02**: Dynamic Island automatically expands when agent completes
- [ ] **CORE-03**: User can click agent card to jump to corresponding terminal tab (iTerm2)
- [ ] **CORE-04**: User can click agent card to jump to corresponding terminal tab (Terminal.app)
- [x] **CORE-05**: App plays 8-bit pixel game sound effect when agent changes to in_progress
- [x] **CORE-06**: App plays 8-bit pixel game sound effect when agent changes to complete
- [x] **CORE-07**: App plays 8-bit pixel game sound effect when agent changes to awaiting_approval
- [x] **CORE-08**: Sound effects respect system mute state

### Accessibility

- [x] **ACCS-01**: VoiceOver announces Dynamic Island content correctly
- [x] **ACCS-02**: Dynamic Island UI adapts to system appearance (light/dark mode)
- [x] **ACCS-03**: Dynamic Island UI respects reduced motion accessibility setting

---

## v2.0 Requirements (kpbl)

**Project Code:** `kpbl` — 自用版本迭代代号

### MENUBAR — 菜单栏动态图标

- [ ] **MENUBAR-01**: 用户看到菜单栏显示动态状态指示（状态圆点 + 数量徽章）
- [ ] **MENUBAR-02**: 用户在重要状态变化时看到闪烁动画效果（等待审批/完成）
- [ ] **MENUBAR-03**: 用户看到视觉强调效果（缩放脉冲 + 阴影发光）
- [ ] **MENUBAR-04**: 用户看到赛博朋克霓虹配色方案（青色、品红色、黄色）
- [ ] **MENUBAR-05**: 用户在减少动画模式下看到静态替代效果

### STATUS — 状态检测增强

- [ ] **STATUS-01**: 系统正确识别代理状态（进行中/等待审批/完成）
- [ ] **STATUS-02**: 系统优化关键词检测精度，减少误识别
- [ ] **STATUS-03**: 系统在3秒内检测到状态变化

### SOUND — 音效系统

- [ ] **SOUND-01**: 用户听到不同状态的不同音效（进行中/等待审批/完成）
- [ ] **SOUND-02**: 系统在系统静音时不播放音效
- [ ] **SOUND-03**: 用户可以启用/禁用音效

### FIX — 基础修复

- [ ] **FIX-01**: 修复 @ObservedObject 与单例组合导致的状态丢失问题
- [ ] **FIX-02**: 配置 AVAudioSession 使音效在菜单栏应用中正常工作
- [ ] **FIX-03**: 添加 Accessibility 权限检查并提示用户授权

---

## v3.0 Requirements (Deferred)

### Extended Status Detection

- **STATUS-04**: 系统识别错误状态
- **STATUS-05**: 系统识别空闲状态
- **STATUS-06**: 系统识别思考中状态

### Terminal Integration

- **TERM-01**: 系统精确识别终端标签页 ID
- **TERM-02**: 用户点击代理卡片跳转到正确的终端标签页

### WezTerm Support

- **TERM-03**: 系统支持 WezTerm 终端跳转

### Enhanced UX

- **ENH-01**: User can view activity history of recently completed agents
- **ENH-02**: User sees priority indicators for urgent tasks

### Additional Agents

- **AGXT-01**: App supports monitoring Codex agents
- **AGXT-02**: App supports monitoring OpenClaw agents

---

## Out of Scope

| Feature | Reason |
|---------|--------|
| Socket 协议检测 | Claude Code CLI 不暴露 socket，复杂度高 |
| AI 驱动标题解析 | 过度设计，关键词匹配已足够 |
| 多代理支持 (Codex) | 先验证 Claude Code 概念，v3+ 再扩展 |
| 活动历史记录 | 延后到 v3+ |
| 自定义通知中心 | 使用 macOS 原生通知即可 |
| Terminal content display | Privacy concern — status only, not actual terminal output |
| Chat interface in Dynamic Island | Too cramped, violates Apple's compact design principles |
| Agent configuration UI | Hardcoded for Claude Code in MVP — defer to v3+ |

---

## Traceability

### v1.0 (MVP)

| Requirement | Phase | Status |
|-------------|-------|--------|
| DIUI-01 | Phase 3 | Complete |
| DIUI-02 | Phase 3 | Complete |
| DIUI-03 | Phase 3 | Complete |
| DIUI-04 | Phase 3 | Complete |
| STMG-01 | Phase 2 | Complete |
| STMG-02 | Phase 1 | Complete |
| STMG-03 | Phase 3 | Complete |
| AGNT-01 | Phase 1 | Complete |
| AGNT-02 | Phase 1 | Complete |
| AGNT-03 | Phase 2 | Complete |
| CORE-01 | Phase 3 | Complete |
| CORE-02 | Phase 3 | Complete |
| CORE-03 | Phase 4 | Pending |
| CORE-04 | Phase 4 | Pending |
| CORE-05 | Phase 2 | Complete |
| CORE-06 | Phase 2 | Complete |
| CORE-07 | Phase 2 | Complete |
| CORE-08 | Phase 2 | Complete |
| ACCS-01 | Phase 3 | Complete |
| ACCS-02 | Phase 3 | Complete |
| ACCS-03 | Phase 3 | Complete |

### v2.0 (kpbl)

| Requirement | Phase | Status |
|-------------|-------|--------|
| MENUBAR-01 | Phase 6 | Pending |
| MENUBAR-02 | Phase 6 | Pending |
| MENUBAR-03 | Phase 6 | Pending |
| MENUBAR-04 | Phase 6 | Pending |
| MENUBAR-05 | Phase 6 | Pending |
| STATUS-01 | Phase 7 | Pending |
| STATUS-02 | Phase 7 | Pending |
| STATUS-03 | Phase 7 | Pending |
| SOUND-01 | Phase 8 | Pending |
| SOUND-02 | Phase 8 | Pending |
| SOUND-03 | Phase 8 | Pending |
| FIX-01 | Phase 6 | Pending |
| FIX-02 | Phase 8 | Pending |
| FIX-03 | Phase 7 | Pending |

**Coverage:**
- v2.0 requirements: 14 total
- Mapped to phases: 14
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-02*
*Last updated: 2026-04-03 after v2.0 kpbl milestone definition*