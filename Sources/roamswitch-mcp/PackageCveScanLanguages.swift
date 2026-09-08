// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.0 (build 57).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Package CVE Scan — language ecosystems (see
/// `roamswitch-linux/docs/PACKAGE_CVE_SCAN_SPEC.ja.md` §5's "言語エコシステム"
/// section and `roamswitch-core::package_cve_scan`'s
/// `scan_language_ecosystems`). The macOS counterpart of that Linux logic:
/// scans developer-chosen watched folders for known dependency lockfiles
/// (package-lock.json, requirements.txt, Pipfile.lock, poetry.lock,
/// Cargo.lock, Gemfile.lock, composer.lock, go.sum, pom.xml) and checks each
/// pinned dependency against a purely local, mechanically-generated known-CVE
/// map per ecosystem (npm, PyPI, crates.io, RubyGems, Packagist, Go, Maven —
/// CVSS >= 7.0, no recency cutoff). Zero network activity — the same "empty
/// embedded seed, refreshed only by the signed daily updater" discipline as
/// every other package-CVE map in this app.
///
/// Every version comparator below is a direct, line-by-line port of the
/// already-verified Rust implementation in
/// `roamswitch-core/src/package_cve_scan.rs` (semver, PEP 440, RubyGems
/// `Gem::Version`, Composer/`version_compare()`, Maven
/// `ComparableVersion`) — see that file's own doc comments for what each
/// algorithm was cross-checked against on the Linux side (hundreds to
/// thousands of real comparison pairs from official reference
/// implementations). Unlike `PackageCveScan.swift`'s Homebrew map, these
/// entries carry no `confidence` tier — OSV.dev gives a real CVSS score and
/// a real affected-version range for every one of these 7 ecosystems, so
/// every finding here is as trustworthy as the Debian/RHEL/SUSE OS-package
/// findings, not a fuzzy keyword match.
enum PackageCveScanLanguages {

    // MARK: - Shared numeric helpers

    /// Lexicographic comparison of two `[UInt64]`, matching Rust's derived
    /// `Ord` for `Vec<u64>` (element-wise; a matching prefix with fewer
    /// elements sorts lower).
    private static func compareArrays(_ a: [UInt64], _ b: [UInt64]) -> Int {
        let n = min(a.count, b.count)
        for i in 0..<n where a[i] != b[i] {
            return a[i] < b[i] ? -1 : 1
        }
        if a.count != b.count { return a.count < b.count ? -1 : 1 }
        return 0
    }

    private static func trimTrailingZeros(_ v: [UInt64]) -> [UInt64] {
        var out = v
        while out.count > 1, out.last == 0 { out.removeLast() }
        return out
    }

    private static func namedGroup(_ match: NSTextCheckingResult, _ name: String, in text: String) -> String? {
        let range = match.range(withName: name)
        guard range.location != NSNotFound, let r = Range(range, in: text) else { return nil }
        return String(text[r])
    }

    private static func isAsciiDigit(_ c: Character) -> Bool {
        guard let v = c.asciiValue else { return false }
        return v >= 48 && v <= 57
    }

    // MARK: - Semantic Versioning (semver.org) — npm, crates.io, Go

    private struct SemVer {
        let major: UInt64
        let minor: UInt64
        let patch: UInt64
        let prerelease: [String]
    }

    private static func parseSemver(_ v: String) -> SemVer? {
        var s = v.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("v") { s.removeFirst() }
        if let plusIdx = s.firstIndex(of: "+") { s = String(s[s.startIndex..<plusIdx]) }
        let core: String
        var prerelease: [String] = []
        if let dashIdx = s.firstIndex(of: "-") {
            core = String(s[s.startIndex..<dashIdx])
            let preStr = String(s[s.index(after: dashIdx)...])
            prerelease = preStr.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        } else {
            core = s
        }
        let parts = core.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard !parts.isEmpty, let major = UInt64(parts[0]) else { return nil }
        guard let minor = UInt64(parts.count >= 2 ? parts[1] : "0") else { return nil }
        guard let patch = UInt64(parts.count >= 3 ? parts[2] : "0") else { return nil }
        return SemVer(major: major, minor: minor, patch: patch, prerelease: prerelease)
    }

    private static func comparePrereleaseIdentifier(_ a: String, _ b: String) -> Int {
        switch (UInt64(a), UInt64(b)) {
        case (.some(let x), .some(let y)): return x == y ? 0 : (x < y ? -1 : 1)
        case (.some, .none): return -1
        case (.none, .some): return 1
        case (.none, .none): return a == b ? 0 : (a < b ? -1 : 1)
        }
    }

