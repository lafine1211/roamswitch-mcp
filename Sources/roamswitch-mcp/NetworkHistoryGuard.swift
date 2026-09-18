// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.34 (build 91).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Cross-session network identity learning.
///
/// `ARPSpoofMonitor` only ever looks at the *current* session — it has no
/// memory of networks visited before. That misses two things:
///
/// 1. Reconnecting to a previously-seen SSID from a gateway MAC never seen
///    paired with that name before (router replaced, or something answering
///    for it that wasn't there last time).
/// 2. A brand-new SSID whose name is suspiciously close to one already known
///    — an Evil-Twin AP impersonating a trusted network's *name* at a
///    different physical location (so the gateway MAC and any single-session
///    check never overlap at all).
///
/// Kept deliberately low-precision-risk: (1) is recorded but never alerts on
/// its own (a replaced router is common and not a security event), and (2)
/// only fires on a name that's genuinely close, not merely reused (default
/// router SSIDs like "ASUS" or "TP-Link_5G" collide across unrelated
/// locations constantly and must never trigger this). Mirrors the Linux
/// daemon's `network_history.rs`.
public enum NetworkTrustSignal: Equatable {
    /// This exact (SSID, gateway MAC) pair has been seen before.
    case familiar
    /// Never seen this SSID before, and it isn't suspiciously close to one
    /// that has been.
    case newNetwork
    /// This SSID is known, but not paired with this gateway MAC before.
    case newGatewayForKnownSSID(previousMACs: [String])
    /// This SSID has never been seen, but its name is a near-miss for one
    /// that has — and the gateway answering for it isn't infrastructure
    /// already associated with that known network either.
    case suspiciousSimilarSSID(similarTo: String, distance: Int)
}

final class NetworkHistoryGuard {
    static let shared = NetworkHistoryGuard()

    private struct SSIDRecord: Codable {
        var gatewayMACs: [String]
        var lastSeen: Date
    }

    /// Bound on distinct SSIDs remembered, so the file can't grow without
    /// limit for a laptop that roams through hundreds of networks over its
    /// lifetime.
    private static let maxEntries = 200
    /// Bound on gateway MACs remembered per SSID (mesh networks / multi-AP
    /// sites legitimately present several).
    private static let maxMACsPerSSID = 8

    private var entries: [String: SSIDRecord] = [:]
    private let storeURL: URL?
    private let queue = DispatchQueue(label: "com.tetsuharu.RoamSwitch.NetworkHistoryGuard")

    private init() {
        storeURL = Self.defaultStoreURL()
        load()
    }

