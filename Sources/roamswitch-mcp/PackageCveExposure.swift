// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.16 (build 195).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Audit check `package_cve_exposure`: does the software on this Mac still have a vulnerability that is being
/// exploited (CISA KEV) or very likely to be (EPSS at or above `epssThreshold`), in a version the local known-CVE
/// data says is affected?
///
/// Two sources. The Homebrew packages come from `PackageCveScan` (the inventory from `brew list --versions` and the
/// Homebrew map the updater installs). PHP is read from the disk by `PhpEnvironmentAudit` (version, settings), so a
/// PHP that Homebrew did not install is covered too; a finding of severity high or worse counts. Both read files and
/// start nothing but `brew list` and `php -v`: no network. Other software that did not come from Homebrew is not
/// looked at, and a package the map has no entry for says nothing either way.
///
/// The result is cached for `cacheSeconds` (the report is built often) and a fresh measurement is given
/// `timeLimit` seconds, so a stuck `brew` cannot hold the report.
enum PackageCveExposure {

    /// EPSS (0...1) at or above this makes a finding count even when CISA has not listed it. EPSS is an estimate of
    /// exploitation within 30 days, not a record of it, so the threshold is high.
    static let epssThreshold = 0.9
    /// How long a measured answer is reused.
    static let cacheSeconds: TimeInterval = 30 * 60
    /// How long a failed or timed-out answer is reused (shorter: a transient failure should heal soon).
    static let failureCacheSeconds: TimeInterval = 5 * 60
    /// How long one fresh measurement may take before the item reports "could not check".
    static let timeLimit: TimeInterval = 20
    /// Findings named in the status text.
    static let namedInStatus = 3
    /// Findings listed in the detail text.
    static let listedInDetail = 10

    struct Hit: Equatable {
        let package: String
        let installedVersion: String
        let fixedVersion: String
        let cveId: String
        let kev: Bool
        let epss: Double?
        /// A finding that is not a package + CVE pair (a PHP setting, say): shown instead of `package cveId`.
        var label: String? = nil
        /// What to do about it, for findings the detector explains (PHP).
        var note: String? = nil

        var shownName: String { label ?? "\(package) \(cveId)" }
    }

    /// What the PHP detector found: which findings need action. Kept apart from the Homebrew part so each can be
    /// tested without the other.
    struct PhpScan: Equatable {
        /// Any PHP interpreter, setting or Apache module was found.
        var found = false
        var hits: [Hit] = []
        static let none = PhpScan()
    }

    enum Outcome: Equatable {
        /// Homebrew is not installed.
        case brewMissing
        /// `brew list` could not be run or ended with an error.
        case brewFailed
        /// Homebrew is installed and lists no package.
        case noPackages
        /// The Homebrew map has no entries (never downloaded and no seed).
        case noMapData
        /// The measurement did not finish in `timeLimit`.
        case timedOut
        /// The map has no row for any installed package, so nothing could be compared.
        case noCoverage
        /// Of `packages` distinct installed packages, `covered` have a row in the map and were compared; nothing counts.
        case clear(packages: Int, covered: Int)
        /// No Homebrew packages to compare, but PHP was found and none of it needs action.
        case clearPhpOnly
        /// Every counting finding is covered by a risk acceptance that has not expired.
        case onlyAccepted(accepted: Int)
        /// `count` open findings (distinct package + CVE pairs); `hits` is the first of them, KEV first.
        case exposed(hits: [Hit], count: Int, accepted: Int)

        /// Could not be measured: no penalty, and `verify_security_findings` answers inconclusive.
        var unmeasuredReason: String? {
            switch self {
            case .brewFailed, .timedOut: return "tool_failed"
            case .noMapData, .noCoverage: return "not_verifiable"
            default: return nil
            }
        }

        /// There was nothing to look at (no Homebrew, or no package): not part of the score.
        var isNotApplicable: Bool {
            switch self {
            case .brewMissing, .noPackages: return true
            default: return unmeasuredReason != nil
            }
        }

        var passes: Bool {
            if case .exposed = self { return false }
            return true
        }
    }

    /// What the item shows besides the outcome: which data it compared with.
    struct Result: Equatable {
        var outcome: Outcome
        var mapVersion: String = ""
        var kevDate: String? = nil
    }

    /// Pure: how an inventory, a map and the person's acceptances become an outcome.
    static func evaluate(inventory: (packages: [PackageCveScan.InstalledPackage], state: PackageCveScan.InventoryState),
                         map: PackageCveScan.CveMap,
                         acceptances: VulnerabilityAcceptance.Store,
                         now: Date,
                         php: PhpScan = .none) -> Result {
        var result = evaluateHomebrew(inventory: inventory, map: map, acceptances: acceptances, now: now)
        result.outcome = merge(result.outcome, php: php)
        return result
    }

