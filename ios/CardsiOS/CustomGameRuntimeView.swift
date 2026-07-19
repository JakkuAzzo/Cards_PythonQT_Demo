import SwiftUI

private enum DigitalRoomMode: String, CaseIterable, Identifiable {
    case combined = "Combined"
    case table = "Table"
    case deck = "Your deck"

    var id: String { rawValue }
}

struct CustomGameRuntimeView: View {
    let manifest: GameManifest

    var body: some View {
        switch manifest.archetype {
        case .poker:
            PokerRuntimeView(manifest: manifest)
        case .guessWho:
            GuessWhoRuntimeView(manifest: manifest)
        case .promptDraw:
            LiveTableView(manifest: manifest)
        }
    }
}

private struct PokerRuntimeView: View {
    @Environment(\.dismiss) private var dismiss
    let manifest: GameManifest
    @StateObject private var game = PokerGame(playerNames: ["You", "Avery", "Jordan", "Riley"])
    @State private var showHands = false
    @State private var roomMode: DigitalRoomMode = .combined
    @State private var showingAR = false
    @StateObject private var sync = GameRoomSyncController()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(manifest.name)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Local Texas Hold’em · deal private cards, reveal community streets, and score the showdown.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)

                DigitalRoomModePicker(selection: $roomMode)
                GameRoomSyncPanel(sync: sync)
                Button {
                    showingAR = true
                } label: {
                    Label("Open AR table", systemImage: "arkit")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TableSecondaryButtonStyle())
                .disabled(!manifest.presentation.supportsAR)

                if roomMode != .deck {
                    pokerTable
                }

                if roomMode != .table {
                    pokerDeck
                }
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear(perform: configureSync)
        .navigationTitle("Poker table")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.foregroundStyle(AppTheme.accent) } }
        .sheet(isPresented: $showingAR) {
            ARTableModeView(
                card: .init(id: "poker-\(game.street.rawValue)", text: "Poker · \(game.street.rawValue) · pot \(game.pot)"),
                manifest: manifest
            )
        }
    }

    private var pokerTable: some View {
        Group {
            VStack(spacing: 10) {
                    HStack {
                        Label(game.street.rawValue, systemImage: "circle.hexagongrid.fill")
                        Spacer()
                        Text("Pot \(game.pot)")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.accent)
                    Text(game.actionMessage)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            .surfaceCard()

            VStack(alignment: .leading, spacing: 10) {
                    Text("Community cards")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    HStack(spacing: 8) {
                        ForEach(Array(game.communityCards.enumerated()), id: \.offset) { _, card in PokerCardTile(card: card) }
                        ForEach(game.communityCards.count..<5, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 48, height: 68)
                        }
                    }
                }
            .surfaceCard()

            VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Players")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Spacer()
                        Button(showHands ? "Hide hands" : "Show hands") { showHands.toggle() }
                            .buttonStyle(TableSecondaryButtonStyle())
                    }
                    ForEach(game.players) { player in
                        HStack(spacing: 10) {
                            Circle().fill(player.folded ? Color.gray : AppTheme.accent).frame(width: 9, height: 9)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(player.name + (player.id == game.players[game.dealerIndex].id ? " · Dealer" : ""))
                                Text(player.folded ? "Folded" : "\(player.chips) chips" + (game.street == .showdown ? " · \(game.score(for: player).label)" : ""))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            Spacer()
                            if showHands || player.name == "You" || game.street == .showdown {
                                HStack(spacing: 4) { ForEach(player.hand) { PokerCardTile(card: $0, compact: true) } }
                            } else {
                                Text("Private").font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }
                    if let winner = game.winner {
                        Label("\(winner.name) wins the pot", systemImage: "trophy.fill")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            .surfaceCard()
        }
    }

    private var pokerDeck: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your deck")
                .font(.system(size: 16, weight: .bold, design: .rounded))
            HStack(spacing: 12) {
                ForEach(game.players[0].hand) { PokerCardTile(card: $0) }
                Spacer()
                Text(game.players[0].folded ? "Folded" : "Private hand")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.bottom, 4)
            .surfaceCard()
            HStack(spacing: 12) {
                Button(game.street.nextLabel) { pokerAction("advance-street") }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(TablePrimaryButtonStyle())
                Button("Bet 20") { pokerAction("bet", amount: 20) }
                        .buttonStyle(TableSecondaryButtonStyle())
                        .disabled(game.street == .showdown || game.players[0].folded)
                }
            Button("Fold your hand") { pokerAction("fold") }
                    .frame(maxWidth: .infinity)
                .buttonStyle(TableSecondaryButtonStyle())
                .disabled(game.street == .showdown || game.players[0].folded)
        }
    }

    private func pokerAction(_ action: String, amount: Int? = nil) {
        if sync.isGuest { sync.submit(action: action, amount: amount); return }
        switch action {
        case "advance-street": game.advanceStreet()
        case "bet": game.placeBet(for: game.players[0].id, amount: amount ?? 20)
        case "fold": game.fold(playerID: game.players[0].id)
        default: break
        }
        sync.publish()
    }

    private func configureSync() {
        sync.configure(
            kind: .poker,
            onHostCommand: { command in
                switch command.action {
                case "advance-street": game.advanceStreet()
                case "bet": game.placeBet(for: game.players[1].id, amount: command.amount ?? 20)
                case "fold": game.fold(playerID: game.players[1].id)
                default: return false
                }
                return true
            },
            makePublicState: { (try? JSONEncoder().encode(game.publicSnapshot())) ?? Data() },
            makePrivateState: { (try? JSONEncoder().encode(game.players.dropFirst().first?.hand ?? [])) },
            applyPublicState: { data in if let snapshot = try? JSONDecoder().decode(PokerGame.PublicSnapshot.self, from: data) { game.apply(publicSnapshot: snapshot) } },
            applyPrivateState: { data in if let hand = try? JSONDecoder().decode([PlayingCard].self, from: data) { game.applyPrivateHand(hand) } }
        )
    }
}

