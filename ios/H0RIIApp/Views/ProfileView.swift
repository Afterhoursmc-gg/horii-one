import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                H0RIIBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        avatar
                        Text("Jhonatan Wik")
                            .font(.largeTitle.bold())
                        Text("H0RII / Horii")
                            .foregroundStyle(.secondary)
                        Text("Norwegian digital creator, developer and entrepreneur building software, Minecraft infrastructure, SaaS products and digital systems.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        HStack(spacing: 12) {
                            ProfileLink(title: "Profile", icon: "person.text.rectangle.fill", url: "https://horii.dev/jhonatan-wik")
                            ProfileLink(title: "GitHub", icon: "chevron.left.forwardslash.chevron.right", url: "https://github.com/Afterhoursmc-gg")
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle("App roadmap")
                            RoadmapRow(done: true, title: "Native iOS shell", text: "SwiftUI tabs, H0RII branding and project links.")
                            RoadmapRow(done: true, title: "Status tab", text: "Local status snapshot for web, Discord, Minecraft and security.")
                            RoadmapRow(done: false, title: "Live APIs", text: "Connect to status.horii.dev and AfterHours public endpoints.")
                            RoadmapRow(done: false, title: "Push notifications", text: "Notify about incidents, launches and important bot events.")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 24))
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Profile")
        }
    }

    private var avatar: some View {
        Circle()
            .fill(LinearGradient(colors: [.white, .gray], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 96, height: 96)
            .overlay(Text("H").font(.system(size: 46, weight: .black)).foregroundStyle(.black))
            .shadow(color: .white.opacity(0.18), radius: 24)
    }
}

struct ProfileLink: View {
    let title: String
    let icon: String
    let url: String
    var body: some View {
        Link(destination: URL(string: url)!) {
            Label(title, systemImage: icon)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 18))
                .foregroundStyle(.black)
        }
    }
}

struct RoadmapRow: View {
    let done: Bool
    let title: String
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(done ? .green : .secondary)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.bold())
                Text(text).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

#Preview { ProfileView() }
