// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.6 (build 185).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import CryptoKit

/// The "accepted" state of the AI agent setup, for change detection.
///
/// Why: a skill, an instruction file or an MCP server definition is reviewed once and then trusted
/// from then on. If it is swapped later (a skill that updates itself, a repository that rewrites
/// `.mcp.json`, a file replaced by another process), nothing tells the user. This file keeps what
/// the user last reviewed and accepted, as SHA-256 digests only, so the next audit can say "this
/// changed" or "this is new".
///
/// The baseline moves only when a person asks for it (the GUI button, `roamswitch audit-agent-setup
/// --accept` on Linux). It is never updated by an audit run and never by the MCP tool, so an agent
/// cannot accept its own tampering, and a change stays reported until someone has looked at it.
///
/// What is stored: a path, a digest and (for an MCP server) one digest per top-level key such as
/// `command` or `args`. File contents, arguments and environment values are never stored, so the
/// baseline holds no secret. The file is written with mode 0600. It protects against a change the
/// user did not notice; a process that can write to the user's home can also rewrite this file.
enum AgentSetupBaseline {

    struct Entry: Codable, Equatable {
        /// Hex SHA-256 of the file, or of the canonical JSON of the MCP server definition.
        var sha256: String
        /// MCP servers only: hex SHA-256 of each top-level key's value (`command`, `args`, `env`, ...).
        var fields: [String: String]?
    }

    struct Snapshot: Codable, Equatable {
        /// Folders the snapshot covers: the home folder first, then every registered project folder.
        var scopes: [String] = []
        /// Audited file path -> digest.
        var files: [String: Entry] = [:]
        /// MCP config path -> server name -> digest.
        var servers: [String: [String: Entry]] = [:]
        /// Claude Code settings path -> what the file allows, denies and runs. nil in a state accepted before
        /// settings were recorded: such a state says nothing about them, so nothing is compared.
        var settings: [String: SettingsEntry]?

        var isEmpty: Bool { files.isEmpty && servers.isEmpty && (settings ?? [:]).isEmpty }
    }

    /// What a Claude Code settings file lets happen without asking, as digests only. A rule is hashed, not
    /// stored, so the baseline holds no command line and no path pattern. Which way a change goes matters
    /// here: a deny rule that disappears weakens the setup, a deny rule that is added does not.
    struct SettingsEntry: Codable, Equatable {
        /// Hex SHA-256 of each `permissions.deny` rule.
        var denyRules: [String] = []
        /// Hex SHA-256 of each `permissions.allow` rule that lets any command run (see `AgentSetupAuditor.broadGrant`).
        var broadAllow: [String] = []
        /// Hex SHA-256 of event, matcher and command of each hook.
        var hooks: [String] = []
        /// `permissions.defaultMode` when it is one of the known modes.
        var defaultMode: String?
        /// `sandbox.enabled` is explicitly false.
        var sandboxDisabled = false
        /// `skipDangerousModePermissionPrompt` is true.
        var dangerousPromptSkipped = false
        /// The file exists but could not be read or parsed. It is not compared, so a file that cannot be read
        /// is never mistaken for one whose rules are gone.
        var unreadable = false
    }

    /// One way a settings file got weaker than the accepted state.
    enum SettingsWeakening: Equatable {
        case denyRemoved(Int)
        case broadAllowAdded(Int)
        case hookAdded(Int)
        /// A hook of the accepted state is gone and nothing replaced it. A hook can be a guard (a monitor, a command
        /// that blocks a tool call), so losing one weakens the setup as much as gaining one.
        case hookRemoved(Int)
        case modeRaised(from: String, to: String)
        case sandboxDisabled
        case dangerousPromptSkipped
    }

    struct Store: Codable, Equatable {
        var version = 1
        /// ISO 8601, UTC.
        var acceptedAt: String
        var snapshot: Snapshot
    }

    enum Change: Equatable {
        case fileChanged(path: String)
        case fileAdded(path: String)
        case serverChanged(path: String, name: String, fields: [String])
        case serverAdded(path: String, name: String)
        case settingsWeakened(path: String, reasons: [SettingsWeakening])
    }

