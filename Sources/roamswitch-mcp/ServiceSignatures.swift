// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.15.1 (build 175).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Process-identity-based known-service risk signatures.
///
/// Counterpart to the Linux client's `service_signatures.rs` (Phase 1 of the
/// active-vulnerability-verification roadmap; see `roamswitch-linux/docs/
/// ACTIVE_VULN_SCAN_SPEC.ja.md`). Purely passive, zero additional network
/// I/O beyond what `PortSecurityAuditor` already does — matching runs
/// entirely against metadata `ListeningPortMonitor` already collects
/// (process name, executable path).
///
/// Complements `PortSecurityAuditor.checkKnownDangerousPort`, which only
/// fires when a well-known service happens to be listening on its
/// conventional port. A signature here instead matches on the listening
/// process's binary name, so a service moved to a non-standard port (e.g.
/// Redis remapped to 16379) is still flagged. Every entry below describes a
/// well-documented, version-stable "insecure unless explicitly configured
/// otherwise" default — not a specific CVE, which would require per-version
/// tracking this scanner does not attempt.
/// What a probe leaves behind on the machine it probes, beyond the one ordinary connection or request that every
/// probe makes (a service may log that in its normal access log; that is not declared here).
/// Declared per probe in `ProbeCatalog`, from what the code actually sends.
enum ProbeSideEffect: String, Codable, CaseIterable, Equatable {
    /// The request carries content shaped like an attack or a marker of this scan (a `../` path to `/etc/passwd`,
    /// a foreign `Origin`, a redirect target, a URL for the server to fetch). The target's log, or a WAF or
    /// intrusion-detection log, may record it as an indicator.
    case iocInLogs = "ioc_in_logs"
    /// A throw-away listener is opened on 127.0.0.1 for the duration of the probe and closed afterwards.
    case temporaryListener = "temporary_listener"
    /// More than five requests to one port in a single run.
    case manyRequests = "many_requests"
}

/// How strong the evidence behind a finding is.
enum EvidenceKind: String, Codable, CaseIterable, Equatable {
    /// RoamSwitch sent a request and the answer showed the weakness (for example `PING` answered without `AUTH`).
    case confirmed
    /// Only the reported version lies inside a range that a known CVE affects. Nothing was exploited or tested.
    case versionRangeMatch = "version_range_match"
    /// Only that a matching service is listening was seen (by process name or port). Nothing was sent to it.
    case portOpenOnly = "port_open_only"
    /// The finding is another tool's own output (nmap NSE). RoamSwitch did not verify it.
    case externalToolReport = "external_tool_report"
}

/// The declared side effects and evidence kind of every probe `ActiveVulnScan` can run, keyed by the id
/// recorded in the probe log (`ProbeRunRecord.probeName`).
enum ProbeCatalog {
    struct Declaration: Equatable {
        let sideEffects: [ProbeSideEffect]
        /// What a positive result from this probe is.
        let evidenceKind: EvidenceKind
    }

    /// The generic web checks (`ActiveVulnScan` Phase 3) and the nmap layer (Phase 4). Request counts are the
    /// most a run sends to one port: CORS 1, traversal 3, open redirect 8, SSRF 12 (eight parameter names at `/`
    /// plus `url` at four paths).
    static let webChecks: [String: Declaration] = [
        "webvuln-cors": Declaration(sideEffects: [.iocInLogs], evidenceKind: .confirmed),
        "webvuln-traversal": Declaration(sideEffects: [.iocInLogs], evidenceKind: .confirmed),
        "webvuln-redirect": Declaration(sideEffects: [.iocInLogs, .manyRequests], evidenceKind: .confirmed),
        "webvuln-ssrf": Declaration(sideEffects: [.iocInLogs, .temporaryListener, .manyRequests], evidenceKind: .confirmed),
        "webvuln-unauth-admin": Declaration(sideEffects: [.iocInLogs, .manyRequests], evidenceKind: .confirmed),
        nmapNSEProbeName: Declaration(sideEffects: [.manyRequests], evidenceKind: .externalToolReport),
    ]

    /// nmap's `safe` NSE scripts run once over every port of a scan. Not written to the probe log.
    static let nmapNSEProbeName = "nmap-nse"

    static func declaration(forProbeName name: String) -> Declaration? {
        if let web = webChecks[name] { return web }
        guard let signature = ServiceSignatures.signatures.first(where: { $0.id == name }) else { return nil }
        return Declaration(sideEffects: signature.sideEffects, evidenceKind: .confirmed)
    }
}

