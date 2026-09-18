// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.37 (build 94).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Optional supplementary layer for `ActiveVulnScan`: `nmap`'s Nmap
/// Scripting Engine (NSE), restricted to `safe and not broadcast and not
/// external`, run against ports already confirmed open. The macOS
/// counterpart of the Linux/Sensor implementation
/// (`roamswitch-linux/crates/roamswitch-core/src/nmap_nse.rs`) — see that
/// file's doc comment for the full design rationale (why an external tool
/// at all, the trust-model difference from `ActiveVulnScan`'s own hand-
/// rolled probes, and why `safe` alone isn't actually safe enough).
///
/// Script selector: plain `safe` also pulls in *broadcast* scripts (query
/// the whole LAN via multicast/broadcast, not just the target) and scripts
/// nmap itself categorizes `external` (send data to a third-party service —
/// `vulners.nse`, tagged `{"vuln", "safe", "external"}`, queries
/// vulners.com with the detected service/version) — both confirmed live,
/// 2026-09-18, actually firing against a real LAN-connected host during the
/// Linux implementation's own verification. `--script-timeout 15s` caps
/// each individual script's own runtime (not the whole scan — some `safe`
/// HTTP scripts run indefinitely long against non-standard HTTP APIs,
/// starving every other port of the shared external timeout), and `-T4`
/// speeds up otherwise-conservative default timing. Runs whenever
/// `ActiveVulnScan.isEnabled` is on — no separate opt-in of its own; a
/// former second toggle read `UserDefaults.standard` directly, which is
/// always empty inside the separate-process, separate-bundle-ID
/// `RoamSwitchMCPServer`, so NSE silently never ran for MCP-triggered
/// audits even when the menu bar showed it as on.
enum NmapNSE {

    struct NSEFinding {
        let port: Int
        let script: String
        let output: String
    }

    /// Homebrew's two install prefixes (Apple Silicon / Intel) plus
    /// MacPorts — GUI apps launched via LaunchServices don't inherit the
    /// user's shell `PATH`, so this can't rely on `which`/`$PATH` the way a
    /// Terminal-launched process could. Same convention as
    /// `PackageCveScan.resolveBrewPath()`.
    private static func resolveNmapPath() -> String? {
        for candidate in ["/opt/homebrew/bin/nmap", "/usr/local/bin/nmap", "/opt/local/bin/nmap", "/usr/bin/nmap"] {
            if FileManager.default.isExecutableFile(atPath: candidate) { return candidate }
        }
        return nil
    }

    static func nmapAvailable() -> Bool {
        resolveNmapPath() != nil
    }

