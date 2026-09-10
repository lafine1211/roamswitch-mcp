// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.15 (build 72).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

public enum LogEventCategory: String, CaseIterable, Identifiable, Codable {
    case all
    case sudo
    case ssh
    case gatekeeper
    case xprotect
    case auth

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .all: return loc("すべて")
        case .sudo: return loc("Sudo/管理者権限")
        case .ssh: return loc("SSH接続")
        case .gatekeeper: return loc("Gatekeeper遮断")
        case .xprotect: return loc("XProtect検知")
        case .auth: return loc("ログイン/認証")
        }
    }

    public var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .sudo: return "key.fill"
        case .ssh: return "network"
        case .gatekeeper: return "shield.slash.fill"
        case .xprotect: return "cross.case.fill"
        case .auth: return "lock.fill"
        }
    }
}

public enum LogEventSeverity: String, Codable {
    case info
    case warning
    case critical

    public var badge: String {
        switch self {
        case .info: return "ℹ️ " + loc("情報")
        case .warning: return "⚠️ " + loc("注意")
        case .critical: return "🚨 " + loc("警告")
        }
    }
}

public struct SecurityLogEvent: Identifiable, Equatable, Codable {
    public let id = UUID()
    public let timestamp: Date
    public let process: String
    public let category: LogEventCategory
    public let severity: LogEventSeverity
    public let message: String
}

public struct SecurityLogAuditReport: Equatable {
    public let auditDate: Date
    public let timeWindowHours: Int
    public let totalEvents: Int
    public let sudoFailures: Int
    public let sshAttempts: Int
    public let gatekeeperBlocks: Int
    public let xprotectDetections: Int
    public let events: [SecurityLogEvent]
    public let templateAnomalies: [LogTemplateAnomaly]

    public var isClean: Bool {
        sudoFailures == 0 && gatekeeperBlocks == 0 && xprotectDetections == 0
    }
}

final class SecurityLogAuditor {
    static let shared = SecurityLogAuditor()

