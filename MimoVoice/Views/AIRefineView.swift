import SwiftUI

@available(iOS 16.0, *)
struct AIRefineView: View {
    @State private var inputText = ""
    @State private var selectedStyle: AIVoiceStyle = .sweet
    @State private var customPrompt = ""
    @State private var isLoading = false
    @State private var resultAudio: Data?
    @State private var errorMessage: String?
    @State private var showSuccess = false
    
    @StateObject private var audioService = AudioService()
    @StateObject private var recorder = AudioService()
    
    var stylePrompt: String {
        selectedStyle == .custom ? customPrompt : selectedStyle.prompt
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 文本输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("要合成的文字").font(.headline)
                        TextEditor(text: $inputText)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    // 音色选择
                    VStack(alignment: .leading, spacing: 8) {
                        Text("选择音色").font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                            ForEach(AIVoiceStyle.allCases) { style in
                                Button {
                                    selectedStyle = style
                                } label: {
                                    Text(style.rawValue)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(selectedStyle == style ? Color.purple : Color(.systemGray6))
                                        .foregroundColor(selectedStyle == style ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        
                        if selectedStyle == .custom {
                            TextEditor(text: $customPrompt)
                                .frame(height: 60)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    Text("描述你想要的声音风格...")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 12)
                                        .padding(.top, 16)
                                        .opacity(customPrompt.isEmpty ? 1 : 0)
                                )
                        }
                    }
                    
                    // 合成按钮
                    Button {
                        Task { await synthesize() }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.white)
                            }
                            Text(isLoading ? "合成中..." : "✨ 开始合成")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .disabled(inputText.isEmpty || isLoading)
                    
                    // 错误提示
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // 播放区
                    if let audio = resultAudio {
                        VStack(spacing: 12) {
                            Text("合成完成 ✅")
                                .font(.headline)
                                .foregroundColor(.green)
                            
                            HStack(spacing: 16) {
                                Button {
                                    try? audioService.play(data: audio)
                                } label: {
                                    Label(audioService.isPlaying ? "播放中..." : "播放", systemImage: audioService.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                        .font(.title3)
                                }
                                .disabled(audioService.isPlaying)
                                
                                Button {
                                    if audioService.saveToDocuments(data: audio, filename: "mimo_\(Date().timeIntervalSince1970).wav") != nil {
                                        showSuccess = true
                                    }
                                } label: {
                                    Label("保存", systemImage: "square.and.arrow.down")
                                        .font(.title3)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                }
                .padding()
            }
            .navigationTitle("AI 精修")
        }
    }
    
    private func synthesize() async {
        isLoading = true
        errorMessage = nil
        resultAudio = nil
        
        do {
            let audio = try await MiMoAPIService.shared.synthesize(
                text: inputText,
                stylePrompt: stylePrompt
            )
            await MainActor.run {
                resultAudio = audio
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
