// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.15.1 (build 175).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Backup recency (audit check `backup_recency`): is there a backup destination, and was it written to
/// recently? The macOS counterpart of the Linux client's `backup_recency` check.
///
/// Time Machine records, per destination, the dates of its snapshots in its preferences domain
/// (`Destinations[].SnapshotDates`). `defaults export` reads that without root or Full Disk Access, unlike
/// `tmutil latestbackup`, which tries to mount the destination and fails when the disk is not attached.
///
/// This reads a record. It does not restore anything, so it says nothing about whether a backup can
/// really be restored: a restore writes the user's files and is not automated. Every shape this does not
/// recognise ends in `.unreadable` (not measured), never in a pass.
enum BackupRecency {

    /// A backup older than this many days fails the check.
    static let staleAfterDays = 7

    static let preferencesDomain = "/Library/Preferences/com.apple.TimeMachine"

    /// Backup apps recognised by their install path only. RoamSwitch cannot read when they last ran, so
    /// finding one never passes the check; it only changes what is reported.
    static let otherBackupApps: [(name: String, path: String)] = [
        ("Arq", "/Applications/Arq.app"),
        ("Carbon Copy Cloner", "/Applications/Carbon Copy Cloner.app"),
        ("SuperDuper!", "/Applications/SuperDuper!.app"),
        ("ChronoSync", "/Applications/ChronoSync.app"),
        ("Backblaze", "/Library/Backblaze.bzpkg"),
    ]

    enum Outcome: Equatable {
        /// The newest recorded backup is at most `staleAfterDays` old.
        case recent(days: Int)
        case stale(days: Int)
        /// A destination exists and the record lists no backup at all.
        case neverBackedUp
        /// No destination. `localSnapshots`: APFS local snapshots exist, which sit on the same disk.
        case notConfigured(localSnapshots: Bool)
        /// No Time Machine destination, but another backup app is installed.
        case otherToolOnly(names: [String])
        case unreadable
    }

    /// Pure: `preferences` is the decoded plist (nil = unreadable), `installedApps` the names found.
    static func evaluate(preferences: [String: Any]?, localSnapshotCount: Int?, installedApps: [String], now: Date) -> Outcome {
        guard let preferences else { return .unreadable }
        guard let destinations = preferences["Destinations"] as? [[String: Any]], !destinations.isEmpty else {
            // `Destinations` missing or empty on a readable file with a known version = nothing configured.
            // A file without `PreferencesVersion` is not one this understands.
            guard preferences["PreferencesVersion"] != nil else { return .unreadable }
            if !installedApps.isEmpty { return .otherToolOnly(names: installedApps) }
            return .notConfigured(localSnapshots: (localSnapshotCount ?? 0) > 0)
        }
        var newest: Date?
        var sawList = false
        for destination in destinations {
            guard let raw = destination["SnapshotDates"] as? [Any] else { continue }
            sawList = true
            for entry in raw {
                if let date = parseDate(entry), newest == nil || date > newest! { newest = date }
            }
        }
        // A destination without any `SnapshotDates` key: this macOS may record it elsewhere. Not a failure.
        guard sawList else { return .unreadable }
        guard let newest else { return .neverBackedUp }
        let seconds = max(0, now.timeIntervalSince(newest))
        let days = Int(seconds / 86_400)
        return days > staleAfterDays ? .stale(days: days) : .recent(days: days)
    }

    private static func parseDate(_ value: Any) -> Date? {
        if let date = value as? Date { return date }
        if let text = value as? String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            return formatter.date(from: text)
        }
        return nil
    }

    /// The XML plist `defaults export <domain> -` prints. nil when it is not a dictionary.
    static func decodePreferences(_ xml: String) -> [String: Any]? {
        guard let data = xml.data(using: .utf8), !data.isEmpty else { return nil }
        return (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? [String: Any]
    }

    /// Lines of `tmutil listlocalsnapshotdates` that look like a snapshot date (`2026-10-19-132809`).
    static func localSnapshotCount(_ output: CommandOutput) -> Int? {
        guard output.status == 0 else { return nil }
        return output.stdout.split(whereSeparator: \.isNewline).filter { line in
            let t = line.trimmingCharacters(in: .whitespaces)
            return t.count == 17 && t.first?.isNumber == true && t.filter({ $0 == "-" }).count == 3
        }.count
    }
}

/// Where the plist and the installed apps come from (replaced in tests).
protocol BackupSource {
    func timeMachinePreferences() -> [String: Any]?
    func installedBackupApps() -> [String]
}

struct SystemBackupSource: BackupSource {
    /// `defaults export` goes through cfprefsd, so it works without Full Disk Access. Opening the plist file
    /// directly fails with "Operation not permitted" for an ordinary process (verified on macOS 27).
    func timeMachinePreferences() -> [String: Any]? {
        guard let out = SystemCommand.run("/usr/bin/defaults", ["export", BackupRecency.preferencesDomain, "-"]), out.status == 0 else { return nil }
        return BackupRecency.decodePreferences(out.stdout)
    }

    func installedBackupApps() -> [String] {
        BackupRecency.otherBackupApps
            .filter { FileManager.default.fileExists(atPath: $0.path) }
            .map { $0.name }
    }
}
