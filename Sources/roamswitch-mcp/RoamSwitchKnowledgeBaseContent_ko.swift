// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.40 (build 97).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

// Korean (ko) content for `RoamSwitchKnowledgeBase`.
// Translated from the English source (`RoamSwitchKnowledgeBaseContent_en.swift`).
// Every entry id here must also exist in every other
// `RoamSwitchKnowledgeBaseContent_<lang>.swift` file.
extension RoamSwitchKnowledgeBase {
    static func labelsKo() -> MarkdownLabels {
        return MarkdownLabels(
            featuresTitle: "RoamSwitch 전체 기능 명세 및 아키텍처 가이드",
            featuresIntro: "RoamSwitch의 모든 보안 기능이 어떻게 동작하는지, 기본값과 한계는 무엇인지 상세히 설명합니다.",
            alertsTitle: "RoamSwitch 알림 및 경고 메시지 대응 가이드",
            alertsIntro: "RoamSwitch가 표시하는 모든 알림 배너, 경고, 긴급 창을 원인, 자동으로 취해지는 방어 조치, 권장 단계별 대응과 함께 정리했습니다.",
            settingsTitle: "RoamSwitch 설정 및 운영 가이드",
            settingsIntro: "RoamSwitch의 모든 설정, 전환 스위치, 허용 목록, 정책에 대한 단계별 안내입니다.",
            troubleshootingTitle: "RoamSwitch 문제 해결 및 자주 묻는 질문",
            troubleshootingIntro: "자주 묻는 질문, 권한과 승인, Homebrew / ClamAV / blueutil 설치, 오탐 처리, 개인정보 보호 설계에 대한 공식 답변입니다.",
            summary: "요약",
            overview: "개요",
            detailsHeading: "세부 정보와 원인",
            adviceHeading: "대처 방법",
            recommendation: "권장 사항",
            bestPractice: "권장 설정",
            advice: "조언"
        )
    }

    static func contentKo() -> [LocalizedEntry] {
        var list: [LocalizedEntry] = []
        list.append(contentsOf: featuresKoNetwork())
        list.append(contentsOf: featuresKoMalware())
        list.append(contentsOf: featuresKoAudit())
        list.append(contentsOf: alertsKoNetwork())
        list.append(contentsOf: alertsKoMalware())
        list.append(contentsOf: settingsKo())
        list.append(contentsOf: troubleshootingKoSetup())
        list.append(contentsOf: troubleshootingKoOperation())
        return list
    }

    // MARK: - Features: network & devices

