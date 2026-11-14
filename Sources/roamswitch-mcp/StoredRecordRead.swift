// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.0.1 (build 217).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Why a stored record could not be read.
public enum StoredRecordFailure: String, Codable, Equatable {
    /// It is there but is not what was saved (damaged, cut short, written by a version with another shape).
    case corrupt
    /// This process may not read it.
    case permissionDenied = "permission_denied"
    /// Reading failed for another reason.
    case readFailed = "read_failed"
}

/// A stored record as read now. `missing` is a record never saved (an empty, readable list); `unreadable` is one that
/// is there and could not be read, so a reader must not call it empty and a writer must not save over it.
public enum StoredRecordRead<T> {
    case missing
    case loaded(T)
    case unreadable(StoredRecordFailure)

    /// The value, or `empty` when there is none to read (missing or unreadable).
    public func value(or empty: T) -> T {
        if case .loaded(let v) = self { return v }
        return empty
    }

    public var isUnreadable: Bool {
        if case .unreadable = self { return true }
        return false
    }
}

/// Records kept in files (the helper's state under `/Library/Application Support/RoamSwitch`, the app's under the
/// user's Application Support).
///
/// The old pattern was "decode, `[]` on any failure, add the new entry, save": a damaged or unreadable file read as
/// "nothing recorded", every reader showed an empty list, and the next save replaced every earlier entry with the new
/// one. Here a reader is told the file could not be read, and a read-modify-write first keeps a copy of the bad file
/// next to it (`<name>.corrupt-<unix time>`), or does not save at all when no copy could
/// be made.
enum StoredRecordFile {
    static func read<T: Decodable>(_ type: T.Type, path: String) -> StoredRecordRead<T> {
        let data: Data
        do {
            data = try Data(contentsOf: URL(fileURLWithPath: path))
        } catch {
            return classify(error).map { .unreadable($0) } ?? .missing
        }
        // A key that appears twice in one object is not what any writer of ours saved (JSONEncoder never does it), and
        // the decoder would silently keep one of the two values: the file was edited or damaged, so it is corrupt.
        if StoredRecordJSON.hasDuplicateKeys(data) { return .unreadable(.corrupt) }
        guard let value = try? JSONDecoder().decode(type, from: data) else { return .unreadable(.corrupt) }
        return .loaded(value)
    }

    /// The base of a read-modify-write. A missing file is `empty`. An unreadable one is copied aside first and the
    /// write starts from `empty`; `nil` when the copy could not be made, and the caller must then not save.
    static func loadForUpdate<T: Decodable>(_ type: T.Type, path: String, empty: T, now: Date = Date()) -> T? {
        switch read(type, path: path) {
        case .missing: return empty
        case .loaded(let v): return v
        case .unreadable(let failure):
            guard let copy = keepCopy(path: path, now: now) else {
                NSLog("RoamSwitch: %@ could not be read (%@) nor copied aside; not saving over it", path, failure.rawValue)
                return nil
            }
            NSLog("RoamSwitch: %@ could not be read (%@); kept as %@", path, failure.rawValue, copy)
            return empty
        }
    }

    static let corruptInfix = ".corrupt-"

    /// For a writer about to replace (or remove) `path` with what it decided from a read that may have found nothing:
    /// a file there that cannot be read as `type` is copied aside first. false when it could not be copied; the caller
    /// then must not replace it.
    static func mayReplace<T: Decodable>(_ type: T.Type, path: String, now: Date = Date()) -> Bool {
        guard case .unreadable(let failure) = read(type, path: path) else { return true }
        guard let copy = keepCopy(path: path, now: now) else {
            NSLog("RoamSwitch: %@ could not be read (%@) nor copied aside; not replacing it", path, failure.rawValue)
            return false
        }
        NSLog("RoamSwitch: %@ could not be read (%@); kept as %@", path, failure.rawValue, copy)
        return true
    }

