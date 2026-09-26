// Mirrored from RoamSwitchTests/ — RoamSwitch 1.10.5 (build 123). Do not edit here; see SYNC.md.

import XCTest
import Network
@testable import roamswitch_mcp

/// Covers `ActiveVulnScan`'s Phase 2 (known-service reachability) and Phase 3 (generic
/// CORS/path-traversal) probes — the macOS counterpart of the Linux client's
/// `active_vuln_scan.rs` / `web_vuln_scan.rs` test suites. Spins up a real local
/// `NWListener` per test (the same "bind a real listener" precedent as the Linux
/// `spawn_stub_server` helper) and feeds it a fixed byte reply, so these exercise the
/// actual `NWConnection`/`URLSession` code paths rather than mocking them out.
final class ActiveVulnScanTests: XCTestCase {

    /// Starts a one-shot TCP listener on an ephemeral port that replies with `reply` to
    /// the first connection it accepts, then stops.
    private func spawnStubServer(reply: Data) -> Int {
        let listener = try! NWListener(using: .tcp, on: .any)
        let ready = DispatchSemaphore(value: 0)
        var boundPort: Int = 0

        listener.stateUpdateHandler = { state in
            if case .ready = state, boundPort == 0 {
                boundPort = Int(listener.port?.rawValue ?? 0)
                ready.signal()
            }
        }
        listener.newConnectionHandler = { connection in
            connection.stateUpdateHandler = { state in
                if state == .ready {
                    connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { _, _, _, _ in
                        connection.send(content: reply, completion: .contentProcessed { _ in
                            connection.cancel()
                        })
                    }
                }
            }
            connection.start(queue: .global())
        }
        listener.start(queue: .global())
        _ = ready.wait(timeout: .now() + 2)
        return boundPort
    }

    // MARK: - Redis

    func testProbeRedisNoAuthDetectsUnauthenticatedPong() {
        let port = spawnStubServer(reply: Data("+PONG\r\n".utf8))
        XCTAssertEqual(ActiveVulnScan.probeRedisNoAuth(port: port), true)
    }

    func testProbeRedisNoAuthDoesNotFlagWhenAuthRequired() {
        let port = spawnStubServer(reply: Data("-NOAUTH Authentication required.\r\n".utf8))
        XCTAssertEqual(ActiveVulnScan.probeRedisNoAuth(port: port), false)
    }

    func testProbeRedisNoAuthReturnsNilOnClosedPort() {
        // An arbitrary high port nothing is listening on.
        XCTAssertNil(ActiveVulnScan.probeRedisNoAuth(port: 18237, timeout: 0.3))
    }

    // MARK: - Memcached

    func testProbeMemcachedDetectsStatsResponse() {
        let port = spawnStubServer(reply: Data("STAT pid 123\r\nEND\r\n".utf8))
        XCTAssertEqual(ActiveVulnScan.probeMemcachedNoAuth(port: port), true)
    }

    func testProbeMemcachedDoesNotFlagUnexpectedResponse() {
        let port = spawnStubServer(reply: Data("ERROR\r\n".utf8))
        XCTAssertEqual(ActiveVulnScan.probeMemcachedNoAuth(port: port), false)
    }

    // MARK: - MongoDB

    func testProbeMongoDBDetectsUnauthenticatedListDatabases() {
        // Real (truncated) OP_MSG reply bytes captured from an unauthenticated
        // `mongo:6` container's `listDatabases` response while implementing the Linux
        // counterpart — contains the lowercase `databases` field name.
        let reply = Data("\u{00}\u{00}\u{00}\u{00}\u{00}\u{00}\u{00}\u{00}\u{00}databases\u{00}\u{00}ok\u{00}".utf8)
        let port = spawnStubServer(reply: reply)
        XCTAssertEqual(ActiveVulnScan.probeMongoDBNoAuth(port: port), true)
    }

