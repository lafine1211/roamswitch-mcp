// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.3 (build 182).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Host-level verdict for the link-guard content filter, shared by the app and
/// the `RoamSwitchLinkFilter` system extension.
///
/// The extension runs as root and cannot read the user's `~/Library`, so the
/// filter's working set is published by the privileged helper to a
/// root-owned, world-readable directory:
///
///   /Library/Application Support/RoamSwitch/linkfilter/
///     feed.txt        one host per line (the threat feed ∪ blocklistExtra)
///     allowlist.txt   one host per line (user allowances)
///     mode            "off" | "warn" | "block"
///
/// Files are re-read when their mtime changes (checked at most every few
/// seconds), so a feed refresh or an allow takes effect without restarting the
/// extension.
public final class LinkFilterEngine {

    /// Self-contained so the system extension has no shared-code dependency.
    public enum Verdict { case allow, warn, block }
    public enum Mode: String { case off, warn, block }

    /// Which of `verdictWithReason`'s checks actually fired — threaded into
    /// `events.log` as a 4th field so the app's notification can say *why*
    /// a host was flagged, not just that it was.
    public enum VerdictReason: String { case feed, ja3, extra, homograph, comboSquat
        /// A security-test callback (OAST) server. Notice only: the verdict stays `.allow`.
        case callbackDomain }

    public static let shared = LinkFilterEngine()

    public static let stateDir = "/Library/Application Support/RoamSwitch/linkfilter"

    private let feedURL: URL
    /// JA3 TLS-client-fingerprint feed — same tier/reload cadence as
    /// `feedURL`. Not yet populated by anything (no updater source wired up
    /// for it — see the Linux daemon's `DEFAULT_JA3_FEED_PATH` doc comment
    /// for the equivalent, deliberate scope boundary); an absent file just
    /// means `ja3Hashes` stays empty and JA3 matching is a no-op, same as a
    /// missing `feed.txt`.
    private let ja3URL: URL
    private let extraURL: URL
    private let allowURL: URL
    private let modeURL: URL
    /// Append-only `<epoch>\t(block|warn)\t<host>` log the extension writes and
    /// the app tails to raise notifications. World-readable, tail-truncated.
    private let eventsURL: URL

    private let lock = NSLock()
    /// The threat feed (`feed.txt`) — large, reloaded only when its mtime moves.
    private var feedHosts = Set<String>()
    /// The JA3 fingerprint feed (`ja3.txt`, lowercase-hex MD5 hashes) — same
    /// reload tier as `feedHosts`.
    private var ja3Hashes = Set<String>()
    /// The user blocklist (`extra.txt`) — small, reloaded on the fast path too.
    private var extraHosts = Set<String>()
    private var allowed = Set<String>()
    private var mode: Mode = .block
    private var lastLoad = Date.distantPast
    private var lastMTimes: [String: Date] = [:]
    private var lastReported: [String: Date] = [:]

    private init() {
        let base = URL(fileURLWithPath: Self.stateDir, isDirectory: true)
        feedURL = base.appendingPathComponent("feed.txt")
        ja3URL = base.appendingPathComponent("ja3.txt")
        extraURL = base.appendingPathComponent("extra.txt")
        allowURL = base.appendingPathComponent("allowlist.txt")
        modeURL = base.appendingPathComponent("mode")
        eventsURL = base.appendingPathComponent("events.log")
        reloadIfChanged(force: true)
    }

    /// The current published mode (used by the filter to decide what to do with
    /// a flow it can't name, e.g. QUIC).
    public var currentMode: Mode {
        reloadIfChanged(force: false)
        lock.lock(); defer { lock.unlock() }
        return mode
    }

    /// The enforcement decision for a bare hostname (already lowercased).
    /// Records an event (→ `events.log` → app notification) for a non-`allow`.
    public func verdict(forHost host: String) -> Verdict {
        verdict(forHost: host, ja3Hash: nil)
    }

    /// Same decision, plus the JA3 fingerprint of the TLS connection this
    /// SNI was read from, if available — see `verdictRaw(forHost:ja3Hash:)`.
    public func verdict(forHost host: String, ja3Hash: String?) -> Verdict {
        verdict(forHost: host, ja3Hash: ja3Hash, sourceApp: nil)
    }

