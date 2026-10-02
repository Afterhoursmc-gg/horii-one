import SwiftUI
import Speech
import AVFoundation
import AVFAudio
import Contacts
import UIKit

struct DashboardView: View {
    @StateObject private var statsStore = PublicStatsStore()

    var body: some View {
        NavigationStack {
            ZStack {
                H0RIIBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        hero
                        stats
                        AfterHoursStatsCard(store: statsStore)
                        quickActions
                        SectionTitle("Live overview")
                        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                            ForEach(H0RIIService.live) { service in
                                ServiceMiniCard(service: service)
                            }
                        }
                        SectionTitle("Latest")
                        ForEach(H0RIIUpdate.feed) { item in
                            ActivityCard(title: item.title, text: item.body, symbol: item.symbol, trailing: item.time)
                        }
                    }
                    .padding(20)
                }
                .refreshable { await statsStore.refresh() }
            }
            .navigationTitle("H0RII")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task { await statsStore.refresh() }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("H0RII")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                    Text("Command center")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.78))
                }
                Spacer()
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 40))
                    .symbolRenderingMode(.hierarchical)
            }

            Text("A native iOS home for Jhonatan Wik / H0RII projects, live links, ops status and product updates.")
                .foregroundStyle(.secondary)
                .font(.title3)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Label("Native SwiftUI", systemImage: "swift")
                Spacer()
                Label("Ready for Xcode", systemImage: "hammer.fill")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.75))
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white.opacity(0.12)))
    }

    private var stats: some View {
        HStack(spacing: 12) {
            StatPill(value: "4", label: "Projects")
            StatPill(value: "Live", label: "Web")
            StatPill(value: "iOS", label: "Native")
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("Quick actions")
            HStack(spacing: 12) {
                QuickAction(title: "Open H0RII", icon: "safari.fill", url: "https://horii.dev")
                QuickAction(title: "AfterHours", icon: "gamecontroller.fill", url: "https://afterhoursmc.gg")
            }
            HStack(spacing: 12) {
                QuickAction(title: "HXSecurity", icon: "shield.fill", url: "https://hxsecurity.net")
                QuickAction(title: "Excel", icon: "tablecells.fill", url: "https://excel.horii.dev")
            }
        }
    }
}

struct StatusView: View {
    @StateObject private var statsStore = PublicStatsStore()

    var body: some View {
        NavigationStack {
            ZStack {
                H0RIIBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Status")
                            .font(.largeTitle.bold())
                        Text("Live-facing snapshot for H0RII systems. Pull down to refresh public stats.")
                            .foregroundStyle(.secondary)
                        AfterHoursStatsCard(store: statsStore)
                        ForEach(H0RIIService.live) { service in
                            StatusRow(service: service)
                        }
                        ActivityCard(title: "Next upgrade", text: "Wire this tab to status.horii.dev for incidents, uptime history and push notifications.", symbol: "antenna.radiowaves.left.and.right", trailing: "API")
                    }
                    .padding(20)
                }
                .refreshable { await statsStore.refresh() }
            }
            .navigationTitle("Status")
            .task { await statsStore.refresh() }
        }
    }
}

struct H0RIIBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, Color(red: 0.035, green: 0.035, blue: 0.07)], startPoint: .top, endPoint: .bottom)
            Circle().fill(.blue.opacity(0.15)).blur(radius: 60).offset(x: 130, y: -260)
            Circle().fill(.purple.opacity(0.12)).blur(radius: 70).offset(x: -160, y: 260)
        }
        .ignoresSafeArea()
    }
}

struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View { Text(text).font(.headline).foregroundStyle(.white) }
}

struct StatPill: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.08)))
    }
}

struct QuickAction: View {
    let title: String
    let icon: String
    let url: String
    var body: some View {
        Link(destination: URL(string: url)!) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 18))
                .foregroundStyle(.black)
        }
    }
}

