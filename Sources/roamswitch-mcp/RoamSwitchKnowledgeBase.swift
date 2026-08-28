// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.4.6 (build 20).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Comprehensive, authoritative offline knowledge base for RoamSwitch.
/// Exposes full product specifications, internal mechanics, alert message advice,
/// settings guidance, and troubleshooting information to MCP clients and tests.
public struct RoamSwitchKnowledgeBase: Sendable {
    public static let shared = RoamSwitchKnowledgeBase()

    // MARK: - Models

    public struct KnowledgeItem: Codable, Sendable, Equatable {
        public let id: String
        public let topic: String
        public let title: String
        public let summary: String
        public let details: String
        public let recommendation: String?
        public let tags: [String]

        public init(
            id: String,
            topic: String,
            title: String,
            summary: String,
            details: String,
            recommendation: String? = nil,
            tags: [String] = []
        ) {
            self.id = id
            self.topic = topic
            self.title = title
            self.summary = summary
            self.details = details
            self.recommendation = recommendation
            self.tags = tags
        }
    }

    public struct KnowledgeSearchResult: Codable, Sendable, Equatable {
        public let query: String?
        public let topic: String?
        public let totalResults: Int
        public let items: [KnowledgeItem]

        public init(query: String?, topic: String?, totalResults: Int, items: [KnowledgeItem]) {
            self.query = query
            self.topic = topic
            self.totalResults = totalResults
            self.items = items
        }
    }

    // MARK: - Knowledge Database

    public let allItems: [KnowledgeItem]

    public init() {
        var items: [KnowledgeItem] = []

        // 1. Features
        items.append(contentsOf: Self.buildFeatures())

        // 2. Alert Messages & Advice
        items.append(contentsOf: Self.buildAlertMessages())

        // 3. Settings & Operations
        items.append(contentsOf: Self.buildSettings())

        // 4. Troubleshooting & FAQ
        items.append(contentsOf: Self.buildTroubleshooting())

        self.allItems = items
    }

    // MARK: - Search API

    public func search(query: String? = nil, topic: String? = nil) -> KnowledgeSearchResult {
        let trimmedQuery = query?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedTopic = topic?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        var filtered = allItems

        if let topic = trimmedTopic, !topic.isEmpty, topic != "all" {
            filtered = filtered.filter { $0.topic.lowercased() == topic }
        }

        if let q = trimmedQuery, !q.isEmpty {
            let tokens = q.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            filtered = filtered.filter { item in
                let targetText = "\(item.title) \(item.summary) \(item.details) \(item.recommendation ?? "") \(item.tags.joined(separator: " "))".lowercased()
                return tokens.allSatisfy { targetText.contains($0) }
            }
        }

        return KnowledgeSearchResult(
            query: query,
            topic: topic,
            totalResults: filtered.count,
            items: filtered
        )
    }

    // MARK: - MCP Resource Documents

    public func resource(for uri: String) -> String? {
        switch uri {
        case "roamswitch://docs/features":
            return generateFeaturesMarkdown()
        case "roamswitch://docs/alerts-and-messages":
            return generateAlertsMarkdown()
        case "roamswitch://docs/settings-guide":
            return generateSettingsMarkdown()
        case "roamswitch://docs/troubleshooting":
            return generateTroubleshootingMarkdown()
        default:
            return nil
        }
    }

    // MARK: - Internal Builders: Features

