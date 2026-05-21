import CoreAudio
import Foundation

final class CoreAudioHALService {
    enum CoreAudioHALServiceError: LocalizedError {
        case audioStatus(OSStatus, String)
        case propertyUnavailable(String)

        var errorDescription: String? {
            switch self {
            case .audioStatus(let status, let operation):
                return "\(operation) failed with OSStatus \(status)."
            case .propertyUnavailable(let property):
                return "\(property) is not available on the current audio device."
            }
        }
    }

    func activeOutputProcesses() throws -> [AudioAppRecord] {
        var address = propertyAddress(kAudioHardwarePropertyProcessObjectList)
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(systemObjectID, &address, 0, nil, &dataSize)
        guard status == noErr else {
            throw CoreAudioHALServiceError.audioStatus(status, "Reading CoreAudio process list size")
        }

        guard dataSize > 0 else { return [] }

        let count = Int(dataSize) / MemoryLayout<AudioObjectID>.stride
        var processObjects = [AudioObjectID](repeating: AudioObjectID(kAudioObjectUnknown), count: count)

        status = processObjects.withUnsafeMutableBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else { return noErr }
            return AudioObjectGetPropertyData(systemObjectID, &address, 0, nil, &dataSize, baseAddress)
        }
        guard status == noErr else {
            throw CoreAudioHALServiceError.audioStatus(status, "Reading CoreAudio process list")
        }

        let records = processObjects.compactMap { objectID -> AudioAppRecord? in
            guard objectID != AudioObjectID(kAudioObjectUnknown) else { return nil }
            guard (try? readUInt32(objectID, kAudioProcessPropertyIsRunningOutput)) == 1 else { return nil }
            guard let pid = try? readPID(objectID), pid > 0 else { return nil }
            guard let bundleID = try? readRetainedString(objectID, kAudioProcessPropertyBundleID), !bundleID.isEmpty else {
                return nil
            }

            return AudioAppRecord(
                processObjectID: objectID,
                pid: pid,
                bundleID: bundleID,
                isRunningOutput: true
            )
        }

