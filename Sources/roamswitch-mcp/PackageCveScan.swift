// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.5 (build 62).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Package CVE Scan (see `roamswitch-linux/docs/PACKAGE_CVE_SCAN_SPEC.ja.md`): a
/// purely local, zero-network inventory check — the macOS counterpart of the Linux
/// client's `package_cve_scan.rs`. Covers Homebrew (`brew list --versions`), the
/// macOS equivalent of the Linux client's dpkg/pacman OS-package scans.
///
/// Two confidence tiers (see the spec's §7): entries whose `confidence` field is
/// `"confirmed"` come from a hand-curated formula→CPE allowlist (real, verified
/// vendor:product pairs — never guessed); entries tagged `"gray"` come from an
/// exact-keyword CPE-dictionary match that was never hand-verified per formula, so
/// findings from those are explicitly labeled as possibly a false positive. Both
/// tiers are generated once via `scripts/gen_package_cve_map_homebrew.py` (NVD's
/// real CVE API — see the script for how CVSS/version-range data is pulled) and
/// shipped the same way as every other package-CVE map: an empty embedded seed,
/// refreshed by the daily updater — never a live query from the app itself.
enum PackageCveScan {

    // MARK: - Homebrew version comparison

    /// A single parsed version segment, mirroring Homebrew's own `Version::Token`
    /// hierarchy (`/opt/homebrew/Library/Homebrew/version.rb`) closely enough to
    /// match its real `<=>` behavior on realistic version strings — verified
    /// against the real `Version` class (`brew ruby`) across 595 comparison pairs.
    private enum Segment: Equatable {
        case numeric(Int)
        case alpha(Int)   // alphaN / aN
        case beta(Int)    // betaN / bN
        case pre(Int)      // preN
        case rc(Int)        // rcN
        case patch(Int)   // pN
        case post(Int)     // .postN
        case string(String) // any other alphabetic run

        /// Homebrew's real tier order for the composite "release stage" tokens:
        /// alpha < beta < pre < rc < post < patch (the post/patch order is a real
        /// quirk of Homebrew's own source — `PatchToken`/`PostToken` don't compare
        /// against each other explicitly and fall back to raw string comparison of
        /// their captured text, which happens to sort ".post1" before "p1").
        var stageRank: Int? {
            switch self {
            case .alpha: return 0
            case .beta: return 1
            case .pre: return 2
            case .rc: return 3
            case .post: return 4
            case .patch: return 5
            default: return nil
            }
        }

        var stageRev: Int? {
            switch self {
            case .alpha(let n), .beta(let n), .pre(let n), .rc(let n), .patch(let n), .post(let n): return n
            default: return nil
            }
        }
    }

    /// Splits a version string into segments the same way Homebrew's `SCAN_PATTERN`
    /// does: alpha/beta/pre/rc/patch tokens are recognized first (longest-priority
    /// keyword match), post requires a literal preceding '.', everything else is a
    /// plain digit run or letter run. Non-alphanumeric separators (`.`, `-`, `_`,
    /// `+`) are skipped between tokens, mirroring the real scan.
    private static func tokenize(_ version: String) -> [Segment] {
        var segments: [Segment] = []
        let chars = Array(version.lowercased())
        var i = 0

        func matchKeyword(_ kw: String, at pos: Int) -> Int? {
            guard pos + kw.count <= chars.count else { return nil }
            guard String(chars[pos..<(pos + kw.count)]) == kw else { return nil }
            return pos + kw.count
        }
        func readDigits(from pos: Int) -> (Int, Int) {
            var j = pos
            while j < chars.count, chars[j].isNumber { j += 1 }
            let n = j > pos ? (Int(String(chars[pos..<j])) ?? 0) : 0
            return (n, j)
        }

        while i < chars.count {
            let c = chars[i]
            if !c.isLetter && !c.isNumber {
                i += 1
                continue
            }
            // ".postN" — the leading dot is part of the token itself.
            if c == "." { /* unreachable: dots are filtered by the isLetter/isNumber check above */ }
            if i > 0, chars[i - 1] == ".", let after = matchKeyword("post", at: i) {
                let (n, end) = readDigits(from: after)
                segments.append(.post(n))
                i = end
                continue
            }
            if let after = matchKeyword("alpha", at: i) {
                let (n, end) = readDigits(from: after)
                segments.append(.alpha(n))
                i = end
                continue
            }
            if c == "a", i + 1 < chars.count, chars[i + 1].isNumber {
                let (n, end) = readDigits(from: i + 1)
                segments.append(.alpha(n))
                i = end
                continue
            }
            if let after = matchKeyword("beta", at: i) {
                let (n, end) = readDigits(from: after)
                segments.append(.beta(n))
                i = end
                continue
            }
            if c == "b", i + 1 < chars.count, chars[i + 1].isNumber {
                let (n, end) = readDigits(from: i + 1)
                segments.append(.beta(n))
                i = end
                continue
            }
            if let after = matchKeyword("pre", at: i) {
                let (n, end) = readDigits(from: after)
                segments.append(.pre(n))
                i = end
                continue
            }
            if let after = matchKeyword("rc", at: i) {
                let (n, end) = readDigits(from: after)
                segments.append(.rc(n))
                i = end
                continue
            }
            if c == "p" {
                // Unlike alpha/beta's bare-letter shorthand (`a[0-9]+`/`b[0-9]+`,
                // which require at least one digit), Homebrew's real PatchToken
                // pattern is `p[0-9]*` — bare "p" alone matches too, with zero
                // digits (verified: "patch1" tokenizes as Patch(0)+"atch"+1, NOT
                // as a recognized "patch" keyword — there is no such keyword).
                let (n, end) = readDigits(from: i + 1)
                segments.append(.patch(n))
                i = end
                continue
            }
            if c.isNumber {
                let (n, end) = readDigits(from: i)
                segments.append(.numeric(n))
                i = end
                continue
            }
            // A plain letter run (not matching any keyword above).
            var j = i
            while j < chars.count, chars[j].isLetter { j += 1 }
            segments.append(.string(String(chars[i..<j])))
            i = j
        }
        return segments
    }

