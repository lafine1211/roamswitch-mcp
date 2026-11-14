// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.0.0 (build 216).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import Darwin

/// PHP binaries that Homebrew does not look after: MAMP, XAMPP, a tarball or source build (`/usr/local/bin/php`), a
/// version manager (phpbrew, asdf, phpenv, mise). Their versions are never in `brew list`, so the Homebrew scan did not
/// see them (the flaws CVE-2026-109618 and CVE-2026-109619, "PHP2Shell", were exploited from 2026-10-17 and are fixed in
/// 8.2.35, 8.3.36, 8.4.27 and 8.5.12).
///
/// Like `NodeRuntimeScan`, nothing here runs a binary found on disk. The version is read, in this order, from the
/// `php_version.h` beside the binary (`<prefix>/include/php/main/`), from the directory name (`.../php-8.4.24/bin/php`,
/// MAMP's `php8.4.24`), and last from the `X-Powered-By: PHP/8.4.24` string inside the binary.
///
/// A binary Homebrew owns (its path or its link target runs through `/Cellar/`) is left to the Homebrew scan, and one
/// MacPorts owns (`/opt/local`) is left alone. The data is the `php` rows of the Homebrew map.
/// Mirrors `roamswitch-core/src/php_runtime_scan.rs` on Linux (which also looks at XAMPP's `/opt/lampp`).
enum PhpRuntimeScan {

    /// One PHP binary and the release it is.
    struct Install: Equatable {
        let path: String
        let version: String
    }

    /// The largest binary the last-resort scan reads (a PHP binary is 10 to 60 MB).
    static let maxBinaryBytes: UInt64 = 300 * 1024 * 1024

    private static func isPlainVersion(_ s: Substring) -> Bool {
        let parts = s.split(separator: ".", omittingEmptySubsequences: false)
        return parts.count == 3 && parts.allSatisfy { !$0.isEmpty && $0.count <= 5 && $0.allSatisfy { $0.isASCII && $0.isNumber } }
    }

    // MARK: - Reading a version

    /// `PHP_VERSION "8.4.24"` of a `php_version.h`. A build with an extra version (`-dev`, `RC1`) is not judged.
    static func versionFromHeader(_ text: String) -> String? {
        var version: String?, extra: String?
        for line in text.split(whereSeparator: \.isNewline) {
            let words = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
            guard words.count >= 3, words[0] == "#define" else { continue }
            let value = words[2].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            switch words[1] {
            case "PHP_VERSION": version = value
            case "PHP_EXTRA_VERSION": extra = value
            default: break
            }
        }
        guard let version, (extra ?? "").isEmpty, isPlainVersion(Substring(version)) else { return nil }
        return version
    }

    /// A path component that names a release: `php-8.4.24`, `php8.4.24` (MAMP), `php-8.4.24-darwin-arm64`.
    static func versionFromPath(_ path: String) -> String? {
        for comp in path.split(separator: "/") {
            var rest = comp
            if rest.hasPrefix("php-") { rest = rest.dropFirst(4) } else if rest.hasPrefix("php") { rest = rest.dropFirst(3) } else { continue }
            guard let v = rest.split(separator: "-", omittingEmptySubsequences: false).first, isPlainVersion(v) else { continue }
            return String(v)
        }
        return nil
    }

    /// The version inside the binary: `X-Powered-By: PHP/8.4.24`, read in chunks. A plain release followed by the end of
    /// the string only.
    static func versionFromBinary(_ handle: FileHandle) -> String? {
        let key = Data("X-Powered-By: PHP/".utf8)
        let keep = 64
        var carry = Data()
        while true {
            guard let chunk = try? handle.read(upToCount: 1 << 20), !chunk.isEmpty else { return nil }
            var window = carry
            window.append(chunk)
            var from = window.startIndex
            while let r = window.range(of: key, in: from..<window.endIndex) {
                let tail = window[r.upperBound..<min(window.endIndex, r.upperBound + 32)]
                if let v = parseVersionTail(tail) { return v }
                from = r.upperBound
            }
            carry = Data(window.suffix(keep))
        }
    }

