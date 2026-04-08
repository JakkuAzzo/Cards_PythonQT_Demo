import SwiftUI

struct PackDetailView: View {
    let pack: PackRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(pack.badge.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.3)
                        .foregroundStyle(AppTheme.textSecondary)

                    Text(pack.name)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(pack.summary)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Text(pack.status)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(pack.gradient, in: Capsule())
                    .foregroundStyle(.black)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Configuration")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                ForEach(pack.configItems, id: \.key) { item in
                    HStack(alignment: .top) {
                        Text(item.key.replacingOccurrences(of: "_", with: " ").capitalized)
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                        Text(item.value)
                            .foregroundStyle(AppTheme.textPrimary)
                            .multilineTextAlignment(.trailing)
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                }
            }
        }
        .surfaceCard()
    }
}