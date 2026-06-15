import Foundation

struct SessionTimingSummary: Equatable {
    let visibleHint: String?
    let logLine: String
}

enum SessionTimingDiagnostics {
    static func makeSummary(
        startedAt: Date,
        firstTranscriptAt: Date?,
        transformStartedAt: Date?,
        finishedAt: Date
    ) -> SessionTimingSummary {
        let firstTranscriptSeconds = firstTranscriptAt?.timeIntervalSince(startedAt)
        let transformSeconds = transformStartedAt.flatMap { transformStartedAt in
            Optional(finishedAt.timeIntervalSince(transformStartedAt))
        }
        let totalSeconds = finishedAt.timeIntervalSince(startedAt)

        let visibleHint: String?
        if let firstTranscriptSeconds, firstTranscriptSeconds >= 1.2 {
            visibleHint = "响应偏慢：开始到出字 \(formatVisible(firstTranscriptSeconds)) 秒"
        } else if let transformSeconds, transformSeconds >= 3.0 {
            visibleHint = "响应偏慢：AI 整理 \(formatVisible(transformSeconds)) 秒"
        } else {
            visibleHint = nil
        }

        let logLine = [
            "firstTranscript=\(formatLog(firstTranscriptSeconds))s",
            "transform=\(formatLog(transformSeconds))s",
            "total=\(formatLog(totalSeconds))s"
        ].joined(separator: " ")

        return SessionTimingSummary(visibleHint: visibleHint, logLine: logLine)
    }

    private static func formatLog(_ value: TimeInterval?) -> String {
        guard let value else {
            return "--"
        }
        return String(format: "%.2f", value)
    }

    private static func formatLog(_ value: TimeInterval) -> String {
        String(format: "%.2f", value)
    }

    private static func formatVisible(_ value: TimeInterval) -> String {
        String(format: "%.1f", value)
    }
}
