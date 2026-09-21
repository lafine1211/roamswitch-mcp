// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.50 (build 107).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

// Simplified Chinese (zh-Hans) content for `RoamSwitchKnowledgeBase`.
// Translated from the Japanese source (`RoamSwitchKnowledgeBaseContent_ja.swift`).
// Every entry id here must also exist in every other
// `RoamSwitchKnowledgeBaseContent_<lang>.swift` file.
extension RoamSwitchKnowledgeBase {
    static func labelsZhHans() -> MarkdownLabels {
        return MarkdownLabels(
            featuresTitle: "RoamSwitch 功能规格与内部结构指南",
            featuresIntro: "全面讲解 RoamSwitch 所有安全功能的工作原理、默认值与限制事项。",
            alertsTitle: "RoamSwitch 通知与警告消息处理指南",
            alertsIntro: "RoamSwitch 显示的通知横幅、警告和紧急弹窗一览，汇总了触发原因、自动执行的防御措施以及推荐的处理步骤。",
            settingsTitle: "RoamSwitch 设置与运维指南",
            settingsIntro: "各项设置、开关、允许列表与策略的具体配置步骤。",
            troubleshootingTitle: "RoamSwitch 故障排除与常见问题",
            troubleshootingIntro: "关于常见问题、权限与批准、Homebrew / ClamAV / blueutil 的安装、误报处理以及隐私设计的官方解答。",
            summary: "概要",
            overview: "概览",
            detailsHeading: "详细信息与触发原因",
            adviceHeading: "处理方法",
            recommendation: "推荐",
            bestPractice: "推荐设置",
            advice: "建议"
        )
    }

    static func contentZhHans() -> [LocalizedEntry] {
        var list: [LocalizedEntry] = []
        list.append(contentsOf: featuresZhHansNetwork())
        list.append(contentsOf: featuresZhHansMalware())
        list.append(contentsOf: featuresZhHansAudit())
        list.append(contentsOf: alertsZhHansNetwork())
        list.append(contentsOf: alertsZhHansMalware())
        list.append(contentsOf: settingsZhHans())
        list.append(contentsOf: troubleshootingZhHansSetup())
        list.append(contentsOf: troubleshootingZhHansOperation())
        return list
    }

    // MARK: - Features: network & devices

