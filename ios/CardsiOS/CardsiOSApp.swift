import SwiftUI

@main
struct CardsiOSApp: App {
    @StateObject private var store = PackStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}