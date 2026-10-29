// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.13 (build 192).
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

    public init(timestamp: Date, process: String, category: LogEventCategory, severity: LogEventSeverity, message: String, subsystem: String = "") {
        self.timestamp = timestamp
        self.process = process
        self.category = category
        self.severity = severity
        self.message = message
        self.subsystem = subsystem
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
    /// Events parsed from the output.
    public var eventsRead = 0

    public init() {}

    /// Nothing could be read: the audit says nothing about the log.
    public var unreadable: Bool { eventsRead == 0 && (failureReason != nil || timedOut) }
    public var windowClamped: Bool { hoursRequested != 0 && hoursRequested != hoursQueried }
    /// Part of the log was not examined.
    public var limited: Bool { !unreadable && (failureReason != nil || timedOut || outputTruncated) }
    public var skippedAnything: Bool { unreadable || limited || windowClamped || linesLossy > 0 || linesUnparsable > 0 }

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
                out.append(String(format: loc("ログを読めませんでした(%d 秒以内に読み終えられませんでした)。「問題なし」という意味ではありません。"), seconds))
            } else {
                out.append(loc("ログを読めませんでした(log コマンドがエラーで終了しました)。「問題なし」という意味ではありません。"))
            }
        } else {
            if timedOut {
                out.append(String(format: loc("ログの取得が %d 秒の制限で止まったため、途中までを調べました。"), seconds))
            } else if failureReason != nil {
                out.append(loc("ログの取得が途中でエラーになったため、途中までを調べました。"))
            }
            if outputTruncated {
                out.append(String(format: loc("ログが大きいため、新しい側の約 %d MB だけを調べました(古いログは含まれません)。"),
                                  SecurityLogAuditor.maxLogOutputBytes / (1024 * 1024)))
            }
        }
        if windowClamped {
            out.append(String(format: loc("指定の %d 時間は範囲外のため、直近 %d 時間を調べました。"), hoursRequested, hoursQueried))
        }
        if linesLossy > 0 {
            out.append(String(format: loc("読めない文字を含む行が %d 件ありました(文字を置き換えて調べました)。"), linesLossy))
        }
        if linesUnparsable > 0 {
            out.append(String(format: loc("解析できなかった行が %d 件ありました。"), linesUnparsable))
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
    /// The subset of `templateAnomalies` whose example line came from an event
    /// with a non-`info` severity (failed sudo/ssh/login, Gatekeeper denial,
    /// XProtect hit, ...). Only these may notify or land in the notification
    /// history; the rest stay visible in the audit view but never page
    /// (alert-fatigue fix, 2026-09-30).
    public var notifiableTemplateAnomalies: [LogTemplateAnomaly] = []
    /// What the log read could not deliver (see `SecurityLogReadStatus`).
    public var readStatus = SecurityLogReadStatus()

    /// Nothing found in the log. A log that could not be read is never clean: it says nothing.
    public var isClean: Bool {
        sudoFailures == 0 && gatekeeperBlocks == 0 && xprotectDetections == 0 && !readStatus.unreadable
    }
}

final class SecurityLogAuditor {
    static let shared = SecurityLogAuditor()

