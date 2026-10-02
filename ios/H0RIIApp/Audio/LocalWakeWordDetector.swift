import Foundation
import AVFoundation
import CoreML

@MainActor
final class LocalWakeWordDetector: WakeWordDetector, ObservableObject {
    var onWakeWordDetected: (() -> Void)?
    var onPartialTranscript: ((String) -> Void)?

    private let audioEngine = AVAudioEngine()
    private var model: MLModel?
    private var recentScores: [Double] = []
    private let threshold = 0.78
    private let requiredHits = 2

    static var isConfigured: Bool {
        bundledModelURL() != nil
    }

    func start() {
        guard Self.isConfigured else {
            onPartialTranscript?("Gratis lokal wake-word modell mangler. Legg HeiHoriiWakeWord.mlmodel inn i Xcode target, ellers brukes Apple Speech fallback.")
            return
        }
        guard !audioEngine.isRunning else { return }

        do {
            try AudioSessionManager.shared.configureForAssistant()
            if model == nil, let url = Self.bundledModelURL() {
                model = try MLModel(contentsOf: url)
            }
            let input = audioEngine.inputNode
            input.removeTap(onBus: 0)
            let format = input.outputFormat(forBus: 0)
            input.installTap(onBus: 0, bufferSize: 16_000, format: format) { [weak self] buffer, _ in
                Task { @MainActor in self?.process(buffer: buffer) }
            }
            audioEngine.prepare()
            try audioEngine.start()
            onPartialTranscript?("Gratis CoreML wake-word detector lytter lokalt etter Hei Horii")
        } catch {
            onPartialTranscript?("Lokal wake-word detector kunne ikke starte: \(error.localizedDescription)")
            stop()
        }
    }

    func stop() {
        if audioEngine.isRunning { audioEngine.stop() }
        audioEngine.inputNode.removeTap(onBus: 0)
        recentScores.removeAll()
    }

    private func process(buffer: AVAudioPCMBuffer) {
        guard let model else { return }
        guard let features = WakeWordAudioFeatures(buffer: buffer) else { return }
        do {
            let output = try model.prediction(from: features)
            let score = Self.extractScore(from: output)
            recentScores.append(score)
            recentScores = Array(recentScores.suffix(requiredHits))
            onPartialTranscript?("Lokal wake-score: \(String(format: "%.2f", score))")
            if recentScores.count == requiredHits && recentScores.allSatisfy({ $0 >= threshold }) {
                stop()
                onPartialTranscript?("Gratis lokal modell oppdaget Hei Horii")
                onWakeWordDetected?()
            }
        } catch {
            onPartialTranscript?("Wake-word model prediction feilet: \(error.localizedDescription)")
        }
    }

    private static func extractScore(from output: MLFeatureProvider) -> Double {
        for key in ["probability", "score", "wake_word", "hei_horii", "output"] {
            if let value = output.featureValue(for: key) {
                if value.type == .double { return value.doubleValue }
                if value.type == .multiArray, let array = value.multiArrayValue, array.count > 0 {
                    return array[0].doubleValue
                }
            }
        }
        if let first = output.featureNames.first, let value = output.featureValue(for: first) {
            if value.type == .double { return value.doubleValue }
            if value.type == .multiArray, let array = value.multiArrayValue, array.count > 0 {
                return array[0].doubleValue
            }
        }
        return 0
    }

    private static func bundledModelURL() -> URL? {
        Bundle.main.url(forResource: "HeiHoriiWakeWord", withExtension: "mlmodelc")
            ?? Bundle.main.url(forResource: "hei_horii_wake_word", withExtension: "mlmodelc")
    }
}

final class WakeWordAudioFeatures: MLFeatureProvider {
    private let audio: MLMultiArray

    var featureNames: Set<String> { ["audio", "input", "waveform"] }

    init?(buffer: AVAudioPCMBuffer) {
        guard let channel = buffer.floatChannelData?[0] else { return nil }
        let count = min(Int(buffer.frameLength), 16_000)
        guard let array = try? MLMultiArray(shape: [NSNumber(value: count)], dataType: .float32) else { return nil }
        for index in 0..<count {
            array[index] = NSNumber(value: channel[index])
        }
        self.audio = array
    }

    func featureValue(for featureName: String) -> MLFeatureValue? {
        guard featureNames.contains(featureName) else { return nil }
        return MLFeatureValue(multiArray: audio)
    }
}
