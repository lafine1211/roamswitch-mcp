// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.10.21 (build 139).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Symlink-safe directory walking and file reading for the folder scanners that
/// the MCP server (and the app UI) point at user-registered project folders
/// (`PackageCveScanLanguages`, `PackageCveScriptScan`, `TyposquatGuard`,
/// `SecretLeakScanning.auditDirectory`).
///
/// A project folder is attacker-influenced content (a cloned repo, an installed
/// dependency): a symlink inside it such as `node_modules/x -> ~/.ssh` or
/// `notes.txt -> /etc/passwd` must not make a scan read outside the folder the
/// user registered. `FileManager.enumerator`/`contentsOfDirectory` +
/// `resourceValues(.isDirectoryKey)` / `Data(contentsOf:)` all follow links, so
/// every scanner goes through this type instead:
///   * every entry is classified with `lstat`; a symlink is followed only when
///     its `realpath` is still inside the canonical scan root (pnpm-style
///     `node_modules` links stay working), otherwise it is skipped;
///   * only regular files and directories are returned (no FIFO/socket/device);
///   * traversal continues from the *resolved* path, so later components are
///     link-free and `O_NOFOLLOW` on the final component is sufficient;
///   * file reads use `O_NOFOLLOW | O_NONBLOCK`, re-check `S_ISREG` on the open
///     descriptor (`fstat`) and read at most a bounded number of bytes.
enum SafeScanFS {
    /// Default per-file read cap (source / manifest files).
    static let maxFileBytes = 2 * 1024 * 1024
    /// Cap for lockfiles, which can legitimately be far larger than source files.
    static let maxLockfileBytes = 32 * 1024 * 1024

    enum Kind { case directory, regularFile }

    struct Entry {
        /// Name as it appears in the parent directory (the link's own name for a followed link).
        let name: String
        /// Canonical path (symlink-free when the entry was a followed link).
        let path: String
        let kind: Kind
        /// `st_size` of the resolved item (0 for directories).
        let size: Int64
    }

    /// Fully resolved absolute path, or nil if relative/malformed/overlong/nonexistent.
    static func canonicalPath(_ path: String) -> String? {
        guard path.hasPrefix("/"), !path.contains("\0"), path.utf8.count < Int(PATH_MAX) else { return nil }
        var buffer = [CChar](repeating: 0, count: Int(PATH_MAX))
        guard realpath(path, &buffer) != nil else { return nil }
        return String(cString: buffer)
    }

    static func isWithin(_ path: String, root: String) -> Bool {
        if path == root { return true }
        return path.hasPrefix(root.hasSuffix("/") ? root : root + "/")
    }

    /// Classifies `path` without trusting links: nil unless it is a directory or
    /// regular file located inside `root` (canonical). A symlink is resolved and
    /// re-verified against `root`.
    static func classify(_ path: String, root: String) -> Entry? {
        var st = stat()
        guard lstat(path, &st) == 0 else { return nil }
        var resolved = path
        if (st.st_mode & mode_t(S_IFMT)) == mode_t(S_IFLNK) {
            guard let real = canonicalPath(path), isWithin(real, root: root),
                  lstat(real, &st) == 0 else { return nil }
            resolved = real
        }
        let name = (path as NSString).lastPathComponent
        switch st.st_mode & mode_t(S_IFMT) {
        case mode_t(S_IFDIR):
            return Entry(name: name, path: resolved, kind: .directory, size: 0)
        case mode_t(S_IFREG):
            return Entry(name: name, path: resolved, kind: .regularFile, size: Int64(st.st_size))
        default:
            return nil
        }
    }

    /// Safe children of `dir` (a canonical path): links leaving `root`, dangling
    /// links and special files are omitted. Sorted by name for stable output.
    static func children(ofDirectory dir: String, root: String) -> [Entry] {
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: dir) else { return [] }
        var out: [Entry] = []
        for name in names.sorted() {
            guard let entry = classify((dir as NSString).appendingPathComponent(name), root: root) else { continue }
            out.append(Entry(name: name, path: entry.path, kind: entry.kind, size: entry.size))
        }
        return out
    }

    /// Reads a regular file without following a final-component symlink, with a
    /// hard byte cap (nil when it is not a regular file or exceeds `maxBytes`).
    static func readRegularFile(atPath path: String, maxBytes: Int = maxFileBytes) -> Data? {
        let fd = open(path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
        guard fd >= 0 else { return nil }
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: false)
        defer { try? handle.close() }
        var st = stat()
        guard fstat(fd, &st) == 0, (st.st_mode & mode_t(S_IFMT)) == mode_t(S_IFREG),
              st.st_size <= off_t(maxBytes) else { return nil }
        // Bounded read: a file that grows after the fstat still cannot inflate memory.
        let data = (try? handle.read(upToCount: maxBytes + 1)) ?? Data()
        return data.count <= maxBytes ? data : nil
    }

    /// `classify` + `readRegularFile`: the file must lie inside `root` (after
    /// link resolution) and be a regular file. Returns the resolved path too.
    static func readFile(_ path: String, root: String, maxBytes: Int = maxFileBytes) -> (path: String, data: Data)? {
        guard let entry = classify(path, root: root), entry.kind == .regularFile,
              let data = readRegularFile(atPath: entry.path, maxBytes: maxBytes) else { return nil }
        return (entry.path, data)
    }
}
