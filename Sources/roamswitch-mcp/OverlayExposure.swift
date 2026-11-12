// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.30 (build 209).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Audit check `overlay_exposure`: what the Tailscale tailnet adds to this Mac's exposure.
///
/// A device in the same tailnet reaches this Mac's listening ports directly, from the inside, unless Tailscale's
/// incoming-connection block ("shields up") is on. So a risky listener (SSH, a database, a remote-control port)
/// that a LAN firewall would hide is open to every device in the tailnet. And an `ngrok` or `cloudflared` tunnel
/// next to Tailscale turns a break-in through the tunnel into a way into the tailnet.
///
/// What is read, all of it local and read-only (nothing is sent anywhere, nothing is written):
/// - `tailscale status --json`: only whether the backend is running.
/// - `tailscale debug prefs`: only `ShieldsUp`, `AdvertiseRoutes` and `RunSSH`. That JSON also carries the node's
///   private keys; nothing but those three fields is kept, and nothing of it is logged or put in an error text.
/// - the listening-port list the `exposed_ports` check already has (`ListeningPortInfo`, with the bind address).
/// - the names of the running programs (`ps`), only to look for `ngrok` and `cloudflared` by exact name.
///
/// What it does not do: it does not read the tailnet's access rules (ACLs), so a listener that the ACL hides from
/// every other device is still reported. It does not treat the macOS firewall as a reason to pass: whether the
/// firewall's block-all stops traffic that arrives on the Tailscale interface has not been measured, so only
/// Tailscale's own incoming block ends the listener part of the check.
/// Advertising an exit node, advertising subnet routes and Tailscale SSH are shown in the status line and never fail it.
enum OverlayExposure {

    // MARK: - Tailscale's CLI

    /// The Tailscale command-line tool, in the order it is looked for. The one inside the App Store app is last.
    /// `TailscaleVPNManager` uses this same list.
    static let cliCandidates = [
        "/usr/local/bin/tailscale",
        "/opt/homebrew/bin/tailscale",
        "/Applications/Tailscale.app/Contents/MacOS/Tailscale",
    ]

    static func firstCLIPath(exists: (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }) -> String? {
        cliCandidates.first(where: exists)
    }

    /// The standalone `tailscaled` sockets, newest Homebrew first. Empty for the App Store build (its own IPC).
    static func socketArgs(cli: String, exists: (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }) -> [String] {
        guard !cli.hasPrefix("/Applications/Tailscale.app") else { return [] }
        for s in ["/var/run/tailscaled.socket", "/var/run/tailscale/tailscaled.sock"] where exists(s) {
            return ["--socket", s]
        }
        return []
    }

    // MARK: - What is read from Tailscale

    /// The three fields of `tailscale debug prefs` this check uses. Nothing else of that JSON is kept.
    struct Prefs: Equatable {
        /// Tailscale's incoming-connection block (`tailscale set --shields-up`).
        var shieldsUp: Bool
        /// `0.0.0.0/0` or `::/0` is advertised: this Mac offers itself as an exit node.
        var advertisesExitNode: Bool
        /// Advertised routes other than the default routes: this Mac offers itself as a subnet router.
        var advertisedSubnets: [String]
        /// Tailscale SSH (`tailscale set --ssh`).
        var runSSH: Bool
    }

    /// nil when `ShieldsUp` is not a boolean (the shape is not the one this reads, so nothing is guessed) or
    /// when `AdvertiseRoutes` is present but is not a list of strings.
    static func parsePrefs(_ data: Data) -> Prefs? {
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let shields = root["ShieldsUp"] as? Bool else { return nil }
        var routes: [String] = []
        switch root["AdvertiseRoutes"] {
        case nil, is NSNull: break
        case let list as [String]: routes = list
        default: return nil
        }
        let defaults: Set<String> = ["0.0.0.0/0", "::/0"]
        return Prefs(
            shieldsUp: shields,
            advertisesExitNode: routes.contains { defaults.contains($0) },
            advertisedSubnets: routes.filter { !defaults.contains($0) },
            runSSH: (root["RunSSH"] as? Bool) ?? false)
    }

    /// `tailscale status --json`: the backend state, nil when the output is not that JSON.
    static func parseBackendState(_ data: Data) -> String? {
        ((try? JSONSerialization.jsonObject(with: data)) as? [String: Any])?["BackendState"] as? String
    }

    enum TailscaleState: Equatable {
        case notInstalled
        /// The tool is there and the backend is not running (stopped, logged out, or the service is not up).
        case notRunning
        /// The tool is there but its answer could not be read (not measured).
        case unreadable
        case running(Prefs)
    }

    // MARK: - Listeners

    /// Ports whose listener is a way into the Mac from another machine: the unauthenticated services and local AI
    /// runtimes `PortSecurityAuditor.criticalUnauthenticatedServicePorts` names, plus remote login, file sharing,
    /// remote desktop and the common databases.
    static let remoteAccessPorts: Set<Int> = [22, 23, 139, 445, 2049, 2376, 3306, 3389, 5432, 5900]

