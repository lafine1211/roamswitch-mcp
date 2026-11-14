// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.36 (build 215).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Audit check `snmp_exposure`: does this Mac's `snmpd` answer to a default SNMP community?
///
/// macOS ships Net-SNMP's `snmpd` (`/usr/sbin/snmpd`) switched off (its launchd job has `Disabled` set) with a
/// sample `/etc/snmp/snmpd.conf` whose only real community line is restricted to one OID subtree. So the normal
/// state is "present, stopped" and passes. What fails is a config that gives the community `public` or `private`
/// to every source for the whole tree: anybody who can reach UDP 161 can then read the host's tables (and, for
/// `rwcommunity`, change them). It fails with stronger wording when `snmpd` is also listening on a non-loopback
/// address, and with plain warning wording when it is stopped (it would be open the moment it is enabled).
///
/// What is read, all of it local and read-only: `/usr/sbin/snmpd` (existence only), `/etc/snmp/snmpd.conf` and
/// the `*.conf` files in `/etc/snmp/snmpd.conf.d` and `/etc/snmp/snmpd.d`, and `netstat -an -p udp` (needs no
/// privilege) for whether UDP 161 is bound on a non-loopback address. Nothing is started, nothing is sent to the
/// network. The findings are two booleans: a community string is never kept, logged or shown.
///
/// The judgement is the same as the Linux version (`snmp_exposure`):
/// - default community = exactly `public` or `private` (case-sensitive). A placeholder such as `COMMUNITY` is not.
/// - `rocommunity|rwcommunity|rocommunity6|rwcommunity6 <community> [<source> [<oid>]]` is unrestricted when the
///   source is absent or one of `default`, `0.0.0.0/0`, `::/0`, `0.0.0.0`, `::` and there is no further argument
///   (an OID subtree or a view counts as a restriction).
/// - `com2sec [-Cn <context>] <secname> <source> <community>` is unrestricted when the source is `default`,
///   `0.0.0.0/0` or `::/0`.
/// - `read_write` is true only for an unrestricted default `rwcommunity`.
/// `include` and `includeDir` lines are not followed.
enum SNMPExposure {

    // MARK: - Result

    struct Findings: Equatable {
        /// A default community (`public` / `private`) is open to every source for more than a subtree.
        var defaultCommunityUnrestricted = false
        /// That open default community is a read-write (`rwcommunity`) one.
        var readWrite = false
    }

    enum State: Equatable {
        /// No `snmpd` binary and no `snmpd.conf`.
        case notApplicable
        /// A config file exists but could not be read.
        case unconfirmed
        case checked(listeningExposed: Bool, defaultCommunityUnrestricted: Bool, readWrite: Bool)
    }

    /// One config file as read: absent, present but unreadable, or its text.
    enum ConfRead: Equatable {
        case missing
        case unreadable
        case text(String)
    }

    // MARK: - Config parsing (pure)

    private static let defaultCommunities: Set<String> = ["public", "private"]
    private static let openSourcesForCommunityLines: Set<String> = ["default", "0.0.0.0/0", "::/0", "0.0.0.0", "::"]
    private static let openSourcesForCom2sec: Set<String> = ["default", "0.0.0.0/0", "::/0"]

    /// Findings of one `snmpd.conf` text. Comment lines (`#`) and blank lines are ignored.
    static func analyze(conf: String) -> Findings {
        var findings = Findings()
        for raw in conf.split(whereSeparator: \.isNewline) {
            let tokens = raw.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
            guard let keyword = tokens.first, !keyword.hasPrefix("#") else { continue }
            let args = Array(tokens.dropFirst())
            switch keyword {
            case "rocommunity", "rocommunity6", "rwcommunity", "rwcommunity6":
                guard let community = args.first, defaultCommunities.contains(community) else { continue }
                let source = args.count >= 2 ? args[1] : nil
                let sourceIsOpen = source == nil || openSourcesForCommunityLines.contains(source ?? "")
                guard sourceIsOpen, args.count <= 2 else { continue }
                findings.defaultCommunityUnrestricted = true
                if keyword.hasPrefix("rw") { findings.readWrite = true }
            case "com2sec":
                var rest = args
                if rest.first == "-Cn" { rest = Array(rest.dropFirst(2)) }
                guard rest.count >= 3 else { continue }
                if openSourcesForCom2sec.contains(rest[1]), defaultCommunities.contains(rest[2]) {
                    findings.defaultCommunityUnrestricted = true
                }
            default:
                continue
            }
        }
        return findings
    }

    // MARK: - Listening (pure)

    /// Whether `netstat -an -p udp` shows UDP port 161 bound on a non-loopback address: the wildcard (`*.161`) or
    /// a concrete address other than 127.x, `::1` and a `%lo0` link-local one.
    static func isListeningExposed(netstat: String) -> Bool {
        for line in netstat.split(whereSeparator: \.isNewline) {
            let columns = line.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
            guard columns.count >= 4, columns[0].hasPrefix("udp") else { continue }
            let local = columns[3]
            guard let dot = local.lastIndex(of: "."), local[local.index(after: dot)...] == "161" else { continue }
            let address = String(local[..<dot])
            if address.isEmpty { continue }
            if address.hasPrefix("127.") || address == "::1" || address == "localhost" || address.hasSuffix("%lo0") { continue }
            return true
        }
        return false
    }

    // MARK: - Judgement (pure)

