import AVFoundation
import AVFAudio

@MainActor
final class AudioSessionManager {
    static let shared = AudioSessionManager()
    private init() {}

    private(set) var isConfigured = false

    func configureForAssistant() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP, .duckOthers]
        )
        try session.setPreferredSampleRate(16_000)
        try session.setPreferredIOBufferDuration(0.02)
        try session.setActive(true, options: [])
        isConfigured = true
    }

    func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isConfigured = false
    }
}
