import AVFoundation
import XCTest
@testable import SpeakMore

final class AudioCaptureEngineTests: XCTestCase {
    func testStartUsesPlainMicrophoneInputByDefault() throws {
        let inputNode = FakeAudioInputNode()
        let engineCore = FakeAudioEngineCore(inputNode: inputNode)
        let captureEngine = AudioCaptureEngine(engineCore: engineCore)

        try captureEngine.start { _ in }

        XCTAssertEqual(inputNode.events, [.removeTap(0), .outputFormat(0), .installTap(0)])
        XCTAssertEqual(engineCore.events, [.stop, .prepare, .start])
    }
}

private final class FakeAudioEngineCore: AudioEngineCore {
    enum Event: Equatable {
        case prepare
        case start
        case stop
    }

    let inputNode: AudioInputNodeCore
    private(set) var events: [Event] = []

    init(inputNode: AudioInputNodeCore) {
        self.inputNode = inputNode
    }

    func prepare() {
        events.append(.prepare)
    }

    func start() throws {
        events.append(.start)
    }

    func stop() {
        events.append(.stop)
    }
}

private final class FakeAudioInputNode: AudioInputNodeCore {
    enum Event: Equatable {
        case outputFormat(AVAudioNodeBus)
        case installTap(AVAudioNodeBus)
        case removeTap(AVAudioNodeBus)
    }

    private(set) var events: [Event] = []

    func outputFormat(forBus bus: AVAudioNodeBus) -> AVAudioFormat {
        events.append(.outputFormat(bus))
        return AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48_000, channels: 1, interleaved: false)!
    }

    func installTap(
        onBus bus: AVAudioNodeBus,
        bufferSize: AVAudioFrameCount,
        format: AVAudioFormat,
        block tapBlock: @escaping AVAudioNodeTapBlock
    ) {
        events.append(.installTap(bus))
    }

    func removeTap(onBus bus: AVAudioNodeBus) {
        events.append(.removeTap(bus))
    }
}
