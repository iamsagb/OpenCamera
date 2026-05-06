import AVFoundation
import UIKit

public struct RecordedVideo {
    public let url: URL
    public let duration: CMTime
    public let resolution: CGSize?
}

public final class VideoCapture: NSObject {

    private weak var session: CameraSession?
    private var startContinuation: CheckedContinuation<URL, Error>?
    private var stopContinuation: CheckedContinuation<RecordedVideo, Error>?
    private var startedURL: URL?

    init(session: CameraSession) {
        self.session = session
        super.init()
    }

    public var isRecording: Bool {
        session?.movieOutput.isRecording ?? false
    }

    public func startRecording(to url: URL? = nil) async throws -> URL {
        guard let session else { throw CameraError.sessionNotRunning }
        guard session.isRunning else { throw CameraError.sessionNotRunning }
        guard !session.movieOutput.isRecording else {
            throw CameraError.recordingFailed(underlying: nil)
        }

        let outputURL = url ?? FileManager.default.temporaryDirectory
            .appendingPathComponent("video-\(UUID().uuidString).mov")
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }

        applyVideoSettings(in: session)
        applyOrientation(in: session)

        return try await withCheckedThrowingContinuation { continuation in
            self.startContinuation = continuation
            self.startedURL = outputURL
            session.movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        }
    }

    public func stopRecording() async throws -> RecordedVideo {
        guard let session else { throw CameraError.sessionNotRunning }
        guard session.movieOutput.isRecording else {
            throw CameraError.recordingFailed(underlying: nil)
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.stopContinuation = continuation
            session.movieOutput.stopRecording()
        }
    }

    private func applyVideoSettings(in session: CameraSession) {
        let movieOutput = session.movieOutput
        guard let connection = movieOutput.connection(with: .video) else { return }
        let codec = session.configuration.videoCodec.avCodec
        if movieOutput.availableVideoCodecTypes.contains(codec) {
            movieOutput.setOutputSettings([AVVideoCodecKey: codec], for: connection)
        }
        if connection.isVideoStabilizationSupported {
            connection.preferredVideoStabilizationMode = session.configuration.stabilization.avMode
        }
    }

    private func applyOrientation(in session: CameraSession) {
        guard let connection = session.movieOutput.connection(with: .video) else { return }
        if connection.isVideoOrientationSupported,
           let orientation = CameraOrientation.from(deviceOrientation: UIDevice.current.orientation) {
            connection.videoOrientation = orientation.avVideoOrientation
        }
    }
}

extension VideoCapture: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        let continuation = startContinuation
        startContinuation = nil
        continuation?.resume(returning: fileURL)
    }

    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        let continuation = stopContinuation
        stopContinuation = nil
        if let error = error {
            let nsError = error as NSError
            let interrupted = nsError.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool ?? false
            if interrupted == false {
                continuation?.resume(throwing: CameraError.recordingFailed(underlying: error))
                return
            }
        }
        let asset = AVURLAsset(url: outputFileURL)
        let duration = asset.duration
        let track = asset.tracks(withMediaType: .video).first
        let size = track?.naturalSize
        let result = RecordedVideo(url: outputFileURL, duration: duration, resolution: size)
        continuation?.resume(returning: result)
    }
}
