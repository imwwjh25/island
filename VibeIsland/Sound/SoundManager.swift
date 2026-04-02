//
//  SoundManager.swift
//  VibeIsland
//
//  音效播放管理
//

import Foundation
import AVFoundation
import Combine

/// 音效管理器
/// 负责播放状态变化音效和检测系统静音状态
class SoundManager {

    // MARK: - 单例

    /// 共享实例
    static let shared = SoundManager()

    // MARK: - 常量

    /// 音效文件名
    private let soundFileName = "state_update.aiff"

    /// UserDefaults 音效开关键
    private let soundEnabledKey = "soundEnabled"

    // MARK: - 属性

    /// 音频播放器
    private var audioPlayer: AVAudioPlayer?

    /// 音效是否启用
    @Published var isSoundEnabled: Bool = true

    /// 音效文件是否已加载
    private var soundFileLoaded = false

    /// 上次播放时间（用于频率限制）
    private var lastPlayTime: Date?

    /// 最小播放间隔（秒）
    private let minPlayInterval: TimeInterval = 0.1

    // MARK: - 初始化

    private init() {
        // 从 UserDefaults 加载音效设置
        loadSoundEnabledSetting()

        // 加载音效文件
        loadSoundFile()
    }

    // MARK: - 音效播放

    /// 播放状态变化音效
    func playStateChangeSound() {
        // 检查音效是否启用
        guard isSoundEnabled else {
            return
        }

        // 检查系统是否静音
        guard !isSystemMuted() else {
            return
        }

        // 检查频率限制
        if let lastTime = lastPlayTime {
            let timeSinceLastPlay = Date().timeIntervalSince(lastTime)
            guard timeSinceLastPlay >= minPlayInterval else {
                return
            }
        }

        // 检查音效文件是否已加载
        guard soundFileLoaded, let player = audioPlayer else {
            return
        }

        // 重置到开头
        player.currentTime = 0

        // 播放音效
        do {
            try player.play()
            lastPlayTime = Date()
            print("🔊 播放状态变化音效")
        } catch {
            print("⚠️ 播放音效失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 系统静音检测

    /// 检查系统是否静音
    /// - Returns: 是否静音
    func isSystemMuted() -> Bool {
        // macOS 上通过 AVAudioSession 检查音量
        // 注意：在 macOS 上，outputVolume 可能始终返回 1.0
        // 这里使用备用方法检测静音状态

        #if os(macOS)
        // macOS 备用方法：检查系统音量
        let volume = getSystemVolume()
        return volume < 0.01
        #else
        // iOS 方法
        return AVAudioSession.sharedInstance().outputVolume < 0.01
        #endif
    }

    /// 获取系统音量（macOS 备用方法）
    /// - Returns: 音量值 (0.0 - 1.0)
    private func getSystemVolume() -> Float {
        // 在 macOS 上，可以通过 AppleScript 获取系统音量
        // 这里返回默认值，实际应用中可以使用 NSAppleScript

        let script = "output volume of (get volume settings)"
        var error: NSDictionary?

        if let scriptObject = NSAppleScript(source: script) {
            let output = scriptObject.executeAndReturnError(&error)
            if let volumeString = output.stringValue,
               let volume = Float(volumeString.trimmingCharacters(in: .whitespaces)) {
                return volume / 100.0 // 转换为 0.0 - 1.0 范围
            }
        }

        // 如果获取失败，返回默认值（假设系统不是静音）
        return 0.5
    }

    // MARK: - 音效开关

    /// 切换音效开关
    func toggleSound() {
        isSoundEnabled.toggle()
        saveSoundEnabledSetting()

        print("🔇 音效已\(isSoundEnabled ? "启用" : "禁用")")
    }

    /// 设置音效开关
    /// - Parameter enabled: 是否启用
    func setSoundEnabled(_ enabled: Bool) {
        isSoundEnabled = enabled
        saveSoundEnabledSetting()

        print("🔇 音效已\(isSoundEnabled ? "启用" : "禁用")")
    }

    // MARK: - 音效文件加载

    /// 加载音效文件
    private func loadSoundFile() {
        guard let soundURL = Bundle.main.url(forResource: "state_update", withExtension: "aiff") else {
            print("⚠️ 音效文件未找到: \(soundFileName)")
            soundFileLoaded = false
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            soundFileLoaded = true
            print("✅ 音效文件已加载: \(soundFileName)")
        } catch {
            print("❌ 加载音效文件失败: \(error.localizedDescription)")
            soundFileLoaded = false
        }
    }

    /// 重新加载音效文件（用于测试）
    func reloadSoundFile() {
        loadSoundFile()
    }

    // MARK: - 持久化

    /// 加载音效设置
    private func loadSoundEnabledSetting() {
        let defaults = UserDefaults.standard
        isSoundEnabled = defaults.object(forKey: soundEnabledKey) as? Bool ?? true
    }

    /// 保存音效设置
    private func saveSoundEnabledSetting() {
        let defaults = UserDefaults.standard
        defaults.set(isSoundEnabled, forKey: soundEnabledKey)
        defaults.synchronize()
    }
}