// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.35 (build 214).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Debug and proxy ports that must not be reachable from the network: JDWP (5005, 8453), the Node.js / V8
/// inspector (9229, 5858), PHP-FPM / Xdebug (9000) and SOCKS (1080). Same catalog, tiers and texts as
/// roamswitch-linux `debug_port.rs`; keep the two in step.
///
/// All of them take commands without authentication. A debugger that a stranger can reach runs the stranger's
/// code (JDWP, the V8 inspector, FastCGI), and an open SOCKS proxy lets the stranger reach this Mac's own
/// network. A port scanner lists these ports first for that reason.
///
/// **Confirmed**: the port and the process agree (`java` on 5005, `node` on 9229, `php-fpm` on 9000, `ssh` or a
/// SOCKS server on 1080). Reported at the exposure level of the port audit. **Guess**: the port is the
/// service's own default and almost nothing else uses it (5005, 9229, 1080) but the process does not say what
/// it is: reported as `info` (it does not raise the overall risk) and says it is a guess. 9000, 8453 and 5858 are shared with other software
/// (MinIO, Portainer, SonarQube, ClickHouse, ...) and are reported only together with the process, the way
/// port 8000 is reported as vLLM only for a vLLM process. A listener on loopback is the intended setup
/// (`node --inspect` and `ssh -D` bind there by default) and is not reported. Nothing is sent: the port number
/// and the process name are what the listener scan already has.
enum DebugPortRisk {
    enum Confidence: Equatable { case confirmed, guess }

    enum Kind: Equatable { case jdwp, nodeInspector, phpFpmXdebug, socks }

    struct Service {
        let kind: Kind
        let id: String
        let name: String
        let ports: Set<Int>
        /// The ports nothing else conventionally uses, so the port alone is a guess.
        let guessPorts: Set<Int>
        /// Lower-case process or executable names that are the service's own (exact, or followed by a non-letter).
        let processNames: [String]
    }

    struct Match: Equatable {
        let kind: Kind
        let id: String
        let name: String
        let confidence: Confidence
    }

    static let catalog: [Service] = [
        // `-agentlib:jdwp=transport=dt_socket,server=y,address=5005`; 8453 is a second port debug launchers use.
        Service(kind: .jdwp, id: "jdwp", name: "JDWP (Java debugger)", ports: [5005, 8453], guessPorts: [5005],
                processNames: ["java", "javaw"]),
        // `node --inspect` listens on 9229; the legacy `--debug` used 5858.
        Service(kind: .nodeInspector, id: "node-inspector", name: "Node.js inspector", ports: [9229, 5858], guessPorts: [9229],
                processNames: ["node", "nodejs", "deno", "bun"]),
        // PHP-FPM's FastCGI port and Xdebug's classic client port are both 9000; only a PHP process is taken as evidence.
        Service(kind: .phpFpmXdebug, id: "php-fpm-xdebug", name: "PHP-FPM / Xdebug", ports: [9000], guessPorts: [],
                processNames: ["php", "php-fpm", "php-cgi"]),
        // 1080 is the registered SOCKS port: `ssh -D 0.0.0.0:1080` and the SOCKS servers below listen there.
        Service(kind: .socks, id: "socks", name: "SOCKS proxy", ports: [1080], guessPorts: [1080],
                processNames: ["ssh", "sslocal", "ss-local", "microsocks", "danted", "sockd", "3proxy", "gost", "xray", "v2ray", "sing-box"]),
    ]

    /// `name` equals `marker`, or starts with it followed by a non-letter (`php-fpm8.3`); `sshd` is not `ssh`.
    static func nameMatches(_ name: String, _ marker: String) -> Bool {
        guard name.hasPrefix(marker) else { return false }
        let rest = name.dropFirst(marker.count)
        guard let first = rest.first else { return true }
        return !first.isLetter
    }

    /// The debug / proxy service a listener on `port` may be, or nil.
    static func identify(port: Int, processName: String, executablePath: String?) -> Match? {
        let process = processName.lowercased()
        let exe = executablePath.map { ($0 as NSString).lastPathComponent.lowercased() } ?? ""
        for s in catalog where s.ports.contains(port) {
            let named = s.processNames.contains { nameMatches(process, $0) || (!exe.isEmpty && nameMatches(exe, $0)) }
            if named { return Match(kind: s.kind, id: s.id, name: s.name, confidence: .confirmed) }
            if s.guessPorts.contains(port) { return Match(kind: s.kind, id: s.id, name: s.name, confidence: .guess) }
        }
        return nil
    }

    /// The finding for a listener reachable from the network. `isGlobal` / `isFirewallBlocking` are the plain
    /// port finding's own inputs; a guess is `info` (as the `low` of roamswitch-linux).
    static func finding(for match: Match, isGlobal: Bool, isFirewallBlocking: Bool) -> PortAuditFinding {
        let exposure: PortSecurityRiskLevel = (isGlobal && !isFirewallBlocking) ? .critical : .warning
        switch match.confidence {
        case .confirmed:
            let (title, description) = confirmedTexts(match.kind)
            return PortAuditFinding(title: title, riskLevel: exposure, description: description, recommendation: recommendation(match.kind))
        case .guess:
            return PortAuditFinding(
                title: String(format: loc("このポートは %@ の既定です(ポート番号からの推測)"), match.name),
                riskLevel: .info,
                description: String(format: loc("プロセス名からは %@ と確かめられませんでした。%@ なら、認証なしで操作を受け付けます。待ち受けているプロセスを確認してください。"), match.name, match.name),
                recommendation: recommendation(match.kind))
        }
    }

    private static func recommendation(_ kind: Kind) -> String {
        kind == .socks
            ? loc("待ち受けを 127.0.0.1 にするか、認証つきのプロキシに替えるか、ファイアウォールで接続元を限ってください。使わないなら止めてください。")
            : loc("デバッグは 127.0.0.1 だけで待ち受け(必要なときは SSH のポート転送を使う)、ファイアウォールで接続元を限り、使い終わったらデバッグ設定を外して再起動してください。")
    }

    private static func confirmedTexts(_ kind: Kind) -> (String, String) {
        switch kind {
        case .jdwp: return (loc("Java のデバッグ用ポート(JDWP)がネットワークから届きます"), loc("JDWP は認証がありません。つないだ相手は、この Java プロセスの中で任意のコードを実行できます。"))
        case .nodeInspector: return (loc("Node.js のインスペクタ(デバッグ用ポート)がネットワークから届きます"), loc("インスペクタは認証がありません。つないだ相手は、この Node.js プロセスで任意のコードを実行できます。`--inspect` は既定では 127.0.0.1 だけで待ち受けるので、0.0.0.0 などを明示した設定です。"))
        case .phpFpmXdebug: return (loc("PHP のポート 9000(PHP-FPM / Xdebug)がネットワークから届きます"), loc("9000 は PHP-FPM の FastCGI の既定ポートで、Xdebug の既定のデバッグ用ポートでもあります。どちらも認証がありません。FastCGI に届く相手は、PHP にコードを実行させられます。"))
        case .socks: return (loc("SOCKS プロキシがネットワークから届きます"), loc("認証のない SOCKS プロキシは、つないだ相手が、このマシンを踏み台にして、このマシンから見える内側のネットワークへ入れます。"))
        }
    }
}
