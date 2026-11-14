// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.0.2 (build 218).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// The pre-roll of packet headers (`incidentPrerollEnabled`, off by default).
///
/// A packet capture that starts after a detection cannot see what led to it: `tcpdump` needs a moment to start (about
/// 130 to 160 ms measured on Linux), and by then the process has been contained. Seeing the traffic before the
/// detection needs a capture that is already running. That writes network traffic to disk, so it is kept as small
/// as it can be and says so:
///
///  - the ring holds the first `snapLength` bytes of each packet: the headers and, when the headers are short, the
///    first bytes of what was sent (a TCP segment without options leaves about 40 of 96 bytes to it). Only root can read it;
///  - a root-only folder, mode 0700, files 0600;
///  - only the last `seconds` (plus a margin) and at most `maxTotalBytes` in all, older files are deleted;
///  - nothing leaves that folder until a detection saves an evidence bundle, which gets the last `seconds` of it with
///    every packet cut at the end of its headers (`PacketPrerollTrim`): no payload goes into a bundle.
///
/// This file holds the rules, free of the helper, the files and the clock, so they can be tested.
public enum PacketPrerollPolicy {
    /// The app's `UserDefaults` keys (the MCP server reads the first to say whether the person switched it on).
    public static let enabledDefaultsKey = "RoamSwitch.IncidentPrerollEnabled"
    public static let secondsDefaultsKey = "RoamSwitch.IncidentPrerollSeconds"
    public static let defaultSeconds = 30
    public static let secondsRange = 10...120
    /// Bytes `tcpdump` keeps of each packet (`-s`): link 16, IPv6 40 and TCP with options 40 fit. That is the headers and, when
    /// they are short, a little of the payload, which is why a bundle does not take the file as it is.
    public static let snapLength = 96
    /// A new file every this many seconds (`tcpdump -G`).
    public static let rotateSeconds = 5
    /// A new file when one reaches this size in MiB (`tcpdump -C`).
    public static let maxFileMiB = 16
    /// The most the folder holds, and the most one bundle takes.
    public static let maxTotalBytes: Int64 = 128 * 1024 * 1024
    public static let filePrefix = "ring-"

    /// `seconds` brought into `secondsRange`.
    public static func clamp(seconds: Int) -> Int {
        min(max(seconds, secondsRange.lowerBound), secondsRange.upperBound)
    }

    /// How long a file is kept: the window and two rotations, so the file that was being written when the window
    /// began is still there.
    public static func retentionSeconds(seconds: Int) -> Int {
        clamp(seconds: seconds) + 2 * rotateSeconds
    }

    public static func isRingFile(_ name: String) -> Bool {
        name.hasPrefix(filePrefix) && !name.contains("/") && name != filePrefix
    }

    public struct FileInfo: Equatable {
        public let name: String
        public let size: Int64
        /// The last write (a file is still written to until the next one is started).
        public let modified: Date
        public init(name: String, size: Int64, modified: Date) {
            self.name = name
            self.size = size
            self.modified = modified
        }
    }

    /// The files to delete from the folder: those whose last write is older than the retention, and then, oldest
    /// first, as many more as it takes to get under `maxTotalBytes`. The newest file is never deleted (it is the one
    /// being written).
    public static func filesToPrune(_ files: [FileInfo], now: Date, seconds: Int, maxTotalBytes: Int64 = PacketPrerollPolicy.maxTotalBytes) -> [String] {
        let ring = files.filter { isRingFile($0.name) }.sorted { ($0.modified, $0.name) < ($1.modified, $1.name) }
        guard let newest = ring.last else { return [] }
        let cutoff = now.addingTimeInterval(-TimeInterval(retentionSeconds(seconds: seconds)))
        var doomed = ring.filter { $0.modified < cutoff && $0.name != newest.name }.map(\.name)
        var kept = ring.filter { !doomed.contains($0.name) }
        var total = kept.reduce(Int64(0)) { $0 + $1.size }
        while total > maxTotalBytes, kept.count > 1 {
            let oldest = kept.removeFirst()
            total -= oldest.size
            doomed.append(oldest.name)
        }
        return doomed
    }

    public struct Selection: Equatable {
        /// Oldest first.
        public let files: [FileInfo]
        /// Files that were in the window but left out because the bundle takes at most `maxTotalBytes` (the oldest go first).
        public let droppedCount: Int
        public let droppedBytes: Int64
    }

