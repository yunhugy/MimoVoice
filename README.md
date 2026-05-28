# MiMoVoice 🎙️

基于 Xiaomi MiMo TTS 的 iOS 变声 App

## 功能

| 功能 | 说明 | 费用 |
|------|------|------|
| ✨ AI 精修变声 | 输入文字 → 选择音色 → AI 语音合成 | 限时免费 |
| 🧬 声音克隆 | 上传/录制样本 → 用克隆音色说任意文字 | 限时免费 |
| 🎙️ 实时变声 | 麦克风实时 DSP 处理（花栗鼠/低沉/机器人等） | 纯本地 |
| 📝 录音转文字 | Whisper ASR 识别 | 需 OpenAI Key |

## 使用前准备

1. 前往 [MiMo 开放平台](https://platform.xiaomimimo.com/console/plan-manage) 获取 **Token Plan API Key**（`tp-xxxxx` 格式）
2. （可选）如需录音转文字，准备 [OpenAI API Key](https://platform.openai.com/api-keys)

## 快速开始

```bash
# 安装 XcodeGen
brew install xcodegen

# 生成 Xcode 项目
xcodegen generate

# 编译运行
open MimoVoice.xcodeproj
```

## GitHub Actions 自动构建

Push 到 main 分支后自动编译 IPA，下载链接在 Actions 页面。

## 技术栈

- SwiftUI + AVFoundation
- MiMo-V2.5-TTS API (OpenAI 兼容)
- 实时变声：AVAudioEngine + TimePitch

## License

MIT
