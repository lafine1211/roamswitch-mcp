// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.9 (build 66).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
// Seed data — deliberately empty. This map is entirely mechanically
// generated (roamswitch-linux's scripts/gen_package_cve_map_homebrew.py,
// which pulls real CVE/CVSS/version-range data from NVD's CVE API for a
// hand-curated formula→CPE allowlist, plus a lower-confidence "gray" tier
// from an exact-keyword CPE match — see PackageCveScan.swift's doc comment
// and roamswitch-linux/docs/PACKAGE_CVE_SCAN_SPEC.ja.md §7), never
// hand-populated here. A real dataset arrives only via
// PackageCveMapUpdater's daily signed manifest fetch; until then, the
// Homebrew package-CVE scan reports nothing rather than fabricating or
// approximating data.
enum PackageCveMapData {
    static let embeddedJSON = #"""
{"mapVersion":"","ecosystem":"Homebrew","entries":[]}
"""#
}
