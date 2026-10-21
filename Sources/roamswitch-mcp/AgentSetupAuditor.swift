// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.15.0 (build 174).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Static audit of the files that steer an AI coding agent on this Mac, plus the OpenClaw
/// gateway configuration.
///
/// Why: an agent obeys text. A line hidden in `CLAUDE.md`, `AGENTS.md`, a custom command, a
/// subagent or a skill is a standing instruction the user never reviewed, and a skill can also
/// carry scripts and precompiled code. The classic tricks are invisible Unicode tag characters
/// (a whole sentence that no editor shows), "ignore your previous instructions" and "do not tell
/// the user" wording, a `curl | sh` or base64-decoded payload, a reference to key files next to an
/// upload, and instructions inside an HTML comment (invisible once the Markdown is rendered). The
/// OpenClaw gateway is a second door: a gateway with authentication switched off, a wildcard
/// browser origin, an auth token that is too short, or one of its `dangerously…` switches turned
/// on lets the wrong party drive the agent.
///
/// Read-only and local: it opens a fixed list of well-known files and folders (plus the project
/// folders registered in RoamSwitch), never the network, and never reports a secret. A token is
/// reported by length only. The text of an instruction file is untrusted data (it is exactly what
/// an attacker writes), so only a rule's name, a line number, a URL host and, for hidden Unicode
/// tag characters, the decoded hidden text (sanitized and cut short) are copied into the result,
/// and the MCP tool marks the whole result as untrusted.
///
/// Beyond the text rules there are four more: a skill or file name that mixes lookalike letters of
/// different alphabets, a whitespace padding that pushes text out of view, encoded text (a base64
/// blob or a `data:text/` URI) and an over-broad `allowed-tools` grant. And there is change
/// detection: once a person accepts the current state (`AgentSetupBaseline`), later runs report
/// files and MCP server definitions whose content changed, and ones that are new.
///
/// Three more kinds of input are read besides the instruction files. Agent memory (the notes an agent
/// keeps between sessions) goes through the same text rules, but is not part of change detection, since
/// an agent rewrites it all the time. `.vscode/tasks.json` of a registered project is checked for a task
/// that runs when the folder is opened. `.github/workflows/*.yml` of a registered project is checked for
/// three well-known mistakes (see `auditWorkflowFile`).
///
/// Every rule here is deterministic; none of it decides that something is malicious. A match
/// means "a human should look at this line", and the messages say so. The rules were written from
/// the public OpenClaw documentation (docs.openclaw.ai, gateway security pages) and from how these
/// injection tricks are published in the open; they do not copy any third-party rule set.
enum AgentSetupAuditor {

    struct Finding: Codable, Equatable {
        /// Stable id, see `findingIDs`.
        let id: String
        /// `high` or `medium`.
        let severity: String
        /// `instructions`, `openclaw`, `mcp` (an MCP server definition that changed) or `project`
        /// (an editor task or a CI workflow of a registered project).
        let area: String
        let file: String
        /// Short technical fact (rule, line number, URL host, key path), never a secret.
        let detail: String
        /// Localized explanation and what to do about it.
        let message: String
    }

    struct Result: Equatable {
        var scannedFiles: [String] = []
        /// Skill folders (a folder with a `SKILL.md`) that were looked into.
        var skillCount = 0
        var openClawConfigFound = false
        var findings: [Finding] = []
        /// Files that exist but could not be read. Reported so "nothing found" is never
        /// mistaken for "everything was checked".
        var unreadableFiles: [String] = []
        /// Digests of everything audited, in the form `AgentSetupBaseline` stores. What a person
        /// accepts is exactly this snapshot, i.e. what the result on screen was computed from.
        var snapshot = AgentSetupBaseline.Snapshot()
        /// When the state this run was compared with was accepted (ISO 8601), nil if none was.
        var baselineAcceptedAt: String?
    }

    /// One file as read from disk: its bytes and POSIX permission bits (nil if unknown).
    /// `inSkill` marks files that live inside a skill folder.
    struct FileInput {
        let path: String
        let data: Data
        let mode: UInt16?
        var inSkill = false
        /// Hex SHA-256 of the whole file (nil for the pure `audit`, which has only the bytes it was given).
        var sha256: String?
        /// Which rules read the file. Only `instruction` files are part of change detection.
        var role: Role = .instruction
        /// The file belongs to a registered project folder (and so can arrive with a repository), not to the home folder.
        var inProject = false

        enum Role: Equatable {
            /// An instruction, command, agent, rule or skill file: text rules and change detection.
            case instruction
            /// A file of an agent's memory: the text rules, no change detection.
            case memory
            /// `.vscode/tasks.json`
            case tasks
            /// `.github/workflows/*.yml`
            case workflow
            /// Claude Code `settings.json` / `settings.local.json`: permissions, hooks, sandbox.
            case settings
        }
    }

    static let findingIDs = [
        "hidden_tag_characters", "invisible_characters", "override_instruction", "remote_script_exec",
        "encoded_payload_exec", "credential_access", "credential_exfil_shape", "exfil_endpoint",
        "persistence_instruction", "skill_precompiled_code", "agent_file_writable",
        "homoglyph_name", "whitespace_padding", "hidden_encoded_text", "skill_broad_tool_grant",
        "agent_file_changed", "agent_file_added", "mcp_server_changed", "mcp_server_added",
        "openclaw_auth_disabled", "openclaw_wide_bind", "openclaw_weak_token", "openclaw_origin_wildcard",
        "openclaw_dangerous_flag", "openclaw_broad_trusted_proxy", "openclaw_proxy_trust_loosened",
        "openclaw_open_dm", "openclaw_mdns_full", "openclaw_audit_suppressed", "openclaw_loose_permissions",
        "editor_auto_run_task", "workflow_pwn_request", "workflow_expression_injection", "workflow_unpinned_action",
        "agent_settings_hook", "agent_settings_bypass", "agent_settings_broad_allow", "agent_settings_endpoint_override",
        "agent_settings_weakened", "agent_settings_writable",
    ]

    static let maxTextBytes = 512 * 1024
    static let maxFiles = 2000
    static let maxFilesPerSkill = 200
    static let maxProjectFolders = 50

    // MARK: - Candidate files

    /// Single files read in the user's home.
    static func homeInstructionFiles(home: String) -> [String] {
        [
            "\(home)/.claude/CLAUDE.md",
            "\(home)/.codex/AGENTS.md",
            "\(home)/.gemini/GEMINI.md",
            "\(home)/.codeium/windsurf/memories/global_rules.md",
        ]
    }

    /// Folders under the user's home whose Markdown / text files are instructions.
    static func homeInstructionFolders(home: String) -> [String] {
        [
            "\(home)/.claude/commands", "\(home)/.claude/agents",
            "\(home)/.codex/prompts", "\(home)/.cursor/rules",
        ]
    }

    /// Folders that hold one sub-folder per skill.
    static func homeSkillRoots(home: String) -> [String] {
        [
            "\(home)/.claude/skills", "\(home)/.codex/skills", "\(home)/.agents/skills",
            "\(home)/.openclaw/skills", "\(home)/.openclaw/workspace/skills",
        ]
    }

    static func projectInstructionFiles(folder: String) -> [String] {
        [
            "CLAUDE.md", "CLAUDE.local.md", "AGENTS.md", "GEMINI.md", ".cursorrules", ".windsurfrules",
            ".clinerules", ".github/copilot-instructions.md",
        ].map { "\(folder)/\($0)" }
    }

    static func projectInstructionFolders(folder: String) -> [String] {
        [".claude/commands", ".claude/agents", ".cursor/rules", ".clinerules"].map { "\(folder)/\($0)" }
    }

    static func projectSkillRoots(folder: String) -> [String] {
        [".claude/skills", ".agents/skills", "skills"].map { "\(folder)/\($0)" }
    }

    /// Folders of an agent's own notes: Claude Code's per-project memory (`~/.claude/projects/<project>/memory`)
    /// and subagent memory, Codex, Windsurf and OpenClaw memory.
    static func homeMemoryFolders(home: String) -> [String] {
        var folders = ["\(home)/.claude/agent-memory", "\(home)/.codex/memories", "\(home)/.codeium/windsurf/memories",
                       "\(home)/.openclaw/workspace/memory"]
        let projects = "\(home)/.claude/projects"
        if let names = try? FileManager.default.contentsOfDirectory(atPath: projects) {
            folders += names.sorted().filter { !$0.hasPrefix(".") }.map { "\(projects)/\($0)/memory" }
        }
        return folders
    }

    static func homeMemoryFiles(home: String) -> [String] {
        ["\(home)/.openclaw/workspace/MEMORY.md"]
    }

    static func projectMemoryFolders(folder: String) -> [String] {
        [".claude/agent-memory", ".claude/agent-memory-local"].map { "\(folder)/\($0)" }
    }

    static func projectTasksFile(folder: String) -> String { "\(folder)/.vscode/tasks.json" }

    /// Claude Code settings: the user's own, and the ones a repository can carry.
    static func homeSettingsFiles(home: String) -> [String] {
        ["\(home)/.claude/settings.json", "\(home)/.claude/settings.local.json"]
    }

    static func projectSettingsFiles(folder: String) -> [String] {
        [".claude/settings.json", ".claude/settings.local.json"].map { "\(folder)/\($0)" }
    }

    static func projectWorkflowFolder(folder: String) -> String { "\(folder)/.github/workflows" }

    static func isWorkflowFile(_ path: String) -> Bool {
        let ext = (path as NSString).pathExtension.lowercased()
        return (ext == "yml" || ext == "yaml") && !(path as NSString).lastPathComponent.hasPrefix(".")
    }

    static func openClawConfigPath(home: String, environment: [String: String] = ProcessInfo.processInfo.environment) -> String {
        if let custom = environment["OPENCLAW_CONFIG_PATH"], custom.hasPrefix("/") { return custom }
        return "\(home)/.openclaw/openclaw.json"
    }

    // MARK: - Run

    static func run(home: String = NSHomeDirectory(), projectFolders: [String],
                    baselineURL: URL = AgentSetupBaseline.defaultURL) -> Result {
        let fm = FileManager.default
        var inputs: [FileInput] = []
        var unreadable: [String] = []
        var skillCount = 0
        var seenPaths = Set<String>()

        func read(_ path: String, inSkill: Bool, role: FileInput.Role = .instruction, inProject: Bool = false) {
            guard inputs.count < maxFiles, seenPaths.insert(path).inserted else { return }
            guard let attrs = try? fm.attributesOfItem(atPath: path) else { return }
            let type = attrs[.type] as? FileAttributeType
            guard type == .typeRegular || type == .typeSymbolicLink else { return }
            let mode = (attrs[.posixPermissions] as? NSNumber).map { UInt16($0.intValue & 0o7777) }
            let size = (attrs[.size] as? NSNumber)?.intValue ?? 0
            // Large files are read only as far as their first bytes (enough for the binary check).
            guard let handle = FileHandle(forReadingAtPath: path) else { unreadable.append(path); return }
            defer { try? handle.close() }
            let data = (try? handle.read(upToCount: size > maxTextBytes ? 8 : maxTextBytes)) ?? Data()
            if size > maxTextBytes, !inSkill { unreadable.append(path); return }
            // The digest covers the whole file, also when only its first bytes were read above.
            let digest = size > maxTextBytes ? AgentSetupBaseline.sha256Hex(ofFileAt: path) : AgentSetupBaseline.sha256Hex(data)
            inputs.append(FileInput(path: path, data: data, mode: mode, inSkill: inSkill, sha256: digest, role: role, inProject: inProject))
        }

        func files(in folder: String, maxDepth: Int) -> [String] {
            guard let enumerator = fm.enumerator(atPath: folder) else { return [] }
            var out: [String] = []
            for case let rel as String in enumerator {
                if rel.split(separator: "/").count > maxDepth { enumerator.skipDescendants(); continue }
                if rel.split(separator: "/").contains(where: { $0 == ".git" || $0 == "node_modules" }) { enumerator.skipDescendants(); continue }
                var isDir: ObjCBool = false
                let full = "\(folder)/\(rel)"
                if fm.fileExists(atPath: full, isDirectory: &isDir), !isDir.boolValue { out.append(full) }
                if out.count >= maxFilesPerSkill * 5 { break }
            }
            return out.sorted()
        }

        let folders = Array(projectFolders.prefix(maxProjectFolders))
        var singles = homeInstructionFiles(home: home)
        var instructionFolders = homeInstructionFolders(home: home)
        var skillRoots = homeSkillRoots(home: home)
        for folder in folders {
            singles += projectInstructionFiles(folder: folder)
            instructionFolders += projectInstructionFolders(folder: folder)
            skillRoots += projectSkillRoots(folder: folder)
        }
        for path in singles { read(path, inSkill: false) }
        for folder in instructionFolders {
            for path in files(in: folder, maxDepth: 4) where isInstructionText(path) { read(path, inSkill: false) }
        }
        for root in skillRoots {
            guard let skills = try? fm.contentsOfDirectory(atPath: root) else { continue }
            for skill in skills.sorted() where !skill.hasPrefix(".") {
                let dir = "\(root)/\(skill)"
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: dir, isDirectory: &isDir), isDir.boolValue else { continue }
                guard fm.fileExists(atPath: "\(dir)/SKILL.md") else { continue }
                skillCount += 1
                for path in files(in: dir, maxDepth: 4).prefix(maxFilesPerSkill) { read(path, inSkill: true) }
            }
        }

