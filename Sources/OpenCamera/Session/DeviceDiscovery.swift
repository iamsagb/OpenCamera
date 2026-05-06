import AVFoundation

public enum DeviceDiscovery {

    public static func device(
        position: CameraPosition,
        preferredLens: CameraLens? = nil
    ) -> AVCaptureDevice? {
        let lensOrder: [CameraLens] = {
            if let preferredLens { return [preferredLens] + fallbackOrder.filter { $0 != preferredLens } }
            return fallbackOrder
        }()

        for lens in lensOrder {
            if let device = AVCaptureDevice.default(lens.avDeviceType, for: .video, position: position.avPosition) {
                return device
            }
        }
        return AVCaptureDevice.default(for: .video)
    }

    public static func availableLenses(position: CameraPosition) -> [CameraLens] {
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: allDeviceTypes,
            mediaType: .video,
            position: position.avPosition
        )
        return session.devices.compactMap { device in
            allLenses.first { $0.avDeviceType == device.deviceType }
        }
    }

    public static func allVideoDevices() -> [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: allDeviceTypes,
            mediaType: .video,
            position: .unspecified
        ).devices
    }

    public static func microphone() -> AVCaptureDevice? {
        AVCaptureDevice.default(for: .audio)
    }

    private static let fallbackOrder: [CameraLens] = [
        .triple, .dual, .dualWide, .wide, .ultraWide, .telephoto, .trueDepth
    ]

    private static let allLenses: [CameraLens] = [
        .wide, .ultraWide, .telephoto, .dual, .dualWide, .triple, .trueDepth
    ]

    private static let allDeviceTypes: [AVCaptureDevice.DeviceType] = [
        .builtInWideAngleCamera,
        .builtInUltraWideCamera,
        .builtInTelephotoCamera,
        .builtInDualCamera,
        .builtInDualWideCamera,
        .builtInTripleCamera,
        .builtInTrueDepthCamera
    ]
}
