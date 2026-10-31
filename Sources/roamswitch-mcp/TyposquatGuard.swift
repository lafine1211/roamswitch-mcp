// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.17 (build 196).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Static (offline judgment, network-refreshed data) typosquatting check for
/// npm/pnpm dependency names — the macOS counterpart of
/// `roamswitch-linux`'s `typosquat_guard.rs`. Flags a name declared in
/// `package.json` that is *almost* the name of a well-known popular package
/// (Levenshtein distance 1-2), the classic supply-chain attack of publishing
/// `expres`/`loadash`/`reactt` hoping for a fat-fingered `npm install`. This
/// is a reference heuristic, not a verdict: some legitimate packages are
/// genuinely one edit away from a popular one (`preact` vs `react`), so a
/// small allowlist of known look-alikes suppresses the most common false
/// positives, and every finding should be read as "worth a second look,"
/// not "confirmed malicious."
///
/// The app itself makes no network connections to do this check. The
/// popular-package list it checks against is a two-tier read exactly like
/// `PackageCveScanLanguages.loadCVEMap`: a build-time embedded baseline,
/// or `PackageCveMapUpdater`'s daily-refreshed signed snapshot when present
/// and at least as new (`mapVersion` compared as a date string) — see
/// `updatedListURL` / `PackageCveMapUpdater.swift`'s `popularNpmPackages`
/// feed. This mirrors the Linux side's `typosquat_guard.rs` exactly,
/// including the underlying `data/popular_npm_packages.json` seed content.
///
/// Scoped to `package.json`'s own `dependencies`/`devDependencies`/
/// `optionalDependencies` (what a human actually typed or a teammate added)
/// rather than the full transitive tree in `node_modules` — that's the
/// moment a typo is introduced, and it keeps this fully offline with no
/// lockfile parser needed.
enum TyposquatGuard {
    struct Finding: Identifiable {
        let dependencyName: String
        let suspectedTarget: String
        let distance: Int
        /// The project folder whose `package.json` declares the name; empty
        /// when the check ran on a bare name (`checkName`).
        var projectDir: String = ""
        var id: String { projectDir + "\u{0}" + dependencyName }

        /// The project folder with the home folder shortened to `~`.
        var projectDisplay: String { (projectDir as NSString).abbreviatingWithTildeInPath }
    }

    private struct PopularPackageList: Decodable {
        let mapVersion: String
        /// The hand-added names. Older versions of the app read only this key, so it stays exactly that.
        let packages: [String]
        /// Names taken from public rankings (the daily list job adds them, never a person). They match at one edit
        /// only. Absent in the embedded seed and in lists made before this key existed.
        var rankedPackages: [String]? = nil
    }

