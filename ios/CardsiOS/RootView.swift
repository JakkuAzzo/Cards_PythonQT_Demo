import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: PackStore
    @State private var selectedTab: RootTab = .home

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView()
                }
                .tag(RootTab.home)

                NavigationStack {
                    LibraryView()
                }
                .tag(RootTab.library)

                NavigationStack {
                    LiveTableView()
                }
                .tag(RootTab.table)

                NavigationStack {
                    CreatorView()
                }
                .tag(RootTab.create)

                NavigationStack {
                    ShopView()
                }
                .tag(RootTab.discover)
            }
            .toolbar(.hidden, for: .tabBar)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PremiumTabBar(selection: $selectedTab)
        }
        .appBackground()
        .sheet(item: $store.activeSessionPack, onDismiss: {
            store.closeSession()
        }) { pack in
            NavigationStack {
                GameSessionView(pack: pack)
            }
            .presentationDetents([.large])
        }
        .preferredColorScheme(.dark)
    }
}

private enum RootTab: String, CaseIterable, Hashable {
    case home, library, table, create, discover

    var title: String {
        switch self {
        case .home: return "Home"
        case .library: return "Library"
        case .table: return "Table"
        case .create: return "Create"
        case .discover: return "Discover"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .library: return "square.stack.3d.up.fill"
        case .table: return "person.3.fill"
        case .create: return "wand.and.stars"
        case .discover: return "sparkles"
        }
    }
}

private struct PremiumTabBar: View {
    @Binding var selection: RootTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(RootTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { selection = tab }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 15, weight: .bold))
                        if selection == tab {
                            Text(tab.title)
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .foregroundStyle(selection == tab ? AppTheme.accent : AppTheme.navMuted)
                    .background(selection == tab ? AppTheme.navActive : .clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .padding(6)
        .background(AppTheme.navDock, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(AppTheme.navDockStroke, lineWidth: 1)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}
