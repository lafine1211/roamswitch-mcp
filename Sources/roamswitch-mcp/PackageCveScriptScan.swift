// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.10.18 (build 136).
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
