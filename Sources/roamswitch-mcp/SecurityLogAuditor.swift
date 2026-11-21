// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.2.3 (build 227).
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
    /// Lines from the system itself that the log audit reads for a named kind (`LogAuditKind`): privacy permissions
    /// (tccd), the kernel, the disk, crash reports and Wi-Fi authentication.
    case system
    /// Synthetic category for `LogTemplateAnomaly` results, folded into the
    /// same filterable/searchable list as everything else in
    /// `SecurityLogAuditView` instead of being visible only via the
    /// KPI card's bare count or the clipboard-only report/AI-consultation
    /// text — found from a live user report that a "テンプレート異常: N件"
    /// count with no way to actually look at the N items, right there on
    /// screen, was not useful.
    case templateAnomaly

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .all: return loc("すべて")
        case .sudo: return loc("Sudo/管理者権限")
        case .ssh: return loc("SSH接続")
        case .gatekeeper: return loc("Gatekeeper遮断")
        case .xprotect: return loc("XProtect検知")
        case .auth: return loc("ログイン/認証")
        case .system: return loc("システム/OS")
        case .templateAnomaly: return loc("テンプレート異常")
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
        case .system: return "gearshape.fill"
        case .templateAnomaly: return "puzzlepiece.extension.fill"
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
    /// The unified log `subsystem` field (e.g. `"com.apple.wallpaper"`) —
    /// set by the logging process itself, not attacker-influenced content,
    /// same provenance argument as `process`. Kept alongside `message`
    /// (rather than folded into it) so `isKnownBenignNoise` can exclude an
    /// entire Apple-owned subsystem structurally instead of enumerating its
    /// individual message text. Defaults to `""` for the handful of
    /// synthetic/test events that have no real unified-log entry behind them.
    public let subsystem: String
    /// The full path of the process that wrote the line (`processImagePath`), for reading its signature. `""` when the
    /// log did not give one.
    public let processPath: String
    /// The kind of line a person can judge (`LogAuditKind`); nil for a line that is only a statistic.
    public let kind: LogAuditKind?

    public init(timestamp: Date, process: String, category: LogEventCategory, severity: LogEventSeverity, message: String, subsystem: String = "",
                processPath: String = "", kind: LogAuditKind? = nil) {
        self.timestamp = timestamp
        self.process = process
        self.category = category
        self.severity = severity
        self.message = message
        self.subsystem = subsystem
        self.processPath = processPath
        self.kind = kind
    }
}

/// What one `log show` run could not deliver. A full, clean read leaves every field at its default.
public struct SecurityLogReadStatus: Equatable {
    /// Hours the caller asked for and hours actually queried (held to 1...168). 0 = not recorded (hand-built reports).
    public var hoursRequested = 0
    public var hoursQueried = 0
    /// `launch_failed`: `log` could not be started. `exit_error`: it exited with an error (`exitStatus`) or the
    /// output could not be read to the end.
    public var failureReason: String?
    public var exitStatus: Int32?
    /// The wall-clock ceiling stopped the query; what had been read until then was used.
    public var timedOut = false
    /// The output went past the byte cap: the newest part was kept and the oldest part was dropped.
    public var outputTruncated = false
    /// Lines with bytes that are not valid UTF-8 (examined with the bytes replaced), and lines that looked like
    /// JSON but could not be parsed (not examined).
    public var linesLossy = 0
    public var linesUnparsable = 0
    /// The kernel and disk lines were read over this many hours, fewer than `hoursQueried` (0 = the same window).
    public var kernelStageHours = 0
    /// Events parsed from the output.
    public var eventsRead = 0

    public init() {}

    /// Nothing could be read: the audit says nothing about the log.
    public var unreadable: Bool { eventsRead == 0 && (failureReason != nil || timedOut) }
    public var windowClamped: Bool { hoursRequested != 0 && hoursRequested != hoursQueried }
    /// Part of the log was not examined.
    public var limited: Bool { !unreadable && (failureReason != nil || timedOut || outputTruncated) }
    /// Why only part of the window came back (`GuardReaderHealth.readLimited`), nil for a whole read or one that read nothing.
    public var limitedReason: String? {
        guard limited else { return nil }
        if timedOut { return "timeout" }
        if outputTruncated { return "output_cap" }
        return "exit_error"
    }
    public var kernelWindowShortened: Bool { kernelStageHours != 0 }
    public var skippedAnything: Bool { unreadable || limited || windowClamped || kernelWindowShortened || linesLossy > 0 || linesUnparsable > 0 }

