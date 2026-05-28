import Foundation

class MiMoAPIService: ObservableObject {
    @AppStorage("apiKey") private var storedApiKey = ""
    @AppStorage("baseURL") private var storedBaseURL = "https://token-plan-sgp.xiaomimimo.com/v1"
    @AppStorage("whisperKey") private var whisperKey = ""
    
    static let shared = MiMoAPIService()
    
    private var baseURL: String { storedBaseURL }
    private var apiKey: String { storedApiKey }
    
    // MARK: - TTS (Text to Speech)
    func synthesize(text: String, stylePrompt: String, model: String = "mimo-v2.5-tts") async throws -> Data {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": stylePrompt],
                ["role": "assistant", "content": text]
            ],
            "audio": [
                "format": "wav",
                "optimize_text_preview": true
            ],
            "stream": false
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(response, data: data)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let audio = message["audio"] as? [String: Any],
              let audioDataStr = audio["data"] as? String,
              let audioBytes = Data(base64Encoded: audioDataStr) else {
            throw APIError.invalidResponse
        }
        
        return audioBytes
    }
    
    // MARK: - Voice Clone TTS
    func synthesizeWithClone(text: String, sampleAudioBase64: String, mimeType: String = "audio/wav", stylePrompt: String = "") async throws -> Data {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let userContent = stylePrompt.isEmpty ? "" : stylePrompt
        
        let body: [String: Any] = [
            "model": "mimo-v2.5-tts-voiceclone",
            "messages": [
                ["role": "user", "content": userContent],
                ["role": "assistant", "content": text]
            ],
            "audio": [
                "format": "wav",
                "voice": "data:\(mimeType);base64,\(sampleAudioBase64)"
            ],
            "stream": false
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(response, data: data)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let audio = message["audio"] as? [String: Any],
              let audioDataStr = audio["data"] as? String,
              let audioBytes = Data(base64Encoded: audioDataStr) else {
            throw APIError.invalidResponse
        }
        
        return audioBytes
    }
    
    // MARK: - Whisper ASR (Speech to Text)
    func transcribe(audioData: Data, language: String = "zh") async throws -> String {
        guard !whisperKey.isEmpty else {
            throw APIError.noWhisperKey
        }
        guard let url = URL(string: "https://api.openai.com/v1/audio/transcriptions") else {
            throw APIError.invalidURL
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(whisperKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\nwhisper-1\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n\(language)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(response, data: data)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["text"] as? String else {
            throw APIError.invalidResponse
        }
        
        return text
    }
    
    // MARK: - Helpers
    private func checkResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResp = response as? HTTPURLResponse else {
            throw APIError.networkError
        }
        if httpResp.statusCode == 401 {
            throw APIError.authError
        }
        if httpResp.statusCode >= 400 {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(msg)
        }
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case networkError
    case authError
    case invalidResponse
    case serverError(String)
    case noWhisperKey
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL 无效"
        case .networkError: return "网络错误"
        case .authError: return "API Key 无效，请检查设置"
        case .invalidResponse: return "响应格式错误"
        case .serverError(let msg): return "服务端错误: \(msg)"
        case .noWhisperKey: return "未配置 Whisper API Key（语音识别）"
        }
    }
}