    /// Permission modes from the most to the least careful. Only these are ranked; any other value is not compared.
    static let modeRank: [String: Int] = ["plan": 0, "default": 1, "acceptEdits": 2, "bypassPermissions": 3]

    // MARK: - Digests

    /// Files above this size are not hashed (only their size is compared).
    static let maxHashedBytes = 64 * 1024 * 1024

    static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    /// Streams the file, so a large file in a skill folder does not have to fit in memory.
    /// A file above `maxHashedBytes` yields `size:<bytes>`; an unreadable one yields nil.
    static func sha256Hex(ofFileAt path: String) -> String? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let size = (attrs[.size] as? NSNumber)?.intValue else { return nil }
        if size > maxHashedBytes { return "size:\(size)" }
        guard let handle = FileHandle(forReadingAtPath: path) else { return nil }
        defer { try? handle.close() }
        var hasher = SHA256()
        while let chunk = try? handle.read(upToCount: 1 << 20), !chunk.isEmpty {
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    /// Digest of an MCP server definition: the whole object, and each top-level key on its own.
    static func serverEntry(_ config: [String: Any]) -> Entry? {
        func canonical(_ value: Any) -> Data? {
            try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys, .fragmentsAllowed])
        }
        guard let whole = canonical(config) else { return nil }
        var fields: [String: String] = [:]
        for (key, value) in config {
            if let data = canonical(value) { fields[key] = sha256Hex(data) }
        }
        return Entry(sha256: sha256Hex(whole), fields: fields)
    }

    // MARK: - Scopes

    /// The scope a path belongs to: the longest folder in `scopes` that contains it, else the first
    /// scope (the home folder), which also covers files such as a custom `OPENCLAW_CONFIG_PATH`.
    static func scope(of path: String, in scopes: [String]) -> String? {
        var best: String?
        for scope in scopes where path == scope || path.hasPrefix(scope.hasSuffix("/") ? scope : scope + "/") {
            if best == nil || scope.count > best!.count { best = scope }
        }
        return best ?? scopes.first
    }

    // MARK: - Compare

    /// What differs between the accepted state and the current one. A file or server that is gone
    /// is not reported (removing something cannot plant an instruction). A new file or server counts
    /// only inside a folder that was already covered when the state was accepted, so registering
    /// another project folder does not flag everything in it.
    static func compare(_ store: Store, with current: Snapshot) -> [Change] {
        let old = store.snapshot
        var changes: [Change] = []
        for path in current.files.keys.sorted() {
            guard let entry = current.files[path] else { continue }
            if let previous = old.files[path] {
                if previous.sha256 != entry.sha256 { changes.append(.fileChanged(path: path)) }
            } else if let scope = scope(of: path, in: current.scopes), old.scopes.contains(scope) {
                changes.append(.fileAdded(path: path))
            }
        }
        for path in current.servers.keys.sorted() {
            guard let servers = current.servers[path] else { continue }
            let known = old.servers[path]
            let covered = scope(of: path, in: current.scopes).map { old.scopes.contains($0) } ?? false
            for name in servers.keys.sorted() {
                guard let entry = servers[name] else { continue }
                if let previous = known?[name] {
                    if previous.sha256 != entry.sha256 {
                        let before = previous.fields ?? [:]
                        let after = entry.fields ?? [:]
                        let changed = Set(before.keys).union(after.keys).filter { before[$0] != after[$0] }.sorted()
                        changes.append(.serverChanged(path: path, name: name, fields: changed))
                    }
                } else if covered {
                    changes.append(.serverAdded(path: path, name: name))
                }
            }
        }
        changes += settingsChanges(old: old, current: current)
        return changes
    }

    /// Only the direction that weakens is reported. A deleted settings file counts as a file with no rules, so
    /// deleting one that held deny rules is a weakening; a file that is new counts only in a folder that was
    /// already covered, as for the other kinds.
    static func settingsChanges(old: Snapshot, current: Snapshot) -> [Change] {
        guard let oldSettings = old.settings else { return [] }
        let currentSettings = current.settings ?? [:]
        var changes: [Change] = []
        for path in Set(oldSettings.keys).union(currentSettings.keys).sorted() {
            // A file of a folder that is no longer registered is not a deleted file. The home folder covers its own
            // `.claude` settings only, not the projects that happen to lie under it.
            if currentSettings[path] == nil, !isSettingsCandidate(path, scopes: current.scopes) { continue }
            let now = currentSettings[path] ?? SettingsEntry()
            if now.unreadable { continue }
            let before: SettingsEntry
            if let previous = oldSettings[path] {
                if previous.unreadable { continue }
                before = previous
            } else if let scope = scope(of: path, in: current.scopes), old.scopes.contains(scope) {
                before = SettingsEntry()
            } else {
                continue
            }
            var reasons: [SettingsWeakening] = []
            let denyRemoved = Set(before.denyRules).subtracting(now.denyRules).count
            if denyRemoved > 0 { reasons.append(.denyRemoved(denyRemoved)) }
            let allowAdded = Set(now.broadAllow).subtracting(before.broadAllow).count
            if allowAdded > 0 { reasons.append(.broadAllowAdded(allowAdded)) }
            let hooksAdded = Set(now.hooks).subtracting(before.hooks).count
            if hooksAdded > 0 { reasons.append(.hookAdded(hooksAdded)) }
            // An edited hook shows up as one gone and one new, which is already `hookAdded`: only the ones without a
            // replacement count as removed.
            let hooksRemoved = max(0, Set(before.hooks).subtracting(now.hooks).count - hooksAdded)
            if hooksRemoved > 0 { reasons.append(.hookRemoved(hooksRemoved)) }
            let oldMode = before.defaultMode ?? "default"
            let newMode = now.defaultMode ?? "default"
            if let a = modeRank[oldMode], let b = modeRank[newMode], b > a { reasons.append(.modeRaised(from: oldMode, to: newMode)) }
            if now.sandboxDisabled && !before.sandboxDisabled { reasons.append(.sandboxDisabled) }
            if now.dangerousPromptSkipped && !before.dangerousPromptSkipped { reasons.append(.dangerousPromptSkipped) }
            if !reasons.isEmpty { changes.append(.settingsWeakened(path: path, reasons: reasons)) }
        }
        return changes
    }

    /// A settings file this snapshot looked for: one of the home folder's own, or one inside a registered project folder.
    private static func isSettingsCandidate(_ path: String, scopes: [String]) -> Bool {
        if let home = scopes.first, path == home + "/.claude/settings.json" || path == home + "/.claude/settings.local.json" { return true }
        return scopes.dropFirst().contains { path.hasPrefix($0.hasSuffix("/") ? $0 : $0 + "/") }
    }

    // MARK: - Storage

    static var defaultURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory() + "/Library/Application Support")
        return support.appendingPathComponent("RoamSwitch/agent_setup_baseline.json")
    }

    static func load(from url: URL = defaultURL) -> Store? {
        guard let data = try? Data(contentsOf: url),
              let store = try? StrictJSON.decode(Store.self, from: data), store.version == 1 else { return nil }
        return store
    }

    /// Records `snapshot` as the accepted state. Atomic, owner-only.
    @discardableResult
    static func accept(_ snapshot: Snapshot, to url: URL = defaultURL, now: Date = Date()) throws -> Store {
        let store = Store(acceptedAt: isoString(now), snapshot: snapshot)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(store)
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        // Created owner-only from the start (no window where it is world-readable), then swapped in.
        let temporary = directory.appendingPathComponent(".agent_setup_baseline.\(UUID().uuidString).tmp")
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

    static func isoString(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    /// `2026-10-18` out of `2026-10-18T09:30:00Z`.
    static func day(of acceptedAt: String) -> String { String(acceptedAt.prefix(10)) }
}