    private static func defaultStoreURL() -> URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("RoamSwitch", isDirectory: true)
            .appendingPathComponent("network_history.json")
    }

    // MARK: - Read-only snapshot (RoamSwitchMCPServer `get_network_history`)

    /// One remembered network. Deliberately carries only a *count* of gateway
    /// MACs, never the MACs themselves.
    struct HistorySnapshotEntry: Equatable {
        let ssid: String
        let gatewayCount: Int
        let lastSeen: Date
    }

    /// Two remembered SSIDs whose names are a suspicious near-miss of each
    /// other (same `NetworkSSIDSimilarity` rule `observe` alerts on) while no
    /// gateway MAC was ever shared between them — i.e. a past Evil-Twin
    /// candidate, not a guest network on the same router.
    struct LookalikePair: Equatable {
        let ssid: String
        let similarTo: String
        let distance: Int
    }

    /// Decodes the history file directly, without touching `shared` (whose
    /// `observe` writes). Missing/corrupt file → empty snapshot.
    static func readSnapshot(from url: URL? = nil) -> (entries: [HistorySnapshotEntry], lookalikes: [LookalikePair]) {
        guard let fileURL = url ?? defaultStoreURL(),
              let data = try? Data(contentsOf: fileURL),
              let records = try? JSONDecoder().decode([String: SSIDRecord].self, from: data) else {
            return ([], [])
        }

        var entries: [HistorySnapshotEntry] = []
        for (ssid, record) in records {
            entries.append(HistorySnapshotEntry(ssid: ssid, gatewayCount: record.gatewayMACs.count, lastSeen: record.lastSeen))
        }
        entries.sort { $0.lastSeen > $1.lastSeen }

        var lookalikes: [LookalikePair] = []
        let ssids = records.keys.sorted()
        for i in 0..<ssids.count {
            for j in (i + 1)..<ssids.count {
                let a = ssids[i]
                let b = ssids[j]
                guard let recordA = records[a], let recordB = records[b] else { continue }
                let sharesGateway = recordA.gatewayMACs.contains { macA in
                    recordB.gatewayMACs.contains { $0.caseInsensitiveCompare(macA) == .orderedSame }
                }
                if sharesGateway { continue }
                if let distance = NetworkSSIDSimilarity.suspiciousDistance(a, b) {
                    lookalikes.append(LookalikePair(ssid: a, similarTo: b, distance: distance))
                }
            }
        }
        return (entries, lookalikes)
    }

    /// Evaluates `(ssid, gatewayMAC)` against the recorded history, then
    /// records the observation. Call once per confirmed network switch, not
    /// on every diagnostics tick.
    func observe(ssid: String, gatewayMAC: String) -> NetworkTrustSignal {
        queue.sync {
            let signal = Self.evaluate(entries: entries, ssid: ssid, gatewayMAC: gatewayMAC)

            var record = entries[ssid] ?? SSIDRecord(gatewayMACs: [], lastSeen: Date())
            if !record.gatewayMACs.contains(where: { $0.caseInsensitiveCompare(gatewayMAC) == .orderedSame }) {
                record.gatewayMACs.append(gatewayMAC)
                if record.gatewayMACs.count > Self.maxMACsPerSSID {
                    record.gatewayMACs.removeFirst()
                }
            }
            record.lastSeen = Date()
            entries[ssid] = record

            evictOldestIfOverCapacity()
            save()
            return signal
        }
    }

    private func evictOldestIfOverCapacity() {
        guard entries.count > Self.maxEntries else { return }
        let byAge = entries.sorted { $0.value.lastSeen < $1.value.lastSeen }
        let excess = entries.count - Self.maxEntries
        for (key, _) in byAge.prefix(excess) {
            entries.removeValue(forKey: key)
        }
    }

    private static func evaluate(entries: [String: SSIDRecord], ssid: String, gatewayMAC: String) -> NetworkTrustSignal {
        if let record = entries[ssid] {
            if record.gatewayMACs.contains(where: { $0.caseInsensitiveCompare(gatewayMAC) == .orderedSame }) {
                return .familiar
            }
            return .newGatewayForKnownSSID(previousMACs: record.gatewayMACs)
        }

        for (knownSSID, record) in entries {
            // Same infrastructure broadcasting a second SSID (guest network,
            // renamed router) isn't an impersonation signal.
            if record.gatewayMACs.contains(where: { $0.caseInsensitiveCompare(gatewayMAC) == .orderedSame }) {
                continue
            }
            if let distance = NetworkSSIDSimilarity.suspiciousDistance(ssid, knownSSID) {
                return .suspiciousSimilarSSID(similarTo: knownSSID, distance: distance)
            }
        }

        return .newNetwork
    }

    // MARK: - Persistence

    private func load() {
        guard let storeURL, let data = try? Data(contentsOf: storeURL) else { return }
        entries = (try? JSONDecoder().decode([String: SSIDRecord].self, from: data)) ?? [:]
    }

    private func save() {
        guard let storeURL else { return }
        try? FileManager.default.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }
}

enum NetworkSSIDSimilarity {
    /// Levenshtein edit distance between two strings (char-wise).
    static func levenshtein(_ a: String, _ b: String) -> Int {
        let a = Array(a)
        let b = Array(b)
        let (n, m) = (a.count, b.count)
        if n == 0 { return m }
        if m == 0 { return n }
        var prev = Array(0...m)
        var cur = [Int](repeating: 0, count: m + 1)
        for i in 1...n {
            cur[0] = i
            for j in 1...m {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                cur[j] = Swift.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost)
            }
            swap(&prev, &cur)
        }
        return prev[m]
    }

    /// Non-nil when `a` and `b` are different but close enough to read as an
    /// impersonation attempt of one another rather than an unrelated name
    /// that happens to collide (generic default-router SSIDs like "ASUS" or
    /// "NETGEAR" must never trigger this). Deliberately conservative: short
    /// names are exempted entirely, and the allowed distance grows slowly
    /// with length.
    static func suspiciousDistance(_ a: String, _ b: String) -> Int? {
        let na = normalize(a)
        let nb = normalize(b)
        guard na != nb, !na.isEmpty, !nb.isEmpty else { return nil }
        let longer = Swift.max(na.count, nb.count)
        guard longer >= 6 else { return nil }
        let distance = levenshtein(na, nb)
        let threshold = Swift.min(Swift.max(longer / 8, 1), 2)
        return (distance >= 1 && distance <= threshold) ? distance : nil
    }

    private static func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