private struct GuessWhoRuntimeView: View {
    @Environment(\.dismiss) private var dismiss
    let manifest: GameManifest
    @StateObject private var game = GuessWhoGame(playerNames: ["You", "Avery"])
    @State private var selected: GuessWhoGame.Character?
    @State private var roomMode: DigitalRoomMode = .combined
    @State private var showingAR = false
    @State private var revealTarget = false
    @StateObject private var sync = GameRoomSyncController()
    private let columns = [GridItem(.adaptive(minimum: 92), spacing: 10)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(manifest.name)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Each player has a private target. Ask a question, eliminate possibilities, then make one careful guess.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)

                DigitalRoomModePicker(selection: $roomMode)
                GameRoomSyncPanel(sync: sync)
                Button {
                    showingAR = true
                } label: {
                    Label("Open AR board", systemImage: "arkit")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TableSecondaryButtonStyle())
                .disabled(!manifest.presentation.supportsAR)

                if roomMode != .deck {
                    guessTable
                }

                if roomMode != .table {
                    guessDeck
                }
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear(perform: configureSync)
        .navigationTitle("Guess Who")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.foregroundStyle(AppTheme.accent) } }
        .sheet(isPresented: $showingAR) {
            ARTableModeView(
                card: .init(id: "guess-board", text: "Guess Who · \(game.eliminated.count) eliminated · \(game.activePlayer)'s turn"),
                manifest: manifest
            )
        }
    }

    private var guessTable: some View {
        Group {
            VStack(alignment: .leading, spacing: 8) {
                    Label(game.winnerName == nil ? "\(game.activePlayer)’s turn" : "\(game.winnerName!) wins", systemImage: game.winnerName == nil ? "person.crop.circle.fill" : "trophy.fill")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.accent)
                    Text(game.message).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(AppTheme.textSecondary)
                    if let selected { Text("Selected: \(selected.name)").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.textPrimary) }
                }
                .surfaceCard()

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(game.characters) { character in
                        Button {
                            selected = character
                        } label: {
                            GuessCharacterTile(
                                character: character,
                                isEliminated: game.eliminated.contains(character.id),
                                isSelected: selected == character
                            )
                        }
                        .disabled(game.winnerName != nil)
                    }
                }
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Shared board", systemImage: "person.3.fill")
                    Spacer()
                    Text("\(game.characters.count - game.eliminated.count) possible")
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.accent)
                Text("For Guess Who, the Table page is the shared board and score tracker—not a physical card table.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .surfaceCard()
        }
    }

    private var guessDeck: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your deck")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                if let target = game.targets[game.players.first ?? "You"] {
                    Text(revealTarget ? target.name : "Private target hidden")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(revealTarget ? "Keep this card private from the other player." : "Reveal only when the device is in your hands.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                    Button(revealTarget ? "Hide target" : "Reveal target") { revealTarget.toggle() }
                        .buttonStyle(TableSecondaryButtonStyle())
                }
            }
            .surfaceCard()

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button("Ask question") { guessAction("ask-question") }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(TablePrimaryButtonStyle())
                    Button("Eliminate") { if let selected { guessAction("toggle-elimination", character: selected) } }
                        .buttonStyle(TableSecondaryButtonStyle())
                        .disabled(selected == nil || game.winnerName != nil)
                }
                Button("Guess selected character") { if let selected { guessAction("guess", character: selected) } }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(TableSecondaryButtonStyle())
                    .disabled(selected == nil || game.winnerName != nil)
                Button("New game") { selected = nil; if sync.isGuest { sync.submit(action: "restart") } else { game.restart(); sync.publish() } }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(TableSecondaryButtonStyle())
            }
        }
    }

    private func guessAction(_ action: String, character: GuessWhoGame.Character? = nil) {
        if sync.isGuest { sync.submit(action: action, characterID: character?.id); return }
        switch action {
        case "ask-question": game.askQuestion()
        case "toggle-elimination": if let character { game.toggleElimination(character) }
        case "guess": if let character { game.guess(character) }
        default: break
        }
        sync.publish()
    }

    private func configureSync() {
        sync.configure(
            kind: .guessWho,
            onHostCommand: { command in
                switch command.action {
                case "ask-question": game.askQuestion()
                case "toggle-elimination": guard let id = command.characterID, let character = game.characters.first(where: { $0.id == id }) else { return false }; game.toggleElimination(character)
                case "guess": guard let id = command.characterID, let character = game.characters.first(where: { $0.id == id }) else { return false }; game.guess(character)
                case "restart": game.restart()
                default: return false
                }
                return true
            },
            makePublicState: { (try? JSONEncoder().encode(game.publicSnapshot())) ?? Data() },
            makePrivateState: { guard let target = game.targets[game.players.dropFirst().first ?? ""] else { return nil }; return try? JSONEncoder().encode(target.id) },
            applyPublicState: { data in if let snapshot = try? JSONDecoder().decode(GuessWhoGame.PublicSnapshot.self, from: data) { game.apply(publicSnapshot: snapshot) } },
            applyPrivateState: { data in if let id = try? JSONDecoder().decode(String.self, from: data) { game.applyPrivateTarget(id: id) } }
        )
    }
}

