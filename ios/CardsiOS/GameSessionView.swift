import SwiftUI

struct GameSessionView: View {
    @EnvironmentObject private var store: PackStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var session: GameSession

    init(pack: PackRecord) {
        _session = StateObject(wrappedValue: GameSession(pack: pack))
    }

    var body: some View {
        VStack(spacing: 20) {
            header

            Spacer(minLength: 8)

            if let card = session.currentCard {
                SessionCardView(card: card, pack: session.pack)
                    .id(card.id)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            }

            Spacer(minLength: 8)

            controls
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(session.pack.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    store.closeSession()
                    dismiss()
                }
                .foregroundStyle(AppTheme.accent)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                Label("\(session.cardsDrawn) drawn", systemImage: "rectangle.stack.fill")
                Spacer()
                Text("\(session.cardsRemaining) left")
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.textSecondary)

            ProgressView(value: Double(session.cardsDrawn), total: Double(max(session.totalCards, 1)))
                .tint(AppTheme.accent)
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                    if session.draw() != nil {
                        store.recordCardDrawn(for: session.pack)
                    }
                }
            } label: {
                Label(session.isComplete ? "Deck complete" : "Draw next card", systemImage: session.isComplete ? "checkmark.circle.fill" : "hand.tap.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SessionPrimaryButtonStyle())
            .disabled(session.isComplete)

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    session.restart()
                    store.restartSession()
                }
            } label: {
                Label("Shuffle & restart", systemImage: "shuffle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SessionSecondaryButtonStyle())
        }
    }
}

private struct SessionCardView: View {
    let card: SessionCard
    let pack: PackRecord

    var body: some View {
        Group {
            switch card.content {
            case .playing(let playingCard):
                playingCardView(playingCard)
            case .prompt(let prompt):
                promptCardView(prompt)
            }
        }
        .frame(maxWidth: 330, minHeight: 410, maxHeight: 470)
        .shadow(color: .black.opacity(0.32), radius: 24, x: 0, y: 18)
        .accessibilityElement(children: .combine)
    }

    private func playingCardView(_ card: PlayingCard) -> some View {
        let color: Color = card.suit.isRed ? .red : .black

        return ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white)

            VStack {
                HStack {
                    cardCorner(card, color: color)
                    Spacer()
                }

                Spacer()

                Text(card.suit.rawValue)
                    .font(.system(size: 118, weight: .medium, design: .rounded))
                    .foregroundStyle(color)

                Spacer()

                HStack {
                    Spacer()
                    cardCorner(card, color: color)
                        .rotationEffect(.degrees(180))
                }
            }
            .padding(24)
        }
    }

    private func cardCorner(_ card: PlayingCard, color: Color) -> some View {
        VStack(spacing: -2) {
            Text(card.rank.rawValue)
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text(card.suit.rawValue)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(color)
    }

    private func promptCardView(_ prompt: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(pack.gradient)

            VStack(alignment: .leading, spacing: 18) {
                Text(pack.badge.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.72))

                Spacer()

                Text(prompt)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.72)

                Spacer()

                Label("Pass the phone after answering", systemImage: "person.2.fill")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
            }
            .padding(28)
        }
    }
}

private struct SessionSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.vertical, 13)
            .padding(.horizontal, 14)
            .background(Color.white.opacity(configuration.isPressed ? 0.08 : 0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct SessionPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(Color.black)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(AppTheme.accent.opacity(configuration.isPressed ? 0.78 : 1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
