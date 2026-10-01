// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.10.17 (build 135).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// A file ClamAV flagged and moved out of harm's way, kept until the user
/// decides what to do with it. Nothing is ever permanently deleted without
/// the user explicitly choosing "完全に削除" — a false positive should
/// never mean silent, unrecoverable data loss.
public struct QuarantinedFile: Identifiable, Equatable {
    public let id: String  // quarantined file path — unique per file
    public let originalPath: String
    public let quarantinedPath: String
    public let threatName: String
    public let quarantinedAt: Date
    public let fileSize: Int64
}

final class QuarantineManager {
    static let shared = QuarantineManager()

    /// Where ClamAV moves infected files to instead of leaving them in
    /// place. Kept under Application Support (not /tmp) so it survives
    /// reboots and isn't swept by any cleanup tooling.
    var quarantineDirectory: String {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("RoamSwitch/Quarantine", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.path
    }

    /// Sidecar metadata file recording where each quarantined file came
    /// from and why — ClamAV's --move only preserves the file itself, not
    /// its original location or the detected signature name.
    private var metadataPath: String {
        quarantineDirectory + "/.metadata.json"
    }

    private struct MetadataEntry: Codable {
        let id: String?
        let originalPath: String
        let quarantinedFileName: String
        let threatName: String
        let quarantinedAt: Date
        /// 隔離前のパーミッション(下位9bit)。復元時に戻す。古い記録には無い(nil → 0644)。
        var originalPermissions: Int? = nil
    }

    /// clamscan の検出行 `<path>: <Signature> FOUND` を分解する。パス自体に ": " が含まれ得るので、
    /// 先頭の ": " ではなく末尾の " FOUND" を外してから「最後の ": "」で分ける(シグネチャ名は空白・コロンを含まない)。
    static func parseFoundLine(_ line: String) -> (path: String, threat: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasSuffix(" FOUND") else { return nil }
        let body = String(trimmed.dropLast(" FOUND".count))
        guard let sep = body.range(of: ": ", options: .backwards) else { return nil }
        let path = String(body[body.startIndex..<sep.lowerBound])
        let threat = String(body[sep.upperBound...])
        guard !path.isEmpty, !threat.isEmpty else { return nil }
        return (path, threat)
    }

    /// Call right after a clamscan run with --move completes, passing the
    /// "path: Threat.Name FOUND" lines it printed — before the move, those
    /// paths were still the files' original locations. Also called directly
    /// by `WebMailDownloadGuard` for a `StaticSignatureScanner` hit, where
    /// the move below is the only thing that actually relocates the file.
    ///
    /// Returns the `originalPath`s that were genuinely confirmed quarantined
    /// (the file now exists at `destPath` and no longer at `originalPath`)
    /// — a path from `lines` that's missing from the returned set means its
    /// move failed and the malicious file is still sitting untouched at its
    /// original location. Callers that tell the user "quarantined" must
    /// check this per file rather than assuming the whole batch succeeded.
    /// `try?` silently swallowing `moveItem`'s error (permission denied,
    /// locked file, read-only volume, ...) used to mean a failed quarantine
    /// attempt still got recorded and reported as a success. A file whose
    /// `originalPath` no longer exists when this runs (e.g. clamscan's own
    /// `--move` already relocated it) is treated as already-quarantined,
    /// not a failure — there's nothing left to move.
    @discardableResult
    func recordQuarantinedFiles(fromFoundLines lines: [String]) -> Set<String> {
        var entries = loadMetadata()
        let fileManager = FileManager.default
        let qDir = quarantineDirectory
        var quarantinedPaths: Set<String> = []

        for line in lines {
            guard let parsed = Self.parseFoundLine(line) else { continue }
            let originalPath = parsed.path
            let threatName = parsed.threat
            let originalFileName = (originalPath as NSString).lastPathComponent

            // 既に別の記録が使っている隔離名(=別ファイル)。同名の別ファイルを「隔離済み」と誤認しないために使う。
            let takenNames = Set(entries.map { $0.quarantinedFileName })
            var actualQuarantinedName = originalFileName
            var destPath = qDir + "/" + actualQuarantinedName

            if fileManager.fileExists(atPath: originalPath) {
                // 元の場所にまだある(clamscan --move が失敗した、または直接呼ばれた)。空いている名前へ移す。
                var counter = 0
                while fileManager.fileExists(atPath: destPath) || takenNames.contains(actualQuarantinedName) {
                    counter += 1
                    let ext = (originalFileName as NSString).pathExtension
                    let base = (originalFileName as NSString).deletingPathExtension
                    let suffix = "_\(Int(Date().timeIntervalSince1970))" + (counter > 1 ? "_\(counter)" : "")
                    actualQuarantinedName = ext.isEmpty ? "\(base)\(suffix)" : "\(base)\(suffix).\(ext)"
                    destPath = qDir + "/" + actualQuarantinedName
                }
                do {
                    try fileManager.moveItem(atPath: originalPath, toPath: destPath)
                } catch {
                    NSLog("RoamSwitch QuarantineManager: failed to move \(originalPath) to quarantine: \(error.localizedDescription)")
                }
            } else if takenNames.contains(actualQuarantinedName),
                      !entries.contains(where: { $0.quarantinedFileName == actualQuarantinedName && $0.originalPath == originalPath }) {
                // 元ファイルは既に無いが、隔離フォルダの同名ファイルは別の元パスの記録のもの。
                // どちらのファイルか判別できないので「隔離済み」とは記録しない。
                NSLog("RoamSwitch QuarantineManager: \(originalPath) is gone, but the same-named quarantine file belongs to a different record; not claiming it")
                continue
            }

            guard fileManager.fileExists(atPath: destPath) else {
                // The move either failed above, or never ran because
                // `originalPath` was already gone for some other reason —
                // either way, nothing is quarantined at `destPath`, so this
                // path isn't added to `quarantinedPaths`.
                continue
            }
            quarantinedPaths.insert(originalPath)

            // 復元時に戻せるよう、無効化の前に元のパーミッションを控える。
            let originalPermissions = (try? fileManager.attributesOfItem(atPath: destPath)[.posixPermissions] as? NSNumber)?
                .map { $0.intValue & 0o777 }

            // Neutralize threat by removing all execute & read permissions (chmod 000)
            try? fileManager.setAttributes([.posixPermissions: 0o000], ofItemAtPath: destPath)

            // Prevent duplicate records for the same file within a 60-second window
            if entries.contains(where: { $0.originalPath == originalPath && abs($0.quarantinedAt.timeIntervalSinceNow) < 60 }) {
                continue
            }

            entries.append(MetadataEntry(
                id: UUID().uuidString,
                originalPath: originalPath,
                quarantinedFileName: actualQuarantinedName,
                threatName: threatName,
                quarantinedAt: Date(),
                originalPermissions: originalPermissions
            ))
        }
        saveMetadata(entries)
        return quarantinedPaths
    }

    func listQuarantinedFiles() -> [QuarantinedFile] {
        let entries = loadMetadata()
        let fileManager = FileManager.default
        return entries.compactMap { entry in
            let quarantinedPath = quarantineDirectory + "/" + entry.quarantinedFileName
            guard fileManager.fileExists(atPath: quarantinedPath) else { return nil }
            let size = (try? fileManager.attributesOfItem(atPath: quarantinedPath)[.size] as? Int64) ?? 0
            return QuarantinedFile(
                id: quarantinedPath,
                originalPath: entry.originalPath,
                quarantinedPath: quarantinedPath,
                threatName: entry.threatName,
                quarantinedAt: entry.quarantinedAt,
                fileSize: size ?? 0
            )
        }
        .sorted { $0.quarantinedAt > $1.quarantinedAt }
    }

    /// Moves a quarantined file back to its original location. Fails if
    /// something already exists there (never silently overwrites).
    @discardableResult
    func restore(_ file: QuarantinedFile) -> Result<Void, Error> {
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: file.originalPath) else {
            return .failure(NSError(domain: "Quarantine", code: 1, userInfo: [
                NSLocalizedDescriptionKey: loc("復元先に既に同名のファイルが存在するため、復元できませんでした。")
            ]))
        }
        do {
            let originalDir = (file.originalPath as NSString).deletingLastPathComponent
            try fileManager.createDirectory(atPath: originalDir, withIntermediateDirectories: true)
            // 記録してある元のパーミッションへ戻す(記録が無い古い隔離は 0644)。setuid/setgid は付けない。
            let fileName = (file.quarantinedPath as NSString).lastPathComponent
            let recorded = loadMetadata().first { $0.quarantinedFileName == fileName && $0.originalPath == file.originalPath }?.originalPermissions
            try? fileManager.setAttributes([.posixPermissions: (recorded ?? 0o644) & 0o777], ofItemAtPath: file.quarantinedPath)
            try fileManager.moveItem(atPath: file.quarantinedPath, toPath: file.originalPath)
            removeMetadata(for: file)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    @discardableResult
    func deletePermanently(_ file: QuarantinedFile) -> Result<Void, Error> {
        do {
            // Restore write permissions in case 000 permissions impede deletion
            try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: file.quarantinedPath)
            try FileManager.default.removeItem(atPath: file.quarantinedPath)
            removeMetadata(for: file)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Metadata persistence

    private func loadMetadata() -> [MetadataEntry] {
        guard let data = FileManager.default.contents(atPath: metadataPath),
              let entries = try? JSONDecoder().decode([MetadataEntry].self, from: data) else {
            return []
        }
        return entries
    }

    private func saveMetadata(_ entries: [MetadataEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: URL(fileURLWithPath: metadataPath), options: .atomic)
    }

    private func removeMetadata(for file: QuarantinedFile) {
        let fileName = (file.quarantinedPath as NSString).lastPathComponent
        var entries = loadMetadata()
        if let idx = entries.firstIndex(where: { $0.quarantinedFileName == fileName && $0.originalPath == file.originalPath }) {
            entries.remove(at: idx)
        } else {
            entries.removeAll { $0.quarantinedFileName == fileName }
        }
        saveMetadata(entries)
    }
}
