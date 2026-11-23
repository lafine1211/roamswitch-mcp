// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.2.6 (build 230).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// The kinds of log line a person can judge and act on. The scheduled log audit notifies about a log pattern only when
/// its line belongs to one of these kinds; a pattern whose kind cannot be named is recorded to the notification history
/// without a notice (owner decision 2026-11-18: a notice the reader cannot judge only teaches them to ignore notices).
///
/// The classification is fixed rules over what the unified log says about itself: the process, the subsystem and the
/// message. No model chooses it, and no statistic raises or lowers a kind's severity.
///
/// The wording of every rule was checked against the real unified log of a disposable macOS 26.6.2 VM (2026-11-18):
/// a 40-minute idle log, and the lines a wrong sudo password, a wrong ssh password, `tccutil reset`, an unsigned
/// program, a crashing process and a wrong dscl password write. Kinds whose words could not be confirmed there are
/// not in this list (see `docs/RELEASE_DOC_UPDATES_log_audit_judgeable.md`): XProtect detections (the engine's lines are
/// mostly `<private>`; a detection has its own path through Endpoint Security), privacy-permission refusals (50 lines in
/// 40 idle minutes, most of them preflight checks), Wi-Fi authentication failures (no radio in the VM) and loginwindow
/// authentication failures (no line of loginwindow that says so was found).
public enum LogAuditKind: String, CaseIterable, Codable {
    case sudoFailure
    case remoteLoginFailure
    case remoteLoginAccepted
    case localAuthFailure
    case privilegeEscalation
    case tccChanged
    case gatekeeperBlock
    case kernelWarning
    case diskFailure
    case appCrashLoop

    /// Fixed per kind. `info` is recorded to the history only; `warning` and `critical` are delivered as a notice.
    /// (A kernel line that says `panic` is `critical`: see `OtherRule`.)
    public var severity: LogEventSeverity {
        switch self {
        case .sudoFailure, .remoteLoginFailure: return .critical
        case .remoteLoginAccepted, .localAuthFailure, .tccChanged, .kernelWarning,
             .diskFailure, .appCrashLoop: return .warning
        // History only (owner, 2026-11-20): the line does not name the program and does not say it was stopped, so a person cannot
        // judge it. A Mac that builds and tests writes these all day.
        case .privilegeEscalation, .gatekeeperBlock: return .info
        }
    }

    /// A kind that is a series by definition: one crash is not a crash loop.
    public var minimumCount: Int {
        switch self {
        case .appCrashLoop: return LogAuditKind.crashLoopThreshold
        default: return 1
        }
    }

    /// Crashes of one app inside one scan window before they count as a series.
    public static let crashLoopThreshold = 3

    /// The `log show` predicate that lists the lines of this kind (shown to the reader as the way to look).
    public var checkPredicate: String {
        switch self {
        case .sudoFailure: return "process == \"sudo\" AND eventMessage CONTAINS[c] \"COMMAND=\""
        case .remoteLoginFailure, .remoteLoginAccepted: return "process == \"sshd\" OR process == \"sshd-session\""
        case .localAuthFailure: return "process == \"authd\" OR process == \"opendirectoryd\""
        case .privilegeEscalation: return "process == \"sudo\" OR process == \"authd\""
        case .tccChanged: return "process == \"tccd\" AND eventMessage CONTAINS[c] \"TCCAccessResetInternal\""
        case .gatekeeperBlock: return "subsystem == \"com.apple.syspolicy.exec\""
        case .kernelWarning: return "process == \"kernel\" AND (eventMessage CONTAINS[c] \"panic(cpu\" OR eventMessage CONTAINS[c] \"watchdog\")"
        case .diskFailure: return "(process == \"kernel\" OR process == \"diskarbitrationd\") AND (eventMessage CONTAINS[c] \"I/O error\" OR eventMessage CONTAINS[c] \"is corrupt\")"
        case .appCrashLoop: return "process == \"ReportCrash\""
        }
    }

    /// The command the notice names, as the reader would type it.
    public var checkCommand: String {
        "log show --predicate '\(checkPredicate)' --last 1h"
    }

    // MARK: - What a line is

    /// How one line is read: the kind (nil: a line the audit keeps as a statistic only), the category it is listed under
    /// and its severity.
    struct Classified: Equatable {
        let kind: LogAuditKind?
        let category: LogEventCategory
        let severity: LogEventSeverity
    }

