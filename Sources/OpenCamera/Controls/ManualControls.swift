import AVFoundation
import CoreMedia
import CoreGraphics

public final class ManualControls {

    private weak var session: CameraSession?

    init(session: CameraSession) {
        self.session = session
    }

    private var device: AVCaptureDevice? { session?.currentDevice }

    public var minISO: Float? { device?.activeFormat.minISO }
    public var maxISO: Float? { device?.activeFormat.maxISO }
    public var minExposureDuration: CMTime? { device?.activeFormat.minExposureDuration }
    public var maxExposureDuration: CMTime? { device?.activeFormat.maxExposureDuration }
    public var minExposureTargetBias: Float? { device?.minExposureTargetBias }
    public var maxExposureTargetBias: Float? { device?.maxExposureTargetBias }
    public var maxZoomFactor: CGFloat? { device?.activeFormat.videoMaxZoomFactor }
    public var minAvailableVideoZoomFactor: CGFloat? { device?.minAvailableVideoZoomFactor }
    public var maxAvailableVideoZoomFactor: CGFloat? { device?.maxAvailableVideoZoomFactor }

    public func setFocusMode(_ mode: FocusMode) throws {
        try lock { device in
            guard device.isFocusModeSupported(mode.avFocusMode) else {
                throw CameraError.unsupportedFeature(name: "FocusMode \(mode)")
            }
            device.focusMode = mode.avFocusMode
        }
    }

    public func focus(at point: CGPoint, mode: FocusMode = .autoFocus) throws {
        try lock { device in
            guard device.isFocusPointOfInterestSupported else {
                throw CameraError.unsupportedFeature(name: "FocusPointOfInterest")
            }
            device.focusPointOfInterest = point
            if device.isFocusModeSupported(mode.avFocusMode) {
                device.focusMode = mode.avFocusMode
            }
        }
    }

    public func setLensPosition(_ position: Float) throws {
        let clamped = max(0, min(1, position))
        try lock { device in
            guard device.isLockingFocusWithCustomLensPositionSupported else {
                throw CameraError.unsupportedFeature(name: "Manual lens position")
            }
            device.setFocusModeLocked(lensPosition: clamped, completionHandler: nil)
        }
    }

    public func setExposureMode(_ mode: ExposureMode) throws {
        try lock { device in
            guard device.isExposureModeSupported(mode.avExposureMode) else {
                throw CameraError.unsupportedFeature(name: "ExposureMode \(mode)")
            }
            device.exposureMode = mode.avExposureMode
        }
    }

    public func expose(at point: CGPoint, mode: ExposureMode = .autoExpose) throws {
        try lock { device in
            guard device.isExposurePointOfInterestSupported else {
                throw CameraError.unsupportedFeature(name: "ExposurePointOfInterest")
            }
            device.exposurePointOfInterest = point
            if device.isExposureModeSupported(mode.avExposureMode) {
                device.exposureMode = mode.avExposureMode
            }
        }
    }

    public func setExposure(duration: CMTime, iso: Float) throws {
        try lock { device in
            guard device.isExposureModeSupported(.custom) else {
                throw CameraError.unsupportedFeature(name: "Custom exposure")
            }
            let clampedISO = max(device.activeFormat.minISO, min(device.activeFormat.maxISO, iso))
            let minDur = device.activeFormat.minExposureDuration
            let maxDur = device.activeFormat.maxExposureDuration
            let clamped: CMTime
            if CMTimeCompare(duration, minDur) < 0 {
                clamped = minDur
            } else if CMTimeCompare(duration, maxDur) > 0 {
                clamped = maxDur
            } else {
                clamped = duration
            }
            device.setExposureModeCustom(duration: clamped, iso: clampedISO, completionHandler: nil)
        }
    }

    public func setExposureTargetBias(_ bias: Float) throws {
        try lock { device in
            let clamped = max(device.minExposureTargetBias, min(device.maxExposureTargetBias, bias))
            device.setExposureTargetBias(clamped, completionHandler: nil)
        }
    }

    public func setWhiteBalanceMode(_ mode: WhiteBalanceMode) throws {
        try lock { device in
            guard device.isWhiteBalanceModeSupported(mode.avWhiteBalanceMode) else {
                throw CameraError.unsupportedFeature(name: "WhiteBalanceMode \(mode)")
            }
            device.whiteBalanceMode = mode.avWhiteBalanceMode
        }
    }

