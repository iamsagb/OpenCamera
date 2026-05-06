import AVFoundation
import CoreImage
import CoreMedia
import OpenCamera
import Photos
import SwiftUI
import UIKit

@MainActor
final class CameraViewModel: ObservableObject {

    let session = OpenCamera.makeSession(.defaultPhoto)

    @Published var isReady: Bool = false
    @Published var isRecording: Bool = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var mode: CameraMode = .photo
    @Published var position: CameraPosition = .back
    @Published var flashMode: FlashMode = .auto
    @Published var torchOn: Bool = false
    @Published var zoom: CGFloat = 1.0
    @Published var iso: Float = 100
    @Published var exposureBias: Float = 0
    @Published var exposureDurationMillis: Float = 16
    @Published var whiteBalanceTemperature: Float = 5500
    @Published var whiteBalanceTint: Float = 0
    @Published var manualMode: Bool = false
    @Published var errorMessage: String?
    @Published var selectedFilterIndex: Int = 0
    @Published var availableLenses: [CameraLens] = []
    @Published var captures: [CapturedItem] = []
    @Published var settings = CameraSettings()
    @Published var focusIndicator: CGPoint?

    let availableFilters: [CameraFilter] = BuiltInFilters.all
    var currentFilter: CameraFilter { availableFilters[selectedFilterIndex] }
    var hasActiveFilter: Bool { !(currentFilter is PassthroughFilter) }

    private var recordingTimer: Timer?
    private var recordingStart: Date?