struct AfterHoursStatsCard: View {
    @ObservedObject var store: PublicStatsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("AfterHoursMC public stats", systemImage: "gamecontroller.fill")
                    .font(.headline)
                Spacer()
                if store.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.secondary)
                }
            }

            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 10) {
                MetricCell(title: "Servers", value: store.stats.servers?.compactFormatted ?? "—")
                MetricCell(title: "Online", value: store.stats.playersOnline?.compactFormatted ?? "—")
                MetricCell(title: "Nodes", value: store.stats.nodes?.compactFormatted ?? "—")
                MetricCell(title: "Customers", value: store.stats.customers?.compactFormatted ?? "—")
            }

            HStack {
                Label("Uptime", systemImage: "checkmark.seal.fill")
                Spacer()
                Text(store.stats.uptime.map { String(format: "%.2f%%", $0) } ?? "—")
                    .font(.headline)
                    .foregroundStyle(.green)
            }
            .font(.subheadline)

            Text(store.lastError ?? "Updated from public endpoint when reachable")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(Color.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.08)))
    }
}

struct MetricCell: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.title3.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ServiceMiniCard: View {
    let service: H0RIIService
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: service.symbol)
                .font(.title2)
                .foregroundStyle(service.tint)
            Text(service.name).font(.headline)
            Text(service.value).font(.caption.bold()).foregroundStyle(service.tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 20))
    }
}

struct StatusRow: View {
    let service: H0RIIService
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: service.symbol)
                .font(.title3)
                .foregroundStyle(service.tint)
                .frame(width: 42, height: 42)
                .background(service.tint.opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(service.name).font(.headline)
                Text(service.detail).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Text(service.value)
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(service.tint.opacity(0.16), in: Capsule())
                .foregroundStyle(service.tint)
        }
        .padding(16)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 22))
    }
}

struct ActivityCard: View {
    let title: String
    let text: String
    let symbol: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol).font(.title2).foregroundStyle(.white)
                .frame(width: 44, height: 44).background(Color.white.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title).font(.headline)
                    Spacer()
                    if let trailing {
                        Text(trailing).font(.caption.bold()).foregroundStyle(.secondary)
                    }
                }
                Text(text).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 22))
    }
}

struct VoiceAssistantView: View {
    @StateObject private var assistant = VoiceAssistantController()
    @State private var typedCommand = ""

    var body: some View {
        NavigationStack {
            ZStack {
                H0RIIBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("H0RII Reise")
                                .font(.largeTitle.bold())
                            Text("Skyss-style travel assistant with better place recognition, voice and spoken replies.")
                                .foregroundStyle(.secondary)
                        }

                        ReisePlannerCard(assistant: assistant)
                        AlwaysOnH0RIICard()

                        VStack(spacing: 14) {
                            Button {
                                assistant.toggleListening()
                            } label: {
                                VStack(spacing: 10) {
                                    Image(systemName: assistant.isListening ? "waveform.circle.fill" : "mic.circle.fill")
                                        .font(.system(size: 76))
                                        .symbolRenderingMode(.hierarchical)
                                    Text(assistant.isListening ? "Listening… tap to stop" : "Hold the idea. Tap and speak.")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 28)
                                .background(assistant.isListening ? Color.red.opacity(0.22) : Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 30))
                                .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white.opacity(0.12)))
                            }
                            .buttonStyle(.plain)

                            Text(assistant.transcript.isEmpty ? "Try: ‘Når går bussen fra Bergen busstasjon til Åsane terminal?’" : assistant.transcript)
                                .font(.body)
                                .foregroundColor(assistant.transcript.isEmpty ? Color.secondary : Color.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 18))
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle("Type a test command")
                            HStack(spacing: 10) {
                                TextField("Ask H0RII…", text: $typedCommand)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .padding(14)
                                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                                Button("Run") {
                                    assistant.handle(typedCommand)
                                    typedCommand = ""
                                }
                                .font(.headline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                                .foregroundStyle(.black)
                            }
                        }

                        if !assistant.response.isEmpty {
                            ActivityCard(title: "H0RII says", text: assistant.response, symbol: "speaker.wave.2.fill", trailing: "Voice")
                        }

                        SectionTitle("Skills")
                        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                            VoiceSkillCard(title: "Bus", text: "‘buss fra Oslo til Bergen’", icon: "bus.fill")
                            VoiceSkillCard(title: "Weather", text: "‘vær i Oslo’", icon: "cloud.sun.fill")
                            VoiceSkillCard(title: "Call", text: "‘ring Sofie’ or number", icon: "phone.fill")
                            VoiceSkillCard(title: "Math", text: "‘kalkuler 12 * 8’", icon: "function")
                            VoiceSkillCard(title: "Translate", text: "‘oversett hei til engelsk’", icon: "character.book.closed.fill")
                            VoiceSkillCard(title: "Speak back", text: "Reads answers aloud", icon: "speaker.wave.3.fill")
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Voice")
        }
    }
}

