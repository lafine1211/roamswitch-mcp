// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.15 (build 194).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import Darwin

/// What the PHP check (and the session-folder part of the web scan) needs to know about the PHP installs of
/// this Mac: where the interpreters are, which ini files belong to which install, what the ini files say
/// (last assignment wins), whether Apache loads PHP as a module, and which folders hold PHP session files.
///
/// Everything here reads files. PHP is asked for its version only (`runVersion`), never to run a script.
/// All functions are pure over a `PhpFS`, so tests build a fake Mac in a temp folder.

// MARK: - File access

/// A view of the disk. Every path the logic sees is a "virtual" absolute path; `root` is put in front of it
/// when the disk is touched (empty on a real Mac, a temp folder in tests).
struct PhpFS {
    var root = ""

    func real(_ path: String) -> String { root + path }

    func read(_ path: String, maxBytes: Int = 1_048_576) -> String? {
        guard let h = FileHandle(forReadingAtPath: real(path)) else { return nil }
        defer { try? h.close() }
        guard let data = try? h.read(upToCount: maxBytes) else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    func isDirectory(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: real(path), isDirectory: &isDir) && isDir.boolValue
    }

    func isFile(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: real(path), isDirectory: &isDir) && !isDir.boolValue
    }

    func isExecutableFile(_ path: String) -> Bool {
        isFile(path) && FileManager.default.isExecutableFile(atPath: real(path))
    }

    /// Entry names of a folder, sorted; empty when it cannot be listed.
    func list(_ dir: String) -> [String] {
        ((try? FileManager.default.contentsOfDirectory(atPath: real(dir))) ?? []).sorted()
    }

    /// `*` and `?` inside a path component (fnmatch). Returns existing virtual paths, sorted.
    func glob(_ pattern: String) -> [String] {
        let comps = pattern.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
        var current = [""]
        for comp in comps {
            var next: [String] = []
            for base in current {
                if comp.contains("*") || comp.contains("?") {
                    for name in list(base.isEmpty ? "/" : base) where fnmatch(comp, name, 0) == 0 {
                        next.append(base + "/" + name)
                    }
                } else {
                    let p = base + "/" + comp
                    if FileManager.default.fileExists(atPath: real(p)) { next.append(p) }
                }
            }
            current = next
            if current.isEmpty { return [] }
        }
        return current.sorted()
    }

    /// The path with symlinks resolved, without the `root` (used to tell two names of one file apart).
    func resolved(_ path: String) -> String {
        let r = URL(fileURLWithPath: real(path)).resolvingSymlinksInPath().path
        return root.isEmpty ? r : (r.hasPrefix(root) ? String(r.dropFirst(root.count)) : r)
    }
}

// MARK: - Values

enum PhpSeverity: Int, Comparable {
    case info = 0, medium, high, critical
    static func < (a: PhpSeverity, b: PhpSeverity) -> Bool { a.rawValue < b.rawValue }
    var label: String {
        switch self {
        case .info: return "info"
        case .medium: return "medium"
        case .high: return "high"
        case .critical: return "critical"
        }
    }
}

struct PhpInterpreter: Equatable {
    enum Kind: String { case cli, fpm, frankenphp }
    let kind: Kind
    let path: String
    var version: String?

    /// `8.3` for `8.3.12`.
    var branch: String? { PhpEnvironment.branch(ofVersion: version) }
}

/// The ini files that belong to one install (one Homebrew version folder, one MAMP PHP, one Herd PHP).
struct PhpIniSet: Equatable {
    var label: String
    /// `8.3`, when the folder name says it.
    var branch: String?
    var phpIni: String?
    var confD: [String]
    var poolFiles: [String]

    /// In the order PHP reads them: php.ini, then conf.d alphabetically.
    var iniFiles: [String] { (phpIni.map { [$0] } ?? []) + confD }
}

// MARK: - Environment

enum PhpEnvironment {
    // MARK: Version

    /// php.net releases of 2026-10-21; judges this advisory only (CVE-2026-109618, CVE-2026-109619).
    /// Branch -> first patch level that has the fix.
    static let fixedPatch: [String: Int] = ["8.2": 35, "8.3": 36, "8.4": 27, "8.5": 12]

