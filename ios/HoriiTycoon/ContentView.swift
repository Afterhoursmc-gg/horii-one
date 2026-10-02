import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: TycoonStore
    @State private var scene = TycoonScene()

    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.025, green: 0.035, blue: 0.07).ignoresSafeArea()
            VStack(spacing: 0) {
                header
                Tycoon3DView(store: store, scene: scene)
                    .frame(minHeight: 260, maxHeight: 380)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .padding(.horizontal)
                dashboard
                actions
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) { Text("H0RII TYCOON").font(.system(size: 22, weight: .black, design: .rounded)); Text("Dag \(store.day) · \(store.companyName)").foregroundStyle(.secondary).font(.caption) }
            Spacer()
            Menu { Button("HQ") { store.selectedMap = "HQ" }; Button("Downtown") { store.selectedMap = "Downtown" }; Divider(); Button("Reset save", role: .destructive) { store.reset() } } label: { Label(store.selectedMap, systemImage: "map.fill").font(.caption.bold()).padding(10).background(.white.opacity(0.1), in: Capsule()) }
        }.padding(.horizontal).padding(.top, 12).padding(.bottom, 8)
    }

    private var dashboard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) { stat("CASH", "$\(store.cash)", .green); stat("LIKES", "\(store.likes)", .pink); stat("FOLLOWERS", "\(store.followers)", .cyan); stat("/DAY", "+$\(store.dailyRevenue)", .orange) }
            Text(store.toast).font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.78)).lineLimit(2)
            HStack { TextField("Creator username", text: $store.creatorName).textFieldStyle(.roundedBorder); Button("Profile") { store.createProfile() }.buttonStyle(.borderedProminent).tint(.pink) }
        }.padding(.horizontal).padding(.top, 12)
    }

    private func stat(_ title: String, _ value: String, _ color: Color) -> some View { VStack(alignment: .leading, spacing: 3) { Text(title).font(.system(size: 9, weight: .bold)); Text(value).font(.system(size: 15, weight: .black, design: .rounded)).foregroundStyle(color) }.frame(maxWidth: .infinity, alignment: .leading).padding(9).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12)) }

    private var actions: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) { action("Publish post", "paperplane.fill", .pink) { store.publishPost() }; action("Ship project", "shippingbox.fill", .orange) { store.shipProject() } }
            HStack(spacing: 8) { action("Hire creator", "person.badge.plus", .cyan) { store.hireCreator() }; action("Next day", "sunrise.fill", .green) { store.nextDay() } }
        }.padding().padding(.bottom, 4)
    }

    private func action(_ title: String, _ icon: String, _ tint: Color, _ tap: @escaping () -> Void) -> some View { Button(action: tap) { Label(title, systemImage: icon).font(.subheadline.bold()).frame(maxWidth: .infinity).padding(12) }.buttonStyle(.borderedProminent).tint(tint) }
}
