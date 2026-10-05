// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.10.27 (build 145).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Localized one-line state text shared by the app UI and the MCP tools (same
/// `loc` keys, so no extra strings).
enum ExecRecorderText {
    static func status(_ s: ExecRecorderStatus?, enabled: Bool) -> String {
        guard let s else {
            return enabled ? loc("ヘルパーからの状態をまだ受信していません") : loc("停止中")
        }
        switch s.state {
        case "running": return loc("記録中")
        case "starting": return loc("起動中…")
        case "needsFullDiskAccess": return loc("実行記録は利用できません: フルディスクアクセスでRoamSwitchの許可が必要です（一覧に無ければ「+」から /Applications/RoamSwitch.app を追加）")
        case "esloggerMissing": return loc("実行記録は利用できません: /usr/bin/esloggerが見つかりません(macOS 13以降が必要)")
        case "backoff": return loc("esloggerが停止したため、再試行を待っています")
        case "failed": return loc("esloggerを起動できません。時間をおいて自動的に再試行します")
        default: return loc("停止中")
        }
    }
}

struct MCPExecRecorderStatePayload: Encodable {
    let enabledInSettings: Bool
    let state: String
    let stateLabel: String
    let eventsRecorded: UInt64?
    let eventsDropped: UInt64?
    let malformedLines: UInt64?
    let alertsRaised: UInt64?
    let statusUpdatedAt: String?
}

/// Output hygiene for exec-recorder data returned over MCP. Everything in an exec
/// event (process path, argv, cwd, signing identity) is chosen by whoever ran the
/// process, i.e. potentially an attacker targeting the MCP client's LLM, and argv
/// routinely carries secrets (`--token xxx`, `Authorization: Bearer ...`,
/// `https://user:pass@host`). So before anything leaves this process every string is
/// (1) stripped of control/format characters, (2) secret-masked, and (3) capped at
/// `MCPUntrustedText.maxLength` (300) — always in that order, so an invisible
/// character can't hide a secret from the masker and a cut can't leave a half-masked
/// secret behind. The recorder's own store limits (`ESLoggerParser.maxArgChars` 512,
/// `maxPathChars` 1024) are upper bounds on what is *kept*; this 300-character cap on
/// what is *returned* is deliberately stricter.
enum ExecOutputSanitizer {
    /// Pre-mask cap: above the parser's own per-string limits so the masker sees whole values.
    private static let premaskLimit = 1024
    static let redactionMarker = "****"

    /// One string (path, cwd, signing ID, ...).
    static func clean(_ s: String) -> String {
        MCPUntrustedText.sanitize(maskText(MCPUntrustedText.sanitize(s, maxLength: premaskLimit)))
    }

    static func clean(_ s: String?) -> String? { s.map { clean($0) } }

    /// A whole argv: flag/value pairs are masked across element boundaries.
    static func cleanArgs(_ args: [String]?) -> [String]? {
        guard let args else { return nil }
        let stripped = args.map { MCPUntrustedText.sanitize($0, maxLength: premaskLimit) }
        return maskArgs(stripped).map { MCPUntrustedText.sanitize($0) }
    }

    // MARK: - Masking

    /// `--api-key`, `-token`, ... The rules live in `ExecCommandMasker` (Shared/) so the
    /// helper's masked search match uses exactly the same ones.
    static func isSensitiveFlagName(_ rawName: String) -> Bool { ExecCommandMasker.isSensitiveFlagName(rawName) }

    /// A whole argv: flag/value pairs are masked across element boundaries.
    static func maskArgs(_ args: [String]) -> [String] {
        ExecCommandMasker.maskArgs(args, marker: redactionMarker, text: maskText)
    }

    /// Masks secrets inside one string: URL credentials, bearer/basic tokens,
    /// `name=value` / `name: value` / `--flag value` for secret-looking names
    /// (also inside `sh -c '...'` bodies), then every known token format
    /// (`SecretLeakScanning.redact`: OpenAI/Anthropic/GitHub/AWS/..., private keys,
    /// crypto keys, mnemonics). `redact` compiles its patterns per call, so it is only
    /// run on strings long enough to hold any of those secrets.
    static func maskText(_ s: String) -> String {
        let result = ExecCommandMasker.maskStructural(s, marker: redactionMarker)
        return result.count >= 12 ? ExecCommandMasker.maskHighEntropy(SecretLeakScanning.redact(result), marker: redactionMarker) : result
    }
}

