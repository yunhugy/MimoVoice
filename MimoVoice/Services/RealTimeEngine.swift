import AVFoundation
import Accelerate

class RealTimeEngine: ObservableObject {
    
    private var audioEngine = AVAudioEngine()
    private var pitchNode = AVAudioUnitTimePitch()
    private var playerNode = AVAudioPlayerNode()
    private var mixerNode: AVAudioMixerNode
    
    @Published var isActive = false
    @Published var currentPitch: Float = 0
    @Published var volume: Float = 1.0
    @Published var effectName: String = "原声"
    
    // 混响参数
    private var reverbNode = AVAudioUnitReverb()
    private var delayNode = AVAudioUnitDelay()
    
    override init() {
        mixerNode = audioEngine.mainMixerNode
        super.init()
    }
    
    func setup() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.allowBluetooth])
        try session.setActive(true)
        
        audioEngine.attach(pitchNode)
        audioEngine.attach(reverbNode)
        audioEngine.attach(delayNode)
        
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        // input → pitch → reverb/delay → output
        audioEngine.connect(inputNode, to: pitchNode, format: format)
        audioEngine.connect(pitchNode, to: mixerNode, format: format)
        
        try audioEngine.start()
    }
    
    func start() throws {
        try setup()
        isActive = true
    }
    
    func stop() {
        audioEngine.stop()
        audioEngine.reset()
        isActive = false
    }
    
    func setEffect(_ effect: RealTimeEffect) {
        currentPitch = effect.pitch
        effectName = effect.rawValue
        pitchNode.pitch = effect.pitch
        
        switch effect {
        case .none:
            pitchNode.pitch = 0
            pitchNode.rate = 1.0
            reverbNode.wetDryMix = 0
            delayNode.wetDryMix = 0
        case .chipmunk:
            pitchNode.pitch = 1200
            pitchNode.rate = 1.2
            reverbNode.wetDryMix = 0
            delayNode.wetDryMix = 0
        case .deep:
            pitchNode.pitch = -800
            pitchNode.rate = 0.85
            reverbNode.wetDryMix = 0
            delayNode.wetDryMix = 0
        case .robot:
            pitchNode.pitch = 0
            pitchNode.rate = 1.0
            // 机器人效果用回声模拟
            delayNode.delayTime = 0.02
            delayNode.feedback = 80
            delayNode.wetDryMix = 60
            reverbNode.wetDryMix = 0
        case .echo:
            delayNode.delayTime = 0.3
            delayNode.feedback = 50
            delayNode.wetDryMix = 70
            reverbNode.wetDryMix = 0
        case .alien:
            pitchNode.pitch = 600
            pitchNode.rate = 1.1
            reverbNode.wetDryMix = 30
            delayNode.wetDryMix = 20
        case .kid:
            pitchNode.pitch = 400
            pitchNode.rate = 1.15
            reverbNode.wetDryMix = 0
            delayNode.wetDryMix = 0
        case .giant:
            pitchNode.pitch = -1200
            pitchNode.rate = 0.7
            reverbNode.wetDryMix = 40
            delayNode.wetDryMix = 0
        }
    }
    
    func setPitch(_ pitch: Float) {
        currentPitch = pitch
        pitchNode.pitch = pitch
    }
    
    func setRate(_ rate: Float) {
        pitchNode.rate = rate
    }
}