    /// The reason code kept in `GuardReaderHealth` when the log could not be read.
    public var healthReason: String {
        if failureReason == "launch_failed" { return "launch_failed" }
        return timedOut ? "log_timeout" : "log_exit_error"
    }

    /// One plain sentence per thing that was skipped; empty for a clean full read.
    public var notes: [String] {
        var out: [String] = []
        let seconds = Int(SecurityLogAuditor.logQueryTimeoutSeconds)
        if unreadable {
            if failureReason == "launch_failed" {
                out.append(loc("ログを読めませんでした(log コマンドを起動できませんでした)。「問題なし」という意味ではありません。"))
            } else if timedOut {
                out.append(locFormat("ログを読めませんでした(%d 秒以内に読み終えられませんでした)。「問題なし」という意味ではありません。", seconds))
            } else {
                out.append(loc("ログを読めませんでした(log コマンドがエラーで終了しました)。「問題なし」という意味ではありません。"))
            }
        } else {
            if timedOut {
                out.append(locFormat("ログの取得が %d 秒の制限で止まったため、途中までを調べました。", seconds))
            } else if failureReason != nil {
                out.append(loc("ログの取得が途中でエラーになったため、途中までを調べました。"))
            }
            if outputTruncated {
                out.append(String(format: loc("ログが大きいため、新しい側の約 %d MB だけを調べました(古いログは含まれません)。"),
                                  SecurityLogAuditor.maxLogOutputBytes / (1024 * 1024)))
            }
        }
        if windowClamped {
            out.append(locFormat("指定の %d 時間は範囲外のため、直近 %d 時間を調べました。", hoursRequested, hoursQueried))
        }
        if kernelWindowShortened {
            out.append(locFormat("カーネルとディスクのログは、重いため、直近 %d 時間分だけを調べました。", kernelStageHours))
        }
        if linesLossy > 0 {
            out.append(locFormat("読めない文字を含む行が %d 件ありました(文字を置き換えて調べました)。", linesLossy))
        }
        if linesUnparsable > 0 {
            out.append(locFormat("解析できなかった行が %d 件ありました。", linesUnparsable))
        }
        return out
    }

    /// `notes` as one text, with what "no findings" then means; nil for a clean full read.
    public var coverageNote: String? {
        let n = notes
        guard !n.isEmpty else { return nil }
        if unreadable { return n.joined(separator: " ") }
        return (n + [loc("「問題なし」は、調べられた範囲に見つからなかったという意味です。")]).joined(separator: " ")
    }
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
    /// What the anomalies come to: findings whose line belongs to a kind a person can judge (`LogAuditKind`: they
    /// may notify), and the anomalies that belong to none (they are kept in the history and never notify).
    public var outcome = LogAuditOutcome()
    /// What the log read could not deliver (see `SecurityLogReadStatus`).
    public var readStatus = SecurityLogReadStatus()

    /// Nothing found in the log. A log that could not be read is never clean: it says nothing.
    public var isClean: Bool {
        sudoFailures == 0 && gatekeeperBlocks == 0 && xprotectDetections == 0 && !readStatus.unreadable
    }
}

/// What one audit run writes to the notification history on its own. The scheduled guard delivers its notice itself
/// (which records it), so it asks the audit not to record the same findings a second time.
enum LogAuditHistoryPolicy: Equatable {
    /// The findings' notice and the record of the unclassified patterns (manual audit, MCP).
    case all
    /// The unclassified record only: the guard delivers (and so records) the findings.
    case leaveNoticesToNotifier
    /// The findings' notice only: the guard's first scan after a launch learns the baseline, and the launch's own
    /// narration is not worth a history entry.
    case firstScanQuiet
}

final class SecurityLogAuditor {
    static let shared = SecurityLogAuditor()