    /// Compares one segment against "nothing" (Homebrew's `NullToken`): `nil`
    /// on either side means that side's token list ran out at this position.
    private static func compareSegment(_ a: Segment?, _ b: Segment?) -> Int {
        switch (a, b) {
        case (nil, nil):
            return 0
        case (nil, .some(let sb)):
            // NullToken vs other: alpha/beta/pre/rc lose to "nothing" (1, i.e.
            // null wins / a bare release beats a pre-release suffix); a numeric
            // zero ties; everything else (post/patch/generic string/nonzero
            // numeric) beats "nothing".
            if case .numeric(let n) = sb { return n == 0 ? 0 : -1 }
            if let rank = sb.stageRank, rank <= 3 { return 1 } // alpha/beta/pre/rc
            return -1
        case (.some(let sa), nil):
            return -compareSegment(nil, sa)
        case (.some(let sa), .some(let sb)):
            return compareSegmentPair(sa, sb)
        }
    }

    private static func isNumeric(_ s: Segment?) -> Bool {
        if case .numeric = s { return true }
        return false
    }

    private static func compareSegmentPair(_ a: Segment, _ b: Segment) -> Int {
        switch (a, b) {
        case (.numeric(let x), .numeric(let y)):
            return x == y ? 0 : (x < y ? -1 : 1)
        case (.numeric, _):
            return 1 // numeric always outranks a non-numeric segment
        case (_, .numeric):
            return -1
        default:
            break
        }
        // Both non-numeric: if both are recognized "stage" tokens (alpha/beta/
        // pre/rc/patch/post), use Homebrew's real tier order; a plain string
        // segment (or a stage token compared against a plain string) falls
        // back to raw lexical comparison of the segment's own text, mirroring
        // the real `StringToken#<=>` fallback path.
        if let ra = a.stageRank, let rb = b.stageRank {
            if ra != rb { return ra < rb ? -1 : 1 }
            let reva = a.stageRev ?? 0
            let revb = b.stageRev ?? 0
            return reva == revb ? 0 : (reva < revb ? -1 : 1)
        }
        let sa = segmentText(a)
        let sb = segmentText(b)
        return sa == sb ? 0 : (sa < sb ? -1 : 1)
    }

    private static func segmentText(_ s: Segment) -> String {
        switch s {
        case .numeric(let n): return String(n)
        case .alpha(let n): return "a\(n)"
        case .beta(let n): return "b\(n)"
        case .pre(let n): return "pre\(n)"
        case .rc(let n): return "rc\(n)"
        case .patch(let n): return "p\(n)"
        case .post(let n): return ".post\(n)"
        case .string(let s): return s
        }
    }

