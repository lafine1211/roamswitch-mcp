// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.2.2 (build 226).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import Security

/// Who signed the program that wrote a log line.
public enum LogAuditSigner: Equatable {
    case apple
    case team(String)
    case unsigned
    case invalid
    /// The program is not a file on disk (the kernel) or its path is not known.
    case unknown

    /// Looks the signature up. Reading a signature is a read of the file's embedded code signature: it runs nothing.
    static func lookup(path: String) -> LogAuditSigner {
        guard !path.isEmpty, path.hasPrefix("/"), FileManager.default.fileExists(atPath: path) else { return .unknown }
        var staticCode: SecStaticCode?
        guard SecStaticCodeCreateWithPath(URL(fileURLWithPath: path) as CFURL, [], &staticCode) == errSecSuccess,
              let code = staticCode else { return .unsigned }
        var info: CFDictionary?
        guard SecCodeCopySigningInformation(code, SecCSFlags(rawValue: kSecCSSigningInformation), &info) == errSecSuccess,
              let dict = info as? [String: Any],
              let identifier = dict[kSecCodeInfoIdentifier as String] as? String else { return .unsigned }
        let flags = (dict[kSecCodeInfoFlags as String] as? UInt32) ?? 0
        if flags & 0x2 != 0 { return .unsigned }   // ad hoc: no signer to name
        guard SecStaticCodeCheckValidity(code, SecCSFlags(rawValue: kSecCSDoNotValidateResources), nil) == errSecSuccess else {
            return .invalid
        }
        if let team = dict[kSecCodeInfoTeamIdentifier as String] as? String { return .team(team) }
        // No team identifier and a valid signature: a platform binary (Apple's own) carries the `com.apple.` identifier.
        return identifier.hasPrefix("com.apple.") ? .apple : .team(identifier)
    }
}

/// One kind of log line that turned up in this scan, with what the reader needs to judge it.
public struct LogAuditFinding: Equatable {
    public let kind: LogAuditKind
    public let severity: LogEventSeverity
    /// Lines of this kind in the examined window (for a crash series: the crashes of the app that crossed the threshold).
    public let count: Int
    public let firstSeen: Date
    public let process: String
    public let signer: LogAuditSigner
    public let example: String
    /// Mean lines per hour of this kind in earlier scans; nil while the history is still too short to say.
    public let pastMeanPerHour: Double?
    public let pastObservations: Int
    /// Lines per hour in this scan's window.
    public let ratePerHour: Double
}

/// What a scan's anomalies come to: findings the reader can judge, and the rest.
public struct LogAuditOutcome: Equatable {
    public var findings: [LogAuditFinding] = []
    /// Template anomalies (new or frequent) whose line belongs to no kind. They are kept in the history and never notify.
    public var unclassified: [LogTemplateAnomaly] = []
    public var isEmpty: Bool { findings.isEmpty && unclassified.isEmpty }
}

public enum LogAuditFindings {
    /// Scans before a kind's own frequency is stated as a past mean.
    public static let minObservationsForPastMean = 3

