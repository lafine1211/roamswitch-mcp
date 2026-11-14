// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.0.0 (build 216).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// `RoamSwitchMCPServer agent-check`: the destination check an AI coding agent runs before a tool call (a Claude Code
/// `PreToolUse` hook). The rules are `RoamSwitch/AgentCheck.swift`; this file reads stdin and prints the hook's answer.
///
///   RoamSwitchMCPServer agent-check                      reads the hook JSON on stdin
///   RoamSwitchMCPServer agent-check --print-hook-config  prints a settings.json `hooks` entry to paste (writes nothing)
///   RoamSwitchMCPServer agent-check --help               the limits and the rules, in the person's language
///
/// Hook contract (Claude Code hooks reference, https://code.claude.com/docs/en/hooks, read 2026-11-13): the JSON on stdin
/// has `tool_name`, `tool_input`, `cwd`, `hook_event_name`; the answer is `hookSpecificOutput` with
/// `hookEventName: "PreToolUse"`, `permissionDecision` (`allow` | `deny` | `ask` | `defer`) and
/// `permissionDecisionReason`, on stdout with exit 0. Exit 0 with no output is "no decision": the normal permission flow
/// goes on. An explicit `allow` would skip the person's permission prompt, so this command never prints one. An exit
/// code other than 0 or 2 is a non-blocking error: a call is never stopped because this command failed.
///
/// No network: this command opens no socket. Linux: `crates/roamswitch-cli/src/agent_check_cmd.rs`.
enum AgentCheckCommand {
    static let flag = "agent-check"
    /// The longest hook JSON read (a `Write` of a large file is the biggest input).
    static let maxInput = 16 * 1024 * 1024

    static func run(_ args: [String]) -> Int32 {
        if args.contains("--print-hook-config") {
            let program = Bundle.main.executableURL?.path ?? CommandLine.arguments[0]
            print(AgentCheck.hookConfigJSON(program: program.hasPrefix("/") ? program : "RoamSwitchMCPServer"))
            FileHandle.standardError.write(Data((loc("上の JSON を、自分の ~/.claude/settings.json の hooks に貼り付けてください(何も書き込んでいません)。貼り付けたあと、AI エージェントの設定の点検が「フックが増えた」と知らせます。内容を確かめたら、メニューの「AIエージェントの指示ファイルを監査…」で確認済みにしてください。このフックは検知の補助です。スクリプトの中、変数、分けて書かれたコマンド、base64 は見えません。") + "\n").utf8))
            return 0
        }
        if args.contains("--help") || args.contains("-h") {
            print(AgentCheckUsage.text)
            return 0
        }
        if let bad = args.first(where: { $0.hasPrefix("-") }) {
            fail(String(format: loc("agent-check: %@ は使えません。使い方は --help を見てください"), bad))
            return 2
        }
        if isatty(0) != 0 {
            // Waiting for a hook that is not there would look like a hang.
            fail(loc("agent-check はフックの JSON を標準入力で受け取ります。端末からは使えません。使い方は --help を見てください"))
            return 2
        }
        var raw = Data()
        while let chunk = try? FileHandle.standardInput.read(upToCount: 1 << 16), !chunk.isEmpty {
            raw.append(chunk)
            if raw.count > maxInput { break }
        }
        guard raw.count <= maxInput,
              let v = (try? JSONSerialization.jsonObject(with: raw)) as? [String: Any],
              let tool = v["tool_name"] as? String
        else {
            fail(loc("agent-check: 標準入力が PreToolUse フックの JSON ではないため、何も判定していません。呼び出しは止めていません"))
            return 1
        }
        // Another event than PreToolUse is not ours to judge.
        if let event = v["hook_event_name"] as? String, event != "PreToolUse" { return 0 }
        let env = AgentCheck.Env(feed: { _ in nil }, allowlist: nil, cwd: v["cwd"] as? String)
        let decision = AgentCheck.check(tool: tool, input: v["tool_input"], env: env)
        if !AgentCheckLog.record(tool: tool, decision: decision) {
            // The answer does not depend on the log.
            fail(loc("agent-check: 記録に書き込めませんでした。判定には影響しません"))
        }
        if let out = AgentCheck.hookOutput(decision) { print(out) }
        return 0
    }

    private static func fail(_ message: String) {
        FileHandle.standardError.write(Data((message + "\n").utf8))
    }
}
