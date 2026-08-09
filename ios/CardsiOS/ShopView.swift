import SwiftUI

struct ShopView: View {
    @EnvironmentObject private var store: PackStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                NavigationLink {
                    CustomGameRuntimeView(manifest: .dominoes)
                } label: {
                    dominoesCard
                }
                .buttonStyle(.plain)

                ForEach(store.packs.filter(\.featured)) { pack in
                    Button {
                        store.select(pack)
                    } label: {
                        featuredCard(pack)
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("No account required", systemImage: "lock.shield.fill")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Every deck in this build is included and works offline. A real catalogue can replace this view when pack delivery and purchases exist.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .surfaceCard()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Discover")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Included games and decks worth trying next.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var dominoesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Label("NEW BUILT-IN GAME", systemImage: "square.grid.2x2.fill")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.76))
                    Text("Double-Six Dominoes")
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Place matching tiles on a shared table. Each player gets a private hand view.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.76))
                }
                Spacer()
                DominoesDiscoverTile(left: 6, right: 4)
            }

            HStack {
                Label("2–4 players", systemImage: "person.2.fill")
                Spacer()
                Label("Play now", systemImage: "arrow.right.circle.fill")
            }
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.90))
        }
        .padding(18)
        .background(LinearGradient(colors: [Color(hex: "0F766E"), Color(hex: "0891B2")], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white.opacity(0.18), lineWidth: 1))
    }

    private func featuredCard(_ pack: PackRecord) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(pack.gradient)
                .frame(height: 160)
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(pack.badge.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.3)
                            .foregroundStyle(.white.opacity(0.76))
                        Text(pack.name)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(18)
                }

            HStack(alignment: .top) {
                Text(pack.summary)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer(minLength: 12)
                Text(store.selectedPack?.id == pack.id ? "Selected" : "Choose")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(store.selectedPack?.id == pack.id ? Color.black : AppTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(store.selectedPack?.id == pack.id ? AppTheme.accent : Color.white.opacity(0.10), in: Capsule())
            }
        }
        .surfaceCard()
    }
}

private struct DominoesDiscoverTile: View {
    let left: Int
    let right: Int

    var body: some View {
        HStack(spacing: 5) {
            Text("\(left)")
            Rectangle().fill(Color.black.opacity(0.18)).frame(width: 1)
            Text("\(right)")
        }
        .font(.system(size: 22, weight: .bold, design: .rounded))
        .foregroundStyle(AppTheme.ink)
        .frame(width: 72, height: 50)
        .background(Color(red: 0.97, green: 0.95, blue: 0.88), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .rotationEffect(.degrees(8))
    }
}
