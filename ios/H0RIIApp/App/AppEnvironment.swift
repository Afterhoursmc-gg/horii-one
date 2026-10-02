import Foundation

enum HoriiEnvironment: String {
    case development
    case staging
    case production
}

struct AppEnvironment {
    let name: HoriiEnvironment
    let apiBaseURL: URL

    static let current: AppEnvironment = {
        let rawName = (Bundle.main.object(forInfoDictionaryKey: "HORII_ENVIRONMENT") as? String) ?? "production"
        let name = HoriiEnvironment(rawValue: rawName) ?? .production
        let rawURL = (Bundle.main.object(forInfoDictionaryKey: "HORII_API_BASE_URL") as? String) ?? "https://api.horii.dev"
        let url = URL(string: rawURL.trimmingCharacters(in: .whitespacesAndNewlines)) ?? URL(string: "https://api.horii.dev")!
        return AppEnvironment(name: name, apiBaseURL: url)
    }()
}
