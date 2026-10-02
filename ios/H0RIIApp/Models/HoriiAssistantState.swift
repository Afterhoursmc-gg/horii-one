import Foundation

enum HoriiAssistantState: String, CaseIterable, Identifiable {
    case idle
    case waitingForWakeWord
    case wakeWordDetected
    case listening
    case processing
    case speaking

    var id: String { rawValue }

    var title: String {
        switch self {
        case .idle: "Sleeping"
        case .waitingForWakeWord: "Listening for “Hei Horii”"
        case .wakeWordDetected: "Wake word detected"
        case .listening: "Listening…"
        case .processing: "Thinking…"
        case .speaking: "Speaking…"
        }
    }

    var detail: String {
        switch self {
        case .idle: "Assistant is off."
        case .waitingForWakeWord: "Local wake-word adapter is armed."
        case .wakeWordDetected: "Horii heard the wake phrase."
        case .listening: "Command audio is being transcribed."
        case .processing: "Sending command to Horii AI provider."
        case .speaking: "Horii is reading the answer aloud."
        }
    }
}
