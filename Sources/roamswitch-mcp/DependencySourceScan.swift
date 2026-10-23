// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.3 (build 182).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Static check for settings that make a dependency-confusion attack possible: a public package that takes
/// the place of a private one of the same name, because the package manager looks in more than one place.
///
/// Two kinds of finding, both read from files in the project folders `PackageCveWatchedFolders` tracks:
///  * `pip_extra_index_url`: `--extra-index-url` / `extra-index-url` in `requirements*.txt`, `pip.conf`,
///    `pyproject.toml` or `uv.toml`. pip then asks the extra index and PyPI and takes the highest version,
///    so a squatted name on PyPI with a higher version wins.
///  * `npm_scope_not_pinned`: an npm lockfile resolves packages of a scope (`@acme/x`) from a registry that
///    is not npmjs.org, and no `.npmrc` (in the project, above it up to the watched folder, or in the home
///    folder) maps that scope to that registry with `@acme:registry=`. Without the mapping, an install
///    that has no lockfile entry for the name asks the default registry.
///
/// What this is not: it never asks a registry whether a name is free to claim, so it does not know that an
/// attack is possible, only that the setting allows one. It sends no network request and executes nothing.
/// Not evaluated: unscoped npm packages from a private registry (no `.npmrc` key can pin them), yarn Berry
/// lockfiles (they do not record the source URL), Poetry's `[[tool.poetry.source]]`, uv's `[[tool.uv.index]]`,
/// and index URLs that are not http(s). Credentials inside a URL are dropped; only the host is kept.
enum DependencySourceScan {

    enum Kind: String, Codable, Equatable {
        case pipExtraIndexUrl = "pip_extra_index_url"
        case npmScopeNotPinned = "npm_scope_not_pinned"
    }

    struct Finding: Identifiable, Equatable {
        let kind: Kind
        /// Absolute path of the file the finding comes from.
        let file: String
        /// 1-based line (pip findings); nil for npm.
        let line: Int?
        /// Host of the index or registry, without credentials, lower case.
        let host: String
        /// `@acme` (npm findings); nil for pip.
        let scope: String?
        /// npm: how many packages of the scope the lockfile resolves from `host`. 0 for pip.
        let packageCount: Int

        var id: String { "\(kind.rawValue)|\(file)|\(line ?? 0)|\(scope ?? "")|\(host)" }
        var fileName: String { (file as NSString).lastPathComponent }
        var projectDisplay: String { ((file as NSString).deletingLastPathComponent as NSString).abbreviatingWithTildeInPath }
    }

    /// Hosts that are the default source, so using them is not a finding.
    static let defaultNpmHosts: Set<String> = ["registry.npmjs.org", "registry.npmjs.com", "registry.yarnpkg.com"]
    static let defaultPipHosts: Set<String> = ["pypi.org", "files.pythonhosted.org"]

    // MARK: - URL handling

