import AVFoundation
import UIKit

public struct CapturedPhoto {
    public let imageData: Data?
    public let rawData: Data?
    public let livePhotoMovieURL: URL?
    public let depthData: AVDepthData?
    public let portraitEffectsMatte: AVPortraitEffectsMatte?
    public let metadata: [String: Any]
    public let dimensions: CGSize?

    public var image: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
}

public final class PhotoCapture {

    private weak var session: CameraSession?
    private var pendingDelegates: [Int64: PhotoCaptureDelegate] = [:]
    private let lock = NSLock()

    init(session: CameraSession) {
        self.session = session
    }

    public func capture(
        flashMode: FlashMode? = nil,
        format: PhotoFormat? = nil
    ) async throws -> CapturedPhoto {
        guard let session else { throw CameraError.sessionNotRunning }
        guard session.isRunning else { throw CameraError.sessionNotRunning }

        let chosenFlash = flashMode ?? session.configuration.flashMode
        let chosenFormat = format ?? session.configuration.photoFormat
        let settings = try buildSettings(format: chosenFormat, flashMode: chosenFlash, in: session)

        applyConnectionOrientation(in: session)

        return try await withCheckedThrowingContinuation { continuation in
            let delegate = PhotoCaptureDelegate(settings: settings) { [weak self] result in
                guard let self else { return }
                self.lock.lock()
                self.pendingDelegates.removeValue(forKey: settings.uniqueID)
                self.lock.unlock()
                continuation.resume(with: result)
            }
            lock.lock()
            pendingDelegates[settings.uniqueID] = delegate
            lock.unlock()
            session.photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }

    private func buildSettings(format: PhotoFormat, flashMode: FlashMode, in session: CameraSession) throws -> AVCapturePhotoSettings {
        let output = session.photoOutput
        let settings: AVCapturePhotoSettings

        switch format {
        case .heif:
            if output.availablePhotoCodecTypes.contains(.hevc) {
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            } else {
                settings = AVCapturePhotoSettings()
            }
        case .heifMaxQuality:
            if output.availablePhotoCodecTypes.contains(.hevc) {
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            } else {
                settings = AVCapturePhotoSettings()
            }
            settings.photoQualityPrioritization = .quality
        case .jpeg:
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        case .raw:
            guard let rawFormat = output.availableRawPhotoPixelFormatTypes.first else {
                throw CameraError.formatNotSupported(reason: "RAW not supported on this device.")
            }
            settings = AVCapturePhotoSettings(rawPixelFormatType: rawFormat)
        case .rawPlusHEIF:
            guard let rawFormat = output.availableRawPhotoPixelFormatTypes.first else {
                throw CameraError.formatNotSupported(reason: "RAW not supported on this device.")
            }
            let processedCodec: AVVideoCodecType = output.availablePhotoCodecTypes.contains(.hevc) ? .hevc : .jpeg
            settings = AVCapturePhotoSettings(
                rawPixelFormatType: rawFormat,
                processedFormat: [AVVideoCodecKey: processedCodec]
            )
        }

        if let device = session.currentDevice, device.isFlashAvailable,
           output.supportedFlashModes.contains(flashMode.avFlashMode) {
            settings.flashMode = flashMode.avFlashMode
        }

        settings.isHighResolutionPhotoEnabled = output.isHighResolutionCaptureEnabled

        if output.isLivePhotoCaptureSupported, output.isLivePhotoCaptureEnabled {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("live-\(UUID().uuidString).mov")
            settings.livePhotoMovieFileURL = url
        }

        if output.isDepthDataDeliveryEnabled {
            settings.isDepthDataDeliveryEnabled = true
            settings.embedsDepthDataInPhoto = true
        }
        if output.isPortraitEffectsMatteDeliveryEnabled {
            settings.isPortraitEffectsMatteDeliveryEnabled = true
            settings.embedsPortraitEffectsMatteInPhoto = true
        }

        return settings
    }

    private func applyConnectionOrientation(in session: CameraSession) {
        guard let connection = session.photoOutput.connection(with: .video) else { return }
        if connection.isVideoOrientationSupported,
           let orientation = CameraOrientation.from(deviceOrientation: UIDevice.current.orientation) {
            connection.videoOrientation = orientation.avVideoOrientation
        }
    }
}

final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    typealias Completion = (Result<CapturedPhoto, Error>) -> Void

    let settings: AVCapturePhotoSettings
    let completion: Completion

    private var processedData: Data?
    private var rawData: Data?
    private var depthData: AVDepthData?
    private var portraitMatte: AVPortraitEffectsMatte?
    private var metadata: [String: Any] = [:]
    private var dimensions: CGSize?
    private var livePhotoURL: URL?
    private var captureError: Error?

    init(settings: AVCapturePhotoSettings, completion: @escaping Completion) {
        self.settings = settings
        self.completion = completion
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            captureError = error
            return
        }
        if photo.isRawPhoto {
            rawData = photo.fileDataRepresentation()
        } else {
            processedData = photo.fileDataRepresentation()
        }
        depthData = photo.depthData
        portraitMatte = photo.portraitEffectsMatte
        metadata = photo.metadata
        if let pixelBuffer = photo.pixelBuffer {
            let w = CVPixelBufferGetWidth(pixelBuffer)
            let h = CVPixelBufferGetHeight(pixelBuffer)
            dimensions = CGSize(width: w, height: h)
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishRecordingLivePhotoMovieForEventualFileAt outputFileURL: URL, resolvedSettings: AVCaptureResolvedPhotoSettings) {
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if error == nil {
            livePhotoURL = outputFileURL
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = captureError ?? error {
            completion(.failure(CameraError.captureFailed(underlying: error)))
            return
        }
        let result = CapturedPhoto(
            imageData: processedData,
            rawData: rawData,
            livePhotoMovieURL: livePhotoURL,
            depthData: depthData,
            portraitEffectsMatte: portraitMatte,
            metadata: metadata,
            dimensions: dimensions
        )
        completion(.success(result))
    }
}
