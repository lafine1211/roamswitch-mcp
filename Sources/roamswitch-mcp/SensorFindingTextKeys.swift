// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.33 (build 212).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Which roamswitch-core check wrote a Sensor finding's texts — `roamswitch-sensor`'s `FindingTextKeys`
/// (`sensor-core::scan_history`), sent in PullResult as each finding's `text_keys`. The Sensor writes the texts of
/// an audit this Mac requested in English; with these keys the app shows them in its own display language
/// (`SensorFindingTexts.render`). Absent from an older Sensor's findings and from texts no key gives back, which are
/// shown as the Sensor wrote them.
public struct SensorFindingTextKeys: Codable, Equatable {
    /// `signature` (a service signature: `check` is its id), `web` (a `webvuln-*` check) or `cve` (an entry of
    /// roamswitch-core's known-CVE table: `check` is the CVE id, `args["signature"]` the signature whose version matched).
    public let source: String
    public let check: String
    /// What the texts take besides the check (`cve`: `signature`). Empty for a signature or a web check.
    public let args: [String: String]

    /// Longer than any check of roamswitch-core is not one (the Sensor's `TEXT_KEY_MAX_CHARS`).
    public static let maxChars = 64
    /// More arguments than any key takes (roamswitch-core's `TEXT_KEY_MAX_ARGS`).
    public static let maxArgs = 4

    public init(source: String, check: String, args: [String: String] = [:]) {
        self.source = source
        self.check = check
        self.args = args
    }

    private enum CodingKeys: String, CodingKey { case source, check, args }

    /// `args` is optional in what is stored, so a record written before it reads the same, and a key with no
    /// arguments is written as it was.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        source = try c.decode(String.self, forKey: .source)
        check = try c.decode(String.self, forKey: .check)
        args = try c.decodeIfPresent([String: String].self, forKey: .args) ?? [:]
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(source, forKey: .source)
        try c.encode(check, forKey: .check)
        if !args.isEmpty { try c.encode(args, forKey: .args) }
    }

    /// The keys of one PullResult finding (`dict["text_keys"]`), or `nil` when there are none or they are not of
    /// this shape: `args`, when present and not empty, is an object of at most `maxArgs` strings, names and values
    /// no longer than `maxChars`. Whether this build can render them is `SensorFindingTexts.render`'s question.
    public init?(wire value: Any?) {
        guard let obj = value as? [String: Any],
              let source = obj["source"] as? String, let check = obj["check"] as? String,
              !source.isEmpty, !check.isEmpty,
              source.count <= Self.maxChars, check.count <= Self.maxChars else { return nil }
        var args: [String: String] = [:]
        if let raw = obj["args"], !(raw is NSNull) {
            if let list = raw as? [Any], list.isEmpty {
                // no arguments
            } else if let map = raw as? [String: Any] {
                guard map.count <= Self.maxArgs else { return nil }
                for (name, value) in map {
                    guard let value = value as? String, !name.isEmpty, name.count <= Self.maxChars,
                          value.count <= Self.maxChars else { return nil }
                    args[name] = value
                }
            } else {
                return nil
            }
        }
        self.source = source
        self.check = check
        self.args = args
    }
}
