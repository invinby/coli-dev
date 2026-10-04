import SwiftUI

@main
struct ColiDevApp: App {
    @StateObject private var store = LearningStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 980, minHeight: 680)
        }
    }
}
