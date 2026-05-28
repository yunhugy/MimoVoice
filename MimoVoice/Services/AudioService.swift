import Foundation
import AVFoundation

class AudioService: ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingURL: URL?
    
    private let tempDir = FileManager.default.temporaryDirectory
    
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
        
        audioRecorder = try AVAudioRecorder(url: filename, settings: settings)
        audioRecorder?.record()
        
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
        
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
        
        DispatchQueue.main.async {
            self.isPlaying = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + (audioPlayer?.duration ?? 0)) {
            self.isPlaying = false
        }
    }
    
    func play(url: URL) throws {
        stopPlayback()
        
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
        
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
        
        DispatchQueue.main.async {
            self.isPlaying = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + (audioPlayer?.duration ?? 0)) {
            self.isPlaying = false
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        DispatchQueue.main.async {
            self.isPlaying = false
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
