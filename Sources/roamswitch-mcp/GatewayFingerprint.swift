// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.5.9 (build 32).
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
    static func currentGatewayIPAddress() -> String? {
        guard let output = runShell("/sbin/route", ["-n", "get", "default"]) else { return nil }
        for line in output.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("gateway:") {
                return trimmed
                    .replacingOccurrences(of: "gateway:", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    static func currentGatewayMACAddress() -> String? {
        guard let gatewayIP = currentGatewayIPAddress() else { return nil }

        // Nudge the ARP cache in case the entry is missing or stale; ignore
        // failures, arp below will simply come back empty in that case.
        _ = runShell("/sbin/ping", ["-c", "1", "-t", "1", gatewayIP])

        guard let output = runShell("/usr/sbin/arp", ["-n", gatewayIP]) else { return nil }
        return parseMACAddress(fromArpOutput: output)
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