    public func setWhiteBalanceGains(_ gains: WhiteBalanceGains) throws {
        try lock { device in
            guard device.isLockingWhiteBalanceWithCustomDeviceGainsSupported else {
                throw CameraError.unsupportedFeature(name: "Manual white balance")
            }
            let temperatureAndTint = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(
                temperature: gains.temperature,
                tint: gains.tint
            )
            var deviceGains = device.deviceWhiteBalanceGains(for: temperatureAndTint)
            deviceGains = clampGains(deviceGains, max: device.maxWhiteBalanceGain)
            device.setWhiteBalanceModeLocked(with: deviceGains, completionHandler: nil)
        }
    }

    public func setZoom(_ factor: CGFloat, ramp: Bool = false, rate: Float = 1.0) throws {
        try lock { device in
            let clamped = max(device.minAvailableVideoZoomFactor, min(device.maxAvailableVideoZoomFactor, factor))
            if ramp {
                device.ramp(toVideoZoomFactor: clamped, withRate: rate)
            } else {
                device.videoZoomFactor = clamped
            }
        }
    }

    public func setTorchMode(_ mode: TorchMode) throws {
        try lock { device in
            guard device.hasTorch else {
                throw CameraError.unsupportedFeature(name: "Torch")
            }
            switch mode {
            case .off:
                device.torchMode = .off
            case .auto:
                if device.isTorchModeSupported(.auto) { device.torchMode = .auto }
            case .on:
                if device.isTorchModeSupported(.on) { device.torchMode = .on }
            case .level(let value):
                let clamped = max(0.001, min(1.0, value))
                try device.setTorchModeOn(level: clamped)
            }
        }
    }

    public func setFlashMode(_ mode: FlashMode) {
        session?.configuration.flashMode = mode
    }

    public func setLowLightBoost(_ enabled: Bool) throws {
        try lock { device in
            guard device.isLowLightBoostSupported else {
                throw CameraError.unsupportedFeature(name: "LowLightBoost")
            }
            device.automaticallyEnablesLowLightBoostWhenAvailable = enabled
        }
    }

    public func setFrameRate(_ fps: Int?) throws {
        try lock { device in
            guard let fps else {
                device.activeVideoMinFrameDuration = .invalid
                device.activeVideoMaxFrameDuration = .invalid
                return
            }
            let supported = device.activeFormat.videoSupportedFrameRateRanges.contains { range in
                Float(range.minFrameRate) <= Float(fps) && Float(range.maxFrameRate) >= Float(fps)
            }
            guard supported else {
                throw CameraError.formatNotSupported(reason: "Frame rate \(fps) not supported by active format.")
            }
            device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(fps))
            device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(fps))
        }
    }

    public func supportedFrameRateRanges() -> [(min: Float, max: Float)] {
        guard let device else { return [] }
        return device.activeFormat.videoSupportedFrameRateRanges.map { (Float($0.minFrameRate), Float($0.maxFrameRate)) }
    }

    public func setHDREnabled(_ enabled: Bool) throws {
        try lock { device in
            guard device.activeFormat.isVideoHDRSupported else {
                throw CameraError.unsupportedFeature(name: "VideoHDR")
            }
            device.automaticallyAdjustsVideoHDREnabled = false
            device.isVideoHDREnabled = enabled
        }
    }

    public func setSmoothAutoFocusEnabled(_ enabled: Bool) throws {
        try lock { device in
            guard device.isSmoothAutoFocusSupported else { return }
            device.isSmoothAutoFocusEnabled = enabled
        }
    }

    private func lock(_ block: (AVCaptureDevice) throws -> Void) throws {
        guard let device = device else {
            throw CameraError.noDeviceAvailable(position: session?.configuration.position ?? .unspecified)
        }
        do {
            try device.lockForConfiguration()
        } catch {
            throw CameraError.deviceLockFailed(underlying: error)
        }
        defer { device.unlockForConfiguration() }
        try block(device)
    }

    private func clampGains(_ gains: AVCaptureDevice.WhiteBalanceGains, max maxValue: Float) -> AVCaptureDevice.WhiteBalanceGains {
        var g = gains
        let lower: Float = 1.0
        g.redGain = min(max(g.redGain, lower), maxValue)
        g.greenGain = min(max(g.greenGain, lower), maxValue)
        g.blueGain = min(max(g.blueGain, lower), maxValue)
        return g
    }
}
