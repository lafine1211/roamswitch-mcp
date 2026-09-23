// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.54 (build 115).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import CryptoKit
import os

private let forensicCaptureLog = Logger(subsystem: "com.tetsuharu.RoamSwitch", category: "forensic-capture")

/// Automatic evidence preservation on detection — the Mac counterpart of
/// `roamswitch-os`'s `hardening/incident-capture` (and the same design now
/// ported into `roamswitch-linux` as the standalone `roamswitch-incident-capture`
/// binary). By the time a human looks at an alert, the attacker's process
/// may already be gone, network connections closed, memory state lost —
/// this captures a timestamped evidence bundle (current process list,
/// network connections, and files recently modified in the ransomware
/// target folders) to `~/Library/Application Support/RoamSwitch/incident-evidence/
/// <timestamp>-<short-id>/manifest.json` (with the SHA-256 of every
/// artifact) so evidence still exists for later review.
///
/// **Scope narrower than the Linux/roamswitch-os editions on purpose.**
/// Neither a bounded packet capture (needs a privileged Network Extension
/// entitlement this project doesn't hold) nor a full `/proc`-equivalent
/// per-process memory/fd snapshot (macOS has no `/proc`; the closest
/// equivalent needs the EndpointSecurity entitlement this project has
/// decided not to pursue — see `no-endpointsecurity-entitlement-policy`) is
/// attempted here. What IS captured uses only unprivileged, already-
/// established primitives from elsewhere in this codebase: `ps`/`lsof`
/// subprocess snapshots (same technique as `RansomwareCanaryGuard`'s
/// `runLsofForCurrentUser`) and a recently-modified-files scan (same
/// technique as `RansomwareCanaryGuard.recentlyModifiedFiles`, duplicated
/// per this codebase's established convention rather than shared).
enum ForensicCaptureManager {
    private static func evidenceRoot() -> URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        return appSupport.appendingPathComponent("RoamSwitch/incident-evidence", isDirectory: true)
    }

    private static func shortID() -> String {
        let nanos = UInt64(Date().timeIntervalSince1970 * 1_000_000_000)
        let hex = String(nanos, radix: 16)
        let short = String(hex.suffix(8))
        return "\(short)-\(ProcessInfo.processInfo.processIdentifier)"
    }

    private static func bundleDirName(capturedAt: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return "\(formatter.string(from: capturedAt))-\(shortID())"
    }

    /// Captures a bundle and returns its directory URL, or `nil` if the
    /// bundle directory itself couldn't be created (disk full, permissions).
    /// Individual artifacts within the bundle are always best-effort — a
    /// missing `lsof`/`ps` or an empty recently-modified-files scan is
    /// recorded as such in `manifest.json`, never treated as a hard failure.
    @discardableResult
    static func captureSnapshot(reason: String, suspectedPID: Int32?) -> URL? {
        guard let root = evidenceRoot() else { return nil }
        let capturedAt = Date()
        let bundleDir = root.appendingPathComponent(bundleDirName(capturedAt: capturedAt), isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: bundleDir, withIntermediateDirectories: true)
        } catch {
            forensicCaptureLog.error("could not create evidence bundle directory: \(error.localizedDescription, privacy: .public)")
            return nil
        }

        var artifacts: [ForensicArtifactRecord] = []

        artifacts.append(writeTextArtifact(
            in: bundleDir, relativePath: "process_list.txt", name: "process_list",
            content: runProcessList(),
            capturedNote: "実行中プロセス一覧(ps)を記録", skippedNote: "ps コマンドの実行に失敗しました"
        ))

        artifacts.append(writeTextArtifact(
            in: bundleDir, relativePath: "network_connections.txt", name: "network_connections",
            content: runLsofNetworkSnapshot(),
            capturedNote: "現在のユーザーのネットワーク接続一覧(lsof)を記録", skippedNote: "lsof コマンドの実行に失敗しました"
        ))

        let recentFiles = recentlyModifiedFiles(inDirectories: suspiciousTargetDirectories(), within: 300, limit: 200)
        artifacts.append(writeTextArtifact(
            in: bundleDir, relativePath: "recently_modified_files.txt", name: "recently_modified_files",
            content: recentFiles.isEmpty ? nil : recentFiles.joined(separator: "\n"),
            capturedNote: "直近5分間に変更されたファイル \(recentFiles.count) 件を記録(Documents/Desktop/Downloads/Pictures)",
            skippedNote: "対象フォルダ内に直近の変更ファイルが見つかりませんでした"
        ))

        if let pid = suspectedPID {
            artifacts.append(writeTextArtifact(
                in: bundleDir, relativePath: "suspected_process_openfiles.txt", name: "suspected_process_openfiles",
                content: runLsofForPID(pid),
                capturedNote: "疑わしいプロセス(PID \(pid))が開いているファイル一覧を記録",
                skippedNote: "疑わしいプロセス(PID \(pid))は既に終了しているか、情報を取得できませんでした"
            ))
        }

        let manifest = ForensicManifest(
            capturedAt: ISO8601DateFormatter().string(from: capturedAt),
            reason: reason,
            suspectedPID: suspectedPID,
            artifacts: artifacts
        )
        if let data = try? JSONEncoder().encode(manifest) {
            try? data.write(to: bundleDir.appendingPathComponent("manifest.json"), options: .atomic)
        }

        forensicCaptureLog.log("evidence bundle captured at \(bundleDir.path, privacy: .public)")
        return bundleDir
    }

    private static func writeTextArtifact(
        in bundleDir: URL, relativePath: String, name: String,
        content: String?, capturedNote: String, skippedNote: String
    ) -> ForensicArtifactRecord {
        guard let content, !content.isEmpty else {
            return ForensicArtifactRecord(name: name, status: "skipped", detail: skippedNote, relativePath: nil, sha256: nil)
        }
        let fileURL = bundleDir.appendingPathComponent(relativePath)
        guard (try? content.write(to: fileURL, atomically: true, encoding: .utf8)) != nil else {
            return ForensicArtifactRecord(name: name, status: "skipped", detail: skippedNote, relativePath: nil, sha256: nil)
        }
        let hash = sha256Hex(Data(content.utf8))
        return ForensicArtifactRecord(name: name, status: "captured", detail: capturedNote, relativePath: relativePath, sha256: hash)
    }

    // MARK: - Listing (for MCP / GUI consumption — read-only, no side effects)

    /// Lists every evidence bundle's manifest, newest first, up to `limit`.
    /// Safe to call from `RoamSwitchMCPServer` — reads only local disk
    /// state, no dependency on `LicenseManager`/AppKit.
    static func listBundles(limit: Int = 20) -> [ForensicBundleSummary] {
        guard let root = evidenceRoot(),
              let entries = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: [.contentModificationDateKey]) else {
            return []
        }
        let sorted = entries
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true }
            .sorted { lhsURL, rhsURL in
                lhsURL.lastPathComponent > rhsURL.lastPathComponent // bundle dir names are timestamp-prefixed, so lexical == chronological
            }
        var out: [ForensicBundleSummary] = []
        for dir in sorted.prefix(limit) {
            guard let data = try? Data(contentsOf: dir.appendingPathComponent("manifest.json")),
                  let manifest = try? JSONDecoder().decode(ForensicManifest.self, from: data) else { continue }
            out.append(ForensicBundleSummary(
                bundleDir: dir.path,
                capturedAt: manifest.capturedAt,
                reason: manifest.reason,
                suspectedPID: manifest.suspectedPID,
                capturedArtifactCount: manifest.artifacts.filter { $0.status == "captured" }.count,
                skippedArtifactCount: manifest.artifacts.filter { $0.status == "skipped" }.count
            ))
        }
        return out
    }

    // MARK: - Capture primitives (unprivileged subprocess snapshots)

    private static func runProcessList() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-axo", "pid,ppid,user,%cpu,%mem,comm"]
        return runAndCaptureOutput(process)
    }

    private static func runLsofNetworkSnapshot() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-a", "-u", NSUserName(), "-i"]
        return runAndCaptureOutput(process)
    }

    private static func runLsofForPID(_ pid: Int32) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-p", String(pid)]
        return runAndCaptureOutput(process)
    }

    private static func runAndCaptureOutput(_ process: Process) -> String? {
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }

    private static func suspiciousTargetDirectories() -> [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return [home + "/Documents", home + "/Desktop", home + "/Downloads", home + "/Pictures"]
    }

    /// Duplicated from `RansomwareCanaryGuard.recentlyModifiedFiles` per
    /// this codebase's established "duplicate rather than share small
    /// helpers across guard types" convention — see that function's own
    /// doc comment for the same rationale.
    private static func recentlyModifiedFiles(
        inDirectories directories: [String],
        within seconds: TimeInterval,
        limit: Int,
        now: Date = Date(),
        fileManager: FileManager = .default
    ) -> [String] {
        let cutoff = now.addingTimeInterval(-seconds)
        var matches: [String] = []
        for dir in directories {
            guard let entries = try? fileManager.contentsOfDirectory(atPath: dir) else { continue }
            for entry in entries {
                let path = dir + "/" + entry
                guard let attrs = try? fileManager.attributesOfItem(atPath: path),
                      let modified = attrs[.modificationDate] as? Date,
                      modified > cutoff else { continue }
                matches.append(path)
                if matches.count >= limit { return matches }
            }
        }
        return matches
    }

    private static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

struct ForensicArtifactRecord: Codable {
    let name: String
    let status: String // "captured" | "skipped"
    let detail: String
    let relativePath: String?
    let sha256: String?
}

struct ForensicManifest: Codable {
    let capturedAt: String
    let reason: String
    let suspectedPID: Int32?
    let artifacts: [ForensicArtifactRecord]
}

public struct ForensicBundleSummary: Codable, Equatable {
    public let bundleDir: String
    public let capturedAt: String
    public let reason: String
    public let suspectedPID: Int32?
    public let capturedArtifactCount: Int
    public let skippedArtifactCount: Int
}
