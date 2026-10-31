// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.17 (build 196).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import Darwin

/// IP addresses a named public source has published as attack servers, and the pf rules that cut
/// them off. Only addresses that source printed itself belong here, with the source and date:
/// rented-server addresses get reassigned, so an entry can outlive its attacker.
///
/// Source: JPCERT/CC, "Web・API を狙う攻撃" report, 2026-10-15, Appendix B (IoC),
/// https://blogs.jpcert.or.jp/ja/2026/10/web_api_attacks.html
///
/// Shared by the app (the link audit names these addresses) and the privileged helper
/// (`PFRulesetCoordinator` drops traffic to and from them). Linux mirror: `KNOWN_ATTACK_IPS` in
/// `link_safety.rs` and `assets/threatfeed/malicious_ips.txt`.
enum KnownAttackServers {
    static let ips: [String] = ["210.149.87.120", "118.26.36.16", "69.10.51.162"]

    /// `ips` that are well-formed addresses, so a bad entry can never become rule text.
    static func validIPs(_ candidates: [String] = KnownAttackServers.ips) -> [String] {
        candidates.filter { ip in
            var v4 = in_addr(), v6 = in6_addr()
            return inet_pton(AF_INET, ip, &v4) == 1 || inet_pton(AF_INET6, ip, &v6) == 1
        }
    }

    /// Both directions are dropped. Unlike the port-scan block (which only refuses new inbound
    /// SYNs, because a forged scan "from" the gateway must not cut this Mac off), these are fixed
    /// public addresses that are not the gateway, a resolver or this Mac, so matching on the
    /// address alone cannot be turned against the user.
    static func egressBlockRules(_ candidates: [String] = KnownAttackServers.ips) -> String {
        let valid = validIPs(candidates)
        let v4 = valid.filter { !$0.contains(":") }
        let v6 = valid.filter { $0.contains(":") }
        var s = ""
        if !v4.isEmpty {
            let l = v4.joined(separator: ", ")
            s += "block drop quick inet from any to { \(l) }\n"
            s += "block drop quick inet from { \(l) } to any\n"
        }
        if !v6.isEmpty {
            let l = v6.joined(separator: ", ")
            s += "block drop quick inet6 from any to { \(l) }\n"
            s += "block drop quick inet6 from { \(l) } to any\n"
        }
        return s
    }

    /// Puts the block rules right after `anchorCall` (the main ruleset's anchor line). They are
    /// `quick`, so they must come before the `pass quick` holes of a kill-switch ruleset to win.
    /// Without that anchor line they go after `set skip on lo0`, and failing that at the top.
    static func insertingEgressBlock(into rules: String, anchorCall: String, ips: [String] = KnownAttackServers.ips) -> String {
        let block = egressBlockRules(ips)
        guard !block.isEmpty else { return rules }
        if let r = rules.range(of: anchorCall) {
            return rules.replacingCharacters(in: r, with: anchorCall + block)
        }
        let skip = "set skip on lo0\n"
        if let r = rules.range(of: skip) {
            return rules.replacingCharacters(in: r, with: skip + block)
        }
        return block + rules
    }
}
