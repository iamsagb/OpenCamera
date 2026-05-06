import AVFoundation
import CoreMedia
import UIKit

public protocol CameraSessionDelegate: AnyObject {
    func cameraSessionDidStart(_ session: CameraSession)
    func cameraSessionDidStop(_ session: CameraSession)
    func cameraSession(_ session: CameraSession, didChangeDevice device: AVCaptureDevice)
    func cameraSession(_ session: CameraSession, didEncounterError error: Error)
    func cameraSession(_ session: CameraSession, didOutputVideoSampleBuffer sampleBuffer: CMSampleBuffer)
}

public extension CameraSessionDelegate {
    func cameraSessionDidStart(_ session: CameraSession) {}
    func cameraSessionDidStop(_ session: CameraSession) {}
    func cameraSession(_ session: CameraSession, didChangeDevice device: AVCaptureDevice) {}
    func cameraSession(_ session: CameraSession, didEncounterError error: Error) {}
    func cameraSession(_ session: CameraSession, didOutputVideoSampleBuffer sampleBuffer: CMSampleBuffer) {}
}

public final class CameraSession: NSObject {

    public let captureSession = AVCaptureSession()

    public internal(set) var configuration: CameraConfiguration
    public internal(set) var currentDevice: AVCaptureDevice?
    public internal(set) var currentVideoInput: AVCaptureDeviceInput?
    public internal(set) var currentAudioInput: AVCaptureDeviceInput?

    public let photoOutput = AVCapturePhotoOutput()
    public let movieOutput = AVCaptureMovieFileOutput()
    public let videoDataOutput = AVCaptureVideoDataOutput()

    public weak var delegate: CameraSessionDelegate?

    let sessionQueue = DispatchQueue(label: "com.opencamera.session", qos: .userInitiated)
    let videoDataQueue = DispatchQueue(label: "com.opencamera.videodata", qos: .userInitiated)

    public lazy var controls: ManualControls = ManualControls(session: self)
    public lazy var photo: PhotoCapture = PhotoCapture(session: self)
    public lazy var video: VideoCapture = VideoCapture(session: self)
    public lazy var filters: FilterPipeline = FilterPipeline(session: self)

    public init(configuration: CameraConfiguration = .defaultPhoto) {
        self.configuration = configuration
        super.init()
    }

    public var isRunning: Bool { captureSession.isRunning }

    public func prepare() async throws {
        try await CameraPermissions.ensureCameraAccess()
        if configuration.enableAudio && configuration.mode == .video {
            try await CameraPermissions.ensureMicrophoneAccess()
        }
        try await performAsync { [weak self] in
            try self?.configureInitial()
        }
    }

