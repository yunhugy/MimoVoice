import SwiftUI
import UniformTypeIdentifiers

struct VoiceCloneView: View {
    @StateObject private var audioService = AudioService()
    
    @State private var inputText: String = ""
    @State private var sampleData: Data? = nil
    @State private var sampleFileName: String = ""
    @State private var stylePrompt: String = ""
    @State private var resultAudio: Data? = nil
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showDocPicker: Bool = false
    @State private var isRecording: Bool = false
    @State private var recordingURL: URL? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    sampleSection
                    textSection
                    styleSection
                    cloneButton
                    errorSection
                    resultSection
                }
                .padding()
            }
            .navigationTitle("声音克隆")
            .fileImporter(
                isPresented: $showDocPicker,
                allowedContentTypes: [UTType.audio],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result: result)
            }
        }
    }
    
    // MARK: - Sub Views
    
    private var sampleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("第一步：提供声音样本").font(.headline)
            
            HStack(spacing: 12) {
                Button(action: { showDocPicker = true }) {
                    Label("选择音频文件", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Button(action: handleRecording) {
                    Label(isRecording ? "停止录音" : "现场录音",
                          systemImage: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isRecording ? Color.red.opacity(0.2) : Color.orange.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            
            if let sample = sampleData {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    Text("已加载: \(sampleFileName) (\(sample.count / 1024)KB)")
                        .font(.caption).lineLimit(1)
                }
            }
        }
    }
    
    private var textSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("第二步：输入要说的话").font(.headline)
            TextEditor(text: $inputText)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
    
    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("可选：风格指令").font(.headline)
            TextEditor(text: $stylePrompt)
                .frame(height: 60)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(alignment: .topLeading) {
                    if stylePrompt.isEmpty {
                        Text("如：用开心的语气说")
                            .foregroundColor(.gray)
                            .padding(.leading, 12)
                            .padding(.top, 16)
                    }
                }
        }
    }
    
    private var cloneButton: some View {
        Button(action: { Task { await cloneVoice() } }) {
            HStack {
                if isLoading { ProgressView().tint(.white) }
                Text(isLoading ? "克隆中..." : "🧬 开始克隆")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canClone ? Color.orange : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .disabled(!canClone || isLoading)
    }
    
    @ViewBuilder
    private var errorSection: some View {
        if let error = errorMessage {
            Text(error).font(.caption).foregroundColor(.red)
                .padding().background(Color.red.opacity(0.1)).cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private var resultSection: some View {
        if let audio = resultAudio {
            VStack(spacing: 12) {
                Text("克隆完成 ✅").font(.headline).foregroundColor(.green)
                Button(action: { try? audioService.play(data: audio) }) {
                    Label(audioService.isPlaying ? "播放中..." : "播放克隆语音",
                          systemImage: "play.circle.fill")
                        .font(.title3)
                }
                .disabled(audioService.isPlaying)
            }
            .padding().background(Color(.systemGray6)).cornerRadius(16)
        }
    }
    
    // MARK: - Helpers
    
    private var canClone: Bool {
        sampleData != nil && !inputText.isEmpty
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
        if case .success(let urls) = result, let url = urls.first {
            let accessing = url.startAccessingSecurityScopedResource()
            if let data = try? Data(contentsOf: url) {
                sampleData = data
                sampleFileName = url.lastPathComponent
            }
            if accessing { url.stopAccessingSecurityScopedResource() }
        }
    }
    
    private func handleRecording() {
        if isRecording {
            recordingURL = audioService.stopRecording()
            isRecording = false
            if let url = recordingURL, let data = try? Data(contentsOf: url) {
                sampleData = data
                sampleFileName = url.lastPathComponent
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
            let mime = sampleFileName.hasSuffix(".wav") ? "audio/wav" : "audio/mpeg"
            let audio = try await MiMoAPIService.shared.synthesizeWithClone(
                text: inputText,
                sampleAudioBase64: sample.base64EncodedString(),
                mimeType: mime,
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