    /// The Homebrew part alone.
    private static func evaluateHomebrew(inventory: (packages: [PackageCveScan.InstalledPackage], state: PackageCveScan.InventoryState),
                                         map: PackageCveScan.CveMap,
                                         acceptances: VulnerabilityAcceptance.Store,
                                         now: Date) -> Result {
        switch inventory.state {
        case .brewMissing: return Result(outcome: .brewMissing)
        case .brewFailed: return Result(outcome: .brewFailed)
        case .read(let count) where count == 0: return Result(outcome: .noPackages)
        case .read: break
        }
        guard !map.entries.isEmpty else { return Result(outcome: .noMapData) }

        // Only entries a person confirmed against the CPE dictionary count: a guessed name match must not cost points.
        // A package the map has no row for can say nothing; how many could be compared is part of the answer.
        let mapped = Set(map.entries.map(\.package))
        let names = Set(inventory.packages.map(\.name))
        let covered = names.intersection(mapped).count
        guard covered > 0 else { return Result(outcome: .noCoverage, mapVersion: map.mapVersion, kevDate: map.kevDate) }
        let counting = PackageCveScan.scan(installed: inventory.packages, map: map).filter { f in
            f.confidence == "confirmed" && (f.kev || (f.epss ?? 0) >= epssThreshold)
        }
        var open: [PackageCveScan.Finding] = []
        var accepted = 0
        for f in counting {
            if let record = VulnerabilityAcceptance.record(for: f.acceptanceSubject, in: acceptances),
               case .active = VulnerabilityAcceptance.status(of: record, now: now) {
                accepted += 1
            } else {
                open.append(f)
            }
        }
        let packages = names.count
        var outcome: Outcome
        if open.isEmpty {
            outcome = accepted > 0 ? .onlyAccepted(accepted: accepted) : .clear(packages: packages, covered: covered)
        } else {
            // `scan` lists KEV first, then by severity and EPSS; one row per package + CVE.
            var seen = Set<String>()
            var hits: [Hit] = []
            for f in open where seen.insert(f.package + "|" + f.cveId).inserted {
                hits.append(Hit(package: f.package, installedVersion: f.installedVersion, fixedVersion: f.fixedVersion,
                                cveId: f.cveId, kev: f.kev, epss: f.epss))
            }
            outcome = .exposed(hits: hits, count: hits.count, accepted: accepted)
        }
        return Result(outcome: outcome, mapVersion: map.mapVersion, kevDate: map.kevDate)
    }
}

extension PackageCveExposure {

    /// Puts the PHP findings next to the Homebrew outcome. A PHP finding that needs action fails the item even when
    /// the Homebrew part could not be measured; PHP that was found and is fine makes a Mac without Homebrew
    /// packages count as checked.
    static func merge(_ brew: Outcome, php: PhpScan) -> Outcome {
        if !php.hits.isEmpty {
            switch brew {
            case .exposed(let hits, _, let accepted):
                let all = ordered(hits + php.hits)
                return .exposed(hits: all, count: all.count, accepted: accepted)
            case .onlyAccepted(let accepted):
                return .exposed(hits: ordered(php.hits), count: php.hits.count, accepted: accepted)
            default:
                return .exposed(hits: ordered(php.hits), count: php.hits.count, accepted: 0)
            }
        }
        if php.found {
            switch brew {
            case .brewMissing, .noPackages: return .clearPhpOnly
            default: break
            }
        }
        return brew
    }

    /// KEV first, then the higher EPSS; between equals the earlier one stays first (Homebrew before PHP).
    static func ordered(_ hits: [Hit]) -> [Hit] {
        hits.enumerated().sorted { a, b in
            if a.element.kev != b.element.kev { return a.element.kev }
            let ea = a.element.epss ?? -1, eb = b.element.epss ?? -1
            if ea != eb { return ea > eb }
            return a.offset < b.offset
        }.map(\.element)
    }

    /// The findings of the PHP detector that need action (severity high or worse), as hits. The two advisories of
    /// 2026-10-21 become one hit per CVE, like a package + CVE pair; `kev` says whether the daily CISA list names it.
    static func phpScan(from result: PhpCheckResult, kev: KevCatalog.Loaded?) -> PhpScan {
        let found = result.findings.contains { $0.id != "php_not_found" }
        var hits: [Hit] = []
        for f in result.findings where f.severity >= .high {
            switch f.id {
            case "php_version_unpatched", "php_version_no_upstream_fix":
                let version = f.version ?? ""
                var fixed = ""
                if case .unpatched(let release) = PhpEnvironment.verdict(forVersion: f.version) { fixed = release }
                for cve in ["CVE-2026-109618", "CVE-2026-109619"] {
                    hits.append(Hit(package: "php", installedVersion: version, fixedVersion: fixed, cveId: cve,
                                    kev: kev?.contains(cve) ?? false, epss: nil,
                                    note: (cve == "CVE-2026-109618" && !f.mitigation.isEmpty) ? f.mitigation : nil))
                }
            case "serialize_handler_combination":
                hits.append(Hit(package: "php", installedVersion: "", fixedVersion: "", cveId: "CVE-2026-115560",
                                kev: kev?.contains("CVE-2026-115560") ?? false, epss: nil, note: f.mitigation))
            default:
                hits.append(Hit(package: "php", installedVersion: "", fixedVersion: "", cveId: "", kev: false, epss: nil,
                                label: f.title, note: f.mitigation.isEmpty ? nil : f.mitigation))
            }
        }
        return PhpScan(found: found, hits: hits)
    }
}

