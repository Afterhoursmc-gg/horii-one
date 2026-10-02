import Foundation
import SwiftUI

struct H0RIIProject: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let subtitle: String
    let status: String
    let accent: String
    let url: String
    let metric: String
    let icon: String
    let category: String

    static let samples: [H0RIIProject] = [
        .init(name: "H0RII Labs", subtitle: "Software, infrastructure and product systems", status: "Building", accent: "blue", url: "https://horii.dev", metric: "Core", icon: "sparkles", category: "Company"),
        .init(name: "AfterHoursMC", subtitle: "Minecraft network, community and hosting systems", status: "Live", accent: "purple", url: "https://afterhoursmc.gg", metric: "SMP", icon: "gamecontroller.fill", category: "Gaming"),
        .init(name: "HXSecurity", subtitle: "Consent-first security tooling and reports", status: "In progress", accent: "red", url: "https://hxsecurity.net", metric: "Labs", icon: "shield.lefthalf.filled", category: "Security"),
        .init(name: "H0RII Excel", subtitle: "Web spreadsheet app for clean workflows", status: "Beta", accent: "green", url: "https://excel.horii.dev", metric: "PWA", icon: "tablecells.fill", category: "Product")
    ]
}

struct H0RIIService: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let value: String
    let detail: String
    let symbol: String
    let tint: Color

    static let live: [H0RIIService] = [
        .init(name: "Web", value: "Online", detail: "horii.dev and project pages", symbol: "globe", tint: .green),
        .init(name: "Discord", value: "Active", detail: "Bots and community systems", symbol: "message.fill", tint: .blue),
        .init(name: "Minecraft", value: "Live", detail: "AfterHoursMC network", symbol: "cube.fill", tint: .purple),
        .init(name: "Security", value: "Building", detail: "HXSecurity modules", symbol: "lock.shield.fill", tint: .red)
    ]
}

struct H0RIIUpdate: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let body: String
    let time: String
    let symbol: String

    static let feed: [H0RIIUpdate] = [
        .init(title: "iOS app upgraded", body: "Dashboard, status, favorites, search and public stats are being built out.", time: "Now", symbol: "iphone"),
        .init(title: "H0RII web live", body: "Entity pages and project links are available from horii.dev.", time: "Today", symbol: "safari.fill"),
        .init(title: "AfterHoursMC connected", body: "Community, store and server links are grouped in one place.", time: "Today", symbol: "gamecontroller.fill")
    ]
}

struct AfterHoursPublicStats: Codable, Equatable {
    var servers: Int?
    var playersOnline: Int?
    var nodes: Int?
    var customers: Int?
    var uptime: Double?
    var updatedAt: String?

    static let fallback = AfterHoursPublicStats(
        servers: 481,
        playersOnline: 32191,
        nodes: 8,
        customers: 20000,
        uptime: 99.99,
        updatedAt: "Founder-provided"
    )
}

@MainActor
final class PublicStatsStore: ObservableObject {
    @Published var stats: AfterHoursPublicStats = .fallback
    @Published var isLoading = false
    @Published var lastError: String?

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        guard let url = URL(string: "https://horii.dev/api/public/stats") else { return }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            stats = try JSONDecoder().decode(AfterHoursPublicStats.self, from: data)
        } catch {
            lastError = "Using cached founder-provided stats"
            stats = .fallback
        }
    }
}

extension H0RIIProject {
    var color: Color {
        switch accent {
        case "purple": return .purple
        case "red": return .red
        case "green": return .green
        default: return .blue
        }
    }
}

extension Int {
    var compactFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: self)) ?? String(self)
    }
}
