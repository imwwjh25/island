# Phase 4 人工验证指南

**创建时间:** 2026-04-02
**验证文件:** 04-terminal-integration-HUMAN-UAT.md

## 前置准备

### 1. 构建应用
```bash
# 在项目根目录执行
cd /Users/Zhuanz/island

# 使用 Xcode 打开项目
open VibeIsland.xcodeproj

# 在 Xcode 中：
# 1. 选择 VibeIsland scheme
# 2. 选择 "My Mac" 作为目标设备
# 3. 点击 Run (⌘R) 或 Product > Run
```

### 2. 确保 Claude Code 运行
```bash
# 在终端中确认 Claude Code 正在运行
# 应用需要监控 Claude Code 的状态
```

---

## 测试清单

### ✅ 测试 1: iTerm2 标签页跳转

**步骤:**
1. 打开 iTerm2
2. 创建至少 3 个标签页 (⌘T)
3. 在其中一个标签页运行 Claude Code
4. 点击菜单栏的 Vibe Island 图标
5. 展开详细视图
6. 点击某个代理卡片

**预期结果:**
- [ ] iTerm2 应用激活（窗口前置）
- [ ] 自动切换到对应的标签页
- [ ] 标签页内容可见

**实际结果:**
