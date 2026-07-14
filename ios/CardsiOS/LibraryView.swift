import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var store: PackStore
    @State private var searchText = ""

    private var visiblePacks: [PackRecord] {
        let packs = store.packs.sorted {
            let leftFavorite = store.isFavorite($0)
            let rightFavorite = store.isFavorite($1)
            return leftFavorite == rightFavorite ? $0.name < $1.name : leftFavorite
        }
        guard !searchText.isEmpty else { return packs }
        return packs.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.summary.localizedCaseInsensitiveContains(searchText) ||
            $0.badge.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if visiblePacks.isEmpty {
                    Text(searchText.isEmpty ? "No bundled packs are available yet." : "No decks match your search.")
                        .foregroundStyle(AppTheme.textSecondary)
                        .surfaceCard()
                } else {
                    ForEach(visiblePacks) { pack in
                        HStack(spacing: 10) {
                            Button {
                                store.select(pack)
                            } label: {
                                PackLibraryRow(pack: pack, isSelected: store.selectedPack?.id == pack.id)
                            }
                            .buttonStyle(.plain)

                            Button {
                                store.toggleFavorite(pack)
                            } label: {
                                Image(systemName: store.isFavorite(pack) ? "star.fill" : "star")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(store.isFavorite(pack) ? AppTheme.accent : AppTheme.textSecondary)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white.opacity(0.08), in: Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(store.isFavorite(pack) ? "Remove \(pack.name) from favourites" : "Add \(pack.name) to favourites")
                        }
                    }
                }

                Button {
                    store.loadPacks()
                } label: {
                    Label("Reload Bundled Packs", systemImage: "arrow.clockwise.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search decks")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Deck Library")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Choose a deck to play. Favourites stay at the top.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}

private struct PackLibraryRow: View {
    let pack: PackRecord
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(pack.gradient)
                .frame(width: 56, height: 72)
                .overlay(
                    Image(systemName: "rectangle.stack.fill")
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(pack.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Spacer()
                    if isSelected {
                        Text("Selected")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.accent, in: Capsule())
                            .foregroundStyle(.black)
                    }
                }

                Text(pack.summary)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)

                Text(pack.titleLine)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(isSelected ? 0.16 : 0.08), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isSelected ? AppTheme.accent.opacity(0.75) : Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.16), radius: 16, x: 0, y: 10)
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
