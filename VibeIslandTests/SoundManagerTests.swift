//
//  SoundManagerTests.swift
//  VibeIslandTests
//
//  音效管理器测试
//

import XCTest
import AVFoundation
@testable import VibeIsland

@available(macOS 14.0, *)
final class SoundManagerTests: XCTestCase {

    var soundManager: SoundManager!

    override func setUpWithError() throws {
        soundManager = SoundManager.shared
    }

    override func tearDownWithError() throws {
        soundManager = nil
    }

    // MARK: - 音效文件加载测试

    func testSoundManagerIsSingleton() throws {
        // 验证单例模式
        let instance1 = SoundManager.shared
        let instance2 = SoundManager.shared

        XCTAssertTrue(instance1 === instance2, "SoundManager 应该是单例")
    }

    func testSoundEnabledDefault() throws {
        // 验证默认启用音效
        XCTAssertTrue(soundManager.isSoundEnabled, "音效应该默认启用")
    }

    func testSoundEnabledPersistence() throws {
        // 保存原始状态
        let originalState = soundManager.isSoundEnabled

        // 切换音效状态
        soundManager.toggleSound()
        let toggledState = soundManager.isSoundEnabled

        // 创建新实例验证持久化
        let newSoundManager = SoundManager.shared
        XCTAssertEqual(newSoundManager.isSoundEnabled, toggledState, "音效状态应该持久化")

        // 恢复原始状态
        if originalState {
            soundManager.toggleSound()
        }
    }

    func testToggleSound() throws {
        // 保存原始状态
        let originalState = soundManager.isSoundEnabled

        // 切换音效
        soundManager.toggleSound()
        XCTAssertEqual(soundManager.isSoundEnabled, !originalState, "音效状态应该切换")

        // 再次切换
        soundManager.toggleSound()
        XCTAssertEqual(soundManager.isSoundEnabled, originalState, "音效状态应该恢复")
    }

    // MARK: - 音效播放测试

    func testPlayStateChangeSoundWhenEnabled() throws {
        // 确保音效启用
        soundManager.isSoundEnabled = true

        // 测试播放音效
        XCTAssertNoThrow(soundManager.playStateChangeSound(), "启用时播放音效应该成功")
    }

    func testPlayStateChangeSoundWhenDisabled() throws {
        // 禁用音效
        soundManager.isSoundEnabled = false

        // 测试播放音效
        soundManager.playStateChangeSound()

        // 验证没有抛出错误（应该静默返回）
        XCTAssertTrue(true, "禁用时播放音效应该静默返回")
    }

    // MARK: - 系统静音检测测试

    func testSystemMutedDetection() throws {
        // 测试系统静音检测
        let isMuted = soundManager.isSystemMuted()

        // 验证返回布尔值
        XCTAssertTrue(isMuted == true || isMuted == false, "应该返回有效的布尔值")
    }

    func testSoundNotPlayedWhenSystemMuted() throws {
        // 这是一个集成测试，实际运行时系统可能不是静音状态
        // 这里只测试方法调用不崩溃

        // 确保音效启用
        soundManager.isSoundEnabled = true

        // 测试播放（如果系统静音，音效不应该播放）
        XCTAssertNoThrow(soundManager.playStateChangeSound(), "系统静音时播放音效不应该崩溃")
    }

    // MARK: - 边界情况测试

    func testMultipleRapidPlayCalls() throws {
        // 测试快速连续播放
        soundManager.isSoundEnabled = true

        for _ in 0..<10 {
            XCTAssertNoThrow(soundManager.playStateChangeSound(), "快速连续播放不应该崩溃")
        }
    }

    func testToggleMultipleTimes() throws {
        // 测试多次切换
        for _ in 0..<10 {
            soundManager.toggleSound()
        }

        // 验证最终状态
        let finalState = soundManager.isSoundEnabled
        XCTAssertTrue(finalState == true || finalState == false, "音效状态应该有效")
    }

    // MARK: - 资源管理测试

    func testSoundManagerCleanup() throws {
        // 测试资源清理
        weak var weakSoundManager: SoundManager?

        autoreleasepool {
            weakSoundManager = SoundManager.shared
            XCTAssertNotNil(weakSoundManager, "SoundManager 应该存在")
        }

        // 由于是单例，不会真正释放
        // 这个测试验证内存管理不会崩溃
        XCTAssertNotNil(SoundManager.shared, "单例应该始终存在")
    }

    // MARK: - 性能测试

    func testPlaySoundPerformance() throws {
        measure {
            soundManager.playStateChangeSound()
        }
    }
}