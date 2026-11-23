// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.2.6 (build 230).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

// What the Endpoint Security extension counts when it loses events, and how the app turns it into the reader-health records
// that `get_guard_status` shows. The extension writes the counters into `esclient/status.json` (`ESClientStatus`); until this
// existed nothing read them, so the kernel could drop events, or the extension's queue overflow, and every guard stayed `on`.
//
// What is read, per client of the extension:
//  - `droppedEvents`: events the kernel dropped for the client (a gap in `seq_num`). A loss of that many events and one gap.
//  - `<stream>.droppedQueueFull`: lines the extension's writer dropped because its queue was full. A loss of that many.
//  - `<stream>.writeErrors`: writes that failed, each losing a batch of unknown size. A gap, no count.
//  - `muteOverflow` (the narrow clients): more paths than the kernel takes, so some were left out. Part of what the guards should
//    watch is not delivered: `scopeLimited`. `muteRefused` (a `contains` pattern with no coarse prefix) is not read: the guards
//    register only exact and prefix patterns, so it belongs to another watch (the file-actor recorder) and would mark guards
//    that lost nothing.
//  - `received`: not a loss. It only tells that the extension started over (the count went back), so the baseline is reset
//    and a restart is not read as a negative number.
// Not read, with the reason: `ESSequenceGapCounter.droppedByType` stays inside the extension (it is a finer cut of the same
// drops and is not in the status file); `rotations`, `submitted` and `written` are throughput, not loss; `received` is not
// used as proof of life, because a quiet client (system events on an idle Mac) is healthy with no message for hours.

/// The counters of one client, summed over the streams it writes.
struct ESClientCounters: Equatable, Codable {
    var received: UInt64 = 0
    var droppedEvents: UInt64 = 0
    var droppedQueueFull: UInt64 = 0
    var writeErrors: UInt64 = 0
    var muteRefused: UInt64 = 0
    var muteOverflow: UInt64 = 0

    init() {}

    init(_ c: ESClientStatus) {
        received = c.received
        droppedEvents = c.droppedEvents
        muteRefused = c.extra["muteRefused"] ?? 0
        muteOverflow = c.extra["muteOverflow"] ?? 0
        for (k, v) in c.extra {
            if k.hasSuffix(".droppedQueueFull") { droppedQueueFull &+= v }
            else if k.hasSuffix(".writeErrors") { writeErrors &+= v }
        }
    }
}

/// What changed for one client since the last reading.
struct ESLossDelta: Equatable {
    /// Events or lines lost since the last reading.
    var events: UInt64 = 0
    /// Failed writes since the last reading (each lost a batch of unknown size).
    var writeErrors: UInt64 = 0
    /// Whether the client's watches are not fully delivered now (nil: not a client that mutes).
    var scopeLimited: Bool?
    /// The extension started over: the counters went back, so this reading is the new baseline and adds nothing.
    var restarted = false

    var hasLoss: Bool { events > 0 || writeErrors > 0 }
}

enum ESDropAccounting {
    /// The reader-health record of each client of the extension that delivers events to a guard.
    static let sourceByPurpose: [String: String] = [
        ESPurpose.processEvents: "esClientProcessEvents",
        ESPurpose.systemEvents: "esClientSystemEvents",
        ESPurpose.pathWatchBroad: "esClientPathBroad",
        ESPurpose.pathWatchNarrow: "esClientPathNarrow",
        ESPurpose.pathWatchClose: "esClientPathClose",
    ]

    /// The loss between two readings. `previousPID` is the extension process the previous reading came from.
    static func delta(previous: ESClientCounters?, previousPID: Int32?, current: ESClientCounters, currentPID: Int32) -> ESLossDelta {
        var d = ESLossDelta()
        d.scopeLimited = current.muteOverflow > 0
        guard let previous else { return d }
        // A different process, or a count that went back: the extension started over. Its own start is not a loss in its stream.
        if previousPID != currentPID || current.received < previous.received || current.droppedEvents < previous.droppedEvents {
            d.restarted = true
            return d
        }
        d.events = (current.droppedEvents - previous.droppedEvents)
            &+ (current.droppedQueueFull >= previous.droppedQueueFull ? current.droppedQueueFull - previous.droppedQueueFull : 0)
        d.writeErrors = current.writeErrors >= previous.writeErrors ? current.writeErrors - previous.writeErrors : 0
        return d
    }

