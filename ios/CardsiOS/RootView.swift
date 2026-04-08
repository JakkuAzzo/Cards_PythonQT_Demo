import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: PackStore

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            TabView {
                NavigationStack {
                    HomeView()
                }
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

                NavigationStack {
                    LibraryView()
                }
                .tabItem {
                    Label("Library", systemImage: "rectangle.stack.fill")
                }

                NavigationStack {
                    ShopView()
                }
                .tabItem {
                    Label("Shop", systemImage: "cart.fill")
                }
            }
            .tint(AppTheme.accent)
        }
        .sheet(item: $store.activeSessionPack) { pack in
            NavigationStack {
                GameSessionView(pack: pack)
            }
            .presentationDetents([.large])
        }
    }
}