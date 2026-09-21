// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.51 (build 108).
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
        var id: String { dependencyName }
    }

    private struct PopularPackageList: Decodable {
        let mapVersion: String
        let packages: [String]
    }

    /// Build-time embedded baseline — a curated, hand-maintained snapshot of
    /// widely-used npm package names, identical to
    /// `roamswitch-linux/crates/roamswitch-core/data/popular_npm_packages.json`.
    /// Not exhaustive, not live (no registry query at build OR run time).
    private static let embeddedJSON = #"""
    {"note": "Curated, hand-maintained snapshot of widely-used npm package names for TyposquatGuard.swift's typosquatting check. Unlike the CVE maps, this is NOT mechanically generated from an external vulnerability feed — it's a hand-curated popularity list, refreshed periodically and republished via PackageCveMapUpdater's daily signed manifest fetch (same pipeline as the CVE maps, and the same underlying list as roamswitch-linux's typosquat_guard.rs). This file is the build-time embedded baseline; a newer version installed by PackageCveMapUpdater at ~/Library/Application Support/RoamSwitch/popular_npm_packages.json takes precedence when present.", "mapVersion": "2026-09-15", "packages": ["react", "react-dom", "react-native", "redux", "react-redux", "vue", "vuex", "angular", "svelte", "next", "nuxt", "gatsby", "remix", "preact", "lodash", "underscore", "ramda", "moment", "dayjs", "date-fns", "luxon", "axios", "node-fetch", "isomorphic-fetch", "got", "request", "superagent", "express", "koa", "fastify", "hapi", "nestjs", "restify", "connect", "webpack", "webpack-cli", "rollup", "parcel", "vite", "esbuild", "gulp", "grunt", "browserify", "babel-core", "core-js", "regenerator-runtime", "typescript", "tslib", "ts-node", "eslint", "prettier", "jshint", "tslint", "jest", "mocha", "chai", "sinon", "jasmine", "karma", "ava", "tape", "cypress", "playwright", "puppeteer", "webdriverio", "selenium-webdriver", "jsdom", "enzyme", "testing-library", "storybook", "chalk", "commander", "yargs", "minimist", "inquirer", "prompts", "figlet", "ora", "cli-progress", "debug", "winston", "pino", "bunyan", "morgan", "log4js", "uuid", "nanoid", "shortid", "cuid", "crypto-js", "bcrypt", "bcryptjs", "jsonwebtoken", "jwt-decode", "passport", "passport-jwt", "passport-local", "dotenv", "cross-env", "config", "convict", "nconf", "cors", "helmet", "body-parser", "cookie-parser", "express-session", "multer", "formidable", "busboy", "sharp", "jimp", "canvas", "glob", "fast-glob", "globby", "rimraf", "mkdirp", "fs-extra", "del", "chokidar", "watch", "nodemon", "pm2", "forever", "concurrently", "async", "bluebird", "q", "rxjs", "xstate", "immer", "immutable", "classnames", "clsx", "prop-types", "styled-components", "emotion", "tailwindcss", "bootstrap", "material-ui", "antd", "semantic-ui-react", "jquery", "zepto", "d3", "three", "chart.js", "recharts", "victory", "socket.io", "ws", "engine.io", "sockjs", "mqtt", "amqplib", "graphql", "apollo-server", "apollo-client", "graphql-tag", "urql", "sequelize", "typeorm", "prisma", "knex", "mongoose", "objection", "pg", "mysql", "mysql2", "sqlite3", "redis", "ioredis", "memcached", "aws-sdk", "@aws-sdk/client-s3", "firebase", "firebase-admin", "stripe", "twilio", "sendgrid", "nodemailer", "mailgun-js", "semver", "validator", "joi", "yup", "zod", "ajv", "class-validator", "lodash.merge", "lodash.get", "lodash.debounce", "lodash.clonedeep", "axios-retry", "http-proxy", "http-proxy-middleware", "proxy-agent", "puppeteer-core", "cheerio", "xml2js", "fast-xml-parser", "csv-parser", "csv-parse", "papaparse", "exceljs", "xlsx", "archiver", "adm-zip", "tar", "yauzl", "unzipper", "node-cron", "cron", "agenda", "bull", "bee-queue", "husky", "lint-staged", "commitizen", "standard-version", "semantic-release", "vercel", "netlify-cli", "serverless", "aws-cdk", "terraform", "react-router", "react-router-dom", "history", "reach-router", "formik", "react-hook-form", "final-form", "redux-form", "swr", "react-query", "apollo-boost", "graphql-request", "next-auth", "clerk", "auth0", "keycloak-connect", "eslint-config-airbnb", "eslint-plugin-react", "eslint-plugin-import", "babel-preset-env", "babel-plugin-transform-runtime", "postcss", "autoprefixer", "sass", "less", "stylus", "webpack-dev-server", "html-webpack-plugin", "mini-css-extract-plugin", "terser-webpack-plugin", "css-loader", "style-loader", "file-loader", "vue-router", "pinia", "vuex-module-decorators", "vue-i18n", "svelte-kit", "sveltekit", "solid-js", "qwik", "lit", "stencil", "electron", "electron-builder", "nw.js", "tauri", "react-native-vector-icons", "react-native-svg", "expo", "node", "npm", "yarn", "pnpm", "corepack"]}
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
        let decoder = JSONDecoder()
        let embedded = (try? decoder.decode(PopularPackageList.self, from: Data(embeddedJSON.utf8)))
            ?? PopularPackageList(mapVersion: "", packages: [])
        if let data = try? Data(contentsOf: updatedListURL),
           let updated = try? decoder.decode(PopularPackageList.self, from: data),
           updated.mapVersion >= embedded.mapVersion {
            return updated.packages
        }
        return embedded.packages
    }

    /// Known legitimate packages that happen to sit one edit away from a
    /// popular name — suppressed to avoid the most common, well-documented
    /// false positives. Not exhaustive; see this type's doc comment.
    private static let knownLookalikeAllowlist: Set<String> = ["preact", "is-array", "isarray", "node-fetch"]

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
        let a = Array(a), b = Array(b)
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

    /// Checks one dependency name against a given popular-package list.
    /// Returns `nil` if `name` *is* a popular package (exact match,
    /// unscoped), is on the look-alike allowlist, or isn't close enough to
    /// anything popular to be worth a second look.
    static func checkName(_ name: String, against popular: [String]) -> Finding? {
        let base = unscoped(name)
        if knownLookalikeAllowlist.contains(base) { return nil }
        if popular.contains(base) { return nil } // it IS the popular package

        var best: (target: String, distance: Int)?
        for candidate in popular {
            let lenDiff = abs(base.count - candidate.count)
            if lenDiff > 2 { continue } // cheap pre-filter before the O(n*m) DP call
            let threshold = candidate.count >= 8 ? 2 : 1
            let d = levenshtein(base, candidate)
            if d == 0 || d > threshold { continue }
            if best == nil || d < best!.distance {
                best = (candidate, d)
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
    static func scanPackageJSON(_ projectDir: URL, against popular: [String]) -> [Finding] {
        let manifestURL = projectDir.appendingPathComponent("package.json")
        guard let data = try? Data(contentsOf: manifestURL),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [] }

        var names: Set<String> = []
        for field in ["dependencies", "devDependencies", "optionalDependencies"] {
            if let deps = obj[field] as? [String: Any] {
                names.formUnion(deps.keys)
            }
        }
        return names.sorted().compactMap { checkName($0, against: popular) }
    }

    private static let skipDirNames: Set<String> =
        ["node_modules", ".git", "vendor", "target", ".venv", "venv", "dist", "build", ".tox"]

    /// Walks `folder` up to `maxDepth` levels checking every `package.json`
    /// it finds — mirrors `PackageCveScriptScan.scanWatchedFolder`'s
    /// recursion shape, but never descends into `node_modules` at all
    /// (unlike that scanner): a typosquat is introduced at the moment a
    /// human adds a dependency to *some* project's own manifest, not
    /// somewhere in an already-installed transitive tree.
    static func scanWatchedFolder(_ folder: URL, maxDepth: Int, against popular: [String]) -> [Finding] {
        var out = scanPackageJSON(folder, against: popular)
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: [.isDirectoryKey], options: []
        ) else { return out }
        for entryURL in entries {
            let fileName = entryURL.lastPathComponent
            let isDir = (try? entryURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            guard isDir, !skipDirNames.contains(fileName) else { continue }
            if maxDepth > 0 {
                out.append(contentsOf: scanWatchedFolder(entryURL, maxDepth: maxDepth - 1, against: popular))
            }
        }
        return out
    }

    /// Entry point: scans every watched folder (the same list
    /// `PackageCveScanLanguages`/`PackageCveScriptScan` use) for
    /// `package.json` typosquat candidates.
    static func runScan(watchedFolders: [String]) -> [Finding] {
        let popular = popularPackageNames()
        var out: [Finding] = []
        for folder in watchedFolders {
            out.append(contentsOf: scanWatchedFolder(URL(fileURLWithPath: folder), maxDepth: 6, against: popular))
        }
        return out
    }
}
