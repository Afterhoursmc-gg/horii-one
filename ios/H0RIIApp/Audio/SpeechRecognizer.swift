import Foundation
import Speech
import AVFoundation

@MainActor
final class HoriiSpeechRecognizer: NSObject, ObservableObject {
    @Published private(set) var transcript = ""
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "nb_NO"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func requestPermissions() async -> Bool {
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        let mic = await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { allowed in
                    continuation.resume(returning: allowed)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                    continuation.resume(returning: allowed)
                }
            }
        }
        return speech && mic
    }

    func listenForCommand(timeout: TimeInterval = 5.0) async throws -> String {
        transcript = ""
        try AudioSessionManager.shared.configureForAssistant()

        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.shouldReportPartialResults = true
        request = recognitionRequest

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak recognitionRequest] buffer, _ in
            recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        return try await withCheckedThrowingContinuation { continuation in
            var didResume = false
            let finish: (Result<String, Error>) -> Void = { [weak self] result in
                guard !didResume else { return }
                didResume = true
                Task { @MainActor in self?.stop() }
                continuation.resume(with: result)
            }

            task = recognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                        if result.isFinal {
                            finish(.success(self.transcript))
                        }
                    }
                    if let error {
                        finish(.failure(error))
                    }
                }
            }

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                let final = self.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                finish(.success(final))
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil
        if audioEngine.isRunning { audioEngine.stop() }
        audioEngine.inputNode.removeTap(onBus: 0)
    }
}
