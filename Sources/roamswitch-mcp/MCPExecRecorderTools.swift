// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.10.4 (build 122).
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
        case "needsFullDiskAccess": return loc("実行記録は利用できません: RoamSwitchHelperにフルディスクアクセスが必要です")
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

    static func eventPayload(_ r: ExecEventRecord) -> MCPExecEventPayload {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return MCPExecEventPayload(
            seq: r.seq, time: iso.string(from: Date(timeIntervalSince1970: r.time)), kind: r.kind, pid: r.pid, ppid: r.ppid,
            uid: r.uid, path: r.path, args: r.args, cwd: r.cwd, signature: r.signatureClass.rawValue,
            signingID: r.signingID, teamID: r.teamID, cdhash: r.cdhash, exitStatus: r.exitStatus,
            dyldInsertLibraries: r.dyldInsertLibraries
        )
    }

    static func nodePayload(_ n: ExecProcessNode) -> MCPProcessNodePayload {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return MCPProcessNodePayload(
            depth: n.depth, pid: n.pid, ppid: n.ppid, time: iso.string(from: Date(timeIntervalSince1970: n.time)),
            path: n.path, args: n.args, signature: n.signature.rawValue, signingID: n.signingID, teamID: n.teamID
        )
    }

    static let mailboxTransport: ExecReadTransport = { ExecMCPMailbox.submitAndWait($0) }

    /// Localized reason for a missing answer / error code from the app bridge.
    static func unavailableText(code: String?) -> String {
        switch code {
        case "pro_required": return loc(proRequiredMessage)
        case "helper_unavailable", "bad_request":
            return loc("ヘルパーから実行記録を取得できませんでした。RoamSwitchHelperが動作しているか確認してください。")
        default:
            return loc("実行記録のログはroot専用で、RoamSwitchアプリと特権ヘルパー経由でのみ読み取れます。RoamSwitchアプリが起動していないか、応答がありませんでした。")
        }
    }

    /// `arguments`: query (text), pid, ppid, since, until, kind (exec|fork|exit),
    /// signature (platform|developer|adhoc|unsigned), teamID, limit (1-200).
    static func search(arguments: [String: Any], defaults: UserDefaults, transport: ExecReadTransport = MCPExecRecorderTools.mailboxTransport, now: Date = Date()) -> MCPExecSearchPayload {
        func int32(_ k: String) -> Int32? { (arguments[k] as? Int).flatMap { Int32(exactly: $0) } }
        let text = (arguments["query"] as? String).map { String($0.prefix(200)) }
        let since = (arguments["since"] as? String).flatMap { parseTimeArgument($0, now: now) }
        let until = (arguments["until"] as? String).flatMap { parseTimeArgument($0, now: now) }
        let kind = (arguments["kind"] as? String).flatMap { ["exec", "fork", "exit"].contains($0) ? $0 : nil }
        let sig = (arguments["signature"] as? String).flatMap { ExecSignatureClass(rawValue: $0) }
        let limit = min(max((arguments["limit"] as? Int) ?? 50, 1), 200)
        let request = ExecSearchRequest(text: text, pid: int32("pid"), ppid: int32("ppid"), since: since, until: until, kind: kind,
                                        signature: sig?.rawValue, teamID: arguments["teamID"] as? String, limit: limit)
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
