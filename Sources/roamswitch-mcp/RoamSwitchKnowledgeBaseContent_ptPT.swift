// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.9.33 (build 90).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

// European Portuguese (pt-PT) content for `RoamSwitchKnowledgeBase`.
// Translated from the English source (`RoamSwitchKnowledgeBaseContent_en.swift`).
// Every entry id here must also exist in every other
// `RoamSwitchKnowledgeBaseContent_<lang>.swift` file.
extension RoamSwitchKnowledgeBase {
    static func labelsPtPT() -> MarkdownLabels {
        return MarkdownLabels(
            featuresTitle: "Especificação completa de funcionalidades e arquitetura do RoamSwitch",
            featuresIntro: "Como funciona cada funcionalidade de segurança do RoamSwitch, com as suas predefinições e limitações.",
            alertsTitle: "Catálogo de alertas e notificações do RoamSwitch",
            alertsIntro: "Todos os avisos de notificação, alertas e janelas de emergência mostrados pelo RoamSwitch, com a respetiva causa, a defesa automática acionada e as ações recomendadas passo a passo.",
            settingsTitle: "Guia de definições e funcionamento do RoamSwitch",
            settingsIntro: "Instruções passo a passo para cada definição, interruptor, lista de permissões e política do RoamSwitch.",
            troubleshootingTitle: "Resolução de problemas e perguntas frequentes do RoamSwitch",
            troubleshootingIntro: "Respostas oficiais sobre perguntas frequentes, permissões e aprovações, configuração do Homebrew / ClamAV / blueutil, falsos positivos e o design de privacidade.",
            summary: "Resumo",
            overview: "Descrição geral",
            detailsHeading: "Detalhes e causas",
            adviceHeading: "O que fazer",
            recommendation: "Recomendação",
            bestPractice: "Boa prática",
            advice: "Conselho"
        )
    }

    static func contentPtPT() -> [LocalizedEntry] {
        var list: [LocalizedEntry] = []
        list.append(contentsOf: featuresPtPTNetwork())
        list.append(contentsOf: featuresPtPTMalware())
        list.append(contentsOf: featuresPtPTAudit())
        list.append(contentsOf: alertsPtPTNetwork())
        list.append(contentsOf: alertsPtPTMalware())
        list.append(contentsOf: settingsPtPT())
        list.append(contentsOf: troubleshootingPtPTSetup())
        list.append(contentsOf: troubleshootingPtPTOperation())
        return list
    }

    // MARK: - Features: network & devices