    /// Reads one line by its process (`procName`: the last path component), subsystem and message. Nil: the line is no event
    /// at all. A line of sudo, ssh, syspolicy, XProtect or loginwindow is always an event (a statistic at least); a
    /// line of any other process is one only when a rule of `otherRules` accepts it.
    static func classify(process procName: String, subsystem: String, message: String) -> Classified? {
        if procName.contains("sudo") {
            let kind = sudoKind(message)
            return Classified(kind: kind, category: .sudo, severity: kind?.severity ?? .info)
        }
        if procName.contains("sshd") {
            let kind = sshKind(message, subsystem: subsystem)
            return Classified(kind: kind, category: .ssh, severity: kind?.severity ?? .info)
        }
        if procName.contains("syspolicy") || subsystem.hasPrefix("com.apple.syspolicy") || subsystem == "com.apple.security.syspolicy" {
            // XProtect's verdict is written by syspolicyd, in Gatekeeper's subsystem: read it before Gatekeeper's own decision
            // (a detection does not write `GK eval - was allowed: 0`, so the two never double up).
            if XProtectScanLine.parse(message) != nil {
                return Classified(kind: nil, category: .xprotect, severity: .critical)
            }
            let kind = gatekeeperKind(message)
            return Classified(kind: kind, category: .gatekeeper, severity: kind?.severity ?? .info)
        }
        if procName.contains("XProtect") || subsystem.hasPrefix("com.apple.XProtectFramework") {
            // Only the engine's own words for a finding. "malware" alone is in every scan line ("performing a direct
            // malware and dylib scan"); "scan" and "Forwarding detection" are not findings either. The audit lists the
            // finding; the notice and the Air-Gap are `RuntimeThreatContainmentManager`'s (see `XProtectStreamPolicy`).
            // A real detection is the `XPScan` line above, which has neither word. These two words are for a Remediator's own
            // lines and have not been seen in a real log (an Apple rule match on a VM wrote no such line): they are kept, and
            // they are not enough alone for anything but the notice. A line that Apple hid (`<private>`) says nothing.
            let lower = message.lowercased()
            let found = (lower.contains("remediated") || lower.contains("infected")) && !message.contains("<private>")
            return Classified(kind: nil, category: .xprotect, severity: found ? .critical : .info)
        }
        if procName.contains("loginwindow") {
            // No line of loginwindow that says a login failed was found in a real log; its words ("fail", "reject")
            // are in unrelated lines. It stays a statistic.
            return Classified(kind: nil, category: .auth, severity: .info)
        }
        if let other = classifyOther(process: procName, message: message) {
            return Classified(kind: other.kind, category: other.category, severity: other.severity)
        }
        return nil
    }

    /// A refusal by sudo itself. sudo writes one line per refused attempt, with the command on it
    /// (`admin : 1 incorrect password attempt ; PWD=… ; USER=root ; COMMAND=…`), and these four are its own words. The
    /// word "fail" alone is not a sign: `COMMAND=` also carries any command name (`fail2ban-client`).
    static let sudoRefusalPhrases = ["incorrect password attempt", "user not in sudoers", "a password is required", "command not allowed"]

    static func isSudoAuthFailure(_ message: String) -> Bool {
        let lower = message.lowercased()
        return sudoRefusalPhrases.contains { lower.contains($0) }
    }

    /// sudo logs a run that worked only when `/etc/sudoers` has `log_allowed`; macOS ships `Defaults !log_allowed`, so on
    /// a default Mac this never matches. A line with `TTY=` and `COMMAND=` and none of the refusal words is such a run.
    static func sudoKind(_ message: String) -> LogAuditKind? {
        if isSudoAuthFailure(message) { return .sudoFailure }
        return message.contains("TTY=") && message.contains("COMMAND=") ? .privilegeEscalation : nil
    }

    /// sshd's own wording, from lines with no subsystem (the helper lines the login writes have one, or are generic
    /// directory-service chatter). One refused attempt writes up to four lines ("Invalid user", "Failed …", "error: PAM:
    /// authentication error", "Connection closed by authenticating user … [preauth]"); only the `Failed …` line, which
    /// every refused attempt has once, is counted. A closed connection before authentication ends is not a failure
    /// here: a scanner writes it too, so the frequency baseline of the lines is what shows it.
    static func sshKind(_ message: String, subsystem: String) -> LogAuditKind? {
        guard subsystem.isEmpty else { return nil }
        let text = message.trimmingCharacters(in: .whitespaces)
        if text.hasPrefix("Failed password for") || text.hasPrefix("Failed keyboard-interactive") || text.hasPrefix("Failed publickey") {
            return .remoteLoginFailure
        }
        if text.hasPrefix("Accepted ") { return .remoteLoginAccepted }
        return nil
    }