        // Agent memory (text rules, no change detection), then the editor tasks and CI workflows of the projects.
        var memoryFolders = homeMemoryFolders(home: home)
        for folder in folders { memoryFolders += projectMemoryFolders(folder: folder) }
        for path in homeMemoryFiles(home: home) { read(path, inSkill: false, role: .memory) }
        for folder in memoryFolders {
            for path in files(in: folder, maxDepth: 4) where isInstructionText(path) { read(path, inSkill: false, role: .memory) }
        }
        for folder in folders {
            read(projectTasksFile(folder: folder), inSkill: false, role: .tasks)
            let workflows = projectWorkflowFolder(folder: folder)
            for name in ((try? fm.contentsOfDirectory(atPath: workflows)) ?? []).sorted() where isWorkflowFile(name) {
                read("\(workflows)/\(name)", inSkill: false, role: .workflow)
            }
        }

        // Claude Code settings: permissions, hooks and the sandbox switch.
        let settingsCandidates = homeSettingsFiles(home: home) + folders.flatMap { projectSettingsFiles(folder: $0) }
        for path in homeSettingsFiles(home: home) { read(path, inSkill: false, role: .settings) }
        for folder in folders { for path in projectSettingsFiles(folder: folder) { read(path, inSkill: false, role: .settings, inProject: true) } }

        // OpenClaw configuration and state directory.
        var openClaw: FileInput?
        let configPath = openClawConfigPath(home: home)
        if let attrs = try? fm.attributesOfItem(atPath: configPath), (attrs[.type] as? FileAttributeType) != .typeDirectory {
            if let data = fm.contents(atPath: configPath), data.count <= maxTextBytes {
                let mode = (attrs[.posixPermissions] as? NSNumber).map { UInt16($0.intValue & 0o7777) }
                openClaw = FileInput(path: configPath, data: data, mode: mode, sha256: AgentSetupBaseline.sha256Hex(data))
            } else {
                unreadable.append(configPath)
            }
        }
        var stateDirs: [(String, UInt16)] = []
        for dir in ["\(home)/.openclaw", "\(home)/.openclaw/credentials"] {
            if let attrs = try? fm.attributesOfItem(atPath: dir), (attrs[.type] as? FileAttributeType) == .typeDirectory,
               let mode = (attrs[.posixPermissions] as? NSNumber).map({ UInt16($0.intValue & 0o7777) }) {
                stateDirs.append((dir, mode))
            }
        }

        var result = audit(files: inputs, openClawConfig: openClaw, openClawDirectories: stateDirs)
        result.skillCount = skillCount
        result.unreadableFiles += unreadable

