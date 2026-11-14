// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.36 (build 215).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Pure `/etc/hosts` managed-section logic for the passive link guard.
/// Separated from `HelperTool` so it is unit-testable without root and without
/// touching the real `/etc/hosts`.
enum LinkGuardHosts {
    static let beginMarker = "# BEGIN RoamSwitch link guard — managed, do not edit"
    static let endMarker = "# END RoamSwitch link guard"

    /// `/etc/hosts` stays fast well past this, but cap so a runaway feed can
    /// never wedge name resolution.
    static let maxDomains = 60_000

    /// The lines of `hosts` with any existing managed section (and its trailing
    /// blank lines) removed.
    static func stripSection(_ hosts: String) -> [String] {
        var kept: [String] = []
        var inSection = false
        for line in hosts.components(separatedBy: "\n") {
            if line == beginMarker { inSection = true; continue }
            if line == endMarker { inSection = false; continue }
            if !inSection { kept.append(line) }
        }
        while kept.last == "" { kept.removeLast() }
        return kept
    }

    /// What Critical Path FIM should hash for `/etc/hosts`: everything *except*
    /// this feature's own routine output. The managed section is rewritten by
    /// RoamSwitch itself on every launch, mode change and feed refresh, so
    /// hashing the whole file made the app flag its own edits as tampering
    /// (a "/etc/hosts changed" critical alert right after every update).
    ///
    /// Lines outside the section are kept verbatim, so a real redirect
    /// (`1.2.3.4 bank.example`) is still detected. Inside the section only
    /// blank lines, comments and plain `0.0.0.0 <domain>` sinkhole entries are
    /// ignored; anything else in there (an entry pointing at a real address,
    /// hidden between the markers) is kept and therefore still changes the
    /// hash. An unterminated section is treated the same way.
    static func fimComparableContent(_ hosts: String) -> String {
        var kept: [String] = []
        var inSection = false
        for line in hosts.components(separatedBy: "\n") {
            if line == beginMarker { inSection = true; continue }
            if line == endMarker { inSection = false; continue }
            if !inSection {
                kept.append(line)
                continue
            }
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") || isSinkholeEntry(trimmed) { continue }
            kept.append("[in managed section] " + line)
        }
        while kept.last == "" { kept.removeLast() }
        return kept.joined(separator: "\n")
    }

    static func isSinkholeEntry(_ line: String) -> Bool {
        line.range(of: "^0\\.0\\.0\\.0 [a-z0-9]([a-z0-9.-]*[a-z0-9])?$", options: .regularExpression) != nil
    }

    /// Lowercase, trim, drop implausible entries and bare IPs, de-dupe, cap.
    static func sanitise(_ domains: [String]) -> [String] {
        var seen = Set<String>()
        var clean: [String] = []
        for d in domains {
            let host = d.trimmingCharacters(in: .whitespaces).lowercased()
            guard isPlausibleDomain(host), seen.insert(host).inserted else { continue }
            clean.append(host)
            if clean.count >= maxDomains { break }
        }
        return clean
    }

    /// New `/etc/hosts` content: the existing file with the managed section
    /// stripped, plus a fresh managed section for `domains` (omitted entirely
    /// when `domains` sanitises to empty).
    static func rewrite(existing: String, domains: [String]) -> (content: String, count: Int) {
        let clean = sanitise(domains)
        var out = stripSection(existing)
        if !clean.isEmpty {
            out.append("")
            out.append(beginMarker)
            out.append("# \(clean.count) domains — refreshed by RoamSwitch")
            for h in clean {
                out.append("0.0.0.0 \(h)")
                out.append("0.0.0.0 www.\(h)")
            }
            out.append(endMarker)
        }
        out.append("")
        return (out.joined(separator: "\n"), clean.count)
    }

    static func isPlausibleDomain(_ d: String) -> Bool {
        guard !d.isEmpty, d.count <= 253, d.contains("."),
              d.range(of: "^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$",
                      options: .regularExpression) != nil else { return false }
        // reject bare IPs
        return d.range(of: "^([0-9]{1,3}\\.){3}[0-9]{1,3}$", options: .regularExpression) == nil
    }
}
