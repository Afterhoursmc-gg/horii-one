import SwiftUI

struct HoriiAssistantPrototypeView: View {
    @StateObject private var controller = HoriiAssistantController()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("HORII")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                    Text("Always Listening prototype beside Siri")
                        .foregroundColor(.secondary)
                }

                stateCard
                enableButton
                testControls
                localModelSettings
                telemetryCard
                privacyCard
                limitationCard
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .foregroundColor(.white)
        .navigationTitle("Horii")
    }

    private var stateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(controller.state.title)
                .font(.title2.weight(.bold))
            Text(controller.state.detail)
                .foregroundColor(.secondary)
            ProgressView(value: progress)
                .tint(.cyan)
        }
        .padding()
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
    }

    private var enableButton: some View {
        Button {
            Task {
                if controller.state == .idle {
                    await controller.enableAssistant()
                } else {
                    controller.disableAssistant()
                }
            }
        } label: {
            HStack {
                Image(systemName: controller.state == .idle ? "mic.circle.fill" : "stop.circle.fill")
                Text(controller.state == .idle ? "Enable Assistant" : "Disable Assistant")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(controller.state == .idle ? Color.cyan : Color.red, in: RoundedRectangle(cornerRadius: 18))
            .foregroundColor(.black)
        }
    }

    private var testControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test without locking")
                .font(.headline)
            Text("Use this to prove the state machine, AI mock and TTS work before testing iOS locked-screen behavior.")
                .font(.footnote)
                .foregroundColor(.secondary)
            HStack(spacing: 10) {
                Button("Simulate Hei Horii") {
                    Task { await controller.simulateWakeWordForTesting() }
                }
                .buttonStyle(.borderedProminent)

                Button("Send typed") {
                    Task { await controller.sendTypedCommandForTesting() }
                }
                .buttonStyle(.bordered)
            }
            TextField("hva er en pluss en", text: $controller.typedCommand)
                .textFieldStyle(.roundedBorder)
                .foregroundColor(.primary)
        }
        .padding()
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
    }

    private var localModelSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Free local wake-word engine")
                .font(.headline)
            Text("No Picovoice, no paid AccessKey. Horii looks for a bundled CoreML model named `HeiHoriiWakeWord.mlmodel`. If the model is present, detection runs fully local. If not, the app falls back to the Apple Speech debug adapter.")
                .font(.footnote)
                .foregroundColor(.secondary)
            Label("Expected model: HeiHoriiWakeWord.mlmodel", systemImage: "cpu")
                .font(.footnote)
                .foregroundColor(.cyan)
        }
        .padding()
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
    }

    private var telemetryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(controller.microphoneStatus, systemImage: "mic")
            Label(controller.backgroundListeningActive ? "Background audio session active" : "Background listening inactive", systemImage: controller.backgroundListeningActive ? "waveform" : "waveform.slash")
            Divider().background(.white.opacity(0.2))
            Text("Transcript")
                .font(.headline)
            Text(controller.transcript.isEmpty ? "Say “Hei Horii”, then a command." : controller.transcript)
                .foregroundColor(controller.transcript.isEmpty ? .secondary : .white)
            Text("AI answer")
                .font(.headline)
            Text(controller.answer.isEmpty ? "Horii AI response appears here." : controller.answer)
                .foregroundColor(controller.answer.isEmpty ? .secondary : .white)
        }
        .padding()
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
    }

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Privacy", systemImage: "lock.shield")
                .font(.headline)
            Text("Wake-word detection is local through the WakeWordDetector adapter. Only after “Hei Horii” is detected does Horii transcribe the command and call HoriiAIService. The default service is mock-only.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
    }

    private var limitationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("iOS reality check", systemImage: "exclamationmark.triangle")
                .font(.headline)
            Text(controller.technicalLimitation.isEmpty ? "iOS supports background audio for permitted audio apps, but it does not give third-party apps Siri-level always-on custom hotword entitlement. This prototype uses public APIs only and isolates WakeWordDetector so a real local wake-word SDK can replace the adapter." : controller.technicalLimitation)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 24))
    }

    private var progress: Double {
        switch controller.state {
        case .idle: 0.05
        case .waitingForWakeWord: 0.25
        case .wakeWordDetected: 0.45
        case .listening: 0.6
        case .processing: 0.78
        case .speaking: 0.95
        }
    }
}
