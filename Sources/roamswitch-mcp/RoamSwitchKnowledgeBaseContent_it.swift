// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.10.4 (build 122).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

// Italian (it) content for `RoamSwitchKnowledgeBase`.
// Translated from the English source (`RoamSwitchKnowledgeBaseContent_en.swift`).
// Every entry id here must also exist in every other
// `RoamSwitchKnowledgeBaseContent_<lang>.swift` file.
extension RoamSwitchKnowledgeBase {
    static func labelsIt() -> MarkdownLabels {
        return MarkdownLabels(
            featuresTitle: "Specifica completa delle funzionalità e architettura di RoamSwitch",
            featuresIntro: "Come funziona ogni funzione di sicurezza di RoamSwitch, con le sue impostazioni predefinite e i suoi limiti.",
            alertsTitle: "Catalogo di avvisi e notifiche di RoamSwitch",
            alertsIntro: "Ogni banner di notifica, avviso e finestra di emergenza mostrati da RoamSwitch, con la relativa causa, la difesa automatica attivata e le azioni consigliate passo per passo.",
            settingsTitle: "Guida alle impostazioni e all'uso di RoamSwitch",
            settingsIntro: "Istruzioni passo per passo per ogni impostazione, interruttore, lista consentiti e criterio di RoamSwitch.",
            troubleshootingTitle: "Risoluzione dei problemi e domande frequenti di RoamSwitch",
            troubleshootingIntro: "Risposte ufficiali su domande frequenti, permessi e approvazioni, configurazione di Homebrew / ClamAV / blueutil, falsi positivi e il design della privacy.",
            summary: "Riepilogo",
            overview: "Panoramica",
            detailsHeading: "Dettagli e cause",
            adviceHeading: "Cosa fare",
            recommendation: "Consiglio",
            bestPractice: "Buona pratica",
            advice: "Suggerimento"
        )
    }

    static func contentIt() -> [LocalizedEntry] {
        var list: [LocalizedEntry] = []
        list.append(contentsOf: featuresItNetwork())
        list.append(contentsOf: featuresItMalware())
        list.append(contentsOf: featuresItAudit())
        list.append(contentsOf: alertsItNetwork())
        list.append(contentsOf: alertsItMalware())
        list.append(contentsOf: settingsIt())
        list.append(contentsOf: troubleshootingItSetup())
        list.append(contentsOf: troubleshootingItOperation())
        return list
    }

    // MARK: - Features: network & devices

