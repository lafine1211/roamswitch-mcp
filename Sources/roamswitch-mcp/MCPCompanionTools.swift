// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.35 (build 214).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import CryptoKit
import Foundation
import Security

/// MCP tools that the Linux edition has and that have a counterpart on this Mac: `get_privilege_escalation_paths`
/// (PathScope), `get_access_log_report` (AccessScope), `get_link_guard_status`, `get_vpn_status` and `verify_fim`.
/// The Linux edition (`roamswitch-mcp`) is the specification: same names, arguments, output fields and cautions. Where
/// this Mac cannot know something (the live VPN tunnel and a pending Link Guard decision live in the app and the
/// root helper, not in this process) the field is `null` or left out and a caveat says so. Everything handed to the
/// LLM is English. Pure payload builders: the handlers in `MCPServer` pass in what they read, so the tests need no
/// real system state.
enum MCPCompanion {
    // MARK: - Shared helpers

    /// `s` without control characters (a space stays), at most `n` characters.
    static func clip(_ s: String, _ n: Int) -> String {
        String(s.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) || $0 == " " }.map(Character.init).prefix(n))
    }

    /// Every string value in `payload` except under the top-level `excludedKeys` (the tool's own fixed notes). What
    /// the prompt-injection scan is given: the data that came from outside, not the tool's own wording.
    static func untrustedStrings(_ payload: [String: Any], excludingTopLevel excluded: Set<String>) -> [String] {
        var out: [String] = []
        func walk(_ v: Any) {
            if let s = v as? String { out.append(s) }
            else if let a = v as? [Any] { a.forEach(walk) }
            else if let d = v as? [String: Any] { d.values.forEach(walk) }
        }
        for (k, v) in payload where !excluded.contains(k) { walk(v) }
        return out
    }

    static func jsonText(_ object: Any) -> String {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]),
              let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }

    /// The answer of a tool: the payload for the client, or a rejected argument.
    enum Answer {
        case invalidParams(String)
        /// `untrusted`: the payload carries text from outside (names, paths, log lines).
        case payload([String: Any], untrusted: Bool)
    }

    // MARK: - Running PathScope / AccessScope

    /// Runs one of the sibling products (PathScope, AccessScope) for the MCP tools, port of `pathscope_run.rs`.
    /// The program is looked for at fixed absolute places only and must carry this developer's signature, so a
    /// replaced copy (the apps are installed by a drag and the user can write them) is not run. Arguments come from
    /// constants and validated values, no shell; the environment is reset; time and output are limited.
    enum ScopeRunner {
        /// `DEVELOPMENT_TEAM` of project.yml (`RoamSwitchIdentifiers.teamID`; a test keeps the two equal).
        static let teamID = "GV76B6G4YU"

        struct Runner {
            var candidates: [String]
            var requireSignature = true
            var timeout: TimeInterval
            var maxOutputBytes: Int

            static let pathScope = Runner(candidates: ["/Applications/PathScope.app/Contents/MacOS/pathscope"],
                                          timeout: 60, maxOutputBytes: 2 * 1024 * 1024)
            static let accessScope = Runner(candidates: ["/Applications/AccessScope.app/Contents/MacOS/accessscope"],
                                            timeout: 120, maxOutputBytes: 4 * 1024 * 1024)
        }

        enum Failure: Error, Equatable {
            case notInstalled
            case notTrusted(String)
            case timeout
            case outputTooLarge
            case couldNotStart(String)
            case exit(Int32, String)
            case killed
            case badOutput(String)

            var reason: String {
                switch self {
                case .notInstalled: return "not_installed"
                case .notTrusted: return "not_trusted"
                case .timeout: return "timeout"
                case .outputTooLarge: return "output_too_large"
                case .couldNotStart: return "could_not_start"
                case .exit(let code, _): return "exit_\(code)"
                case .killed: return "killed"
                case .badOutput: return "bad_output"
                }
            }
        }

        static let signatureRequirement = "anchor apple generic and certificate leaf[subject.OU] = \"\(teamID)\""

        static func isSignedByThisDeveloper(path: String) -> Bool {
            var code: SecStaticCode?
            var requirement: SecRequirement?
            guard SecStaticCodeCreateWithPath(URL(fileURLWithPath: path) as CFURL, [], &code) == errSecSuccess, let code,
                  SecRequirementCreateWithString(signatureRequirement as CFString, [], &requirement) == errSecSuccess,
                  let requirement else { return false }
            return SecStaticCodeCheckValidity(code, SecCSFlags(rawValue: kSecCSStrictValidate), requirement) == errSecSuccess
        }

        static func locate(_ runner: Runner) -> Result<String, Failure> {
            var refused: String?
            for path in runner.candidates where path.hasPrefix("/") {
                var isDir: ObjCBool = false
                guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir) else { continue }
                if isDir.boolValue { refused = refused ?? "\(path) is not a regular file"; continue }
                guard FileManager.default.isExecutableFile(atPath: path) else { refused = refused ?? "\(path) is not executable"; continue }
                if let mode = (try? FileManager.default.attributesOfItem(atPath: path)[.posixPermissions]) as? Int, mode & 0o022 != 0 {
                    refused = refused ?? "\(path) can be written by the group or others"
                    continue
                }
                if runner.requireSignature, !isSignedByThisDeveloper(path: path) {
                    refused = refused ?? "\(path) does not carry the signature of this developer"
                    continue
                }
                return .success(path)
            }
            return .failure(refused.map { .notTrusted($0) } ?? .notInstalled)
        }

        /// Runs the program with `argv` and returns its JSON. Output is read up to the limit and the program is stopped
        /// at the limit or at the timeout. Only `HOME` of the environment is passed on.
        static func run(_ runner: Runner, argv: [String]) -> Result<[String: Any], Failure> {
            let program: String
            switch locate(runner) {
            case .failure(let f): return .failure(f)
            case .success(let p): program = p
            }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: program)
            process.arguments = argv
            var environment = ["PATH": "/usr/bin:/bin:/usr/sbin:/sbin", "LC_ALL": "C"]
            if let home = ProcessInfo.processInfo.environment["HOME"] { environment["HOME"] = home }
            process.environment = environment
            let outPipe = Pipe(), errPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = errPipe
            process.standardInput = FileHandle.nullDevice
            do { try process.run() } catch { return .failure(.couldNotStart(clip(error.localizedDescription, 120))) }

            let pid = process.processIdentifier
            let lock = NSLock()
            var timedOut = false
            let watchdog = DispatchWorkItem {
                lock.lock(); timedOut = true; lock.unlock()
                process.terminate()
                DispatchQueue.global().asyncAfter(deadline: .now() + 3) { if process.isRunning { kill(pid, SIGKILL) } }
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + runner.timeout, execute: watchdog)

            // Only the start of stderr is kept; the rest is read and dropped so the program never blocks on a full pipe.
            var stderrData = Data()
            let stderrDone = DispatchGroup()
            stderrDone.enter()
            DispatchQueue.global().async {
                let reader = errPipe.fileHandleForReading
                while let chunk = try? reader.read(upToCount: 4096), !chunk.isEmpty {
                    if stderrData.count < 4096 { stderrData.append(chunk.prefix(4096 - stderrData.count)) }
                }
                stderrDone.leave()
            }

            var data = Data()
            var tooLarge = false
            let reader = outPipe.fileHandleForReading
            while let chunk = try? reader.read(upToCount: 64 * 1024), !chunk.isEmpty {
                data.append(chunk)
                if data.count > runner.maxOutputBytes { tooLarge = true; process.terminate(); break }
            }
            process.waitUntilExitWithoutRunLoop()
            watchdog.cancel()
            _ = stderrDone.wait(timeout: .now() + 0.5)

            lock.lock(); let didTimeOut = timedOut; lock.unlock()
            if didTimeOut { return .failure(.timeout) }
            if tooLarge { return .failure(.outputTooLarge) }
            if process.terminationReason == .uncaughtSignal { return .failure(.killed) }
            if process.terminationStatus != 0 {
                return .failure(.exit(process.terminationStatus, clip(String(decoding: stderrData, as: UTF8.self), 300)))
            }
            guard let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
                return .failure(.badOutput("the standard output is not a JSON object"))
            }
            return .success(object)
        }

        /// The tool answer for a failed run. `errorKey` carries the program's first words of stderr on an exit code.
        static func failurePayload(_ f: Failure, name: String, installPath: String, errorKey: String) -> [String: Any] {
            let (available, note): (Bool, String)
            switch f {
            case .notInstalled: (available, note) = (false, "\(name) is not installed on this Mac (no \(installPath)), so nothing was analysed.")
            case .notTrusted(let why): (available, note) = (false, "A \(name) program was found but is not run: \(why).")
            case .timeout: (available, note) = (true, "\(name) did not finish in time and was stopped, so no result is available.")
            case .outputTooLarge: (available, note) = (true, "\(name)'s output is larger than the limit, so it was stopped and not read.")
            case .couldNotStart(let e): (available, note) = (true, "\(name) could not be started: \(e)")
            case .exit(2, _): (available, note) = (true, "\(name) reported a usage or input error (exit code 2), so no result is available.")
            case .exit(let c, _): (available, note) = (true, "\(name) ended with exit code \(c), which is not a result.")
            case .killed: (available, note) = (true, "\(name) was ended by a signal, so no result is available.")
            case .badOutput(let why): (available, note) = (true, "\(name)'s output could not be read: \(why).")
            }
            var out: [String: Any] = ["available": available, "analyzed": false, "reason": f.reason, "mcpNote": note]
            if case .exit(_, let stderr) = f, !stderr.isEmpty { out[errorKey] = stderr }
            return out
        }
    }

    // MARK: - get_privilege_escalation_paths (PathScope)

    enum PathScope {
        static let installPath = "/Applications/PathScope.app/Contents/MacOS/pathscope"
        static let maxPathsShown = 20
        static let maxUrgentShown = 20

        struct Caller: Equatable {
            var uid: UInt32
            /// Login name; nil when it cannot be looked up.
            var name: String?
            /// root, or a member of the `admin` group.
            var admin: Bool

            static func current() -> Caller {
                let uid = getuid()
                var admin = uid == 0
                if !admin, let group = getgrnam("admin") {
                    let adminGID = group.pointee.gr_gid
                    var groups = [gid_t](repeating: 0, count: 64)
                    let n = getgroups(Int32(groups.count), &groups)
                    admin = getegid() == adminGID || (n > 0 && groups.prefix(Int(n)).contains(adminGID))
                }
                return Caller(uid: uid, name: ProcessInfo.processInfo.environment["USER"].flatMap { $0.isEmpty ? nil : $0 } ?? NSUserName(), admin: admin)
            }
        }

        /// 1 to 32 of `[A-Za-z0-9._-]`, not starting with `-` or `.`.
        static func validUserName(_ name: String) -> Bool {
            !name.isEmpty && name.utf8.count <= 32 && !name.hasPrefix("-") && !name.hasPrefix(".")
                && name.unicodeScalars.allSatisfy { ($0.isASCII && (CharacterSet.alphanumerics.contains($0) || $0 == "." || $0 == "_" || $0 == "-")) }
        }

        static func argv(user: String) -> [String] { ["--lang=en", "--start=\(user)", "--format=json"] }

        /// `true` when part of the machine was not looked at, so that "no path" does not mean "safe".
        static func isIncomplete(_ report: [String: Any]) -> Bool {
            let uncollected = (report["uncollected_by_kind"] as? [String: Any]).map { !$0.isEmpty } ?? true
            return uncollected || (report["privileged"] as? Bool) != true
        }

        private static func text(_ d: [String: Any], _ key: String, _ n: Int = 300) -> Any {
            (d[key] as? String).map { clip($0, n) } ?? NSNull()
        }

        private static func edgeValue(_ e: [String: Any]) -> [String: Any] {
            let reasons = ((e["reason"] as? [Any]) ?? []).compactMap { ($0 as? String).map { clip($0, 200) } }
            return ["from": text(e, "from"), "to": text(e, "to"), "kind": reasons.first.map { $0 as Any } ?? NSNull(), "reason": reasons]
        }

        private static func counts(_ report: [String: Any], _ key: String) -> [String: Any] {
            var out: [String: Any] = [:]
            for (k, v) in (report[key] as? [String: Any]) ?? [:] { out[clip(k, 80)] = (v as? NSNumber)?.intValue ?? 0 }
            return out
        }

        /// What this tool returns of one report: start, whether it ran with privilege, how many paths, the urgent fixes
        /// (priority critical or high), what was not collected and the notes. Fix commands are not copied.
        static func summarize(_ report: [String: Any]) -> [String: Any] {
            let paths = (report["paths"] as? [[String: Any]]) ?? []
            let shown: [[[String: Any]]] = paths.prefix(maxPathsShown).map { p in
                ((p["edges"] as? [[String: Any]]) ?? []).map(edgeValue)
            }
            let urgentAll = ((report["choke_points"] as? [[String: Any]]) ?? []).filter { c in
                let level = (c["priority"] as? [String: Any])?["level"] as? String
                return level == "critical" || level == "high"
            }
            let urgent: [[String: Any]] = urgentAll.prefix(maxUrgentShown).map { c in
                let priority = c["priority"] as? [String: Any]
                var item: [String: Any] = [
                    "edge": (c["edge"] as? [String: Any]).map(edgeValue) ?? NSNull(),
                    "impact": c["impact"] ?? NSNull(),
                    "priority": ["level": priority?["level"] ?? NSNull(), "score": priority?["score"] ?? NSNull()],
                    "remediationSummary": ((c["remediation"] as? [String: Any])?["summary"] as? String).map { clip($0, 300) } ?? NSNull(),
                ]
                if let attack = c["attack"] as? [String: Any] {
                    item["attack"] = ["techniqueId": text(attack, "technique_id"), "techniqueName": text(attack, "technique_name")]
                } else {
                    item["attack"] = NSNull()
                }
                return item
            }
            let notes = ((report["notes"] as? [Any]) ?? []).compactMap { ($0 as? String).map { clip($0, 800) } }.prefix(20)
            let incomplete = isIncomplete(report)
            var out: [String: Any] = [
                "start": text(report, "start"),
                "goal": text(report, "goal"),
                "os": text(report, "os"),
                "privileged": (report["privileged"] as? Bool).map { $0 as Any } ?? NSNull(),
                "paths": paths.count,
                "pathsShown": shown,
                "urgentTotal": urgentAll.count,
                "urgent": urgent,
                "uncollectedByKind": counts(report, "uncollected_by_kind"),
                "uncollectedFixableWithPrivilege": counts(report, "uncollected_fixable_with_privilege"),
                "notes": Array(notes),
                "complete": !incomplete,
            ]
            if incomplete { out["mcpCaution"] = caution(report, pathCount: paths.count) }
            return out
        }

        private static func caution(_ report: [String: Any], pathCount: Int) -> String {
            let uncollected = ((report["uncollected_by_kind"] as? [String: Any]) ?? [:]).keys.map { clip($0, 60) }.sorted()
            var why: [String] = []
            if (report["privileged"] as? Bool) != true {
                why.append("PathScope ran without root, so what only root can see (for example files and databases that belong to root) was not looked at")
            }
            if !uncollected.isEmpty { why.append("some places could not be collected (\(uncollected.joined(separator: ", ")))") }
            let lead = pathCount == 0 ? "No path was found, but that does NOT mean the account is safe" : "More paths than the ones listed may exist"
            return "\(lead): \(why.joined(separator: "; "))."
        }

        static func answer(arguments: [String: Any], caller: Caller, runner: ScopeRunner.Runner = .pathScope,
                           run: (ScopeRunner.Runner, [String]) -> Result<[String: Any], ScopeRunner.Failure> = ScopeRunner.run) -> Answer {
            if let extra = arguments.keys.first(where: { $0 != "start" }) {
                return .invalidParams("unknown argument '\(clip(extra, 40))': only start is accepted")
            }
            var start: String?
            if let raw = arguments["start"], !(raw is NSNull) {
                guard let s = raw as? String else { return .invalidParams("start must be a string") }
                start = s
            }
            guard let user = start ?? caller.name else {
                return .invalidParams("the calling user's name could not be looked up; pass start")
            }
            guard validUserName(user) else {
                return .invalidParams("start must be 1 to 32 characters of letters, digits, dot, underscore and hyphen, and must not begin with - or .")
            }
            if caller.name != user, !caller.admin {
                return .payload(["available": true, "analyzed": false, "reason": "not_permitted",
                                 "mcpNote": "Only root and administrators (the admin group) can analyse another account; omit start to analyse your own."], untrusted: false)
            }
            switch run(runner, argv(user: user)) {
            case .failure(let f):
                let payload = ScopeRunner.failurePayload(f, name: "PathScope", installPath: installPath, errorKey: "pathscopeError")
                return .payload(payload, untrusted: payload["pathscopeError"] != nil)
            case .success(let report):
                var payload = summarize(report)
                payload["available"] = true
                payload["analyzed"] = true
                payload["mode"] = "single"
                payload["requestedUser"] = user
                return .payload(payload, untrusted: true)
            }
        }
    }

    // MARK: - get_access_log_report (AccessScope)

    enum AccessScope {
        static let installPath = "/Applications/AccessScope.app/Contents/MacOS/accessscope"
        static let defaultSince = "24h"
        static let schema = "accessscope-brief/1"
        static let maxHours = 90 * 24
        static let maxDays = 90
        static let maxString = 600

        /// `^[0-9]+[hd]$`, 1 to 2160 hours or 1 to 90 days.
        static func validSince(_ s: String) -> Bool {
            guard let unit = s.last, unit == "h" || unit == "d" else { return false }
            let digits = s.dropLast()
            guard !digits.isEmpty, digits.count <= 4, digits.allSatisfy({ $0.isASCII && $0.isNumber }), let n = Int(digits), n >= 1 else { return false }
            return n <= (unit == "h" ? maxHours : maxDays)
        }

        static func argv(since: String) -> [String] {
            ["scan", "--auto", "--since", since, "--format", "brief-json", "--lang", "en", "--no-suppress"]
        }

        /// Every string cut to `maxString` characters and without control characters; the JSON shape is kept.
        static func clean(_ v: Any) -> Any {
            if let s = v as? String { return clip(s, maxString) }
            if let a = v as? [Any] { return a.map(clean) }
            if let d = v as? [String: Any] {
                var out: [String: Any] = [:]
                for (k, x) in d { out[String(k.prefix(80))] = clean(x) }
                return out
            }
            return v
        }

        /// `true` when "nothing found" cannot mean "safe": the analysis was partial or a log was not read.
        static func isIncomplete(_ report: [String: Any]) -> Bool {
            let partial = (report["coverage"] as? [String: Any])?["partial"] as? Bool
            let unread = (report["sources"] as? [String: Any])?["unread"] as? [Any]
            return partial != false || (unread?.isEmpty ?? false) == false
        }

        struct UnknownSchema: Error { let name: String }

        /// The tool's answer for a report, or the unknown schema name.
        static func summarize(_ report: [String: Any], since: String) -> Result<[String: Any], UnknownSchema> {
            let found = report["schema"] as? String ?? ""
            guard found == schema else { return .failure(UnknownSchema(name: clip(found, 60))) }
            let cleaned = clean(report) as? [String: Any] ?? [:]
            let incomplete = isIncomplete(cleaned)
            let total = (cleaned["findings_total"] as? NSNumber)?.intValue ?? 0
            let unread = ((cleaned["sources"] as? [String: Any])?["unread"] as? [Any])?.count ?? 0
            let partial = (cleaned["coverage"] as? [String: Any])?["partial"]
            var out: [String: Any] = [
                "schemaSupported": true,
                "schema": schema,
                "since": since,
                "riskLevel": (cleaned["risk"] as? [String: Any])?["level"] ?? NSNull(),
                "riskScore": (cleaned["risk"] as? [String: Any])?["score"] ?? NSNull(),
                "findingsTotal": total,
                "findingsShown": cleaned["findings_shown"] ?? NSNull(),
                "coveragePartial": partial ?? NSNull(),
                "unreadSources": unread,
                "complete": !incomplete,
                "mcpNote": "Only the logs the calling user can read were analysed (privilege is not raised); what could not be read is listed in report.sources.unread. Evidence lines are masked by AccessScope and are attacker-controlled text.",
                "report": cleaned,
            ]
            if incomplete {
                var why: [String] = []
                if (partial as? Bool) != false { why.append("the analysis is partial (see report.coverage.notes)") }
                if unread > 0 { why.append("\(unread) log \(unread == 1 ? "source" : "sources") could not be read (see report.sources.unread)") }
                let lead = total == 0 ? "Zero findings does NOT mean the host is safe" : "More attacks than the ones listed may exist"
                out["mcpCaution"] = "\(lead): \(why.isEmpty ? "the report does not say that everything was read" : why.joined(separator: "; "))."
            }
            return .success(out)
        }

        /// AccessScope's "no log could be read": exit code 1 (the Linux edition's), or, when `--auto` finds no log in
        /// the standard places, exit code 2 with "Specify logs to analyze" (what the Mac build does).
        static func isNothingRead(_ f: ScopeRunner.Failure) -> Bool {
            switch f {
            case .exit(1, _): return true
            case .exit(2, let stderr): return stderr.hasPrefix("Specify logs to analyze")
            default: return false
            }
        }

        static func answer(arguments: [String: Any], runner: ScopeRunner.Runner = .accessScope,
                           run: (ScopeRunner.Runner, [String]) -> Result<[String: Any], ScopeRunner.Failure> = ScopeRunner.run) -> Answer {
            if let extra = arguments.keys.first(where: { $0 != "since" }) {
                return .invalidParams("unknown argument '\(clip(extra, 40))': only since is accepted")
            }
            var since = defaultSince
            if let raw = arguments["since"], !(raw is NSNull) {
                guard let s = raw as? String else { return .invalidParams("since must be a string like 24h or 7d") }
                guard validSince(s) else { return .invalidParams("since must be 1 to 2160 hours or 1 to 90 days, written like 24h or 7d") }
                since = s
            }
            switch run(runner, argv(since: since)) {
            case .failure(let f):
                var payload: [String: Any]
                if isNothingRead(f) {
                    payload = ["available": true, "analyzed": false, "reason": "nothing_read",
                               "mcpNote": "AccessScope could not read any log: no web server, SSH or auth log that this user may read was found in the standard places. This says nothing about the Mac being safe; run the tool as a user who can read the logs."]
                } else {
                    payload = ScopeRunner.failurePayload(f, name: "AccessScope", installPath: installPath, errorKey: "accessscopeError")
                }
                return .payload(payload, untrusted: payload["accessscopeError"] != nil)
            case .success(let report):
                switch summarize(report, since: since) {
                case .success(var payload):
                    payload["available"] = true
                    payload["analyzed"] = true
                    return .payload(payload, untrusted: true)
                case .failure(let unknown):
                    return .payload(["available": true, "analyzed": false, "reason": "unknown_schema", "schema": unknown.name,
                                     "mcpNote": "AccessScope answered with a schema this version of RoamSwitch does not understand (expected \(schema)), so its data is not shown. Update RoamSwitch or run accessscope scan yourself."],
                                    untrusted: true)
                }
            }
        }
    }

    // MARK: - get_link_guard_status

    enum LinkGuardStatus {
        static let windowDays = 7
        static let maxEvents = 50
        static let maxListed = 200
        /// How much of the end of `events.log` is read (the file is trimmed by the filter; this bounds a damaged one).
        static let maxLogBytes = 512 * 1024

        struct Input {
            var configuredMode: String?
            var allowlist: [String] = []
            /// host -> epoch seconds when a temporary allowance ends.
            var allowExpiry: [String: Double] = [:]
            var blocklistExtra: [String] = []
            var updatesEnabled: Bool?
            var feedVersion: String?
            var enforcement: LinkGuardEnforcement?
            /// The mode the content filter publishes (`linkfilter/mode`); nil when it cannot be read.
            var publishedMode: String?
            /// `nil`: the event log could not be read. An absent file is the empty string.
            var eventsLog: String?
            var now: Date
        }

        static let modeKey = "RoamSwitch.LinkGuardMode"
        static let updatesKey = "RoamSwitch.LinkGuardUpdatesEnabled"
        static let allowlistKey = "RoamSwitch.LinkGuardAllowlist"
        static let allowExpiryKey = "RoamSwitch.LinkGuardAllowExpiry"
        static let blocklistExtraKey = "RoamSwitch.LinkGuardBlocklistExtra"
        static let feedVersionKey = "RoamSwitch.LinkGuardFeedVersion"

        /// The end of `path` as text: the empty string when the file does not exist, nil when it exists and cannot be read.
        static func readTail(path: String, maxBytes: Int = maxLogBytes) -> String? {
            guard FileManager.default.fileExists(atPath: path) else { return "" }
            guard let handle = FileHandle(forReadingAtPath: path) else { return nil }
            defer { try? handle.close() }
            guard let size = try? handle.seekToEnd() else { return nil }
            let start = size > UInt64(maxBytes) ? size - UInt64(maxBytes) : 0
            guard (try? handle.seek(toOffset: start)) != nil, let data = try? handle.readToEnd() else { return nil }
            return String(decoding: data, as: UTF8.self)
        }

        /// What the app saved in `defaults` and what the content filter published in `stateDir`.
        static func input(defaults: UserDefaults, stateDir: String, now: Date, enforcement: LinkGuardEnforcement?) -> Input {
            var input = Input(now: now)
            input.configuredMode = defaults.string(forKey: modeKey)
            input.allowlist = defaults.stringArray(forKey: allowlistKey) ?? []
            input.allowExpiry = defaults.dictionary(forKey: allowExpiryKey) as? [String: Double] ?? [:]
            input.blocklistExtra = defaults.stringArray(forKey: blocklistExtraKey) ?? []
            input.updatesEnabled = defaults.object(forKey: updatesKey) == nil ? nil : defaults.bool(forKey: updatesKey)
            input.feedVersion = defaults.string(forKey: feedVersionKey)
            input.enforcement = enforcement
            input.publishedMode = (try? String(contentsOfFile: stateDir + "/mode", encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines)
            input.eventsLog = readTail(path: stateDir + "/events.log")
            return input
        }

        /// `events.log` lines newest first within the window: `<epoch> TAB block|warn|notice TAB host TAB reason TAB app`.
        static func events(from log: String, now: Date) -> [[String: Any]] {
            let iso = ISO8601DateFormatter()
            let from = now.addingTimeInterval(-Double(windowDays) * 86_400)
            var out: [(Date, [String: Any])] = []
            for line in log.split(separator: "\n") {
                guard let event = LinkFilterEngine.parseEventLine(line),
                      let epoch = line.split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false).first.flatMap({ Double($0) }) else { continue }
                let at = Date(timeIntervalSince1970: epoch)
                guard at >= from, at <= now.addingTimeInterval(3600) else { continue }
                let (kind, label) = event.kind == "block" ? ("blocked", "Blocked") : event.kind == "warn" ? ("held", "Held, waiting for the user") : ("callback", "Contact with a security-test callback server (notice only)")
                var item: [String: Any] = ["timestamp": iso.string(from: at), "kind": kind, "kindLabel": label, "host": clip(event.host, 200)]
                if let reason = event.reason { item["reason"] = clip(reason, 60) }
                if let app = event.sourceApp { item["sourceApp"] = clip(app, 200) }
                out.append((at, item))
            }
            return out.sorted { $0.0 > $1.0 }.prefix(maxEvents).map(\.1)
        }

        static func payload(_ i: Input) -> [String: Any] {
            let mode = LinkGuardMode(rawValue: i.configuredMode ?? "")?.rawValue ?? "block"
            let enabled = mode != "off"
            let nowEpoch = i.now.timeIntervalSince1970
            // A temporary allowance that has ended is not an allowance (the app prunes it at its next change).
            let allowlist = i.allowlist.filter { host in (i.allowExpiry[host.lowercased()] ?? i.allowExpiry[host]).map { $0 > nowEpoch } ?? true }
            let eventList = i.eventsLog.map { events(from: $0, now: i.now) } ?? []
            let blocked = eventList.filter { $0["kind"] as? String == "blocked" }.count
            let held = eventList.filter { $0["kind"] as? String == "held" }.count
            let callbacks = eventList.count - blocked - held
            var caveats = [
                "Events come from the content filter's event log (one line per host per hour at most), so the counts are hosts that were reported, not connection attempts, and the log keeps only the recent past.",
                "A connection that is held right now, waiting for the user's allow or block decision, is kept in the app's memory and cannot be seen from this process.",
                "Hosts and application paths in the events come from the network and from running programs and are untrusted.",
            ]
            if i.eventsLog == nil { caveats.append("The content filter's event log could not be read, so recentEvents may be empty although events happened.") }
            if enabled, let enforcement = i.enforcement, enforcement.isDegraded {
                caveats.append("The system extension is not filtering (enforcement: \(enforcement.rawValue)): the guard falls back to the /etc/hosts block list, which browsers that encrypt their DNS (DoH) bypass.")
            }
            if i.enforcement == nil { caveats.append("The app has not reported where the guard is enforced lately (it may not be running), so enforcement is unknown.") }
            var out: [String: Any] = [
                "enabled": enabled,
                "mode": mode,
                "effectiveMode": enabled ? mode : "off",
                "enforcement": i.enforcement?.rawValue ?? "unknown",
                "allowlist": Array(allowlist.prefix(maxListed).map { clip($0, 200) }),
                "blocklistExtra": Array(i.blocklistExtra.prefix(maxListed).map { clip($0, 200) }),
                "feedUpdatesEnabled": i.updatesEnabled ?? true,
                "recentEvents": eventList,
                "summary": "Link Guard: \(enabled ? mode : "off") (last \(windowDays) days: \(blocked) blocked / \(held) held / \(callbacks) callback \(callbacks == 1 ? "notice" : "notices"))",
                "caveats": caveats,
            ]
            if let published = i.publishedMode { out["publishedMode"] = clip(published, 20) }
            if let version = i.feedVersion, !version.isEmpty, version != "—" { out["feedVersion"] = clip(version, 40) }
            return out
        }
    }

    // MARK: - get_vpn_status

    enum VPNStatus {
        struct Input {
            var backend: String
            var wireGuardEnabled: Bool
            var wireGuardEndpointHost: String?
            var wireGuardEndpointPort: Int?
            var tailscaleExitNode: String
            var tailscaleKillSwitch: Bool
            var activeLevel: String
        }

        static func input(defaults: UserDefaults, activeLevel: String) -> Input {
            let stored = (defaults.string(forKey: "RoamSwitch.VPNBackend") ?? "").lowercased()
            let port = defaults.integer(forKey: "RoamSwitch.WireGuardEndpointPort")
            return Input(
                backend: stored == "tailscale" || stored == "ts" ? "tailscale" : "wireguard",
                wireGuardEnabled: defaults.bool(forKey: "RoamSwitch.WireGuardVPNEnabled"),
                wireGuardEndpointHost: defaults.string(forKey: "RoamSwitch.WireGuardEndpointHost"),
                wireGuardEndpointPort: port > 0 ? port : nil,
                tailscaleExitNode: defaults.string(forKey: "RoamSwitch.VPNTailscaleExitNode") ?? "",
                tailscaleKillSwitch: defaults.bool(forKey: "RoamSwitch.VPNTailscaleKillSwitch"),
                activeLevel: activeLevel)
        }

        static func payload(_ i: Input) -> [String: Any] {
            let tailscale = i.backend == "tailscale"
            // For Tailscale the protection is "an exit node is chosen"; for WireGuard it is the toggle.
            let enabled = tailscale ? !i.tailscaleExitNode.isEmpty : i.wireGuardEnabled
            let expected = enabled && i.activeLevel == "lockdown"
            var wireguard: [String: Any] = ["autoConnectEnabled": i.wireGuardEnabled]
            if let host = i.wireGuardEndpointHost, !host.isEmpty {
                wireguard["endpoint"] = i.wireGuardEndpointPort.map { "\(clip(host, 200)):\($0)" } ?? clip(host, 200)
            }
            return [
                "vpnOnUntrustedEnabled": enabled,
                "backend": i.backend,
                "activeLevel": i.activeLevel,
                "tunnelExpectedNow": expected,
                "tunnelUp": NSNull(),
                "killSwitchArmed": NSNull(),
                "killSwitchVerified": NSNull(),
                "wireguard": wireguard,
                "tailscale": ["exitNodeConfigured": !i.tailscaleExitNode.isEmpty, "killSwitchEnabledInSettings": i.tailscaleKillSwitch],
                "summary": "VPN on untrusted networks: \(enabled ? "on" : "off") (\(i.backend)); the tunnel is expected up now: \(expected ? "yes" : "no") (it is brought up only at the lockdown level, now \(i.activeLevel)); whether it is up cannot be read from this process",
                "caveats": [
                    "Settings only: whether the tunnel is actually up and whether the kill-switch rules are loaded are held by the app and its root helper, so tunnelUp, killSwitchArmed and killSwitchVerified are null here.",
                    "The daemon brings the tunnel up only at the lockdown level (and, for WireGuard, with a configuration imported; for Tailscale, with an exit node chosen); tunnelExpectedNow is that rule applied to the settings.",
                    "activeLevel is the manual override, or the level used away from trusted networks: the current gateway is not looked up here, so on a trusted network the level in force may differ.",
                ],
            ]
        }
    }

    // MARK: - verify_fim

    enum Fim {
        static let baselineKey = "RoamSwitch.CriticalPathFimBaselineV1"
        static let hostsPath = "/etc/hosts"

        enum Read: Equatable {
            case hash(String)
            /// The file does not exist.
            case absent
            /// It exists and the calling user cannot read it.
            case unreadable
        }

        static var fixedTargets: [String] {
            ["/etc/sudoers", "/etc/pam.d/sudo", "/etc/ssh/sshd_config", "/etc/hosts",
             (NSHomeDirectoryForUser("root") ?? "/var/root") + "/.ssh/authorized_keys"]
        }

        /// The paths to read: the helper's list (the fixed files and the entries of the watched directories) plus every
        /// path the baseline holds, so a file that left the list is still compared.
        static func targets(stored: [String: String]) -> [String] {
            var targets = CriticalPathFimTargets.expand(
                fixed: fixedTargets,
                listDirectory: { try? FileManager.default.contentsOfDirectory(atPath: $0) },
                isDirectory: { path in
                    var isDir: ObjCBool = false
                    return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
                })
            for path in stored.keys.sorted() where !targets.contains(path) { targets.append(path) }
            return targets
        }

        /// SHA-256 as the helper takes it (`/etc/hosts` without RoamSwitch's own managed section).
        static func read(path: String) -> Read {
            guard FileManager.default.fileExists(atPath: path) else { return .absent }
            guard var data = FileManager.default.contents(atPath: path) else { return .unreadable }
            if path == hostsPath, let text = String(data: data, encoding: .utf8) {
                data = Data(LinkGuardHosts.fimComparableContent(text).utf8)
            }
            return .hash(SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined())
        }

        /// The whole check: the baseline from `defaults`, the files as the calling user can read them.
        static func run(defaults: UserDefaults, now: Date = Date()) -> [String: Any] {
            var stored: [String: String]?
            var unreadable = false
            if let data = defaults.data(forKey: baselineKey) {
                if let hashes = try? StrictJSON.decode([String: String].self, from: data) { stored = hashes } else { unreadable = true }
            }
            var reads: [String: Read] = [:]
            if let stored { for path in targets(stored: stored) { reads[path] = read(path: path) } }
            return payload(stored: stored, baselineUnreadable: unreadable, reads: reads, now: now)
        }

        /// `stored`: the baseline (path -> SHA-256); nil when there is none or it cannot be read.
        static func payload(stored: [String: String]?, baselineUnreadable: Bool, reads: [String: Read], now: Date) -> [String: Any] {
            let iso = ISO8601DateFormatter().string(from: now)
            let caveats = [
                "Critical Path FIM checks a fixed set of system files (sudoers, pam, sshd_config, /etc/hosts without RoamSwitch's own managed section, root's authorized_keys and the files in sshd_config.d, sudoers.d and pam.d) against the baseline the app saved. This tool re-hashes them as the calling user, so files only root can read are counted in skipped_unreadable and are not compared.",
                "It does not update or initialize the baseline: taking the current files as the new baseline is a confirmed action in the app, deliberately not exposed through MCP.",
                "Lockfile tamper detection (dependency lockfiles in the registered project folders) and the record of who made a change are not part of this tool on the Mac; lockfileFim is null for that reason.",
            ]
            var out: [String: Any] = ["lockfileFim": NSNull(), "baselineAvailable": stored != nil]
            guard let stored else {
                out["criticalPathFim"] = NSNull()
                out["mcpNote"] = baselineUnreadable
                    ? "The saved baseline exists but could not be read, so nothing was compared. This says nothing about the files being unchanged."
                    : "No baseline is saved (Critical Path FIM has not been turned on, or has not taken its first baseline yet), so nothing was compared."
                out["caveats"] = caveats
                return out
            }
            var violations: [[String: Any]] = []
            var passed = 0, skipped = 0
            for path in stored.keys.sorted() {
                let expected = stored[path]
                switch reads[path] ?? .unreadable {
                case .unreadable: skipped += 1
                case .absent:
                    violations.append(["path": clip(path, 300), "violation_type": "deleted", "expected_sha256": expected as Any, "actual_sha256": NSNull(), "detected_at": iso])
                case .hash(let actual):
                    if actual == expected { passed += 1 }
                    else { violations.append(["path": clip(path, 300), "violation_type": "modified", "expected_sha256": expected as Any, "actual_sha256": actual, "detected_at": iso]) }
                }
            }
            for path in reads.keys.sorted() where stored[path] == nil {
                if case .hash(let actual) = reads[path]! {
                    violations.append(["path": clip(path, 300), "violation_type": "new_file", "expected_sha256": NSNull(), "actual_sha256": actual, "detected_at": iso])
                }
            }
            out["criticalPathFim"] = [
                "total_monitored": stored.count,
                "passed_count": passed,
                "violations": violations,
                "last_checked_at": iso,
                "is_healthy": violations.isEmpty,
                "skipped_unreadable": skipped,
            ] as [String: Any]
            if skipped > 0 {
                out["mcpCaution"] = "\(skipped) of \(stored.count) baseline files could not be read without root and were not compared: no violation here does NOT mean those files are unchanged. The app compares them continuously through its root helper."
            }
            out["caveats"] = caveats
            return out
        }
    }
}
