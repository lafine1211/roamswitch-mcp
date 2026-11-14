// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.0.0 (build 216).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// What the Endpoint Security extension (`RoamSwitchESClient`) tells the app, and how the app turns it into a state a
/// person can act on. Pure data and rules: no Endpoint Security here, so it is compiled into the app, the extension
/// and the tests.
///
/// **One extension, one approval, one Full Disk Access, many clients.** Every Endpoint Security client of the product
/// (AUTH ones such as the pre-exec block, the frozen-process protection and the USB mount check, and NOTIFY ones of
/// later stages) lives in this extension, so the person approves one extension and one Full Disk Access row, and every
/// guard that uses it shows the same reasons (`es_*`, see `ESEnforcement`). What belongs to one client (its counters,
/// whether it is running) is in its `ESClientStatus`, found by its `purpose`.
///
/// **How the two talk (and why).** The extension runs as root and writes into a root-owned folder, which the app
/// reads; the helper, which is root too, writes the settings the extension reads. This is the way the link-filter
/// extension and the app already talk (`linkfilter/outscan.conf`, `outscan.log`). The folder is `0755` and root-owned,
/// so a process that is not root cannot change what the extension said or what it reads: an attacker cannot make the
/// app believe the extension works, or change its settings, by writing there. An XPC mach service of the extension
/// (`NSEndpointSecurityMachServiceName`) would push events at once, but a system extension's service name has to
/// begin with an App Group the extension is entitled to, which needs a new capability and profile; see
/// `docs/ES_CLIENT.md`. The folder works with the profile in hand and is the path taken now.
enum ESExtensionFiles {
    static let stateDir = "/Library/Application Support/RoamSwitch/esclient"
    static let statusFileName = "status.json"
    static var statusPath: String { stateDir + "/" + statusFileName }
}

/// The names of the clients (`ESClientPurpose.purposeName`, `ESClientStatus.purpose`). A stage that adds a client adds
/// its name here.
enum ESPurpose {
    /// AUTH_EXEC: the pre-exec block (`ExecBlockPurpose`).
    static let execBlock = "execBlock"
    /// AUTH_SIGNAL and AUTH_PROC_SUSPEND_RESUME: the protection of frozen processes (`FrozenGuardPurpose`).
    static let frozenGuard = "frozenGuard"
    /// AUTH_MOUNT: the USB storage mount check (`USBMountPurpose`).
    static let usbMount = "usbMount"
    /// NOTIFY_SIGNAL only: the extension's part of the frozen-signal watch in a build without `ES_AUTH` (`FrozenSignalNotifyPurpose`).
    /// With `ES_AUTH` the same watch is a part of `frozenGuard`; `frozenSignalWatch` names the client that has it in this build.
    static let frozenSignal = "frozenSignal"
    /// The client that delivers the frozen-signal watch's events (`signal` stream) in this build.
    #if ES_AUTH
    static let frozenSignalWatch = frozenGuard
    #else
    static let frozenSignalWatch = frozenSignal
    #endif
    /// NOTIFY_EXEC / FORK / EXIT: every process event, given to the purposes that subscribed (`ProcessEventPurpose`,
    /// `ESProcessEventRouter`). The process recorder (the exec recorder of the helper) is the first subscriber.
    static let processEvents = "processEvents"
    /// The NOTIFY events that are not about files or process starts (background-task registrations, SSH and console logins,
    /// XProtect, sudo, authentication, task ports, profiles, Screen Sharing, TCC, Open Directory, quarantine removal,
    /// Gatekeeper overrides): `SystemEventsPurpose`, `ESSystemUse`.
    static let systemEvents = "systemEvents"
    /// The few file events (create, rename, unlink, clone, copyfile, truncate), no mute inversion: every event reaches the
    /// extension, which delivers it to the watches it matches (`ESPathWatchRegistry`, class `broad`).
    static let pathWatchBroad = "pathWatchBroad"
    /// The many file events (open), inverted target-path muting: the kernel delivers only the registered paths
    /// (`ESPathWatchRegistry`, class `narrow`).
    static let pathWatchNarrow = "pathWatchNarrow"
    /// `close` (the file was written), inverted target-path muting, its own client (`ESPathClientClass.narrowClose`).
    static let pathWatchClose = "pathWatchClose"
}

/// Whether a file of the state folder may be believed: written by root and not writable by anyone else. The extension
/// reads the settings the helper wrote and the app reads what the extension wrote; both check this first (and that
/// the folder is root's too), so a file planted by an ordinary process is ignored.
enum ESStateFileTrust {
    static func isTrustedFile(uid: UInt32, mode: UInt32) -> Bool {
        let isRegular = (mode & 0o170000) == 0o100000
        return uid == 0 && isRegular && (mode & 0o022) == 0
    }
}