    /// Gatekeeper's decision line: `GK eval - was allowed: 0, show prompt: 1`. The error line
    /// (`GatekeeperPolicyScanError`) and the prompt line come with it and are not counted again.
    static func gatekeeperKind(_ message: String) -> LogAuditKind? {
        message.lowercased().contains("gk eval - was allowed: 0") ? .gatekeeperBlock : nil
    }

    // MARK: - Processes beyond the five the audit always reads

    /// The queries of the audit: `main` is one `log show` with the five always-read processes and the cheap rules; `kernel`
    /// is a second one with the kernel's lines, which cost several times more to filter, over a shorter window.
    enum Stage { case main, kernel }

    /// A line from a process the audit does not read in full: it is an event only when it matches a rule here, so the
    /// query stays small (`predicateClauses` is built from the same rules, so the query can never be narrower than
    /// the classification). `all`: every word must be in the message; `any`: at least one (empty = none needed).
    /// Words are lower case and matched without regard to case.
    struct OtherRule {
        let processes: [String]
        let all: [String]
        let any: [String]
        let kind: LogAuditKind
        let category: LogEventCategory
        /// The kind's severity unless a rule overrides it (the kernel's `panic`).
        let severity: LogEventSeverity?
        let stage: Stage
    }

    static let otherRules: [OtherRule] = [
        // authd: a refused password (`failed to authenticate user`) and the decision that follows (`Evaluate denied`).
        // `Sandbox denied authorizing right` is an app refused by its sandbox, not a person's authentication.
        OtherRule(processes: ["authd"], all: [], any: ["failed to authenticate", "evaluate denied"],
                  kind: .localAuthFailure, category: .auth, severity: nil, stage: .main),
        // opendirectoryd writes 4 to 5 lines for one refused password; `Authentication failed for` with the credentials
        // error is the one line of them. `ODErrorCredentialsMethodNotSupported` is a routine line after boot.
        OtherRule(processes: ["opendirectoryd"], all: ["authentication failed for", "oderrorcredentialsinvalid"], any: [],
                  kind: .localAuthFailure, category: .auth, severity: nil, stage: .main),
        // The administrator right was granted: an app or command runs with administrator rights.
        OtherRule(processes: ["authd"], all: [], any: ["succeeded authorizing right 'system.privilege.admin'"],
                  kind: .privilegeEscalation, category: .auth, severity: nil, stage: .main),
        // Privacy permissions: the request line that names the service and the client (`tccutil reset`, an app that resets).
        OtherRule(processes: ["tccd"], all: ["request_msg:", "tccaccessresetinternal"], any: [],
                  kind: .tccChanged, category: .system, severity: nil, stage: .main),
        // Crashes: one line per crash, `Formulating fatal 309 report for corpse[PID] <process>`. The process name stays
        // in the template, the numbers are masked, so a series of one program counts as one pattern.
        OtherRule(processes: ["ReportCrash"], all: ["report for corpse"], any: [],
                  kind: .appCrashLoop, category: .system, severity: nil, stage: .main),
        // Kernel: concrete forms only. "panic" alone is in `panicmedic`, `IOExtensiblePaniclog`; "watchdog" alone is in
        // `watchdog expired for approval entry` (a privacy-permission prompt that timed out).
        OtherRule(processes: ["kernel"], all: [], any: ["panic(cpu", "kernel panic"],
                  kind: .kernelWarning, category: .system, severity: .critical, stage: .kernel),
        OtherRule(processes: ["kernel"], all: ["watchdog"], any: ["watchdog timeout", "failed to check in"],
                  kind: .kernelWarning, category: .system, severity: nil, stage: .kernel),
        // Disk and file system: concrete forms (`corruptedStateDetected=NO` is a status line). "unrecoverable" alone is not one: the
        // kernel writes `AMFI: '<path>': Unrecoverable CT signature issue, bailing out.` for every unsigned or ad hoc program that is
        // run (a build, a test), and that was reported as a disk error with First Aid advice (2026-11-19).
        OtherRule(processes: ["kernel", "diskarbitrationd"], all: [],
                  any: ["i/o error", "is corrupt", "unrecoverable read", "unrecoverable write", "unrecoverable media", "unrecoverable medium", "unrecoverable disk"],
                  kind: .diskFailure, category: .system, severity: nil, stage: .kernel),
    ]

