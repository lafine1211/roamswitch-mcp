// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.30 (build 209).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// The records that could not be read, so a reader is told "cannot be checked" instead of "none".
///
/// Each record is read by its owner (`StoredRecordDefaults` / `StoredRecordFile`, or the helper's answer over XPC);
/// the owner marks it here, and the menu shows one line while any is marked. A mark stays until the app quits: once a
/// later save has replaced the record, what it held before is only in the copy, so the list is still not complete. The MCP server, a process of its own,
/// reads the records itself and puts the same sentence (`message`) in its answer. In the MCP server target too.
enum StoredRecord: String, CaseIterable {
    case canaryIncidents
    case entropyAlerts
    case honeytokenEvents
    case browserCredentialEvents
    case portAnomalyIncidents
    case portScanIncidents
    case sshGuardIncidents
    case sshGuardSessions
    case ransomwareSnapshots
    case webRuleFindings
    case trustedKeychainReaders
    case networkHistory
    case findingHistory
    case recentDownloads
    case networkSettingsBaselines
    case logTemplateBaseline
    case probeLog
    case trustedSensors
    case sensorAuditResults
    case fileIntegrityBaseline
    case lockfileBaseline

    /// The record's name, in the app's language.
    var title: String { loc(titleKey) }

    /// The catalog key of `title`.
    var titleKey: String {
        switch self {
        case .canaryIncidents: return "おとりファイルの検知の記録"
        case .entropyAlerts: return "暗号化の検知の記録"
        case .honeytokenEvents: return "おとりの認証情報を読んだ記録"
        case .browserCredentialEvents: return "ブラウザーの保存パスワードを読んだ記録"
        case .portAnomalyIncidents: return "ポートの異常の記録"
        case .portScanIncidents: return "ポートスキャンの記録"
        case .sshGuardIncidents: return "SSHへの攻撃の記録"
        case .sshGuardSessions: return "SSHのログインの記録"
        case .ransomwareSnapshots: return "スナップショットの記録"
        case .webRuleFindings: return "Webの規則に一致したファイルの一覧"
        case .trustedKeychainReaders: return "許可したキーチェーンの読み手の一覧"
        case .networkHistory: return "ネットワークの履歴"
        case .findingHistory: return "前回までの診断の結果"
        case .recentDownloads: return "最近検査したダウンロードの一覧"
        case .networkSettingsBaselines: return "ネットワーク設定の基準"
        case .logTemplateBaseline: return "ログの基準"
        case .probeLog: return "脆弱性検査の記録"
        case .trustedSensors: return "ペアリングしたSensorの一覧"
        case .sensorAuditResults: return "Sensorの監査結果"
        case .fileIntegrityBaseline: return "重要なファイルの基準"
        case .lockfileBaseline: return "ロックファイルの基準"
        }
    }

    /// What the menu, a window and the MCP answer say while the record cannot be read.
    var message: String {
        String(format: loc(Self.messageKey), title)
    }

    static let messageKey = "%@を確認できません。保存されていた記録が壊れているか、読み込めませんでした。前の記録は消さずに別の名前で残します。"
}

enum StoredRecordHealth {
    private static let lock = NSLock()
    private static var marked: Set<StoredRecord> = []

    static func set(_ record: StoredRecord, unreadable: Bool) {
        lock.lock(); defer { lock.unlock() }
        if unreadable { marked.insert(record) } else { marked.remove(record) }
    }

    static func isUnreadable(_ record: StoredRecord) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return marked.contains(record)
    }

    /// In the order of `StoredRecord.allCases`.
    static var unreadable: [StoredRecord] {
        lock.lock(); defer { lock.unlock() }
        return StoredRecord.allCases.filter { marked.contains($0) }
    }

    /// The menu's line, or nil while every record could be read.
    static var menuTitle: String? {
        let list = unreadable
        guard !list.isEmpty else { return nil }
        return String(format: loc("⚠️ 確認できない記録があります (%d件)"), list.count)
    }

    static var menuTooltip: String {
        unreadable.map(\.message).joined(separator: "\n")
    }

    /// For a writer that replaces `key` with what it holds in memory: keeps the value it replaces when that cannot be
    /// read, and marks `record` (the earlier entries are then only in the copy).
    static func preserve<T: Decodable>(_ type: T.Type, key: String, defaults: UserDefaults, record: StoredRecord) {
        if StoredRecordDefaults.preserveIfUnreadable(type, key: key, defaults: defaults) { set(record, unreadable: true) }
    }

    /// The list a guard keeps in memory, as the last run saved it, so the first new entry after a restart is added to it
    /// instead of replacing it (the saved list is also what the MCP server answers with). Empty when nothing was saved;
    /// one that cannot be read is kept as `<key>.unreadable`, marked, and the guard starts from empty.
    static func restore<T: Decodable>(_ type: [T].Type, key: String, defaults: UserDefaults, record: StoredRecord) -> [T] {
        load(type, key: key, defaults: defaults, record: record).value(or: [])
    }

    /// Reads `key` for its owner (see `StoredRecordDefaults.load`) and marks `record`.
    static func load<T: Decodable>(_ type: T.Type, key: String, defaults: UserDefaults, record: StoredRecord) -> StoredRecordRead<T> {
        let read = StoredRecordDefaults.load(type, key: key, defaults: defaults)
        if read.isUnreadable { set(record, unreadable: true) }
        return read
    }
}