    /// The records of the clients that deliver events to the guard (empty for a guard that does not use the extension). The path
    /// guards share the broad and close clients, the credential guards the narrow one; the system-events guards and the
    /// process-event guards each share one client. A loss in a client marks every guard that reads it: the extension cannot say
    /// whose events were dropped.
    static let clientSourcesByGuard: [String: [String]] = {
        let broadClose = ["esClientPathBroad", "esClientPathClose"]
        var t: [String: [String]] = [:]
        for g in ["credentialFileWatchGuard", "browserCredentialWatchGuard", "credentialHoneytokenGuard"] {
            t[g] = ["esClientPathNarrow", "esGuardStream"]
        }
        for g in ["logTamperWatchGuard", "criticalPathFim", "lockfileTamperGuard", "persistenceMonitor", "ransomwareCanaryGuard",
                  "ransomwareEntropyGuard", "webMailDownloadGuard", "agentSetupWatch", "webRulesFolderScan"] {
            t[g] = broadClose + ["esGuardStream"]
        }
        // The system-events client also feeds the BTM check of the persistence monitor, the SSH guard and XProtect.
        t["persistenceMonitor"]! += ["esClientSystemEvents"]
        for g in ["esAccountWatch", "esInjectionWatch", "esQuarantineWatch", "sshGuard", "runtimeThreatContainment"] {
            t[g] = (t[g] ?? []) + ["esClientSystemEvents"]
        }
        for g in ["execRecorder", "reverseShellWatch", "dockerEventGuard", "webWorkerCrashWatch"] {
            t[g] = (t[g] ?? []) + ["esClientProcessEvents"]
        }
        return t
    }()
}

/// One recorder per reader-health source for the whole process. Two recorders over one source would each write their own copy of
/// the record over the other's; the readers of the system-events client (the drop watch and the hub) share this one.
enum ESLossRecorders {
    private static let lock = NSLock()
    private static var byID: [String: GuardReaderHealthRecorder] = [:]

    static func recorder(_ source: String) -> GuardReaderHealthRecorder {
        lock.lock(); defer { lock.unlock() }
        if let r = byID[source] { return r }
        let r = GuardReaderHealthRecorder.forApp(source: source)
        byID[source] = r
        return r
    }
}

/// Keeps what the last reading of the extension's counters was, across restarts of the app (so what the extension lost while the
/// app was not running is counted at the next start), and writes the losses into the reader-health records.
final class ESDropWatch {
    static let defaultsKey = "RoamSwitch.ESDropBaselineV1"

    private struct Baseline: Codable, Equatable {
        var pid: Int32
        var counters: ESClientCounters
    }

    private let defaults: UserDefaults
    private let recorder: (String) -> GuardReaderHealthRecorder
    private var recorders: [String: GuardReaderHealthRecorder] = [:]
    private let lock = NSLock()

    init(defaults: UserDefaults = .standard,
         recorder: @escaping (String) -> GuardReaderHealthRecorder = { ESLossRecorders.recorder($0) }) {
        self.defaults = defaults
        self.recorder = recorder
    }

    private func baselines() -> [String: Baseline] {
        guard let data = defaults.data(forKey: Self.defaultsKey),
              let b = try? JSONDecoder().decode([String: Baseline].self, from: data) else { return [:] }
        return b
    }

    /// One reading of the extension's report. A report that is not fresh is not read (the extension is not running; that is
    /// `ESEnforcement.notRunning`, a different notice).
    func poll(status: ESExtensionStatus?, now: Double = Date().timeIntervalSince1970) {
        guard let status, status.isFresh(now: now) else { return }
        lock.lock(); defer { lock.unlock() }
        var known = baselines()
        for c in status.clients {
            guard let source = ESDropAccounting.sourceByPurpose[c.purpose] else { continue }
            let counters = ESClientCounters(c)
            let before = known[c.purpose]
            let d = ESDropAccounting.delta(previous: before?.counters, previousPID: before?.pid, current: counters, currentPID: status.pid)
            known[c.purpose] = Baseline(pid: status.pid, counters: counters)
            let rec: GuardReaderHealthRecorder
            if let r = recorders[source] { rec = r } else { rec = recorder(source); recorders[source] = rec }
            if d.hasLoss {
                rec.update(now: now, force: true) { h, t in h.recordLoss(events: d.events, now: t) }
            }
            if let limited = d.scopeLimited, rec.snapshot.scopeLimited != limited, limited || rec.snapshot.scopeLimited != nil {
                rec.update(now: now, force: true) { h, t in h.setScopeLimited(limited, now: t) }
            }
        }
        if let data = try? JSONEncoder().encode(known) { defaults.set(data, forKey: Self.defaultsKey) }
    }
}
