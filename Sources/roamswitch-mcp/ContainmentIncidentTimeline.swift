// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.27 (build 206).
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
    /// `WebMailDownloadGuard`'s RMM-installer-source check (APT_REPORT
    /// applicability analysis, A6): a known remote-support tool (AnyDesk,
    /// ScreenConnect, TeamViewer, ngrok) downloaded from a source that
    /// isn't that vendor's own domain. Always notify-only -- these tools
    /// are legitimate business software, so this is never quarantined or
    /// air-gapped. Always maps to T1219 (Remote Access Software). Added
    /// additively, same as the cases above.
    case rmmInstallerUnofficialSource
    /// `PersistenceMonitorGuard`: a new LaunchAgent/LaunchDaemon that looks illegitimate, or a suspicious line in a
    /// file run at start-up (shell start-up files, periodic scripts, hooks, Folder Actions, Python start-up files).
    /// The Mac counterpart of the Linux edition's `Persistence`, and like it a sign for `DevicePosture`. The callers
    /// pass the technique. Added additively, same as the cases above.
    case persistence
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

/// The kind of sentence a record's `summary` is, and its values, so a reader can write the sentence in the language it
/// shows now instead of the one in use when the record was made. The same shape as the Linux edition's `summary_code`
/// (`{"code": "...", "args": {...}}`). `code` is a fixed dotted name, never translated; the values are copied as they
/// were (paths, addresses, process names: text from the system or from an attacker, never interpreted).
public struct ContainmentSummaryCode: Codable, Equatable {
    public let code: String
    public let args: [String: String]

    public init(_ code: String, _ args: [String: String] = [:]) {
        self.code = code
        self.args = args
    }

    private enum CodingKeys: String, CodingKey { case code, args }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        code = try c.decode(String.self, forKey: .code)
        args = try c.decodeIfPresent([String: String].self, forKey: .args) ?? [:]
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
    /// What `summary` says, without a language (see `ContainmentSummaryCode`). `nil` on records written before it
    /// existed and on records whose text has no fixed form; those are shown as stored.
    public var summaryCode: ContainmentSummaryCode?

    /// The summary in the language shown now: written from `summaryCode` when it is a code this build knows,
    /// otherwise the stored text.
    public var displaySummary: String {
        summaryCode.flatMap { ContainmentSummaryText.text(for: $0) } ?? summary
    }

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
        evidenceRefs: [ContainmentEvidenceRef] = [],
        summaryCode: ContainmentSummaryCode? = nil
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
        self.summaryCode = summaryCode
    }

    // The three link fields are newer than the file format: a file written before them has none of the keys, and a
    // record without links is written without them, so an older build reads the file as before.
    private enum CodingKeys: String, CodingKey {
        case id, timestamp, source, severity, summary, processName, processID, attackTechnique, actionTaken
        case resolvedAt, resolution, parentEventID, rootEventID, evidenceRefs, summaryCode
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
        // A code this build cannot read (a damaged entry) leaves the record readable with its stored text.
        summaryCode = (try? c.decodeIfPresent(ContainmentSummaryCode.self, forKey: .summaryCode)) ?? nil
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
        try c.encodeIfPresent(summaryCode, forKey: .summaryCode)
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

    /// Called after the stored records changed: a record was added, or one was marked resolved. `recordObserver` belongs
    /// to the forwarder, so `DevicePostureTrust` listens here instead. It runs on the calling thread and must return quickly.
    public static var changeHook: (() -> Void)?

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
        evidenceRefs: [ContainmentEvidenceRef] = [],
        summaryCode: ContainmentSummaryCode? = nil
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
            evidenceRefs: evidenceRefs,
            summaryCode: summaryCode
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
        changeHook?()
        return event.id
    }

    /// Records an incident whose summary has a fixed form: `summary` is `code` written in the language shown now, and
    /// the code is stored with it so readers can write it again in theirs.
    @discardableResult
    public static func record(
        source: ContainmentIncidentSource,
        severity: String,
        code: ContainmentSummaryCode,
        processName: String? = nil,
        processID: Int32? = nil,
        attackTechnique: String? = nil,
        actionTaken: String,
        parentEventID: UUID? = nil,
        evidenceRefs: [ContainmentEvidenceRef] = []
    ) -> UUID {
        record(source: source, severity: severity, summary: ContainmentSummaryText.text(for: code) ?? code.code,
               processName: processName, processID: processID, attackTechnique: attackTechnique, actionTaken: actionTaken,
               parentEventID: parentEventID, evidenceRefs: evidenceRefs, summaryCode: code)
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
        changeHook?()
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
        changeHook?()
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
        case .rmmInstallerUnofficialSource:
            return "T1219" // Remote Access Software — current callers always pass this explicitly anyway
        case .runtimeThreat, .portAnomaly, .clickFix, .execRecorder, .vulnerabilityAcceptance, .criticalPathFim, .forensicCapture,
             .persistence:
            // XProtect/Gatekeeper/port-anomaly summaries don't carry a
            // Falco-style rule name to pattern-match on macOS, so this
            // stays unmapped rather than guessing.
            return nil
        }
    }
}