    /// `8.4.24\0...` or `8.4.24\r\n...` (the part after `X-Powered-By: PHP/`).
    private static func parseVersionTail(_ tail: Data) -> String? {
        guard let end = tail.firstIndex(where: { !($0 == UInt8(ascii: ".") || ($0 >= 0x30 && $0 <= 0x39)) }) else { return nil }
        let v = String(decoding: tail[tail.startIndex..<end], as: UTF8.self)
        guard isPlainVersion(Substring(v)) else { return nil }
        let stop = tail[end]
        return (stop == 0 || stop == UInt8(ascii: "\r") || stop == UInt8(ascii: "\n") || stop == UInt8(ascii: "\"")) ? v : nil
    }

    /// The release of the binary at `path` (inside `root`, which is empty on a real Mac), without running it.
    static func versionOf(root: String = "", path: String) -> String? {
        let prefix = ((path as NSString).deletingLastPathComponent as NSString).deletingLastPathComponent
        let header = root + prefix + "/include/php/main/php_version.h"
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

    /// The programs of a PHP prefix: the CLI, the FastCGI manager, the CGI.
    private static let programs = ["/bin/php", "/sbin/php-fpm", "/bin/php-cgi"]

    /// The PHP files at the places PHP usually lands, below `root`, as paths inside it. Only regular files (or links to one).
    static func candidates(root: String = "") -> [String] {
        var found: [String] = []
        func add(_ inside: String) {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: root + inside, isDirectory: &isDir), !isDir.boolValue { found.append(inside) }
        }
        for p in ["/usr/local/bin/php", "/usr/local/bin/php-cgi", "/usr/local/sbin/php-fpm",
                  "/Applications/XAMPP/xamppfiles/bin/php", "/Applications/XAMPP/xamppfiles/sbin/php-fpm"] { add(p) }
        // A prefix that holds a release: `/opt/php-8.4.24/bin/php`, `/usr/local/php5/bin/php`, and MAMP's
        // `/Applications/MAMP/bin/php/php8.4.24/bin/php`.
        for base in ["/opt", "/usr/local", "/Applications/MAMP/bin/php"] {
            for d in entries(root + base) where (d as NSString).lastPathComponent.hasPrefix("php") {
                for prog in programs { add(String(d.dropFirst(root.count)) + prog) }
            }
        }
        // Per-user version managers: phpbrew, asdf, phpenv, mise.
        var homes = entries(root + "/Users").map { String($0.dropFirst(root.count)) }
        if root.isEmpty { homes.append(NSHomeDirectory()) }
        for h in Set(homes) {
            for base in ["/.phpbrew/php", "/.asdf/installs/php", "/.phpenv/versions", "/.local/share/mise/installs/php"] {
                for d in entries(root + h + base) {
                    for prog in programs { add(String(d.dropFirst(root.count)) + prog) }
                }
            }
        }
        return found
    }

    /// Every PHP binary of this Mac, and the running ones, that Homebrew and MacPorts do not look after, with the release
    /// each is. A binary whose release cannot be read is left out.
    static func discover(root: String = "", running: [String]? = nil) -> [Install] {
        var seen = Set<String>()
        var out: [Install] = []
        let all = candidates(root: root) + (running ?? (root.isEmpty ? NodeRuntimeScan.runningPaths(named: ["php", "php-fpm", "php-cgi"]) : []))
        for p in all {
            let canon = URL(fileURLWithPath: root + p).resolvingSymlinksInPath().path
            if seen.contains(canon) || NodeRuntimeScan.ownedByAPackageManager(root + p) { continue }
            guard let v = versionOf(root: root, path: p) else { continue }
            seen.insert(canon)
            out.append(Install(path: p, version: v))
        }
        return out
    }
}