    /// First line of `php -v` (`PHP 8.3.12 (cli) ...`) or `frankenphp version`
    /// (`FrankenPHP v1.5.0 PHP 8.4.5 Caddy ...`). nil when no `x.y.z` is found.
    static func parseVersion(_ output: String, kind: PhpInterpreter.Kind = .cli) -> String? {
        let line = output.split(separator: "\n", omittingEmptySubsequences: true).first.map(String.init) ?? ""
        func first(_ pattern: String) -> String? {
            guard let re = try? NSRegularExpression(pattern: pattern),
                  let m = re.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                  let r = Range(m.numberOfRanges > 1 ? m.range(at: 1) : m.range, in: line) else { return nil }
            return String(line[r])
        }
        if let v = first(#"PHP (\d+\.\d+\.\d+)"#) { return v }
        // FrankenPHP prints its own version first, so a bare number would be the wrong one.
        return kind == .frankenphp ? nil : first(#"\d+\.\d+\.\d+"#)
    }

    static func parts(ofVersion version: String?) -> (major: Int, minor: Int, patch: Int)? {
        guard let version else { return nil }
        let p = version.split(separator: ".").map { Int($0) }
        guard p.count >= 3, let a = p[0], let b = p[1], let c = p[2] else { return nil }
        return (a, b, c)
    }

    static func branch(ofVersion version: String?) -> String? {
        parts(ofVersion: version).map { "\($0.major).\($0.minor)" }
    }

    enum VersionVerdict: Equatable {
        case unpatched(fixed: String)
        case noUpstreamFix
        case patched
        case unknown
    }

    static func verdict(forVersion version: String?) -> VersionVerdict {
        guard let v = parts(ofVersion: version) else { return .unknown }
        if v.major < 8 || (v.major == 8 && v.minor < 2) { return .noUpstreamFix }
        guard let fixed = fixedPatch["\(v.major).\(v.minor)"] else { return .unknown }
        return v.patch >= fixed ? .patched : .unpatched(fixed: "\(v.major).\(v.minor).\(fixed)")
    }

    /// Asks the binary for its version (never runs a script). 5 second limit. nil when it cannot be started.
    static func runVersion(_ interpreter: PhpInterpreter) -> String? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: interpreter.path)
        // -n: no php.ini and so no extension loading; the version does not depend on them.
        p.arguments = interpreter.kind == .frankenphp ? ["version"] : ["-n", "-v"]
        p.environment = ["PATH": "/usr/bin:/bin:/usr/sbin:/sbin", "HOME": NSHomeDirectory()]
        let out = Pipe()
        p.standardOutput = out
        p.standardError = FileHandle.nullDevice
        p.standardInput = FileHandle.nullDevice
        let done = DispatchSemaphore(value: 0)
        p.terminationHandler = { _ in done.signal() }
        do { try p.run() } catch { return nil }
        if done.wait(timeout: .now() + 5) == .timedOut {
            p.terminate()
            return nil
        }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        return parseVersion(String(decoding: data, as: UTF8.self), kind: interpreter.kind)
    }

    // MARK: Interpreters

    /// `php`, `php-fpm` and `frankenphp` of Homebrew, MAMP, Herd and PATH, one entry per real file. Versions are not read.
    static func interpreters(fs: PhpFS, home: String, pathEnv: String) -> [PhpInterpreter] {
        var dirs: [(dir: String, herd: Bool)] = []
        for prefix in ["/opt/homebrew", "/usr/local"] {
            dirs.append(("\(prefix)/bin", false))
            dirs.append(("\(prefix)/sbin", false))
            for d in fs.glob("\(prefix)/opt/php@*/bin") + fs.glob("\(prefix)/opt/php@*/sbin") { dirs.append((d, false)) }
        }
        dirs.append(("\(home)/Library/Application Support/Herd/bin", true))
        for d in pathEnv.split(separator: ":").map(String.init) where d.hasPrefix("/") { dirs.append((d, false)) }

        var found: [PhpInterpreter] = []
        var seen = Set<String>()
        func add(_ path: String, _ kind: PhpInterpreter.Kind) {
            guard fs.isExecutableFile(path) else { return }
            guard seen.insert(fs.resolved(path)).inserted else { return }
            found.append(PhpInterpreter(kind: kind, path: path, version: nil))
        }
        for (dir, herd) in dirs {
            for name in fs.list(dir) {
                let kind: PhpInterpreter.Kind?
                switch name {
                case "php": kind = .cli
                case "php-fpm": kind = .fpm
                case "frankenphp": kind = .frankenphp
                default: kind = (herd && name.hasPrefix("php") && name.dropFirst(3).allSatisfy(\.isNumber) && name.count > 3) ? .cli : nil
                }
                if let kind { add(dir + "/" + name, kind) }
            }
        }
        for p in fs.glob("/Applications/MAMP/bin/php/php*/bin/php") { add(p, .cli) }
        return found
    }

    // MARK: ini

