// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.10 (build 189).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// One finding of the PHP detector. `id` is stable.
struct PhpFinding: Equatable {
    let id: String
    let severity: PhpSeverity
    let title: String
    let detail: String
    let mitigation: String
    let evidence: String?
    /// The PHP version a version finding is about.
    var version: String? = nil
}

struct PhpCheckResult {
    var findings: [PhpFinding] = []
    var interpreters: [PhpInterpreter] = []
    var iniFilesRead = 0

    var worst: PhpSeverity { findings.map(\.severity).max() ?? .info }
    /// The verdict: high or critical means something has to be done.
    var needsAction: Bool { worst >= .high }
    var actionCount: Int { findings.filter { $0.severity >= .high }.count }
}

/// The read-only PHP detector behind the PHP part of the `package_cve_exposure` item: no network, no PHP script is
/// run. Written for the PHP advisories of 2026-10-21 (CVE-2026-109618, CVE-2026-109619) and 2026-10-23
/// (CVE-2026-115560, no fix yet): which builds are fixed, whether the settings that carry the known attack paths
/// are on, and whether application code switches `session.serialize_handler` at run time. PHP session files are
/// read by the Web rules scan (`WebRuleFolderScanner`), not here.
enum PhpEnvironmentAudit {
    static let upload = "session.upload_progress.enabled"
    static let backtraces = "fatal_error_backtraces"
    static let memory = "memory_limit"
    static let handlerKey = "session.serialize_handler"
    /// The serialize handlers other than the default `php`. CVE-2026-115560 needs one of them in the configuration.
    static let nonDefaultHandlers: Set<String> = ["php_binary", "php_serialize"]

    /// `versionCountedElsewhere` names interpreters whose version is already judged by another source (a Homebrew
    /// php that the Homebrew map covers); they stay in the list but produce no version finding, so one install is
    /// not counted twice.
    static func run(fs: PhpFS = PhpFS(),
                    home: String = NSHomeDirectory(),
                    pathEnv: String = ProcessInfo.processInfo.environment["PATH"] ?? "",
                    versionOf: (PhpInterpreter) -> String? = { PhpEnvironment.runVersion($0) },
                    versionCountedElsewhere: (PhpInterpreter) -> Bool = { _ in false }) -> PhpCheckResult {
        var interpreters = PhpEnvironment.interpreters(fs: fs, home: home, pathEnv: pathEnv)
        for i in interpreters.indices { interpreters[i].version = versionOf(interpreters[i]) }
        let sets = PhpEnvironment.iniSets(fs: fs, home: home)
        let modPhp = PhpEnvironment.modPhpConfigs(fs: fs)

        var result = PhpCheckResult()
        result.interpreters = interpreters
        result.iniFilesRead = sets.reduce(0) { $0 + $1.iniFiles.count + $1.poolFiles.count }

        if interpreters.isEmpty && sets.isEmpty && modPhp.isEmpty {
            result.findings = [PhpFinding(
                id: "php_not_found", severity: .info,
                title: loc("PHPは見つかりませんでした"),
                detail: loc("Homebrew、MAMP、Herd、PATHのどこにも、php、php-fpm、frankenphp がありませんでした。"),
                mitigation: "", evidence: nil)]
            return result
        }

        var findings: [PhpFinding] = []
        findings += versionFindings(interpreters.filter { !versionCountedElsewhere($0) })
        findings += sapiFindings(interpreters, modPhp: modPhp)
        findings += configFindings(fs: fs, sets: sets, interpreters: interpreters, modPhp: !modPhp.isEmpty)
        findings += handlerFindings(fs: fs, sets: sets, interpreters: interpreters, modPhp: !modPhp.isEmpty, home: home)

        result.findings = findings.enumerated().sorted {
            $0.element.severity != $1.element.severity ? $0.element.severity > $1.element.severity : $0.offset < $1.offset
        }.map(\.element)
        return result
    }

    // MARK: Version