    /// The helper's error reply for a record it could not read, so the app tells it from a failed connection and says
    /// "cannot be checked" rather than keeping quiet. `<prefix><failure>`.
    static let unreadableReplyPrefix = "stored record unreadable: "

    static func unreadableReply(_ failure: StoredRecordFailure) -> String { unreadableReplyPrefix + failure.rawValue }

    static func isUnreadableReply(_ message: String?) -> Bool { message?.hasPrefix(unreadableReplyPrefix) == true }

    /// Copies the bad file to `<path>.corrupt-<unix time>` (0600), keeping the newest `keep`. Identical content to
    /// the newest existing copy is not copied again, so a file that stays corrupt cannot push older evidence out.
    /// Returns the copy's path, if any.
    @discardableResult
    static func keepCopy(path: String, keep: Int = copiesKept, now: Date = Date()) -> String? {
        let fm = FileManager.default
        let dir = (path as NSString).deletingLastPathComponent
        let base = (path as NSString).lastPathComponent
        let prefix = base + corruptInfix
        func copies() -> [(Int, String)] {
            ((try? fm.contentsOfDirectory(atPath: dir)) ?? [])
                .compactMap { name -> (Int, String)? in
                    guard name.hasPrefix(prefix), let n = Int(name.dropFirst(prefix.count)) else { return nil }
                    return (n, dir + "/" + name)
                }
                .sorted { $0.0 > $1.0 }
        }
        let existing = copies()
        var copyPath: String?
        let bad = fm.contents(atPath: path)
        if let newest = existing.first, let bad, fm.contents(atPath: newest.1) == bad {
            copyPath = newest.1
        } else {
            var stamp = Int(now.timeIntervalSince1970)
            if let newest = existing.first, stamp <= newest.0 { stamp = newest.0 + 1 }
            let dest = dir + "/" + prefix + String(stamp)
            if let bad {
                guard fm.createFile(atPath: dest, contents: bad, attributes: [.posixPermissions: 0o600]) else { return nil }
                chmod(dest, 0o600)
                copyPath = dest
            } else if (try? fm.copyItem(atPath: path, toPath: dest)) != nil {
                chmod(dest, 0o600)
                copyPath = dest
            }
        }
        for (_, p) in copies().dropFirst(keep) { try? fm.removeItem(atPath: p) }
        return copyPath
    }

    /// How many copies of a bad record are kept, per record (the same as the Linux edition's `json_state`).
    static let copiesKept = 3

    /// Removes all but the newest `keep` files in `dir` whose names start with `prefix`, for the copies that are not made
    /// by `keepCopy` (`VulnerabilityAcceptance`, `QuarantineManager`). Their names carry the time after `prefix` in a form
    /// that sorts (`yyyyMMdd…`), so the newest are the last by name. (A moved file keeps its old modification time.)
    static func pruneCopies(dir: String, prefix: String, keep: Int = copiesKept) {
        let fm = FileManager.default
        let names = ((try? fm.contentsOfDirectory(atPath: dir)) ?? []).filter { $0.hasPrefix(prefix) }.sorted()
        for name in names.dropLast(keep) { try? fm.removeItem(atPath: dir + "/" + name) }
    }

    /// `nil`: the file (or its folder) is not there. Otherwise why it could not be read.
    static func classify(_ error: Error) -> StoredRecordFailure? {
        let ns = error as NSError
        let posix = (ns.userInfo[NSUnderlyingErrorKey] as? NSError).flatMap { $0.domain == NSPOSIXErrorDomain ? $0.code : nil }
            ?? (ns.domain == NSPOSIXErrorDomain ? ns.code : nil)
        if ns.domain == NSCocoaErrorDomain, ns.code == NSFileReadNoSuchFileError || ns.code == NSFileNoSuchFileError { return nil }
        if posix == Int(ENOENT) || posix == Int(ENOTDIR) { return nil }
        if ns.domain == NSCocoaErrorDomain, ns.code == NSFileReadNoPermissionError { return .permissionDenied }
        if posix == Int(EACCES) || posix == Int(EPERM) { return .permissionDenied }
        return .readFailed
    }
}

