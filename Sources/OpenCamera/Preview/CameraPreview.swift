import AVFoundation
import SwiftUI
import UIKit

public struct PreviewTap {
    public let devicePoint: CGPoint
    public let viewPoint: CGPoint
}

public struct CameraPreview: UIViewRepresentable {

    public let session: CameraSession
    public var videoGravity: AVLayerVideoGravity
    public var onTapToFocus: ((PreviewTap) -> Void)?
    public var onPinchZoom: ((CGFloat) -> Void)?

    public init(
        session: CameraSession,
        videoGravity: AVLayerVideoGravity = .resizeAspectFill,
        onTapToFocus: ((PreviewTap) -> Void)? = nil,
        onPinchZoom: ((CGFloat) -> Void)? = nil
    ) {
        self.session = session
        self.videoGravity = videoGravity
        self.onTapToFocus = onTapToFocus
        self.onPinchZoom = onPinchZoom
    }

    public func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView(session: session)
        view.videoGravity = videoGravity
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)
        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        view.addGestureRecognizer(pinch)
        context.coordinator.view = view
        return view
    }

    public func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        uiView.session = session
        uiView.videoGravity = videoGravity
        context.coordinator.parent = self
    }

    public func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    public final class Coordinator: NSObject {
        var parent: CameraPreview
        weak var view: CameraPreviewView?

        init(parent: CameraPreview) {
            self.parent = parent
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = view else { return }
            let layerPoint = gesture.location(in: view)
            let devicePoint = view.capturePoint(for: layerPoint)
            parent.onTapToFocus?(PreviewTap(devicePoint: devicePoint, viewPoint: layerPoint))
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            parent.onPinchZoom?(gesture.scale)
            if gesture.state == .changed { gesture.scale = 1.0 }
        }
    }
}