    private static func buildFeatures() -> [KnowledgeItem] {
        return [
            KnowledgeItem(
                id: "feat_network_autoswitch",
                topic: "feature",
                title: "自動ネットワークセキュリティ切替 & PFパケットフィルタ (3段階レベル)",
                summary: "接続先ネットワーク（BSSID/ゲートウェイMAC/IP）を常時監視し、未登録Wi-Fiでは自動で最大ロックダウンを適用。PFパケットフィルタとステルスモードでMacを防御します。",
                details: """
                • 🟢 信頼 (Trusted / Open): 自宅・専用オフィス等。ファイアウォール解除、共有サービス（SSH/SMB/VNC/画面共有）およびAirDropを許可。
                • 🟡 標準保護 (Protected / Filter): 職場・テザリング等。PFパケットフィルタ有効、ステルスモードで外部探査を遮断しつつ、共有サービスを維持。
                • 🔴 最大ロックダウン (Lockdown): カフェ・公衆Wi-Fi・未登録ネットワーク等。PFパケットフィルタ全遮断、ステルスモード、共有デーモン停止、AirDrop完全無効化。
                • 内部構造: 特権ヘルパー `RoamSwitchHelper`（XPC経由）が `/sbin/pfctl` の専用アンカー `com.tetsuharu.roamswitch` を操作。カーネルレベルでパケットを破棄（drop）。
                • 手動オーバーライド: 「1時間だけ」「次回ネットワーク切断まで」「手動変更まで」を指定可能。移動時は自動解除され安全を維持。
                """,
                recommendation: "自宅・安全なオフィスは「現在のネットワークを登録」から登録し、外出先では常に「最大ロックダウン」が自動適用される状態で運用してください。",
                tags: ["network", "firewall", "pf", "packet filter", "lockdown", "stealth", "airdrop", "ssh", "smb"]
            ),
            KnowledgeItem(
                id: "feat_arp_spoof_guard",
                topic: "feature",
                title: "ARPスプーフィング（なりすまし通信）検知 & 自動隔離",
                summary: "同一Wi-Fi内の攻撃者がルーターになりすまして通信を盗聴・改ざんするARPスプーフィング（中間者攻撃 / MITM）をリアルタイム検知し、自動遮断します。",
                details: """
                • 動作原理: 定期的にローカルARPテーブルを監視し、デフォルトゲートウェイのIPアドレスに対応するMACアドレスの急変や不審な重複エントリを検知。
                • 自動隔離 (Pro): 有効時、攻撃を検知した瞬間にPFパケットフィルタを緊急ロックダウンに切り替え、通信を即座に遮断（エアギャップ隔離）してデータ流出を阻止。
                • 誤検知対応: メッシュWi-FiのAP切り替え等による誤検知時は、ポート・診断画面やメニューからいつでも解除可能。
                """,
                recommendation: "「ARPスプーフィング自動遮断 (Pro)」はPro有効化時に既定でオンです。ルーター再起動やメッシュWi-FiのAP切り替えで誤発動した場合は、緊急画面から安全を確認して解除してください。",
                tags: ["arp", "spoofing", "mitm", "eavesdropping", "gateway", "mac", "airgap", "pro"]
            ),
            KnowledgeItem(
                id: "feat_port_anomaly_guard",
                topic: "feature",
                title: "ポート監視・未知のポート自動遮断 & 開発サーバー隔離",
                summary: "リスニング中の全TCPポートを監視し、0.0.0.0で不用意にLANへ晒されたポートの検知、未知ポートの自動遮断、開発サーバーのワンクリック127.0.0.1隔離を行います。",
                details: """
                • リスニングポート監査: `lsof -iTCP -sTCP:LISTEN -n -P` で待機ポートを抽出。`0.0.0.0` (全公開) か `127.0.0.1` (localhost限定) かを判定。
                • 危険サービス検査: 認証なしで公開されがちなRedis (6379), MongoDB (27017), Memcached (11211), Elasticsearch (9200), VNC (5900) などを検知し警告。
                • 未知ポート自動遮断 (Pro): 過去に確認されていない新しい実行体が突然0.0.0.0でリッスンを開始した際、`PFRulesetCoordinator` 経由でpfに外部アクセス遮断ルールを追加（localhostは素通し）。Pro有効化時に既定でオン。macOS標準のシステムデーモン（rapportd等、Handoffの中身）は対象外。誤検知時は通知の「許可する」ボタンまたは「外部公開ポート」画面で恒久的に解除可能。
                • 開発サーバー外部隔離: Vite, Next.js, Flask, Docker等がLAN内に露出した際、ワンクリックで外部通信を遮断しローカル専用に封鎖。
                """,
                recommendation: "Web開発時はローカルサーバーを `127.0.0.1` にバインドして起動してください（例: `npm run dev -- -H 127.0.0.1`）。",
                tags: ["port", "devserver", "0.0.0.0", "localhost", "redis", "mongodb", "lsof", "pro"]
            ),
            KnowledgeItem(
                id: "feat_usb_storage_guard",
                topic: "feature",
                title: "不正USBストレージ自動遮断 & ClamAV自動スキャン",
                summary: "未登録のUSBストレージやSDカード接続時に自動取り出し。許可デバイスもClamAVでマルウェア検査を行ってからアクセスを許可します。",
                details: """
                • DiskArbitration監視: `DASession` と `DARegisterDiskAppearedCallback` により、外部ストレージマウントを瞬時に捕捉。
                • 未登録デバイス遮断 (Pro): ホワイトリスト（USB許可リスト）に登録されていないデバイスを即座に `DADiskUnmount` / `DADiskEject` で取り出し。
                • 段階的アクセス許可: 許可済みデバイスであっても、まずは「読み取り専用」でマウントしてClamAVでウイルススキャン。感染がなければ設定されたアクセス権（読み書き or 読み取り専用）に昇格。
                • 感染時の緊急排出: マルウェア検知時は即座にアンマウント・取り出しを実行し、ユーザーへ緊急通知を発出。
                """,
                recommendation: "業務で使用する安全なUSBメモリのみを「USBデバイス許可リスト」に登録し、不要なデバイスの接続を制限してください。",
                tags: ["usb", "badusb", "diskarbitration", "clamav", "whitelist", "pro", "storage"]
            ),
            KnowledgeItem(
                id: "feat_webmail_download_guard",
                topic: "feature",
                title: "Web・メールダウンロード保護 & 自動検疫隔離",
                summary: "Safari, Chrome, Mail, Slack, Discord等から保存されたファイルをFSEventsで常時監視し、ClamAVで即座にウイルス検査して隔離します。",
                details: """
                • FSEvents監視: `Downloads`, `Desktop`, `Documents` およびユーザー指定の監視対象フォルダを常時監視。
                • 隔離属性検知: ダウンロード時にmacOSが付与する `com.apple.quarantine` 拡張属性を検出。
                • ClamAV自動スキャン: バックグラウンドで `clamscan` を実行。
                • セキュア隔離: 脅威検知時、ファイルを専用の隔離フォルダ（`~/Library/Application Support/RoamSwitch/Quarantine/`）へ即時退避し、パーミッションを `000` に制限して無力化。
                • 隔離管理画面: メニューの「検疫・隔離ファイル管理」から、隔離理由の確認、完全削除、または安全確認後の復元が可能。
                """,
                recommendation: "「Web・メールダウンロード保護 (Pro)」を有効化し、独自の保存フォルダがある場合は「監視対象フォルダの編集」から追加してください。",
                tags: ["download", "mail", "fsevents", "quarantine", "clamav", "malware", "pro"]
            ),
            KnowledgeItem(
                id: "feat_dns_threat_guard",
                topic: "feature",
                title: "DNS脅威保護 & セキュア暗号化DNS自動適用",
                summary: "Quad9, Cloudflare, AdGuard, CleanBrowsing等のセキュアDNSプロファイルを適用し、マルウェアC2通信やフィッシング詐欺ドメインをDNSレイヤーで未然に遮断します。",
                details: """
                • セキュアDNSプロバイダ: Quad9 (脅威ブロック重視), Cloudflare (1.1.1.2 マルウェアブロック), AdGuard (広告・トラッカー遮断), CleanBrowsing (セキュリティフィルター)。
                • 適用ポリシー: 「未信頼ネットワークのみ適用（外出先限定）」または「常時適用（すべてのネットワーク）」。
                • 内部制御: `networksetup -setdnsservers` を通じてアクティブなネットワークインターフェースのDNS設定を安全に切替・復元。
                """,
                recommendation: "外出先での悪質ドメイン接続や公衆Wi-Fiの偽DNSサーバー（DNSハイジャック）を防ぐため、Quad9等のセキュアDNSを有効化してください。",
                tags: ["dns", "quad9", "cloudflare", "adguard", "phishing", "c2", "pro"]
            ),
            KnowledgeItem(
                id: "feat_ransomware_canary_guard",
                topic: "feature",
                title: "ランサムウェア・ふるまい検知 & 自律エアギャップ隔離",
                summary: "重要フォルダ内に高エントロピーなおとり（カナリア）ファイルを配置し、不正な暗号化や大量改ざんを検知した瞬間にネットワークを緊急全遮断します。",
                details: """
                • カナリア監視: `Desktop`, `Documents`, `Downloads` 内に隠しカナリアファイルを配置。FSEventsで変更・リネーム・削除を監視。
                • ふるまいバースト検知: 短時間での異常な大量ファイル書き換えや暗号化シグネチャ（エントロピー上昇）を監視。
                • 緊急エアギャップ隔離: ランサムウェア活動を検知した瞬間、PFパケットフィルタで外部通信を全遮断、共有サービスを停止し、被害拡大を物理防御。
                """,
                recommendation: "未知のゼロデイランサムウェアから重要データを守るため、「ランサムウェア・ふるまい検知 (Pro)」を有効にしておいてください。",
                tags: ["ransomware", "canary", "airgap", "entropy", "fsevents", "pro"]
            ),
            KnowledgeItem(
                id: "feat_bluetooth_guard",
                topic: "feature",
                title: "未信頼ネットワークでのBluetooth自動オフ",
                summary: "外出先などの未登録Wi-Fiに接続した瞬間、Bluetoothを自動でオフにし、BlueBorne攻撃やAirTag/BLEトラッキングを防止。信頼ネットワークに戻ると自動復帰します。",
                details: """
                • ツール連携: Homebrew経由のオープンソースツール `blueutil` を使用してBluetoothの電源状態を制御。
                • 動作フロー: 未登録Wi-Fi検知 -> Bluetooth切断・OFF -> 登録済みWi-Fi（自宅・職場）再接続 -> 自動でONに復帰。
                • 注意事項: 有効にするには `brew install blueutil` が必要です（未導入時はメニュー内にセットアップ案内が表示されます）。
                """,
                recommendation: "外出先でAirDropやBLE機器を使用しない場合は、Bluetooth自動オフを有効にして周囲からの電波探索を防ぎましょう。",
                tags: ["bluetooth", "blueutil", "ble", "blueborne", "pro", "homebrew"]
            ),
            KnowledgeItem(
                id: "feat_link_safety_auditor",
                topic: "feature",
                title: "メール・Webリンクの安全性診断 (Zero Telemetry)",
                summary: "不審なURLや短縮URLをブラウザで開く前に、端末内（Zero Telemetry）で安全に展開・解析し、Unicodeホモグラフ偽装やフィッシング危険度を100点満点で診断します。",
                details: """
                • Unicodeホモグラフ偽装検知: キリル文字やギリシャ文字を使ったなりすまし文字（Punycode / `xn--`）を検出。
                • サブドメイン偽装検知: `apple.com.login-verify.xyz` のように大手ブランド名をサブドメインに紛れ込ませた構造を解析。
                • 高リスクTLD判定: `.xyz`, `.top`, `.tk`, `.icu` などの使い捨てフィッシング頻出TLDをスコアリング減点。
                • HTTP平文・IP直打ち検知: 認証画面等での暗号化なしHTTPや、生IPアドレスURLを警告。
                • 完全ローカル完結: 外部の診断API等にURLを送信しないため、機密URLや認証トークンが外部に漏洩しません。
                """,
                recommendation: "メールやチャットで届いた不審なリンクは、直接クリックせずに「リンク安全性診断」またはMCPの `audit_url_safety` で検査してください。",
                tags: ["link", "url", "phishing", "homograph", "punycode", "zerotelemetry", "audit"]
            ),
            KnowledgeItem(
                id: "feat_security_health_checker",
                topic: "feature",
                title: "Macセキュリティ総合診断 (10項目 スコア & レポート)",
                summary: "FileVault, SIP, Gatekeeper, 自動アップデート, XProtect, ファイアウォール, Wi-Fi暗号化, ARP, ポート露出等を包括的にスキャンし、100点スコアと改善手順を提示します。",
                details: """
                • 1. FileVault: APFSディスク暗号化が有効か
                • 2. SIP (システム整合性保護): OS中核ファイル保護が有効か
                • 3. Gatekeeper: 開発元公認アプリのみに制限されているか
                • 4. 自動アップデート: セキュリティパッチの自動適用が有効か
                • 5. XProtect: Apple標準マルウェア定義が最新稼働しているか
                • 6. macOSファイアウォール: 受信接続ブロックが有効か
                • 7. ステルスモード: ICMP/探査パケットへの応答拒否が有効か
                • 8. Wi-Fi暗号化強度: WPA3/WPA2が適用されているか (Open/WEP警告)
                • 9. ARPスプーフィング: ゲートウェイなりすましがないか
                • 10. 外部公開ポート: 危険な0.0.0.0バインドの待機ポートがないか
                """,
                recommendation: "定期的に「総合診断レポート」を実行し、スコア90点以上（Grade A）を維持するように設定を調整してください。",
                tags: ["audit", "score", "filevault", "sip", "gatekeeper", "firewall", "xprotect"]
            ),
            KnowledgeItem(
                id: "feat_autonomous_sentinel",
                topic: "feature",
                title: "バックグラウンド自律巡回 & ClamAV定義自動更新",
                summary: "アプリ起動中、4時間ごとにバックグラウンドでセキュリティ健全性を自律診断。スコア低下時の自動警告や1日1回のウイルス定義更新・定期スキャンを行います。",
                details: """
                • 4時間ごとの定期診断: スコア低下や新たな脆弱性（ポート露出、ファイアウォール無効化など）を検知すると自動通知。
                • ClamAV定義自動更新: 1日1回 `freshclam` を自律実行し、最新のウイルスシグネチャを自動取得。
                • 日次定期スキャン: 指定フォルダのウイルススキャンを行い、脅威検出時は即時隔離＋警告通知を発出。
                """,
                recommendation: "Pro版をお使いの場合は、バックグラウンド自律巡回が有効になっていることを確認してください。",
                tags: ["autonomous", "sentinel", "background", "freshclam", "pro"]
            ),
            KnowledgeItem(
                id: "feat_privileged_helper",
                topic: "feature",
                title: "特権ヘルパーツール (`RoamSwitchHelper` XPC)",
                summary: "macOSのPFファイアウォールや共有サービスを安全に制御するため、特権分離されたLaunchDaemonヘルパーがバックグラウンドで連携動作します。",
                details: """
                • 特権分離アーキテクチャ: メインアプリは通常ユーザー権限で動作し、ルート権限が必要なPFルール変更やデーモン制御のみを専用XPCプロトコル経由で `RoamSwitchHelper` に委譲。
                • インストール場所: `/Library/PrivilegedHelperTools/com.tetsuharu.RoamSwitch.Helper`
                • セキュリティ検証: コード署名（Team ID / Requirement string）を相互検証し、不正なプロセスからのXPC呼び出しを遮断。
                """,
                recommendation: "初回起動時にヘルパーツールのインストール許可（パスワードまたはTouch ID）を承認してください。",
                tags: ["helper", "xpc", "root", "pfctl", "privilege", "security"]
            ),
            KnowledgeItem(
                id: "feat_license_pro_tier",
                topic: "feature",
                title: "Pro 永続ライセンス & 2台利用アンロック",
                summary: "買い切り（¥2,980）のPro永続ライセンス。Ed25519暗号署名トークンによりオフラインでも動作し、1ライセンスで2台のMacまで利用可能です。",
                details: """
                • Proアンロック機能: ランサムウェアふるまい検知、未知ポート自動遮断、ARPスプーフィング自動遮断、不正USBストレージガード、Web/Mailダウンロード自動隔離、DNS脅威保護、Bluetooth自動オフ、リアルタイム通知、自律巡回、ログCSV出力。
                • 暗号検証: サーバーから発行されるEd25519電子署名入りライセンストークンをアプリ内の公開鍵で端末ローカル検証。
                • 端末管理: ライセンス認証画面から現在のアクティベーション状況確認や、買い替え時のアンバインド（登録解除）が可能。
                """,
                recommendation: "高度な自動防護機能や自律巡回を利用したい場合は、Pro版へのアップグレードをご検討ください。",
                tags: ["license", "pro", "ed25519", "activation", "devices"]
            ),
        ]
    }

