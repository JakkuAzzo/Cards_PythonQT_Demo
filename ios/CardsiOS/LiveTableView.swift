import SwiftUI

struct LiveTableView: View {
    @StateObject private var session: NearbyTableSession
    @State private var nextGuestNumber = 1
    @State private var errorMessage: String?
    @State private var showingAR = false
    @State private var joinCode = ""

    init(manifest: GameManifest = .tableTalk) {
        _session = StateObject(wrappedValue: NearbyTableSession(manifest: manifest))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                connectionCard

                if session.state.phase == .lobby {
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
        .onAppear {
            perform { try session.beginLocalPreview() }
        }
        .alert("Cannot continue", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .sheet(isPresented: $showingAR) {
            ARTableModeView(card: session.state.currentCard, manifest: session.manifest)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(session.manifest.name)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Text("Host nearby games without a Wi-Fi network, or keep play on one device.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var connectionCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.role.label)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(session.statusMessage)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Circle()
                    .fill(session.role == .localPreview ? Color.orange : Color.green)
                    .frame(width: 10, height: 10)
            }
            if session.role == .localPreview {
                Button {
                    perform { try session.host() }
                } label: {
                    Label("Host nearby table", systemImage: "dot.radiowaves.left.and.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TablePrimaryButtonStyle())

                HStack(spacing: 10) {
                    TextField("Table code", text: $joinCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                    Button("Join") { session.join(code: joinCode) }
                        .buttonStyle(TableSecondaryButtonStyle())
                }
            } else {
                HStack {
                    if session.role == .host {
                        Label(session.sessionCode, systemImage: "number")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.accent)
                    }
                    Spacer()
                    Text("\(session.connectedPeers.count) connected")
                        .foregroundStyle(AppTheme.textSecondary)
                    Button("Leave") { session.disconnect() }
                        .buttonStyle(TableSecondaryButtonStyle())
                }
            }
        }
        .surfaceCard()
    }

    private var lobby: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Players")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            ForEach(session.state.players) { player in
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
                if session.role == .localPreview {
                    Button {
                        addGuest()
                    } label: {
                        Label("Add local player", systemImage: "person.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(TableSecondaryButtonStyle())
                    .disabled(session.state.players.count >= session.manifest.players.maximum)
                }
                Button {
                    perform { try session.start() }
                } label: {
                    Label(session.role == .guest ? "Ask host to start" : "Start", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TablePrimaryButtonStyle())
                .disabled(session.state.players.count < session.manifest.players.minimum || session.role == .guest)
            }
        }
        .surfaceCard()
    }

    private var table: some View {
        VStack(spacing: 16) {
            HStack {
                Label(session.state.activePlayer?.name ?? "Finished", systemImage: "person.crop.circle.fill")
                Spacer()
                Text("\(session.state.drawPile.count) cards left")
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.textSecondary)

            Group {
                if let card = session.state.currentCard {
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
                            colors: [Color(hex: session.manifest.presentation.accentStartHex), Color(hex: session.manifest.presentation.accentEndHex)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 28, style: .continuous)
                    )
                } else {
                    VStack(spacing: 14) {
                        Image(systemName: session.state.phase == .finished ? "checkmark.circle.fill" : "rectangle.stack.fill")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(AppTheme.accent)
                        Text(session.state.phase == .finished ? "Game complete" : "Ready to draw")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 260)
                    .surfaceCard()
                }
            }

            if session.state.phase == .waitingForDraw, session.state.activePlayer != nil {
                Button {
                    perform { try session.draw() }
                } label: {
                    Label("Draw for \(session.state.activePlayer?.name ?? "player")", systemImage: "hand.tap.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TablePrimaryButtonStyle())
            } else if session.state.phase == .showingCard, session.state.activePlayer != nil {
                Button {
                    perform { try session.endTurn() }
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
                .disabled(!session.manifest.presentation.supportsAR)

                Button {
                    perform { try session.beginLocalPreview() }
                } label: {
                    Label("Reset", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TableSecondaryButtonStyle())
            }
        }
    }

    private func addGuest() {
        let number = nextGuestNumber
        nextGuestNumber += 1
        // Local preview stays available for one-device sessions and screenshots.
        // Actual nearby participants are admitted by the host after a hello envelope.
        perform { try session.addLocalPreviewGuest(id: "guest-\(number)", name: "Player \(number + 1)") }
    }

    private func perform(_ operation: () throws -> Void) {
        do {
            try operation()
        } catch {
            errorMessage = String(describing: error)
        }
    }
}

struct TablePrimaryButtonStyle: ButtonStyle {
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

struct TableSecondaryButtonStyle: ButtonStyle {
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
