import Foundation
import AppIntents
import BackgroundTasks
import UserNotifications

struct H0RIIAssistantBrain {
    static func answer(_ rawText: String) -> String {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = text.lowercased()
            .replacingOccurrences(of: "hei horii", with: "")
            .replacingOccurrences(of: "hey horii", with: "")
            .replacingOccurrences(of: "hei h0rii", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let math = simpleMath(normalized) {
            return "Svaret er \(math.cleanString)."
        }
        if normalized.contains("buss") || normalized.contains("reise") {
            return "Jeg åpner Reise-modus. Si for eksempel: Når går bussen fra Bergen busstasjon til Åsane terminal."
        }
        if normalized.contains("vær") || normalized.contains("weather") {
            return "Jeg kan sjekke været inne i H0RII-appen når appen er åpen."
        }
        if normalized.contains("status") {
            return "H0RII er klar. Bakgrunnsoppdatering og Siri-snarvei er registrert i appen."
        }
        if normalized.contains("hva kan du") || normalized.contains("hjelp") || normalized.contains("help") {
            return "Jeg kan svare, regne, planlegge reise, lese opp svar og starte H0RII via Siri-snarvei. For ekte låst skjerm må iOS bruke Siri: si Hei Siri, H0RII."
        }
        return "Jeg hørte: \(text). Åpne H0RII for fullt svar med Reise, vær, kontakter og stemme."
    }

    private static func simpleMath(_ text: String) -> Double? {
        let expression = text
            .replacingOccurrences(of: "hva er", with: "")
            .replacingOccurrences(of: "ka er", with: "")
            .replacingOccurrences(of: "kalkuler", with: "")
            .replacingOccurrences(of: "regn ut", with: "")
            .replacingOccurrences(of: "en", with: "1")
            .replacingOccurrences(of: "ett", with: "1")
            .replacingOccurrences(of: "to", with: "2")
            .replacingOccurrences(of: "tre", with: "3")
            .replacingOccurrences(of: "fire", with: "4")
            .replacingOccurrences(of: "fem", with: "5")
            .replacingOccurrences(of: "pluss", with: "+")
            .replacingOccurrences(of: "minus", with: "-")
            .replacingOccurrences(of: "ganger", with: "*")
            .replacingOccurrences(of: "delt på", with: "/")
        return SimpleCalculator.evaluate(expression)
    }
}

struct AskH0RIIIntent: AppIntent {
    static var title: LocalizedStringResource = "Ask H0RII"
    static var description = IntentDescription("Ask H0RII through Siri Shortcuts. Use: Hei Siri, H0RII.")
    static var openAppWhenRun = false

    @Parameter(title: "Question", default: "Hva kan du gjøre?")
    var question: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let answer = H0RIIAssistantBrain.answer(question)
        return .result(dialog: IntentDialog(stringLiteral: answer))
    }
}

struct OpenH0RIIIntent: AppIntent {
    static var title: LocalizedStringResource = "H0RII"
    static var description = IntentDescription("Open H0RII voice/Reise mode.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: "Åpner H0RII.")
    }
}

struct H0RIIShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AskH0RIIIntent(),
            phrases: [
                "Ask \(.applicationName)",
                "Hey \(.applicationName)",
                "Hei \(.applicationName)"
            ],
            shortTitle: "Ask H0RII",
            systemImageName: "waveform.circle.fill"
        )
        AppShortcut(
            intent: OpenH0RIIIntent(),
            phrases: [
                "Open \(.applicationName)",
                "Åpne \(.applicationName)"
            ],
            shortTitle: "Open H0RII",
            systemImageName: "bolt.circle.fill"
        )
    }
}

@MainActor
final class H0RIIBackgroundRefresh {
    static let shared = H0RIIBackgroundRefresh()
    static let taskIdentifier = "dev.horii.H0RIIApp.refresh"

    private init() {}

    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskIdentifier, using: nil) { task in
            guard let task = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            Task { await self.handle(task) }
        }
    }

    func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    func handle(_ task: BGAppRefreshTask) async {
        schedule()
        task.expirationHandler = { task.setTaskCompleted(success: false) }
        await refreshSnapshot()
        task.setTaskCompleted(success: true)
    }

    func refreshSnapshot() async {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "h0rii.lastBackgroundRefresh")
    }
}

@MainActor
final class H0RIINotificationService {
    static let shared = H0RIINotificationService()
    private init() {}

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { allowed, _ in
                continuation.resume(returning: allowed)
            }
        }
    }

    func sendLocalWakeHint() async {
        let allowed = await requestPermission()
        guard allowed else { return }
        let content = UNMutableNotificationContent()
        content.title = "H0RII klar"
        content.body = "For låst skjerm: si ‘Hei Siri, H0RII’. iOS tillater ikke egne alltid-på wake words for tredjepartsapper."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "h0rii-wake-hint", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
