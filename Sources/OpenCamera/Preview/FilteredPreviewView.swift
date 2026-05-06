import CoreImage
import MetalKit
import SwiftUI
import UIKit

public final class FilteredPreviewView: MTKView {

    private let commandQueue: MTLCommandQueue?
    private let ciContext: CIContext
    private var image: CIImage?
    private let renderQueue = DispatchQueue(label: "com.opencamera.filtered.render")

    public init(device: MTLDevice? = MTLCreateSystemDefaultDevice()) {
        let mtlDevice = device
        self.commandQueue = mtlDevice?.makeCommandQueue()
        if let mtlDevice {
            self.ciContext = CIContext(mtlDevice: mtlDevice)
        } else {
            self.ciContext = CIContext()
        }
        super.init(frame: .zero, device: mtlDevice)
        self.framebufferOnly = false
        self.isPaused = true
        self.enableSetNeedsDisplay = true
        self.colorPixelFormat = .bgra8Unorm
        self.contentScaleFactor = UIScreen.main.scale
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    public func display(image: CIImage) {
        renderQueue.async { [weak self] in
            self?.image = image
            DispatchQueue.main.async {
                self?.setNeedsDisplay()
            }
        }
    }

    public override func draw(_ rect: CGRect) {
        guard
            let image = image,
            let drawable = currentDrawable,
            let commandBuffer = commandQueue?.makeCommandBuffer()
        else { return }

        let drawableSize = drawable.layer.drawableSize
        let scaleX = drawableSize.width / image.extent.width
        let scaleY = drawableSize.height / image.extent.height
        let scale = max(scaleX, scaleY)
        let scaled = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let xOffset = (scaled.extent.width - drawableSize.width) / 2
        let yOffset = (scaled.extent.height - drawableSize.height) / 2
        let centered = scaled.transformed(by: CGAffineTransform(translationX: -xOffset, y: -yOffset))

        let dest = CIRenderDestination(
            width: Int(drawableSize.width),
            height: Int(drawableSize.height),
            pixelFormat: colorPixelFormat,
            commandBuffer: commandBuffer,
            mtlTextureProvider: { drawable.texture }
        )

        do {
            _ = try ciContext.startTask(toRender: centered, to: dest)
        } catch {
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

public struct FilteredCameraPreview: UIViewRepresentable {

    public let session: CameraSession

    public init(session: CameraSession) {
        self.session = session
    }

    public func makeUIView(context: Context) -> FilteredPreviewView {
        let view = FilteredPreviewView()
        session.filters.isEnabled = true
        session.filters.setHandler { image in
            view.display(image: image)
        }
        return view
    }

    public func updateUIView(_ uiView: FilteredPreviewView, context: Context) {}

    public static func dismantleUIView(_ uiView: FilteredPreviewView, coordinator: ()) {
    }
}