    static func isRiskyPort(_ l: ListeningPortInfo) -> Bool {
        if PortSecurityAuditor.criticalUnauthenticatedServicePorts[l.port] != nil {
            return PortSecurityAuditor.namesTheService(l)
        }
        return remoteAccessPorts.contains(l.port)
    }

    /// Whether a bind address, as `lsof` prints it, can be reached from the tailnet: a wildcard, or an address of
    /// the Tailscale interface (`100.64.0.0/10`, `fd7a:115c:a1e0::/48`). A bind to the LAN address or to loopback is not.
    static func isTailnetReachableBind(_ host: String) -> Bool {
        var h = host.trimmingCharacters(in: .whitespaces).lowercased()
        if h.hasPrefix("["), h.hasSuffix("]") { h = String(h.dropFirst().dropLast()) }
        if h == "*" || h == "0.0.0.0" || h == "::" { return true }
        if h.hasPrefix("fd7a:115c:a1e0:") { return true }
        let octets = h.split(separator: ".", omittingEmptySubsequences: false).map { Int($0) }
        if octets.count == 4, let a = octets[0], let b = octets[1], a == 100, (64...127).contains(b),
           octets.allSatisfy({ ($0 ?? -1) >= 0 && ($0 ?? 256) <= 255 }) { return true }
        return false
    }

    /// The risky TCP listeners the tailnet can reach, one per port.
    static func tailnetRiskyListeners(_ ports: [ListeningPortInfo]) -> [ListeningPortInfo] {
        var seen = Set<Int>()
        var out: [ListeningPortInfo] = []
        for l in ports.sorted(by: { $0.port < $1.port }) where l.proto == "tcp" && isRiskyPort(l) && isTailnetReachableBind(l.bindHost) {
            if seen.insert(l.port).inserted { out.append(l) }
        }
        return out
    }

    // MARK: - Tunnels

    /// Programs that publish a local service to the internet. Matched by the exact file name.
    static let tunnelPrograms: Set<String> = ["ngrok", "cloudflared"]

    /// The program names of `ps -axo comm=` (one executable path per line): the last path component of each line.
    static func parseProgramNames(_ psOutput: String) -> Set<String> {
        var names = Set<String>()
        for line in psOutput.split(whereSeparator: \.isNewline) {
            let t = line.trimmingCharacters(in: .whitespaces)
            guard !t.isEmpty else { continue }
            names.insert(t.split(separator: "/", omittingEmptySubsequences: true).last.map(String.init) ?? t)
        }
        return names
    }

    // MARK: - Verdict

    struct Outcome: Equatable {
        var isApplicable: Bool
        var isPassed: Bool
        /// `not_measured` / `tool_failed`, the codes `exposed_ports` uses; nil when the result is confirmed.
        var inconclusiveReason: String?
        var prefs: Prefs?
        /// The risky ports the tailnet reaches (empty when shields are up).
        var riskyPorts: [(port: Int, process: String)]
        /// `ngrok` / `cloudflared` found running next to Tailscale.
        var tunnels: [String]

        static func == (a: Outcome, b: Outcome) -> Bool {
            a.isApplicable == b.isApplicable && a.isPassed == b.isPassed && a.inconclusiveReason == b.inconclusiveReason
                && a.prefs == b.prefs && a.tunnels == b.tunnels
                && a.riskyPorts.map { "\($0.port) \($0.process)" } == b.riskyPorts.map { "\($0.port) \($0.process)" }
        }
    }

    /// Pure. `listeners`: nil when the port list could not be read. `programs`: nil when the program list could not
    /// be read. `listenersNotMeasuredYet`: the list was never taken (reason `not_measured`) rather than failed.
    static func evaluate(tailscale: TailscaleState, listeners: [ListeningPortInfo]?, programs: Set<String>?,
                         listenersNotMeasuredYet: Bool = false) -> Outcome {
        func plain(_ applicable: Bool, passed: Bool = true, reason: String? = nil) -> Outcome {
            Outcome(isApplicable: applicable, isPassed: passed, inconclusiveReason: reason, prefs: nil, riskyPorts: [], tunnels: [])
        }
        switch tailscale {
        case .notInstalled, .notRunning:
            return plain(false)
        case .unreadable:
            return plain(true, reason: "tool_failed")
        case .running(let prefs):
            let risky = prefs.shieldsUp ? [] : tailnetRiskyListeners(listeners ?? [])
            let tunnels = (programs ?? []).intersection(tunnelPrograms).sorted()
            let failed = !risky.isEmpty || !tunnels.isEmpty
            // A failure that was seen stands, whatever else could not be read.
            var reason: String?
            if !failed {
                if !prefs.shieldsUp && listeners == nil {
                    reason = listenersNotMeasuredYet ? "not_measured" : "tool_failed"
                } else if programs == nil {
                    reason = "tool_failed"
                }
            }
            return Outcome(isApplicable: true, isPassed: !failed, inconclusiveReason: reason, prefs: prefs,
                           riskyPorts: risky.map { ($0.port, $0.processName) }, tunnels: tunnels)
        }
    }