    /// `-1` = `a` older, `0` = equal, `1` = `a` newer. Falls back to treating
    /// an unparseable string as always-less-than a parseable one, and to a
    /// raw string comparison when neither side parses — never panics.
    static func semverCompare(_ a: String, _ b: String) -> Int {
        guard let pa = parseSemver(a) else {
            if parseSemver(b) != nil { return -1 }
            return a == b ? 0 : (a < b ? -1 : 1)
        }
        guard let pb = parseSemver(b) else { return 1 }
        if pa.major != pb.major { return pa.major < pb.major ? -1 : 1 }
        if pa.minor != pb.minor { return pa.minor < pb.minor ? -1 : 1 }
        if pa.patch != pb.patch { return pa.patch < pb.patch ? -1 : 1 }
        switch (pa.prerelease.isEmpty, pb.prerelease.isEmpty) {
        case (true, true): return 0
        case (true, false): return 1 // no prerelease outranks any prerelease
        case (false, true): return -1
        case (false, false): break
        }
        let n = min(pa.prerelease.count, pb.prerelease.count)
        for i in 0..<n {
            let c = comparePrereleaseIdentifier(pa.prerelease[i], pb.prerelease[i])
            if c != 0 { return c }
        }
        if pa.prerelease.count != pb.prerelease.count {
            return pa.prerelease.count < pb.prerelease.count ? -1 : 1
        }
        return 0
    }

    // MARK: - PEP 440 (peps.python.org/pep-0440) — PyPI

    private struct Pep440 {
        let epoch: UInt64
        let release: [UInt64]
        let pre: (UInt8, UInt64)?
        let post: UInt64?
        let dev: UInt64?
        let local: String?
    }

