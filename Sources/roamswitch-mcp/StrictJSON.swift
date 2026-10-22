// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.16.2 (build 178).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// JSON decoding that refuses a repeated key.
///
/// `JSONDecoder` and `JSONSerialization` keep the LAST value of a repeated key without a word. A state
/// file that anchors trust (an accepted baseline, a list of paired sensors, a file-integrity baseline) could
/// then carry two entries for one path, and the reader would act on whichever came second. `validate` reads
/// the whole text once and throws on a repeated key at any depth, on invalid JSON, and on anything after the
/// first value. `decode` runs it before decoding.
enum StrictJSON {
    enum Failure: Error, Equatable {
        case duplicateKey(String)
        case invalid
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try validate(data)
        return try JSONDecoder().decode(type, from: data)
    }

    static func validate(_ data: Data) throws {
        var p = Parser(bytes: [UInt8](data))
        p.skipSpace()
        try p.value(depth: 0)
        p.skipSpace()
        guard p.index == p.bytes.count else { throw Failure.invalid }
    }

    private struct Parser {
        let bytes: [UInt8]
        var index = 0
        static let maxDepth = 256

        init(bytes: [UInt8]) { self.bytes = bytes }

        mutating func skipSpace() {
            while index < bytes.count, [0x20, 0x09, 0x0A, 0x0D].contains(bytes[index]) { index += 1 }
        }

        mutating func value(depth: Int) throws {
            guard depth <= Parser.maxDepth, index < bytes.count else { throw Failure.invalid }
            switch bytes[index] {
            case UInt8(ascii: "{"): try object(depth: depth)
            case UInt8(ascii: "["): try array(depth: depth)
            case UInt8(ascii: "\""): _ = try string()
            case UInt8(ascii: "t"): try literal("true")
            case UInt8(ascii: "f"): try literal("false")
            case UInt8(ascii: "n"): try literal("null")
            default: try number()
            }
        }

        mutating func object(depth: Int) throws {
            index += 1
            skipSpace()
            var seen = Set<String>()
            if index < bytes.count, bytes[index] == UInt8(ascii: "}") { index += 1; return }
            while true {
                skipSpace()
                guard index < bytes.count, bytes[index] == UInt8(ascii: "\"") else { throw Failure.invalid }
                let key = try string()
                if !seen.insert(key).inserted { throw Failure.duplicateKey(key) }
                skipSpace()
                guard index < bytes.count, bytes[index] == UInt8(ascii: ":") else { throw Failure.invalid }
                index += 1
                skipSpace()
                try value(depth: depth + 1)
                skipSpace()
                guard index < bytes.count else { throw Failure.invalid }
                if bytes[index] == UInt8(ascii: ",") { index += 1; continue }
                if bytes[index] == UInt8(ascii: "}") { index += 1; return }
                throw Failure.invalid
            }
        }

        mutating func array(depth: Int) throws {
            index += 1
            skipSpace()
            if index < bytes.count, bytes[index] == UInt8(ascii: "]") { index += 1; return }
            while true {
                skipSpace()
                try value(depth: depth + 1)
                skipSpace()
                guard index < bytes.count else { throw Failure.invalid }
                if bytes[index] == UInt8(ascii: ",") { index += 1; continue }
                if bytes[index] == UInt8(ascii: "]") { index += 1; return }
                throw Failure.invalid
            }
        }

        /// Reads a string and returns it with escapes resolved, so `"a"` and `"a"` are the same key.
        mutating func string() throws -> String {
            index += 1
            var units: [UInt16] = []
            var run: [UInt8] = []
            func flush() {
                if !run.isEmpty { units.append(contentsOf: Array(String(decoding: run, as: UTF8.self).utf16)); run.removeAll() }
            }
            while index < bytes.count {
                let c = bytes[index]
                if c == UInt8(ascii: "\"") {
                    index += 1
                    flush()
                    return String(decoding: units, as: UTF16.self)
                }
                if c < 0x20 { throw Failure.invalid }
                if c != UInt8(ascii: "\\") { run.append(c); index += 1; continue }
                flush()
                index += 1
                guard index < bytes.count else { throw Failure.invalid }
                switch bytes[index] {
                case UInt8(ascii: "\""): units.append(0x22)
                case UInt8(ascii: "\\"): units.append(0x5C)
                case UInt8(ascii: "/"): units.append(0x2F)
                case UInt8(ascii: "b"): units.append(0x08)
                case UInt8(ascii: "f"): units.append(0x0C)
                case UInt8(ascii: "n"): units.append(0x0A)
                case UInt8(ascii: "r"): units.append(0x0D)
                case UInt8(ascii: "t"): units.append(0x09)
                case UInt8(ascii: "u"):
                    guard index + 4 < bytes.count else { throw Failure.invalid }
                    var v: UInt16 = 0
                    for k in 1...4 {
                        guard let d = Parser.hexValue(bytes[index + k]) else { throw Failure.invalid }
                        v = v << 4 | UInt16(d)
                    }
                    units.append(v)
                    index += 4
                default: throw Failure.invalid
                }
                index += 1
            }
            throw Failure.invalid
        }

        static func hexValue(_ c: UInt8) -> Int? {
            switch c {
            case 0x30...0x39: return Int(c) - 0x30
            case 0x41...0x46: return Int(c) - 0x41 + 10
            case 0x61...0x66: return Int(c) - 0x61 + 10
            default: return nil
            }
        }

        mutating func literal(_ word: String) throws {
            let w = Array(word.utf8)
            guard index + w.count <= bytes.count, Array(bytes[index..<index + w.count]) == w else { throw Failure.invalid }
            index += w.count
        }

        mutating func number() throws {
            let start = index
            if index < bytes.count, bytes[index] == UInt8(ascii: "-") { index += 1 }
            while index < bytes.count, [0x30...0x39, 0x2E...0x2E, 0x65...0x65, 0x45...0x45, 0x2B...0x2B, 0x2D...0x2D].contains(where: { $0.contains(bytes[index]) }) { index += 1 }
            guard index > start, index - start > (bytes[start] == UInt8(ascii: "-") ? 1 : 0) else { throw Failure.invalid }
        }
    }
}
