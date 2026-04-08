import SwiftUI

struct GameSessionView: View {
    @EnvironmentObject private var store: PackStore
    @Environment(\.dismiss) private var dismiss
    let pack: PackRecord

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                PackDetailView(pack: pack)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Session Shell")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("The native iPhone UI is running. The original PyQt game widget runtime still needs a mobile replacement or a backend service.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .surfaceCard()

                HStack(spacing: 12) {
                    Button {
                        store.restartSession()
                    } label: {
                        Label("Restart", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button(role: .destructive) {
                        store.closeSession()
                        dismiss()
                    } label: {
                        Label("Close", systemImage: "xmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(DestructiveButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Live Session")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text("This is the native iPhone shell for the selected pack.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
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