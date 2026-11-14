// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.0.2 (build 218).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// The address half of `FwdEgress` (destination guard, see `RoamSwitch/FwdEgressGuard.swift`): parsing an address in any
/// notation, the classes of internal addresses and a CIDR. Pure, no localized text, so that every target that needs to
/// classify an address can compile it (the MCP server's `agent-check` does, with `Shared/ExecAgentExfil.swift`).
/// The class labels (`Category.label`) and the policy that uses them stay in `FwdEgressGuard.swift`.
enum FwdEgress {
    // MARK: Addresses

    enum IP: Equatable, CustomStringConvertible {
        case v4([UInt8])
        case v6([UInt8])

        var description: String {
            switch self {
            case .v4(let b): return b.map(String.init).joined(separator: ".")
            case .v6(let b):
                var addr = in6_addr()
                withUnsafeMutableBytes(of: &addr) { raw in for i in 0..<16 { raw[i] = b[i] } }
                var buf = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
                guard inet_ntop(AF_INET6, &addr, &buf, socklen_t(buf.count)) != nil else { return "::" }
                return String(cString: buf)
            }
        }

        /// The form curl's `resolve` and `NWEndpoint.Host` take (IPv6 in brackets for `resolve`).
        var bracketed: String {
            if case .v6 = self { return "[\(description)]" }
            return description
        }
    }

    /// Why an address is internal. Same classes as Linux `Category`.
    enum Category: Equatable {
        case unspecified, loopback, privateRFC1918, linkLocal, cgnat, uniqueLocal, multicast, reserved, metadata
    }

    /// `a.b.c.d`-style host in any form `inet_aton(3)` (and curl) accepts: 1-4 parts, each decimal,
    /// `0x` hex or leading-`0` octal; the last part fills the remaining bytes (`2130706433`,
    /// `0x7f.1`, `0177.0.0.1`, `127.1`). Port of Linux `parse_ipv4_lenient`.
    static func parseIPv4Lenient(_ raw: String) -> [UInt8]? {
        var s = Substring(raw)
        if s.hasSuffix(".") { s = s.dropLast() }
        if s.isEmpty { return nil }
        let parts = s.split(separator: ".", omittingEmptySubsequences: false)
        if parts.count > 4 { return nil }
        var nums: [UInt64] = []
        for p in parts {
            if p.isEmpty { return nil }
            let n: UInt64
            if p.hasPrefix("0x") || p.hasPrefix("0X") {
                let h = p.dropFirst(2)
                if h.isEmpty { n = 0 } else { guard let v = UInt64(h, radix: 16) else { return nil }; n = v }
            } else if p.count > 1 && p.hasPrefix("0") {
                guard let v = UInt64(p.dropFirst(), radix: 8) else { return nil }
                n = v
            } else {
                guard p.allSatisfy({ $0.isASCII && $0.isNumber }), let v = UInt64(p) else { return nil }
                n = v
            }
            nums.append(n)
        }
        guard let last = nums.last else { return nil }
        let head = nums.dropLast()
        var v: UInt64 = 0
        for n in head {
            if n > 255 { return nil }
            v = (v << 8) | n
        }
        let remainingBits = UInt64(8 * (4 - head.count))
        if remainingBits < 64 && last >= (UInt64(1) << remainingBits) { return nil }
        v = (v << remainingBits) | last
        let u = UInt32(truncatingIfNeeded: v)
        return [UInt8(u >> 24), UInt8((u >> 16) & 0xff), UInt8((u >> 8) & 0xff), UInt8(u & 0xff)]
    }

    /// Host text -> IP, including bracketed IPv6, zone ids and the lenient IPv4 forms.
    static func parseHostIP(_ host: String) -> IP? {
        var h = host.trimmingCharacters(in: .whitespaces)
        if h.hasPrefix("[") && h.hasSuffix("]") { h = String(h.dropFirst().dropLast()) }
        if let pct = h.firstIndex(of: "%") { h = String(h[..<pct]) }
        if h.contains(":") {
            var a6 = in6_addr()
            guard inet_pton(AF_INET6, h, &a6) == 1 else { return nil }
            return .v6(withUnsafeBytes(of: &a6) { Array($0) })
        }
        return parseIPv4Lenient(h).map { .v4($0) }
    }

    /// The IPv4 embedded in an IPv6 address (mapped `::ffff:a.b.c.d`, deprecated compatible
    /// `::a.b.c.d`, NAT64 `64:ff9b::/96`, 6to4 `2002::/16`).
    static func embeddedV4(_ o: [UInt8]) -> [UInt8]? {
        let s: [UInt16] = (0..<8).map { UInt16(o[2 * $0]) << 8 | UInt16(o[2 * $0 + 1]) }
        if s[0..<5].allSatisfy({ $0 == 0 }) && s[5] == 0xffff { return Array(o[12..<16]) }
        if s[0..<6].allSatisfy({ $0 == 0 }) && !(s[6] == 0 && s[7] <= 1) { return Array(o[12..<16]) }
        if s[0] == 0x0064 && s[1] == 0xff9b && s[2..<6].allSatisfy({ $0 == 0 }) { return Array(o[12..<16]) }
        if s[0] == 0x2002 { return Array(o[2..<6]) }
        return nil
    }

