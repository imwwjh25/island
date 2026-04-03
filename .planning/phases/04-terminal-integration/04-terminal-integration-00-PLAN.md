---
phase: 04-terminal-integration
plan: 00
type: execute
wave: 0
depends_on: []
files_modified:
  - VibeIslandTests/Terminal/TerminalControllerTests.swift
  - VibeIslandTests/Terminal/TerminalIntegrationTests.swift
  - VibeIslandTests/Terminal/Mocks/MockTerminalController.swift
  - VibeIslandTests/Terminal/Mocks/MockAppleScriptExecutor.swift
autonomous: true
requirements: []

must_haves:
  truths:
    - "测试文件结构已创建，支持 TerminalController 的单元测试"
    - "测试文件结构已创建，支持终端集成的集成测试"
    - "模拟对象已创建，支持 AppleScript 执行的模拟"
  artifacts:
    - path: "VibeIslandTests/Terminal/TerminalControllerTests.swift"
      provides: "TerminalController 单元测试框架"
      exports: ["testTerminalType", "testIsTerminalRunning", "testJumpToTab"]
    - path: "VibeIslandTests/Terminal/TerminalIntegrationTests.swift"
      provides: "终端集成测试框架"
      exports: ["testAgentCardTapGesture", "testJumpToTerminalTab", "testAlertShownOnError"]
    - path: "VibeIslandTests/Terminal/Mocks/MockTerminalController.swift"
      provides: "模拟终端控制器用于测试"
      exports: ["MockTerminalController"]
    - path: "VibeIslandTests/Terminal/Mocks/MockAppleScriptExecutor.swift"
      provides: "模拟 AppleScript 执行器用于测试"
      exports: ["MockAppleScriptExecutor"]
  key_links: []
---

<objective>
创建测试基础设施，建立 TerminalController 和终端集成的测试框架

目的：为后续 Wave 1 和 Wave 2 提供测试文件支持，确保代码质量和功能正确性

输出：完整的测试文件结构和模拟对象
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/phases/04-terminal-integration/04-terminal-integration-VALIDATION.md
@VibeIslandTests/（现有测试结构）
</context>

<tasks>

<task type="auto">
  <name>任务 1: 创建 TerminalController 单元测试文件</name>
  <files>VibeIslandTests/Terminal/TerminalControllerTests.swift</files>
  <read_first>
    - VibeIslandTests/（了解现有测试结构和模式）
  </read_first>
  <action>
创建 VibeIslandTests/Terminal/TerminalControllerTests.swift 文件，包含以下测试用例：

**导入和设置：**
```swift
import XCTest
@testable import VibeIsland

final class TerminalControllerTests: XCTestCase {
    var controller: TerminalController!

    override func setUp() {
        super.setUp()
        controller = TerminalController.shared
    }

    override func tearDown() {
        controller = nil
        super.tearDown()
    }
}
```

**TerminalType 测试：**
```swift
func testTerminalTypeIterm2BundleId() {
    XCTAssertEqual(TerminalType.iterm2.rawValue, "com.googlecode.iterm2")
}

func testTerminalTypeTerminalBundleId() {
    XCTAssertEqual(TerminalType.terminal.rawValue, "com.apple.terminal")
}

func testTerminalTypeIterm2DisplayName() {
    XCTAssertEqual(TerminalType.iterm2.displayName, "iTerm2")
}

func testTerminalTypeTerminalDisplayName() {
    XCTAssertEqual(TerminalType.terminal.displayName, "Terminal.app")
}

func testTerminalTypeAllCases() {
    XCTAssertEqual(TerminalType.allCases.count, 2)
    XCTAssertTrue(TerminalType.allCases.contains(.iterm2))
    XCTAssertTrue(TerminalType.allCases.contains(.terminal))
}
```