    /// Sorts the anomalies of one scan into findings and the unclassified rest.
    /// - `events`: the lines this scan examined (after the known noise was removed), oldest first.
    /// - `kindStats`: each kind's frequency history before this scan.
    /// Returns the outcome and the kind history after this scan (every kind gets this scan's count, zero included).
    static func evaluate(
        anomalies: [LogTemplateAnomaly],
        events: [SecurityLogEvent],
        hours: Int,
        kindStats: [String: TemplateFrequencyStats],
        signer: (String) -> LogAuditSigner = LogAuditSigner.lookup(path:)
    ) -> (outcome: LogAuditOutcome, updatedKindStats: [String: TemplateFrequencyStats]) {
        let window = Double(max(hours, 1))

        var exampleEvent: [String: SecurityLogEvent] = [:]
        var byKind: [LogAuditKind: [SecurityLogEvent]] = [:]
        for event in events {
            if exampleEvent[event.message] == nil { exampleEvent[event.message] = event }
            if let kind = event.kind { byKind[kind, default: []].append(event) }
        }

        var outcome = LogAuditOutcome()
        var anomaliesByKind: [LogAuditKind: [LogTemplateAnomaly]] = [:]
        for anomaly in anomalies {
            if let kind = exampleEvent[anomaly.example]?.kind, anomaly.count >= kind.minimumCount {
                anomaliesByKind[kind, default: []].append(anomaly)
            } else {
                outcome.unclassified.append(anomaly)
            }
        }

        for kind in LogAuditKind.allCases {
            guard let kindAnomalies = anomaliesByKind[kind], let top = kindAnomalies.first else { continue }
            let lines = byKind[kind] ?? []
            guard let first = lines.min(by: { $0.timestamp < $1.timestamp }) ?? exampleEvent[top.example] else { continue }
            let count = kind == .appCrashLoop ? kindAnomalies.map(\.count).reduce(0, +) : max(lines.count, top.count)
            let stats = kindStats[kind.rawValue]
            let mean = (stats?.observations ?? 0) >= minObservationsForPastMean ? stats?.mean : nil
            // A kernel line that says `panic` outranks the kind's usual severity (`OtherRule.severity`).
            let severity = lines.map(\.severity).contains(.critical) && kind == .kernelWarning ? LogEventSeverity.critical : kind.severity
            outcome.findings.append(LogAuditFinding(
                kind: kind, severity: severity, count: count, firstSeen: first.timestamp, process: first.process,
                signer: signer(first.processPath), example: top.example,
                pastMeanPerHour: mean, pastObservations: stats?.observations ?? 0, ratePerHour: Double(count) / window
            ))
        }
        outcome.findings.sort { rank($0.severity) > rank($1.severity) }

        var updated = kindStats
        for kind in LogAuditKind.allCases {
            var stats = updated[kind.rawValue] ?? TemplateFrequencyStats()
            stats.update(Double(byKind[kind]?.count ?? 0) / window)
            updated[kind.rawValue] = stats
        }
        return (outcome, updated)
    }

    private static func rank(_ s: LogEventSeverity) -> Int {
        switch s { case .critical: return 2; case .warning: return 1; case .info: return 0 }
    }

    // MARK: - Kind frequency history (UserDefaults, the same domain as the template baseline)

    private static let kindStatsKey = "RoamSwitch.LogTemplateBaseline.KindFrequencyV1"

    static func loadKindStats(defaults: UserDefaults? = nil) -> [String: TemplateFrequencyStats] {
        let store = defaults ?? AppLanguage.sharedDefaults
        guard let data = store.data(forKey: kindStatsKey),
              let decoded = try? JSONDecoder().decode([String: TemplateFrequencyStats].self, from: data) else { return [:] }
        return decoded
    }

    static func saveKindStats(_ stats: [String: TemplateFrequencyStats], defaults: UserDefaults? = nil) {
        let store = defaults ?? AppLanguage.sharedDefaults
        if let data = try? JSONEncoder().encode(stats) { store.set(data, forKey: kindStatsKey) }
    }
}

// MARK: - The notice

/// The text of the scheduled log audit's notice and of its history-only record, in one language (`code`).
/// Conclusion, then what to do, then the cause, then the facts a reader judges by; the statistics are not in the text.
public enum LogAuditNotice {
    /// Findings written in full; the rest are named by count.
    static let maxFindingsInBody = 3
    /// Raw lines shown in the history-only record.
    static let maxUnclassifiedExamples = 3

