// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.29 (build 86).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

// Japanese (source language) content for `RoamSwitchKnowledgeBase`.
// Every entry id here must also exist in every other
// `RoamSwitchKnowledgeBaseContent_<lang>.swift` file.
extension RoamSwitchKnowledgeBase {
    static func labelsJa() -> MarkdownLabels {
        return MarkdownLabels(
            featuresTitle: "RoamSwitch 機能仕様・内部構造ガイド",
            featuresIntro: "RoamSwitch の全セキュリティ機能について、動作の仕組み・既定値・制限事項を網羅的に解説します。",
            alertsTitle: "RoamSwitch 通知・警告メッセージ対処ガイド",
            alertsIntro: "RoamSwitch が表示する通知バナー・警告・緊急モーダルの一覧です。発生原因、自動で行われる防御、推奨される対処手順をまとめています。",
            settingsTitle: "RoamSwitch 設定・運用ガイド",
            settingsIntro: "各種設定項目・トグル・許可リスト・ポリシーの具体的な設定手順です。",
            troubleshootingTitle: "RoamSwitch トラブルシューティング & よくある質問",
            troubleshootingIntro: "よくある質問、権限・承認、Homebrew / ClamAV / blueutil の導入、誤検知への対処、プライバシー設計についての公式回答です。",
            summary: "概要",
            overview: "概要",
            detailsHeading: "詳細と発生原因",
            adviceHeading: "対処法",
            recommendation: "推奨",
            bestPractice: "おすすめの設定",
            advice: "アドバイス"
        )
    }

    static func contentJa() -> [LocalizedEntry] {
        var list: [LocalizedEntry] = []
        list.append(contentsOf: featuresJaNetwork())
        list.append(contentsOf: featuresJaMalware())
        list.append(contentsOf: featuresJaAudit())
        list.append(contentsOf: alertsJaNetwork())
        list.append(contentsOf: alertsJaMalware())
        list.append(contentsOf: settingsJa())
        list.append(contentsOf: troubleshootingJaSetup())
        list.append(contentsOf: troubleshootingJaOperation())
        return list
    }

    // MARK: - Features: network & devices