    /// Build-time embedded baseline — a curated, hand-maintained snapshot of
    /// widely-used npm package names, identical to
    /// `roamswitch-linux/crates/roamswitch-core/data/popular_npm_packages.json`.
    /// Not exhaustive, not live (no registry query at build OR run time).
    private static let embeddedJSON = #"""
    {"note": "Curated, hand-maintained snapshot of widely-used npm package names for TyposquatGuard.swift's typosquatting check. Unlike the CVE maps, this is NOT mechanically generated from an external vulnerability feed — it's a hand-curated popularity list, refreshed periodically and republished via PackageCveMapUpdater's daily signed manifest fetch (same pipeline as the CVE maps, and the same underlying list as roamswitch-linux's typosquat_guard.rs). This file is the build-time embedded baseline; a newer version installed by PackageCveMapUpdater at ~/Library/Application Support/RoamSwitch/popular_npm_packages.json takes precedence when present.", "mapVersion": "2026-09-15", "packages": ["react", "react-dom", "react-native", "redux", "react-redux", "vue", "vuex", "angular", "svelte", "next", "nuxt", "gatsby", "remix", "preact", "lodash", "underscore", "ramda", "moment", "dayjs", "date-fns", "luxon", "axios", "node-fetch", "isomorphic-fetch", "got", "request", "superagent", "express", "koa", "fastify", "hapi", "nestjs", "restify", "connect", "webpack", "webpack-cli", "rollup", "parcel", "vite", "esbuild", "gulp", "grunt", "browserify", "babel-core", "core-js", "regenerator-runtime", "typescript", "tslib", "ts-node", "eslint", "prettier", "jshint", "tslint", "jest", "mocha", "chai", "sinon", "jasmine", "karma", "ava", "tape", "cypress", "playwright", "puppeteer", "webdriverio", "selenium-webdriver", "jsdom", "enzyme", "testing-library", "storybook", "chalk", "commander", "yargs", "minimist", "inquirer", "prompts", "figlet", "ora", "cli-progress", "debug", "winston", "pino", "bunyan", "morgan", "log4js", "uuid", "nanoid", "shortid", "cuid", "crypto-js", "bcrypt", "bcryptjs", "jsonwebtoken", "jwt-decode", "passport", "passport-jwt", "passport-local", "dotenv", "cross-env", "config", "convict", "nconf", "cors", "helmet", "body-parser", "cookie-parser", "express-session", "multer", "formidable", "busboy", "sharp", "jimp", "canvas", "glob", "fast-glob", "globby", "rimraf", "mkdirp", "fs-extra", "del", "chokidar", "watch", "nodemon", "pm2", "forever", "concurrently", "async", "bluebird", "q", "rxjs", "xstate", "immer", "immutable", "classnames", "clsx", "prop-types", "styled-components", "emotion", "tailwindcss", "bootstrap", "material-ui", "antd", "semantic-ui-react", "jquery", "zepto", "d3", "three", "chart.js", "recharts", "victory", "socket.io", "ws", "engine.io", "sockjs", "mqtt", "amqplib", "graphql", "apollo-server", "apollo-client", "graphql-tag", "urql", "sequelize", "typeorm", "prisma", "knex", "mongoose", "objection", "pg", "mysql", "mysql2", "sqlite3", "redis", "ioredis", "memcached", "aws-sdk", "@aws-sdk/client-s3", "firebase", "firebase-admin", "stripe", "twilio", "sendgrid", "nodemailer", "mailgun-js", "semver", "validator", "joi", "yup", "zod", "ajv", "class-validator", "lodash.merge", "lodash.get", "lodash.debounce", "lodash.clonedeep", "axios-retry", "http-proxy", "http-proxy-middleware", "proxy-agent", "puppeteer-core", "cheerio", "xml2js", "fast-xml-parser", "csv-parser", "csv-parse", "papaparse", "exceljs", "xlsx", "archiver", "adm-zip", "tar", "yauzl", "unzipper", "node-cron", "cron", "agenda", "bull", "bee-queue", "husky", "lint-staged", "commitizen", "standard-version", "semantic-release", "vercel", "netlify-cli", "serverless", "aws-cdk", "terraform", "react-router", "react-router-dom", "history", "reach-router", "formik", "react-hook-form", "final-form", "redux-form", "swr", "react-query", "apollo-boost", "graphql-request", "next-auth", "clerk", "auth0", "keycloak-connect", "eslint-config-airbnb", "eslint-plugin-react", "eslint-plugin-import", "babel-preset-env", "babel-plugin-transform-runtime", "postcss", "autoprefixer", "sass", "less", "stylus", "webpack-dev-server", "html-webpack-plugin", "mini-css-extract-plugin", "terser-webpack-plugin", "css-loader", "style-loader", "file-loader", "vue-router", "pinia", "vuex-module-decorators", "vue-i18n", "svelte-kit", "sveltekit", "solid-js", "qwik", "lit", "stencil", "electron", "electron-builder", "nw.js", "tauri", "react-native-vector-icons", "react-native-svg", "expo", "node", "npm", "yarn", "pnpm", "corepack", "discord.js", "ethers", "web3", "zustand", "vitest", "hardhat", "jotai"]}
    """#

    /// Where `PackageCveMapUpdater` installs a fresher signed snapshot
    /// (desktop client only). Preferred over the bundled baseline when
    /// present and its `mapVersion` is newer.
    static let updatedListURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RoamSwitch", isDirectory: true)
        return base.appendingPathComponent("popular_npm_packages.json")
    }()

    /// The popular-package-name list to check dependency names against —
    /// same two-tier precedence as `PackageCveScanLanguages.loadCVEMap`.
    /// Deliberately unscoped (`@types/node` is compared as `node`) since
    /// typosquats target the base name a person actually types — see
    /// `unscoped(_:)`.
    static func popularPackageNames() -> [String] {
        popularLists().hand
    }

    /// `popularPackageNames()` with the names taken from public rankings (see `PopularIndex`): the same two-tier choice
    /// between the embedded seed (hand-added names only) and the installed snapshot.
    static func popularLists() -> (hand: [String], ranked: [String]) {
        let decoder = JSONDecoder()
        let embedded = (try? decoder.decode(PopularPackageList.self, from: Data(embeddedJSON.utf8)))
            ?? PopularPackageList(mapVersion: "", packages: [])
        if let data = try? Data(contentsOf: updatedListURL),
           let updated = try? decoder.decode(PopularPackageList.self, from: data),
           updated.mapVersion >= embedded.mapVersion {
            return (updated.packages, updated.rankedPackages ?? [])
        }
        return (embedded.packages, [])
    }

    /// Known legitimate packages that happen to sit one edit away from a
    /// popular name — suppressed to avoid the most common, well-documented
    /// false positives. Not exhaustive; see this type's doc comment.
    private static let knownLookalikeAllowlist: Set<String> = ["preact", "is-array", "isarray", "node-fetch"]

    /// Names shorter than this are not compared at all.
    private static let minBaseNameLength = 4

    /// The base name a person actually types/reads — `@scope/pkg` compares
    /// as `pkg`, since a typosquat targets the recognizable part of the
    /// name.
    private static func unscoped(_ name: String) -> String {
        guard name.hasPrefix("@"), let slashIndex = name.firstIndex(of: "/") else { return name }
        return String(name[name.index(after: slashIndex)...])
    }

    /// Standard Levenshtein (edit) distance, iterative DP with
    /// `O(min(m,n))` extra space.
    private static func levenshtein(_ a: String, _ b: String) -> Int {
        levenshtein(Array(a), Array(b))
    }

    private static func levenshtein<T: Equatable>(_ a: [T], _ b: [T]) -> Int {
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var prev = Array(0...b.count)
        var curr = [Int](repeating: 0, count: b.count + 1)
        for i in 1...a.count {
            curr[0] = i
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                curr[j] = min(prev[j] + 1, curr[j - 1] + 1, prev[j - 1] + cost)
            }
            swap(&prev, &curr)
        }
        return prev[b.count]
    }

    /// `nodemonjs`, `zustand.js` → the name without its `js` tail. Names that do not end in one are returned
    /// unchanged. `-js` is left alone on purpose: it is how real packages are named (`postcss-js`, `solid-js`).
    fileprivate static func withoutJsSuffix(_ name: String) -> String {
        for tail in [".js", "js"] where name.hasSuffix(tail) {
            let stem = String(name.dropLast(tail.count))
            if !stem.isEmpty, !stem.hasSuffix("-"), !stem.hasSuffix("_") { return stem }
        }
        return name
    }

    /// A popular-package list with the per-name work done once (length, threshold, the name without its `js` tail,
    /// the characters), so that checking many dependency names against a list of thousands stays quick. Building
    /// it costs about as much as one check; build it once per scan, not once per name.
    ///
    /// The list has two parts. A hand-added name matches at distance 1 (2 when it has 8 or more letters). A name
    /// taken from a ranking matches at distance 1 only, the `js` tail second chance included: it is weaker evidence
    /// of a name people type, and a long list of them attracts real names (docs/PACKAGE_CVE_SCAN_SPEC.ja.md §15).
    struct PopularIndex {
        fileprivate struct Entry {
            let name: String
            let length: Int
            let threshold: Int
            /// The bytes of the name and of the name without its `js` tail, compared byte by byte when both names are
            /// ASCII (every valid npm name is). Anything else is compared by characters.
            let units: [UInt8]
            let stem: String
            let stemLength: Int
            let stemUnits: [UInt8]
            let isASCII: Bool
            /// Taken from a ranking, not added by hand.
            let isRanked: Bool
        }

        fileprivate let names: Set<String>
        fileprivate let entries: [Entry]

        /// `popular`: the hand-added names (every name of a list in the old shape); `ranked`: the ranking-derived ones.
        init(_ popular: [String], ranked: [String] = []) {
            names = Set(popular).union(ranked)
            func entry(_ name: String, rankedName: Bool) -> Entry {
                let length = name.utf8.count
                let stem = TyposquatGuard.withoutJsSuffix(name)
                return Entry(
                    name: name, length: length, threshold: rankedName || length < 8 ? 1 : 2, units: Array(name.utf8),
                    stem: stem, stemLength: stem.utf8.count, stemUnits: Array(stem.utf8), isASCII: name.utf8.allSatisfy { $0 < 0x80 },
                    isRanked: rankedName
                )
            }
            entries = popular.map { entry($0, rankedName: false) } + ranked.map { entry($0, rankedName: true) }
        }

        /// The list the app uses: the embedded seed or the installed snapshot, both parts.
        static func load() -> PopularIndex {
            let lists = TyposquatGuard.popularLists()
            return PopularIndex(lists.hand, ranked: lists.ranked)
        }
    }

    /// The keys next to each key on a QWERTY keyboard (letters and digits).
    private static let keyboardNeighbours: [Character: [Character]] = {
        var out: [Character: [Character]] = [:]
        let table = "0:9op,1:2q,2:13qw,3:24ew,4:35er,5:46rt,6:57ty,7:68uy,8:79iu,9:08io,a:qswz,b:ghnv,c:dfvx,d:cefrsx,e:34drsw,f:cdgrtv,g:bfhtvy,h:bgjnuy,i:89jkou,j:hikmnu,k:ijlmo,l:kop,m:jkn,n:bhjm,o:09iklp,p:0lo,q:12aw,r:45deft,s:adewxz,t:56fgry,u:78hijy,v:bcfg,w:23aeqs,x:cdsz,y:67ghtu,z:asx"
        for pair in table.split(separator: ",") {
            let parts = pair.split(separator: ":")
            out[parts[0].first!] = Array(parts[1])
        }
        return out
    }()

    /// `a` is `b` with two neighbouring letters swapped.
    static func isSwap(_ a: String, _ b: String) -> Bool {
        let a = Array(a), b = Array(b)
        guard a.count == b.count else { return false }
        let diff = (0..<a.count).filter { a[$0] != b[$0] }
        return diff.count == 2 && diff[1] == diff[0] + 1 && a[diff[0]] == b[diff[1]] && a[diff[1]] == b[diff[0]]
    }

    /// Every string one typing-like edit away from `s` (not `s` itself, not empty): a letter dropped or repeated, two
    /// neighbouring letters swapped, a letter replaced by the key next to it, a vowel by another vowel, a separator
    /// (`-`, `_`, `.`) by another, or a separator added anywhere.
    private static func oneTypingEdit(_ s: String) -> Set<String> {
        let vowels: [Character] = ["a", "e", "i", "o", "u"]
        let separators: [Character] = ["-", "_", "."]
        let c = Array(s)
        let n = c.count
        func build(_ head: ArraySlice<Character>, _ middle: [Character], _ tail: ArraySlice<Character>) -> String {
            String(head) + String(middle) + String(tail)
        }
        var out = Set<String>()
        for i in 0..<n {
            out.insert(build(c[..<i], [], c[(i + 1)...]))
            out.insert(build(c[...i], [c[i]], c[(i + 1)...]))
            if i + 1 < n, c[i] != c[i + 1] { out.insert(build(c[..<i], [c[i + 1], c[i]], c[(i + 2)...])) }
            for k in keyboardNeighbours[c[i]] ?? [] { out.insert(build(c[..<i], [k], c[(i + 1)...])) }
            if vowels.contains(c[i]) {
                for v in vowels where v != c[i] { out.insert(build(c[..<i], [v], c[(i + 1)...])) }
            }
            if separators.contains(c[i]) {
                for t in separators where t != c[i] { out.insert(build(c[..<i], [t], c[(i + 1)...])) }
            }
        }
        for i in 0...n {
            for t in separators { out.insert(build(c[..<i], [t], c[i...])) }
        }
        out.remove(s)
        out.remove("")
        return out
    }

    /// `name` is `target` after at most two typing-like edits.
    static func typingLikeWithinTwo(_ name: String, _ target: String) -> Bool {
        let first = oneTypingEdit(target)
        if first.contains(name) { return true }
        let nameLength = name.utf8.count
        return first.contains { mid in
            abs(mid.utf8.count - nameLength) <= 1 && levenshtein(mid, name) <= 1 && oneTypingEdit(mid).contains(name)
        }
    }

    /// Checks one dependency name against a given popular-package list.
    /// Returns `nil` if `name` *is* a popular package (exact match,
    /// unscoped), is on the look-alike allowlist, or isn't close enough to
    /// anything popular to be worth a second look.
    static func checkName(_ name: String, against popular: [String]) -> Finding? {
        checkName(name, against: PopularIndex(popular))
    }

    /// The same check against a list prepared once with `PopularIndex` (lengths are in bytes, as on the Linux side).
    /// A name from a ranking also matches when the checked name is it with two neighbouring letters swapped. If
    /// `hasInstallCode` answers yes (the dependency is installed and has install-time code; it is asked only when the
    /// answer matters, at most once), a ranked name also matches after up to two typing-like edits.
    static func checkName(_ name: String, against index: PopularIndex, hasInstallCode: () -> Bool = { false }) -> Finding? {
        let base = unscoped(name)
        let baseLength = base.utf8.count
        // One edit apart means nothing at two or three letters (`js`/`ws`,
        // `pg`/`pm`); every short name would be "close" to some popular one.
        if baseLength < minBaseNameLength { return nil }
        if knownLookalikeAllowlist.contains(base) { return nil }
        if index.names.contains(base) { return nil } // it IS the popular package

        let stem = withoutJsSuffix(base)
        let stemLength = stem.utf8.count
        let baseUnits = Array(base.utf8)
        let stemUnits = Array(stem.utf8)
        let baseASCII = baseUnits.allSatisfy { $0 < 0x80 }
        // Distance between a name of the checked side and one of the list: bytes when both are ASCII, else characters.
        func distance(_ a: String, _ aUnits: [UInt8], _ b: String, _ bUnits: [UInt8], _ bASCII: Bool) -> Int {
            baseASCII && bASCII ? levenshtein(aUnits, bUnits) : levenshtein(a, b)
        }
        // A scoped name (`@solana/web3.js`) lives in its owner's namespace, so the tail is not a disguise there:
        // it never gets the second chance. Nor does a name without a tail (a real `chart` or `core` is not a
        // look-alike of `chart.js` or `core-js`).
        let canTakeTailOff = !name.hasPrefix("@") && stemLength != baseLength && stemLength >= minBaseNameLength
        var best: (target: String, distance: Int)?
        var installCode: Bool?
        func askInstallCode() -> Bool {
            if installCode == nil { installCode = hasInstallCode() }
            return installCode!
        }
        // A ranked name beyond the one-edit limit: a swap of two neighbouring letters, or typing-like edits of a
        // dependency that is installed with install-time code. Only a closer match than the best so far changes anything.
        func rankedBeyondLimit(_ entry: PopularIndex.Entry, direct: Int?, tailTakenOff: Int?) -> Bool {
            if let best, distance(base, baseUnits, entry.name, entry.units, entry.isASCII) >= best.distance { return false }
            if direct == 2, isSwap(base, entry.name) { return true }
            if tailTakenOff == 2, isSwap(stem, entry.stem) { return true }
            let typing = ((direct ?? 3) <= 2 && typingLikeWithinTwo(base, entry.name))
                || ((tailTakenOff ?? 3) <= 2 && typingLikeWithinTwo(stem, entry.stem))
            return typing && askInstallCode()
        }
        for entry in index.entries {
            let threshold = entry.threshold
            // The name as typed.
            let direct: Int? = abs(baseLength - entry.length) > 2 ? nil : distance(base, baseUnits, entry.name, entry.units, entry.isASCII)
            // The same name with its `js` tail (`nodemonjs`, `zustand.js`, `etherdjs`) taken off, against the popular
            // name with its tail taken off: the tail is how a squat dresses up the real name, and it moves the plain
            // distance past the threshold. It is a second chance to match, never a stricter test.
            var tailTakenOff: Int?
            if canTakeTailOff, abs(stemLength - entry.stemLength) <= 2 {
                tailTakenOff = distance(stem, stemUnits, entry.stem, entry.stemUnits, entry.isASCII)
            }
            let d: Int
            if let a = direct, a <= threshold {
                d = a
            } else if let b = tailTakenOff, b <= threshold {
                d = distance(base, baseUnits, entry.name, entry.units, entry.isASCII)
            } else if entry.isRanked, rankedBeyondLimit(entry, direct: direct, tailTakenOff: tailTakenOff) {
                // a ranked name, beyond the one-edit limit
                d = distance(base, baseUnits, entry.name, entry.units, entry.isASCII)
            } else {
                continue
            }
            if d == 0 { continue }
            if best == nil || d < best!.distance {
                best = (entry.name, d)
            }
        }
        guard let best else { return nil }
        return Finding(dependencyName: name, suspectedTarget: best.target, distance: best.distance)
    }

    /// Convenience wrapper that loads `popularPackageNames()` itself — fine
    /// for a single lookup or a test, but a multi-name scan should call
    /// `popularPackageNames()` once and use `checkName(_:against:)`
    /// directly to avoid re-reading/re-parsing the list per name.
    static func checkName(_ name: String) -> Finding? {
        checkName(name, against: popularPackageNames())
    }

    /// Reads `package.json` in `projectDir` and checks every name declared
    /// in `dependencies`/`devDependencies`/`optionalDependencies` (not
    /// `peerDependencies`, which describes what the *environment* is
    /// expected to provide, not something this project installs).
    /// The manifest is read through `SafeScanFS` (inside the scan root after
    /// link resolution, regular file, size-capped); `root` defaults to `projectDir`.
    static func scanPackageJSON(_ projectDir: URL, against popular: [String], root: String? = nil, allowed: Set<String> = []) -> [Finding] {
        scanPackageJSON(projectDir, against: PopularIndex(popular), root: root, allowed: allowed)
    }

    static func scanPackageJSON(_ projectDir: URL, against popular: PopularIndex, root: String? = nil, allowed: Set<String> = []) -> [Finding] {
        guard let base = SafeScanFS.canonicalPath(projectDir.path),
              let manifest = SafeScanFS.readFile(base + "/package.json", root: root ?? base),
              let obj = try? JSONSerialization.jsonObject(with: manifest.data) as? [String: Any] else { return [] }

        var names: Set<String> = []
        for field in ["dependencies", "devDependencies", "optionalDependencies"] {
            if let deps = obj[field] as? [String: Any] {
                names.formUnion(deps.keys)
            }
        }
        let scanRoot = root ?? base
        return names.subtracting(allowed).sorted().compactMap { name in
            guard var finding = checkName(name, against: popular, hasInstallCode: { dependencyHasInstallCode(project: base, root: scanRoot, name: name) }) else { return nil }
            finding.projectDir = base
            return finding
        }
    }

    /// Whether `name` is installed (in `node_modules` of the project or of a folder above it, up to `root`) and has code
    /// that runs when it is installed: a `preinstall` / `install` / `postinstall` script, or a `binding.gyp` (npm then
    /// runs `node-gyp rebuild`). False when it is not installed: a name that is only declared has not run anything yet.
    static func dependencyHasInstallCode(project: String, root: String, name: String) -> Bool {
        guard isValidPackageName(name) else { return false }
        var dir = project
        while dir == root || dir.hasPrefix(root + "/") {
            let package = dir + "/node_modules/" + name
            if let manifest = SafeScanFS.readFile(package + "/package.json", root: root) {
                if let obj = try? JSONSerialization.jsonObject(with: manifest.data) as? [String: Any],
                   let scripts = obj["scripts"] as? [String: Any],
                   ["preinstall", "install", "postinstall"].contains(where: { (scripts[$0] as? String).map { !$0.isEmpty } ?? false }) {
                    return true
                }
                return SafeScanFS.readFile(package + "/binding.gyp", root: root) != nil
            }
            if dir == root { break }
            let parent = (dir as NSString).deletingLastPathComponent
            if parent == dir { break }
            dir = parent
        }
        return false
    }

    private static let skipDirNames: Set<String> =
        ["node_modules", ".git", "vendor", "target", ".venv", "venv", "dist", "build", ".tox"]

    /// Walks `folder` up to `maxDepth` levels checking every `package.json`
    /// it finds — mirrors `PackageCveScriptScan.scanWatchedFolder`'s
    /// recursion shape, but never descends into `node_modules` at all
    /// (unlike that scanner): a typosquat is introduced at the moment a
    /// human adds a dependency to *some* project's own manifest, not
    /// somewhere in an already-installed transitive tree.
    static func scanWatchedFolder(_ folder: URL, maxDepth: Int, against popular: [String], root: String? = nil, allowed: Set<String> = []) -> [Finding] {
        scanWatchedFolder(folder, maxDepth: maxDepth, against: PopularIndex(popular), root: root, allowed: allowed)
    }

    static func scanWatchedFolder(_ folder: URL, maxDepth: Int, against popular: PopularIndex, root: String? = nil, allowed: Set<String> = []) -> [Finding] {
        guard let base = SafeScanFS.canonicalPath(folder.path) else { return [] }
        let scopeRoot = root ?? base
        var out = scanPackageJSON(URL(fileURLWithPath: base), against: popular, root: scopeRoot, allowed: allowed)
        guard maxDepth > 0 else { return out }
        // Symlinks leaving the scan root are skipped (`SafeScanFS`).
        for entry in SafeScanFS.children(ofDirectory: base, root: scopeRoot)
        where entry.kind == .directory && !skipDirNames.contains(entry.name) {
            out.append(contentsOf: scanWatchedFolder(
                URL(fileURLWithPath: entry.path), maxDepth: maxDepth - 1, against: popular, root: scopeRoot, allowed: allowed
            ))
        }
        return out
    }

    /// Entry point: scans every watched folder (the same list
    /// `PackageCveScanLanguages`/`PackageCveScriptScan` use) for
    /// `package.json` typosquat candidates. A name the person marked as legitimate
    /// (`allow`) is left out, here and in the automatic check.
    static func runScan(watchedFolders: [String], allowed: Set<String>? = nil) -> [Finding] {
        let popular = PopularIndex.load()
        let allowedNames = allowed ?? loadAllowed()
        var out: [Finding] = []
        for folder in watchedFolders {
            out.append(contentsOf: scanWatchedFolder(URL(fileURLWithPath: folder), maxDepth: 6, against: popular, allowed: allowedNames))
        }
        return out
    }

    // MARK: Names a person marked as legitimate

    /// `~/Library/Application Support/RoamSwitch/typosquat_allow.json`, next to the accepted install state.
    static var allowListURL: URL {
        PackageCveScriptScan.installBaselineURL.deletingLastPathComponent().appendingPathComponent("typosquat_allow.json")
    }

    private struct AllowFile: Codable {
        var version = 1
        var names: [String] = []
    }

    /// A name an npm package can have: at most 214 characters, lowercase letters, digits and `-._~`, with an
    /// optional `@scope/` in front. Anything else is not written to the list.
    static func isValidPackageName(_ name: String) -> Bool {
        func plain(_ s: Substring) -> Bool {
            !s.isEmpty && s.unicodeScalars.allSatisfy { ("a"..."z").contains($0) || ("0"..."9").contains($0) || "-._~".unicodeScalars.contains($0) }
        }
        guard !name.isEmpty, name.utf8.count <= 214 else { return false }
        if name.hasPrefix("@") {
            let rest = name.dropFirst()
            guard let slash = rest.firstIndex(of: "/") else { return false }
            return plain(rest[rest.startIndex..<slash]) && plain(rest[rest.index(after: slash)...])
        }
        return plain(Substring(name))
    }

    /// The legitimate names in the file (empty when there is none or it cannot be read: never "everything is allowed").
    static func loadAllowed(from url: URL = allowListURL) -> Set<String> {
        guard let data = try? Data(contentsOf: url), data.count <= 4 * 1024 * 1024,
              let file = try? StrictJSON.decode(AllowFile.self, from: data), file.version == 1 else { return [] }
        return Set(file.names.filter(isValidPackageName))
    }

    private static func saveAllowed(_ names: Set<String>, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(AllowFile(version: 1, names: names.sorted()))
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let temporary = directory.appendingPathComponent(".typosquat_allow.\(UUID().uuidString).tmp")
        guard FileManager.default.createFile(atPath: temporary.path, contents: data, attributes: [.posixPermissions: 0o600]) else {
            throw CocoaError(.fileWriteUnknown)
        }
        if FileManager.default.fileExists(atPath: url.path) {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: temporary)
        } else {
            try FileManager.default.moveItem(at: temporary, to: url)
        }
    }

    /// Marks `name` as a legitimate dependency. Only a person does this (a button): no scan, no MCP tool and no
    /// automatic check calls it, so an agent cannot silence a finding. Returns whether the list changed.
    @discardableResult
    static func allow(_ name: String, to url: URL = allowListURL) throws -> Bool {
        guard isValidPackageName(name) else { throw CocoaError(.fileWriteInvalidFileName) }
        var names = loadAllowed(from: url)
        guard names.insert(name).inserted else { return false }
        try saveAllowed(names, to: url)
        return true
    }

    /// Takes `name` off the list again. Returns whether it was on it.
    @discardableResult
    static func unallow(_ name: String, to url: URL = allowListURL) throws -> Bool {
        var names = loadAllowed(from: url)
        guard names.remove(name) != nil else { return false }
        try saveAllowed(names, to: url)
        return true
    }
}