/// Records kept in the app's preferences. Same rules as `StoredRecordFile`; the copy of a value that could not be read
/// is `<key>.unreadable` (`.unreadable.<unix time>` when that is taken by another value).
enum StoredRecordDefaults {
    /// Reads without writing anything (the MCP server, a status reader).
    static func peek<T: Decodable>(_ type: T.Type, key: String, defaults: UserDefaults) -> StoredRecordRead<T> {
        guard let raw = defaults.object(forKey: key) else { return .missing }
        guard let data = raw as? Data, !StoredRecordJSON.hasDuplicateKeys(data),
              let value = try? JSONDecoder().decode(type, from: data) else { return .unreadable(.corrupt) }
        return .loaded(value)
    }

    /// Reads for the owner of the value: one that cannot be read is first copied to `<key>.unreadable`, so a later
    /// save cannot lose it. The same value read again (a restart before anything was saved) is not copied twice.
    static func load<T: Decodable>(_ type: T.Type, key: String, defaults: UserDefaults, now: Date = Date()) -> StoredRecordRead<T> {
        let read = peek(type, key: key, defaults: defaults)
        if read.isUnreadable { keepCopy(key: key, defaults: defaults, now: now) }
        return read
    }

    /// For a writer that replaces the value without reading it (a copy of what is in memory): keeps the value it is
    /// about to replace when that value cannot be read.
    /// true when the value could not be read (and was copied).
    @discardableResult
    static func preserveIfUnreadable<T: Decodable>(_ type: T.Type, key: String, defaults: UserDefaults, now: Date = Date()) -> Bool {
        load(type, key: key, defaults: defaults, now: now).isUnreadable
    }

    /// Keeps the newest `StoredRecordFile.copiesKept` copies of `key` (`pruneCopies`). A value already kept under one of
    /// them is not copied again.
    static func keepCopy(key: String, defaults: UserDefaults, now: Date = Date()) {
        guard let raw = defaults.object(forKey: key) else { return }
        if copyKeys(of: key, defaults: defaults).contains(where: { (defaults.object(forKey: $0) as? NSObject)?.isEqual(raw) == true }) { return }
        let backup = nextCopyKey(of: key, defaults: defaults, now: now)
        defaults.set(raw, forKey: backup)
        NSLog("RoamSwitch: the stored record %@ could not be read; kept as %@", key, backup)
        pruneCopies(of: key, defaults: defaults)
    }

    /// `<key>.unreadable` (the first copy) and `<key>.unreadable.<unix time>`, oldest first.
    static func copyKeys(of key: String, defaults: UserDefaults) -> [String] {
        let plain = key + ".unreadable"
        let stamped = defaults.dictionaryRepresentation().keys.compactMap { k -> (Int, String)? in
            guard k.hasPrefix(plain + "."), let n = Int(k.dropFirst(plain.count + 1)) else { return nil }
            return (n, k)
        }.sorted { $0.0 < $1.0 }.map(\.1)
        return (defaults.object(forKey: plain) != nil ? [plain] : []) + stamped
    }

    /// `<key>.unreadable` while there is no copy, then `<key>.unreadable.<unix time>`, always after the newest copy (so
    /// the plain name stays the oldest, and pruning never removes the copy just made).
    static func nextCopyKey(of key: String, defaults: UserDefaults, now: Date = Date()) -> String {
        let plain = key + ".unreadable"
        let existing = copyKeys(of: key, defaults: defaults)
        guard !existing.isEmpty else { return plain }
        var stamp = Int(now.timeIntervalSince1970)
        if let last = existing.last, let n = Int(last.dropFirst(plain.count + 1)), stamp <= n { stamp = n + 1 }
        return plain + ".\(stamp)"
    }

