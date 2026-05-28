import AVFoundation

class RealTimeEngine: ObservableObject {
    
    private var audioEngine: AVAudioEngine?
    private var pitchNode: AVAudioUnitTimePitch?
    
    @Published var isActive = false
    @Published var currentPitch: Float = 0
    @Published var effectName: String = "原声"
    
    func start() throws {
        stop()
        
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)
        
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let outputNode = engine.mainMixerNode
        let pitch = AVAudioUnitTimePitch()
        
        engine.attach(pitch)
        
        // 用输出格式统一（避免 inputNode 格式在权限刚授予时无效）
        let format = outputNode.inputFormat(forBus: 0)
        guard format.sampleRate > 0 else {
            throw EngineError.invalidAudioFormat
        }
        
        engine.connect(inputNode, to: pitch, format: format)
        engine.connect(pitch, to: outputNode, format: format)
        engine.prepare()
        
        try engine.start()
        
        audioEngine = engine
        pitchNode = pitch
        isActive = true
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
            pitch.pitch = 0; pitch.rate = 1.0
        case .chipmunk:
            pitch.pitch = 1200; pitch.rate = 1.2
        case .deep:
            pitch.pitch = -800; pitch.rate = 0.85
        case .robot:
            pitch.pitch = 0; pitch.rate = 1.0
        case .echo:
            pitch.pitch = 0; pitch.rate = 1.0
        case .alien:
            pitch.pitch = 600; pitch.rate = 1.1
        case .kid:
            pitch.pitch = 400; pitch.rate = 1.15
        case .giant:
            pitch.pitch = -1200; pitch.rate = 0.7
        }
    }
    
    func setPitch(_ v: Float) { currentPitch = v; pitchNode?.pitch = v }
    func setRate(_ v: Float) { pitchNode?.rate = v }
}

enum EngineError: LocalizedError {
    case invalidAudioFormat
    
    var errorDescription: String? {
        switch self {
        case .invalidAudioFormat: return "音频格式无效，请检查麦克风"
        }
    }
}