    /// Compares two Homebrew formula version strings the same way Homebrew's own
    /// `Version#<=>` does. `-1` = `a` older, `0` = equal, `1` = `a` newer.
    ///
    /// This is NOT simple positional token comparison: a trailing `_N` "revision"
    /// (Homebrew's own rebuild counter, e.g. `"3.8.13_2"`) tokenizes as just
    /// another plain numeric segment — verified directly against the real
    /// `Version#tokens` (`brew ruby`) rather than assumed. The real algorithm
    /// instead walks both token lists with two independently-advancing cursors:
    /// when one side's token at the current position is numeric and the other
    /// isn't, a numeric **zero** is treated as insignificant and skipped
    /// (advancing only that side's cursor, not both) rather than immediately
    /// deciding the comparison — this is what makes `"1.0.0"` and `"1.0a"`
    /// compare *equal* (the trailing `.0` is invisible against the following
    /// non-numeric `"a"`). Ported directly from `Version#<=>`
    /// (`/opt/homebrew/Library/Homebrew/version.rb`) and verified against the
    /// real class across 595 comparison pairs.
    static func homebrewVersionCompare(_ a: String, _ b: String) -> Int {
        if a == b { return 0 }
        let ltokens = tokenize(a)
        let rtokens = tokenize(b)
        let maxLen = max(ltokens.count, rtokens.count)
        var l = 0
        var r = 0
        // The real loop's termination isn't structurally obvious (only `l` is
        // bounded by `max`, `r` advances independently) — bound total steps
        // defensively so a mistranslation here can never hang instead of
        // just reporting a wrong (but bounded) answer.
        var guard_ = 0
        while l < maxLen, guard_ < 4 * maxLen + 16 {
            guard_ += 1
            let ta: Segment? = l < ltokens.count ? ltokens[l] : nil
            let tb: Segment? = r < rtokens.count ? rtokens[r] : nil
            if compareSegment(ta, tb) == 0 {
                l += 1
                r += 1
                continue
            }
            if isNumeric(ta), !isNumeric(tb) {
                if compareSegment(ta, nil) > 0 { return 1 }
                l += 1
            } else if !isNumeric(ta), isNumeric(tb) {
                if compareSegment(tb, nil) > 0 { return -1 }
                r += 1
            } else {
                return compareSegment(ta, tb)
            }
        }
        return 0
    }

    // MARK: - CVE map model

    /// One known-vulnerable version range for one package. Mirrors
    /// `roamswitch-core`'s `PackageCveRange` exactly (same field names, same JSON
    /// shape) so the same generator/updater architecture applies unchanged.
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
        /// `"confirmed"` (hand-curated formula→CPE allowlist) or `"gray"`
        /// (exact-keyword CPE match, never hand-verified — findings from these
        /// are labeled as possibly a false positive). Absent/unrecognized values
        /// default to `"gray"` — the safer direction if a future map version
        /// ever ships a value this build doesn't know about.
        let confidence: String

