import Foundation

enum VoiceMode: String, CaseIterable, Identifiable {
    case aiRefine = "AI精修"
    case voiceClone = "声音克隆"
    case realTime = "实时变声"
    
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .aiRefine: return "sparkles"
        case .voiceClone: return "person.wave.2"
        case .realTime: return "mic.waves.and.arrow.right"
        }
    }
}

enum AIVoiceStyle: String, CaseIterable, Identifiable {
    case sweet = "甜美少女"
    case gentle = "温柔姐姐"
    case cool = "高冷御姐"
    case lively = "元气萝莉"
    case mature = "磁性大叔"
    case gentleMan = "温柔男神"
    case boy = "阳光少年"
    case loli = "软萌萝莉"
    case custom = "自定义..."
    
    var id: String { rawValue }
    
    var prompt: String {
        switch self {
        case .sweet: return "用甜美可爱的少女声线，语气温柔活泼，带一点撒娇感"
        case .gentle: return "用温柔知性的成熟女声，语气温和沉稳，声音清澈"
        case .cool: return "用高冷淡然的御姐声线，语调略低，发音干净利落"
        case .lively: return "用元气满满的少女声线，语速较快，充满活力和朝气"
        case .mature: return "用低沉磁性的成熟男声，语速沉稳，带有磁性和深度"
        case .gentleMan: return "用温柔阳光的年轻男声，语气温柔体贴，声音清爽"
        case .boy: return "用阳光开朗的少年声线，语气活泼，带着青春气息"
        case .loli: return "用软萌可爱的萝莉声线，声音甜美稚嫩，语气天真烂漫"
        case .custom: return ""
        }
    }
}

enum RealTimeEffect: String, CaseIterable, Identifiable {
    case none = "原声"
    case chipmunk = "花栗鼠"
    case deep = "低沉"
    case robot = "机器人"
    case echo = "回声"
    case alien = "外星人"
    case kid = "小孩"
    case giant = "巨人"
    
    var id: String { rawValue }
    
    var pitch: Float {
        switch self {
        case .none: return 0
        case .chipmunk: return 1200
        case .deep: return -800
        case .robot: return 0
        case .echo: return 0
        case .alien: return 600
        case .kid: return 400
        case .giant: return -1200
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "mic.fill"
        case .chipmunk: return "squirrel.fill"
        case .deep: return "bubble.left.and.bubble.right.fill"
        case .robot: return "cpu"
        case .echo: return "dot.radiowaves.left.and.right"
        case .alien: return "sparkles"
        case .kid: return "figure.child"
        case .giant: return "arrow.up.to.line"
        }
    }
}

struct CloneSample: Identifiable, Codable {
    let id: UUID
    let name: String
    let audioData: Data
    let createdAt: Date
    
    init(name: String, audioData: Data) {
        self.id = UUID()
        self.name = name
        self.audioData = audioData
        self.createdAt = Date()
    }
}
