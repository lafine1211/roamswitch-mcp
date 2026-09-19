// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.44 (build 101).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

// Traditional Chinese (zh-Hant, Taiwan usage) content for `RoamSwitchKnowledgeBase`.
// Translated from the English source (`RoamSwitchKnowledgeBaseContent_en.swift`).
// Every entry id here must also exist in every other
// `RoamSwitchKnowledgeBaseContent_<lang>.swift` file.
extension RoamSwitchKnowledgeBase {
    static func labelsZhHant() -> MarkdownLabels {
        return MarkdownLabels(
            featuresTitle: "RoamSwitch 功能規格與內部架構指南",
            featuresIntro: "完整說明 RoamSwitch 每一項安全功能的運作方式、預設值與限制。",
            alertsTitle: "RoamSwitch 通知與警告訊息處理指南",
            alertsIntro: "RoamSwitch 顯示的每一種通知橫幅、警告與緊急視窗，包含發生原因、自動採取的防禦措施，以及建議的逐步處理方式。",
            settingsTitle: "RoamSwitch 設定與操作指南",
            settingsIntro: "RoamSwitch 每一項設定、開關、允許清單與政策的逐步設定說明。",
            troubleshootingTitle: "RoamSwitch 疑難排解與常見問題",
            troubleshootingIntro: "關於常見問題、權限與批准、Homebrew / ClamAV / blueutil 安裝、誤判處理，以及隱私設計的權威解答。",
            summary: "概要",
            overview: "概覽",
            detailsHeading: "詳細資訊與原因",
            adviceHeading: "處理方式",
            recommendation: "建議",
            bestPractice: "最佳做法",
            advice: "建議"
        )
    }

    static func contentZhHant() -> [LocalizedEntry] {
        var list: [LocalizedEntry] = []
        list.append(contentsOf: featuresZhHantNetwork())
        list.append(contentsOf: featuresZhHantMalware())
        list.append(contentsOf: featuresZhHantAudit())
        list.append(contentsOf: alertsZhHantNetwork())
        list.append(contentsOf: alertsZhHantMalware())
        list.append(contentsOf: settingsZhHant())
        list.append(contentsOf: troubleshootingZhHantSetup())
        list.append(contentsOf: troubleshootingZhHantOperation())
        return list
    }

    // MARK: - Features: network & devices

