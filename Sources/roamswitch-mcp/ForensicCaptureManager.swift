// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.5 (build 184).
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
    ///
    /// `triggerEventID` is the id of the timeline record of the detection this bundle is for, when the caller has
    /// it. It goes into `manifest.json`, the bundle is named on that record (`evidenceRefs`), and a
    /// `.forensicCapture` record is added as its child. Without it nothing is added to the timeline, as before.
    @discardableResult
    static func captureSnapshot(reason: String, suspectedPID: Int32?, triggerEventID: UUID? = nil) -> URL? {
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
            artifacts: artifacts,
            triggerEventID: triggerEventID?.uuidString
        )
        if let data = try? JSONEncoder().encode(manifest) {
            let manifestURL = bundleDir.appendingPathComponent("manifest.json")
            try? data.write(to: manifestURL, options: .atomic)
            ForensicChain.flush(manifestURL)
            ForensicChain.flush(bundleDir)
            // Anchor the manifest outside the bundle, so rewriting it after the fact is detectable.
            if !ForensicChain.record(root: root, bundleName: bundleDir.lastPathComponent, capturedAt: manifest.capturedAt, manifestData: data) {
                forensicCaptureLog.error("evidence anchor could not be written")
            }
            if let trigger = triggerEventID {
                linkToTimeline(trigger: trigger, bundleName: bundleDir.lastPathComponent, manifest: manifest, manifestData: data)
            }
        }

        forensicCaptureLog.log("evidence bundle captured at \(bundleDir.path, privacy: .public)")
        return bundleDir
    }

    /// The references a timeline record gets for a finished bundle: `manifest.json` first (its SHA-256 is the one in
    /// the chain), then the captured files, at most `ContainmentIncidentTimeline.maxEvidenceRefs` in all. Bundle
    /// folder name, file names and hashes only, never content.
    static func timelineRefs(bundleName: String, manifest: ForensicManifest, manifestData: Data) -> [ContainmentEvidenceRef] {
        var refs = [ContainmentEvidenceRef(bundle: bundleName, artifact: "manifest.json", sha256: ForensicChain.sha256Hex(manifestData))]
        for a in manifest.artifacts where a.status == "captured" {
            guard let rel = a.relativePath else { continue }
            refs.append(ContainmentEvidenceRef(bundle: bundleName, artifact: rel, sha256: a.sha256))
        }
        return Array(refs.prefix(ContainmentIncidentTimeline.maxEvidenceRefs))
    }

    /// Records the bundle as a child of the detection and names it on the detection. The detection is recorded by the
    /// caller before the capture starts; if it is not in the timeline the child is stored without a parent.
    private static func linkToTimeline(trigger: UUID, bundleName: String, manifest: ForensicManifest, manifestData: Data) {
        let refs = timelineRefs(bundleName: bundleName, manifest: manifest, manifestData: manifestData)
        ContainmentIncidentTimeline.record(
            source: .forensicCapture,
            severity: "info",
            summary: String(format: loc("証拠バンドルを保存しました: %@"), bundleName),
            processID: manifest.suspectedPID,
            actionTaken: "evidence_captured",
            parentEventID: trigger,
            evidenceRefs: refs
        )
        ContainmentIncidentTimeline.linkEvidence(to: trigger, refs: refs)
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
        ForensicChain.flush(fileURL)
        let hash = sha256Hex(Data(content.utf8))
        return ForensicArtifactRecord(name: name, status: "captured", detail: capturedNote, relativePath: relativePath, sha256: hash)
    }

    // MARK: - Listing (for MCP / GUI consumption — read-only, no side effects)

    /// Lists every evidence bundle's manifest, newest first, up to `limit`.
    /// Safe to call from `RoamSwitchMCPServer` — reads only local disk
    /// state, no dependency on `LicenseManager`/AppKit.
    static func listBundles(limit: Int = 20) -> [ForensicBundleSummary] {
        guard let root = evidenceRoot() else { return [] }
        return listBundles(root: root, limit: limit)
    }

    /// The same listing for an explicit evidence folder (what the tests use). Each bundle carries the result of
    /// checking it against the anchor chain and its own artifact hashes (`ForensicChain.integrity`).
    static func listBundles(root: URL, limit: Int = 20) -> [ForensicBundleSummary] {
        guard let entries = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: [.contentModificationDateKey]) else {
            return []
        }
        let chain = ForensicChain.load(root: root)
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
                skippedArtifactCount: manifest.artifacts.filter { $0.status == "skipped" }.count,
                integrity: ForensicChain.integrity(bundleDir: dir, manifestData: data, manifest: manifest, chain: chain)
            ))
        }
        return out
    }

    /// What `get_forensic_evidence_bundles` returns: the listing plus the state of the chain as a whole.
    static func bundlesPayload() -> MCPForensicEvidenceBundlesPayload {
        guard let root = evidenceRoot() else { return MCPForensicEvidenceBundlesPayload(bundles: []) }
        return bundlesPayload(root: root)
    }

    static func bundlesPayload(root: URL, limit: Int = 20) -> MCPForensicEvidenceBundlesPayload {
        let chain = ForensicChain.load(root: root)
        return MCPForensicEvidenceBundlesPayload(
            bundles: listBundles(root: root, limit: limit), chainOk: chain.chainOK, chainBrokenAt: chain.brokenAt,
            missingBundles: ForensicChain.missingBundles(root: root, chain: chain)
        )
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
    /// The timeline record of the detection this bundle was saved for, when the caller knew it. Absent in older
    /// manifests; the SHA-256 chain covers it like every other byte of the file.
    var triggerEventID: String? = nil
}

