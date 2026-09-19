// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.46 (build 103).
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
enum ServiceSignatures {

    struct Signature {
        let id: String
        /// Case-insensitive substrings matched against the process name or
        /// executable basename.
        let processPatterns: [String]
        let title: String
        let description: String
        let recommendation: String
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
