---
phase: 02-main-app-core
plan: 01
type: execute
wave: 1
depends_on:
  - 01-data-layer-foundation-01
files_modified:
  - VibeIsland/State/StateManager.swift
  - VibeIsland/VibeIslandApp.swift
autonomous: true
requirements:
  - AGNT-03
  - STMG-01
  - CORE-05
  - CORE-06
  - CORE-07
  - CORE-08
user_setup:
  - service: sound-effects
    why: "需要8-bit风格音效文件用于状态变化反馈"
    env_vars: []
    dashboard_config:
      - task: "创建或获取8-bit风格音效文件（AIFF或WAV格式）"
        location: "应用bundle资源目录"

must_haves:
  truths:
    - "应用检测代理状态何时变化（in_progress、complete、awaiting_approval）"
    - "应用在状态变化时播放8-bit像素游戏音效"
    - "音效尊重系统静音状态（静音时不播放声音）"
    - "Widget在状态变化后立即重新加载时间线"
  artifacts:
    - path: "VibeIsland/State/StateManager.swift"
      provides: "状态变化检测和事件发布"
      exports: ["updateAgentState", "lastAgentStates"]
    - path: "VibeIsland/Sound/SoundManager.swift"
      provides: "音效播放管理"
      exports: ["playStateChangeSound", "isSystemMuted", "isSoundEnabled"]
    - path: "VibeIsland/VibeIslandApp.swift"
      provides: "音效触发和widget重新加载优化"
      contains: "状态变化监听、频率限制"
    - path: "VibeIsland/Resources/sounds/state_update.aiff"
      provides: "8-bit风格音效文件"
      min_lines: 1
  key_links:
    - from: "VibeIsland/State/StateManager.swift"
      to: "VibeIsland/Sound/SoundManager.swift"
      via: "状态变化通知"
      pattern: "agentStatusDidChange"
    - from: "VibeIsland/Sound/SoundManager.swift"
      to: "AVAudioPlayer"
      via: "音效播放"
      pattern: "AVAudioPlayer.*play"
    - from: "VibeIsland/VibeIslandApp.swift"
      to: "WidgetCenter"
      via: "时间线重新加载"
      pattern: "reloadAllTimelines"
---

<objective>
实现后台监控，检测代理状态变化并提供音效反馈。

目的：让用户能够在代理状态变化时立即得到听觉反馈，同时确保widget实时显示最新状态。这解决了"代理状态反映实际的Claude Code状态"和"音效尊重系统静音状态"的需求。

输出：完整的状态变化检测、音效播放系统和优化的widget时间线重新加载机制。
</objective>

<execution_context>
@/Users/Zhuanz/island/.claude/get-shit-done/workflows/execute-plan.md
@/Users/Zhuanz/island/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/02-main-app-core/02-CONTEXT.md
@.planning/REQUIREMENTS.md
@.planning/research/STACK.md
@.planning/research/PITFALLS.md
@.planning/phases/01-data-layer-foundation/01-data-layer-foundation-01-SUMMARY.md

# 上下文决策（已锁定）
- D-01: 在StateManager中追踪上一个状态，仅在状态变化时触发事件（响应AGNT-03）
- D-02: 为每个代理维护状态历史，检测从相同状态到相同状态的更新（避免重复音效）
- D-03: 使用AVFoundation的AVAudioPlayer播放音效（响应CORE-05/06/07）
- D-04: 音效格式：短8-bit风格AIFF或WAV文件，内置在应用bundle中
- D-05: 单一"状态更新"音效（简化MVP，用于所有状态变化）
- D-06: 通过AVAudioSession检测系统静音状态（响应CORE-08）
- D-07: 在播放前检查静音状态，静音时跳过音效
- D-08: 在状态变化时调用WidgetCenter.shared.reloadTimelines()
- D-09: 限制重新加载频率（最多每秒一次），避免过度调用
- D-10: 提供音效开关（UserDefaults存储）
- D-11: 默认启用音效

# 关键陷阱
- PITFALLS.md #1: WidgetKit更新延迟 - 需要立即重新加载时间线
- PITFALLS.md #6: 套接字连接不健壮 - Phase 1已实现，需确保稳定
- PITFALLS.md #7: 不当播放音效 - 必须检测系统静音，仅在状态转换时播放
- PITFALLS.md #9: 内存泄漏 - 正确管理AVAudioPlayer和定时器

# Phase 1 实现摘要
- StateManager已实现：单例模式、状态持久化、发布通知（.agentStateDidChange, .agentStatesDidChange）
- SocketMonitor已实现：指数退避重连、心跳机制、JSON消息解析
- VibeIslandApp已实现：基本的widget重新加载触发器
- 所有单元测试通过

