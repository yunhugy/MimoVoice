import AVFoundation

class RealTimeEngine: ObservableObject {
    
    private var audioEngine: AVAudioEngine?
    private var pitchNode: AVAudioUnitTimePitch?
    
    @Published var isActive = false
    @Published var currentPitch: Float = 0
    @Published var effectName: String = "原声"
    
    func start() throws {
        // 先清理旧的
        stop()
        
        // 配置音频会话
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)
        
        // 创建引擎
        let engine = AVAudioEngine()
        let pitch = AVAudioUnitTimePitch()
        
        let inputNode = engine.inputNode
        let mixerNode = engine.mainMixerNode
        
        // 先 detach 所有已有的连接
        engine.attach(pitch)
        
        let hwFormat = inputNode.outputFormat(forBus: 0)
        
        guard hwFormat.sampleRate > 0, hwFormat.channelCount > 0 else {
            throw EngineError.invalidAudioFormat
        }
        
        // input → pitch → output
        engine.connect(inputNode, to: pitch, format: hwFormat)
        engine.connect(pitch, to: mixerNode, format: hwFormat)
        
        // 标记活跃状态（必须在 engine.start 之前，这样 UI 不会卡）
        pitchNode = pitch
        audioEngine = engine
        isActive = true
        
        // 启动引擎（可能抛异常，此时 UI 已更新，catch 里回退状态）
        do {
            try engine.start()
        } catch {
            // 启动失败，回退状态
            self.audioEngine = nil
            self.pitchNode = nil
            self.isActive = false
            throw error
        }
    }
    
    func stop() {
        audioEngine?.stop()
        audioEngine = nil
        pitchNode = nil
        isActive = false
    }
    
    func setEffect(_ effect: RealTimeEffect) {
        effectName = effect.rawValue
        guard let pitch = pitchNode else { return }
        
        switch effect {
        case .none:
            pitch.pitch = 0
            pitch.rate = 1.0
        case .chipmunk:
            pitch.pitch = 1200
            pitch.rate = 1.2
        case .deep:
            pitch.pitch = -800
            pitch.rate = 0.85
        case .robot:
            pitch.pitch = 0
            pitch.rate = 1.0
        case .echo:
            pitch.pitch = 0
            pitch.rate = 1.0
        case .alien:
            pitch.pitch = 600
            pitch.rate = 1.1
        case .kid:
            pitch.pitch = 400
            pitch.rate = 1.15
        case .giant:
            pitch.pitch = -1200
            pitch.rate = 0.7
        }
    }
    
    func setPitch(_ pitchValue: Float) {
        currentPitch = pitchValue
        pitchNode?.pitch = pitchValue
    }
    
    func setRate(_ rate: Float) {
        pitchNode?.rate = rate
    }
}

enum EngineError: LocalizedError {
    case invalidAudioFormat
    case micPermissionDenied
    
    var errorDescription: String? {
        switch self {
        case .invalidAudioFormat: return "音频格式无效，请检查麦克风是否可用"
        case .micPermissionDenied: return "需要麦克风权限才能实时变声"
        }
    }
}
