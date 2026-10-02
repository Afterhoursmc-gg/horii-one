import Foundation

@MainActor
final class HoriiWebSocketClient: NSObject, ObservableObject {
    @Published private(set) var isConnected = false
    @Published private(set) var lastEvent: HoriiRealtimeEvent?

    private let environment: AppEnvironment
    private let auth: HoriiAuthManager
    private let session: URLSession
    private var task: URLSessionWebSocketTask?
    private var reconnectAttempt = 0
    private var shouldReconnect = false

    override init() {
        self.environment = .current
        self.auth = HoriiAuthManager()
        self.session = .shared
        super.init()
    }

    init(environment: AppEnvironment, auth: HoriiAuthManager, session: URLSession) {
        self.environment = environment
        self.auth = auth
        self.session = session
        super.init()
    }

    func connect() {
        guard !shouldReconnect else { return }
        guard let token = auth.token() else { return }
        shouldReconnect = true
        reconnectAttempt = 0
        open(token: token)
    }

    func disconnect() {
        shouldReconnect = false
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        isConnected = false
    }

    private func open(token: String) {
        guard shouldReconnect else { return }
        var components = URLComponents(url: environment.apiBaseURL, resolvingAgainstBaseURL: false)
        components?.scheme = environment.apiBaseURL.scheme == "https" ? "wss" : "ws"
        components?.path = "/api/v1/realtime"
        components?.queryItems = [URLQueryItem(name: "token", value: token)]
        guard let url = components?.url else { return }

        let socket = session.webSocketTask(with: url)
        task = socket
        socket.resume()
        isConnected = true
        listen()
    }

    private func listen() {
        task?.receive { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case let .success(message):
                    self.handle(message)
                    self.listen()
                case .failure:
                    self.isConnected = false
                    self.scheduleReconnect()
                }
            }
        }
    }

    private func handle(_ message: URLSessionWebSocketTask.Message) {
        let data: Data?
        switch message {
        case let .data(value): data = value
        case let .string(value): data = value.data(using: .utf8)
        @unknown default: data = nil
        }
        guard let data, let event = try? JSONDecoder.horiiRealtime.decode(HoriiRealtimeEvent.self, from: data) else { return }
        lastEvent = event
        if event.type == "assistant.state", event.data["state"] == "connected" {
            isConnected = true
            reconnectAttempt = 0
        }
    }

    private func scheduleReconnect() {
        guard shouldReconnect else { return }
        reconnectAttempt += 1
        let capped = min(reconnectAttempt, 6)
        let delay = min(pow(2.0, Double(capped)), 30.0) + Double.random(in: 0...0.5)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard self.shouldReconnect, let token = self.auth.token() else { return }
            self.open(token: token)
        }
    }
}

struct HoriiRealtimeEvent: Codable, Identifiable {
    let type: String
    let id: String
    let timestamp: Date
    let data: [String: String]
}

private extension JSONDecoder {
    static var horiiRealtime: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