    private static func featuresZhHantNetwork() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_network_autoswitch",
                title: "自動網路安全切換 & PF 封包過濾器（3 個等級）",
                summary: "將目前網路的閘道 MAC 位址與您已註冊的網路比對，並自動套用該網路的保護等級。未註冊的網路則套用「外出預設保護」等級（初始值為最大鎖定）。免費版即可使用。",
                details: """
                • 🟢 信任（開放－解除保護）：例如住家。防火牆關閉；允許共享服務（SSH / SMB / 螢幕共享）與 AirDrop。
                • 🟡 平衡（防火牆與隱形模式）：例如公司或行動熱點分享。PF 封包過濾器與隱形模式會阻擋外部探測，同時保留共享服務。
                • 🔴 最大鎖定（關閉共享與 AirDrop）：咖啡廳、公共 Wi-Fi、未註冊的網路。封鎖所有連入連線、停止共享常駐程式、停用 AirDrop。
                • 判斷方式：網路變更時會讀取閘道的 MAC 位址並與已註冊網路比對。不會改變閘道的路徑事件（DHCP 更新、Wi-Fi 漫遊）不會觸發完整重新判斷。
                • 內部運作：特權輔助工具 `RoamSwitchHelper`（透過 XPC）管理專用的 `pfctl` 錨點，封包會在核心層級被丟棄。
                • 手動覆蓋：可在「手動覆蓋」中為每個等級選擇「直到網路中斷（推薦）」「僅 1 小時」「僅 4 小時」或「直到手動解除」（參見 set_manual_override）。
                """,
                recommendation: "透過「已註冊網路」把住家與其他安全的辦公室註冊起來，其餘場所讓最大鎖定自動套用即可。"
            ),
            LocalizedEntry(
                id: "feat_network_history_guard",
                title: "網路歷史學習 & 邪惡雙胞胎（仿冒 Wi-Fi）偵測 (Pro)",
                summary: "僅在這台 Mac 上學習每個 Wi-Fi SSID 曾使用過哪些閘道 MAC 位址，當您加入一個名稱與過去使用過的網路極為相似的未知 SSID 時，會警告可能是邪惡雙胞胎（假冒基地台）。",
                details: """
                • 學習內容：針對每個 SSID 記錄觀察到的閘道 MAC 位址（每個 SSID 最多 8 組，可支援 Mesh Wi-Fi），儲存於 `~/Library/Application Support/RoamSwitch/network_history.json`。最多保留 200 個 SSID，最舊的優先淘汰。所有資料都不會傳出裝置。
                • 相似度判斷：使用不分大小寫的編輯距離（Levenshtein distance）。少於 6 個字元的名稱不列入判斷，且允許的距離會隨長度緩慢增加（1 到 2 個字元），因此像「ASUS」或「TP-Link_5G」這類常見預設 SSID 的偶然重複永遠不會觸發警告。
                • 誤判控制：同一個閘道硬體廣播的第二個 SSID（訪客網路、改名的路由器）不會被標記。已知 SSID 搭配新的閘道 MAC（路由器更換）只會被記錄，不會單獨發出警告。
                • 偵測到 ARP 詐騙期間會跳過觀察，避免將攻擊者的 MAC 學習為合法紀錄。
                • 此警告為即時通知，於 Pro 版發送。已學習的歷史記錄可透過 MCP 工具 `get_network_history` 取得。
                """,
                recommendation: "若收到此警告，請不要在該 Wi-Fi 上輸入帳密，並確認真正的網路名稱與所在位置。VPN 隧道（feat_vpn_tunnel）是最可靠的因應方式。"
            ),
            LocalizedEntry(
                id: "feat_arp_spoof_guard",
                title: "ARP 詐騙（網路冒充）偵測 & 自動封鎖 (Pro)",
                summary: "偵測同一網路內攻擊者冒充路由器以竊聽或竄改流量的 ARP 詐騙（中間人攻擊）。在最大鎖定的網路上會立即斷網，其他等級則僅發出通知，交由您決定。",
                details: """
                • 偵測方式：預設閘道的 IP 位址不變，但其 MAC 位址突然改變。除了網路變更事件外，也有專門的 15 秒輪詢，可捕捉在連線期間才開始的攻擊。
                • 回應方式：在最大鎖定的網路上，會立即進行氣隙圍堵（feat_airgap_containment）。在信任或平衡等級的網路上僅發出通知，您也可以從「連接埠與裝置監控」選擇「偵測到 ARP 詐騙 — 立即全部斷網」來手動觸發圍堵。這樣可避免路由器重開機或 Mesh 漫遊造成誤觸發，也能防止單一偽造 ARP 封包被利用成自我斷網的攻擊手段。
                • 預設值：首次啟用 Pro 授權時，選單項目「偵測到 ARP 詐騙（網路冒充）時自動封鎖 (Pro)」會自動開啟（set_pro_default_guards）。
                • 定位：這是事後的因應措施。事先預防則由閘道 ARP/NDP 固定（feat_gateway_arp_lock）與 VPN 隧道（feat_vpn_tunnel）負責。
                • 事件會以 MITRE ATT&CK T1557 記錄在事件時間軸（feat_containment_incident_timeline）中。
                """,
                recommendation: "請保持開啟。若需要更強的中間人攻擊防護，可加開 VPN 隧道；若想在不增加基礎設施的情況下事先預防，可加開閘道 ARP/NDP 固定。"
            ),
            LocalizedEntry(
                id: "feat_gateway_arp_lock",
                title: "閘道 ARP/NDP 固定（預防性）(Pro)",
                summary: "加入不受信任的網路時，將閘道、IPv6 路由器與同一連結上任何 DNS 伺服器的 MAC 位址固定為靜態鄰居快取項目，在 ARP/NDP 詐騙的中間人攻擊發生前就先行防範。預設為關閉。",
                details: """
                • 啟用方式：「連接埠與裝置監控」→「在不受信任的網路上固定閘道 ARP/NDP（預防）(Pro)」。
                • 運作方式：連線時讀取目前的 MAC 位址，並由輔助工具透過 `arp -s` / `ndp -s` 將其固定為永久項目。之後核心會忽略針對這些 IP 的偽造 ARP 回覆與鄰居通告。
                • 範圍：僅限上述三種項目。不會在信任（開放）網路上固定，因此住家路由器重開機不會中斷連線。每次網路變更時都會清除並重新固定。
                • 限制（首次使用即信任）：信任第一次觀察到的 MAC，因此若攻擊者在您連線前就已存在，其 MAC 也可能被固定下來。若無法接受此前提，請改用 VPN 隧道。
                • 會反映在「Mac 安全稽核」的「閘道 ARP 固定（預防性中間人攻擊防護）」項目中。
                """,
                recommendation: "在難以使用 VPN 時，這是一項輕量的中間人攻擊防護。也可以與 VPN 隧道併用（VPN 是主要防線，這是輔助措施）。"
            ),
            LocalizedEntry(
                id: "feat_vpn_tunnel",
                title: "VPN 隧道（WireGuard / Tailscale，含終止開關）(Pro)",
                summary: "在不受信任的網路上自動建立加密隧道，讓中間人攻擊只能看到密文。可選擇 WireGuard（設定檔）或 Tailscale（出口節點）作為後端。不依賴 L2（ARP/NDP）的完整性，是主要的反中間人攻擊防線。不需要 Network Extension 授權。",
                details: """
                • 後端選擇：「連接埠與裝置監控」→「VPN 隧道（不受信任網路的中間人攻擊防護）(Pro)」→「後端」，選擇 WireGuard 或 Tailscale。只有選定的後端會運作。
                • WireGuard：需要 Homebrew 的 `wireguard-tools`（`brew install wireguard-tools`）。以「匯入 WireGuard 設定 (.conf)…」載入設定檔。設定檔須由您自行準備（Mullvad、IVPN、Proton VPN、自架伺服器、公司提供等）；RoamSwitch 不提供 VPN 伺服器。
                • WireGuard 終止開關：pf 執行「block drop all」，僅放行 lo、隧道介面、與端點的 UDP 交握、DHCP 與 ICMP。隧道中斷時完全不會外洩明文。
                • Tailscale：適合已在使用 Tailscale 的使用者。RoamSwitch 不會安裝或登入，只會讀取 `tailscale status` 並執行 `tailscale set --exit-node=<節點>`。必須選擇出口節點（所有流量都會經過該節點）。若所選出口節點離線，會顯示在狀態列中。
                • 建議使用 Tailscale CLI（獨立版）：`brew install tailscale` → `sudo tailscaled install-system-daemon` → `sudo tailscale up`。App Store（GUI）版本無法從應用程式外部以 `tailscale set` 控制，因此請在 Tailscale App 內選擇出口節點，RoamSwitch 僅負責顯示狀態與終止開關。
                • Tailscale 終止開關（預設關閉，須自行開啟）：pf 僅放行 lo、Tailscale 的 utun、CGNAT 100.64.0.0/10、DNS、STUN 3478、41641、DERP tcp 443、DHCP 與 ICMP。比 WireGuard 寬鬆（屬於「不易外洩」而非完全防洩），且在某些環境下可能干擾 Tailscale 自身的連線，因此設為選用。
                • 自動化：在不受信任的網路上建立隧道／出口節點，在受信任的網路上中斷。授權過期時，隧道與終止開關會自動解除。
                """,
                recommendation: "若經常使用公共 Wi-Fi，這是最有效的防護。已使用 Tailscale 的使用者：安裝 CLI 並選擇 Tailscale 後端加上出口節點。否則以 `brew install wireguard-tools` 搭配 VPN 供應商的 `.conf` 檔是最簡便的方式。"
            ),
            LocalizedEntry(
                id: "feat_airgap_containment",
                title: "緊急氣隙圍堵（全面斷網、關閉 Wi-Fi 無線電、自動復原保護機制）",
                summary: "偵測到重大威脅（勒索軟體、XProtect 惡意軟體判定、ARP 詐騙、ClickFix）時使用的共用緊急圍堵機制，會封鎖所有連入與連出流量。即使發生當機或重新開機，網路最多也會在 10 分鐘內自動恢復。",
                details: """
                • 運作方式：特權輔助工具載入 pf 的「block drop all」（迴路介面除外）並讀回確認。連出流量也會被切斷，可阻止金鑰或資料外洩至 C2 伺服器。若套用失敗，最多重試 3 次（每次逾時 8 秒）；若仍失敗，會顯示「自動斷網失敗」並要求您手動中斷連線。系統絕不會宣稱已隔離但實際上沒有生效。
                • 關閉 Wi-Fi 無線電：pf 只能丟棄封包，介面卡本身仍會保持關聯，因此 ARP 詐騙、勒索軟體與 XProtect 圍堵也會透過 `networksetup` 關閉 Wi-Fi 無線電本身（預設開啟；內部設定 `RoamSwitch.AirGapAutoWiFiKillEnabled`）。ClickFix 圍堵則不會關閉無線電。
                • 解除：從緊急視窗或通知解除後，會移除 pf 封鎖並重新開啟 Wi-Fi。
                • 保護機制：若應用程式當機或沒有人解除，輔助工具端的計時器會在 10 分鐘後強制解除氣隙並恢復 Wi-Fi 無線電。重新啟動應用程式或重新開機 Mac 也不需要手動操作即可恢復。
                • 開機閘：開機後、應用程式尚未套用政策之前，會生效一道預設拒絕的 pf 開機閘，最多 90 秒後自動解除。
                """,
                recommendation: "圍堵啟動時，請先閱讀通知內容，結束可疑的應用程式並執行掃描，再進行解除。若確定是誤判，可立即解除。"
            ),
            LocalizedEntry(
                id: "feat_port_anomaly_guard",
                title: "自動封鎖未知監聽連接埠 & 開發伺服器隔離 (Pro)",
                summary: "監控所有正在監聽的 TCP 連接埠，當一個先前未曾對外開放的執行檔突然開始在 0.0.0.0 上監聽時，會封鎖該連接埠來自區域網路的存取。開發伺服器與本機 AI 伺服器也能一鍵隔離至僅限 127.0.0.1。",
                details: """
                • 監控方式：每 20 秒掃描一次監聽中的連接埠。判斷依據為執行檔路徑，因此已知的應用程式只是換了連接埠並不會觸發。啟用後的當下狀態會被記錄為基準線。
                • 自動封鎖：當未知的執行檔開始對外開放連接埠時，pf 只會封鎖外部存取（Mac 本機與 localhost 仍可使用）。此機制可在不知道惡意軟體家族的情況下，捕捉零時差漏洞植入的後門。
                • 排除項目：位於 `/System/Library` 或 `/usr/libexec` 下、由 Apple 簽署的系統常駐程式（例如 rapportd，為 Handoff、AirPlay、AirDrop 所需）。位於 `/usr/bin` 下的通用工具，例如 `/usr/bin/python3` 或 `/usr/bin/nc`，仍會被標記。
                • 高風險服務：辨識常見的預設無驗證服務，例如 Redis（6379）、MongoDB（27017）、Memcached（11211）、Elasticsearch（9200）、VNC（5900），以及本機 AI 伺服器如 Ollama（11434）、LM Studio（1234）、Gradio（7860）、vLLM（8000）。
                • 開發伺服器隔離：從「外部公開連接埠」開啟該連接埠並選擇「執行外部隔離」，將其限制為僅限 127.0.0.1（Pro）。
                • 誤判處理：可用通知中的「允許」按鈕，或從連接埠稽核畫面永久允許。關閉此防護（或授權過期）會釋放所有由其建立的封鎖。
                • 預設值：首次啟用 Pro 時自動開啟。事件記錄可透過 MCP 工具 `get_port_anomaly_incidents` 取得。
                """,
                recommendation: "請將開發伺服器與本機 LLM 綁定至 `127.0.0.1`（例如 `OLLAMA_HOST=127.0.0.1 ollama serve`、`npm run dev -- -H 127.0.0.1`）。"
            ),
            LocalizedEntry(
                id: "feat_active_vuln_scan",
                title: "實證型漏洞驗證 — 預設關閉",
                summary: "針對這台 Mac 自身（127.0.0.1）偵測到的服務，以最小限度的唯讀探測確認它們是否真的能在未驗證的情況下回應。預設關閉，需明確自行開啟並在每次執行時再次確認。",
                details: """
                • 啟用方式：「連接埠與裝置監控」→「實證型漏洞驗證（主動可達性確認）」。這只會解鎖連接埠稽核畫面中的「執行實證驗證」按鈕，本身不會傳送任何內容，每次執行前都會先詢問「是否傳送驗證請求？」。
                • 僅限 127.0.0.1：絕不會傳送至其他主機。
                • 無驗證存取：對 Redis（PING）、Memcached（stats）、MongoDB（listDatabases）進行單次、短逾時、非破壞性的探測。
                • 通用開發伺服器：檢查 CORS 設定錯誤（反射 Origin 並允許憑證）、路徑穿越與開放重新導向。
                • 已知 CVE 版本比對：對於無需驗證即可存取的 Redis / Memcached，會以非破壞性查詢讀取版本，並與已知 CVE 版本範圍比對。不會傳送任何攻擊酬載。
                • 也可透過 MCP 工具 `run_active_vuln_scan` 使用（是唯一會傳送網路流量的工具，且僅傳送至本機）。
                """,
                recommendation: "只有在想確認自己 Mac 上執行的 Redis、Docker、本機 LLM 等是否真的能在未驗證下被存取時，才需要開啟此功能。"
            ),
            LocalizedEntry(
                id: "feat_nmap_nse",
                title: "nmap NSE 補充掃描（實證型弱點驗證的附加層）",
                summary: "僅在「實證型弱點驗證」同時啟用時，使用系統已安裝的 nmap 對暴露連接埠額外執行「safe」類別的 NSE 指令碼，以補充本產品自身偵測所不具備的通訊協定涵蓋範圍（SSH 主機金鑰、SMTP 回應等）。結果是 nmap 自身的判定，本產品不做獨立驗證。",
                details: """
                • 自動執行：只要「實證型弱點驗證（主動可達性驗證）」已啟用即會自動執行，沒有獨立的開關設定。nmap 不會被自動安裝——僅當系統中已安裝（例如透過 Homebrew）時才會生效，否則不執行任何操作。
                • 指令碼選擇：`safe and not broadcast and not external`。僅靠「safe」類別本身並不足夠——`broadcast` 類指令碼會以多播/廣播方式查詢整個區域網路，而不僅是目標主機；`external` 類指令碼（如 `vulners.nse`）會將偵測到的服務/版本實際傳送給 vulners.com 等第三方。兩者都違背了本產品「僅存取 127.0.0.1、絕不接觸任何其他主機或外部伺服器」的設計原則，因此被排除。
                • 逾時：每個指令碼 15 秒（`--script-timeout 15s`）。部分「safe」指令碼針對非標準 HTTP API 可能無限期執行，若無此限制會導致其他連接埠的結果遺失。
                • 範圍：與實證型弱點驗證自身相同的、已確認開放的連接埠。
                """,
                recommendation: "請將 nmap 的發現僅作為參考資訊，核實內容後如確實相關再採取行動。"
            ),
            LocalizedEntry(
                id: "feat_usb_keyboard_guard",
                title: "非法 USB / BadUSB 實體連接埠防護（鍵盤批准 & 按鍵節奏分析）(Pro)",
                summary: "當未知的 USB 鍵盤或改造過的傳輸線（Rubber Ducky、O.MG Cable、Flipper Zero 等）被接上時，會封鎖該裝置的按鍵輸入直到您核准為止，藉此防止自動化指令注入。同時也會分析按鍵間隔，若看起來像是腳本輸入就會發出警告。",
                details: """
                • 偵測方式：IOHIDManager 即時偵測新接上的鍵盤。內建鍵盤會自動被信任。
                • 封鎖方式：未核准的裝置會被獨佔佔用（IOHIDDevice seize），因此只有該裝置的按鍵輸入無法送達系統；其他鍵盤仍可正常使用。只有在無法佔用裝置時，才會退回使用需要輔助使用權限的 CGEventTap 封鎖。
                • 核准方式：最前端的視窗會提供「信任並允許」或「拒絕並保持攔截」。已允許的鍵盤會加入允許清單。
                • 按鍵節奏分析：封鎖期間仍會測量該裝置的按鍵間隔。累積至少 5 次間隔後，若平均值為 12 毫秒以下，或平均值為 45 毫秒以下且非常均勻（變異係數 0.35 以下），就會發出「呈現腳本輸入跡象」的警告。這捕捉的是人類無法做到的機械式速度與規律性，僅作為輔助證據，不會改變封鎖的判斷。
                • 預設關閉。可從「連接埠與裝置監控」→「非法 USB / BadUSB 實體連接埠防護 (Pro)」啟用；在「USB / BadUSB 防護設定…」中管理允許清單。
                """,
                recommendation: "若使用外接鍵盤，請只以「信任並允許」核准您自己接上的裝置。任何觸發腳本輸入警告的裝置，都應一律拒絕並拔除。"
            ),
            LocalizedEntry(
                id: "feat_usb_storage_guard",
                title: "自動封鎖非法 USB 儲存裝置 & ClamAV 自動掃描 (Pro)",
                summary: "不在允許清單中的 USB 隨身碟或外接硬碟，會先以唯讀方式掛載，並詢問您該如何處理。已允許的裝置在以設定的權限連接前，也會先以 ClamAV 掃描。",
                details: """
                • 監控方式：DiskArbitration 會立即捕捉外接／可移除磁碟區的掛載。
                • 未註冊的裝置：為安全起見會重新以唯讀方式掛載，並顯示對話框提供「允許讀寫」「以唯讀方式允許」或「退出」。選擇退出會立即卸載並退出。
                • 已允許的裝置：會自動套用允許清單中的權限（唯讀／讀寫），並在升級為可讀寫之前先執行 ClamAV 掃描。
                • 感染：若發現惡意軟體，磁碟區會自動退出並發出緊急警示。
                • 重新格式化的磁碟機：若磁碟區 UUID 改變，但包含序號在內的硬體識別碼相符，則允許狀態會延續（僅供應商／產品編號一致並不算是相符）。
                • 涵蓋範圍：涵蓋透過儲存裝置進行的資料外洩與惡意酬載。偽裝成鍵盤的 HID 型 BadUSB 裝置則由 feat_usb_keyboard_guard 負責。
                """,
                recommendation: "只將工作用的 USB 隨身碟加入允許清單，處理敏感資料的 Mac 建議優先使用唯讀權限。"
            ),
            LocalizedEntry(
                id: "feat_bluetooth_guard",
                title: "在不受信任的網路自動關閉 Bluetooth (Pro)",
                summary: "當您加入套用最大鎖定的外出網路時，會自動關閉 Bluetooth，以降低遭受未經同意的配對與 BLE 攻擊的曝險，回到受信任的網路後會自動恢復。",
                details: """
                • 工具依賴：macOS 沒有讓應用程式切換 Bluetooth 電源的公開 API，因此 RoamSwitch 使用開源的 Homebrew 工具 `blueutil`（`brew install blueutil`）。若尚未安裝，選單會顯示安裝指引。
                • 恢復方式：只有在 RoamSwitch 關閉 Bluetooth 之前它原本是開啟的，才會在回到受信任網路時重新開啟；您在外出時自行做出的選擇不會被覆蓋。
                • 預設關閉：許多人在咖啡廳等場所會使用 AirPods 等裝置，若靜默切斷音訊將造成困擾，因此為自行開啟選項。
                """,
                recommendation: "若外出時不使用 Bluetooth 配件，建議開啟此功能以避免電波掃描與未經同意的配對。"
            ),
        ]
    }

    // MARK: - Features: malware & web protection

    private static func featuresZhHantMalware() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_webmail_download_guard",
                title: "網頁與郵件保護（下載檔案自動掃描與隔離）(Pro)",
                summary: "使用 FSEvents 監控從瀏覽器、Mail、Slack、Discord 等下載的檔案，以靜態特徵碼檢查與 ClamAV 進行掃描，並將威脅移至隔離區。",
                details: """
                • 監控資料夾：預設為 `~/Downloads`、`~/Desktop`、`~/Documents` 與 Mail 的下載資料夾。可透過「⚙️ 管理監控資料夾…」新增或移除。
                • 下載來源：依 macOS 附加的 `com.apple.quarantine` 擴充屬性判斷。
                • 雙層檢查：裝置端的靜態特徵碼檢查（如經典的反向殼一行指令等，即使未安裝 ClamAV 也能運作）加上 ClamAV 掃描。靜態特徵碼一旦命中就會隔離，不受 ClamAV 判定影響；若 ClamAV 結果不一致，通知會提及可能是誤判。
                • 隔離：威脅會被移至 `~/Library/Application Support/RoamSwitch/Quarantine/`（絕不會刪除）。若移動失敗，通知會顯示隔離失敗，並要求您手動刪除該檔案。
                • EICAR 測試檔：業界標準且無害的測試特徵碼不會被隔離或封鎖，也不會發出通知橫幅；只會被記錄於通知歷史（feat_notification_history）。
                • 首次資料夾存取：在 macOS 的權限提示出現之前，會先顯示一次性說明，告知這是此掃描功能所需的合法權限。
                • Pickle 格式 AI 模型警告：請參見 feat_ai_model_guard。
                """,
                recommendation: "安裝並啟用 ClamAV，並將任何自訂的瀏覽器下載資料夾加入監控資料夾清單。"
            ),
            LocalizedEntry(
                id: "feat_ai_model_guard",
                title: "危險 AI 模型格式（Pickle / PyTorch）下載警告 (Pro)",
                summary: "當從 Hugging Face、Civitai 等下載 `.pkl` / `.pickle` / `.pt` 模型檔時，會警告 Pickle 格式在載入時可能執行任意程式碼，並建議改用 SafeTensors / GGUF 格式。",
                details: """
                • 偵測方式：檢查透過網頁與郵件保護（feat_webmail_download_guard）所監控資料夾下載檔案的副檔名。
                • 風險：Python 的 Pickle 在反序列化時可執行任意程式碼，因此僅僅載入惡意模型就可能危害 Mac。
                • 行為：僅發出警告，不會隔離該檔案（若同時被 ClamAV 或靜態特徵碼判定為威脅，仍會照常隔離）。
                """,
                recommendation: "不要載入來源不明的 Pickle / PyTorch 模型，請改用 `.safetensors` 或 `.gguf` 格式的模型。"
            ),
            LocalizedEntry(
                id: "feat_quarantine_manager",
                title: "隔離檔案管理（隔離區、還原、刪除、掃描排除）",
                summary: "被 ClamAV 或靜態特徵碼檢查標記的檔案絕不會被刪除，而是保留在隔離區。隔離管理員可讓您查看原因、還原至原始位置、徹底刪除，或將某個路徑排除於未來的掃描之外。",
                details: """
                • 開啟方式：「惡意軟體防護 (XProtect & ClamAV)」→ ClamAV →「📦 管理隔離檔案…」，或在網頁與郵件保護下選擇「📦 開啟隔離管理員…」。
                • 位置：`~/Library/Application Support/RoamSwitch/Quarantine/`，並附有原始路徑、威脅名稱與隔離時間等中繼資料。除非您明確選擇「徹底刪除」，否則不會移除任何檔案。
                • 還原：將檔案放回原始位置；僅在您確定沒有感染時使用。
                • 排除並還原：確定為誤判時，將檔案還原並將該確切路徑排除於未來的 ClamAV 掃描之外。排除清單顯示在同一個視窗中，可用「取消排除」復原。
                • 徹底刪除：經確認後刪除，此動作無法復原。
                • MCP 工具 `get_quarantine_status` 可列出所有隔離中的檔案。
                """,
                recommendation: "刪除您不認識的檔案，只有像自己的指令碼或開發用執行檔這類確定為誤判的情況，才使用「排除並還原」。"
            ),
            LocalizedEntry(
                id: "feat_xprotect_file_safety",
                title: "Apple XProtect 狀態 & 檔案／應用程式安全性檢查",
                summary: "顯示 Apple 內建的 XProtect 惡意軟體防護的特徵庫版本與運作狀態，並檢查任意檔案或應用程式的公證狀態、簽署者、Team ID 與下載隔離屬性。免費版即可使用。",
                details: """
                • 開啟方式：「惡意軟體防護 (XProtect & ClamAV)」→「🍏 Apple XProtect」→「查看 XProtect 執行狀態…」／「檢查檔案/應用程式安全性…」。
                • 檢查項目：是否經 Apple 核准（公證／Gatekeeper）、簽署者、Team ID、網頁下載隔離屬性（`com.apple.quarantine`）與路徑。
                • 用途：在首次開啟應用程式前，確認它是否由合法開發者簽署並公證。
                """,
                recommendation: "在開啟來源不明的應用程式前先進行檢查，未經核准或未簽署的內容請不要開啟。"
            ),
            LocalizedEntry(
                id: "feat_dns_threat_guard",
                title: "DNS 威脅防護（攔截惡意網站與 C2）(Pro)",
                summary: "套用安全 DNS 解析服務（Quad9、Cloudflare、AdGuard、CleanBrowsing），在 DNS 階段就攔截對惡意軟體 C2 伺服器與釣魚網站的名稱查詢。",
                details: """
                • 供應商：Quad9（9.9.9.9 / 149.112.112.112）、Cloudflare Security（1.1.1.2 / 1.0.0.2）、AdGuard DNS（94.140.14.14 / 94.140.15.15，同時攔截廣告與追蹤器）、CleanBrowsing Security（185.228.168.9 / 185.228.169.9）。
                • 政策：「僅在不受信任 Wi-Fi 套用（推薦）」或「在所有網路中一律套用（包含受信任網路）」。
                • 內部運作：特權輔助工具會切換目前使用中網路服務的 DNS 伺服器，回到受信任網路時會恢復原本的 DHCP／手動 DNS 設定。
                • 狀態顯示：選單會顯示「🟢 安全 DNS 生效中」或「🏠 受信任網路（使用路由器預設 DNS）」，同時也是 Mac 安全稽核中的一個項目。
                """,
                recommendation: "為避免公共 Wi-Fi 上的假 DNS（DNS 挾持）與惡意網域，建議先從 Quad9 加上僅外出時套用的政策開始。"
            ),
            LocalizedEntry(
                id: "feat_passive_link_guard",
                title: "連結保護（偵測並封鎖釣魚連線：系統延伸功能、支援 DoH、警告模式故障關閉）(Pro)",
                summary: "根據已知詐騙網域的威脅情資與品牌仿冒偵測，無論使用何種瀏覽器或應用程式，都在裝置上封鎖與釣魚及詐騙網站的連線。以內容過濾系統延伸功能運作，在延伸功能獲得核准前，會以 /etc/hosts 黑洞作為備援。",
                details: """
                • 模式：「關閉」「僅警告（不攔截）」與「自動攔截明顯的釣魚網站（建議）」（預設值）。可在「惡意軟體防護」→「連結保護（釣魚連線偵測）(Pro)」中切換。
                • 攔截對象：僅限明確的情況，也就是威脅情資中收錄的網域，或是品牌名稱的 Unicode 同形異義字仿冒。子網域仿冒、高風險 TLD 等則視為警告。判定引擎與情資與 Linux 版共用。
                • 系統延伸功能（建議）：內容過濾系統延伸功能 `RoamSwitchLinkFilter` 會在名稱解析後檢查 TCP 連線。除了作業系統解析出的主機名稱外，也會讀取 TLS ClientHello 中的 SNI，因此即使瀏覽器使用自己的 DoH / DoT 也能判定。在攔截模式下，會捨棄看不到 SNI 的 QUIC（UDP 443），讓瀏覽器回退到 TCP。首次使用須在「系統設定」中核准。
                • JA3 指紋：對於能讀取到 SNI 的 TLS 連線，也會計算用戶端的 JA3 雜湊值，並與情資中的 JA3 清單比對（沒有 SNI 的連線絕不會單獨使用 JA3 判定）。
                • 警告模式（故障關閉）：相符的連線會被暫停，並顯示允許／封鎖通知與最前端面板，依您的回答恢復或捨棄該連線。若約 8 秒內沒有回應，該連線就會被封鎖。此結果不會被快取，因此下次嘗試時會再次詢問。您實際做出的選擇則會被記住。警告模式需要系統延伸功能。
                • hosts 備援：在延伸功能尚未生效期間，攔截模式會由特權輔助工具將網域以 `0.0.0.0` 寫入 `/etc/hosts` 的受管理區段。
                • 威脅情資：每天取得一次，僅接收（不傳送任何識別碼），並以專屬的 Ed25519 情資金鑰驗證（與應用程式更新金鑰分開）。關閉「自動更新」後對外流量為零，仍可依靠內建資料與同形異義字偵測運作。
                • 非 Pro 版：模式會被保存，但不會執行任何攔截。
                """,
                recommendation: "保持預設的自動攔截並核准系統延伸功能，是最可靠的保護方式。若內部工具遭誤攔截，可使用通知中的「本次允許（5 分鐘）」或加入允許清單。"
            ),
            LocalizedEntry(
                id: "feat_link_safety_auditor",
                title: "連結安全性診斷（手動檢查，Zero Telemetry）",
                summary: "在瀏覽器中開啟可疑網址之前，完全在裝置端進行分析，依 Unicode 同形異義字、子網域仿冒、高風險 TLD、明文 HTTP、直接使用 IP 等因素，以百分制評估危險程度。免費版即可使用。",
                details: """
                • 開啟方式：「惡意軟體防護」→「🔗 手動檢查連結…」，或 MCP 工具 `audit_url_safety`。
                • 同形異義字：偵測使用西里爾字母、希臘字母等外觀相似字元的仿冒（Punycode / `xn--`）。
                • 子網域仿冒：分析像 `apple.com.login-verify.xyz` 這類混入知名品牌名稱的結構。
                • 高風險 TLD：對於 `.xyz`、`.top`、`.tk`、`.icu` 等常見於一次性釣魚攻擊的 TLD 進行扣分。
                • 明文 HTTP 與直接 IP：警告登入頁面使用未加密 HTTP，以及使用裸 IP 位址的網址。
                • 完全在地執行：網址絕不會傳送到外部分析 API，因此機密網址與權杖不會外洩。
                """,
                recommendation: "收到郵件或聊天訊息中的可疑連結時，請勿直接點擊，先以連結安全性診斷檢查。"
            ),
            LocalizedEntry(
                id: "feat_ransomware_canary_guard",
                title: "勒索軟體誘餌檔案偵測 & 自主氣隙圍堵與程序凍結 (Pro)",
                summary: "在您的使用者資料夾中放置隱藏的誘餌（canary）檔案。一旦其中任何一個遭修改、刪除或重新命名，會立即自動斷網、停止共享服務，並暫停（SIGSTOP）可疑的程序。",
                details: """
                • 誘餌檔案：`~/Library/Application Support/RoamSwitch/CanaryGuard/` 中有四個，另外在文稿、桌面、下載項目與圖片資料夾中有以 `.roamswitch_security_canary_do_not_delete` 開頭的隱藏檔案。每個檔案的 SHA-256 會被記錄為基準值。
                • 偵測方式：結合即時 kqueue 監控與每 60 秒的定期檢查。每個檔案有 10 秒的冷卻時間，避免同一波事件被重複處理。過去 60 秒內遭修改的真實檔案也會被記錄為可能受影響。
                • 自動回應：（1）套用「應用程式防火牆」鎖定 （2）氣隙圍堵（pf 封鎖所有流量並關閉 Wi-Fi 無線電，feat_airgap_containment） （3）停止共享服務（SMB / SSH / 螢幕共享） （4）以 SIGSTOP 暫停可疑程序而非強制結束 （5）發出緊急警示並顯示最前端的緊急視窗。
                • 為何暫停而非結束：網路已經被切斷，因此暫停的程序無法造成進一步損害。若確認是誤判，解除時會以 SIGCONT 恢復該程序，不會遺失任何資料。
                • 解除時：網路與 Wi-Fi 會恢復，暫停的程序會被恢復執行，遭竄改的誘餌檔案也會重新產生。
                • 預設值：首次啟用 Pro 時自動開啟。事件記錄可透過 MCP 工具 `get_canary_status` 取得，並可在選單中使用「勒索軟體防禦模擬測試（驗證運作）」安全地測試。
                """,
                recommendation: "為保護重要資料免受未知勒索軟體侵害，請保持開啟，且不要刪除隱藏的誘餌檔案。"
            ),
            LocalizedEntry(
                id: "feat_runtime_threat_containment",
                title: "XProtect 偵測到惡意軟體時自動斷網 (Pro)",
                summary: "當 Apple 內建的 XProtect / XProtect Remediator 實際偵測或移除惡意軟體的當下，會以緊急氣隙方式斷網。Gatekeeper 對未簽署應用程式的封鎖並不會斷網，只會發出通知。",
                details: """
                • 訊號來源：以 ndjson 格式長期訂閱 `/usr/bin/log stream`（採阻塞式等待而非輪詢，因此閒置時 CPU 消耗趨近於零），監控與 XProtect 相關的系統日誌。
                • 觸發條件：只有當 XProtect 記錄重大惡意軟體判定時，才會啟動氣隙圍堵（包含關閉 Wi-Fi 無線電），且與網路的信任等級無關。
                • 與 Gatekeeper 的差異：日常的 Gatekeeper 事件，例如封鎖開發者自己建置的未簽署程式，只會發出「Gatekeeper 已封鎖未簽署應用程式的執行」通知。
                • 一致性：與手動的「Mac 安全日誌審計」共用相同的分類邏輯。
                • 未使用 EndpointSecurity 授權，因此這是偵測後的立即圍堵，而非執行前的封鎖。
                • 預設值：首次啟用 Pro 時自動開啟（並會顯示一次性提示，說明自動斷網已啟用）。狀態可透過 MCP 工具 `get_runtime_threat_status` 取得，並可用「模擬惡意軟體偵測連動氣隙（測試）」測試。
                """,
                recommendation: "請保持開啟，作為與 Apple 自身惡意軟體引擎連動的自動防禦。經常執行自己開發的未簽署應用程式也不會觸發，因為單純的 Gatekeeper 封鎖絕不會斷網。"
            ),
            LocalizedEntry(
                id: "feat_clickfix_guard",
                title: "ClickFix 防護 — 偵測到可疑終端機指令時自動封鎖 (Pro，預設關閉)",
                summary: "從您的殼層歷史記錄中偵測 ClickFix 手法──假冒的驗證碼或錯誤頁面誘導您自行貼上並執行指令，並斷網以阻止正在進行中的多階段攻擊。",
                details: """
                • 監控範圍：僅監控 `~/.zsh_history` 與 `~/.bash_history` 新增的行（既有歷史記錄不列入監控）。
                • 判斷模式：（1）已知的反向殼一行指令（與靜態特徵碼檢查共用）（2）將 Base64 解碼的內容直接透過管線傳給殼層或 `osascript` 的雙重間接手法。像 Homebrew 等合法安裝程式所使用的單純 `curl ... | bash` 刻意不會被標記。
                • 回應方式：氣隙圍堵（不會關閉 Wi-Fi 無線電），最多 10 分鐘後自動恢復。通知會建議您檢查 Keychain、瀏覽器儲存的密碼與加密貨幣錢包。
                • 為何是事後處理：指令出現在歷史記錄時已經執行過了，但立即斷網仍可能阻止正在進行中的第二階段下載、即時反向殼連線或憑證外洩。
                • 為何 Gatekeeper 無法阻止：這是您自己合法的殼層，完全依照您輸入的內容執行，因此程序本身看不出任何異常。
                • 互補功能：剪貼簿保護（feat_secret_leak_auditor）會在複製當下就攔截該指令，涵蓋貼到指令碼編輯器、Spotlight 等 Terminal 以外的位置。
                • 預設關閉：由於這是一種相對較新的啟發式判斷方式，並會自動斷網，因此設為自行開啟。
                """,
                recommendation: "若擔心被假錯誤頁面或驗證碼誘騙而執行指令，建議考慮開啟此功能。"
            ),
            LocalizedEntry(
                id: "feat_persistence_monitor_guard",
                title: "監控新增自動啟動註冊（LaunchAgent / LaunchDaemon）(Pro)",
                summary: "即時監控新的 LaunchAgent / LaunchDaemon 註冊，當有項目直接啟動殼層或指令碼直譯器，或註冊了簽署無效的執行檔時通知您。",
                details: """
                • 監控範圍：透過 FSEvents 監控 `~/Library/LaunchAgents`、`/Library/LaunchAgents` 與 `/Library/LaunchDaemons`（去彈跳約 1.5 秒）。
                • 判斷依據：近期的資訊竊取程式常透過合法 Apple 簽署的 `/bin/bash` 或 `/usr/bin/osascript` 執行以 Base64 隱藏的指令碼來達成持久化。由於直譯器本身的簽署有效，任何直接啟動裸直譯器的註冊，無論簽署狀態都會被視為可疑，其指令碼參數也會經由靜態特徵碼檢查。未簽署或簽署無效的執行檔同樣會被標記。Homebrew services 的包裝程式則為例外。
                • 僅偵測：由於未使用 EndpointSecurity 授權，無法阻止 plist 的寫入本身。系統會在寫入後約 1.5 秒內判斷並回報。
                • 預設值：Pro 版預設開啟。可在「惡意軟體防護」→「監控新增自動啟動註冊(LaunchAgent/Daemon) (Pro)」切換。
                """,
                recommendation: "若收到不熟悉的註冊警告，請檢查通知中顯示的 plist 內容，若不認得就刪除。若是剛安裝合法應用程式後出現，通常沒有問題。"
            ),
            LocalizedEntry(
                id: "feat_docker_event_guard",
                title: "偵測 Docker 特權容器與 docker.sock 掛載 (Pro，預設關閉)",
                summary: "在容器啟動時，通知您可能導致容器逃逸的高風險 Docker 設定，例如以 `--privileged` 啟動，或掛載了 `/var/run/docker.sock` 的容器。",
                details: """
                • 運作方式：每 20 秒以 `docker ps` 找出僅是新啟動的容器，再以 `docker inspect` 檢查其設定。偵測格式與 Linux 版完全相同，因此兩個平台會標記相同的條件。
                • 僅發出通知：這是高風險的「設定」，並非確認的入侵事件（例如監控代理程式可能刻意以特權模式執行），因此不會自動封鎖任何內容。
                • 預設關閉：大多數使用者並未使用 Docker，因此即使是 Pro 版也預設關閉。
                • 測試方式：「⚠️ Docker 風險偵測模擬（驗證運作）…」可在不接觸 Docker 的情況下檢查通知路徑是否正常。
                """,
                recommendation: "若您在開發時使用 Docker，建議開啟此功能以及早發現容器逃逸風險。"
            ),
        ]
    }

    // MARK: - Features: audit, monitoring & platform

    private static func featuresZhHantAudit() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_critical_path_fim",
                title: "重要系統檔案竄改監控（Critical Path FIM）(Pro)",
                summary: "記錄 sudoers、SSH 設定、PAM、hosts 等重要檔案的 SHA-256 基準值──這些檔案幾乎不會因合法的作業系統更新或應用程式安裝而變動──並在任何修改、刪除或新增檔案時通知您。",
                details: """
                • 涵蓋檔案：`/etc/sudoers`、`/etc/pam.d/sudo`、`/etc/ssh/sshd_config`、`/etc/ssh/sshd_config.d/` 下的所有檔案、`/etc/hosts`，以及 root 的 `~/.ssh/authorized_keys`。這些檔案僅限 root 讀取，因此由特權輔助工具計算雜湊值。
                • 觸發時機：`/etc`、`/etc/pam.d` 與 `/etc/ssh` 上的 FSEvents 會觸發近乎即時的重新掃描，並以每小時掃描一次作為後備。
                • 基準線：於第一次掃描時建立。偵測到的變更絕不會自動被採用為新的基準線，因此該發現會持續存在，直到有人手動審視為止。在應用程式持續執行期間，相同狀態不會重複通知；若有進一步變更則會再次警告。
                • 盲點警告：若輔助工具連續 3 次掃描都無法連線，會告知您竄改偵測目前無法運作。
                • 備註：當連結保護執行於 hosts 備援模式時，RoamSwitch 本身可能會改寫其管理的 `/etc/hosts` 區段。LaunchAgent / Daemon 則由 feat_persistence_monitor_guard 負責。
                • 預設值：首次啟用 Pro 時自動開啟。選單：「惡意軟體防護」→「定期監控重要系統檔案是否遭竄改 (Pro)」。
                """,
                recommendation: "收到警告時，請確認是否是您自己所做的變更（例如 `sudo visudo` 或編輯設定檔）。若不是，請立即檢查該檔案的內容，並考慮變更密碼。"
            ),
            LocalizedEntry(
                id: "feat_security_log_audit",
                title: "Mac 安全日誌審計（手動、範本異常偵測、AI 諮詢資料複製）",
                summary: "從 macOS 統一日誌中擷取 sudo 失敗、SSH 連線、Gatekeeper 封鎖、XProtect 偵測與驗證事件，同時列出新的日誌模式與頻率激增（範本異常）。免費版即可使用。",
                details: """
                • 開啟方式：「Mac 安全稽核」→「📜 Mac 安全日誌審計…」，或 MCP 工具 `audit_security_logs`。
                • 期間：過去 24 小時、3 天或 7 天。
                • 摘要卡片：Sudo 失敗、SSH 連線、Gatekeeper 封鎖、XProtect 偵測、範本異常。可依類別篩選並搜尋。
                • 範本異常：透過遮蔽可變部分（IP 位址、十六進位位址、數字）將日誌行轉換為範本。會列出這台 Mac 從未見過的新模式（[新增]）與遠高於平常頻率的激增（[激增 z=…]，z 分數 3 以上）。每個範本的頻率在觀測 3 次後即完成學習，之後正常的量就不會再警告。
                • 白話判定：裝置端的規則式輔助工具會為非專業使用者總結結果，並列出具體的檢查重點（不使用外部 API）。
                • 輸出：「複製報告」「複製供 AI 諮詢的資料」（複製一段問題與日誌內容，供貼到 Claude、ChatGPT 等使用；RoamSwitch 本身不會傳送任何內容），以及「匯出 CSV (Pro)」。
                """,
                recommendation: "當持續收到可疑通知或 Mac 出現異常行為時執行此功能，並檢查是否有 XProtect 偵測或 sudo 失敗次數暴增的情況。"
            ),
            LocalizedEntry(
                id: "feat_scheduled_log_audit",
                title: "自動日誌審計（定期學習新模式與頻率異常）(Pro)",
                summary: "在背景每小時執行一次日誌審計的範本異常偵測，持續學習這台 Mac 平常的日誌行為。發現新模式或頻率激增時，會附上真實日誌行與白話說明通知您。",
                details: """
                • 排程：每小時分析上一小時的資料。啟用後約 10 秒會執行第一次掃描，但由於其中包含應用程式自身的啟動日誌，該次執行只會學習，不會發出通知。
                • 通知內容：異常件數（分為新模式與激增）、最多 3 行真實日誌、學習進度說明，以及非專業使用者也能理解的解釋。包含頻率激增時會在通知中心顯示提醒；僅有新模式時則不會彈出提醒，只會記錄到通知歷史中。新模式記錄一次後就會成為「已知」，同樣內容不會再重複記錄；一旦該範本自身的基準線學習完成，激增也會停止警告。
                • 與手動審計共用：與手動的「Mac 安全日誌審計」及 MCP 工具 `audit_security_logs` 使用相同的分析與已學習基準線。
                • 預設值：首次啟用 Pro 時自動開啟。選單：「惡意軟體防護」→「自動記錄稽核(定期學習新模式與頻率異常) (Pro)」。
                """,
                recommendation: "剛設定完成時，新模式的通知會稍微多一些，隨著學習進行會逐漸減少。若警告中出現不熟悉的應用程式名稱或 IP 位址，請開啟日誌審計視窗查看詳情。"
            ),
            LocalizedEntry(
                id: "feat_containment_incident_timeline",
                title: "圍堵事件時間軸（統一記錄、MITRE ATT&CK 對應）",
                summary: "將四種自動回應（ARP 詐騙、勒索軟體誘餌檔案、XProtect 連動斷網、未知連接埠自動封鎖）統一記錄在裝置上的一份時間順序紀錄中，方便您日後回顧發生了什麼、採取了什麼行動，以及何時解除。",
                details: """
                • 記錄內容：時間、來源、嚴重程度、摘要、程序名稱與 PID（若已知）、採取的行動，以及解除時間與原因（手動解除、逾時自動解除，或加入允許清單）。
                • MITRE ATT&CK：僅在對應確定時才附上技術 ID（ARP 詐騙 = T1557；誘餌檔案遭刪除或重新命名 = T1485；加密 = T1486；其他竄改 = T1565）。不會猜測任何內容。
                • 儲存位置：`~/Library/Application Support/RoamSwitch/containment_incident_timeline.json`（保留最新 200 筆）。絕不會傳送到任何地方。
                • MCP 工具 `get_incident_timeline` 可取得這份統一時間軸（在氣隙期間可用於協助本機 AI 進行事件分析）。個別防護的歷史也可透過 `get_canary_status`、`get_port_anomaly_incidents` 與 `get_runtime_threat_status` 取得。
                """,
                recommendation: "發生自動斷網後，請將此時間軸與通知歷史一併檢視，以找出原因並避免再次發生。"
            ),
            LocalizedEntry(
                id: "feat_notification_history",
                title: "通知歷史（過去一週）",
                summary: "保留 RoamSwitch 發出的每一則通知達 7 天，方便您回顧錯過的警告。像 EICAR 測試特徵碼偵測這類只記錄而不顯示橫幅的事件，也會出現在這裡。免費版即可使用。",
                details: """
                • 開啟方式：「Mac 安全稽核」→「🔔 通知歷史…」。
                • 保留期限：7 天；每次記錄新項目時，會自動清除較舊的項目。
                • 內容：時間、標題與內文，包含威脅警示、連結保護連線事件、ClickFix 與機密金鑰偵測，以及自動斷網事件。
                • EICAR 測試特徵碼：這個無害的業界測試檔並非真正的威脅，因此不會被隔離或封鎖，也不會顯示橫幅；只會被記錄於此。無論是下載保護、快速掃描或排程掃描皆是如此。
                • AI 助理可透過 MCP 工具 `get_notification_history` 讀取此記錄。
                """,
                recommendation: "若在外出或忙碌時錯過了通知，可在此處查看。"
            ),
            LocalizedEntry(
                id: "feat_secret_leak_auditor",
                title: "剪貼簿保護（API 金鑰貼上警告 & ClickFix 指令移除）",
                summary: "僅在裝置端監控剪貼簿，當偵測到已複製 API 金鑰或私密金鑰時發出警告，避免您誤貼上；當複製到詐騙網站要求您執行的惡意指令（ClickFix）時，會自動清除剪貼簿。免費版預設開啟。",
                details: """
                • 監控方式：約每秒檢查一次剪貼簿是否有變更。內容絕不會被傳送或儲存到任何地方。
                • 偵測的金鑰：OpenAI、Anthropic、GitHub、AWS、Hugging Face、Google AI / Gemini、Slack 與 Stripe 的 API 金鑰與權杖，以及 RSA / SSH 私密金鑰。另外還包括加密錢包助記詞（BIP39）與比特幣私鑰（WIF/BIP32），皆經過檢查碼驗證以降低誤判。
                • 機密金鑰：僅發出通知（「剪貼簿中偵測到機密金鑰」）；不會清除剪貼簿，因為外洩的金鑰日後仍可撤銷並重新產生。
                • ClickFix 指令：發出通知（「剪貼簿中偵測到可疑指令」）並立即清除剪貼簿，阻止您貼到 Terminal、指令碼編輯器、Spotlight 或其他任何地方。此功能與監控殼層歷史記錄的 feat_clickfix_guard 相輔相成。
                """,
                recommendation: "複製 API 金鑰後，請留意您要貼到哪裡，尤其是 AI 聊天室與網頁表單。若不小心分享出去，請立即撤銷並重新產生金鑰。"
            ),
            LocalizedEntry(
                id: "feat_secret_leak_audit_tool",
                title: "手動機密資訊／API 金鑰洩露稽核（貼上文字或掃描整個資料夾）",
                summary: "隨選稽核工具，可即時檢查貼上的文字，或遞迴掃描整個資料夾，並顯示行號、遮蔽後的數值，以及各類金鑰的撤銷步驟。免費版即可使用。",
                details: """
                • 開啟方式：「惡意軟體防護」→「🔑 手動稽核機密資訊/API 金鑰洩露…」，或 MCP 工具 `audit_secrets`（帶入 `text` 或 `path`）。
                • 判斷方式：正規表示式加上夏農熵評分。偵測到的數值會以遮蔽方式顯示。
                • 資料夾掃描：`.git`、`node_modules`、`target`、`vendor`、`dist`、`build`、`__pycache__`、`venv` 會自動略過，超過 2 MB 的檔案與二進位檔亦然。
                • 權限說明：選擇桌面或下載項目等受保護資料夾時，會先於 macOS 的權限提示之前顯示一次性說明，告知為何需要此存取權，以及此掃描屬於 Zero Telemetry。
                • 於背景執行緒運作，不會凍結介面。任何內容都不會被傳送出去。
                """,
                recommendation: "在發佈儲存庫或將程式碼貼到 AI 聊天室之前，先使用此工具檢查。"
            ),
            LocalizedEntry(
                id: "feat_package_cve_scan",
                title: "套件 CVE 比對（Homebrew + 7 個生態系，含 npm / PyPI / crates.io，Zero Telemetry）",
                summary: "將已安裝的 Homebrew 套件，以及您指定的專案資料夾中的相依性鎖定檔，與裝置端保存的已知 CVE 對應表進行比對。掃描本身不會發出任何網路請求。免費版即可使用。",
                details: """
                • 開啟方式：「惡意軟體防護」→「📦 軟體包CVE比對（Homebrew）…」。相依性部分請在「相依性」分頁新增專案資料夾。
                • Homebrew：以 `brew list --versions` 的結果比對由真實 NVD 資料產生的 formula 對 CPE 對應表。結果會附上信心等級：confirmed（已驗證的對應表）或 gray（未驗證的關鍵字比對，可能為誤判）。
                • 相依性：解析 package-lock.json / requirements.txt / Pipfile.lock / poetry.lock / Cargo.lock / Gemfile.lock / composer.lock / go.sum / pom.xml，並與 npm、PyPI、crates.io、RubyGems、Packagist、Go、Maven 的已知 CVE 對應表比對（來源為 OSV.dev，CVSS 7.0 以上）。
                • 資料更新：CVE 對應表每天從已簽署的清單取得一次，僅接收。取得之前會顯示尚未下載，且不會偵測到任何項目。
                • MCP 工具：`run_package_cve_scan`（Homebrew）與 `run_package_cve_scan_languages`（相依性，`watchedFolders` 參數）。
                """,
                recommendation: "定期執行 Homebrew 掃描，在「相依性」分頁登錄開發中的專案，並儘快更新含有嚴重 CVE 的套件。"
            ),
            LocalizedEntry(
                id: "feat_lockfile_tamper_guard",
                title: "相依鎖定檔案竄改監控 (Lockfile FIM, Pro)",
                summary: "透過 SHA-256 基準持續監控 package-lock.json / yarn.lock / pnpm-lock.yaml / npm-shrinkwrap.json，偵測經由 CI 或供應鏈的外部竄改。僅限 Pro。",
                details: """
                • 開啟方式：在選單列「🔔/✅ 定期監控相依鎖定檔案是否遭竄改 (Pro)」項目中切換。
                • 監控對象：與套件 CVE 比對「相依關係」分頁中登記的相同專案資料夾內的 package-lock.json / yarn.lock / pnpm-lock.yaml / npm-shrinkwrap.json。不新增獨立的監控資料夾清單。
                • 偵測方式：透過 CryptoKit 進行 SHA-256 基準差異比對，結合 FSEvents 近即時偵測與每小時一次的備援掃描。
                • 通知緊急程度：若偵測時 npm/yarn/pnpm 本身正在執行，會記錄於通知記錄中並以靜音方式通知；未執行時的竄改則為一般緊急通知。無論何種情況，偵測本身都必定執行。
                • 若 Pro 授權失效將自動停用。
                """,
                recommendation: "建議將重要專案登記到套件 CVE 比對的「相依關係」分頁中，並保持此功能開啟（啟用 Pro 後預設開啟）。"
            ),
            LocalizedEntry(
                id: "feat_package_lifecycle_script_scan",
                title: "安裝指令碼清單 (npm package.json lifecycle 指令碼, Pro)",
                summary: "列出 node_modules 下 package.json 宣告的 preinstall/install/postinstall/prepare 指令碼。目的是讓 npm install 時無條件執行的程式碼可見，並非威脅判定。僅限 Pro。",
                details: """
                • 開啟方式：選單「惡意軟體防護」→「📦 套件 CVE 比對 (Homebrew)…」→「安裝指令碼 (npm) (Pro)」分頁。掃描對象與「相依關係」分頁相同。
                • 掃描範圍：node_modules 下一層（@scope/ 套件再多一層）。絕不深入套件自身巢狀的 node_modules。
                • 僅供參考的危險標記：符合 curl|sh、wget|sh、eval(、base64 -d、node -e 的指令會顯示 ⚠️ 標記——這僅是輕量啟發式判斷，並非定論，許多合法指令碼（如原生模組建置）也會命中。
                • 完全不進行任何網路連線，也絕不執行指令碼——純粹的靜態清單展示。
                • MCP 工具：`run_package_lifecycle_script_scan`（`watchedFolders` 參數，僅限 Pro）。
                """,
                recommendation: "對標有 ⚠️ 的指令碼，請逐一確認該套件是否確實需要執行此操作。對不熟悉套件的 postinstall 指令碼請格外留意。"
            ),
            LocalizedEntry(
                id: "feat_npm_audit_signatures",
                title: "npm 簽章/來源驗證 (npm audit signatures，選擇性啟用，Pro)",
                summary: "與 npm 註冊表通訊，驗證已安裝套件的簽章/來源。這是 RoamSwitch 中唯一與 npmjs.com 通訊的功能——預設關閉，需要明確選擇性啟用並在每次執行時確認。僅限 Pro。",
                details: """
                • 啟用方式：「📦 套件 CVE 比對」→「npm 簽章驗證（選擇性啟用）(Pro)」分頁中的「啟用 npm 簽章驗證」開關。這僅會解鎖每個專案資料夾的「執行稽核」按鈕，本身不會傳送任何內容。每次執行都會以「要與 npm 註冊表通訊嗎？」進行確認。
                • 執行內容：以目標資料夾為工作目錄執行 `npm audit signatures`，與 npm 註冊表 (registry.npmjs.org) 通訊。這是 RoamSwitch 中唯一與 npmjs.com 通訊的功能。
                • 輸出：原樣顯示 npm 指令的輸出（絕不自行解讀或定論）。若結束代碼非零，或輸出中包含「invalid」/「missing registry signature」等字樣，會顯示輕量級的注意提示。
                • 若找不到 npm 指令，會顯示提示安裝 Node.js/npm 的訊息。
                • MCP 工具：`run_npm_audit_signatures`（`directory` 參數，Pro 與選擇性啟用開關的雙重限制）。
                """,
                recommendation: "僅在部署前的相依性稽核，或懷疑發生供應鏈入侵的事件調查時啟用即可，無需一直保持開啟。"
            ),
            LocalizedEntry(
                id: "feat_npm_sandboxed_install",
                title: "npm/pnpm 安裝沙箱執行 (roamswitch-npm, Pro)",
                summary: "這是一個真正進行介入的包裝器,而非僅做偵測——僅將 preinstall/install/postinstall/prepare 腳本的執行限制在禁止連網的沙箱(sandbox-exec)中,實際代為執行安裝。僅限 Pro 版。",
                details: """
                • 啟用方法: 在「📦 套件 CVE 比對」→「沙箱安裝 (npm/pnpm) (Pro)」分頁點選「安裝」按鈕,即可將命令列包裝器 `roamswitch-npm` 放置到 ~/Library/Application Support/RoamSwitch/bin/。
                • 兩階段流程: ①下載階段照常連網執行 `npm install --ignore-scripts` / `pnpm install --ignore-scripts`。②腳本執行階段在設有 `(deny network-outbound)` 的 sandbox-exec 設定檔下執行 `npm rebuild` / `pnpm rebuild`(若根目錄宣告了 prepare,還會執行 `run prepare`)。
                • 沙箱方式: Linux 版採用 bwrap 進行檔案系統限制,但 macOS 沒有同等技術,因此改為採用已在實機驗證可行的網路阻斷(`(allow default)` + `(deny network-outbound)`)。不限制檔案讀寫與子行程的啟動。
                • Shell 別名: 可在 shell 設定檔中追加兩行別名,讓 `npm`/`pnpm` 經由包裝器執行(選用,僅追加,不變更現有內容)。
                • 預覽: 執行前可列出專案資料夾的生命週期腳本清單(與「安裝指令碼清單」功能使用相同的掃描器)。
                • 若 sandbox-exec 不可用或執行失敗,絕不會默默回退到不加沙箱的執行。不支援 yarn。沒有 GTK/MCP 工具——這是一個從終端機使用的命令列工具。
                """,
                recommendation: "對於包含陌生套件的專案,或從外部來源取得的專案,建議使用 `roamswitch-npm install` 取代常規的 npm/pnpm install。"
            ),
            LocalizedEntry(
                id: "feat_typosquat_guard",
                title: "打字仿冒偵測 (npm/pnpm package.json, Pro)",
                summary: "將 package.json 的相依名稱與知名 npm 套件名稱清單進行編輯距離(Levenshtein 1〜2)比對，偵測 expres→express、loadash→lodash 這類可能的打字仿冒。應用程式本身完全不為此進行網路連線。僅限 Pro 版。",
                details: """
                • 範圍：僅限專案自身 package.json 的 dependencies/devDependencies/optionalDependencies（peerDependencies 不在範圍內）。node_modules（已安裝的傳遞相依性）也刻意不在範圍內——打字錯誤產生於人類將相依性加入 package.json 的那一刻。
                • 比對邏輯：標準的 Levenshtein 距離動態規劃實作，將每個相依名稱與知名 npm 套件名稱清單比對。帶作用域的套件（`@scope/pkg`）以其基礎名稱（`pkg`）比較。長度差超過 2 的候選會被低成本預過濾跳過。閾值為：知名名稱長度 8 個字元以上時允許距離最多為 2，更短則僅允許距離 1。
                • 清單保持更新的方式：用於比對的熱門套件名稱清單由 `PackageCveMapUpdater` 透過與 CVE 對應表相同的每日一次、僅接收、Ed25519 簽章驗證的清單進行分發（建置時內嵌種子加兩層覆蓋，優先採用 `mapVersion` 較新的一方）。無需等待應用程式發布即可更新該清單。
                • 這是參考資訊，並非定論——已知的許可清單會部分排除一些正規的相似套件（如 preact），但並不完整。
                • 開啟方式：「📦 套件 CVE 比對」→「打字仿冒偵測 (Pro)」分頁，針對與「相依性」分頁相同的專案資料夾。MCP：`run_typosquat_scan`（`watchedFolders` 參數，僅限 Pro）。
                """,
                recommendation: "請對任何標記 ⚠️ 的相依性逐一核實是否確實是拼寫錯誤——尤其要留意陌生的套件名稱。"
            ),
            LocalizedEntry(
                id: "feat_port_scan_guard",
                title: "入站連接埠掃描偵測 (自動封鎖, Pro)",
                summary: "偵測在短時間(5分鐘)內連線至多個不同連接埠(15個以上)的來源IP並發出通知(這是nmap/masscan等偵察工具的典型特徵)。偵測到的掃描來源預設會被自動封鎖10分鐘。僅限 Pro。",
                details: """
                • 運作方式：具有特權的Helper透過`tcpdump -i pflog0`監控pf(封包過濾器)日誌，偵測在短時間視窗內到達足夠多不同目的連接埠的來源IP。判定僅根據日誌記錄，絕不會變更或檢查通訊內容本身。對應Linux版的`port_scan_detect.rs`(nftables `log` + `journalctl`)。
                • 自動封鎖：偵測到的掃描來源會透過`PFRulesetCoordinator`加入pf規則，預設封鎖10分鐘。自動封鎖可狜立於偵測功能本身單狜開關。
                • 通知：每次偵測(及封鎖)都會發送macOS通知，並記錄到統一的事件時間軸中。
                • 開啟方式：選單列 → 「連接埠與裝置監控」 → 「🔍 入站連接埠掃描偵測 (Pro)」。啟用和停用都需要經過確認對話框。預設關閉。
                """,
                recommendation: "沒有依IP的許可清單，封鎖會在10分鐘後自動解除。如果您在家庭或公司環境中定期執行合法的掃描工具(資產盤點、弱點掃描等)，建議在其執行期間關閉自動封鎖(僅保留偵測/通知)，以避免因誤判而反復封鎖。"
            ),
            LocalizedEntry(
                id: "feat_sensor_pairing",
                title: "RoamSwitch Sensor 配對 (配對碼方式, Pro)",
                summary: "管理與同一區域網路上的獨立產品「RoamSwitch Sensor」(專用主動稽核集線器)之間的相互信任配對。採用由 Sensor 核發配對碼的主動配對方式，假定 Sensor 以固定 IP 運作，因此不再使用 mDNS 自動探索。僅限 Pro。",
                details: """
                • 運作方式：產生並永久保存此裝置自身的 Ed25519 金鑰對。配對時，此裝置攜帶 Sensor 操作者核發的一次性配對碼(核發後 10 分鐘失效)以及此裝置自身的位址/主機名稱，連線至 Sensor 的 TCP 監聽器(連接埠 50543)。若配對碼有效，Sensor 會將此裝置的公開金鑰加入其信任清單。
                • 請求稽核：配對完成後，可透過「向 Sensor 請求稽核」要求 Sensor 執行一次主動稽核(可達性驗證)。由於 Sensor 是非同步產生結果，此裝置端常駐的特權輔助程序會每隔 5 分鐘自動嘗試取得結果，最多 5 次。取得的結果也會保存在此裝置上，可於設定畫面的「稽核結果」清單中查看。
                • 開啟方式：選單列 → 「連接埠與裝置監控」 → 「🔍 RoamSwitch Sensor 配對…」。顯示此裝置自身的公開金鑰/位址(附複製按鈕)、已配對的 Sensor 清單(取消配對按鈕)、配對碼輸入表單以及稽核結果清單。
                • 使用與 Linux 版(`roamswitch-core::sensor_pairing`)相同的 TCP 控制協定——連接埠 50543、換行分隔 JSON、Ed25519 簽章。
                """,
                recommendation: "請僅使用確實由您自己設定的 RoamSwitch Sensor 操作畫面所核發的配對碼。如果被要求輸入陌生的配對碼，請勿配對——建議向網路管理員核實。"
            ),
            LocalizedEntry(
                id: "feat_security_health_checker",
                title: "Mac 安全稽核（18 個項目、分數與修正步驟）",
                summary: "檢查六大領域（系統強化、網路防禦、驗證與存取控制、連接埠曝露、惡意軟體防護、實體裝置防護）共 18 個項目，並顯示 0 到 100 分的分數、等級，以及每個未通過項目的修正步驟。免費版即可使用。",
                details: """
                • 系統強化：1. FileVault、2. SIP（系統完整性保護）、3. Gatekeeper、4. 自動安全更新、5. Apple XProtect。
                • 網路防禦：6. macOS 防火牆、7. 隱形模式、8. Wi-Fi 加密強度、9. ARP 詐騙監控、10. 閘道 ARP 固定。
                • 驗證與存取控制：11. SSH 遠端登入設定（是否停用 root 登入、僅限金鑰驗證）、12. sudo 權限提升（`NOPASSWD` 稽核）。
                • 服務與連接埠曝露：13. 公開連接埠。
                • 惡意軟體與下載保護：14. 網頁與郵件保護、15. DNS 威脅防護、16. 釣魚與惡意連結防護（Safari 詐騙網站警告）。
                • 實體連接埠與裝置：17. 非法 USB / BadUSB 實體連接埠防護、18. macOS 配件連線保護（Apple 晶片）。
                • 不適用項目：受信任網路上的防火牆與隱形模式、遠端登入關閉時的 SSH 檢查、輔助工具連線前的 sudo 稽核，以及 Intel Mac 的配件保護，都會排除在分數計算之外。
                • 等級：100 分為 S、85 至 99 分為 A、70 至 84 分為 B、低於 70 分為 C。也可透過 MCP 工具 `get_security_report` 取得。
                """,
                recommendation: "定期開啟稽核報告，依照顯示的修正步驟處理標示 ⚠️ 的項目，並維持在 A 級以上。"
            ),
            LocalizedEntry(
                id: "feat_autonomous_sentinel",
                title: "背景自主巡邏、ClamAV 病毒特徵庫更新與排程掃描",
                summary: "每 4 小時在背景重新整理安全稽核、連接埠、USB 裝置與 XProtect 狀態（所有版本皆適用）。Pro 版另會警告分數下降、自動更新 ClamAV 特徵庫，並每天執行一次病毒掃描。",
                details: """
                • 定期稽核（所有版本）：啟動後約 30 秒開始，之後每 4 小時執行一次，即使長時間停留在同一個網路，結果也能保持最新。
                • 分數下降警告（Pro）：當分數低於 80 或有 4 個以上項目未通過時通知您。
                • ClamAV 特徵庫（Pro）：靜默執行 `freshclam`。
                • 排程掃描（Pro）：每天一次，以 ClamAV 掃描 `~/Downloads`、`~/Desktop` 與 `~/Library/LaunchAgents`。發現威脅會自動隔離並發出緊急警示；結果乾淨時只會顯示安靜的完成通知。若只發現 EICAR 測試特徵碼，不會顯示任何內容，僅記錄於通知歷史。
                """,
                recommendation: "使用 Pro 版時建議安裝 ClamAV，讓特徵庫更新與排程掃描能自動執行。"
            ),
            LocalizedEntry(
                id: "feat_simulation_self_test",
                title: "模擬（自我測試）工具",
                summary: "在不造成任何真實攻擊或檔案損壞的情況下，安全地測試勒索軟體防禦、惡意軟體偵測氣隙，以及 Docker 風險偵測是否正常運作。",
                details: """
                • 位置：位於「惡意軟體防護 (XProtect & ClamAV)」的底部。
                • 🚨 勒索軟體防禦模擬測試（驗證運作）…：執行與偵測到加密行為相同的步驟，檢查氣隙與緊急視窗是否正常運作。不會傷害任何檔案。
                • 🚨 惡意軟體偵測聯動 Air-Gap 模擬（功能測試）…：執行與真實 XProtect 偵測相同的步驟，檢查圍堵與緊急視窗的運作。事件會被標記為模擬。
                • ⚠️ Docker 風險偵測模擬（驗證運作）…：檢查特權容器通知是否會送達，不會實際觸碰 Docker。
                • 注意：氣隙測試會真的暫時斷網。請從緊急視窗解除（也會在 10 分鐘內自行恢復）。
                • 若要測試下載保護，可使用無害的 EICAR 測試檔（不會出現橫幅，會記錄於通知歷史）。
                """,
                recommendation: "在啟用 Pro 或變更設定後執行一次模擬，確認通知與氣隙按預期運作。"
            ),
            LocalizedEntry(
                id: "feat_privileged_helper",
                title: "特權輔助工具（RoamSwitchHelper，XPC）",
                summary: "只有需要 root 權限的操作（PF 防火牆、共享服務、DNS、氣隙等）會由特權分離的 LaunchDaemon 輔助工具透過 XPC 執行。",
                details: """
                • 特權分離：主應用程式以一般使用者權限執行，僅將 pf 規則變更、共享常駐程式控制、DNS 設定、ARP 固定、重要檔案雜湊計算等交由 `RoamSwitchHelper` 處理。
                • 註冊方式：透過 macOS 的 SMAppService 以應用程式內建的 LaunchDaemon 形式註冊。首次使用需要在「系統設定」→「一般」→「登入項目與延伸功能」中核准。若應用程式不在「應用程式」資料夾中，則無法註冊（faq_install_location）。
                • 附屬常駐程式：也會註冊用於氣隙保護機制（10 分鐘後自動解除）與開機閘（最多 90 秒）的輔助 LaunchDaemon。
                • 驗證機制：XPC 連線時會檢查程式碼簽署（Team ID），拒絕來自未經授權程序的呼叫。
                • 更新後的重新核准：應用程式會自動嘗試切換為新版輔助工具，但 macOS 有時仍會將其設為待核准狀態。此時選單列圖示會變為警告樣式，顯示「⚠️ 更新後需要重新核准」，並會同時發出通知提醒。
                """,
                recommendation: "首次啟動時出現提示，請核准輔助工具。若尚未核准，選單會顯示「⚠️ 批准輔助工具…」。更新後若出現此提示或通知，同樣可透過「系統設定」>「一般」>「登入項目與擴充功能」重新核准。"
            ),
            LocalizedEntry(
                id: "feat_mcp_server",
                title: "MCP 伺服器整合（供 AI 助理使用的唯讀存取）",
                summary: "RoamSwitch.app 內建唯讀的 MCP（Model Context Protocol）伺服器，讓 Claude 等 AI 助理可以查詢您 Mac 的安全狀態。其中沒有任何可以變更設定或封鎖任何項目的工具。",
                details: """
                • 傳輸方式：僅限本機 stdio。執行檔位置：`/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`。
                • 主要工具：`get_security_report`（安全稽核）、`get_exposed_ports`、`get_guard_status`、`audit_url_safety`、`audit_secrets`、`audit_security_logs`、`get_quarantine_status`、`get_notification_history`、`get_canary_status`、`get_port_anomaly_incidents`、`get_runtime_threat_status`、`get_incident_timeline`（圍堵事件時間軸）、`get_network_history`（網路歷史學習）、`run_package_cve_scan`、`run_package_cve_scan_languages`、`run_active_vuln_scan`（唯一會傳送流量的工具，僅為非破壞性探測至 127.0.0.1），以及 `get_app_help`（本知識庫）。
                • 資源：`roamswitch://docs/features`、`roamswitch://docs/alerts-and-messages`、`roamswitch://docs/settings-guide`、`roamswitch://docs/troubleshooting`。
                • 語言：回答依應用程式的語言設定而定。`get_app_help` 接受 `language` 參數（ja / en / zh-Hans / zh-Hant / ko / de / fr / es / it / pt-PT）。
                • 安全性：由於是唯讀，即使 AI 遭提示注入操縱，也無法變更保護等級或隔離連接埠。
                """,
                recommendation: "設定方式請參見 faq_mcp_setup。您可以用日常語言提問，例如「幫我用 RoamSwitch 確認一下我的 Mac 現在安不安全」或「這則通知是什麼意思？」"
            ),
            LocalizedEntry(
                id: "feat_license_pro_tier",
                title: "Pro 永久授權（單次購買，最多 2 台 Mac）",
                summary: "Pro 是一次性購買的永久授權（¥2,980 / $19.99），最多可用於 2 台 Mac。以 Ed25519 簽署的授權權杖會在裝置端驗證，因此啟用後 Pro 也能離線運作。",
                details: """
                • Pro 功能：選單中標示 (Pro) 的自動防禦（勒索軟體誘餌檔案偵測、XProtect 連動斷網、未知連接埠自動封鎖與開發伺服器隔離、ARP 詐騙自動封鎖、閘道 ARP/NDP 固定、VPN 隧道、BadUSB 與 USB 儲存裝置防護、網頁與郵件保護、DNS 威脅防護、連結保護、Bluetooth 自動關閉、ClickFix 防護、自動啟動註冊監控、Docker 風險偵測、重要檔案竄改監控、自動日誌審計）、即時威脅通知、巡邏警告與排程掃描、日誌 CSV 匯出等。
                • 授權類型：Pro 永久授權（2 台 Mac）與 Team 永久授權（5 台 Mac）。
                • 啟用方式：從「💎 啟用 / 購買 Pro 版…」輸入授權金鑰（ROAM-XXXX-…）。伺服器核發的簽署權杖會以應用程式內建的公開金鑰驗證，並儲存於 Keychain。
                • 解除授權：從授權視窗操作，會從這台 Mac 移除授權並釋放伺服器上的名額（即使網路請求失敗，本機解除授權仍一定會生效）。
                • 授權過期時：Pro 專屬防護會自動關閉，VPN 隧道與連接埠隔離也會被解除。
                """,
                recommendation: "若需要自動圍堵、即時防禦與巡邏警告，可考慮升級 Pro。更換 Mac 時，請先在舊機上解除授權，再於新機上啟用。"
            ),
        ]
    }

    // MARK: - Alerts: network, devices, links

    private static func alertsZhHantNetwork() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "alert_arp_spoofing",
                title: "⚠️ ARP 詐騙（中間人攻擊）警告",
                summary: "顯示於偵測到您網路上有裝置疑似冒充路由器（閘道）以竊聽或竄改流量時。",
                details: """
                • 原因：攻擊者傳送偽造的 ARP 回覆，讓您的流量經過他們（中間人攻擊）。當閘道 IP 不變但 MAC 位址突然改變時即會偵測到。路由器重新開機或 Mesh Wi-Fi 換手也可能造成此現象。
                • 自動防禦：在最大鎖定並啟用「偵測到 ARP 詐騙（網路冒充）時自動封鎖 (Pro)」的情況下，會立即進行氣隙圍堵。其他等級則僅發出通知，選單會顯示「偵測到 ARP 詐騙 — 立即全部斷網」。
                """,
                recommendation: """
                1. 立即停止在此網路上輸入密碼、進行付款或處理工作流量。
                2. 若在公共 Wi-Fi 或任何不熟悉的網路上，請從選單選擇「立即全部斷網」或直接關閉 Wi-Fi。
                3. 若需要網路連線，請改用行動熱點分享或 VPN 隧道等安全連線。
                4. 只有在確定是誤判時（例如剛重新啟動住家路由器）才繼續使用該網路。
                """
            ),
            LocalizedEntry(
                id: "alert_evil_twin_ssid",
                title: "⚠️ 偵測到可能為邪惡雙胞胎的 Wi-Fi 網路",
                summary: "顯示於您加入的 Wi-Fi 名稱（SSID）與過去使用過的網路極為相似時，可能是惡意的假冒基地台（邪惡雙胞胎）。",
                details: """
                • 原因：攻擊者架設一個名稱與合法網路僅差一兩個字元的假基地台以誘騙使用者。網路歷史學習（feat_network_history_guard）會根據與已學習名稱的編輯距離，以及不同的閘道硬體來判斷。
                • 誤判控制：較短的名稱，以及由同一閘道硬體廣播的額外 SSID 不會觸發此警告。
                • 自動防禦：僅發出通知。作為未註冊網路，會套用外出預設保護等級。
                """,
                recommendation: """
                1. 請勿在此 Wi-Fi 上登入或輸入個人資訊。
                2. 確認正式的網路名稱（店內或辦公室的公告），若不相符請立即中斷連線。
                3. 若必須繼續使用，請連接 VPN 隧道。
                """
            ),
            LocalizedEntry(
                id: "alert_unencrypted_wifi",
                title: "⚠️ 已連上未加密的 Wi-Fi",
                summary: "顯示於您加入一個沒有密碼或加密（WPA2 / WPA3）的開放 Wi-Fi，或老舊的 WEP 網路時。",
                details: """
                • 原因：無線連線未加密，附近任何人都能擷取流量。
                • 自動防禦：若該網路未註冊，外出預設保護（初始為最大鎖定）會封鎖連入連線與共享服務。
                """,
                recommendation: """
                1. 若可能，請連接 VPN 隧道，或改用行動熱點分享等受信任的連線。
                2. 避免在非 HTTPS 的網站上登入或輸入個人資訊。
                3. 在選單中確認保護等級為最大鎖定。
                """
            ),
            LocalizedEntry(
                id: "alert_port_anomaly",
                title: "🚨 已自動封鎖未知的監聽連接埠",
                summary: "顯示於某個先前未曾對外開放的程式開始在 0.0.0.0 上向區域網路開放連接埠，且已自動封鎖外部存取時（若封鎖未成功，會顯示「偵測到未知的監聽連接埠（封鎖失敗）」）。",
                details: """
                • 原因：開發伺服器啟動（Next.js、Vite、Python、Docker）、LocalSend 或 Syncthing 等區域網路接收應用程式首次啟動，或是後門程式／惡意程式開始監聽。
                • 自動防禦：pf 只會封鎖外部存取（Mac 本機與 localhost 仍可使用）。macOS 系統常駐程式不在此列。
                """,
                recommendation: """
                1. 請確認通知中顯示的程序名稱、PID 與連接埠是否為您所認得（也可在「外部公開連接埠」中查看）。
                2. 若是您自己的伺服器或區域網路接收應用程式，可用通知中的「允許」按鈕或從連接埠稽核畫面允許，往後就會持續生效。
                3. 開發伺服器建議改以 `127.0.0.1` 綁定後重新啟動，較為安全。
                4. 若不認得，請維持封鎖狀態、結束該程序，並執行安全稽核與病毒掃描。
                """
            ),
            LocalizedEntry(
                id: "alert_exposed_database",
                title: "🚨 未經驗證的資料庫服務已對外公開",
                summary: "顯示於預設常無驗證機制的服務（Redis、MongoDB、Memcached、Elasticsearch）在沒有防火牆保護的情況下對區域網路公開時。",
                details: """
                • 原因：資料庫或後端服務以 0.0.0.0 啟動，而目前的保護等級允許連入連線。同一網路上的任何人都可能讀取或寫入資料。
                • 自動防禦：發出通知（Pro），同一連接埠不會重複通知。
                """,
                recommendation: """
                1. 將該服務的監聽位址改為 `127.0.0.1`，或啟用驗證機制。
                2. 若無法立即修正，可在「外部公開連接埠」中開啟該連接埠並選擇「執行外部隔離」。
                3. 在公共網路上請使用最大鎖定。
                """
            ),
            LocalizedEntry(
                id: "alert_unapproved_keyboard",
                title: "⚠️ 偵測到未經核准的鍵盤／BadUSB 連線",
                summary: "當一個不在允許清單中的新 USB 鍵盤（或偽裝成鍵盤的裝置，如改造的傳輸線）被接上，且其按鍵輸入在核准前已被封鎖時所顯示的通知與核准視窗。",
                details: """
                • 原因：接上新的外接鍵盤或擴充座，或是像 Rubber Ducky 這類按鍵注入裝置。
                • 自動防禦：只有該裝置的按鍵輸入會被封鎖（其他鍵盤仍可正常使用）。「⚠️ 偵測到未知 USB 裝置 / 鍵盤」視窗會要求核准。
                """,
                recommendation: """
                1. 若這是您自行接上、信任的鍵盤，請點選「信任並允許」。它會被加入允許清單並啟用輸入功能。
                2. 若您不認得該裝置，或是在沒有接上任何東西的情況下出現此通知，請點選「拒絕並保持攔截」並拔除該裝置。
                """
            ),
            LocalizedEntry(
                id: "alert_scripted_keyboard",
                title: "🚨 這個鍵盤呈現自動化（腳本）輸入的跡象",
                summary: "顯示於等待核准的鍵盤以人類無法達到的過快且過於均勻的間隔傳送按鍵時，極有可能是自動化指令注入（BadUSB 攻擊）。",
                details: """
                • 原因：Rubber Ducky、Flipper Zero、Arduino / Digispark 等裝置嘗試以高速輸入預先寫好的指令。判斷方式為按鍵節奏分析：累積至少 5 次間隔後，平均值為 12 毫秒以下，或 45 毫秒以下且非常均勻。
                • 自動防禦：該裝置的按鍵輸入在核准前就已被封鎖，從未送達 Mac。此警告只是為您的判斷提供額外證據。
                """,
                recommendation: """
                1. 請務必在核准視窗中選擇「拒絕並保持攔截」。
                2. 立即拔除該裝置，並確認它的來源（撿到的隨身碟、他人贈送的傳輸線等）。
                3. 為求謹慎，請執行安全稽核並檢查自動啟動註冊項目。
                """
            ),
            LocalizedEntry(
                id: "alert_untrusted_usb",
                title: "🔒 USB 儲存裝置已以唯讀方式掛載 / 🔌 已自動封鎖非法 USB 儲存裝置",
                summary: "顯示於一個不在允許清單中的 USB 隨身碟或外接硬碟被接上，並已先以唯讀方式掛載等待您核准，或已被退出時。",
                details: """
                • 原因：接上了未註冊的儲存裝置。此機制可防止資料竊取與惡意檔案被帶入。
                • 自動防禦：以唯讀方式重新掛載，並顯示「是否允許 USB 儲存裝置「…」？」對話框。若選擇「退出」，會退出裝置並發出「已自動封鎖非法 USB 儲存裝置」通知。
                """,
                recommendation: """
                1. 若是您自己的裝置，請選擇「允許讀寫」或「以唯讀方式允許」。它會被加入允許清單，下次接上時會自動套用。
                2. 若不認得該裝置，請選擇「退出」。
                3. 您可稍後在「USB / BadUSB 防護設定…」中變更允許清單。
                """
            ),
            LocalizedEntry(
                id: "alert_malware_usb",
                title: "🚨 在 USB 儲存裝置上偵測到惡意軟體",
                summary: "顯示於 USB 儲存裝置以讀寫方式連接前所執行的 ClamAV 掃描，發現感染檔案時。",
                details: """
                • 原因：USB 隨身碟中存在感染檔案。
                • 自動防禦：立即退出該磁碟區，避免 Mac 本機遭受感染。
                """,
                recommendation: """
                1. 請在另一個安全的環境中重新格式化或清除該磁碟機後再使用。
                2. 執行 ClamAV 快速掃描或資料夾掃描，確認 Mac 本機沒有遭到感染。
                """
            ),
            LocalizedEntry(
                id: "alert_link_guard_blocked",
                title: "🛑 連結保護：連線已被封鎖",
                summary: "顯示於連結保護自動封鎖了與疑似詐騙或釣魚網站的連線時（收錄於威脅情資，或屬於品牌仿冒）。",
                details: """
                • 原因：來自郵件或社群媒體的連結、廣告或應用程式，嘗試連往已知的詐騙網域。
                • 自動防禦：無論使用何種瀏覽器或應用程式，系統延伸功能會捨棄該連線，或由 hosts 備援機制將該網域解析為 0.0.0.0。
                """,
                recommendation: """
                1. 若非您所預期的連線，不需要進一步處理，但請勿在該頁面輸入任何資訊。
                2. 若誤封鎖了您需要使用的合法網站，可使用通知中的「本次允許（5 分鐘）」，或將其加入允許清單。
                """
            ),
            LocalizedEntry(
                id: "alert_link_guard_warn_hold",
                title: "⚠️ 連結保護：連線暫停中",
                summary: "在警告模式下，當與疑似品牌仿冒或詐騙網站的連線因等待您決定是否允許而被暫停時，顯示的通知與最前端面板。",
                details: """
                • 原因：連往觸發警告的網域（子網域仿冒、高風險 TLD 等）。
                • 自動防禦：該連線會暫停，等待您的回應。若約 8 秒內沒有回應則會被封鎖（故障關閉）。此結果不會被快取，因此下次連線仍會再次詢問。您實際做出的選擇則會被記住。
                """,
                recommendation: """
                1. 若這是您刻意開啟且信任的網站，請選擇「允許」。
                2. 若不認得該連線或不確定，請選擇「封鎖」或直接等待（將會自動被封鎖）。
                3. 若是誤封鎖，重新載入頁面即可再次詢問。
                """
            ),
            LocalizedEntry(
                id: "alert_dangerous_url",
                title: "🛑 危險連結／疑似釣魚（連結安全性診斷）",
                summary: "顯示於連結安全性診斷（或 `audit_url_safety`）判定某網址因同形異義字、偽造子網域、高風險 TLD 等因素而危險時。",
                details: """
                • 檢查項目：同形異義字（Punycode）、模仿知名企業的子網域、常見於釣魚攻擊的 TLD、明文 HTTP、直接使用 IP 位址等。
                • 分數：低於 50 分為危險；50 至 79 分為需注意。
                """,
                recommendation: """
                1. 請勿開啟該連結。
                2. 刪除該訊息，若適用可回報給安全負責人員。
                """
            ),
            LocalizedEntry(
                id: "alert_helper_disconnected",
                title: "⚠️ 輔助工具未連線",
                summary: "顯示於無法與特權輔助工具（RoamSwitchHelper）建立 XPC 通訊時。",
                details: """
                • 原因：「登入項目與延伸功能」中未核准背景執行、macOS 更新後輔助工具停止運作，或應用程式不在「應用程式」資料夾中（例如位於下載項目或磁碟映像檔內）。
                • 影響：需要 root 權限的操作（切換保護等級、氣隙圍堵、DNS 設定、重要檔案監控等）都無法執行。
                """,
                recommendation: """
                1. 在選單中選擇「⚠️ 批准輔助工具…」以開啟核准步驟。
                2. 前往「系統設定」→「一般」→「登入項目與延伸功能」，在「允許在背景中執行」中開啟 RoamSwitchHelper。
                3. 確認 RoamSwitch 位於「應用程式」資料夾中。
                4. 若仍無法解決，請依照 faq_helper_troubleshooting 的步驟處理。
                """
            ),
            LocalizedEntry(
                id: "alert_score_drop",
                title: "⚠️ Mac 安全性下降警告",
                summary: "當安全分數低於 80 分，或有 4 個以上項目未通過時，由自主巡邏發出的通知 (Pro)。",
                details: """
                • 原因：設定或環境的變化，例如關閉 FileVault 或防火牆、公開了危險的連接埠，或某項防護被停用。
                • 判斷條件：分數低於 80，或未通過項目達 4 個以上。
                """,
                recommendation: """
                1. 從選單開啟稽核報告（或使用 MCP 工具 `get_security_report`）。
                2. 依照顯示的修正步驟，逐一處理標示 ⚠️ 的項目。
                """
            ),
        ]
    }

    // MARK: - Alerts: malware, containment, audit

    private static func alertsZhHantMalware() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "alert_quarantined_download",
                title: "🚨 已隔離危險的下載檔案",
                summary: "顯示於從瀏覽器、Mail 或聊天應用程式儲存的檔案中含有威脅，並已移至隔離區時（若移動失敗，會顯示「隔離失敗」）。",
                details: """
                • 原因：下載的檔案中含有惡意軟體、木馬程式、反向殼等。
                • 自動防禦：移至 `~/Library/Application Support/RoamSwitch/Quarantine/`，使其無法執行。若是靜態特徵碼檢查標記但 ClamAV 未命中，通知會提及可能為誤判。
                """,
                recommendation: """
                1. 若隔離成功，該檔案已無法執行。
                2. 開啟「📦 管理隔離檔案…」，若不認得該檔案，選擇「徹底刪除」。
                3. 只有在確定為誤判時，才使用「還原」或「排除並還原」。
                4. 若隔離失敗，請手動刪除通知中顯示路徑的檔案。
                """
            ),
            LocalizedEntry(
                id: "alert_eicar_test_signature",
                title: "🧪 偵測到 EICAR 測試特徵碼（無害）— 僅記錄於通知歷史",
                summary: "說明用來測試防毒軟體的無害 EICAR 測試檔如何被處理：由於並非真正的威脅，不會顯示橫幅，也不會被隔離或封鎖，只會被記錄於通知歷史。",
                details: """
                • 適用範圍：無論是網頁與郵件保護、ClamAV 的快速／資料夾掃描，或巡邏的排程掃描皆是如此。
                • 行為：該檔案會維持原狀。「偵測到 EICAR 測試特徵碼（無害）」會被記錄於「🔔 通知歷史…」中。
                • 原因：若對非威脅發出警告橫幅，將會淹沒真正重要的警示。
                """,
                recommendation: """
                1. 不需要任何處理。若您是為了測試而放置該檔案，確認結果後可將其刪除。
                2. 您可以透過檢查通知歷史中是否有此記錄，來確認掃描功能是否正常運作。
                """
            ),
            LocalizedEntry(
                id: "alert_pickle_model",
                title: "⚠️ 偵測到 Pickle 格式的 AI 模型下載",
                summary: "顯示於下載 `.pkl` / `.pickle` / `.pt` 格式的 AI 模型檔時。Pickle 格式只要被載入就可能執行任意程式碼。",
                details: """
                • 原因：從 Hugging Face、Civitai 等下載了模型檔。
                • 自動防禦：僅發出警告（不會隔離該檔案）。
                """,
                recommendation: """
                1. 除非來自受信任的官方來源，否則請勿載入該模型。
                2. 若有可能，請改用相同模型的 `.safetensors` 或 `.gguf` 格式。
                """
            ),
            LocalizedEntry(
                id: "alert_ransomware_activity",
                title: "🚨 【緊急自動防護】已封鎖勒索軟體活動",
                summary: "當誘餌（canary）檔案遭修改、刪除或重新命名，並已觸發氣隙圍堵、共享服務關閉與暫停可疑程序時，所顯示的緊急通知與緊急視窗。",
                details: """
                • 原因：類似勒索軟體的程序試圖加密或破壞您使用者資料夾中的檔案（或執行模擬測試）。
                • 自動防禦：切斷所有流量並關閉 Wi-Fi 無線電、停止 SMB / SSH / 螢幕共享，並暫停（SIGSTOP）可疑程序。緊急視窗會顯示斷網是否成功、可疑程序，以及可能受影響的檔案。
                """,
                recommendation: """
                1. 儲存目前正在編輯的檔案，並結束所有可疑的應用程式。
                2. 在「活動監視器」中查看 CPU 或磁碟寫入異常飆升的程序，並強制結束任何您不認得的程序。
                3. 檢查可能受影響的檔案，以及您的備份（Time Machine 等）。
                4. 確認安全後，從緊急視窗解除圍堵（網路會恢復、暫停的程序會恢復執行、誘餌檔案也會重新產生）。
                """
            ),
            LocalizedEntry(
                id: "alert_runtime_threat_airgap",
                title: "🚨 XProtect 偵測到惡意軟體 — 已自動斷網",
                summary: "顯示於 Apple 的 XProtect / XProtect Remediator 判定某檔案為惡意軟體，且 XProtect 連動自動斷網已啟動氣隙圍堵時的緊急視窗與通知。",
                details: """
                • 原因：Apple 的惡意軟體引擎判定您下載或執行的檔案為惡意。
                • 自動防禦：切斷所有流量並關閉 Wi-Fi 無線電，若未解除則最多 10 分鐘內自動恢復。會記錄偵測到的程序、類別與 Apple 的偵測訊息。
                """,
                recommendation: """
                1. 找出您剛下載或執行的檔案或應用程式並將其刪除。
                2. 執行 ClamAV 掃描與安全稽核，並檢查自動啟動註冊（LaunchAgent）是否有可疑項目。
                3. 確認安全後，從緊急視窗解除圍堵。
                4. 也可透過 MCP 工具 `get_runtime_threat_status` 查看狀態。
                """
            ),
            LocalizedEntry(
                id: "alert_gatekeeper_block",
                title: "🛡️ Gatekeeper 已封鎖未簽署應用程式的執行",
                summary: "macOS Gatekeeper 封鎖了一個沒有簽署或公證的應用程式啟動的通知。不會自動斷網。",
                details: """
                • 原因：您嘗試開啟從網際網路下載的未簽署應用程式，或您自己開發中的建置版本。
                • 自動防禦：無（僅發出通知）。只有在 XProtect 實際偵測到惡意軟體時，才會啟動 XProtect 連動斷網。
                """,
                recommendation: """
                1. 若您認得該應用程式（例如是自己的建置版本），不需要進一步處理。
                2. 若不認得，請以「檢查檔案/應用程式安全性…」確認簽署者，若有可疑之處請刪除。
                """
            ),
            LocalizedEntry(
                id: "alert_clickfix_command",
                title: "🚨 偵測到可疑指令執行 / ⚠️ 剪貼簿中偵測到可疑指令",
                summary: "顯示於在 Terminal 中執行（從殼層歷史記錄偵測）或複製到剪貼簿的指令符合 ClickFix 手法時。",
                details: """
                • 原因：您被誘導至假的驗證碼或假錯誤頁面，並被要求「執行此指令來修復」。反向殼一行指令，以及將 Base64 解碼內容傳給殼層或 osascript 的行為都會被標記。
                • 自動防禦（於 Terminal 執行時，Pro，預設關閉）：氣隙圍堵（不會關閉 Wi-Fi 無線電），最多 10 分鐘內自動恢復。
                • 自動防禦（複製時，預設開啟）：立即清除剪貼簿。
                """,
                recommendation: """
                1. 若只是複製了指令，請關閉該網頁，不要貼上或執行任何內容。
                2. 若已經執行過，請確認 Keychain、瀏覽器儲存的密碼與加密貨幣錢包是否安全，並改用另一台受信任的裝置變更重要密碼。
                3. 檢查自動啟動註冊（LaunchAgent / Daemon）是否有可疑項目，並執行 ClamAV 掃描。
                """
            ),
            LocalizedEntry(
                id: "alert_new_persistence_item",
                title: "🚨 偵測到新的自動啟動註冊",
                summary: "顯示於偵測到新的 LaunchAgent / LaunchDaemon 註冊，並判定為可疑時（直接啟動指令碼直譯器、簽署無效等）。",
                details: """
                • 原因：像資訊竊取程式這類惡意軟體為了在重新開機後存活而自行註冊，或是應用程式安裝程式新增的項目。
                • 自動防禦：僅發出通知（無法阻止註冊本身）。通知會顯示 plist 路徑與判定原因。
                """,
                recommendation: """
                1. 請確認您是否剛自行安裝了某個應用程式。若是，不需要進一步處理。
                2. 若不是，請刪除通知中顯示的 plist，以及它啟動的指令碼或應用程式。
                3. 之後請重新啟動 Mac 並執行 ClamAV 掃描。
                """
            ),
            LocalizedEntry(
                id: "alert_docker_risk",
                title: "⚠️ 偵測到高風險的 Docker 容器設定",
                summary: "通知您一個以 `--privileged` 啟動，或掛載了 `docker.sock` 的容器剛剛啟動。",
                details: """
                • 原因：特權容器與 Docker Socket 掛載讓容器得以控制主機，形成容器逃逸的風險。
                • 自動防禦：無（僅發出通知）。
                """,
                recommendation: """
                1. 若是刻意的設定（例如監控代理程式），不需要進一步處理。
                2. 若非如此，請以 `docker ps` 與 `docker inspect` 檢查該容器並將其停止。
                """
            ),
            LocalizedEntry(
                id: "alert_critical_file_tampering",
                title: "🚨 偵測到重要系統檔案遭竄改",
                summary: "顯示於偵測到 sudoers、SSH 設定、PAM、hosts 或 root 的 authorized_keys 等重要檔案發生變更、刪除或新增時。",
                details: """
                • 原因：管理員的設定變更（`sudo visudo`、編輯 SSH 設定）、軟體造成的變更，或攻擊者藉此提升權限或植入後門。
                • 自動防禦：僅發出通知。新的狀態絕不會自動被視為合法。
                • 相關訊息：「重要系統檔案的竄改偵測目前無法運作」表示因為無法連線特權輔助工具，掃描已連續失敗。
                """,
                recommendation: """
                1. 請確認是否是您本人或管理員變更了通知中顯示的檔案。
                2. 若不是，請檢查 `/etc/sudoers` 中是否有 `NOPASSWD` 設定、`authorized_keys` 中是否有陌生的金鑰等，並將其移除。
                3. 變更管理員密碼並執行安全稽核。
                """
            ),
            LocalizedEntry(
                id: "alert_log_audit_anomaly",
                title: "🔔 日誌審計：偵測到異常模式",
                summary: "當自動日誌審計發現這台 Mac 從未見過的日誌模式（[新增]），或頻率遠高於平常的日誌（[激增 z=…]）時發出的通知。",
                details: """
                • 原因：多半是連接新裝置或應用程式／macOS 更新所帶來的預期變化，但有時也可能是可疑的登入嘗試或未知程序活動。
                • 內容：件數細目、最多 3 行真實日誌、學習進度（例如頻率學習中：目前已觀測 2/3 次），以及白話解釋。
                • 自動防禦：無（僅發出通知）。
                """,
                recommendation: """
                1. 若只有新模式，且沒有不熟悉的應用程式名稱或 IP 位址，不需要進一步處理。
                2. 若頻率激增與您沒有進行過的操作時間重疊，請開啟「📜 Mac 安全日誌審計…」查看詳情。
                3. 若不確定，可使用「複製供 AI 諮詢的資料」向 AI 助理諮詢。
                """
            ),
            LocalizedEntry(
                id: "alert_secret_in_clipboard",
                title: "🔑 剪貼簿中偵測到機密金鑰",
                summary: "告知您剪貼簿中有 API 金鑰或私密金鑰（OpenAI、Anthropic、GitHub、AWS 等）。",
                details: """
                • 原因：您複製了 API 金鑰、權杖或私密金鑰。
                • 自動防禦：僅發出通知（不會清除剪貼簿）。
                """,
                recommendation: """
                1. 請留意不要不小心貼到網站或 AI 聊天室。
                2. 使用完畢後，複製其他文字以覆寫剪貼簿內容。
                3. 若不小心分享出去，請立即在該服務的控制台中撤銷並重新產生金鑰。
                """
            ),
            LocalizedEntry(
                id: "alert_airgap_failed",
                title: "🚨 自動斷網失敗",
                summary: "當嘗試進行緊急斷網（勒索軟體、ARP 詐騙、XProtect 偵測、ClickFix 等）卻無法完成 pf 全面封鎖時，顯示的緊急警告。",
                details: """
                • 原因：特權輔助工具沒有回應（未核准、已停止或逾時）。連續重試 3 次失敗後才會顯示此訊息。
                • 目前狀態：連入流量可能已被「應用程式防火牆」封鎖，但連出流量尚未被切斷。
                """,
                recommendation: """
                1. 立即關閉 Wi-Fi 或拔除網路線。
                2. 處理該威脅（結束程序、執行掃描）。
                3. 之後請檢查輔助工具的狀態（faq_helper_troubleshooting）。
                """
            ),
        ]
    }

    // MARK: - Settings

    private static func settingsZhHant() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "set_trusted_networks",
                title: "已註冊網路與各網路保護等級",
                summary: "將目前的網路註冊為住家、公司、行動熱點分享等，並設定各個網路的保護等級（信任／平衡／最大鎖定）。",
                details: """
                • 註冊方式：「已註冊網路」→「註冊為「家」（信任）」／「註冊為「工作」 (標準保護)」／「註冊為「熱點分享」 (標準保護)」／「使用自訂名稱註冊…」。網路以閘道的 MAC 位址識別。
                • 變更等級：在「目前網路: …」或「已註冊網路 (n)」下選取該網路，並選擇 🟢 / 🟡 / 🔴。
                • 重新命名或移除：重新命名…、解除註冊，或刪除註冊。
                """,
                recommendation: "住家設為 🟢 信任、公司或行動熱點分享設為 🟡 平衡，效果良好。共用的辦公室 Wi-Fi 較安全的做法是不註冊，維持在最大鎖定狀態。"
            ),
            LocalizedEntry(
                id: "set_away_default_level",
                title: "外出預設保護（未註冊網路的等級）",
                summary: "選擇加入未註冊網路時自動套用的保護等級。初始值為 🔴 最大鎖定。",
                details: """
                • 設定方式：選單中的「外出預設保護: …」，選擇 🟢 信任 / 🟡 平衡 / 🔴 最大鎖定。
                • 也會影響以「處於不受信任網路」為條件的功能，例如 DNS 威脅防護（僅外出時）、VPN 自動連線、閘道 ARP/NDP 固定，以及 Bluetooth 自動關閉。
                """,
                recommendation: "若您外出時不使用共享服務或 AirDrop，強烈建議維持最大鎖定。"
            ),
            LocalizedEntry(
                id: "set_manual_override",
                title: "手動覆蓋 & 防止忘記恢復",
                summary: "暫時以手動方式指定保護等級並選擇期限。時間到或網路變更時會自動恢復自動判定，避免您忘記恢復保護。",
                details: """
                • 設定方式：「手動覆蓋」→ 選擇等級（🟢 / 🟡 / 🔴）→ 選擇期限。
                • 期限：直到網路中斷（推薦）、僅 1 小時、僅 4 小時、直到手動解除。
                • 解除方式：「手動覆蓋」→「恢復自動判定」，或選單頂端的「🔄 解除手動指定 (恢復自動)」。
                • 解除氣隙圍堵時，也會一併清除任何手動覆蓋設定。
                """,
                recommendation: "在簡報或開發工作等需要暫時放寬保護時，請使用「直到網路中斷」或「僅 1 小時」，避免外出時忘記恢復保護。"
            ),
            LocalizedEntry(
                id: "set_pro_default_guards",
                title: "啟用 Pro 時自動開啟的防護，與需自行開啟的防護",
                summary: "首次啟用 Pro 授權時，主要的自主防禦防護會自動開啟。此後會依您對各項防護所做的開／關選擇來執行。",
                details: """
                • 自動開啟（僅首次啟用 Pro 時一次）：自動封鎖未知監聽連接埠、勒索軟體誘餌檔案偵測、偵測到 ARP 詐騙時自動封鎖、XProtect 惡意軟體偵測時自動斷網、自動日誌審計，以及定期監控重要系統檔案是否遭竄改。開啟 ARP 與 XProtect 斷網功能時，會顯示一次性說明。
                • Pro 版預設開啟：網頁與郵件保護，以及自動啟動註冊（LaunchAgent/Daemon）監控。
                • 預設關閉（須自行開啟）：ClickFix 自動封鎖、Docker 風險偵測、BadUSB 實體連接埠防護、USB 儲存裝置自動封鎖、閘道 ARP/NDP 固定、VPN 隧道、Bluetooth 自動關閉，以及實證型漏洞驗證。DNS 威脅防護的供應商由您自行選擇。
                • 即使在免費版也預設開啟：剪貼簿保護（API 金鑰與 ClickFix 指令）。
                • 之後版本新增的防護，會為既有的 Pro 使用者套用各自的一次性預設值。授權過期時，Pro 專屬防護會被關閉。
                """,
                recommendation: "啟用 Pro 後，請檢查選單中的 ✅ 標記。不符合您使用情境的防護（例如未使用 Docker）可維持關閉，並開啟您需要的功能（例如經常使用公共 Wi-Fi 就開啟 VPN）。"
            ),
            LocalizedEntry(
                id: "set_usb_whitelist",
                title: "USB / BadUSB 防護設定（鍵盤允許清單 & 儲存裝置權限）(Pro)",
                summary: "在允許清單中管理受信任的鍵盤與工作用 USB 儲存裝置，並將儲存裝置權限設定為唯讀或讀寫。",
                details: """
                • 開啟方式：「連接埠與裝置監控」→「USB / BadUSB 防護設定…」。
                • 鍵盤：在核准視窗中選擇「信任並允許」後即會加入；可在此處移除。
                • 儲存裝置：在連線對話框中選擇「允許讀寫」或「以唯讀方式允許」後即會加入；可在此變更權限或移除。若變更目前未連接的裝置，請拔除並重新插入才能套用變更。
                • 即使是已允許的裝置，連線時的 ClamAV 掃描仍會在升級為讀寫之前執行。
                """,
                recommendation: "在處理敏感資料的 Mac 上，將儲存裝置設為唯讀權限可大幅降低資料外洩風險。"
            ),
            LocalizedEntry(
                id: "set_watched_folders",
                title: "網頁與郵件保護的監控資料夾 (Pro)",
                summary: "新增、移除或重設下載保護（FSEvents 監控與自動掃描）所監控的資料夾。",
                details: """
                • 預設資料夾：`~/Downloads`、`~/Desktop`、`~/Documents`，以及 Mail 的下載資料夾。
                • 編輯方式：「網頁與郵件保護（下載檔案自動掃描）(Pro)」→「📁 監控目標資料夾」→「⚙️ 管理監控資料夾…」。
                • 重設：「🔄 恢復預設」。
                • 最近的掃描記錄（最多顯示 5 筆）與「清除掃描記錄」也位於同一個選單中。
                """,
                recommendation: "若您變更了瀏覽器或聊天應用程式儲存檔案的位置，請務必將該資料夾加入監控清單。"
            ),
            LocalizedEntry(
                id: "set_dns_policy",
                title: "DNS 威脅防護的供應商與政策 (Pro)",
                summary: "選擇用來攔截惡意網域的安全 DNS 供應商，以及套用時機（僅外出時／一律套用）。",
                details: """
                • 設定方式：「DNS 威脅防護（攔截惡意網站與 C2）(Pro)」→「DNS提供商: …」與「⚙️ 套用政策」。
                • 供應商：Quad9（自動攔截惡意軟體與 C2）／Cloudflare Security (1.1.1.2)／AdGuard DNS（攔截威脅與廣告）／CleanBrowsing（安全過濾器）。
                • 政策：「僅在不受信任 Wi-Fi 套用（推薦）」或「在所有網路中一律套用（包含受信任網路）」。選擇僅外出套用時，回到受信任網路會恢復原本的 DNS 設定。
                • 選單中的狀態項目可開啟網路設定，讓您確認目前套用的內容。
                """,
                recommendation: "對大多數人而言，Quad9 搭配僅外出時套用的政策是不錯的選擇。若公司內部需要使用內部 DNS，請避免使用一律套用政策。"
            ),
            LocalizedEntry(
                id: "set_link_guard_modes",
                title: "連結保護的模式、自動更新、系統延伸功能與允許清單 (Pro)",
                summary: "設定連結保護的模式、威脅情資自動更新、系統延伸功能核准狀態，以及如何允許誤封鎖的網站。",
                details: """
                • 模式：「連結保護（釣魚連線偵測）(Pro)」→「關閉」「僅警告（不攔截）」或「自動攔截明顯的釣魚網站（建議）」。警告模式僅在系統延伸功能生效時才能運作。
                • 自動更新：點選「自動更新：開（僅接收）」即可關閉。關閉後仍可依靠內建資料與同形異義字偵測運作。選單中會顯示情資版本與網域數量。
                • 強制點：「強制點：系統延伸功能（支援 DoH）」、「強制點：hosts 備援」、「正在啟用系統延伸功能…」，或系統延伸功能錯誤。等待核准期間會顯示「核准系統延伸功能（開啟「系統設定」）…」。
                • 允許／封鎖：封鎖通知中的「本次允許（5 分鐘）」可暫時允許該網站 5 分鐘。在警告面板中選擇的允許／封鎖會被記住。
                """,
                recommendation: "核准系統延伸功能，並在自動攔截搭配自動更新開啟的狀態下使用，可獲得最有效的保護。"
            ),
            LocalizedEntry(
                id: "set_vpn_backend",
                title: "VPN 隧道後端設定（WireGuard / Tailscale）(Pro)",
                summary: "選擇 VPN 隧道的後端、匯入 WireGuard 設定、選擇 Tailscale 出口節點，並設定終止開關。",
                details: """
                • 開啟方式：「連接埠與裝置監控」→「VPN 隧道 (不受信任網路的中間人攻擊防護) (Pro)」→「後端」。
                • WireGuard：「匯入 WireGuard 設定 (.conf)…」→「在不受信任網路自動連線」。另有「立即連線」「斷線」「刪除設定」。狀態會顯示例如「🟢 已連線（最後交握 N 秒前）」，終止開關永遠開啟。若未安裝 `wireguard-tools`，會顯示安裝指引。
                • Tailscale：在「出口節點」中選擇一個節點（選擇「（無 — 保護關閉）」以停用）。另有「重新整理候選」與「重新整理狀態」。「終止開關：開（防洩漏）」為選用項目，預設關閉。
                • 狀態列範例：「⚪️ 待命（在不受信任的網路上自動連線）」、「🟡 所選出口節點已離線」。
                """,
                recommendation: "若您已在使用 Tailscale，請選擇 Tailscale；否則使用 VPN 供應商提供的 WireGuard 設定檔是最簡便的方式。"
            ),
            LocalizedEntry(
                id: "set_language",
                title: "顯示語言（應用程式與 MCP 回答語言）",
                summary: "RoamSwitch 可顯示 10 種語言（日本語、English、简体中文、繁體中文、한국어、Deutsch、Français、Español、Italiano、Português）。MCP 伺服器的回答與本知識庫都會使用相同的語言。",
                details: """
                • 設定方式：在選單「語言 / Language」中選擇。「依照系統設定」會使用 macOS 的偏好語言。
                • MCP：MCP 伺服器會讀取應用程式中選擇的語言。若依照系統設定但系統語言不受支援，則會以英文回答。
                • `get_app_help` 工具接受 `language` 參數，可依每次呼叫個別指定回答語言。搜尋則可以任何語言的關鍵字比對。
                """,
                recommendation: "若想以與應用程式不同的語言與 AI 助理互動，請使用 `get_app_help` 的 `language` 參數。"
            ),
        ]
    }

    // MARK: - Troubleshooting: setup

    private static func troubleshootingZhHantSetup() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "faq_free_vs_pro",
                title: "免費版與 Pro 永久版的差異",
                summary: "免費版即包含依網路自動切換保護、18 項安全稽核，以及一系列手動檢查工具，且沒有時間限制。Pro 版則解鎖自動圍堵、即時防禦與巡邏警告。",
                details: """
                【免費版】
                • 依網路自動切換 3 個等級的 PF 封包過濾器，共享服務與 AirDrop 會自動停止並恢復
                • Mac 安全稽核（18 個項目）、XProtect 狀態，以及檔案／應用程式安全性檢查
                • 顯示公開連接埠與 USB 裝置清單
                • 連結安全性診斷、手動機密資訊／API 金鑰洩露稽核、剪貼簿保護
                • 套件 CVE 掃描、實證型漏洞驗證、Mac 安全日誌審計、通知歷史
                • 手動 ClamAV 掃描與隔離管理
                • MCP 伺服器整合
                【Pro 永久版（單次購買 ¥2,980 / $19.99，最多 2 台 Mac）】
                • 具氣隙功能的勒索軟體誘餌檔案偵測、XProtect 連動自動斷網、ClickFix 防護
                • 未知監聽連接埠自動封鎖、開發伺服器隔離
                • ARP 詐騙自動封鎖、閘道 ARP/NDP 固定、VPN 隧道（WireGuard / Tailscale）、邪惡雙胞胎警告
                • BadUSB 鍵盤防護、USB 儲存裝置自動封鎖
                • 網頁與郵件保護（自動掃描、隔離、Pickle 警告）、DNS 威脅防護、連結保護
                • 自動啟動註冊監控、Docker 風險偵測、重要檔案竄改監控、自動日誌審計
                • Bluetooth 自動關閉、即時威脅通知、巡邏警告、特徵庫更新與排程掃描、日誌 CSV 匯出
                """,
                recommendation: "若您需要自動圍堵、即時防禦與背景監控，請選擇 Pro 版。"
            ),
            LocalizedEntry(
                id: "faq_homebrew_clamav",
                title: "設定 ClamAV（病毒掃描）與 Homebrew",
                summary: "病毒掃描功能使用開源的 ClamAV，可透過 Homebrew 安裝。即使未安裝，XProtect 整合以及 RoamSwitch 本身的所有功能仍能正常運作。",
                details: """
                • Homebrew：macOS 的套件管理工具（https://brew.sh/）。
                • 步驟：
                  1. 在 Terminal 中執行 Homebrew 的官方安裝指令（詳見 https://brew.sh/）。
                  2. 執行 `brew install clamav`。選單中的「📥 透過 Homebrew 安裝 ClamAV…」也能開啟安裝指引。
                  3. 選擇「🛡️ ClamAV (免費防毒軟體)」→「🔄 立即更新病毒特徵庫」。
                • 需要 ClamAV 才能使用的功能：快速掃描（下載／桌面）、資料夾掃描、網頁與郵件保護及 USB 儲存裝置的掃描，以及巡邏的排程掃描。
                • 未安裝 ClamAV 時：封包過濾、連接埠監控、連結分析、靜態特徵碼檢查等功能仍可正常運作。
                """,
                recommendation: "若希望下載檔案與 USB 儲存裝置能自動掃描，建議安裝 Homebrew 與 ClamAV。"
            ),
            LocalizedEntry(
                id: "faq_blueutil_setup",
                title: "Bluetooth 自動關閉 (Pro) 與 blueutil 設定",
                summary: "外出時自動關閉 Bluetooth 的功能，需要安裝開源工具 `blueutil`。",
                details: """
                • 背景：macOS 沒有讓應用程式切換 Bluetooth 電源的公開 API，因此使用 CLI 工具 `blueutil`。
                • 步驟：
                  1. 在 Terminal 中執行 `brew install blueutil`（或使用選單中的「📥 透過 Homebrew 安裝 blueutil…」）。
                  2. 啟用「連接埠與裝置監控」→「在不受信任的網路自動關閉 Bluetooth (Pro)」。
                • 若尚未安裝：不會影響其他功能，選單會顯示「🔵 Bluetooth 自動關閉（未安裝）」。
                """,
                recommendation: "為避免公共 Wi-Fi 上的電波追蹤與 Bluetooth 漏洞，請執行 `brew install blueutil` 並開啟此功能。"
            ),
            LocalizedEntry(
                id: "faq_helper_troubleshooting",
                title: "出現「⚠️ 輔助工具未連線」時的處理方式",
                summary: "當 RoamSwitch 無法與特權輔助工具（RoamSwitchHelper）通訊時的復原步驟。",
                details: """
                1. 在選單中選擇「⚠️ 批准輔助工具…」，並依照顯示的步驟操作。
                2. 開啟「系統設定」→「一般」→「登入項目與延伸功能」，確認 RoamSwitchHelper 在「允許在背景中執行」中已開啟。
                3. 確認 RoamSwitch 位於「應用程式」資料夾中（faq_install_location）。
                4. 在導覽視窗中按下「重試註冊輔助工具」。
                5. 若仍失敗，可在 Terminal 執行 `sudo killall RoamSwitchHelper` 重新啟動輔助工具（launchd 會自動重新啟動它），再重新啟動 RoamSwitch。
                """,
                recommendation: "若 macOS 更新後輔助工具立即停止回應，請先檢查登入項目的開關，再嘗試 `sudo killall RoamSwitchHelper`。"
            ),
            LocalizedEntry(
                id: "faq_install_location",
                title: "應用程式安裝位置（從「應用程式」資料夾以外啟動）",
                summary: "macOS 不會為位於「應用程式」資料夾以外的應用程式註冊特權輔助工具，因此 RoamSwitch 必須放在 `/Applications` 或 `~/Applications` 中並從那裡啟動。",
                details: """
                • 無法註冊的位置：下載項目或桌面、仍掛載中的磁碟映像檔（.dmg）內執行，或是 Gatekeeper App Translocation 已將應用程式移到暫時的唯讀位置。
                • 指引：導覽流程會在啟動時檢查安裝位置，並提供「移動到「應用程式」並重新啟動」或「在 Finder 中開啟「應用程式」」的選項。
                • 移動後：按下「重新檢查」或重新啟動，再核准輔助工具。
                """,
                recommendation: "請將 RoamSwitch 從磁碟映像檔拖曳到「應用程式」資料夾，並從該處啟動。"
            ),
            LocalizedEntry(
                id: "faq_system_extension_approval",
                title: "核准連結保護的系統延伸功能",
                summary: "為使連結保護發揮最佳效果（支援 DoH、警告模式），必須核准內容過濾系統延伸功能。在核准之前，會使用 /etc/hosts 備援機制。",
                details: """
                • 步驟：「連結保護（釣魚連線偵測）(Pro)」→「核准系統延伸功能（開啟「系統設定」）…」→「系統設定」→「一般」→「登入項目與延伸功能」，允許 RoamSwitch 的網路延伸功能。
                • 核准後：選單會顯示「強制點：系統延伸功能（支援 DoH）」。
                • 若顯示系統延伸功能錯誤：請確認應用程式位於「應用程式」資料夾中，然後重新選擇一次連結保護的模式以重試。
                • 此方式不需要 App Store 審核或申請額外授權（採用 Developer ID 簽署並公證）。
                """,
                recommendation: "核准系統延伸功能，即使瀏覽器使用 DNS over HTTPS，保護也能持續生效。"
            ),
            LocalizedEntry(
                id: "faq_mcp_setup",
                title: "設定 MCP 伺服器（Claude Desktop、Claude Code 等）",
                summary: "如何將 RoamSwitch 內建的 MCP 伺服器註冊到支援 MCP 的 AI 用戶端。",
                details: """
                • 執行檔路徑：`/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`
                • Claude Desktop：在 `~/Library/Application Support/Claude/claude_desktop_config.json` 的 `mcpServers` 中，將執行檔路徑加為 `command`。
                • Claude Code：`claude mcp add roamswitch /Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`
                • 其他用戶端（Codex CLI 等）的設定方式：https://lafine.net/mcp-setup.html
                • 回答語言：依應用程式「語言 / Language」設定而定。`get_app_help` 每次呼叫都可帶入 `language` 參數。
                • 通訊僅限本機 stdio，不會對外傳送任何內容（僅 `run_active_vuln_scan` 會傳送非破壞性探測至 127.0.0.1）。
                """,
                recommendation: "註冊完成後，可以請 AI「用 RoamSwitch 幫我確認一下這台 Mac 現在的安全狀態」，它就會為您解說稽核結果。"
            ),
        ]
    }

    // MARK: - Troubleshooting: operation

    private static func troubleshootingZhHantOperation() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "faq_network_cut_off",
                title: "網路突然中斷（氣隙圍堵／保護等級）",
                summary: "可能是 RoamSwitch 的緊急氣隙或最大鎖定正在阻擋流量。如何找出原因並解除。",
                details: """
                • 檢查方式：查看是否有緊急視窗，並檢查通知歷史中是否有【緊急自動防護】、XProtect、ARP 詐騙或可疑指令執行等警示。Wi-Fi 無線電也可能已被關閉。
                • 解除方式：使用緊急視窗或通知中的解除按鈕。網路與 Wi-Fi 無線電會恢復。
                • 自動恢復：即使沒有解除，輔助工具的保護機制也會在 10 分鐘內恢復網路。結束應用程式、當機或重新開機後都不需要手動操作。
                • 剛開機後：開機閘最多可能在 90 秒內限制網路流量。
                • 其他原因：最大鎖定會封鎖連入連線，但不會阻止一般的連出使用，例如瀏覽網頁。也請檢查 VPN 終止開關（隧道中斷期間）、DNS 威脅防護的解析設定，以及連結保護的封鎖情況。
                """,
                recommendation: "圍堵啟動時，請先閱讀觸發的通知，確認安全後再解除。若某項防護經常誤觸發，可從選單個別關閉該項防護。"
            ),
            LocalizedEntry(
                id: "faq_quarantine_false_positive",
                title: "還原誤判隔離的下載檔案",
                summary: "如何還原被誤判為威脅並隔離的自製指令碼或開發用執行檔，並將其排除於掃描之外。",
                details: """
                1. 開啟「惡意軟體防護」→ ClamAV →「📦 管理隔離檔案…」。
                2. 在隔離的檔案清單中選取該檔案（會顯示原始路徑、威脅名稱與隔離時間）。
                3. 若確定為誤判，按下「排除並還原」：檔案會回到原始位置，並排除於未來的掃描之外。若只想還原一次，請按下「還原」。
                4. 若要取消排除，可在同一個視窗的已排除路徑清單中按下「取消排除」。
                5. 若要停止監控整個資料夾，請在網頁與郵件保護中調整「⚙️ 管理監控資料夾…」。
                """,
                recommendation: "若您無法確定某個檔案是否安全，請不要還原它，選擇「徹底刪除」即可。"
            ),
            LocalizedEntry(
                id: "faq_eicar_test",
                title: "放置了 EICAR 測試檔卻沒有收到通知",
                summary: "這是設計上的行為。EICAR 測試特徵碼是無害的測試，因此不會顯示橫幅，也不會被隔離。此次偵測會被記錄於通知歷史中。",
                details: """
                • 確認方式：檢查「Mac 安全稽核」→「🔔 通知歷史…」中是否有「偵測到 EICAR 測試特徵碼（無害）」的記錄。
                • 檔案狀態：維持原狀。
                • 若要測試真正的警示流程：可使用「惡意軟體防護」底部的模擬功能（勒索軟體防禦、惡意軟體偵測氣隙、Docker 風險偵測）。
                """,
                recommendation: "測試完成後請刪除 EICAR 檔案。"
            ),
            LocalizedEntry(
                id: "faq_dev_server_blocked",
                title: "我的開發伺服器或區域網路接收應用程式無法從其他裝置存取",
                summary: "未知監聽連接埠自動封鎖功能，可能封鎖了一個剛開始對外開放連接埠的程式。從 Mac 本機仍可正常存取。",
                details: """
                • 檢查方式：在通知歷史中尋找「已自動封鎖未知的監聽連接埠」。
                • 允許方式：使用通知中的「允許」按鈕，或從「外部公開連接埠」→ 該連接埠 → 連接埠稽核畫面允許。允許狀態會針對該執行檔永久生效。
                • 與手動隔離的差異：您自行以「執行外部隔離」隔離的連接埠，須在連接埠稽核畫面中以「解除隔離」還原。
                • 保護等級：在最大鎖定的網路上，防火牆會完全封鎖連入連線。若要允許區域網路存取，請將該網路註冊並設為平衡或信任。
                """,
                recommendation: "像 LocalSend 或 Syncthing 這類經常使用的區域網路接收應用程式，只要允許一次，之後就不會再被封鎖。"
            ),
            LocalizedEntry(
                id: "faq_link_guard_false_block",
                title: "連結保護誤封鎖合法網站／連線持續暫停中",
                summary: "當連結保護誤封鎖某網站，或以警告模式將其暫停時的處理方式。",
                details: """
                • 暫時允許：使用封鎖通知中的「本次允許（5 分鐘）」。
                • 永久允許：在警告面板中選擇「允許」會被記住。
                • 暫停的連線自動被封鎖：警告模式若約 8 秒內沒有回應就會封鎖（故障關閉）。此結果不會被快取，因此重新載入頁面會再次詢問。
                • 看不到通知：橫幅式通知樣式可能會隱藏按鈕，因此也會顯示最前端面板。若在專注模式中，請檢查通知歷史。
                • 暫時停用：將模式切換為「僅警告（不攔截）」或「關閉」。
                """,
                recommendation: "若工作工具持續被封鎖，請先確認網域名稱是否有拼字錯誤或仿冒，再決定是否允許。"
            ),
            LocalizedEntry(
                id: "faq_keyboard_blocked",
                title: "我的外接鍵盤無法輸入（BadUSB 防護）",
                summary: "BadUSB 實體連接埠防護正在封鎖一個不在允許清單中的鍵盤，直到您核准為止。",
                details: """
                • 核准方式：在「⚠️ 偵測到未知 USB 裝置 / 鍵盤」視窗中點選「信任並允許」（可使用內建鍵盤或觸控式軌跡板操作）。
                • 找不到視窗：拔除並重新插入該裝置即可重新顯示。
                • 擴充座與 KVM 切換器：內建鍵盤功能的裝置也在涵蓋範圍內。若是您自己的裝置，請予以允許。
                • 輔助使用權限：當裝置無法被獨佔佔用時，所使用的替代封鎖方式依賴輔助使用權限。
                • 撤銷允許：可在「USB / BadUSB 防護設定…」中移除。
                """,
                recommendation: "若某裝置觸發了腳本輸入警告，請不要允許它，並將其拔除。"
            ),
            LocalizedEntry(
                id: "faq_vpn_troubleshooting",
                title: "VPN 隧道無法連線／流量無法通過",
                summary: "當 WireGuard 或 Tailscale 後端無法正常運作時的檢查事項。",
                details: """
                • WireGuard：確認已安裝 `brew install wireguard-tools`，並已匯入 `.conf` 檔。若狀態顯示「🟡 無回應（最後交握 …）」，請檢查 VPN 伺服器，以及設定檔中的金鑰與端點。由於終止開關為開啟狀態，隧道建立完成前不會有任何流量通過。
                • Tailscale：確認已安裝 CLI 並已登入（否則選單會顯示「請先登入 Tailscale」），並已選擇出口節點。若所選出口節點已離線，請改選其他節點。
                • App Store 版的 Tailscale：無法從應用程式外部設定出口節點，請在 Tailscale App 內選擇。
                • Tailscale 終止開關：在某些網路環境下可能會干擾 Tailscale 自身的連線；若無法連線，請將其關閉。
                • 在受信任網路上自動斷線是正常的行為。
                """,
                recommendation: "請先查看選單中的狀態列：WireGuard 看交握狀態，Tailscale 看出口節點狀態。"
            ),
            LocalizedEntry(
                id: "faq_log_audit_repeated_alerts",
                title: "日誌審計通知一直出現",
                summary: "自動日誌審計會在執行過程中學習這台 Mac 平常的日誌行為。剛設定完成或進行重大更新後，通知會較多，隨著學習進行會自然減少。",
                details: """
                • 新模式：一經回報就會成為已知，同樣內容不會再重複通知。
                • 頻率激增：每個範本的學習會在觀測 3 次後完成，之後正常的量就不會再警告。當通知顯示類似「頻率學習中: 目前已觀測 2/3 次」時，表示仍在學習中。
                • 常見原因：macOS 或應用程式更新、連接新裝置、暫時的高負載。
                • 如何停止：在選單中關閉「自動記錄稽核(定期學習新模式與頻率異常) (Pro)」（手動日誌審計仍可正常使用）。
                """,
                recommendation: "除非警告中包含不熟悉的應用程式名稱、IP 位址或 sudo 失敗，否則可以先觀察一段時間。"
            ),
            LocalizedEntry(
                id: "faq_zero_telemetry",
                title: "Zero Telemetry 隱私設計",
                summary: "RoamSwitch 及其 MCP 伺服器絕不會將稽核結果、網址、連接埠資訊、日誌或檔案內容傳送到外部伺服器。唯一的網路流量僅限以下明確列出的例外情況。",
                details: """
                • 完全在地執行：安全稽核、連接埠監控、連結分析、機密資訊稽核、日誌審計、病毒掃描與 MCP 通訊，全部都在裝置端完成。
                • 例外情況：
                  - 授權啟用與解除授權（僅在您操作時發生）以及開啟購買頁面
                  - 應用程式更新檢查（Sparkle）
                  - ClamAV 特徵庫更新（`freshclam`）
                  - 每天下載連結保護的威脅情資、套件 CVE 對應表與漏洞 CVE 對應表（僅接收、經簽署驗證、不傳送任何識別碼；連結保護的自動更新可以關閉）
                  - 與您所設定的 VPN 與安全 DNS 供應商之間的一般流量
                  - 實證型漏洞驗證針對 127.0.0.1（這台 Mac 本機）的非破壞性探測
                • 程式碼中完全沒有任何遙測或使用情況蒐集。即使是輔助工具核准提醒功能，也只依賴裝置端的計數運作。
                """,
                recommendation: "即使在高機密的商業環境或個人開發環境中，也能安心使用而不必擔心資料外洩。"
            ),
        ]
    }
}
