// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.16.2 (build 178).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// EPSS (FIRST's Exploit Prediction Scoring System) for the package CVE scans.
///
/// The signed CVE feeds may carry, per entry, an optional `epss` between 0 and 1 and, per map, an optional
/// `epssDate` (`YYYY-MM-DD`, the day the values were taken). Both are optional: a feed without them decodes
/// exactly as before, and a CVE without a value shows nothing. Nothing is estimated here and nothing is
/// fetched; the app only reads what the signed feed delivered.
///
/// EPSS estimates how likely exploitation activity is within the next 30 days. It is not a record that an
/// exploit exists or was used, so it is shown as a hint and used only to order findings of equal severity.
enum PackageCveEpss {

    /// A value from a feed, only if it is a finite number in 0...1.
    static func validated(_ raw: Double?) -> Double? {
        guard let raw, raw.isFinite, (0.0...1.0).contains(raw) else { return nil }
        return raw
    }

    /// A date from a feed, only if it has the shape `YYYY-MM-DD` (it is shown, never computed with).
    static func validatedDate(_ raw: String?) -> String? {
        guard let raw, raw.count == 10 else { return nil }
        let parts = raw.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              parts.allSatisfy({ $0.allSatisfy(\.isASCII) && $0.allSatisfy(\.isNumber) }) else { return nil }
        return raw
    }

    /// `EPSS 12% (2026-10-18)`; below one percent `EPSS <1%`. nil when the feed gave no value.
    static func label(epss: Double?, date: String?) -> String? {
        guard let epss = validated(epss) else { return nil }
        let percent = epss < 0.005 ? "<1%" : "\(Int((epss * 100).rounded()))%"
        if let date = validatedDate(date) { return "EPSS \(percent) (\(date))" }
        return "EPSS \(percent)"
    }

    /// Severity bands by CVSS v3 qualitative rating. Findings are ordered by band first, so a high EPSS never
    /// lifts a medium finding above a critical one.
    static func band(cvss: Double) -> Int {
        switch cvss {
        case 9.0...: return 3
        case 7.0..<9.0: return 2
        case 4.0..<7.0: return 1
        default: return 0
        }
    }

    /// True when `a` should be listed before `b`: higher band, then higher EPSS (a finding with a value before
    /// one without), then higher CVSS, then the CVE id.
    static func precedes(cvssA: Double, epssA: Double?, idA: String, cvssB: Double, epssB: Double?, idB: String) -> Bool {
        let bandA = band(cvss: cvssA), bandB = band(cvss: cvssB)
        if bandA != bandB { return bandA > bandB }
        let eA = validated(epssA), eB = validated(epssB)
        if eA != eB {
            guard let eA else { return false }
            guard let eB else { return true }
            return eA > eB
        }
        if cvssA != cvssB { return cvssA > cvssB }
        return idA < idB
    }
}
