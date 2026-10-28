// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.8 (build 187).
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
    /// `ClickFixGuard`'s command-history heuristic. Added additively:
    /// existing timeline files never contain it, so they decode unchanged.
    case clickFix
    /// `ExecRecorderManager`'s correlation-rule alerts (process-exec recorder,
    /// notify-only). Added additively like `.clickFix`: older timeline files
    /// never contain it, so they decode unchanged; a build that predates it
    /// simply never wrote such records.
    case execRecorder
    /// `RansomwareEntropyGuard`'s general (non-canary-file-dependent)
    /// mass-encryption detection. Added additively like `.execRecorder`:
    /// older timeline files never contain it.
    case ransomwareEntropy
    /// `CredentialHoneytokenGuard` detected real access to a planted decoy
    /// credential file. Always maps to T1552 (Unsecured Credentials).
    /// Added additively, same as the cases above.
    case honeytoken
    /// `BrowserCredentialWatchGuard` detected a non-browser process
    /// accessing a browser's saved-password/session-cookie store. Always
    /// maps to T1539 (Steal Web Session Cookie). Added additively, same as
    /// the cases above.
    case browserCredentialWatch
    /// `ReverseShellWatchGuard`: a shell or relay tool whose input and output are an outward TCP connection. Always T1059.004.
    /// Added additively, same as the cases above.
    case reverseShellWatch
    /// `NetworkSettingsWatchGuard`: DNS, router or proxy auto-config that differs from what the same network gave before. T1557.003 for
    /// DHCP-supplied DNS and router, T1557 for proxy auto-config. Added additively, same as the cases above.
    case networkSettingsWatch
    /// `SSHGuard` banned an SSH brute-force source, or a login succeeded after a run of failures. Always maps to
    /// T1110 (Brute Force). Added additively, same as the cases above.
    case sshGuard
    /// A package CVE finding's risk acceptance (`VulnerabilityAcceptance`) ran out. Never mapped to an ATT&CK
    /// technique: it is a housekeeping event, not an attack. Added additively, same as the cases above.
    case vulnerabilityAcceptance
    /// A person accepted the current state of the critical system files as the new `CriticalPathFimGuard` baseline
    /// (menu action). A record of that decision, never an attack: not mapped to an ATT&CK technique. Added additively,
    /// same as the cases above.
    case criticalPathFim
    /// `ForensicCaptureManager` saved an evidence bundle for another record's detection. An evidence-preserving action,
    /// not a detection: never mapped to an ATT&CK technique. It is recorded as a child of the detection it was saved
    /// for (`parentEventID`). Added additively, same as the cases above.
    case forensicCapture
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

/// Points from a timeline record to saved evidence: the bundle folder name (never a path), optionally one file in it and
/// that file's SHA-256. Nothing else is stored, so a reference cannot carry file content or a secret.
public struct ContainmentEvidenceRef: Codable, Equatable {
    public let bundle: String
    public let artifact: String?
    public let sha256: String?

    public init(bundle: String, artifact: String? = nil, sha256: String? = nil) {
        self.bundle = bundle
        self.artifact = artifact
        self.sha256 = sha256
    }