    private static func featuresPtPTNetwork() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_network_autoswitch",
                title: "Comutação automática da segurança de rede e filtro de pacotes PF (3 níveis)",
                summary: "Compara o endereço MAC da gateway da rede atual com as suas redes registadas e aplica automaticamente o nível de proteção dessa rede. As redes não registadas recebem o nível de Proteção predefinida em viagem (inicialmente Bloqueio máximo). Disponível na edição gratuita.",
                details: """
                • 🟢 Confiável (Aberta - Desbloqueada): por exemplo em casa. Firewall desligada; serviços de partilha (SSH / SMB / Partilha de ecrã) e AirDrop permitidos.
                • 🟡 Equilibrado (Firewall e furtividade): por exemplo no trabalho ou em partilha de ligação. O filtro de pacotes PF e o modo furtivo bloqueiam sondagens externas, mantendo os serviços de partilha disponíveis.
                • 🔴 Bloqueio máximo (Partilha e AirDrop desligados): cafés, Wi-Fi público, redes não registadas. Todo o tráfego de entrada é bloqueado, os daemons de partilha são parados e o AirDrop é desativado.
                • Como decide: quando a rede muda, o endereço MAC da gateway é lido e comparado com as redes registadas. Eventos de caminho que não alteram a gateway (renovação DHCP, roaming Wi-Fi) não desencadeiam uma reavaliação completa.
                • Internamente: o auxiliar privilegiado `RoamSwitchHelper` (via XPC) gere uma âncora `pfctl` dedicada, pelo que os pacotes são descartados ao nível do kernel.
                • Substituição manual: em Substituição manual pode escolher, por nível, Até desligar da rede (Recomendado), Durante 1 hora, Durante 4 horas, ou Até ser desativado manualmente (ver set_manual_override).
                """,
                recommendation: "Registe a sua casa e outros escritórios seguros através de «Registar rede atual», e deixe que o Bloqueio máximo se aplique automaticamente em qualquer outro lugar."
            ),
            LocalizedEntry(
                id: "feat_network_history_guard",
                title: "Aprendizagem do histórico de rede e deteção de gémeo maligno (Wi-Fi semelhante) (Pro)",
                summary: "Aprende, apenas neste Mac, que endereços MAC de gateway cada SSID Wi-Fi já usou, e avisa de um possível gémeo maligno (ponto de acesso falso) quando entra numa SSID desconhecida cujo nome se assemelha de forma suspeita a uma rede já usada.",
                details: """
                • O que é aprendido: para cada SSID, os endereços MAC de gateway observados (até 8 por SSID, para Wi-Fi em malha), guardados em `~/Library/Application Support/RoamSwitch/network_history.json`. Até 200 SSID, removendo primeiro os mais antigos. Nada é enviado para fora do dispositivo.
                • Teste de semelhança: distância de edição (Levenshtein) sem distinção entre maiúsculas e minúsculas. Nomes com menos de 6 carateres estão isentos, e a distância permitida aumenta lentamente com o comprimento (1 a 2 carateres), pelo que SSID genéricas comuns como «ASUS» ou «TP-Link_5G» que coincidam por acaso nunca acionam isto.
                • Controlo de falsos positivos: o mesmo hardware de gateway a difundir uma segunda SSID (rede de convidados, router renomeado) não é assinalado. Uma SSID conhecida observada com um novo MAC de gateway (router substituído) é registada mas nunca alerta sozinha.
                • Enquanto é detetada falsificação de ARP, a observação é ignorada para que o MAC de um atacante nunca seja aprendido como legítimo.
                • O aviso é um alerta em tempo real, enviado na versão Pro. O histórico aprendido está disponível através da ferramenta MCP `get_network_history`.
                """,
                recommendation: "Se receber este aviso, não introduza credenciais nesse Wi-Fi e confirme o verdadeiro nome e localização da rede. Um túnel VPN (feat_vpn_tunnel) é a contramedida mais fiável."
            ),
            LocalizedEntry(
                id: "feat_arp_spoof_guard",
                title: "Deteção de falsificação ARP (personificação na rede) e bloqueio automático (Pro)",
                summary: "Deteta a falsificação ARP, em que um atacante na mesma rede se faz passar pelo router para escutar ou adulterar o tráfego (ataque intermediário). Em redes com Bloqueio máximo, corta a rede de imediato; noutros níveis, apenas notifica e deixa a decisão a seu cargo.",
                details: """
                • Deteção: o IP da gateway predefinida mantém-se igual enquanto o seu endereço MAC muda subitamente. Além dos eventos de mudança de rede, uma sondagem dedicada a cada 15 segundos também deteta ataques que começam a meio de uma sessão.
                • Resposta: numa rede com Bloqueio máximo, contenção Air-Gap imediata (feat_airgap_containment). Em redes Confiáveis ou Equilibradas, apenas notificação, podendo acionar a contenção a partir de «Monitor de portas e dispositivos» com «Falsificação ARP detetada — cortar toda a rede agora». Isto evita ativações falsas por reinícios do router ou roaming em malha, e impede que um único pacote ARP falsificado seja usado como arma para provocar um corte autoinfligido.
                • Predefinição: a opção de menu «Bloqueio automático ao detetar ARP spoofing (personificação na rede) (Pro)» é ativada automaticamente na primeira ativação de uma licença Pro (set_pro_default_guards).
                • Papel: esta é a resposta posterior ao facto. A prevenção é feita pela fixação ARP/NDP da gateway (feat_gateway_arp_lock) e pelo túnel VPN (feat_vpn_tunnel).
                • Os incidentes são registados na linha temporal de incidentes (feat_containment_incident_timeline) como MITRE ATT&CK T1557.
                """,
                recommendation: "Mantenha-a ativa. Para uma proteção MITM mais forte, adicione o túnel VPN; para prevenção sem infraestrutura adicional, adicione a fixação ARP/NDP da gateway."
            ),
            LocalizedEntry(
                id: "feat_gateway_arp_lock",
                title: "Fixação ARP/NDP da gateway (Preventivo) (Pro)",
                summary: "Ao entrar numa rede não fiável, fixa os endereços MAC da gateway, do router IPv6 e de qualquer servidor DNS no mesmo enlace como entradas estáticas na cache de vizinhos, evitando ataques intermediários por falsificação ARP/NDP antes de começarem. Desativado por predefinição.",
                details: """
                • Ativação: «Monitor de portas e dispositivos» → «Fixar ARP/NDP do gateway em redes não fiáveis (preventivo) (Pro)».
                • Funcionamento: ao ligar, os endereços MAC atuais são lidos e o auxiliar fixa-os como entradas permanentes com `arp -s` / `ndp -s`. O kernel passa depois a ignorar respostas ARP falsificadas e anúncios de vizinhos para esses IP.
                • Âmbito: apenas estes três tipos de entradas. Nada é fixado em redes Confiáveis (abertas), pelo que reiniciar o router de casa nunca quebra a ligação. As fixações são limpas e recriadas em cada mudança de rede.
                • Limitação (confiança na primeira utilização): confia-se no primeiro MAC observado, pelo que um atacante já presente antes da sua ligação poderia conseguir que o seu próprio MAC fosse fixado. Se não puder aceitar esse pressuposto, use o túnel VPN.
                • Refletido no item «Fixação ARP da gateway (defesa preventiva contra MITM)» da auditoria de segurança do Mac.
                """,
                recommendation: "Uma boa defesa MITM leve quando uma VPN não é prática. Pode ser combinada com o túnel VPN (a VPN é a defesa principal, isto um complemento)."
            ),
            LocalizedEntry(
                id: "feat_vpn_tunnel",
                title: "Túnel VPN (WireGuard / Tailscale, com kill switch) (Pro)",
                summary: "Estabelece automaticamente um túnel cifrado em redes não fiáveis para que os ataques intermediários vejam apenas texto cifrado. Escolha WireGuard (ficheiro de configuração) ou Tailscale (nó de saída) como backend. Não depende da integridade da camada 2 (ARP/NDP), tornando-o a defesa anti-MITM principal. Não requer permissão Network Extension.",
                details: """
                • Backend: «Monitor de portas e dispositivos» → «Túnel VPN (anti-MITM em redes não fiáveis) (Pro)» → «Backend», depois escolha WireGuard ou Tailscale. Apenas o backend selecionado funciona.
                • WireGuard: requer `wireguard-tools` do Homebrew (`brew install wireguard-tools`). Importe uma configuração com «Importar configuração WireGuard (.conf)…». Fornece você a configuração (Mullvad, IVPN, Proton VPN, um servidor próprio, a sua entidade patronal); o RoamSwitch não fornece servidores VPN.
                • Kill switch do WireGuard: o pf aplica «block drop all» com exceções apenas para lo, a interface do túnel, o handshake UDP com o ponto final, DHCP e ICMP. Nada é exposto em texto simples enquanto o túnel está inativo.
                • Tailscale: para quem já usa Tailscale. O RoamSwitch não o instala nem inicia sessão; lê `tailscale status` e executa `tailscale set --exit-node=<nó>`. É necessário um nó de saída (todo o tráfego passa por ele). Um nó de saída offline é mostrado na linha de estado.
                • Recomenda-se a CLI do Tailscale (autónoma): `brew install tailscale` → `sudo tailscaled install-system-daemon` → `sudo tailscale up`. A versão da App Store (interface gráfica) não pode ser controlada com `tailscale set` a partir de fora da app; nesse caso, escolha o nó de saída na app Tailscale, e o RoamSwitch trata apenas da apresentação do estado e do kill switch.
                • Kill switch do Tailscale (desligado por predefinição, opcional): o pf deixa passar apenas lo, a utun do Tailscale, o CGNAT 100.64.0.0/10, DNS, STUN 3478, 41641, DERP tcp 443, DHCP e ICMP. Menos rigoroso que o do WireGuard («difícil de deixar fugas» em vez de estanque), e em algumas redes pode interferir com a conetividade do próprio Tailscale, por isso é opcional.
                • Automático: o túnel/nó de saída ativa-se em redes não fiáveis e desativa-se em redes fiáveis. Se a licença expirar, o túnel e o kill switch são libertados automaticamente.
                """,
                recommendation: "A proteção mais eficaz se usar frequentemente Wi-Fi público. Utilizadores de Tailscale: instale a CLI e escolha o backend Tailscale mais um nó de saída. Caso contrário, `brew install wireguard-tools` com o ficheiro `.conf` do seu fornecedor VPN é o caminho mais simples."
            ),
            LocalizedEntry(
                id: "feat_airgap_containment",
                title: "Contenção de emergência Air-Gap (corte total da rede, Wi-Fi desligado, rede de segurança de restauro automático)",
                summary: "A contenção de emergência partilhada usada quando é detetada uma ameaça grave (ransomware, deteção de malware pelo XProtect, falsificação de ARP, ClickFix). Bloqueia todo o tráfego de entrada e de saída. Mesmo após uma falha ou reinício, a rede regressa automaticamente no máximo em 10 minutos.",
                details: """
                • Como: o auxiliar privilegiado carrega o pf com «block drop all» (exceto o loopback) e volta a lê-lo para confirmar. O tráfego de saída também é cortado, o que impede a exfiltração de chaves ou dados para um servidor C2. Se a aplicação falhar, são feitas até 3 novas tentativas (8 segundos de tempo limite cada); se continuar a falhar, mostra «Falha ao cortar a rede automaticamente» e pede para desligar manualmente. Nunca afirma um isolamento que não seja real.
                • Wi-Fi desligado: o pf apenas descarta pacotes enquanto o adaptador permanece associado, pelo que a contenção por falsificação ARP, ransomware e XProtect também desliga o próprio Wi-Fi através do `networksetup` (ligado por predefinição; definição interna `RoamSwitch.AirGapAutoWiFiKillEnabled`). A contenção por ClickFix não desliga o Wi-Fi.
                • Libertação: libertar a partir da janela de emergência ou da notificação remove o bloqueio do pf e volta a ligar o Wi-Fi.
                • Rede de segurança: se a app falhar ou ninguém libertar a contenção, um temporizador do lado do auxiliar força a libertação do Air-Gap ao fim de 10 minutos e restaura o Wi-Fi. Reiniciar a app ou o Mac também recupera sem passos manuais.
                • Porta de arranque: logo após o arranque, até a app aplicar a sua política, está em vigor uma porta pf que nega por predefinição; liberta-se sozinha ao fim de 90 segundos no máximo.
                """,
                recommendation: "Quando a contenção for acionada, leia primeiro a notificação, feche as apps suspeitas e execute uma análise antes de a libertar. Se souber que se trata de um falso positivo, liberte-a de imediato."
            ),
            LocalizedEntry(
                id: "feat_port_anomaly_guard",
                title: "Bloqueio automático de portas de escuta desconhecidas e isolamento de servidores de desenvolvimento (Pro)",
                summary: "Monitoriza todas as portas TCP em escuta e, quando um executável que antes não estava exposto começa subitamente a escutar em 0.0.0.0, bloqueia o acesso a essa porta a partir da LAN. Servidores de desenvolvimento e servidores de IA locais também podem ser isolados para 127.0.0.1 com um clique.",
                details: """
                • Monitorização: as portas em escuta são analisadas a cada 20 segundos. A identidade é o caminho do executável, pelo que uma app conhecida que apenas muda de número de porta não aciona isto. O estado imediatamente após a ativação é capturado como referência.
                • Bloqueio automático: quando um executável desconhecido começa a expor uma porta, o pf bloqueia apenas o acesso externo (o próprio Mac e o localhost podem continuar a usá-la). Isto deteta uma backdoor implantada por um exploit de dia zero sem conhecer a família de malware.
                • Excluídos: daemons do sistema assinados pela Apple em `/System/Library` ou `/usr/libexec` (por exemplo, o rapportd, necessário para Handoff, AirPlay, AirDrop). Ferramentas genéricas em `/usr/bin`, como `/usr/bin/python3` ou `/usr/bin/nc`, são mesmo assim assinaladas.
                • Serviços de risco: identifica serviços frequentemente expostos sem autenticação, como Redis (6379), MongoDB (27017), Memcached (11211), Elasticsearch (9200), VNC (5900), e servidores de IA locais como Ollama (11434), LM Studio (1234), Gradio (7860) e vLLM (8000).
                • Isolamento de servidores de desenvolvimento: abra a porta em «Portas expostas» e escolha «Isolar porta» para a restringir a 127.0.0.1 (Pro).
                • Falsos positivos: permita de forma permanente com o botão «Permitir» da notificação ou a partir do ecrã de auditoria de portas. Desativar esta proteção (ou uma licença expirada) liberta todos os bloqueios que criou.
                • Predefinição: ativa-se automaticamente na primeira ativação da Pro. O histórico de incidentes está disponível através da ferramenta MCP `get_port_anomaly_incidents`.
                """,
                recommendation: "Vincule os seus servidores de desenvolvimento e LLM locais a `127.0.0.1` (por exemplo, `OLLAMA_HOST=127.0.0.1 ollama serve`, `npm run dev -- -H 127.0.0.1`)."
            ),
            LocalizedEntry(
                id: "feat_active_vuln_scan",
                title: "Verificação ativa de vulnerabilidades — desligada por predefinição",
                summary: "Para os serviços detetados neste próprio Mac (127.0.0.1), verifica com sondas mínimas de leitura se respondem realmente sem autenticação. Desligada por predefinição; requer ativação explícita e confirmação em cada execução.",
                details: """
                • Ativação: «Monitor de portas e dispositivos» → «Verificação ativa de vulnerabilidades». Isto apenas desbloqueia o botão «Executar verificação ativa» no ecrã de auditoria de portas; não envia nada por iniciativa própria, e cada execução pergunta primeiro «Enviar o pedido de verificação?».
                • Apenas para 127.0.0.1: nunca é enviado nada para outro anfitrião.
                • Acesso não autenticado: sondas únicas, com tempo limite curto e não destrutivas, para Redis (PING), Memcached (stats) e MongoDB (listDatabases).
                • Servidores de desenvolvimento genéricos: verifica configuração incorreta de CORS (Origin refletido com credenciais), travessia de caminhos e redirecionamentos abertos.
                • Correspondência com CVE conhecidas: para Redis / Memcached acessíveis sem autenticação, a versão é lida com uma consulta não destrutiva e comparada com intervalos de versão de CVE conhecidas. Não são enviadas cargas de exploração.
                • Também disponível como a ferramenta MCP `run_active_vuln_scan` (a única ferramenta que envia tráfego de rede, apenas para localhost).
                """,
                recommendation: "Ative-a apenas quando quiser confirmar se o Redis, o Docker, um LLM local ou algo semelhante em execução no seu próprio Mac está mesmo acessível sem autenticação."
            ),
            LocalizedEntry(
                id: "feat_nmap_nse",
                title: "Varrimento complementar nmap NSE (camada adicional para a verificação ativa de vulnerabilidades)",
                summary: "Quando a verificação ativa de vulnerabilidades também está ativada, executa os scripts NSE da categoria «safe» do nmap instalado no sistema contra as portas expostas para acrescentar cobertura de protocolos que as próprias sondas deste produto não têm (chaves de anfitrião SSH, banners SMTP, etc.). O resultado é o próprio julgamento do nmap, não reverificado de forma independente por este produto.",
                details: """
                • Incluído automaticamente: é executado automaticamente sempre que a «Verificação ativa de vulnerabilidades (verificação ativa de acessibilidade)» estiver ativada, sem uma definição separada para isso. O nmap nunca é instalado automaticamente — isto só tem efeito se já estiver instalado no sistema (por exemplo, via Homebrew); caso contrário, não faz nada.
                • Seleção de scripts: `safe and not broadcast and not external`. A categoria «safe» sozinha não é suficiente — os scripts `broadcast` consultam toda a LAN via multicast/difusão, não apenas o anfitrião-alvo, e os scripts `external` (por exemplo, `vulners.nse`) enviam efetivamente o serviço/versão detetados a terceiros, como o vulners.com. Ambos contrariam o princípio de design deste produto de tocar apenas em 127.0.0.1 e nunca em qualquer outro anfitrião ou servidor externo, pelo que são excluídos.
                • Tempo limite: 15 segundos por script (`--script-timeout 15s`). Alguns scripts «safe» podem correr indefinidamente contra APIs HTTP não padrão, privando outras portas de resultados sem este limite.
                • Âmbito: as mesmas portas já confirmadas como abertas que a própria verificação ativa de vulnerabilidades utiliza.
                """,
                recommendation: "Trate os resultados do nmap como informação de referência — reveja o conteúdo e aja apenas se for realmente relevante."
            ),
            LocalizedEntry(
                id: "feat_usb_keyboard_guard",
                title: "Proteção física da porta contra USB não autorizado / BadUSB (Aprovação de teclado e análise do ritmo de digitação) (Pro)",
                summary: "Quando é ligado um teclado USB desconhecido ou um cabo modificado (Rubber Ducky, O.MG Cable, Flipper Zero e semelhantes), as teclas premidas nesse dispositivo são bloqueadas até o aprovar, impedindo a injeção automatizada de comandos. Também analisa os intervalos entre teclas e avisa quando parecem ser guionizados.",
                details: """
                • Deteção: o IOHIDManager identifica novos teclados em tempo real. O teclado incorporado é confiado automaticamente.
                • Bloqueio: o dispositivo não aprovado é tomado de forma exclusiva (seize do IOHIDDevice), pelo que apenas as teclas desse dispositivo deixam de chegar ao sistema; os outros teclados continuam a funcionar. Só quando a tomada exclusiva falha é que se recorre a um bloqueio via CGEventTap, que usa a permissão de Acessibilidade.
                • Aprovação: uma janela em primeiro plano oferece «Confiar e permitir» ou «Rejeitar e manter bloqueado». Os teclados permitidos são adicionados à lista de permissões.
                • Análise do ritmo de digitação: enquanto bloqueado, os intervalos entre teclas do dispositivo continuam a ser medidos. Após pelo menos 5 intervalos, uma média de 12 ms ou menos, ou de 45 ms ou menos com uma uniformidade muito elevada (coeficiente de variação de 0,35 ou inferior), gera um aviso de «apresenta sinais de digitação guionizada». Isto capta uma velocidade e regularidade mecânicas que nenhum humano produz, apenas como prova adicional; não altera a decisão de bloqueio.
                • Desligada por predefinição. Ative-a com «Monitor de portas e dispositivos» → «Proteção física da porta contra USB não autorizado / BadUSB (Pro)»; faça a gestão da lista de permissões em «Definições de proteção USB / BadUSB…».
                """,
                recommendation: "Se usar teclados externos, registe apenas os que ligou você mesmo com «Confiar e permitir». Rejeite e desligue sempre um dispositivo que acione o aviso de digitação guionizada."
            ),
            LocalizedEntry(
                id: "feat_usb_storage_guard",
                title: "Bloqueio automático de armazenamento USB não autorizado e verificação automática com ClamAV (Pro)",
                summary: "Uma unidade USB ou disco externo que não conste na lista de permissões é primeiro montado só de leitura enquanto lhe é perguntado como proceder. Os dispositivos permitidos também são verificados com o ClamAV antes de serem ligados com a permissão configurada.",
                details: """
                • Monitorização: o DiskArbitration deteta instantaneamente as montagens de volumes externos/amovíveis.
                • Dispositivos não registados: voltam a ser montados só de leitura por segurança, com uma caixa de diálogo que oferece «Permitir leitura/escrita», «Permitir só de leitura» ou «Ejetar». Ejetar desmonta e ejeta de imediato.
                • Dispositivos permitidos: a permissão da lista de permissões (Só de leitura / Leitura/escrita) é aplicada automaticamente, com uma verificação ClamAV antes de qualquer promoção para leitura/escrita.
                • Infeção: se for encontrado malware, o volume é ejetado automaticamente e é enviado um alerta urgente.
                • Unidades reformatadas: se o UUID do volume mudar mas a identidade do hardware, incluindo o número de série, corresponder, a aprovação é mantida (o ID de fabricante/produto por si só nunca conta como correspondência).
                • Âmbito: cobre a exfiltração de dados e as cargas maliciosas via armazenamento. Os dispositivos BadUSB do tipo HID que se fazem passar por teclados são geridos por feat_usb_keyboard_guard.
                """,
                recommendation: "Adicione à lista de permissões apenas as unidades USB que usa para trabalho, e prefira a permissão Só de leitura em Macs que lidam com dados sensíveis."
            ),
            LocalizedEntry(
                id: "feat_bluetooth_guard",
                title: "Desativação automática do Bluetooth em redes não fiáveis (Pro)",
                summary: "Ao entrar numa rede em viagem onde se aplica o Bloqueio máximo, o Bluetooth é desligado automaticamente para reduzir a exposição a emparelhamentos não solicitados e ataques BLE, e restaurado ao voltar a uma rede fiável.",
                details: """
                • Ferramenta: o macOS não oferece uma API pública para ligar/desligar a alimentação do Bluetooth, pelo que o RoamSwitch usa a ferramenta open source do Homebrew `blueutil` (`brew install blueutil`). Se estiver em falta, o menu mostra instruções de instalação.
                • Restauro: o Bluetooth só volta a ligar-se numa rede fiável se estivesse ligado imediatamente antes de o RoamSwitch o desligar; uma escolha feita por si em viagem não é anulada.
                • Desligada por predefinição: muitas pessoas usam AirPods e semelhantes em cafés, pelo que cortar o áudio silenciosamente não seria bem recebido. Opcional.
                """,
                recommendation: "Se não usar acessórios Bluetooth em viagem, ative-a para evitar a deteção por rádio e os emparelhamentos não solicitados."
            ),
        ]
    }

    // MARK: - Features: malware & web protection

    private static func featuresPtPTMalware() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_webmail_download_guard",
                title: "Proteção Web e E-mail (Verificação automática e quarentena de descargas) (Pro)",
                summary: "Vigia com FSEvents os ficheiros guardados a partir de navegadores, Mail, Slack, Discord e semelhantes, verifica-os com uma assinatura estática e o ClamAV, e move as ameaças para o cofre de quarentena.",
                details: """
                • Pastas monitorizadas: por predefinição `~/Downloads`, `~/Desktop`, `~/Documents` e a pasta de descargas do Mail. Adicione ou remova pastas com «⚙️ Editar pastas monitorizadas…».
                • Origem da descarga: identificada através do atributo estendido `com.apple.quarantine` que o macOS lhe associa.
                • Verificação em duas camadas: uma verificação de assinatura estática no dispositivo (frases clássicas de reverse shell e semelhantes; funciona mesmo sem o ClamAV) mais uma verificação com o ClamAV. Uma correspondência de assinatura estática leva à quarentena independentemente do veredito do ClamAV, e se o ClamAV discordar, a notificação indica que pode ser um falso positivo.
                • Quarentena: as ameaças são movidas para `~/Library/Application Support/RoamSwitch/Quarantine/` (nunca eliminadas). Se a movimentação falhar, a notificação indica que a quarentena falhou e pede para eliminar o ficheiro manualmente.
                • Ficheiro de teste EICAR: a assinatura de teste padrão da indústria, inofensiva, não é colocada em quarentena nem bloqueada e não gera nenhuma notificação; é apenas registada no histórico de notificações (feat_notification_history).
                • Primeiro acesso à pasta: antes do pedido de permissão do macOS, surge um aviso único a explicar que se trata de uma permissão legítima para esta função de verificação.
                • Avisos sobre modelos em formato Pickle: ver feat_ai_model_guard.
                """,
                recommendation: "Instale e ative o ClamAV, e adicione qualquer pasta de descargas do navegador personalizada às pastas monitorizadas."
            ),
            LocalizedEntry(
                id: "feat_ai_model_guard",
                title: "Aviso de descarga de um formato de modelo de IA perigoso (Pickle / PyTorch) (Pro)",
                summary: "Quando um ficheiro de modelo `.pkl` / `.pickle` / `.pt` é descarregado do Hugging Face, Civitai ou semelhante, avisa que o formato Pickle pode executar código arbitrário ao ser carregado, e recomenda SafeTensors / GGUF.",
                details: """
                • Deteção: verifica a extensão dos ficheiros descarregados nas pastas monitorizadas pela Proteção Web e E-mail (feat_webmail_download_guard).
                • Risco: o Pickle do Python pode executar código arbitrário durante a desserialização, pelo que o simples carregamento de um modelo malicioso pode comprometer o Mac.
                • Comportamento: apenas um aviso; o ficheiro não é colocado em quarentena (uma correspondência do ClamAV ou da assinatura estática continua a levar à quarentena como habitualmente).
                """,
                recommendation: "Não carregue modelos Pickle / PyTorch de fontes desconhecidas; use antes modelos `.safetensors` ou `.gguf`."
            ),
            LocalizedEntry(
                id: "feat_quarantine_manager",
                title: "Gestão de ficheiros em quarentena (cofre, restauro, eliminação, exclusões de análise)",
                summary: "Os ficheiros assinalados pelo ClamAV ou pela verificação de assinatura estática nunca são eliminados; ficam guardados no cofre de quarentena. O Gestor de quarentena permite ver o motivo, restaurar para o local original, eliminar permanentemente, ou excluir um caminho de análises futuras.",
                details: """
                • Abrir: «Proteção contra malware (XProtect e ClamAV)» → ClamAV → «📦 Gerir ficheiros em quarentena…», ou «📦 Abrir gestor de quarentena…» em Proteção Web e E-mail.
                • Localização: `~/Library/Application Support/RoamSwitch/Quarantine/`, com metadados sobre o caminho original, o nome da ameaça e o momento da quarentena. Nada é removido a menos que escolha explicitamente Eliminar permanentemente.
                • Restaurar: repõe o ficheiro no seu local original; use apenas quando tiver a certeza de que não está infetado.
                • Excluir e restaurar: para um falso positivo confirmado, restaura o ficheiro e exclui esse caminho exato de futuras verificações do ClamAV. As exclusões estão listadas na mesma janela, onde «Remover exclusão» as reverte.
                • Eliminar permanentemente: elimina após uma confirmação. Esta ação não pode ser anulada.
                • A ferramenta MCP `get_quarantine_status` lista os ficheiros em quarentena.
                """,
                recommendation: "Elimine os ficheiros que não reconhece, e use «Excluir e restaurar» apenas para falsos positivos certos, como os seus próprios scripts ou binários de desenvolvimento."
            ),
            LocalizedEntry(
                id: "feat_xprotect_file_safety",
                title: "Estado do Apple XProtect e verificação de segurança de ficheiro/app",
                summary: "Mostra a versão das definições e o estado da proteção anti-malware integrada do macOS, o XProtect, e verifica se um ficheiro ou app qualquer está notarizado, por que autoridade foi assinado, com que Team ID e com o atributo de quarentena de descarga. Disponível na edição gratuita.",
                details: """
                • Abrir: «Proteção contra malware (XProtect e ClamAV)» → «🍏 Apple XProtect» → «Verificar estado do XProtect…» / «Verificar segurança de ficheiro/app…».
                • Verificações: aprovado pela Apple (Notarizado/Gatekeeper) ou não, autoridade de assinatura, Team ID, o atributo de quarentena de descargas Web (`com.apple.quarantine`), e o caminho.
                • Utilização: antes de abrir uma app pela primeira vez, confirme que foi assinada e notarizada por um programador legítimo.
                """,
                recommendation: "Verifique as apps de origem desconhecida antes de as executar, e não abra nada que não esteja aprovado nem assinado."
            ),
            LocalizedEntry(
                id: "feat_dns_threat_guard",
                title: "Proteção contra ameaças DNS (Bloquear malware e C2) (Pro)",
                summary: "Aplica um resolvedor DNS seguro (Quad9, Cloudflare, AdGuard, CleanBrowsing) para que as resoluções de nomes para servidores C2 de malware e sites de phishing sejam bloqueadas já na fase DNS.",
                details: """
                • Fornecedores: Quad9 (9.9.9.9 / 149.112.112.112), Cloudflare Security (1.1.1.2 / 1.0.0.2), AdGuard DNS (94.140.14.14 / 94.140.15.15, também bloqueia anúncios e rastreadores), CleanBrowsing Security (185.228.168.9 / 185.228.169.9).
                • Política: «Apenas em Wi-Fi não fidedigno fora de casa (recomendado)» ou «Sempre ativo em todas as redes (incluindo redes fidedignas)».
                • Internamente: o auxiliar privilegiado muda os servidores DNS do serviço de rede ativo e restaura as definições DHCP/DNS manuais originais ao voltar a uma rede fidedigna.
                • Estado: o menu mostra «🟢 DNS seguro ativo» ou «🏠 Rede fidedigna (DNS padrão do router)». É também um item da auditoria de segurança do Mac.
                """,
                recommendation: "Para evitar DNS falso em Wi-Fi público (sequestro de DNS) e domínios maliciosos, comece com o Quad9 e a política reservada a fora de casa."
            ),
            LocalizedEntry(
                id: "feat_passive_link_guard",
                title: "Proteção de links (Detetar e bloquear ligações de phishing: extensão do sistema, compatível com DoH, o modo Aviso falha de forma fechada) (Pro)",
                summary: "Bloqueia no dispositivo as ligações a sites de phishing e de burla, para qualquer navegador ou app, com base numa lista de ameaças de domínios de burla conhecidos e na deteção de personificação de marca. Funciona como uma extensão do sistema de filtragem de conteúdo, com um «sinkhole» /etc/hosts como alternativa até a extensão ser aprovada.",
                details: """
                • Modos: «Desligado», «Apenas avisar (nunca bloquear)» e «Bloquear automaticamente sites de phishing evidentes (recomendado)» (predefinição). Mude o modo em Proteção contra malware → «Proteção de links (deteção de ligações de phishing) (Pro)».
                • O que é bloqueado: apenas os casos evidentes, ou seja, domínios presentes na lista de ameaças ou personificação de marca através de homógrafos Unicode. Truques com a marca num subdomínio, TLD de alto risco e semelhantes são tratados como avisos. O motor de veredito e a lista são partilhados com a edição Linux.
                • Extensão do sistema (recomendado): a extensão do sistema de filtragem de conteúdo `RoamSwitchLinkFilter` examina os fluxos TCP após a resolução do nome. Além do nome de anfitrião resolvido pelo sistema operativo, também lê o SNI do ClientHello TLS, pelo que funciona mesmo que o navegador use o seu próprio DoH / DoT. No modo bloqueio, descarta o QUIC (UDP 443), onde o SNI não é visível, para que os navegadores recorram ao TCP. A primeira utilização requer aprovação nas Definições do Sistema.
                • Impressão digital JA3: para ligações TLS cujo SNI foi lido, também é calculado o hash JA3 do cliente e comparado com a lista JA3 das ameaças (o JA3 nunca é usado sozinho em ligações sem SNI).
                • Modo Aviso (falha de forma fechada): a ligação correspondente é pausada e surgem uma notificação Permitir/Bloquear e um painel em primeiro plano; o fluxo é retomado ou descartado consoante a sua resposta. Sem resposta em cerca de 8 segundos, a ligação é bloqueada. Esse resultado não é guardado em cache, pelo que a tentativa seguinte voltará a perguntar. As respostas que efetivamente der são memorizadas. O modo Aviso requer a extensão do sistema.
                • Alternativa via hosts: enquanto a extensão não está ativa, o modo bloqueio faz o auxiliar privilegiado escrever os domínios como `0.0.0.0` numa secção gerida de `/etc/hosts`.
                • Lista de ameaças: obtida uma vez por dia, apenas em receção, sem enviar identificadores, e verificada com uma chave dedicada Ed25519 para a lista (distinta da chave de atualização da app). Desligar a «Atualização automática» significa zero tráfego de saída; os dados incluídos e a deteção de homógrafos continuam a funcionar.
                • Sem Pro: o modo é guardado mas nada é bloqueado.
                """,
                recommendation: "Mantenha o bloqueio automático predefinido e aprove a extensão do sistema para a proteção mais fiável. Se uma ferramenta interna for bloqueada por engano, use «Permitir uma vez (5 min)» na notificação ou a lista de permissões."
            ),
            LocalizedEntry(
                id: "feat_link_safety_auditor",
                title: "Verificação de segurança de links (verificação manual, Zero Telemetry)",
                summary: "Antes de abrir um URL suspeito, analisa-o inteiramente no dispositivo e pontua o seu risco numa escala até 100 com base em homógrafos Unicode, personificação de subdomínio, TLD de alto risco, HTTP não cifrado, endereços IP em bruto, e mais. Disponível na edição gratuita.",
                details: """
                • Abrir: Proteção contra malware → «🔗 Verificar um link manualmente…», ou a ferramenta MCP `audit_url_safety`.
                • Homógrafos: deteta carateres visualmente semelhantes, como letras cirílicas ou gregas (Punycode / `xn--`).
                • Personificação de subdomínio: analisa estruturas como `apple.com.login-verify.xyz` que incorporam o nome de uma grande marca.
                • TLD de alto risco: retira pontos por TLD comuns em phishing descartável, como `.xyz`, `.top`, `.tk`, `.icu`.
                • HTTP não cifrado e IP em bruto: avisa sobre HTTP não cifrado em páginas de início de sessão e URL com endereço IP nu.
                • Totalmente local: os URL nunca são enviados para uma API de análise externa, pelo que os URL confidenciais e os tokens não são divulgados.
                """,
                recommendation: "Não clique diretamente em links suspeitos recebidos por e-mail ou chat; verifique-os primeiro com a Verificação de segurança de links."
            ),
            LocalizedEntry(
                id: "feat_ransomware_canary_guard",
                title: "Deteção de ransomware através de ficheiros-isco e Air-Gap autónomo com congelamento de processos (Pro)",
                summary: "Coloca ficheiros-isco (canário) ocultos nas suas pastas de utilizador. Assim que um deles é modificado, eliminado ou renomeado, corta automaticamente a rede, para os serviços de partilha e coloca em pausa (SIGSTOP) o processo suspeito.",
                details: """
                • Ficheiros-isco: quatro em `~/Library/Application Support/RoamSwitch/CanaryGuard/`, mais ficheiros ocultos que começam por `.roamswitch_security_canary_do_not_delete` em Documentos, Ambiente de Trabalho, Transferências e Fotografias. O SHA-256 de cada ficheiro é registado como referência.
                • Deteção: vigilância kqueue em tempo real mais uma verificação a cada 60 segundos. Um período de espera de 10 segundos por ficheiro evita o processamento duplicado de uma mesma rajada de eventos. Ficheiros reais modificados nos últimos 60 segundos são registados como possivelmente afetados.
                • Resposta automática: (1) bloqueio da firewall de aplicações, (2) contenção Air-Gap (o pf bloqueia todo o tráfego e o Wi-Fi é desligado, feat_airgap_containment), (3) os serviços de partilha (SMB / SSH / Partilha de ecrã) são parados, (4) o processo suspeito é colocado em pausa com SIGSTOP em vez de terminado, (5) alerta urgente e janela de emergência em primeiro plano.
                • Porquê pausar em vez de terminar: a rede já está cortada, pelo que um processo em pausa não pode causar mais danos. Se foi um falso positivo, é retomado (SIGCONT) ao libertar a contenção, sem perda de dados.
                • Ao libertar: a rede e o Wi-Fi são restaurados, o processo em pausa é retomado, e os ficheiros-isco adulterados são regenerados.
                • Predefinição: ativa-se automaticamente na primeira ativação da Pro. Histórico de incidentes através da ferramenta MCP `get_canary_status`. Teste em segurança com «Simulação de defesa contra ransomware (Modo de teste)» no menu.
                """,
                recommendation: "Mantenha-a ativa para proteger dados importantes de ransomware desconhecido, e não elimine os ficheiros-isco ocultos."
            ),
            LocalizedEntry(
                id: "feat_runtime_threat_containment",
                title: "Desconexão automática da rede na deteção de malware pelo XProtect (Pro)",
                summary: "No instante em que o XProtect / XProtect Remediator, integrado no macOS, deteta ou remove realmente malware, a rede é cortada num Air-Gap de emergência. Um bloqueio do Gatekeeper a uma app não assinada não corta a rede; envia apenas uma notificação.",
                details: """
                • Origem do sinal: uma subscrição de longa duração a `/usr/bin/log stream` em formato ndjson (espera bloqueante em vez de sondagem, pelo que o custo de CPU em repouso é quase nulo) vigia os registos do sistema relacionados com o XProtect.
                • Acionamento: apenas quando o XProtect regista uma deteção crítica de malware é que a contenção Air-Gap é acionada (incluindo a desativação do Wi-Fi), independentemente do nível de confiança da rede.
                • Diferença em relação ao Gatekeeper: eventos quotidianos do Gatekeeper, como bloquear uma compilação não assinada do próprio programador, apenas geram a notificação «O Gatekeeper impediu a execução de uma app não assinada».
                • Consistência: partilha a mesma lógica de classificação da Auditoria de registos de segurança do Mac manual.
                • Por não usar a permissão EndpointSecurity, trata-se de uma contenção imediata após a deteção, e não de um bloqueio antes da execução.
                • Predefinição: ativa-se automaticamente na primeira ativação da Pro (com um aviso único de que a desconexão automática está ativa). O estado está disponível através da ferramenta MCP `get_runtime_threat_status`; teste com «Simulação de Air-Gap por deteção de malware (teste)».
                """,
                recommendation: "Mantenha-a ativa como defesa automática ligada ao próprio motor anti-malware da Apple. Executar frequentemente as suas próprias apps não assinadas não a irá acionar, porque um simples bloqueio do Gatekeeper nunca corta a rede."
            ),
            LocalizedEntry(
                id: "feat_clickfix_guard",
                title: "Defesa ClickFix — bloqueio automático ao detetar comandos suspeitos no Terminal (Pro, desligada por predefinição)",
                summary: "Deteta no histórico da shell a técnica ClickFix, em que uma falsa página de verificação ou de erro o induz a colar e executar você mesmo um comando, e corta a rede para travar um ataque de várias etapas em curso.",
                details: """
                • Vigiado: apenas as linhas recentemente adicionadas a `~/.zsh_history` e `~/.bash_history` (o histórico existente é ignorado).
                • Padrões: (1) frases conhecidas de reverse shell (partilhadas com a verificação de assinatura estática), e (2) dupla indireção que canaliza conteúdo descodificado em Base64 diretamente para uma shell ou para o `osascript`. Um simples `curl ... | bash`, como o usado por instaladores legítimos como o Homebrew, é deliberadamente não assinalado.
                • Resposta: contenção Air-Gap (o Wi-Fi não é desligado), restaurada automaticamente no máximo em 10 minutos. A notificação recomenda verificar o seu porta-chaves, as palavras-passe guardadas no navegador e as suas carteiras de criptomoedas.
                • Porquê depois do facto: quando uma linha aparece no histórico, o comando já foi executado, mas cortar a rede de imediato ainda pode travar uma segunda descarga em curso, uma ligação de reverse shell ativa, ou uma exfiltração de credenciais em curso.
                • Porque o Gatekeeper não pode impedi-lo: é a sua própria shell legítima a executar exatamente o que escreveu, pelo que nada no processo em si parece invulgar.
                • Complemento: a proteção da área de transferência (feat_secret_leak_auditor) intercepta o comando no momento da cópia, cobrindo as colagens no Editor de Scripts, Spotlight, e outros locais além do Terminal.
                • Desligada por predefinição: um corte automático da rede motivado por uma heurística relativamente nova, sendo por isso opcional.
                """,
                recommendation: "Considere ativá-la se receia ser enganado por falsas páginas de erro ou verificações para executar comandos."
            ),
            LocalizedEntry(
                id: "feat_persistence_monitor_guard",
                title: "Monitorizar novos registos de início automático (LaunchAgent / LaunchDaemon) (Pro)",
                summary: "Vigia em tempo real novos registos de LaunchAgent / LaunchDaemon e avisa-o quando um deles inicia diretamente uma shell ou um interpretador de scripts, ou regista um executável com uma assinatura inválida.",
                details: """
                • Vigiado: `~/Library/LaunchAgents`, `/Library/LaunchAgents` e `/Library/LaunchDaemons` através de FSEvents (anti-ressalto de cerca de 1,5 segundos).
                • Critério: os ladrões de informação recentes conseguem persistência fazendo com que um `/bin/bash` ou `/usr/bin/osascript` validamente assinado pela Apple execute um script oculto em Base64. Como a assinatura do próprio interpretador é válida, qualquer registo que inicie um interpretador puro é tratado como suspeito independentemente da assinatura, e os seus argumentos de script também passam pela verificação de assinatura estática. Executáveis não assinados ou com assinatura inválida também são assinalados. Os invólucros do Homebrew services estão isentos.
                • Apenas deteção: sem a permissão EndpointSecurity, não é possível impedir a escrita do plist. É avaliado e notificado cerca de 1,5 segundos após ser escrito.
                • Predefinição: ativa por predefinição com a Pro. Ative/desative em Proteção contra malware → «Monitorizar novos registos de início automático (LaunchAgent/Daemon) (Pro)».
                """,
                recommendation: "Se receber um alerta de registo desconhecido, examine o plist mostrado na notificação e elimine-o se não o reconhecer. Logo após instalar uma app legítima, normalmente não há problema."
            ),
            LocalizedEntry(
                id: "feat_docker_event_guard",
                title: "Detetar contentores Docker privilegiados e montagens docker.sock (Pro, desligada por predefinição)",
                summary: "Avisa-o, quando um contentor é iniciado, sobre configurações do Docker arriscadas que podem levar a uma fuga do contentor, como contentores iniciados com `--privileged` ou com `/var/run/docker.sock` montado.",
                details: """
                • Como: a cada 20 segundos, `docker ps` encontra apenas os contentores recém-iniciados, e `docker inspect` verifica as suas definições. O formato de deteção é idêntico ao da edição Linux, pelo que ambas as plataformas assinalam as mesmas condições.
                • Apenas notificação: trata-se de uma configuração arriscada, e não de um comprometimento confirmado (um agente de monitorização pode ser executado privilegiado de propósito), pelo que nada é bloqueado automaticamente.
                • Desligada por predefinição: a maioria dos utilizadores não usa Docker, pelo que está desligada mesmo na Pro.
                • Teste: «⚠️ Simulação de deteção de riscos do Docker (Modo de teste)…» verifica o caminho de notificação sem tocar no Docker.
                """,
                recommendation: "Se usar o Docker para desenvolvimento, ative-a para detetar cedo os riscos de fuga do contentor."
            ),
        ]
    }

    // MARK: - Features: audit, monitoring & platform

    private static func featuresPtPTAudit() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "feat_critical_path_fim",
                title: "Monitorização de adulteração de ficheiros críticos do sistema (Critical Path FIM) (Pro)",
                summary: "Regista uma referência SHA-256 de ficheiros críticos como sudoers, a configuração SSH, PAM e hosts, que atualizações legítimas do sistema ou instalações de apps quase nunca alteram, e avisa-o de qualquer modificação, eliminação ou novo ficheiro.",
                details: """
                • Ficheiros: `/etc/sudoers`, `/etc/pam.d/sudo`, `/etc/ssh/sshd_config`, tudo o que está em `/etc/ssh/sshd_config.d/`, `/etc/hosts`, e o `~/.ssh/authorized_keys` do root. São apenas acessíveis pelo root, pelo que o auxiliar privilegiado calcula os hashes.
                • Quando: os FSEvents em `/etc`, `/etc/pam.d` e `/etc/ssh` desencadeiam uma nova análise quase em tempo real, com uma análise horária como rede de segurança.
                • Referência: capturada na primeira análise. Uma alteração detetada nunca é adotada automaticamente como nova referência, pelo que a deteção persiste até ser revista por um humano. O mesmo estado não é renotificado enquanto a app estiver em execução; qualquer alteração adicional volta a alertar.
                • Aviso de ponto cego: se o auxiliar não puder ser contactado durante 3 análises seguidas, é avisado de que a deteção de adulteração não está a funcionar.
                • Nota: enquanto a Proteção de links funciona na sua alternativa via hosts, o próprio RoamSwitch pode reescrever a sua secção gerida de `/etc/hosts`. Os LaunchAgents / Daemons são cobertos por feat_persistence_monitor_guard.
                • Predefinição: ativa-se automaticamente na primeira ativação da Pro. Menu: Proteção contra malware → «Monitorizar periodicamente ficheiros críticos do sistema quanto a adulterações (Pro)».
                """,
                recommendation: "Quando for avisado, verifique se foi você a fazer a alteração (por exemplo, `sudo visudo` ou uma edição de configuração). Se não, examine o ficheiro de imediato e pondere mudar a sua palavra-passe."
            ),
            LocalizedEntry(
                id: "feat_security_log_audit",
                title: "Auditoria de registos de segurança do Mac (manual, deteção de anomalias de modelo, cópia para consulta com IA)",
                summary: "Extrai do registo unificado do macOS as falhas de sudo, ligações SSH, bloqueios do Gatekeeper, deteções do XProtect e eventos de autenticação, e também lista novos padrões de registo e picos de frequência (anomalias de modelo). Disponível na edição gratuita.",
                details: """
                • Abrir: Auditoria de segurança do Mac → «📜 Auditoria de registos de segurança do Mac…», ou a ferramenta MCP `audit_security_logs`.
                • Período: últimas 24 horas, 3 dias ou 7 dias.
                • Cartões de resumo: falhas de Sudo, ligações SSH, bloqueios do Gatekeeper, deteções do XProtect, anomalias de modelo. Pode filtrar por categoria e pesquisar.
                • Anomalias de modelo: as linhas de registo são transformadas em modelos ao mascarar as partes variáveis (endereços IP, endereços hexadecimais, números). Isto faz sobressair padrões nunca vistos neste Mac ([novo]) e picos bem acima da sua frequência habitual ([pico z=…], pontuação z de 3 ou mais). A frequência de cada padrão é aprendida após 3 observações, após o que um volume normal deixa de alertar.
                • Veredito em linguagem simples: um assistente baseado em regras no dispositivo resume o resultado para não especialistas com pontos concretos a verificar (sem API externa).
                • Saída: «Copiar relatório», «Copiar materiais para consulta com IA» (copia uma pergunta mais os registos para colar no Claude, ChatGPT e semelhantes; o RoamSwitch não envia nada), e «Exportar CSV (Pro)».
                """,
                recommendation: "Execute-a quando continuarem a chegar notificações suspeitas ou o Mac se comportar de forma estranha, e verifique se há deteções do XProtect ou um aumento de falhas de sudo."
            ),
            LocalizedEntry(
                id: "feat_scheduled_log_audit",
                title: "Auditoria automática de registos (aprende novos padrões e anomalias de frequência de forma agendada) (Pro)",
                summary: "Executa de hora a hora, em segundo plano, a deteção de anomalias de modelo da auditoria de registos, aprendendo continuamente o comportamento normal dos registos deste Mac. Quando encontra novos padrões ou picos de frequência, avisa-o com linhas de registo reais e uma explicação em linguagem simples.",
                details: """
                • Calendário: de hora a hora, analisando a última hora. A primeira análise é executada cerca de 10 segundos após a ativação, mas como inclui os próprios registos de arranque da app, essa execução apenas aprende e nunca notifica.
                • Notificação: a contagem de anomalias (dividida em novos padrões e picos), até 3 linhas de registo reais, uma nota sobre o progresso da aprendizagem, e uma explicação para não especialistas. Um lote que inclua um pico de frequência mostra um alerta na Central de Notificações; um lote composto apenas por novos padrões é registado no histórico de notificações sem mostrar qualquer alerta. Um novo padrão torna-se «conhecido» assim que é registado e nunca mais é reregistado pelo mesmo conteúdo; um pico deixa de alertar assim que a referência própria desse padrão for aprendida.
                • Partilhada com a auditoria manual: usa a mesma análise e a mesma referência aprendida que a Auditoria de registos de segurança do Mac manual e a ferramenta MCP `audit_security_logs`.
                • Predefinição: ativa-se automaticamente na primeira ativação da Pro. Menu: Proteção contra malware → «Auditoria automática de registos (aprende novos padrões e anomalias de frequência de forma agendada) (Pro)».
                """,
                recommendation: "Espere um pouco mais de alertas de novos padrões logo após a configuração; estabilizam à medida que a aprendizagem avança. Se um alerta mencionar uma app ou um IP desconhecido, abra a janela de auditoria de registos para mais detalhes."
            ),
            LocalizedEntry(
                id: "feat_containment_incident_timeline",
                title: "Linha temporal de incidentes de contenção (registo unificado, correspondência com MITRE ATT&CK)",
                summary: "Guarda as quatro respostas automáticas (falsificação de ARP, ficheiros-isco de ransomware, corte ligado ao XProtect, bloqueio automático de porta desconhecida) num único registo cronológico no dispositivo, para que possa rever mais tarde o que aconteceu, o que foi feito e quando foi resolvido.",
                details: """
                • Registado: hora, origem, gravidade, resumo, nome do processo e PID (se conhecido), ação tomada, e hora e motivo da resolução (libertado manualmente, libertado automaticamente por tempo esgotado, ou adicionado à lista de permissões).
                • MITRE ATT&CK: um identificador de técnica só é adicionado quando a correspondência é certa (falsificação de ARP = T1557; ficheiro-isco eliminado ou renomeado = T1485; cifragem = T1486; outra adulteração = T1565). Nada é adivinhado.
                • Armazenamento: `~/Library/Application Support/RoamSwitch/containment_incident_timeline.json` (os 200 mais recentes). Nunca é enviado para lado nenhum.
                • A ferramenta MCP `get_incident_timeline` devolve esta linha temporal unificada (útil para triagem com uma IA local durante um Air-Gap). O histórico por proteção também está disponível através de `get_canary_status`, `get_port_anomaly_incidents` e `get_runtime_threat_status`.
                """,
                recommendation: "Após um corte automático, reveja esta linha temporal juntamente com o histórico de notificações para encontrar a causa e evitar que se repita."
            ),
            LocalizedEntry(
                id: "feat_notification_history",
                title: "Histórico de notificações (última semana)",
                summary: "Guarda todas as notificações enviadas pelo RoamSwitch durante 7 dias para que possa rever os avisos que perdeu. Eventos registados no histórico sem aviso, como a deteção de uma assinatura de teste EICAR, também aparecem aqui. Disponível na edição gratuita.",
                details: """
                • Abrir: Auditoria de segurança do Mac → «🔔 Histórico de notificações…».
                • Retenção: 7 dias; as entradas mais antigas são removidas automaticamente sempre que é registada uma nova.
                • Conteúdo: hora, título e corpo, incluindo alertas de ameaça, eventos de ligação da Proteção de links, deteções de ClickFix e de chaves secretas, e cortes automáticos.
                • Assinatura de teste EICAR: o ficheiro de teste inofensivo padrão da indústria não é uma ameaça real, pelo que não é colocado em quarentena nem bloqueado e não aparece nenhum aviso; é apenas registado aqui. Isto aplica-se da mesma forma à proteção de descargas, verificações rápidas e verificações agendadas.
                • Um assistente de IA pode lê-lo através da ferramenta MCP `get_notification_history`.
                """,
                recommendation: "Se perdeu uma notificação enquanto estava fora ou ocupado, verifique-a aqui."
            ),
            LocalizedEntry(
                id: "feat_secret_leak_auditor",
                title: "Proteção da área de transferência (aviso de colagem de chave de API e remoção de comandos ClickFix)",
                summary: "Vigia a área de transferência apenas no dispositivo, avisa quando uma chave de API ou uma chave privada foi copiada para que não a cole por engano, e limpa automaticamente a área de transferência quando copia um comando malicioso que um site de burla quer que execute (ClickFix). Ativa por predefinição na edição gratuita.",
                details: """
                • Monitorização: verifica alterações na área de transferência cerca de uma vez por segundo. O conteúdo nunca é enviado nem armazenado.
                • Chaves detetadas: chaves de API e tokens da OpenAI, Anthropic, GitHub, AWS, Hugging Face, Google AI / Gemini, Slack e Stripe, além de chaves privadas RSA / SSH. Também frases-semente de carteiras cripto (BIP39) e chaves privadas Bitcoin (WIF/BIP32), ambas verificadas por checksum para reduzir falsos positivos.
                • Para chaves secretas: apenas notificação («Chave confidencial detetada na área de transferência»); a área de transferência não é limpa, uma vez que uma chave divulgada ainda pode ser revogada e renovada posteriormente.
                • Para comandos ClickFix: notificação («Comando suspeito detetado na área de transferência») e a área de transferência é limpa de imediato, impedindo a colagem seja para onde for: Terminal, Editor de Scripts, Spotlight ou outro local. Isto complementa feat_clickfix_guard, que vigia o histórico da shell.
                """,
                recommendation: "Depois de copiar uma chave de API, tenha cuidado com o local onde a cola, especialmente em chats de IA e formulários web. Se a partilhou por engano, revogue-a e renove-a de imediato."
            ),
            LocalizedEntry(
                id: "feat_secret_leak_audit_tool",
                title: "Auditoria manual de fugas de segredos / chaves de API (colar texto ou analisar uma pasta inteira)",
                summary: "Uma ferramenta de auditoria a pedido que verifica instantaneamente o texto colado ou analisa uma pasta de forma recursiva, mostrando números de linha, valores mascarados e passos de revogação para cada tipo de chave. Disponível na edição gratuita.",
                details: """
                • Abrir: Proteção contra malware → «🔑 Auditar manualmente fugas de segredos/chaves de API…», ou a ferramenta MCP `audit_secrets` (com `text` ou `path`).
                • Método: expressões regulares mais uma pontuação de entropia de Shannon. Os valores detetados são mostrados mascarados.
                • Análise de pasta: `.git`, `node_modules`, `target`, `vendor`, `dist`, `build`, `__pycache__` e `venv` são ignorados automaticamente, tal como ficheiros com mais de 2 MB e ficheiros binários.
                • Aviso de permissão: escolher uma pasta protegida como Ambiente de Trabalho ou Transferências mostra primeiro um aviso único a explicar porque é necessário o acesso e que a análise é Zero Telemetry, antes do pedido do macOS.
                • Executa-se numa thread em segundo plano sem bloquear a interface. Nada é enviado para lado nenhum.
                """,
                recommendation: "Use-a antes de publicar um repositório ou de colar código num chat de IA."
            ),
            LocalizedEntry(
                id: "feat_package_cve_scan",
                title: "Verificação de CVE de pacotes (Homebrew + 7 ecossistemas, incluindo npm / PyPI / crates.io, Zero Telemetry)",
                summary: "Compara os pacotes Homebrew instalados e os ficheiros de bloqueio de dependências nas pastas de projeto que escolher com mapas de CVE conhecidas guardados no dispositivo. A própria verificação não efetua qualquer pedido de rede. Disponível na edição gratuita.",
                details: """
                • Abrir: Proteção contra malware → «📦 Verificação de CVE de pacotes (Homebrew)…». Para dependências, adicione pastas de projeto no separador Dependências.
                • Homebrew: `brew list --versions` é comparado com uma tabela de fórmula para CPE gerada a partir de dados reais da NVD. Os resultados têm um nível de confiança: confirmed (tabela verificada) ou gray (correspondência de palavra-chave não verificada que pode ser um falso positivo).
                • Dependências: analisa package-lock.json / requirements.txt / Pipfile.lock / poetry.lock / Cargo.lock / Gemfile.lock / composer.lock / go.sum / pom.xml e compara-os com mapas de CVE conhecidas para npm, PyPI, crates.io, RubyGems, Packagist, Go e Maven (do OSV.dev, CVSS 7,0 ou superior).
                • Distribuição de dados: os mapas de CVE são obtidos uma vez por dia a partir de um manifesto assinado, apenas em receção. Antes de serem obtidos, mostram-se como ainda não descarregados e não detetam nada.
                • Ferramentas MCP: `run_package_cve_scan` (Homebrew) e `run_package_cve_scan_languages` (dependências, argumento `watchedFolders`).
                """,
                recommendation: "Execute a verificação do Homebrew regularmente, registe os projetos ativos no separador Dependências, e atualize prontamente os pacotes com CVE graves."
            ),
            LocalizedEntry(
                id: "feat_lockfile_tamper_guard",
                title: "Monitorização de adulteração de lockfiles de dependências (Lockfile FIM, Pro)",
                summary: "Monitoriza continuamente package-lock.json / yarn.lock / pnpm-lock.yaml / npm-shrinkwrap.json através de uma linha de base SHA-256, detetando adulteração externa via CI ou cadeia de fornecimento. Apenas Pro.",
                details: """
                • Como abrir: alterne a partir do item da barra de menus «🔔/✅ Monitorizar periodicamente a adulteração de lockfiles de dependências (Pro)».
                • Ficheiros monitorizados: as mesmas pastas de projeto registadas no separador «Dependências» da verificação de CVE de pacotes — sem lista de pastas separada.
                • Deteção: diferença de linha de base SHA-256 via CryptoKit, com deteção quase em tempo real por FSEvents mais uma verificação de reserva a cada hora.
                • Urgência da notificação: se o npm/yarn/pnpm estiver em execução no momento da deteção, isso é registado no histórico de notificações com um alerta silencioso; caso contrário, é um alerta crítico normal. A deteção em si nunca é omitida em nenhum dos casos.
                • Desativado automaticamente em caso de perda da licença Pro.
                """,
                recommendation: "Registe os projetos importantes no separador «Dependências» da verificação de CVE de pacotes e deixe esta funcionalidade ativa (predefinida quando o Pro está ativo)."
            ),
            LocalizedEntry(
                id: "feat_package_lifecycle_script_scan",
                title: "Inventário de scripts de instalação (scripts de ciclo de vida package.json do npm, Pro)",
                summary: "Lista os scripts preinstall/install/postinstall/prepare declarados pelos ficheiros package.json em node_modules. Destina-se a revelar código executado incondicionalmente durante o npm install — não é um veredito de ameaça. Apenas Pro.",
                details: """
                • Como abrir: menu «Proteção contra malware» → «📦 Verificação de CVE de pacotes (Homebrew)…» → separador «Scripts de instalação (npm) (Pro)». Analisa as mesmas pastas de projeto do separador «Dependências».
                • Âmbito: um nível abaixo de node_modules (mais um nível adicional para pacotes @scope/). Nunca desce ao node_modules próprio de um pacote.
                • Marcação apenas informativa: os comandos que correspondem a curl|sh, wget|sh, eval(, base64 -d ou node -e recebem um emblema ⚠️ — uma heurística leve, não um veredito; muitos scripts legítimos (compilações de módulos nativos, etc.) também correspondem.
                • Sem qualquer ligação de rede, e nada é executado — um inventário puramente estático.
                • Ferramenta MCP: `run_package_lifecycle_script_scan` (argumento `watchedFolders`, apenas Pro).
                """,
                recommendation: "Para qualquer script assinalado com ⚠️, verifique se o pacote realmente precisa dele — preste especial atenção aos scripts postinstall de pacotes pouco conhecidos."
            ),
            LocalizedEntry(
                id: "feat_npm_audit_signatures",
                title: "Verificação de assinaturas/proveniência npm (npm audit signatures, opcional, Pro)",
                summary: "Contacta o registo npm para verificar as assinaturas/proveniência dos pacotes instalados. A única funcionalidade do RoamSwitch que comunica com npmjs.com — desativada por predefinição, requer ativação explícita e confirmação em cada execução. Apenas Pro.",
                details: """
                • Como ativar: o interruptor «Ativar a verificação de assinaturas npm» no separador «📦 Verificação de CVE de pacotes» → «Verificação de assinaturas npm (opcional) (Pro)». Isto apenas desbloqueia o botão «Executar auditoria» de cada pasta de projeto — nunca envia nada por si só. Cada execução é confirmada com «Contactar o registo npm?».
                • O que faz: executa `npm audit signatures` com a pasta alvo como diretório de trabalho, contactando o registo npm (registry.npmjs.org). É a única funcionalidade do RoamSwitch que comunica com npmjs.com.
                • Saída: a saída do próprio comando npm é apresentada tal como é (nunca interpretada manualmente). Um código de saída diferente de zero, ou termos como «invalid»/«missing registry signature» na saída, recebem uma marca de atenção leve.
                • Se o comando npm não for encontrado, aparece uma mensagem a sugerir a instalação do Node.js/npm.
                • Ferramenta MCP: `run_npm_audit_signatures` (argumento `directory`, com dupla verificação Pro mais o interruptor opcional).
                """,
                recommendation: "Ative apenas para uma auditoria de dependências antes de um deployment ou ao investigar uma suspeita de comprometimento da cadeia de fornecimento — não precisa de estar sempre ativo."
            ),
            LocalizedEntry(
                id: "feat_npm_sandboxed_install",
                title: "Instalação npm/pnpm em sandbox (roamswitch-npm, Pro)",
                summary: "Um wrapper de intervenção real — não apenas deteção — que confina apenas a execução dos scripts preinstall/install/postinstall/prepare dentro de uma sandbox sem acesso à rede (sandbox-exec), executando realmente a instalação em seu nome. Apenas Pro.",
                details: """
                • Como ativar: o botão «Instalar» em «📦 Verificação de CVE de pacotes» → «Instalação em sandbox (npm/pnpm) (Pro)» coloca o wrapper de linha de comandos `roamswitch-npm` em ~/Library/Application Support/RoamSwitch/bin/.
                • Fluxo em duas fases: ① A fase de download executa `npm install --ignore-scripts` / `pnpm install --ignore-scripts` normalmente, com acesso à rede. ② A fase de scripts executa `npm rebuild` / `pnpm rebuild` (além de `run prepare` se a raiz declarar um) sob um perfil sandbox-exec com `(deny network-outbound)`.
                • Mecanismo de sandbox: a versão Linux usa bwrap para restringir o sistema de ficheiros; como o macOS não tem uma tecnologia equivalente, é usado em vez disso um bloqueio de rede, verificado em hardware real (`(allow default)` + `(deny network-outbound)`). As leituras/escritas de ficheiros e o lançamento de processos-filho não são restringidos.
                • Alias de shell: podem ser acrescentadas duas linhas de alias que encaminham `npm`/`pnpm` através do wrapper ao ficheiro de configuração da sua shell (opcional, apenas acrescentado — o conteúdo existente não é alterado).
                • Pré-visualização: antes de executar, pode listar os scripts de ciclo de vida da pasta do projeto (o mesmo scanner usado em «Inventário de scripts de instalação»).
                • Se o sandbox-exec não estiver disponível ou falhar, nunca há um recuo silencioso para uma execução sem sandbox. O yarn não é suportado. Não existe ferramenta GTK/MCP — é uma ferramenta de linha de comandos usada a partir de um terminal.
                """,
                recommendation: "Para projetos que contenham pacotes pouco familiares, ou projetos obtidos de fontes externas, utilize `roamswitch-npm install` em vez de um npm/pnpm install habitual."
            ),
            LocalizedEntry(
                id: "feat_typosquat_guard",
                title: "Deteção de typosquatting (npm/pnpm package.json, Pro)",
                summary: "Compara os nomes de dependências do package.json com uma lista de pacotes npm populares por distância de edição (Levenshtein 1-2), assinalando possível typosquatting como expres→express ou loadash→lodash. A própria aplicação não estabelece qualquer ligação de rede para isto. Apenas Pro.",
                details: """
                • Âmbito: apenas as dependencies/devDependencies/optionalDependencies próprias do projeto no package.json (peerDependencies fica fora do âmbito). O node_modules (dependências transitivas já instaladas) também fica deliberadamente fora do âmbito — um erro de digitação é introduzido no momento em que uma pessoa adiciona uma dependência ao package.json.
                • Lógica de comparação: uma implementação DP padrão da distância de Levenshtein compara cada nome de dependência com uma lista de pacotes npm populares. Os pacotes com âmbito (`@scope/pkg`) são comparados pelo nome base (`pkg`). Os candidatos cuja diferença de comprimento seja superior a 2 são ignorados por um pré-filtro económico. O limiar é uma distância de edição até 2 para nomes populares com 8 ou mais carateres, apenas distância 1 para nomes mais curtos.
                • Como a lista se mantém atualizada: a lista de nomes de pacotes populares com que compara é distribuída pelo `PackageCveMapUpdater` através do mesmo manifesto diário, apenas de receção e assinado com Ed25519 dos mapas de CVE (uma semente incorporada em tempo de compilação mais uma substituição de dois níveis, preferindo a que tiver o `mapVersion` mais recente). A lista pode ser atualizada sem esperar por uma nova versão da aplicação.
                • Informação de referência, não um veredito — uma lista de permissões conhecida suprime alguns pacotes legítimos semelhantes (por exemplo, preact), mas não é exaustiva.
                • Como abrir: separador «📦 Verificação de CVE de pacotes» → «Deteção de typosquatting (Pro)», visando as mesmas pastas de projeto que o separador «Dependências». MCP: `run_typosquat_scan` (argumento `watchedFolders`, apenas Pro).
                """,
                recommendation: "Volte a verificar qualquer dependência assinalada com ⚠️ para um erro de digitação real — preste especial atenção a nomes de pacotes pouco familiares."
            ),
            LocalizedEntry(
                id: "feat_port_scan_guard",
                title: "Deteção de varrimento de portas de entrada (bloqueio automático, Pro)",
                summary: "Deteta e notifica sobre um IP de origem que contactou muitas portas diferentes (15 ou mais) num curto espaço de tempo (5 minutos) — a assinatura clássica de ferramentas de reconhecimento como nmap/masscan. Uma origem de varrimento detetada é automaticamente bloqueada durante 10 minutos por predefinição. Apenas Pro.",
                details: """
                • Como funciona: o helper privilegiado monitoriza os registos do pf (packet filter) através de `tcpdump -i pflog0` e assinala um IP de origem que alcança portas de destino diferentes suficientes numa janela curta. A deteção baseia-se exclusivamente em registos; nunca altera nem inspeciona o próprio tráfego. Corresponde ao `port_scan_detect.rs` da edição Linux (nftables `log` + `journalctl`).
                • Bloqueio automático: uma origem de varrimento detetada é adicionada a uma regra do pf e bloqueada durante 10 minutos por predefinição através do `PFRulesetCoordinator`. O bloqueio automático pode ser ativado/desativado independentemente da própria funcionalidade de deteção.
                • Notificações: é enviada uma notificação do macOS em cada deteção (e bloqueio), também registada na linha cronológica de incidentes unificada.
                • Como abrir: barra de menus → “Monitor de portas e dispositivos” → “🔍 Deteção de varrimento de portas de entrada (Pro)”. Tanto ativar como desativar passam por uma caixa de diálogo de confirmação. Desativado por predefinição.
                """,
                recommendation: "Não existe uma lista de permissões por IP, e um bloqueio é levantado automaticamente ao fim de 10 minutos. Se executar regularmente uma ferramenta de varrimento legítima em casa ou no trabalho (inventário de ativos, varrimento de vulnerabilidades, etc.), considere desativar o bloqueio automático (mantendo apenas a deteção/notificação) enquanto esta é executada, para evitar bloqueios repetidos por falsos positivos."
            ),
            LocalizedEntry(
                id: "feat_sensor_pairing",
                title: "Emparelhamento do RoamSwitch Sensor (código de emparelhamento, Pro)",
                summary: "Gere o emparelhamento de confiança mútua com um produto separado, o “RoamSwitch Sensor” (um hub de auditoria ativa dedicado), na mesma LAN. Utiliza um fluxo de emparelhamento ativo através de um código emitido pelo Sensor — sem deteção automática mDNS, uma vez que se assume que o Sensor opera com um IP fixo. Apenas Pro.",
                details: """
                • Como funciona: gera e mantém persistentemente o próprio par de chaves Ed25519 deste dispositivo. Para emparelhar, este dispositivo liga-se ao listener TCP do Sensor (porta 50543) com um código de emparelhamento de utilização única emitido pelo operador do Sensor (expira 10 minutos após a emissão), juntamente com o endereço/nome de anfitrião deste dispositivo. Se o código for válido, o Sensor adiciona a chave pública deste dispositivo à sua lista de confiança.
                • Solicitar uma auditoria: após o emparelhamento, “Solicitar auditoria ao Sensor” pede ao Sensor que execute uma auditoria ativa (verificação de acessibilidade). Como o Sensor gera os resultados de forma assíncrona, o próprio processo auxiliar privilegiado, sempre ativo, deste dispositivo consulta o resultado a cada 5 minutos, até 5 vezes. Os resultados obtidos também são guardados neste dispositivo e apresentados em “Resultados de auditoria” no ecrã de definições.
                • Como abrir: barra de menus → “Monitor de portas e dispositivos” → “🔍 Emparelhamento do RoamSwitch Sensor…”. Mostra a chave pública/endereço deste próprio dispositivo (com botão de copiar), os Sensors emparelhados (com botão Desemparelhar), um formulário para introduzir o código de emparelhamento e a lista de resultados de auditoria.
                • Utiliza o mesmo protocolo de controlo TCP da edição Linux (`roamswitch-core::sensor_pairing`) — porta 50543, JSON delimitado por quebras de linha, assinaturas Ed25519.
                """,
                recommendation: "Utilize apenas um código de emparelhamento efetivamente emitido a partir do ecrã de operador de um Sensor configurado por si. Se lhe pedirem para introduzir um código desconhecido, não emparelhe — consulte antes quem administra a rede."
            ),
            LocalizedEntry(
                id: "feat_security_health_checker",
                title: "Auditoria de segurança do Mac (18 pontos, pontuação e passos de correção)",
                summary: "Verifica 18 pontos em seis áreas (reforço do sistema, defesa de rede, autenticação e controlo de acesso, exposição de portas, proteção contra malware e defesa física de dispositivos) e mostra uma pontuação de 0 a 100, uma nota, e os passos para corrigir cada ponto não aprovado. Disponível na edição gratuita.",
                details: """
                • Reforço do sistema: 1. FileVault, 2. SIP (Proteção da Integridade do Sistema), 3. Gatekeeper, 4. atualizações de segurança automáticas, 5. Apple XProtect.
                • Defesa de rede: 6. firewall do macOS, 7. modo furtivo, 8. robustez da cifragem Wi-Fi, 9. monitor de falsificação de ARP, 10. fixação ARP da gateway.
                • Autenticação e controlo de acesso: 11. configuração de início de sessão SSH remoto (início de sessão root desativado, apenas autenticação por chave), 12. escalonamento de privilégios sudo (verificação `NOPASSWD`).
                • Serviços e exposição de portas: 13. portas expostas.
                • Proteção contra malware e descargas: 14. Proteção Web e E-mail, 15. Proteção contra ameaças DNS, 16. proteção contra phishing e links maliciosos (aviso de site fraudulento do Safari).
                • Portas físicas e dispositivos: 17. Proteção física da porta contra USB não autorizado / BadUSB, 18. proteção de ligação de acessórios do macOS (Apple Silicon).
                • Não aplicável: a firewall e o modo furtivo numa rede fidedigna, o SSH quando o início de sessão remoto está desativado, a verificação sudo antes de ligar o auxiliar, e a proteção de acessórios em Macs Intel são excluídos da pontuação.
                • Notas: 100 = S, 85-99 = A, 70-84 = B, abaixo de 70 = C. Também disponível através da ferramenta MCP `get_security_report`.
                """,
                recommendation: "Abra o relatório de auditoria regularmente, resolva os pontos marcados com ⚠️ seguindo os passos de correção, e mantenha pelo menos a nota A."
            ),
            LocalizedEntry(
                id: "feat_autonomous_sentinel",
                title: "Patrulha autónoma em segundo plano, atualização das definições do ClamAV e verificações agendadas",
                summary: "A cada 4 horas, atualiza em segundo plano a auditoria de segurança, as portas, os dispositivos USB e o estado do XProtect (todas as edições). A Pro avisa ainda em caso de queda de pontuação, atualiza automaticamente as definições do ClamAV, e executa uma verificação antivírus diária.",
                details: """
                • Auditoria periódica (todas as edições): cerca de 30 segundos após o arranque e depois a cada 4 horas, para que os resultados se mantenham atualizados mesmo que permaneça horas na mesma rede.
                • Aviso de queda de pontuação (Pro): notifica quando a pontuação desce abaixo de 80 ou 4 ou mais pontos falham.
                • Definições do ClamAV (Pro): executa `freshclam` em silêncio.
                • Verificação agendada (Pro): uma vez por dia, analisa `~/Downloads`, `~/Desktop` e `~/Library/LaunchAgents` com o ClamAV. As ameaças são colocadas em quarentena automaticamente com um alerta urgente; um resultado limpo gera apenas um aviso discreto de conclusão. Se apenas for encontrada a assinatura de teste EICAR, nada é mostrado, sendo apenas registado no histórico de notificações.
                """,
                recommendation: "Na Pro, instale o ClamAV para que as atualizações das definições e as verificações agendadas sejam executadas automaticamente."
            ),
            LocalizedEntry(
                id: "feat_simulation_self_test",
                title: "Ferramentas de simulação (auto-teste)",
                summary: "Verifique em segurança se a defesa contra ransomware, o Air-Gap de deteção de malware e a deteção de riscos do Docker funcionam, sem qualquer ataque real nem danos em ficheiros.",
                details: """
                • Localização: na parte inferior de «Proteção contra malware (XProtect e ClamAV)».
                • 🚨 Simulação de defesa contra ransomware (Modo de teste)…: executa os mesmos passos de uma tentativa de cifragem detetada para verificar o Air-Gap e a janela de emergência. Nenhum ficheiro é danificado.
                • 🚨 Simulação de Air-Gap por deteção de malware (teste)…: executa os mesmos passos de uma deteção real do XProtect para verificar a contenção e a janela de emergência. O evento é identificado como simulação.
                • ⚠️ Simulação de deteção de riscos do Docker (Modo de teste)…: verifica se a notificação de contentor privilegiado chega. O Docker não é tocado.
                • Nota: os testes de Air-Gap cortam mesmo a rede temporariamente. Liberte a partir da janela de emergência (também se restaura sozinha em 10 minutos).
                • Para testar a proteção de descargas, pode usar um ficheiro de teste EICAR inofensivo (sem aviso; é registado no histórico de notificações).
                """,
                recommendation: "Execute uma simulação uma vez depois de ativar a Pro ou de alterar definições para confirmar que as notificações e o Air-Gap se comportam como esperado."
            ),
            LocalizedEntry(
                id: "feat_privileged_helper",
                title: "Ferramenta auxiliar privilegiada (RoamSwitchHelper, XPC)",
                summary: "Apenas as operações que necessitam de permissões root (firewall PF, serviços de partilha, DNS, Air-Gap, etc.) são realizadas por um auxiliar LaunchDaemon com privilégios separados, via XPC.",
                details: """
                • Separação de privilégios: a app principal é executada com permissões de utilizador normais e delega apenas as alterações de regras pf, o controlo de daemons de partilha, as definições DNS, a fixação ARP, o cálculo de hash de ficheiros críticos e tarefas semelhantes ao `RoamSwitchHelper`.
                • Registo: registado através do SMAppService do macOS como um LaunchDaemon incluído na app. A primeira utilização requer aprovação em Definições do Sistema → Geral → Itens de início e extensões. Não pode ser registado se a app não estiver na pasta Aplicações (faq_install_location).
                • Daemons associados: também são registados LaunchDaemons auxiliares para a rede de segurança do Air-Gap (libertação automática ao fim de 10 minutos) e a porta de arranque (até 90 segundos).
                • Verificação: as assinaturas de código (Team ID) são verificadas nas ligações XPC, rejeitando chamadas de processos não autorizados.
                • Nova aprovação após uma atualização: a app tenta mudar automaticamente para o novo auxiliar, mas o macOS pode ainda assim deixá-lo pendente de aprovação. Nesse caso, o ícone da barra de menus muda para um aviso com «⚠️ É necessária nova aprovação após a atualização», e também é enviada uma notificação.
                """,
                recommendation: "Aprove o auxiliar quando lhe for pedido no primeiro arranque. Se não estiver aprovado, o menu mostra «⚠️ Aprovar o auxiliar…». Se este aviso ou notificação aparecer após uma atualização, os mesmos passos (Definições do Sistema > Geral > Itens de início de sessão e extensões) permitem aprová-lo novamente."
            ),
            LocalizedEntry(
                id: "feat_mcp_server",
                title: "Integração do servidor MCP (acesso só de leitura para assistentes de IA)",
                summary: "O RoamSwitch.app inclui um servidor MCP (Model Context Protocol) só de leitura, para que assistentes de IA como o Claude possam perguntar pelo estado de segurança do seu Mac. Não existe nenhuma ferramenta que altere definições ou bloqueie o que quer que seja.",
                details: """
                • Transporte: apenas stdio local. Binário: `/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`.
                • Principais ferramentas: `get_security_report` (auditoria de segurança), `get_exposed_ports`, `get_guard_status`, `audit_url_safety`, `audit_secrets`, `audit_security_logs`, `get_quarantine_status`, `get_notification_history`, `get_canary_status`, `get_port_anomaly_incidents`, `get_runtime_threat_status`, `get_incident_timeline` (linha temporal de incidentes de contenção), `get_network_history` (aprendizagem do histórico de rede), `run_package_cve_scan`, `run_package_cve_scan_languages`, `run_active_vuln_scan` (a única ferramenta que envia tráfego, sondas não destrutivas apenas para 127.0.0.1), e `get_app_help` (esta base de conhecimento).
                • Recursos: `roamswitch://docs/features`, `roamswitch://docs/alerts-and-messages`, `roamswitch://docs/settings-guide`, `roamswitch://docs/troubleshooting`.
                • Idioma: as respostas seguem a definição de idioma da app. `get_app_help` aceita um argumento `language` (ja / en / zh-Hans / zh-Hant / ko / de / fr / es / it / pt-PT).
                • Segurança: por ser só de leitura, mesmo uma IA manipulada por injeção de comandos não pode alterar o nível de proteção nem isolar portas.
                """,
                recommendation: "Para a configuração, ver faq_mcp_setup. Pode fazer perguntas em linguagem corrente, como «O meu Mac está seguro neste momento?» ou «O que significa esta notificação?»"
            ),
            LocalizedEntry(
                id: "feat_license_pro_tier",
                title: "Licença Pro vitalícia (compra única, até 2 Macs)",
                summary: "A Pro é uma licença vitalícia de compra única (2.980 ¥ / 19,99 $) utilizável em até 2 Macs. O token de licença assinado com Ed25519 é verificado no dispositivo, pelo que a Pro continua a funcionar offline após a ativação.",
                details: """
                • Funcionalidades Pro: as defesas automáticas marcadas com (Pro) no menu (deteção de ransomware através de ficheiros-isco, corte ligado ao XProtect, bloqueio automático de porta desconhecida e isolamento de servidor de desenvolvimento, bloqueio automático de falsificação de ARP, fixação ARP/NDP da gateway, túnel VPN, proteções BadUSB e de armazenamento USB, Proteção Web e E-mail, Proteção contra ameaças DNS, Proteção de links, desativação automática do Bluetooth, defesa ClickFix, monitorização de registos de início automático, deteção de riscos do Docker, monitorização de adulteração de ficheiros críticos, auditoria automática de registos), notificações de ameaça em tempo real, avisos de patrulha e verificações agendadas, exportação CSV de registos, e mais.
                • Tipos de licença: Pro vitalícia (2 Macs) e Team vitalícia (5 Macs).
                • Ativação: introduza a sua chave de licença (ROAM-XXXX-…) em «💎 Ativar / Comprar Pro…». O token assinado emitido pelo servidor é verificado com a chave pública incluída na app e guardado no porta-chaves.
                • Desativação: a partir da janela de licença. Remove a licença deste Mac e liberta o lugar no servidor (a desativação local acontece sempre, mesmo que o pedido de rede falhe).
                • No termo: as proteções exclusivas da Pro são desativadas automaticamente, e o túnel VPN e o isolamento de portas são libertados.
                """,
                recommendation: "Considere a Pro se quiser contenção automática, defesa em tempo real e avisos de patrulha. Ao substituir um Mac, desative-a primeiro no antigo antes de a ativar no novo."
            ),
        ]
    }

    // MARK: - Alerts: network, devices, links

    private static func alertsPtPTNetwork() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "alert_arp_spoofing",
                title: "⚠️ Alerta de falsificação ARP (MITM)",
                summary: "Aparece quando há indícios de que um dispositivo na sua rede se está a fazer passar pelo router (gateway) para escutar ou adulterar o seu tráfego.",
                details: """
                • Causa: um atacante envia respostas ARP falsificadas para que o seu tráfego passe por ele (ataque intermediário). É detetado quando o IP da gateway se mantém igual mas o seu endereço MAC muda subitamente. Um reinício do router ou uma transição de Wi-Fi em malha também o podem causar.
                • Defesa automática: com o Bloqueio máximo e «Bloqueio automático ao detetar ARP spoofing (personificação na rede) (Pro)» ativo, contenção Air-Gap imediata. Nos outros níveis, apenas notificação, e o menu mostra «Falsificação ARP detetada — cortar toda a rede agora».
                """,
                recommendation: """
                1. Pare imediatamente de introduzir palavras-passe, fazer pagamentos ou transmitir tráfego de trabalho nesta rede.
                2. Em Wi-Fi público ou uma rede desconhecida, escolha «cortar toda a rede agora» no menu ou desligue o Wi-Fi.
                3. Se precisar de acesso à internet, mude para uma ligação segura, como a partilha de ligação ou o túnel VPN.
                4. Continue a usar a rede apenas se tiver a certeza de que é um falso positivo, por exemplo logo após reiniciar o router de casa.
                """
            ),
            LocalizedEntry(
                id: "alert_evil_twin_ssid",
                title: "⚠️ Possível rede Wi-Fi gémea maligna detetada",
                summary: "Aparece quando o nome (SSID) do Wi-Fi a que se ligou se assemelha muito a uma rede já usada anteriormente. Pode tratar-se de um ponto de acesso falso malicioso (gémeo maligno).",
                details: """
                • Causa: um atacante configura um ponto de acesso falso cujo nome difere do legítimo apenas por um ou dois carateres para atrair pessoas. A aprendizagem do histórico de rede (feat_network_history_guard) avalia isto com base na distância de edição em relação aos nomes aprendidos e no hardware de gateway diferente.
                • Controlo de falsos positivos: nomes curtos e SSID adicionais difundidas pelo mesmo hardware de gateway não o acionam.
                • Defesa automática: apenas notificação. Sendo uma rede não registada, aplica-se o nível de Proteção predefinida em viagem.
                """,
                recommendation: """
                1. Não inicie sessão nem introduza informações pessoais neste Wi-Fi.
                2. Confirme o nome oficial da rede (avisos na loja ou no escritório) e desligue-se se não corresponder.
                3. Se precisar de continuar a usá-la, ligue o túnel VPN.
                """
            ),
            LocalizedEntry(
                id: "alert_unencrypted_wifi",
                title: "⚠️ Ligado a um Wi-Fi não cifrado",
                summary: "Aparece quando entra numa rede Wi-Fi aberta sem palavra-passe nem cifragem (WPA2 / WPA3), ou numa rede WEP antiga.",
                details: """
                • Causa: a ligação sem fios não está cifrada, pelo que qualquer pessoa nas proximidades pode intercetar o tráfego.
                • Defesa automática: se a rede não estiver registada, a Proteção predefinida em viagem (inicialmente Bloqueio máximo) bloqueia as ligações de entrada e os serviços de partilha.
                """,
                recommendation: """
                1. Se possível, ligue o túnel VPN ou mude para uma ligação fiável como a partilha de ligação.
                2. Evite iniciar sessão ou introduzir informações pessoais em sites que não sejam HTTPS.
                3. Confirme no menu que o nível de proteção é Bloqueio máximo.
                """
            ),
            LocalizedEntry(
                id: "alert_port_anomaly",
                title: "🚨 Porta de escuta desconhecida bloqueada automaticamente",
                summary: "Aparece quando um programa que antes não estava exposto começou a expor uma porta à LAN em 0.0.0.0 e o acesso a partir do exterior foi bloqueado automaticamente (é mostrado «Porta de escuta desconhecida detetada (bloqueio falhado)» se o bloqueio não for bem-sucedido).",
                details: """
                • Causa: o arranque de um servidor de desenvolvimento (Next.js, Vite, Python, Docker), uma app de receção LAN como o LocalSend ou o Syncthing a arrancar pela primeira vez, ou uma backdoor ou app maliciosa a começar a escutar.
                • Defesa automática: o pf bloqueia apenas o acesso externo (o próprio Mac e o localhost podem continuar a usá-la). Os daemons do sistema do macOS são excluídos.
                """,
                recommendation: """
                1. Verifique se reconhece o nome do processo, o PID e a porta mostrados na notificação (também visíveis em Portas expostas).
                2. Se for o seu próprio servidor ou uma app de receção LAN, permita-o com o botão «Permitir» da notificação ou a partir do ecrã de auditoria de portas. Ficará permitido de forma permanente a partir daí.
                3. Para servidores de desenvolvimento, reiniciar vinculado a `127.0.0.1` é a opção mais segura.
                4. Se não o reconhecer, mantenha-o bloqueado, feche o processo e execute a auditoria de segurança e uma verificação antivírus.
                """
            ),
            LocalizedEntry(
                id: "alert_exposed_database",
                title: "🚨 Serviço de base de dados não autenticado exposto externamente",
                summary: "Aparece quando um serviço frequentemente sem autenticação por predefinição (Redis, MongoDB, Memcached, Elasticsearch) fica exposto à LAN sem proteção de firewall.",
                details: """
                • Causa: um serviço de base de dados ou de backend foi iniciado em 0.0.0.0 enquanto o nível de proteção atual permite ligações de entrada. Qualquer pessoa na mesma rede poderá conseguir ler ou escrever os dados.
                • Defesa automática: apenas notificação (Pro), não repetida para a mesma porta.
                """,
                recommendation: """
                1. Mude o endereço de escuta do serviço para `127.0.0.1` ou ative a autenticação.
                2. Se não conseguir corrigir de imediato, abra a porta em Portas expostas e escolha «Isolar porta».
                3. Use o Bloqueio máximo em redes públicas.
                """
            ),
            LocalizedEntry(
                id: "alert_unapproved_keyboard",
                title: "⚠️ Teclado não autorizado / ligação BadUSB detetada",
                summary: "A notificação e a janela de aprovação que aparecem quando um novo teclado USB fora da lista de permissões (ou um dispositivo que se faz passar por um, como um cabo modificado) é ligado e as suas teclas são bloqueadas até ser aprovado.",
                details: """
                • Causa: a ligação de um novo teclado externo ou de uma base de ancoragem, ou de um dispositivo de injeção de teclas como um Rubber Ducky.
                • Defesa automática: apenas as teclas desse dispositivo são bloqueadas (os outros teclados continuam a funcionar). A janela «⚠️ Dispositivo USB / teclado desconhecido detetado» pede aprovação.
                """,
                recommendation: """
                1. Se for um teclado de confiança que ligou você mesmo, clique em «Confiar e permitir». Será adicionado à lista de permissões e a entrada será ativada.
                2. Se não o reconhecer, ou surgir sem ter ligado nada, clique em «Rejeitar e manter bloqueado» e desligue o dispositivo.
                """
            ),
            LocalizedEntry(
                id: "alert_scripted_keyboard",
                title: "🚨 Este teclado apresenta sinais de digitação automatizada (guionizada)",
                summary: "Aparece quando um teclado em espera de aprovação envia teclas a intervalos demasiado rápidos e demasiado uniformes para um humano. É muito provável uma injeção automatizada de comandos (ataque BadUSB).",
                details: """
                • Causa: um Rubber Ducky, Flipper Zero, Arduino/Digispark ou semelhante tentou escrever comandos pré-carregados a alta velocidade. Determinado pela análise do ritmo de digitação: após pelo menos 5 intervalos, uma média de 12 ms ou menos, ou de 45 ms ou menos com uma uniformidade muito elevada.
                • Defesa automática: as teclas do dispositivo já estavam bloqueadas antes da aprovação e nunca chegaram ao Mac. Este aviso apenas acrescenta provas para a sua decisão.
                """,
                recommendation: """
                1. Escolha sempre «Rejeitar e manter bloqueado» na janela de aprovação.
                2. Desligue o dispositivo de imediato e verifique a sua proveniência (uma pen USB encontrada, um cabo oferecido, etc.).
                3. Como precaução, execute a auditoria de segurança e reveja os registos de início automático.
                """
            ),
            LocalizedEntry(
                id: "alert_untrusted_usb",
                title: "🔒 Armazenamento USB montado só de leitura / 🔌 Armazenamento USB não autorizado bloqueado automaticamente",
                summary: "Aparece quando uma unidade USB ou disco externo fora da lista de permissões é ligado e foi montado só de leitura à espera da sua aprovação, ou foi ejetado.",
                details: """
                • Causa: foi ligado um dispositivo de armazenamento não registado. Isto evita o roubo de dados e a introdução de ficheiros maliciosos.
                • Defesa automática: voltado a montar só de leitura com a caixa de diálogo «Permitir o armazenamento USB «…»?». Escolher Ejetar ejeta-o e envia «Armazenamento USB não autorizado bloqueado automaticamente».
                """,
                recommendation: """
                1. Se for o seu dispositivo, escolha «Permitir leitura/escrita» ou «Permitir só de leitura». Será adicionado à lista de permissões e aplicado automaticamente da próxima vez.
                2. Se não o reconhecer, escolha «Ejetar».
                3. Pode alterar a lista de permissões mais tarde em «Definições de proteção USB / BadUSB…».
                """
            ),
            LocalizedEntry(
                id: "alert_malware_usb",
                title: "🚨 Malware detetado em armazenamento USB",
                summary: "Aparece quando a verificação do ClamAV executada antes de um dispositivo de armazenamento USB ser ligado em leitura/escrita encontra ficheiros infetados.",
                details: """
                • Causa: existem ficheiros infetados na unidade USB.
                • Defesa automática: o volume é ejetado de imediato para que o Mac não fique infetado.
                """,
                recommendation: """
                1. Formate ou desinfete a unidade num ambiente seguro separado antes de a voltar a usar.
                2. Execute uma verificação rápida ou uma verificação de pasta com o ClamAV para garantir que o próprio Mac não está infetado.
                """
            ),
            LocalizedEntry(
                id: "alert_link_guard_blocked",
                title: "🛑 Proteção de links: ligação bloqueada",
                summary: "Aparece quando a Proteção de links bloqueou automaticamente uma ligação a um site suspeito de burla ou phishing (presente na lista de ameaças, ou homógrafo de marca).",
                details: """
                • Causa: um link de e-mail ou de redes sociais, um anúncio, ou uma app tentou ligar-se a um domínio de burla conhecido.
                • Defesa automática: a extensão do sistema descarta a ligação, ou a alternativa via hosts resolve o domínio para 0.0.0.0, independentemente do navegador ou da app.
                """,
                recommendation: """
                1. Se não era esperado, não é necessário mais nada; não introduza informações nessa página.
                2. Se um site legítimo de que precisa foi bloqueado por engano, use «Permitir uma vez (5 min)» na notificação ou adicione-o à lista de permissões.
                """
            ),
            LocalizedEntry(
                id: "alert_link_guard_warn_hold",
                title: "⚠️ Proteção de links: ligação em espera",
                summary: "No modo Aviso, a notificação e o painel em primeiro plano que aparecem quando uma ligação a um site suspeito de personificação de marca ou burla foi pausada enquanto decide se a permite.",
                details: """
                • Causa: uma ligação a um domínio que aciona um aviso (personificação de subdomínio, TLD de alto risco, etc.).
                • Defesa automática: a ligação é pausada à espera da sua resposta. Sem resposta em cerca de 8 segundos, é bloqueada (falha de forma fechada). Esse resultado não é guardado em cache, pelo que a próxima visita voltará a perguntar. As respostas que der são memorizadas.
                """,
                recommendation: """
                1. Se a abriu de propósito e confia no site, escolha «Permitir».
                2. Se não a reconhecer ou não tiver a certeza, escolha «Bloquear» ou simplesmente aguarde (será bloqueada automaticamente).
                3. Se foi bloqueada por engano, recarregue a página para voltar a ser perguntado.
                """
            ),
            LocalizedEntry(
                id: "alert_dangerous_url",
                title: "🛑 Link perigoso / phishing suspeito (Verificação de segurança de links)",
                summary: "Aparece quando a Verificação de segurança de links (ou `audit_url_safety`) considera um URL perigoso devido a homógrafos, um subdomínio falsificado, um TLD de alto risco, e semelhantes.",
                details: """
                • Verificações: carateres homógrafos (Punycode), subdomínios que imitam grandes empresas, TLD comuns em phishing, HTTP não cifrado, endereços IP em bruto, e mais.
                • Pontuação: abaixo de 50 é perigoso; entre 50 e 79 é cautela.
                """,
                recommendation: """
                1. Não abra o link.
                2. Elimine a mensagem e comunique-a à sua equipa de segurança, se aplicável.
                """
            ),
            LocalizedEntry(
                id: "alert_helper_disconnected",
                title: "⚠️ Auxiliar não ligado",
                summary: "Aparece quando não é possível estabelecer a comunicação XPC com a ferramenta auxiliar privilegiada (RoamSwitchHelper).",
                details: """
                • Causa: a execução em segundo plano não está aprovada em Itens de início e extensões, o auxiliar parou após uma atualização do macOS, ou a app está fora da pasta Aplicações (em Transferências ou dentro da imagem de disco).
                • Impacto: operações que necessitam de permissões root (mudar o nível de proteção, contenção Air-Gap, definições DNS, monitorização de ficheiros críticos, etc.) não podem ser executadas.
                """,
                recommendation: """
                1. Escolha «⚠️ Aprovar o auxiliar…» no menu para abrir os passos de aprovação.
                2. Em Definições do Sistema → Geral → Itens de início e extensões, ative o RoamSwitchHelper em Permitir em segundo plano.
                3. Assegure-se de que o RoamSwitch está na pasta Aplicações.
                4. Se isso não resolver o problema, siga faq_helper_troubleshooting.
                """
            ),
            LocalizedEntry(
                id: "alert_score_drop",
                title: "⚠️ Aviso de degradação da segurança do Mac",
                summary: "Enviado pela patrulha autónoma quando a pontuação de segurança desce abaixo de 80 ou 4 ou mais pontos falham (Pro).",
                details: """
                • Causa: uma alteração nas definições ou no ambiente, como desativar o FileVault ou a firewall, uma porta perigosa exposta, ou uma proteção parada.
                • Critérios: pontuação abaixo de 80, ou 4 ou mais pontos em falha.
                """,
                recommendation: """
                1. Abra o relatório de auditoria a partir do menu (ou use a ferramenta MCP `get_security_report`).
                2. Resolva os pontos marcados com ⚠️ seguindo os passos de correção mostrados.
                """
            ),
        ]
    }

    // MARK: - Alerts: malware, containment, audit

    private static func alertsPtPTMalware() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "alert_quarantined_download",
                title: "🚨 Ficheiro descarregado perigoso colocado em quarentena",
                summary: "Aparece quando um ficheiro guardado a partir de um navegador, Mail ou uma app de chat continha uma ameaça e foi movido para o cofre de quarentena (é mostrado «quarentena falhada» se a movimentação não for bem-sucedida).",
                details: """
                • Causa: o ficheiro descarregado continha malware, um trojan, um reverse shell ou semelhante.
                • Defesa automática: movido para `~/Library/Application Support/RoamSwitch/Quarantine/` para que não possa ser executado. Se a verificação de assinatura estática o assinalou mas o ClamAV não, a notificação menciona um possível falso positivo.
                """,
                recommendation: """
                1. Se a quarentena for bem-sucedida, o ficheiro não pode ser executado.
                2. Abra «📦 Gerir ficheiros em quarentena…» e escolha «Eliminar permanentemente» se não o reconhecer.
                3. Use «Restaurar» ou «Excluir e restaurar» apenas para falsos positivos certos.
                4. Se a quarentena falhar, elimine manualmente o ficheiro no caminho indicado na notificação.
                """
            ),
            LocalizedEntry(
                id: "alert_eicar_test_signature",
                title: "🧪 Assinatura de teste EICAR detetada (inofensiva) — registada apenas no histórico de notificações",
                summary: "Explica como é tratado o ficheiro de teste EICAR inofensivo usado para verificar software antivírus. Não é uma ameaça real, pelo que não aparece nenhum aviso e nada é colocado em quarentena nem bloqueado; é apenas registado no histórico de notificações.",
                details: """
                • Aplica-se a: Proteção Web e E-mail, verificações rápidas/de pasta do ClamAV, e a verificação agendada da patrulha da mesma forma.
                • Comportamento: o ficheiro permanece onde está. «Assinatura de teste EICAR detetada (inofensiva)» é registada em «🔔 Histórico de notificações…».
                • Motivo: avisos para itens que não são ameaças enterrariam os alertas verdadeiramente importantes.
                """,
                recommendation: """
                1. Não é necessária nenhuma ação. Se colocou o ficheiro para fins de teste, elimine-o depois de confirmar o resultado.
                2. Pode confirmar que a verificação funciona verificando este registo no histórico de notificações.
                """
            ),
            LocalizedEntry(
                id: "alert_pickle_model",
                title: "⚠️ Deteção de descarga de um modelo de IA em formato Pickle",
                summary: "Aparece quando é descarregado um ficheiro de modelo de IA `.pkl` / `.pickle` / `.pt`. O formato Pickle pode executar código arbitrário apenas por ser carregado.",
                details: """
                • Causa: um ficheiro de modelo foi guardado do Hugging Face, Civitai ou semelhante.
                • Defesa automática: apenas um aviso (o ficheiro não é colocado em quarentena).
                """,
                recommendation: """
                1. Não carregue modelos a menos que provenham de uma fonte oficial de confiança.
                2. Quando possível, use o mesmo modelo em formato `.safetensors` ou `.gguf`.
                """
            ),
            LocalizedEntry(
                id: "alert_ransomware_activity",
                title: "🚨 DEFESA AUTOMÁTICA CRÍTICA: atividade de ransomware bloqueada",
                summary: "A notificação urgente e a janela de emergência que aparecem quando um ficheiro-isco (canário) foi modificado, eliminado ou renomeado e foram acionados a contenção Air-Gap, a paragem da partilha e a pausa do processo suspeito.",
                details: """
                • Causa: um processo como um ransomware a tentar cifrar ou destruir ficheiros nas suas pastas de utilizador (ou a execução de uma simulação).
                • Defesa automática: todo o tráfego cortado mais o Wi-Fi desligado, o SMB / SSH / Partilha de ecrã parados, e o processo suspeito colocado em pausa (SIGSTOP). A janela de emergência mostra se o corte foi bem-sucedido, o processo suspeito, e os ficheiros que possam ter sido afetados.
                """,
                recommendation: """
                1. Guarde o trabalho em curso e feche todas as apps suspeitas.
                2. No Monitor de Atividade, procure processos com utilização de CPU ou escritas em disco disparadas e force o fecho dos que não reconhecer.
                3. Verifique os ficheiros que possam ter sido afetados e as suas cópias de segurança (Time Machine, etc.).
                4. Assim que estiver seguro, liberte a contenção a partir da janela de emergência (a rede é restaurada, o processo em pausa é retomado, e os ficheiros-isco são regenerados).
                """
            ),
            LocalizedEntry(
                id: "alert_runtime_threat_airgap",
                title: "🚨 O XProtect detetou malware — rede cortada automaticamente",
                summary: "A janela de emergência e a notificação que aparecem quando o XProtect / XProtect Remediator da Apple condenou um ficheiro como malware e a desconexão automática ligada ao XProtect acionou a contenção Air-Gap.",
                details: """
                • Causa: o motor anti-malware da Apple determinou que um ficheiro que descarregou ou executou era malicioso.
                • Defesa automática: todo o tráfego cortado mais o Wi-Fi desligado, restaurado automaticamente no máximo em 10 minutos se não for libertado. São registados o processo detetor, a categoria e a mensagem de deteção da Apple.
                """,
                recommendation: """
                1. Identifique os ficheiros ou apps que acabou de descarregar ou executar e elimine-os.
                2. Execute uma verificação do ClamAV e a auditoria de segurança, e verifique os registos de início automático (LaunchAgents) à procura de algo suspeito.
                3. Assim que estiver seguro, liberte a contenção a partir da janela de emergência.
                4. O estado também está disponível através da ferramenta MCP `get_runtime_threat_status`.
                """
            ),
            LocalizedEntry(
                id: "alert_gatekeeper_block",
                title: "🛡️ O Gatekeeper impediu a execução de uma app não assinada",
                summary: "Uma notificação de que o Gatekeeper do macOS impediu o arranque de uma app sem assinatura nem notarização. Sem corte automático.",
                details: """
                • Causa: tentou abrir uma app não assinada proveniente da internet ou a sua própria compilação de desenvolvimento.
                • Defesa automática: nenhuma (apenas notificação). A desconexão ligada ao XProtect só se aciona quando o XProtect deteta realmente malware.
                """,
                recommendation: """
                1. Se a reconhecer (por exemplo a sua própria compilação), não é necessária nenhuma ação.
                2. Caso contrário, verifique a autoridade de assinatura com «Verificar segurança de ficheiro/app…» e elimine-a se suspeitar.
                """
            ),
            LocalizedEntry(
                id: "alert_clickfix_command",
                title: "🚨 Execução de comando suspeito detetada / ⚠️ Comando suspeito detetado na área de transferência",
                summary: "Aparece quando um comando correspondente à técnica ClickFix foi executado no Terminal (detetado a partir do histórico da shell) ou copiado para a área de transferência.",
                details: """
                • Causa: foi levado a uma falsa verificação ou a uma falsa página de erro que dizia «execute este comando para resolver». São assinaladas as frases de reverse shell e o conteúdo descodificado em Base64 canalizado diretamente para uma shell ou para o osascript.
                • Defesa automática (executado no Terminal, Pro, desligada por predefinição): contenção Air-Gap (o Wi-Fi não é desligado), restaurada automaticamente no máximo em 10 minutos.
                • Defesa automática (copiado, ativa por predefinição): a área de transferência é limpa de imediato.
                """,
                recommendation: """
                1. Se apenas o copiou, feche essa página web e não cole nem execute nada.
                2. Se o executou, verifique se o seu porta-chaves, as palavras-passe guardadas no navegador e as suas carteiras de criptomoedas estão seguros, e mude palavras-passe importantes a partir de outro dispositivo de confiança.
                3. Verifique os registos de início automático (LaunchAgents / Daemons) à procura de algo suspeito e execute uma verificação do ClamAV.
                """
            ),
            LocalizedEntry(
                id: "alert_new_persistence_item",
                title: "🚨 Novo registo de início automático detetado",
                summary: "Aparece quando um novo LaunchAgent / LaunchDaemon foi registado e considerado suspeito (inicia diretamente um interpretador de scripts, tem uma assinatura inválida, etc.).",
                details: """
                • Causa: malware como um ladrão de informação a registar-se para sobreviver a reinícios, ou um instalador de app a adicionar um.
                • Defesa automática: apenas notificação (o próprio registo não pode ser impedido). A notificação mostra o caminho do plist e o motivo.
                """,
                recommendation: """
                1. Verifique se acabou de instalar você mesmo uma app. Nesse caso, não é necessária nenhuma ação.
                2. Caso contrário, elimine o plist mostrado na notificação e o script ou app que este inicia.
                3. Reinicie o Mac depois e execute uma verificação do ClamAV.
                """
            ),
            LocalizedEntry(
                id: "alert_docker_risk",
                title: "⚠️ Configuração de contentor Docker de risco detetada",
                summary: "Avisa-o de que acabou de arrancar um contentor com `--privileged` ou com `docker.sock` montado.",
                details: """
                • Causa: contentores privilegiados e montagens do socket do Docker permitem que um contentor controle o anfitrião, criando um risco de fuga do contentor.
                • Defesa automática: nenhuma (apenas notificação).
                """,
                recommendation: """
                1. Se for intencional (por exemplo, um agente de monitorização), não é necessária nenhuma ação.
                2. Caso contrário, verifique o contentor com `docker ps` e `docker inspect` e pare-o.
                """
            ),
            LocalizedEntry(
                id: "alert_critical_file_tampering",
                title: "🚨 Adulteração de ficheiro crítico do sistema detetada",
                summary: "Aparece quando é detetada uma alteração, eliminação ou novo ficheiro entre ficheiros críticos como sudoers, a configuração SSH, PAM, hosts, ou o authorized_keys do root.",
                details: """
                • Causa: uma alteração de configuração feita por um administrador (`sudo visudo`, edição das definições SSH), uma alteração feita por software, ou um atacante a escalar privilégios ou a instalar uma backdoor.
                • Defesa automática: apenas notificação. O novo estado nunca é aceite automaticamente como legítimo.
                • Relacionado: «A deteção de adulteração de ficheiros críticos não está a funcionar» significa que as verificações têm falhado repetidamente porque não foi possível contactar o auxiliar privilegiado.
                """,
                recommendation: """
                1. Verifique se foi você ou um administrador a alterar os ficheiros mostrados na notificação.
                2. Caso contrário, procure entradas `NOPASSWD` em `/etc/sudoers`, chaves desconhecidas em `authorized_keys` e semelhantes, e remova-as.
                3. Mude a palavra-passe de administrador e execute a auditoria de segurança.
                """
            ),
            LocalizedEntry(
                id: "alert_log_audit_anomaly",
                title: "🔔 Auditoria de registos: padrões anómalos detetados",
                summary: "Enviada pela auditoria automática de registos quando encontra padrões de registo nunca vistos neste Mac ([novo]) ou registos muito mais frequentes do que o habitual ([pico z=…]).",
                details: """
                • Causa: normalmente alterações esperadas devido à ligação de um novo dispositivo ou a atualizações de apps ou do macOS, mas por vezes tentativas de início de sessão suspeitas ou atividade de processos desconhecida.
                • Conteúdo: a repartição da contagem, até 3 linhas de registo reais, o progresso da aprendizagem (por exemplo, aprendizagem de frequência em curso: 2/3 observações), e uma explicação em linguagem simples.
                • Defesa automática: nenhuma (apenas notificação).
                """,
                recommendation: """
                1. Se houver apenas novos padrões e nenhuma app ou endereço IP desconhecido, não é necessária nenhuma ação.
                2. Se um pico de frequência coincidir com algo que não fez, abra «📜 Auditoria de registos de segurança do Mac…» para mais detalhes.
                3. Em caso de dúvida, use «Copiar materiais para consulta com IA» para perguntar a um assistente de IA.
                """
            ),
            LocalizedEntry(
                id: "alert_secret_in_clipboard",
                title: "🔑 Chave confidencial detetada na área de transferência",
                summary: "Informa-o de que uma chave de API ou uma chave privada (OpenAI, Anthropic, GitHub, AWS, etc.) se encontra na área de transferência.",
                details: """
                • Causa: copiou uma chave de API, um token ou uma chave privada.
                • Defesa automática: apenas notificação (a área de transferência não é limpa).
                """,
                recommendation: """
                1. Tenha cuidado para não a colar por engano num site ou num chat de IA.
                2. Quando terminar, copie outro texto para a substituir.
                3. Se a partilhou por engano, revogue-a e renove-a de imediato na consola do serviço.
                """
            ),
            LocalizedEntry(
                id: "alert_airgap_failed",
                title: "🚨 Falha ao cortar a rede automaticamente",
                summary: "Um aviso urgente que aparece quando foi tentado um corte de emergência (ransomware, falsificação de ARP, deteção do XProtect, ClickFix, etc.) mas não foi possível aplicar o bloqueio completo do pf.",
                details: """
                • Causa: o auxiliar privilegiado não respondeu (não aprovado, parado, ou tempo esgotado). Aparece após 3 tentativas falhadas.
                • Estado atual: o tráfego de entrada pode estar bloqueado pela firewall de aplicações, mas o tráfego de saída não foi interrompido.
                """,
                recommendation: """
                1. Desligue o Wi-Fi de imediato ou desligue o cabo de rede.
                2. Trate da ameaça (feche processos, execute verificações).
                3. Depois, verifique o estado do auxiliar (faq_helper_troubleshooting).
                """
            ),
        ]
    }

    // MARK: - Settings

    private static func settingsPtPT() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "set_trusted_networks",
                title: "Redes registadas e níveis de proteção por rede",
                summary: "Registe a rede atual como Casa, Trabalho, Partilha de ligação, etc., e defina o nível de proteção de cada rede (Confiável / Equilibrado / Bloqueio máximo).",
                details: """
                • Registar: Registar rede atual → Registar como «Casa» (Confiável) / Registar como 'Trabalho' (Equilibrado) / Registar como 'Partilha de ligação' (Equilibrado) / Registar com nome personalizado…. As redes são identificadas pelo endereço MAC da gateway.
                • Mudar de nível: escolha a rede em «Rede atual: …» ou «Redes registadas (n)» e escolha 🟢 / 🟡 / 🔴.
                • Mudar o nome ou remover: Mudar o nome…, Cancelar registo, ou Eliminar.
                """,
                recommendation: "Casa como 🟢 Confiável e Trabalho ou Partilha de ligação como 🟡 Equilibrado funcionam bem. É mais seguro deixar um Wi-Fi de escritório partilhado por registar, mantendo-o em Bloqueio máximo."
            ),
            LocalizedEntry(
                id: "set_away_default_level",
                title: "Proteção predefinida em viagem (nível para redes não registadas)",
                summary: "Escolhe o nível de proteção aplicado automaticamente quando entra numa rede que não registou. Inicialmente 🔴 Bloqueio máximo.",
                details: """
                • Definição: «Proteção predefinida em viagem: …» no menu, depois 🟢 Confiável / 🟡 Equilibrado / 🔴 Bloqueio máximo.
                • Afeta também funcionalidades condicionadas a estar numa rede não fiável, como a Proteção contra ameaças DNS (apenas em viagem), a ligação automática de VPN, a fixação ARP/NDP da gateway, e a desativação automática do Bluetooth.
                """,
                recommendation: "Se não usar serviços de partilha nem AirDrop em viagem, recomenda-se vivamente deixá-lo em Bloqueio máximo."
            ),
            LocalizedEntry(
                id: "set_manual_override",
                title: "Substituição manual e proteção contra esquecer de repor",
                summary: "Define temporariamente um nível de proteção à mão durante uma duração escolhida. Volta à deteção automática quando o tempo termina ou a rede muda, para que não se esqueça de repor a proteção.",
                details: """
                • Definição: Substituição manual → um nível (🟢 / 🟡 / 🔴) → uma duração.
                • Durações: Até desligar da rede (Recomendado), Durante 1 hora, Durante 4 horas, Até ser desativado manualmente.
                • Limpar: Substituição manual → Voltar à deteção automática, ou «🔄 Limpar substituição manual (Auto)» no topo do menu.
                • Libertar uma contenção Air-Gap também limpa qualquer substituição manual.
                """,
                recommendation: "Ao aliviar temporariamente a proteção para uma apresentação ou trabalho de desenvolvimento, use Até desligar da rede ou Durante 1 hora para nunca ficar desprotegido em viagem."
            ),
            LocalizedEntry(
                id: "set_pro_default_guards",
                title: "Proteções ativadas automaticamente com a Pro, e proteções opcionais",
                summary: "Na primeira ativação de uma licença Pro, as principais proteções de defesa autónoma são ativadas automaticamente. Depois disso, a escolha de ativar/desativar que fizer para cada proteção é respeitada.",
                details: """
                • Ativadas automaticamente (uma vez, na primeira ativação da Pro): bloqueio automático de portas de escuta desconhecidas, deteção de ransomware através de ficheiros-isco, bloqueio automático ao detetar falsificação de ARP, desconexão automática ao detetar malware pelo XProtect, auditoria automática de registos, e monitorização periódica de adulteração de ficheiros críticos do sistema. Ao ativar os cortes de ARP e XProtect, surge um aviso único a explicar.
                • Ativas por predefinição com a Pro: Proteção Web e E-mail, e monitorização de registos de início automático (LaunchAgent/Daemon).
                • Desligadas por predefinição (opcionais): bloqueio automático ClickFix, deteção de riscos do Docker, proteção física da porta BadUSB, bloqueio automático de armazenamento USB, fixação ARP/NDP da gateway, túnel VPN, desativação automática do Bluetooth, e verificação ativa de vulnerabilidades. O fornecedor da Proteção contra ameaças DNS é uma escolha sua.
                • Ativa por predefinição mesmo na edição gratuita: proteção da área de transferência (chaves de API e comandos ClickFix).
                • As proteções adicionadas em versões posteriores recebem o seu próprio valor predefinido, uma única vez, para os utilizadores Pro existentes. Se a licença expirar, as proteções exclusivas da Pro são desligadas.
                """,
                recommendation: "Depois de ativar a Pro, verifique as marcas ✅ no menu. Deixe desligadas as proteções que não se adequem à sua utilização (por exemplo, o Docker se não o usar), e ative o que precisar (por exemplo, a VPN se usar frequentemente Wi-Fi público)."
            ),
            LocalizedEntry(
                id: "set_usb_whitelist",
                title: "Definições de proteção USB / BadUSB (lista de permissões de teclados e permissões de armazenamento) (Pro)",
                summary: "Faça a gestão de teclados de confiança e dispositivos de armazenamento USB de trabalho em listas de permissões, e defina a permissão de armazenamento como Só de leitura ou Leitura/escrita.",
                details: """
                • Abrir: «Monitor de portas e dispositivos» → «Definições de proteção USB / BadUSB…».
                • Teclados: são adicionados quando escolhe «Confiar e permitir» na janela de aprovação; podem ser removidos aqui.
                • Armazenamento: é adicionado quando escolhe «Permitir leitura/escrita» ou «Permitir só de leitura» na caixa de diálogo de ligação; pode mudar a permissão ou removê-lo aqui. Se alterar um dispositivo que não esteja ligado, desligue-o e volte a ligá-lo para que a alteração se aplique.
                • A verificação do ClamAV na ligação continua a ser executada para os dispositivos permitidos antes de serem ligados em leitura/escrita.
                """,
                recommendation: "Em Macs que lidam com dados sensíveis, registar o armazenamento como Só de leitura reduz consideravelmente o risco de fugas de dados."
            ),
            LocalizedEntry(
                id: "set_watched_folders",
                title: "Pastas monitorizadas pela Proteção Web e E-mail (Pro)",
                summary: "Adicione, remova ou reponha as pastas monitorizadas pela proteção de descargas (vigilância FSEvents e verificações automáticas).",
                details: """
                • Pastas predefinidas: `~/Downloads`, `~/Desktop`, `~/Documents`, e a pasta de descargas do Mail.
                • Editar: «Proteção Web e E-mail (Verificação automática de descargas) (Pro)» → «📁 Pastas monitorizadas» → «⚙️ Editar pastas monitorizadas…».
                • Repor: «🔄 Repor predefinição».
                • O histórico de verificações recente (até 5 mostradas) e «Limpar histórico de verificações» estão no mesmo menu.
                """,
                recommendation: "Se mudou o local onde o seu navegador ou as suas apps de chat guardam ficheiros, certifique-se de adicionar essa pasta."
            ),
            LocalizedEntry(
                id: "set_dns_policy",
                title: "Fornecedor e política da Proteção contra ameaças DNS (Pro)",
                summary: "Escolha o fornecedor DNS seguro que bloqueia domínios maliciosos, e quando se aplica (apenas em viagem / sempre).",
                details: """
                • Definição: «Proteção contra ameaças DNS (Bloquear malware e C2) (Pro)» → «Fornecedor: …» e «⚙️ Política de aplicação».
                • Fornecedores: Quad9 (Bloqueio automático de malware e C2) / Cloudflare Security (1.1.1.2) / AdGuard DNS (Bloquear ameaças e anúncios) / CleanBrowsing (Filtro de segurança).
                • Política: «Apenas em Wi-Fi não fidedigno fora de casa (recomendado)» ou «Sempre ativo em todas as redes (incluindo redes fidedignas)». Com a opção apenas em viagem, as definições DNS originais são restauradas em redes fidedignas.
                • O item de estado no menu abre as definições de rede para que possa confirmar o que está aplicado.
                """,
                recommendation: "Para a maioria das pessoas, o Quad9 com a política reservada a fora de casa é uma boa escolha. Evite a política sempre ativa se precisar de DNS interno da empresa."
            ),
            LocalizedEntry(
                id: "set_link_guard_modes",
                title: "Modo, atualização automática, extensão do sistema e lista de permissões da Proteção de links (Pro)",
                summary: "Configure o modo da Proteção de links, a atualização automática da lista de ameaças, o estado de aprovação da extensão do sistema, e a forma de permitir sites bloqueados por engano.",
                details: """
                • Modo: «Proteção de links (deteção de ligações de phishing) (Pro)» → «Desligado», «Apenas avisar (nunca bloquear)», ou «Bloquear automaticamente sites de phishing evidentes (recomendado)». O modo Aviso só funciona quando a extensão do sistema está ativa.
                • Atualização automática: clique em «Atualização automática: ligada (apenas receção)» para a desligar. Continua a funcionar com os dados incluídos e a deteção de homógrafos. A versão da lista e o número de domínios são mostrados no menu.
                • Ponto de imposição: «Imposição: extensão do sistema (compatível com DoH)», «Imposição: alternativa via hosts», «A ativar a extensão do sistema…», ou um erro da extensão do sistema. Enquanto a aprovação está pendente, surge «Aprovar a extensão do sistema (abrir Definições do Sistema)…».
                • Permitir/bloquear: «Permitir uma vez (5 min)» numa notificação de bloqueio permite o site durante 5 minutos. As escolhas Permitir/Bloquear no painel de aviso são memorizadas.
                """,
                recommendation: "Aprove a extensão do sistema e use o bloqueio automático com a atualização automática ligada para a proteção mais eficaz."
            ),
            LocalizedEntry(
                id: "set_vpn_backend",
                title: "Definições de backend do túnel VPN (WireGuard / Tailscale) (Pro)",
                summary: "Escolha o backend do túnel VPN, importe uma configuração WireGuard, selecione um nó de saída do Tailscale, e configure o kill switch.",
                details: """
                • Abrir: «Monitor de portas e dispositivos» → «Túnel VPN (anti-MITM em redes não fiáveis) (Pro)» → «Backend».
                • WireGuard: «Importar configuração WireGuard (.conf)…» → «Ligação automática em redes não fiáveis». Também «Ligar agora», «Desligar» e «Remover configuração». O estado mostra, por exemplo, «🟢 Ligado (último handshake há N s)», e o kill switch está sempre ativo. Se faltar `wireguard-tools`, surgem instruções de instalação.
                • Tailscale: escolha um nó em «Exit-Node» («(nenhum — proteção desligada)» para o desativar). Também «Atualizar candidatos» e «Atualizar estado». «Kill-switch: ligado (previne fugas)» é opcional e está desligado por predefinição.
                • Exemplos de linhas de estado: «⚪️ Em espera (liga automaticamente em redes não fiáveis)», «🟡 O nó de saída selecionado está offline».
                """,
                recommendation: "Se já usa Tailscale, escolha Tailscale; caso contrário, a configuração WireGuard do seu fornecedor de VPN é a opção mais simples."
            ),
            LocalizedEntry(
                id: "set_language",
                title: "Idioma de visualização (respostas da app e do MCP)",
                summary: "O RoamSwitch pode ser apresentado em 10 idiomas (日本語, English, 简体中文, 繁體中文, 한국어, Deutsch, Français, Español, Italiano, Português). As respostas do servidor MCP e esta base de conhecimento usam o mesmo idioma.",
                details: """
                • Definição: escolha no menu em «Idioma / Language». «Seguir definições do sistema» usa o idioma preferido do macOS.
                • MCP: o servidor MCP lê o idioma escolhido na app. Se seguir o sistema e o idioma do sistema não for suportado, responde em inglês.
                • A ferramenta `get_app_help` aceita um argumento `language` para escolher o idioma de resposta em cada chamada. As pesquisas encontram correspondências de palavras-chave em qualquer idioma.
                """,
                recommendation: "Para falar com o seu assistente de IA num idioma diferente do da app, use o argumento `language` de `get_app_help`."
            ),
        ]
    }

    // MARK: - Troubleshooting: setup

    private static func troubleshootingPtPTSetup() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "faq_free_vs_pro",
                title: "Diferença entre a edição gratuita e a versão Pro vitalícia",
                summary: "A edição gratuita inclui, sem limite de tempo, a comutação automática de proteção baseada na rede, a auditoria de segurança de 18 pontos, e um conjunto de ferramentas de verificação manual. A Pro desbloqueia a contenção automática, as defesas em tempo real e os avisos de patrulha.",
                details: """
                [Gratuito]
                • Comutação automática do filtro de pacotes PF de 3 níveis por rede, com serviços de partilha e AirDrop parados e restaurados automaticamente
                • Auditoria de segurança do Mac (18 pontos), estado do XProtect, e verificação de segurança de ficheiro/app
                • Listas de portas expostas e dispositivos USB
                • Verificação de segurança de links, auditoria manual de fugas de segredos/chaves de API, proteção da área de transferência
                • Verificação de CVE de pacotes, verificação ativa de vulnerabilidades, Auditoria de registos de segurança do Mac, histórico de notificações
                • Verificações manuais com o ClamAV e gestão de quarentena
                • Integração do servidor MCP
                [Pro vitalícia (compra única 2.980 ¥ / 19,99 $, até 2 Macs)]
                • Deteção de ransomware através de ficheiros-isco com Air-Gap, corte automático ligado ao XProtect, defesa ClickFix
                • Bloqueio automático de portas de escuta desconhecidas, isolamento de servidores de desenvolvimento
                • Bloqueio automático de falsificação de ARP, fixação ARP/NDP da gateway, túnel VPN (WireGuard / Tailscale), avisos de gémeo maligno
                • Proteção de teclado BadUSB, bloqueio automático de armazenamento USB
                • Proteção Web e E-mail (verificação automática, quarentena, avisos Pickle), Proteção contra ameaças DNS, Proteção de links
                • Monitorização de registos de início automático, deteção de riscos do Docker, monitorização de adulteração de ficheiros críticos, auditoria automática de registos
                • Desativação automática do Bluetooth, notificações de ameaça em tempo real, avisos de patrulha, atualizações de definições e verificações agendadas, exportação CSV de registos
                """,
                recommendation: "Escolha a Pro se precisar de contenção automática, defesa em tempo real e monitorização em segundo plano."
            ),
            LocalizedEntry(
                id: "faq_homebrew_clamav",
                title: "Configurar o ClamAV (verificação de vírus) e o Homebrew",
                summary: "A verificação de vírus usa o ClamAV, um software open source instalável com o Homebrew. Sem ele, a integração com o XProtect e todas as funcionalidades próprias do RoamSwitch continuam a funcionar.",
                details: """
                • Homebrew: o gestor de pacotes para macOS (https://brew.sh/).
                • Passos:
                  1. Execute no Terminal o comando oficial de instalação do Homebrew (indicado em https://brew.sh/).
                  2. Execute `brew install clamav`. «📥 Instalar ClamAV através do Homebrew…» no menu também abre instruções.
                  3. Escolha «🛡️ ClamAV (Antivírus gratuito)» → «🔄 Atualizar base de vírus agora».
                • Ativados pelo ClamAV: verificação rápida (Transferências/Secretária), verificação de pasta, verificações na Proteção Web e E-mail e no armazenamento USB, e a verificação agendada da patrulha.
                • Sem o ClamAV: a filtragem de pacotes, a monitorização de portas, a análise de links, a verificação de assinatura estática e mais continuam a funcionar.
                """,
                recommendation: "Instale o Homebrew e o ClamAV se quiser que as descargas e o armazenamento USB sejam verificados automaticamente."
            ),
            LocalizedEntry(
                id: "faq_blueutil_setup",
                title: "Desativação automática do Bluetooth (Pro) e configuração do blueutil",
                summary: "Desativar automaticamente o Bluetooth em viagem requer a ferramenta open source `blueutil`.",
                details: """
                • Contexto: o macOS não oferece uma API pública para as apps ligarem/desligarem a alimentação do Bluetooth, pelo que é usada a ferramenta de linha de comandos `blueutil`.
                • Passos:
                  1. Execute `brew install blueutil` no Terminal (ou use «📥 Instalar o blueutil através do Homebrew…» no menu).
                  2. Ative «Monitor de portas e dispositivos» → «Desativação automática do Bluetooth em redes não fiáveis (Pro)».
                • Se não estiver instalado: nada mais é afetado, e o menu mostra «🔵 Desativação automática do Bluetooth (não instalado)».
                """,
                recommendation: "Para evitar o rastreio por rádio e as vulnerabilidades do Bluetooth em Wi-Fi público, execute `brew install blueutil` e ative-a."
            ),
            LocalizedEntry(
                id: "faq_helper_troubleshooting",
                title: "O que fazer quando aparece «⚠️ Auxiliar não ligado»",
                summary: "Passos de recuperação quando o RoamSwitch não consegue comunicar com a ferramenta auxiliar privilegiada (RoamSwitchHelper).",
                details: """
                1. Escolha «⚠️ Aprovar o auxiliar…» no menu e siga os passos mostrados.
                2. Abra Definições do Sistema → Geral → Itens de início e extensões e assegure-se de que o RoamSwitchHelper está ativo em Permitir em segundo plano.
                3. Assegure-se de que o RoamSwitch está na pasta Aplicações (faq_install_location).
                4. Prima «Repetir o registo do auxiliar» na janela de boas-vindas.
                5. Se continuar a falhar, execute `sudo killall RoamSwitchHelper` no Terminal para reiniciar o auxiliar (o launchd volta a lançá-lo automaticamente), depois reinicie o RoamSwitch.
                """,
                recommendation: "Se o auxiliar deixar de responder logo após uma atualização do macOS, verifique primeiro o interruptor dos Itens de início e, depois, tente `sudo killall RoamSwitchHelper`."
            ),
            LocalizedEntry(
                id: "faq_install_location",
                title: "Localização da app (iniciada fora da pasta Aplicações)",
                summary: "O macOS não regista o auxiliar privilegiado para uma app que esteja fora da pasta Aplicações, pelo que o RoamSwitch deve ficar em `/Applications` ou `~/Applications` e ser iniciado a partir daí.",
                details: """
                • Localizações que não permitem o registo: Transferências ou Secretária, execução a partir de uma imagem de disco (.dmg) ainda montada, ou quando o Gatekeeper App Translocation moveu a app para uma localização temporária só de leitura.
                • Orientação: as boas-vindas verificam a localização no arranque e propõem «Mover para Aplicações e reiniciar» ou «Abrir Aplicações no Finder».
                • Depois de mover: prima «Verificar novamente» ou reinicie, e depois aprove o auxiliar.
                """,
                recommendation: "Arraste o RoamSwitch da imagem de disco para a pasta Aplicações e inicie-o a partir daí."
            ),
            LocalizedEntry(
                id: "faq_system_extension_approval",
                title: "Aprovar a extensão do sistema da Proteção de links",
                summary: "Para que a Proteção de links funcione da melhor forma (compatível com DoH, modo Aviso), a extensão do sistema de filtragem de conteúdo tem de ser aprovada. Até lá, usa a alternativa via /etc/hosts.",
                details: """
                • Passos: «Proteção de links (deteção de ligações de phishing) (Pro)» → «Aprovar a extensão do sistema (abrir Definições do Sistema)…» → Definições do Sistema → Geral → Itens de início e extensões, depois permita a extensão de rede do RoamSwitch.
                • Após a aprovação: o menu mostra «Imposição: extensão do sistema (compatível com DoH)».
                • Se aparecer um erro da extensão do sistema: assegure-se de que a app está na pasta Aplicações, depois volte a selecionar um modo da Proteção de links para tentar novamente.
                • Este método não requer revisão da App Store nem pedido de permissão adicional (assinada com Developer ID e notarizada).
                """,
                recommendation: "Aprove a extensão do sistema para que a proteção se mantenha mesmo quando o seu navegador usa DNS sobre HTTPS."
            ),
            LocalizedEntry(
                id: "faq_mcp_setup",
                title: "Configurar o servidor MCP (Claude Desktop, Claude Code e outros)",
                summary: "Como registar o servidor MCP incluído no RoamSwitch num cliente de IA compatível com MCP.",
                details: """
                • Caminho do binário: `/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`
                • Claude Desktop: adicione o caminho do binário como `command` em `mcpServers` em `~/Library/Application Support/Claude/claude_desktop_config.json`.
                • Claude Code: `claude mcp add roamswitch /Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer`
                • Outros clientes (Codex CLI e mais): https://lafine.net/mcp-setup.html
                • Idioma de resposta: segue a definição «Idioma / Language» da app. `get_app_help` aceita um argumento `language` por chamada.
                • A comunicação é feita apenas por stdio local, sem enviar nada para o exterior (apenas `run_active_vuln_scan` envia sondas não destrutivas para 127.0.0.1).
                """,
                recommendation: "Depois de registado, peça à sua IA algo como «Verifica o estado de segurança do meu Mac com o RoamSwitch» e ela explicar-lhe-á os resultados da auditoria."
            ),
        ]
    }

    // MARK: - Troubleshooting: operation

    private static func troubleshootingPtPTOperation() -> [LocalizedEntry] {
        return [
            LocalizedEntry(
                id: "faq_network_cut_off",
                title: "A internet deixou subitamente de funcionar (contenção Air-Gap / nível de proteção)",
                summary: "O Air-Gap de emergência ou o Bloqueio máximo do RoamSwitch podem estar a impedir o tráfego. Como encontrar a causa e libertá-lo.",
                details: """
                • Verificar: procure uma janela de emergência, e verifique o histórico de notificações à procura de alertas como DEFESA AUTOMÁTICA CRÍTICA, XProtect, falsificação de ARP, ou execução de comandos suspeitos. O Wi-Fi também pode ter sido desligado.
                • Libertar: use o botão de libertação na janela de emergência ou na notificação. A rede e o Wi-Fi voltam.
                • Restauro automático: mesmo sem libertar, a rede de segurança do auxiliar restaura a rede em 10 minutos. Não é necessário nenhum passo manual após fechar a app, uma falha, ou um reinício.
                • Logo após o arranque: o tráfego pode estar limitado pela porta de arranque até 90 segundos.
                • Outras causas: o Bloqueio máximo bloqueia o tráfego de entrada mas não impede a utilização normal de saída, como navegar na web. Verifique também o kill switch da VPN (enquanto o túnel está inativo), o resolvedor da Proteção contra ameaças DNS, e os bloqueios da Proteção de links.
                """,
                recommendation: "Quando a contenção for acionada, leia a notificação que a desencadeou e liberte-a assim que confirmar que é seguro. Se uma proteção se ativar frequentemente por engano, pode desligá-la individualmente a partir do menu."
            ),
            LocalizedEntry(
                id: "faq_quarantine_false_positive",
                title: "Restaurar uma descarga colocada em quarentena por engano",
                summary: "Como restaurar o seu próprio script ou binário de desenvolvimento colocado em quarentena como falso positivo, e excluí-lo das verificações.",
                details: """
                1. Abra Proteção contra malware → ClamAV → «📦 Gerir ficheiros em quarentena…».
                2. Selecione o ficheiro entre os ficheiros em quarentena (são mostrados o caminho original, o nome da ameaça e o momento da quarentena).
                3. Para um falso positivo certo, prima «Excluir e restaurar»: volta ao local original e esse caminho é excluído de verificações futuras. Para restaurar apenas uma vez, prima «Restaurar».
                4. Para anular uma exclusão, prima «Remover exclusão» na lista de caminhos excluídos, na mesma janela.
                5. Para deixar de monitorizar uma pasta inteira, ajuste «⚙️ Editar pastas monitorizadas…» em Proteção Web e E-mail.
                """,
                recommendation: "Se não tiver a certeza de que um ficheiro é seguro, não o restaure; escolha Eliminar permanentemente."
            ),
            LocalizedEntry(
                id: "faq_eicar_test",
                title: "Coloquei um ficheiro de teste EICAR mas não recebi nenhuma notificação",
                summary: "É intencional. A assinatura de teste EICAR é um teste inofensivo, pelo que não aparece nenhum aviso e nada é colocado em quarentena. A deteção é registada no histórico de notificações.",
                details: """
                • Como confirmar: verifique em Auditoria de segurança do Mac → «🔔 Histórico de notificações…» se aparece «🧪 Assinatura de teste EICAR detetada (inofensiva)».
                • O ficheiro: permanece onde está.
                • Para testar o caminho de aviso real: use as simulações na parte inferior de Proteção contra malware (defesa contra ransomware, Air-Gap de deteção de malware, deteção de riscos do Docker).
                """,
                recommendation: "Elimine o ficheiro EICAR quando terminar os testes."
            ),
            LocalizedEntry(
                id: "faq_dev_server_blocked",
                title: "O meu servidor de desenvolvimento ou a minha app de receção LAN não é acessível a partir de outros dispositivos",
                summary: "O bloqueio automático de portas de escuta desconhecidas pode estar a bloquear um programa que acabou de começar a expor uma porta. Continua acessível a partir do próprio Mac.",
                details: """
                • Verificar: procure no histórico de notificações «Porta de escuta desconhecida bloqueada automaticamente».
                • Permitir: use o botão «Permitir» da notificação, ou Portas expostas → a porta → o ecrã de auditoria de portas. Permiti-la aplica-se de forma permanente, por executável.
                • Em contraste com o isolamento manual: uma porta que isolou você mesmo com «Isolar porta» é restaurada com «Remover isolamento» no ecrã de auditoria de portas.
                • Nível de proteção: numa rede com Bloqueio máximo, a firewall bloqueia completamente as ligações de entrada. Para permitir acesso a partir da LAN, registe essa rede e defina-a como Equilibrado ou Confiável.
                """,
                recommendation: "Permita uma vez as apps de receção LAN que usa regularmente, como o LocalSend ou o Syncthing, e não voltarão a ser bloqueadas."
            ),
            LocalizedEntry(
                id: "faq_link_guard_false_block",
                title: "A Proteção de links bloqueia um site legítimo / mantém uma ligação em espera",
                summary: "O que fazer quando a Proteção de links bloqueia um site por engano ou o mantém em espera no modo Aviso.",
                details: """
                • Permitir temporariamente: «Permitir uma vez (5 min)» na notificação de bloqueio.
                • Permitir permanentemente: escolher «Permitir» no painel de aviso é memorizado.
                • Uma ligação em espera bloqueou-se sozinha: o modo Aviso bloqueia se não houver resposta em cerca de 8 segundos (falha de forma fechada). Esse resultado não é guardado em cache, pelo que recarregar a página voltará a perguntar.
                • Não vê a notificação: com o estilo de notificação em faixa, os botões podem ficar ocultos, pelo que também surge um painel em primeiro plano. Durante o modo Não incomodar, verifique o histórico de notificações.
                • Desligar temporariamente: mude o modo para «Apenas avisar (nunca bloquear)» ou «Desligado».
                """,
                recommendation: "Se uma ferramenta de trabalho for bloqueada repetidamente, verifique se o domínio não tem erros de escrita nem semelhanças suspeitas antes de o permitir."
            ),
            LocalizedEntry(
                id: "faq_keyboard_blocked",
                title: "O meu teclado externo não escreve (proteção BadUSB)",
                summary: "A proteção física da porta contra BadUSB está a bloquear a entrada de um teclado fora da lista de permissões até o aprovar.",
                details: """
                • Aprovar: clique em «Confiar e permitir» na janela «⚠️ Dispositivo USB / teclado desconhecido detetado» (use o teclado incorporado ou o trackpad).
                • Não encontra a janela: desligue e volte a ligar o dispositivo para que reapareça.
                • Docas e comutadores KVM: os dispositivos com função de teclado incorporada também estão cobertos. Permita-os se forem seus.
                • Permissão de Acessibilidade: o bloqueio alternativo usado quando o dispositivo não pode ser tomado de forma exclusiva depende da permissão de Acessibilidade.
                • Revogar: remova-o em «Definições de proteção USB / BadUSB…».
                """,
                recommendation: "Não permita um dispositivo que tenha acionado o aviso de digitação guionizada; desligue-o."
            ),
            LocalizedEntry(
                id: "faq_vpn_troubleshooting",
                title: "O túnel VPN não liga / não passa tráfego",
                summary: "O que verificar quando o backend WireGuard ou Tailscale não funciona.",
                details: """
                • WireGuard: confirme que `brew install wireguard-tools` está instalado e que foi importada uma `.conf`. Se o estado mostrar «🟡 Sem resposta (último handshake …)», verifique o servidor VPN e as chaves e o ponto final da configuração. O kill switch está ativo, pelo que nada passa até o túnel estar estabelecido.
                • Tailscale: confirme que a CLI está instalada e com sessão iniciada (caso contrário, o menu mostra «Inicie sessão no Tailscale primeiro») e que um nó de saída está selecionado. Se o nó de saída selecionado estiver offline, escolha outro.
                • Tailscale da App Store: o nó de saída não pode ser definido a partir de fora da app, escolha-o na app Tailscale.
                • Kill switch do Tailscale: em algumas redes pode interferir com a conetividade do próprio Tailscale; desligue-o se não conseguir ligar-se.
                • Desligar-se automaticamente em redes fidedignas é o comportamento esperado.
                """,
                recommendation: "Comece pela linha de estado no menu: o handshake para o WireGuard, o estado do nó de saída para o Tailscale."
            ),
            LocalizedEntry(
                id: "faq_log_audit_repeated_alerts",
                title: "As notificações da auditoria de registos não param de chegar",
                summary: "A auditoria automática de registos aprende o comportamento normal dos registos deste Mac à medida que é executada. Os alertas aumentam logo após a configuração ou uma atualização importante e diminuem naturalmente à medida que a aprendizagem avança.",
                details: """
                • Novos padrões: uma vez notificado, um padrão torna-se conhecido e não é renotificado pelo mesmo conteúdo.
                • Picos de frequência: a aprendizagem de cada padrão completa-se após 3 observações; depois disso, um volume normal não gera alertas. Enquanto a notificação continuar a mostrar algo como «aprendizagem de frequência em curso: 2/3 observações», a aprendizagem continua.
                • Causas comuns: atualizações do macOS ou de apps, ligação de novos dispositivos, carga elevada temporária.
                • Para o parar: desligue no menu «Auditoria automática de registos (aprende novos padrões e anomalias de frequência de forma agendada) (Pro)» (a auditoria manual de registos continua disponível).
                """,
                recommendation: "Enquanto os alertas não incluírem nomes de apps ou endereços IP desconhecidos, nem falhas de sudo, pode aguardar um pouco."
            ),
            LocalizedEntry(
                id: "faq_zero_telemetry",
                title: "Design de privacidade Zero Telemetry",
                summary: "O RoamSwitch e o seu servidor MCP nunca enviam resultados de auditoria, URL, informações de portas, registos ou conteúdo de ficheiros para servidores externos. O único tráfego de rede são as exceções explícitas seguintes.",
                details: """
                • Totalmente local: a auditoria de segurança, a monitorização de portas, a análise de links, a auditoria de segredos, a auditoria de registos, a verificação antivírus e a comunicação MCP permanecem todas no dispositivo.
                • Exceções:
                  - A ativação e desativação de licença (apenas quando age) e a abertura da página de compra
                  - As verificações de atualização da app (Sparkle)
                  - As atualizações das definições do ClamAV (`freshclam`)
                  - As descargas diárias da lista de ameaças da Proteção de links, dos mapas de CVE de pacotes, e dos mapas de CVE de vulnerabilidades (apenas em receção, verificados por assinatura, sem enviar identificadores; a atualização automática da Proteção de links pode ser desligada)
                  - O tráfego normal para os fornecedores de VPN e DNS seguro que configurar
                  - As sondas não destrutivas da verificação ativa de vulnerabilidades para 127.0.0.1 (este próprio Mac)
                • Não existe em nenhum lugar do código telemetria nem recolha de utilização. Até o lembrete de aprovação do auxiliar funciona apenas a partir de uma contagem no dispositivo.
                """,
                recommendation: "É seguro de usar em ambientes empresariais altamente confidenciais e configurações de desenvolvimento pessoais sem se preocupar com fugas de dados."
            ),
        ]
    }
}
