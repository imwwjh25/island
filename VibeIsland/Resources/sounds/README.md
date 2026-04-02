# 音效文件说明

## 需要的文件

请在 `VibeIsland/Resources/sounds/` 目录下放置以下音效文件：

- `state_update.aiff` - 8-bit风格状态变化音效

## 音效规格

- 格式：AIFF 或 WAV
- 时长：0.5秒以内（短促音效）
- 风格：Classic NES / 8-bit 像素游戏音效
- 音量：适中（不要过大或过小）

## 推荐音效类型

可以使用以下类型的8-bit音效：

1. 简短的"叮"声（coin pickup）
2. 状态更新提示音
3. 任务完成音效
4. 任何具有复古游戏感觉的短音效

## 如何获取音效

1. 使用音频编辑软件（如Audacity）创建
2. 从免费的8-bit音效库下载
3. 使用AI工具生成8-bit风格音效

## 音效文件示例位置

`VibeIsland/Resources/sounds/state_update.aiff`

## 集成步骤

1. 将音效文件拖拽到 Xcode 项目中
2. 确保添加到 "Copy Bundle Resources" 构建阶段
3. 验证文件名为 `state_update.aiff`

## 测试

在运行应用之前，确保音效文件已正确添加到项目bundle中。