// MARK: - What the extension reports

/// The result of `es_new_client`, in words of ours (the extension maps `es_new_client_result_t` to it).
enum ESClientCreateResult: String, Codable, Equatable {
    /// Not tried yet, or not wanted (the extension holds no client for it).
    case notAttempted
    case success
    case invalidArgument
    case internalError
    /// The extension lacks `com.apple.developer.endpoint-security.client` (a build signed without the profile).
    case notEntitled
    /// The extension is not approved for Full Disk Access (the header: "es_new_client returns ERR_NOT_PERMITTED").
    case notPermitted
    /// The process is not root.
    case notPrivileged
    /// Other Endpoint Security products use up the clients the system allows.
    case tooManyClients
}

struct ESClientStatus: Codable, Equatable {
    /// What the client is for (`ESClientPurpose.purposeName`). Each stage that adds a client names its own.
    var purpose: String
    var result: ESClientCreateResult = .notAttempted
    var subscribed = false
    /// Messages received since the extension started.
    var received: UInt64 = 0
    /// Events the kernel dropped for this client (gaps in `seq_num` / `global_seq_num`).
    var droppedEvents: UInt64 = 0
    /// Counters of the purpose itself, by name (a purpose adds what it wants shown).
    var extra: [String: UInt64] = [:]
    /// The events this client holds a subscription to (`ES_EVENT_TYPE_...`), empty while it has no client. For checking a build,
    /// above all that a build without `ES_AUTH` holds no AUTH event. Optional: a report of an older extension has no such key.
    var subscribedEvents: [String]?
}

struct ESExtensionStatus: Codable, Equatable {
    static let currentSchema = 1
    /// The extension rewrites the file this often even when nothing changed, so the app can tell "not running".
    static let heartbeatSecs: Double = 15
    /// Older than this, the file is not evidence of anything running now.
    static let freshSecs: Double = 90

    var schema = ESExtensionStatus.currentSchema
    var updatedEpoch: Double
    var pid: Int32
    /// One entry per client the extension holds or wants. Empty when no purpose is registered.
    var clients: [ESClientStatus]

    func client(_ purpose: String) -> ESClientStatus? { clients.first { $0.purpose == purpose } }

    func isFresh(now: Double) -> Bool {
        now - updatedEpoch <= Self.freshSecs && updatedEpoch - now <= Self.freshSecs
    }

    static func decode(_ data: Data) -> ESExtensionStatus? {
        guard let s = try? JSONDecoder().decode(ESExtensionStatus.self, from: data), s.schema == currentSchema else { return nil }
        return s
    }

    func encoded() -> Data? {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        return try? e.encode(self)
    }
}

// MARK: - What it means for the person

/// The state of the Endpoint Security extension as the status window, the menu and the guards that use it show it.
enum ESEnforcement: String, Codable, Equatable, CaseIterable {
    /// The extension runs and reports; every client that was asked for is created and subscribed.
    case active
    /// The extension is waiting for the person's approval (System Settings, Login Items & Extensions).
    case waitingForApproval
    /// Approved, but the system starts it only after a restart.
    case waitingForReboot
    /// The extension runs but cannot create a client: Full Disk Access is missing.
    case needsFullDiskAccess
    /// The extension was signed without the Endpoint Security entitlement.
    case notEntitled
    /// The system allows no more Endpoint Security clients.
    case tooManyClients
    /// The request or a client failed for another reason.
    case failed
    /// Not requested yet, or not running (no recent report from the extension).
    case notRunning

    var isActive: Bool { self == .active }

    /// The reason code of the guard status list (`GuardEffectNarratives`); nil when the extension works.
    var reasonCode: String? {
        switch self {
        case .active: return nil
        case .waitingForApproval: return "es_not_approved"
        case .waitingForReboot: return "es_reboot"
        case .needsFullDiskAccess: return "es_fda"
        case .notEntitled: return "es_entitlement"
        case .tooManyClients: return "es_clients"
        case .failed: return "es_failed"
        case .notRunning: return "es_not_active"
        }
    }

    /// Every reason code the extension can show (the cases that are not `active`).
    static let allReasonCodes: Set<String> = Set(allCases.compactMap(\.reasonCode))

    static let defaultsKeyPrefix = "RoamSwitch.ESEnforcementV2."
    static let freshSecs: Double = 180