    /// The three texts of a kind. Keys are written out in full so the catalog and the source stay in step.
    static func keys(_ kind: LogAuditKind) -> (title: String, action: String, cause: String) {
        switch kind {
        case .sudoFailure:
            return ("sudo の認証に %d 回失敗しました",
                    "心当たりがなければ、管理者パスワードを変更し、システム設定の「ユーザとグループ」に見覚えのないアカウントがないか確かめてください。",
                    "sudo は管理者の権限でコマンドを実行する命令です。パスワードが受け付けられなかった記録です。")
        case .remoteLoginFailure:
            return ("SSH のログインに %d 回失敗しました",
                    "この Mac に SSH で入る予定がなければ、システム設定の「一般」→「共有」でリモートログインをオフにしてください。",
                    "ネットワーク越しにこの Mac へのログインが試され、拒否された記録です。接続元は下の確認コマンドで見られます。")
        case .remoteLoginAccepted:
            return ("SSH でこの Mac にログインされました(%d 回)",
                    "自分や管理者の接続でなければ、リモートログインをオフにして、パスワードを変更してください。",
                    "ネットワーク越しのログインが受け付けられた記録です。接続元と使われたアカウントは下の確認コマンドで見られます。")
        case .localAuthFailure:
            return ("ログインや認証の失敗が %d 件ありました",
                    "自分の操作でなければ、Mac の近くにいた人を思い出し、続くときはログインパスワードを変更してください。",
                    "ログイン画面や管理者の認証ダイアログで、パスワードが受け付けられなかった記録です。")
        case .privilegeEscalation:
            return ("管理者権限での実行が %d 件ありました",
                    "自分の操作なら、対応は要りません。心当たりがなければ、下の確認コマンドで実行された内容を確かめてください。",
                    "sudo や管理者の認証で、コマンドやアプリが管理者の権限を得た記録です。")
        case .tccChanged:
            return ("アプリへのプライバシー権限の変更が %d 件ありました",
                    "自分で変えていなければ、システム設定の「プライバシーとセキュリティ」で、許可されているアプリを確かめてください。",
                    "カメラ、マイク、フルディスクアクセスなどの許可が、リセットまたは書き換えられた記録です。")
        case .gatekeeperBlock:
            return ("Gatekeeper の判定で「許可」にならなかったプログラムが %d 件ありました",
                    "開いた覚えのないアプリなら、実行せずに、入手元を確かめてください。ビルドやテストが作るプログラムでも出ます。",
                    "署名がない、または開発元を確認できないプログラムを、macOS の Gatekeeper が評価した記録です。実際に止められたとは限りません。")
        case .kernelWarning:
            return ("カーネルの警告(パニックやウォッチドッグ)が %d 件ありました",
                    "再起動や固まりが続くときは、macOS を最新に更新し、周辺機器を外して試してください。直らなければ Apple に相談してください。",
                    "macOS の中核(カーネル)が、異常停止や応答なしを記録した行です。")
        case .diskFailure:
            return ("ディスクやファイルシステムのエラーが %d 件ありました",
                    "先にバックアップを取り、ディスクユーティリティの「First Aid」で調べてください。外付けディスクなら、ケーブルを替えて試してください。",
                    "ディスクの読み書きに失敗した、またはファイルシステムの破損が見つかった記録です。")
        case .appCrashLoop:
            return ("アプリのクラッシュが続いています(%d 回)",
                    "アプリを最新版に更新してください。直らなければ、入れ直すか、開発元に報告してください。見覚えのないアプリなら、削除してください。",
                    "同じアプリが、短い間に何度も異常終了した記録です。")
        }
    }

    /// Every catalog key the notice and the history record can use (the source of the catalog tests and the script).
    static var allKeys: [String] {
        var keys: [String] = []
        for kind in LogAuditKind.allCases {
            let k = Self.keys(kind)
            keys += [k.title, k.action, k.cause]
        }
        keys += [
            "ログ監査: %@", "ログ監査: %d 種類のログを確認してください", "対応: %@", "原因: %@",
            "出どころ: %@(%@)", "出どころ: %@", "Apple の署名", "開発元の署名(Team ID %@)", "署名なし", "署名が壊れている",
            "初出: %@",
            "同じ種類の過去の頻度: 1 時間あたり平均 %.1f 件(過去 %d 回の確認)。今回は 1 時間あたり %.1f 件",
            "同じ種類の過去の頻度: まだ学習中です(%d 回の確認)。今回は 1 時間あたり %.1f 件",
            "確認: %@", "ほか %d 種類は、通知履歴に記録しました",
            "ログ監査: 分類できない新出パターン %d 件",
            "通知はしていません。種類(認証の失敗など)を判断できないため、通知履歴にだけ記録しました。対応は要りません。気になるときは「Macセキュリティログ監査」の「テンプレート異常」で見られます。",
            "新規 %d 件・頻度が上がったもの %d 件",
        ]
        return keys
    }

