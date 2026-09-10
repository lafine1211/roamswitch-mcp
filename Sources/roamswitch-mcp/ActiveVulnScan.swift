// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.18 (build 75).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import Network

/// Phase 2 & 3 of the active-vulnerability-verification roadmap (see
/// `roamswitch-linux/docs/ACTIVE_VULN_SCAN_SPEC.ja.md`) — the macOS counterpart of the
/// Linux client's `active_vuln_scan.rs` (Phase 2) and `web_vuln_scan.rs` (Phase 3).
///
/// Unlike `ServiceSignatures.swift` (Phase 1, zero network I/O), this file actually
/// connects to a listening service on `127.0.0.1` and sends a minimal, read-only probe
/// to confirm whether it is really reachable without authentication — not just "the
/// port is open."
///
/// Safety invariants (same as the Linux implementation):
/// - Every target is `127.0.0.1` only. Targets are derived exclusively from this
///   machine's own `ListeningPortMonitor` output.
/// - Every probe is a single connection attempt with a short timeout and no retries.
/// - Every probe is read-only: it asks "are you there, unauthenticated?" and nothing
///   else. No write/delete/config-changing command is ever sent.
/// - Disabled unless `UserDefaults.standard.bool(forKey: "RoamSwitch.ActiveVulnScanEnabled")`
///   is true (opt-in, off by default) — callers must check this before invoking anything
///   here; this file performs no work on its own.
enum ActiveVulnScan {