    // MARK: - Internal Builders: Alert Messages & Advice

    private static func buildAlertMessages() -> [KnowledgeItem] {
        return [
            KnowledgeItem(
                id: "alert_arp_spoofing",
                topic: "alert_message",
                title: "🚨 ARP Spoofing Detected / ゲートウェイのなりすまし通信を検知",
                summary: "同じWi-Fiネットワーク内に、ルーター（ゲートウェイ）になりすまして通信を盗聴・改ざんしようとしている端末が存在することを検知した際のアラート。",
                details: """
                • 発生原因: 攻撃者が同一LAN内でARP応答パケットを偽造してブロードキャストし、被害端末の通信を自分経由に誘導（中間者攻撃 / Man-In-The-Middle）。
                • 自動防御: RoamSwitchのARPガードが自動的に通信を隔離し、パケット傍受を防止。
                • メッセージ例:
                  - 「🚨 ARPスプーフィング（なりすまし通信）を検知しました」
                  - 「Gateway 192.168.1.1 is being spoofed by 00:11:22:33:44:55」
                """,
                recommendation: """
                【即時対処手順】
                1. 🚨 **ただちにWi-Fiを切断**してください（このWi-Fiネットワークは極めて危険です）。
                2. インターネットが必要な場合は、スマートフォンのテザリングや暗号化された安全な回線に切り替えてください。
                3. パスワード入力やオンライン決済、業務通信は絶対に行わないでください。
                4. メッシュWi-Fiの移動による誤検知と判明している場合のみ、メニューから手動で解除してください。
                """,
                tags: ["alert", "arp", "spoofing", "mitm", "wifi", "danger"]
            ),
            KnowledgeItem(
                id: "alert_unencrypted_wifi",
                topic: "alert_message",
                title: "⚠️ Unencrypted Wi-Fi / 暗号化のない公衆Wi-Fiに接続",
                summary: "パスワード設定や暗号化（WPA2/WPA3）のないOpen Wi-Fi、または古いWEP暗号化ネットワークに接続した際の警告。",
                details: """
                • 発生原因: カフェや街頭のフリーWi-Fiなど、無線区間が平文で暗号化されていないため、周囲の誰でも無線パケットを傍受可能な状態。
                • 自動防御: RoamSwitchが自動で「最大ロックダウン」を適用し、外部からのインバウンド接続と共有サービスを停止。
                """,
                recommendation: """
                【即時対処手順】
                1. 可能であればVPN（Virtual Private Network）を併用するか、信頼できるテザリング回線に切り替えてください。
                2. 暗号化されていないHTTPサイトでのログインや個人情報の入力は避けてください。
                3. RoamSwitchの「最大ロックダウン」が有効になっていることを確認してください。
                """,
                tags: ["alert", "wifi", "open", "unencrypted", "wep", "lockdown"]
            ),
            KnowledgeItem(
                id: "alert_port_anomaly",
                topic: "alert_message",
                title: "🚪 Port Anomaly Detected / 新しい外部公開ポートが検出されました",
                summary: "これまで確認されていない新しいTCPポートが `0.0.0.0` (全公開) でバインドされ、外部ネットワークに露出した際のアラート。",
                details: """
                • 発生原因: 開発用Webサーバー（Next.js, Vite, Python, Docker）の起動、LAN受信アプリ（LocalSend, Syncthing等）のガード有効化後の起動、またはバックドア/不正アプリの待機開始。
                • 自動防御: 「未知ポート自動遮断 (Pro)」が有効な場合、該当ポートへの外部アクセスをpfパケットフィルタで即座に遮断（Macからの利用・localhostは影響なし）。macOS標準のシステムデーモンは対象外。
                """,
                recommendation: """
                【即時対処手順】
                1. メニューの「外部公開ポート」または `get_exposed_ports` ツールでプロセス名（PID）とポート番号を確認してください。
                2. 自身の開発サーバーやLAN受信アプリ（LocalSend等）の場合は、通知バナーの「許可する」ボタン、または「外部公開ポート」画面の当該項目で解除してください。以降は恒久的に許可されます。
                3. 開発サーバーは `127.0.0.1` バインドに変更して再起動するのが安全です。
                4. 身に覚えのない不審なプロセスの場合は、そのまま遮断させたうえでプロセスを終了し、セキュリティ診断とウイルススキャンを実行してください。
                """,
                tags: ["alert", "port", "anomaly", "exposed", "0.0.0.0", "devserver"]
            ),
            KnowledgeItem(
                id: "alert_untrusted_usb",
                topic: "alert_message",
                title: "🔌 Untrusted USB Storage Blocked / 未登録のUSBストレージを取り出しました",
                summary: "ホワイトリスト（許可リスト）に登録されていないUSBメモリや外部ストレージが挿入され、データ保護のため自動排出された際のアラート。",
                details: """
                • 発生原因: 未許可のUSBストレージ接続。悪意ある人物による不正持ち出しやBadUSB攻撃を防止。
                • 自動防御: ディスクをマウントさせずに即時アンマウント・排出。
                """,
                recommendation: """
                【対処手順】
                1. 自身が接続した安全なデバイスである場合は、メニューの「USBストレージ保護設定」>「接続中デバイスから追加」で許可リストに登録してください。
                2. 業務方針に合わせて「読み取り専用」または「読み書き両方」を選択して登録してください。
                """,
                tags: ["alert", "usb", "storage", "untrusted", "eject", "badusb"]
            ),
            KnowledgeItem(
                id: "alert_malware_usb",
                topic: "alert_message",
                title: "🦠 Malware Detected on USB / USBストレージからマルウェアを検出",
                summary: "許可済みUSBストレージのマウント前ClamAV自動検査において、ウイルスまたは悪意あるファイルが検出された際のアラート。",
                details: """
                • 発生原因: USBメモリ内に感染ファイルが存在。
                • 自動防御: 直ちにボリュームをアンマウントして強制排出。Mac本体への感染を防ぎます。
                """,
                recommendation: """
                【即時対処手順】
                1. 該当のUSBメモリを別の安全な隔離環境で初期化（フォーマット）するか、ウイルス駆除を行ってください。
                2. Mac本体に感染がないか、「マルウェア対策」からシステム全体のスキャンを実行してください。
                """,
                tags: ["alert", "malware", "virus", "usb", "clamav", "danger"]
            ),
            KnowledgeItem(
                id: "alert_quarantined_download",
                topic: "alert_message",
                title: "📥 Malicious Download Quarantined / ダウンロードされた脅威ファイルを隔離しました",
                summary: "Webブラウザやメール、Slack等から保存されたファイルからマルウェアシグネチャが検出され、即座に安全な隔離フォルダへ移動された際のアラート。",
                details: """
                • 発生原因: ダウンロードファイルにウイルス、トロイの木馬、アドウェアが含まれていた。
                • 自動防御: ファイルを直ちに `~/Library/Application Support/RoamSwitch/Quarantine/` へ退避し、パーミッション `000` で無力化。
                """,
                recommendation: """
                【対処手順】
                1. 該当ファイルは実行できない状態に隔離されています。
                2. メニューの「検疫・隔離ファイル管理」を開き、該当ファイルを選択して「完全に削除」してください。
                3. 誤検知が確実な開発用バイナリ等の場合のみ、「元の場所へ復元」を実行してください。
                """,
                tags: ["alert", "download", "quarantine", "clamav", "trojan", "malware"]
            ),
            KnowledgeItem(
                id: "alert_ransomware_activity",
                topic: "alert_message",
                title: "🚨 Ransomware Activity Detected / ランサムウェアの疑いのある活動を検知・緊急隔離",
                summary: "カナリアファイルの不正な改ざんや、短時間での異常なファイル書き換えバーストを検知し、緊急エアギャップ全遮断が発動した際のアラート。",
                details: """
                • 発生原因: バックグラウンドで動作する未知のランサムウェアがユーザーのドキュメントを暗号化しようとした。
                • 自動防御: 外部通信を全遮断、共有サービスを緊急停止し、C2サーバーとの通信やLAN内への感染拡大を物理阻止。
                """,
                recommendation: """
                【緊急対処手順】
                1. 🚨 **作業中の重要な未保存ファイルを別名保存し、不審なアプリをすべて終了**してください。
                2. アクティビティモニタでCPUやディスク書き込みが急増している不審なプロセスがないか確認・強制終了してください。
                3. Time Machineバックアップの最新状態を確認し、必要に応じて安全な時点への復元を検討してください。
                """,
                tags: ["alert", "ransomware", "canary", "airgap", "emergency", "danger"]
            ),
            KnowledgeItem(
                id: "alert_helper_disconnected",
                topic: "alert_message",
                title: "⚠️ Helper Not Connected / ヘルパー未接続",
                summary: "RoamSwitchの特権ヘルパーツール（`RoamSwitchHelper`）とのXPC通信が確立できない際のエラー警告。",
                details: """
                • 発生原因: macOSアップデート等でLaunchDaemonが停止したか、「ログイン項目と機能拡張」でバックグラウンド実行がオフになっている。
                • 影響: ファイアウォール切替やデーモン停止などの特権操作が制限されます。
                """,
                recommendation: """
                【修復手順】
                1. ターミナルで `sudo killall RoamSwitchHelper` を実行してヘルパーを再起動してください。
                2. 「システム設定」>「一般」>「ログイン項目とApp機能拡張」を開き、「RoamSwitchHelper」が許可されているか確認してください。
                3. 改善しない場合は、RoamSwitchアプリを再起動し、ヘルパーの再インストールを許可してください。
                """,
                tags: ["alert", "helper", "xpc", "error", "troubleshooting"]
            ),
            KnowledgeItem(
                id: "alert_score_drop",
                topic: "alert_message",
                title: "⚠️ Security Score Drop / セキュリティスコア低下アラート",
                summary: "自律診断または手動診断において、Macのセキュリティ健全性スコアが低下（FileVault無効、SIP無効、ポート露出等）した際の通知。",
                details: """
                • 発生原因: OS設定の変更、ファイアウォール解除、危険なポートの開放など。
                • 判定基準: スコア80点未満（Grade B以下）または重要項目の失敗。
                """,
                recommendation: """
                【改善手順】
                1. `get_security_report` ツールまたはアプリ内の「総合診断レポート」を実行してください。
                2. 「改善点」として赤色・黄色で表示された項目（例: FileVault有効化、SIP有効化、ポートバインド修正）を順に対応してください。
                """,
                tags: ["alert", "score", "audit", "health", "recommendation"]
            ),
            KnowledgeItem(
                id: "alert_dangerous_url",
                topic: "alert_message",
                title: "🛑 Dangerous URL Detected / 危険なリンク・フィッシング詐欺を検出",
                summary: "リンク診断（`audit_url_safety`）において、ホモグラフ偽装、偽装サブドメイン、高リスクTLD等を含む悪質なURLを検知した際の警告。",
                details: """
                • 判定項目: ホモグラフ文字（Punycode）、大手企業を装う偽装サブドメイン、フィッシング頻出TLD、短縮URL転送先など。
                • スコア: 50点未満（危険 / Dangerous）または50〜79点（注意 / Caution）。
                """,
                recommendation: """
                【推奨アクション】
                1. 🛑 **該当のリンクは絶対に開かないでください**。
                2. メールやメッセージを破棄し、必要に応じて社内のセキュリティ担当者へフィッシング報告を行ってください。
                """,
                tags: ["alert", "url", "link", "phishing", "homograph", "danger"]
            ),
        ]
    }