/// Writes a `ContainmentSummaryCode` as a sentence in the language shown now. Every code here has the same sentence as
/// the text its writer stores in `summary`, so a record reads the same in the language it was made in. A code this
/// build does not know, or one that lacks a value it needs, gives `nil`: the reader then shows the stored text.
///
/// The codes are the Mac edition's own. None reuses a Linux `summary_code` name, because their values differ.
public enum ContainmentSummaryText {
    /// The title of an exec-recorder rule by its id. Set by the app (the rule titles live there); the targets that only
    /// read the timeline (the MCP server) leave it `nil` and show the stored text for those records.
    public static var execRuleTitle: ((String) -> String?)?

    // MARK: Codes (the writers use these, so a name or value is never spelled twice)

    public static func browserCredentialAccess(file: String) -> ContainmentSummaryCode {
        ContainmentSummaryCode("browser_credential.access", ["file": file])
    }
    public static func vulnAcceptanceExpired(package: String, version: String, cve: String, reason: String) -> ContainmentSummaryCode {
        ContainmentSummaryCode("vuln_acceptance.expired", ["package": package, "version": version, "cve": cve, "reason": reason])
    }
    public static func networkSettingsChanged(savedDNSOnly: Bool) -> ContainmentSummaryCode {
        ContainmentSummaryCode(savedDNSOnly ? "network_settings.saved_dns_added" : "network_settings.changed")
    }
    public static let portScanSaturated = ContainmentSummaryCode("port_scan.saturated")
    public static func portScanIncoming(source: String) -> ContainmentSummaryCode {
        ContainmentSummaryCode("port_scan.incoming", ["source": source])
    }
    public static let airGapDegraded = ContainmentSummaryCode("air_gap.degraded")
    public static func evidenceBundleSaved(bundle: String) -> ContainmentSummaryCode {
        ContainmentSummaryCode("forensic.bundle_saved", ["bundle": bundle])
    }
    public static func sigmaRuleMatch(title: String, process: String) -> ContainmentSummaryCode {
        ContainmentSummaryCode("sigma.rule_match", ["title": title, "process": process])
    }
    public enum SSHKind: String { case banned = "ssh_guard.source_banned", detected = "ssh_guard.source_detected",
                                       loginAfterFailures = "ssh_guard.source_login_after_failures" }
    public static func ssh(_ kind: SSHKind, source: String) -> ContainmentSummaryCode {
        ContainmentSummaryCode(kind.rawValue, ["source": source])
    }
    public static func gatewayMACChanged(previous: String, current: String) -> ContainmentSummaryCode {
        ContainmentSummaryCode("arp_spoof.gateway_mac_changed", ["previous": previous, "current": current])
    }
    public static func honeytokenCascade(path: String) -> ContainmentSummaryCode {
        ContainmentSummaryCode("honeytoken.cascade_deployed", ["path": path])
    }
    public static func honeytokenAccess(kind: String, path: String) -> ContainmentSummaryCode {
        ContainmentSummaryCode("honeytoken.access", ["kind": kind, "path": path])
    }
    public static func persistence(path: String) -> ContainmentSummaryCode {
        ContainmentSummaryCode("persistence.suspicious", ["path": path])
    }
    public static func exposedPort(_ port: Int, udp: Bool) -> ContainmentSummaryCode {
        ContainmentSummaryCode(udp ? "port_anomaly.udp_exposed" : "port_anomaly.tcp_exposed", ["port": String(port)])
    }
    /// A listener an SSH session into this Mac opened (`ssh -R` from the other side). `address`: `127.0.0.1:8080`.
    public static func sshForwardListener(address: String, process: String, pid: Int) -> ContainmentSummaryCode {
        ContainmentSummaryCode("port_anomaly.ssh_forward_listener", ["address": address, "process": process, "pid": String(pid)])
    }
    /// `repeated`: the same rule, program and parent less than five minutes after a notified alert (recorded, not notified).
    public static func execRule(_ ruleID: String, process: String, repeated: Bool = false) -> ContainmentSummaryCode {
        var args = ["rule": ruleID, "process": process]
        if repeated { args["repeated"] = "1" }
        return ContainmentSummaryCode("exec.rule", args)
    }
    public static func reverseShell(process: String, peer: String) -> ContainmentSummaryCode {
        ContainmentSummaryCode("reverse_shell.suspected", ["process": process, "peer": peer])
    }
    public static func canary(_ trigger: RansomwareCanaryTrigger) -> ContainmentSummaryCode {
        ContainmentSummaryCode("canary.triggered", ["trigger": trigger.rawValue])
    }
    /// `average` / `window`: the entropy figures, kept with two decimals as the sentence shows them.
    public static func entropyBurst(files: Int, average: Double?, window: Double?) -> ContainmentSummaryCode {
        var args = ["files": String(files)]
        if let average { args["average"] = String(format: "%.2f", average) }
        if let window { args["window"] = String(format: "%.2f", window) }
        return ContainmentSummaryCode("ransomware.entropy_files", args)
    }
    public enum ClickFixPattern: String { case known, base64Osascript = "base64_osascript", base64PipeShell = "base64_pipe_shell",
                                              base64ShellRun = "base64_shell_run" }
    /// `name`: the signature name, for `.known` only.
    public static func clickFix(_ pattern: ClickFixPattern, name: String? = nil) -> ContainmentSummaryCode {
        ContainmentSummaryCode("clickfix.pattern", name.map { ["pattern": pattern.rawValue, "name": $0] } ?? ["pattern": pattern.rawValue])
    }
    /// Files under /etc/pam.d that the first scan on a new macOS build took into the baseline.
    public static func pamRebaselined(_ paths: [String]) -> ContainmentSummaryCode {
        ContainmentSummaryCode("fim.pam_rebaselined", ["files": paths.joined(separator: "\n")])
    }
    /// An accepted baseline: `entries` are (kind, path) with kind `changed` / `deleted` / `new`; `more` files were left out.
    public static func fimBaselineAccepted(entries: [(kind: String, path: String)], more: Int) -> ContainmentSummaryCode {
        var args = ["entries": entries.map { $0.kind + "\t" + $0.path }.joined(separator: "\n")]
        if more > 0 { args["more"] = String(more) }
        return ContainmentSummaryCode("fim.baseline_accepted", args)
    }

