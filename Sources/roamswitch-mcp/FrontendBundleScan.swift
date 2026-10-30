// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.16 (build 195).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Secrets left in the files a web front end publishes (the `audit_secrets` tool with `include_build_output`).
///
/// `SecretLeakScanning.auditDirectory` skips `dist/` and `build/` on purpose (they are rebuilt, and a repository
/// scan should not report generated code twice), which means the one place a key is certain to reach the public, the
/// built bundle, is the one place that scan never looks. A script that reads a site's JavaScript pulls out the API
/// paths, the storage keys, a hard-coded token or an encryption key in one pass; this scan reads the same files first.
///
/// * Where: the build directories under the folder (`dist`, `build`, `out`, `.next/static`, `.output/public`,
///   `.svelte-kit/output`, `public`, `static`), or the folder itself when it holds none of them. `node_modules` and
///   `.git` are never entered; symbolic links leading out of the folder are never followed (`SafeScanFS`).
/// * What: what `SecretLeakScanning` knows (API keys, private keys, wallet keys), a JSON Web Token embedded in a
///   script, and a source map file left in the published folder. Values are masked to 4 characters and a length.
/// * Limits: 5 MB per file, 200 MB and 20,000 files in all. Reading only. Same rules as the Linux build.
enum FrontendBundleScan {

    enum Kind: String { case secret, jwt, sourceMap = "source_map" }

    struct Finding: Equatable {
        let kind: Kind
        /// Relative to the scanned folder.
        let file: String
        /// 0 for a source map (the file itself is the finding).
        let line: Int
        /// The provider for a secret, `JWT` for a token, the size in bytes for a source map.
        let detail: String
        let masked: String
    }

    struct Report: Equatable {
        var scannedDirs: [String] = []
        var scannedFiles = 0
        var findings: [Finding] = []
        /// A limit stopped the walk early.
        var truncated = false
    }

    static let buildDirs = ["dist", "build", "out", ".next/static", ".output/public", ".svelte-kit/output", "public", "static"]
    private static let extensions: Set<String> = ["js", "mjs", "cjs", "css", "map", "html", "json", "txt"]
    private static let maxFileBytes = 5 * 1024 * 1024
    private static let maxTotalBytes = 200 * 1024 * 1024
    private static let maxFiles = 20_000
    private static let maxDepth = 24

    /// `abcd…(52)`: enough to find the string, not enough to use it.
    static func mask(_ value: String) -> String { "\(value.prefix(4))…(\(value.count))" }

    private static let jwtPattern = try! NSRegularExpression(pattern: #"\beyJ[A-Za-z0-9_-]{8,}\.eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}"#)

    /// The findings in one file's text: the secrets `SecretLeakScanning` knows, then JSON Web Tokens.
    static func scanText(_ text: String) -> [(line: Int, kind: Kind, detail: String, masked: String)] {
        var out: [(Int, Kind, String, String)] = []
        for f in SecretLeakScanning.auditText(text) {
            out.append((f.lineNumber, .secret, f.type.rawValue, f.masked))
        }
        for (i, line) in text.components(separatedBy: "\n").enumerated() {
            let ns = line as NSString
            for m in jwtPattern.matches(in: line, range: NSRange(location: 0, length: ns.length)) {
                out.append((i + 1, .jwt, "JWT", mask(ns.substring(with: m.range))))
            }
        }
        return out.map { (line: $0.0, kind: $0.1, detail: $0.2, masked: $0.3) }
    }

    static func scan(root: URL) -> Report {
        var report = Report()
        guard let rootPath = SafeScanFS.canonicalPath(root.path) else { return report }
        var dirs = buildDirs.map { (rootPath as NSString).appendingPathComponent($0) }.filter { path in
            var isDir: ObjCBool = false
            return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
                && SafeScanFS.canonicalPath(path).map { SafeScanFS.isWithin($0, root: rootPath) } == true
        }
        if dirs.isEmpty { dirs = [rootPath] }

        var files: [(path: String, size: Int)] = []
        for dir in dirs {
            let rel = dir == rootPath ? "." : String(dir.dropFirst(rootPath.count + 1))
            report.scannedDirs.append(rel)
            var stack: [(path: String, depth: Int)] = [(dir, 0)]
            var visited: Set<String> = [dir]
            while let item = stack.popLast() {
                for entry in SafeScanFS.children(ofDirectory: item.path, root: rootPath).sorted(by: { $0.name < $1.name }) {
                    switch entry.kind {
                    case .directory:
                        guard item.depth < maxDepth, entry.name != "node_modules", entry.name != ".git",
                              visited.insert(entry.path).inserted else { continue }
                        stack.append((entry.path, item.depth + 1))
                    case .regularFile:
                        let ext = (entry.name as NSString).pathExtension.lowercased()
                        guard extensions.contains(ext) else { continue }
                        if files.count >= maxFiles { report.truncated = true; continue }
                        files.append((entry.path, Int(clamping: entry.size)))
                    }
                }
            }
        }

        var total = 0
        for file in files {
            let rel = file.path.hasPrefix(rootPath + "/") ? String(file.path.dropFirst(rootPath.count + 1)) : file.path
            guard file.size <= maxFileBytes else { continue }
            total += file.size
            if total > maxTotalBytes { report.truncated = true; break }
            report.scannedFiles += 1
            if (file.path as NSString).pathExtension.lowercased() == "map" {
                report.findings.append(Finding(kind: .sourceMap, file: rel, line: 0, detail: String(file.size), masked: ""))
            }
            guard let data = SafeScanFS.readRegularFile(atPath: file.path, maxBytes: maxFileBytes) else { continue }
            if data.prefix(8192).contains(0) { continue }
            let text = String(decoding: data, as: UTF8.self)
            for f in scanText(text) {
                report.findings.append(Finding(kind: f.kind, file: rel, line: f.line, detail: f.detail, masked: f.masked))
            }
        }
        return report
    }
}