    public func start() async throws {
        try await performAsync { [weak self] in
            guard let self else { return }
            guard !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.delegate?.cameraSessionDidStart(self)
            }
        }
    }

    public func stop() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            sessionQueue.async { [weak self] in
                guard let self else { continuation.resume(); return }
                if self.captureSession.isRunning {
                    self.captureSession.stopRunning()
                    DispatchQueue.main.async {
                        self.delegate?.cameraSessionDidStop(self)
                    }
                }
                continuation.resume()
            }
        }
    }

    public func switchCamera() async throws {
        let newPosition: CameraPosition = configuration.position == .back ? .front : .back
        try await setPosition(newPosition)
    }

    public func setPosition(_ position: CameraPosition, lens: CameraLens? = nil) async throws {
        try await performAsync { [weak self] in
            guard let self else { return }
            self.configuration.position = position
            if let lens { self.configuration.preferredLens = lens }
            try self.replaceVideoInput()
        }
    }

    public func setMode(_ mode: CameraMode) async throws {
        try await performAsync { [weak self] in
            guard let self else { return }
            self.configuration.mode = mode
            try self.applyOutputs()
        }
    }

    public func updateConfiguration(_ block: @escaping (inout CameraConfiguration) -> Void) async throws {
        try await performAsync { [weak self] in
            guard let self else { return }
            block(&self.configuration)
            try self.applyOutputs()
            try self.applySessionPreset()
            try self.applyConnectionSettings()
        }
    }

    func performAsync(_ work: @escaping () throws -> Void) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async {
                do {
                    try work()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func configureInitial() throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        if captureSession.canSetSessionPreset(configuration.sessionPreset.avPreset) {
            captureSession.sessionPreset = configuration.sessionPreset.avPreset
        }

        try replaceVideoInputLocked()
        try ensureAudioInputLocked()
        try applyOutputsLocked()
        try applyConnectionSettingsLocked()
    }

    private func replaceVideoInput() throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        try replaceVideoInputLocked()
        try applyConnectionSettingsLocked()
    }

    private func replaceVideoInputLocked() throws {
        if let current = currentVideoInput {
            captureSession.removeInput(current)
            currentVideoInput = nil
        }

        guard let device = DeviceDiscovery.device(
            position: configuration.position,
            preferredLens: configuration.preferredLens
        ) else {
            throw CameraError.noDeviceAvailable(position: configuration.position)
        }

        let input: AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput(device: device)
        } catch {
            throw CameraError.configurationFailed(reason: error.localizedDescription)
        }

        guard captureSession.canAddInput(input) else {
            throw CameraError.cannotAddInput
        }
        captureSession.addInput(input)
        currentVideoInput = input
        currentDevice = device

        if let fps = configuration.preferredFrameRate {
            try setActiveFrameRate(fps, on: device)
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.delegate?.cameraSession(self, didChangeDevice: device)
        }
    }

    private func ensureAudioInputLocked() throws {
        if !configuration.enableAudio || configuration.mode != .video {
            if let current = currentAudioInput {
                captureSession.removeInput(current)
                currentAudioInput = nil
            }
            return
        }
        if currentAudioInput != nil { return }
        guard let mic = DeviceDiscovery.microphone() else { return }
        let input: AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput(device: mic)
        } catch {
            throw CameraError.configurationFailed(reason: error.localizedDescription)
        }
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
            currentAudioInput = input
        }
    }

    private func applyOutputs() throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        try applyOutputsLocked()
    }

    private func applyOutputsLocked() throws {
        switch configuration.mode {
        case .photo:
            removeOutputIfNeeded(movieOutput)
            addOutputIfNeeded(photoOutput)
            addOutputIfNeeded(videoDataOutput)
            configurePhotoOutputLocked()
        case .video:
            removeOutputIfNeeded(photoOutput)
            addOutputIfNeeded(movieOutput)
            addOutputIfNeeded(videoDataOutput)
        }
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataQueue)
    }

    private func configurePhotoOutputLocked() {
        photoOutput.isHighResolutionCaptureEnabled = configuration.enableHighResolutionPhoto
        if configuration.enableLivePhotos, photoOutput.isLivePhotoCaptureSupported {
            photoOutput.isLivePhotoCaptureEnabled = true
        } else {
            photoOutput.isLivePhotoCaptureEnabled = false
        }
        if configuration.enableDepthData, photoOutput.isDepthDataDeliverySupported {
            photoOutput.isDepthDataDeliveryEnabled = true
        }
        if configuration.enablePortraitEffectsMatte, photoOutput.isPortraitEffectsMatteDeliverySupported {
            photoOutput.isPortraitEffectsMatteDeliveryEnabled = true
        }
        photoOutput.maxPhotoQualityPrioritization = .quality
    }

    private func applySessionPreset() throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        let preset = configuration.sessionPreset.avPreset
        if captureSession.canSetSessionPreset(preset) {
            captureSession.sessionPreset = preset
        } else {
            throw CameraError.formatNotSupported(reason: "Preset \(preset.rawValue) not supported.")
        }
    }

    private func applyConnectionSettings() throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        try applyConnectionSettingsLocked()
    }

    private func applyConnectionSettingsLocked() throws {
        if let connection = movieOutput.connection(with: .video) {
            applyStabilization(on: connection)
            applyMirroring(on: connection)
        }
        if let connection = videoDataOutput.connection(with: .video) {
            applyStabilization(on: connection)
            applyMirroring(on: connection)
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
        if let connection = photoOutput.connection(with: .video) {
            applyMirroring(on: connection)
        }
    }

    private func applyStabilization(on connection: AVCaptureConnection) {
        guard connection.isVideoStabilizationSupported else { return }
        connection.preferredVideoStabilizationMode = configuration.stabilization.avMode
    }

    private func applyMirroring(on connection: AVCaptureConnection) {
        guard let device = currentDevice else { return }
        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = device.position == .front
        }
    }

    private func setActiveFrameRate(_ fps: Int, on device: AVCaptureDevice) throws {
        let format = device.activeFormat
        guard format.videoSupportedFrameRateRanges.contains(where: { Float($0.minFrameRate) <= Float(fps) && Float($0.maxFrameRate) >= Float(fps) }) else {
            throw CameraError.formatNotSupported(reason: "Frame rate \(fps) not supported by active format.")
        }
        do {
            try device.lockForConfiguration()
            device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(fps))
            device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(fps))
            device.unlockForConfiguration()
        } catch {
            throw CameraError.deviceLockFailed(underlying: error)
        }
    }

    private func addOutputIfNeeded(_ output: AVCaptureOutput) {
        if !captureSession.outputs.contains(output), captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        }
    }

    private func removeOutputIfNeeded(_ output: AVCaptureOutput) {
        if captureSession.outputs.contains(output) {
            captureSession.removeOutput(output)
        }
    }
}

extension CameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.cameraSession(self, didOutputVideoSampleBuffer: sampleBuffer)
        filters.process(sampleBuffer: sampleBuffer)
    }
}
