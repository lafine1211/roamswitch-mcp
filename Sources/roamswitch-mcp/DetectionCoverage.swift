// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.12.8 (build 170).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// What RoamSwitch can and cannot see, per MITRE ATT&CK technique, for the techniques an attacker uses to
/// weaken, evade or outlast a Mac's defenses (plus a few neighbours the code already maps).
///
/// This is a self-check, not an attack: nothing here runs, simulates or reproduces an evasion. It exists so
/// a person (or an AI agent triaging for them) can tell "RoamSwitch saw nothing" apart from "RoamSwitch
/// cannot see this". Windows-only evasion (AMSI or ETW patching, ScareCrow-style loaders) has no Mac
/// counterpart and is not listed.
///
/// Every `detects` and `partial` entry is backed by code that was read when the entry was written, and the
/// file it lives in is named in the comment above the entry. The tests check the machine-checkable half: each
/// guard id exists in the guard-status vocabulary (`get_guard_status`), each audit check id exists in the
/// security audit, and (app tests) each exec rule id exists in `ExecRuleID` with the technique the rule
/// itself reports. An entry that cannot be backed is `none` with the limit stated, never rounded up.
///
/// The assessment is RoamSwitch's own. `detects` means a rule exists for the technique's main form, not
/// that every variant is caught; the blind spot says what is left.
enum DetectionCoverage {

    enum Coverage: String, Codable, Equatable { case detects, partial, none }

    struct Source: Codable, Equatable {
        /// `guard` (an id from `get_guard_status`), `exec_rule` (a process-exec correlation rule),
        /// `audit_check` (a `get_security_report` checkId) or `feature` (always-on code with no toggle).
        let kind: String
        let id: String
    }

    struct Entry: Equatable {
        let technique: String
        let name: String
        let coverage: Coverage
        let sources: [Source]
        let blindSpot: String
    }

    private static func guardSource(_ id: String) -> Source { Source(kind: "guard", id: id) }
    private static func rule(_ id: String) -> Source { Source(kind: "exec_rule", id: id) }
    private static func check(_ id: String) -> Source { Source(kind: "audit_check", id: id) }
    private static func feature(_ id: String) -> Source { Source(kind: "feature", id: id) }

    /// Features with no setting of their own, so their running state cannot be read from here.
    static let knownFeatures: Set<String> = ["watchdog"]