    /// App-side asynchronous audit: records what the read could not deliver in the reader health.
    func performAudit(timeWindowHours: Int = 24, completion: @escaping (SecurityLogAuditReport) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let report = self.buildReport(timeWindowHours: timeWindowHours, history: .all)
            Self.recordReadHealth(report.readStatus)
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
    /// `recordHealth` is for the app's own callers; the MCP server process has no reader-health store of its own.
    /// `history`: what the audit writes to the notification history itself (see `LogAuditHistoryPolicy`).
    func performAuditSync(timeWindowHours: Int = 24, recordHealth: Bool = false, history: LogAuditHistoryPolicy = .all) -> SecurityLogAuditReport {
        let report = buildReport(timeWindowHours: timeWindowHours, history: history)
        if recordHealth { Self.recordReadHealth(report.readStatus) }
        return report
    }

    /// The reader-health source of the scheduled and manual log audit (`get_guard_status`: `scheduledLogAudit`).
    static let readHealthSource = "scheduledLogAudit"
    private static let readHealthRecorder = GuardReaderHealthRecorder.forApp(source: readHealthSource)

    /// Keeps what the last run could not read: unreadable log -> the guard is `off`; part of it skipped -> `partial`
    /// until the next full read. A cap that was reached does not notify by itself.
    static func recordReadHealth(_ status: SecurityLogReadStatus, recorder: GuardReaderHealthRecorder? = nil) {
        (recorder ?? readHealthRecorder).update(force: true) { h, now in
            h.enableDropCounters()
            if status.unreadable {
                h.markUnreadable(reason: status.healthReason, now: now)
            } else {
                h.markStarted(now: now)
                // A log query is not a scan of files: a limited read is its own result (it was shown as "1 file read only at
                // its start and end", with steps about files).
                h.setScanResult(filesUnreadable: 0, foldersUnreadable: 0, filesTruncated: 0, now: now)
                h.setReadLimited(status.limitedReason, now: now)
            }
            h.addDropped(status.linesUnparsable, now: now)
        }
    }

    private func buildReport(timeWindowHours: Int, history: LogAuditHistoryPolicy) -> SecurityLogAuditReport {
        let (events, readStatus) = fetchSecurityLogs(hours: timeWindowHours)

        // A log that could not be read at all must not move the template baseline: an empty window would count as
        // "zero occurrences" for every known pattern and blunt the next frequency check.
        if readStatus.unreadable {
            var report = SecurityLogAuditReport(
                auditDate: Date(), timeWindowHours: readStatus.hoursQueried, totalEvents: 0, sudoFailures: 0, sshAttempts: 0,
                gatekeeperBlocks: 0, xprotectDetections: 0, events: [], templateAnomalies: []
            )
            report.readStatus = readStatus
            return report
        }

        let sudoFails = events.filter { $0.category == .sudo && $0.severity != .info }.count
        let sshCount = events.filter { $0.category == .ssh }.count
        let gkBlocks = events.filter { $0.category == .gatekeeper && $0.severity != .info }.count
        let xpCount = events.filter { $0.category == .xprotect && $0.severity != .info }.count

        let scan = evaluateScan(events: events, hoursQueried: readStatus.hoursQueried, history: history)

        var report = SecurityLogAuditReport(
            auditDate: Date(),
            timeWindowHours: readStatus.hoursQueried,
            totalEvents: events.count,
            sudoFailures: sudoFails,
            sshAttempts: sshCount,
            gatekeeperBlocks: gkBlocks,
            xprotectDetections: xpCount,
            events: events,
            templateAnomalies: scan.anomalies,
            outcome: scan.outcome
        )
        report.readStatus = readStatus
        return report
    }

    /// The analysis of one scan, apart from reading the log: template anomalies against the persisted baseline, the
    /// kinds of line they belong to, the kind frequency history, and what goes to the notification history.
    /// `defaults` is the store for the baselines and the history (nil: the app's own; tests pass a scratch suite).
    func evaluateScan(
        events: [SecurityLogEvent],
        hoursQueried: Int,
        history: LogAuditHistoryPolicy,
        defaults: UserDefaults? = nil,
        signer: (String) -> LogAuditSigner = LogAuditSigner.lookup(path:)
    ) -> (anomalies: [LogTemplateAnomaly], outcome: LogAuditOutcome) {
        // `events` is newest-first (see `fetchSecurityLogs`'s sort); the
        // cursor logic needs chronological order to find where the
        // previous run left off. Only events after that cursor are
        // eligible for anomaly scoring — `totalEvents`/`sudoFailures`/etc.
        // (the caller) deliberately still reflect the *full* requested window,
        // since a human asking "what happened in the past N hours" wants
        // everything, not just what's new since the last scheduled scan.
        // Slicing on the full `SecurityLogEvent` (not just its message)
        // keeps category/severity attached, since `isKnownBenignNoise`
        // needs both.
        let chronologicalEvents = Array(events.reversed())
        let baseline = LogTemplateAnalyzer.loadBaseline(defaults: defaults)
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
        let examined = newSinceCursor.filter { !Self.isKnownBenignNoise($0) }
        let (anomalies, updatedKnown, updatedHistory) = LogTemplateAnalyzer.analyze(
            messages: examined.map(\.message),
            knownTemplates: baseline.known,
            baselineCaptured: baseline.captured,
            frequencyHistory: baseline.frequencyHistory
        )
        LogTemplateAnalyzer.saveBaseline(
            known: updatedKnown,
            frequencyHistory: updatedHistory,
            lastProcessedMessage: chronologicalEvents.last?.message ?? baseline.lastProcessedMessage,
            defaults: defaults
        )

        // What a new or frequent pattern comes to is decided by the kind of its line (`LogAuditKind`: fixed rules over
        // the process, subsystem and message), never by how unusual the statistic is. A pattern whose line belongs to a
        // kind a person can judge is a finding, with the kind, the program and the kind's own past frequency; any other
        // pattern is a statistic nobody can act on, and goes to the notification history without a notice.
        let kindStats = LogAuditFindings.loadKindStats(defaults: defaults)
        let (outcome, updatedKindStats) = LogAuditFindings.evaluate(
            anomalies: anomalies, events: examined, hours: hoursQueried, kindStats: kindStats, signer: signer
        )
        LogAuditFindings.saveKindStats(updatedKindStats, defaults: defaults)

        // Recorded here (not only by the scheduled guard) so every path that reaches this function leaves the same
        // durable trail, Pro or not. A new pattern cannot be flagged again once the baseline above absorbed it, and a
        // spike's lines are behind the cursor, so this is the only chance to keep what was found.
        if history != .firstScanQuiet, let record = LogAuditNotice.composeUnclassified(outcome.unclassified) {
            NotificationHistory.record(title: record.title, body: record.body, defaults: defaults)
        }
        if history != .leaveNoticesToNotifier, let notice = LogAuditNotice.compose(outcome.findings) {
            NotificationHistory.record(title: notice.title, body: notice.body, defaults: defaults)
        }
        return (anomalies, outcome)
    }

    /// Wall-clock ceiling for one `log show` query.
    static let logQueryTimeoutSeconds: TimeInterval = 60
    /// Output kept from one query (excess is drained and dropped).
    static let maxLogOutputBytes = 64 * 1024 * 1024

    /// Predicate targeting critical security subsystems and processes. The first part reads every line of the processes it
    /// names (the subsystems of macOS 26.6.2, checked in a VM: `com.apple.syspolicy.exec` for Gatekeeper's decisions,
    /// `com.apple.XProtectFramework.Plugin` for the Remediator's plug-ins; the names an earlier macOS used are kept, and
    /// read nothing where they do not exist); the rest
    /// (`LogAuditKind.predicateClauses(stage: .main)`) reads a line of authd, opendirectoryd, tccd and ReportCrash only when
    /// its message has a word of a rule, so the volume stays small. The kernel is read by `kernelLogPredicate`.
    /// macOS 26 (OpenSSH 10) writes the login lines from `sshd-session` instead of `sshd`, so both are listed (exact
    /// names: a prefix match would also pull in unrelated `sshd-*` helpers and their noise).
    static let securityLogPredicate = """
    process == "sudo" OR \
    process == "sshd" OR \
    process == "sshd-session" OR \
    process == "loginwindow" OR \
    subsystem == "com.apple.syspolicy.exec" OR \
    subsystem == "com.apple.security.syspolicy" OR \
    subsystem == "com.apple.XProtectFramework.Plugin" OR \
    subsystem == "com.apple.XProtectFramework.PluginService"
    """ + " OR " + LogAuditKind.predicateClauses(stage: .main).joined(separator: " OR ")

    /// The kernel stage: the kernel's and the disk daemon's lines that have a word of a rule (`LogAuditKind.otherRules`).
    static let kernelLogPredicate = LogAuditKind.predicateClauses(stage: .kernel).joined(separator: " OR ")

    /// A flag set from the watchdog's queue and read after the child has exited.
    private final class Flag {
        private let lock = NSLock()
        private var value = false
        func set() { lock.lock(); value = true; lock.unlock() }
        var isSet: Bool { lock.lock(); defer { lock.unlock() }; return value }
    }

    /// The audit's read: the main query, then the kernel stage over a shorter window (`kernelStageMaxHours`). The kernel's
    /// lines cost several times more to filter than the rest together, and a query that outlasts `logQueryTimeoutSeconds`
    /// is cut, so the kernel has a query of its own: a slow or failed stage leaves the main stage's events in place and
    /// says what was not read (`SecurityLogReadStatus`).
    private func fetchSecurityLogs(hours requested: Int) -> (events: [SecurityLogEvent], status: SecurityLogReadStatus) {
        // Defence in depth: never query more than 7 days, whatever the caller passed.
        let hours = min(max(requested, 1), 168)
        var (events, status) = runLogShow(predicate: Self.securityLogPredicate, hours: hours)
        status.hoursRequested = requested
        status.hoursQueried = hours

        let kernelHours = min(hours, Self.kernelStageMaxHours)
        let kernel = runLogShow(predicate: Self.kernelLogPredicate, hours: kernelHours)
        events += kernel.events
        status.timedOut = status.timedOut || kernel.status.timedOut
        status.outputTruncated = status.outputTruncated || kernel.status.outputTruncated
        if status.failureReason == nil { status.failureReason = kernel.status.failureReason; status.exitStatus = kernel.status.exitStatus }
        status.linesLossy += kernel.status.linesLossy
        status.linesUnparsable += kernel.status.linesUnparsable
        status.kernelStageHours = kernelHours < hours ? kernelHours : 0
        events.sort { $0.timestamp > $1.timestamp }
        status.eventsRead = events.count
        return (events, status)
    }

    /// Hours of the kernel stage at most. A 24-hour audit reads the kernel's last 6 hours; the scheduled audit (1 hour) is
    /// not cut. Measured in a VM (2026-11-18): the kernel's 5 words were the heaviest part of one query.
    static let kernelStageMaxHours = 6

    /// One `log show` over `hours` with `predicate`. `status.hoursRequested`/`hoursQueried` are the caller's.
    private func runLogShow(predicate: String, hours: Int) -> (events: [SecurityLogEvent], status: SecurityLogReadStatus) {
        var status = SecurityLogReadStatus()
        var results: [SecurityLogEvent] = []

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
        // Not read: a Pipe here would stop `log show` once 64 KB of its warnings were in it.
        process.standardError = FileHandle.nullDevice

        let timedOut = Flag()
        do {
            try process.run()

            // Hard ceiling so a wedged/very slow `log show` can't stall the caller: SIGTERM
            // at the deadline, SIGKILL shortly after. Killing the process closes its pipe, so
            // the read loop below ends.
            let watchdog = DispatchWorkItem {
                timedOut.set()
                ChildProcessTree.end(process, grace: 3)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + Self.logQueryTimeoutSeconds, execute: watchdog)

            // Bounded read: keep the newest `maxLogOutputBytes` (`log show` prints oldest first, so the oldest
            // chunks are dropped), keep draining so the child never blocks on a full pipe.
            let fileHandle = pipe.fileHandleForReading
            var chunks: [Data] = []
            var kept = 0
            var readFailed = false
            while true {
                let chunk: Data?
                do { chunk = try fileHandle.read(upToCount: 64 * 1024) } catch { readFailed = true; break }
                guard let chunk, !chunk.isEmpty else { break }
                chunks.append(chunk)
                kept += chunk.count
                while kept > Self.maxLogOutputBytes, let first = chunks.first {
                    chunks.removeFirst()
                    kept -= first.count
                    status.outputTruncated = true
                }
            }
            process.waitUntilExitWithoutRunLoop()
            watchdog.cancel()

            status.timedOut = timedOut.isSet
            if !status.timedOut && (readFailed || process.terminationStatus != 0) {
                status.failureReason = "exit_error"
                status.exitStatus = process.terminationStatus
            }

            var data = Data(capacity: kept)
            for chunk in chunks { data.append(chunk) }
            let decoded = decodeLogOutput(data, startsMidLine: status.outputTruncated)
            results = decoded.events
            status.linesLossy = decoded.linesLossy
            status.linesUnparsable = decoded.linesUnparsable
        } catch {
            status.failureReason = "launch_failed"
            // stderr, never stdout: in `RoamSwitchMCPServer` stdout IS the JSON-RPC channel,
            // so a stray print would corrupt the protocol stream.
            FileHandle.standardError.write(Data("[SecurityLogAuditor] Log query failed: \(error)\n".utf8))
        }

        // Sort descending by timestamp
        results.sort { $0.timestamp > $1.timestamp }
        status.eventsRead = results.count
        return (results, status)
    }

    /// Turns `log show --style ndjson` output into events, counting what it could not use. A line with bytes that
    /// are not valid UTF-8 is read with the bytes replaced; a line that looks like JSON but does not parse is
    /// counted and skipped (non-JSON header lines and events without a message are routine, not losses).
    /// `startsMidLine`: the data was cut at a byte cap, so its first fragment is not a whole line.
    func decodeLogOutput(_ data: Data, startsMidLine: Bool = false) -> (events: [SecurityLogEvent], linesLossy: Int, linesUnparsable: Int) {
        var events: [SecurityLogEvent] = []
        var lossy = 0
        var unparsable = 0
        var unreadableTimes = 0
        var lines = data.split(separator: 0x0A, omittingEmptySubsequences: true)
        if startsMidLine, !lines.isEmpty { lines.removeFirst() }
        for raw in lines {
            let line = Data(raw)
            let text: String
            if let decoded = String(data: line, encoding: .utf8) {
                text = decoded
            } else {
                text = String(decoding: line, as: UTF8.self)
                lossy += 1
            }
            switch parseNdjson(text) {
            case .event(let event):
                events.append(event)
                continue
            case .unreadableTime:
                unparsable += 1
                unreadableTimes += 1
                continue
            case .notAnEvent:
                break
            }
            if let first = line.first(where: { $0 != 0x20 && $0 != 0x09 && $0 != 0x0D }), first == UInt8(ascii: "{"),
               (try? JSONSerialization.jsonObject(with: line)) as? [String: Any] == nil {
                unparsable += 1
            }
        }
        if unreadableTimes > 0 {
            // stderr, never stdout: in `RoamSwitchMCPServer` stdout IS the JSON-RPC channel.
            FileHandle.standardError.write(Data("[SecurityLogAuditor] \(unreadableTimes) log lines have a time that cannot be read and were not used\n".utf8))
        }
        return (events, lossy, unparsable)
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
            || isKnownBenignCoreAudioHalNoise(event.message)
            || isKnownBenignApplicationCoalitionStateNoise(event.message)
            || isKnownBenignAppleRenderingFrameworkNoise(event.subsystem)
            || isKnownBenignSleepWakePowerNoise(event.message, subsystem: event.subsystem)
            || isKnownBenignLockscreenStatusWidgetNoise(event.message, subsystem: event.subsystem)
    }

    /// Known-benign sleep/wake/display-power lifecycle tracing —
    /// `com.apple.loginwindow.logging` is *not* a safe subsystem to exclude
    /// wholesale (it also carries `LWAuthServiceManager`/`LWDefaultScreenLockUI`,
    /// which are exactly the authentication/unlock-domain classes that must
    /// stay fully monitored), so this is scoped to a bounded set of specific
    /// power-lifecycle function-name prefixes plus the `ScreenSaverDaemon`
    /// class (idle-timer scheduling, not authentication — distinct from the
    /// screen-lock UI classes). Found 2026-09-11 live: `SleepWakeCallback_
    /// block_invoke` and a `ScreenSaverDaemon`-adjacent battery/Wi-Fi widget
    /// trace (see `isKnownBenignLockscreenStatusWidgetNoise`) were 3 of 10
    /// "new pattern" hits in one alert, both purely internal power-state
    /// bookkeeping.
    private static let benignPowerLifecyclePrefixes: [String] = [
        "SleepWakeCallback", "RegisterSleepWakeCallback",
        "LWDisplayDidWakeCallback", "LWDisplayWillSleepCallback",
        "PMDisplaySleepIsBlocked", "determineWakeIntervals", "logWakeIntervals",
        "-[ScreenSaverDaemon ",
    ]
    private static func isKnownBenignSleepWakePowerNoise(_ message: String, subsystem: String) -> Bool {
        guard subsystem == "com.apple.loginwindow.logging" else { return false }
        return benignPowerLifecyclePrefixes.contains { message.hasPrefix($0) }
    }

    /// Known-benign lock-screen status-bar widget lifecycle tracing (the
    /// Wi-Fi/Battery icons shown on the lock screen): loginwindow logs
    /// `"<numeric id>: <Class> <method> <pointer?>"` for each of these
    /// widgets' view-lifecycle events (`viewDidLoad`, `pause`, `_resume`,
    /// `dealloc`, `_updateStatus`, ...) — the same generic, non-security
    /// widget-lifecycle tracing convention `isKnownBenignApplicationCoalitionStateNoise`
    /// already excludes for `Application`/`ApplicationManager`, just a
    /// numeric-ID-prefixed variant instead of `-[Class selector:]`. Content
    /// is limited to class/method names and pointers — no network name,
    /// battery percentage, or other security-relevant detail is present.
    /// Scoped to `com.apple.loginwindow`'s `dflt` category, where a live
    /// 6-hour sample on this Mac was *entirely* this pattern. Found
    /// 2026-09-11 live: "150766294: Battery pause 0xbb1346120".
    private static let lockscreenStatusWidgetRegex = try! NSRegularExpression(pattern: #"^\d+: (WiFi|Battery|Status|UIController) "#)
    private static func isKnownBenignLockscreenStatusWidgetNoise(_ message: String, subsystem: String) -> Bool {
        guard subsystem == "com.apple.loginwindow" else { return false }
        let range = NSRange(message.startIndex..., in: message)
        return lockscreenStatusWidgetRegex.firstMatch(in: message, range: range) != nil
    }

    /// Known-benign rendering-framework internal diagnostics, excluded by
    /// `subsystem` identity rather than by message text — the unified log's
    /// `subsystem` field is set by the logging process itself, the same
    /// forgery-resistance property `process` has, so this is a provenance
    /// check, not a keyword guess. `loginwindow` hosts the lock-screen/
    /// wallpaper rendering pipeline, which drives three purely-graphical
    /// Apple frameworks with zero security semantics at any frequency:
    /// `com.apple.wallpaper` (wallpaper crossfade, logs an incrementing
    /// "Release Assertion N" per frame), `com.apple.coreanimation`
    /// ("CAMetalLayer ignoring invalid setDrawableSize ..." while a
    /// transitional layer is momentarily zero-sized), and
    /// `com.apple.avatarkit` (Memoji/wallpaper avatar rendering, "Error
    /// while writing subdiv data: <private>"). Found 2026-09-11 live on this
    /// Mac: a single wallpaper transition burst ~10-15 of these lines within
    /// the same millisecond, all flagged as a frequency spike even though
    /// the digit-masking fix already collapsed each into one template —
    /// three unrelated message shapes from one non-security cause, exactly
    /// the case a subsystem-identity rule handles in one place instead of
    /// enumerating each message text individually.
    private static func isKnownBenignAppleRenderingFrameworkNoise(_ subsystem: String) -> Bool {
        benignRenderingSubsystems.contains(subsystem)
    }

    private static let benignRenderingSubsystems: Set<String> = [
        "com.apple.wallpaper", "com.apple.coreanimation", "com.apple.avatarkit",
    ]

    /// Excludes *every* method-trace line loginwindow logs from its own
    /// `Application`/`ApplicationManager` objects, regardless of selector —
    /// a class-identity rule instead of yet another selector/keyword to
    /// enumerate. `loginwindow`'s `-[ClassName selector:] | detail` verbose
    /// method-tracing convention was never designed as a security signal;
    /// it's internal implementation-detail tracing, and different classes
    /// under it mean fundamentally different things. A 24h/16k-line sample
    /// of this Mac's own `process == "loginwindow"` stream (the same query
    /// `performAuditSync` issues) found `Application`/`ApplicationManager`
    /// alone behind 1,756 of these lines (23% of loginwindow's entire
    /// "Standard"-category volume) — 100% generic AppKit/LaunchServices app
    /// coalition/state bookkeeping (`kLSNotify*`, `setState:`,
    /// `handleCASEvent:withData:`), *zero* containing any
    /// authentication-adjacent keyword (password/unlock/biometric/
    /// keychain/credential/...). That's structurally different from the
    /// dozen or so other classes sharing this same trace convention
    /// (`LWScreenLock`, `LWAuthServiceManager`, `LWTouchIDLockScreen`,
    /// `LWPAMManager`, `SessionAgentCom`, ...), which the loginwindow
    /// codebase itself scopes to its actual authentication/session domain —
    /// `Application`/`ApplicationManager` are the two generic,
    /// non-loginwindow-specific classes loginwindow just happens to also
    /// drive while managing app coalitions during login/logout. Found
    /// 2026-09-11: `-[Application setState:]` and `-[ApplicationManager
    /// handleCASEvent:withData:] | kLSNotify...` flagged as 5 "new pattern"
    /// hits from one ordinary Microsoft Update Assistant launch — the third
    /// individually-enumerated exclusion in this area in as many days,
    /// which is what prompted digging for this class-level rule instead.
    private static func isKnownBenignApplicationCoalitionStateNoise(_ message: String) -> Bool {
        message.hasPrefix("-[Application ") || message.hasPrefix("-[ApplicationManager ")
    }

    /// Known-benign CoreAudio HAL (Hardware Abstraction Layer) internal
    /// trace logging — `HALC_ProxyIOContext`/`HALC_*` classes log their own
    /// C++ source file, line number, and method on every I/O
    /// resume/pause, which happens routinely (every audio-route change:
    /// waking, a Bluetooth device connecting, an app opening/closing an
    /// audio stream) and is reachable through `loginwindow` (which links
    /// CoreAudio for system sounds, so it matches this auditor's
    /// `process == "loginwindow"` predicate) with zero security relevance.
    /// `HALC_` is Apple's own fixed internal naming convention for this
    /// framework's classes, not attacker-influenced content. Found
    /// 2026-09-11: seven of ten anomalies in one notification were this
    /// single source, repeatedly triggering as a frequency spike as well
    /// as a new pattern — excluded entirely rather than just de-prioritized,
    /// since audio I/O churn has no security value at any frequency.
    private static func isKnownBenignCoreAudioHalNoise(_ message: String) -> Bool {
        message.contains("HALC_")
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

    /// How one ndjson line reads.
    enum NdjsonParse {
        case event(SecurityLogEvent)
        /// Valid JSON that is not an event the audit keeps (a process and a message no rule accepts).
        case notAnEvent
        /// An event whose `timestamp` cannot be read. It is not used: a time guessed as "now" would put an old line in the
        /// present (found 2026-11-18: every line of `log show --style ndjson` has `2026-11-18 00:53:31.749589+0000`, which
        /// an ISO 8601 reader refuses, so every event was dated now).
        case unreadableTime
    }

    /// The time of a line as `log show --style ndjson` writes it (`2026-11-18 00:53:31.749589+0000`: no `T`, the zone
    /// as `+0000`), and the ISO 8601 forms (with or without fractional seconds, `T`, `Z`) that earlier builds and test
    /// lines use. Nil when none fits.
    static func parseLogTimestamp(_ text: String) -> Date? {
        for formatter in timestampFormatters {
            if let date = formatter.date(from: text) { return date }
        }
        for options: ISO8601DateFormatter.Options in [[.withInternetDateTime, .withFractionalSeconds], [.withInternetDateTime]] {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = options
            if let date = iso.date(from: text) { return date }
        }
        return nil
    }

    /// Fixed locale and a numeric zone: the user's language and calendar do not change what the log wrote.
    private static let timestampFormatters: [DateFormatter] = ["yyyy-MM-dd HH:mm:ss.SSSSSSZ", "yyyy-MM-dd HH:mm:ssZ"].map { format in
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = format
        return f
    }

    /// `liveStream`: the line comes from `log stream` and is read the moment it is written, so a time that cannot be read is
    /// "now" and true (the Air-Gap and Gatekeeper notice of `RuntimeThreatContainmentManager`). A line read from `log show`
    /// has its own time, and one that cannot be read is not used.
    func parseNdjson(_ line: String, liveStream: Bool = false) -> NdjsonParse {
        guard let data = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .notAnEvent
        }

        let process = json["processImagePath"] as? String ?? json["process"] as? String ?? ""
        let procName = URL(fileURLWithPath: process).lastPathComponent
        let processPath = process.hasPrefix("/") ? process : ""
        let msg = json["eventMessage"] as? String ?? ""
        guard !msg.isEmpty else { return .notAnEvent }
        let subsystem = json["subsystem"] as? String ?? ""

        // What the line is: its category, its severity and the kind a person can judge (`LogAuditKind.classify`).
        guard let classified = LogAuditKind.classify(process: procName, subsystem: subsystem, message: msg) else {
            return .notAnEvent
        }
        let category = classified.category
        let severity = classified.severity
        let kind = classified.kind

        let date: Date
        if let parsed = Self.parseLogTimestamp(json["timestamp"] as? String ?? "") {
            date = parsed
        } else if liveStream {
            date = Date()
        } else {
            return .unreadableTime
        }

        // Redacted here — the single construction site for every
        // SecurityLogEvent — so the GUI table, the AI-consultation prompt,
        // the "copy report" clipboard flow, and the MCP JSON payload all see
        // a masked `message` with no separate redaction pass needed at each
        // of those call sites.
        return .event(SecurityLogEvent(
            timestamp: date,
            process: procName,
            category: category,
            severity: severity,
            message: SecretLeakScanning.redact(msg),
            subsystem: subsystem,
            processPath: processPath,
            kind: kind
        ))
    }

    /// Not `private`: `RuntimeThreatContainmentManager` shares this exact
    /// categorization so its autonomous Air-Gap trigger and this manual
    /// report always agree on what counts as a critical XProtect/Gatekeeper
    /// event. Nil for a line that is no event, or whose time cannot be read (see `parseNdjson`).
    func parseNdjsonLine(_ line: String, liveStream: Bool = false) -> SecurityLogEvent? {
        if case .event(let event) = parseNdjson(line, liveStream: liveStream) { return event }
        return nil
    }
}
