// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.12.8 (build 170).
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

        var isEmpty: Bool { files.isEmpty && servers.isEmpty }
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
    }

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
        return changes
    }

    // MARK: - Storage

    static var defaultURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory() + "/Library/Application Support")
        return support.appendingPathComponent("RoamSwitch/agent_setup_baseline.json")
    }

    static func load(from url: URL = defaultURL) -> Store? {
        guard let data = try? Data(contentsOf: url),
              let store = try? JSONDecoder().decode(Store.self, from: data), store.version == 1 else { return nil }
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