        enum CodingKeys: String, CodingKey {
            case cveId, package, cvssScore, ranges, summary, confidence
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            cveId = try c.decode(String.self, forKey: .cveId)
            package = try c.decode(String.self, forKey: .package)
            cvssScore = try c.decode(Double.self, forKey: .cvssScore)
            ranges = try c.decode([CveRange].self, forKey: .ranges)
            summary = try c.decodeIfPresent(String.self, forKey: .summary) ?? ""
            let raw = try c.decodeIfPresent(String.self, forKey: .confidence) ?? "gray"
            confidence = raw == "confirmed" ? "confirmed" : "gray"
        }
    }

    struct CveMap: Decodable {
        let mapVersion: String
        let ecosystem: String
        let entries: [CveEntry]

        static let empty = CveMap(mapVersion: "", ecosystem: "Homebrew", entries: [])
    }

    /// Where `PackageCveMapUpdater` installs a fresher signed copy (desktop client
    /// only). Preferred over the bundled baseline when present and its
    /// `mapVersion` is newer — mirrors `ActiveVulnScan.updatedCVEMapURL` and
    /// `roamswitch-core::package_cve_scan::load_cve_map_for_ecosystem` exactly.
    static let updatedCVEMapURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RoamSwitch", isDirectory: true)
        return base.appendingPathComponent("package_cve_map_homebrew.json")
    }()

    static func loadCVEMap() -> CveMap {
        let decoder = JSONDecoder()
        // Compiled in via `PackageCveMapData.swift` rather than a bundle resource
        // — same reasoning as `ActiveVulnScan.loadCVEMap`: `RoamSwitchMCPServer`
        // is a bare `tool` target with no `.app` bundle, so a real resource file
        // would silently leave it with zero baseline data.
        let bundled = (try? decoder.decode(CveMap.self, from: Data(PackageCveMapData.embeddedJSON.utf8))) ?? .empty
        if let data = try? Data(contentsOf: updatedCVEMapURL),
           let updated = try? decoder.decode(CveMap.self, from: data),
           updated.mapVersion >= bundled.mapVersion {
            return updated
        }
        return bundled
    }

    /// Returns every map entry whose package name matches and whose range
    /// contains `installedVersion`. Mirrors `roamswitch-core::package_cve_scan::
    /// find_known_cves` in returning *all* matches, not just the first.
    static func findKnownCVEs(map: CveMap, package: String, installedVersion: String) -> [CveEntry] {
        map.entries.filter { entry in
            entry.package == package && entry.ranges.contains { range in
                homebrewVersionCompare(installedVersion, range.introduced) >= 0
                    && homebrewVersionCompare(installedVersion, range.fixed) < 0
            }
        }
    }

    /// Picks the tightest (lowest) `fixed` version strictly above
    /// `installedVersion` among a CVE entry's ranges — the version the user
    /// actually needs to upgrade to.
    private static func tightestFixedVersion(installedVersion: String, entry: CveEntry) -> String {
        entry.ranges
            .map(\.fixed)
            .filter { homebrewVersionCompare(installedVersion, $0) < 0 }
            .min { homebrewVersionCompare($0, $1) < 0 } ?? ""
    }

    // MARK: - Package enumeration

    struct InstalledPackage {
        let name: String
        let version: String
    }

    /// Runs `brew list --versions` and parses the `<name> <version> [<version> ...]`
    /// output (one line per formula; a formula can have multiple versions
    /// installed side by side, e.g. `"ripgrep 15.1.0 15.2.0"` — every installed
    /// version is checked, not just the latest, since an older side-by-side
    /// install is just as real a target). Returns an empty array (never throws)
    /// on any failure — Homebrew may simply not be installed.
    static func enumerateHomebrewPackages() -> [InstalledPackage] {
        guard let brewPath = resolveBrewPath() else { return [] }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: brewPath)
        process.arguments = ["list", "--versions"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
        } catch {
            return []
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return [] }

        var packages: [InstalledPackage] = []
        for line in String(decoding: data, as: UTF8.self).split(separator: "\n") {
            let parts = line.split(separator: " ")
            guard parts.count >= 2 else { continue }
            let name = String(parts[0])
            for version in parts.dropFirst() {
                packages.append(InstalledPackage(name: name, version: String(version)))
            }
        }
        return packages
    }

    /// `brew` lives at a different path on Apple Silicon (`/opt/homebrew/bin/brew`)
    /// vs Intel (`/usr/local/bin/brew`) Macs — checked directly rather than
    /// relying on `PATH`, since a GUI app's environment often doesn't include the
    /// shell's `PATH` additions.
    private static func resolveBrewPath() -> String? {
        for candidate in ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"] {
            if FileManager.default.isExecutableFile(atPath: candidate) { return candidate }
        }
        return nil
    }

    // MARK: - Scan

    struct Finding: Identifiable {
        let cveId: String
        let package: String
        let installedVersion: String
        let cvssScore: Double
        let fixedVersion: String
        let summary: String
        let confidence: String

        var id: String { "\(cveId)|\(package)|\(installedVersion)" }
    }

    /// Enumerates installed Homebrew packages and checks each against the local
    /// Homebrew package-CVE map. Purely local — no network, no subprocess beyond
    /// `brew list --versions` itself.
    static func runScan() -> [Finding] {
        let map = loadCVEMap()
        guard !map.entries.isEmpty else { return [] }
        let installed = enumerateHomebrewPackages()
        var findings: [Finding] = []
        for pkg in installed {
            for cve in findKnownCVEs(map: map, package: pkg.name, installedVersion: pkg.version) {
                findings.append(Finding(
                    cveId: cve.cveId,
                    package: pkg.name,
                    installedVersion: pkg.version,
                    cvssScore: cve.cvssScore,
                    fixedVersion: tightestFixedVersion(installedVersion: pkg.version, entry: cve),
                    summary: cve.summary,
                    confidence: cve.confidence
                ))
            }
        }
        return findings
    }
}
