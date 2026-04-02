---
phase: 01-data-layer-foundation
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - VibeIsland/Models/AgentState.swift
  - VibeIsland/State/StateManager.swift
  - VibeIsland/Networking/SocketMonitor.swift
  - VibeIsland/SharedContainer/SharedContainer.swift
  - VibeIslandWidget/SharedModels/AgentState.swift
autonomous: true
requirements:
  - AGNT-01
  - AGNT-02
  - STMG-02
  - STMG-03
user_setup:
  - service: claude-code
    why: "套接字连接需要Claude Code CLI运行并监听本地套接字"
    env_vars: []
    dashboard_config:
      - task: "确认Claude Code配置为监听本地套接字"
        location: "Claude Code配置文件或启动参数"
  - service: app-groups
    why: "主应用和widget扩展必须使用相同的App Group标识符"
    env_vars: []
    dashboard_config:
      - task: "在Xcode项目中为主应用和widget扩展启用App Groups能力"
        location: "Xcode -> Signing & Capabilities -> App Groups"

must_haves:
  truths:
    - "应用通过本地套接字连接到Claude Code并成功解析JSON消息"
    - "应用检测并存储共享容器中的多个并发代理状态"
    - "代理状态在应用终止和重新启动后持久化"
    - "共享容器可被主应用和widget扩展访问"
  artifacts:
    - path: "VibeIsland/Models/AgentState.swift"
      provides: "代理状态数据模型"
      contains: "struct AgentState, enum AgentStatus"
    - path: "VibeIsland/State/StateManager.swift"
      provides: "中央状态管理和持久化"
      exports: ["StateManager", "updateAgentState", "getAgentStates", "getAgentState"]
    - path: "VibeIsland/Networking/SocketMonitor.swift"
      provides: "套接字连接和消息解析"
      exports: ["SocketMonitor", "start", "stop", "onMessageReceived"]
    - path: "VibeIsland/SharedContainer/SharedContainer.swift"
      provides: "App Groups共享容器访问"
      exports: ["SharedContainer", "sharedUserDefaults"]
    - path: "VibeIslandWidget/SharedModels/AgentState.swift"
      provides: "widget使用的代理状态模型"
      contains: "struct AgentState, enum AgentStatus"
  key_links:
    - from: "VibeIsland/Networking/SocketMonitor.swift"
      to: "VibeIsland/State/StateManager.swift"
      via: "状态更新回调"
      pattern: "updateAgentState"
    - from: "VibeIsland/State/StateManager.swift"
      to: "VibeIsland/SharedContainer/SharedContainer.swift"
      via: "UserDefaults写入"
      pattern: "sharedUserDefaults\\..*set"
    - from: "VibeIsland/Models/AgentState.swift"
      to: "VibeIslandWidget/SharedModels/AgentState.swift"
      via: "共享数据模型定义"
      pattern: "struct AgentState"
---

<objective>
建立共享数据基础设施，使主应用和widget扩展能够可靠地通信和持久化代理状态。

目的：这是整个项目的基础，如果没有可靠的数据流，所有后续功能（UI、音效、终端集成）都无法正常工作。本阶段确保主应用和widget扩展能够通过App Groups共享数据，并通过套接字接收Claude Code的状态更新。

输出：完整的数据层实现，包括数据模型、状态管理器、套接字监控器和共享容器访问，以及单元测试验证数据流。
</objective>

<execution_context>
@/Users/Zhuanz/island/.claude/get-shit-done/workflows/execute-plan.md
@/Users/Zhuanz/island/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/01-data-layer-foundation/01-CONTEXT.md
@.planning/REQUIREMENTS.md
@.planning/research/ARCHITECTURE.md
@.planning/research/STACK.md
@.planning/research/PITFALLS.md

# 上下文决策（已锁定）
- D-01: Socket协议格式为JSON，包含agent_id, status, terminal, timestamp
- D-02: 共享数据结构为UserDefaults字典，以agent_id为键
- D-03: 连接处理使用指数退避重连策略（1s起始，30s最大，倍增）
- D-04: 数据模型最小化字段：id, status, terminalAppBundleId, terminalTabId, lastUpdated

