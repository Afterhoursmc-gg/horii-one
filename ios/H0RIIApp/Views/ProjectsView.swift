import SwiftUI

struct ProjectsView: View {
    let projects = H0RIIProject.samples
    @State private var searchText = ""
    @AppStorage("favoriteProjectNames") private var favoriteProjectNames = ""

    private var favorites: Set<String> {
        Set(favoriteProjectNames.split(separator: ",").map(String.init))
    }

    private var filteredProjects: [H0RIIProject] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return projects }
        return projects.filter { project in
            project.name.localizedCaseInsensitiveContains(searchText)
            || project.subtitle.localizedCaseInsensitiveContains(searchText)
            || project.category.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                H0RIIBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Projects")
                            .font(.largeTitle.bold())
                        Text("Everything important grouped into one native iOS interface.")
                            .foregroundStyle(.secondary)

                        SearchField(text: $searchText)

                        if !favorites.isEmpty {
                            SectionTitle("Favorites")
                            ForEach(projects.filter { favorites.contains($0.name) }) { project in
                                projectLink(project)
                            }
                        }

                        SectionTitle(searchText.isEmpty ? "All projects" : "Results")
                        ForEach(filteredProjects) { project in
                            projectLink(project)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Projects")
        }
    }

    private func projectLink(_ project: H0RIIProject) -> some View {
        Link(destination: URL(string: project.url)!) {
            ProjectRow(
                project: project,
                isFavorite: favorites.contains(project.name),
                toggleFavorite: { toggleFavorite(project.name) }
            )
        }
        .buttonStyle(.plain)
    }

    private func toggleFavorite(_ name: String) {
        var next = favorites
        if next.contains(name) { next.remove(name) } else { next.insert(name) }
        favoriteProjectNames = next.sorted().joined(separator: ",")
    }
}

struct SearchField: View {
    @Binding var text: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search projects", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
    }
}

struct ProjectRow: View {
    let project: H0RIIProject
    let isFavorite: Bool
    let toggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 16)
                .fill(project.color.opacity(0.85))
                .frame(width: 58, height: 58)
                .overlay(Image(systemName: project.icon).font(.title2.bold()).foregroundStyle(.white))
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(project.name).font(.headline).foregroundStyle(.white)
                    Spacer()
                    Text(project.metric).font(.caption.bold()).foregroundStyle(project.color)
                }
                Text(project.subtitle).font(.subheadline).foregroundStyle(.secondary)
                HStack {
                    Text(project.status).font(.caption.bold()).foregroundStyle(project.color)
                    Text("•")
                    Text(project.category).font(.caption).foregroundStyle(.secondary)
                }
            }
            Button(action: toggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(isFavorite ? .yellow : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.08)))
    }
}

#Preview { ProjectsView() }
