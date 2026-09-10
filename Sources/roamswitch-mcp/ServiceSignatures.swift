// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.19 (build 76).
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