    /// `key = value` lines in order. `;` starts a comment (a whole line, or after the value); quotes around a value
    /// are removed; `[section]` lines are skipped.
    static func parseIni(_ text: String) -> [(key: String, value: String)] {
        var out: [(String, String)] = []
        for raw in text.split(whereSeparator: \.isNewline) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix(";") || line.hasPrefix("[") { continue }
            guard let eq = line.firstIndex(of: "=") else { continue }
            let key = line[..<eq].trimmingCharacters(in: .whitespaces)
            if key.isEmpty { continue }
            out.append((key, unquote(String(line[line.index(after: eq)...]))))
        }
        return out
    }

    /// The value of an ini assignment without its comment and quotes.
    static func unquote(_ raw: String) -> String {
        let v = raw.trimmingCharacters(in: .whitespaces)
        if let q = v.first, q == "\"" || q == "'" {
            let rest = v.dropFirst()
            if let end = rest.firstIndex(of: q) { return String(rest[..<end]) }
            return String(rest)
        }
        let cut = v.firstIndex(of: ";").map { String(v[..<$0]) } ?? v
        return cut.trimmingCharacters(in: .whitespaces)
    }

    /// PHP's reading of an ini boolean: on / true / yes are true, off / false / no / none / empty are false,
    /// a number is true when it is not zero, anything else is false.
    static func iniBool(_ value: String) -> Bool {
        let v = value.trimmingCharacters(in: .whitespaces).lowercased()
        if ["on", "true", "yes"].contains(v) { return true }
        if let n = Int(v) { return n != 0 }
        return false
    }

    /// The last assignment of each wanted key over the files, in order.
    static func iniValues(fs: PhpFS, files: [String], keys: Set<String>) -> [String: (value: String, file: String)] {
        var out: [String: (String, String)] = [:]
        for f in files {
            guard let text = fs.read(f) else { continue }
            for (k, v) in parseIni(text) where keys.contains(k) { out[k] = (v, f) }
        }
        return out
    }

    struct PoolSection: Equatable {
        let name: String
        let file: String
        /// Value set by `php_admin_value[...]`/`php_value[...]` (flags too); the admin form wins.
        var values: [String: String]
    }

    /// The pools of a PHP-FPM config file. `[global]` is not a pool.
    static func parsePools(_ text: String, file: String, keys: Set<String>) -> [PoolSection] {
        var pools: [PoolSection] = []
        var admin: [String: String] = [:]
        var plain: [String: String] = [:]
        var name: String?
        func close() {
            if let n = name { pools.append(PoolSection(name: n, file: file, values: plain.merging(admin) { _, a in a })) }
            admin = [:]; plain = [:]
        }
        for raw in text.split(whereSeparator: \.isNewline) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix(";") { continue }
            if line.hasPrefix("["), let end = line.firstIndex(of: "]") {
                close()
                let n = String(line[line.index(after: line.startIndex)..<end])
                name = n.lowercased() == "global" ? nil : n
                continue
            }
            guard name != nil, let eq = line.firstIndex(of: "=") else { continue }
            let lhs = line[..<eq].trimmingCharacters(in: .whitespaces)
            guard let open = lhs.firstIndex(of: "["), lhs.hasSuffix("]") else { continue }
            let directive = lhs[..<open].lowercased()
            let key = String(lhs[lhs.index(after: open)..<lhs.index(before: lhs.endIndex)])
            guard keys.contains(key) else { continue }
            let value = unquote(String(line[line.index(after: eq)...]))
            switch directive {
            case "php_admin_value", "php_admin_flag": admin[key] = value
            case "php_value", "php_flag": plain[key] = value
            default: break
            }
        }
        close()
        return pools
    }

    // MARK: ini sets

    /// `8.3` from a folder name: `8.3` (Homebrew), `php8.3.1` (MAMP), `83` (Herd).
    static func branch(fromFolderName name: String) -> String? {
        func match(_ pattern: String) -> String? {
            guard let re = try? NSRegularExpression(pattern: pattern),
                  let m = re.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)),
                  let a = Range(m.range(at: 1), in: name), let b = Range(m.range(at: 2), in: name) else { return nil }
            return "\(name[a]).\(name[b])"
        }
        return match(#"^(\d)\.(\d+)"#) ?? match(#"^php(\d)\.(\d+)"#) ?? match(#"^(\d)(\d{1,2})$"#)
    }

    static func iniSets(fs: PhpFS, home: String) -> [PhpIniSet] {
        var sets: [PhpIniSet] = []
        func add(label: String, name: String, dir: String, hasConfD: Bool = true, pools: Bool = false) {
            let ini = fs.isFile(dir + "/php.ini") ? dir + "/php.ini" : nil
            let confD = hasConfD ? fs.glob(dir + "/conf.d/*.ini") : []
            var poolFiles: [String] = []
            if pools {
                poolFiles = fs.glob(dir + "/php-fpm.d/*.conf")
                if fs.isFile(dir + "/php-fpm.conf") { poolFiles.insert(dir + "/php-fpm.conf", at: 0) }
            }
            guard ini != nil || !confD.isEmpty || !poolFiles.isEmpty else { return }
            sets.append(PhpIniSet(label: label, branch: branch(fromFolderName: name), phpIni: ini, confD: confD, poolFiles: poolFiles))
        }
        for prefix in ["/opt/homebrew", "/usr/local"] {
            for dir in fs.glob("\(prefix)/etc/php/*") where fs.isDirectory(dir) {
                let name = String(dir.split(separator: "/").last ?? "")
                add(label: "Homebrew \(name)", name: name, dir: dir, pools: true)
            }
        }
        for dir in fs.glob("/Applications/MAMP/bin/php/php*/conf") {
            let name = String(dir.split(separator: "/").dropLast().last ?? "")
            add(label: "MAMP \(name)", name: name, dir: dir)
        }
        for dir in fs.glob("\(home)/Library/Application Support/Herd/config/php/*") where fs.isDirectory(dir) {
            let name = String(dir.split(separator: "/").last ?? "")
            add(label: "Herd \(name)", name: name, dir: dir)
        }
        if fs.isFile("/etc/php.ini") {
            sets.append(PhpIniSet(label: "/etc/php.ini", branch: nil, phpIni: "/etc/php.ini", confD: [], poolFiles: []))
        }
        return sets
    }

    // MARK: Apache

    static let apacheConfigFiles = [
        "/etc/apache2/httpd.conf",
        "/opt/homebrew/etc/httpd/httpd.conf",
        "/usr/local/etc/httpd/httpd.conf",
        "/Applications/MAMP/conf/apache/httpd.conf",
    ]

    /// Apache config files with an uncommented `LoadModule php*_module` line.
    static func modPhpConfigs(fs: PhpFS) -> [String] {
        apacheConfigFiles.filter { path in
            guard let text = fs.read(path) else { return false }
            return text.split(whereSeparator: \.isNewline).contains { raw in
                let words = raw.split(whereSeparator: { $0 == " " || $0 == "\t" })
                guard words.count >= 2, words[0].lowercased() == "loadmodule" else { return false }
                let module = words[1].lowercased()
                return module.hasPrefix("php") && module.hasSuffix("_module")
            }
        }
    }

    // MARK: Session folders

    /// `session.save_path` without the `N;` and `N;MODE;` prefixes (`"2;/var/sessions"`, `"1;0600;/var/sessions"`).
    static func sessionPath(fromSavePath value: String) -> String {
        var rest = value.trimmingCharacters(in: .whitespaces)
        func drop(_ pattern: String) {
            if let r = rest.range(of: pattern, options: .regularExpression), r.upperBound < rest.endIndex { rest = String(rest[r.upperBound...]) }
        }
        drop(#"^\d+;"#)
        if rest != value { drop(#"^[0-7]+;"#) }
        return rest.trimmingCharacters(in: .whitespaces)
    }

    /// The folders PHP sessions can live in on this Mac, existing ones only, each once.
    /// From `session.save_path` of every ini set (and FPM pool), the PHP defaults when a set leaves it empty,
    /// and MAMP's own folder. A folder is listed, never walked.
    static func sessionDirectories(fs: PhpFS, home: String, tempDirectory: String) -> [String] {
        let sets = iniSets(fs: fs, home: home)
        let key = "session.save_path"
        var candidates: [String] = []
        var needsDefaults = sets.isEmpty
        for set in sets {
            let v = iniValues(fs: fs, files: set.iniFiles, keys: [key])[key]?.value ?? ""
            let p = sessionPath(fromSavePath: v)
            if p.isEmpty { needsDefaults = true } else { candidates.append(p) }
            for f in set.poolFiles {
                guard let text = fs.read(f) else { continue }
                for pool in parsePools(text, file: f, keys: [key]) {
                    if let pv = pool.values[key] { let pp = sessionPath(fromSavePath: pv); if !pp.isEmpty { candidates.append(pp) } }
                }
            }
        }
        if needsDefaults { candidates += ["/tmp", "/private/var/tmp", tempDirectory] }
        candidates.append("/Applications/MAMP/tmp/php")

        var out: [String] = []
        var seen = Set<String>()
        for c in candidates where c.hasPrefix("/") && fs.isDirectory(c) {
            let std = fs.resolved(c)
            if seen.insert(std).inserted { out.append(c.hasSuffix("/") && c.count > 1 ? String(c.dropLast()) : c) }
        }
        return out
    }
}