    static let entries: [Entry] = [
        // T1562.001. RoamSwitchWatchdog/WatchdogManager.swift: restarts the app after an unexpected exit
        // (handleApplicationDidTerminate -> handleAppCrash) and shows a notification.
        Entry(technique: "T1562.001", name: "Impair Defenses: Disable or Modify Tools", coverage: .partial,
              sources: [feature("watchdog")],
              blindSpot: "Covers only an unexpected exit of the RoamSwitch app itself, which is restarted with a notification. It says nothing about other security tools being disabled."),
        // T1562.004. SecurityHealthChecker.swift host_firewall / MCPResponseFormatting.configOnlyCaveat: the
        // audit reports RoamSwitch's protection level, not a measurement of the macOS firewall.
        Entry(technique: "T1562.004", name: "Impair Defenses: Disable or Modify System Firewall", coverage: .none,
              sources: [],
              blindSpot: "RoamSwitch applies its own firewall rules, but its audit reports RoamSwitch's protection level, not the macOS firewall, so a change made outside RoamSwitch is not detected."),
        Entry(technique: "T1562.006", name: "Impair Defenses: Indicator Blocking", coverage: .none,
              sources: [],
              blindSpot: "No dedicated detection for log, event or telemetry sources being blocked or starved."),
        // T1070.002. SecurityLogAuditor.swift reads logs for anomalies; nothing watches the logs themselves.
        Entry(technique: "T1070.002", name: "Indicator Removal: Clear Linux or Mac System Logs", coverage: .none,
              sources: [],
              blindSpot: "System logs are read for the log audit, but their deletion or truncation is not detected."),
        // T1070.003. ClickFixGuard.swift reads ~/.zsh_history and ~/.bash_history for pasted commands only.
        Entry(technique: "T1070.003", name: "Indicator Removal: Clear Command History", coverage: .none,
              sources: [],
              blindSpot: "The shell history is read by the ClickFix guard to find pasted commands, but clearing or disabling the history is not detected."),
        // T1553.001. Shared/ExecCorrelationRules.swift rule 5 (xattr -d/-c com.apple.quarantine, then an exec
        // under that path within a window); SecurityHealthChecker.swift gatekeeper_app_verification.
        Entry(technique: "T1553.001", name: "Subvert Trust Controls: Gatekeeper Bypass", coverage: .partial,
              sources: [guardSource("execRecorder"), rule("exec.quarantine_stripped_then_exec"), check("gatekeeper_app_verification")],
              blindSpot: "The rule needs the exec recorder (Pro, off by default) and fires only when something under the path is run shortly after its quarantine flag was removed. Gatekeeper being switched off is reported by the audit check when it is run."),
        // T1574.006. Shared/ExecCorrelationRules.swift rule dyldInsertLibraries: DYLD_INSERT_LIBRARIES on the
        // exec of a non-Apple-signed binary (ExecEventRecord.dyldInsertLibraries).
        Entry(technique: "T1574.006", name: "Hijack Execution Flow: Dynamic Linker Hijacking", coverage: .partial,
              sources: [guardSource("execRecorder"), rule("exec.dyld_insert_libraries")],
              blindSpot: "Looks at the environment of each exec only. A library injected into an already running process is not seen, and processes with the hardened runtime ignore the variable anyway."),
        Entry(technique: "T1574.004", name: "Hijack Execution Flow: Dylib Hijacking", coverage: .none,
              sources: [],
              blindSpot: "A planted or missing dylib that an app loads by search path is not checked."),
        Entry(technique: "T1036", name: "Masquerading", coverage: .none,
              sources: [],
              blindSpot: "A name is not compared with what the binary really is. Fake launch items are caught through their signature and interpreter use (see T1543), not through the name."),
        Entry(technique: "T1055", name: "Process Injection", coverage: .none,
              sources: [],
              blindSpot: "Code injected into a running process is not detected."),
        // T1027.010. Shared/ExecCorrelationRules.swift rules interpreterInlineObfuscated (python/perl/ruby/php/
        // pwsh one-liners with base64/eval plus a download) and osascriptObfuscated.
        Entry(technique: "T1027.010", name: "Obfuscated Files or Information: Command Obfuscation", coverage: .partial,
              sources: [guardSource("execRecorder"), rule("exec.interpreter_inline_obfuscated"), rule("exec.osascript_obfuscated")],
              blindSpot: "Only obfuscated one-liners given on the command line are examined. Obfuscated script files and packed or encrypted binaries are not analysed by the exec recorder."),
        // T1059.002. Shared/ExecCorrelationRules.swift rule 4: osascript -e that combines shell execution with
        // base64 or eval.
        Entry(technique: "T1059.002", name: "Command and Scripting Interpreter: AppleScript", coverage: .partial,
              sources: [guardSource("execRecorder"), rule("exec.osascript_obfuscated")],
              blindSpot: "Only an inline osascript -e that combines shell execution with base64 or eval is flagged. Ordinary AppleScript is not."),
        // T1059.004. Shared/ExecCorrelationRules.swift rules 1 and 3: a shell or interpreter started by a
        // browser, Office or mail app; a download piped into a shell together with an aggravating fact.
        Entry(technique: "T1059.004", name: "Command and Scripting Interpreter: Unix Shell", coverage: .partial,
              sources: [guardSource("execRecorder"), rule("exec.shell_from_app"), rule("exec.pipe_to_shell")],
              blindSpot: "Flags a shell started by a browser, Office or mail app, and a download piped into a shell only together with an aggravating fact. A plain curl | sh typed in a terminal looks like an official installer and is not flagged on its own."),
        // T1543.001 / T1543.004. RoamSwitch/PersistenceMonitorGuard.swift (FSEvents on LaunchAgent and
        // LaunchDaemon plists; flags a bare interpreter or an unsigned program) and Shared/ExecCorrelationRules.swift
        // rule 6 (an unsigned or ad-hoc binary started by launchd from a just-written plist).
        Entry(technique: "T1543.001", name: "Create or Modify System Process: Launch Agent", coverage: .detects,
              sources: [guardSource("persistenceMonitor"), guardSource("execRecorder"), rule("exec.launchd_untrusted_binary")],
              blindSpot: "A new plist is noticed within seconds, but it cannot be blocked (there is no EndpointSecurity authorization hook), and a validly signed program passes the signature check."),
        Entry(technique: "T1543.004", name: "Create or Modify System Process: Launch Daemon", coverage: .detects,
              sources: [guardSource("persistenceMonitor"), guardSource("execRecorder"), rule("exec.launchd_untrusted_binary")],
              blindSpot: "A new plist is noticed within seconds, but it cannot be blocked (there is no EndpointSecurity authorization hook), and a validly signed program passes the signature check."),
        Entry(technique: "T1547.015", name: "Boot or Logon Autostart Execution: Login Items", coverage: .none,
              sources: [],
              blindSpot: "Login items are not monitored; the persistence monitor watches LaunchAgent and LaunchDaemon plists only."),
        // T1555.001. Shared/ExecCorrelationRules.swift rule 7: the security command reading a secret, run by a
        // non-Apple ancestor that is not a trusted reader.
        Entry(technique: "T1555.001", name: "Credentials from Password Stores: Keychain", coverage: .partial,
              sources: [guardSource("execRecorder"), rule("exec.keychain_access")],
              blindSpot: "Only secret reads through the security command-line tool by a non-Apple process are flagged. Reading the keychain through system APIs is not seen."),
        // T1555.003. RoamSwitch/BrowserCredentialWatchGuard.swift: opt-in, notify-only watch of browser
        // credential and cookie stores; the file header says who opened the file is a best-effort snapshot.
        Entry(technique: "T1555.003", name: "Credentials from Password Stores: Credentials from Web Browsers", coverage: .partial,
              sources: [guardSource("browserCredentialWatchGuard")],
              blindSpot: "Opt-in and notify-only. macOS gives no reliable view of which process opened the file, so the reader is identified on a best-effort basis and the guard can be noisy or miss a short access."),
        // T1552.001. RoamSwitch/CredentialHoneytokenGuard.swift and Shared/ExecCorrelationRules.swift
        // honeytokenPath: decoy credential files only.
        Entry(technique: "T1552.001", name: "Unsecured Credentials: Credentials In Files", coverage: .partial,
              sources: [guardSource("credentialHoneytokenGuard"), guardSource("execRecorder"), rule("exec.honeytoken_path")],
              blindSpot: "Only RoamSwitch's own decoy files are watched. Reading a real credential file is not detected."),
        // T1490. Shared/ExecCorrelationRules.swift ransomwareRecoveryTampering: tmutil deletelocalsnapshots or
        // thinlocalsnapshots run by anything other than RoamSwitch or the OS.
        Entry(technique: "T1490", name: "Inhibit System Recovery", coverage: .partial,
              sources: [guardSource("execRecorder"), rule("exec.ransomware_recovery_tampering")],
              blindSpot: "Covers tmutil deleting or thinning local snapshots. Other ways to destroy recovery points are not watched."),
        // T1548.003. SecurityHealthChecker.swift sudo_hygiene (NOPASSWD audit); RoamSwitchHelper/HelperTool.swift
        // criticalPathFimTargets (/etc/sudoers, /etc/sudoers.d, /etc/pam.d/sudo hashed).
        Entry(technique: "T1548.003", name: "Abuse Elevation Control Mechanism: Sudo and Sudo Caching", coverage: .partial,
              sources: [check("sudo_hygiene"), guardSource("criticalPathFim")],
              blindSpot: "Detects NOPASSWD entries and changes to the sudoers and sudo PAM files. Abuse of an already open sudo session is not seen."),
        // T1098.004. RoamSwitchHelper/HelperTool.swift criticalPathFimTargets: root's authorized_keys and
        // sshd_config (plus sshd_config.d) are hashed.
        Entry(technique: "T1098.004", name: "Account Manipulation: SSH Authorized Keys", coverage: .partial,
              sources: [guardSource("criticalPathFim")],
              blindSpot: "Only root's authorized_keys and the sshd configuration are hashed. Users' own ~/.ssh/authorized_keys files are not."),
    ]

