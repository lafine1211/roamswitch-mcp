// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.15.0 (build 174).
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
/// guard id exists in the guard-status vocabulary (`get_guard_status`), every guard in that vocabulary either backs a
/// technique or is on `exemptGuards` with a reason, each audit check id exists in the
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
        // T1059.004. Shared/ExecCorrelationRules.swift rules 1, 3 and 14: a shell or interpreter started by a
        // browser, Office or mail app; a download piped into a shell together with an aggravating fact; a
        // reverse or bind shell command line (reverseShellShape). RoamSwitch/ReverseShellScan.swift and
        // ReverseShellWatchGuard.swift: a live poll (libproc, every 4 seconds) of the user's own shells,
        // interpreters and nc/ncat/socat for an outward public TCP connection that is their input and output.
        Entry(technique: "T1059.004", name: "Command and Scripting Interpreter: Unix Shell", coverage: .partial,
              sources: [guardSource("reverseShellWatch"), guardSource("execRecorder"), rule("exec.shell_from_app"), rule("exec.pipe_to_shell"), rule("exec.reverse_shell_argv")],
              blindSpot: "Flags a shell started by a browser, Office or mail app, and a download piped into a shell only together with an aggravating fact. A plain curl | sh typed in a terminal looks like an official installer and is not flagged on its own. The exec recorder (opt-in) flags a reverse or bind shell only when it is spelled out on a sh -c command line or an nc, ncat or socat command line. The reverse-shell watch (Pro, on by default) sees a live one: a shell or interpreter, or nc, ncat or socat running a program, whose input and output are an established outward TCP connection to a public address, found on a poll every few seconds and notified once the second poll agrees. It reads the logged-in user's own processes only, so a root-owned shell is not seen. A peer on a private network (home LAN, Tailscale, containers) or loopback is not watched, and neither is a program that is not one of the listed shells, interpreters or relay tools. A shell written into a script file or compiled into a program is not seen until it connects."),
        // T1557.003. RoamSwitch/NetworkSettingsWatch.swift and NetworkSettingsWatchGuard.swift (system configuration
        // store: DNS servers, router, proxy auto-config compared with what the same network gave before) and
        // ProxyAutoDiscoveryCheck.swift (audit check proxy_autodiscovery: Auto Proxy Discovery / PAC in force).
        Entry(technique: "T1557.003", name: "Adversary-in-the-Middle: DHCP Spoofing", coverage: .partial,
              sources: [guardSource("networkSettingsWatch"), check("proxy_autodiscovery")],
              blindSpot: "A rogue DHCP server cannot be seen directly; only its result is. A new DNS server, or a new router together with one, on a network that RoamSwitch has seen before is notified, as is a new proxy auto-config (PAC) address or Auto Proxy Discovery (WPAD) switched on. The first time a network is seen it is only learned. A rogue server that hands out the same DNS and router as before, or a well-known public resolver, is not noticed, and neither is a change on a VPN or other tunnel. A DNS-over-HTTPS profile and addresses set by hand or by RoamSwitch's own secure DNS are not compared. The audit check reports Auto Proxy Discovery or a network-supplied PAC address being on, and does not read the PAC file."),
        // T1553.004. RoamSwitch/TrustAnchorCheck.swift (audit check trust_anchors: the certificates the user or an
        // administrator set to "trust", read with `security dump-trust-settings`).
        Entry(technique: "T1553.004", name: "Subvert Trust Controls: Install Root Certificate", coverage: .partial,
              sources: [check("trust_anchors")],
              blindSpot: "Only the certificates that have a trust setting in the user and administrator domains are listed, which is every certificate somebody added to what the Mac trusts. When one was added is not known, a new one is not notified as it appears, and a certificate an application carries for itself never touches the system trust and is not seen. Added certificates whose names do not look like an interception tool are reported as information, because a company or a developer tool adds its own on purpose."),
        // T1557.001. mDNSResponder carries no LLMNR code (searched), so macOS has no LLMNR to poison. NetBIOS name
        // service is another matter: /usr/sbin/netbiosd ships with macOS and runs as a LaunchDaemon.
        Entry(technique: "T1557.001", name: "Adversary-in-the-Middle: LLMNR/NBT-NS Poisoning and SMB Relay", coverage: .none,
              sources: [],
              blindSpot: "Not looked for. macOS has no LLMNR client or responder to poison. The NetBIOS name service is present (netbiosd, a system LaunchDaemon) and RoamSwitch does not watch NBNS replies or the SMB name lookups that use them, so poisoning of NetBIOS name resolution is not detected. mDNS (Bonjour) is on by design and is not treated as a finding."),
        // T1543.001 / T1543.004. RoamSwitch/PersistenceMonitorGuard.swift (FSEvents on LaunchAgent and
        // LaunchDaemon plists; flags a bare interpreter or an unsigned program) and Shared/ExecCorrelationRules.swift
        // rule 6 (an unsigned or ad-hoc binary started by launchd from a just-written plist).
        Entry(technique: "T1543.001", name: "Create or Modify System Process: Launch Agent", coverage: .detects,
              sources: [guardSource("persistenceMonitor"), guardSource("execRecorder"), rule("exec.launchd_untrusted_binary")],
              blindSpot: "A new plist is noticed within seconds, but it cannot be blocked (there is no EndpointSecurity authorization hook), and a validly signed program passes the signature check."),
        Entry(technique: "T1543.004", name: "Create or Modify System Process: Launch Daemon", coverage: .detects,
              sources: [guardSource("persistenceMonitor"), guardSource("execRecorder"), rule("exec.launchd_untrusted_binary")],
              blindSpot: "A new plist is noticed within seconds, but it cannot be blocked (there is no EndpointSecurity authorization hook), and a validly signed program passes the signature check."),
        // T1546.004. RoamSwitch/StartupScriptWatch.swift (polled every 5 seconds, run by the persistence monitor):
        // zsh, bash and fish start-up files in the home folder and /etc.
        Entry(technique: "T1546.004", name: "Event Triggered Execution: Unix Shell Configuration Modification", coverage: .partial,
              sources: [guardSource("persistenceMonitor")],
              blindSpot: "Only a new line shaped like a reverse shell, decode-and-run, download-and-run or a program run from a temporary folder is notified. A suspicious line that was already in the file when the watch started is not reported again, and the start-up files of other shells such as csh and tcsh are not watched."),
        Entry(technique: "T1547.015", name: "Boot or Logon Autostart Execution: Login Items", coverage: .none,
              sources: [],
              blindSpot: "Login items are not monitored; the persistence monitor watches LaunchAgent and LaunchDaemon plists and a few text files (shell start-up files, periodic scripts, hooks), not the Login Items list."),
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
        // honeytokenPath: decoy credential files only. RoamSwitch/AgentCredentialFileCheck.swift (audit check
        // agent_credential_files): permissions and location of the AI coding tools' sign-in files, metadata only.
        Entry(technique: "T1552.001", name: "Unsecured Credentials: Credentials In Files", coverage: .partial,
              sources: [guardSource("credentialHoneytokenGuard"), guardSource("execRecorder"), rule("exec.honeytoken_path"), check("agent_credential_files")],
              blindSpot: "Only RoamSwitch's own decoy files are watched. Reading a real credential file is not detected: without Endpoint Security a Mac cannot see which process opened a file, and no decoy is placed at the paths real tools read on every start (it would fire constantly). The audit check looks at the permissions and location (a cloud-synced folder, a git work tree) of the sign-in files of Claude Code, Codex, Gemini CLI, GitHub Copilot and opencode, by metadata only, in their default locations. Claude Code keeps its sign-in in the Keychain on a Mac, so its file is checked only when it exists."),
        // T1490. Shared/ExecCorrelationRules.swift ransomwareRecoveryTampering: tmutil deletelocalsnapshots or
        // thinlocalsnapshots run by anything other than RoamSwitch or the OS.
        Entry(technique: "T1490", name: "Inhibit System Recovery", coverage: .partial,
              sources: [guardSource("execRecorder"), rule("exec.ransomware_recovery_tampering")],
              blindSpot: "Covers tmutil deleting or thinning local snapshots. Other ways to destroy recovery points are not watched."),
        // T1548.003. SecurityHealthChecker.swift sudo_hygiene (NOPASSWD audit); RoamSwitchHelper/HelperTool.swift
        // criticalPathFimTargets and CriticalPathFimTargets.expand (/etc/sudoers, every file in /etc/sudoers.d and /etc/pam.d hashed).
        Entry(technique: "T1548.003", name: "Abuse Elevation Control Mechanism: Sudo and Sudo Caching", coverage: .partial,
              sources: [check("sudo_hygiene"), guardSource("criticalPathFim")],
              blindSpot: "Detects NOPASSWD entries, and changes, additions and deletions of /etc/sudoers, the files under /etc/sudoers.d, and the PAM files under /etc/pam.d. Abuse of an already open sudo session is not seen."),
        // T1098.004. RoamSwitchHelper/HelperTool.swift criticalPathFimTargets: root's authorized_keys and
        // sshd_config (plus sshd_config.d) are hashed.
        Entry(technique: "T1098.004", name: "Account Manipulation: SSH Authorized Keys", coverage: .partial,
              sources: [guardSource("criticalPathFim")],
              blindSpot: "Only root's authorized_keys and the sshd configuration are hashed. Users' own ~/.ssh/authorized_keys files are not."),
        // T1110.001. RoamSwitch/SSHGuard.swift and Shared/SSHGuardCore.swift (run by RoamSwitchHelper/SSHGuardDetector.swift):
        // failed sshd logins are read from the unified log and counted per source in a sliding window (default 6 failures
        // in 600 s); the source is then banned through pf for new connections to the SSH ports only.
        Entry(technique: "T1110.001", name: "Brute Force: Password Guessing", coverage: .detects,
              sources: [guardSource("sshGuard")],
              blindSpot: "SSH only, and only while Remote Login is on. Guessing against other services (Screen Sharing, File Sharing, a local web login) is not looked at, a source that stays under the failure limit is not banned, and a ban never cuts a session that is already open."),
        // T1046. RoamSwitch/PortScanGuard.swift; the logic runs in RoamSwitchHelper/PortScanDetector.swift on the packet
        // filter's log (pflog0) with Shared/PortScanTracker.swift: a source that reaches many distinct ports in a short
        // window, plus a slower window for slow scans; the source is blocked for a bounded time when auto-block is on.
        Entry(technique: "T1046", name: "Network Service Discovery", coverage: .partial,
              sources: [guardSource("portScanGuard")],
              blindSpot: "Scans against this Mac only, seen through the packet filter's log. A scan that stays under the distinct-port limits is not flagged, and a scan run from this Mac is not looked at. Needs the helper and Pro."),
        // T1486. RoamSwitch/RansomwareCanaryGuard.swift (bait files in Application Support and four user folders, compared
        // with their recorded SHA-256) and RoamSwitch/RansomwareEntropyGuard.swift (new writes in the same folders whose
        // content looks like ciphertext: entropy of the whole file, and 4 KiB windows for partial encryption).
        Entry(technique: "T1486", name: "Data Encrypted for Impact", coverage: .partial,
              sources: [guardSource("ransomwareCanaryGuard"), guardSource("ransomwareEntropyGuard")],
              blindSpot: "Bait files and new writes inside the watched folders only. macOS gives no writing-process id, so encryption elsewhere, or slow encryption that stays under the entropy limit, is not seen, and the cause of a hit is attributed on a best-effort basis."),
        // T1557.002. RoamSwitch/ARPSpoofContainmentManager.swift (the gateway's MAC address changing while its IP stays put
        // air-gaps the network) and RoamSwitch/GatewayARPLockManager.swift (pins the default gateway, the IPv6 router and
        // on-link DNS resolvers into the ARP / NDP cache).
        Entry(technique: "T1557.002", name: "Adversary-in-the-Middle: ARP Cache Poisoning", coverage: .partial,
              sources: [guardSource("arpSpoofAutoContainment"), guardSource("gatewayARPLock")],
              blindSpot: "Covers the default gateway and the on-link hosts that are pinned. Spoofing of other neighbours is not looked at, and the containment needs the helper and Pro."),
        // T1200. RoamSwitch/USBKeyboardGuard.swift: IOHIDManager notices a keyboard that is not on the approved list and its
        // keystrokes are held back until it is approved; opt-in, needs the Accessibility permission.
        Entry(technique: "T1200", name: "Hardware Additions", coverage: .partial,
              sources: [guardSource("usbKeyboardGuard")],
              blindSpot: "Looks at devices that present themselves as keyboards. A device that copies the identity of an approved keyboard, or injects through another HID class, is not caught. Opt-in; USB storage is handled by the storage guard."),
        // T1091. RoamSwitch/USBStorageGuard.swift: an unknown external USB volume is mounted read-only until approved and
        // every insertion passes a ClamAV scan before it is released to read-write.
        Entry(technique: "T1091", name: "Replication Through Removable Media", coverage: .partial,
              sources: [guardSource("usbStorageGuard")],
              blindSpot: "External USB volumes only, and the scan is signature-based: a payload with no signature passes, and a volume the user approves read-write after a clean scan is trusted. HID devices are not covered here (see T1200)."),
        // T1204.002. RoamSwitch/WebMailDownloadGuard.swift: files that arrive with the quarantine attribute in Downloads,
        // Desktop, Documents and Mail Downloads are scanned by ClamAV and, through StaticSignatureScanner, by byte-pattern
        // rules; threats are quarantined.
        Entry(technique: "T1204.002", name: "User Execution: Malicious File", coverage: .partial,
              sources: [guardSource("webMailDownloadGuard")],
              blindSpot: "Only files in the watched folders that arrive with the quarantine attribute (outside Downloads) are checked, and detection is signature and pattern based: a new variant with no signature, or an archive the engines cannot open, passes."),
        // T1204.004. RoamSwitch/ClickFixGuard.swift (shell history lines) and RoamSwitch/SecretLeakAuditor.swift (the
        // pasteboard, at copy time) match known ClickFix command shapes; the history check runs after the command has run.
        Entry(technique: "T1204.004", name: "User Execution: Malicious Copy and Paste", coverage: .partial,
              sources: [guardSource("clickFixGuard"), guardSource("secretLeakClipboardAuditor")],
              blindSpot: "Only the shapes RoamSwitch knows are flagged: reverse-shell one-liners and a base64 decode piped into a shell or osascript. A plain curl | bash is deliberately not flagged, and the history check is after the fact."),
        // T1195.001. RoamSwitch/LockfileTamperGuard.swift: package-lock.json, yarn.lock, pnpm-lock.yaml and
        // npm-shrinkwrap.json in the registered project folders are hashed; a change is re-flagged until a person
        // re-trusts it.
        Entry(technique: "T1195.001", name: "Supply Chain Compromise: Compromise Software Dependencies and Development Tools", coverage: .partial,
              sources: [guardSource("lockfileTamperGuard")],
              blindSpot: "Notices that a lockfile changed, not whether the dependency it now pins is malicious. Only the npm-family lockfiles of registered project folders are hashed."),
        // T1505.003. RoamSwitch/WebRuleFolderScanner.swift (local web roots and project folders, once a day and on demand)
        // and RoamSwitch/WebMailDownloadGuard.swift (the same web rules on the download folders, live), through
        // StaticSignatureScanner.
        Entry(technique: "T1505.003", name: "Server Software Component: Web Shell", coverage: .partial,
              sources: [guardSource("webRulesFolderScan"), guardSource("webMailDownloadGuard")],
              blindSpot: "Local web roots, project folders and the download folders only. A web shell written anywhere else is not examined, there is no view of a remote server, and a file larger than the read limit is checked at its start only."),
        // T1566.002. RoamSwitch/LinkGuardManager.swift: outbound connections to hosts in the phishing and scam feed are
        // blocked or paused for an answer (hosts sinkhole, plus the content-filter extension when it is active).
        Entry(technique: "T1566.002", name: "Phishing: Spearphishing Link", coverage: .partial,
              sources: [guardSource("linkGuard")],
              blindSpot: "Hosts in the feed only. A new or unlisted link passes, and a connection the filter cannot see (no extension, and not in the hosts file) is not stopped."),
        // T1610. RoamSwitch/DockerEventGuard.swift: polls docker ps / inspect every 20 seconds and notifies (no
        // containment) for a new container that runs privileged or with /var/run/docker.sock mounted.
        Entry(technique: "T1610", name: "Deploy Container", coverage: .partial,
              sources: [guardSource("dockerEventGuard")],
              blindSpot: "Only a new privileged container, or one with the Docker socket mounted, is flagged. Other new containers, and one that starts and stops between two polls, are not."),
    ]

    /// Guards of `get_guard_status` that detect nothing a single ATT&CK technique names, each with the reason. Together with
    /// the guards some entry above relies on, this covers the whole guard-status vocabulary; the tests fail for a guard that
    /// is in neither place.
    static let exemptGuards: [String: String] = [
        "portAnomalyGuard": "Exposure control: blocks outside access to a newly listening executable; no ATT&CK technique matches a new listener.",
        "runtimeThreatContainment": "Contains what XProtect convicted; XProtect's detections are not tied to one technique.",
        "dnsThreatGuard": "Switches to a filtering DNS resolver away from home; prevention, not the detection of a technique.",
        "bluetoothGuard": "Turns Bluetooth off on an untrusted network; exposure reduction, no detection.",
        "airGapAutoWiFiKill": "A response (cuts the network when a threat is confirmed), not a detection.",
        "wireGuardVPN": "Network protection (the VPN tunnel); no detection.",
        "tailscaleKillSwitch": "Network protection (the Tailscale kill switch); no detection.",
        "linkGuardFeedUpdates": "Keeps the link guard's feed current; covers nothing by itself (see T1566.002).",
        "activeVulnScan": "Probes this Mac's own listening services for weaknesses; an assessment, not the detection of an attack.",
        "scheduledLogAudit": "Looks for new or surging log patterns in general; not tied to one technique.",
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
    /// health, Pro (needed and not active: `off`) and the helper link (needed and not connected: `off`; needed for
    /// a response only: `partial`) are included; granted permissions are not checked.
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
        /// Present when the state is not just the toggle and the readers: `pro_not_active`, `helper_not_connected` or
        /// `helper_status_unknown`.
        var reason: String? = nil
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
        let reasons = Dictionary(guards.compactMap { g in g.liveStateReason.map { (g.key, $0) } }, uniquingKeysWith: { first, _ in first })
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
            guards: used.map { GuardStatePayload(id: $0, state: states[$0] ?? "unknown", reason: reasons[$0]) },
            caveats: [
                loc("この一覧は、RoamSwitch自身が実装を確認して付けた評価で、第三者の検証結果ではありません。「none」は検知する仕組みがないという意味で、攻撃が起きていないという意味ではありません。"),
                loc("「detects」は、その手口の主な形を検知するルールがあるという意味で、すべての変種を検知できるという意味ではありません。限界は blindSpot に書いてあります。"),
                loc("liveState は、設定のトグルに、次を加えて判定します。Pro版が有効か、ヘルパーに接続できているか、入力を読めているか(読めていない、直近24時間の取りこぼし)。Pro版が必要なのに有効でない検知は off、ヘルパーが必要なのに接続できていない検知は off(一部の機能だけ要する検知は partial)です。理由は guards の reason にあります。Pro版の有効とヘルパーの接続は、アプリが保存した記録を読みます。アプリが動いていないか記録が古いとき、ヘルパーが必要な検知は unknown です。権限(フルディスクアクセスなど)の許可そのものは確認していません。"),
            ]
        )
    }

    // MARK: ATT&CK Navigator layer
    //
    // The same table as an ATT&CK Navigator layer (layer format 4.5), for people who look at coverage in the
    // Navigator. Only techniques RoamSwitch assessed are listed; a technique that is not listed was not
    // assessed, and the Navigator shows it uncoloured. The colours say what RoamSwitch wrote about itself.

    /// The ATT&CK version written to the layer's `versions.attack`. The upstream skill catalog this work was
    /// compared with says v19.1; that was not checked against MITRE's release notes. The technique ids used here
    /// have existed since well before v19, so a different version in the Navigator does not move them.
    static let navigatorAttackVersion = "19"
    static let navigatorVersion = "5.1.0"
    static let navigatorLayerVersion = "4.5"

    /// Green = detects, yellow = partial, red = none. Fixed so two exports can be compared.
    private static let layerColors: [String: String] = ["detects": "#3fb950", "partial": "#e3b341", "none": "#f85149"]
    private static let layerScores: [String: Int] = ["detects": 2, "partial": 1, "none": 0]

    /// The layer as a JSON-ready dictionary (`JSONSerialization` with sorted keys makes it stable).
    static func navigatorLayer(_ payload: Payload) -> [String: Any] {
        let techniques: [[String: Any]] = payload.techniques.map { t in
            let by = t.coveredBy.isEmpty ? "nothing" : t.coveredBy.joined(separator: ", ")
            return [
                "techniqueID": t.id,
                "color": layerColors[t.coverage] ?? layerColors["none"]!,
                "score": layerScores[t.coverage] ?? 0,
                "comment": "\(t.coverage). Blind spot: \(t.blindSpot) Covered by: \(by). Live state: \(t.liveState).",
                "enabled": true,
                "showSubtechniques": false,
                "metadata": [] as [[String: String]],
                "links": [] as [[String: String]],
            ]
        }
        return [
            "name": "RoamSwitch detection coverage (\(payload.platform))",
            "versions": ["attack": navigatorAttackVersion, "navigator": navigatorVersion, "layer": navigatorLayerVersion],
            "domain": "enterprise-attack",
            "description": "What RoamSwitch can and cannot see, for the techniques it assessed. This is RoamSwitch's own assessment, checked against its code, not a third-party test. Red (none) means no detection exists, not that no attack happened; green (detects) means a rule exists for the technique's main form, not every variant. A technique that is not listed was not assessed.",
            "filters": ["platforms": ["macOS"]],
            "sorting": 0,
            "layout": ["layout": "side", "aggregateFunction": "average", "showID": true, "showName": true,
                       "showAggregateScores": false, "countUnscored": false, "expandedSubtechniques": "all"],
            "hideDisabled": false,
            "techniques": techniques,
            "gradient": ["colors": [layerColors["none"]!, layerColors["partial"]!, layerColors["detects"]!], "minValue": 0, "maxValue": 2],
            "legendItems": [
                ["label": "detects: a rule exists for the main form", "color": layerColors["detects"]!],
                ["label": "partial: a named part is covered", "color": layerColors["partial"]!],
                ["label": "none: nothing looks for it", "color": layerColors["none"]!],
            ],
            "metadata": [
                ["name": "generator", "value": "RoamSwitch get_detection_coverage"],
                ["name": "platform", "value": payload.platform],
                ["name": "summary", "value": "detects \(payload.summary.detects), partial \(payload.summary.partial), none \(payload.summary.none) of \(payload.summary.total)"],
            ],
            "links": [] as [[String: String]],
            "showTacticRowBackground": false,
            "tacticRowBackground": "#dddddd",
            "selectTechniquesAcrossTactics": true,
            "selectSubtechniquesWithParent": false,
            "selectVisibleTechniques": false,
        ]
    }

    static func navigatorLayerJSON(_ payload: Payload) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: navigatorLayer(payload), options: [.sortedKeys, .prettyPrinted])) ?? Data("{}".utf8)
        return String(decoding: data, as: UTF8.self)
    }
}
