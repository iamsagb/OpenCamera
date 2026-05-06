import Foundation

public enum OpenCamera {
    public static let version = "0.1.0"

    public static func makeSession(_ configuration: CameraConfiguration = .defaultPhoto) -> CameraSession {
        CameraSession(configuration: configuration)
    }
}
