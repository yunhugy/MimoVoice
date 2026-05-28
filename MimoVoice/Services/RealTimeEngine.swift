import AVFoundation
import Combine

class RealTimeEngine: ObservableObject {
    
    private var audioEngine: AVAudioEngine?
    private var pitchNode: AVAudioUnitTimePitch?
    private var cancellable: AnyCancellable?
    
    @Published var isActive = false
    @Published var currentPitch: Float = 0
    @Published var effectName: String = "原声"
    
    func start() throws {
        stop()
        
        // 1. 先配 Session（必须在 engine 之前）
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)
        
        // 2. 监听中断
        cancellable = NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self else { return }
                if let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                   AVAudioSession.InterruptionType(rawValue: type) == .ended {
                    // 中断结束，重启引擎
                    do {
                        try self.start()
                        self.setEffect(self.effectName.isEmpty ? .none : .none)
                    } catch {
                        print("Engine restart after interruption failed: \(error)")
                    }
                } else {
                    self.stop()
                }
            }
        
        // 3. 创建引擎
        let engine = AVAudioEngine()
        let pitch = AVAudioUnitTimePitch()
        
        engine.attach(pitch)
        
        // 4. 用 inputNode 的 format 驱动整条链（关键！）
        let format = engine.inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw EngineError.invalidAudioFormat
        }
        
        // 5. input → pitch → mixer（用同一个 format）
        engine.connect(engine.inputNode, to: pitch, format: format)
        engine.connect(pitch, to: engine.mainMixerNode, format: format)
        
        // 6. 关键：mixer → outputNode
        let outputFormat = engine.outputNode.inputFormat(forBus: 0)
        engine.connect(engine.mainMixerNode, to: engine.outputNode, format: outputFormat)
        
        engine.prepare()
        
        // 7. 启动
        do {
            try engine.start()
        } catch {
            print("AVAudioEngine.start() failed: \(error.localizedDescription)")
            throw error
        }
        
        audioEngine = engine
        pitchNode = pitch
        isActive = true
    }
    
    func stop() {
        cancellable?.cancel()
        cancellable = nil
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