# 关键陷阱
- PITFALLS.md #2: App Group配置错误会导致无法共享数据
- PITFALLS.md #6: 套接字连接需要健壮的错误处理和重连机制
- PITFALLS.md #8: 状态必须持久化到UserDefaults
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: 创建共享数据模型和状态管理器</name>
  <files>
    VibeIsland/Models/AgentState.swift
    VibeIsland/State/StateManager.swift
    VibeIsland/SharedContainer/SharedContainer.swift
    VibeIslandWidget/SharedModels/AgentState.swift
    VibeIslandTests/StateManagerTests.swift
  </files>
  <behavior>
    - AgentState数据模型包含：id (String), status (AgentStatus枚举), terminalAppBundleId (String), terminalTabId (String可选), lastUpdated (ISO8601字符串)
    - AgentStatus枚举值：inProgress, complete, awaitingApproval
    - StateManager能够存储和检索多个代理状态
    - StateManager在状态更新时持久化到App Groups共享容器
    - StateManager在应用启动时从共享容器加载持久化状态
    - SharedContainer提供访问App Groups共享UserDefaults的接口
  </behavior>
  <action>
    1. 创建VibeIsland/Models/AgentState.swift：
       - 定义AgentStatus枚举（遵循Codable, CaseIterable）
       - 定义AgentState结构体（遵循Codable, Identifiable, Equatable）
       - 包含字段：id, status, terminalAppBundleId, terminalTabId, lastUpdated
       - 添加静态方法从JSON字符串创建AgentState（处理错误）

    2. 创建VibeIslandWidget/SharedModels/AgentState.swift：
       - 复制主应用的AgentState和AgentStatus定义
       - 确保widget扩展使用相同的数据模型

    3. 创建VibeIsland/SharedContainer/SharedContainer.swift：
       - 定义常量appGroupIdentifier（从配置或环境变量读取）
       - 提供共享UserDefaults访问：static var sharedUserDefaults: UserDefaults?
       - 实现错误处理：如果App Groups未配置，提供优雅降级

    4. 创建VibeIsland/State/StateManager.swift：
       - 实现单例模式或依赖注入（根据项目约定）
       - 维护内部状态：[String: AgentState]字典（agent_id -> AgentState）
       - 实现updateAgentState(_ agent: AgentState)方法：
         - 更新或添加代理状态
         - 持久化到SharedContainer.sharedUserDefaults
         - 触发状态变化事件（发布/订阅或回调）
       - 实现getAgentStates() -> [AgentState]方法：返回所有代理状态
       - 实现getAgentState(id: String) -> AgentState?方法：返回特定代理状态
       - 实现loadPersistedStates()方法：从SharedContainer加载持久化状态
       - 在初始化时调用loadPersistedStates()恢复状态

    5. 创建VibeIslandTests/StateManagerTests.swift：
       - 测试updateAgentState正确添加新代理
       - 测试updateAgentState正确更新现有代理
       - 测试getAgentStates返回所有代理
       - 测试getAgentState返回特定代理
       - 测试状态持久化到SharedContainer
       - 测试loadPersistedStates从SharedContainer恢复状态
       - 测试多个并发代理状态存储（响应STMG-03）

    注意：确保代码注释使用中文（遵循CLAUDE.md规范）
  </action>
  <verify>
    <automated>xcodebuild test -scheme VibeIsland -destination 'platform=macOS' -only-testing:VibeIslandTests/StateManagerTests</automated>
  </verify>
  <done>
    - AgentState和AgentStatus模型定义完成并可通过Codable序列化
    - StateManager能够存储、检索和持久化多个代理状态
    - SharedContainer提供App Groups共享容器访问
    - 所有单元测试通过，包括多代理状态存储测试
    - 代码注释使用中文
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: 实现套接字监控和JSON消息解析</name>
  <files>
    VibeIsland/Networking/SocketMonitor.swift
    VibeIslandTests/SocketMonitorTests.swift
  </files>
  <behavior>
    - SocketMonitor连接到Claude Code本地套接字
    - SocketMonitor解析JSON消息（格式：{"agent_id": "...", "status": "...", "terminal": "...", "timestamp": "..."}）
    - SocketMonitor实现指数退避重连策略（1s起始，30s最大，倍增）
    - SocketMonitor每30s发送心跳检测
    - SocketMonitor在收到消息后调用回调函数传递AgentState
    - SocketMonitor处理连接错误和重连逻辑
  </behavior>
  <action>
    1. 创建VibeIsland/Networking/SocketMonitor.swift：
       - 定义SocketMonitor类（遵循ObservableObject或使用回调）
       - 定义套接字配置：localhost, 默认端口（从配置读取）
       - 实现连接方法start()：
         - 使用Network framework的NWConnection创建连接
         - 实现指数退避重连策略（起始1s，最大30s，倍增）
         - 连接失败后延迟重试
         - 使用async/await避免阻塞主线程
       - 实现数据接收循环：
         - 接收数据流
         - 解析JSON消息（处理格式错误和部分消息）
         - 创建AgentState实例
         - 通过回调或发布事件传递AgentState
       - 实现心跳机制：
         - 每30s发送心跳消息
         - 检测连接超时
         - 无响应时触发重连
       - 实现停止方法stop()：
         - 取消连接
         - 停止心跳定时器
       - 实现错误处理：
         - 记录连接错误
         - 优雅处理网络中断
         - 重连时不清除现有状态

    2. 创建VibeIslandTests/SocketMonitorTests.swift：
       - 使用模拟套接字测试JSON消息解析
       - 测试有效JSON消息正确解析为AgentState
       - 测试无效JSON消息错误处理
       - 测试部分消息缓冲处理
       - 测试多个并发消息处理
       - 测试重连策略（指数退避）

    3. 集成SocketMonitor和StateManager：
       - 在主应用中创建SocketMonitor实例
       - 将StateManager注册为SocketMonitor的消息回调
       - 在收到消息时调用StateManager.updateAgentState(_ agent: AgentState)

    注意：确保代码注释使用中文（遵循CLAUDE.md规范）
  </action>
  <verify>
    <automated>xcodebuild test -scheme VibeIsland -destination 'platform=macOS' -only-testing:VibeIslandTests/SocketMonitorTests</automated>
  </verify>
  <done>
    - SocketMonitor成功连接到本地套接字
    - SocketMonitor正确解析JSON消息并创建AgentState
    - SocketMonitor实现指数退避重连策略
    - SocketMonitor每30s发送心跳检测
    - SocketMonitor在连接错误时自动重连
    - SocketMonitor与StateManager集成，消息正确传递
    - 所有单元测试通过
    - 代码注释使用中文
  </done>
