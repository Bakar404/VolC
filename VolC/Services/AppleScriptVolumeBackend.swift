import Foundation

final class AppleScriptVolumeBackend {
    struct SupportedApp {
        let bundleID: String
        let displayName: String
        let limitation: String
    }

    private enum BrowserScriptKind {
        case chromium
        case safari
    }

    private let chromiumBrowserIDs: Set<String> = [
        "com.google.Chrome",
        "com.microsoft.edgemac",
        "com.brave.Browser",
        "com.vivaldi.Vivaldi",
        "com.operasoftware.Opera",
        "com.operasoftware.OperaGX"
    ]

    private let helperBundleMappings: [(prefix: String, controlBundleID: String)] = [
        ("com.google.chrome.helper", "com.google.Chrome"),
        ("com.microsoft.edgemac.helper", "com.microsoft.edgemac"),
        ("com.microsoft.edge.helper", "com.microsoft.edgemac"),
        ("com.brave.browser.helper", "com.brave.Browser"),
        ("com.vivaldi.vivaldi.helper", "com.vivaldi.Vivaldi"),
        ("com.operasoftware.opera.helper", "com.operasoftware.Opera"),
        ("com.operasoftware.operagx.helper", "com.operasoftware.OperaGX")
    ]

    let supportedApps: [String: SupportedApp] = [
        "com.spotify.client": SupportedApp(
            bundleID: "com.spotify.client",
            displayName: "Spotify",
            limitation: "Uses Spotify's AppleScript sound volume property."
        ),
        "com.apple.Music": SupportedApp(
            bundleID: "com.apple.Music",
            displayName: "Music",
            limitation: "Uses Music's AppleScript sound volume property."
        ),
        "com.google.Chrome": SupportedApp(
            bundleID: "com.google.Chrome",
            displayName: "Google Chrome",
            limitation: "Applies to reachable media elements in Chrome tabs; Chrome must allow JavaScript from Apple Events."
        ),
        "com.microsoft.edgemac": SupportedApp(
            bundleID: "com.microsoft.edgemac",
            displayName: "Microsoft Edge",
            limitation: "Applies to reachable media elements in Edge tabs; Edge must allow JavaScript from Apple Events."
        ),
        "com.brave.Browser": SupportedApp(
            bundleID: "com.brave.Browser",
            displayName: "Brave Browser",
            limitation: "Applies to reachable media elements in Brave tabs; Brave must allow JavaScript from Apple Events."
        ),
        "com.vivaldi.Vivaldi": SupportedApp(
            bundleID: "com.vivaldi.Vivaldi",
            displayName: "Vivaldi",
            limitation: "Applies to reachable media elements in Vivaldi tabs; Vivaldi must allow JavaScript from Apple Events."
        ),
        "com.operasoftware.Opera": SupportedApp(
            bundleID: "com.operasoftware.Opera",
            displayName: "Opera",
            limitation: "Applies to reachable media elements in Opera tabs; Opera must allow JavaScript from Apple Events."
        ),
        "com.operasoftware.OperaGX": SupportedApp(
            bundleID: "com.operasoftware.OperaGX",
            displayName: "Opera GX",
            limitation: "Applies to reachable media elements in Opera GX tabs; Opera GX must allow JavaScript from Apple Events."
        ),
        "com.apple.Safari": SupportedApp(
            bundleID: "com.apple.Safari",
            displayName: "Safari",
            limitation: "Applies to reachable media elements in Safari tabs; Safari must allow JavaScript from Apple Events."
        )
    ]

    func isSupported(bundleID: String) -> Bool {
        supportedApp(for: bundleID) != nil
    }

    func supportedApp(for bundleID: String) -> SupportedApp? {
        guard let controlBundleID = controlBundleID(for: bundleID) else { return nil }
        return supportedApps[controlBundleID]
    }

    func controlBundleID(for bundleID: String) -> String? {
        if supportedApps[bundleID] != nil {
            return bundleID
        }

        let normalizedBundleID = bundleID.lowercased()
        if let mapping = helperBundleMappings.first(where: { normalizedBundleID == $0.prefix || normalizedBundleID.hasPrefix($0.prefix + ".") }) {
            return mapping.controlBundleID
        }

        return nil
    }