    // MARK: Payload
    //
    // The JSON shape is the one the Linux edition's `get_detection_coverage` returns (core `detection_coverage.rs`:
    // `CoverageReport`, `TechniqueCoverage`, `GuardState`, `CoverageSummary`), with `platform` "macos". The kind of each
    // source (guard / exec_rule / audit_check / feature) lives in `Entry.sources` and is checked by the tests; the JSON
    // carries plain ids only.

    /// `on` (every covering guard is on and can see its input), `off` (none is: switched off, or its reader cannot read
    /// its source), `partial` (some are, or input was lost recently), `unknown` (a covering feature has no setting to
    /// read, or a guard has not reported) or `not_applicable` (nothing covers the technique). A guard's reader
    /// health is included; Pro activation, helper connection and granted permissions beyond that are not checked.
    enum LiveState: String, Codable, Equatable { case on, off, partial, unknown, notApplicable = "not_applicable" }

    struct TechniquePayload: Codable, Equatable {
        let id: String
        let name: String
        let platform: String
        let coverage: String
        let coveredBy: [String]
        let blindSpot: String
        let liveState: String
    }

    struct GuardStatePayload: Codable, Equatable {
        let id: String
        /// The guard's `liveState` from `get_guard_status`: `on`, `off`, `partial` or `unknown` (also when the guard is
        /// not in the guard-status vocabulary).
        let state: String
    }

