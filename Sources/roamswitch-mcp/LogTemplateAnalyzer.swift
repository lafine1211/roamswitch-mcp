// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.15 (build 72).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// A log template flagged as anomalous by `LogTemplateAnalyzer.analyze`
/// (either never seen before, relative to the persisted baseline, or a
/// statistical frequency outlier within the current audit run). Mirrors
/// `TemplateAnomalySummary` in roamswitch-linux's `models.rs`.
public struct LogTemplateAnomaly: Codable, Identifiable, Equatable {
    public var id: String { template }
    public let template: String
    public let example: String
    public let count: Int
    public let zScore: Double
    public let isNew: Bool
    /// How many runs (including this one) `template` has now been observed
    /// in, and whether that's enough to trust its own historical baseline
    /// rather than a same-run cross-template comparison. Lets a reader
    /// distinguish "still learning this pattern's normal frequency" from
    /// "this deviates from an already-established baseline".
    public let ownHistoryObservations: Int
    public let ownHistoryMature: Bool
}

/// Running per-template frequency baseline — "how many times has this
/// template historically appeared per audit run" — updated incrementally
/// with Welford's online algorithm (no need to retain a full time series).
/// Mirrors `TemplateFrequencyStats` in roamswitch-linux's `log_template.rs`;
/// see that file's doc comment for the full rationale (a recurring-but-
/// legitimate pattern, e.g. a daily cron job, should stop being flagged once
/// its typical volume is learned, instead of re-alerting forever just
/// because it looks bursty relative to whatever else happened to log that
/// hour).
public struct TemplateFrequencyStats: Codable, Equatable {
    public var observations: Int = 0
    public var mean: Double = 0
    /// Sum of squared differences from the running mean (Welford's `M2`).
    public var m2: Double = 0

    mutating func update(_ newCount: Double) {
        observations += 1
        let delta = newCount - mean
        mean += delta / Double(observations)
        let delta2 = newCount - mean
        m2 += delta * delta2
    }

    func stddev(floor: Double) -> Double {
        max((m2 / Double(observations)).squareRoot(), floor)
    }

    /// Z-score of `count` against this template's own history, once there's
    /// enough of it to trust (`LogTemplateAnalyzer.minObservationsForOwnBaseline`).
    func zScore(count: Int, minObservations: Int, stddevFloor: Double) -> Double? {
        guard observations >= minObservations else { return nil }
        return (Double(count) - mean) / stddev(floor: stddevFloor)
    }
}

