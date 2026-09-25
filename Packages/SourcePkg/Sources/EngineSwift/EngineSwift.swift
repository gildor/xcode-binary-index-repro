import EngineC

public final class EngineSwiftMixHandler {
    private var handle: EngineCMixHandle

    public init(trackCount: Int32) {
        handle = engine_c_make_mix(trackCount)
    }

    public func setEngineSwiftTempo(_ tempo: Double) {
        engine_c_set_tempo(&handle, tempo)
    }

    public var engineSwiftTempo: Double { handle.engineCTempo }

    // Exposes the C type on the public surface, like the Swift-over-C engine split.
    public var rawEngineCHandle: EngineCMixHandle { handle }
}
