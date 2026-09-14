// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.26 (build 83).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

// French (fr) content for `RoamSwitchKnowledgeBase`.
// Translated from the English source (`RoamSwitchKnowledgeBaseContent_en.swift`).
// Every entry id here must also exist in every other
// `RoamSwitchKnowledgeBaseContent_<lang>.swift` file.
extension RoamSwitchKnowledgeBase {
    static func labelsFr() -> MarkdownLabels {
        return MarkdownLabels(
            featuresTitle: "Spécification complète des fonctionnalités et architecture de RoamSwitch",
            featuresIntro: "Le fonctionnement de chaque fonction de sécurité de RoamSwitch, avec ses réglages par défaut et ses limites.",
            alertsTitle: "Catalogue des alertes et notifications de RoamSwitch",
            alertsIntro: "Chaque bannière de notification, avertissement et fenêtre d'urgence affichés par RoamSwitch, avec leur cause, la défense automatique déclenchée et les actions recommandées étape par étape.",
            settingsTitle: "Guide des réglages et de l'utilisation de RoamSwitch",
            settingsIntro: "Instructions pas à pas pour chaque réglage, interrupteur, liste d'autorisation et politique de RoamSwitch.",
            troubleshootingTitle: "Dépannage et questions fréquentes de RoamSwitch",
            troubleshootingIntro: "Réponses officielles aux questions fréquentes, aux autorisations et approbations, à l'installation de Homebrew / ClamAV / blueutil, aux faux positifs et à la conception de la confidentialité.",
            summary: "Résumé",
            overview: "Aperçu",
            detailsHeading: "Détails et causes",
            adviceHeading: "Que faire",
            recommendation: "Recommandation",
            bestPractice: "Bonne pratique",
            advice: "Conseil"
        )
    }

    static func contentFr() -> [LocalizedEntry] {
        var list: [LocalizedEntry] = []
        list.append(contentsOf: featuresFrNetwork())
        list.append(contentsOf: featuresFrMalware())
        list.append(contentsOf: featuresFrAudit())
        list.append(contentsOf: alertsFrNetwork())
        list.append(contentsOf: alertsFrMalware())
        list.append(contentsOf: settingsFr())
        list.append(contentsOf: troubleshootingFrSetup())
        list.append(contentsOf: troubleshootingFrOperation())
        return list
    }

    // MARK: - Features: network & devices