    /// The reference as it is stored: the bundle is its last path component, an artifact name is a relative path
    /// without `..`, a hash is kept only if it is 64 hex digits. `nil` when no usable bundle name is left.
    func sanitized() -> ContainmentEvidenceRef? {
        let bundle = (self.bundle as NSString).lastPathComponent.trimmingCharacters(in: .whitespaces)
        func plain(_ s: String) -> Bool { s.count <= 200 && !s.unicodeScalars.contains { CharacterSet.controlCharacters.contains($0) } }
        guard !bundle.isEmpty, bundle != ".", bundle != "..", plain(bundle) else { return nil }
        let artifact = self.artifact.map { $0.trimmingCharacters(in: .whitespaces) }.flatMap { a -> String? in
            guard !a.isEmpty, plain(a), !a.hasPrefix("/"), !a.split(separator: "/").contains("..") else { return nil }
            return a
        }
        let sha = self.sha256.map { $0.trimmingCharacters(in: .whitespaces).lowercased() }.flatMap { h -> String? in
            h.count == 64 && h.allSatisfy(\.isHexDigit) ? h : nil
        }
        return ContainmentEvidenceRef(bundle: bundle, artifact: artifact, sha256: sha)
    }
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
    /// The record that caused this one, set only by a writer that holds that record's id. `record` drops it when the
    /// parent is not in the timeline, when it would make a cycle, or when the chain would pass
    /// `ContainmentIncidentTimeline.maxChainDepth`.
    public var parentEventID: UUID?
    /// The first record of the chain this one belongs to. Set by `record`, never by the writer.
    public var rootEventID: UUID?
    /// Evidence saved for this record (at most `ContainmentIncidentTimeline.maxEvidenceRefs`).
    public var evidenceRefs: [ContainmentEvidenceRef]

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
        resolution: ContainmentIncidentResolution? = nil,
        parentEventID: UUID? = nil,
        rootEventID: UUID? = nil,
        evidenceRefs: [ContainmentEvidenceRef] = []
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
        self.parentEventID = parentEventID
        self.rootEventID = rootEventID
        self.evidenceRefs = evidenceRefs
    }

    // The three link fields are newer than the file format: a file written before them has none of the keys, and a
    // record without links is written without them, so an older build reads the file as before.
    private enum CodingKeys: String, CodingKey {
        case id, timestamp, source, severity, summary, processName, processID, attackTechnique, actionTaken
        case resolvedAt, resolution, parentEventID, rootEventID, evidenceRefs
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        timestamp = try c.decode(Date.self, forKey: .timestamp)
        source = try c.decode(ContainmentIncidentSource.self, forKey: .source)
        severity = try c.decode(String.self, forKey: .severity)
        summary = try c.decode(String.self, forKey: .summary)
        processName = try c.decodeIfPresent(String.self, forKey: .processName)
        processID = try c.decodeIfPresent(Int32.self, forKey: .processID)
        attackTechnique = try c.decodeIfPresent(String.self, forKey: .attackTechnique)
        actionTaken = try c.decode(String.self, forKey: .actionTaken)
        resolvedAt = try c.decodeIfPresent(Date.self, forKey: .resolvedAt)
        resolution = try c.decodeIfPresent(ContainmentIncidentResolution.self, forKey: .resolution)
        parentEventID = try c.decodeIfPresent(UUID.self, forKey: .parentEventID)
        rootEventID = try c.decodeIfPresent(UUID.self, forKey: .rootEventID)
        evidenceRefs = try c.decodeIfPresent([ContainmentEvidenceRef].self, forKey: .evidenceRefs) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(timestamp, forKey: .timestamp)
        try c.encode(source, forKey: .source)
        try c.encode(severity, forKey: .severity)
        try c.encode(summary, forKey: .summary)
        try c.encodeIfPresent(processName, forKey: .processName)
        try c.encodeIfPresent(processID, forKey: .processID)
        try c.encodeIfPresent(attackTechnique, forKey: .attackTechnique)
        try c.encode(actionTaken, forKey: .actionTaken)
        try c.encodeIfPresent(resolvedAt, forKey: .resolvedAt)
        try c.encodeIfPresent(resolution, forKey: .resolution)
        try c.encodeIfPresent(parentEventID, forKey: .parentEventID)
        try c.encodeIfPresent(rootEventID, forKey: .rootEventID)
        if !evidenceRefs.isEmpty { try c.encode(evidenceRefs, forKey: .evidenceRefs) }
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

    /// Evidence references kept on one record. More are dropped, not an error.
    public static let maxEvidenceRefs = 8
    /// A chain of cause links is never longer than this many records. A new record that would make it longer is
    /// recorded without a parent.
    public static let maxChainDepth = 16

    /// Checks the cause link of a new record against the records already stored and fills `rootEventID`. A link that
    /// cannot be trusted is dropped and the record is still stored; nothing here can fail. Pure, for tests.
    static func resolveLinks(_ event: inout ContainmentIncidentEvent, existing: [ContainmentIncidentEvent]) {
        event.rootEventID = nil
        event.evidenceRefs = Array(event.evidenceRefs.compactMap { $0.sanitized() }.prefix(maxEvidenceRefs))
        guard let parentID = event.parentEventID else { return }
        func drop() { event.parentEventID = nil; event.rootEventID = nil }
        func find(_ id: UUID?) -> ContainmentIncidentEvent? { id.flatMap { id in existing.first { $0.id == id } } }
        guard parentID != event.id, var current = find(parentID) else { return drop() }
        // Walk up from the parent. Meeting the new record's own id is a cycle; a walk past the cap, or one that
        // loops among older records, is refused as well.
        var seen = Set<UUID>()
        var depth = 1
        while true {
            if current.id == event.id || !seen.insert(current.id).inserted { return drop() }
            guard let next = find(current.parentEventID) else { break }
            depth += 1
            if depth >= maxChainDepth { return drop() }
            current = next
        }
        event.rootEventID = current.id
    }

    /// Called with every record after it was stored. The app sets it to hand the event to the opt-in
    /// forwarder (`EventForwarder`); it stays `nil` in the targets that only read this file's data.
    public static var recordObserver: ((ContainmentIncidentEvent) -> Void)?

    /// What reading the timeline file found. A file that is damaged or cannot be read used to look the same as a file
    /// that has no incidents, and the next record wrote over it (audit D-L1).
    public enum FileState: Equatable {
        /// There is no file yet: no incident was ever recorded.
        case missing
        case ok
        /// The file exists but is not a readable timeline (damaged, or no permission).
        case unreadable
    }

    /// Pure: the events in the file's bytes, and what state the file is in. `data == nil` means the file is not there
    /// (`fileExists` false) or could not be read (true).
    static func parse(_ data: Data?, fileExists: Bool) -> (events: [ContainmentIncidentEvent], state: FileState) {
        guard let data else { return ([], fileExists ? .unreadable : .missing) }
        guard let events = try? JSONDecoder().decode([ContainmentIncidentEvent].self, from: data) else { return ([], .unreadable) }
        return (events, .ok)
    }

    private static func loadAllWithState() -> (events: [ContainmentIncidentEvent], state: FileState) {
        let url = storeURL
        return parse(try? Data(contentsOf: url), fileExists: FileManager.default.fileExists(atPath: url.path))
    }

    private static func loadAll() -> [ContainmentIncidentEvent] {
        loadAllWithState().events
    }

    /// Where a damaged file is kept before the next record replaces it.
    static func backupURL(for url: URL, existing: (URL) -> Bool, now: Date = Date()) -> URL {
        let plain = url.appendingPathExtension("bak")
        guard existing(plain) else { return plain }
        return url.appendingPathExtension("bak.\(Int(now.timeIntervalSince1970))")
    }

    /// Persisted so the activity log and the MCP tool can say that the record was damaged and set aside.
    public static let damagedAtKey = "RoamSwitch.IncidentTimeline.DamagedAt"
    public static let damagedBackupKey = "RoamSwitch.IncidentTimeline.DamagedBackup"

    /// The file state now, for the windows and the MCP tool.
    public static func fileState() -> FileState { queue.sync { loadAllWithState().state } }

    /// A damaged file is renamed to `.bak` (never overwritten, never deleted) before anything new is written.
    private static func setAsideIfDamaged(defaults: UserDefaults? = nil) {
        // The app's domain: the activity log reads the mark there, whichever process set the file aside (the MCP server records too).
        let defaults = defaults ?? AppLanguage.sharedDefaults
        let url = storeURL
        let (_, state) = loadAllWithState()
        guard state == .unreadable else { return }
        let target = backupURL(for: url, existing: { FileManager.default.fileExists(atPath: $0.path) })
        do {
            try FileManager.default.moveItem(at: url, to: target)
            defaults.set(Date(), forKey: damagedAtKey)
            defaults.set(target.lastPathComponent, forKey: damagedBackupKey)
            NSLog("RoamSwitch ContainmentIncidentTimeline: the record could not be read; set aside as \(target.lastPathComponent)")
        } catch {
            NSLog("RoamSwitch ContainmentIncidentTimeline: the record could not be read and could not be set aside: \(error)")
        }
    }

    private static func saveAll(_ events: [ContainmentIncidentEvent]) {
        guard let data = try? JSONEncoder().encode(events) else { return }
        let url = storeURL
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        setAsideIfDamaged()
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
        actionTaken: String,
        parentEventID: UUID? = nil,
        evidenceRefs: [ContainmentEvidenceRef] = []
    ) -> UUID {
        var event = ContainmentIncidentEvent(
            source: source,
            severity: severity,
            summary: summary,
            processName: processName,
            processID: processID,
            attackTechnique: attackTechnique ?? Self.attackTechnique(for: source, context: summary),
            actionTaken: actionTaken,
            parentEventID: parentEventID,
            evidenceRefs: evidenceRefs
        )
        queue.sync {
            var events = loadAll()
            resolveLinks(&event, existing: events)
            events.insert(event, at: 0)
            if events.count > maxEntries {
                events.removeLast(events.count - maxEntries)
            }
            saveAll(events)
        }
        recordObserver?(event)
        return event.id
    }

    /// Adds `refs` to the evidence of the record with `id` (duplicates and anything past `maxEvidenceRefs` are skipped).
    /// `false` when the record is not there. Best effort, like every writer here.
    @discardableResult
    public static func linkEvidence(to id: UUID, refs: [ContainmentEvidenceRef]) -> Bool {
        queue.sync {
            var events = loadAll()
            guard let idx = events.firstIndex(where: { $0.id == id }) else { return false }
            events[idx].evidenceRefs = appendingEvidence(refs, to: events[idx].evidenceRefs)
            saveAll(events)
            return true
        }
    }

    /// Pure: `existing` followed by the usable, new entries of `refs`, never more than `maxEvidenceRefs`.
    static func appendingEvidence(_ refs: [ContainmentEvidenceRef], to existing: [ContainmentEvidenceRef]) -> [ContainmentEvidenceRef] {
        var out = existing
        for r in refs.compactMap({ $0.sanitized() }) where out.count < maxEvidenceRefs && !out.contains(r) {
            out.append(r)
        }
        return out
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

    /// Marks one specific event resolved. Used for records that describe a
    /// transition rather than an incident (e.g. FULL -> DEGRADED air-gap),
    /// which are stamped resolved at creation so a later `resolveLatest`
    /// still lands on the original incident, not on the transition record.
    public static func resolve(id: UUID, resolution: ContainmentIncidentResolution) {
        queue.sync {
            var events = loadAll()
            guard let idx = events.firstIndex(where: { $0.id == id }) else { return }
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
        case .ransomwareEntropy:
            return "T1486" // Data Encrypted for Impact — current callers always pass this explicitly anyway
        case .honeytoken:
            return "T1552" // Unsecured Credentials — current callers always pass this explicitly anyway
        case .browserCredentialWatch:
            return "T1539" // Steal Web Session Cookie — current callers always pass this explicitly anyway
        case .sshGuard:
            return "T1110" // Brute Force — current callers always pass this explicitly anyway
        case .reverseShellWatch:
            return "T1059.004" // Unix Shell — current callers always pass this explicitly anyway
        case .networkSettingsWatch:
            return "T1557" // Adversary-in-the-Middle — current callers always pass this explicitly anyway
        case .runtimeThreat, .portAnomaly, .clickFix, .execRecorder, .vulnerabilityAcceptance, .criticalPathFim, .forensicCapture:
            // XProtect/Gatekeeper/port-anomaly summaries don't carry a
            // Falco-style rule name to pattern-match on macOS, so this
            // stays unmapped rather than guessing.
            return nil
        }
    }
}