    func prepare() async {
        do {
            try await session.prepare()
            session.filters.isEnabled = true
            session.filters.setFilter(availableFilters[selectedFilterIndex])
            try await session.start()
            availableLenses = DeviceDiscovery.availableLenses(position: position)
            isReady = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleMode() async {
        let newMode: CameraMode = mode == .photo ? .video : .photo
        do {
            try await session.setMode(newMode)
            try await session.updateConfiguration { [self] config in
                config.mode = newMode
                if newMode == .photo {
                    config.sessionPreset = .photo
                } else {
                    config.sessionPreset = self.settings.sessionPreset
                    config.videoCodec = self.settings.videoCodec
                    config.stabilization = self.settings.stabilization
                }
            }
            mode = newMode
            if newMode == .video { try? session.controls.setFrameRate(settings.frameRate) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func switchCamera() async {
        do {
            try await session.switchCamera()
            position = session.configuration.position
            availableLenses = DeviceDiscovery.availableLenses(position: position)
            zoom = 1.0
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setLens(_ lens: CameraLens) async {
        do {
            try await session.setPosition(position, lens: lens)
            zoom = 1.0
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleFlash() {
        flashMode = nextFlash(flashMode)
        session.controls.setFlashMode(flashMode)
    }

    func toggleTorch() {
        torchOn.toggle()
        do {
            try session.controls.setTorchMode(torchOn ? .on : .off)
        } catch {
            errorMessage = error.localizedDescription
            torchOn = !torchOn
        }
    }

    func capturePhoto() async {
        do {
            let photo = try await session.photo.capture(
                flashMode: flashMode,
                format: settings.photoFormat
            )
            guard let original = photo.image else { return }
            let final = applyFilterIfNeeded(to: original)
            let item = CapturedItem(media: .photo(final), date: Date())
            captures.insert(item, at: 0)
            await saveToLibrary(image: final, livePhotoMovie: photo.livePhotoMovieURL)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleRecording() async {
        if isRecording {
            do {
                let video = try await session.video.stopRecording()
                stopRecordingTimer()
                let finalURL: URL
                if settings.convertVideoToMP4 {
                    finalURL = await convertToMP4(video.url) ?? video.url
                } else {
                    finalURL = video.url
                }
                let item = CapturedItem(media: .video(finalURL), date: Date())
                captures.insert(item, at: 0)
                isRecording = false
                await saveVideoToLibrary(url: finalURL)
            } catch {
                stopRecordingTimer()
                isRecording = false
                errorMessage = error.localizedDescription
            }
        } else {
            do {
                _ = try await session.video.startRecording()
                isRecording = true
                startRecordingTimer()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func handleTapToFocus(_ point: CGPoint, viewPoint: CGPoint) {
        do {
            try session.controls.focus(at: point, mode: .autoFocus)
            try session.controls.expose(at: point, mode: .autoExpose)
            focusIndicator = viewPoint
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.focusIndicator = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func handlePinchZoom(_ scale: CGFloat) {
        let newZoom = max(1.0, min(maxZoom, zoom * scale))
        do {
            try session.controls.setZoom(newZoom)
            zoom = newZoom
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var maxZoom: CGFloat {
        session.controls.maxAvailableVideoZoomFactor ?? 5
    }

    func setManualMode(_ enabled: Bool) {
        manualMode = enabled
        do {
            try session.controls.setExposureMode(enabled ? .custom : .continuousAutoExposure)
            try session.controls.setWhiteBalanceMode(enabled ? .locked : .continuousAutoWhiteBalance)
            try session.controls.setFocusMode(enabled ? .locked : .continuousAutoFocus)
            if enabled { applyManualValues() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func applyManualValues() {
        guard manualMode else { return }
        do {
            let durationSeconds = Double(exposureDurationMillis) / 1000.0
            let duration = CMTimeMakeWithSeconds(durationSeconds, preferredTimescale: 1_000_000_000)
            try session.controls.setExposure(duration: duration, iso: iso)
            try session.controls.setWhiteBalanceGains(
                WhiteBalanceGains(temperature: whiteBalanceTemperature, tint: whiteBalanceTint)
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setExposureBias(_ bias: Float) {
        exposureBias = bias
        do { try session.controls.setExposureTargetBias(bias) }
        catch { errorMessage = error.localizedDescription }
    }

    func setSelectedFilter(_ index: Int) {
        selectedFilterIndex = index
        session.filters.setFilter(availableFilters[index])
    }

    func applySettings() async {
        do {
            try await session.updateConfiguration { config in
                config.videoCodec = self.settings.videoCodec
                config.stabilization = self.settings.stabilization
                config.enableLivePhotos = self.settings.enableLivePhotos
                config.enableDepthData = self.settings.enableDepthData
                config.enablePortraitEffectsMatte = self.settings.enablePortraitMatte
                config.enableHDR = self.settings.enableHDR
                config.enableAudio = self.settings.enableAudio
                if self.mode == .video {
                    config.sessionPreset = self.settings.sessionPreset
                }
            }
            if mode == .video {
                try? session.controls.setFrameRate(settings.frameRate)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func nextFlash(_ mode: FlashMode) -> FlashMode {
        switch mode {
        case .auto: return .on
        case .on: return .off
        case .off: return .auto
        }
    }

    private func applyFilterIfNeeded(to image: UIImage) -> UIImage {
        guard hasActiveFilter else { return image }
        guard let ciImage = CIImage(image: image) else { return image }
        let filtered = currentFilter.apply(to: ciImage)
        let context = session.filters.context
        guard let cg = context.createCGImage(filtered, from: filtered.extent) else { return image }
        return UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
    }

    private func convertToMP4(_ source: URL) async -> URL? {
        let asset = AVURLAsset(url: source)
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("video-\(UUID().uuidString).mp4")
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else { return nil }
        exporter.outputURL = dest
        exporter.outputFileType = .mp4
        exporter.shouldOptimizeForNetworkUse = true
        await exporter.export()
        return exporter.status == .completed ? dest : nil
    }

    private func startRecordingTimer() {
        recordingStart = Date()
        recordingDuration = 0
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let start = self.recordingStart else { return }
                self.recordingDuration = Date().timeIntervalSince(start)
            }
        }
    }

    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingStart = nil
    }

    private func saveToLibrary(image: UIImage, livePhotoMovie: URL?) async {
        let status = await CameraPermissions.requestPhotoLibrary()
        guard status == .authorized || status == .limited else { return }
        guard let data = image.jpegData(compressionQuality: 0.95) else { return }
        try? await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: data, options: nil)
            if let movie = livePhotoMovie {
                request.addResource(with: .pairedVideo, fileURL: movie, options: nil)
            }
        }
    }

    private func saveVideoToLibrary(url: URL) async {
        let status = await CameraPermissions.requestPhotoLibrary()
        guard status == .authorized || status == .limited else { return }
        try? await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }
    }
}