    private static func featuresKoNetwork() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_network_autoswitch",
                title: "자동 네트워크 보안 전환 & PF 패킷 필터 (3단계)",
                summary: "현재 네트워크의 게이트웨이 MAC 주소를 등록된 네트워크와 비교하여 해당 네트워크의 보호 수준을 자동으로 적용합니다. 등록되지 않은 네트워크에는 외부 기본 보호 수준(초기값은 최대 잠금)이 적용됩니다. 무료 버전에서도 사용할 수 있습니다.",
                details: """
                • 🟢 신뢰함 (개방 - 보호 해제): 예를 들어 집. 방화벽 해제, 공유 서비스(SSH / SMB / 화면 공유)와 AirDrop 허용.
                • 🟡 표준 보호 (방화벽과 스텔스): 예를 들어 회사나 테더링. PF 패킷 필터와 스텔스 모드로 외부 탐색을 차단하면서 공유 서비스는 유지.
                • 🔴 최대 잠금 (공유・AirDrop 정지): 카페, 공용 Wi-Fi, 등록되지 않은 네트워크. 모든 수신 차단, 공유 데몬 정지, AirDrop 비활성화.
                • 판단 방식: 네트워크가 변경되면 게이트웨이의 MAC 주소를 읽어 등록된 네트워크와 비교합니다. 게이트웨이가 바뀌지 않는 경로 이벤트(DHCP 갱신, Wi-Fi 로밍)는 전체 재판정을 일으키지 않습니다.
                • 내부 구조: 특권 헬퍼 `RoamSwitchHelper`(XPC 경유)가 전용 `pfctl` 앵커를 관리하여 커널 수준에서 패킷을 폐기합니다.
                • 수동 오버라이드: 수동 오버라이드에서 각 등급별로 다음 네트워크 연결 해제 시까지(권장), 1시간 동안, 4시간 동안, 해제할 때까지 유지 중에서 선택할 수 있습니다(set_manual_override 참조).
                """,
                recommendation: "현재 네트워크를 등록에서 집과 안전한 사무실을 등록하고, 그 외의 모든 장소에서는 최대 잠금이 자동으로 적용되도록 두세요."
            ),
            LocalizedEntry(
                id: "feat_network_history_guard",
                title: "네트워크 이력 학습 & 이블 트윈(유사 Wi-Fi) 탐지 (Pro)",
                summary: "이 Mac에서만 각 Wi-Fi SSID가 사용한 게이트웨이 MAC 주소를 학습하고, 이전에 사용했던 네트워크와 이름이 의심스러울 정도로 비슷한 미지의 SSID에 연결하면 이블 트윈(가짜 액세스 포인트)일 가능성을 경고합니다.",
                details: """
                • 학습 내용: 각 SSID별로 관측된 게이트웨이 MAC 주소(메시 Wi-Fi를 위해 SSID당 최대 8개)를 `~/Library/Application Support/RoamSwitch/network_history.json`에 저장합니다. 최대 200개 SSID까지 보관하며, 가장 오래된 것부터 제거됩니다. 어떤 정보도 기기 밖으로 전송되지 않습니다.
                • 유사도 판정: 대소문자를 구분하지 않는 편집 거리(레벤슈타인 거리)를 사용합니다. 6자 미만의 이름은 대상에서 제외되며, 허용 거리는 이름 길이에 따라 완만하게 늘어나므로(1~2자), "ASUS"나 "TP-Link_5G"처럼 흔한 기본 SSID가 우연히 겹쳐도 절대 경고를 일으키지 않습니다.
                • 오탐 방지: 같은 게이트웨이 장비가 두 번째 SSID(게스트 네트워크, 이름을 바꾼 라우터)를 방송하는 경우는 표시되지 않습니다. 이미 알려진 SSID가 새로운 게이트웨이 MAC과 함께 관측된 경우(라우터 교체)는 기록만 될 뿐 그 자체로는 경고하지 않습니다.
                • ARP 스푸핑이 감지되는 동안에는 관측을 건너뛰어, 공격자의 MAC이 정당한 것으로 학습되지 않도록 합니다.
                • 이 경고는 Pro에서 발송되는 실시간 알림입니다. 학습된 이력은 MCP 도구 `get_network_history`로 확인할 수 있습니다.
                """,
                recommendation: "이 경고를 받으면 해당 Wi-Fi에서 계정 정보를 입력하지 말고 실제 네트워크 이름과 위치를 확인하세요. VPN 터널(feat_vpn_tunnel)이 가장 확실한 대응책입니다."
            ),
            LocalizedEntry(
                id: "feat_arp_spoof_guard",
                title: "ARP 스푸핑(네트워크 위장) 탐지 & 자동 차단 (Pro)",
                summary: "같은 네트워크의 공격자가 라우터로 위장하여 트래픽을 도청하거나 변조하는 ARP 스푸핑(중간자 공격)을 탐지합니다. 최대 잠금 네트워크에서는 즉시 네트워크를 차단하고, 다른 등급에서는 알림만 보내고 판단은 사용자에게 맡깁니다.",
                details: """
                • 탐지 방식: 기본 게이트웨이의 IP는 그대로인데 MAC 주소가 갑자기 바뀌는 것을 감지합니다. 네트워크 변경 이벤트 외에도 전용 15초 폴링을 통해 세션 도중에 시작되는 공격도 포착합니다.
                • 대응 방식: 최대 잠금 네트워크에서는 즉시 에어갭 봉쇄(feat_airgap_containment)를 실행합니다. 신뢰함 또는 표준 보호 네트워크에서는 알림만 보내며, 포트・기기 모니터링에서 "ARP 스푸핑 감지 — 지금 전체 차단"을 선택해 수동으로 봉쇄를 실행할 수 있습니다. 이는 라우터 재부팅이나 메시 로밍으로 인한 오작동을 방지하고, 위조된 ARP 패킷 하나로 자체 정전을 유발하는 무기화를 막기 위한 것입니다.
                • 기본값: Pro 라이선스를 처음 활성화할 때 메뉴 항목 "ARP 스푸핑(네트워크 위장) 감지 시 자동 차단 (Pro)"이 자동으로 켜집니다(set_pro_default_guards).
                • 위치: 이것은 사후 대응입니다. 사전 예방은 게이트웨이 ARP/NDP 고정(feat_gateway_arp_lock)과 VPN 터널(feat_vpn_tunnel)이 담당합니다.
                • 사고는 MITRE ATT&CK T1557로 사고 타임라인(feat_containment_incident_timeline)에 기록됩니다.
                """,
                recommendation: "계속 켜 두세요. 더 강력한 중간자 공격 대응이 필요하면 VPN 터널을 추가하고, 추가 인프라 없이 사전 예방을 원하면 게이트웨이 ARP/NDP 고정을 추가하세요."
            ),
            LocalizedEntry(
                id: "feat_gateway_arp_lock",
                title: "게이트웨이 ARP/NDP 고정 (예방적) (Pro)",
                summary: "신뢰할 수 없는 네트워크에 연결하면 게이트웨이, IPv6 라우터, 동일 링크상의 DNS 서버의 MAC 주소를 정적 네이버 캐시 항목으로 고정하여 ARP/NDP 스푸핑에 의한 중간자 공격을 사전에 방지합니다. 기본값은 꺼짐입니다.",
                details: """
                • 활성화 방법: 포트・기기 모니터링 → "미신뢰 네트워크에서 게이트웨이 ARP/NDP 고정(예방) (Pro)".
                • 동작 방식: 연결 시 현재 MAC 주소를 읽고, 헬퍼가 `arp -s` / `ndp -s`로 영구 항목으로 고정합니다. 이후 커널은 해당 IP에 대한 위조 ARP 응답과 네이버 광고를 무시합니다.
                • 범위: 위 세 가지 항목만 해당합니다. 신뢰함(개방) 네트워크에서는 고정하지 않으므로 집 라우터를 재부팅해도 연결이 끊기지 않습니다. 네트워크가 바뀔 때마다 해제하고 다시 고정합니다.
                • 한계(최초 사용 시 신뢰): 처음 관측된 MAC을 신뢰하므로, 연결하기 전부터 공격자가 이미 있었다면 그 MAC이 고정될 수 있습니다. 이 전제를 받아들일 수 없다면 VPN 터널을 사용하세요.
                • Mac 보안 진단의 "게이트웨이 ARP 고정 (예방적 MITM 대책)" 항목에 반영됩니다.
                """,
                recommendation: "VPN을 사용하기 어려울 때 가벼운 중간자 공격 대책으로 유용합니다. VPN 터널과 함께 사용할 수도 있습니다(VPN이 주된 방어, 이것은 보조 수단)."
            ),
            LocalizedEntry(
                id: "feat_vpn_tunnel",
                title: "VPN 터널 (WireGuard / Tailscale, 킬 스위치 포함) (Pro)",
                summary: "신뢰할 수 없는 네트워크에서 암호화된 터널을 자동으로 연결하여 중간자 공격이 암호문만 보게 만듭니다. WireGuard(설정 파일) 또는 Tailscale(exit node)을 백엔드로 선택할 수 있습니다. L2(ARP/NDP)의 무결성에 의존하지 않아 중간자 공격 대책의 핵심입니다. Network Extension 권한이 필요 없습니다.",
                details: """
                • 백엔드: 포트・기기 모니터링 → "VPN 터널 (미신뢰 네트워크의 MITM 대응) (Pro)" → 백엔드에서 WireGuard 또는 Tailscale을 선택합니다. 선택한 백엔드만 동작합니다.
                • WireGuard: Homebrew의 `wireguard-tools`(`brew install wireguard-tools`)가 필요합니다. "WireGuard 설정(.conf) 가져오기…"로 설정 파일을 불러옵니다. 설정 파일은 사용자가 직접 준비해야 합니다(Mullvad, IVPN, Proton VPN, 자체 서버, 회사 제공 등). RoamSwitch는 VPN 서버를 제공하지 않습니다.
                • WireGuard 킬 스위치: pf가 "block drop all"을 적용하고 lo, 터널 인터페이스, 엔드포인트로의 UDP 핸드셰이크, DHCP, ICMP만 통과시킵니다. 터널이 끊긴 동안에는 어떤 평문도 유출되지 않습니다.
                • Tailscale: 이미 Tailscale을 사용 중인 사람들을 위한 것입니다. RoamSwitch는 설치나 로그인을 하지 않고 `tailscale status`를 읽어 `tailscale set --exit-node=<노드>`를 실행할 뿐입니다. exit node 지정이 필수입니다(모든 트래픽이 그곳을 거칩니다). 선택한 exit node가 오프라인이면 상태 표시줄에 나타납니다.
                • Tailscale CLI(독립 실행형) 권장: `brew install tailscale` → `sudo tailscaled install-system-daemon` → `sudo tailscale up`. App Store(GUI) 버전은 앱 외부에서 `tailscale set`으로 제어할 수 없으므로, Tailscale 앱에서 exit node를 선택하고 RoamSwitch는 상태 표시와 킬 스위치만 담당합니다.
                • Tailscale 킬 스위치(기본 꺼짐, 선택적 사용): pf가 lo, Tailscale의 utun, CGNAT 100.64.0.0/10, DNS, STUN 3478, 41641, DERP tcp 443, DHCP, ICMP만 통과시킵니다. WireGuard보다 느슨하며("유출되기 어려움" 수준이지 완전 방지는 아님) 일부 환경에서는 Tailscale 자체의 연결을 방해할 수 있어 선택 사항으로 두었습니다.
                • 자동화: 신뢰할 수 없는 네트워크에서는 터널/exit node를 켜고, 신뢰하는 네트워크에서는 끕니다. 라이선스가 만료되면 터널과 킬 스위치는 자동으로 해제됩니다.
                """,
                recommendation: "공용 Wi-Fi를 자주 사용한다면 가장 효과적인 보호책입니다. Tailscale 사용자는 CLI를 설치하고 Tailscale 백엔드와 exit node를 선택하세요. 그렇지 않다면 `brew install wireguard-tools`와 VPN 제공업체의 `.conf` 파일을 사용하는 것이 가장 간편합니다."
            ),
            LocalizedEntry(
                id: "feat_airgap_containment",
                title: "긴급 에어갭 봉쇄 (전체 네트워크 차단, Wi-Fi 무선 끄기, 자동 복구 안전장치)",
                summary: "심각한 위협(랜섬웨어, XProtect 악성코드 판정, ARP 스푸핑, ClickFix)이 감지되었을 때 사용되는 공통 긴급 봉쇄 기능입니다. 모든 수신 및 송신 트래픽을 차단합니다. 앱이 충돌하거나 재부팅되어도 최대 10분 이내에 네트워크가 자동으로 복구됩니다.",
                details: """
                • 동작 방식: 특권 헬퍼가 pf의 "block drop all"(루프백 제외)을 적용하고 다시 읽어 확인합니다. 송신도 차단되므로 C2 서버로의 키나 데이터 유출도 막습니다. 적용에 실패하면 최대 3회(각 8초 타임아웃) 재시도하고, 그래도 실패하면 "자동 네트워크 차단 실패"라고 명시하고 수동 연결 해제를 요청합니다. 실제로 격리되지 않았는데 격리되었다고 표시하는 일은 없습니다.
                • Wi-Fi 무선 끄기: pf는 패킷만 폐기할 뿐 어댑터 자체는 연결된 상태로 남으므로, ARP 스푸핑, 랜섬웨어, XProtect 봉쇄는 `networksetup`을 통해 Wi-Fi 무선 자체도 끕니다(기본값 켜짐, 내부 설정 `RoamSwitch.AirGapAutoWiFiKillEnabled`). ClickFix 봉쇄는 무선을 끄지 않습니다.
                • 해제: 긴급 창이나 알림에서 해제하면 pf 차단이 풀리고 Wi-Fi가 다시 켜집니다.
                • 안전장치: 앱이 충돌하거나 아무도 해제하지 않으면 헬퍼 측 타이머가 10분 후 에어갭을 강제로 해제하고 Wi-Fi 무선을 복구합니다. 앱을 다시 실행하거나 Mac을 재부팅해도 별도의 수동 조작 없이 복구됩니다.
                • 부팅 게이트: 부팅 직후 앱이 정책을 적용하기 전까지 기본 거부 pf 부팅 게이트가 작동하며, 최대 90초 후 자동으로 해제됩니다.
                """,
                recommendation: "봉쇄가 발동하면 먼저 알림 내용을 확인하고, 의심스러운 앱을 종료한 뒤 검사를 실행하고 나서 해제하세요. 오탐임을 알고 있다면 즉시 해제해도 됩니다."
            ),
            LocalizedEntry(
                id: "feat_port_anomaly_guard",
                title: "알 수 없는 리스닝 포트 자동 차단 & 개발 서버 격리 (Pro)",
                summary: "모든 리스닝 TCP 포트를 감시하다가, 이전에 노출되지 않았던 실행 파일이 갑자기 0.0.0.0으로 리스닝을 시작하면 LAN에서의 해당 포트 접근을 차단합니다. 개발 서버나 로컬 AI 서버도 클릭 한 번으로 127.0.0.1에 격리할 수 있습니다.",
                details: """
                • 모니터링 방식: 20초마다 리스닝 포트를 스캔합니다. 판별 기준은 실행 파일 경로이므로, 알려진 앱이 포트 번호만 바꾼 경우에는 반응하지 않습니다. 활성화 직후의 상태가 기준선으로 기록됩니다.
                • 자동 차단: 알 수 없는 실행 파일이 포트를 노출하기 시작하면 pf가 외부 접근만 차단합니다(Mac 자체와 localhost에서는 계속 사용 가능). 이를 통해 악성코드 계열을 몰라도 제로데이 취약점으로 심어진 백도어를 잡아낼 수 있습니다.
                • 제외 대상: `/System/Library` 또는 `/usr/libexec` 아래의 Apple 서명 시스템 데몬(예: Handoff, AirPlay, AirDrop에 필요한 rapportd). `/usr/bin` 아래의 범용 도구(`/usr/bin/python3`, `/usr/bin/nc` 등)는 여전히 표시됩니다.
                • 위험 서비스: 기본적으로 인증 없이 노출되는 경우가 많은 Redis(6379), MongoDB(27017), Memcached(11211), Elasticsearch(9200), VNC(5900)와 로컬 AI 서버(Ollama 11434, LM Studio 1234, Gradio 7860, vLLM 8000)를 식별합니다.
                • 개발 서버 격리: 외부 공개 포트에서 해당 포트를 열고 "외부 격리 실행"을 선택하면 127.0.0.1로 제한할 수 있습니다(Pro).
                • 오탐 처리: 알림의 "허용" 버튼이나 포트 진단 화면에서 영구적으로 허용할 수 있습니다. 이 기능을 끄거나 라이선스가 만료되면 생성했던 모든 차단이 해제됩니다.
                • 기본값: Pro를 처음 활성화할 때 자동으로 켜집니다. 사고 기록은 MCP 도구 `get_port_anomaly_incidents`로 확인할 수 있습니다.
                """,
                recommendation: "개발 서버와 로컬 LLM은 `127.0.0.1`에 바인딩하세요(예: `OLLAMA_HOST=127.0.0.1 ollama serve`, `npm run dev -- -H 127.0.0.1`)."
            ),
            LocalizedEntry(
                id: "feat_active_vuln_scan",
                title: "실증형 취약점 검증 — 기본값 꺼짐",
                summary: "이 Mac 자체(127.0.0.1)에서 발견된 서비스가 실제로 인증 없이 응답하는지를 최소한의 읽기 전용 프로브로 확인합니다. 기본값은 꺼짐이며, 명시적으로 켜야 하고 실행할 때마다 확인이 필요합니다.",
                details: """
                • 활성화 방법: 포트・기기 모니터링 → "실증형 취약점 검증(능동적 도달 확인)". 이 설정은 포트 진단 화면의 "실증 확인 실행" 버튼을 여는 것일 뿐 그 자체로는 아무것도 전송하지 않으며, 실행할 때마다 "검증 요청을 전송하시겠습니까?"라고 먼저 묻습니다.
                • 127.0.0.1로만 전송: 다른 호스트로는 절대 전송하지 않습니다.
                • 비인증 접근: Redis(PING), Memcached(stats), MongoDB(listDatabases)에 단발성, 짧은 타임아웃의 비파괴적 프로브를 보냅니다.
                • 일반 개발 서버: CORS 설정 오류(자격 증명 포함 Origin 반사), 경로 순회, 오픈 리다이렉트를 확인합니다.
                • 알려진 CVE 버전 대조: 인증 없이 도달 가능한 Redis/Memcached의 버전을 비파괴적 쿼리로 읽어 알려진 CVE 버전 범위와 대조합니다. 공격용 페이로드는 전송하지 않습니다.
                • MCP 도구 `run_active_vuln_scan`으로도 사용할 수 있습니다(유일하게 네트워크 트래픽을 보내는 도구이며, localhost로만 전송합니다).
                """,
                recommendation: "본인 Mac에서 실행 중인 Redis, Docker, 로컬 LLM 등이 정말로 인증 없이 도달 가능한지 확인하고 싶을 때만 켜세요."
            ),
            LocalizedEntry(
                id: "feat_nmap_nse",
                title: "nmap NSE 보완 스캔(실증형 취약점 검증의 추가 레이어)",
                summary: "「실증형 취약점 검증」도 활성화된 경우에만, 시스템에 설치된 nmap을 사용해 노출된 포트에 대해 \"safe\" 범주의 NSE 스크립트를 추가로 실행하여 본 제품 자체의 프로브가 갖추지 못한 프로토콜 범위(SSH 호스트 키, SMTP 배너 등)를 보완합니다. 결과는 nmap 자체의 판단이며 본 제품이 독립적으로 재검증하지 않습니다.",
                details: """
                • 자동 실행: 「실증형 취약점 검증(능동적 도달 확인)」이 활성화되어 있으면 자동으로 실행됩니다. 별도의 켜기/끄기 설정은 없습니다. nmap은 자동으로 설치되지 않으며, 시스템에 이미 설치되어 있는 경우(예: Homebrew)에만 작동하고, 그렇지 않으면 아무 작업도 하지 않습니다.
                • 스크립트 선택: `safe and not broadcast and not external`. 단순한 "safe" 범주만으로는 충분하지 않습니다 — `broadcast` 스크립트는 대상 호스트뿐 아니라 LAN 전체에 멀티캐스트/브로드캐스트로 질의하며, `external` 스크립트(예: `vulners.nse`)는 감지한 서비스/버전을 실제로 vulners.com 같은 제3자에게 전송합니다. 둘 다 127.0.0.1에만 접근하고 다른 호스트나 외부 서버에는 일절 접근하지 않는다는 본 제품의 설계 원칙에 반하므로 제외됩니다.
                • 시간 제한: 스크립트당 15초(`--script-timeout 15s`). 일부 "safe" 스크립트가 비표준 HTTP API에 대해 무한정 실행되어 이 제한이 없으면 다른 포트의 결과까지 손실될 수 있습니다.
                • 범위: 실증형 취약점 검증 자체가 사용하는 것과 동일한, 이미 열려 있음이 확인된 포트만 대상으로 합니다.
                """,
                recommendation: "nmap의 소견은 어디까지나 참고 정보로 취급하고, 내용을 확인한 후 해당되는 경우에만 대응하세요."
            ),
            LocalizedEntry(
                id: "feat_usb_keyboard_guard",
                title: "무단 USB / BadUSB 물리 포트 가드 (키보드 승인 & 키 입력 타이밍 분석) (Pro)",
                summary: "알 수 없는 USB 키보드나 개조된 케이블(Rubber Ducky, O.MG Cable, Flipper Zero 등)이 연결되면 승인할 때까지 해당 기기의 키 입력을 차단하여 자동화된 명령어 주입을 막습니다. 또한 키 입력 간격을 분석하여 스크립트처럼 보이면 경고합니다.",
                details: """
                • 감지 방식: IOHIDManager가 새로운 키보드 연결을 실시간으로 감지합니다. 내장 키보드는 자동으로 신뢰됩니다.
                • 차단 방식: 미승인 기기는 독점적으로 점유(IOHIDDevice seize)되어 해당 기기의 키 입력만 시스템에 도달하지 못하게 됩니다. 다른 키보드는 계속 정상 작동합니다. 점유에 실패한 경우에만 손쉬운 사용 권한을 사용하는 CGEventTap 차단으로 대체합니다.
                • 승인 방식: 최전면 창에서 "신뢰하고 허용" 또는 "거부하고 차단 유지"를 선택할 수 있습니다. 허용된 키보드는 허용 목록에 추가됩니다.
                • 키 입력 타이밍 분석: 차단 중에도 해당 기기의 키 입력 간격을 계속 측정합니다. 최소 5회 이상의 간격을 확보한 뒤 평균이 12ms 이하이거나, 평균이 45ms 이하이면서 매우 균일(변동 계수 0.35 이하)하면 "자동 입력(스크립트)의 징후" 경고가 발생합니다. 이는 사람이 낼 수 없는 기계적인 속도와 규칙성을 포착하는 보조 증거일 뿐이며, 차단 여부 판단 자체는 바꾸지 않습니다.
                • 기본값은 꺼짐입니다. 포트・기기 모니터링 → "무단 USB / BadUSB 물리 포트 가드 (Pro)"에서 활성화하고, "USB / BadUSB 가드 설정…"에서 허용 목록을 관리합니다.
                """,
                recommendation: "외장 키보드를 사용한다면 본인이 직접 연결한 것만 신뢰하고 허용으로 등록하세요. 스크립트 입력 경고가 뜬 기기는 항상 거부하고 뽑아 두세요."
            ),
            LocalizedEntry(
                id: "feat_usb_storage_guard",
                title: "무단 USB 저장장치 자동 차단 & ClamAV 자동 검사 (Pro)",
                summary: "허용 목록에 없는 USB 드라이브나 외장 디스크는 먼저 읽기 전용으로 마운트되어 사용자에게 처리 방법을 묻습니다. 허용된 기기도 설정된 권한으로 연결되기 전에 ClamAV로 검사합니다.",
                details: """
                • 모니터링 방식: DiskArbitration이 외장/이동식 볼륨 마운트를 즉시 포착합니다.
                • 미등록 기기: 안전을 위해 읽기 전용으로 다시 마운트되며 "읽기·쓰기 허용", "읽기 전용으로 허용", "꺼내기"를 제공하는 대화상자가 표시됩니다. 꺼내기를 선택하면 즉시 마운트 해제 및 꺼내기가 실행됩니다.
                • 허용된 기기: 허용 목록의 권한(읽기 전용/읽기・쓰기)이 자동으로 적용되며, 읽기・쓰기로 승격되기 전에 ClamAV 검사를 실행합니다.
                • 감염: 악성코드가 발견되면 볼륨이 자동으로 꺼내지고 긴급 경보가 발송됩니다.
                • 재포맷된 드라이브: 볼륨 UUID가 바뀌어도 일련번호를 포함한 하드웨어 식별 정보가 일치하면 승인 정보가 그대로 이어집니다(공급업체/제품 ID만으로는 일치로 간주하지 않습니다).
                • 범위: 저장장치를 통한 데이터 유출과 악성 페이로드를 방지합니다. 키보드로 위장하는 HID형 BadUSB 기기는 feat_usb_keyboard_guard가 처리합니다.
                """,
                recommendation: "업무용으로 사용하는 USB 드라이브만 허용 목록에 등록하고, 민감한 데이터를 다루는 Mac에서는 읽기 전용 권한을 우선하세요."
            ),
            LocalizedEntry(
                id: "feat_bluetooth_guard",
                title: "미신뢰 네트워크에서 Bluetooth 자동 끄기 (Pro)",
                summary: "최대 잠금이 적용되는 외부 네트워크에 연결하면 Bluetooth를 자동으로 꺼서 원치 않는 페어링이나 BLE 공격에 노출되는 것을 줄이고, 신뢰하는 네트워크로 돌아오면 다시 켭니다.",
                details: """
                • 사용 도구: macOS에는 앱에서 Bluetooth 전원을 전환할 수 있는 공개 API가 없으므로, RoamSwitch는 오픈소스 Homebrew 도구 `blueutil`(`brew install blueutil`)을 사용합니다. 설치되어 있지 않으면 메뉴에 설치 안내가 표시됩니다.
                • 복원 방식: RoamSwitch가 끄기 직전에 Bluetooth가 켜져 있었던 경우에만 신뢰하는 네트워크에서 다시 켭니다. 외출 중에 사용자가 직접 내린 선택은 덮어쓰지 않습니다.
                • 기본값 꺼짐: 카페 등에서 AirPods를 사용하는 사람이 많아 조용히 오디오를 끊으면 불편할 수 있으므로 선택적 사용으로 두었습니다.
                """,
                recommendation: "외출 중 Bluetooth 액세서리를 사용하지 않는다면 켜서 전파 탐색과 원치 않는 페어링을 방지하세요."
            ),
        ]
    }

    // MARK: - Features: malware & web protection

    private static func featuresKoMalware() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_webmail_download_guard",
                title: "웹 및 이메일 보호 (다운로드 자동 검사 & 격리) (Pro)",
                summary: "브라우저, Mail, Slack, Discord 등에서 저장된 파일을 FSEvents로 감시하고, 정적 시그니처 검사와 ClamAV로 검사하여 위협이 발견되면 격리소로 옮깁니다.",
                details: """
                • 감시 폴더: 기본값은 `~/Downloads`, `~/Desktop`, `~/Documents`와 Mail의 다운로드 폴더입니다. "⚙️ 감시 대상 폴더 편집…"에서 폴더를 추가하거나 제거할 수 있습니다.
                • 다운로드 출처: macOS가 부여하는 `com.apple.quarantine` 확장 속성으로 식별합니다.
                • 이중 검사: 기기 내 정적 시그니처 검사(교과서적인 리버스 셸 한 줄 명령어 등, ClamAV 없이도 동작)와 ClamAV 검사를 함께 사용합니다. 정적 시그니처가 탐지하면 ClamAV의 판정과 관계없이 격리되며, ClamAV가 다른 판정을 내리면 오탐일 수 있다는 안내가 알림에 표시됩니다.
                • 격리: 위협은 `~/Library/Application Support/RoamSwitch/Quarantine/`으로 이동됩니다(삭제되지 않음). 이동이 실패하면 격리 실패라고 알리고 수동 삭제를 요청합니다.
                • EICAR 테스트 파일: 업계 표준의 무해한 테스트 시그니처는 격리되거나 차단되지 않으며 알림도 발생하지 않고, 알림 기록(feat_notification_history)에만 기록됩니다.
                • 최초 폴더 접근: macOS의 권한 요청 전에, 이것이 이 검사 기능을 위한 정당한 권한임을 설명하는 일회성 안내가 표시됩니다.
                • Pickle 형식 AI 모델 경고: feat_ai_model_guard를 참조하세요.
                """,
                recommendation: "ClamAV를 설치하고 활성화한 후, 브라우저의 다운로드 폴더를 별도로 지정했다면 감시 대상 폴더에 추가하세요."
            ),
            LocalizedEntry(
                id: "feat_ai_model_guard",
                title: "위험한 AI 모델 형식(Pickle / PyTorch) 다운로드 경고 (Pro)",
                summary: "Hugging Face, Civitai 등에서 `.pkl` / `.pickle` / `.pt` 모델 파일을 다운로드하면 Pickle 형식이 로드 시 임의 코드를 실행할 수 있음을 경고하고 SafeTensors / GGUF 사용을 권장합니다.",
                details: """
                • 감지 방식: 웹 및 이메일 보호(feat_webmail_download_guard)가 감시하는 폴더에 다운로드된 파일의 확장자를 확인합니다.
                • 위험성: 파이썬의 Pickle은 역직렬화 과정에서 임의의 코드를 실행할 수 있어, 악성 모델을 로드하기만 해도 Mac이 위협받을 수 있습니다.
                • 동작: 경고만 표시하며 파일은 격리하지 않습니다(ClamAV나 정적 시그니처가 탐지한 경우에는 여전히 격리됩니다).
                """,
                recommendation: "출처가 불분명한 Pickle / PyTorch 모델은 로드하지 말고 `.safetensors`나 `.gguf` 형식의 모델을 사용하세요."
            ),
            LocalizedEntry(
                id: "feat_quarantine_manager",
                title: "격리 파일 관리 (격리소, 복원, 삭제, 검사 제외)",
                summary: "ClamAV나 정적 시그니처 검사에서 표시된 파일은 절대 삭제되지 않고 격리소에 보관됩니다. 격리 관리자에서 이유를 확인하고, 원래 위치로 복원하거나, 완전히 삭제하거나, 이후 검사에서 특정 경로를 제외할 수 있습니다.",
                details: """
                • 열기: 악성코드 보호 (XProtect & ClamAV) → ClamAV → "📦 격리 파일 관리…" 또는 웹 및 이메일 보호 아래의 "📦 격리 관리자 열기…".
                • 위치: `~/Library/Application Support/RoamSwitch/Quarantine/`에 원래 경로, 위협 이름, 격리 시각을 메타데이터로 함께 보관합니다. 사용자가 명시적으로 완전히 삭제를 선택하지 않는 한 아무것도 제거되지 않습니다.
                • 복원: 파일을 원래 위치로 되돌립니다. 감염되지 않았음을 확신할 때만 사용하세요.
                • 제외하고 복원: 확실한 오탐인 경우 파일을 복원하고 해당 정확한 경로를 이후 ClamAV 검사에서 제외합니다. 제외 목록은 같은 창에 표시되며, "제외 해제"로 되돌릴 수 있습니다.
                • 완전히 삭제: 확인 후 삭제됩니다. 이 작업은 되돌릴 수 없습니다.
                • MCP 도구 `get_quarantine_status`로 격리된 파일 목록을 확인할 수 있습니다.
                """,
                recommendation: "알아볼 수 없는 파일은 삭제하고, 본인의 스크립트나 개발용 바이너리처럼 확실한 오탐일 때만 제외하고 복원을 사용하세요."
            ),
            LocalizedEntry(
                id: "feat_xprotect_file_safety",
                title: "Apple XProtect 상태 확인 & 파일/앱 안전성 진단",
                summary: "Apple의 내장 XProtect 악성코드 방지 기능의 정의 버전과 상태를 보여주고, 임의의 파일이나 앱에 대해 공증 여부, 서명 권한자, Team ID, 다운로드 격리 속성을 검사합니다. 무료 버전에서도 사용할 수 있습니다.",
                details: """
                • 열기: 악성코드 보호 (XProtect & ClamAV) → "🍏 Apple XProtect" → "XProtect 실행 상태 확인…" / "파일/앱 안전성 진단…".
                • 확인 항목: Apple 승인(공증/Gatekeeper) 여부, 서명 권한자, Team ID, 웹 다운로드 격리 속성(`com.apple.quarantine`), 경로.
                • 용도: 앱을 처음 열기 전에 정당한 개발자가 서명하고 공증했는지 확인합니다.
                """,
                recommendation: "출처가 불분명한 앱은 실행하기 전에 안전성을 진단하고, 승인되지 않았거나 서명되지 않은 것은 열지 마세요."
            ),
            LocalizedEntry(
                id: "feat_dns_threat_guard",
                title: "DNS 위협 보호 (악성 사이트 및 C2 차단) (Pro)",
                summary: "보안 DNS 리졸버(Quad9, Cloudflare, AdGuard, CleanBrowsing)를 적용하여 악성코드 C2 서버와 피싱 사이트에 대한 이름 조회를 DNS 단계에서 차단합니다.",
                details: """
                • 제공업체: Quad9(9.9.9.9 / 149.112.112.112), Cloudflare Security(1.1.1.2 / 1.0.0.2), AdGuard DNS(94.140.14.14 / 94.140.15.15, 광고와 트래커도 차단), CleanBrowsing Security(185.228.168.9 / 185.228.169.9).
                • 정책: "외부·미신뢰 Wi-Fi에서만 적용(권장)" 또는 "모든 네트워크에서 항상 적용(신뢰 환경 포함)".
                • 내부 동작: 특권 헬퍼가 활성 네트워크 서비스의 DNS 서버를 전환하고, 신뢰하는 네트워크로 돌아오면 원래의 DHCP/수동 DNS 설정을 복원합니다.
                • 상태: 메뉴에 "🟢 보안 DNS 적용 중" 또는 "🏠 신뢰 네트워크(라우터 표준 DNS)"가 표시됩니다. Mac 보안 진단의 항목이기도 합니다.
                """,
                recommendation: "공용 Wi-Fi의 가짜 DNS(DNS 하이재킹)와 악성 도메인을 피하려면 Quad9와 외부 전용 정책부터 시작하세요."
            ),
            LocalizedEntry(
                id: "feat_passive_link_guard",
                title: "링크 보호 (피싱 접속 탐지 및 차단: 시스템 확장, DoH 대응, 경고 모드는 실패 시 차단) (Pro)",
                summary: "알려진 사기 도메인 정보와 브랜드 위장 탐지를 기반으로 어떤 브라우저나 앱에서도 피싱 및 사기 사이트로의 접속을 기기 자체에서 차단합니다. 콘텐츠 필터 시스템 확장으로 동작하며, 확장이 승인되기 전까지는 /etc/hosts 싱크홀을 대체 수단으로 사용합니다.",
                details: """
                • 모드: "끔", "경고만(차단 안 함)", "명백한 피싱 사이트는 자동 차단(권장)"(기본값)이 있습니다. 악성코드 보호 → "링크 보호(피싱 접속 감지) (Pro)"에서 전환합니다.
                • 차단 대상: 위협 정보에 등록된 도메인이나 브랜드의 유니코드 동형 문자 위장처럼 명백한 경우만 차단합니다. 브랜드를 서브도메인에 넣는 수법이나 고위험 TLD 등은 경고로 처리됩니다. 판정 엔진과 정보는 Linux 버전과 공유됩니다.
                • 시스템 확장(권장): 콘텐츠 필터 시스템 확장 `RoamSwitchLinkFilter`가 이름 해석 이후의 TCP 흐름을 검사합니다. OS가 해석한 호스트 이름 외에도 TLS ClientHello의 SNI를 읽으므로, 브라우저가 자체 DoH / DoT를 사용해도 동작합니다. 차단 모드에서는 SNI를 볼 수 없는 QUIC(UDP 443)를 폐기하여 브라우저가 TCP로 대체하도록 유도합니다. 처음 사용할 때는 시스템 설정에서 승인이 필요합니다.
                • JA3 지문: SNI를 읽을 수 있었던 TLS 연결에 대해 클라이언트의 JA3 해시도 계산하여 정보의 JA3 목록과 대조합니다(SNI가 없는 연결에서는 JA3만으로 판단하지 않습니다).
                • 경고 모드(실패 시 차단): 해당하는 연결이 일시 정지되고 허용/차단 알림과 최전면 패널이 표시됩니다. 답변에 따라 흐름이 재개되거나 폐기됩니다. 약 8초 안에 응답이 없으면 연결이 차단됩니다. 이 결과는 캐시되지 않으므로 다음 시도 때 다시 물어봅니다. 실제로 내린 답변은 기억됩니다. 경고 모드는 시스템 확장이 필요합니다.
                • hosts 대체: 확장이 활성화되지 않은 동안, 차단 모드에서는 특권 헬퍼가 해당 도메인을 `/etc/hosts`의 관리 구역에 `0.0.0.0`으로 기록합니다.
                • 위협 정보: 하루에 한 번 수신 전용으로 가져오며 식별자는 전송하지 않고, 전용 Ed25519 정보 키(앱 업데이트 키와는 별개)로 검증합니다. "자동 업데이트"를 끄면 외부 통신이 전혀 없으며 내장 데이터와 동형 문자 탐지만으로 동작합니다.
                • Pro가 아닌 경우: 모드는 저장되지만 아무것도 차단되지 않습니다.
                """,
                recommendation: "기본값인 자동 차단을 유지하고 시스템 확장을 승인하는 것이 가장 확실합니다. 사내 도구가 실수로 차단되면 알림의 \u{201C}이번만 허용(5분)\u{201D}이나 허용 목록을 사용하세요."
            ),
            LocalizedEntry(
                id: "feat_link_safety_auditor",
                title: "링크 안전성 진단 (수동 확인, Zero Telemetry)",
                summary: "브라우저에서 의심스러운 URL을 열기 전에 기기 내에서만 분석하여 유니코드 동형 문자, 서브도메인 위장, 고위험 TLD, 평문 HTTP, 원시 IP 주소 등을 기준으로 100점 만점으로 위험도를 평가합니다. 무료 버전에서도 사용할 수 있습니다.",
                details: """
                • 열기: 악성코드 보호 → "🔗 링크 수동 확인…" 또는 MCP 도구 `audit_url_safety`.
                • 동형 문자: 키릴 문자나 그리스 문자처럼 비슷하게 생긴 글자(Punycode / `xn--`)를 탐지합니다.
                • 서브도메인 위장: `apple.com.login-verify.xyz`처럼 유명 브랜드 이름을 끼워 넣은 구조를 분석합니다.
                • 고위험 TLD: 일회성 피싱에서 흔히 쓰이는 `.xyz`, `.top`, `.tk`, `.icu` 등에 감점을 매깁니다.
                • 평문 HTTP와 원시 IP: 로그인 페이지에서 암호화되지 않은 HTTP와 순수 IP 주소 URL을 경고합니다.
                • 완전히 로컬에서 처리: URL이 외부 분석 API로 전송되지 않으므로 기밀 URL이나 토큰이 유출되지 않습니다.
                """,
                recommendation: "이메일이나 채팅으로 받은 의심스러운 링크는 바로 클릭하지 말고 먼저 링크 안전성 진단으로 확인하세요."
            ),
            LocalizedEntry(
                id: "feat_ransomware_canary_guard",
                title: "랜섬웨어 미끼 파일 탐지 & 프로세스 정지를 동반한 자율 에어갭 (Pro)",
                summary: "사용자 폴더에 숨겨진 미끼(canary) 파일을 배치합니다. 그중 하나라도 수정, 삭제, 이름 변경되는 순간 자동으로 네트워크를 차단하고 공유 서비스를 정지하며 의심되는 프로세스를 일시 정지(SIGSTOP)합니다.",
                details: """
                • 미끼 파일: `~/Library/Application Support/RoamSwitch/CanaryGuard/`에 4개, 그리고 문서, 데스크탑, 다운로드, 사진 폴더에 `.roamswitch_security_canary_do_not_delete`로 시작하는 숨김 파일이 있습니다. 각 파일의 SHA-256이 기준값으로 기록됩니다.
                • 탐지 방식: 실시간 kqueue 감시와 60초마다의 확인을 함께 사용합니다. 파일별로 10초의 대기 시간을 두어 한 번의 이벤트 폭주가 중복 처리되지 않도록 합니다. 지난 60초 이내에 수정된 실제 파일은 영향을 받았을 가능성이 있는 파일로 기록됩니다.
                • 자동 대응: (1) 응용 프로그램 방화벽 잠금 (2) 에어갭 봉쇄(pf가 모든 트래픽을 차단하고 Wi-Fi 무선을 끔, feat_airgap_containment) (3) 공유 서비스(SMB / SSH / 화면 공유) 정지 (4) 의심되는 프로세스를 강제 종료 대신 SIGSTOP으로 일시 정지 (5) 긴급 경보와 최전면 긴급 창 표시.
                • 종료 대신 정지하는 이유: 네트워크가 이미 차단되었으므로 정지된 프로세스는 더 이상 피해를 줄 수 없습니다. 오탐이었다면 해제 시 SIGCONT로 재개되어 데이터 손실이 없습니다.
                • 해제 시: 네트워크와 Wi-Fi가 복원되고, 정지된 프로세스가 재개되며, 변조된 미끼 파일이 다시 생성됩니다.
                • 기본값: Pro를 처음 활성화할 때 자동으로 켜집니다. 사고 기록은 MCP 도구 `get_canary_status`로 확인할 수 있습니다. 메뉴의 "랜섬웨어 방어 시뮬레이션(동작 확인)"으로 안전하게 테스트할 수 있습니다.
                """,
                recommendation: "알 수 없는 랜섬웨어로부터 중요한 데이터를 보호하려면 계속 켜 두고, 숨겨진 미끼 파일은 삭제하지 마세요."
            ),
            LocalizedEntry(
                id: "feat_runtime_threat_containment",
                title: "XProtect 악성코드 탐지 시 자동 네트워크 차단 (Pro)",
                summary: "Apple의 내장 XProtect / XProtect Remediator가 실제로 악성코드를 탐지하거나 제거하는 순간 긴급 에어갭으로 네트워크를 차단합니다. Gatekeeper가 서명되지 않은 앱을 차단하는 것만으로는 네트워크가 차단되지 않고 알림만 발송됩니다.",
                details: """
                • 신호 출처: ndjson 형식의 장기 실행 `/usr/bin/log stream` 구독(폴링이 아닌 블로킹 대기 방식이라 유휴 시 CPU 사용량이 거의 0)으로 XProtect 관련 시스템 로그를 감시합니다.
                • 발동 조건: XProtect가 심각한 악성코드 판정을 기록했을 때만 에어갭 봉쇄(Wi-Fi 무선 끄기 포함)가 작동하며, 네트워크의 신뢰 수준과는 무관합니다.
                • Gatekeeper와의 차이: 개발자가 자신의 서명되지 않은 빌드를 차단하는 것과 같은 일상적인 Gatekeeper 이벤트는 "Gatekeeper가 서명되지 않은 앱의 실행을 차단했습니다" 알림만 발생시킵니다.
                • 일관성: 수동으로 실행하는 Mac 보안 로그 감사와 동일한 분류 로직을 공유합니다.
                • EndpointSecurity 권한을 사용하지 않으므로, 실행 전 차단이 아니라 탐지 직후의 즉각적인 봉쇄입니다.
                • 기본값: Pro를 처음 활성화할 때 자동으로 켜집니다(자동 차단이 활성화되었다는 일회성 안내와 함께). 상태는 MCP 도구 `get_runtime_threat_status`로 확인할 수 있으며 "멀웨어 감지 연동 Air-Gap 시뮬레이션(동작 확인)"으로 테스트할 수 있습니다.
                """,
                recommendation: "Apple 자체의 악성코드 엔진과 연동된 자동 방어로서 계속 켜 두세요. 서명되지 않은 자체 앱을 자주 실행해도 Gatekeeper 차단만으로는 네트워크가 차단되지 않으므로 문제가 되지 않습니다."
            ),
            LocalizedEntry(
                id: "feat_clickfix_guard",
                title: "ClickFix 대책 — 의심스러운 터미널 명령어 감지 시 자동 차단 (Pro, 기본값 꺼짐)",
                summary: "가짜 캡차나 오류 페이지가 사용자로 하여금 명령어를 직접 붙여넣고 실행하게 만드는 ClickFix 수법을 셸 기록에서 탐지하고, 진행 중인 다단계 공격을 막기 위해 네트워크를 차단합니다.",
                details: """
                • 감시 범위: `~/.zsh_history`와 `~/.bash_history`에 새로 추가된 줄만 감시합니다(기존 기록은 대상이 아닙니다).
                • 판정 패턴: (1) 알려진 리버스 셸 한 줄 명령어(정적 시그니처 검사와 공유), (2) Base64로 디코딩한 내용을 셸이나 `osascript`에 직접 파이프로 넘기는 이중 우회. Homebrew처럼 정당한 설치 프로그램이 사용하는 단순한 `curl ... | bash`는 의도적으로 표시하지 않습니다.
                • 대응 방식: 에어갭 봉쇄(Wi-Fi 무선은 끄지 않음), 최대 10분 후 자동 복구됩니다. 알림은 Keychain, 브라우저에 저장된 비밀번호, 암호화폐 지갑을 확인하라고 권장합니다.
                • 사후 대응인 이유: 명령어가 기록에 남을 즈음에는 이미 실행된 뒤이지만, 즉시 네트워크를 차단하면 진행 중인 2단계 다운로드, 살아있는 리버스 셸 연결, 자격 증명 유출을 막을 수 있습니다.
                • Gatekeeper로 막을 수 없는 이유: 사용자 자신의 정당한 셸이 입력한 그대로 실행하는 것이므로 프로세스 자체에는 이상한 점이 없습니다.
                • 보완 기능: 클립보드 보호(feat_secret_leak_auditor)는 복사하는 순간에 명령어를 탐지하여 터미널 외에 스크립트 편집기, Spotlight 등에 붙여넣는 것도 커버합니다.
                • 기본값 꺼짐: 비교적 새로운 휴리스틱으로 자동 네트워크 차단을 실행하므로 선택적 사용으로 두었습니다.
                """,
                recommendation: "가짜 오류 페이지나 캡차에 속아 명령어를 실행하게 될까 걱정된다면 활성화를 고려하세요."
            ),
            LocalizedEntry(
                id: "feat_persistence_monitor_guard",
                title: "신규 자동 실행 등록(LaunchAgent / LaunchDaemon) 감시 (Pro)",
                summary: "새로운 LaunchAgent / LaunchDaemon 등록을 실시간으로 감시하다가, 셸이나 스크립트 인터프리터를 직접 실행하거나 서명이 유효하지 않은 실행 파일을 등록하면 알립니다.",
                details: """
                • 감시 대상: `~/Library/LaunchAgents`, `/Library/LaunchAgents`, `/Library/LaunchDaemons`를 FSEvents로 감시합니다(약 1.5초의 디바운스).
                • 판정 근거: 최근의 정보 탈취형 악성코드는 유효하게 Apple 서명된 `/bin/bash`나 `/usr/bin/osascript`가 Base64로 숨긴 스크립트를 실행하게 하여 지속성을 확보합니다. 인터프리터 자체의 서명은 유효하므로, 순수 인터프리터를 직접 실행하는 등록은 서명 상태와 무관하게 의심스러운 것으로 처리되며, 스크립트 인자도 정적 시그니처 검사를 거칩니다. 서명되지 않았거나 서명이 유효하지 않은 실행 파일도 표시됩니다. Homebrew services 래퍼는 예외입니다.
                • 탐지만 수행: EndpointSecurity 권한이 없어 plist 작성 자체를 막을 수는 없습니다. 작성된 지 약 1.5초 안에 판정하고 보고합니다.
                • 기본값: Pro에서 기본으로 켜져 있습니다. 악성코드 보호 → "신규 자동 실행 등록(LaunchAgent/Daemon) 감시 (Pro)"에서 전환할 수 있습니다.
                """,
                recommendation: "낯선 등록 경고를 받으면 알림에 표시된 plist를 확인하고 알아볼 수 없다면 삭제하세요. 정당한 앱을 막 설치한 직후라면 대개 문제없습니다."
            ),
            LocalizedEntry(
                id: "feat_docker_event_guard",
                title: "Docker 특권 컨테이너 및 docker.sock 마운트 감지 (Pro, 기본값 꺼짐)",
                summary: "컨테이너 탈출로 이어질 수 있는 위험한 Docker 설정, 예를 들어 `--privileged`로 시작하거나 `/var/run/docker.sock`이 마운트된 컨테이너가 시작될 때 알립니다.",
                details: """
                • 동작 방식: 20초마다 `docker ps`로 새로 시작된 컨테이너만 찾아 `docker inspect`로 설정을 확인합니다. 탐지 형식은 Linux 버전과 동일하여 두 플랫폼이 같은 조건을 표시합니다.
                • 알림만 발송: 확인된 침해가 아니라 위험한 "설정"이므로(예: 모니터링 에이전트가 의도적으로 특권 모드로 실행되는 경우도 있음) 아무것도 자동으로 차단하지 않습니다.
                • 기본값 꺼짐: 대부분의 사용자는 Docker를 사용하지 않으므로 Pro에서도 기본값은 꺼짐입니다.
                • 테스트: "⚠️ Docker 위험 감지 시뮬레이션(동작 확인)…"으로 Docker를 건드리지 않고 알림 경로를 확인할 수 있습니다.
                """,
                recommendation: "개발에 Docker를 사용한다면 컨테이너 탈출 위험을 조기에 발견하기 위해 활성화하세요."
            ),
        ]
    }

    // MARK: - Features: audit, monitoring & platform

    private static func featuresKoAudit() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_critical_path_fim",
                title: "중요 시스템 파일 변조 감시 (Critical Path FIM) (Pro)",
                summary: "sudoers, SSH 설정, PAM, hosts처럼 정당한 OS 업데이트나 앱 설치로는 거의 바뀌지 않는 중요 파일의 SHA-256 기준값을 기록하고, 수정・삭제・신규 파일이 생기면 알립니다.",
                details: """
                • 대상 파일: `/etc/sudoers`, `/etc/pam.d/sudo`, `/etc/ssh/sshd_config`, `/etc/ssh/sshd_config.d/` 아래의 모든 파일, `/etc/hosts`, 그리고 root의 `~/.ssh/authorized_keys`. 이들은 root 전용이므로 특권 헬퍼가 해시를 계산합니다.
                • 시점: `/etc`, `/etc/pam.d`, `/etc/ssh`의 FSEvents가 거의 실시간으로 재검사를 유발하며, 매시간 검사가 안전장치로 작동합니다.
                • 기준선: 첫 검사에서 확보됩니다. 탐지된 변경 사항은 사람이 검토할 때까지 자동으로 새 기준선으로 채택되지 않으므로 발견 내용이 계속 남아 있습니다. 앱이 실행되는 동안 같은 상태에 대해서는 다시 알리지 않으며, 추가 변경이 있으면 다시 경고합니다.
                • 사각지대 경고: 헬퍼에 3회 연속 접속하지 못하면 변조 탐지가 작동하지 않고 있다고 알려줍니다.
                • 참고: 링크 보호가 hosts 대체 모드로 동작하는 동안 RoamSwitch 자체가 관리하는 `/etc/hosts` 구역을 다시 쓸 수 있습니다. LaunchAgent / Daemon은 feat_persistence_monitor_guard가 담당합니다.
                • 기본값: Pro를 처음 활성화할 때 자동으로 켜집니다. 메뉴: 악성코드 보호 → "중요 시스템 파일 변조를 정기적으로 감시 (Pro)".
                """,
                recommendation: "경고를 받으면 직접 변경한 것인지(예: `sudo visudo`나 설정 편집) 확인하세요. 그렇지 않다면 즉시 파일 내용을 확인하고 비밀번호 변경을 고려하세요."
            ),
            LocalizedEntry(
                id: "feat_security_log_audit",
                title: "Mac 보안 로그 감사 (수동, 템플릿 이상 탐지, AI 상담용 복사)",
                summary: "macOS 통합 로그에서 sudo 실패, SSH 연결, Gatekeeper 차단, XProtect 탐지, 인증 이벤트를 추출하고, 새로운 로그 패턴과 빈도 급증(템플릿 이상)도 함께 나열합니다. 무료 버전에서도 사용할 수 있습니다.",
                details: """
                • 열기: Mac 보안 진단 → "📜 Mac 보안 로그 감사…" 또는 MCP 도구 `audit_security_logs`.
                • 기간: 지난 24시간, 3일, 7일 중 선택.
                • 요약 카드: Sudo 실패, SSH 연결, Gatekeeper 차단, XProtect 탐지, 템플릿 이상. 카테고리별 필터링과 검색이 가능합니다.
                • 템플릿 이상: 가변 부분(IP 주소, 16진수 주소, 숫자)을 마스킹하여 로그 줄을 패턴으로 변환합니다. 이 Mac에서 한 번도 본 적 없는 패턴([신규])과 평소 빈도를 크게 넘는 급증([급증 z=…], z 점수 3 이상)을 표시합니다. 각 패턴의 빈도는 3회 관측 후 학습이 완료되며, 그 뒤로는 정상적인 양에는 알리지 않습니다.
                • 쉬운 언어 요약: 기기 내 규칙 기반 도우미가 비전문가를 위해 결과를 요약하고 구체적으로 확인할 사항을 알려줍니다(외부 API 사용 없음).
                • 출력: "보고서 복사", "AI 상담용 자료 복사"(Claude, ChatGPT 등에 붙여넣을 질문과 로그를 함께 복사하며 RoamSwitch는 아무것도 전송하지 않습니다), "CSV 내보내기 (Pro)".
                """,
                recommendation: "의심스러운 알림이 계속 오거나 Mac이 이상하게 동작할 때 실행하여 XProtect 탐지나 sudo 실패 급증이 있는지 확인하세요."
            ),
            LocalizedEntry(
                id: "feat_scheduled_log_audit",
                title: "자동 로그 감사 (정기적으로 새 패턴과 빈도 이상을 학습) (Pro)",
                summary: "로그 감사의 템플릿 이상 탐지를 백그라운드에서 매시간 실행하여 이 Mac의 평소 로그 동작을 지속적으로 학습합니다. 새 패턴이나 빈도 급증을 발견하면 실제 로그 줄과 쉬운 언어 설명으로 알립니다.",
                details: """
                • 일정: 매시간 지난 한 시간을 분석합니다. 활성화 후 약 10초 뒤 첫 스캔이 실행되지만, 앱 자체의 시작 로그가 포함되어 있어 이 최초 실행은 학습만 하고 알리지 않습니다.
                • 알림 내용: 이상 건수(신규 패턴과 급증으로 구분), 최대 3개의 실제 로그 줄, 학습 진행 상황, 비전문가를 위한 설명. 빈도 급증이 포함된 경우 알림 센터에 표시되지만, 신규 패턴만 있는 경우에는 팝업 없이 통지 기록에만 저장됩니다. 신규 패턴은 한 번 기록되면 "알려진" 상태가 되어 같은 내용으로 다시 기록되지 않으며, 급증은 해당 패턴 자체의 기준선이 학습되면 더 이상 알리지 않습니다.
                • 수동 감사와 공유: 수동 Mac 보안 로그 감사 및 MCP 도구 `audit_security_logs`와 동일한 분석 및 학습된 기준선을 사용합니다.
                • 기본값: Pro를 처음 활성화할 때 자동으로 켜집니다. 메뉴: 악성코드 보호 → "자동 로그 감사(정기적으로 새 패턴과 빈도 이상을 학습) (Pro)".
                """,
                recommendation: "설정 직후에는 신규 패턴 알림이 조금 더 많을 수 있으며, 학습이 진행되면서 안정됩니다. 알림에 낯선 앱이나 IP 주소가 언급되면 로그 감사 창을 열어 자세히 확인하세요."
            ),
            LocalizedEntry(
                id: "feat_containment_incident_timeline",
                title: "봉쇄 사고 타임라인 (통합 기록, MITRE ATT&CK 매핑)",
                summary: "네 가지 자동 대응(ARP 스푸핑, 랜섬웨어 미끼 파일, XProtect 연동 차단, 알 수 없는 포트 자동 차단)을 기기 내 하나의 시간순 기록으로 저장하여 나중에 무슨 일이 있었는지, 어떤 조치를 취했는지, 언제 해결되었는지 확인할 수 있습니다.",
                details: """
                • 기록 내용: 시간, 출처, 심각도, 요약, 프로세스 이름과 PID(알 수 있는 경우), 취해진 조치, 해결 시각과 사유(수동 해제, 시간 초과로 자동 해제, 허용 목록 등록).
                • MITRE ATT&CK: 매핑이 확실할 때만 기법 ID를 붙입니다(ARP 스푸핑 = T1557, 미끼 파일 삭제 또는 이름 변경 = T1485, 암호화 = T1486, 그 외의 변조 = T1565). 추측으로 매핑하지 않습니다.
                • 저장 위치: `~/Library/Application Support/RoamSwitch/containment_incident_timeline.json`(최신 200건). 어디로도 전송되지 않습니다.
                • MCP 도구 `get_incident_timeline`은 이 통합 타임라인을 반환합니다(에어갭 상황에서 로컬 AI로 원인을 조사할 때 유용). 각 가드별 기록은 `get_canary_status`, `get_port_anomaly_incidents`, `get_runtime_threat_status`로도 확인할 수 있습니다.
                """,
                recommendation: "자동 차단이 발생한 후에는 이 타임라인을 알림 기록과 함께 검토하여 원인을 찾고 재발을 방지하세요."
            ),
            LocalizedEntry(
                id: "feat_notification_history",
                title: "알림 기록 (지난 1주일)",
                summary: "RoamSwitch가 보낸 모든 알림을 7일간 보관하여 놓친 경고를 검토할 수 있습니다. EICAR 테스트 시그니처 탐지처럼 배너 없이 기록만 남는 이벤트도 여기에 표시됩니다. 무료 버전에서도 사용할 수 있습니다.",
                details: """
                • 열기: Mac 보안 진단 → "🔔 알림 기록…".
                • 보관 기간: 7일. 새 항목이 기록될 때마다 오래된 항목이 자동으로 정리됩니다.
                • 내용: 시간, 제목, 본문. 위협 경보, 링크 보호 접속 이벤트, ClickFix 및 비밀 키 탐지, 자동 차단이 포함됩니다.
                • EICAR 테스트 시그니처: 무해한 업계 테스트 파일은 실제 위협이 아니므로 격리되거나 차단되지 않고 배너도 표시되지 않으며 여기에만 기록됩니다. 다운로드 보호, 빠른 검사, 예약 검사 모두 동일합니다.
                • AI 도우미는 MCP 도구 `get_notification_history`로 이 기록을 읽을 수 있습니다.
                """,
                recommendation: "외출 중이거나 바빠서 알림을 놓쳤다면 여기서 확인하세요."
            ),
            LocalizedEntry(
                id: "feat_secret_leak_auditor",
                title: "클립보드 보호 (API 키 붙여넣기 경고 & ClickFix 명령어 제거)",
                summary: "기기 내에서만 클립보드를 감시하여 API 키나 개인 키가 복사되면 실수로 붙여넣지 않도록 경고하고, 사기 사이트가 실행하도록 유도하는 악성 명령어(ClickFix)가 복사되면 클립보드를 자동으로 비웁니다. 무료 버전에서도 기본값으로 켜져 있습니다.",
                details: """
                • 모니터링 방식: 약 1초마다 클립보드 변경을 확인합니다. 내용은 어디로도 전송되거나 저장되지 않습니다.
                • 탐지하는 키: OpenAI, Anthropic, GitHub, AWS, Hugging Face, Google AI / Gemini, Slack, Stripe의 API 키와 토큰, RSA / SSH 개인 키. 그 외 암호화폐 지갑 시드 문구(BIP39)와 비트코인 개인 키(WIF/BIP32)도 감지하며, 둘 다 체크섬 검증을 거쳐 오탐을 줄입니다.
                • 비밀 키의 경우: 알림만 발송합니다("클립보드에서 기밀 키 감지"). 유출된 키는 이후에도 폐기하고 재발급할 수 있으므로 클립보드는 비우지 않습니다.
                • ClickFix 명령어의 경우: 알림을 발송하고("클립보드에서 의심스러운 명령어 감지") 클립보드를 즉시 비워, 터미널, 스크립트 편집기, Spotlight 등 어디로 향하든 붙여넣기를 막습니다. 셸 기록을 감시하는 feat_clickfix_guard를 보완합니다.
                """,
                recommendation: "API 키를 복사한 후에는 어디에 붙여넣는지, 특히 AI 채팅이나 웹 양식에 주의하세요. 실수로 공유했다면 즉시 폐기하고 재발급하세요."
            ),
            LocalizedEntry(
                id: "feat_secret_leak_audit_tool",
                title: "수동 기밀 정보 / API 키 유출 감사 (텍스트 붙여넣기 또는 폴더 전체 검사)",
                summary: "붙여넣은 텍스트를 즉시 확인하거나 폴더를 재귀적으로 검사하는 온디맨드 감사 도구로, 각 키 유형별 줄 번호, 마스킹된 값, 폐기 절차를 보여줍니다. 무료 버전에서도 사용할 수 있습니다.",
                details: """
                • 열기: 악성코드 보호 → "🔑 기밀 정보・API 키 유출 수동 감사…" 또는 MCP 도구 `audit_secrets`(`text` 또는 `path` 지정).
                • 방식: 정규 표현식과 섀넌 엔트로피 점수를 함께 사용합니다. 탐지된 값은 마스킹되어 표시됩니다.
                • 폴더 검사: `.git`, `node_modules`, `target`, `vendor`, `dist`, `build`, `__pycache__`, `venv`는 자동으로 건너뛰며, 2MB를 넘는 파일과 바이너리 파일도 마찬가지입니다.
                • 권한 안내: 데스크탑이나 다운로드 같은 보호 폴더를 선택하면 macOS의 권한 요청 전에 왜 접근이 필요한지, 이 검사가 Zero Telemetry임을 일회성으로 설명합니다.
                • 백그라운드 스레드에서 실행되어 화면이 멈추지 않습니다. 어디로도 전송되지 않습니다.
                """,
                recommendation: "저장소를 공개하기 전이나 코드를 AI 채팅에 붙여넣기 전에 사용하세요."
            ),
            LocalizedEntry(
                id: "feat_package_cve_scan",
                title: "패키지 CVE 대조 (Homebrew + npm / PyPI / crates.io 등 7개 생태계, Zero Telemetry)",
                summary: "설치된 Homebrew 패키지와 사용자가 지정한 프로젝트 폴더의 의존성 잠금 파일을 기기에 보관된 알려진 CVE 맵과 대조합니다. 검사 자체는 어떤 네트워크 요청도 보내지 않습니다. 무료 버전에서도 사용할 수 있습니다.",
                details: """
                • 열기: 악성코드 보호 → "📦 패키지 CVE 대조 (Homebrew)…". 의존성은 의존성 탭에서 프로젝트 폴더를 추가하세요.
                • Homebrew: `brew list --versions` 결과를 실제 NVD 데이터로 생성한 formula-CPE 대응표와 비교합니다. 결과에는 신뢰도가 표시됩니다: confirmed(검증된 대응표) 또는 gray(검증되지 않은 키워드 일치로 오탐일 수 있음).
                • 의존성: package-lock.json / requirements.txt / Pipfile.lock / poetry.lock / Cargo.lock / Gemfile.lock / composer.lock / go.sum / pom.xml을 분석하여 npm, PyPI, crates.io, RubyGems, Packagist, Go, Maven의 알려진 CVE 맵(OSV.dev 기반, CVSS 7.0 이상)과 대조합니다.
                • 데이터 배포: CVE 맵은 서명된 매니페스트에서 하루에 한 번 수신 전용으로 받아옵니다. 받아오기 전에는 아직 다운로드되지 않았다고 표시되며 아무것도 탐지하지 않습니다.
                • MCP 도구: `run_package_cve_scan`(Homebrew)과 `run_package_cve_scan_languages`(의존성, `watchedFolders` 인자).
                """,
                recommendation: "정기적으로 Homebrew 검사를 실행하고, 진행 중인 프로젝트를 의존성 탭에 등록하며, 심각한 CVE가 있는 패키지는 신속히 업데이트하세요."
            ),
            LocalizedEntry(
                id: "feat_lockfile_tamper_guard",
                title: "의존 잠금 파일 변조 감시 (Lockfile FIM, Pro)",
                summary: "package-lock.json / yarn.lock / pnpm-lock.yaml / npm-shrinkwrap.json을 SHA-256 베이스라인으로 지속적으로 감시하여 CI나 공급망을 통한 외부 변조를 감지합니다. Pro 전용.",
                details: """
                • 여는 방법: 메뉴 바의 "🔔/✅ 의존 잠금 파일 변조를 주기적으로 감시 (Pro)" 항목으로 전환합니다.
                • 감시 대상: 패키지 CVE 대조의 "의존성" 탭에 등록한 동일한 프로젝트 폴더 안의 package-lock.json / yarn.lock / pnpm-lock.yaml / npm-shrinkwrap.json. 별도의 감시 폴더 목록을 추가하지 않습니다.
                • 감지 방식: CryptoKit을 이용한 SHA-256 베이스라인 차분. FSEvents를 통한 근실시간 감지와 1시간마다의 백스톱 스캔을 병행합니다.
                • 알림 긴급도: 감지 시점에 npm/yarn/pnpm 자체가 실행 중이면 알림 기록에는 남기되 조용한 알림으로 처리합니다. 실행 중이 아닐 때의 변조는 일반적인 긴급 알림입니다. 감지 자체는 두 경우 모두 항상 수행됩니다.
                • Pro 라이선스를 잃으면 자동으로 비활성화됩니다.
                """,
                recommendation: "중요한 프로젝트는 패키지 CVE 대조의 \"의존성\" 탭에 등록하고, Pro 활성화 시 기본값인 켜짐 상태를 유지하는 것을 권장합니다."
            ),
            LocalizedEntry(
                id: "feat_package_lifecycle_script_scan",
                title: "설치 스크립트 목록 (npm package.json lifecycle 스크립트, Pro)",
                summary: "node_modules 아래 package.json이 선언한 preinstall/install/postinstall/prepare 스크립트를 나열합니다. npm install 시 무조건 실행되는 코드를 가시화하는 것이 목적이며, 위협 판정이 아닙니다. Pro 전용.",
                details: """
                • 여는 방법: 메뉴 "악성코드 방지" → "📦 패키지 CVE 대조 (Homebrew)…" → "설치 스크립트 (npm) (Pro)" 탭. "의존성" 탭과 동일한 프로젝트 폴더를 대상으로 합니다.
                • 범위: node_modules 바로 아래 1단계(@scope/ 패키지는 한 단계 더). 패키지 자체의 중첩된 node_modules에는 내려가지 않습니다.
                • 참고용 위험 패턴 표시: curl|sh, wget|sh, eval(, base64 -d, node -e와 일치하는 명령에는 ⚠️ 배지가 표시되지만, 이는 경량 휴리스틱에 의한 참고 정보이며 많은 정상 스크립트(네이티브 모듈 빌드 등)도 해당됩니다.
                • 네트워크 연결을 전혀 하지 않으며, 스크립트를 실행하지도 않습니다. 순수한 정적 목록 표시입니다.
                • MCP 도구: `run_package_lifecycle_script_scan` (`watchedFolders` 인자, Pro 전용).
                """,
                recommendation: "⚠️ 표시가 있는 스크립트는 해당 패키지에 정말 필요한 작업인지 개별적으로 확인하세요. 낯선 패키지의 postinstall은 특히 주의가 필요합니다."
            ),
            LocalizedEntry(
                id: "feat_npm_audit_signatures",
                title: "npm 서명/출처 검증 (npm audit signatures, 옵트인, Pro)",
                summary: "npm 레지스트리와 통신하여 설치된 패키지의 서명/출처를 검증합니다. RoamSwitch 내에서 npmjs.com과 통신하는 유일한 기능으로, 기본적으로 꺼져 있으며 명시적인 옵트인과 실행마다의 확인이 필요합니다. Pro 전용.",
                details: """
                • 활성화 방법: 「📦 패키지 CVE 대조」→「npm 서명 검증 (옵트인) (Pro)」 탭의 "npm 서명 검증 활성화" 토글. 이는 각 프로젝트 폴더의 "감사 실행" 버튼을 해제할 뿐이며, 그 자체로는 아무것도 전송하지 않습니다. 실행할 때마다 "npm 레지스트리와 통신할까요?"라고 확인합니다.
                • 동작 내용: 대상 폴더를 작업 디렉터리로 하여 `npm audit signatures`를 실행하고, npm 레지스트리(registry.npmjs.org)와 통신합니다. RoamSwitch에서 npmjs.com과 통신하는 것은 이 기능뿐입니다.
                • 출력: npm의 명령 출력을 그대로 표시합니다(자체적으로 해석하거나 단정하지 않음). 종료 코드가 0이 아니거나 출력에 "invalid"/"missing registry signature" 등의 문구가 포함되면 참고용 주의 표시를 합니다.
                • npm 명령을 찾을 수 없으면 Node.js/npm 설치를 안내하는 메시지를 표시합니다.
                • MCP 도구: `run_npm_audit_signatures`(`directory` 인자, Pro와 옵트인 토글의 이중 게이트).
                """,
                recommendation: "배포 전 의존성 감사나 공급망 침해가 의심되는 사고 조사 시에만 활성화하세요. 항상 켜둘 필요는 없습니다."
            ),
            LocalizedEntry(
                id: "feat_npm_sandboxed_install",
                title: "npm/pnpm 설치 샌드박스 실행 (roamswitch-npm, Pro)",
                summary: "단순 탐지가 아니라 실제로 개입하는 래퍼로, preinstall/install/postinstall/prepare 스크립트 실행만을 네트워크가 차단된 샌드박스(sandbox-exec) 안에 가두어 실제로 설치를 대신 수행합니다. Pro 전용.",
                details: """
                • 활성화 방법: "📦 패키지 CVE 대조" → "샌드박스 설치 (npm/pnpm) (Pro)" 탭의 "설치" 버튼을 누르면 명령줄 래퍼 `roamswitch-npm`이 ~/Library/Application Support/RoamSwitch/bin/ 에 배치됩니다.
                • 2단계 흐름: ① 다운로드 단계는 `npm install --ignore-scripts` / `pnpm install --ignore-scripts`를 평소처럼 네트워크를 사용해 실행합니다. ② 스크립트 단계는 `npm rebuild` / `pnpm rebuild`(루트가 prepare를 선언한 경우 `run prepare`도 포함)를 `(deny network-outbound)`가 설정된 sandbox-exec 프로필 아래에서 실행합니다.
                • 샌드박스 방식: Linux 버전은 bwrap을 이용한 파일 시스템 제한을 사용하지만, macOS에는 동등한 기술이 없으므로 실기에서 동작이 검증된 네트워크 차단을 대신 사용합니다(`(allow default)` + `(deny network-outbound)`). 파일 읽기/쓰기와 자식 프로세스 실행은 제한하지 않습니다.
                • 셸 별칭: `npm`/`pnpm`을 래퍼 경유로 만드는 별칭 2줄을 셸 설정 파일에 추가할 수 있습니다(선택 사항, 끝에 추가만 하며 기존 내용은 변경하지 않음).
                • 미리보기: 실행 전에 프로젝트 폴더의 라이프사이클 스크립트 목록("설치 스크립트 목록" 기능과 동일한 스캐너)을 표시할 수 있습니다.
                • sandbox-exec를 사용할 수 없거나 실패하는 경우, 샌드박스 없이 조용히 실행으로 넘어가지 않습니다. yarn은 지원되지 않습니다. GTK/MCP 도구는 없습니다(터미널에서 사용하는 명령줄 도구입니다).
                """,
                recommendation: "낯선 패키지가 포함된 프로젝트나 외부에서 가져온 프로젝트에는 일반 npm/pnpm install 대신 `roamswitch-npm install`을 사용하는 것을 권장합니다."
            ),
            LocalizedEntry(
                id: "feat_typosquat_guard",
                title: "오타스쿼팅 탐지 (npm/pnpm package.json, Pro)",
                summary: "package.json의 의존성 이름을 인기 npm 패키지 이름 목록과 편집 거리(레벤슈타인 1〜2)로 비교하여 expres→express, loadash→lodash 같은 오타스쿼팅 가능성을 탐지합니다. 앱 자체는 이를 위해 네트워크 연결을 전혀 하지 않습니다. Pro 전용.",
                details: """
                • 범위: package.json의 프로젝트 자체 dependencies/devDependencies/optionalDependencies만 해당(peerDependencies는 제외). node_modules(이미 설치된 전이 의존성)도 의도적으로 제외됩니다 — 오타는 사람이 package.json에 의존성을 추가하는 순간 발생하기 때문입니다.
                • 비교 로직: 표준 레벤슈타인 거리 DP 구현으로 각 의존성 이름을 인기 npm 패키지 이름 목록과 비교합니다. 스코프가 있는 패키지(`@scope/pkg`)는 기본 이름(`pkg`)으로 비교합니다. 길이 차이가 2를 초과하는 후보는 저비용 사전 필터로 건너뜁니다. 임계값은 인기 패키지 이름이 8자 이상이면 편집 거리 2까지, 그보다 짧으면 거리 1만 허용합니다.
                • 목록이 최신 상태로 유지되는 방식: 비교 대상인 인기 패키지 이름 목록은 `PackageCveMapUpdater`가 CVE 맵과 동일하게 하루 한 번, 수신 전용, Ed25519 서명된 매니페스트를 통해 배포합니다(빌드 시점에 내장된 시드와 2단계 재정의 중 `mapVersion`이 더 최신인 쪽을 선택). 앱 릴리스를 기다리지 않고 목록을 갱신할 수 있습니다.
                • 참고 정보이며 단정이 아닙니다 — 알려진 허용 목록으로 일부 정상적인 유사 패키지(예: preact)를 제외하지만 완전하지 않습니다.
                • 여는 방법: "📦 패키지 CVE 대조" → "오타스쿼팅 탐지 (Pro)" 탭에서 "의존성" 탭과 동일한 프로젝트 폴더를 대상으로 합니다. MCP: `run_typosquat_scan`(`watchedFolders` 인자, Pro 전용).
                """,
                recommendation: "⚠️가 표시된 의존성은 실제 오타인지 개별적으로 다시 확인하세요 — 낯선 패키지 이름은 특히 주의가 필요합니다."
            ),
            LocalizedEntry(
                id: "feat_port_scan_guard",
                title: "수신 포트 스캔 탐지 (자동 차단, Pro)",
                summary: "짧은 시간(5분) 동안 여러 개의 서로 다른 포트(15개 이상)에 접속한 발신 IP를 탐지하여 알려줍니다(nmap/masscan 등 정찰 도구의 전형적인 특징). 탐지된 스캔 발신지는 기본적으로 10분간 자동으로 차단됩니다. Pro 전용.",
                details: """
                • 작동 방식: 권한을 가진 헬퍼가 `tcpdump -i pflog0`으로 pf(패쾛 필터) 로그를 감시하여, 짧은 시간 창 안에 충분히 많은 서로 다른 목적지 포트에 도달한 발신 IP를 탐지합니다. 판정은 로그 기록에만 기반하며 통신 내용 자체를 변경하거나 검사하지 않습니다. Linux 버전의 `port_scan_detect.rs`(nftables `log` + `journalctl`)에 해당합니다.
                • 자동 차단: 탐지된 스캔 발신지는 `PFRulesetCoordinator`를 통해 pf 규칙에 추가되어 기본적으로 10분간 차단됩니다. 자동 차단은 탐지 기능 자체와 별도로 켜고 끈 수 있습니다.
                • 알림: 탐지(및 차단)할 때마다 macOS 알림이 발송되며, 통합 인시던 타임라인에도 기록됩니다.
                • 여는 방법: 메뉴 막대 → “포트 및 장치 모니터링” → “🔍 수신 포트 스캔 탐지 (Pro)”. 활성화와 비활성화 모두 확인 대화상자를 거칩니다. 기본값은 꺼짐입니다.
                """,
                recommendation: "IP별 허용 목록은 없으며, 차단은 10분 후 자동으로 해제됩니다. 집이나 회사에서 정당한 스캔 도구(자산 관리, 취약점 진단 등)를 정기적으로 실행한다면, 반복적인 오탐 차단을 피하기 위해 실행 중에는 자동 차단만 꺼두고 탐지(알림)만 켜두는 것을 고려하세요."
            ),
            LocalizedEntry(
                id: "feat_sensor_pairing",
                title: "RoamSwitch Sensor 페어링 (페어링 코드 방식, Pro)",
                summary: "동일 LAN에 있는 별도 제품인 “RoamSwitch Sensor”(전용 능동 감사 허브)와의 상호 신뢰 페어링을 관리합니다. Sensor가 발급하는 페어링 코드를 사용하는 능동 페어링 방식이며, Sensor가 고정 IP로 운영됨을 전제로 mDNS 자동 검색은 사용하지 않습니다. Pro 전용.",
                details: """
                • 작동 방식: 이 기기 자체의 Ed25519 키 쌍을 생성·영구 저장합니다. 페어링 시 이 기기는 Sensor 운영자가 발급한 일회용 페어링 코드(발급 후 10분 만료)와 이 기기의 주소·호스트 이름을 함께 사용해 Sensor의 TCP 리스너(포트 50543)에 연결합니다. 코드가 유효하면 Sensor는 이 기기의 공개 키를 신뢰 목록에 등록합니다.
                • 감사 요청: 페어링 후 “Sensor에 감사 요청”으로 Sensor에 능동 감사(도달 가능성 확인) 실행을 요청할 수 있습니다. 결과는 Sensor 측에서 비동기로 생성되므로, 이 기기 측의 상시 실행되는 권한 있는 헬퍼가 5분 간격으로 최대 5회까지 자동으로 결과를 가져옵니다. 가져온 결과는 이 기기에도 저장되며 설정 화면의 “감사 결과” 목록에서 확인할 수 있습니다.
                • 여는 방법: 메뉴 막대 → “포트 및 장치 모니터링” → “🔍 RoamSwitch Sensor 페어링…”. 이 기기 자체의 공개 키/주소 표시(복사 버튼 포함), 페어링된 Sensor 목록(해제 버튼), 페어링 코드 입력 양식, 감사 결과 목록을 제공합니다.
                • Linux 버전(`roamswitch-core::sensor_pairing`)과 동일한 TCP 제어 프로토콜(포트 50543, 줄바꿈으로 구분된 JSON, Ed25519 서명)을 사용합니다.
                """,
                recommendation: "실제로 본인이 직접 설치한 RoamSwitch Sensor의 운영자 화면에서 발급된 페어링 코드만 사용하세요. 낯선 코드를 입력하라는 요청을 받으면 페어링하지 말고 네트워크 관리자에게 확인하는 것을 권장합니다."
            ),
            LocalizedEntry(
                id: "feat_security_health_checker",
                title: "Mac 보안 진단 (18개 항목, 점수와 개선 단계)",
                summary: "시스템 강화, 네트워크 방어, 인증 및 접근 제어, 포트 노출, 악성코드 보호, 물리적 기기 방어 등 6개 영역 18개 항목을 검사하여 0~100점의 점수, 등급, 실패 항목별 개선 단계를 보여줍니다. 무료 버전에서도 사용할 수 있습니다.",
                details: """
                • 시스템 강화: 1. FileVault, 2. SIP(시스템 무결성 보호), 3. Gatekeeper, 4. 자동 보안 업데이트, 5. Apple XProtect.
                • 네트워크 방어: 6. macOS 방화벽, 7. 스텔스 모드, 8. Wi-Fi 암호화 강도, 9. ARP 스푸핑 모니터, 10. 게이트웨이 ARP 고정.
                • 인증 및 접근 제어: 11. SSH 원격 로그인 설정(root 로그인 비활성화, 키 전용 인증), 12. sudo 권한 상승(`NOPASSWD` 감사).
                • 서비스 및 포트 노출: 13. 노출된 포트.
                • 악성코드 및 다운로드 보호: 14. 웹 및 이메일 보호, 15. DNS 위협 보호, 16. 피싱 및 악성 링크 보호(Safari 사기 웹사이트 경고).
                • 물리적 포트 및 기기: 17. 무단 USB / BadUSB 물리 포트 가드, 18. macOS 액세서리 연결 보호(Apple 실리콘).
                • 해당 없음 처리: 신뢰 네트워크에서의 방화벽과 스텔스 모드, 원격 로그인이 꺼져 있을 때의 SSH, 헬퍼 연결 전의 sudo 감사, Intel Mac의 액세서리 보호는 점수 계산에서 제외됩니다.
                • 등급: 100점은 S, 85~99점은 A, 70~84점은 B, 70점 미만은 C입니다. MCP 도구 `get_security_report`로도 확인할 수 있습니다.
                """,
                recommendation: "정기적으로 진단 보고서를 열어 ⚠️로 표시된 항목을 제시된 개선 단계에 따라 처리하고 A 등급 이상을 유지하세요."
            ),
            LocalizedEntry(
                id: "feat_autonomous_sentinel",
                title: "백그라운드 자율 순찰, ClamAV 정의 업데이트 & 예약 검사",
                summary: "4시간마다 백그라운드에서 보안 진단, 포트, USB 기기, XProtect 상태를 갱신합니다(모든 버전). Pro는 추가로 점수 하락을 경고하고, ClamAV 정의를 자동으로 업데이트하며, 매일 바이러스 검사를 실행합니다.",
                details: """
                • 정기 진단(모든 버전): 실행 후 약 30초 뒤부터 시작하여 이후 4시간마다 실행되므로, 한 네트워크에 몇 시간 동안 머물러도 결과가 최신 상태로 유지됩니다.
                • 점수 하락 경고(Pro): 점수가 80 미만이거나 4개 이상의 항목이 실패하면 알립니다.
                • ClamAV 정의(Pro): 조용히 `freshclam`을 실행합니다.
                • 예약 검사(Pro): 하루에 한 번 `~/Downloads`, `~/Desktop`, `~/Library/LaunchAgents`를 ClamAV로 검사합니다. 위협이 발견되면 자동으로 격리하고 긴급 경보를 보내며, 깨끗한 결과는 조용한 완료 알림만 표시합니다. EICAR 테스트 시그니처만 발견된 경우에는 아무것도 표시하지 않고 알림 기록에만 남깁니다.
                """,
                recommendation: "Pro 버전에서는 ClamAV를 설치해 정의 업데이트와 예약 검사가 자동으로 실행되도록 하세요."
            ),
            LocalizedEntry(
                id: "feat_simulation_self_test",
                title: "시뮬레이션(자체 테스트) 도구",
                summary: "실제 공격이나 파일 손상 없이 랜섬웨어 방어, 악성코드 탐지 연동 에어갭, Docker 위험 탐지가 제대로 작동하는지 안전하게 테스트합니다.",
                details: """
                • 위치: 악성코드 보호 (XProtect & ClamAV) 하단.
                • 🚨 랜섬웨어 방어 시뮬레이션(동작 확인)…: 암호화 시도가 탐지된 경우와 같은 단계를 실행하여 에어갭과 긴급 창을 확인합니다. 어떤 파일도 손상되지 않습니다.
                • 🚨 멀웨어 감지 연동 Air-Gap 시뮬레이션(동작 확인)…: 실제 XProtect 탐지와 같은 단계를 실행하여 봉쇄와 긴급 창을 확인합니다. 이벤트에는 시뮬레이션이라고 표시됩니다.
                • ⚠️ Docker 위험 감지 시뮬레이션(동작 확인)…: 특권 컨테이너 알림이 도착하는지 확인합니다. Docker는 건드리지 않습니다.
                • 참고: 에어갭 테스트는 실제로 네트워크를 일시적으로 차단합니다. 긴급 창에서 해제하세요(10분 안에 스스로 복구되기도 합니다).
                • 다운로드 보호를 테스트하려면 무해한 EICAR 테스트 파일을 사용할 수 있습니다(배너는 없고 알림 기록에 남습니다).
                """,
                recommendation: "Pro를 활성화하거나 설정을 변경한 뒤 한 번 시뮬레이션을 실행하여 알림과 에어갭이 예상대로 동작하는지 확인하세요."
            ),
            LocalizedEntry(
                id: "feat_privileged_helper",
                title: "특권 헬퍼 도구 (RoamSwitchHelper, XPC)",
                summary: "root 권한이 필요한 작업(PF 방화벽, 공유 서비스, DNS, 에어갭 등)만 권한이 분리된 LaunchDaemon 헬퍼가 XPC를 통해 수행합니다.",
                details: """
                • 권한 분리: 메인 앱은 일반 사용자 권한으로 실행되며, pf 규칙 변경, 공유 데몬 제어, DNS 설정, ARP 고정, 중요 파일 해시 계산 등만 `RoamSwitchHelper`에 위임합니다.
                • 등록 방식: macOS의 SMAppService를 통해 앱에 내장된 LaunchDaemon으로 등록됩니다. 처음 사용할 때는 시스템 설정 → 일반 → 로그인 항목 및 확장 프로그램에서 승인이 필요합니다. 앱이 응용 프로그램 폴더에 없으면 등록할 수 없습니다(faq_install_location).
                • 부속 데몬: 에어갭 안전장치(10분 후 자동 해제)와 부팅 게이트(최대 90초)를 위한 헬퍼 LaunchDaemon도 함께 등록됩니다.
                • 검증: XPC 연결 시 코드 서명(Team ID)을 확인하여 권한 없는 프로세스의 호출을 거부합니다.
                • 업데이트 후 재승인: 앱이 새 헬퍼로 자동 전환을 시도하지만, macOS가 재승인 대기 상태로 남겨둘 수 있습니다. 이 경우 메뉴 막대 아이콘이 경고 표시로 바뀌며 \u{201C}⚠️ 업데이트 후 재승인이 필요합니다\u{201D}가 표시되고, 알림으로도 안내됩니다.
                """,
                recommendation: "처음 실행할 때 표시되는 안내에 따라 헬퍼를 승인하세요. 승인되지 않았다면 메뉴에 \u{201C}⚠️ 헬퍼 승인…\u{201D}이 표시됩니다. 업데이트 후 이 표시나 알림이 나타나도 같은 방법(시스템 설정 > 일반 > 로그인 항목 및 확장 프로그램)으로 재승인할 수 있습니다."
            ),
            LocalizedEntry(
                id: "feat_mcp_server",
                title: "MCP 서버 연동 (AI 도우미를 위한 읽기 전용 접근)",
                summary: "RoamSwitch.app에는 읽기 전용 MCP(Model Context Protocol) 서버가 포함되어 있어 Claude 같은 AI 도우미가 Mac의 보안 상태를 물어볼 수 있습니다. 설정을 바꾸거나 무언가를 차단하는 도구는 없습니다.",
                details: """
                • 전송 방식: 로컬 stdio만 사용합니다. 실행 파일: `/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`.
                • 주요 도구: `get_security_report`(보안 진단), `get_exposed_ports`, `get_guard_status`, `audit_url_safety`, `audit_secrets`, `audit_security_logs`, `get_quarantine_status`, `get_notification_history`, `get_canary_status`, `get_port_anomaly_incidents`, `get_runtime_threat_status`, `get_incident_timeline`(봉쇄 사고 타임라인), `get_network_history`(네트워크 이력 학습), `run_package_cve_scan`, `run_package_cve_scan_languages`, `run_active_vuln_scan`(트래픽을 전송하는 유일한 도구로, 127.0.0.1로만 비파괴적 프로브를 보냄), `get_app_help`(이 지식 베이스).
                • 리소스: `roamswitch://docs/features`, `roamswitch://docs/alerts-and-messages`, `roamswitch://docs/settings-guide`, `roamswitch://docs/troubleshooting`.
                • 언어: 응답은 앱의 언어 설정을 따릅니다. `get_app_help`는 `language` 인자(ja / en / zh-Hans / zh-Hant / ko / de / fr / es / it / pt-PT)를 받습니다.
                • 안전성: 읽기 전용이므로 프롬프트 주입에 조작된 AI라도 보호 수준을 바꾸거나 포트를 격리할 수 없습니다.
                """,
                recommendation: "설정 방법은 faq_mcp_setup을 참고하세요. \u{201C}지금 내 Mac이 안전한가요?\u{201D}나 \u{201C}이 알림은 무슨 뜻인가요?\u{201D}처럼 자연스러운 말로 물어볼 수 있습니다."
            ),
            LocalizedEntry(
                id: "feat_license_pro_tier",
                title: "Pro 평생 라이선스 (일회성 구매, 최대 2대의 Mac)",
                summary: "Pro는 최대 2대의 Mac에서 사용할 수 있는 일회성 평생 라이선스(¥2,980 / $19.99)입니다. Ed25519로 서명된 라이선스 토큰이 기기 내에서 검증되므로 활성화 후에는 오프라인에서도 Pro가 계속 작동합니다.",
                details: """
                • Pro 기능: 메뉴에서 (Pro)로 표시된 자동 방어(랜섬웨어 미끼 파일 탐지, XProtect 연동 차단, 알 수 없는 포트 자동 차단 및 개발 서버 격리, ARP 스푸핑 자동 차단, 게이트웨이 ARP/NDP 고정, VPN 터널, BadUSB 및 USB 저장장치 가드, 웹 및 이메일 보호, DNS 위협 보호, 링크 보호, Bluetooth 자동 끄기, ClickFix 대책, 자동 실행 등록 감시, Docker 위험 탐지, 중요 파일 변조 감시, 자동 로그 감사), 실시간 위협 알림, 순찰 경고 및 예약 검사, 로그 CSV 내보내기 등입니다.
                • 라이선스 종류: Pro 평생 라이선스(2대) 및 Team 평생 라이선스(5대).
                • 활성화: "💎 Pro 버전 인증 / 구매…"에서 라이선스 키(ROAM-XXXX-…)를 입력합니다. 서버가 발급한 서명된 토큰은 앱 내장 공개 키로 검증되어 Keychain에 저장됩니다.
                • 비활성화: 라이선스 창에서 진행합니다. 이 Mac에서 라이선스를 제거하고 서버의 자리를 반납합니다(네트워크 요청이 실패해도 로컬 비활성화는 항상 이루어집니다).
                • 만료 시: Pro 전용 가드가 자동으로 꺼지고 VPN 터널과 포트 격리도 해제됩니다.
                """,
                recommendation: "자동 봉쇄, 실시간 방어, 순찰 경고가 필요하다면 Pro를 고려하세요. Mac을 교체할 때는 기존 기기에서 먼저 비활성화한 후 새 기기에서 활성화하세요."
            ),
        ]
    }

    // MARK: - Alerts: network, devices, links

    private static func alertsKoNetwork() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "alert_arp_spoofing",
                title: "⚠️ ARP 스푸핑(중간자 공격) 경고",
                summary: "네트워크의 어떤 기기가 라우터(게이트웨이)로 위장하여 트래픽을 도청하거나 변조하려는 징후가 있을 때 표시됩니다.",
                details: """
                • 원인: 공격자가 위조된 ARP 응답을 보내 트래픽이 자신을 거치도록 만듭니다(중간자 공격). 게이트웨이의 IP는 그대로인데 MAC 주소가 갑자기 바뀌면 감지됩니다. 라우터 재부팅이나 메시 Wi-Fi 전환으로도 발생할 수 있습니다.
                • 자동 방어: 최대 잠금에서 "ARP 스푸핑(네트워크 위장) 감지 시 자동 차단 (Pro)"이 켜져 있으면 즉시 에어갭 봉쇄가 실행됩니다. 다른 등급에서는 알림만 발송되며, 메뉴에 "ARP 스푸핑 감지 — 지금 전체 차단"이 표시됩니다.
                """,
                recommendation: """
                1. 이 네트워크에서 비밀번호 입력, 결제, 업무 트래픽을 즉시 중단하세요.
                2. 공용 Wi-Fi나 낯선 네트워크라면 메뉴에서 "지금 전체 차단"을 선택하거나 Wi-Fi를 꺼세요.
                3. 인터넷이 필요하다면 테더링이나 VPN 터널 같은 안전한 연결로 전환하세요.
                4. 집 라우터를 방금 재부팅한 경우처럼 오탐임을 확실히 알 때만 계속 사용하세요.
                """
            ),
            LocalizedEntry(
                id: "alert_evil_twin_ssid",
                title: "⚠️ 이블 트윈으로 의심되는 Wi-Fi 네트워크 감지",
                summary: "연결한 Wi-Fi의 이름(SSID)이 이전에 사용했던 네트워크와 매우 비슷할 때 표시됩니다. 악의적인 가짜 액세스 포인트(이블 트윈)일 수 있습니다.",
                details: """
                • 원인: 공격자가 정당한 네트워크와 한두 글자만 다른 이름의 가짜 액세스 포인트를 설치해 사람들을 유인합니다. 네트워크 이력 학습(feat_network_history_guard)이 학습된 이름과의 편집 거리, 그리고 다른 게이트웨이 하드웨어를 근거로 판단합니다.
                • 오탐 방지: 짧은 이름과 같은 게이트웨이 하드웨어가 방송하는 추가 SSID는 표시되지 않습니다.
                • 자동 방어: 알림만 발송됩니다. 등록되지 않은 네트워크로서 외부 기본 보호 등급이 적용됩니다.
                """,
                recommendation: """
                1. 이 Wi-Fi에서 로그인하거나 개인정보를 입력하지 마세요.
                2. 공식 네트워크 이름(매장이나 사무실의 안내판)을 확인하고 일치하지 않으면 연결을 끊으세요.
                3. 계속 사용해야 한다면 VPN 터널을 연결하세요.
                """
            ),
            LocalizedEntry(
                id: "alert_unencrypted_wifi",
                title: "⚠️ 암호화되지 않은 Wi-Fi에 연결됨",
                summary: "비밀번호나 암호화(WPA2 / WPA3)가 없는 개방형 Wi-Fi 또는 오래된 WEP 네트워크에 연결했을 때 표시됩니다.",
                details: """
                • 원인: 무선 연결이 암호화되지 않아 근처의 누구나 트래픽을 가로챌 수 있습니다.
                • 자동 방어: 등록되지 않은 네트워크라면 외부 기본 보호(초기값 최대 잠금)가 수신 연결과 공유 서비스를 차단합니다.
                """,
                recommendation: """
                1. 가능하다면 VPN 터널을 연결하거나 테더링 같은 신뢰할 수 있는 연결로 전환하세요.
                2. HTTPS가 아닌 사이트에서 로그인하거나 개인정보를 입력하지 마세요.
                3. 메뉴에서 보호 수준이 최대 잠금인지 확인하세요.
                """
            ),
            LocalizedEntry(
                id: "alert_port_anomaly",
                title: "🚨 알 수 없는 리스닝 포트를 자동 차단함",
                summary: "이전에 노출되지 않았던 프로그램이 0.0.0.0으로 LAN에 포트를 노출하기 시작하여 외부 접근이 자동으로 차단되었을 때 표시됩니다(차단이 실패하면 \u{201C}알 수 없는 리스닝 포트 감지(차단 실패)\u{201D}가 표시됩니다).",
                details: """
                • 원인: 개발 서버(Next.js, Vite, Python, Docker) 실행, LocalSend나 Syncthing 같은 LAN 수신 앱의 첫 실행, 또는 백도어나 악성 앱이 리스닝을 시작한 경우입니다.
                • 자동 방어: pf가 외부 접근만 차단합니다(Mac 자체와 localhost에서는 계속 사용 가능). macOS 시스템 데몬은 제외됩니다.
                """,
                recommendation: """
                1. 알림에 표시된 프로세스 이름, PID, 포트가 낯익은지 확인하세요(외부 공개 포트에서도 볼 수 있습니다).
                2. 본인의 서버나 LAN 수신 앱이라면 알림의 "허용" 버튼이나 포트 진단 화면에서 허용하세요. 이후부터는 계속 허용됩니다.
                3. 개발 서버는 `127.0.0.1`에 바인딩하여 다시 시작하는 것이 가장 안전합니다.
                4. 알아볼 수 없다면 차단 상태를 유지하고 해당 프로세스를 종료한 뒤 보안 진단과 바이러스 검사를 실행하세요.
                """
            ),
            LocalizedEntry(
                id: "alert_exposed_database",
                title: "🚨 인증되지 않은 데이터베이스 서비스가 외부에 노출됨",
                summary: "기본적으로 인증이 없는 경우가 많은 서비스(Redis, MongoDB, Memcached, Elasticsearch)가 방화벽 보호 없이 LAN에 노출되었을 때 표시됩니다.",
                details: """
                • 원인: 현재 보호 수준이 수신 연결을 허용하는 상태에서 데이터베이스나 백엔드 서비스가 0.0.0.0으로 시작되었습니다. 같은 네트워크의 누구든 데이터를 읽거나 쓸 수 있을 수 있습니다.
                • 자동 방어: 알림(Pro)만 발송하며 같은 포트에 대해 반복 알림하지 않습니다.
                """,
                recommendation: """
                1. 서비스의 리스닝 주소를 `127.0.0.1`로 바꾸거나 인증을 활성화하세요.
                2. 바로 고칠 수 없다면 외부 공개 포트에서 해당 포트를 열고 "외부 격리 실행"을 선택하세요.
                3. 공용 네트워크에서는 최대 잠금을 사용하세요.
                """
            ),
            LocalizedEntry(
                id: "alert_unapproved_keyboard",
                title: "⚠️ 무단 키보드 / BadUSB 연결 감지",
                summary: "허용 목록에 없는 새 USB 키보드(또는 개조된 케이블처럼 키보드로 위장한 기기)가 연결되어 승인될 때까지 키 입력이 차단되었을 때 표시되는 알림과 승인 창입니다.",
                details: """
                • 원인: 새로운 외장 키보드나 도킹 스테이션 연결, 또는 Rubber Ducky 같은 키 입력 주입 기기입니다.
                • 자동 방어: 해당 기기의 키 입력만 차단됩니다(다른 키보드는 계속 사용 가능). "⚠️ 알 수 없는 USB 기기 / 키보드 연결 감지" 창이 승인을 요청합니다.
                """,
                recommendation: """
                1. 본인이 직접 연결한 신뢰할 수 있는 키보드라면 "신뢰하고 허용"을 클릭하세요. 허용 목록에 추가되고 입력이 활성화됩니다.
                2. 알아볼 수 없거나 아무것도 연결하지 않았는데 나타났다면 "거부하고 차단 유지"를 클릭하고 기기를 뽑으세요.
                """
            ),
            LocalizedEntry(
                id: "alert_scripted_keyboard",
                title: "🚨 이 키보드는 자동화(스크립트) 입력의 징후를 보입니다",
                summary: "승인을 기다리는 키보드가 사람이 낼 수 없을 정도로 빠르고 균일한 간격으로 키 입력을 보낼 때 표시됩니다. 자동화된 명령어 주입(BadUSB 공격)일 가능성이 매우 높습니다.",
                details: """
                • 원인: Rubber Ducky, Flipper Zero, Arduino / Digispark 등이 미리 준비된 명령어를 빠른 속도로 입력하려고 시도했습니다. 키 입력 타이밍 분석으로 판정합니다: 최소 5회 이상의 간격 후 평균이 12ms 이하이거나, 45ms 이하이면서 매우 균일한 경우.
                • 자동 방어: 해당 기기의 키 입력은 승인 전부터 이미 차단되어 Mac에 도달하지 않았습니다. 이 경고는 판단에 도움이 되는 추가 증거를 제공할 뿐입니다.
                """,
                recommendation: """
                1. 승인 창에서 반드시 "거부하고 차단 유지"를 선택하세요.
                2. 기기를 즉시 뽑고 어디서 왔는지 확인하세요(주운 USB 스틱, 선물 받은 케이블 등).
                3. 만약을 위해 보안 진단을 실행하고 자동 실행 등록을 검토하세요.
                """
            ),
            LocalizedEntry(
                id: "alert_untrusted_usb",
                title: "🔒 USB 저장장치를 읽기 전용으로 마운트함 / 🔌 무단 USB 저장장치를 자동 차단함",
                summary: "허용 목록에 없는 USB 드라이브나 외장 디스크가 연결되어 승인을 기다리며 읽기 전용으로 마운트되었거나, 꺼내졌을 때 표시됩니다.",
                details: """
                • 원인: 등록되지 않은 저장장치가 연결되었습니다. 데이터 탈취와 악성 파일 유입을 방지합니다.
                • 자동 방어: 읽기 전용으로 다시 마운트되며 "USB 저장장치 '…'을(를) 허용하시겠습니까?" 대화상자가 표시됩니다. 꺼내기를 선택하면 즉시 꺼내지고 "무단 USB 저장장치를 자동 차단함" 알림이 발송됩니다.
                """,
                recommendation: """
                1. 본인의 기기라면 "읽기・쓰기 허용" 또는 "읽기 전용으로 허용"을 선택하세요. 허용 목록에 추가되어 다음번에는 자동으로 적용됩니다.
                2. 알아볼 수 없다면 "꺼내기"를 선택하세요.
                3. 허용 목록은 나중에 "USB / BadUSB 가드 설정…"에서 변경할 수 있습니다.
                """
            ),
            LocalizedEntry(
                id: "alert_malware_usb",
                title: "🚨 USB 저장장치에서 악성코드 감지됨",
                summary: "USB 저장장치를 읽기・쓰기로 연결하기 전에 실행되는 ClamAV 검사에서 감염된 파일이 발견되었을 때 표시됩니다.",
                details: """
                • 원인: USB 드라이브에 감염된 파일이 있습니다.
                • 자동 방어: 볼륨이 즉시 꺼내져 Mac이 감염되지 않도록 합니다.
                """,
                recommendation: """
                1. 다시 사용하기 전에 별도의 안전한 환경에서 드라이브를 포맷하거나 치료하세요.
                2. ClamAV 빠른 검사나 폴더 검사를 실행하여 Mac 자체가 감염되지 않았는지 확인하세요.
                """
            ),
            LocalizedEntry(
                id: "alert_link_guard_blocked",
                title: "🛑 링크 보호: 연결이 차단됨",
                summary: "링크 보호가 사기나 피싱이 의심되는 사이트(위협 정보에 등록되었거나 브랜드 동형 문자)로의 연결을 자동으로 차단했을 때 표시됩니다.",
                details: """
                • 원인: 이메일이나 소셜 미디어의 링크, 광고, 앱이 알려진 사기 도메인에 연결을 시도했습니다.
                • 자동 방어: 어떤 브라우저나 앱이든 시스템 확장이 연결을 폐기하거나, hosts 대체 방식이 해당 도메인을 0.0.0.0으로 해석합니다.
                """,
                recommendation: """
                1. 예상하지 못한 것이라면 별도의 조치는 필요 없지만, 해당 페이지에 정보를 입력하지 마세요.
                2. 필요한 정당한 사이트가 실수로 차단되었다면 알림의 "이번만 허용(5분)"을 사용하거나 허용 목록에 추가하세요.
                """
            ),
            LocalizedEntry(
                id: "alert_link_guard_warn_hold",
                title: "⚠️ 링크 보호: 연결 보류 중",
                summary: "경고 모드에서 브랜드 위장이나 사기 사이트로 의심되는 연결이 사용자의 허용 여부 결정을 기다리며 일시 정지되었을 때 표시되는 알림과 최전면 패널입니다.",
                details: """
                • 원인: 경고를 유발하는 도메인(서브도메인 위장, 고위험 TLD 등)으로의 연결입니다.
                • 자동 방어: 해당 연결이 답변을 기다리며 일시 정지됩니다. 약 8초 안에 응답이 없으면 차단됩니다(실패 시 차단). 이 결과는 캐시되지 않으므로 다음 방문 시 다시 물어봅니다. 실제로 내린 답변은 기억됩니다.
                """,
                recommendation: """
                1. 직접 의도해서 연 것이고 신뢰하는 사이트라면 "허용"을 선택하세요.
                2. 알아볼 수 없거나 확신이 없다면 "차단"을 선택하거나 그냥 기다리세요(자동으로 차단됩니다).
                3. 실수로 차단되었다면 페이지를 다시 불러오면 다시 물어봅니다.
                """
            ),
            LocalizedEntry(
                id: "alert_dangerous_url",
                title: "🛑 위험한 링크 / 피싱 의심 (링크 안전성 진단)",
                summary: "링크 안전성 진단(또는 `audit_url_safety`)이 동형 문자, 위장된 서브도메인, 고위험 TLD 등으로 인해 URL이 위험하다고 판단했을 때 표시됩니다.",
                details: """
                • 검사 항목: 동형 문자(Punycode), 대기업을 흉내 낸 서브도메인, 피싱에서 흔한 TLD, 평문 HTTP, 원시 IP 주소 등입니다.
                • 점수: 50점 미만은 위험, 50~79점은 주의입니다.
                """,
                recommendation: """
                1. 해당 링크를 열지 마세요.
                2. 메시지를 삭제하고 필요하다면 보안 담당자에게 신고하세요.
                """
            ),
            LocalizedEntry(
                id: "alert_helper_disconnected",
                title: "⚠️ 헬퍼가 연결되지 않음",
                summary: "특권 헬퍼 도구(RoamSwitchHelper)와의 XPC 통신을 수립할 수 없을 때 표시됩니다.",
                details: """
                • 원인: 로그인 항목 및 확장 프로그램에서 백그라운드 실행이 승인되지 않았거나, macOS 업데이트 후 헬퍼가 멈췄거나, 앱이 응용 프로그램 폴더 밖(다운로드 폴더나 디스크 이미지 안)에 있는 경우입니다.
                • 영향: root 권한이 필요한 작업(보호 수준 전환, 에어갭 봉쇄, DNS 설정, 중요 파일 감시 등)을 실행할 수 없습니다.
                """,
                recommendation: """
                1. 메뉴에서 "⚠️ 헬퍼 승인…"을 선택해 승인 단계를 여세요.
                2. 시스템 설정 → 일반 → 로그인 항목 및 확장 프로그램에서 "백그라운드에서 실행 허용"에 RoamSwitchHelper를 켜세요.
                3. RoamSwitch가 응용 프로그램 폴더에 있는지 확인하세요.
                4. 그래도 해결되지 않으면 faq_helper_troubleshooting의 절차를 따르세요.
                """
            ),
            LocalizedEntry(
                id: "alert_score_drop",
                title: "⚠️ Mac 보안 저하 경고",
                summary: "보안 점수가 80 미만이거나 4개 이상의 항목이 실패했을 때 자율 순찰이 발송하는 알림입니다(Pro).",
                details: """
                • 원인: FileVault나 방화벽이 꺼지거나, 위험한 포트가 노출되거나, 어떤 가드가 정지되는 등 설정이나 환경의 변화입니다.
                • 기준: 점수 80 미만, 또는 실패 항목 4개 이상.
                """,
                recommendation: """
                1. 메뉴에서 진단 보고서를 열거나(또는 MCP 도구 `get_security_report` 사용).
                2. 표시된 개선 단계에 따라 ⚠️로 표시된 항목을 처리하세요.
                """
            ),
        ]
    }

    // MARK: - Alerts: malware, containment, audit

    private static func alertsKoMalware() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "alert_quarantined_download",
                title: "🚨 위험한 다운로드 파일을 격리함",
                summary: "브라우저, Mail, 채팅 앱에서 저장된 파일에 위협이 포함되어 격리소로 이동되었을 때 표시됩니다(이동이 실패하면 \u{201C}격리 실패\u{201D}가 표시됩니다).",
                details: """
                • 원인: 다운로드한 파일에 악성코드, 트로이 목마, 리버스 셸 등이 포함되어 있습니다.
                • 자동 방어: `~/Library/Application Support/RoamSwitch/Quarantine/`으로 이동되어 실행할 수 없게 됩니다. 정적 시그니처 검사가 탐지했지만 ClamAV는 그렇지 않았다면, 알림에 오탐일 수 있다는 내용이 표시됩니다.
                """,
                recommendation: """
                1. 격리가 성공했다면 해당 파일은 실행할 수 없습니다.
                2. "📦 격리 파일 관리…"를 열어 알아볼 수 없다면 "완전히 삭제"를 선택하세요.
                3. 확실한 오탐일 때만 "복원"이나 "제외하고 복원"을 사용하세요.
                4. 격리가 실패했다면 알림에 표시된 경로의 파일을 수동으로 삭제하세요.
                """
            ),
            LocalizedEntry(
                id: "alert_eicar_test_signature",
                title: "🧪 EICAR 테스트 시그니처 감지(무해) — 알림 기록에만 기록됨",
                summary: "백신 소프트웨어를 확인하는 데 사용되는 무해한 EICAR 테스트 파일이 어떻게 처리되는지 설명합니다. 실제 위협이 아니므로 배너가 표시되지 않고 격리되거나 차단되지 않으며 알림 기록에만 기록됩니다.",
                details: """
                • 적용 범위: 웹 및 이메일 보호, ClamAV 빠른/폴더 검사, 순찰의 예약 검사 모두 동일하게 적용됩니다.
                • 동작: 파일은 그대로 남습니다. "EICAR 테스트 시그니처 감지(무해)"가 "🔔 알림 기록…"에 기록됩니다.
                • 이유: 위협이 아닌 것에 경고 배너를 표시하면 정말 중요한 경고가 묻히게 되기 때문입니다.
                """,
                recommendation: """
                1. 별도의 조치는 필요 없습니다. 테스트를 위해 파일을 두었다면 결과를 확인한 후 삭제하세요.
                2. 알림 기록에 해당 기록이 있는지 확인하면 검사가 정상 작동하는지 알 수 있습니다.
                """
            ),
            LocalizedEntry(
                id: "alert_pickle_model",
                title: "⚠️ Pickle 형식 AI 모델 다운로드 감지",
                summary: "`.pkl` / `.pickle` / `.pt` AI 모델 파일이 다운로드되었을 때 표시됩니다. Pickle 형식은 로드되는 것만으로도 임의 코드를 실행할 수 있습니다.",
                details: """
                • 원인: Hugging Face, Civitai 등에서 모델 파일이 저장되었습니다.
                • 자동 방어: 경고만 표시됩니다(파일은 격리되지 않습니다).
                """,
                recommendation: """
                1. 신뢰할 수 있는 공식 출처가 아니라면 모델을 로드하지 마세요.
                2. 가능하다면 같은 모델의 `.safetensors`나 `.gguf` 형식을 사용하세요.
                """
            ),
            LocalizedEntry(
                id: "alert_ransomware_activity",
                title: "🚨 [긴급 자동 방어] 랜섬웨어 활동이 차단됨",
                summary: "미끼(canary) 파일이 수정, 삭제, 이름 변경되어 에어갭 봉쇄, 공유 종료, 의심 프로세스 정지가 발동되었을 때 표시되는 긴급 알림과 긴급 창입니다.",
                details: """
                • 원인: 랜섬웨어와 같은 프로세스가 사용자 폴더의 파일을 암호화하거나 파괴하려고 시도했습니다(또는 시뮬레이션 실행).
                • 자동 방어: 모든 트래픽 차단과 Wi-Fi 무선 끄기, SMB / SSH / 화면 공유 정지, 의심 프로세스 정지(SIGSTOP)가 실행됩니다. 긴급 창에는 차단 성공 여부, 의심 프로세스, 영향을 받았을 수 있는 파일이 표시됩니다.
                """,
                recommendation: """
                1. 작업 중이던 파일을 저장하고 의심스러운 앱을 모두 종료하세요.
                2. 활동 모니터에서 CPU나 디스크 쓰기가 급증한 프로세스를 찾아 알아볼 수 없다면 강제 종료하세요.
                3. 영향을 받았을 수 있는 파일과 백업(Time Machine 등)을 확인하세요.
                4. 안전을 확인한 후 긴급 창에서 봉쇄를 해제하세요(네트워크가 복원되고 정지된 프로세스가 재개되며 미끼 파일이 다시 생성됩니다).
                """
            ),
            LocalizedEntry(
                id: "alert_runtime_threat_airgap",
                title: "🚨 XProtect가 악성코드를 탐지함 — 네트워크가 자동으로 차단됨",
                summary: "Apple의 XProtect / XProtect Remediator가 파일을 악성코드로 판정하여 XProtect 연동 자동 차단이 에어갭 봉쇄를 발동했을 때 표시되는 긴급 창과 알림입니다.",
                details: """
                • 원인: Apple의 악성코드 엔진이 다운로드하거나 실행한 파일을 악성으로 판단했습니다.
                • 자동 방어: 모든 트래픽 차단과 Wi-Fi 무선 끄기가 실행되며, 해제하지 않아도 최대 10분 안에 자동으로 복구됩니다. 탐지한 프로세스, 카테고리, Apple의 탐지 메시지가 기록됩니다.
                """,
                recommendation: """
                1. 방금 다운로드하거나 실행한 파일이나 앱을 찾아 삭제하세요.
                2. ClamAV 검사와 보안 진단을 실행하고, 자동 실행 등록(LaunchAgent)에 의심스러운 것이 없는지 확인하세요.
                3. 안전을 확인한 후 긴급 창에서 봉쇄를 해제하세요.
                4. 상태는 MCP 도구 `get_runtime_threat_status`로도 확인할 수 있습니다.
                """
            ),
            LocalizedEntry(
                id: "alert_gatekeeper_block",
                title: "🛡️ Gatekeeper가 서명되지 않은 앱의 실행을 차단함",
                summary: "macOS Gatekeeper가 서명이나 공증이 없는 앱의 실행을 차단했다는 알림입니다. 자동 차단은 발생하지 않습니다.",
                details: """
                • 원인: 인터넷에서 받은 서명되지 않은 앱이나 본인의 개발 중인 빌드를 열려고 시도했습니다.
                • 자동 방어: 없음(알림만 발송). XProtect 연동 차단은 XProtect가 실제로 악성코드를 탐지했을 때만 작동합니다.
                """,
                recommendation: """
                1. 본인의 빌드처럼 알아볼 수 있다면 별도 조치는 필요 없습니다.
                2. 알아볼 수 없다면 "파일/앱 안전성 진단…"으로 서명 권한자를 확인하고 의심스럽다면 삭제하세요.
                """
            ),
            LocalizedEntry(
                id: "alert_clickfix_command",
                title: "🚨 의심스러운 명령어 실행 감지 / ⚠️ 클립보드에서 의심스러운 명령어 감지",
                summary: "ClickFix 수법과 일치하는 명령어가 터미널에서 실행되었거나(셸 기록에서 탐지) 클립보드에 복사되었을 때 표시됩니다.",
                details: """
                • 원인: 가짜 캡차나 "이 명령어를 실행하면 해결됩니다"라는 가짜 오류 페이지에 유도되었습니다. 리버스 셸 한 줄 명령어와 Base64로 디코딩된 내용을 셸이나 osascript에 파이프로 넘기는 경우가 표시됩니다.
                • 자동 방어(터미널에서 실행 시, Pro, 기본값 꺼짐): 에어갭 봉쇄(Wi-Fi 무선은 끄지 않음), 최대 10분 후 자동 복구됩니다.
                • 자동 방어(복사 시, 기본값 켜짐): 클립보드가 즉시 비워집니다.
                """,
                recommendation: """
                1. 단순히 복사만 했다면 해당 웹 페이지를 닫고 아무것도 붙여넣거나 실행하지 마세요.
                2. 이미 실행했다면 Keychain, 브라우저에 저장된 비밀번호, 암호화폐 지갑이 안전한지 확인하고, 다른 신뢰할 수 있는 기기에서 중요한 비밀번호를 변경하세요.
                3. 자동 실행 등록(LaunchAgent / Daemon)에 의심스러운 것이 없는지 확인하고 ClamAV 검사를 실행하세요.
                """
            ),
            LocalizedEntry(
                id: "alert_new_persistence_item",
                title: "🚨 새로운 자동 실행 등록 감지됨",
                summary: "새로운 LaunchAgent / LaunchDaemon이 등록되어 의심스럽다고 판단되었을 때 표시됩니다(스크립트 인터프리터를 직접 실행하거나 서명이 유효하지 않은 경우 등).",
                details: """
                • 원인: 정보 탈취형 악성코드 등이 재부팅 후에도 살아남기 위해 스스로 등록했거나, 앱 설치 프로그램이 추가한 것입니다.
                • 자동 방어: 알림만 발송됩니다(등록 자체를 막을 수는 없음). 알림에는 plist 경로와 사유가 표시됩니다.
                """,
                recommendation: """
                1. 방금 앱을 직접 설치했는지 확인하세요. 그렇다면 별도 조치는 필요 없습니다.
                2. 그렇지 않다면 알림에 표시된 plist와 그것이 실행하는 스크립트나 앱을 삭제하세요.
                3. 이후 Mac을 재시작하고 ClamAV 검사를 실행하세요.
                """
            ),
            LocalizedEntry(
                id: "alert_docker_risk",
                title: "⚠️ 위험한 Docker 컨테이너 설정 감지됨",
                summary: "`--privileged`로 시작되었거나 `docker.sock`이 마운트된 컨테이너가 방금 시작되었음을 알립니다.",
                details: """
                • 원인: 특권 컨테이너와 Docker 소켓 마운트는 컨테이너가 호스트를 제어할 수 있게 하여 컨테이너 탈출 위험을 만듭니다.
                • 자동 방어: 없음(알림만 발송).
                """,
                recommendation: """
                1. 의도한 것(예: 모니터링 에이전트)이라면 별도 조치는 필요 없습니다.
                2. 그렇지 않다면 `docker ps`와 `docker inspect`로 해당 컨테이너를 확인하고 중지하세요.
                """
            ),
            LocalizedEntry(
                id: "alert_critical_file_tampering",
                title: "🚨 중요 시스템 파일 변조 감지됨",
                summary: "sudoers, SSH 설정, PAM, hosts, root의 authorized_keys 같은 중요 파일에서 변경, 삭제, 신규 파일이 감지되었을 때 표시됩니다.",
                details: """
                • 원인: 관리자의 설정 변경(`sudo visudo`, SSH 설정 편집), 소프트웨어에 의한 변경, 또는 공격자의 권한 상승이나 백도어 설치입니다.
                • 자동 방어: 알림만 발송됩니다. 새로운 상태가 자동으로 정당한 것으로 인정되는 일은 없습니다.
                • 관련 메시지: "중요 시스템 파일 변조 감지가 작동하지 않습니다"는 특권 헬퍼에 접속할 수 없어 검사가 반복해서 실패하고 있다는 뜻입니다.
                """,
                recommendation: """
                1. 알림에 표시된 파일을 본인이나 관리자가 변경했는지 확인하세요.
                2. 그렇지 않다면 `/etc/sudoers`에 `NOPASSWD` 항목이 있는지, `authorized_keys`에 낯선 키가 있는지 등을 확인하고 제거하세요.
                3. 관리자 비밀번호를 변경하고 보안 진단을 실행하세요.
                """
            ),
            LocalizedEntry(
                id: "alert_log_audit_anomaly",
                title: "🔔 로그 감사: 이상 패턴 감지됨",
                summary: "이 Mac에서 한 번도 본 적 없는 로그 패턴([신규])이나 평소보다 훨씬 잦은 로그([급증 z=…])를 자동 로그 감사가 발견했을 때 발송되는 알림입니다.",
                details: """
                • 원인: 대개 새 기기 연결이나 앱・macOS 업데이트에 따른 예상된 변화이지만, 때로는 의심스러운 로그인 시도나 알 수 없는 프로세스 활동일 수도 있습니다.
                • 내용: 건수 세부 내역, 최대 3개의 실제 로그 줄, 학습 진행 상황(예: 빈도 학습 중: 지금까지 2/3회 관측), 쉬운 언어 설명.
                • 자동 방어: 없음(알림만 발송).
                """,
                recommendation: """
                1. 신규 패턴만 있고 낯선 앱 이름이나 IP 주소가 없다면 별도 조치는 필요 없습니다.
                2. 빈도 급증이 본인이 하지 않은 일과 시간이 겹친다면 "📜 Mac 보안 로그 감사…"를 열어 자세히 확인하세요.
                3. 확신이 없다면 "AI 상담용 자료 복사"를 사용해 AI 도우미에게 물어보세요.
                """
            ),
            LocalizedEntry(
                id: "alert_secret_in_clipboard",
                title: "🔑 클립보드에서 기밀 키 감지됨",
                summary: "OpenAI, Anthropic, GitHub, AWS 등의 API 키나 개인 키가 클립보드에 있다고 알려줍니다.",
                details: """
                • 원인: API 키, 토큰, 개인 키를 복사했습니다.
                • 자동 방어: 알림만 발송됩니다(클립보드는 비워지지 않음).
                """,
                recommendation: """
                1. 실수로 웹사이트나 AI 채팅에 붙여넣지 않도록 주의하세요.
                2. 다 사용했다면 다른 텍스트를 복사해 덮어쓰세요.
                3. 실수로 공유했다면 즉시 해당 서비스의 콘솔에서 키를 폐기하고 재발급하세요.
                """
            ),
            LocalizedEntry(
                id: "alert_airgap_failed",
                title: "🚨 자동 네트워크 차단 실패",
                summary: "긴급 차단(랜섬웨어, ARP 스푸핑, XProtect 탐지, ClickFix 등)을 시도했지만 pf 전체 차단을 적용하지 못했을 때 표시되는 긴급 경고입니다.",
                details: """
                • 원인: 특권 헬퍼가 응답하지 않았습니다(승인되지 않음, 정지됨, 또는 시간 초과). 3회 재시도에 실패한 후 표시됩니다.
                • 현재 상태: 수신 트래픽은 응용 프로그램 방화벽에 의해 차단되었을 수 있지만, 송신 트래픽은 아직 차단되지 않았습니다.
                """,
                recommendation: """
                1. 즉시 Wi-Fi를 끄거나 네트워크 케이블을 뽑으세요.
                2. 위협에 대응하세요(프로세스 종료, 검사 실행).
                3. 그런 다음 헬퍼의 상태를 확인하세요(faq_helper_troubleshooting).
                """
            ),
        ]
    }

    // MARK: - Settings

    private static func settingsKo() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "set_trusted_networks",
                title: "등록된 네트워크와 네트워크별 보호 수준",
                summary: "현재 네트워크를 집, 회사, 테더링 등으로 등록하고 각 네트워크의 보호 수준(신뢰함 / 표준 보호 / 최대 잠금)을 설정합니다.",
                details: """
                • 등록: 현재 네트워크를 등록 → 집으로 등록(신뢰함) / '직장'으로 등록(표준 보호) / '테더링'으로 등록(표준 보호) / 사용자 지정 이름으로 등록…. 네트워크는 게이트웨이의 MAC 주소로 식별됩니다.
                • 등급 변경: "현재 네트워크: …" 또는 "등록된 네트워크 (n)" 아래에서 해당 네트워크를 선택하고 🟢 / 🟡 / 🔴 중 선택하세요.
                • 이름 변경 또는 제거: 이름 변경…, 등록 해제, 또는 등록 삭제.
                """,
                recommendation: "집은 🟢 신뢰함, 회사나 테더링은 🟡 표준 보호로 설정하면 좋습니다. 공용 사무실 Wi-Fi는 등록하지 않고 최대 잠금 상태로 두는 것이 더 안전합니다."
            ),
            LocalizedEntry(
                id: "set_away_default_level",
                title: "외부 기본 보호 (등록되지 않은 네트워크의 등급)",
                summary: "등록하지 않은 네트워크에 연결했을 때 자동으로 적용되는 보호 수준을 선택합니다. 초기값은 🔴 최대 잠금입니다.",
                details: """
                • 설정 방법: 메뉴의 "외부 기본 보호: …"에서 🟢 신뢰함 / 🟡 표준 보호 / 🔴 최대 잠금을 선택합니다.
                • 신뢰할 수 없는 네트워크에 있는 것을 조건으로 하는 기능(DNS 위협 보호(외부 전용), VPN 자동 연결, 게이트웨이 ARP/NDP 고정, Bluetooth 자동 끄기 등)에도 영향을 줍니다.
                """,
                recommendation: "외출 중 공유 서비스나 AirDrop을 사용하지 않는다면 최대 잠금으로 두는 것을 강력히 권장합니다."
            ),
            LocalizedEntry(
                id: "set_manual_override",
                title: "수동 오버라이드 & 원복 잊음 방지",
                summary: "선택한 기간 동안 일시적으로 보호 수준을 수동으로 설정합니다. 시간이 지나거나 네트워크가 바뀌면 자동 감지로 되돌아가므로 보호를 원래대로 되돌리는 것을 잊지 않습니다.",
                details: """
                • 설정 방법: 수동 오버라이드 → 등급(🟢 / 🟡 / 🔴) → 기간.
                • 기간: 다음 네트워크 연결 해제 시까지(권장), 1시간 동안, 4시간 동안, 해제할 때까지 유지.
                • 해제 방법: 수동 오버라이드 → 자동 감지로 돌아가기, 또는 메뉴 상단의 "🔄 수동 지정 해제(자동 감지 복원)".
                • 에어갭 봉쇄를 해제하면 수동 오버라이드도 함께 지워집니다.
                """,
                recommendation: "발표나 개발 작업 때문에 일시적으로 보호를 완화할 때는 다음 네트워크 연결 해제 시까지나 1시간 동안을 사용해 외출 중 보호 없는 상태로 남지 않도록 하세요."
            ),
            LocalizedEntry(
                id: "set_pro_default_guards",
                title: "Pro 활성화 시 자동으로 켜지는 가드와 선택적으로 켜는 가드",
                summary: "Pro 라이선스를 처음 활성화하면 주요 자율 방어 가드가 자동으로 켜집니다. 이후에는 각 가드에 대해 사용자가 내린 켜기/끄기 선택이 존중됩니다.",
                details: """
                • 자동으로 켜짐(Pro를 처음 활성화할 때 한 번): 알 수 없는 리스닝 포트 자동 차단, 랜섬웨어 미끼 파일 탐지, ARP 스푸핑 감지 시 자동 차단, XProtect 악성코드 탐지 시 자동 차단, 자동 로그 감사, 중요 시스템 파일 변조 정기 감시. ARP와 XProtect 차단이 켜질 때는 이를 설명하는 일회성 안내가 표시됩니다.
                • Pro에서 기본값 켜짐: 웹 및 이메일 보호, 자동 실행 등록(LaunchAgent/Daemon) 감시.
                • 기본값 꺼짐(선택적 사용): ClickFix 자동 차단, Docker 위험 탐지, BadUSB 물리 포트 가드, USB 저장장치 자동 차단, 게이트웨이 ARP/NDP 고정, VPN 터널, Bluetooth 자동 끄기, 실증형 취약점 검증. DNS 위협 보호의 제공업체는 사용자가 선택합니다.
                • 무료 버전에서도 기본값 켜짐: 클립보드 보호(API 키와 ClickFix 명령어).
                • 이후 버전에 추가되는 가드는 기존 Pro 사용자에게도 각각 한 번의 기본값이 적용됩니다. 라이선스가 만료되면 Pro 전용 가드는 꺼집니다.
                """,
                recommendation: "Pro를 활성화한 후 메뉴의 ✅ 표시를 확인하세요. 사용 목적에 맞지 않는 가드(예: Docker를 사용하지 않는다면)는 꺼둔 채로 두고, 필요한 것(예: 공용 Wi-Fi를 자주 사용한다면 VPN)은 켜세요."
            ),
            LocalizedEntry(
                id: "set_usb_whitelist",
                title: "USB / BadUSB 가드 설정 (키보드 허용 목록 & 저장장치 권한) (Pro)",
                summary: "신뢰하는 키보드와 업무용 USB 저장장치를 허용 목록으로 관리하고, 저장장치 권한을 읽기 전용이나 읽기・쓰기로 설정합니다.",
                details: """
                • 열기: 포트・기기 모니터링 → "USB / BadUSB 가드 설정…".
                • 키보드: 승인 창에서 "신뢰하고 허용"을 선택하면 추가됩니다. 여기서 제거할 수 있습니다.
                • 저장장치: 연결 대화상자에서 "읽기・쓰기 허용" 또는 "읽기 전용으로 허용"을 선택하면 추가됩니다. 여기서 권한을 바꾸거나 제거할 수 있습니다. 연결되어 있지 않은 기기를 변경했다면 뽑았다 다시 꽂아야 적용됩니다.
                • 허용된 기기라도 연결 시 ClamAV 검사는 읽기・쓰기로 연결되기 전에 계속 실행됩니다.
                """,
                recommendation: "민감한 데이터를 다루는 Mac에서는 저장장치를 읽기 전용 권한으로 등록하면 데이터 유출 위험을 크게 줄일 수 있습니다."
            ),
            LocalizedEntry(
                id: "set_watched_folders",
                title: "웹 및 이메일 보호의 감시 대상 폴더 (Pro)",
                summary: "다운로드 보호(FSEvents 감시와 자동 검사)가 감시하는 폴더를 추가, 제거, 초기화합니다.",
                details: """
                • 기본 폴더: `~/Downloads`, `~/Desktop`, `~/Documents`, Mail의 다운로드 폴더.
                • 편집: "웹 및 이메일 보호(다운로드 자동 검사) (Pro)" → "📁 감시 대상 폴더" → "⚙️ 감시 대상 폴더 편집…".
                • 초기화: "🔄 기본값으로 복원".
                • 최근 검사 기록(최대 5개 표시)과 "검사 기록 지우기"도 같은 메뉴에 있습니다.
                """,
                recommendation: "브라우저나 채팅 앱의 파일 저장 위치를 바꿨다면 반드시 해당 폴더를 감시 목록에 추가하세요."
            ),
            LocalizedEntry(
                id: "set_dns_policy",
                title: "DNS 위협 보호의 제공업체와 정책 (Pro)",
                summary: "악성 도메인을 차단하는 보안 DNS 제공업체와 적용 시점(외부 전용 / 항상)을 선택합니다.",
                details: """
                • 설정 방법: "DNS 위협 보호(악성 사이트 및 C2 차단) (Pro)" → "제공자: …"와 "⚙️ 적용 정책".
                • 제공업체: Quad9(악성코드 및 C2 자동 차단) / Cloudflare Security(1.1.1.2) / AdGuard DNS(위협 및 광고 차단) / CleanBrowsing(보안 필터).
                • 정책: "외부·미신뢰 Wi-Fi에서만 적용(권장)" 또는 "모든 네트워크에서 항상 적용(신뢰 환경 포함)". 외부 전용을 선택하면 신뢰하는 네트워크에서는 원래 DNS 설정으로 복원됩니다.
                • 메뉴의 상태 항목을 누르면 네트워크 설정을 열어 적용된 내용을 확인할 수 있습니다.
                """,
                recommendation: "대부분의 경우 Quad9와 외부 전용 정책의 조합이 좋은 선택입니다. 회사 내부 DNS가 필요한 환경에서는 항상 적용 정책을 피하세요."
            ),
            LocalizedEntry(
                id: "set_link_guard_modes",
                title: "링크 보호의 모드, 자동 업데이트, 시스템 확장, 허용 목록 (Pro)",
                summary: "링크 보호의 모드, 위협 정보 자동 업데이트, 시스템 확장 승인 상태, 실수로 차단된 사이트를 허용하는 방법을 설정합니다.",
                details: """
                • 모드: "링크 보호(피싱 접속 감지) (Pro)" → "끔", "경고만(차단 안 함)", 또는 "명백한 피싱 사이트는 자동 차단(권장)". 경고 모드는 시스템 확장이 활성화되어 있을 때만 작동합니다.
                • 자동 업데이트: "자동 업데이트: 켬(수신 전용)"을 클릭하면 끌 수 있습니다. 꺼도 내장 데이터와 동형 문자 탐지로 계속 동작합니다. 메뉴에 정보 버전과 도메인 수가 표시됩니다.
                • 적용 지점: "적용 지점: 시스템 확장(DoH 대응)", "적용 지점: hosts 폴백", "시스템 확장 활성화 중…", 또는 시스템 확장 오류. 승인 대기 중일 때는 "시스템 확장 승인(시스템 설정 열기)…"이 표시됩니다.
                • 허용/차단: 차단 알림의 "이번만 허용(5분)"으로 해당 사이트를 5분간 허용할 수 있습니다. 경고 패널에서 선택한 허용/차단은 기억됩니다.
                """,
                recommendation: "시스템 확장을 승인하고 자동 업데이트를 켠 상태로 자동 차단을 사용하는 것이 가장 효과적인 보호입니다."
            ),
            LocalizedEntry(
                id: "set_vpn_backend",
                title: "VPN 터널 백엔드 설정 (WireGuard / Tailscale) (Pro)",
                summary: "VPN 터널의 백엔드를 선택하고, WireGuard 설정을 가져오고, Tailscale exit node를 선택하며, 킬 스위치를 설정합니다.",
                details: """
                • 열기: 포트・기기 모니터링 → "VPN 터널(미신뢰 네트워크의 MITM 대응) (Pro)" → 백엔드.
                • WireGuard: "WireGuard 설정(.conf) 가져오기…" → "미신뢰 네트워크에서 자동 연결". "지금 연결", "연결 끊기", "설정 삭제"도 있습니다. 상태는 예를 들어 "🟢 연결됨(마지막 핸드셰이크 N초 전)"처럼 표시되며 킬 스위치는 항상 켜져 있습니다. `wireguard-tools`가 없으면 설치 안내가 표시됩니다.
                • Tailscale: "Exit Node"에서 노드를 선택합니다("(없음 — 보호 꺼짐)"으로 비활성화). "후보 새로고침"과 "상태 새로고침"도 있습니다. "킬 스위치: 켬(누출 방지)"은 선택 사항이며 기본값은 꺼짐입니다.
                • 상태 표시 예: "⚪️ 대기 중(신뢰할 수 없는 네트워크에서 자동 연결)", "🟡 선택한 exit node가 오프라인".
                """,
                recommendation: "이미 Tailscale을 사용 중이라면 Tailscale을 선택하고, 그렇지 않다면 VPN 제공업체의 WireGuard 설정 파일을 사용하는 것이 가장 쉽습니다."
            ),
            LocalizedEntry(
                id: "set_language",
                title: "표시 언어 (앱과 MCP 응답)",
                summary: "RoamSwitch는 10개 언어(日本語, English, 简体中文, 繁體中文, 한국어, Deutsch, Français, Español, Italiano, Português)로 표시할 수 있습니다. MCP 서버 응답과 이 지식 베이스도 같은 언어를 사용합니다.",
                details: """
                • 설정 방법: 메뉴의 "언어 / Language"에서 선택합니다. "시스템 설정 따르기"는 macOS의 선호 언어를 사용합니다.
                • MCP: MCP 서버는 앱에서 선택된 언어를 읽습니다. 시스템 설정을 따르는데 시스템 언어가 지원되지 않으면 영어로 응답합니다.
                • `get_app_help` 도구는 호출마다 응답 언어를 지정할 수 있는 `language` 인자를 받습니다. 검색은 어떤 언어의 키워드와도 일치할 수 있습니다.
                """,
                recommendation: "앱과 다른 언어로 AI 도우미와 대화하고 싶다면 `get_app_help`의 `language` 인자를 사용하세요."
            ),
        ]
    }

    // MARK: - Troubleshooting: setup

    private static func troubleshootingKoSetup() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "faq_free_vs_pro",
                title: "무료 버전과 Pro 평생 버전의 차이",
                summary: "무료 버전에는 네트워크 기반 자동 보호 전환, 18개 항목 보안 진단, 다양한 수동 검사 도구가 시간 제한 없이 포함되어 있습니다. Pro는 자동 봉쇄, 실시간 방어, 순찰 경고를 추가로 제공합니다.",
                details: """
                【무료 버전】
                • 네트워크별 3단계 PF 패킷 필터 자동 전환, 공유 서비스와 AirDrop 자동 정지 및 복원
                • Mac 보안 진단(18개 항목), XProtect 상태, 파일/앱 안전성 진단
                • 노출된 포트와 USB 기기 목록
                • 링크 안전성 진단, 수동 기밀/API 키 유출 감사, 클립보드 보호
                • 패키지 CVE 검사, 실증형 취약점 검증, Mac 보안 로그 감사, 알림 기록
                • 수동 ClamAV 검사와 격리 관리
                • MCP 서버 연동
                【Pro 평생 버전(일회성 ¥2,980 / $19.99, 최대 2대의 Mac)】
                • 에어갭을 동반한 랜섬웨어 미끼 파일 탐지, XProtect 연동 자동 차단, ClickFix 대책
                • 알 수 없는 리스닝 포트 자동 차단, 개발 서버 격리
                • ARP 스푸핑 자동 차단, 게이트웨이 ARP/NDP 고정, VPN 터널(WireGuard / Tailscale), 이블 트윈 경고
                • BadUSB 키보드 가드, USB 저장장치 자동 차단
                • 웹 및 이메일 보호(자동 검사, 격리, Pickle 경고), DNS 위협 보호, 링크 보호
                • 자동 실행 등록 감시, Docker 위험 탐지, 중요 파일 변조 감시, 자동 로그 감사
                • Bluetooth 자동 끄기, 실시간 위협 알림, 순찰 경고, 정의 업데이트와 예약 검사, 로그 CSV 내보내기
                """,
                recommendation: "자동 봉쇄, 실시간 방어, 백그라운드 모니터링이 필요하다면 Pro 버전을 선택하세요."
            ),
            LocalizedEntry(
                id: "faq_homebrew_clamav",
                title: "ClamAV(바이러스 검사)와 Homebrew 설정하기",
                summary: "바이러스 검사는 오픈소스 ClamAV를 사용하며 Homebrew로 설치할 수 있습니다. 설치하지 않아도 XProtect 연동과 RoamSwitch 자체 기능은 모두 정상 작동합니다.",
                details: """
                • Homebrew: macOS용 패키지 관리 도구(https://brew.sh/).
                • 단계:
                  1. 터미널에서 Homebrew의 공식 설치 명령을 실행하세요(https://brew.sh/에 안내되어 있습니다).
                  2. `brew install clamav`를 실행하세요. 메뉴의 "📥 Homebrew로 ClamAV 설치…"에서도 안내를 열 수 있습니다.
                  3. "🛡️ ClamAV(무료 백신)" → "🔄 바이러스 정의 지금 업데이트"를 선택하세요.
                • ClamAV로 활성화되는 기능: 빠른 검사(다운로드/데스크탑), 폴더 검사, 웹 및 이메일 보호와 USB 저장장치의 검사, 순찰의 예약 검사.
                • ClamAV 없이도: 패킷 필터링, 포트 모니터링, 링크 분석, 정적 시그니처 검사 등은 계속 작동합니다.
                """,
                recommendation: "다운로드 파일과 USB 저장장치를 자동으로 검사하고 싶다면 Homebrew와 ClamAV를 설치하세요."
            ),
            LocalizedEntry(
                id: "faq_blueutil_setup",
                title: "Bluetooth 자동 끄기 (Pro)와 blueutil 설정",
                summary: "외출 중 Bluetooth를 자동으로 끄는 기능에는 오픈소스 도구 `blueutil`이 필요합니다.",
                details: """
                • 배경: macOS에는 앱에서 Bluetooth 전원을 전환할 수 있는 공개 API가 없어 CLI 도구 `blueutil`을 사용합니다.
                • 단계:
                  1. 터미널에서 `brew install blueutil`을 실행하세요(또는 메뉴의 "📥 Homebrew로 blueutil 설치…" 사용).
                  2. 포트・기기 모니터링 → "미신뢰 네트워크에서 Bluetooth 자동 끄기 (Pro)"를 활성화하세요.
                • 설치되어 있지 않다면: 다른 기능에는 영향이 없으며, 메뉴에 "🔵 Bluetooth 자동 끄기(미설치)"가 표시됩니다.
                """,
                recommendation: "공용 Wi-Fi에서의 전파 추적과 Bluetooth 취약점을 피하려면 `brew install blueutil`을 실행하고 활성화하세요."
            ),
            LocalizedEntry(
                id: "faq_helper_troubleshooting",
                title: "\u{201C}⚠️ 헬퍼가 연결되지 않음\u{201D}이 표시될 때 대처법",
                summary: "RoamSwitch가 특권 헬퍼 도구(RoamSwitchHelper)와 통신할 수 없을 때의 복구 단계입니다.",
                details: """
                1. 메뉴에서 "⚠️ 헬퍼 승인…"을 선택하고 표시되는 단계를 따르세요.
                2. 시스템 설정 → 일반 → 로그인 항목 및 확장 프로그램을 열어 "백그라운드에서 실행 허용"에 RoamSwitchHelper가 켜져 있는지 확인하세요.
                3. RoamSwitch가 응용 프로그램 폴더에 있는지 확인하세요(faq_install_location).
                4. 온보딩 창에서 "헬퍼 등록 다시 시도"를 누르세요.
                5. 그래도 실패하면 터미널에서 `sudo killall RoamSwitchHelper`를 실행해 헬퍼를 다시 시작하고(launchd가 자동으로 재시작합니다), RoamSwitch를 다시 실행하세요.
                """,
                recommendation: "macOS 업데이트 직후 헬퍼가 응답하지 않는다면 먼저 로그인 항목 스위치를 확인하고, 그다음 `sudo killall RoamSwitchHelper`를 시도하세요."
            ),
            LocalizedEntry(
                id: "faq_install_location",
                title: "앱 위치 (응용 프로그램 폴더 밖에서 실행됨)",
                summary: "macOS는 응용 프로그램 폴더 밖에 있는 앱의 특권 헬퍼를 등록하지 않으므로, RoamSwitch는 `/Applications`나 `~/Applications`에 두고 그곳에서 실행해야 합니다.",
                details: """
                • 등록할 수 없는 위치: 다운로드나 데스크탑, 여전히 마운트된 디스크 이미지(.dmg)에서 실행, 또는 Gatekeeper App Translocation이 앱을 임시 읽기 전용 위치로 옮긴 경우입니다.
                • 안내: 온보딩 과정에서 실행 시 위치를 확인하고 "응용 프로그램으로 옮기고 다시 실행" 또는 "Finder에서 응용 프로그램 열기"를 제안합니다.
                • 이동 후: "다시 확인"을 누르거나 다시 실행한 뒤 헬퍼를 승인하세요.
                """,
                recommendation: "RoamSwitch를 디스크 이미지에서 응용 프로그램 폴더로 끌어다 놓고 그곳에서 실행하세요."
            ),
            LocalizedEntry(
                id: "faq_system_extension_approval",
                title: "링크 보호의 시스템 확장 승인하기",
                summary: "링크 보호가 최상으로 동작하려면(DoH 대응, 경고 모드) 콘텐츠 필터 시스템 확장을 승인해야 합니다. 승인 전까지는 /etc/hosts 대체 방식을 사용합니다.",
                details: """
                • 단계: "링크 보호(피싱 접속 감지) (Pro)" → "시스템 확장 승인(시스템 설정 열기)…" → 시스템 설정 → 일반 → 로그인 항목 및 확장 프로그램에서 RoamSwitch의 네트워크 확장을 허용하세요.
                • 승인 후: 메뉴에 "적용 지점: 시스템 확장(DoH 대응)"이 표시됩니다.
                • 시스템 확장 오류가 표시되면: 앱이 응용 프로그램 폴더에 있는지 확인한 후 링크 보호 모드를 다시 선택해 재시도하세요.
                • 이 방식은 App Store 심사나 별도 권한 신청이 필요 없습니다(Developer ID로 서명 및 공증됨).
                """,
                recommendation: "브라우저가 DNS over HTTPS를 사용해도 보호가 유지되도록 시스템 확장을 승인하세요."
            ),
            LocalizedEntry(
                id: "faq_mcp_setup",
                title: "MCP 서버 설정하기 (Claude Desktop, Claude Code 등)",
                summary: "RoamSwitch에 내장된 MCP 서버를 MCP를 지원하는 AI 클라이언트에 등록하는 방법입니다.",
                details: """
                • 실행 파일 경로: `/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`
                • Claude Desktop: `~/Library/Application Support/Claude/claude_desktop_config.json`의 `mcpServers`에 실행 파일 경로를 `command`로 추가하세요.
                • Claude Code: `claude mcp add roamswitch /Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`
                • 다른 클라이언트(Codex CLI 등)의 설정 방법: https://lafine.net/mcp-setup.html
                • 응답 언어: 앱의 "언어 / Language" 설정을 따릅니다. `get_app_help`는 호출마다 `language` 인자를 받을 수 있습니다.
                • 통신은 로컬 stdio만 사용하며 외부로는 아무것도 전송되지 않습니다(`run_active_vuln_scan`만 127.0.0.1로 비파괴적 프로브를 전송합니다).
                """,
                recommendation: "등록한 후 AI에게 \u{201C}RoamSwitch로 내 Mac의 보안 상태를 확인해줘\u{201D}처럼 물어보면 진단 결과를 설명해 줍니다."
            ),
        ]
    }

    // MARK: - Troubleshooting: operation

    private static func troubleshootingKoOperation() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "faq_network_cut_off",
                title: "인터넷이 갑자기 끊김 (에어갭 봉쇄 / 보호 수준)",
                summary: "RoamSwitch의 긴급 에어갭이나 최대 잠금이 트래픽을 막고 있을 수 있습니다. 원인을 찾고 해제하는 방법입니다.",
                details: """
                • 확인 방법: 긴급 창이 떠 있는지, 알림 기록에 긴급 자동 방어, XProtect, ARP 스푸핑, 의심스러운 명령어 실행 같은 경고가 있는지 확인하세요. Wi-Fi 무선이 꺼져 있을 수도 있습니다.
                • 해제 방법: 긴급 창이나 알림의 해제 버튼을 사용하세요. 네트워크와 Wi-Fi 무선이 돌아옵니다.
                • 자동 복구: 해제하지 않아도 헬퍼의 안전장치가 10분 안에 네트워크를 복원합니다. 앱 종료, 충돌, 재부팅 후에도 별도의 수동 조작이 필요 없습니다.
                • 부팅 직후: 부팅 게이트로 인해 최대 90초 동안 트래픽이 제한될 수 있습니다.
                • 다른 원인: 최대 잠금은 수신 연결을 차단하지만 웹 서핑 같은 일반적인 송신 사용은 막지 않습니다. VPN 킬 스위치(터널이 끊긴 동안), DNS 위협 보호의 리졸버, 링크 보호의 차단도 확인해 보세요.
                """,
                recommendation: "봉쇄가 발동하면 트리거된 알림을 읽고 안전을 확인한 후 해제하세요. 특정 가드가 자주 오작동한다면 메뉴에서 그 가드만 개별적으로 끌 수 있습니다."
            ),
            LocalizedEntry(
                id: "faq_quarantine_false_positive",
                title: "오탐으로 격리된 다운로드 복원하기",
                summary: "오탐으로 격리된 본인의 스크립트나 개발용 바이너리를 복원하고 검사에서 제외하는 방법입니다.",
                details: """
                1. 악성코드 보호 → ClamAV → "📦 격리 파일 관리…"를 여세요.
                2. 격리된 파일 중에서 해당 파일을 선택하세요(원래 경로, 위협 이름, 격리 시각이 표시됩니다).
                3. 확실한 오탐이라면 "제외하고 복원"을 누르세요. 원래 위치로 돌아가고 해당 경로는 이후 검사에서 제외됩니다. 한 번만 복원하려면 "복원"을 누르세요.
                4. 제외를 취소하려면 같은 창의 제외된 경로 목록에서 "제외 해제"를 누르세요.
                5. 폴더 전체 감시를 중단하려면 웹 및 이메일 보호에서 "⚙️ 감시 대상 폴더 편집…"을 조정하세요.
                """,
                recommendation: "파일이 안전한지 확신할 수 없다면 복원하지 말고 완전히 삭제를 선택하세요."
            ),
            LocalizedEntry(
                id: "faq_eicar_test",
                title: "EICAR 테스트 파일을 두었는데 알림이 오지 않음",
                summary: "의도된 설계입니다. EICAR 테스트 시그니처는 무해한 테스트이므로 배너가 표시되지 않고 격리되지도 않습니다. 탐지는 알림 기록에 기록됩니다.",
                details: """
                • 확인 방법: Mac 보안 진단 → "🔔 알림 기록…"에서 "🧪 EICAR 테스트 시그니처 감지(무해)"를 확인하세요.
                • 파일 상태: 그대로 남아 있습니다.
                • 실제 경고 경로를 테스트하려면: 악성코드 보호 하단의 시뮬레이션(랜섬웨어 방어, 악성코드 탐지 에어갭, Docker 위험 탐지)을 사용하세요.
                """,
                recommendation: "테스트가 끝나면 EICAR 파일을 삭제하세요."
            ),
            LocalizedEntry(
                id: "faq_dev_server_blocked",
                title: "내 개발 서버나 LAN 수신 앱에 다른 기기에서 접근할 수 없음",
                summary: "알 수 없는 리스닝 포트 자동 차단이 방금 포트를 노출하기 시작한 프로그램을 차단하고 있을 수 있습니다. Mac 자체에서는 계속 접근할 수 있습니다.",
                details: """
                • 확인 방법: 알림 기록에서 "🚨 알 수 없는 리스닝 포트를 자동 차단함"을 찾아보세요.
                • 허용 방법: 알림의 "허용" 버튼을 사용하거나 외부 공개 포트 → 해당 포트 → 포트 진단 화면에서 허용하세요. 허용은 실행 파일 단위로 영구적으로 적용됩니다.
                • 수동 격리와의 차이: 본인이 "외부 격리 실행"으로 격리한 포트는 포트 진단 화면의 "격리 해제"로 되돌립니다.
                • 보호 수준: 최대 잠금 네트워크에서는 방화벽이 수신 연결을 완전히 차단합니다. LAN에서의 접근을 허용하려면 해당 네트워크를 등록하고 표준 보호나 신뢰함으로 설정하세요.
                """,
                recommendation: "LocalSend나 Syncthing처럼 자주 사용하는 LAN 수신 앱은 한 번만 허용하면 다시 차단되지 않습니다."
            ),
            LocalizedEntry(
                id: "faq_link_guard_false_block",
                title: "링크 보호가 정당한 사이트를 차단함 / 연결이 계속 보류됨",
                summary: "링크 보호가 실수로 사이트를 차단했거나 경고 모드로 보류했을 때의 대처법입니다.",
                details: """
                • 임시로 허용: 차단 알림의 "이번만 허용(5분)".
                • 영구적으로 허용: 경고 패널에서 "허용"을 선택하면 기억됩니다.
                • 보류된 연결이 스스로 차단됨: 경고 모드는 약 8초 안에 응답이 없으면 차단합니다(실패 시 차단). 이 결과는 캐시되지 않으므로 페이지를 다시 불러오면 다시 물어봅니다.
                • 알림이 보이지 않음: 배너 스타일 알림에서는 버튼이 숨겨질 수 있어 최전면 패널도 함께 표시됩니다. 방해 금지 모드 중이라면 알림 기록을 확인하세요.
                • 임시로 비활성화: 모드를 "경고만(차단 안 함)"이나 "끔"으로 전환하세요.
                """,
                recommendation: "업무 도구가 반복해서 차단된다면 허용하기 전에 도메인에 오타나 유사 문자가 없는지 확인하세요."
            ),
            LocalizedEntry(
                id: "faq_keyboard_blocked",
                title: "외장 키보드가 입력되지 않음 (BadUSB 가드)",
                summary: "BadUSB 물리 포트 가드가 허용 목록에 없는 키보드의 입력을 승인할 때까지 차단하고 있습니다.",
                details: """
                • 승인 방법: "⚠️ 알 수 없는 USB 기기 / 키보드 연결 감지" 창에서 "신뢰하고 허용"을 클릭하세요(내장 키보드나 트랙패드를 사용하세요).
                • 창을 찾을 수 없음: 기기를 뽑았다가 다시 연결하면 다시 표시됩니다.
                • 도킹 스테이션과 KVM 스위치: 내장 키보드 기능이 있는 기기도 대상에 포함됩니다. 본인의 기기라면 허용하세요.
                • 손쉬운 사용 권한: 기기를 점유할 수 없을 때 사용되는 대체 차단 방식은 손쉬운 사용 권한에 의존합니다.
                • 취소: "USB / BadUSB 가드 설정…"에서 제거할 수 있습니다.
                """,
                recommendation: "스크립트 입력 경고가 뜬 기기는 허용하지 말고 뽑으세요."
            ),
            LocalizedEntry(
                id: "faq_vpn_troubleshooting",
                title: "VPN 터널이 연결되지 않음 / 트래픽이 통과하지 않음",
                summary: "WireGuard나 Tailscale 백엔드가 작동하지 않을 때 확인할 사항입니다.",
                details: """
                • WireGuard: `brew install wireguard-tools`가 설치되어 있고 `.conf`가 가져와졌는지 확인하세요. 상태가 "🟡 응답 없음(마지막 핸드셰이크 …)"이라면 VPN 서버와 설정 파일의 키・엔드포인트를 확인하세요. 킬 스위치가 켜져 있어 터널이 수립되기 전까지는 아무것도 통과하지 못합니다.
                • Tailscale: CLI가 설치되어 로그인되어 있는지(그렇지 않으면 메뉴에 "먼저 Tailscale에 로그인하세요"가 표시됩니다) exit node가 선택되었는지 확인하세요. 선택한 exit node가 오프라인이라면 다른 노드를 선택하세요.
                • App Store의 Tailscale: 앱 외부에서 exit node를 설정할 수 없으므로 Tailscale 앱에서 선택하세요.
                • Tailscale 킬 스위치: 일부 네트워크에서는 Tailscale 자체의 연결을 방해할 수 있으므로 연결이 안 된다면 꺼 보세요.
                • 신뢰하는 네트워크에서 자동으로 연결이 끊기는 것은 정상적인 동작입니다.
                """,
                recommendation: "메뉴의 상태 표시부터 확인하세요: WireGuard는 핸드셰이크 상태를, Tailscale은 exit node 상태를 확인하세요."
            ),
            LocalizedEntry(
                id: "faq_log_audit_repeated_alerts",
                title: "로그 감사 알림이 계속 옴",
                summary: "자동 로그 감사는 실행되면서 이 Mac의 평소 로그 동작을 학습합니다. 설정 직후나 큰 업데이트 후에는 알림이 늘어나며, 학습이 진행되면 자연스럽게 줄어듭니다.",
                details: """
                • 신규 패턴: 한 번 보고되면 알려진 것이 되어 같은 내용으로 다시 알리지 않습니다.
                • 빈도 급증: 각 패턴의 학습은 3회 관측 후 완료되며, 그 뒤로는 정상적인 양에는 알리지 않습니다. 알림에 "빈도 학습 중: 지금까지 2/3회 관측"처럼 표시되는 동안은 아직 학습 중입니다.
                • 흔한 원인: macOS나 앱 업데이트, 새 기기 연결, 일시적인 고부하.
                • 멈추는 방법: 메뉴에서 "자동 로그 감사(정기적으로 새 패턴과 빈도 이상을 학습) (Pro)"를 끄세요(수동 로그 감사는 계속 사용할 수 있습니다).
                """,
                recommendation: "알림에 낯선 앱 이름, IP 주소, sudo 실패가 포함되어 있지 않다면 한동안 지켜봐도 괜찮습니다."
            ),
            LocalizedEntry(
                id: "faq_zero_telemetry",
                title: "Zero Telemetry 개인정보 보호 설계",
                summary: "RoamSwitch와 그 MCP 서버는 진단 결과, URL, 포트 정보, 로그, 파일 내용을 외부 서버로 전송하지 않습니다. 유일한 네트워크 트래픽은 아래에 명시된 예외뿐입니다.",
                details: """
                • 완전히 로컬 처리: 보안 진단, 포트 모니터링, 링크 분석, 기밀 정보 감사, 로그 감사, 바이러스 검사, MCP 통신 모두 기기 안에서만 이루어집니다.
                • 예외 사항:
                  - 라이선스 활성화와 비활성화(사용자가 조작할 때만)와 구매 페이지 열기
                  - 앱 업데이트 확인(Sparkle)
                  - ClamAV 정의 업데이트(`freshclam`)
                  - 링크 보호 위협 정보, 패키지 CVE 맵, 취약점 CVE 맵의 일일 다운로드(수신 전용, 서명 검증, 식별자 미전송; 링크 보호 자동 업데이트는 끌 수 있음)
                  - 사용자가 설정한 VPN 및 보안 DNS 제공업체와의 일반 트래픽
                  - 실증형 취약점 검증의 127.0.0.1(이 Mac 자체)로의 비파괴적 프로브
                • 코드 어디에도 사용 현황 수집이나 원격 측정은 존재하지 않습니다. 헬퍼 승인 알림조차 기기 내 카운트만으로 동작합니다.
                """,
                recommendation: "기밀성이 높은 업무 환경이나 개인 개발 환경에서도 데이터 유출 걱정 없이 안심하고 사용할 수 있습니다."
            ),
        ]
    }
}
