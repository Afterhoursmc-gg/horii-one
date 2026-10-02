import Foundation
import Combine

struct TycoonProject: Identifiable, Codable {
    let id: UUID
    var name: String
    var likes: Int
    var status: String
}

@MainActor
final class TycoonStore: ObservableObject {
    @Published var companyName: String { didSet { save() } }
    @Published var creatorName: String { didSet { save() } }
    @Published private(set) var cash: Int { didSet { save() } }
    @Published private(set) var likes: Int { didSet { save() } }
    @Published private(set) var followers: Int { didSet { save() } }
    @Published private(set) var day: Int { didSet { save() } }
    @Published private(set) var dailyRevenue: Int { didSet { save() } }
    @Published private(set) var projects: [TycoonProject] { didSet { save() } }
    @Published var selectedMap = "HQ"
    @Published private(set) var toast = "Velkommen til H0RII Tycoon"

    private let key = "horii.tycoon.save.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let save = try? JSONDecoder().decode(SaveGame.self, from: data) {
            companyName = save.companyName; creatorName = save.creatorName
            cash = save.cash; likes = save.likes; followers = save.followers
            day = save.day; dailyRevenue = save.dailyRevenue; projects = save.projects
        } else {
            companyName = "H0RII Labs"; creatorName = "horii"
            cash = 5000; likes = 340; followers = 120
            day = 1; dailyRevenue = 420
            projects = [TycoonProject(id: UUID(), name: "H0RII ONE", likes: 180, status: "Live")]
        }
    }

    func publishPost() {
        guard cash >= 150 else { toast = "Du trenger $150 for å publisere"; return }
        cash -= 150; likes += 75; followers += 12
        toast = "Post publisert: +75 likes, +12 followers"
    }

    func shipProject() {
        guard cash >= 500 else { toast = "Du trenger $500 for å shippe"; return }
        cash -= 500; likes += 240; followers += 35; dailyRevenue += 180
        let project = TycoonProject(id: UUID(), name: "Ny H0RII-lansering", likes: 240, status: "Shipped")
        projects.insert(project, at: 0)
        toast = "Prosjekt shippet: +$180 daglig inntekt"
    }

    func hireCreator() {
        guard cash >= 1000 else { toast = "Du trenger $1,000 for å ansette"; return }
        cash -= 1000; dailyRevenue += 200; followers += 80
        toast = "Creator ansatt: +$200 daglig inntekt"
    }

    func createProfile() {
        let clean = creatorName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { toast = "Skriv et creator-navn først"; return }
        followers += 100; likes += 120
        toast = "@\(clean) er live: +100 followers"
    }

    func nextDay() {
        day += 1; cash += dailyRevenue; likes += max(1, followers / 25)
        toast = "Dag \(day): +$\(dailyRevenue) inntekt"
    }

    func reset() {
        UserDefaults.standard.removeObject(forKey: key)
        companyName = "H0RII Labs"; creatorName = "horii"
        cash = 5000; likes = 340; followers = 120; day = 1; dailyRevenue = 420
        projects = [TycoonProject(id: UUID(), name: "H0RII ONE", likes: 180, status: "Live")]
        toast = "Spillet er startet på nytt"
    }

    private func save() {
        let save = SaveGame(companyName: companyName, creatorName: creatorName, cash: cash,
                            likes: likes, followers: followers, day: day,
                            dailyRevenue: dailyRevenue, projects: projects)
        if let data = try? JSONEncoder().encode(save) { UserDefaults.standard.set(data, forKey: key) }
    }

    private struct SaveGame: Codable {
        var companyName: String; var creatorName: String; var cash: Int
        var likes: Int; var followers: Int; var day: Int; var dailyRevenue: Int
        var projects: [TycoonProject]
    }
}