    private static func featuresJaNetwork() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_network_autoswitch",
                title: "自動ネットワークセキュリティ切替 & PFパケットフィルタ（3段階レベル）",
                summary: "接続中ネットワークのゲートウェイMACアドレスを登録済みネットワークと照合し、ネットワークごとの保護レベルを自動で適用します。未登録のネットワークには「外出先デフォルト保護」のレベル（初期値: 最大ロックダウン）が適用されます。無料版で利用できます。",
                details: """
                • 🟢 信頼 (オープン - 保護解除): 自宅など。ファイアウォールを解除し、共有サービス（SSH / SMB / 画面共有）とAirDropを許可。
                • 🟡 標準保護 (ファイアウォール&ステルス): 職場・テザリングなど。PFパケットフィルタとステルスモードで外部からの探査を遮断しつつ、共有サービスは維持。
                • 🔴 最大ロックダウン (共有・AirDrop停止): カフェ・公衆Wi-Fi・未登録ネットワーク。受信を全遮断し、共有デーモンを停止、AirDropを無効化。
                • 判定の仕組み: ネットワーク変更時にゲートウェイのMACアドレスを取得し、登録済みネットワークと照合。DHCP更新やWi-Fiローミングなど、ゲートウェイが変わらない経路イベントでは再判定の負荷を抑えています。
                • 内部構造: 特権ヘルパー `RoamSwitchHelper`（XPC経由）が `pfctl` の専用アンカーを操作し、カーネルレベルでパケットを破棄します。
                • 手動オーバーライド: メニューの「手動オーバーライド」から、レベルごとに「次回ネットワーク切断まで（推奨）」「1時間だけ」「4時間だけ」「解除するまで継続」を選択可能（set_manual_override を参照）。
                """,
                recommendation: "自宅や安全なオフィスはメニューの「現在のネットワークを登録」から登録し、それ以外の場所では最大ロックダウンが自動で適用される状態で運用してください。"
            ),
            LocalizedEntry(
                id: "feat_network_history_guard",
                title: "ネットワーク履歴学習 & Evil Twin（なりすましWi-Fi）検知 (Pro)",
                summary: "接続したWi-FiのSSIDとゲートウェイMACアドレスの組み合わせを端末内に学習し、過去に接続したネットワークと酷似した名前の未知のSSIDに接続した際に「Evil Twin（偽アクセスポイント）」の疑いとして警告します。",
                details: """
                • 学習内容: SSIDごとに観測したゲートウェイMACアドレス（1 SSIDあたり最大8件、メッシュWi-Fi対応）を `~/Library/Application Support/RoamSwitch/network_history.json` に保存。最大200 SSIDまで、古いものから削除。外部送信はありません。
                • 酷似SSIDの判定: 大文字小文字を無視した編集距離（レーベンシュタイン距離）で比較。6文字未満の短い名前は対象外とし、許容距離は名前の長さに応じて1〜2文字。「ASUS」「TP-Link_5G」のような既定SSIDの偶然の一致では警告しません。
                • 誤検知の抑制: 同じゲートウェイ機器が別名のSSID（ゲストネットワーク等）を出している場合は対象外。既知のSSIDに新しいゲートウェイMACで接続した場合（ルーター交換など）は記録のみで警告しません。
                • ARPスプーフィングを検知している最中は、攻撃者のMACを正規として学習しないよう記録をスキップします。
                • 通知はリアルタイム警告のためPro版で送信されます。学習済みの履歴はMCPツール `get_network_history` で確認できます。
                """,
                recommendation: "警告が出た場合は、そのWi-Fiで認証情報を入力せず、正規のネットワーク名・場所かを確認してください。VPNトンネル（feat_vpn_tunnel）の併用が最も確実な対策です。"
            ),
            LocalizedEntry(
                id: "feat_arp_spoof_guard",
                title: "ARPスプーフィング（なりすまし通信）検知 & 自動遮断 (Pro)",
                summary: "同一ネットワーク内の攻撃者がルーターになりすまして通信を盗聴・改ざんするARPスプーフィング（中間者攻撃）を検知します。最大ロックダウン中は即座にネットワークを全遮断し、それ以外のレベルでは通知してユーザーの判断で遮断できます。",
                details: """
                • 検知原理: デフォルトゲートウェイのIPアドレスはそのままで、対応するMACアドレスが急変したことを検知。ネットワーク変更イベントとは別に15秒ごとの独自ポーリングで監視し、接続途中から始まった攻撃も捕捉します。
                • 検知時の挙動: 最大ロックダウンのネットワークでは即座にエアギャップ隔離（feat_airgap_containment）。信頼・標準保護のネットワークでは通知のみとし、メニュー「ポート・デバイス監視」の「ARPスプーフィング検知 — 今すぐ全遮断する」から手動で発動。ルーター再起動やメッシュWi-Fiの切替による誤発動や、偽ARP 1つで通信を止めさせる攻撃への悪用を防ぐためです。
                • 既定値: メニュー「ARPスプーフィング（なりすまし通信）検知時に自動遮断 (Pro)」。Proライセンスの初回有効化時に自動でオンになります（set_pro_default_guards）。
                • 位置づけ: 検知後の事後策です。未然防止はゲートウェイARP/NDP固定（feat_gateway_arp_lock）とVPNトンネル（feat_vpn_tunnel）が担います。
                • インシデントはインシデント履歴（feat_containment_incident_timeline）に MITRE ATT&CK T1557 として記録されます。
                """,
                recommendation: "既定のまま有効にしておき、より強い中間者攻撃対策が必要ならVPNトンネル、追加インフラなしの予防ならゲートウェイARP/NDP固定を併用してください。"
            ),
            LocalizedEntry(
                id: "feat_gateway_arp_lock",
                title: "ゲートウェイ ARP/NDP 固定（予防） (Pro)",
                summary: "未信頼ネットワークに接続した時点で、ゲートウェイ・IPv6ルーター・同一リンク上のDNSサーバーのMACアドレスを近隣キャッシュに静的固定し、ARP/NDPスプーフィングによる中間者攻撃を未然に防ぎます。既定はオフです。",
                details: """
                • 有効化: メニュー「ポート・デバイス監視」→「未信頼ネットワークでゲートウェイのARP/NDPを固定（予防） (Pro)」。
                • 動作: 接続時に現在のMACアドレスを取得し、ヘルパーが `arp -s` / `ndp -s` で permanent エントリとして固定。固定後はカーネルが偽のARP応答・近隣広告を無視します。
                • 範囲: 上記3種のエントリのみ。信頼（オープン）ネットワークでは固定しないため、自宅ルーターの再起動で通信不能になることはありません。ネットワーク変更ごとに解除して再固定します。
                • 限界（TOFU）: 最初に観測したMACを信頼する方式のため、接続前から攻撃者が居座っていた場合は偽のMACを固定し得ます。この前提を置きたくない場合はVPNトンネルを使用してください。
                • セキュリティ総合診断の「ゲートウェイ ARP 固定 (予防的MITM対策)」項目に反映されます。
                """,
                recommendation: "VPNの用意が難しい場合の軽量な中間者攻撃対策として有効です。VPNトンネルとの併用も可能です（VPNが本命、こちらは補助）。"
            ),
            LocalizedEntry(
                id: "feat_vpn_tunnel",
                title: "VPNトンネル（WireGuard / Tailscale・キルスイッチ付き） (Pro)",
                summary: "未信頼ネットワークで暗号化トンネルを自動接続し、中間者攻撃を無効化します。バックエンドは WireGuard（設定ファイル）または Tailscale（Exit Node）から選択。L2（ARP/NDP）の完全性に依存しない、中間者攻撃対策の本命です。Network Extensionのエンタイトルメントは不要です。",
                details: """
                • バックエンド選択: メニュー「ポート・デバイス監視」→「VPNトンネル (未信頼ネットワークでのMITM対策) (Pro)」→「バックエンド」で WireGuard か Tailscale を選択。選んだ方だけが動作します。
                • WireGuard: Homebrew の `wireguard-tools`（`brew install wireguard-tools`）が必要。「WireGuard設定(.conf)を読み込む…」で設定ファイルを取り込みます。設定ファイルはユーザーが用意します（Mullvad・IVPN・Proton VPN、自前サーバー、勤務先支給など）。RoamSwitch はVPNサーバーを提供しません。
                • WireGuardキルスイッチ: pf の `block drop all` に「lo / トンネルIF / エンドポイントへのUDPハンドシェイク / DHCP / ICMP」だけを許可。トンネルが切れている間も平文が漏れません。
                • Tailscale: 既にTailscaleを使っている人向け。RoamSwitch は導入やログインは行わず、`tailscale status` を読み `tailscale set --exit-node=<ノード>` を実行するだけです。Exit Node の選択が必須（全通信をそこ経由に）。選択したノードがオフラインの場合は状態表示でお知らせします。
                • Tailscale は CLI版（standalone）推奨: `brew install tailscale` → `sudo tailscaled install-system-daemon` → `sudo tailscale up`。App Store版（GUI）はアプリ外から `tailscale set` を実行できないため、TailscaleアプリでExit Nodeを選び、RoamSwitch は状態表示とキルスイッチのみを担当します。
                • Tailscaleキルスイッチ（既定オフ・オプトイン）: pf で「lo / Tailscale の utun / CGNAT 100.64.0.0/10 / DNS / STUN 3478 / 41641 / DERP tcp 443 / DHCP / ICMP」のみ許可。WireGuardより緩い「漏れにくい」水準で、環境によってはTailscale自身の接続を妨げることがあるため任意です。
                • 自動適用: 未信頼ネットワークでトンネル／Exit Node を接続し、信頼済みネットワークで切断。ライセンス失効時はトンネル・キルスイッチを自動解除します。
                """,
                recommendation: "公衆Wi-Fiを頻繁に使うなら最も効果的な対策です。Tailscale利用者はCLI版を導入してTailscaleバックエンド＋Exit Nodeを、それ以外は `brew install wireguard-tools` とVPNプロバイダーの `.conf` でWireGuardを使うのが手軽です。"
            ),
            LocalizedEntry(
                id: "feat_airgap_containment",
                title: "緊急エアギャップ隔離（ネットワーク全遮断・Wi-Fi無線オフ・自動復旧フェイルセーフ）",
                summary: "ランサムウェア検知・XProtectのマルウェア検知・ARPスプーフィング・ClickFixなど重大な脅威を検知した際に、ネットワークの送受信をすべて遮断する共通の緊急隔離機構です。クラッシュや再起動が起きても最大10分で自動的に通信が復旧します。",
                details: """
                • 遮断方法: 特権ヘルパーが pf に `block drop all`（ループバックのみ許可）を読み込み、読み戻して適用を確認。受信だけでなく送信も止まるため、C2サーバーへの鍵やデータの持ち出しを防ぎます。適用に失敗した場合は最大3回（1回8秒のタイムアウト）再試行し、それでも失敗したら「自動ネットワーク遮断に失敗しました」と明示して手動での切断を促します（隔離できていないのに隔離済みと表示することはありません）。
                • Wi-Fi無線もオフ: pf の遮断はパケットを止めるだけで無線アダプタ自体は接続したままのため、ARPスプーフィング・ランサムウェア・XProtect連動の隔離では `networksetup` で Wi-Fi 無線そのものも切断します（既定オン、内部設定 `RoamSwitch.AirGapAutoWiFiKillEnabled`）。ClickFix対策の隔離では無線は切断しません。
                • 解除: 緊急モーダルや通知から解除すると、pf の遮断とWi-Fi無線が復旧します。
                • フェイルセーフ: アプリがクラッシュしたり解除されないまま放置された場合も、ヘルパー側のタイマーが10分経過で遮断を強制解除し、Wi-Fi無線も戻します。アプリの再起動・Macの再起動でも手動操作なしで復旧します。
                • 起動時ゲート: Mac起動直後、アプリがポリシーを適用するまでの間はブートゲート（既定拒否のpfルール）が働き、最大90秒で自動解除されます。
                """,
                recommendation: "隔離が発動したら、まず通知の内容を確認し、不審なアプリの終了やスキャンを行ってから解除してください。誤検知と判明している場合はすぐに解除して構いません。"
            ),
            LocalizedEntry(
                id: "feat_port_anomaly_guard",
                title: "未知のリスニングポート自動遮断 & 開発サーバー外部隔離 (Pro)",
                summary: "待機中の全TCPポートを監視し、それまで外部公開していなかった実行ファイルが突然 0.0.0.0 でリッスンを始めた場合に、そのポートへの外部LANからのアクセスを自動遮断します。開発サーバーやローカルAIサーバーのワンクリック隔離（127.0.0.1専用化）も可能です。",
                details: """
                • 監視: 20秒ごとに待機ポートを走査。実行ファイルのパスで識別するため、既知のアプリがポート番号を変えただけでは反応しません。有効化直後の状態をベースラインとして記録します。
                • 自動遮断: 未知の実行ファイルが外部公開を始めると、pf で外部からのアクセスのみ遮断（Mac自身・localhostからは引き続き利用可能）。マルウェアの種類を知らなくても、ゼロデイ攻撃で仕込まれたバックドアを捕捉できます。
                • 対象外: `/System/Library` や `/usr/libexec` 配下のApple署名システムデーモン（rapportd など、Handoff・AirPlay・AirDropの動作に必要なもの）。`/usr/bin/python3` や `/usr/bin/nc` など `/usr/bin` の汎用ツールによるリッスンは対象です。
                • 危険サービス警告: 認証なしで公開されがちな Redis (6379)、MongoDB (27017)、Memcached (11211)、Elasticsearch (9200)、VNC (5900) や、Ollama (11434)、LM Studio (1234)、Gradio (7860)、vLLM (8000) などのローカルAIサーバーを識別して警告します。
                • 開発サーバー隔離: メニュー「外部公開ポート」から対象ポートを開き「外部から隔離する」で127.0.0.1専用に封鎖（Pro）。
                • 誤検知時: 通知の「許可する」ボタン、またはポート診断画面から恒久的に許可。ガードをオフにする（またはライセンス失効）と、自動で作成した遮断はすべて解除されます。
                • 既定値: Proライセンスの初回有効化時に自動でオン。検知履歴はMCPの `get_port_anomaly_incidents` で確認できます。
                """,
                recommendation: "開発サーバーやローカルLLMは `127.0.0.1` にバインドして起動してください（例: `OLLAMA_HOST=127.0.0.1 ollama serve`、`npm run dev -- -H 127.0.0.1`）。"
            ),
            LocalizedEntry(
                id: "feat_active_vuln_scan",
                title: "実証型脆弱性診断（能動的到達確認） — 既定オフ",
                summary: "このMac自身（127.0.0.1）で検出されたサービスに対し、認証なしで実際に応答してしまうかを、最小限の読み取り専用プローブで確認します。既定でオフで、明示的なオプトインと実行ごとの確認が必要です。",
                details: """
                • 有効化: メニュー「ポート・デバイス監視」→「実証型脆弱性診断（能動的到達確認）」。これはポート診断画面の「実証確認を実行」ボタンを解禁するだけで、単独では何も送信しません。実行時も毎回「実証確認を送信しますか？」と確認します。
                • 対象は127.0.0.1のみ: 他のホストへは一切送信しません。
                • 無認証確認: Redis（PING）、Memcached（stats）、MongoDB（listDatabases）に、単発・短タイムアウトの非破壊プローブを送信。
                • 汎用開発サーバー診断: CORS誤設定（Origin反射＋資格情報許可）、パストラバーサル、オープンリダイレクトを確認。
                • 既知CVEのバージョン照合: 無認証で到達できたRedis / Memcachedのバージョンを非破壊クエリで取得し、既知CVEのバージョン範囲と照合。攻撃ペイロードは送信しません。
                • MCPツール `run_active_vuln_scan` からも実行できます（このツールだけはローカルホストへの通信を伴います）。
                """,
                recommendation: "自分のMacで動かしているRedis・Docker・ローカルLLMなどが本当に無認証で到達できる状態かを確かめたいときにだけ有効化してください。"
            ),
            LocalizedEntry(
                id: "feat_usb_keyboard_guard",
                title: "不正USB / BadUSB 物理ポートガード（キーボード承認 & キー入力タイミング解析） (Pro)",
                summary: "未知のUSBキーボードや改造USBケーブル（Rubber Ducky / O.MG Cable / Flipper Zero など）が接続されると、承認されるまでそのデバイスのキー入力を遮断し、自動コマンド注入を防ぎます。さらに、キー入力の間隔から自動スクリプトの兆候を解析して警告します。",
                details: """
                • 検知: IOHIDManager で新しいキーボードの接続をリアルタイムに検知。内蔵キーボードは自動で信頼されます。
                • 遮断: 未承認デバイスを排他的に占有（IOHIDDeviceのseize）し、そのデバイスのキー入力だけがシステムに届かないようにします。他のキーボードは通常どおり使えます。占有できない場合のみ、アクセシビリティ権限を使ったCGEventTapによる遮断に切り替えます。
                • 承認: 最前面の承認ウィンドウで「信頼して許可する」または「拒否して遮断を維持」を選択。許可したキーボードは許可リストに登録されます。
                • キー入力タイミング解析: 遮断中もそのデバイスからのキー入力間隔を計測。5回以上の入力で、平均間隔が12ms以下、または平均45ms以下かつ非常に均一（変動係数0.35以下）な場合に「自動入力(スクリプト)の兆候」として警告します。人間の打鍵にはない機械的な速さ・均一さを捉える補助シグナルで、遮断の判断自体には影響しません。
                • 既定オフ。メニュー「ポート・デバイス監視」→「不正USB / BadUSB物理ポートガード (Pro)」で有効化し、「USB / BadUSBガード設定…」で許可リストを管理します。
                """,
                recommendation: "外付けキーボードを使う場合は、自分で接続したものだけを「信頼して許可する」で登録してください。スクリプトの兆候の警告が出たデバイスは必ず拒否して取り外してください。"
            ),
            LocalizedEntry(
                id: "feat_usb_storage_guard",
                title: "不正USBストレージ自動遮断 & ClamAV自動スキャン (Pro)",
                summary: "許可リストにないUSBメモリや外部ストレージが接続されると、まず読み取り専用でマウントして承認を求めます。許可済みのデバイスもClamAVでスキャンしてから、設定された権限で接続します。",
                details: """
                • 監視: DiskArbitration で外部・リムーバブルボリュームのマウントを即座に捕捉。
                • 未登録デバイス: 安全のため読み取り専用で再マウントし、「読み書きで許可」「読み取り専用で許可」「取り出す」を選ぶダイアログを表示。取り出しを選ぶと即座にアンマウント・排出します。
                • 許可済みデバイス: 許可リストの権限（読み取り専用 / 読み書き両方）を自動適用。読み書きに昇格する前にClamAVでスキャンします。
                • 感染時: マルウェアを検出したら自動で取り出し、緊急通知を送ります。
                • 再フォーマット対応: ボリュームUUIDが変わっても、シリアル番号を含むハードウェア識別子が一致すれば同じドライブとして許可を引き継ぎます（ベンダーID/製品IDだけでは一致とみなしません）。
                • 範囲: ストレージ経由のデータ持ち出し・不正ペイロードを防ぐ機能です。キーボードを装うHID型BadUSBは feat_usb_keyboard_guard が担当します。
                """,
                recommendation: "業務で使う安全なUSBメモリだけを許可リストに登録し、機密データを扱うMacでは「読み取り専用」での許可を推奨します。"
            ),
            LocalizedEntry(
                id: "feat_bluetooth_guard",
                title: "未信頼ネットワークでBluetoothを自動オフ (Pro)",
                summary: "最大ロックダウンが適用される外出先ネットワークに接続すると、Bluetoothを自動でオフにし、不正なペアリングやBLE攻撃への露出を減らします。信頼済みネットワークに戻ると自動で元に戻します。",
                details: """
                • ツール連携: macOSにはBluetoothの電源をアプリから切り替える公開APIがないため、Homebrewのオープンソースツール `blueutil` を使用します（`brew install blueutil`）。未導入の場合はメニューに導入案内が表示されます。
                • 復元: オフにする直前にBluetoothがオンだった場合のみ、信頼済みネットワークで再びオンにします。外出中にユーザーが自分で切り替えた状態は上書きしません。
                • 既定オフ: カフェでAirPodsなどを使う人が多く、無断で音声を切ると不便なため、オプトインです。
                """,
                recommendation: "外出先でBluetooth機器を使わない場合は有効にして、周囲からの電波探索や不正ペアリングを防ぎましょう。"
            ),
        ]
    }

    // MARK: - Features: malware & web protection

    private static func featuresJaMalware() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_webmail_download_guard",
                title: "Web・メール保護（ダウンロード自動スキャン & 自動隔離） (Pro)",
                summary: "ブラウザ・メール・Slack・Discordなどから保存されたファイルをFSEventsで監視し、静的シグネチャ検査とClamAVで自動スキャンして、脅威を検疫フォルダへ隔離します。",
                details: """
                • 監視対象: 既定は `~/Downloads`、`~/Desktop`、`~/Documents` とメールのダウンロードフォルダ。「⚙️ 監視対象フォルダを編集…」で追加・削除できます。
                • ダウンロード元の識別: macOSが付与する `com.apple.quarantine` 拡張属性からダウンロード元アプリを判別します。
                • 二段構えの検査: 端末内の静的シグネチャ検査（リバースシェルの定型コマンドなど、ClamAV未導入でも動作）と、ClamAVによる検査を実行。静的シグネチャで検知したファイルはClamAVの結果に関わらず隔離し、ClamAVが一致しなかった場合は「誤検知の可能性」を通知に明記します。
                • 隔離: 脅威は `~/Library/Application Support/RoamSwitch/Quarantine/` に移動（削除はしません）。移動に失敗した場合は「隔離に失敗しました」と明示し、手動削除を案内します。
                • EICARテストファイル: 業界標準の無害なテスト署名は隔離も遮断もせず、通知も出さずに通知履歴への記録のみ行います（feat_notification_history）。
                • 初回のフォルダアクセス: macOSのアクセス許可ダイアログの前に、これがスキャン機能のための正規の許可であることを説明する案内を1度だけ表示します。
                • Pickle形式のAIモデルの警告は feat_ai_model_guard を参照。
                """,
                recommendation: "ClamAVを導入した上で有効化し、ブラウザの保存先を独自フォルダにしている場合は監視対象フォルダに追加してください。"
            ),
            LocalizedEntry(
                id: "feat_ai_model_guard",
                title: "危険なAIモデル形式（Pickle / PyTorch）のダウンロード警告 (Pro)",
                summary: "HuggingFaceやCivitaiなどから `.pkl` / `.pickle` / `.pt` 形式のモデルファイルがダウンロードされると、読み込み時に任意のコードを実行できるPickle形式であることを警告し、SafeTensors / GGUF 形式の利用を推奨します。",
                details: """
                • 検知: Web・メール保護（feat_webmail_download_guard）の監視対象でダウンロードされたファイルの拡張子を判定します。
                • リスク: PythonのPickleはデシリアライズ時に任意のコードを実行できるため、悪意あるモデルを読み込むだけで感染する可能性があります。
                • 挙動: 警告通知のみで、ファイルの隔離は行いません（ClamAVや静的シグネチャで脅威が検出された場合は通常どおり隔離されます）。
                """,
                recommendation: "出所の分からないPickle / PyTorch形式のモデルは読み込まず、`.safetensors` や `.gguf` 形式のモデルを利用してください。"
            ),
            LocalizedEntry(
                id: "feat_quarantine_manager",
                title: "隔離ファイルの管理（検疫Vault・復元・削除・スキャン除外）",
                summary: "ClamAVや静的シグネチャで検出されたファイルは削除されず、検疫Vaultに保管されます。「隔離ファイルの管理」画面で、隔離理由の確認・元の場所への復元・完全削除・スキャン対象からの除外を行えます。",
                details: """
                • 開き方: メニュー「マルウェア対策 (XProtect & ClamAV)」→ ClamAV →「📦 隔離ファイルを管理…」、または Web・メール保護の「📦 隔離マネージャーを開く…」。
                • 保管場所: `~/Library/Application Support/RoamSwitch/Quarantine/`。元のパス・脅威名・隔離日時をメタデータとして保存します。ユーザーが明示的に「完全に削除」を選ばない限り、ファイルが消えることはありません。
                • 元に戻す: 感染していないと確信できる場合のみ、元の場所へ戻します。
                • 除外して復元: 誤検知と確信できる場合に、元の場所へ戻し、そのパスを今後のClamAVスキャン対象から除外します（完全一致のパスのみ）。除外は同じ画面の「スキャン対象から除外中のパス」から「除外を解除」できます。
                • 完全に削除: 確認ダイアログの後に削除します。取り消しはできません。
                • MCPツール `get_quarantine_status` で隔離中のファイル一覧を確認できます。
                """,
                recommendation: "心当たりのないファイルは「完全に削除」し、自作のスクリプトや開発用バイナリなど誤検知が確実な場合のみ「除外して復元」を使ってください。"
            ),
            LocalizedEntry(
                id: "feat_xprotect_file_safety",
                title: "Apple XProtect 稼働確認 & ファイル・アプリの安全性診断",
                summary: "Apple純正のマルウェア対策 XProtect の定義バージョンと稼働状態を表示し、任意のファイルやアプリについて、Apple公証（Notarization）・署名発行元・Team ID・ダウンロード隔離属性をまとめて診断します。無料版で利用できます。",
                details: """
                • 開き方: メニュー「マルウェア対策 (XProtect & ClamAV)」→「🍏 Apple XProtect」→「XProtect 稼働状態を確認…」「ファイル・アプリの安全性診断…」。
                • 診断項目: Apple公認（Notarized / Gatekeeper）の可否、署名発行元、Team ID、Webダウンロード隔離属性（`com.apple.quarantine`）の有無、対象パス。
                • 用途: 入手したアプリを初めて開く前に、正規の開発元が署名・公証したものかを確認できます。
                """,
                recommendation: "出所の分からないアプリは起動前に安全性診断を行い、未承認・署名なしの場合は開かないでください。"
            ),
            LocalizedEntry(
                id: "feat_dns_threat_guard",
                title: "DNS脅威保護（悪質サイト・C2遮断） (Pro)",
                summary: "Quad9・Cloudflare・AdGuard・CleanBrowsing のセキュアDNSを適用し、マルウェアのC2サーバーやフィッシングサイトへの名前解決をDNSの段階で遮断します。",
                details: """
                • プロバイダー: Quad9（9.9.9.9 / 149.112.112.112）、Cloudflare Security（1.1.1.2 / 1.0.0.2）、AdGuard DNS（94.140.14.14 / 94.140.15.15、広告・トラッカーも遮断）、CleanBrowsing Security（185.228.168.9 / 185.228.169.9）。
                • 適用ポリシー: 「外出先・未信頼Wi-Fiのみ適用（推奨）」または「すべてのネットワークで常時適用 (保護環境含む)」。
                • 内部制御: 特権ヘルパーがアクティブなネットワークサービスのDNS設定を切り替え、信頼済みネットワークに戻ると元のDHCP / 手動DNS設定に復元します。
                • 状態表示: メニューに「🟢 セキュアDNS適用中」または「🏠 信頼ネットワーク（ルーター標準DNS）」を表示。セキュリティ総合診断の項目にも反映されます。
                """,
                recommendation: "公衆Wi-Fiの偽DNS（DNSハイジャック）や悪質ドメインへの接続を防ぐため、Quad9＋「外出先・未信頼Wi-Fiのみ適用」から始めるのがおすすめです。"
            ),
            LocalizedEntry(
                id: "feat_passive_link_guard",
                title: "リンク保護（フィッシング接続の検知・遮断：システム拡張 / DoH対応 / 警告モードはフェイルクローズ） (Pro)",
                summary: "既知の詐欺サイト一覧（脅威フィード）とブランド偽装ドメインの判定に基づき、ブラウザやアプリを問わずフィッシング・詐欺サイトへの接続を端末側で遮断します。コンテンツフィルタのシステム拡張で動作し、承認前は /etc/hosts シンクホールで代替します。",
                details: """
                • モード: 「オフ」「警告のみ (遮断しない)」「明らかな詐欺サイトは自動でブロック (推奨)」。既定は自動ブロック。メニュー「マルウェア対策」→「リンク保護 (フィッシング接続の検知) (Pro)」で切替。
                • 遮断対象: 脅威フィードに掲載されたドメイン、またはブランド名のUnicodeホモグラフ偽装など明確なケースのみ。サブドメイン偽装や高リスクTLDなどは警告扱いです。判定エンジンとフィードはLinux版と共通。
                • システム拡張（推奨）: コンテンツフィルタのシステム拡張 `RoamSwitchLinkFilter` が名前解決後のTCP通信を検査。OSの名前解決情報に加え、TLS ClientHello の SNI を読むため、ブラウザ独自の DoH / DoT を使っていても判定できます。ブロックモードでは SNI を読めない QUIC（UDP 443）を遮断し、ブラウザをTCPにフォールバックさせます。初回はシステム設定での承認が必要です。
                • JA3 フィンガープリント: SNI を読めたTLS接続では、クライアントのJA3ハッシュも算出し、脅威フィードのJA3一覧と照合します（SNIなしの接続にはJA3単独判定は行いません）。
                • 警告モード（フェイルクローズ）: 該当する通信を一時停止し、「許可する / ブロックする」の通知と最前面パネルを表示。回答を受けて通信を再開または破棄します。約8秒以内に回答がなければ通信を遮断します（遮断結果はキャッシュしないため、次回アクセス時に再度確認）。ユーザーが選んだ許可・ブロックは記憶されます。警告モードはシステム拡張が必要です。
                • hostsフォールバック: システム拡張が有効でない間、ブロックモードでは特権ヘルパーが `/etc/hosts` の管理セクションに対象ドメインを `0.0.0.0` として書き込みます。
                • 脅威フィード: 1日1回、受信専用で取得（識別子の送信なし）。フィード専用のEd25519鍵で署名検証します（アプリ更新用の鍵とは別）。「自動更新」をオフにすると外部通信ゼロで、同梱データとホモグラフ検知のみで動作します。
                • 非Pro: モードは保存されますが、遮断は行われません。
                """,
                recommendation: "既定の自動ブロックのまま、システム拡張を承認して使うのが最も確実です。社内ツールなどが誤って遮断された場合は、通知の「今回は許可 (5分)」や許可リストで対応してください。"
            ),
            LocalizedEntry(
                id: "feat_link_safety_auditor",
                title: "リンク安全性診断（手動チェック・Zero Telemetry）",
                summary: "不審なURLをブラウザで開く前に、端末内だけで解析し、Unicodeホモグラフ偽装・サブドメイン偽装・高リスクTLD・平文HTTP・IP直打ちなどから危険度を100点満点で診断します。無料版で利用できます。",
                details: """
                • 開き方: メニュー「マルウェア対策」→「🔗 リンクを手動でチェック…」、またはMCPツール `audit_url_safety`。
                • ホモグラフ偽装: キリル文字・ギリシャ文字などを使った偽装（Punycode / `xn--`）を検出。
                • サブドメイン偽装: `apple.com.login-verify.xyz` のように大手ブランド名を紛れ込ませた構造を解析。
                • 高リスクTLD: `.xyz`、`.top`、`.tk`、`.icu` など、使い捨てのフィッシングで多用されるTLDを減点。
                • 平文HTTP・IP直打ち: ログイン画面などの暗号化なしHTTPや、生のIPアドレスURLを警告。
                • 完全ローカル: 外部の診断APIにURLを送信しないため、機密URLや認証トークンが漏れません。
                """,
                recommendation: "メールやチャットで届いた不審なリンクは直接クリックせず、まずリンク安全性診断で確認してください。"
            ),
            LocalizedEntry(
                id: "feat_ransomware_canary_guard",
                title: "ランサムウェアおとりファイル検知 & 自律エアギャップ隔離・プロセス凍結 (Pro)",
                summary: "ユーザーフォルダに隠しおとり（カナリア）ファイルを配置し、改ざん・削除・リネームを検知した瞬間に、ネットワークの全遮断・共有サービス停止・疑わしいプロセスの一時停止（SIGSTOP）を自動で行います。",
                details: """
                • おとりファイル: `~/Library/Application Support/RoamSwitch/CanaryGuard/` に4つ、さらに「書類」「デスクトップ」「ダウンロード」「ピクチャ」に `.roamswitch_security_canary_do_not_delete` で始まる隠しファイルを配置。各ファイルのSHA-256をベースラインとして記録します。
                • 検知: kqueue によるリアルタイム監視と60秒ごとの定期確認を併用。同じファイルの連続イベントは10秒のクールダウンで重複処理を防ぎます。直近60秒以内に変更された実ファイルも「影響を受けた可能性があるファイル」として記録します。
                • 自動対応: ①アプリケーションファイアウォールのロックダウン ②エアギャップ隔離（pfで送受信を全遮断＋Wi-Fi無線オフ、feat_airgap_containment）③共有サービス（SMB / SSH / 画面共有）の停止 ④疑わしいプロセスを強制終了ではなく一時停止（SIGSTOP）⑤緊急通知と最前面の緊急モーダル表示。
                • 凍結の理由: 通信はすでに遮断されているため、停止したプロセスはそれ以上被害を広げられません。誤検知だった場合は解除時に再開（SIGCONT）でき、データを失いません。
                • 解除時: ネットワークとWi-Fiを復旧し、停止したプロセスを再開し、改ざんされたおとりファイルを再生成します。
                • 既定値: Proライセンスの初回有効化時に自動でオン。検知履歴はMCPの `get_canary_status` で確認できます。メニューの「ランサムウェア防護シミュレーション (動作確認)」で安全にテストできます。
                """,
                recommendation: "未知のランサムウェアから重要データを守るため、有効のままにしてください。おとりファイル（隠しファイル）は削除しないでください。"
            ),
            LocalizedEntry(
                id: "feat_runtime_threat_containment",
                title: "XProtectのマルウェア検知に連動した自動ネットワーク遮断 (Pro)",
                summary: "Apple純正の XProtect / XProtect Remediator が実際にマルウェアを検知・駆除した瞬間に、ネットワークを緊急全遮断します。Gatekeeper による未署名アプリのブロックでは遮断せず、通知のみ行います。",
                details: """
                • 信号源: `/usr/bin/log stream` をndjson形式で常時購読（ポーリングではなく待機型のため、アイドル時のCPU負荷はほぼゼロ）し、XProtect関連のシステムログを監視します。
                • 遮断条件: XProtectが重大（critical）なマルウェア検知を記録した場合のみエアギャップ隔離（Wi-Fi無線オフを含む）。ネットワークの信頼レベルに関係なく発動します。
                • Gatekeeperとの違い: 開発者が自分でビルドした未署名アプリの起動ブロックなど、日常的に起こるGatekeeperイベントは「Gatekeeperが未署名アプリの実行をブロックしました」という通知のみです。
                • 判定の一貫性: 手動の「Macセキュリティログ監査」と同じ分類ロジックを共有しています。
                • EndpointSecurityのエンタイトルメントを使わない設計のため、実行前のブロックではなく「検知後の即時隔離」です。
                • 既定値: Proライセンスの初回有効化時に自動でオン（その際、自動遮断が有効になった旨を1度だけ案内）。状態はMCPの `get_runtime_threat_status` で確認でき、「マルウェア検知連動Air-Gapのシミュレーション (動作確認)」でテストできます。
                """,
                recommendation: "Apple純正のマルウェア対策と連動した自動防御として有効のままにしてください。未署名の自作アプリを頻繁に実行する環境でも、Gatekeeperのブロックだけでは遮断されません。"
            ),
            LocalizedEntry(
                id: "feat_clickfix_guard",
                title: "ClickFix対策 — 不審なTerminalコマンド検知時に自動遮断 (Pro・既定オフ)",
                summary: "偽のCAPTCHAやエラー画面がユーザー自身にコマンドを貼り付けて実行させる「ClickFix」手口を、シェル履歴から検知し、実行中の多段階攻撃を止めるためにネットワークを緊急遮断します。",
                details: """
                • 監視対象: `~/.zsh_history` と `~/.bash_history` の新たに追記された行のみ（既存の履歴は対象外）。
                • 検知パターン: ①既知のリバースシェル定型コマンド（静的シグネチャ検査と共通）②Base64でデコードした内容をシェルや `osascript` に直接渡す二重の迂回パターン。Homebrewなど正規インストーラーが使う単純な `curl ... | bash` は対象外です。
                • 自動対応: エアギャップ隔離（Wi-Fi無線は切断しない）。最大10分で自動復旧します。通知ではKeychain・ブラウザ保存パスワード・暗号資産ウォレットの安全確認を推奨します。
                • 事後対応である理由: 履歴に記録された時点でコマンドは実行済みですが、二段目のダウンロード・リバースシェル接続・認証情報の持ち出しなどが進行中なら、即座の遮断で被害拡大を止められます。
                • Gatekeeperでは防げない理由: ユーザーの正規のシェルが入力どおりに実行しているだけなので、プロセス自体に不審な点がありません。
                • 補完: コピーした時点で検知するクリップボード保護（feat_secret_leak_auditor）もあり、Script EditorやSpotlightなどTerminal以外への貼り付けにも対応します。
                • 既定オフ: ネットワークを自動遮断する比較的新しいヒューリスティックのため、オプトインです。
                """,
                recommendation: "偽エラーページや偽CAPTCHAに誘導されてコマンドを実行してしまうリスクに備えたい場合は、有効化を検討してください。"
            ),
            LocalizedEntry(
                id: "feat_persistence_monitor_guard",
                title: "新規の自動起動登録（LaunchAgent / LaunchDaemon）の監視 (Pro)",
                summary: "新しい LaunchAgent / LaunchDaemon の登録をリアルタイムに監視し、シェルやスクリプトインタプリタを直接起動する登録や、署名が無効な実行ファイルを登録したものを検知して通知します。",
                details: """
                • 監視対象: `~/Library/LaunchAgents`、`/Library/LaunchAgents`、`/Library/LaunchDaemons` を FSEvents で監視（約1.5秒のデバウンス）。
                • 判定: 近年の情報窃取マルウェアは、正規署名済みの `/bin/bash` や `/usr/bin/osascript` にBase64で隠したスクリプトを実行させて永続化します。インタプリタ自体の署名は正しいため、生のインタプリタを直接起動する登録は署名に関係なく不審として扱い、スクリプト引数も静的シグネチャで検査します。署名が無効・未署名の実行ファイルも検知対象です。Homebrew services のラッパーは除外します。
                • 検知のみ: EndpointSecurityのエンタイトルメントを使わないため、plistの書き込み自体は止められません。書き込みから約1.5秒以内に判定して通知します。
                • 既定値: Pro版で既定オン。メニュー「マルウェア対策」→「新規の自動起動登録(LaunchAgent/Daemon)を監視 (Pro)」で切替。
                """,
                recommendation: "見慣れない自動起動登録の通知が来たら、通知に表示されたplistの内容を確認し、心当たりがなければ削除してください。正規アプリのインストール直後であれば問題ありません。"
            ),
            LocalizedEntry(
                id: "feat_docker_event_guard",
                title: "Dockerの特権コンテナ・docker.sockマウント検知 (Pro・既定オフ)",
                summary: "`--privileged` で起動したコンテナや `/var/run/docker.sock` をマウントしたコンテナなど、コンテナ脱出につながり得る危険なDocker設定を、新規起動の時点で検知して通知します。",
                details: """
                • 動作: 20秒ごとに `docker ps` で新しく起動したコンテナだけを確認し、`docker inspect` で設定を検査。Linux版と同じ判定書式を使うため、両OSで同じ条件を検知します。
                • 通知のみ: 危険な「設定」であって侵害が確定したわけではないため（監視エージェントを意図的に特権で動かすなど正当な用途もある）、自動遮断は行いません。
                • 既定オフ: Dockerを使わないユーザーが大半のため、Pro版でも既定はオフです。
                • テスト: メニューの「⚠️ Dockerリスク検知のシミュレーション (動作確認)…」で、Dockerを使わずに通知経路を確認できます。
                """,
                recommendation: "Dockerを開発で使う場合は、コンテナ脱出リスクの早期発見のために有効化を推奨します。"
            ),
        ]
    }

    // MARK: - Features: audit, monitoring & platform

    private static func featuresJaAudit() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_critical_path_fim",
                title: "重要システムファイルの改ざん監視（Critical Path FIM） (Pro)",
                summary: "sudoers・SSH設定・PAM・hosts など、正規のOS更新やアプリのインストールではほとんど変わらない重要ファイルのSHA-256ベースラインを記録し、変更・削除・新規追加を検知して通知します。",
                details: """
                • 対象: `/etc/sudoers`、`/etc/pam.d/sudo`、`/etc/ssh/sshd_config`、`/etc/ssh/sshd_config.d/` 配下、`/etc/hosts`、rootの `~/.ssh/authorized_keys`。root権限でしか読めないため、特権ヘルパーがハッシュを計算します。
                • 検知タイミング: `/etc`・`/etc/pam.d`・`/etc/ssh` の FSEvents でほぼリアルタイムに再スキャンし、1時間ごとの定期スキャンで取りこぼしを補います。
                • ベースライン: 初回スキャン時の状態を記録。改ざんを検知しても自動で新しいベースラインとして採用しないため、人が確認するまで検知状態が続きます（同じ状態についての通知はアプリ起動中は繰り返しません。さらに変更があれば再通知）。
                • 監視停止の警告: ヘルパーに3回連続で接続できない場合は、改ざん検知が機能していないことを通知します。
                • 補足: リンク保護がhostsフォールバックで動作している間は、RoamSwitch自身が `/etc/hosts` の管理セクションを書き換えることがあります。LaunchAgent / Daemon は feat_persistence_monitor_guard が担当します。
                • 既定値: Proライセンスの初回有効化時に自動でオン。メニュー「マルウェア対策」→「重要システムファイルの改ざんを定期監視 (Pro)」。
                """,
                recommendation: "通知が来たら、`sudo visudo` や設定変更など自分で行った作業かを確認してください。心当たりがなければ、該当ファイルの内容を直ちに確認し、パスワードの変更を検討してください。"
            ),
            LocalizedEntry(
                id: "feat_security_log_audit",
                title: "Macセキュリティログ監査（手動・テンプレート異常検知・AI相談用コピー）",
                summary: "macOSの統合ログから、sudoの失敗・SSH接続・Gatekeeperの遮断・XProtectの検知・認証イベントを抽出して分析し、新しいログパターンや頻度の急増（テンプレート異常）も一覧表示します。無料版で利用できます。",
                details: """
                • 開き方: メニュー「Macセキュリティ総合診断」→「📜 Macセキュリティログ監査…」、またはMCPツール `audit_security_logs`。
                • 期間: 過去24時間 / 過去3日間 / 過去7日間。
                • 集計カード: Sudo 失敗、SSH 接続、Gatekeeper 遮断、XProtect 検知、テンプレート異常。カテゴリでの絞り込みと検索が可能です。
                • テンプレート異常検知: IPアドレス・16進アドレス・数値などの可変部分を伏せてログをパターン化し、このMacで初めて見るパターン（[新規]）と、過去の出現頻度から大きく外れた急増（[急増 z=…]、zスコア3以上）を抽出。パターンごとの頻度は3回の観測で学習が完了し、以後は定常的なものを通知しなくなります。
                • 平易な判定: 端末内のルールベースのアシスタントが、非専門家向けの結論と具体的な確認事項を表示します（外部APIは使いません）。
                • 出力: 「レポートをコピー」「AIに相談する材料をコピー」（ClaudeやChatGPTに貼り付ける質問文とログをまとめてコピー。RoamSwitchが送信することはありません）、「CSVエクスポート (Pro)」。
                """,
                recommendation: "不審な通知が続いたときや、Macの挙動に違和感があるときに実行し、XProtect検知やSudo失敗の急増がないか確認してください。"
            ),
            LocalizedEntry(
                id: "feat_scheduled_log_audit",
                title: "自動ログ監査（新規パターン・頻度異常を定期学習） (Pro)",
                summary: "ログ監査のテンプレート異常検知を1時間ごとにバックグラウンドで実行し、このMacの普段のログ傾向を学習し続けます。新しいパターンや頻度の急増を検知すると、実際のログ行の例と平易な説明を添えて通知します。",
                details: """
                • 実行間隔: 1時間ごとに直近1時間分を分析。有効化の約10秒後に最初のスキャンを行いますが、アプリ自身の起動ログを含むため、その回は通知せず学習のみ行います。
                • 通知内容: 異常の件数（新規パターン・頻度急増の内訳）、最大3件の実際のログ行、学習状況の注記、非専門家向けの説明。新規パターンは一度通知すると「既知」として扱われ、同じ内容で再通知されません。頻度急増はパターンごとの学習が完了すると鳴らなくなります。
                • 手動監査との関係: 手動の「Macセキュリティログ監査」やMCPの `audit_security_logs` と同じ分析・学習データを共有します。
                • 既定値: Proライセンスの初回有効化時に自動でオン。メニュー「マルウェア対策」→「自動ログ監査(新規パターン・頻度異常を定期学習) (Pro)」。
                """,
                recommendation: "導入直後は新しいパターンの通知がやや多くなりますが、学習が進むと落ち着きます。見覚えのないアプリ名やIPアドレスが含まれる場合は、ログ監査画面で詳細を確認してください。"
            ),
            LocalizedEntry(
                id: "feat_containment_incident_timeline",
                title: "封じ込めインシデント履歴（統合タイムライン・MITRE ATT&CK分類）",
                summary: "ARPスプーフィング・ランサムウェアおとりファイル・XProtect連動遮断・未知ポート自動遮断の4つの自動対応を、1つの時系列の記録にまとめて端末内に保存します。いつ何が起き、どう対応し、いつ解除されたかを後から振り返れます。",
                details: """
                • 記録内容: 発生日時、検知元、重大度、概要、プロセス名とPID（分かる場合）、実施した対応、解除日時と解除理由（手動解除 / タイムアウトによる自動解除 / 許可リスト登録）。
                • MITRE ATT&CK: 確実に対応付けられる場合のみ技術IDを付与（ARPスプーフィング = T1557、おとりファイルの削除・リネーム = T1485、暗号化 = T1486、その他の改ざん = T1565）。推測での分類は行いません。
                • 保存: `~/Library/Application Support/RoamSwitch/containment_incident_timeline.json`（最新200件）。外部送信はありません。
                • MCPツール `get_incident_timeline` でこの統合タイムラインを取得できます（Air-Gap中にローカルのAIで原因を調べる用途にも使えます）。個別の履歴は `get_canary_status`、`get_port_anomaly_incidents`、`get_runtime_threat_status` でも確認できます。
                """,
                recommendation: "自動遮断が発生した後は、この履歴と通知履歴を合わせて確認し、原因の特定と再発防止に役立ててください。"
            ),
            LocalizedEntry(
                id: "feat_notification_history",
                title: "通知履歴（過去1週間）",
                summary: "RoamSwitchが送信したすべての通知を7日間保存し、見逃した警告を後から確認できます。EICARテスト署名の検出のように、通知を出さずに履歴のみに記録されるイベントもここで確認できます。無料版で利用できます。",
                details: """
                • 開き方: メニュー「Macセキュリティ総合診断」→「🔔 通知履歴…」。
                • 保存期間: 7日間。古い記録は新しい通知を記録するたびに自動で削除されます。
                • 記録内容: 日時・タイトル・本文。脅威アラート、リンク保護の接続イベント、ClickFix・機密キー検知、各種自動遮断などを含みます。
                • EICARテスト署名: 業界標準の無害なテストファイルは実際の脅威ではないため、隔離も遮断もせず、通知バナーも出さずに履歴へ記録のみ行います（ダウンロード保護・クイックスキャン・定期スキャンのいずれでも同様）。
                • MCPツール `get_notification_history` でAIから確認することもできます。
                """,
                recommendation: "外出中や作業中に通知を見逃した場合は、通知履歴で内容を確認してください。"
            ),
            LocalizedEntry(
                id: "feat_secret_leak_auditor",
                title: "クリップボード保護（APIキー誤貼り付け防止 & ClickFixコマンド削除）",
                summary: "クリップボードを端末内だけで監視し、APIキーや秘密鍵のコピーを検知して誤貼り付けを警告します。詐欺サイトが実行させようとする不正なコマンド（ClickFix）をコピーした場合は、クリップボードから自動で削除します。無料版で既定オンです。",
                details: """
                • 監視: 約1秒ごとにクリップボードの変更を確認。内容は外部に送信せず、生データを保存しません。
                • 検知するキー: OpenAI、Anthropic、GitHub、AWS、HuggingFace、Google AI / Gemini、Slack、Stripe のAPIキー・トークン、RSA / SSH 秘密鍵。加えて、暗号資産ウォレットのシードフレーズ（BIP39）とBitcoin秘密鍵（WIF/BIP32、いずれもチェックサム検証付きで誤検知を抑制）。
                • 機密キーの場合: 「クリップボードに機密キーを検知しました」と通知のみ（キーの失効・再発行で事後対応が可能なため、削除はしません）。
                • ClickFixコマンドの場合: 「クリップボードで不審なコマンドを検知しました」と通知し、クリップボードを即座に消去。Terminalだけでなく、Script Editor・Spotlightなど、どこに貼り付けられる前でも止められます。シェル履歴を見る feat_clickfix_guard を補完します。
                """,
                recommendation: "APIキーをコピーした後は、AIチャットやWebフォームへの貼り付け先に注意してください。誤って共有した場合は、すぐにキーを失効・再発行してください。"
            ),
            LocalizedEntry(
                id: "feat_secret_leak_audit_tool",
                title: "機密情報・APIキー漏洩の手動監査（テキスト貼り付け診断 & フォルダ一括スキャン）",
                summary: "テキストを貼り付けての即時診断と、フォルダを丸ごと再帰的にスキャンする、オンデマンドの監査ツールです。行番号・マスク済みの文字列・キーの種類ごとの失効手順を表示します。無料版で利用できます。",
                details: """
                • 開き方: メニュー「マルウェア対策」→「🔑 機密情報・APIキー漏洩を手動監査…」、またはMCPツール `audit_secrets`（`text` または `path` を指定）。
                • 検出方式: 正規表現とシャノンエントロピーによるスコアリング。検出値はマスクして表示します。
                • フォルダスキャン: `.git`・`node_modules`・`target`・`vendor`・`dist`・`build`・`__pycache__`・`venv` は自動除外。2MBを超えるファイルやバイナリはスキップします。
                • 権限の説明: デスクトップやダウンロードなどの保護フォルダを選ぶと、macOSの許可ダイアログの前に、アクセスが必要な理由とZero Telemetryであることを説明する案内を初回のみ表示します。
                • 処理は別スレッドで行われ、UIを止めません。外部への送信は一切ありません。
                """,
                recommendation: "リポジトリを公開する前や、コードをAIチャットに貼り付ける前の一括チェックに活用してください。"
            ),
            LocalizedEntry(
                id: "feat_package_cve_scan",
                title: "パッケージCVE照合（Homebrew + npm / PyPI / crates.io など7エコシステム・Zero Telemetry）",
                summary: "インストール済みのHomebrewパッケージと、指定したプロジェクトフォルダの依存関係ロックファイルを、端末内に保持した既知CVEマップと照合します。スキャン自体はネットワーク通信を一切行いません。無料版で利用できます。",
                details: """
                • 開き方: メニュー「マルウェア対策」→「📦 パッケージCVE照合 (Homebrew)…」。依存関係は「依存関係」タブでプロジェクトフォルダを追加。
                • Homebrew: `brew list --versions` の結果を、NVDの実データから生成したformula→CPE対応表と照合。検出結果には確度（confirmed = 検証済みの対応表 / gray = 未検証のキーワード一致で誤検知の可能性あり）が付きます。
                • 依存関係: package-lock.json / requirements.txt / Pipfile.lock / poetry.lock / Cargo.lock / Gemfile.lock / composer.lock / go.sum / pom.xml を解析し、npm・PyPI・crates.io・RubyGems・Packagist・Go・Maven の既知CVEマップ（OSV.dev由来、CVSS 7.0以上）と照合。
                • データ配信: CVEマップは1日1回、署名付きマニフェストから受信専用で取得します。未取得の間は「未取得」と表示され、何も検出しません。
                • MCPツール: `run_package_cve_scan`（Homebrew）と `run_package_cve_scan_languages`（依存関係、`watchedFolders` 引数）。
                """,
                recommendation: "定期的にHomebrewのスキャンを実行し、開発中のプロジェクトは依存関係タブに登録して、重大なCVEを含むパッケージを早めに更新してください。"
            ),
            LocalizedEntry(
                id: "feat_lockfile_tamper_guard",
                title: "依存関係ロックファイルの改ざん監視 (Lockfile FIM, Pro)",
                summary: "package-lock.json / yarn.lock / pnpm-lock.yaml / npm-shrinkwrap.json をSHA-256ベースラインで常時監視し、CIやサプライチェーン経由の外部改ざんを検知します。Pro版限定。",
                details: """
                • 開き方: メニューバーの「🔔/✅ 依存関係ロックファイルの改ざんを定期監視 (Pro)」で切り替え。
                • 監視対象: パッケージCVE照合の「依存関係」タブで登録した同じプロジェクトフォルダ内の package-lock.json / yarn.lock / pnpm-lock.yaml / npm-shrinkwrap.json。新規の監視対象リストは追加しません。
                • 検知方式: CryptoKitによるSHA-256ベースライン差分。FSEventsによる近似リアルタイム検知＋1時間ごとのバックストップスキャン。
                • 通知の緊急度: npm/yarn/pnpm自体が実行中に検知した場合は、その旨を通知履歴に記録した上で静かな通知にとどめます。非実行中の改ざんは通常の緊急通知です。検知自体は両ケースで必ず行われます。
                • ライセンス喪失時は自動的に無効化されます。
                """,
                recommendation: "重要なプロジェクトはパッケージCVE照合の「依存関係」タブに登録し、Pro版有効化時の既定オンのままにしておくことを推奨します。"
            ),
            LocalizedEntry(
                id: "feat_package_lifecycle_script_scan",
                title: "インストールスクリプトの一覧 (npm package.json lifecycle scripts, Pro)",
                summary: "node_modules配下のpackage.jsonが宣言するpreinstall/install/postinstall/prepareスクリプトを一覧表示します。npm install時に無条件実行されるコードの可視化が目的で、脅威判定ではありません。Pro版限定。",
                details: """
                • 開き方: メニュー「マルウェア対策」→「📦 パッケージCVE照合 (Homebrew)…」→「インストールスクリプト (npm) (Pro)」タブ。「依存関係」タブと同じプロジェクトフォルダを対象にします。
                • 列挙対象: node_modules直下1階層（@scope/パッケージはさらに1階層）のpackage.jsonに宣言されたpreinstall/install/postinstall/prepareスクリプト。ネストしたnode_modulesへは降りません。
                • 危険パターンの参考表示: curl|sh・wget|sh・eval(・base64 -d・node -eに一致するコマンドには⚠️を表示しますが、これは軽量ヒューリスティックによる参考情報で、多くの正規スクリプト（ネイティブモジュールのビルド等）も該当します。
                • ネットワーク接続は一切行わず、スクリプトを実行することもありません。純粋な静的一覧表示です。
                • MCPツール: `run_package_lifecycle_script_scan`（`watchedFolders`引数、Pro限定）。
                """,
                recommendation: "⚠️マークの付いたスクリプトは、そのパッケージが本当に必要とする処理かを個別に確認してください。見慣れないパッケージのpostinstallは特に注意が必要です。"
            ),
            LocalizedEntry(
                id: "feat_npm_audit_signatures",
                title: "npm署名/provenance検証 (npm audit signatures, オプトイン, Pro)",
                summary: "npmレジストリと通信し、インストール済みパッケージの署名/provenanceを検証します。RoamSwitch内でnpmjs.comと通信する唯一の機能で、既定オフ・明示的なオプトインと実行ごとの確認が必要です。Pro版限定。",
                details: """
                • 有効化: 「📦 パッケージCVE照合」→「npm署名検証 (オプトイン) (Pro)」タブの「npm署名検証を有効化」。これは各プロジェクトフォルダの「監査を実行」ボタンを解禁するだけで、単独では何も送信しません。実行時も毎回「npmレジストリと通信しますか？」と確認します。
                • 実行内容: 対象フォルダをカレントディレクトリとして `npm audit signatures` を起動し、npmレジストリ(registry.npmjs.org)と通信します。RoamSwitch内でnpmjs.comと通信するのはこの機能だけです。
                • 出力: npmのコマンド出力をそのまま表示します（独自の解釈・断定はしません）。終了コードが0以外、または「invalid」「missing registry signature」等の文言を含む場合は参考情報として要注意の表示をします。
                • npmコマンドが見つからない場合はNode.js/npmのインストールを促すメッセージを表示します。
                • MCPツール: `run_npm_audit_signatures`（`directory`引数、Pro限定・オプトイン限定の二重ゲート）。
                """,
                recommendation: "本番デプロイ前の依存関係監査や、サプライチェーン侵害が疑われるインシデント調査時にのみ有効化してください。常時オンにする必要はありません。"
            ),
            LocalizedEntry(
                id: "feat_npm_sandboxed_install",
                title: "npm/pnpm installのサンドボックス実行 (roamswitch-npm, Pro)",
                summary: "preinstall/install/postinstall/prepareスクリプトの実行だけをネットワーク接続不可のサンドボックス (sandbox-exec) に封じ込める、実行代行型のコマンドラインラッパーです。単なる検知ではなく実際にインストールを代行します。Pro版限定。",
                details: """
                • 開き方: 「📦 パッケージCVE照合」→「サンドボックス実行 (npm/pnpm) (Pro)」タブの「インストール」ボタンで、コマンドラインラッパー `roamswitch-npm` を ~/Library/Application Support/RoamSwitch/bin/ に配置します。
                • 二段階フロー: ①ダウンロードフェーズは `npm install --ignore-scripts` / `pnpm install --ignore-scripts` を通常通りネットワーク接続ありで実行。②スクリプト実行フェーズは `npm rebuild` / `pnpm rebuild`（rootがprepareを宣言していれば `run prepare` も）を sandbox-exec の `(deny network-outbound)` プロファイル下で実行します。
                • サンドボックス方式: Linux版はbwrapによるファイルシステム制限を採用しますが、macOSには同等技術がないため、実機で動作検証済みのネットワーク遮断を採用しています（`(allow default)` + `(deny network-outbound)`）。ファイル読み書き・子プロセス起動は制限しません。
                • シェルエイリアス: `npm`/`pnpm` をラッパー経由にするエイリアス2行をシェル設定ファイルに追記できます（既存内容は変更せず末尾追記のみ、任意）。
                • プレビュー: 実行前にプロジェクトフォルダのライフサイクルスクリプト一覧（機能「インストールスクリプトの一覧」と同じスキャナ）を表示できます。
                • sandbox-execが利用できない場合や失敗した場合、サンドボックス無しへの暗黙フォールバックはしません。yarnは非対応です。GTK/MCPツールはありません（ターミナルから使うコマンドラインツール）。
                """,
                recommendation: "見慣れないパッケージを含むプロジェクトや、外部から取得したプロジェクトへの `npm install` は、通常のnpm/pnpmの代わりに `roamswitch-npm install` を使うことを推奨します。"
            ),
            LocalizedEntry(
                id: "feat_security_health_checker",
                title: "Macセキュリティ総合診断（18項目・スコア & 改善手順）",
                summary: "システム堅牢性・ネットワーク防御・認証とアクセス制御・ポート露出・マルウェア対策・物理デバイス防御の6分野18項目を検査し、100点満点のスコア・ランクと改善手順を表示します。無料版で利用できます。",
                details: """
                • システム堅牢性: 1. FileVault、2. SIP（システム完全性保護）、3. Gatekeeper、4. 自動セキュリティアップデート、5. Apple XProtect。
                • ネットワーク防御: 6. macOS ファイアウォール、7. ステルスモード、8. Wi-Fi 暗号化強度、9. ARP スプーフィング監視、10. ゲートウェイ ARP 固定。
                • 認証・アクセス制御: 11. SSH リモートログイン設定（rootログイン禁止・鍵認証必須か）、12. Sudo 権限昇格設定（`NOPASSWD` の監査）。
                • サービス・ポート露出: 13. 外部公開ポート。
                • マルウェア・ダウンロード保護: 14. Web・メール保護、15. DNS脅威保護、16. フィッシング・悪質リンク保護（Safariの詐欺Webサイト警告）。
                • 物理ポート・デバイス防御: 17. 不正USB / BadUSB 物理ポートガード、18. macOS アクセサリ接続保護（Apple シリコン）。
                • 対象外の扱い: 信頼ネットワークでのファイアウォール・ステルス、リモートログイン無効時のSSH、ヘルパー未接続時のSudo監査、Intel MacのアクセサリはN/Aとしてスコア計算から除外します。
                • ランク: 100点 = S、85〜99点 = A、70〜84点 = B、70点未満 = C。MCPツール `get_security_report` でも取得できます。
                """,
                recommendation: "定期的に「総合診断レポート」を開き、⚠️ の項目を改善手順に沿って対応して、ランクA以上を維持してください。"
            ),
            LocalizedEntry(
                id: "feat_autonomous_sentinel",
                title: "バックグラウンド自律巡回 & ClamAV定義自動更新・定期スキャン",
                summary: "4時間ごとにバックグラウンドで総合診断・ポート・USB・XProtectの状態を更新します（全プラン）。Pro版ではスコア低下の警告、ClamAVウイルス定義の自動更新、1日1回の定期ウイルススキャンも行います。",
                details: """
                • 定期診断（全プラン）: 起動から約30秒後と、その後4時間ごとに実行。同じネットワークに長時間いても最新の診断結果が保たれます。
                • スコア低下の警告（Pro）: スコアが80点未満、または4項目以上が不合格の場合に通知します。
                • ClamAV定義の自動更新（Pro）: `freshclam` を静かに実行します。
                • 定期スキャン（Pro）: 1日1回、`~/Downloads`・`~/Desktop`・`~/Library/LaunchAgents` をClamAVでスキャン。脅威は自動で隔離し、重大アラートを送ります。問題がなければ控えめな完了通知のみ。EICARテスト署名のみの場合は通知せず、通知履歴に記録します。
                """,
                recommendation: "Pro版をお使いの場合はClamAVを導入しておくと、定義更新と定期スキャンが自動で行われます。"
            ),
            LocalizedEntry(
                id: "feat_simulation_self_test",
                title: "シミュレーション（動作確認）機能",
                summary: "実際の攻撃やファイル破壊を起こさずに、ランサムウェア防護・マルウェア検知連動Air-Gap・Dockerリスク検知が正しく動作するかを安全にテストできます。",
                details: """
                • 開き方: メニュー「マルウェア対策 (XProtect & ClamAV)」の下部。
                • 🚨 ランサムウェア防護シミュレーション (動作確認)…: 暗号化の兆候を検知した場合と同じ手順で、Air-Gap隔離と緊急モーダルが動作するかをテスト。ファイルの破壊などは発生しません。
                • 🚨 マルウェア検知連動Air-Gapのシミュレーション (動作確認)…: XProtectが実際にマルウェアを検知した場合と同じ手順で、隔離と緊急モーダルをテスト。イベントには「[シミュレーション]」と明記されます。
                • ⚠️ Dockerリスク検知のシミュレーション (動作確認)…: 特権コンテナ検知時と同じ通知が届くかをテスト。Dockerへのアクセスは発生しません。
                • 注意: Air-Gap系のテストでは実際に一時的にネットワークが遮断されます。緊急モーダルから解除してください（解除しなくても最大10分で自動復旧）。
                • ダウンロード保護の確認には、無害なEICARテストファイルも使えます（通知は出ず、通知履歴に記録されます）。
                """,
                recommendation: "Proを有効化した直後や設定を変えた後に一度シミュレーションを実行し、通知とAir-Gapの動作を確認しておくと安心です。"
            ),
            LocalizedEntry(
                id: "feat_privileged_helper",
                title: "特権ヘルパーツール（RoamSwitchHelper・XPC）",
                summary: "PFファイアウォール・共有サービス・DNS・エアギャップなど、root権限が必要な操作だけを、特権分離されたLaunchDaemonヘルパーがXPC経由で実行します。",
                details: """
                • 特権分離: メインアプリは通常ユーザー権限で動作し、pfルールの変更・共有デーモンの制御・DNS設定・ARP固定・重要ファイルのハッシュ計算などだけを `RoamSwitchHelper` に委譲します。
                • 登録: macOS標準の SMAppService により、アプリ内に同梱されたLaunchDaemonとして登録されます。初回は「システム設定」→「一般」→「ログイン項目とApp機能拡張」での承認が必要です。アプリが「アプリケーション」フォルダにない場合は登録できません（faq_install_location）。
                • 付随するデーモン: エアギャップのフェイルセーフ（10分で自動解除）と起動時ゲート（最大90秒）を担う補助のLaunchDaemonも登録されます。
                • セキュリティ検証: XPC接続時にコード署名（Team ID）を検証し、不正なプロセスからの呼び出しを拒否します。
                """,
                recommendation: "初回起動時の案内に従ってヘルパーを承認してください。承認されていない場合、メニューに「⚠️ ヘルパーを承認する…」が表示されます。"
            ),
            LocalizedEntry(
                id: "feat_mcp_server",
                title: "MCPサーバー連携（AIアシスタントからの読み取り専用アクセス）",
                summary: "RoamSwitch.appには読み取り専用のMCP（Model Context Protocol）サーバーが同梱されており、ClaudeなどのAIアシスタントからMacのセキュリティ状況を問い合わせられます。設定変更や遮断などの操作系ツールは一切ありません。",
                details: """
                • 通信: ローカルの標準入出力（stdio）のみ。バイナリは `/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`。
                • 主なツール: `get_security_report`（総合診断）、`get_exposed_ports`、`get_guard_status`、`audit_url_safety`、`audit_secrets`、`audit_security_logs`、`get_quarantine_status`、`get_notification_history`、`get_canary_status`、`get_port_anomaly_incidents`、`get_runtime_threat_status`、`get_incident_timeline`（封じ込めインシデント履歴）、`get_network_history`（ネットワーク履歴学習）、`run_package_cve_scan`、`run_package_cve_scan_languages`、`run_active_vuln_scan`（127.0.0.1への非破壊プローブを送る唯一のツール）、`get_app_help`（このナレッジベース）。
                • リソース: `roamswitch://docs/features`、`roamswitch://docs/alerts-and-messages`、`roamswitch://docs/settings-guide`、`roamswitch://docs/troubleshooting`。
                • 言語: 回答はアプリの言語設定に従います。`get_app_help` は `language` 引数（ja / en / zh-Hans / zh-Hant / ko / de / fr / es / it / pt-PT）で言語を指定できます。
                • 安全設計: 読み取り専用のため、プロンプトインジェクションでAIに悪用されても保護レベルの変更やポート隔離などは実行できません。
                """,
                recommendation: "設定手順は faq_mcp_setup を参照してください。「このMacは今安全？」「この通知はどういう意味？」のように自然な言葉で質問できます。"
            ),
            LocalizedEntry(
                id: "feat_license_pro_tier",
                title: "Pro 永続ライセンス（買い切り・2台まで）",
                summary: "Pro版は買い切りの永続ライセンス（¥2,980 / $19.99）で、1ライセンスで2台のMacまで利用できます。Ed25519で電子署名されたライセンストークンを端末内で検証するため、認証後はオフラインでも動作します。",
                details: """
                • Proで利用できる機能: メニューで「(Pro)」が付いた自動防御（ランサムウェアおとりファイル検知、XProtect連動遮断、未知ポート自動遮断と開発サーバー隔離、ARPスプーフィング自動遮断、ゲートウェイARP/NDP固定、VPNトンネル、BadUSB / USBストレージガード、Web・メール保護、DNS脅威保護、リンク保護、Bluetooth自動オフ、ClickFix対策、自動起動登録の監視、Dockerリスク検知、重要ファイル改ざん監視、自動ログ監査）、リアルタイム脅威通知、自律巡回の警告・定期スキャン、ログのCSVエクスポートなど。
                • ライセンス種別: Pro 永続ライセンス（2台）、Team 永続ライセンス（5台）。
                • 認証: メニューの「💎 Pro版を認証 / 購入…」からライセンスキー（ROAM-XXXX-…）を入力。サーバーが発行した署名付きトークンをアプリ内の公開鍵で検証し、キーチェーンに保存します。
                • 端末の解除: 認証画面から解除すると、このMacのライセンスを削除し、サーバー上の利用枠を解放します（通信に失敗しても端末側の解除は必ず行われます）。
                • 失効時: Pro専用のガードは自動で無効化され、VPNトンネル・ポート隔離なども解除されます。
                """,
                recommendation: "自動隔離・リアルタイム防御・自律巡回の警告が必要な場合はProをご検討ください。買い替え時は旧Macでライセンスを解除してから新しいMacで認証してください。"
            ),
        ]
    }

    // MARK: - Alerts: network, devices, links

    private static func alertsJaNetwork() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "alert_arp_spoofing",
                title: "⚠️ ARPスプーフィング（中間者攻撃）の警告",
                summary: "同じネットワーク内で、ルーター（ゲートウェイ）になりすまして通信を盗聴・改ざんしようとする端末の兆候を検知した際の警告です。",
                details: """
                • 発生原因: 攻撃者が偽のARP応答を送り、あなたの通信を自分経由に誘導（中間者攻撃）。ゲートウェイのIPアドレスは同じまま、MACアドレスが急変したことで検知します。ルーターの再起動やメッシュWi-Fiの切替でも発生することがあります。
                • 自動防御: 最大ロックダウン中で「ARPスプーフィング（なりすまし通信）検知時に自動遮断 (Pro)」が有効なら、即座にエアギャップ隔離。それ以外のレベルでは通知のみで、メニューに「ARPスプーフィング検知 — 今すぐ全遮断する」が表示されます。
                """,
                recommendation: """
                1. このネットワークでのパスワード入力・決済・業務通信を直ちに中止してください。
                2. 公衆Wi-Fiなど心当たりのない環境であれば、メニューの「今すぐ全遮断する」を選ぶか、Wi-Fiを切断してください。
                3. インターネットが必要な場合は、テザリングやVPNトンネルなど安全な回線に切り替えてください。
                4. 自宅ルーターの再起動直後など誤検知と判明している場合のみ、そのまま利用を続けてください。
                """
            ),
            LocalizedEntry(
                id: "alert_evil_twin_ssid",
                title: "⚠️ なりすましの疑いがあるWi-Fiネットワークを検知",
                summary: "接続中のWi-Fiの名前（SSID）が、過去に接続したネットワークの名前と酷似している場合の警告です。悪意ある偽アクセスポイント（Evil Twin）の可能性があります。",
                details: """
                • 発生原因: 攻撃者が正規のネットワーク名を1〜2文字だけ変えた偽のアクセスポイントを設置し、利用者を誘い込む手口。ネットワーク履歴学習（feat_network_history_guard）が、過去に学習した名前との編集距離とゲートウェイ機器の違いから判定します。
                • 誤検知の抑制: 短い名前や、同じゲートウェイ機器が出している別名のSSIDでは警告しません。
                • 自動防御: 通知のみ。未登録ネットワークとして外出先デフォルト保護のレベルが適用されます。
                """,
                recommendation: """
                1. このWi-Fiではログインや個人情報の入力を行わないでください。
                2. 店舗やオフィスの掲示などで正規のネットワーク名を確認し、違う場合は切断してください。
                3. 利用を続ける必要がある場合は、VPNトンネルを接続してください。
                """
            ),
            LocalizedEntry(
                id: "alert_unencrypted_wifi",
                title: "⚠️ 暗号化されていないWi-Fiへの接続",
                summary: "パスワードや暗号化（WPA2 / WPA3）のないオープンWi-Fi、または古いWEP方式のネットワークに接続した際の警告です。",
                details: """
                • 発生原因: 無線区間が暗号化されていないため、周囲の誰でも通信を傍受できる状態です。
                • 自動防御: 未登録ネットワークであれば、外出先デフォルト保護（初期値: 最大ロックダウン）により受信と共有サービスが遮断されます。
                """,
                recommendation: """
                1. 可能であればVPNトンネルを接続するか、テザリングなど信頼できる回線に切り替えてください。
                2. HTTPSでないサイトでのログインや個人情報の入力は避けてください。
                3. メニューで保護レベルが最大ロックダウンになっていることを確認してください。
                """
            ),
            LocalizedEntry(
                id: "alert_port_anomaly",
                title: "🚨 未知のリスニングポートを自動遮断しました",
                summary: "これまで外部公開していなかったプログラムが、0.0.0.0でポートを外部LANに公開したことを検知し、外部からのアクセスを自動遮断した際の通知です（遮断に失敗した場合は「遮断に失敗」と表示）。",
                details: """
                • 発生原因: 開発サーバー（Next.js、Vite、Python、Docker）の起動、LocalSendやSyncthingなどLAN受信アプリの初回起動、またはバックドア・不正なアプリの待機開始。
                • 自動防御: pfで外部からのアクセスだけを遮断（Mac自身・localhostからは利用可能）。macOS標準のシステムデーモンは対象外です。
                """,
                recommendation: """
                1. 通知に表示されたプロセス名・PID・ポート番号に心当たりがあるか確認してください（メニュー「外部公開ポート」でも確認できます）。
                2. 自分で起動したサーバーやLAN受信アプリであれば、通知の「許可する」ボタンか、ポート診断画面から許可してください。以後は恒久的に許可されます。
                3. 開発サーバーは `127.0.0.1` にバインドして起動し直すのが安全です。
                4. 心当たりがなければ遮断したままプロセスを終了し、総合診断とウイルススキャンを実行してください。
                """
            ),
            LocalizedEntry(
                id: "alert_exposed_database",
                title: "🚨 未認証のデータベースサービスが外部公開されています",
                summary: "Redis・MongoDB・Memcached・Elasticsearchなど、既定で認証がないことが多いサービスが、ファイアウォールで保護されていない状態で外部LANに公開されていることを検知した際の警告です。",
                details: """
                • 発生原因: データベースやバックエンドサービスを 0.0.0.0 で起動し、かつ現在の保護レベルで受信が許可されている状態。同じネットワークの誰でもデータを読み書きできる可能性があります。
                • 自動防御: 通知（Pro）。同じポートについては繰り返し通知しません。
                """,
                recommendation: """
                1. サービスの設定で待ち受けアドレスを `127.0.0.1` に変更するか、認証を有効にしてください。
                2. すぐに対応できない場合は、メニュー「外部公開ポート」から対象ポートを開き「外部から隔離する」を実行してください。
                3. 公衆ネットワークでは保護レベルを最大ロックダウンにしてください。
                """
            ),
            LocalizedEntry(
                id: "alert_unapproved_keyboard",
                title: "⚠️ 未承認のキーボード / BadUSB接続を検知",
                summary: "許可リストにない新しいUSBキーボード（または改造USBケーブルなどキーボードを装うデバイス）が接続され、承認されるまでキー入力を遮断している際の通知と承認ウィンドウです。",
                details: """
                • 発生原因: 新しい外付けキーボードやドッキングステーションの接続、またはRubber Duckyなどのキー入力注入デバイスの接続。
                • 自動防御: そのデバイスのキー入力のみを遮断（他のキーボードは使えます）。「⚠️ 未知のUSBデバイス / キーボード接続検知」ウィンドウで承認を求めます。
                """,
                recommendation: """
                1. 自分で接続した信頼できるキーボードであれば「信頼して許可する」を押してください。許可リストに登録され、入力が有効になります。
                2. 心当たりがない場合、または何も接続していないのに表示された場合は「拒否して遮断を維持」を押し、デバイスを取り外してください。
                """
            ),
            LocalizedEntry(
                id: "alert_scripted_keyboard",
                title: "🚨 このキーボードは自動入力(スクリプト)の兆候を示しています",
                summary: "承認待ちのキーボードから、人間には不可能なほど速く均一な間隔でキー入力が送られたことを検知した際の警告です。自動スクリプトによるコマンド注入（BadUSB攻撃）の可能性が高い状態です。",
                details: """
                • 発生原因: Rubber Ducky、Flipper Zero、Arduino / Digisparkなどが、あらかじめ仕込まれたコマンドを高速に打ち込もうとした。キー入力タイミング解析（5回以上の入力で平均12ms以下、または平均45ms以下かつ均一）で判定します。
                • 自動防御: そのデバイスのキー入力は承認前からすでに遮断されており、Macには届いていません。この警告は判断材料を追加するものです。
                """,
                recommendation: """
                1. 承認ウィンドウで必ず「拒否して遮断を維持」を選んでください。
                2. デバイスを直ちに取り外し、出所を確認してください（拾ったUSBメモリ、もらったケーブルなど）。
                3. 念のため総合診断と自動起動登録の確認を行ってください。
                """
            ),
            LocalizedEntry(
                id: "alert_untrusted_usb",
                title: "🔒 USBストレージを読み取り専用でマウント / 🔌 不正USBストレージを自動遮断",
                summary: "許可リストにないUSBメモリや外部ストレージが接続され、安全のため読み取り専用でマウントして承認を求めている、または取り出した際の通知です。",
                details: """
                • 発生原因: 未登録のストレージデバイスの接続。データの不正な持ち出しや、悪意あるファイルの持ち込みを防ぎます。
                • 自動防御: 読み取り専用で再マウントし、「USBストレージ「…」を許可しますか？」ダイアログを表示。「取り出す」を選ぶと取り出して「不正USBストレージを自動遮断」と通知します。
                """,
                recommendation: """
                1. 自分のデバイスであれば「読み書きで許可」または「読み取り専用で許可」を選んでください。許可リストに登録され、次回から自動で適用されます。
                2. 心当たりがなければ「取り出す」を選んでください。
                3. 許可リストはメニュー「USB / BadUSBガード設定…」で後から変更できます。
                """
            ),
            LocalizedEntry(
                id: "alert_malware_usb",
                title: "🚨 USBストレージでマルウェアを検出",
                summary: "USBストレージを読み書きで接続する前のClamAVスキャンで、感染ファイルが見つかった際の警告です。",
                details: """
                • 発生原因: USBメモリ内に感染ファイルが存在。
                • 自動防御: 直ちにボリュームを取り出し、Mac本体への感染を防ぎます。
                """,
                recommendation: """
                1. そのUSBメモリは別の安全な環境で初期化するか、駆除してから使用してください。
                2. Mac本体に感染がないか、ClamAVのクイックスキャンまたはフォルダ指定スキャンを実行してください。
                """
            ),
            LocalizedEntry(
                id: "alert_link_guard_blocked",
                title: "🛑 リンク保護: 接続をブロックしました",
                summary: "詐欺・フィッシングの疑いがあるサイト（脅威フィード掲載、またはブランドのホモグラフ偽装）への接続を、リンク保護が自動ブロックした際の通知です。",
                details: """
                • 発生原因: メールやSNSのリンク、広告、アプリ内の通信などが、既知の詐欺ドメインに接続しようとした。
                • 自動防御: システム拡張が通信を破棄、またはhostsフォールバックでドメインを 0.0.0.0 に解決。ブラウザ・アプリを問いません。
                """,
                recommendation: """
                1. 心当たりがなければ何もする必要はありません。そのページで情報を入力しないでください。
                2. 業務で使う正規のサイトが誤って遮断された場合は、通知の「今回は許可 (5分)」で一時的に許可するか、許可リストに追加してください。
                """
            ),
            LocalizedEntry(
                id: "alert_link_guard_warn_hold",
                title: "⚠️ リンク保護: 接続を保留中",
                summary: "警告モードで、ブランド偽装・詐欺サイトの疑いがある宛先への接続を一時停止し、許可するかどうかを尋ねている際の通知と最前面パネルです。",
                details: """
                • 発生原因: 警告対象のドメイン（サブドメイン偽装・高リスクTLDなど）への接続。
                • 自動防御: 通信を一時停止して回答を待ちます。約8秒以内に回答がない場合は接続を遮断します（フェイルクローズ）。遮断結果はキャッシュしないため、次にアクセスした際に再度確認されます。回答した結果は記憶されます。
                """,
                recommendation: """
                1. 自分で開こうとした、信頼できるサイトであれば「許可する」を選んでください。
                2. 心当たりがない、または判断できない場合は「ブロックする」を選ぶか、そのまま待ってください（自動で遮断されます）。
                3. 誤って遮断された場合は、ページを再読み込みすると再度確認が表示されます。
                """
            ),
            LocalizedEntry(
                id: "alert_dangerous_url",
                title: "🛑 危険なリンク・フィッシング詐欺の疑い（リンク安全性診断）",
                summary: "リンク安全性診断（または `audit_url_safety`）で、ホモグラフ偽装・偽装サブドメイン・高リスクTLDなどを含む危険なURLと判定された際の表示です。",
                details: """
                • 判定項目: ホモグラフ文字（Punycode）、大手企業を装うサブドメイン、フィッシングで多用されるTLD、平文HTTP、IPアドレス直打ちなど。
                • スコア: 50点未満は「危険」、50〜79点は「注意」。
                """,
                recommendation: """
                1. 該当のリンクは開かないでください。
                2. メッセージを破棄し、必要に応じて社内のセキュリティ担当者に報告してください。
                """
            ),
            LocalizedEntry(
                id: "alert_helper_disconnected",
                title: "⚠️ ヘルパー未接続",
                summary: "特権ヘルパーツール（RoamSwitchHelper）とのXPC通信が確立できない場合の警告です。",
                details: """
                • 発生原因: 「ログイン項目とApp機能拡張」でバックグラウンド実行が承認されていない、macOSアップデート後にヘルパーが停止した、またはアプリが「アプリケーション」フォルダの外（ダウンロードフォルダやディスクイメージ内）にある。
                • 影響: 保護レベルの切替・エアギャップ隔離・DNS設定・重要ファイル監視など、root権限が必要な操作が行えません。
                """,
                recommendation: """
                1. メニューの「⚠️ ヘルパーを承認する…」を選ぶと、承認手順の画面が開きます。
                2. 「システム設定」→「一般」→「ログイン項目とApp機能拡張」の「バックグラウンドでの実行を許可」で RoamSwitchHelper をオンにしてください。
                3. RoamSwitchが「アプリケーション」フォルダにあるか確認してください。
                4. 改善しない場合は faq_helper_troubleshooting の手順を試してください。
                """
            ),
            LocalizedEntry(
                id: "alert_score_drop",
                title: "⚠️ Macセキュリティ低下の警告",
                summary: "自律巡回の定期診断で、セキュリティスコアが80点未満になった、または4項目以上が不合格になった際の通知です（Pro）。",
                details: """
                • 発生原因: FileVaultやファイアウォールの無効化、危険なポートの公開、ガードの停止など、設定や環境の変化。
                • 判定基準: スコア80点未満、または不合格の項目が4つ以上。
                """,
                recommendation: """
                1. メニューの「📊 総合診断レポートを開く…」（またはMCPの `get_security_report`）で内容を確認してください。
                2. ⚠️ が付いた項目を、表示される改善手順に沿って順番に対応してください。
                """
            ),
        ]
    }

    // MARK: - Alerts: malware, containment, audit

    private static func alertsJaMalware() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "alert_quarantined_download",
                title: "🚨 危険なダウンロードファイルを隔離しました",
                summary: "ブラウザ・メール・チャットアプリから保存されたファイルに脅威が検出され、検疫Vaultへ隔離した際の警告です（移動に失敗した場合は「隔離に失敗しました」と表示）。",
                details: """
                • 発生原因: ダウンロードしたファイルにマルウェア・トロイの木馬・リバースシェルなどが含まれていた。
                • 自動防御: `~/Library/Application Support/RoamSwitch/Quarantine/` に移動して実行できない状態にします。静的シグネチャで検知しClamAVでは一致しなかった場合は、誤検知の可能性がある旨を通知に記載します。
                """,
                recommendation: """
                1. 隔離に成功していれば、ファイルは実行できない状態です。
                2. 「📦 隔離ファイルを管理…」を開き、心当たりがなければ「完全に削除」してください。
                3. 誤検知が確実な場合のみ「元に戻す」または「除外して復元」を使ってください。
                4. 「隔離に失敗しました」の場合は、通知に表示されたパスのファイルを手動で削除してください。
                """
            ),
            LocalizedEntry(
                id: "alert_eicar_test_signature",
                title: "🧪 EICAR テスト署名を検出（無害）— 通知履歴のみに記録",
                summary: "ウイルス対策ソフトの動作確認用に使われる無害な EICAR テストファイルを検出した場合の扱いです。実際の脅威ではないため、通知バナーは出さず、隔離も遮断もせず、通知履歴にだけ記録します。",
                details: """
                • 対象: Web・メール保護、ClamAVのクイックスキャン / フォルダ指定スキャン、自律巡回の定期スキャンのいずれで検出した場合も同じ扱いです。
                • 挙動: ファイルはそのまま残ります。「🔔 通知履歴…」に「EICAR テスト署名を検出（無害）」として記録されます。
                • 理由: 脅威ではないものに警告バナーを出すと、本当に重要な警告が埋もれてしまうためです。
                """,
                recommendation: """
                1. 対応は不要です。テスト目的で置いたファイルであれば、確認後に削除してください。
                2. スキャンが正しく動作しているかは、通知履歴に記録があるかで確認できます。
                """
            ),
            LocalizedEntry(
                id: "alert_pickle_model",
                title: "⚠️ Pickle形式AIモデルのダウンロードを検知",
                summary: "`.pkl` / `.pickle` / `.pt` 形式のAIモデルファイルがダウンロードされた際の警告です。Pickle形式は読み込むだけで任意のコードを実行できるため注意が必要です。",
                details: """
                • 発生原因: HuggingFace・Civitaiなどからモデルファイルを保存した。
                • 自動防御: 警告のみ（ファイルは隔離しません）。
                """,
                recommendation: """
                1. 信頼できる公式の配布元のモデル以外は読み込まないでください。
                2. 可能であれば `.safetensors` または `.gguf` 形式の同じモデルを利用してください。
                """
            ),
            LocalizedEntry(
                id: "alert_ransomware_activity",
                title: "🚨【緊急自動防護発動】ランサムウェア活動を遮断しました",
                summary: "おとり（カナリア）ファイルの改ざん・削除・リネームを検知し、エアギャップ隔離・共有サービス停止・疑わしいプロセスの一時停止が発動した際の緊急通知とモーダルです。",
                details: """
                • 発生原因: ランサムウェアなど、ユーザーフォルダのファイルを暗号化・破壊しようとするプロセスの活動（またはシミュレーションの実行）。
                • 自動防御: 送受信の全遮断＋Wi-Fi無線オフ、SMB / SSH / 画面共有の停止、疑わしいプロセスの一時停止（SIGSTOP）。緊急モーダルに遮断の成否、疑わしいプロセス、影響を受けた可能性のあるファイルを表示します。
                """,
                recommendation: """
                1. 作業中のファイルを保存し、不審なアプリをすべて終了してください。
                2. アクティビティモニタでCPUやディスク書き込みが急増しているプロセスを確認し、心当たりがなければ強制終了してください。
                3. 影響を受けた可能性のあるファイルと、Time Machineなどのバックアップを確認してください。
                4. 安全を確認してから緊急モーダルで隔離を解除してください（ネットワーク復旧・停止プロセスの再開・おとりファイルの再生成が行われます）。
                """
            ),
            LocalizedEntry(
                id: "alert_runtime_threat_airgap",
                title: "🚨 XProtectがマルウェアを検知 — ネットワークを自動遮断",
                summary: "Apple純正の XProtect / XProtect Remediator がマルウェアを検知（有罪判定）し、XProtect連動の自動遮断によってエアギャップ隔離が発動した際の緊急モーダルと通知です。",
                details: """
                • 発生原因: ダウンロードや実行したファイルを、Appleのマルウェア検知エンジンが悪性と判定した。
                • 自動防御: 送受信の全遮断＋Wi-Fi無線オフ。解除しない場合も最大10分で自動復旧します。検知したプロセス・カテゴリ・Appleの検知メッセージが記録されます。
                """,
                recommendation: """
                1. 直前にダウンロード・実行したファイルやアプリを確認し、削除してください。
                2. ClamAVスキャンと総合診断を実行し、自動起動登録（LaunchAgent）に不審なものがないか確認してください。
                3. 安全を確認してから緊急モーダルで隔離を解除してください。
                4. 状態はMCPの `get_runtime_threat_status` でも確認できます。
                """
            ),
            LocalizedEntry(
                id: "alert_gatekeeper_block",
                title: "🛡️ Gatekeeperが未署名アプリの実行をブロックしました",
                summary: "macOSのGatekeeperが、署名や公証のないアプリの起動をブロックしたことを知らせる通知です。自動遮断は行いません。",
                details: """
                • 発生原因: インターネットから入手した未署名アプリや、自分でビルドした開発中のアプリを開こうとした。
                • 自動防御: なし（通知のみ）。XProtect連動の自動遮断は、XProtectが実際にマルウェアを検知した場合にだけ発動します。
                """,
                recommendation: """
                1. 自分でビルドしたアプリなど心当たりがあれば対応は不要です。
                2. 心当たりがない場合は、「ファイル・アプリの安全性診断…」で署名発行元を確認し、不審であれば削除してください。
                """
            ),
            LocalizedEntry(
                id: "alert_clickfix_command",
                title: "🚨 不審なコマンド実行を検知しました / ⚠️ クリップボードで不審なコマンドを検知しました",
                summary: "ClickFix手口に一致するコマンドを、Terminalで実行した（シェル履歴で検知）、またはクリップボードにコピーしたことを検知した際の警告です。",
                details: """
                • 発生原因: 偽のCAPTCHAや「修正するにはこのコマンドを実行してください」という偽エラー画面に誘導された。リバースシェルの定型コマンドや、Base64をデコードしてシェル / osascript に直接渡すパターンが対象です。
                • 自動防御（Terminal実行時・Pro・既定オフ）: エアギャップ隔離（Wi-Fi無線は切断しない、最大10分で自動復旧）。
                • 自動防御（コピー時・既定オン）: クリップボードの内容を即座に削除。
                """,
                recommendation: """
                1. コピーしただけの場合は、そのWebページを閉じてください。貼り付け・実行はしないでください。
                2. 実行してしまった場合は、Keychain・ブラウザに保存したパスワード・暗号資産ウォレットが安全か確認し、重要なパスワードを別の安全な端末から変更してください。
                3. 自動起動登録（LaunchAgent / Daemon）に不審なものがないか確認し、ClamAVスキャンを実行してください。
                """
            ),
            LocalizedEntry(
                id: "alert_new_persistence_item",
                title: "🚨 新しい自動起動登録を検知しました",
                summary: "新しい LaunchAgent / LaunchDaemon が登録され、その内容が不審（スクリプトインタプリタを直接起動する、署名が無効など）と判定された際の警告です。",
                details: """
                • 発生原因: 情報窃取マルウェアなどが再起動後も動き続けるために登録した、またはアプリのインストーラーが登録した。
                • 自動防御: 通知のみ（登録自体は止められません）。通知に登録ファイル（plist）のパスと判定理由を表示します。
                """,
                recommendation: """
                1. 直前に自分でアプリをインストールしたか確認してください。心当たりがあれば対応は不要です。
                2. 心当たりがなければ、通知に表示されたplistファイルを削除し、そのplistが起動するスクリプトやアプリも削除してください。
                3. 削除後にMacを再起動し、ClamAVスキャンを実行してください。
                """
            ),
            LocalizedEntry(
                id: "alert_docker_risk",
                title: "⚠️ リスクのあるDockerコンテナ設定を検知",
                summary: "`--privileged` で起動したコンテナ、または `docker.sock` をマウントしたコンテナが新しく起動したことを知らせる通知です。",
                details: """
                • 発生原因: 特権モードのコンテナやDockerソケットのマウントは、コンテナからホストを操作できるため、コンテナ脱出のリスクがあります。
                • 自動防御: なし（通知のみ）。
                """,
                recommendation: """
                1. 意図した設定（監視エージェントなど）であれば対応は不要です。
                2. 心当たりがなければ `docker ps` と `docker inspect` で該当コンテナを確認し、停止してください。
                """
            ),
            LocalizedEntry(
                id: "alert_critical_file_tampering",
                title: "🚨 重要システムファイルの改ざんを検知しました",
                summary: "sudoers・SSH設定・PAM・hosts・rootのauthorized_keysなど、重要ファイルの変更・削除・新規追加を検知した際の警告です。",
                details: """
                • 発生原因: 管理者による設定変更（`sudo visudo`、SSH設定の編集など）、ソフトウェアによる変更、または攻撃者による権限昇格・バックドア設置。
                • 自動防御: 通知のみ。変更後の状態を自動で正規とはみなしません。
                • 関連警告: 「重要システムファイルの改ざん検知が機能していません」は、特権ヘルパーに接続できずスキャンが続けて失敗していることを示します。
                """,
                recommendation: """
                1. 通知に表示されたファイルを、自分や管理者が変更したか確認してください。
                2. 心当たりがなければ、`/etc/sudoers` の `NOPASSWD` 設定や `authorized_keys` の未知の鍵などを確認し、削除してください。
                3. 管理者パスワードを変更し、総合診断を実行してください。
                """
            ),
            LocalizedEntry(
                id: "alert_log_audit_anomaly",
                title: "🔔 ログ監査: 異常パターンを検知",
                summary: "自動ログ監査で、このMacで初めて現れたログパターン（[新規]）や、普段より大きく増えたログ（[急増 z=…]）を検知した際の通知です。",
                details: """
                • 発生原因: 新しいデバイスの接続やアプリ・OSの更新に伴う想定内の変化が大半ですが、不審なログイン試行や未知のプロセスの活動の場合もあります。
                • 通知内容: 件数の内訳、実際のログ行の例（最大3件）、学習状況（例: 頻度学習中 2/3回観測）、平易な説明。
                • 自動防御: なし（通知のみ）。
                """,
                recommendation: """
                1. 新規パターンのみで、見覚えのないアプリ名やIPアドレスが含まれていなければ、対応は不要です。
                2. 頻度の急増が、自分が行っていない操作と重なる場合は、「📜 Macセキュリティログ監査…」で詳細を確認してください。
                3. 判断に迷う場合は「AIに相談する材料をコピー」を使ってAIアシスタントに相談できます。
                """
            ),
            LocalizedEntry(
                id: "alert_secret_in_clipboard",
                title: "🔑 クリップボードに機密キーを検知しました",
                summary: "OpenAI・Anthropic・GitHub・AWSなどのAPIキーや秘密鍵がクリップボードにコピーされていることを知らせる通知です。",
                details: """
                • 発生原因: APIキー・トークン・秘密鍵をコピーした。
                • 自動防御: 通知のみ（クリップボードは消去しません）。
                """,
                recommendation: """
                1. WebサイトやAIチャットに誤って貼り付けないよう注意してください。
                2. 使い終わったら別のテキストをコピーして上書きしてください。
                3. 誤って共有してしまった場合は、各サービスの管理画面でキーを直ちに失効・再発行してください。
                """
            ),
            LocalizedEntry(
                id: "alert_airgap_failed",
                title: "🚨 自動ネットワーク遮断に失敗しました",
                summary: "ランサムウェア・ARPスプーフィング・XProtect検知・ClickFixなどで緊急遮断を試みたものの、pfによる全遮断を適用できなかった際の緊急警告です。",
                details: """
                • 発生原因: 特権ヘルパーが応答しない（未承認・停止・タイムアウト）など。3回再試行しても失敗した場合に表示されます。
                • 現在の状態: 受信のみアプリケーションファイアウォールで遮断されている可能性がありますが、外部への送信は止まっていません。
                """,
                recommendation: """
                1. ただちにWi-Fiをオフにするか、LANケーブルを抜いてください。
                2. 脅威への対応（プロセスの終了・スキャン）を行ってください。
                3. その後、ヘルパーの状態を確認してください（faq_helper_troubleshooting）。
                """
            ),
        ]
    }

    // MARK: - Settings

    private static func settingsJa() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "set_trusted_networks",
                title: "登録済みネットワークの管理 & 保護レベルの個別設定",
                summary: "接続中のネットワークを「自宅」「職場」「テザリング」などとして登録し、ネットワークごとに保護レベル（信頼 / 標準保護 / 最大ロックダウン）を設定します。",
                details: """
                • 登録: メニュー「現在のネットワークを登録」→「「自宅」として登録 (信頼)」「「職場」として登録 (標準保護)」「「テザリング」として登録 (標準保護)」「カスタム名で登録…」。ゲートウェイのMACアドレスで識別します。
                • レベル変更: メニュー「現在のネットワーク: …」または「登録済みネットワーク (n)」から対象を選び、🟢 / 🟡 / 🔴 のレベルを選択。
                • 名前変更・削除: 「名称を変更…」「登録を解除」「登録を削除」。
                """,
                recommendation: "自宅は「🟢 信頼」、職場やテザリングは「🟡 標準保護」がおすすめです。共用のオフィスWi-Fiは登録せず、最大ロックダウンのまま使うのが安全です。"
            ),
            LocalizedEntry(
                id: "set_away_default_level",
                title: "外出先デフォルト保護（未登録ネットワークの保護レベル）",
                summary: "登録していないネットワークに接続したときに自動で適用される保護レベルを選びます。初期値は「🔴 最大ロックダウン」です。",
                details: """
                • 設定: メニュー「外出先デフォルト保護: …」から 🟢 信頼 / 🟡 標準保護 / 🔴 最大ロックダウン を選択。
                • 影響: DNS脅威保護（外出先のみ適用）、VPNトンネルの自動接続、ゲートウェイARP/NDP固定、Bluetooth自動オフなど、「未信頼ネットワーク」を条件とする機能の動作にも関わります。
                """,
                recommendation: "外出先で共有サービスやAirDropを使わないなら、最大ロックダウンのままにしておくことを強く推奨します。"
            ),
            LocalizedEntry(
                id: "set_manual_override",
                title: "手動オーバーライド & 戻し忘れ防止",
                summary: "一時的に保護レベルを手動で変えたいとき、期間を選んで指定できます。期間が過ぎる、またはネットワークが変わると自動判定に戻るため、戻し忘れを防げます。",
                details: """
                • 設定: メニュー「手動オーバーライド」→ レベル（🟢 / 🟡 / 🔴）→ 期間を選択。
                • 期間: 「次回ネットワーク切断まで（推奨）」「1時間だけ」「4時間だけ」「解除するまで継続」。
                • 解除: 「手動オーバーライド」→「自動判定に戻す」、またはメニュー上部の「🔄 手動指定を解除（自動判定に戻す）」。
                • エアギャップ隔離の解除時は、手動オーバーライドもクリアされます。
                """,
                recommendation: "発表や開発作業で一時的に保護を緩めるときは「次回ネットワーク切断まで」か「1時間だけ」を使い、外出先で無防備なままにならないようにしましょう。"
            ),
            LocalizedEntry(
                id: "set_pro_default_guards",
                title: "Pro有効化時に自動でオンになるガードと、オプトインのガード",
                summary: "Proライセンスを初めて有効化すると、主要な自律防御ガードが自動でオンになります。その後は各ガードでユーザーが選んだオン / オフが尊重されます。",
                details: """
                • 自動でオン（初回のPro有効化時に1回だけ）: 未知のリスニングポートを自動遮断、ランサムウェアおとりファイル検知、ARPスプーフィング検知時に自動遮断、XProtectのマルウェア検知時に自動でネットワーク遮断、自動ログ監査、重要システムファイルの改ざんを定期監視。ARPとXProtectの自動遮断がオンになった際は、その旨の案内を1度だけ表示します。
                • Proで既定オン: Web・メール保護、自動起動登録(LaunchAgent/Daemon)の監視。
                • 既定オフ（オプトイン）: ClickFix対策の自動遮断、Dockerリスク検知、BadUSB物理ポートガード、USBストレージ自動遮断、ゲートウェイARP/NDP固定、VPNトンネル、Bluetooth自動オフ、実証型脆弱性診断、DNS脅威保護のプロバイダー選択は任意。
                • 無料でも既定オン: クリップボード保護（APIキー・ClickFixコマンド）。
                • 後から追加されたガードも、既存のProユーザーに対して各ガードごとに1回だけ既定値が適用されます。ライセンスが失効するとPro専用ガードは無効化されます。
                """,
                recommendation: "Pro有効化後はメニューの ✅ 表示を確認し、使い方に合わないガード（例: Dockerを使わない）はそのまま、必要なもの（例: 公衆Wi-Fiが多いならVPN）を追加で有効にしてください。"
            ),
            LocalizedEntry(
                id: "set_usb_whitelist",
                title: "USB / BadUSBガード設定（キーボード許可リスト & ストレージの権限） (Pro)",
                summary: "信頼できるキーボードと、業務で使うUSBストレージを許可リストで管理し、ストレージには「読み取り専用」または「読み書き両方」の権限を設定します。",
                details: """
                • 開き方: メニュー「ポート・デバイス監視」→「USB / BadUSBガード設定…」。
                • キーボード: 承認ウィンドウで「信頼して許可する」を選ぶと登録されます。設定画面から削除できます。
                • ストレージ: 接続時のダイアログで「読み書きで許可」「読み取り専用で許可」を選ぶと登録。設定画面で権限の変更や削除ができます。接続していない間に変更した場合は、一度抜いて挿し直すと反映されます。
                • 接続時のClamAVスキャンは、許可済みデバイスでも読み書きで接続する前に実行されます。
                """,
                recommendation: "機密データを扱うMacでは、登録するストレージを「読み取り専用」にしておくと情報漏洩のリスクを大きく下げられます。"
            ),
            LocalizedEntry(
                id: "set_watched_folders",
                title: "Web・メール保護の監視対象フォルダ (Pro)",
                summary: "ダウンロード保護（FSEvents監視と自動スキャン）の対象フォルダを追加・削除・初期化できます。",
                details: """
                • 既定の監視フォルダ: `~/Downloads`、`~/Desktop`、`~/Documents`、メールのダウンロードフォルダ。
                • 編集: メニュー「Web・メール保護 (ダウンロード自動スキャン) (Pro)」→「📁 監視対象フォルダ」→「⚙️ 監視対象フォルダを編集…」。
                • 初期化: 「🔄 デフォルトに戻す」。
                • 直近のスキャン履歴（最大5件表示）と「スキャン履歴を消去」も同じメニューにあります。
                """,
                recommendation: "ブラウザやチャットアプリの保存先を独自のフォルダに変更している場合は、必ず監視対象に追加してください。"
            ),
            LocalizedEntry(
                id: "set_dns_policy",
                title: "DNS脅威保護のプロバイダーと適用ポリシー (Pro)",
                summary: "悪質ドメインを遮断するセキュアDNSのプロバイダーと、適用するタイミング（外出先のみ / 常時）を設定します。",
                details: """
                • 設定: メニュー「DNS脅威保護 (悪質サイト・C2遮断) (Pro)」→「プロバイダー: …」「⚙️ 適用ポリシー」。
                • プロバイダー: Quad9 (マルウェア・C2自動遮断) / Cloudflare Security (1.1.1.2) / AdGuard DNS (脅威・広告ブロック) / CleanBrowsing (セキュリティフィルター)。
                • 適用ポリシー: 「外出先・未信頼Wi-Fiのみ適用（推奨）」または「すべてのネットワークで常時適用 (保護環境含む)」。外出先のみの場合、信頼ネットワークでは元のDNS設定に戻します。
                • 適用状況はメニュー内の表示から「ネットワーク設定」を開いて確認できます。
                """,
                recommendation: "一般的な利用では Quad9 と「外出先・未信頼Wi-Fiのみ適用」の組み合わせがおすすめです。社内DNSが必要な環境では常時適用を避けてください。"
            ),
            LocalizedEntry(
                id: "set_link_guard_modes",
                title: "リンク保護のモード・自動更新・システム拡張・許可リスト (Pro)",
                summary: "リンク保護の動作モード、脅威フィードの自動更新、システム拡張の承認状態、誤遮断時の許可を設定します。",
                details: """
                • モード: メニュー「リンク保護 (フィッシング接続の検知) (Pro)」で「オフ」「警告のみ (遮断しない)」「明らかな詐欺サイトは自動でブロック (推奨)」を選択。警告モードはシステム拡張が有効な場合のみ機能します。
                • 自動更新: 「自動更新: オン (受信のみ)」をクリックでオフに切替。オフでも同梱データとホモグラフ検知で動作します。フィードのバージョンと件数はメニューに表示されます。
                • 強制ポイントの表示: 「強制ポイント: システム拡張 (DoH 対応)」「強制ポイント: hosts フォールバック」「システム拡張を有効化中…」「システム拡張エラー」。承認待ちの場合は「システム拡張を承認 (システム設定を開く)…」が表示されます。
                • 許可・ブロック: ブロック通知の「今回は許可 (5分)」で5分間だけ許可。警告パネルの「許可する」「ブロックする」は記憶されます。
                """,
                recommendation: "システム拡張を承認し、「自動ブロック」＋「自動更新: オン」で使うのが最も効果的です。"
            ),
            LocalizedEntry(
                id: "set_vpn_backend",
                title: "VPNトンネルのバックエンド設定（WireGuard / Tailscale） (Pro)",
                summary: "VPNトンネルのバックエンドを選び、WireGuardの設定ファイル読み込み、TailscaleのExit Node選択、キルスイッチを設定します。",
                details: """
                • 開き方: メニュー「ポート・デバイス監視」→「VPNトンネル (未信頼ネットワークでのMITM対策) (Pro)」→「バックエンド」。
                • WireGuard: 「WireGuard設定(.conf)を読み込む…」→「未信頼ネットワークで自動接続する」。「今すぐ接続」「切断」「設定を削除」。状態は「🟢 接続中 (最終ハンドシェイク n秒前)」などで表示され、キルスイッチは常に有効です。`wireguard-tools` が未導入の場合は導入案内が表示されます。
                • Tailscale: 「Exit Node」から出口ノードを選択（「(なし — 保護オフ)」で無効）。「候補を更新」「状態を更新」。「キルスイッチ: オン (漏れ防止)」は任意で、既定オフ。
                • 状態表示の例: 「⚪️ 待機中 (未信頼ネットワークで自動接続)」「🟡 選択した Exit Node がオフライン」。
                """,
                recommendation: "既にTailscaleを使っている場合はTailscale、そうでなければVPNプロバイダーのWireGuard設定を使うのが手軽です。"
            ),
            LocalizedEntry(
                id: "set_language",
                title: "表示言語の設定（アプリとMCPの回答言語）",
                summary: "RoamSwitchの表示言語を10言語（日本語・English・简体中文・繁體中文・한국어・Deutsch・Français・Español・Italiano・Português）から選べます。MCPサーバーの回答やこのナレッジベースも同じ言語で返されます。",
                details: """
                • 設定: メニュー「言語 / Language」から選択。「システム設定に従う」を選ぶとmacOSの優先言語を使用します。
                • MCP: MCPサーバーはアプリで選んだ言語を読み取ります。システム設定に従う場合で、対応していない言語のときは英語で回答します。
                • `get_app_help` ツールは `language` 引数で回答言語を個別に指定できます。検索はどの言語のキーワードでも行えます。
                """,
                recommendation: "AIアシスタントと別の言語でやり取りしたい場合は、`get_app_help` の `language` 引数を使ってください。"
            ),
        ]
    }

    // MARK: - Troubleshooting: setup

    private static func troubleshootingJaSetup() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "faq_free_vs_pro",
                title: "無料版とPro永続版の違い",
                summary: "無料版でもネットワークに応じた自動保護切替や18項目の総合診断など、基本的な防御と各種の手動診断ツールを無期限で利用できます。Pro版では自動隔離・リアルタイム防御・自律巡回の警告などがアンロックされます。",
                details: """
                【無料版】
                • Wi-Fi・ネットワークに応じたpfパケットフィルタの3段階自動切替、共有サービス・AirDropの自動停止と復元
                • Macセキュリティ総合診断（18項目）、XProtect稼働確認とファイル・アプリの安全性診断
                • 外部公開ポート・USBデバイスの一覧表示
                • リンク安全性診断、機密情報・APIキー漏洩の手動監査、クリップボード保護
                • パッケージCVE照合、実証型脆弱性診断、Macセキュリティログ監査、通知履歴
                • ClamAVの手動スキャンと隔離ファイルの管理
                • MCPサーバー連携
                【Pro 永続版（買い切り ¥2,980 / $19.99・2台まで）】
                • ランサムウェアおとりファイル検知＆エアギャップ隔離、XProtect連動の自動遮断、ClickFix対策
                • 未知のリスニングポート自動遮断、開発サーバーの外部隔離
                • ARPスプーフィング自動遮断、ゲートウェイARP/NDP固定、VPNトンネル（WireGuard / Tailscale）、Evil Twin警告
                • BadUSBキーボードガード、USBストレージ自動遮断
                • Web・メール保護（自動スキャン・隔離・Pickle警告）、DNS脅威保護、リンク保護
                • 自動起動登録の監視、Dockerリスク検知、重要ファイル改ざん監視、自動ログ監査
                • Bluetooth自動オフ、リアルタイム脅威通知、自律巡回の警告・定義更新・定期スキャン、ログのCSVエクスポート
                """,
                recommendation: "自動隔離やリアルタイム防御、バックグラウンドでの監視が必要な場合はPro版をお選びください。"
            ),
            LocalizedEntry(
                id: "faq_homebrew_clamav",
                title: "ClamAV（ウイルス検査）のセットアップとHomebrew",
                summary: "ウイルススキャン機能はオープンソースの「ClamAV」を使います。Homebrewで導入でき、未導入でもXProtect連携やRoamSwitch本体の機能はすべて動作します。",
                details: """
                • Homebrew: macOS用のパッケージ管理ツール（https://brew.sh/）。
                • 導入手順:
                  1. ターミナルで Homebrew の公式インストールコマンドを実行（https://brew.sh/ に記載）。
                  2. `brew install clamav` を実行。メニューの「📥 ClamAVをHomebrewで導入…」からも案内を開けます。
                  3. メニュー「🛡️ ClamAV (無料アンチウイルス)」→「🔄 ウイルス定義を今すぐ更新」を実行。
                • 導入後に使える機能: クイックスキャン（ダウンロード / デスクトップ）、フォルダを指定してスキャン、Web・メール保護とUSBストレージのスキャン、自律巡回の定期スキャン。
                • ClamAVなしでも: パケットフィルタ・ポート監視・リンク診断・静的シグネチャ検査などは動作します。
                """,
                recommendation: "ダウンロードファイルやUSBストレージを自動スキャンしたい場合は、HomebrewとClamAVの導入をおすすめします。"
            ),
            LocalizedEntry(
                id: "faq_blueutil_setup",
                title: "Bluetooth自動オフ (Pro) と blueutil のセットアップ",
                summary: "外出先でBluetoothを自動でオフにする機能には、オープンソースツール `blueutil` の導入が必要です。",
                details: """
                • 背景: macOSにはアプリからBluetoothの電源を切り替える公開APIがないため、CLIツール `blueutil` を使います。
                • 導入手順:
                  1. ターミナルで `brew install blueutil` を実行（メニューの「📥 blueutilをHomebrewで導入…」からも可能）。
                  2. メニュー「ポート・デバイス監視」→「未信頼ネットワークでBluetoothを自動オフ (Pro)」を有効化。
                • 未導入の場合: 他の機能には影響しません。メニューに「🔵 Bluetooth自動オフ (未導入)」と表示されます。
                """,
                recommendation: "公衆Wi-Fiでの電波追跡やBluetoothの脆弱性を避けたい場合は、`brew install blueutil` を実行して有効化してください。"
            ),
            LocalizedEntry(
                id: "faq_helper_troubleshooting",
                title: "「⚠️ ヘルパー未接続」と表示される場合の対処法",
                summary: "特権ヘルパーツール（RoamSwitchHelper）との通信ができないときの復旧手順です。",
                details: """
                1. メニューの「⚠️ ヘルパーを承認する…」を選び、表示される手順に従って承認してください。
                2. 「システム設定」→「一般」→「ログイン項目とApp機能拡張」を開き、「バックグラウンドでの実行を許可」の一覧で RoamSwitchHelper がオンになっているか確認してください。
                3. RoamSwitchが「アプリケーション」フォルダにあるか確認してください（faq_install_location）。
                4. オンボーディング画面の「ヘルパーの登録を再試行」を押してください。
                5. それでも改善しない場合は、ターミナルで `sudo killall RoamSwitchHelper` を実行してヘルパーを再起動し（launchdが自動で起動し直します）、RoamSwitchを再起動してください。
                """,
                recommendation: "macOSのアップデート直後にヘルパーが応答しなくなった場合は、まずログイン項目のトグルを確認し、次に `sudo killall RoamSwitchHelper` を試してください。"
            ),
            LocalizedEntry(
                id: "faq_install_location",
                title: "アプリの設置場所（「アプリケーション」フォルダ以外で起動した場合）",
                summary: "macOSは「アプリケーション」フォルダ以外にあるアプリの特権ヘルパーを登録させないため、RoamSwitchは `/Applications` または `~/Applications` に置いて起動する必要があります。",
                details: """
                • 登録できない場所: ダウンロードフォルダやデスクトップ、ディスクイメージ（.dmg）をマウントしたままの状態、Gatekeeperの「App Translocation」で一時的な読み取り専用領域に移された状態。
                • 自動案内: 起動時のオンボーディングが設置場所を確認し、「「アプリケーション」に移動して再起動」または「Finder で「アプリケーション」を開く」を案内します。
                • 移動後: 「確認しなおす」を押すか、アプリを再起動してからヘルパーを承認してください。
                """,
                recommendation: "ディスクイメージからRoamSwitchを「アプリケーション」フォルダにドラッグし、そこから起動してください。"
            ),
            LocalizedEntry(
                id: "faq_system_extension_approval",
                title: "リンク保護のシステム拡張を承認する方法",
                summary: "リンク保護の最適な動作（DoH対応・警告モード）には、コンテンツフィルタのシステム拡張の承認が必要です。承認前は /etc/hosts フォールバックで動作します。",
                details: """
                • 承認手順: メニュー「リンク保護 (フィッシング接続の検知) (Pro)」→「システム拡張を承認 (システム設定を開く)…」→「システム設定」→「一般」→「ログイン項目とApp機能拡張」で RoamSwitch のネットワーク拡張を許可。
                • 承認後: メニューの表示が「強制ポイント: システム拡張 (DoH 対応)」に変わります。
                • 「システム拡張エラー」と表示される場合: アプリが「アプリケーション」フォルダにあるか確認し、リンク保護のモードを一度選び直すと再試行します。
                • Appleの審査やエンタイトルメントの申請は不要な方式（Developer ID署名・公証済み）です。
                """,
                recommendation: "ブラウザがDNS over HTTPSを使っている場合でも確実に保護するため、システム拡張の承認をおすすめします。"
            ),
            LocalizedEntry(
                id: "faq_mcp_setup",
                title: "MCPサーバーの設定方法（Claude Desktop / Claude Code など）",
                summary: "RoamSwitchに同梱されたMCPサーバーを、MCP対応のAIクライアントに登録する方法です。",
                details: """
                • バイナリパス: `/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`
                • Claude Desktop: `~/Library/Application Support/Claude/claude_desktop_config.json` の `mcpServers` に、`command` としてバイナリパスを追加。
                • Claude Code: `claude mcp add roamswitch /Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`
                • その他のクライアント（Codex CLI など）の手順: https://lafine.net/mcp-setup.html
                • 回答言語: アプリの「言語 / Language」の設定に従います。`get_app_help` は `language` 引数で個別に指定できます。
                • 通信はローカルのstdioのみで、外部送信はありません（`run_active_vuln_scan` のみ127.0.0.1への非破壊プローブを送信）。
                """,
                recommendation: "登録後、AIに「RoamSwitchで今のMacのセキュリティ状態を確認して」と頼むと、総合診断の結果を解説してもらえます。"
            ),
        ]
    }

    // MARK: - Troubleshooting: operation

    private static func troubleshootingJaOperation() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "faq_network_cut_off",
                title: "突然インターネットにつながらなくなった（エアギャップ隔離・保護レベル）",
                summary: "RoamSwitchの緊急エアギャップ隔離や最大ロックダウンで通信が止まっている可能性があります。原因の確認方法と解除手順です。",
                details: """
                • 確認: 緊急モーダルが表示されていないか、通知履歴に「緊急自動防護発動」「XProtect」「ARPスプーフィング」「不審なコマンド実行」などの通知がないか確認してください。Wi-Fi無線がオフになっている場合もあります。
                • 解除: 緊急モーダルの解除ボタン、または通知から解除してください。通信とWi-Fi無線が復旧します。
                • 自動復旧: 解除しなくても、ヘルパーのフェイルセーフにより最大10分で自動的に復旧します。アプリの終了・クラッシュ・Macの再起動でも手動操作は不要です。
                • 起動直後: Mac起動直後は最大90秒間、起動時ゲートで通信が制限されることがあります。
                • 隔離以外の原因: 最大ロックダウンは受信を遮断しますが、通常の送信（Web閲覧など）は妨げません。VPNのキルスイッチ（トンネル切断中）、DNS脅威保護のDNS、リンク保護による遮断も確認してください。
                """,
                recommendation: "隔離が発動した場合は、原因となった通知を確認し、安全を確かめてから解除してください。頻繁に誤発動する場合は、該当ガードをメニューから個別にオフにできます。"
            ),
            LocalizedEntry(
                id: "faq_quarantine_false_positive",
                title: "ダウンロードファイルが誤検知で隔離された場合の復元手順",
                summary: "自作のスクリプトや開発用バイナリが誤検知で隔離された場合の、復元とスキャン除外の手順です。",
                details: """
                1. メニュー「マルウェア対策」→ ClamAV →「📦 隔離ファイルを管理…」を開きます。
                2. 隔離中のファイルから対象を選びます（元のパス・脅威名・隔離日時が表示されます）。
                3. 誤検知が確実な場合は「除外して復元」を押します。元の場所に戻り、そのパスは今後のスキャン対象から外れます。一度だけ戻す場合は「元に戻す」。
                4. 除外を取り消すには、同じ画面の「スキャン対象から除外中のパス」で「除外を解除」を押します。
                5. フォルダ単位で監視を外したい場合は、Web・メール保護の「⚙️ 監視対象フォルダを編集…」で調整します。
                """,
                recommendation: "本当に安全か判断できないファイルは復元せず、「完全に削除」してください。"
            ),
            LocalizedEntry(
                id: "faq_eicar_test",
                title: "EICARテストファイルを置いたのに通知が来ない",
                summary: "仕様です。EICARテスト署名は無害なテスト用のため、通知バナーは出さず、隔離もしません。検出の記録は通知履歴に残ります。",
                details: """
                • 確認方法: メニュー「Macセキュリティ総合診断」→「🔔 通知履歴…」に「🧪 EICAR テスト署名を検出（無害）」が記録されているか確認してください。
                • ファイルの扱い: 元の場所にそのまま残ります。
                • 実際の警告経路を確認したい場合: メニュー下部の「ランサムウェア防護シミュレーション」「マルウェア検知連動Air-Gapのシミュレーション」「Dockerリスク検知のシミュレーション」を使ってください。
                """,
                recommendation: "テストが終わったらEICARファイルは削除してください。"
            ),
            LocalizedEntry(
                id: "faq_dev_server_blocked",
                title: "自分の開発サーバーやLAN受信アプリが外部からつながらない",
                summary: "未知のリスニングポート自動遮断が、新しく外部公開を始めたプログラムを遮断している可能性があります。Mac自身からは引き続きアクセスできます。",
                details: """
                • 確認: 通知履歴に「🚨 未知のリスニングポートを自動遮断しました」が記録されていないか確認してください。
                • 許可: 通知の「許可する」ボタン、またはメニュー「外部公開ポート」→ 対象ポート → ポート診断画面から許可します。許可は実行ファイル単位で恒久的に有効です。
                • 手動隔離との違い: 「外部から隔離する」で自分で隔離したポートは、ポート診断画面の「隔離を解除」で戻します。
                • 保護レベル: 最大ロックダウンのネットワークでは、ファイアウォールが受信自体を遮断します。LAN内からアクセスさせたい場合は、そのネットワークを登録して標準保護または信頼に設定してください。
                """,
                recommendation: "LocalSend・Syncthingなど常用するLAN受信アプリは一度許可しておけば、以後は遮断されません。"
            ),
            LocalizedEntry(
                id: "faq_link_guard_false_block",
                title: "リンク保護で正規のサイトがブロックされる / 接続が保留される",
                summary: "リンク保護が誤ってサイトを遮断した、または警告モードで保留された場合の対処法です。",
                details: """
                • 一時的に許可: ブロック通知の「今回は許可 (5分)」。
                • 恒久的に許可: 警告パネルで「許可する」を選ぶと記憶されます。
                • 保留が勝手に遮断された: 警告モードは約8秒以内に回答がないと遮断します（フェイルクローズ）。遮断結果はキャッシュしないため、ページを再読み込みすると再度確認が表示されます。
                • 通知が見えない: macOSの通知スタイルがバナーだとボタンが隠れることがあるため、最前面のパネルも表示されます。集中モード中などは通知履歴を確認してください。
                • 一時的に無効化: モードを「警告のみ (遮断しない)」または「オフ」に変更。
                """,
                recommendation: "業務ツールが繰り返しブロックされる場合は、ドメイン名に誤りやタイポがないか確認した上で許可してください。"
            ),
            LocalizedEntry(
                id: "faq_keyboard_blocked",
                title: "外付けキーボードが入力できない（BadUSBガード）",
                summary: "BadUSB物理ポートガードが、許可リストにないキーボードの入力を承認待ちとして遮断しています。",
                details: """
                • 承認: 表示されている「⚠️ 未知のUSBデバイス / キーボード接続検知」ウィンドウで「信頼して許可する」を押してください（内蔵キーボードやトラックパッドで操作できます）。
                • ウィンドウが見当たらない: デバイスを一度抜いて挿し直すと再表示されます。
                • ドッキングステーションやKVM: キーボード機能を内蔵している機器も対象になります。自分の機器であれば許可してください。
                • アクセシビリティ権限: デバイスの占有に失敗した場合の代替遮断にはアクセシビリティ権限を使います。
                • 許可の取り消し: 「USB / BadUSBガード設定…」から削除できます。
                """,
                recommendation: "「自動入力(スクリプト)の兆候」の警告が出たデバイスは許可せず、取り外してください。"
            ),
            LocalizedEntry(
                id: "faq_vpn_troubleshooting",
                title: "VPNトンネルが接続されない / 通信できない",
                summary: "WireGuard・TailscaleバックエンドのVPNトンネルがうまく動作しない場合の確認事項です。",
                details: """
                • WireGuard: `brew install wireguard-tools` を導入済みか、`.conf` を読み込んだか確認。「🟡 応答なし (最終ハンドシェイク n秒前)」の場合はVPNサーバー側や設定ファイルの鍵・エンドポイントを確認してください。キルスイッチが有効なため、トンネルが確立するまで通信できません。
                • Tailscale: CLI版を導入してログイン済みか（「※ Tailscale にログインしてください」の表示）、Exit Nodeを選んだか確認。「🟡 選択した Exit Node がオフライン」の場合は別のノードを選んでください。
                • App Store版Tailscale: アプリ外から Exit Node を設定できないため、Tailscaleアプリ側でExit Nodeを選んでください。
                • Tailscaleのキルスイッチ: 環境によってはTailscale自身の接続を妨げるため、つながらない場合はオフにしてください。
                • 信頼済みネットワークでは自動で切断されるのが正常な動作です。
                """,
                recommendation: "まずメニューの状態表示を確認し、WireGuardならハンドシェイク、TailscaleならExit Nodeの状態を見てください。"
            ),
            LocalizedEntry(
                id: "faq_log_audit_repeated_alerts",
                title: "ログ監査の通知が何度も来る",
                summary: "自動ログ監査は、このMacの普段のログ傾向を学習しながら動作します。導入直後や大きな更新の後は通知が増えますが、学習が進むと自然に減ります。",
                details: """
                • 新規パターン: 一度通知したパターンは「既知」になり、同じ内容で再通知されません。
                • 頻度の急増: パターンごとに3回の観測で学習が完了し、以後は普段どおりの量なら通知しません。通知に「頻度学習中: 2/3回観測」などと表示されている間は学習中です。
                • よくある原因: macOS・アプリのアップデート、新しいデバイスの接続、一時的な高負荷。
                • 止めたい場合: メニュー「自動ログ監査(新規パターン・頻度異常を定期学習) (Pro)」をオフにしてください（手動のログ監査は引き続き使えます）。
                """,
                recommendation: "見覚えのないアプリ名・IPアドレス・sudoの失敗が含まれていない限り、しばらく様子を見て構いません。"
            ),
            LocalizedEntry(
                id: "faq_zero_telemetry",
                title: "Zero Telemetry（外部送信ゼロ）のプライバシー設計",
                summary: "RoamSwitchとMCPサーバーは、診断結果・URL・ポート情報・ログ・ファイル内容を外部サーバーに送信しません。通信するのは、以下の明示的な例外だけです。",
                details: """
                • 完全ローカル: 総合診断、ポート監視、リンク診断、機密情報監査、ログ監査、ウイルス検査、MCP通信はすべて端末内で完結します。
                • 通信の例外:
                  - ライセンスの認証・解除（ユーザーの操作時のみ）と、購入ページを開く操作
                  - アプリのアップデート確認（Sparkle）
                  - ClamAVウイルス定義の更新（`freshclam`）
                  - リンク保護の脅威フィード、パッケージCVEマップ、脆弱性CVEマップの1日1回の取得（受信専用・署名検証・識別子の送信なし。リンク保護の自動更新はオフにできます）
                  - ユーザーが設定したVPN・セキュアDNSプロバイダーへの通常の通信
                  - 実証型脆弱性診断の、127.0.0.1（このMac自身）への非破壊プローブ
                • テレメトリや利用状況の収集はコード内に存在しません。ヘルパー未承認のリマインダーなども端末内のカウントだけで実現しています。
                """,
                recommendation: "機密性の高い業務環境や個人の開発環境でも、情報流出を心配せずに利用できます。"
            ),
        ]
    }
}