    /// Rebuilds nmap's own NSE script index (`nmap --script-updatedb`,
    /// regenerates `script.db`) so scripts added or changed by a Homebrew
    /// upgrade of `nmap` take effect immediately. Cheap (a local directory
    /// scan, no network) — safe to call periodically. Best-effort and non-
    /// fatal: returns `false` if `nmap` isn't installed or the command
    /// itself fails.
    @discardableResult
    static func updateScriptDB() -> Bool {
        guard let nmapPath = resolveNmapPath() else { return false }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: nmapPath)
        process.arguments = ["--script-updatedb"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return false
        }
        process.waitUntilExit()
        return process.terminationStatus == 0
    }

    /// Runs the restricted NSE script set against `ports` and parses the
    /// human-readable output into `NSEFinding`s. Returns an empty list
    /// (never throws) if `nmap` isn't installed, `ports` is empty, the scan
    /// produced nothing parseable, or the process had to be killed for
    /// exceeding `timeoutSeconds` — a best-effort supplementary layer,
    /// never load-bearing for the rest of the audit. Synchronous/blocking;
    /// callers already run this off the main thread (same
    /// `DispatchQueue.global(qos: .utility)` pattern `ActiveVulnScan.runScan`
    /// itself is invoked from).
    static func runNSESafeScripts(host: String, ports: [Int], timeoutSeconds: TimeInterval) -> [NSEFinding] {
        guard !ports.isEmpty, let nmapPath = resolveNmapPath() else { return [] }
        let portList = ports.map(String.init).joined(separator: ",")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: nmapPath)
        process.arguments = [
            "-Pn", "-n", "-sV", "-T4",
            "--script", "safe and not broadcast and not external",
            "--script-timeout", "15s",
            "-p", portList, host,
        ]
        let outPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            return []
        }

        // Drained concurrently on a dedicated thread, not after
        // `waitUntilExit()` — nmap's stdout can exceed the pipe's kernel
        // buffer, and reading only after exit risks the classic
        // write-blocks-because-nobody-is-reading deadlock.
        var stdoutData = Data()
        let readThread = Thread {
            stdoutData = outPipe.fileHandleForReading.readDataToEndOfFile()
        }
        readThread.start()

        // Polled rather than `waitUntilExit()` directly so a hung/slow NSE
        // script is actually killed at the deadline, not abandoned to
        // finish on its own schedule (mirrors the Rust implementation's
        // `try_wait()` poll loop — a timed-out run must not leak a long-
        // lived orphan `nmap` process).
        let deadline = Date().addingTimeInterval(timeoutSeconds)
        var timedOut = false
        while process.isRunning {
            if Date() >= deadline {
                timedOut = true
                process.terminate()
                break
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        process.waitUntilExit()
        while !readThread.isFinished {
            Thread.sleep(forTimeInterval: 0.02)
        }

        if timedOut {
            return []
        }

        let text = String(decoding: stdoutData, as: UTF8.self)
        return parseNmapOutput(text)
    }

    /// Parses nmap's normal (`-oN`-shaped, which is also what plain stdout
    /// gives) output: a port line (`25/tcp open  smtp`) sets the "current
    /// port," and subsequent `|`/`|_`-prefixed lines are that port's NSE
    /// script output. A new script starts only when no script is currently
    /// open — i.e. right after a port line or right after the previous
    /// script's `|_` terminator line — and its name is whatever precedes
    /// the first `:` on that opening line. Every line after that, until a
    /// `|_`-prefixed line closes the block, is pure continuation content,
    /// appended verbatim regardless of whether it itself contains a colon.
    /// Direct port of `nmap_nse.rs::parse_nmap_output` — see that
    /// function's doc comment for the real multi-line output shape (nested
    /// colons in `vulners`/`ssh2-enum-algos`/`ssl-cert` output) that broke
    /// an earlier, simpler "any line with a colon starts a new script"
    /// parser.
    static func parseNmapOutput(_ text: String) -> [NSEFinding] {
        var findings: [NSEFinding] = []
        var currentPort: Int?
        var currentScript: String?
        var currentOutput = ""

        func flush() {
            if let port = currentPort, let script = currentScript {
                let trimmed = currentOutput.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    findings.append(NSEFinding(port: port, script: script, output: trimmed))
                }
            }
            currentScript = nil
            currentOutput = ""
        }

        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(rawLine)
            let trimmedEnd = line.hasSuffix(" ") ? String(line.reversed().drop { $0 == " " }.reversed()) : line

            if let slashRange = trimmedEnd.range(of: "/tcp") {
                let portCandidate = String(trimmedEnd[trimmedEnd.startIndex..<slashRange.lowerBound])
                if portCandidate.allSatisfy(\.isNumber), !portCandidate.isEmpty, trimmedEnd.contains("open") {
                    flush()
                    currentPort = Int(portCandidate)
                    continue
                }
            }

            let content = trimmedEnd.trimmingCharacters(in: .whitespaces)
            let isTerminator = content.hasPrefix("|_")
            if content.hasPrefix("|_") || content.hasPrefix("|") {
                let rest0 = content.hasPrefix("|_") ? String(content.dropFirst(2)) : String(content.dropFirst(1))
                let rest = rest0.trimmingCharacters(in: .whitespaces)
                if currentScript == nil {
                    // Only an opening line (right after a port line or a
                    // prior `|_` terminator) names a new script — never a
                    // mid-block continuation line, even one that happens to
                    // contain ':'.
                    if let colonIdx = rest.firstIndex(of: ":") {
                        currentScript = String(rest[rest.startIndex..<colonIdx]).trimmingCharacters(in: .whitespaces)
                        let firstLine = String(rest[rest.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)
                        currentOutput += firstLine + "\n"
                    } else {
                        currentScript = rest
                        currentOutput += "\n"
                    }
                } else {
                    currentOutput += rest + "\n"
                }
                if isTerminator {
                    flush()
                }
            } else {
                flush()
            }
        }
        flush()
        return findings
    }
}
