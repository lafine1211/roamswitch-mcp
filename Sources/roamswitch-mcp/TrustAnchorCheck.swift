// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.1 (build 180).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Audit check `trust_anchors`: has a certificate authority been added to what this Mac trusts?
///
/// A proxy that reads encrypted traffic (a company's inspection proxy, a developer's debugging proxy, or malware that
/// wants to) needs the Mac to trust its certificate authority. Apple's own roots are not in the trust settings
/// database at all; a certificate appears there only when a person, an administrator or a profile set a trust
/// setting for it. So the certificates with trust settings in the user and administrator domains are exactly the
/// ones somebody added.
///
/// This reads `security dump-trust-settings` for those two domains and changes nothing. A certificate whose trust
/// result is "deny" is a distrust, not an addition, and is not counted. Names that look like an interception tool
/// (a proxy, an analysis tool, a TLS-inspection product) fail the check; any other added certificate is reported as
/// information, because company and developer tools (mkcert, a corporate root) add theirs on purpose.
///
/// What it cannot see: a certificate an application carries for itself (it never touches the system trust), a
/// certificate trusted for one purpose only is still listed, and nothing says when a certificate was added.
struct TrustedCertificate: Equatable {
    let name: String
}

enum TrustAnchorCheck {

    /// Words that, in the name of an added authority, mark an interception tool.
    static let interceptionWords = ["mitm", "proxy", "charles", "fiddler", "burp", "portswigger", "zscaler", "netskope", "squid", "inspection", "sslsplit", "mitmproxy"]

    /// The reader the audit uses; the tests replace it. `nil` = could not be read.
    static var readCertificates: () -> [TrustedCertificate]? = { liveCertificates() }

    // MARK: Reading

    static func liveCertificates(run: CommandRunner = SystemCommand.run) -> [TrustedCertificate]? {
        var all: [TrustedCertificate] = []
        for args in [["dump-trust-settings"], ["dump-trust-settings", "-d"]] {
            guard let out = run("/usr/bin/security", args) else { return nil }
            guard let parsed = parse(out) else { return nil }
            all += parsed
        }
        var seen = Set<String>()
        return all.filter { seen.insert($0.name).inserted }
    }

    /// Pure. `nil` for an output that is neither a list nor the plain "no trust settings" answer.
    static func parse(_ out: CommandOutput) -> [TrustedCertificate]? {
        let text = out.stdout + "\n" + out.stderr
        if text.contains("No Trust Settings were found") { return [] }
        guard out.status == 0 else { return nil }
        var certs: [TrustedCertificate] = []
        var name: String?
        var denied = false
        func flush() {
            if let n = name, !denied { certs.append(TrustedCertificate(name: n)) }
            name = nil
            denied = false
        }
        var sawHeader = false
        for raw in out.stdout.split(separator: "\n", omittingEmptySubsequences: true) {
            let line = String(raw).trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("Number of trusted certs") { sawHeader = true; continue }
            if line.hasPrefix("Cert "), let colon = line.firstIndex(of: ":") {
                flush()
                sawHeader = true
                name = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
            } else if line.contains("kSecTrustSettingsResultDeny") {
                denied = true
            }
        }
        flush()
        return sawHeader ? certs : nil
    }

    static func looksLikeInterception(_ name: String) -> Bool {
        let lower = name.lowercased()
        return interceptionWords.contains { lower.contains($0) }
    }

    // MARK: Audit item

    static func item(_ certs: [TrustedCertificate]?) -> SecurityAuditItem {
        var isPassed = false
        var inconclusiveReason: String?
        var statusText: String
        var recommendation = loc("設定は万全です。")
        let detail = loc("ユーザーや管理者が「信頼する」と設定した証明書(認証局)を調べます。ここに、プロキシや傍受のための認証局があると、暗号化された通信(パスワードやAPIキーを含む)を、そのプロキシの運営者が読めてしまいます。Appleが標準で信頼する認証局は、数えません。キーチェーンの中身そのものや、アプリが自分で持つ証明書は確認しません。")
        func shown(_ list: [TrustedCertificate]) -> String {
            list.prefix(3).map { MCPUntrustedText.sanitize($0.name, maxLength: 60) }.joined(separator: ", ")
        }
        switch certs {
        case .none:
            statusText = loc("状態を確認できませんでした")
            inconclusiveReason = "not_verifiable"
        case .some(let list) where list.isEmpty:
            isPassed = true
            statusText = loc("追加で信頼している証明書はありません")
        case .some(let list):
            let suspicious = list.filter { looksLikeInterception($0.name) }
            if !suspicious.isEmpty {
                statusText = String(format: loc("⚠️ 通信を中継するソフトの証明書を信頼しています: %@"), shown(suspicious))
                recommendation = loc("使っていないプロキシ・解析ツールの証明書なら、キーチェーンアクセスで、その証明書の「信頼」を「システム設定を使用」に戻すか、削除してください。使っているなら、そのツールが読める通信を把握しておいてください。")
            } else {
                isPassed = true
                statusText = String(format: loc("追加で信頼している証明書が %d 件あります: %@(設定した覚えがあれば問題ありません)"), list.count, shown(list))
                recommendation = loc("設定した覚えがない場合は、キーチェーンアクセスで、その証明書の「信頼」の設定を確認してください。会社や開発ツール(mkcert など)が入れたものは、通常は問題ありません。")
            }
        }
        return SecurityAuditItem(
            category: loc("ネットワーク防御"),
            title: loc("追加された信頼する証明書(認証局)"),
            isPassed: isPassed,
            statusText: statusText,
            detail: detail,
            recommendation: recommendation,
            settingsURL: nil,
            checkId: "trust_anchors",
            inconclusiveReason: inconclusiveReason
        )
    }
}