/// Where the item gets its answer. The live one measures; a test hands in a fixed one.
protocol PackageCveSource {
    func result(now: Date) -> PackageCveExposure.Result
}

/// The live source: `brew list --versions` and the installed map, measured off the calling thread with a time
/// limit, and the answer kept in memory for 30 minutes.
final class SystemPackageCveSource: PackageCveSource {
    static let shared = SystemPackageCveSource()

    /// What one fresh measurement does (a test hands in another).
    private let measure: () -> PackageCveExposure.Result
    private let timeLimit: TimeInterval
    private let lock = NSLock()
    private var cached: (at: Date, result: PackageCveExposure.Result)?
    private var measuring = false

    init(timeLimit: TimeInterval = PackageCveExposure.timeLimit,
         measure: @escaping () -> PackageCveExposure.Result = SystemPackageCveSource.measureOnThisMac) {
        self.timeLimit = timeLimit
        self.measure = measure
    }

    private static func measureOnThisMac() -> PackageCveExposure.Result {
        let map = PackageCveScan.loadCVEMap()
        let fs = phpFS()
        // A Homebrew php that the map has rows for is judged by the map; the detector skips its version so the
        // install is not counted twice. A php the map cannot judge (no rows) is still judged by the detector.
        let mapped = Set(map.entries.map(\.package))
        let mapJudgesPhp = mapped.contains { $0 == "php" || $0.hasPrefix("php@") }
        let detected = PhpEnvironmentAudit.run(
            fs: fs,
            versionOf: { PhpEnvironment.runVersion(PhpInterpreter(kind: $0.kind, path: fs.real($0.path), version: nil)) },
            versionCountedElsewhere: { mapJudgesPhp && fs.resolved($0.path).contains("/Cellar/") })
        return PackageCveExposure.evaluate(
            inventory: PackageCveScan.enumerateHomebrewInventory(),
            map: map,
            acceptances: VulnerabilityAcceptance.load(),
            now: Date(),
            php: PackageCveExposure.phpScan(from: detected, kev: KevCatalog.loadInstalled()))
    }

    /// The disk the PHP detector reads. A debug build can point it at a fake Mac with `ROAMSWITCH_PHP_FS_ROOT` so a
    /// test run never depends on what is installed; a release build always reads the real disk.
    private static func phpFS() -> PhpFS {
        #if DEBUG
        if let root = ProcessInfo.processInfo.environment["ROAMSWITCH_PHP_FS_ROOT"], !root.isEmpty { return PhpFS(root: root) }
        #endif
        return PhpFS()
    }

    func result(now: Date) -> PackageCveExposure.Result {
        lock.lock()
        if let c = cached {
            let ttl = (c.result.outcome == .brewFailed || c.result.outcome == .timedOut)
                ? PackageCveExposure.failureCacheSeconds : PackageCveExposure.cacheSeconds
            if now.timeIntervalSince(c.at) < ttl { lock.unlock(); return c.result }
        }
        // A measurement that has not come back yet (a stuck brew) is not started a second time.
        if measuring { lock.unlock(); return PackageCveExposure.Result(outcome: .timedOut) }
        measuring = true
        lock.unlock()

        let done = DispatchSemaphore(value: 0)
        let box = ResultBox()
        let measure = self.measure
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let value = measure()
            box.set(value)
            self?.lock.lock()
            self?.cached = (now, value)
            self?.measuring = false
            self?.lock.unlock()
            done.signal()
        }
        if done.wait(timeout: .now() + timeLimit) == .timedOut {
            return PackageCveExposure.Result(outcome: .timedOut)
        }
        return box.get() ?? PackageCveExposure.Result(outcome: .timedOut)
    }

    private final class ResultBox: @unchecked Sendable {
        private let lock = NSLock()
        private var value: PackageCveExposure.Result?
        func set(_ v: PackageCveExposure.Result) { lock.lock(); value = v; lock.unlock() }
        func get() -> PackageCveExposure.Result? { lock.lock(); defer { lock.unlock() }; return value }
    }
}