struct AlwaysOnH0RIICard: View {
    @AppStorage("h0rii.lastBackgroundRefresh") private var lastBackgroundRefresh: Double = 0
    @State private var permissionMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Hei H0RII", systemImage: "waveform.circle.fill")
                    .font(.title3.bold())
                Spacer()
                Text("Siri Shortcut")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            }
            Text("iOS lar ikke tredjepartsapper lytte alltid etter egne wake words når telefonen er låst. Derfor bruker H0RII Siri/App Intents: si ‘Hei Siri, H0RII’ eller ‘Hei Siri, ask H0RII’.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 8) {
                Label("Bakgrunnsoppdatering registrert", systemImage: "arrow.triangle.2.circlepath")
                Label("Push/varsler klar for H0RII hints", systemImage: "bell.badge.fill")
                Label("Låst skjerm går via Siri, ikke skjult mic-loop", systemImage: "lock.fill")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.78))

            HStack(spacing: 10) {
                Button("Aktiver varsel-test") {
                    Task {
                        await H0RIINotificationService.shared.sendLocalWakeHint()
                        permissionMessage = "Varsel-test sendt hvis du godkjente notifications."
                    }
                }
                .font(.headline)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.black)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Sist BG-refresh")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(lastBackgroundRefresh > 0 ? Date(timeIntervalSince1970: lastBackgroundRefresh).formatted(date: .omitted, time: .shortened) : "Venter")
                        .font(.caption.bold())
                }
            }
            if !permissionMessage.isEmpty {
                Text(permissionMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.08)))
    }
}

struct ReisePlannerCard: View {
    @ObservedObject var assistant: VoiceAssistantController
    @State private var fromPlace = ""
    @State private var toPlace = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Hvor vil du reise?")
                    .font(.title.bold())
                Spacer()
                Label("Reise", systemImage: "bus.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            }
            PickerLikeTabs()
            VStack(alignment: .leading, spacing: 12) {
                PlaceTextField(title: "Fra", placeholder: "Din posisjon eller sted", text: $fromPlace)
                Divider().background(.white.opacity(0.14))
                PlaceTextField(title: "Til", placeholder: "Søk destinasjon", text: $toPlace)
                Button {
                    let from = fromPlace.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "din posisjon" : fromPlace
                    let to = toPlace.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Åsane terminal" : toPlace
                    assistant.handle("Når går bussen fra \(from) til \(to)")
                } label: {
                    Label("Søk reise", systemImage: "magnifyingglass")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            .padding(18)
            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 24))
            SectionTitle("Forslag")
            VStack(spacing: 10) {
                PlaceSuggestion(title: "Bergen busstasjon", detail: "Trykk/skriv som Fra eller Til")
                PlaceSuggestion(title: "Åsane terminal", detail: "Bergen, Vestland")
                PlaceSuggestion(title: "Lagunen terminal", detail: "Bergen, Vestland")
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white.opacity(0.1)))
    }
}

struct PlaceTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.caption.bold()).foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(false)
                .font(.title3.bold())
                .padding(14)
                .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.08)))
        }
    }
}

struct PickerLikeTabs: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("Finn reise")
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.35), in: Capsule())
            Text("Se avganger")
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .padding(4)
        .background(Color.white.opacity(0.08), in: Capsule())
    }
}

struct PlaceSuggestion: View {
    let title: String
    let detail: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bus.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "tram.fill").foregroundStyle(.orange)
        }
        .padding(14)
        .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 18))
    }
}

struct VoiceSkillCard: View {
    let title: String
    let text: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon).font(.title2).foregroundStyle(.white)
            Text(title).font(.headline)
            Text(text).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 20))
    }
}

