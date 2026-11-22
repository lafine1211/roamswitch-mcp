// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.2.5 (build 229).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// What a guard that reads `partial` only because input was lost within the last day can say about it: when the last loss was, and how
/// much was lost in all. `partial` is a fact (the guard may have missed an event in that time) and stays one; this only tells a reader
/// what it is, instead of the bare word.
public enum GuardInputLoss {
    /// `liveStateReason` of such a guard.
    public static let reasonCode = "input_lost_recently"

    /// The newest loss of the guard's readers (a gap, or lines dropped), within `GuardReaderHealthStore.gapWindowSecs` of `now`; nil when none.
    public static func lastLossAt(forGuard key: String, records: [String: GuardReaderHealth], now: Double) -> Double? {
        let times = GuardReaderHealthStore.sourceIDs(forGuard: key).compactMap { records[$0] }.flatMap { h in [h.lastGapAt, h.lastDropAt].compactMap { $0 } }
        guard let last = times.max(), now - last <= GuardReaderHealthStore.gapWindowSecs else { return nil }
        return last
    }

    /// An English sentence (it is for an LLM that reads `get_guard_status`); nil when the guard has no recent loss to name.
    public static func summary(forGuard key: String, records: [String: GuardReaderHealth], now: Double) -> String? {
        guard let last = lastLossAt(forGuard: key, records: records, now: now) else { return nil }
        let readers = GuardReaderHealthStore.sourceIDs(forGuard: key).compactMap { records[$0] }
        let dropped = readers.compactMap(\.linesDropped).reduce(0, +)
        let gaps = readers.map(\.gaps).reduce(0, +)
        let minutes = max(0, Int((now - last) / 60))
        let iso = ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: last))
        var text = "Input was lost within the last 24 hours: the last loss was at \(iso) (\(minutes) minutes ago)."
        if dropped > 0 { text += " Lines dropped in all since the counter began: \(dropped)." }
        if gaps > 0 { text += " Interruptions in all: \(gaps)." }
        text += " The guard may have missed an event in the lost time. It reads on again after 24 hours without a new loss."
        return text
    }
}
