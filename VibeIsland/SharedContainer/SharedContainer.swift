//
//  SharedContainer.swift
//  VibeIsland
//
//  App Groups 共享容器访问
//

import Foundation

/// 共享容器访问类
/// 提供主应用和 widget 扩展之间的数据共享
class SharedContainer {

    // MARK: - 常量

    /// App Group 标识符
    /// 默认值，生产环境应从配置或环境变量读取
    static let appGroupIdentifier = "group.com.vibeisland.shared"

    // MARK: - 共享 UserDefaults

    /// 共享 UserDefaults 实例
    /// 如果 App Groups 未配置，返回标准 UserDefaults（仅用于调试）
    static var sharedUserDefaults: UserDefaults? {
        // 首先尝试 App Groups
        if let userDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            #if DEBUG
            let testKey = "vibeisland_test_key"
            userDefaults.set("test", forKey: testKey)
            if userDefaults.string(forKey: testKey) == "test" {
                userDefaults.removeObject(forKey: testKey)
                return userDefaults
            }
            #else
            return userDefaults
            #endif
        }

        // 降级到标准 UserDefaults（调试模式）
        #if DEBUG
        print("⚠️ App Groups 不可用，使用标准 UserDefaults（仅调试）")
        return UserDefaults.standard
        #else
        print("⚠️ 无法初始化共享 UserDefaults，请检查 App Groups 配置")
        return nil
        #endif
    }

    // MARK: - 数据存储键

    /// 代理状态数据键
    static let agentStatesKey = "agent_states"

    /// 代理顺序数据键
    static let agentOrderKey = "agent_order"

    // MARK: - 代理状态持久化

    /// 保存代理状态到共享容器
    /// - Parameter states: 代理状态字典
    static func saveAgentStates(_ states: [String: AgentState]) {
        guard let sharedDefaults = sharedUserDefaults else {
            print("⚠️ 无法保存代理状态：共享容器不可用")
            return
        }

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(states)
            sharedDefaults.set(data, forKey: agentStatesKey)
            sharedDefaults.synchronize()
        } catch {
            print("❌ 保存代理状态失败: \(error)")
        }
    }

    /// 从共享容器加载代理状态
    /// - Returns: 代理状态字典
    static func loadAgentStates() -> [String: AgentState] {
        guard let sharedDefaults = sharedUserDefaults else {
            print("⚠️ 无法加载代理状态：共享容器不可用")
            return [:]
        }

        guard let data = sharedDefaults.data(forKey: agentStatesKey) else {
            return [:]
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode([String: AgentState].self, from: data)
        } catch {
            print("❌ 加载代理状态失败: \(error)")
            return [:]
        }
    }

    /// 保存代理顺序到共享容器
    /// - Parameter order: 代理 ID 数组
    static func saveAgentOrder(_ order: [String]) {
        guard let sharedDefaults = sharedUserDefaults else {
            print("⚠️ 无法保存代理顺序：共享容器不可用")
            return
        }

        sharedDefaults.set(order, forKey: agentOrderKey)
        sharedDefaults.synchronize()
    }

    /// 从共享容器加载代理顺序
    /// - Returns: 代理 ID 数组
    static func loadAgentOrder() -> [String] {
        guard let sharedDefaults = sharedUserDefaults else {
            print("⚠️ 无法加载代理顺序：共享容器不可用")
            return []
        }

        return sharedDefaults.stringArray(forKey: agentOrderKey) ?? []
    }

    // MARK: - 清除数据

    /// 清除所有代理状态
    static func clearAgentStates() {
        guard let sharedDefaults = sharedUserDefaults else {
            print("⚠️ 无法清除代理状态：共享容器不可用")
            return
        }

        sharedDefaults.removeObject(forKey: agentStatesKey)
        sharedDefaults.removeObject(forKey: agentOrderKey)
        sharedDefaults.synchronize()
    }
}