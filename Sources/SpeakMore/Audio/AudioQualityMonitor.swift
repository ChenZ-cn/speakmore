@preconcurrency import AVFoundation
import Foundation

enum AudioQualityIssue: Equatable {
    case tooQuiet
    case backgroundNoise
    case clipping
}

enum AudioQualityMeterKind: Hashable {
    case inputVolume
    case backgroundNoise
}

enum AudioQualityMeterStatus: Equatable {
    case low
    case good
    case high
}

struct AudioQualitySnapshot: Equatable {
    let issue: AudioQualityIssue?
    let rmsDBFS: Double
    let peakDBFS: Double
    let crestDB: Double

    func meterStatus(for kind: AudioQualityMeterKind) -> AudioQualityMeterStatus {
        switch kind {
        case .inputVolume:
            if peakDBFS >= -0.3 {
                return .high
            }
            if inputVolumeScore < 0.8 {
                return .low
            }
            return .good
        case .backgroundNoise:
            return issue == .backgroundNoise ? .high : .good
        }
    }

    func meterSeverity(for kind: AudioQualityMeterKind) -> Double {
        switch kind {
        case .inputVolume:
            if peakDBFS >= -0.3 {
                return clamped((peakDBFS + 3) / 3)
            }
            let score = inputVolumeScore
            guard score < 0.8 else {
                return 0
            }
            return clamped((0.8 - score) / 0.8)
        case .backgroundNoise:
            guard issue == .backgroundNoise else {
                return 0
            }
            return clamped((rmsDBFS + 38) / 10)
        }
    }

    private var inputVolumeScore: Double {
        clamped((rmsDBFS + 58) / 20)
    }

    private func clamped(_ value: Double) -> Double {
        min(1, max(0, value))
    }
}

enum AudioQualityAnalyzer {
    static func analyze(buffer: AVAudioPCMBuffer) throws -> AudioQualitySnapshot {
        guard let channel = buffer.floatChannelData?[0], buffer.frameLength > 0 else {
            return AudioQualitySnapshot(issue: nil, rmsDBFS: -120, peakDBFS: -120, crestDB: 0)
        }

        let sampleCount = Int(buffer.frameLength)
        var sumSquares: Double = 0
        var peak: Float = 0

        for sample in UnsafeBufferPointer(start: channel, count: sampleCount) {
            let magnitude = abs(sample)
            peak = max(peak, magnitude)
            sumSquares += Double(sample * sample)
        }

        let rms = sqrt(sumSquares / Double(sampleCount))
        let rmsDBFS = decibels(fromLinear: rms)
        let peakDBFS = decibels(fromLinear: Double(peak))
        let crestDB = peakDBFS - rmsDBFS

        let issue: AudioQualityIssue?
        if peakDBFS >= -0.3 {
            issue = .clipping
        } else if rmsDBFS <= -42 {
            issue = .tooQuiet
        } else if rmsDBFS >= -34 && crestDB <= 7 {
            issue = .backgroundNoise
        } else {
            issue = nil
        }

        return AudioQualitySnapshot(issue: issue, rmsDBFS: rmsDBFS, peakDBFS: peakDBFS, crestDB: crestDB)
    }

    private static func decibels(fromLinear value: Double) -> Double {
        guard value > 0 else {
            return -120
        }
        return max(-120, 20 * log10(value))
    }
}

protocol AudioQualityMonitoring: AnyObject {
    func process(buffer: AVAudioPCMBuffer)
}

final class AudioQualityMonitor: AudioQualityMonitoring {
    private let minimumInterval: TimeInterval
    private let onSnapshot: @MainActor (AudioQualitySnapshot) -> Void
    private var lastEmitDate: Date?

    init(
        minimumInterval: TimeInterval = 0.45,
        onSnapshot: @escaping @MainActor (AudioQualitySnapshot) -> Void
    ) {
        self.minimumInterval = minimumInterval
        self.onSnapshot = onSnapshot
    }

    func process(buffer: AVAudioPCMBuffer) {
        let now = Date()
        if let lastEmitDate, now.timeIntervalSince(lastEmitDate) < minimumInterval {
            return
        }
        lastEmitDate = now

        guard let snapshot = try? AudioQualityAnalyzer.analyze(buffer: buffer) else {
            return
        }

        let onSnapshot = onSnapshot
        Task { @MainActor in
            onSnapshot(snapshot)
        }
    }
}