    // MARK: - Reading this Mac

    /// A command with a time limit, so a Tailscale service that does not answer cannot hold the audit.
    /// nil when it could not start or did not finish in time.
    static func runWithTimeout(_ path: String, _ arguments: [String], timeout: TimeInterval = 5) -> CommandOutput? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = arguments
        let out = Pipe(), err = Pipe()
        p.standardOutput = out
        p.standardError = err
        p.standardInput = FileHandle.nullDevice
        let finished = DispatchSemaphore(value: 0)
        p.terminationHandler = { _ in finished.signal() }
        do { try p.run() } catch { return nil }
        let box = OutputBox()
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global().async { box.setOut(out.fileHandleForReading.readDataToEndOfFile()); group.leave() }
        group.enter()
        DispatchQueue.global().async { box.setErr(err.fileHandleForReading.readDataToEndOfFile()); group.leave() }
        if finished.wait(timeout: .now() + timeout) == .timedOut {
            p.terminate()
            _ = group.wait(timeout: .now() + 1)
            return nil
        }
        group.wait()
        let status: Int32 = p.terminationReason == .uncaughtSignal ? -1 : p.terminationStatus
        let (o, e) = box.get()
        return CommandOutput(status: status, stdout: String(decoding: o, as: UTF8.self), stderr: String(decoding: e, as: UTF8.self))
    }

    private final class OutputBox: @unchecked Sendable {
        private let lock = NSLock()
        private var out = Data(), err = Data()
        func setOut(_ d: Data) { lock.lock(); out = d; lock.unlock() }
        func setErr(_ d: Data) { lock.lock(); err = d; lock.unlock() }
        func get() -> (Data, Data) { lock.lock(); defer { lock.unlock() }; return (out, err) }
    }

    /// The text Tailscale prints when its service is not up. Only this, in a failed `status`, means "not running";
    /// any other failure is "could not read".
    static func saysServiceIsNotRunning(_ stderrAndStdout: String) -> Bool {
        let t = stderrAndStdout.lowercased()
        return t.contains("failed to connect to local tailscale") || t.contains("is tailscale running")
    }

    /// `status --json` and `debug prefs` through `run`, which is given the tool path and its arguments.
    static func readTailscale(cli: String?, socketArgs: [String], run: (String, [String]) -> CommandOutput?) -> TailscaleState {
        guard let cli else { return .notInstalled }
        // With the explicit socket first, then without it (the same order `TailscaleVPNManager` uses).
        var attempts: [[String]] = [socketArgs]
        if !socketArgs.isEmpty { attempts.append([]) }
        var statusOut: CommandOutput?
        var usedArgs: [String] = []
        var serviceDown = false
        for extra in attempts {
            guard let out = run(cli, extra + ["status", "--json"]) else { continue }
            // A status that names its backend state is the answer, whatever the exit status says.
            if parseBackendState(Data(out.stdout.utf8)) != nil {
                statusOut = out
                usedArgs = extra
                break
            }
            if saysServiceIsNotRunning(out.stderr + "\n" + out.stdout) { serviceDown = true }
        }
        guard let statusOut, let state = parseBackendState(Data(statusOut.stdout.utf8)) else {
            return serviceDown ? .notRunning : .unreadable
        }
        guard state == "Running" else { return .notRunning }
        guard let prefsOut = run(cli, usedArgs + ["debug", "prefs"]), prefsOut.status == 0,
              let prefs = parsePrefs(Data(prefsOut.stdout.utf8)) else { return .unreadable }
        return .running(prefs)
    }
}

/// Where Tailscale's state and the program list come from (replaced in tests).
protocol OverlayExposureSource {
    func tailscale() -> OverlayExposure.TailscaleState
    /// nil when the program list could not be read.
    func programNames() -> Set<String>?
}

struct SystemOverlayExposureSource: OverlayExposureSource {
    /// Whether a file exists, and how a command is run. A test replaces them to look at the live reading with no
    /// Tailscale on the Mac, or with a service that is not up, without touching the Tailscale that is running.
    var exists: (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }
    var run: (String, [String]) -> CommandOutput? = { OverlayExposure.runWithTimeout($0, $1) }

    func tailscale() -> OverlayExposure.TailscaleState {
        let cli = OverlayExposure.firstCLIPath(exists: exists)
        return OverlayExposure.readTailscale(
            cli: cli,
            socketArgs: cli.map { OverlayExposure.socketArgs(cli: $0, exists: exists) } ?? [],
            run: run)
    }

    func programNames() -> Set<String>? {
        guard let out = OverlayExposure.runWithTimeout("/bin/ps", ["-axo", "comm="]), out.status == 0 else { return nil }
        return OverlayExposure.parseProgramNames(out.stdout)
    }
}
