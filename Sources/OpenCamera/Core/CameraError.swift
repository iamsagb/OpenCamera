import Foundation

public enum CameraError: LocalizedError {
    case permissionDenied(media: PermissionMedia)
    case noDeviceAvailable(position: CameraPosition)
    case cannotAddInput
    case cannotAddOutput
    case sessionNotRunning
    case sessionAlreadyRunning
    case configurationFailed(reason: String)
    case formatNotSupported(reason: String)
    case captureFailed(underlying: Error?)
    case recordingFailed(underlying: Error?)
    case fileWriteFailed(underlying: Error?)
    case unsupportedFeature(name: String)
    case invalidValue(field: String, reason: String)
    case deviceLockFailed(underlying: Error)

    public enum PermissionMedia: String, Sendable {
        case camera
        case microphone
        case photoLibrary
    }

    public var errorDescription: String? {
        switch self {
        case .permissionDenied(let m): return "Permission denied for \(m.rawValue)."
        case .noDeviceAvailable(let p): return "No camera device available at position \(p)."
        case .cannotAddInput: return "Capture session cannot accept input."
        case .cannotAddOutput: return "Capture session cannot accept output."
        case .sessionNotRunning: return "Camera session is not running."
        case .sessionAlreadyRunning: return "Camera session is already running."
        case .configurationFailed(let r): return "Configuration failed: \(r)"
        case .formatNotSupported(let r): return "Format not supported: \(r)"
        case .captureFailed(let e): return "Capture failed: \(e?.localizedDescription ?? "unknown")"
        case .recordingFailed(let e): return "Recording failed: \(e?.localizedDescription ?? "unknown")"
        case .fileWriteFailed(let e): return "File write failed: \(e?.localizedDescription ?? "unknown")"
        case .unsupportedFeature(let n): return "Unsupported feature: \(n)"
        case .invalidValue(let f, let r): return "Invalid value for \(f): \(r)"
        case .deviceLockFailed(let e): return "Device lock failed: \(e.localizedDescription)"
        }
    }
}