enum ServiceSignatures {

    struct Signature {
        let id: String
        /// Case-insensitive substrings matched against the process name or
        /// executable basename.
        let processPatterns: [String]
        let title: String
        let description: String
        let recommendation: String
        /// A signature whose process pattern is far too broad to mean anything on its
        /// own (every Python listener matches `python`). It is never reported by the
        /// passive port audit; it only produces a finding when `ActiveVulnScan`'s
        /// probe positively identifies the service.
        var probeOnly: Bool = false
        /// A tool whose normal, intended setup is a loopback listener (an intercepting proxy,
        /// a local inspector): it is only worth reporting once it is reachable from the
        /// network, so the passive audit skips it while it is bound to loopback.
        var requiresNetworkExposure: Bool = false
        /// What the active probe for this signature leaves on the target (see `ProbeCatalog`). Every signature
        /// probe sends one ordinary read request or protocol handshake and nothing attack-shaped, so none declares
        /// an effect. A positive result sends one more request to read the version.
        var sideEffects: [ProbeSideEffect] = []
    }

    static let signatures: [Signature] = [
        Signature(
            id: "redis-default-noauth",
            processPatterns: ["redis-server", "redis-stack-server"],
            title: loc("Redis データベース露出リスク（非標準ポート）"),
            description: loc("Redisは bind / requirepass を明示的に設定しない限り、既定で認証なしに接続を受け付けます。標準の6379以外のポートで待ち受けているため、ポート番号ベースの検知では見逃されます。"),
            recommendation: loc("redis.conf で bind 127.0.0.1 および requirepass を設定してください。")
        ),
        Signature(
            id: "mongod-default-noauth",
            processPatterns: ["mongod"],
            title: loc("MongoDB データベース露出リスク（非標準ポート）"),
            description: loc("MongoDBは --auth を明示的に有効化しない限り認証なしで待ち受けます。標準の27017以外のポートで動作しているため、ポート番号ベースの検知では見逃されます。"),
            recommendation: loc("mongod.conf で bindIp: 127.0.0.1 を指定し、--auth を有効にしてください。")
        ),
        Signature(
            id: "dockerd-tcp-noauth",
            processPatterns: ["dockerd"],
            title: loc("Docker デーモン TCP API 露出リスク（非標準ポート）"),
            description: loc("dockerdがTCP経由で待ち受けています。TLS相互認証を設定していない場合、接続できる相手はホストのroot権限に相当する操作が可能になります。"),
            recommendation: loc("TLS相互認証を有効にするか、Unixドメインソケットのみを使用してください。")
        ),
        Signature(
            id: "memcached-noauth",
            processPatterns: ["memcached"],
            title: loc("Memcached 露出リスク（非標準ポート）"),
            description: loc("Memcachedは認証機構を持たないプロトコルで動作します。外部公開されるとキャッシュ内容の読み取り・改ざんに加え、UDPモードではDDoS増幅の踏み台にされる恐れがあります。"),
            recommendation: loc("-l 127.0.0.1 を指定して起動するか、外部からの到達を遮断してください。")
        ),
        Signature(
            id: "etcd-noauth",
            processPatterns: ["etcd"],
            title: loc("etcd クラスタストア露出リスク"),
            description: loc("etcdはクライアント認証（--client-cert-auth 等）を明示的に有効化しない限り、既定では未認証で全キーバリューデータへアクセスできます。"),
            recommendation: loc("--client-cert-auth を有効にするか、127.0.0.1 限定でリッスンしてください。")
        ),
        Signature(
            id: "elasticsearch-noauth",
            processPatterns: ["elasticsearch"],
            title: loc("Elasticsearch 認証なし公開リスク"),
            description: loc("Elasticsearch が認証なしでクラスタ情報に応答しました。セキュリティ機能が無効のまま到達可能だと、全インデックスの読み取り・改ざん・削除が誰にでも可能です。"),
            recommendation: loc("xpack.security.enabled: true を有効にして認証を必須にし、network.host を 127.0.0.1 または管理用ネットワークに限定してください。")
        ),
        Signature(
            id: "couchdb-noauth",
            processPatterns: ["couchdb"],
            title: loc("CouchDB 認証なし公開リスク"),
            description: loc("CouchDB が認証なしでデータベース一覧（_all_dbs）を返しました。管理者アカウントが未設定（Admin Party）のままだと、誰でもデータの読み書きと管理者権限の取得が可能です。"),
            recommendation: loc("管理者アカウントを作成して認証を必須にし、bind_address を 127.0.0.1 に限定してください。")
        ),
        Signature(
            id: "jenkins-noauth",
            processPatterns: ["jenkins"],
            title: loc("Jenkins 認証なし公開リスク"),
            description: loc("Jenkins が認証なしでジョブ情報（/api/json）を返しました。匿名アクセスが許可されていると、ビルド設定や認証情報の閲覧、さらにスクリプト実行によるサーバー乗っ取りにつながります。"),
            recommendation: loc("「Manage Jenkins > Security」でセキュリティを有効にし、匿名ユーザーの読み取り権限も外してください。")
        ),
        Signature(
            id: "vnc-noauth",
            processPatterns: ["Xvnc", "x11vnc", "tigervnc", "vncserver", "wayvnc"],
            title: loc("VNC 認証なし公開リスク"),
            description: loc("VNC サーバーが認証方式として「なし（None）」を受け付けました。到達できる相手は誰でも、パスワードなしでこの画面を閲覧・操作できます。"),
            recommendation: loc("VNC のパスワード認証を必須にするか、SSH トンネル経由に限定して、ポートを外部へ公開しないでください。")
        ),
        Signature(
            id: "smb1-enabled",
            processPatterns: ["smbd"],
            title: loc("SMBv1 が有効です"),
            description: loc("SMB のネゴシエート要求に SMBv1 ヘッダーで応答しました。SMBv1 は EternalBlue/WannaCry 型攻撃（MS17-010）の標的となったプロトコルで、2017年から非推奨です。"),
            recommendation: loc("SMBv1 を無効化してください（Samba では smb.conf に min protocol = SMB2 を設定）。")
        ),
        Signature(
            id: "smb-signing-not-required",
            processPatterns: ["smbd"],
            title: loc("SMB 署名が必須ではありません"),
            description: loc("SMB2 以降で通信の署名が必須になっていません。同じLAN上の攻撃者が認証を中継する NTLM リレー攻撃で、このホストになりすませます。"),
            recommendation: loc("SMB 署名を必須にしてください（Samba では server signing = mandatory）。")
        ),
        Signature(
            id: "caido-network-exposed",
            processPatterns: ["caido-cli", "caido"],
            title: loc("Caido（傍受プロキシ）がネットワークから到達できる状態です"),
            description: loc("Caido は通信を傍受・記録・書き換える Web セキュリティ検査用のプロキシで、AI ペネトレーションテストツールの Strix もこれを内蔵しています。記録された通信にはログイン情報やセッション Cookie が含まれ、ゲストアクセスを許可する設定（--allow-guests）では、同じネットワークの誰でもその内容を閲覧できてしまいます。"),
            recommendation: loc("意図して共有していない場合は、待ち受けを 127.0.0.1 に限定する（--listen 127.0.0.1:ポート）か、プロセスを停止してください。検査用のコンテナや VM の中だけで使い、外部へポートを公開しないでください。"),
            requiresNetworkExposure: true
        ),
        Signature(
            id: "hexstrike-noauth",
            processPatterns: ["python"],
            title: loc("HexStrike AI 型の認証なしコマンド実行 API が稼働しています"),
            description: loc("このポートで HexStrike AI（AI にペネトレーションテスト用ツールを自律実行させる MCP バックエンド）の API が応答しました。このサーバーには認証がなく、/api/command に送られた文字列をそのままシェルで実行します。標準の起動方法（python3 hexstrike_server.py）は全インターフェースで待ち受けるため、同じネットワークの誰でも、この Mac 上で任意のコマンドを実行できる状態になります。"),
            recommendation: loc("意図して使っていない場合はプロセスを停止してください。使う場合は信頼できるネットワークから切り離した検証用の VM 内に限定し、このポートをRoamSwitchのファイアウォールで外部から遮断してください。"),
            probeOnly: true
        ),
        // Local AI / ML services (2026-10). Identity and the unauthenticated-access check come from each
        // service's own endpoints, measured on real servers (Ollama 0.40.4, Gradio 6.30.0, MLflow 3.17.1,
        // Jupyter Server 2.21.1). All four are probe-only: the texts state that the service answered, so they
        // are only reported once `ActiveVulnScan` has really seen it answer. (The passive port audit already
        // covers an exposed Ollama by port number, 11434.)
        Signature(
            id: "ollama-exposed",
            processPatterns: ["ollama"],
            title: loc("Ollama(ローカル LLM サーバー)が認証なしでネットワークから使える状態です"),
            description: loc("このポートで Ollama の API が応答しました。Ollama には認証の仕組みがなく、ネットワークから届く相手は誰でもモデルの一覧取得・ダウンロード・削除・推論の実行ができます。GPU などの計算資源を勝手に使われたり、ディスクを埋められたりします。既定の待ち受けは 127.0.0.1 ですが、OLLAMA_HOST=0.0.0.0 などの設定でネットワークから届く状態になっています。"),
            recommendation: loc("OLLAMA_HOST を 127.0.0.1 に戻して Ollama を再起動してください。他の端末から使う必要がある場合は、認証を付けたリバースプロキシか VPN の内側に限定してください。"),
            probeOnly: true
        ),
        Signature(
            id: "jupyter-noauth",
            processPatterns: ["python", "jupyter"],
            title: loc("Jupyter Server がトークンもパスワードもなしで公開されています"),
            description: loc("このポートで Jupyter Server の API(/api/status)がログインなしで応答しました。Jupyter はノートブックやターミナルからコードを実行できるため、認証がないと、ネットワークから届く相手は誰でもこのユーザーの権限で任意のコマンドを実行できます。トークンとパスワードの両方を無効にしたまま、127.0.0.1 以外で待ち受けると起きる状態です。"),
            recommendation: loc("トークンかパスワードを有効に戻し、待ち受けを 127.0.0.1 だけにしてください。別の端末から使う場合は、SSH のポートフォワードなどで通してください。"),
            probeOnly: true
        ),
        Signature(
            id: "mlflow-noauth",
            processPatterns: ["python", "mlflow", "gunicorn", "uvicorn"],
            title: loc("MLflow Tracking Server が認証なしで公開されています"),
            description: loc("このポートで MLflow の実験一覧(/api/2.0/mlflow/experiments/search)がログインなしで返りました。MLflow は既定では認証がなく、届く相手は誰でも実験名・パラメータ・指標・成果物の保存先を読め、実験やモデルの登録・削除もできます。成果物(学習済みモデルなど)を差し替えられると、それを読み込む側でコードが実行される恐れがあります。"),
            recommendation: loc("--host 127.0.0.1 で起動し直してください。ネットワークに出す必要がある場合は、MLflow の basic-auth(--app-name basic-auth)か、認証付きのリバースプロキシの内側に限定してください。"),
            probeOnly: true
        ),
        Signature(
            id: "gradio-noauth",
            processPatterns: ["python", "gradio"],
            title: loc("Gradio アプリが認証なしで公開されています"),
            description: loc("このポートで Gradio アプリの設定(/config)がログインなしで返りました。Gradio は auth を指定しない限り誰でも操作でき、アプリが持つ機能(ファイルの読み書き、モデルや外部コマンドの実行など)がそのまま使われます。server_name を 0.0.0.0 にした場合や、share=True の公開リンクで起きる状態です。"),
            recommendation: loc("launch() に auth=(ユーザー名, パスワード) を指定し、server_name は 127.0.0.1 にしてください。share=True の公開リンクは使わないでください。"),
            probeOnly: true
        ),
    ]