    // MARK: Writing the sentence

    /// `localeCode`: the language to write in (one of `AppLanguage`'s raw values); the shown one when left out.
    public static func text(for c: ContainmentSummaryCode, localeCode: String? = nil) -> String? {
        let lang = localeCode ?? AppLanguage.activeLocaleCode
        let a = c.args
        func f(_ key: String, _ names: [String]) -> String? {
            var values: [CVarArg] = []
            for n in names { guard let v = a[n] else { return nil }; values.append(v) }
            return locFormat(key, localeCode: lang, arguments: values)
        }
        switch c.code {
        case "browser_credential.access": return f("ブラウザ認証情報ストア(%@)への不審なアクセスを検知", ["file"])
        case "vuln_acceptance.expired":
            return f("脆弱性の受容が期限切れになりました: %@ %@ の %@。再び要対応として表示します。受容した理由: %@", ["package", "version", "cve", "reason"])
        case "network_settings.changed": return loc("ネットワーク設定の変化を検知(DNS・ルーター・プロキシ)", localeCode: lang)
        case "network_settings.saved_dns_added": return loc("保存されたDNSサーバーに、新しいものが加わりました", localeCode: lang)
        case "port_scan.saturated": return loc("SYNの大量受信で、ポートスキャンの検知が飽和しました", localeCode: lang)
        case "port_scan.incoming": return f("着信ポートスキャンを検知: %@", ["source"])
        case "air_gap.degraded": return loc("Air-Gapを全遮断から縮退モードへ移行（原因の解消を確認できなかったため）", localeCode: lang)
        case "forensic.bundle_saved": return f("証拠バンドルを保存しました: %@", ["bundle"])
        case "sigma.rule_match":
            guard let title = a["title"], let process = a["process"] else { return nil }
            return locFormat("Sigmaルールに一致: %@", localeCode: lang, title + " — " + process)
        case SSHKind.banned.rawValue: return f("SSH総当たりを検知し遮断: %@", ["source"])
        case SSHKind.detected.rawValue: return f("SSH総当たりを検知: %@", ["source"])
        case SSHKind.loginAfterFailures.rawValue: return f("失敗を重ねたSSH送信元からログイン成功: %@", ["source"])
        case "arp_spoof.gateway_mac_changed": return f("ゲートウェイMACが %@ から %@ に変化", ["previous", "current"])
        case "honeytoken.cascade_deployed": return f("囮への実際のアクセスを受け、関連する囮を追加で配置しました: %@", ["path"])
        case "honeytoken.access": return f("ハニートークン(%@)へのアクセスを検知: %@", ["kind", "path"])
        case "persistence.suspicious": return f("不審な自動起動の登録: %@", ["path"])
        case "port_anomaly.tcp_exposed", "port_anomaly.udp_exposed":
            guard let port = a["port"].flatMap(Int.init) else { return nil }
            // A port number is not a count: no grouping ("8080", not "8,080").
            return String(format: loc(c.code == "port_anomaly.udp_exposed" ? "UDPポート %d の外部公開を検知" : "ポート %d の外部公開を検知", localeCode: lang), port)
        case "port_anomaly.ssh_forward_listener":
            // Not through locFormat: the PID and the port are not counts ("8080", not "8,080").
            guard let address = a["address"], let process = a["process"], let pid = a["pid"] else { return nil }
            return String(format: loc("SSH の接続が開いた待ち受け: %1$@ (%2$@、PID %3$@)", localeCode: lang), address, process, pid)
        case "exec.rule":
            guard let rule = a["rule"], let process = a["process"], let title = execRuleTitle?(rule) else { return nil }
            guard a["repeated"] == "1" else { return title + " — " + process }
            return title + " — " + process + " " + loc("(5分以内の同じ検知の繰り返し。通知はしていません)", localeCode: lang)
        case "reverse_shell.suspected": return f("リバースシェルの疑い: %1$@ が %2$@ に接続", ["process", "peer"])
        case "canary.triggered":
            switch a["trigger"].flatMap(RansomwareCanaryTrigger.init(rawValue:)) {
            case .deletedOrRenamed: return loc("不審なファイルの削除または拡張子改ざんを検知", localeCode: lang)
            case .tampered: return loc("不審なファイル暗号化・改ざんの活動を検知", localeCode: lang)
            case nil: return nil
            }
        case "ransomware.entropy_files":
            guard let files = a["files"].flatMap(Int.init) else { return nil }
            let average = a["average"].flatMap(Double.init)
            let window = a["window"].flatMap(Double.init)
            switch (average, window) {
            case (let average?, let window?):
                return locFormat("%d件のファイルで高エントロピー(暗号化済みの疑いがある)な書き込みを検知しました(全体で判定したファイルの平均エントロピー %.2f、一部分だけで判定したファイルの最も高い窓 %.2f)", localeCode: lang, files, average, window)
            case (nil, let window?):
                return locFormat("%d件のファイルで、一部分が高エントロピー(暗号化済みの疑いがある)な書き込みを検知しました(最も高い窓のエントロピー %.2f)", localeCode: lang, files, window)
            case (let average, nil):
                return locFormat("%d件のファイルで高エントロピー(暗号化済みの疑いがある)な書き込みを検知しました(平均エントロピー %.2f)", localeCode: lang, files, average ?? 0.0)
            }
        case "clickfix.pattern":
            switch a["pattern"].flatMap(ClickFixPattern.init(rawValue:)) {
            case .known: return f("既知の不審コマンドパターン(%@)", ["name"])
            case .base64Osascript: return loc("Base64デコードした内容をosascriptに直接渡す実行パターン(ClickFix典型手口)", localeCode: lang)
            case .base64PipeShell: return loc("Base64デコードした内容をシェルに直接パイプする実行パターン(ClickFix典型手口)", localeCode: lang)
            case .base64ShellRun: return loc("Base64デコードした内容をシェルに直接渡して実行するパターン(ClickFix典型手口)", localeCode: lang)
            case nil: return nil
            }
        case "fim.pam_rebaselined":
            guard let files = a["files"], !files.isEmpty else { return nil }
            return locFormat("macOSの更新のあと、/etc/pam.d の次のファイルを基準に取り込みました: %@", localeCode: lang,
                             files.split(separator: "\n").joined(separator: ", "))
        case "fim.baseline_accepted":
            guard let entries = a["entries"] else { return nil }
            var parts: [String] = []
            for line in entries.split(separator: "\n") {
                let pieces = line.split(separator: "\t", maxSplits: 1).map(String.init)
                guard pieces.count == 2 else { return nil }
                let kind: String
                switch pieces[0] {
                case "changed": kind = loc("変更", localeCode: lang)
                case "deleted": kind = loc("削除", localeCode: lang)
                case "new": kind = loc("新規追加", localeCode: lang)
                default: return nil
                }
                parts.append("\(pieces[1]) (\(kind))")
            }
            if let more = a["more"].flatMap(Int.init) { parts.append(locFormat("他%d件", localeCode: lang, more)) }
            return locFormat("重要ファイルの基準を更新(%@)", localeCode: lang, parts.joined(separator: ", "))
        default:
            return nil
        }
    }
}
