//
//  SoundManager.swift
//  VibeIsland
//
//  音效播放管理
//

import Foundation
import AVFoundation
import Combine

/// 音效类型
enum SoundType: String {
    /// 开始/进行中
    case inProgress = "start"
    /// 等待审批
    case awaitingApproval = "awaiting"
    /// 完成
    case complete = "complete"
}

/// 音效管理器
/// 负责播放状态变化音效和检测系统静音状态
class SoundManager {

    // MARK: - 单例

    /// 共享实例
    static let shared = SoundManager()

    // MARK: - 常量

    /// 音效文件扩展名
    private let soundFileExtension = "wav"

    /// UserDefaults 音效开关键
    private let soundEnabledKey = "soundEnabled"

    // MARK: - 属性

    /// 音频播放器字典（按类型存储）
    private var audioPlayers: [SoundType: AVAudioPlayer] = [:]

    /// 音效是否启用
    @Published var isSoundEnabled: Bool = true

    /// 音效文件是否已加载
    private var soundFilesLoaded = false

    /// 上次播放时间（用于频率限制）
    private var lastPlayTime: Date?

    /// 最小播放间隔（秒）
    private let minPlayInterval: TimeInterval = 0.1

    // MARK: - 初始化

    private init() {
        // 从 UserDefaults 加载音效设置
        loadSoundEnabledSetting()

        // 加载音效文件
        loadSoundFiles()
    }

    // MARK: - 音效播放

    /// 播放状态变化音效（通用方法，保持向后兼容）
    func playStateChangeSound() {
        // 默认播放进行中音效
        playSound(for: .inProgress)
    }

    /// 播放指定类型的音效
    /// - Parameter type: 音效类型
    func playSound(for type: SoundType) {
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
        guard soundFilesLoaded, let player = audioPlayers[type] else {
            // 如果指定类型的音效未加载，尝试使用备用音效
            if let fallbackPlayer = audioPlayers[.inProgress] {
                fallbackPlayer.currentTime = 0
                do {
                    try fallbackPlayer.play()
                    lastPlayTime = Date()
                    print("🔊 播放备用音效（类型：\(type.rawValue)）")
                } catch {
                    print("⚠️ 播放备用音效失败: \(error.localizedDescription)")
                }
            }
            return
        }

        // 重置到开头
        player.currentTime = 0

        // 播放音效
        do {
            try player.play()
            lastPlayTime = Date()
            print("🔊 播放音效（类型：\(type.rawValue)）")
        } catch {
            print("⚠️ 播放音效失败: \(error.localizedDescription)")
        }
    }

    /// 根据代理状态播放对应音效
    /// - Parameter status: 代理状态
    func playStateChangeSound(for status: AgentStatus) {
        let soundType: SoundType
        switch status {
        case .inProgress:
            soundType = .inProgress
        case .awaitingApproval:
            soundType = .awaitingApproval
        case .complete:
            soundType = .complete
        }
        playSound(for: soundType)
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

    /// 加载所有音效文件
    private func loadSoundFiles() {
        var loadedCount = 0

        for type in [SoundType.inProgress, SoundType.awaitingApproval, SoundType.complete] {
            if let soundURL = Bundle.main.url(forResource: type.rawValue, withExtension: soundFileExtension) {
                do {
                    let player = try AVAudioPlayer(contentsOf: soundURL)
                    player.prepareToPlay()
                    audioPlayers[type] = player
                    loadedCount += 1
                    print("✅ 音效文件已加载: \(type.rawValue).\(soundFileExtension)")
                } catch {
                    print("⚠️ 加载音效文件失败: \(type.rawValue) - \(error.localizedDescription)")
                }
            } else {
                print("⚠️ 音效文件未找到: \(type.rawValue).\(soundFileExtension)")
            }
        }

        soundFilesLoaded = loadedCount > 0

        // 如果没有加载任何音效，尝试加载旧的 aiff 文件作为备用
        if !soundFilesLoaded {
            if let fallbackURL = Bundle.main.url(forResource: "state_update", withExtension: "aiff") {
                do {
                    let player = try AVAudioPlayer(contentsOf: fallbackURL)
                    player.prepareToPlay()
                    audioPlayers[.inProgress] = player
                    soundFilesLoaded = true
                    print("✅ 使用备用音效文件: state_update.aiff")
                } catch {
                    print("❌ 加载备用音效文件失败: \(error.localizedDescription)")
                }
            }
        }
    }

    /// 重新加载音效文件（用于测试）
    func reloadSoundFiles() {
        audioPlayers.removeAll()
        loadSoundFiles()
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