    /// The files an evidence bundle takes: those written to at or after the start of the window (`now - seconds`),
    /// less the oldest ones when together they pass `maxTotalBytes`. A file last written before the window began holds
    /// nothing of it.
    public static func selectForBundle(_ files: [FileInfo], now: Date, seconds: Int, maxTotalBytes: Int64 = PacketPrerollPolicy.maxTotalBytes) -> Selection {
        let start = now.addingTimeInterval(-TimeInterval(clamp(seconds: seconds)))
        var inWindow = files.filter { isRingFile($0.name) && $0.modified >= start }
            .sorted { ($0.modified, $0.name) < ($1.modified, $1.name) }
        var droppedCount = 0
        var droppedBytes: Int64 = 0
        var total = inWindow.reduce(Int64(0)) { $0 + $1.size }
        while total > maxTotalBytes, inWindow.count > 1 {
            let oldest = inWindow.removeFirst()
            total -= oldest.size
            droppedCount += 1
            droppedBytes += oldest.size
        }
        return Selection(files: inWindow, droppedCount: droppedCount, droppedBytes: droppedBytes)
    }

    /// Whether the helper may write a bundle's pre-roll into `path`: a folder inside one user's evidence folder
    /// (`/Users/<name>/Library/Application Support/RoamSwitch/incident-evidence/<bundle>/...`), written as root on the
    /// app's request, so nothing else is accepted (no `..`, no other place).
    public static func isEvidenceDestination(_ path: String) -> Bool {
        let parts = path.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        // "", "Users", name, "Library", "Application Support", "RoamSwitch", "incident-evidence", bundle, ...
        guard parts.count >= 8, parts[0].isEmpty, parts[1] == "Users", !parts[2].isEmpty,
              parts[3] == "Library", parts[4] == "Application Support", parts[5] == "RoamSwitch",
              parts[6] == "incident-evidence", !parts[7].isEmpty else { return false }
        return !parts.dropFirst().contains { $0.isEmpty || $0 == "." || $0 == ".." }
    }

    /// The `tcpdump` arguments of the ring in `directory` on `interface`.
    public static func tcpdumpArguments(interface: String, directory: String) -> [String] {
        [
            "-i", interface,
            "-n",
            "-U",                          // each packet is written at once, so a copy taken now is whole up to it
            "-s", String(snapLength),      // the headers and a little of the payload; the bundle's copy is cut to the headers
            "-G", String(rotateSeconds),
            "-C", String(maxFileMiB),
            "-w", directory + "/" + filePrefix + "%Y%m%dT%H%M%S.pcap",
        ]
    }
}

/// Why the ring is not running, as the helper reports it. The app says each in words (`reason` is one of these keys).
public enum PacketPrerollReason {
    public static let tcpdumpMissing = "tcpdump_missing"
    public static let noDefaultInterface = "no_default_interface"
    public static let launchFailed = "launch_failed"
    public static let tooManyRestarts = "too_many_restarts"
    public static let directoryUnusable = "directory_unusable"
}

/// What the helper says about the ring, as JSON over XPC.
public struct PacketPrerollStatus: Codable, Equatable {
    /// `off`, `running` or `unavailable` (on, but not capturing: `reason` says why).
    public var state: String
    public var reason: String?
    public var interface: String?
    public var seconds: Int
    public var fileCount: Int
    public var totalBytes: Int64

    public init(state: String, reason: String? = nil, interface: String? = nil, seconds: Int, fileCount: Int = 0, totalBytes: Int64 = 0) {
        self.state = state
        self.reason = reason
        self.interface = interface
        self.seconds = seconds
        self.fileCount = fileCount
        self.totalBytes = totalBytes
    }

    public static func off(seconds: Int = PacketPrerollPolicy.defaultSeconds) -> PacketPrerollStatus {
        PacketPrerollStatus(state: "off", seconds: seconds)
    }
}

/// The helper's answer to "put the last seconds into this bundle".
public struct PacketPrerollCopyResult: Codable, Equatable {
    public struct Entry: Codable, Equatable {
        public let name: String
        public let size: Int64
        public init(name: String, size: Int64) {
            self.name = name
            self.size = size
        }
    }
    public var files: [Entry]
    public var droppedCount: Int
    public var droppedBytes: Int64
    /// Files in the window that were left out because they are not pcap files (they are not copied as they are).
    public var refusedCount: Int
    /// Set when nothing was copied: `off`, `empty` (on, no file in the window), `not_pcap` (every file was refused),
    /// or a `PacketPrerollReason`.
    public var skippedReason: String?

    public init(files: [Entry] = [], droppedCount: Int = 0, droppedBytes: Int64 = 0, refusedCount: Int = 0, skippedReason: String? = nil) {
        self.files = files
        self.refusedCount = refusedCount
        self.droppedCount = droppedCount
        self.droppedBytes = droppedBytes
        self.skippedReason = skippedReason
    }
}
