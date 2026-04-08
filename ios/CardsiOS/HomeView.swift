import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: PackStore
    @State private var showingStats = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if let selectedPack = store.selectedPack {
                    selectedPackCard(selectedPack)
                } else {
                    emptyState
                }

                actionButtons

                if let selectedPack = store.selectedPack {
                    quickFacts(for: selectedPack)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("Cards")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingStats) {
            if let selectedPack = store.selectedPack {
                NavigationStack {
                    PackDetailView(pack: selectedPack)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cards Home")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Pick a bundled deck, then launch into a native iPhone session shell.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.top, 8)
    }

    private func selectedPackCard(_ pack: PackRecord) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(pack.badge.uppercased())
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .tracking(1.4)
                        .foregroundStyle(AppTheme.textSecondary)

                    Text(pack.name)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(pack.summary)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Circle()
                    .fill(pack.gradient)
                    .frame(width: 54, height: 54)
                    .overlay(
                        Image(systemName: "suit.heart.fill")
                            .foregroundStyle(.white)
                    )
            }

            Label(pack.titleLine, systemImage: "sparkles")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.10), in: Capsule())
        }
        .surfaceCard()
        .background(pack.gradient.opacity(0.30), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                store.startSession()
            } label: {
                Label("Play / Resume", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())

            HStack(spacing: 12) {
                Button {
                    showingStats = true
                } label: {
                    Label("View Stats", systemImage: "chart.bar.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    store.restartSession()
                    store.startSession()
                } label: {
                    Label("Restart", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            Button(role: .destructive) {
                store.closeSession()
            } label: {
                Label("Close Game", systemImage: "xmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(DestructiveButtonStyle())
        }
    }

    private func quickFacts(for pack: PackRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Configuration")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            ForEach(pack.configItems.prefix(5), id: \.key) { item in
                HStack {
                    Text(item.key.replacingOccurrences(of: "_", with: " ").capitalized)
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Text(item.value)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .font(.system(size: 13, weight: .medium, design: .rounded))
            }
        }
        .surfaceCard()
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
            .foregroundStyle(Color.black)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(AppTheme.accent.opacity(configuration.isPressed ? 0.78 : 1.0), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
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
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
    }
}

private struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.white)
            .padding(.vertical, 13)
            .padding(.horizontal, 14)
            .background(Color.red.opacity(configuration.isPressed ? 0.60 : 0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}