import Darwin
import Foundation

final class SingleInstanceGuard {
    private let fileManager: FileManager
    private let lockURL: URL
    private var lockFileDescriptor: CInt = -1

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        self.lockURL = baseURL
            .appendingPathComponent("VolC", isDirectory: true)
            .appendingPathComponent("VolC.lock")
    }

    deinit {
        guard lockFileDescriptor >= 0 else { return }
        flock(lockFileDescriptor, LOCK_UN)
        close(lockFileDescriptor)
    }

    func acquire() -> Bool {
        do {
            try fileManager.createDirectory(
                at: lockURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        } catch {
            NSLog("VolC could not create single-instance lock directory: \(error.localizedDescription)")
            return true
        }

        let descriptor = open(lockURL.path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard descriptor >= 0 else {
            NSLog("VolC could not open single-instance lock file.")
            return true
        }

        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            close(descriptor)
            return false
        }

        lockFileDescriptor = descriptor
        writeCurrentProcessID(to: descriptor)
        return true
    }

    private func writeCurrentProcessID(to descriptor: CInt) {
        let processID = "\(ProcessInfo.processInfo.processIdentifier)\n"
        guard let data = processID.data(using: .utf8) else { return }

        ftruncate(descriptor, 0)
        lseek(descriptor, 0, SEEK_SET)

        data.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            _ = write(descriptor, baseAddress, data.count)
        }
    }
}
