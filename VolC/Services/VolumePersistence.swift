import Foundation

final class VolumePersistence {
    private let defaults: UserDefaults
    private let perAppVolumesKey = "PerAppVolumes"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func volume(for bundleID: String) -> Double? {
        allVolumes()[bundleID]
    }

    func setVolume(_ volume: Double, for bundleID: String) {
        var volumes = allVolumes()
        volumes[bundleID] = min(max(volume, 0), 1)
        defaults.set(volumes, forKey: perAppVolumesKey)
    }

    func reset() {
        defaults.removeObject(forKey: perAppVolumesKey)
    }

    private func allVolumes() -> [String: Double] {
        defaults.dictionary(forKey: perAppVolumesKey) as? [String: Double] ?? [:]
    }
}

