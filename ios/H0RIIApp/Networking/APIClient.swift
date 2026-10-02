import Foundation

@MainActor
struct HoriiAPIClient {
    let environment: AppEnvironment
    let session: URLSession
    let auth: HoriiAuthManager

    init() {
        self.environment = .current
        self.session = .shared
        self.auth = HoriiAuthManager()
    }

    init(environment: AppEnvironment, session: URLSession, auth: HoriiAuthManager) {
        self.environment = environment
        self.session = session
        self.auth = auth
    }

    func registerCurrentDevice(name: String, identifier: String, capabilities: [String: Bool]) async throws -> HoriiDeviceCredential {
        let payload = HoriiDeviceRegistration(
            name: name,
            deviceIdentifier: identifier,
            deviceType: "ios_native",
            capabilities: capabilities
        )
        let credential: HoriiDeviceCredential = try await request(
            path: "/api/v1/auth/device",
            method: "POST",
            body: payload,
            authenticated: false
        )
        try await MainActor.run { try auth.save(credential) }
        return credential
    }

    func currentDevice() async throws -> HoriiDevice {
        try await request(path: "/api/v1/devices/me", method: "GET", authenticated: true)
    }

    func createConversation(title: String = "New conversation") async throws -> HoriiConversation {
        try await request(
            path: "/api/v1/conversations",
            method: "POST",
            body: ["title": title],
            authenticated: true
        )
    }

    func send(message: String, conversationID: String) async throws -> [HoriiMessage] {
        try await request(
            path: "/api/v1/conversations/\(conversationID)/messages",
            method: "POST",
            body: ["content": message],
            authenticated: true
        )
    }

    func history(conversationID: String) async throws -> [HoriiMessage] {
        try await request(
            path: "/api/v1/conversations/\(conversationID)",
            method: "GET",
            authenticated: true
        )
    }

    private func request<Response: Decodable, Body: Encodable>(
        path: String,
        method: String,
        body: Body? = nil,
        authenticated: Bool
    ) async throws -> Response {
        var request = URLRequest(url: environment.apiBaseURL.appending(path: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authenticated, let token = await MainActor.run(body: { auth.token() }) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body { request.httpBody = try JSONEncoder.horii.encode(body) }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw HoriiAPIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw HoriiAPIError.http(statusCode: http.statusCode, body: String(data: data, encoding: .utf8))
        }
        return try JSONDecoder.horii.decode(Response.self, from: data)
    }

    private func request<Response: Decodable>(
        path: String,
        method: String,
        authenticated: Bool
    ) async throws -> Response {
        try await request(path: path, method: method, body: Optional<String>.none, authenticated: authenticated)
    }
}

private extension JSONEncoder {
    static var horii: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var horii: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

enum HoriiAPIError: LocalizedError {
    case invalidResponse
    case http(statusCode: Int, body: String?)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "H0RII CORE returned an invalid response."
        case let .http(statusCode, body): "H0RII CORE returned HTTP \(statusCode): \(body ?? "no details")"
        }
    }
}
