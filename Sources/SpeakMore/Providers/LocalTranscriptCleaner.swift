import Foundation

struct LocalTranscriptCleaner {
    func fastResult(input: VoiceSessionInput) -> VoiceSessionResult? {
        guard input.mode == .auto || input.mode == .dictate else {
            return nil
        }

        let cleaned = clean(input.rawTranscript)
        if let edited = applyInlineEditingInstruction(to: cleaned) {
            return VoiceSessionResult(
                rawTranscript: input.rawTranscript,
                finalText: edited,
                shouldReplaceSelection: false
            )
        }

        guard isSimpleEnoughForLocalPaste(cleaned) else {
            return nil
        }

        return VoiceSessionResult(
            rawTranscript: input.rawTranscript,
            finalText: cleaned,
            shouldReplaceSelection: false
        )
    }

    func clean(_ transcript: String) -> String {
        var text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        text = removeASRArtifacts(from: text)
        let fillerPrefixes = ["嗯，", "嗯,", "嗯 ", "呃，", "呃,", "呃 ", "那个，", "那个,", "就是，", "就是,"]
        var didRemovePrefix = true
        while didRemovePrefix {
            didRemovePrefix = false
            for prefix in fillerPrefixes where text.hasPrefix(prefix) {
                text.removeFirst(prefix.count)
                text = text.trimmingCharacters(in: .whitespacesAndNewlines)
                didRemovePrefix = true
            }
        }
        return collapseWhitespace(in: text).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func remoteInput(from input: VoiceSessionInput) -> VoiceSessionInput {
        let cleaned = segmentSpokenChineseIfHelpful(clean(input.rawTranscript))
        guard input.mode == .auto || input.mode == .dictate || input.mode == .polish else {
            return VoiceSessionInput(
                mode: input.mode,
                rawTranscript: cleaned,
                selectedText: input.selectedText,
                spokenCommand: input.spokenCommand,
                targetLanguage: input.targetLanguage
            )
        }

        guard let extracted = extractTrailingCommand(from: cleaned) else {
            return VoiceSessionInput(
                mode: input.mode,
                rawTranscript: cleaned,
                selectedText: input.selectedText,
                spokenCommand: input.spokenCommand,
                targetLanguage: input.targetLanguage
            )
        }

        return VoiceSessionInput(
            mode: input.mode,
            rawTranscript: extracted.content,
            selectedText: input.selectedText,
            spokenCommand: input.spokenCommand ?? extracted.command,
            targetLanguage: input.targetLanguage
        )
    }

    private func removeASRArtifacts(from text: String) -> String {
        var cleaned = text
        let artifactPatterns = [
            "[🎼🎵🎶♪♫]+",
            "[\\[【(（]\\s*(音乐|音樂|music|Music|MUSIC|掌声|applause|noise|Noise|NOISE)\\s*[\\]】)）]"
        ]

        for pattern in artifactPatterns {
            cleaned = cleaned.replacingOccurrences(
                of: pattern,
                with: "",
                options: .regularExpression
            )
        }

        return cleaned
    }

    private func extractTrailingCommand(from text: String) -> (content: String, command: String)? {
        let commandPatterns = [
            #"(?i)(?:please\s+)?translate\s+(?:it|this\s+sentence|this\s+paragraph|this\s+text|the\s+above|that)?\s*(?:into|to)\s+[a-z][a-z\s-]*[.!?]?$"#,
            #"(?i)(?:please\s+)?(?:summarize|polish|rewrite|organize|make\s+this\s+into\s+bullet\s+points|turn\s+this\s+into\s+bullet\s+points)[^.!?。！？]*[.!?]?$"#,
            #"((请|帮我)?(把|将)?(它|这句话|这个句子|这段话|上面这段话|以上内容)?(翻译|译|翻)(成|到)(英文|英语|中文|普通话|日文|日语|韩文|韩语|法文|法语|德文|德语|西班牙语|俄语|粤语|广东话)[。.!！?？]?)$"#,
            #"((请|帮我)?(把|将)?(它|这句话|这个句子|这段话|上面这段话|以上内容)?(分点|分条|列点|整理|总结|润色|改写|优化|写自然|写得自然)[^。.!！?？]{0,18}[。.!！?？]?)$"#
        ]

        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        for pattern in commandPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            guard let match = regex.firstMatch(in: text, range: fullRange),
                  match.range.location > 0,
                  match.range.location + match.range.length == nsText.length else {
                continue
            }

            let command = nsText.substring(with: match.range)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let content = nsText.substring(to: match.range.location)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanedContent = removeEmbeddedCommandSentences(from: content)
            guard !cleanedContent.isEmpty else { return nil }
            return (cleanedContent, command)
        }

        return nil
    }

