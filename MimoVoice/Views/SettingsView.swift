import SwiftUI

@available(iOS 16.0, *)
struct SettingsView: View {
    @AppStorage("apiKey") private var apiKey = ""
    @AppStorage("baseURL") private var baseURL = "https://token-plan-sgp.xiaomimimo.com/v1"
    @AppStorage("whisperKey") private var whisperKey = ""
    
    @State private var showKey = false
    @State private var showWhisperKey = false
    @State private var testResult = ""
    @State private var isTesting = false
    
    let regions = [
        ("中国", "https://token-plan-cn.xiaomimimo.com/v1"),
        ("新加坡", "https://token-plan-sgp.xiaomimimo.com/v1"),
        ("欧洲", "https://token-plan-ams.xiaomimimo.com/v1"),
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("MiMo API Key").fontWeight(.medium)
                        Spacer()
                        if showKey {
                            TextField("tp-xxxxx", text: $apiKey)
                                .textContentType(.password)
                                .multilineTextAlignment(.trailing)
                        } else {
                            SecureField("tp-xxxxx", text: $apiKey)
                                .textContentType(.password)
                                .multilineTextAlignment(.trailing)
                        }
                        Button {
                            showKey.toggle()
                        } label: {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Picker("节点区域", selection: $baseURL) {
                        ForEach(regions, id: \.1) { name, url in
                            Text(name).tag(url)
                        }
                    }
                } header: {
                    Text("MiMo Token Plan")
                } footer: {
                    Text("在 token-plan 管理页面获取 API Key，格式为 tp-xxxxx")
                }
                
                Section {
                    HStack {
                        Text("Whisper Key").fontWeight(.medium)
                        Spacer()
                        if showWhisperKey {
                            TextField("sk-xxxxx", text: $whisperKey)
                                .textContentType(.password)
                                .multilineTextAlignment(.trailing)
                        } else {
                            SecureField("sk-xxxxx (可选)", text: $whisperKey)
                                .textContentType(.password)
                                .multilineTextAlignment(.trailing)
                        }
                        Button {
                            showWhisperKey.toggle()
                        } label: {
                            Image(systemName: showWhisperKey ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                } header: {
                    Text("语音识别 (ASR)")
                } footer: {
                    Text("用于录音转文字功能，需要 OpenAI API Key。不填写则无法使用录音转文字。")
                }
                
                Section {
                    Button {
                        Task { await testConnection() }
                    } label: {
                        HStack {
                            if isTesting {
                                ProgressView()
                            }
                            Text(isTesting ? "测试中..." : "测试连接")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(apiKey.isEmpty || isTesting)
                    
                    if !testResult.isEmpty {
                        Text(testResult)
                            .font(.caption)
                            .foregroundColor(testResult.contains("✅") ? .green : .red)
                    }
                }
                
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
                    }
                    HStack {
                        Text("TTS 模型")
                        Spacer()
                        Text("mimo-v2.5-tts").foregroundColor(.secondary)
                    }
                    HStack {
                        Text("费用")
                        Spacer()
                        Text("限时免费 🎉").foregroundColor(.green)
                    }
                }
            }
            .onTapGesture { hideKeyboard() }
            .navigationTitle("设置")
        }
    }
    
    private func testConnection() async {
        isTesting = true
        testResult = ""
        
        do {
            _ = try await MiMoAPIService.shared.synthesize(
                text: "测试",
                stylePrompt: "用普通语气说"
            )
            testResult = "✅ 连接成功！API Key 有效"
        } catch {
            testResult = "❌ \(error.localizedDescription)"
        }
        
        isTesting = false
    }
}
