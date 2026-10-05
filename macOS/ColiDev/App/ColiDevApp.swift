import SwiftUI

@main
struct ColiDevApp: App {
    @StateObject private var store = LearningStore()
    @StateObject private var backendSupervisor = LocalBackendSupervisor()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(backendSupervisor)
                .frame(minWidth: 980, minHeight: 680)
        }
    }
}
