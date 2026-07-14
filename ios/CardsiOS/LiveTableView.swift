import SwiftUI

struct LiveTableView: View {
    @StateObject private var engine: MultiplayerEngine
    @State private var nextGuestNumber = 1
    @State private var errorMessage: String?
    @State private var showingAR = false

    init(manifest: GameManifest = .tableTalk) {
        _engine = StateObject(wrappedValue: MultiplayerEngine(manifest: manifest))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                connectionCard

                if engine.state.phase == .lobby {
                    lobby
                } else {
                    table
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("Live Table")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: addHostIfNeeded)
        .alert("Cannot continue", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .sheet(isPresented: $showingAR) {
            ARTableModeView(card: engine.state.currentCard, manifest: engine.manifest)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(engine.manifest.name)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Text("A host-authoritative multiplayer preview using the same state that nearby devices and AR will render.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var connectionCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
            VStack(alignment: .leading, spacing: 3) {
                Text("Local protocol preview")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Loopback transport · revision \(engine.state.revision)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Circle()
                .fill(Color.green)
                .frame(width: 10, height: 10)
        }
        .surfaceCard()
    }

    private var lobby: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Players")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            ForEach(engine.state.players) { player in
                HStack {
                    Image(systemName: player.isHost ? "crown.fill" : "person.fill")
                        .foregroundStyle(player.isHost ? AppTheme.accent : AppTheme.textSecondary)
                    Text(player.name)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text(player.isHost ? "Host" : "Nearby")
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
            }

            HStack(spacing: 12) {
                Button {
                    addGuest()
                } label: {
                    Label("Simulate join", systemImage: "person.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TableSecondaryButtonStyle())
                .disabled(engine.state.players.count >= engine.manifest.players.maximum)

                Button {
                    perform { try engine.handle(.start(seed: 42)) }
                } label: {
                    Label("Start", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TablePrimaryButtonStyle())
                .disabled(engine.state.players.count < engine.manifest.players.minimum)
            }
        }
        .surfaceCard()
    }

    private var table: some View {
        VStack(spacing: 16) {
            HStack {
                Label(engine.state.activePlayer?.name ?? "Finished", systemImage: "person.crop.circle.fill")
                Spacer()
                Text("\(engine.state.drawPile.count) cards left")
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.textSecondary)

            Group {
                if let card = engine.state.currentCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("CURRENT CARD")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.4)
                            .foregroundStyle(.white.opacity(0.72))
                        Spacer()
                        Text(card.text)
                            .font(.system(size: 27, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, minHeight: 320, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: engine.manifest.presentation.accentStartHex), Color(hex: engine.manifest.presentation.accentEndHex)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 28, style: .continuous)
                    )
                } else {
                    VStack(spacing: 14) {
                        Image(systemName: engine.state.phase == .finished ? "checkmark.circle.fill" : "rectangle.stack.fill")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(AppTheme.accent)
                        Text(engine.state.phase == .finished ? "Game complete" : "Ready to draw")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 260)
                    .surfaceCard()
                }
            }

            if engine.state.phase == .waitingForDraw, let playerID = engine.state.activePlayer?.id {
                Button {
                    perform { try engine.handle(.draw(playerID: playerID)) }
                } label: {
                    Label("Draw for \(engine.state.activePlayer?.name ?? "player")", systemImage: "hand.tap.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TablePrimaryButtonStyle())
            } else if engine.state.phase == .showingCard, let playerID = engine.state.activePlayer?.id {
                Button {
                    perform { try engine.handle(.endTurn(playerID: playerID)) }
                } label: {
                    Label("End turn", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TablePrimaryButtonStyle())
            }

            HStack(spacing: 12) {
                Button {
                    showingAR = true
                } label: {
                    Label("AR table", systemImage: "arkit")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TableSecondaryButtonStyle())
                .disabled(!engine.manifest.presentation.supportsAR)

                Button {
                    engine.reset()
                    addHostIfNeeded()
                } label: {
                    Label("Reset", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TableSecondaryButtonStyle())
            }
        }
    }

    private func addHostIfNeeded() {
        guard engine.state.players.isEmpty else { return }
        perform { try engine.handle(.join(id: "host", name: "You")) }
    }

    private func addGuest() {
        let number = nextGuestNumber
        nextGuestNumber += 1
        perform { try engine.handle(.join(id: "guest-\(number)", name: "Player \(number + 1)")) }
    }

    private func perform(_ operation: () throws -> MultiplayerEvent) {
        do {
            _ = try operation()
        } catch {
            errorMessage = String(describing: error)
        }
    }
}

private struct TablePrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(.black)
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(AppTheme.accent.opacity(configuration.isPressed ? 0.78 : 1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .opacity(isEnabled ? 1 : 0.42)
    }
}

private struct TableSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.vertical, 13)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(configuration.isPressed ? 0.08 : 0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .opacity(isEnabled ? 1 : 0.42)
    }
}