    /// As above, and `sourceApp` (the app the connection came from, `NEFilterFlow.sourceAppIdentifier`) goes into
    /// the event line so the notification can say which app tried to reach the host.
    public func verdict(forHost host: String, ja3Hash: String?, sourceApp: String?) -> Verdict {
        let (v, reason) = verdictWithReason(forHost: host, ja3Hash: ja3Hash)
        if v != .allow {
            recordEvent(v == .block ? "block" : "warn", host: host, reason: reason, sourceApp: sourceApp)
        } else if reason == .callbackDomain {
            // Notify only: the connection is allowed, the app shows a notice.
            recordEvent("notice", host: host, reason: reason, sourceApp: sourceApp)
        }
        return v
    }

    public func verdict(forHost host: String, sourceApp: String?) -> Verdict {
        verdict(forHost: host, ja3Hash: nil, sourceApp: sourceApp)
    }

    /// Same decision as `verdict(forHost:)` but with no event recorded — used by
    /// the system extension while polling a paused `warn` flow for the user's
    /// answer, where re-recording would be noise.
    public func verdictRaw(forHost host: String) -> Verdict {
        verdictRaw(forHost: host, ja3Hash: nil)
    }

    /// `ja3Hash`, when present, identifies the *client* making the
    /// connection rather than the destination — unlike every other check
    /// here, a match fires regardless of whether `host` itself looks wrong
    /// at all (the same malware/C2 toolkit connecting to a never-before-seen
    /// host still fingerprints the same way it always does). Treated as
    /// equally high-confidence as a feed hit on the hostname.
    public func verdictRaw(forHost host: String, ja3Hash: String?) -> Verdict {
        verdictWithReason(forHost: host, ja3Hash: ja3Hash).0
    }

    /// The decision, plus which check produced it — an ordered sequence of
    /// checks (previously a single combined `||` condition that discarded
    /// which branch fired, so `events.log` could only ever say *that* a host
    /// was flagged, never *why*).
    private func verdictWithReason(forHost rawHost: String, ja3Hash: String?) -> (Verdict, VerdictReason?) {
        let host = LinkFilterEngine.normalizedHost(rawHost)
        reloadIfChanged(force: false)
        lock.lock(); defer { lock.unlock() }
        return Self.decide(host: host, ja3Hash: ja3Hash, mode: mode, allowed: allowed,
                           feedHosts: feedHosts, extraHosts: extraHosts, ja3Hashes: ja3Hashes)
    }

    /// The ordered checks, free of files and locks so tests can drive them. `host` is already normalized.
    static func decide(host: String, ja3Hash: String?, mode: Mode, allowed: Set<String>,
                       feedHosts: Set<String>, extraHosts: Set<String>,
                       ja3Hashes: Set<String>) -> (Verdict, VerdictReason?) {
        if mode == .off { return (.allow, nil) }
        if matches(host, in: allowed) { return (.allow, nil) }
        if matches(host, in: feedHosts) {
            return (mode == .block) ? (.block, .feed) : (.warn, .feed)
        }
        if matches(host, in: extraHosts) {
            return (mode == .block) ? (.block, .extra) : (.warn, .extra)
        }
        if let ja3Hash, ja3Hashes.contains(ja3Hash.lowercased()) {
            return (mode == .block) ? (.block, .ja3) : (.warn, .ja3)
        }
        if LinkFilterEngine.isHomographBrandImpersonation(host) {
            return (mode == .block) ? (.block, .homograph) : (.warn, .homograph)
        }
        // A heuristic, not a confirmed match like the ones above — always
        // `.warn` (pause + ask), never an automatic `.block`, even in block
        // mode, to bound the impact of a false positive on this one.
        if LinkFilterEngine.isBrandComboSquat(host) { return (.warn, .comboSquat) }
        // Weakest signal, so it comes last. Never a block and never a hold: `.allow` with a reason,
        // which the caller turns into a notice.
        if CallbackDomains.matches(host) { return (.allow, .callbackDomain) }
        return (.allow, nil)
    }

    /// Is this host on the user's explicit blocklist (`extra.txt`)? Distinct
    /// from "on the threat feed": the extension uses this to turn a held `warn`
    /// into a drop the moment the user taps ブロック, even in `warn` mode.
    public func isUserBlocked(forHost host: String) -> Bool {
        reloadIfChanged(force: false)
        lock.lock(); defer { lock.unlock() }
        return Self.matches(LinkFilterEngine.normalizedHost(host), in: extraHosts)
    }

    /// `evil.com.`(FQDNの末尾ドット)は`evil.com`と同じ宛先だが、そのままでは完全一致にも
    /// サフィックス照合にも掛からず、ブロックを素通りする。小文字化・空白除去・末尾ドット除去。
    static func normalizedHost(_ host: String) -> String {
        var h = host.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        while h.hasSuffix(".") { h.removeLast() }
        return h
    }

