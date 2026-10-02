import Foundation

@MainActor
struct WakeWordDetectorFactory {
    static func make() -> WakeWordDetector {
        if LocalWakeWordDetector.isConfigured {
            return LocalWakeWordDetector()
        }
        return SpeechWakeWordDetector()
    }
}
