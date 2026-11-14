// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.0.2 (build 218).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import Darwin

/// Node.js binaries that Homebrew does not look after: the official installer (`/usr/local/bin/node`), a version
/// manager (nvm, fnm, Volta, asdf, mise, n), a tarball in `/opt`, a binary an app ships. Their versions are never in
/// `brew list`, so the Homebrew scan did not see them (the Brotli flaw CVE-2026-111497, "Node2Shell", was in KEV on
/// 2026-10-27 and is fixed in 22.23.4, 24.22.1 and 26.12.1; a 22.23.3 installer build was not reported).
///
/// Nothing here runs a binary found on disk. The version is read, in this order, from the `node_version.h` beside the
/// binary (`<prefix>/include/node/`), from the directory name (`.../v22.23.3/bin/node`), and last from the build's
/// own source URL inside the binary (`https://nodejs.org/download/release/v22.23.3/node-v22.23.3.tar.gz`).
///
/// A binary Homebrew owns (its path or its link target runs through `/Cellar/`) is left to the Homebrew scan, and one
/// MacPorts owns (`/opt/local`) is left alone. The data is the `node` rows of the Homebrew map.
/// Mirrors `roamswitch-core/src/node_runtime_scan.rs` on Linux.
enum NodeRuntimeScan {

    /// One Node.js binary and the release it is.
    struct Install: Equatable {
        let path: String
        let version: String
    }

    /// The largest binary the last-resort scan reads (a Node.js binary is 100 to 130 MB).
    static let maxBinaryBytes: UInt64 = 600 * 1024 * 1024

    private static func isPlainVersion(_ s: Substring) -> Bool {
        let parts = s.split(separator: ".", omittingEmptySubsequences: false)
        return parts.count == 3 && parts.allSatisfy { !$0.isEmpty && $0.count <= 5 && $0.allSatisfy { $0.isASCII && $0.isNumber } }
    }

    // MARK: - Reading a version

    /// `NODE_MAJOR_VERSION` / `NODE_MINOR_VERSION` / `NODE_PATCH_VERSION` of a `node_version.h`. A pre-release build
    /// (`NODE_VERSION_IS_RELEASE 0`) is not judged.
    static func versionFromHeader(_ text: String) -> String? {
        var major: Int?, minor: Int?, patch: Int?, release: Int?
        for line in text.split(whereSeparator: \.isNewline) {
            let words = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
            guard words.count >= 3, words[0] == "#define", let n = Int(words[2]) else { continue }
            switch words[1] {
            case "NODE_MAJOR_VERSION": major = n
            case "NODE_MINOR_VERSION": minor = n
            case "NODE_PATCH_VERSION": patch = n
            case "NODE_VERSION_IS_RELEASE": release = n
            default: break
            }
        }
        guard release == 1, let major, let minor, let patch else { return nil }
        return "\(major).\(minor).\(patch)"
    }

    /// A path component that names a release: `v22.23.3`, `node-v22.23.3`, `node-v22.23.3-darwin-arm64`.
    static func versionFromPath(_ path: String) -> String? {
        for comp in path.split(separator: "/") {
            var rest = comp
            if rest.hasPrefix("node-") { rest = rest.dropFirst(5) }
            guard rest.hasPrefix("v") else { continue }
            rest = rest.dropFirst()
            guard let v = rest.split(separator: "-", omittingEmptySubsequences: false).first, isPlainVersion(v) else { continue }
            return String(v)
        }
        return nil
    }

    /// The version inside the binary: the source URL of the build, read in chunks. Both numbers must agree.
    static func versionFromBinary(_ handle: FileHandle) -> String? {
        let key = Data("download/release/v".utf8)
        let keep = 160
        var carry = Data()
        while true {
            guard let chunk = try? handle.read(upToCount: 1 << 20), !chunk.isEmpty else { return nil }
            var window = carry
            window.append(chunk)
            var from = window.startIndex
            while let r = window.range(of: key, in: from..<window.endIndex) {
                let tail = window[r.upperBound..<min(window.endIndex, r.upperBound + 64)]
                if let v = parseReleaseURLTail(tail) { return v }
                from = r.upperBound
            }
            carry = Data(window.suffix(keep))
        }
    }

    /// `22.23.3/node-v22.23.3.tar.gz...` (the part after `download/release/v`).
    private static func parseReleaseURLTail(_ tail: Data) -> String? {
        guard let end = tail.firstIndex(where: { !($0 == UInt8(ascii: ".") || ($0 >= 0x30 && $0 <= 0x39)) }) else { return nil }
        let v = String(decoding: tail[tail.startIndex..<end], as: UTF8.self)
        guard isPlainVersion(Substring(v)) else { return nil }
        let expect = Data("/node-v\(v).tar.gz".utf8)
        return tail[end...].starts(with: expect) ? v : nil
    }