    private static func featuresFrNetwork() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_network_autoswitch",
                title: "Basculement automatique de la sécurité réseau & filtre de paquets PF (3 niveaux)",
                summary: "Compare l'adresse MAC de la passerelle du réseau actuel à vos réseaux enregistrés et applique automatiquement le niveau de protection correspondant. Les réseaux non enregistrés reçoivent le niveau « Protection par défaut en déplacement » (initialement Verrouillage maximal). Disponible dans l'édition gratuite.",
                details: """
                • 🟢 Approuvé (Ouvert - Débloqué) : par exemple à la maison. Pare-feu désactivé ; services de partage (SSH / SMB / Partage d'écran) et AirDrop autorisés.
                • 🟡 Équilibré (Pare-feu & Furtivité) : par exemple au travail ou en partage de connexion. Le filtre de paquets PF et le mode furtif bloquent les sondages externes tout en gardant les services de partage disponibles.
                • 🔴 Verrouillage maximal (Partage & AirDrop désactivés) : cafés, Wi-Fi public, réseaux non enregistrés. Tout le trafic entrant est bloqué, les démons de partage sont arrêtés, AirDrop est désactivé.
                • Logique de décision : lors d'un changement de réseau, l'adresse MAC de la passerelle est lue et comparée aux réseaux enregistrés. Les événements de chemin qui ne changent pas la passerelle (renouvellement DHCP, itinérance Wi-Fi) ne déclenchent pas de réévaluation complète.
                • Détails internes : l'assistant privilégié `RoamSwitchHelper` (via XPC) gère une ancre `pfctl` dédiée, ce qui permet de rejeter les paquets au niveau du noyau.
                • Dérogation manuelle : depuis Dérogation manuelle, vous pouvez choisir, pour chaque niveau, Jusqu'à la déconnexion (Recommandé), Pendant 1 heure, Pendant 4 heures, ou Jusqu'à annulation manuelle (voir set_manual_override).
                """,
                recommendation: "Enregistrez votre domicile et les autres bureaux sûrs via « Enregistrer le réseau actuel », et laissez le Verrouillage maximal s'appliquer automatiquement partout ailleurs."
            ),
            LocalizedEntry(
                id: "feat_network_history_guard",
                title: "Apprentissage de l'historique réseau & détection de jumeau maléfique (Wi-Fi similaire) (Pro)",
                summary: "Apprend, uniquement sur ce Mac, quelles adresses MAC de passerelle chaque SSID Wi-Fi a utilisées, et avertit d'un possible jumeau maléfique (point d'accès factice) lorsque vous rejoignez un SSID inconnu dont le nom ressemble étrangement à un réseau déjà utilisé.",
                details: """
                • Ce qui est appris : pour chaque SSID, les adresses MAC de passerelle observées (jusqu'à 8 par SSID, pour le Wi-Fi maillé), stockées dans `~/Library/Application Support/RoamSwitch/network_history.json`. Jusqu'à 200 SSID, le plus ancien étant supprimé en premier. Rien n'est envoyé hors de l'appareil.
                • Test de ressemblance : distance d'édition (Levenshtein) insensible à la casse. Les noms de moins de 6 caractères sont exemptés, et la distance autorisée augmente lentement avec la longueur (1 à 2 caractères), de sorte que des SSID génériques par défaut comme « ASUS » ou « TP-Link_5G » qui coïncident par hasard ne déclenchent jamais l'alerte.
                • Contrôle des faux positifs : le même matériel de passerelle diffusant un second SSID (réseau invité, routeur renommé) n'est pas signalé. Un SSID connu observé avec une nouvelle adresse MAC de passerelle (routeur remplacé) est enregistré mais n'alerte jamais à lui seul.
                • Pendant qu'une usurpation ARP est détectée, l'observation est ignorée afin que l'adresse MAC d'un attaquant ne soit jamais apprise comme légitime.
                • L'avertissement est une alerte en temps réel, envoyée en Pro. L'historique appris est accessible via l'outil MCP `get_network_history`.
                """,
                recommendation: "Si vous recevez cet avertissement, ne saisissez pas d'identifiants sur ce Wi-Fi et vérifiez le vrai nom et l'emplacement du réseau. Un tunnel VPN (feat_vpn_tunnel) est la contre-mesure la plus fiable."
            ),
            LocalizedEntry(
                id: "feat_arp_spoof_guard",
                title: "Détection d'usurpation ARP (usurpation réseau) & blocage automatique (Pro)",
                summary: "Détecte l'usurpation ARP, où un attaquant sur le même réseau se fait passer pour le routeur afin d'espionner ou de modifier le trafic (attaque de l'intercepteur). Sur les réseaux en Verrouillage maximal, le réseau est coupé immédiatement ; sur les autres niveaux, une notification vous informe et vous laisse décider.",
                details: """
                • Détection : l'adresse IP de la passerelle par défaut reste identique tandis que son adresse MAC change soudainement. Outre les événements de changement de réseau, une interrogation dédiée toutes les 15 secondes détecte aussi les attaques qui commencent en cours de session.
                • Réponse : sur un réseau en Verrouillage maximal, confinement Air-Gap immédiat (feat_airgap_containment). Sur les réseaux Approuvé ou Équilibré, notification uniquement, et vous pouvez déclencher le confinement depuis « Surveillance des ports et appareils » avec « Usurpation ARP détectée — couper tout le réseau maintenant ». Cela évite les déclenchements erronés dus aux redémarrages de routeur ou à l'itinérance maillée, et empêche qu'un unique paquet ARP falsifié soit utilisé comme arme pour provoquer une panne auto-infligée.
                • Par défaut : l'option de menu « Blocage automatique à la détection d'usurpation ARP (usurpation réseau) (Pro) » est activée automatiquement lors de la première activation d'une licence Pro (set_pro_default_guards).
                • Rôle : il s'agit d'une réponse a posteriori. La prévention est assurée par l'épinglage ARP/NDP de la passerelle (feat_gateway_arp_lock) et le tunnel VPN (feat_vpn_tunnel).
                • Les incidents sont enregistrés dans la chronologie des incidents (feat_containment_incident_timeline) sous la référence MITRE ATT&CK T1557.
                """,
                recommendation: "Gardez cette fonction activée. Pour une protection MITM renforcée, ajoutez le tunnel VPN ; pour une prévention sans infrastructure supplémentaire, ajoutez l'épinglage ARP/NDP de la passerelle."
            ),
            LocalizedEntry(
                id: "feat_gateway_arp_lock",
                title: "Épinglage ARP/NDP de la passerelle (Préventif) (Pro)",
                summary: "Lorsque vous rejoignez un réseau non fiable, épingle les adresses MAC de la passerelle, du routeur IPv6 et de tout serveur DNS local en tant qu'entrées statiques du cache de voisinage, empêchant les attaques de l'intercepteur par usurpation ARP/NDP avant qu'elles ne commencent. Désactivé par défaut.",
                details: """
                • Activation : « Surveillance des ports et appareils » → « Épingler l'ARP/NDP de la passerelle sur les réseaux non fiables (préventif) (Pro) ».
                • Fonctionnement : à la connexion, les adresses MAC actuelles sont lues et l'assistant les épingle en tant qu'entrées permanentes avec `arp -s` / `ndp -s`. Le noyau ignore ensuite les réponses ARP falsifiées et les annonces de voisinage pour ces IP.
                • Portée : uniquement ces trois types d'entrées. Rien n'est épinglé sur les réseaux Approuvés (ouverts), de sorte qu'un redémarrage du routeur domestique ne coupe jamais la connexion. Les épinglages sont effacés et recréés à chaque changement de réseau.
                • Limite (confiance à la première utilisation) : la première adresse MAC observée est approuvée, donc un attaquant déjà présent avant votre connexion pourrait faire épingler sa propre adresse MAC. Si vous ne pouvez pas accepter cette hypothèse, utilisez le tunnel VPN.
                • Reflété dans le point « Épinglage ARP de la passerelle (défense préventive contre les attaques MITM) » de l'audit de sécurité Mac.
                """,
                recommendation: "Une bonne défense MITM légère lorsqu'un VPN n'est pas pratique. Peut être combinée avec le tunnel VPN (le VPN étant la défense principale, ceci un complément)."
            ),
            LocalizedEntry(
                id: "feat_vpn_tunnel",
                title: "Tunnel VPN (WireGuard / Tailscale, avec coupe-circuit) (Pro)",
                summary: "Établit automatiquement un tunnel chiffré sur les réseaux non fiables afin que les attaques de l'intercepteur ne voient que du texte chiffré. Choisissez WireGuard (fichier de configuration) ou Tailscale (nœud de sortie) comme backend. Ne dépend pas de l'intégrité de la couche 2 (ARP/NDP), ce qui en fait la défense anti-MITM principale. Aucune autorisation Network Extension requise.",
                details: """
                • Backend : « Surveillance des ports et appareils » → « Tunnel VPN (anti-MITM sur réseaux non fiables) (Pro) » → « Backend », puis choisissez WireGuard ou Tailscale. Seul le backend sélectionné fonctionne.
                • WireGuard : nécessite `wireguard-tools` de Homebrew (`brew install wireguard-tools`). Importez une configuration avec « Importer une config WireGuard (.conf)… ». Vous fournissez vous-même la configuration (Mullvad, IVPN, Proton VPN, votre propre serveur, votre employeur) ; RoamSwitch ne fournit pas de serveurs VPN.
                • Coupe-circuit WireGuard : pf applique « block drop all » avec des exceptions uniquement pour lo, l'interface du tunnel, la poignée de main UDP vers le point de terminaison, le DHCP et l'ICMP. Rien ne fuit en clair pendant que le tunnel est coupé.
                • Tailscale : pour les personnes qui utilisent déjà Tailscale. RoamSwitch ne l'installe pas et ne se connecte pas ; il lit `tailscale status` et exécute `tailscale set --exit-node=<nœud>`. Un nœud de sortie est requis (tout le trafic y passe). Un nœud de sortie hors ligne est indiqué dans la ligne d'état.
                • La CLI Tailscale (autonome) est recommandée : `brew install tailscale` → `sudo tailscaled install-system-daemon` → `sudo tailscale up`. La version App Store (interface graphique) ne peut pas être pilotée avec `tailscale set` depuis l'extérieur de l'app ; choisissez alors le nœud de sortie dans l'app Tailscale, RoamSwitch se chargeant uniquement de l'affichage de l'état et du coupe-circuit.
                • Coupe-circuit Tailscale (désactivé par défaut, optionnel) : pf laisse passer uniquement lo, l'interface utun de Tailscale, le CGNAT 100.64.0.0/10, le DNS, STUN 3478, 41641, DERP tcp 443, le DHCP et l'ICMP. Plus permissif que WireGuard (« difficile à faire fuir » plutôt qu'étanche), et peut sur certains réseaux gêner la connectivité propre de Tailscale, d'où son caractère optionnel.
                • Automatique : le tunnel/nœud de sortie s'active sur les réseaux non fiables, se désactive sur les réseaux fiables. Si la licence expire, le tunnel et le coupe-circuit sont libérés automatiquement.
                """,
                recommendation: "La protection la plus efficace si vous utilisez souvent le Wi-Fi public. Utilisateurs de Tailscale : installez la CLI et choisissez le backend Tailscale plus un nœud de sortie. Sinon, `brew install wireguard-tools` avec le fichier `.conf` de votre fournisseur VPN est la voie la plus simple."
            ),
            LocalizedEntry(
                id: "feat_airgap_containment",
                title: "Confinement d'urgence Air-Gap (coupure réseau totale, désactivation du Wi-Fi, filet de sécurité de rétablissement automatique)",
                summary: "Le confinement d'urgence partagé utilisé lorsqu'une menace grave est détectée (rançongiciel, détection de malware par XProtect, usurpation ARP, ClickFix). Il bloque tout le trafic entrant et sortant. Même après un plantage ou un redémarrage, le réseau revient automatiquement en 10 minutes maximum.",
                details: """
                • Fonctionnement : l'assistant privilégié charge pf avec « block drop all » (sauf la boucle locale) et relit la règle pour confirmer. Le trafic sortant est également coupé, ce qui empêche l'exfiltration de clés ou de données vers un serveur C2. Si l'application échoue, jusqu'à 3 nouvelles tentatives sont effectuées (délai de 8 secondes chacune) ; si cela échoue encore, le message « Échec de la coupure réseau automatique » s'affiche et vous demande de vous déconnecter manuellement. Il ne prétend jamais à une isolation qui ne serait pas réelle.
                • Désactivation du Wi-Fi : pf ne fait que rejeter les paquets tandis que l'adaptateur reste associé, donc les confinements par usurpation ARP, rançongiciel et XProtect désactivent aussi le Wi-Fi lui-même via `networksetup` (activé par défaut ; réglage interne `RoamSwitch.AirGapAutoWiFiKillEnabled`). Le confinement ClickFix ne désactive pas le Wi-Fi.
                • Libération : lever le confinement depuis la fenêtre d'urgence ou la notification retire le blocage pf et réactive le Wi-Fi.
                • Filet de sécurité : si l'app plante ou que personne ne lève le confinement, une minuterie côté assistant force la levée de l'Air-Gap après 10 minutes et rétablit le Wi-Fi. Relancer l'app ou redémarrer le Mac permet aussi de récupérer sans étape manuelle.
                • Porte de démarrage : juste après le démarrage, avant que l'app n'applique sa politique, une porte pf refusant par défaut est en vigueur ; elle se libère d'elle-même après 90 secondes maximum.
                """,
                recommendation: "Lorsque le confinement se déclenche, lisez d'abord la notification, quittez les applications suspectes et lancez une analyse avant de lever le confinement. Si vous savez qu'il s'agit d'un faux positif, levez-le immédiatement."
            ),
            LocalizedEntry(
                id: "feat_port_anomaly_guard",
                title: "Blocage automatique des ports d'écoute inconnus & isolement des serveurs de développement (Pro)",
                summary: "Surveille chaque port TCP en écoute et, lorsqu'un exécutable qui n'était pas exposé auparavant se met soudainement à écouter sur 0.0.0.0, bloque l'accès à ce port depuis le réseau local. Les serveurs de développement et les serveurs d'IA locaux peuvent aussi être isolés sur 127.0.0.1 en un clic.",
                details: """
                • Surveillance : les ports en écoute sont analysés toutes les 20 secondes. L'identité repose sur le chemin de l'exécutable, de sorte qu'une application connue qui change simplement de numéro de port ne déclenche rien. L'état juste après l'activation est enregistré comme référence.
                • Blocage automatique : lorsqu'un exécutable inconnu commence à exposer un port, pf bloque uniquement l'accès externe (le Mac lui-même et localhost peuvent continuer à l'utiliser). Cela permet de détecter une porte dérobée implantée par une faille zero-day sans connaître la famille du malware.
                • Exclus : les démons système signés par Apple sous `/System/Library` ou `/usr/libexec` (par exemple rapportd, nécessaire pour Handoff, AirPlay, AirDrop). Les outils généraux sous `/usr/bin`, comme `/usr/bin/python3` ou `/usr/bin/nc`, sont quand même signalés.
                • Services à risque : identifie les services souvent exposés sans authentification, comme Redis (6379), MongoDB (27017), Memcached (11211), Elasticsearch (9200), VNC (5900), ainsi que les serveurs d'IA locaux comme Ollama (11434), LM Studio (1234), Gradio (7860) et vLLM (8000).
                • Isolement des serveurs de développement : ouvrez le port depuis « Ports exposés » et choisissez « Isoler le port » pour le restreindre à 127.0.0.1 (Pro).
                • Faux positifs : autorisez de façon permanente via le bouton « Autoriser » de la notification ou depuis l'écran d'audit des ports. Désactiver cette protection (ou une licence expirée) libère tous les blocages créés.
                • Par défaut : activé automatiquement lors de la première activation de Pro. L'historique des incidents est accessible via l'outil MCP `get_port_anomaly_incidents`.
                """,
                recommendation: "Liez vos serveurs de développement et vos LLM locaux à `127.0.0.1` (par exemple `OLLAMA_HOST=127.0.0.1 ollama serve`, `npm run dev -- -H 127.0.0.1`)."
            ),
            LocalizedEntry(
                id: "feat_active_vuln_scan",
                title: "Vérification active des vulnérabilités — désactivée par défaut",
                summary: "Pour les services détectés sur ce Mac lui-même (127.0.0.1), vérifie avec des sondes minimales en lecture seule s'ils répondent réellement sans authentification. Désactivée par défaut ; nécessite une activation explicite et une confirmation à chaque exécution.",
                details: """
                • Activation : « Surveillance des ports et appareils » → « Vérification active des vulnérabilités ». Cela déverrouille uniquement le bouton « Exécuter la vérification active » dans l'écran d'audit des ports ; rien n'est envoyé de son propre chef, et chaque exécution demande d'abord « Envoyer la demande de vérification ? ».
                • Uniquement vers 127.0.0.1 : rien n'est jamais envoyé à un autre hôte.
                • Accès non authentifié : sondes uniques, à délai court et non destructives vers Redis (PING), Memcached (stats) et MongoDB (listDatabases).
                • Serveurs de développement génériques : vérifie une mauvaise configuration CORS (Origin reflété avec identifiants), la traversée de chemin et les redirections ouvertes.
                • Correspondance avec des CVE connues : pour Redis / Memcached accessibles sans authentification, la version est lue via une requête non destructive et comparée aux plages de versions de CVE connues. Aucune charge utile d'exploitation n'est envoyée.
                • Également disponible via l'outil MCP `run_active_vuln_scan` (le seul outil qui envoie du trafic réseau, uniquement vers localhost).
                """,
                recommendation: "Activez cette fonction uniquement lorsque vous souhaitez vérifier si Redis, Docker, un LLM local ou similaire fonctionnant sur votre propre Mac est réellement accessible sans authentification."
            ),
            LocalizedEntry(
                id: "feat_usb_keyboard_guard",
                title: "Protection physique du port contre USB non autorisé / BadUSB (Approbation du clavier & analyse du rythme de frappe) (Pro)",
                summary: "Lorsqu'un clavier USB inconnu ou un câble modifié (Rubber Ducky, O.MG Cable, Flipper Zero et similaires) est branché, les frappes de cet appareil sont bloquées jusqu'à ce que vous l'approuviez, empêchant l'injection automatisée de commandes. Analyse aussi les intervalles de frappe et avertit lorsqu'ils semblent scriptés.",
                details: """
                • Détection : IOHIDManager repère les nouveaux claviers en temps réel. Le clavier intégré est approuvé automatiquement.
                • Blocage : l'appareil non approuvé est saisi de manière exclusive (Seize IOHIDDevice), de sorte que seules les frappes de cet appareil n'atteignent pas le système ; les autres claviers continuent de fonctionner. Ce n'est qu'en cas d'échec de la saisie exclusive qu'un blocage par CGEventTap est utilisé en repli, ce qui requiert l'autorisation Accessibilité.
                • Approbation : une fenêtre au premier plan propose « Faire confiance et autoriser » ou « Rejeter et maintenir le blocage ». Les claviers autorisés sont ajoutés à la liste d'autorisation.
                • Analyse du rythme de frappe : pendant le blocage, les intervalles de frappe de l'appareil continuent d'être mesurés. Après au moins 5 intervalles, une moyenne de 12 ms ou moins, ou de 45 ms ou moins avec une très grande régularité (coefficient de variation de 0,35 ou moins), déclenche un avertissement « présente des signes de frappe scriptée ». Cela capture une vitesse et une régularité mécaniques qu'aucun humain ne produit, à titre de preuve supplémentaire uniquement ; cela ne change pas la décision de blocage.
                • Désactivée par défaut. Activez-la via « Surveillance des ports et appareils » → « Protection physique du port contre USB non autorisé / BadUSB (Pro) » ; gérez la liste d'autorisation dans « Paramètres de protection USB / BadUSB… ».
                """,
                recommendation: "Si vous utilisez des claviers externes, n'enregistrez que ceux que vous avez branchés vous-même avec « Faire confiance et autoriser ». Rejetez et débranchez toujours un appareil qui déclenche l'avertissement de frappe scriptée."
            ),
            LocalizedEntry(
                id: "feat_usb_storage_guard",
                title: "Blocage automatique du stockage USB non autorisé & analyse automatique ClamAV (Pro)",
                summary: "Un lecteur USB ou un disque externe qui ne figure pas dans la liste d'autorisation est d'abord monté en lecture seule pendant qu'on vous demande comment procéder. Les appareils autorisés sont également analysés avec ClamAV avant d'être connectés avec la permission configurée.",
                details: """
                • Surveillance : DiskArbitration détecte instantanément les montages de volumes externes/amovibles.
                • Appareils non enregistrés : remontés en lecture seule par sécurité, avec une boîte de dialogue proposant « Autoriser en lecture-écriture », « Autoriser en lecture seule » ou « Éjecter ». Éjecter démonte et éjecte immédiatement.
                • Appareils autorisés : la permission de la liste d'autorisation (Lecture seule / Lecture-écriture) est appliquée automatiquement, avec une analyse ClamAV avant toute mise à niveau vers la lecture-écriture.
                • Infection : si un malware est détecté, le volume est éjecté automatiquement et une alerte urgente est envoyée.
                • Lecteurs reformatés : si l'UUID du volume change mais que l'identité matérielle, y compris le numéro de série, correspond, l'approbation est conservée (l'ID fabricant/produit seul ne compte jamais comme une correspondance).
                • Portée : couvre l'exfiltration de données et les charges malveillantes via le stockage. Les appareils BadUSB de type HID se faisant passer pour des claviers sont gérés par feat_usb_keyboard_guard.
                """,
                recommendation: "N'ajoutez à la liste d'autorisation que les lecteurs USB que vous utilisez pour le travail, et privilégiez la permission Lecture seule sur les Mac traitant des données sensibles."
            ),
            LocalizedEntry(
                id: "feat_bluetooth_guard",
                title: "Désactivation automatique du Bluetooth sur les réseaux non fiables (Pro)",
                summary: "Lorsque vous rejoignez un réseau en déplacement où le Verrouillage maximal s'applique, le Bluetooth est désactivé automatiquement pour réduire l'exposition aux appairages non sollicités et aux attaques BLE, et rétabli lorsque vous retrouvez un réseau fiable.",
                details: """
                • Outil : macOS ne propose pas d'API publique pour basculer l'alimentation du Bluetooth, donc RoamSwitch utilise l'outil open source Homebrew `blueutil` (`brew install blueutil`). S'il est absent, le menu affiche des instructions d'installation.
                • Rétablissement : le Bluetooth n'est réactivé sur un réseau fiable que s'il était activé juste avant que RoamSwitch ne le désactive ; un choix que vous avez fait vous-même en déplacement n'est pas annulé.
                • Désactivé par défaut : de nombreuses personnes utilisent des AirPods et similaires dans les cafés, donc couper silencieusement l'audio serait mal accueilli. Fonction optionnelle.
                """,
                recommendation: "Si vous n'utilisez pas d'accessoires Bluetooth en déplacement, activez cette fonction pour éviter le balayage radio et les appairages non sollicités."
            ),
        ]
    }

    // MARK: - Features: malware & web protection

    private static func featuresFrMalware() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_webmail_download_guard",
                title: "Protection Web et E-mail (Analyse auto et mise en quarantaine des téléchargements) (Pro)",
                summary: "Surveille avec FSEvents les fichiers enregistrés depuis les navigateurs, Mail, Slack, Discord et similaires, les vérifie avec une signature statique et ClamAV, et déplace les menaces dans le coffre de quarantaine.",
                details: """
                • Dossiers surveillés : par défaut `~/Downloads`, `~/Desktop`, `~/Documents` ainsi que le dossier de téléchargement de Mail. Ajoutez ou retirez des dossiers avec « ⚙️ Gérer les dossiers surveillés… ».
                • Source du téléchargement : identifiée grâce à l'attribut étendu `com.apple.quarantine` que macOS y attache.
                • Vérification à deux niveaux : une vérification statique de signature sur l'appareil (lignes classiques de shell inversé et similaires ; fonctionne même sans ClamAV) plus une analyse ClamAV. Une correspondance de signature statique entraîne la mise en quarantaine quel que soit le verdict de ClamAV, et si ClamAV n'est pas d'accord, la notification indique qu'il pourrait s'agir d'un faux positif.
                • Quarantaine : les menaces sont déplacées vers `~/Library/Application Support/RoamSwitch/Quarantine/` (jamais supprimées). Si le déplacement échoue, la notification indique l'échec de la mise en quarantaine et vous demande de supprimer le fichier manuellement.
                • Fichier de test EICAR : la signature de test standard de l'industrie, inoffensive, n'est ni mise en quarantaine ni bloquée et ne déclenche aucune notification ; elle est simplement enregistrée dans l'historique des notifications (feat_notification_history).
                • Premier accès à un dossier : avant la demande d'autorisation de macOS, un avis unique explique qu'il s'agit d'une autorisation légitime pour cette fonction d'analyse.
                • Avertissements sur les modèles au format Pickle : voir feat_ai_model_guard.
                """,
                recommendation: "Installez et activez ClamAV, et ajoutez tout dossier de téléchargement de navigateur personnalisé aux dossiers surveillés."
            ),
            LocalizedEntry(
                id: "feat_ai_model_guard",
                title: "Avertissement lors du téléchargement d'un format de modèle d'IA dangereux (Pickle / PyTorch) (Pro)",
                summary: "Lorsqu'un fichier modèle `.pkl` / `.pickle` / `.pt` est téléchargé depuis Hugging Face, Civitai ou similaire, avertit que le format Pickle peut exécuter du code arbitraire lors du chargement, et recommande SafeTensors / GGUF.",
                details: """
                • Détection : vérifie l'extension des fichiers téléchargés dans les dossiers surveillés par la Protection Web et E-mail (feat_webmail_download_guard).
                • Risque : le Pickle de Python peut exécuter du code arbitraire pendant la désérialisation, donc le simple fait de charger un modèle malveillant peut compromettre le Mac.
                • Comportement : avertissement uniquement ; le fichier n'est pas mis en quarantaine (une correspondance de ClamAV ou de la signature statique entraîne toujours la mise en quarantaine comme d'habitude).
                """,
                recommendation: "Ne chargez pas de modèles Pickle / PyTorch provenant de sources inconnues ; utilisez plutôt des modèles `.safetensors` ou `.gguf`."
            ),
            LocalizedEntry(
                id: "feat_quarantine_manager",
                title: "Gestion des fichiers en quarantaine (coffre, restauration, suppression, exclusions d'analyse)",
                summary: "Les fichiers signalés par ClamAV ou la vérification de signature statique ne sont jamais supprimés ; ils sont conservés dans le coffre de quarantaine. Le gestionnaire de quarantaine permet de voir pourquoi, de restaurer à l'emplacement d'origine, de supprimer définitivement, ou d'exclure un chemin des analyses futures.",
                details: """
                • Ouvrir : « Protection contre les malwares (XProtect & ClamAV) » → ClamAV → « 📦 Gérer les fichiers en quarantaine… », ou « 📦 Ouvrir le gestionnaire de quarantaine… » sous Protection Web et E-mail.
                • Emplacement : `~/Library/Application Support/RoamSwitch/Quarantine/`, avec des métadonnées pour le chemin d'origine, le nom de la menace et l'heure de mise en quarantaine. Rien n'est supprimé sauf si vous choisissez explicitement Supprimer définitivement.
                • Restaurer : remet le fichier à son emplacement d'origine ; à utiliser uniquement lorsque vous êtes certain qu'il n'est pas infecté.
                • Exclure et restaurer : pour un faux positif confirmé, restaure le fichier et exclut ce chemin exact des analyses ClamAV futures. Les exclusions sont listées dans la même fenêtre, où « Retirer l'exclusion » les annule.
                • Supprimer définitivement : supprime après confirmation. Cette action est irréversible.
                • L'outil MCP `get_quarantine_status` liste les fichiers en quarantaine.
                """,
                recommendation: "Supprimez les fichiers que vous ne reconnaissez pas, et n'utilisez « Exclure et restaurer » que pour des faux positifs certains, comme vos propres scripts ou binaires de développement."
            ),
            LocalizedEntry(
                id: "feat_xprotect_file_safety",
                title: "État de Apple XProtect & analyse de sécurité de fichier/app",
                summary: "Affiche la version des définitions et l'état de la protection intégrée de macOS contre les malwares, XProtect, et vérifie qu'un fichier ou une app quelconque est notarisé, signé par une autorité de confiance, avec un Team ID et l'attribut de quarantaine des téléchargements. Disponible dans l'édition gratuite.",
                details: """
                • Ouvrir : « Protection contre les malwares (XProtect & ClamAV) » → « 🍏 Apple XProtect » → « Vérifier l'état de XProtect… » / « Analyser la sécurité du fichier/de l'app… ».
                • Vérifications : approuvé par Apple (Notarisé/Gatekeeper) ou non, autorité de signature, Team ID, attribut de quarantaine des téléchargements Web (`com.apple.quarantine`), et le chemin.
                • Usage : avant d'ouvrir une app pour la première fois, confirmez qu'elle a été signée et notarisée par un développeur légitime.
                """,
                recommendation: "Analysez les apps d'origine inconnue avant de les lancer, et n'ouvrez rien qui ne soit ni approuvé ni signé."
            ),
            LocalizedEntry(
                id: "feat_dns_threat_guard",
                title: "Protection DNS contre les menaces (Bloquer malwares et C2) (Pro)",
                summary: "Applique un résolveur DNS sécurisé (Quad9, Cloudflare, AdGuard, CleanBrowsing) afin que les résolutions de noms vers des serveurs C2 de malwares et des sites d'hameçonnage soient bloquées dès l'étape DNS.",
                details: """
                • Fournisseurs : Quad9 (9.9.9.9 / 149.112.112.112), Cloudflare Security (1.1.1.2 / 1.0.0.2), AdGuard DNS (94.140.14.14 / 94.140.15.15, bloque aussi les publicités et traceurs), CleanBrowsing Security (185.228.168.9 / 185.228.169.9).
                • Politique : « Wi-Fi non fiable uniquement (Recommandé) » ou « Toujours actif sur tous les réseaux (y compris fiables) ».
                • Détails internes : l'assistant privilégié bascule les serveurs DNS du service réseau actif et rétablit les paramètres DHCP/DNS manuels d'origine lorsque vous revenez sur un réseau fiable.
                • État : le menu affiche « 🟢 DNS sécurisé actif » ou « 🏠 Réseau de confiance (DNS standard du routeur) ». Fait aussi partie de l'audit de sécurité Mac.
                """,
                recommendation: "Pour éviter le faux DNS sur le Wi-Fi public (détournement DNS) et les domaines malveillants, commencez avec Quad9 et la politique réservée au déplacement."
            ),
            LocalizedEntry(
                id: "feat_passive_link_guard",
                title: "Protection des liens (Détecter et bloquer les connexions d'hameçonnage : extension système, compatible DoH, le mode Avertissement échoue en mode fermé) (Pro)",
                summary: "Bloque sur l'appareil les connexions vers les sites d'hameçonnage et d'arnaque, pour tout navigateur ou toute app, en s'appuyant sur une liste de menaces de domaines d'arnaque connus et sur la détection d'usurpation de marque. Fonctionne comme une extension système de filtrage de contenu, avec un « sinkhole » /etc/hosts comme solution de repli jusqu'à ce que l'extension soit approuvée.",
                details: """
                • Modes : « Désactivé », « Avertir seulement (ne jamais bloquer) » et « Bloquer automatiquement les sites d'hameçonnage manifestes (recommandé) » (par défaut). Changez de mode sous Protection contre les malwares → « Protection des liens (détection des connexions d'hameçonnage) (Pro) ».
                • Ce qui est bloqué : uniquement les cas manifestes, c'est-à-dire les domaines figurant dans la liste de menaces ou une usurpation de marque par homographe Unicode. Les astuces de marque insérée dans un sous-domaine, les TLD à haut risque et similaires sont traités comme des avertissements. Le moteur de verdict et la liste sont partagés avec l'édition Linux.
                • Extension système (recommandé) : l'extension système de filtrage de contenu `RoamSwitchLinkFilter` examine les flux TCP après la résolution de nom. Outre le nom d'hôte résolu par le système, elle lit aussi le SNI du ClientHello TLS, ce qui fonctionne même si le navigateur utilise son propre DoH / DoT. En mode blocage, elle abandonne le QUIC (UDP 443), où le SNI n'est pas visible, afin que les navigateurs se rabattent sur le TCP. La première utilisation nécessite une approbation dans les Réglages Système.
                • Empreinte JA3 : pour les connexions TLS dont le SNI a été lu, l'empreinte JA3 du client est également calculée et comparée à la liste JA3 de la liste de menaces (JA3 n'est jamais utilisé seul sur des connexions sans SNI).
                • Mode Avertissement (échoue en mode fermé) : la connexion correspondante est mise en pause et une notification Autoriser/Bloquer ainsi qu'un panneau au premier plan apparaissent ; le flux reprend ou est abandonné selon votre réponse. Sans réponse dans environ 8 secondes, la connexion est bloquée. Ce résultat n'est pas mis en cache, donc la tentative suivante redemandera. Les réponses que vous donnez réellement sont mémorisées. Le mode Avertissement nécessite l'extension système.
                • Solution de repli hosts : tant que l'extension n'est pas active, le mode blocage fait écrire les domaines par l'assistant privilégié sous forme de `0.0.0.0` dans une section gérée de `/etc/hosts`.
                • Liste de menaces : récupérée une fois par jour, en réception seule, sans envoi d'identifiants, et vérifiée avec une clé de liste Ed25519 dédiée (distincte de la clé de mise à jour de l'app). Désactiver la « Mise à jour auto » signifie zéro trafic sortant ; les données intégrées et la détection d'homographe continuent de fonctionner.
                • Sans Pro : le mode est enregistré mais rien n'est bloqué.
                """,
                recommendation: "Conservez le blocage automatique par défaut et approuvez l'extension système pour la protection la plus fiable. Si un outil interne est bloqué par erreur, utilisez « Autoriser une fois (5 min) » dans la notification ou la liste d'autorisation."
            ),
            LocalizedEntry(
                id: "feat_link_safety_auditor",
                title: "Audit de sécurité des liens (Vérification manuelle, Zero Telemetry)",
                summary: "Avant d'ouvrir une URL suspecte, l'analyse entièrement sur l'appareil et évalue son risque sur une échelle de 100 en fonction des homographes Unicode, de l'usurpation de sous-domaine, des TLD à haut risque, du HTTP en clair, des adresses IP brutes, et plus encore. Disponible dans l'édition gratuite.",
                details: """
                • Ouvrir : Protection contre les malwares → « 🔗 Vérifier un lien manuellement… », ou l'outil MCP `audit_url_safety`.
                • Homographes : détecte les caractères visuellement similaires comme les lettres cyrilliques ou grecques (Punycode / `xn--`).
                • Usurpation de sous-domaine : analyse des structures comme `apple.com.login-verify.xyz` qui intègrent le nom d'une grande marque.
                • TLD à haut risque : déduit des points pour les TLD courants dans l'hameçonnage jetable, comme `.xyz`, `.top`, `.tk`, `.icu`.
                • HTTP en clair et IP brutes : avertit du HTTP non chiffré sur les pages de connexion et des URL avec adresse IP nue.
                • Entièrement local : les URL ne sont jamais envoyées à une API d'analyse externe, de sorte que les URL confidentielles et les jetons ne fuient pas.
                """,
                recommendation: "Ne cliquez pas directement sur les liens suspects reçus par e-mail ou chat ; vérifiez-les d'abord avec l'Audit de sécurité des liens."
            ),
            LocalizedEntry(
                id: "feat_ransomware_canary_guard",
                title: "Détection par fichiers leurres contre les rançongiciels & Air-Gap autonome avec gel de processus (Pro)",
                summary: "Place des fichiers leurres (canaris) cachés dans vos dossiers utilisateur. Dès que l'un d'eux est modifié, supprimé ou renommé, RoamSwitch coupe automatiquement le réseau, arrête les services de partage et met en pause (SIGSTOP) le processus suspect.",
                details: """
                • Fichiers leurres : quatre dans `~/Library/Application Support/RoamSwitch/CanaryGuard/`, plus des fichiers cachés commençant par `.roamswitch_security_canary_do_not_delete` dans Documents, Bureau, Téléchargements et Photos. Le SHA-256 de chaque fichier est enregistré comme référence.
                • Détection : surveillance kqueue en temps réel plus une vérification toutes les 60 secondes. Un délai de grâce de 10 secondes par fichier empêche le traitement en double d'une même rafale d'événements. Les fichiers réels modifiés dans les 60 dernières secondes sont enregistrés comme potentiellement affectés.
                • Réponse automatique : (1) verrouillage du pare-feu applicatif, (2) confinement Air-Gap (pf bloque tout le trafic et le Wi-Fi est désactivé, feat_airgap_containment), (3) arrêt des services de partage (SMB / SSH / Partage d'écran), (4) le processus suspect est mis en pause avec SIGSTOP plutôt que tué, (5) alerte urgente et fenêtre d'urgence au premier plan.
                • Pourquoi geler plutôt que tuer : le réseau est déjà coupé, donc un processus en pause ne peut causer aucun dommage supplémentaire. En cas de faux positif, il est repris (SIGCONT) à la levée du confinement, sans perte de données.
                • À la levée : le réseau et le Wi-Fi sont rétablis, le processus en pause est repris, et les fichiers leurres altérés sont régénérés.
                • Par défaut : activé automatiquement lors de la première activation de Pro. Historique des incidents via l'outil MCP `get_canary_status`. Testez sans risque avec « Simulation de défense contre les rançongiciels (Test) » dans le menu.
                """,
                recommendation: "Gardez cette fonction activée pour protéger les données importantes des rançongiciels inconnus, et ne supprimez pas les fichiers leurres cachés."
            ),
            LocalizedEntry(
                id: "feat_runtime_threat_containment",
                title: "Déconnexion réseau automatique lors d'une détection de malware par XProtect (Pro)",
                summary: "Dès l'instant où le XProtect / XProtect Remediator intégré à Apple détecte ou supprime réellement un malware, le réseau est coupé par un Air-Gap d'urgence. Un blocage Gatekeeper d'une app non signée ne coupe pas le réseau ; il envoie seulement une notification.",
                details: """
                • Source du signal : un abonnement de longue durée à `/usr/bin/log stream` au format ndjson (attente bloquante plutôt qu'interrogation, donc un coût CPU quasi nul au repos) surveille les journaux système liés à XProtect.
                • Déclenchement : seul un enregistrement critique de XProtect engage le confinement Air-Gap (y compris la désactivation du Wi-Fi), quel que soit le niveau de confiance du réseau.
                • Différence avec Gatekeeper : les événements Gatekeeper quotidiens, comme le blocage d'une compilation non signée créée par un développeur lui-même, ne déclenchent que la notification « Gatekeeper a empêché l'exécution d'une app non signée ».
                • Cohérence : partage la même logique de classification que l'Audit des journaux de sécurité Mac manuel.
                • N'utilisant pas d'autorisation EndpointSecurity, il s'agit d'un confinement immédiat après détection, et non d'un blocage avant exécution.
                • Par défaut : activé automatiquement lors de la première activation de Pro (avec un avis unique indiquant que la coupure automatique est activée). État disponible via l'outil MCP `get_runtime_threat_status` ; testez avec « Simulation de l'Air-Gap lié à la détection de malware (test) ».
                """,
                recommendation: "Gardez cette fonction activée comme défense automatique liée au propre moteur anti-malware d'Apple. Exécuter fréquemment vos propres apps non signées ne la déclenchera pas, car un simple blocage Gatekeeper ne coupe jamais le réseau."
            ),
            LocalizedEntry(
                id: "feat_clickfix_guard",
                title: "Protection ClickFix — blocage automatique en cas de commandes Terminal suspectes (Pro, désactivé par défaut)",
                summary: "Détecte, dans l'historique du shell, la technique ClickFix par laquelle une fausse page de vérification ou d'erreur vous incite à coller et exécuter vous-même une commande, et coupe le réseau pour stopper une attaque en plusieurs étapes en cours.",
                details: """
                • Surveillé : uniquement les lignes nouvellement ajoutées à `~/.zsh_history` et `~/.bash_history` (l'historique existant est ignoré).
                • Motifs : (1) les lignes de shell inversé connues (partagées avec la vérification de signature statique), et (2) une double indirection qui envoie un contenu décodé en Base64 directement dans un shell ou `osascript`. Un simple `curl ... | bash`, comme utilisé par des installateurs légitimes tels que Homebrew, n'est délibérément pas signalé.
                • Réponse : confinement Air-Gap (le Wi-Fi n'est pas désactivé), rétabli automatiquement en 10 minutes maximum. La notification recommande de vérifier votre trousseau, les mots de passe enregistrés dans le navigateur et vos portefeuilles de cryptomonnaies.
                • Pourquoi après coup : au moment où une ligne apparaît dans l'historique, la commande a déjà été exécutée, mais couper le réseau immédiatement peut encore arrêter un téléchargement de deuxième étape, une connexion de shell inversé active, ou une exfiltration d'identifiants en cours.
                • Pourquoi Gatekeeper ne peut pas l'empêcher : c'est votre propre shell légitime qui exécute exactement ce que vous avez tapé, donc rien dans le processus lui-même ne semble inhabituel.
                • Complément : la protection du presse-papiers (feat_secret_leak_auditor) intercepte la commande dès la copie, couvrant les collages dans l'Éditeur de scripts, Spotlight, et ailleurs qu'au Terminal.
                • Désactivé par défaut : une coupure réseau automatique déclenchée par une heuristique relativement récente, donc optionnelle.
                """,
                recommendation: "Envisagez d'activer cette fonction si vous craignez d'être piégé par de fausses pages d'erreur ou des vérifications pour exécuter des commandes."
            ),
            LocalizedEntry(
                id: "feat_persistence_monitor_guard",
                title: "Surveiller les nouveaux enregistrements de démarrage automatique (LaunchAgent / LaunchDaemon) (Pro)",
                summary: "Surveille en temps réel les nouveaux enregistrements de LaunchAgent / LaunchDaemon et vous avertit lorsque l'un d'eux lance directement un shell ou un interpréteur de script, ou enregistre un exécutable dont la signature est invalide.",
                details: """
                • Surveillé : `~/Library/LaunchAgents`, `/Library/LaunchAgents` et `/Library/LaunchDaemons` via FSEvents (anti-rebond d'environ 1,5 seconde).
                • Jugement : les voleurs d'informations récents assurent leur persistance en faisant exécuter par un `/bin/bash` ou `/usr/bin/osascript` valablement signé par Apple un script caché en Base64. Comme la signature de l'interpréteur lui-même est valide, tout enregistrement lançant un interpréteur nu est traité comme suspect quelle que soit la signature, et ses arguments de script passent aussi par la vérification de signature statique. Les exécutables non signés ou avec une signature invalide sont également signalés. Les enveloppes de Homebrew services sont exemptées.
                • Détection uniquement : sans autorisation EndpointSecurity, l'écriture du plist ne peut pas être empêchée. Elle est jugée et signalée dans les 1,5 seconde environ après son écriture.
                • Par défaut : activé par défaut avec Pro. Basculez sous Protection contre les malwares → « Surveiller les nouveaux enregistrements de démarrage automatique (LaunchAgent/Daemon) (Pro) ».
                """,
                recommendation: "Si vous recevez une alerte d'enregistrement inconnu, examinez le plist affiché dans la notification et supprimez-le si vous ne le reconnaissez pas. Juste après l'installation d'une app légitime, c'est généralement sans danger."
            ),
            LocalizedEntry(
                id: "feat_docker_event_guard",
                title: "Détecter les conteneurs Docker privilégiés et les montages docker.sock (Pro, désactivé par défaut)",
                summary: "Vous avertit, au démarrage d'un conteneur, des configurations Docker risquées pouvant mener à une évasion de conteneur, comme des conteneurs démarrés avec `--privileged` ou avec `/var/run/docker.sock` monté.",
                details: """
                • Fonctionnement : toutes les 20 secondes, `docker ps` repère uniquement les conteneurs nouvellement démarrés, et `docker inspect` vérifie leurs paramètres. Le format de détection est identique à celui de l'édition Linux, de sorte que les deux plateformes signalent les mêmes conditions.
                • Notification uniquement : il s'agit d'une configuration risquée, non d'une compromission confirmée (un agent de surveillance peut être exécuté en mode privilégié à dessein), donc rien n'est bloqué automatiquement.
                • Désactivé par défaut : la plupart des utilisateurs n'utilisent pas Docker, donc cette fonction est désactivée même en Pro.
                • Test : « ⚠️ Simulation de détection des risques Docker (Test)… » vérifie le chemin de notification sans toucher à Docker.
                """,
                recommendation: "Si vous utilisez Docker pour le développement, activez cette fonction pour repérer tôt les risques d'évasion de conteneur."
            ),
        ]
    }

    // MARK: - Features: audit, monitoring & platform

    private static func featuresFrAudit() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_critical_path_fim",
                title: "Surveillance de l'altération des fichiers système critiques (Critical Path FIM) (Pro)",
                summary: "Enregistre une référence SHA-256 de fichiers critiques comme sudoers, la configuration SSH, PAM et hosts, que les mises à jour légitimes du système ou les installations d'apps ne modifient presque jamais, et vous avertit de toute modification, suppression ou nouveau fichier.",
                details: """
                • Fichiers : `/etc/sudoers`, `/etc/pam.d/sudo`, `/etc/ssh/sshd_config`, tout ce qui se trouve sous `/etc/ssh/sshd_config.d/`, `/etc/hosts`, ainsi que `~/.ssh/authorized_keys` de root. Ils sont réservés à root, donc l'assistant privilégié calcule les empreintes.
                • Quand : les FSEvents sur `/etc`, `/etc/pam.d` et `/etc/ssh` déclenchent une nouvelle analyse quasi instantanée, avec une analyse horaire en filet de sécurité.
                • Référence : capturée lors de la première analyse. Un changement détecté n'est jamais adopté automatiquement comme nouvelle référence, de sorte que la constatation persiste jusqu'à ce qu'un humain la vérifie. Le même état n'est pas renotifié tant que l'app fonctionne ; tout changement ultérieur alerte à nouveau.
                • Avertissement d'angle mort : si l'assistant reste inaccessible pendant 3 analyses consécutives, vous êtes averti que la détection d'altération ne fonctionne pas.
                • Remarque : pendant que la Protection des liens fonctionne en solution de repli hosts, RoamSwitch peut lui-même réécrire sa section gérée de `/etc/hosts`. Les LaunchAgents / Daemons sont couverts par feat_persistence_monitor_guard.
                • Par défaut : activé automatiquement lors de la première activation de Pro. Menu : Protection contre les malwares → « Surveiller périodiquement les fichiers système critiques contre toute altération (Pro) ».
                """,
                recommendation: "En cas d'alerte, vérifiez si vous avez vous-même effectué le changement (par exemple `sudo visudo` ou une modification de configuration). Sinon, examinez immédiatement le fichier et envisagez de changer votre mot de passe."
            ),
            LocalizedEntry(
                id: "feat_security_log_audit",
                title: "Audit des journaux de sécurité Mac (manuel, détection d'anomalies de modèle, copie pour consultation IA)",
                summary: "Extrait des journaux unifiés de macOS les échecs sudo, les connexions SSH, les blocages Gatekeeper, les détections XProtect et les événements d'authentification, et liste aussi les nouveaux motifs de journal et les pics de fréquence (anomalies de modèle). Disponible dans l'édition gratuite.",
                details: """
                • Ouvrir : Audit de sécurité Mac → « 📜 Audit des journaux de sécurité Mac… », ou l'outil MCP `audit_security_logs`.
                • Période : dernières 24 heures, 3 jours ou 7 jours.
                • Cartes récapitulatives : échecs Sudo, connexions SSH, blocages Gatekeeper, détections XProtect, anomalies de modèle. Filtrable par catégorie et interrogeable.
                • Anomalies de modèle : les lignes de journal sont transformées en modèles en masquant les parties variables (adresses IP, adresses hexadécimales, nombres). Cela fait ressortir les motifs jamais vus sur ce Mac ([nouveau]) et les pics bien au-dessus de leur fréquence habituelle ([pic z=…], score z de 3 ou plus). La fréquence de chaque motif est apprise après 3 observations, après quoi un volume normal ne déclenche plus d'alerte.
                • Verdict en langage clair : un assistant à base de règles sur l'appareil résume le résultat pour les non-experts avec des points précis à vérifier (aucune API externe).
                • Sortie : « Copier le rapport », « Copier les éléments pour consultation IA » (copie une question plus les journaux à coller dans Claude, ChatGPT et similaires ; RoamSwitch n'envoie rien), et « Exporter CSV (Pro) ».
                """,
                recommendation: "Exécutez cet audit lorsque des notifications suspectes se poursuivent ou que le Mac se comporte étrangement, et vérifiez les détections XProtect ou une hausse des échecs sudo."
            ),
            LocalizedEntry(
                id: "feat_scheduled_log_audit",
                title: "Audit automatique des journaux (apprend les nouveaux motifs et anomalies de fréquence selon un calendrier) (Pro)",
                summary: "Exécute toutes les heures en arrière-plan la détection d'anomalies de modèle de l'audit des journaux, apprenant en continu le comportement normal des journaux de ce Mac. Lorsqu'elle trouve de nouveaux motifs ou des pics de fréquence, elle vous avertit avec de vraies lignes de journal et une explication en langage clair.",
                details: """
                • Calendrier : toutes les heures, en analysant la dernière heure. La première analyse s'exécute environ 10 secondes après l'activation, mais comme elle inclut les propres journaux de démarrage de l'app, cette exécution ne fait qu'apprendre, sans notifier.
                • Notification : le nombre d'anomalies (réparti en nouveaux motifs et pics), jusqu'à 3 vraies lignes de journal, une note sur la progression de l'apprentissage, et une explication pour les non-experts. Un nouveau motif devient « connu » une fois signalé et n'est plus jamais renotifié pour le même contenu ; un pic cesse d'alerter une fois que la référence propre à ce motif a été apprise.
                • Partagé avec l'audit manuel : utilise la même analyse et la même référence apprise que l'Audit des journaux de sécurité Mac manuel et l'outil MCP `audit_security_logs`.
                • Par défaut : activé automatiquement lors de la première activation de Pro. Menu : Protection contre les malwares → « Audit automatique des journaux (apprend les nouveaux motifs et anomalies de fréquence selon un calendrier) (Pro) ».
                """,
                recommendation: "Attendez-vous à un peu plus d'alertes de nouveaux motifs juste après la configuration ; elles se stabilisent à mesure que l'apprentissage progresse. Si une alerte mentionne une app ou une adresse IP inconnue, ouvrez la fenêtre d'audit des journaux pour plus de détails."
            ),
            LocalizedEntry(
                id: "feat_containment_incident_timeline",
                title: "Chronologie des incidents de confinement (registre unifié, correspondance MITRE ATT&CK)",
                summary: "Enregistre les quatre réponses automatiques (usurpation ARP, fichiers leurres de rançongiciel, coupure liée à XProtect, blocage automatique de port inconnu) dans un registre chronologique unique sur l'appareil, afin que vous puissiez revoir plus tard ce qui s'est passé, ce qui a été fait et quand cela a été résolu.",
                details: """
                • Enregistré : heure, source, gravité, résumé, nom du processus et PID (si connu), action entreprise, ainsi que l'heure et la raison de la résolution (levé manuellement, levé automatiquement après délai, ou ajouté à la liste d'autorisation).
                • MITRE ATT&CK : un identifiant de technique n'est ajouté que lorsque la correspondance est certaine (usurpation ARP = T1557 ; fichier leurre supprimé ou renommé = T1485 ; chiffrement = T1486 ; autre altération = T1565). Rien n'est deviné.
                • Stockage : `~/Library/Application Support/RoamSwitch/containment_incident_timeline.json` (les 200 plus récents). Jamais envoyé nulle part.
                • L'outil MCP `get_incident_timeline` renvoie cette chronologie unifiée (utile pour un tri avec une IA locale pendant un Air-Gap). L'historique par protection est également disponible via `get_canary_status`, `get_port_anomaly_incidents` et `get_runtime_threat_status`.
                """,
                recommendation: "Après une coupure automatique, consultez cette chronologie avec l'historique des notifications pour trouver la cause et éviter une récidive."
            ),
            LocalizedEntry(
                id: "feat_notification_history",
                title: "Historique des notifications (semaine écoulée)",
                summary: "Conserve chaque notification envoyée par RoamSwitch pendant 7 jours afin que vous puissiez revoir les alertes manquées. Les événements enregistrés dans l'historique sans bannière, comme une détection de signature de test EICAR, apparaissent aussi ici. Disponible dans l'édition gratuite.",
                details: """
                • Ouvrir : Audit de sécurité Mac → « 🔔 Historique des notifications… ».
                • Conservation : 7 jours ; les entrées plus anciennes sont automatiquement supprimées à chaque nouvel enregistrement.
                • Contenu : heure, titre et corps, y compris les alertes de menace, les événements de connexion de la Protection des liens, les détections ClickFix et de clé secrète, et les coupures automatiques.
                • Signature de test EICAR : le fichier de test inoffensif standard de l'industrie n'est pas une vraie menace, donc il n'est ni mis en quarantaine ni bloqué et aucune bannière ne s'affiche ; il est seulement enregistré ici. Ceci vaut également pour la protection des téléchargements, les analyses rapides et les analyses planifiées.
                • Un assistant IA peut le lire via l'outil MCP `get_notification_history`.
                """,
                recommendation: "Si vous avez manqué une notification en déplacement ou occupé, vérifiez-la ici."
            ),
            LocalizedEntry(
                id: "feat_secret_leak_auditor",
                title: "Protection du presse-papiers (avertissement de collage de clé API & suppression des commandes ClickFix)",
                summary: "Surveille le presse-papiers uniquement sur l'appareil, avertit lorsqu'une clé API ou une clé privée a été copiée afin que vous ne la colliez pas par erreur, et vide automatiquement le presse-papiers lorsque vous copiez une commande malveillante qu'un site d'arnaque veut vous faire exécuter (ClickFix). Activé par défaut dans l'édition gratuite.",
                details: """
                • Surveillance : vérifie les changements du presse-papiers environ une fois par seconde. Le contenu n'est jamais envoyé ni stocké.
                • Clés détectées : clés API et jetons d'OpenAI, Anthropic, GitHub, AWS, Hugging Face, Google AI / Gemini, Slack et Stripe, ainsi que les clés privées RSA / SSH. Également les phrases de récupération de portefeuille crypto (BIP39) et les clés privées Bitcoin (WIF/BIP32), toutes deux vérifiées par somme de contrôle pour limiter les faux positifs.
                • Pour les clés secrètes : notification uniquement (« Clé confidentielle détectée dans le presse-papiers ») ; le presse-papiers n'est pas vidé, car une clé divulguée peut encore être révoquée et renouvelée ensuite.
                • Pour les commandes ClickFix : notification (« Commande suspecte détectée dans le presse-papiers ») et le presse-papiers est vidé immédiatement, empêchant le collage où qu'il soit destiné : Terminal, Éditeur de scripts, Spotlight ou ailleurs. Cela complète feat_clickfix_guard, qui surveille l'historique du shell.
                """,
                recommendation: "Après avoir copié une clé API, faites attention à l'endroit où vous la collez, surtout dans les chats IA et les formulaires Web. Si vous l'avez partagée par erreur, révoquez-la et réémettez-la immédiatement."
            ),
            LocalizedEntry(
                id: "feat_secret_leak_audit_tool",
                title: "Audit manuel des fuites de secrets / clés API (coller du texte ou analyser un dossier entier)",
                summary: "Un outil d'audit à la demande qui vérifie instantanément le texte collé ou analyse un dossier récursivement, affichant les numéros de ligne, les valeurs masquées et les étapes de révocation pour chaque type de clé. Disponible dans l'édition gratuite.",
                details: """
                • Ouvrir : Protection contre les malwares → « 🔑 Auditer manuellement les fuites de secrets/clés API… », ou l'outil MCP `audit_secrets` (avec `text` ou `path`).
                • Méthode : expressions régulières plus un score d'entropie de Shannon. Les valeurs détectées sont affichées masquées.
                • Analyse de dossier : `.git`, `node_modules`, `target`, `vendor`, `dist`, `build`, `__pycache__` et `venv` sont ignorés automatiquement, tout comme les fichiers de plus de 2 Mo et les binaires.
                • Avis de permission : choisir un dossier protégé comme Bureau ou Téléchargements affiche d'abord un avis unique expliquant pourquoi l'accès est nécessaire et que l'analyse est Zero Telemetry, avant la demande de macOS.
                • S'exécute sur un fil d'arrière-plan sans geler l'interface. Rien n'est envoyé nulle part.
                """,
                recommendation: "Utilisez cet outil avant de publier un dépôt ou de coller du code dans un chat IA."
            ),
            LocalizedEntry(
                id: "feat_package_cve_scan",
                title: "Vérification CVE des paquets (Homebrew + 7 écosystèmes dont npm / PyPI / crates.io, Zero Telemetry)",
                summary: "Compare les paquets Homebrew installés et les fichiers de verrouillage de dépendances dans les dossiers de projet que vous choisissez à des cartes de CVE connues conservées sur l'appareil. L'analyse elle-même n'effectue aucune requête réseau. Disponible dans l'édition gratuite.",
                details: """
                • Ouvrir : Protection contre les malwares → « 📦 Vérification CVE des paquets (Homebrew)… ». Pour les dépendances, ajoutez des dossiers de projet dans l'onglet Dépendances.
                • Homebrew : `brew list --versions` est comparé à une table formule-vers-CPE générée à partir de vraies données NVD. Les résultats portent un niveau de confiance : confirmed (table vérifiée) ou gray (correspondance de mot-clé non vérifiée, pouvant être un faux positif).
                • Dépendances : analyse package-lock.json / requirements.txt / Pipfile.lock / poetry.lock / Cargo.lock / Gemfile.lock / composer.lock / go.sum / pom.xml et les compare aux cartes de CVE connues pour npm, PyPI, crates.io, RubyGems, Packagist, Go et Maven (issues d'OSV.dev, CVSS 7,0 ou plus).
                • Diffusion des données : les cartes de CVE sont récupérées une fois par jour depuis un manifeste signé, en réception seule. Avant leur récupération, elles s'affichent comme non encore téléchargées et ne détectent rien.
                • Outils MCP : `run_package_cve_scan` (Homebrew) et `run_package_cve_scan_languages` (dépendances, argument `watchedFolders`).
                """,
                recommendation: "Exécutez régulièrement l'analyse Homebrew, enregistrez les projets actifs dans l'onglet Dépendances, et mettez à jour rapidement les paquets présentant des CVE graves."
            ),
            LocalizedEntry(
                id: "feat_security_health_checker",
                title: "Audit de sécurité Mac (18 points, score et étapes de correction)",
                summary: "Vérifie 18 points répartis en six domaines (renforcement système, défense réseau, authentification et contrôle d'accès, exposition des ports, protection contre les malwares et défense physique des appareils) et affiche un score de 0 à 100, une note, ainsi que les étapes pour corriger chaque point non validé. Disponible dans l'édition gratuite.",
                details: """
                • Renforcement système : 1. FileVault, 2. SIP (Protection de l'intégrité du système), 3. Gatekeeper, 4. mises à jour de sécurité automatiques, 5. Apple XProtect.
                • Défense réseau : 6. pare-feu macOS, 7. mode furtif, 8. force du chiffrement Wi-Fi, 9. surveillance de l'usurpation ARP, 10. verrouillage ARP de la passerelle.
                • Authentification et contrôle d'accès : 11. configuration de la connexion SSH distante (connexion root désactivée, authentification par clé uniquement), 12. élévation de privilège sudo (audit `NOPASSWD`).
                • Services et exposition des ports : 13. ports exposés.
                • Protection contre les malwares et les téléchargements : 14. Protection Web et E-mail, 15. Protection DNS contre les menaces, 16. protection contre l'hameçonnage et les liens malveillants (avertissement de site frauduleux de Safari).
                • Ports physiques et appareils : 17. Protection physique du port contre USB non autorisé / BadUSB, 18. protection de connexion d'accessoire macOS (Apple Silicon).
                • Non applicable : le pare-feu et le mode furtif sur un réseau fiable, le SSH lorsque la connexion distante est désactivée, l'audit sudo avant la connexion de l'assistant, et la protection des accessoires sur les Mac Intel sont exclus du score.
                • Notes : 100 = S, 85-99 = A, 70-84 = B, en dessous de 70 = C. Aussi disponible via l'outil MCP `get_security_report`.
                """,
                recommendation: "Ouvrez régulièrement le rapport d'audit, traitez les points marqués ⚠️ en suivant les étapes de correction, et maintenez au moins la note A."
            ),
            LocalizedEntry(
                id: "feat_autonomous_sentinel",
                title: "Patrouille autonome en arrière-plan, mises à jour des définitions ClamAV & analyses planifiées",
                summary: "Toutes les 4 heures, rafraîchit en arrière-plan l'audit de sécurité, les ports, les appareils USB et l'état de XProtect (toutes éditions). Pro avertit en outre en cas de baisse de score, met à jour automatiquement les définitions ClamAV, et exécute une analyse antivirus quotidienne.",
                details: """
                • Audit périodique (toutes éditions) : environ 30 secondes après le lancement puis toutes les 4 heures, afin que les résultats restent à jour même si vous restez sur un même réseau pendant des heures.
                • Avertissement de baisse de score (Pro) : notifie lorsque le score tombe sous 80 ou que 4 points ou plus échouent.
                • Définitions ClamAV (Pro) : exécute `freshclam` silencieusement.
                • Analyse planifiée (Pro) : une fois par jour, analyse `~/Downloads`, `~/Desktop` et `~/Library/LaunchAgents` avec ClamAV. Les menaces sont mises en quarantaine automatiquement avec une alerte urgente ; un résultat propre entraîne un simple avis discret de fin. Si seule la signature de test EICAR est trouvée, rien n'est affiché, seule une trace est ajoutée à l'historique des notifications.
                """,
                recommendation: "En Pro, installez ClamAV pour que les mises à jour des définitions et les analyses planifiées s'exécutent automatiquement."
            ),
            LocalizedEntry(
                id: "feat_simulation_self_test",
                title: "Outils de simulation (auto-test)",
                summary: "Testez en toute sécurité que la défense contre les rançongiciels, l'Air-Gap lié à la détection de malware et la détection des risques Docker fonctionnent, sans aucune attaque réelle ni dommage aux fichiers.",
                details: """
                • Emplacement : en bas de « Protection contre les malwares (XProtect & ClamAV) ».
                • 🚨 Simulation de défense contre les rançongiciels (Test)… : exécute les mêmes étapes qu'une tentative de chiffrement détectée pour vérifier l'Air-Gap et la fenêtre d'urgence. Aucun fichier n'est endommagé.
                • 🚨 Simulation de l'Air-Gap lié à la détection de malware (test)… : exécute les mêmes étapes qu'une vraie détection XProtect pour vérifier le confinement et la fenêtre d'urgence. L'événement est étiqueté comme simulation.
                • ⚠️ Simulation de détection des risques Docker (Test)… : vérifie que la notification de conteneur privilégié arrive. Docker n'est pas touché.
                • Remarque : les tests d'Air-Gap coupent réellement le réseau temporairement. Levez le confinement depuis la fenêtre d'urgence (il se rétablit aussi de lui-même dans les 10 minutes).
                • Pour tester la protection des téléchargements, vous pouvez utiliser un fichier de test EICAR inoffensif (pas de bannière ; enregistré dans l'historique des notifications).
                """,
                recommendation: "Exécutez une simulation une fois après l'activation de Pro ou une modification des réglages pour confirmer que les notifications et l'Air-Gap se comportent comme prévu."
            ),
            LocalizedEntry(
                id: "feat_privileged_helper",
                title: "Outil assistant privilégié (RoamSwitchHelper, XPC)",
                summary: "Seules les opérations nécessitant les droits root (pare-feu PF, services de partage, DNS, Air-Gap, etc.) sont effectuées par un assistant LaunchDaemon à privilèges séparés, via XPC.",
                details: """
                • Séparation des privilèges : l'app principale s'exécute avec des droits d'utilisateur normaux et ne délègue à `RoamSwitchHelper` que les changements de règles pf, le contrôle des démons de partage, les réglages DNS, l'épinglage ARP, le hachage des fichiers critiques et tâches similaires.
                • Enregistrement : enregistré via le SMAppService de macOS en tant que LaunchDaemon intégré à l'app. La première utilisation nécessite une approbation sous Réglages Système → Général → Éléments de connexion et extensions. Il ne peut pas être enregistré si l'app n'est pas dans le dossier Applications (faq_install_location).
                • Démons associés : des LaunchDaemons assistants pour le filet de sécurité de l'Air-Gap (libération automatique après 10 minutes) et la porte de démarrage (jusqu'à 90 secondes) sont également enregistrés.
                • Vérification : les signatures de code (Team ID) sont vérifiées lors des connexions XPC, rejetant les appels de processus non autorisés.
                """,
                recommendation: "Approuvez l'assistant lorsque vous y êtes invité au premier lancement. S'il n'est pas approuvé, le menu affiche « ⚠️ Approuver l'assistant… »."
            ),
            LocalizedEntry(
                id: "feat_mcp_server",
                title: "Intégration du serveur MCP (accès en lecture seule pour les assistants IA)",
                summary: "RoamSwitch.app inclut un serveur MCP (Model Context Protocol) en lecture seule, permettant à des assistants IA comme Claude de s'informer sur l'état de sécurité de votre Mac. Il n'existe aucun outil pour modifier les réglages ou bloquer quoi que ce soit.",
                details: """
                • Transport : stdio local uniquement. Binaire : `/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`.
                • Principaux outils : `get_security_report` (audit de sécurité), `get_exposed_ports`, `get_guard_status`, `audit_url_safety`, `audit_secrets`, `audit_security_logs`, `get_quarantine_status`, `get_notification_history`, `get_canary_status`, `get_port_anomaly_incidents`, `get_runtime_threat_status`, `get_incident_timeline` (chronologie des incidents de confinement), `get_network_history` (apprentissage de l'historique réseau), `run_package_cve_scan`, `run_package_cve_scan_languages`, `run_active_vuln_scan` (le seul outil qui envoie du trafic, des sondes non destructives vers 127.0.0.1 uniquement), et `get_app_help` (cette base de connaissances).
                • Ressources : `roamswitch://docs/features`, `roamswitch://docs/alerts-and-messages`, `roamswitch://docs/settings-guide`, `roamswitch://docs/troubleshooting`.
                • Langue : les réponses suivent le réglage de langue de l'app. `get_app_help` accepte un argument `language` (ja / en / zh-Hans / zh-Hant / ko / de / fr / es / it / pt-PT).
                • Sécurité : étant en lecture seule, même une IA manipulée par injection de prompt ne peut ni changer le niveau de protection ni isoler des ports.
                """,
                recommendation: "Pour la configuration, voir faq_mcp_setup. Vous pouvez poser des questions en langage courant, comme « Mon Mac est-il sécurisé en ce moment ? » ou « Que signifie cette notification ? »"
            ),
            LocalizedEntry(
                id: "feat_license_pro_tier",
                title: "Licence Pro à vie (achat unique, jusqu'à 2 Mac)",
                summary: "Pro est une licence à vie à achat unique (2 980 ¥ / 19,99 $) utilisable sur jusqu'à 2 Mac. Le jeton de licence signé Ed25519 est vérifié sur l'appareil, donc Pro continue de fonctionner hors ligne après activation.",
                details: """
                • Fonctionnalités Pro : les défenses automatiques marquées (Pro) dans le menu (détection par fichiers leurres de rançongiciel, coupure liée à XProtect, blocage automatique de port inconnu et isolement de serveur de développement, blocage automatique d'usurpation ARP, épinglage ARP/NDP de la passerelle, tunnel VPN, protections BadUSB et stockage USB, Protection Web et E-mail, Protection DNS contre les menaces, Protection des liens, désactivation automatique du Bluetooth, protection ClickFix, surveillance des enregistrements de démarrage automatique, détection des risques Docker, surveillance de l'altération des fichiers critiques, audit automatique des journaux), notifications de menace en temps réel, avertissements de patrouille et analyses planifiées, export CSV des journaux, et plus.
                • Types de licence : Pro à vie (2 Mac) et Team à vie (5 Mac).
                • Activation : saisissez votre clé de licence (ROAM-XXXX-…) depuis « 💎 Activer / Acheter Pro… ». Le jeton signé émis par le serveur est vérifié avec la clé publique intégrée à l'app et stocké dans le trousseau.
                • Désactivation : depuis la fenêtre de licence. Retire la licence de ce Mac et libère la place sur le serveur (la désactivation locale se produit toujours, même en cas d'échec de la requête réseau).
                • En cas d'expiration : les protections réservées à Pro sont désactivées automatiquement, et le tunnel VPN ainsi que l'isolement de port sont levés.
                """,
                recommendation: "Envisagez Pro si vous souhaitez un confinement automatique, une défense en temps réel et des avertissements de patrouille. Lors du remplacement d'un Mac, désactivez d'abord sur l'ancien avant d'activer sur le nouveau."
            ),
        ]
    }

    // MARK: - Alerts: network, devices, links

    private static func alertsFrNetwork() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "alert_arp_spoofing",
                title: "⚠️ Alerte d'usurpation ARP (MITM)",
                summary: "Affichée lorsqu'il existe des signes qu'un appareil de votre réseau se fait passer pour le routeur (passerelle) afin d'espionner ou de modifier votre trafic.",
                details: """
                • Cause : un attaquant envoie de fausses réponses ARP pour que votre trafic passe par lui (attaque de l'intercepteur). Détecté lorsque l'IP de la passerelle reste identique mais que son adresse MAC change soudainement. Un redémarrage de routeur ou un transfert Wi-Fi maillé peuvent aussi le provoquer.
                • Défense automatique : en Verrouillage maximal avec « Blocage automatique à la détection d'usurpation ARP (usurpation réseau) (Pro) » activé, confinement Air-Gap immédiat. Sur les autres niveaux, notification uniquement, et le menu affiche « Usurpation ARP détectée — couper tout le réseau maintenant ».
                """,
                recommendation: """
                1. Cessez immédiatement de saisir des mots de passe, d'effectuer des paiements ou de faire transiter du trafic professionnel sur ce réseau.
                2. Sur un Wi-Fi public ou un réseau inconnu, choisissez « couper tout le réseau maintenant » dans le menu ou désactivez le Wi-Fi.
                3. Si vous avez besoin d'accès Internet, basculez vers une connexion sûre comme le partage de connexion ou le tunnel VPN.
                4. Ne continuez à utiliser le réseau que si vous savez avec certitude qu'il s'agit d'un faux positif, par exemple juste après avoir redémarré votre routeur domestique.
                """
            ),
            LocalizedEntry(
                id: "alert_evil_twin_ssid",
                title: "⚠️ Réseau Wi-Fi jumeau maléfique potentiel détecté",
                summary: "Affichée lorsque le nom (SSID) du Wi-Fi que vous avez rejoint ressemble beaucoup à un réseau déjà utilisé. Il pourrait s'agir d'un point d'accès factice malveillant (jumeau maléfique).",
                details: """
                • Cause : un attaquant met en place un point d'accès factice dont le nom diffère du légitime de seulement un ou deux caractères pour attirer les personnes. L'apprentissage de l'historique réseau (feat_network_history_guard) en juge à partir de la distance d'édition avec les noms appris et du matériel de passerelle différent.
                • Contrôle des faux positifs : les noms courts et les SSID supplémentaires diffusés par le même matériel de passerelle ne le déclenchent pas.
                • Défense automatique : notification uniquement. En tant que réseau non enregistré, le niveau Protection par défaut en déplacement s'applique.
                """,
                recommendation: """
                1. Ne vous connectez pas et ne saisissez pas d'informations personnelles sur ce Wi-Fi.
                2. Vérifiez le nom officiel du réseau (affiches en magasin ou au bureau) et déconnectez-vous s'il ne correspond pas.
                3. Si vous devez continuer à l'utiliser, connectez le tunnel VPN.
                """
            ),
            LocalizedEntry(
                id: "alert_unencrypted_wifi",
                title: "⚠️ Connecté à un Wi-Fi non chiffré",
                summary: "Affichée lorsque vous rejoignez un réseau Wi-Fi ouvert sans mot de passe ni chiffrement (WPA2 / WPA3), ou un ancien réseau WEP.",
                details: """
                • Cause : la liaison sans fil n'est pas chiffrée, de sorte que toute personne à proximité peut capturer le trafic.
                • Défense automatique : si le réseau n'est pas enregistré, la Protection par défaut en déplacement (initialement Verrouillage maximal) bloque les connexions entrantes et les services de partage.
                """,
                recommendation: """
                1. Si possible, connectez le tunnel VPN ou basculez vers une connexion fiable comme le partage de connexion.
                2. Évitez de vous connecter ou de saisir des informations personnelles sur des sites qui ne sont pas en HTTPS.
                3. Vérifiez dans le menu que le niveau de protection est Verrouillage maximal.
                """
            ),
            LocalizedEntry(
                id: "alert_port_anomaly",
                title: "🚨 Port d'écoute inconnu automatiquement bloqué",
                summary: "Affichée lorsqu'un programme qui n'était pas exposé auparavant a commencé à exposer un port au réseau local sur 0.0.0.0 et que l'accès depuis l'extérieur a été bloqué automatiquement (« Port d'écoute inconnu détecté (échec du blocage) » s'affiche si le blocage n'a pas réussi).",
                details: """
                • Cause : le démarrage d'un serveur de développement (Next.js, Vite, Python, Docker), une app de réception LAN comme LocalSend ou Syncthing se lançant pour la première fois, ou une porte dérobée ou app malveillante commençant à écouter.
                • Défense automatique : pf bloque uniquement l'accès externe (le Mac lui-même et localhost peuvent continuer à l'utiliser). Les démons système macOS sont exclus.
                """,
                recommendation: """
                1. Vérifiez si vous reconnaissez le nom du processus, le PID et le port indiqués dans la notification (également visibles sous Ports exposés).
                2. S'il s'agit de votre propre serveur ou d'une app de réception LAN, autorisez-le avec le bouton « Autoriser » de la notification ou depuis l'écran d'audit des ports. Il restera autorisé par la suite.
                3. Pour les serveurs de développement, redémarrer lié à `127.0.0.1` est l'option la plus sûre.
                4. Si vous ne le reconnaissez pas, gardez-le bloqué, quittez le processus et lancez l'audit de sécurité ainsi qu'une analyse antivirus.
                """
            ),
            LocalizedEntry(
                id: "alert_exposed_database",
                title: "🚨 Service de base de données non authentifié exposé à l'extérieur",
                summary: "Affichée lorsqu'un service souvent dépourvu d'authentification par défaut (Redis, MongoDB, Memcached, Elasticsearch) est exposé au réseau local sans protection de pare-feu.",
                details: """
                • Cause : un service de base de données ou de backend a démarré sur 0.0.0.0 alors que le niveau de protection actuel autorise les connexions entrantes. Toute personne sur le même réseau pourrait potentiellement lire ou écrire les données.
                • Défense automatique : notification (Pro) uniquement, non répétée pour le même port.
                """,
                recommendation: """
                1. Changez l'adresse d'écoute du service pour `127.0.0.1` ou activez l'authentification.
                2. Si vous ne pouvez pas le corriger immédiatement, ouvrez le port sous Ports exposés et choisissez « Isoler le port ».
                3. Utilisez le Verrouillage maximal sur les réseaux publics.
                """
            ),
            LocalizedEntry(
                id: "alert_unapproved_keyboard",
                title: "⚠️ Clavier non autorisé / connexion BadUSB détectée",
                summary: "La notification et la fenêtre d'approbation affichées lorsqu'un nouveau clavier USB absent de la liste d'autorisation (ou un appareil qui s'en fait passer pour un, comme un câble modifié) est branché et que ses frappes sont bloquées jusqu'à approbation.",
                details: """
                • Cause : le branchement d'un nouveau clavier externe ou d'une station d'accueil, ou d'un appareil d'injection de frappe comme un Rubber Ducky.
                • Défense automatique : seules les frappes de cet appareil sont bloquées (les autres claviers continuent de fonctionner). La fenêtre « ⚠️ Périphérique USB / clavier inconnu détecté » demande une approbation.
                """,
                recommendation: """
                1. S'il s'agit d'un clavier de confiance que vous avez branché vous-même, cliquez sur « Faire confiance et autoriser ». Il est ajouté à la liste d'autorisation et la saisie est activée.
                2. Si vous ne le reconnaissez pas, ou qu'il apparaît sans que vous ayez rien branché, cliquez sur « Rejeter et maintenir le blocage » et débranchez l'appareil.
                """
            ),
            LocalizedEntry(
                id: "alert_scripted_keyboard",
                title: "🚨 Ce clavier présente des signes de saisie automatisée (scriptée)",
                summary: "Affichée lorsqu'un clavier en attente d'approbation envoie des frappes à des intervalles trop rapides et trop réguliers pour un humain. Une injection automatisée de commandes (attaque BadUSB) est très probable.",
                details: """
                • Cause : un Rubber Ducky, Flipper Zero, Arduino/Digispark ou similaire a tenté de taper des commandes préchargées à grande vitesse. Jugé par l'analyse du rythme de frappe : après au moins 5 intervalles, une moyenne de 12 ms ou moins, ou de 45 ms ou moins avec une très grande régularité.
                • Défense automatique : les frappes de l'appareil étaient déjà bloquées avant l'approbation et n'ont jamais atteint le Mac. Cet avertissement ajoute simplement des preuves pour votre décision.
                """,
                recommendation: """
                1. Choisissez toujours « Rejeter et maintenir le blocage » dans la fenêtre d'approbation.
                2. Débranchez immédiatement l'appareil et vérifiez d'où il provient (une clé USB trouvée, un câble offert, etc.).
                3. Par précaution, lancez l'audit de sécurité et examinez les enregistrements de démarrage automatique.
                """
            ),
            LocalizedEntry(
                id: "alert_untrusted_usb",
                title: "🔒 Stockage USB monté en lecture seule / 🔌 Stockage USB non autorisé automatiquement bloqué",
                summary: "Affichée lorsqu'un lecteur USB ou un disque externe absent de la liste d'autorisation est branché et a été monté en lecture seule en attendant votre approbation, ou a été éjecté.",
                details: """
                • Cause : un appareil de stockage non enregistré a été branché. Cela empêche le vol de données et l'introduction de fichiers malveillants.
                • Défense automatique : remonté en lecture seule avec une boîte de dialogue « Autoriser le stockage USB « … » ? ». Choisir Éjecter l'éjecte et envoie « Stockage USB non autorisé automatiquement bloqué ».
                """,
                recommendation: """
                1. S'il s'agit de votre appareil, choisissez « Autoriser en lecture-écriture » ou « Autoriser en lecture seule ». Il sera ajouté à la liste d'autorisation et appliqué automatiquement la prochaine fois.
                2. Si vous ne le reconnaissez pas, choisissez « Éjecter ».
                3. Vous pouvez modifier la liste d'autorisation plus tard dans « Paramètres de protection USB / BadUSB… ».
                """
            ),
            LocalizedEntry(
                id: "alert_malware_usb",
                title: "🚨 Malware détecté sur un support de stockage USB",
                summary: "Affichée lorsque l'analyse ClamAV exécutée avant qu'un appareil de stockage USB ne soit connecté en lecture-écriture trouve des fichiers infectés.",
                details: """
                • Cause : des fichiers infectés se trouvent sur le lecteur USB.
                • Défense automatique : le volume est éjecté immédiatement afin que le Mac ne soit pas infecté.
                """,
                recommendation: """
                1. Formatez ou désinfectez le lecteur dans un environnement sûr séparé avant de le réutiliser.
                2. Effectuez une analyse rapide ou une analyse de dossier avec ClamAV pour vous assurer que le Mac lui-même n'est pas infecté.
                """
            ),
            LocalizedEntry(
                id: "alert_link_guard_blocked",
                title: "🛑 Protection des liens : connexion bloquée",
                summary: "Affichée lorsque la Protection des liens a automatiquement bloqué une connexion vers un site suspecté d'arnaque ou d'hameçonnage (répertorié dans la liste de menaces, ou homographe de marque).",
                details: """
                • Cause : un lien dans un e-mail ou un réseau social, une publicité, ou une app a tenté de se connecter à un domaine d'arnaque connu.
                • Défense automatique : l'extension système abandonne la connexion, ou la solution de repli hosts résout le domaine vers 0.0.0.0, quel que soit le navigateur ou l'app.
                """,
                recommendation: """
                1. Si ce n'était pas attendu, rien de plus n'est nécessaire ; ne saisissez pas d'informations sur cette page.
                2. Si un site légitime dont vous avez besoin a été bloqué par erreur, utilisez « Autoriser une fois (5 min) » sur la notification ou ajoutez-le à la liste d'autorisation.
                """
            ),
            LocalizedEntry(
                id: "alert_link_guard_warn_hold",
                title: "⚠️ Protection des liens : connexion en attente",
                summary: "En mode Avertissement, la notification et le panneau au premier plan affichés lorsqu'une connexion vers un site suspecté d'usurpation de marque ou d'arnaque a été mise en pause pendant que vous décidez de l'autoriser ou non.",
                details: """
                • Cause : une connexion vers un domaine qui déclenche un avertissement (usurpation de sous-domaine, TLD à haut risque, etc.).
                • Défense automatique : la connexion est mise en pause en attendant votre réponse. Sans réponse dans environ 8 secondes, elle est bloquée (échec en mode fermé). Ce résultat n'est pas mis en cache, donc la prochaine visite redemandera. Les réponses que vous donnez sont mémorisées.
                """,
                recommendation: """
                1. Si vous l'avez ouvert délibérément et faites confiance au site, choisissez « Autoriser ».
                2. Si vous ne le reconnaissez pas ou n'êtes pas sûr, choisissez « Bloquer » ou attendez simplement (il sera bloqué automatiquement).
                3. S'il a été bloqué par erreur, rechargez la page pour être interrogé à nouveau.
                """
            ),
            LocalizedEntry(
                id: "alert_dangerous_url",
                title: "🛑 Lien dangereux / hameçonnage suspecté (Audit de sécurité des liens)",
                summary: "Affichée lorsque l'Audit de sécurité des liens (ou `audit_url_safety`) juge une URL dangereuse en raison d'homographes, d'un sous-domaine usurpé, d'un TLD à haut risque, et similaires.",
                details: """
                • Vérifications : caractères homographes (Punycode), sous-domaines imitant de grandes entreprises, TLD courants dans l'hameçonnage, HTTP en clair, adresses IP brutes, et plus.
                • Score : en dessous de 50, c'est dangereux ; entre 50 et 79, c'est prudence.
                """,
                recommendation: """
                1. N'ouvrez pas le lien.
                2. Supprimez le message et signalez-le à votre équipe de sécurité si nécessaire.
                """
            ),
            LocalizedEntry(
                id: "alert_helper_disconnected",
                title: "⚠️ Assistant non connecté",
                summary: "Affichée lorsque la communication XPC avec l'outil assistant privilégié (RoamSwitchHelper) ne peut pas être établie.",
                details: """
                • Cause : l'exécution en arrière-plan n'est pas approuvée dans Éléments de connexion et extensions, l'assistant s'est arrêté après une mise à jour de macOS, ou l'app se trouve hors du dossier Applications (dans Téléchargements ou dans l'image disque).
                • Impact : les opérations nécessitant les droits root (changement de niveau de protection, confinement Air-Gap, réglages DNS, surveillance des fichiers critiques, etc.) ne peuvent pas s'exécuter.
                """,
                recommendation: """
                1. Choisissez « ⚠️ Approuver l'assistant… » dans le menu pour ouvrir les étapes d'approbation.
                2. Dans Réglages Système → Général → Éléments de connexion et extensions, activez RoamSwitchHelper sous Autoriser en arrière-plan.
                3. Vérifiez que RoamSwitch se trouve dans le dossier Applications.
                4. Si cela ne résout pas le problème, suivez faq_helper_troubleshooting.
                """
            ),
            LocalizedEntry(
                id: "alert_score_drop",
                title: "⚠️ Avertissement de dégradation de la sécurité du Mac",
                summary: "Envoyée par la patrouille autonome lorsque le score de sécurité tombe sous 80 ou que 4 points ou plus échouent (Pro).",
                details: """
                • Cause : un changement de réglages ou d'environnement, comme la désactivation de FileVault ou du pare-feu, un port dangereux exposé, ou une protection arrêtée.
                • Critères : score inférieur à 80, ou 4 points ou plus en échec.
                """,
                recommendation: """
                1. Ouvrez le rapport d'audit depuis le menu (ou utilisez l'outil MCP `get_security_report`).
                2. Traitez les points marqués ⚠️ en suivant les étapes de correction affichées.
                """
            ),
        ]
    }

    // MARK: - Alerts: malware, containment, audit

    private static func alertsFrMalware() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "alert_quarantined_download",
                title: "🚨 Fichier téléchargé dangereux mis en quarantaine",
                summary: "Affichée lorsqu'un fichier enregistré depuis un navigateur, Mail ou une app de chat contenait une menace et a été déplacé vers le coffre de quarantaine (« échec de la quarantaine » s'affiche si le déplacement n'a pas réussi).",
                details: """
                • Cause : le fichier téléchargé contenait un malware, un cheval de Troie, un shell inversé ou similaire.
                • Défense automatique : déplacé vers `~/Library/Application Support/RoamSwitch/Quarantine/` afin qu'il ne puisse pas s'exécuter. Si la vérification de signature statique l'a signalé mais pas ClamAV, la notification mentionne un possible faux positif.
                """,
                recommendation: """
                1. Si la quarantaine a réussi, le fichier ne peut pas s'exécuter.
                2. Ouvrez « 📦 Gérer les fichiers en quarantaine… » et choisissez « Supprimer définitivement » si vous ne le reconnaissez pas.
                3. N'utilisez « Restaurer » ou « Exclure et restaurer » que pour des faux positifs certains.
                4. Si la quarantaine a échoué, supprimez manuellement le fichier au chemin indiqué dans la notification.
                """
            ),
            LocalizedEntry(
                id: "alert_eicar_test_signature",
                title: "🧪 Signature de test EICAR détectée (inoffensive) — enregistrée uniquement dans l'historique des notifications",
                summary: "Explique comment est traité le fichier de test EICAR inoffensif utilisé pour vérifier les logiciels antivirus. Ce n'est pas une vraie menace, donc aucune bannière ne s'affiche et rien n'est mis en quarantaine ni bloqué ; il est simplement enregistré dans l'historique des notifications.",
                details: """
                • S'applique à : la Protection Web et E-mail, les analyses rapides/de dossier ClamAV, ainsi que l'analyse planifiée de la patrouille de la même manière.
                • Comportement : le fichier reste où il est. « Signature de test EICAR détectée (inoffensive) » est enregistré dans « 🔔 Historique des notifications… ».
                • Raison : des bannières d'avertissement pour des non-menaces enfouiraient les alertes réellement importantes.
                """,
                recommendation: """
                1. Aucune action n'est nécessaire. Si vous avez placé le fichier à des fins de test, supprimez-le après avoir confirmé le résultat.
                2. Vous pouvez confirmer que l'analyse fonctionne en vérifiant la présence de cet enregistrement dans l'historique des notifications.
                """
            ),
            LocalizedEntry(
                id: "alert_pickle_model",
                title: "⚠️ Téléchargement d'un modèle d'IA au format Pickle détecté",
                summary: "Affichée lorsqu'un fichier modèle d'IA `.pkl` / `.pickle` / `.pt` est téléchargé. Le format Pickle peut exécuter du code arbitraire par le simple fait d'être chargé.",
                details: """
                • Cause : un fichier modèle a été enregistré depuis Hugging Face, Civitai ou similaire.
                • Défense automatique : avertissement uniquement (le fichier n'est pas mis en quarantaine).
                """,
                recommendation: """
                1. Ne chargez pas de modèles sauf s'ils proviennent d'une source officielle de confiance.
                2. Si possible, utilisez le même modèle au format `.safetensors` ou `.gguf`.
                """
            ),
            LocalizedEntry(
                id: "alert_ransomware_activity",
                title: "🚨 DÉFENSE AUTOMATIQUE CRITIQUE : activité de rançongiciel bloquée",
                summary: "La notification urgente et la fenêtre d'urgence affichées lorsqu'un fichier leurre (canari) a été modifié, supprimé ou renommé et que le confinement Air-Gap, l'arrêt du partage et la mise en pause du processus suspect ont été déclenchés.",
                details: """
                • Cause : un processus tel qu'un rançongiciel tentant de chiffrer ou de détruire des fichiers dans vos dossiers utilisateur (ou l'exécution d'une simulation).
                • Défense automatique : tout le trafic coupé plus le Wi-Fi désactivé, SMB / SSH / Partage d'écran arrêtés, et le processus suspect mis en pause (SIGSTOP). La fenêtre d'urgence montre si la coupure a réussi, le processus suspect, et les fichiers potentiellement affectés.
                """,
                recommendation: """
                1. Enregistrez votre travail en cours et quittez toutes les apps suspectes.
                2. Dans le Moniteur d'activité, recherchez les processus dont l'utilisation du CPU ou de l'écriture disque grimpe en flèche et forcez la fermeture de ceux que vous ne reconnaissez pas.
                3. Vérifiez les fichiers potentiellement affectés et vos sauvegardes (Time Machine, etc.).
                4. Une fois en sécurité, levez le confinement depuis la fenêtre d'urgence (le réseau est rétabli, le processus en pause repris, et les fichiers leurres régénérés).
                """
            ),
            LocalizedEntry(
                id: "alert_runtime_threat_airgap",
                title: "🚨 XProtect a détecté un malware — réseau coupé automatiquement",
                summary: "La fenêtre d'urgence et la notification affichées lorsque XProtect / XProtect Remediator d'Apple a condamné un fichier comme malware et que la coupure automatique liée à XProtect a engagé le confinement Air-Gap.",
                details: """
                • Cause : le moteur anti-malware d'Apple a jugé malveillant un fichier que vous avez téléchargé ou exécuté.
                • Défense automatique : tout le trafic coupé plus le Wi-Fi désactivé, rétabli automatiquement en 10 minutes maximum si non levé. Le processus détecteur, la catégorie et le message de détection d'Apple sont enregistrés.
                """,
                recommendation: """
                1. Identifiez les fichiers ou apps que vous venez de télécharger ou d'exécuter et supprimez-les.
                2. Effectuez une analyse ClamAV et l'audit de sécurité, et vérifiez les enregistrements de démarrage automatique (LaunchAgents) à la recherche de quoi que ce soit de suspect.
                3. Une fois en sécurité, levez le confinement depuis la fenêtre d'urgence.
                4. L'état est également disponible via l'outil MCP `get_runtime_threat_status`.
                """
            ),
            LocalizedEntry(
                id: "alert_gatekeeper_block",
                title: "🛡️ Gatekeeper a empêché l'exécution d'une app non signée",
                summary: "Une notification indiquant que Gatekeeper de macOS a empêché le lancement d'une app sans signature ni notarisation. Pas de coupure automatique.",
                details: """
                • Cause : vous avez tenté d'ouvrir une app non signée provenant d'Internet ou votre propre version de développement.
                • Défense automatique : aucune (notification uniquement). La coupure liée à XProtect ne s'engage que lorsque XProtect détecte réellement un malware.
                """,
                recommendation: """
                1. Si vous la reconnaissez (par exemple votre propre version), aucune action n'est nécessaire.
                2. Sinon, vérifiez l'autorité de signature avec « Analyser la sécurité du fichier/de l'app… » et supprimez-la en cas de doute.
                """
            ),
            LocalizedEntry(
                id: "alert_clickfix_command",
                title: "🚨 Exécution de commande suspecte détectée / ⚠️ Commande suspecte détectée dans le presse-papiers",
                summary: "Affichée lorsqu'une commande correspondant à la technique ClickFix a été exécutée dans Terminal (détectée depuis l'historique du shell) ou copiée dans le presse-papiers.",
                details: """
                • Cause : vous avez été amené à une fausse vérification ou une fausse page d'erreur disant « exécutez cette commande pour résoudre le problème ». Les lignes de shell inversé et le contenu décodé en Base64 envoyé directement dans un shell ou osascript sont signalés.
                • Défense automatique (exécutée dans Terminal, Pro, désactivée par défaut) : confinement Air-Gap (le Wi-Fi n'est pas désactivé), rétabli automatiquement en 10 minutes maximum.
                • Défense automatique (copiée, activée par défaut) : le presse-papiers est vidé immédiatement.
                """,
                recommendation: """
                1. Si vous l'avez seulement copiée, fermez cette page Web et ne collez ni n'exécutez rien.
                2. Si vous l'avez exécutée, vérifiez que votre trousseau, vos mots de passe enregistrés dans le navigateur et vos portefeuilles de cryptomonnaies sont en sécurité, et changez les mots de passe importants depuis un autre appareil de confiance.
                3. Vérifiez les enregistrements de démarrage automatique (LaunchAgents / Daemons) à la recherche de quoi que ce soit de suspect et lancez une analyse ClamAV.
                """
            ),
            LocalizedEntry(
                id: "alert_new_persistence_item",
                title: "🚨 Nouvel enregistrement de démarrage automatique détecté",
                summary: "Affichée lorsqu'un nouveau LaunchAgent / LaunchDaemon a été enregistré et jugé suspect (lance directement un interpréteur de script, possède une signature invalide, etc.).",
                details: """
                • Cause : un malware tel qu'un voleur d'informations s'enregistrant pour survivre aux redémarrages, ou un installateur d'app en ajoutant un.
                • Défense automatique : notification uniquement (l'enregistrement lui-même ne peut pas être empêché). La notification affiche le chemin du plist et la raison.
                """,
                recommendation: """
                1. Vérifiez si vous venez d'installer vous-même une app. Si oui, aucune action n'est nécessaire.
                2. Sinon, supprimez le plist affiché dans la notification ainsi que le script ou l'app qu'il lance.
                3. Redémarrez ensuite le Mac et effectuez une analyse ClamAV.
                """
            ),
            LocalizedEntry(
                id: "alert_docker_risk",
                title: "⚠️ Configuration de conteneur Docker risquée détectée",
                summary: "Vous informe qu'un conteneur démarré avec `--privileged` ou avec `docker.sock` monté vient de démarrer.",
                details: """
                • Cause : les conteneurs privilégiés et les montages du socket Docker permettent à un conteneur de contrôler l'hôte, créant un risque d'évasion de conteneur.
                • Défense automatique : aucune (notification uniquement).
                """,
                recommendation: """
                1. Si c'est intentionnel (par exemple un agent de surveillance), aucune action n'est nécessaire.
                2. Sinon, vérifiez le conteneur avec `docker ps` et `docker inspect` et arrêtez-le.
                """
            ),
            LocalizedEntry(
                id: "alert_critical_file_tampering",
                title: "🚨 Altération d'un fichier système critique détectée",
                summary: "Affichée lorsqu'une modification, une suppression ou un nouveau fichier est détecté parmi les fichiers critiques comme sudoers, la configuration SSH, PAM, hosts, ou les authorized_keys de root.",
                details: """
                • Cause : un changement de configuration par un administrateur (`sudo visudo`, modification des réglages SSH), un changement effectué par un logiciel, ou un attaquant élevant ses privilèges ou installant une porte dérobée.
                • Défense automatique : notification uniquement. Le nouvel état n'est jamais accepté automatiquement comme légitime.
                • Lié : « La détection d'altération des fichiers critiques ne fonctionne pas » signifie que les analyses ont échoué de manière répétée car l'assistant privilégié était inaccessible.
                """,
                recommendation: """
                1. Vérifiez si vous ou un administrateur avez modifié les fichiers indiqués dans la notification.
                2. Sinon, recherchez des entrées `NOPASSWD` dans `/etc/sudoers`, des clés inconnues dans `authorized_keys` et similaires, et supprimez-les.
                3. Changez le mot de passe administrateur et lancez l'audit de sécurité.
                """
            ),
            LocalizedEntry(
                id: "alert_log_audit_anomaly",
                title: "🔔 Audit des journaux : motifs anormaux détectés",
                summary: "Envoyée par l'audit automatique des journaux lorsqu'il trouve des motifs de journal jamais vus sur ce Mac ([nouveau]) ou des journaux bien plus fréquents que d'habitude ([pic z=…]).",
                details: """
                • Cause : généralement des changements attendus liés au branchement d'un nouvel appareil ou à des mises à jour d'apps ou de macOS, mais parfois des tentatives de connexion suspectes ou une activité de processus inconnue.
                • Contenu : la répartition du nombre, jusqu'à 3 vraies lignes de journal, la progression de l'apprentissage (par exemple apprentissage de la fréquence en cours : 2/3 observations), et une explication en langage clair.
                • Défense automatique : aucune (notification uniquement).
                """,
                recommendation: """
                1. S'il n'y a que de nouveaux motifs et aucune app ou adresse IP inconnue, aucune action n'est nécessaire.
                2. Si un pic de fréquence coïncide avec quelque chose que vous n'avez pas fait, ouvrez « 📜 Audit des journaux de sécurité Mac… » pour plus de détails.
                3. En cas de doute, utilisez « Copier les éléments pour consultation IA » pour interroger un assistant IA.
                """
            ),
            LocalizedEntry(
                id: "alert_secret_in_clipboard",
                title: "🔑 Clé confidentielle détectée dans le presse-papiers",
                summary: "Vous informe qu'une clé API ou une clé privée (OpenAI, Anthropic, GitHub, AWS, etc.) se trouve dans le presse-papiers.",
                details: """
                • Cause : vous avez copié une clé API, un jeton ou une clé privée.
                • Défense automatique : notification uniquement (le presse-papiers n'est pas vidé).
                """,
                recommendation: """
                1. Faites attention à ne pas la coller par erreur dans un site Web ou un chat IA.
                2. Une fois terminé, copiez un autre texte pour l'écraser.
                3. Si vous l'avez partagée par erreur, révoquez-la et réémettez-la immédiatement dans la console du service.
                """
            ),
            LocalizedEntry(
                id: "alert_airgap_failed",
                title: "🚨 Échec de la coupure réseau automatique",
                summary: "Un avertissement urgent affiché lorsqu'une coupure d'urgence (rançongiciel, usurpation ARP, détection XProtect, ClickFix, etc.) a été tentée mais que le blocage complet pf n'a pas pu être appliqué.",
                details: """
                • Cause : l'assistant privilégié n'a pas répondu (non approuvé, arrêté, ou délai dépassé). Affichée après 3 tentatives échouées.
                • État actuel : le trafic entrant peut être bloqué par le pare-feu applicatif, mais le trafic sortant n'a pas été arrêté.
                """,
                recommendation: """
                1. Désactivez immédiatement le Wi-Fi ou débranchez le câble réseau.
                2. Gérez la menace (fermez les processus, lancez des analyses).
                3. Vérifiez ensuite l'état de l'assistant (faq_helper_troubleshooting).
                """
            ),
        ]
    }

    // MARK: - Settings

    private static func settingsFr() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "set_trusted_networks",
                title: "Réseaux enregistrés & niveaux de protection par réseau",
                summary: "Enregistrez le réseau actuel comme Domicile, Travail, Partage de connexion, etc., et définissez le niveau de protection de chaque réseau (Approuvé / Équilibré / Verrouillage maximal).",
                details: """
                • Enregistrer : Enregistrer le réseau actuel → Enregistrer comme « Domicile » (Approuvé) / Enregistrer sous 'Travail' (Équilibré) / Enregistrer sous 'Partage de connexion' (Équilibré) / Enregistrer avec un nom personnalisé…. Les réseaux sont identifiés par l'adresse MAC de la passerelle.
                • Changer de niveau : sélectionnez le réseau sous « Réseau actuel : … » ou « Réseaux enregistrés (n) » et choisissez 🟢 / 🟡 / 🔴.
                • Renommer ou retirer : Renommer…, Désenregistrer, ou Supprimer.
                """,
                recommendation: "Domicile en tant que 🟢 Approuvé et Travail ou Partage de connexion en tant que 🟡 Équilibré fonctionnent bien. Il est plus sûr de laisser un Wi-Fi de bureau partagé non enregistré, sous Verrouillage maximal."
            ),
            LocalizedEntry(
                id: "set_away_default_level",
                title: "Protection par défaut en déplacement (niveau pour les réseaux non enregistrés)",
                summary: "Choisit le niveau de protection appliqué automatiquement lorsque vous rejoignez un réseau que vous n'avez pas enregistré. Initialement 🔴 Verrouillage maximal.",
                details: """
                • Réglage : « Protection par défaut en déplacement : … » dans le menu, puis 🟢 Approuvé / 🟡 Équilibré / 🔴 Verrouillage maximal.
                • Affecte aussi les fonctions conditionnées par la présence sur un réseau non fiable, comme la Protection DNS contre les menaces (déplacement uniquement), la connexion VPN automatique, l'épinglage ARP/NDP de la passerelle, et la désactivation automatique du Bluetooth.
                """,
                recommendation: "Si vous n'utilisez pas de services de partage ou d'AirDrop en déplacement, il est fortement recommandé de le laisser sur Verrouillage maximal."
            ),
            LocalizedEntry(
                id: "set_manual_override",
                title: "Dérogation manuelle & protection contre l'oubli de rétablissement",
                summary: "Définissez temporairement un niveau de protection à la main pour une durée choisie. Il revient à la détection automatique une fois le délai écoulé ou le réseau changé, afin que vous n'oubliiez pas de rétablir la protection.",
                details: """
                • Réglage : Dérogation manuelle → un niveau (🟢 / 🟡 / 🔴) → une durée.
                • Durées : Jusqu'à la déconnexion (Recommandé), Pendant 1 heure, Pendant 4 heures, Jusqu'à annulation manuelle.
                • Annuler : Dérogation manuelle → Revenir à la détection automatique, ou « 🔄 Annuler la dérogation manuelle (Auto) » en haut du menu.
                • Lever un confinement Air-Gap annule aussi toute dérogation manuelle.
                """,
                recommendation: "Pour assouplir temporairement la protection lors d'une présentation ou d'un travail de développement, utilisez Jusqu'à la déconnexion ou Pendant 1 heure afin de ne jamais rester sans protection en déplacement."
            ),
            LocalizedEntry(
                id: "set_pro_default_guards",
                title: "Protections activées automatiquement avec Pro, et protections optionnelles",
                summary: "Lors de la première activation d'une licence Pro, les principales protections de défense autonome sont activées automatiquement. Ensuite, le choix d'activation/désactivation que vous faites pour chaque protection est respecté.",
                details: """
                • Activées automatiquement (une fois, lors de la première activation de Pro) : blocage automatique des ports d'écoute inconnus, détection par fichiers leurres de rançongiciel, blocage automatique à la détection d'usurpation ARP, déconnexion automatique lors d'une détection de malware par XProtect, audit automatique des journaux, et surveillance périodique de l'altération des fichiers système critiques. Lorsque les coupures ARP et XProtect sont activées, un avis unique explique la fonction.
                • Activées par défaut avec Pro : Protection Web et E-mail, et surveillance des enregistrements de démarrage automatique (LaunchAgent/Daemon).
                • Désactivées par défaut (optionnelles) : blocage automatique ClickFix, détection des risques Docker, protection physique du port BadUSB, blocage automatique du stockage USB, épinglage ARP/NDP de la passerelle, tunnel VPN, désactivation automatique du Bluetooth, et vérification active des vulnérabilités. Le fournisseur de la Protection DNS contre les menaces est votre choix.
                • Activée par défaut même dans l'édition gratuite : protection du presse-papiers (clés API et commandes ClickFix).
                • Les protections ajoutées dans des versions ultérieures reçoivent leur propre valeur par défaut, une seule fois, pour les utilisateurs Pro existants. Si la licence expire, les protections réservées à Pro sont désactivées.
                """,
                recommendation: "Après avoir activé Pro, vérifiez les marques ✅ dans le menu. Laissez désactivées les protections qui ne correspondent pas à votre usage (par exemple Docker si vous ne l'utilisez pas), et activez ce dont vous avez besoin (par exemple le VPN si vous utilisez souvent le Wi-Fi public)."
            ),
            LocalizedEntry(
                id: "set_usb_whitelist",
                title: "Paramètres de protection USB / BadUSB (liste d'autorisation des claviers & permissions de stockage) (Pro)",
                summary: "Gérez les claviers de confiance et les appareils de stockage USB professionnels dans des listes d'autorisation, et définissez la permission de stockage sur Lecture seule ou Lecture-écriture.",
                details: """
                • Ouvrir : « Surveillance des ports et appareils » → « Paramètres de protection USB / BadUSB… ».
                • Claviers : ajoutés lorsque vous choisissez « Faire confiance et autoriser » dans la fenêtre d'approbation ; retirables ici.
                • Stockage : ajouté lorsque vous choisissez « Autoriser en lecture-écriture » ou « Autoriser en lecture seule » dans la boîte de dialogue de connexion ; modifiez la permission ou retirez-le ici. Si vous modifiez un appareil non connecté, débranchez-le et rebranchez-le pour que le changement s'applique.
                • L'analyse ClamAV à la connexion continue de s'exécuter pour les appareils autorisés avant qu'ils ne soient connectés en lecture-écriture.
                """,
                recommendation: "Sur les Mac traitant des données sensibles, enregistrer le stockage en Lecture seule réduit considérablement le risque de fuite de données."
            ),
            LocalizedEntry(
                id: "set_watched_folders",
                title: "Dossiers surveillés par la Protection Web et E-mail (Pro)",
                summary: "Ajoutez, retirez ou réinitialisez les dossiers surveillés par la protection des téléchargements (surveillance FSEvents et analyses automatiques).",
                details: """
                • Dossiers par défaut : `~/Downloads`, `~/Desktop`, `~/Documents`, ainsi que le dossier de téléchargement de Mail.
                • Modifier : « Protection Web et E-mail (Analyse auto des téléchargements) (Pro) » → « 📁 Dossiers surveillés » → « ⚙️ Gérer les dossiers surveillés… ».
                • Réinitialiser : « 🔄 Rétablir par défaut ».
                • L'historique récent des analyses (jusqu'à 5 affichés) et « Effacer l'historique des analyses » se trouvent dans le même menu.
                """,
                recommendation: "Si vous avez modifié l'emplacement où votre navigateur ou vos apps de chat enregistrent les fichiers, assurez-vous d'ajouter ce dossier."
            ),
            LocalizedEntry(
                id: "set_dns_policy",
                title: "Fournisseur et politique de la Protection DNS contre les menaces (Pro)",
                summary: "Choisissez le fournisseur DNS sécurisé qui bloque les domaines malveillants, et quand il s'applique (déplacement uniquement / toujours).",
                details: """
                • Réglage : « Protection DNS contre les menaces (Bloquer malwares et C2) (Pro) » → « Fournisseur DNS : … » et « ⚙️ Politique d'application ».
                • Fournisseurs : Quad9 (Blocage auto des malwares et C2) / Cloudflare Security (1.1.1.2) / AdGuard DNS (Bloquer menaces et pubs) / CleanBrowsing (Filtre de sécurité).
                • Politique : « Wi-Fi non fiable uniquement (Recommandé) » ou « Toujours actif sur tous les réseaux (y compris fiables) ». Avec le déplacement uniquement, les réglages DNS d'origine sont rétablis sur les réseaux fiables.
                • L'élément d'état dans le menu ouvre les réglages réseau afin que vous puissiez confirmer ce qui est appliqué.
                """,
                recommendation: "Pour la plupart des personnes, Quad9 avec la politique réservée au déplacement est un bon choix. Évitez la politique toujours active si vous avez besoin d'un DNS interne d'entreprise."
            ),
            LocalizedEntry(
                id: "set_link_guard_modes",
                title: "Mode, mise à jour automatique, extension système & liste d'autorisation de la Protection des liens (Pro)",
                summary: "Configurez le mode de la Protection des liens, la mise à jour automatique de la liste de menaces, l'état d'approbation de l'extension système, et la manière d'autoriser des sites bloqués par erreur.",
                details: """
                • Mode : « Protection des liens (détection des connexions d'hameçonnage) (Pro) » → « Désactivé », « Avertir seulement (ne jamais bloquer) », ou « Bloquer automatiquement les sites d'hameçonnage manifestes (recommandé) ». Le mode Avertissement ne fonctionne que si l'extension système est active.
                • Mise à jour automatique : cliquez sur « Mise à jour auto : activée (réception seule) » pour la désactiver. Elle continue de fonctionner avec les données intégrées et la détection d'homographe. La version de la liste et le nombre de domaines s'affichent dans le menu.
                • Point d'application : « Application : extension système (compatible DoH) », « Application : solution de repli hosts », « Activation de l'extension système… », ou une erreur d'extension système. Pendant que l'approbation est en attente, « Approuver l'extension système (ouvrir Réglages Système)… » s'affiche.
                • Autoriser/bloquer : « Autoriser une fois (5 min) » sur une notification de blocage autorise le site pendant 5 minutes. Les choix Autoriser/Bloquer dans le panneau d'avertissement sont mémorisés.
                """,
                recommendation: "Approuvez l'extension système et utilisez le blocage automatique avec la mise à jour automatique activée pour la protection la plus efficace."
            ),
            LocalizedEntry(
                id: "set_vpn_backend",
                title: "Réglages de backend du tunnel VPN (WireGuard / Tailscale) (Pro)",
                summary: "Choisissez le backend du tunnel VPN, importez une configuration WireGuard, sélectionnez un nœud de sortie Tailscale, et configurez le coupe-circuit.",
                details: """
                • Ouvrir : « Surveillance des ports et appareils » → « Tunnel VPN (anti-MITM sur réseaux non fiables) (Pro) » → « Backend ».
                • WireGuard : « Importer une config WireGuard (.conf)… » → « Connexion auto sur réseaux non fiables ». Également « Se connecter », « Déconnecter » et « Supprimer la config ». L'état affiche par exemple « 🟢 Connecté (dernière poignée de main il y a N s) », et le coupe-circuit est toujours actif. Si `wireguard-tools` est absent, des instructions d'installation s'affichent.
                • Tailscale : choisissez un nœud sous « Exit-Node » (« (aucun — protection désactivée) » pour désactiver). Également « Actualiser les nœuds » et « Actualiser l'état ». « Kill-switch : activé (anti-fuite) » est optionnel et désactivé par défaut.
                • Exemples de lignes d'état : « ⚪️ En veille (connexion auto sur les réseaux non fiables) », « 🟡 Le nœud de sortie sélectionné est hors ligne ».
                """,
                recommendation: "Si vous utilisez déjà Tailscale, choisissez Tailscale ; sinon, la configuration WireGuard de votre fournisseur VPN est l'option la plus simple."
            ),
            LocalizedEntry(
                id: "set_language",
                title: "Langue d'affichage (réponses de l'app et de MCP)",
                summary: "RoamSwitch peut s'afficher dans 10 langues (日本語, English, 简体中文, 繁體中文, 한국어, Deutsch, Français, Español, Italiano, Português). Les réponses du serveur MCP et cette base de connaissances utilisent la même langue.",
                details: """
                • Réglage : choisissez dans le menu sous « Langue / Language ». « Suivre les réglages système » utilise la langue préférée de macOS.
                • MCP : le serveur MCP lit la langue choisie dans l'app. En cas de suivi du système et si la langue système n'est pas prise en charge, les réponses sont en anglais.
                • L'outil `get_app_help` accepte un argument `language` pour choisir la langue de réponse à chaque appel. Les recherches trouvent des correspondances de mots-clés dans n'importe quelle langue.
                """,
                recommendation: "Pour discuter avec votre assistant IA dans une langue différente de celle de l'app, utilisez l'argument `language` de `get_app_help`."
            ),
        ]
    }

    // MARK: - Troubleshooting: setup

    private static func troubleshootingFrSetup() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "faq_free_vs_pro",
                title: "Différence entre l'édition gratuite et la version Pro à vie",
                summary: "L'édition gratuite inclut, sans limite de temps, le basculement automatique de la protection selon le réseau, l'audit de sécurité à 18 points, ainsi qu'un ensemble d'outils de vérification manuelle. Pro débloque le confinement automatique, les défenses en temps réel et les avertissements de patrouille.",
                details: """
                [Gratuit]
                • Basculement automatique du filtre de paquets PF à 3 niveaux par réseau, avec arrêt et rétablissement automatiques des services de partage et d'AirDrop
                • Audit de sécurité Mac (18 points), état de XProtect, et analyse de sécurité de fichier/app
                • Listes des ports exposés et des appareils USB
                • Audit de sécurité des liens, audit manuel des fuites de secrets/clés API, protection du presse-papiers
                • Vérification CVE des paquets, vérification active des vulnérabilités, Audit des journaux de sécurité Mac, historique des notifications
                • Analyses ClamAV manuelles et gestion de la quarantaine
                • Intégration du serveur MCP
                [Pro à vie (achat unique 2 980 ¥ / 19,99 $, jusqu'à 2 Mac)]
                • Détection par fichiers leurres de rançongiciel avec Air-Gap, coupure automatique liée à XProtect, protection ClickFix
                • Blocage automatique des ports d'écoute inconnus, isolement des serveurs de développement
                • Blocage automatique d'usurpation ARP, épinglage ARP/NDP de la passerelle, tunnel VPN (WireGuard / Tailscale), avertissements de jumeau maléfique
                • Protection de clavier BadUSB, blocage automatique du stockage USB
                • Protection Web et E-mail (analyse auto, quarantaine, avertissements Pickle), Protection DNS contre les menaces, Protection des liens
                • Surveillance des enregistrements de démarrage automatique, détection des risques Docker, surveillance de l'altération des fichiers critiques, audit automatique des journaux
                • Désactivation automatique du Bluetooth, notifications de menace en temps réel, avertissements de patrouille, mises à jour des définitions et analyses planifiées, export CSV des journaux
                """,
                recommendation: "Choisissez Pro si vous avez besoin de confinement automatique, de défense en temps réel et de surveillance en arrière-plan."
            ),
            LocalizedEntry(
                id: "faq_homebrew_clamav",
                title: "Configurer ClamAV (analyse antivirus) et Homebrew",
                summary: "L'analyse antivirus utilise ClamAV, un logiciel open source installable avec Homebrew. Sans lui, l'intégration XProtect et toutes les fonctionnalités propres à RoamSwitch continuent de fonctionner.",
                details: """
                • Homebrew : le gestionnaire de paquets pour macOS (https://brew.sh/).
                • Étapes :
                  1. Exécutez dans Terminal la commande d'installation officielle de Homebrew (indiquée sur https://brew.sh/).
                  2. Exécutez `brew install clamav`. « 📥 Installer ClamAV via Homebrew… » dans le menu ouvre aussi des instructions.
                  3. Choisissez « 🛡️ ClamAV (Antivirus gratuit) » → « 🔄 Mettre à jour la base virale maintenant ».
                • Activés par ClamAV : analyse rapide (Téléchargements/Bureau), analyse de dossier, analyses dans la Protection Web et E-mail et pour le stockage USB, ainsi que l'analyse planifiée de la patrouille.
                • Sans ClamAV : le filtrage de paquets, la surveillance des ports, l'analyse de liens, la vérification de signature statique et plus continuent de fonctionner.
                """,
                recommendation: "Installez Homebrew et ClamAV si vous souhaitez que les téléchargements et le stockage USB soient analysés automatiquement."
            ),
            LocalizedEntry(
                id: "faq_blueutil_setup",
                title: "Désactivation automatique du Bluetooth (Pro) et configuration de blueutil",
                summary: "La désactivation automatique du Bluetooth en déplacement nécessite l'outil open source `blueutil`.",
                details: """
                • Contexte : macOS ne propose pas d'API publique permettant aux apps de basculer l'alimentation du Bluetooth, donc l'outil en ligne de commande `blueutil` est utilisé.
                • Étapes :
                  1. Exécutez `brew install blueutil` dans Terminal (ou utilisez « 📥 Installer blueutil via Homebrew… » dans le menu).
                  2. Activez « Surveillance des ports et appareils » → « Désactivation auto du Bluetooth sur réseaux non fiables (Pro) ».
                • Si non installé : rien d'autre n'est affecté, et le menu affiche « 🔵 Bluetooth auto-désactivation (non installé) ».
                """,
                recommendation: "Pour éviter le suivi radio et les vulnérabilités Bluetooth sur le Wi-Fi public, exécutez `brew install blueutil` et activez la fonction."
            ),
            LocalizedEntry(
                id: "faq_helper_troubleshooting",
                title: "Que faire lorsque « ⚠️ Assistant non connecté » apparaît",
                summary: "Étapes de récupération lorsque RoamSwitch ne peut pas communiquer avec l'outil assistant privilégié (RoamSwitchHelper).",
                details: """
                1. Choisissez « ⚠️ Approuver l'assistant… » dans le menu et suivez les étapes affichées.
                2. Ouvrez Réglages Système → Général → Éléments de connexion et extensions et assurez-vous que RoamSwitchHelper est activé sous Autoriser en arrière-plan.
                3. Vérifiez que RoamSwitch se trouve dans le dossier Applications (faq_install_location).
                4. Cliquez sur « Réessayer l'enregistrement de l'assistant » dans la fenêtre d'accueil.
                5. Si cela échoue toujours, exécutez `sudo killall RoamSwitchHelper` dans Terminal pour redémarrer l'assistant (launchd le relance automatiquement), puis relancez RoamSwitch.
                """,
                recommendation: "Si l'assistant cesse de répondre juste après une mise à jour de macOS, vérifiez d'abord l'interrupteur des Éléments de connexion, puis essayez `sudo killall RoamSwitchHelper`."
            ),
            LocalizedEntry(
                id: "faq_install_location",
                title: "Emplacement de l'app (lancée en dehors du dossier Applications)",
                summary: "macOS n'enregistre pas l'assistant privilégié pour une app se trouvant en dehors du dossier Applications, donc RoamSwitch doit être placé dans `/Applications` ou `~/Applications` et lancé depuis là.",
                details: """
                • Emplacements ne permettant pas l'enregistrement : Téléchargements ou Bureau, exécution depuis une image disque (.dmg) encore montée, ou lorsque Gatekeeper App Translocation a déplacé l'app vers un emplacement temporaire en lecture seule.
                • Guidage : l'accueil vérifie l'emplacement au lancement et propose « Déplacer vers Applications et relancer » ou « Ouvrir Applications dans le Finder ».
                • Après le déplacement : cliquez sur « Vérifier à nouveau » ou relancez, puis approuvez l'assistant.
                """,
                recommendation: "Faites glisser RoamSwitch depuis l'image disque vers le dossier Applications et lancez-le depuis là."
            ),
            LocalizedEntry(
                id: "faq_system_extension_approval",
                title: "Approuver l'extension système de la Protection des liens",
                summary: "Pour que la Protection des liens fonctionne au mieux (compatible DoH, mode Avertissement), l'extension système de filtrage de contenu doit être approuvée. Jusque-là, elle utilise la solution de repli /etc/hosts.",
                details: """
                • Étapes : « Protection des liens (détection des connexions d'hameçonnage) (Pro) » → « Approuver l'extension système (ouvrir Réglages Système)… » → Réglages Système → Général → Éléments de connexion et extensions, puis autorisez l'extension réseau de RoamSwitch.
                • Après l'approbation : le menu affiche « Application : extension système (compatible DoH) ».
                • Si une erreur d'extension système s'affiche : assurez-vous que l'app se trouve dans le dossier Applications, puis resélectionnez un mode de Protection des liens pour réessayer.
                • Cette méthode ne nécessite ni examen par l'App Store ni demande d'autorisation supplémentaire (signée Developer ID et notarisée).
                """,
                recommendation: "Approuvez l'extension système afin que la protection tienne même lorsque votre navigateur utilise le DNS sur HTTPS."
            ),
            LocalizedEntry(
                id: "faq_mcp_setup",
                title: "Configurer le serveur MCP (Claude Desktop, Claude Code et autres)",
                summary: "Comment enregistrer le serveur MCP intégré de RoamSwitch auprès d'un client IA compatible MCP.",
                details: """
                • Chemin du binaire : `/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`
                • Claude Desktop : ajoutez le chemin du binaire comme `command` sous `mcpServers` dans `~/Library/Application Support/Claude/claude_desktop_config.json`.
                • Claude Code : `claude mcp add roamswitch /Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`
                • Autres clients (Codex CLI et autres) : https://lafine.net/mcp-setup.html
                • Langue de réponse : suit le réglage « Langue / Language » de l'app. `get_app_help` accepte un argument `language` par appel.
                • La communication se fait uniquement en stdio local, sans rien envoyer à l'extérieur (seul `run_active_vuln_scan` envoie des sondes non destructives vers 127.0.0.1).
                """,
                recommendation: "Une fois enregistré, demandez à votre IA quelque chose comme « Vérifie l'état de sécurité de mon Mac avec RoamSwitch » et elle vous expliquera les résultats de l'audit."
            ),
        ]
    }

    // MARK: - Troubleshooting: operation

    private static func troubleshootingFrOperation() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "faq_network_cut_off",
                title: "Internet a soudainement cessé de fonctionner (confinement Air-Gap / niveau de protection)",
                summary: "L'Air-Gap d'urgence ou le Verrouillage maximal de RoamSwitch pourraient arrêter le trafic. Comment trouver la cause et lever le confinement.",
                details: """
                • Vérifier : recherchez une fenêtre d'urgence, et vérifiez l'historique des notifications pour des alertes comme DÉFENSE AUTOMATIQUE CRITIQUE, XProtect, usurpation ARP, ou exécution de commande suspecte. Le Wi-Fi peut aussi avoir été désactivé.
                • Lever le confinement : utilisez le bouton de levée dans la fenêtre d'urgence ou la notification. Le réseau et le Wi-Fi reviennent.
                • Rétablissement automatique : même sans lever le confinement, le filet de sécurité de l'assistant rétablit le réseau en 10 minutes. Aucune étape manuelle n'est nécessaire après une fermeture, un plantage, ou un redémarrage.
                • Juste après le démarrage : le trafic peut être restreint par la porte de démarrage pendant jusqu'à 90 secondes.
                • Autres causes : le Verrouillage maximal bloque le trafic entrant mais n'empêche pas l'utilisation sortante normale comme la navigation Web. Vérifiez aussi le coupe-circuit VPN (pendant que le tunnel est coupé), le résolveur de la Protection DNS contre les menaces, et les blocages de la Protection des liens.
                """,
                recommendation: "Lorsque le confinement se déclenche, lisez la notification qui l'a déclenché et levez-le une fois que vous avez confirmé que c'est sûr. Si une protection se déclenche souvent à tort, vous pouvez la désactiver individuellement depuis le menu."
            ),
            LocalizedEntry(
                id: "faq_quarantine_false_positive",
                title: "Restaurer un téléchargement mis en quarantaine par erreur",
                summary: "Comment restaurer votre propre script ou binaire de développement mis en quarantaine comme faux positif, et l'exclure des analyses.",
                details: """
                1. Ouvrez Protection contre les malwares → ClamAV → « 📦 Gérer les fichiers en quarantaine… ».
                2. Sélectionnez le fichier parmi les fichiers en quarantaine (le chemin d'origine, le nom de la menace et l'heure de mise en quarantaine sont affichés).
                3. Pour un faux positif certain, cliquez sur « Exclure et restaurer » : il retourne à son emplacement d'origine et ce chemin est exclu des analyses futures. Pour restaurer une seule fois, cliquez sur « Restaurer ».
                4. Pour annuler une exclusion, cliquez sur « Retirer l'exclusion » dans la liste des chemins exclus, dans la même fenêtre.
                5. Pour cesser de surveiller un dossier entier, ajustez « ⚙️ Gérer les dossiers surveillés… » sous Protection Web et E-mail.
                """,
                recommendation: "Si vous ne pouvez pas être certain qu'un fichier est sûr, ne le restaurez pas ; choisissez Supprimer définitivement."
            ),
            LocalizedEntry(
                id: "faq_eicar_test",
                title: "J'ai placé un fichier de test EICAR mais je n'ai reçu aucune notification",
                summary: "C'est voulu. La signature de test EICAR est un test inoffensif, donc aucune bannière ne s'affiche et rien n'est mis en quarantaine. La détection est enregistrée dans l'historique des notifications.",
                details: """
                • Comment le confirmer : vérifiez sous Audit de sécurité Mac → « 🔔 Historique des notifications… » la présence de « 🧪 Signature de test EICAR détectée (inoffensive) ».
                • Le fichier : reste où il est.
                • Pour tester le vrai chemin d'alerte : utilisez les simulations en bas de Protection contre les malwares (défense contre les rançongiciels, Air-Gap de détection de malware, détection des risques Docker).
                """,
                recommendation: "Supprimez le fichier EICAR une fois vos tests terminés."
            ),
            LocalizedEntry(
                id: "faq_dev_server_blocked",
                title: "Mon serveur de développement ou mon app de réception LAN n'est pas accessible depuis d'autres appareils",
                summary: "Le blocage automatique des ports d'écoute inconnus bloque peut-être un programme qui vient de commencer à exposer un port. Il reste accessible depuis le Mac lui-même.",
                details: """
                • Vérifier : recherchez dans l'historique des notifications « Port d'écoute inconnu automatiquement bloqué ».
                • Autoriser : utilisez le bouton « Autoriser » de la notification, ou Ports exposés → le port → l'écran d'audit des ports. L'autorisation s'applique de façon permanente, par exécutable.
                • Par rapport à l'isolement manuel : un port que vous avez isolé vous-même avec « Isoler le port » est rétabli avec « Désisoler » dans l'écran d'audit des ports.
                • Niveau de protection : sur un réseau en Verrouillage maximal, le pare-feu bloque entièrement les connexions entrantes. Pour autoriser l'accès depuis le réseau local, enregistrez ce réseau et réglez-le sur Équilibré ou Approuvé.
                """,
                recommendation: "Autorisez une fois les apps de réception LAN que vous utilisez régulièrement, comme LocalSend ou Syncthing, et elles ne seront plus jamais bloquées."
            ),
            LocalizedEntry(
                id: "faq_link_guard_false_block",
                title: "La Protection des liens bloque un site légitime / maintient une connexion en attente",
                summary: "Que faire lorsque la Protection des liens bloque un site par erreur ou le maintient en attente en mode Avertissement.",
                details: """
                • Autoriser temporairement : « Autoriser une fois (5 min) » sur la notification de blocage.
                • Autoriser définitivement : choisir « Autoriser » dans le panneau d'avertissement est mémorisé.
                • Une connexion en attente s'est bloquée d'elle-même : le mode Avertissement bloque s'il n'y a pas de réponse dans environ 8 secondes (échec en mode fermé). Ce résultat n'est pas mis en cache, donc recharger la page redemande.
                • Notification invisible : avec le style de notification bannière, les boutons peuvent être masqués, donc un panneau au premier plan s'affiche aussi. En mode Ne pas déranger, vérifiez l'historique des notifications.
                • Désactiver temporairement : basculez le mode sur « Avertir seulement (ne jamais bloquer) » ou « Désactivé ».
                """,
                recommendation: "Si un outil professionnel est bloqué à répétition, vérifiez que le domaine ne contient pas de faute de frappe ou de ressemblance suspecte avant de l'autoriser."
            ),
            LocalizedEntry(
                id: "faq_keyboard_blocked",
                title: "Mon clavier externe n'écrit pas (protection BadUSB)",
                summary: "La protection physique du port contre BadUSB bloque la saisie d'un clavier absent de la liste d'autorisation jusqu'à ce que vous l'approuviez.",
                details: """
                • Approuver : cliquez sur « Faire confiance et autoriser » dans la fenêtre « ⚠️ Périphérique USB / clavier inconnu détecté » (utilisez le clavier intégré ou le trackpad).
                • Fenêtre introuvable : débranchez et rebranchez l'appareil pour la faire réapparaître.
                • Stations d'accueil et commutateurs KVM : les appareils dotés d'une fonction clavier intégrée sont aussi couverts. Autorisez-les s'ils sont à vous.
                • Autorisation Accessibilité : le blocage de repli utilisé lorsque l'appareil ne peut pas être saisi de manière exclusive repose sur l'autorisation Accessibilité.
                • Révoquer : retirez-le dans « Paramètres de protection USB / BadUSB… ».
                """,
                recommendation: "N'autorisez pas un appareil qui a déclenché l'avertissement de frappe scriptée ; débranchez-le."
            ),
            LocalizedEntry(
                id: "faq_vpn_troubleshooting",
                title: "Le tunnel VPN ne se connecte pas / aucun trafic ne passe",
                summary: "Que vérifier lorsque le backend WireGuard ou Tailscale ne fonctionne pas.",
                details: """
                • WireGuard : confirmez que `brew install wireguard-tools` est installé et qu'une `.conf` est importée. Si l'état affiche « 🟡 Sans réponse (dernière poignée de main …) », vérifiez le serveur VPN ainsi que les clés et le point de terminaison de la configuration. Le coupe-circuit est activé, donc rien ne passe tant que le tunnel n'est pas établi.
                • Tailscale : confirmez que la CLI est installée et connectée (sinon le menu affiche « Connectez-vous d'abord à Tailscale ») et qu'un nœud de sortie est sélectionné. Si le nœud de sortie sélectionné est hors ligne, choisissez-en un autre.
                • Tailscale depuis l'App Store : le nœud de sortie ne peut pas être défini depuis l'extérieur de l'app, choisissez-le dans l'app Tailscale.
                • Coupe-circuit Tailscale : sur certains réseaux, il peut gêner la connectivité propre de Tailscale ; désactivez-le si vous ne pouvez pas vous connecter.
                • Se déconnecter automatiquement sur les réseaux fiables est un comportement attendu.
                """,
                recommendation: "Commencez par la ligne d'état dans le menu : la poignée de main pour WireGuard, l'état du nœud de sortie pour Tailscale."
            ),
            LocalizedEntry(
                id: "faq_log_audit_repeated_alerts",
                title: "Les notifications de l'audit des journaux n'arrêtent pas d'arriver",
                summary: "L'audit automatique des journaux apprend le comportement normal des journaux de ce Mac au fur et à mesure de son exécution. Les alertes augmentent juste après la configuration ou une mise à jour majeure et diminuent naturellement à mesure que l'apprentissage progresse.",
                details: """
                • Nouveaux motifs : une fois signalé, un motif devient connu et n'est plus renotifié pour le même contenu.
                • Pics de fréquence : l'apprentissage de chaque motif se termine après 3 observations ; ensuite, un volume normal ne déclenche pas d'alerte. Tant que la notification affiche encore quelque chose comme « apprentissage de la fréquence en cours : 2/3 observations », l'apprentissage se poursuit.
                • Causes courantes : mises à jour de macOS ou des apps, connexion de nouveaux appareils, charge élevée temporaire.
                • Pour l'arrêter : désactivez dans le menu « Audit automatique des journaux (apprend les nouveaux motifs et anomalies de fréquence selon un calendrier) (Pro) » (l'audit manuel des journaux reste disponible).
                """,
                recommendation: "Tant que les alertes ne contiennent pas de nom d'app inconnu, d'adresse IP ou d'échecs sudo, il est acceptable d'attendre un peu."
            ),
            LocalizedEntry(
                id: "faq_zero_telemetry",
                title: "Conception de confidentialité Zero Telemetry",
                summary: "RoamSwitch et son serveur MCP n'envoient jamais de résultats d'audit, d'URL, d'informations de port, de journaux ou de contenu de fichier à des serveurs externes. Le seul trafic réseau correspond aux exceptions explicites ci-dessous.",
                details: """
                • Entièrement local : l'audit de sécurité, la surveillance des ports, l'analyse de liens, l'audit des secrets, l'audit des journaux, l'analyse antivirus et la communication MCP restent tous sur l'appareil.
                • Exceptions :
                  - L'activation et la désactivation de licence (uniquement lorsque vous agissez) et l'ouverture de la page d'achat
                  - Les vérifications de mise à jour de l'app (Sparkle)
                  - Les mises à jour des définitions ClamAV (`freshclam`)
                  - Les téléchargements quotidiens de la liste de menaces de la Protection des liens, des cartes de CVE des paquets, et des cartes de CVE de vulnérabilités (en réception seule, vérifiées par signature, sans envoi d'identifiants ; la mise à jour automatique de la Protection des liens peut être désactivée)
                  - Le trafic normal vers les fournisseurs VPN et DNS sécurisé que vous configurez
                  - Les sondes non destructives de la vérification active des vulnérabilités vers 127.0.0.1 (ce Mac lui-même)
                • Il n'existe nulle part dans le code de télémétrie ni de collecte d'utilisation. Même le rappel d'approbation de l'assistant fonctionne uniquement à partir d'un compteur sur l'appareil.
                """,
                recommendation: "Il est sûr à utiliser dans des environnements professionnels hautement confidentiels et des configurations de développement personnelles sans craindre de fuite de données."
            ),
        ]
    }
}
