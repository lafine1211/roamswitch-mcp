// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.31 (build 88).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

// English content for `RoamSwitchKnowledgeBase` (also the fallback language).
// Every entry id here must also exist in every other
// `RoamSwitchKnowledgeBaseContent_<lang>.swift` file.
extension RoamSwitchKnowledgeBase {
    static func labelsEn() -> MarkdownLabels {
        return MarkdownLabels(
            featuresTitle: "RoamSwitch Full Feature Specification & Architecture",
            featuresIntro: "How every RoamSwitch security feature works, its defaults, and its limitations.",
            alertsTitle: "RoamSwitch Alert & Notification Advice Catalog",
            alertsIntro: "Every notification banner, warning, and emergency window RoamSwitch shows, with its cause, the automatic defense taken, and recommended step-by-step actions.",
            settingsTitle: "RoamSwitch Settings & Operations Guide",
            settingsIntro: "Step-by-step guidance for every setting, toggle, allowlist, and policy in RoamSwitch.",
            troubleshootingTitle: "RoamSwitch Troubleshooting & FAQ",
            troubleshootingIntro: "Authoritative answers on common questions, permissions and approvals, Homebrew / ClamAV / blueutil setup, false positives, and the privacy design.",
            summary: "Summary",
            overview: "Overview",
            detailsHeading: "Details & Causes",
            adviceHeading: "What to Do",
            recommendation: "Recommendation",
            bestPractice: "Best Practice",
            advice: "Advice"
        )
    }

    static func contentEn() -> [LocalizedEntry] {
        var list: [LocalizedEntry] = []
        list.append(contentsOf: featuresEnNetwork())
        list.append(contentsOf: featuresEnMalware())
        list.append(contentsOf: featuresEnAudit())
        list.append(contentsOf: alertsEnNetwork())
        list.append(contentsOf: alertsEnMalware())
        list.append(contentsOf: settingsEn())
        list.append(contentsOf: troubleshootingEnSetup())
        list.append(contentsOf: troubleshootingEnOperation())
        return list
    }

    // MARK: - Features: network & devices

