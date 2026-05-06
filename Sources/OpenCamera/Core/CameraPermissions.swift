import AVFoundation
import Photos

public enum CameraAuthorizationStatus: Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
    case limited
}

public enum CameraPermissions {
    public static func cameraStatus() -> CameraAuthorizationStatus {
        map(AVCaptureDevice.authorizationStatus(for: .video))
    }

    public static func microphoneStatus() -> CameraAuthorizationStatus {
        map(AVCaptureDevice.authorizationStatus(for: .audio))
    }

    public static func photoLibraryStatus() -> CameraAuthorizationStatus {
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .notDetermined: return .notDetermined
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .limited: return .limited
        @unknown default: return .denied
        }
    }

    @discardableResult
    public static func requestCamera() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }

    @discardableResult
    public static func requestMicrophone() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .audio)
    }

    @discardableResult
    public static func requestPhotoLibrary() async -> CameraAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                let mapped: CameraAuthorizationStatus
                switch status {
                case .notDetermined: mapped = .notDetermined
                case .authorized: mapped = .authorized
                case .denied: mapped = .denied
                case .restricted: mapped = .restricted
                case .limited: mapped = .limited
                @unknown default: mapped = .denied
                }
                continuation.resume(returning: mapped)
            }
        }
    }

    public static func ensureCameraAccess() async throws {
        switch cameraStatus() {
        case .authorized: return
        case .notDetermined:
            let granted = await requestCamera()
            if !granted { throw CameraError.permissionDenied(media: .camera) }
        default:
            throw CameraError.permissionDenied(media: .camera)
        }
    }

    public static func ensureMicrophoneAccess() async throws {
        switch microphoneStatus() {
        case .authorized: return
        case .notDetermined:
            let granted = await requestMicrophone()
            if !granted { throw CameraError.permissionDenied(media: .microphone) }
        default:
            throw CameraError.permissionDenied(media: .microphone)
        }
    }

    private static func map(_ status: AVAuthorizationStatus) -> CameraAuthorizationStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorized: return .authorized
        @unknown default: return .denied
        }
    }
}
