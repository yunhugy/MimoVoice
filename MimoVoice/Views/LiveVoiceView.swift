import SwiftUI

@available(iOS 16.0, *)
struct LiveVoiceView: View {
    @StateObject private var engine = RealTimeEngine()
    
    @State private var selectedEffect: RealTimeEffect = .none
    @State private var customPitch: Float = 0
    @State private var customRate: Float = 1.0
    
    let effects = RealTimeEffect.allCases
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 状态指示
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(engine.isActive ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        if engine.isActive {
                            Circle()
                                .stroke(Color.green, lineWidth: 4)
                                .frame(width: 120, height: 120)
                        }
                        
                        Image(systemName: engine.isActive ? "mic.fill" : "mic.slash.fill")
                            .font(.system(size: 40))
                            .foregroundColor(engine.isActive ? .green : .gray)
                    }
                    
                    Text(engine.isActive ? "实时变声中 - \(engine.effectName)" : "点击下方按钮开始")
                        .font(.headline)
                        .foregroundColor(engine.isActive ? .green : .secondary)
                }
                .padding(.top, 20)
                
                // 效果选择
                VStack(alignment: .leading, spacing: 12) {
                    Text("变声效果").font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 10) {
                        ForEach(effects) { effect in
                            Button {
                                selectedEffect = effect
                                if engine.isActive {
                                    engine.setEffect(effect)
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: effect.icon)
                                        .font(.title2)
                                    Text(effect.rawValue)
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selectedEffect == effect ? Color.purple : Color(.systemGray6))
                                .foregroundColor(selectedEffect == effect ? .white : .primary)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                
                // 手动调节
                VStack(spacing: 16) {
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
                
                Spacer()
                
                // 开始/停止按钮
                Button {
                    if engine.isActive {
                        engine.stop()
                    } else {
                        do {
                            engine.setEffect(selectedEffect)
                            try engine.start()
                        } catch {
                            print("Engine start error: \(error)")
                        }
                    }
                } label: {
                    Text(engine.isActive ? "停止" : "开始变声")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(engine.isActive ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.bottom, 20)
            }
            .padding()
            .navigationTitle("实时变声")
        }
    }
}
