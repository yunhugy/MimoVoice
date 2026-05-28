import SwiftUI

@main
@available(iOS 16.0, *)
struct MimoVoiceApp: App {
    @AppStorage("apiKey") private var apiKey = ""
    @AppStorage("baseURL") private var baseURL = "https://token-plan-sgp.xiaomimimo.com/v1"
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    if baseURL.isEmpty {
                        baseURL = "https://token-plan-sgp.xiaomimimo.com/v1"
                    }
                }
        }
    }
}
