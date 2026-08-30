// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.5.3 (build 26).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

public struct ListeningPortInfo: Identifiable, Equatable, Hashable {
    public var id: String { "\(processName):\(port):\(pid)" }
    public let processName: String
    public let pid: Int
    public let port: Int
    public let isGloballyExposed: Bool
    public let executablePath: String?
}

final class ListeningPortMonitor {
    static let shared = ListeningPortMonitor()

    func scanListeningPorts() -> [ListeningPortInfo] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-iTCP", "-sTCP:LISTEN", "-n", "-P"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return parseLsofOutput(output)
        } catch {
            return []
        }
    }

    func getProcessPath(pid: Int) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-p", "\(pid)", "-o", "comm="]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return output?.isEmpty == false ? output : nil
        } catch {
            return nil
        }
    }

    /// Parses `lsof -iTCP -sTCP:LISTEN -n -P` output. `internal` (not `private`)
    /// so the adversarial-input tests can feed it crafted text directly.
    func parseLsofOutput(_ output: String) -> [ListeningPortInfo] {
        var seenIDs: Set<String> = []
        var results: [ListeningPortInfo] = []
        let lines = output.components(separatedBy: .newlines)

        for line in lines.dropFirst() { // Skip header
            let parts = line.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard parts.count >= 9 else { continue }
            let command = parts[0]
            guard let pid = Int(parts[1]) else { continue }
            let nameField = parts[8] // e.g. "*:8080", "127.0.0.1:3000", "0.0.0.0:22"

            if let colonIndex = nameField.lastIndex(of: ":") {
                let hostPart = String(nameField[..<colonIndex])
                let portStr = String(nameField[nameField.index(after: colonIndex)...])
                if let port = Int(portStr) {
                    let isGlobal = hostPart == "*" || hostPart == "0.0.0.0" || hostPart == "::"
                    let uniqueKey = "\(command):\(port):\(pid)"
                    if !seenIDs.contains(uniqueKey) {
                        seenIDs.insert(uniqueKey)
                        let path = getProcessPath(pid: pid)
                        results.append(ListeningPortInfo(
                            processName: command,
                            pid: pid,
                            port: port,
                            isGloballyExposed: isGlobal,
                            executablePath: path
                        ))
                    }
                }
            }
        }
        return results
    }
}