# 需要增强的组件
- StateManager: 添加状态变化检测逻辑（比较新旧状态）
- VibeIslandApp: 添加音效管理和优化widget重新加载

# 需要新建的组件
- SoundManager: 音效播放管理
- 8-bit音效文件: state_update.aiff
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: 增强StateManager的状态变化检测</name>
  <files>
    VibeIsland/State/StateManager.swift
    VibeIslandTests/StateManagerTests.swift
  </files>
  <behavior>
    - StateManager追踪每个代理的上一个状态
    - StateManager仅在状态实际变化时触发agentStatusDidChange通知
    - StateManager检测从相同状态到相同状态的更新，不触发事件（避免重复音效）
    - 通知包含代理ID、旧状态和新状态信息
  </behavior>
  <action>
    1. 增强VibeIsland/State/StateManager.swift：
       - 添加属性：`private var lastAgentStates: [String: AgentStatus] = [:]` 追踪上一个状态
       - 修改updateAgentState(_ agent: AgentState)方法：
         - 获取旧状态：`let oldStatus = stateDictionary[agent.id]?.status`
         - 比较新旧状态：`let statusChanged = oldStatus != agent.status`
         - 仅在状态变化时发布agentStatusDidChange通知
         - 更新lastAgentStates字典
         - 通知userInfo包含：["agentId": agent.id, "oldStatus": oldStatus?.rawValue, "newStatus": agent.status.rawValue]
       - 修改loadPersistedStates()方法：
         - 初始化lastAgentStates字典
         - 从持久化状态中加载最后一个状态
       - 添加状态变化检测辅助方法：
         - `didAgentStatusChange(_ agentId: String, newStatus: AgentStatus) -> Bool`
         - 返回布尔值表示状态是否变化

    2. 更新VibeIslandTests/StateManagerTests.swift：
       - 测试状态变化检测：从in_progress到complete应触发通知
       - 测试无状态变化：从in_progress到in_progress不应触发通知
       - 测试新代理状态：新代理应被视为状态变化
       - 测试lastAgentStates追踪：验证正确记录上一个状态
       - 测试批量更新：updateAgentStates应正确处理多个代理的状态变化

    注意：确保代码注释使用中文（遵循CLAUDE.md规范）
  </action>
  <verify>
    <automated>xcodebuild test -scheme VibeIsland -destination 'platform=macOS' -only-testing:VibeIslandTests/StateManagerTests</automated>
  </verify>
  <done>
    - StateManager正确追踪每个代理的上一个状态
    - 状态变化时发布agentStatusDidChange通知，包含完整的状态信息
    - 无状态变化时不发布通知（避免重复音效）
    - 所有单元测试通过
    - 代码注释使用中文
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: 实现音效播放系统</name>
  <files>
    VibeIsland/Sound/SoundManager.swift
    VibeIslandTests/SoundManagerTests.swift
    VibeIsland/Resources/sounds/state_update.aiff
  </files>
  <behavior>
    - SoundManager使用AVAudioPlayer播放8-bit风格音效
    - SoundManager检测系统静音状态，静音时不播放音效
    - SoundManager提供音效开关（UserDefaults存储）
    - SoundManager默认启用音效
    - SoundManager提供playStateChangeSound()方法播放状态变化音效
  </behavior>
  <action>
    1. 创建VibeIsland/Sound/SoundManager.swift：
       - 实现单例模式：`static let shared = SoundManager()`
       - 定义常量：音效文件名"state_update.aiff"，UserDefaults键"soundEnabled"
       - 添加属性：
         - `private var audioPlayer: AVAudioPlayer?`
         - `@Published var isSoundEnabled: Bool`（绑定到UserDefaults）
         - `private var lastReloadTime: Date?` 用于频率限制
       - 实现初始化：
         - 从UserDefaults加载音效设置，默认为true
         - 加载音效文件到内存
       - 实现playStateChangeSound()方法：
         - 检查音效是否启用，禁用时直接返回
         - 调用isSystemMuted()检查系统静音状态
         - 静音时直接返回，不播放音效
         - 重置audioPlayer到开头
         - 播放音效
         - 记录播放日志
       - 实现isSystemMuted()方法：
         - 使用AVAudioSession.sharedInstance().outputVolume检查音量
         - 返回布尔值表示系统是否静音
       - 实现toggleSound()方法：
         - 切换音效开关
         - 保存到UserDefaults
       - 实现loadSoundFile()私有方法：
         - 从bundle加载音效文件
         - 创建AVAudioPlayer实例
         - 错误处理：文件不存在或加载失败时记录日志
       - 错误处理：
         - 音效文件不存在时提供优雅降级
         - 播放失败时不影响应用功能

    2. 创建或准备VibeIsland/Resources/sounds/state_update.aiff：
       - 8-bit风格短音效（0.5秒以内）
       - 使用Classic NES风格的合成音效
       - 音量适中（不过大或过小）

    3. 创建VibeIslandTests/SoundManagerTests.swift：
       - 测试音效文件加载：验证文件存在且可播放
       - 测试系统静音检测：isSystemMuted()返回正确值
       - 测试音效开关：toggleSound()切换音效状态
       - 测试音效播放：playStateChangeSound()在启用时播放
       - 测试静音时跳过：系统静音时不播放音效
       - 测试禁用时跳过：音效禁用时不播放音效
       - 测试UserDefaults持久化：音效设置在应用重启后保留

    注意：确保代码注释使用中文（遵循CLAUDE.md规范）
  </action>
  <verify>
    <automated>xcodebuild test -scheme VibeIsland -destination 'platform=macOS' -only-testing:VibeIslandTests/SoundManagerTests</automated>
  </verify>
  <done>
    - SoundManager成功加载音效文件
    - SoundManager正确检测系统静音状态
    - SoundManager在系统静音时跳过音效播放
    - SoundManager提供音效开关并持久化到UserDefaults
    - SoundManager默认启用音效
    - 所有单元测试通过
    - 代码注释使用中文
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: 集成音效系统和优化widget重新加载</name>
  <files>
    VibeIsland/VibeIslandApp.swift
    VibeIslandTests/VibeIslandAppTests.swift
  </files>
  <behavior>
    - VibeIslandApp监听状态变化通知并触发音效
    - VibeIslandApp优化widget重新加载，限制频率（最多每秒一次）
    - VibeIslandApp在状态变化后立即重新加载widget时间线
  </behavior>
  <action>
    1. 增强VibeIsland/VibeIslandApp.swift：
       - 添加属性：
         - `private var lastWidgetReloadTime: Date?` 用于频率限制
         - `private let widgetReloadInterval: TimeInterval = 1.0` 最大每秒一次
       - 修改setupIntegration()方法：
         - 添加状态变化通知监听
         - 在收到agentStatusDidChange通知时调用playStateChangeSound()
         - 在收到通知后调用triggerWidgetUpdate()
       - 优化triggerWidgetUpdate(agentId: String? = nil)方法：
         - 检查距离上次重新加载的时间间隔
         - 如果间隔小于widgetReloadInterval，跳过重新加载
         - 否则调用WidgetCenter.shared.reloadAllTimelines()
         - 更新lastWidgetReloadTime
       - 添加playStateChangeSound()方法：
         - 调用SoundManager.shared.playStateChangeSound()
       - 添加系统静音状态变化监听（可选增强）：
         - 使用AVAudioSession通知监听音量变化
         - 在静音/取消静音时更新UI或提供反馈

    2. 创建或增强VibeIslandTests/VibeIslandAppTests.swift：
       - 测试状态变化时触发音效：验证SoundManager被调用
       - 测试widget重新加载频率限制：验证每秒最多一次
       - 测试连续状态变化处理：多次快速变化正确处理
       - 测试批量状态更新处理：agentStatesDidChange通知正确处理
       - 集成测试：完整的状态变化→音效→widget重新加载流程

    3. 验证Notification.Name扩展：
       - 确保agentStatusDidChange通知包含正确的userInfo
       - 验证旧状态和新状态信息正确传递

    注意：确保代码注释使用中文（遵循CLAUDE.md规范）
  </action>
  <verify>
    <automated>xcodebuild test -scheme VibeIsland -destination 'platform=macOS' -only-testing:VibeIslandTests/VibeIslandAppTests</automated>
  </verify>
  <done>
    - VibeIslandApp在状态变化时触发音效播放
    - VibeIslandApp优化widget重新加载，限制频率为每秒最多一次
    - VibeIslandApp在状态变化后立即重新加载widget时间线
    - 连续状态变化正确处理，避免过度重新加载
    - 所有单元测试通过
    - 代码注释使用中文
  </done>