    static func versionFindings(_ interpreters: [PhpInterpreter]) -> [PhpFinding] {
        // One finding per (verdict, version); the binaries that share it are listed in it.
        var order: [String] = []
        var groups: [String: [PhpInterpreter]] = [:]
        for i in interpreters {
            let key = i.version ?? "?"
            if groups[key] == nil { order.append(key) }
            groups[key, default: []].append(i)
        }
        return order.map { key in
            let list = groups[key] ?? []
            let version = list.first?.version
            let shown = version ?? loc("不明")
            let names = list.map(\.path).joined(separator: "\n")
            let evidence = list.first?.path
            switch PhpEnvironment.verdict(forVersion: version) {
            case .unpatched(let fixed):
                return PhpFinding(id: "php_version_unpatched", severity: .high,
                                  title: String(format: loc("PHP %@ は修正版より前です"), shown),
                                  detail: String(format: loc("この系列の修正版は %@ です。重大な脆弱性2件（CVE-2026-109618、CVE-2026-109619）が、リモートコード実行につながり得ます。"), fixed) + "\n" + names,
                                  mitigation: String(format: loc("PHPを %@ 以降に更新してください。更新が完全な対処です。"), fixed),
                                  evidence: evidence, version: version)
            case .noUpstreamFix:
                return PhpFinding(id: "php_version_no_upstream_fix", severity: .high,
                                  title: String(format: loc("PHP %@ には公式の修正版がありません"), shown),
                                  detail: loc("8.1以前の系列には、重大な脆弱性2件（CVE-2026-109618、CVE-2026-109619）の修正が出ていません。") + "\n" + names,
                                  mitigation: loc("修正版が出ている系列（8.2以降）へ移ってください。"),
                                  evidence: evidence, version: version)
            case .patched:
                return PhpFinding(id: "php_version_patched", severity: .info,
                                  title: String(format: loc("PHP %@ は修正版です"), shown),
                                  detail: loc("重大な脆弱性2件（CVE-2026-109618、CVE-2026-109619）の修正を含む版です。") + "\n" + names,
                                  mitigation: "", evidence: evidence)
            case .unknown:
                return PhpFinding(id: "php_version_unknown", severity: .medium,
                                  title: String(format: loc("PHP %@ の修正状況は判定できません"), shown),
                                  detail: loc("この点検が判定できるのは、8.2から8.5の系列と、8.1以前です。") + "\n" + names,
                                  mitigation: loc("php.netで確認してください。"),
                                  evidence: evidence)
            }
        }
    }

    // MARK: SAPI

    static func sapiFindings(_ interpreters: [PhpInterpreter], modPhp: [String]) -> [PhpFinding] {
        var out: [PhpFinding] = []
        if let conf = modPhp.first {
            out.append(PhpFinding(id: "sapi_mod_php", severity: .medium,
                                  title: loc("ApacheがPHPをモジュールとして読み込んでいます"),
                                  detail: loc("公表された情報では、Apache用のPHPモジュール（mod_php）が最も影響を受けやすい動かし方です。") + "\n" + modPhp.joined(separator: "\n"),
                                  mitigation: loc("PHPを更新し、使わない upload_progress は切ってください。"),
                                  evidence: conf))
        }
        if let fpm = interpreters.first(where: { $0.kind == .fpm }) {
            out.append(PhpFinding(id: "sapi_fpm", severity: .info,
                                  title: loc("PHP-FPM があります"),
                                  detail: loc("公表された情報では、影響を受け得るとされています。完全な攻撃手順はまだ示されていません。"),
                                  mitigation: "", evidence: fpm.path))
        }
        if let fr = interpreters.first(where: { $0.kind == .frankenphp }) {
            out.append(PhpFinding(id: "sapi_frankenphp", severity: .info,
                                  title: loc("FrankenPHP があります"),
                                  detail: loc("公表された情報では、影響を受ける可能性が高いとされています。"),
                                  mitigation: "", evidence: fr.path))
        }
        return out
    }

    // MARK: Config

    /// One effective value and where it came from (`file` nil for the PHP default).
    struct Effective { let value: Bool; let file: String? }

    /// The values the web side sees for a boolean key: the ini value (or the default), replaced by a pool's own
    /// `php_admin_value`/`php_value` in each FPM pool; mod_php sees the ini value.
    static func webContexts(fs: PhpFS, set: PhpIniSet, key: String, defaultValue: Bool, modPhp: Bool) -> [Effective] {
        let base = PhpEnvironment.iniValues(fs: fs, files: set.iniFiles, keys: [key])[key]
        let baseValue = base.map { PhpEnvironment.iniBool($0.value) } ?? defaultValue
        let baseEffective = Effective(value: baseValue, file: base?.file)
        var pools: [Effective] = []
        for f in set.poolFiles {
            guard let text = fs.read(f) else { continue }
            for pool in PhpEnvironment.parsePools(text, file: f, keys: [key]) {
                pools.append(pool.values[key].map { Effective(value: PhpEnvironment.iniBool($0), file: f) } ?? baseEffective)
            }
        }
        if pools.isEmpty { return [baseEffective] }
        return modPhp ? pools + [baseEffective] : pools
    }

