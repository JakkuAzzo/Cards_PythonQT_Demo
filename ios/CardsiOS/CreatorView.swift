import SwiftUI

struct CreatorView: View {
    @EnvironmentObject private var store: PackStore
    @State private var description = """
    idea: four-player poker night
    multiplayer: y
    max_user: 4
    ar: n
    tabledesign: poker_2.png
    """
    @State private var draft: GameManifest?
    @State private var errorMessage: String?
    @State private var showingPreview = false

    private let interpreter = GameDraftInterpreter()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                editor

                Button {
                    createDraft()
                } label: {
                    Label("Build validated draft", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CreatorPrimaryButtonStyle())

                if let draft {
                    preview(draft)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("Create")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPreview) {
            if let draft {
                NavigationStack {
                    CustomGameRuntimeView(manifest: draft)
                }
            }
        }
        .alert("Draft needs attention", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Game Creator")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Text("Describe a known game or provide a few settings. Cards chooses a tested template and bundled resources; it never generates or runs code.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Try poker, guess who, or a custom prompt game with dashed card lines. Settings override template defaults.")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            TextEditor(text: $description)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .scrollContentBackground(.hidden)
                .foregroundStyle(AppTheme.textPrimary)
                .frame(minHeight: 250)
                .padding(12)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .surfaceCard()
    }

    private func preview(_ manifest: GameManifest) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Validated manifest", systemImage: "checkmark.shield.fill")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.green)
            Text(manifest.name)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Text("\(manifest.archetype.rawValue) · \(manifest.players.minimum)–\(manifest.players.maximum) players · \(manifest.resources.tableDesign) · AR \(manifest.capabilities.ar ? "on" : "off")")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)

            Button {
                showingPreview = true
            } label: {
                Label("Play local preview", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CreatorSecondaryButtonStyle())

            Button {
                store.saveDraft(manifest)
            } label: {
                Label("Save to your library", systemImage: "bookmark.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CreatorSecondaryButtonStyle())
            .accessibilityHint("Saves this validated game configuration on this device")
        }
        .surfaceCard()
    }

    private func createDraft() {
        do {
            draft = try interpreter.interpret(description)
        } catch {
            draft = nil
            errorMessage = error.localizedDescription
        }
    }
}

private struct CreatorPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(.black)
            .padding(.vertical, 14)
            .background(AppTheme.accent.opacity(configuration.isPressed ? 0.78 : 1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct CreatorSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.vertical, 13)
            .background(Color.white.opacity(configuration.isPressed ? 0.08 : 0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