    /// Removes all but the newest `keep` copies of `key`.
    static func pruneCopies(of key: String, defaults: UserDefaults, keep: Int = StoredRecordFile.copiesKept) {
        let keys = copyKeys(of: key, defaults: defaults)
        for k in keys.dropLast(keep) { defaults.removeObject(forKey: k) }
    }

    static func backupKey(for key: String, existing: (String) -> Bool, now: Date = Date()) -> String {
        let plain = key + ".unreadable"
        guard existing(plain) else { return plain }
        return plain + ".\(Int(now.timeIntervalSince1970))"
    }
}

/// Duplicate-key detection for stored JSON. `JSONDecoder` (like `JSONSerialization`) keeps one of two values for the same
/// key without saying so, so a record with `"enabled": false, "enabled": true` reads as whichever it picks. One pass over
/// the bytes, no recursion (a deeply nested file cannot exhaust the stack). Keys are compared after their escapes are
/// decoded (`"a"` and `"\u0061"` are the same key). Text that is not valid JSON is left to the decoder to refuse.
enum StoredRecordJSON {
    static func hasDuplicateKeys(_ data: Data) -> Bool {
        let b = [UInt8](data)
        var i = 0
        // One entry per open container: the keys seen so far for an object, nil for an array.
        var stack: [Set<String>?] = []
        // Inside an object, the next string is a key.
        var expectKey = false
        while i < b.count {
            let c = b[i]
            switch c {
            case UInt8(ascii: "{"):
                stack.append(Set<String>()); expectKey = true; i += 1
            case UInt8(ascii: "["):
                stack.append(nil); expectKey = false; i += 1
            case UInt8(ascii: "}"), UInt8(ascii: "]"):
                if !stack.isEmpty { stack.removeLast() }
                expectKey = false; i += 1
            case UInt8(ascii: ","):
                if let top = stack.last { expectKey = top != nil }
                i += 1
            case UInt8(ascii: ":"):
                expectKey = false; i += 1
            case UInt8(ascii: "\""):
                guard let (text, end) = decodeString(b, from: i) else { return false }
                if expectKey, let top = stack.last, var keys = top {
                    if keys.contains(text) { return true }
                    keys.insert(text)
                    stack[stack.count - 1] = keys
                    expectKey = false
                }
                i = end
            default:
                i += 1
            }
        }
        return false
    }

    /// The decoded string starting at the quote at `start`, and the index after its closing quote. nil when the
    /// string is not closed or an escape is malformed.
    private static func decodeString(_ b: [UInt8], from start: Int) -> (String, Int)? {
        var i = start + 1
        var units: [UInt16] = []
        var raw: [UInt8] = []
        func flushRaw() {
            if !raw.isEmpty { units.append(contentsOf: String(decoding: raw, as: UTF8.self).utf16); raw.removeAll() }
        }
        while i < b.count {
            let c = b[i]
            if c == UInt8(ascii: "\"") {
                flushRaw()
                return (String(decoding: units, as: UTF16.self), i + 1)
            }
            if c == UInt8(ascii: "\\") {
                guard i + 1 < b.count else { return nil }
                flushRaw()
                let e = b[i + 1]
                switch e {
                case UInt8(ascii: "\""): units.append(0x22)
                case UInt8(ascii: "\\"): units.append(0x5C)
                case UInt8(ascii: "/"): units.append(0x2F)
                case UInt8(ascii: "b"): units.append(0x08)
                case UInt8(ascii: "f"): units.append(0x0C)
                case UInt8(ascii: "n"): units.append(0x0A)
                case UInt8(ascii: "r"): units.append(0x0D)
                case UInt8(ascii: "t"): units.append(0x09)
                case UInt8(ascii: "u"):
                    guard i + 6 <= b.count, let v = UInt16(String(decoding: b[(i + 2)..<(i + 6)], as: UTF8.self), radix: 16) else { return nil }
                    units.append(v)
                    i += 4
                default: return nil
                }
                i += 2
                continue
            }
            raw.append(c)
            i += 1
        }
        return nil
    }
}
