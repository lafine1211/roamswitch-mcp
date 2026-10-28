// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.10 (build 189).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Static, read-only enumeration of `package.json` lifecycle scripts
/// (`preinstall`/`install`/`postinstall`/`prepare`) declared by installed
/// npm dependencies — inspired by a dev.to article on npm-install
/// supply-chain risk: these scripts run unconditionally at install time and
/// can execute arbitrary code, yet nothing in RoamSwitch previously
/// surfaced what's actually declared. This is a plain inventory, not a
/// threat verdict: a dangerous-looking command can be entirely legitimate
/// (native module rebuilds, postinstall setup wizards), and this scan makes
/// no network connection and never executes anything.
///
/// Reuses `PackageCveWatchedFolders`'s folder list — the same one
/// `PackageCveScanLanguages`'s lockfile scan uses — rather than
/// introducing a third watched-folder list.
enum PackageCveScriptScan {
    struct Finding: Identifiable {
        let packageName: String
        let packageVersion: String
        let scriptName: String
        let scriptCommand: String
        let relativePath: String
        /// A lightweight heuristic match against common risky shell
        /// patterns (`curl|sh`, `eval(`, `base64 -d`, ...) — reference
        /// information only, not a verdict. Many legitimate postinstall
        /// scripts (native module builds, telemetry opt-outs) also match.
        let isDangerPattern: Bool
        /// Which pattern in `dangerPatterns` matched (e.g. "curl | sh"),
        /// or nil when `isDangerPattern` is false. Exported/displayed
        /// alongside `isDangerPattern` so a reviewer sees *what* looked
        /// risky, not just a bare true/false.
        let dangerPatternLabel: String?

        var id: String { "\(relativePath)|\(scriptName)" }

        /// The project folder that owns the `node_modules` the package sits
        /// in, with the home folder shortened to `~`.
        var projectDisplay: String {
            let dir = relativePath.range(of: "/node_modules/").map { String(relativePath[..<$0.lowerBound]) }
                ?? (relativePath as NSString).deletingLastPathComponent
            return (dir as NSString).abbreviatingWithTildeInPath
        }
    }

    static let lifecycleScriptNames: [String] = ["preinstall", "install", "postinstall", "prepare"]

