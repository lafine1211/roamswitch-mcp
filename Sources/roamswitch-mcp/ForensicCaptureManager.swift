// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.0.2 (build 218).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import CryptoKit
import Darwin
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
        // Monotonic start, for the time each artifact and the whole capture took (`elapsedMs`, `durationMs`).
        let startedAt = DispatchTime.now()
        func elapsedMs() -> Int { Int((DispatchTime.now().uptimeNanoseconds &- startedAt.uptimeNanoseconds) / 1_000_000) }
        let bundleDir = root.appendingPathComponent(bundleDirName(capturedAt: capturedAt), isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: bundleDir, withIntermediateDirectories: true)
        } catch {
            forensicCaptureLog.error("could not create evidence bundle directory: \(error.localizedDescription, privacy: .public)")
            return nil
        }

        var artifacts: [ForensicArtifactRecord] = []

        func stamped(_ record: ForensicArtifactRecord) -> ForensicArtifactRecord {
            var r = record
            r.elapsedMs = elapsedMs()
            return r
        }

        artifacts.append(stamped(writeTextArtifact(
            in: bundleDir, relativePath: "process_list.txt", name: "process_list",
            content: runProcessList(),
            capturedNote: "実行中プロセス一覧(ps)を記録", skippedNote: "ps コマンドの実行に失敗しました"
        )))

        artifacts.append(stamped(writeTextArtifact(
            in: bundleDir, relativePath: "network_connections.txt", name: "network_connections",
            content: runLsofNetworkSnapshot(),
            capturedNote: "現在のユーザーのネットワーク接続一覧(lsof)を記録", skippedNote: "lsof コマンドの実行に失敗しました"
        )))

        let recentFiles = recentlyModifiedFiles(inDirectories: suspiciousTargetDirectories(), within: 300, limit: 200)
        artifacts.append(stamped(writeTextArtifact(
            in: bundleDir, relativePath: "recently_modified_files.txt", name: "recently_modified_files",
            content: recentFiles.isEmpty ? nil : recentFiles.joined(separator: "\n"),
            capturedNote: "直近5分間に変更されたファイル \(recentFiles.count) 件を記録(Documents/Desktop/Downloads/Pictures)",
            skippedNote: "対象フォルダ内に直近の変更ファイルが見つかりませんでした"
        )))

        if let pid = suspectedPID {
            // The sockets first: a read of the process's own tables takes a moment, `lsof` below takes far longer, and
            // the process may be gone by then.
            artifacts.append(stamped(captureNetworkArtifact(in: bundleDir, pid: pid)))
            artifacts.append(stamped(writeTextArtifact(
                in: bundleDir, relativePath: "suspected_process_openfiles.txt", name: "suspected_process_openfiles",
                content: runLsofForPID(pid),
                capturedNote: "疑わしいプロセス(PID \(pid))が開いているファイル一覧を記録",
                skippedNote: "疑わしいプロセス(PID \(pid))は既に終了しているか、情報を取得できませんでした"
            )))
        }

        // The seconds of packet headers before the detection, when the person has switched the pre-roll on. The ring is
        // the helper's and root's; it is copied into this bundle as files the user owns, then recorded and hashed here.
        artifacts.append(contentsOf: capturePrerollArtifacts(in: bundleDir).map(stamped))

        let manifest = ForensicManifest(
            capturedAt: ISO8601DateFormatter().string(from: capturedAt),
            reason: reason,
            suspectedPID: suspectedPID,
            artifacts: artifacts,
            triggerEventID: triggerEventID?.uuidString,
            durationMs: elapsedMs()
        )
        if let data = try? JSONEncoder().encode(manifest) {
            let manifestURL = bundleDir.appendingPathComponent("manifest.json")
            try? AtomicFile.write(data, to: manifestURL)
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
            code: ContainmentSummaryText.evidenceBundleSaved(bundle: bundleName),
            processID: manifest.suspectedPID,
            actionTaken: "evidence_captured",
            parentEventID: trigger,
            evidenceRefs: refs
        )
        ContainmentIncidentTimeline.linkEvidence(to: trigger, refs: refs)
    }

    /// `process/network`: the addresses, ports and states of the sockets the suspected process has open (not what was
    /// sent over them). Skipped, with the reason, when the process is gone or belongs to someone this app cannot read.
    static func captureNetworkArtifact(in bundleDir: URL, pid: Int32) -> ForensicArtifactRecord {
        let name = "process/network"
        let relativePath = "process/network.json"
        func skipped(_ detail: String) -> ForensicArtifactRecord {
            ForensicArtifactRecord(name: name, status: "skipped", detail: detail, relativePath: nil, sha256: nil)
        }
        switch ForensicProcessNetwork.collect(pid: pid) {
        case .exited:
            return skipped("疑わしいプロセス(PID \(pid))は既に終了しているため、ソケットを読めませんでした")
        case .notPermitted:
            return skipped("疑わしいプロセス(PID \(pid))は別のユーザーのプロセスで、ソケットを読む権限がありません")
        case .failed(let code):
            return skipped("疑わしいプロセス(PID \(pid))のソケット一覧を取得できませんでした(エラー \(code))")
        case .sockets(let sockets):
            guard let data = ForensicProcessNetwork.json(sockets) else {
                return skipped("ソケット一覧を JSON にできませんでした")
            }
            let dir = bundleDir.appendingPathComponent("process", isDirectory: true)
            let fileURL = bundleDir.appendingPathComponent(relativePath)
            guard (try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)) != nil,
                  (try? AtomicFile.write(data, to: fileURL)) != nil else {
                return skipped("ソケット一覧をファイルに書けませんでした")
            }
            ForensicChain.flush(fileURL)
            let note = sockets.isEmpty
                ? "疑わしいプロセス(PID \(pid))が開いている TCP・UDP のソケットはありません"
                : "疑わしいプロセス(PID \(pid))が開いている TCP・UDP のソケット \(sockets.count) 件の、アドレスとポートと状態を記録(通信の内容は取らない)"
            return ForensicArtifactRecord(name: name, status: "captured", detail: note, relativePath: relativePath, sha256: sha256Hex(data))
        }
    }

    // MARK: - Pre-roll of packet headers

    /// Asks the helper to copy the ring's last seconds into a folder (the destination path), and answers with what it
    /// did, or nil when the helper could not be reached in time. Set by the app at launch (`PacketPrerollManager`);
    /// nil in the MCP server, which has no helper connection (then the pre-roll is recorded as not captured).
    static var prerollCopier: ((String) -> PacketPrerollCopyResult?)?

    /// Whether the person switched the pre-roll on (the helper still decides whether a ring is running).
    static func prerollSwitchedOn(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: PacketPrerollPolicy.enabledDefaultsKey)
    }

    /// The `packet_preroll` records of a bundle: one `skipped` with the reason when nothing was taken, else the index
    /// (`packet_preroll/index.json`, named `packet_preroll`) and one record per file (`packet_preroll/<file>`), each with
    /// its SHA-256, so the chain covers every byte. The files are pcap files with every packet cut at the end of its headers (no payload: `PacketPrerollTrim`).
    static func capturePrerollArtifacts(
        in bundleDir: URL,
        switchedOn: Bool = prerollSwitchedOn(),
        copier: ((String) -> PacketPrerollCopyResult?)? = prerollCopier
    ) -> [ForensicArtifactRecord] {
        let name = "packet_preroll"
        func skipped(_ detail: String) -> [ForensicArtifactRecord] {
            [ForensicArtifactRecord(name: name, status: "skipped", detail: detail, relativePath: nil, sha256: nil)]
        }
        guard switchedOn else { return skipped("事前のパケット取得はオフです") }
        guard let copier else { return skipped("ヘルパーに接続できないため、事前に取得したパケットをコピーできませんでした") }
        let dir = bundleDir.appendingPathComponent(name, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        } catch {
            return skipped("事前に取得したパケットの保存先のフォルダーを作れませんでした")
        }
        guard let result = copier(dir.path) else {
            return skipped("ヘルパーの応答がなく、事前に取得したパケットをコピーできませんでした")
        }
        if let reason = result.skippedReason {
            // An empty folder left behind says nothing; remove it.
            try? FileManager.default.removeItem(at: dir)
            switch reason {
            case "off": return skipped("ヘルパー側で事前のパケット取得がオフです(Pro のライセンスがないか、設定が反映されていません)")
            case "empty": return skipped("事前の取得はオンですが、直近の時間に取得したファイルがありませんでした")
            case "destination_refused": return skipped("ヘルパーが保存先を受け付けませんでした")
            case "not_pcap": return skipped("事前に取得したファイルが pcap 形式ではなかったため、束に入れませんでした(そのままコピーはしません)")
            case PacketPrerollReason.tcpdumpMissing: return skipped("tcpdump が見つからないため、事前に取得したパケットはありません")
            case PacketPrerollReason.noDefaultInterface: return skipped("ネットワークに接続していなかったため、事前に取得したパケットはありません")
            case PacketPrerollReason.tooManyRestarts: return skipped("tcpdump が続けて終了して取得を止めていたため、事前に取得したパケットはありません")
            default: return skipped("事前の取得が動いていなかったため、コピーできませんでした")
            }
        }
        var records: [ForensicArtifactRecord] = []
        var indexEntries: [[String: Any]] = []
        for entry in result.files {
            let fileURL = dir.appendingPathComponent(entry.name)
            guard let data = try? Data(contentsOf: fileURL, options: .mappedIfSafe) else { continue }
            let hash = sha256Hex(data)
            let rel = "\(name)/\(entry.name)"
            records.append(ForensicArtifactRecord(
                name: rel, status: "captured",
                detail: "事前に取得したパケットを、各パケットをヘッダの終わりで切った形で \(entry.size) バイト記録(通信の内容は入らない)",
                relativePath: rel, sha256: hash
            ))
            indexEntries.append(["file": entry.name, "bytes": Int(entry.size), "sha256": hash])
        }
        guard !records.isEmpty else {
            try? FileManager.default.removeItem(at: dir)
            return skipped("事前に取得したパケットのファイルを読み取れませんでした")
        }
        let index: [String: Any] = [
            "ringSnapLength": PacketPrerollPolicy.snapLength,
            "cutAt": "transport_header_end",
            "refusedFiles": result.refusedCount,
            "droppedFiles": result.droppedCount,
            "droppedBytes": Int(result.droppedBytes),
            "files": indexEntries,
        ]
        guard let indexData = try? JSONSerialization.data(withJSONObject: index, options: [.prettyPrinted, .sortedKeys]),
              (try? AtomicFile.write(indexData, to: dir.appendingPathComponent("index.json"))) != nil else {
            return records
        }
        ForensicChain.flush(dir.appendingPathComponent("index.json"))
        var note = "事前に取得したパケットのファイル \(records.count) 件を、各パケットをヘッダの終わりで切った形で記録(通信の内容は入らない)"
        if result.refusedCount > 0 { note += "。pcap 形式でない \(result.refusedCount) 件は入れていません" }
        if result.droppedCount > 0 { note += "。上限のため古い \(result.droppedCount) 件(\(result.droppedBytes) バイト)は含めていません" }
        let summary = ForensicArtifactRecord(name: name, status: "captured", detail: note, relativePath: "\(name)/index.json", sha256: sha256Hex(indexData))
        return [summary] + records
    }

    private static func writeTextArtifact(
        in bundleDir: URL, relativePath: String, name: String,
        content: String?, capturedNote: String, skippedNote: String
    ) -> ForensicArtifactRecord {
        guard let content, !content.isEmpty else {
            return ForensicArtifactRecord(name: name, status: "skipped", detail: skippedNote, relativePath: nil, sha256: nil)
        }
        let fileURL = bundleDir.appendingPathComponent(relativePath)
        guard (try? AtomicFile.write(content, to: fileURL)) != nil else {
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
    static func bundlesPayload(witness: String? = nil) -> MCPForensicEvidenceBundlesPayload {
        guard let root = evidenceRoot() else { return MCPForensicEvidenceBundlesPayload(bundles: []) }
        return bundlesPayload(root: root, witness: witness)
    }

    /// The end of the chain, and the check of a head kept outside this Mac against it (`ForensicChain.checkWitness`),
    /// for the tools that return `evidenceChecks` or the bundle list. `witness` is only checked when given.
    static func chainEndPayload(witness: String? = nil) -> (head: MCPChainHeadPayload?, witness: String?) {
        guard let root = evidenceRoot() else { return (nil, witness == nil ? nil : "invalid") }
        return chainEnd(root: root, witness: witness)
    }

    static func chainEnd(root: URL, witness: String?) -> (head: MCPChainHeadPayload?, witness: String?) {
        let chain = ForensicChain.load(root: root)
        let head = ForensicChain.head(chain: chain).map { MCPChainHeadPayload(seq: $0.seq, chain: $0.chain) }
        return (head, witness.map { ForensicChain.checkWitness($0, chain: chain) })
    }

    /// How the bundles named by timeline records stand against the anchor chain right now (see `ForensicChain.check`).
    /// Empty when no record points at a bundle.
    static func checkEvidenceRefs(_ refs: [ContainmentEvidenceRef]) -> [MCPEvidenceCheckPayload] {
        guard !refs.isEmpty, let root = evidenceRoot() else { return [] }
        return ForensicChain.check(refs: refs, root: root, chain: ForensicChain.load(root: root))
    }

    static func bundlesPayload(root: URL, limit: Int = 20, witness: String? = nil) -> MCPForensicEvidenceBundlesPayload {
        let chain = ForensicChain.load(root: root)
        let end = chainEnd(root: root, witness: witness)
        return MCPForensicEvidenceBundlesPayload(
            bundles: listBundles(root: root, limit: limit), chainOk: chain.chainOK, chainBrokenAt: chain.brokenAt,
            missingBundles: ForensicChain.missingBundles(root: root, chain: chain),
            chainHead: end.head, chainWitness: end.witness
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
            process.waitUntilExitWithoutRunLoop()
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
    /// Milliseconds from the start of the capture to the moment this artifact was done. Absent in older manifests.
    var elapsedMs: Int? = nil
}

struct ForensicManifest: Codable {
    let capturedAt: String
    let reason: String
    let suspectedPID: Int32?
    let artifacts: [ForensicArtifactRecord]
    /// The timeline record of the detection this bundle was saved for, when the caller knew it. Absent in older
    /// manifests; the SHA-256 chain covers it like every other byte of the file.
    var triggerEventID: String? = nil
    /// Milliseconds the whole capture took (until the manifest was built). Absent in older manifests.
    var durationMs: Int? = nil
}

public struct ForensicBundleSummary: Codable, Equatable {
    public let bundleDir: String
    public let capturedAt: String
    public let reason: String
    public let suspectedPID: Int32?
    public let capturedArtifactCount: Int
    public let skippedArtifactCount: Int
    /// `verified`, `manifest_altered`, `artifact_altered:<name>`, `artifact_missing:<name>`, `anchor_removed` (the chain has
    /// a start mark and the bundle was captured after it, but its line is gone) or `not_anchored` (a bundle with no entry in
    /// the chain: captured before the chain existed, or the chain has no start mark).
    public var integrity: String = "not_anchored"
}

/// The evidence bundles as a chain. Every bundle's manifest hash is written to `chain.log` beside the bundles, each
/// line carrying the hash of the line before it, so a manifest rewritten after the fact, a line removed or edited,
/// or a whole bundle deleted shows up when the chain is read. It is tamper-EVIDENT, not tamper-proof: someone who
/// can rewrite the folder and the log together can still forge a consistent history.
///
/// Two things close the gaps the chain alone leaves:
/// - A new log starts with a start mark (a line for the bundle `@genesis`). With it, a bundle captured after the log
///   began but missing from it is `anchor_removed` (its line was cut off the end), which a bundle from before the log
///   (`not_anchored`) is not.
/// - The head of the chain (`seq`, the number of lines, and the hash of the last one) can be kept outside this Mac, and
///   a later `witness` (`SEQ:HASH`) is checked against the log: a log cut back to fewer lines is `truncated`, one
///   whose line `SEQ` differs is `diverged`. The head of each new line is also written to the system log.
enum ForensicChain {
    static let fileName = "chain.log"
    static let genesis = "GENESIS"
    /// The bundle name of the start mark. No real bundle has it (bundle names start with a time).
    static let startMarkBundle = "@genesis"
    static let startMarkManifestSHA = String(repeating: "0", count: 64)

    struct Entry: Equatable {
        let time: String
        let bundle: String
        let manifestSHA: String
        let prev: String
        let chain: String
    }

    /// The end of the chain: the number of lines (the start mark counts) and the hash of the last one.
    struct Head: Equatable {
        let seq: Int
        let chain: String
    }

    struct Loaded: Equatable {
        /// Every line that follows, the start mark included.
        var entries: [Entry] = []
        /// The first bundle whose line does not follow from the one before it (or does not parse).
        var brokenAt: String? = nil
        var chainOK: Bool { brokenAt == nil }
        /// The lines of bundles: the start mark is not one.
        var bundleEntries: [Entry] { entries.filter { $0.bundle != ForensicChain.startMarkBundle } }
        /// When the log began, if it starts with the start mark (older logs do not).
        var startMarkTime: String? { entries.first.flatMap { $0.bundle == ForensicChain.startMarkBundle ? $0.time : nil } }
        func anchored(_ bundle: String) -> Entry? {
            guard bundle != ForensicChain.startMarkBundle else { return nil }
            return entries.last { $0.bundle == bundle }
        }
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

    // MARK: - Head and witness

    /// The end of the chain as it reads now. nil when the log is empty or does not check out (the head of a broken log
    /// would be the head of what is left of it).
    static func head(chain: Loaded) -> Head? {
        guard chain.chainOK, let last = chain.entries.last else { return nil }
        return Head(seq: chain.entries.count, chain: last.chain)
    }

    /// A head kept outside this Mac, in the form `SEQ:HASH` (`SEQ` from 1, `HASH` the 64 hex digits of the chain hash of
    /// that line), against the log as it is now:
    /// `consistent` (line `SEQ` has that hash, so the log still holds the history up to there), `truncated` (the log
    /// has fewer than `SEQ` lines), `diverged` (line `SEQ` has another hash: the history up to there was rewritten),
    /// `invalid` (not that form) or `chain_broken` (the log does not check out; the witness is not compared).
    static func checkWitness(_ witness: String, chain: Loaded) -> String {
        let parts = witness.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2, let seq = Int(parts[0]), seq >= 1,
              parts[1].count == 64, parts[1].allSatisfy({ $0.isHexDigit }) else { return "invalid" }
        guard chain.chainOK else { return "chain_broken" }
        guard chain.entries.count >= seq else { return "truncated" }
        return chain.entries[seq - 1].chain == parts[1].lowercased() ? "consistent" : "diverged"
    }

    // MARK: - Writing

    /// The line the system log gets for a new bundle line, so the head of the chain also exists outside this folder.
    static func systemLogMessage(bundle: String, manifestSHA: String, seq: Int, chain: String) -> String {
        "bundle=\(bundle) manifest_sha256=\(manifestSHA) seq=\(seq) chain=\(chain)"
    }

    /// Appends the anchor of one bundle. Returns false when the log could not be written. A log that does not exist yet
    /// (or is empty) starts with the start mark, whose time is `capturedAt` so that this bundle counts as made after it
    /// (`startMark: false` is for tests of older logs). After the line is on disk the new head goes to the system log
    /// (`logger`, best effort, with a time limit; `logToSystem: false` in tests).
    @discardableResult
    static func record(root: URL, bundleName: String, capturedAt: String, manifestData: Data,
                       startMark: Bool = true, logToSystem: Bool = true) -> Bool {
        let loaded = load(root: root)
        // A broken chain is not extended silently: the new line would hide where it broke.
        guard loaded.chainOK else { return false }
        let url = root.appendingPathComponent(fileName)
        // A log that has content but could not be read is not a new log: it is not started over.
        if loaded.entries.isEmpty,
           let size = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? NSNumber, size.intValue > 0 { return false }
        var prev = loaded.entries.last?.chain ?? genesis
        var seq = loaded.entries.count
        var text = ""
        if loaded.entries.isEmpty && startMark {
            let mark = chainHash(time: capturedAt, bundle: startMarkBundle, manifestSHA: startMarkManifestSHA, prev: prev)
            text += "\(capturedAt) \(startMarkBundle) \(startMarkManifestSHA) \(prev) \(mark)\n"
            prev = mark
            seq += 1
        }
        let manifestSHA = sha256Hex(manifestData)
        let chain = chainHash(time: capturedAt, bundle: bundleName, manifestSHA: manifestSHA, prev: prev)
        text += "\(capturedAt) \(bundleName) \(manifestSHA) \(prev) \(chain)\n"
        seq += 1
        if !FileManager.default.fileExists(atPath: url.path) {
            guard FileManager.default.createFile(atPath: url.path, contents: nil, attributes: [.posixPermissions: 0o600]) else { return false }
        }
        guard let handle = try? FileHandle(forWritingTo: url) else { return false }
        defer { try? handle.close() }
        do {
            try handle.seekToEnd()
            try handle.write(contentsOf: Data(text.utf8))
            try handle.synchronize()
        } catch { return false }
        if logToSystem {
            _ = OverlayExposure.runWithTimeout("/usr/bin/logger", ["-t", "roamswitch-evidence",
                systemLogMessage(bundle: bundleName, manifestSHA: manifestSHA, seq: seq, chain: chain)], timeout: 3)
        }
        return true
    }

    // MARK: - Reading

    /// The time in a manifest (`2026-10-20T00:00:00Z`) or at the start of a bundle name (`20261020T000000Z-...`).
    static func date(fromISO text: String) -> Date? { ISO8601DateFormatter().date(from: text) }

    static func date(fromBundleName name: String) -> Date? {
        guard name.count >= 16 else { return nil }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return f.date(from: String(name.prefix(16)))
    }

    /// What a bundle with no line in the chain is: `anchor_removed` when the log has a start mark and the bundle was
    /// captured at or after it (its line should be there, and was cut off), `not_anchored` otherwise (the bundle is from
    /// before the log, or the log has no start mark so the two cannot be told apart). The capture time is the
    /// manifest's, or the bundle name's when the manifest cannot be read.
    static func unanchoredStatus(bundle: String, manifestCapturedAt: String?, chain: Loaded) -> String {
        guard let markTime = chain.startMarkTime, let start = date(fromISO: markTime) else { return "not_anchored" }
        let captured = manifestCapturedAt.flatMap(date(fromISO:)) ?? date(fromBundleName: bundle)
        guard let captured, captured >= start else { return "not_anchored" }
        return "anchor_removed"
    }

    /// One bundle against the chain and its own artifact hashes.
    static func integrity(bundleDir: URL, manifestData: Data, manifest: ForensicManifest, chain: Loaded) -> String {
        guard let entry = chain.anchored(bundleDir.lastPathComponent) else {
            return unanchoredStatus(bundle: bundleDir.lastPathComponent, manifestCapturedAt: manifest.capturedAt, chain: chain)
        }
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
        chain.bundleEntries.map(\.bundle).filter { !FileManager.default.fileExists(atPath: root.appendingPathComponent($0).path) }
    }

    /// Whether each bundle a timeline record points at (`evidenceRefs`) still matches the chain as it is now, one result
    /// per distinct bundle. The statuses are the Linux edition's (`roamswitch-core` `evidence_check`): `matches`,
    /// `bundle_missing` (the chain agrees but the folder is gone), `manifest_altered` (the manifest differs from the one the
    /// chain recorded), `ref_changed` (the hash held by the timeline differs from the chain's), `chain_broken`,
    /// `anchor_removed` (the log has a start mark, the bundle was captured after it and has no line: the line was cut off),
    /// `not_anchored` (no line for the bundle, from before the log or in a log with no start mark) and `unchecked` (the log
    /// cannot be read). Read-only; nothing is stored.
    static func check(refs: [ContainmentEvidenceRef], root: URL, chain: Loaded) -> [MCPEvidenceCheckPayload] {
        let log = root.appendingPathComponent(fileName).path
        let unreadable = FileManager.default.fileExists(atPath: log) && !FileManager.default.isReadableFile(atPath: log)
        var seen: [String] = []
        var out: [MCPEvidenceCheckPayload] = []
        for r in refs where !seen.contains(r.bundle) {
            seen.append(r.bundle)
            let refManifest = refs.first { $0.bundle == r.bundle && $0.artifact == "manifest.json" }?.sha256
            let manifestFile = root.appendingPathComponent(r.bundle).appendingPathComponent("manifest.json")
            let status: String
            if unreadable {
                status = "unchecked"
            } else if !chain.chainOK {
                status = "chain_broken"
            } else if let entry = chain.anchored(r.bundle) {
                if let held = refManifest, held != entry.manifestSHA {
                    status = "ref_changed"
                } else if let data = try? Data(contentsOf: manifestFile) {
                    status = sha256Hex(data) == entry.manifestSHA ? "matches" : "manifest_altered"
                } else if FileManager.default.fileExists(atPath: root.appendingPathComponent(r.bundle).path) {
                    status = "unchecked"
                } else {
                    status = "bundle_missing"
                }
            } else {
                let capturedAt = (try? Data(contentsOf: manifestFile)).flatMap { try? JSONDecoder().decode(ForensicManifest.self, from: $0) }?.capturedAt
                status = unanchoredStatus(bundle: r.bundle, manifestCapturedAt: capturedAt, chain: chain)
            }
            out.append(MCPEvidenceCheckPayload(
                bundle: r.bundle, status: status, stale: status != "matches" && status != "unchecked",
                chainBrokenAt: status == "chain_broken" ? chain.brokenAt : nil
            ))
        }
        return out
    }
}


/// One socket of a process: `proto` is `tcp`, `tcp6`, `udp` or `udp6`; `local` and `remote` are `address:port`
/// (`[address]:port` for IPv6, `*` for the unspecified address, `*:0` for a remote address that is not set);
/// `state` is the TCP state (`LISTEN`, `ESTABLISHED`, ...), left out for UDP, which has none; `fd` is the descriptor.
struct ForensicSocketEntry: Codable, Equatable {
    let proto: String
    let local: String
    let remote: String
    var state: String? = nil
    var fd: Int32? = nil
}

/// The sockets a process has open, read from the process's own tables with `libproc` (`proc_pidinfo`,
/// `proc_pidfdinfo`): the same user's processes only, no privilege needed, nothing is sent and no traffic is read.
enum ForensicProcessNetwork {
    enum Result: Equatable {
        case sockets([ForensicSocketEntry])
        /// The process is not there (any more).
        case exited
        /// The process belongs to another user (or is protected): the list cannot be read from this app.
        case notPermitted
        /// Another failure, with its `errno`.
        case failed(Int32)
    }

    static func collect(pid: Int32) -> Result {
        errno = 0
        let size = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, nil, 0)
        if size <= 0 { return failure(errno) }
        // The descriptor table can grow between the two calls: leave room.
        var fds = [proc_fdinfo](repeating: proc_fdinfo(), count: Int(size) / MemoryLayout<proc_fdinfo>.size + 16)
        errno = 0
        let got = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, &fds, Int32(fds.count * MemoryLayout<proc_fdinfo>.size))
        if got <= 0 { return failure(errno) }
        var out: [ForensicSocketEntry] = []
        for f in fds.prefix(Int(got) / MemoryLayout<proc_fdinfo>.size) where f.proc_fdtype == UInt32(PROX_FDTYPE_SOCKET) {
            var si = socket_fdinfo()
            // A descriptor closed since the list was read is left out; the others are still read.
            let r = proc_pidfdinfo(pid, f.proc_fd, PROC_PIDFDSOCKETINFO, &si, Int32(MemoryLayout<socket_fdinfo>.size))
            if r <= 0 { continue }
            if let entry = entry(from: si, fd: f.proc_fd) { out.append(entry) }
        }
        return .sockets(sorted(out))
    }

    private static func failure(_ code: Int32) -> Result {
        switch code {
        case ESRCH: return .exited
        case EPERM, EACCES: return .notPermitted
        default: return .failed(code)
        }
    }

    /// Fixed order: by descriptor, then by local address.
    static func sorted(_ entries: [ForensicSocketEntry]) -> [ForensicSocketEntry] {
        entries.sorted { a, b in
            let fa = a.fd ?? Int32.max, fb = b.fd ?? Int32.max
            return fa != fb ? fa < fb : (a.local, a.remote) < (b.local, b.remote)
        }
    }

    static func json(_ sockets: [ForensicSocketEntry]) -> Data? {
        struct Payload: Encodable { let sockets: [ForensicSocketEntry] }
        let enc = JSONEncoder()
        enc.outputFormatting = [.sortedKeys, .prettyPrinted]
        return try? enc.encode(Payload(sockets: sockets))
    }

    private static func entry(from si: socket_fdinfo, fd: Int32) -> ForensicSocketEntry? {
        let family = si.psi.soi_family
        guard family == AF_INET || family == AF_INET6 else { return nil }
        let six = family == AF_INET6
        if si.psi.soi_kind == SOCKINFO_TCP {
            let t = si.psi.soi_proto.pri_tcp
            return ForensicSocketEntry(
                proto: six ? "tcp6" : "tcp",
                local: address(t.tcpsi_ini, local: true), remote: address(t.tcpsi_ini, local: false),
                state: tcpState(t.tcpsi_state), fd: fd
            )
        }
        if si.psi.soi_kind == SOCKINFO_IN, si.psi.soi_protocol == IPPROTO_UDP {
            let i = si.psi.soi_proto.pri_in
            return ForensicSocketEntry(
                proto: six ? "udp6" : "udp",
                local: address(i, local: true), remote: address(i, local: false), state: nil, fd: fd
            )
        }
        return nil
    }

    private static func address(_ v: in_sockinfo, local: Bool) -> String {
        let port = UInt16(bigEndian: UInt16(truncatingIfNeeded: local ? v.insi_lport : v.insi_fport))
        let ipv6Only = (v.insi_vflag & UInt8(INI_IPV6)) != 0 && (v.insi_vflag & UInt8(INI_IPV4)) == 0
        if ipv6Only {
            var a = local ? v.insi_laddr.ina_6 : v.insi_faddr.ina_6
            var buf = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
            inet_ntop(AF_INET6, &a, &buf, socklen_t(INET6_ADDRSTRLEN))
            let text = String(cString: buf)
            return (text == "::" ? "*" : "[\(text)]") + ":\(port)"
        }
        var a = local ? v.insi_laddr.ina_46.i46a_addr4 : v.insi_faddr.ina_46.i46a_addr4
        var buf = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        inet_ntop(AF_INET, &a, &buf, socklen_t(INET_ADDRSTRLEN))
        let text = String(cString: buf)
        return (text == "0.0.0.0" ? "*" : text) + ":\(port)"
    }

    private static func tcpState(_ state: Int32) -> String {
        switch state {
        case 0: return "CLOSED"
        case 1: return "LISTEN"
        case 2: return "SYN_SENT"
        case 3: return "SYN_RECEIVED"
        case 4: return "ESTABLISHED"
        case 5: return "CLOSE_WAIT"
        case 6: return "FIN_WAIT_1"
        case 7: return "CLOSING"
        case 8: return "LAST_ACK"
        case 9: return "FIN_WAIT_2"
        case 10: return "TIME_WAIT"
        default: return "UNKNOWN(\(state))"
        }
    }
}