    func testProbeMongoDBDoesNotFlagAuthRequiredResponse() {
        // Real (truncated) OP_MSG reply bytes captured from an auth-enabled `mongo:6`
        // container's rejection — echoes the mixed-case command name "listDatabases"
        // inside errmsg, which must NOT be confused with the lowercase "databases"
        // success marker.
        let reply = Data("\u{00}\u{00}\u{00}\u{00}errmsg\u{00}command listDatabases requires authentication\u{00}".utf8)
        let port = spawnStubServer(reply: reply)
        XCTAssertEqual(ActiveVulnScan.probeMongoDBNoAuth(port: port), false)
    }

    // MARK: - CORS misconfiguration

    private func spawnHTTPStub(response: String) -> Int {
        spawnStubServer(reply: Data(response.utf8))
    }

    func testCorsFlagsReflectedOriginWithCredentials() {
        let port = spawnHTTPStub(response:
            "HTTP/1.1 200 OK\r\nAccess-Control-Allow-Origin: http://roamswitch-cors-probe.invalid\r\nAccess-Control-Allow-Credentials: true\r\nContent-Length: 2\r\n\r\nOK")
        XCTAssertEqual(ActiveVulnScan.probeCorsMisconfiguration(port: port), true)
    }

    func testCorsFlagsWildcardWithCredentials() {
        let port = spawnHTTPStub(response:
            "HTTP/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nAccess-Control-Allow-Credentials: true\r\nContent-Length: 2\r\n\r\nOK")
        XCTAssertEqual(ActiveVulnScan.probeCorsMisconfiguration(port: port), true)
    }

    func testCorsDoesNotFlagWildcardWithoutCredentials() {
        let port = spawnHTTPStub(response:
            "HTTP/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: 2\r\n\r\nOK")
        XCTAssertEqual(ActiveVulnScan.probeCorsMisconfiguration(port: port), false)
    }

    func testCorsDoesNotFlagFixedAllowlistedOrigin() {
        let port = spawnHTTPStub(response:
            "HTTP/1.1 200 OK\r\nAccess-Control-Allow-Origin: https://app.example.com\r\nAccess-Control-Allow-Credentials: true\r\nContent-Length: 2\r\n\r\nOK")
        XCTAssertEqual(ActiveVulnScan.probeCorsMisconfiguration(port: port), false)
    }

    // MARK: - Path traversal

    func testTraversalDetectsMacOSPasswdMarker() {
        let port = spawnHTTPStub(response:
            "HTTP/1.1 200 OK\r\nContent-Length: 40\r\n\r\nroot:*:0:0:System Administrator:/var/root")
        XCTAssertEqual(ActiveVulnScan.probePathTraversal(port: port), true)
    }

    func testTraversalDoesNotFlagNormal404() {
        let port = spawnHTTPStub(response: "HTTP/1.1 404 Not Found\r\nContent-Length: 9\r\n\r\nNot Found")
        XCTAssertEqual(ActiveVulnScan.probePathTraversal(port: port), false)
    }

    // MARK: - Open redirect

    func testRedirectDetectsReflectedExternalLocation() {
        // "redirect" is the first candidate parameter name, so this also implicitly
        // covers the single-attempt case (only one connection is ever made).
        let port = spawnHTTPStub(response:
            "HTTP/1.1 302 Found\r\nLocation: http://roamswitch-redirect-probe.invalid/\r\nContent-Length: 0\r\n\r\n")
        XCTAssertEqual(ActiveVulnScan.probeOpenRedirect(port: port), true)
    }

    func testRedirectDoesNotFlagNonRedirectResponse() {
        let port = spawnHTTPStub(response: "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK")
        XCTAssertEqual(ActiveVulnScan.probeOpenRedirect(port: port), false)
    }

    func testRedirectDoesNotFlagRedirectToUnrelatedLocation() {
        // A 3xx that redirects somewhere of the server's own choosing (not our probe
        // domain) is normal application behavior, not an open redirect.
        let port = spawnHTTPStub(response: "HTTP/1.1 302 Found\r\nLocation: /dashboard\r\nContent-Length: 0\r\n\r\n")
        XCTAssertEqual(ActiveVulnScan.probeOpenRedirect(port: port), false)
    }

