import SwiftUI

struct HoriiCoreChatView: View {
    @StateObject private var model = HoriiCoreConversationViewModel()

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label(model.connectionState, systemImage: model.connectionState == "CORE ONLINE" ? "circle.fill" : "circle.dotted")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(model.connectionState == "CORE ONLINE" ? .green : .yellow)
                Spacer()
                if model.isSending { ProgressView().tint(.white) }
            }

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if model.messages.isEmpty {
                            Text("Skriv til H0RII ONE. Meldingen går til H0RII CORE når backend-URL er konfigurert.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        }
                        ForEach(model.messages) { message in
                            HStack {
                                if message.role == "user" { Spacer(minLength: 35) }
                                Text(message.content)
                                    .font(.subheadline)
                                    .foregroundColor(message.role == "user" ? .black : .white)
                                    .padding(12)
                                    .background(message.role == "user" ? Color.cyan : Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                                if message.role != "user" { Spacer(minLength: 35) }
                            }
                            .id(message.id)
                        }
                    }
                }
                .frame(maxHeight: 250)
                .onChange(of: model.messages.count) { _, _ in
                    if let last = model.messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }

            HStack(spacing: 8) {
                TextField("Skriv til H0RII CORE…", text: $model.draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                Button {
                    Task { await model.sendDraft() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                }
                .disabled(model.isSending || model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let error = model.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 24))
        .task { await model.connect() }
    }
}
