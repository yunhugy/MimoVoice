import AVFoundation

class RealTimeEngine: ObservableObject {
    
    private var audioEngine: AVAudioEngine?
    private var pitchNode: AVAudioUnitTimePitch?
    
    @Published var isActive = false
    @Published var currentPitch: Float = 0
    @Published var effectName: String = "原声"
    
    private var isSetup = false
    
    func start() throws {
        if isSetup { stop() }
        
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)
        
        let engine = AVAudioEngine()
        let pitch = AVAudioUnitTimePitch()
        let inputNode = engine.inputNode
        let outputNode = engine.mainMixerNode
        
        engine.attach(pitch)
        
        let format = inputNode.outputFormat(forBus: 0)
        engine.connect(inputNode, to: pitch, format: format)
        engine.connect(pitch, to: outputNode, format: format)
        engine.prepare()
        
        try engine.start()
        
        audioEngine = engine
        pitchNode = pitch
        isSetup = true
        
        DispatchQueue.main.async {
            self.isActive = true
            self.setEffect(.none)
        }
    }
    
    func stop() {
        audioEngine?.stop()
        audioEngine?.disconnectNodeInput(audioEngine!.inputNode)
        audioEngine = nil
        pitchNode = nil
        isSetup = false
        
        DispatchQueue.main.async {
            self.isActive = false
        }
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
