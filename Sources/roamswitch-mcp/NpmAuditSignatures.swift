// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.10.24 (build 142).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Opt-in wrapper around `npm audit signatures`, which verifies installed
/// packages' registry signatures against npm's own provenance/signing
/// infrastructure — inspired by a dev.to article on npm-install
/// supply-chain risk. Unlike every other package/CVE check in this app,
/// this one actually talks to the npm registry (`registry.npmjs.org`),
/// which conflicts with RoamSwitch's "receive-only / Zero Telemetry"
/// design unless the user explicitly consents — same double-gate pattern
/// as `ActiveVulnScan.swift`: (1) a persistent opt-in toggle, off by
/// default, and (2) a per-run confirmation dialog that re-states what will
/// happen. No output is parsed into a rigid, hand-maintained schema — npm's
/// exact wording isn't a contract this app controls, so the raw command
/// output is surfaced directly, with only a lightweight heuristic
/// (`hasIssues`) to flag whether a human should read it closely.
enum NpmAuditSignatures {

    static let enabledDefaultsKey = "RoamSwitch.NpmAuditSignaturesEnabled"

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: enabledDefaultsKey)
    }

    struct Result {
        let directory: String
        /// `npm audit signatures`' own stdout+stderr, verbatim.
        let rawOutput: String
        let exitCode: Int32
        /// A lightweight heuristic (non-zero exit code, or "invalid"/
        /// "missing" appearing in the output) — not a parsed verdict.
        /// npm's own exit code is the actual source of truth; this just
        /// surfaces it alongside a keyword check for a human skimming the
        /// summary line before reading the full output.
        var hasIssues: Bool {
            if exitCode != 0 { return true }
            let lower = rawOutput.lowercased()
            return lower.contains("invalid") || lower.contains("missing registry signature")
        }
    }

    enum RunError: Error {
        case npmNotFound
        case launchFailed(String)
    }

    /// Wall-clock ceiling for one `npm audit signatures` run.
    static let timeoutSeconds: TimeInterval = 90
    /// Output kept in the result; anything beyond this is drained and dropped.
    static let maxOutputBytes = 256 * 1024

    /// Registry pinned on the command line (overrides any `registry=` in a
    /// project/user `.npmrc` or `npm_config_registry` env var).
    static let pinnedRegistry = "https://registry.npmjs.org/"

    /// Locates the `npm` binary without trusting an attacker-influenced
    /// `$PATH`. Well-known install locations are tried first; then `$PATH`
    /// entries, but only absolute ones that are NOT inside the project being
    /// audited (no `./node_modules/.bin`-style planted `npm`), whose directory
    /// and file are not group/world-writable and are owned by root or the
    /// current user.
    private static func resolveNpmPath(avoidingDirectory projectDir: String) -> String? {
        let home = NSHomeDirectory()
        var candidates = [
            "/opt/homebrew/bin/npm",
            "/usr/local/bin/npm",
            "\(home)/.volta/bin/npm",
        ]
        let pathEntries = (ProcessInfo.processInfo.environment["PATH"] ?? "")
            .split(separator: ":").map(String.init)
        for entry in pathEntries where entry.hasPrefix("/") {
            candidates.append((entry as NSString).appendingPathComponent("npm"))
        }
        let projectPrefix = projectDir.hasSuffix("/") ? projectDir : projectDir + "/"
        for candidate in candidates {
            let resolved = URL(fileURLWithPath: candidate).resolvingSymlinksInPath().path
            if resolved.hasPrefix(projectPrefix) || candidate.hasPrefix(projectPrefix) { continue }
            guard FileManager.default.isExecutableFile(atPath: resolved),
                  isTrustedOwnership(path: resolved),
                  isTrustedOwnership(path: (candidate as NSString).deletingLastPathComponent) else { continue }
            return candidate
        }
        return nil
    }

    /// Owned by root or the current user, and not writable by group/others.
    private static func isTrustedOwnership(path: String) -> Bool {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let owner = attrs[.ownerAccountID] as? NSNumber,
              let perms = attrs[.posixPermissions] as? NSNumber else { return false }
        let uid = owner.uint32Value
        guard uid == 0 || uid == getuid() else { return false }
        return perms.uint16Value & 0o022 == 0
    }

    /// A minimal, allow-listed environment: no `npm_config_*`, `NODE_OPTIONS`,
    /// `NODE_PATH` etc. that could redirect the registry or inject code. PATH
    /// is rebuilt from the npm binary's own directory plus system locations
    /// (npm is a `#!/usr/bin/env node` script and must find its sibling node).
    private static func sanitizedEnvironment(npmPath: String) -> [String: String] {
        let source = ProcessInfo.processInfo.environment
        let keep = ["HOME", "USER", "LOGNAME", "TMPDIR", "LANG", "LC_ALL", "LC_CTYPE",
                    "HTTP_PROXY", "HTTPS_PROXY", "NO_PROXY", "ALL_PROXY",
                    "http_proxy", "https_proxy", "no_proxy", "all_proxy",
                    "NODE_EXTRA_CA_CERTS", "SSL_CERT_FILE"]
        var env: [String: String] = [:]
        for key in keep { if let v = source[key] { env[key] = v } }
        let npmDir = ((npmPath as NSString).resolvingSymlinksInPath as NSString).deletingLastPathComponent
        let npmLinkDir = (npmPath as NSString).deletingLastPathComponent
        env["PATH"] = [npmLinkDir, npmDir, "/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin"]
            .reduce(into: [String]()) { if !$1.isEmpty && !$0.contains($1) { $0.append($1) } }
            .joined(separator: ":")
        return env
    }

    /// Project `.npmrc` can declare scoped registries (`@scope:registry=`) or
    /// auth/proxy settings that a `--registry` flag does not override, which
    /// would send requests to an arbitrary host. Refuse such projects.
    private static func projectNpmrcOverridesRegistry(directory: String) -> Bool {
        let rc = (directory as NSString).appendingPathComponent(".npmrc")
        guard let text = try? String(contentsOfFile: rc, encoding: .utf8) else { return false }
        let lower = text.lowercased()
        return lower.contains("registry") || lower.contains("proxy") || lower.contains("cafile")
    }

    /// Runs `npm audit signatures` with `directory` as the working
    /// directory. Sends real requests to the npm registry — callers MUST
    /// check `isEnabled` (and, in the app UI, get a fresh per-run
    /// confirmation) before calling this. Callers exposed to untrusted input
    /// (the MCP server) must additionally restrict `directory` to registered
    /// project folders *before* calling (see `MCPServer.resolveRegisteredPath`).
    static func run(directory: String) -> Swift.Result<Result, RunError> {
        let dirURL = URL(fileURLWithPath: directory).resolvingSymlinksInPath()
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: dirURL.path, isDirectory: &isDir), isDir.boolValue else {
            return .failure(.launchFailed("directory not found"))
        }
        if projectNpmrcOverridesRegistry(directory: dirURL.path) {
            return .failure(.launchFailed("project .npmrc overrides registry/proxy settings; refusing to run"))
        }
        guard let npmPath = resolveNpmPath(avoidingDirectory: dirURL.path) else {
            return .failure(.npmNotFound)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: npmPath)
        process.arguments = [
            "audit", "signatures",
            "--userconfig", "/dev/null",
            "--globalconfig", "/dev/null",
            "--registry=\(pinnedRegistry)",
            "--ignore-scripts",
            "--no-update-notifier",
        ]
        process.currentDirectoryURL = dirURL
        process.environment = sanitizedEnvironment(npmPath: npmPath)

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        process.standardInput = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            return .failure(.launchFailed(error.localizedDescription))
        }

        // Watchdog: SIGTERM at the deadline, SIGKILL 3 s later if it lingers.
        let pid = process.processIdentifier
        let lock = NSLock()
        var timedOut = false
        let watchdog = DispatchWorkItem {
            lock.lock(); timedOut = true; lock.unlock()
            process.terminate()
            DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                if process.isRunning { kill(pid, SIGKILL) }
            }
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeoutSeconds, execute: watchdog)

        // Bounded read: keep at most `maxOutputBytes`, keep draining so the
        // child never blocks on a full pipe.
        var data = Data()
        var truncated = false
        let reader = outputPipe.fileHandleForReading
        while true {
            guard let chunk = try? reader.read(upToCount: 64 * 1024), !chunk.isEmpty else { break }
            if data.count < maxOutputBytes {
                data.append(chunk.prefix(maxOutputBytes - data.count))
                if data.count >= maxOutputBytes { truncated = true }
            } else {
                truncated = true
            }
        }
        process.waitUntilExit()
        watchdog.cancel()

        lock.lock(); let didTimeOut = timedOut; lock.unlock()
        if didTimeOut {
            return .failure(.launchFailed("npm audit signatures timed out after \(Int(timeoutSeconds))s"))
        }

        var output = String(decoding: data, as: UTF8.self)
        if truncated { output += "\n…(output truncated)" }
        return .success(Result(directory: dirURL.path, rawOutput: output, exitCode: process.terminationStatus))
    }
}