@MainActor
final class VoiceAssistantController: NSObject, ObservableObject {
    @Published var transcript = ""
    @Published var response = ""
    @Published var isListening = false

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "nb_NO"))
    private let audioEngine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()
    private let contactStore = CNContactStore()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func toggleListening() {
        isListening ? stopListening() : startListening()
    }

    func startListening() {
        Task {
            let speechAllowed = await requestSpeechPermission()
            let micAllowed = await requestMicrophonePermission()
            guard speechAllowed && micAllowed else {
                answer("I need microphone and speech recognition access first.")
                return
            }
            beginRecognition()
        }
    }

    func stopListening() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        isListening = false
        let finalText = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !finalText.isEmpty { handle(finalText) }
    }

    func handle(_ rawText: String) {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        transcript = text
        let normalized = text.lowercased()
            .replacingOccurrences(of: "hei horii", with: "")
            .replacingOccurrences(of: "hei h0rii", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let quickMath = SimpleCalculator.evaluate(normalized
            .replacingOccurrences(of: "hva er", with: "")
            .replacingOccurrences(of: "ka er", with: "")
            .replacingOccurrences(of: "en", with: "1")
            .replacingOccurrences(of: "ett", with: "1")
            .replacingOccurrences(of: "to", with: "2")
            .replacingOccurrences(of: "pluss", with: "+")) {
            answer("Svaret er \(quickMath.cleanString).")
        } else if normalized.contains("buss") || normalized.contains("bus") {
            planTransit(from: normalized)
        } else if normalized.contains("vær") || normalized.contains("weather") {
            Task { await weather(from: normalized) }
        } else if normalized.hasPrefix("ring ") || normalized.contains(" ring ") || normalized.hasPrefix("call ") {
            prepareCallContactOrNumber(from: normalized)
        } else if normalized.contains("kalkuler") || normalized.contains("calculator") || normalized.contains("regn ut") {
            calculate(from: normalized)
        } else if normalized.contains("oversett") || normalized.contains("translate") {
            translate(from: normalized)
        } else {
            answer(generalAnswer(for: normalized))
        }
    }

    private func beginRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        transcript = ""

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            answer("Could not start microphone session.")
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        audioEngine.prepare()
        do { try audioEngine.start() } catch {
            answer("Could not start audio engine.")
            return
        }

        isListening = true
        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result { self.transcript = result.bestTranscription.formattedString }
                if error != nil || result?.isFinal == true { self.stopListening() }
            }
        }
    }

    private func requestSpeechPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
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
    }

    private func answer(_ text: String) {
        response = text
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "nb-NO") ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.48
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }

    private func planTransit(from text: String) {
        let corrected = correctTravelSpeech(text)
        let parts = splitFromTo(corrected)
        guard let from = parts.from, let to = parts.to else {
            answer("Si det sånn: Når går bussen fra Bergen busstasjon til Åsane terminal. Jeg prøver å rette stedene hvis talegjenkjenningen hører feil.")
            return
        }
        answer("Reise fra \(from) til \(to). Jeg gjenkjente stedene og holder deg inne i appen. Neste steg er ekte Entur/Skyss-avgang direkte her: linje, avgangstid, forsinkelse og gangtid.")
    }

    private func weather(from text: String) async {
        let city = text
            .replacingOccurrences(of: "hvordan er været i", with: "")
            .replacingOccurrences(of: "vær i", with: "")
            .replacingOccurrences(of: "weather in", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let query = city.isEmpty ? "Oslo" : city
        do {
            let weather = try await OpenMeteoService.fetchWeather(for: query)
            answer("Været i \(weather.name): \(weather.temperature.cleanString) grader, vind \(weather.wind.cleanString) meter per sekund. Dette vises direkte i appen.")
        } catch {
            answer("Jeg klarte ikke hente været akkurat nå, men jeg blir i appen. Prøv: vær i Oslo.")
        }
    }

    private func prepareCallContactOrNumber(from text: String) {
        let query = text
            .replacingOccurrences(of: "ring", with: "")
            .replacingOccurrences(of: "call", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            answer("Who should I call?")
            return
        }
        if let direct = normalizedPhoneNumber(query), !direct.isEmpty {
            answer("Jeg fant nummeret \(direct). Jeg holder deg inne i appen — legg til en bekreft-knapp senere hvis du vil at H0RII faktisk skal starte samtalen.")
            return
        }

        contactStore.requestAccess(for: .contacts) { [weak self] granted, _ in
            Task { @MainActor in
                guard let self else { return }
                guard granted else {
                    self.answer("I need Contacts access before I can call saved contacts.")
                    return
                }
                let keys: [CNKeyDescriptor] = [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor]
                let request = CNContactFetchRequest(keysToFetch: keys)
                var match: (name: String, phone: String)?
                try? self.contactStore.enumerateContacts(with: request) { contact, stop in
                    let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                    if name.lowercased().contains(query.lowercased()), let number = contact.phoneNumbers.first?.value.stringValue {
                        match = (name, number)
                        stop.pointee = true
                    }
                }
                if let match, let phone = self.normalizedPhoneNumber(match.phone) {
                    self.answer("Jeg fant \(match.name): \(phone). Jeg blir i appen og viser nummeret her i stedet for å sende deg ut.")
                } else {
                    self.answer("I could not find \(query) in contacts.")
                }
            }
        }
    }

    private func calculate(from text: String) {
        let expression = text
            .replacingOccurrences(of: "kalkuler", with: "")
            .replacingOccurrences(of: "regn ut", with: "")
            .replacingOccurrences(of: "calculator", with: "")
            .replacingOccurrences(of: "pluss", with: "+")
            .replacingOccurrences(of: "minus", with: "-")
            .replacingOccurrences(of: "ganger", with: "*")
            .replacingOccurrences(of: "delt på", with: "/")
        if let value = SimpleCalculator.evaluate(expression) {
            answer("Svaret er \(value.cleanString).")
        } else {
            answer("I could not calculate that yet. Try: kalkuler 12 * 8.")
        }
    }

    private func translate(from text: String) {
        let phrase = text
            .replacingOccurrences(of: "oversett", with: "")
            .replacingOccurrences(of: "translate", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !phrase.isEmpty else {
            answer("Si hva du vil jeg skal oversette.")
            return
        }
        let translated = LocalTranslator.translate(phrase)
        answer(translated)
    }

    private func generalAnswer(for text: String) -> String {
        if text.contains("hva er horii") || text.contains("ka e horii") {
            return "H0RII er brandet og systemet rundt prosjektene dine: web, Minecraft, bots, sikkerhet, produktbygging og nå iOS-assistenten."
        }
        if text.contains("hvem er jhonatan") {
            return "Jhonatan Wik er H0RII: norsk digital creator, developer og entrepreneur født i 2006."
        }
        if text.contains("hjelp") || text.contains("help") || text.contains("kan du") {
            return "Ja. Jeg kan svare inne i appen, regne, oversette enkle ting, vise vær, lage buss-plan, finne kontaktinfo og lese svaret høyt."
        }
        if text.contains("status") {
            return "Status akkurat nå: H0RII web er live, AfterHoursMC er live, HXSecurity bygges, og appen er under aktiv utvikling."
        }
        return "Jeg skjønte spørsmålet, men har ikke full AI-backend koblet enda. Jeg svarer lokalt nå, og neste steg er å koble H0RII Voice til en trygg server-side AI endpoint så du kan spørre om hva som helst uten å forlate appen."
    }

    private func splitFromTo(_ text: String) -> (from: String?, to: String?) {
        let cleaned = text
            .replacingOccurrences(of: "når går bussen", with: "")
            .replacingOccurrences(of: "nar gar bussen", with: "")
            .replacingOccurrences(of: "bussen", with: "")
            .replacingOccurrences(of: "buss", with: "")
        guard let fromRange = cleaned.range(of: "fra "), let toRange = cleaned.range(of: " til ") else { return (nil, nil) }
        let fromRaw = String(cleaned[fromRange.upperBound..<toRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        let toRaw = String(cleaned[toRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        let from = knownPlace(fromRaw)
        let to = knownPlace(toRaw)
        return (from.isEmpty ? nil : from, to.isEmpty ? nil : to)
    }

    private func correctTravelSpeech(_ value: String) -> String {
        value.lowercased()
            .replacingOccurrences(of: "å sane", with: "åsane")
            .replacingOccurrences(of: "a sane", with: "åsane")
            .replacingOccurrences(of: "asane", with: "åsane")
            .replacingOccurrences(of: "bergen bus station", with: "bergen busstasjon")
            .replacingOccurrences(of: "bergen busstation", with: "bergen busstasjon")
            .replacingOccurrences(of: "bergen buss stasjon", with: "bergen busstasjon")
            .replacingOccurrences(of: "bergen bussen stasjon", with: "bergen busstasjon")
            .replacingOccurrences(of: "bærgen", with: "bergen")
    }

    private func knownPlace(_ value: String) -> String {
        let text = correctTravelSpeech(value)
        if text.contains("bergen") && (text.contains("busstasjon") || text.contains("stasjon")) { return "Bergen busstasjon" }
        if text.contains("åsane") { return "Åsane terminal" }
        if text.contains("lagunen") { return "Lagunen terminal" }
        if text.contains("sandvik") { return "Sandvikvåg ferjekai" }
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizedPhoneNumber(_ value: String) -> String? {
        let allowed = Set("+0123456789")
        let phone = String(value.filter { allowed.contains($0) })
        return phone.count >= 3 ? phone : nil
    }

    private func openURL(_ raw: String) {
        guard let url = URL(string: raw) else { return }
        UIApplication.shared.open(url)
    }
}

struct WeatherAnswer {
    let name: String
    let temperature: Double
    let wind: Double
}

struct OpenMeteoService {
    struct GeoResponse: Decodable {
        let results: [Place]?
    }

    struct Place: Decodable {
        let name: String
        let latitude: Double
        let longitude: Double
        let country: String?
    }

    struct ForecastResponse: Decodable {
        let current_weather: CurrentWeather
    }

    struct CurrentWeather: Decodable {
        let temperature: Double
        let windspeed: Double
    }

    static func fetchWeather(for city: String) async throws -> WeatherAnswer {
        let geoURL = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(city.urlEncoded)&count=1&language=no&format=json")!
        let (geoData, _) = try await URLSession.shared.data(from: geoURL)
        let geo = try JSONDecoder().decode(GeoResponse.self, from: geoData)
        guard let place = geo.results?.first else { throw URLError(.cannotFindHost) }
        let forecastURL = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(place.latitude)&longitude=\(place.longitude)&current_weather=true")!
        let (forecastData, _) = try await URLSession.shared.data(from: forecastURL)
        let forecast = try JSONDecoder().decode(ForecastResponse.self, from: forecastData)
        let displayName = [place.name, place.country].compactMap { $0 }.joined(separator: ", ")
        return WeatherAnswer(name: displayName, temperature: forecast.current_weather.temperature, wind: forecast.current_weather.windspeed)
    }
}

struct LocalTranslator {
    static func translate(_ phrase: String) -> String {
        let lower = phrase.lowercased()
        let dictionary = [
            "hei": "hello",
            "ha det": "goodbye",
            "takk": "thank you",
            "god morgen": "good morning",
            "jeg elsker deg": "I love you",
            "hvordan går det": "how are you",
            "hvor er bussen": "where is the bus"
        ]
        for (source, target) in dictionary where lower.contains(source) {
            return "Oversatt: \(target)."
        }
        return "Jeg holder deg i appen. Lokal mini-oversetter kan de vanligste frasene nå; full oversetting trenger H0RII AI/translation backend."
    }
}

struct SimpleCalculator {
    static func evaluate(_ expression: String) -> Double? {
        let tokens = tokenize(expression)
        guard !tokens.isEmpty else { return nil }
        var values: [Double] = []
        var ops: [Character] = []

        func precedence(_ op: Character) -> Int { (op == "*" || op == "/") ? 2 : 1 }
        func apply() {
            guard values.count >= 2, let op = ops.popLast() else { return }
            let rhs = values.removeLast()
            let lhs = values.removeLast()
            switch op {
            case "+": values.append(lhs + rhs)
            case "-": values.append(lhs - rhs)
            case "*": values.append(lhs * rhs)
            case "/": values.append(rhs == 0 ? .nan : lhs / rhs)
            default: break
            }
        }

        for token in tokens {
            if let number = Double(token) {
                values.append(number)
            } else if let op = token.first, "+-*/".contains(op) {
                while let last = ops.last, precedence(last) >= precedence(op) { apply() }
                ops.append(op)
            }
        }
        while !ops.isEmpty { apply() }
        return values.first?.isFinite == true ? values.first : nil
    }

    private static func tokenize(_ expression: String) -> [String] {
        var tokens: [String] = []
        var number = ""
        for char in expression.replacingOccurrences(of: ",", with: ".") {
            if char.isNumber || char == "." {
                number.append(char)
            } else if "+-*/".contains(char) {
                if !number.isEmpty { tokens.append(number); number = "" }
                tokens.append(String(char))
            } else if char.isWhitespace, !number.isEmpty {
                tokens.append(number); number = ""
            }
        }
        if !number.isEmpty { tokens.append(number) }
        return tokens
    }
}

extension String {
    var urlEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}

extension Double {
    var cleanString: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(Int(self)) : String(format: "%.2f", self)
    }
}

#Preview { DashboardView() }
#Preview { StatusView() }
#Preview { VoiceAssistantView() }
