// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.0.0 (build 216).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// The text of `RoamSwitchMCPServer agent-check --help`. A string of the catalog (`loc`), so it is shown in the person's language.
/// The same words as Linux `roamswitch agent-check --help` (`i18n_ext/agent_check.rs`, `ac_usage`), without what macOS does not have:
/// the malicious-IP list, the Server Edition's `agent_egress_allow`, and the kernel allowlist of agent accounts.
enum AgentCheckUsage {
    static var text: String {
        loc("使い方: RoamSwitchMCPServer agent-check [--print-hook-config]\n\nAI コーディングエージェントが、ツールを呼ぶ前に実行する確認です(Claude Code の PreToolUse フック)。標準入力でフックの JSON({tool_name, tool_input, cwd, ...})を受け取り、呼び出しの宛先を調べます。\n  deny   クラウドのメタデータのアドレス(169.254.169.254、fd00:ec2::254、100.100.100.200 など)。どんな書き方でも見つけます\n  ask    認証情報のファイル(.ssh、.aws、.env、クラウド CLI の設定など)と、この端末のネットワークの外への宛先が、同じ呼び出しにある\nループバックと私設のアドレスは通します。報告することがない呼び出しは、何も出力せず終了コード 0 で終わるので、エージェント自身の許可の確認はそのまま働きます。\n--print-hook-config は、貼り付ける settings.json の hooks の例を表示します。設定は書き換えません。\n\n検知の補助であり、防ぐ壁ではありません。スクリプトファイルの中、変数、コマンド置換、複数のコマンドに分けた指定、base64 は見えません。名前は解決せず、書かれたとおりに判定します。ネットワークには接続しません。記録(~/Library/Application Support/RoamSwitch/agent_check_log.jsonl)には、ツール名と理由のキーだけを残し、値は残しません。")
    }
}