struct MCPExecEventPayload: Encodable {
    let seq: UInt64
    let time: String
    let kind: String
    let pid: Int32
    let ppid: Int32
    let uid: UInt32?
    let path: String
    let args: [String]?
    let cwd: String?
    let signature: String
    let signingID: String?
    let teamID: String?
    let cdhash: String?
    let exitStatus: Int32?
    /// The value of `DYLD_INSERT_LIBRARIES` when set on this exec, `nil`
    /// otherwise — the one deliberate exception to this recorder never
    /// reading environment variables (see `ExecEventRecord`'s doc comment).
    let dyldInsertLibraries: String?
}

struct MCPExecSearchPayload: Encodable {
    let recorder: MCPExecRecorderStatePayload
    let logReadable: Bool
    let matched: Int
    let scanTruncated: Bool
    let events: [MCPExecEventPayload]
    /// Why no data could be read (nil when the log was read).
    let unavailableReason: String?
    let caveats: [String]
}

struct MCPProcessNodePayload: Encodable {
    let depth: Int
    let pid: Int32
    let ppid: Int32
    let time: String
    let path: String
    let args: [String]?
    let signature: String
    let signingID: String?
    let teamID: String?
}

struct MCPProcessTreePayload: Encodable {
    let recorder: MCPExecRecorderStatePayload
    let logReadable: Bool
    let found: Bool
    let ancestors: [MCPProcessNodePayload]
    let process: MCPProcessNodePayload?
    let descendants: [MCPProcessNodePayload]
    let truncated: Bool
    let unavailableReason: String?
    let caveats: [String]
}

/// Sliding-window limit on `search_exec_events` calls that carry a text query. One MCP server
/// process serves one client session, so process-wide state is per session. A legitimate
/// investigation needs a handful of queries; probing for a secret needs thousands.
final class MCPExecSearchThrottle {
    static let shared = MCPExecSearchThrottle()

    let maxQueries: Int
    let window: Double
    private var stamps: [Double] = []
    private let lock = NSLock()

    init(maxQueries: Int = 20, window: Double = 60) {
        self.maxQueries = maxQueries
        self.window = window
    }

    /// Records the call and returns true when it is within the limit; a refused call is not recorded.
    func allow(now: Double = Date().timeIntervalSince1970) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        stamps.removeAll { now - $0 >= window }
        guard stamps.count < maxQueries else { return false }
        stamps.append(now)
        return true
    }
}

/// Answers an `ExecMCPMailbox.Request` (nil = no answer). The default asks the
/// running RoamSwitch app; tests inject a closure.
typealias ExecReadTransport = (ExecMCPMailbox.Request) -> ExecMCPMailbox.Response?

/// Read-only `search_exec_events` / `get_process_tree`. The exec log is
/// root-only (0700/0600: command lines may hold secrets) and this MCP process
/// cannot reach the helper's XPC service (its code signature is not the main
/// app's), so requests go through the app: `ExecMCPMailbox` (private per-user
/// directory) -> `ExecMCPBridge` in the app -> helper XPC. No network, never
/// writes the log, no exec data is stored outside the root-owned directory.
enum MCPExecRecorderTools {
    static let proRequiredMessage = "この機能はPro版限定です。RoamSwitchでPro版を有効化してください。"

    static func caveats() -> [String] {
        [
            loc("記録はmacOS標準のesloggerによる事後の観測で、実行のブロックはできません。ヘルパー起動前のプロセスや、記録を有効にする前のイベントは含まれません。"),
            loc("コマンドライン引数には機密情報が含まれる場合があります(環境変数は、DYLD_INSERT_LIBRARIES一つを除いて記録されません)。"),
            loc("時刻は記録時のもので、署名区分は platform=Apple / developer=Team ID付き / adhoc=アドホック / unsigned=署名なし です。"),
        ]
    }