    private static func featuresItNetwork() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_network_autoswitch",
                title: "Cambio automatico della sicurezza di rete e filtro pacchetti PF (3 livelli)",
                summary: "Confronta l'indirizzo MAC del gateway della rete attuale con le reti registrate e applica automaticamente il livello di protezione di quella rete. Le reti non registrate ricevono il livello di Protezione predefinita fuori sede (inizialmente Blocco massimo). Disponibile nell'edizione gratuita.",
                details: """
                • 🟢 Attendibile (Aperta - Sbloccata): ad esempio a casa. Firewall disattivato; servizi di condivisione (SSH / SMB / Condivisione schermo) e AirDrop consentiti.
                • 🟡 Bilanciato (Firewall e furtività): ad esempio al lavoro o in tethering. Il filtro pacchetti PF e la modalità invisibile bloccano i sondaggi esterni mantenendo attivi i servizi di condivisione.
                • 🔴 Blocco massimo (Condivisione e AirDrop disattivati): bar, Wi-Fi pubblico, reti non registrate. Tutto il traffico in entrata viene bloccato, i demoni di condivisione vengono arrestati, AirDrop viene disattivato.
                • Come decide: a un cambio di rete legge l'indirizzo MAC del gateway e lo confronta con le reti registrate. Gli eventi di percorso che non cambiano il gateway (rinnovo DHCP, roaming Wi-Fi) non attivano una rivalutazione completa.
                • Dettagli interni: l'helper privilegiato `RoamSwitchHelper` (via XPC) gestisce un'ancora `pfctl` dedicata, così i pacchetti vengono scartati a livello di kernel.
                • Override manuale: da Override manuale puoi scegliere, per livello, Fino alla disconnessione (Consigliato), Per 1 ora, Per 4 ore, o Fino all'annullamento manuale (vedi set_manual_override).
                """,
                recommendation: "Registra la tua casa e altri uffici sicuri tramite «Registra rete attuale», e lascia che il Blocco massimo si applichi automaticamente altrove."
            ),
            LocalizedEntry(
                id: "feat_network_history_guard",
                title: "Apprendimento della cronologia di rete e rilevamento di gemello malvagio (Wi-Fi simile) (Pro)",
                summary: "Apprende, solo su questo Mac, quali indirizzi MAC del gateway ha usato ogni SSID Wi-Fi, e avvisa di un possibile gemello malvagio (punto di accesso falso) quando ti unisci a un SSID sconosciuto il cui nome somiglia in modo sospetto a una rete già usata.",
                details: """
                • Cosa viene appreso: per ogni SSID, gli indirizzi MAC del gateway osservati (fino a 8 per SSID, per il Wi-Fi mesh), salvati in `~/Library/Application Support/RoamSwitch/network_history.json`. Fino a 200 SSID, eliminando prima i più vecchi. Nulla viene inviato fuori dal dispositivo.
                • Test di somiglianza: distanza di modifica (Levenshtein) senza distinzione tra maiuscole e minuscole. I nomi più corti di 6 caratteri sono esenti, e la distanza consentita cresce lentamente con la lunghezza (1-2 caratteri), così SSID generici predefiniti come «ASUS» o «TP-Link_5G» che coincidono per caso non lo attivano mai.
                • Controllo dei falsi positivi: lo stesso hardware gateway che trasmette un secondo SSID (rete ospiti, router rinominato) non viene segnalato. Un SSID noto osservato con un nuovo MAC del gateway (router sostituito) viene registrato ma non allerta mai da solo.
                • Mentre viene rilevato lo spoofing ARP, l'osservazione viene saltata, così il MAC di un attaccante non viene mai appreso come legittimo.
                • L'avviso è un allarme in tempo reale, inviato in Pro. La cronologia appresa è disponibile tramite lo strumento MCP `get_network_history`.
                """,
                recommendation: "Se ricevi questo avviso, non inserire credenziali su quel Wi-Fi e verifica il vero nome e la posizione della rete. Un tunnel VPN (feat_vpn_tunnel) è la contromisura più affidabile."
            ),
            LocalizedEntry(
                id: "feat_arp_spoof_guard",
                title: "Rilevamento di ARP spoofing (impersonificazione di rete) e blocco automatico (Pro)",
                summary: "Rileva l'ARP spoofing, in cui un attaccante sulla stessa rete si spaccia per il router per intercettare o manomettere il traffico (attacco man-in-the-middle). Sulle reti con Blocco massimo taglia subito la rete; sugli altri livelli notifica soltanto e lascia la decisione a te.",
                details: """
                • Rilevamento: l'indirizzo IP del gateway predefinito resta invariato mentre il suo indirizzo MAC cambia improvvisamente. Oltre agli eventi di cambio rete, un sondaggio dedicato ogni 15 secondi rileva anche attacchi che iniziano a sessione già avviata.
                • Risposta: su una rete con Blocco massimo, contenimento Air-Gap immediato (feat_airgap_containment). Su reti Attendibili o Bilanciate, solo notifica, e puoi attivare il contenimento da «Monitoraggio porte e dispositivi» con «Spoofing ARP rilevato — interrompi ora tutta la rete». Questo evita falsi allarmi da riavvii del router o roaming mesh, ed evita che un singolo pacchetto ARP falsificato venga usato come arma per provocare un'interruzione autoinflitta.
                • Predefinito: la voce di menu «Blocco automatico al rilevamento di ARP spoofing (impersonificazione di rete) (Pro)» si attiva automaticamente alla prima attivazione di una licenza Pro (set_pro_default_guards).
                • Ruolo: questa è la risposta successiva al fatto. La prevenzione è affidata al blocco ARP/NDP del gateway (feat_gateway_arp_lock) e al tunnel VPN (feat_vpn_tunnel).
                • Gli incidenti vengono registrati nella cronologia degli incidenti (feat_containment_incident_timeline) come MITRE ATT&CK T1557.
                """,
                recommendation: "Tienila attiva. Per una protezione MITM più forte aggiungi il tunnel VPN; per la prevenzione senza infrastruttura aggiuntiva aggiungi il blocco ARP/NDP del gateway."
            ),
            LocalizedEntry(
                id: "feat_gateway_arp_lock",
                title: "Blocco ARP/NDP del gateway (Preventivo) (Pro)",
                summary: "Quando ti unisci a una rete non attendibile, blocca gli indirizzi MAC del gateway, del router IPv6 e di qualsiasi server DNS sul link locale come voci statiche della cache dei vicini, prevenendo gli attacchi man-in-the-middle da spoofing ARP/NDP prima che inizino. Disattivato per impostazione predefinita.",
                details: """
                • Attivazione: «Monitoraggio porte e dispositivi» → «Blocca ARP/NDP del gateway sulle reti non attendibili (preventivo) (Pro)».
                • Funzionamento: alla connessione vengono lette le MAC attuali e l'helper le blocca come voci permanenti con `arp -s` / `ndp -s`. Il kernel ignora poi le risposte ARP falsificate e gli annunci dei vicini per quegli IP.
                • Ambito: solo questi tre tipi di voci. Nulla viene bloccato sulle reti Attendibili (aperte), così un riavvio del router domestico non interrompe mai la connessione. I blocchi vengono cancellati e ricreati a ogni cambio di rete.
                • Limite (fiducia al primo utilizzo): viene attendibile il primo MAC osservato, quindi un attaccante già presente prima della connessione potrebbe far bloccare il proprio MAC. Se non puoi accettare questo presupposto, usa il tunnel VPN.
                • Si riflette nel punto «Blocco ARP del gateway (difesa preventiva da MITM)» dell'audit di sicurezza del Mac.
                """,
                recommendation: "Una buona difesa MITM leggera quando una VPN non è praticabile. Può essere combinata con il tunnel VPN (la VPN è la difesa principale, questo un complemento)."
            ),
            LocalizedEntry(
                id: "feat_vpn_tunnel",
                title: "Tunnel VPN (WireGuard / Tailscale, con kill switch) (Pro)",
                summary: "Attiva automaticamente un tunnel cifrato sulle reti non attendibili così gli attacchi man-in-the-middle vedono solo testo cifrato. Scegli WireGuard (file di configurazione) o Tailscale (exit node) come backend. Non dipende dall'integrità del livello 2 (ARP/NDP), rendendolo la difesa anti-MITM principale. Non richiede il permesso Network Extension.",
                details: """
                • Backend: «Monitoraggio porte e dispositivi» → «Tunnel VPN (anti-MITM su reti non attendibili) (Pro)» → «Backend», poi scegli WireGuard o Tailscale. Funziona solo il backend selezionato.
                • WireGuard: richiede `wireguard-tools` di Homebrew (`brew install wireguard-tools`). Importa una configurazione con «Importa config WireGuard (.conf)…». Fornisci tu la configurazione (Mullvad, IVPN, Proton VPN, un tuo server, il tuo datore di lavoro); RoamSwitch non fornisce server VPN.
                • Kill switch di WireGuard: pf applica «block drop all» con eccezioni solo per lo, l'interfaccia del tunnel, l'handshake UDP verso l'endpoint, DHCP e ICMP. Nulla trapela in chiaro mentre il tunnel è giù.
                • Tailscale: per chi usa già Tailscale. RoamSwitch non lo installa né effettua l'accesso; legge `tailscale status` ed esegue `tailscale set --exit-node=<nodo>`. È richiesto un exit node (tutto il traffico passa da lì). Un exit node offline è mostrato nella riga di stato.
                • Si consiglia la CLI di Tailscale (standalone): `brew install tailscale` → `sudo tailscaled install-system-daemon` → `sudo tailscale up`. La versione App Store (interfaccia grafica) non può essere pilotata con `tailscale set` dall'esterno dell'app; scegli allora l'exit node nell'app Tailscale, mentre RoamSwitch gestisce solo la visualizzazione dello stato e il kill switch.
                • Kill switch di Tailscale (disattivato per impostazione predefinita, opzionale): pf lascia passare solo lo, l'utun di Tailscale, il CGNAT 100.64.0.0/10, il DNS, STUN 3478, 41641, DERP tcp 443, DHCP e ICMP. Meno rigoroso di WireGuard («difficile da far trapelare» anziché a tenuta stagna), e su alcune reti può interferire con la connettività di Tailscale stessa, per questo è opzionale.
                • Automatico: il tunnel/exit node si attiva sulle reti non attendibili, si disattiva su quelle attendibili. Se la licenza scade, il tunnel e il kill switch vengono rilasciati automaticamente.
                """,
                recommendation: "La protezione più efficace se usi spesso il Wi-Fi pubblico. Utenti Tailscale: installa la CLI e scegli il backend Tailscale più un exit node. Altrimenti `brew install wireguard-tools` con il file `.conf` del tuo provider VPN è la via più semplice."
            ),
            LocalizedEntry(
                id: "feat_airgap_containment",
                title: "Contenimento di emergenza Air-Gap (interruzione totale della rete, Wi-Fi disattivato, rete di sicurezza per il ripristino automatico)",
                summary: "Il contenimento di emergenza condiviso usato quando viene rilevata una minaccia grave (ransomware, rilevamento malware da XProtect, spoofing ARP, ClickFix). Blocca tutto il traffico in entrata e in uscita. Interrompe anche le connessioni già aperte. Per i trigger a bassa affidabilità (come ClickFix), la rete torna automaticamente entro 10 minuti al massimo, anche dopo un crash o un riavvio. I trigger ad alta affidabilità (file esca del ransomware, rilevamento XProtect, spoofing ARP su una rete con Blocco massimo, contenimento ARP avviato con «Interrompi ora tutta la rete» dall'avviso di spoofing) non si riaprono mai da soli: dopo fino a 1 ora di interruzione totale passano a una modalità ridotta che continua a bloccare le nuove connessioni in uscita.",
                details: """
                • Come: l'helper privilegiato carica pf con «block drop all» (eccetto il loopback) e lo rilegge per confermare. Anche il traffico in uscita viene tagliato, il che impedisce l'esfiltrazione di chiavi o dati verso un server C2. Se l'applicazione fallisce, viene ritentata fino a 3 volte (8 secondi di timeout ciascuna); se fallisce ancora, mostra «Interruzione automatica della rete non riuscita» e chiede di disconnettersi manualmente. Non dichiara mai un isolamento che non sia reale.
                • Wi-Fi disattivato: pf scarta solo i pacchetti mentre l'adattatore resta associato, quindi il contenimento per spoofing ARP, ransomware e XProtect disattiva anche il Wi-Fi stesso tramite `networksetup` (attivo per impostazione predefinita; impostazione interna `RoamSwitch.AirGapAutoWiFiKillEnabled`). Il contenimento ClickFix non disattiva il Wi-Fi.
                • Rilascio: rilasciare dalla finestra di emergenza o dalla notifica rimuove il blocco pf e riattiva il Wi-Fi. La voce della barra dei menu «Rimuovi isolamento Air-Gap» è sempre disponibile, anche nella versione gratuita e anche se una licenza Pro scade durante l'incidente. Le notifiche sullo stato dell'isolamento (avviato, ridotto, rimosso, non riuscito) arrivano anche agli utenti gratuiti; gli avvisi di rilevamento restano Pro.
                • Rete di sicurezza: se nessuno lo rilascia (anche dopo un crash dell'app o un riavvio del Mac), un timer lato helper agisce in base all'affidabilità del trigger. Bassa affidabilità (ClickFix, euristiche generiche, un Air-Gap manuale semplice senza avviso): l'Air-Gap viene rilasciato forzatamente dopo 10 minuti e il Wi-Fi viene ripristinato. Alta affidabilità (file esca del ransomware, rilevamento XProtect, spoofing ARP su una rete con Blocco massimo, contenimento ARP avviato con «Interrompi ora tutta la rete» dall'avviso di spoofing): Air-Gap completo fino a 1 ora, poi modalità ridotta. In modalità ridotta le nuove connessioni in uscita (tranne DHCP) restano bloccate, ma il Wi-Fi viene riacceso così puoi vedere a quale rete sei collegato; non si apre mai a tempo, solo quando lo rilasci o una nuova verifica conferma che la causa è scomparsa (ad esempio il processo sospetto è terminato). Per il contenimento ARP la nuova verifica legge la cache ARP senza inviare traffico e considera risolta la causa solo se il MAC attendibile del gateway compare in 3 verifiche consecutive distribuite su almeno 60 secondi (un MAC diverso, una voce assente o incompleta, un MAC duplicato o una cache illeggibile azzerano il conteggio). Le connessioni già aperte vengono interrotte quando l'Air-Gap si attiva e di nuovo al passaggio alla modalità ridotta.
                • Porta di avvio: subito dopo l'avvio, prima che l'app applichi la sua politica, è in vigore una porta pf a rifiuto predefinito; si rilascia da sola dopo al massimo 90 secondi.
                """,
                recommendation: "Quando il contenimento si attiva, leggi prima la notifica, chiudi le app sospette ed esegui una scansione prima di rilasciarlo. Se sai che è un falso positivo, rilascialo subito."
            ),
            LocalizedEntry(
                id: "feat_port_anomaly_guard",
                title: "Blocco automatico delle porte di ascolto sconosciute e isolamento dei server di sviluppo (Pro)",
                summary: "Monitora ogni porta TCP in ascolto e, quando un eseguibile prima non esposto inizia improvvisamente ad ascoltare su 0.0.0.0, blocca l'accesso a quella porta dalla LAN. I server di sviluppo e i server AI locali possono anche essere isolati su 127.0.0.1 con un clic.",
                details: """
                • Monitoraggio: le porte in ascolto vengono analizzate ogni 20 secondi. L'identità è il percorso dell'eseguibile, così un'app nota che cambia solo numero di porta non lo attiva. Lo stato subito dopo l'attivazione viene catturato come base di riferimento.
                • Blocco automatico: quando un eseguibile sconosciuto inizia a esporre una porta, pf blocca solo l'accesso esterno (il Mac stesso e localhost possono continuare a usarla). Questo intercetta una backdoor impiantata da un exploit zero-day senza conoscere la famiglia del malware.
                • Esclusi: i demoni di sistema firmati da Apple sotto `/System/Library` o `/usr/libexec` (ad esempio rapportd, necessario per Handoff, AirPlay, AirDrop). Gli strumenti generici sotto `/usr/bin`, come `/usr/bin/python3` o `/usr/bin/nc`, vengono comunque segnalati.
                • Servizi rischiosi: identifica servizi spesso esposti senza autenticazione, come Redis (6379), MongoDB (27017), Memcached (11211), Elasticsearch (9200), VNC (5900), e server AI locali come Ollama (11434), LM Studio (1234), Gradio (7860) e vLLM (8000).
                • Isolamento dei server di sviluppo: apri la porta da «Porte esposte» e scegli «Isola porta» per limitarla a 127.0.0.1 (Pro).
                • Falsi positivi: consenti in modo permanente con il pulsante «Consenti» della notifica o dalla schermata di audit delle porte. Disattivare questa protezione (o una licenza scaduta) rilascia tutti i blocchi creati.
                • Predefinito: si attiva automaticamente alla prima attivazione di Pro. La cronologia degli incidenti è disponibile tramite lo strumento MCP `get_port_anomaly_incidents`.
                """,
                recommendation: "Vincola i tuoi server di sviluppo e gli LLM locali a `127.0.0.1` (ad esempio `OLLAMA_HOST=127.0.0.1 ollama serve`, `npm run dev -- -H 127.0.0.1`)."
            ),
            LocalizedEntry(
                id: "feat_active_vuln_scan",
                title: "Verifica attiva delle vulnerabilità — disattivata per impostazione predefinita",
                summary: "Per i servizi rilevati su questo stesso Mac (127.0.0.1), verifica con sonde minime di sola lettura se rispondono davvero senza autenticazione. Disattivata per impostazione predefinita; richiede attivazione esplicita e una conferma a ogni esecuzione.",
                details: """
                • Attivazione: «Monitoraggio porte e dispositivi» → «Verifica attiva delle vulnerabilità». Questo sblocca solo il pulsante «Esegui verifica attiva» nella schermata di audit delle porte; non invia nulla di propria iniziativa, e ogni esecuzione chiede prima «Inviare la richiesta di verifica?».
                • Solo verso 127.0.0.1: non viene mai inviato nulla a un altro host.
                • Accesso non autenticato: sonde singole, a breve timeout e non distruttive verso Redis (PING), Memcached (stats) e MongoDB (listDatabases).
                • Server di sviluppo generici: verifica configurazioni CORS errate (Origin riflesso con credenziali), path traversal e redirect aperti.
                • Corrispondenza con CVE note: per Redis / Memcached raggiungibili senza autenticazione, la versione viene letta con una query non distruttiva e confrontata con intervalli di versione di CVE note. Non vengono inviati payload di exploit.
                • Disponibile anche come strumento MCP `run_active_vuln_scan` (l'unico strumento che invia traffico di rete, solo verso localhost).
                """,
                recommendation: "Attivala solo quando vuoi verificare se Redis, Docker, un LLM locale o simili in esecuzione sul tuo stesso Mac sono davvero raggiungibili senza autenticazione."
            ),
            LocalizedEntry(
                id: "feat_nmap_nse",
                title: "Scansione supplementare nmap NSE (livello aggiuntivo per la verifica attiva delle vulnerabilità)",
                summary: "Quando è attiva anche la verifica attiva delle vulnerabilità, esegue gli script NSE della categoria «safe» del nmap installato nel sistema sulle porte esposte per aggiungere una copertura di protocolli che le sonde proprie di questo prodotto non hanno (chiavi host SSH, banner SMTP, ecc.). Il risultato è un giudizio proprio di nmap, non riverificato in modo indipendente da questo prodotto.",
                details: """
                • Incluso automaticamente: viene eseguito automaticamente quando «Verifica attiva delle vulnerabilità (verifica attiva della raggiungibilità)» è attiva, senza un'impostazione separata per questo. nmap non viene mai installato automaticamente — questo ha effetto solo se è già installato nel sistema (ad esempio tramite Homebrew); altrimenti non fa nulla.
                • Selezione degli script: `safe and not broadcast and not external`. La sola categoria «safe» non basta — gli script `broadcast` interrogano l'intera LAN tramite multicast/broadcast, non solo l'host di destinazione, e gli script `external` (ad es. `vulners.nse`) inviano effettivamente il servizio/la versione rilevati a terze parti come vulners.com. Entrambi contraddicono il principio di progettazione di questo prodotto di toccare solo 127.0.0.1 e mai altri host o server esterni, quindi vengono esclusi.
                • Timeout: 15 secondi per script (`--script-timeout 15s`). Alcuni script «safe» possono essere eseguiti indefinitamente contro API HTTP non standard, sottraendo risultati alle altre porte senza questo limite.
                • Ambito: le stesse porte già confermate aperte utilizzate dalla verifica attiva delle vulnerabilità stessa.
                """,
                recommendation: "Considera i risultati di nmap come informazioni di riferimento — esamina il contenuto e agisci solo se effettivamente pertinente."
            ),
            LocalizedEntry(
                id: "feat_usb_keyboard_guard",
                title: "Protezione fisica della porta da USB non autorizzato / BadUSB (Approvazione tastiera e analisi del ritmo di digitazione) (Pro)",
                summary: "Quando viene collegata una tastiera USB sconosciuta o un cavo modificato (Rubber Ducky, O.MG Cable, Flipper Zero e simili), i tasti premuti da quel dispositivo vengono bloccati finché non lo approvi, impedendo l'iniezione automatizzata di comandi. Analizza anche gli intervalli di digitazione e avvisa quando sembrano scriptati.",
                details: """
                • Rilevamento: IOHIDManager individua le nuove tastiere in tempo reale. La tastiera integrata viene attendibile automaticamente.
                • Blocco: il dispositivo non approvato viene acquisito in modo esclusivo (seize di IOHIDDevice), così solo i tasti premuti su quel dispositivo non raggiungono il sistema; le altre tastiere continuano a funzionare. Solo se l'acquisizione fallisce si ricorre a un blocco tramite CGEventTap, che richiede il permesso Accessibilità.
                • Approvazione: una finestra in primo piano offre «Fidati e consenti» o «Rifiuta e mantieni bloccato». Le tastiere consentite vengono aggiunte alla lista consentiti.
                • Analisi del ritmo di digitazione: mentre è bloccato, gli intervalli di digitazione del dispositivo continuano a essere misurati. Dopo almeno 5 intervalli, una media di 12 ms o meno, oppure di 45 ms o meno con un'uniformità molto elevata (coefficiente di variazione di 0,35 o inferiore), genera un avviso «mostra segni di digitazione scriptata». Questo cattura una velocità e una regolarità meccaniche che nessun umano produce, solo come prova supplementare; non cambia la decisione di blocco.
                • Disattivata per impostazione predefinita. Attivala con «Monitoraggio porte e dispositivi» → «Protezione fisica della porta da USB non autorizzato / BadUSB (Pro)»; gestisci la lista consentiti in «Impostazioni protezione USB / BadUSB…».
                """,
                recommendation: "Se usi tastiere esterne, registra solo quelle che hai collegato tu stesso con «Fidati e consenti». Rifiuta e scollega sempre un dispositivo che attiva l'avviso di digitazione scriptata."
            ),
            LocalizedEntry(
                id: "feat_usb_storage_guard",
                title: "Blocco automatico di archiviazione USB non autorizzata e scansione automatica ClamAV (Pro)",
                summary: "Un'unità USB o un disco esterno non presente nella lista consentiti viene prima montato in sola lettura mentre ti viene chiesto come procedere. I dispositivi consentiti vengono anche scansionati con ClamAV prima di essere collegati con il permesso configurato.",
                details: """
                • Monitoraggio: DiskArbitration rileva istantaneamente i montaggi di volumi esterni/rimovibili.
                • Dispositivi non registrati: rimontati in sola lettura per sicurezza, con una finestra di dialogo che offre «Consenti lettura-scrittura», «Consenti in sola lettura» o «Espelli». Espelli smonta ed espelle immediatamente.
                • Dispositivi consentiti: il permesso della lista consentiti (Sola lettura / Lettura-scrittura) viene applicato automaticamente, con una scansione ClamAV prima di qualsiasi passaggio a lettura-scrittura.
                • Infezione: se viene trovato malware, il volume viene espulso automaticamente e viene inviato un avviso urgente.
                • Unità riformattate: se l'UUID del volume cambia ma l'identità hardware, incluso il numero di serie, corrisponde, l'approvazione viene mantenuta (il solo ID produttore/prodotto non conta mai come corrispondenza).
                • Ambito: copre l'esfiltrazione di dati e i payload dannosi tramite archiviazione. I dispositivi BadUSB di tipo HID che si fingono tastiere sono gestiti da feat_usb_keyboard_guard.
                """,
                recommendation: "Aggiungi alla lista consentiti solo le unità USB che usi per lavoro, e preferisci il permesso Sola lettura sui Mac che gestiscono dati sensibili."
            ),
            LocalizedEntry(
                id: "feat_bluetooth_guard",
                title: "Spegnimento automatico del Bluetooth sulle reti non attendibili (Pro)",
                summary: "Quando ti unisci a una rete fuori sede dove si applica il Blocco massimo, il Bluetooth viene disattivato automaticamente per ridurre l'esposizione ad accoppiamenti non richiesti e attacchi BLE, e viene ripristinato quando torni su una rete attendibile.",
                details: """
                • Strumento: macOS non offre un'API pubblica per attivare/disattivare l'alimentazione del Bluetooth, quindi RoamSwitch usa lo strumento open source Homebrew `blueutil` (`brew install blueutil`). Se manca, il menu mostra istruzioni di installazione.
                • Ripristino: il Bluetooth viene riattivato su una rete attendibile solo se era attivo subito prima che RoamSwitch lo disattivasse; una scelta fatta da te fuori sede non viene annullata.
                • Disattivata per impostazione predefinita: molte persone usano AirPods e simili nei bar, quindi interrompere silenziosamente l'audio non sarebbe gradito. Opzionale.
                """,
                recommendation: "Se non usi accessori Bluetooth fuori sede, attivala per evitare la scansione radio e gli accoppiamenti non richiesti."
            ),
        ]
    }

    // MARK: - Features: malware & web protection

    private static func featuresItMalware() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_webmail_download_guard",
                title: "Protezione Web ed e-mail (Scansione automatica e quarantena dei download) (Pro)",
                summary: "Sorveglia con FSEvents i file salvati da browser, Mail, Slack, Discord e simili, li verifica con una firma statica e ClamAV, e sposta le minacce nel caveau di quarantena.",
                details: """
                • Cartelle monitorate: per impostazione predefinita `~/Downloads`, `~/Desktop`, `~/Documents` e la cartella di download di Mail. Aggiungi o rimuovi cartelle con «⚙️ Gestisci cartelle monitorate…».
                • Origine del download: identificata dall'attributo esteso `com.apple.quarantine` che macOS vi associa.
                • Verifica a due livelli: una verifica di firma statica sul dispositivo (frasi tipiche di reverse shell e simili; funziona anche senza ClamAV) più una scansione ClamAV. Una corrispondenza della firma statica porta alla quarantena indipendentemente dal verdetto di ClamAV, e se ClamAV non concorda, la notifica indica che potrebbe trattarsi di un falso positivo.
                • Quarantena: le minacce vengono spostate in `~/Library/Application Support/RoamSwitch/Quarantine/` (mai eliminate). Se lo spostamento fallisce, la notifica indica che la quarantena è fallita e chiede di eliminare il file manualmente.
                • File di test EICAR: la firma di test standard del settore, innocua, non viene messa in quarantena né bloccata e non genera alcuna notifica; viene solo registrata nella cronologia delle notifiche (feat_notification_history).
                • Primo accesso alla cartella: prima della richiesta di permesso di macOS, appare un unico avviso che spiega che si tratta di un permesso legittimo per questa funzione di scansione.
                • Avvisi sui modelli in formato Pickle: vedi feat_ai_model_guard.
                """,
                recommendation: "Installa e attiva ClamAV, e aggiungi qualsiasi cartella di download del browser personalizzata alle cartelle monitorate."
            ),
            LocalizedEntry(
                id: "feat_ai_model_guard",
                title: "Avviso di download di un formato di modello IA pericoloso (Pickle / PyTorch) (Pro)",
                summary: "Quando viene scaricato un file modello `.pkl` / `.pickle` / `.pt` da Hugging Face, Civitai o simili, avvisa che il formato Pickle può eseguire codice arbitrario al caricamento, e consiglia SafeTensors / GGUF.",
                details: """
                • Rilevamento: controlla l'estensione dei file scaricati nelle cartelle monitorate dalla Protezione Web ed e-mail (feat_webmail_download_guard).
                • Rischio: il Pickle di Python può eseguire codice arbitrario durante la deserializzazione, quindi il semplice caricamento di un modello dannoso può compromettere il Mac.
                • Comportamento: solo un avviso; il file non viene messo in quarantena (una corrispondenza di ClamAV o della firma statica porta comunque alla quarantena come di consueto).
                """,
                recommendation: "Non caricare modelli Pickle / PyTorch da fonti sconosciute; usa invece modelli `.safetensors` o `.gguf`."
            ),
            LocalizedEntry(
                id: "feat_quarantine_manager",
                title: "Gestione dei file in quarantena (caveau, ripristino, eliminazione, esclusioni dalla scansione)",
                summary: "I file segnalati da ClamAV o dalla verifica di firma statica non vengono mai eliminati; restano nel caveau di quarantena. Il Gestore quarantena consente di vedere il motivo, ripristinare nella posizione originale, eliminare definitivamente, o escludere un percorso dalle scansioni future.",
                details: """
                • Apri: «Protezione da malware (XProtect e ClamAV)» → ClamAV → «📦 Gestisci file in quarantena…», oppure «📦 Apri gestione quarantena…» sotto Protezione Web ed e-mail.
                • Posizione: `~/Library/Application Support/RoamSwitch/Quarantine/`, con metadati su percorso originale, nome della minaccia e momento della quarantena. Nulla viene rimosso a meno che tu non scelga esplicitamente Elimina definitivamente.
                • Ripristina: riporta il file nella posizione originale; usalo solo quando sei certo che non sia infetto.
                • Escludi e ripristina: per un falso positivo confermato, ripristina il file ed esclude quel percorso esatto dalle future scansioni ClamAV. Le esclusioni sono elencate nella stessa finestra, dove «Rimuovi esclusione» le annulla.
                • Elimina definitivamente: elimina dopo una conferma. Questa azione non può essere annullata.
                • Lo strumento MCP `get_quarantine_status` elenca i file in quarantena.
                """,
                recommendation: "Elimina i file che non riconosci, e usa «Escludi e ripristina» solo per falsi positivi certi, come i tuoi script o binari di sviluppo."
            ),
            LocalizedEntry(
                id: "feat_xprotect_file_safety",
                title: "Stato di Apple XProtect e verifica sicurezza file/app",
                summary: "Mostra la versione delle definizioni e lo stato della protezione anti-malware integrata di macOS, XProtect, e verifica che un file o un'app qualsiasi sia notarizzato, con quale autorità di firma, con quale Team ID e con l'attributo di quarantena dei download. Disponibile nell'edizione gratuita.",
                details: """
                • Apri: «Protezione da malware (XProtect e ClamAV)» → «🍏 Apple XProtect» → «Verifica stato XProtect…» / «Verifica sicurezza file/app…».
                • Verifiche: approvato da Apple (Notarizzato/Gatekeeper) o no, autorità di firma, Team ID, l'attributo di quarantena dei download Web (`com.apple.quarantine`), e il percorso.
                • Uso: prima di aprire un'app per la prima volta, conferma che sia stata firmata e notarizzata da uno sviluppatore legittimo.
                """,
                recommendation: "Verifica le app di origine sconosciuta prima di avviarle, e non aprire nulla che non sia approvato o firmato."
            ),
            LocalizedEntry(
                id: "feat_dns_threat_guard",
                title: "Protezione dalle minacce DNS (Blocca malware e C2) (Pro)",
                summary: "Applica un resolver DNS sicuro (Quad9, Cloudflare, AdGuard, CleanBrowsing) in modo che le risoluzioni dei nomi verso server C2 di malware e siti di phishing vengano bloccate già nella fase DNS.",
                details: """
                • Provider: Quad9 (9.9.9.9 / 149.112.112.112), Cloudflare Security (1.1.1.2 / 1.0.0.2), AdGuard DNS (94.140.14.14 / 94.140.15.15, blocca anche pubblicità e tracker), CleanBrowsing Security (185.228.168.9 / 185.228.169.9).
                • Criterio: «Solo su Wi-Fi non attendibile (Consigliato)» oppure «Sempre attivo su tutte le reti (comprese quelle attendibili)».
                • Dettagli interni: l'helper privilegiato cambia i server DNS del servizio di rete attivo e ripristina le impostazioni DHCP/DNS manuali originali quando torni su una rete attendibile.
                • Stato: il menu mostra «🟢 DNS sicuro attivo» o «🏠 Rete attendibile (DNS standard del router)». È anche un punto dell'audit di sicurezza del Mac.
                """,
                recommendation: "Per evitare il DNS falso sul Wi-Fi pubblico (DNS hijacking) e i domini dannosi, inizia con Quad9 e il criterio riservato a fuori sede."
            ),
            LocalizedEntry(
                id: "feat_passive_link_guard",
                title: "Protezione link (Rileva e blocca connessioni di phishing: estensione di sistema, compatibile DoH, la modalità Avviso fallisce in modo chiuso) (Pro)",
                summary: "Blocca sul dispositivo le connessioni verso siti di phishing e truffa, per qualsiasi browser o app, basandosi su un elenco di minacce di domini di truffa noti e sul rilevamento dell'impersonificazione del marchio. Funziona come un'estensione di sistema per il filtraggio dei contenuti, con un «sinkhole» /etc/hosts come ripiego finché l'estensione non viene approvata.",
                details: """
                • Modalità: «Disattivata», «Solo avvisa (mai bloccare)» e «Blocca automaticamente i siti di phishing evidenti (consigliato)» (predefinita). Cambia modalità sotto Protezione da malware → «Protezione link (rilevamento connessioni di phishing) (Pro)».
                • Cosa viene bloccato: solo i casi evidenti, cioè i domini presenti nell'elenco delle minacce o l'impersonificazione del marchio tramite omografi Unicode. I trucchi con il marchio in un sottodominio, i TLD ad alto rischio e simili vengono trattati come avvisi. Il motore di verdetto e l'elenco sono condivisi con l'edizione Linux.
                • Estensione di sistema (consigliata): l'estensione di sistema per il filtraggio dei contenuti `RoamSwitchLinkFilter` esamina i flussi TCP dopo la risoluzione del nome. Oltre al nome host risolto dal sistema operativo, legge anche l'SNI dal ClientHello TLS, quindi funziona anche se il browser usa il proprio DoH / DoT. In modalità blocco, scarta il QUIC (UDP 443), dove l'SNI non è visibile, così i browser ripiegano su TCP. Il primo utilizzo richiede l'approvazione in Impostazioni di Sistema.
                • Impronta JA3: per le connessioni TLS il cui SNI è stato letto, viene calcolato anche l'hash JA3 del client e confrontato con l'elenco JA3 delle minacce (JA3 non viene mai usato da solo su connessioni senza SNI).
                • Modalità Avviso (fallisce in modo chiuso): la connessione corrispondente viene messa in pausa e appaiono una notifica Consenti/Blocca e un pannello in primo piano; il flusso riprende o viene scartato in base alla tua risposta. Senza risposta entro circa 8 secondi, la connessione viene bloccata. Questo risultato non viene memorizzato nella cache, quindi il tentativo successivo chiederà di nuovo. Le risposte che dai effettivamente vengono ricordate. La modalità Avviso richiede l'estensione di sistema.
                • Ripiego su hosts: finché l'estensione non è attiva, la modalità blocco fa scrivere all'helper privilegiato i domini come `0.0.0.0` in una sezione gestita di `/etc/hosts`.
                • Elenco minacce: viene recuperato una volta al giorno, solo in ricezione, senza inviare identificatori, e verificato con una chiave dedicata Ed25519 per l'elenco (distinta dalla chiave di aggiornamento dell'app). Disattivare l'«Aggiornamento automatico» significa zero traffico in uscita; i dati inclusi e il rilevamento degli omografi continuano a funzionare.
                • Senza Pro: la modalità viene salvata ma nulla viene bloccato.
                """,
                recommendation: "Mantieni il blocco automatico predefinito e approva l'estensione di sistema per la protezione più affidabile. Se uno strumento interno viene bloccato per errore, usa «Consenti una volta (5 min)» nella notifica o la lista consentiti."
            ),
            LocalizedEntry(
                id: "feat_link_safety_auditor",
                title: "Verifica sicurezza dei link (controllo manuale, Zero Telemetry)",
                summary: "Prima di aprire un URL sospetto, lo analizza interamente sul dispositivo e ne valuta il rischio su una scala di 100 in base a omografi Unicode, impersonificazione di sottodominio, TLD ad alto rischio, HTTP non cifrato, indirizzi IP grezzi, e altro ancora. Disponibile nell'edizione gratuita.",
                details: """
                • Apri: Protezione da malware → «🔗 Controlla un link manualmente…», oppure lo strumento MCP `audit_url_safety`.
                • Omografi: rileva caratteri visivamente simili come lettere cirilliche o greche (Punycode / `xn--`).
                • Impersonificazione di sottodominio: analizza strutture come `apple.com.login-verify.xyz` che incorporano il nome di un grande marchio.
                • TLD ad alto rischio: sottrae punti per i TLD comuni nel phishing usa e getta, come `.xyz`, `.top`, `.tk`, `.icu`.
                • HTTP non cifrato e IP grezzi: avvisa dell'HTTP non cifrato nelle pagine di accesso e degli URL con indirizzo IP nudo.
                • Completamente locale: gli URL non vengono mai inviati a un'API di analisi esterna, così gli URL riservati e i token non trapelano.
                """,
                recommendation: "Non fare clic direttamente sui link sospetti ricevuti via e-mail o chat; verificali prima con la Verifica sicurezza dei link."
            ),
            LocalizedEntry(
                id: "feat_ransomware_canary_guard",
                title: "Rilevamento ransomware tramite file esca e Air-Gap autonomo con congelamento dei processi (Pro)",
                summary: "Posiziona file esca (canarino) nascosti nelle tue cartelle utente. Non appena uno di essi viene modificato, eliminato o rinominato, interrompe automaticamente la rete, arresta i servizi di condivisione e mette in pausa (SIGSTOP) il processo sospetto.",
                details: """
                • File esca: quattro in `~/Library/Application Support/RoamSwitch/CanaryGuard/`, più file nascosti che iniziano con `.roamswitch_security_canary_do_not_delete` in Documenti, Scrivania, Download e Foto. Lo SHA-256 di ogni file viene registrato come riferimento.
                • Rilevamento: sorveglianza kqueue in tempo reale più un controllo ogni 60 secondi. Un periodo di attesa di 10 secondi per file evita l'elaborazione duplicata di una stessa raffica di eventi. I file reali modificati negli ultimi 60 secondi vengono registrati come possibilmente interessati.
                • Risposta automatica: (1) blocco del firewall applicativo, (2) contenimento Air-Gap (pf blocca tutto il traffico e il Wi-Fi viene disattivato, feat_airgap_containment), (3) i servizi di condivisione (SMB / SSH / Condivisione schermo) vengono arrestati, (4) il processo sospetto viene messo in pausa con SIGSTOP anziché terminato, (5) avviso urgente e finestra di emergenza in primo piano.
                • Perché mettere in pausa anziché terminare: la rete è già interrotta, quindi un processo in pausa non può causare ulteriori danni. Se si è trattato di un falso positivo, viene ripreso (SIGCONT) al rilascio, senza perdita di dati.
                • Al rilascio: rete e Wi-Fi vengono ripristinati, il processo in pausa viene ripreso, e i file esca manomessi vengono rigenerati.
                • Predefinito: si attiva automaticamente alla prima attivazione di Pro. Cronologia degli incidenti tramite lo strumento MCP `get_canary_status`. Provala in sicurezza con «Simulazione difesa ransomware (Modalità test)» nel menu.
                """,
                recommendation: "Tienila attiva per proteggere i dati importanti da ransomware sconosciuti, e non eliminare i file esca nascosti."
            ),
            LocalizedEntry(
                id: "feat_ransomware_recovery",
                title: "Ripristino da ransomware (estrarre file da uno snapshot preventivo)",
                summary: "Per tornare allo stato precedente alla cifratura, RoamSwitch crea periodicamente snapshot locali APFS e permette di estrarre solo i file necessari in un altro posto. I file attuali non vengono mai sovrascritti.",
                details: """
                • Snapshot preventivi: creati per impostazione predefinita ogni 6 ore (disattivati / 1 / 3 / 6 / 12 / 24 ore), indipendentemente da qualsiasi rilevamento. Uno snapshot creato dopo un rilevamento può contenere già file cifrati.
                • Snapshot di rilevamento: creati anche quando scatta la guardia delle esche, ma possono contenere file cifrati e non sono consigliati come origine del ripristino.
                • Modalità di conservazione: finché uno snapshot di rilevamento è il più recente (fino a 7 giorni), i nuovi snapshot preventivi e la pulizia di quelli vecchi sono sospesi, per non spingere fuori l'ultima generazione precedente alla cifratura.
                • Estrazione: da «Ripristino da ransomware…» nel menu, i file o le cartelle dello snapshot consigliato (il più recente snapshot preventivo ancora presente) vengono copiati in `~/RoamSwitch-Recovered/<ID dello snapshot>/`. I file esistenti non vengono mai sovrascritti e non è previsto il ripristino dell'intero volume. Il ripristino è sempre manuale.
                • Limiti: macOS può eliminare da solo gli snapshot locali dopo circa 24 ore (prima se lo spazio libero è poco) e una generazione scomparsa non è utilizzabile. L'estrazione richiede l'Accesso completo al disco per l'helper di RoamSwitch (la creazione no).
                • MCP: lo strumento di sola lettura `get_ransomware_recovery_snapshots` mostra l'elenco e il consiglio (non può ripristinare nulla).
                • Pro: Questa finestra (elenco ed estrazione dei file) e lo strumento MCP sono funzioni Pro. La creazione degli snapshot funziona anche senza Pro.
                """,
                recommendation: "Mantenga attivi gli snapshot preventivi. Se nota un danno, scolleghi prima la rete ed estragga i file dallo snapshot preventivo consigliato, non da quello di rilevamento."
            ),
            LocalizedEntry(
                id: "feat_runtime_threat_containment",
                title: "Disconnessione di rete automatica al rilevamento di malware da XProtect (Pro)",
                summary: "Nell'istante in cui XProtect / XProtect Remediator, integrato in macOS, rileva o rimuove realmente un malware, la rete viene interrotta con un Air-Gap di emergenza. Un blocco di Gatekeeper su un'app non firmata non interrompe la rete; invia solo una notifica.",
                details: """
                • Origine del segnale: un abbonamento di lunga durata a `/usr/bin/log stream` in formato ndjson (attesa bloccante anziché polling, quindi un costo CPU quasi nullo a riposo) sorveglia i log di sistema relativi a XProtect.
                • Attivazione: solo quando XProtect registra un rilevamento critico di malware si attiva il contenimento Air-Gap (compresa la disattivazione del Wi-Fi), indipendentemente dal livello di attendibilità della rete.
                • Differenza con Gatekeeper: gli eventi quotidiani di Gatekeeper, come il blocco di una build non firmata dello sviluppatore stesso, generano solo la notifica «Gatekeeper ha impedito l'esecuzione di un'app non firmata».
                • Coerenza: condivide la stessa logica di classificazione dell'Audit registro di sicurezza Mac manuale.
                • Non usando il permesso EndpointSecurity, si tratta di un contenimento immediato dopo il rilevamento, non di un blocco prima dell'esecuzione.
                • Predefinito: si attiva automaticamente alla prima attivazione di Pro (con un avviso unico che la disconnessione automatica è attiva). Lo stato è disponibile tramite lo strumento MCP `get_runtime_threat_status`; provalo con «Simulazione Air-Gap collegata al rilevamento malware (test)».
                """,
                recommendation: "Tienila attiva come difesa automatica collegata al motore anti-malware di Apple stesso. Eseguire spesso le tue app non firmate non la attiverà, perché un semplice blocco di Gatekeeper non interrompe mai la rete."
            ),
            LocalizedEntry(
                id: "feat_clickfix_guard",
                title: "Difesa ClickFix — blocco automatico al rilevamento di comandi Terminale sospetti (Pro, disattivata per impostazione predefinita)",
                summary: "Rileva dalla cronologia della shell la tecnica ClickFix, in cui una falsa pagina di verifica o di errore ti induce a incollare ed eseguire tu stesso un comando, e interrompe la rete per fermare un attacco in più fasi in corso.",
                details: """
                • Sorvegliate: solo le righe aggiunte di recente a `~/.zsh_history` e `~/.bash_history` (la cronologia esistente viene ignorata).
                • Pattern: (1) frasi note di reverse shell (condivise con la verifica di firma statica), e (2) doppia indirezione che incanala contenuto decodificato in Base64 direttamente in una shell o in `osascript`. Un semplice `curl ... | bash`, come quello usato da installer legittimi come Homebrew, non viene deliberatamente segnalato.
                • Risposta: contenimento Air-Gap (il Wi-Fi non viene disattivato), ripristinato automaticamente entro al massimo 10 minuti. La notifica consiglia di controllare il portachiavi, le password salvate nel browser e i tuoi portafogli di criptovalute.
                • Perché a posteriori: quando una riga compare nella cronologia, il comando è già stato eseguito, ma interrompere subito la rete può comunque fermare un secondo download in corso, una connessione reverse shell attiva, o un'esfiltrazione di credenziali in atto.
                • Perché Gatekeeper non può impedirlo: è la tua stessa shell legittima che esegue esattamente ciò che hai digitato, quindi nulla nel processo stesso appare insolito.
                • Complemento: la protezione degli appunti (feat_secret_leak_auditor) intercetta il comando al momento della copia, coprendo gli incollaggi in Editor script, Spotlight, e altri luoghi oltre al Terminale.
                • Disattivata per impostazione predefinita: un'interruzione automatica della rete guidata da un'euristica relativamente nuova, quindi opzionale.
                """,
                recommendation: "Valuta di attivarla se temi di essere ingannato da false pagine di errore o verifiche per eseguire comandi."
            ),
            LocalizedEntry(
                id: "feat_exec_recorder",
                title: "Registrazione dell'esecuzione dei processi (eslogger, solo notifica, Pro, disattivata per impostazione predefinita)",
                summary: "Registra quali programmi si avviano su questo Mac tramite /usr/bin/eslogger di Apple (macOS 13+) e ti avvisa quando un avvio corrisponde a una combinazione sospetta. Non blocca mai un'esecuzione né interrompe la rete; il registro resta su questo Mac.",
                details: """
                • Come funziona: l'helper con privilegi avvia `/usr/bin/eslogger exec fork exit` come processo figlio e analizza il suo flusso JSON. eslogger è incluso in macOS; RoamSwitch non usa né richiede l'entitlement EndpointSecurity, quindi si tratta di osservazione a posteriori, non di blocco prima dell'esecuzione.
                • Requisiti: macOS 13 o successivo e Accesso completo al disco per RoamSwitchHelper. Senza di esso la finestra mostra «Registrazione delle esecuzioni non disponibile: RoamSwitchHelper richiede l'Accesso completo al disco» (o che eslogger non è stato trovato) e non viene fatto altro; non c'è alcun ripiego su un polling continuo. Gli eventi precedenti all'attivazione o all'avvio dell'helper non vengono registrati.
                • Regole di correlazione (solo notifica, silenziose per impostazione predefinita, ciascuna con ID stabile e tecnica MITRE ATT&CK): shell o interprete di script avviato direttamente da un browser, da Office o da un'app di posta (exec.shell_from_app, T1059); binario non firmato o con firma ad hoc eseguito da /tmp, /private/var/tmp o con l'attributo di quarantena (exec.untrusted_location, T1204.002); one-liner `sh -c` che passa curl/wget a una shell con un elemento aggravante come URL con IP grezzo, base64, eval, verifica TLS disabilitata o browser come processo padre (exec.pipe_to_shell, T1059.004); `osascript -e` che combina do shell script con base64/eval (exec.osascript_obfuscated, T1059.002); `xattr -d com.apple.quarantine` seguito dall'esecuzione di quel file entro 15 minuti (exec.quarantine_stripped_then_exec, T1553.001); binario non firmato o ad hoc avviato da launchd da un LaunchAgent/LaunchDaemon scritto nelle ultime 24 ore (exec.launchd_untrusted_binary, T1543.001/.004); `security find-generic-password -w` o `dump-keychain` sotto un antenato che non è una shell né è firmato da Apple (exec.keychain_access, T1555.001). Un semplice `curl | sh` digitato in Terminale non viene segnalato di proposito.
                • Avvisi: una notifica (Pro) più una voce nella cronologia degli incidenti (origine execRecorder, azione «solo notifica»). Un avviso non attiva mai da solo l'air-gap né altri isolamenti.
                • Archiviazione: JSON Lines segmentato in /Library/Application Support/RoamSwitch/exec_log (leggibile solo da root: 0700/0600, perché le righe di comando possono contenere segreti; app, visualizzatore e server MCP leggono solo tramite l’helper privilegiato), 200 MB / 14 giorni per impostazione predefinita (modificabile), rotazione sicura in caso di crash. I segmenti sono concatenati con hash per rilevare segmenti eliminati, modificati o troncati («Verifica catena»); rileva le manomissioni ma non le impedisce. Le variabili d'ambiente non vengono mai registrate, ma gli argomenti della riga di comando possono contenere segreti.
                • Controllo del carico: coda limitata che scarta le righe più vecchie in caso di sovraccarico (contate e mostrate), riavvii con backoff esponenziale; disattivandola, eslogger viene fermato del tutto.
                • Visualizzazione ed esportazione: menu → Protezione dal malware → «Registro di esecuzione dei processi…» (ricerca, albero dei processi, esportazione in JSON Lines). Strumenti MCP `search_exec_events` e `get_process_tree` (Pro, sola lettura).
                """,
                recommendation: "Attivala se vuoi una cronologia delle esecuzioni per l'analisi degli incidenti, concedendo prima l'Accesso completo al disco a RoamSwitchHelper. Considera gli avvisi come indizi da verificare nel registro, non come prova di compromissione."
            ),
            LocalizedEntry(
                id: "feat_persistence_monitor_guard",
                title: "Monitora le nuove registrazioni di avvio automatico (LaunchAgent / LaunchDaemon) (Pro)",
                summary: "Sorveglia in tempo reale le nuove registrazioni di LaunchAgent / LaunchDaemon e ti avvisa quando una di esse avvia direttamente una shell o un interprete di script, oppure registra un eseguibile con una firma non valida.",
                details: """
                • Sorvegliate: `~/Library/LaunchAgents`, `/Library/LaunchAgents` e `/Library/LaunchDaemons` tramite FSEvents (antirimbalzo di circa 1,5 secondi).
                • Criterio: i ladri di informazioni recenti ottengono la persistenza facendo eseguire a un `/bin/bash` o `/usr/bin/osascript` validamente firmato da Apple uno script nascosto in Base64. Poiché la firma dell'interprete stesso è valida, qualsiasi registrazione che avvia un interprete nudo viene trattata come sospetta indipendentemente dalla firma, e i suoi argomenti di script passano anche dalla verifica di firma statica. Vengono segnalati anche eseguibili non firmati o con firma non valida. I wrapper di Homebrew services sono esentati.
                • Solo rilevamento: senza il permesso EndpointSecurity, la scrittura del plist non può essere impedita. Viene valutata e segnalata entro circa 1,5 secondi dalla scrittura.
                • Predefinito: attiva per impostazione predefinita con Pro. Attiva/disattiva sotto Protezione da malware → «Monitora le nuove registrazioni di avvio automatico (LaunchAgent/Daemon) (Pro)».
                """,
                recommendation: "Se ricevi un avviso di registrazione sconosciuta, esamina il plist mostrato nella notifica ed eliminalo se non lo riconosci. Subito dopo l'installazione di un'app legittima, di solito è innocuo."
            ),
            LocalizedEntry(
                id: "feat_docker_event_guard",
                title: "Rileva container Docker privilegiati e mount di docker.sock (Pro, disattivata per impostazione predefinita)",
                summary: "Ti avvisa, all'avvio di un container, di configurazioni Docker rischiose che possono portare a un escape dal container, come container avviati con `--privileged` o con `/var/run/docker.sock` montato.",
                details: """
                • Come: ogni 20 secondi, `docker ps` trova solo i container appena avviati, e `docker inspect` ne verifica le impostazioni. Il formato di rilevamento è identico a quello dell'edizione Linux, così entrambe le piattaforme segnalano le stesse condizioni.
                • Solo notifica: si tratta di una configurazione rischiosa, non di una compromissione confermata (un agente di monitoraggio può essere eseguito privilegiato di proposito), quindi nulla viene bloccato automaticamente.
                • Disattivata per impostazione predefinita: la maggior parte degli utenti non usa Docker, quindi è disattivata anche in Pro.
                • Test: «⚠️ Simulazione di rilevamento rischi Docker (Modalità test)…» verifica il percorso di notifica senza toccare Docker.
                """,
                recommendation: "Se usi Docker per lo sviluppo, attivala per individuare presto i rischi di escape dal container."
            ),
        ]
    }

    // MARK: - Features: audit, monitoring & platform

    private static func featuresItAudit() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_critical_path_fim",
                title: "Monitoraggio manomissione dei file di sistema critici (Critical Path FIM) (Pro)",
                summary: "Registra una base di riferimento SHA-256 di file critici come sudoers, la configurazione SSH, PAM e hosts, che gli aggiornamenti legittimi del sistema o le installazioni di app quasi mai modificano, e ti avvisa di qualsiasi modifica, eliminazione o nuovo file.",
                details: """
                • File: `/etc/sudoers`, `/etc/pam.d/sudo`, `/etc/ssh/sshd_config`, tutto ciò che si trova sotto `/etc/ssh/sshd_config.d/`, `/etc/hosts`, e `~/.ssh/authorized_keys` di root. Sono accessibili solo a root, quindi l'helper privilegiato calcola gli hash.
                • Quando: gli FSEvents su `/etc`, `/etc/pam.d` e `/etc/ssh` attivano una nuova scansione quasi in tempo reale, con una scansione oraria come rete di sicurezza.
                • Base di riferimento: catturata alla prima scansione. Una modifica rilevata non viene mai adottata automaticamente come nuova base di riferimento, così il rilevamento persiste finché un essere umano non lo rivede. Lo stesso stato non viene rinotificato finché l'app resta in esecuzione; qualsiasi ulteriore modifica allerta di nuovo.
                • Avviso di punto cieco: se l'helper non è raggiungibile per 3 scansioni consecutive, ti viene segnalato che il rilevamento delle manomissioni non funziona.
                • Nota: mentre la Protezione link funziona con il ripiego su hosts, RoamSwitch stesso può riscrivere la sua sezione gestita di `/etc/hosts`. I LaunchAgent / Daemon sono coperti da feat_persistence_monitor_guard.
                • Predefinito: si attiva automaticamente alla prima attivazione di Pro. Menu: Protezione da malware → «Monitora periodicamente i file di sistema critici per rilevare manomissioni (Pro)».
                """,
                recommendation: "Quando ricevi un avviso, verifica se hai effettuato tu stesso la modifica (ad esempio `sudo visudo` o una modifica di configurazione). In caso contrario, esamina subito il file e valuta di cambiare la password."
            ),
            LocalizedEntry(
                id: "feat_security_log_audit",
                title: "Audit registro di sicurezza Mac (manuale, rilevamento anomalie modello, copia per consulenza IA)",
                summary: "Estrae dal registro unificato di macOS i fallimenti sudo, le connessioni SSH, i blocchi Gatekeeper, i rilevamenti XProtect e gli eventi di autenticazione, ed elenca anche nuovi pattern di log e picchi di frequenza (anomalie di modello). Disponibile nell'edizione gratuita.",
                details: """
                • Apri: Audit di sicurezza del Mac → «📜 Audit registro di sicurezza Mac…», oppure lo strumento MCP `audit_security_logs`.
                • Periodo: ultime 24 ore, 3 giorni o 7 giorni.
                • Schede riepilogative: fallimenti Sudo, connessioni SSH, blocchi Gatekeeper, rilevamenti XProtect, anomalie di modello. Filtrabile per categoria e ricercabile.
                • Anomalie di modello: le righe di log vengono trasformate in modelli mascherando le parti variabili (indirizzi IP, indirizzi esadecimali, numeri). Fa emergere pattern mai visti su questo Mac ([nuovo]) e picchi ben oltre la loro frequenza abituale ([picco z=…], punteggio z pari o superiore a 3). La frequenza di ogni pattern viene appresa dopo 3 osservazioni, dopodiché un volume normale non allerta più.
                • Verdetto in linguaggio semplice: un assistente basato su regole sul dispositivo riassume il risultato per i non esperti con punti specifici da verificare (nessuna API esterna).
                • Output: «Copia rapporto», «Copia materiali per consulenza IA» (copia una domanda più i log da incollare in Claude, ChatGPT e simili; RoamSwitch non invia nulla), e «Esporta CSV (Pro)».
                """,
                recommendation: "Eseguila quando continuano ad arrivare notifiche sospette o il Mac si comporta in modo strano, e verifica se ci sono rilevamenti XProtect o un aumento dei fallimenti sudo."
            ),
            LocalizedEntry(
                id: "feat_scheduled_log_audit",
                title: "Controllo automatico dei log (apprende nuovi pattern e anomalie di frequenza secondo una pianificazione) (Pro)",
                summary: "Esegue ogni ora, in background, il rilevamento delle anomalie di modello dell'audit dei log, apprendendo continuamente il comportamento normale dei log di questo Mac. Quando trova nuovi pattern o picchi di frequenza, ti avvisa con righe di log reali e una spiegazione in linguaggio semplice.",
                details: """
                • Pianificazione: ogni ora, analizzando l'ultima ora. La prima scansione viene eseguita circa 10 secondi dopo l'attivazione, ma poiché include i log di avvio dell'app stessa, quell'esecuzione si limita ad apprendere senza mai notificare.
                • Notifica: il conteggio delle anomalie (suddiviso in nuovi pattern e picchi), fino a 3 righe di log reali, una nota sul progresso dell'apprendimento, e una spiegazione per i non esperti. Un lotto che include un picco di frequenza mostra un avviso nel Centro Notifiche; un lotto composto solo da nuovi pattern viene registrato nella cronologia delle notifiche senza mostrare alcun avviso. Un nuovo pattern diventa «noto» una volta registrato e non viene più ri-registrato per lo stesso contenuto; un picco smette di allertare non appena viene appresa la base di riferimento propria di quel pattern.
                • Condiviso con l'audit manuale: usa la stessa analisi e la stessa base di riferimento appresa dell'Audit registro di sicurezza Mac manuale e dello strumento MCP `audit_security_logs`.
                • Predefinito: si attiva automaticamente alla prima attivazione di Pro. Menu: Protezione da malware → «Controllo automatico dei log (apprende nuovi pattern e anomalie di frequenza secondo una pianificazione) (Pro)».
                """,
                recommendation: "Aspettati un po' più avvisi di nuovi pattern subito dopo la configurazione; si stabilizzano man mano che l'apprendimento procede. Se un avviso menziona un'app o un IP sconosciuto, apri la finestra di audit dei log per maggiori dettagli."
            ),
            LocalizedEntry(
                id: "feat_containment_incident_timeline",
                title: "Cronologia degli incidenti di contenimento (registro unificato, corrispondenza MITRE ATT&CK)",
                summary: "Salva le quattro risposte automatiche (spoofing ARP, file esca ransomware, interruzione collegata a XProtect, blocco automatico di porta sconosciuta) in un unico registro cronologico sul dispositivo, così puoi rivedere in seguito cosa è successo, cosa è stato fatto e quando è stato risolto.",
                details: """
                • Registrato: ora, origine, gravità, riepilogo, nome del processo e PID (se noto), azione intrapresa, e ora e motivo della risoluzione (rilasciato manualmente, rilasciato automaticamente per timeout, o aggiunto alla lista consentiti).
                • MITRE ATT&CK: un identificatore di tecnica viene aggiunto solo quando la corrispondenza è certa (spoofing ARP = T1557; file esca eliminato o rinominato = T1485; cifratura = T1486; altra manomissione = T1565). Nulla viene indovinato.
                • Archiviazione: `~/Library/Application Support/RoamSwitch/containment_incident_timeline.json` (i 200 più recenti). Non viene mai inviato da nessuna parte.
                • Lo strumento MCP `get_incident_timeline` restituisce questa cronologia unificata (utile per il triage con un'IA locale durante un Air-Gap). La cronologia per singola protezione è disponibile anche tramite `get_canary_status`, `get_port_anomaly_incidents` e `get_runtime_threat_status`.
                """,
                recommendation: "Dopo un'interruzione automatica, esamina questa cronologia insieme alla cronologia delle notifiche per trovare la causa ed evitare che si ripeta."
            ),
            LocalizedEntry(
                id: "feat_notification_history",
                title: "Cronologia notifiche (ultima settimana)",
                summary: "Conserva ogni notifica inviata da RoamSwitch per 7 giorni, così puoi rivedere gli avvisi che hai perso. Anche gli eventi registrati nella cronologia senza banner, come il rilevamento di una firma di test EICAR, appaiono qui. Disponibile nell'edizione gratuita.",
                details: """
                • Apri: Audit di sicurezza del Mac → «🔔 Cronologia notifiche…».
                • Conservazione: 7 giorni; le voci più vecchie vengono rimosse automaticamente ogni volta che ne viene registrata una nuova.
                • Contenuto: ora, titolo e corpo, inclusi gli avvisi di minaccia, gli eventi di connessione della Protezione link, i rilevamenti di ClickFix e chiavi segrete, e le interruzioni automatiche.
                • Firma di test EICAR: il file di test innocuo standard del settore non è una minaccia reale, quindi non viene messo in quarantena né bloccato e non appare alcun banner; viene solo registrato qui. Questo vale allo stesso modo per la protezione dei download, le scansioni rapide e le scansioni pianificate.
                • Un assistente IA può leggerla tramite lo strumento MCP `get_notification_history`.
                """,
                recommendation: "Se hai perso una notifica mentre eri fuori o occupato, controllala qui."
            ),
            LocalizedEntry(
                id: "feat_secret_leak_auditor",
                title: "Protezione degli appunti (avviso di incollaggio chiave API e rimozione dei comandi ClickFix)",
                summary: "Sorveglia gli appunti solo sul dispositivo, avvisa quando è stata copiata una chiave API o una chiave privata così da non incollarla per errore, e svuota automaticamente gli appunti quando copi un comando dannoso che un sito truffaldino vuole farti eseguire (ClickFix). Attiva per impostazione predefinita nell'edizione gratuita.",
                details: """
                • Monitoraggio: controlla le modifiche agli appunti circa una volta al secondo. I contenuti non vengono mai inviati né memorizzati.
                • Chiavi rilevate: chiavi API e token di OpenAI, Anthropic, GitHub, AWS, Hugging Face, Google AI / Gemini, Slack e Stripe, oltre alle chiavi private RSA / SSH. Anche frasi seed di wallet crypto (BIP39) e chiavi private Bitcoin (WIF/BIP32), entrambe verificate tramite checksum per ridurre i falsi positivi.
                • Per le chiavi segrete: solo notifica («Chiave riservata rilevata negli appunti»); gli appunti non vengono svuotati, poiché una chiave trapelata può comunque essere revocata e rinnovata in seguito.
                • Per i comandi ClickFix: notifica («Comando sospetto rilevato negli appunti») e gli appunti vengono svuotati immediatamente, impedendo l'incollaggio ovunque fosse diretto: Terminale, Editor script, Spotlight o altrove. Questo integra feat_clickfix_guard, che sorveglia la cronologia della shell.
                """,
                recommendation: "Dopo aver copiato una chiave API, presta attenzione a dove la incolli, specialmente nelle chat IA e nei moduli web. Se l'hai condivisa per errore, revocala e rinnovala subito."
            ),
            LocalizedEntry(
                id: "feat_secret_leak_audit_tool",
                title: "Verifica manuale delle fughe di segreti / chiavi API (incolla testo o analizza un'intera cartella)",
                summary: "Uno strumento di verifica su richiesta che controlla istantaneamente il testo incollato o analizza una cartella in modo ricorsivo, mostrando numeri di riga, valori mascherati e passaggi di revoca per ogni tipo di chiave. Disponibile nell'edizione gratuita.",
                details: """
                • Apri: Protezione da malware → «🔑 Verifica manuale delle fughe di segreti/chiavi API…», oppure lo strumento MCP `audit_secrets` (con `text` o `path`).
                • Metodo: espressioni regolari più un punteggio di entropia di Shannon. I valori rilevati vengono mostrati mascherati.
                • Analisi cartella: `.git`, `node_modules`, `target`, `vendor`, `dist`, `build`, `__pycache__` e `venv` vengono saltati automaticamente, così come i file oltre 2 MB e i binari.
                • Avviso sui permessi: scegliere una cartella protetta come Scrivania o Download mostra prima un unico avviso che spiega perché è necessario l'accesso e che la scansione è Zero Telemetry, prima della richiesta di macOS.
                • Viene eseguito su un thread in background senza bloccare l'interfaccia. Nulla viene inviato da nessuna parte.
                """,
                recommendation: "Usalo prima di pubblicare un repository o di incollare codice in una chat IA."
            ),
            LocalizedEntry(
                id: "feat_package_cve_scan",
                title: "Verifica CVE dei pacchetti (Homebrew + 7 ecosistemi tra cui npm / PyPI / crates.io, Zero Telemetry)",
                summary: "Confronta i pacchetti Homebrew installati e i file di blocco delle dipendenze nelle cartelle di progetto che scegli con mappe di CVE note conservate sul dispositivo. La scansione stessa non effettua alcuna richiesta di rete. Disponibile nell'edizione gratuita.",
                details: """
                • Apri: Protezione da malware → «📦 Verifica CVE dei pacchetti (Homebrew)…». Per le dipendenze, aggiungi le cartelle di progetto nella scheda Dipendenze.
                • Homebrew: `brew list --versions` viene confrontato con una tabella formula-CPE generata da dati NVD reali. I risultati riportano un livello di fiducia: confirmed (tabella verificata) o gray (corrispondenza di parola chiave non verificata che potrebbe essere un falso positivo).
                • Dipendenze: analizza package-lock.json / requirements.txt / Pipfile.lock / poetry.lock / Cargo.lock / Gemfile.lock / composer.lock / go.sum / pom.xml e li confronta con mappe di CVE note per npm, PyPI, crates.io, RubyGems, Packagist, Go e Maven (da OSV.dev, CVSS 7,0 o superiore).
                • Distribuzione dei dati: le mappe di CVE vengono recuperate una volta al giorno da un manifesto firmato, solo in ricezione. Prima del recupero risultano non ancora scaricate e non rilevano nulla.
                • Strumenti MCP: `run_package_cve_scan` (Homebrew) e `run_package_cve_scan_languages` (dipendenze, argomento `watchedFolders`).
                """,
                recommendation: "Esegui regolarmente la scansione Homebrew, registra i progetti attivi nella scheda Dipendenze, e aggiorna tempestivamente i pacchetti con CVE gravi."
            ),
            LocalizedEntry(
                id: "feat_lockfile_tamper_guard",
                title: "Monitoraggio manomissioni dei lockfile delle dipendenze (Lockfile FIM, Pro)",
                summary: "Monitora continuamente package-lock.json / yarn.lock / pnpm-lock.yaml / npm-shrinkwrap.json tramite una baseline SHA-256, rilevando manomissioni esterne tramite CI o supply chain. Solo Pro.",
                details: """
                • Come aprire: attiva/disattiva dalla voce della barra dei menu «🔔/✅ Monitora periodicamente le manomissioni dei lockfile delle dipendenze (Pro)».
                • File monitorati: le stesse cartelle di progetto registrate nella scheda «Dipendenze» della verifica CVE dei pacchetti — nessun elenco di cartelle separato.
                • Rilevamento: diff della baseline SHA-256 tramite CryptoKit, con rilevamento quasi in tempo reale via FSEvents più una scansione di backup oraria.
                • Urgenza della notifica: se npm/yarn/pnpm è in esecuzione al momento del rilevamento, viene registrato nella cronologia delle notifiche con un avviso silenzioso; altrimenti è un avviso critico normale. Il rilevamento stesso non viene mai saltato in entrambi i casi.
                • Disattivato automaticamente in caso di perdita della licenza Pro.
                """,
                recommendation: "Registra i progetti importanti nella scheda «Dipendenze» della verifica CVE dei pacchetti e lascia questa funzione attiva (predefinita quando Pro è attivo)."
            ),
            LocalizedEntry(
                id: "feat_package_lifecycle_script_scan",
                title: "Elenco degli script di installazione (script del ciclo di vita package.json npm, Pro)",
                summary: "Elenca gli script preinstall/install/postinstall/prepare dichiarati dai file package.json sotto node_modules. Mostra il codice eseguito incondizionatamente durante npm install — non è un verdetto di minaccia. Solo Pro.",
                details: """
                • Come aprire: menu «Protezione da malware» → «📦 Verifica CVE dei pacchetti (Homebrew)…» → scheda «Script di installazione (npm) (Pro)». Analizza le stesse cartelle di progetto della scheda «Dipendenze».
                • Ambito: un livello sotto node_modules (più un livello aggiuntivo per i pacchetti @scope/). Non scende mai nel node_modules proprio di un pacchetto.
                • Segnalazione solo a titolo informativo: i comandi che corrispondono a curl|sh, wget|sh, eval(, base64 -d o node -e ricevono un badge ⚠️ — un'euristica leggera, non un verdetto; anche molti script legittimi (build di moduli nativi, ecc.) corrispondono.
                • Nessuna connessione di rete e non viene mai eseguito nulla — un elenco puramente statico.
                • Strumento MCP: `run_package_lifecycle_script_scan` (argomento `watchedFolders`, solo Pro).
                """,
                recommendation: "Per ogni script contrassegnato con ⚠️, verifica se il pacchetto ne ha davvero bisogno — presta particolare attenzione agli script postinstall di pacchetti poco noti."
            ),
            LocalizedEntry(
                id: "feat_npm_audit_signatures",
                title: "Verifica firme/provenienza npm (npm audit signatures, opt-in, Pro)",
                summary: "Contatta il registro npm per verificare le firme/provenienza dei pacchetti installati. L'unica funzione di RoamSwitch che comunica con npmjs.com — disattivata per impostazione predefinita, richiede attivazione esplicita e conferma a ogni esecuzione. Solo Pro.",
                details: """
                • Come attivarla: l'interruttore «Attiva la verifica delle firme npm» nella scheda «📦 Verifica CVE dei pacchetti» → «Verifica firme npm (opt-in) (Pro)». Questo sblocca solo il pulsante «Esegui audit» per ciascuna cartella di progetto — non invia nulla da solo. Ogni esecuzione viene confermata con «Contattare il registro npm?».
                • Cosa fa: esegue `npm audit signatures` con la cartella indicata come directory di lavoro, contattando il registro npm (registry.npmjs.org). È l'unica funzione di RoamSwitch che comunica con npmjs.com.
                • Output: viene mostrato l'output del comando npm così com'è (mai interpretato autonomamente). Un codice di uscita diverso da zero, o termini come «invalid»/«missing registry signature» nell'output, ricevono un leggero indicatore di attenzione.
                • Se il comando npm non viene trovato, appare un messaggio che invita a installare Node.js/npm.
                • Strumento MCP: `run_npm_audit_signatures` (argomento `directory`, doppio blocco Pro più interruttore opt-in).
                """,
                recommendation: "Attivala solo per un audit delle dipendenze prima del deployment o durante l'indagine su un sospetto compromesso della supply chain — non deve restare sempre attiva."
            ),
            LocalizedEntry(
                id: "feat_npm_sandboxed_install",
                title: "Installazione npm/pnpm in sandbox (roamswitch-npm, Pro)",
                summary: "Un vero wrapper di intervento, non solo rilevamento, che confina esclusivamente l'esecuzione degli script preinstall/install/postinstall/prepare all'interno di una sandbox senza accesso alla rete (sandbox-exec), eseguendo realmente l'installazione per conto vostro. Solo Pro.",
                details: """
                • Come attivarlo: il pulsante «Installa» in «📦 Verifica CVE dei pacchetti» → «Installazione in sandbox (npm/pnpm) (Pro)» posiziona il wrapper da riga di comando `roamswitch-npm` in ~/Library/Application Support/RoamSwitch/bin/.
                • Flusso a due fasi: ① La fase di download esegue `npm install --ignore-scripts` / `pnpm install --ignore-scripts` normalmente, con accesso alla rete. ② La fase degli script esegue `npm rebuild` / `pnpm rebuild` (oltre a `run prepare` se la root ne dichiara uno) sotto un profilo sandbox-exec con `(deny network-outbound)`.
                • Meccanismo della sandbox: la versione Linux utilizza bwrap per limitare il file system; poiché macOS non dispone di una tecnologia equivalente, viene invece utilizzato un blocco di rete, verificato su hardware reale (`(allow default)` + `(deny network-outbound)`). Le letture/scritture di file e l'avvio di processi figli non sono limitati.
                • Alias della shell: è possibile aggiungere al file di configurazione della shell due righe di alias che instradano `npm`/`pnpm` attraverso il wrapper (facoltativo, solo aggiunta — il contenuto esistente non viene modificato).
                • Anteprima: prima dell'esecuzione è possibile elencare gli script del ciclo di vita della cartella di progetto (lo stesso scanner usato da «Elenco degli script di installazione»).
                • Se sandbox-exec non è disponibile o fallisce, non si ricade mai silenziosamente in un'esecuzione senza sandbox. yarn non è supportato. Non esiste uno strumento GTK/MCP: è uno strumento da riga di comando utilizzato da un terminale.
                """,
                recommendation: "Per i progetti che contengono pacchetti sconosciuti, o per i progetti ottenuti da fonti esterne, utilizzare `roamswitch-npm install` al posto di un normale npm/pnpm install."
            ),
            LocalizedEntry(
                id: "feat_typosquat_guard",
                title: "Rilevamento typosquatting (npm/pnpm package.json, Pro)",
                summary: "Confronta i nomi delle dipendenze in package.json con un elenco di pacchetti npm popolari tramite distanza di modifica (Levenshtein 1-2), segnalando un possibile typosquatting come expres→express o loadash→lodash. L'app stessa non stabilisce alcuna connessione di rete per questo controllo. Solo Pro.",
                details: """
                • Ambito: solo le dependencies/devDependencies/optionalDependencies proprie del progetto in package.json (peerDependencies è escluso). Anche node_modules (dipendenze transitive già installate) è deliberatamente escluso — un errore di battitura viene introdotto nel momento in cui una persona aggiunge una dipendenza a package.json.
                • Logica di confronto: un'implementazione DP standard della distanza di Levenshtein confronta ogni nome di dipendenza con un elenco di pacchetti npm popolari. I pacchetti con scope (`@scope/pkg`) vengono confrontati in base al nome base (`pkg`). I candidati la cui lunghezza differisce di più di 2 vengono scartati da un pre-filtro economico. La soglia è una distanza di modifica fino a 2 per nomi popolari di 8 o più caratteri, solo distanza 1 per nomi più brevi.
                • Come l'elenco resta aggiornato: l'elenco dei nomi di pacchetti popolari con cui viene confrontato è distribuito da `PackageCveMapUpdater` tramite lo stesso manifest giornaliero, di sola ricezione e firmato Ed25519 delle mappe CVE (un seed incorporato in fase di build più una sostituzione a due livelli, preferendo quella con `mapVersion` più recente). L'elenco può essere aggiornato senza attendere una nuova release dell'app.
                • Informazione di riferimento, non un verdetto — una whitelist nota sopprime alcuni pacchetti legittimi simili (ad es. preact), ma non è esaustiva.
                • Come aprirlo: scheda «📦 Verifica CVE dei pacchetti» → «Rilevamento typosquatting (Pro)», rivolta alle stesse cartelle di progetto della scheda «Dipendenze». MCP: `run_typosquat_scan` (argomento `watchedFolders`, solo Pro).
                """,
                recommendation: "Ricontrolla ogni dipendenza contrassegnata con ⚠️ per un effettivo errore di battitura — presta particolare attenzione ai nomi di pacchetti sconosciuti."
            ),
            LocalizedEntry(
                id: "feat_port_scan_guard",
                title: "Rilevamento scansioni delle porte in entrata (blocco automatico, Pro)",
                summary: "Rileva un IP di origine che ha contattato molte porte diverse (15 o più) in poco tempo (5 minuti) — la firma classica di strumenti di ricognizione come nmap/masscan — e invia una notifica. Una sorgente di scansione rilevata viene bloccata automaticamente per 10 minuti per impostazione predefinita. Solo Pro.",
                details: """
                • Come funziona: l'helper privilegiato monitora i log di pf (packet filter) tramite `tcpdump -i pflog0` e segnala un IP di origine che raggiunge un numero sufficiente di porte di destinazione diverse in una breve finestra temporale. Il rilevamento si basa esclusivamente sui log; non modifica né ispeziona mai il contenuto del traffico stesso. Corrisponde a `port_scan_detect.rs` dell'edizione Linux (nftables `log` + `journalctl`).
                • Blocco automatico: una sorgente di scansione rilevata viene aggiunta a una regola pf e bloccata per 10 minuti per impostazione predefinita tramite `PFRulesetCoordinator`. Il blocco automatico può essere attivato/disattivato indipendentemente dalla funzione di rilevamento stessa.
                • Notifiche: viene inviata una notifica macOS a ogni rilevamento (e blocco), registrata anche nella cronologia unificata degli incidenti.
                • Come aprirlo: barra dei menu → «Monitoraggio porte e dispositivi» → «🔍 Rilevamento scansioni delle porte in entrata (Pro)». Sia l'attivazione che la disattivazione richiedono una conferma. Disattivato per impostazione predefinita.
                """,
                recommendation: "Non esiste una whitelist per IP e un blocco si annulla automaticamente dopo 10 minuti. Se esegui regolarmente uno strumento di scansione legittimo in casa o al lavoro (inventario risorse, scansione vulnerabilità, ecc.), valuta di disattivare il blocco automatico (mantenendo solo rilevamento/notifica) durante l'esecuzione, per evitare blocchi ripetuti per falsi positivi."
            ),
            LocalizedEntry(
                id: "feat_sensor_pairing",
                title: "Associazione RoamSwitch Sensor (codice di associazione, Pro)",
                summary: "Gestisce l'associazione di fiducia reciproca con un prodotto separato, «RoamSwitch Sensor» (un hub di controllo attivo dedicato), sulla stessa LAN. Usa un flusso di associazione attiva tramite un codice emesso dal Sensor — nessun rilevamento automatico mDNS, poiché si presume che il Sensor operi con un IP fisso. Solo Pro.",
                details: """
                • Come funziona: genera e conserva in modo persistente la propria coppia di chiavi Ed25519 di questo dispositivo. Per associarsi, questo dispositivo si connette al listener TCP del Sensor (porta 50543) con un codice di associazione monouso emesso dall'operatore del Sensor (scade 10 minuti dopo l'emissione), insieme all'indirizzo/nome host di questo dispositivo. Se il codice è valido, il Sensor aggiunge la chiave pubblica di questo dispositivo al proprio elenco di fiducia.
                • Richiesta di un controllo: dopo l'associazione, «Richiedi controllo al Sensor» chiede al Sensor di eseguire un controllo attivo (verifica di raggiungibilità). Poiché il Sensor genera i risultati in modo asincrono, l'helper privilegiato sempre attivo di questo dispositivo interroga il risultato ogni 5 minuti, fino a 5 volte. I risultati ottenuti vengono salvati anche su questo dispositivo e mostrati in «Risultati controllo» nella schermata delle impostazioni.
                • Come aprirlo: barra dei menu → «Monitoraggio porte e dispositivi» → «🔍 Associazione RoamSwitch Sensor…». Mostra la chiave pubblica/indirizzo di questo dispositivo (con pulsante di copia), i Sensor associati (con pulsante Disassocia), un modulo per inserire il codice di associazione e l'elenco dei risultati di controllo.
                • Usa lo stesso protocollo di controllo TCP dell'edizione Linux (`roamswitch-core::sensor_pairing`) — porta 50543, JSON delimitato da a-capo, firme Ed25519.
                • Protezione del trasporto (TLS): l’API di controllo viene raggiunta via TLS 1.3 e il certificato del Sensor è considerato attendibile solo tramite pinning della sua impronta (SHA-256 del certificato; nessuna verifica di CA o nome host). Durante l’associazione digiti a mano l’impronta mostrata sullo schermo del Sensor (non viene mai recuperata via rete). La richiesta di associazione è legata con una firma a quell’impronta e alla chiave di questo dispositivo, quindi un man-in-the-middle con un altro certificato fallisce. Se il Sensor rigenera il certificato (tls rotate), le connessioni vengono rifiutate; ripeti il pinning con «Registra / aggiorna impronta» usando il nuovo valore mostrato sul Sensor (mai automatico). Un Sensor associato prima del pinning continua a usare il testo in chiaro (con un avviso nella finestra); se il TLS fallisce non c’è alcun ripiego automatico sul testo in chiaro.
                """,
                recommendation: "Usa solo un codice di associazione effettivamente emesso dalla schermata operatore di un Sensor configurato da te. Se ti viene chiesto di inserire un codice sconosciuto, non associarti — verifica invece con chi amministra la rete."
            ),
            LocalizedEntry(
                id: "feat_security_health_checker",
                title: "Audit di sicurezza del Mac (18 punti, punteggio e passaggi di correzione)",
                summary: "Verifica 18 punti in sei aree (rafforzamento del sistema, difesa di rete, autenticazione e controllo degli accessi, esposizione delle porte, protezione da malware e difesa fisica dei dispositivi) e mostra un punteggio da 0 a 100, un voto, e i passaggi per correggere ogni punto non superato. Disponibile nell'edizione gratuita.",
                details: """
                • Rafforzamento del sistema: 1. FileVault, 2. SIP (Protezione dell'integrità del sistema), 3. Gatekeeper, 4. aggiornamenti di sicurezza automatici, 5. Apple XProtect.
                • Difesa di rete: 6. firewall di macOS, 7. modalità invisibile, 8. robustezza della cifratura Wi-Fi, 9. monitoraggio spoofing ARP, 10. blocco ARP del gateway.
                • Autenticazione e controllo degli accessi: 11. configurazione dell'accesso SSH remoto (accesso root disattivato, solo autenticazione con chiave), 12. escalation dei privilegi sudo (verifica `NOPASSWD`).
                • Servizi ed esposizione delle porte: 13. porte esposte.
                • Protezione da malware e download: 14. Protezione Web ed e-mail, 15. Protezione dalle minacce DNS, 16. protezione da phishing e link dannosi (avviso di sito fraudolento di Safari).
                • Porte fisiche e dispositivi: 17. Protezione fisica della porta da USB non autorizzato / BadUSB, 18. protezione connessione accessori macOS (Apple Silicon).
                • Non applicabile: firewall e modalità invisibile su una rete attendibile, SSH quando l'accesso remoto è disattivato, la verifica sudo prima della connessione dell'helper, e la protezione degli accessori sui Mac Intel sono esclusi dal punteggio.
                • Voti: 100 = S, 85-99 = A, 70-84 = B, sotto 70 = C. Disponibile anche tramite lo strumento MCP `get_security_report`.
                """,
                recommendation: "Apri regolarmente il rapporto di audit, risolvi i punti contrassegnati con ⚠️ seguendo i passaggi di correzione, e mantieni almeno il voto A."
            ),
            LocalizedEntry(
                id: "feat_autonomous_sentinel",
                title: "Pattugliamento autonomo in background, aggiornamento delle definizioni ClamAV e scansioni pianificate",
                summary: "Ogni 4 ore, aggiorna in background l'audit di sicurezza, le porte, i dispositivi USB e lo stato di XProtect (tutte le edizioni). Pro avvisa inoltre in caso di calo del punteggio, aggiorna automaticamente le definizioni ClamAV, ed esegue una scansione antivirus giornaliera.",
                details: """
                • Audit periodico (tutte le edizioni): circa 30 secondi dopo l'avvio e poi ogni 4 ore, così i risultati restano aggiornati anche se rimani sulla stessa rete per ore.
                • Avviso di calo del punteggio (Pro): notifica quando il punteggio scende sotto 80 o falliscono 4 o più punti.
                • Definizioni ClamAV (Pro): esegue `freshclam` in silenzio.
                • Scansione pianificata (Pro): una volta al giorno, analizza `~/Downloads`, `~/Desktop` e `~/Library/LaunchAgents` con ClamAV. Le minacce vengono messe in quarantena automaticamente con un avviso urgente; un risultato pulito genera solo un discreto avviso di completamento. Se viene trovata solo la firma di test EICAR, non viene mostrato nulla, e viene registrata solo nella cronologia delle notifiche.
                """,
                recommendation: "In Pro, installa ClamAV affinché gli aggiornamenti delle definizioni e le scansioni pianificate vengano eseguiti automaticamente."
            ),
            LocalizedEntry(
                id: "feat_simulation_self_test",
                title: "Strumenti di simulazione (autotest)",
                summary: "Verifica in sicurezza che la difesa contro il ransomware, l'Air-Gap di rilevamento malware e il rilevamento dei rischi Docker funzionino, senza alcun attacco reale né danno ai file.",
                details: """
                • Posizione: in fondo a «Protezione da malware (XProtect e ClamAV)».
                • 🚨 Simulazione difesa ransomware (Modalità test)…: esegue gli stessi passaggi di un tentativo di cifratura rilevato per verificare l'Air-Gap e la finestra di emergenza. Nessun file viene danneggiato.
                • 🚨 Simulazione Air-Gap collegata al rilevamento malware (test)…: esegue gli stessi passaggi di un vero rilevamento XProtect per verificare il contenimento e la finestra di emergenza. L'evento viene etichettato come simulazione.
                • ⚠️ Simulazione di rilevamento rischi Docker (Modalità test)…: verifica che arrivi la notifica di container privilegiato. Docker non viene toccato.
                • Nota: i test Air-Gap interrompono davvero temporaneamente la rete. Rilascia dalla finestra di emergenza (le simulazioni contano come alta affidabilità, quindi non si rilasciano da sole dopo 10 minuti; dopo fino a 1 ora passano alla modalità ridotta).
                • Per testare la protezione dei download puoi usare un file di test EICAR innocuo (nessun banner; viene registrato nella cronologia delle notifiche).
                """,
                recommendation: "Esegui una simulazione una volta dopo aver attivato Pro o modificato le impostazioni per confermare che notifiche e Air-Gap si comportino come previsto."
            ),
            LocalizedEntry(
                id: "feat_privileged_helper",
                title: "Strumento helper privilegiato (RoamSwitchHelper, XPC)",
                summary: "Solo le operazioni che richiedono i permessi root (firewall PF, servizi di condivisione, DNS, Air-Gap, ecc.) vengono eseguite da un helper LaunchDaemon con privilegi separati, tramite XPC.",
                details: """
                • Separazione dei privilegi: l'app principale viene eseguita con permessi utente normali e delega solo le modifiche alle regole pf, il controllo dei demoni di condivisione, le impostazioni DNS, il blocco ARP, l'hashing dei file critici e compiti simili a `RoamSwitchHelper`.
                • Registrazione: registrato tramite lo SMAppService di macOS come LaunchDaemon incluso nell'app. Il primo utilizzo richiede l'approvazione in Impostazioni di Sistema → Generali → Elementi login ed estensioni. Non può essere registrato se l'app non è nella cartella Applicazioni (faq_install_location).
                • Demoni collegati: vengono registrati anche i LaunchDaemon helper per la rete di sicurezza dell'Air-Gap (rilascio automatico dopo 10 minuti con bassa affidabilità, modalità ridotta dopo il limite con alta affidabilità) e la porta di avvio (fino a 90 secondi).
                • Verifica: le firme del codice (Team ID) vengono controllate alle connessioni XPC, rifiutando le chiamate da processi non autorizzati.
                • Nuova approvazione dopo un aggiornamento: l'app tenta automaticamente di passare al nuovo helper, ma macOS può comunque lasciarlo in attesa di approvazione. In tal caso l'icona nella barra dei menu passa a un avviso con «⚠️ È necessaria una nuova approvazione dopo l'aggiornamento», e viene inviata anche una notifica.
                """,
                recommendation: "Approva l'helper quando richiesto al primo avvio. Se non è approvato, il menu mostra «⚠️ Approva il helper…». Se questo avviso o notifica compare dopo un aggiornamento, gli stessi passaggi (Impostazioni di Sistema > Generali > Elementi login ed estensioni) permettono di approvarlo di nuovo."
            ),
            LocalizedEntry(
                id: "feat_mcp_server",
                title: "Integrazione del server MCP (accesso in sola lettura per assistenti IA)",
                summary: "RoamSwitch.app include un server MCP (Model Context Protocol) in sola lettura, così assistenti IA come Claude possono chiedere informazioni sullo stato di sicurezza del tuo Mac. Non esiste alcuno strumento che modifichi le impostazioni o blocchi qualcosa.",
                details: """
                • Trasporto: solo stdio locale. Binario: `/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`.
                • Strumenti principali: `get_security_report` (audit di sicurezza), `get_exposed_ports`, `get_guard_status`, `audit_url_safety`, `audit_secrets`, `audit_security_logs`, `get_quarantine_status`, `get_notification_history`, `get_canary_status`, `get_port_anomaly_incidents`, `get_runtime_threat_status`, `get_incident_timeline` (cronologia degli incidenti di contenimento), `get_network_history` (apprendimento della cronologia di rete), `run_package_cve_scan`, `run_package_cve_scan_languages`, `run_active_vuln_scan` (l'unico strumento che invia traffico, sonde non distruttive solo verso 127.0.0.1), e `get_app_help` (questa base di conoscenza).
                • Registro di esecuzione dei processi (Pro, sola lettura): `search_exec_events` (cerca gli eventi di avvio) e `get_process_tree` (antenati e discendenti di un processo).
                • Risorse: `roamswitch://docs/features`, `roamswitch://docs/alerts-and-messages`, `roamswitch://docs/settings-guide`, `roamswitch://docs/troubleshooting`.
                • Lingua: le risposte seguono l'impostazione della lingua dell'app. `get_app_help` accetta un argomento `language` (ja / en / zh-Hans / zh-Hant / ko / de / fr / es / it / pt-PT).
                • Sicurezza: essendo in sola lettura, nemmeno un'IA manipolata tramite prompt injection può cambiare il livello di protezione o isolare le porte.
                """,
                recommendation: "Per la configurazione, vedi faq_mcp_setup. Puoi fare domande in linguaggio comune, come «Il mio Mac è sicuro in questo momento?» oppure «Cosa significa questa notifica?»"
            ),
            LocalizedEntry(
                id: "feat_license_pro_tier",
                title: "Licenza Pro a vita (acquisto unico, fino a 2 Mac)",
                summary: "Pro è una licenza a vita ad acquisto unico (2.980 ¥ / 19,99 $) utilizzabile su fino a 2 Mac. Il token di licenza firmato con Ed25519 viene verificato sul dispositivo, quindi Pro continua a funzionare offline dopo l'attivazione.",
                details: """
                • Funzioni Pro: le difese automatiche contrassegnate con (Pro) nel menu (rilevamento ransomware tramite file esca, interruzione collegata a XProtect, blocco automatico di porta sconosciuta e isolamento server di sviluppo, blocco automatico spoofing ARP, blocco ARP/NDP del gateway, tunnel VPN, protezioni BadUSB e archiviazione USB, Protezione Web ed e-mail, Protezione dalle minacce DNS, Protezione link, spegnimento automatico Bluetooth, difesa ClickFix, monitoraggio delle registrazioni di avvio automatico, rilevamento rischi Docker, monitoraggio manomissione file critici, controllo automatico dei log), notifiche di minaccia in tempo reale, avvisi di pattugliamento e scansioni pianificate, esportazione CSV dei log, e altro.
                • Tipi di licenza: Pro a vita (2 Mac) e Team a vita (5 Mac).
                • Attivazione: inserisci la tua chiave di licenza (ROAM-XXXX-…) da «💎 Attiva / Acquista Pro…». Il token firmato emesso dal server viene verificato con la chiave pubblica inclusa nell'app e salvato nel portachiavi.
                • Disattivazione: dalla finestra della licenza. Rimuove la licenza da questo Mac e libera il posto sul server (la disattivazione locale avviene sempre anche se la richiesta di rete fallisce).
                • Alla scadenza: le protezioni esclusive Pro vengono disattivate automaticamente, e vengono rilasciati il tunnel VPN e l'isolamento delle porte.
                """,
                recommendation: "Valuta Pro se vuoi contenimento automatico, difesa in tempo reale e avvisi di pattugliamento. Quando sostituisci un Mac, disattivala prima su quello vecchio e poi attivala su quello nuovo."
            ),
        ]
    }

    // MARK: - Alerts: network, devices, links

    private static func alertsItNetwork() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "alert_arp_spoofing",
                title: "⚠️ Allarme spoofing ARP (MITM)",
                summary: "Appare quando ci sono indizi che un dispositivo della tua rete si spaccia per il router (gateway) per intercettare o manomettere il tuo traffico.",
                details: """
                • Causa: un attaccante invia risposte ARP falsificate così il tuo traffico passa da lui (attacco man-in-the-middle). Viene rilevato quando l'IP del gateway resta invariato ma il suo indirizzo MAC cambia improvvisamente. Anche un riavvio del router o un passaggio del Wi-Fi mesh può causarlo.
                • Difesa automatica: con il Blocco massimo e «Blocco automatico al rilevamento di ARP spoofing (impersonificazione di rete) (Pro)» attivo, contenimento Air-Gap immediato. Sugli altri livelli, solo notifica, e il menu mostra «Spoofing ARP rilevato — interrompi ora tutta la rete».
                """,
                recommendation: """
                1. Smetti immediatamente di inserire password, effettuare pagamenti o trasmettere traffico di lavoro su questa rete.
                2. Su Wi-Fi pubblico o una rete sconosciuta, scegli «interrompi ora tutta la rete» nel menu oppure disattiva il Wi-Fi.
                3. Se hai bisogno di accesso a internet, passa a una connessione sicura come il tethering o il tunnel VPN.
                4. Continua a usare la rete solo se sai con certezza che si tratta di un falso positivo, ad esempio subito dopo aver riavviato il router di casa.
                """
            ),
            LocalizedEntry(
                id: "alert_evil_twin_ssid",
                title: "⚠️ Rilevata possibile rete Wi-Fi gemella malvagia",
                summary: "Appare quando il nome (SSID) del Wi-Fi a cui ti sei unito somiglia molto a una rete già usata in precedenza. Potrebbe trattarsi di un punto di accesso falso dannoso (gemello malvagio).",
                details: """
                • Causa: un attaccante configura un punto di accesso falso il cui nome differisce da quello legittimo solo per uno o due caratteri per attirare le persone. L'apprendimento della cronologia di rete (feat_network_history_guard) lo valuta in base alla distanza di modifica rispetto ai nomi appresi e all'hardware gateway diverso.
                • Controllo dei falsi positivi: nomi brevi e SSID aggiuntivi trasmessi dallo stesso hardware gateway non lo attivano.
                • Difesa automatica: solo notifica. Trattandosi di una rete non registrata, si applica il livello di Protezione predefinita fuori sede.
                """,
                recommendation: """
                1. Non accedere né inserire informazioni personali su questo Wi-Fi.
                2. Conferma il nome ufficiale della rete (cartelli nel negozio o in ufficio) e disconnettiti se non corrisponde.
                3. Se devi comunque usarla, connetti il tunnel VPN.
                """
            ),
            LocalizedEntry(
                id: "alert_unencrypted_wifi",
                title: "⚠️ Connesso a un Wi-Fi non cifrato",
                summary: "Appare quando ti unisci a una rete Wi-Fi aperta senza password o cifratura (WPA2 / WPA3), o a una vecchia rete WEP.",
                details: """
                • Causa: il collegamento wireless non è cifrato, quindi chiunque nelle vicinanze può intercettare il traffico.
                • Difesa automatica: se la rete non è registrata, la Protezione predefinita fuori sede (inizialmente Blocco massimo) blocca le connessioni in entrata e i servizi di condivisione.
                """,
                recommendation: """
                1. Se possibile, connetti il tunnel VPN oppure passa a una connessione attendibile come il tethering.
                2. Evita di accedere o inserire informazioni personali su siti che non usano HTTPS.
                3. Conferma nel menu che il livello di protezione sia Blocco massimo.
                """
            ),
            LocalizedEntry(
                id: "alert_port_anomaly",
                title: "🚨 Porta di ascolto sconosciuta bloccata automaticamente",
                summary: "Appare quando un programma prima non esposto ha iniziato a esporre una porta alla LAN su 0.0.0.0 e l'accesso dall'esterno è stato bloccato automaticamente (viene mostrato «Porta di ascolto sconosciuta rilevata (blocco non riuscito)» se il blocco non è andato a buon fine).",
                details: """
                • Causa: l'avvio di un server di sviluppo (Next.js, Vite, Python, Docker), un'app di ricezione LAN come LocalSend o Syncthing avviata per la prima volta, oppure una backdoor o un'app dannosa che inizia ad ascoltare.
                • Difesa automatica: pf blocca solo l'accesso esterno (il Mac stesso e localhost possono continuare a usarla). I demoni di sistema di macOS sono esclusi.
                """,
                recommendation: """
                1. Verifica se riconosci il nome del processo, il PID e la porta mostrati nella notifica (visibili anche in Porte esposte).
                2. Se è un tuo server o un'app di ricezione LAN, consentilo con il pulsante «Consenti» della notifica o dalla schermata di audit delle porte. Resterà consentito in modo permanente da quel momento in poi.
                3. Per i server di sviluppo, riavviare vincolato a `127.0.0.1` è l'opzione più sicura.
                4. Se non lo riconosci, tienilo bloccato, chiudi il processo ed esegui l'audit di sicurezza e una scansione antivirus.
                """
            ),
            LocalizedEntry(
                id: "alert_exposed_database",
                title: "🚨 Servizio di database non autenticato esposto esternamente",
                summary: "Appare quando un servizio spesso privo di autenticazione predefinita (Redis, MongoDB, Memcached, Elasticsearch) risulta esposto alla LAN senza protezione firewall.",
                details: """
                • Causa: un servizio di database o backend è stato avviato su 0.0.0.0 mentre il livello di protezione attuale consente connessioni in entrata. Chiunque sulla stessa rete potrebbe potenzialmente leggere o scrivere i dati.
                • Difesa automatica: solo notifica (Pro), non ripetuta per la stessa porta.
                """,
                recommendation: """
                1. Cambia l'indirizzo di ascolto del servizio in `127.0.0.1` oppure attiva l'autenticazione.
                2. Se non puoi risolvere subito, apri la porta in Porte esposte e scegli «Isola porta».
                3. Usa il Blocco massimo sulle reti pubbliche.
                """
            ),
            LocalizedEntry(
                id: "alert_unapproved_keyboard",
                title: "⚠️ Tastiera non autorizzata / connessione BadUSB rilevata",
                summary: "La notifica e la finestra di approvazione che appaiono quando viene collegata una nuova tastiera USB non presente nella lista consentiti (o un dispositivo che si finge tale, come un cavo modificato) e i tasti premuti vengono bloccati fino all'approvazione.",
                details: """
                • Causa: il collegamento di una nuova tastiera esterna o di una docking station, oppure di un dispositivo di iniezione di tasti come un Rubber Ducky.
                • Difesa automatica: vengono bloccati solo i tasti premuti su quel dispositivo (le altre tastiere continuano a funzionare). La finestra «⚠️ Rilevato dispositivo USB / tastiera sconosciuto» chiede l'approvazione.
                """,
                recommendation: """
                1. Se è una tastiera attendibile che hai collegato tu stesso, fai clic su «Fidati e consenti». Verrà aggiunta alla lista consentiti e l'input verrà attivato.
                2. Se non la riconosci, o appare senza che tu abbia collegato nulla, fai clic su «Rifiuta e mantieni bloccato» e scollega il dispositivo.
                """
            ),
            LocalizedEntry(
                id: "alert_scripted_keyboard",
                title: "🚨 Questa tastiera mostra segni di digitazione automatizzata (scriptata)",
                summary: "Appare quando una tastiera in attesa di approvazione invia tasti premuti a intervalli troppo rapidi e troppo uniformi per un umano. È molto probabile un'iniezione automatizzata di comandi (attacco BadUSB).",
                details: """
                • Causa: un Rubber Ducky, Flipper Zero, Arduino/Digispark o simile ha tentato di digitare comandi precaricati ad alta velocità. Determinato dall'analisi del ritmo di digitazione: dopo almeno 5 intervalli, una media di 12 ms o meno, oppure di 45 ms o meno con un'uniformità molto elevata.
                • Difesa automatica: i tasti premuti dal dispositivo erano già bloccati prima dell'approvazione e non hanno mai raggiunto il Mac. Questo avviso aggiunge solo prove per la tua decisione.
                """,
                recommendation: """
                1. Scegli sempre «Rifiuta e mantieni bloccato» nella finestra di approvazione.
                2. Scollega subito il dispositivo e verifica da dove proviene (una chiavetta USB trovata, un cavo ricevuto in regalo, ecc.).
                3. Come precauzione, esegui l'audit di sicurezza e rivedi le registrazioni di avvio automatico.
                """
            ),
            LocalizedEntry(
                id: "alert_untrusted_usb",
                title: "🔒 Archiviazione USB montata in sola lettura / 🔌 Archiviazione USB non autorizzata bloccata automaticamente",
                summary: "Appare quando un'unità USB o un disco esterno non presente nella lista consentiti viene collegato ed è stato montato in sola lettura in attesa della tua approvazione, oppure è stato espulso.",
                details: """
                • Causa: è stato collegato un dispositivo di archiviazione non registrato. Questo previene il furto di dati e l'introduzione di file dannosi.
                • Difesa automatica: rimontato in sola lettura con la finestra di dialogo «Consentire l'archiviazione USB «…»?». Scegliendo Espelli, il dispositivo viene espulso e viene inviato «Archiviazione USB non autorizzata bloccata automaticamente».
                """,
                recommendation: """
                1. Se è il tuo dispositivo, scegli «Consenti lettura-scrittura» oppure «Consenti in sola lettura». Verrà aggiunto alla lista consentiti e applicato automaticamente la prossima volta.
                2. Se non lo riconosci, scegli «Espelli».
                3. Puoi modificare la lista consentiti in seguito in «Impostazioni protezione USB / BadUSB…».
                """
            ),
            LocalizedEntry(
                id: "alert_malware_usb",
                title: "🚨 Malware rilevato su archiviazione USB",
                summary: "Appare quando la scansione ClamAV eseguita prima di collegare un dispositivo di archiviazione USB in lettura-scrittura trova file infetti.",
                details: """
                • Causa: sono presenti file infetti sull'unità USB.
                • Difesa automatica: il volume viene espulso immediatamente in modo che il Mac non venga infettato.
                """,
                recommendation: """
                1. Formatta o disinfetta l'unità in un ambiente sicuro separato prima di riutilizzarla.
                2. Esegui una scansione rapida o una scansione cartella con ClamAV per assicurarti che il Mac stesso non sia infetto.
                """
            ),
            LocalizedEntry(
                id: "alert_link_guard_blocked",
                title: "🛑 Protezione link: connessione bloccata",
                summary: "Appare quando la Protezione link ha bloccato automaticamente una connessione verso un sito sospettato di truffa o phishing (presente nell'elenco delle minacce, oppure omografo del marchio).",
                details: """
                • Causa: un link da e-mail o social media, una pubblicità, o un'app ha tentato di connettersi a un dominio di truffa noto.
                • Difesa automatica: l'estensione di sistema scarta la connessione, oppure il ripiego su hosts risolve il dominio verso 0.0.0.0, indipendentemente dal browser o dall'app.
                """,
                recommendation: """
                1. Se non era previsto, non serve altro; non inserire informazioni su quella pagina.
                2. Se un sito legittimo di cui hai bisogno è stato bloccato per errore, usa «Consenti una volta (5 min)» nella notifica oppure aggiungilo alla lista consentiti.
                """
            ),
            LocalizedEntry(
                id: "alert_link_guard_warn_hold",
                title: "⚠️ Protezione link: connessione in attesa",
                summary: "In modalità Avviso, la notifica e il pannello in primo piano che appaiono quando una connessione verso un sito sospettato di impersonificazione del marchio o truffa è stata messa in pausa mentre decidi se consentirla.",
                details: """
                • Causa: una connessione verso un dominio che attiva un avviso (impersonificazione di sottodominio, TLD ad alto rischio, ecc.).
                • Difesa automatica: la connessione viene messa in pausa in attesa della tua risposta. Senza risposta entro circa 8 secondi, viene bloccata (fallisce in modo chiuso). Questo risultato non viene memorizzato nella cache, quindi la visita successiva chiederà di nuovo. Le risposte che dai vengono ricordate.
                """,
                recommendation: """
                1. Se l'hai aperta di proposito e ti fidi del sito, scegli «Consenti».
                2. Se non la riconosci o non sei sicuro, scegli «Blocca» oppure aspetta semplicemente (verrà bloccata automaticamente).
                3. Se è stata bloccata per errore, ricarica la pagina per essere richiesto di nuovo.
                """
            ),
            LocalizedEntry(
                id: "alert_dangerous_url",
                title: "🛑 Link pericoloso / phishing sospetto (Verifica sicurezza dei link)",
                summary: "Appare quando la Verifica sicurezza dei link (o `audit_url_safety`) giudica un URL pericoloso a causa di omografi, un sottodominio contraffatto, un TLD ad alto rischio, e simili.",
                details: """
                • Verifiche: caratteri omografi (Punycode), sottodomini che imitano grandi aziende, TLD comuni nel phishing, HTTP non cifrato, indirizzi IP grezzi, e altro ancora.
                • Punteggio: sotto 50 è pericoloso; tra 50 e 79 è cautela.
                """,
                recommendation: """
                1. Non aprire il link.
                2. Elimina il messaggio e segnalalo al tuo team di sicurezza se opportuno.
                """
            ),
            LocalizedEntry(
                id: "alert_helper_disconnected",
                title: "⚠️ Helper non connesso",
                summary: "Appare quando non è possibile stabilire la comunicazione XPC con lo strumento helper privilegiato (RoamSwitchHelper).",
                details: """
                • Causa: l'esecuzione in background non è approvata in Elementi login ed estensioni, l'helper si è arrestato dopo un aggiornamento di macOS, oppure l'app si trova fuori dalla cartella Applicazioni (in Download o dentro l'immagine disco).
                • Impatto: le operazioni che richiedono i permessi root (cambio del livello di protezione, contenimento Air-Gap, impostazioni DNS, monitoraggio dei file critici, ecc.) non possono essere eseguite.
                """,
                recommendation: """
                1. Scegli «⚠️ Approva il helper…» nel menu per aprire i passaggi di approvazione.
                2. In Impostazioni di Sistema → Generali → Elementi login ed estensioni, attiva RoamSwitchHelper sotto Consenti in background.
                3. Assicurati che RoamSwitch sia nella cartella Applicazioni.
                4. Se questo non risolve il problema, segui faq_helper_troubleshooting.
                """
            ),
            LocalizedEntry(
                id: "alert_score_drop",
                title: "⚠️ Avviso di peggioramento della sicurezza del Mac",
                summary: "Inviato dal pattugliamento autonomo quando il punteggio di sicurezza scende sotto 80 o falliscono 4 o più punti (Pro).",
                details: """
                • Causa: una modifica alle impostazioni o all'ambiente, come la disattivazione di FileVault o del firewall, una porta pericolosa esposta, o una protezione arrestata.
                • Criteri: punteggio sotto 80, oppure 4 o più punti falliti.
                """,
                recommendation: """
                1. Apri il rapporto di audit dal menu (oppure usa lo strumento MCP `get_security_report`).
                2. Risolvi i punti contrassegnati con ⚠️ seguendo i passaggi di correzione mostrati.
                """
            ),
        ]
    }

    // MARK: - Alerts: malware, containment, audit

    private static func alertsItMalware() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "alert_quarantined_download",
                title: "🚨 File scaricato pericoloso messo in quarantena",
                summary: "Appare quando un file salvato da un browser, Mail o un'app di chat conteneva una minaccia ed è stato spostato nel caveau di quarantena (viene mostrato «quarantena non riuscita» se lo spostamento non è andato a buon fine).",
                details: """
                • Causa: il file scaricato conteneva malware, un trojan, un reverse shell o simili.
                • Difesa automatica: spostato in `~/Library/Application Support/RoamSwitch/Quarantine/` così non può essere eseguito. Se la verifica di firma statica lo ha segnalato ma ClamAV no, la notifica menziona un possibile falso positivo.
                """,
                recommendation: """
                1. Se la quarantena è riuscita, il file non può essere eseguito.
                2. Apri «📦 Gestisci file in quarantena…» e scegli «Elimina definitivamente» se non lo riconosci.
                3. Usa «Ripristina» o «Escludi e ripristina» solo per falsi positivi certi.
                4. Se la quarantena è fallita, elimina manualmente il file nel percorso indicato dalla notifica.
                """
            ),
            LocalizedEntry(
                id: "alert_eicar_test_signature",
                title: "🧪 Firma di test EICAR rilevata (innocua) — registrata solo nella cronologia delle notifiche",
                summary: "Spiega come viene gestito il file di test EICAR innocuo usato per verificare i software antivirus. Non è una minaccia reale, quindi non appare alcun banner e nulla viene messo in quarantena o bloccato; viene solo registrato nella cronologia delle notifiche.",
                details: """
                • Si applica a: Protezione Web ed e-mail, scansioni rapide/cartella di ClamAV, e la scansione pianificata del pattugliamento allo stesso modo.
                • Comportamento: il file resta dove si trova. «Firma di test EICAR rilevata (innocua)» viene registrata in «🔔 Cronologia notifiche…».
                • Motivo: banner di avviso per elementi che non sono minacce affosserebbero gli avvisi davvero importanti.
                """,
                recommendation: """
                1. Non è necessaria alcuna azione. Se hai posizionato il file a scopo di test, eliminalo dopo aver confermato il risultato.
                2. Puoi confermare che la scansione funziona controllando la presenza di questo record nella cronologia delle notifiche.
                """
            ),
            LocalizedEntry(
                id: "alert_pickle_model",
                title: "⚠️ Rilevato download di un modello IA in formato Pickle",
                summary: "Appare quando viene scaricato un file modello IA `.pkl` / `.pickle` / `.pt`. Il formato Pickle può eseguire codice arbitrario per il solo fatto di essere caricato.",
                details: """
                • Causa: un file modello è stato salvato da Hugging Face, Civitai o simili.
                • Difesa automatica: solo un avviso (il file non viene messo in quarantena).
                """,
                recommendation: """
                1. Non caricare modelli a meno che non provengano da una fonte ufficiale attendibile.
                2. Quando possibile, usa lo stesso modello nel formato `.safetensors` o `.gguf`.
                """
            ),
            LocalizedEntry(
                id: "alert_ransomware_activity",
                title: "🚨 DIFESA AUTOMATICA CRITICA: attività ransomware bloccata",
                summary: "La notifica urgente e la finestra di emergenza che appaiono quando un file esca (canarino) è stato modificato, eliminato o rinominato e sono stati attivati il contenimento Air-Gap, l'arresto della condivisione e la pausa del processo sospetto.",
                details: """
                • Causa: un processo come un ransomware che tenta di cifrare o distruggere file nelle tue cartelle utente (oppure l'esecuzione di una simulazione).
                • Difesa automatica: tutto il traffico interrotto più il Wi-Fi disattivato, SMB / SSH / Condivisione schermo arrestati, e il processo sospetto messo in pausa (SIGSTOP). La finestra di emergenza mostra se l'interruzione è riuscita, il processo sospetto, e i file che potrebbero essere stati interessati.
                """,
                recommendation: """
                1. Salva il lavoro aperto e chiudi tutte le app sospette.
                2. Nel Monitoraggio attività, cerca processi con un uso della CPU o scritture su disco impennati e forza la chiusura di quelli che non riconosci.
                3. Controlla i file che potrebbero essere stati interessati e i tuoi backup (Time Machine, ecc.).
                4. Una volta al sicuro, rilascia il contenimento dalla finestra di emergenza (la rete viene ripristinata, il processo in pausa ripreso, e i file esca rigenerati).
                """
            ),
            LocalizedEntry(
                id: "alert_runtime_threat_airgap",
                title: "🚨 XProtect ha rilevato malware — rete interrotta automaticamente",
                summary: "La finestra di emergenza e la notifica che appaiono quando XProtect / XProtect Remediator di Apple ha condannato un file come malware e la disconnessione automatica collegata a XProtect ha attivato il contenimento Air-Gap.",
                details: """
                • Causa: il motore anti-malware di Apple ha giudicato dannoso un file che hai scaricato o eseguito.
                • Difesa automatica: tutto il traffico interrotto, Wi-Fi disattivato e connessioni già aperte interrotte. Un rilevamento XProtect è ad alta affidabilità, quindi non viene ripristinato dopo 10 minuti: dopo fino a 1 ora di interruzione totale passa a una modalità ridotta (nessuna nuova connessione in uscita) finché non lo rilasci o una nuova verifica conferma che la causa è scomparsa. Vengono registrati il processo rilevante, la categoria e il messaggio di rilevamento di Apple.
                """,
                recommendation: """
                1. Individua i file o le app appena scaricati o eseguiti ed eliminali.
                2. Esegui una scansione ClamAV e l'audit di sicurezza, e controlla le registrazioni di avvio automatico (LaunchAgent) alla ricerca di qualcosa di sospetto.
                3. Una volta al sicuro, rilascia il contenimento dalla finestra di emergenza.
                4. Lo stato è disponibile anche tramite lo strumento MCP `get_runtime_threat_status`.
                """
            ),
            LocalizedEntry(
                id: "alert_gatekeeper_block",
                title: "🛡️ Gatekeeper ha impedito l'esecuzione di un'app non firmata",
                summary: "Una notifica che Gatekeeper di macOS ha impedito l'avvio di un'app senza firma o notarizzazione. Nessuna interruzione automatica.",
                details: """
                • Causa: hai provato ad aprire un'app non firmata proveniente da internet o una tua build di sviluppo.
                • Difesa automatica: nessuna (solo notifica). La disconnessione collegata a XProtect si attiva solo quando XProtect rileva realmente malware.
                """,
                recommendation: """
                1. Se la riconosci (ad esempio una tua build), non è necessaria alcuna azione.
                2. In caso contrario, verifica l'autorità di firma con «Verifica sicurezza file/app…» ed eliminala se sospetta.
                """
            ),
            LocalizedEntry(
                id: "alert_clickfix_command",
                title: "🚨 Rilevata esecuzione di comando sospetto / ⚠️ Comando sospetto rilevato negli appunti",
                summary: "Appare quando un comando corrispondente alla tecnica ClickFix è stato eseguito nel Terminale (rilevato dalla cronologia della shell) oppure copiato negli appunti.",
                details: """
                • Causa: sei stato indirizzato a una falsa verifica o a una falsa pagina di errore che diceva «esegui questo comando per risolvere». Vengono segnalate le frasi di reverse shell e il contenuto decodificato in Base64 incanalato direttamente in una shell o in osascript.
                • Difesa automatica (eseguito nel Terminale, Pro, disattivata per impostazione predefinita): contenimento Air-Gap (il Wi-Fi non viene disattivato), ripristinato automaticamente entro al massimo 10 minuti.
                • Difesa automatica (copiato, attiva per impostazione predefinita): gli appunti vengono svuotati immediatamente.
                """,
                recommendation: """
                1. Se l'hai solo copiato, chiudi quella pagina web e non incollare né eseguire nulla.
                2. Se lo hai eseguito, verifica che il portachiavi, le password salvate nel browser e i tuoi portafogli di criptovalute siano sicuri, e cambia le password importanti da un altro dispositivo attendibile.
                3. Controlla le registrazioni di avvio automatico (LaunchAgent / Daemon) alla ricerca di qualcosa di sospetto ed esegui una scansione ClamAV.
                """
            ),
            LocalizedEntry(
                id: "alert_new_persistence_item",
                title: "🚨 Rilevata nuova registrazione di avvio automatico",
                summary: "Appare quando un nuovo LaunchAgent / LaunchDaemon è stato registrato ed è stato giudicato sospetto (avvia direttamente un interprete di script, ha una firma non valida, ecc.).",
                details: """
                • Causa: malware come un ladro di informazioni che si registra per sopravvivere ai riavvii, oppure un installer di app che ne aggiunge uno.
                • Difesa automatica: solo notifica (la registrazione stessa non può essere impedita). La notifica mostra il percorso del plist e il motivo.
                """,
                recommendation: """
                1. Verifica se hai appena installato tu stesso un'app. In tal caso, non è necessaria alcuna azione.
                2. In caso contrario, elimina il plist mostrato nella notifica e lo script o l'app che avvia.
                3. Riavvia poi il Mac ed esegui una scansione ClamAV.
                """
            ),
            LocalizedEntry(
                id: "alert_docker_risk",
                title: "⚠️ Rilevata configurazione di container Docker rischiosa",
                summary: "Ti avvisa che è appena stato avviato un container con `--privileged` oppure con `docker.sock` montato.",
                details: """
                • Causa: i container privilegiati e i mount del socket Docker permettono a un container di controllare l'host, creando un rischio di escape dal container.
                • Difesa automatica: nessuna (solo notifica).
                """,
                recommendation: """
                1. Se è intenzionale (ad esempio un agente di monitoraggio), non è necessaria alcuna azione.
                2. In caso contrario, verifica il container con `docker ps` e `docker inspect` e fermalo.
                """
            ),
            LocalizedEntry(
                id: "alert_critical_file_tampering",
                title: "🚨 Rilevata manomissione di un file di sistema critico",
                summary: "Appare quando viene rilevata una modifica, un'eliminazione o un nuovo file tra file critici come sudoers, la configurazione SSH, PAM, hosts, o l'authorized_keys di root.",
                details: """
                • Causa: una modifica di configurazione da parte di un amministratore (`sudo visudo`, modifica delle impostazioni SSH), una modifica effettuata da software, oppure un attaccante che eleva i privilegi o installa una backdoor.
                • Difesa automatica: solo notifica. Il nuovo stato non viene mai accettato automaticamente come legittimo.
                • Correlato: «Il rilevamento della manomissione dei file critici non funziona» significa che le scansioni sono fallite ripetutamente perché non è stato possibile contattare l'helper privilegiato.
                """,
                recommendation: """
                1. Verifica se tu o un amministratore avete modificato i file mostrati nella notifica.
                2. In caso contrario, cerca voci `NOPASSWD` in `/etc/sudoers`, chiavi sconosciute in `authorized_keys` e simili, e rimuovile.
                3. Cambia la password amministratore ed esegui l'audit di sicurezza.
                """
            ),
            LocalizedEntry(
                id: "alert_log_audit_anomaly",
                title: "🔔 Audit dei log: rilevati pattern anomali",
                summary: "Inviato dal controllo automatico dei log quando trova pattern di log mai visti su questo Mac ([nuovo]) oppure log molto più frequenti del solito ([picco z=…]).",
                details: """
                • Causa: solitamente cambiamenti attesi dovuti al collegamento di un nuovo dispositivo o ad aggiornamenti di app o di macOS, ma a volte tentativi di accesso sospetti o attività di processi sconosciuti.
                • Contenuto: la ripartizione del conteggio, fino a 3 righe di log reali, il progresso dell'apprendimento (ad esempio apprendimento della frequenza in corso: 2/3 osservazioni), e una spiegazione in linguaggio semplice.
                • Difesa automatica: nessuna (solo notifica).
                """,
                recommendation: """
                1. Se ci sono solo nuovi pattern senza nomi di app o indirizzi IP sconosciuti, non è necessaria alcuna azione.
                2. Se un picco di frequenza coincide con qualcosa che non hai fatto, apri «📜 Audit registro di sicurezza Mac…» per maggiori dettagli.
                3. In caso di dubbio, usa «Copia materiali per consulenza IA» per chiedere a un assistente IA.
                """
            ),
            LocalizedEntry(
                id: "alert_secret_in_clipboard",
                title: "🔑 Chiave riservata rilevata negli appunti",
                summary: "Ti informa che una chiave API o una chiave privata (OpenAI, Anthropic, GitHub, AWS, ecc.) si trova negli appunti.",
                details: """
                • Causa: hai copiato una chiave API, un token o una chiave privata.
                • Difesa automatica: solo notifica (gli appunti non vengono svuotati).
                """,
                recommendation: """
                1. Fai attenzione a non incollarla per errore in un sito web o in una chat IA.
                2. Al termine, copia un altro testo per sovrascriverla.
                3. Se l'hai condivisa per errore, revocala e rinnovala subito nella console del servizio.
                """
            ),
            LocalizedEntry(
                id: "alert_airgap_failed",
                title: "🚨 Interruzione automatica della rete non riuscita",
                summary: "Un avviso urgente che appare quando è stata tentata un'interruzione di emergenza (ransomware, spoofing ARP, rilevamento XProtect, ClickFix, ecc.) ma non è stato possibile applicare il blocco completo di pf.",
                details: """
                • Causa: l'helper privilegiato non ha risposto (non approvato, arrestato, o timeout scaduto). Appare dopo 3 tentativi falliti.
                • Stato attuale: il traffico in entrata potrebbe essere bloccato dal firewall applicativo, ma il traffico in uscita non è stato fermato.
                """,
                recommendation: """
                1. Disattiva subito il Wi-Fi oppure scollega il cavo di rete.
                2. Gestisci la minaccia (chiudi i processi, esegui scansioni).
                3. Verifica poi lo stato dell'helper (faq_helper_troubleshooting).
                """
            ),
        ]
    }

    // MARK: - Settings

    private static func settingsIt() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "set_trusted_networks",
                title: "Reti registrate e livelli di protezione per rete",
                summary: "Registra la rete attuale come Casa, Lavoro, Tethering, ecc., e imposta il livello di protezione di ogni rete (Attendibile / Bilanciato / Blocco massimo).",
                details: """
                • Registra: Registra rete attuale → Registra come «Casa» (Attendibile) / Registra come 'Lavoro' (Bilanciato) / Registra come 'Tethering' (Bilanciato) / Registra con nome personalizzato…. Le reti vengono identificate dall'indirizzo MAC del gateway.
                • Cambia livello: scegli la rete sotto «Rete attuale: …» oppure «Reti registrate (n)» e scegli 🟢 / 🟡 / 🔴.
                • Rinomina o rimuovi: Rinomina…, Annulla registrazione, oppure Elimina.
                """,
                recommendation: "Casa come 🟢 Attendibile e Lavoro o Tethering come 🟡 Bilanciato funzionano bene. È più sicuro lasciare non registrato un Wi-Fi da ufficio condiviso, mantenendolo sotto Blocco massimo."
            ),
            LocalizedEntry(
                id: "set_away_default_level",
                title: "Protezione predefinita fuori sede (livello per le reti non registrate)",
                summary: "Sceglie il livello di protezione applicato automaticamente quando ti unisci a una rete che non hai registrato. Inizialmente 🔴 Blocco massimo.",
                details: """
                • Impostazione: «Protezione predefinita fuori sede: …» nel menu, poi 🟢 Attendibile / 🟡 Bilanciato / 🔴 Blocco massimo.
                • Influisce anche sulle funzioni condizionate dall'essere su una rete non attendibile, come la Protezione dalle minacce DNS (solo fuori sede), la connessione automatica VPN, il blocco ARP/NDP del gateway, e lo spegnimento automatico del Bluetooth.
                """,
                recommendation: "Se non usi servizi di condivisione o AirDrop fuori sede, è vivamente consigliato lasciarlo su Blocco massimo."
            ),
            LocalizedEntry(
                id: "set_manual_override",
                title: "Override manuale e protezione dal dimenticare di ripristinare",
                summary: "Imposta temporaneamente a mano un livello di protezione per una durata scelta. Torna al rilevamento automatico allo scadere del tempo o al cambio di rete, così non dimentichi di ripristinare la protezione.",
                details: """
                • Impostazione: Override manuale → un livello (🟢 / 🟡 / 🔴) → una durata.
                • Durate: Fino alla disconnessione (Consigliato), Per 1 ora, Per 4 ore, Fino all'annullamento manuale.
                • Annulla: Override manuale → Torna al rilevamento automatico, oppure «🔄 Rimuovi override manuale (Auto)» in alto nel menu.
                • Rilasciare un contenimento Air-Gap annulla anche qualsiasi override manuale.
                """,
                recommendation: "Quando allenti temporaneamente la protezione per una presentazione o un lavoro di sviluppo, usa Fino alla disconnessione o Per 1 ora così da non restare mai senza protezione fuori sede."
            ),
            LocalizedEntry(
                id: "set_pro_default_guards",
                title: "Protezioni attivate automaticamente con Pro, e protezioni opzionali",
                summary: "Alla prima attivazione di una licenza Pro, le principali protezioni di difesa autonoma vengono attivate automaticamente. In seguito, viene rispettata la scelta di attivazione/disattivazione che fai per ogni protezione.",
                details: """
                • Attivate automaticamente (una volta, alla prima attivazione di Pro): blocco automatico delle porte di ascolto sconosciute, rilevamento ransomware tramite file esca, blocco automatico al rilevamento di spoofing ARP, disconnessione automatica al rilevamento di malware da XProtect, controllo automatico dei log, e monitoraggio periodico della manomissione dei file di sistema critici. Quando vengono attivate le interruzioni ARP e XProtect, appare un avviso unico che lo spiega.
                • Attive per impostazione predefinita con Pro: Protezione Web ed e-mail, e monitoraggio delle registrazioni di avvio automatico (LaunchAgent/Daemon).
                • Disattivate per impostazione predefinita (opzionali): blocco automatico ClickFix, rilevamento rischi Docker, protezione fisica della porta BadUSB, blocco automatico dell'archiviazione USB, blocco ARP/NDP del gateway, tunnel VPN, spegnimento automatico Bluetooth, e verifica attiva delle vulnerabilità. Il provider della Protezione dalle minacce DNS è una tua scelta.
                • Attiva per impostazione predefinita anche nell'edizione gratuita: protezione degli appunti (chiavi API e comandi ClickFix).
                • Le protezioni aggiunte nelle versioni successive ricevono il proprio valore predefinito, una sola volta, per gli utenti Pro esistenti. Se la licenza scade, le protezioni esclusive Pro vengono disattivate.
                """,
                recommendation: "Dopo aver attivato Pro, controlla i segni di spunta ✅ nel menu. Lascia disattivate le protezioni che non si adattano al tuo uso (ad esempio Docker se non lo usi), e attiva ciò di cui hai bisogno (ad esempio la VPN se usi spesso il Wi-Fi pubblico)."
            ),
            LocalizedEntry(
                id: "set_usb_whitelist",
                title: "Impostazioni protezione USB / BadUSB (lista consentiti tastiere e permessi di archiviazione) (Pro)",
                summary: "Gestisci tastiere attendibili e dispositivi di archiviazione USB di lavoro in liste consentiti, e imposta il permesso di archiviazione su Sola lettura o Lettura-scrittura.",
                details: """
                • Apri: «Monitoraggio porte e dispositivi» → «Impostazioni protezione USB / BadUSB…».
                • Tastiere: vengono aggiunte quando scegli «Fidati e consenti» nella finestra di approvazione; possono essere rimosse qui.
                • Archiviazione: viene aggiunta quando scegli «Consenti lettura-scrittura» oppure «Consenti in sola lettura» nella finestra di dialogo di connessione; qui puoi cambiare il permesso o rimuoverla. Se modifichi un dispositivo non collegato, scollegalo e ricollegalo perché la modifica venga applicata.
                • La scansione ClamAV alla connessione continua a essere eseguita per i dispositivi consentiti prima che vengano collegati in lettura-scrittura.
                """,
                recommendation: "Sui Mac che gestiscono dati sensibili, registrare l'archiviazione come Sola lettura riduce notevolmente il rischio di fughe di dati."
            ),
            LocalizedEntry(
                id: "set_watched_folders",
                title: "Cartelle monitorate dalla Protezione Web ed e-mail (Pro)",
                summary: "Aggiungi, rimuovi o ripristina le cartelle monitorate dalla protezione dei download (sorveglianza FSEvents e scansioni automatiche).",
                details: """
                • Cartelle predefinite: `~/Downloads`, `~/Desktop`, `~/Documents`, e la cartella di download di Mail.
                • Modifica: «Protezione Web ed e-mail (Scansione automatica download) (Pro)» → «📁 Cartelle monitorate» → «⚙️ Gestisci cartelle monitorate…».
                • Ripristina: «🔄 Ripristina predefiniti».
                • La cronologia recente delle scansioni (fino a 5 mostrate) e «Cancella cronologia scansioni» si trovano nello stesso menu.
                """,
                recommendation: "Se hai cambiato dove il tuo browser o le tue app di chat salvano i file, assicurati di aggiungere quella cartella."
            ),
            LocalizedEntry(
                id: "set_dns_policy",
                title: "Provider e criterio della Protezione dalle minacce DNS (Pro)",
                summary: "Scegli il provider DNS sicuro che blocca i domini dannosi, e quando si applica (solo fuori sede / sempre).",
                details: """
                • Impostazione: «Protezione dalle minacce DNS (Blocca malware e C2) (Pro)» → «Provider DNS: …» e «⚙️ Criterio di applicazione».
                • Provider: Quad9 (Blocco automatico malware e C2) / Cloudflare Security (1.1.1.2) / AdGuard DNS (Blocca minacce e pubblicità) / CleanBrowsing (Filtro di sicurezza).
                • Criterio: «Solo su Wi-Fi non attendibile (Consigliato)» oppure «Sempre attivo su tutte le reti (comprese quelle attendibili)». Con l'opzione solo fuori sede, sulle reti attendibili vengono ripristinate le impostazioni DNS originali.
                • L'elemento di stato nel menu apre le impostazioni di rete così puoi confermare cosa viene applicato.
                """,
                recommendation: "Per la maggior parte delle persone, Quad9 con il criterio riservato a fuori sede è una buona scelta. Evita il criterio sempre attivo se hai bisogno di un DNS interno aziendale."
            ),
            LocalizedEntry(
                id: "set_link_guard_modes",
                title: "Modalità, aggiornamento automatico, estensione di sistema e lista consentiti della Protezione link (Pro)",
                summary: "Configura la modalità della Protezione link, l'aggiornamento automatico dell'elenco delle minacce, lo stato di approvazione dell'estensione di sistema, e come consentire i siti bloccati per errore.",
                details: """
                • Modalità: «Protezione link (rilevamento connessioni di phishing) (Pro)» → «Disattivata», «Solo avvisa (mai bloccare)», oppure «Blocca automaticamente i siti di phishing evidenti (consigliato)». La modalità Avviso funziona solo quando l'estensione di sistema è attiva.
                • Aggiornamento automatico: fai clic su «Aggiornamento automatico: attivo (solo ricezione)» per disattivarlo. Continua a funzionare con i dati inclusi e il rilevamento degli omografi. La versione dell'elenco e il numero di domini vengono mostrati nel menu.
                • Punto di applicazione: «Applicazione: estensione di sistema (compatibile DoH)», «Applicazione: ripiego su hosts», «Attivazione dell'estensione di sistema…», oppure un errore dell'estensione di sistema. Mentre l'approvazione è in sospeso, appare «Approva l'estensione di sistema (apri Impostazioni di Sistema)…».
                • Consenti/blocca: «Consenti una volta (5 min)» su una notifica di blocco consente il sito per 5 minuti. Le scelte Consenti/Blocca nel pannello di avviso vengono ricordate.
                """,
                recommendation: "Approva l'estensione di sistema e usa il blocco automatico con l'aggiornamento automatico attivo per la protezione più efficace."
            ),
            LocalizedEntry(
                id: "set_vpn_backend",
                title: "Impostazioni backend del tunnel VPN (WireGuard / Tailscale) (Pro)",
                summary: "Scegli il backend del tunnel VPN, importa una configurazione WireGuard, seleziona un exit node Tailscale, e configura il kill switch.",
                details: """
                • Apri: «Monitoraggio porte e dispositivi» → «Tunnel VPN (anti-MITM su reti non attendibili) (Pro)» → «Backend».
                • WireGuard: «Importa config WireGuard (.conf)…» → «Connessione automatica su reti non attendibili». Inoltre «Connetti ora», «Disconnetti» e «Rimuovi config». Lo stato mostra ad esempio «🟢 Connesso (ultimo handshake N s fa)», e il kill switch è sempre attivo. Se manca `wireguard-tools`, appaiono istruzioni di installazione.
                • Tailscale: scegli un nodo sotto «Exit-Node» («(nessuno — protezione disattivata)» per disattivarlo). Inoltre «Aggiorna candidati» e «Aggiorna stato». «Kill-switch: attivo (anti-fuga)» è opzionale e disattivato per impostazione predefinita.
                • Esempi di righe di stato: «⚪️ In attesa (connessione automatica su reti non attendibili)», «🟡 Il nodo di uscita selezionato è offline».
                """,
                recommendation: "Se usi già Tailscale, scegli Tailscale; altrimenti la configurazione WireGuard del tuo provider VPN è l'opzione più semplice."
            ),
            LocalizedEntry(
                id: "set_language",
                title: "Lingua di visualizzazione (risposte dell'app e di MCP)",
                summary: "RoamSwitch può essere visualizzato in 10 lingue (日本語, English, 简体中文, 繁體中文, 한국어, Deutsch, Français, Español, Italiano, Português). Le risposte del server MCP e questa base di conoscenza usano la stessa lingua.",
                details: """
                • Impostazione: scegli nel menu sotto «Lingua / Language». «Segui impostazioni di sistema» usa la lingua preferita di macOS.
                • MCP: il server MCP legge la lingua scelta nell'app. Se segue il sistema e la lingua di sistema non è supportata, risponde in inglese.
                • Lo strumento `get_app_help` accetta un argomento `language` per scegliere la lingua di risposta a ogni chiamata. Le ricerche trovano corrispondenze di parole chiave in qualsiasi lingua.
                """,
                recommendation: "Per parlare con il tuo assistente IA in una lingua diversa da quella dell'app, usa l'argomento `language` di `get_app_help`."
            ),
        ]
    }

    // MARK: - Troubleshooting: setup

    private static func troubleshootingItSetup() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "faq_free_vs_pro",
                title: "Differenza tra l'edizione gratuita e la versione Pro a vita",
                summary: "L'edizione gratuita include, senza limiti di tempo, il cambio automatico della protezione in base alla rete, l'audit di sicurezza a 18 punti, e una serie di strumenti di verifica manuale. Pro sblocca il contenimento automatico, le difese in tempo reale e gli avvisi di pattugliamento.",
                details: """
                [Gratis]
                • Cambio automatico del filtro pacchetti PF a 3 livelli per rete, con servizi di condivisione e AirDrop arrestati e ripristinati automaticamente
                • Audit di sicurezza del Mac (18 punti), stato di XProtect, e verifica sicurezza file/app
                • Elenchi delle porte esposte e dei dispositivi USB
                • Verifica sicurezza dei link, verifica manuale delle fughe di segreti/chiavi API, protezione degli appunti
                • Verifica CVE dei pacchetti, verifica attiva delle vulnerabilità, Audit registro di sicurezza Mac, cronologia notifiche
                • Scansioni manuali ClamAV e gestione della quarantena
                • Integrazione del server MCP
                [Pro a vita (acquisto unico 2.980 ¥ / 19,99 $, fino a 2 Mac)]
                • Rilevamento ransomware tramite file esca con Air-Gap, interruzione automatica collegata a XProtect, difesa ClickFix
                • Blocco automatico delle porte di ascolto sconosciute, isolamento dei server di sviluppo
                • Blocco automatico dello spoofing ARP, blocco ARP/NDP del gateway, tunnel VPN (WireGuard / Tailscale), avvisi di gemello malvagio
                • Protezione tastiera BadUSB, blocco automatico dell'archiviazione USB
                • Protezione Web ed e-mail (scansione automatica, quarantena, avvisi Pickle), Protezione dalle minacce DNS, Protezione link
                • Monitoraggio delle registrazioni di avvio automatico, rilevamento rischi Docker, monitoraggio manomissione file critici, controllo automatico dei log
                • Spegnimento automatico Bluetooth, notifiche di minaccia in tempo reale, avvisi di pattugliamento, aggiornamenti delle definizioni e scansioni pianificate, esportazione CSV dei log
                """,
                recommendation: "Scegli Pro se hai bisogno di contenimento automatico, difesa in tempo reale e monitoraggio in background."
            ),
            LocalizedEntry(
                id: "faq_homebrew_clamav",
                title: "Configurare ClamAV (scansione antivirus) e Homebrew",
                summary: "La scansione antivirus usa ClamAV, un software open source installabile con Homebrew. Senza di esso, l'integrazione con XProtect e tutte le funzioni proprie di RoamSwitch continuano a funzionare.",
                details: """
                • Homebrew: il gestore di pacchetti per macOS (https://brew.sh/).
                • Passaggi:
                  1. Esegui nel Terminale il comando ufficiale di installazione di Homebrew (indicato su https://brew.sh/).
                  2. Esegui `brew install clamav`. «📥 Installa ClamAV tramite Homebrew…» nel menu apre anche le istruzioni.
                  3. Scegli «🛡️ ClamAV (Antivirus gratuito)» → «🔄 Aggiorna database virus adesso».
                • Attivati da ClamAV: scansione rapida (Download/Scrivania), scansione cartella, scansioni nella Protezione Web ed e-mail e per l'archiviazione USB, e la scansione pianificata del pattugliamento.
                • Senza ClamAV: il filtraggio dei pacchetti, il monitoraggio delle porte, l'analisi dei link, la verifica della firma statica e altro continuano a funzionare.
                """,
                recommendation: "Installa Homebrew e ClamAV se vuoi che download e archiviazione USB vengano scansionati automaticamente."
            ),
            LocalizedEntry(
                id: "faq_blueutil_setup",
                title: "Spegnimento automatico del Bluetooth (Pro) e configurazione di blueutil",
                summary: "Disattivare automaticamente il Bluetooth fuori sede richiede lo strumento open source `blueutil`.",
                details: """
                • Contesto: macOS non offre un'API pubblica perché le app attivino/disattivino l'alimentazione del Bluetooth, quindi viene usato lo strumento a riga di comando `blueutil`.
                • Passaggi:
                  1. Esegui `brew install blueutil` nel Terminale (oppure usa «📥 Installa blueutil tramite Homebrew…» nel menu).
                  2. Attiva «Monitoraggio porte e dispositivi» → «Spegnimento automatico Bluetooth su reti non attendibili (Pro)».
                • Se non installato: nient'altro viene influenzato, e il menu mostra «🔵 Spegnimento automatico Bluetooth (non installato)».
                """,
                recommendation: "Per evitare il tracciamento radio e le vulnerabilità Bluetooth sul Wi-Fi pubblico, esegui `brew install blueutil` e attivala."
            ),
            LocalizedEntry(
                id: "faq_helper_troubleshooting",
                title: "Cosa fare quando appare «⚠️ Helper non connesso»",
                summary: "Passaggi di ripristino quando RoamSwitch non riesce a comunicare con lo strumento helper privilegiato (RoamSwitchHelper).",
                details: """
                1. Scegli «⚠️ Approva il helper…» nel menu e segui i passaggi mostrati.
                2. Apri Impostazioni di Sistema → Generali → Elementi login ed estensioni e assicurati che RoamSwitchHelper sia attivo sotto Consenti in background.
                3. Assicurati che RoamSwitch sia nella cartella Applicazioni (faq_install_location).
                4. Premi «Riprova la registrazione del helper» nella finestra di benvenuto.
                5. Se continua a fallire, esegui `sudo killall RoamSwitchHelper` nel Terminale per riavviare l'helper (launchd lo rilancia automaticamente), poi riavvia RoamSwitch.
                """,
                recommendation: "Se l'helper smette di rispondere subito dopo un aggiornamento di macOS, controlla prima l'interruttore degli Elementi login, poi prova `sudo killall RoamSwitchHelper`."
            ),
            LocalizedEntry(
                id: "faq_install_location",
                title: "Posizione dell'app (avviata al di fuori della cartella Applicazioni)",
                summary: "macOS non registra l'helper privilegiato per un'app che si trova al di fuori della cartella Applicazioni, quindi RoamSwitch deve essere posizionato in `/Applications` o `~/Applications` e avviato da lì.",
                details: """
                • Posizioni che non consentono la registrazione: Download o Scrivania, esecuzione da un'immagine disco (.dmg) ancora montata, oppure quando Gatekeeper App Translocation ha spostato l'app in una posizione temporanea di sola lettura.
                • Guida: la procedura di benvenuto controlla la posizione all'avvio e propone «Sposta in Applicazioni e riavvia» oppure «Apri Applicazioni nel Finder».
                • Dopo lo spostamento: premi «Controlla di nuovo» oppure riavvia, poi approva l'helper.
                """,
                recommendation: "Trascina RoamSwitch dall'immagine disco nella cartella Applicazioni e avvialo da lì."
            ),
            LocalizedEntry(
                id: "faq_system_extension_approval",
                title: "Approvare l'estensione di sistema della Protezione link",
                summary: "Perché la Protezione link funzioni al meglio (compatibile DoH, modalità Avviso), l'estensione di sistema per il filtraggio dei contenuti deve essere approvata. Fino ad allora usa il ripiego su /etc/hosts.",
                details: """
                • Passaggi: «Protezione link (rilevamento connessioni di phishing) (Pro)» → «Approva l'estensione di sistema (apri Impostazioni di Sistema)…» → Impostazioni di Sistema → Generali → Elementi login ed estensioni, poi consenti l'estensione di rete di RoamSwitch.
                • Dopo l'approvazione: il menu mostra «Applicazione: estensione di sistema (compatibile DoH)».
                • Se appare un errore dell'estensione di sistema: assicurati che l'app sia nella cartella Applicazioni, poi riseleziona una modalità della Protezione link per riprovare.
                • Questo metodo non richiede revisione dell'App Store né richiesta di permessi aggiuntivi (firmata con Developer ID e notarizzata).
                """,
                recommendation: "Approva l'estensione di sistema così la protezione resta valida anche quando il tuo browser usa DNS su HTTPS."
            ),
            LocalizedEntry(
                id: "faq_mcp_setup",
                title: "Configurare il server MCP (Claude Desktop, Claude Code e altri)",
                summary: "Come registrare il server MCP incluso in RoamSwitch con un client IA compatibile con MCP.",
                details: """
                • Percorso del binario: `/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`
                • Claude Desktop: aggiungi il percorso del binario come `command` sotto `mcpServers` in `~/Library/Application Support/Claude/claude_desktop_config.json`.
                • Claude Code: `claude mcp add roamswitch /Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`
                • Altri client (Codex CLI e altri): https://lafine.net/mcp-setup.html
                • Lingua di risposta: segue l'impostazione «Lingua / Language» dell'app. `get_app_help` accetta un argomento `language` per chiamata.
                • La comunicazione avviene solo tramite stdio locale, senza inviare nulla all'esterno (solo `run_active_vuln_scan` invia sonde non distruttive verso 127.0.0.1).
                """,
                recommendation: "Una volta registrato, chiedi alla tua IA qualcosa come «Verifica lo stato di sicurezza del mio Mac con RoamSwitch» e ti spiegherà i risultati dell'audit."
            ),
        ]
    }

    // MARK: - Troubleshooting: operation

    private static func troubleshootingItOperation() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "faq_network_cut_off",
                title: "Internet ha improvvisamente smesso di funzionare (contenimento Air-Gap / livello di protezione)",
                summary: "L'Air-Gap di emergenza o il Blocco massimo di RoamSwitch potrebbero star fermando il traffico. Come trovare la causa e rilasciarlo.",
                details: """
                • Verifica: cerca una finestra di emergenza, e controlla la cronologia delle notifiche per avvisi come DIFESA AUTOMATICA CRITICA, XProtect, spoofing ARP, o esecuzione di comandi sospetti. Anche il Wi-Fi potrebbe essere stato disattivato.
                • Rilascia: usa il pulsante di rilascio nella finestra di emergenza o nella notifica. Rete e Wi-Fi tornano attivi.
                • Ripristino automatico: per i trigger a bassa affidabilità (come ClickFix), la rete di sicurezza dell'helper ripristina la rete entro 10 minuti anche senza rilascio. Per quelli ad alta affidabilità (file esca del ransomware, rilevamento XProtect) la rete non si riapre da sola: dopo fino a 1 ora passa alla modalità ridotta finché non rilasci dalla finestra di emergenza o dalla notifica, o una nuova verifica conferma che la causa è scomparsa. Vale anche dopo la chiusura, un crash o un riavvio.
                • Subito dopo l'avvio: il traffico può essere limitato dalla porta di avvio fino a 90 secondi.
                • Altre cause: il Blocco massimo blocca il traffico in entrata ma non impedisce il normale uso in uscita come la navigazione web. Controlla anche il kill switch della VPN (mentre il tunnel è giù), il resolver della Protezione dalle minacce DNS, e i blocchi della Protezione link.
                """,
                recommendation: "Quando il contenimento si attiva, leggi la notifica che lo ha scatenato e rilascialo una volta confermato che è sicuro. Se una protezione si attiva spesso per errore, puoi disattivarla singolarmente dal menu."
            ),
            LocalizedEntry(
                id: "faq_quarantine_false_positive",
                title: "Ripristinare un download messo in quarantena per errore",
                summary: "Come ripristinare un tuo script o binario di sviluppo messo in quarantena come falso positivo, ed escluderlo dalle scansioni.",
                details: """
                1. Apri Protezione da malware → ClamAV → «📦 Gestisci file in quarantena…».
                2. Seleziona il file tra quelli in quarantena (vengono mostrati il percorso originale, il nome della minaccia e il momento della quarantena).
                3. Per un falso positivo certo, premi «Escludi e ripristina»: torna alla posizione originale e quel percorso viene escluso dalle future scansioni. Per ripristinarlo una sola volta, premi «Ripristina».
                4. Per annullare un'esclusione, premi «Rimuovi esclusione» nell'elenco dei percorsi esclusi, nella stessa finestra.
                5. Per smettere di monitorare un'intera cartella, modifica «⚙️ Gestisci cartelle monitorate…» sotto Protezione Web ed e-mail.
                """,
                recommendation: "Se non puoi essere certo che un file sia sicuro, non ripristinarlo; scegli Elimina definitivamente."
            ),
            LocalizedEntry(
                id: "faq_eicar_test",
                title: "Ho posizionato un file di test EICAR ma non ho ricevuto alcuna notifica",
                summary: "È intenzionale. La firma di test EICAR è un test innocuo, quindi non appare alcun banner e nulla viene messo in quarantena. Il rilevamento viene registrato nella cronologia delle notifiche.",
                details: """
                • Come confermarlo: controlla in Audit di sicurezza del Mac → «🔔 Cronologia notifiche…» la presenza di «🧪 Firma di test EICAR rilevata (innocua)».
                • Il file: resta dove si trova.
                • Per testare il percorso di avviso reale: usa le simulazioni in fondo a Protezione da malware (difesa ransomware, Air-Gap di rilevamento malware, rilevamento rischi Docker).
                """,
                recommendation: "Elimina il file EICAR una volta terminati i test."
            ),
            LocalizedEntry(
                id: "faq_dev_server_blocked",
                title: "Il mio server di sviluppo o la mia app di ricezione LAN non è raggiungibile da altri dispositivi",
                summary: "Il blocco automatico delle porte di ascolto sconosciute potrebbe star bloccando un programma che ha appena iniziato a esporre una porta. Resta raggiungibile dal Mac stesso.",
                details: """
                • Verifica: cerca nella cronologia delle notifiche «Porta di ascolto sconosciuta bloccata automaticamente».
                • Consenti: usa il pulsante «Consenti» della notifica, oppure Porte esposte → la porta → la schermata di audit delle porte. Consentirla si applica in modo permanente, per eseguibile.
                • Rispetto all'isolamento manuale: una porta che hai isolato tu stesso con «Isola porta» viene ripristinata con «Rimuovi isolamento» nella schermata di audit delle porte.
                • Livello di protezione: su una rete con Blocco massimo, il firewall blocca completamente le connessioni in entrata. Per consentire l'accesso dalla LAN, registra quella rete e impostala su Bilanciato o Attendibile.
                """,
                recommendation: "Consenti una volta le app di ricezione LAN che usi regolarmente, come LocalSend o Syncthing, e non verranno più bloccate."
            ),
            LocalizedEntry(
                id: "faq_link_guard_false_block",
                title: "La Protezione link blocca un sito legittimo / mantiene una connessione in attesa",
                summary: "Cosa fare quando la Protezione link blocca un sito per errore o lo mantiene in attesa in modalità Avviso.",
                details: """
                • Consenti temporaneamente: «Consenti una volta (5 min)» sulla notifica di blocco.
                • Consenti permanentemente: scegliere «Consenti» nel pannello di avviso viene ricordato.
                • Una connessione in attesa si è bloccata da sola: la modalità Avviso blocca se non c'è risposta entro circa 8 secondi (fallisce in modo chiuso). Questo risultato non viene memorizzato nella cache, quindi ricaricare la pagina chiederà di nuovo.
                • Non vedi la notifica: con lo stile di notifica a banner, i pulsanti possono restare nascosti, quindi appare anche un pannello in primo piano. Durante la modalità Non disturbare, controlla la cronologia delle notifiche.
                • Disattiva temporaneamente: passa la modalità a «Solo avvisa (mai bloccare)» oppure «Disattivata».
                """,
                recommendation: "Se uno strumento di lavoro viene bloccato ripetutamente, controlla che il dominio non presenti errori di battitura o somiglianze sospette prima di consentirlo."
            ),
            LocalizedEntry(
                id: "faq_keyboard_blocked",
                title: "La mia tastiera esterna non scrive (protezione BadUSB)",
                summary: "La protezione fisica della porta da BadUSB sta bloccando l'input di una tastiera non presente nella lista consentiti finché non la approvi.",
                details: """
                • Approva: fai clic su «Fidati e consenti» nella finestra «⚠️ Rilevato dispositivo USB / tastiera sconosciuto» (usa la tastiera integrata o il trackpad).
                • Non trovi la finestra: scollega e ricollega il dispositivo per farla riapparire.
                • Dock e switch KVM: sono coperti anche i dispositivi con funzione tastiera integrata. Consentili se sono tuoi.
                • Permesso Accessibilità: il blocco alternativo usato quando il dispositivo non può essere acquisito in modo esclusivo dipende dal permesso Accessibilità.
                • Revoca: rimuovila in «Impostazioni protezione USB / BadUSB…».
                """,
                recommendation: "Non consentire un dispositivo che ha attivato l'avviso di digitazione scriptata; scollegalo."
            ),
            LocalizedEntry(
                id: "faq_vpn_troubleshooting",
                title: "Il tunnel VPN non si connette / non passa traffico",
                summary: "Cosa controllare quando il backend WireGuard o Tailscale non funziona.",
                details: """
                • WireGuard: conferma che `brew install wireguard-tools` sia installato e che sia stata importata una `.conf`. Se lo stato mostra «🟡 Nessuna risposta (ultimo handshake …)», controlla il server VPN e le chiavi e l'endpoint della configurazione. Il kill switch è attivo, quindi nulla passa finché il tunnel non è stabilito.
                • Tailscale: conferma che la CLI sia installata e con accesso effettuato (altrimenti il menu mostra «Accedi prima a Tailscale») e che sia selezionato un exit node. Se l'exit node selezionato è offline, scegline un altro.
                • Tailscale dall'App Store: l'exit node non può essere impostato dall'esterno dell'app, scegli invece nell'app Tailscale.
                • Kill switch di Tailscale: su alcune reti può interferire con la connettività di Tailscale stessa; disattivalo se non riesci a connetterti.
                • La disconnessione automatica sulle reti attendibili è un comportamento previsto.
                """,
                recommendation: "Inizia dalla riga di stato nel menu: l'handshake per WireGuard, lo stato dell'exit node per Tailscale."
            ),
            LocalizedEntry(
                id: "faq_log_audit_repeated_alerts",
                title: "Le notifiche dell'audit dei log continuano ad arrivare",
                summary: "Il controllo automatico dei log apprende il comportamento normale dei log di questo Mac man mano che viene eseguito. Gli avvisi aumentano subito dopo la configurazione o un aggiornamento importante e diminuiscono naturalmente man mano che l'apprendimento procede.",
                details: """
                • Nuovi pattern: una volta segnalato, un pattern diventa noto e non viene più rinotificato per lo stesso contenuto.
                • Picchi di frequenza: l'apprendimento di ogni pattern si completa dopo 3 osservazioni; dopodiché, un volume normale non genera avvisi. Finché la notifica mostra ancora qualcosa come «apprendimento della frequenza in corso: 2/3 osservazioni», l'apprendimento continua.
                • Cause comuni: aggiornamenti di macOS o delle app, collegamento di nuovi dispositivi, carico elevato temporaneo.
                • Per fermarlo: disattiva nel menu «Controllo automatico dei log (apprende nuovi pattern e anomalie di frequenza secondo una pianificazione) (Pro)» (l'audit manuale dei log resta disponibile).
                """,
                recommendation: "Finché gli avvisi non includono nomi di app o indirizzi IP sconosciuti, o fallimenti sudo, va bene aspettare un po'."
            ),
            LocalizedEntry(
                id: "faq_zero_telemetry",
                title: "Design della privacy Zero Telemetry",
                summary: "RoamSwitch e il suo server MCP non inviano mai risultati di audit, URL, informazioni sulle porte, log o contenuti di file a server esterni. L'unico traffico di rete sono le eccezioni esplicite seguenti.",
                details: """
                • Completamente locale: l'audit di sicurezza, il monitoraggio delle porte, l'analisi dei link, l'audit dei segreti, l'audit dei log, la scansione antivirus e la comunicazione MCP restano tutti sul dispositivo.
                • Eccezioni:
                  - L'attivazione e la disattivazione della licenza (solo quando agisci tu) e l'apertura della pagina di acquisto
                  - I controlli di aggiornamento dell'app (Sparkle)
                  - Gli aggiornamenti delle definizioni ClamAV (`freshclam`)
                  - I download giornalieri dell'elenco delle minacce della Protezione link, delle mappe CVE dei pacchetti, e delle mappe CVE delle vulnerabilità (solo in ricezione, verificate tramite firma, senza inviare identificatori; l'aggiornamento automatico della Protezione link può essere disattivato)
                  - Il traffico normale verso i provider VPN e DNS sicuro che configuri
                  - Le sonde non distruttive della verifica attiva delle vulnerabilità verso 127.0.0.1 (questo stesso Mac)
                • Non esiste da nessuna parte nel codice telemetria o raccolta di utilizzo. Anche il promemoria di approvazione dell'helper funziona solo grazie a un contatore sul dispositivo.
                """,
                recommendation: "È sicuro da usare in ambienti aziendali altamente riservati e configurazioni di sviluppo personali senza preoccuparsi di fughe di dati."
            ),
        ]
    }
}