    /// App-side asynchronous audit: records what the read could not deliver in the reader health.
    func performAudit(timeWindowHours: Int = 24, completion: @escaping (SecurityLogAuditReport) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let report = self.buildReport(timeWindowHours: timeWindowHours)
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
    func performAuditSync(timeWindowHours: Int = 24, recordHealth: Bool = false) -> SecurityLogAuditReport {
        let report = buildReport(timeWindowHours: timeWindowHours)
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
                h.setScanResult(filesUnreadable: 0, foldersUnreadable: 0, filesTruncated: status.limited ? 1 : 0, now: now)
            }
            h.addDropped(status.linesUnparsable, now: now)
        }
    }

    private func buildReport(timeWindowHours: Int) -> SecurityLogAuditReport {
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

        // `isNew` anomalies are a one-shot detection — once `saveBaseline`
        // above absorbs the template into `known`, it structurally can
        // never be flagged again (see `LogTemplateAnalyzer.analyze`'s doc
        // comment), so this is the only chance to keep a durable record of
        // it. Found from a live user report: the "テンプレート異常" count
        // dropping from 1 back to 0 on the next scan/reopen looked like the
        // anomaly had vanished with no way to look back at what it was.
        // Recorded here (this function, not `ScheduledLogAuditGuard`) so it
        // covers every path that reaches `buildReport` — the audit window's
        // own manual rescan included, not just the scheduled background
        // scan — and unconditionally (unlike `SecurityNotifier
        // .sendThreatAlert`, this isn't Pro-gated): a Free user gets the
        // same durable record, just without the live banner/sound.
        // Only anomalies whose source line was itself a warning/critical
        // security event may notify or enter the history. Everything else the
        // template analyzer flags (loginwindow/syspolicy narration, XPC
        // teardown, app-group container lookups) is routine OS chatter that
        // turned this into a boy-who-cried-wolf alert; it stays in the audit
        // view's `templateAnomalies`.
        let relevantMessages = Set(newSinceCursor.filter { $0.severity != .info }.map(\.message))
        let notifiable = anomalies.filter { relevantMessages.contains($0.example) }
        for anomaly in notifiable where anomaly.isNew {
            NotificationHistory.record(
                title: "🧩 " + loc("新規ログパターンを検出"),
                body: anomaly.example
            )
        }
        // Frequency spikes were deliberately NOT recorded here for a long
        // time (they can recur across a template's first few runs while its
        // own baseline is still maturing, unlike `isNew`'s one-shot nature),
        // on the assumption a spike would still be visible afterward via
        // this same `buildReport`'s own `templateAnomalies` output. That
        // assumption is false: `lastProcessedMessage` above already
        // advanced past every line this spike was computed from, and
        // `updatedHistory` already folded its count into the template's
        // mean/stddev — so the *next* call to `buildReport` (whether the
        // next scheduled scan or a human opening the audit view moments
        // later) can structurally never see these same lines again, let
        // alone re-flag them. A live user report: `ScheduledLogAuditGuard`
        // fired a spike notification, and opening the audit detail view
        // right after showed "no anomalies detected" with no way to look
        // back at what had just been flagged. Recording here (a handful of
        // near-duplicate entries while a template's baseline matures, at
        // most `LogTemplateAnalyzer.minObservationsForOwnBaseline` of them)
        // is a better trade than a notification with zero durable trail.
        for anomaly in notifiable where !anomaly.isNew {
            NotificationHistory.record(
                title: "📈 " + String(format: loc("ログの発生頻度が急増 (z=%.1f)"), anomaly.zScore),
                body: anomaly.example
            )
        }

        var report = SecurityLogAuditReport(
            auditDate: Date(),
            timeWindowHours: readStatus.hoursQueried,
            totalEvents: events.count,
            sudoFailures: sudoFails,
            sshAttempts: sshCount,
            gatekeeperBlocks: gkBlocks,
            xprotectDetections: xpCount,
            events: events,
            templateAnomalies: anomalies,
            notifiableTemplateAnomalies: notifiable
        )
        report.readStatus = readStatus
        return report
    }

    /// Wall-clock ceiling for one `log show` query.
    static let logQueryTimeoutSeconds: TimeInterval = 60
    /// Output kept from one query (excess is drained and dropped).
    static let maxLogOutputBytes = 64 * 1024 * 1024

    /// Predicate targeting critical security subsystems and processes. macOS 26 (OpenSSH 10) writes the login lines
    /// from `sshd-session` instead of `sshd`, so both are listed (exact names: a prefix match would also pull in
    /// unrelated `sshd-*` helpers and their noise).
    static let securityLogPredicate = """
    process == "sudo" OR \
    process == "sshd" OR \
    process == "sshd-session" OR \
    process == "loginwindow" OR \
    subsystem == "com.apple.security.syspolicy" OR \
    subsystem == "com.apple.XProtectFramework.PluginService" OR \
    process == "XProtectRemediator"
    """

    /// A flag set from the watchdog's queue and read after the child has exited.
    private final class Flag {
        private let lock = NSLock()
        private var value = false
        func set() { lock.lock(); value = true; lock.unlock() }
        var isSet: Bool { lock.lock(); defer { lock.unlock() }; return value }
    }

    private func fetchSecurityLogs(hours requested: Int) -> (events: [SecurityLogEvent], status: SecurityLogReadStatus) {
        var status = SecurityLogReadStatus()
        var results: [SecurityLogEvent] = []

        let predicate = Self.securityLogPredicate

        // Defence in depth: never query more than 7 days, whatever the caller passed.
        let hours = min(max(requested, 1), 168)
        status.hoursRequested = requested
        status.hoursQueried = hours

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

        let timedOut = Flag()
        do {
            try process.run()

            // Hard ceiling so a wedged/very slow `log show` can't stall the caller: SIGTERM
            // at the deadline, SIGKILL shortly after. Killing the process closes its pipe, so
            // the read loop below ends.
            let pid = process.processIdentifier
            let watchdog = DispatchWorkItem {
                timedOut.set()
                process.terminate()
                DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                    if process.isRunning { kill(pid, SIGKILL) }
                }
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
            if let event = parseNdjsonLine(text) {
                events.append(event)
                continue
            }
            if let first = line.first(where: { $0 != 0x20 && $0 != 0x09 && $0 != 0x0D }), first == UInt8(ascii: "{"),
               (try? JSONSerialization.jsonObject(with: line)) as? [String: Any] == nil {
                unparsable += 1
            }
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
        let subsystem = json["subsystem"] as? String ?? ""

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
            message: SecretLeakScanning.redact(msg),
            subsystem: subsystem
        )
    }
}