    struct Summary: Codable, Equatable {
        let total: Int
        let detects: Int
        let partial: Int
        let none: Int
        /// Techniques that are covered (`detects` or `partial`) whose `liveState` is `off`.
        let coveredButOff: Int
    }

    struct Payload: Codable, Equatable {
        let platform: String
        let summary: Summary
        let techniques: [TechniquePayload]
        /// The state of every guard that some technique relies on, in order of first use.
        let guards: [GuardStatePayload]
        let caveats: [String]
    }

    static func liveState(of entry: Entry, guardStates: [String: String]) -> LiveState {
        if entry.sources.isEmpty { return .notApplicable }
        let guards = entry.sources.filter { $0.kind == "guard" }.map { guardStates[$0.id] ?? "unknown" }
        if guards.isEmpty || guards.contains("unknown") { return .unknown }
        if guards.allSatisfy({ $0 == "on" }) { return .on }
        if guards.allSatisfy({ $0 == "off" }) { return .off }
        return .partial
    }

    /// `guards` is the guard list `get_guard_status` builds from the shared preferences.
    static func payload(guards: [MCPGuardEntryPayload]) -> Payload {
        // The guard's `liveState` (reader down -> off, input lost recently -> partial, not reported -> unknown) when
        // `get_guard_status` has one; the bare toggle otherwise.
        let states = Dictionary(guards.map { ($0.key, $0.liveState ?? ($0.enabledInSettings ? "on" : "off")) }, uniquingKeysWith: { first, _ in first })
        var used: [String] = []
        var summary = (detects: 0, partial: 0, none: 0, off: 0)
        let techniques = entries.map { entry -> TechniquePayload in
            for source in entry.sources where source.kind == "guard" && !used.contains(source.id) { used.append(source.id) }
            let live = liveState(of: entry, guardStates: states)
            switch entry.coverage {
            case .detects: summary.detects += 1
            case .partial: summary.partial += 1
            case .none: summary.none += 1
            }
            if entry.coverage != .none && live == .off { summary.off += 1 }
            return TechniquePayload(id: entry.technique, name: entry.name, platform: "macos", coverage: entry.coverage.rawValue,
                                    coveredBy: entry.sources.map(\.id), blindSpot: entry.blindSpot, liveState: live.rawValue)
        }
        return Payload(
            platform: "macos",
            summary: Summary(total: techniques.count, detects: summary.detects, partial: summary.partial, none: summary.none, coveredButOff: summary.off),
            techniques: techniques,
            guards: used.map { GuardStatePayload(id: $0, state: states[$0] ?? "unknown") },
            caveats: [
                loc("この一覧は、RoamSwitch自身が実装を確認して付けた評価で、第三者の検証結果ではありません。「none」は検知する仕組みがないという意味で、攻撃が起きていないという意味ではありません。"),
                loc("「detects」は、その手口の主な形を検知するルールがあるという意味で、すべての変種を検知できるという意味ではありません。限界は blindSpot に書いてあります。"),
                loc("liveState は、設定のトグルに、入力を読む仕組みの状態(読めていない、直近24時間の取りこぼし)を加えて判定します。Pro版の有効化、ヘルパーの接続、権限の許可そのものは確認していません。"),
            ]
        )
    }
}
