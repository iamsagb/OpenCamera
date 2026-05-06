import XCTest
@testable import OpenCamera

final class OpenCameraTests: XCTestCase {
    func testVersion() {
        XCTAssertFalse(OpenCamera.version.isEmpty)
    }

    func testDefaultPhotoConfiguration() {
        let config = CameraConfiguration.defaultPhoto
        XCTAssertEqual(config.mode, .photo)
        XCTAssertEqual(config.position, .back)
    }

    func testDefaultVideoConfiguration() {
        let config = CameraConfiguration.defaultVideo
        XCTAssertEqual(config.mode, .video)
    }

    func testBuiltInFiltersIncludePassthrough() {
        XCTAssertTrue(BuiltInFilters.all.contains(where: { $0.name == "None" }))
    }

    func testMakeSessionReturnsSession() {
        let session = OpenCamera.makeSession()
        XCTAssertNotNil(session)
        XCTAssertFalse(session.isRunning)
    }
}