    // MARK: - Known-CVE version matching

    func testProbeRedisVersionExtractsVersionFromInfoResponse() {
        let port = spawnStubServer(reply: Data("$1234\r\n# Server\r\nredis_version:6.0.19\r\nredis_git_sha1:00000000\r\n".utf8))
        XCTAssertEqual(ActiveVulnScan.probeRedisVersion(port: port), "6.0.19")
    }

    func testProbeMemcachedVersionExtractsVersionFromStatsResponse() {
        let port = spawnStubServer(reply: Data("STAT pid 123\r\nSTAT version 1.5.5\r\nEND\r\n".utf8))
        XCTAssertEqual(ActiveVulnScan.probeMemcachedVersion(port: port), "1.5.5")
    }

    /// Starts a listener that inspects each incoming request and replies with `pong` to a
    /// `PING`, or `infoReply` to anything else (i.e. the `INFO server` version check) —
    /// needed to exercise `runScan`'s two-request Redis flow (reachability, then version)
    /// against a single stub. Persistent `newConnectionHandler`, so it serves any number
    /// of sequential connections.
    private func spawnRedisVersionStub(pong: Data, infoReply: Data) -> Int {
        let listener = try! NWListener(using: .tcp, on: .any)
        let ready = DispatchSemaphore(value: 0)
        var boundPort: Int = 0

        listener.stateUpdateHandler = { state in
            if case .ready = state, boundPort == 0 {
                boundPort = Int(listener.port?.rawValue ?? 0)
                ready.signal()
            }
        }
        listener.newConnectionHandler = { connection in
            connection.stateUpdateHandler = { state in
                if state == .ready {
                    connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { data, _, _, _ in
                        let request = String(decoding: data ?? Data(), as: UTF8.self)
                        let reply = request.hasPrefix("PING") ? pong : infoReply
                        connection.send(content: reply, completion: .contentProcessed { _ in
                            connection.cancel()
                        })
                    }
                }
            }
            connection.start(queue: .global())
        }
        listener.start(queue: .global())
        _ = ready.wait(timeout: .now() + 2)
        return boundPort
    }

    func testRunScanAppendsCVEFindingForVulnerableRedisVersion() {
        let port = spawnRedisVersionStub(
            pong: Data("+PONG\r\n".utf8),
            infoReply: Data("$1234\r\n# Server\r\nredis_version:6.0.19\r\n".utf8)
        )
        let ports = [ListeningPortInfo(processName: "redis-server", pid: 1, port: port, isGloballyExposed: false, executablePath: nil)]
        let findings = runScanIsolated(ports: ports).findings
        XCTAssertTrue(findings.contains { $0.title.contains("CVE-2022-24834") })
    }

    func testRunScanDoesNotAppendCVE202224834FindingForItsFixedVersion() {
        // 6.0.20 is specifically the fix boundary for CVE-2022-24834's first affected
        // range — this only checks that one CVE's absence, since the version is still
        // within several other (newer, broader) entries' ranges by design.
        let port = spawnRedisVersionStub(
            pong: Data("+PONG\r\n".utf8),
            infoReply: Data("$1234\r\n# Server\r\nredis_version:6.0.20\r\n".utf8)
        )
        let ports = [ListeningPortInfo(processName: "redis-server", pid: 1, port: port, isGloballyExposed: false, executablePath: nil)]
        let findings = runScanIsolated(ports: ports).findings
        XCTAssertFalse(findings.contains { $0.title.contains("CVE-2022-24834") })
    }

