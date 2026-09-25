import Foundation

public protocol SwiftKitRendering: AnyObject {
    func renderSwiftKitFrame(index: Int) -> String
}

public struct SwiftKitTrackModel: Hashable, Sendable {
    public let title: String
    public let durationSeconds: Double

    public init(title: String, durationSeconds: Double) {
        self.title = title
        self.durationSeconds = durationSeconds
    }
}

open class SwiftKitPlaybackController: SwiftKitRendering {
    public private(set) var tracks: [SwiftKitTrackModel] = []

    public init() {}

    open func enqueueSwiftKitTrack(_ track: SwiftKitTrackModel) {
        tracks.append(track)
    }

    public func renderSwiftKitFrame(index: Int) -> String {
        "frame \(index) of \(tracks.count) tracks"
    }
}

public enum SwiftKitPlaybackState: String, Sendable {
    case idle, playing, paused
}
