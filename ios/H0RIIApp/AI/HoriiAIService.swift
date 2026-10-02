import Foundation

struct HoriiAIConfiguration: Sendable {
    var endpoint: URL?
    var apiKey: String?

    static let mock = HoriiAIConfiguration(endpoint: nil, apiKey: nil)
}

protocol HoriiAIService: Sendable {
    func send(message: String) async throws -> String
}

struct MockHoriiAIService: HoriiAIService {
    func send(message: String) async throws -> String {
        let text = message.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let math = SimpleCalculator.evaluate(text
            .replacingOccurrences(of: "hva er", with: "")
            .replacingOccurrences(of: "ka er", with: "")
            .replacingOccurrences(of: "en", with: "1")
            .replacingOccurrences(of: "ett", with: "1")
            .replacingOccurrences(of: "to", with: "2")
            .replacingOccurrences(of: "pluss", with: "+")) {
            return "Svaret er \(math.cleanString)."
        }
        if text.contains("buss") || text.contains("reise") {
            return "Jeg kan planlegge reisen inne i Horii. Åpne Reise-fanen for fra og til-søk."
        }
        if text.contains("hva kan du") || text.contains("hjelp") {
            return "Jeg kan lytte etter Hei Horii, transkribere kommandoer, sende dem til Horii AI, lese svaret høyt og gå tilbake til wake-word-modus."
        }
        return "Mock Horii AI hørte: \(message). Koble HoriiAIService til backend senere for ekte svar."
    }
}

struct HTTPHoriiAIService: HoriiAIService {
    let configuration: HoriiAIConfiguration

    func send(message: String) async throws -> String {
        guard let endpoint = configuration.endpoint else {
            return try await MockHoriiAIService().send(message: message)
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = configuration.apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(["message": message])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(HoriiAIResponse.self, from: data)
        return decoded.answer
    }
}

private struct HoriiAIResponse: Decodable {
    let answer: String
}
