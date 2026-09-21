// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.50 (build 107).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

// Spanish (es) content for `RoamSwitchKnowledgeBase`.
// Translated from the English source (`RoamSwitchKnowledgeBaseContent_en.swift`).
// Every entry id here must also exist in every other
// `RoamSwitchKnowledgeBaseContent_<lang>.swift` file.
extension RoamSwitchKnowledgeBase {
    static func labelsEs() -> MarkdownLabels {
        return MarkdownLabels(
            featuresTitle: "Especificación completa de funciones y arquitectura de RoamSwitch",
            featuresIntro: "Cómo funciona cada función de seguridad de RoamSwitch, con sus valores predeterminados y limitaciones.",
            alertsTitle: "Catálogo de alertas y notificaciones de RoamSwitch",
            alertsIntro: "Cada aviso de notificación, advertencia y ventana de emergencia que muestra RoamSwitch, con su causa, la defensa automática aplicada y las acciones recomendadas paso a paso.",
            settingsTitle: "Guía de ajustes y funcionamiento de RoamSwitch",
            settingsIntro: "Instrucciones paso a paso para cada ajuste, interruptor, lista de permitidos y política de RoamSwitch.",
            troubleshootingTitle: "Solución de problemas y preguntas frecuentes de RoamSwitch",
            troubleshootingIntro: "Respuestas oficiales sobre preguntas frecuentes, permisos y aprobaciones, instalación de Homebrew / ClamAV / blueutil, falsos positivos y el diseño de privacidad.",
            summary: "Resumen",
            overview: "Descripción general",
            detailsHeading: "Detalles y causas",
            adviceHeading: "Qué hacer",
            recommendation: "Recomendación",
            bestPractice: "Práctica recomendada",
            advice: "Consejo"
        )
    }

    static func contentEs() -> [LocalizedEntry] {
        var list: [LocalizedEntry] = []
        list.append(contentsOf: featuresEsNetwork())
        list.append(contentsOf: featuresEsMalware())
        list.append(contentsOf: featuresEsAudit())
        list.append(contentsOf: alertsEsNetwork())
        list.append(contentsOf: alertsEsMalware())
        list.append(contentsOf: settingsEs())
        list.append(contentsOf: troubleshootingEsSetup())
        list.append(contentsOf: troubleshootingEsOperation())
        return list
    }

    // MARK: - Features: network & devices