    /// `confs` is `snmpd.conf` first, then the `*.conf` files of the two `.d` directories.
    static func evaluate(binaryExists: Bool, mainConf: ConfRead, extraConfs: [ConfRead], netstat: String?) -> State {
        if !binaryExists, mainConf == .missing { return .notApplicable }
        var findings = Findings()
        for conf in [mainConf] + extraConfs {
            switch conf {
            case .missing: continue
            case .unreadable: return .unconfirmed
            case .text(let text):
                let f = analyze(conf: text)
                findings.defaultCommunityUnrestricted = findings.defaultCommunityUnrestricted || f.defaultCommunityUnrestricted
                findings.readWrite = findings.readWrite || f.readWrite
            }
        }
        return .checked(listeningExposed: netstat.map(isListeningExposed(netstat:)) ?? false,
                        defaultCommunityUnrestricted: findings.defaultCommunityUnrestricted,
                        readWrite: findings.readWrite)
    }

    // MARK: - Reading

    static let binaryPath = "/usr/sbin/snmpd"
    static let mainConfPath = "/etc/snmp/snmpd.conf"
    static let extraConfDirectories = ["/etc/snmp/snmpd.conf.d", "/etc/snmp/snmpd.d"]

    /// The reader the audit uses; the tests replace it.
    static var readState: () -> State = { liveState() }

    static func liveState(runner: CommandRunner = SystemCommand.run) -> State {
        let fm = FileManager.default
        func read(_ path: String) -> ConfRead {
            guard fm.fileExists(atPath: path) else { return .missing }
            guard let data = fm.contents(atPath: path) else { return .unreadable }
            return .text(String(decoding: data, as: UTF8.self))
        }
        let extras: [ConfRead] = extraConfDirectories.flatMap { dir -> [ConfRead] in
            ((try? fm.contentsOfDirectory(atPath: dir)) ?? []).filter { $0.hasSuffix(".conf") }.sorted().map { read(dir + "/" + $0) }
        }
        var netstat: String?
        if let out = runner("/usr/sbin/netstat", ["-an", "-p", "udp"]), out.status == 0 { netstat = out.stdout }
        return evaluate(binaryExists: fm.fileExists(atPath: binaryPath), mainConf: read(mainConfPath), extraConfs: extras, netstat: netstat)
    }

    // MARK: - Audit item

    static func item(_ state: State) -> SecurityAuditItem {
        var isPassed = true
        var isApplicable = true
        var inconclusiveReason: String?
        let statusText: String
        var recommendation = loc("対応は不要です。")
        switch state {
        case .notApplicable:
            isApplicable = false
            statusText = loc("対象外 (snmpd が入っていません)")
            recommendation = loc("対象がないため、点数に入れません。")
        case .unconfirmed:
            isPassed = false
            inconclusiveReason = "not_verifiable"
            statusText = loc("状態を確認できませんでした")
            recommendation = loc("/etc/snmp/snmpd.conf を読める状態で、もう一度診断してください。")
        case .checked(let listening, let unrestricted, let readWrite):
            if !unrestricted {
                if listening {
                    statusText = loc("問題なし (snmpd が待ち受け中ですが、初期値のコミュニティ名を誰にでも開く設定はありません)")
                    recommendation = loc("SNMPを使わないなら、snmpd を止めてください。")
                } else {
                    statusText = loc("問題なし (snmpd は停止中。macOS は snmpd を無効にして出荷します)")
                }
            } else if listening {
                isPassed = false
                statusText = readWrite
                    ? loc("⚠️ snmpd が待ち受け中で、初期値のコミュニティ名で誰でも読み書きできます")
                    : loc("⚠️ snmpd が待ち受け中で、初期値のコミュニティ名で誰でも読めます")
                recommendation = loc("すぐに `sudo launchctl bootout system/org.net-snmp.snmpd` で snmpd を止めてください。使うなら、/etc/snmp/snmpd.conf の該当行で、初期値のコミュニティ名をやめるか、接続元を限ってください。")
            } else {
                isPassed = false
                statusText = readWrite
                    ? loc("⚠️ 設定に、初期値のコミュニティ名で誰でも読み書きできる行があります (snmpd は停止中)")
                    : loc("⚠️ 設定に、初期値のコミュニティ名で誰でも読める行があります (snmpd は停止中)")
                recommendation = loc("snmpd を有効にする前に、/etc/snmp/snmpd.conf の該当行で、初期値のコミュニティ名をやめるか、接続元を限ってください。")
            }
        }
        return SecurityAuditItem(
            category: loc("サービス・ポート露出"),
            title: loc("SNMPの公開設定"),
            isPassed: isPassed,
            statusText: statusText,
            detail: loc("macOS に入っている SNMP サービス (snmpd) の設定と待ち受けを確認します。コミュニティ名がSNMPの初期値のまま、接続元もOIDも限っていない行があると不合格です。snmpd が待ち受け中なら強い警告に、停止中なら、有効にした時点で公開される警告になります。標準の設定は、1つのOIDだけに限っているので合格です。設定ファイルと、ローカルの待ち受け一覧だけを読みます。snmpd は起動せず、外部への通信もしません。コミュニティ名は表示も記録もしません。"),
            recommendation: recommendation,
            settingsURL: nil,
            isApplicable: isApplicable,
            checkId: "snmp_exposure",
            cisControlID: "4.8",
            nistCsfCategories: ["PR.PS-01"],
            inconclusiveReason: inconclusiveReason
        )
    }
}
