import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: PackStore
    @State private var showingDetails = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                if let selectedPack = store.selectedPack {
                    selectedPackCard(selectedPack)
                    actionButtons
                    quickFacts(for: selectedPack)
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            // Leave room for the floating root dock so the stats card never sits
            // underneath navigation on the initial viewport.
            .padding(.bottom, 100)
        }
        .navigationTitle("Cards")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingDetails) {
            if let selectedPack = store.selectedPack {
                NavigationStack { PackDetailView(pack: selectedPack) }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label("READY WHEN YOU ARE", systemImage: "sparkles")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(AppTheme.accent)

            Text("Deal yourself in.")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Pick a deck and make the next card the moment.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private func selectedPackCard(_ pack: PackRecord) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(pack.badge.uppercased())
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .tracking(1.4)
                        .foregroundStyle(.white.opacity(0.68))

                    Text(pack.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(pack.summary)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.76))
                        .lineLimit(3)
                }

                Spacer()
                deckPreview
            }

            HStack {
                Label(pack.titleLine, systemImage: "rectangle.stack.fill")
                Spacer()
                Label("Offline ready", systemImage: "checkmark.circle.fill")
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.84))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.12), in: Capsule())
        }
        .padding(20)
        .background(pack.gradient, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.28), radius: 20, x: 0, y: 12)
    }

    private var deckPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color.white.opacity(0.20))
                .frame(width: 65, height: 86)
                .rotationEffect(.degrees(8))
                .offset(x: 7, y: 4)

            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color.white)
                .frame(width: 65, height: 86)
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: -2) {
                        Text("A")
                        Image(systemName: "suit.spade.fill")
                            .font(.system(size: 13))
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .padding(9)
                }
                .overlay {
                    Image(systemName: "suit.spade.fill")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                }
        }
        .accessibilityHidden(true)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button { store.startSession() } label: {
                Label("Start a solo game", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())

            HStack(spacing: 12) {
                Button { store.restartSession() } label: {
                    Label("Shuffle", systemImage: "shuffle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())

                Button { showingDetails = true } label: {
                    Label("Deck details", systemImage: "info.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    private func quickFacts(for pack: PackRecord) -> some View {
        let stats = store.stats(for: pack)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Your table, so far")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            HStack(spacing: 12) {
                statTile(value: "\(stats.sessionsStarted)", label: "Sessions")
                statTile(value: "\(stats.cardsDrawn)", label: "Cards drawn")
            }

            Text("Want a different feel? Browse your deck library from the tab bar.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .surfaceCard()
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var emptyState: some View {
        Text("No bundled packs were loaded.")
            .foregroundStyle(AppTheme.textSecondary)
            .surfaceCard()
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(AppTheme.ink)
            .padding(.vertical, 15)
            .padding(.horizontal, 16)
            .background(AppTheme.accent.opacity(configuration.isPressed ? 0.78 : 1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.vertical, 13)
            .padding(.horizontal, 14)
            .background(Color.white.opacity(configuration.isPressed ? 0.08 : 0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.10), lineWidth: 1))
    }
}