        // Change detection: what is there now, and how it differs from the state a person accepted.
        var snapshot = AgentSetupBaseline.Snapshot()
        snapshot.scopes = [home] + folders
        for input in inputs.filter({ $0.role == .instruction }) + (openClaw.map { [$0] } ?? []) {
            if let digest = input.sha256 { snapshot.files[input.path] = AgentSetupBaseline.Entry(sha256: digest, fields: nil) }
        }
        snapshot.servers = MCPConfigAuditor.serverSnapshot(home: home, projectFolders: folders)
        var settingsSnapshot: [String: AgentSetupBaseline.SettingsEntry] = [:]
        for path in settingsCandidates {
            if let input = inputs.first(where: { $0.path == path && $0.role == .settings }) {
                settingsSnapshot[path] = settingsFacts(input.data).map(settingsEntry) ?? AgentSetupBaseline.SettingsEntry(unreadable: true)
            } else if fm.fileExists(atPath: path) {
                settingsSnapshot[path] = AgentSetupBaseline.SettingsEntry(unreadable: true)
            }
        }
        snapshot.settings = settingsSnapshot
        result.snapshot = snapshot
        if let store = AgentSetupBaseline.load(from: baselineURL) {
            result.baselineAcceptedAt = store.acceptedAt
            result.findings += driftFindings(AgentSetupBaseline.compare(store, with: snapshot),
                                             acceptedAt: store.acceptedAt, existing: result.findings)
        }
        return result
    }

    /// Records the state `result` was computed from as the accepted one. The caller is a person
    /// (a button, a command-line flag); an audit run and the MCP tool never call this.
    @discardableResult
    static func acceptCurrentState(_ result: Result, baselineURL: URL = AgentSetupBaseline.defaultURL) throws -> AgentSetupBaseline.Store {
        try AgentSetupBaseline.accept(result.snapshot, to: baselineURL)
    }

    /// MCP server keys whose change alters what runs or what it may do without asking.
    private static let serverRiskFields: Set<String> = [
        "command", "args", "url", "serverUrl", "env", "headers", "cwd", "type", "transport", "alwaysAllow", "autoApprove",
    ]

    /// Findings for what differs from the accepted state. A changed file is `high` when the same file
    /// also has a `high` finding in this run: it changed into something that looks wrong.
    static func driftFindings(_ changes: [AgentSetupBaseline.Change], acceptedAt: String, existing: [Finding]) -> [Finding] {
        let day = AgentSetupBaseline.day(of: acceptedAt)
        var out: [Finding] = []
        for change in changes {
            switch change {
            case .fileChanged(let path):
                let worse = existing.contains { $0.file == path && $0.severity == "high" }
                out.append(Finding(id: "agent_file_changed", severity: worse ? "high" : "medium", area: "instructions", file: path,
                                   detail: "content differs from the state accepted on \(day)", message: message("agent_file_changed")))
            case .fileAdded(let path):
                out.append(Finding(id: "agent_file_added", severity: "medium", area: "instructions", file: path,
                                   detail: "not present when the state was accepted on \(day)", message: message("agent_file_added")))
            case .serverChanged(let path, let name, let fields):
                let risky = fields.isEmpty || fields.contains { serverRiskFields.contains($0) }
                let what = fields.isEmpty ? "definition" : fields.map { sanitized($0, limit: 24) }.joined(separator: ", ")
                out.append(Finding(id: "mcp_server_changed", severity: risky ? "high" : "medium", area: "mcp", file: path,
                                   detail: "server \"\(sanitized(name, limit: 40))\": \(what) changed since \(day)", message: message("mcp_server_changed")))
            case .serverAdded(let path, let name):
                out.append(Finding(id: "mcp_server_added", severity: "medium", area: "mcp", file: path,
                                   detail: "server \"\(sanitized(name, limit: 40))\" was not configured when the state was accepted on \(day)",
                                   message: message("mcp_server_added")))
            case .settingsWeakened(let path, let reasons):
                // A hook, a higher permission mode or a switched-off sandbox changes what runs without asking: high.
                // Fewer deny rules or a wider allow rule is medium.
                let severe = reasons.contains { reason in
                    switch reason {
                    case .hookAdded, .modeRaised, .sandboxDisabled, .dangerousPromptSkipped: return true
                    case .denyRemoved, .broadAllowAdded: return false
                    }
                }
                out.append(Finding(id: "agent_settings_weakened", severity: severe ? "high" : "medium", area: "settings", file: path,
                                   detail: reasons.map(describe).joined(separator: "; ") + " since \(day)", message: message("agent_settings_weakened")))
            }
        }
        return out
    }

    /// Text-looking instruction files in a commands / agents / rules folder.
    static func isInstructionText(_ path: String) -> Bool {
        let name = (path as NSString).lastPathComponent.lowercased()
        if name.hasPrefix(".") { return false }
        let ext = (name as NSString).pathExtension
        return ["md", "mdc", "markdown", "txt", ""].contains(ext)
    }

    // MARK: - Pure audit

    static func audit(files: [FileInput], openClawConfig: FileInput?, openClawDirectories: [(String, UInt16)] = []) -> Result {
        var result = Result()
        for file in files {
            result.scannedFiles.append(file.path)
            switch file.role {
            case .instruction, .memory:
                result.findings += auditInstructionFile(file)
            case .tasks:
                // A tasks file that cannot be parsed was not audited.
                if let found = auditTasksFile(file) { result.findings += found } else { result.unreadableFiles.append(file.path) }
            case .workflow:
                result.findings += auditWorkflowFile(file)
            case .settings:
                if let found = auditSettingsFile(file) { result.findings += found } else { result.unreadableFiles.append(file.path) }
            }
        }
        if let config = openClawConfig {
            if let found = auditOpenClawConfig(config) {
                result.openClawConfigFound = true
                result.findings += found
            } else {
                result.openClawConfigFound = true
                result.unreadableFiles.append(config.path)
            }
        }
        for (dir, mode) in openClawDirectories where mode & 0o077 != 0 {
            result.findings.append(Finding(
                id: "openclaw_loose_permissions", severity: "medium", area: "openclaw", file: dir,
                detail: "mode \(String(mode, radix: 8)) (recommended 700)", message: message("openclaw_loose_permissions")))
        }
        if let config = openClawConfig, let mode = config.mode, mode & 0o077 != 0 {
            result.findings.append(Finding(
                id: "openclaw_loose_permissions", severity: "medium", area: "openclaw", file: config.path,
                detail: "mode \(String(mode, radix: 8)) (recommended 600)", message: message("openclaw_loose_permissions")))
        }
        return result
    }

    // MARK: - Instruction and skill files

    private struct Hit {
        let id: String
        var severity: String
        let line: Int
        let detail: String
    }

    private static let binaryExtensions: Set<String> = ["pyc", "pyo", "pyd", "so", "dylib", "dll", "exe", "node", "class", "jar", "wasm"]
    private static let imageLikeExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "webp", "ico", "pdf", "svg", "ttf", "otf", "woff", "woff2", "zip", "gz", "tar", "mp3", "mp4", "mov"]

    static func auditInstructionFile(_ file: FileInput) -> [Finding] {
        var findings: [Finding] = []
        let ext = (file.path as NSString).pathExtension.lowercased()

        func add(_ id: String, _ severity: String, _ detail: String) {
            findings.append(Finding(id: id, severity: severity, area: "instructions", file: file.path, detail: detail, message: message(id)))
        }

        if let mode = file.mode, mode & 0o022 != 0 {
            add("agent_file_writable", "medium", "mode \(String(mode, radix: 8)) is writable by group or others")
        }

        // Precompiled code inside a skill: it cannot be read, so it cannot be reviewed.
        if file.inSkill, isPrecompiled(file.data, ext: ext) {
            add("skill_precompiled_code", "medium", ext.isEmpty ? "executable file" : ".\(ext) file")
            return findings
        }
        if imageLikeExtensions.contains(ext) { return findings }
        // Not text (NUL bytes or invalid UTF-8): nothing a text rule can say about it.
        guard !file.data.prefix(8192).contains(0), let text = String(data: file.data, encoding: .utf8) else { return findings }

        let isMarkdownLike = ["md", "mdc", "markdown", "txt", ""].contains(ext)
        let lines = text.components(separatedBy: "\n")
        let inComment = htmlCommentLines(lines)
        let inMarkdownComment = markdownCommentLines(lines)
        let front = isMarkdownLike ? frontMatter(lines) : nil
        var hits: [Hit] = []

        // Hidden Unicode.
        if let tag = hiddenTagText(text) {
            hits.append(Hit(id: "hidden_tag_characters", severity: "high", line: tag.line,
                            detail: "line \(tag.line): \(tag.count) tag characters" + (tag.decoded.isEmpty ? "" : ", hidden text \"\(sanitized(tag.decoded))\"")))
        }
        if let invisible = firstInvisible(text) {
            hits.append(Hit(id: "invisible_characters", severity: "medium", line: invisible.line,
                            detail: "line \(invisible.line): U+\(String(format: "%04X", invisible.scalar)) (\(invisible.count) in total)"))
        }

        // Names: a skill, a file or a front-matter name that mixes lookalike letters of two alphabets.
        for (label, name) in identifiers(of: file.path, frontMatter: front) {
            if let mixed = mixedScript(name) {
                hits.append(Hit(id: "homoglyph_name", severity: mixed.script == "Cyrillic" ? "high" : "medium", line: 1,
                                detail: "\(label) \"\(sanitized(name, limit: 40))\" mixes Latin and \(mixed.script) letters (U+\(String(format: "%04X", mixed.scalar)))"))
            }
        }
        // Text pushed out of view by a long run of blanks or empty lines.
        for padding in whitespacePaddings(lines) {
            hits.append(Hit(id: "whitespace_padding", severity: "medium", line: padding.line, detail: "line \(padding.line): \(padding.detail)"))
        }
        // allowed-tools that lets the file run any command without asking.
        if let front, let value = frontMatterValue(front, keys: ["allowed-tools", "allowed_tools"]) {
            let broad = splitGrants(value).compactMap(broadGrant)
            if !broad.isEmpty {
                let shown = broad.prefix(3).map { sanitized($0, limit: 40) }.joined(separator: ", ")
                hits.append(Hit(id: "skill_broad_tool_grant", severity: "medium", line: 1,
                                detail: "allowed-tools grants unrestricted commands: \(shown)" + (broad.count > 3 ? " (+\(broad.count - 3) more)" : "")))
            }
        }

        var credentialLine: Int?
        var exfilLine: Int?
        for (index, rawLine) in lines.enumerated() {
            let number = index + 1
            let line = rawLine
            let lower = line.lowercased()
            let commentKind: String? = inComment[index] ? "an HTML comment" : (inMarkdownComment[index] ? "a hidden Markdown comment" : nil)
            let commented = commentKind != nil
            func bump(_ severity: String) -> String { commented ? "high" : severity }
            func note(_ detail: String) -> String { "line \(number)\(commentKind.map { " (inside \($0))" } ?? ""): \(detail)" }

            for blob in encodedTexts(in: line) {
                let tail = blob.rule.map { ", the text contains \($0)" } ?? ""
                hits.append(Hit(id: "hidden_encoded_text", severity: bump(blob.rule != nil ? "high" : "medium"), line: number,
                                detail: note("\(blob.length) encoded characters\(blob.isDataURI ? " in a data:text URI" : " that decode to text")\(tail)")))
            }

            if isMarkdownLike, matchesUnquoted(overridePatterns, lower) {
                hits.append(Hit(id: "override_instruction", severity: bump("medium"), line: number, detail: note("instruction-override wording")))
            }
            if matches(remoteExecPatterns, lower) {
                let host = firstURLHost(in: line)
                let rawIP = host.map { isIPAddress($0) } ?? false
                hits.append(Hit(id: "remote_script_exec", severity: bump(rawIP ? "high" : "medium"), line: number,
                                detail: note("downloads and runs a script" + (host.map { " from \(sanitized($0))" } ?? ""))))
            }
            if matches(encodedExecPatterns, lower) {
                hits.append(Hit(id: "encoded_payload_exec", severity: "high", line: number, detail: note("decodes text and runs it")))
            }
            if !hasNegation(lower), matches(credentialPatterns, lower) {
                if credentialLine == nil { credentialLine = number }
                hits.append(Hit(id: "credential_access", severity: bump("medium"), line: number, detail: note("refers to a credential file or store")))
            }
            if let host = matchedExfilHost(lower) {
                if exfilLine == nil { exfilLine = number }
                hits.append(Hit(id: "exfil_endpoint", severity: bump("medium"), line: number, detail: note("mentions \(host)")))
            } else if matches(uploadPatterns, line), !lower.contains("localhost"), !lower.contains("127.0.0.1") {
                if exfilLine == nil { exfilLine = number }
            }
            if !hasNegation(lower), matches(persistencePatterns, lower) {
                hits.append(Hit(id: "persistence_instruction", severity: bump("medium"), line: number, detail: note("sets up something that survives a restart")))
            }
        }
        if let credential = credentialLine, let exfil = exfilLine {
            hits.append(Hit(id: "credential_exfil_shape", severity: "high", line: credential,
                            detail: "credential reference at line \(credential) and an upload or drop-site reference at line \(exfil) in the same file"))
        }

        // One finding per rule per file: the first line, plus how many more there were.
        var seen: [String: (Hit, Int)] = [:]
        var order: [String] = []
        for hit in hits {
            if let existing = seen[hit.id] {
                let strongest = existing.0.severity == "high" || hit.severity != "high" ? existing.0 : hit
                seen[hit.id] = (strongest, existing.1 + 1)
            } else {
                seen[hit.id] = (hit, 1)
                order.append(hit.id)
            }
        }
        for id in order {
            guard let (hit, count) = seen[id] else { continue }
            add(id, hit.severity, hit.detail + (count > 1 ? " (+\(count - 1) more)" : ""))
        }
        return findings
    }

    // MARK: - Editor tasks and CI workflows of a project

    /// `.vscode/tasks.json` (JSON with comments and trailing commas). A task whose `runOptions.runOn` is
    /// `folderOpen` starts by itself when the folder is opened in VS Code or a compatible editor, so an
    /// untrusted project runs its command without a click. Medium; high when the command downloads and runs
    /// a script or decodes text and runs it. The command is never copied into the result. nil: not parseable.
    static func auditTasksFile(_ file: FileInput) -> [Finding]? {
        guard let found = auditTasksFileContent(file) else { return nil }
        return writableByEveryUser(file, area: "project") + found
    }

    /// Every user can write this file: a settings, tasks or workflow file that steers what runs. Only the "others"
    /// write bit counts. A group-writable mode (0664) is the default for some setups, so flagging it would be noise.
    static func writableByEveryUser(_ file: FileInput, area: String) -> [Finding] {
        guard let mode = file.mode, mode & 0o002 != 0 else { return [] }
        return [Finding(id: "agent_settings_writable", severity: "high", area: area, file: file.path,
                        detail: "mode \(String(mode & 0o7777, radix: 8)) is writable by every user", message: message("agent_settings_writable"))]
    }

    private static func auditTasksFileContent(_ file: FileInput) -> [Finding]? {
        guard let root = (try? JSONSerialization.jsonObject(with: file.data, options: [.json5Allowed])) as? [String: Any] else { return nil }
        guard let tasks = root["tasks"] as? [Any] else { return [] }
        var hits: [(severity: String, detail: String)] = []
        for case let task as [String: Any] in tasks {
            let runOptions = task["runOptions"] as? [String: Any]
            guard (runOptions?["runOn"] as? String)?.lowercased() == "folderopen" else { continue }
            // The command may also be given per platform (`osx`, `linux`, `windows`).
            var commandText: [String] = []
            for scope in [task] + ["osx", "linux", "windows"].compactMap({ task[$0] as? [String: Any] }) {
                if let command = scope["command"] as? String { commandText.append(command) }
                if let args = scope["args"] as? [Any] {
                    commandText += args.map { ($0 as? String) ?? (($0 as? [String: Any])?["value"] as? String) ?? "" }
                }
            }
            let lower = commandText.joined(separator: " ").lowercased()
            let rule: String?
            if matches(remoteExecPatterns, lower) { rule = "the command downloads and runs a script" }
            else if matches(encodedExecPatterns, lower) { rule = "the command decodes text and runs it" }
            else { rule = nil }
            let label = sanitized((task["label"] as? String) ?? "unnamed", limit: 40)
            hits.append((rule == nil ? "medium" : "high", "task \"\(label)\" runs when the folder is opened" + (rule.map { ", \($0)" } ?? "")))
        }
        guard let strongest = hits.first(where: { $0.severity == "high" }) ?? hits.first else { return [] }
        return [Finding(id: "editor_auto_run_task", severity: strongest.severity, area: "project", file: file.path,
                        detail: strongest.detail + (hits.count > 1 ? " (+\(hits.count - 1) more)" : ""), message: message("editor_auto_run_task"))]
    }

    // MARK: - Claude Code settings

    /// What the audit reads out of a Claude Code settings file. Rule and command text stays here; only digests
    /// (`settingsEntry`) and a few key names reach a result.
    struct SettingsFacts {
        var hooks: [(event: String, matcher: String, command: String)] = []
        var allow: [String] = []
        var deny: [String] = []
        var defaultMode: String?
        var dangerousPromptSkipped = false
        var sandboxEnabled: Bool?
        var baseURL: String?
    }

    /// nil when the file is not a JSON object. An empty file has no settings.
    static func settingsFacts(_ data: Data) -> SettingsFacts? {
        if data.allSatisfy({ $0 == 0x20 || $0 == 0x0A || $0 == 0x0D || $0 == 0x09 }) { return SettingsFacts() }
        guard let root = (try? JSONSerialization.jsonObject(with: data, options: [.json5Allowed])) as? [String: Any] else { return nil }
        var facts = SettingsFacts()
        if let events = root["hooks"] as? [String: Any] {
            for (event, value) in events.sorted(by: { $0.key < $1.key }) {
                for case let group as [String: Any] in (value as? [Any]) ?? [] {
                    let matcher = (group["matcher"] as? String) ?? ""
                    // `{"matcher": …, "hooks": [{"type": "command", "command": …}]}`, or the command directly in the group.
                    for case let hook as [String: Any] in (group["hooks"] as? [Any]) ?? [group] {
                        if let command = hook["command"] as? String, !command.isEmpty { facts.hooks.append((event, matcher, command)) }
                    }
                }
            }
        }
        if let permissions = root["permissions"] as? [String: Any] {
            facts.allow = ((permissions["allow"] as? [Any]) ?? []).compactMap { $0 as? String }
            facts.deny = ((permissions["deny"] as? [Any]) ?? []).compactMap { $0 as? String }
            if let mode = permissions["defaultMode"] as? String { facts.defaultMode = mode }
        }
        if (root["skipDangerousModePermissionPrompt"] as? Bool) == true { facts.dangerousPromptSkipped = true }
        if let sandbox = root["sandbox"] as? [String: Any] { facts.sandboxEnabled = sandbox["enabled"] as? Bool }
        if let env = root["env"] as? [String: Any], let base = env["ANTHROPIC_BASE_URL"] as? String { facts.baseURL = base }
        return facts
    }

    /// The digests the baseline keeps for a settings file.
    static func settingsEntry(_ facts: SettingsFacts) -> AgentSetupBaseline.SettingsEntry {
        func digest(_ text: String) -> String { AgentSetupBaseline.sha256Hex(Data(text.utf8)) }
        var entry = AgentSetupBaseline.SettingsEntry()
        entry.denyRules = Array(Set(facts.deny.map(digest))).sorted()
        entry.broadAllow = Array(Set(facts.allow.filter { broadGrant($0) != nil }.map(digest))).sorted()
        entry.hooks = Array(Set(facts.hooks.map { digest("\($0.event)\u{0}\($0.matcher)\u{0}\($0.command)") })).sorted()
        if let mode = facts.defaultMode, AgentSetupBaseline.modeRank[mode] != nil { entry.defaultMode = mode }
        entry.sandboxDisabled = facts.sandboxEnabled == false
        entry.dangerousPromptSkipped = facts.dangerousPromptSkipped
        return entry
    }

    static func describe(_ reason: AgentSetupBaseline.SettingsWeakening) -> String {
        switch reason {
        case .denyRemoved(let n): return "\(n) deny rule\(n == 1 ? "" : "s") removed"
        case .broadAllowAdded(let n): return "\(n) allow rule\(n == 1 ? "" : "s") that let any command run added"
        case .hookAdded(let n): return "\(n) hook command\(n == 1 ? "" : "s") added or changed"
        case .modeRaised(let from, let to): return "permission mode \(from) -> \(to)"
        case .sandboxDisabled: return "sandbox switched off"
        case .dangerousPromptSkipped: return "the warning before bypassPermissions switched off"
        }
    }

    /// `~/.claude/settings.json` and a project's `.claude/settings.json`. What it steers is what runs without asking:
    /// a permission mode that skips every prompt (`agent_settings_bypass`), an allow rule that lets any command run
    /// (`agent_settings_broad_allow`), hook commands that run on every tool call or session start
    /// (`agent_settings_hook`: high when the command downloads and runs a script or decodes text and runs it, and
    /// medium for any hook in a project file, since a repository can carry it) and an API endpoint set to another host
    /// (`agent_settings_endpoint_override`; high in a project file, which can point the agent's key at a stranger).
    /// A hook in the user's own file is not flagged by itself: the baseline reports it when it appears.
    /// Rule and command text is never copied into the result. nil: not parseable.
    static func auditSettingsFile(_ file: FileInput) -> [Finding]? {
        guard let facts = settingsFacts(file.data) else { return nil }
        var findings: [Finding] = []
        func add(_ id: String, _ severity: String, _ detail: String) {
            findings.append(Finding(id: id, severity: severity, area: "settings", file: file.path, detail: detail, message: message(id)))
        }
        findings += writableByEveryUser(file, area: "settings")
        if facts.defaultMode == "bypassPermissions" {
            add("agent_settings_bypass", "high", "permissions.defaultMode is bypassPermissions")
        } else if facts.dangerousPromptSkipped {
            add("agent_settings_bypass", "high", "skipDangerousModePermissionPrompt is true")
        }
        let broad = facts.allow.compactMap(broadGrant)
        if !broad.isEmpty {
            let shown = broad.prefix(3).map { sanitized($0, limit: 40) }.joined(separator: ", ")
            add("agent_settings_broad_allow", "medium", "permissions.allow lets any command run: \(shown)" + (broad.count > 3 ? " (+\(broad.count - 3) more)" : ""))
        }
        if !facts.hooks.isEmpty {
            var risky: (event: String, rule: String)?
            for hook in facts.hooks {
                let lower = hook.command.lowercased()
                if matches(remoteExecPatterns, lower) { risky = (hook.event, "downloads and runs a script"); break }
                if matches(encodedExecPatterns, lower) { risky = (hook.event, "decodes text and runs it"); break }
            }
            if let risky {
                add("agent_settings_hook", "high", "\(sanitized(risky.event, limit: 30)) hook \(risky.rule)" + (facts.hooks.count > 1 ? " (\(facts.hooks.count) hook commands in the file)" : ""))
            } else if file.inProject {
                add("agent_settings_hook", "medium", "\(facts.hooks.count) hook command\(facts.hooks.count == 1 ? "" : "s") in a project file, run on Claude Code events")
            }
        }
        if let base = facts.baseURL, let host = URL(string: base)?.host?.lowercased(), host != "api.anthropic.com" {
            add("agent_settings_endpoint_override", file.inProject ? "high" : "medium", "env.ANTHROPIC_BASE_URL points to \(sanitized(host, limit: 60))")
        }
        return findings
    }

    /// Workflow triggers that run with the repository's secrets or write access on input a stranger wrote.
    static let privilegedWorkflowTriggers: Set<String> = [
        "pull_request_target", "issue_comment", "issues", "workflow_run", "discussion", "discussion_comment",
        "pull_request_review", "pull_request_review_comment",
    ]

    private static let onKeyPattern = regex(#"^["']?(on|true)["']?\s*:\s*(.*)$"#)
    private static let scriptKeyPattern = regex(#"^(\s*)(-\s+)?(run|script)\s*:\s*(.*)$"#)
    private static let refKeyPattern = regex(#"^\s*(?:-\s+)?ref\s*:\s*(.+)$"#)
    private static let usesKeyPattern = regex(#"^\s*(?:-\s+)?uses\s*:\s*["']?([^\s"'#]+)"#)
    private static let commitSHAPattern = regex(#"^[0-9a-f]{40}$"#)

    /// Text a stranger can write (an issue or pull-request title or body, a comment, a branch name, a commit
    /// message, an author name or e-mail), as GitHub's own security guidance lists it.
    private static let untrustedExpressionPattern = regex(
        #"\$\{\{[^}]*?\b(github\.event\.(?:issue\.(?:title|body)|pull_request\.(?:title|body|head\.ref|head\.label|head\.repo\.default_branch)"#
        + #"|comment\.body|review\.body|review_comment\.body|discussion\.(?:title|body)|head_commit\.(?:message|author\.(?:name|email))"#
        + #"|commits\[[^\]]*\]\.(?:message|author\.(?:name|email))|pages\[[^\]]*\]\.page_name"#
        + #"|workflow_run\.(?:head_branch|head_commit\.(?:message|author\.(?:name|email))))|github\.head_ref)"#)

    /// Names of what the pull request or the run that started the workflow brought along.
    private static let headCodeMarkers = [
        "github.event.pull_request.head", "github.head_ref", "github.event.workflow_run.head_",
    ]

    private static func indent(of line: String) -> Int { line.prefix { $0 == " " }.count }

    private static func isBlankOrComment(_ line: String) -> Bool {
        let t = line.trimmingCharacters(in: .whitespaces)
        return t.isEmpty || t.hasPrefix("#")
    }

    /// The trigger names of the top-level `on:` key, in lower case. A small line-based reader, not a YAML parser.
    static func workflowTriggers(_ lines: [String]) -> Set<String> {
        var out = Set<String>()
        for (i, line) in lines.enumerated() {
            let range = NSRange(line.startIndex..., in: line)
            guard let m = onKeyPattern.firstMatch(in: line, options: [], range: range), let restRange = Range(m.range(at: 2), in: line) else { continue }
            var rest = String(line[restRange])
            if let hash = rest.range(of: " #") { rest = String(rest[..<hash.lowerBound]) }
            rest = rest.trimmingCharacters(in: .whitespaces)
            if !rest.isEmpty {
                // `on: pull_request_target`, `on: [push, issues]`, `on: { issues: ... }`
                for token in rest.lowercased().split(whereSeparator: { !($0.isLetter || $0 == "_") }) { out.insert(String(token)) }
                continue
            }
            var block: [String] = []
            var j = i + 1
            while j < lines.count, isBlankOrComment(lines[j]) || indent(of: lines[j]) > 0 {
                if !isBlankOrComment(lines[j]) { block.append(lines[j]) }
                j += 1
            }
            guard let childIndent = block.map(indent(of:)).min() else { continue }
            for entry in block where indent(of: entry) == childIndent {
                var text = entry.trimmingCharacters(in: .whitespaces)
                if text.hasPrefix("- ") { text = String(text.dropFirst(2)) }
                let key = text.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? text
                out.insert(key.trimmingCharacters(in: CharacterSet(charactersIn: " \"'")).lowercased())
            }
        }
        return out
    }

    /// The text of every `run:` and `script:` value, with its line number. Handles a block scalar (`|`, `>`)
    /// by indentation. `run:` as a mapping key (`defaults.run`) has no text of its own and yields nothing.
    static func workflowScripts(_ lines: [String]) -> [(line: Int, text: String)] {
        var out: [(Int, String)] = []
        var i = 0
        while i < lines.count {
            let line = lines[i]
            let range = NSRange(line.startIndex..., in: line)
            guard let m = scriptKeyPattern.firstMatch(in: line, options: [], range: range),
                  let leadRange = Range(m.range(at: 1), in: line), let restRange = Range(m.range(at: 4), in: line) else { i += 1; continue }
            let dash = Range(m.range(at: 2), in: line).map { line[$0].count } ?? 0
            let keyColumn = line[leadRange].count + dash
            let rest = String(line[restRange]).trimmingCharacters(in: .whitespaces)
            if rest.hasPrefix("|") || rest.hasPrefix(">") {
                var j = i + 1
                while j < lines.count {
                    let next = lines[j]
                    if next.trimmingCharacters(in: .whitespaces).isEmpty { j += 1; continue }
                    guard indent(of: next) > keyColumn else { break }
                    out.append((j + 1, next))
                    j += 1
                }
                i = j
                continue
            }
            if !rest.isEmpty, !rest.hasPrefix("#") { out.append((i + 1, rest)) }
            i += 1
        }
        return out
    }

    /// Three mistakes that turn a workflow into a way in, in a registered project's `.github/workflows`:
    /// pull-request code checked out where secrets exist (`workflow_pwn_request`, high), text a stranger wrote
    /// pasted into a script with `${{ }}` (`workflow_expression_injection`, high under a trigger that has secrets
    /// or write access, otherwise medium), and a third-party action that is not pinned to a commit
    /// (`workflow_unpinned_action`, medium; `actions/*` and `github/*`, local `./` and `docker://` are skipped).
    /// Nothing from the file except an expression name and an `owner/repo@ref` is copied into the result.
    static func auditWorkflowFile(_ file: FileInput) -> [Finding] {
        writableByEveryUser(file, area: "project") + auditWorkflowFileContent(file)
    }

    private static func auditWorkflowFileContent(_ file: FileInput) -> [Finding] {
        guard let text = String(data: file.data, encoding: .utf8) else { return [] }
        let lines = text.components(separatedBy: "\n").map { $0.hasSuffix("\r") ? String($0.dropLast()) : $0 }
        let triggers = workflowTriggers(lines)
        let privileged = triggers.intersection(privilegedWorkflowTriggers).sorted()
        var findings: [Finding] = []
        func add(_ id: String, _ severity: String, _ detail: String) {
            findings.append(Finding(id: id, severity: severity, area: "project", file: file.path, detail: detail, message: message(id)))
        }

        // Pull-request code where the secrets are.
        if let trigger = ["pull_request_target", "workflow_run"].first(where: { triggers.contains($0) }) {
            var hits: [Int] = []
            for (index, line) in lines.enumerated() {
                let range = NSRange(line.startIndex..., in: line)
                guard let m = refKeyPattern.firstMatch(in: line, options: [], range: range), let value = Range(m.range(at: 1), in: line) else { continue }
                let lower = line[value].lowercased()
                if headCodeMarkers.contains(where: { lower.contains($0) }) { hits.append(index + 1) }
            }
            if let first = hits.first {
                add("workflow_pwn_request", "high",
                    "line \(first): trigger \(trigger) and a checkout of the pull request's code" + (hits.count > 1 ? " (+\(hits.count - 1) more)" : ""))
            }
        }

        // Text a stranger wrote, pasted into a script.
        var injections: [(line: Int, name: String)] = []
        for script in workflowScripts(lines) {
            let range = NSRange(script.text.startIndex..., in: script.text)
            for m in untrustedExpressionPattern.matches(in: script.text, options: [], range: range) {
                let group = m.range(at: 1).location != NSNotFound ? m.range(at: 1) : m.range
                if let r = Range(group, in: script.text) { injections.append((script.line, sanitized(String(script.text[r]), limit: 60))) }
            }
        }
        if let first = injections.first {
            let context = privileged.isEmpty ? "" : ", trigger \(privileged[0])"
            add("workflow_expression_injection", privileged.isEmpty ? "medium" : "high",
                "line \(first.line): \(first.name) is placed in a script\(context)" + (injections.count > 1 ? " (+\(injections.count - 1) more)" : ""))
        }

        // Third-party actions that can be moved by their owner.
        var unpinned: [(line: Int, ref: String)] = []
        for (index, line) in lines.enumerated() {
            let range = NSRange(line.startIndex..., in: line)
            guard let m = usesKeyPattern.firstMatch(in: line, options: [], range: range), let r = Range(m.range(at: 1), in: line) else { continue }
            let value = String(line[r])
            if value.hasPrefix("./") || value.lowercased().hasPrefix("docker://") { continue }
            guard let at = value.lastIndex(of: "@") else { continue }
            let owner = value.split(separator: "/").first.map { $0.lowercased() } ?? ""
            if owner == "actions" || owner == "github" || owner.isEmpty { continue }
            let ref = String(value[value.index(after: at)...])
            if commitSHAPattern.firstMatch(in: ref, options: [], range: NSRange(ref.startIndex..., in: ref)) != nil { continue }
            unpinned.append((index + 1, sanitized(value, limit: 60)))
        }
        if let first = unpinned.first {
            add("workflow_unpinned_action", "medium",
                "line \(first.line): \(first.ref) is not pinned to a commit SHA" + (unpinned.count > 1 ? " (+\(unpinned.count - 1) more)" : ""))
        }
        return findings
    }

    // MARK: Rules

    private static func regex(_ pattern: String, caseInsensitive: Bool = true) -> NSRegularExpression {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: pattern, options: caseInsensitive ? [.caseInsensitive] : [])
    }

    private static func matches(_ patterns: [NSRegularExpression], _ lowercasedLine: String) -> Bool {
        let range = NSRange(lowercasedLine.startIndex..., in: lowercasedLine)
        return patterns.contains { $0.firstMatch(in: lowercasedLine, options: [], range: range) != nil }
    }

    /// "ignore previous instructions", "do not tell the user" and their Japanese forms.
    private static let overridePatterns: [NSRegularExpression] = [
        regex(#"(ignore|disregard|forget)\s+(all\s+|any\s+|the\s+|your\s+)*(previous|prior|above|earlier|system)\s+(instructions?|prompts?|rules?|messages?)"#),
        regex(#"(do not|don't|never|dont)\s+(tell|inform|mention|reveal|show)\s+(this\s+to\s+)?(the\s+)?user"#),
        regex(#"without\s+(telling|informing|notifying|alerting)\s+(the\s+)?user"#),
        regex(#"(以前|これまで|上記|先ほど)の?(指示|命令|ルール|プロンプト)を?(すべて|全て)?(無視|忘れ)"#),
        regex(#"ユーザー(に)?は?(言わ|伝え|知らせ|見せ|気づか)(ない|せない)で"#),
        regex(#"<\|im_(start|end)\|>"#),
    ]

    /// Like `matches`, but a phrase that is itself quoted ("ignore previous instructions" in quotation
    /// marks, 「…」 or backticks) is a mention, as in a warning or a list of examples, not an order.
    private static func matchesUnquoted(_ patterns: [NSRegularExpression], _ lowercasedLine: String) -> Bool {
        let whole = NSRange(lowercasedLine.startIndex..., in: lowercasedLine)
        let openers: Set<Character> = ["\"", "'", "`", "「", "『", "“", "‘", "«", "("]
        for pattern in patterns {
            for match in pattern.matches(in: lowercasedLine, options: [], range: whole) {
                guard let range = Range(match.range, in: lowercasedLine) else { continue }
                let before = lowercasedLine[..<range.lowerBound].last
                if let before, openers.contains(before) { continue }
                return true
            }
        }
        return false
    }

    /// Fetch-and-run: `curl … | sh`, `bash <(curl …)`, `iex (irm …)`.
    private static let remoteExecPatterns: [NSRegularExpression] = [
        regex(#"(curl|wget)\b[^\n|]*\|\s*(sudo\s+)?(ba|z|da|k)?sh\b"#),
        regex(#"(curl|wget)\b[^\n|]*\|\s*(sudo\s+)?(python[0-9.]*|node|perl|ruby)\b"#),
        regex(#"(ba|z)?sh\s+<\(\s*(curl|wget)"#),
        regex(#"(iex|invoke-expression)\b.{0,40}(iwr|irm|invoke-webrequest|invoke-restmethod|downloadstring)"#),
        regex(#"(iwr|irm|invoke-webrequest|invoke-restmethod)\b[^\n|]*\|\s*(iex|invoke-expression)"#),
    ]

    /// Decode-and-run.
    private static let encodedExecPatterns: [NSRegularExpression] = [
        regex(#"base64\s+(-d|-D|--decode)\b[^\n|]*\|\s*(sudo\s+)?(ba|z|da|k)?sh\b"#),
        regex(#"base64\s+(-d|-D|--decode)\b[^\n|]*\|\s*(python[0-9.]*|node|perl|ruby)\b"#),
        regex(#"(exec|eval)\s*\(\s*(base64\.b64decode|atob|buffer\.from)"#),
        regex(#"(frombase64string|\[convert\]::frombase64)"#),
    ]

    /// Files and stores that hold keys, tokens, cookies and passwords.
    private static let credentialPatterns: [NSRegularExpression] = [
        regex(#"\.ssh/(id_[a-z0-9_]+|authorized_keys)\b"#),
        regex(#"\.aws/(credentials|config)\b"#),
        regex(#"\.config/gcloud\b|\.azure/|\.kube/config|\.docker/config\.json|\.npmrc\b|\.netrc\b|\.git-credentials\b|\.pypirc\b"#),
        regex(#"library/keychains|security\s+(find|dump)-(generic|internet)-password|login\.keychain"#),
        regex(#"login data\b|cookies\.sqlite|key[34]\.db|logins\.json"#),
        regex(#"(cat|type|read|print|cp|copy|upload|send)\s+[^\n]*\.env(\s|$|["'])"#),
        regex(#"\.openclaw/(credentials|openclaw\.json)|\.claude\.json|\.gnupg/"#),
    ]

    /// Hosts that attackers use as a drop site or a quick tunnel (public, widely documented).
    private static let exfilHosts = [
        "discord.com/api/webhooks", "discordapp.com/api/webhooks", "hooks.slack.com/services", "api.telegram.org/bot",
        "pastebin.com", "paste.ee", "transfer.sh", "webhook.site", "requestbin", "pipedream.net", "interact.sh",
        "oast.pro", "oast.live", "oast.site", "oast.online", "oast.fun", "oast.me", "burpcollaborator", "ngrok.io", "ngrok-free.app", "trycloudflare.com", "file.io", "anonfiles",
    ]

    /// A host counts only at the start of a name: `oast.` must not match `toast.` or `coast.`.
    private static let exfilHostPatterns: [(String, NSRegularExpression)] = exfilHosts.map {
        ($0, regex("(?<![a-z0-9-])" + NSRegularExpression.escapedPattern(for: $0)))
    }

    private static func matchedExfilHost(_ lowercasedLine: String) -> String? {
        let range = NSRange(lowercasedLine.startIndex..., in: lowercasedLine)
        return exfilHostPatterns.first { $0.1.firstMatch(in: lowercasedLine, options: [], range: range) != nil }?.0
    }

    /// Sending local data to a remote URL.
    /// Case-sensitive and matched against the original line: `-F` (form upload) and `-f` (fail) differ.
    private static let uploadPatterns: [NSRegularExpression] = [
        regex(#"curl\b[^\n]*\s(-d|--data[a-z-]*|-F|--form|-T|--upload-file)\b[^\n]*https?://"#, caseInsensitive: false),
        regex(#"\b(nc|ncat|netcat)\s+[^\n]*[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"#, caseInsensitive: false),
        regex(#"requests\.(post|put)\s*\(\s*['"]https?://"#, caseInsensitive: false),
    ]

    /// Cron, launchd, systemd, shell profiles, authorized_keys.
    private static let persistencePatterns: [NSRegularExpression] = [
        regex(#"\bcrontab\s+-(\s|$)|\(crontab\s+-l"#),
        regex(#"launchctl\s+(load|bootstrap|enable)\b|library/launchagents|library/launchdaemons"#),
        regex(#"systemctl\s+(--user\s+)?enable\b"#),
        regex(#">>\s*~?/?[^\s]*\.(bashrc|zshrc|zprofile|profile|bash_profile)\b"#),
        regex(#">>?\s*~?/?[^\s]*authorized_keys"#),
    ]

    /// A line that forbids the thing it mentions ("never read ~/.ssh") is not an instruction to do it.
    private static let negationWords = [
        "never", "do not", "don't", "dont", "must not", "should not", "avoid", "forbid", "prohibit", "deny", "denied",
        "disallow", "refuse", "not allowed", "禁止", "しないで", "しない", "読まない", "触らない", "触れない", "使わない", "避け",
    ]

    private static func hasNegation(_ lowercasedLine: String) -> Bool {
        negationWords.contains { lowercasedLine.contains($0) }
    }

    // MARK: Helpers

    /// For each line, whether it is (partly) inside an HTML comment (`<!-- … -->`), which a
    /// rendered Markdown page does not show.
    static func htmlCommentLines(_ lines: [String]) -> [Bool] {
        var open = false
        var out: [Bool] = []
        for line in lines {
            var inside = open
            var rest = Substring(line)
            while !rest.isEmpty {
                if open {
                    inside = true
                    if let end = rest.range(of: "-->") { rest = rest[end.upperBound...]; open = false } else { rest = "" }
                } else if let start = rest.range(of: "<!--") {
                    inside = true
                    rest = rest[start.upperBound...]
                    open = true
                } else { break }
            }
            out.append(inside)
        }
        return out
    }

    /// Unicode tag characters (U+E0000-E007F) render as nothing, yet a model reads them as
    /// ASCII text. The legitimate use is the end of an emoji flag sequence after U+1F3F4.
    static func hiddenTagText(_ text: String) -> (line: Int, count: Int, decoded: String)? {
        var line = 1
        var firstLine: Int?
        var count = 0
        var decoded = ""
        var inFlagSequence = false
        for scalar in text.unicodeScalars {
            let v = scalar.value
            if v == 0x0A { line += 1 }
            if v == 0x1F3F4 { inFlagSequence = true }
            if (0xE0000...0xE007F).contains(v) {
                if inFlagSequence { continue }
                count += 1
                if firstLine == nil { firstLine = line }
                if (0xE0020...0xE007E).contains(v), let ascii = UnicodeScalar(v - 0xE0000) { decoded.unicodeScalars.append(ascii) }
            } else if v != 0x1F3F4 {
                inFlagSequence = false
            }
        }
        guard let first = firstLine, count > 0 else { return nil }
        return (first, count, decoded)
    }

    /// Zero-width and bidirectional-control characters. A joiner / non-joiner (U+200C, U+200D)
    /// is ordinary in emoji and in several scripts and is not counted; a byte-order mark at the
    /// very start of the file is not counted either.
    static func firstInvisible(_ text: String) -> (line: Int, scalar: UInt32, count: Int)? {
        var line = 1
        var first: (Int, UInt32)?
        var count = 0
        var index = 0
        for scalar in text.unicodeScalars {
            let v = scalar.value
            if v == 0x0A { line += 1 }
            let invisible = v == 0x200B || v == 0x2060 || (v == 0xFEFF && index > 0)
                || (0x202A...0x202E).contains(v) || (0x2066...0x2069).contains(v)
            if invisible {
                count += 1
                if first == nil { first = (line, v) }
            }
            index += 1
        }
        guard let f = first else { return nil }
        return (f.0, f.1, count)
    }

    private static func firstURLHost(in line: String) -> String? {
        guard let range = line.range(of: #"https?://[^/\s'"<>)]+"#, options: .regularExpression) else { return nil }
        var host = String(line[range])
        host = host.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "")
        if let at = host.lastIndex(of: "@") { host = String(host[host.index(after: at)...]) }
        if let colon = host.lastIndex(of: ":"), !host.hasPrefix("[") { host = String(host[..<colon]) }
        return host.isEmpty ? nil : host
    }

    private static func isIPAddress(_ host: String) -> Bool {
        let parts = host.split(separator: ".")
        return parts.count == 4 && parts.allSatisfy { Int($0) != nil } || host.hasPrefix("[")
    }

    /// Executables and bytecode: Mach-O, ELF, PE, Java class, Python bytecode (by extension and magic).
    private static func isPrecompiled(_ data: Data, ext: String) -> Bool {
        if binaryExtensions.contains(ext) { return true }
        let head = [UInt8](data.prefix(4))
        guard head.count == 4 else { return false }
        let magics: [[UInt8]] = [
            [0xFE, 0xED, 0xFA, 0xCE], [0xFE, 0xED, 0xFA, 0xCF], [0xCE, 0xFA, 0xED, 0xFE], [0xCF, 0xFA, 0xED, 0xFE],
            [0xCA, 0xFE, 0xBA, 0xBE], [0x7F, 0x45, 0x4C, 0x46],
        ]
        if magics.contains(head) { return true }
        return head[0] == 0x4D && head[1] == 0x5A && data.prefix(8192).contains(0) // "MZ" (PE) that is not text
    }

    /// Printable, bounded text for anything that came from a file.
    static func sanitized(_ text: String, limit: Int = 60) -> String {
        let cleaned = String(text.unicodeScalars.filter { $0.value >= 0x20 && $0.value != 0x7F && !(0x200B...0x200F).contains($0.value) && !(0x202A...0x202E).contains($0.value) && !(0x2066...0x2069).contains($0.value) }.map(Character.init))
        return cleaned.count > limit ? String(cleaned.prefix(limit)) + "…" : cleaned
    }

    // MARK: - Names, padding, encoded text, tool grants

    /// The names a file is known by: its own name, a skill's folder name and the `name:` of its front
    /// matter. Each is checked for lookalike letters (a Cyrillic `а` in `reаd_file`).
    static func identifiers(of path: String, frontMatter front: [String]?) -> [(String, String)] {
        var out: [(String, String)] = []
        let url = URL(fileURLWithPath: path)
        let stem = url.deletingPathExtension().lastPathComponent
        if !stem.isEmpty { out.append(("file name", stem)) }
        if url.lastPathComponent.lowercased() == "skill.md" {
            let folder = url.deletingLastPathComponent().lastPathComponent
            if !folder.isEmpty { out.append(("skill folder name", folder)) }
        }
        if let front, let name = frontMatterValue(front, keys: ["name"]), !name.isEmpty { out.append(("front matter name", name)) }
        return out
    }

    /// Whether `name` has letters of the Latin alphabet and of another alphabet that has lookalikes
    /// of Latin letters (Cyrillic, Greek, Armenian). A name in Japanese, or Latin with kana, is fine.
    static func mixedScript(_ name: String) -> (script: String, scalar: UInt32)? {
        var hasLatin = false
        var other: (String, UInt32)?
        for scalar in name.unicodeScalars where scalar.properties.isAlphabetic {
            let v = scalar.value
            if (0x41...0x5A).contains(v) || (0x61...0x7A).contains(v) || ((0xC0...0x24F).contains(v) && v != 0xD7 && v != 0xF7) || (0x1E00...0x1EFF).contains(v) {
                hasLatin = true
            } else if other == nil {
                if (0x400...0x52F).contains(v) || (0x2DE0...0x2DFF).contains(v) || (0xA640...0xA69F).contains(v) { other = ("Cyrillic", v) }
                else if (0x370...0x3FF).contains(v) || (0x1F00...0x1FFF).contains(v) { other = ("Greek", v) }
                else if (0x530...0x58F).contains(v) { other = ("Armenian", v) }
            }
        }
        guard hasLatin, let other else { return nil }
        return (other.0, other.1)
    }

    /// Blanks that take no room on screen the way text does: space, tab, no-break and the wide spaces.
    private static func isPaddingScalar(_ v: UInt32) -> Bool {
        v == 0x20 || v == 0x09 || v == 0xA0 || v == 0x1680 || (0x2000...0x200A).contains(v) || v == 0x202F || v == 0x205F || v == 0x3000
    }

    static let horizontalPaddingRun = 100
    static let verticalPaddingLines = 30

    /// A run of at least `horizontalPaddingRun` blanks in front of text on the same line, or at least
    /// `verticalPaddingLines` empty lines in front of text. An editor shows neither the text that
    /// follows (it is far to the right or far below) nor any sign that it exists.
    static func whitespacePaddings(_ lines: [String]) -> [(line: Int, detail: String)] {
        var out: [(line: Int, detail: String)] = []
        var blankStart: Int?
        var blankCount = 0
        for (index, line) in lines.enumerated() {
            var run = 0
            var hasText = false
            var horizontal: Int?
            for scalar in line.unicodeScalars {
                let v = scalar.value
                if isPaddingScalar(v) { run += 1; continue }
                if v == 0x0D { continue }
                hasText = true
                if run >= horizontalPaddingRun, horizontal == nil { horizontal = run }
                run = 0
            }
            if let horizontal { out.append((index + 1, "\(horizontal) blanks before text")) }
            if hasText {
                if blankCount >= verticalPaddingLines, let start = blankStart { out.append((start + 1, "\(blankCount) empty lines before text")) }
                blankStart = nil
                blankCount = 0
            } else {
                if blankStart == nil { blankStart = index }
                blankCount += 1
            }
        }
        return out
    }

    private static let base64BlobPattern = regex(#"[A-Za-z0-9+/]{60,}={0,2}"#, caseInsensitive: false)
    private static let dataTextURIPattern = regex(#"data:text/[a-z0-9.+-]+(?:;[a-z0-9=._-]+)*;base64,([A-Za-z0-9+/]+={0,2})"#)

    /// Encoded text in one line: a `data:text/…;base64,` URI, or a base64 run of 60 characters or
    /// more that decodes to readable UTF-8 text (the chance of that for anything else, such as a
    /// hash, a key or an image, is negligible). `rule` names what the decoded text itself would
    /// trip if it were written out. The decoded text is never copied into a result.
    static func encodedTexts(in line: String) -> [(length: Int, isDataURI: Bool, rule: String?)] {
        var out: [(length: Int, isDataURI: Bool, rule: String?)] = []
        let whole = NSRange(line.startIndex..., in: line)
        var covered: [Range<String.Index>] = []
        for match in dataTextURIPattern.matches(in: line, options: [], range: whole) {
            guard let full = Range(match.range, in: line), let payload = Range(match.range(at: 1), in: line) else { continue }
            covered.append(full)
            out.append((line[payload].count, true, decodedText(String(line[payload])).flatMap(wording(in:))))
        }
        for match in base64BlobPattern.matches(in: line, options: [], range: whole) {
            guard let range = Range(match.range, in: line), !covered.contains(where: { $0.overlaps(range) }) else { continue }
            guard let text = decodedText(String(line[range])) else { continue }
            out.append((line[range].count, false, wording(in: text)))
        }
        return out
    }

    /// Base64 → UTF-8 text with no control characters (other than line breaks and tab), at least 24 bytes.
    private static func decodedText(_ encoded: String) -> String? {
        var body = encoded.trimmingCharacters(in: CharacterSet(charactersIn: "="))
        if body.count % 4 == 1 { body.removeLast() }
        body += String(repeating: "=", count: (4 - body.count % 4) % 4)
        guard let data = Data(base64Encoded: body), data.count >= 24 else { return nil }
        // The run may end inside a multi-byte character when text follows it directly.
        guard let text = (0...3).lazy.compactMap({ String(data: data.dropLast($0), encoding: .utf8) }).first else { return nil }
        for scalar in text.unicodeScalars where scalar.value < 0x20 && ![0x09, 0x0A, 0x0D].contains(scalar.value) { return nil }
        return text
    }

    /// What kind of rule decoded text trips, as a short phrase; nil if none.
    private static func wording(in text: String) -> String? {
        for raw in text.components(separatedBy: "\n") {
            let lower = raw.lowercased()
            if matchesUnquoted(overridePatterns, lower) { return "instruction-override wording" }
            if matches(remoteExecPatterns, lower) || matches(encodedExecPatterns, lower) { return "a command that downloads or decodes and runs code" }
            if matches(credentialPatterns, lower) { return "a reference to a credential file" }
            if matchedExfilHost(lower) != nil { return "a drop-site address" }
        }
        return nil
    }

    /// Lines of a Markdown link-reference definition used as a comment (`[//]: # (text)`,
    /// `[comment]: <> "text"`). Markdown renders none of it.
    static func markdownCommentLines(_ lines: [String]) -> [Bool] {
        lines.map { markdownCommentPattern.firstMatch(in: $0, options: [], range: NSRange($0.startIndex..., in: $0)) != nil }
    }

    private static let markdownCommentPattern = regex(#"^\s*\[[^\]]+\]:\s*(?:#|<>)\s*[(\"'].*$"#, caseInsensitive: false)

    /// The YAML front matter of a Markdown file (`---` … `---` at the very top), without the fences.
    static func frontMatter(_ lines: [String]) -> [String]? {
        func fence(_ line: String) -> Bool {
            line.replacingOccurrences(of: "\u{FEFF}", with: "").trimmingCharacters(in: .whitespacesAndNewlines) == "---"
        }
        guard let first = lines.first, fence(first) else { return nil }
        for index in 1..<min(lines.count, 200) where fence(lines[index]) || lines[index].trimmingCharacters(in: .whitespacesAndNewlines) == "..." {
            return Array(lines[1..<index])
        }
        return nil
    }

    /// The value of a top-level front-matter key, flattened to one string: an inline value, an inline
    /// list (`[a, b]`) or a block list (`- a` lines) joined by commas. Matching is case-insensitive.
    static func frontMatterValue(_ front: [String], keys: [String]) -> String? {
        for (index, raw) in front.enumerated() {
            guard !raw.hasPrefix(" "), !raw.hasPrefix("\t"), let colon = raw.firstIndex(of: ":") else { continue }
            let key = raw[..<colon].trimmingCharacters(in: .whitespaces).lowercased()
            guard keys.contains(key) else { continue }
            var value = raw[raw.index(after: colon)...].trimmingCharacters(in: .whitespacesAndNewlines)
            if value.isEmpty || value == "|" || value == ">" {
                var items: [String] = []
                var next = index + 1
                while next < front.count {
                    let line = front[next]
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    next += 1
                    if trimmed.isEmpty { continue }
                    guard line.hasPrefix(" ") || line.hasPrefix("\t") || trimmed.hasPrefix("-") else { break }
                    items.append(trimmed.hasPrefix("-") ? String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces) : trimmed)
                }
                value = items.joined(separator: ",")
            } else if value.hasPrefix("["), value.hasSuffix("]") {
                value = String(value.dropFirst().dropLast())
            }
            if value.count >= 2, let q = value.first, q == "\"" || q == "'", value.last == q { value = String(value.dropFirst().dropLast()) }
            return value
        }
        return nil
    }

    /// Splits an `allowed-tools` value into grants. Commas and blanks separate grants, except inside
    /// a specifier: `Bash(git status:*)` is one grant, and a parenthesis inside a specifier is a
    /// literal character (the specifier ends at a `)` followed by a separator or the end).
    static func splitGrants(_ value: String) -> [String] {
        var grants: [String] = []
        var current = ""
        var inSpecifier = false
        let chars = Array(value)
        for (i, c) in chars.enumerated() {
            if inSpecifier {
                current.append(c)
                if c == ")" {
                    let next = i + 1 < chars.count ? chars[i + 1] : nil
                    if next == nil || next == "," || next!.isWhitespace { inSpecifier = false }
                }
            } else if c == "(" {
                inSpecifier = true
                current.append(c)
            } else if c == "," || c.isWhitespace {
                if !current.isEmpty { grants.append(current); current = "" }
            } else {
                current.append(c)
            }
        }
        if !current.isEmpty { grants.append(current) }
        return grants.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"'")) }.filter { !$0.isEmpty }
    }

    /// Commands that run whatever they are given: a shell, an interpreter, a package runner, a
    /// downloader, a remote shell, a privilege switch. `Bash(python3:*)` is no narrower than `Bash`.
    private static let arbitraryExecCommands: Set<String> = [
        "sh", "bash", "zsh", "dash", "ksh", "fish", "csh", "tcsh", "python", "python2", "python3", "node", "deno", "bun",
        "perl", "ruby", "php", "lua", "eval", "exec", "sudo", "doas", "su", "env", "xargs", "curl", "wget", "nc", "ncat",
        "netcat", "ssh", "scp", "sftp", "osascript", "npx", "bunx", "uvx", "pipx", "pwsh", "powershell", "cmd",
    ]

    /// The grant itself if it allows any shell command: `*`, `Bash`, `Bash(*)`, `Bash(:*)`, or a
    /// wildcard on a command that runs anything (`Bash(curl:*)`, `Bash(python3 *)`). A grant narrowed
    /// to a fixed script or subcommand (`Bash(python3 scripts/lint.py:*)`, `Bash(git status:*)`) is fine.
    static func broadGrant(_ grant: String) -> String? {
        if grant == "*" || grant == "**" { return grant }
        var name = grant
        var specifier: String?
        if let open = grant.firstIndex(of: "("), grant.hasSuffix(")") {
            name = String(grant[..<open])
            specifier = String(grant[grant.index(after: open)..<grant.index(before: grant.endIndex)])
        }
        guard ["bash", "shell"].contains(name.lowercased()) else { return nil }
        guard let specifier else { return grant }
        var base = specifier.trimmingCharacters(in: .whitespaces)
        if base.isEmpty || ["*", "**", ":*", "*:*"].contains(base) { return grant }
        guard let suffix = [":*", " *", "*"].first(where: { base.hasSuffix($0) }) else { return nil }
        base = String(base.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
        guard !base.contains(" ") else { return nil }
        return arbitraryExecCommands.contains((base as NSString).lastPathComponent.lowercased()) ? grant : nil
    }

    // MARK: - OpenClaw configuration

    /// Placeholder-looking or short values are not echoed; only a length is.
    static func auditOpenClawConfig(_ file: FileInput) -> [Finding]? {
        guard let root = (try? JSONSerialization.jsonObject(with: file.data, options: [.json5Allowed])) as? [String: Any] else { return nil }
        var findings: [Finding] = []
        func add(_ id: String, _ severity: String, _ detail: String) {
            findings.append(Finding(id: id, severity: severity, area: "openclaw", file: file.path, detail: detail, message: message(id)))
        }
        let gateway = root["gateway"] as? [String: Any] ?? [:]
        let auth = gateway["auth"] as? [String: Any] ?? [:]
        let bind = (gateway["bind"] as? String)?.lowercased() ?? "loopback"
        let wide = ["lan", "tailnet", "custom", "0.0.0.0", "::"].contains(bind)
        let mode = (auth["mode"] as? String)?.lowercased()

        if mode == "none" {
            add("openclaw_auth_disabled", wide ? "high" : "medium", "gateway.auth.mode is none, gateway.bind is \(sanitized(bind))")
        } else if wide {
            add("openclaw_wide_bind", "medium", "gateway.bind is \(sanitized(bind)) (default loopback)")
        }
        if let token = auth["token"] as? String, !token.isEmpty, token.count < 24, mode == nil || mode == "token" {
            add("openclaw_weak_token", "high", "gateway.auth.token is \(token.count) characters (at least 24 are expected)")
        }
        if let ui = gateway["controlUi"] as? [String: Any], let origins = ui["allowedOrigins"] as? [Any],
           origins.contains(where: { ($0 as? String)?.trimmingCharacters(in: .whitespaces) == "*" }) {
            add("openclaw_origin_wildcard", "high", "gateway.controlUi.allowedOrigins contains *")
        }
        if let proxies = gateway["trustedProxies"] as? [Any],
           let broad = proxies.compactMap({ $0 as? String }).first(where: { ["*", "0.0.0.0/0", "::/0"].contains($0.trimmingCharacters(in: .whitespaces)) }) {
            add("openclaw_broad_trusted_proxy", "high", "gateway.trustedProxies contains \(sanitized(broad))")
        }
        var loosened: [String] = []
        if (gateway["allowRealIpFallback"] as? Bool) == true { loosened.append("gateway.allowRealIpFallback") }
        if let nodes = gateway["nodes"] as? [String: Any], let pairing = nodes["pairing"] as? [String: Any],
           let cidrs = pairing["autoApproveCidrs"] as? [Any], !cidrs.isEmpty { loosened.append("gateway.nodes.pairing.autoApproveCidrs") }
        if let trusted = auth["trustedProxy"] as? [String: Any], (trusted["allowLoopback"] as? Bool) == true { loosened.append("gateway.auth.trustedProxy.allowLoopback") }
        if !loosened.isEmpty { add("openclaw_proxy_trust_loosened", "medium", loosened.joined(separator: ", ")) }

        let dangerous = dangerousPaths(in: root)
        if !dangerous.isEmpty {
            add("openclaw_dangerous_flag", "high", dangerous.prefix(8).joined(separator: ", ") + (dangerous.count > 8 ? " (+\(dangerous.count - 8) more)" : ""))
        }

        let open = openDMPaths(in: root)
        if !open.isEmpty {
            add("openclaw_open_dm", "medium", open.prefix(8).joined(separator: ", ") + (open.count > 8 ? " (+\(open.count - 8) more)" : ""))
        }
        if let discovery = root["discovery"] as? [String: Any], let mdns = discovery["mdns"] as? [String: Any],
           (mdns["mode"] as? String)?.lowercased() == "full" {
            add("openclaw_mdns_full", "medium", "discovery.mdns.mode is full (default minimal)")
        }
        if let security = root["security"] as? [String: Any], let audit = security["audit"] as? [String: Any] {
            let suppressions = audit["suppressions"]
            if (suppressions as? [Any])?.isEmpty == false || (suppressions as? [String: Any])?.isEmpty == false {
                add("openclaw_audit_suppressed", "medium", "security.audit.suppressions is not empty")
            }
        }
        return findings
    }

    /// Paths of switches the OpenClaw documentation names as dangerous and turned on:
    /// every `dangerously…` key set to true (the retired `dangerouslyDisableDeviceAuth` has no effect and is ignored),
    /// `allowUnsafeExternalContent`, `tools.exec.applyPatch.workspaceOnly=false` and
    /// `plugins.entries.acpx.config.permissionMode=approve-all`.
    static func dangerousPaths(in root: [String: Any]) -> [String] {
        var out: [String] = []
        func walk(_ value: Any, _ path: String) {
            if let dict = value as? [String: Any] {
                for (key, child) in dict.sorted(by: { $0.key < $1.key }) {
                    let childPath = path.isEmpty ? key : "\(path).\(key)"
                    if key.hasPrefix("dangerously"), key != "dangerouslyDisableDeviceAuth", (child as? Bool) == true { out.append(sanitized(childPath, limit: 120)) }
                    else if key == "allowUnsafeExternalContent", (child as? Bool) == true { out.append(sanitized(childPath, limit: 120)) }
                    else if childPath == "tools.exec.applyPatch.workspaceOnly", (child as? Bool) == false { out.append(childPath) }
                    else if childPath == "plugins.entries.acpx.config.permissionMode", (child as? String) == "approve-all" { out.append(childPath) }
                    else { walk(child, childPath) }
                }
            } else if let array = value as? [Any] {
                for (index, child) in array.enumerated() { walk(child, "\(path)[\(index)]") }
            }
        }
        walk(root, "")
        return out
    }

    /// `dmPolicy: "open"` / `groupPolicy: "open"` / `dm.policy: "open"`, and an `allowFrom` that contains `*`.
    static func openDMPaths(in root: [String: Any]) -> [String] {
        var out: [String] = []
        func walk(_ value: Any, _ path: String) {
            if let dict = value as? [String: Any] {
                for (key, child) in dict.sorted(by: { $0.key < $1.key }) {
                    let childPath = path.isEmpty ? key : "\(path).\(key)"
                    if ["dmPolicy", "groupPolicy"].contains(key), (child as? String)?.lowercased() == "open" { out.append(sanitized(childPath, limit: 120)) }
                    else if key == "policy", path.hasSuffix(".dm"), (child as? String)?.lowercased() == "open" { out.append(sanitized(childPath, limit: 120)) }
                    else if key == "allowFrom", let list = child as? [Any], list.contains(where: { ($0 as? String) == "*" }) { out.append(sanitized(childPath, limit: 120)) }
                    else { walk(child, childPath) }
                }
            } else if let array = value as? [Any] {
                for (index, child) in array.enumerated() { walk(child, "\(path)[\(index)]") }
            }
        }
        walk(root, "")
        return out
    }

    // MARK: - Messages

    /// The short card title of a finding id. Japanese is the source text.
    static func title(_ id: String) -> String {
        switch id {
        case "hidden_tag_characters": return loc("画面に見えない指示が隠されています(タグ文字)")
        case "invisible_characters": return loc("表示されない文字が含まれています")
        case "override_instruction": return loc("指示の上書き・隠し事を求める文があります")
        case "remote_script_exec": return loc("ネットのスクリプトをそのまま実行します")
        case "encoded_payload_exec": return loc("符号化した文字列を復号して実行します")
        case "credential_access": return loc("秘密を含むファイルを扱う記述があります")
        case "credential_exfil_shape": return loc("秘密の参照と外部送信が同じファイルにあります")
        case "exfil_endpoint": return loc("データの受け口によく使われる宛先があります")
        case "persistence_instruction": return loc("再起動後も残る仕掛けを作る記述があります")
        case "skill_precompiled_code": return loc("スキルに読めないコンパイル済みコードがあります")
        case "agent_file_writable": return loc("所有者以外も書き込めるファイルです")
        case "homoglyph_name": return loc("名前に見た目が似た別の文字が混ざっています")
        case "whitespace_padding": return loc("空白や空行の連続で、続きが画面の外に押し出されています")
        case "hidden_encoded_text": return loc("符号化された文章が埋め込まれています")
        case "skill_broad_tool_grant": return loc("ツールの許可（allowed-tools）が広すぎます")
        case "agent_file_changed": return loc("確認済みにした後で内容が変わっています")
        case "agent_file_added": return loc("確認済みにした後で増えたファイルです")
        case "mcp_server_changed": return loc("確認済みにした後で MCP サーバーの設定が変わっています")
        case "mcp_server_added": return loc("確認済みにした後で MCP サーバーが増えています")
        case "openclaw_auth_disabled": return loc("OpenClaw のゲートウェイの認証が無効です")
        case "openclaw_wide_bind": return loc("OpenClaw のゲートウェイが外から届く状態です")
        case "openclaw_weak_token": return loc("OpenClaw のトークンが短すぎます")
        case "openclaw_origin_wildcard": return loc("OpenClaw のコントロール画面がすべてのサイトを許可しています")
        case "openclaw_dangerous_flag": return loc("OpenClaw の「危険」スイッチがオンです")
        case "openclaw_broad_trusted_proxy": return loc("OpenClaw がすべての相手をプロキシとして信頼しています")
        case "openclaw_proxy_trust_loosened": return loc("OpenClaw のプロキシ・ノードの信頼が広げられています")
        case "openclaw_open_dm": return loc("OpenClaw が誰からでもメッセージを受け付けます")
        case "openclaw_mdns_full": return loc("OpenClaw が詳しい情報をネットワークに広告しています")
        case "openclaw_audit_suppressed": return loc("OpenClaw の自己診断の指摘が非表示になっています")
        case "openclaw_loose_permissions": return loc("OpenClaw の設定が他のユーザーに読める権限です")
        case "editor_auto_run_task": return loc("フォルダを開くと自動で実行されるタスクがあります")
        case "workflow_pwn_request": return loc("ワークフローが、プルリクエストのコードをシークレットのある環境で実行します")
        case "workflow_expression_injection": return loc("ワークフローが、他人の書いた文字列をそのままスクリプトに入れています")
        case "workflow_unpinned_action": return loc("ワークフローが、コミットで固定していないアクションを使っています")
        case "agent_settings_hook": return loc("Claude Code の設定に、イベントのたびに実行されるフックがあります")
        case "agent_settings_bypass": return loc("Claude Code の設定が、確認なしですべてを実行する状態です")
        case "agent_settings_broad_allow": return loc("Claude Code の設定が、どんなコマンドも確認なしで許可しています")
        case "agent_settings_endpoint_override": return loc("Claude Code の設定が、API の接続先を別のホストに変えています")
        case "agent_settings_weakened": return loc("確認済みにした後で、Claude Code の設定が緩くなっています")
        case "agent_settings_writable": return loc("設定ファイルを、すべてのユーザーが書き換えられます")
        default: return id
        }
    }

    /// The localized explanation of a finding id. Japanese is the source text.
    static func message(_ id: String) -> String {
        switch id {
        case "hidden_tag_characters":
            return loc("このファイルには、画面に何も表示されない Unicode のタグ文字が含まれています。人の目には見えませんが、AI はこれを文字として読めるため、見えない指示を仕込む手口に使われます。意図して入れたものでなければ、その部分を取り除いてください。")
        case "invisible_characters":
            return loc("このファイルには、ゼロ幅文字や文字の向きを変える制御文字など、画面に表示されない文字が含まれています。見えない文字で語句を隠して検査をすり抜ける手口に使われます。意図して入れたものでなければ取り除いてください。")
        case "override_instruction":
            return loc("「以前の指示を無視する」「ユーザーには伝えない」といった、AI に対する指示の上書きや隠し事を求める書き方があります。注意喚起や例として書かれた文であれば問題ありませんが、AI への命令として書かれていないか確認してください。")
        case "remote_script_exec":
            return loc("ネットからスクリプトを取得して、そのまま実行する書き方（curl … | sh など）があります。取得先の内容が後から差し替えられると、AI がそれを実行してしまいます。中身を確認できる形に変えるか、取得先が信頼できるか確認してください。")
        case "encoded_payload_exec":
            return loc("base64 などで符号化した文字列を復号して、そのまま実行する書き方があります。何を実行するのか読めなくするために使われる手口です。復号した内容を確認し、意図したものでなければ取り除いてください。")
        case "credential_access":
            return loc("SSH 鍵、クラウドの認証情報、パスワード保存場所、ブラウザの Cookie など、秘密を含むファイルを扱う記述があります。AI にそれらを読ませる指示になっていないか確認してください。")
        case "credential_exfil_shape":
            return loc("同じファイルに、秘密を含むファイルの参照と、外部へ送る（アップロード・受け口サービス）記述の両方があります。秘密を持ち出す指示の形に似ています。内容を読んで、意図したものか確認してください。")
        case "exfil_endpoint":
            return loc("Webhook やファイル共有、トンネルなど、データの受け口によく使われるサービスの宛先が書かれています。そこへ何を送る記述なのか確認してください。")
        case "persistence_instruction":
            return loc("cron・launchd・systemd・シェルの起動ファイル・authorized_keys など、再起動後も残る仕掛けを作る記述があります。AI にそれらを設定させる指示になっていないか確認してください。")
        case "skill_precompiled_code":
            return loc("このスキルには、人が読めないコンパイル済みのコード（実行ファイルやバイトコード）が入っています。中身を確認できないため、出どころが確かな場合を除いて使わないでください。")
        case "agent_file_writable":
            return loc("このファイルは、所有者以外も書き込める権限になっています。他のユーザーやプロセスが指示を書き換えれば、次に AI が読んだときにその内容に従います。chmod go-w で書き込み権限を外してください。")
        case "homoglyph_name":
            return loc("スキルやファイルの名前に、ラテン文字とよく似た別の文字（キリル文字やギリシャ文字など）が混ざっています。見た目は本物の名前と区別がつきませんが、実際は別の名前なので、本物になりすます手口に使われます。名前を打ち直して、混ざっている文字を取り除いてください。")
        case "whitespace_padding":
            return loc("空白や空行が異常に長く続いた後ろに、文章が置かれています。エディタで開いても続きは画面の外にあって見えず、そこに指示を隠す手口に使われます。その位置まで移動して、後ろに書かれている内容を確認し、不要な空白は取り除いてください。")
        case "hidden_encoded_text":
            return loc("base64 などで符号化された文章（data:text/… の形を含みます）が埋め込まれています。符号化されていると人は中身を読めませんが、AI は復号して扱える場合があります。復号した内容を確認し、意図したものでなければ取り除いてください。")
        case "skill_broad_tool_grant":
            return loc("このファイルの allowed-tools が、どんなシェルコマンドでも実行できる許可（Bash 全体や *）、または任意のコードを実行できるコマンドの許可（sh・python・curl など）になっています。動いている間は、確認なしで何でも実行されることになります。使うコマンドだけに絞った書き方（例: Bash(git status:*)）に変えてください。")
        case "agent_file_changed":
            return loc("このファイルは、確認済みにした時点から内容が変わっています。自分で編集した場合は問題ありません。覚えのない変更なら、差し替えられた可能性があるので、内容を確認してください。確認できたら、確認済みにし直してください。")
        case "agent_file_added":
            return loc("このファイルは、確認済みにした時点では存在しませんでした。自分でスキルや設定を追加した場合は問題ありません。覚えがなければ、誰がどこから置いたのか確認してください。確認できたら、確認済みにし直してください。")
        case "mcp_server_changed":
            return loc("この MCP サーバーの起動コマンドや接続先などの設定が、確認済みにした時点から変わっています。MCP サーバーは設定された通りのコマンドを実行するので、差し替えられていると任意のコードが動きます。自分で変更した覚えがなければ、設定ファイルを開いて内容を確認してください。確認できたら、確認済みにし直してください。")
        case "mcp_server_added":
            return loc("この MCP サーバーは、確認済みにした時点では設定されていませんでした。追加した覚えがなければ、設定ファイルを開いて、どのコマンドや接続先を指しているか確認してください。確認できたら、確認済みにし直してください。")
        case "openclaw_auth_disabled":
            return loc("OpenClaw のゲートウェイの認証が無効（gateway.auth.mode が none）です。到達できる相手は誰でも、このゲートウェイ経由でエージェントを操作できます。トークン認証に戻してください。")
        case "openclaw_wide_bind":
            return loc("OpenClaw のゲートウェイが、このPCの外からも届く待ち受け方（lan・tailnet など）になっています。認証は必須ですが、意図して公開していない場合は loopback に戻し、公開する場合はファイアウォールで届く範囲を絞ってください。")
        case "openclaw_weak_token":
            return loc("OpenClaw のゲートウェイのトークンが短すぎます（24文字未満）。推測や総当たりで破られる恐れがあります。openssl rand -hex 32 などで作り直してください。")
        case "openclaw_origin_wildcard":
            return loc("OpenClaw のコントロール画面が、すべてのサイト（*）からのブラウザ操作を許可しています。悪意のある Web ページから、ゲートウェイを操作される恐れがあります。許可するオリジンを明示してください。")
        case "openclaw_dangerous_flag":
            return loc("OpenClaw が「危険」と明記している安全機能の無効化スイッチ（dangerously… など）がオンになっています。意図して設定したものでなければオフに戻してください。")
        case "openclaw_broad_trusted_proxy":
            return loc("OpenClaw が、すべての相手（0.0.0.0/0 など）を信頼するプロキシとして扱う設定になっています。ヘッダーを偽装されて、認証や接続元の判定をすり抜けられる恐れがあります。実際のプロキシのアドレスだけに絞ってください。")
        case "openclaw_proxy_trust_loosened":
            return loc("OpenClaw が、プロキシやノードの信頼を広げる設定（X-Real-IP の信頼・ノードの自動承認・ループバックのプロキシ許可）になっています。意図した構成か確認してください。")
        case "openclaw_open_dm":
            return loc("OpenClaw が、誰からでも DM やグループのメッセージを受け付ける設定（open）になっています。見知らぬ相手の文章が、ツールを持つエージェントへの指示になり得ます。許可リスト方式に変えられないか検討してください。")
        case "openclaw_mdns_full":
            return loc("OpenClaw が mDNS で、実行ファイルのパス（ユーザー名を含みます）やホスト名を同じネットワークに広告しています（full）。近くの端末への手がかりになるため、必要がなければ minimal に戻してください。")
        case "openclaw_audit_suppressed":
            return loc("OpenClaw の自己診断の指摘を非表示にする設定（security.audit.suppressions）があります。隠した指摘が見直されなくなるため、今も隠す必要があるか確認してください。")
        case "openclaw_loose_permissions":
            return loc("OpenClaw の設定フォルダまたは設定ファイルが、所有者以外にも読める権限になっています。トークンや認証情報が他のユーザーに読まれる恐れがあります。フォルダは 700、ファイルは 600 にしてください。")
        case "editor_auto_run_task":
            return loc("このプロジェクトの .vscode/tasks.json に、VS Code やその互換エディタでフォルダを開いたとき自動で実行されるタスクがあります。出どころの分からないプロジェクトでは、クリックなしでそのコマンドが動きます。タスクの内容を読み、覚えがなければ削除して、そのフォルダを信頼しないでください。")
        case "workflow_pwn_request":
            return loc("pull_request_target または workflow_run で始まるワークフローが、プルリクエストのコードをチェックアウトしています。そのコードは書き込み権限とシークレットのある環境で動きます。ベースのコードだけをチェックアウトするか、信頼できないコードにシークレットを渡さないようにジョブを分けてください。")
        case "workflow_expression_injection":
            return loc("Issue のタイトル、ブランチ名、コミットメッセージなど、他人が書ける文字列が ${{ }} でスクリプトの中に直接入っています。書き方次第で、その人のコマンドを実行させられます。環境変数に渡して、スクリプトからは環境変数として読むようにしてください。")
        case "workflow_unpinned_action":
            return loc("外部の作者のアクションを、作者が付け替えられるタグやブランチで指定しています。後から中身を差し替えられても気づけません。40桁のコミット SHA で固定してください。")
        case "agent_settings_hook":
            return loc("Claude Code の設定に、ツールの実行前後やセッションの開始などのたびに自動で実行されるコマンド（フック）があります。プロジェクトの設定に入っていると、そのリポジトリを開いて信頼しただけで動きます。コマンドの中身を読み、覚えがなければ削除してください。")
        case "agent_settings_bypass":
            return loc("Claude Code の権限モードが bypassPermissions（または、その警告を出さない設定）になっています。すべての操作が確認なしで実行されるため、悪意のある指示が紛れ込んでも止められません。意図して設定したものでなければ、defaultMode を default に戻してください。")
        case "agent_settings_broad_allow":
            return loc("permissions.allow に、どんなシェルコマンドでも実行できる許可（Bash 全体や *）、または任意のコードを実行できるコマンドの許可（sh・python・curl など）があります。使うコマンドだけに絞った書き方（例: Bash(git status:*)）に変えてください。")
        case "agent_settings_endpoint_override":
            return loc("env の ANTHROPIC_BASE_URL が、Anthropic の公式の接続先とは別のホストを指しています。やり取りの内容と API キーがそのホストに送られます。社内のゲートウェイなど、自分で用意した接続先でなければ削除してください。プロジェクトの設定にある場合は特に注意してください。")
        case "agent_settings_writable":
            return loc("この設定ファイル(Claude Code の設定、VS Code のタスク、GitHub Actions のワークフロー)は、すべてのユーザーが書き込める権限になっています。他のユーザーやプロセスが、確認なしにコマンドを許可する設定や、自動で動くコマンドを書き足せます。chmod o-w で書き込み権限を外し、内容も確認してください。")
        case "agent_settings_weakened":
            return loc("確認済みにした時点と比べて、Claude Code の設定で確認なしに実行できる範囲が広がっています（禁止ルールの削除、広い許可の追加、フックの追加、権限モードの引き上げ、サンドボックスの無効化のいずれか）。自分で変更した覚えがなければ、設定ファイルを開いて確認してください。確認できたら、確認済みにし直してください。")
        default:
            return id
        }
    }
}

/// JSON payload of the MCP tool `audit_agent_setup` (same shape on the Linux edition).
public struct AgentSetupAuditResultPayload: Codable, Equatable {
    public struct FindingPayload: Codable, Equatable {
        public let id: String
        public let severity: String
        public let area: String
        public let file: String
        public let detail: String
        public let message: String
        /// OWASP Top 10 for LLM Applications (2025) ids this rule belongs to (RoamSwitch's own classification).
        public let owaspLlm: [String]
        /// MITRE ATT&CK technique ids, empty where no technique fits plainly.
        public let attackId: [String]
    }
    public let scannedFileCount: Int
    public let scannedFiles: [String]
    public let skillCount: Int
    public let openClawConfigFound: Bool
    /// Files that exist but could not be read or parsed (so they were NOT audited).
    public let unreadableFiles: [String]
    public let findings: [FindingPayload]
    /// When the accepted state the drift findings compare against was recorded (ISO 8601); nil if none.
    public let baselineAcceptedAt: String?
}
