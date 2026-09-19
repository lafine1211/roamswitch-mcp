// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.41 (build 98).
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

    /// Locates the `npm` binary the same way a user's shell would —
    /// `/usr/bin/env npm` walks `$PATH`, covering Homebrew, nvm, Volta, and
    /// system installs without hardcoding any one location.
    private static func resolveNpmPath() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["which", "npm"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return (path?.isEmpty == false) ? path : nil
        } catch {
            return nil
        }
    }

    /// Runs `npm audit signatures` with `directory` as the working
    /// directory. Sends real requests to the npm registry — callers MUST
    /// check `isEnabled` (and, in the app UI, get a fresh per-run
    /// confirmation) before calling this.
    static func run(directory: String) -> Swift.Result<Result, RunError> {
        guard let npmPath = resolveNpmPath() else {
            return .failure(.npmNotFound)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: npmPath)
        process.arguments = ["audit", "signatures"]
        process.currentDirectoryURL = URL(fileURLWithPath: directory)

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        do {
            try process.run()
        } catch {
            return .failure(.launchFailed(error.localizedDescription))
        }

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let output = String(data: data, encoding: .utf8) ?? ""
        return .success(Result(directory: directory, rawOutput: output, exitCode: process.terminationStatus))
    }
}
