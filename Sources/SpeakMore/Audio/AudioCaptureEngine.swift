@preconcurrency import AVFoundation
import Foundation

protocol AudioCapturing: AnyObject {
    func start(onBuffer: @escaping (AVAudioPCMBuffer) -> Void) throws
    func stop()
}

protocol AudioEngineCore: AnyObject {
    var inputNode: AudioInputNodeCore { get }
    func prepare()
    func start() throws
    func stop()
}

protocol AudioInputNodeCore: AnyObject {
    func outputFormat(forBus bus: AVAudioNodeBus) -> AVAudioFormat
    func installTap(
        onBus bus: AVAudioNodeBus,
        bufferSize: AVAudioFrameCount,
        format: AVAudioFormat,
        block tapBlock: @escaping AVAudioNodeTapBlock
    )
    func removeTap(onBus bus: AVAudioNodeBus)
}

final class AudioCaptureEngine: AudioCapturing {
    private let engineCore: AudioEngineCore
    private let audioQualityMonitor: AudioQualityMonitoring?
    private var onBuffer: ((AVAudioPCMBuffer) -> Void)?

    init(
        engineCore: AudioEngineCore = SystemAudioEngineCore(),
        audioQualityMonitor: AudioQualityMonitoring? = nil
    ) {
        self.engineCore = engineCore
        self.audioQualityMonitor = audioQualityMonitor
    }

    func start(onBuffer: @escaping (AVAudioPCMBuffer) -> Void) throws {
        stop()

        self.onBuffer = onBuffer
        let inputNode = engineCore.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { [audioQualityMonitor] buffer, _ in
            audioQualityMonitor?.process(buffer: buffer)
            onBuffer(buffer)
        }
        engineCore.prepare()
        try engineCore.start()
    }

    func stop() {
        engineCore.inputNode.removeTap(onBus: 0)
        engineCore.stop()
        onBuffer = nil
    }
}

private final class SystemAudioEngineCore: AudioEngineCore {
    private let engine = AVAudioEngine()
    private lazy var inputNodeCore = SystemAudioInputNodeCore(node: engine.inputNode)

    var inputNode: AudioInputNodeCore {
        inputNodeCore
    }

    func prepare() {
        engine.prepare()
    }

    func start() throws {
        try engine.start()
    }

    func stop() {
        engine.stop()
    }
}

private final class SystemAudioInputNodeCore: AudioInputNodeCore {
    private let node: AVAudioInputNode

    init(node: AVAudioInputNode) {
        self.node = node
    }

    func outputFormat(forBus bus: AVAudioNodeBus) -> AVAudioFormat {
        node.outputFormat(forBus: bus)
    }

    func installTap(
        onBus bus: AVAudioNodeBus,
        bufferSize: AVAudioFrameCount,
        format: AVAudioFormat,
        block tapBlock: @escaping AVAudioNodeTapBlock
    ) {
        node.installTap(onBus: bus, bufferSize: bufferSize, format: format, block: tapBlock)
    }

    func removeTap(onBus bus: AVAudioNodeBus) {
        node.removeTap(onBus: bus)
    }
}