    /// Host of an http(s) URL, lower case, never with credentials. nil for anything else.
    static func host(ofURL text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: CharacterSet(charactersIn: "\"' \t,;[]"))
        guard let parts = URLComponents(string: trimmed), let scheme = parts.scheme?.lowercased(),
              scheme == "http" || scheme == "https", let host = parts.host, !host.isEmpty else { return nil }
        return host.lowercased()
    }

    // MARK: - pip

    typealias LineHost = (line: Int, host: String)

    private static func strippedComment(_ line: Substring) -> String {
        var text = String(line)
        if let hash = text.range(of: " #") { text = String(text[..<hash.lowerBound]) }
        return text.trimmingCharacters(in: .whitespaces)
    }

    /// `--extra-index-url URL` and `--extra-index-url=URL` lines of a requirements file.
    static func pipExtraIndexInRequirements(_ text: String) -> [LineHost] {
        var out: [LineHost] = []
        for (index, raw) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let line = strippedComment(raw)
            guard line.hasPrefix("--extra-index-url") else { continue }
            let rest = line.dropFirst("--extra-index-url".count)
            guard let first = rest.first, first == "=" || first == " " || first == "\t" else { continue }
            let value = rest.dropFirst(first == "=" ? 1 : 0).trimmingCharacters(in: .whitespaces)
            if let host = host(ofURL: value) { out.append((index + 1, host)) }
        }
        return out
    }

    /// `extra-index-url` (or `extra_index_url`) in a pip.conf: the value may continue on indented lines.
    static func pipExtraIndexInPipConf(_ text: String) -> [LineHost] {
        var out: [LineHost] = []
        var inValue = false
        for (index, raw) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") || trimmed.hasPrefix(";") { continue }
            let indented = raw.first == " " || raw.first == "\t"
            if inValue, indented, trimmed.lowercased().hasPrefix("http") {
                for token in trimmed.split(whereSeparator: { $0 == " " || $0 == "\t" }) {
                    if let host = host(ofURL: String(token)) { out.append((index + 1, host)) }
                }
                continue
            }
            inValue = false
            guard let eq = trimmed.firstIndex(where: { $0 == "=" || $0 == ":" }) else { continue }
            let key = trimmed[..<eq].trimmingCharacters(in: .whitespaces).lowercased().replacingOccurrences(of: "_", with: "-")
            guard key == "extra-index-url" else { continue }
            inValue = true
            for token in trimmed[trimmed.index(after: eq)...].split(whereSeparator: { $0 == " " || $0 == "\t" }) {
                if let host = host(ofURL: String(token)) { out.append((index + 1, host)) }
            }
        }
        return out
    }

    /// `extra-index-url = "…"` or `= ["…", "…"]` in pyproject.toml / uv.toml (an array may span lines).
    static func pipExtraIndexInToml(_ text: String) -> [LineHost] {
        var out: [LineHost] = []
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        var i = 0
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            defer { i += 1 }
            guard !line.hasPrefix("#"), line.hasPrefix("extra-index-url") || line.hasPrefix("extra_index_url") else { continue }
            guard let eq = line.firstIndex(of: "=") else { continue }
            var value = String(line[line.index(after: eq)...])
            let startLine = i + 1
            if value.contains("["), !value.contains("]") {
                var j = i + 1
                while j < lines.count, j < i + 50 {
                    value += " " + lines[j]
                    if lines[j].contains("]") { break }
                    j += 1
                }
            }
            for token in value.split(whereSeparator: { $0 == "," || $0 == " " || $0 == "\t" }) {
                if let host = host(ofURL: String(token)) { out.append((startLine, host)) }
            }
        }
        return out
    }

    // MARK: - npm

    typealias ResolvedEntry = (name: String, url: String)

    /// `node_modules/a/node_modules/@s/b` -> `@s/b`.
    private static func nameFromLockKey(_ key: String) -> String? {
        guard let range = key.range(of: "node_modules/", options: .backwards) else { return nil }
        let name = String(key[range.upperBound...])
        return name.isEmpty ? nil : name
    }

    /// package-lock.json / npm-shrinkwrap.json (lockfile v1 `dependencies`, v2 and v3 `packages`).
    static func resolvedEntries(packageLock text: String) -> [ResolvedEntry] {
        guard let data = text.data(using: .utf8),
              let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return [] }
        var out: [ResolvedEntry] = []
        if let packages = root["packages"] as? [String: Any] {
            for (key, value) in packages {
                guard let dict = value as? [String: Any], dict["link"] as? Bool != true,
                      let url = dict["resolved"] as? String,
                      let name = (dict["name"] as? String) ?? nameFromLockKey(key) else { continue }
                out.append((name, url))
            }
        } else if let dependencies = root["dependencies"] as? [String: Any] {
            func walk(_ deps: [String: Any], depth: Int) {
                guard depth < 40 else { return }
                for (name, value) in deps {
                    guard let dict = value as? [String: Any] else { continue }
                    if let url = dict["resolved"] as? String { out.append((name, url)) }
                    if let nested = dict["dependencies"] as? [String: Any] { walk(nested, depth: depth + 1) }
                }
            }
            walk(dependencies, depth: 0)
        }
        return out
    }

    /// yarn.lock v1. Berry (`__metadata:`) does not record where a package came from, so it yields nothing.
    static func resolvedEntries(yarnLock text: String) -> [ResolvedEntry] {
        if text.contains("__metadata:") { return [] }
        var out: [ResolvedEntry] = []
        var current: String?
        for raw in text.split(separator: "\n", omittingEmptySubsequences: false) {
            if raw.hasPrefix("#") || raw.isEmpty { continue }
            if raw.first != " " {
                // `"@scope/name@^1.0.0", "@scope/name@^1.1.0":`  or  `name@^1.0.0:`
                let header = raw.trimmingCharacters(in: CharacterSet(charactersIn: ": "))
                let first = header.split(separator: ",").first.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\" ")) } ?? ""
                if let at = first.dropFirst().firstIndex(of: "@") {
                    current = String(first[..<at])
                } else {
                    current = nil
                }
                continue
            }
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("resolved "), let name = current {
                let url = line.dropFirst("resolved ".count).trimmingCharacters(in: CharacterSet(charactersIn: "\" "))
                out.append((name, url))
            }
        }
        return out
    }

    /// pnpm-lock.yaml: a `tarball:` URL appears in a package's `resolution` only when it is not the default form.
    static func resolvedEntries(pnpmLock text: String) -> [ResolvedEntry] {
        var out: [ResolvedEntry] = []
        var current: String?
        for raw in text.split(separator: "\n", omittingEmptySubsequences: false) {
            if raw.hasPrefix("  "), !raw.hasPrefix("   ") {
                // `  /@scope/name@1.2.3:`  or  `  '@scope/name@1.2.3':`
                var key = raw.trimmingCharacters(in: CharacterSet(charactersIn: " :'\""))
                if key.hasPrefix("/") { key.removeFirst() }
                if let at = key.dropFirst().firstIndex(of: "@") {
                    current = String(key[..<at])
                } else {
                    current = nil
                }
                continue
            }
            guard let name = current, let range = raw.range(of: "tarball:") else { continue }
            let rest = raw[range.upperBound...]
            let url = rest.split(whereSeparator: { $0 == "," || $0 == "}" || $0 == " " }).first.map(String.init) ?? ""
            if !url.isEmpty { out.append((name, url.trimmingCharacters(in: CharacterSet(charactersIn: "'\"")))) }
        }
        return out
    }

    /// `@scope:registry=URL` lines of an .npmrc. The value is the registry's host; `*` when the URL holds an
    /// environment variable (`${REGISTRY}`) and the host cannot be known, which counts as pinned.
    static func npmrcScopeRegistries(_ text: String) -> [String: String] {
        var out: [String: String] = [:]
        for raw in text.split(whereSeparator: \.isNewline) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("@"), !line.hasPrefix("#"), let eq = line.firstIndex(of: "=") else { continue }
            let key = line[..<eq].trimmingCharacters(in: .whitespaces)
            guard key.hasSuffix(":registry") else { continue }
            let scope = String(key.dropLast(":registry".count)).lowercased()
            let value = line[line.index(after: eq)...].trimmingCharacters(in: CharacterSet(charactersIn: " \"'"))
            if value.contains("${") { out[scope] = "*" } else if let host = host(ofURL: value) { out[scope] = host }
        }
        return out
    }

    /// Findings for one lockfile: scopes resolved from a non-default host that no `.npmrc` pins to it.
    /// `pinned`: scope -> hosts it is mapped to (`*` = unknown, counts as pinned).
    static func npmFindings(entries: [ResolvedEntry], pinned: [String: Set<String>], file: String) -> [Finding] {
        var groups: [String: (scope: String, host: String, names: Set<String>)] = [:]
        for (name, url) in entries {
            guard name.hasPrefix("@"), let slash = name.firstIndex(of: "/"),
                  let host = host(ofURL: url), !defaultNpmHosts.contains(host) else { continue }
            let scope = String(name[..<slash]).lowercased()
            if let hosts = pinned[scope], hosts.contains("*") || hosts.contains(host) { continue }
            let key = scope + "|" + host
            var group = groups[key] ?? (scope, host, [])
            group.names.insert(name)
            groups[key] = group
        }
        return groups.values
            .sorted { ($0.scope, $0.host) < ($1.scope, $1.host) }
            .map { Finding(kind: .npmScopeNotPinned, file: file, line: nil, host: $0.host, scope: $0.scope, packageCount: $0.names.count) }
    }

    // MARK: - Walking

    private static let skipDirNames: Set<String> =
        [".git", "node_modules", "vendor", "target", ".venv", "venv", "dist", "build", ".tox"]
    private static let npmLockfiles: Set<String> = ["package-lock.json", "npm-shrinkwrap.json", "yarn.lock", "pnpm-lock.yaml"]

    private static func isRequirementsFile(_ name: String) -> Bool {
        name.hasPrefix("requirements") && name.hasSuffix(".txt")
    }

    /// Every `.npmrc` that applies to a lockfile in `directory`: its own folder and each folder above it up to
    /// `root`, then the home folder. Pins from all of them count.
    private static func pinnedScopes(forLockfileIn directory: String, root: String, home: String?, cache: inout [String: [String: String]]) -> [String: Set<String>] {
        var dirs: [String] = []
        var current = directory
        while SafeScanFS.isWithin(current, root: root) {
            dirs.append(current)
            if current == root { break }
            current = (current as NSString).deletingLastPathComponent
        }
        if let home { dirs.append(home) }
        var pinned: [String: Set<String>] = [:]
        for dir in dirs {
            let path = (dir as NSString).appendingPathComponent(".npmrc")
            let scopes: [String: String]
            if let known = cache[path] {
                scopes = known
            } else {
                scopes = SafeScanFS.readRegularFile(atPath: path, maxBytes: SafeScanFS.maxFileBytes)
                    .flatMap { String(data: $0, encoding: .utf8) }
                    .map(npmrcScopeRegistries) ?? [:]
                cache[path] = scopes
            }
            for (scope, host) in scopes { pinned[scope, default: []].insert(host) }
        }
        return pinned
    }

    /// Walks `folder` up to `maxDepth` levels (symlinks only while they stay inside the folder, see `SafeScanFS`).
    static func scanWatchedFolder(_ folder: URL, maxDepth: Int, home: String?, root: String? = nil, npmrcCache: inout [String: [String: String]]) -> [Finding] {
        var out: [Finding] = []
        guard let base = SafeScanFS.canonicalPath(folder.path) else { return out }
        let scopeRoot = root ?? base
        for entry in SafeScanFS.children(ofDirectory: base, root: scopeRoot) {
            if entry.kind == .directory {
                if maxDepth > 0, !skipDirNames.contains(entry.name) {
                    out.append(contentsOf: scanWatchedFolder(URL(fileURLWithPath: entry.path), maxDepth: maxDepth - 1, home: home, root: scopeRoot, npmrcCache: &npmrcCache))
                }
                continue
            }
            let name = entry.name
            let isPip = isRequirementsFile(name) || name == "pip.conf" || name == "pyproject.toml" || name == "uv.toml"
            guard isPip || npmLockfiles.contains(name),
                  let data = SafeScanFS.readRegularFile(atPath: entry.path, maxBytes: SafeScanFS.maxLockfileBytes),
                  let text = String(data: data, encoding: .utf8) else { continue }
            if isPip {
                let hits: [LineHost]
                if name == "pip.conf" { hits = pipExtraIndexInPipConf(text) }
                else if name.hasSuffix(".toml") { hits = pipExtraIndexInToml(text) }
                else { hits = pipExtraIndexInRequirements(text) }
                for hit in hits where !defaultPipHosts.contains(hit.host) {
                    out.append(Finding(kind: .pipExtraIndexUrl, file: entry.path, line: hit.line, host: hit.host, scope: nil, packageCount: 0))
                }
            } else {
                let entries: [ResolvedEntry]
                switch name {
                case "yarn.lock": entries = resolvedEntries(yarnLock: text)
                case "pnpm-lock.yaml": entries = resolvedEntries(pnpmLock: text)
                default: entries = resolvedEntries(packageLock: text)
                }
                let pinned = pinnedScopes(forLockfileIn: (entry.path as NSString).deletingLastPathComponent, root: scopeRoot, home: home, cache: &npmrcCache)
                out.append(contentsOf: npmFindings(entries: entries, pinned: pinned, file: entry.path))
            }
        }
        return out
    }

    static func runScan(watchedFolders: [String], home: String? = NSHomeDirectory()) -> [Finding] {
        var cache: [String: [String: String]] = [:]
        var findings: [Finding] = []
        for folder in watchedFolders {
            findings.append(contentsOf: scanWatchedFolder(URL(fileURLWithPath: folder), maxDepth: 6, home: home, npmrcCache: &cache))
        }
        return findings.sorted { ($0.file, $0.line ?? 0, $0.host) < ($1.file, $1.line ?? 0, $1.host) }
    }
}