    private static func featuresEsNetwork() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_network_autoswitch",
                title: "Cambio automático de seguridad de red y filtro de paquetes PF (3 niveles)",
                summary: "Compara la dirección MAC de la puerta de enlace de la red actual con tus redes registradas y aplica automáticamente el nivel de protección de esa red. Las redes no registradas reciben el nivel de Protección predeterminada fuera de casa (inicialmente Bloqueo máximo). Disponible en la edición gratuita.",
                details: """
                • 🟢 De confianza (Abierta - Desbloqueada): por ejemplo en casa. Cortafuegos desactivado; se permiten los servicios compartidos (SSH / SMB / Compartir pantalla) y AirDrop.
                • 🟡 Equilibrado (Cortafuegos y sigilo): por ejemplo en el trabajo o al compartir internet. El filtro de paquetes PF y el modo sigiloso bloquean los sondeos externos mientras los servicios compartidos siguen disponibles.
                • 🔴 Bloqueo máximo (Compartir y AirDrop desactivados): cafeterías, Wi-Fi público, redes no registradas. Se bloquea todo el tráfico entrante, se detienen los demonios de compartición y se desactiva AirDrop.
                • Cómo decide: al cambiar de red, se lee la dirección MAC de la puerta de enlace y se compara con las redes registradas. Los eventos de ruta que no cambian la puerta de enlace (renovación DHCP, itinerancia Wi-Fi) no provocan una reevaluación completa.
                • Internamente: el asistente privilegiado `RoamSwitchHelper` (mediante XPC) gestiona un ancla `pfctl` dedicada, por lo que los paquetes se descartan a nivel de kernel.
                • Anulación manual: desde Anulación manual puedes elegir, por nivel, Hasta la desconexión (Recomendado), Durante 1 hora, Durante 4 horas, o Hasta que se desactive manualmente (consulta set_manual_override).
                """,
                recommendation: "Registra tu casa y otras oficinas seguras mediante «Registrar red actual», y deja que el Bloqueo máximo se aplique automáticamente en cualquier otro lugar."
            ),
            LocalizedEntry(
                id: "feat_network_history_guard",
                title: "Aprendizaje del historial de red y detección de gemelo malvado (Wi-Fi similar) (Pro)",
                summary: "Aprende, solo en este Mac, qué direcciones MAC de puerta de enlace ha usado cada SSID Wi-Fi, y advierte de un posible gemelo malvado (punto de acceso falso) cuando te unes a un SSID desconocido cuyo nombre se parece sospechosamente a una red usada antes.",
                details: """
                • Qué se aprende: para cada SSID, las direcciones MAC de puerta de enlace observadas (hasta 8 por SSID, para Wi-Fi en malla), guardadas en `~/Library/Application Support/RoamSwitch/network_history.json`. Hasta 200 SSID, eliminando primero el más antiguo. No se envía nada fuera del dispositivo.
                • Prueba de similitud: distancia de edición (Levenshtein) sin distinguir mayúsculas de minúsculas. Los nombres de menos de 6 caracteres quedan exentos, y la distancia permitida crece lentamente con la longitud (1 a 2 caracteres), de modo que SSID genéricos habituales como «ASUS» o «TP-Link_5G» que coincidan por azar nunca activan esto.
                • Control de falsos positivos: el mismo hardware de puerta de enlace que difunde un segundo SSID (red de invitados, router renombrado) no se señala. Un SSID conocido observado con una nueva MAC de puerta de enlace (router sustituido) se registra pero nunca alerta por sí solo.
                • Mientras se detecta suplantación ARP, se omite la observación para que la MAC de un atacante nunca se aprenda como legítima.
                • El aviso es una alerta en tiempo real, enviada en Pro. El historial aprendido está disponible mediante la herramienta MCP `get_network_history`.
                """,
                recommendation: "Si recibes este aviso, no introduzcas credenciales en ese Wi-Fi y verifica el nombre y la ubicación reales de la red. Un túnel VPN (feat_vpn_tunnel) es la contramedida más fiable."
            ),
            LocalizedEntry(
                id: "feat_arp_spoof_guard",
                title: "Detección de suplantación ARP (suplantación de red) y bloqueo automático (Pro)",
                summary: "Detecta la suplantación ARP, en la que un atacante en la misma red se hace pasar por el router para espiar o manipular el tráfico (ataque de intermediario). En redes con Bloqueo máximo corta la red de inmediato; en otros niveles solo notifica y deja la decisión en tus manos.",
                details: """
                • Detección: la IP de la puerta de enlace predeterminada se mantiene igual mientras su dirección MAC cambia de repente. Además de los eventos de cambio de red, un sondeo dedicado cada 15 segundos detecta también ataques que comienzan a mitad de sesión.
                • Respuesta: en una red con Bloqueo máximo, contención Air-Gap inmediata (feat_airgap_containment). En redes De confianza o Equilibradas, solo notificación, y puedes activar la contención desde «Monitor de puertos y dispositivos» con «Suplantación ARP detectada: cortar toda la red ahora». Esto evita activaciones falsas por reinicios de router o itinerancia en malla, y evita que un único paquete ARP falsificado se use como arma para provocar un corte autoinfligido.
                • Predeterminado: la opción de menú «Bloqueo automático al detectar suplantación ARP (suplantación de red) (Pro)» se activa automáticamente al activar por primera vez una licencia Pro (set_pro_default_guards).
                • Papel: esta es la respuesta posterior al hecho. La prevención corre a cargo de la fijación ARP/NDP de la puerta de enlace (feat_gateway_arp_lock) y el túnel VPN (feat_vpn_tunnel).
                • Los incidentes se registran en la cronología de incidentes (feat_containment_incident_timeline) como MITRE ATT&CK T1557.
                """,
                recommendation: "Mantenla activada. Para una protección MITM más fuerte, añade el túnel VPN; para prevención sin infraestructura adicional, añade la fijación ARP/NDP de la puerta de enlace."
            ),
            LocalizedEntry(
                id: "feat_gateway_arp_lock",
                title: "Fijación ARP/NDP de la puerta de enlace (Preventivo) (Pro)",
                summary: "Al unirte a una red no confiable, fija las direcciones MAC de la puerta de enlace, el router IPv6 y cualquier servidor DNS del enlace local como entradas estáticas de la caché de vecinos, evitando los ataques de intermediario por suplantación ARP/NDP antes de que empiecen. Desactivado por defecto.",
                details: """
                • Activación: «Monitor de puertos y dispositivos» → «Fijar ARP/NDP de la puerta de enlace en redes no confiables (preventivo) (Pro)».
                • Funcionamiento: al conectar, se leen las direcciones MAC actuales y el asistente las fija como entradas permanentes con `arp -s` / `ndp -s`. El kernel ignora después las respuestas ARP falsificadas y los anuncios de vecinos para esas IP.
                • Alcance: solo esos tres tipos de entradas. No se fija nada en redes De confianza (abiertas), por lo que un reinicio del router doméstico nunca interrumpe la conexión. Las fijaciones se borran y se recrean en cada cambio de red.
                • Limitación (confianza en el primer uso): se confía en la primera MAC observada, así que un atacante ya presente antes de tu conexión podría lograr que se fijara su propia MAC. Si no puedes aceptar esa suposición, usa el túnel VPN.
                • Se refleja en el punto «Fijación ARP de la puerta de enlace (defensa preventiva contra MITM)» de la auditoría de seguridad del Mac.
                """,
                recommendation: "Una buena defensa MITM ligera cuando una VPN no es práctica. Puede combinarse con el túnel VPN (la VPN es la defensa principal, esto un complemento)."
            ),
            LocalizedEntry(
                id: "feat_vpn_tunnel",
                title: "Túnel VPN (WireGuard / Tailscale, con interruptor de corte) (Pro)",
                summary: "Establece automáticamente un túnel cifrado en redes no confiables para que los ataques de intermediario solo vean texto cifrado. Elige WireGuard (archivo de configuración) o Tailscale (nodo de salida) como backend. No depende de la integridad de la capa 2 (ARP/NDP), lo que lo convierte en la defensa anti-MITM principal. No requiere permiso de Network Extension.",
                details: """
                • Backend: «Monitor de puertos y dispositivos» → «Túnel VPN (anti-MITM en redes no confiables) (Pro)» → «Backend», luego elige WireGuard o Tailscale. Solo funciona el backend seleccionado.
                • WireGuard: requiere `wireguard-tools` de Homebrew (`brew install wireguard-tools`). Importa una configuración con «Importar configuración WireGuard (.conf)…». Tú proporcionas la configuración (Mullvad, IVPN, Proton VPN, tu propio servidor, tu empleador); RoamSwitch no proporciona servidores VPN.
                • Interruptor de corte de WireGuard: pf aplica «block drop all» con excepciones solo para lo, la interfaz del túnel, el intercambio UDP con el punto final, DHCP e ICMP. Nada se filtra en texto claro mientras el túnel está caído.
                • Tailscale: para quienes ya usan Tailscale. RoamSwitch no lo instala ni inicia sesión; lee `tailscale status` y ejecuta `tailscale set --exit-node=<nodo>`. Se requiere un nodo de salida (todo el tráfico pasa por él). Un nodo de salida sin conexión se muestra en la línea de estado.
                • Se recomienda la CLI de Tailscale (independiente): `brew install tailscale` → `sudo tailscaled install-system-daemon` → `sudo tailscale up`. La versión de la App Store (interfaz gráfica) no puede controlarse con `tailscale set` desde fuera de la app; en ese caso, elige el nodo de salida en la app de Tailscale y RoamSwitch se encarga solo de mostrar el estado y del interruptor de corte.
                • Interruptor de corte de Tailscale (desactivado por defecto, opcional): pf deja pasar solo lo, el utun de Tailscale, el CGNAT 100.64.0.0/10, DNS, STUN 3478, 41641, DERP tcp 443, DHCP e ICMP. Menos estricto que el de WireGuard («difícil de filtrar» en vez de totalmente estanco), y en algunas redes puede interferir con la conectividad propia de Tailscale, por eso es opcional.
                • Automático: el túnel/nodo de salida se activa en redes no confiables y se desactiva en las confiables. Si la licencia caduca, el túnel y el interruptor de corte se liberan automáticamente.
                """,
                recommendation: "La protección más eficaz si usas a menudo Wi-Fi público. Usuarios de Tailscale: instala la CLI y elige el backend Tailscale más un nodo de salida. Si no, `brew install wireguard-tools` con el archivo `.conf` de tu proveedor VPN es la vía más sencilla."
            ),
            LocalizedEntry(
                id: "feat_airgap_containment",
                title: "Contención de emergencia Air-Gap (corte total de red, desactivación de Wi-Fi, restauración automática de seguridad)",
                summary: "La contención de emergencia compartida usada al detectar una amenaza grave (ransomware, hallazgo de malware por XProtect, suplantación ARP, ClickFix). Bloquea todo el tráfico entrante y saliente. Incluso tras un fallo o reinicio, la red vuelve automáticamente en un máximo de 10 minutos.",
                details: """
                • Cómo: el asistente privilegiado carga pf con «block drop all» (excepto loopback) y lo vuelve a leer para confirmarlo. También se corta el tráfico saliente, lo que impide la exfiltración de claves o datos a un servidor C2. Si la aplicación falla, se reintenta hasta 3 veces (8 segundos de tiempo de espera cada vez); si sigue fallando, muestra «Error al cortar la red automáticamente» y te pide desconectar manualmente. Nunca afirma un aislamiento que no sea real.
                • Desactivación de Wi-Fi: pf solo descarta paquetes mientras el adaptador sigue asociado, así que la contención por suplantación ARP, ransomware y XProtect también desactiva el propio Wi-Fi mediante `networksetup` (activado por defecto; ajuste interno `RoamSwitch.AirGapAutoWiFiKillEnabled`). La contención por ClickFix no desactiva el Wi-Fi.
                • Liberación: liberar desde la ventana de emergencia o la notificación elimina el bloqueo de pf y reactiva el Wi-Fi.
                • Red de seguridad: si la app falla o nadie libera la contención, un temporizador del lado del asistente fuerza la liberación del Air-Gap tras 10 minutos y restaura el Wi-Fi. Reiniciar la app o el Mac también se recupera sin pasos manuales.
                • Puerta de arranque: justo después de arrancar, hasta que la app aplica su política, está vigente una puerta pf de denegación predeterminada; se libera sola tras 90 segundos como máximo.
                """,
                recommendation: "Cuando se active la contención, lee primero la notificación, cierra las apps sospechosas y ejecuta un análisis antes de liberarla. Si sabes que es un falso positivo, libérala de inmediato."
            ),
            LocalizedEntry(
                id: "feat_port_anomaly_guard",
                title: "Bloqueo automático de puertos de escucha desconocidos y aislamiento de servidores de desarrollo (Pro)",
                summary: "Supervisa cada puerto TCP en escucha y, cuando un ejecutable que antes no estaba expuesto empieza de repente a escuchar en 0.0.0.0, bloquea el acceso a ese puerto desde la LAN. Los servidores de desarrollo y de IA local también pueden aislarse a 127.0.0.1 con un clic.",
                details: """
                • Supervisión: los puertos en escucha se analizan cada 20 segundos. La identidad es la ruta del ejecutable, así que una app conocida que simplemente cambia de número de puerto no lo activa. El estado justo después de activarlo se captura como línea base.
                • Bloqueo automático: cuando un ejecutable desconocido empieza a exponer un puerto, pf bloquea solo el acceso externo (el propio Mac y localhost pueden seguir usándolo). Esto detecta una puerta trasera plantada por un exploit de día cero sin conocer la familia de malware.
                • Excluidos: los demonios del sistema firmados por Apple bajo `/System/Library` o `/usr/libexec` (por ejemplo rapportd, necesario para Handoff, AirPlay, AirDrop). Las herramientas de propósito general bajo `/usr/bin`, como `/usr/bin/python3` o `/usr/bin/nc`, sí se señalan.
                • Servicios peligrosos: identifica servicios que suelen exponerse sin autenticación, como Redis (6379), MongoDB (27017), Memcached (11211), Elasticsearch (9200), VNC (5900), y servidores de IA local como Ollama (11434), LM Studio (1234), Gradio (7860) y vLLM (8000).
                • Aislamiento de servidores de desarrollo: abre el puerto desde «Puertos expuestos» y elige «Aislar puerto» para restringirlo a 127.0.0.1 (Pro).
                • Falsos positivos: permite de forma permanente con el botón «Permitir» de la notificación o desde la pantalla de auditoría de puertos. Desactivar esta protección (o una licencia caducada) libera todos los bloqueos que creó.
                • Predeterminado: se activa automáticamente al activar Pro por primera vez. El historial de incidentes está disponible mediante la herramienta MCP `get_port_anomaly_incidents`.
                """,
                recommendation: "Vincula tus servidores de desarrollo y LLM locales a `127.0.0.1` (por ejemplo `OLLAMA_HOST=127.0.0.1 ollama serve`, `npm run dev -- -H 127.0.0.1`)."
            ),
            LocalizedEntry(
                id: "feat_active_vuln_scan",
                title: "Verificación activa de vulnerabilidades — desactivada por defecto",
                summary: "Para los servicios detectados en este propio Mac (127.0.0.1), comprueba con sondas mínimas de solo lectura si realmente responden sin autenticación. Desactivada por defecto; requiere activación explícita y confirmación en cada ejecución.",
                details: """
                • Activación: «Monitor de puertos y dispositivos» → «Verificación activa de vulnerabilidades». Esto solo desbloquea el botón «Ejecutar verificación activa» en la pantalla de auditoría de puertos; no envía nada por sí sola, y cada ejecución pregunta primero «¿Enviar la solicitud de verificación?».
                • Solo hacia 127.0.0.1: nunca se envía nada a otro host.
                • Acceso sin autenticación: sondas únicas, de tiempo de espera corto y no destructivas hacia Redis (PING), Memcached (stats) y MongoDB (listDatabases).
                • Servidores de desarrollo genéricos: comprueba configuración incorrecta de CORS (Origin reflejado con credenciales), recorrido de rutas y redirecciones abiertas.
                • Coincidencia con CVE conocidas: para Redis / Memcached accesibles sin autenticación, se lee la versión con una consulta no destructiva y se compara con rangos de versión de CVE conocidas. No se envían cargas útiles de explotación.
                • También disponible como la herramienta MCP `run_active_vuln_scan` (la única herramienta que envía tráfico de red, únicamente hacia localhost).
                """,
                recommendation: "Actívala solo cuando quieras confirmar si Redis, Docker, un LLM local o similar que se ejecuta en tu propio Mac es realmente accesible sin autenticación."
            ),
            LocalizedEntry(
                id: "feat_nmap_nse",
                title: "Escaneo complementario nmap NSE (capa adicional para la verificación activa de vulnerabilidades)",
                summary: "Cuando también está activada la verificación activa de vulnerabilidades, ejecuta los scripts NSE de la categoría «safe» del nmap instalado en el sistema contra los puertos expuestos para añadir cobertura de protocolos que las propias comprobaciones de este producto no tienen (claves de host SSH, banners SMTP, etc.). El resultado es el propio juicio de nmap, no reverificado de forma independiente por este producto.",
                details: """
                • Incluido automáticamente: se ejecuta automáticamente siempre que «Verificación activa de vulnerabilidades (verificación activa de accesibilidad)» esté activada; no existe un interruptor independiente para ello. nmap nunca se instala automáticamente: esto solo tiene efecto si ya está instalado en el sistema (por ejemplo, mediante Homebrew); en caso contrario, no hace nada.
                • Selección de scripts: `safe and not broadcast and not external`. La categoría «safe» por sí sola no es suficiente: los scripts `broadcast` consultan toda la LAN mediante multidifusión/difusión, no solo el host objetivo, y los scripts `external` (por ejemplo, `vulners.nse`) envían realmente el servicio/versión detectados a un tercero como vulners.com. Ambos contradicen el principio de diseño de este producto de tocar únicamente 127.0.0.1 y nunca ningún otro host ni servidor externo, por lo que se excluyen.
                • Tiempo de espera: 15 segundos por script (`--script-timeout 15s`). Algunos scripts «safe» pueden ejecutarse indefinidamente contra API HTTP no estándar, privando de resultados a otros puertos sin este límite.
                • Alcance: los mismos puertos ya confirmados como abiertos que usa la propia verificación activa de vulnerabilidades.
                """,
                recommendation: "Trate los hallazgos de nmap como información de referencia: revise el contenido y actúe solo si es realmente relevante."
            ),
            LocalizedEntry(
                id: "feat_usb_keyboard_guard",
                title: "Protección física del puerto contra USB no autorizado / BadUSB (Aprobación de teclado y análisis del ritmo de pulsaciones) (Pro)",
                summary: "Cuando se conecta un teclado USB desconocido o un cable modificado (Rubber Ducky, O.MG Cable, Flipper Zero y similares), se bloquean sus pulsaciones hasta que lo apruebes, evitando la inyección automatizada de comandos. También analiza los intervalos de pulsación y avisa cuando parecen guionizados.",
                details: """
                • Detección: IOHIDManager detecta nuevos teclados en tiempo real. El teclado integrado se confía automáticamente.
                • Bloqueo: el dispositivo no aprobado se toma de forma exclusiva (captura de IOHIDDevice), de modo que solo las pulsaciones de ese dispositivo dejan de llegar al sistema; los demás teclados siguen funcionando. Solo si la captura falla se recurre a un bloqueo mediante CGEventTap, que usa el permiso de Accesibilidad.
                • Aprobación: una ventana en primer plano ofrece «Confiar y permitir» o «Rechazar y mantener bloqueado». Los teclados permitidos se añaden a la lista de permitidos.
                • Análisis del ritmo de pulsaciones: mientras está bloqueado, se siguen midiendo los intervalos de pulsación del dispositivo. Tras al menos 5 intervalos, una media de 12 ms o menos, o de 45 ms o menos con una uniformidad muy alta (coeficiente de variación de 0,35 o menos), genera un aviso de «muestra indicios de escritura guionizada». Esto capta una velocidad y regularidad mecánicas que ningún humano produce, solo como evidencia adicional; no cambia la decisión de bloqueo.
                • Desactivada por defecto. Actívala con «Monitor de puertos y dispositivos» → «Protección física del puerto contra USB no autorizado / BadUSB (Pro)»; gestiona la lista de permitidos en «Ajustes de protección USB / BadUSB…».
                """,
                recommendation: "Si usas teclados externos, registra solo los que hayas conectado tú mismo con «Confiar y permitir». Rechaza y desconecta siempre un dispositivo que active el aviso de escritura guionizada."
            ),
            LocalizedEntry(
                id: "feat_usb_storage_guard",
                title: "Bloqueo automático de almacenamiento USB no autorizado y análisis automático con ClamAV (Pro)",
                summary: "Una unidad USB o disco externo que no esté en la lista de permitidos se monta primero como solo lectura mientras se te pregunta qué hacer. Los dispositivos permitidos también se analizan con ClamAV antes de conectarse con el permiso configurado.",
                details: """
                • Supervisión: DiskArbitration detecta al instante los montajes de volúmenes externos/extraíbles.
                • Dispositivos no registrados: se vuelven a montar como solo lectura por seguridad, con un diálogo que ofrece «Permitir lectura y escritura», «Permitir como solo lectura» o «Expulsar». Expulsar desmonta y expulsa de inmediato.
                • Dispositivos permitidos: el permiso de la lista de permitidos (Solo lectura / Lectura y escritura) se aplica automáticamente, con un análisis ClamAV antes de cualquier ascenso a lectura y escritura.
                • Infección: si se encuentra malware, el volumen se expulsa automáticamente y se envía una alerta urgente.
                • Unidades reformateadas: si cambia el UUID del volumen pero coincide la identidad del hardware, incluido el número de serie, se conserva la aprobación (el ID de fabricante/producto por sí solo nunca cuenta como coincidencia).
                • Alcance: cubre la exfiltración de datos y las cargas maliciosas mediante almacenamiento. Los dispositivos BadUSB de tipo HID que se hacen pasar por teclados los gestiona feat_usb_keyboard_guard.
                """,
                recommendation: "Añade a la lista de permitidos solo las unidades USB que uses para trabajar, y prefiere el permiso Solo lectura en los Mac que manejan datos sensibles."
            ),
            LocalizedEntry(
                id: "feat_bluetooth_guard",
                title: "Desactivación automática de Bluetooth en redes no confiables (Pro)",
                summary: "Al unirte a una red fuera de casa donde se aplica el Bloqueo máximo, el Bluetooth se desactiva automáticamente para reducir la exposición a emparejamientos no solicitados y ataques BLE, y se restaura al volver a una red de confianza.",
                details: """
                • Herramienta: macOS no ofrece una API pública para alternar la alimentación del Bluetooth, así que RoamSwitch usa la herramienta de código abierto de Homebrew `blueutil` (`brew install blueutil`). Si falta, el menú muestra instrucciones de instalación.
                • Restauración: el Bluetooth vuelve a activarse en una red de confianza solo si estaba activo justo antes de que RoamSwitch lo desactivara; una elección que hayas hecho tú mismo fuera de casa no se anula.
                • Desactivada por defecto: mucha gente usa AirPods y similares en cafeterías, así que cortar el audio en silencio no sería bien recibido. Opcional.
                """,
                recommendation: "Si no usas accesorios Bluetooth fuera de casa, actívala para evitar el rastreo por radio y los emparejamientos no solicitados."
            ),
        ]
    }

    // MARK: - Features: malware & web protection

    private static func featuresEsMalware() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_webmail_download_guard",
                title: "Protección web y correo (Análisis automático y cuarentena de descargas) (Pro)",
                summary: "Vigila con FSEvents los archivos guardados desde navegadores, Mail, Slack, Discord y similares, los comprueba con una firma estática y ClamAV, y mueve las amenazas a la bóveda de cuarentena.",
                details: """
                • Carpetas supervisadas: por defecto `~/Downloads`, `~/Desktop`, `~/Documents` y la carpeta de descargas de Mail. Añade o quita carpetas con «⚙️ Gestionar carpetas supervisadas…».
                • Origen de la descarga: se identifica mediante el atributo extendido `com.apple.quarantine` que añade macOS.
                • Comprobación en dos capas: una comprobación de firma estática en el dispositivo (frases típicas de reverse shell y similares; funciona incluso sin ClamAV) más un análisis de ClamAV. Una coincidencia de firma estática pone en cuarentena sin importar el veredicto de ClamAV, y si ClamAV no coincide, la notificación indica que podría ser un falso positivo.
                • Cuarentena: las amenazas se mueven a `~/Library/Application Support/RoamSwitch/Quarantine/` (nunca se eliminan). Si el movimiento falla, la notificación indica que la cuarentena falló y pide eliminar el archivo manualmente.
                • Archivo de prueba EICAR: la firma de prueba estándar del sector, inofensiva, no se pone en cuarentena ni se bloquea y no genera notificación; solo se registra en el historial de notificaciones (feat_notification_history).
                • Primer acceso a la carpeta: antes de la solicitud de permiso de macOS, aparece un único aviso que explica que se trata de un permiso legítimo para esta función de análisis.
                • Avisos sobre modelos en formato Pickle: consulta feat_ai_model_guard.
                """,
                recommendation: "Instala y activa ClamAV, y añade cualquier carpeta de descargas del navegador personalizada a las carpetas supervisadas."
            ),
            LocalizedEntry(
                id: "feat_ai_model_guard",
                title: "Aviso de descarga de un formato de modelo de IA peligroso (Pickle / PyTorch) (Pro)",
                summary: "Cuando se descarga un archivo de modelo `.pkl` / `.pickle` / `.pt` desde Hugging Face, Civitai o similar, avisa de que el formato Pickle puede ejecutar código arbitrario al cargarse, y recomienda SafeTensors / GGUF.",
                details: """
                • Detección: comprueba la extensión de los archivos descargados en las carpetas supervisadas por la Protección web y correo (feat_webmail_download_guard).
                • Riesgo: Pickle de Python puede ejecutar código arbitrario durante la deserialización, así que basta con cargar un modelo malicioso para comprometer el Mac.
                • Comportamiento: solo un aviso; el archivo no se pone en cuarentena (una coincidencia de ClamAV o de la firma estática sigue poniéndolo en cuarentena como de costumbre).
                """,
                recommendation: "No cargues modelos Pickle / PyTorch de fuentes desconocidas; usa en su lugar modelos `.safetensors` o `.gguf`."
            ),
            LocalizedEntry(
                id: "feat_quarantine_manager",
                title: "Gestión de archivos en cuarentena (bóveda, restaurar, eliminar, exclusiones de análisis)",
                summary: "Los archivos señalados por ClamAV o por la comprobación de firma estática nunca se eliminan; se conservan en la bóveda de cuarentena. El Gestor de cuarentena permite ver el motivo, restaurar a la ubicación original, eliminar permanentemente, o excluir una ruta de análisis futuros.",
                details: """
                • Abrir: «Protección contra malware (XProtect y ClamAV)» → ClamAV → «📦 Gestionar archivos en cuarentena…», o «📦 Abrir gestor de cuarentena…» bajo Protección web y correo.
                • Ubicación: `~/Library/Application Support/RoamSwitch/Quarantine/`, con metadatos de la ruta original, el nombre de la amenaza y el momento de la cuarentena. Nada se elimina a menos que elijas explícitamente Eliminar permanentemente.
                • Restaurar: devuelve el archivo a su ubicación original; úsalo solo cuando estés seguro de que no está infectado.
                • Excluir y restaurar: para un falso positivo confirmado, restaura el archivo y excluye esa ruta exacta de futuros análisis de ClamAV. Las exclusiones se listan en la misma ventana, donde «Quitar exclusión» las revierte.
                • Eliminar permanentemente: elimina tras una confirmación. Esto no se puede deshacer.
                • La herramienta MCP `get_quarantine_status` lista los archivos en cuarentena.
                """,
                recommendation: "Elimina los archivos que no reconozcas, y usa «Excluir y restaurar» solo para falsos positivos seguros, como tus propios scripts o binarios de desarrollo."
            ),
            LocalizedEntry(
                id: "feat_xprotect_file_safety",
                title: "Estado de Apple XProtect y comprobación de seguridad de archivo/app",
                summary: "Muestra la versión de definiciones y el estado de la protección integrada de macOS contra malware, XProtect, y comprueba si un archivo o app cualquiera está notarizado, con qué autoridad de firma, con qué Team ID y con el atributo de cuarentena de descarga. Disponible en la edición gratuita.",
                details: """
                • Abrir: «Protección contra malware (XProtect y ClamAV)» → «🍏 Apple XProtect» → «Comprobar estado de XProtect…» / «Comprobar seguridad de archivo/app…».
                • Comprobaciones: aprobado por Apple (notarizado/Gatekeeper) o no, autoridad de firma, Team ID, el atributo de cuarentena de descargas web (`com.apple.quarantine`), y la ruta.
                • Uso: antes de abrir una app por primera vez, confirma que fue firmada y notarizada por un desarrollador legítimo.
                """,
                recommendation: "Comprueba las apps de origen desconocido antes de ejecutarlas, y no abras nada que no esté aprobado ni firmado."
            ),
            LocalizedEntry(
                id: "feat_dns_threat_guard",
                title: "Protección contra amenazas DNS (Bloquear malware y C2) (Pro)",
                summary: "Aplica un resolutor DNS seguro (Quad9, Cloudflare, AdGuard, CleanBrowsing) para que las búsquedas de nombres hacia servidores C2 de malware y sitios de phishing se bloqueen ya en la etapa DNS.",
                details: """
                • Proveedores: Quad9 (9.9.9.9 / 149.112.112.112), Cloudflare Security (1.1.1.2 / 1.0.0.2), AdGuard DNS (94.140.14.14 / 94.140.15.15, también bloquea anuncios y rastreadores), CleanBrowsing Security (185.228.168.9 / 185.228.169.9).
                • Política: «Solo en Wi-Fi no seguro (Recomendado)» o «Siempre activo en todas las redes (incluidas las de confianza)».
                • Internamente: el asistente privilegiado cambia los servidores DNS del servicio de red activo y restaura la configuración DHCP/DNS manual original al volver a una red de confianza.
                • Estado: el menú muestra «🟢 DNS seguro activo» o «🏠 Red de confianza (DNS estándar del router)». También es un punto de la Auditoría de seguridad del Mac.
                """,
                recommendation: "Para evitar el DNS falso en Wi-Fi público (secuestro de DNS) y los dominios maliciosos, empieza con Quad9 y la política de solo fuera de casa."
            ),
            LocalizedEntry(
                id: "feat_passive_link_guard",
                title: "Protección de enlaces (Detectar y bloquear conexiones de phishing: extensión del sistema, compatible con DoH, el modo Advertencia falla cerrado) (Pro)",
                summary: "Bloquea en el dispositivo las conexiones hacia sitios de phishing y estafa, para cualquier navegador o app, basándose en una lista de amenazas de dominios de estafa conocidos y en la detección de suplantación de marca. Funciona como una extensión del sistema de filtrado de contenido, con un «sinkhole» /etc/hosts como respaldo hasta que se apruebe la extensión.",
                details: """
                • Modos: «Desactivado», «Solo advertir (nunca bloquear)» y «Bloquear automáticamente los sitios de phishing evidentes (recomendado)» (predeterminado). Cambia el modo en Protección contra malware → «Protección de enlaces (detección de conexiones de phishing) (Pro)».
                • Qué se bloquea: solo los casos claros, es decir, dominios de la lista de amenazas o suplantación de marca por homógrafos Unicode. Los trucos de marca en un subdominio, los TLD de alto riesgo y similares se tratan como advertencias. El motor de veredicto y la lista se comparten con la edición de Linux.
                • Extensión del sistema (recomendado): la extensión del sistema de filtrado de contenido `RoamSwitchLinkFilter` inspecciona los flujos TCP después de la resolución de nombres. Además del nombre de host resuelto por el sistema operativo, lee el SNI del ClientHello TLS, por lo que funciona incluso si el navegador usa su propio DoH / DoT. En modo bloqueo, descarta el QUIC (UDP 443), donde no se ve el SNI, para que los navegadores recurran a TCP. El primer uso requiere aprobación en Ajustes del Sistema.
                • Huella JA3: para las conexiones TLS cuyo SNI se leyó, también se calcula el hash JA3 del cliente y se compara con la lista JA3 de la lista de amenazas (JA3 nunca se usa solo en conexiones sin SNI).
                • Modo Advertencia (falla cerrado): la conexión correspondiente se pausa y aparecen una notificación de Permitir/Bloquear y un panel en primer plano; el flujo se reanuda o se descarta según tu respuesta. Sin respuesta en unos 8 segundos, la conexión se bloquea. Ese resultado no se guarda en caché, así que el siguiente intento volverá a preguntar. Las respuestas que realmente das se recuerdan. El modo Advertencia requiere la extensión del sistema.
                • Alternativa mediante hosts: mientras la extensión no está activa, el modo bloqueo hace que el asistente privilegiado escriba los dominios como `0.0.0.0` en una sección gestionada de `/etc/hosts`.
                • Lista de amenazas: se obtiene una vez al día, solo en recepción, sin enviar identificadores, y se verifica con una clave de lista Ed25519 dedicada (distinta de la clave de actualización de la app). Desactivar la «Actualización automática» significa cero tráfico saliente; los datos incluidos y la detección de homógrafos siguen funcionando.
                • Sin Pro: el modo se guarda pero no se bloquea nada.
                """,
                recommendation: "Mantén el bloqueo automático predeterminado y aprueba la extensión del sistema para la protección más fiable. Si una herramienta interna se bloquea por error, usa «Permitir una vez (5 min)» en la notificación o la lista de permitidos."
            ),
            LocalizedEntry(
                id: "feat_link_safety_auditor",
                title: "Auditoría de seguridad de enlaces (comprobación manual, Zero Telemetry)",
                summary: "Antes de abrir una URL sospechosa, la analiza por completo en el dispositivo y puntúa su riesgo sobre 100 según homógrafos Unicode, suplantación de subdominio, TLD de alto riesgo, HTTP sin cifrar, direcciones IP en bruto, y más. Disponible en la edición gratuita.",
                details: """
                • Abrir: Protección contra malware → «🔗 Comprobar un enlace manualmente…», o la herramienta MCP `audit_url_safety`.
                • Homógrafos: detecta caracteres de aspecto similar, como letras cirílicas o griegas (Punycode / `xn--`).
                • Suplantación de subdominio: analiza estructuras como `apple.com.login-verify.xyz` que incrustan el nombre de una gran marca.
                • TLD de alto riesgo: resta puntos por TLD habituales en el phishing desechable, como `.xyz`, `.top`, `.tk`, `.icu`.
                • HTTP sin cifrar e IP en bruto: avisa del HTTP sin cifrar en páginas de inicio de sesión y de las URL con dirección IP desnuda.
                • Totalmente local: las URL nunca se envían a una API de análisis externa, de modo que las URL confidenciales y los tokens no se filtran.
                """,
                recommendation: "No hagas clic directamente en enlaces sospechosos del correo o del chat; compruébalos primero con la Auditoría de seguridad de enlaces."
            ),
            LocalizedEntry(
                id: "feat_ransomware_canary_guard",
                title: "Detección de ransomware mediante archivos señuelo y Air-Gap autónomo con congelación de procesos (Pro)",
                summary: "Coloca archivos señuelo (canario) ocultos en tus carpetas de usuario. En cuanto uno de ellos se modifica, elimina o renombra, corta automáticamente la red, detiene los servicios de compartición y pausa (SIGSTOP) el proceso sospechoso.",
                details: """
                • Archivos señuelo: cuatro en `~/Library/Application Support/RoamSwitch/CanaryGuard/`, más archivos ocultos que empiezan por `.roamswitch_security_canary_do_not_delete` en Documentos, Escritorio, Descargas y Fotos. El SHA-256 de cada archivo se registra como referencia.
                • Detección: vigilancia kqueue en tiempo real más una comprobación cada 60 segundos. Un periodo de gracia de 10 segundos por archivo evita el procesamiento duplicado de una misma ráfaga de eventos. Los archivos reales modificados en los últimos 60 segundos se registran como posiblemente afectados.
                • Respuesta automática: (1) bloqueo del cortafuegos de aplicaciones, (2) contención Air-Gap (pf bloquea todo el tráfico y se desactiva el Wi-Fi, feat_airgap_containment), (3) se detienen los servicios de compartición (SMB / SSH / Compartir pantalla), (4) el proceso sospechoso se pausa con SIGSTOP en lugar de terminarse, (5) alerta urgente y ventana de emergencia en primer plano.
                • Por qué pausar en vez de terminar: la red ya está cortada, así que un proceso pausado no puede causar más daño. Si fue un falso positivo, se reanuda (SIGCONT) al liberar la contención, sin pérdida de datos.
                • Al liberar: se restauran la red y el Wi-Fi, se reanuda el proceso pausado, y se regeneran los archivos señuelo alterados.
                • Predeterminado: se activa automáticamente al activar Pro por primera vez. Historial de incidentes mediante la herramienta MCP `get_canary_status`. Pruébalo con seguridad con «Simulación de defensa contra ransomware (Modo prueba)» en el menú.
                """,
                recommendation: "Mantenla activada para proteger datos importantes de ransomware desconocido, y no elimines los archivos señuelo ocultos."
            ),
            LocalizedEntry(
                id: "feat_ransomware_recovery",
                title: "Recuperación de ransomware (extraer archivos de una instantánea previa)",
                summary: "Para volver al estado anterior al cifrado, RoamSwitch crea instantáneas locales APFS de forma periódica y permite extraer solo los archivos necesarios a otro lugar. Sus archivos actuales nunca se sobrescriben.",
                details: """
                • Instantáneas previas: se crean por defecto cada 6 horas (desactivadas / 1 / 3 / 6 / 12 / 24 horas), con independencia de cualquier detección. Una instantánea tomada tras una detección puede contener ya archivos cifrados.
                • Instantáneas de detección: también se toman cuando se activa el vigilante de señuelos, pero pueden contener archivos cifrados y no se recomiendan como origen de recuperación.
                • Modo de retención: mientras una instantánea de detección sea la más reciente (hasta 7 días), se pausan las nuevas instantáneas previas y la limpieza de las anteriores, para que no se desplace la última generación previa al cifrado.
                • Extracción: con «Recuperación de ransomware…» en el menú, los archivos o carpetas de la instantánea recomendada (la previa más reciente que aún existe) se copian a `~/RoamSwitch-Recovered/<ID de la instantánea>/`. Los archivos existentes nunca se sobrescriben y no hay restauración completa del volumen. La recuperación es siempre manual.
                • Límites: macOS puede eliminar las instantáneas locales por sí mismo tras unas 24 horas (antes si queda poco espacio libre), y una generación que ya no existe no se puede usar. Extraer archivos requiere Acceso total al disco para el ayudante de RoamSwitch (crear instantáneas no).
                • MCP: la herramienta de solo lectura `get_ransomware_recovery_snapshots` muestra la lista y la recomendación (no puede restaurar nada).
                • Pro: Esta ventana (lista y extracción de archivos) y la herramienta MCP son funciones Pro. La creación de las instantáneas funciona también sin Pro.
                """,
                recommendation: "Mantenga activadas las instantáneas previas. Si nota daños, corte primero la red y extraiga los archivos de la instantánea previa recomendada, no de la de detección."
            ),
            LocalizedEntry(
                id: "feat_runtime_threat_containment",
                title: "Desconexión de red automática al detectar malware con XProtect (Pro)",
                summary: "En el instante en que XProtect / XProtect Remediator, integrado en macOS, detecta o elimina realmente malware, la red se corta en un Air-Gap de emergencia. Un bloqueo de Gatekeeper a una app sin firmar no corta la red; solo envía una notificación.",
                details: """
                • Origen de la señal: una suscripción de larga duración a `/usr/bin/log stream` en formato ndjson (espera bloqueante en vez de sondeo, por lo que el coste de CPU en reposo es casi nulo) vigila los registros del sistema relacionados con XProtect.
                • Activación: solo cuando XProtect registra un hallazgo crítico de malware se activa la contención Air-Gap (incluida la desactivación del Wi-Fi), sin importar el nivel de confianza de la red.
                • Diferencia con Gatekeeper: los eventos cotidianos de Gatekeeper, como bloquear una compilación sin firmar del propio desarrollador, solo generan la notificación «Gatekeeper impidió la ejecución de una app sin firmar».
                • Coherencia: comparte la misma lógica de clasificación que la Auditoría de registros de seguridad Mac manual.
                • Al no usar el permiso EndpointSecurity, se trata de una contención inmediata tras la detección, no de un bloqueo previo a la ejecución.
                • Predeterminado: se activa automáticamente al activar Pro por primera vez (con un aviso único de que la desconexión automática está activada). El estado está disponible mediante la herramienta MCP `get_runtime_threat_status`; pruébalo con «Simulación de Air-Gap por detección de malware (prueba)».
                """,
                recommendation: "Mantenla activada como defensa automática vinculada al propio motor de malware de Apple. Ejecutar con frecuencia tus propias apps sin firmar no la activará, porque un simple bloqueo de Gatekeeper nunca corta la red."
            ),
            LocalizedEntry(
                id: "feat_clickfix_guard",
                title: "Defensa ClickFix — bloqueo automático al detectar comandos sospechosos en Terminal (Pro, desactivada por defecto)",
                summary: "Detecta en el historial del shell la técnica ClickFix, en la que una falsa página de verificación o error te induce a pegar y ejecutar tú mismo un comando, y corta la red para detener un ataque en curso de varias etapas.",
                details: """
                • Vigilado: solo las líneas nuevas añadidas a `~/.zsh_history` y `~/.bash_history` (el historial existente se ignora).
                • Patrones: (1) frases conocidas de reverse shell (compartidas con la comprobación de firma estática), y (2) doble indirección que canaliza contenido decodificado en Base64 directamente a un shell o a `osascript`. Un simple `curl ... | bash`, como el que usan instaladores legítimos como Homebrew, se omite deliberadamente.
                • Respuesta: contención Air-Gap (no se desactiva el Wi-Fi), restaurada automáticamente en un máximo de 10 minutos. La notificación recomienda revisar tu llavero, las contraseñas guardadas en el navegador y tus carteras de criptomonedas.
                • Por qué a posteriori: cuando una línea aparece en el historial, el comando ya se ejecutó, pero cortar la red de inmediato aún puede detener una segunda descarga en curso, una conexión de reverse shell activa, o una exfiltración de credenciales en marcha.
                • Por qué Gatekeeper no puede evitarlo: es tu propio shell legítimo ejecutando exactamente lo que escribiste, así que nada en el proceso en sí parece inusual.
                • Complemento: la protección del portapapeles (feat_secret_leak_auditor) intercepta el comando al copiarlo, cubriendo los pegados en el Editor de scripts, Spotlight y otros lugares además de Terminal.
                • Desactivada por defecto: un corte automático de red impulsado por una heurística relativamente nueva, por lo que es opcional.
                """,
                recommendation: "Considera activarla si te preocupa que te engañen falsas páginas de error o verificaciones para ejecutar comandos."
            ),
            LocalizedEntry(
                id: "feat_persistence_monitor_guard",
                title: "Vigilar nuevos registros de inicio automático (LaunchAgent / LaunchDaemon) (Pro)",
                summary: "Vigila en tiempo real los nuevos registros de LaunchAgent / LaunchDaemon y te avisa cuando uno de ellos lanza directamente un shell o un intérprete de scripts, o registra un ejecutable con una firma no válida.",
                details: """
                • Vigilado: `~/Library/LaunchAgents`, `/Library/LaunchAgents` y `/Library/LaunchDaemons` mediante FSEvents (antirrebote de aproximadamente 1,5 segundos).
                • Criterio: los ladrones de información recientes logran persistencia haciendo que un `/bin/bash` o `/usr/bin/osascript` firmado válidamente por Apple ejecute un script oculto en Base64. Como la firma del propio intérprete es válida, cualquier registro que lance un intérprete puro se trata como sospechoso sin importar la firma, y sus argumentos de script también pasan por la comprobación de firma estática. Los ejecutables sin firmar o con firma no válida también se señalan. Los envoltorios de Homebrew services están exentos.
                • Solo detección: sin el permiso EndpointSecurity, no se puede impedir la escritura del plist. Se evalúa y notifica en aproximadamente 1,5 segundos tras escribirse.
                • Predeterminado: activada por defecto con Pro. Cámbiala en Protección contra malware → «Vigilar nuevos registros de inicio automático (LaunchAgent/Daemon) (Pro)».
                """,
                recommendation: "Si recibes una alerta de registro desconocido, examina el plist que muestra la notificación y elimínalo si no lo reconoces. Justo después de instalar una app legítima, normalmente es inofensivo."
            ),
            LocalizedEntry(
                id: "feat_docker_event_guard",
                title: "Detectar contenedores Docker privilegiados y montajes de docker.sock (Pro, desactivada por defecto)",
                summary: "Te avisa, al iniciarse un contenedor, de configuraciones de Docker arriesgadas que pueden llevar a un escape de contenedor, como contenedores iniciados con `--privileged` o con `/var/run/docker.sock` montado.",
                details: """
                • Cómo: cada 20 segundos, `docker ps` encuentra solo los contenedores recién iniciados, y `docker inspect` comprueba su configuración. El formato de detección es idéntico al de la edición de Linux, de modo que ambas plataformas señalan las mismas condiciones.
                • Solo notificación: es una configuración de riesgo, no una vulneración confirmada (un agente de supervisión puede ejecutarse en modo privilegiado a propósito), así que nada se bloquea automáticamente.
                • Desactivada por defecto: la mayoría de los usuarios no usa Docker, así que está desactivada incluso en Pro.
                • Prueba: «⚠️ Simulación de detección de riesgos de Docker (Modo prueba)…» comprueba la vía de notificación sin tocar Docker.
                """,
                recommendation: "Si usas Docker para desarrollo, actívala para detectar pronto los riesgos de escape de contenedor."
            ),
        ]
    }

    // MARK: - Features: audit, monitoring & platform

    private static func featuresEsAudit() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_critical_path_fim",
                title: "Supervisión de manipulación de archivos críticos del sistema (Critical Path FIM) (Pro)",
                summary: "Registra una línea base SHA-256 de archivos críticos como sudoers, la configuración SSH, PAM y hosts, que las actualizaciones legítimas del sistema o las instalaciones de apps casi nunca cambian, y te avisa de cualquier modificación, eliminación o archivo nuevo.",
                details: """
                • Archivos: `/etc/sudoers`, `/etc/pam.d/sudo`, `/etc/ssh/sshd_config`, todo lo que hay bajo `/etc/ssh/sshd_config.d/`, `/etc/hosts`, y `~/.ssh/authorized_keys` de root. Son de solo acceso para root, así que el asistente privilegiado calcula los hashes.
                • Cuándo: los FSEvents en `/etc`, `/etc/pam.d` y `/etc/ssh` provocan un nuevo análisis casi en tiempo real, con un análisis cada hora como respaldo.
                • Línea base: se captura en el primer análisis. Un cambio detectado nunca se adopta automáticamente como nueva línea base, de modo que el hallazgo persiste hasta que un humano lo revisa. El mismo estado no se vuelve a notificar mientras la app sigue en ejecución; cualquier cambio adicional vuelve a alertar.
                • Aviso de punto ciego: si no se puede contactar con el asistente durante 3 análisis seguidos, se te avisa de que la detección de manipulación no está funcionando.
                • Nota: mientras la Protección de enlaces funciona en su alternativa mediante hosts, RoamSwitch puede reescribir por sí mismo su sección gestionada de `/etc/hosts`. Los LaunchAgents / Daemons los cubre feat_persistence_monitor_guard.
                • Predeterminado: se activa automáticamente al activar Pro por primera vez. Menú: Protección contra malware → «Supervisar periódicamente archivos críticos del sistema en busca de manipulaciones (Pro)».
                """,
                recommendation: "Cuando recibas un aviso, comprueba si hiciste tú mismo el cambio (por ejemplo `sudo visudo` o una edición de configuración). Si no, examina el archivo de inmediato y plantéate cambiar tu contraseña."
            ),
            LocalizedEntry(
                id: "feat_security_log_audit",
                title: "Auditoría de registros de seguridad Mac (manual, detección de anomalías de plantilla, copia para consulta con IA)",
                summary: "Extrae del registro unificado de macOS los fallos de sudo, las conexiones SSH, los bloqueos de Gatekeeper, las detecciones de XProtect y los eventos de autenticación, y también lista nuevos patrones de registro y picos de frecuencia (anomalías de plantilla). Disponible en la edición gratuita.",
                details: """
                • Abrir: Auditoría de seguridad del Mac → «📜 Auditoría de registros de seguridad Mac…», o la herramienta MCP `audit_security_logs`.
                • Periodo: últimas 24 horas, 3 días o 7 días.
                • Tarjetas resumen: fallos de Sudo, conexiones SSH, bloqueos de Gatekeeper, detecciones de XProtect, anomalías de plantilla. Se puede filtrar por categoría y buscar.
                • Anomalías de plantilla: las líneas de registro se convierten en plantillas enmascarando las partes variables (direcciones IP, direcciones hexadecimales, números). Saca a la luz patrones nunca vistos en este Mac ([nuevo]) y picos muy por encima de su frecuencia habitual ([pico z=…], puntuación z de 3 o más). La frecuencia de cada patrón se aprende tras 3 observaciones, tras lo cual un volumen normal deja de alertar.
                • Veredicto en lenguaje llano: un asistente basado en reglas en el dispositivo resume el resultado para no expertos con puntos concretos que comprobar (sin API externa).
                • Salida: «Copiar informe», «Copiar materiales para consulta con IA» (copia una pregunta más los registros para pegar en Claude, ChatGPT y similares; RoamSwitch no envía nada), y «Exportar CSV (Pro)».
                """,
                recommendation: "Ejecútala cuando sigan llegando notificaciones sospechosas o el Mac se comporte de forma extraña, y comprueba si hay detecciones de XProtect o un aumento de fallos de sudo."
            ),
            LocalizedEntry(
                id: "feat_scheduled_log_audit",
                title: "Auditoría automática de registros (aprende patrones nuevos y anomalías de frecuencia según un calendario) (Pro)",
                summary: "Ejecuta cada hora, en segundo plano, la detección de anomalías de plantilla de la auditoría de registros, aprendiendo continuamente el comportamiento normal de los registros de este Mac. Cuando encuentra patrones nuevos o picos de frecuencia, te avisa con líneas de registro reales y una explicación en lenguaje llano.",
                details: """
                • Calendario: cada hora, analizando la última hora. El primer análisis se ejecuta unos 10 segundos después de activarse, pero como incluye los propios registros de inicio de la app, esa ejecución solo aprende y nunca notifica.
                • Notificación: el recuento de anomalías (dividido en patrones nuevos y picos), hasta 3 líneas de registro reales, una nota sobre el progreso del aprendizaje, y una explicación para no expertos. Un lote que incluye un pico de frecuencia muestra una alerta en el Centro de Notificaciones; un lote formado solo por patrones nuevos se registra en el historial de notificaciones sin mostrar ningún aviso. Un patrón nuevo se vuelve «conocido» una vez registrado y nunca se vuelve a registrar por el mismo contenido; un pico deja de alertar en cuanto se aprende la línea base propia de ese patrón.
                • Compartida con la auditoría manual: usa el mismo análisis y la misma línea base aprendida que la Auditoría de registros de seguridad Mac manual y la herramienta MCP `audit_security_logs`.
                • Predeterminado: se activa automáticamente al activar Pro por primera vez. Menú: Protección contra malware → «Auditoría automática de registros (aprende patrones nuevos y anomalías de frecuencia según un calendario) (Pro)».
                """,
                recommendation: "Espera algo más de avisos de patrones nuevos justo después de configurarla; se estabilizan a medida que avanza el aprendizaje. Si un aviso menciona una app o una IP desconocida, abre la ventana de auditoría de registros para más detalles."
            ),
            LocalizedEntry(
                id: "feat_containment_incident_timeline",
                title: "Cronología de incidentes de contención (registro unificado, correspondencia con MITRE ATT&CK)",
                summary: "Guarda las cuatro respuestas automáticas (suplantación ARP, archivos señuelo de ransomware, corte vinculado a XProtect, bloqueo automático de puerto desconocido) en un registro cronológico único en el dispositivo, para que después puedas revisar qué pasó, qué se hizo y cuándo se resolvió.",
                details: """
                • Registrado: hora, origen, gravedad, resumen, nombre del proceso y PID (si se conoce), acción tomada, y hora y motivo de la resolución (liberado manualmente, liberado automáticamente por tiempo de espera, o añadido a la lista de permitidos).
                • MITRE ATT&CK: solo se añade un identificador de técnica cuando la correspondencia es segura (suplantación ARP = T1557; archivo señuelo eliminado o renombrado = T1485; cifrado = T1486; otra manipulación = T1565). Nada se adivina.
                • Almacenamiento: `~/Library/Application Support/RoamSwitch/containment_incident_timeline.json` (los 200 más recientes). Nunca se envía a ningún sitio.
                • La herramienta MCP `get_incident_timeline` devuelve esta cronología unificada (útil para triaje con una IA local durante un Air-Gap). El historial por protección también está disponible mediante `get_canary_status`, `get_port_anomaly_incidents` y `get_runtime_threat_status`.
                """,
                recommendation: "Después de un corte automático, revisa esta cronología junto con el historial de notificaciones para encontrar la causa y evitar que se repita."
            ),
            LocalizedEntry(
                id: "feat_notification_history",
                title: "Historial de notificaciones (última semana)",
                summary: "Guarda cada notificación enviada por RoamSwitch durante 7 días para que puedas revisar los avisos que hayas pasado por alto. Los eventos registrados en el historial sin aviso, como la detección de una firma de prueba EICAR, también aparecen aquí. Disponible en la edición gratuita.",
                details: """
                • Abrir: Auditoría de seguridad del Mac → «🔔 Historial de notificaciones…».
                • Retención: 7 días; las entradas más antiguas se eliminan automáticamente cada vez que se registra una nueva.
                • Contenido: hora, título y cuerpo, incluidas las alertas de amenaza, los eventos de conexión de la Protección de enlaces, las detecciones de ClickFix y de claves secretas, y los cortes automáticos.
                • Firma de prueba EICAR: el archivo de prueba inofensivo estándar del sector no es una amenaza real, así que no se pone en cuarentena ni se bloquea y no aparece ningún aviso; solo se registra aquí. Esto se aplica igual a la protección de descargas, los análisis rápidos y los análisis programados.
                • Un asistente de IA puede leerlo mediante la herramienta MCP `get_notification_history`.
                """,
                recommendation: "Si te perdiste una notificación mientras estabas fuera u ocupado, compruébala aquí."
            ),
            LocalizedEntry(
                id: "feat_secret_leak_auditor",
                title: "Protección del portapapeles (aviso de pegado de clave API y eliminación de comandos ClickFix)",
                summary: "Vigila el portapapeles solo en el dispositivo, avisa cuando se ha copiado una clave API o una clave privada para que no la pegues por error, y vacía automáticamente el portapapeles cuando copias un comando malicioso que un sitio de estafa quiere que ejecutes (ClickFix). Activada por defecto en la edición gratuita.",
                details: """
                • Supervisión: comprueba los cambios del portapapeles aproximadamente una vez por segundo. El contenido nunca se envía ni se almacena.
                • Claves detectadas: claves API y tokens de OpenAI, Anthropic, GitHub, AWS, Hugging Face, Google AI / Gemini, Slack y Stripe, además de claves privadas RSA / SSH. También frases semilla de monederos cripto (BIP39) y claves privadas de Bitcoin (WIF/BIP32), ambas verificadas por checksum para reducir los falsos positivos.
                • Para claves secretas: solo notificación («Clave confidencial detectada en el portapapeles»); el portapapeles no se vacía, ya que una clave filtrada aún puede revocarse y renovarse después.
                • Para comandos ClickFix: notificación («Comando sospechoso detectado en el portapapeles») y el portapapeles se vacía de inmediato, deteniendo el pegado allá donde fuera a ir: Terminal, Editor de scripts, Spotlight u otro lugar. Esto complementa a feat_clickfix_guard, que vigila el historial del shell.
                """,
                recommendation: "Después de copiar una clave API, ten cuidado de dónde la pegas, sobre todo en chats de IA y formularios web. Si la compartiste por error, revócala y renuévala de inmediato."
            ),
            LocalizedEntry(
                id: "feat_secret_leak_audit_tool",
                title: "Auditoría manual de fugas de secretos / claves API (pegar texto o analizar una carpeta entera)",
                summary: "Una herramienta de auditoría a demanda que comprueba al instante el texto pegado o analiza una carpeta de forma recursiva, mostrando números de línea, valores enmascarados y pasos de revocación para cada tipo de clave. Disponible en la edición gratuita.",
                details: """
                • Abrir: Protección contra malware → «🔑 Auditar manualmente fugas de secretos/claves API…», o la herramienta MCP `audit_secrets` (con `text` o `path`).
                • Método: expresiones regulares más una puntuación de entropía de Shannon. Los valores detectados se muestran enmascarados.
                • Análisis de carpeta: `.git`, `node_modules`, `target`, `vendor`, `dist`, `build`, `__pycache__` y `venv` se omiten automáticamente, igual que los archivos de más de 2 MB y los binarios.
                • Aviso de permiso: elegir una carpeta protegida como Escritorio o Descargas muestra primero un aviso único que explica por qué se necesita el acceso y que el análisis es Zero Telemetry, antes de la solicitud de macOS.
                • Se ejecuta en un hilo en segundo plano sin congelar la interfaz. No se envía nada a ningún sitio.
                """,
                recommendation: "Úsala antes de publicar un repositorio o de pegar código en un chat de IA."
            ),
            LocalizedEntry(
                id: "feat_package_cve_scan",
                title: "Comprobación de CVE de paquetes (Homebrew + 7 ecosistemas, incl. npm / PyPI / crates.io, Zero Telemetry)",
                summary: "Compara los paquetes de Homebrew instalados y los archivos de bloqueo de dependencias en las carpetas de proyecto que elijas con mapas de CVE conocidas guardados en el dispositivo. El propio análisis no realiza ninguna solicitud de red. Disponible en la edición gratuita.",
                details: """
                • Abrir: Protección contra malware → «📦 Comprobación de CVE de paquetes (Homebrew)…». Para dependencias, añade carpetas de proyecto en la pestaña Dependencias.
                • Homebrew: `brew list --versions` se compara con una tabla de fórmula a CPE generada a partir de datos reales de NVD. Los hallazgos llevan un nivel de confianza: confirmed (tabla verificada) o gray (coincidencia de palabra clave no verificada que podría ser un falso positivo).
                • Dependencias: analiza package-lock.json / requirements.txt / Pipfile.lock / poetry.lock / Cargo.lock / Gemfile.lock / composer.lock / go.sum / pom.xml y los compara con mapas de CVE conocidas para npm, PyPI, crates.io, RubyGems, Packagist, Go y Maven (de OSV.dev, CVSS 7,0 o superior).
                • Entrega de datos: los mapas de CVE se obtienen una vez al día desde un manifiesto firmado, solo en recepción. Antes de obtenerse se muestran como aún no descargados y no detectan nada.
                • Herramientas MCP: `run_package_cve_scan` (Homebrew) y `run_package_cve_scan_languages` (dependencias, argumento `watchedFolders`).
                """,
                recommendation: "Ejecuta el análisis de Homebrew regularmente, registra los proyectos activos en la pestaña Dependencias, y actualiza cuanto antes los paquetes con CVE graves."
            ),
            LocalizedEntry(
                id: "feat_lockfile_tamper_guard",
                title: "Monitorización de manipulación de lockfiles de dependencias (Lockfile FIM, Pro)",
                summary: "Vigila continuamente package-lock.json / yarn.lock / pnpm-lock.yaml / npm-shrinkwrap.json mediante una línea base SHA-256, detectando manipulación externa vía CI o la cadena de suministro. Solo Pro.",
                details: """
                • Cómo abrir: alterne desde el elemento de la barra de menús «🔔/✅ Supervisar periódicamente la manipulación de lockfiles de dependencias (Pro)».
                • Archivos vigilados: las mismas carpetas de proyecto registradas en la pestaña «Dependencias» del cotejo de CVE de paquetes — sin lista de carpetas separada.
                • Detección: diferencia de línea base SHA-256 mediante CryptoKit, con detección casi en tiempo real vía FSEvents más un análisis de respaldo cada hora.
                • Urgencia de la notificación: si npm/yarn/pnpm se está ejecutando en el momento de la detección, se registra en el historial de notificaciones con una alerta silenciosa; en caso contrario es una alerta crítica normal. La detección en sí nunca se omite en ningún caso.
                • Se desactiva automáticamente si se pierde la licencia Pro.
                """,
                recommendation: "Registre los proyectos importantes en la pestaña «Dependencias» del cotejo de CVE de paquetes y déjelo activado (predeterminado con Pro activo)."
            ),
            LocalizedEntry(
                id: "feat_package_lifecycle_script_scan",
                title: "Inventario de scripts de instalación (scripts de ciclo de vida de package.json de npm, Pro)",
                summary: "Enumera los scripts preinstall/install/postinstall/prepare declarados por los archivos package.json bajo node_modules. Muestra código que se ejecuta incondicionalmente al hacer npm install — no es un veredicto de amenaza. Solo Pro.",
                details: """
                • Cómo abrir: menú «Protección contra malware» → «📦 Cotejo de CVE de paquetes (Homebrew)…» → pestaña «Scripts de instalación (npm) (Pro)». Analiza las mismas carpetas de proyecto que la pestaña «Dependencias».
                • Alcance: un nivel bajo node_modules (más un nivel adicional para paquetes @scope/). Nunca desciende al node_modules propio de un paquete.
                • Marcado de referencia únicamente: los comandos que coinciden con curl|sh, wget|sh, eval(, base64 -d o node -e reciben una insignia ⚠️ — una heurística ligera, no un veredicto; muchos scripts legítimos (compilaciones de módulos nativos, etc.) también coinciden.
                • Sin ninguna conexión de red, y nunca se ejecuta nada — un inventario puramente estático.
                • Herramienta MCP: `run_package_lifecycle_script_scan` (argumento `watchedFolders`, solo Pro).
                """,
                recommendation: "Para cualquier script marcado con ⚠️, compruebe si el paquete realmente lo necesita — preste especial atención a los scripts postinstall de paquetes poco conocidos."
            ),
            LocalizedEntry(
                id: "feat_npm_audit_signatures",
                title: "Verificación de firmas/procedencia de npm (npm audit signatures, opcional, Pro)",
                summary: "Contacta con el registro de npm para verificar las firmas/procedencia de los paquetes instalados. La única función de RoamSwitch que se comunica con npmjs.com — desactivada de forma predeterminada, requiere activación explícita y confirmación en cada ejecución. Solo Pro.",
                details: """
                • Cómo activarla: el interruptor «Activar la verificación de firmas de npm» en la pestaña «📦 Cotejo de CVE de paquetes» → «Verificación de firmas de npm (opcional) (Pro)». Esto solo desbloquea el botón «Ejecutar auditoría» de cada carpeta de proyecto — nunca envía nada por sí solo. Cada ejecución se confirma con «¿Contactar con el registro de npm?».
                • Qué hace: ejecuta `npm audit signatures` con la carpeta indicada como directorio de trabajo, contactando con el registro de npm (registry.npmjs.org). Es la única función de RoamSwitch que se comunica con npmjs.com.
                • Salida: se muestra la salida del propio comando npm tal cual (nunca interpretada manualmente). Un código de salida distinto de cero, o términos como «invalid»/«missing registry signature» en la salida, reciben una marca de atención ligera.
                • Si no se encuentra el comando npm, aparece un mensaje que sugiere instalar Node.js/npm.
                • Herramienta MCP: `run_npm_audit_signatures` (argumento `directory`, doble control: Pro más el interruptor de activación).
                """,
                recommendation: "Actívela solo para una auditoría de dependencias antes de desplegar o al investigar una posible vulneración de la cadena de suministro — no es necesario dejarla activada siempre."
            ),
            LocalizedEntry(
                id: "feat_npm_sandboxed_install",
                title: "Instalación npm/pnpm en sandbox (roamswitch-npm, Pro)",
                summary: "Un wrapper de intervención real, no solo detección, que confina únicamente la ejecución de los scripts preinstall/install/postinstall/prepare dentro de un sandbox sin acceso a la red (sandbox-exec), ejecutando realmente la instalación en su nombre. Solo Pro.",
                details: """
                • Cómo activarlo: el botón «Instalar» en «📦 Cotejo de CVE de paquetes» → «Instalación en sandbox (npm/pnpm) (Pro)» coloca el wrapper de línea de comandos `roamswitch-npm` en ~/Library/Application Support/RoamSwitch/bin/.
                • Flujo de dos fases: ① La fase de descarga ejecuta `npm install --ignore-scripts` / `pnpm install --ignore-scripts` con normalidad, con acceso a la red. ② La fase de scripts ejecuta `npm rebuild` / `pnpm rebuild` (además de `run prepare` si la raíz lo declara) bajo un perfil de sandbox-exec con `(deny network-outbound)`.
                • Mecanismo de sandbox: la versión de Linux usa bwrap para restringir el sistema de archivos; como macOS no tiene una tecnología equivalente, en su lugar se usa el bloqueo de red, verificado en hardware real (`(allow default)` + `(deny network-outbound)`). No se restringen las lecturas/escrituras de archivos ni el lanzamiento de procesos hijos.
                • Alias de shell: se pueden añadir dos líneas de alias que enrutan `npm`/`pnpm` a través del wrapper al archivo de configuración de su shell (opcional, solo se añaden — el contenido existente no se modifica).
                • Vista previa: antes de ejecutar, puede listar los scripts de ciclo de vida de la carpeta del proyecto (el mismo escáner que usa «Inventario de scripts de instalación»).
                • Si sandbox-exec no está disponible o falla, nunca se recurre silenciosamente a una ejecución sin sandbox. yarn no es compatible. No hay herramienta GTK/MCP: es una herramienta de línea de comandos que se usa desde una terminal.
                """,
                recommendation: "Para proyectos con paquetes desconocidos, o proyectos obtenidos de fuentes externas, use `roamswitch-npm install` en lugar de un npm/pnpm install habitual."
            ),
            LocalizedEntry(
                id: "feat_typosquat_guard",
                title: "Detección de typosquatting (npm/pnpm package.json, Pro)",
                summary: "Compara los nombres de dependencias de package.json con una lista de paquetes npm populares mediante distancia de edición (Levenshtein 1-2), señalando un posible typosquatting como expres→express o loadash→lodash. La propia aplicación no establece ninguna conexión de red para ello. Solo Pro.",
                details: """
                • Alcance: solo las dependencies/devDependencies/optionalDependencies propias del proyecto en package.json (peerDependencies queda fuera de alcance). node_modules (dependencias transitivas ya instaladas) también queda deliberadamente fuera de alcance — un error tipográfico se introduce en el momento en que una persona añade una dependencia a package.json.
                • Lógica de comparación: una implementación estándar de programación dinámica de la distancia de Levenshtein compara cada nombre de dependencia con una lista de paquetes npm populares. Los paquetes con ámbito (`@scope/pkg`) se comparan por su nombre base (`pkg`). Los candidatos cuya longitud difiere en más de 2 se omiten mediante un filtro previo económico. El umbral es una distancia de edición de hasta 2 para nombres populares de 8 o más caracteres, y solo distancia 1 para nombres más cortos.
                • Cómo se mantiene actualizada la lista: la lista de nombres de paquetes populares con la que se compara la distribuye `PackageCveMapUpdater` mediante el mismo manifiesto diario, de solo recepción y firmado con Ed25519 que los mapas de CVE (una semilla incorporada en tiempo de compilación más una sustitución de dos niveles, prefiriendo la que tenga el `mapVersion` más reciente). La lista puede actualizarse sin esperar a una versión de la aplicación.
                • Información de referencia, no un veredicto — una lista blanca conocida suprime algunos paquetes legítimos similares (por ejemplo, preact), pero no es exhaustiva.
                • Cómo abrirlo: pestaña «📦 Cotejo de CVE de paquetes» → «Detección de typosquatting (Pro)», dirigida a las mismas carpetas de proyecto que la pestaña «Dependencias». MCP: `run_typosquat_scan` (argumento `watchedFolders`, solo Pro).
                """,
                recommendation: "Vuelva a comprobar cualquier dependencia marcada con ⚠️ para ver si se trata realmente de un error tipográfico — preste especial atención a los nombres de paquetes desconocidos."
            ),
            LocalizedEntry(
                id: "feat_port_scan_guard",
                title: "Detección de escaneo de puertos entrante (bloqueo automático, Pro)",
                summary: "Detecta y notifica sobre una IP de origen que se ha conectado a numerosos puertos distintos (15 o más) en poco tiempo (5 minutos), la firma clásica de herramientas de reconocimiento como nmap/masscan. Un origen de escaneo detectado se bloquea automáticamente durante 10 minutos de forma predeterminada. Solo Pro.",
                details: """
                • Cómo funciona: el helper privilegiado supervisa los registros de pf (filtro de paquetes) mediante `tcpdump -i pflog0` y marca una IP de origen que alcanza suficientes puertos de destino distintos en una ventana corta. La detección se basa únicamente en los registros; nunca modifica ni inspecciona el contenido del tráfico. Corresponde a `port_scan_detect.rs` de la edición Linux (nftables `log` + `journalctl`).
                • Bloqueo automático: un origen de escaneo detectado se añade a una regla de pf y se bloquea durante 10 minutos de forma predeterminada mediante `PFRulesetCoordinator`. El bloqueo automático puede activarse o desactivarse de forma independiente a la propia función de detección.
                • Notificaciones: se envía una notificación de macOS en cada detección (y bloqueo), y también se registra en la línea temporal de incidentes unificada.
                • Cómo abrirlo: barra de menús → “Monitor de puertos y dispositivos” → “🔍 Detección de escaneo de puertos entrante (Pro)”. Tanto activar como desactivar pasan por un cuadro de confirmación. Desactivado de forma predeterminada.
                """,
                recommendation: "No existe una lista blanca por IP, y un bloqueo se levanta automáticamente a los 10 minutos. Si ejecuta regularmente una herramienta de escaneo legítima en casa o en el trabajo (inventario de activos, escaneo de vulnerabilidades, etc.), considere desactivar el bloqueo automático (dejando solo la detección/notificación) mientras se ejecuta, para evitar bloqueos repetidos por falsos positivos."
            ),
            LocalizedEntry(
                id: "feat_sensor_pairing",
                title: "Emparejamiento de RoamSwitch Sensor (código de emparejamiento, Pro)",
                summary: "Gestiona el emparejamiento de confianza mutua con un producto independiente, “RoamSwitch Sensor” (un concentrador de auditoría activa dedicado), en la misma LAN. Usa un flujo de emparejamiento activo mediante un código que emite el Sensor — sin descubrimiento automático por mDNS, ya que se asume que el Sensor funciona con una IP fija. Solo Pro.",
                details: """
                • Cómo funciona: genera y conserva de forma persistente el propio par de claves Ed25519 de este dispositivo. Para emparejar, este dispositivo se conecta al listener TCP del Sensor (puerto 50543) con un código de emparejamiento de un solo uso emitido por el operador del Sensor (caduca 10 minutos después de emitirse), junto con la dirección/nombre de host de este dispositivo. Si el código es válido, el Sensor añade la clave pública de este dispositivo a su lista de confianza.
                • Solicitar una auditoría: una vez emparejado, “Solicitar auditoría al Sensor” pide al Sensor que ejecute una auditoría activa (verificación de accesibilidad). Como el Sensor genera los resultados de forma asíncrona, el propio proceso auxiliar privilegiado (siempre activo) de este dispositivo consulta el resultado cada 5 minutos, hasta 5 veces. Los resultados obtenidos también se guardan en este dispositivo y se muestran en “Resultados de auditoría” en la pantalla de ajustes.
                • Cómo abrirlo: barra de menús → “Monitor de puertos y dispositivos” → “🔍 Emparejamiento de RoamSwitch Sensor…”. Muestra la clave pública/dirección de este propio dispositivo (con botón de copiar), los Sensors emparejados (con botón de desemparejar), un formulario para introducir el código de emparejamiento y la lista de resultados de auditoría.
                • Usa el mismo protocolo de control TCP que la edición para Linux (`roamswitch-core::sensor_pairing`) — puerto 50543, JSON delimitado por saltos de línea, firmas Ed25519.
                """,
                recommendation: "Use únicamente un código de emparejamiento emitido realmente desde la pantalla de operador de un Sensor que usted mismo configuró. Si le piden introducir un código desconocido, no empareje — consulte con quien administre la red."
            ),
            LocalizedEntry(
                id: "feat_security_health_checker",
                title: "Auditoría de seguridad del Mac (18 puntos, puntuación y pasos de corrección)",
                summary: "Comprueba 18 puntos en seis áreas (endurecimiento del sistema, defensa de red, autenticación y control de acceso, exposición de puertos, protección contra malware y defensa física de dispositivos) y muestra una puntuación de 0 a 100, una nota, y los pasos para corregir cada punto no superado. Disponible en la edición gratuita.",
                details: """
                • Endurecimiento del sistema: 1. FileVault, 2. SIP (Protección de la integridad del sistema), 3. Gatekeeper, 4. actualizaciones de seguridad automáticas, 5. Apple XProtect.
                • Defensa de red: 6. cortafuegos de macOS, 7. modo sigiloso, 8. fuerza del cifrado Wi-Fi, 9. monitor de suplantación ARP, 10. fijación ARP de la puerta de enlace.
                • Autenticación y control de acceso: 11. configuración de inicio de sesión SSH remoto (inicio de sesión root desactivado, solo autenticación por clave), 12. escalada de privilegios sudo (auditoría `NOPASSWD`).
                • Servicios y exposición de puertos: 13. puertos expuestos.
                • Protección contra malware y descargas: 14. Protección web y correo, 15. Protección contra amenazas DNS, 16. protección contra phishing y enlaces maliciosos (aviso de sitio fraudulento de Safari).
                • Puertos físicos y dispositivos: 17. Protección física del puerto contra USB no autorizado / BadUSB, 18. protección de conexión de accesorios de macOS (Apple Silicon).
                • No aplicable: el cortafuegos y el modo sigiloso en una red de confianza, el SSH cuando el inicio de sesión remoto está desactivado, la auditoría sudo antes de conectar el asistente, y la protección de accesorios en los Mac Intel se excluyen de la puntuación.
                • Notas: 100 = S, 85-99 = A, 70-84 = B, por debajo de 70 = C. También disponible mediante la herramienta MCP `get_security_report`.
                """,
                recommendation: "Abre el informe de auditoría con regularidad, resuelve los puntos marcados con ⚠️ siguiendo los pasos de corrección, y mantén al menos la nota A."
            ),
            LocalizedEntry(
                id: "feat_autonomous_sentinel",
                title: "Patrulla autónoma en segundo plano, actualización de definiciones ClamAV y análisis programados",
                summary: "Cada 4 horas, actualiza en segundo plano la auditoría de seguridad, los puertos, los dispositivos USB y el estado de XProtect (todas las ediciones). Pro además avisa de caídas de puntuación, actualiza automáticamente las definiciones de ClamAV, y ejecuta un análisis antivirus diario.",
                details: """
                • Auditoría periódica (todas las ediciones): unos 30 segundos después del inicio y después cada 4 horas, para que los resultados se mantengan actualizados aunque permanezcas horas en la misma red.
                • Aviso de caída de puntuación (Pro): notifica cuando la puntuación cae por debajo de 80 o fallan 4 puntos o más.
                • Definiciones de ClamAV (Pro): ejecuta `freshclam` en silencio.
                • Análisis programado (Pro): una vez al día, analiza `~/Downloads`, `~/Desktop` y `~/Library/LaunchAgents` con ClamAV. Las amenazas se ponen en cuarentena automáticamente con una alerta urgente; un resultado limpio genera solo un aviso discreto de finalización. Si solo se encuentra la firma de prueba EICAR, no se muestra nada, y solo se registra en el historial de notificaciones.
                """,
                recommendation: "En Pro, instala ClamAV para que las actualizaciones de definiciones y los análisis programados se ejecuten automáticamente."
            ),
            LocalizedEntry(
                id: "feat_simulation_self_test",
                title: "Herramientas de simulación (autoprueba)",
                summary: "Comprueba con seguridad que la defensa contra ransomware, el Air-Gap de detección de malware y la detección de riesgos de Docker funcionan, sin ningún ataque real ni daño a archivos.",
                details: """
                • Ubicación: en la parte inferior de «Protección contra malware (XProtect y ClamAV)».
                • 🚨 Simulación de defensa contra ransomware (Modo prueba)…: ejecuta los mismos pasos que un intento de cifrado detectado para comprobar el Air-Gap y la ventana de emergencia. No se daña ningún archivo.
                • 🚨 Simulación de Air-Gap por detección de malware (prueba)…: ejecuta los mismos pasos que una detección real de XProtect para comprobar la contención y la ventana de emergencia. El evento se etiqueta como simulación.
                • ⚠️ Simulación de detección de riesgos de Docker (Modo prueba)…: comprueba que llega la notificación de contenedor privilegiado. Docker no se toca.
                • Nota: las pruebas de Air-Gap sí cortan la red temporalmente de verdad. Libérala desde la ventana de emergencia (también se restaura sola en 10 minutos).
                • Para probar la protección de descargas puedes usar un archivo de prueba EICAR inofensivo (sin aviso; se registra en el historial de notificaciones).
                """,
                recommendation: "Ejecuta una simulación una vez tras activar Pro o cambiar ajustes para confirmar que las notificaciones y el Air-Gap se comportan como se espera."
            ),
            LocalizedEntry(
                id: "feat_privileged_helper",
                title: "Herramienta asistente con privilegios (RoamSwitchHelper, XPC)",
                summary: "Solo las operaciones que necesitan permisos de root (cortafuegos PF, servicios compartidos, DNS, Air-Gap, etc.) las realiza un asistente LaunchDaemon con privilegios separados, mediante XPC.",
                details: """
                • Separación de privilegios: la app principal se ejecuta con permisos de usuario normales y solo delega en `RoamSwitchHelper` los cambios de reglas pf, el control de demonios de compartición, los ajustes DNS, la fijación ARP, el hash de archivos críticos y tareas similares.
                • Registro: se registra mediante el SMAppService de macOS como un LaunchDaemon incluido en la app. El primer uso requiere aprobación en Ajustes del Sistema → General → Elementos de inicio y extensiones. No puede registrarse si la app no está en la carpeta Aplicaciones (faq_install_location).
                • Demonios acompañantes: también se registran los LaunchDaemons asistentes para la red de seguridad del Air-Gap (liberación automática tras 10 minutos) y la puerta de arranque (hasta 90 segundos).
                • Verificación: las firmas de código (Team ID) se comprueban en las conexiones XPC, rechazando llamadas de procesos no autorizados.
                • Nueva aprobación tras una actualización: la app intenta cambiar automáticamente al nuevo asistente, pero macOS puede dejarlo pendiente de aprobación de todos modos. En ese caso, el icono de la barra de menús cambia a un aviso y muestra «⚠️ Se requiere nueva aprobación tras la actualización», además de enviarse una notificación.
                """,
                recommendation: "Aprueba el asistente cuando se te solicite en el primer inicio. Si no está aprobado, el menú muestra «⚠️ Aprobar el asistente…». Si este aviso o notificación aparece tras una actualización, los mismos pasos (Ajustes del Sistema > General > Ítems de inicio y extensiones) permiten volver a aprobarlo."
            ),
            LocalizedEntry(
                id: "feat_mcp_server",
                title: "Integración del servidor MCP (acceso de solo lectura para asistentes de IA)",
                summary: "RoamSwitch.app incluye un servidor MCP (Model Context Protocol) de solo lectura, para que asistentes de IA como Claude puedan preguntar por el estado de seguridad de tu Mac. No hay ninguna herramienta que cambie ajustes ni bloquee nada.",
                details: """
                • Transporte: solo stdio local. Binario: `/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`.
                • Herramientas principales: `get_security_report` (auditoría de seguridad), `get_exposed_ports`, `get_guard_status`, `audit_url_safety`, `audit_secrets`, `audit_security_logs`, `get_quarantine_status`, `get_notification_history`, `get_canary_status`, `get_port_anomaly_incidents`, `get_runtime_threat_status`, `get_incident_timeline` (cronología de incidentes de contención), `get_network_history` (aprendizaje del historial de red), `run_package_cve_scan`, `run_package_cve_scan_languages`, `run_active_vuln_scan` (la única herramienta que envía tráfico, sondas no destructivas solo hacia 127.0.0.1), y `get_app_help` (esta base de conocimiento).
                • Recursos: `roamswitch://docs/features`, `roamswitch://docs/alerts-and-messages`, `roamswitch://docs/settings-guide`, `roamswitch://docs/troubleshooting`.
                • Idioma: las respuestas siguen el ajuste de idioma de la app. `get_app_help` acepta un argumento `language` (ja / en / zh-Hans / zh-Hant / ko / de / fr / es / it / pt-PT).
                • Seguridad: al ser de solo lectura, ni siquiera una IA manipulada mediante inyección de instrucciones puede cambiar el nivel de protección ni aislar puertos.
                """,
                recommendation: "Para la configuración, consulta faq_mcp_setup. Puedes preguntar en lenguaje natural, como «¿Está mi Mac seguro ahora mismo?» o «¿Qué significa esta notificación?»"
            ),
            LocalizedEntry(
                id: "feat_license_pro_tier",
                title: "Licencia Pro de por vida (compra única, hasta 2 Mac)",
                summary: "Pro es una licencia de por vida de compra única (2980 ¥ / 19,99 $) utilizable en hasta 2 Mac. El token de licencia firmado con Ed25519 se verifica en el dispositivo, así que Pro sigue funcionando sin conexión tras activarse.",
                details: """
                • Funciones de Pro: las defensas automáticas marcadas con (Pro) en el menú (detección de ransomware mediante archivos señuelo, corte vinculado a XProtect, bloqueo automático de puerto desconocido y aislamiento de servidor de desarrollo, bloqueo automático de suplantación ARP, fijación ARP/NDP de la puerta de enlace, túnel VPN, protecciones BadUSB y de almacenamiento USB, Protección web y correo, Protección contra amenazas DNS, Protección de enlaces, desactivación automática de Bluetooth, defensa ClickFix, vigilancia de registros de inicio automático, detección de riesgos de Docker, supervisión de manipulación de archivos críticos, auditoría automática de registros), notificaciones de amenazas en tiempo real, avisos de patrulla y análisis programados, exportación CSV de registros, y más.
                • Tipos de licencia: Pro de por vida (2 Mac) y Team de por vida (5 Mac).
                • Activación: introduce tu clave de licencia (ROAM-XXXX-…) desde «💎 Activar / Comprar Pro…». El token firmado emitido por el servidor se verifica con la clave pública incluida en la app y se guarda en el llavero.
                • Desactivación: desde la ventana de licencia. Elimina la licencia de este Mac y libera la plaza en el servidor (la desactivación local siempre ocurre aunque falle la solicitud de red).
                • Al caducar: las protecciones exclusivas de Pro se desactivan automáticamente, y se liberan el túnel VPN y el aislamiento de puertos.
                """,
                recommendation: "Considera Pro si quieres contención automática, defensa en tiempo real y avisos de patrulla. Al cambiar de Mac, desactívala primero en el antiguo antes de activarla en el nuevo."
            ),
        ]
    }

    // MARK: - Alerts: network, devices, links

    private static func alertsEsNetwork() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "alert_arp_spoofing",
                title: "⚠️ Alerta de suplantación ARP (MITM)",
                summary: "Aparece cuando hay indicios de que un dispositivo de tu red se hace pasar por el router (puerta de enlace) para espiar o manipular tu tráfico.",
                details: """
                • Causa: un atacante envía respuestas ARP falsificadas para que tu tráfico pase por él (ataque de intermediario). Se detecta cuando la IP de la puerta de enlace se mantiene igual pero su dirección MAC cambia de repente. Un reinicio de router o un cambio de Wi-Fi en malla también pueden causarlo.
                • Defensa automática: en Bloqueo máximo con «Bloqueo automático al detectar suplantación ARP (suplantación de red) (Pro)» activado, contención Air-Gap inmediata. En otros niveles, solo notificación, y el menú muestra «Suplantación ARP detectada: cortar toda la red ahora».
                """,
                recommendation: """
                1. Deja de introducir contraseñas, hacer pagos o transmitir tráfico de trabajo en esta red de inmediato.
                2. En Wi-Fi público o una red desconocida, elige «cortar toda la red ahora» en el menú o desactiva el Wi-Fi.
                3. Si necesitas acceso a internet, cambia a una conexión segura como compartir internet o el túnel VPN.
                4. Sigue usando la red solo si sabes con certeza que es un falso positivo, por ejemplo justo después de reiniciar tu router doméstico.
                """
            ),
            LocalizedEntry(
                id: "alert_evil_twin_ssid",
                title: "⚠️ Posible red Wi-Fi gemela malvada detectada",
                summary: "Aparece cuando el nombre (SSID) del Wi-Fi al que te has unido se parece mucho a una red que has usado antes. Podría ser un punto de acceso falso malicioso (gemelo malvado).",
                details: """
                • Causa: un atacante configura un punto de acceso falso cuyo nombre difiere del legítimo en solo uno o dos caracteres para atraer a la gente. El aprendizaje del historial de red (feat_network_history_guard) lo juzga a partir de la distancia de edición con los nombres aprendidos y del hardware de puerta de enlace diferente.
                • Control de falsos positivos: los nombres cortos y los SSID adicionales difundidos por el mismo hardware de puerta de enlace no lo activan.
                • Defensa automática: solo notificación. Al ser una red no registrada, se aplica el nivel de Protección predeterminada fuera de casa.
                """,
                recommendation: """
                1. No inicies sesión ni introduzcas información personal en este Wi-Fi.
                2. Confirma el nombre oficial de la red (carteles en la tienda u oficina) y desconéctate si no coincide.
                3. Si necesitas seguir usándola, conecta el túnel VPN.
                """
            ),
            LocalizedEntry(
                id: "alert_unencrypted_wifi",
                title: "⚠️ Conectado a un Wi-Fi sin cifrar",
                summary: "Aparece cuando te unes a una red Wi-Fi abierta sin contraseña ni cifrado (WPA2 / WPA3), o a una red WEP antigua.",
                details: """
                • Causa: el enlace inalámbrico no está cifrado, así que cualquiera cerca puede capturar el tráfico.
                • Defensa automática: si la red no está registrada, la Protección predeterminada fuera de casa (inicialmente Bloqueo máximo) bloquea las conexiones entrantes y los servicios de compartición.
                """,
                recommendation: """
                1. Si es posible, conecta el túnel VPN o cambia a una conexión de confianza como compartir internet.
                2. Evita iniciar sesión o introducir información personal en sitios que no sean HTTPS.
                3. Confirma en el menú que el nivel de protección es Bloqueo máximo.
                """
            ),
            LocalizedEntry(
                id: "alert_port_anomaly",
                title: "🚨 Puerto de escucha desconocido bloqueado automáticamente",
                summary: "Aparece cuando un programa que antes no estaba expuesto empezó a exponer un puerto a la LAN en 0.0.0.0 y el acceso desde el exterior se bloqueó automáticamente (se muestra «Puerto de escucha desconocido detectado (fallo del bloqueo)» si el bloqueo no tuvo éxito).",
                details: """
                • Causa: el inicio de un servidor de desarrollo (Next.js, Vite, Python, Docker), una app de recepción LAN como LocalSend o Syncthing lanzándose por primera vez, o una puerta trasera o app maliciosa que empieza a escuchar.
                • Defensa automática: pf bloquea solo el acceso externo (el propio Mac y localhost pueden seguir usándolo). Los demonios del sistema de macOS quedan excluidos.
                """,
                recommendation: """
                1. Comprueba si reconoces el nombre del proceso, el PID y el puerto que muestra la notificación (también visibles en Puertos expuestos).
                2. Si es tu propio servidor o una app de recepción LAN, permítelo con el botón «Permitir» de la notificación o desde la pantalla de auditoría de puertos. Quedará permitido de forma permanente a partir de entonces.
                3. Para servidores de desarrollo, reiniciar vinculado a `127.0.0.1` es la opción más segura.
                4. Si no lo reconoces, mantenlo bloqueado, cierra el proceso y ejecuta la auditoría de seguridad y un análisis antivirus.
                """
            ),
            LocalizedEntry(
                id: "alert_exposed_database",
                title: "🚨 Servicio de base de datos sin autenticar expuesto externamente",
                summary: "Aparece cuando un servicio que a menudo carece de autenticación por defecto (Redis, MongoDB, Memcached, Elasticsearch) queda expuesto a la LAN sin protección de cortafuegos.",
                details: """
                • Causa: un servicio de base de datos o de backend se inició en 0.0.0.0 mientras el nivel de protección actual permite conexiones entrantes. Cualquiera en la misma red podría llegar a leer o escribir los datos.
                • Defensa automática: solo notificación (Pro), que no se repite para el mismo puerto.
                """,
                recommendation: """
                1. Cambia la dirección de escucha del servicio a `127.0.0.1` o activa la autenticación.
                2. Si no puedes solucionarlo de inmediato, abre el puerto en Puertos expuestos y elige «Aislar puerto».
                3. Usa el Bloqueo máximo en redes públicas.
                """
            ),
            LocalizedEntry(
                id: "alert_unapproved_keyboard",
                title: "⚠️ Teclado no autorizado / conexión BadUSB detectada",
                summary: "La notificación y la ventana de aprobación que aparecen cuando se conecta un nuevo teclado USB que no está en la lista de permitidos (o un dispositivo que se hace pasar por uno, como un cable modificado) y sus pulsaciones se bloquean hasta que se aprueba.",
                details: """
                • Causa: la conexión de un nuevo teclado externo o una estación de acoplamiento, o de un dispositivo de inyección de pulsaciones como un Rubber Ducky.
                • Defensa automática: solo se bloquean las pulsaciones de ese dispositivo (los demás teclados siguen funcionando). La ventana «⚠️ Dispositivo USB / teclado desconocido detectado» solicita aprobación.
                """,
                recommendation: """
                1. Si es un teclado de confianza que conectaste tú mismo, haz clic en «Confiar y permitir». Se añadirá a la lista de permitidos y se activará la entrada.
                2. Si no lo reconoces, o aparece sin que hayas conectado nada, haz clic en «Rechazar y mantener bloqueado» y desconecta el dispositivo.
                """
            ),
            LocalizedEntry(
                id: "alert_scripted_keyboard",
                title: "🚨 Este teclado muestra indicios de escritura automatizada (guionizada)",
                summary: "Aparece cuando un teclado a la espera de aprobación envía pulsaciones a intervalos demasiado rápidos y uniformes para una persona. Es muy probable una inyección automatizada de comandos (ataque BadUSB).",
                details: """
                • Causa: un Rubber Ducky, Flipper Zero, Arduino/Digispark o similar intentó escribir comandos precargados a gran velocidad. Se determina mediante el análisis del ritmo de pulsaciones: tras al menos 5 intervalos, una media de 12 ms o menos, o de 45 ms o menos con una uniformidad muy alta.
                • Defensa automática: las pulsaciones del dispositivo ya estaban bloqueadas antes de la aprobación y nunca llegaron al Mac. Este aviso solo añade pruebas para tu decisión.
                """,
                recommendation: """
                1. Elige siempre «Rechazar y mantener bloqueado» en la ventana de aprobación.
                2. Desconecta el dispositivo de inmediato y comprueba de dónde procede (una memoria USB encontrada, un cable regalado, etc.).
                3. Como precaución, ejecuta la auditoría de seguridad y revisa los registros de inicio automático.
                """
            ),
            LocalizedEntry(
                id: "alert_untrusted_usb",
                title: "🔒 Almacenamiento USB montado como solo lectura / 🔌 Almacenamiento USB no autorizado bloqueado automáticamente",
                summary: "Aparece cuando se conecta una unidad USB o un disco externo que no está en la lista de permitidos y se ha montado como solo lectura a la espera de tu aprobación, o ha sido expulsado.",
                details: """
                • Causa: se conectó un dispositivo de almacenamiento no registrado. Esto evita el robo de datos y la introducción de archivos maliciosos.
                • Defensa automática: se vuelve a montar como solo lectura con un diálogo «¿Permitir el almacenamiento USB «…»?». Elegir Expulsar lo expulsa y envía «Almacenamiento USB no autorizado bloqueado automáticamente».
                """,
                recommendation: """
                1. Si es tu dispositivo, elige «Permitir lectura y escritura» o «Permitir como solo lectura». Se añadirá a la lista de permitidos y se aplicará automáticamente la próxima vez.
                2. Si no lo reconoces, elige «Expulsar».
                3. Puedes cambiar la lista de permitidos más tarde en «Ajustes de protección USB / BadUSB…».
                """
            ),
            LocalizedEntry(
                id: "alert_malware_usb",
                title: "🚨 Malware detectado en almacenamiento USB",
                summary: "Aparece cuando el análisis de ClamAV realizado antes de conectar un dispositivo de almacenamiento USB en lectura y escritura encuentra archivos infectados.",
                details: """
                • Causa: hay archivos infectados en la unidad USB.
                • Defensa automática: el volumen se expulsa de inmediato para que el Mac no se infecte.
                """,
                recommendation: """
                1. Formatea o desinfecta la unidad en un entorno seguro aparte antes de volver a usarla.
                2. Ejecuta un análisis rápido o de carpeta con ClamAV para asegurarte de que el propio Mac no está infectado.
                """
            ),
            LocalizedEntry(
                id: "alert_link_guard_blocked",
                title: "🛑 Protección de enlaces: conexión bloqueada",
                summary: "Aparece cuando la Protección de enlaces bloqueó automáticamente una conexión hacia un sitio sospechoso de estafa o phishing (registrado en la lista de amenazas, o un homógrafo de marca).",
                details: """
                • Causa: un enlace de correo o redes sociales, un anuncio, o una app intentó conectarse a un dominio de estafa conocido.
                • Defensa automática: la extensión del sistema descarta la conexión, o la alternativa mediante hosts resuelve el dominio hacia 0.0.0.0, sea cual sea el navegador o la app.
                """,
                recommendation: """
                1. Si no lo esperabas, no hace falta nada más; no introduzcas información en esa página.
                2. Si un sitio legítimo que necesitas se bloqueó por error, usa «Permitir una vez (5 min)» en la notificación o añádelo a la lista de permitidos.
                """
            ),
            LocalizedEntry(
                id: "alert_link_guard_warn_hold",
                title: "⚠️ Protección de enlaces: conexión en espera",
                summary: "En modo Advertencia, la notificación y el panel en primer plano que aparecen cuando se ha pausado una conexión hacia un sitio sospechoso de suplantación de marca o estafa mientras decides si permitirla.",
                details: """
                • Causa: una conexión hacia un dominio que activa una advertencia (suplantación de subdominio, TLD de alto riesgo, etc.).
                • Defensa automática: la conexión se pausa a la espera de tu respuesta. Sin respuesta en unos 8 segundos, se bloquea (falla cerrado). Ese resultado no se guarda en caché, así que la próxima visita volverá a preguntar. Las respuestas que des se recuerdan.
                """,
                recommendation: """
                1. Si la abriste a propósito y confías en el sitio, elige «Permitir».
                2. Si no lo reconoces o no estás seguro, elige «Bloquear» o simplemente espera (se bloqueará automáticamente).
                3. Si se bloqueó por error, recarga la página para que vuelva a preguntar.
                """
            ),
            LocalizedEntry(
                id: "alert_dangerous_url",
                title: "🛑 Enlace peligroso / phishing sospechoso (Auditoría de seguridad de enlaces)",
                summary: "Aparece cuando la Auditoría de seguridad de enlaces (o `audit_url_safety`) considera peligrosa una URL debido a homógrafos, un subdominio suplantado, un TLD de alto riesgo, y similares.",
                details: """
                • Comprobaciones: caracteres homógrafos (Punycode), subdominios que imitan grandes empresas, TLD habituales en phishing, HTTP sin cifrar, direcciones IP en bruto, y más.
                • Puntuación: por debajo de 50 es peligroso; entre 50 y 79 es precaución.
                """,
                recommendation: """
                1. No abras el enlace.
                2. Elimina el mensaje e infórmalo a tu equipo de seguridad si procede.
                """
            ),
            LocalizedEntry(
                id: "alert_helper_disconnected",
                title: "⚠️ Asistente no conectado",
                summary: "Aparece cuando no se puede establecer la comunicación XPC con la herramienta asistente con privilegios (RoamSwitchHelper).",
                details: """
                • Causa: la ejecución en segundo plano no está aprobada en Elementos de inicio y extensiones, el asistente se detuvo tras una actualización de macOS, o la app está fuera de la carpeta Aplicaciones (en Descargas o dentro de la imagen de disco).
                • Impacto: las operaciones que necesitan permisos de root (cambiar el nivel de protección, contención Air-Gap, ajustes DNS, supervisión de archivos críticos, etc.) no pueden ejecutarse.
                """,
                recommendation: """
                1. Elige «⚠️ Aprobar el asistente…» en el menú para abrir los pasos de aprobación.
                2. En Ajustes del Sistema → General → Elementos de inicio y extensiones, activa RoamSwitchHelper bajo Permitir en segundo plano.
                3. Asegúrate de que RoamSwitch está en la carpeta Aplicaciones.
                4. Si eso no soluciona el problema, sigue faq_helper_troubleshooting.
                """
            ),
            LocalizedEntry(
                id: "alert_score_drop",
                title: "⚠️ Aviso de degradación de la seguridad del Mac",
                summary: "Enviada por la patrulla autónoma cuando la puntuación de seguridad cae por debajo de 80 o fallan 4 puntos o más (Pro).",
                details: """
                • Causa: un cambio en los ajustes o el entorno, como desactivar FileVault o el cortafuegos, un puerto peligroso expuesto, o una protección detenida.
                • Criterios: puntuación por debajo de 80, o 4 puntos o más en fallo.
                """,
                recommendation: """
                1. Abre el informe de auditoría desde el menú (o usa la herramienta MCP `get_security_report`).
                2. Resuelve los puntos marcados con ⚠️ siguiendo los pasos de corrección mostrados.
                """
            ),
        ]
    }

    // MARK: - Alerts: malware, containment, audit

    private static func alertsEsMalware() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "alert_quarantined_download",
                title: "🚨 Archivo descargado peligroso puesto en cuarentena",
                summary: "Aparece cuando un archivo guardado desde un navegador, Mail o una app de chat contenía una amenaza y se movió a la bóveda de cuarentena (se muestra «fallo de la cuarentena» si el movimiento no tuvo éxito).",
                details: """
                • Causa: el archivo descargado contenía malware, un troyano, un reverse shell o similar.
                • Defensa automática: se mueve a `~/Library/Application Support/RoamSwitch/Quarantine/` para que no pueda ejecutarse. Si la comprobación de firma estática lo señaló pero ClamAV no, la notificación menciona un posible falso positivo.
                """,
                recommendation: """
                1. Si la cuarentena tuvo éxito, el archivo no puede ejecutarse.
                2. Abre «📦 Gestionar archivos en cuarentena…» y elige «Eliminar permanentemente» si no lo reconoces.
                3. Usa «Restaurar» o «Excluir y restaurar» solo para falsos positivos seguros.
                4. Si la cuarentena falló, elimina manualmente el archivo en la ruta que indica la notificación.
                """
            ),
            LocalizedEntry(
                id: "alert_eicar_test_signature",
                title: "🧪 Firma de prueba EICAR detectada (inofensiva) — registrada solo en el historial de notificaciones",
                summary: "Explica cómo se gestiona el archivo de prueba EICAR, inofensivo, usado para comprobar el software antivirus. No es una amenaza real, así que no aparece ningún aviso y nada se pone en cuarentena ni se bloquea; solo se registra en el historial de notificaciones.",
                details: """
                • Se aplica a: la Protección web y correo, los análisis rápidos/de carpeta de ClamAV, y el análisis programado de la patrulla por igual.
                • Comportamiento: el archivo se queda donde está. «Firma de prueba EICAR detectada (inofensiva)» se registra en «🔔 Historial de notificaciones…».
                • Motivo: los avisos de advertencia para no amenazas enterrarían las alertas realmente importantes.
                """,
                recommendation: """
                1. No hace falta ninguna acción. Si colocaste el archivo con fines de prueba, elimínalo tras confirmar el resultado.
                2. Puedes confirmar que el análisis funciona comprobando el registro en el historial de notificaciones.
                """
            ),
            LocalizedEntry(
                id: "alert_pickle_model",
                title: "⚠️ Descarga de un modelo de IA en formato Pickle detectada",
                summary: "Aparece cuando se descarga un archivo de modelo de IA `.pkl` / `.pickle` / `.pt`. El formato Pickle puede ejecutar código arbitrario con solo cargarse.",
                details: """
                • Causa: se guardó un archivo de modelo desde Hugging Face, Civitai o similar.
                • Defensa automática: solo un aviso (el archivo no se pone en cuarentena).
                """,
                recommendation: """
                1. No cargues modelos a menos que provengan de una fuente oficial de confianza.
                2. Cuando sea posible, usa el mismo modelo en formato `.safetensors` o `.gguf`.
                """
            ),
            LocalizedEntry(
                id: "alert_ransomware_activity",
                title: "🚨 DEFENSA AUTOMÁTICA CRÍTICA: actividad de ransomware bloqueada",
                summary: "La notificación urgente y la ventana de emergencia que aparecen cuando un archivo señuelo (canario) se modificó, eliminó o renombró y se activaron la contención Air-Gap, el cierre de la compartición y la pausa del proceso sospechoso.",
                details: """
                • Causa: un proceso como un ransomware intentando cifrar o destruir archivos en tus carpetas de usuario (o la ejecución de una simulación).
                • Defensa automática: se corta todo el tráfico y se desactiva el Wi-Fi, se detienen SMB / SSH / Compartir pantalla, y el proceso sospechoso se pausa (SIGSTOP). La ventana de emergencia muestra si el corte tuvo éxito, el proceso sospechoso, y los archivos que podrían haberse visto afectados.
                """,
                recommendation: """
                1. Guarda tu trabajo abierto y cierra todas las apps sospechosas.
                2. En el Monitor de actividad, busca procesos con un uso de CPU o escritura en disco disparado y fuerza el cierre de los que no reconozcas.
                3. Comprueba los archivos que podrían haberse visto afectados y tus copias de seguridad (Time Machine, etc.).
                4. Una vez seguro, libera la contención desde la ventana de emergencia (se restaura la red, se reanuda el proceso pausado, y se regeneran los archivos señuelo).
                """
            ),
            LocalizedEntry(
                id: "alert_runtime_threat_airgap",
                title: "🚨 XProtect detectó malware — red cortada automáticamente",
                summary: "La ventana de emergencia y la notificación que aparecen cuando XProtect / XProtect Remediator de Apple condenó un archivo como malware y la desconexión automática vinculada a XProtect activó la contención Air-Gap.",
                details: """
                • Causa: el motor de malware de Apple determinó que un archivo que descargaste o ejecutaste era malicioso.
                • Defensa automática: se corta todo el tráfico y se desactiva el Wi-Fi, restaurado automáticamente en un máximo de 10 minutos si no se libera. Se registran el proceso detector, la categoría y el mensaje de detección de Apple.
                """,
                recommendation: """
                1. Identifica los archivos o apps que acabas de descargar o ejecutar y elimínalos.
                2. Ejecuta un análisis de ClamAV y la auditoría de seguridad, y comprueba los registros de inicio automático (LaunchAgents) por si hay algo sospechoso.
                3. Una vez seguro, libera la contención desde la ventana de emergencia.
                4. El estado también está disponible mediante la herramienta MCP `get_runtime_threat_status`.
                """
            ),
            LocalizedEntry(
                id: "alert_gatekeeper_block",
                title: "🛡️ Gatekeeper impidió la ejecución de una app sin firmar",
                summary: "Una notificación de que Gatekeeper de macOS impidió el lanzamiento de una app sin firma ni notarización. No hay corte automático.",
                details: """
                • Causa: intentaste abrir una app sin firmar procedente de internet o tu propia compilación de desarrollo.
                • Defensa automática: ninguna (solo notificación). La desconexión vinculada a XProtect solo se activa cuando XProtect detecta realmente malware.
                """,
                recommendation: """
                1. Si la reconoces (por ejemplo tu propia compilación), no hace falta ninguna acción.
                2. Si no, comprueba la autoridad de firma con «Comprobar seguridad de archivo/app…» y elimínala si sospechas de ella.
                """
            ),
            LocalizedEntry(
                id: "alert_clickfix_command",
                title: "🚨 Ejecución de comando sospechoso detectada / ⚠️ Comando sospechoso detectado en el portapapeles",
                summary: "Aparece cuando se ejecutó en Terminal un comando que coincide con la técnica ClickFix (detectado desde el historial del shell) o se copió en el portapapeles.",
                details: """
                • Causa: te llevaron a una falsa verificación o una falsa página de error que decía «ejecuta este comando para solucionarlo». Se señalan las frases de reverse shell y el contenido decodificado en Base64 que se canaliza directamente a un shell u osascript.
                • Defensa automática (ejecutado en Terminal, Pro, desactivada por defecto): contención Air-Gap (el Wi-Fi no se desactiva), restaurada automáticamente en un máximo de 10 minutos.
                • Defensa automática (copiado, activada por defecto): el portapapeles se vacía de inmediato.
                """,
                recommendation: """
                1. Si solo lo copiaste, cierra esa página web y no pegues ni ejecutes nada.
                2. Si lo ejecutaste, comprueba que tu llavero, las contraseñas guardadas en el navegador y tus carteras de criptomonedas estén seguros, y cambia las contraseñas importantes desde otro dispositivo de confianza.
                3. Comprueba los registros de inicio automático (LaunchAgents / Daemons) por si hay algo sospechoso y ejecuta un análisis de ClamAV.
                """
            ),
            LocalizedEntry(
                id: "alert_new_persistence_item",
                title: "🚨 Nuevo registro de inicio automático detectado",
                summary: "Aparece cuando se registró un nuevo LaunchAgent / LaunchDaemon y se consideró sospechoso (lanza directamente un intérprete de scripts, tiene una firma no válida, etc.).",
                details: """
                • Causa: malware como un ladrón de información registrándose para sobrevivir a los reinicios, o un instalador de app añadiendo uno.
                • Defensa automática: solo notificación (el registro en sí no puede impedirse). La notificación muestra la ruta del plist y el motivo.
                """,
                recommendation: """
                1. Comprueba si acabas de instalar tú mismo una app. Si es así, no hace falta ninguna acción.
                2. Si no, elimina el plist que muestra la notificación y el script o app que lanza.
                3. Reinicia el Mac después y ejecuta un análisis de ClamAV.
                """
            ),
            LocalizedEntry(
                id: "alert_docker_risk",
                title: "⚠️ Configuración de contenedor Docker de riesgo detectada",
                summary: "Te avisa de que acaba de iniciarse un contenedor con `--privileged` o con `docker.sock` montado.",
                details: """
                • Causa: los contenedores privilegiados y los montajes del socket de Docker permiten que un contenedor controle el host, creando riesgo de escape de contenedor.
                • Defensa automática: ninguna (solo notificación).
                """,
                recommendation: """
                1. Si es intencionado (por ejemplo, un agente de supervisión), no hace falta ninguna acción.
                2. Si no, comprueba el contenedor con `docker ps` y `docker inspect` y detenlo.
                """
            ),
            LocalizedEntry(
                id: "alert_critical_file_tampering",
                title: "🚨 Manipulación de archivo crítico del sistema detectada",
                summary: "Aparece cuando se detecta un cambio, una eliminación o un archivo nuevo entre archivos críticos como sudoers, la configuración SSH, PAM, hosts, o el authorized_keys de root.",
                details: """
                • Causa: un cambio de configuración por parte de un administrador (`sudo visudo`, edición de ajustes SSH), un cambio hecho por software, o un atacante escalando privilegios o instalando una puerta trasera.
                • Defensa automática: solo notificación. El nuevo estado nunca se acepta automáticamente como legítimo.
                • Relacionado: «La detección de manipulación de archivos críticos no está funcionando» significa que los análisis han fallado repetidamente porque no se pudo contactar con el asistente privilegiado.
                """,
                recommendation: """
                1. Comprueba si tú o un administrador cambiasteis los archivos que muestra la notificación.
                2. Si no, busca entradas `NOPASSWD` en `/etc/sudoers`, claves desconocidas en `authorized_keys` y similares, y elimínalas.
                3. Cambia la contraseña de administrador y ejecuta la auditoría de seguridad.
                """
            ),
            LocalizedEntry(
                id: "alert_log_audit_anomaly",
                title: "🔔 Auditoría de registros: patrones anómalos detectados",
                summary: "Enviada por la auditoría automática de registros cuando encuentra patrones de registro nunca vistos en este Mac ([nuevo]) o registros mucho más frecuentes de lo habitual ([pico z=…]).",
                details: """
                • Causa: normalmente cambios esperados por la conexión de un nuevo dispositivo o actualizaciones de apps o de macOS, pero a veces intentos de inicio de sesión sospechosos o actividad de procesos desconocida.
                • Contenido: el desglose del recuento, hasta 3 líneas de registro reales, el progreso del aprendizaje (por ejemplo aprendizaje de frecuencia en curso: 2/3 observaciones), y una explicación en lenguaje llano.
                • Defensa automática: ninguna (solo notificación).
                """,
                recommendation: """
                1. Si solo hay patrones nuevos y no hay apps ni direcciones IP desconocidas, no hace falta ninguna acción.
                2. Si un pico de frecuencia coincide con algo que no hiciste, abre «📜 Auditoría de registros de seguridad Mac…» para más detalles.
                3. Si no estás seguro, usa «Copiar materiales para consulta con IA» para preguntar a un asistente de IA.
                """
            ),
            LocalizedEntry(
                id: "alert_secret_in_clipboard",
                title: "🔑 Clave confidencial detectada en el portapapeles",
                summary: "Te informa de que hay una clave API o una clave privada (OpenAI, Anthropic, GitHub, AWS, etc.) en el portapapeles.",
                details: """
                • Causa: copiaste una clave API, un token o una clave privada.
                • Defensa automática: solo notificación (el portapapeles no se vacía).
                """,
                recommendation: """
                1. Ten cuidado de no pegarla por error en un sitio web o un chat de IA.
                2. Cuando termines, copia otro texto para sobrescribirla.
                3. Si la compartiste por error, revócala y renuévala de inmediato en la consola del servicio.
                """
            ),
            LocalizedEntry(
                id: "alert_airgap_failed",
                title: "🚨 Error al cortar la red automáticamente",
                summary: "Una advertencia urgente que aparece cuando se intentó un corte de emergencia (ransomware, suplantación ARP, detección de XProtect, ClickFix, etc.) pero no se pudo aplicar el bloqueo completo de pf.",
                details: """
                • Causa: el asistente privilegiado no respondió (no aprobado, detenido, o tiempo de espera agotado). Aparece tras 3 intentos fallidos.
                • Estado actual: el tráfico entrante puede estar bloqueado por el cortafuegos de aplicaciones, pero el tráfico saliente no se ha detenido.
                """,
                recommendation: """
                1. Desactiva el Wi-Fi de inmediato o desconecta el cable de red.
                2. Gestiona la amenaza (cierra procesos, ejecuta análisis).
                3. Después, comprueba el estado del asistente (faq_helper_troubleshooting).
                """
            ),
        ]
    }

    // MARK: - Settings

    private static func settingsEs() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "set_trusted_networks",
                title: "Redes registradas y niveles de protección por red",
                summary: "Registra la red actual como Casa, Trabajo, Compartir internet, etc., y define el nivel de protección de cada red (De confianza / Equilibrado / Bloqueo máximo).",
                details: """
                • Registrar: Registrar red actual → Registrar como «Casa» (De confianza) / Registrar como 'Trabajo' (Equilibrado) / Registrar como 'Compartir internet' (Equilibrado) / Registrar con nombre personalizado…. Las redes se identifican por la dirección MAC de la puerta de enlace.
                • Cambiar de nivel: elige la red bajo «Red actual: …» o «Redes registradas (n)» y elige 🟢 / 🟡 / 🔴.
                • Renombrar o eliminar: Renombrar…, Cancelar registro, o Eliminar.
                """,
                recommendation: "Casa como 🟢 De confianza y Trabajo o Compartir internet como 🟡 Equilibrado funcionan bien. Es más seguro dejar sin registrar un Wi-Fi de oficina compartida, bajo Bloqueo máximo."
            ),
            LocalizedEntry(
                id: "set_away_default_level",
                title: "Protección predeterminada fuera de casa (nivel para redes no registradas)",
                summary: "Elige el nivel de protección que se aplica automáticamente al unirte a una red que no has registrado. Inicialmente 🔴 Bloqueo máximo.",
                details: """
                • Ajuste: «Protección predeterminada fuera: …» en el menú, luego 🟢 De confianza / 🟡 Equilibrado / 🔴 Bloqueo máximo.
                • También afecta a las funciones condicionadas a estar en una red no confiable, como la Protección contra amenazas DNS (solo fuera de casa), la conexión automática de VPN, la fijación ARP/NDP de la puerta de enlace, y la desactivación automática de Bluetooth.
                """,
                recommendation: "Si no usas servicios compartidos ni AirDrop fuera de casa, se recomienda encarecidamente dejarlo en Bloqueo máximo."
            ),
            LocalizedEntry(
                id: "set_manual_override",
                title: "Anulación manual y protección contra el olvido de revertir",
                summary: "Establece temporalmente un nivel de protección a mano durante una duración elegida. Vuelve a la detección automática cuando pasa el tiempo o cambia la red, para que no olvides restaurar la protección.",
                details: """
                • Ajuste: Anulación manual → un nivel (🟢 / 🟡 / 🔴) → una duración.
                • Duraciones: Hasta la desconexión (Recomendado), Durante 1 hora, Durante 4 horas, Hasta que se desactive manualmente.
                • Borrar: Anulación manual → Volver a la detección automática, o «🔄 Borrar anulación manual (Auto)» en la parte superior del menú.
                • Liberar una contención Air-Gap también borra cualquier anulación manual.
                """,
                recommendation: "Al relajar temporalmente la protección para una presentación o trabajo de desarrollo, usa Hasta la desconexión o Durante 1 hora para no quedar nunca sin protección fuera de casa."
            ),
            LocalizedEntry(
                id: "set_pro_default_guards",
                title: "Protecciones activadas automáticamente con Pro, y protecciones opcionales",
                summary: "Al activar por primera vez una licencia Pro, las principales protecciones de defensa autónoma se activan automáticamente. Después, se respeta la elección de activación/desactivación que hagas para cada protección.",
                details: """
                • Activadas automáticamente (una vez, al activar Pro por primera vez): bloqueo automático de puertos de escucha desconocidos, detección de ransomware mediante archivos señuelo, bloqueo automático al detectar suplantación ARP, desconexión automática al detectar malware con XProtect, auditoría automática de registros, y supervisión periódica de manipulación de archivos críticos del sistema. Al activar los cortes de ARP y XProtect, aparece un aviso único que lo explica.
                • Activadas por defecto con Pro: Protección web y correo, y vigilancia de registros de inicio automático (LaunchAgent/Daemon).
                • Desactivadas por defecto (opcionales): bloqueo automático ClickFix, detección de riesgos de Docker, protección física del puerto BadUSB, bloqueo automático de almacenamiento USB, fijación ARP/NDP de la puerta de enlace, túnel VPN, desactivación automática de Bluetooth, y verificación activa de vulnerabilidades. El proveedor de la Protección contra amenazas DNS es tu elección.
                • Activada por defecto incluso en la edición gratuita: protección del portapapeles (claves API y comandos ClickFix).
                • Las protecciones añadidas en versiones posteriores reciben su propio valor predeterminado, una sola vez, para los usuarios Pro existentes. Si la licencia caduca, las protecciones exclusivas de Pro se desactivan.
                """,
                recommendation: "Después de activar Pro, comprueba las marcas ✅ en el menú. Deja desactivadas las protecciones que no encajen con tu uso (por ejemplo Docker si no lo usas), y activa lo que necesites (por ejemplo la VPN si usas a menudo Wi-Fi público)."
            ),
            LocalizedEntry(
                id: "set_usb_whitelist",
                title: "Ajustes de protección USB / BadUSB (lista de permitidos de teclados y permisos de almacenamiento) (Pro)",
                summary: "Gestiona teclados de confianza y dispositivos de almacenamiento USB de trabajo en listas de permitidos, y define el permiso de almacenamiento como Solo lectura o Lectura y escritura.",
                details: """
                • Abrir: «Monitor de puertos y dispositivos» → «Ajustes de protección USB / BadUSB…».
                • Teclados: se añaden al elegir «Confiar y permitir» en la ventana de aprobación; se pueden quitar aquí.
                • Almacenamiento: se añade al elegir «Permitir lectura y escritura» o «Permitir como solo lectura» en el diálogo de conexión; cambia el permiso o quítalo aquí. Si cambias un dispositivo que no está conectado, desconéctalo y vuelve a conectarlo para que el cambio se aplique.
                • El análisis de ClamAV al conectar sigue ejecutándose para los dispositivos permitidos antes de que se conecten en lectura y escritura.
                """,
                recommendation: "En los Mac que manejan datos sensibles, registrar el almacenamiento como Solo lectura reduce considerablemente el riesgo de fugas de datos."
            ),
            LocalizedEntry(
                id: "set_watched_folders",
                title: "Carpetas supervisadas por la Protección web y correo (Pro)",
                summary: "Añade, quita o restablece las carpetas supervisadas por la protección de descargas (vigilancia FSEvents y análisis automáticos).",
                details: """
                • Carpetas predeterminadas: `~/Downloads`, `~/Desktop`, `~/Documents`, y la carpeta de descargas de Mail.
                • Editar: «Protección web y correo (Análisis automático de descargas) (Pro)» → «📁 Carpetas supervisadas» → «⚙️ Gestionar carpetas supervisadas…».
                • Restablecer: «🔄 Restablecer predeterminados».
                • El historial de análisis reciente (hasta 5 mostrados) y «Borrar historial de análisis» están en el mismo menú.
                """,
                recommendation: "Si cambiaste dónde guardan los archivos tu navegador o tus apps de chat, asegúrate de añadir esa carpeta."
            ),
            LocalizedEntry(
                id: "set_dns_policy",
                title: "Proveedor y política de la Protección contra amenazas DNS (Pro)",
                summary: "Elige el proveedor DNS seguro que bloquea dominios maliciosos, y cuándo se aplica (solo fuera de casa / siempre).",
                details: """
                • Ajuste: «Protección contra amenazas DNS (Bloquear malware y C2) (Pro)» → «Proveedor DNS: …» y «⚙️ Política de aplicación».
                • Proveedores: Quad9 (Bloqueo automático de malware y C2) / Cloudflare Security (1.1.1.2) / AdGuard DNS (Bloquear amenazas y publicidad) / CleanBrowsing (Filtro de seguridad).
                • Política: «Solo en Wi-Fi no seguro (Recomendado)» o «Siempre activo en todas las redes (incluidas las de confianza)». Con la opción de solo fuera de casa, se restauran los ajustes DNS originales en redes de confianza.
                • El elemento de estado en el menú abre los ajustes de red para que puedas confirmar qué se está aplicando.
                """,
                recommendation: "Para la mayoría, Quad9 con la política de solo fuera de casa es una buena elección. Evita la política siempre activa si necesitas un DNS interno de empresa."
            ),
            LocalizedEntry(
                id: "set_link_guard_modes",
                title: "Modo, actualización automática, extensión del sistema y lista de permitidos de la Protección de enlaces (Pro)",
                summary: "Configura el modo de la Protección de enlaces, la actualización automática de la lista de amenazas, el estado de aprobación de la extensión del sistema, y cómo permitir sitios bloqueados por error.",
                details: """
                • Modo: «Protección de enlaces (detección de conexiones de phishing) (Pro)» → «Desactivado», «Solo advertir (nunca bloquear)», o «Bloquear automáticamente los sitios de phishing evidentes (recomendado)». El modo Advertencia solo funciona cuando la extensión del sistema está activa.
                • Actualización automática: haz clic en «Actualización automática: activada (solo recepción)» para desactivarla. Sigue funcionando con los datos incluidos y la detección de homógrafos. La versión de la lista y el número de dominios se muestran en el menú.
                • Punto de aplicación: «Aplicación: extensión del sistema (compatible con DoH)», «Aplicación: alternativa mediante hosts», «Activando la extensión del sistema…», o un error de extensión del sistema. Mientras la aprobación está pendiente, aparece «Aprobar la extensión del sistema (abrir Ajustes del Sistema)…».
                • Permitir/bloquear: «Permitir una vez (5 min)» en una notificación de bloqueo permite el sitio durante 5 minutos. Las elecciones de Permitir/Bloquear en el panel de advertencia se recuerdan.
                """,
                recommendation: "Aprueba la extensión del sistema y usa el bloqueo automático con la actualización automática activada para la protección más eficaz."
            ),
            LocalizedEntry(
                id: "set_vpn_backend",
                title: "Ajustes de backend del túnel VPN (WireGuard / Tailscale) (Pro)",
                summary: "Elige el backend del túnel VPN, importa una configuración de WireGuard, selecciona un nodo de salida de Tailscale, y configura el interruptor de corte.",
                details: """
                • Abrir: «Monitor de puertos y dispositivos» → «Túnel VPN (anti-MITM en redes no confiables) (Pro)» → «Backend».
                • WireGuard: «Importar configuración WireGuard (.conf)…» → «Conexión automática en redes no confiables». También «Conectar ahora», «Desconectar» y «Eliminar configuración». El estado muestra por ejemplo «🟢 Conectado (último handshake hace N s)», y el interruptor de corte siempre está activo. Si falta `wireguard-tools`, aparecen instrucciones de instalación.
                • Tailscale: elige un nodo bajo «Exit-Node» («(ninguno — protección desactivada)» para desactivarlo). También «Actualizar candidatos» y «Actualizar estado». «Kill-switch: activado (previene fugas)» es opcional y está desactivado por defecto.
                • Ejemplos de líneas de estado: «⚪️ En espera (se conecta automáticamente en redes no confiables)», «🟡 El nodo de salida seleccionado está sin conexión».
                """,
                recommendation: "Si ya usas Tailscale, elige Tailscale; si no, la configuración WireGuard de tu proveedor VPN es la opción más sencilla."
            ),
            LocalizedEntry(
                id: "set_language",
                title: "Idioma de visualización (respuestas de la app y de MCP)",
                summary: "RoamSwitch puede mostrarse en 10 idiomas (日本語, English, 简体中文, 繁體中文, 한국어, Deutsch, Français, Español, Italiano, Português). Las respuestas del servidor MCP y esta base de conocimiento usan el mismo idioma.",
                details: """
                • Ajuste: elige en el menú bajo «Idioma / Language». «Seguir ajustes del sistema» usa el idioma preferido de macOS.
                • MCP: el servidor MCP lee el idioma elegido en la app. Si sigue al sistema y el idioma del sistema no está admitido, responde en inglés.
                • La herramienta `get_app_help` acepta un argumento `language` para elegir el idioma de respuesta en cada llamada. Las búsquedas encuentran coincidencias de palabras clave en cualquier idioma.
                """,
                recommendation: "Para hablar con tu asistente de IA en un idioma distinto al de la app, usa el argumento `language` de `get_app_help`."
            ),
        ]
    }

    // MARK: - Troubleshooting: setup

    private static func troubleshootingEsSetup() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "faq_free_vs_pro",
                title: "Diferencia entre la edición gratuita y la versión Pro de por vida",
                summary: "La edición gratuita incluye, sin límite de tiempo, el cambio automático de protección según la red, la auditoría de seguridad de 18 puntos, y un conjunto de herramientas de comprobación manual. Pro desbloquea la contención automática, las defensas en tiempo real y los avisos de patrulla.",
                details: """
                [Gratis]
                • Cambio automático del filtro de paquetes PF de 3 niveles por red, con servicios compartidos y AirDrop detenidos y restaurados automáticamente
                • Auditoría de seguridad del Mac (18 puntos), estado de XProtect, y comprobación de seguridad de archivo/app
                • Listas de puertos expuestos y dispositivos USB
                • Auditoría de seguridad de enlaces, auditoría manual de fugas de secretos/claves API, protección del portapapeles
                • Comprobación de CVE de paquetes, verificación activa de vulnerabilidades, Auditoría de registros de seguridad Mac, historial de notificaciones
                • Análisis manuales de ClamAV y gestión de cuarentena
                • Integración del servidor MCP
                [Pro de por vida (compra única 2980 ¥ / 19,99 $, hasta 2 Mac)]
                • Detección de ransomware mediante archivos señuelo con Air-Gap, corte automático vinculado a XProtect, defensa ClickFix
                • Bloqueo automático de puertos de escucha desconocidos, aislamiento de servidores de desarrollo
                • Bloqueo automático de suplantación ARP, fijación ARP/NDP de la puerta de enlace, túnel VPN (WireGuard / Tailscale), avisos de gemelo malvado
                • Protección de teclado BadUSB, bloqueo automático de almacenamiento USB
                • Protección web y correo (análisis automático, cuarentena, avisos de Pickle), Protección contra amenazas DNS, Protección de enlaces
                • Vigilancia de registros de inicio automático, detección de riesgos de Docker, supervisión de manipulación de archivos críticos, auditoría automática de registros
                • Desactivación automática de Bluetooth, notificaciones de amenazas en tiempo real, avisos de patrulla, actualizaciones de definiciones y análisis programados, exportación CSV de registros
                """,
                recommendation: "Elige Pro si necesitas contención automática, defensa en tiempo real y supervisión en segundo plano."
            ),
            LocalizedEntry(
                id: "faq_homebrew_clamav",
                title: "Configurar ClamAV (análisis antivirus) y Homebrew",
                summary: "El análisis antivirus usa ClamAV, un software de código abierto instalable con Homebrew. Sin él, la integración con XProtect y todas las funciones propias de RoamSwitch siguen funcionando.",
                details: """
                • Homebrew: el gestor de paquetes para macOS (https://brew.sh/).
                • Pasos:
                  1. Ejecuta en Terminal el comando oficial de instalación de Homebrew (indicado en https://brew.sh/).
                  2. Ejecuta `brew install clamav`. «📥 Instalar ClamAV mediante Homebrew…» en el menú también abre instrucciones.
                  3. Elige «🛡️ ClamAV (Antivirus gratuito)» → «🔄 Actualizar base de virus ahora».
                • Activados por ClamAV: análisis rápido (Descargas/Escritorio), análisis de carpeta, análisis en la Protección web y correo y para almacenamiento USB, y el análisis programado de la patrulla.
                • Sin ClamAV: el filtrado de paquetes, la supervisión de puertos, el análisis de enlaces, la comprobación de firma estática y más siguen funcionando.
                """,
                recommendation: "Instala Homebrew y ClamAV si quieres que las descargas y el almacenamiento USB se analicen automáticamente."
            ),
            LocalizedEntry(
                id: "faq_blueutil_setup",
                title: "Desactivación automática de Bluetooth (Pro) y configuración de blueutil",
                summary: "Desactivar automáticamente el Bluetooth fuera de casa requiere la herramienta de código abierto `blueutil`.",
                details: """
                • Contexto: macOS no ofrece una API pública para que las apps alternen la alimentación del Bluetooth, así que se usa la herramienta de línea de comandos `blueutil`.
                • Pasos:
                  1. Ejecuta `brew install blueutil` en Terminal (o usa «📥 Instalar blueutil mediante Homebrew…» en el menú).
                  2. Activa «Monitor de puertos y dispositivos» → «Desactivación automática de Bluetooth en redes no confiables (Pro)».
                • Si no está instalado: nada más se ve afectado, y el menú muestra «🔵 Desactivación automática de Bluetooth (no instalado)».
                """,
                recommendation: "Para evitar el rastreo por radio y las vulnerabilidades de Bluetooth en Wi-Fi público, ejecuta `brew install blueutil` y actívalo."
            ),
            LocalizedEntry(
                id: "faq_helper_troubleshooting",
                title: "Qué hacer cuando aparece «⚠️ Asistente no conectado»",
                summary: "Pasos de recuperación cuando RoamSwitch no puede comunicarse con la herramienta asistente con privilegios (RoamSwitchHelper).",
                details: """
                1. Elige «⚠️ Aprobar el asistente…» en el menú y sigue los pasos que se muestran.
                2. Abre Ajustes del Sistema → General → Elementos de inicio y extensiones y asegúrate de que RoamSwitchHelper esté activado bajo Permitir en segundo plano.
                3. Asegúrate de que RoamSwitch está en la carpeta Aplicaciones (faq_install_location).
                4. Pulsa «Reintentar el registro del asistente» en la ventana de bienvenida.
                5. Si sigue fallando, ejecuta `sudo killall RoamSwitchHelper` en Terminal para reiniciar el asistente (launchd lo relanza automáticamente), y luego vuelve a abrir RoamSwitch.
                """,
                recommendation: "Si el asistente deja de responder justo después de una actualización de macOS, comprueba primero el interruptor de Elementos de inicio, y luego prueba `sudo killall RoamSwitchHelper`."
            ),
            LocalizedEntry(
                id: "faq_install_location",
                title: "Ubicación de la app (iniciada fuera de la carpeta Aplicaciones)",
                summary: "macOS no registra el asistente con privilegios para una app que esté fuera de la carpeta Aplicaciones, así que RoamSwitch debe colocarse en `/Applications` o `~/Applications` y ejecutarse desde ahí.",
                details: """
                • Ubicaciones que no permiten registro: Descargas o Escritorio, ejecución desde una imagen de disco (.dmg) todavía montada, o cuando Gatekeeper App Translocation ha movido la app a una ubicación temporal de solo lectura.
                • Orientación: la bienvenida comprueba la ubicación al iniciar y ofrece «Mover a Aplicaciones y reiniciar» u «Abrir Aplicaciones en el Finder».
                • Tras mover la app: pulsa «Comprobar de nuevo» o reinicia, y luego aprueba el asistente.
                """,
                recommendation: "Arrastra RoamSwitch desde la imagen de disco a la carpeta Aplicaciones y ejecútalo desde ahí."
            ),
            LocalizedEntry(
                id: "faq_system_extension_approval",
                title: "Aprobar la extensión del sistema de la Protección de enlaces",
                summary: "Para que la Protección de enlaces funcione al máximo (compatible con DoH, modo Advertencia), debe aprobarse la extensión del sistema de filtrado de contenido. Hasta entonces, usa la alternativa mediante /etc/hosts.",
                details: """
                • Pasos: «Protección de enlaces (detección de conexiones de phishing) (Pro)» → «Aprobar la extensión del sistema (abrir Ajustes del Sistema)…» → Ajustes del Sistema → General → Elementos de inicio y extensiones, y luego permite la extensión de red de RoamSwitch.
                • Tras la aprobación: el menú muestra «Aplicación: extensión del sistema (compatible con DoH)».
                • Si aparece un error de extensión del sistema: asegúrate de que la app está en la carpeta Aplicaciones, y luego vuelve a seleccionar un modo de Protección de enlaces para reintentarlo.
                • Este método no requiere revisión de la App Store ni solicitud de permiso adicional (firmada con Developer ID y notarizada).
                """,
                recommendation: "Aprueba la extensión del sistema para que la protección se mantenga incluso cuando tu navegador use DNS sobre HTTPS."
            ),
            LocalizedEntry(
                id: "faq_mcp_setup",
                title: "Configurar el servidor MCP (Claude Desktop, Claude Code y otros)",
                summary: "Cómo registrar el servidor MCP incluido en RoamSwitch con un cliente de IA compatible con MCP.",
                details: """
                • Ruta del binario: `/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`
                • Claude Desktop: añade la ruta del binario como `command` bajo `mcpServers` en `~/Library/Application Support/Claude/claude_desktop_config.json`.
                • Claude Code: `claude mcp add roamswitch /Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`
                • Otros clientes (Codex CLI y más): https://lafine.net/mcp-setup.html
                • Idioma de respuesta: sigue el ajuste «Idioma / Language» de la app. `get_app_help` acepta un argumento `language` por llamada.
                • La comunicación es solo mediante stdio local, sin enviar nada al exterior (solo `run_active_vuln_scan` envía sondas no destructivas hacia 127.0.0.1).
                """,
                recommendation: "Una vez registrado, pídele a tu IA algo como «Comprueba el estado de seguridad de mi Mac con RoamSwitch» y te explicará los resultados de la auditoría."
            ),
        ]
    }

    // MARK: - Troubleshooting: operation

    private static func troubleshootingEsOperation() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "faq_network_cut_off",
                title: "Internet dejó de funcionar de repente (contención Air-Gap / nivel de protección)",
                summary: "El Air-Gap de emergencia o el Bloqueo máximo de RoamSwitch podrían estar deteniendo el tráfico. Cómo encontrar la causa y liberarlo.",
                details: """
                • Comprobar: busca una ventana de emergencia, y revisa el historial de notificaciones en busca de alertas como DEFENSA AUTOMÁTICA CRÍTICA, XProtect, suplantación ARP, o ejecución de comandos sospechosos. El Wi-Fi también podría haberse desactivado.
                • Liberar: usa el botón de liberar en la ventana de emergencia o la notificación. La red y el Wi-Fi vuelven.
                • Restauración automática: incluso sin liberarlo, la red de seguridad del asistente restaura la red en 10 minutos. No hace falta ningún paso manual tras cerrar la app, un fallo, o un reinicio.
                • Justo después de arrancar: el tráfico puede estar restringido por la puerta de arranque hasta 90 segundos.
                • Otras causas: el Bloqueo máximo bloquea el tráfico entrante pero no impide el uso saliente normal, como navegar por la web. Comprueba también el interruptor de corte de la VPN (mientras el túnel está caído), el resolutor de la Protección contra amenazas DNS, y los bloqueos de la Protección de enlaces.
                """,
                recommendation: "Cuando se active la contención, lee la notificación que la desencadenó y libérala una vez confirmes que es seguro. Si una protección se activa a menudo por error, puedes desactivarla individualmente desde el menú."
            ),
            LocalizedEntry(
                id: "faq_quarantine_false_positive",
                title: "Restaurar una descarga puesta en cuarentena por error",
                summary: "Cómo restaurar tu propio script o binario de desarrollo puesto en cuarentena como falso positivo, y excluirlo de los análisis.",
                details: """
                1. Abre Protección contra malware → ClamAV → «📦 Gestionar archivos en cuarentena…».
                2. Selecciona el archivo entre los archivos en cuarentena (se muestran la ruta original, el nombre de la amenaza y el momento de la cuarentena).
                3. Para un falso positivo seguro, pulsa «Excluir y restaurar»: vuelve a su ubicación original y esa ruta se excluye de futuros análisis. Para restaurar solo una vez, pulsa «Restaurar».
                4. Para deshacer una exclusión, pulsa «Quitar exclusión» en la lista de rutas excluidas, en la misma ventana.
                5. Para dejar de supervisar una carpeta entera, ajusta «⚙️ Gestionar carpetas supervisadas…» bajo Protección web y correo.
                """,
                recommendation: "Si no puedes estar seguro de que un archivo es seguro, no lo restaures; elige Eliminar permanentemente."
            ),
            LocalizedEntry(
                id: "faq_eicar_test",
                title: "Coloqué un archivo de prueba EICAR pero no recibí ninguna notificación",
                summary: "Es intencionado. La firma de prueba EICAR es una prueba inofensiva, así que no aparece ningún aviso y nada se pone en cuarentena. La detección se registra en el historial de notificaciones.",
                details: """
                • Cómo confirmarlo: comprueba en Auditoría de seguridad del Mac → «🔔 Historial de notificaciones…» si aparece «🧪 Firma de prueba EICAR detectada (inofensiva)».
                • El archivo: se queda donde está.
                • Para probar la ruta de alerta real: usa las simulaciones en la parte inferior de Protección contra malware (defensa contra ransomware, Air-Gap de detección de malware, detección de riesgos de Docker).
                """,
                recommendation: "Elimina el archivo EICAR cuando termines de probar."
            ),
            LocalizedEntry(
                id: "faq_dev_server_blocked",
                title: "No se puede acceder a mi servidor de desarrollo o app de recepción LAN desde otros dispositivos",
                summary: "El bloqueo automático de puertos de escucha desconocidos podría estar bloqueando un programa que acaba de empezar a exponer un puerto. Sigue siendo accesible desde el propio Mac.",
                details: """
                • Comprobar: busca en el historial de notificaciones «Puerto de escucha desconocido bloqueado automáticamente».
                • Permitir: usa el botón «Permitir» de la notificación, o Puertos expuestos → el puerto → la pantalla de auditoría de puertos. Permitirlo se aplica de forma permanente, por ejecutable.
                • Frente al aislamiento manual: un puerto que aislaste tú mismo con «Aislar puerto» se restaura con «Desaislar» en la pantalla de auditoría de puertos.
                • Nivel de protección: en una red con Bloqueo máximo, el cortafuegos bloquea por completo las conexiones entrantes. Para permitir el acceso desde la LAN, registra esa red y ajústala a Equilibrado o De confianza.
                """,
                recommendation: "Permite una vez las apps de recepción LAN que uses habitualmente, como LocalSend o Syncthing, y no volverán a bloquearse."
            ),
            LocalizedEntry(
                id: "faq_link_guard_false_block",
                title: "La Protección de enlaces bloquea un sitio legítimo / mantiene una conexión en espera",
                summary: "Qué hacer cuando la Protección de enlaces bloquea un sitio por error o lo mantiene en espera en modo Advertencia.",
                details: """
                • Permitir temporalmente: «Permitir una vez (5 min)» en la notificación de bloqueo.
                • Permitir permanentemente: elegir «Permitir» en el panel de advertencia se recuerda.
                • Una conexión en espera se bloqueó sola: el modo Advertencia bloquea si no hay respuesta en unos 8 segundos (falla cerrado). Ese resultado no se guarda en caché, así que recargar la página vuelve a preguntar.
                • No se ve la notificación: con el estilo de notificación de aviso, los botones pueden quedar ocultos, así que también aparece un panel en primer plano. Durante el modo No molestar, revisa el historial de notificaciones.
                • Desactivar temporalmente: cambia el modo a «Solo advertir (nunca bloquear)» o «Desactivado».
                """,
                recommendation: "Si una herramienta de trabajo se bloquea repetidamente, comprueba que el dominio no tenga erratas ni se parezca sospechosamente a otro antes de permitirlo."
            ),
            LocalizedEntry(
                id: "faq_keyboard_blocked",
                title: "Mi teclado externo no escribe (protección BadUSB)",
                summary: "La protección física del puerto contra BadUSB está bloqueando la entrada de un teclado que no está en la lista de permitidos hasta que lo apruebes.",
                details: """
                • Aprobar: haz clic en «Confiar y permitir» en la ventana «⚠️ Dispositivo USB / teclado desconocido detectado» (usa el teclado integrado o el trackpad).
                • No encuentras la ventana: desconecta y vuelve a conectar el dispositivo para que vuelva a aparecer.
                • Docks y conmutadores KVM: los dispositivos con función de teclado integrada también están cubiertos. Permítelos si son tuyos.
                • Permiso de Accesibilidad: el bloqueo alternativo usado cuando el dispositivo no puede tomarse de forma exclusiva depende del permiso de Accesibilidad.
                • Revocar: quítalo en «Ajustes de protección USB / BadUSB…».
                """,
                recommendation: "No permitas un dispositivo que haya activado el aviso de escritura guionizada; desconéctalo."
            ),
            LocalizedEntry(
                id: "faq_vpn_troubleshooting",
                title: "El túnel VPN no se conecta / no pasa tráfico",
                summary: "Qué comprobar cuando el backend de WireGuard o Tailscale no funciona.",
                details: """
                • WireGuard: confirma que `brew install wireguard-tools` está instalado y que se ha importado una `.conf`. Si el estado muestra «🟡 Sin respuesta (último handshake …)», comprueba el servidor VPN y las claves y el punto final de la configuración. El interruptor de corte está activado, así que no pasa nada hasta que se establece el túnel.
                • Tailscale: confirma que la CLI está instalada y con sesión iniciada (si no, el menú muestra «Inicia sesión en Tailscale primero») y que hay un nodo de salida seleccionado. Si el nodo de salida seleccionado está sin conexión, elige otro.
                • Tailscale desde la App Store: el nodo de salida no puede establecerse desde fuera de la app, elígelo en la app de Tailscale.
                • Interruptor de corte de Tailscale: en algunas redes puede interferir con la conectividad propia de Tailscale; desactívalo si no puedes conectarte.
                • Que se desconecte automáticamente en redes de confianza es el comportamiento esperado.
                """,
                recommendation: "Empieza por la línea de estado en el menú: el handshake para WireGuard, el estado del nodo de salida para Tailscale."
            ),
            LocalizedEntry(
                id: "faq_log_audit_repeated_alerts",
                title: "Las notificaciones de la auditoría de registros no dejan de llegar",
                summary: "La auditoría automática de registros aprende el comportamiento normal de los registros de este Mac a medida que se ejecuta. Las alertas aumentan justo después de la configuración o una actualización importante y disminuyen de forma natural a medida que avanza el aprendizaje.",
                details: """
                • Patrones nuevos: una vez notificado, un patrón se vuelve conocido y no se vuelve a notificar por el mismo contenido.
                • Picos de frecuencia: el aprendizaje de cada patrón se completa tras 3 observaciones; después, un volumen normal no genera alerta. Mientras la notificación siga mostrando algo como «aprendizaje de frecuencia en curso: 2/3 observaciones», el aprendizaje continúa.
                • Causas comunes: actualizaciones de macOS o de apps, conexión de nuevos dispositivos, carga elevada temporal.
                • Para detenerlo: desactiva en el menú «Auditoría automática de registros (aprende patrones nuevos y anomalías de frecuencia según un calendario) (Pro)» (la auditoría manual de registros sigue disponible).
                """,
                recommendation: "Mientras las alertas no incluyan nombres de apps o direcciones IP desconocidos, o fallos de sudo, está bien esperar un poco."
            ),
            LocalizedEntry(
                id: "faq_zero_telemetry",
                title: "Diseño de privacidad Zero Telemetry",
                summary: "RoamSwitch y su servidor MCP nunca envían resultados de auditoría, URL, información de puertos, registros o contenido de archivos a servidores externos. El único tráfico de red son las excepciones explícitas siguientes.",
                details: """
                • Totalmente local: la auditoría de seguridad, la supervisión de puertos, el análisis de enlaces, la auditoría de secretos, la auditoría de registros, el análisis antivirus y la comunicación MCP permanecen todos en el dispositivo.
                • Excepciones:
                  - La activación y desactivación de licencia (solo cuando actúas) y la apertura de la página de compra
                  - Las comprobaciones de actualización de la app (Sparkle)
                  - Las actualizaciones de definiciones de ClamAV (`freshclam`)
                  - Las descargas diarias de la lista de amenazas de la Protección de enlaces, los mapas de CVE de paquetes, y los mapas de CVE de vulnerabilidades (solo en recepción, verificados por firma, sin enviar identificadores; la actualización automática de la Protección de enlaces puede desactivarse)
                  - El tráfico normal hacia los proveedores de VPN y DNS seguro que configures
                  - Las sondas no destructivas de la verificación activa de vulnerabilidades hacia 127.0.0.1 (este propio Mac)
                • No existe en ningún lugar del código telemetría ni recopilación de uso. Incluso el recordatorio de aprobación del asistente funciona solo a partir de un contador en el dispositivo.
                """,
                recommendation: "Es seguro de usar en entornos empresariales altamente confidenciales y configuraciones de desarrollo personales sin preocuparte por fugas de datos."
            ),
        ]
    }
}