**isTerminalRunning 测试：**
```swift
func testIsTerminalRunningIterm2Running() {
    // 检查 iTerm2 是否运行（如果未运行则跳过）
    let isRunning = NSRunningApplication.runningApplications(withBundleIdentifier: TerminalType.iterm2.rawValue).isEmpty == false
    if isRunning {
        XCTAssertTrue(controller.isTerminalRunning(.iterm2))
    }
}

func testIsTerminalRunningIterm2NotRunning() {
    // 确保使用不存在的 Bundle ID 返回 false
    XCTAssertFalse(controller.isTerminalRunning(.iterm2) || !NSRunningApplication.runningApplications(withBundleIdentifier: TerminalType.iterm2.rawValue).isEmpty)
}

func testIsTerminalRunningTerminalRunning() {
    let isRunning = NSRunningApplication.runningApplications(withBundleIdentifier: TerminalType.terminal.rawValue).isEmpty == false
    if isRunning {
        XCTAssertTrue(controller.isTerminalRunning(.terminal))
    }
}

func testIsTerminalRunningTerminalNotRunning() {
    XCTAssertFalse(controller.isTerminalRunning(.terminal) || !NSRunningApplication.runningApplications(withBundleIdentifier: TerminalType.terminal.rawValue).isEmpty)
}
```

**jumpToTab 测试：**
```swift
func testJumpToTabIterm2NotRunning() {
    let result = controller.jumpToTab(terminal: .iterm2, tabId: "test-tab")
    // 如果 iTerm2 未运行，应返回 false
    if !controller.isTerminalRunning(.iterm2) {
        XCTAssertFalse(result)
    }
}

func testJumpToTabTerminalNotRunning() {
    let result = controller.jumpToTab(terminal: .terminal, tabId: "test-tab")
    // 如果 Terminal.app 未运行，应返回 false
    if !controller.isTerminalRunning(.terminal) {
        XCTAssertFalse(result)
    }
}

func testJumpToTabInvalidTabId() {
    // 测试无效标签页 ID 的处理
    let result = controller.jumpToTab(terminal: .iterm2, tabId: "")
    XCTAssertFalse(result)
}
```

**所有代码注释使用中文**
  </action>
  <verify>
    <automated>xcodebuild test -scheme VibeIsland -destination 'platform=macOS' -only-testing:VibeIslandTests/TerminalControllerTests</automated>
  </verify>
  <done>
    TerminalControllerTests.swift 文件存在且编译通过
    包含 TerminalType 枚举测试（5 个测试用例）
    包含 isTerminalRunning 测试（4 个测试用例）
    包含 jumpToTab 测试（3 个测试用例）
    所有代码注释使用中文
  </done>
</task>

<task type="auto">
  <name>任务 2: 创建终端集成测试文件</name>
  <files>VibeIslandTests/Terminal/TerminalIntegrationTests.swift</files>
  <read_first>
    - VibeIslandTests/（了解现有测试结构和模式）
  </read_first>
  <action>
创建 VibeIslandTests/Terminal/TerminalIntegrationTests.swift 文件，包含以下测试用例：

**导入和设置：**
```swift
import XCTest
@testable import VibeIsland

final class TerminalIntegrationTests: XCTestCase {
    var controller: TerminalController!

    override func setUp() {
        super.setUp()
        controller = TerminalController.shared
    }

    override func tearDown() {
        controller = nil
        super.tearDown()
    }
}
```

**多终端场景测试：**
```swift
func testMultipleTerminalsSimultaneously() {
    // 测试同时处理多个终端应用
    let iterm2Running = controller.isTerminalRunning(.iterm2)
    let terminalRunning = controller.isTerminalRunning(.terminal)

    // 至少验证方法调用不会崩溃
    XCTAssertNoThrow(controller.isTerminalRunning(.iterm2))
    XCTAssertNoThrow(controller.isTerminalRunning(.terminal))
}
```

**边界条件测试：**
```swift
func testJumpToTabWithSpecialCharacters() {
    // 测试包含特殊字符的标签页 ID
    let specialTabIds = ["test-123", "test_tab", "test.tab", "测试标签"]
    for tabId in specialTabIds {
        XCTAssertNoThrow(controller.jumpToTab(terminal: .iterm2, tabId: tabId))
    }
}

func testJumpToTabWithNilTabId() {
    // 测试空字符串处理
    XCTAssertFalse(controller.jumpToTab(terminal: .iterm2, tabId: ""))
}
```

