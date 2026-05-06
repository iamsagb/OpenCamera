import AVFoundation
import CoreMedia
import UIKit

public enum CameraPosition: Sendable {
    case back
    case front
    case unspecified

    var avPosition: AVCaptureDevice.Position {
        switch self {
        case .back: return .back
        case .front: return .front
        case .unspecified: return .unspecified
        }
    }
}

public enum CameraMode: Sendable {
    case photo
    case video
}

public enum CameraLens: Sendable, Hashable {
    case wide
    case ultraWide
    case telephoto
    case dual
    case dualWide
    case triple
    case trueDepth

    var avDeviceType: AVCaptureDevice.DeviceType {
        switch self {
        case .wide: return .builtInWideAngleCamera
        case .ultraWide: return .builtInUltraWideCamera
        case .telephoto: return .builtInTelephotoCamera
        case .dual: return .builtInDualCamera
        case .dualWide: return .builtInDualWideCamera
        case .triple: return .builtInTripleCamera
        case .trueDepth: return .builtInTrueDepthCamera
        }
    }
}

public enum SessionPreset: Sendable {
    case photo
    case high
    case medium
    case low
    case hd1280x720
    case hd1920x1080
    case hd4K3840x2160
    case vga640x480
    case iFrame960x540
    case iFrame1280x720
    case inputPriority

    var avPreset: AVCaptureSession.Preset {
        switch self {
        case .photo: return .photo
        case .high: return .high
        case .medium: return .medium
        case .low: return .low
        case .hd1280x720: return .hd1280x720
        case .hd1920x1080: return .hd1920x1080
        case .hd4K3840x2160: return .hd4K3840x2160
        case .vga640x480: return .vga640x480
        case .iFrame960x540: return .iFrame960x540
        case .iFrame1280x720: return .iFrame1280x720
        case .inputPriority: return .inputPriority
        }
    }
}

public enum PhotoFormat: Sendable {
    case heif
    case heifMaxQuality
    case jpeg
    case raw
    case rawPlusHEIF
}

public enum FlashMode: Sendable {
    case auto
    case on
    case off

    var avFlashMode: AVCaptureDevice.FlashMode {
        switch self {
        case .auto: return .auto
        case .on: return .on
        case .off: return .off
        }
    }
}

public enum TorchMode: Sendable {
    case auto
    case on
    case off
    case level(Float)

    var avTorchMode: AVCaptureDevice.TorchMode {
        switch self {
        case .auto: return .auto
        case .on, .level: return .on
        case .off: return .off
        }
    }
}

public enum FocusMode: Sendable {
    case locked
    case autoFocus
    case continuousAutoFocus

    var avFocusMode: AVCaptureDevice.FocusMode {
        switch self {
        case .locked: return .locked
        case .autoFocus: return .autoFocus
        case .continuousAutoFocus: return .continuousAutoFocus
        }
    }
}

public enum ExposureMode: Sendable {
    case locked
    case autoExpose
    case continuousAutoExposure
    case custom

    var avExposureMode: AVCaptureDevice.ExposureMode {
        switch self {
        case .locked: return .locked
        case .autoExpose: return .autoExpose
        case .continuousAutoExposure: return .continuousAutoExposure
        case .custom: return .custom
        }
    }
}

public enum WhiteBalanceMode: Sendable {
    case locked
    case autoWhiteBalance
    case continuousAutoWhiteBalance

    var avWhiteBalanceMode: AVCaptureDevice.WhiteBalanceMode {
        switch self {
        case .locked: return .locked
        case .autoWhiteBalance: return .autoWhiteBalance
        case .continuousAutoWhiteBalance: return .continuousAutoWhiteBalance
        }
    }
}

public struct WhiteBalanceGains: Sendable {
    public var temperature: Float
    public var tint: Float

    public init(temperature: Float, tint: Float = 0) {
        self.temperature = temperature
        self.tint = tint
    }
}

public enum VideoCodec: Sendable {
    case h264
    case hevc
    case proRes422
    case proRes422HQ
    case proRes422LT
    case proRes422Proxy

    var avCodec: AVVideoCodecType {
        switch self {
        case .h264: return .h264
        case .hevc: return .hevc
        case .proRes422: return .proRes422
        case .proRes422HQ: return .proRes422HQ
        case .proRes422LT: return .proRes422LT
        case .proRes422Proxy: return .proRes422Proxy
        }
    }
}

public enum VideoStabilization: Sendable {
    case off
    case standard
    case cinematic
    case cinematicExtended
    case auto

    @available(iOS 13.0, *)
    var avMode: AVCaptureVideoStabilizationMode {
        switch self {
        case .off: return .off
        case .standard: return .standard
        case .cinematic: return .cinematic
        case .cinematicExtended: return .cinematicExtended
        case .auto: return .auto
        }
    }
}

public enum CameraOrientation: Sendable {
    case portrait
    case portraitUpsideDown
    case landscapeLeft
    case landscapeRight

    var avVideoOrientation: AVCaptureVideoOrientation {
        switch self {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        }
    }

    static func from(deviceOrientation: UIDeviceOrientation) -> CameraOrientation? {
        switch deviceOrientation {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        default: return nil
        }
    }
}
