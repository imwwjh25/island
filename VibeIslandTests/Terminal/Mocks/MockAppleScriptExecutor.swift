//
//  MockAppleScriptExecutor.swift
//  VibeIslandTests
//
//  模拟 AppleScript 执行器
//

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