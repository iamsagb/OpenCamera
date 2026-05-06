import AVFoundation
import UIKit

public final class CameraPreviewView: UIView {

    public override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    public var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    public weak var session: CameraSession? {
        didSet { previewLayer.session = session?.captureSession }
    }

    public var videoGravity: AVLayerVideoGravity {
        get { previewLayer.videoGravity }
        set { previewLayer.videoGravity = newValue }
    }

    public init(session: CameraSession? = nil) {
        super.init(frame: .zero)
        previewLayer.videoGravity = .resizeAspectFill
        if let session {
            self.session = session
            previewLayer.session = session.captureSession
        }
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        previewLayer.videoGravity = .resizeAspectFill
    }

    public func capturePoint(for layerPoint: CGPoint) -> CGPoint {
        previewLayer.captureDevicePointConverted(fromLayerPoint: layerPoint)
    }
}