    func performAudit(timeWindowHours: Int = 24, completion: @escaping (SecurityLogAuditReport) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let report = self.buildReport(timeWindowHours: timeWindowHours)
            DispatchQueue.main.async {
                completion(report)
            }
        }
    }

    /// Synchronous variant for callers that already run off the main thread
    /// (or a bare command-line context, like `RoamSwitchMCPServer`, whose
    /// `while readLine()` main loop never pumps `RunLoop.main` — routing
    /// through `performAudit`'s `DispatchQueue.main.async` completion there
    /// would deadlock since nothing ever drains the main queue).
    func performAuditSync(timeWindowHours: Int = 24) -> SecurityLogAuditReport {
        buildReport(timeWindowHours: timeWindowHours)
    }

    private func buildReport(timeWindowHours: Int) -> SecurityLogAuditReport {
        let events = fetchSecurityLogs(hours: timeWindowHours)

        let sudoFails = events.filter { $0.category == .sudo && $0.severity != .info }.count
        let sshCount = events.filter { $0.category == .ssh }.count
        let gkBlocks = events.filter { $0.category == .gatekeeper && $0.severity != .info }.count
        let xpCount = events.filter { $0.category == .xprotect && $0.severity != .info }.count

        // `events` is newest-first (see `fetchSecurityLogs`'s sort); the
        // cursor logic needs chronological order to find where the
        // previous run left off. Only events after that cursor are
        // eligible for anomaly scoring — `totalEvents`/`sudoFailures`/etc.
        // above deliberately still reflect the *full* requested window,
        // since a human asking "what happened in the past N hours" wants
        // everything, not just what's new since the last scheduled scan.
        // Slicing on the full `SecurityLogEvent` (not just its message)
        // keeps category/severity attached, since `isKnownBenignNoise`
        // needs both.
        let chronologicalEvents = Array(events.reversed())
        let baseline = LogTemplateAnalyzer.loadBaseline()
        // Matched on `.message` directly rather than via
        // `LogTemplateAnalyzer.itemsSinceCursor` — `SecurityLogEvent`'s
        // synthesized `Equatable` includes its random per-instance `id`
        // (see its declaration), so two structurally-identical events built
        // in different runs would never compare equal there.
        let newSinceCursor: [SecurityLogEvent]
        if let cursor = baseline.lastProcessedMessage, let idx = chronologicalEvents.lastIndex(where: { $0.message == cursor }) {
            newSinceCursor = Array(chronologicalEvents[(idx + 1)...])
        } else {
            newSinceCursor = chronologicalEvents
        }
        let (anomalies, updatedKnown, updatedHistory) = LogTemplateAnalyzer.analyze(
            messages: newSinceCursor.filter { !Self.isKnownBenignNoise($0) }.map(\.message),
            knownTemplates: baseline.known,
            baselineCaptured: baseline.captured,
            frequencyHistory: baseline.frequencyHistory
        )
        LogTemplateAnalyzer.saveBaseline(
            known: updatedKnown,
            frequencyHistory: updatedHistory,
            lastProcessedMessage: chronologicalEvents.last?.message ?? baseline.lastProcessedMessage
        )

        return SecurityLogAuditReport(
            auditDate: Date(),
            timeWindowHours: timeWindowHours,
            totalEvents: events.count,
            sudoFailures: sudoFails,
            sshAttempts: sshCount,
            gatekeeperBlocks: gkBlocks,
            xprotectDetections: xpCount,
            events: events,
            templateAnomalies: anomalies
        )
    }

    private func fetchSecurityLogs(hours: Int) -> [SecurityLogEvent] {
        var results: [SecurityLogEvent] = []

        // Predicate targeting critical security subsystems and processes
        let predicate = """
        process == "sudo" OR \
        process == "sshd" OR \
        process == "loginwindow" OR \
        subsystem == "com.apple.security.syspolicy" OR \
        subsystem == "com.apple.XProtectFramework.PluginService" OR \
        process == "XProtectRemediator"
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/log")
        process.arguments = [
            "show",
            "--predicate", predicate,
            "--last", "\(hours)h",
            "--style", "ndjson",
            "--info"
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            
            // Read output stream line by line with 8s timeout to avoid stalls
            let fileHandle = pipe.fileHandleForReading
            let data = fileHandle.readDataToEndOfFile()
            process.waitUntilExit()

            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                for line in lines where !line.isEmpty {
                    if let event = parseNdjsonLine(line) {
                        results.append(event)
                    }
                }
            }
        } catch {
            print("[SecurityLogAuditor] Log query failed: \(error)")
        }

        // Sort descending by timestamp
        results.sort { $0.timestamp > $1.timestamp }
        return results
    }

    /// Known-benign noise, excluded from `LogTemplateAnalyzer`'s
    /// frequency-spike/new-pattern scoring — mirrors
    /// `is_known_benign_apparmor_denial` / `is_known_benign_suspend_masked_noise`
    /// in roamswitch-linux's `log_auditor.rs`, which had no equivalent here
    /// until this gap was flagged by the 2026-09-10 Linux false-positive audit.
    ///
    /// A `.gatekeeper` event that `parseNdjsonLine` classified `.info` is a
    /// *successful* syspolicyd assessment, not a denial — `deny`/`block`/`reject`
    /// keywords already route to `.warning` above and are never touched here,
    /// no matter how many occur. Every binary a package manager (Homebrew,
    /// MacPorts, ...) installs or replaces triggers one of these successful
    /// assessments, so a single `brew upgrade` touching dozens of formulae can
    /// legitimately burst near-identical assessment lines in
    /// `com.apple.security.syspolicy` — the same shape as the Linux snapd/
    /// suspend-loop false positives, just not yet observed in the wild here.
    static func isKnownBenignNoise(_ event: SecurityLogEvent) -> Bool {
        (event.category == .gatekeeper && event.severity == .info)
            || isKnownBenignFirstResponderKvoNoise(event.message)
            || isKnownBenignLoginLogoutRelaunchNoise(event.message)
            || isKnownBenignPasteboardConnectionNoise(event.message)
    }

    /// Known-benign pasteboard-server hiccup: `CFPasteboardRef` logs
    /// "Failed to set up ... Connection invalid" whenever the system
    /// pasteboard server (`pboard`) is momentarily unavailable — common
    /// right after wake, a fast-user-switch, or an app launching before
    /// the server has finished restarting. Routine macOS plumbing chatter
    /// with zero security relevance. Found 2026-09-10.
    private static func isKnownBenignPasteboardConnectionNoise(_ message: String) -> Bool {
        let lower = message.lowercased()
        return lower.contains("cfpasteboardref") && lower.contains("connection invalid")
    }

    /// Known-benign login/logout session-relaunch chatter: macOS's own
    /// `PersistentAppsSupport` (the "reopen windows when logging back in"
    /// feature) and `BTMManager` (Background Task Management — the
    /// LaunchAgent/LaunchDaemon legitimacy tracker Apple added in Ventura)
    /// both log unconditionally on every login/logout/reboot cycle. Since
    /// these lines are essentially absent the rest of the time, their
    /// per-template baseline mean sits near zero — so the very next login
    /// after any gap produces a z-score in the double digits purely from
    /// that near-zero floor, not from anything actually anomalous. Found
    /// 2026-09-10: a real notification's single highest-z-score entry
    /// (z=14.0) was exactly this, unrelated to security.
    private static func isKnownBenignLoginLogoutRelaunchNoise(_ message: String) -> Bool {
        let lower = message.lowercased()
        return lower.contains("persistentappssupport") || lower.contains("btmmanager")
    }

    /// Known-benign AppKit/lock-screen KVO chatter: `LWDefaultScreenLockUI`
    /// (and similar system UI classes) log an `observeValueForKeyPath:
    /// ofObject:change:context:` line every time UI focus moves anywhere in
    /// the system — an extremely common, entirely routine event with zero
    /// security relevance, not a sign anything happened. Found 2026-09-10:
    /// a real ScheduledLogAuditGuard notification highlighted this as its
    /// single representative example (highest z-score among that run's
    /// "new pattern" hits), leaving the reader with no way to tell it was
    /// meaningless UI noise.
    private static func isKnownBenignFirstResponderKvoNoise(_ message: String) -> Bool {
        let lower = message.lowercased()
        return lower.contains("observevalueforkeypath") && lower.contains("firstresponder changed")
    }

    /// Not `private`: `RuntimeThreatContainmentManager` shares this exact
    /// categorization so its autonomous Air-Gap trigger and this manual
    /// report always agree on what counts as a critical XProtect/Gatekeeper
    /// event.
    func parseNdjsonLine(_ line: String) -> SecurityLogEvent? {
        guard let data = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let process = json["processImagePath"] as? String ?? json["process"] as? String ?? ""
        let procName = URL(fileURLWithPath: process).lastPathComponent
        let msg = json["eventMessage"] as? String ?? ""
        guard !msg.isEmpty else { return nil }

        let timestampStr = json["timestamp"] as? String ?? ""
        let date: Date = {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return iso.date(from: timestampStr) ?? Date()
        }()

        // Categorize & Assess Severity
        let category: LogEventCategory
        let severity: LogEventSeverity

        if procName.contains("sudo") {
            category = .sudo
            if msg.localizedCaseInsensitiveContains("incorrect password") ||
               msg.localizedCaseInsensitiveContains("authentication error") ||
               msg.localizedCaseInsensitiveContains("fail") {
                severity = .critical
            } else {
                severity = .info
            }
        } else if procName.contains("sshd") {
            category = .ssh
            if msg.localizedCaseInsensitiveContains("Failed") ||
               msg.localizedCaseInsensitiveContains("Invalid") {
                severity = .critical
            } else if msg.localizedCaseInsensitiveContains("Accepted") {
                severity = .warning
            } else {
                severity = .info
            }
        } else if procName.contains("syspolicy") || json["subsystem"] as? String == "com.apple.security.syspolicy" {
            category = .gatekeeper
            if msg.localizedCaseInsensitiveContains("deny") ||
               msg.localizedCaseInsensitiveContains("block") ||
               msg.localizedCaseInsensitiveContains("reject") {
                severity = .warning
            } else {
                severity = .info
            }
        } else if procName.contains("XProtect") || json["subsystem"] as? String == "com.apple.XProtectFramework.PluginService" {
            category = .xprotect
            if msg.localizedCaseInsensitiveContains("infected") ||
               msg.localizedCaseInsensitiveContains("remediated") ||
               msg.localizedCaseInsensitiveContains("malware") {
                severity = .critical
            } else {
                severity = .info
            }
        } else if procName.contains("loginwindow") {
            category = .auth
            if msg.localizedCaseInsensitiveContains("fail") ||
               msg.localizedCaseInsensitiveContains("reject") {
                severity = .warning
            } else {
                severity = .info
            }
        } else {
            return nil
        }

        // Redacted here — the single construction site for every
        // SecurityLogEvent — so the GUI table, the AI-consultation prompt,
        // the "copy report" clipboard flow, and the MCP JSON payload all see
        // a masked `message` with no separate redaction pass needed at each
        // of those call sites.
        return SecurityLogEvent(
            timestamp: date,
            process: procName,
            category: category,
            severity: severity,
            message: SecretLeakScanning.redact(msg)
        )
    }
}
