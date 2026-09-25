import EngineC
import EngineSwift
import ObjCKit
import SwiftKit
import SwiftUI

@main
struct ReproApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    // One use of each framework type, so every module is imported and referenced.
    private let controller = SwiftKitPlaybackController()
    private let track = SwiftKitTrackModel(title: "Demo", durationSeconds: 3)
    private let state = SwiftKitPlaybackState.idle
    private let console = SwiftKitMixerConsole()
    private let mixer = OBJKAudioMixer(objkChannelCount: 2)
    private let mode = OBJKMixerMode.stereo
    private let engine = EngineSwiftMixHandler(trackCount: 4)
    private let raw: EngineCMixHandle = engine_c_make_mix(1)

    var body: some View {
        VStack {
            Text(controller.renderSwiftKitFrame(index: 0))
            Text("\(track.title) \(state.rawValue) \(mixer.objkChannelCount) \(mode.rawValue)")
            Text("\(engine.engineSwiftTempo) \(raw.engineCTrackCount)")
        }
    }
}
