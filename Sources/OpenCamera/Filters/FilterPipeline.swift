import AVFoundation
import CoreImage
import CoreMedia
import UIKit

public final class FilterPipeline {

    public typealias FilteredImageHandler = (CIImage) -> Void

    private weak var session: CameraSession?
    private let ciContext: CIContext

    private let lock = NSLock()
    private var _filter: CameraFilter = PassthroughFilter()
    private var _handler: FilteredImageHandler?

    public var isEnabled: Bool = false

    init(session: CameraSession) {
        self.session = session
        if let device = MTLCreateSystemDefaultDevice() {
            self.ciContext = CIContext(mtlDevice: device)
        } else {
            self.ciContext = CIContext()
        }
    }

    public var context: CIContext { ciContext }

    public var currentFilter: CameraFilter {
        lock.lock(); defer { lock.unlock() }
        return _filter
    }

    public func setFilter(_ filter: CameraFilter) {
        lock.lock()
        _filter = filter
        lock.unlock()
    }

    public func setHandler(_ handler: FilteredImageHandler?) {
        lock.lock()
        _handler = handler
        lock.unlock()
    }

    func process(sampleBuffer: CMSampleBuffer) {
        guard isEnabled else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let image = CIImage(cvPixelBuffer: pixelBuffer)

        lock.lock()
        let filter = _filter
        let handler = _handler
        lock.unlock()

        let output = filter.apply(to: image)
        handler?(output)
    }

    public func render(_ image: CIImage, to pixelBuffer: CVPixelBuffer) {
        ciContext.render(image, to: pixelBuffer)
    }

    public func renderImage(_ image: CIImage) -> UIImage? {
        guard let cg = ciContext.createCGImage(image, from: image.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
