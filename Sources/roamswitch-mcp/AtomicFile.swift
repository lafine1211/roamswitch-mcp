// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.36 (build 215).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import Darwin

/// The one way a state file is replaced (the Mac counterpart of the Linux edition's `write_private_atomic`).
///
/// `Data.write(to:options: .atomic)` already wrote a temporary file and renamed it, so a reader never saw half a file.
/// What it did not do: refuse a symbolic link at the destination (it replaced the link with a file, or for the
/// temporary name followed a link someone planted), keep the mode the file had (the new file got the default mode, so a
/// 0600 file was world-readable until the caller's `chmod` ran), flush the bytes before the rename (a power cut could
/// leave an empty file under the real name), and flush the directory after it (the rename itself could be lost).
///
/// Here:
/// 1. The destination is checked with `lstat`: a symbolic link or anything that is not a regular file is refused.
/// 2. The bytes go to a new file next to it, opened `O_CREAT | O_EXCL | O_NOFOLLOW` with a random name, so an existing
///    file or link of that name is never written through.
/// 3. The mode is `mode` when given, else the mode the destination had, else `newFileMode`. As root the owner and
///    group of the destination are kept too. Both are set on the open descriptor before the rename, so the file never
///    appears under its name with a wider mode.
/// 4. `fsync` on the file, `rename` onto the name, `fsync` on the directory.
/// Any failure removes the temporary file and leaves the destination as it was.
///
/// A damaged file is still the caller's to keep aside (`StoredRecordFile.loadForUpdate` / `mayReplace`): this replaces
/// whatever is there.
public enum AtomicFile {
    public enum WriteError: Error, Equatable, CustomStringConvertible {
        /// The destination is a symbolic link.
        case destinationIsSymlink(String)
        /// The destination exists and is not a regular file (a directory, a device, a socket).
        case destinationNotRegular(String)
        /// A system call failed: which step, and errno.
        case failed(step: String, errno: Int32)

        public var description: String {
            switch self {
            case .destinationIsSymlink(let p): return "\(p) is a symbolic link; not writing through it"
            case .destinationNotRegular(let p): return "\(p) is not a regular file"
            case .failed(let step, let e): return "\(step) failed: \(String(cString: strerror(e)))"
            }
        }
    }

    /// The mode a file that did not exist gets when the caller names none (what `.atomic` gave under the usual umask).
    public static let defaultNewFileMode: mode_t = 0o644

    /// Test hook: called after the temporary file is fully written and flushed, before the rename. Throwing here is a
    /// failure in the middle of a write.
    static var beforeRenameHook: ((String) throws -> Void)?

    public static func write(_ data: Data, to url: URL, mode: mode_t? = nil, newFileMode: mode_t = defaultNewFileMode) throws {
        try write(data, toPath: url.path, mode: mode, newFileMode: newFileMode)
    }

    public static func write(_ string: String, to url: URL, mode: mode_t? = nil, newFileMode: mode_t = defaultNewFileMode) throws {
        try write(Data(string.utf8), toPath: url.path, mode: mode, newFileMode: newFileMode)
    }

    public static func write(_ string: String, toPath path: String, mode: mode_t? = nil, newFileMode: mode_t = defaultNewFileMode) throws {
        try write(Data(string.utf8), toPath: path, mode: mode, newFileMode: newFileMode)
    }

    public static func write(_ data: Data, toPath path: String, mode: mode_t? = nil, newFileMode: mode_t = defaultNewFileMode) throws {
        var st = stat()
        var existing: stat?
        if lstat(path, &st) == 0 {
            if (st.st_mode & S_IFMT) == S_IFLNK { throw WriteError.destinationIsSymlink(path) }
            guard (st.st_mode & S_IFMT) == S_IFREG else { throw WriteError.destinationNotRegular(path) }
            existing = st
        } else if errno != ENOENT {
            throw WriteError.failed(step: "lstat", errno: errno)
        }
        let finalMode = mode ?? existing.map { $0.st_mode & 0o7777 } ?? newFileMode

        let dir = (path as NSString).deletingLastPathComponent.isEmpty ? "." : (path as NSString).deletingLastPathComponent
        let base = (path as NSString).lastPathComponent
        let tmp = dir + "/." + base + ".tmp-" + String(getpid()) + "-" + String(UInt32.random(in: .min ... .max), radix: 16)
        let fd = open(tmp, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard fd >= 0 else { throw WriteError.failed(step: "open", errno: errno) }
        var closed = false
        func fail(_ step: String, _ e: Int32) -> WriteError {
            if !closed { close(fd); closed = true }
            unlink(tmp)
            return .failed(step: step, errno: e)
        }
        let written = data.withUnsafeBytes { raw -> Int32 in
            guard let base = raw.baseAddress else { return 0 }
            var offset = 0
            while offset < raw.count {
                let n = Darwin.write(fd, base.advanced(by: offset), raw.count - offset)
                if n < 0 {
                    if errno == EINTR { continue }
                    return errno
                }
                if n == 0 { return EIO }
                offset += n
            }
            return 0
        }
        if written != 0 { throw fail("write", written) }
        if geteuid() == 0, let existing, fchown(fd, existing.st_uid, existing.st_gid) != 0 { throw fail("fchown", errno) }
        if fchmod(fd, finalMode) != 0 { throw fail("fchmod", errno) }
        if fsync(fd) != 0 { throw fail("fsync", errno) }
        if let hook = beforeRenameHook {
            do { try hook(tmp) } catch { throw fail("hook", EIO) }
        }
        close(fd); closed = true
        guard rename(tmp, path) == 0 else {
            let e = errno
            unlink(tmp)
            throw WriteError.failed(step: "rename", errno: e)
        }
        // The rename is in the directory: flush it too. A directory that cannot be opened is not a failed write (the
        // file is in place); it only loses the guarantee across a power cut.
        let dfd = open(dir, O_RDONLY | O_DIRECTORY | O_CLOEXEC)
        if dfd >= 0 {
            _ = fsync(dfd)
            close(dfd)
        }
    }

    /// Runs `body` while holding an exclusive `flock` on `<path>.lock` (0600, created when missing), for a
    /// read-modify-write of `path` that another process does too (the app and the MCP server on the incident timeline,
    /// the app and the watchdog on the watchdog state). The lock is advisory and only between our own processes. When
    /// the lock file cannot be opened `body` still runs, unlocked: losing one record to a race is better than losing
    /// it to a failed lock.
    @discardableResult
    public static func withLock<T>(_ path: String, _ body: () throws -> T) rethrows -> T {
        let lockPath = path + ".lock"
        let fd = open(lockPath, O_RDWR | O_CREAT | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard fd >= 0 else { return try body() }
        defer { close(fd) }
        while flock(fd, LOCK_EX) != 0 {
            if errno != EINTR { return try body() }
        }
        defer { flock(fd, LOCK_UN) }
        return try body()
    }
}