    /// Returns every signature whose process pattern matches the given
    /// process name or executable path. Matching is case-insensitive
    /// substring matching against both, since `lsof`/`ps` naming can vary
    /// slightly (a wrapper script vs. the real binary basename).
    static func match(processName: String, executablePath: String?) -> [Signature] {
        let processLower = processName.lowercased()
        let exeBasenameLower = (executablePath as NSString?)?.lastPathComponent.lowercased() ?? ""

        return signatures.filter { signature in
            signature.processPatterns.contains { pattern in
                let pattern = pattern.lowercased()
                return processLower.contains(pattern) || exeBasenameLower.contains(pattern)
            }
        }
    }
}

/// Local AI runtimes recognised from the listening port and from the response headers the port audit
/// already reads (`PortSecurityAuditor.probeHTTPService`: one GET to 127.0.0.1, headers only; no body and
/// no page title is read).
///
/// Two confidence tiers, and the tier decides what a match may do:
/// - `confirmed`: a single-purpose default port (Ollama, 11434) or a marker the product itself puts in a
///   response (llama.cpp's server names itself in the `Server` header), or a header marker that agrees with
///   the product's default port.
/// - `likely`: a port that is the product's default but shared with other software (ComfyUI, LiteLLM,
///   Ray Dashboard, Gradio, LM Studio, vLLM-style servers), or a header that a fronting proxy could also
///   forward (`x-litellm-*`, TGI's `x-compute-type` family). A `likely` match is reported at warning level
///   at most, and only when the port is reachable from the network; it never raises a finding above the
///   plain port finding.
///
/// Only products whose defaults are documented by the products themselves are listed. The Linux edition
/// has the same catalog.
enum LocalAIRuntime {
    enum Confidence: String, Equatable { case confirmed, likely }

