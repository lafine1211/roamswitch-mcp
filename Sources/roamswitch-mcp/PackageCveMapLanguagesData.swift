// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.0 (build 57).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
// Seed data — deliberately empty, one map per language ecosystem. Each map
// is entirely mechanically generated (roamswitch-linux's
// scripts/gen_package_cve_map_osv.py, from OSV.dev's per-ecosystem dump,
// CVSS >= 7.0, no recency cutoff — see PackageCveScanLanguages.swift's doc
// comment and roamswitch-linux/docs/PACKAGE_CVE_SCAN_SPEC.ja.md), never
// hand-populated here. A real dataset arrives only via
// PackageCveMapUpdater's daily signed manifest fetch (one manifest entry
// per ecosystem, under `packageCveMapLanguages`); until then, the
// corresponding ecosystem's scan reports nothing rather than fabricating or
// approximating data.
enum PackageCveMapLanguagesData {
    private static let seeds: [String: String] = [
        "npm": #"""
        {"mapVersion":"2026-09-08-seed","ecosystem":"npm","minScore":7.0,"entries":[]}
        """#,
        "pypi": #"""
        {"mapVersion":"2026-09-08-seed","ecosystem":"PyPI","minScore":7.0,"entries":[]}
        """#,
        "cratesio": #"""
        {"mapVersion":"2026-09-08-seed","ecosystem":"crates.io","minScore":7.0,"entries":[]}
        """#,
        "rubygems": #"""
        {"mapVersion":"2026-09-08-seed","ecosystem":"RubyGems","minScore":7.0,"entries":[]}
        """#,
        "packagist": #"""
        {"mapVersion":"2026-09-08-seed","ecosystem":"Packagist","minScore":7.0,"entries":[]}
        """#,
        "go": #"""
        {"mapVersion":"2026-09-08-seed","ecosystem":"Go","minScore":7.0,"entries":[]}
        """#,
        "maven": #"""
        {"mapVersion":"2026-09-08-seed","ecosystem":"Maven","minScore":7.0,"entries":[]}
        """#,
    ]

    static func embeddedJSON(forFileKey key: String) -> String {
        seeds[key] ?? #"{"mapVersion":"","ecosystem":"","entries":[]}"#
    }
}
