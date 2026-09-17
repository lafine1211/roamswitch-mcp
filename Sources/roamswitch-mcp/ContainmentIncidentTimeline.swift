// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.32 (build 89).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Unified, cross-manager incident record — the macOS counterpart of Linux
/// RoamSwitch's `incident_timeline.rs`. `ARPSpoofContainmentManager`,
/// `RansomwareContainmentManager` (via `RansomwareCanaryGuard`),
/// `RuntimeThreatContainmentManager`, and `PortAnomalyGuard` each already
/// keep their own detection-specific record (or, in ARPSpoofContainmentManager's
/// case, none at all — only an `NSLog` line). This adds a lightweight,
/// additive layer on top: one chronological view across all four, so
/// reviewing "what happened recently" doesn't mean checking four different
/// places with four different schemas. It does not replace any existing
/// store.
public enum ContainmentIncidentSource: String, Codable {
    case arpSpoof
    case ransomwareCanary
    case runtimeThreat
    case portAnomaly
}

/// What a ransomware canary actually observed, as a stable identifier —
/// independent of the localized `summary` text recorded alongside it.
public enum RansomwareCanaryTrigger: String, Codable {
    case deletedOrRenamed
    case tampered
}

public enum ContainmentIncidentResolution: String, Codable {
    case released
    case autoTimeout
    case allowlisted
}

public struct ContainmentIncidentEvent: Identifiable, Codable, Equatable {
    public let id: UUID
    public let timestamp: Date
    public let source: ContainmentIncidentSource
    public let severity: String
    public let summary: String
    public let processName: String?
    public let processID: Int32?
    /// MITRE ATT&CK technique ID. Only ever set for mappings confident
    /// enough to name — see `attackTechnique(for:context:)`. A wrong tag
    /// actively misleads an incident review, which is worse than a missing
    /// one, so an unmapped case is `nil`, never a guess.
    public let attackTechnique: String?
    public let actionTaken: String
    public var resolvedAt: Date?
    public var resolution: ContainmentIncidentResolution?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        source: ContainmentIncidentSource,
        severity: String,
        summary: String,
        processName: String? = nil,
        processID: Int32? = nil,
        attackTechnique: String? = nil,
        actionTaken: String,
        resolvedAt: Date? = nil,
        resolution: ContainmentIncidentResolution? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.severity = severity
        self.summary = summary
        self.processName = processName
        self.processID = processID
        self.attackTechnique = attackTechnique
        self.actionTaken = actionTaken
        self.resolvedAt = resolvedAt
        self.resolution = resolution
    }
}

public enum ContainmentIncidentTimeline {
    /// Capped higher than any individual guard's own cap (50) since this
    /// aggregates four sources into one list.
    private static let maxEntries = 200

    /// Pure path computation — no side effects, so the read-only
    /// `RoamSwitchMCPServer` (`get_incident_timeline`) can resolve it
    /// without creating directories. Only `saveAll` creates the directory.
    private static var storeURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RoamSwitch", isDirectory: true)
            .appendingPathComponent("containment_incident_timeline.json")
    }

    private static let queue = DispatchQueue(label: "com.tetsuharu.RoamSwitch.ContainmentIncidentTimeline")

    private static func loadAll() -> [ContainmentIncidentEvent] {
        guard let data = try? Data(contentsOf: storeURL) else { return [] }
        return (try? JSONDecoder().decode([ContainmentIncidentEvent].self, from: data)) ?? []
    }

    private static func saveAll(_ events: [ContainmentIncidentEvent]) {
        guard let data = try? JSONEncoder().encode(events) else { return }
        let url = storeURL
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    /// Records a new incident and returns its id, so the caller can later
    /// resolve this exact entry rather than "whatever is latest" if it
    /// tracks the id itself (most callers use `resolveLatest` instead,
    /// since the existing per-manager code doesn't thread an id through).
    @discardableResult
    public static func record(
        source: ContainmentIncidentSource,
        severity: String,
        summary: String,
        processName: String? = nil,
        processID: Int32? = nil,
        attackTechnique: String? = nil,
        actionTaken: String
    ) -> UUID {
        let event = ContainmentIncidentEvent(
            source: source,
            severity: severity,
            summary: summary,
            processName: processName,
            processID: processID,
            attackTechnique: attackTechnique ?? Self.attackTechnique(for: source, context: summary),
            actionTaken: actionTaken
        )
        queue.sync {
            var events = loadAll()
            events.insert(event, at: 0)
            if events.count > maxEntries {
                events.removeLast(events.count - maxEntries)
            }
            saveAll(events)
        }
        return event.id
    }

    /// Marks the most recent unresolved event from `source` (optionally
    /// narrowed to a specific `processID`) as resolved. No-op if nothing
    /// matches — mirrors Linux's `resolve_latest`, which is likewise
    /// best-effort since the resolving code path (a release/allow action)
    /// must never fail just because the forensic record couldn't be
    /// updated.
    public static func resolveLatest(
        source: ContainmentIncidentSource,
        processID: Int32? = nil,
        resolution: ContainmentIncidentResolution
    ) {
        queue.sync {
            var events = loadAll()
            guard let idx = events.firstIndex(where: {
                $0.source == source && $0.resolvedAt == nil && (processID == nil || $0.processID == processID)
            }) else { return }
            events[idx].resolvedAt = Date()
            events[idx].resolution = resolution
            saveAll(events)
        }
    }

    public static func loadRecent(limit: Int = 50) -> [ContainmentIncidentEvent] {
        queue.sync { Array(loadAll().prefix(limit)) }
    }

    /// Language-independent ATT&CK mapping for a ransomware canary trigger.
    /// `RansomwareCanaryGuard` passes this explicitly to `record`, so the tag
    /// no longer depends on the (localized) summary text — the old
    /// `context.contains("削除"/"delete"/"暗号化"/"encrypt")` heuristic below
    /// silently fell through to T1565 in every other UI language.
    public static func attackTechnique(forRansomwareTrigger trigger: RansomwareCanaryTrigger) -> String {
        switch trigger {
        case .deletedOrRenamed: return "T1485" // Data Destruction
        case .tampered: return "T1486"         // Data Encrypted for Impact
        }
    }

    /// Confident, hand-verified mappings only — see the doc comment on
    /// `attackTechnique` above. The `.ransomwareCanary` string matching is a
    /// legacy fallback only, for callers that don't pass an explicit
    /// technique (current code always does, via
    /// `attackTechnique(forRansomwareTrigger:)`); entries already persisted
    /// keep whatever technique was stored when they were recorded.
    /// Extended deliberately, one verified case at
    /// a time, mirroring `incident_timeline.rs`'s `attack_technique_for` on
    /// the Linux side.
    static func attackTechnique(for source: ContainmentIncidentSource, context: String) -> String? {
        switch source {
        case .arpSpoof:
            return "T1557" // Adversary-in-the-Middle
        case .ransomwareCanary:
            if context.contains("削除") || context.contains("delete") || context.contains("rename") || context.contains("リネーム") {
                return "T1485" // Data Destruction
            }
            if context.contains("暗号化") || context.contains("encrypt") {
                return "T1486" // Data Encrypted for Impact
            }
            return "T1565" // Data Manipulation
        case .runtimeThreat, .portAnomaly:
            // XProtect/Gatekeeper/port-anomaly summaries don't carry a
            // Falco-style rule name to pattern-match on macOS, so this
            // stays unmapped rather than guessing.
            return nil
        }
    }
}