    struct Match: Equatable {
        let product: String
        let confidence: Confidence
        /// What matched: `port`, `header`, `server-banner`.
        let basis: [String]
    }

    private struct Entry {
        let product: String
        /// Default port of the product, if it has one.
        let port: Int?
        /// The port is single-purpose, i.e. alone enough for `confirmed`.
        let portIsDedicated: Bool
        /// Lower-cased header-name prefixes that only this product emits.
        let headerPrefixes: [String]
        /// Exact lower-cased header names that only this product emits.
        let headerNames: [String]
        /// Substring of the (lower-cased) `Server` header that names the product.
        let serverBanner: String?
    }

    private static let catalog: [Entry] = [
        Entry(product: "Ollama", port: 11434, portIsDedicated: true, headerPrefixes: [], headerNames: [], serverBanner: nil),
        Entry(product: "LM Studio server", port: 1234, portIsDedicated: false, headerPrefixes: [], headerNames: [], serverBanner: nil),
        Entry(product: "Gradio / AI web UI", port: 7860, portIsDedicated: false, headerPrefixes: [], headerNames: [], serverBanner: nil),
        Entry(product: "vLLM-style inference server", port: 8000, portIsDedicated: false, headerPrefixes: [], headerNames: [], serverBanner: nil),
        Entry(product: "ComfyUI", port: 8188, portIsDedicated: false, headerPrefixes: [], headerNames: [], serverBanner: nil),
        Entry(product: "Ray Dashboard", port: 8265, portIsDedicated: false, headerPrefixes: [], headerNames: [], serverBanner: nil),
        Entry(product: "LiteLLM proxy", port: 4000, portIsDedicated: false, headerPrefixes: ["x-litellm-"], headerNames: [], serverBanner: nil),
        // Text Generation Inference puts these timing/token headers on its generation responses; they
        // may be absent from a plain GET of "/", in which case nothing matches here.
        Entry(product: "Text Generation Inference", port: nil, portIsDedicated: false, headerPrefixes: [],
              headerNames: ["x-compute-type", "x-prompt-tokens", "x-generated-tokens", "x-compute-time"], serverBanner: nil),
        Entry(product: "llama.cpp server", port: nil, portIsDedicated: false, headerPrefixes: [], headerNames: [], serverBanner: "llama.cpp"),
    ]

    /// Ports the plain port audit (`checkKnownDangerousPort`) already reports on, so a port-only match there
    /// adds data but no second finding.
    static let portsWithPlainFinding: Set<Int> = [11434, 1234, 7860, 8000]

    /// `headers` are the lower-cased response headers of the port's HTTP root, if it answered.
    static func identify(port: Int, headers: [String: String]?) -> [Match] {
        var out: [Match] = []
        for entry in catalog {
            var basis: [String] = []
            let portMatches = entry.port == port
            if portMatches { basis.append("port") }
            var headerMatches = false
            if let headers {
                headerMatches = headers.keys.contains { key in
                    let k = key.lowercased()
                    return entry.headerNames.contains(k) || entry.headerPrefixes.contains { k.hasPrefix($0) }
                }
                if headerMatches { basis.append("header") }
                if let banner = entry.serverBanner, (headers["server"] ?? "").lowercased().contains(banner) { basis.append("server-banner") }
            }
            guard !basis.isEmpty else { continue }
            let confirmed = basis.contains("server-banner")
                || (portMatches && entry.portIsDedicated)
                || (portMatches && headerMatches)
            out.append(Match(product: entry.product, confidence: confirmed ? .confirmed : .likely, basis: basis))
        }
        return out
    }
}