    private func removeEmbeddedCommandSentences(from text: String) -> String {
        let sentenceEnders = CharacterSet(charactersIn: "。.!！?？")
        let sentencePattern = #"[^。.!！?？]+[。.!！?？]?"#
        guard let regex = try? NSRegularExpression(pattern: sentencePattern) else {
            return text
        }

        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        let keptSentences = matches.compactMap { match -> String? in
            let sentence = nsText.substring(with: match.range)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !sentence.isEmpty else { return nil }
            if isCommandSentence(sentence) {
                return nil
            }
            return sentence
        }

        if keptSentences.isEmpty {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let joined = keptSentences.joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let last = joined.last else {
            return joined
        }
        if sentenceEnders.contains(last.unicodeScalars.first!) {
            return joined
        }
        if joined.range(of: "\\p{Han}", options: .regularExpression) != nil {
            return joined + "。"
        }
        return joined + "."
    }

    private func isCommandSentence(_ sentence: String) -> Bool {
        let commandPatterns = [
            #"(?i)^\s*(please\s+)?translate\s+[^。.!！?？]+[。.!！?？]?\s*$"#,
            #"(?i)^\s*(please\s+)?(?:summarize|polish|rewrite|organize|make\s+this\s+into\s+bullet\s+points|turn\s+this\s+into\s+bullet\s+points)[^。.!！?？]*[。.!！?？]?\s*$"#,
            #"^\s*(请|帮我)?(把|将)?[^。.!！?？]{0,16}(翻译|译|翻)(成|到)[^。.!！?？]+[。.!！?？]?\s*$"#,
            #"^\s*(请|帮我)?(把|将)?[^。.!！?？]{0,16}(分点|分条|列点|整理|总结|润色|改写|优化|写自然|写得自然)[^。.!！?？]*[。.!！?？]?\s*$"#
        ]

        return commandPatterns.contains { pattern in
            sentence.range(of: pattern, options: .regularExpression) != nil
        }
    }

    private func applyInlineEditingInstruction(to text: String) -> String? {
        let instructionPatterns = [
            "你?把(所有的?)?文字都?(删了|删掉|删除)[,，。\\s]*(只)?保留第一个(字|字符)",
            "(只)?保留第一个(字|字符)",
            "(只)?留下第一个(字|字符)"
        ]

        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        let match = instructionPatterns
            .compactMap { pattern -> NSTextCheckingResult? in
                guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
                return regex.firstMatch(in: text, range: fullRange)
            }
            .min { $0.range.location < $1.range.location }

        guard let match, match.range.location > 0 else {
            return nil
        }

        let earlierContent = nsText.substring(to: match.range.location)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "，,。.!！?？"))

        guard let firstCharacter = earlierContent.first else {
            return nil
        }

        return String(firstCharacter)
    }

    private func isSimpleEnoughForLocalPaste(_ text: String) -> Bool {
        guard !text.isEmpty else {
            return false
        }

        let lowercased = text.lowercased()
        let instructionKeywords = ["翻译", "translate", "总结", "summary", "列表", "list", "第一", "第二", "步骤"]
        if instructionKeywords.contains(where: { lowercased.contains($0) }) {
            return false
        }

        if containsHan(text) {
            if !hasSentenceEnding(text) && !isSimpleAcknowledgement(text) {
                return false
            }
            if text.count > 12 {
                return false
            }
        }

        let words = lowercased.split { $0 == " " || $0 == "\n" || $0 == "\t" }
        if words.count >= 3 && lowercased.range(of: "[a-z]", options: .regularExpression) != nil {
            return false
        }

        return text.count <= 12 || words.count <= 2
    }

    private func segmentSpokenChineseIfHelpful(_ text: String) -> String {
        guard shouldSegmentSpokenChinese(text) else {
            return text
        }

        var segmented = text
        let connectorPatterns = [
            "但是",
            "然后",
            "另外",
            "对了",
            "还有一个",
            "第二个",
            "第三个",
            "第四个",
            "第四的话",
            "第五个",
            "第五的话",
            "第六个",
            "第六的话"
        ]

        for connector in connectorPatterns {
            segmented = segmented.replacingOccurrences(
                of: #"(?<![。.!！?？])\#(connector)"#,
                with: #"。\#(connector)"#,
                options: .regularExpression
            )
        }

        segmented = segmented.replacingOccurrences(
            of: "呢。",
            with: "呢。"
        )
        return appendSentenceEndingIfNeeded(segmented)
    }

    private func shouldSegmentSpokenChinese(_ text: String) -> Bool {
        containsHan(text)
            && text.count >= 36
            && text.range(of: "[。.!！?？]", options: .regularExpression) == nil
            && text.range(
                of: "(但是|然后|另外|对了|还有一个|第二个|第三个|第四|第五|第六)",
                options: .regularExpression
            ) != nil
    }

    private func appendSentenceEndingIfNeeded(_ text: String) -> String {
        guard let scalar = text.unicodeScalars.last else {
            return text
        }
        if CharacterSet(charactersIn: "。.!！?？").contains(scalar) {
            return text
        }
        return text + "。"
    }

    private func containsHan(_ text: String) -> Bool {
        text.range(of: "\\p{Han}", options: .regularExpression) != nil
    }

    private func hasSentenceEnding(_ text: String) -> Bool {
        guard let scalar = text.unicodeScalars.last else { return false }
        return CharacterSet(charactersIn: "。.!！?？").contains(scalar)
    }

    private func isSimpleAcknowledgement(_ text: String) -> Bool {
        let normalized = text.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "。.!！?？，,～~"))
        )
        let acknowledgements: Set<String> = [
            "好",
            "好的",
            "可以",
            "行",
            "嗯",
            "嗯嗯",
            "谢谢",
            "收到",
            "没问题",
            "辛苦了"
        ]
        return acknowledgements.contains(normalized)
    }

    private func collapseWhitespace(in text: String) -> String {
        text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}

@MainActor
final class FastPathTextTransformProvider: TextTransformProvider {
    private let remoteProvider: TextTransformProvider
    private let cleaner: LocalTranscriptCleaner

    init(
        remoteProvider: TextTransformProvider,
        cleaner: LocalTranscriptCleaner = LocalTranscriptCleaner()
    ) {
        self.remoteProvider = remoteProvider
        self.cleaner = cleaner
    }

    func transform(input: VoiceSessionInput) async throws -> VoiceSessionResult {
        if let result = cleaner.fastResult(input: input) {
            return result
        }

        return try await remoteProvider.transform(input: cleaner.remoteInput(from: input))
    }
}
