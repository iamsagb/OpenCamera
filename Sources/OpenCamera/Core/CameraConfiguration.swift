import AVFoundation
import Foundation

public struct CameraConfiguration: Sendable {
    public var mode: CameraMode
    public var position: CameraPosition
    public var preferredLens: CameraLens?
    public var sessionPreset: SessionPreset
    public var photoFormat: PhotoFormat
    public var videoCodec: VideoCodec
    public var stabilization: VideoStabilization
    public var enableHDR: Bool
    public var enableLivePhotos: Bool
    public var enableDepthData: Bool
    public var enablePortraitEffectsMatte: Bool
    public var enableHighResolutionPhoto: Bool
    public var enableAudio: Bool
    public var preferredFrameRate: Int?
    public var flashMode: FlashMode
    public var torchMode: TorchMode

    public init(
        mode: CameraMode = .photo,
        position: CameraPosition = .back,
        preferredLens: CameraLens? = nil,
        sessionPreset: SessionPreset = .photo,
        photoFormat: PhotoFormat = .heif,
        videoCodec: VideoCodec = .hevc,
        stabilization: VideoStabilization = .auto,
        enableHDR: Bool = true,
        enableLivePhotos: Bool = false,
        enableDepthData: Bool = false,
        enablePortraitEffectsMatte: Bool = false,
        enableHighResolutionPhoto: Bool = true,
        enableAudio: Bool = true,
        preferredFrameRate: Int? = nil,
        flashMode: FlashMode = .auto,
        torchMode: TorchMode = .off
    ) {
        self.mode = mode
        self.position = position
        self.preferredLens = preferredLens
        self.sessionPreset = sessionPreset
        self.photoFormat = photoFormat
        self.videoCodec = videoCodec
        self.stabilization = stabilization
        self.enableHDR = enableHDR
        self.enableLivePhotos = enableLivePhotos
        self.enableDepthData = enableDepthData
        self.enablePortraitEffectsMatte = enablePortraitEffectsMatte
        self.enableHighResolutionPhoto = enableHighResolutionPhoto
        self.enableAudio = enableAudio
        self.preferredFrameRate = preferredFrameRate
        self.flashMode = flashMode
        self.torchMode = torchMode
    }

    public static let defaultPhoto = CameraConfiguration(mode: .photo)
    public static let defaultVideo = CameraConfiguration(
        mode: .video,
        sessionPreset: .hd1920x1080,
        videoCodec: .hevc
    )
}