    /// The release of the binary at `path` (inside `root`, which is empty on a real Mac), without running it.
    static func versionOf(root: String = "", path: String) -> String? {
        let prefix = ((path as NSString).deletingLastPathComponent as NSString).deletingLastPathComponent
        let header = root + prefix + "/include/node/node_version.h"
        if let data = FileManager.default.contents(atPath: header),
           let v = versionFromHeader(String(decoding: data, as: UTF8.self)) {
            return v
        }
        if let v = versionFromPath(path) { return v }
        let file = root + path
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: file),
              (attrs[.type] as? FileAttributeType) == .typeRegular,
              let size = attrs[.size] as? UInt64, size <= maxBinaryBytes,
              let h = FileHandle(forReadingAtPath: file) else { return nil }
        defer { try? h.close() }
        return versionFromBinary(h)
    }

    // MARK: - Finding the binaries

    private static func entries(_ dir: String) -> [String] {
        ((try? FileManager.default.contentsOfDirectory(atPath: dir)) ?? []).sorted().map { dir + "/" + $0 }
    }

    /// The `node` files at the places Node.js usually lands, below `root`, as paths inside it. Only regular files
    /// (or links to one).
    static func candidates(root: String = "") -> [String] {
        var found: [String] = []
        func add(_ inside: String) {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: root + inside, isDirectory: &isDir), !isDir.boolValue { found.append(inside) }
        }
        for p in ["/usr/local/bin/node", "/usr/local/bin/nodejs"] { add(p) }
        // A prefix that holds a release: `/opt/node-v22.23.3-darwin-arm64/bin/node`, `/usr/local/lib/nodejs/...`,
        // `/usr/local/n/versions/node/22.23.3/bin/node` (n).
        for base in ["/opt", "/usr/local/lib/nodejs", "/usr/local/n/versions/node"] {
            for d in entries(root + base) { add(String(d.dropFirst(root.count)) + "/bin/node") }
        }
        // Per-user version managers: nvm, fnm, Volta, asdf, mise.
        var homes = entries(root + "/Users").map { String($0.dropFirst(root.count)) }
        if root.isEmpty { homes.append(NSHomeDirectory()) }
        for h in Set(homes) {
            for (base, tail) in [
                ("/.nvm/versions/node", "/bin/node"),
                ("/.local/share/fnm/node-versions", "/installation/bin/node"),
                ("/Library/Application Support/fnm/node-versions", "/installation/bin/node"),
                ("/.volta/tools/image/node", "/bin/node"),
                ("/.asdf/installs/nodejs", "/bin/node"),
                ("/.local/share/mise/installs/node", "/bin/node"),
            ] {
                for d in entries(root + h + base) { add(String(d.dropFirst(root.count)) + tail) }
            }
        }
        return found
    }

    /// Whether Homebrew or MacPorts looks after this binary (checked on its real location too).
    static func ownedByAPackageManager(_ path: String) -> Bool {
        let resolved = (try? FileManager.default.destinationOfSymbolicLink(atPath: path))
            .map { $0.hasPrefix("/") ? $0 : ((path as NSString).deletingLastPathComponent as NSString).appendingPathComponent($0) }
            ?? path
        let real = URL(fileURLWithPath: resolved).resolvingSymlinksInPath().path
        for p in [path, resolved, real] {
            if p.contains("/Cellar/") || p.hasPrefix("/opt/homebrew/") || p.hasPrefix("/opt/local/") { return true }
        }
        return false
    }

    /// Paths of the running processes whose executable is named `node`.
    static func runningNodePaths() -> [String] { runningPaths(named: ["node"]) }

    /// Paths of the running processes whose executable has one of these file names (`PhpRuntimeScan` asks for `php`).
    static func runningPaths(named names: Set<String>) -> [String] {
        let bytes = proc_listallpids(nil, 0)
        guard bytes > 0 else { return [] }
        var pids = [pid_t](repeating: 0, count: Int(bytes) / MemoryLayout<pid_t>.size + 64)
        let got = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        guard got > 0 else { return [] }
        var out: [String] = []
        var buf = [CChar](repeating: 0, count: 4096)
        for pid in pids.prefix(Int(got)) where pid > 0 {
            let n = proc_pidpath(pid, &buf, UInt32(buf.count))
            guard n > 0 else { continue }
            let path = String(cString: buf)
            if names.contains((path as NSString).lastPathComponent) { out.append(path) }
        }
        return out
    }

    /// Every Node.js binary of this Mac, and the running ones, that Homebrew and MacPorts do not look after, with the
    /// release each is. A binary whose release cannot be read is left out.
    static func discover(root: String = "", running: [String]? = nil) -> [Install] {
        var seen = Set<String>()
        var out: [Install] = []
        let all = candidates(root: root) + (running ?? (root.isEmpty ? runningNodePaths() : []))
        for p in all {
            let canon = URL(fileURLWithPath: root + p).resolvingSymlinksInPath().path
            if seen.contains(canon) || ownedByAPackageManager(root + p) { continue }
            guard let v = versionOf(root: root, path: p) else { continue }
            seen.insert(canon)
            out.append(Install(path: p, version: v))
        }
        return out
    }
}
