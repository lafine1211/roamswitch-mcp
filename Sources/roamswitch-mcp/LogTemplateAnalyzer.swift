// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.3 (build 60).
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

    public static func analyze(
        messages: [String],
        knownTemplates: Set<String>,
        baselineCaptured: Bool
    ) -> (anomalies: [LogTemplateAnomaly], updatedKnown: Set<String>) {
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
        for template in counts.keys {
            updatedKnown.insert(template)
        }

        guard counts.count >= 2 else {
            let anomalies: [LogTemplateAnomaly] = baselineCaptured
                ? counts.filter { !knownTemplates.contains($0.key) }.map {
                    LogTemplateAnomaly(template: $0.key, example: $0.value.example, count: $0.value.count, zScore: 0, isNew: true)
                }
                : []
            return (anomalies, updatedKnown)
        }

        let total = counts.values.reduce(0) { $0 + $1.count }
        let mean = Double(total) / Double(counts.count)
        let variance = counts.values.reduce(0.0) { acc, entry in
            let d = Double(entry.count) - mean
            return acc + d * d
        } / Double(counts.count)
        let stddev = variance.squareRoot()

        var anomalies: [LogTemplateAnomaly] = counts.compactMap { template, entry in
            let zScore = stddev > 0 ? (Double(entry.count) - mean) / stddev : 0
            let isNew = baselineCaptured && !knownTemplates.contains(template)
            let isSpike = entry.count >= minSpikeCount && zScore > zScoreThreshold
            guard isNew || isSpike else { return nil }
            return LogTemplateAnomaly(template: template, example: entry.example, count: entry.count, zScore: zScore, isNew: isNew)
        }

        anomalies.sort { $0.zScore > $1.zScore }
        if anomalies.count > maxAnomalies {
            anomalies = Array(anomalies.prefix(maxAnomalies))
        }
        return (anomalies, updatedKnown)
    }

    // MARK: - Baseline persistence (UserDefaults, mirroring PortAnomalyGuard.swift)

    private static let knownTemplatesKey = "RoamSwitch.LogTemplateBaseline.KnownTemplatesV1"
    private static let baselineCapturedKey = "RoamSwitch.LogTemplateBaseline.BaselineCapturedV1"

    public static func loadBaseline() -> (known: Set<String>, captured: Bool) {
        let captured = UserDefaults.standard.bool(forKey: baselineCapturedKey)
        guard let data = UserDefaults.standard.data(forKey: knownTemplatesKey),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            return ([], captured)
        }
        return (Set(decoded), captured)
    }

    public static func saveBaseline(known: Set<String>) {
        if let data = try? JSONEncoder().encode(Array(known)) {
            UserDefaults.standard.set(data, forKey: knownTemplatesKey)
        }
        UserDefaults.standard.set(true, forKey: baselineCapturedKey)
    }
}