    static func signerText(_ signer: LogAuditSigner, code: String) -> String? {
        switch signer {
        case .apple: return loc("Apple の署名", localeCode: code)
        case .team(let id): return locFormat("開発元の署名(Team ID %@)", localeCode: code, id)
        case .unsigned: return loc("署名なし", localeCode: code)
        case .invalid: return loc("署名が壊れている", localeCode: code)
        case .unknown: return nil
        }
    }

    /// The notice for the findings of one scan: title and body. Nil when there is nothing to say.
    static func compose(_ findings: [LogAuditFinding], code: String = AppLanguage.activeLocaleCode) -> (title: String, body: String)? {
        guard let top = findings.first else { return nil }
        let icon = findings.contains { $0.severity == .critical } ? "🚨 " : (findings.contains { $0.severity == .warning } ? "⚠️ " : "ℹ️ ")
        let title: String
        if findings.count == 1 {
            title = icon + locFormat("ログ監査: %@", localeCode: code,
                                     locFormat(keys(top.kind).title, localeCode: code, top.count))
        } else {
            title = icon + locFormat("ログ監査: %d 種類のログを確認してください", localeCode: code, findings.count)
        }

        let time = DateFormatter()
        time.locale = Locale(identifier: code)
        time.dateStyle = .none
        time.timeStyle = .short

        var blocks: [String] = []
        for f in findings.prefix(maxFindingsInBody) {
            let k = keys(f.kind)
            var lines: [String] = [
                locFormat(k.title, localeCode: code, f.count),
                locFormat("対応: %@", localeCode: code, loc(k.action, localeCode: code)),
                locFormat("原因: %@", localeCode: code, loc(k.cause, localeCode: code)),
            ]
            if !f.process.isEmpty {
                if let signer = signerText(f.signer, code: code) {
                    lines.append(locFormat("出どころ: %@(%@)", localeCode: code, f.process, signer))
                } else {
                    lines.append(locFormat("出どころ: %@", localeCode: code, f.process))
                }
            }
            lines.append(locFormat("初出: %@", localeCode: code, time.string(from: f.firstSeen)))
            if let mean = f.pastMeanPerHour {
                lines.append(locFormat("同じ種類の過去の頻度: 1 時間あたり平均 %.1f 件(過去 %d 回の確認)。今回は 1 時間あたり %.1f 件",
                                       localeCode: code, mean, f.pastObservations, f.ratePerHour))
            } else {
                lines.append(locFormat("同じ種類の過去の頻度: まだ学習中です(%d 回の確認)。今回は 1 時間あたり %.1f 件",
                                       localeCode: code, f.pastObservations, f.ratePerHour))
            }
            lines.append(locFormat("確認: %@", localeCode: code, f.kind.checkCommand))
            blocks.append(lines.joined(separator: "\n"))
        }
        if findings.count > maxFindingsInBody {
            blocks.append(locFormat("ほか %d 種類は、通知履歴に記録しました", localeCode: code, findings.count - maxFindingsInBody))
        }
        return (title, blocks.joined(separator: "\n\n"))
    }

    /// Whether the findings are delivered as a notice (`warning` or `critical`) or only written to the history (`info`).
    static func interrupts(_ findings: [LogAuditFinding]) -> Bool {
        findings.contains { $0.severity != .info }
    }

    /// The history-only record of the anomalies that belong to no kind. Nil when there are none.
    static func composeUnclassified(_ anomalies: [LogTemplateAnomaly], code: String = AppLanguage.activeLocaleCode) -> (title: String, body: String)? {
        guard !anomalies.isEmpty else { return nil }
        let newCount = anomalies.filter(\.isNew).count
        var lines = [
            loc("通知はしていません。種類(認証の失敗など)を判断できないため、通知履歴にだけ記録しました。対応は要りません。気になるときは「Macセキュリティログ監査」の「テンプレート異常」で見られます。", localeCode: code),
            locFormat("新規 %d 件・頻度が上がったもの %d 件", localeCode: code, newCount, anomalies.count - newCount),
        ]
        lines += anomalies.prefix(maxUnclassifiedExamples).map { "- " + $0.example }
        return (locFormat("ログ監査: 分類できない新出パターン %d 件", localeCode: code, anomalies.count), lines.joined(separator: "\n"))
    }
}