</task>

</tasks>

<verification>
## 整体验证

### 自动化验证
1. 运行所有单元测试：`xcodebuild test -scheme VibeIsland -destination 'platform=macOS'`
2. 验证状态变化检测：模拟代理状态变化，验证通知触发
3. 验证音效播放：模拟状态变化，验证音效播放
4. 验证系统静音检测：设置系统静音，验证音效不播放
5. 验证widget重新加载：模拟状态变化，验证widget时间线重新加载
6. 验证频率限制：快速触发多次状态变化，验证widget重新加载不超过每秒一次

### 手动验证（需要用户配置）
1. 启动Claude Code CLI，创建并更新代理状态
2. 启动Vibe Island应用
3. 验证代理状态变化时播放音效
4. 系统静音状态下验证音效不播放
5. 通过偏好设置切换音效开关，验证音效启用/禁用
6. 观察动态岛widget，验证状态实时更新

### 功能验证
- [ ] 应用检测代理状态何时变化（响应AGNT-03）
- [ ] 代理状态反映实际的Claude Code状态（响应STMG-01）
- [ ] 代理变化到in_progress时应用播放8-bit像素游戏音效（响应CORE-05）
- [ ] 代理变化到complete时应用播放8-bit像素游戏音效（响应CORE-06）
- [ ] 代理变化到awaiting_approval时应用播放8-bit像素游戏音效（响应CORE-07）
- [ ] 音效尊重系统静音状态（响应CORE-08）

