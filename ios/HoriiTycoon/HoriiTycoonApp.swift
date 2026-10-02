import SwiftUI

@main
struct HoriiTycoonApp: App {
    @StateObject private var store = TycoonStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
