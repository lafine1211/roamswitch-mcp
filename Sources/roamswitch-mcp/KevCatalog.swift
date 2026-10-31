// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.18 (build 197).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// CISA's Known Exploited Vulnerabilities (KEV) list as the daily signed `kevCatalog` feed carries it.
///
/// The package CVE maps are rebuilt about once a week and bake the KEV flag in at build time, so a CVE that CISA
/// lists in between shows no flag until the next map. This small file (CVE ids only, about 30 KB) is fetched every
/// day by `PackageCveMapUpdater` from the same signed manifest, and `loadCVEMap` marks an entry as KEV when either
/// the map or this list says so. Nothing is contacted by the scan itself.
///
/// A missing or invalid file changes nothing: the maps behave exactly as they did before this list existed.
enum KevCatalog {

    /// What the feed payload decodes to.
    struct Payload: Decodable {
        let kevCatalogVersion: Int
        let date: String
        let catalogVersion: String
        let cves: [String]
    }

    /// A catalog that passed validation.
    struct Loaded: Equatable {
        /// The day (`YYYY-MM-DD`) of the CISA list.
        let date: String
        let ids: Set<String>

        func contains(_ cveId: String) -> Bool { ids.contains(cveId.uppercased()) }
    }

    enum Invalid: Error, Equatable, LocalizedError {
        case tooLarge
        case malformed
        case unsupportedVersion
        case badDate
        case tooFewIds(Int)
        case badId(String)

        var errorDescription: String? {
            switch self {
            case .tooLarge: return "kev catalog is larger than \(KevCatalog.maxBytes) bytes"
            case .malformed: return "kev catalog is not the expected JSON"
            case .unsupportedVersion: return "unsupported kev catalog version"
            case .badDate: return "kev catalog has no valid date"
            case .tooFewIds(let n): return "kev catalog has \(n) ids, expected at least \(KevCatalog.minimumIds)"
            case .badId(let id): return "kev catalog has a bad CVE id (\(id.prefix(24)))"
            }
        }
    }

    /// A real list has about 1,800 ids. Far fewer means an error page or a cut-off file.
    static let minimumIds = 500
    static let maxBytes = 2 * 1024 * 1024
    private static let supportedVersion = 1

    /// Where `PackageCveMapUpdater` installs the list, next to the installed maps.
    static let installedURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RoamSwitch", isDirectory: true)
        return base.appendingPathComponent("kev_catalog.json")
    }()

    /// The file that is read. A debug build can point it elsewhere with `ROAMSWITCH_KEV_CATALOG_FILE` so a test run
    /// never touches the installed app's folder; a release build always reads `installedURL`.
    static var readURL: URL {
        #if DEBUG
        if let path = ProcessInfo.processInfo.environment["ROAMSWITCH_KEV_CATALOG_FILE"], !path.isEmpty {
            return URL(fileURLWithPath: path)
        }
        #endif
        return installedURL
    }

    /// CVE ids as CISA writes them: `CVE-2024-0001`.
    static func isCveId(_ s: String) -> Bool {
        let parts = s.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0] == "CVE",
              parts[1].count == 4, parts[1].allSatisfy({ $0.isASCII && $0.isNumber }),
              parts[2].count >= 4, parts[2].allSatisfy({ $0.isASCII && $0.isNumber }) else { return false }
        return true
    }

    /// Checks a payload and returns the list. Throws `Invalid` for anything that is not a complete catalog.
    static func validate(_ data: Data) throws -> Loaded {
        guard data.count <= maxBytes else { throw Invalid.tooLarge }
        guard let payload = try? JSONDecoder().decode(Payload.self, from: data) else { throw Invalid.malformed }
        guard payload.kevCatalogVersion == supportedVersion else { throw Invalid.unsupportedVersion }
        guard let date = PackageCveEpss.validatedDate(payload.date) else { throw Invalid.badDate }
        if let bad = payload.cves.first(where: { !isCveId($0) }) { throw Invalid.badId(bad) }
        let ids = Set(payload.cves)
        guard ids.count >= minimumIds else { throw Invalid.tooFewIds(ids.count) }
        return Loaded(date: date, ids: ids)
    }

    /// An older list never replaces a newer one (a rolled-back manifest); the same day is allowed.
    static func isOlder(candidate: String, than installed: String?) -> Bool {
        guard let installed, !installed.isEmpty else { return false }
        return candidate < installed
    }

    /// The installed list, or nil when there is none or it is not valid.
    static func loadInstalled() -> Loaded? {
        guard let data = try? Data(contentsOf: readURL) else { return nil }
        return try? validate(data)
    }

    /// The date of the installed list, for the "do not go back in time" test.
    static func installedDate() -> String? { loadInstalled()?.date }
}

extension PackageCveScan.CveMap {
    /// The same map with `kev` set on every entry that `catalog` lists. `kevDate` becomes the later of the two days.
    /// Without a catalog the map is returned as it is.
    func applyingKev(_ catalog: KevCatalog.Loaded?) -> PackageCveScan.CveMap {
        guard let catalog else { return self }
        let marked = entries.map { catalog.contains($0.cveId) && !$0.kev ? $0.withKev() : $0 }
        let date = [kevDate, catalog.date].compactMap { $0 }.max()
        return PackageCveScan.CveMap(mapVersion: mapVersion, ecosystem: ecosystem, entries: marked, epssDate: epssDate, kevDate: date)
    }
}

extension PackageCveScanLanguages.CveMap {
    /// See `PackageCveScan.CveMap.applyingKev`.
    func applyingKev(_ catalog: KevCatalog.Loaded?) -> PackageCveScanLanguages.CveMap {
        guard let catalog else { return self }
        let marked = entries.map { catalog.contains($0.cveId) && !$0.kev ? $0.withKev() : $0 }
        let date = [kevDate, catalog.date].compactMap { $0 }.max()
        return PackageCveScanLanguages.CveMap(mapVersion: mapVersion, ecosystem: ecosystem, entries: marked, epssDate: epssDate, kevDate: date)
    }
}