    static func configFindings(fs: PhpFS, sets givenSets: [PhpIniSet], interpreters: [PhpInterpreter], modPhp: Bool) -> [PhpFinding] {
        var out: [PhpFinding] = []
        // PHP found but no ini file at all: it runs on its built-in defaults.
        var sets = givenSets
        if sets.isEmpty && !interpreters.isEmpty {
            sets = [PhpIniSet(label: loc("設定ファイルなし"), branch: nil, phpIni: nil, confD: [], poolFiles: [])]
        }
        let has85 = interpreters.contains { $0.branch == "8.5" }

        var memoryLines: [String] = []
        for set in sets {
            // session.upload_progress: On when nothing sets it.
            let up = webContexts(fs: fs, set: set, key: upload, defaultValue: true, modPhp: modPhp)
            if let on = up.first(where: { $0.value }) {
                let note = on.file == nil ? "\n" + loc("設定に指定がないため、既定のオンです。") : ""
                out.append(PhpFinding(id: "upload_progress_on", severity: .medium,
                                      title: String(format: loc("session.upload_progress が有効です（%@）"), set.label),
                                      detail: loc("アップロードの進み具合を、セッションファイルに書き込む機能です。公表された情報の攻撃経路の1つが、ここを通ります。") + note,
                                      mitigation: loc("使っていなければ session.upload_progress.enabled=0 にしてください。更新したあとも、使わないなら切っておくのが無難です。"),
                                      evidence: on.file ?? set.phpIni))
            } else {
                out.append(PhpFinding(id: "upload_progress_off", severity: .info,
                                      title: String(format: loc("session.upload_progress は無効です（%@）"), set.label),
                                      detail: "", mitigation: "", evidence: up.first?.file ?? set.phpIni))
            }

            // fatal_error_backtraces: On when nothing sets it.
            // The setting exists on PHP 8.5 only; a set that belongs to another version is left out.
            if has85 && (set.branch == nil || set.branch == "8.5") {
                let bt = webContexts(fs: fs, set: set, key: backtraces, defaultValue: true, modPhp: modPhp)
                if let on = bt.first(where: { $0.value }) {
                    let builds = interpreters.filter { $0.branch == "8.5" }
                    let unpatched = builds.contains { if case .unpatched = PhpEnvironment.verdict(forVersion: $0.version) { return true } else { return false } }
                    let note = on.file == nil ? "\n" + loc("設定に指定がないため、既定のオンです。") : ""
                    out.append(PhpFinding(id: "fatal_error_backtraces_on", severity: unpatched ? .high : .medium,
                                          title: String(format: loc("fatal_error_backtraces が有効です（%@）"), set.label),
                                          detail: loc("PHP 8.5 にある設定です。公表された情報の攻撃経路の1つが、ここを通ります。") + note,
                                          mitigation: loc("fatal_error_backtraces=0 にしてください。"),
                                          evidence: on.file ?? set.phpIni))
                }
            }

            let mem = PhpEnvironment.iniValues(fs: fs, files: set.iniFiles, keys: [memory])[memory]?.value
            if let mem { memoryLines.append("\(set.label)  memory_limit = \(mem)") }
        }
        if !memoryLines.isEmpty {
            out.append(PhpFinding(id: "memory_limit", severity: .info,
                                  title: loc("memory_limit の設定"),
                                  detail: memoryLines.joined(separator: "\n"),
                                  mitigation: loc("公表された情報では、memory_limit=-1 は、メモリ不足を使った攻撃を部分的に防ぐ応急処置とされています。勧めてはいません。完全な対処は、修正版への更新です。"),
                                  evidence: nil))
        }
        return out
    }

    // MARK: serialize_handler (CVE-2026-115560)

    /// What the web side sees for `session.serialize_handler`: the ini value, replaced by a pool's own value in
    /// each FPM pool (the same layout as `webContexts`, so the two lists can be read side by side).
    static func handlerContexts(fs: PhpFS, set: PhpIniSet, modPhp: Bool) -> [(value: String, file: String?)] {
        func clean(_ v: String) -> String { v.trimmingCharacters(in: CharacterSet(charactersIn: " \t\"'")).lowercased() }
        let base = PhpEnvironment.iniValues(fs: fs, files: set.iniFiles, keys: [handlerKey])[handlerKey]
        let baseEffective = (value: base.map { clean($0.value) } ?? "php", file: base?.file)
        var pools: [(value: String, file: String?)] = []
        for f in set.poolFiles {
            guard let text = fs.read(f) else { continue }
            for pool in PhpEnvironment.parsePools(text, file: f, keys: [handlerKey]) {
                pools.append(pool.values[handlerKey].map { (value: clean($0), file: Optional(f)) } ?? baseEffective)
            }
        }
        if pools.isEmpty { return [baseEffective] }
        return modPhp ? pools + [baseEffective] : pools
    }

    /// Where web applications keep their PHP files on a Mac.
    static func codeRoots(home: String) -> [String] {
        ["/opt/homebrew/var/www", "/usr/local/var/www", "/Applications/MAMP/htdocs", "/Library/WebServer/Documents", home + "/Sites", home + "/Herd"]
    }

    /// True for a line that calls `ini_set` on `session.serialize_handler` (the call may start on the line before).
    static func switchesSerializeHandler(previous: String, line: String) -> Bool {
        let l = line.lowercased()
        return l.contains("serialize_handler") && (l.contains("ini_set") || previous.lowercased().contains("ini_set"))
    }

