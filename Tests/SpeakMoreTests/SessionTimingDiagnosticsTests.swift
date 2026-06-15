import Foundation
import XCTest
@testable import SpeakMore

final class SessionTimingDiagnosticsTests: XCTestCase {
    func testSlowFirstTranscriptProducesVisibleHint() {
        let summary = SessionTimingDiagnostics.makeSummary(
            startedAt: Date(timeIntervalSince1970: 0),
            firstTranscriptAt: Date(timeIntervalSince1970: 1.4),
            transformStartedAt: Date(timeIntervalSince1970: 2.0),
            finishedAt: Date(timeIntervalSince1970: 3.0)
        )

        XCTAssertEqual(summary.visibleHint, "响应偏慢：开始到出字 1.4 秒")
        XCTAssertTrue(summary.logLine.contains("firstTranscript=1.40s"))
    }

    func testFastSessionOnlyLogsWithoutVisibleHint() {
        let summary = SessionTimingDiagnostics.makeSummary(
            startedAt: Date(timeIntervalSince1970: 0),
            firstTranscriptAt: Date(timeIntervalSince1970: 0.4),
            transformStartedAt: Date(timeIntervalSince1970: 1.0),
            finishedAt: Date(timeIntervalSince1970: 1.5)
        )

        XCTAssertNil(summary.visibleHint)
        XCTAssertTrue(summary.logLine.contains("total=1.50s"))
    }
}
