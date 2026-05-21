import AppKit
import CoreAudio

struct AudioAppRecord: Hashable, Identifiable {
    let processObjectID: AudioObjectID
    let pid: pid_t
    let bundleID: String
    let isRunningOutput: Bool

    var id: String { bundleID }
}

enum AppVolumeControlKind: String {
    case appleScript
    case unsupported
}

enum VolumeApplyResult: Equatable {
    case applied
    case unsupported(String)
    case failed(String)

    var message: String? {
        switch self {
        case .applied:
            return nil
        case .unsupported(let message), .failed(let message):
            return message
        }
    }
}

struct AppVolume: Identifiable, Equatable {
    let id: String
    let bundleID: String
    let displayName: String
    let processID: pid_t
    let processObjectID: AudioObjectID
    let icon: NSImage?
    let controlKind: AppVolumeControlKind
    var volume: Double
    var isActive: Bool
    var status: String?

    var supportsVolumeControl: Bool {
        controlKind != .unsupported
    }

    static func == (lhs: AppVolume, rhs: AppVolume) -> Bool {
        lhs.id == rhs.id &&
            lhs.bundleID == rhs.bundleID &&
            lhs.displayName == rhs.displayName &&
            lhs.processID == rhs.processID &&
            lhs.processObjectID == rhs.processObjectID &&
            lhs.controlKind == rhs.controlKind &&
            lhs.volume == rhs.volume &&
            lhs.isActive == rhs.isActive &&
            lhs.status == rhs.status
    }
}

