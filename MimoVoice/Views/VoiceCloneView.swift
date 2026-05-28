import SwiftUI

struct VoiceCloneView: View {
    @StateObject private var audioService = AudioService()
    
    @State private var inputText = ""
    @State private var sampleData: Data?
    @State private var sampleFileName = ""
    @State private var stylePrompt = ""
    @State private var resultAudio: Data?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showDocPicker = false
    @State private var isRecording = false
    @State private var recordingURL: URL?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 声音样本
                    VStack(alignment: .leading, spacing: 8) {
                        Text("第一步：提供声音样本").font(.headline)
                        
                        HStack(spacing: 12) {
                            Button {
                                showDocPicker = true
                            } label: {
                                Label("选择音频文件", systemImage: "doc.badge.plus")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            
                            Button {
                                Task { await toggleRecording() }
                            } label: {
                                Label(isRecording ? "停止录音" : "现场录音", systemImage: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isRecording ? Color.red.opacity(0.2) : Color.orange.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                        
                        if let sample = sampleData {
                            HStack {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                Text("已加载样本: \(sampleFileName) (\(sample.count / 1024)KB)")
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                        }
                    }
                    
                    // 要说的话
                    VStack(alignment: .leading, spacing: 8) {
                        Text("第二步：输入要说的话").font(.headline)
                        TextEditor(text: $inputText)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    // 风格控制
                    VStack(alignment: .leading, spacing: 8) {
                        Text("可选：风格指令").font(.headline)
                        TextEditor(text: $stylePrompt)
                            .frame(height: 60)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                Text("如：用开心的语气说")
                                    .foregroundColor(.gray)
                                    .padding(.leading, 12)
                                    .padding(.top, 16)
                                    .opacity(stylePrompt.isEmpty ? 1 : 0)
                            )
                    }
                    
                    // 克隆按钮
                    Button {
                        Task { await cloneVoice() }
                    } label: {
                        HStack {
                            if isLoading { ProgressView().tint(.white) }
                            Text(isLoading ? "克隆中..." : "🧬 开始克隆")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(sampleData == nil || inputText.isEmpty ? Color.gray : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .disabled(sampleData == nil || inputText.isEmpty || isLoading)
                    
                    if let error = errorMessage {
                        Text(error).font(.caption).foregroundColor(.red)
                            .padding().background(Color.red.opacity(0.1)).cornerRadius(8)
                    }
                    
                    if let audio = resultAudio {
                        VStack(spacing: 12) {
                            Text("克隆完成 ✅").font(.headline).foregroundColor(.green)
                            Button {
                                try? audioService.play(data: audio)
                            } label: {
                                Label(audioService.isPlaying ? "播放中..." : "播放克隆语音", systemImage: "play.circle.fill")
                                    .font(.title3)
                            }
                            .disabled(audioService.isPlaying)
                        }
                        .padding().background(Color(.systemGray6)).cornerRadius(16)
                    }
                }
                .padding()
            }
            .navigationTitle("声音克隆")
            .fileImporter(
                isPresented: $showDocPicker,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: false
            ) { result in
                if let url = try? result.first {
                    loadAudio(from: url)
                }
            }
        }
    }
    
    private func loadAudio(from url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        
        if let data = try? Data(contentsOf: url) {
            sampleData = data
            sampleFileName = url.lastPathComponent
        }
    }
    
    private func toggleRecording() async {
        if isRecording {
            recordingURL = audioService.stopRecording()
            isRecording = false
            if let url = recordingURL {
                loadAudio(from: url)
            }
        } else {
            try? audioService.startRecording()
            isRecording = true
        }
    }
    
    private func cloneVoice() async {
        guard let sample = sampleData else { return }
        isLoading = true
        errorMessage = nil
        resultAudio = nil
        
        do {
            let audio = try await MiMoAPIService.shared.synthesizeWithClone(
                text: inputText,
                sampleAudioBase64: sample.base64EncodedString(),
                mimeType: sampleFileName.hasSuffix(".wav") ? "audio/wav" : "audio/mpeg",
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
