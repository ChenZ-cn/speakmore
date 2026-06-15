import XCTest
@testable import SpeakMore

final class SpeakMoreModeTests: XCTestCase {
    func testModeTitlesAreStable() {
        XCTAssertEqual(SpeakMoreMode.auto.title, "自动模式")
        XCTAssertEqual(SpeakMoreMode.dictate.title, "直接听写")
        XCTAssertEqual(SpeakMoreMode.translate.title, "翻译模式")
        XCTAssertEqual(SpeakMoreMode.polish.title, "润色模式")
        XCTAssertEqual(SpeakMoreMode.askSelectedText.title, "对选中文字提问")
    }

    func testAutoModeIsDefaultMenuChoice() {
        XCTAssertEqual(SpeakMoreMode.allCases.first, .auto)
    }

    func testAllModesHaveSubtitles() {
        for mode in SpeakMoreMode.allCases {
            XCTAssertFalse(mode.subtitle.isEmpty)
        }
    }
}
