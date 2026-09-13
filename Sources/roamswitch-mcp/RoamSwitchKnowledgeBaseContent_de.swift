// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.26 (build 83).
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
                summary: "Die gemeinsame Notfall-Eindämmung, die bei Erkennung einer ernsten Bedrohung (Ransomware, XProtect-Malware-Fund, ARP-Spoofing, ClickFix) genutzt wird. Sie blockiert allen ein- und ausgehenden Datenverkehr. Selbst nach einem Absturz oder Neustart kehrt die Netzwerkverbindung spätestens nach 10 Minuten automatisch zurück.",
                details: """
                • Funktionsweise: Der privilegierte Helfer lädt pf mit „block drop all“ (außer Loopback) und liest es zur Bestätigung zurück. Auch ausgehender Verkehr wird gekappt, was das Abfließen von Schlüsseln oder Daten an einen C2-Server verhindert. Schlägt die Anwendung fehl, wird bis zu dreimal erneut versucht (je 8 Sekunden Timeout); schlägt es weiterhin fehl, wird „Automatische Netzwerktrennung fehlgeschlagen“ angezeigt und um manuelles Trennen gebeten. Es wird nie eine Isolation behauptet, die nicht tatsächlich vorliegt.
                • WLAN-Funk aus: pf verwirft nur Pakete, während der Adapter verbunden bleibt, daher schalten ARP-Spoofing-, Ransomware- und XProtect-Eindämmung über `networksetup` auch den WLAN-Funk selbst aus (standardmäßig an; interne Einstellung `RoamSwitch.AirGapAutoWiFiKillEnabled`). Die ClickFix-Eindämmung schaltet den Funk nicht aus.
                • Aufheben: Das Aufheben über das Notfallfenster oder die Benachrichtigung entfernt die pf-Sperre und schaltet WLAN wieder ein.
                • Sicherheitsnetz: Stürzt die App ab oder hebt niemand die Sperre auf, hebt ein Timer auf Helfer-Seite den Air-Gap nach 10 Minuten zwangsweise auf und stellt den WLAN-Funk wieder her. Ein Neustart der App oder des Mac stellt den Zustand ebenfalls ohne manuelle Schritte wieder her.
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
                • Allgemeine Entwicklungsserver: Prüft auf CORS-Fehlkonfiguration (reflektierter Origin mit Credentials), Path Traversal und offene Weiterleitungen.
                • Abgleich mit bekannten CVEs: Für ohne Authentifizierung erreichbares Redis/Memcached wird die Version mit einer nicht-destruktiven Abfrage gelesen und mit bekannten CVE-Versionsbereichen verglichen. Es werden keine Exploit-Payloads gesendet.
                • Auch als MCP-Tool `run_active_vuln_scan` verfügbar (das einzige Tool, das Netzwerkverkehr sendet, ausschließlich an localhost).
                """,
                recommendation: "Aktivieren Sie diese Funktion nur, wenn Sie prüfen möchten, ob Redis, Docker, ein lokales LLM o. Ä. auf Ihrem eigenen Mac wirklich ohne Authentifizierung erreichbar ist."
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
                • Standardmäßig deaktiviert. Aktivieren Sie unter „Port- & Geräteüberwachung“ → „Physischer Portschutz vor unbefugtem USB / BadUSB (Pro)“; die Positivliste verwalten Sie unter „USB / BadUSB-Schutzeinstellungen…“.
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
                • Warnmodus (schließt bei Ausfall): Die betreffende Verbindung wird angehalten, und es erscheinen eine Erlauben/Blockieren-Benachrichtigung sowie ein Fenster im Vordergrund; die Verbindung wird je nach Ihrer Antwort fortgesetzt oder verworfen. Ohne Antwort innerhalb von etwa 8 Sekunden wird die Verbindung blockiert. Dieses Ergebnis wird nicht zwischengespeichert, sodass beim nächsten Versuch erneut gefragt wird. Tatsächlich getroffene Antworten werden gespeichert. Der Warnmodus erfordert die Systemerweiterung.
                • hosts-Notlösung: Solange die Erweiterung nicht aktiv ist, lässt der Blockiermodus den privilegierten Helfer die Domains als `0.0.0.0` in einem verwalteten Abschnitt von `/etc/hosts` eintragen.
                • Bedrohungsliste: Wird einmal täglich rein empfangend abgerufen, ohne Übertragung von Kennungen, und mit einem eigenen Ed25519-Listenschlüssel überprüft (getrennt vom App-Update-Schlüssel). Wird „Auto-Update“ deaktiviert, entsteht kein ausgehender Datenverkehr mehr; die mitgelieferten Daten und die Homograph-Erkennung funktionieren weiterhin.
                • Ohne Pro: Der Modus wird gespeichert, aber nichts wird blockiert.
                """,
                recommendation: "Behalten Sie die Standardeinstellung „Automatisch blockieren“ bei und genehmigen Sie die Systemerweiterung für den zuverlässigsten Schutz. Wird ein internes Tool versehentlich blockiert, nutzen Sie „Einmal erlauben (5 Min.)“ in der Benachrichtigung oder die Positivliste."
            ),
            LocalizedEntry(
                id: "feat_link_safety_auditor",
                title: "Link-Sicherheitsprüfung (manuell, Zero Telemetry)",
                summary: "Analysiert eine verdächtige URL vor dem Öffnen im Browser vollständig auf dem Gerät und bewertet das Risiko auf einer Skala bis 100 anhand von Unicode-Homographen, Subdomain-Imitation, riskanten TLDs, unverschlüsseltem HTTP, rohen IP-Adressen und mehr. In der kostenlosen Version enthalten.",
                details: """
                • Öffnen: Malware-Schutz → „🔗 Link manuell prüfen…“ oder das MCP-Tool `audit_url_safety`.
                • Homographen: Erkennt ähnlich aussehende Zeichen wie kyrillische oder griechische Buchstaben (Punycode / `xn--`).
                • Subdomain-Imitation: Analysiert Strukturen wie `apple.com.login-verify.xyz`, die den Namen einer bekannten Marke einbetten.
                • Riskante TLDs: Zieht Punkte ab für TLDs, die häufig bei Wegwerf-Phishing genutzt werden, etwa `.xyz`, `.top`, `.tk`, `.icu`.
                • Unverschlüsseltes HTTP und rohe IPs: Warnt vor unverschlüsseltem HTTP auf Anmeldeseiten und nackten IP-Adress-URLs.
                • Vollständig lokal: URLs werden nie an eine externe Analyse-API gesendet, sodass vertrauliche URLs und Tokens nicht durchsickern.
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
                • Beim Aufheben: Netzwerk und WLAN werden wiederhergestellt, der pausierte Prozess fortgesetzt und manipulierte Köderdateien neu erzeugt.
                • Standard: Wird bei erstmaliger Aktivierung von Pro automatisch eingeschaltet. Der Vorfallsverlauf ist über das MCP-Tool `get_canary_status` abrufbar. Testen Sie sicher mit „Ransomware-Abwehr-Simulation (Testmodus)“ im Menü.
                """,
                recommendation: "Lassen Sie diese Funktion aktiviert, um wichtige Daten vor unbekannter Ransomware zu schützen, und löschen Sie die versteckten Köderdateien nicht."
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
                • Warum nachträglich: Sobald eine Zeile im Verlauf steht, wurde der Befehl bereits ausgeführt, doch das sofortige Trennen des Netzwerks kann einen laufenden zweiten Download, eine aktive Reverse-Shell-Verbindung oder eine Zugangsdaten-Exfiltration noch stoppen.
                • Warum Gatekeeper es nicht verhindern kann: Es ist Ihre eigene legitime Shell, die genau das ausführt, was Sie eingegeben haben, sodass am Prozess selbst nichts ungewöhnlich wirkt.
                • Ergänzung: Der Zwischenablage-Schutz (feat_secret_leak_auditor) erkennt den Befehl bereits beim Kopieren und deckt so auch das Einfügen in Skripteditor, Spotlight und andere Stellen außer Terminal ab.
                • Standardmäßig deaktiviert: Eine automatische Netzwerktrennung, ausgelöst durch eine relativ neue Heuristik, daher Opt-in.
                """,
                recommendation: "Erwägen Sie die Aktivierung, wenn Sie befürchten, durch gefälschte Fehlerseiten oder Captchas zur Ausführung von Befehlen verleitet zu werden."
            ),
            LocalizedEntry(
                id: "feat_persistence_monitor_guard",
                title: "Überwachung neuer Autostart-Registrierungen (LaunchAgent / LaunchDaemon) (Pro)",
                summary: "Überwacht neue LaunchAgent-/LaunchDaemon-Registrierungen in Echtzeit und benachrichtigt Sie, wenn eine davon direkt eine Shell oder einen Skript-Interpreter startet oder eine ausführbare Datei mit ungültiger Signatur registriert.",
                details: """
                • Überwacht: `~/Library/LaunchAgents`, `/Library/LaunchAgents` und `/Library/LaunchDaemons` per FSEvents (etwa 1,5 Sekunden Entprellung).
                • Beurteilung: Aktuelle Infostealer erreichen Persistenz, indem sie gültig Apple-signierte `/bin/bash` oder `/usr/bin/osascript` ein Base64-verstecktes Skript ausführen lassen. Da die Signatur des Interpreters selbst gültig ist, wird jede Registrierung, die einen bloßen Interpreter startet, unabhängig von der Signatur als verdächtig eingestuft, und die Skriptargumente werden zusätzlich durch die statische Signaturprüfung geleitet. Unsignierte oder ungültig signierte ausführbare Dateien werden ebenfalls gemeldet. Homebrew-Services-Wrapper sind ausgenommen.
                • Nur Erkennung: Ohne EndpointSecurity-Berechtigung kann das Schreiben der plist nicht verhindert werden. Sie wird innerhalb von etwa 1,5 Sekunden nach dem Schreiben bewertet und gemeldet.
                • Standard: Bei Pro standardmäßig aktiv. Umschaltbar unter Malware-Schutz → „Neue Autostart-Registrierungen überwachen (LaunchAgent/Daemon) (Pro)“.
                """,
                recommendation: "Erhalten Sie eine Warnung zu einer unbekannten Registrierung, prüfen Sie die in der Benachrichtigung gezeigte plist und löschen Sie sie, wenn Sie sie nicht kennen. Direkt nach der Installation einer legitimen App ist es meist unbedenklich."
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
                """,
                recommendation: "Nutzen Sie Docker für die Entwicklung, aktivieren Sie diese Funktion, um Risiken eines Container-Ausbruchs früh zu erkennen."
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
                • Dateien: `/etc/sudoers`, `/etc/pam.d/sudo`, `/etc/ssh/sshd_config`, alles unter `/etc/ssh/sshd_config.d/`, `/etc/hosts` sowie `~/.ssh/authorized_keys` von root. Diese sind nur für root lesbar, daher berechnet der privilegierte Helfer die Prüfsummen.
                • Zeitpunkt: FSEvents auf `/etc`, `/etc/pam.d` und `/etc/ssh` lösen eine nahezu sofortige erneute Prüfung aus, mit einer stündlichen Prüfung als Rückfallebene.
                • Basislinie: Wird beim ersten Scan erfasst. Eine erkannte Änderung wird nie automatisch als neue Basislinie übernommen, sodass der Befund bestehen bleibt, bis ihn ein Mensch überprüft. Derselbe Zustand wird nicht erneut gemeldet, solange die App läuft; jede weitere Änderung löst erneut einen Alarm aus.
                • Warnung bei blinder Stelle: Kann der Helfer dreimal in Folge nicht erreicht werden, erhalten Sie den Hinweis, dass die Manipulationserkennung nicht funktioniert.
                • Hinweis: Während der Link-Schutz im hosts-Notlösungsmodus läuft, schreibt RoamSwitch selbst möglicherweise seinen verwalteten Abschnitt von `/etc/hosts` neu. LaunchAgents / Daemons werden von feat_persistence_monitor_guard abgedeckt.
                • Standard: Wird bei erstmaliger Aktivierung von Pro automatisch eingeschaltet. Menü: Malware-Schutz → „Wichtige Systemdateien regelmäßig auf Manipulation überwachen (Pro)“.
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
                • Benachrichtigung: Anzahl der Anomalien (aufgeteilt in neue Muster und Spitzen), bis zu 3 echte Protokollzeilen, ein Hinweis zum Lernfortschritt sowie eine Erklärung für Laien. Ein neues Muster gilt nach der Meldung als „bekannt“ und wird für denselben Inhalt nie erneut gemeldet; eine Spitze wird nicht mehr gemeldet, sobald die eigene Basislinie dieses Musters gelernt wurde.
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
                """,
                recommendation: "Prüfen Sie nach einer automatischen Trennung diese Zeitleiste zusammen mit dem Benachrichtigungsverlauf, um die Ursache zu finden und eine Wiederholung zu verhindern."
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
                • Erkannte Schlüssel: API-Schlüssel und Tokens von OpenAI, Anthropic, GitHub, AWS, Hugging Face, Google AI / Gemini, Slack und Stripe sowie private RSA-/SSH-Schlüssel.
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
                • Datenzustellung: Die CVE-Karten werden einmal täglich aus einem signierten Manifest rein empfangend abgerufen. Vor dem Abruf werden sie als noch nicht heruntergeladen angezeigt und erkennen nichts.
                • MCP-Tools: `run_package_cve_scan` (Homebrew) und `run_package_cve_scan_languages` (Abhängigkeiten, Argument `watchedFolders`).
                """,
                recommendation: "Führen Sie den Homebrew-Scan regelmäßig aus, registrieren Sie aktive Projekte im Tab „Abhängigkeiten“ und aktualisieren Sie Pakete mit schwerwiegenden CVEs umgehend."
            ),
            LocalizedEntry(
                id: "feat_security_health_checker",
                title: "Mac-Sicherheitsprüfung (18 Punkte, Punktzahl & Korrekturschritte)",
                summary: "Prüft 18 Punkte in sechs Bereichen (Systemhärtung, Netzwerkverteidigung, Authentifizierung und Zugriffskontrolle, Portexposition, Malware-Schutz sowie physischer Geräteschutz) und zeigt eine Punktzahl von 0 bis 100, eine Note sowie Korrekturschritte für jeden nicht bestandenen Punkt. In der kostenlosen Version enthalten.",
                details: """
                • Systemhärtung: 1. FileVault, 2. SIP (Systemintegritätsschutz), 3. Gatekeeper, 4. automatische Sicherheitsupdates, 5. Apple XProtect.
                • Netzwerkverteidigung: 6. macOS-Firewall, 7. Tarnmodus, 8. WLAN-Verschlüsselungsstärke, 9. ARP-Spoofing-Überwachung, 10. Gateway-ARP-Fixierung.
                • Authentifizierung & Zugriffskontrolle: 11. SSH-Fernanmeldungskonfiguration (Root-Anmeldung deaktiviert, nur Schlüsselauthentifizierung), 12. sudo-Rechteausweitung (`NOPASSWD`-Prüfung).
                • Dienste & Portexposition: 13. offengelegte Ports.
                • Malware- & Download-Schutz: 14. Web- & E-Mail-Schutz, 15. DNS-Bedrohungsschutz, 16. Phishing- und Malware-Link-Schutz (Safari-Betrugsseiten-Warnung).
                • Physische Ports & Geräte: 17. Physischer Portschutz vor unbefugtem USB / BadUSB, 18. macOS-Zubehörverbindungsschutz (Apple Silicon).
                • Nicht anwendbar: Firewall und Tarnmodus in einem vertrauenswürdigen Netzwerk, SSH bei deaktivierter Fernanmeldung, die sudo-Prüfung vor Verbindung des Helfers sowie der Zubehörschutz auf Intel-Macs werden von der Punktzahl ausgeschlossen.
                • Noten: 100 = S, 85–99 = A, 70–84 = B, unter 70 = C. Auch über das MCP-Tool `get_security_report` abrufbar.
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
                • Hinweis: Die Air-Gap-Tests trennen das Netzwerk wirklich vorübergehend. Heben Sie die Sperre über das Notfallfenster auf (sie stellt sich auch innerhalb von 10 Minuten von selbst wieder her).
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
                • Begleitdienste: Auch Helfer-LaunchDaemons für das Air-Gap-Sicherheitsnetz (automatische Freigabe nach 10 Minuten) und das Boot-Gate (bis zu 90 Sekunden) werden registriert.
                • Verifizierung: Bei XPC-Verbindungen werden Codesignaturen (Team-ID) geprüft, um Aufrufe von nicht autorisierten Prozessen abzulehnen.
                """,
                recommendation: "Genehmigen Sie den Helfer beim ersten Start, wenn Sie dazu aufgefordert werden. Ist er nicht genehmigt, zeigt das Menü „⚠️ Helfer genehmigen…“."
            ),
            LocalizedEntry(
                id: "feat_mcp_server",
                title: "MCP-Server-Integration (Nur-Lese-Zugriff für KI-Assistenten)",
                summary: "RoamSwitch.app enthält einen reinen Lese-MCP-Server (Model Context Protocol), sodass KI-Assistenten wie Claude nach dem Sicherheitszustand Ihres Mac fragen können. Es gibt keine Werkzeuge, die Einstellungen ändern oder etwas blockieren.",
                details: """
                • Übertragung: Nur lokales stdio. Programm: `/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`.
                • Wichtigste Tools: `get_security_report` (Sicherheitsprüfung), `get_exposed_ports`, `get_guard_status`, `audit_url_safety`, `audit_secrets`, `audit_security_logs`, `get_quarantine_status`, `get_notification_history`, `get_canary_status`, `get_port_anomaly_incidents`, `get_runtime_threat_status`, `get_incident_timeline` (Eindämmungs-Vorfall-Zeitleiste), `get_network_history` (Netzwerkverlauf-Lernen), `run_package_cve_scan`, `run_package_cve_scan_languages`, `run_active_vuln_scan` (das einzige Tool, das Datenverkehr sendet, ausschließlich nicht-destruktive Sondierungen an 127.0.0.1) sowie `get_app_help` (diese Wissensdatenbank).
                • Ressourcen: `roamswitch://docs/features`, `roamswitch://docs/alerts-and-messages`, `roamswitch://docs/settings-guide`, `roamswitch://docs/troubleshooting`.
                • Sprache: Antworten folgen der Spracheinstellung der App. `get_app_help` akzeptiert ein `language`-Argument (ja / en / zh-Hans / zh-Hant / ko / de / fr / es / it / pt-PT).
                • Sicherheit: Da alles nur lesend ist, kann selbst eine durch Prompt-Injection manipulierte KI weder die Schutzstufe ändern noch Ports isolieren.
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
                2. Wurde eine benötigte legitime Seite versehentlich blockiert, nutzen Sie „Einmal erlauben (5 Min.)“ in der Benachrichtigung oder fügen Sie sie der Positivliste hinzu.
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
                • Automatische Abwehr: Sämtlicher Datenverkehr gekappt plus WLAN-Funk aus, wird ohne Aufhebung nach maximal 10 Minuten automatisch wiederhergestellt. Der erkennende Prozess, die Kategorie und Apples Erkennungsmeldung werden festgehalten.
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
                • Automatische Abwehr (bei Ausführung im Terminal, Pro, standardmäßig deaktiviert): Air-Gap-Eindämmung (WLAN-Funk wird nicht ausgeschaltet), automatisch nach maximal 10 Minuten wiederhergestellt.
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
                summary: "Beim ersten Aktivieren einer Pro-Lizenz werden die wichtigsten autonomen Verteidigungsfunktionen automatisch eingeschaltet. Danach wird die von Ihnen für jede Funktion getroffene Ein-/Aus-Wahl respektiert.",
                details: """
                • Automatisch eingeschaltet (einmalig, bei erster Pro-Aktivierung): Automatische Blockierung unbekannter Listening-Ports, Ransomware-Köderdatei-Erkennung, automatische Blockierung bei ARP-Spoofing, automatische Trennung bei XProtect-Malware-Erkennung, automatische Protokollprüfung sowie regelmäßige Überwachung wichtiger Systemdateien auf Manipulation. Beim Einschalten der ARP- und XProtect-Trennungen erscheint ein einmaliger erklärender Hinweis.
                • Bei Pro standardmäßig aktiv: Web- & E-Mail-Schutz sowie Überwachung von Autostart-Registrierungen (LaunchAgent/Daemon).
                • Standardmäßig deaktiviert (Opt-in): ClickFix-Auto-Blockierung, Docker-Risikoerkennung, physischer BadUSB-Portschutz, automatische Blockierung von USB-Speicher, Gateway-ARP/NDP-Fixierung, VPN-Tunnel, automatisches Bluetooth-Aus sowie aktive Schwachstellenverifizierung. Der Anbieter des DNS-Bedrohungsschutzes ist Ihre Wahl.
                • Auch in der kostenlosen Version standardmäßig aktiv: Zwischenablage-Schutz (API-Schlüssel und ClickFix-Befehle).
                • Später hinzugefügte Schutzfunktionen erhalten für bestehende Pro-Nutzer jeweils einen eigenen einmaligen Standardwert. Läuft die Lizenz ab, werden Nur-Pro-Schutzfunktionen ausgeschaltet.
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
                title: "Modus, Auto-Update, Systemerweiterung & Positivliste des Link-Schutzes (Pro)",
                summary: "Konfigurieren Sie den Modus des Link-Schutzes, das automatische Update der Bedrohungsliste, den Genehmigungsstatus der Systemerweiterung sowie den Umgang mit versehentlich blockierten Seiten.",
                details: """
                • Modus: „Link-Schutz (Phishing-Verbindungserkennung) (Pro)“ → „Aus“, „Nur warnen (nie blockieren)“ oder „Eindeutige Phishing-Seiten automatisch blockieren (empfohlen)“. Der Warnmodus funktioniert nur, wenn die Systemerweiterung aktiv ist.
                • Auto-Update: Klicken Sie auf „Auto-Update: an (nur Empfang)“, um es auszuschalten. Es funktioniert weiterhin mit den mitgelieferten Daten und der Homograph-Erkennung. Listenversion und Domainanzahl werden im Menü angezeigt.
                • Durchsetzungspunkt: „Durchsetzung: Systemerweiterung (DoH-fähig)“, „Durchsetzung: hosts-Fallback“, „Systemerweiterung wird aktiviert…“ oder ein Fehler der Systemerweiterung. Während die Genehmigung aussteht, erscheint „Systemerweiterung genehmigen (Systemeinstellungen öffnen)…“.
                • Erlauben/Blockieren: „Einmal erlauben (5 Min.)“ bei einer Blockierungsbenachrichtigung erlaubt die Seite für 5 Minuten. Im Warnfenster getroffene Erlauben-/Blockieren-Entscheidungen werden gespeichert.
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
                summary: "Die kostenlose Version umfasst zeitlich unbegrenzt die automatische netzwerkbasierte Schutzumschaltung, die 18-Punkte-Sicherheitsprüfung sowie eine Reihe manueller Prüfwerkzeuge. Pro schaltet automatische Eindämmung, Echtzeitschutz und Patrouillenwarnungen frei.",
                details: """
                [Kostenlos]
                • Automatische 3-stufige PF-Paketfilter-Umschaltung je Netzwerk, mit automatischem Stopp und Wiederherstellen von Freigabediensten und AirDrop
                • Mac-Sicherheitsprüfung (18 Punkte), XProtect-Status sowie Datei-/App-Sicherheitsprüfung
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
                • Andere Clients (Codex CLI u. a.): https://lafine.net/mcp-setup.html
                • Antwortsprache: Folgt der Einstellung „Sprache / Language“ der App. `get_app_help` akzeptiert pro Aufruf ein `language`-Argument.
                • Die Kommunikation erfolgt ausschließlich über lokales stdio, ohne nach außen zu senden (nur `run_active_vuln_scan` sendet nicht-destruktive Sondierungen an 127.0.0.1).
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
                • Automatische Wiederherstellung: Auch ohne manuelles Aufheben stellt das Sicherheitsnetz des Helfers die Netzwerkverbindung innerhalb von 10 Minuten wieder her. Nach Beenden, einem Absturz oder Neustart sind keine manuellen Schritte nötig.
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
                • Vorübergehend erlauben: „Einmal erlauben (5 Min.)“ bei der Blockierungsbenachrichtigung.
                • Dauerhaft erlauben: Die Wahl „Erlauben“ im Warnfenster wird gespeichert.
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
                  - Tägliche Downloads der Link-Schutz-Bedrohungsliste, der Paket-CVE-Karten und der Schwachstellen-CVE-Karten (rein empfangend, signaturgeprüft, ohne Übertragung von Kennungen; das Auto-Update des Link-Schutzes lässt sich ausschalten)
                  - Normaler Datenverkehr zu den von Ihnen konfigurierten VPN- und sicheren DNS-Anbietern
                  - Nicht-destruktive Sondierungen der aktiven Schwachstellenverifizierung an 127.0.0.1 (diesen Mac selbst)
                • Es gibt nirgendwo im Code eine Telemetrie oder Nutzungserfassung. Sogar die Erinnerung zur Helfer-Genehmigung funktioniert nur mit einer geräteinternen Zählung.
                """,
                recommendation: "Es ist auch in hochvertraulichen Geschäftsumgebungen und persönlichen Entwicklungsumgebungen bedenkenlos nutzbar, ohne Sorge vor Datenlecks."
            ),
        ]
    }
}