    /// `path:line` of every place in the PHP files of the web roots (Composer packages under `vendor/` included)
    /// that calls `ini_set()` on `session.serialize_handler`. Links are not followed; `node_modules` and `.git`
    /// are skipped; the walk is bounded in files, depth and file size.
    static func scanSerializeHandlerSwitches(fs: PhpFS, home: String, maxFiles: Int = 40_000, maxHits: Int = 20) -> [String] {
        var hits: [String] = []
        var files = 0
        var stack: [(path: String, depth: Int)] = codeRoots(home: home).filter { fs.isDirectory($0) }.map { ($0, 0) }
        func kind(_ path: String) -> FileAttributeType? {
            (try? FileManager.default.attributesOfItem(atPath: fs.real(path)))?[.type] as? FileAttributeType
        }
        while let (dir, depth) = stack.popLast() {
            for name in fs.list(dir) {
                let path = dir.hasSuffix("/") ? dir + name : dir + "/" + name
                switch kind(path) {
                case .typeDirectory:
                    if depth < 12 && name != "node_modules" && name != ".git" { stack.append((path, depth + 1)) }
                case .typeRegular:
                    let lower = name.lowercased()
                    guard lower.hasSuffix(".php") || lower.hasSuffix(".phtml") || lower.hasSuffix(".inc") else { continue }
                    files += 1
                    if files > maxFiles { return hits.sorted() }
                    guard let text = fs.read(path, maxBytes: 2_097_152), text.lowercased().contains("serialize_handler") else { continue }
                    var previous = ""
                    for (i, line) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
                        if switchesSerializeHandler(previous: previous, line: String(line)) {
                            hits.append("\(path):\(i + 1)")
                            if hits.count >= maxHits { return hits.sorted() }
                        }
                        previous = String(line)
                    }
                default:
                    continue
                }
            }
        }
        return hits.sorted()
    }

    /// CVE-2026-115560 needs three things at once: a non-default handler in the configuration, application code that
    /// switches it back with `ini_set()`, and upload progress on. Only the combination needs action.
    static func handlerFindings(fs: PhpFS, sets givenSets: [PhpIniSet], interpreters: [PhpInterpreter], modPhp: Bool, home: String) -> [PhpFinding] {
        var sets = givenSets
        if sets.isEmpty && !interpreters.isEmpty {
            sets = [PhpIniSet(label: loc("設定ファイルなし"), branch: nil, phpIni: nil, confD: [], poolFiles: [])]
        }
        var pair: (value: String, file: String?)?
        var nonDefault: (value: String, file: String?)?
        for set in sets {
            let up = webContexts(fs: fs, set: set, key: upload, defaultValue: true, modPhp: modPhp)
            for (i, h) in handlerContexts(fs: fs, set: set, modPhp: modPhp).enumerated() where nonDefaultHandlers.contains(h.value) {
                let file = h.file ?? set.phpIni
                if nonDefault == nil { nonDefault = (h.value, file) }
                if pair == nil, i < up.count, up[i].value { pair = (h.value, file) }
            }
        }
        let hits = scanSerializeHandlerSwitches(fs: fs, home: home)
        if let first = hits.first {
            if let pair {
                return [PhpFinding(id: "serialize_handler_combination", severity: .high,
                                   title: loc("CVE-2026-115560 の条件がそろっています"),
                                   detail: String(format: loc("設定は %@ で、アプリのコードが ini_set() で session.serialize_handler を切り替え、アップロード進捗も有効です。この脆弱性には修正がまだありません。"), pair.value) + "\n" + hits.joined(separator: "\n"),
                                   mitigation: loc("session.upload_progress.enabled=0 にして、PHPを再起動してください。進捗バーにこの機能を使っているアプリは、表示が止まります。"),
                                   evidence: first)]
            }
            return [PhpFinding(id: "serialize_handler_switch", severity: .info,
                               title: loc("アプリのコードが session.serialize_handler を切り替えています"),
                               detail: String(format: loc("%@ か所で ini_set() が使われています。設定が php_binary か php_serialize で、アップロード進捗が有効になると、CVE-2026-115560 の条件がそろいます。"), String(hits.count)) + "\n" + hits.joined(separator: "\n"),
                               mitigation: "", evidence: first)]
        }
        if let nonDefault {
            return [PhpFinding(id: "serialize_handler_non_default", severity: .info,
                               title: String(format: loc("session.serialize_handler が既定の php ではありません（%@）"), nonDefault.value),
                               detail: loc("アプリのコードがこれを ini_set() で切り替え、アップロード進捗が有効だと、CVE-2026-115560 の条件がそろいます。"),
                               mitigation: "", evidence: nonDefault.file)]
        }
        return []
    }
}