    private static func featuresEnNetwork() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_network_autoswitch",
                title: "Automatic Network Security Switching & PF Packet Filter (3 Levels)",
                summary: "Matches the current network's gateway MAC address against your registered networks and applies that network's protection level automatically. Unregistered networks get the Default Away Protection level (initially Maximum Lockdown). Available in the free edition.",
                details: """
                • 🟢 Trusted (Open - Unblocked): e.g. home. Firewall off; sharing services (SSH / SMB / Screen Sharing) and AirDrop allowed.
                • 🟡 Balanced (Firewall & Stealth): e.g. work or tethering. PF packet filter and stealth mode block outside probing while sharing services stay available.
                • 🔴 Maximum Lockdown (Sharing & AirDrop Off): cafés, public Wi-Fi, unregistered networks. All inbound blocked, sharing daemons stopped, AirDrop disabled.
                • How it decides: on a network change it reads the gateway's MAC address and matches it against registered networks. Path events that don't change the gateway (DHCP renewal, Wi-Fi roaming) don't trigger a full re-evaluation.
                • Internals: the privileged helper `RoamSwitchHelper` (over XPC) manages a dedicated `pfctl` anchor, so packets are dropped at the kernel level.
                • Manual override: from Manual Override you can pick, per level, Until Disconnected (Recommended), For 1 Hour, For 4 Hours, or Until Manually Cleared (see set_manual_override).
                """,
                recommendation: "Register home and other safe offices via Register Current Network, and let Maximum Lockdown apply automatically everywhere else."
            ),
            LocalizedEntry(
                id: "feat_network_history_guard",
                title: "Network History Learning & Evil Twin (Look-alike Wi-Fi) Detection (Pro)",
                summary: "Learns, on this Mac only, which gateway MAC addresses each Wi-Fi SSID has used, and warns about a possible Evil Twin (fake access point) when you join an unknown SSID whose name is suspiciously close to a network you've used before.",
                details: """
                • What is learned: for each SSID, the gateway MAC addresses seen (up to 8 per SSID, for mesh Wi-Fi), stored in `~/Library/Application Support/RoamSwitch/network_history.json`. Up to 200 SSIDs, oldest evicted first. Nothing is sent off the device.
                • Look-alike test: case-insensitive edit (Levenshtein) distance. Names shorter than 6 characters are exempt, and the allowed distance grows slowly with length (1 to 2 characters), so generic default SSIDs like "ASUS" or "TP-Link_5G" colliding by chance never trigger it.
                • False-positive control: the same gateway hardware broadcasting a second SSID (guest network, renamed router) is not flagged. A known SSID seen with a new gateway MAC (router replaced) is recorded but never alerts on its own.
                • While ARP spoofing is detected, the observation is skipped so an attacker's MAC is never learned as legitimate.
                • The warning is a real-time alert, sent on Pro. The learned history is available via the MCP tool `get_network_history`.
                """,
                recommendation: "If you get this warning, don't enter credentials on that Wi-Fi and confirm the real network name and location. A VPN tunnel (feat_vpn_tunnel) is the most reliable countermeasure."
            ),
            LocalizedEntry(
                id: "feat_arp_spoof_guard",
                title: "ARP Spoofing (Network Impersonation) Detection & Auto-Block (Pro)",
                summary: "Detects ARP spoofing, where an attacker on the same network impersonates the router to eavesdrop on or tamper with traffic (man-in-the-middle). On Maximum Lockdown networks it cuts the network immediately; on other levels it notifies you and lets you decide.",
                details: """
                • Detection: the default gateway's IP stays the same while its MAC address suddenly changes. Besides network-change events, a dedicated 15-second poll catches attacks that start mid-session.
                • Response: on a Maximum Lockdown network, immediate air-gap containment (feat_airgap_containment). On Trusted or Balanced networks, notification only, and you can trigger containment from Ports & Devices Monitor with "ARP spoofing detected — cut all network now". This avoids false triggers from router reboots or mesh roaming, and stops a single forged ARP packet from being weaponized into a self-inflicted outage.
                • Default: the menu item "Auto-block on ARP spoofing (network impersonation) detection (Pro)" is turned on automatically the first time a Pro license is activated (set_pro_default_guards).
                • Role: this is the after-the-fact response. Prevention comes from Gateway ARP/NDP pinning (feat_gateway_arp_lock) and the VPN tunnel (feat_vpn_tunnel).
                • Incidents are recorded in the incident timeline (feat_containment_incident_timeline) as MITRE ATT&CK T1557.
                """,
                recommendation: "Keep it on. For stronger MITM protection add the VPN tunnel; for prevention without extra infrastructure add Gateway ARP/NDP pinning."
            ),
            LocalizedEntry(
                id: "feat_gateway_arp_lock",
                title: "Gateway ARP/NDP Pinning (Preventive) (Pro)",
                summary: "When you join an untrusted network, pins the MAC addresses of the gateway, the IPv6 router, and any on-link DNS server as static neighbor-cache entries, preventing ARP/NDP spoofing man-in-the-middle attacks before they start. Off by default.",
                details: """
                • Enable: Ports & Devices Monitor → "Pin gateway ARP/NDP on untrusted networks (preventive) (Pro)".
                • How: on connect it reads the current MAC addresses and the helper pins them as permanent entries with `arp -s` / `ndp -s`. The kernel then ignores forged ARP replies and neighbor advertisements for those IPs.
                • Scope: only those three kinds of entries. Nothing is pinned on Trusted (open) networks, so a home router reboot never breaks connectivity. Pins are cleared and re-created on every network change.
                • Limitation (trust on first use): the first MAC observed is trusted, so an attacker already present before you connected could get their MAC pinned. If you can't accept that assumption, use the VPN tunnel.
                • Reflected in the Mac Security Audit item "Gateway ARP Pinning (Preventive MITM Defense)".
                """,
                recommendation: "A good lightweight MITM defense when a VPN isn't practical. It can be combined with the VPN tunnel (the VPN is the primary defense, this is a supplement)."
            ),
            LocalizedEntry(
                id: "feat_vpn_tunnel",
                title: "VPN Tunnel (WireGuard / Tailscale, with Kill Switch) (Pro)",
                summary: "Automatically brings up an encrypted tunnel on untrusted networks so man-in-the-middle attacks see only ciphertext. Choose WireGuard (config file) or Tailscale (exit node) as the backend. It doesn't depend on L2 (ARP/NDP) integrity, making it the primary anti-MITM defense. No Network Extension entitlement required.",
                details: """
                • Backend: Ports & Devices Monitor → "VPN Tunnel (anti-MITM on untrusted networks) (Pro)" → Backend, then WireGuard or Tailscale. Only the selected backend runs.
                • WireGuard: requires Homebrew's `wireguard-tools` (`brew install wireguard-tools`). Import a config with "Import WireGuard config (.conf)…". You supply the config (Mullvad, IVPN, Proton VPN, your own server, your employer); RoamSwitch does not provide VPN servers.
                • WireGuard kill switch: pf `block drop all` with passes only for lo, the tunnel interface, the UDP handshake to the endpoint, DHCP, and ICMP. Nothing leaks in cleartext while the tunnel is down.
                • Tailscale: for people who already use Tailscale. RoamSwitch doesn't install it or log in; it reads `tailscale status` and runs `tailscale set --exit-node=<node>`. An exit node is required (all traffic goes through it). An offline exit node is shown in the status line.
                • Tailscale CLI (standalone) recommended: `brew install tailscale` → `sudo tailscaled install-system-daemon` → `sudo tailscale up`. The App Store (GUI) version can't be driven with `tailscale set` from outside the app, so pick the exit node in the Tailscale app and RoamSwitch handles status display and the kill switch only.
                • Tailscale kill switch (off by default, opt-in): pf passes only lo, Tailscale's utun, CGNAT 100.64.0.0/10, DNS, STUN 3478, 41641, DERP tcp 443, DHCP, and ICMP. Looser than WireGuard's ("hard to leak" rather than leak-proof), and on some networks it can interfere with Tailscale's own connectivity, hence optional.
                • Automatic: tunnel / exit node up on untrusted networks, down on trusted ones. If the license lapses, the tunnel and kill switch are released automatically.
                """,
                recommendation: "The most effective protection if you use public Wi-Fi often. Tailscale users: install the CLI and choose the Tailscale backend plus an exit node. Otherwise `brew install wireguard-tools` with your VPN provider's `.conf` is the easiest path."
            ),
            LocalizedEntry(
                id: "feat_airgap_containment",
                title: "Emergency Air-Gap Containment (Full Network Cut, Wi-Fi Radio Off, Auto-Restore Failsafe)",
                summary: "The shared emergency containment used when a serious threat is detected (ransomware, an XProtect malware finding, ARP spoofing, ClickFix). It blocks all inbound and outbound traffic. Even after a crash or reboot, networking comes back automatically within 10 minutes at most.",
                details: """
                • How: the privileged helper loads pf `block drop all` (loopback excepted) and reads it back to confirm. Outbound is cut too, which stops exfiltration of keys or data to a C2 server. If applying fails it retries up to 3 times (8-second timeout each); if it still fails it says "Automatic network cutoff failed" and asks you to disconnect manually. It never claims isolation that isn't real.
                • Wi-Fi radio off: pf only drops packets while the adapter stays associated, so ARP-spoofing, ransomware, and XProtect containment also turn the Wi-Fi radio itself off via `networksetup` (on by default; internal setting `RoamSwitch.AirGapAutoWiFiKillEnabled`). ClickFix containment does not turn the radio off.
                • Release: releasing from the emergency window or notification removes the pf block and turns Wi-Fi back on.
                • Failsafe: if the app crashes or nobody releases it, a helper-side timer force-releases the air-gap after 10 minutes and restores the Wi-Fi radio. Relaunching the app or rebooting the Mac also recovers without manual steps.
                • Boot gate: right after boot, until the app applies its policy, a default-deny pf boot gate is in effect; it releases itself after 90 seconds at most.
                """,
                recommendation: "When containment fires, read the notification first, quit suspicious apps and run a scan, then release. If you know it's a false positive, release it right away."
            ),
            LocalizedEntry(
                id: "feat_port_anomaly_guard",
                title: "Auto-Block Unknown Listening Ports & Dev Server Isolation (Pro)",
                summary: "Monitors every listening TCP port and, when an executable that wasn't exposed before suddenly starts listening on 0.0.0.0, blocks access to that port from the LAN. Dev servers and local AI servers can also be isolated to 127.0.0.1 with one click.",
                details: """
                • Monitoring: listening ports are scanned every 20 seconds. Identity is the executable path, so a known app merely switching port numbers doesn't trigger it. The state right after enabling is captured as the baseline.
                • Auto-block: when an unknown executable starts exposing a port, pf blocks external access only (the Mac itself and localhost can still use it). This catches a backdoor planted by a zero-day exploit without knowing the malware family.
                • Excluded: Apple-signed system daemons under `/System/Library` or `/usr/libexec` (e.g. rapportd, needed for Handoff, AirPlay, AirDrop). General-purpose tools under `/usr/bin` such as `/usr/bin/python3` or `/usr/bin/nc` are still flagged.
                • Dangerous services: identifies services often exposed without authentication, such as Redis (6379), MongoDB (27017), Memcached (11211), Elasticsearch (9200), VNC (5900), and local AI servers like Ollama (11434), LM Studio (1234), Gradio (7860), and vLLM (8000).
                • Dev server isolation: open the port from Exposed Ports and choose "Isolate Port" to restrict it to 127.0.0.1 (Pro).
                • False positives: allow permanently with the notification's "Allow" button or from the port audit screen. Turning the guard off (or a lapsed license) releases every block it created.
                • Default: turned on automatically the first time Pro is activated. Incident history is available via the MCP tool `get_port_anomaly_incidents`.
                """,
                recommendation: "Bind dev servers and local LLMs to `127.0.0.1` (e.g. `OLLAMA_HOST=127.0.0.1 ollama serve`, `npm run dev -- -H 127.0.0.1`)."
            ),
            LocalizedEntry(
                id: "feat_active_vuln_scan",
                title: "Active Vulnerability Verification — Off by Default",
                summary: "For services detected on this Mac itself (127.0.0.1), checks with minimal read-only probes whether they actually answer without authentication. Off by default; requires explicit opt-in and a confirmation for every run.",
                details: """
                • Enable: Ports & Devices Monitor → "Active Vulnerability Verification". This only unlocks the "Run Active Verification" button in the port audit screen; it sends nothing on its own, and every run asks "Send the verification request?" first.
                • 127.0.0.1 only: nothing is ever sent to another host.
                • Unauthenticated access: single, short-timeout, non-destructive probes to Redis (PING), Memcached (stats), and MongoDB (listDatabases).
                • Generic dev servers: checks for CORS misconfiguration (reflected Origin with credentials), path traversal, and open redirects.
                • Known-CVE version match: for Redis / Memcached reachable without auth, reads the version with a non-destructive query and compares it with known CVE version ranges. No exploit payloads are sent.
                • Also available as the MCP tool `run_active_vuln_scan` (the only tool that sends network traffic, to localhost).
                """,
                recommendation: "Enable it only when you want to confirm whether Redis, Docker, a local LLM, or similar running on your own Mac is really reachable without authentication."
            ),
            LocalizedEntry(
                id: "feat_usb_keyboard_guard",
                title: "Unauthorized USB / BadUSB Physical Port Guard (Keyboard Approval & Keystroke Timing Analysis) (Pro)",
                summary: "When an unknown USB keyboard or a modified cable (Rubber Ducky, O.MG Cable, Flipper Zero, and similar) is connected, that device's keystrokes are blocked until you approve it, preventing automated command injection. It also analyzes keystroke intervals and warns when they look scripted.",
                details: """
                • Detection: IOHIDManager spots new keyboards in real time. The built-in keyboard is trusted automatically.
                • Blocking: the unapproved device is seized exclusively (IOHIDDevice seize), so only that device's keystrokes stop reaching the system; other keyboards keep working. Only if seizing fails does it fall back to a CGEventTap block, which uses the Accessibility permission.
                • Approval: a front-most window offers "Trust & Allow" or "Reject & Keep Blocked". Allowed keyboards go on the allowlist.
                • Keystroke timing analysis: while blocked, the device's keystroke intervals are still measured. After at least 5 intervals, a mean of 12 ms or less, or a mean of 45 ms or less that is also very uniform (coefficient of variation 0.35 or less), raises a "shows signs of scripted input" warning. It captures machine-like speed and regularity no human produces, as supplementary evidence only; it doesn't change the block decision.
                • Off by default. Enable with Ports & Devices Monitor → "Unauthorized USB / BadUSB Physical Port Guard (Pro)"; manage the allowlist in "USB / BadUSB Guard Settings…".
                """,
                recommendation: "If you use external keyboards, register only the ones you connected yourself with Trust & Allow. Always reject and unplug a device that triggers the scripted-input warning."
            ),
            LocalizedEntry(
                id: "feat_usb_storage_guard",
                title: "Auto-Block Unauthorized USB Storage & ClamAV Auto-Scan (Pro)",
                summary: "A USB drive or external disk that isn't on the allowlist is first mounted read-only while you're asked what to do. Allowed devices are also scanned with ClamAV before being connected with their configured permission.",
                details: """
                • Monitoring: DiskArbitration catches external / removable volume mounts instantly.
                • Unregistered devices: remounted read-only for safety, with a dialog offering "Allow read-write", "Allow as Read-Only", or "Eject". Eject unmounts and ejects immediately.
                • Allowed devices: the allowlist permission (Read-only / Read & Write) is applied automatically, with a ClamAV scan before any upgrade to read-write.
                • Infection: if malware is found, the volume is ejected automatically and an urgent alert is sent.
                • Reformatted drives: if the volume UUID changes but the hardware identity including the serial number matches, the approval carries over (vendor/product ID alone never counts as a match).
                • Scope: covers data exfiltration and malicious payloads via storage. HID-type BadUSB devices pretending to be keyboards are handled by feat_usb_keyboard_guard.
                """,
                recommendation: "Allowlist only the USB drives you use for work, and prefer Read-only permission on Macs that handle sensitive data."
            ),
            LocalizedEntry(
                id: "feat_bluetooth_guard",
                title: "Auto-Off Bluetooth on Untrusted Networks (Pro)",
                summary: "When you join an away network where Maximum Lockdown applies, Bluetooth is turned off automatically to reduce exposure to unsolicited pairing and BLE attacks, and restored when you're back on a trusted network.",
                details: """
                • Tooling: macOS has no public API for toggling Bluetooth power, so RoamSwitch uses the open-source Homebrew tool `blueutil` (`brew install blueutil`). If it's missing, the menu shows setup guidance.
                • Restore: Bluetooth is turned back on at a trusted network only if it was on right before RoamSwitch turned it off; a choice you made yourself while away isn't overridden.
                • Off by default: many people use AirPods and similar at cafés, so silently cutting audio would be unwelcome. Opt-in.
                """,
                recommendation: "If you don't use Bluetooth accessories while away, enable it to avoid radio scanning and unsolicited pairing."
            ),
        ]
    }

    // MARK: - Features: malware & web protection

    private static func featuresEnMalware() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_webmail_download_guard",
                title: "Web & Mail Protection (Auto-Scan & Quarantine Downloads) (Pro)",
                summary: "Watches files saved from browsers, Mail, Slack, Discord, and similar with FSEvents, scans them with a static signature check and ClamAV, and moves threats to the quarantine vault.",
                details: """
                • Watched folders: by default `~/Downloads`, `~/Desktop`, `~/Documents`, and Mail's download folder. Add or remove folders with "⚙️ Manage Watched Folders…".
                • Download source: identified from the `com.apple.quarantine` extended attribute macOS attaches.
                • Two-layer check: an on-device static signature check (textbook reverse-shell one-liners and similar; works even without ClamAV) plus a ClamAV scan. A static-signature hit is quarantined regardless of ClamAV's verdict, and if ClamAV disagrees the notification says it may be a false positive.
                • Quarantine: threats are moved to `~/Library/Application Support/RoamSwitch/Quarantine/` (never deleted). If the move fails, the notification says quarantine failed and asks you to delete the file manually.
                • EICAR test file: the harmless industry-standard test signature is neither quarantined nor blocked and raises no notification; it is only recorded in the notification history (feat_notification_history).
                • First folder access: before macOS's permission prompt, a one-time notice explains that it is a legitimate permission for this scanning feature.
                • Pickle-format AI model warnings: see feat_ai_model_guard.
                """,
                recommendation: "Install ClamAV and enable it, and add any custom browser download folder to the watched folders."
            ),
            LocalizedEntry(
                id: "feat_ai_model_guard",
                title: "Dangerous AI Model Format (Pickle / PyTorch) Download Warning (Pro)",
                summary: "When a `.pkl` / `.pickle` / `.pt` model file is downloaded from Hugging Face, Civitai, or similar, warns that the Pickle format can run arbitrary code when loaded, and recommends SafeTensors / GGUF.",
                details: """
                • Detection: checks the extension of files downloaded into the folders watched by Web & Mail Protection (feat_webmail_download_guard).
                • Risk: Python's Pickle can execute arbitrary code during deserialization, so simply loading a malicious model can compromise the Mac.
                • Behavior: warning only; the file isn't quarantined (a ClamAV or static-signature hit is still quarantined as usual).
                """,
                recommendation: "Don't load Pickle / PyTorch models from unknown sources; use `.safetensors` or `.gguf` models instead."
            ),
            LocalizedEntry(
                id: "feat_quarantine_manager",
                title: "Quarantined File Management (Vault, Restore, Delete, Scan Exclusions)",
                summary: "Files flagged by ClamAV or the static signature check are never deleted; they are kept in the quarantine vault. The Quarantine Manager lets you see why, restore to the original location, delete permanently, or exclude a path from future scans.",
                details: """
                • Open: Malware Protection (XProtect & ClamAV) → ClamAV → "📦 Manage Quarantined Files…", or "📦 Open Quarantine Manager…" under Web & Mail Protection.
                • Location: `~/Library/Application Support/RoamSwitch/Quarantine/`, with metadata for original path, threat name, and quarantine time. Nothing is removed unless you explicitly choose Delete Permanently.
                • Restore: puts the file back in its original location; use only when you're sure it isn't infected.
                • Exclude & Restore: for a confirmed false positive, restores the file and excludes that exact path from future ClamAV scans. Exclusions are listed in the same window, where "Remove Exclusion" undoes them.
                • Delete Permanently: deletes after a confirmation. This can't be undone.
                • The MCP tool `get_quarantine_status` lists quarantined files.
                """,
                recommendation: "Delete files you don't recognize, and use Exclude & Restore only for certain false positives such as your own scripts or development binaries."
            ),
            LocalizedEntry(
                id: "feat_xprotect_file_safety",
                title: "Apple XProtect Status & File/App Safety Inspection",
                summary: "Shows the definition version and status of Apple's built-in XProtect malware protection, and inspects any file or app for notarization, signing authority, Team ID, and the download quarantine attribute. Available in the free edition.",
                details: """
                • Open: Malware Protection (XProtect & ClamAV) → "🍏 Apple XProtect" → "Check XProtect Status…" / "Inspect File/App Safety…".
                • Checks: Apple-approved (Notarized / Gatekeeper) or not, signing authority, Team ID, the web download quarantine attribute (`com.apple.quarantine`), and the path.
                • Use: before opening an app for the first time, confirm it was signed and notarized by a legitimate developer.
                """,
                recommendation: "Inspect apps of unknown origin before launching them, and don't open anything that isn't approved or signed."
            ),
            LocalizedEntry(
                id: "feat_dns_threat_guard",
                title: "DNS Threat Protection (Block Malware & C2) (Pro)",
                summary: "Applies a secure DNS resolver (Quad9, Cloudflare, AdGuard, CleanBrowsing) so name lookups for malware C2 servers and phishing sites are blocked at the DNS stage.",
                details: """
                • Providers: Quad9 (9.9.9.9 / 149.112.112.112), Cloudflare Security (1.1.1.2 / 1.0.0.2), AdGuard DNS (94.140.14.14 / 94.140.15.15, also blocks ads and trackers), CleanBrowsing Security (185.228.168.9 / 185.228.169.9).
                • Policy: "Untrusted Wi-Fi Only (Recommended)" or "Always Active on All Networks (Including Trusted)".
                • Internals: the privileged helper switches the DNS servers of the active network service and restores the original DHCP / manual DNS settings when you return to a trusted network.
                • Status: the menu shows "🟢 Secure DNS Active" or "🏠 Trusted Network (Standard Router DNS)". It is also an item in the Mac Security Audit.
                """,
                recommendation: "To avoid fake DNS on public Wi-Fi (DNS hijacking) and malicious domains, start with Quad9 plus the away-only policy."
            ),
            LocalizedEntry(
                id: "feat_passive_link_guard",
                title: "Link Guard (Detect & Block Phishing Connections: System Extension, DoH-aware, Warn Mode Fails Closed) (Pro)",
                summary: "Blocks connections to phishing and scam sites on the device, for any browser or app, based on a threat feed of known scam domains and brand-impersonation detection. Runs as a content-filter system extension, with an /etc/hosts sinkhole as the fallback until the extension is approved.",
                details: """
                • Modes: "Off", "Warn only (never block)", and "Auto-block clearly phishing sites (recommended)" (the default). Switch under Malware Protection → "Link Guard (phishing-connection detection) (Pro)".
                • What gets blocked: only clear cases, meaning domains in the threat feed or Unicode homograph impersonation of a brand. Brand-in-subdomain tricks, high-risk TLDs, and the like are treated as warnings. The verdict engine and feed are shared with the Linux edition.
                • System extension (recommended): the `RoamSwitchLinkFilter` content-filter system extension inspects TCP flows after name resolution. Besides the OS's resolved hostname it reads the SNI from the TLS ClientHello, so it works even when the browser uses its own DoH / DoT. In block mode it drops QUIC (UDP 443), where SNI isn't visible, so browsers fall back to TCP. First use needs approval in System Settings.
                • JA3 fingerprint: for TLS connections whose SNI was read, the client's JA3 hash is also computed and matched against the feed's JA3 list (JA3 alone is never used on connections without an SNI).
                • Warn mode (fails closed): the matching connection is paused and an Allow / Block notification plus a front-most panel appear; the flow resumes or is dropped based on your answer. With no answer within about 8 seconds the connection is blocked. That outcome isn't cached, so the next attempt asks again. Answers you actually give are remembered. Warn mode requires the system extension.
                • hosts fallback: while the extension isn't active, block mode has the privileged helper write the domains as `0.0.0.0` in a managed section of `/etc/hosts`.
                • Threat feed: fetched once a day, receive-only, with no identifiers sent, and verified with a dedicated Ed25519 feed key (separate from the app-update key). Turning Auto-update off means zero outbound traffic; the bundled data and homograph detection still work.
                • Without Pro: the mode is saved but nothing is blocked.
                """,
                recommendation: "Keep the default auto-block and approve the system extension for the most reliable protection. If an internal tool gets blocked by mistake, use the notification's “Allow once (5 min)” or the allowlist."
            ),
            LocalizedEntry(
                id: "feat_link_safety_auditor",
                title: "Link Safety Audit (Manual Check, Zero Telemetry)",
                summary: "Before you open a suspicious URL, analyzes it entirely on the device and scores its risk out of 100 based on Unicode homographs, subdomain impersonation, high-risk TLDs, cleartext HTTP, raw IP addresses, and more. Available in the free edition.",
                details: """
                • Open: Malware Protection → "🔗 Check a link manually…", or the MCP tool `audit_url_safety`.
                • Homographs: detects look-alike characters such as Cyrillic or Greek letters (Punycode / `xn--`).
                • Subdomain impersonation: analyzes structures like `apple.com.login-verify.xyz` that embed a major brand name.
                • High-risk TLDs: deducts points for TLDs common in throwaway phishing, such as `.xyz`, `.top`, `.tk`, `.icu`.
                • Cleartext HTTP and raw IPs: warns about unencrypted HTTP on login pages and bare IP-address URLs.
                • Fully local: URLs are never sent to an outside analysis API, so confidential URLs and tokens don't leak.
                """,
                recommendation: "Don't click suspicious links from email or chat directly; check them with the Link Safety Audit first."
            ),
            LocalizedEntry(
                id: "feat_ransomware_canary_guard",
                title: "Ransomware Bait-File Detection & Autonomous Air-Gap with Process Freeze (Pro)",
                summary: "Places hidden decoy (canary) files in your user folders. The moment one is modified, deleted, or renamed, it automatically cuts the network, stops sharing services, and pauses (SIGSTOP) the suspected process.",
                details: """
                • Bait files: four in `~/Library/Application Support/RoamSwitch/CanaryGuard/`, plus hidden files starting with `.roamswitch_security_canary_do_not_delete` in Documents, Desktop, Downloads, and Pictures. Each file's SHA-256 is recorded as its baseline.
                • Detection: real-time kqueue watching plus a check every 60 seconds. A 10-second per-file cooldown prevents duplicate handling of one event storm. Real files modified within the last 60 seconds are recorded as possibly affected.
                • Automatic response: (1) Application Firewall lockdown, (2) air-gap containment (pf blocks all traffic and the Wi-Fi radio is turned off, feat_airgap_containment), (3) sharing services (SMB / SSH / Screen Sharing) stopped, (4) the suspected process paused with SIGSTOP rather than killed, (5) an urgent alert and a front-most emergency window.
                • Why freeze instead of kill: networking is already cut, so a paused process can do no further damage. If it was a false positive, it is resumed (SIGCONT) on release and no data is lost.
                • On release: networking and Wi-Fi are restored, the paused process is resumed, and tampered bait files are regenerated.
                • Default: turned on automatically the first time Pro is activated. Incident history via the MCP tool `get_canary_status`. Test safely with "Ransomware Defense Simulation (Test Mode)" in the menu.
                """,
                recommendation: "Keep it on to protect important data from unknown ransomware, and don't delete the hidden bait files."
            ),
            LocalizedEntry(
                id: "feat_runtime_threat_containment",
                title: "Auto-Disconnect Network on XProtect Malware Detection (Pro)",
                summary: "The moment Apple's built-in XProtect / XProtect Remediator actually detects or removes malware, the network is cut in an emergency air-gap. A Gatekeeper block of an unsigned app does not cut the network; it only sends a notification.",
                details: """
                • Signal source: a long-running `/usr/bin/log stream` subscription in ndjson format (blocking wait rather than polling, so idle CPU cost is near zero) watches XProtect-related system logs.
                • Trigger: only when XProtect logs a critical malware finding does air-gap containment (including Wi-Fi radio off) engage, regardless of the network's trust level.
                • Versus Gatekeeper: everyday Gatekeeper events, such as blocking a developer's own unsigned build, only raise the notification "Gatekeeper blocked an unsigned app from running".
                • Consistency: it shares its classification logic with the manual Mac Security Log Audit.
                • It doesn't use an EndpointSecurity entitlement, so this is immediate containment after detection, not pre-execution blocking.
                • Default: turned on automatically the first time Pro is activated (with a one-time notice that automatic cutoff is enabled). Status via the MCP tool `get_runtime_threat_status`; test with "Simulate Malware-Detection Air-Gap (Test)".
                """,
                recommendation: "Keep it on as automatic defense linked to Apple's own malware engine. Frequently running your own unsigned apps won't trigger it, because Gatekeeper blocks alone never cut the network."
            ),
            LocalizedEntry(
                id: "feat_clickfix_guard",
                title: "ClickFix Defense — Auto-Block on Suspicious Terminal Commands (Pro, Off by Default)",
                summary: "Detects the ClickFix technique, where a fake CAPTCHA or error page tricks you into pasting and running a command yourself, from your shell history, and cuts the network to stop a multi-stage attack in progress.",
                details: """
                • Watched: only newly appended lines of `~/.zsh_history` and `~/.bash_history` (existing history is ignored).
                • Patterns: (1) known reverse-shell one-liners (shared with the static signature check), and (2) double indirection that pipes Base64-decoded content straight into a shell or `osascript`. A plain `curl ... | bash`, as used by legitimate installers such as Homebrew, is deliberately not flagged.
                • Response: air-gap containment (the Wi-Fi radio is not turned off), restored automatically within 10 minutes. The notification recommends checking your Keychain, browser-saved passwords, and crypto wallets.
                • Why after the fact: by the time a line is in history the command has already run, but cutting the network immediately can still stop a second-stage download, a live reverse shell, or credential exfiltration in progress.
                • Why Gatekeeper can't stop it: it's your own legitimate shell running exactly what you typed, so nothing about the process looks unusual.
                • Complement: clipboard protection (feat_secret_leak_auditor) catches the command at copy time, covering pastes into Script Editor, Spotlight, and other places besides Terminal.
                • Off by default: an automatic network cutoff driven by a relatively new heuristic, so it's opt-in.
                """,
                recommendation: "Consider enabling it if you're worried about being tricked by fake error pages or CAPTCHAs into running commands."
            ),
            LocalizedEntry(
                id: "feat_persistence_monitor_guard",
                title: "Watch for New Auto-Launch Registrations (LaunchAgent / LaunchDaemon) (Pro)",
                summary: "Watches for new LaunchAgent / LaunchDaemon registrations in real time and notifies you when one launches a shell or script interpreter directly, or registers an executable with an invalid signature.",
                details: """
                • Watched: `~/Library/LaunchAgents`, `/Library/LaunchAgents`, and `/Library/LaunchDaemons` via FSEvents (about 1.5-second debounce).
                • Judgment: recent infostealers persist by having validly Apple-signed `/bin/bash` or `/usr/bin/osascript` run a Base64-hidden script. Because the interpreter's own signature is valid, any registration that launches a bare interpreter is treated as suspicious regardless of signature, and its script arguments are also run through the static signature check. Unsigned or invalidly signed executables are flagged too. Homebrew services wrappers are exempt.
                • Detection only: without an EndpointSecurity entitlement, writing the plist can't be prevented. It is judged and reported within about 1.5 seconds of being written.
                • Default: on by default with Pro. Toggle under Malware Protection → "Watch for New Auto-Launch Registrations (LaunchAgent/Daemon) (Pro)".
                """,
                recommendation: "If you get an unfamiliar registration alert, inspect the plist shown in the notification and delete it if you don't recognize it. Right after installing a legitimate app, it's usually fine."
            ),
            LocalizedEntry(
                id: "feat_docker_event_guard",
                title: "Detect Docker Privileged Containers & docker.sock Mounts (Pro, Off by Default)",
                summary: "Notifies you, at container start, about risky Docker settings that can lead to container escape, such as containers started with `--privileged` or with `/var/run/docker.sock` mounted.",
                details: """
                • How: every 20 seconds `docker ps` finds only newly started containers, and `docker inspect` checks their settings. The detection format is identical to the Linux edition's, so both platforms flag the same conditions.
                • Notification only: it's a risky configuration, not a confirmed compromise (a monitoring agent may be run privileged on purpose), so nothing is blocked automatically.
                • Off by default: most users don't use Docker, so it's off even with Pro.
                • Test: "⚠️ Docker Risk Detection Simulation (Test Mode)…" checks the notification path without touching Docker.
                """,
                recommendation: "If you use Docker for development, enable it to spot container-escape risks early."
            ),
        ]
    }

    // MARK: - Features: audit, monitoring & platform

    private static func featuresEnAudit() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_critical_path_fim",
                title: "Critical System File Tampering Monitor (Critical Path FIM) (Pro)",
                summary: "Records a SHA-256 baseline of critical files such as sudoers, SSH configuration, PAM, and hosts, which legitimate OS updates and app installs almost never change, and notifies you of any modification, deletion, or new file.",
                details: """
                • Files: `/etc/sudoers`, `/etc/pam.d/sudo`, `/etc/ssh/sshd_config`, everything under `/etc/ssh/sshd_config.d/`, `/etc/hosts`, and root's `~/.ssh/authorized_keys`. They are root-only, so the privileged helper computes the hashes.
                • When: FSEvents on `/etc`, `/etc/pam.d`, and `/etc/ssh` trigger a near-real-time rescan, with an hourly scan as a backstop.
                • Baseline: captured on the first scan. A detected change is never adopted as the new baseline automatically, so the finding persists until a human reviews it. The same state isn't re-notified while the app keeps running; any further change alerts again.
                • Blind-spot warning: if the helper can't be reached for 3 scans in a row, you're told that tamper detection isn't working.
                • Note: while Link Guard runs in its hosts fallback, RoamSwitch itself may rewrite its managed section of `/etc/hosts`. LaunchAgents / Daemons are covered by feat_persistence_monitor_guard.
                • Default: turned on automatically the first time Pro is activated. Menu: Malware Protection → "Periodically monitor critical system files for tampering (Pro)".
                """,
                recommendation: "When alerted, check whether you made the change yourself (e.g. `sudo visudo` or a config edit). If not, inspect the file immediately and consider changing your password."
            ),
            LocalizedEntry(
                id: "feat_security_log_audit",
                title: "Mac Security Log Audit (Manual, Template Anomaly Detection, AI Consultation Copy)",
                summary: "Extracts sudo failures, SSH connections, Gatekeeper blocks, XProtect detections, and authentication events from macOS Unified Logging, and also lists new log patterns and frequency spikes (template anomalies). Available in the free edition.",
                details: """
                • Open: Mac Security Audit → "📜 Mac Security Log Audit…", or the MCP tool `audit_security_logs`.
                • Period: past 24 hours, 3 days, or 7 days.
                • Summary cards: Sudo failures, SSH connections, Gatekeeper blocks, XProtect detections, template anomalies. Filter by category and search.
                • Template anomalies: log lines are turned into patterns by masking variable parts (IP addresses, hex addresses, numbers). It surfaces patterns never seen on this Mac ([new]) and spikes far above their usual frequency ([spike z=…], z-score 3 or more). Each pattern's frequency is learned after 3 observations, after which normal volume no longer alerts.
                • Plain-language verdict: an on-device rule-based assistant summarizes the result for non-experts with specific things to check (no external API).
                • Output: "Copy Report", "Copy Materials for AI Consultation" (copies a question plus logs to paste into Claude, ChatGPT, and similar; RoamSwitch sends nothing), and "Export CSV (Pro)".
                """,
                recommendation: "Run it when suspicious notifications keep coming or the Mac behaves oddly, and check for XProtect detections or a surge in sudo failures."
            ),
            LocalizedEntry(
                id: "feat_scheduled_log_audit",
                title: "Automatic Log Audit (Learns New Patterns & Frequency Anomalies on a Schedule) (Pro)",
                summary: "Runs the log audit's template anomaly detection in the background every hour, continuously learning this Mac's normal log behavior. When it finds new patterns or frequency spikes, it notifies you with real log lines and a plain-language explanation.",
                details: """
                • Schedule: every hour, analyzing the last hour. The first scan runs about 10 seconds after enabling, but because it includes the app's own startup logs, that run only learns and never notifies.
                • Notification: the anomaly count (split into new patterns and spikes), up to 3 real log lines, a learning-progress note, and an explanation for non-experts. A new pattern becomes "known" once reported and is never re-notified for the same content; a spike stops alerting once that pattern's own baseline has been learned.
                • Shared with manual audit: uses the same analysis and learned baseline as the manual Mac Security Log Audit and the MCP tool `audit_security_logs`.
                • Default: turned on automatically the first time Pro is activated. Menu: Malware Protection → "Automatic Log Audit (learns new patterns & frequency anomalies on a schedule) (Pro)".
                """,
                recommendation: "Expect somewhat more new-pattern alerts right after setup; they settle as learning progresses. If an alert mentions an unfamiliar app or IP address, open the log audit window for details."
            ),
            LocalizedEntry(
                id: "feat_containment_incident_timeline",
                title: "Containment Incident Timeline (Unified Record, MITRE ATT&CK Mapping)",
                summary: "Stores the four automatic responses (ARP spoofing, ransomware bait files, XProtect-linked cutoff, unknown-port auto-block) in one chronological record on the device, so you can later review what happened, what was done, and when it was resolved.",
                details: """
                • Recorded: time, source, severity, summary, process name and PID (when known), action taken, and resolution time and reason (released manually, auto-released on timeout, or allowlisted).
                • MITRE ATT&CK: a technique ID is attached only when the mapping is certain (ARP spoofing = T1557; bait file deleted or renamed = T1485; encryption = T1486; other tampering = T1565). Nothing is guessed.
                • Storage: `~/Library/Application Support/RoamSwitch/containment_incident_timeline.json` (latest 200). Never sent anywhere.
                • The MCP tool `get_incident_timeline` returns this unified timeline (useful for triage with a local AI during an Air-Gap). Per-guard history is also available via `get_canary_status`, `get_port_anomaly_incidents`, and `get_runtime_threat_status`.
                """,
                recommendation: "After an automatic cutoff, review this timeline together with the notification history to find the cause and prevent a recurrence."
            ),
            LocalizedEntry(
                id: "feat_notification_history",
                title: "Notification History (Past Week)",
                summary: "Keeps every notification RoamSwitch has sent for 7 days so you can review alerts you missed. Events recorded to history without a banner, such as an EICAR test signature detection, also appear here. Available in the free edition.",
                details: """
                • Open: Mac Security Audit → "🔔 Notification History…".
                • Retention: 7 days; older entries are pruned automatically whenever a new one is recorded.
                • Contents: time, title, and body, including threat alerts, Link Guard connection events, ClickFix and secret-key detections, and automatic cutoffs.
                • EICAR test signature: the harmless industry test file isn't a real threat, so it is neither quarantined nor blocked and no banner is shown; it is only recorded here. This is the same for download protection, quick scans, and scheduled scans.
                • An AI assistant can read it via the MCP tool `get_notification_history`.
                """,
                recommendation: "If you missed a notification while away or busy, check it here."
            ),
            LocalizedEntry(
                id: "feat_secret_leak_auditor",
                title: "Clipboard Protection (API Key Paste Warning & ClickFix Command Removal)",
                summary: "Watches the clipboard on the device only, warns when an API key or private key has been copied so you don't paste it by mistake, and automatically clears the clipboard when you copy a malicious command that a scam site wants you to run (ClickFix). On by default in the free edition.",
                details: """
                • Monitoring: checks the clipboard for changes about once per second. Contents are never sent anywhere or stored.
                • Keys detected: OpenAI, Anthropic, GitHub, AWS, Hugging Face, Google AI / Gemini, Slack, and Stripe API keys and tokens, plus RSA / SSH private keys. Also cryptocurrency wallet seed phrases (BIP39) and Bitcoin private keys (WIF/BIP32) — both checksum-verified to keep false positives low.
                • For secret keys: notification only ("Confidential Key Detected in Clipboard"); the clipboard isn't cleared, since a leaked key can still be revoked and rotated afterwards.
                • For ClickFix commands: notification ("Suspicious Command Detected in Clipboard") and the clipboard is cleared immediately, stopping the paste wherever it was headed: Terminal, Script Editor, Spotlight, or elsewhere. It complements feat_clickfix_guard, which watches shell history.
                """,
                recommendation: "After copying an API key, be careful where you paste it, especially AI chats and web forms. If you shared one by mistake, revoke and reissue it right away."
            ),
            LocalizedEntry(
                id: "feat_secret_leak_audit_tool",
                title: "Manual Secret / API Key Leak Audit (Paste Text or Scan a Whole Folder)",
                summary: "An on-demand audit tool that checks pasted text instantly or scans a folder recursively, showing line numbers, masked values, and revocation steps for each key type. Available in the free edition.",
                details: """
                • Open: Malware Protection → "🔑 Manually Audit Secret/API Key Leaks…", or the MCP tool `audit_secrets` (with `text` or `path`).
                • Method: regular expressions plus Shannon entropy scoring. Detected values are shown masked.
                • Folder scan: `.git`, `node_modules`, `target`, `vendor`, `dist`, `build`, `__pycache__`, and `venv` are skipped automatically, as are files over 2 MB and binaries.
                • Permission notice: choosing a protected folder such as Desktop or Downloads first shows a one-time explanation of why access is needed and that the scan is Zero Telemetry, before macOS's prompt.
                • Runs on a background thread without freezing the UI. Nothing is sent anywhere.
                """,
                recommendation: "Use it before publishing a repository or pasting code into an AI chat."
            ),
            LocalizedEntry(
                id: "feat_package_cve_scan",
                title: "Package CVE Scan (Homebrew + 7 Ecosystems incl. npm / PyPI / crates.io, Zero Telemetry)",
                summary: "Checks installed Homebrew packages and the dependency lockfiles in project folders you choose against known-CVE maps kept on the device. The scan itself makes no network requests. Available in the free edition.",
                details: """
                • Open: Malware Protection → "📦 Package CVE Scan (Homebrew)…". For dependencies, add project folders in the Dependencies tab.
                • Homebrew: `brew list --versions` is matched against a formula-to-CPE table generated from real NVD data. Findings carry a confidence level: confirmed (verified table) or gray (unverified keyword match that may be a false positive).
                • Dependencies: parses package-lock.json / requirements.txt / Pipfile.lock / poetry.lock / Cargo.lock / Gemfile.lock / composer.lock / go.sum / pom.xml and checks them against known-CVE maps for npm, PyPI, crates.io, RubyGems, Packagist, Go, and Maven (from OSV.dev, CVSS 7.0 or higher).
                • Data delivery: the CVE maps are fetched once a day from a signed manifest, receive-only. Until fetched they show as not yet downloaded and detect nothing.
                • MCP tools: `run_package_cve_scan` (Homebrew) and `run_package_cve_scan_languages` (dependencies, `watchedFolders` argument).
                """,
                recommendation: "Run the Homebrew scan regularly, register active projects in the Dependencies tab, and update packages with serious CVEs promptly."
            ),
            LocalizedEntry(
                id: "feat_lockfile_tamper_guard",
                title: "Dependency Lockfile Tamper Monitoring (Lockfile FIM, Pro)",
                summary: "Continuously watches package-lock.json / yarn.lock / pnpm-lock.yaml / npm-shrinkwrap.json via a SHA-256 baseline, detecting external tampering via CI or the supply chain. Pro only.",
                details: """
                • How to open: toggle via the menu bar item "🔔/✅ Periodically monitor dependency lockfiles for tampering (Pro)".
                • Watched files: the same project folders registered in the Package CVE Scan window's "Dependencies" tab — no separate watched-folder list.
                • Detection: a CryptoKit SHA-256 baseline diff, with near-real-time FSEvents detection plus an hourly backstop scan.
                • Notification urgency: if npm/yarn/pnpm itself is running at detection time, it's recorded in notification history with a quiet, non-critical alert; otherwise it's a standard critical alert. Detection itself is never skipped either way.
                • Automatically disabled if the Pro license is lost.
                """,
                recommendation: "Register important projects in the Package CVE Scan window's \"Dependencies\" tab and leave this on (the default once Pro is active)."
            ),
            LocalizedEntry(
                id: "feat_package_lifecycle_script_scan",
                title: "Install Script Inventory (npm package.json lifecycle scripts, Pro)",
                summary: "Lists preinstall/install/postinstall/prepare scripts declared by package.json files under node_modules. Meant to surface code that runs unconditionally at npm install time — not a threat verdict. Pro only.",
                details: """
                • How to open: menu "Malware Protection" → "📦 Package CVE Scan (Homebrew)..." → the "Install Scripts (npm) (Pro)" tab. Scans the same project folders as the "Dependencies" tab.
                • Scope: one level under node_modules (plus one extra level for @scope/ packages). Never descends into a package's own nested node_modules.
                • Reference-only danger markers: commands matching curl|sh, wget|sh, eval(, base64 -d, or node -e get a ⚠️ badge — a lightweight heuristic, not a verdict; many legitimate scripts (native module builds, etc.) also match.
                • No network connection at all, and nothing is ever executed — a purely static inventory.
                • MCP tool: `run_package_lifecycle_script_scan` (`watchedFolders` argument, Pro only).
                """,
                recommendation: "For any script flagged ⚠️, check whether the package genuinely needs it — pay particular attention to postinstall scripts from unfamiliar packages."
            ),
            LocalizedEntry(
                id: "feat_npm_audit_signatures",
                title: "npm Signature / Provenance Verification (npm audit signatures, opt-in, Pro)",
                summary: "Contacts the npm registry to verify installed packages' signatures/provenance. The only feature in RoamSwitch that talks to npmjs.com — off by default, requiring explicit opt-in plus a per-run confirmation. Pro only.",
                details: """
                • How to enable: the "Enable npm signature verification" toggle in the "📦 Package CVE Scan" → "npm Signature Verification (opt-in) (Pro)" tab. This only unlocks the "Run Audit" button for each project folder — it never sends anything on its own. Every run is confirmed with "Contact the npm registry?".
                • What it does: runs `npm audit signatures` with the target folder as the working directory, contacting the npm registry (registry.npmjs.org). This is the only RoamSwitch feature that talks to npmjs.com.
                • Output: npm's own command output is shown verbatim (never hand-interpreted). A non-zero exit code, or wording like "invalid"/"missing registry signature" in the output, gets a lightweight attention marker.
                • If the npm command isn't found, a message prompts installing Node.js/npm.
                • MCP tool: `run_npm_audit_signatures` (`directory` argument, double-gated on Pro plus the opt-in toggle).
                """,
                recommendation: "Enable this only for a pre-deploy dependency audit or when investigating a suspected supply-chain compromise — it doesn't need to stay on all the time."
            ),
            LocalizedEntry(
                id: "feat_npm_sandboxed_install",
                title: "Sandboxed npm/pnpm Install (roamswitch-npm, Pro)",
                summary: "A real intervention wrapper — not just detection — that confines only the preinstall/install/postinstall/prepare script execution inside a network-denied sandbox (sandbox-exec), actually running the install on your behalf. Pro only.",
                details: """
                • How to enable: the "Install" button in "📦 Package CVE Scan" → "Sandboxed Install (npm/pnpm) (Pro)" places the command-line wrapper `roamswitch-npm` at ~/Library/Application Support/RoamSwitch/bin/.
                • Two-phase flow: ① The download phase runs `npm install --ignore-scripts` / `pnpm install --ignore-scripts` normally, with network access. ② The script phase runs `npm rebuild` / `pnpm rebuild` (plus `run prepare` if the root declares one) under a sandbox-exec profile with `(deny network-outbound)`.
                • Sandbox mechanism: the Linux version uses bwrap for filesystem restriction, but since macOS has no equivalent technology, this uses network blocking instead, verified to actually work on real hardware (`(allow default)` + `(deny network-outbound)`). File reads/writes and spawning child processes are not restricted.
                • Shell alias: two alias lines routing `npm`/`pnpm` through the wrapper can be appended to your shell config file (optional, only appended — existing content is left unchanged).
                • Preview: before running, you can list the project folder's lifecycle scripts (the same scanner "Install Script Inventory" uses).
                • If sandbox-exec is unavailable or fails, this never silently falls back to running unsandboxed. yarn is not supported. There's no GTK/MCP tool — it's a command-line tool used from a terminal.
                """,
                recommendation: "For projects containing unfamiliar packages, or projects fetched from external sources, use `roamswitch-npm install` in place of a regular npm/pnpm install."
            ),
            LocalizedEntry(
                id: "feat_typosquat_guard",
                title: "Typosquat Detection (npm/pnpm package.json, Pro)",
                summary: "Checks package.json dependency names against a list of popular npm package names by edit distance (Levenshtein 1-2), flagging possible typosquatting such as expres→express or loadash→lodash. The app itself makes no network connections to do this. Pro only.",
                details: """
                • Scope: only the project's own package.json dependencies/devDependencies/optionalDependencies (peerDependencies is out of scope). node_modules (already-installed transitive dependencies) is deliberately out of scope too — a typo is introduced at the moment a human adds a dependency to package.json.
                • Matching logic: a standard Levenshtein-distance DP implementation checks each dependency name against a list of popular npm package names. Scoped packages (`@scope/pkg`) compare by their base name (`pkg`). Candidates whose length differs by more than 2 are skipped by a cheap pre-filter. The threshold is edit distance up to 2 for popular names of 8+ characters, distance 1 only for shorter names.
                • How the list stays current: the popular-package-name list checked against is distributed by `PackageCveMapUpdater` via the same once-a-day, receive-only, Ed25519-signed manifest as the CVE maps (a build-time embedded seed plus a two-tier override, preferring whichever has the newer `mapVersion`). The list can be refreshed without waiting for an app release.
                • Reference information, not a verdict — a known allowlist suppresses some legitimate look-alike packages (e.g. preact), but it isn't exhaustive.
                • How to open: "📦 Package CVE Scan" → "Typosquat Detection (Pro)" tab, targeting the same project folders as the "Dependencies" tab. MCP: `run_typosquat_scan` (`watchedFolders` argument, Pro only).
                """,
                recommendation: "Double-check any ⚠️-flagged dependency for an actual typo — pay particular attention to unfamiliar package names."
            ),
            LocalizedEntry(
                id: "feat_security_health_checker",
                title: "Mac Security Audit (18 Items, Score & Fix Steps)",
                summary: "Checks 18 items across six areas (system hardening, network defense, authentication and access control, port exposure, malware protection, and physical device defense) and shows a 0-100 score, a grade, and steps to fix each failing item. Available in the free edition.",
                details: """
                • System hardening: 1. FileVault, 2. SIP (System Integrity Protection), 3. Gatekeeper, 4. automatic security updates, 5. Apple XProtect.
                • Network defense: 6. macOS firewall, 7. stealth mode, 8. Wi-Fi encryption strength, 9. ARP spoofing monitor, 10. gateway ARP lock.
                • Authentication & access control: 11. SSH remote login configuration (root login disabled, key-only auth), 12. sudo privilege escalation (`NOPASSWD` audit).
                • Services & port exposure: 13. exposed ports.
                • Malware & download protection: 14. Web & Mail Protection, 15. DNS Threat Protection, 16. phishing & malicious link protection (Safari fraudulent website warning).
                • Physical ports & devices: 17. Unauthorized USB / BadUSB physical port guard, 18. macOS accessory connection protection (Apple silicon).
                • Not applicable: firewall and stealth on a trusted network, SSH when remote login is off, the sudo audit before the helper connects, and accessory protection on Intel Macs are excluded from the score.
                • Grades: 100 = S, 85-99 = A, 70-84 = B, below 70 = C. Also available via the MCP tool `get_security_report`.
                """,
                recommendation: "Open the audit report regularly, work through the ⚠️ items using the fix steps, and keep grade A or better."
            ),
            LocalizedEntry(
                id: "feat_autonomous_sentinel",
                title: "Background Autonomous Patrol, ClamAV Definition Updates & Scheduled Scans",
                summary: "Every 4 hours, refreshes the security audit, ports, USB devices, and XProtect status in the background (all editions). Pro additionally warns about score drops, updates ClamAV definitions automatically, and runs a daily virus scan.",
                details: """
                • Periodic audit (all editions): about 30 seconds after launch and then every 4 hours, so results stay current even if you stay on one network for hours.
                • Score-drop warning (Pro): notifies when the score falls below 80 or 4 or more items fail.
                • ClamAV definitions (Pro): runs `freshclam` silently.
                • Scheduled scan (Pro): once a day, scans `~/Downloads`, `~/Desktop`, and `~/Library/LaunchAgents` with ClamAV. Threats are quarantined automatically with an urgent alert; a clean result is a quiet completion notice. If only the EICAR test signature is found, nothing is shown and it's recorded to notification history.
                """,
                recommendation: "On Pro, install ClamAV so definition updates and scheduled scans run automatically."
            ),
            LocalizedEntry(
                id: "feat_simulation_self_test",
                title: "Simulation (Self-Test) Tools",
                summary: "Safely test that ransomware defense, the malware-detection air-gap, and Docker risk detection work, without any real attack or file damage.",
                details: """
                • Where: at the bottom of Malware Protection (XProtect & ClamAV).
                • 🚨 Ransomware Defense Simulation (Test Mode)…: runs the same steps as a detected encryption attempt to check the air-gap and emergency window. No files are harmed.
                • 🚨 Simulate Malware-Detection Air-Gap (Test)…: runs the same steps as a real XProtect detection to check containment and the emergency window. The event is labeled as a simulation.
                • ⚠️ Docker Risk Detection Simulation (Test Mode)…: checks that the privileged-container notification arrives. Docker isn't touched.
                • Note: the air-gap tests really do cut the network temporarily. Release from the emergency window (it also restores itself within 10 minutes).
                • To test download protection you can use a harmless EICAR test file (no banner; it's recorded in notification history).
                """,
                recommendation: "Run a simulation once after activating Pro or changing settings to confirm notifications and the air-gap behave as expected."
            ),
            LocalizedEntry(
                id: "feat_privileged_helper",
                title: "Privileged Helper Tool (RoamSwitchHelper, XPC)",
                summary: "Only operations that need root (PF firewall, sharing services, DNS, air-gap, and so on) are performed by a privilege-separated LaunchDaemon helper over XPC.",
                details: """
                • Privilege separation: the main app runs with normal user rights and delegates only pf rule changes, sharing daemon control, DNS settings, ARP pinning, critical-file hashing, and similar tasks to `RoamSwitchHelper`.
                • Registration: registered via macOS's SMAppService as a LaunchDaemon bundled inside the app. First use requires approval in System Settings → General → Login Items & Extensions. It can't be registered if the app isn't in the Applications folder (faq_install_location).
                • Companion daemons: helper LaunchDaemons for the air-gap failsafe (auto-release after 10 minutes) and the boot gate (up to 90 seconds) are also registered.
                • Verification: code signatures (Team ID) are checked on XPC connections, rejecting calls from unauthorized processes.
                """,
                recommendation: "Approve the helper when prompted on first launch. If it isn't approved, the menu shows “⚠️ Approve the helper…”."
            ),
            LocalizedEntry(
                id: "feat_mcp_server",
                title: "MCP Server Integration (Read-Only Access for AI Assistants)",
                summary: "RoamSwitch.app includes a read-only MCP (Model Context Protocol) server, so AI assistants such as Claude can ask about your Mac's security state. There are no tools that change settings or block anything.",
                details: """
                • Transport: local stdio only. Binary: `/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`.
                • Main tools: `get_security_report` (security audit), `get_exposed_ports`, `get_guard_status`, `audit_url_safety`, `audit_secrets`, `audit_security_logs`, `get_quarantine_status`, `get_notification_history`, `get_canary_status`, `get_port_anomaly_incidents`, `get_runtime_threat_status`, `get_incident_timeline` (containment incident timeline), `get_network_history` (network history learning), `run_package_cve_scan`, `run_package_cve_scan_languages`, `run_active_vuln_scan` (the only tool that sends traffic, non-destructive probes to 127.0.0.1), and `get_app_help` (this knowledge base).
                • Resources: `roamswitch://docs/features`, `roamswitch://docs/alerts-and-messages`, `roamswitch://docs/settings-guide`, `roamswitch://docs/troubleshooting`.
                • Language: answers follow the app's language setting. `get_app_help` accepts a `language` argument (ja / en / zh-Hans / zh-Hant / ko / de / fr / es / it / pt-PT).
                • Safety: because it's read-only, even an AI manipulated by prompt injection can't change the protection level or isolate ports.
                """,
                recommendation: "See faq_mcp_setup for setup. You can ask in plain language, like “Is my Mac secure right now?” or “What does this notification mean?”"
            ),
            LocalizedEntry(
                id: "feat_license_pro_tier",
                title: "Pro Lifetime License (One-Time Purchase, Up to 2 Macs)",
                summary: "Pro is a one-time lifetime license (¥2,980 / $19.99) usable on up to 2 Macs. The Ed25519-signed license token is verified on the device, so Pro keeps working offline after activation.",
                details: """
                • Pro features: the automatic defenses marked (Pro) in the menu (ransomware bait-file detection, XProtect-linked cutoff, unknown-port auto-block and dev server isolation, ARP spoofing auto-block, gateway ARP/NDP pinning, VPN tunnel, BadUSB and USB storage guards, Web & Mail Protection, DNS Threat Protection, Link Guard, Bluetooth auto-off, ClickFix defense, auto-launch registration monitoring, Docker risk detection, critical file tampering monitor, automatic log audit), real-time threat notifications, patrol warnings and scheduled scans, CSV export of logs, and more.
                • License types: Pro Lifetime (2 Macs) and Team Lifetime (5 Macs).
                • Activation: enter your license key (ROAM-XXXX-…) from "💎 Activate / Buy Pro…". The signed token issued by the server is verified with the public key inside the app and stored in the Keychain.
                • Deactivation: from the license window. It removes the license from this Mac and frees the seat on the server (local deactivation always happens even if the network request fails).
                • On lapse: Pro-only guards are turned off automatically, and the VPN tunnel and port isolation are released.
                """,
                recommendation: "Consider Pro if you want automatic containment, real-time defense, and patrol warnings. When replacing a Mac, deactivate on the old one first, then activate on the new one."
            ),
        ]
    }

    // MARK: - Alerts: network, devices, links

    private static func alertsEnNetwork() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "alert_arp_spoofing",
                title: "⚠️ ARP Spoofing (MITM) Alert",
                summary: "Shown when there are signs of a device on your network impersonating the router (gateway) to eavesdrop on or tamper with your traffic.",
                details: """
                • Cause: an attacker sends forged ARP replies so your traffic flows through them (man-in-the-middle). Detected when the gateway's IP stays the same but its MAC address suddenly changes. A router reboot or mesh Wi-Fi handoff can also cause it.
                • Automatic defense: on Maximum Lockdown with "Auto-block on ARP spoofing (network impersonation) detection (Pro)" enabled, immediate air-gap containment. On other levels, notification only, and the menu shows "ARP spoofing detected — cut all network now".
                """,
                recommendation: """
                1. Stop entering passwords, making payments, or doing work traffic on this network immediately.
                2. On public Wi-Fi or any unfamiliar network, choose "cut all network now" from the menu or turn Wi-Fi off.
                3. If you need internet access, switch to a safe connection such as tethering or the VPN tunnel.
                4. Keep using the network only if you know it's a false positive, for example right after restarting your home router.
                """
            ),
            LocalizedEntry(
                id: "alert_evil_twin_ssid",
                title: "⚠️ Possible Evil-Twin Wi-Fi network detected",
                summary: "Shown when the name (SSID) of the Wi-Fi you joined is very similar to a network you've used before. It may be a malicious fake access point (Evil Twin).",
                details: """
                • Cause: an attacker sets up a fake access point whose name differs from a legitimate one by just one or two characters to lure people in. Network history learning (feat_network_history_guard) judges this from the edit distance to learned names and the different gateway hardware.
                • False-positive control: short names and extra SSIDs broadcast by the same gateway hardware don't trigger it.
                • Automatic defense: notification only. As an unregistered network, the Default Away Protection level applies.
                """,
                recommendation: """
                1. Don't log in or enter personal information on this Wi-Fi.
                2. Confirm the official network name (signs in the shop or office) and disconnect if it doesn't match.
                3. If you must keep using it, connect the VPN tunnel.
                """
            ),
            LocalizedEntry(
                id: "alert_unencrypted_wifi",
                title: "⚠️ Connected to Unencrypted Wi-Fi",
                summary: "Shown when you join an open Wi-Fi network without a password or encryption (WPA2 / WPA3), or an old WEP network.",
                details: """
                • Cause: the wireless link isn't encrypted, so anyone nearby can capture the traffic.
                • Automatic defense: if the network is unregistered, Default Away Protection (initially Maximum Lockdown) blocks inbound connections and sharing services.
                """,
                recommendation: """
                1. If possible, connect the VPN tunnel or switch to a trusted connection such as tethering.
                2. Avoid logging in or entering personal information on sites that aren't HTTPS.
                3. Confirm in the menu that the protection level is Maximum Lockdown.
                """
            ),
            LocalizedEntry(
                id: "alert_port_anomaly",
                title: "🚨 Automatically blocked an unknown listening port",
                summary: "Shown when a program that wasn't exposed before started exposing a port to the LAN on 0.0.0.0 and access from outside was blocked automatically (“Detected an unknown listening port (blocking failed)” is shown if blocking didn't succeed).",
                details: """
                • Cause: a dev server starting (Next.js, Vite, Python, Docker), a LAN receiver app such as LocalSend or Syncthing launching for the first time, or a backdoor or rogue app starting to listen.
                • Automatic defense: pf blocks external access only (the Mac itself and localhost can still use it). macOS system daemons are excluded.
                """,
                recommendation: """
                1. Check whether you recognize the process name, PID, and port shown in the notification (also visible under Exposed Ports).
                2. If it's your own server or a LAN receiver app, allow it with the notification's "Allow" button or from the port audit screen. It stays allowed from then on.
                3. For dev servers, restarting bound to `127.0.0.1` is the safest option.
                4. If you don't recognize it, keep it blocked, quit the process, and run the security audit and a virus scan.
                """
            ),
            LocalizedEntry(
                id: "alert_exposed_database",
                title: "🚨 Unauthenticated database service exposed externally",
                summary: "Shown when a service that often has no authentication by default (Redis, MongoDB, Memcached, Elasticsearch) is exposed to the LAN without firewall protection.",
                details: """
                • Cause: a database or backend service started on 0.0.0.0 while the current protection level allows inbound connections. Anyone on the same network may be able to read or write the data.
                • Automatic defense: notification (Pro), not repeated for the same port.
                """,
                recommendation: """
                1. Change the service's listen address to `127.0.0.1` or enable authentication.
                2. If you can't fix it right away, open the port under Exposed Ports and choose "Isolate Port".
                3. Use Maximum Lockdown on public networks.
                """
            ),
            LocalizedEntry(
                id: "alert_unapproved_keyboard",
                title: "⚠️ Unauthorized Keyboard / BadUSB Connection Detected",
                summary: "The notification and approval window shown when a new USB keyboard that isn't on the allowlist (or a device pretending to be one, such as a modified cable) is connected and its keystrokes are blocked until approved.",
                details: """
                • Cause: connecting a new external keyboard or docking station, or a keystroke-injection device such as a Rubber Ducky.
                • Automatic defense: only that device's keystrokes are blocked (other keyboards keep working). The "⚠️ Unknown USB Device / Keyboard Detected" window asks for approval.
                """,
                recommendation: """
                1. If it's a trusted keyboard you connected yourself, click "Trust & Allow". It's added to the allowlist and input is enabled.
                2. If you don't recognize it, or it appeared without you connecting anything, click "Reject & Keep Blocked" and unplug the device.
                """
            ),
            LocalizedEntry(
                id: "alert_scripted_keyboard",
                title: "🚨 This keyboard shows signs of automated (scripted) typing",
                summary: "Shown when a keyboard awaiting approval sends keystrokes at intervals too fast and too uniform for a human. Automated command injection (a BadUSB attack) is highly likely.",
                details: """
                • Cause: a Rubber Ducky, Flipper Zero, Arduino / Digispark, or similar tried to type pre-loaded commands at high speed. Judged by keystroke timing analysis: after at least 5 intervals, a mean of 12 ms or less, or 45 ms or less while very uniform.
                • Automatic defense: the device's keystrokes were already blocked before approval and never reached the Mac. This warning adds evidence for your decision.
                """,
                recommendation: """
                1. Always choose "Reject & Keep Blocked" in the approval window.
                2. Unplug the device immediately and check where it came from (a found USB stick, a gifted cable, and so on).
                3. As a precaution, run the security audit and review auto-launch registrations.
                """
            ),
            LocalizedEntry(
                id: "alert_untrusted_usb",
                title: "🔒 Mounted USB Storage as Read-Only / 🔌 Automatically Blocked Unauthorized USB Storage",
                summary: "Shown when a USB drive or external disk that isn't on the allowlist is connected and has been mounted read-only pending your approval, or has been ejected.",
                details: """
                • Cause: an unregistered storage device was connected. This prevents data theft and malicious files being brought in.
                • Automatic defense: remounted read-only with an "Allow USB storage “…”?" dialog. Choosing Eject ejects it and sends "Automatically Blocked Unauthorized USB Storage".
                """,
                recommendation: """
                1. If it's your device, choose "Allow read-write" or "Allow as Read-Only". It's added to the allowlist and applied automatically next time.
                2. If you don't recognize it, choose "Eject".
                3. You can change the allowlist later in "USB / BadUSB Guard Settings…".
                """
            ),
            LocalizedEntry(
                id: "alert_malware_usb",
                title: "🚨 Malware Detected on USB Storage",
                summary: "Shown when the ClamAV scan run before a USB storage device is connected read-write finds infected files.",
                details: """
                • Cause: infected files on the USB drive.
                • Automatic defense: the volume is ejected immediately so the Mac isn't infected.
                """,
                recommendation: """
                1. Format or disinfect the drive in a separate safe environment before using it again.
                2. Run a ClamAV quick scan or folder scan to make sure the Mac itself isn't infected.
                """
            ),
            LocalizedEntry(
                id: "alert_link_guard_blocked",
                title: "🛑 Link Guard: connection blocked",
                summary: "Shown when Link Guard automatically blocked a connection to a suspected scam or phishing site (listed in the threat feed, or a brand homograph).",
                details: """
                • Cause: a link in email or social media, an ad, or an app tried to connect to a known scam domain.
                • Automatic defense: the system extension drops the connection, or the hosts fallback resolves the domain to 0.0.0.0, for any browser or app.
                """,
                recommendation: """
                1. If you didn't expect it, nothing more is needed; don't enter information on that page.
                2. If a legitimate site you need was blocked by mistake, use "Allow once (5 min)" on the notification or add it to the allowlist.
                """
            ),
            LocalizedEntry(
                id: "alert_link_guard_warn_hold",
                title: "⚠️ Link Protection: connection on hold",
                summary: "In warn mode, the notification and front-most panel shown when a connection to a suspected brand-impersonation or scam site has been paused while you decide whether to allow it.",
                details: """
                • Cause: a connection to a domain that triggers a warning (subdomain impersonation, high-risk TLD, and so on).
                • Automatic defense: the connection is paused awaiting your answer. With no answer within about 8 seconds it is blocked (fail-closed). That result isn't cached, so the next visit asks again. Answers you give are remembered.
                """,
                recommendation: """
                1. If you opened it on purpose and trust the site, choose "Allow".
                2. If you don't recognize it or aren't sure, choose "Block" or just wait (it will be blocked automatically).
                3. If it was blocked by mistake, reload the page to be asked again.
                """
            ),
            LocalizedEntry(
                id: "alert_dangerous_url",
                title: "🛑 Dangerous Link / Suspected Phishing (Link Safety Audit)",
                summary: "Shown when the Link Safety Audit (or `audit_url_safety`) judges a URL dangerous because of homographs, a spoofed subdomain, a high-risk TLD, and similar.",
                details: """
                • Checks: homograph characters (Punycode), subdomains imitating major companies, TLDs common in phishing, cleartext HTTP, raw IP addresses, and more.
                • Score: below 50 is Dangerous; 50-79 is Caution.
                """,
                recommendation: """
                1. Don't open the link.
                2. Delete the message and report it to your security team if appropriate.
                """
            ),
            LocalizedEntry(
                id: "alert_helper_disconnected",
                title: "⚠️ Helper Not Connected",
                summary: "Shown when XPC communication with the privileged helper tool (RoamSwitchHelper) can't be established.",
                details: """
                • Cause: background execution isn't approved in Login Items & Extensions, the helper stopped after a macOS update, or the app is outside the Applications folder (in Downloads or inside the disk image).
                • Impact: operations that need root (switching protection levels, air-gap containment, DNS settings, critical file monitoring, and so on) can't run.
                """,
                recommendation: """
                1. Choose "⚠️ Approve the helper…" in the menu to open the approval steps.
                2. In System Settings → General → Login Items & Extensions, turn on RoamSwitchHelper under Allow in the Background.
                3. Make sure RoamSwitch is in the Applications folder.
                4. If that doesn't help, follow faq_helper_troubleshooting.
                """
            ),
            LocalizedEntry(
                id: "alert_score_drop",
                title: "⚠️ Mac Security Degradation Warning",
                summary: "Sent by the autonomous patrol when the security score falls below 80 or 4 or more items fail (Pro).",
                details: """
                • Cause: a change in settings or environment, such as FileVault or the firewall being turned off, a dangerous port being exposed, or a guard being stopped.
                • Criteria: score below 80, or 4 or more failing items.
                """,
                recommendation: """
                1. Open the audit report from the menu (or use the MCP tool `get_security_report`).
                2. Work through the items marked ⚠️ using the fix steps shown.
                """
            ),
        ]
    }

    // MARK: - Alerts: malware, containment, audit

    private static func alertsEnMalware() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "alert_quarantined_download",
                title: "🚨 Quarantined Dangerous Downloaded File",
                summary: "Shown when a file saved from a browser, Mail, or a chat app contained a threat and was moved to the quarantine vault (“quarantine failed” is shown if the move didn't succeed).",
                details: """
                • Cause: the downloaded file contained malware, a trojan, a reverse shell, or similar.
                • Automatic defense: moved to `~/Library/Application Support/RoamSwitch/Quarantine/` so it can't run. If the static signature check flagged it but ClamAV didn't, the notification mentions a possible false positive.
                """,
                recommendation: """
                1. If quarantine succeeded, the file can't run.
                2. Open "📦 Manage Quarantined Files…" and choose "Delete Permanently" if you don't recognize it.
                3. Use "Restore" or "Exclude & Restore" only for certain false positives.
                4. If quarantine failed, delete the file at the path shown in the notification manually.
                """
            ),
            LocalizedEntry(
                id: "alert_eicar_test_signature",
                title: "🧪 EICAR test signature detected (harmless) — Recorded to Notification History Only",
                summary: "How the harmless EICAR test file used to check antivirus software is handled. It isn't a real threat, so no banner is shown and nothing is quarantined or blocked; it's only recorded in the notification history.",
                details: """
                • Applies to: Web & Mail Protection, ClamAV quick / folder scans, and the patrol's scheduled scan alike.
                • Behavior: the file stays where it is. "EICAR test signature detected (harmless)" is recorded in "🔔 Notification History…".
                • Why: warning banners for non-threats would bury the alerts that really matter.
                """,
                recommendation: """
                1. No action needed. If you placed the file for testing, delete it once you've confirmed the result.
                2. You can confirm scanning works by checking the notification history for the record.
                """
            ),
            LocalizedEntry(
                id: "alert_pickle_model",
                title: "⚠️ Pickle Format AI Model Download Detected",
                summary: "Shown when a `.pkl` / `.pickle` / `.pt` AI model file is downloaded. The Pickle format can run arbitrary code just by being loaded.",
                details: """
                • Cause: a model file was saved from Hugging Face, Civitai, or similar.
                • Automatic defense: warning only (the file isn't quarantined).
                """,
                recommendation: """
                1. Don't load models unless they come from a trusted official source.
                2. Where possible, use the same model in `.safetensors` or `.gguf` format.
                """
            ),
            LocalizedEntry(
                id: "alert_ransomware_activity",
                title: "🚨 CRITICAL AUTO-DEFENSE: Ransomware Activity Blocked",
                summary: "The urgent notification and emergency window shown when a decoy (canary) file was modified, deleted, or renamed and air-gap containment, sharing shutdown, and a pause of the suspected process were triggered.",
                details: """
                • Cause: a process such as ransomware trying to encrypt or destroy files in your user folders (or a simulation run).
                • Automatic defense: all traffic cut plus Wi-Fi radio off, SMB / SSH / Screen Sharing stopped, and the suspected process paused (SIGSTOP). The emergency window shows whether the cutoff succeeded, the suspected process, and files that may have been affected.
                """,
                recommendation: """
                1. Save your open work and quit every suspicious app.
                2. In Activity Monitor, look for processes with spiking CPU or disk writes and force-quit any you don't recognize.
                3. Check the possibly affected files and your backups (Time Machine and so on).
                4. Once safe, release containment from the emergency window (networking is restored, the paused process resumed, and the bait files regenerated).
                """
            ),
            LocalizedEntry(
                id: "alert_runtime_threat_airgap",
                title: "🚨 XProtect Detected Malware — Network Cut Automatically",
                summary: "The emergency window and notification shown when Apple's XProtect / XProtect Remediator convicted a file as malware and the XProtect-linked auto-cutoff engaged air-gap containment.",
                details: """
                • Cause: Apple's malware engine judged a file you downloaded or ran to be malicious.
                • Automatic defense: all traffic cut plus Wi-Fi radio off, restored automatically within 10 minutes if not released. The detecting process, category, and Apple's detection message are recorded.
                """,
                recommendation: """
                1. Identify the files or apps you just downloaded or ran and delete them.
                2. Run a ClamAV scan and the security audit, and check auto-launch registrations (LaunchAgents) for anything suspicious.
                3. Once safe, release containment from the emergency window.
                4. The status is also available via the MCP tool `get_runtime_threat_status`.
                """
            ),
            LocalizedEntry(
                id: "alert_gatekeeper_block",
                title: "🛡️ Gatekeeper blocked an unsigned app from running",
                summary: "A notification that macOS Gatekeeper blocked an app without a signature or notarization from launching. No automatic cutoff.",
                details: """
                • Cause: you tried to open an unsigned app from the internet or your own development build.
                • Automatic defense: none (notification only). The XProtect-linked cutoff engages only when XProtect actually detects malware.
                """,
                recommendation: """
                1. If you recognize it (e.g. your own build), no action is needed.
                2. If not, check the signing authority with "Inspect File/App Safety…" and delete it if suspicious.
                """
            ),
            LocalizedEntry(
                id: "alert_clickfix_command",
                title: "🚨 Suspicious command execution detected / ⚠️ Suspicious Command Detected in Clipboard",
                summary: "Shown when a command matching the ClickFix technique was run in Terminal (detected from shell history) or copied to the clipboard.",
                details: """
                • Cause: you were led to a fake CAPTCHA or a fake error page saying "run this command to fix it". Reverse-shell one-liners and Base64-decoded content piped into a shell or osascript are flagged.
                • Automatic defense (run in Terminal, Pro, off by default): air-gap containment (Wi-Fi radio not turned off), restored automatically within 10 minutes.
                • Automatic defense (copied, on by default): the clipboard is cleared immediately.
                """,
                recommendation: """
                1. If you only copied it, close that web page and don't paste or run anything.
                2. If you ran it, check that your Keychain, browser-saved passwords, and crypto wallets are safe, and change important passwords from another trusted device.
                3. Check auto-launch registrations (LaunchAgents / Daemons) for anything suspicious and run a ClamAV scan.
                """
            ),
            LocalizedEntry(
                id: "alert_new_persistence_item",
                title: "🚨 New auto-launch registration detected",
                summary: "Shown when a new LaunchAgent / LaunchDaemon was registered and judged suspicious (it launches a script interpreter directly, has an invalid signature, and so on).",
                details: """
                • Cause: malware such as an infostealer registering itself to survive reboots, or an app installer adding one.
                • Automatic defense: notification only (the registration itself can't be prevented). The notification shows the plist path and the reason.
                """,
                recommendation: """
                1. Check whether you just installed an app yourself. If so, no action is needed.
                2. If not, delete the plist shown in the notification and the script or app it launches.
                3. Restart the Mac afterwards and run a ClamAV scan.
                """
            ),
            LocalizedEntry(
                id: "alert_docker_risk",
                title: "⚠️ Risky Docker Container Configuration Detected",
                summary: "Notifies you that a container started with `--privileged` or with `docker.sock` mounted has just started.",
                details: """
                • Cause: privileged containers and Docker socket mounts let a container control the host, creating a container-escape risk.
                • Automatic defense: none (notification only).
                """,
                recommendation: """
                1. If it's intentional (e.g. a monitoring agent), no action is needed.
                2. Otherwise, check the container with `docker ps` and `docker inspect` and stop it.
                """
            ),
            LocalizedEntry(
                id: "alert_critical_file_tampering",
                title: "🚨 Critical system file tampering detected",
                summary: "Shown when a change, deletion, or new file is detected among critical files such as sudoers, SSH configuration, PAM, hosts, or root's authorized_keys.",
                details: """
                • Cause: a configuration change by an administrator (`sudo visudo`, editing SSH settings), a change by software, or an attacker escalating privileges or planting a backdoor.
                • Automatic defense: notification only. The new state is never accepted as legitimate automatically.
                • Related: "Critical file tamper detection isn't working" means scans have repeatedly failed because the privileged helper couldn't be reached.
                """,
                recommendation: """
                1. Check whether you or an administrator changed the files shown in the notification.
                2. If not, look for `NOPASSWD` entries in `/etc/sudoers`, unknown keys in `authorized_keys`, and similar, and remove them.
                3. Change the administrator password and run the security audit.
                """
            ),
            LocalizedEntry(
                id: "alert_log_audit_anomaly",
                title: "🔔 Log Audit: anomalous patterns detected",
                summary: "Sent by the automatic log audit when it finds log patterns never seen on this Mac ([new]) or logs far more frequent than usual ([spike z=…]).",
                details: """
                • Cause: usually expected changes from connecting a new device or updating apps or macOS, but sometimes suspicious login attempts or unknown process activity.
                • Contents: the count breakdown, up to 3 real log lines, learning progress (e.g. frequency baseline still learning: 2/3 observations), and a plain-language explanation.
                • Automatic defense: none (notification only).
                """,
                recommendation: """
                1. If there are only new patterns and no unfamiliar app names or IP addresses, no action is needed.
                2. If a frequency spike coincides with something you didn't do, open "📜 Mac Security Log Audit…" for details.
                3. If unsure, use "Copy Materials for AI Consultation" to ask an AI assistant.
                """
            ),
            LocalizedEntry(
                id: "alert_secret_in_clipboard",
                title: "🔑 Confidential Key Detected in Clipboard",
                summary: "Tells you an API key or private key (OpenAI, Anthropic, GitHub, AWS, and so on) is on the clipboard.",
                details: """
                • Cause: you copied an API key, token, or private key.
                • Automatic defense: notification only (the clipboard isn't cleared).
                """,
                recommendation: """
                1. Be careful not to paste it into a website or AI chat by mistake.
                2. When done, copy some other text to overwrite it.
                3. If you shared it by mistake, revoke and reissue the key in the service's console immediately.
                """
            ),
            LocalizedEntry(
                id: "alert_airgap_failed",
                title: "🚨 Automatic Network Cutoff Failed",
                summary: "An urgent warning shown when an emergency cutoff (ransomware, ARP spoofing, XProtect detection, ClickFix, and so on) was attempted but the pf full block couldn't be applied.",
                details: """
                • Cause: the privileged helper didn't respond (not approved, stopped, or timed out). Shown after 3 failed retries.
                • Current state: inbound traffic may be blocked by the Application Firewall, but outbound traffic has not been stopped.
                """,
                recommendation: """
                1. Turn Wi-Fi off or unplug the network cable immediately.
                2. Deal with the threat (quit processes, run scans).
                3. Then check the helper's status (faq_helper_troubleshooting).
                """
            ),
        ]
    }

    // MARK: - Settings

    private static func settingsEn() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "set_trusted_networks",
                title: "Registered Networks & Per-Network Protection Levels",
                summary: "Register the current network as Home, Work, Tethering, and so on, and set each network's protection level (Trusted / Balanced / Maximum Lockdown).",
                details: """
                • Register: Register Current Network → Register as “Home” (Trusted) / Register as ‘Work’ (Balanced) / Register as ‘Tethering’ (Balanced) / Register with Custom Name…. Networks are identified by the gateway's MAC address.
                • Change level: pick the network under "Current Network: …" or "Trusted Networks (n)" and choose 🟢 / 🟡 / 🔴.
                • Rename or remove: Rename…, Unregister, or Delete Registration.
                """,
                recommendation: "Home as 🟢 Trusted and work or tethering as 🟡 Balanced work well. Shared office Wi-Fi is safer left unregistered, under Maximum Lockdown."
            ),
            LocalizedEntry(
                id: "set_away_default_level",
                title: "Default Away Protection (Level for Unregistered Networks)",
                summary: "Chooses the protection level applied automatically when you join a network you haven't registered. Initially 🔴 Maximum Lockdown.",
                details: """
                • Setting: "Default Away Protection: …" in the menu, then 🟢 Trusted / 🟡 Balanced / 🔴 Maximum Lockdown.
                • Also affects features conditioned on being on an untrusted network, such as DNS Threat Protection (away-only), VPN auto-connect, gateway ARP/NDP pinning, and Bluetooth auto-off.
                """,
                recommendation: "If you don't use sharing services or AirDrop while away, leaving it at Maximum Lockdown is strongly recommended."
            ),
            LocalizedEntry(
                id: "set_manual_override",
                title: "Manual Override & Forgetting-to-Revert Protection",
                summary: "Temporarily set a protection level by hand for a chosen duration. It reverts to automatic detection when the time is up or the network changes, so you don't forget to restore protection.",
                details: """
                • Setting: Manual Override → a level (🟢 / 🟡 / 🔴) → a duration.
                • Durations: Until Disconnected (Recommended), For 1 Hour, For 4 Hours, Until Manually Cleared.
                • Clear: Manual Override → Revert to Auto-Detection, or "🔄 Clear Manual Override (Auto)" at the top of the menu.
                • Releasing air-gap containment also clears any manual override.
                """,
                recommendation: "When loosening protection temporarily for a presentation or development work, use Until Disconnected or For 1 Hour so you're never left unprotected away from home."
            ),
            LocalizedEntry(
                id: "set_pro_default_guards",
                title: "Guards Turned On Automatically with Pro, and Opt-In Guards",
                summary: "The first time a Pro license is activated, the main autonomous defense guards are turned on automatically. After that, the on/off choice you make for each guard is respected.",
                details: """
                • Turned on automatically (once, at first Pro activation): auto-block unknown listening ports, ransomware bait-file detection, auto-block on ARP spoofing, auto-disconnect on XProtect malware detection, automatic log audit, and periodic critical system file tampering monitoring. When the ARP and XProtect cutoffs are turned on, a one-time notice explains this.
                • On by default with Pro: Web & Mail Protection and auto-launch registration (LaunchAgent/Daemon) monitoring.
                • Off by default (opt-in): ClickFix auto-block, Docker risk detection, BadUSB physical port guard, USB storage auto-block, gateway ARP/NDP pinning, VPN tunnel, Bluetooth auto-off, and active vulnerability verification. The DNS Threat Protection provider is your choice.
                • On by default even in the free edition: clipboard protection (API keys and ClickFix commands).
                • Guards added in later versions get their own one-time default for existing Pro users. If the license lapses, Pro-only guards are turned off.
                """,
                recommendation: "After activating Pro, check the ✅ marks in the menu. Leave guards that don't fit your use (e.g. Docker if you don't use it) off, and turn on what you need (e.g. the VPN if you use public Wi-Fi often)."
            ),
            LocalizedEntry(
                id: "set_usb_whitelist",
                title: "USB / BadUSB Guard Settings (Keyboard Allowlist & Storage Permissions) (Pro)",
                summary: "Manage trusted keyboards and work USB storage devices in allowlists, and set storage permission to Read-only or Read & Write.",
                details: """
                • Open: Ports & Devices Monitor → "USB / BadUSB Guard Settings…".
                • Keyboards: added when you choose "Trust & Allow" in the approval window; remove them here.
                • Storage: added when you choose "Allow read-write" or "Allow as Read-Only" in the connection dialog; change permission or remove here. If you change a device that isn't connected, unplug and reconnect it for the change to apply.
                • The ClamAV scan on connection still runs for allowed devices before they are connected read-write.
                """,
                recommendation: "On Macs that handle sensitive data, registering storage as Read-only greatly reduces the risk of data leaks."
            ),
            LocalizedEntry(
                id: "set_watched_folders",
                title: "Web & Mail Protection Watched Folders (Pro)",
                summary: "Add, remove, or reset the folders monitored by download protection (FSEvents watching and automatic scans).",
                details: """
                • Default folders: `~/Downloads`, `~/Desktop`, `~/Documents`, and Mail's download folder.
                • Edit: "Web & Mail Protection (Auto-Scan Downloads) (Pro)" → "📁 Watched Folders" → "⚙️ Manage Watched Folders…".
                • Reset: "🔄 Reset to Default".
                • The recent scan history (up to 5 shown) and "Clear Scan History" are in the same menu.
                """,
                recommendation: "If you changed where your browser or chat apps save files, be sure to add that folder."
            ),
            LocalizedEntry(
                id: "set_dns_policy",
                title: "DNS Threat Protection Provider & Policy (Pro)",
                summary: "Choose the secure DNS provider that blocks malicious domains and when it applies (away only / always).",
                details: """
                • Setting: "DNS Threat Protection (Block Malware & C2) (Pro)" → "Provider: …" and "⚙️ Application Policy".
                • Providers: Quad9 (Auto-Block Malware & C2) / Cloudflare Security (1.1.1.2) / AdGuard DNS (Block Threats & Ads) / CleanBrowsing (Security Filter).
                • Policy: "Untrusted Wi-Fi Only (Recommended)" or "Always Active on All Networks (Including Trusted)". With away-only, the original DNS settings are restored on trusted networks.
                • The status item in the menu opens Network settings so you can confirm what's applied.
                """,
                recommendation: "For most people, Quad9 with the away-only policy is a good choice. Avoid the always-on policy where you need internal company DNS."
            ),
            LocalizedEntry(
                id: "set_link_guard_modes",
                title: "Link Guard Mode, Auto-Update, System Extension & Allowlist (Pro)",
                summary: "Configure Link Guard's mode, threat feed auto-update, system extension approval state, and how to allow sites blocked by mistake.",
                details: """
                • Mode: "Link Guard (phishing-connection detection) (Pro)" → "Off", "Warn only (never block)", or "Auto-block clearly phishing sites (recommended)". Warn mode only works when the system extension is active.
                • Auto-update: click "Auto-update: on (receive-only)" to turn it off. It still works with the bundled data and homograph detection. The feed version and domain count are shown in the menu.
                • Enforcement point: "Enforcement: system extension (DoH-aware)", "Enforcement: hosts fallback", "Enabling system extension…", or a system extension error. While approval is pending, "Approve system extension (open System Settings)…" appears.
                • Allow / block: "Allow once (5 min)" on a block notification allows the site for 5 minutes. Allow / Block choices in the warning panel are remembered.
                """,
                recommendation: "Approve the system extension and use auto-block with auto-update on for the most effective protection."
            ),
            LocalizedEntry(
                id: "set_vpn_backend",
                title: "VPN Tunnel Backend Settings (WireGuard / Tailscale) (Pro)",
                summary: "Choose the VPN tunnel backend, import a WireGuard config, pick a Tailscale exit node, and configure the kill switch.",
                details: """
                • Open: Ports & Devices Monitor → "VPN Tunnel (anti-MITM on untrusted networks) (Pro)" → Backend.
                • WireGuard: "Import WireGuard config (.conf)…" → "Auto-connect on untrusted networks". Also "Connect now", "Disconnect", and "Remove config". Status shows e.g. "🟢 Connected (last handshake Ns ago)", and the kill switch is always on. If `wireguard-tools` is missing, setup guidance appears.
                • Tailscale: pick an exit node under Exit Node ("(none — protection off)" disables it). Also "Refresh candidates" and "Refresh status". "Kill-switch: on (leak prevention)" is optional and off by default.
                • Example status lines: "⚪️ Standby (auto-connects on untrusted networks)", "🟡 Selected exit node is offline".
                """,
                recommendation: "If you already use Tailscale, choose Tailscale; otherwise your VPN provider's WireGuard config is the easiest option."
            ),
            LocalizedEntry(
                id: "set_language",
                title: "Display Language (App and MCP Answers)",
                summary: "RoamSwitch can be displayed in 10 languages (日本語, English, 简体中文, 繁體中文, 한국어, Deutsch, Français, Español, Italiano, Português). MCP server answers and this knowledge base use the same language.",
                details: """
                • Setting: choose under "Language / 言語" in the menu. "Follow System Settings" uses macOS's preferred language.
                • MCP: the MCP server reads the language chosen in the app. When following the system and the system language isn't supported, answers are in English.
                • The `get_app_help` tool takes a `language` argument to pick the answer language per call. Searches match keywords in any language.
                """,
                recommendation: "To talk to your AI assistant in a different language from the app, use the `language` argument of `get_app_help`."
            ),
        ]
    }

    // MARK: - Troubleshooting: setup

    private static func troubleshootingEnSetup() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "faq_free_vs_pro",
                title: "Free vs. Pro Lifetime",
                summary: "The free edition includes automatic network-based protection switching, the 18-item security audit, and a range of manual inspection tools, with no time limit. Pro unlocks automatic containment, real-time defenses, and patrol warnings.",
                details: """
                [Free]
                • Automatic 3-level PF packet filter switching per network, with sharing services and AirDrop stopped and restored automatically
                • Mac Security Audit (18 items), XProtect status, and file/app safety inspection
                • Lists of exposed ports and USB devices
                • Link Safety Audit, manual secret / API key leak audit, clipboard protection
                • Package CVE scan, active vulnerability verification, Mac Security Log Audit, notification history
                • Manual ClamAV scans and quarantine management
                • MCP server integration
                [Pro Lifetime (one-time ¥2,980 / $19.99, up to 2 Macs)]
                • Ransomware bait-file detection with air-gap, XProtect-linked auto-cutoff, ClickFix defense
                • Unknown listening port auto-block, dev server isolation
                • ARP spoofing auto-block, gateway ARP/NDP pinning, VPN tunnel (WireGuard / Tailscale), Evil Twin warnings
                • BadUSB keyboard guard, USB storage auto-block
                • Web & Mail Protection (auto-scan, quarantine, Pickle warnings), DNS Threat Protection, Link Guard
                • Auto-launch registration monitoring, Docker risk detection, critical file tampering monitor, automatic log audit
                • Bluetooth auto-off, real-time threat notifications, patrol warnings, definition updates and scheduled scans, CSV export of logs
                """,
                recommendation: "Choose Pro if you need automatic containment, real-time defense, and background monitoring."
            ),
            LocalizedEntry(
                id: "faq_homebrew_clamav",
                title: "Setting Up ClamAV (Virus Scanning) and Homebrew",
                summary: "Virus scanning uses the open-source ClamAV, installable with Homebrew. Without it, XProtect integration and all of RoamSwitch's own features still work.",
                details: """
                • Homebrew: the package manager for macOS (https://brew.sh/).
                • Steps:
                  1. Run Homebrew's official install command in Terminal (shown at https://brew.sh/).
                  2. Run `brew install clamav`. "📥 Install ClamAV via Homebrew…" in the menu also opens guidance.
                  3. Choose "🛡️ ClamAV (Free Antivirus)" → "🔄 Update Virus Database Now".
                • Enabled by ClamAV: quick scan (Downloads / Desktop), folder scan, scanning in Web & Mail Protection and USB storage, and the patrol's scheduled scan.
                • Without ClamAV: packet filtering, port monitoring, link analysis, the static signature check, and more still work.
                """,
                recommendation: "Install Homebrew and ClamAV if you want downloads and USB storage scanned automatically."
            ),
            LocalizedEntry(
                id: "faq_blueutil_setup",
                title: "Bluetooth Auto-Off (Pro) and blueutil Setup",
                summary: "Turning Bluetooth off automatically while away requires the open-source tool `blueutil`.",
                details: """
                • Background: macOS has no public API for apps to toggle Bluetooth power, so the CLI tool `blueutil` is used.
                • Steps:
                  1. Run `brew install blueutil` in Terminal (or use "📥 Install blueutil via Homebrew…" in the menu).
                  2. Enable Ports & Devices Monitor → "Auto-Off Bluetooth on Untrusted Networks (Pro)".
                • If not installed: nothing else is affected, and the menu shows "🔵 Bluetooth Auto-Off (Not Installed)".
                """,
                recommendation: "To avoid radio tracking and Bluetooth vulnerabilities on public Wi-Fi, run `brew install blueutil` and enable it."
            ),
            LocalizedEntry(
                id: "faq_helper_troubleshooting",
                title: "What to Do When “⚠️ Helper Not Connected” Appears",
                summary: "Recovery steps when RoamSwitch can't communicate with the privileged helper tool (RoamSwitchHelper).",
                details: """
                1. Choose "⚠️ Approve the helper…" in the menu and follow the steps shown.
                2. Open System Settings → General → Login Items & Extensions and make sure RoamSwitchHelper is on under Allow in the Background.
                3. Make sure RoamSwitch is in the Applications folder (faq_install_location).
                4. Press "Retry helper registration" in the onboarding window.
                5. If it still fails, run `sudo killall RoamSwitchHelper` in Terminal to restart the helper (launchd relaunches it automatically), then relaunch RoamSwitch.
                """,
                recommendation: "If the helper stops responding right after a macOS update, first check the Login Items toggle, then try `sudo killall RoamSwitchHelper`."
            ),
            LocalizedEntry(
                id: "faq_install_location",
                title: "App Location (Launched from Outside the Applications Folder)",
                summary: "macOS won't register the privileged helper for an app outside the Applications folder, so RoamSwitch must be placed in `/Applications` or `~/Applications` and launched from there.",
                details: """
                • Locations that can't register: Downloads or Desktop, running from a still-mounted disk image (.dmg), or Gatekeeper App Translocation having moved the app to a temporary read-only location.
                • Guidance: onboarding checks the location at launch and offers "Move to Applications & relaunch" or "Open Applications in Finder".
                • After moving: press "Check again" or relaunch, then approve the helper.
                """,
                recommendation: "Drag RoamSwitch from the disk image into the Applications folder and launch it from there."
            ),
            LocalizedEntry(
                id: "faq_system_extension_approval",
                title: "Approving Link Guard's System Extension",
                summary: "For Link Guard to work best (DoH-aware, warn mode), the content-filter system extension must be approved. Until then it uses the /etc/hosts fallback.",
                details: """
                • Steps: "Link Guard (phishing-connection detection) (Pro)" → "Approve system extension (open System Settings)…" → System Settings → General → Login Items & Extensions, then allow RoamSwitch's network extension.
                • After approval: the menu shows "Enforcement: system extension (DoH-aware)".
                • If a system extension error is shown: make sure the app is in the Applications folder, then re-select a Link Guard mode to retry.
                • This method needs no App Store review or entitlement application (Developer ID signed and notarized).
                """,
                recommendation: "Approve the system extension so protection holds even when your browser uses DNS over HTTPS."
            ),
            LocalizedEntry(
                id: "faq_mcp_setup",
                title: "Setting Up the MCP Server (Claude Desktop, Claude Code, and Others)",
                summary: "How to register RoamSwitch's bundled MCP server with an MCP-capable AI client.",
                details: """
                • Binary path: `/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`
                • Claude Desktop: add the binary path as `command` under `mcpServers` in `~/Library/Application Support/Claude/claude_desktop_config.json`.
                • Claude Code: `claude mcp add roamswitch /Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`
                • Other clients (Codex CLI and more): https://lafine.net/mcp-setup.html
                • Answer language: follows the app's "Language / 言語" setting. `get_app_help` accepts a `language` argument per call.
                • Communication is local stdio only, with nothing sent externally (only `run_active_vuln_scan` sends non-destructive probes to 127.0.0.1).
                """,
                recommendation: "Once registered, ask your AI something like “Check my Mac's security state with RoamSwitch” and it will explain the audit results."
            ),
        ]
    }

    // MARK: - Troubleshooting: operation

    private static func troubleshootingEnOperation() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "faq_network_cut_off",
                title: "The Internet Suddenly Stopped Working (Air-Gap Containment / Protection Level)",
                summary: "RoamSwitch's emergency air-gap or Maximum Lockdown may be stopping traffic. How to find the cause and release it.",
                details: """
                • Check: look for an emergency window, and check notification history for alerts such as CRITICAL AUTO-DEFENSE, XProtect, ARP spoofing, or suspicious command execution. The Wi-Fi radio may also have been turned off.
                • Release: use the release button in the emergency window or the notification. Networking and the Wi-Fi radio come back.
                • Auto-restore: even without releasing, the helper's failsafe restores networking within 10 minutes. No manual steps are needed after quitting, a crash, or rebooting.
                • Right after boot: traffic may be restricted by the boot gate for up to 90 seconds.
                • Other causes: Maximum Lockdown blocks inbound but doesn't prevent normal outbound use such as web browsing. Also check the VPN kill switch (while the tunnel is down), DNS Threat Protection's resolver, and Link Guard blocks.
                """,
                recommendation: "When containment fires, read the triggering notification and release once you've confirmed it's safe. If a guard triggers falsely often, you can turn it off individually from the menu."
            ),
            LocalizedEntry(
                id: "faq_quarantine_false_positive",
                title: "Restoring a Download Quarantined by Mistake",
                summary: "How to restore your own script or development binary that was quarantined as a false positive, and exclude it from scans.",
                details: """
                1. Open Malware Protection → ClamAV → "📦 Manage Quarantined Files…".
                2. Select the file among the quarantined files (original path, threat name, and quarantine time are shown).
                3. For a certain false positive, press "Exclude & Restore": it goes back to its original location and that path is excluded from future scans. To restore just once, press "Restore".
                4. To undo an exclusion, press "Remove Exclusion" in the excluded paths list in the same window.
                5. To stop watching a whole folder, adjust "⚙️ Manage Watched Folders…" under Web & Mail Protection.
                """,
                recommendation: "If you can't be sure a file is safe, don't restore it; choose Delete Permanently."
            ),
            LocalizedEntry(
                id: "faq_eicar_test",
                title: "I Placed an EICAR Test File but Got No Notification",
                summary: "This is by design. The EICAR test signature is a harmless test, so no banner is shown and nothing is quarantined. The detection is recorded in the notification history.",
                details: """
                • How to confirm: check Mac Security Audit → "🔔 Notification History…" for "🧪 EICAR test signature detected (harmless)".
                • The file: stays where it is.
                • To test the real alert path: use the simulations at the bottom of Malware Protection (ransomware defense, malware-detection air-gap, Docker risk detection).
                """,
                recommendation: "Delete the EICAR file once you're done testing."
            ),
            LocalizedEntry(
                id: "faq_dev_server_blocked",
                title: "My Dev Server or LAN Receiver App Can't Be Reached from Other Devices",
                summary: "The unknown listening port auto-block may be blocking a program that just started exposing a port. It remains reachable from the Mac itself.",
                details: """
                • Check: look in notification history for "🚨 Unknown listening port auto-blocked".
                • Allow: use the notification's "Allow" button, or Exposed Ports → the port → the port audit screen. Allowing applies permanently, per executable.
                • Versus manual isolation: a port you isolated yourself with "Isolate Port" is restored with "Unisolate" in the port audit screen.
                • Protection level: on a Maximum Lockdown network the firewall blocks inbound connections entirely. To allow access from the LAN, register that network and set it to Balanced or Trusted.
                """,
                recommendation: "Allow LAN receiver apps you use regularly, such as LocalSend or Syncthing, once and they won't be blocked again."
            ),
            LocalizedEntry(
                id: "faq_link_guard_false_block",
                title: "Link Guard Blocks a Legitimate Site / Keeps a Connection on Hold",
                summary: "What to do when Link Guard blocks a site by mistake or holds it in warn mode.",
                details: """
                • Allow temporarily: "Allow once (5 min)" on the block notification.
                • Allow permanently: choosing "Allow" in the warning panel is remembered.
                • A held connection got blocked on its own: warn mode blocks if there's no answer within about 8 seconds (fail-closed). That outcome isn't cached, so reloading the page asks again.
                • Can't see the notification: with the banner notification style the buttons can be hidden, so a front-most panel is shown too. During Focus modes, check notification history.
                • Disable temporarily: switch the mode to "Warn only (never block)" or "Off".
                """,
                recommendation: "If a work tool is blocked repeatedly, check the domain for typos or look-alikes before allowing it."
            ),
            LocalizedEntry(
                id: "faq_keyboard_blocked",
                title: "My External Keyboard Doesn't Type (BadUSB Guard)",
                summary: "The BadUSB physical port guard is blocking input from a keyboard that isn't on the allowlist until you approve it.",
                details: """
                • Approve: click "Trust & Allow" in the "⚠️ Unknown USB Device / Keyboard Detected" window (use the built-in keyboard or trackpad).
                • Can't find the window: unplug and reconnect the device to show it again.
                • Docks and KVM switches: devices with a built-in keyboard function are covered too. Allow them if they're yours.
                • Accessibility permission: the fallback block used when the device can't be seized relies on the Accessibility permission.
                • Revoke: remove it in "USB / BadUSB Guard Settings…".
                """,
                recommendation: "Don't allow a device that triggered the scripted-input warning; unplug it."
            ),
            LocalizedEntry(
                id: "faq_vpn_troubleshooting",
                title: "The VPN Tunnel Won't Connect / No Traffic Gets Through",
                summary: "What to check when the WireGuard or Tailscale backend isn't working.",
                details: """
                • WireGuard: confirm `brew install wireguard-tools` is installed and a `.conf` is imported. If the status shows "🟡 Stale (last handshake …)", check the VPN server and the config's keys and endpoint. The kill switch is on, so nothing gets through until the tunnel is established.
                • Tailscale: confirm the CLI is installed and logged in (otherwise the menu shows "Log in to Tailscale first") and an exit node is selected. If the selected exit node is offline, choose another.
                • Tailscale from the App Store: the exit node can't be set from outside the app, so choose it in the Tailscale app.
                • Tailscale kill switch: on some networks it interferes with Tailscale's own connectivity; turn it off if you can't connect.
                • Disconnecting automatically on trusted networks is expected behavior.
                """,
                recommendation: "Start with the status line in the menu: the handshake for WireGuard, the exit node state for Tailscale."
            ),
            LocalizedEntry(
                id: "faq_log_audit_repeated_alerts",
                title: "Log Audit Notifications Keep Coming",
                summary: "The automatic log audit learns this Mac's normal log behavior as it runs. Alerts increase right after setup or a major update and taper off naturally as learning progresses.",
                details: """
                • New patterns: once reported, a pattern becomes known and isn't re-notified for the same content.
                • Frequency spikes: each pattern's learning completes after 3 observations; after that, normal volume doesn't alert. While the notification shows something like "frequency baseline still learning: 2/3 observations", it's still learning.
                • Common causes: macOS or app updates, connecting new devices, temporary heavy load.
                • To stop it: turn off "Automatic Log Audit (learns new patterns & frequency anomalies on a schedule) (Pro)" in the menu (the manual log audit remains available).
                """,
                recommendation: "Unless alerts include unfamiliar app names, IP addresses, or sudo failures, it's fine to wait a while."
            ),
            LocalizedEntry(
                id: "faq_zero_telemetry",
                title: "Zero Telemetry Privacy Design",
                summary: "RoamSwitch and its MCP server never send audit results, URLs, port information, logs, or file contents to external servers. The only network traffic is the explicit exceptions below.",
                details: """
                • Fully local: the security audit, port monitoring, link analysis, secret audit, log audit, virus scanning, and MCP communication all stay on the device.
                • Exceptions:
                  - License activation and deactivation (only when you act) and opening the purchase page
                  - App update checks (Sparkle)
                  - ClamAV definition updates (`freshclam`)
                  - Daily downloads of the Link Guard threat feed, package CVE maps, and vulnerability CVE maps (receive-only, signature-verified, no identifiers sent; Link Guard auto-update can be turned off)
                  - Normal traffic to the VPN and secure DNS providers you configure
                  - Active vulnerability verification's non-destructive probes to 127.0.0.1 (this Mac itself)
                • There is no telemetry or usage collection anywhere in the code. Even the helper-approval reminder works from an on-device count only.
                """,
                recommendation: "It's safe to use in highly confidential business environments and personal development setups without worrying about data leaks."
            ),
        ]
    }
}
