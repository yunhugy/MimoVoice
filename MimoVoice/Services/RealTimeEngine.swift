import AVFoundation

class RealTimeEngine: ObservableObject {
    
    private var audioEngine: AVAudioEngine?
    private var pitchNode: AVAudioUnitTimePitch?
    
    @Published var isActive = false
    @Published var currentPitch: Float = 0
    @Published var effectName: String = "原声"
    
    private var isSetup = false
    
    // MARK: - 请求麦克风权限
    func requestMicPermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    // MARK: - 启动引擎
    func start() throws {
        if isSetup { stop() }
        
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)
        
        let engine = AVAudioEngine()
        let pitch = AVAudioUnitTimePitch()
        
        engine.attach(pitch)
        
        let inputNode = engine.inputNode
        let outputNode = engine.mainMixerNode
        let format = inputNode.outputFormat(forBus: 0)
        
        // 验证 format 有效
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw EngineError.invalidAudioFormat
        }
        
        engine.connect(inputNode, to: pitch, format: format)
        engine.connect(pitch, to: outputNode, format: format)
        engine.prepare()
        
        try engine.start()
        
        // 全部成功后才赋值
        audioEngine = engine
        pitchNode = pitch
        isSetup = true
        isActive = true
    }
    
    // MARK: - 停止引擎（安全清理）
    func stop() {
        guard let engine = audioEngine else {
            // 即使 engine 为 nil，也要重置状态
            isActive = false
            isSetup = false
            return
        }
        
        engine.stop()
        engine.disconnectNodeInput(engine.inputNode)
        audioEngine = nil
        pitchNode = nil
        isSetup = false
        isActive = false
    }
    
    // MARK: - 设置效果
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
        case .invalidAudioFormat: return "音频格式无效，请检查麦克风"
        case .micPermissionDenied: return "需要麦克风权限才能实时变声"
        }
    }
}