private struct PokerCardTile: View {
    let card: PlayingCard
    var compact = false

    var body: some View {
        Text("\(card.rank.rawValue)\(card.suit.rawValue)")
            .font(.system(size: compact ? 14 : 18, weight: .bold, design: .rounded))
            .foregroundStyle(card.suit.isRed ? Color.red : Color.black)
            .frame(width: compact ? 34 : 48, height: compact ? 46 : 68)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct GuessCharacterTile: View {
    let character: GuessWhoGame.Character
    let isEliminated: Bool
    let isSelected: Bool

    var body: some View {
        let background = isEliminated ? Color.gray.opacity(0.25) : (isSelected ? AppTheme.accent.opacity(0.5) : Color.white.opacity(0.08))
        Text(character.name)
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity, minHeight: 62)
            .foregroundStyle(isEliminated ? AppTheme.textSecondary : AppTheme.textPrimary)
            .background(background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(isSelected ? AppTheme.accent : Color.clear, lineWidth: 2))
    }
}

private struct DigitalRoomModePicker: View {
    @Binding var selection: DigitalRoomMode

    var body: some View {
        Picker("Digital view", selection: $selection) {
            ForEach(DigitalRoomMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Digital game room view")
    }
}

private struct GameRoomSyncPanel: View {
    @ObservedObject var sync: GameRoomSyncController
    @State private var transport: GameRoomSyncController.TransportKind = .bluetooth
    @State private var joinCode = ""
    @State private var joinSecret = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Nearby room", systemImage: "dot.radiowaves.left.and.right")
                Spacer()
                Picker("Transport", selection: $transport) {
                    ForEach(GameRoomSyncController.TransportKind.allCases) { Text($0.rawValue).tag($0) }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(AppTheme.accent)

            Text(sync.status)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            if !sync.roomCode.isEmpty {
                Text("Room: \(sync.roomCode)" + (sync.pairingSecret.isEmpty ? "" : " · Secret: \(sync.pairingSecret)"))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .textSelection(.enabled)
            }
            HStack(spacing: 10) {
                Button("Host") { sync.host(using: transport) }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(TablePrimaryButtonStyle())
                Button("Leave") { sync.disconnect() }
                    .buttonStyle(TableSecondaryButtonStyle())
            }
            TextField("Room code", text: $joinCode)
                .textInputAutocapitalization(.characters)
                .textFieldStyle(.roundedBorder)
            if transport == .bluetooth {
                SecureField("Pairing secret", text: $joinSecret)
                    .textFieldStyle(.roundedBorder)
            }
            Button("Join nearby room") { sync.join(code: joinCode, pairingSecret: joinSecret, using: transport) }
                .frame(maxWidth: .infinity)
                .buttonStyle(TableSecondaryButtonStyle())
        }
        .surfaceCard()
    }
}