    private static func featuresZhHansNetwork() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_network_autoswitch",
                title: "自动切换网络安全级别 & PF 数据包过滤（三级保护）",
                summary: "将当前网络网关的 MAC 地址与已注册网络进行比对，自动应用各网络对应的保护级别。未注册的网络将应用「外出默认保护」的级别（初始值：最大锁定）。免费版即可使用。",
                details: """
                • 🟢 信任（开放 - 解除保护）：适用于家中等场所。解除防火墙，允许共享服务（SSH / SMB / 屏幕共享）和 AirDrop。
                • 🟡 标准保护（防火墙和隐身模式）：适用于公司、网络共享（热点）等场所。通过 PF 数据包过滤和隐身模式阻止来自外部的探测，同时保留共享服务。
                • 🔴 最大锁定（停用共享与 AirDrop）：适用于咖啡馆、公共 Wi-Fi 及未注册网络。阻止所有入站连接，停止共享守护进程，并禁用 AirDrop。
                • 判定机制：网络变化时获取网关的 MAC 地址并与已注册网络比对。对于 DHCP 续租、Wi-Fi 漫游等网关不变的路由事件，会抑制重新判定的开销。
                • 内部结构：特权辅助程序 `RoamSwitchHelper`（通过 XPC）操作 `pfctl` 的专用锚点（anchor），在内核层面丢弃数据包。
                • 手动覆盖：可在菜单「手动覆盖」中为每个级别选择「直到网络断开 (推荐)」「仅1小时」「仅4小时」「直到手动解除」（参见 set_manual_override）。
                """,
                recommendation: "请通过菜单「注册当前网络」注册家中或安全的办公室网络，在其他场所则保持自动应用最大锁定的状态使用。"
            ),
            LocalizedEntry(
                id: "feat_network_history_guard",
                title: "网络历史学习 & Evil Twin（仿冒 Wi-Fi）检测 (Pro)",
                summary: "在本机学习已连接 Wi-Fi 的 SSID 与网关 MAC 地址的组合。当连接到名称与以往连接过的网络极为相似的未知 SSID 时，会作为疑似「Evil Twin（伪造接入点）」发出警告。",
                details: """
                • 学习内容：按 SSID 保存观测到的网关 MAC 地址（每个 SSID 最多 8 个，支持 Mesh Wi-Fi），存储于 `~/Library/Application Support/RoamSwitch/network_history.json`。最多保存 200 个 SSID，超出时从最旧的开始删除。不会向外部发送。
                • 相似 SSID 判定：以忽略大小写的编辑距离（莱文斯坦距离）进行比较。少于 6 个字符的短名称不在判定范围内，允许的距离根据名称长度为 1～2 个字符。对于「ASUS」「TP-Link_5G」这类默认 SSID 的偶然相似不会发出警告。
                • 抑制误报：同一网关设备广播不同名称 SSID（如访客网络）的情况不在判定范围内。以新的网关 MAC 连接已知 SSID（如更换路由器）时仅记录，不发出警告。
                • 在检测到 ARP 欺骗期间会跳过记录，以免将攻击者的 MAC 学习为正规地址。
                • 由于属于实时警告，通知仅在 Pro 版中发送。已学习的历史可通过 MCP 工具 `get_network_history` 查看。
                """,
                recommendation: "出现警告时，请勿在该 Wi-Fi 上输入认证信息，并确认网络名称和地点是否正规。同时使用 VPN 隧道（feat_vpn_tunnel）是最可靠的对策。"
            ),
            LocalizedEntry(
                id: "feat_arp_spoof_guard",
                title: "ARP 欺骗（网络冒充）检测 & 自动阻断 (Pro)",
                summary: "检测同一网络内攻击者冒充路由器来窃听、篡改通信的 ARP 欺骗（中间人攻击）。在最大锁定状态下会立即全面断网；在其他级别下则发出通知，由用户决定是否阻断。",
                details: """
                • 检测原理：检测默认网关的 IP 地址保持不变而对应 MAC 地址突然改变的情况。除网络变化事件外，还以每 15 秒一次的独立轮询进行监视，可捕获在连接过程中才开始的攻击。
                • 检测后的行为：在最大锁定的网络上立即执行气隙隔离（feat_airgap_containment）。在信任、标准保护的网络上仅发出通知，可从菜单「端口与设备监控」中的「检测到 ARP 欺骗 — 立即全部断网」手动触发。这是为了防止路由器重启或 Mesh Wi-Fi 切换导致误触发，以及防止攻击者仅用一个伪造 ARP 就能让通信中断的滥用。
                • 默认值：菜单「检测到 ARP 欺骗（网络冒充）时自动阻止 (Pro)」。首次激活 Pro 许可证时自动开启（set_pro_default_guards）。
                • 定位：属于检测后的事后对策。事前防范由网关 ARP/NDP 固定（feat_gateway_arp_lock）和 VPN 隧道（feat_vpn_tunnel）负责。
                • 事件会以 MITRE ATT&CK T1557 记录到事件历史（feat_containment_incident_timeline）中。
                """,
                recommendation: "请保持默认启用。如需更强的中间人攻击防护，请同时使用 VPN 隧道；如需无需额外基础设施的预防措施，请同时使用网关 ARP/NDP 固定。"
            ),
            LocalizedEntry(
                id: "feat_gateway_arp_lock",
                title: "网关 ARP/NDP 固定（预防） (Pro)",
                summary: "在连接到不受信任的网络时，将网关、IPv6 路由器以及同一链路上 DNS 服务器的 MAC 地址静态固定到邻居缓存中，事先防范基于 ARP/NDP 欺骗的中间人攻击。默认关闭。",
                details: """
                • 启用方法：菜单「端口与设备监控」→「在不受信任的网络上固定网关 ARP/NDP（预防） (Pro)」。
                • 工作方式：连接时获取当前 MAC 地址，由辅助程序通过 `arp -s` / `ndp -s` 固定为 permanent 条目。固定后，内核会忽略伪造的 ARP 应答和邻居通告。
                • 范围：仅限上述 3 类条目。在信任（开放）网络上不会固定，因此重启家中路由器不会导致无法通信。每次网络变化时会先解除再重新固定。
                • 局限性（TOFU）：由于采用信任首次观测到的 MAC 的方式，如果攻击者在连接之前就已潜伏，可能会固定伪造的 MAC。若不希望依赖这一前提，请使用 VPN 隧道。
                • 会反映在 Mac 安全综合诊断的「网关 ARP 固定（预防性中间人攻击防护）」项目中。
                """,
                recommendation: "在难以准备 VPN 时，可作为轻量级的中间人攻击对策使用。也可以与 VPN 隧道同时使用（VPN 为主，此功能为辅）。"
            ),
            LocalizedEntry(
                id: "feat_vpn_tunnel",
                title: "VPN 隧道（WireGuard / Tailscale，带终止开关） (Pro)",
                summary: "在不受信任的网络上自动连接加密隧道，使中间人攻击失效。后端可在 WireGuard（配置文件）与 Tailscale（出口节点）之间选择。这是不依赖 L2（ARP/NDP）完整性的中间人攻击主力对策，无需 Network Extension 权限（entitlement）。",
                details: """
                • 选择后端：菜单「端口与设备监控」→「VPN 隧道 (不受信任网络的中间人攻击防护) (Pro)」→「后端」中选择 WireGuard 或 Tailscale。只有所选的一方会运行。
                • WireGuard：需要 Homebrew 的 `wireguard-tools`（`brew install wireguard-tools`）。通过「导入 WireGuard 配置 (.conf)…」导入配置文件。配置文件需由用户自行准备（Mullvad、IVPN、Proton VPN、自建服务器、公司提供等）。RoamSwitch 不提供 VPN 服务器。
                • WireGuard 终止开关：在 pf 的 `block drop all` 基础上仅放行「lo / 隧道接口 / 到端点的 UDP 握手 / DHCP / ICMP」。即使隧道断开期间，明文流量也不会泄露。
                • Tailscale：面向已在使用 Tailscale 的用户。RoamSwitch 不负责安装和登录，只读取 `tailscale status` 并执行 `tailscale set --exit-node=<节点>`。必须选择出口节点（所有流量经由该节点）。所选节点离线时会在状态显示中提示。
                • Tailscale 推荐使用 CLI 版（standalone）：`brew install tailscale` → `sudo tailscaled install-system-daemon` → `sudo tailscale up`。App Store 版（GUI）无法从应用外部执行 `tailscale set`，因此请在 Tailscale 应用中选择出口节点，RoamSwitch 仅负责状态显示和终止开关。
                • Tailscale 终止开关（默认关闭，需手动启用）：在 pf 中仅放行「lo / Tailscale 的 utun / CGNAT 100.64.0.0/10 / DNS / STUN 3478 / 41641 / DERP tcp 443 / DHCP / ICMP」。这是比 WireGuard 宽松的「不易泄露」级别，在某些环境下可能妨碍 Tailscale 自身的连接，因此为可选项。
                • 自动应用：在不受信任的网络上连接隧道／出口节点，在受信任的网络上断开。许可证失效时会自动解除隧道和终止开关。
                """,
                recommendation: "如果经常使用公共 Wi-Fi，这是最有效的对策。Tailscale 用户可安装 CLI 版并使用 Tailscale 后端＋出口节点；其他用户使用 `brew install wireguard-tools` 加上 VPN 服务商提供的 `.conf` 来运行 WireGuard 最为简便。"
            ),
            LocalizedEntry(
                id: "feat_airgap_containment",
                title: "紧急气隙隔离（全面断网、关闭 Wi-Fi 无线、自动恢复故障保护）",
                summary: "在检测到勒索软件、XProtect 恶意软件检测、ARP 欺骗、ClickFix 等严重威胁时，阻断所有网络收发的通用紧急隔离机制。即使发生崩溃或重启，最多 10 分钟后通信也会自动恢复。",
                details: """
                • 阻断方式：特权辅助程序向 pf 加载 `block drop all`（仅允许回环），并回读以确认已生效。不仅阻断入站，也阻断出站，可防止密钥或数据被外传至 C2 服务器。如果应用失败，最多重试 3 次（每次超时 8 秒）；仍失败时会明确提示「自动断网失败」并引导手动断网（绝不会在未隔离的情况下显示为已隔离）。
                • 同时关闭 Wi-Fi 无线：pf 阻断只是拦截数据包，无线网卡本身仍保持连接。因此在 ARP 欺骗、勒索软件、XProtect 联动的隔离中，还会通过 `networksetup` 关闭 Wi-Fi 无线本身（默认开启，内部设置 `RoamSwitch.AirGapAutoWiFiKillEnabled`）。ClickFix 防护触发的隔离不会关闭无线。
                • 解除：从紧急弹窗或通知中解除后，pf 阻断和 Wi-Fi 无线都会恢复。
                • 故障保护：即使应用崩溃或长时间未解除，辅助程序端的计时器也会在 10 分钟后强制解除阻断并恢复 Wi-Fi 无线。应用重启或 Mac 重启后也无需手动操作即可恢复。
                • 启动闸门：Mac 刚启动、应用尚未应用策略期间，启动闸门（默认拒绝的 pf 规则）会生效，最多 90 秒后自动解除。
                """,
                recommendation: "隔离触发后，请先确认通知内容，结束可疑应用或进行扫描后再解除。若已确认是误报，可以立即解除。"
            ),
            LocalizedEntry(
                id: "feat_port_anomaly_guard",
                title: "自动阻止未知监听端口 & 开发服务器外部隔离 (Pro)",
                summary: "监视所有处于监听状态的 TCP 端口，当此前未对外公开的可执行文件突然开始在 0.0.0.0 上监听时，自动阻止外部局域网对该端口的访问。也可一键隔离开发服务器或本地 AI 服务器（仅限 127.0.0.1）。",
                details: """
                • 监视：每 20 秒扫描一次监听端口。由于以可执行文件路径进行识别，已知应用仅更改端口号不会触发反应。启用后立即将当前状态记录为基线。
                • 自动阻止：未知可执行文件开始对外公开时，通过 pf 仅阻止来自外部的访问（Mac 本机和 localhost 仍可使用）。即使不了解恶意软件的种类，也能捕获零日攻击植入的后门。
                • 排除对象：`/System/Library` 和 `/usr/libexec` 下由 Apple 签名的系统守护进程（如 rapportd 等 Handoff、AirPlay、AirDrop 运行所需的进程）。由 `/usr/bin/python3`、`/usr/bin/nc` 等 `/usr/bin` 下通用工具发起的监听仍在监视范围内。
                • 危险服务警告：识别并警告常在无认证状态下公开的 Redis (6379)、MongoDB (27017)、Memcached (11211)、Elasticsearch (9200)、VNC (5900)，以及 Ollama (11434)、LM Studio (1234)、Gradio (7860)、vLLM (8000) 等本地 AI 服务器。
                • 开发服务器隔离：在菜单「外部公开端口」中打开目标端口，点击「执行外部隔离」即可封锁为仅限 127.0.0.1 访问（Pro）。
                • 误报时：通过通知中的「允许」按钮或端口诊断界面永久允许。关闭此防护（或许可证失效）后，自动创建的所有阻止规则都会被解除。
                • 默认值：首次激活 Pro 许可证时自动开启。检测历史可通过 MCP 的 `get_port_anomaly_incidents` 查看。
                """,
                recommendation: "请将开发服务器和本地 LLM 绑定到 `127.0.0.1` 启动（例如：`OLLAMA_HOST=127.0.0.1 ollama serve`、`npm run dev -- -H 127.0.0.1`）。"
            ),
            LocalizedEntry(
                id: "feat_active_vuln_scan",
                title: "实证型漏洞验证（主动可达性确认）— 默认关闭",
                summary: "针对在本 Mac（127.0.0.1）上检测到的服务，以最少量的只读探测确认其是否会在无认证的情况下实际响应。默认关闭，需要明确选择启用，并在每次执行时确认。",
                details: """
                • 启用方法：菜单「端口与设备监控」→「实证型漏洞验证（主动可达性确认）」。该选项只是解锁端口诊断界面中的「执行实证验证」按钮，单独开启不会发送任何内容。每次执行时也会确认「是否发送验证请求？」。
                • 仅针对 127.0.0.1：绝不会向其他主机发送任何内容。
                • 无认证确认：向 Redis（PING）、Memcached（stats）、MongoDB（listDatabases）发送单次、短超时的非破坏性探测。
                • 通用开发服务器诊断：检查 CORS 配置错误（Origin 反射＋允许凭据）、路径遍历和开放重定向。
                • 已知 CVE 版本比对：通过非破坏性查询获取可无认证访问的 Redis / Memcached 版本，并与已知 CVE 的受影响版本范围进行比对。不会发送攻击载荷。
                • 也可通过 MCP 工具 `run_active_vuln_scan` 执行（只有该工具会与本地主机通信）。
                """,
                recommendation: "仅在您想确认自己 Mac 上运行的 Redis、Docker、本地 LLM 等是否确实处于无认证即可访问的状态时启用。"
            ),
            LocalizedEntry(
                id: "feat_nmap_nse",
                title: "nmap NSE 补充扫描（实证型漏洞验证的附加层）",
                summary: "仅在「实证型漏洞验证」同时启用时，使用系统已安装的 nmap 对暴露端口额外运行「safe」类别的 NSE 脚本，以补充本产品自身探测所不具备的协议覆盖范围（SSH 主机密钥、SMTP 响应等）。结果是 nmap 自身的判定，本产品不做独立验证。",
                details: """
                • 自动执行：只要「实证型漏洞验证（能动可达性验证）」已启用即会自动执行，没有独立的开关设置。nmap 不会被自动安装——仅当系统中已安装（例如通过 Homebrew）时才会生效，否则不执行任何操作。
                • 脚本选择：`safe and not broadcast and not external`。仅靠「safe」类别本身并不足够——`broadcast` 类脚本会以多播/广播方式查询整个局域网，而不仅是目标主机；`external` 类脚本（如 `vulners.nse`）会将检测到的服务/版本实际发送给 vulners.com 等第三方。两者都违背了本产品「仅访问 127.0.0.1、绝不接触任何其他主机或外部服务器」的设计原则，因此被排除。
                • 超时：每个脚本 15 秒（`--script-timeout 15s`）。部分「safe」脚本针对非标准 HTTP API 可能无限期运行，若无此限制会导致其他端口的结果丢失。
                • 范围：与实证型漏洞验证自身相同的、已确认开放的端口。
                """,
                recommendation: "请将 nmap 的发现仅作为参考信息，核实内容后如确实相关再采取行动。"
            ),
            LocalizedEntry(
                id: "feat_usb_keyboard_guard",
                title: "非法 USB / BadUSB 物理端口防护（键盘批准 & 按键时序分析） (Pro)",
                summary: "当连接未知的 USB 键盘或改装 USB 线缆（Rubber Ducky / O.MG Cable / Flipper Zero 等）时，在批准之前拦截该设备的按键输入，防止自动命令注入。此外还会根据按键间隔分析自动脚本的迹象并发出警告。",
                details: """
                • 检测：通过 IOHIDManager 实时检测新键盘的连接。内置键盘会被自动信任。
                • 拦截：独占未批准的设备（IOHIDDevice 的 seize），使仅该设备的按键输入无法到达系统。其他键盘可正常使用。仅在无法独占时，才切换为使用辅助功能权限的 CGEventTap 进行拦截。
                • 批准：在最前端的批准窗口中选择「信任并允许」或「拒绝并保持拦截」。允许的键盘会被加入允许列表。
                • 按键时序分析：即使在拦截期间也会测量该设备的按键间隔。在 5 次以上的输入中，若平均间隔不超过 12ms，或平均不超过 45ms 且极为均匀（变异系数不超过 0.35），则作为「自动化(脚本)输入的迹象」发出警告。这是捕捉人类打字所没有的机械速度与均匀性的辅助信号，不影响拦截判断本身。
                • 默认关闭。通过菜单「端口与设备监控」→「非法 USB / BadUSB 物理端口防护 (Pro)」启用，并在「USB / BadUSB 防护设置…」中管理允许列表。
                """,
                recommendation: "使用外接键盘时，请只将自己连接的键盘通过「信任并允许」注册。出现脚本迹象警告的设备，请务必拒绝并拔下。"
            ),
            LocalizedEntry(
                id: "feat_usb_storage_guard",
                title: "自动阻止非法 USB 存储设备 & ClamAV 自动扫描 (Pro)",
                summary: "当连接不在允许列表中的 U 盘或外部存储设备时，会先以只读方式挂载并请求批准。已允许的设备也会先经 ClamAV 扫描，再以设定的权限连接。",
                details: """
                • 监视：通过 DiskArbitration 即时捕获外部、可移动卷的挂载。
                • 未注册设备：出于安全考虑以只读方式重新挂载，并显示可选择「允许读写」「以只读方式允许」「退出」的对话框。选择退出后会立即卸载并弹出。
                • 已允许设备：自动应用允许列表中的权限（只读 / 读写均可）。在提升为读写之前会先用 ClamAV 扫描。
                • 感染时：检测到恶意软件后会自动弹出并发送紧急通知。
                • 支持重新格式化：即使卷 UUID 发生变化，只要包含序列号在内的硬件标识符一致，就会视为同一驱动器并沿用允许设置（仅厂商 ID/产品 ID 一致不视为匹配）。
                • 范围：用于防止通过存储设备外传数据或带入恶意载荷。伪装成键盘的 HID 型 BadUSB 由 feat_usb_keyboard_guard 负责。
                """,
                recommendation: "请只将工作中使用的安全 U 盘加入允许列表；在处理机密数据的 Mac 上，建议以「只读」方式允许。"
            ),
            LocalizedEntry(
                id: "feat_bluetooth_guard",
                title: "在不受信任的网络自动关闭 Bluetooth (Pro)",
                summary: "连接到应用最大锁定的外出网络时，自动关闭 Bluetooth，减少遭受非法配对和 BLE 攻击的风险。回到受信任的网络后会自动恢复。",
                details: """
                • 工具协作：macOS 没有供应用切换 Bluetooth 电源的公开 API，因此使用 Homebrew 的开源工具 `blueutil`（`brew install blueutil`）。未安装时，菜单中会显示安装引导。
                • 恢复：仅当关闭前 Bluetooth 处于开启状态时，才会在受信任的网络上重新开启。不会覆盖用户在外出期间自行切换的状态。
                • 默认关闭：许多人在咖啡馆使用 AirPods 等设备，擅自切断音频会造成不便，因此需手动启用。
                """,
                recommendation: "如果在外出时不使用 Bluetooth 设备，请启用此功能，防止周围的无线探测和非法配对。"
            ),
        ]
    }

    // MARK: - Features: malware & web protection

    private static func featuresZhHansMalware() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_webmail_download_guard",
                title: "网页与邮件保护（下载文件自动扫描 & 自动隔离） (Pro)",
                summary: "通过 FSEvents 监视从浏览器、邮件、Slack、Discord 等保存的文件，使用静态特征检测和 ClamAV 自动扫描，并将威胁隔离到隔离文件夹。",
                details: """
                • 监视对象：默认为 `~/Downloads`、`~/Desktop`、`~/Documents` 以及邮件的下载文件夹。可通过「⚙️ 管理监控文件夹…」添加或删除。
                • 识别下载来源：根据 macOS 附加的 `com.apple.quarantine` 扩展属性判断下载来源应用。
                • 双重检测：执行本机静态特征检测（如反向 Shell 的典型命令等，未安装 ClamAV 也可运行）和 ClamAV 检测。由静态特征检测到的文件无论 ClamAV 结果如何都会被隔离；若 ClamAV 未匹配，通知中会注明「可能是误报」。
                • 隔离：威胁会被移动到 `~/Library/Application Support/RoamSwitch/Quarantine/`（不会删除）。移动失败时会明确提示「隔离失败」，并引导手动删除。
                • EICAR 测试文件：对于业界标准的无害测试签名，既不隔离也不阻止，也不发出通知，仅记录到通知历史中（feat_notification_history）。
                • 首次访问文件夹：在 macOS 的访问权限对话框出现之前，会显示一次说明，解释这是扫描功能所需的正规权限。
                • 关于 Pickle 格式 AI 模型的警告，请参见 feat_ai_model_guard。
                """,
                recommendation: "请在安装 ClamAV 后启用此功能；如果浏览器的保存位置设置为自定义文件夹，请将其添加到监控文件夹中。"
            ),
            LocalizedEntry(
                id: "feat_ai_model_guard",
                title: "危险 AI 模型格式（Pickle / PyTorch）下载警告 (Pro)",
                summary: "当从 HuggingFace、Civitai 等下载 `.pkl` / `.pickle` / `.pt` 格式的模型文件时，警告其为加载时可执行任意代码的 Pickle 格式，并建议使用 SafeTensors / GGUF 格式。",
                details: """
                • 检测：判断在网页与邮件保护（feat_webmail_download_guard）监视范围内下载的文件扩展名。
                • 风险：Python 的 Pickle 在反序列化时可执行任意代码，因此仅加载恶意模型就可能导致感染。
                • 行为：仅发出警告通知，不隔离文件（如果 ClamAV 或静态特征检测到威胁，则照常隔离）。
                """,
                recommendation: "请勿加载来源不明的 Pickle / PyTorch 格式模型，请使用 `.safetensors` 或 `.gguf` 格式的模型。"
            ),
            LocalizedEntry(
                id: "feat_quarantine_manager",
                title: "管理隔离文件（隔离区、还原、删除、扫描排除）",
                summary: "被 ClamAV 或静态特征检测到的文件不会被删除，而是保存在隔离区中。可在「管理隔离文件」界面中查看隔离原因、还原到原位置、彻底删除或从扫描对象中排除。",
                details: """
                • 打开方式：菜单「恶意软件防护 (XProtect & ClamAV)」→ ClamAV →「📦 管理隔离文件…」，或网页与邮件保护中的「📦 打开隔离管理器…」。
                • 保存位置：`~/Library/Application Support/RoamSwitch/Quarantine/`。原路径、威胁名称和隔离时间会作为元数据保存。除非用户明确选择「彻底删除」，文件不会消失。
                • 还原：仅在确信文件未被感染时，将其放回原位置。
                • 排除并还原：在确信是误报时，将文件放回原位置，并将该路径从今后的 ClamAV 扫描对象中排除（仅限完全一致的路径）。可在同一界面的「已从扫描中排除的路径」中点击「取消排除」撤销排除。
                • 彻底删除：经确认对话框后删除，无法撤销。
                • 可通过 MCP 工具 `get_quarantine_status` 查看隔离中的文件列表。
                """,
                recommendation: "对于没有印象的文件，请选择「彻底删除」；仅在自制脚本、开发用二进制文件等确定是误报的情况下，才使用「排除并还原」。"
            ),
            LocalizedEntry(
                id: "feat_xprotect_file_safety",
                title: "Apple XProtect 运行状态确认 & 文件/应用安全性诊断",
                summary: "显示 Apple 内置恶意软件防护 XProtect 的定义版本和运行状态，并可针对任意文件或应用，综合诊断 Apple 公证（Notarization）、签名发行者、Team ID 和下载隔离属性。免费版即可使用。",
                details: """
                • 打开方式：菜单「恶意软件防护 (XProtect & ClamAV)」→「🍏 Apple XProtect」→「查看 XProtect 运行状态…」「检查文件/应用安全性…」。
                • 诊断项目：是否经 Apple 认证（Notarized / Gatekeeper）、签名发行者、Team ID、是否带有 Web 下载隔离属性（`com.apple.quarantine`）、目标路径。
                • 用途：在首次打开获取的应用之前，可确认其是否由正规开发者签名并经过公证。
                """,
                recommendation: "对于来源不明的应用，请在启动前进行安全性诊断；若未经认证或无签名，请勿打开。"
            ),
            LocalizedEntry(
                id: "feat_dns_threat_guard",
                title: "DNS 威胁防护（拦截恶意网站与 C2） (Pro)",
                summary: "应用 Quad9、Cloudflare、AdGuard、CleanBrowsing 的安全 DNS，在 DNS 解析阶段阻止对恶意软件 C2 服务器和钓鱼网站的域名解析。",
                details: """
                • 服务商：Quad9（9.9.9.9 / 149.112.112.112）、Cloudflare Security（1.1.1.2 / 1.0.0.2）、AdGuard DNS（94.140.14.14 / 94.140.15.15，同时拦截广告与跟踪器）、CleanBrowsing Security（185.228.168.9 / 185.228.169.9）。
                • 应用策略：「仅在不可信Wi-Fi应用（推荐）」或「在所有网络中始终应用（包含信任网络）」。
                • 内部控制：特权辅助程序切换当前活动网络服务的 DNS 设置，回到受信任的网络后恢复原来的 DHCP / 手动 DNS 设置。
                • 状态显示：菜单中显示「🟢 安全DNS生效中」或「🏠 受信任网络（使用路由器默认DNS）」，并反映在 Mac 安全综合诊断的项目中。
                """,
                recommendation: "为防止公共 Wi-Fi 上的伪造 DNS（DNS 劫持）和连接恶意域名，建议从 Quad9＋「仅在不可信Wi-Fi应用」开始使用。"
            ),
            LocalizedEntry(
                id: "feat_passive_link_guard",
                title: "链接保护（钓鱼连接检测与拦截：系统扩展 / 支持 DoH / 警告模式故障关闭） (Pro)",
                summary: "基于已知诈骗网站名单（威胁情报源）和品牌仿冒域名判定，无论使用何种浏览器或应用，都在本机阻止连接钓鱼和诈骗网站。通过内容过滤系统扩展运行，批准前以 /etc/hosts 黑洞（sinkhole）方式代替。",
                details: """
                • 模式：「关闭」「仅警告（不拦截）」「自动拦截明显的钓鱼网站（推荐）」。默认为自动拦截。可在菜单「恶意软件防护」→「链接保护（钓鱼连接检测）(Pro)」中切换。
                • 拦截对象：仅限威胁情报源中收录的域名，或品牌名称的 Unicode 同形异义字（homograph）仿冒等明确情况。子域名仿冒、高风险 TLD 等按警告处理。判定引擎和情报源与 Linux 版相同。
                • 系统扩展（推荐）：内容过滤系统扩展 `RoamSwitchLinkFilter` 检查域名解析后的 TCP 通信。除了操作系统的域名解析信息外，还会读取 TLS ClientHello 中的 SNI，因此即使浏览器使用自带的 DoH / DoT 也能判定。在拦截模式下，会阻止无法读取 SNI 的 QUIC（UDP 443），使浏览器回退到 TCP。首次使用需要在系统设置中批准。
                • JA3 指纹：对于能读取 SNI 的 TLS 连接，还会计算客户端的 JA3 哈希，并与威胁情报源中的 JA3 列表比对（对没有 SNI 的连接不进行单独的 JA3 判定）。
                • 警告模式（故障关闭）：暂停相应的通信，并显示「允许 / 阻止」通知和最前端面板，根据回答恢复或丢弃通信。若约 8 秒内未回答则阻断通信（阻断结果不缓存，下次访问时会再次确认）。用户选择的允许或阻止会被记住。警告模式需要系统扩展。
                • hosts 回退：在系统扩展未生效期间，拦截模式下由特权辅助程序将目标域名以 `0.0.0.0` 写入 `/etc/hosts` 的托管区段。
                • 威胁情报源：每天获取一次，仅接收（不发送标识符）。使用情报源专用的 Ed25519 密钥进行签名验证（与应用更新用的密钥分开）。关闭「自动更新」后对外通信为零，仅依靠随附数据和同形异义字检测运行。
                • 非 Pro：模式会被保存，但不会执行拦截。
                """,
                recommendation: "保持默认的自动拦截并批准系统扩展是最可靠的用法。如果内部工具等被误拦截，请使用通知中的「本次允许（5 分钟）」或允许列表处理。"
            ),
            LocalizedEntry(
                id: "feat_link_safety_auditor",
                title: "链接安全性诊断（手动检查・Zero Telemetry）",
                summary: "在浏览器中打开可疑 URL 之前，仅在本机进行分析，根据 Unicode 同形异义字仿冒、子域名仿冒、高风险 TLD、明文 HTTP、直接使用 IP 等因素，以 100 分制诊断危险程度。免费版即可使用。",
                details: """
                • 打开方式：菜单「恶意软件防护」→「🔗 手动检查链接…」，或 MCP 工具 `audit_url_safety`。
                • 同形异义字仿冒：检测使用西里尔字母、希腊字母等进行的仿冒（Punycode / `xn--`）。
                • 子域名仿冒：分析像 `apple.com.login-verify.xyz` 这样混入知名品牌名称的结构。
                • 高风险 TLD：对 `.xyz`、`.top`、`.tk`、`.icu` 等常被一次性钓鱼网站使用的 TLD 扣分。
                • 明文 HTTP、直接使用 IP：对登录页面等未加密的 HTTP 以及裸 IP 地址 URL 发出警告。
                • 完全本地：不会将 URL 发送到外部诊断 API，因此机密 URL 和认证令牌不会泄露。
                """,
                recommendation: "对于通过邮件或聊天收到的可疑链接，请不要直接点击，先用链接安全性诊断进行确认。"
            ),
            LocalizedEntry(
                id: "feat_ransomware_canary_guard",
                title: "勒索软件诱饵文件检测 & 自主气隙隔离、进程冻结 (Pro)",
                summary: "在用户文件夹中放置隐藏的诱饵（金丝雀）文件，一旦检测到被篡改、删除或重命名，立即自动执行全面断网、停止共享服务，并暂停可疑进程（SIGSTOP）。",
                details: """
                • 诱饵文件：在 `~/Library/Application Support/RoamSwitch/CanaryGuard/` 中放置 4 个，并在「文稿」「桌面」「下载」「图片」中放置以 `.roamswitch_security_canary_do_not_delete` 开头的隐藏文件。每个文件的 SHA-256 会被记录为基线。
                • 检测：同时使用基于 kqueue 的实时监视和每 60 秒一次的定期检查。同一文件的连续事件以 10 秒冷却期防止重复处理。最近 60 秒内被修改的真实文件也会被记录为「可能受影响的文件」。
                • 自动响应：① 应用程序防火墙锁定 ② 气隙隔离（通过 pf 阻断所有收发＋关闭 Wi-Fi 无线，feat_airgap_containment）③ 停止共享服务（SMB / SSH / 屏幕共享）④ 暂停（SIGSTOP）而非强制结束可疑进程 ⑤ 发送紧急通知并显示最前端的紧急弹窗。
                • 冻结的原因：由于通信已被阻断，已暂停的进程无法进一步扩大损害。如果是误报，解除时可恢复运行（SIGCONT），不会丢失数据。
                • 解除时：恢复网络和 Wi-Fi，恢复已暂停的进程，并重新生成被篡改的诱饵文件。
                • 默认值：首次激活 Pro 许可证时自动开启。检测历史可通过 MCP 的 `get_canary_status` 查看。可通过菜单中的「🚨 勒索软件防御模拟测试（验证运行）…」安全地进行测试。
                """,
                recommendation: "为保护重要数据免受未知勒索软件侵害，请保持启用。请勿删除诱饵文件（隐藏文件）。"
            ),
            LocalizedEntry(
                id: "feat_ransomware_recovery",
                title: "勒索软件恢复（从事前快照中按文件取出）",
                summary: "为了回到加密之前的状态，RoamSwitch 会定期创建 APFS 本地快照，只把需要的文件取出并复制到其他位置。不会覆盖当前的文件。",
                details: """
                • 事前快照：与检测无关，默认每 6 小时创建一次（可选：关闭/1/3/6/12/24 小时）。检测之后创建的快照，可能已经包含被加密的文件。
                • 检测时快照：诱饵文件被触发时也会创建，但可能包含已加密的文件，不建议作为恢复来源。
                • 保留模式：当检测时快照是最新的快照时（最长 7 天），会暂停创建新的事前快照并暂停清理旧快照，避免加密前的最后一代被挤掉。
                • 取出：在菜单中选择「勒索软件恢复…」，即可把推荐快照（仍然存在的最新事前快照）中的文件或文件夹复制到 `~/RoamSwitch-Recovered/<快照ID>/`。不会覆盖已有文件，也不提供整体回滚。恢复始终由人工手动完成。
                • 限制：macOS 可能会在约 24 小时后自动删除本地快照（可用空间不足时更早），已经不存在的快照无法使用。取出文件需要 RoamSwitch 辅助程序拥有「完全磁盘访问权限」（创建快照不需要）。
                • MCP：只读的 `get_ransomware_recovery_snapshots` 可查看列表和推荐项（无法执行恢复）。
                • Pro: 此窗口（列表与取出文件）和 MCP 工具属于 Pro 功能。快照的创建本身在非 Pro 下也会运行。
                """,
                recommendation: "为防范勒索软件，请保持事前快照开启。发现受损后，请先断开网络，再从「推荐」的事前快照（而非检测时快照）中取出文件。"
            ),
            LocalizedEntry(
                id: "feat_runtime_threat_containment",
                title: "与 XProtect 恶意软件检测联动的自动断网 (Pro)",
                summary: "当 Apple 内置的 XProtect / XProtect Remediator 实际检测到或清除恶意软件时，立即紧急全面断网。对于 Gatekeeper 拦截未签名应用的情况不会断网，仅发出通知。",
                details: """
                • 信号来源：以 ndjson 格式持续订阅 `/usr/bin/log stream`（采用等待式而非轮询，空闲时 CPU 负载几乎为零），监视与 XProtect 相关的系统日志。
                • 阻断条件：仅当 XProtect 记录了严重（critical）的恶意软件检测时，才执行气隙隔离（包括关闭 Wi-Fi 无线）。无论网络的信任级别如何都会触发。
                • 与 Gatekeeper 的区别：开发者自行构建的未签名应用被阻止启动等日常发生的 Gatekeeper 事件，只会发出「Gatekeeper 已阻止未签名应用运行」的通知。
                • 判定一致性：与手动的「Mac 安全日志审计」共享同一套分类逻辑。
                • 由于设计上不使用 EndpointSecurity 权限（entitlement），因此不是执行前的拦截，而是「检测后立即隔离」。
                • 默认值：首次激活 Pro 许可证时自动开启（届时会提示一次已启用自动阻断）。状态可通过 MCP 的 `get_runtime_threat_status` 查看，并可通过「🚨 恶意软件检测联动 Air-Gap 模拟（功能测试）…」进行测试。
                """,
                recommendation: "请将其作为与 Apple 内置恶意软件防护联动的自动防御保持启用。即使在经常运行未签名自制应用的环境中，仅 Gatekeeper 的拦截也不会触发断网。"
            ),
            LocalizedEntry(
                id: "feat_clickfix_guard",
                title: "ClickFix 防护 — 检测到可疑终端命令时自动阻断 (Pro・默认关闭)",
                summary: "通过 Shell 历史记录检测「ClickFix」手法（伪造的 CAPTCHA 或错误页面诱导用户自己粘贴并执行命令），并紧急断网以阻止正在进行的多阶段攻击。",
                details: """
                • 监视对象：仅 `~/.zsh_history` 和 `~/.bash_history` 中新追加的行（已有历史记录不在范围内）。
                • 检测模式：① 已知的反向 Shell 典型命令（与静态特征检测共用）② 将 Base64 解码后的内容直接传给 Shell 或 `osascript` 的双重绕过模式。Homebrew 等正规安装程序使用的简单 `curl ... | bash` 不在检测范围内。
                • 自动响应：气隙隔离（不关闭 Wi-Fi 无线），最多 10 分钟后自动恢复。通知中会建议检查钥匙串（Keychain）、浏览器保存的密码和加密货币钱包是否安全。
                • 属于事后响应的原因：命令被记录到历史中时已经执行，但如果第二阶段下载、反向 Shell 连接、凭据外传等仍在进行中，立即断网即可阻止损害扩大。
                • Gatekeeper 无法防范的原因：只是用户的正规 Shell 按照输入内容执行，进程本身没有任何可疑之处。
                • 补充：还有在复制时即进行检测的剪贴板保护（feat_secret_leak_auditor），可覆盖粘贴到 Script Editor、Spotlight 等终端以外位置的情况。
                • 默认关闭：这是会自动断网的相对较新的启发式功能，因此需手动启用。
                """,
                recommendation: "如果希望防范被伪造错误页面或伪造 CAPTCHA 诱导执行命令的风险，请考虑启用。"
            ),
            LocalizedEntry(
                id: "feat_persistence_monitor_guard",
                title: "监控新增自动启动注册（LaunchAgent / LaunchDaemon） (Pro)",
                summary: "实时监视新的 LaunchAgent / LaunchDaemon 注册，检测直接启动 Shell 或脚本解释器的注册，以及注册了签名无效的可执行文件的情况，并发出通知。",
                details: """
                • 监视对象：通过 FSEvents 监视 `~/Library/LaunchAgents`、`/Library/LaunchAgents`、`/Library/LaunchDaemons`（约 1.5 秒防抖）。
                • 判定：近年来的信息窃取类恶意软件会让经过正规签名的 `/bin/bash` 或 `/usr/bin/osascript` 执行以 Base64 隐藏的脚本来实现持久化。由于解释器本身的签名是正确的，因此无论签名如何，直接启动原始解释器的注册都会被视为可疑，并用静态特征检查脚本参数。签名无效或未签名的可执行文件同样在检测范围内。Homebrew services 的包装程序除外。
                • 仅检测：由于不使用 EndpointSecurity 权限（entitlement），无法阻止 plist 的写入本身。会在写入后约 1.5 秒内完成判定并通知。
                • 默认值：Pro 版默认开启。可在菜单「恶意软件防护」→「监控新增自动启动注册(LaunchAgent/Daemon) (Pro)」中切换。
                """,
                recommendation: "收到陌生的自动启动注册通知时，请检查通知中显示的 plist 内容，若无印象请删除。如果是刚安装正规应用，则无需担心。"
            ),
            LocalizedEntry(
                id: "feat_docker_event_guard",
                title: "Docker 特权容器与 docker.sock 挂载检测 (Pro・默认关闭)",
                summary: "在新容器启动时，检测以 `--privileged` 启动的容器或挂载了 `/var/run/docker.sock` 的容器等可能导致容器逃逸的危险 Docker 配置，并发出通知。",
                details: """
                • 工作方式：每 20 秒通过 `docker ps` 仅检查新启动的容器，并用 `docker inspect` 检查其配置。由于使用与 Linux 版相同的判定格式，两个操作系统会检测相同的条件。
                • 仅通知：这属于危险的「配置」而非已确认的入侵（例如有意以特权模式运行监控代理等正当用途），因此不会自动阻断。
                • 默认关闭：大多数用户不使用 Docker，因此即使在 Pro 版中默认也是关闭的。
                • 测试：通过菜单中的「⚠️ Docker 风险检测模拟（验证运行）…」，无需使用 Docker 即可确认通知路径。
                """,
                recommendation: "如果在开发中使用 Docker，建议启用此功能以尽早发现容器逃逸风险。"
            ),
        ]
    }

    // MARK: - Features: audit, monitoring & platform

    private static func featuresZhHansAudit() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_critical_path_fim",
                title: "重要系统文件篡改监控（Critical Path FIM） (Pro)",
                summary: "记录 sudoers、SSH 配置、PAM、hosts 等在正规系统更新或应用安装中几乎不会改变的重要文件的 SHA-256 基线，检测修改、删除和新增并发出通知。",
                details: """
                • 对象：`/etc/sudoers`、`/etc/pam.d/sudo`、`/etc/ssh/sshd_config`、`/etc/ssh/sshd_config.d/` 下的文件、`/etc/hosts`、root 的 `~/.ssh/authorized_keys`。由于只有 root 权限才能读取，哈希由特权辅助程序计算。
                • 检测时机：通过 `/etc`、`/etc/pam.d`、`/etc/ssh` 的 FSEvents 近乎实时地重新扫描，并以每小时一次的定期扫描弥补遗漏。
                • 基线：记录首次扫描时的状态。检测到篡改后不会自动将新状态采纳为基线，因此在人工确认之前检测状态会一直持续（在应用运行期间，同一状态不会重复通知；若再次发生变化则会重新通知）。
                • 监控停止警告：连续 3 次无法连接辅助程序时，会通知篡改检测未在运行。
                • 补充：在链接保护以 hosts 回退方式运行期间，RoamSwitch 自身可能会改写 `/etc/hosts` 的托管区段。LaunchAgent / Daemon 由 feat_persistence_monitor_guard 负责。
                • 默认值：首次激活 Pro 许可证时自动开启。菜单「恶意软件防护」→「定期监控重要系统文件是否被篡改 (Pro)」。
                """,
                recommendation: "收到通知后，请确认是否为您自己进行的操作（如 `sudo visudo` 或修改配置）。若无印象，请立即检查相应文件的内容，并考虑更改密码。"
            ),
            LocalizedEntry(
                id: "feat_security_log_audit",
                title: "Mac 安全日志审计（手动・模板异常检测・复制供 AI 咨询）",
                summary: "从 macOS 统一日志中提取并分析 sudo 失败、SSH 连接、Gatekeeper 拦截、XProtect 检测和认证事件，同时列出新出现的日志模式和频率激增（模板异常）。免费版即可使用。",
                details: """
                • 打开方式：菜单「Mac 安全综合诊断」→「📜 Mac 安全日志审计…」，或 MCP 工具 `audit_security_logs`。
                • 时间范围：过去 24 小时 / 过去 3 天 / 过去 7 天。
                • 汇总卡片：Sudo 失败、SSH 连接、Gatekeeper 拦截、XProtect 检测、模板异常。可按类别筛选和搜索。
                • 模板异常检测：将 IP 地址、十六进制地址、数值等可变部分屏蔽后对日志进行模式化，提取本 Mac 上首次出现的模式（[新增]）以及明显偏离以往出现频率的激增（[激增 z=…]，z 分数 3 以上）。每种模式的频率在观测 3 次后完成学习，之后不再对常态化的模式发出通知。
                • 通俗判定：本机内基于规则的助手会显示面向非专业人士的结论和具体的检查事项（不使用外部 API）。
                • 输出：「复制报告」「复制供 AI 咨询的材料」（将可粘贴到 Claude 或 ChatGPT 的提问文本与日志一并复制，RoamSwitch 不会发送任何内容）、「导出 CSV (Pro)」。
                """,
                recommendation: "当可疑通知持续出现或感觉 Mac 行为异常时运行，确认是否有 XProtect 检测或 Sudo 失败的激增。"
            ),
            LocalizedEntry(
                id: "feat_scheduled_log_audit",
                title: "自动日志审计（定期学习新模式与频率异常） (Pro)",
                summary: "每小时在后台执行一次日志审计的模板异常检测，持续学习本 Mac 平常的日志趋势。检测到新模式或频率激增时，会附上实际日志行示例和通俗说明发出通知。",
                details: """
                • 执行间隔：每小时分析最近 1 小时的日志。启用约 10 秒后执行首次扫描，但由于其中包含应用自身的启动日志，该次仅进行学习而不发出通知。
                • 通知内容：异常数量（新模式与频率激增的明细）、最多 3 条实际日志行、学习状态说明，以及面向非专业人士的解释。包含频率激增时会在通知中心显示提醒；仅有新模式时则不会弹出提醒，只记录到通知历史中。新模式记录一次后即被视为「已知」，同样的内容不会再次记录。频率激增在该模式学习完成后将不再提醒。
                • 与手动审计的关系：与手动的「Mac 安全日志审计」及 MCP 的 `audit_security_logs` 共享相同的分析和学习数据。
                • 默认值：首次激活 Pro 许可证时自动开启。菜单「恶意软件防护」→「自动日志审计(定期学习新模式与频率异常) (Pro)」。
                """,
                recommendation: "刚开始使用时新模式的通知会稍多一些，随着学习的推进会逐渐减少。如果包含陌生的应用名称或 IP 地址，请在日志审计界面中查看详情。"
            ),
            LocalizedEntry(
                id: "feat_containment_incident_timeline",
                title: "遏制事件历史（统一时间线・MITRE ATT&CK 分类）",
                summary: "将 ARP 欺骗、勒索软件诱饵文件、XProtect 联动阻断、未知端口自动阻止这 4 种自动响应汇总为一条时间顺序记录并保存在本机。可事后回顾何时发生了什么、如何响应以及何时解除。",
                details: """
                • 记录内容：发生时间、检测来源、严重程度、概要、进程名称和 PID（如可获取）、执行的响应、解除时间和解除原因（手动解除 / 超时自动解除 / 加入允许列表）。
                • MITRE ATT&CK：仅在能够确定对应关系时才附加技术 ID（ARP 欺骗 = T1557，诱饵文件删除或重命名 = T1485，加密 = T1486，其他篡改 = T1565）。不进行推测性分类。
                • 保存：`~/Library/Application Support/RoamSwitch/containment_incident_timeline.json`（最新 200 条）。不会向外部发送。
                • 可通过 MCP 工具 `get_incident_timeline` 获取此统一时间线（也可用于在 Air-Gap 期间借助本地 AI 调查原因）。各功能的单独历史也可通过 `get_canary_status`、`get_port_anomaly_incidents`、`get_runtime_threat_status` 查看。
                """,
                recommendation: "发生自动阻断后，请结合此历史与通知历史进行确认，以帮助查明原因并防止再次发生。"
            ),
            LocalizedEntry(
                id: "feat_notification_history",
                title: "通知历史记录（过去7天）",
                summary: "将 RoamSwitch 发送的所有通知保存 7 天，便于事后查看错过的警告。像 EICAR 测试签名检测这类不发出通知、仅记录到历史中的事件，也可以在这里查看。免费版即可使用。",
                details: """
                • 打开方式：菜单「Mac 安全综合诊断」→「🔔 通知历史…」。
                • 保存期限：7 天。每次记录新通知时会自动删除旧记录。
                • 记录内容：时间、标题、正文。包括威胁警报、链接保护的连接事件、ClickFix 与机密密钥检测、各类自动阻断等。
                • EICAR 测试签名：业界标准的无害测试文件并非真正的威胁，因此既不隔离也不阻止，也不显示通知横幅，仅记录到历史中（下载保护、快速扫描、定期扫描均相同）。
                • 也可以通过 MCP 工具 `get_notification_history` 让 AI 查看。
                """,
                recommendation: "如果在外出或工作时错过了通知，请在通知历史中查看内容。"
            ),
            LocalizedEntry(
                id: "feat_secret_leak_auditor",
                title: "剪贴板保护（防止误粘贴 API 密钥 & 删除 ClickFix 命令）",
                summary: "仅在本机监视剪贴板，检测到复制了 API 密钥或私钥时发出误粘贴警告。如果复制了诈骗网站企图让您执行的恶意命令（ClickFix），会自动从剪贴板中删除。免费版默认开启。",
                details: """
                • 监视：约每 1 秒检查一次剪贴板的变化。内容不会发送到外部，也不会保存原始数据。
                • 检测的密钥：OpenAI、Anthropic、GitHub、AWS、HuggingFace、Google AI / Gemini、Slack、Stripe 的 API 密钥和令牌，以及 RSA / SSH 私钥。此外还包括加密钱包助记词（BIP39）和比特币私钥（WIF/BIP32），两者均经过校验和验证以降低误报。
                • 机密密钥的情况：仅发出「剪贴板中检测到机密密钥」通知（由于可以通过吊销并重新签发密钥进行事后处理，因此不会删除）。
                • ClickFix 命令的情况：发出「剪贴板中检测到可疑命令」通知，并立即清空剪贴板。不仅是终端，在粘贴到 Script Editor、Spotlight 等任何位置之前都能拦截。可补充基于 Shell 历史记录的 feat_clickfix_guard。
                """,
                recommendation: "复制 API 密钥后，请注意粘贴到 AI 聊天或网页表单的目标位置。如果误分享了密钥，请立即吊销并重新签发。"
            ),
            LocalizedEntry(
                id: "feat_secret_leak_audit_tool",
                title: "机密信息与 API 密钥泄露手动审计（粘贴文本诊断 & 文件夹批量扫描）",
                summary: "按需使用的审计工具，支持粘贴文本即时诊断和递归扫描整个文件夹。会显示行号、已打码的字符串以及各类密钥的吊销步骤。免费版即可使用。",
                details: """
                • 打开方式：菜单「恶意软件防护」→「🔑 手动审计机密信息/API 密钥泄露…」，或 MCP 工具 `audit_secrets`（指定 `text` 或 `path`）。
                • 检测方式：基于正则表达式和香农熵的评分。检测到的值会打码显示。
                • 文件夹扫描：自动排除 `.git`、`node_modules`、`target`、`vendor`、`dist`、`build`、`__pycache__`、`venv`。超过 2MB 的文件和二进制文件会被跳过。
                • 权限说明：选择桌面、下载等受保护文件夹时，会在 macOS 权限对话框出现之前（仅首次）显示说明，解释需要访问的原因以及 Zero Telemetry 设计。
                • 处理在独立线程中进行，不会阻塞界面。不会向外部发送任何内容。
                """,
                recommendation: "可在公开代码仓库之前，或将代码粘贴到 AI 聊天之前，用于批量检查。"
            ),
            LocalizedEntry(
                id: "feat_package_cve_scan",
                title: "软件包 CVE 照合（Homebrew + npm / PyPI / crates.io 等 7 个生态系统・Zero Telemetry）",
                summary: "将已安装的 Homebrew 软件包，以及指定项目文件夹中的依赖锁定文件，与本机保存的已知 CVE 映射进行比对。扫描本身完全不进行网络通信。免费版即可使用。",
                details: """
                • 打开方式：菜单「恶意软件防护」→「📦 软件包CVE照合（Homebrew）…」。依赖关系请在「依赖关系」标签页中添加项目文件夹。
                • Homebrew：将 `brew list --versions` 的结果与根据 NVD 实际数据生成的 formula→CPE 对应表进行比对。检测结果会附带可信度（confirmed = 经验证的对应表 / gray = 未经验证的关键词匹配，可能存在误报）。
                • 依赖关系：解析 package-lock.json / requirements.txt / Pipfile.lock / poetry.lock / Cargo.lock / Gemfile.lock / composer.lock / go.sum / pom.xml，并与 npm、PyPI、crates.io、RubyGems、Packagist、Go、Maven 的已知 CVE 映射（源自 OSV.dev，CVSS 7.0 以上）进行比对。
                • 数据分发：CVE 映射每天一次从签名清单中以仅接收方式获取。尚未获取时会显示「未获取」，且不会检测出任何内容。
                • MCP 工具：`run_package_cve_scan`（Homebrew）和 `run_package_cve_scan_languages`（依赖关系，`watchedFolders` 参数）。
                """,
                recommendation: "请定期运行 Homebrew 扫描，并将开发中的项目登记到依赖关系标签页，尽早更新含有严重 CVE 的软件包。"
            ),
            LocalizedEntry(
                id: "feat_lockfile_tamper_guard",
                title: "依赖锁定文件篡改监控 (Lockfile FIM, Pro)",
                summary: "通过 SHA-256 基线持续监控 package-lock.json / yarn.lock / pnpm-lock.yaml / npm-shrinkwrap.json，检测经由 CI 或供应链的外部篡改。仅限 Pro。",
                details: """
                • 打开方式：在菜单栏「🔔/✅ 定期监控依赖锁定文件是否被篡改 (Pro)」项中切换。
                • 监控对象：与软件包 CVE 比对「依赖关系」标签页中登记的相同项目文件夹内的 package-lock.json / yarn.lock / pnpm-lock.yaml / npm-shrinkwrap.json。不新增独立的监控文件夹列表。
                • 检测方式：通过 CryptoKit 进行 SHA-256 基线差分比对，结合 FSEvents 近实时检测与每小时一次的兜底扫描。
                • 通知紧急程度：若检测时 npm/yarn/pnpm 本身正在运行，会记录到通知历史中并以静默方式通知；未运行时的篡改则为常规紧急通知。无论哪种情况，检测本身都必定执行。
                • 若 Pro 许可证失效将自动停用。
                """,
                recommendation: "建议将重要项目登记到软件包 CVE 比对的「依赖关系」标签页中，并保持此功能开启（启用 Pro 后默认开启）。"
            ),
            LocalizedEntry(
                id: "feat_package_lifecycle_script_scan",
                title: "安装脚本清单 (npm package.json 生命周期脚本, Pro)",
                summary: "列出 node_modules 下 package.json 声明的 preinstall/install/postinstall/prepare 脚本。目的是让 npm install 时无条件执行的代码可见，并非威胁判定。仅限 Pro。",
                details: """
                • 打开方式：菜单「恶意软件防护」→「📦 软件包 CVE 比对 (Homebrew)…」→「安装脚本 (npm) (Pro)」标签页。扫描对象与「依赖关系」标签页相同。
                • 扫描范围：node_modules 下一层（@scope/ 软件包再多一层）。绝不深入软件包自身嵌套的 node_modules。
                • 仅供参考的危险标记：匹配 curl|sh、wget|sh、eval(、base64 -d、node -e 的命令会显示 ⚠️ 标记——这只是轻量级启发式判断，并非定论，许多合法脚本（如原生模块构建）也会命中。
                • 完全不进行任何网络连接，也绝不执行脚本——纯粹的静态清单展示。
                • MCP 工具：`run_package_lifecycle_script_scan`（`watchedFolders` 参数，仅限 Pro）。
                """,
                recommendation: "对标有 ⚠️ 的脚本，请逐一确认该软件包是否确实需要执行此操作。对不熟悉软件包的 postinstall 脚本请格外留意。"
            ),
            LocalizedEntry(
                id: "feat_npm_audit_signatures",
                title: "npm 签名/来源验证 (npm audit signatures，选择性启用，Pro)",
                summary: "与 npm 注册表通信，验证已安装软件包的签名/来源。这是 RoamSwitch 中唯一与 npmjs.com 通信的功能——默认关闭，需要明确选择性启用并在每次运行时确认。仅限 Pro。",
                details: """
                • 启用方式：「📦 软件包 CVE 比对」→「npm 签名验证（选择性启用）(Pro)」标签页中的"启用 npm 签名验证"开关。这仅会解锁每个项目文件夹的「运行审计」按钮，本身不会发送任何内容。每次运行都会以"要与 npm 注册表通信吗？"进行确认。
                • 执行内容：以目标文件夹为工作目录运行 `npm audit signatures`，与 npm 注册表 (registry.npmjs.org) 通信。这是 RoamSwitch 中唯一与 npmjs.com 通信的功能。
                • 输出：原样显示 npm 命令的输出（绝不自行解读或定论）。若退出码非零，或输出中包含 "invalid"/"missing registry signature" 等字样，会显示轻量级的注意提示。
                • 若找不到 npm 命令，会显示提示安装 Node.js/npm 的信息。
                • MCP 工具：`run_npm_audit_signatures`（`directory` 参数，Pro 与选择性启用开关的双重限制）。
                """,
                recommendation: "仅在部署前的依赖审计，或怀疑发生供应链入侵的事件调查时启用即可，无需始终保持开启。"
            ),
            LocalizedEntry(
                id: "feat_npm_sandboxed_install",
                title: "npm/pnpm 安装沙箱执行 (roamswitch-npm, Pro)",
                summary: "这是一个真正进行干预的包装器,而非仅做检测——仅将 preinstall/install/postinstall/prepare 脚本的执行限制在禁止联网的沙箱(sandbox-exec)中,实际代为执行安装。仅限 Pro 版。",
                details: """
                • 启用方法: 在「📦 软件包 CVE 比对」→「沙箱安装 (npm/pnpm) (Pro)」标签页点击「安装」按钮,即可将命令行包装器 `roamswitch-npm` 放置到 ~/Library/Application Support/RoamSwitch/bin/。
                • 两阶段流程: ①下载阶段照常联网执行 `npm install --ignore-scripts` / `pnpm install --ignore-scripts`。②脚本执行阶段在设有 `(deny network-outbound)` 的 sandbox-exec 配置文件下执行 `npm rebuild` / `pnpm rebuild`(若根目录声明了 prepare,还会执行 `run prepare`)。
                • 沙箱方式: Linux 版采用 bwrap 进行文件系统限制,但 macOS 没有同等技术,因此改为采用已在实机验证可行的网络阻断(`(allow default)` + `(deny network-outbound)`)。不限制文件读写与子进程的启动。
                • Shell 别名: 可在 shell 配置文件中追加两行别名,让 `npm`/`pnpm` 经由包装器执行(可选,仅追加,不更改现有内容)。
                • 预览: 执行前可列出项目文件夹的生命周期脚本清单(与「安装脚本清单」功能使用相同的扫描器)。
                • 若 sandbox-exec 不可用或执行失败,绝不会默默回退到不加沙箱的执行。不支持 yarn。没有 GTK/MCP 工具——这是一个从终端使用的命令行工具。
                """,
                recommendation: "对于包含陌生软件包的项目,或从外部来源获取的项目,建议使用 `roamswitch-npm install` 代替常规的 npm/pnpm install。"
            ),
            LocalizedEntry(
                id: "feat_typosquat_guard",
                title: "打字仿冒检测 (npm/pnpm package.json, Pro)",
                summary: "将 package.json 的依赖名称与知名 npm 包名列表进行编辑距离(Levenshtein 1〜2)比对，检测 expres→express、loadash→lodash 这类可能的打字仿冒。应用本身完全不为此进行网络连接。仅限 Pro 版。",
                details: """
                • 范围：仅限项目自身 package.json 的 dependencies/devDependencies/optionalDependencies（peerDependencies 不在范围内）。node_modules（已安装的传递依赖）也刻意不在范围内——打字错误产生于人类将依赖添加到 package.json 的那一刻。
                • 比对逻辑：标准的 Levenshtein 距离动态规划实现，将每个依赖名称与知名 npm 包名列表比对。带作用域的包（`@scope/pkg`）以其基础名称（`pkg`）比较。长度差超过 2 的候选会被低成本预过滤跳过。阈值为：知名名称长度 8 个字符以上时允许距离最多为 2，更短则仅允许距离 1。
                • 列表保持更新的方式：用于比对的热门包名列表由 `PackageCveMapUpdater` 通过与 CVE 映射相同的每日一次、仅接收、Ed25519 签名验证的清单进行分发（构建时内嵌种子加两层覆盖，优先采用 `mapVersion` 较新的一方）。无需等待应用发布即可更新该列表。
                • 这是参考信息，并非定论——已知的许可清单会部分排除一些正规的相似软件包（如 preact），但并不完整。
                • 开启方式：「📦 软件包 CVE 比对」→「打字仿冒检测 (Pro)」标签页，针对与「依赖关系」标签页相同的项目文件夹。MCP：`run_typosquat_scan`（`watchedFolders` 参数，仅限 Pro）。
                """,
                recommendation: "请对任何标记 ⚠️ 的依赖逐一核实是否确实是拼写错误——尤其要留意陌生的软件包名称。"
            ),
            LocalizedEntry(
                id: "feat_port_scan_guard",
                title: "入站端口扫描检测 (自动封锁, Pro)",
                summary: "检测在短时间(5分钟)内连接了多个不同端口(15个以上)的来源IP并发出通知(这是nmap/masscan等侦察工具的典型特征)。检测到的扫描来源默认会被自动封锐10分钟。仅限 Pro。",
                details: """
                • 工作原理：具有特权的Helper通过`tcpdump -i pflog0`监控pf(数据包过滤器)日志，检测在短时间窗口内到达足够多不同目标端口的来源IP。判定仅基于日志记录，绝不会更改或检查通信内容本身。对应Linux版的`port_scan_detect.rs`(nftables `log` + `journalctl`)。
                • 自动封锁：检测到的扫描来源会通过`PFRulesetCoordinator`加入pf规则，默认封锐10分钟。自动封锁可独立于检测功能本身单独开关。
                • 通知：每次检测(及封锁)都会发送macOS通知，并记录到统一的事件时间线中。
                • 开启方式：菜单栏 → 「端口与设备监控」 → 「🔍 入站端口扫描检测 (Pro)」。启用和停用都需要经过确认对话框。默认关闭。
                """,
                recommendation: "没有按IP的许可清单，封锁会在10分钟后自动解除。如果您在家庭或公司环境中定期运行合法的扫描工具(资产清点、漏洞扫描等)，建议在其运行期间关闭自动封锁(仅保留检测/通知)，以避免因误报而反复封锁。"
            ),
            LocalizedEntry(
                id: "feat_sensor_pairing",
                title: "RoamSwitch Sensor 配对 (配对码方式, Pro)",
                summary: "管理与同一局域网上的独立产品 “RoamSwitch Sensor”(专用主动审计集线器)之间的相互信任配对。采用由 Sensor 签发配对码的主动配对方式，假定 Sensor 以固定 IP 运行，因此不再使用 mDNS 自动发现。仅限 Pro。",
                details: """
                • 工作原理：生成并持久保存此设备自身的 Ed25519 密钥对。配对时，此设备携带 Sensor 操作者签发的一次性配对码(签发后 10 分钟失效)以及此设备自身的地址/主机名，连接到 Sensor 的 TCP 监听器(端口 50543)。若配对码有效，Sensor 会将此设备的公钥加入其信任列表。
                • 请求审计：配对完成后，可通过「向 Sensor 请求审计」要求 Sensor 执行一次主动审计(可达性验证)。由于 Sensor 是异步生成结果的，此设备侧常驻的特权辅助进程会每隔 5 分钟自动尝试获取结果，最多 5 次。获取到的结果也会保存在此设备上，可在设置界面的「审计结果」列表中查看。
                • 打开方式：菜单栏 → 「端口与设备监控」 → 「🔍 RoamSwitch Sensor 配对…」。显示此设备自身的公钥/地址(附复制按钮)、已配对的 Sensor 列表(取消配对按钮)、配对码输入表单以及审计结果列表。
                • 使用与 Linux 版(`roamswitch-core::sensor_pairing`)相同的 TCP 控制协议——端口 50543、换行分隔 JSON、Ed25519 签名。
                """,
                recommendation: "请仅使用确实由您自己设置的 RoamSwitch Sensor 操作界面所签发的配对码。如果被要求输入陌生的配对码，请勿配对——建议向网络管理员核实。"
            ),
            LocalizedEntry(
                id: "feat_security_health_checker",
                title: "Mac 安全综合诊断（18 个项目・评分 & 改进步骤）",
                summary: "检查系统健壮性、网络防御、身份验证与访问控制、端口暴露、恶意软件防护、物理设备防御 6 个领域共 18 个项目，并显示 100 分制的评分、等级和改进步骤。免费版即可使用。",
                details: """
                • 系统健壮性：1. FileVault，2. SIP（系统完整性保护），3. Gatekeeper，4. 自动安全更新，5. Apple XProtect。
                • 网络防御：6. macOS 防火墙，7. 隐身模式，8. Wi-Fi 加密强度，9. ARP 欺骗监视，10. 网关 ARP 固定。
                • 身份验证与访问控制：11. SSH 远程登录设置（是否禁止 root 登录、是否强制密钥认证），12. Sudo 权限提升设置（审计 `NOPASSWD`）。
                • 服务与端口暴露：13. 外部公开端口。
                • 恶意软件与下载保护：14. 网页与邮件保护，15. DNS 威胁防护，16. 钓鱼与恶意链接防护（Safari 的欺诈网站警告）。
                • 物理端口与设备防御：17. 非法 USB / BadUSB 物理端口防护，18. macOS 配件连接保护（Apple 芯片）。
                • 不适用项的处理：受信任网络上的防火墙和隐身模式、远程登录禁用时的 SSH、辅助程序未连接时的 Sudo 审计、Intel Mac 的配件保护将标记为 N/A，并从评分计算中排除。
                • 等级：100 分 = S，85～99 分 = A，70～84 分 = B，低于 70 分 = C。也可通过 MCP 工具 `get_security_report` 获取。
                """,
                recommendation: "请定期打开「综合诊断报告」，按照改进步骤处理带 ⚠️ 的项目，保持 A 级以上。"
            ),
            LocalizedEntry(
                id: "feat_autonomous_sentinel",
                title: "后台自主巡查 & ClamAV 病毒库自动更新与定期扫描",
                summary: "每 4 小时在后台更新一次综合诊断、端口、USB 和 XProtect 的状态（所有方案）。Pro 版还会发出评分下降警告、自动更新 ClamAV 病毒库，并每天执行一次定期病毒扫描。",
                details: """
                • 定期诊断（所有方案）：启动约 30 秒后执行，此后每 4 小时执行一次。即使长时间停留在同一网络，也能保持最新的诊断结果。
                • 评分下降警告（Pro）：当评分低于 80 分，或有 4 个以上项目不合格时发出通知。
                • ClamAV 病毒库自动更新（Pro）：静默运行 `freshclam`。
                • 定期扫描（Pro）：每天一次使用 ClamAV 扫描 `~/Downloads`、`~/Desktop`、`~/Library/LaunchAgents`。威胁会被自动隔离并发送严重警报。若无问题，仅发出低调的完成通知。若只检测到 EICAR 测试签名，则不发通知，仅记录到通知历史中。
                """,
                recommendation: "使用 Pro 版时，建议预先安装 ClamAV，病毒库更新和定期扫描将自动进行。"
            ),
            LocalizedEntry(
                id: "feat_simulation_self_test",
                title: "模拟（功能验证）功能",
                summary: "无需发起真实攻击或破坏文件，即可安全测试勒索软件防御、恶意软件检测联动 Air-Gap 以及 Docker 风险检测是否正常工作。",
                details: """
                • 打开方式：菜单「恶意软件防护 (XProtect & ClamAV)」的底部。
                • 🚨 勒索软件防御模拟测试（验证运行）…：按照检测到加密迹象时的相同流程，测试 Air-Gap 隔离和紧急弹窗是否正常工作。不会造成文件损坏等后果。
                • 🚨 恶意软件检测联动 Air-Gap 模拟（功能测试）…：按照 XProtect 实际检测到恶意软件时的相同流程，测试隔离和紧急弹窗。事件中会明确标注「[模拟]」。
                • ⚠️ Docker 风险检测模拟（验证运行）…：测试是否会收到与检测到特权容器时相同的通知。不会访问 Docker。
                • 注意：Air-Gap 类测试会实际暂时阻断网络。请从紧急弹窗中解除（即使不解除，最多 10 分钟后也会自动恢复）。
                • 确认下载保护时，也可以使用无害的 EICAR 测试文件（不会发出通知，而是记录到通知历史中）。
                """,
                recommendation: "建议在刚激活 Pro 或更改设置后运行一次模拟，确认通知和 Air-Gap 的运行情况，这样更为安心。"
            ),
            LocalizedEntry(
                id: "feat_privileged_helper",
                title: "特权辅助程序（RoamSwitchHelper・XPC）",
                summary: "PF 防火墙、共享服务、DNS、气隙隔离等需要 root 权限的操作，仅由经过权限分离的 LaunchDaemon 辅助程序通过 XPC 执行。",
                details: """
                • 权限分离：主应用以普通用户权限运行，仅将 pf 规则变更、共享守护进程控制、DNS 设置、ARP 固定、重要文件哈希计算等操作委托给 `RoamSwitchHelper`。
                • 注册：通过 macOS 标准的 SMAppService，作为应用内置的 LaunchDaemon 进行注册。首次使用需在「系统设置」→「通用」→「登录项与扩展」中批准。如果应用不在「应用程序」文件夹中，则无法注册（faq_install_location）。
                • 附属守护进程：还会注册负责气隙隔离故障保护（10 分钟自动解除）和启动闸门（最多 90 秒）的辅助 LaunchDaemon。
                • 安全验证：XPC 连接时验证代码签名（Team ID），拒绝来自非法进程的调用。
                • 更新后的重新批准：应用会自动尝试切换到新版辅助程序，但 macOS 有时仍会将其置于待批准状态。此时菜单栏图标会变为警告样式，显示「⚠️ 更新后需要重新批准」，并会同时发送通知提醒。
                """,
                recommendation: "请按照首次启动时的引导批准辅助程序。未批准时，菜单中会显示「⚠️ 批准助手…」。更新后如出现此提示或通知，同样可通过「系统设置」>「通用」>「登录项与扩展」重新批准。"
            ),
            LocalizedEntry(
                id: "feat_mcp_server",
                title: "MCP 服务器集成（AI 助手的只读访问）",
                summary: "RoamSwitch.app 内置了只读的 MCP（Model Context Protocol）服务器，Claude 等 AI 助手可以查询 Mac 的安全状况。其中完全没有更改设置或执行阻断等操作类工具。",
                details: """
                • 通信：仅使用本地标准输入输出（stdio）。二进制文件为 `/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`。
                • 主要工具：`get_security_report`（综合诊断）、`get_exposed_ports`、`get_guard_status`、`audit_url_safety`、`audit_secrets`、`audit_security_logs`、`get_quarantine_status`、`get_notification_history`、`get_canary_status`、`get_port_anomaly_incidents`、`get_runtime_threat_status`、`get_incident_timeline`（遏制事件历史）、`get_network_history`（网络历史学习）、`run_package_cve_scan`、`run_package_cve_scan_languages`、`run_active_vuln_scan`（唯一会向 127.0.0.1 发送非破坏性探测的工具）、`get_app_help`（本知识库）。
                • 资源：`roamswitch://docs/features`、`roamswitch://docs/alerts-and-messages`、`roamswitch://docs/settings-guide`、`roamswitch://docs/troubleshooting`。
                • 语言：回答遵循应用的语言设置。`get_app_help` 可通过 `language` 参数（ja / en / zh-Hans / zh-Hant / ko / de / fr / es / it / pt-PT）指定语言。
                • 安全设计：由于是只读的，即使 AI 因提示注入而被滥用，也无法更改保护级别或隔离端口等。
                """,
                recommendation: "配置步骤请参见 faq_mcp_setup。可以用自然语言提问，例如「这台 Mac 现在安全吗？」「这个通知是什么意思？」。"
            ),
            LocalizedEntry(
                id: "feat_license_pro_tier",
                title: "Pro 永久许可证（一次性买断・最多 2 台）",
                summary: "Pro 版为一次性买断的永久许可证（¥2,980 / $19.99），一个许可证最多可在 2 台 Mac 上使用。许可证令牌经 Ed25519 电子签名并在本机验证，因此激活后可离线运行。",
                details: """
                • Pro 可用功能：菜单中标有「(Pro)」的自动防御（勒索软件诱饵文件检测、XProtect 联动阻断、未知端口自动阻止与开发服务器隔离、ARP 欺骗自动阻断、网关 ARP/NDP 固定、VPN 隧道、BadUSB / USB 存储防护、网页与邮件保护、DNS 威胁防护、链接保护、Bluetooth 自动关闭、ClickFix 防护、自动启动注册监控、Docker 风险检测、重要文件篡改监控、自动日志审计）、实时威胁通知、自主巡查的警告与定期扫描、日志 CSV 导出等。
                • 许可证类型：Pro 永久许可证（2 台）、Team 永久许可证（5 台）。
                • 激活：通过菜单中的「💎 激活 / 购买 Pro 版…」输入许可证密钥（ROAM-XXXX-…）。应用使用内置公钥验证服务器签发的签名令牌，并保存到钥匙串中。
                • 解除设备：从激活界面解除后，会删除本 Mac 上的许可证并释放服务器上的使用名额（即使通信失败，本机端的解除也一定会执行）。
                • 失效时：Pro 专属防护会自动停用，VPN 隧道、端口隔离等也会被解除。
                """,
                recommendation: "如果需要自动隔离、实时防御和自主巡查警告，请考虑 Pro 版。更换 Mac 时，请先在旧 Mac 上解除许可证，再在新 Mac 上激活。"
            ),
        ]
    }

    // MARK: - Alerts: network, devices, links

    private static func alertsZhHansNetwork() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "alert_arp_spoofing",
                title: "⚠️ ARP 欺骗 (中间人攻击) 警报",
                summary: "在同一网络中检测到有设备冒充路由器（网关）企图窃听或篡改通信的迹象时发出的警告。",
                details: """
                • 触发原因：攻击者发送伪造的 ARP 应答，将您的通信引导经由其自身（中间人攻击）。通过检测网关 IP 地址不变而 MAC 地址突然改变来识别。路由器重启或 Mesh Wi-Fi 切换时也可能触发。
                • 自动防御：在最大锁定状态下且「检测到 ARP 欺骗（网络冒充）时自动阻止 (Pro)」已启用时，立即执行气隙隔离。在其他级别下仅发出通知，并在菜单中显示「检测到 ARP 欺骗 — 立即全部断网」。
                """,
                recommendation: """
                1. 请立即停止在此网络上输入密码、进行支付或处理工作通信。
                2. 如果是公共 Wi-Fi 等不熟悉的环境，请选择菜单中的「立即全部断网」，或断开 Wi-Fi。
                3. 如需使用互联网，请切换到网络共享（热点）或 VPN 隧道等安全线路。
                4. 仅在确认是误报（如刚重启家中路由器）的情况下，才可继续使用。
                """
            ),
            LocalizedEntry(
                id: "alert_evil_twin_ssid",
                title: "⚠️ 检测到疑似仿冒 (Evil Twin) 的 Wi-Fi 网络",
                summary: "当前连接的 Wi-Fi 名称（SSID）与以往连接过的网络名称极为相似时发出的警告。可能是恶意的伪造接入点（Evil Twin）。",
                details: """
                • 触发原因：攻击者设置仅将正规网络名称改动 1～2 个字符的伪造接入点来诱骗用户。网络历史学习（feat_network_history_guard）会根据与已学习名称的编辑距离以及网关设备的差异进行判定。
                • 抑制误报：对于较短的名称，或由同一网关设备广播的其他名称 SSID，不会发出警告。
                • 自动防御：仅通知。该网络将作为未注册网络应用外出默认保护的级别。
                """,
                recommendation: """
                1. 请勿在此 Wi-Fi 上登录或输入个人信息。
                2. 请通过店铺或办公室的公告等确认正规的网络名称，如不一致请断开连接。
                3. 如需继续使用，请连接 VPN 隧道。
                """
            ),
            LocalizedEntry(
                id: "alert_unencrypted_wifi",
                title: "⚠️ 已连接到未加密的公开 Wi-Fi",
                summary: "连接到没有密码或加密（WPA2 / WPA3）的开放 Wi-Fi，或使用旧式 WEP 方式的网络时发出的警告。",
                details: """
                • 触发原因：无线链路未加密，周围任何人都可以截获通信。
                • 自动防御：如果是未注册网络，外出默认保护（初始值：最大锁定）会阻止入站连接和共享服务。
                """,
                recommendation: """
                1. 如有可能，请连接 VPN 隧道，或切换到网络共享（热点）等可信线路。
                2. 请避免在非 HTTPS 网站上登录或输入个人信息。
                3. 请在菜单中确认保护级别为最大锁定。
                """
            ),
            LocalizedEntry(
                id: "alert_port_anomaly",
                title: "🚨 已自动阻止未知的监听端口",
                summary: "检测到此前未对外公开的程序在 0.0.0.0 上向外部局域网公开端口，并已自动阻止外部访问时发出的通知（阻止失败时会显示「阻止失败」）。",
                details: """
                • 触发原因：启动开发服务器（Next.js、Vite、Python、Docker），首次启动 LocalSend、Syncthing 等局域网接收类应用，或后门、非法应用开始监听。
                • 自动防御：通过 pf 仅阻止来自外部的访问（Mac 本机和 localhost 仍可使用）。macOS 标准系统守护进程不在范围内。
                """,
                recommendation: """
                1. 请确认是否认识通知中显示的进程名称、PID 和端口号（也可以在菜单「外部公开端口」中查看）。
                2. 如果是自己启动的服务器或局域网接收类应用，请通过通知中的「允许」按钮或端口诊断界面允许。之后将永久允许。
                3. 将开发服务器绑定到 `127.0.0.1` 重新启动更为安全。
                4. 如果没有印象，请保持阻止状态并结束该进程，然后运行综合诊断和病毒扫描。
                """
            ),
            LocalizedEntry(
                id: "alert_exposed_database",
                title: "🚨 未经身份验证的数据库服务正在对外公开",
                summary: "检测到 Redis、MongoDB、Memcached、Elasticsearch 等默认常无认证的服务，在未受防火墙保护的状态下向外部局域网公开时发出的警告。",
                details: """
                • 触发原因：数据库或后端服务在 0.0.0.0 上启动，且当前保护级别允许入站连接。同一网络中的任何人都可能读写数据。
                • 自动防御：发出通知（Pro）。同一端口不会重复通知。
                """,
                recommendation: """
                1. 请在服务配置中将监听地址改为 `127.0.0.1`，或启用身份验证。
                2. 如果无法立即处理，请在菜单「外部公开端口」中打开目标端口，并执行「执行外部隔离」。
                3. 在公共网络上请将保护级别设为最大锁定。
                """
            ),
            LocalizedEntry(
                id: "alert_unapproved_keyboard",
                title: "⚠️ 检测到未授权键盘 / BadUSB 连接",
                summary: "当连接了不在允许列表中的新 USB 键盘（或改装 USB 线缆等伪装成键盘的设备），并在批准前拦截其按键输入时显示的通知和批准窗口。",
                details: """
                • 触发原因：连接了新的外接键盘或扩展坞，或连接了 Rubber Ducky 等按键注入设备。
                • 自动防御：仅拦截该设备的按键输入（其他键盘仍可使用）。通过「⚠️ 检测到未知 USB 设备 / 键盘」窗口请求批准。
                """,
                recommendation: """
                1. 如果是自己连接的可信键盘，请点击「信任并允许」。该键盘将加入允许列表，输入随即生效。
                2. 如果没有印象，或在未连接任何设备时出现此提示，请点击「拒绝并保持拦截」，并拔下设备。
                """
            ),
            LocalizedEntry(
                id: "alert_scripted_keyboard",
                title: "🚨 该键盘显示出自动化(脚本)输入的迹象",
                summary: "检测到等待批准的键盘以人类不可能达到的快速且均匀的间隔发送按键输入时发出的警告。很可能是自动脚本进行的命令注入（BadUSB 攻击）。",
                details: """
                • 触发原因：Rubber Ducky、Flipper Zero、Arduino / Digispark 等设备试图高速输入预置的命令。通过按键时序分析（5 次以上输入且平均不超过 12ms，或平均不超过 45ms 且均匀）进行判定。
                • 自动防御：该设备的按键输入在批准前就已被拦截，并未到达 Mac。此警告是为判断提供额外依据。
                """,
                recommendation: """
                1. 请务必在批准窗口中选择「拒绝并保持拦截」。
                2. 请立即拔下设备并确认其来源（如捡到的 U 盘、别人送的线缆等）。
                3. 为保险起见，请运行综合诊断并检查自动启动注册。
                """
            ),
            LocalizedEntry(
                id: "alert_untrusted_usb",
                title: "🔒 已将 USB 存储设备以只读方式挂载 / 🔌 自动阻止非法 USB 存储设备",
                summary: "当连接了不在允许列表中的 U 盘或外部存储设备，出于安全考虑以只读方式挂载并请求批准，或已将其弹出时发出的通知。",
                details: """
                • 触发原因：连接了未注册的存储设备。用于防止非法外传数据或带入恶意文件。
                • 自动防御：以只读方式重新挂载，并显示「是否允许 USB 存储设备“…”？」对话框。选择「退出」后会弹出设备并发出「自动阻止非法 USB 存储设备」通知。
                """,
                recommendation: """
                1. 如果是您自己的设备，请选择「允许读写」或「以只读方式允许」。该设备将加入允许列表，下次起自动应用。
                2. 如果没有印象，请选择「退出」。
                3. 之后可以在菜单「USB / BadUSB 防护设置…」中更改允许列表。
                """
            ),
            LocalizedEntry(
                id: "alert_malware_usb",
                title: "🚨 在 USB 存储设备上检测到恶意软件",
                summary: "在以读写方式连接 USB 存储设备之前的 ClamAV 扫描中发现感染文件时发出的警告。",
                details: """
                • 触发原因：U 盘中存在感染文件。
                • 自动防御：立即弹出该卷，防止感染 Mac 本机。
                """,
                recommendation: """
                1. 请在其他安全环境中格式化该 U 盘，或清除恶意软件后再使用。
                2. 请运行 ClamAV 的快速扫描或指定文件夹扫描，确认 Mac 本机未被感染。
                """
            ),
            LocalizedEntry(
                id: "alert_link_guard_blocked",
                title: "🛑 链接保护：已阻止连接",
                summary: "链接保护自动阻止了对疑似诈骗或钓鱼网站（收录于威胁情报源，或属于品牌同形异义字仿冒）的连接时发出的通知。",
                details: """
                • 触发原因：邮件或社交媒体中的链接、广告、应用内通信等试图连接已知的诈骗域名。
                • 自动防御：系统扩展丢弃该通信，或通过 hosts 回退将域名解析为 0.0.0.0。与使用何种浏览器或应用无关。
                """,
                recommendation: """
                1. 如果没有印象，则无需任何操作。请勿在该页面上输入信息。
                2. 如果工作中使用的正规网站被误拦截，请通过通知中的「本次允许（5 分钟）」临时允许，或将其加入允许列表。
                """
            ),
            LocalizedEntry(
                id: "alert_link_guard_warn_hold",
                title: "⚠️ 链接保护：连接已暂停",
                summary: "在警告模式下，暂停对疑似品牌仿冒或诈骗网站的连接，并询问是否允许时显示的通知和最前端面板。",
                details: """
                • 触发原因：连接到属于警告对象的域名（子域名仿冒、高风险 TLD 等）。
                • 自动防御：暂停通信并等待回答。若约 8 秒内未回答，则阻断连接（故障关闭）。阻断结果不会缓存，因此下次访问时会再次确认。已回答的结果会被记住。
                """,
                recommendation: """
                1. 如果是您自己打算打开的可信网站，请选择「允许」。
                2. 如果没有印象或无法判断，请选择「阻止」，或直接等待（将自动阻断）。
                3. 如果被误阻断，重新加载页面后会再次显示确认。
                """
            ),
            LocalizedEntry(
                id: "alert_dangerous_url",
                title: "🛑 疑似危险链接或钓鱼诈骗（链接安全性诊断）",
                summary: "链接安全性诊断（或 `audit_url_safety`）判定 URL 含有同形异义字仿冒、伪装子域名、高风险 TLD 等危险因素时的显示内容。",
                details: """
                • 判定项目：同形异义字（Punycode）、冒充大型企业的子域名、钓鱼中常用的 TLD、明文 HTTP、直接使用 IP 地址等。
                • 评分：低于 50 分为「危险」，50～79 分为「注意」。
                """,
                recommendation: """
                1. 请勿打开该链接。
                2. 请删除该消息，必要时向公司的安全负责人报告。
                """
            ),
            LocalizedEntry(
                id: "alert_helper_disconnected",
                title: "⚠️ 辅助程序未连接",
                summary: "无法与特权辅助程序（RoamSwitchHelper）建立 XPC 通信时发出的警告。",
                details: """
                • 触发原因：未在「登录项与扩展」中批准后台运行，macOS 更新后辅助程序停止运行，或应用位于「应用程序」文件夹之外（下载文件夹或磁盘映像内）。
                • 影响：无法执行切换保护级别、气隙隔离、DNS 设置、重要文件监控等需要 root 权限的操作。
                """,
                recommendation: """
                1. 选择菜单中的「⚠️ 批准助手…」，将打开批准步骤界面。
                2. 请在「系统设置」→「通用」→「登录项与扩展」的「允许在后台运行」中打开 RoamSwitchHelper。
                3. 请确认 RoamSwitch 位于「应用程序」文件夹中。
                4. 如果仍未改善，请尝试 faq_helper_troubleshooting 中的步骤。
                """
            ),
            LocalizedEntry(
                id: "alert_score_drop",
                title: "⚠️ Mac 安全性下降警告",
                summary: "在自主巡查的定期诊断中，安全评分低于 80 分，或有 4 个以上项目不合格时发出的通知（Pro）。",
                details: """
                • 触发原因：FileVault 或防火墙被禁用、公开了危险端口、防护功能停止等设置或环境的变化。
                • 判定标准：评分低于 80 分，或不合格项目达到 4 个以上。
                """,
                recommendation: """
                1. 请通过菜单中的「📊 打开综合诊断报告…」（或 MCP 的 `get_security_report`）查看内容。
                2. 请按照显示的改进步骤，依次处理带有 ⚠️ 的项目。
                """
            ),
        ]
    }

    // MARK: - Alerts: malware, containment, audit

    private static func alertsZhHansMalware() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "alert_quarantined_download",
                title: "🚨 已隔离危险的下载文件",
                summary: "在从浏览器、邮件、聊天应用保存的文件中检测到威胁，并已将其隔离到隔离区时发出的警告（移动失败时会显示「隔离失败」）。",
                details: """
                • 触发原因：下载的文件中含有恶意软件、木马、反向 Shell 等。
                • 自动防御：移动到 `~/Library/Application Support/RoamSwitch/Quarantine/`，使其处于无法执行的状态。如果由静态特征检测到而 ClamAV 未匹配，通知中会注明可能是误报。
                """,
                recommendation: """
                1. 如果隔离成功，该文件已处于无法执行的状态。
                2. 请打开「📦 管理隔离文件…」，如果没有印象，请选择「彻底删除」。
                3. 仅在确定是误报时，才使用「还原」或「排除并还原」。
                4. 如果显示「隔离失败」，请手动删除通知中显示路径下的文件。
                """
            ),
            LocalizedEntry(
                id: "alert_eicar_test_signature",
                title: "🧪 检测到 EICAR 测试签名（无害）— 仅记录到通知历史",
                summary: "检测到用于验证防病毒软件运行的无害 EICAR 测试文件时的处理方式。由于并非真正的威胁，不会显示通知横幅，也不会隔离或阻止，仅记录到通知历史中。",
                details: """
                • 适用范围：无论是由网页与邮件保护、ClamAV 的快速扫描 / 指定文件夹扫描，还是自主巡查的定期扫描检测到，处理方式都相同。
                • 行为：文件保持原样。会在「🔔 通知历史…」中记录为「检测到 EICAR 测试签名（无害）」。
                • 原因：如果对非威胁内容显示警告横幅，真正重要的警告就会被淹没。
                """,
                recommendation: """
                1. 无需任何处理。如果是出于测试目的放置的文件，确认后请将其删除。
                2. 可以通过通知历史中是否有记录来确认扫描是否正常工作。
                """
            ),
            LocalizedEntry(
                id: "alert_pickle_model",
                title: "⚠️ 检测到 Pickle 格式 AI 模型下载",
                summary: "下载了 `.pkl` / `.pickle` / `.pt` 格式的 AI 模型文件时发出的警告。Pickle 格式仅加载就能执行任意代码，需要特别注意。",
                details: """
                • 触发原因：从 HuggingFace、Civitai 等保存了模型文件。
                • 自动防御：仅警告（不隔离文件）。
                """,
                recommendation: """
                1. 除了来自可信官方发布渠道的模型外，请勿加载。
                2. 如有可能，请使用同一模型的 `.safetensors` 或 `.gguf` 格式版本。
                """
            ),
            LocalizedEntry(
                id: "alert_ransomware_activity",
                title: "🚨【紧急自动防护触发】已拦截勒索软件活动",
                summary: "检测到诱饵（金丝雀）文件被篡改、删除或重命名，并触发了气隙隔离、共享服务停止和可疑进程暂停时显示的紧急通知和弹窗。",
                details: """
                • 触发原因：勒索软件等试图加密或破坏用户文件夹中文件的进程活动（或执行了模拟测试）。
                • 自动防御：阻断所有收发＋关闭 Wi-Fi 无线，停止 SMB / SSH / 屏幕共享，暂停可疑进程（SIGSTOP）。紧急弹窗中会显示阻断是否成功、可疑进程以及可能受影响的文件。
                """,
                recommendation: """
                1. 请保存正在编辑的文件，并退出所有可疑应用。
                2. 请在活动监视器中查看 CPU 或磁盘写入急剧增加的进程，如果没有印象请强制退出。
                3. 请检查可能受影响的文件，以及 Time Machine 等备份。
                4. 确认安全后，请在紧急弹窗中解除隔离（将恢复网络、恢复已暂停的进程并重新生成诱饵文件）。
                """
            ),
            LocalizedEntry(
                id: "alert_runtime_threat_airgap",
                title: "🚨 XProtect 检测到恶意软件 — 已自动断网",
                summary: "Apple 内置的 XProtect / XProtect Remediator 检测到恶意软件（判定为恶意），并由 XProtect 联动的自动阻断触发气隙隔离时显示的紧急弹窗和通知。",
                details: """
                • 触发原因：下载或执行的文件被 Apple 的恶意软件检测引擎判定为恶意。
                • 自动防御：阻断所有收发＋关闭 Wi-Fi 无线。即使不解除，最多 10 分钟后也会自动恢复。会记录检测到的进程、类别以及 Apple 的检测消息。
                """,
                recommendation: """
                1. 请检查刚刚下载或执行的文件和应用，并将其删除。
                2. 请运行 ClamAV 扫描和综合诊断，并确认自动启动注册（LaunchAgent）中没有可疑项目。
                3. 确认安全后，请在紧急弹窗中解除隔离。
                4. 也可以通过 MCP 的 `get_runtime_threat_status` 查看状态。
                """
            ),
            LocalizedEntry(
                id: "alert_gatekeeper_block",
                title: "🛡️ Gatekeeper 已阻止未签名应用运行",
                summary: "告知 macOS 的 Gatekeeper 阻止了未经签名或公证的应用启动的通知。不会自动阻断网络。",
                details: """
                • 触发原因：试图打开从互联网获取的未签名应用，或自己构建的开发中应用。
                • 自动防御：无（仅通知）。XProtect 联动的自动阻断仅在 XProtect 实际检测到恶意软件时才会触发。
                """,
                recommendation: """
                1. 如果是自己构建的应用等有印象的情况，则无需处理。
                2. 如果没有印象，请通过「检查文件/应用安全性…」确认签名发行者，若可疑请将其删除。
                """
            ),
            LocalizedEntry(
                id: "alert_clickfix_command",
                title: "🚨 检测到可疑命令执行 / ⚠️ 剪贴板中检测到可疑命令",
                summary: "检测到在终端中执行了（通过 Shell 历史记录检测）或复制到剪贴板中的命令符合 ClickFix 手法时发出的警告。",
                details: """
                • 触发原因：被伪造的 CAPTCHA 或「要修复问题，请运行此命令」之类的伪造错误页面诱导。检测对象为反向 Shell 的典型命令，以及将 Base64 解码后直接传给 Shell / osascript 的模式。
                • 自动防御（终端执行时・Pro・默认关闭）：气隙隔离（不关闭 Wi-Fi 无线，最多 10 分钟后自动恢复）。
                • 自动防御（复制时・默认开启）：立即删除剪贴板中的内容。
                """,
                recommendation: """
                1. 如果只是复制了命令，请关闭该网页。请勿粘贴或执行。
                2. 如果已经执行，请确认钥匙串（Keychain）、浏览器中保存的密码和加密货币钱包是否安全，并从另一台安全的设备上更改重要密码。
                3. 请确认自动启动注册（LaunchAgent / Daemon）中没有可疑项目，并运行 ClamAV 扫描。
                """
            ),
            LocalizedEntry(
                id: "alert_new_persistence_item",
                title: "🚨 检测到新的自动启动注册",
                summary: "注册了新的 LaunchAgent / LaunchDaemon，且其内容被判定为可疑（直接启动脚本解释器、签名无效等）时发出的警告。",
                details: """
                • 触发原因：信息窃取类恶意软件等为了在重启后继续运行而进行的注册，或应用安装程序进行的注册。
                • 自动防御：仅通知（无法阻止注册本身）。通知中会显示注册文件（plist）的路径和判定理由。
                """,
                recommendation: """
                1. 请确认刚才是否自己安装了应用。如果有印象，则无需处理。
                2. 如果没有印象，请删除通知中显示的 plist 文件，以及该 plist 所启动的脚本或应用。
                3. 删除后请重启 Mac，并运行 ClamAV 扫描。
                """
            ),
            LocalizedEntry(
                id: "alert_docker_risk",
                title: "⚠️ 检测到有风险的 Docker 容器配置",
                summary: "告知新启动了以 `--privileged` 启动的容器，或挂载了 `docker.sock` 的容器的通知。",
                details: """
                • 触发原因：特权模式容器或挂载 Docker 套接字的容器能够从容器内操作主机，存在容器逃逸风险。
                • 自动防御：无（仅通知）。
                """,
                recommendation: """
                1. 如果是有意为之的配置（如监控代理等），则无需处理。
                2. 如果没有印象，请通过 `docker ps` 和 `docker inspect` 检查相应容器，并将其停止。
                """
            ),
            LocalizedEntry(
                id: "alert_critical_file_tampering",
                title: "🚨 检测到重要系统文件被篡改",
                summary: "检测到 sudoers、SSH 配置、PAM、hosts、root 的 authorized_keys 等重要文件被修改、删除或新增时发出的警告。",
                details: """
                • 触发原因：管理员修改配置（`sudo visudo`、编辑 SSH 配置等）、软件进行的修改，或攻击者进行权限提升、设置后门。
                • 自动防御：仅通知。不会自动将修改后的状态视为正规状态。
                • 相关警告：「重要文件篡改检测未正常运行」表示无法连接特权辅助程序，扫描持续失败。
                """,
                recommendation: """
                1. 请确认通知中显示的文件是否由您本人或管理员修改。
                2. 如果没有印象，请检查 `/etc/sudoers` 中的 `NOPASSWD` 设置以及 `authorized_keys` 中的未知密钥等，并将其删除。
                3. 请更改管理员密码，并运行综合诊断。
                """
            ),
            LocalizedEntry(
                id: "alert_log_audit_anomaly",
                title: "🔔 日志审计：检测到异常模式",
                summary: "自动日志审计检测到本 Mac 上首次出现的日志模式（[新增]），或比平时大幅增加的日志（[激增 z=…]）时发出的通知。",
                details: """
                • 触发原因：大多是连接新设备或应用、系统更新带来的预期内变化，但也可能是可疑的登录尝试或未知进程的活动。
                • 通知内容：数量明细、实际日志行示例（最多 3 条）、学习状态（例如：频率学习中，已观测 2/3 次）、通俗说明。
                • 自动防御：无（仅通知）。
                """,
                recommendation: """
                1. 如果只有新模式，且不包含陌生的应用名称或 IP 地址，则无需处理。
                2. 如果频率激增与您未进行的操作时间重合，请通过「📜 Mac 安全日志审计…」查看详情。
                3. 如果难以判断，可以使用「复制供 AI 咨询的材料」向 AI 助手咨询。
                """
            ),
            LocalizedEntry(
                id: "alert_secret_in_clipboard",
                title: "🔑 剪贴板中检测到机密密钥",
                summary: "告知 OpenAI、Anthropic、GitHub、AWS 等的 API 密钥或私钥已被复制到剪贴板的通知。",
                details: """
                • 触发原因：复制了 API 密钥、令牌或私钥。
                • 自动防御：仅通知（不会清空剪贴板）。
                """,
                recommendation: """
                1. 请注意不要误粘贴到网站或 AI 聊天中。
                2. 使用完毕后，请复制其他文本进行覆盖。
                3. 如果不慎分享，请立即在各服务的管理界面中吊销并重新签发密钥。
                """
            ),
            LocalizedEntry(
                id: "alert_airgap_failed",
                title: "🚨 自动断网失败",
                summary: "因勒索软件、ARP 欺骗、XProtect 检测、ClickFix 等尝试紧急断网，但未能通过 pf 应用全面阻断时发出的紧急警告。",
                details: """
                • 触发原因：特权辅助程序无响应（未批准、已停止、超时）等。重试 3 次仍失败时显示。
                • 当前状态：可能仅通过应用程序防火墙阻止了入站连接，但对外发送并未停止。
                """,
                recommendation: """
                1. 请立即关闭 Wi-Fi，或拔掉网线。
                2. 请处理威胁（结束进程、进行扫描）。
                3. 之后请检查辅助程序的状态（faq_helper_troubleshooting）。
                """
            ),
        ]
    }

    // MARK: - Settings

    private static func settingsZhHans() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "set_trusted_networks",
                title: "管理已注册网络 & 单独设置保护级别",
                summary: "将当前连接的网络注册为「家」「工作」「网络共享」等，并为每个网络设置保护级别（信任 / 标准保护 / 最大锁定）。",
                details: """
                • 注册：菜单「注册当前网络」→「注册为“家”（信任）」「注册为“工作” (标准保护)」「注册为“网络共享” (标准保护)」「使用自定义名称注册…」。通过网关的 MAC 地址进行识别。
                • 更改级别：从菜单「当前网络：…」或「已注册网络 (n)」中选择目标网络，然后选择 🟢 / 🟡 / 🔴 级别。
                • 重命名与删除：「重命名…」「解除注册」「删除注册」。
                """,
                recommendation: "建议家中设为「🟢 信任」，工作场所和网络共享设为「🟡 标准保护」。共用的办公室 Wi-Fi 不注册、保持最大锁定使用更为安全。"
            ),
            LocalizedEntry(
                id: "set_away_default_level",
                title: "外出默认保护（未注册网络的保护级别）",
                summary: "选择连接到未注册网络时自动应用的保护级别。初始值为「🔴 最大锁定」。",
                details: """
                • 设置：在菜单「外出默认保护：…」中选择 🟢 信任 / 🟡 标准保护 / 🔴 最大锁定。
                • 影响：还会影响 DNS 威胁防护（仅外出时应用）、VPN 隧道自动连接、网关 ARP/NDP 固定、Bluetooth 自动关闭等以「不受信任的网络」为条件的功能。
                """,
                recommendation: "如果在外出时不使用共享服务或 AirDrop，强烈建议保持最大锁定。"
            ),
            LocalizedEntry(
                id: "set_manual_override",
                title: "手动覆盖 & 防止忘记恢复",
                summary: "需要临时手动更改保护级别时，可以选择期限进行指定。期限结束或网络发生变化后会恢复自动判定，从而防止忘记恢复。",
                details: """
                • 设置：菜单「手动覆盖」→ 级别（🟢 / 🟡 / 🔴）→ 选择期限。
                • 期限：「直到网络断开 (推荐)」「仅1小时」「仅4小时」「直到手动解除」。
                • 解除：「手动覆盖」→「恢复自动判定」，或菜单顶部的「🔄 解除手动指定 (恢复自动)」。
                • 解除气隙隔离时，手动覆盖也会被清除。
                """,
                recommendation: "因演示或开发工作需要临时放宽保护时，请使用「直到网络断开」或「仅1小时」，避免在外出时处于无防护状态。"
            ),
            LocalizedEntry(
                id: "set_pro_default_guards",
                title: "激活 Pro 时自动开启的防护与需手动启用的防护",
                summary: "首次激活 Pro 许可证时，主要的自主防御防护会自动开启。此后会尊重用户对各项防护选择的开启 / 关闭状态。",
                details: """
                • 自动开启（仅在首次激活 Pro 时执行一次）：自动阻止未知监听端口、勒索软件诱饵文件检测、检测到 ARP 欺骗时自动阻止、XProtect 检测到恶意软件时自动断网、自动日志审计、定期监控重要系统文件是否被篡改。ARP 与 XProtect 的自动阻断开启时，会显示一次相关提示。
                • Pro 默认开启：网页与邮件保护、监控自动启动注册(LaunchAgent/Daemon)。
                • 默认关闭（需手动启用）：ClickFix 防护的自动阻断、Docker 风险检测、BadUSB 物理端口防护、USB 存储设备自动阻止、网关 ARP/NDP 固定、VPN 隧道、Bluetooth 自动关闭、实证型漏洞验证；DNS 威胁防护的服务商选择为可选项。
                • 免费版也默认开启：剪贴板保护（API 密钥、ClickFix 命令）。
                • 后续新增的防护也会对现有 Pro 用户按每项防护各应用一次默认值。许可证失效后，Pro 专属防护将被停用。
                """,
                recommendation: "激活 Pro 后，请确认菜单中的 ✅ 标记。与您的使用方式不符的防护（例如不使用 Docker）保持原样即可，并额外启用所需的防护（例如经常使用公共 Wi-Fi 则启用 VPN）。"
            ),
            LocalizedEntry(
                id: "set_usb_whitelist",
                title: "USB / BadUSB 防护设置（键盘允许列表 & 存储设备权限） (Pro)",
                summary: "通过允许列表管理可信键盘和工作中使用的 USB 存储设备，并为存储设备设置「只读」或「读写均可」权限。",
                details: """
                • 打开方式：菜单「端口与设备监控」→「USB / BadUSB 防护设置…」。
                • 键盘：在批准窗口中选择「信任并允许」即可注册。可在设置界面中删除。
                • 存储设备：在连接时的对话框中选择「允许读写」或「以只读方式允许」即可注册。可在设置界面中更改权限或删除。如果在设备未连接时进行了更改，拔出后重新插入即可生效。
                • 即使是已允许的设备，在以读写方式连接之前也会执行连接时的 ClamAV 扫描。
                """,
                recommendation: "在处理机密数据的 Mac 上，将注册的存储设备设为「只读」可大幅降低信息泄露的风险。"
            ),
            LocalizedEntry(
                id: "set_watched_folders",
                title: "网页与邮件保护的监控文件夹 (Pro)",
                summary: "可以添加、删除或重置下载保护（FSEvents 监视与自动扫描）的目标文件夹。",
                details: """
                • 默认监控文件夹：`~/Downloads`、`~/Desktop`、`~/Documents`、邮件的下载文件夹。
                • 编辑：菜单「网页与邮件保护（下载文件自动扫描）(Pro)」→「📁 监控目标文件夹」→「⚙️ 管理监控文件夹…」。
                • 重置：「🔄 恢复默认」。
                • 最近的扫描历史（最多显示 5 条）和「清除扫描历史」也在同一菜单中。
                """,
                recommendation: "如果将浏览器或聊天应用的保存位置更改为自定义文件夹，请务必将其添加到监控对象中。"
            ),
            LocalizedEntry(
                id: "set_dns_policy",
                title: "DNS 威胁防护的服务商与应用策略 (Pro)",
                summary: "设置用于拦截恶意域名的安全 DNS 服务商，以及应用的时机（仅外出时 / 始终）。",
                details: """
                • 设置：菜单「DNS 威胁防护（拦截恶意网站与 C2）(Pro)」→「DNS提供商：…」「⚙️ 应用策略」。
                • 服务商：Quad9（自动拦截恶意软件与 C2）/ Cloudflare Security (1.1.1.2) / AdGuard DNS（拦截威胁与广告）/ CleanBrowsing（安全过滤）。
                • 应用策略：「仅在不可信Wi-Fi应用（推荐）」或「在所有网络中始终应用（包含信任网络）」。选择仅外出时，在受信任的网络上会恢复原来的 DNS 设置。
                • 应用状态可以从菜单中的显示打开「网络设置」进行确认。
                """,
                recommendation: "一般使用建议选择 Quad9 与「仅在不可信Wi-Fi应用」的组合。在需要公司内部 DNS 的环境中，请避免始终应用。"
            ),
            LocalizedEntry(
                id: "set_link_guard_modes",
                title: "链接保护的模式、自动更新、系统扩展与允许列表 (Pro)",
                summary: "设置链接保护的运行模式、威胁情报源的自动更新、系统扩展的批准状态，以及误拦截时的允许操作。",
                details: """
                • 模式：在菜单「链接保护（钓鱼连接检测）(Pro)」中选择「关闭」「仅警告（不拦截）」「自动拦截明显的钓鱼网站（推荐）」。警告模式仅在系统扩展生效时才能工作。
                • 自动更新：点击「自动更新：开（仅接收）」可切换为关闭。即使关闭，也会依靠随附数据和同形异义字检测运行。情报源的版本和条目数会显示在菜单中。
                • 强制点显示：「强制点：系统扩展（支持 DoH）」「强制点：hosts 回退」「正在启用系统扩展…」「系统扩展错误」。等待批准时会显示「批准系统扩展（打开“系统设置”）…」。
                • 允许与阻止：通过拦截通知中的「本次允许（5 分钟）」仅允许 5 分钟。警告面板中的「允许」「阻止」选择会被记住。
                """,
                recommendation: "批准系统扩展，并以「自动拦截」＋「自动更新：开」的组合使用效果最佳。"
            ),
            LocalizedEntry(
                id: "set_vpn_backend",
                title: "VPN 隧道的后端设置（WireGuard / Tailscale） (Pro)",
                summary: "选择 VPN 隧道的后端，并设置 WireGuard 配置文件导入、Tailscale 出口节点选择以及终止开关。",
                details: """
                • 打开方式：菜单「端口与设备监控」→「VPN 隧道 (不受信任网络的中间人攻击防护) (Pro)」→「后端」。
                • WireGuard：「导入 WireGuard 配置 (.conf)…」→「在不受信任网络自动连接」。另有「立即连接」「断开」「删除配置」。状态以「🟢 已连接（最后握手 n 秒前）」等形式显示，终止开关始终有效。未安装 `wireguard-tools` 时会显示安装引导。
                • Tailscale：在「出口节点」中选择出口节点（选择「（无 — 保护关闭）」则停用）。另有「刷新候选」「刷新状态」。「终止开关：开（防泄漏）」为可选项，默认关闭。
                • 状态显示示例：「⚪️ 待命（在不受信任的网络上自动连接）」「🟡 所选出口节点已离线」。
                """,
                recommendation: "如果已在使用 Tailscale，选择 Tailscale 最为简便；否则使用 VPN 服务商提供的 WireGuard 配置即可。"
            ),
            LocalizedEntry(
                id: "set_language",
                title: "显示语言设置（应用与 MCP 的回答语言）",
                summary: "RoamSwitch 的显示语言可从 10 种语言（日本語・English・简体中文・繁體中文・한국어・Deutsch・Français・Español・Italiano・Português）中选择。MCP 服务器的回答和本知识库也会以相同语言返回。",
                details: """
                • 设置：从菜单「语言 / Language」中选择。选择「跟随系统设置」时将使用 macOS 的首选语言。
                • MCP：MCP 服务器会读取应用中选择的语言。在跟随系统设置且系统语言不受支持时，将以英语回答。
                • `get_app_help` 工具可以通过 `language` 参数单独指定回答语言。可以使用任何语言的关键词进行搜索。
                """,
                recommendation: "如果希望与 AI 助手使用其他语言交流，请使用 `get_app_help` 的 `language` 参数。"
            ),
        ]
    }

    // MARK: - Troubleshooting: setup

    private static func troubleshootingZhHansSetup() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "faq_free_vs_pro",
                title: "免费版与 Pro 永久版的区别",
                summary: "免费版也可以无限期使用根据网络自动切换保护、18 个项目的综合诊断等基础防御功能以及各类手动诊断工具。Pro 版将解锁自动隔离、实时防御、自主巡查警告等功能。",
                details: """
                【免费版】
                • 根据 Wi-Fi 和网络自动切换三级 pf 数据包过滤，自动停止与恢复共享服务和 AirDrop
                • Mac 安全综合诊断（18 个项目）、XProtect 运行状态确认与文件/应用安全性诊断
                • 外部公开端口和 USB 设备列表显示
                • 链接安全性诊断、机密信息与 API 密钥泄露手动审计、剪贴板保护
                • 软件包 CVE 照合、实证型漏洞验证、Mac 安全日志审计、通知历史
                • ClamAV 手动扫描与隔离文件管理
                • MCP 服务器集成
                【Pro 永久版（一次性买断 ¥2,980 / $19.99・最多 2 台）】
                • 勒索软件诱饵文件检测＆气隙隔离、XProtect 联动自动阻断、ClickFix 防护
                • 自动阻止未知监听端口、开发服务器外部隔离
                • ARP 欺骗自动阻断、网关 ARP/NDP 固定、VPN 隧道（WireGuard / Tailscale）、Evil Twin 警告
                • BadUSB 键盘防护、USB 存储设备自动阻止
                • 网页与邮件保护（自动扫描、隔离、Pickle 警告）、DNS 威胁防护、链接保护
                • 自动启动注册监控、Docker 风险检测、重要文件篡改监控、自动日志审计
                • Bluetooth 自动关闭、实时威胁通知、自主巡查的警告、病毒库更新与定期扫描、日志 CSV 导出
                """,
                recommendation: "如果需要自动隔离、实时防御或后台监控，请选择 Pro 版。"
            ),
            LocalizedEntry(
                id: "faq_homebrew_clamav",
                title: "ClamAV（病毒检测）的安装与 Homebrew",
                summary: "病毒扫描功能使用开源的「ClamAV」。可通过 Homebrew 安装；即使未安装，XProtect 联动和 RoamSwitch 本体的所有功能也都能正常运行。",
                details: """
                • Homebrew：macOS 的软件包管理工具（https://brew.sh/）。
                • 安装步骤：
                  1. 在终端中运行 Homebrew 的官方安装命令（见 https://brew.sh/）。
                  2. 运行 `brew install clamav`。也可以从菜单中的「📥 通过 Homebrew 安装 ClamAV…」打开安装引导。
                  3. 执行菜单「🛡️ ClamAV (免费防病毒)」→「🔄 立即更新病毒特征库」。
                • 安装后可用的功能：快速扫描（下载 / 桌面）、指定文件夹扫描、网页与邮件保护和 USB 存储设备扫描、自主巡查的定期扫描。
                • 即使没有 ClamAV：数据包过滤、端口监视、链接诊断、静态特征检测等仍可正常运行。
                """,
                recommendation: "如果希望自动扫描下载文件和 USB 存储设备，建议安装 Homebrew 和 ClamAV。"
            ),
            LocalizedEntry(
                id: "faq_blueutil_setup",
                title: "Bluetooth 自动关闭 (Pro) 与 blueutil 的安装",
                summary: "在外出时自动关闭 Bluetooth 的功能需要安装开源工具 `blueutil`。",
                details: """
                • 背景：macOS 没有供应用切换 Bluetooth 电源的公开 API，因此使用 CLI 工具 `blueutil`。
                • 安装步骤：
                  1. 在终端中运行 `brew install blueutil`（也可以通过菜单中的「📥 通过 Homebrew 安装 blueutil…」完成）。
                  2. 启用菜单「端口与设备监控」→「在不受信任的网络自动关闭 Bluetooth (Pro)」。
                • 未安装时：不会影响其他功能。菜单中会显示「🔵 Bluetooth 自动关闭（未安装）」。
                """,
                recommendation: "如果希望避免在公共 Wi-Fi 环境中被无线信号追踪或受 Bluetooth 漏洞影响，请运行 `brew install blueutil` 并启用此功能。"
            ),
            LocalizedEntry(
                id: "faq_helper_troubleshooting",
                title: "显示「⚠️ 辅助程序未连接」时的处理方法",
                summary: "无法与特权辅助程序（RoamSwitchHelper）通信时的恢复步骤。",
                details: """
                1. 选择菜单中的「⚠️ 批准助手…」，按照显示的步骤进行批准。
                2. 打开「系统设置」→「通用」→「登录项与扩展」，在「允许在后台运行」列表中确认 RoamSwitchHelper 已打开。
                3. 请确认 RoamSwitch 位于「应用程序」文件夹中（faq_install_location）。
                4. 请点击引导界面中的「重试注册助手」。
                5. 如果仍未改善，请在终端中运行 `sudo killall RoamSwitchHelper` 重启辅助程序（launchd 会自动重新启动它），然后重启 RoamSwitch。
                """,
                recommendation: "如果 macOS 更新后辅助程序停止响应，请先检查登录项中的开关，然后尝试 `sudo killall RoamSwitchHelper`。"
            ),
            LocalizedEntry(
                id: "faq_install_location",
                title: "应用的放置位置（在「应用程序」文件夹以外启动时）",
                summary: "macOS 不允许为「应用程序」文件夹以外的应用注册特权辅助程序，因此必须将 RoamSwitch 放在 `/Applications` 或 `~/Applications` 中启动。",
                details: """
                • 无法注册的位置：下载文件夹或桌面、磁盘映像（.dmg）仍处于挂载状态、被 Gatekeeper 的「App Translocation」移至临时只读区域的状态。
                • 自动引导：启动时的引导流程会检查放置位置，并提示「移动到「应用程序」并重新启动」或「在访达中打开「应用程序」」。
                • 移动后：请点击「重新检查」，或重启应用后再批准辅助程序。
                """,
                recommendation: "请从磁盘映像将 RoamSwitch 拖到「应用程序」文件夹中，并从那里启动。"
            ),
            LocalizedEntry(
                id: "faq_system_extension_approval",
                title: "如何批准链接保护的系统扩展",
                summary: "要让链接保护以最佳方式运行（支持 DoH、警告模式），需要批准内容过滤系统扩展。批准前将以 /etc/hosts 回退方式运行。",
                details: """
                • 批准步骤：菜单「链接保护（钓鱼连接检测）(Pro)」→「批准系统扩展（打开“系统设置”）…」→「系统设置」→「通用」→「登录项与扩展」中允许 RoamSwitch 的网络扩展。
                • 批准后：菜单中的显示会变为「强制点：系统扩展（支持 DoH）」。
                • 显示「系统扩展错误」时：请确认应用位于「应用程序」文件夹中，然后重新选择一次链接保护的模式即可重试。
                • 此方式无需 Apple 审核或申请权限（entitlement）（使用 Developer ID 签名并已公证）。
                """,
                recommendation: "为了在浏览器使用 DNS over HTTPS 时也能可靠地提供保护，建议批准系统扩展。"
            ),
            LocalizedEntry(
                id: "faq_mcp_setup",
                title: "MCP 服务器的配置方法（Claude Desktop / Claude Code 等）",
                summary: "将 RoamSwitch 内置的 MCP 服务器注册到支持 MCP 的 AI 客户端的方法。",
                details: """
                • 二进制路径：`/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`
                • Claude Desktop：在 `~/Library/Application Support/Claude/claude_desktop_config.json` 的 `mcpServers` 中，将二进制路径添加为 `command`。
                • Claude Code：`claude mcp add roamswitch /Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`
                • 其他客户端（如 Codex CLI 等）的步骤：https://lafine.net/mcp-setup.html
                • 回答语言：遵循应用的「语言 / Language」设置。`get_app_help` 可通过 `language` 参数单独指定。
                • 通信仅通过本地 stdio 进行，不会向外部发送（只有 `run_active_vuln_scan` 会向 127.0.0.1 发送非破坏性探测）。
                """,
                recommendation: "注册后，只需让 AI「用 RoamSwitch 检查一下这台 Mac 当前的安全状态」，它就会为您讲解综合诊断的结果。"
            ),
        ]
    }

    // MARK: - Troubleshooting: operation

    private static func troubleshootingZhHansOperation() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "faq_network_cut_off",
                title: "突然无法连接互联网（气隙隔离・保护级别）",
                summary: "可能是 RoamSwitch 的紧急气隙隔离或最大锁定导致通信中断。以下是确认原因的方法和解除步骤。",
                details: """
                • 确认：请查看是否显示了紧急弹窗，以及通知历史中是否有「紧急自动防护触发」「XProtect」「ARP 欺骗」「检测到可疑命令执行」等通知。Wi-Fi 无线也可能已被关闭。
                • 解除：请通过紧急弹窗中的解除按钮或通知进行解除。通信和 Wi-Fi 无线将会恢复。
                • 自动恢复：即使不解除，辅助程序的故障保护也会在最多 10 分钟后自动恢复。应用退出、崩溃或 Mac 重启时也无需手动操作。
                • 刚启动时：Mac 刚启动后，最多 90 秒内可能会因启动闸门而限制通信。
                • 隔离以外的原因：最大锁定会阻止入站连接，但不会妨碍正常的出站通信（如浏览网页）。另请检查 VPN 的终止开关（隧道断开期间）、DNS 威胁防护的 DNS 以及链接保护的拦截。
                """,
                recommendation: "隔离触发后，请查看引发隔离的通知，确认安全后再解除。如果频繁误触发，可以从菜单中单独关闭相应的防护。"
            ),
            LocalizedEntry(
                id: "faq_quarantine_false_positive",
                title: "下载文件因误报被隔离时的还原步骤",
                summary: "自制脚本或开发用二进制文件因误报被隔离时，进行还原和扫描排除的步骤。",
                details: """
                1. 打开菜单「恶意软件防护」→ ClamAV →「📦 管理隔离文件…」。
                2. 从隔离中的文件里选择目标（会显示原路径、威胁名称和隔离时间）。
                3. 如果确定是误报，请点击「排除并还原」。文件将回到原位置，该路径今后将不再被扫描。如果只想还原一次，请点击「还原」。
                4. 如需撤销排除，请在同一界面的「已从扫描中排除的路径」中点击「取消排除」。
                5. 如果想按文件夹取消监控，请在网页与邮件保护的「⚙️ 管理监控文件夹…」中进行调整。
                """,
                recommendation: "对于无法判断是否真正安全的文件，请不要还原，而是选择「彻底删除」。"
            ),
            LocalizedEntry(
                id: "faq_eicar_test",
                title: "放置了 EICAR 测试文件却没有收到通知",
                summary: "这是设计如此。EICAR 测试签名是无害的测试用途，因此不会显示通知横幅，也不会隔离。检测记录会保留在通知历史中。",
                details: """
                • 确认方法：请在菜单「Mac 安全综合诊断」→「🔔 通知历史…」中确认是否记录了「🧪 检测到 EICAR 测试签名（无害）」。
                • 文件的处理：文件会原样保留在原位置。
                • 如果想确认实际的警告路径：请使用菜单底部的「勒索软件防御模拟」「恶意软件检测联动 Air-Gap 模拟」「Docker 风险检测模拟」。
                """,
                recommendation: "测试结束后，请删除 EICAR 文件。"
            ),
            LocalizedEntry(
                id: "faq_dev_server_blocked",
                title: "自己的开发服务器或局域网接收类应用无法从外部连接",
                summary: "可能是自动阻止未知监听端口功能阻止了新开始对外公开的程序。从 Mac 本机仍可正常访问。",
                details: """
                • 确认：请查看通知历史中是否记录了「🚨 已自动阻止未知的监听端口」。
                • 允许：通过通知中的「允许」按钮，或菜单「外部公开端口」→ 目标端口 → 端口诊断界面进行允许。允许以可执行文件为单位永久有效。
                • 与手动隔离的区别：通过「执行外部隔离」自行隔离的端口，请在端口诊断界面中点击「解除隔离」恢复。
                • 保护级别：在最大锁定的网络上，防火墙会阻止入站连接本身。如果希望允许局域网内访问，请注册该网络并将其设为标准保护或信任。
                """,
                recommendation: "LocalSend、Syncthing 等常用的局域网接收类应用只需允许一次，之后就不会再被阻止。"
            ),
            LocalizedEntry(
                id: "faq_link_guard_false_block",
                title: "链接保护阻止了正规网站 / 连接被暂停",
                summary: "链接保护误拦截了网站，或在警告模式下暂停了连接时的处理方法。",
                details: """
                • 临时允许：拦截通知中的「本次允许（5 分钟）」。
                • 永久允许：在警告面板中选择「允许」后会被记住。
                • 暂停的连接被自动阻断：警告模式下若约 8 秒内未回答就会阻断（故障关闭）。阻断结果不会缓存，因此重新加载页面后会再次显示确认。
                • 看不到通知：当 macOS 的通知样式为横幅时，按钮可能被隐藏，因此还会显示最前端的面板。在专注模式等情况下，请查看通知历史。
                • 临时停用：将模式更改为「仅警告（不拦截）」或「关闭」。
                """,
                recommendation: "如果工作工具反复被拦截，请先确认域名没有错误或拼写错误，再进行允许。"
            ),
            LocalizedEntry(
                id: "faq_keyboard_blocked",
                title: "外接键盘无法输入（BadUSB 防护）",
                summary: "BadUSB 物理端口防护正在将不在允许列表中的键盘输入视为待批准而进行拦截。",
                details: """
                • 批准：请在显示的「⚠️ 检测到未知 USB 设备 / 键盘」窗口中点击「信任并允许」（可使用内置键盘或触控板操作）。
                • 找不到窗口：拔出设备后重新插入即可再次显示。
                • 扩展坞或 KVM：内置键盘功能的设备也在检测范围内。如果是您自己的设备，请予以允许。
                • 辅助功能权限：设备独占失败时的替代拦截方式会使用辅助功能权限。
                • 撤销允许：可以在「USB / BadUSB 防护设置…」中删除。
                """,
                recommendation: "出现「自动化(脚本)输入的迹象」警告的设备，请勿允许，并将其拔下。"
            ),
            LocalizedEntry(
                id: "faq_vpn_troubleshooting",
                title: "VPN 隧道无法连接 / 无法通信",
                summary: "WireGuard 或 Tailscale 后端的 VPN 隧道无法正常工作时的检查事项。",
                details: """
                • WireGuard：请确认是否已安装 `brew install wireguard-tools`，以及是否已导入 `.conf`。如果显示「🟡 无响应（最后握手 n 秒前）」，请检查 VPN 服务器端或配置文件中的密钥和端点。由于终止开关处于启用状态，在隧道建立之前将无法通信。
                • Tailscale：请确认是否已安装 CLI 版并完成登录（会显示「请先登录 Tailscale」），以及是否已选择出口节点。如果显示「🟡 所选出口节点已离线」，请选择其他节点。
                • App Store 版 Tailscale：无法从应用外部设置出口节点，请在 Tailscale 应用中选择出口节点。
                • Tailscale 的终止开关：在某些环境下会妨碍 Tailscale 自身的连接，如果无法连接请将其关闭。
                • 在受信任的网络上自动断开属于正常行为。
                """,
                recommendation: "请先查看菜单中的状态显示：WireGuard 请查看握手情况，Tailscale 请查看出口节点的状态。"
            ),
            LocalizedEntry(
                id: "faq_log_audit_repeated_alerts",
                title: "日志审计的通知反复出现",
                summary: "自动日志审计会一边学习本 Mac 平常的日志趋势一边运行。刚开始使用或大型更新之后通知会增多，但随着学习的推进会自然减少。",
                details: """
                • 新模式：已通知过一次的模式会成为「已知」，同样的内容不会再次通知。
                • 频率激增：每种模式在观测 3 次后完成学习，之后如果数量处于平常水平就不会通知。通知中显示「频率学习中：已观测 2/3 次」等字样时，表示仍在学习中。
                • 常见原因：macOS 或应用更新、连接新设备、暂时性高负载。
                • 如果想停止：请关闭菜单「自动日志审计(定期学习新模式与频率异常) (Pro)」（手动日志审计仍可继续使用）。
                """,
                recommendation: "只要不包含陌生的应用名称、IP 地址或 sudo 失败，可以先观察一段时间。"
            ),
            LocalizedEntry(
                id: "faq_zero_telemetry",
                title: "Zero Telemetry（零外部发送）的隐私设计",
                summary: "RoamSwitch 和 MCP 服务器不会将诊断结果、URL、端口信息、日志或文件内容发送到外部服务器。仅在以下明确列出的例外情况下进行通信。",
                details: """
                • 完全本地：综合诊断、端口监视、链接诊断、机密信息审计、日志审计、病毒检测和 MCP 通信全部在本机内完成。
                • 通信例外：
                  - 许可证的激活与解除（仅在用户操作时），以及打开购买页面的操作
                  - 应用更新检查（Sparkle）
                  - ClamAV 病毒库更新（`freshclam`）
                  - 每天一次获取链接保护的威胁情报源、软件包 CVE 映射和漏洞 CVE 映射（仅接收、签名验证、不发送标识符；链接保护的自动更新可以关闭）
                  - 与用户配置的 VPN、安全 DNS 服务商之间的正常通信
                  - 实证型漏洞验证向 127.0.0.1（本 Mac）发送的非破坏性探测
                • 代码中不存在遥测或使用情况收集。辅助程序未批准提醒等功能也仅通过本机内的计数实现。
                """,
                recommendation: "即使在高度机密的工作环境或个人开发环境中，也可以放心使用，无需担心信息泄露。"
            ),
        ]
    }
}
