import CoreImage
import CoreImage.CIFilterBuiltins

public protocol CameraFilter {
    var name: String { get }
    func apply(to image: CIImage) -> CIImage
}

public struct PassthroughFilter: CameraFilter {
    public let name = "None"
    public init() {}
    public func apply(to image: CIImage) -> CIImage { image }
}

public struct CIBuiltInFilter: CameraFilter {
    public let name: String
    public let ciFilterName: String
    public let parameters: [String: Any]

    public init(name: String, ciFilterName: String, parameters: [String: Any] = [:]) {
        self.name = name
        self.ciFilterName = ciFilterName
        self.parameters = parameters
    }

    public func apply(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: ciFilterName) else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        for (key, value) in parameters {
            filter.setValue(value, forKey: key)
        }
        return filter.outputImage ?? image
    }
}

public enum BuiltInFilters {
    public static let none: CameraFilter = PassthroughFilter()
    public static let mono = CIBuiltInFilter(name: "Mono", ciFilterName: "CIPhotoEffectMono")
    public static let noir = CIBuiltInFilter(name: "Noir", ciFilterName: "CIPhotoEffectNoir")
    public static let chrome = CIBuiltInFilter(name: "Chrome", ciFilterName: "CIPhotoEffectChrome")
    public static let fade = CIBuiltInFilter(name: "Fade", ciFilterName: "CIPhotoEffectFade")
    public static let instant = CIBuiltInFilter(name: "Instant", ciFilterName: "CIPhotoEffectInstant")
    public static let process = CIBuiltInFilter(name: "Process", ciFilterName: "CIPhotoEffectProcess")
    public static let tonal = CIBuiltInFilter(name: "Tonal", ciFilterName: "CIPhotoEffectTonal")
    public static let transfer = CIBuiltInFilter(name: "Transfer", ciFilterName: "CIPhotoEffectTransfer")
    public static let sepia = CIBuiltInFilter(name: "Sepia", ciFilterName: "CISepiaTone", parameters: [kCIInputIntensityKey: 0.9])
    public static let invert = CIBuiltInFilter(name: "Invert", ciFilterName: "CIColorInvert")
    public static let vibrance = CIBuiltInFilter(name: "Vibrance", ciFilterName: "CIVibrance", parameters: ["inputAmount": 1.0])
    public static let posterize = CIBuiltInFilter(name: "Posterize", ciFilterName: "CIColorPosterize", parameters: ["inputLevels": 6])

    public static let all: [CameraFilter] = [
        none, mono, noir, chrome, fade, instant, process, tonal, transfer, sepia, invert, vibrance, posterize
    ]
}