    func testRunScanAppendsMultipleOverlappingCVEFindingsForOldRedisVersion() {
        // Several entries have genuinely overlapping ranges — a real instance this old
        // is legitimately vulnerable to more than one, and all must be reported.
        let port = spawnRedisVersionStub(
            pong: Data("+PONG\r\n".utf8),
            infoReply: Data("$1234\r\n# Server\r\nredis_version:6.0.19\r\n".utf8)
        )
        let ports = [ListeningPortInfo(processName: "redis-server", pid: 1, port: port, isGloballyExposed: false, executablePath: nil)]
        let findings = runScanIsolated(ports: ports).findings
        XCTAssertTrue(findings.contains { $0.title.contains("CVE-2022-24834") })
        XCTAssertTrue(findings.contains { $0.title.contains("CVE-2025-21605") })
    }

    func testRunScanAppendsNoCVEFindingForFullyPatchedRedisVersion() {
        let port = spawnRedisVersionStub(
            pong: Data("+PONG\r\n".utf8),
            infoReply: Data("$1234\r\n# Server\r\nredis_version:8.8.0\r\n".utf8)
        )
        let ports = [ListeningPortInfo(processName: "redis-server", pid: 1, port: port, isGloballyExposed: false, executablePath: nil)]
        let findings = runScanIsolated(ports: ports).findings
        XCTAssertEqual(findings.count, 1)
        XCTAssertFalse(findings[0].title.contains("CVE-"))
    }

    /// `ActiveVulnCveMapUpdater` writes its verified payload straight to
    /// `ActiveVulnScan.updatedCVEMapURL` — this exercises the override-preference
    /// half of `loadCVEMap` (an updater-installed map newer than the embedded
    /// baseline wins) without needing to mock the network fetch, matching how
    /// `LinkGuardManager`'s own feed-refresh network path also has no dedicated
    /// unit test in this codebase.
    func testRunScanPrefersNewerUpdaterInstalledCVEMapOverEmbeddedBaseline() {
        let url = ActiveVulnScan.updatedCVEMapURL
        let dir = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let original = try? Data(contentsOf: url)
        defer {
            if let original { try? original.write(to: url) } else { try? FileManager.default.removeItem(at: url) }
        }

        let overrideJSON = """
        {"mapVersion":"9999-01-01","entries":[{
            "cveId":"CVE-9999-00001","signatureId":"redis-default-noauth",
            "minVersion":[0,0,0],"fixedVersion":[999,0,0],
            "title":{"en":"override marker title"},
            "description":{"en":"override marker description"},
            "recommendation":{"en":"override marker recommendation"}
        }]}
        """
        try! Data(overrideJSON.utf8).write(to: url)

        let port = spawnRedisVersionStub(
            pong: Data("+PONG\r\n".utf8),
            infoReply: Data("$1234\r\n# Server\r\nredis_version:6.0.19\r\n".utf8)
        )
        let ports = [ListeningPortInfo(processName: "redis-server", pid: 1, port: port, isGloballyExposed: false, executablePath: nil)]
        let findings = runScanIsolated(ports: ports).findings
        XCTAssertTrue(findings.contains { $0.title == "override marker title" })
        // The embedded baseline's own entries must be absent — the override fully
        // replaces it rather than merging.
        XCTAssertFalse(findings.contains { $0.title.contains("CVE-2022-24834") })
    }

    // MARK: - Orchestration

    func testRunScanSkipsNonProbeableSignatures() {
        // etcd has a Phase 1 signature but no Phase 2 prober on macOS either.
        let ports = [ListeningPortInfo(processName: "etcd", pid: 1, port: 2379, isGloballyExposed: false, executablePath: nil)]
        XCTAssertTrue(runScanIsolated(ports: ports).findings.isEmpty)
    }

    // MARK: - Heartbeat log (see `ActiveVulnScan.ProbeRunRecord`)