    static func recorderState(defaults: UserDefaults, now: Date = Date()) -> MCPExecRecorderStatePayload {
        let enabled = defaults.bool(forKey: MCPResponseFormatting.execRecorderKey)
        let s = ExecRecorderStatus.read()
        let iso = ISO8601DateFormatter()
        return MCPExecRecorderStatePayload(
            enabledInSettings: enabled,
            state: s?.state ?? (enabled ? "unknown" : "stopped"),
            stateLabel: ExecRecorderText.status(s, enabled: enabled),
            eventsRecorded: s?.eventsRecorded,
            eventsDropped: s?.eventsDropped,
            malformedLines: s?.malformedLines,
            alertsRaised: s?.alertsRaised,
            statusUpdatedAt: s.map { iso.string(from: Date(timeIntervalSince1970: $0.updatedAt)) }
        )
    }

    /// ISO-8601 or a relative age like "30m", "2h", "7d" (ago). nil if unparsable.
    static func parseTimeArgument(_ s: String, now: Date = Date()) -> Double? {
        let t = s.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return nil }
        if let unit = t.last, "mhd".contains(unit), let n = Double(t.dropLast()), n >= 0 {
            let secs: Double = unit == "m" ? 60 : (unit == "h" ? 3600 : 86_400)
            return now.timeIntervalSince1970 - n * secs
        }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: t) { return d.timeIntervalSince1970 }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: t)?.timeIntervalSince1970
    }

    /// Every attacker-controlled string goes through `ExecOutputSanitizer` (control/format
    /// characters stripped, secrets masked, 300-character cap); callers must send the result
    /// with `textContentResult(_, untrusted: true)`.
    static func eventPayload(_ r: ExecEventRecord) -> MCPExecEventPayload {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return MCPExecEventPayload(
            seq: r.seq, time: iso.string(from: Date(timeIntervalSince1970: r.time)), kind: r.kind, pid: r.pid, ppid: r.ppid,
            uid: r.uid, path: ExecOutputSanitizer.clean(r.path), args: ExecOutputSanitizer.cleanArgs(r.args),
            cwd: ExecOutputSanitizer.clean(r.cwd), signature: r.signatureClass.rawValue,
            signingID: ExecOutputSanitizer.clean(r.signingID), teamID: ExecOutputSanitizer.clean(r.teamID),
            cdhash: ExecOutputSanitizer.clean(r.cdhash), exitStatus: r.exitStatus,
            dyldInsertLibraries: ExecOutputSanitizer.clean(r.dyldInsertLibraries)
        )
    }

    static func nodePayload(_ n: ExecProcessNode) -> MCPProcessNodePayload {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return MCPProcessNodePayload(
            depth: n.depth, pid: n.pid, ppid: n.ppid, time: iso.string(from: Date(timeIntervalSince1970: n.time)),
            path: ExecOutputSanitizer.clean(n.path), args: ExecOutputSanitizer.cleanArgs(n.args), signature: n.signature.rawValue,
            signingID: ExecOutputSanitizer.clean(n.signingID), teamID: ExecOutputSanitizer.clean(n.teamID)
        )
    }

    static let mailboxTransport: ExecReadTransport = { ExecMCPMailbox.submitAndWait($0) }

    /// Localized reason for a missing answer / error code from the app bridge.
    static func unavailableText(code: String?) -> String {
        switch code {
        case "pro_required": return loc(proRequiredMessage)
        case "rate_limited": return loc("検索語付きの検索が短時間に集中しました。しばらく待ってから再試行してください。")
        case "helper_unavailable", "bad_request":
            return loc("ヘルパーから実行記録を取得できませんでした。RoamSwitchHelperが動作しているか確認してください。")
        default:
            return loc("実行記録のログはroot専用で、RoamSwitchアプリと特権ヘルパー経由でのみ読み取れます。RoamSwitchアプリが起動していないか、応答がありませんでした。")
        }
    }

    /// A rejected query (too short / too frequent): same payload shape, no data, the reason in
    /// `unavailableReason`.
    private static func rejectedSearch(_ reason: String, defaults: UserDefaults, now: Date) -> MCPExecSearchPayload {
        MCPExecSearchPayload(recorder: recorderState(defaults: defaults, now: now), logReadable: false, matched: 0,
                             scanTruncated: false, events: [], unavailableReason: reason, caveats: caveats())
    }

    /// `arguments`: query (text), pid, ppid, since, until, kind (exec|fork|exit),
    /// signature (platform|developer|adhoc|unsigned), teamID, limit (1-200).
    ///
    /// `query` is matched by the helper against the secret-masked command line only
    /// (`maskedTextMatch`): matching the raw line would let an LLM (or an injected prompt)
    /// recover a secret one character at a time from whether a query hits. As further
    /// defence in depth a query must be at least `ExecCommandMasker.minQueryLength`
    /// characters, and text queries are rate-limited per MCP session (`MCPExecSearchThrottle`).
    static func search(arguments: [String: Any], defaults: UserDefaults, transport: ExecReadTransport = MCPExecRecorderTools.mailboxTransport, throttle: MCPExecSearchThrottle = .shared, now: Date = Date()) -> MCPExecSearchPayload {
        func int32(_ k: String) -> Int32? { (arguments[k] as? Int).flatMap { Int32(exactly: $0) } }
        let text = (arguments["query"] as? String).map { String($0.prefix(200)) }
        let since = (arguments["since"] as? String).flatMap { parseTimeArgument($0, now: now) }
        let until = (arguments["until"] as? String).flatMap { parseTimeArgument($0, now: now) }
        let kind = (arguments["kind"] as? String).flatMap { ["exec", "fork", "exit"].contains($0) ? $0 : nil }
        let sig = (arguments["signature"] as? String).flatMap { ExecSignatureClass(rawValue: $0) }
        let limit = min(max((arguments["limit"] as? Int) ?? 50, 1), 200)
        if let text, !text.isEmpty {
            guard ExecCommandMasker.normalizedNeedle(text).count >= ExecCommandMasker.minQueryLength else {
                return rejectedSearch(loc("検索語は3文字以上で指定してください(短い検索語でコマンドライン中の秘密を1文字ずつ探ることを防ぐためです)。"), defaults: defaults, now: now)
            }
            guard throttle.allow(now: now.timeIntervalSince1970) else {
                return rejectedSearch(loc("検索語付きの検索が短時間に集中しました。しばらく待ってから再試行してください。"), defaults: defaults, now: now)
            }
        }
        let request = ExecSearchRequest(text: text, pid: int32("pid"), ppid: int32("ppid"), since: since, until: until, kind: kind,
                                        signature: sig?.rawValue, teamID: arguments["teamID"] as? String, limit: limit,
                                        maskedTextMatch: true)
        let response = transport(ExecMCPMailbox.Request(op: "search", search: request))
        let reply = (response?.ok == true) ? response?.search : nil
        return MCPExecSearchPayload(
            recorder: recorderState(defaults: defaults, now: now),
            logReadable: reply?.readable ?? false,
            matched: reply?.events.count ?? 0,
            scanTruncated: (reply?.truncatedScan ?? false) || (reply?.truncatedReply ?? false),
            events: (reply?.events ?? []).map(eventPayload),
            unavailableReason: reply == nil ? unavailableText(code: response?.error) : nil,
            caveats: caveats()
        )
    }

    /// `arguments`: pid (required), at (time; default now), lookbackHours (1-168, default 24).
    static func processTree(arguments: [String: Any], defaults: UserDefaults, transport: ExecReadTransport = MCPExecRecorderTools.mailboxTransport, now: Date = Date()) -> MCPProcessTreePayload? {
        guard let pidInt = arguments["pid"] as? Int, let pid = Int32(exactly: pidInt) else { return nil }
        let at = (arguments["at"] as? String).flatMap { parseTimeArgument($0, now: now) }
        let lookbackHours = min(max((arguments["lookbackHours"] as? Int) ?? 24, 1), 168)
        let request = ExecProcessTreeRequest(pid: pid, at: at, lookbackHours: lookbackHours)
        let response = transport(ExecMCPMailbox.Request(op: "tree", tree: request))
        let reply = (response?.ok == true) ? response?.tree : nil
        let tree = reply?.tree
        return MCPProcessTreePayload(
            recorder: recorderState(defaults: defaults, now: now),
            logReadable: reply?.readable ?? false,
            found: tree?.node != nil,
            ancestors: (tree?.ancestors ?? []).map(nodePayload),
            process: tree?.node.map(nodePayload),
            descendants: (tree?.descendants ?? []).map(nodePayload),
            truncated: reply?.truncatedScan ?? false,
            unavailableReason: reply == nil ? unavailableText(code: response?.error) : nil,
            caveats: caveats()
        )
    }
}