    /// Reference-only heuristic patterns, never treated as a definitive
    /// verdict — see this type's doc comment.
    private static let dangerPatterns: [(label: String, regex: NSRegularExpression)] = [
        ("curl | sh", #"curl[^|]*\|\s*(sudo\s+)?(sh|bash)\b"#),
        ("wget | sh", #"wget[^|]*\|\s*(sudo\s+)?(sh|bash)\b"#),
        ("eval()", #"\beval\s*\("#),
        ("base64 decode", #"base64\s+(-d|--decode)\b"#),
        ("node -e (inline eval)", #"\bnode\s+-e\b"#),
    ].compactMap { label, pattern in
        (try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])).map { (label, $0) }
    }

    static func matchesDangerPattern(_ command: String) -> Bool {
        matchedDangerPatternLabel(command) != nil
    }

    /// The label of the first `dangerPatterns` entry matching `command`,
    /// or nil if none match.
    static func matchedDangerPatternLabel(_ command: String) -> String? {
        let range = NSRange(command.startIndex..<command.endIndex, in: command)
        return dangerPatterns.first { $0.regex.firstMatch(in: command, range: range) != nil }?.label
    }

    private static let skipDirNames: Set<String> =
        [".git", "vendor", "target", ".venv", "venv", "dist", "build", ".tox"]

    /// Walks `folder` up to `maxDepth` levels like
    /// `PackageCveScanLanguages.scanWatchedFolder`, but branches into
    /// `enumerateLifecycleScripts(inNodeModules:)` on reaching a
    /// `node_modules` directory instead of skipping it outright — and never
    /// descends further within it (no nested `node_modules`).
    /// Symlinks are only followed while they stay inside the scan root
    /// (`SafeScanFS`); `root` is set by the recursion, callers omit it.
    static func scanWatchedFolder(_ folder: URL, maxDepth: Int, root: String? = nil) -> [Finding] {
        var out: [Finding] = []
        guard let base = SafeScanFS.canonicalPath(folder.path) else { return out }
        let scopeRoot = root ?? base
        for entry in SafeScanFS.children(ofDirectory: base, root: scopeRoot) {
            guard entry.kind == .directory else { continue }
            let entryURL = URL(fileURLWithPath: entry.path)
            if entry.name == "node_modules" {
                out.append(contentsOf: enumerateLifecycleScripts(inNodeModules: entryURL, root: scopeRoot))
                continue
            }
            if maxDepth > 0, !skipDirNames.contains(entry.name) {
                out.append(contentsOf: scanWatchedFolder(entryURL, maxDepth: maxDepth - 1, root: scopeRoot))
            }
        }
        return out
    }

    /// Enumerates lifecycle scripts one level under `node_modules`
    /// (`node_modules/<pkg>/package.json`), with one extra level for
    /// scoped packages (`node_modules/@scope/<pkg>/package.json`). Never
    /// descends into a package's own `node_modules` (nested dependency
    /// trees) — this is a top-level inventory, not a full recursive audit.
    /// A package directory that is a symlink (pnpm) is followed only when it
    /// resolves inside the scan root.
    static func enumerateLifecycleScripts(inNodeModules nodeModulesURL: URL, root: String? = nil) -> [Finding] {
        var out: [Finding] = []
        guard let base = SafeScanFS.canonicalPath(nodeModulesURL.path) else { return out }
        let scopeRoot = root ?? base
        for entry in SafeScanFS.children(ofDirectory: base, root: scopeRoot) where entry.kind == .directory {
            if entry.name.hasPrefix("@") {
                for scoped in SafeScanFS.children(ofDirectory: entry.path, root: scopeRoot) where scoped.kind == .directory {
                    out.append(contentsOf: extractLifecycleScripts(
                        packageDir: scoped.path, packageName: "\(entry.name)/\(scoped.name)", root: scopeRoot
                    ))
                }
            } else {
                out.append(contentsOf: extractLifecycleScripts(packageDir: entry.path, packageName: entry.name, root: scopeRoot))
            }
        }
        return out
    }

    private static func extractLifecycleScripts(packageDir: String, packageName: String, root: String) -> [Finding] {
        // No link-following read: regular file inside the scan root, size-capped.
        guard let manifest = SafeScanFS.readFile(packageDir + "/package.json", root: root),
              let obj = try? JSONSerialization.jsonObject(with: manifest.data) as? [String: Any] else { return [] }
        let manifestPath = manifest.path
        let version = (obj["version"] as? String) ?? ""
        guard let scripts = obj["scripts"] as? [String: Any] else { return [] }

        var out: [Finding] = []
        for scriptName in lifecycleScriptNames {
            guard let command = scripts[scriptName] as? String, !command.isEmpty else { continue }
            let dangerLabel = matchedDangerPatternLabel(command)
            out.append(Finding(
                packageName: packageName,
                packageVersion: version,
                scriptName: scriptName,
                // Attacker-authored (any dependency's package.json): cap + strip control chars.
                scriptCommand: MCPUntrustedText.sanitize(command),
                relativePath: manifestPath,
                isDangerPattern: dangerLabel != nil,
                dangerPatternLabel: dangerLabel
            ))
        }
        return out
    }

    /// Entry point: scans every watched folder (the same list
    /// `PackageCveScanLanguages` uses) for lifecycle scripts declared by
    /// currently-installed npm dependencies.
    /// Upper bound on folders scanned per call.
    static let maxWatchedFolders = 50

    static func runScan(watchedFolders: [String]) -> [Finding] {
        var out: [Finding] = []
        var seen = Set<String>()
        for folder in watchedFolders.prefix(maxWatchedFolders) {
            // Defence in depth (callers exposed to untrusted input validate against the
            // registered-folder list first): absolute, existing directory, no duplicates.
            guard folder.hasPrefix("/"), !folder.contains("\0") else { continue }
            let url = URL(fileURLWithPath: folder).resolvingSymlinksInPath()
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue,
                  seen.insert(url.path).inserted else { continue }
            out.append(contentsOf: scanWatchedFolder(url, maxDepth: 6))
        }
        return out
    }
}

// MARK: - Install-time code that appeared since a person last looked

/// A package that gains an install script, or compiled code, in a new release is the plainest way a
/// compromised dependency reaches a developer's machine: the scan above lists what is declared today but
/// cannot say what is new. This compares today's state with the state a person accepted. It reads local
/// files only, runs nothing, and records digests of the commands, never the commands themselves.
///
/// Only the direction that adds install-time code is reported (a script added, a script changed, compiled
/// code added, a new package that brings either). A script or a package that is gone is not. The accepted
/// state moves only when a person asks for it (a button in the app), never by a scan and never through the
/// MCP tool, so an agent cannot accept its own supply-chain change.
extension PackageCveScriptScan {

    /// One installed package as seen on disk.
    struct Observed: Equatable {
        var version: String
        /// Lifecycle script name -> command (the command is not stored in the baseline).
        var scripts: [String: String]
        /// A `binding.gyp`, a `.node`/`.so`/`.dylib`/`.dll` file or a file that starts like an executable.
        var native: Bool
    }

    /// `node_modules` folder (canonical path) -> package name -> observation.
    typealias Observation = [String: [String: Observed]]

    struct PackageState: Codable, Equatable {
        var version: String
        /// Lifecycle script name -> hex SHA-256 of the command.
        var scripts: [String: String]
        var native: Bool
    }

    struct InstallBaseline: Codable, Equatable {
        var version = 1
        /// ISO 8601, UTC.
        var acceptedAt: String
        /// `node_modules` folder -> package name -> state.
        var folders: [String: [String: PackageState]]
    }

    enum DriftKind: String, Equatable {
        case scriptAdded = "script_added"
        case scriptChanged = "script_changed"
        case nativeAdded = "native_added"
        case newPackageWithInstallCode = "new_package_with_install_code"
    }

    struct Drift: Equatable, Identifiable {
        let nodeModules: String
        let packageName: String
        let oldVersion: String?
        let newVersion: String
        let kind: DriftKind
        /// The lifecycle script concerned (script kinds only).
        let scriptName: String?
        /// `high` or `medium`.
        let severity: String
        /// Label of the risky pattern the command matches, if it does (see `dangerPatterns`).
        let dangerPatternLabel: String?

        var id: String { "\(nodeModules)|\(packageName)|\(kind.rawValue)|\(scriptName ?? "")" }
    }

    static let nativeFileExtensions: Set<String> = ["node", "so", "dylib", "dll"]
    private static let nativeScanMaxEntries = 300
    private static let nativeScanMaxDepth = 3
    private static let nativeMagicReadsPerPackage = 40

    // MARK: Observing

    /// Every top-level package of every `node_modules` under the watched folders, with its install scripts and
    /// whether it carries compiled code. Walks like `runScan`.
    static func observe(watchedFolders: [String]) -> Observation {
        var out: Observation = [:]
        var seen = Set<String>()
        for folder in watchedFolders.prefix(maxWatchedFolders) {
            guard folder.hasPrefix("/"), !folder.contains("\0") else { continue }
            let url = URL(fileURLWithPath: folder).resolvingSymlinksInPath()
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue,
                  seen.insert(url.path).inserted else { continue }
            observeWatchedFolder(url, maxDepth: 6, root: nil, into: &out)
        }
        return out
    }

    private static func observeWatchedFolder(_ folder: URL, maxDepth: Int, root: String?, into out: inout Observation) {
        guard let base = SafeScanFS.canonicalPath(folder.path) else { return }
        let scopeRoot = root ?? base
        for entry in SafeScanFS.children(ofDirectory: base, root: scopeRoot) where entry.kind == .directory {
            if entry.name == "node_modules" {
                out[entry.path] = observeNodeModules(entry.path, root: scopeRoot)
            } else if maxDepth > 0, !skipDirNames.contains(entry.name) {
                observeWatchedFolder(URL(fileURLWithPath: entry.path), maxDepth: maxDepth - 1, root: scopeRoot, into: &out)
            }
        }
    }

    private static func observeNodeModules(_ path: String, root: String) -> [String: Observed] {
        var out: [String: Observed] = [:]
        for entry in SafeScanFS.children(ofDirectory: path, root: root) where entry.kind == .directory {
            if entry.name.hasPrefix("@") {
                for scoped in SafeScanFS.children(ofDirectory: entry.path, root: root) where scoped.kind == .directory {
                    if let seen = observePackage(dir: scoped.path, root: root) { out["\(entry.name)/\(scoped.name)"] = seen }
                }
            } else if !entry.name.hasPrefix("."), let seen = observePackage(dir: entry.path, root: root) {
                out[entry.name] = seen
            }
        }
        return out
    }

    private static func observePackage(dir: String, root: String) -> Observed? {
        guard let manifest = SafeScanFS.readFile(dir + "/package.json", root: root),
              let object = try? JSONSerialization.jsonObject(with: manifest.data) as? [String: Any] else { return nil }
        var scripts: [String: String] = [:]
        if let declared = object["scripts"] as? [String: Any] {
            for name in lifecycleScriptNames {
                if let command = declared[name] as? String, !command.isEmpty { scripts[name] = command }
            }
        }
        return Observed(version: (object["version"] as? String) ?? "", scripts: scripts, native: hasCompiledCode(packageDir: dir, root: root))
    }

    /// Looks a few levels into a package for `binding.gyp`, a native module or an executable. Bounded in depth,
    /// entries and magic-number reads, and never enters a nested `node_modules`.
    static func hasCompiledCode(packageDir: String, root: String) -> Bool {
        var visited = 0
        var magicReads = 0
        func walk(_ dir: String, depth: Int) -> Bool {
            for entry in SafeScanFS.children(ofDirectory: dir, root: root) {
                visited += 1
                if visited > nativeScanMaxEntries { return false }
                switch entry.kind {
                case .directory:
                    if depth < nativeScanMaxDepth, entry.name != "node_modules", walk(entry.path, depth: depth + 1) { return true }
                case .regularFile:
                    let ext = (entry.name as NSString).pathExtension.lowercased()
                    if entry.name == "binding.gyp" || nativeFileExtensions.contains(ext) { return true }
                    if ext.isEmpty, entry.size >= 4096, magicReads < nativeMagicReadsPerPackage {
                        magicReads += 1
                        if startsLikeExecutable(entry.path) { return true }
                    }
                }
            }
            return false
        }
        return walk(packageDir, depth: 1)
    }

    /// ELF, Mach-O (thin and fat) or PE.
    static func startsLikeExecutable(_ path: String) -> Bool {
        let fd = open(path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
        guard fd >= 0 else { return false }
        defer { close(fd) }
        var head = [UInt8](repeating: 0, count: 4)
        guard read(fd, &head, 4) == 4 else { return false }
        return isExecutableMagic(head)
    }

    static func isExecutableMagic(_ head: [UInt8]) -> Bool {
        guard head.count >= 4 else { return false }
        if head[0] == 0x7F, head[1] == 0x45, head[2] == 0x4C, head[3] == 0x46 { return true }          // ELF
        let word = head.prefix(4).map { String(format: "%02x", $0) }.joined()
        if ["feedface", "feedfacf", "cefaedfe", "cffaedfe", "cafebabe"].contains(word) { return true }   // Mach-O
        return head[0] == 0x4D && head[1] == 0x5A                                                        // PE ("MZ")
    }

    // MARK: Comparing

    /// What the baseline keeps for an observation: digests of the commands, not the commands.
    static func installBaselineFolders(_ observation: Observation) -> [String: [String: PackageState]] {
        observation.mapValues { packages in
            packages.mapValues { seen in
                PackageState(version: seen.version,
                             scripts: seen.scripts.mapValues { AgentSetupBaseline.sha256Hex(Data($0.utf8)) },
                             native: seen.native)
            }
        }
    }

    /// A folder that was not in the accepted state is not compared (a new project would otherwise flag every
    /// package in it); a package that was not in a covered folder counts only when it brings install-time code.
    static func drift(from baseline: InstallBaseline, to observation: Observation) -> [Drift] {
        var out: [Drift] = []
        for (nodeModules, packages) in observation.sorted(by: { $0.key < $1.key }) {
            guard let known = baseline.folders[nodeModules] else { continue }
            for (name, seen) in packages.sorted(by: { $0.key < $1.key }) {
                func danger(_ script: String) -> String? { seen.scripts[script].flatMap(matchedDangerPatternLabel) }
                func make(_ kind: DriftKind, _ script: String?, _ severity: String, old: String?) -> Drift {
                    Drift(nodeModules: nodeModules, packageName: name, oldVersion: old, newVersion: seen.version, kind: kind,
                          scriptName: script, severity: severity, dangerPatternLabel: script.flatMap(danger))
                }
                guard let before = known[name] else {
                    if !seen.scripts.isEmpty || seen.native {
                        let risky = seen.scripts.keys.contains { danger($0) != nil }
                        let script = lifecycleScriptNames.first { seen.scripts[$0] != nil }
                        out.append(make(.newPackageWithInstallCode, script, risky ? "high" : "medium", old: nil))
                    }
                    continue
                }
                for script in lifecycleScriptNames {
                    guard let command = seen.scripts[script] else { continue }
                    if before.scripts[script] == nil {
                        out.append(make(.scriptAdded, script, "high", old: before.version))
                    } else if before.scripts[script] != AgentSetupBaseline.sha256Hex(Data(command.utf8)) {
                        out.append(make(.scriptChanged, script, danger(script) != nil ? "high" : "medium", old: before.version))
                    }
                }
                if seen.native, !before.native {
                    out.append(make(.nativeAdded, nil, before.version == seen.version ? "high" : "medium", old: before.version))
                }
            }
        }
        return out.sorted { ($0.severity == "high" ? 0 : 1, $0.id) < ($1.severity == "high" ? 0 : 1, $1.id) }
    }

    /// The `node_modules` folders seen now that the accepted state does not cover. `drift` skips them, so an empty
    /// `drift` says nothing about them: the caller must say they were not compared.
    static func uncoveredFolders(baseline: InstallBaseline, observation: Observation) -> [String] {
        observation.keys.filter { baseline.folders[$0] == nil }.sorted()
    }

    // MARK: Storage

    static var installBaselineURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory() + "/Library/Application Support")
        return support.appendingPathComponent("RoamSwitch/package_install_baseline.json")
    }

    static func loadInstallBaseline(from url: URL = installBaselineURL) -> InstallBaseline? {
        guard let data = try? Data(contentsOf: url),
              let store = try? StrictJSON.decode(InstallBaseline.self, from: data), store.version == 1 else { return nil }
        return store
    }

    /// Records `observation` as the accepted state. The caller is a person (a button); a scan and the MCP tool never
    /// call this. Atomic, owner-only.
    @discardableResult
    static func acceptInstallState(_ observation: Observation, to url: URL = installBaselineURL, now: Date = Date()) throws -> InstallBaseline {
        let store = InstallBaseline(acceptedAt: AgentSetupBaseline.isoString(now), folders: installBaselineFolders(observation))
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(store)
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let temporary = directory.appendingPathComponent(".package_install_baseline.\(UUID().uuidString).tmp")
        guard FileManager.default.createFile(atPath: temporary.path, contents: data, attributes: [.posixPermissions: 0o600]) else {
            throw CocoaError(.fileWriteUnknown)
        }
        if FileManager.default.fileExists(atPath: url.path) {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: temporary)
        } else {
            try FileManager.default.moveItem(at: temporary, to: url)
        }
        return store
    }
}
