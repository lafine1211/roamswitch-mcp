// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.34 (build 213).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// The apps the macOS application firewall has been told to let in (System Settings > Network > Firewall > Options, or
/// `socketfilterfw --add`), as `socketfilterfw --listapps` prints them.
///
/// RoamSwitch's "標準保護" and "ロックダウン" turn on "block all incoming connections". An app on this list is still
/// let in under that setting: measured on 2026-11-02, Docker Desktop (`/Applications/Docker.app`, "Allow incoming
/// connections") published ports 3000 and 8000 on `0.0.0.0` and a Sensor on the same LAN reached both while the menu
/// said "ファイアウォールにより外部遮断中". The menu and the port audit use this to tell such a listener from one the
/// firewall really holds back.
enum FirewallAllowList {
    struct Entry: Equatable {
        let path: String
        let allowsIncoming: Bool
    }

    /// Parses the output of `socketfilterfw --listapps`:
    /// ```
    /// Total number of apps = 34
    /// 1 : /Applications/Docker.app
    ///              (Allow incoming connections)
    /// 2 : /Applications/Some Tool.app
    ///              (Block incoming connections)
    /// ```
    /// A path can contain spaces. An entry without a recognisable state line is not counted as allowing.
    static func parse(_ text: String) -> [Entry] {
        var entries: [Entry] = []
        var pendingPath: String?
        for rawLine in text.components(separatedBy: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if let colon = line.range(of: " : "), Int(line[line.startIndex..<colon.lowerBound]) != nil {
                if let path = pendingPath { entries.append(Entry(path: path, allowsIncoming: false)) }
                pendingPath = String(line[colon.upperBound...]).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("("), let path = pendingPath {
                entries.append(Entry(path: path, allowsIncoming: line.lowercased().contains("allow incoming")))
                pendingPath = nil
            }
        }
        if let path = pendingPath { entries.append(Entry(path: path, allowsIncoming: false)) }
        return entries
    }

    /// Whether `executablePath` is inside an entry that allows incoming connections. An entry is an app bundle or a
    /// program; the match is on whole path components, so `/Applications/Docker.app` covers
    /// `/Applications/Docker.app/Contents/MacOS/com.docker.backend` and not `/Applications/Docker.app2/x`.
    static func allowsIncoming(executablePath: String?, entries: [Entry]) -> Bool {
        guard let executablePath, !executablePath.isEmpty else { return false }
        let target = (executablePath as NSString).standardizingPath
        return entries.contains { entry in
            guard entry.allowsIncoming else { return false }
            let base = (entry.path as NSString).standardizingPath
            return target == base || target.hasPrefix(base.hasSuffix("/") ? base : base + "/")
        }
    }

    static let socketfilterfw = "/usr/libexec/ApplicationFirewall/socketfilterfw"

    private static var cache: (at: Date, entries: [Entry])?
    private static let lock = NSLock()

    /// The current list, read with `socketfilterfw --listapps` (about 20 ms, no root needed) and kept for 30 seconds.
    /// Empty when the tool cannot be run: the caller then behaves as if there were no list.
    static func current(maxAge: TimeInterval = 30, runner: CommandRunner = SystemCommand.run) -> [Entry] {
        lock.lock(); defer { lock.unlock() }
        if let cache, Date().timeIntervalSince(cache.at) < maxAge { return cache.entries }
        guard let out = runner(socketfilterfw, ["--listapps"]), out.status == 0 else {
            return cache?.entries ?? []
        }
        let entries = parse(out.stdout)
        cache = (Date(), entries)
        return entries
    }

    static func allowsIncoming(executablePath: String?) -> Bool {
        allowsIncoming(executablePath: executablePath, entries: current())
    }
}