    /// What `classify` gives a line from a process outside the five it always reads: nil when no rule matches.
    static func classifyOther(process: String, message: String) -> (kind: LogAuditKind, category: LogEventCategory, severity: LogEventSeverity)? {
        let lower = message.lowercased()
        for rule in otherRules where rule.processes.contains(process) {
            guard rule.all.allSatisfy({ lower.contains($0) }) else { continue }
            guard rule.any.isEmpty || rule.any.contains(where: { lower.contains($0) }) else { continue }
            return (rule.kind, rule.category, rule.severity ?? rule.kind.severity)
        }
        return nil
    }

    /// `log show` clauses for the rules of one stage, joined by OR: a process and the words of its rules. The word lists
    /// are the rules' own, so a line a rule would accept is a line the query returns.
    static func predicateClauses(stage: Stage) -> [String] {
        var byProcess: [String: [OtherRule]] = [:]
        var order: [String] = []
        for rule in otherRules where rule.stage == stage {
            for p in rule.processes {
                if byProcess[p] == nil { order.append(p) }
                byProcess[p, default: []].append(rule)
            }
        }
        func contains(_ word: String) -> String { "eventMessage CONTAINS[c] \"\(word)\"" }
        return order.map { process in
            let rules = byProcess[process] ?? []
            let alternatives = rules.map { rule -> String in
                var parts = rule.all.map(contains)
                if !rule.any.isEmpty { parts.append("(" + rule.any.map(contains).joined(separator: " OR ") + ")") }
                return parts.isEmpty ? "TRUEPREDICATE" : "(" + parts.joined(separator: " AND ") + ")"
            }
            return "(process == \"\(process)\" AND (" + alternatives.joined(separator: " OR ") + "))"
        }
    }
}

/// XProtect's verdict on a file as Gatekeeper's `syspolicyd` writes it (checked on a macOS 26.6.2 VM with files that match XProtect's
/// own rules, 2026-11-18; the process is `syspolicyd`, the subsystem `com.apple.syspolicy.exec`, the level Info):
///
///     GK Xprotect results: PST: (path: …), (team: (null)), (id: (null)), (bundle_id: (null)), XPScan: 11,279035629968643688,
///         2026-11-18 03:45:37 +0000,MACOS.644e18d,1ED79000-6E8D-4D08-BE52-646441233660,file:///tmp/T5.app/Contents/MacOS/t
///
/// The fields after `XPScan:` are the result code, an id, the time, the malware family, a UUID and the file as a URL (the URL is last
/// because it may hold commas). The result code is `0` and the family and UUID are `(null)` for a clean file. Neither `remediated`
/// nor `infected` is in a real detection. One detection writes this line once, then `GK scan complete`, `Evaluating blocked code`,
/// `Attempting to move malware to trash` and `Prompt shown`; only this line is read, so one detection is one finding.
struct XProtectScanLine: Equatable {
    let family: String
    /// The file, as the log gives it (`file:///…`).
    let path: String

    private static let pattern = try! NSRegularExpression(
        pattern: #"XPScan: (\d+),(\d+),(\d{4}-\d{2}-\d{2} [0-9:]+ [+-]\d{4}),([^,]+),([0-9A-Fa-f-]{36}),(.*)$"#)

    /// The detection in `message`, or nil: not this line, or a clean file (result code 0, family `(null)`).
    static func parse(_ message: String) -> XProtectScanLine? {
        guard message.contains("GK Xprotect results:"), message.contains("XPScan:") else { return nil }
        let range = NSRange(message.startIndex..., in: message)
        guard let m = pattern.firstMatch(in: message, range: range), m.numberOfRanges == 7 else { return nil }
        func field(_ i: Int) -> String { Range(m.range(at: i), in: message).map { String(message[$0]) } ?? "" }
        let family = field(4).trimmingCharacters(in: .whitespaces)
        guard field(1) != "0", !family.isEmpty, family != "(null)" else { return nil }
        return XProtectScanLine(family: family, path: field(6).trimmingCharacters(in: .whitespaces))
    }
}