</task>

</tasks>

<verification>
## 整体验证

### 自动化验证
1. 运行所有单元测试：`xcodebuild test -scheme VibeIsland -destination 'platform=macOS'`
2. 验证App Groups配置：检查两个目标使用相同的App Group标识符
3. 验证数据持久化：
   - 主应用写入测试数据到SharedContainer
   - 终止应用
   - 重新启动应用
   - 验证数据正确加载

### 手动验证（需要用户配置）
1. 启动Claude Code CLI，配置为监听本地套接字
2. 启动Vibe Island应用
3. 在Claude Code中创建代理并更新状态
4. 验证应用正确接收和存储状态
5. 终止Vibe Island应用
6. 重新启动应用
7. 验证代理状态持久化成功

### 功能验证
- [ ] 应用通过本地套接字连接到Claude Code（响应AGNT-01）
- [ ] 应用正确解析代理状态：in_progress、complete、awaiting_approval（响应AGNT-02）
- [ ] 应用检测并存储多个并发代理状态（响应STMG-03）
- [ ] 代理状态在应用终止和重新启动后持久化（响应STMG-02）
- [ ] 共享容器可被主应用和widget扩展访问

### 集成验证
- [ ] SocketMonitor → StateManager数据流正常
- [ ] StateManager → SharedContainer持久化正常
- [ ] SharedContainer在两个目标间共享数据正常

## 风险和缓解措施

| 风险 | 缓解措施 |
|------|----------|
| App Groups配置错误 | 在任务1中提供配置指南，实现优雅降级，在日志中显示警告 |
| Claude Code套接字不可用 | 在任务2中实现重连策略，记录连接状态，提供用户反馈 |
| JSON解析失败 | 在任务2中实现错误处理，记录错误消息，忽略无效消息 |
| 状态持久化失败 | 在任务1中测试持久化流程，在错误时记录详细日志 |
| 内存泄漏 | 使用 Instruments 分析长时间运行场景，确保正确关闭套接字连接 |

</verification>

<success_criteria>
## 完成标准

### 功能完成
- [ ] AgentState数据模型定义完成并可在主应用和widget扩展间共享
- [ ] StateManager实现完整的CRUD操作（创建、读取、更新）
- [ ] StateManager实现状态持久化到App Groups共享容器
- [ ] StateManager在应用启动时从共享容器恢复状态
- [ ] SharedContainer提供可靠的共享容器访问接口
- [ ] SocketMonitor实现本地套接字连接
- [ ] SocketMonitor实现JSON消息解析
- [ ] SocketMonitor实现指数退避重连策略
- [ ] SocketMonitor实现心跳机制（30s间隔）
- [ ] SocketMonitor与StateManager集成

### 测试完成
- [ ] StateManager所有单元测试通过
- [ ] SocketMonitor所有单元测试通过
- [ ] 多代理状态存储测试通过
- [ ] 状态持久化测试通过
- [ ] JSON消息解析测试通过（包括有效和无效消息）
- [ ] 重连策略测试通过

### 文档完成
- [ ] 代码注释使用中文
- [ ] App Groups配置指南提供
- [ ] Claude Code套接字配置指南提供

### 质量标准
- [ ] 所有代码遵循Swift编码规范
- [ ] 所有公共接口有文档注释
- [ ] 错误处理完善且有日志记录
- [ ] 无编译警告
- [ ] 无内存泄漏（通过Instruments验证）

### 需求覆盖
- [ ] AGNT-01: 应用通过本地套接字连接到Claude Code
- [ ] AGNT-02: 应用解析代理状态：in_progress、complete、awaiting_approval
- [ ] STMG-02: 代理状态在应用后台和终止后持久化
- [ ] STMG-03: 多个活跃的Claude代理在一个动态岛视图中显示

</success_criteria>

<output>
完成阶段后，创建`.planning/phases/01-data-layer-foundation/01-data-layer-foundation-01-SUMMARY.md`，包含：
- 实现的组件列表（数据模型、状态管理器、套接字监控器、共享容器）
- 测试结果摘要
- 遇到的挑战和解决方案
- 与需求的映射（AGNT-01, AGNT-02, STMG-02, STMG-03）
- 下一阶段的依赖项（widget扩展需要访问共享容器）
</output>