    // MARK: - Internal Builders: Settings

    private static func buildSettings() -> [KnowledgeItem] {
        return [
            KnowledgeItem(
                id: "set_trusted_networks",
                topic: "setting",
                title: "登録済みネットワーク管理 & 保護レベル個別設定",
                summary: "接続したことのあるWi-Fiネットワークを「自宅」「職場」「テザリング」等として登録し、ネットワークごとに保護強度（信頼/標準保護/ロックダウン）を設定できます。",
                details: """
                • 登録方法: 接続中のネットワークでメニューから「現在のネットワークを登録」を選択。
                • レベル変更: 登録済みネットワーク一覧から対象Wi-Fiを選び、「🟢信頼」「🟡標準保護」「🔴最大ロックダウン」を選択。
                • 名前変更・削除: 「名称を変更…」で識別しやすい名前に編集可能。不要になったネットワークは「登録を解除」で削除。
                """,
                recommendation: "自宅LANは「🟢信頼」、職場の共有オフィスWi-Fiは「🟡標準保護」に設定するのが最適です。",
                tags: ["settings", "networks", "trusted", "levels"]
            ),
            KnowledgeItem(
                id: "set_manual_override",
                topic: "setting",
                title: "手動オーバーライド & 戻し忘れ防止タイマー",
                summary: "一時的に保護レベルを手動で変更したい場合、戻し忘れを防ぐためタイマーや自動解除トリガーを設定できます。",
                details: """
                • オプション:
                  - 「1時間だけ」: 60分経過後に自動で元のポリシーへ復帰。
                  - 「次回ネットワーク切断まで」: 別のWi-Fiへ移動・切断した瞬間に手動設定を自動解除。
                  - 「手動で変更するまで」: 永続的に固定。
                • 即時解除: メニュー最上部の「🔄 手動指定を解除」からいつでもワンクリックで自動判定に戻せます。
                """,
                recommendation: "開発作業やプレゼン等で一時的に保護を緩める際は、「1時間だけ」または「次回切断まで」を活用して外出先での無防備化を防ぎましょう。",
                tags: ["settings", "override", "timer", "revert"]
            ),
            KnowledgeItem(
                id: "set_usb_whitelist",
                topic: "setting",
                title: "USBストレージ許可リスト & アクセス権設定 (Pro)",
                summary: "業務で使用する安全なUSBストレージをホワイトリストに登録し、「読み取り専用」または「読み書き両方」のアクセス権を管理します。",
                details: """
                • 登録手順: USBストレージを接続 -> メニュー「USBストレージ保護設定」>「接続中デバイスから追加」をクリック。
                • モード選択:
                  - 「読み取り専用 (Read Only)」: データの吸い上げ・持ち出しを物理遮断し、閲覧のみ許可。
                  - 「読み書き両方 (Read & Write)」: 通常の書き込みも許可（接続時のClamAVスキャンは常時実行）。
                """,
                recommendation: "機密データを扱うMacでは、登録デバイスを「読み取り専用」にしておくことで情報漏洩リスクを大幅に低減できます。",
                tags: ["settings", "usb", "whitelist", "readonly", "pro"]
            ),
            KnowledgeItem(
                id: "set_watched_folders",
                topic: "setting",
                title: "Web・メール監視対象フォルダの編集 (Pro)",
                summary: "ダウンロード保護（FSEvents監視）の対象となるフォルダを自由に追加・削除・デフォルト復元できます。",
                details: """
                • デフォルト監視フォルダ: `~/Downloads`, `~/Desktop`, `~/Documents`
                • カスタム追加: 「フォルダを追加…」から任意の作業用フォルダ（例: `~/Inbox`, `~/SharedProjects`）を指定可能。
                • ワンクリック復元: 「デフォルトに戻す」ボタンで標準構成にいつでもリセット可能。
                """,
                recommendation: "ブラウザの保存先を独自フォルダに変更している場合は、必ず監視対象フォルダに追加してください。",
                tags: ["settings", "watched_folders", "downloads", "fsevents", "pro"]
            ),
            KnowledgeItem(
                id: "set_dns_policy",
                topic: "setting",
                title: "DNS脅威保護ポリシー & プロバイダ選択 (Pro)",
                summary: "悪質ドメインを遮断するセキュアDNSプロバイダの選択と、適用タイミング（外出先のみ / 常時）を設定します。",
                details: """
                • プロバイダ選択:
                  - Quad9 (9.9.9.9): 高度なマルウェア・フィッシング遮断
                  - Cloudflare Security (1.1.1.2): 高速かつマルウェアブロック
                  - AdGuard (94.140.14.14): 悪質サイト＋広告・トラッカー遮断
                  - CleanBrowsing Security (185.228.168.9): セキュリティフィルター
                • 適用ポリシー:
                  - 「未信頼ネットワークのみ」: 外出先Wi-Fiに接続した際のみ自動切替。
                  - 「常時適用」: 自宅や職場を含むすべての接続でセキュアDNSを強制。
                """,
                recommendation: "一般的な利用では「Quad9」＋「未信頼ネットワークのみ」または「常時適用」が最も効果的です。",
                tags: ["settings", "dns", "quad9", "cloudflare", "policy", "pro"]
            ),
        ]
    }