    /// The app writes its reading for one client for the MCP server (a separate process that cannot ask the system
    /// extension manager). One record per purpose: the extension is shared, the clients are not.
    static func write(_ value: ESEnforcement, purpose: String, now: Double, defaults: UserDefaults = .standard) {
        defaults.set(["state": value.rawValue, "at": now] as [String: Any], forKey: defaultsKeyPrefix + purpose)
    }

    static func read(purpose: String, defaults: UserDefaults, now: Double) -> ESEnforcement? {
        guard let record = defaults.dictionary(forKey: defaultsKeyPrefix + purpose), let raw = record["state"] as? String,
              let value = ESEnforcement(rawValue: raw), let at = record["at"] as? Double,
              now - at <= freshSecs, at - now <= freshSecs else { return nil }
        return value
    }
}

/// The system's answer to the app's request to install the extension (`OSSystemExtensionRequest`).
enum ESActivation: String, Codable, Equatable {
    case notRequested, activating, needsUserApproval, willCompleteAfterReboot, activated, failed
}

enum ESHealth {
    /// Combines the system's answer with what the extension reported. A report that is not fresh counts for nothing
    /// (the extension may have been stopped or removed since).
    ///
    /// - Parameter purpose: the client the caller needs. Its own result decides (Full Disk Access is only needed once a
    ///   client is wanted, so a client that is not wanted is `notRunning`, not `needsFullDiskAccess`). With none, a fresh
    ///   report of the extension is all it takes.
    static func resolve(activation: ESActivation, status: ESExtensionStatus?, now: Double, purpose: String?) -> ESEnforcement {
        switch activation {
        case .notRequested, .activating: return .notRunning
        case .needsUserApproval: return .waitingForApproval
        case .willCompleteAfterReboot: return .waitingForReboot
        case .failed: return .failed
        case .activated: break
        }
        guard let status, status.isFresh(now: now) else { return .notRunning }
        guard let purpose else { return .active }
        guard let c = status.client(purpose) else { return .notRunning }
        switch c.result {
        case .success: return c.subscribed ? .active : .failed
        case .notAttempted: return .notRunning
        case .notPermitted: return .needsFullDiskAccess
        case .notEntitled: return .notEntitled
        case .tooManyClients: return .tooManyClients
        case .invalidArgument, .internalError, .notPrivileged: return .failed
        }
    }
}

// MARK: - Reading the report

enum ESStatusFile {
    /// What the extension last reported, if the file can be believed: a regular file owned by root that nobody else can
    /// write, in a folder that is root's and not writable by others. Anything else is not read.
    static func read(path: String = ESExtensionFiles.statusPath, dir: String = ESExtensionFiles.stateDir) -> ESExtensionStatus? {
        var d = stat(), f = stat()
        guard lstat(dir, &d) == 0, (d.st_mode & S_IFMT) == S_IFDIR, d.st_uid == 0, (d.st_mode & 0o022) == 0 else { return nil }
        guard lstat(path, &f) == 0, ESStateFileTrust.isTrustedFile(uid: f.st_uid, mode: UInt32(f.st_mode)) else { return nil }
        guard let data = FileManager.default.contents(atPath: path) else { return nil }
        return ESExtensionStatus.decode(data)
    }

    /// The client `purpose` is created, subscribed and reported a moment ago.
    static func isClientRunning(_ purpose: String, status: ESExtensionStatus?, now: Double) -> Bool {
        guard let status, status.isFresh(now: now), let c = status.client(purpose) else { return false }
        return c.result == .success && c.subscribed
    }
}

/// `ESStatusFile.isClientRunning` for a caller that asks often (the helper's frozen-process watch asks at every
/// pass): the file is read at most once per `ttl` seconds.
final class ESClientRunningProbe {
    private let purpose: String
    private let ttl: TimeInterval
    private let read: () -> ESExtensionStatus?
    private let lock = NSLock()
    private var checkedAt: TimeInterval = -1_000_000
    private var value = false

    init(purpose: String, ttl: TimeInterval = 2, read: @escaping () -> ESExtensionStatus? = { ESStatusFile.read() }) {
        self.purpose = purpose; self.ttl = ttl; self.read = read
    }

    /// `monotonic` and `wall` are seconds (system uptime, and the Unix epoch the extension writes).
    func isRunning(monotonic: TimeInterval = ProcessInfo.processInfo.systemUptime, wall: Double = Date().timeIntervalSince1970) -> Bool {
        lock.lock(); defer { lock.unlock() }
        if monotonic - checkedAt >= ttl || monotonic < checkedAt {
            value = ESStatusFile.isClientRunning(purpose, status: read(), now: wall)
            checkedAt = monotonic
        }
        return value
    }
}
