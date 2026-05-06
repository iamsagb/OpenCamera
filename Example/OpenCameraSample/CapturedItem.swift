import AVFoundation
import Foundation
import UIKit

enum CapturedMedia {
    case photo(UIImage)
    case video(URL)
}

struct CapturedItem: Identifiable, Equatable {
    let id = UUID()
    let media: CapturedMedia
    let date: Date

    var thumbnail: UIImage? {
        switch media {
        case .photo(let image): return image
        case .video(let url): return Self.makeThumbnail(for: url)
        }
    }

    var isVideo: Bool {
        if case .video = media { return true }
        return false
    }

    static func == (lhs: CapturedItem, rhs: CapturedItem) -> Bool {
        lhs.id == rhs.id
    }

    private static func makeThumbnail(for url: URL) -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0.1, preferredTimescale: 600)
        guard let cg = try? generator.copyCGImage(at: time, actualTime: nil) else { return nil }
        return UIImage(cgImage: cg)
    }
}
