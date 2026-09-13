# roamswitch-mcp

[English](README.md) | **日本語**

[![CI](https://github.com/lafine1211/roamswitch-mcp/actions/workflows/ci.yml/badge.svg)](https://github.com/lafine1211/roamswitch-mcp/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

[RoamSwitch](https://lafine.net)（Mac のネットワーク境界を自動防衛するメニューバーアプリ）に
同梱されている **読み取り専用の [MCP](https://modelcontextprotocol.io) サーバーと、その検知
ロジック本体** です。RoamSwitch が何を計算し、AI クライアントへ何を渡しているのかを、誰でも
そのまま読んで検証できるように公開しています。

このリポジトリは RoamSwitch アプリ内の該当ソースの **検証可能なミラー** です。アプリ本体では
ありません。特権ヘルパー、パケットフィルタ（`pf`）制御、実際に通信を遮断するガード、ライセンス
・決済コード、UI はいずれも含みません。含まれるのは *観測するコード* と *stdio で質問に答える
コード* だけです。

## 収録内容

| 領域 | ファイル |
| --- | --- |
| MCP stdio サーバー（自前実装の JSON-RPC 2.0） | `main.swift`, `MCPProtocol.swift`, `MCPServer.swift`, `MCPResponseFormatting.swift` |
| ネットワーク信頼判定 / ゲートウェイ・フィンガープリント | `TrustedNetwork.swift`, `GatewayFingerprint.swift` |
| ARP スプーフィング検知 | `ARPSpoofMonitor.swift` |
| リスニングポート列挙・監査 | `ListeningPortMonitor.swift`, `PortSecurityAuditor.swift`, `ServiceSignatures.swift` |
| Wi-Fi 暗号化強度の判定 | `WiFiSecurityMonitor.swift` |
| macOS セキュリティ 18 項目診断 | `SecurityHealthChecker.swift` |
| フィッシング / ホモグラフ / URL 安全性（完全オフライン） | `LinkSafetyAuditor.swift` |
| APIキー・シークレット漏洩検査（完全オフライン） | `SecretLeakScanning.swift` |
| 統合ログのセキュリティ監査＋ログテンプレート異常検知 | `SecurityLogAuditor.swift`, `LogTemplateAnalyzer.swift` |
| 実証型脆弱性検証（`127.0.0.1` 限定・オプトイン） | `ActiveVulnScan.swift`, `ActiveVulnCveMapData.swift` |
| ネットワーク非依存のローカル CVE 照合（Homebrew＋ロックファイル） | `PackageCveScan.swift`, `PackageCveMapData.swift`, `PackageCveScanLanguages.swift`, `PackageCveMapLanguagesData.swift` |
| 各ガードの状態リーダー（隔離Vault・カナリア・ポート異常・ランタイム脅威・通知履歴・封じ込めタイムライン・ネットワーク履歴） | `QuarantineManager.swift`, `CanaryStatusReader.swift`, `PortAnomalyStatusReader.swift`, `RuntimeThreatStatusReader.swift`, `NotificationHistory.swift`, `ContainmentIncidentTimeline.swift`, `NetworkHistoryGuard.swift` |
| 同梱ナレッジベース（`get_app_help`） | `RoamSwitchKnowledgeBase.swift` |
| 多言語化まわり | `AppLanguage.swift` |
| テスト | `Tests/roamswitch-mcpTests/` — ミラーされたユニットテスト＋ `StdioSmokeTests.swift` |

## 提供ツール（`tools/list`）

全 17 ツール。すべて読み取り専用です。ソケットを開くのは `get_exposed_ports` と、既定で無効な
`run_active_vuln_scan` の 2 つだけで、いずれも `127.0.0.1` 限定です。

### 状態診断・ネットワーク

- `get_security_report` — macOS セキュリティ 18 項目の総合診断（FileVault、SIP、Gatekeeper、
  自動アップデート、XProtect、ファイアウォール、ステルスモード、Wi-Fi 暗号化強度、ARP
  スプーフィング、ゲートウェイ ARP 固定、SSH、sudo の `NOPASSWD` 監査、外部公開ポート、
  ダウンロード保護 / DNS 脅威保護 / リンク保護、USB・アクセサリ防御）をスコア化し、
  項目ごとの改善アドバイスを返します。
- `get_exposed_ports` — 現在リッスン中の全 TCP ポート。localhost を超えて公開されている
  ものは既知の危険サービス DB（Redis・MongoDB 等に加え、Ollama:11434 / LM Studio:1234 /
  Gradio:7860 / vLLM:8000 などのローカル AI 推論サーバー）と照合し、`127.0.0.1:<port>` への
  CORS・ヘッダー確認も行います。
- `get_guard_status` — 全 22 項目のガード設定の ON/OFF（ポート異常、ARP 封じ込め、USB、
  Bluetooth、ダウンロード / DNS 保護、ランタイム脅威、ランサムウェア・カナリア、ClickFix、
  Docker イベント、重要パス FIM、永続化監視、ゲートウェイ ARP 固定、定期ログ監査、クリップボードの
  機密情報漏洩監視、Air-Gap 時の Wi-Fi 自動オフ、WireGuard / Tailscale キルスイッチ、リンク保護と
  フィード更新、実証型脆弱性診断）と、一度も切り替えていない既定値かどうか（`usingDefault`）。
  加えてリンク保護モード、VPN 方式、DNS 脅威保護のプロバイダー / 適用範囲、隔離中の開発サーバー
  ポート、USB ストレージ許可リスト件数、現在の保護レベル、信頼ネットワーク判定を返します（アプリの
  preferences ドメインから読み取り。後述「単体ビルド時の差異」参照）。設定値のみで、VPN トンネルの
  実際の接続状態は特権ヘルパー側にあるため返しません。

### 完全オフラインの監査

- `audit_url_safety` — フィッシング / Unicode ホモグラフ / ブランド偽装サブドメイン /
  高リスク TLD / 平文 HTTP の判定。**同期処理・完全オフライン**で、URL はどこにも送信せず、
  対象ページを取得もしません。各リスク要因には言語非依存の `kind`（例: `homograph`）が付きます。
- `audit_secrets` — 文字列・ファイル・ディレクトリ（再帰）から API キー（OpenAI、Anthropic、
  GitHub、AWS、HuggingFace、Google AI/Gemini、Slack、Stripe）や SSH/RSA 秘密鍵を、正規表現と
  シャノンエントロピー評価で検出します。検出値は出力時にマスクされます。
- `audit_security_logs` — この Mac 自身の統合ログ（`log show`）から直近のセキュリティ事象
  （sudo 失敗、SSH 接続、Gatekeeper 遮断、XProtect 検知、ログイン/認証）を集計します。
  メッセージはプロセス外へ出る前にキー・トークンをマスクし、ログテンプレート異常
  （未知の新規パターン、統計的な頻度スパイク）も併せて返します。
- `get_app_help` — 同梱ナレッジベースの全文検索。

### 脆弱性・CVE

- `run_active_vuln_scan` — **唯一ネットワークリクエストを送るツール**です。非破壊・読み取り
  専用・`127.0.0.1` 限定・チェックごとに短いタイムアウトの 1 リクエストのみで、他ホストには
  一切触れません。検出済みの無認証既定サービス（Redis / Memcached / MongoDB）へのプロトコル
  準拠プローブ、検出済み開発サーバーへの CORS 設定ミス・パストラバーサル・オープンリダイレクト
  検査、および既知 CVE のバージョン範囲照合のみ（実際のエクスプロイト送信は一切なし）。
  **既定で無効**で、RoamSwitch 設定の「実証型脆弱性検証」を有効にするまで実行を拒否します。
- `run_package_cve_scan` — インストール済み Homebrew formula を、NVD の実データから機械生成
  した完全ローカルの CVE マップと照合します。ネットワーク通信なし。
- `run_package_cve_scan_languages` — 指定フォルダ内の依存ロックファイル（`package-lock.json`、
  `requirements.txt`、`Pipfile.lock`、`poetry.lock`、`Cargo.lock`、`Gemfile.lock`、
  `composer.lock`、`go.sum`、`pom.xml`）を同じローカルマップと照合します。ネットワーク通信なし。

### インシデント状態（Air-Gap 中でも動作）

いずれもローカル状態のみを読むため、RoamSwitch がネットワークを緊急遮断している最中でも、
ローカル LLM と組み合わせればその場でトリアージできます。

- `get_runtime_threat_status` — Apple の XProtect がマルウェアを実際に検知したことで、この Mac
  が現在ネットワーク隔離（Air-Gap）されているかどうかと、その発動理由となった直近のインシデント。
  **Air-Gap が発動している理由を調べるなら、まずこれを見てください。**
- `get_canary_status` — ランサムウェア・カナリアガード。おとりファイルの設置状況と、直近 50 件
  までの検知インシデント。
- `get_port_anomaly_incidents` — ポート異常ガード。ベースライン取得状況、現在自動隔離中の
  ポート、直近 50 件までのインシデント（外部公開ポートで待ち受け始めた未知の実行ファイル）。
- `get_quarantine_status` — マルウェア隔離 Vault の中身。元パス、ClamAV が検出した脅威名、
  隔離日時、サイズ。ファイルは移動されるだけで削除されません。
- `get_notification_history` — 直近 7 日間に RoamSwitch が送信した通知を新しい順で返します。
- `get_incident_timeline` — ARP スプーフィング自動封じ込め、ランサムウェア・カナリアガード、
  ランタイム脅威封じ込め、ポート異常ガードの封じ込めを 1 本の時系列で横断表示します（発生元、
  重大度、概要、プロセス、確度の高い場合のみ MITRE ATT&CK ID、実施した対処、未解決 / 解除済み /
  許可済みの状態）。ARP スプーフィング封じ込めの記録はここにしかありません。Linux 版と同名の
  ツールです。
- `get_network_history` — 常時稼働の Evil Twin 検知が記憶しているネットワーク履歴。SSID ごとの
  ゲートウェイ機器の**件数**と最終接続日時（MAC アドレスは出力しません）、および共通の
  ゲートウェイを持たないのに名前が酷似した SSID の組を返します。

### リソース（`resources/list`）

AI クライアントがコンテキストとして直接読み込める `roamswitch://docs/*` ドキュメントが 4 種類
（機能仕様、全アラート・通知カタログ、設定・運用ガイド、トラブルシューティング FAQ）。

**状態を変更するツールは 1 つもありません**。ロックダウン切替も、ポート隔離も、デバイス取り出しも
ありません。設計上そのような API がこのコードに存在しないためです（ホワイトペーパー §8）。

## ビルドと実行

```sh
swift build -c release
./.build/release/roamswitch-mcp
```

動作確認:

```sh
printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
  | ./.build/release/roamswitch-mcp
```

テストは、ミラーされたユニットテスト、stdio のエンドツーエンドテスト、JSON-RPC パーサーおよび
`lsof` / `arp` パーサーへの敵対的入力テスト、ミューテーション・ファジングで構成されています。
詳細は [`SECURITY_TESTING.md`](./SECURITY_TESTING.md) を参照してください。

```sh
swift test
FUZZ_ITERATIONS=200000 swift test --filter MutationFuzzTests   # 長時間ファジング
```

### MCP クライアントからの利用

```jsonc
// Claude Desktop: ~/Library/Application Support/Claude/claude_desktop_config.json
{
  "mcpServers": {
    "roamswitch": {
      "command": "/absolute/path/to/roamswitch-mcp/.build/release/roamswitch-mcp"
    }
  }
}
```

RoamSwitch をインストール済みの場合は、アプリに同梱されているバイナリ
（`/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`）の利用を推奨します。
Claude Desktop / Claude Code / Codex CLI / OpenCode / Antigravity の設定手順は
<https://lafine.net/mcp-setup.html> にあります。

## 単体ビルド時の差異

RoamSwitch アプリのバンドル内で動く場合、このコードはアプリのライブ状態を読みます。
このリポジトリから単体ビルドした場合の違いは 4 点です。

- **`get_guard_status`** は `com.tetsuharu.RoamSwitch` の preferences ドメインを読みますが、
  アプリ以外のバイナリからは空のため、「ガードはすべて無効・ネットワークは未信頼」と報告します。
- **インシデント状態系ツール**（`get_canary_status`、`get_port_anomaly_incidents`、
  `get_runtime_threat_status`、`get_notification_history`、`get_quarantine_status`）も同じ
  ドメインとアプリの隔離 Vault を読むため、単体では失敗ではなく「未有効・履歴なし」を返します。
- **`get_incident_timeline` / `get_network_history`** は
  `~/Library/Application Support/RoamSwitch/` 配下の JSON を読むため、同じユーザーに RoamSwitch
  がインストールされていれば実際の履歴を、そうでなければ空の結果を返します。
- **多言語化**: アプリの `.lproj` リソースがないため `loc(_:)` はキー（＝日本語の原文）に
  フォールバックします。それ以外の出力は同一です。

これ以外（ARP 解析、ポートスキャン、HTTP プローブ、状態診断、URL 監査、シークレット検査、
ログ監査、CVE 照合）はまったく同じ動作です。いずれも `arp`、`route`、`lsof`、`fdesetup`、
`csrutil`、`spctl`、`pfctl -sr`、`log show`、`brew` などを呼び出し、システム状態を直接読んで
いるためです。

## セキュリティ上の性質

- **読み取り専用。** 状態を変更する API は存在しません。
- **ソケットを開かない。** stdin から 1 行読み、stdout へ 1 行書き、クライアントがパイプを
  閉じたら終了します。
- **テレメトリなし・外部通信なし。** 例外は `get_exposed_ports` のローカル `127.0.0.1`
  プローブと、既定で無効なオプトイン機能 `run_active_vuln_scan`（これも `127.0.0.1` 限定）
  のみです。`audit_url_safety` はネットワークに一切触れず、URL の取得も行いません。
- MIT ライセンス。

## これはミラーです — ここで編集しないでください

各 `.swift` ファイルの先頭には、どの RoamSwitch バージョンからミラーしたかを示すヘッダーが
あります。**正本は RoamSwitch アプリ側**であり、ここでの編集は出荷アプリにはコンパイルされず、
次回同期時に上書きされます。RoamSwitch の各リリースはここにミラー・タグ付けされるため、
出荷バイナリのシンボルと突き合わせて検証できます。詳細は [`SYNC.md`](./SYNC.md) を参照。

## 関連情報

- アーキテクチャ・セキュリティ設計書: <https://lafine.net/security.html>（§8 が本サーバー）
- インストール済み RoamSwitch を照会する Swift クライアントライブラリ:
  [RoamSwitchKit](https://github.com/lafine1211/RoamSwitchKit)
- Linux 版は独自の MCP サーバー（`roamswitch-mcp`、全 19 ツール）と非同期 Rust クライアント
  [roamswitch-linux-kit](https://github.com/lafine1211/roamswitch-linux-kit) を提供しています。