    static let enabledDefaultsKey = "RoamSwitch.ActiveVulnScanEnabled"

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: enabledDefaultsKey)
    }

    struct Finding {
        let port: Int
        let processName: String
        let title: String
        let description: String
        let recommendation: String
    }

    // MARK: - Phase 2: known-service raw-TCP probes

    /// Sends a single non-destructive `PING` to a Redis-protocol port and checks whether
    /// it answers without requiring `AUTH`. `nil` means inconclusive (connection failed,
    /// timed out, or closed) — never treated as a finding either way.
    static func probeRedisNoAuth(port: Int, timeout: TimeInterval = 2.0) -> Bool? {
        guard let response = sendRawTCP(port: port, payload: Data("PING\r\n".utf8), timeout: timeout) else {
            return nil
        }
        return String(decoding: response, as: UTF8.self).hasPrefix("+PONG")
    }

    /// Sends a single non-destructive `stats` command (read-only server statistics, not a
    /// data key) to a Memcached port and checks for the standard `STAT ...` response.
    static func probeMemcachedNoAuth(port: Int, timeout: TimeInterval = 2.0) -> Bool? {
        guard let response = sendRawTCP(port: port, payload: Data("stats\r\n".utf8), timeout: timeout) else {
            return nil
        }
        return String(decoding: response, as: UTF8.self).hasPrefix("STAT ")
    }

    /// Sends a single non-destructive `listDatabases` command (`OP_MSG`) and checks
    /// whether the server actually answers it, rather than rejecting it as requiring
    /// authentication.
    ///
    /// This deliberately does **not** use the `isMaster`/`hello` handshake command:
    /// MongoDB allows that one before authentication *by design* (drivers need it to
    /// negotiate wire-protocol capabilities before they can even attempt to log in) —
    /// confirmed empirically while building the Linux counterpart against a real
    /// `mongo:6` container, which answered `isMaster` successfully regardless of whether
    /// `--auth` was enabled. `listDatabases` has no such pre-auth exemption: an
    /// auth-enabled server replies with `errmsg: "command listDatabases requires
    /// authentication"`, while an open one replies with a `databases` array — verified
    /// against the same container. See `active_vuln_scan.rs::probe_mongod_noauth` for
    /// the identical Linux implementation this mirrors byte-for-byte.
    static func probeMongoDBNoAuth(port: Int, timeout: TimeInterval = 2.0) -> Bool? {
        guard let response = sendRawTCP(port: port, payload: buildMongoListDatabasesOpMsg(), timeout: timeout) else {
            return nil
        }
        // The success response's BSON contains the field name "databases" (lowercase).
        // The auth-required error only ever echoes the command name "listDatabases"
        // (mixed case) inside its error message — the two never collide.
        return String(decoding: response, as: UTF8.self).contains("databases")
    }

    /// BSON `{ listDatabases: 1, $db: "admin" }` wrapped in an `OP_MSG` (opcode 2013)
    /// wire-protocol message. The query is fixed, so its bytes are constructed
    /// explicitly here rather than via a general-purpose BSON encoder.
    private static func buildMongoListDatabasesOpMsg() -> Data {
        var docBody = Data()
        docBody.append(0x10) // type: int32
        docBody.append(Data("listDatabases\0".utf8))
        docBody.append(contentsOf: withUnsafeBytes(of: Int32(1).littleEndian) { Data($0) })
        docBody.append(0x02) // type: string
        docBody.append(Data("$db\0".utf8))
        docBody.append(contentsOf: withUnsafeBytes(of: Int32(6).littleEndian) { Data($0) }) // "admin" + null
        docBody.append(Data("admin\0".utf8))

        var document = Data()
        let docLen = Int32(4 + docBody.count + 1)
        document.append(contentsOf: withUnsafeBytes(of: docLen.littleEndian) { Data($0) })
        document.append(docBody)
        document.append(0x00)

        var body = Data()
        body.append(contentsOf: withUnsafeBytes(of: UInt32(0).littleEndian) { Data($0) }) // flagBits
        body.append(0x00) // section kind 0
        body.append(document)

        var message = Data()
        let messageLength = Int32(16 + body.count)
        message.append(contentsOf: withUnsafeBytes(of: messageLength.littleEndian) { Data($0) })
        message.append(contentsOf: withUnsafeBytes(of: Int32(1).littleEndian) { Data($0) }) // requestID
        message.append(contentsOf: withUnsafeBytes(of: Int32(0).littleEndian) { Data($0) }) // responseTo
        message.append(contentsOf: withUnsafeBytes(of: Int32(2013).littleEndian) { Data($0) }) // opCode: OP_MSG
        message.append(body)
        return message
    }

    /// Opens a single TCP connection to `127.0.0.1:port`, writes `payload`, reads
    /// whatever comes back within `timeout`, and closes. Returns `nil` on any
    /// connection/timeout failure — never a `Bool`, since an inconclusive probe must
    /// never be treated as evidence either way.
    private static func sendRawTCP(port: Int, payload: Data, timeout: TimeInterval) -> Data? {
        guard let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else { return nil }
        let connection = NWConnection(host: "127.0.0.1", port: nwPort, using: .tcp)
        let semaphore = DispatchSemaphore(value: 0)
        var result: Data?

        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                connection.send(content: payload, completion: .contentProcessed { _ in
                    connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { data, _, _, _ in
                        result = data
                        semaphore.signal()
                    }
                })
            case .failed, .cancelled:
                semaphore.signal()
            default:
                break
            }
        }
        connection.start(queue: DispatchQueue.global(qos: .utility))
        _ = semaphore.wait(timeout: .now() + timeout)
        connection.cancel()
        return result
    }

    // MARK: - Known-CVE version matching

    /// One version range known to be affected by a specific CVE. Matching is by
    /// semver-range only — never sends an actual exploit or DoS payload, only a
    /// harmless version-reporting command. `title`/`description`/`recommendation`
    /// are full per-language dictionaries (keyed by the same 10 language codes as
    /// `Localizable.xcstrings`'s `pt-PT`-style codes) rather than a single Japanese
    /// string routed through `loc(_:)` — this map can add genuinely new CVEs via the
    /// daily updater alone, without waiting for an app release to ship new
    /// translated strings, so the translations must travel with the data itself.
    /// Mirrors `roamswitch-core`'s `ActiveVulnCveEntry`/`ActiveVulnCveMap` exactly.
    struct KnownCVE: Decodable {
        let cveId: String
        let signatureID: String
        let minVersion: [Int]
        let fixedVersion: [Int]
        let title: [String: String]
        let description: [String: String]
        let recommendation: [String: String]

        enum CodingKeys: String, CodingKey {
            case cveId, signatureID = "signatureId", minVersion, fixedVersion
            case title, description, recommendation
        }
    }

    struct CVEMap: Decodable {
        let mapVersion: String
        let entries: [KnownCVE]
    }

    private static func versionLess(_ a: [Int], _ b: [Int]) -> Bool {
        for i in 0..<3 {
            if a[i] != b[i] { return a[i] < b[i] }
        }
        return false
    }

    private static func versionGreaterOrEqual(_ a: [Int], _ b: [Int]) -> Bool {
        !versionLess(a, b)
    }

    /// Where `ActiveVulnCveMapUpdater` installs a fresher signed copy (desktop client
    /// only). Preferred over the bundled baseline when present and its `mapVersion` is
    /// newer — mirrors `roamswitch-core::active_vuln_scan::load_cve_map` exactly.
    static let updatedCVEMapURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RoamSwitch", isDirectory: true)
        return base.appendingPathComponent("active_vuln_cve_map.json")
    }()

    private static func loadCVEMap() -> CVEMap {
        let decoder = JSONDecoder()
        // Compiled in via `ActiveVulnCveMapData.swift` rather than loaded as a bundle
        // resource: `RoamSwitchMCPServer` is a bare `tool` target with no `.app`
        // bundle (`Bundle.main.url(forResource:)` always returns nil there), so a real
        // resource file would silently leave the MCP server with zero baseline data.
        // A compiled-in string works identically in both the app and the tool target.
        let bundled: CVEMap = (try? decoder.decode(CVEMap.self, from: Data(ActiveVulnCveMapData.embeddedJSON.utf8)))
            ?? CVEMap(mapVersion: "", entries: [])
        if let data = try? Data(contentsOf: updatedCVEMapURL),
           let updated = try? decoder.decode(CVEMap.self, from: data),
           updated.mapVersion >= bundled.mapVersion {
            return updated
        }
        return bundled
    }

    /// Resolves one entry's text for the active app language, falling back to English
    /// then Japanese then whatever the map happens to have, so a partially-translated
    /// feed update (e.g. a brand-new CVE added upstream before every language catches
    /// up) never surfaces an empty string. Mirrors the Linux implementation's
    /// `resolve_lang`.
    private static func resolveLang(_ dict: [String: String]) -> String {
        let lang = AppLanguage.activeLocaleCode
        return dict[lang] ?? dict["en"] ?? dict["ja"] ?? dict.values.first ?? ""
    }

    /// Parses a `"6.0.19"`-style version string into `[major, minor, patch]`, tolerating
    /// a trailing non-numeric suffix on the patch component (e.g. `"6.2.13-beta1"`).
    private static func parseSemver(_ s: String) -> [Int]? {
        let parts = s.trimmingCharacters(in: .whitespaces).split(separator: ".")
        guard !parts.isEmpty, let major = Int(parts[0]) else { return nil }
        let minor = parts.count > 1 ? (Int(parts[1]) ?? 0) : 0
        let patchDigits = parts.count > 2 ? parts[2].prefix(while: { $0.isNumber }) : ""
        let patch = patchDigits.isEmpty ? 0 : (Int(patchDigits) ?? 0)
        return [major, minor, patch]
    }

    /// Returns every map entry the version matches, not just the first — several of
    /// these CVEs have genuinely overlapping affected ranges (distinct bugs that happen
    /// to affect the same versions), so a single instance can legitimately be vulnerable
    /// to more than one at once. Mirrors the Linux implementation's `find_known_cves`.
    private static func findKnownCVEs(signatureID: String, version: [Int]) -> [KnownCVE] {
        loadCVEMap().entries.filter {
            $0.signatureID == signatureID
                && versionGreaterOrEqual(version, $0.minVersion)
                && versionLess(version, $0.fixedVersion)
        }
    }

    /// Sends a single non-destructive `INFO server` command and extracts
    /// `redis_version:X.Y.Z` from the plain-text response.
    static func probeRedisVersion(port: Int, timeout: TimeInterval = 2.0) -> String? {
        guard let response = sendRawTCP(port: port, payload: Data("INFO server\r\n".utf8), timeout: timeout) else {
            return nil
        }
        let text = String(decoding: response, as: UTF8.self)
        for line in text.split(separator: "\r\n") where line.hasPrefix("redis_version:") {
            return String(line.dropFirst("redis_version:".count)).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    /// Reuses the same `stats` response `probeMemcachedNoAuth` already sends and extracts
    /// the `STAT version X.Y.Z` line from it.
    static func probeMemcachedVersion(port: Int, timeout: TimeInterval = 2.0) -> String? {
        guard let response = sendRawTCP(port: port, payload: Data("stats\r\n".utf8), timeout: timeout) else {
            return nil
        }
        let text = String(decoding: response, as: UTF8.self)
        for line in text.split(separator: "\r\n") where line.hasPrefix("STAT version ") {
            return String(line.dropFirst("STAT version ".count)).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    private static func probeVersion(signatureID: String, port: Int, timeout: TimeInterval) -> String? {
        switch signatureID {
        case "redis-default-noauth": return probeRedisVersion(port: port, timeout: timeout)
        case "memcached-noauth": return probeMemcachedVersion(port: port, timeout: timeout)
        default: return nil
        }
    }

    // MARK: - Phase 3: generic dev-server HTTP checks (endpoint-agnostic)

    private static let corsTestOrigin = "http://roamswitch-cors-probe.invalid"

    /// Sends one GET to `/` with an arbitrary, never-allow-listed `Origin` header and
    /// checks whether the response reflects it (or sends a wildcard) *together with*
    /// `Access-Control-Allow-Credentials: true` — the actually exploitable combination.
    /// A bare wildcard without credentials is deliberately not flagged, to keep the
    /// false-positive rate low (many public/no-auth dev APIs use `*` safely).
    static func probeCorsMisconfiguration(port: Int, timeout: TimeInterval = 2.0) -> Bool? {
        guard let url = URL(string: "http://127.0.0.1:\(port)/") else { return nil }
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "GET"
        request.setValue(corsTestOrigin, forHTTPHeaderField: "Origin")

        guard let response = syncHTTPRequest(request, timeout: timeout) as? HTTPURLResponse else { return nil }
        let acao = response.value(forHTTPHeaderField: "Access-Control-Allow-Origin") ?? ""
        let acac = response.value(forHTTPHeaderField: "Access-Control-Allow-Credentials") ?? ""

        let reflectsOrWildcard = acao == "*" || acao == corsTestOrigin
        let credentialsAllowed = acac.caseInsensitiveCompare("true") == .orderedSame
        return reflectsOrWildcard && credentialsAllowed
    }

    /// A handful of common path-traversal encodings against the root path, targeting
    /// `/etc/passwd` — world-readable on macOS, so this stays a pure reachability proof
    /// and never needs to touch anything sensitive.
    private static let traversalPayloads = [
        "/../../../../../../../../etc/passwd",
        "/..%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2fetc%2fpasswd",
        "/static/../../../../../../etc/passwd",
    ]

    /// macOS's `/etc/passwd` uses `root:*:0:0:` (an asterisk in the password field —
    /// this file is a legacy stub next to Open Directory, not shadow-password-backed).
    /// This is deliberately **not** the same marker as the Linux implementation's
    /// `root:x:0:0:` — each targets the real format of the OS it actually runs on.
    private static let passwdMarker = "root:*:0:0:"

    /// Tries each payload in turn and stops at the first one that gets a reachable
    /// response containing the passwd marker.
    static func probePathTraversal(port: Int, timeout: TimeInterval = 2.0) -> Bool? {
        var sawAnyResponse = false
        for payload in traversalPayloads {
            guard let url = URL(string: "http://127.0.0.1:\(port)\(payload)") else { continue }
            var request = URLRequest(url: url, timeoutInterval: timeout)
            request.httpMethod = "GET"
            guard let data = syncHTTPBody(request, timeout: timeout) else { continue }
            sawAnyResponse = true
            if String(decoding: data, as: UTF8.self).contains(passwdMarker) {
                return true
            }
        }
        return sawAnyResponse ? false : nil
    }

    /// Ephemeral-session, no-cache GET matching `PortSecurityAuditor.probeHTTPService`'s
    /// isolation settings — this is a security-audit probe, not a normal browse request.
    private static func syncHTTPRequest(_ request: URLRequest, timeout: TimeInterval) -> URLResponse? {
        var result: URLResponse?
        let semaphore = DispatchSemaphore(value: 0)
        let config = URLSessionConfiguration.ephemeral
        config.httpShouldSetCookies = false
        config.httpCookieAcceptPolicy = .never
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.timeoutIntervalForRequest = timeout
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        let task = session.dataTask(with: request) { _, response, _ in
            result = response
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + timeout + 0.5)
        return result
    }

    private static func syncHTTPBody(_ request: URLRequest, timeout: TimeInterval) -> Data? {
        var result: Data?
        let semaphore = DispatchSemaphore(value: 0)
        let config = URLSessionConfiguration.ephemeral
        config.httpShouldSetCookies = false
        config.httpCookieAcceptPolicy = .never
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.timeoutIntervalForRequest = timeout
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        let task = session.dataTask(with: request) { data, response, _ in
            if response is HTTPURLResponse {
                result = data ?? Data()
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + timeout + 0.5)
        return result
    }

    /// `URLSession` follows redirects transparently by default, which would hide the
    /// very `3xx` + `Location` response this probe needs to see. This delegate refuses
    /// every redirect (`completionHandler(nil)`) so the initial response is what
    /// `syncHTTPRequestNoRedirect` receives instead.
    private final class NoRedirectDelegate: NSObject, URLSessionTaskDelegate {
        func urlSession(
            _ session: URLSession,
            task: URLSessionTask,
            willPerformHTTPRedirection response: HTTPURLResponse,
            newRequest request: URLRequest,
            completionHandler: @escaping (URLRequest?) -> Void
        ) {
            completionHandler(nil)
        }
    }

    private static func syncHTTPRequestNoRedirect(_ request: URLRequest, timeout: TimeInterval) -> HTTPURLResponse? {
        var result: HTTPURLResponse?
        let semaphore = DispatchSemaphore(value: 0)
        let config = URLSessionConfiguration.ephemeral
        config.httpShouldSetCookies = false
        config.httpCookieAcceptPolicy = .never
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.timeoutIntervalForRequest = timeout
        let delegate = NoRedirectDelegate()
        let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        let task = session.dataTask(with: request) { _, response, _ in
            result = response as? HTTPURLResponse
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + timeout + 0.5)
        return result
    }

    // MARK: - Open redirect

    private static let redirectTestTarget = "roamswitch-redirect-probe.invalid"
    private static let redirectTestTargetURL = "http://roamswitch-redirect-probe.invalid/"

    /// Common redirect-parameter names, tried one at a time against the root path.
    /// Unlike CORS/traversal, this doesn't need every dev server to use one of these —
    /// a server using a different parameter name is simply not flagged (biasing this
    /// check toward false negatives, never false positives).
    private static let redirectParamNames = ["redirect", "url", "next", "return_to", "returnUrl", "redirect_uri", "continue", "dest"]

    /// Tries each candidate parameter name in turn and stops at the first one that gets
    /// a `3xx` response whose `Location` header points at our (unregistered,
    /// unreachable) test domain — proof the server redirects to an attacker-controlled
    /// URL without validating it, rather than just accepting the parameter unused.
    static func probeOpenRedirect(port: Int, timeout: TimeInterval = 2.0) -> Bool? {
        var sawAnyResponse = false
        for param in redirectParamNames {
            var components = URLComponents(string: "http://127.0.0.1:\(port)/")!
            components.queryItems = [URLQueryItem(name: param, value: redirectTestTargetURL)]
            guard let url = components.url else { continue }
            var request = URLRequest(url: url, timeoutInterval: timeout)
            request.httpMethod = "GET"
            guard let response = syncHTTPRequestNoRedirect(request, timeout: timeout) else { continue }
            sawAnyResponse = true
            let location = response.value(forHTTPHeaderField: "Location") ?? ""
            if (300...399).contains(response.statusCode), location.contains(redirectTestTarget) {
                return true
            }
        }
        return sawAnyResponse ? false : nil
    }

    // MARK: - Orchestration

    /// Which `ServiceSignatures` ids Phase 2 has an actual probe implemented for.
    /// Signatures without a matching prober here are Phase-1-only (flagged passively).
    private static let probeableSignatureIDs: Set<String> = [
        "redis-default-noauth", "memcached-noauth", "mongod-default-noauth",
    ]

    /// Whether `runScan` would attempt anything at all for this port — i.e. it either
    /// matches a Phase 2 probeable signature or is a Phase 3 dev-server candidate. Lets
    /// UI code decide whether to offer the "Run Active Verification" action at all,
    /// without duplicating the matching logic.
    static func hasApplicableTargets(for port: ListeningPortInfo) -> Bool {
        let hasSignatureProbe = ServiceSignatures.match(processName: port.processName, executablePath: port.executablePath)
            .contains { probeableSignatureIDs.contains($0.id) }
        return hasSignatureProbe || PortSecurityAuditor.isKnownDevServerPort(port.port)
    }

    /// Runs Phase 2 (known-service reachability) and Phase 3 (generic CORS/traversal
    /// checks, only for ports flagged as dev servers) against the given ports, returning
    /// only confirmed findings. Sequential — no concurrency, matching the Linux
    /// implementation's safety invariants.
    static func runScan(ports: [ListeningPortInfo]) -> [Finding] {
        var findings: [Finding] = []

        for port in ports {
            let signatures = ServiceSignatures.match(processName: port.processName, executablePath: port.executablePath)
            for signature in signatures where probeableSignatureIDs.contains(signature.id) {
                let confirmed: Bool?
                switch signature.id {
                case "redis-default-noauth": confirmed = probeRedisNoAuth(port: port.port)
                case "memcached-noauth": confirmed = probeMemcachedNoAuth(port: port.port)
                case "mongod-default-noauth": confirmed = probeMongoDBNoAuth(port: port.port)
                default: confirmed = nil
                }
                if confirmed == true {
                    findings.append(Finding(
                        port: port.port,
                        processName: port.processName,
                        title: signature.title,
                        description: signature.description,
                        recommendation: signature.recommendation
                    ))
                    if let versionString = probeVersion(signatureID: signature.id, port: port.port, timeout: 2.0),
                       let version = parseSemver(versionString) {
                        for cve in findKnownCVEs(signatureID: signature.id, version: version) {
                            findings.append(Finding(
                                port: port.port,
                                processName: port.processName,
                                title: resolveLang(cve.title),
                                description: resolveLang(cve.description),
                                recommendation: resolveLang(cve.recommendation)
                            ))
                        }
                    }
                }
            }
        }

        for port in ports where PortSecurityAuditor.isKnownDevServerPort(port.port) {
            if probeCorsMisconfiguration(port: port.port) == true {
                findings.append(Finding(
                    port: port.port,
                    processName: port.processName,
                    title: loc("CORS 設定ミス（認証情報付きクロスオリジン許可）"),
                    description: loc("任意のOriginヘッダを送信したところ、そのOriginがAccess-Control-Allow-Originに反映（または*が返却）され、かつAccess-Control-Allow-Credentials: trueが同時に返されました。この組み合わせは、悪意あるWebサイトが被害者のブラウザ経由でこのサーバーへ認証済みリクエストを送信し、レスポンスを読み取れることを意味します。"),
                    recommendation: loc("Access-Control-Allow-Origin を信頼できる特定のオリジンのみに限定し、Access-Control-Allow-Credentials は本当に必要な場合のみ有効にしてください。")
                ))
            }
            if probePathTraversal(port: port.port) == true {
                findings.append(Finding(
                    port: port.port,
                    processName: port.processName,
                    title: loc("パストラバーサル（ディレクトリトラバーサル）"),
                    description: loc("静的ファイル配信のパスに ../ を含むリクエストを送信したところ、Webルート外の /etc/passwd の内容が取得できました。ファイルパスの正規化・検証が不十分なため、Webルート外の任意のファイルを読み取られる危険があります。"),
                    recommendation: loc("静的ファイル配信ライブラリを最新版に更新し、配信元パスを正規化したうえでWebルート内に限定してください。可能であればサンドボックスでファイルシステムへのアクセス範囲自体を制限することも推奨します。")
                ))
            }
            if probeOpenRedirect(port: port.port) == true {
                findings.append(Finding(
                    port: port.port,
                    processName: port.processName,
                    title: loc("オープンリダイレクト（未検証の外部リダイレクト）"),
                    description: loc("既知のリダイレクトパラメータ（redirect/url/next 等）に外部ドメインを指定したところ、検証なしにそのドメインへリダイレクトされました。フィッシング詐欺で正規サイトのURLを装いつつ悪意あるサイトへ誘導する手口に悪用される危険があります。"),
                    recommendation: loc("リダイレクト先URLを許可リスト（同一オリジンまたは信頼済みドメインのみ）で検証してください。")
                ))
            }
        }

        return findings
    }
}