    // MARK: - Internal Builders: Troubleshooting

    private static func buildTroubleshooting() -> [KnowledgeItem] {
        return [
            KnowledgeItem(
                id: "faq_free_vs_pro",
                topic: "troubleshooting",
                title: "無料版とPro永続版の違い",
                summary: "無料版でも全10項目のセキュリティ手動診断やパケット自動遮断が利用可能です。Pro版ではリアルタイム自動隔離や自律巡回などの高度機能がアンロックされます。",
                details: """
                【無料版 (Free)】
                • Wi-Fi接続先に応じたパケットフィルタ自動切替（外出先ロックダウン）
                • Macセキュリティ総合診断（10項目の手動診断・スコアリング・改善提案）
                • Apple XProtect稼働状況確認、ファイル署名・隔離属性診断
                • 待機中ポート一覧表示
                • リンク安全性診断（Zero Telemetry）
                • MCPサーバー連携（AIからの全診断ツールの呼び出し）

                【Pro 永続版 (買い切り ¥2,980)】
                • 🚨 ランサムウェア・ふるまい検知 & 緊急エアギャップ自律隔離
                • 📥 Web・メールダウンロード自動保護 & ClamAV自動検疫隔離
                • 🌐 DNS脅威保護 & セキュア暗号化DNS自動適用
                • 🛡️ 開発サーバーのワンクリック外部隔離 (127.0.0.1封鎖)
                • 🚪 未知のリスニングポート自動遮断
                • 📡 ARPスプーフィング検知時の自動隔離
                • 🔌 不正USB / BadUSB 物理ポート自動遮断 & 自動ウイルススキャン
                • 🔵 未信頼ネットワークでのBluetooth自動オフ
                • 🤖 4時間ごとのバックグラウンド自律巡回 & ClamAV定義自動更新
                • 📄 セキュリティログのCSVエクスポート
                • 2台のMacでの同時利用
                """,
                recommendation: "自動隔離やリアルタイム防護、バックグラウンド巡回が必要な場合はPro版をお選びください。",
                tags: ["faq", "free", "pro", "features", "comparison", "license"]
            ),
            KnowledgeItem(
                id: "faq_homebrew_clamav",
                topic: "troubleshooting",
                title: "ClamAV (ウイルス検査) のセットアップとHomebrewについて",
                summary: "無料のウイルススキャン機能「ClamAV」を利用する場合のみHomebrewが必要です。未導入でもApple XProtectやRoamSwitch本体機能は100%動作します。",
                details: """
                • Homebrewとは: macOS用の安全な標準パッケージ管理ツール (https://brew.sh/ja/)
                • インストール手順:
                  1. ターミナルを開き、公式コマンドを実行:
                     `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
                  2. 続いてClamAVをインストール:
                     `brew install clamav`
                  3. メニューの「マルウェア対策」>「ウイルス定義の更新」を実行。
                • 注意点: ClamAVを導入しなくても、Apple公式のXProtectやRoamSwitchの全パケット防御・ポート監査・リンク診断は完全に動作します。
                """,
                recommendation: "ファイルのウイルス自動スキャンやUSB接続時スキャンを活用したい場合は、HomebrewとClamAVの導入をおすすめします。",
                tags: ["faq", "clamav", "homebrew", "install", "antivirus", "troubleshooting"]
            ),
            KnowledgeItem(
                id: "faq_blueutil_setup",
                topic: "troubleshooting",
                title: "Bluetooth自動オフガード (Pro) と blueutil のセットアップ",
                summary: "外出先でBluetoothを自動オフにする機能には、オープンソースツール `blueutil` の導入が必要です。",
                details: """
                • 背景: macOSにはアプリから直接Bluetoothの電源を切り替える公式APIが存在しないため、CLIツール `blueutil` を連携利用します。
                • インストール手順:
                  1. ターミナルで `brew install blueutil` を実行。
                  2. RoamSwitchメニューの「ポート・デバイス監視」>「Bluetooth自動オフ」を有効化。
                • 未導入時の動作: 未導入でも他の機能には一切影響せず、初期設定はオフになっています。
                """,
                recommendation: "公衆Wi-Fiでの電波追跡やBluetooth脆弱性を防ぎたい場合は、`brew install blueutil` を実行して有効化してください。",
                tags: ["faq", "bluetooth", "blueutil", "homebrew", "setup"]
            ),
            KnowledgeItem(
                id: "faq_helper_troubleshooting",
                topic: "troubleshooting",
                title: "「⚠️ ヘルパー未接続」と表示される場合の対処法",
                summary: "特権ヘルパーツール（RoamSwitchHelper）との通信が切断されている場合の復旧手順。",
                details: """
                【復旧コマンドと手順】
                1. ターミナルを開き、ヘルパープロセスを再起動:
                   `sudo killall RoamSwitchHelper`
                   （launchdにより数秒で自動再起動されます）
                2. 「システム設定」>「一般」>「ログイン項目とApp機能拡張」を開き、「RoamSwitchHelper」のトグルがオンになっているか確認。
                3. アプリを再起動し、メニューバーの表示が「🟢 接続中」または正常アイコンに戻るか確認。
                """,
                recommendation: "OSアップデート直後などにヘルパーが応答しなくなった場合は、`sudo killall RoamSwitchHelper` を試してください。",
                tags: ["faq", "helper", "troubleshooting", "xpc", "repair"]
            ),
            KnowledgeItem(
                id: "faq_quarantine_false_positive",
                topic: "troubleshooting",
                title: "ダウンロードファイルが誤検知で隔離された場合の復元手順",
                summary: "自作のスクリプトや開発用バイナリがClamAVに誤検知されて隔離された場合の復元と除外設定手順。",
                details: """
                【復元手順】
                1. メニューバーアイコンをクリックし、「検疫・隔離ファイル管理」を選択。
                2. 隔離ファイル一覧から該当ファイルを選択。
                3. 「元の場所へ復元」ボタンをクリック（元のパーミッションが復元され、元のパスに戻ります）。
                4. 特定のフォルダをスキャン対象外にしたい場合は、「設定」>「ClamAV除外設定」または「監視対象フォルダの編集」から調整可能。
                """,
                recommendation: "自作の実行可能ファイルが誤検知された場合は、「検疫・隔離ファイル管理」から安全に復元してください。",
                tags: ["faq", "quarantine", "restore", "false_positive", "clamav"]
            ),
            KnowledgeItem(
                id: "faq_zero_telemetry",
                topic: "troubleshooting",
                title: "Zero Telemetry（外部送信ゼロ）のプライバシー設計",
                summary: "RoamSwitchおよびMCPサーバーは、診断データやURL、ポート情報、ログを外部サーバーに一切送信しません。",
                details: """
                • 完全ローカル処理: セキュリティ診断、ポートスキャン、URLリンク解析、ウイルス検査、MCP通信はすべてMac端末内で完結。
                • 通信の唯一の例外:
                  - Stripe決済ページを開く際のリダイレクト（ユーザーがPro購入ボタンを押した時のみ）
                  - ライセンス認証時のEd25519署名トークン取得（認証時のみ）
                  - Sparkleによるアプリアップデート確認（GitHub / 公式ホスティング）
                  - ClamAVウイルス定義ファイルの更新（`freshclam` 実行時）
                • 診断データ・ログ・URL等のテレメトリ収集はコードベース内に一切存在しません。
                """,
                recommendation: "機密性の高い企業ネットワークや個人開発環境でも、情報流出の懸念なく安全にご利用いただけます。",
                tags: ["faq", "privacy", "zero_telemetry", "security", "telemetry"]
            ),
        ]
    }

