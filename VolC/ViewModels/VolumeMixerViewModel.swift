import AppKit
import CoreAudio
import Foundation
import SwiftUI

@MainActor
final class VolumeMixerViewModel: ObservableObject {
    @Published private(set) var apps: [AppVolume] = []
    @Published var masterVolume: Double = 1
    @Published private(set) var launchAtLogin = false
    @Published private(set) var footerMessage = "Ready"
    @Published private(set) var isRefreshing = false

    private let audioService: CoreAudioHALService
    private let appleScriptBackend: AppleScriptVolumeBackend
    private let persistence: VolumePersistence
    private let launchService: LaunchAtLoginService
    private var pollingTimer: Timer?
    private var volumeApplyWorkItems: [AppVolume.ID: DispatchWorkItem] = [:]
    private var activeBundleIDs = Set<String>()

    init(
        audioService: CoreAudioHALService = CoreAudioHALService(),
        appleScriptBackend: AppleScriptVolumeBackend = AppleScriptVolumeBackend(),
        persistence: VolumePersistence = VolumePersistence(),
        launchService: LaunchAtLoginService = LaunchAtLoginService()
    ) {
        self.audioService = audioService
        self.appleScriptBackend = appleScriptBackend
        self.persistence = persistence
        self.launchService = launchService
        self.launchAtLogin = launchService.isEnabled
    }

    func start() {
        guard pollingTimer == nil else { return }
        refresh()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    func stop() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        cancelPendingVolumeApplies()
    }

    func refresh() {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let records = try audioService.activeOutputProcesses()
            let nextApps = buildAppVolumes(from: records)
            let nextBundleIDs = Set(nextApps.map(\.bundleID))
            let newlyDetectedApps = nextApps.filter { !activeBundleIDs.contains($0.bundleID) }

            apps = nextApps
            activeBundleIDs = nextBundleIDs
            restoreSavedVolumesIfNeeded(for: newlyDetectedApps)
            footerMessage = apps.isEmpty ? "No active output apps" : "Updated \(Date.now.formatted(date: .omitted, time: .shortened))"
        } catch {
            footerMessage = error.localizedDescription
        }

        do {
            masterVolume = try audioService.currentDefaultOutputVolume()
        } catch {
            if apps.isEmpty {
                footerMessage = error.localizedDescription
            }
        }
    }

    func volumeBinding(for appID: AppVolume.ID) -> Binding<Double> {
        Binding(
            get: { [weak self] in
                self?.apps.first(where: { $0.id == appID })?.volume ?? 1
            },
            set: { [weak self] value in
                self?.setVolume(for: appID, value: value)
            }
        )
    }

    func setVolume(for appID: AppVolume.ID, value: Double) {
        guard let index = apps.firstIndex(where: { $0.id == appID }) else { return }
        let clamped = min(max(value, 0), 1)
        apps[index].volume = clamped
        persistence.setVolume(clamped, for: apps[index].bundleID)

        apps[index].status = nil
        footerMessage = "\(apps[index].displayName) \(Int((clamped * 100).rounded()))%"
        scheduleVolumeApply(clamped, to: apps[index])
    }

    func setMasterVolume(_ value: Double) {
        let clamped = min(max(value, 0), 1)
        masterVolume = clamped

        do {
            try audioService.setDefaultOutputVolume(clamped)
            footerMessage = "Master \(Int((clamped * 100).rounded()))%"
        } catch {
            footerMessage = error.localizedDescription
        }
    }

    func resetAll() {
        persistence.reset()
        cancelPendingVolumeApplies()

        for index in apps.indices {
            apps[index].volume = 1
            let result = applyVolume(1, to: apps[index])
            apps[index].status = result.message
        }

        setMasterVolume(1)
        footerMessage = "Reset complete"
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try launchService.setEnabled(enabled)
            launchAtLogin = launchService.isEnabled
            footerMessage = launchAtLogin ? "Launch at login enabled" : "Launch at login disabled"
        } catch {
            launchAtLogin = launchService.isEnabled
            footerMessage = error.localizedDescription
        }
    }

    private func buildAppVolumes(from records: [AudioAppRecord]) -> [AppVolume] {
        var uniqueRecords: [String: AudioAppRecord] = [:]
        records.forEach { record in
            let canonicalBundleID = appleScriptBackend.controlBundleID(for: record.bundleID) ?? record.bundleID
            uniqueRecords[canonicalBundleID] = uniqueRecords[canonicalBundleID] ?? record
        }

        return uniqueRecords.map { canonicalBundleID, record in
            let runningApp = NSRunningApplication(processIdentifier: record.pid)
            let supportedApp = appleScriptBackend.supportedApp(for: canonicalBundleID)
            let displayName = supportedApp?.displayName ?? runningApp?.localizedName ?? appName(for: canonicalBundleID)
            let previousVolume = apps.first(where: { $0.bundleID == canonicalBundleID })?.volume
            let savedVolume = persistence.volume(for: canonicalBundleID)
            let isSupported = supportedApp != nil

            return AppVolume(
                id: canonicalBundleID,
                bundleID: canonicalBundleID,
                displayName: displayName,
                processID: record.pid,
                processObjectID: record.processObjectID,
                icon: icon(for: canonicalBundleID, runningApp: runningApp),
                controlKind: isSupported ? .appleScript : .unsupported,
                volume: previousVolume ?? savedVolume ?? 1,
                isActive: record.isRunningOutput,
                status: isSupported ? nil : "Read only"
            )
        }
        .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    private func restoreSavedVolumesIfNeeded(for appsToRestore: [AppVolume]) {
        for app in appsToRestore {
            guard app.supportsVolumeControl, let savedVolume = persistence.volume(for: app.bundleID) else { continue }
            let result = applyVolume(savedVolume, to: app)
            guard let index = apps.firstIndex(where: { $0.id == app.id }) else { continue }
            apps[index].status = result.message
        }
    }

    private func scheduleVolumeApply(_ volume: Double, to app: AppVolume) {
        guard app.supportsVolumeControl else { return }

        volumeApplyWorkItems[app.id]?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.applyScheduledVolume(volume, to: app)
            }
        }

        volumeApplyWorkItems[app.id] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: workItem)
    }

    private func applyScheduledVolume(_ volume: Double, to app: AppVolume) {
        volumeApplyWorkItems[app.id] = nil

        guard let index = apps.firstIndex(where: { $0.id == app.id }) else { return }
        guard abs(apps[index].volume - volume) < 0.001 else { return }

        let result = applyVolume(volume, to: apps[index])
        if let message = result.message {
            apps[index].status = message
            footerMessage = message
        } else {
            apps[index].status = nil
        }
    }

    private func cancelPendingVolumeApplies() {
        volumeApplyWorkItems.values.forEach { $0.cancel() }
        volumeApplyWorkItems.removeAll()
    }

    private func applyVolume(_ volume: Double, to app: AppVolume) -> VolumeApplyResult {
        if app.controlKind == .appleScript {
            return appleScriptBackend.setVolume(volume, bundleID: app.bundleID)
        }

        return audioService.setPerProcessGainIfPubliclyAvailable(volume, processObjectID: app.processObjectID)
    }

    private func appName(for bundleID: String) -> String {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return bundleID
        }

        return FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
    }

    private func icon(for bundleID: String, runningApp: NSRunningApplication?) -> NSImage? {
        if let icon = runningApp?.icon {
            return icon
        }

        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }

        return NSWorkspace.shared.icon(forFile: url.path)
    }
}