        return records.sorted { $0.bundleID.localizedCaseInsensitiveCompare($1.bundleID) == .orderedAscending }
    }

    func currentDefaultOutputVolume() throws -> Double {
        let deviceID = try defaultOutputDeviceID()
        let elements = volumeElements(for: deviceID)
        guard !elements.isEmpty else {
            throw CoreAudioHALServiceError.propertyUnavailable("Default output volume")
        }

        let values = try elements.map { try readFloat32(deviceID, kAudioDevicePropertyVolumeScalar, scope: kAudioDevicePropertyScopeOutput, element: $0) }
        let average = values.reduce(Float32(0), +) / Float32(values.count)
        return Double(average)
    }

    func setDefaultOutputVolume(_ volume: Double) throws {
        let deviceID = try defaultOutputDeviceID()
        let writableElements = volumeElements(for: deviceID).filter {
            isSettable(deviceID, kAudioDevicePropertyVolumeScalar, scope: kAudioDevicePropertyScopeOutput, element: $0)
        }

        guard !writableElements.isEmpty else {
            throw CoreAudioHALServiceError.propertyUnavailable("Default output volume")
        }

        let value = Float32(min(max(volume, 0), 1))
        try writableElements.forEach {
            try setFloat32(deviceID, kAudioDevicePropertyVolumeScalar, value: value, scope: kAudioDevicePropertyScopeOutput, element: $0)
        }
    }

    func setPerProcessGainIfPubliclyAvailable(_ volume: Double, processObjectID: AudioObjectID) -> VolumeApplyResult {
        // Public HAL process objects expose identity and running-state properties, but no writable
        // process gain selector. Returning unsupported keeps the app honest and avoids private APIs.
        _ = (volume, processObjectID)
        return .unsupported("CoreAudio HAL can enumerate this app, but macOS does not expose public per-app gain control for it.")
    }

    private var systemObjectID: AudioObjectID {
        AudioObjectID(kAudioObjectSystemObject)
    }

    private func defaultOutputDeviceID() throws -> AudioObjectID {
        var address = propertyAddress(kAudioHardwarePropertyDefaultOutputDevice)
        var deviceID = AudioObjectID(kAudioObjectUnknown)
        var dataSize = UInt32(MemoryLayout<AudioObjectID>.stride)
        let status = AudioObjectGetPropertyData(systemObjectID, &address, 0, nil, &dataSize, &deviceID)
        guard status == noErr else {
            throw CoreAudioHALServiceError.audioStatus(status, "Reading default output device")
        }
        guard deviceID != AudioObjectID(kAudioObjectUnknown) else {
            throw CoreAudioHALServiceError.propertyUnavailable("Default output device")
        }
        return deviceID
    }

    private func volumeElements(for deviceID: AudioObjectID) -> [AudioObjectPropertyElement] {
        if hasProperty(
            deviceID,
            kAudioDevicePropertyVolumeScalar,
            scope: kAudioDevicePropertyScopeOutput,
            element: kAudioObjectPropertyElementMain
        ) {
            return [kAudioObjectPropertyElementMain]
        }

        return [AudioObjectPropertyElement(1), AudioObjectPropertyElement(2)].filter {
            hasProperty(deviceID, kAudioDevicePropertyVolumeScalar, scope: kAudioDevicePropertyScopeOutput, element: $0)
        }
    }

    private func hasProperty(
        _ objectID: AudioObjectID,
        _ selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
        element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain
    ) -> Bool {
        var address = propertyAddress(selector, scope: scope, element: element)
        return AudioObjectHasProperty(objectID, &address)
    }

    private func isSettable(
        _ objectID: AudioObjectID,
        _ selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
        element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain
    ) -> Bool {
        var address = propertyAddress(selector, scope: scope, element: element)
        var settable = DarwinBoolean(false)
        let status = AudioObjectIsPropertySettable(objectID, &address, &settable)
        return status == noErr && settable.boolValue
    }

    private func readUInt32(
        _ objectID: AudioObjectID,
        _ selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
        element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain
    ) throws -> UInt32 {
        var address = propertyAddress(selector, scope: scope, element: element)
        var value: UInt32 = 0
        var dataSize = UInt32(MemoryLayout<UInt32>.stride)
        let status = AudioObjectGetPropertyData(objectID, &address, 0, nil, &dataSize, &value)
        guard status == noErr else {
            throw CoreAudioHALServiceError.audioStatus(status, "Reading UInt32 CoreAudio property")
        }
        return value
    }

    private func readPID(_ objectID: AudioObjectID) throws -> pid_t {
        var address = propertyAddress(kAudioProcessPropertyPID)
        var value = pid_t(0)
        var dataSize = UInt32(MemoryLayout<pid_t>.stride)
        let status = AudioObjectGetPropertyData(objectID, &address, 0, nil, &dataSize, &value)
        guard status == noErr else {
            throw CoreAudioHALServiceError.audioStatus(status, "Reading process PID")
        }
        return value
    }

    private func readFloat32(
        _ objectID: AudioObjectID,
        _ selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope,
        element: AudioObjectPropertyElement
    ) throws -> Float32 {
        var address = propertyAddress(selector, scope: scope, element: element)
        var value = Float32(0)
        var dataSize = UInt32(MemoryLayout<Float32>.stride)
        let status = AudioObjectGetPropertyData(objectID, &address, 0, nil, &dataSize, &value)
        guard status == noErr else {
            throw CoreAudioHALServiceError.audioStatus(status, "Reading Float32 CoreAudio property")
        }
        return value
    }

    private func setFloat32(
        _ objectID: AudioObjectID,
        _ selector: AudioObjectPropertySelector,
        value: Float32,
        scope: AudioObjectPropertyScope,
        element: AudioObjectPropertyElement
    ) throws {
        var address = propertyAddress(selector, scope: scope, element: element)
        var mutableValue = value
        let dataSize = UInt32(MemoryLayout<Float32>.stride)
        let status = AudioObjectSetPropertyData(objectID, &address, 0, nil, dataSize, &mutableValue)
        guard status == noErr else {
            throw CoreAudioHALServiceError.audioStatus(status, "Setting Float32 CoreAudio property")
        }
    }

    private func readRetainedString(_ objectID: AudioObjectID, _ selector: AudioObjectPropertySelector) throws -> String? {
        var address = propertyAddress(selector)
        var value: Unmanaged<CFString>?
        var dataSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.stride)
        let status = AudioObjectGetPropertyData(objectID, &address, 0, nil, &dataSize, &value)
        guard status == noErr else {
            throw CoreAudioHALServiceError.audioStatus(status, "Reading CoreAudio string property")
        }

        return value?.takeRetainedValue() as String?
    }

    private func propertyAddress(
        _ selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
        element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain
    ) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: scope,
            mElement: element
        )
    }
}