    private static func isMetadataV4(_ o: [UInt8]) -> Bool {
        o == [169, 254, 169, 254] || o == [169, 254, 170, 2] || o == [100, 100, 100, 200] || o == [192, 0, 0, 192]
    }

    /// `fd00:ec2::254` (AWS IPv6 metadata).
    private static let awsV6Metadata: [UInt8] = [0xfd, 0, 0x0e, 0xc2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x02, 0x54]

    static func isMetadata(_ ip: IP) -> Bool {
        switch ip {
        case .v4(let o): return isMetadataV4(o)
        case .v6(let o):
            if let v4 = embeddedV4(o) { return isMetadataV4(v4) }
            return o == awsV6Metadata
        }
    }

    private static func classifyV4(_ o: [UInt8]) -> Category? {
        if isMetadataV4(o) { return .metadata }
        switch (o[0], o[1], o[2]) {
        case (0, _, _): return .unspecified
        case (127, _, _): return .loopback
        case (10, _, _): return .privateRFC1918
        case (172, 16...31, _): return .privateRFC1918
        case (192, 168, _): return .privateRFC1918
        case (169, 254, _): return .linkLocal
        case (100, 64...127, _): return .cgnat
        case (224...239, _, _): return .multicast
        case (240...255, _, _): return .reserved
        case (192, 0, 0): return .reserved
        case (198, 18, _), (198, 19, _): return .reserved
        default: return nil
        }
    }

    /// The category when the address is internal / not public, `nil` for a routable public address.
    static func classify(_ ip: IP) -> Category? {
        switch ip {
        case .v4(let o): return classifyV4(o)
        case .v6(let o):
            if let v4 = embeddedV4(o) { return classifyV4(v4) }
            if o == awsV6Metadata { return .metadata }
            if o.allSatisfy({ $0 == 0 }) { return .unspecified }
            if o[0..<15].allSatisfy({ $0 == 0 }) && o[15] == 1 { return .loopback }
            let s0 = UInt16(o[0]) << 8 | UInt16(o[1])
            if s0 & 0xfe00 == 0xfc00 { return .uniqueLocal }
            if s0 & 0xffc0 == 0xfe80 || s0 & 0xffc0 == 0xfec0 { return .linkLocal }
            if s0 & 0xff00 == 0xff00 { return .multicast }
            return nil
        }
    }

    // MARK: Allow list

    /// One allow-list entry (`10.1.2.0/24`, `fd00::/8`, or a bare address = /32 | /128).
    struct Cidr: Equatable {
        let net: IP
        let prefix: Int

        static func parse(_ raw: String) -> Cidr? {
            let s = raw.trimmingCharacters(in: .whitespaces)
            let parts = s.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
            guard var ip = FwdEgress.parseHostIP(String(parts[0])) else { return nil }
            var off = 0
            // A mapped IPv6 CIDR is stored as the IPv4 it stands for.
            if case .v6(let o) = ip, o[0..<10].allSatisfy({ $0 == 0 }), o[10] == 0xff, o[11] == 0xff {
                ip = .v4(Array(o[12..<16])); off = 96
            }
            let max: Int
            if case .v4 = ip { max = 32 } else { max = 128 }
            guard parts.count == 2 else { return Cidr(net: ip, prefix: max) }
            let p = parts[1].trimmingCharacters(in: .whitespaces)
            guard !p.isEmpty, p.allSatisfy({ $0.isASCII && $0.isNumber }), let n = Int(p), n - off >= 0, n - off <= max else { return nil }
            return Cidr(net: ip, prefix: n - off)
        }

        func contains(_ ip: IP) -> Bool {
            var ip = ip
            if case .v6(let o) = ip, o[0..<10].allSatisfy({ $0 == 0 }), o[10] == 0xff, o[11] == 0xff { ip = .v4(Array(o[12..<16])) }
            switch (net, ip) {
            case (.v4(let n), .v4(let a)): return Self.prefixEqual(n, a, prefix)
            case (.v6(let n), .v6(let a)): return Self.prefixEqual(n, a, prefix)
            default: return false
            }
        }

        private static func prefixEqual(_ a: [UInt8], _ b: [UInt8], _ prefix: Int) -> Bool {
            var bits = prefix
            for i in 0..<a.count {
                if bits <= 0 { return true }
                let mask: UInt8 = bits >= 8 ? 0xff : UInt8(0xff << (8 - bits) & 0xff)
                if a[i] & mask != b[i] & mask { return false }
                bits -= 8
            }
            return true
        }
    }
}
