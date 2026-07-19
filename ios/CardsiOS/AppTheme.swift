import SwiftUI

enum AppTheme {
    static let background = LinearGradient(
        colors: [
            Color(red: 0.06, green: 0.08, blue: 0.14),
            Color(red: 0.10, green: 0.13, blue: 0.21),
            Color(red: 0.04, green: 0.05, blue: 0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let surface = Color.white.opacity(0.08)
    static let surfaceStrong = Color.white.opacity(0.14)
    static let accent = Color(red: 0.95, green: 0.70, blue: 0.18)
    static let mint = Color(red: 0.10, green: 0.78, blue: 0.68)
    static let ink = Color(red: 0.025, green: 0.035, blue: 0.065)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.72)
}

struct SurfaceCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.20), radius: 18, x: 0, y: 12)
    }
}

extension View {
    func surfaceCard() -> some View {
        modifier(SurfaceCard())
    }

    func appBackground() -> some View {
        background {
            ZStack {
                AppTheme.background
                Circle()
                    .fill(AppTheme.mint.opacity(0.12))
                    .frame(width: 340, height: 340)
                    .blur(radius: 52)
                    .offset(x: 150, y: -310)
                Circle()
                    .fill(AppTheme.accent.opacity(0.10))
                    .frame(width: 280, height: 280)
                    .blur(radius: 58)
                    .offset(x: -140, y: 330)
            }
            .ignoresSafeArea()
        }
    }
}
