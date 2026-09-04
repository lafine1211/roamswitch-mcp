// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.8.3 (build 50).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

public enum PortSecurityRiskLevel: String, Equatable {
    case safe
    case warning
    case critical

    public var badge: String {
        switch self {
        case .safe: return "🟢 " + loc("安全")
        case .warning: return "🟡 " + loc("注意")
        case .critical: return "🔴 " + loc("高リスク")
        }
    }
}

public struct PortAuditFinding: Identifiable, Equatable {
    public var id: String { title }
    public let title: String
    public let riskLevel: PortSecurityRiskLevel
    public let description: String
    public let recommendation: String
}

public struct PortSecurityAuditResult: Identifiable, Equatable {
    public var id: String { "\(portInfo.port):\(portInfo.pid)" }
    public let portInfo: ListeningPortInfo
    public let overallRisk: PortSecurityRiskLevel
    public let isFirewallShielded: Bool
    public let findings: [PortAuditFinding]
    public let httpHeaders: [String: String]?
}

final class PortSecurityAuditor {
    static let shared = PortSecurityAuditor()

    func auditPort(
        portInfo: ListeningPortInfo,
        isFirewallBlocking: Bool,
        completion: @escaping (PortSecurityAuditResult) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            var findings: [PortAuditFinding] = []

            // 1. Binding Interface Exposure Audit (0.0.0.0 vs 127.0.0.1)
            if portInfo.isGloballyExposed {
                if isFirewallBlocking {
                    findings.append(PortAuditFinding(
                        title: loc("0.0.0.0 バインド（全LAN公開設定）"),
                        riskLevel: .warning,
                        description: loc("プロセスが0.0.0.0（全インターフェース）で待ち受けています。RoamSwitchのファイアウォールにより外部遮断中ですが、設定自体の見直しを推奨します。"),
                        recommendation: loc("開発サーバーの起動オプションでホストを 127.0.0.1 (localhost) に限定してください（例: --host 127.0.0.1 または app.listen(port, '127.0.0.1')）。")
                    ))
                } else {
                    findings.append(PortAuditFinding(
                        title: loc("0.0.0.0 バインド（同一Wi-Fi・LANに完全露出中）"),
                        riskLevel: .critical,
                        description: loc("同一ネットワーク（Wi-Fi）に接続している他のPCやスマホから、このポートへのアクセスが可能です。"),
                        recommendation: loc("直ちにバインド先を 127.0.0.1 (localhost) に変更するか、RoamSwitchでファイアウォール（標準保護または最大ロックダウン）を有効にしてください。")
                    ))
                }
            } else {
                findings.append(PortAuditFinding(
                    title: loc("ローカル限定バインド (127.0.0.1)"),
                    riskLevel: .safe,
                    description: loc("このポートは自分自身のMac (localhost) からのみアクセス可能です。同一LANの他端末からは隔離されています。"),
                    recommendation: loc("現在の設定を維持してください。")
                ))
            }

            // 2. Known Dangerous / Unauthenticated Ports Audit
            if let knownRisk = self.checkKnownDangerousPort(port: portInfo.port, isGlobal: portInfo.isGloballyExposed, isFirewallBlocking: isFirewallBlocking) {
                findings.append(knownRisk)
            }

            // 3. HTTP / CORS / Security Header Probe (for HTTP-like ports)
            let (headers, httpFindings) = self.probeHTTPService(port: portInfo.port)
            findings.append(contentsOf: httpFindings)

            // Calculate Overall Risk
            let overall: PortSecurityRiskLevel
            if findings.contains(where: { $0.riskLevel == .critical }) {
                overall = .critical
            } else if findings.contains(where: { $0.riskLevel == .warning }) {
                overall = .warning
            } else {
                overall = .safe
            }

            let result = PortSecurityAuditResult(
                portInfo: portInfo,
                overallRisk: overall,
                isFirewallShielded: isFirewallBlocking,
                findings: findings,
                httpHeaders: headers
            )

            completion(result)
        }
    }

    // MARK: - Proactive critical-exposure alerting

    /// Port → service name for backend/data services that are unauthenticated
    /// by default and therefore critical the instant they're reachable from
    /// the LAN (e.g. an accidentally 0.0.0.0-bound Redis or MongoDB left
    /// running). Used by `AppState` to proactively notify the moment one is
    /// seen globally exposed, rather than waiting for the user to think to
    /// open the port audit sheet themselves. Deliberately a narrower list
    /// than `checkKnownDangerousPort` below (which also covers ports that
    /// are only ever "warning" level, like FTP/Telnet) — this one is only
    /// for ports worth an unprompted alert.
    static let criticalUnauthenticatedServicePorts: [Int: String] = [
        6379: "Redis",
        27017: "MongoDB",
        9200: "Elasticsearch",
        9300: "Elasticsearch",
        2375: "Docker",
        11211: "Memcached",
        11434: "Ollama",
        1234: "LM Studio",
        7860: "Gradio",
        8000: "vLLM",
    ]

    // MARK: - Known Ports Database

    private func checkKnownDangerousPort(port: Int, isGlobal: Bool, isFirewallBlocking: Bool) -> PortAuditFinding? {
        let riskLevel: PortSecurityRiskLevel = (isGlobal && !isFirewallBlocking) ? .critical : .warning

        switch port {
        case 11434:
            return PortAuditFinding(
                title: loc("Ollama ローカルLLM API 露出リスク"),
                riskLevel: riskLevel,
                description: loc("Ollamaはデフォルトで未認証のHTTP APIを提供します。外部露出時に同一ネットワークから勝手にAIモデルを実行・ダウンロード・削除される危険があります。"),
                recommendation: loc("環境変数 OLLAMA_HOST=127.0.0.1 を指定して起動するか、RoamSwitchのファイアウォールで外部遮断してください。")
            )
        case 1234:
            return PortAuditFinding(
                title: loc("LM Studio ローカル推論サーバー露出リスク"),
                riskLevel: riskLevel,
                description: loc("LM Studioのローカルサーバー機能が外部公開されており、未認証でAPI呼び出しや推論リソースを不正利用される恐れがあります。"),
                recommendation: loc("LM StudioのDeveloper設定でローカルネットワーク共有をオフにし、localhost (127.0.0.1) 限定に設定してください。")
            )
        case 7860:
            return PortAuditFinding(
                title: loc("Gradio / AI WebUI 露出リスク"),
                riskLevel: riskLevel,
                description: loc("GradioやAI WebUIが外部公開されており、未認証で推論実行やファイル操作を行われる危険があります。"),
                recommendation: loc("起動オプションで --share や 0.0.0.0 バインドを控え、127.0.0.1 限定にするか認証を有効にしてください。")
            )
        case 8000:
            return PortAuditFinding(
                title: loc("vLLM / ローカルAI推論エンドポイント露出リスク"),
                riskLevel: riskLevel,
                description: loc("vLLM等の推論サーバーが未認証で外部公開されている場合、GPUリソースの不正利用や機密プロンプトの盗聴リスクがあります。"),
                recommendation: loc("--host 127.0.0.1 を指定して起動するか、APIキー認証を有効にしてください。")
            )
        case 6379:
            return PortAuditFinding(
                title: loc("Redis キャッシュ/データベース露出リスク"),
                riskLevel: riskLevel,
                description: loc("Redisはデフォルトで認証なしで動作することが多く、外部露出時に不正コマンド実行やデータ改ざんの対象になりやすいポートです。"),
                recommendation: loc("redis.conf で bind 127.0.0.1 および requirepass (認証パスワード) を設定してください。")
            )
        case 27017:
            return PortAuditFinding(
                title: loc("MongoDB データベース露出リスク"),
                riskLevel: riskLevel,
                description: loc("開発用MongoDBが認証無効のまま外部公開されていると、ランサムウェアや全データ窃取のリスクがあります。"),
                recommendation: loc("mongod.conf で bindIp: 127.0.0.1 を指定し、--auth を有効にしてください。")
            )
        case 9200, 9300:
            return PortAuditFinding(
                title: loc("Elasticsearch REST API 露出リスク"),
                riskLevel: riskLevel,
                description: loc("ElasticsearchのHTTP REST APIは未認証でインデックスの全読み書きが可能な場合があります。"),
                recommendation: loc("elasticsearch.yml で network.host: 127.0.0.1 を指定し、xpack.security を有効にしてください。")
            )
        case 2375:
            return PortAuditFinding(
                title: loc("Docker デーモン未暗号化TCPソケット (極めて危険)"),
                riskLevel: .critical,
                description: loc("未認証のDocker TCPソケットにアクセスできる攻撃者は、ホストOSに対するroot権限の奪取が可能です。"),
                recommendation: loc("TCPソケット 0.0.0.0:2375 の開放を停止し、UnixドメインソケットまたはTLS認証付き(2376)を使用してください。")
            )
        case 11211:
            return PortAuditFinding(
                title: loc("Memcached 露出リスク"),
                riskLevel: riskLevel,
                description: loc("Memcachedは認証なしで動作し、キャッシュ改ざんやDDoSリフレクション攻撃の踏み台にされる危険があります。"),
                recommendation: loc("-l 127.0.0.1 オプションを指定して起動してください。")
            )
        case 21, 23:
            return PortAuditFinding(
                title: loc("旧式平文プロトコル (FTP / Telnet) の検出"),
                riskLevel: .warning,
                description: loc("通信が暗号化されないため、同一Wi-Fi上の攻撃者によりパスワードや転送データが平文で盗聴されます。"),
                recommendation: loc("SFTP / SSH などの暗号化された安全なプロトコルへ移行してください。")
            )
        case 5900...5905:
            return PortAuditFinding(
                title: loc("VNC / 画面共有ポートの露出"),
                riskLevel: isGlobal ? .warning : .safe,
                description: loc("画面共有サービスが待ち受けています。強固なパスワードまたはSSHトンネル経由での接続が推奨されます。"),
                recommendation: loc("不要な場合はシステム設定から「画面共有」をオフにしてください。")
            )
        default:
            return nil
        }
    }

    // MARK: - Non-destructive HTTP Probe

    private func probeHTTPService(port: Int) -> ([String: String]?, [PortAuditFinding]) {
        guard let url = URL(string: "http://127.0.0.1:\(port)/") else {
            return (nil, [])
        }

        var request = URLRequest(url: url, timeoutInterval: 1.2)
        request.httpMethod = "GET"
        request.setValue("RoamSwitch-Security-Auditor/1.0", forHTTPHeaderField: "User-Agent")

        let semaphore = DispatchSemaphore(value: 0)
        var responseHeaders: [String: String]? = nil
        var findings: [PortAuditFinding] = []

        let task = URLSession.shared.dataTask(with: request) { _, response, _ in
            if let http = response as? HTTPURLResponse {
                var headerMap: [String: String] = [:]
                for (k, v) in http.allHeaderFields {
                    if let key = k as? String, let val = v as? String {
                        headerMap[key.lowercased()] = val
                    }
                }
                responseHeaders = headerMap

                // Check CORS Wildcard
                if let cors = headerMap["access-control-allow-origin"], cors.trimmingCharacters(in: .whitespaces) == "*" {
                    findings.append(PortAuditFinding(
                        title: loc("CORS 全ドメイン許可 (*) の検出"),
                        riskLevel: .warning,
                        description: loc("Access-Control-Allow-Origin: * が設定されています。ブラウザで閲覧中の悪意あるWebサイトから、このローカルAPIへクロスオリジン通信が送信されるリスクがあります。"),
                        recommendation: loc("開発時であっても信頼できるオリジン（例: http://localhost:5173）のみを明示的に許可してください。")
                    ))
                }

                // Check Server banner information disclosure
                if let server = headerMap["server"], !server.isEmpty {
                    findings.append(PortAuditFinding(
                        title: String(format: loc("サーバー製品情報ヘッダーの露出 (%@)"), server),
                        riskLevel: .warning,
                        description: loc("Server ヘッダーにより使用中のWebサーバーソフトウェアやバージョンが外部に漏洩しています。"),
                        recommendation: loc("本番設定では Server ヘッダーや X-Powered-By ヘッダーの出力を無効化（隠蔽）してください。")
                    ))
                }

                if let poweredBy = headerMap["x-powered-by"], !poweredBy.isEmpty {
                    findings.append(PortAuditFinding(
                        title: String(format: loc("フレームワーク情報ヘッダーの露出 (%@)"), poweredBy),
                        riskLevel: .warning,
                        description: loc("X-Powered-By ヘッダーにより使用中のバックエンドフレームワークが露出しています。"),
                        recommendation: loc("app.disable('x-powered-by') などでヘッダーを削除してください。")
                    ))
                }

                // Check Missing basic security headers
                if headerMap["x-content-type-options"] == nil {
                    findings.append(PortAuditFinding(
                        title: loc("MIMEスニッフィング防止ヘッダー (X-Content-Type-Options) の欠落"),
                        riskLevel: .safe,
                        description: loc("X-Content-Type-Options: nosniff が設定されていません。"),
                        recommendation: loc("レスポンスヘッダーに X-Content-Type-Options: nosniff を追加することを推奨します。")
                    ))
                }
            }
            semaphore.signal()
        }

        task.resume()
        _ = semaphore.wait(timeout: .now() + 1.5)

        return (responseHeaders, findings)
    }
}
