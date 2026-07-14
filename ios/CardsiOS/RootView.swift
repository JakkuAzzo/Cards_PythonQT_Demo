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
                    LiveTableView()
                }
                .tabItem {
                    Label("Table", systemImage: "person.3.fill")
                }

                NavigationStack {
                    CreatorView()
                }
                .tabItem {
                    Label("Create", systemImage: "wand.and.stars")
                }

                NavigationStack {
                    ShopView()
                }
                .tabItem {
                    Label("Discover", systemImage: "sparkles")
                }
            }
            .tint(AppTheme.accent)
        }
        .sheet(item: $store.activeSessionPack, onDismiss: {
            store.closeSession()
        }) { pack in
            NavigationStack {
                GameSessionView(pack: pack)
            }
            .presentationDetents([.large])
        }
    }
}
