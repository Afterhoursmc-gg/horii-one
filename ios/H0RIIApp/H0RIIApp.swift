import SwiftUI
import BackgroundTasks

@main
@MainActor
struct H0RIIApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        H0RIIBackgroundRefresh.shared.register()
        H0RIIBackgroundRefresh.shared.schedule()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                H0RIIBackgroundRefresh.shared.schedule()
            }
        }
        .backgroundTask(.appRefresh(H0RIIBackgroundRefresh.taskIdentifier)) {
            await H0RIIBackgroundRefresh.shared.refreshSnapshot()
            H0RIIBackgroundRefresh.shared.schedule()
        }
    }
}
