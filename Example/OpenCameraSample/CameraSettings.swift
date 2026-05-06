import Foundation
import OpenCamera

struct CameraSettings: Equatable {
    var photoFormat: PhotoFormat = .heif
    var videoCodec: VideoCodec = .hevc
    var sessionPreset: SessionPreset = .hd1920x1080
    var frameRate: Int = 30
    var stabilization: VideoStabilization = .auto
    var enableLivePhotos: Bool = false
    var enableDepthData: Bool = false
    var enablePortraitMatte: Bool = false
    var enableHDR: Bool = true
    var enableAudio: Bool = true
    var convertVideoToMP4: Bool = false

    static let frameRateOptions: [Int] = [24, 30, 60, 120, 240]
    static let presetOptions: [(SessionPreset, String)] = [
        (.hd1280x720, "720p HD"),
        (.hd1920x1080, "1080p HD"),
        (.hd4K3840x2160, "4K UHD"),
        (.photo, "Photo Best")
    ]
    static let photoFormats: [(PhotoFormat, String)] = [
        (.heif, "HEIF"),
        (.heifMaxQuality, "HEIF Max"),
        (.jpeg, "JPEG"),
        (.raw, "RAW (DNG)"),
        (.rawPlusHEIF, "RAW + HEIF")
    ]
    static let codecOptions: [(VideoCodec, String)] = [
        (.hevc, "HEVC (H.265)"),
        (.h264, "H.264"),
        (.proRes422HQ, "ProRes 422 HQ"),
        (.proRes422, "ProRes 422"),
        (.proRes422LT, "ProRes 422 LT"),
        (.proRes422Proxy, "ProRes Proxy")
    ]
    static let stabilizationOptions: [(VideoStabilization, String)] = [
        (.off, "Off"),
        (.standard, "Standard"),
        (.cinematic, "Cinematic"),
        (.cinematicExtended, "Cinematic Ext."),
        (.auto, "Auto")
    ]
}

extension PhotoFormat: Hashable, Equatable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(label)
    }
    public static func == (lhs: PhotoFormat, rhs: PhotoFormat) -> Bool {
        lhs.label == rhs.label
    }
    var label: String {
        switch self {
        case .heif: return "heif"
        case .heifMaxQuality: return "heifmax"
        case .jpeg: return "jpeg"
        case .raw: return "raw"
        case .rawPlusHEIF: return "rawheif"
        }
    }
}

extension VideoCodec: Hashable, Equatable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(label)
    }
    public static func == (lhs: VideoCodec, rhs: VideoCodec) -> Bool {
        lhs.label == rhs.label
    }
    var label: String {
        switch self {
        case .h264: return "h264"
        case .hevc: return "hevc"
        case .proRes422: return "prores"
        case .proRes422HQ: return "proreshq"
        case .proRes422LT: return "proreslt"
        case .proRes422Proxy: return "proresproxy"
        }
    }
}

extension SessionPreset: Hashable, Equatable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(label)
    }
    public static func == (lhs: SessionPreset, rhs: SessionPreset) -> Bool {
        lhs.label == rhs.label
    }
    var label: String {
        switch self {
        case .photo: return "photo"
        case .high: return "high"
        case .medium: return "medium"
        case .low: return "low"
        case .hd1280x720: return "720"
        case .hd1920x1080: return "1080"
        case .hd4K3840x2160: return "4k"
        case .vga640x480: return "vga"
        case .iFrame960x540: return "if540"
        case .iFrame1280x720: return "if720"
        case .inputPriority: return "input"
        }
    }
}

extension VideoStabilization: Hashable, Equatable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(label)
    }
    public static func == (lhs: VideoStabilization, rhs: VideoStabilization) -> Bool {
        lhs.label == rhs.label
    }
    var label: String {
        switch self {
        case .off: return "off"
        case .standard: return "standard"
        case .cinematic: return "cinematic"
        case .cinematicExtended: return "cinematicext"
        case .auto: return "auto"
        }
    }
}
