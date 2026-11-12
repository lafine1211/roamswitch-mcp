// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.31 (build 210).
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

/// Why the vault's record (`.metadata.json`) could not be read. The list is then empty because nothing was read,
/// not because nothing is quarantined, so no reader may call it "0 files".
public enum QuarantineUnreadableReason: String, Equatable {
    /// The file is there but is not a list of records (damaged, cut short, edited by hand).
    case corrupt
    /// This process may not read the file or its folder.
    case permissionDenied = "permission_denied"
    /// Reading failed for another reason (an I/O error, a folder where the file should be).
    case readFailed = "read_failed"

    /// The sentence the window, the menu's tooltip and the MCP answer show, in the app's language.
    var text: String {
        switch self {
        case .corrupt:
            return loc("隔離中のファイルを確認できません。隔離の記録ファイル(.metadata.json)が壊れています。次に隔離するとき、壊れた記録は消さずに別の名前で残します。")
        case .permissionDenied:
            return loc("隔離中のファイルを確認できません。隔離の記録ファイル(.metadata.json)を読む権限がありません。")
        case .readFailed:
            return loc("隔離中のファイルを確認できません。隔離の記録ファイル(.metadata.json)を読み込めませんでした。")
        }
    }
}

/// The vault as read now: the files, or why they could not be read (`files` is then empty).
public struct QuarantineListing: Equatable {
    public let files: [QuarantinedFile]
    public let unreadable: QuarantineUnreadableReason?
}

final class QuarantineManager {
    static let shared = QuarantineManager()

    /// Where ClamAV moves infected files to instead of leaving them in
    /// place. Kept under Application Support (not /tmp) so it survives
    /// reboots and isn't swept by any cleanup tooling.
    var quarantineDirectory: String { quarantineDirectoryURL.path }

    /// Tests point this at a throwaway folder; the app uses the default under Application Support.
    private let directoryOverride: URL?
    /// Where each move is recorded (`begin`, then `done` or `failed` from the files as they are after the move). The
    /// app's journal by default; none for a test folder unless the test gives one.
    private let journal: ActionJournal?

    init(directory: URL? = nil, journal: ActionJournal? = nil) {
        directoryOverride = directory
        self.journal = journal ?? (directory == nil ? AppActionJournal.shared : nil)
    }

    private var quarantineDirectoryURL: URL {
        directoryOverride ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("RoamSwitch/Quarantine", isDirectory: true)
    }

    /// Reading the vault (MCP `get_quarantine_status`, the menu count) must not create it, so the folder is
    /// made only where a file or the metadata is written.
    @discardableResult
    private func ensureQuarantineDirectory() -> String {
        try? FileManager.default.createDirectory(at: quarantineDirectoryURL, withIntermediateDirectories: true)
        return quarantineDirectory
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
        // nil: the record could not be read nor moved aside. The files are still moved and neutralized below, but
        // nothing is saved, so the earlier records are not written over.
        let loaded = loadMetadataForUpdate()
        var entries = loaded ?? []
        let fileManager = FileManager.default
        let qDir = ensureQuarantineDirectory()
        var quarantinedPaths: Set<String> = []

        for line in lines {
            guard let parsed = Self.parseFoundLine(line) else { continue }
            let originalPath = parsed.path
            let threatName = parsed.threat
            let originalFileName = (originalPath as NSString).lastPathComponent

            // 既に別の記録が使っている隔離名(=別ファイル)。同名の別ファイルを「隔離済み」と誤認しないために使う。
            let journalID = journal?.begin(.quarantine, target: originalPath, origin: .auto, trigger: threatName)
            // Read back after the move: in the folder, and gone from where it was.
            func finishJournal(_ destination: String?) {
                guard let journalID, let journal else { return }
                if let destination, fileManager.fileExists(atPath: destination), !fileManager.fileExists(atPath: originalPath) {
                    journal.finish(journalID, .done)
                } else {
                    journal.finish(journalID, .failed, detail: "the file is not in the quarantine folder")
                }
            }
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
                finishJournal(nil)
                continue
            }

            finishJournal(destPath)
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
        if loaded != nil { saveMetadata(entries) }
        return quarantinedPaths
    }

    func listQuarantinedFiles() -> [QuarantinedFile] {
        listing().files
    }

