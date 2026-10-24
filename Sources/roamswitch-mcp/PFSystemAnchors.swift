// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.6 (build 185).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// macOS の標準の `/etc/pf.conf` は、`com.apple/*` の下のアンカーを、整形(scrub)・NAT・転送(rdr)・帯域制御(dummynet)・
/// フィルターの順に呼ぶ。インターネット共有や、Tart・UTM・Docker の仮想マシンの NAT は、この下のアンカーに NAT の規則を入れる。
/// RoamSwitch が自分の規則だけで主のルールセットを読み込み直すと、`anchor` の呼び出しだけが残り、NAT の呼び出しが消える。
/// すると仮想マシンは、ゲートウェイには届くが、外へ出られなくなる。
/// 読み込む規則に、標準と同じ 4 つの呼び出しを足して、他のツールのアンカーを RoamSwitch の規則が消さないようにする。
enum PFSystemAnchors {
    static let preamble = """
    scrub-anchor "com.apple/*"
    nat-anchor "com.apple/*"
    rdr-anchor "com.apple/*"
    dummynet-anchor "com.apple/*"

    """

    /// `set skip on lo0` の行の直後に足す(pf はオプション、整形、変換、フィルターの順に書く)。その行がなければ先頭に足す。
    /// すでに `nat-anchor "com.apple/*"` を含む規則には足さない。
    static func inserting(into rules: String) -> String {
        if rules.contains("nat-anchor \"com.apple/*\"") { return rules }
        let skip = "set skip on lo0\n"
        if let r = rules.range(of: skip) {
            return rules.replacingCharacters(in: r, with: skip + preamble)
        }
        return preamble + rules
    }
}
