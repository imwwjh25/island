//
//  PermissionPromptView.swift
//  VibeIsland
//
//  Accessibility 权限提示视图
//

import SwiftUI

/// Accessibility 权限提示视图
/// 当权限未授权时显示引导用户授权的 UI
struct PermissionPromptView: View {

    // MARK: - 属性

    @ObservedObject var accessibilityManager = AccessibilityManager.shared

    // MARK: - Body

    var body: some View {
        if !accessibilityManager.hasPermission {
            VStack(spacing: 16) {
                // 警告图标
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 32))

                // 标题
                Text("需要 Accessibility 权限")
                    .font(.headline)

                // 说明文本
                Text("Vibe Island 需要监控终端窗口标题以检测 Claude Code 状态。")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                // 授权按钮
                Button("授权") {
                    accessibilityManager.checkPermission(promptUser: true)
                }
                .buttonStyle(.borderedProminent)

                // 打开系统设置按钮
                Button("打开系统设置") {
                    accessibilityManager.openAccessibilitySettings()
                }
                .buttonStyle(.bordered)

                // 设置路径提示
                Text("设置路径：系统设置 → 隐私与安全性 → 辅助功能")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(12)
            .shadow(radius: 4)
        }
    }
}

#Preview {
    PermissionPromptView()
        .previewLayout(.sizeThatFits)
        .padding()
}