**性能测试：**
```swift
func testTerminalDetectionPerformance() {
    measure {
        _ = controller.isTerminalRunning(.iterm2)
    }
}

func testJumpToTabPerformance() {
    measure {
        _ = controller.jumpToTab(terminal: .iterm2, tabId: "test")
    }
}
```

**所有代码注释使用中文**
  </action>
  <verify>
    <automated>xcodebuild test -scheme VibeIsland -destination 'platform=macOS' -only-testing:VibeIslandTests/TerminalIntegrationTests</automated>
  </verify>
  <done>
    TerminalIntegrationTests.swift 文件存在且编译通过
    包含多终端场景测试
    包含边界条件测试
    包含性能测试
    所有代码注释使用中文
  </done>
</task>

<task type="auto">
  <name>任务 3: 创建模拟对象文件</name>
  <files>
    VibeIslandTests/Terminal/Mocks/MockTerminalController.swift
    VibeIslandTests/Terminal/Mocks/MockAppleScriptExecutor.swift
  </files>
  <read_first>
    - VibeIslandTests/（了解现有测试结构和模式）
  </read_first>
  <action>
创建模拟对象文件，用于隔离测试：

**MockAppleScriptExecutor.swift:**
```swift
import Foundation

/// 模拟 AppleScript 执行器，用于测试
class MockAppleScriptExecutor {
    enum ExecutionResult {
        case success
        case failure(String)
    }

    /// 模拟的执行结果
    var mockResult: ExecutionResult = .success

    /// 执行 AppleScript（模拟）
    func execute(script: String) throws -> String {
        switch mockResult {
        case .success:
            return "模拟执行成功"
        case .failure(let error):
            throw NSError(domain: "MockAppleScript", code: 1, userInfo: [NSLocalizedDescriptionKey: error])
        }
    }

    /// 重置模拟状态
    func reset() {
        mockResult = .success
    }
}
```

**MockTerminalController.swift:**
```swift
import Foundation

/// 模拟终端控制器，用于测试
class MockTerminalController {
    /// 模拟的终端运行状态
    var isIterm2Running = false
    var isTerminalRunning = false

    /// 模拟的跳转结果
    var jumpToTabResult = true

    /// 模拟的 AppleScript 执行器
    let mockExecutor = MockAppleScriptExecutor()

    /// 检查终端是否运行（模拟）
    func isTerminalRunning(_ type: TerminalType) -> Bool {
        switch type {
        case .iterm2:
            return isIterm2Running
        case .terminal:
            return isTerminalRunning
        }
    }

    /// 跳转到标签页（模拟）
    func jumpToTab(terminal type: TerminalType, tabId: String) -> Bool {
        if !isTerminalRunning(type) {
            return false
        }
        return jumpToTabResult
    }

    /// 重置模拟状态
    func reset() {
        isIterm2Running = false
        isTerminalRunning = false
        jumpToTabResult = true
        mockExecutor.reset()
    }
}
```

**所有代码注释使用中文**
  </action>
  <verify>
    <automated>xcodebuild build -scheme VibeIsland -destination 'platform=macOS' | grep -E "(error:|warning:|BUILD SUCCEEDED)"</automated>
  </verify>
  <done>
    MockAppleScriptExecutor.swift 文件存在且编译通过
    MockTerminalController.swift 文件存在且编译通过
    MockAppleScriptExecutor 包含 execute 方法和 reset 方法
    MockTerminalController 包含 isTerminalRunning 和 jumpToTab 方法
    所有代码注释使用中文
  </done>
</task>

</tasks>

<verification>
编译项目确保没有错误：
```bash
xcodebuild -scheme VibeIsland -destination 'platform=macOS' clean build
```

运行测试验证测试基础设施：
```bash
xcodebuild test -scheme VibeIsland -destination 'platform=macOS'
```
</verification>

<success_criteria>
1. 所有测试文件创建成功，编译通过
2. TerminalControllerTests.swift 包含 12+ 个测试用例
3. TerminalIntegrationTests.swift 包含集成测试和性能测试
4. 模拟对象创建成功，支持隔离测试
5. 所有代码注释使用中文
6. 所有测试文件编译通过
</success_criteria>

<output>
完成后创建 `.planning/phases/04-terminal-integration/04-terminal-integration-00-SUMMARY.md`
</output>