    // MARK: - Markdown Document Generators

    public func generateFeaturesMarkdown() -> String {
        var md = "# 🛡️ RoamSwitch Full Feature Specification & Architecture\n\n"
        md += "This document details the complete technical architecture and operational specifications of RoamSwitch.\n\n"
        let features = allItems.filter { $0.topic == "feature" }
        for f in features {
            md += "## \(f.title)\n"
            md += "**Summary**: \(f.summary)\n\n"
            md += "\(f.details)\n\n"
            if let rec = f.recommendation {
                md += "> **💡 Recommendation**: \(rec)\n\n"
            }
            md += "---\n\n"
        }
        return md
    }

    public func generateAlertsMarkdown() -> String {
        var md = "# 🚨 RoamSwitch Complete Alert Catalog & Advice Guide\n\n"
        md += "This catalog lists all alert banners, notification messages, and warning states displayed by RoamSwitch, along with exact causes, automated defenses, and recommended step-by-step user actions.\n\n"
        let alerts = allItems.filter { $0.topic == "alert_message" }
        for a in alerts {
            md += "## \(a.title)\n"
            md += "**Overview**: \(a.summary)\n\n"
            md += "### Details & Technical Causes\n\(a.details)\n\n"
            if let rec = a.recommendation {
                md += "### 🛠️ Step-by-Step User Advice\n\(rec)\n\n"
            }
            md += "---\n\n"
        }
        return md
    }