    /// The quarantined files, or why the record of them could not be read. A record that is not there yet
    /// (nothing was ever quarantined) is an empty, readable vault.
    func listing() -> QuarantineListing {
        let entries: [MetadataEntry]
        switch readMetadata() {
        case .missing: entries = []
        case .entries(let list): entries = list
        case .unreadable(let reason): return QuarantineListing(files: [], unreadable: reason)
        }
        let fileManager = FileManager.default
        let files: [QuarantinedFile] = entries.compactMap { entry in
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
        return QuarantineListing(files: files, unreadable: nil)
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

    private enum MetadataRead {
        case missing
        case entries([MetadataEntry])
        case unreadable(QuarantineUnreadableReason)
    }

    /// `FileManager.contents(atPath:)` returns nil both for a file that is not there and for one that cannot be
    /// read, and a failed decode used to be `[]` as well: a damaged or unreadable record read as "no files".
    private func readMetadata() -> MetadataRead {
        let data: Data
        do {
            data = try Data(contentsOf: URL(fileURLWithPath: metadataPath))
        } catch {
            return Self.classifyReadError(error).map { .unreadable($0) } ?? .missing
        }
        guard let entries = try? JSONDecoder().decode([MetadataEntry].self, from: data) else {
            return .unreadable(.corrupt)
        }
        return .entries(entries)
    }

    /// nil: the file (or its folder) is not there. Otherwise why it could not be read.
    static func classifyReadError(_ error: Error) -> QuarantineUnreadableReason? {
        let ns = error as NSError
        let posix = (ns.userInfo[NSUnderlyingErrorKey] as? NSError).flatMap { $0.domain == NSPOSIXErrorDomain ? $0.code : nil }
            ?? (ns.domain == NSPOSIXErrorDomain ? ns.code : nil)
        if ns.domain == NSCocoaErrorDomain, ns.code == NSFileReadNoSuchFileError || ns.code == NSFileNoSuchFileError { return nil }
        if posix == Int(ENOENT) || posix == Int(ENOTDIR) { return nil }
        if ns.domain == NSCocoaErrorDomain, ns.code == NSFileReadNoPermissionError { return .permissionDenied }
        if posix == Int(EACCES) || posix == Int(EPERM) { return .permissionDenied }
        return .readFailed
    }

    /// The records for a read-modify-write. A record that cannot be read is moved aside
    /// (`.metadata.json.corrupt-<time>-<n>`) and never written over; `nil` when it could not be moved either, and the
    /// caller then must not save (the next save would replace every earlier record with the new ones only).
    private func loadMetadataForUpdate() -> [MetadataEntry]? {
        switch readMetadata() {
        case .missing: return []
        case .entries(let list): return list
        case .unreadable(let reason):
            let stamp: String = {
                let f = DateFormatter()
                f.locale = Locale(identifier: "en_US_POSIX")
                f.dateFormat = "yyyyMMdd_HHmmss"
                return f.string(from: Date())
            }()
            let aside = quarantineDirectory + "/.metadata.json.corrupt-\(stamp)-\(UInt32.random(in: 0...UInt32.max))"
            do {
                try FileManager.default.moveItem(atPath: metadataPath, toPath: aside)
                NSLog("RoamSwitch QuarantineManager: the quarantine record was unreadable (\(reason.rawValue)); kept as \(aside)")
                // The newest three are kept.
                StoredRecordFile.pruneCopies(dir: quarantineDirectory, prefix: ".metadata.json.corrupt-")
                return []
            } catch {
                NSLog("RoamSwitch QuarantineManager: the quarantine record was unreadable (\(reason.rawValue)) and could not be moved aside: \(error.localizedDescription); not saving")
                return nil
            }
        }
    }

    /// Lookups only (never saved back): an unreadable record has nothing to find.
    private func loadMetadata() -> [MetadataEntry] {
        if case .entries(let list) = readMetadata() { return list }
        return []
    }

    private func saveMetadata(_ entries: [MetadataEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        ensureQuarantineDirectory()
        try? AtomicFile.write(data, to: URL(fileURLWithPath: metadataPath))
    }

    private func removeMetadata(for file: QuarantinedFile) {
        let fileName = (file.quarantinedPath as NSString).lastPathComponent
        guard var entries = loadMetadataForUpdate() else { return }
        if let idx = entries.firstIndex(where: { $0.quarantinedFileName == fileName && $0.originalPath == file.originalPath }) {
            entries.remove(at: idx)
        } else {
            entries.removeAll { $0.quarantinedFileName == fileName }
        }
        saveMetadata(entries)
    }
}