    /// Re-read the small user-controlled files (`mode` / `allowlist.txt` /
    /// `extra.txt`) immediately, bypassing the periodic debounce and never
    /// touching the ~18 MB feed. The extension calls this while a `warn` flow is
    /// paused so the user's 許可 / ブロック tap lands within a second.
    public func reloadUserFilesNow() {
        lock.lock(); defer { lock.unlock() }
        reloadLocked(force: true, includeFeed: false)
    }

    // MARK: - Event log (extension → app notifications)

    /// One `events.log` line: `<epoch> TAB block|warn|notice TAB host TAB reason TAB sourceApp`. The 4th and 5th fields were
    /// added later: a reader of an older version ignores them. Tabs and line breaks cannot occur in a field.
    public static func eventLine(epoch: Int, kind: String, host: String, reason: String?, sourceApp: String?) -> String {
        func field(_ s: String?) -> String {
            String((s ?? "").unicodeScalars.filter { $0 != "\t" && $0 != "\n" && $0 != "\r" }.map(Character.init)).prefix(200).description
        }
        return "\(epoch)\t\(kind)\t\(field(host))\t\(field(reason))\t\(field(sourceApp))\n"
    }

    /// The parts of one `events.log` line; nil for a line that is not an event.
    public static func parseEventLine(_ line: Substring) -> (kind: String, host: String, reason: String?, sourceApp: String?)? {
        let f = line.split(separator: "\t", omittingEmptySubsequences: false)
        guard f.count >= 3 else { return nil }
        let kind = String(f[1]), host = String(f[2])
        guard kind == "block" || kind == "warn" || kind == "notice" else { return nil }
        func optional(_ i: Int) -> String? { f.count > i && !f[i].isEmpty ? String(f[i]) : nil }
        return (kind, host, optional(3), optional(4))
    }

    private func recordEvent(_ kind: String, host: String, reason: VerdictReason?, sourceApp: String? = nil) {
        lock.lock()
        // One line per host per hour — a busy page pulls a domain repeatedly.
        if let t = lastReported[host], Date().timeIntervalSince(t) < 3600 { lock.unlock(); return }
        lastReported[host] = Date()
        if lastReported.count > 512 {
            let cutoff = Date().addingTimeInterval(-3600)
            lastReported = lastReported.filter { $0.value > cutoff }
        }
        lock.unlock()

        // 4th field (reason) is new — a version-skewed reader during an
        // upgrade moment must still parse the first 3 fields fine.
        let line = Self.eventLine(epoch: Int(Date().timeIntervalSince1970), kind: kind, host: host, reason: reason?.rawValue, sourceApp: sourceApp)
        guard let data = line.data(using: .utf8) else { return }

        if let h = try? FileHandle(forWritingTo: eventsURL) {
            defer { try? h.close() }
            _ = try? h.seekToEnd()
            try? h.write(contentsOf: data)
        } else {
            try? data.write(to: eventsURL)
            try? FileManager.default.setAttributes([.posixPermissions: NSNumber(value: 0o644)],
                                                   ofItemAtPath: eventsURL.path)
        }
        // Keep the file bounded — the app only cares about the tail.
        if let size = try? FileManager.default.attributesOfItem(atPath: eventsURL.path)[.size] as? Int,
           size > 65_536,
           let all = try? Data(contentsOf: eventsURL) {
            try? all.suffix(16_384).write(to: eventsURL)
        }
    }

    // MARK: - Loading

    private func reloadIfChanged(force: Bool) {
        lock.lock(); defer { lock.unlock() }
        if !force, Date().timeIntervalSince(lastLoad) < 3 { return }
        lastLoad = Date()
        reloadLocked(force: force, includeFeed: true)
    }

    /// Caller holds `lock`. `includeFeed: false` reloads only the small
    /// user-controlled files, leaving the (tens-of-MB) feed untouched.
    private func reloadLocked(force: Bool, includeFeed: Bool) {
        var feedChanged = false
        var smallChanged = force
        let urls = includeFeed ? [feedURL, ja3URL, extraURL, allowURL, modeURL] : [extraURL, allowURL, modeURL]
        for url in urls {
            let m = (try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date) ?? nil
            if lastMTimes[url.path] != m {
                lastMTimes[url.path] = m
                if url == feedURL || url == ja3URL { feedChanged = true } else { smallChanged = true }
            }
        }
        if includeFeed, feedChanged {
            feedHosts = Self.hosts(from: feedURL)
            ja3Hashes = Self.ja3Hashes(from: ja3URL)
        }
        guard smallChanged else { return }
        extraHosts = Self.hosts(from: extraURL)
        allowed = Self.hosts(from: allowURL)
        if let raw = try? String(contentsOf: modeURL, encoding: .utf8),
           let m = Mode(rawValue: raw.trimmingCharacters(in: .whitespacesAndNewlines)) {
            mode = m
        }
    }