    public func generateSettingsMarkdown() -> String {
        var md = "# ⚙️ RoamSwitch Settings & Operational Guide\n\n"
        md += "Step-by-step guidance for every configuration option, toggle, whitelist, and custom policy in RoamSwitch.\n\n"
        let settings = allItems.filter { $0.topic == "setting" }
        for s in settings {
            md += "## \(s.title)\n"
            md += "**Summary**: \(s.summary)\n\n"
            md += "\(s.details)\n\n"
            if let rec = s.recommendation {
                md += "> **💡 Best Practice**: \(rec)\n\n"
            }
            md += "---\n\n"
        }
        return md
    }

    public func generateTroubleshootingMarkdown() -> String {
        var md = "# 🔧 RoamSwitch Troubleshooting, FAQ & Technical Q&A\n\n"
        md += "Authoritative answers for common questions, permissions, Homebrew/ClamAV/blueutil installation, false-positive handling, and privacy guarantees.\n\n"
        let faqs = allItems.filter { $0.topic == "troubleshooting" }
        for faq in faqs {
            md += "## \(faq.title)\n"
            md += "**Summary**: \(faq.summary)\n\n"
            md += "\(faq.details)\n\n"
            if let rec = faq.recommendation {
                md += "> **💡 Advice**: \(rec)\n\n"
            }
            md += "---\n\n"
        }
        return md
    }
}