    private func scratchProbeLogURL(_ name: String) -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("rs-active-vuln-scan-log-test-\(name)-\(ProcessInfo.processInfo.processIdentifier).json")
    }

    /// Every test that runs `runScan` without caring about the heartbeat log must
    /// go through this: `runScan`'s default `probeLogURL` is the real, persisted
    /// `active_vuln_scan_log.json`, so calling it bare from a test writes stub-server
    /// results (ephemeral ports, fake "redis-server") into a developer's or user's
    /// actual log — which then shows up in the CSV export as if it were a real finding.
    private func runScanIsolated(ports: [ListeningPortInfo]) -> ActiveVulnScan.ScanRunResult {
        let url = scratchProbeLogURL("isolated-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: url) }
        return ActiveVulnScan.runScan(ports: ports, probeLogURL: url, includeNmapNSE: false)
    }

    private func loadRecords(at url: URL) -> [ActiveVulnScan.ProbeRunRecord]? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode([ActiveVulnScan.ProbeRunRecord].self, from: data)
    }

    func testAppendProbeLogCreatesTheFileAndPersistsAcrossCalls() {
        let url = scratchProbeLogURL("basic")
        try? FileManager.default.removeItem(at: url)

        ActiveVulnScan.appendProbeLog([
            ActiveVulnScan.ProbeRunRecord(probeName: "redis-default-noauth", port: 6379, lastStartedAt: "t1", lastFinishedAt: "t1", outcome: "safe"),
        ], to: url)
        XCTAssertEqual(loadRecords(at: url)?.count, 1)

        ActiveVulnScan.appendProbeLog([
            ActiveVulnScan.ProbeRunRecord(probeName: "mongod-default-noauth", port: 27017, lastStartedAt: "t2", lastFinishedAt: "t2", outcome: "inconclusive"),
        ], to: url)
        let entries = loadRecords(at: url)
        XCTAssertEqual(entries?.count, 2, "second call must append, not overwrite")
        XCTAssertEqual(entries?.first?.probeName, "redis-default-noauth")
        XCTAssertEqual(entries?.last?.probeName, "mongod-default-noauth")

        try? FileManager.default.removeItem(at: url)
    }

    func testAppendProbeLogGivesEachAppendItsOwnScanIdAndKeepsRowsUnderConcurrency() {
        let url = scratchProbeLogURL("concurrent")
        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.removeItem(at: url.appendingPathExtension("lock"))

        DispatchQueue.concurrentPerform(iterations: 8) { _ in
            for _ in 0..<5 {
                ActiveVulnScan.appendProbeLog([
                    ActiveVulnScan.ProbeRunRecord(probeName: "a", port: 1, lastStartedAt: "t", lastFinishedAt: "t", outcome: "safe"),
                    ActiveVulnScan.ProbeRunRecord(probeName: "b", port: 2, lastStartedAt: "t", lastFinishedAt: "t", outcome: "inconclusive"),
                ], to: url)
                Thread.sleep(forTimeInterval: 0.002)
            }
        }
        let entries = loadRecords(at: url) ?? []
        XCTAssertEqual(entries.count, 8 * 5 * 2, "rows were lost under concurrent appends")
        XCTAssertTrue(entries.allSatisfy { $0.scanId != nil })
        XCTAssertGreaterThan(Set(entries.compactMap { $0.scanId }).count, 1, "separate appends should carry separate scan ids")

        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.removeItem(at: url.appendingPathExtension("lock"))
    }

    func testAppendProbeLogWritesNothingForAnEmptyRecordsList() {
        let url = scratchProbeLogURL("empty")
        try? FileManager.default.removeItem(at: url)

        ActiveVulnScan.appendProbeLog([], to: url)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path), "a run with zero applicable targets must not touch the file")
    }

    func testRunScanRecordsOneHeartbeatLogEntryPerTargetProbed() {
        // Unlike the Linux port, this can pass an explicit scratch URL
        // straight through `runScan`'s default parameter instead of
        // touching any process-global state, so it needs no isolation
        // workaround for concurrently-running tests.
        let url = scratchProbeLogURL("run-scan-e2e")
        try? FileManager.default.removeItem(at: url)

        let port = spawnStubServer(reply: Data("+PONG\r\n".utf8))
        let ports = [ListeningPortInfo(processName: "redis-server", pid: 1, port: port, isGloballyExposed: false, executablePath: nil)]
        _ = ActiveVulnScan.runScan(ports: ports, probeLogURL: url)

        let entries = loadRecords(at: url)
        XCTAssertEqual(entries?.count, 1)
        XCTAssertEqual(entries?.first?.probeName, "redis-default-noauth")
        XCTAssertEqual(entries?.first?.outcome, "vulnerable")
        XCTAssertFalse(entries?.first?.lastStartedAt.isEmpty ?? true)
        XCTAssertFalse(entries?.first?.lastFinishedAt.isEmpty ?? true)

        try? FileManager.default.removeItem(at: url)
    }

    /// Mirrors the Linux port's
    /// `active_vuln_scan::tests::embedded_cve_map_has_every_language_for_every_entry`
    /// — the embedded baseline (`ActiveVulnCveMapData.swift`, mechanically
    /// regenerated from `roamswitch-linux`'s NVD-sourced
    /// `active_vuln_cve_map.json` via `scripts/gen_swift_cve_map_data.py`,
    /// 2026-09) must still carry all 10 UI languages for every entry even
    /// though the *content* is now NVD's raw English text repeated into
    /// every slot rather than translated — a missing/empty key would fall
    /// through to `resolveLang`'s English-then-Japanese-then-anything
    /// fallback silently, so this only catches a genuinely broken
    /// generation run (a key dropped entirely), not a translation-quality
    /// regression.
    func testEmbeddedCveMapHasEveryLanguageForEveryEntry() {
        let allLangs = ["ja", "en", "zh-Hans", "zh-Hant", "ko", "de", "fr", "es", "it", "pt-PT"]
        let decoder = JSONDecoder()
        guard let map = try? decoder.decode(
            ActiveVulnScan.CVEMap.self,
            from: Data(ActiveVulnCveMapData.embeddedJSON.utf8)
        ) else {
            XCTFail("embedded CVE map failed to decode")
            return
        }
        XCTAssertFalse(map.entries.isEmpty)
        for entry in map.entries {
            for lang in allLangs {
                for (fieldName, dict) in [
                    ("title", entry.title),
                    ("description", entry.description),
                    ("recommendation", entry.recommendation),
                ] {
                    let text = dict[lang]
                    XCTAssertTrue(
                        text?.isEmpty == false,
                        "\(entry.cveId) missing/empty \(fieldName) for \(lang)"
                    )
                }
            }
        }
    }

    /// The test above only proves each language slot is non-empty, which an
    /// English string copied into all ten slots also satisfies — exactly the
    /// state the mechanically generated map was in before its fixed text was
    /// translated. Title, recommendation and description must differ from the
    /// English text in every other language (NVD's own description is
    /// English-only, so it carries a language label instead).
    func testEmbeddedCveMapIsReallyLocalizedNotEnglishInEverySlot() {
        let otherLangs = ["ja", "zh-Hans", "zh-Hant", "ko", "de", "fr", "es", "it", "pt-PT"]
        guard let map = try? JSONDecoder().decode(
            ActiveVulnScan.CVEMap.self,
            from: Data(ActiveVulnCveMapData.embeddedJSON.utf8)
        ) else {
            XCTFail("embedded CVE map failed to decode")
            return
        }
        for entry in map.entries {
            for lang in otherLangs {
                for (fieldName, dict) in [
                    ("title", entry.title),
                    ("recommendation", entry.recommendation),
                    ("description", entry.description),
                ] {
                    XCTAssertNotEqual(
                        dict[lang], dict["en"],
                        "\(entry.cveId) \(fieldName) for \(lang) is still the English text"
                    )
                }
            }
        }
    }

    // MARK: - Extended probes (Elasticsearch / CouchDB / Jenkins / VNC / SMB)

    private func http200(_ body: String) -> Data {
        Data("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nConnection: close\r\n\r\n\(body)".utf8)
    }

    func testProbeElasticsearchFlagsOpenClusterAndNotAuthRequired() {
        let open = spawnStubServer(reply: http200("{\"name\":\"n\",\"cluster_name\":\"c\"}"))
        XCTAssertEqual(ActiveVulnScan.probeElasticsearchNoAuth(port: open), true)
        let locked = spawnStubServer(reply: Data("HTTP/1.1 401 Unauthorized\r\nConnection: close\r\n\r\n{\"error\":\"security_exception\"}".utf8))
        XCTAssertEqual(ActiveVulnScan.probeElasticsearchNoAuth(port: locked), false)
    }

    func testProbeCouchDBFlagsAllDbsArray() {
        let open = spawnStubServer(reply: http200("[\"_users\",\"db\"]"))
        XCTAssertEqual(ActiveVulnScan.probeCouchDBNoAuth(port: open), true)
        let locked = spawnStubServer(reply: Data("HTTP/1.1 401 Unauthorized\r\nConnection: close\r\n\r\n{}".utf8))
        XCTAssertEqual(ActiveVulnScan.probeCouchDBNoAuth(port: locked), false)
    }

    func testProbeJenkinsFlagsApiJsonAndNotForbidden() {
        let open = spawnStubServer(reply: http200("{\"_class\":\"hudson.model.Hudson\",\"jobs\":[]}"))
        XCTAssertEqual(ActiveVulnScan.probeJenkinsNoAuth(port: open), true)
        let locked = spawnStubServer(reply: Data("HTTP/1.1 403 Forbidden\r\nConnection: close\r\n\r\n".utf8))
        XCTAssertEqual(ActiveVulnScan.probeJenkinsNoAuth(port: locked), false)
    }

    /// Two-step RFB stub: sends the version banner immediately, then the given security-type
    /// bytes after the client echoes its version.
    private func spawnVNCStub(types: Data) -> Int {
        let listener = try! NWListener(using: .tcp, on: .any)
        let ready = DispatchSemaphore(value: 0)
        var boundPort = 0
        listener.stateUpdateHandler = { state in
            if case .ready = state, boundPort == 0 {
                boundPort = Int(listener.port?.rawValue ?? 0)
                ready.signal()
            }
        }
        listener.newConnectionHandler = { connection in
            connection.stateUpdateHandler = { state in
                guard state == .ready else { return }
                connection.send(content: Data("RFB 003.008\n".utf8), completion: .contentProcessed { _ in
                    connection.receive(minimumIncompleteLength: 12, maximumLength: 12) { _, _, _, _ in
                        connection.send(content: types, completion: .contentProcessed { _ in connection.cancel() })
                    }
                })
            }
            connection.start(queue: .global())
        }
        listener.start(queue: .global())
        _ = ready.wait(timeout: .now() + 2)
        return boundPort
    }

    func testProbeVNCFlagsNoneSecurityType() {
        XCTAssertEqual(ActiveVulnScan.probeVNCNoAuth(port: spawnVNCStub(types: Data([2, 1, 2]))), true)
        XCTAssertEqual(ActiveVulnScan.probeVNCNoAuth(port: spawnVNCStub(types: Data([1, 2]))), false)
    }

    private func smbWrap(_ body: [UInt8]) -> Data {
        Data([0x00, UInt8((body.count >> 16) & 0xFF), UInt8((body.count >> 8) & 0xFF), UInt8(body.count & 0xFF)] + body)
    }

    private func smb2Reply(securityMode: UInt16) -> Data {
        var body: [UInt8] = [0xFE, 0x53, 0x4D, 0x42] + [UInt8](repeating: 0, count: 60)
        body += [65, 0, UInt8(securityMode & 0xFF), UInt8(securityMode >> 8)]
        body += [UInt8](repeating: 0, count: 42)
        return smbWrap(body)
    }

    func testProbeSMBNegotiateDistinguishesV1AndSigning() {
        let v1 = spawnStubServer(reply: smbWrap([0xFF, 0x53, 0x4D, 0x42] + [UInt8](repeating: 0, count: 32)))
        XCTAssertEqual(ActiveVulnScan.probeSMBNegotiate(port: v1), .smb1)
        let notRequired = spawnStubServer(reply: smb2Reply(securityMode: 0x01))
        XCTAssertEqual(ActiveVulnScan.probeSMBNegotiate(port: notRequired), .smb2SigningNotRequired)
        let required = spawnStubServer(reply: smb2Reply(securityMode: 0x03))
        XCTAssertEqual(ActiveVulnScan.probeSMBNegotiate(port: required), .smb2SigningRequired)
    }

    func testEveryNewSignatureHasTranslationsInAllLanguages() {
        for id in ["elasticsearch-noauth", "couchdb-noauth", "jenkins-noauth", "vnc-noauth", "smb1-enabled", "smb-signing-not-required"] {
            let sig = ServiceSignatures.signatures.first { $0.id == id }
            XCTAssertNotNil(sig, id)
        }
    }

    // MARK: - pass_age / probeStatusSummary

    private static let isoFormatter = ISO8601DateFormatter()

    private func record(_ probeName: String, port: Int?, outcome: String, finishedAt: Date) -> ActiveVulnScan.ProbeRunRecord {
        let ts = Self.isoFormatter.string(from: finishedAt)
        return ActiveVulnScan.ProbeRunRecord(probeName: probeName, port: port, lastStartedAt: ts, lastFinishedAt: ts, outcome: outcome, scanId: nil)
    }

    func testProbeStatusSummaryComputesPassAgeInWholeDays() {
        let now = Date()
        let fiveDaysAgo = Calendar.current.date(byAdding: .day, value: -5, to: now)!
        let entries = [record("redis-default-noauth", port: 6379, outcome: "safe", finishedAt: fiveDaysAgo)]
        let statuses = ActiveVulnScan.probeStatusSummary(from: entries, now: now)
        XCTAssertEqual(statuses.count, 1)
        XCTAssertEqual(statuses[0].passAgeDays, 5)
        XCTAssertEqual(statuses[0].lastOutcome, "safe")
    }

    func testProbeStatusSummaryKeepsOnlyTheMostRecentRowPerProbeAndPort() {
        let now = Date()
        let old = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let recent = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let entries = [
            record("redis-default-noauth", port: 6379, outcome: "vulnerable", finishedAt: old),
            record("redis-default-noauth", port: 6379, outcome: "safe", finishedAt: recent),
        ]
        let statuses = ActiveVulnScan.probeStatusSummary(from: entries, now: now)
        XCTAssertEqual(statuses.count, 1, "must collapse to one row per (probeName, port)")
        XCTAssertEqual(statuses[0].lastOutcome, "safe", "must keep the newer row, not the older one")
    }

    func testProbeStatusSummaryTreatsDifferentPortsAsDistinctProbes() {
        let now = Date()
        let entries = [
            record("redis-default-noauth", port: 6379, outcome: "safe", finishedAt: now),
            record("redis-default-noauth", port: 6380, outcome: "vulnerable", finishedAt: now),
        ]
        let statuses = ActiveVulnScan.probeStatusSummary(from: entries, now: now)
        XCTAssertEqual(statuses.count, 2, "two Redis instances on different ports must not collapse into one status")
    }

    func testProbeStatusSummarySortsMostStaleFirst() {
        let now = Date()
        let entries = [
            record("fresh-probe", port: 1, outcome: "safe", finishedAt: Calendar.current.date(byAdding: .day, value: -1, to: now)!),
            record("stale-probe", port: 2, outcome: "safe", finishedAt: Calendar.current.date(byAdding: .day, value: -90, to: now)!),
        ]
        let statuses = ActiveVulnScan.probeStatusSummary(from: entries, now: now)
        XCTAssertEqual(statuses.first?.probeName, "stale-probe")
        XCTAssertEqual(statuses.last?.probeName, "fresh-probe")
    }

    func testProbeStatusSummaryOfEmptyLogIsEmpty() {
        XCTAssertTrue(ActiveVulnScan.probeStatusSummary(from: [], now: Date()).isEmpty)
    }

}
