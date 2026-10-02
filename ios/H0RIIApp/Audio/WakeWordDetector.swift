import Foundation
import AVFoundation
import Speech

@MainActor
protocol WakeWordDetector: AnyObject {
    func start()
    func stop()
    var onWakeWordDetected: (() -> Void)? { get set }
    var onPartialTranscript: ((String) -> Void)? { get set }
}

@MainActor
final class SpeechWakeWordDetector: NSObject, WakeWordDetector, ObservableObject {
    var onWakeWordDetected: (() -> Void)?
    var onPartialTranscript: ((String) -> Void)?
    @Published private(set) var isRunning = false
    @Published private(set) var lastHeard = ""
    @Published private(set) var limitation = "Prototype detector uses Apple Speech as an adapter. Replace with a true on-device wake-word engine later."

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "nb_NO"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let wakeWords = [
        "hei horii", "hey horii", "hei hori", "hey hori", "hei h0rii",
        "hei ho rii", "hey ho ree", "hei hori i", "hei harry", "hey harry",
        "hei horry", "hey horry", "hey quarry", "hei hori"
    ]

    func start() {
        guard !isRunning else { return }
        do {
            try AudioSessionManager.shared.configureForAssistant()
            beginRecognition()
        } catch {
            limitation = "Could not start audio session: \(error.localizedDescription)"
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil
        if audioEngine.isRunning { audioEngine.stop() }
        audioEngine.inputNode.removeTap(onBus: 0)
        isRunning = false
    }

    private func beginRecognition() {
        task?.cancel()
        task = nil

        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        self.request = recognitionRequest

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak recognitionRequest] buffer, _ in
            recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRunning = true
        } catch {
            limitation = "Could not start wake-word audio engine: \(error.localizedDescription)"
            return
        }

        task = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    let rawText = result.bestTranscription.formattedString
                    let text = Self.normalized(rawText)
                    self.lastHeard = rawText
                    self.onPartialTranscript?("Hører wake-word: \(rawText)")
                    if self.wakeWords.contains(where: { text.contains($0) }) || Self.looksLikeHeiHorii(text) {
                        self.stop()
                        self.onPartialTranscript?("Wake-word oppdaget: \(rawText)")
                        self.onWakeWordDetected?()
                        return
                    }
                    if result.isFinal && self.isRunning {
                        self.restartSoon()
                    }
                }
                if error != nil && self.isRunning {
                    self.restartSoon()
                }
            }
        }
    }

    private func restartSoon() {
        stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            Task { @MainActor in
                self?.start()
            }
        }
    }

    private static func normalized(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "hørii", with: "horii")
            .replacingOccurrences(of: "hori i", with: "horii")
            .replacingOccurrences(of: "h o r i i", with: "horii")
            .replacingOccurrences(of: "0", with: "o")
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func looksLikeHeiHorii(_ text: String) -> Bool {
        let compact = text.replacingOccurrences(of: " ", with: "")
        let starts = ["hei", "hey", "hai"]
        let names = ["horii", "hori", "horry", "harry", "hory", "hørii"]
        return starts.contains(where: { compact.hasPrefix($0) }) && names.contains(where: { compact.contains($0) })
    }
}
