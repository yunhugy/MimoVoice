import SwiftUI

@available(iOS 16.0, *)
struct ContentView: View {
    @AppStorage("apiKey") private var apiKey = ""
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AIRefineView()
                .tabItem { Label("AI 精修", systemImage: "wand.and.stars") }
                .tag(0)
            
            VoiceCloneView()
                .tabItem { Label("声音克隆", systemImage: "person.wave.2") }
                .tag(1)
            
            LiveVoiceView()
                .tabItem { Label("实时变声", systemImage: "mic.fill") }
                .tag(2)
            
            SettingsView()
                .tabItem { Label("设置", systemImage: "gear") }
                .tag(3)
        }
        .tint(.purple)
        .overlay(alignment: .top) {
            if apiKey.isEmpty {
                VStack(spacing: 4) {
                    Text("⚠️ 请先在「设置」中配置 API Key")
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }
        }
    }
}
