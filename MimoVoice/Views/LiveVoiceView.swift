import SwiftUI

@available(iOS 16.0, *)
struct LiveVoiceView: View {
    @StateObject private var engine = RealTimeEngine()
    
    @State private var selectedEffect: RealTimeEffect = .none
    @State private var customPitch: Float = 0
    @State private var customRate: Float = 1.0
    @State private var showError = false
    @State private var errorMessage = ""
    
    let effects = RealTimeEffect.allCases
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 状态指示
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(engine.isActive ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            if engine.isActive {
                                Circle()
                                    .stroke(Color.green, lineWidth: 3)
                                    .frame(width: 100, height: 100)
                            }
                            
                            Image(systemName: engine.isActive ? "mic.fill" : "mic.slash.fill")
                                .font(.system(size: 36))
                                .foregroundColor(engine.isActive ? .green : .gray)
                        }
                        
                        Text(engine.isActive ? "实时变声中 - \(engine.effectName)" : "选择效果后点击开始")
                            .font(.headline)
                            .foregroundColor(engine.isActive ? .green : .secondary)
                    }
                    .padding(.top, 10)
                    
                    // 效果选择
                    VStack(alignment: .leading, spacing: 10) {
                        Text("变声效果").font(.headline)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                            ForEach(effects) { effect in
                                Button {
                                    selectedEffect = effect
                                    if engine.isActive {
                                        engine.setEffect(effect)
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: effect.icon)
                                            .font(.title3)
                                        Text(effect.rawValue)
                                            .font(.caption2)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(selectedEffect == effect ? Color.purple : Color(.systemGray6))
                                    .foregroundColor(selectedEffect == effect ? .white : .primary)
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                    
                    // 手动调节
                    VStack(spacing: 14) {
                        VStack(alignment: .leading) {
                            Text("音调: \(Int(customPitch))").font(.subheadline)
                            Slider(value: $customPitch, in: -2400...2400, step: 100)
                                .onChange(of: customPitch) { newValue in
                                    engine.setPitch(newValue)
                                }
                        }
                        
                        VStack(alignment: .leading) {
                            Text("语速: \(String(format: "%.1f", customRate))x").font(.subheadline)
                            Slider(value: $customRate, in: 0.5...2.0, step: 0.1)
                                .onChange(of: customRate) { newValue in
                                    engine.setRate(newValue)
                                }
                        }
                    }
                    .padding(.horizontal)
                    
                    // 开始/停止按钮
                    Button {
                        toggleEngine()
                    } label: {
                        Text(engine.isActive ? "⏹ 停止变声" : "🎙 开始变声")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(engine.isActive ? Color.red : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("实时变声")
            .alert("错误", isPresented: $showError) {
                Button("确定") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func toggleEngine() {
        if engine.isActive {
            engine.stop()
        } else {
            // 先请求麦克风权限
            engine.requestMicPermission { granted in
                guard granted else {
                    errorMessage = "需要麦克风权限才能实时变声，请在系统设置中授权"
                    showError = true
                    return
                }
                do {
                    try self.engine.start()
                    // 启动成功后再设效果
                    self.engine.setEffect(self.selectedEffect)
                } catch {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
}