    private static func hosts(from url: URL) -> Set<String> {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        var out = Set<String>()
        for raw in text.split(separator: "\n") {
            let line = raw.split(separator: "#", maxSplits: 1).first
                .map(String.init)?.trimmingCharacters(in: .whitespaces) ?? ""
            if line.isEmpty { continue }
            // tolerate "0.0.0.0 host" hosts-file lines
            let host = line.split(separator: " ").last.map(String.init) ?? line
            out.insert(host.lowercased())
        }
        return out
    }

    /// Parses `ja3.txt`: one lowercase-hex MD5 hash per line, `#` comments,
    /// blank lines ignored — the JA3 counterpart to `hosts(from:)`.
    private static func ja3Hashes(from url: URL) -> Set<String> {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        var out = Set<String>()
        for raw in text.split(separator: "\n") {
            let line = raw.split(separator: "#", maxSplits: 1).first
                .map(String.init)?.trimmingCharacters(in: .whitespaces).lowercased() ?? ""
            guard line.count == 32, line.allSatisfy(\.isHexDigit) else { continue }
            out.insert(line)
        }
        return out
    }

    /// `evil.com` matches `evil.com`, `a.evil.com`, `a.b.evil.com` — but never a
    /// bare public suffix.
    static func matches(_ host: String, in set: Set<String>) -> Bool {
        if set.contains(host) { return true }
        var h = host[...]
        while let dot = h.firstIndex(of: ".") {
            h = h[h.index(after: dot)...]
            if !h.contains(".") { break }
            if set.contains(String(h)) { return true }
        }
        return false
    }

    // MARK: - Brand-homograph detection (UTS-#39-style skeleton compare)

    /// A curated set of confusable folds and protected brands, matching the
    /// Linux `roamswitch-core::link_guard::homograph` engine. Kept small and
    /// self-contained so the extension has no dependency on `LinkSafetyAuditor`.
    ///
    /// **Deliberately compares `skel` against `skeleton(brand)`, not the raw
    /// `brand` string.** `fold()` maps ASCII `l` to `i` (it's the classic
    /// `1`/`l`/`i` confusable triad), so `skeleton("apple")` is `"appie"`,
    /// not `"apple"` — comparing against the raw brand string here would
    /// mean this function could *never* match "apple" or "paypal" (the only
    /// two protected brands containing `l`) under any input, homograph or
    /// not. Found 2026-09-23 via on-device testing.
    ///
    /// Also excludes `label == brand` (the exact, unmodified real domain) —
    /// necessary precisely because comparing skeleton-to-skeleton (rather
    /// than skeleton-to-raw) now correctly matches the real domain's own
    /// skeleton too; without this exclusion every visit to the real
    /// apple.com/paypal.com would self-flag as impersonating itself.
    static func isHomographBrandImpersonation(_ host: String) -> Bool {
        let label = host.split(separator: ".").first.map(String.init) ?? host
        let skel = skeleton(label)
        for (brand, brandSkel) in protectedBrandSkeletons where skel == brandSkel && label != brand {
            return true
        }
        return false
    }

    /// Common words a credential-harvesting page combines with a brand name
    /// in a freshly registered domain that is not the brand's own —
    /// `microsoft-security-alert.com`, `my-paypal-security.com`. Local
    /// threat feeds can't catch this until the domain gets reported (up to
    /// 24h delay), and it's neither a Unicode/ASCII-confusable substitution
    /// (`isHomographBrandImpersonation`'s job) nor a subdomain-embedding
    /// trick (`LinkSafetyAuditor.detectSubdomainSpoofing`'s job) — the whole
    /// label just legitimately contains both an unmodified brand name and
    /// one of these words. Deliberately narrow to keep the false-positive
    /// rate down: generic words like "app" or "shop" are excluded.
    private static let comboSquatWords: Set<String> = [
        "security", "secure", "support", "verify", "verification", "login",
        "signin", "account", "update", "confirm", "alert", "service", "help",
        "billing", "password", "unlock", "suspended", "restore", "recover",
    ]