### 集成验证
- [ ] StateManager → SoundManager数据流正常
- [ ] StateManager → VibeIslandApp通知流正常
- [ ] VibeIslandApp → SoundManager音效触发正常
- [ ] VibeIslandApp → WidgetCenter重新加载正常

## 风险和缓解措施

| 风险 | 缓解措施 |
|------|----------|
| 音效文件缺失或加载失败 | 在SoundManager中提供优雅降级，记录错误日志，不影响应用核心功能 |
| 系统静音检测不准确 | 在测试中验证多个场景，提供备用检测方法 |
| Widget重新加载频率限制导致延迟 | 设置合理的间隔（1秒），确保关键状态变化立即更新 |
| 音效播放影响性能 | 使用短音效（0.5秒以内），避免阻塞主线程 |
| 内存泄漏（AVAudioPlayer） | 正确管理audioPlayer实例，在不再需要时释放资源 |
| 状态变化通知丢失 | 确保NotificationCenter正确配置，测试多线程场景 |

</verification>

<success_criteria>
## 完成标准

### 功能完成
- [ ] StateManager追踪每个代理的上一个状态
- [ ] StateManager仅在状态变化时触发agentStatusDidChange通知
- [ ] StateManager检测从相同状态到相同状态的更新，不触发事件
- [ ] SoundManager成功加载8-bit风格音效文件
- [ ] SoundManager正确检测系统静音状态
- [ ] SoundManager在系统静音时跳过音效播放
- [ ] SoundManager提供音效开关并持久化到UserDefaults
- [ ] SoundManager默认启用音效
- [ ] VibeIslandApp在状态变化时触发音效播放
- [ ] VibeIslandApp优化widget重新加载，限制频率为每秒最多一次
- [ ] VibeIslandApp在状态变化后立即重新加载widget时间线

### 测试完成
- [ ] StateManager状态变化检测测试通过
- [ ] StateManager无状态变化测试通过
- [ ] StateManager新代理状态测试通过
- [ ] StateManagerlastAgentStates追踪测试通过
- [ ] StateManager批量更新测试通过
- [ ] SoundManager音效文件加载测试通过
- [ ] SoundManager系统静音检测测试通过
- [ ] SoundManager音效开关测试通过
- [ ] SoundManager音效播放测试通过
- [ ] SoundManager静音时跳过测试通过
- [ ] SoundManager禁用时跳过测试通过
- [ ] SoundManagerUserDefaults持久化测试通过
- [ ] VibeIslandApp状态变化音效测试通过
- [ ] VibeIslandAppwidget重新加载频率限制测试通过
- [ ] VibeIslandApp连续状态变化处理测试通过
- [ ] VibeIslandApp批量状态更新处理测试通过
- [ ] VibeIslandApp集成测试通过

### 文档完成
- [ ] 代码注释使用中文
- [ ] 音效文件提供
- [ ] 音效开关配置说明提供

### 质量标准
- [ ] 所有代码遵循Swift编码规范
- [ ] 所有公共接口有文档注释
- [ ] 错误处理完善且有日志记录
- [ ] 无编译警告
- [ ] 无内存泄漏（通过Instruments验证）
- [ ] 音效文件大小合理（<100KB）

### 需求覆盖
- [ ] AGNT-03: 应用检测代理状态何时变化
- [ ] STMG-01: 代理状态反映实际的Claude Code状态（不是过时数据）
- [ ] CORE-05: 代理变化到in_progress时应用播放8-bit像素游戏音效
- [ ] CORE-06: 代理变化到complete时应用播放8-bit像素游戏音效
- [ ] CORE-07: 代理变化到awaiting_approval时应用播放8-bit像素游戏音效
- [ ] CORE-08: 音效尊重系统静音状态

</success_criteria>

<output>
完成阶段后，创建`.planning/phases/02-main-app-core/02-main-app-core-01-SUMMARY.md`，包含：
- 实现的组件列表（状态变化检测、音效系统、widget重新加载优化）
- 测试结果摘要
- 遇到的挑战和解决方案
- 与需求的映射（AGNT-03, STMG-01, CORE-05, CORE-06, CORE-07, CORE-08）
- 下一阶段的依赖项（widget扩展需要访问实时状态）
</output>