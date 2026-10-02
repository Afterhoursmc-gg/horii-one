import SwiftUI

struct RootView: View {
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            HoriiAssistantPrototypeView()
                .tabItem { Label("Horii", systemImage: "mic.badge.plus") }
                .tag(1)
            ProjectsView()
                .tabItem { Label("Projects", systemImage: "square.grid.2x2.fill") }
                .tag(2)
            StatusView()
                .tabItem { Label("Status", systemImage: "waveform.path.ecg") }
                .tag(3)
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(4)
        }
        .tint(.white)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    RootView()
}
