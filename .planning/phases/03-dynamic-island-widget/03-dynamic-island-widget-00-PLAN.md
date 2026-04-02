---
phase: 03-dynamic-island-widget
plan: 00
type: execute
wave: 0
depends_on: []
files_modified:
  - VibeIslandTests/MenuBarManagerTests.swift
  - VibeIslandTests/CompactStatusViewTests.swift
  - VibeIslandTests/ExpandedDetailsViewTests.swift
  - VibeIslandTests/AccessibilityTests.swift
  - VibeIslandTests/VibeIslandMenuBarTests.swift
autonomous: false
requirements: []
user_setup: []

must_haves:
  truths:
    - "测试目标 VibeIslandTests 已创建"
    - "所有测试文件包含基础的测试存根"
    - "测试套件可以成功运行（即使测试数量为0）"
  artifacts:
    - path: "VibeIslandTests/MenuBarManagerTests.swift"
      provides: "MenuBarManager 单元测试"
      exports: ["MenuBarManagerTests", "testAutoExpandOnAwaitingApproval", "testAutoExpandOnComplete"]
    - path: "VibeIslandTests/CompactStatusViewTests.swift"
      provides: "CompactStatusView UI 测试"
      exports: ["CompactStatusViewTests"]
    - path: "VibeIslandTests/ExpandedDetailsViewTests.swift"
      provides: "ExpandedDetailsView UI 测试"
      exports: ["ExpandedDetailsViewTests"]
    - path: "VibeIslandTests/AccessibilityTests.swift"
      provides: "辅助功能测试"
      exports: ["AccessibilityTests"]
    - path: "VibeIslandTests/VibeIslandMenuBarTests.swift"
      provides: "MenuBarExtra 集成测试"
      exports: ["VibeIslandMenuBarTests"]
  key_links: []
---

<objective>
建立 Phase 3 的测试基础设施，创建所有必需的测试文件和测试存根，确保后续计划的验证测试可以正常运行。

Purpose: Nyquist 验证框架要求 Wave 0 建立测试基础设施。此计划创建测试文件骨架，后续计划的验证测试将引用这些文件中的具体测试方法。
Output: 完整的测试文件结构，所有测试存都已创建，测试套件可运行。
</objective>

<execution_context>
@/Users/Zhuanz/island/.claude/get-shit-done/workflows/execute-plan.md
@/Users/Zhuanz/island/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/03-dynamic-island-widget/03-dynamic-island-widget-VALIDATION.md
@.planning/phases/03-dynamic-island-widget/03-dynamic-island-widget-RESEARCH.md

@VibeIsland/Models/AgentState.swift
@VibeIsland/State/StateManager.swift
</context>

<tasks>

