// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.6.2 (build 35).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

public enum SecurityLevel: String, Codable, CaseIterable, Identifiable {
    case open = "open"          // 信頼 (オープン)
    case balanced = "balanced"  // 標準保護
    case lockdown = "lockdown"  // 最大ロックダウン

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .open: return loc("🟢 信頼 (オープン - 保護解除)")
        case .balanced: return loc("🟡 標準保護 (ファイアウォール&ステルス)")
        case .lockdown: return loc("🔴 最大ロックダウン (共有・AirDrop停止)")
        }
    }

    public var shortName: String {
        switch self {
        case .open: return loc("信頼(オープン)")
        case .balanced: return loc("標準保護")
        case .lockdown: return loc("ロックダウン")
        }
    }

    public var firewallBlockAll: Bool {
        switch self {
        case .open: return false
        case .balanced, .lockdown: return true
        }
    }

    public var sharingServicesEnabled: Bool {
        switch self {
        case .open, .balanced: return true
        case .lockdown: return false
        }
    }

    public var airDropDisabled: Bool {
        switch self {
        case .open, .balanced: return false
        case .lockdown: return true
        }
    }
}

public struct TrustedNetwork: Identifiable, Codable, Equatable {
    public var id: String { macAddress }
    public let macAddress: String
    public var name: String
    public var securityLevel: SecurityLevel
    public var createdAt: Date

    public init(
        macAddress: String,
        name: String,
        securityLevel: SecurityLevel = .balanced,
        createdAt: Date = Date()
    ) {
        self.macAddress = macAddress
        self.name = name
        self.securityLevel = securityLevel
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case macAddress
        case name
        case securityLevel
        case createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        macAddress = try container.decode(String.self, forKey: .macAddress)
        name = try container.decode(String.self, forKey: .name)
        securityLevel = try container.decodeIfPresent(SecurityLevel.self, forKey: .securityLevel) ?? .balanced
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}