public struct ForensicBundleSummary: Codable, Equatable {
    public let bundleDir: String
    public let capturedAt: String
    public let reason: String
    public let suspectedPID: Int32?
    public let capturedArtifactCount: Int
    public let skippedArtifactCount: Int
    /// `verified`, `manifest_altered`, `artifact_altered:<name>`, `artifact_missing:<name>` or `not_anchored`
    /// (a bundle with no entry in the chain: captured before the chain existed, or its entry was removed).
    public var integrity: String = "not_anchored"
}

/// The evidence bundles as a chain. Every bundle's manifest hash is written to `chain.log` beside the bundles, each
/// line carrying the hash of the line before it, so a manifest rewritten after the fact, a line removed or edited,
/// or a whole bundle deleted shows up when the chain is read. It is tamper-EVIDENT, not tamper-proof: someone who
/// can rewrite the folder and the log together can still forge a consistent history.
enum ForensicChain {
    static let fileName = "chain.log"
    static let genesis = "GENESIS"

    struct Entry: Equatable {
        let time: String
        let bundle: String
        let manifestSHA: String
        let prev: String
        let chain: String
    }

    struct Loaded: Equatable {
        var entries: [Entry] = []
        /// The first bundle whose line does not follow from the one before it (or does not parse).
        var brokenAt: String? = nil
        var chainOK: Bool { brokenAt == nil }
        func anchored(_ bundle: String) -> Entry? { entries.last { $0.bundle == bundle } }
    }

    static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func chainHash(time: String, bundle: String, manifestSHA: String, prev: String) -> String {
        sha256Hex(Data("\(time) \(bundle) \(manifestSHA) \(prev)".utf8))
    }

    /// Flushes a file or directory to disk (best effort).
    static func flush(_ url: URL) {
        let fd = open(url.path, O_RDONLY)
        guard fd >= 0 else { return }
        _ = fcntl(fd, F_FULLFSYNC)
        close(fd)
    }

    static func load(root: URL) -> Loaded {
        var loaded = Loaded()
        guard let text = try? String(contentsOf: root.appendingPathComponent(fileName), encoding: .utf8) else { return loaded }
        var prev = genesis
        for line in text.split(separator: "\n") {
            let f = line.split(separator: " ").map(String.init)
            guard f.count == 5, f[3] == prev, chainHash(time: f[0], bundle: f[1], manifestSHA: f[2], prev: f[3]) == f[4] else {
                loaded.brokenAt = f.count >= 2 ? f[1] : String(line.prefix(40))
                return loaded
            }
            loaded.entries.append(Entry(time: f[0], bundle: f[1], manifestSHA: f[2], prev: f[3], chain: f[4]))
            prev = f[4]
        }
        return loaded
    }

    /// Appends the anchor of one bundle. Returns false when the log could not be written.
    @discardableResult
    static func record(root: URL, bundleName: String, capturedAt: String, manifestData: Data) -> Bool {
        let loaded = load(root: root)
        // A broken chain is not extended silently: the new line would hide where it broke.
        guard loaded.chainOK else { return false }
        let prev = loaded.entries.last?.chain ?? genesis
        let manifestSHA = sha256Hex(manifestData)
        let chain = chainHash(time: capturedAt, bundle: bundleName, manifestSHA: manifestSHA, prev: prev)
        let line = "\(capturedAt) \(bundleName) \(manifestSHA) \(prev) \(chain)\n"
        let url = root.appendingPathComponent(fileName)
        if !FileManager.default.fileExists(atPath: url.path) {
            guard FileManager.default.createFile(atPath: url.path, contents: nil, attributes: [.posixPermissions: 0o600]) else { return false }
        }
        guard let handle = try? FileHandle(forWritingTo: url) else { return false }
        defer { try? handle.close() }
        do {
            try handle.seekToEnd()
            try handle.write(contentsOf: Data(line.utf8))
            try handle.synchronize()
        } catch { return false }
        return true
    }

    /// One bundle against the chain and its own artifact hashes.
    static func integrity(bundleDir: URL, manifestData: Data, manifest: ForensicManifest, chain: Loaded) -> String {
        guard let entry = chain.anchored(bundleDir.lastPathComponent) else { return "not_anchored" }
        if entry.manifestSHA != sha256Hex(manifestData) { return "manifest_altered" }
        for a in manifest.artifacts where a.status == "captured" {
            guard let rel = a.relativePath, let expected = a.sha256 else { continue }
            guard let data = try? Data(contentsOf: bundleDir.appendingPathComponent(rel)) else { return "artifact_missing:\(a.name)" }
            if sha256Hex(data) != expected { return "artifact_altered:\(a.name)" }
        }
        return "verified"
    }

    /// Bundles the chain names that are no longer in the folder (deleted after the fact).
    static func missingBundles(root: URL, chain: Loaded) -> [String] {
        chain.entries.map(\.bundle).filter { !FileManager.default.fileExists(atPath: root.appendingPathComponent($0).path) }
    }
}