<task type="auto">
  <name>Task 1: 创建测试文件结构和基础测试存根</name>
  <files>VibeIslandTests/MenuBarManagerTests.swift, VibeIslandTests/CompactStatusViewTests.swift, VibeIslandTests/ExpandedDetailsViewTests.swift, VibeIslandTests/AccessibilityTests.swift, VibeIslandTests/VibeIslandMenuBarTests.swift</files>
  <read_first>
    - VibeIsland/Models/AgentState.swift（了解数据模型）
    - VibeIsland/State/StateManager.swift（了解状态管理 API）
    - .planning/phases/03-dynamic-island-widget/03-dynamic-island-widget-VALIDATION.md（了解验证要求）
  </read_first>
  <action>
    创建以下测试文件，每个文件包含基础的测试存根：

    ## VibeIslandTests/MenuBarManagerTests.swift
    ```swift
    import XCTest
    @testable import VibeIsland

    final class MenuBarManagerTests: XCTestCase {
        var manager: MenuBarManager!

        override func setUp() {
            super.setUp()
            manager = MenuBarManager()
        }

        override func tearDown() {
            manager = nil
            super.tearDown()
        }

        // MARK: - Auto Expand Tests

        func testAutoExpandOnAwaitingApproval() {
            // TODO: 实现测试
            // 验证当代理状态变为 awaiting_approval 时，自动展开逻辑被触发
        }

        func testAutoExpandOnComplete() {
            // TODO: 实现测试
            // 验证当代理状态变为 complete 时，自动展开逻辑被触发
        }

        func testAutoExpandFrequencyLimit() {
            // TODO: 实现测试
            // 验证自动展开有最小间隔限制
        }

        func testAutoExpandDisabled() {
            // TODO: 实现测试
            // 验证当 shouldAutoExpand = false 时，不触发自动展开
        }
    }
    ```

    ## VibeIslandTests/CompactStatusViewTests.swift
    ```swift
    import XCTest
    import SwiftUI
    @testable import VibeIsland

    final class CompactStatusViewTests: XCTestCase {
        var stateManager: StateManager!

        override func setUp() {
            super.setUp()
            stateManager = StateManager.shared
            stateManager.agentStates = []
        }

        override func tearDown() {
            stateManager.agentStates = []
            super.tearDown()
        }

        // MARK: - Compact View Tests

        func testCompactViewWithNoAgents() {
            // TODO: 实现测试
            // 验证无代理时显示正确图标
        }

        func testCompactViewWithActiveAgents() {
            // TODO: 实现测试
            // 验证有活跃代理时显示状态圆点和数量徽章
        }

        func testCompactViewStatusIndicatorColors() {
            // TODO: 实现测试
            // 验证不同状态显示正确颜色
        }

        func testCompactViewBadgeCount() {
            // TODO: 实现测试
            // 验证徽章数量正确
        }
    }
    ```

    ## VibeIslandTests/ExpandedDetailsViewTests.swift
    ```swift
    import XCTest
    import SwiftUI
    @testable import VibeIsland

    final class ExpandedDetailsViewTests: XCTestCase {
        var stateManager: StateManager!

        override func setUp() {
            super.setUp()
            stateManager = StateManager.shared
            stateManager.agentStates = []
        }

        override func tearDown() {
            stateManager.agentStates = []
            super.tearDown()
        }

        // MARK: - Expanded View Tests

        func testExpandedViewWithNoAgents() {
            // TODO: 实现测试
            // 验证空状态正确显示
        }

        func testExpandedViewWithAgents() {
            // TODO: 实现测试
            // 验证所有代理正确显示在列表中
        }

        func testExpandedViewScroll() {
            // TODO: 实现测试
            // 验证多个代理时滚动功能正常
        }

        func testExpandedViewAgentCardLayout() {
            // TODO: 实现测试
            // 验证代理卡片布局正确
        }
    }
    ```

    ## VibeIslandTests/AccessibilityTests.swift
    ```swift
    import XCTest
    import SwiftUI
    @testable import VibeIsland

    final class AccessibilityTests: XCTestCase {
        var stateManager: StateManager!

        override func setUp() {
            super.setUp()
            stateManager = StateManager.shared
        }

        override func tearDown() {
            super.tearDown()
        }

        // MARK: - VoiceOver Tests

        func testCompactViewVoiceOverLabel() {
            // TODO: 实现测试
            // 验证紧凑视图的 VoiceOver 标签正确
        }

        func testExpandedViewVoiceOverLabel() {
            // TODO: 实现测试
            // 验证展开视图的 VoiceOver 标签正确
        }

        func testAgentCardVoiceOverLabel() {
            // TODO: 实现测试
            // 验证代理卡片的 VoiceOver 标签正确
        }

        // MARK: - Reduced Motion Tests

        func testReducedMotion() {
            // TODO: 实现测试
            // 验证减少动画设置被正确尊重
        }

        // MARK: - Color Scheme Tests

        func testDarkMode() {
            // TODO: 实现测试
            // 验证深色模式下 UI 正确显示
        }

        func testLightMode() {
            // TODO: 实现测试
            // 验证浅色模式下 UI 正确显示
        }
    }
    ```

    ## VibeIslandTests/VibeIslandMenuBarTests.swift
    ```swift
    import XCTest
    import SwiftUI
    @testable import VibeIsland

    final class VibeIslandMenuBarTests: XCTestCase {
        var stateManager: StateManager!

        override func setUp() {
            super.setUp()
            stateManager = StateManager.shared
        }

        override func tearDown() {
            super.tearDown()
        }

        // MARK: - Integration Tests

        func testMenuBarExtraStructure() {
            // TODO: 实现测试
            // 验证 MenuBarExtra 结构正确
        }

        func testStateChangesUpdateUI() {
            // TODO: 实现测试
            // 验证状态变化时 UI 更新
        }

        func testPopoverExpandCollapse() {
            // TODO: 实现测试
            // 验证 popover 展开和折叠功能
        }
    }
    ```

    **重要**: 所有测试方法目前是 TODO 存根。在后续计划中，当实现相应功能时，这些测试将被填充。
  </action>
  <verify>
    <automated>xcodebuild test -scheme VibeIsland -destination 'platform=macOS'</automated>
  </verify>
  <done>
    - VibeIslandTests/MenuBarManagerTests.swift 文件存在且包含测试存根
    - VibeIslandTests/CompactStatusViewTests.swift 文件存在且包含测试存根
    - VibeIslandTests/ExpandedDetailsViewTests.swift 文件存在且包含测试存根
    - VibeIslandTests/AccessibilityTests.swift 文件存在且包含测试存根
    - VibeIslandTests/VibeIslandMenuBarTests.swift 文件存在且包含测试存根
    - 测试套件可以运行（即使测试数量为 0）
  </done>
</task>

</tasks>

<verification>
- [ ] 所有 5 个测试文件已创建
- [ ] 每个文件包含基础测试类和 setUp/tearDown
- [ ] 测试套件可以成功运行
- [ ] VALIDATION.md 中的 nyquist_compliant 设置为 true
- [ ] VALIDATION.md 中的 wave_0_complete 设置为 true
</verification>

<success_criteria>
测试基础设施已建立，后续计划的验证测试可以引用具体的测试方法和命令。
</success_criteria>

<output>
After completion, create `.planning/phases/03-dynamic-island-widget/03-dynamic-island-widget-00-SUMMARY.md`
</output>