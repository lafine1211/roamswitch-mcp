// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.8.3 (build 50).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Fingerprints the current network by the MAC address of its default
/// gateway. Chosen over Wi-Fi SSID/BSSID (CoreWLAN) because gateway lookup
/// works for both Wi-Fi and Ethernet and needs no Location Services
/// authorization.
enum GatewayFingerprint {
    /// Interface-name prefixes that are tunnels, not the physical LAN. A VPN
    /// (WireGuard, or a Tailscale exit node) makes `route get default` point at
    /// one of these, which would make RoamSwitch think it left the trusted
    /// network. Fingerprinting must stay anchored to the physical gateway.
    private static let tunnelPrefixes = ["utun", "ipsec", "ppp", "tap", "wg", "gpd", "tun"]

    /// Physical link interfaces to probe for a DHCP router, in priority order.
    private static let physicalIfaces = (0..<8).map { "en\($0)" }

    static func currentGatewayIPAddress() -> String? {
        // Primary source: the DHCP-assigned router on a physical interface
        // (`ipconfig getoption`). This comes from the DHCP lease, so it's
        // rock-stable — a VPN churning the routing table (a Tailscale exit node
        // coming up or being torn down removes/re-adds the physical `default`
        // route for ~20s) never affects it. Only interfaces that actually have
        // an IPv4 address are considered.
        for iface in physicalIfaces {
            guard let addr = runShell("/usr/sbin/ipconfig", ["getifaddr", iface])?
                .trimmingCharacters(in: .whitespacesAndNewlines), !addr.isEmpty else { continue }
            if let r = runShell("/usr/sbin/ipconfig", ["getoption", iface, "router"])?
                .trimmingCharacters(in: .whitespacesAndNewlines), r.contains(".") {
                return r
            }
        }

        // Fallback 1: the physical `default` route from `netstat -rn` — skip
        // tunnel interfaces and the blackhole (`!`) bridge routes.
        if let ns = runShell("/usr/sbin/netstat", ["-rn", "-f", "inet"]) {
            for line in ns.split(separator: "\n") {
                let f = line.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
                guard f.count >= 4, f[0] == "default" else { continue }
                let iface = f.first(where: { $0.rangeOfCharacter(from: .letters) != nil && $0 != "default" && !$0.hasPrefix("link#") && $0 != "UGScg" }) ?? (f.last ?? "")
                if tunnelPrefixes.contains(where: iface.hasPrefix) || iface.hasPrefix("bridge") { continue }
                let gw = f[1]
                if gw.contains(".") { return gw }
            }
        }
        // Fallback 2: `route get default`, but reject a tunnel interface.
        guard let output = runShell("/sbin/route", ["-n", "get", "default"]) else { return nil }
        var gateway: String?
        var iface: String?
        for line in output.split(separator: "\n") {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("gateway:") { gateway = t.replacingOccurrences(of: "gateway:", with: "").trimmingCharacters(in: .whitespaces) }
            if t.hasPrefix("interface:") { iface = t.replacingOccurrences(of: "interface:", with: "").trimmingCharacters(in: .whitespaces) }
        }
        if let iface, tunnelPrefixes.contains(where: iface.hasPrefix) { return nil }
        return gateway
    }

    static func currentGatewayMACAddress() -> String? {
        guard let gatewayIP = currentGatewayIPAddress() else { return nil }

        // A VPN (Tailscale exit node) coming up churns the routing table and can
        // briefly empty the ARP entry for the LAN gateway. That's not "left the
        // network" — retry a couple of times before giving up, so AppState
        // doesn't flip to the away/lockdown level over a transient.
        for attempt in 0..<3 {
            if attempt > 0 { Thread.sleep(forTimeInterval: 0.4) }
            _ = runShell("/sbin/ping", ["-c", "1", "-t", "1", gatewayIP])
            if let output = runShell("/usr/sbin/arp", ["-n", gatewayIP]),
               let mac = parseMACAddress(fromArpOutput: output) {
                return mac
            }
        }
        return nil
    }

    static func parseMACAddress(fromArpOutput output: String) -> String? {
        // Example: "192.168.1.1 (192.168.1.1) at a1:b2:c3:d4:e5:f6 on en0 ifscope [ethernet]"
        guard let range = output.range(
            of: #"at ([0-9a-fA-F]{1,2}:){5}[0-9a-fA-F]{1,2}"#,
            options: .regularExpression
        ) else {
            return nil
        }
        return String(output[range])
            .replacingOccurrences(of: "at ", with: "")
            .lowercased()
    }

    private static func runShell(_ launchPath: String, _ arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return nil
        }
        process.waitUntilExit()

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }
}
