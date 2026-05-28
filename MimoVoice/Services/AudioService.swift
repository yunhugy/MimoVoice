import Foundation
import AVFoundation

class AudioService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingURL: URL?
    
    private let tempDir = FileManager.default.temporaryDirectory
    
    override init() {
        super.init()
    }
    
    // MARK: - 权限
    static func requestMicPermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    // MARK: - Recording
    func startRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)
        
        let filename = tempDir.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        let recorder = try AVAudioRecorder(url: filename, settings: settings)
        recorder.record()
        audioRecorder = recorder
        
        DispatchQueue.main.async {
            self.isRecording = true
            self.recordingURL = filename
        }
    }
    
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        audioRecorder = nil
        DispatchQueue.main.async {
            self.isRecording = false
        }
        return recordingURL
    }
    
    // MARK: - Playback
    func play(data: Data) throws {
        stopPlayback()
        
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
        
        let player = try AVAudioPlayer(data: data)
        player.delegate = self
        player.prepareToPlay()
        player.play()
        audioPlayer = player
        
        DispatchQueue.main.async {
            self.isPlaying = true
        }
    }
    
    func play(url: URL) throws {
        stopPlayback()
        
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
        
        let player = try AVAudioPlayer(contentsOf: url)
        player.delegate = self
        player.prepareToPlay()
        player.play()
        audioPlayer = player
        
        DispatchQueue.main.async {
            self.isPlaying = true
        }
    }
    
    func stopPlayback() {
        audioPlayer?.delegate = nil
        audioPlayer?.stop()
        audioPlayer = nil
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
    
    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.audioPlayer = nil
        }
    }
    
    // MARK: - Save
    func saveToDocuments(data: Data, filename: String) -> URL? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = docs.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            return url
        } catch {
            print("Save error: \(error)")
            return nil
        }
    }
}
