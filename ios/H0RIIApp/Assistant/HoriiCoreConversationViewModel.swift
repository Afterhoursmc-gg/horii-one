import Foundation
import UIKit

@MainActor
final class HoriiCoreConversationViewModel: ObservableObject {
    @Published private(set) var connectionState = "CORE not connected"
    @Published private(set) var messages: [HoriiMessage] = []
    @Published var draft = ""
    @Published private(set) var isSending = false
    @Published private(set) var lastError: String?

    private let api: HoriiAPIClient
    private var conversationID: String?

    init(api: HoriiAPIClient = HoriiAPIClient()) {
        self.api = api
    }

    func connect() async {
        do {
            if api.auth.isAuthenticated {
                _ = try await api.currentDevice()
            } else {
                let identifier = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
                _ = try await api.registerCurrentDevice(
                    name: "H0RII ONE",
                    identifier: identifier,
                    capabilities: [
                        "microphone": true,
                        "speaker": true,
                        "camera": true,
                        "display": true,
                        "notifications": false,
                    ]
                )
            }
            if conversationID == nil {
                let conversation = try await api.createConversation(title: "H0RII ONE")
                conversationID = conversation.id
            }
            connectionState = "CORE ONLINE"
            lastError = nil
        } catch {
            connectionState = "CORE OFFLINE"
            lastError = error.localizedDescription
        }
    }

    func sendDraft() async {
        let message = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        isSending = true
        lastError = nil
        do {
            if conversationID == nil { await connect() }
            guard let conversationID else { throw HoriiCoreError.notConnected }
            messages = try await api.send(message: message, conversationID: conversationID)
            draft = ""
            connectionState = "CORE ONLINE"
        } catch {
            connectionState = "CORE OFFLINE"
            lastError = error.localizedDescription
        }
        isSending = false
    }

    func refreshHistory() async {
        guard let conversationID else { return }
        do {
            messages = try await api.history(conversationID: conversationID)
        } catch {
            connectionState = "CORE OFFLINE"
            lastError = error.localizedDescription
        }
    }
}

enum HoriiCoreError: LocalizedError {
    case notConnected
    var errorDescription: String? { "H0RII ONE is not connected to H0RII CORE yet." }
}