    /// Brands eligible for the substring-based combosquat check below, as
    /// their **folded skeletons** — not the raw spelling. `fold()` remaps
    /// ASCII `l` to `i` even for correctly-spelled text (see
    /// `isHomographBrandImpersonation`'s header comment), so `skeleton(label)`
    /// below would contain `"paypai"`, never literal `"paypal"`; matching
    /// against the raw brand string here has the exact same "can never
    /// match a brand containing l" bug that function had. Short codes
    /// (`au`, `jcb`, 4-letter bank abbreviations) are excluded — as a bare
    /// substring (not a whole-label skeleton match) they collide with
    /// unrelated English words far too easily (`au` alone matches "author",
    /// "august", ...).
    private static let comboSquatEligibleBrandSkeletons: Set<String> =
        Set(protectedBrands.filter { $0.count >= 5 }.map(skeleton))

    /// True when the label both contains a protected brand name as a
    /// substring and combines it with a common phishing-page word, and the
    /// label is not the brand's own exact domain. A heuristic, not a
    /// confirmed match the way a threat-feed hit or a homograph is —
    /// callers must treat a `true` result as advisory (`.warn`), never an
    /// automatic `.block`.
    static func isBrandComboSquat(_ host: String) -> Bool {
        let label = (host.split(separator: ".").first.map(String.init) ?? host).lowercased()
        guard !protectedBrands.contains(label) else { return false }
        // Skeleton-fold first so an ASCII-confusable combo (`amaz0n-support`)
        // is caught too, not just an exact-spelling one.
        let skel = skeleton(label)
        guard comboSquatEligibleBrandSkeletons.contains(where: { skel.contains($0) }) else { return false }
        return comboSquatWords.contains { skel.contains($0) }
    }

    private static let protectedBrands: Set<String> = [
        "apple", "icloud", "google", "gmail", "microsoft", "office365", "amazon",
        "paypal", "facebook", "instagram", "netflix", "coinbase", "binance",
        "rakuten", "mufg", "smbc", "mizuho", "jcb", "aeon", "yamato", "sagawa",
        "jppost", "nexco", "docomo", "softbank", "au", "etax", "amex",
    ]

    private static let protectedBrandSkeletons: [String: String] =
        Dictionary(uniqueKeysWithValues: protectedBrands.map { ($0, skeleton($0)) })

    private static func skeleton(_ s: String) -> String {
        String(s.lowercased().unicodeScalars.map { fold(Character($0)) })
    }

    private static func fold(_ c: Character) -> Character {
        switch c {
        case "а", "ａ", "α", "@", "４": return "a"
        case "е", "ё", "ｅ", "３": return "e"
        case "о", "ο", "ｏ", "０", "0": return "o"
        case "р", "ρ", "ｐ": return "p"
        case "с", "ｃ": return "c"
        case "ѕ", "ｓ", "$", "５": return "s"
        case "х", "χ", "ｘ": return "x"
        case "у", "ｙ": return "y"
        case "і", "ӏ", "ｉ", "1", "l", "|", "！": return "i"
        case "ԁ", "ｄ": return "d"
        case "ɡ", "ｇ": return "g"
        case "һ", "ｈ": return "h"
        case "ｋ": return "k"
        case "ｍ": return "m"
        case "ｎ": return "n"
        case "ｒ": return "r"
        case "ｔ", "７": return "t"
        case "ｕ": return "u"
        default: return c
        }
    }
}


/// Hosts of public out-of-band (OAST) servers. Security-testing tools (interactsh, Burp Collaborator,
/// DNSLog, CEYE) make a victim connect to a unique name under one of these to prove an SSRF, XXE or RCE
/// worked. A normal app has almost no reason to connect to them. Used for a notice only, never a block.
/// The Linux list is the same: `roamswitch-core/src/callback_domains.rs`.
public enum CallbackDomains {
    public static let apexes: [String] = [
        "interact.sh", "oast.pro", "oast.live", "oast.site", "oast.online", "oast.fun", "oast.me",
        "burpcollaborator.net", "oastify.com", "dnslog.cn", "ceye.io",
    ]

    /// True for an apex itself or any subdomain of it, on a label boundary (`toast.pro` does not match
    /// `oast.pro`). Case-insensitive; a trailing dot is ignored.
    public static func matches(_ rawHost: String) -> Bool {
        let host = LinkFilterEngine.normalizedHost(rawHost)
        guard !host.isEmpty else { return false }
        return apexes.contains { host == $0 || host.hasSuffix("." + $0) }
    }
}
