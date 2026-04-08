import SwiftUI

struct ShopView: View {
    @EnvironmentObject private var store: PackStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    ForEach(featuredCards) { offer in
                        ShopCard(offer: offer)
                    }
                }

                if let pack = store.packs.first {
                    PackDetailView(pack: pack)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("Shop")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Card Shop")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text("A native store shell for featured decks and future pack drops.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var featuredCards: [ShopOffer] {
        [
            ShopOffer(
                id: "featured-demo",
                title: "Demo Pack",
                subtitle: "Bundled starter deck",
                note: "Loaded from the iPhone build resources.",
                accentStartHex: "F59E0B",
                accentEndHex: "EF4444"
            ),
            ShopOffer(
                id: "featured-next",
                title: "Next Pack Slot",
                subtitle: "Coming soon",
                note: "Use this slot for the first native expansion pack.",
                accentStartHex: "60A5FA",
                accentEndHex: "22C55E"
            )
        ]
    }
}

private struct ShopOffer: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let note: String
    let accentStartHex: String
    let accentEndHex: String
}

private struct ShopCard: View {
    let offer: ShopOffer

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: offer.accentStartHex), Color(hex: offer.accentEndHex)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 112)
                .overlay(
                    VStack(alignment: .leading) {
                        Spacer()
                        Text(offer.subtitle.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.2)
                            .foregroundStyle(.white.opacity(0.84))
                    }
                    .padding(14)
                )

            Text(offer.title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text(offer.note)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(3)
        }
        .surfaceCard()
    }
}