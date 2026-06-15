import AVFoundation
import XCTest
@testable import SpeakMore

final class AudioQualityMonitorTests: XCTestCase {
    func testDetectsQuietInput() throws {
        let snapshot = try AudioQualityAnalyzer.analyze(buffer: makeBuffer(samples: Array(repeating: 0.003, count: 512)))

        XCTAssertEqual(snapshot.issue, .tooQuiet)
    }

    func testDetectsSteadyBackgroundNoise() throws {
        let samples = (0..<512).map { index in
            Float(index.isMultiple(of: 2) ? 0.04 : -0.04)
        }

        let snapshot = try AudioQualityAnalyzer.analyze(buffer: makeBuffer(samples: samples))

        XCTAssertEqual(snapshot.issue, .backgroundNoise)
    }

    func testDetectsClippingInput() throws {
        let snapshot = try AudioQualityAnalyzer.analyze(buffer: makeBuffer(samples: Array(repeating: 1.0, count: 512)))

        XCTAssertEqual(snapshot.issue, .clipping)
    }

    func testLeavesDynamicSpeechLikeInputUnflagged() throws {
        var samples = Array(repeating: Float(0.01), count: 512)
        for index in stride(from: 0, to: samples.count, by: 32) {
            samples[index] = 0.45
        }

        let snapshot = try AudioQualityAnalyzer.analyze(buffer: makeBuffer(samples: samples))

        XCTAssertNil(snapshot.issue)
    }

    private func makeBuffer(samples: [Float]) throws -> AVAudioPCMBuffer {
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48_000, channels: 1, interleaved: false)!
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)))
        buffer.frameLength = AVAudioFrameCount(samples.count)
        let channel = try XCTUnwrap(buffer.floatChannelData?[0])
        for (index, sample) in samples.enumerated() {
            channel[index] = sample
        }
        return buffer
    }
}
