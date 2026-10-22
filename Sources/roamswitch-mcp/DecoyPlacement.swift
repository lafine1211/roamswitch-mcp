// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.0 (build 179).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// How many decoy credential files the honeytoken guard really put in place, and why the others were left out.
///
/// The check mark of a decoy guard used to appear whether or not a single decoy existed: a path that already holds
/// a real file is left alone (never overwritten, never watched), and a path that cannot be written is skipped.
/// With every path taken the guard watched nothing. This record is written by the guard after each placement and
/// read by the menu and the MCP tool (a separate process), so it has no dependency on the app. A guard with a
/// switch on and `placed == 0` is not working.
struct DecoyPlacementRecord: Codable, Equatable {
    /// Decoys in place and watched.
    var placed: Int
    /// Decoys the guard would place (the number of candidate paths).
    var expected: Int
    /// Paths that already hold a file that is not ours (or one we no longer recognise): left alone.
    var realFilesKept: Int
    /// Paths that are a symbolic link or a special file: left alone.
    var specialSkipped: Int
    /// Paths where the write failed (no permission to the folder, disk).
    var writeFailed: Int
    /// Unix seconds.
    var at: Double

    var noneWerePlaced: Bool { expected > 0 && placed == 0 }

    /// Why none (or not all) were placed, in one sentence; nil when everything was placed.
    func shortfallText() -> String? {
        guard placed < expected else { return nil }
        var parts: [String] = []
        if realFilesKept > 0 { parts.append(String(format: loc("本物のファイルが既にある: %d件"), realFilesKept)) }
        if specialSkipped > 0 { parts.append(String(format: loc("シンボリックリンクなどで置けない: %d件"), specialSkipped)) }
        if writeFailed > 0 { parts.append(String(format: loc("書き込めなかった: %d件"), writeFailed)) }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: loc("、"))
    }

    /// The count shown next to the guard's name in the menu.
    func countSuffix() -> String {
        String(format: loc("設置 %1$d/%2$d"), placed, expected)
    }

    /// The sentence for the tooltip: the count, and the reason when some are missing.
    func tooltip() -> String {
        var text = String(format: loc("おとりを %1$d 個中 %2$d 個、実際に置けています。"), expected, placed)
        if let why = shortfallText() { text += " " + String(format: loc("置けなかった理由: %@。"), why) }
        if noneWerePlaced { text += " " + loc("1つも置けていないため、このままでは何も検知できません。") }
        return text
    }
}

enum CanaryGuardPlacement {
    /// The canary guard's bait files that exist on disk, as a placement record. A file that is missing was not
    /// written (no permission to the folder) or has been deleted; either way it is not in place.
    static func record(isEnabled: Bool, placed: Int, expected: Int, now: Date = Date()) -> DecoyPlacementRecord? {
        guard isEnabled, expected > 0 else { return nil }
        return DecoyPlacementRecord(placed: placed, expected: expected, realFilesKept: 0, specialSkipped: 0,
                                    writeFailed: max(0, expected - placed), at: now.timeIntervalSince1970)
    }
}

enum DecoyPlacementStore {
    static let honeytokenKey = "RoamSwitch.HoneytokenPlacementV1"

    static func write(_ record: DecoyPlacementRecord, key: String, defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(record) { defaults.set(data, forKey: key) }
    }

    static func read(key: String, defaults: UserDefaults) -> DecoyPlacementRecord? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(DecoyPlacementRecord.self, from: data)
    }
}