/// Groups `SecurityLogEvent.message` values into templates by masking their
/// variable parts (IPv4 addresses, long hex/hash-like tokens, bare numbers),
/// then flags templates that are either never-before-seen (relative to a
/// persisted baseline) or a statistical frequency outlier within this run.
///
/// A full Drain-style prefix tree is unnecessary at the volumes a single
/// audit run sees (at most a few hundred events); a plain dictionary keyed
/// by the masked template string is sufficient.
public enum LogTemplateAnalyzer {
    private static let ipv4Regex = try! NSRegularExpression(pattern: #"\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"#)
    private static let hexRegex = try! NSRegularExpression(pattern: #"\b[0-9a-fA-F]{8,}\b"#)
    private static let numRegex = try! NSRegularExpression(pattern: #"\b\d+\b"#)

    /// Minimum occurrences within a single run before a frequency spike is
    /// considered meaningful.
    private static let minSpikeCount = 3
    /// Same Z-score threshold used by the local-LLM log pipeline that
    /// inspired this feature (note.com/aoi_localai).
    private static let zScoreThreshold = 3.0
    private static let maxAnomalies = 10
    /// How many prior runs a template needs before its own history
    /// (`TemplateFrequencyStats`) is trusted for spike-scoring. Below this,
    /// a template falls back to the cross-template comparison below, same
    /// as before per-template history existed, so a genuinely new attack
    /// pattern is never under-covered during its first few sightings.
    public static let minObservationsForOwnBaseline = 3
    /// Floor on a template's own historical stddev, so a template that has
    /// happened at *exactly* the same count on every prior run (stddev == 0)
    /// doesn't turn a trivial +/-1 fluctuation into a division-by-near-zero,
    /// infinite-looking z-score.
    private static let minOwnStddev = 1.0

    /// `message` is expected to already be timestamp-free (as
    /// `SecurityLogEvent.message` is, unlike Linux's raw journalctl lines).
    public static func extractTemplate(_ message: String) -> String {
        func replace(_ regex: NSRegularExpression, in text: String, with template: String) -> String {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: template)
        }
        var result = replace(ipv4Regex, in: message, with: "<IP>")
        result = replace(hexRegex, in: result, with: "<HEX>")
        result = replace(numRegex, in: result, with: "<NUM>")
        return result
    }

    /// A template's own history is used for the frequency check once it has
    /// enough observations (`minObservationsForOwnBaseline`) — this is what
    /// lets a recurring-but-legitimate pattern stop being flagged once its
    /// typical volume is learned. A template still building up history
    /// instead falls back to a cross-template comparison (this run's other
    /// template counts), the same method used before per-template history
    /// existed.
    public static func analyze(
        messages: [String],
        knownTemplates: Set<String>,
        baselineCaptured: Bool,
        frequencyHistory: [String: TemplateFrequencyStats]
    ) -> (anomalies: [LogTemplateAnomaly], updatedKnown: Set<String>, updatedHistory: [String: TemplateFrequencyStats]) {
        var counts: [String: (count: Int, example: String)] = [:]
        for message in messages where !message.trimmingCharacters(in: .whitespaces).isEmpty {
            let template = extractTemplate(message)
            if var entry = counts[template] {
                entry.count += 1
                counts[template] = entry
            } else {
                counts[template] = (1, message)
            }
        }

        var updatedKnown = knownTemplates
        var updatedHistory = frequencyHistory
        for (template, entry) in counts {
            updatedKnown.insert(template)
            var stats = updatedHistory[template] ?? TemplateFrequencyStats()
            stats.update(Double(entry.count))
            updatedHistory[template] = stats
        }

        // Cross-template comparison (this run's own distribution of
        // counts), used as a fallback only for templates whose own history
        // isn't mature yet.
        let total = counts.values.reduce(0) { $0 + $1.count }
        let crossMean = Double(total) / Double(max(counts.count, 1))
        let crossVariance = counts.values.reduce(0.0) { acc, entry in
            let d = Double(entry.count) - crossMean
            return acc + d * d
        } / Double(max(counts.count, 1))
        let crossStddev = crossVariance.squareRoot()

        var anomalies: [LogTemplateAnomaly] = counts.compactMap { template, entry in
            let ownZScore = frequencyHistory[template]?.zScore(
                count: entry.count,
                minObservations: minObservationsForOwnBaseline,
                stddevFloor: minOwnStddev
            )
            let zScore = ownZScore ?? (crossStddev > 0 ? (Double(entry.count) - crossMean) / crossStddev : 0)
            let isNew = baselineCaptured && !knownTemplates.contains(template)
            let isSpike = entry.count >= minSpikeCount && zScore > zScoreThreshold
            guard isNew || isSpike else { return nil }
            let observations = updatedHistory[template]?.observations ?? 0
            let isMature = observations >= minObservationsForOwnBaseline
            return LogTemplateAnomaly(
                template: template, example: entry.example, count: entry.count, zScore: zScore, isNew: isNew,
                ownHistoryObservations: observations, ownHistoryMature: isMature
            )
        }

        anomalies.sort { $0.zScore > $1.zScore }
        if anomalies.count > maxAnomalies {
            anomalies = Array(anomalies.prefix(maxAnomalies))
        }
        return (anomalies, updatedKnown, updatedHistory)
    }

    // MARK: - Baseline persistence (UserDefaults, mirroring PortAnomalyGuard.swift)

    private static let knownTemplatesKey = "RoamSwitch.LogTemplateBaseline.KnownTemplatesV1"
    private static let baselineCapturedKey = "RoamSwitch.LogTemplateBaseline.BaselineCapturedV1"
    /// New key (frequency history didn't exist in V1) — a host upgrading
    /// from an older build with no value here just starts learning fresh
    /// via the `?? [:]` fallback below, no migration needed.
    private static let frequencyHistoryKey = "RoamSwitch.LogTemplateBaseline.FrequencyHistoryV1"
    /// The raw text of the most recent log message fed into `analyze` on
    /// the previous run. `ScheduledLogAuditGuard`'s scan interval and audit
    /// window are the same length (1 hour each), so consecutive scheduled
    /// runs nearly abut rather than deliberately double-overlapping like
    /// the Linux daemons' rounded-up window — but the very first kickoff
    /// scan (10s after enabling) landing close to the first regular-interval
    /// scan, or any timer drift across a sleep/wake cycle, can still
    /// re-present the same historical burst inside two consecutive windows.
    /// Left unfiltered, that burst gets re-counted into the frequency
    /// baseline and re-alerted every time it's still in view — mirrors
    /// `LogTemplateBaseline::last_processed_line` in roamswitch-linux's
    /// `log_auditor.rs`, found 2026-09-10 from the same failure mode
    /// observed live on the Linux side first.
    private static let lastProcessedMessageKey = "RoamSwitch.LogTemplateBaseline.LastProcessedMessageV1"

    public static func loadBaseline() -> (known: Set<String>, captured: Bool, frequencyHistory: [String: TemplateFrequencyStats], lastProcessedMessage: String?) {
        let captured = UserDefaults.standard.bool(forKey: baselineCapturedKey)
        let known: Set<String>
        if let data = UserDefaults.standard.data(forKey: knownTemplatesKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            known = Set(decoded)
        } else {
            known = []
        }
        let history: [String: TemplateFrequencyStats]
        if let data = UserDefaults.standard.data(forKey: frequencyHistoryKey),
           let decoded = try? JSONDecoder().decode([String: TemplateFrequencyStats].self, from: data) {
            history = decoded
        } else {
            history = [:]
        }
        let lastProcessedMessage = UserDefaults.standard.string(forKey: lastProcessedMessageKey)
        return (known, captured, history, lastProcessedMessage)
    }

    public static func saveBaseline(known: Set<String>, frequencyHistory: [String: TemplateFrequencyStats], lastProcessedMessage: String?) {
        if let data = try? JSONEncoder().encode(Array(known)) {
            UserDefaults.standard.set(data, forKey: knownTemplatesKey)
        }
        if let data = try? JSONEncoder().encode(frequencyHistory) {
            UserDefaults.standard.set(data, forKey: frequencyHistoryKey)
        }
        UserDefaults.standard.set(true, forKey: baselineCapturedKey)
        if let lastProcessedMessage {
            UserDefaults.standard.set(lastProcessedMessage, forKey: lastProcessedMessageKey)
        }
    }

    /// Returns the slice of `chronological` strictly after `cursor` (the
    /// previous run's last-processed item — a message string in
    /// `SecurityLogAuditor`'s real use, but generic here so the slicing
    /// logic itself is unit-testable without needing a real
    /// `SecurityLogEvent`), assuming the input is already oldest-first. If
    /// `cursor` is `nil` (first run) or isn't found (it aged out of the
    /// window entirely — a scan was missed for longer than the window
    /// covers), the whole array is returned rather than silently seeing
    /// nothing.
    public static func itemsSinceCursor<T: Equatable>(_ chronological: [T], cursor: T?) -> [T] {
        guard let cursor, let idx = chronological.lastIndex(of: cursor) else {
            return chronological
        }
        return Array(chronological[(idx + 1)...])
    }
}