    func setVolume(_ volume: Double, bundleID: String) -> VolumeApplyResult {
        guard let controlBundleID = controlBundleID(for: bundleID) else {
            return .unsupported("CoreAudio does not expose a public per-app gain setter for this app.")
        }

        let percent = Int((clamp(volume) * 100).rounded())
        let fraction = String(format: "%.3f", locale: Locale(identifier: "en_US_POSIX"), clamp(volume))

        switch controlBundleID {
        case "com.spotify.client":
            return run("""
            tell application id "com.spotify.client"
                if it is running then set sound volume to \(percent)
            end tell
            """)

        case "com.apple.Music":
            return run("""
            tell application id "com.apple.Music"
                if it is running then set sound volume to \(percent)
            end tell
            """)

        case "com.apple.Safari":
            return setBrowserVolume(
                fraction: fraction,
                bundleID: controlBundleID,
                displayName: "Safari",
                scriptKind: .safari
            )

        case let browserID where chromiumBrowserIDs.contains(browserID):
            return setBrowserVolume(
                fraction: fraction,
                bundleID: browserID,
                displayName: supportedApps[browserID]?.displayName ?? "Browser",
                scriptKind: .chromium
            )

        default:
            return .unsupported("CoreAudio does not expose a public per-app gain setter for this app.")
        }
    }

    private func setBrowserVolume(
        fraction: String,
        bundleID: String,
        displayName: String,
        scriptKind: BrowserScriptKind
    ) -> VolumeApplyResult {
        switch scriptKind {
        case .chromium:
            return run("""
            tell application id "\(bundleID)"
                if it is running and (count of windows) > 0 then
                    set volCJavaScript to "\(mediaJavaScript(fraction: fraction))"
                    set volCMediaCount to 0

                    repeat with browserWindow in windows
                        repeat with browserTab in tabs of browserWindow
                            try
                                tell browserTab to set tabMediaCount to execute javascript volCJavaScript
                                try
                                    set volCMediaCount to volCMediaCount + (tabMediaCount as integer)
                                end try
                            end try
                        end repeat
                    end repeat

                    if volCMediaCount is 0 then
                        error "No controllable \(displayName) media found. Enable JavaScript from Apple Events, then try a tab with video or audio."
                    end if
                else
                    error "\(displayName) is not running with an open window."
                end if
            end tell
            """, automationHint: "Enable \(displayName) > View > Developer > Allow JavaScript from Apple Events.")

        case .safari:
            return run("""
            tell application id "\(bundleID)"
                if it is running and (count of windows) > 0 then
                    set volCJavaScript to "\(mediaJavaScript(fraction: fraction))"
                    set volCMediaCount to 0

                    repeat with safariWindow in windows
                        repeat with safariTab in tabs of safariWindow
                            try
                                tell safariTab to set tabMediaCount to do JavaScript volCJavaScript
                                try
                                    set volCMediaCount to volCMediaCount + (tabMediaCount as integer)
                                end try
                            end try
                        end repeat
                    end repeat

                    if volCMediaCount is 0 then
                        error "No controllable Safari media found. Enable JavaScript from Apple Events, then try a tab with video or audio."
                    end if
                else
                    error "Safari is not running with an open window."
                end if
            end tell
            """, automationHint: "Enable Safari > Develop > Allow JavaScript from Apple Events.")
        }
    }

    private func mediaJavaScript(fraction: String) -> String {
        "(() => { const visit = root => { let count = 0; root.querySelectorAll('video,audio').forEach(el => { el.volume = \(fraction); el.muted = false; count += 1; }); root.querySelectorAll('*').forEach(el => { if (el.shadowRoot) { count += visit(el.shadowRoot); } }); return count; }; return visit(document); })();"
    }

    private func run(_ source: String, automationHint: String? = nil) -> VolumeApplyResult {
        guard let script = NSAppleScript(source: source) else {
            return .failed("Could not compile AppleScript.")
        }

        var errorInfo: NSDictionary?
        script.executeAndReturnError(&errorInfo)

        if let errorInfo {
            let message = errorInfo["NSAppleScriptErrorMessage"] as? String
            let number = errorInfo["NSAppleScriptErrorNumber"] as? NSNumber
            if number?.intValue == -1743, let automationHint {
                return .failed(automationHint)
            }

            let suffix = number.map { " (\($0))" } ?? ""
            return .failed((message ?? "AppleScript failed.") + suffix)
        }

        return .applied
    }

    private func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