    private static let pep440Regex: NSRegularExpression = {
        let pattern = #"""
        ^\s*v?
        (?:(?<epoch>[0-9]+)!)?
        (?<release>[0-9]+(?:\.[0-9]+)*)
        (?:
            [-_.]?
            (?<preL>alpha|beta|preview|pre|a|b|c|rc)
            [-_.]?
            (?<preN>[0-9]+)?
        )?
        (?:
            (?:-(?<postN1>[0-9]+))
            |
            (?:
                [-_.]?
                (?<postL>post|rev|r)
                [-_.]?
                (?<postN2>[0-9]+)?
            )
        )?
        (?:
            [-_.]?dev[-_.]?(?<devN>[0-9]+)?
        )?
        (?:\+(?<local>[a-z0-9]+(?:[-_.][a-z0-9]+)*))?
        \s*$
        """#
        return try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .allowCommentsAndWhitespace])
    }()

    private static func parsePep440(_ v: String) -> Pep440? {
        let ns = v as NSString
        guard let m = pep440Regex.firstMatch(in: v, range: NSRange(location: 0, length: ns.length)) else { return nil }
        let epoch = namedGroup(m, "epoch", in: v).flatMap { UInt64($0) } ?? 0
        guard let releaseStr = namedGroup(m, "release", in: v) else { return nil }
        let release = releaseStr.split(separator: ".").map { UInt64($0) ?? 0 }

        let pre: (UInt8, UInt64)? = namedGroup(m, "preL", in: v).map { l in
            let rank: UInt8
            switch l.lowercased() {
            case "a", "alpha": rank = 0
            case "b", "beta": rank = 1
            default: rank = 2 // c, rc, pre, preview all normalize to "rc"
            }
            let n = namedGroup(m, "preN", in: v).flatMap { UInt64($0) } ?? 0
            return (rank, n)
        }

        let hasPost = namedGroup(m, "postN1", in: v) != nil || namedGroup(m, "postL", in: v) != nil
        let post: UInt64? = hasPost
            ? ((namedGroup(m, "postN1", in: v) ?? namedGroup(m, "postN2", in: v)).flatMap { UInt64($0) } ?? 0)
            : nil

        let dev: UInt64? = v.lowercased().contains("dev")
            ? (namedGroup(m, "devN", in: v).flatMap { UInt64($0) } ?? 0)
            : nil

        let local = namedGroup(m, "local", in: v)
        return Pep440(epoch: epoch, release: release, pre: pre, post: post, dev: dev, local: local)
    }

    static func pep440Compare(_ a: String, _ b: String) -> Int {
        guard let pa = parsePep440(a) else {
            if parsePep440(b) != nil { return -1 }
            return a == b ? 0 : (a < b ? -1 : 1)
        }
        guard let pb = parsePep440(b) else { return 1 }
        if pa.epoch != pb.epoch { return pa.epoch < pb.epoch ? -1 : 1 }

        let ra = trimTrailingZeros(pa.release)
        let rb = trimTrailingZeros(pb.release)
        if ra != rb { return compareArrays(ra, rb) }

        // Sentinel ordering per Python packaging's `_cmpkey`: a pure dev
        // release sorts before any pre-release of the same release segment;
        // otherwise an absent pre-release sorts after every pre-release.
        func preKey(_ p: Pep440) -> (UInt8, (UInt8, UInt64)) {
            if let pr = p.pre { return (1, pr) }
            if p.post == nil, p.dev != nil { return (0, (0, 0)) }
            return (2, (UInt8.max, UInt64.max))
        }
        let ka = preKey(pa), kb = preKey(pb)
        if ka.0 != kb.0 { return ka.0 < kb.0 ? -1 : 1 }
        if ka.1.0 != kb.1.0 { return ka.1.0 < kb.1.0 ? -1 : 1 }
        if ka.1.1 != kb.1.1 { return ka.1.1 < kb.1.1 ? -1 : 1 }

        // Absence of post sorts below presence of post.
        let aHasPost = pa.post != nil, bHasPost = pb.post != nil
        if aHasPost != bHasPost { return aHasPost ? 1 : -1 }
        if aHasPost {
            let va = pa.post ?? 0, vb = pb.post ?? 0
            if va != vb { return va < vb ? -1 : 1 }
        }

        // Absent dev sorts above present dev.
        switch (pa.dev, pb.dev) {
        case (nil, nil): break
        case (nil, .some): return 1
        case (.some, nil): return -1
        case (.some(let da), .some(let db)):
            if da != db { return da < db ? -1 : 1 }
        }

        let la = pa.local ?? "", lb = pb.local ?? ""
        if la != lb { return la < lb ? -1 : 1 }
        return 0
    }

    // MARK: - RubyGems (Gem::Version) — RubyGems

    private enum GemSegment: Equatable {
        case num(UInt64)
        case str(String)
    }

    private static func gemSegments(_ v: String) -> [GemSegment] {
        // Real `Gem::Version#initialize` rewrites every "-" to ".pre." before
        // splitting, so "1.0.0-rc1" tokenizes as "1.0.0.pre.rc1".
        let normalized = v.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "-", with: ".pre.")
        return normalized.split(separator: ".", omittingEmptySubsequences: true).map { tok in
            if let n = UInt64(tok) { return .num(n) }
            return .str(String(tok).lowercased())
        }
    }

    static func rubygemsVersionCompare(_ a: String, _ b: String) -> Int {
        let sa = gemSegments(a), sb = gemSegments(b)
        let len = max(sa.count, sb.count)
        for i in 0..<len {
            let da = i < sa.count ? sa[i] : .num(0)
            let db = i < sb.count ? sb[i] : .num(0)
            switch (da, db) {
            case (.num(let x), .num(let y)):
                if x != y { return x < y ? -1 : 1 }
            case (.str, .num):
                return -1
            case (.num, .str):
                return 1
            case (.str(let x), .str(let y)):
                if x != y { return x < y ? -1 : 1 }
            }
        }
        return 0
    }

    // MARK: - Composer/Packagist (`version_compare()`) — Packagist

    private static let composerRegex: NSRegularExpression = {
        let pattern = #"""
        ^\s*v?
        (?<release>[0-9]+(?:\.[0-9]+){0,3})
        (?:
            [-_.]?
            (?<stab>dev|alpha|a|beta|b|rc|pl|p)
            [-_.]?
            (?<num>[0-9]+)?
        )?
        \s*$
        """#
        return try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .allowCommentsAndWhitespace])
    }()

    private static func composerStabilityRank(_ tag: String?) -> Int8 {
        guard let t = tag?.lowercased() else { return 4 } // no suffix == stable
        switch t {
        case "dev": return 0
        case "alpha", "a": return 1
        case "beta", "b": return 2
        case "rc": return 3
        case "pl", "p": return 5
        default: return 4
        }
    }

    static func composerVersionCompare(_ a: String, _ b: String) -> Int {
        let nsA = a as NSString, nsB = b as NSString
        guard let ma = composerRegex.firstMatch(in: a, range: NSRange(location: 0, length: nsA.length)) else {
            if composerRegex.firstMatch(in: b, range: NSRange(location: 0, length: nsB.length)) != nil { return -1 }
            return a == b ? 0 : (a < b ? -1 : 1)
        }
        guard let mb = composerRegex.firstMatch(in: b, range: NSRange(location: 0, length: nsB.length)) else { return 1 }

        let releaseA = trimTrailingZeros((namedGroup(ma, "release", in: a) ?? "0").split(separator: ".").map { UInt64($0) ?? 0 })
        let releaseB = trimTrailingZeros((namedGroup(mb, "release", in: b) ?? "0").split(separator: ".").map { UInt64($0) ?? 0 })
        if releaseA != releaseB { return compareArrays(releaseA, releaseB) }

        let rankA = composerStabilityRank(namedGroup(ma, "stab", in: a))
        let rankB = composerStabilityRank(namedGroup(mb, "stab", in: b))
        if rankA != rankB { return rankA < rankB ? -1 : 1 }

        let numA = namedGroup(ma, "num", in: a).flatMap { UInt64($0) } ?? 0
        let numB = namedGroup(mb, "num", in: b).flatMap { UInt64($0) } ?? 0
        if numA != numB { return numA < numB ? -1 : 1 }
        return 0
    }

    // MARK: - Maven (`ComparableVersion`) — Maven

    private enum MavenToken: Equatable {
        case num(UInt64)
        case qualifier(Int8, String)
    }

    private static func mavenQualifierRank(_ q: String) -> Int8 {
        switch q.lowercased() {
        case "alpha": return 0
        case "beta": return 1
        case "milestone", "m": return 2
        case "rc", "cr": return 3
        case "snapshot": return 4
        case "", "ga", "final", "release": return 5
        case "sp": return 6
        default: return 5 // unrecognized qualifiers sort alongside "release" by text
        }
    }

    private static func mavenSplitAlnumRuns(_ segment: String) -> [String] {
        let chars = Array(segment)
        guard !chars.isEmpty else { return [] }
        var runs: [String] = []
        var start = 0
        for i in 1...chars.count {
            let boundary = i == chars.count || isAsciiDigit(chars[i - 1]) != isAsciiDigit(chars[i])
            if boundary {
                runs.append(String(chars[start..<i]))
                start = i
            }
        }
        return runs
    }

    private static func mavenTokens(_ v: String) -> [MavenToken] {
        let trimmed = v.trimmingCharacters(in: .whitespaces)
        var tokens: [MavenToken] = []
        for segment in trimmed.split(whereSeparator: { $0 == "." || $0 == "-" }) {
            for run in mavenSplitAlnumRuns(String(segment)) {
                if let n = UInt64(run) {
                    tokens.append(.num(n))
                } else {
                    tokens.append(.qualifier(mavenQualifierRank(run), run.lowercased()))
                }
            }
        }
        return tokens
    }

    /// A missing trailing token compares as numeric 0 against a numeric
    /// opposite, but as an implicit "release" qualifier against a qualifier
    /// opposite — this is what makes pre-release qualifiers sort below a
    /// bare release while "sp" sorts above one.
    private static func mavenFillerFor(_ opposite: MavenToken) -> MavenToken {
        switch opposite {
        case .num: return .num(0)
        case .qualifier: return .qualifier(5, "")
        }
    }

    static func mavenVersionCompare(_ a: String, _ b: String) -> Int {
        let ta = mavenTokens(a), tb = mavenTokens(b)
        let len = max(ta.count, tb.count)
        for i in 0..<len {
            let rawA: MavenToken? = i < ta.count ? ta[i] : nil
            let rawB: MavenToken? = i < tb.count ? tb[i] : nil
            let da = rawA ?? mavenFillerFor(rawB!)
            let db = rawB ?? mavenFillerFor(rawA!)
            switch (da, db) {
            case (.num(let x), .num(let y)):
                if x != y { return x < y ? -1 : 1 }
            case (.qualifier, .num):
                return -1
            case (.num, .qualifier):
                return 1
            case (.qualifier(let ra, let sa), .qualifier(let rb, let sb)):
                if ra != rb { return ra < rb ? -1 : 1 }
                if sa != sb { return sa < sb ? -1 : 1 }
            }
        }
        return 0
    }

    /// Dispatches to the ecosystem's native version-ordering scheme. npm,
    /// crates.io, and Go all use semver natively (Go module versions are
    /// semver with a mandatory `v` prefix, already stripped by
    /// `semverCompare`).
    static func compareVersions(ecosystem: String, _ a: String, _ b: String) -> Int {
        switch ecosystem {
        case "npm", "crates.io", "Go": return semverCompare(a, b)
        case "PyPI": return pep440Compare(a, b)
        case "RubyGems": return rubygemsVersionCompare(a, b)
        case "Packagist": return composerVersionCompare(a, b)
        case "Maven": return mavenVersionCompare(a, b)
        default: return semverCompare(a, b)
        }
    }

    // MARK: - CVE map model

    struct CveRange: Decodable {
        let introduced: String
        let fixed: String
    }

    struct CveEntry: Decodable {
        let cveId: String
        let package: String
        let cvssScore: Double
        let ranges: [CveRange]
        let summary: String

        enum CodingKeys: String, CodingKey { case cveId, package, cvssScore, ranges, summary }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            cveId = try c.decode(String.self, forKey: .cveId)
            package = try c.decode(String.self, forKey: .package)
            cvssScore = try c.decode(Double.self, forKey: .cvssScore)
            ranges = try c.decodeIfPresent([CveRange].self, forKey: .ranges) ?? []
            summary = try c.decodeIfPresent(String.self, forKey: .summary) ?? ""
        }
    }

    struct CveMap: Decodable {
        let mapVersion: String
        let ecosystem: String
        let entries: [CveEntry]

        enum CodingKeys: String, CodingKey { case mapVersion, ecosystem, entries }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            mapVersion = try c.decodeIfPresent(String.self, forKey: .mapVersion) ?? ""
            ecosystem = try c.decodeIfPresent(String.self, forKey: .ecosystem) ?? ""
            entries = try c.decodeIfPresent([CveEntry].self, forKey: .entries) ?? []
        }
        init(mapVersion: String, ecosystem: String, entries: [CveEntry]) {
            self.mapVersion = mapVersion
            self.ecosystem = ecosystem
            self.entries = entries
        }
        static func empty(ecosystem: String) -> CveMap { CveMap(mapVersion: "", ecosystem: ecosystem, entries: []) }
    }

    /// File-name keys for the 7 supported language ecosystems — matches
    /// `roamswitch-updater::package_cve_map_languages::ECOSYSTEM_FILE_KEYS`
    /// on the Linux side exactly, including the manifest's
    /// `packageCveMapLanguages` dictionary keys.
    static let ecosystemFileKeys: [String] = ["npm", "pypi", "cratesio", "rubygems", "packagist", "go", "maven"]

    static func ecosystemDisplayName(forFileKey key: String) -> String {
        switch key {
        case "npm": return "npm"
        case "pypi": return "PyPI"
        case "cratesio": return "crates.io"
        case "rubygems": return "RubyGems"
        case "packagist": return "Packagist"
        case "go": return "Go"
        case "maven": return "Maven"
        default: return key
        }
    }

    static func updatedCVEMapURL(fileKey: String) -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RoamSwitch", isDirectory: true)
        return base.appendingPathComponent("package_cve_map_\(fileKey).json")
    }

    static func loadCVEMap(fileKey: String) -> CveMap {
        let decoder = JSONDecoder()
        let ecosystem = ecosystemDisplayName(forFileKey: fileKey)
        let embeddedJSON = PackageCveMapLanguagesData.embeddedJSON(forFileKey: fileKey)
        let bundled = (try? decoder.decode(CveMap.self, from: Data(embeddedJSON.utf8))) ?? .empty(ecosystem: ecosystem)
        if let data = try? Data(contentsOf: updatedCVEMapURL(fileKey: fileKey)),
           let updated = try? decoder.decode(CveMap.self, from: data),
           updated.mapVersion >= bundled.mapVersion {
            return updated
        }
        return bundled
    }

    /// Loads all 7 ecosystem maps, keyed by their `ecosystem` display name
    /// (not the file key) — matching how `WatchedDependency.ecosystem` and
    /// `findKnownCVEs` look them up.
    static func loadAllCVEMaps() -> [String: CveMap] {
        var maps: [String: CveMap] = [:]
        for key in ecosystemFileKeys {
            let m = loadCVEMap(fileKey: key)
            maps[m.ecosystem] = m
        }
        return maps
    }

    static func findKnownCVEs(map: CveMap, package: String, installedVersion: String) -> [CveEntry] {
        map.entries.filter { entry in
            entry.package == package && entry.ranges.contains { range in
                compareVersions(ecosystem: map.ecosystem, installedVersion, range.introduced) >= 0
                    && compareVersions(ecosystem: map.ecosystem, installedVersion, range.fixed) < 0
            }
        }
    }

    private static func tightestFixedVersion(ecosystem: String, installedVersion: String, entry: CveEntry) -> String {
        entry.ranges
            .map(\.fixed)
            .filter { compareVersions(ecosystem: ecosystem, installedVersion, $0) < 0 }
            .min { compareVersions(ecosystem: ecosystem, $0, $1) < 0 } ?? ""
    }

    // MARK: - Lockfile parsing

    struct WatchedDependency {
        let ecosystem: String
        let name: String
        let version: String
    }

    private static func jsonObject(_ text: String) -> [String: Any]? {
        guard let data = text.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    static func parsePackageLockJSON(_ text: String) -> [WatchedDependency] {
        guard let obj = jsonObject(text) else { return [] }
        var out: [WatchedDependency] = []
        if let packages = obj["packages"] as? [String: Any] {
            // lockfileVersion 2/3: keys are paths like "node_modules/foo" or
            // nested scoped paths; the package name is the last
            // "node_modules/<name>" segment.
            for (path, entryAny) in packages {
                if path.isEmpty { continue } // the root project itself
                guard let entry = entryAny as? [String: Any], let version = entry["version"] as? String else { continue }
                let name: String
                if let range = path.range(of: "node_modules/", options: .backwards) {
                    name = String(path[range.upperBound...])
                } else {
                    name = path
                }
                out.append(WatchedDependency(ecosystem: "npm", name: name, version: version))
            }
        } else if let deps = obj["dependencies"] as? [String: Any] {
            // lockfileVersion 1: nested "dependencies" object, recursed.
            collectNpmV1Deps(deps, &out)
        }
        return out
    }

    private static func collectNpmV1Deps(_ deps: [String: Any], _ out: inout [WatchedDependency]) {
        for (name, entryAny) in deps {
            guard let entry = entryAny as? [String: Any] else { continue }
            if let version = entry["version"] as? String {
                out.append(WatchedDependency(ecosystem: "npm", name: name, version: version))
            }
            if let nested = entry["dependencies"] as? [String: Any] {
                collectNpmV1Deps(nested, &out)
            }
        }
    }

    private static let requirementsTxtRegex = try! NSRegularExpression(
        pattern: #"^([A-Za-z0-9][A-Za-z0-9._-]*)\s*==\s*([A-Za-z0-9.*+!_-]+)"#
    )

    /// Only an exact `==` pin names a definite installed version; ranges
    /// (>=, ~=, etc.) don't, and are intentionally not matched.
    static func parseRequirementsTxt(_ text: String) -> [WatchedDependency] {
        var out: [WatchedDependency] = []
        for rawLine in text.components(separatedBy: .newlines) {
            let beforeComment = rawLine.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false).first
                .map(String.init) ?? ""
            let line = beforeComment.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("-") { continue }
            let ns = line as NSString
            guard let m = requirementsTxtRegex.firstMatch(in: line, range: NSRange(location: 0, length: ns.length)) else { continue }
            out.append(WatchedDependency(
                ecosystem: "PyPI",
                name: ns.substring(with: m.range(at: 1)),
                version: ns.substring(with: m.range(at: 2))
            ))
        }
        return out
    }

    static func parsePipfileLock(_ text: String) -> [WatchedDependency] {
        guard let obj = jsonObject(text) else { return [] }
        var out: [WatchedDependency] = []
        for section in ["default", "develop"] {
            guard let pkgs = obj[section] as? [String: Any] else { continue }
            for (name, entryAny) in pkgs {
                guard let entry = entryAny as? [String: Any], var version = entry["version"] as? String else { continue }
                while version.hasPrefix("==") { version.removeFirst(2) }
                out.append(WatchedDependency(ecosystem: "PyPI", name: name, version: version))
            }
        }
        return out
    }

    /// Minimal `[[package]]` block extractor for Cargo.lock / poetry.lock —
    /// both are TOML, but only the top-level `name`/`version` scalar fields
    /// of each `[[package]]` array-of-tables entry are needed, so a full
    /// TOML parser (and the new dependency it would add) isn't warranted.
    /// Any subsequent `[...]` header (e.g. `[package.dependencies]`) ends
    /// the current block's scalar-field collection, exactly like a real TOML
    /// parser would scope it.
    private static func parseTomlPackageBlocks(_ text: String) -> [(name: String, version: String)] {
        var results: [(String, String)] = []
        var inBlock = false
        var currentName: String?
        var currentVersion: String?

        func flush() {
            if let n = currentName, let v = currentVersion { results.append((n, v)) }
            currentName = nil
            currentVersion = nil
        }
        func stringValue(_ line: String, key: String) -> String? {
            guard line.hasPrefix("\(key) ") || line.hasPrefix("\(key)=") else { return nil }
            guard let eqIdx = line.firstIndex(of: "=") else { return nil }
            let rhs = line[line.index(after: eqIdx)...].trimmingCharacters(in: .whitespaces)
            guard rhs.hasPrefix("\""), let closeQuote = rhs.dropFirst().firstIndex(of: "\"") else { return nil }
            return String(rhs[rhs.index(after: rhs.startIndex)..<closeQuote])
        }

        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("[[") {
                if inBlock { flush() }
                inBlock = (line == "[[package]]")
                continue
            }
            if line.hasPrefix("[") {
                if inBlock { flush() }
                inBlock = false
                continue
            }
            guard inBlock else { continue }
            if let name = stringValue(line, key: "name") { currentName = name }
            if let version = stringValue(line, key: "version") { currentVersion = version }
        }
        if inBlock { flush() }
        return results
    }

    static func parsePoetryLock(_ text: String) -> [WatchedDependency] {
        parseTomlPackageBlocks(text).map { WatchedDependency(ecosystem: "PyPI", name: $0.name, version: $0.version) }
    }

    static func parseCargoLock(_ text: String) -> [WatchedDependency] {
        parseTomlPackageBlocks(text).map { WatchedDependency(ecosystem: "crates.io", name: $0.name, version: $0.version) }
    }

    private static let gemfileLockRegex = try! NSRegularExpression(pattern: #"^ {4}(\S+) \(([^)]+)\)$"#)

    /// Exactly 4-space indent selects top-level specs, not their nested
    /// (6-space-indented) sub-dependency listings.
    static func parseGemfileLock(_ text: String) -> [WatchedDependency] {
        var out: [WatchedDependency] = []
        for line in text.components(separatedBy: .newlines) {
            let ns = line as NSString
            guard let m = gemfileLockRegex.firstMatch(in: line, range: NSRange(location: 0, length: ns.length)) else { continue }
            out.append(WatchedDependency(
                ecosystem: "RubyGems",
                name: ns.substring(with: m.range(at: 1)),
                version: ns.substring(with: m.range(at: 2))
            ))
        }
        return out
    }

    static func parseComposerLock(_ text: String) -> [WatchedDependency] {
        guard let obj = jsonObject(text) else { return [] }
        var out: [WatchedDependency] = []
        for section in ["packages", "packages-dev"] {
            guard let pkgs = obj[section] as? [[String: Any]] else { continue }
            for pkg in pkgs {
                guard let name = pkg["name"] as? String, var version = pkg["version"] as? String else { continue }
                while version.hasPrefix("v") { version.removeFirst() }
                out.append(WatchedDependency(ecosystem: "Packagist", name: name, version: version))
            }
        }
        return out
    }

    static func parseGoSum(_ text: String) -> [WatchedDependency] {
        var seen = Set<String>()
        var out: [WatchedDependency] = []
        for line in text.components(separatedBy: .newlines) {
            let parts = line.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
            guard parts.count >= 2 else { continue }
            let module = parts[0], version = parts[1]
            if version.hasSuffix("/go.mod") { continue } // the go.mod-only hash line for the same module@version
            let key = "\(module)@\(version)"
            if !seen.insert(key).inserted { continue }
            out.append(WatchedDependency(ecosystem: "Go", name: module, version: version))
        }
        return out
    }

    private static let pomDependencyRegex = try! NSRegularExpression(
        pattern: "<dependency>(?<body>.*?)</dependency>",
        options: [.dotMatchesLineSeparators]
    )
    private static func pomFieldRegex(_ tag: String) -> NSRegularExpression {
        try! NSRegularExpression(pattern: "<\(tag)>\\s*([^<]+?)\\s*</\(tag)>")
    }

    /// Extracts `<dependency>` blocks from a `pom.xml` via regex rather than
    /// a full XML parser, and skips any whose `<version>` is a `${...}`
    /// property placeholder — resolving those needs full Maven POM
    /// inheritance, out of scope here; only directly-literal versions are
    /// reported.
    static func parsePomXml(_ text: String) -> [WatchedDependency] {
        let groupRe = pomFieldRegex("groupId")
        let artifactRe = pomFieldRegex("artifactId")
        let versionRe = pomFieldRegex("version")
        let ns = text as NSString
        var out: [WatchedDependency] = []
        pomDependencyRegex.enumerateMatches(in: text, range: NSRange(location: 0, length: ns.length)) { match, _, _ in
            guard let match, let bodyRange = Range(match.range(withName: "body"), in: text) else { return }
            let body = String(text[bodyRange])
            let bodyNS = body as NSString
            let bodyRangeAll = NSRange(location: 0, length: bodyNS.length)
            guard let gm = groupRe.firstMatch(in: body, range: bodyRangeAll),
                  let am = artifactRe.firstMatch(in: body, range: bodyRangeAll),
                  let vm = versionRe.firstMatch(in: body, range: bodyRangeAll) else { return }
            let group = bodyNS.substring(with: gm.range(at: 1))
            let artifact = bodyNS.substring(with: am.range(at: 1))
            let version = bodyNS.substring(with: vm.range(at: 1))
            if version.contains("${") { return }
            out.append(WatchedDependency(ecosystem: "Maven", name: "\(group):\(artifact)", version: version))
        }
        return out
    }

    /// Recognized lockfile basenames and the parser to run against their
    /// contents.
    private static let lockfileParsers: [String: (String) -> [WatchedDependency]] = [
        "package-lock.json": parsePackageLockJSON,
        "requirements.txt": parseRequirementsTxt,
        "Pipfile.lock": parsePipfileLock,
        "poetry.lock": parsePoetryLock,
        "Cargo.lock": parseCargoLock,
        "Gemfile.lock": parseGemfileLock,
        "composer.lock": parseComposerLock,
        "go.sum": parseGoSum,
        "pom.xml": parsePomXml,
    ]

    /// Directory names never descended into — dependency stores and VCS
    /// metadata that are enormous, irrelevant, or both.
    private static let skipDirNames: Set<String> =
        [".git", "node_modules", "vendor", "target", ".venv", "venv", "dist", "build", ".tox"]

    /// Walks `folder` up to `maxDepth` levels, running the matching parser
    /// on every recognized lockfile found. Tolerant of any I/O error —
    /// returns whatever it could read.
    static func scanWatchedFolder(_ folder: URL, maxDepth: Int) -> [WatchedDependency] {
        var out: [WatchedDependency] = []
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: [.isDirectoryKey], options: []
        ) else { return out }
        for entryURL in entries {
            let fileName = entryURL.lastPathComponent
            let isDir = (try? entryURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            if isDir {
                if maxDepth > 0, !skipDirNames.contains(fileName) {
                    out.append(contentsOf: scanWatchedFolder(entryURL, maxDepth: maxDepth - 1))
                }
                continue
            }
            if let parser = lockfileParsers[fileName], let text = try? String(contentsOf: entryURL, encoding: .utf8) {
                out.append(contentsOf: parser(text))
            }
        }
        return out
    }

    // MARK: - Scan

    struct Finding: Identifiable {
        let ecosystem: String
        let package: String
        let installedVersion: String
        let cveId: String
        let cvssScore: Double
        let fixedVersion: String
        let summary: String

        var id: String { "\(cveId)|\(ecosystem)|\(package)|\(installedVersion)" }
    }

    /// Scans every watched folder for known lockfiles, then checks each
    /// discovered dependency against the matching ecosystem's local CVE
    /// map. Ecosystems whose map has no installed data (seed-only, updater
    /// hasn't run yet) are simply never matched — never fabricated.
    static func runScan(watchedFolders: [String]) -> [Finding] {
        let maps = loadAllCVEMaps()
        guard !maps.values.allSatisfy({ $0.entries.isEmpty }) else { return [] }

        var deps: [WatchedDependency] = []
        for folder in watchedFolders {
            deps.append(contentsOf: scanWatchedFolder(URL(fileURLWithPath: folder), maxDepth: 6))
        }

        var findings: [Finding] = []
        for dep in deps {
            guard let map = maps[dep.ecosystem] else { continue }
            for cve in findKnownCVEs(map: map, package: dep.name, installedVersion: dep.version) {
                findings.append(Finding(
                    ecosystem: dep.ecosystem,
                    package: dep.name,
                    installedVersion: dep.version,
                    cveId: cve.cveId,
                    cvssScore: cve.cvssScore,
                    fixedVersion: tightestFixedVersion(ecosystem: dep.ecosystem, installedVersion: dep.version, entry: cve),
                    summary: cve.summary
                ))
            }
        }
        return findings
    }
}
