// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.31 (build 210).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
// GENERATED FILE — do not edit by hand.
//
// Regenerate with:
//   python3 scripts/gen_swift_sensor_finding_texts.py /path/to/roamswitch-linux
//
// Source of truth: roamswitch-linux's roamswitch-core (service_signatures.rs and its i18n catalog), the
// checks a RoamSwitch Sensor audits with, and its known-CVE table (data/active_vuln_cve_map.json, map
// version 2026-10-16). Keyed by `<source>:<check>` of a finding's `text_keys`
// (`cve:<signature>:<CVE id>` for a CVE); each language has [title, description, recommendation].
// Left out (their texts take arguments): web:webvuln-unauth-admin.

enum SensorFindingTextsData {
    static let embeddedJSON = #"""
{
 "cve:gradio-noauth:CVE-2021-43831": {
  "de": [
   "Bekannte Schwachstelle: CVE-2021-43831 (Gradio)",
   "NVD-Beschreibung (englischer Originaltext): Gradio is an open source framework for building interactive machine learning models and demos. In versions prior to 2.5.0 there is a vulnerability that affects anyone who creates and publicly shares Gradio interfaces. File paths are not restricted and users who receive a Gradio link can access any files on the host computer if they know the file names or file paths. This is limited only by the host operating system. Paths are opened in read only mode. The problem has been patched in gradio 2.5.0",
   "Aktualisieren Sie Gradio so schnell wie möglich auf eine Version, die von CVE-2021-43831 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2021-43831 (Gradio)",
   "Gradio is an open source framework for building interactive machine learning models and demos. In versions prior to 2.5.0 there is a vulnerability that affects anyone who creates and publicly shares Gradio interfaces. File paths are not restricted and users who receive a Gradio link can access any files on the host computer if they know the file names or file paths. This is limited only by the host operating system. Paths are opened in read only mode. The problem has been patched in gradio 2.5.0",
   "Upgrade Gradio to a version not affected by CVE-2021-43831 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2021-43831 (Gradio)",
   "Descripción de NVD (texto original en inglés): Gradio is an open source framework for building interactive machine learning models and demos. In versions prior to 2.5.0 there is a vulnerability that affects anyone who creates and publicly shares Gradio interfaces. File paths are not restricted and users who receive a Gradio link can access any files on the host computer if they know the file names or file paths. This is limited only by the host operating system. Paths are opened in read only mode. The problem has been patched in gradio 2.5.0",
   "Actualice Gradio lo antes posible a una versión no afectada por CVE-2021-43831 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2021-43831 (Gradio)",
   "Description NVD (texte original en anglais) : Gradio is an open source framework for building interactive machine learning models and demos. In versions prior to 2.5.0 there is a vulnerability that affects anyone who creates and publicly shares Gradio interfaces. File paths are not restricted and users who receive a Gradio link can access any files on the host computer if they know the file names or file paths. This is limited only by the host operating system. Paths are opened in read only mode. The problem has been patched in gradio 2.5.0",
   "Mettez à niveau Gradio dès que possible vers une version non affectée par CVE-2021-43831 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2021-43831 (Gradio)",
   "Descrizione NVD (testo originale in inglese): Gradio is an open source framework for building interactive machine learning models and demos. In versions prior to 2.5.0 there is a vulnerability that affects anyone who creates and publicly shares Gradio interfaces. File paths are not restricted and users who receive a Gradio link can access any files on the host computer if they know the file names or file paths. This is limited only by the host operating system. Paths are opened in read only mode. The problem has been patched in gradio 2.5.0",
   "Aggiorna Gradio il prima possibile a una versione non interessata da CVE-2021-43831 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2021-43831 (Gradio)",
   "NVDの説明（英語原文）: Gradio is an open source framework for building interactive machine learning models and demos. In versions prior to 2.5.0 there is a vulnerability that affects anyone who creates and publicly shares Gradio interfaces. File paths are not restricted and users who receive a Gradio link can access any files on the host computer if they know the file names or file paths. This is limited only by the host operating system. Paths are opened in read only mode. The problem has been patched in gradio 2.5.0",
   "Gradio を CVE-2021-43831 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2021-43831 (Gradio)",
   "NVD 설명(영어 원문): Gradio is an open source framework for building interactive machine learning models and demos. In versions prior to 2.5.0 there is a vulnerability that affects anyone who creates and publicly shares Gradio interfaces. File paths are not restricted and users who receive a Gradio link can access any files on the host computer if they know the file names or file paths. This is limited only by the host operating system. Paths are opened in read only mode. The problem has been patched in gradio 2.5.0",
   "Gradio을(를) CVE-2021-43831의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2021-43831 (Gradio)",
   "Descrição do NVD (texto original em inglês): Gradio is an open source framework for building interactive machine learning models and demos. In versions prior to 2.5.0 there is a vulnerability that affects anyone who creates and publicly shares Gradio interfaces. File paths are not restricted and users who receive a Gradio link can access any files on the host computer if they know the file names or file paths. This is limited only by the host operating system. Paths are opened in read only mode. The problem has been patched in gradio 2.5.0",
   "Atualize o Gradio o quanto antes para uma versão não afetada por CVE-2021-43831 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2021-43831（Gradio）",
   "NVD 说明（英文原文）：Gradio is an open source framework for building interactive machine learning models and demos. In versions prior to 2.5.0 there is a vulnerability that affects anyone who creates and publicly shares Gradio interfaces. File paths are not restricted and users who receive a Gradio link can access any files on the host computer if they know the file names or file paths. This is limited only by the host operating system. Paths are opened in read only mode. The problem has been patched in gradio 2.5.0",
   "请尽快将 Gradio 升级到不受 CVE-2021-43831 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2021-43831（Gradio）",
   "NVD 說明（英文原文）：Gradio is an open source framework for building interactive machine learning models and demos. In versions prior to 2.5.0 there is a vulnerability that affects anyone who creates and publicly shares Gradio interfaces. File paths are not restricted and users who receive a Gradio link can access any files on the host computer if they know the file names or file paths. This is limited only by the host operating system. Paths are opened in read only mode. The problem has been patched in gradio 2.5.0",
   "請儘快將 Gradio 升級到不受 CVE-2021-43831 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:gradio-noauth:CVE-2022-24770": {
  "de": [
   "Bekannte Schwachstelle: CVE-2022-24770 (Gradio)",
   "NVD-Beschreibung (englischer Originaltext): `gradio` is an open source framework for building interactive machine learning models and demos. Prior to version 2.8.11, `gradio` suffers from Improper Neutralization of Formula Elements in a CSV File. The `gradio` library has a flagging functionality which saves input/output data into a CSV file on the developer's computer. This can allow a user to save arbitrary text into the CSV file, such as commands. If a program like MS Excel opens such a file, then it automatically runs these commands, w",
   "Aktualisieren Sie Gradio so schnell wie möglich auf eine Version, die von CVE-2022-24770 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2022-24770 (Gradio)",
   "`gradio` is an open source framework for building interactive machine learning models and demos. Prior to version 2.8.11, `gradio` suffers from Improper Neutralization of Formula Elements in a CSV File. The `gradio` library has a flagging functionality which saves input/output data into a CSV file on the developer's computer. This can allow a user to save arbitrary text into the CSV file, such as commands. If a program like MS Excel opens such a file, then it automatically runs these commands, w",
   "Upgrade Gradio to a version not affected by CVE-2022-24770 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2022-24770 (Gradio)",
   "Descripción de NVD (texto original en inglés): `gradio` is an open source framework for building interactive machine learning models and demos. Prior to version 2.8.11, `gradio` suffers from Improper Neutralization of Formula Elements in a CSV File. The `gradio` library has a flagging functionality which saves input/output data into a CSV file on the developer's computer. This can allow a user to save arbitrary text into the CSV file, such as commands. If a program like MS Excel opens such a file, then it automatically runs these commands, w",
   "Actualice Gradio lo antes posible a una versión no afectada por CVE-2022-24770 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2022-24770 (Gradio)",
   "Description NVD (texte original en anglais) : `gradio` is an open source framework for building interactive machine learning models and demos. Prior to version 2.8.11, `gradio` suffers from Improper Neutralization of Formula Elements in a CSV File. The `gradio` library has a flagging functionality which saves input/output data into a CSV file on the developer's computer. This can allow a user to save arbitrary text into the CSV file, such as commands. If a program like MS Excel opens such a file, then it automatically runs these commands, w",
   "Mettez à niveau Gradio dès que possible vers une version non affectée par CVE-2022-24770 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2022-24770 (Gradio)",
   "Descrizione NVD (testo originale in inglese): `gradio` is an open source framework for building interactive machine learning models and demos. Prior to version 2.8.11, `gradio` suffers from Improper Neutralization of Formula Elements in a CSV File. The `gradio` library has a flagging functionality which saves input/output data into a CSV file on the developer's computer. This can allow a user to save arbitrary text into the CSV file, such as commands. If a program like MS Excel opens such a file, then it automatically runs these commands, w",
   "Aggiorna Gradio il prima possibile a una versione non interessata da CVE-2022-24770 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2022-24770 (Gradio)",
   "NVDの説明（英語原文）: `gradio` is an open source framework for building interactive machine learning models and demos. Prior to version 2.8.11, `gradio` suffers from Improper Neutralization of Formula Elements in a CSV File. The `gradio` library has a flagging functionality which saves input/output data into a CSV file on the developer's computer. This can allow a user to save arbitrary text into the CSV file, such as commands. If a program like MS Excel opens such a file, then it automatically runs these commands, w",
   "Gradio を CVE-2022-24770 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2022-24770 (Gradio)",
   "NVD 설명(영어 원문): `gradio` is an open source framework for building interactive machine learning models and demos. Prior to version 2.8.11, `gradio` suffers from Improper Neutralization of Formula Elements in a CSV File. The `gradio` library has a flagging functionality which saves input/output data into a CSV file on the developer's computer. This can allow a user to save arbitrary text into the CSV file, such as commands. If a program like MS Excel opens such a file, then it automatically runs these commands, w",
   "Gradio을(를) CVE-2022-24770의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2022-24770 (Gradio)",
   "Descrição do NVD (texto original em inglês): `gradio` is an open source framework for building interactive machine learning models and demos. Prior to version 2.8.11, `gradio` suffers from Improper Neutralization of Formula Elements in a CSV File. The `gradio` library has a flagging functionality which saves input/output data into a CSV file on the developer's computer. This can allow a user to save arbitrary text into the CSV file, such as commands. If a program like MS Excel opens such a file, then it automatically runs these commands, w",
   "Atualize o Gradio o quanto antes para uma versão não afetada por CVE-2022-24770 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2022-24770（Gradio）",
   "NVD 说明（英文原文）：`gradio` is an open source framework for building interactive machine learning models and demos. Prior to version 2.8.11, `gradio` suffers from Improper Neutralization of Formula Elements in a CSV File. The `gradio` library has a flagging functionality which saves input/output data into a CSV file on the developer's computer. This can allow a user to save arbitrary text into the CSV file, such as commands. If a program like MS Excel opens such a file, then it automatically runs these commands, w",
   "请尽快将 Gradio 升级到不受 CVE-2022-24770 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2022-24770（Gradio）",
   "NVD 說明（英文原文）：`gradio` is an open source framework for building interactive machine learning models and demos. Prior to version 2.8.11, `gradio` suffers from Improper Neutralization of Formula Elements in a CSV File. The `gradio` library has a flagging functionality which saves input/output data into a CSV file on the developer's computer. This can allow a user to save arbitrary text into the CSV file, such as commands. If a program like MS Excel opens such a file, then it automatically runs these commands, w",
   "請儘快將 Gradio 升級到不受 CVE-2022-24770 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:gradio-noauth:CVE-2023-34239": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-34239 (Gradio)",
   "NVD-Beschreibung (englischer Originaltext): Gradio is an open-source Python library that is used to build machine learning and data science. Due to a lack of path filtering Gradio does not properly restrict file access to users. Additionally Gradio does not properly restrict the what URLs are proxied. These issues have been addressed in version 3.34.0. Users are advised to upgrade. There are no known workarounds for this vulnerability.",
   "Aktualisieren Sie Gradio so schnell wie möglich auf eine Version, die von CVE-2023-34239 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-34239 (Gradio)",
   "Gradio is an open-source Python library that is used to build machine learning and data science. Due to a lack of path filtering Gradio does not properly restrict file access to users. Additionally Gradio does not properly restrict the what URLs are proxied. These issues have been addressed in version 3.34.0. Users are advised to upgrade. There are no known workarounds for this vulnerability.",
   "Upgrade Gradio to a version not affected by CVE-2023-34239 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-34239 (Gradio)",
   "Descripción de NVD (texto original en inglés): Gradio is an open-source Python library that is used to build machine learning and data science. Due to a lack of path filtering Gradio does not properly restrict file access to users. Additionally Gradio does not properly restrict the what URLs are proxied. These issues have been addressed in version 3.34.0. Users are advised to upgrade. There are no known workarounds for this vulnerability.",
   "Actualice Gradio lo antes posible a una versión no afectada por CVE-2023-34239 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-34239 (Gradio)",
   "Description NVD (texte original en anglais) : Gradio is an open-source Python library that is used to build machine learning and data science. Due to a lack of path filtering Gradio does not properly restrict file access to users. Additionally Gradio does not properly restrict the what URLs are proxied. These issues have been addressed in version 3.34.0. Users are advised to upgrade. There are no known workarounds for this vulnerability.",
   "Mettez à niveau Gradio dès que possible vers une version non affectée par CVE-2023-34239 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-34239 (Gradio)",
   "Descrizione NVD (testo originale in inglese): Gradio is an open-source Python library that is used to build machine learning and data science. Due to a lack of path filtering Gradio does not properly restrict file access to users. Additionally Gradio does not properly restrict the what URLs are proxied. These issues have been addressed in version 3.34.0. Users are advised to upgrade. There are no known workarounds for this vulnerability.",
   "Aggiorna Gradio il prima possibile a una versione non interessata da CVE-2023-34239 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-34239 (Gradio)",
   "NVDの説明（英語原文）: Gradio is an open-source Python library that is used to build machine learning and data science. Due to a lack of path filtering Gradio does not properly restrict file access to users. Additionally Gradio does not properly restrict the what URLs are proxied. These issues have been addressed in version 3.34.0. Users are advised to upgrade. There are no known workarounds for this vulnerability.",
   "Gradio を CVE-2023-34239 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-34239 (Gradio)",
   "NVD 설명(영어 원문): Gradio is an open-source Python library that is used to build machine learning and data science. Due to a lack of path filtering Gradio does not properly restrict file access to users. Additionally Gradio does not properly restrict the what URLs are proxied. These issues have been addressed in version 3.34.0. Users are advised to upgrade. There are no known workarounds for this vulnerability.",
   "Gradio을(를) CVE-2023-34239의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-34239 (Gradio)",
   "Descrição do NVD (texto original em inglês): Gradio is an open-source Python library that is used to build machine learning and data science. Due to a lack of path filtering Gradio does not properly restrict file access to users. Additionally Gradio does not properly restrict the what URLs are proxied. These issues have been addressed in version 3.34.0. Users are advised to upgrade. There are no known workarounds for this vulnerability.",
   "Atualize o Gradio o quanto antes para uma versão não afetada por CVE-2023-34239 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-34239（Gradio）",
   "NVD 说明（英文原文）：Gradio is an open-source Python library that is used to build machine learning and data science. Due to a lack of path filtering Gradio does not properly restrict file access to users. Additionally Gradio does not properly restrict the what URLs are proxied. These issues have been addressed in version 3.34.0. Users are advised to upgrade. There are no known workarounds for this vulnerability.",
   "请尽快将 Gradio 升级到不受 CVE-2023-34239 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-34239（Gradio）",
   "NVD 說明（英文原文）：Gradio is an open-source Python library that is used to build machine learning and data science. Due to a lack of path filtering Gradio does not properly restrict file access to users. Additionally Gradio does not properly restrict the what URLs are proxied. These issues have been addressed in version 3.34.0. Users are advised to upgrade. There are no known workarounds for this vulnerability.",
   "請儘快將 Gradio 升級到不受 CVE-2023-34239 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:gradio-noauth:CVE-2023-6572": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-6572 (Gradio)",
   "NVD-Beschreibung (englischer Originaltext): Command Injection in GitHub repository gradio-app/gradio prior to main.",
   "Aktualisieren Sie Gradio so schnell wie möglich auf eine Version, die von CVE-2023-6572 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-6572 (Gradio)",
   "Command Injection in GitHub repository gradio-app/gradio prior to main.",
   "Upgrade Gradio to a version not affected by CVE-2023-6572 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-6572 (Gradio)",
   "Descripción de NVD (texto original en inglés): Command Injection in GitHub repository gradio-app/gradio prior to main.",
   "Actualice Gradio lo antes posible a una versión no afectada por CVE-2023-6572 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-6572 (Gradio)",
   "Description NVD (texte original en anglais) : Command Injection in GitHub repository gradio-app/gradio prior to main.",
   "Mettez à niveau Gradio dès que possible vers une version non affectée par CVE-2023-6572 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-6572 (Gradio)",
   "Descrizione NVD (testo originale in inglese): Command Injection in GitHub repository gradio-app/gradio prior to main.",
   "Aggiorna Gradio il prima possibile a una versione non interessata da CVE-2023-6572 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-6572 (Gradio)",
   "NVDの説明（英語原文）: Command Injection in GitHub repository gradio-app/gradio prior to main.",
   "Gradio を CVE-2023-6572 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-6572 (Gradio)",
   "NVD 설명(영어 원문): Command Injection in GitHub repository gradio-app/gradio prior to main.",
   "Gradio을(를) CVE-2023-6572의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-6572 (Gradio)",
   "Descrição do NVD (texto original em inglês): Command Injection in GitHub repository gradio-app/gradio prior to main.",
   "Atualize o Gradio o quanto antes para uma versão não afetada por CVE-2023-6572 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-6572（Gradio）",
   "NVD 说明（英文原文）：Command Injection in GitHub repository gradio-app/gradio prior to main.",
   "请尽快将 Gradio 升级到不受 CVE-2023-6572 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-6572（Gradio）",
   "NVD 說明（英文原文）：Command Injection in GitHub repository gradio-app/gradio prior to main.",
   "請儘快將 Gradio 升級到不受 CVE-2023-6572 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:gradio-noauth:CVE-2024-0964": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-0964 (Gradio)",
   "NVD-Beschreibung (englischer Originaltext): A local file include could be remotely triggered in Gradio due to a vulnerable user-supplied JSON value in an API request.",
   "Aktualisieren Sie Gradio so schnell wie möglich auf eine Version, die von CVE-2024-0964 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-0964 (Gradio)",
   "A local file include could be remotely triggered in Gradio due to a vulnerable user-supplied JSON value in an API request.",
   "Upgrade Gradio to a version not affected by CVE-2024-0964 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-0964 (Gradio)",
   "Descripción de NVD (texto original en inglés): A local file include could be remotely triggered in Gradio due to a vulnerable user-supplied JSON value in an API request.",
   "Actualice Gradio lo antes posible a una versión no afectada por CVE-2024-0964 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-0964 (Gradio)",
   "Description NVD (texte original en anglais) : A local file include could be remotely triggered in Gradio due to a vulnerable user-supplied JSON value in an API request.",
   "Mettez à niveau Gradio dès que possible vers une version non affectée par CVE-2024-0964 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-0964 (Gradio)",
   "Descrizione NVD (testo originale in inglese): A local file include could be remotely triggered in Gradio due to a vulnerable user-supplied JSON value in an API request.",
   "Aggiorna Gradio il prima possibile a una versione non interessata da CVE-2024-0964 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-0964 (Gradio)",
   "NVDの説明（英語原文）: A local file include could be remotely triggered in Gradio due to a vulnerable user-supplied JSON value in an API request.",
   "Gradio を CVE-2024-0964 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-0964 (Gradio)",
   "NVD 설명(영어 원문): A local file include could be remotely triggered in Gradio due to a vulnerable user-supplied JSON value in an API request.",
   "Gradio을(를) CVE-2024-0964의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-0964 (Gradio)",
   "Descrição do NVD (texto original em inglês): A local file include could be remotely triggered in Gradio due to a vulnerable user-supplied JSON value in an API request.",
   "Atualize o Gradio o quanto antes para uma versão não afetada por CVE-2024-0964 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-0964（Gradio）",
   "NVD 说明（英文原文）：A local file include could be remotely triggered in Gradio due to a vulnerable user-supplied JSON value in an API request.",
   "请尽快将 Gradio 升级到不受 CVE-2024-0964 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-0964（Gradio）",
   "NVD 說明（英文原文）：A local file include could be remotely triggered in Gradio due to a vulnerable user-supplied JSON value in an API request.",
   "請儘快將 Gradio 升級到不受 CVE-2024-0964 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:gradio-noauth:CVE-2024-1561": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-1561 (Gradio)",
   "NVD-Beschreibung (englischer Originaltext): An issue was discovered in gradio-app/gradio, where the `/component_server` endpoint improperly allows the invocation of any method on a `Component` class with attacker-controlled arguments. Specifically, by exploiting the `move_resource_to_block_cache()` method of the `Block` class, an attacker can copy any file on the filesystem to a temporary directory and subsequently retrieve it. This vulnerability enables unauthorized local file read access, posing a significant risk especially when the ap",
   "Aktualisieren Sie Gradio so schnell wie möglich auf eine Version, die von CVE-2024-1561 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-1561 (Gradio)",
   "An issue was discovered in gradio-app/gradio, where the `/component_server` endpoint improperly allows the invocation of any method on a `Component` class with attacker-controlled arguments. Specifically, by exploiting the `move_resource_to_block_cache()` method of the `Block` class, an attacker can copy any file on the filesystem to a temporary directory and subsequently retrieve it. This vulnerability enables unauthorized local file read access, posing a significant risk especially when the ap",
   "Upgrade Gradio to a version not affected by CVE-2024-1561 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-1561 (Gradio)",
   "Descripción de NVD (texto original en inglés): An issue was discovered in gradio-app/gradio, where the `/component_server` endpoint improperly allows the invocation of any method on a `Component` class with attacker-controlled arguments. Specifically, by exploiting the `move_resource_to_block_cache()` method of the `Block` class, an attacker can copy any file on the filesystem to a temporary directory and subsequently retrieve it. This vulnerability enables unauthorized local file read access, posing a significant risk especially when the ap",
   "Actualice Gradio lo antes posible a una versión no afectada por CVE-2024-1561 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-1561 (Gradio)",
   "Description NVD (texte original en anglais) : An issue was discovered in gradio-app/gradio, where the `/component_server` endpoint improperly allows the invocation of any method on a `Component` class with attacker-controlled arguments. Specifically, by exploiting the `move_resource_to_block_cache()` method of the `Block` class, an attacker can copy any file on the filesystem to a temporary directory and subsequently retrieve it. This vulnerability enables unauthorized local file read access, posing a significant risk especially when the ap",
   "Mettez à niveau Gradio dès que possible vers une version non affectée par CVE-2024-1561 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-1561 (Gradio)",
   "Descrizione NVD (testo originale in inglese): An issue was discovered in gradio-app/gradio, where the `/component_server` endpoint improperly allows the invocation of any method on a `Component` class with attacker-controlled arguments. Specifically, by exploiting the `move_resource_to_block_cache()` method of the `Block` class, an attacker can copy any file on the filesystem to a temporary directory and subsequently retrieve it. This vulnerability enables unauthorized local file read access, posing a significant risk especially when the ap",
   "Aggiorna Gradio il prima possibile a una versione non interessata da CVE-2024-1561 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-1561 (Gradio)",
   "NVDの説明（英語原文）: An issue was discovered in gradio-app/gradio, where the `/component_server` endpoint improperly allows the invocation of any method on a `Component` class with attacker-controlled arguments. Specifically, by exploiting the `move_resource_to_block_cache()` method of the `Block` class, an attacker can copy any file on the filesystem to a temporary directory and subsequently retrieve it. This vulnerability enables unauthorized local file read access, posing a significant risk especially when the ap",
   "Gradio を CVE-2024-1561 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-1561 (Gradio)",
   "NVD 설명(영어 원문): An issue was discovered in gradio-app/gradio, where the `/component_server` endpoint improperly allows the invocation of any method on a `Component` class with attacker-controlled arguments. Specifically, by exploiting the `move_resource_to_block_cache()` method of the `Block` class, an attacker can copy any file on the filesystem to a temporary directory and subsequently retrieve it. This vulnerability enables unauthorized local file read access, posing a significant risk especially when the ap",
   "Gradio을(를) CVE-2024-1561의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-1561 (Gradio)",
   "Descrição do NVD (texto original em inglês): An issue was discovered in gradio-app/gradio, where the `/component_server` endpoint improperly allows the invocation of any method on a `Component` class with attacker-controlled arguments. Specifically, by exploiting the `move_resource_to_block_cache()` method of the `Block` class, an attacker can copy any file on the filesystem to a temporary directory and subsequently retrieve it. This vulnerability enables unauthorized local file read access, posing a significant risk especially when the ap",
   "Atualize o Gradio o quanto antes para uma versão não afetada por CVE-2024-1561 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-1561（Gradio）",
   "NVD 说明（英文原文）：An issue was discovered in gradio-app/gradio, where the `/component_server` endpoint improperly allows the invocation of any method on a `Component` class with attacker-controlled arguments. Specifically, by exploiting the `move_resource_to_block_cache()` method of the `Block` class, an attacker can copy any file on the filesystem to a temporary directory and subsequently retrieve it. This vulnerability enables unauthorized local file read access, posing a significant risk especially when the ap",
   "请尽快将 Gradio 升级到不受 CVE-2024-1561 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-1561（Gradio）",
   "NVD 說明（英文原文）：An issue was discovered in gradio-app/gradio, where the `/component_server` endpoint improperly allows the invocation of any method on a `Component` class with attacker-controlled arguments. Specifically, by exploiting the `move_resource_to_block_cache()` method of the `Block` class, an attacker can copy any file on the filesystem to a temporary directory and subsequently retrieve it. This vulnerability enables unauthorized local file read access, posing a significant risk especially when the ap",
   "請儘快將 Gradio 升級到不受 CVE-2024-1561 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:gradio-noauth:CVE-2024-1728": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-1728 (Gradio)",
   "NVD-Beschreibung (englischer Originaltext): gradio-app/gradio is vulnerable to a local file inclusion vulnerability due to improper validation of user-supplied input in the UploadButton component. Attackers can exploit this vulnerability to read arbitrary files on the filesystem, such as private SSH keys, by manipulating the file path in the request to the `/queue/join` endpoint. This issue could potentially lead to remote code execution. The vulnerability is present in the handling of file upload paths, allowing attackers to redirect fil",
   "Aktualisieren Sie Gradio so schnell wie möglich auf eine Version, die von CVE-2024-1728 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-1728 (Gradio)",
   "gradio-app/gradio is vulnerable to a local file inclusion vulnerability due to improper validation of user-supplied input in the UploadButton component. Attackers can exploit this vulnerability to read arbitrary files on the filesystem, such as private SSH keys, by manipulating the file path in the request to the `/queue/join` endpoint. This issue could potentially lead to remote code execution. The vulnerability is present in the handling of file upload paths, allowing attackers to redirect fil",
   "Upgrade Gradio to a version not affected by CVE-2024-1728 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-1728 (Gradio)",
   "Descripción de NVD (texto original en inglés): gradio-app/gradio is vulnerable to a local file inclusion vulnerability due to improper validation of user-supplied input in the UploadButton component. Attackers can exploit this vulnerability to read arbitrary files on the filesystem, such as private SSH keys, by manipulating the file path in the request to the `/queue/join` endpoint. This issue could potentially lead to remote code execution. The vulnerability is present in the handling of file upload paths, allowing attackers to redirect fil",
   "Actualice Gradio lo antes posible a una versión no afectada por CVE-2024-1728 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-1728 (Gradio)",
   "Description NVD (texte original en anglais) : gradio-app/gradio is vulnerable to a local file inclusion vulnerability due to improper validation of user-supplied input in the UploadButton component. Attackers can exploit this vulnerability to read arbitrary files on the filesystem, such as private SSH keys, by manipulating the file path in the request to the `/queue/join` endpoint. This issue could potentially lead to remote code execution. The vulnerability is present in the handling of file upload paths, allowing attackers to redirect fil",
   "Mettez à niveau Gradio dès que possible vers une version non affectée par CVE-2024-1728 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-1728 (Gradio)",
   "Descrizione NVD (testo originale in inglese): gradio-app/gradio is vulnerable to a local file inclusion vulnerability due to improper validation of user-supplied input in the UploadButton component. Attackers can exploit this vulnerability to read arbitrary files on the filesystem, such as private SSH keys, by manipulating the file path in the request to the `/queue/join` endpoint. This issue could potentially lead to remote code execution. The vulnerability is present in the handling of file upload paths, allowing attackers to redirect fil",
   "Aggiorna Gradio il prima possibile a una versione non interessata da CVE-2024-1728 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-1728 (Gradio)",
   "NVDの説明（英語原文）: gradio-app/gradio is vulnerable to a local file inclusion vulnerability due to improper validation of user-supplied input in the UploadButton component. Attackers can exploit this vulnerability to read arbitrary files on the filesystem, such as private SSH keys, by manipulating the file path in the request to the `/queue/join` endpoint. This issue could potentially lead to remote code execution. The vulnerability is present in the handling of file upload paths, allowing attackers to redirect fil",
   "Gradio を CVE-2024-1728 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-1728 (Gradio)",
   "NVD 설명(영어 원문): gradio-app/gradio is vulnerable to a local file inclusion vulnerability due to improper validation of user-supplied input in the UploadButton component. Attackers can exploit this vulnerability to read arbitrary files on the filesystem, such as private SSH keys, by manipulating the file path in the request to the `/queue/join` endpoint. This issue could potentially lead to remote code execution. The vulnerability is present in the handling of file upload paths, allowing attackers to redirect fil",
   "Gradio을(를) CVE-2024-1728의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-1728 (Gradio)",
   "Descrição do NVD (texto original em inglês): gradio-app/gradio is vulnerable to a local file inclusion vulnerability due to improper validation of user-supplied input in the UploadButton component. Attackers can exploit this vulnerability to read arbitrary files on the filesystem, such as private SSH keys, by manipulating the file path in the request to the `/queue/join` endpoint. This issue could potentially lead to remote code execution. The vulnerability is present in the handling of file upload paths, allowing attackers to redirect fil",
   "Atualize o Gradio o quanto antes para uma versão não afetada por CVE-2024-1728 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-1728（Gradio）",
   "NVD 说明（英文原文）：gradio-app/gradio is vulnerable to a local file inclusion vulnerability due to improper validation of user-supplied input in the UploadButton component. Attackers can exploit this vulnerability to read arbitrary files on the filesystem, such as private SSH keys, by manipulating the file path in the request to the `/queue/join` endpoint. This issue could potentially lead to remote code execution. The vulnerability is present in the handling of file upload paths, allowing attackers to redirect fil",
   "请尽快将 Gradio 升级到不受 CVE-2024-1728 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-1728（Gradio）",
   "NVD 說明（英文原文）：gradio-app/gradio is vulnerable to a local file inclusion vulnerability due to improper validation of user-supplied input in the UploadButton component. Attackers can exploit this vulnerability to read arbitrary files on the filesystem, such as private SSH keys, by manipulating the file path in the request to the `/queue/join` endpoint. This issue could potentially lead to remote code execution. The vulnerability is present in the handling of file upload paths, allowing attackers to redirect fil",
   "請儘快將 Gradio 升級到不受 CVE-2024-1728 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:gradio-noauth:CVE-2024-34510": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-34510 (Gradio)",
   "NVD-Beschreibung (englischer Originaltext): Gradio before 4.20 allows credential leakage on Windows.",
   "Aktualisieren Sie Gradio so schnell wie möglich auf eine Version, die von CVE-2024-34510 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-34510 (Gradio)",
   "Gradio before 4.20 allows credential leakage on Windows.",
   "Upgrade Gradio to a version not affected by CVE-2024-34510 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-34510 (Gradio)",
   "Descripción de NVD (texto original en inglés): Gradio before 4.20 allows credential leakage on Windows.",
   "Actualice Gradio lo antes posible a una versión no afectada por CVE-2024-34510 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-34510 (Gradio)",
   "Description NVD (texte original en anglais) : Gradio before 4.20 allows credential leakage on Windows.",
   "Mettez à niveau Gradio dès que possible vers une version non affectée par CVE-2024-34510 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-34510 (Gradio)",
   "Descrizione NVD (testo originale in inglese): Gradio before 4.20 allows credential leakage on Windows.",
   "Aggiorna Gradio il prima possibile a una versione non interessata da CVE-2024-34510 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-34510 (Gradio)",
   "NVDの説明（英語原文）: Gradio before 4.20 allows credential leakage on Windows.",
   "Gradio を CVE-2024-34510 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-34510 (Gradio)",
   "NVD 설명(영어 원문): Gradio before 4.20 allows credential leakage on Windows.",
   "Gradio을(를) CVE-2024-34510의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-34510 (Gradio)",
   "Descrição do NVD (texto original em inglês): Gradio before 4.20 allows credential leakage on Windows.",
   "Atualize o Gradio o quanto antes para uma versão não afetada por CVE-2024-34510 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-34510（Gradio）",
   "NVD 说明（英文原文）：Gradio before 4.20 allows credential leakage on Windows.",
   "请尽快将 Gradio 升级到不受 CVE-2024-34510 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-34510（Gradio）",
   "NVD 說明（英文原文）：Gradio before 4.20 allows credential leakage on Windows.",
   "請儘快將 Gradio 升級到不受 CVE-2024-34510 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:gradio-noauth:CVE-2024-39236": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-39236 (Gradio)",
   "NVD-Beschreibung (englischer Originaltext): Gradio v4.36.1 was discovered to contain a code injection vulnerability via the component /gradio/component_meta.py. This vulnerability is triggered via a crafted input. NOTE: the supplier disputes this because the report is about a user attacking himself.",
   "Aktualisieren Sie Gradio so schnell wie möglich auf eine Version, die von CVE-2024-39236 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-39236 (Gradio)",
   "Gradio v4.36.1 was discovered to contain a code injection vulnerability via the component /gradio/component_meta.py. This vulnerability is triggered via a crafted input. NOTE: the supplier disputes this because the report is about a user attacking himself.",
   "Upgrade Gradio to a version not affected by CVE-2024-39236 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-39236 (Gradio)",
   "Descripción de NVD (texto original en inglés): Gradio v4.36.1 was discovered to contain a code injection vulnerability via the component /gradio/component_meta.py. This vulnerability is triggered via a crafted input. NOTE: the supplier disputes this because the report is about a user attacking himself.",
   "Actualice Gradio lo antes posible a una versión no afectada por CVE-2024-39236 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-39236 (Gradio)",
   "Description NVD (texte original en anglais) : Gradio v4.36.1 was discovered to contain a code injection vulnerability via the component /gradio/component_meta.py. This vulnerability is triggered via a crafted input. NOTE: the supplier disputes this because the report is about a user attacking himself.",
   "Mettez à niveau Gradio dès que possible vers une version non affectée par CVE-2024-39236 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-39236 (Gradio)",
   "Descrizione NVD (testo originale in inglese): Gradio v4.36.1 was discovered to contain a code injection vulnerability via the component /gradio/component_meta.py. This vulnerability is triggered via a crafted input. NOTE: the supplier disputes this because the report is about a user attacking himself.",
   "Aggiorna Gradio il prima possibile a una versione non interessata da CVE-2024-39236 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-39236 (Gradio)",
   "NVDの説明（英語原文）: Gradio v4.36.1 was discovered to contain a code injection vulnerability via the component /gradio/component_meta.py. This vulnerability is triggered via a crafted input. NOTE: the supplier disputes this because the report is about a user attacking himself.",
   "Gradio を CVE-2024-39236 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-39236 (Gradio)",
   "NVD 설명(영어 원문): Gradio v4.36.1 was discovered to contain a code injection vulnerability via the component /gradio/component_meta.py. This vulnerability is triggered via a crafted input. NOTE: the supplier disputes this because the report is about a user attacking himself.",
   "Gradio을(를) CVE-2024-39236의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-39236 (Gradio)",
   "Descrição do NVD (texto original em inglês): Gradio v4.36.1 was discovered to contain a code injection vulnerability via the component /gradio/component_meta.py. This vulnerability is triggered via a crafted input. NOTE: the supplier disputes this because the report is about a user attacking himself.",
   "Atualize o Gradio o quanto antes para uma versão não afetada por CVE-2024-39236 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-39236（Gradio）",
   "NVD 说明（英文原文）：Gradio v4.36.1 was discovered to contain a code injection vulnerability via the component /gradio/component_meta.py. This vulnerability is triggered via a crafted input. NOTE: the supplier disputes this because the report is about a user attacking himself.",
   "请尽快将 Gradio 升级到不受 CVE-2024-39236 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-39236（Gradio）",
   "NVD 說明（英文原文）：Gradio v4.36.1 was discovered to contain a code injection vulnerability via the component /gradio/component_meta.py. This vulnerability is triggered via a crafted input. NOTE: the supplier disputes this because the report is about a user attacking himself.",
   "請儘快將 Gradio 升級到不受 CVE-2024-39236 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:gradio-noauth:CVE-2024-4253": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-4253 (Gradio)",
   "NVD-Beschreibung (englischer Originaltext): A command injection vulnerability exists in the gradio-app/gradio repository, specifically within the 'test-functional.yml' workflow. The vulnerability arises due to improper neutralization of special elements used in a command, allowing for unauthorized modification of the base repository or secrets exfiltration. The issue affects versions up to and including '@gradio/video@0.6.12'. The flaw is present in the workflow's handling of GitHub context information, where it echoes the full name of th",
   "Aktualisieren Sie Gradio so schnell wie möglich auf eine Version, die von CVE-2024-4253 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-4253 (Gradio)",
   "A command injection vulnerability exists in the gradio-app/gradio repository, specifically within the 'test-functional.yml' workflow. The vulnerability arises due to improper neutralization of special elements used in a command, allowing for unauthorized modification of the base repository or secrets exfiltration. The issue affects versions up to and including '@gradio/video@0.6.12'. The flaw is present in the workflow's handling of GitHub context information, where it echoes the full name of th",
   "Upgrade Gradio to a version not affected by CVE-2024-4253 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-4253 (Gradio)",
   "Descripción de NVD (texto original en inglés): A command injection vulnerability exists in the gradio-app/gradio repository, specifically within the 'test-functional.yml' workflow. The vulnerability arises due to improper neutralization of special elements used in a command, allowing for unauthorized modification of the base repository or secrets exfiltration. The issue affects versions up to and including '@gradio/video@0.6.12'. The flaw is present in the workflow's handling of GitHub context information, where it echoes the full name of th",
   "Actualice Gradio lo antes posible a una versión no afectada por CVE-2024-4253 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-4253 (Gradio)",
   "Description NVD (texte original en anglais) : A command injection vulnerability exists in the gradio-app/gradio repository, specifically within the 'test-functional.yml' workflow. The vulnerability arises due to improper neutralization of special elements used in a command, allowing for unauthorized modification of the base repository or secrets exfiltration. The issue affects versions up to and including '@gradio/video@0.6.12'. The flaw is present in the workflow's handling of GitHub context information, where it echoes the full name of th",
   "Mettez à niveau Gradio dès que possible vers une version non affectée par CVE-2024-4253 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-4253 (Gradio)",
   "Descrizione NVD (testo originale in inglese): A command injection vulnerability exists in the gradio-app/gradio repository, specifically within the 'test-functional.yml' workflow. The vulnerability arises due to improper neutralization of special elements used in a command, allowing for unauthorized modification of the base repository or secrets exfiltration. The issue affects versions up to and including '@gradio/video@0.6.12'. The flaw is present in the workflow's handling of GitHub context information, where it echoes the full name of th",
   "Aggiorna Gradio il prima possibile a una versione non interessata da CVE-2024-4253 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-4253 (Gradio)",
   "NVDの説明（英語原文）: A command injection vulnerability exists in the gradio-app/gradio repository, specifically within the 'test-functional.yml' workflow. The vulnerability arises due to improper neutralization of special elements used in a command, allowing for unauthorized modification of the base repository or secrets exfiltration. The issue affects versions up to and including '@gradio/video@0.6.12'. The flaw is present in the workflow's handling of GitHub context information, where it echoes the full name of th",
   "Gradio を CVE-2024-4253 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-4253 (Gradio)",
   "NVD 설명(영어 원문): A command injection vulnerability exists in the gradio-app/gradio repository, specifically within the 'test-functional.yml' workflow. The vulnerability arises due to improper neutralization of special elements used in a command, allowing for unauthorized modification of the base repository or secrets exfiltration. The issue affects versions up to and including '@gradio/video@0.6.12'. The flaw is present in the workflow's handling of GitHub context information, where it echoes the full name of th",
   "Gradio을(를) CVE-2024-4253의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-4253 (Gradio)",
   "Descrição do NVD (texto original em inglês): A command injection vulnerability exists in the gradio-app/gradio repository, specifically within the 'test-functional.yml' workflow. The vulnerability arises due to improper neutralization of special elements used in a command, allowing for unauthorized modification of the base repository or secrets exfiltration. The issue affects versions up to and including '@gradio/video@0.6.12'. The flaw is present in the workflow's handling of GitHub context information, where it echoes the full name of th",
   "Atualize o Gradio o quanto antes para uma versão não afetada por CVE-2024-4253 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-4253（Gradio）",
   "NVD 说明（英文原文）：A command injection vulnerability exists in the gradio-app/gradio repository, specifically within the 'test-functional.yml' workflow. The vulnerability arises due to improper neutralization of special elements used in a command, allowing for unauthorized modification of the base repository or secrets exfiltration. The issue affects versions up to and including '@gradio/video@0.6.12'. The flaw is present in the workflow's handling of GitHub context information, where it echoes the full name of th",
   "请尽快将 Gradio 升级到不受 CVE-2024-4253 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-4253（Gradio）",
   "NVD 說明（英文原文）：A command injection vulnerability exists in the gradio-app/gradio repository, specifically within the 'test-functional.yml' workflow. The vulnerability arises due to improper neutralization of special elements used in a command, allowing for unauthorized modification of the base repository or secrets exfiltration. The issue affects versions up to and including '@gradio/video@0.6.12'. The flaw is present in the workflow's handling of GitHub context information, where it echoes the full name of th",
   "請儘快將 Gradio 升級到不受 CVE-2024-4253 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:gradio-noauth:CVE-2024-4254": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-4254 (Gradio)",
   "NVD-Beschreibung (englischer Originaltext): The 'deploy-website.yml' workflow in the gradio-app/gradio repository, specifically in the 'main' branch, is vulnerable to secrets exfiltration due to improper authorization. The vulnerability arises from the workflow's explicit checkout and execution of code from a fork, which is unsafe as it allows the running of untrusted code in an environment with access to push to the base repository and access secrets. This flaw could lead to the exfiltration of sensitive secrets such as GITHUB_TOKEN, HF_",
   "Aktualisieren Sie Gradio so schnell wie möglich auf eine Version, die von CVE-2024-4254 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-4254 (Gradio)",
   "The 'deploy-website.yml' workflow in the gradio-app/gradio repository, specifically in the 'main' branch, is vulnerable to secrets exfiltration due to improper authorization. The vulnerability arises from the workflow's explicit checkout and execution of code from a fork, which is unsafe as it allows the running of untrusted code in an environment with access to push to the base repository and access secrets. This flaw could lead to the exfiltration of sensitive secrets such as GITHUB_TOKEN, HF_",
   "Upgrade Gradio to a version not affected by CVE-2024-4254 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-4254 (Gradio)",
   "Descripción de NVD (texto original en inglés): The 'deploy-website.yml' workflow in the gradio-app/gradio repository, specifically in the 'main' branch, is vulnerable to secrets exfiltration due to improper authorization. The vulnerability arises from the workflow's explicit checkout and execution of code from a fork, which is unsafe as it allows the running of untrusted code in an environment with access to push to the base repository and access secrets. This flaw could lead to the exfiltration of sensitive secrets such as GITHUB_TOKEN, HF_",
   "Actualice Gradio lo antes posible a una versión no afectada por CVE-2024-4254 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-4254 (Gradio)",
   "Description NVD (texte original en anglais) : The 'deploy-website.yml' workflow in the gradio-app/gradio repository, specifically in the 'main' branch, is vulnerable to secrets exfiltration due to improper authorization. The vulnerability arises from the workflow's explicit checkout and execution of code from a fork, which is unsafe as it allows the running of untrusted code in an environment with access to push to the base repository and access secrets. This flaw could lead to the exfiltration of sensitive secrets such as GITHUB_TOKEN, HF_",
   "Mettez à niveau Gradio dès que possible vers une version non affectée par CVE-2024-4254 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-4254 (Gradio)",
   "Descrizione NVD (testo originale in inglese): The 'deploy-website.yml' workflow in the gradio-app/gradio repository, specifically in the 'main' branch, is vulnerable to secrets exfiltration due to improper authorization. The vulnerability arises from the workflow's explicit checkout and execution of code from a fork, which is unsafe as it allows the running of untrusted code in an environment with access to push to the base repository and access secrets. This flaw could lead to the exfiltration of sensitive secrets such as GITHUB_TOKEN, HF_",
   "Aggiorna Gradio il prima possibile a una versione non interessata da CVE-2024-4254 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-4254 (Gradio)",
   "NVDの説明（英語原文）: The 'deploy-website.yml' workflow in the gradio-app/gradio repository, specifically in the 'main' branch, is vulnerable to secrets exfiltration due to improper authorization. The vulnerability arises from the workflow's explicit checkout and execution of code from a fork, which is unsafe as it allows the running of untrusted code in an environment with access to push to the base repository and access secrets. This flaw could lead to the exfiltration of sensitive secrets such as GITHUB_TOKEN, HF_",
   "Gradio を CVE-2024-4254 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-4254 (Gradio)",
   "NVD 설명(영어 원문): The 'deploy-website.yml' workflow in the gradio-app/gradio repository, specifically in the 'main' branch, is vulnerable to secrets exfiltration due to improper authorization. The vulnerability arises from the workflow's explicit checkout and execution of code from a fork, which is unsafe as it allows the running of untrusted code in an environment with access to push to the base repository and access secrets. This flaw could lead to the exfiltration of sensitive secrets such as GITHUB_TOKEN, HF_",
   "Gradio을(를) CVE-2024-4254의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-4254 (Gradio)",
   "Descrição do NVD (texto original em inglês): The 'deploy-website.yml' workflow in the gradio-app/gradio repository, specifically in the 'main' branch, is vulnerable to secrets exfiltration due to improper authorization. The vulnerability arises from the workflow's explicit checkout and execution of code from a fork, which is unsafe as it allows the running of untrusted code in an environment with access to push to the base repository and access secrets. This flaw could lead to the exfiltration of sensitive secrets such as GITHUB_TOKEN, HF_",
   "Atualize o Gradio o quanto antes para uma versão não afetada por CVE-2024-4254 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-4254（Gradio）",
   "NVD 说明（英文原文）：The 'deploy-website.yml' workflow in the gradio-app/gradio repository, specifically in the 'main' branch, is vulnerable to secrets exfiltration due to improper authorization. The vulnerability arises from the workflow's explicit checkout and execution of code from a fork, which is unsafe as it allows the running of untrusted code in an environment with access to push to the base repository and access secrets. This flaw could lead to the exfiltration of sensitive secrets such as GITHUB_TOKEN, HF_",
   "请尽快将 Gradio 升级到不受 CVE-2024-4254 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-4254（Gradio）",
   "NVD 說明（英文原文）：The 'deploy-website.yml' workflow in the gradio-app/gradio repository, specifically in the 'main' branch, is vulnerable to secrets exfiltration due to improper authorization. The vulnerability arises from the workflow's explicit checkout and execution of code from a fork, which is unsafe as it allows the running of untrusted code in an environment with access to push to the base repository and access secrets. This flaw could lead to the exfiltration of sensitive secrets such as GITHUB_TOKEN, HF_",
   "請儘快將 Gradio 升級到不受 CVE-2024-4254 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:gradio-noauth:CVE-2024-4325": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-4325 (Gradio)",
   "NVD-Beschreibung (englischer Originaltext): A Server-Side Request Forgery (SSRF) vulnerability exists in the gradio-app/gradio version 4.21.0, specifically within the `/queue/join` endpoint and the `save_url_to_cache` function. The vulnerability arises when the `path` value, obtained from the user and expected to be a URL, is used to make an HTTP request without sufficient validation checks. This flaw allows an attacker to send crafted requests that could lead to unauthorized access to the local network or the AWS metadata endpoint, there",
   "Aktualisieren Sie Gradio so schnell wie möglich auf eine Version, die von CVE-2024-4325 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-4325 (Gradio)",
   "A Server-Side Request Forgery (SSRF) vulnerability exists in the gradio-app/gradio version 4.21.0, specifically within the `/queue/join` endpoint and the `save_url_to_cache` function. The vulnerability arises when the `path` value, obtained from the user and expected to be a URL, is used to make an HTTP request without sufficient validation checks. This flaw allows an attacker to send crafted requests that could lead to unauthorized access to the local network or the AWS metadata endpoint, there",
   "Upgrade Gradio to a version not affected by CVE-2024-4325 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-4325 (Gradio)",
   "Descripción de NVD (texto original en inglés): A Server-Side Request Forgery (SSRF) vulnerability exists in the gradio-app/gradio version 4.21.0, specifically within the `/queue/join` endpoint and the `save_url_to_cache` function. The vulnerability arises when the `path` value, obtained from the user and expected to be a URL, is used to make an HTTP request without sufficient validation checks. This flaw allows an attacker to send crafted requests that could lead to unauthorized access to the local network or the AWS metadata endpoint, there",
   "Actualice Gradio lo antes posible a una versión no afectada por CVE-2024-4325 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-4325 (Gradio)",
   "Description NVD (texte original en anglais) : A Server-Side Request Forgery (SSRF) vulnerability exists in the gradio-app/gradio version 4.21.0, specifically within the `/queue/join` endpoint and the `save_url_to_cache` function. The vulnerability arises when the `path` value, obtained from the user and expected to be a URL, is used to make an HTTP request without sufficient validation checks. This flaw allows an attacker to send crafted requests that could lead to unauthorized access to the local network or the AWS metadata endpoint, there",
   "Mettez à niveau Gradio dès que possible vers une version non affectée par CVE-2024-4325 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-4325 (Gradio)",
   "Descrizione NVD (testo originale in inglese): A Server-Side Request Forgery (SSRF) vulnerability exists in the gradio-app/gradio version 4.21.0, specifically within the `/queue/join` endpoint and the `save_url_to_cache` function. The vulnerability arises when the `path` value, obtained from the user and expected to be a URL, is used to make an HTTP request without sufficient validation checks. This flaw allows an attacker to send crafted requests that could lead to unauthorized access to the local network or the AWS metadata endpoint, there",
   "Aggiorna Gradio il prima possibile a una versione non interessata da CVE-2024-4325 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-4325 (Gradio)",
   "NVDの説明（英語原文）: A Server-Side Request Forgery (SSRF) vulnerability exists in the gradio-app/gradio version 4.21.0, specifically within the `/queue/join` endpoint and the `save_url_to_cache` function. The vulnerability arises when the `path` value, obtained from the user and expected to be a URL, is used to make an HTTP request without sufficient validation checks. This flaw allows an attacker to send crafted requests that could lead to unauthorized access to the local network or the AWS metadata endpoint, there",
   "Gradio を CVE-2024-4325 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-4325 (Gradio)",
   "NVD 설명(영어 원문): A Server-Side Request Forgery (SSRF) vulnerability exists in the gradio-app/gradio version 4.21.0, specifically within the `/queue/join` endpoint and the `save_url_to_cache` function. The vulnerability arises when the `path` value, obtained from the user and expected to be a URL, is used to make an HTTP request without sufficient validation checks. This flaw allows an attacker to send crafted requests that could lead to unauthorized access to the local network or the AWS metadata endpoint, there",
   "Gradio을(를) CVE-2024-4325의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-4325 (Gradio)",
   "Descrição do NVD (texto original em inglês): A Server-Side Request Forgery (SSRF) vulnerability exists in the gradio-app/gradio version 4.21.0, specifically within the `/queue/join` endpoint and the `save_url_to_cache` function. The vulnerability arises when the `path` value, obtained from the user and expected to be a URL, is used to make an HTTP request without sufficient validation checks. This flaw allows an attacker to send crafted requests that could lead to unauthorized access to the local network or the AWS metadata endpoint, there",
   "Atualize o Gradio o quanto antes para uma versão não afetada por CVE-2024-4325 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-4325（Gradio）",
   "NVD 说明（英文原文）：A Server-Side Request Forgery (SSRF) vulnerability exists in the gradio-app/gradio version 4.21.0, specifically within the `/queue/join` endpoint and the `save_url_to_cache` function. The vulnerability arises when the `path` value, obtained from the user and expected to be a URL, is used to make an HTTP request without sufficient validation checks. This flaw allows an attacker to send crafted requests that could lead to unauthorized access to the local network or the AWS metadata endpoint, there",
   "请尽快将 Gradio 升级到不受 CVE-2024-4325 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-4325（Gradio）",
   "NVD 說明（英文原文）：A Server-Side Request Forgery (SSRF) vulnerability exists in the gradio-app/gradio version 4.21.0, specifically within the `/queue/join` endpoint and the `save_url_to_cache` function. The vulnerability arises when the `path` value, obtained from the user and expected to be a URL, is used to make an HTTP request without sufficient validation checks. This flaw allows an attacker to send crafted requests that could lead to unauthorized access to the local network or the AWS metadata endpoint, there",
   "請儘快將 Gradio 升級到不受 CVE-2024-4325 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:gradio-noauth:CVE-2024-47084": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-47084 (Gradio)",
   "NVD-Beschreibung (englischer Originaltext): Gradio is an open-source Python package designed for quick prototyping. This vulnerability is related to **CORS origin validation**, where the Gradio server fails to validate the request origin when a cookie is present. This allows an attacker’s website to make unauthorized requests to a local Gradio server. Potentially, attackers can upload files, steal authentication tokens, and access user data if the victim visits a malicious website while logged into Gradio. This impacts users who have depl",
   "Aktualisieren Sie Gradio so schnell wie möglich auf eine Version, die von CVE-2024-47084 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-47084 (Gradio)",
   "Gradio is an open-source Python package designed for quick prototyping. This vulnerability is related to **CORS origin validation**, where the Gradio server fails to validate the request origin when a cookie is present. This allows an attacker’s website to make unauthorized requests to a local Gradio server. Potentially, attackers can upload files, steal authentication tokens, and access user data if the victim visits a malicious website while logged into Gradio. This impacts users who have depl",
   "Upgrade Gradio to a version not affected by CVE-2024-47084 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-47084 (Gradio)",
   "Descripción de NVD (texto original en inglés): Gradio is an open-source Python package designed for quick prototyping. This vulnerability is related to **CORS origin validation**, where the Gradio server fails to validate the request origin when a cookie is present. This allows an attacker’s website to make unauthorized requests to a local Gradio server. Potentially, attackers can upload files, steal authentication tokens, and access user data if the victim visits a malicious website while logged into Gradio. This impacts users who have depl",
   "Actualice Gradio lo antes posible a una versión no afectada por CVE-2024-47084 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-47084 (Gradio)",
   "Description NVD (texte original en anglais) : Gradio is an open-source Python package designed for quick prototyping. This vulnerability is related to **CORS origin validation**, where the Gradio server fails to validate the request origin when a cookie is present. This allows an attacker’s website to make unauthorized requests to a local Gradio server. Potentially, attackers can upload files, steal authentication tokens, and access user data if the victim visits a malicious website while logged into Gradio. This impacts users who have depl",
   "Mettez à niveau Gradio dès que possible vers une version non affectée par CVE-2024-47084 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-47084 (Gradio)",
   "Descrizione NVD (testo originale in inglese): Gradio is an open-source Python package designed for quick prototyping. This vulnerability is related to **CORS origin validation**, where the Gradio server fails to validate the request origin when a cookie is present. This allows an attacker’s website to make unauthorized requests to a local Gradio server. Potentially, attackers can upload files, steal authentication tokens, and access user data if the victim visits a malicious website while logged into Gradio. This impacts users who have depl",
   "Aggiorna Gradio il prima possibile a una versione non interessata da CVE-2024-47084 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-47084 (Gradio)",
   "NVDの説明（英語原文）: Gradio is an open-source Python package designed for quick prototyping. This vulnerability is related to **CORS origin validation**, where the Gradio server fails to validate the request origin when a cookie is present. This allows an attacker’s website to make unauthorized requests to a local Gradio server. Potentially, attackers can upload files, steal authentication tokens, and access user data if the victim visits a malicious website while logged into Gradio. This impacts users who have depl",
   "Gradio を CVE-2024-47084 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-47084 (Gradio)",
   "NVD 설명(영어 원문): Gradio is an open-source Python package designed for quick prototyping. This vulnerability is related to **CORS origin validation**, where the Gradio server fails to validate the request origin when a cookie is present. This allows an attacker’s website to make unauthorized requests to a local Gradio server. Potentially, attackers can upload files, steal authentication tokens, and access user data if the victim visits a malicious website while logged into Gradio. This impacts users who have depl",
   "Gradio을(를) CVE-2024-47084의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-47084 (Gradio)",
   "Descrição do NVD (texto original em inglês): Gradio is an open-source Python package designed for quick prototyping. This vulnerability is related to **CORS origin validation**, where the Gradio server fails to validate the request origin when a cookie is present. This allows an attacker’s website to make unauthorized requests to a local Gradio server. Potentially, attackers can upload files, steal authentication tokens, and access user data if the victim visits a malicious website while logged into Gradio. This impacts users who have depl",
   "Atualize o Gradio o quanto antes para uma versão não afetada por CVE-2024-47084 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-47084（Gradio）",
   "NVD 说明（英文原文）：Gradio is an open-source Python package designed for quick prototyping. This vulnerability is related to **CORS origin validation**, where the Gradio server fails to validate the request origin when a cookie is present. This allows an attacker’s website to make unauthorized requests to a local Gradio server. Potentially, attackers can upload files, steal authentication tokens, and access user data if the victim visits a malicious website while logged into Gradio. This impacts users who have depl",
   "请尽快将 Gradio 升级到不受 CVE-2024-47084 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-47084（Gradio）",
   "NVD 說明（英文原文）：Gradio is an open-source Python package designed for quick prototyping. This vulnerability is related to **CORS origin validation**, where the Gradio server fails to validate the request origin when a cookie is present. This allows an attacker’s website to make unauthorized requests to a local Gradio server. Potentially, attackers can upload files, steal authentication tokens, and access user data if the victim visits a malicious website while logged into Gradio. This impacts users who have depl",
   "請儘快將 Gradio 升級到不受 CVE-2024-47084 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:gradio-noauth:CVE-2024-47167": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-47167 (Gradio)",
   "NVD-Beschreibung (englischer Originaltext): Gradio is an open-source Python package designed for quick prototyping. This vulnerability relates to **Server-Side Request Forgery (SSRF)** in the `/queue/join` endpoint. Gradio’s `async_save_url_to_cache` function allows attackers to force the Gradio server to send HTTP requests to user-controlled URLs. This could enable attackers to target internal servers or services within a local network and possibly exfiltrate data or cause unwanted internal requests. Additionally, the content from these ",
   "Aktualisieren Sie Gradio so schnell wie möglich auf eine Version, die von CVE-2024-47167 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-47167 (Gradio)",
   "Gradio is an open-source Python package designed for quick prototyping. This vulnerability relates to **Server-Side Request Forgery (SSRF)** in the `/queue/join` endpoint. Gradio’s `async_save_url_to_cache` function allows attackers to force the Gradio server to send HTTP requests to user-controlled URLs. This could enable attackers to target internal servers or services within a local network and possibly exfiltrate data or cause unwanted internal requests. Additionally, the content from these ",
   "Upgrade Gradio to a version not affected by CVE-2024-47167 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-47167 (Gradio)",
   "Descripción de NVD (texto original en inglés): Gradio is an open-source Python package designed for quick prototyping. This vulnerability relates to **Server-Side Request Forgery (SSRF)** in the `/queue/join` endpoint. Gradio’s `async_save_url_to_cache` function allows attackers to force the Gradio server to send HTTP requests to user-controlled URLs. This could enable attackers to target internal servers or services within a local network and possibly exfiltrate data or cause unwanted internal requests. Additionally, the content from these ",
   "Actualice Gradio lo antes posible a una versión no afectada por CVE-2024-47167 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-47167 (Gradio)",
   "Description NVD (texte original en anglais) : Gradio is an open-source Python package designed for quick prototyping. This vulnerability relates to **Server-Side Request Forgery (SSRF)** in the `/queue/join` endpoint. Gradio’s `async_save_url_to_cache` function allows attackers to force the Gradio server to send HTTP requests to user-controlled URLs. This could enable attackers to target internal servers or services within a local network and possibly exfiltrate data or cause unwanted internal requests. Additionally, the content from these ",
   "Mettez à niveau Gradio dès que possible vers une version non affectée par CVE-2024-47167 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-47167 (Gradio)",
   "Descrizione NVD (testo originale in inglese): Gradio is an open-source Python package designed for quick prototyping. This vulnerability relates to **Server-Side Request Forgery (SSRF)** in the `/queue/join` endpoint. Gradio’s `async_save_url_to_cache` function allows attackers to force the Gradio server to send HTTP requests to user-controlled URLs. This could enable attackers to target internal servers or services within a local network and possibly exfiltrate data or cause unwanted internal requests. Additionally, the content from these ",
   "Aggiorna Gradio il prima possibile a una versione non interessata da CVE-2024-47167 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-47167 (Gradio)",
   "NVDの説明（英語原文）: Gradio is an open-source Python package designed for quick prototyping. This vulnerability relates to **Server-Side Request Forgery (SSRF)** in the `/queue/join` endpoint. Gradio’s `async_save_url_to_cache` function allows attackers to force the Gradio server to send HTTP requests to user-controlled URLs. This could enable attackers to target internal servers or services within a local network and possibly exfiltrate data or cause unwanted internal requests. Additionally, the content from these ",
   "Gradio を CVE-2024-47167 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-47167 (Gradio)",
   "NVD 설명(영어 원문): Gradio is an open-source Python package designed for quick prototyping. This vulnerability relates to **Server-Side Request Forgery (SSRF)** in the `/queue/join` endpoint. Gradio’s `async_save_url_to_cache` function allows attackers to force the Gradio server to send HTTP requests to user-controlled URLs. This could enable attackers to target internal servers or services within a local network and possibly exfiltrate data or cause unwanted internal requests. Additionally, the content from these ",
   "Gradio을(를) CVE-2024-47167의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-47167 (Gradio)",
   "Descrição do NVD (texto original em inglês): Gradio is an open-source Python package designed for quick prototyping. This vulnerability relates to **Server-Side Request Forgery (SSRF)** in the `/queue/join` endpoint. Gradio’s `async_save_url_to_cache` function allows attackers to force the Gradio server to send HTTP requests to user-controlled URLs. This could enable attackers to target internal servers or services within a local network and possibly exfiltrate data or cause unwanted internal requests. Additionally, the content from these ",
   "Atualize o Gradio o quanto antes para uma versão não afetada por CVE-2024-47167 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-47167（Gradio）",
   "NVD 说明（英文原文）：Gradio is an open-source Python package designed for quick prototyping. This vulnerability relates to **Server-Side Request Forgery (SSRF)** in the `/queue/join` endpoint. Gradio’s `async_save_url_to_cache` function allows attackers to force the Gradio server to send HTTP requests to user-controlled URLs. This could enable attackers to target internal servers or services within a local network and possibly exfiltrate data or cause unwanted internal requests. Additionally, the content from these ",
   "请尽快将 Gradio 升级到不受 CVE-2024-47167 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-47167（Gradio）",
   "NVD 說明（英文原文）：Gradio is an open-source Python package designed for quick prototyping. This vulnerability relates to **Server-Side Request Forgery (SSRF)** in the `/queue/join` endpoint. Gradio’s `async_save_url_to_cache` function allows attackers to force the Gradio server to send HTTP requests to user-controlled URLs. This could enable attackers to target internal servers or services within a local network and possibly exfiltrate data or cause unwanted internal requests. Additionally, the content from these ",
   "請儘快將 Gradio 升級到不受 CVE-2024-47167 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:gradio-noauth:CVE-2024-47867": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-47867 (Gradio)",
   "NVD-Beschreibung (englischer Originaltext): Gradio is an open-source Python package designed for quick prototyping. This vulnerability is a **lack of integrity check** on the downloaded FRP client, which could potentially allow attackers to introduce malicious code. If an attacker gains access to the remote URL from which the FRP client is downloaded, they could modify the binary without detection, as the Gradio server does not verify the file's checksum or signature.  Any users utilizing the Gradio server's sharing mechanism that downloa",
   "Aktualisieren Sie Gradio so schnell wie möglich auf eine Version, die von CVE-2024-47867 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-47867 (Gradio)",
   "Gradio is an open-source Python package designed for quick prototyping. This vulnerability is a **lack of integrity check** on the downloaded FRP client, which could potentially allow attackers to introduce malicious code. If an attacker gains access to the remote URL from which the FRP client is downloaded, they could modify the binary without detection, as the Gradio server does not verify the file's checksum or signature.  Any users utilizing the Gradio server's sharing mechanism that downloa",
   "Upgrade Gradio to a version not affected by CVE-2024-47867 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-47867 (Gradio)",
   "Descripción de NVD (texto original en inglés): Gradio is an open-source Python package designed for quick prototyping. This vulnerability is a **lack of integrity check** on the downloaded FRP client, which could potentially allow attackers to introduce malicious code. If an attacker gains access to the remote URL from which the FRP client is downloaded, they could modify the binary without detection, as the Gradio server does not verify the file's checksum or signature.  Any users utilizing the Gradio server's sharing mechanism that downloa",
   "Actualice Gradio lo antes posible a una versión no afectada por CVE-2024-47867 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-47867 (Gradio)",
   "Description NVD (texte original en anglais) : Gradio is an open-source Python package designed for quick prototyping. This vulnerability is a **lack of integrity check** on the downloaded FRP client, which could potentially allow attackers to introduce malicious code. If an attacker gains access to the remote URL from which the FRP client is downloaded, they could modify the binary without detection, as the Gradio server does not verify the file's checksum or signature.  Any users utilizing the Gradio server's sharing mechanism that downloa",
   "Mettez à niveau Gradio dès que possible vers une version non affectée par CVE-2024-47867 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-47867 (Gradio)",
   "Descrizione NVD (testo originale in inglese): Gradio is an open-source Python package designed for quick prototyping. This vulnerability is a **lack of integrity check** on the downloaded FRP client, which could potentially allow attackers to introduce malicious code. If an attacker gains access to the remote URL from which the FRP client is downloaded, they could modify the binary without detection, as the Gradio server does not verify the file's checksum or signature.  Any users utilizing the Gradio server's sharing mechanism that downloa",
   "Aggiorna Gradio il prima possibile a una versione non interessata da CVE-2024-47867 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-47867 (Gradio)",
   "NVDの説明（英語原文）: Gradio is an open-source Python package designed for quick prototyping. This vulnerability is a **lack of integrity check** on the downloaded FRP client, which could potentially allow attackers to introduce malicious code. If an attacker gains access to the remote URL from which the FRP client is downloaded, they could modify the binary without detection, as the Gradio server does not verify the file's checksum or signature.  Any users utilizing the Gradio server's sharing mechanism that downloa",
   "Gradio を CVE-2024-47867 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-47867 (Gradio)",
   "NVD 설명(영어 원문): Gradio is an open-source Python package designed for quick prototyping. This vulnerability is a **lack of integrity check** on the downloaded FRP client, which could potentially allow attackers to introduce malicious code. If an attacker gains access to the remote URL from which the FRP client is downloaded, they could modify the binary without detection, as the Gradio server does not verify the file's checksum or signature.  Any users utilizing the Gradio server's sharing mechanism that downloa",
   "Gradio을(를) CVE-2024-47867의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-47867 (Gradio)",
   "Descrição do NVD (texto original em inglês): Gradio is an open-source Python package designed for quick prototyping. This vulnerability is a **lack of integrity check** on the downloaded FRP client, which could potentially allow attackers to introduce malicious code. If an attacker gains access to the remote URL from which the FRP client is downloaded, they could modify the binary without detection, as the Gradio server does not verify the file's checksum or signature.  Any users utilizing the Gradio server's sharing mechanism that downloa",
   "Atualize o Gradio o quanto antes para uma versão não afetada por CVE-2024-47867 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-47867（Gradio）",
   "NVD 说明（英文原文）：Gradio is an open-source Python package designed for quick prototyping. This vulnerability is a **lack of integrity check** on the downloaded FRP client, which could potentially allow attackers to introduce malicious code. If an attacker gains access to the remote URL from which the FRP client is downloaded, they could modify the binary without detection, as the Gradio server does not verify the file's checksum or signature.  Any users utilizing the Gradio server's sharing mechanism that downloa",
   "请尽快将 Gradio 升级到不受 CVE-2024-47867 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-47867（Gradio）",
   "NVD 說明（英文原文）：Gradio is an open-source Python package designed for quick prototyping. This vulnerability is a **lack of integrity check** on the downloaded FRP client, which could potentially allow attackers to introduce malicious code. If an attacker gains access to the remote URL from which the FRP client is downloaded, they could modify the binary without detection, as the Gradio server does not verify the file's checksum or signature.  Any users utilizing the Gradio server's sharing mechanism that downloa",
   "請儘快將 Gradio 升級到不受 CVE-2024-47867 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:gradio-noauth:CVE-2024-47868": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-47868 (Gradio)",
   "NVD-Beschreibung (englischer Originaltext): Gradio is an open-source Python package designed for quick prototyping. This is a **data validation vulnerability** affecting several Gradio components, which allows arbitrary file leaks through the post-processing step. Attackers can exploit these components by crafting requests that bypass expected input constraints. This issue could lead to sensitive files being exposed to unauthorized users, especially when combined with other vulnerabilities, such as issue TOB-GRADIO-15. The components most",
   "Aktualisieren Sie Gradio so schnell wie möglich auf eine Version, die von CVE-2024-47868 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-47868 (Gradio)",
   "Gradio is an open-source Python package designed for quick prototyping. This is a **data validation vulnerability** affecting several Gradio components, which allows arbitrary file leaks through the post-processing step. Attackers can exploit these components by crafting requests that bypass expected input constraints. This issue could lead to sensitive files being exposed to unauthorized users, especially when combined with other vulnerabilities, such as issue TOB-GRADIO-15. The components most",
   "Upgrade Gradio to a version not affected by CVE-2024-47868 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-47868 (Gradio)",
   "Descripción de NVD (texto original en inglés): Gradio is an open-source Python package designed for quick prototyping. This is a **data validation vulnerability** affecting several Gradio components, which allows arbitrary file leaks through the post-processing step. Attackers can exploit these components by crafting requests that bypass expected input constraints. This issue could lead to sensitive files being exposed to unauthorized users, especially when combined with other vulnerabilities, such as issue TOB-GRADIO-15. The components most",
   "Actualice Gradio lo antes posible a una versión no afectada por CVE-2024-47868 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-47868 (Gradio)",
   "Description NVD (texte original en anglais) : Gradio is an open-source Python package designed for quick prototyping. This is a **data validation vulnerability** affecting several Gradio components, which allows arbitrary file leaks through the post-processing step. Attackers can exploit these components by crafting requests that bypass expected input constraints. This issue could lead to sensitive files being exposed to unauthorized users, especially when combined with other vulnerabilities, such as issue TOB-GRADIO-15. The components most",
   "Mettez à niveau Gradio dès que possible vers une version non affectée par CVE-2024-47868 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-47868 (Gradio)",
   "Descrizione NVD (testo originale in inglese): Gradio is an open-source Python package designed for quick prototyping. This is a **data validation vulnerability** affecting several Gradio components, which allows arbitrary file leaks through the post-processing step. Attackers can exploit these components by crafting requests that bypass expected input constraints. This issue could lead to sensitive files being exposed to unauthorized users, especially when combined with other vulnerabilities, such as issue TOB-GRADIO-15. The components most",
   "Aggiorna Gradio il prima possibile a una versione non interessata da CVE-2024-47868 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-47868 (Gradio)",
   "NVDの説明（英語原文）: Gradio is an open-source Python package designed for quick prototyping. This is a **data validation vulnerability** affecting several Gradio components, which allows arbitrary file leaks through the post-processing step. Attackers can exploit these components by crafting requests that bypass expected input constraints. This issue could lead to sensitive files being exposed to unauthorized users, especially when combined with other vulnerabilities, such as issue TOB-GRADIO-15. The components most",
   "Gradio を CVE-2024-47868 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-47868 (Gradio)",
   "NVD 설명(영어 원문): Gradio is an open-source Python package designed for quick prototyping. This is a **data validation vulnerability** affecting several Gradio components, which allows arbitrary file leaks through the post-processing step. Attackers can exploit these components by crafting requests that bypass expected input constraints. This issue could lead to sensitive files being exposed to unauthorized users, especially when combined with other vulnerabilities, such as issue TOB-GRADIO-15. The components most",
   "Gradio을(를) CVE-2024-47868의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-47868 (Gradio)",
   "Descrição do NVD (texto original em inglês): Gradio is an open-source Python package designed for quick prototyping. This is a **data validation vulnerability** affecting several Gradio components, which allows arbitrary file leaks through the post-processing step. Attackers can exploit these components by crafting requests that bypass expected input constraints. This issue could lead to sensitive files being exposed to unauthorized users, especially when combined with other vulnerabilities, such as issue TOB-GRADIO-15. The components most",
   "Atualize o Gradio o quanto antes para uma versão não afetada por CVE-2024-47868 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-47868（Gradio）",
   "NVD 说明（英文原文）：Gradio is an open-source Python package designed for quick prototyping. This is a **data validation vulnerability** affecting several Gradio components, which allows arbitrary file leaks through the post-processing step. Attackers can exploit these components by crafting requests that bypass expected input constraints. This issue could lead to sensitive files being exposed to unauthorized users, especially when combined with other vulnerabilities, such as issue TOB-GRADIO-15. The components most",
   "请尽快将 Gradio 升级到不受 CVE-2024-47868 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-47868（Gradio）",
   "NVD 說明（英文原文）：Gradio is an open-source Python package designed for quick prototyping. This is a **data validation vulnerability** affecting several Gradio components, which allows arbitrary file leaks through the post-processing step. Attackers can exploit these components by crafting requests that bypass expected input constraints. This issue could lead to sensitive files being exposed to unauthorized users, especially when combined with other vulnerabilities, such as issue TOB-GRADIO-15. The components most",
   "請儘快將 Gradio 升級到不受 CVE-2024-47868 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:gradio-noauth:CVE-2024-47870": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-47870 (Gradio)",
   "NVD-Beschreibung (englischer Originaltext): Gradio is an open-source Python package designed for quick prototyping. This vulnerability involves a **race condition** in the `update_root_in_config` function, allowing an attacker to modify the `root` URL used by the Gradio frontend to communicate with the backend. By exploiting this flaw, an attacker can redirect user traffic to a malicious server. This could lead to the interception of sensitive data such as authentication credentials or uploaded files. This impacts all users who connect to",
   "Aktualisieren Sie Gradio so schnell wie möglich auf eine Version, die von CVE-2024-47870 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-47870 (Gradio)",
   "Gradio is an open-source Python package designed for quick prototyping. This vulnerability involves a **race condition** in the `update_root_in_config` function, allowing an attacker to modify the `root` URL used by the Gradio frontend to communicate with the backend. By exploiting this flaw, an attacker can redirect user traffic to a malicious server. This could lead to the interception of sensitive data such as authentication credentials or uploaded files. This impacts all users who connect to",
   "Upgrade Gradio to a version not affected by CVE-2024-47870 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-47870 (Gradio)",
   "Descripción de NVD (texto original en inglés): Gradio is an open-source Python package designed for quick prototyping. This vulnerability involves a **race condition** in the `update_root_in_config` function, allowing an attacker to modify the `root` URL used by the Gradio frontend to communicate with the backend. By exploiting this flaw, an attacker can redirect user traffic to a malicious server. This could lead to the interception of sensitive data such as authentication credentials or uploaded files. This impacts all users who connect to",
   "Actualice Gradio lo antes posible a una versión no afectada por CVE-2024-47870 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-47870 (Gradio)",
   "Description NVD (texte original en anglais) : Gradio is an open-source Python package designed for quick prototyping. This vulnerability involves a **race condition** in the `update_root_in_config` function, allowing an attacker to modify the `root` URL used by the Gradio frontend to communicate with the backend. By exploiting this flaw, an attacker can redirect user traffic to a malicious server. This could lead to the interception of sensitive data such as authentication credentials or uploaded files. This impacts all users who connect to",
   "Mettez à niveau Gradio dès que possible vers une version non affectée par CVE-2024-47870 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-47870 (Gradio)",
   "Descrizione NVD (testo originale in inglese): Gradio is an open-source Python package designed for quick prototyping. This vulnerability involves a **race condition** in the `update_root_in_config` function, allowing an attacker to modify the `root` URL used by the Gradio frontend to communicate with the backend. By exploiting this flaw, an attacker can redirect user traffic to a malicious server. This could lead to the interception of sensitive data such as authentication credentials or uploaded files. This impacts all users who connect to",
   "Aggiorna Gradio il prima possibile a una versione non interessata da CVE-2024-47870 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-47870 (Gradio)",
   "NVDの説明（英語原文）: Gradio is an open-source Python package designed for quick prototyping. This vulnerability involves a **race condition** in the `update_root_in_config` function, allowing an attacker to modify the `root` URL used by the Gradio frontend to communicate with the backend. By exploiting this flaw, an attacker can redirect user traffic to a malicious server. This could lead to the interception of sensitive data such as authentication credentials or uploaded files. This impacts all users who connect to",
   "Gradio を CVE-2024-47870 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-47870 (Gradio)",
   "NVD 설명(영어 원문): Gradio is an open-source Python package designed for quick prototyping. This vulnerability involves a **race condition** in the `update_root_in_config` function, allowing an attacker to modify the `root` URL used by the Gradio frontend to communicate with the backend. By exploiting this flaw, an attacker can redirect user traffic to a malicious server. This could lead to the interception of sensitive data such as authentication credentials or uploaded files. This impacts all users who connect to",
   "Gradio을(를) CVE-2024-47870의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-47870 (Gradio)",
   "Descrição do NVD (texto original em inglês): Gradio is an open-source Python package designed for quick prototyping. This vulnerability involves a **race condition** in the `update_root_in_config` function, allowing an attacker to modify the `root` URL used by the Gradio frontend to communicate with the backend. By exploiting this flaw, an attacker can redirect user traffic to a malicious server. This could lead to the interception of sensitive data such as authentication credentials or uploaded files. This impacts all users who connect to",
   "Atualize o Gradio o quanto antes para uma versão não afetada por CVE-2024-47870 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-47870（Gradio）",
   "NVD 说明（英文原文）：Gradio is an open-source Python package designed for quick prototyping. This vulnerability involves a **race condition** in the `update_root_in_config` function, allowing an attacker to modify the `root` URL used by the Gradio frontend to communicate with the backend. By exploiting this flaw, an attacker can redirect user traffic to a malicious server. This could lead to the interception of sensitive data such as authentication credentials or uploaded files. This impacts all users who connect to",
   "请尽快将 Gradio 升级到不受 CVE-2024-47870 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-47870（Gradio）",
   "NVD 說明（英文原文）：Gradio is an open-source Python package designed for quick prototyping. This vulnerability involves a **race condition** in the `update_root_in_config` function, allowing an attacker to modify the `root` URL used by the Gradio frontend to communicate with the backend. By exploiting this flaw, an attacker can redirect user traffic to a malicious server. This could lead to the interception of sensitive data such as authentication credentials or uploaded files. This impacts all users who connect to",
   "請儘快將 Gradio 升級到不受 CVE-2024-47870 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:gradio-noauth:CVE-2024-47871": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-47871 (Gradio)",
   "NVD-Beschreibung (englischer Originaltext): Gradio is an open-source Python package designed for quick prototyping. This vulnerability involves **insecure communication** between the FRP (Fast Reverse Proxy) client and server when Gradio's `share=True` option is used. HTTPS is not enforced on the connection, allowing attackers to intercept and read files uploaded to the Gradio server, as well as modify responses or data sent between the client and server. This impacts users who are sharing Gradio demos publicly over the internet using `sh",
   "Aktualisieren Sie Gradio so schnell wie möglich auf eine Version, die von CVE-2024-47871 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-47871 (Gradio)",
   "Gradio is an open-source Python package designed for quick prototyping. This vulnerability involves **insecure communication** between the FRP (Fast Reverse Proxy) client and server when Gradio's `share=True` option is used. HTTPS is not enforced on the connection, allowing attackers to intercept and read files uploaded to the Gradio server, as well as modify responses or data sent between the client and server. This impacts users who are sharing Gradio demos publicly over the internet using `sh",
   "Upgrade Gradio to a version not affected by CVE-2024-47871 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-47871 (Gradio)",
   "Descripción de NVD (texto original en inglés): Gradio is an open-source Python package designed for quick prototyping. This vulnerability involves **insecure communication** between the FRP (Fast Reverse Proxy) client and server when Gradio's `share=True` option is used. HTTPS is not enforced on the connection, allowing attackers to intercept and read files uploaded to the Gradio server, as well as modify responses or data sent between the client and server. This impacts users who are sharing Gradio demos publicly over the internet using `sh",
   "Actualice Gradio lo antes posible a una versión no afectada por CVE-2024-47871 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-47871 (Gradio)",
   "Description NVD (texte original en anglais) : Gradio is an open-source Python package designed for quick prototyping. This vulnerability involves **insecure communication** between the FRP (Fast Reverse Proxy) client and server when Gradio's `share=True` option is used. HTTPS is not enforced on the connection, allowing attackers to intercept and read files uploaded to the Gradio server, as well as modify responses or data sent between the client and server. This impacts users who are sharing Gradio demos publicly over the internet using `sh",
   "Mettez à niveau Gradio dès que possible vers une version non affectée par CVE-2024-47871 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-47871 (Gradio)",
   "Descrizione NVD (testo originale in inglese): Gradio is an open-source Python package designed for quick prototyping. This vulnerability involves **insecure communication** between the FRP (Fast Reverse Proxy) client and server when Gradio's `share=True` option is used. HTTPS is not enforced on the connection, allowing attackers to intercept and read files uploaded to the Gradio server, as well as modify responses or data sent between the client and server. This impacts users who are sharing Gradio demos publicly over the internet using `sh",
   "Aggiorna Gradio il prima possibile a una versione non interessata da CVE-2024-47871 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-47871 (Gradio)",
   "NVDの説明（英語原文）: Gradio is an open-source Python package designed for quick prototyping. This vulnerability involves **insecure communication** between the FRP (Fast Reverse Proxy) client and server when Gradio's `share=True` option is used. HTTPS is not enforced on the connection, allowing attackers to intercept and read files uploaded to the Gradio server, as well as modify responses or data sent between the client and server. This impacts users who are sharing Gradio demos publicly over the internet using `sh",
   "Gradio を CVE-2024-47871 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-47871 (Gradio)",
   "NVD 설명(영어 원문): Gradio is an open-source Python package designed for quick prototyping. This vulnerability involves **insecure communication** between the FRP (Fast Reverse Proxy) client and server when Gradio's `share=True` option is used. HTTPS is not enforced on the connection, allowing attackers to intercept and read files uploaded to the Gradio server, as well as modify responses or data sent between the client and server. This impacts users who are sharing Gradio demos publicly over the internet using `sh",
   "Gradio을(를) CVE-2024-47871의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-47871 (Gradio)",
   "Descrição do NVD (texto original em inglês): Gradio is an open-source Python package designed for quick prototyping. This vulnerability involves **insecure communication** between the FRP (Fast Reverse Proxy) client and server when Gradio's `share=True` option is used. HTTPS is not enforced on the connection, allowing attackers to intercept and read files uploaded to the Gradio server, as well as modify responses or data sent between the client and server. This impacts users who are sharing Gradio demos publicly over the internet using `sh",
   "Atualize o Gradio o quanto antes para uma versão não afetada por CVE-2024-47871 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-47871（Gradio）",
   "NVD 说明（英文原文）：Gradio is an open-source Python package designed for quick prototyping. This vulnerability involves **insecure communication** between the FRP (Fast Reverse Proxy) client and server when Gradio's `share=True` option is used. HTTPS is not enforced on the connection, allowing attackers to intercept and read files uploaded to the Gradio server, as well as modify responses or data sent between the client and server. This impacts users who are sharing Gradio demos publicly over the internet using `sh",
   "请尽快将 Gradio 升级到不受 CVE-2024-47871 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-47871（Gradio）",
   "NVD 說明（英文原文）：Gradio is an open-source Python package designed for quick prototyping. This vulnerability involves **insecure communication** between the FRP (Fast Reverse Proxy) client and server when Gradio's `share=True` option is used. HTTPS is not enforced on the connection, allowing attackers to intercept and read files uploaded to the Gradio server, as well as modify responses or data sent between the client and server. This impacts users who are sharing Gradio demos publicly over the internet using `sh",
   "請儘快將 Gradio 升級到不受 CVE-2024-47871 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:gradio-noauth:CVE-2024-4941": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-4941 (Gradio)",
   "NVD-Beschreibung (englischer Originaltext): A local file inclusion vulnerability exists in the JSON component of gradio-app/gradio version 4.25. The vulnerability arises from improper input validation in the `postprocess()` function within `gradio/components/json_component.py`, where a user-controlled string is parsed as JSON. If the parsed JSON object contains a `path` key, the specified file is moved to a temporary directory, making it possible to retrieve it later via the `/file=..` endpoint. This issue is due to the `processing_utils.",
   "Aktualisieren Sie Gradio so schnell wie möglich auf eine Version, die von CVE-2024-4941 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-4941 (Gradio)",
   "A local file inclusion vulnerability exists in the JSON component of gradio-app/gradio version 4.25. The vulnerability arises from improper input validation in the `postprocess()` function within `gradio/components/json_component.py`, where a user-controlled string is parsed as JSON. If the parsed JSON object contains a `path` key, the specified file is moved to a temporary directory, making it possible to retrieve it later via the `/file=..` endpoint. This issue is due to the `processing_utils.",
   "Upgrade Gradio to a version not affected by CVE-2024-4941 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-4941 (Gradio)",
   "Descripción de NVD (texto original en inglés): A local file inclusion vulnerability exists in the JSON component of gradio-app/gradio version 4.25. The vulnerability arises from improper input validation in the `postprocess()` function within `gradio/components/json_component.py`, where a user-controlled string is parsed as JSON. If the parsed JSON object contains a `path` key, the specified file is moved to a temporary directory, making it possible to retrieve it later via the `/file=..` endpoint. This issue is due to the `processing_utils.",
   "Actualice Gradio lo antes posible a una versión no afectada por CVE-2024-4941 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-4941 (Gradio)",
   "Description NVD (texte original en anglais) : A local file inclusion vulnerability exists in the JSON component of gradio-app/gradio version 4.25. The vulnerability arises from improper input validation in the `postprocess()` function within `gradio/components/json_component.py`, where a user-controlled string is parsed as JSON. If the parsed JSON object contains a `path` key, the specified file is moved to a temporary directory, making it possible to retrieve it later via the `/file=..` endpoint. This issue is due to the `processing_utils.",
   "Mettez à niveau Gradio dès que possible vers une version non affectée par CVE-2024-4941 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-4941 (Gradio)",
   "Descrizione NVD (testo originale in inglese): A local file inclusion vulnerability exists in the JSON component of gradio-app/gradio version 4.25. The vulnerability arises from improper input validation in the `postprocess()` function within `gradio/components/json_component.py`, where a user-controlled string is parsed as JSON. If the parsed JSON object contains a `path` key, the specified file is moved to a temporary directory, making it possible to retrieve it later via the `/file=..` endpoint. This issue is due to the `processing_utils.",
   "Aggiorna Gradio il prima possibile a una versione non interessata da CVE-2024-4941 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-4941 (Gradio)",
   "NVDの説明（英語原文）: A local file inclusion vulnerability exists in the JSON component of gradio-app/gradio version 4.25. The vulnerability arises from improper input validation in the `postprocess()` function within `gradio/components/json_component.py`, where a user-controlled string is parsed as JSON. If the parsed JSON object contains a `path` key, the specified file is moved to a temporary directory, making it possible to retrieve it later via the `/file=..` endpoint. This issue is due to the `processing_utils.",
   "Gradio を CVE-2024-4941 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-4941 (Gradio)",
   "NVD 설명(영어 원문): A local file inclusion vulnerability exists in the JSON component of gradio-app/gradio version 4.25. The vulnerability arises from improper input validation in the `postprocess()` function within `gradio/components/json_component.py`, where a user-controlled string is parsed as JSON. If the parsed JSON object contains a `path` key, the specified file is moved to a temporary directory, making it possible to retrieve it later via the `/file=..` endpoint. This issue is due to the `processing_utils.",
   "Gradio을(를) CVE-2024-4941의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-4941 (Gradio)",
   "Descrição do NVD (texto original em inglês): A local file inclusion vulnerability exists in the JSON component of gradio-app/gradio version 4.25. The vulnerability arises from improper input validation in the `postprocess()` function within `gradio/components/json_component.py`, where a user-controlled string is parsed as JSON. If the parsed JSON object contains a `path` key, the specified file is moved to a temporary directory, making it possible to retrieve it later via the `/file=..` endpoint. This issue is due to the `processing_utils.",
   "Atualize o Gradio o quanto antes para uma versão não afetada por CVE-2024-4941 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-4941（Gradio）",
   "NVD 说明（英文原文）：A local file inclusion vulnerability exists in the JSON component of gradio-app/gradio version 4.25. The vulnerability arises from improper input validation in the `postprocess()` function within `gradio/components/json_component.py`, where a user-controlled string is parsed as JSON. If the parsed JSON object contains a `path` key, the specified file is moved to a temporary directory, making it possible to retrieve it later via the `/file=..` endpoint. This issue is due to the `processing_utils.",
   "请尽快将 Gradio 升级到不受 CVE-2024-4941 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-4941（Gradio）",
   "NVD 說明（英文原文）：A local file inclusion vulnerability exists in the JSON component of gradio-app/gradio version 4.25. The vulnerability arises from improper input validation in the `postprocess()` function within `gradio/components/json_component.py`, where a user-controlled string is parsed as JSON. If the parsed JSON object contains a `path` key, the specified file is moved to a temporary directory, making it possible to retrieve it later via the `/file=..` endpoint. This issue is due to the `processing_utils.",
   "請儘快將 Gradio 升級到不受 CVE-2024-4941 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:gradio-noauth:CVE-2025-0187": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-0187 (Gradio)",
   "NVD-Beschreibung (englischer Originaltext): A Denial of Service (DoS) vulnerability was discovered in the file upload feature of gradio-app/gradio version 0.39.1. The vulnerability is due to improper handling of form-data with a large filename in the file upload request. By sending a payload with an excessively large filename, the server becomes overwhelmed and unresponsive, leading to unavailability for legitimate users.",
   "Aktualisieren Sie Gradio so schnell wie möglich auf eine Version, die von CVE-2025-0187 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-0187 (Gradio)",
   "A Denial of Service (DoS) vulnerability was discovered in the file upload feature of gradio-app/gradio version 0.39.1. The vulnerability is due to improper handling of form-data with a large filename in the file upload request. By sending a payload with an excessively large filename, the server becomes overwhelmed and unresponsive, leading to unavailability for legitimate users.",
   "Upgrade Gradio to a version not affected by CVE-2025-0187 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-0187 (Gradio)",
   "Descripción de NVD (texto original en inglés): A Denial of Service (DoS) vulnerability was discovered in the file upload feature of gradio-app/gradio version 0.39.1. The vulnerability is due to improper handling of form-data with a large filename in the file upload request. By sending a payload with an excessively large filename, the server becomes overwhelmed and unresponsive, leading to unavailability for legitimate users.",
   "Actualice Gradio lo antes posible a una versión no afectada por CVE-2025-0187 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-0187 (Gradio)",
   "Description NVD (texte original en anglais) : A Denial of Service (DoS) vulnerability was discovered in the file upload feature of gradio-app/gradio version 0.39.1. The vulnerability is due to improper handling of form-data with a large filename in the file upload request. By sending a payload with an excessively large filename, the server becomes overwhelmed and unresponsive, leading to unavailability for legitimate users.",
   "Mettez à niveau Gradio dès que possible vers une version non affectée par CVE-2025-0187 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-0187 (Gradio)",
   "Descrizione NVD (testo originale in inglese): A Denial of Service (DoS) vulnerability was discovered in the file upload feature of gradio-app/gradio version 0.39.1. The vulnerability is due to improper handling of form-data with a large filename in the file upload request. By sending a payload with an excessively large filename, the server becomes overwhelmed and unresponsive, leading to unavailability for legitimate users.",
   "Aggiorna Gradio il prima possibile a una versione non interessata da CVE-2025-0187 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-0187 (Gradio)",
   "NVDの説明（英語原文）: A Denial of Service (DoS) vulnerability was discovered in the file upload feature of gradio-app/gradio version 0.39.1. The vulnerability is due to improper handling of form-data with a large filename in the file upload request. By sending a payload with an excessively large filename, the server becomes overwhelmed and unresponsive, leading to unavailability for legitimate users.",
   "Gradio を CVE-2025-0187 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-0187 (Gradio)",
   "NVD 설명(영어 원문): A Denial of Service (DoS) vulnerability was discovered in the file upload feature of gradio-app/gradio version 0.39.1. The vulnerability is due to improper handling of form-data with a large filename in the file upload request. By sending a payload with an excessively large filename, the server becomes overwhelmed and unresponsive, leading to unavailability for legitimate users.",
   "Gradio을(를) CVE-2025-0187의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-0187 (Gradio)",
   "Descrição do NVD (texto original em inglês): A Denial of Service (DoS) vulnerability was discovered in the file upload feature of gradio-app/gradio version 0.39.1. The vulnerability is due to improper handling of form-data with a large filename in the file upload request. By sending a payload with an excessively large filename, the server becomes overwhelmed and unresponsive, leading to unavailability for legitimate users.",
   "Atualize o Gradio o quanto antes para uma versão não afetada por CVE-2025-0187 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-0187（Gradio）",
   "NVD 说明（英文原文）：A Denial of Service (DoS) vulnerability was discovered in the file upload feature of gradio-app/gradio version 0.39.1. The vulnerability is due to improper handling of form-data with a large filename in the file upload request. By sending a payload with an excessively large filename, the server becomes overwhelmed and unresponsive, leading to unavailability for legitimate users.",
   "请尽快将 Gradio 升级到不受 CVE-2025-0187 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-0187（Gradio）",
   "NVD 說明（英文原文）：A Denial of Service (DoS) vulnerability was discovered in the file upload feature of gradio-app/gradio version 0.39.1. The vulnerability is due to improper handling of form-data with a large filename in the file upload request. By sending a payload with an excessively large filename, the server becomes overwhelmed and unresponsive, leading to unavailability for legitimate users.",
   "請儘快將 Gradio 升級到不受 CVE-2025-0187 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:gradio-noauth:CVE-2025-23042": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-23042 (Gradio)",
   "NVD-Beschreibung (englischer Originaltext): Gradio is an open-source Python package that allows quick building of demos and web application for machine learning models, API, or any arbitrary Python function. Gradio's Access Control List (ACL) for file paths can be bypassed by altering the letter case of a blocked file or directory path. This vulnerability arises due to the lack of case normalization in the file path validation logic. On case-insensitive file systems, such as those used by Windows and macOS, this flaw enables attackers to ",
   "Aktualisieren Sie Gradio so schnell wie möglich auf eine Version, die von CVE-2025-23042 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-23042 (Gradio)",
   "Gradio is an open-source Python package that allows quick building of demos and web application for machine learning models, API, or any arbitrary Python function. Gradio's Access Control List (ACL) for file paths can be bypassed by altering the letter case of a blocked file or directory path. This vulnerability arises due to the lack of case normalization in the file path validation logic. On case-insensitive file systems, such as those used by Windows and macOS, this flaw enables attackers to ",
   "Upgrade Gradio to a version not affected by CVE-2025-23042 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-23042 (Gradio)",
   "Descripción de NVD (texto original en inglés): Gradio is an open-source Python package that allows quick building of demos and web application for machine learning models, API, or any arbitrary Python function. Gradio's Access Control List (ACL) for file paths can be bypassed by altering the letter case of a blocked file or directory path. This vulnerability arises due to the lack of case normalization in the file path validation logic. On case-insensitive file systems, such as those used by Windows and macOS, this flaw enables attackers to ",
   "Actualice Gradio lo antes posible a una versión no afectada por CVE-2025-23042 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-23042 (Gradio)",
   "Description NVD (texte original en anglais) : Gradio is an open-source Python package that allows quick building of demos and web application for machine learning models, API, or any arbitrary Python function. Gradio's Access Control List (ACL) for file paths can be bypassed by altering the letter case of a blocked file or directory path. This vulnerability arises due to the lack of case normalization in the file path validation logic. On case-insensitive file systems, such as those used by Windows and macOS, this flaw enables attackers to ",
   "Mettez à niveau Gradio dès que possible vers une version non affectée par CVE-2025-23042 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-23042 (Gradio)",
   "Descrizione NVD (testo originale in inglese): Gradio is an open-source Python package that allows quick building of demos and web application for machine learning models, API, or any arbitrary Python function. Gradio's Access Control List (ACL) for file paths can be bypassed by altering the letter case of a blocked file or directory path. This vulnerability arises due to the lack of case normalization in the file path validation logic. On case-insensitive file systems, such as those used by Windows and macOS, this flaw enables attackers to ",
   "Aggiorna Gradio il prima possibile a una versione non interessata da CVE-2025-23042 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-23042 (Gradio)",
   "NVDの説明（英語原文）: Gradio is an open-source Python package that allows quick building of demos and web application for machine learning models, API, or any arbitrary Python function. Gradio's Access Control List (ACL) for file paths can be bypassed by altering the letter case of a blocked file or directory path. This vulnerability arises due to the lack of case normalization in the file path validation logic. On case-insensitive file systems, such as those used by Windows and macOS, this flaw enables attackers to ",
   "Gradio を CVE-2025-23042 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-23042 (Gradio)",
   "NVD 설명(영어 원문): Gradio is an open-source Python package that allows quick building of demos and web application for machine learning models, API, or any arbitrary Python function. Gradio's Access Control List (ACL) for file paths can be bypassed by altering the letter case of a blocked file or directory path. This vulnerability arises due to the lack of case normalization in the file path validation logic. On case-insensitive file systems, such as those used by Windows and macOS, this flaw enables attackers to ",
   "Gradio을(를) CVE-2025-23042의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-23042 (Gradio)",
   "Descrição do NVD (texto original em inglês): Gradio is an open-source Python package that allows quick building of demos and web application for machine learning models, API, or any arbitrary Python function. Gradio's Access Control List (ACL) for file paths can be bypassed by altering the letter case of a blocked file or directory path. This vulnerability arises due to the lack of case normalization in the file path validation logic. On case-insensitive file systems, such as those used by Windows and macOS, this flaw enables attackers to ",
   "Atualize o Gradio o quanto antes para uma versão não afetada por CVE-2025-23042 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-23042（Gradio）",
   "NVD 说明（英文原文）：Gradio is an open-source Python package that allows quick building of demos and web application for machine learning models, API, or any arbitrary Python function. Gradio's Access Control List (ACL) for file paths can be bypassed by altering the letter case of a blocked file or directory path. This vulnerability arises due to the lack of case normalization in the file path validation logic. On case-insensitive file systems, such as those used by Windows and macOS, this flaw enables attackers to ",
   "请尽快将 Gradio 升级到不受 CVE-2025-23042 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-23042（Gradio）",
   "NVD 說明（英文原文）：Gradio is an open-source Python package that allows quick building of demos and web application for machine learning models, API, or any arbitrary Python function. Gradio's Access Control List (ACL) for file paths can be bypassed by altering the letter case of a blocked file or directory path. This vulnerability arises due to the lack of case normalization in the file path validation logic. On case-insensitive file systems, such as those used by Windows and macOS, this flaw enables attackers to ",
   "請儘快將 Gradio 升級到不受 CVE-2025-23042 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:gradio-noauth:CVE-2026-28414": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-28414 (Gradio)",
   "NVD-Beschreibung (englischer Originaltext): Gradio is an open-source Python package designed for quick prototyping. Prior to version 6.7, Gradio apps running on Window with Python 3.13+ are vulnerable to an absolute path traversal issue that enables unauthenticated attackers to read arbitrary files from the file system. Python 3.13+ changed the definition of `os.path.isabs` so that root-relative paths like `/windows/win.ini` on Windows are no longer considered absolute paths, resulting in a vulnerability in Gradio's logic for joining path",
   "Aktualisieren Sie Gradio so schnell wie möglich auf eine Version, die von CVE-2026-28414 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-28414 (Gradio)",
   "Gradio is an open-source Python package designed for quick prototyping. Prior to version 6.7, Gradio apps running on Window with Python 3.13+ are vulnerable to an absolute path traversal issue that enables unauthenticated attackers to read arbitrary files from the file system. Python 3.13+ changed the definition of `os.path.isabs` so that root-relative paths like `/windows/win.ini` on Windows are no longer considered absolute paths, resulting in a vulnerability in Gradio's logic for joining path",
   "Upgrade Gradio to a version not affected by CVE-2026-28414 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-28414 (Gradio)",
   "Descripción de NVD (texto original en inglés): Gradio is an open-source Python package designed for quick prototyping. Prior to version 6.7, Gradio apps running on Window with Python 3.13+ are vulnerable to an absolute path traversal issue that enables unauthenticated attackers to read arbitrary files from the file system. Python 3.13+ changed the definition of `os.path.isabs` so that root-relative paths like `/windows/win.ini` on Windows are no longer considered absolute paths, resulting in a vulnerability in Gradio's logic for joining path",
   "Actualice Gradio lo antes posible a una versión no afectada por CVE-2026-28414 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-28414 (Gradio)",
   "Description NVD (texte original en anglais) : Gradio is an open-source Python package designed for quick prototyping. Prior to version 6.7, Gradio apps running on Window with Python 3.13+ are vulnerable to an absolute path traversal issue that enables unauthenticated attackers to read arbitrary files from the file system. Python 3.13+ changed the definition of `os.path.isabs` so that root-relative paths like `/windows/win.ini` on Windows are no longer considered absolute paths, resulting in a vulnerability in Gradio's logic for joining path",
   "Mettez à niveau Gradio dès que possible vers une version non affectée par CVE-2026-28414 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-28414 (Gradio)",
   "Descrizione NVD (testo originale in inglese): Gradio is an open-source Python package designed for quick prototyping. Prior to version 6.7, Gradio apps running on Window with Python 3.13+ are vulnerable to an absolute path traversal issue that enables unauthenticated attackers to read arbitrary files from the file system. Python 3.13+ changed the definition of `os.path.isabs` so that root-relative paths like `/windows/win.ini` on Windows are no longer considered absolute paths, resulting in a vulnerability in Gradio's logic for joining path",
   "Aggiorna Gradio il prima possibile a una versione non interessata da CVE-2026-28414 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-28414 (Gradio)",
   "NVDの説明（英語原文）: Gradio is an open-source Python package designed for quick prototyping. Prior to version 6.7, Gradio apps running on Window with Python 3.13+ are vulnerable to an absolute path traversal issue that enables unauthenticated attackers to read arbitrary files from the file system. Python 3.13+ changed the definition of `os.path.isabs` so that root-relative paths like `/windows/win.ini` on Windows are no longer considered absolute paths, resulting in a vulnerability in Gradio's logic for joining path",
   "Gradio を CVE-2026-28414 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-28414 (Gradio)",
   "NVD 설명(영어 원문): Gradio is an open-source Python package designed for quick prototyping. Prior to version 6.7, Gradio apps running on Window with Python 3.13+ are vulnerable to an absolute path traversal issue that enables unauthenticated attackers to read arbitrary files from the file system. Python 3.13+ changed the definition of `os.path.isabs` so that root-relative paths like `/windows/win.ini` on Windows are no longer considered absolute paths, resulting in a vulnerability in Gradio's logic for joining path",
   "Gradio을(를) CVE-2026-28414의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-28414 (Gradio)",
   "Descrição do NVD (texto original em inglês): Gradio is an open-source Python package designed for quick prototyping. Prior to version 6.7, Gradio apps running on Window with Python 3.13+ are vulnerable to an absolute path traversal issue that enables unauthenticated attackers to read arbitrary files from the file system. Python 3.13+ changed the definition of `os.path.isabs` so that root-relative paths like `/windows/win.ini` on Windows are no longer considered absolute paths, resulting in a vulnerability in Gradio's logic for joining path",
   "Atualize o Gradio o quanto antes para uma versão não afetada por CVE-2026-28414 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-28414（Gradio）",
   "NVD 说明（英文原文）：Gradio is an open-source Python package designed for quick prototyping. Prior to version 6.7, Gradio apps running on Window with Python 3.13+ are vulnerable to an absolute path traversal issue that enables unauthenticated attackers to read arbitrary files from the file system. Python 3.13+ changed the definition of `os.path.isabs` so that root-relative paths like `/windows/win.ini` on Windows are no longer considered absolute paths, resulting in a vulnerability in Gradio's logic for joining path",
   "请尽快将 Gradio 升级到不受 CVE-2026-28414 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-28414（Gradio）",
   "NVD 說明（英文原文）：Gradio is an open-source Python package designed for quick prototyping. Prior to version 6.7, Gradio apps running on Window with Python 3.13+ are vulnerable to an absolute path traversal issue that enables unauthenticated attackers to read arbitrary files from the file system. Python 3.13+ changed the definition of `os.path.isabs` so that root-relative paths like `/windows/win.ini` on Windows are no longer considered absolute paths, resulting in a vulnerability in Gradio's logic for joining path",
   "請儘快將 Gradio 升級到不受 CVE-2026-28414 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:gradio-noauth:CVE-2026-28416": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-28416 (Gradio)",
   "NVD-Beschreibung (englischer Originaltext): Gradio is an open-source Python package designed for quick prototyping. Prior to version 6.6.0, a Server-Side Request Forgery (SSRF) vulnerability in Gradio allows an attacker to make arbitrary HTTP requests from a victim's server by hosting a malicious Gradio Space. When a victim application uses `gr.load()` to load an attacker-controlled Space, the malicious `proxy_url` from the config is trusted and added to the allowlist, enabling the attacker to access internal services, cloud metadata endp",
   "Aktualisieren Sie Gradio so schnell wie möglich auf eine Version, die von CVE-2026-28416 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-28416 (Gradio)",
   "Gradio is an open-source Python package designed for quick prototyping. Prior to version 6.6.0, a Server-Side Request Forgery (SSRF) vulnerability in Gradio allows an attacker to make arbitrary HTTP requests from a victim's server by hosting a malicious Gradio Space. When a victim application uses `gr.load()` to load an attacker-controlled Space, the malicious `proxy_url` from the config is trusted and added to the allowlist, enabling the attacker to access internal services, cloud metadata endp",
   "Upgrade Gradio to a version not affected by CVE-2026-28416 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-28416 (Gradio)",
   "Descripción de NVD (texto original en inglés): Gradio is an open-source Python package designed for quick prototyping. Prior to version 6.6.0, a Server-Side Request Forgery (SSRF) vulnerability in Gradio allows an attacker to make arbitrary HTTP requests from a victim's server by hosting a malicious Gradio Space. When a victim application uses `gr.load()` to load an attacker-controlled Space, the malicious `proxy_url` from the config is trusted and added to the allowlist, enabling the attacker to access internal services, cloud metadata endp",
   "Actualice Gradio lo antes posible a una versión no afectada por CVE-2026-28416 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-28416 (Gradio)",
   "Description NVD (texte original en anglais) : Gradio is an open-source Python package designed for quick prototyping. Prior to version 6.6.0, a Server-Side Request Forgery (SSRF) vulnerability in Gradio allows an attacker to make arbitrary HTTP requests from a victim's server by hosting a malicious Gradio Space. When a victim application uses `gr.load()` to load an attacker-controlled Space, the malicious `proxy_url` from the config is trusted and added to the allowlist, enabling the attacker to access internal services, cloud metadata endp",
   "Mettez à niveau Gradio dès que possible vers une version non affectée par CVE-2026-28416 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-28416 (Gradio)",
   "Descrizione NVD (testo originale in inglese): Gradio is an open-source Python package designed for quick prototyping. Prior to version 6.6.0, a Server-Side Request Forgery (SSRF) vulnerability in Gradio allows an attacker to make arbitrary HTTP requests from a victim's server by hosting a malicious Gradio Space. When a victim application uses `gr.load()` to load an attacker-controlled Space, the malicious `proxy_url` from the config is trusted and added to the allowlist, enabling the attacker to access internal services, cloud metadata endp",
   "Aggiorna Gradio il prima possibile a una versione non interessata da CVE-2026-28416 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-28416 (Gradio)",
   "NVDの説明（英語原文）: Gradio is an open-source Python package designed for quick prototyping. Prior to version 6.6.0, a Server-Side Request Forgery (SSRF) vulnerability in Gradio allows an attacker to make arbitrary HTTP requests from a victim's server by hosting a malicious Gradio Space. When a victim application uses `gr.load()` to load an attacker-controlled Space, the malicious `proxy_url` from the config is trusted and added to the allowlist, enabling the attacker to access internal services, cloud metadata endp",
   "Gradio を CVE-2026-28416 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-28416 (Gradio)",
   "NVD 설명(영어 원문): Gradio is an open-source Python package designed for quick prototyping. Prior to version 6.6.0, a Server-Side Request Forgery (SSRF) vulnerability in Gradio allows an attacker to make arbitrary HTTP requests from a victim's server by hosting a malicious Gradio Space. When a victim application uses `gr.load()` to load an attacker-controlled Space, the malicious `proxy_url` from the config is trusted and added to the allowlist, enabling the attacker to access internal services, cloud metadata endp",
   "Gradio을(를) CVE-2026-28416의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-28416 (Gradio)",
   "Descrição do NVD (texto original em inglês): Gradio is an open-source Python package designed for quick prototyping. Prior to version 6.6.0, a Server-Side Request Forgery (SSRF) vulnerability in Gradio allows an attacker to make arbitrary HTTP requests from a victim's server by hosting a malicious Gradio Space. When a victim application uses `gr.load()` to load an attacker-controlled Space, the malicious `proxy_url` from the config is trusted and added to the allowlist, enabling the attacker to access internal services, cloud metadata endp",
   "Atualize o Gradio o quanto antes para uma versão não afetada por CVE-2026-28416 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-28416（Gradio）",
   "NVD 说明（英文原文）：Gradio is an open-source Python package designed for quick prototyping. Prior to version 6.6.0, a Server-Side Request Forgery (SSRF) vulnerability in Gradio allows an attacker to make arbitrary HTTP requests from a victim's server by hosting a malicious Gradio Space. When a victim application uses `gr.load()` to load an attacker-controlled Space, the malicious `proxy_url` from the config is trusted and added to the allowlist, enabling the attacker to access internal services, cloud metadata endp",
   "请尽快将 Gradio 升级到不受 CVE-2026-28416 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-28416（Gradio）",
   "NVD 說明（英文原文）：Gradio is an open-source Python package designed for quick prototyping. Prior to version 6.6.0, a Server-Side Request Forgery (SSRF) vulnerability in Gradio allows an attacker to make arbitrary HTTP requests from a victim's server by hosting a malicious Gradio Space. When a victim application uses `gr.load()` to load an attacker-controlled Space, the malicious `proxy_url` from the config is trusted and added to the allowlist, enabling the attacker to access internal services, cloud metadata endp",
   "請儘快將 Gradio 升級到不受 CVE-2026-28416 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:gradio-noauth:CVE-2026-49119": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-49119 (Gradio)",
   "NVD-Beschreibung (englischer Originaltext): Gradio before 6.16.0 contain a path traversal vulnerability in the FileExplorer component's preprocess() method that allows unauthenticated attackers to escape the configured root directory by supplying path segments containing directory traversal sequences or absolute paths. Attackers can provide crafted path segments that cause os.path.join to discard the root_dir prefix entirely, resulting in arbitrary file read or exposure of sensitive files outside the intended directory.",
   "Aktualisieren Sie Gradio so schnell wie möglich auf eine Version, die von CVE-2026-49119 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-49119 (Gradio)",
   "Gradio before 6.16.0 contain a path traversal vulnerability in the FileExplorer component's preprocess() method that allows unauthenticated attackers to escape the configured root directory by supplying path segments containing directory traversal sequences or absolute paths. Attackers can provide crafted path segments that cause os.path.join to discard the root_dir prefix entirely, resulting in arbitrary file read or exposure of sensitive files outside the intended directory.",
   "Upgrade Gradio to a version not affected by CVE-2026-49119 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-49119 (Gradio)",
   "Descripción de NVD (texto original en inglés): Gradio before 6.16.0 contain a path traversal vulnerability in the FileExplorer component's preprocess() method that allows unauthenticated attackers to escape the configured root directory by supplying path segments containing directory traversal sequences or absolute paths. Attackers can provide crafted path segments that cause os.path.join to discard the root_dir prefix entirely, resulting in arbitrary file read or exposure of sensitive files outside the intended directory.",
   "Actualice Gradio lo antes posible a una versión no afectada por CVE-2026-49119 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-49119 (Gradio)",
   "Description NVD (texte original en anglais) : Gradio before 6.16.0 contain a path traversal vulnerability in the FileExplorer component's preprocess() method that allows unauthenticated attackers to escape the configured root directory by supplying path segments containing directory traversal sequences or absolute paths. Attackers can provide crafted path segments that cause os.path.join to discard the root_dir prefix entirely, resulting in arbitrary file read or exposure of sensitive files outside the intended directory.",
   "Mettez à niveau Gradio dès que possible vers une version non affectée par CVE-2026-49119 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-49119 (Gradio)",
   "Descrizione NVD (testo originale in inglese): Gradio before 6.16.0 contain a path traversal vulnerability in the FileExplorer component's preprocess() method that allows unauthenticated attackers to escape the configured root directory by supplying path segments containing directory traversal sequences or absolute paths. Attackers can provide crafted path segments that cause os.path.join to discard the root_dir prefix entirely, resulting in arbitrary file read or exposure of sensitive files outside the intended directory.",
   "Aggiorna Gradio il prima possibile a una versione non interessata da CVE-2026-49119 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-49119 (Gradio)",
   "NVDの説明（英語原文）: Gradio before 6.16.0 contain a path traversal vulnerability in the FileExplorer component's preprocess() method that allows unauthenticated attackers to escape the configured root directory by supplying path segments containing directory traversal sequences or absolute paths. Attackers can provide crafted path segments that cause os.path.join to discard the root_dir prefix entirely, resulting in arbitrary file read or exposure of sensitive files outside the intended directory.",
   "Gradio を CVE-2026-49119 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-49119 (Gradio)",
   "NVD 설명(영어 원문): Gradio before 6.16.0 contain a path traversal vulnerability in the FileExplorer component's preprocess() method that allows unauthenticated attackers to escape the configured root directory by supplying path segments containing directory traversal sequences or absolute paths. Attackers can provide crafted path segments that cause os.path.join to discard the root_dir prefix entirely, resulting in arbitrary file read or exposure of sensitive files outside the intended directory.",
   "Gradio을(를) CVE-2026-49119의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-49119 (Gradio)",
   "Descrição do NVD (texto original em inglês): Gradio before 6.16.0 contain a path traversal vulnerability in the FileExplorer component's preprocess() method that allows unauthenticated attackers to escape the configured root directory by supplying path segments containing directory traversal sequences or absolute paths. Attackers can provide crafted path segments that cause os.path.join to discard the root_dir prefix entirely, resulting in arbitrary file read or exposure of sensitive files outside the intended directory.",
   "Atualize o Gradio o quanto antes para uma versão não afetada por CVE-2026-49119 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-49119（Gradio）",
   "NVD 说明（英文原文）：Gradio before 6.16.0 contain a path traversal vulnerability in the FileExplorer component's preprocess() method that allows unauthenticated attackers to escape the configured root directory by supplying path segments containing directory traversal sequences or absolute paths. Attackers can provide crafted path segments that cause os.path.join to discard the root_dir prefix entirely, resulting in arbitrary file read or exposure of sensitive files outside the intended directory.",
   "请尽快将 Gradio 升级到不受 CVE-2026-49119 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-49119（Gradio）",
   "NVD 說明（英文原文）：Gradio before 6.16.0 contain a path traversal vulnerability in the FileExplorer component's preprocess() method that allows unauthenticated attackers to escape the configured root directory by supplying path segments containing directory traversal sequences or absolute paths. Attackers can provide crafted path segments that cause os.path.join to discard the root_dir prefix entirely, resulting in arbitrary file read or exposure of sensitive files outside the intended directory.",
   "請儘快將 Gradio 升級到不受 CVE-2026-49119 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:jupyter-noauth:CVE-2022-24757": {
  "de": [
   "Bekannte Schwachstelle: CVE-2022-24757 (Jupyter Server)",
   "NVD-Beschreibung (englischer Originaltext): The Jupyter Server provides the backend (i.e. the core services, APIs, and REST endpoints) for Jupyter web applications. Prior to version 1.15.4, unauthorized actors can access sensitive information from server logs. Anytime a 5xx error is triggered, the auth cookie and other header values are recorded in Jupyter Server logs by default. Considering these logs do not require root access, an attacker can monitor these logs, steal sensitive auth/cookie information, and gain access to the Jupyter se",
   "Aktualisieren Sie Jupyter Server so schnell wie möglich auf eine Version, die von CVE-2022-24757 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2022-24757 (Jupyter Server)",
   "The Jupyter Server provides the backend (i.e. the core services, APIs, and REST endpoints) for Jupyter web applications. Prior to version 1.15.4, unauthorized actors can access sensitive information from server logs. Anytime a 5xx error is triggered, the auth cookie and other header values are recorded in Jupyter Server logs by default. Considering these logs do not require root access, an attacker can monitor these logs, steal sensitive auth/cookie information, and gain access to the Jupyter se",
   "Upgrade Jupyter Server to a version not affected by CVE-2022-24757 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2022-24757 (Jupyter Server)",
   "Descripción de NVD (texto original en inglés): The Jupyter Server provides the backend (i.e. the core services, APIs, and REST endpoints) for Jupyter web applications. Prior to version 1.15.4, unauthorized actors can access sensitive information from server logs. Anytime a 5xx error is triggered, the auth cookie and other header values are recorded in Jupyter Server logs by default. Considering these logs do not require root access, an attacker can monitor these logs, steal sensitive auth/cookie information, and gain access to the Jupyter se",
   "Actualice Jupyter Server lo antes posible a una versión no afectada por CVE-2022-24757 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2022-24757 (Jupyter Server)",
   "Description NVD (texte original en anglais) : The Jupyter Server provides the backend (i.e. the core services, APIs, and REST endpoints) for Jupyter web applications. Prior to version 1.15.4, unauthorized actors can access sensitive information from server logs. Anytime a 5xx error is triggered, the auth cookie and other header values are recorded in Jupyter Server logs by default. Considering these logs do not require root access, an attacker can monitor these logs, steal sensitive auth/cookie information, and gain access to the Jupyter se",
   "Mettez à niveau Jupyter Server dès que possible vers une version non affectée par CVE-2022-24757 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2022-24757 (Jupyter Server)",
   "Descrizione NVD (testo originale in inglese): The Jupyter Server provides the backend (i.e. the core services, APIs, and REST endpoints) for Jupyter web applications. Prior to version 1.15.4, unauthorized actors can access sensitive information from server logs. Anytime a 5xx error is triggered, the auth cookie and other header values are recorded in Jupyter Server logs by default. Considering these logs do not require root access, an attacker can monitor these logs, steal sensitive auth/cookie information, and gain access to the Jupyter se",
   "Aggiorna Jupyter Server il prima possibile a una versione non interessata da CVE-2022-24757 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2022-24757 (Jupyter Server)",
   "NVDの説明（英語原文）: The Jupyter Server provides the backend (i.e. the core services, APIs, and REST endpoints) for Jupyter web applications. Prior to version 1.15.4, unauthorized actors can access sensitive information from server logs. Anytime a 5xx error is triggered, the auth cookie and other header values are recorded in Jupyter Server logs by default. Considering these logs do not require root access, an attacker can monitor these logs, steal sensitive auth/cookie information, and gain access to the Jupyter se",
   "Jupyter Server を CVE-2022-24757 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2022-24757 (Jupyter Server)",
   "NVD 설명(영어 원문): The Jupyter Server provides the backend (i.e. the core services, APIs, and REST endpoints) for Jupyter web applications. Prior to version 1.15.4, unauthorized actors can access sensitive information from server logs. Anytime a 5xx error is triggered, the auth cookie and other header values are recorded in Jupyter Server logs by default. Considering these logs do not require root access, an attacker can monitor these logs, steal sensitive auth/cookie information, and gain access to the Jupyter se",
   "Jupyter Server을(를) CVE-2022-24757의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2022-24757 (Jupyter Server)",
   "Descrição do NVD (texto original em inglês): The Jupyter Server provides the backend (i.e. the core services, APIs, and REST endpoints) for Jupyter web applications. Prior to version 1.15.4, unauthorized actors can access sensitive information from server logs. Anytime a 5xx error is triggered, the auth cookie and other header values are recorded in Jupyter Server logs by default. Considering these logs do not require root access, an attacker can monitor these logs, steal sensitive auth/cookie information, and gain access to the Jupyter se",
   "Atualize o Jupyter Server o quanto antes para uma versão não afetada por CVE-2022-24757 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2022-24757（Jupyter Server）",
   "NVD 说明（英文原文）：The Jupyter Server provides the backend (i.e. the core services, APIs, and REST endpoints) for Jupyter web applications. Prior to version 1.15.4, unauthorized actors can access sensitive information from server logs. Anytime a 5xx error is triggered, the auth cookie and other header values are recorded in Jupyter Server logs by default. Considering these logs do not require root access, an attacker can monitor these logs, steal sensitive auth/cookie information, and gain access to the Jupyter se",
   "请尽快将 Jupyter Server 升级到不受 CVE-2022-24757 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2022-24757（Jupyter Server）",
   "NVD 說明（英文原文）：The Jupyter Server provides the backend (i.e. the core services, APIs, and REST endpoints) for Jupyter web applications. Prior to version 1.15.4, unauthorized actors can access sensitive information from server logs. Anytime a 5xx error is triggered, the auth cookie and other header values are recorded in Jupyter Server logs by default. Considering these logs do not require root access, an attacker can monitor these logs, steal sensitive auth/cookie information, and gain access to the Jupyter se",
   "請儘快將 Jupyter Server 升級到不受 CVE-2022-24757 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:jupyter-noauth:CVE-2022-29241": {
  "de": [
   "Bekannte Schwachstelle: CVE-2022-29241 (Jupyter Server)",
   "NVD-Beschreibung (englischer Originaltext): Jupyter Server provides the backend (i.e. the core services, APIs, and REST endpoints) for Jupyter web applications like Jupyter Notebook. Prior to version 1.17.1, if notebook server is started with a value of `root_dir` that contains the starting user's home directory, then the underlying REST API can be used to leak the access token assigned at start time by guessing/brute forcing the PID of the jupyter server. While this requires an authenticated user session, this URL can be used from a cros",
   "Aktualisieren Sie Jupyter Server so schnell wie möglich auf eine Version, die von CVE-2022-29241 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2022-29241 (Jupyter Server)",
   "Jupyter Server provides the backend (i.e. the core services, APIs, and REST endpoints) for Jupyter web applications like Jupyter Notebook. Prior to version 1.17.1, if notebook server is started with a value of `root_dir` that contains the starting user's home directory, then the underlying REST API can be used to leak the access token assigned at start time by guessing/brute forcing the PID of the jupyter server. While this requires an authenticated user session, this URL can be used from a cros",
   "Upgrade Jupyter Server to a version not affected by CVE-2022-29241 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2022-29241 (Jupyter Server)",
   "Descripción de NVD (texto original en inglés): Jupyter Server provides the backend (i.e. the core services, APIs, and REST endpoints) for Jupyter web applications like Jupyter Notebook. Prior to version 1.17.1, if notebook server is started with a value of `root_dir` that contains the starting user's home directory, then the underlying REST API can be used to leak the access token assigned at start time by guessing/brute forcing the PID of the jupyter server. While this requires an authenticated user session, this URL can be used from a cros",
   "Actualice Jupyter Server lo antes posible a una versión no afectada por CVE-2022-29241 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2022-29241 (Jupyter Server)",
   "Description NVD (texte original en anglais) : Jupyter Server provides the backend (i.e. the core services, APIs, and REST endpoints) for Jupyter web applications like Jupyter Notebook. Prior to version 1.17.1, if notebook server is started with a value of `root_dir` that contains the starting user's home directory, then the underlying REST API can be used to leak the access token assigned at start time by guessing/brute forcing the PID of the jupyter server. While this requires an authenticated user session, this URL can be used from a cros",
   "Mettez à niveau Jupyter Server dès que possible vers une version non affectée par CVE-2022-29241 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2022-29241 (Jupyter Server)",
   "Descrizione NVD (testo originale in inglese): Jupyter Server provides the backend (i.e. the core services, APIs, and REST endpoints) for Jupyter web applications like Jupyter Notebook. Prior to version 1.17.1, if notebook server is started with a value of `root_dir` that contains the starting user's home directory, then the underlying REST API can be used to leak the access token assigned at start time by guessing/brute forcing the PID of the jupyter server. While this requires an authenticated user session, this URL can be used from a cros",
   "Aggiorna Jupyter Server il prima possibile a una versione non interessata da CVE-2022-29241 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2022-29241 (Jupyter Server)",
   "NVDの説明（英語原文）: Jupyter Server provides the backend (i.e. the core services, APIs, and REST endpoints) for Jupyter web applications like Jupyter Notebook. Prior to version 1.17.1, if notebook server is started with a value of `root_dir` that contains the starting user's home directory, then the underlying REST API can be used to leak the access token assigned at start time by guessing/brute forcing the PID of the jupyter server. While this requires an authenticated user session, this URL can be used from a cros",
   "Jupyter Server を CVE-2022-29241 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2022-29241 (Jupyter Server)",
   "NVD 설명(영어 원문): Jupyter Server provides the backend (i.e. the core services, APIs, and REST endpoints) for Jupyter web applications like Jupyter Notebook. Prior to version 1.17.1, if notebook server is started with a value of `root_dir` that contains the starting user's home directory, then the underlying REST API can be used to leak the access token assigned at start time by guessing/brute forcing the PID of the jupyter server. While this requires an authenticated user session, this URL can be used from a cros",
   "Jupyter Server을(를) CVE-2022-29241의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2022-29241 (Jupyter Server)",
   "Descrição do NVD (texto original em inglês): Jupyter Server provides the backend (i.e. the core services, APIs, and REST endpoints) for Jupyter web applications like Jupyter Notebook. Prior to version 1.17.1, if notebook server is started with a value of `root_dir` that contains the starting user's home directory, then the underlying REST API can be used to leak the access token assigned at start time by guessing/brute forcing the PID of the jupyter server. While this requires an authenticated user session, this URL can be used from a cros",
   "Atualize o Jupyter Server o quanto antes para uma versão não afetada por CVE-2022-29241 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2022-29241（Jupyter Server）",
   "NVD 说明（英文原文）：Jupyter Server provides the backend (i.e. the core services, APIs, and REST endpoints) for Jupyter web applications like Jupyter Notebook. Prior to version 1.17.1, if notebook server is started with a value of `root_dir` that contains the starting user's home directory, then the underlying REST API can be used to leak the access token assigned at start time by guessing/brute forcing the PID of the jupyter server. While this requires an authenticated user session, this URL can be used from a cros",
   "请尽快将 Jupyter Server 升级到不受 CVE-2022-29241 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2022-29241（Jupyter Server）",
   "NVD 說明（英文原文）：Jupyter Server provides the backend (i.e. the core services, APIs, and REST endpoints) for Jupyter web applications like Jupyter Notebook. Prior to version 1.17.1, if notebook server is started with a value of `root_dir` that contains the starting user's home directory, then the underlying REST API can be used to leak the access token assigned at start time by guessing/brute forcing the PID of the jupyter server. While this requires an authenticated user session, this URL can be used from a cros",
   "請儘快將 Jupyter Server 升級到不受 CVE-2022-29241 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:jupyter-noauth:CVE-2024-35178": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-35178 (Jupyter Server)",
   "NVD-Beschreibung (englischer Originaltext): The Jupyter Server provides the backend for Jupyter web applications. Jupyter Server on Windows has a vulnerability that lets unauthenticated attackers leak the NTLMv2 password hash of the Windows user running the Jupyter server. An attacker can crack this password to gain access to the Windows machine hosting the Jupyter server, or access other network-accessible machines or 3rd party services using that credential. Or an attacker perform an NTLM relay attack without cracking the credential to ",
   "Aktualisieren Sie Jupyter Server so schnell wie möglich auf eine Version, die von CVE-2024-35178 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-35178 (Jupyter Server)",
   "The Jupyter Server provides the backend for Jupyter web applications. Jupyter Server on Windows has a vulnerability that lets unauthenticated attackers leak the NTLMv2 password hash of the Windows user running the Jupyter server. An attacker can crack this password to gain access to the Windows machine hosting the Jupyter server, or access other network-accessible machines or 3rd party services using that credential. Or an attacker perform an NTLM relay attack without cracking the credential to ",
   "Upgrade Jupyter Server to a version not affected by CVE-2024-35178 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-35178 (Jupyter Server)",
   "Descripción de NVD (texto original en inglés): The Jupyter Server provides the backend for Jupyter web applications. Jupyter Server on Windows has a vulnerability that lets unauthenticated attackers leak the NTLMv2 password hash of the Windows user running the Jupyter server. An attacker can crack this password to gain access to the Windows machine hosting the Jupyter server, or access other network-accessible machines or 3rd party services using that credential. Or an attacker perform an NTLM relay attack without cracking the credential to ",
   "Actualice Jupyter Server lo antes posible a una versión no afectada por CVE-2024-35178 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-35178 (Jupyter Server)",
   "Description NVD (texte original en anglais) : The Jupyter Server provides the backend for Jupyter web applications. Jupyter Server on Windows has a vulnerability that lets unauthenticated attackers leak the NTLMv2 password hash of the Windows user running the Jupyter server. An attacker can crack this password to gain access to the Windows machine hosting the Jupyter server, or access other network-accessible machines or 3rd party services using that credential. Or an attacker perform an NTLM relay attack without cracking the credential to ",
   "Mettez à niveau Jupyter Server dès que possible vers une version non affectée par CVE-2024-35178 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-35178 (Jupyter Server)",
   "Descrizione NVD (testo originale in inglese): The Jupyter Server provides the backend for Jupyter web applications. Jupyter Server on Windows has a vulnerability that lets unauthenticated attackers leak the NTLMv2 password hash of the Windows user running the Jupyter server. An attacker can crack this password to gain access to the Windows machine hosting the Jupyter server, or access other network-accessible machines or 3rd party services using that credential. Or an attacker perform an NTLM relay attack without cracking the credential to ",
   "Aggiorna Jupyter Server il prima possibile a una versione non interessata da CVE-2024-35178 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-35178 (Jupyter Server)",
   "NVDの説明（英語原文）: The Jupyter Server provides the backend for Jupyter web applications. Jupyter Server on Windows has a vulnerability that lets unauthenticated attackers leak the NTLMv2 password hash of the Windows user running the Jupyter server. An attacker can crack this password to gain access to the Windows machine hosting the Jupyter server, or access other network-accessible machines or 3rd party services using that credential. Or an attacker perform an NTLM relay attack without cracking the credential to ",
   "Jupyter Server を CVE-2024-35178 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-35178 (Jupyter Server)",
   "NVD 설명(영어 원문): The Jupyter Server provides the backend for Jupyter web applications. Jupyter Server on Windows has a vulnerability that lets unauthenticated attackers leak the NTLMv2 password hash of the Windows user running the Jupyter server. An attacker can crack this password to gain access to the Windows machine hosting the Jupyter server, or access other network-accessible machines or 3rd party services using that credential. Or an attacker perform an NTLM relay attack without cracking the credential to ",
   "Jupyter Server을(를) CVE-2024-35178의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-35178 (Jupyter Server)",
   "Descrição do NVD (texto original em inglês): The Jupyter Server provides the backend for Jupyter web applications. Jupyter Server on Windows has a vulnerability that lets unauthenticated attackers leak the NTLMv2 password hash of the Windows user running the Jupyter server. An attacker can crack this password to gain access to the Windows machine hosting the Jupyter server, or access other network-accessible machines or 3rd party services using that credential. Or an attacker perform an NTLM relay attack without cracking the credential to ",
   "Atualize o Jupyter Server o quanto antes para uma versão não afetada por CVE-2024-35178 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-35178（Jupyter Server）",
   "NVD 说明（英文原文）：The Jupyter Server provides the backend for Jupyter web applications. Jupyter Server on Windows has a vulnerability that lets unauthenticated attackers leak the NTLMv2 password hash of the Windows user running the Jupyter server. An attacker can crack this password to gain access to the Windows machine hosting the Jupyter server, or access other network-accessible machines or 3rd party services using that credential. Or an attacker perform an NTLM relay attack without cracking the credential to ",
   "请尽快将 Jupyter Server 升级到不受 CVE-2024-35178 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-35178（Jupyter Server）",
   "NVD 說明（英文原文）：The Jupyter Server provides the backend for Jupyter web applications. Jupyter Server on Windows has a vulnerability that lets unauthenticated attackers leak the NTLMv2 password hash of the Windows user running the Jupyter server. An attacker can crack this password to gain access to the Windows machine hosting the Jupyter server, or access other network-accessible machines or 3rd party services using that credential. Or an attacker perform an NTLM relay attack without cracking the credential to ",
   "請儘快將 Jupyter Server 升級到不受 CVE-2024-35178 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:jupyter-noauth:CVE-2026-35397": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-35397 (Jupyter Server)",
   "NVD-Beschreibung (englischer Originaltext): Jupyter Server is the backend for Jupyter web applications. In versions 2.17.0 and earlier, a path traversal vulnerability in the REST API allows an authenticated user to escape the configured root_dir and access sibling directories whose names begin with the same prefix as the root_dir. For example, with a root_dir named \"test\", the API permits access to a sibling directory named \"testtest\" through a crafted request to the /api/contents endpoint using encoded path components. An attacker can re",
   "Aktualisieren Sie Jupyter Server so schnell wie möglich auf eine Version, die von CVE-2026-35397 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-35397 (Jupyter Server)",
   "Jupyter Server is the backend for Jupyter web applications. In versions 2.17.0 and earlier, a path traversal vulnerability in the REST API allows an authenticated user to escape the configured root_dir and access sibling directories whose names begin with the same prefix as the root_dir. For example, with a root_dir named \"test\", the API permits access to a sibling directory named \"testtest\" through a crafted request to the /api/contents endpoint using encoded path components. An attacker can re",
   "Upgrade Jupyter Server to a version not affected by CVE-2026-35397 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-35397 (Jupyter Server)",
   "Descripción de NVD (texto original en inglés): Jupyter Server is the backend for Jupyter web applications. In versions 2.17.0 and earlier, a path traversal vulnerability in the REST API allows an authenticated user to escape the configured root_dir and access sibling directories whose names begin with the same prefix as the root_dir. For example, with a root_dir named \"test\", the API permits access to a sibling directory named \"testtest\" through a crafted request to the /api/contents endpoint using encoded path components. An attacker can re",
   "Actualice Jupyter Server lo antes posible a una versión no afectada por CVE-2026-35397 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-35397 (Jupyter Server)",
   "Description NVD (texte original en anglais) : Jupyter Server is the backend for Jupyter web applications. In versions 2.17.0 and earlier, a path traversal vulnerability in the REST API allows an authenticated user to escape the configured root_dir and access sibling directories whose names begin with the same prefix as the root_dir. For example, with a root_dir named \"test\", the API permits access to a sibling directory named \"testtest\" through a crafted request to the /api/contents endpoint using encoded path components. An attacker can re",
   "Mettez à niveau Jupyter Server dès que possible vers une version non affectée par CVE-2026-35397 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-35397 (Jupyter Server)",
   "Descrizione NVD (testo originale in inglese): Jupyter Server is the backend for Jupyter web applications. In versions 2.17.0 and earlier, a path traversal vulnerability in the REST API allows an authenticated user to escape the configured root_dir and access sibling directories whose names begin with the same prefix as the root_dir. For example, with a root_dir named \"test\", the API permits access to a sibling directory named \"testtest\" through a crafted request to the /api/contents endpoint using encoded path components. An attacker can re",
   "Aggiorna Jupyter Server il prima possibile a una versione non interessata da CVE-2026-35397 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-35397 (Jupyter Server)",
   "NVDの説明（英語原文）: Jupyter Server is the backend for Jupyter web applications. In versions 2.17.0 and earlier, a path traversal vulnerability in the REST API allows an authenticated user to escape the configured root_dir and access sibling directories whose names begin with the same prefix as the root_dir. For example, with a root_dir named \"test\", the API permits access to a sibling directory named \"testtest\" through a crafted request to the /api/contents endpoint using encoded path components. An attacker can re",
   "Jupyter Server を CVE-2026-35397 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-35397 (Jupyter Server)",
   "NVD 설명(영어 원문): Jupyter Server is the backend for Jupyter web applications. In versions 2.17.0 and earlier, a path traversal vulnerability in the REST API allows an authenticated user to escape the configured root_dir and access sibling directories whose names begin with the same prefix as the root_dir. For example, with a root_dir named \"test\", the API permits access to a sibling directory named \"testtest\" through a crafted request to the /api/contents endpoint using encoded path components. An attacker can re",
   "Jupyter Server을(를) CVE-2026-35397의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-35397 (Jupyter Server)",
   "Descrição do NVD (texto original em inglês): Jupyter Server is the backend for Jupyter web applications. In versions 2.17.0 and earlier, a path traversal vulnerability in the REST API allows an authenticated user to escape the configured root_dir and access sibling directories whose names begin with the same prefix as the root_dir. For example, with a root_dir named \"test\", the API permits access to a sibling directory named \"testtest\" through a crafted request to the /api/contents endpoint using encoded path components. An attacker can re",
   "Atualize o Jupyter Server o quanto antes para uma versão não afetada por CVE-2026-35397 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-35397（Jupyter Server）",
   "NVD 说明（英文原文）：Jupyter Server is the backend for Jupyter web applications. In versions 2.17.0 and earlier, a path traversal vulnerability in the REST API allows an authenticated user to escape the configured root_dir and access sibling directories whose names begin with the same prefix as the root_dir. For example, with a root_dir named \"test\", the API permits access to a sibling directory named \"testtest\" through a crafted request to the /api/contents endpoint using encoded path components. An attacker can re",
   "请尽快将 Jupyter Server 升级到不受 CVE-2026-35397 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-35397（Jupyter Server）",
   "NVD 說明（英文原文）：Jupyter Server is the backend for Jupyter web applications. In versions 2.17.0 and earlier, a path traversal vulnerability in the REST API allows an authenticated user to escape the configured root_dir and access sibling directories whose names begin with the same prefix as the root_dir. For example, with a root_dir named \"test\", the API permits access to a sibling directory named \"testtest\" through a crafted request to the /api/contents endpoint using encoded path components. An attacker can re",
   "請儘快將 Jupyter Server 升級到不受 CVE-2026-35397 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:jupyter-noauth:CVE-2026-40110": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-40110 (Jupyter Server)",
   "NVD-Beschreibung (englischer Originaltext): Jupyter Server is the backend for Jupyter web applications. In versions 2.17.0 and earlier, the Origin header validation uses Python's re.match() to check incoming origins against the allow_origin_pat configuration value. Because re.match() only anchors at the start of the string and does not require a full match, a pattern intended to match only a trusted domain (e.g., trusted.example.com) will also match any origin that begins with that domain followed by additional characters (e.g., trusted.e",
   "Aktualisieren Sie Jupyter Server so schnell wie möglich auf eine Version, die von CVE-2026-40110 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-40110 (Jupyter Server)",
   "Jupyter Server is the backend for Jupyter web applications. In versions 2.17.0 and earlier, the Origin header validation uses Python's re.match() to check incoming origins against the allow_origin_pat configuration value. Because re.match() only anchors at the start of the string and does not require a full match, a pattern intended to match only a trusted domain (e.g., trusted.example.com) will also match any origin that begins with that domain followed by additional characters (e.g., trusted.e",
   "Upgrade Jupyter Server to a version not affected by CVE-2026-40110 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-40110 (Jupyter Server)",
   "Descripción de NVD (texto original en inglés): Jupyter Server is the backend for Jupyter web applications. In versions 2.17.0 and earlier, the Origin header validation uses Python's re.match() to check incoming origins against the allow_origin_pat configuration value. Because re.match() only anchors at the start of the string and does not require a full match, a pattern intended to match only a trusted domain (e.g., trusted.example.com) will also match any origin that begins with that domain followed by additional characters (e.g., trusted.e",
   "Actualice Jupyter Server lo antes posible a una versión no afectada por CVE-2026-40110 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-40110 (Jupyter Server)",
   "Description NVD (texte original en anglais) : Jupyter Server is the backend for Jupyter web applications. In versions 2.17.0 and earlier, the Origin header validation uses Python's re.match() to check incoming origins against the allow_origin_pat configuration value. Because re.match() only anchors at the start of the string and does not require a full match, a pattern intended to match only a trusted domain (e.g., trusted.example.com) will also match any origin that begins with that domain followed by additional characters (e.g., trusted.e",
   "Mettez à niveau Jupyter Server dès que possible vers une version non affectée par CVE-2026-40110 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-40110 (Jupyter Server)",
   "Descrizione NVD (testo originale in inglese): Jupyter Server is the backend for Jupyter web applications. In versions 2.17.0 and earlier, the Origin header validation uses Python's re.match() to check incoming origins against the allow_origin_pat configuration value. Because re.match() only anchors at the start of the string and does not require a full match, a pattern intended to match only a trusted domain (e.g., trusted.example.com) will also match any origin that begins with that domain followed by additional characters (e.g., trusted.e",
   "Aggiorna Jupyter Server il prima possibile a una versione non interessata da CVE-2026-40110 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-40110 (Jupyter Server)",
   "NVDの説明（英語原文）: Jupyter Server is the backend for Jupyter web applications. In versions 2.17.0 and earlier, the Origin header validation uses Python's re.match() to check incoming origins against the allow_origin_pat configuration value. Because re.match() only anchors at the start of the string and does not require a full match, a pattern intended to match only a trusted domain (e.g., trusted.example.com) will also match any origin that begins with that domain followed by additional characters (e.g., trusted.e",
   "Jupyter Server を CVE-2026-40110 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-40110 (Jupyter Server)",
   "NVD 설명(영어 원문): Jupyter Server is the backend for Jupyter web applications. In versions 2.17.0 and earlier, the Origin header validation uses Python's re.match() to check incoming origins against the allow_origin_pat configuration value. Because re.match() only anchors at the start of the string and does not require a full match, a pattern intended to match only a trusted domain (e.g., trusted.example.com) will also match any origin that begins with that domain followed by additional characters (e.g., trusted.e",
   "Jupyter Server을(를) CVE-2026-40110의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-40110 (Jupyter Server)",
   "Descrição do NVD (texto original em inglês): Jupyter Server is the backend for Jupyter web applications. In versions 2.17.0 and earlier, the Origin header validation uses Python's re.match() to check incoming origins against the allow_origin_pat configuration value. Because re.match() only anchors at the start of the string and does not require a full match, a pattern intended to match only a trusted domain (e.g., trusted.example.com) will also match any origin that begins with that domain followed by additional characters (e.g., trusted.e",
   "Atualize o Jupyter Server o quanto antes para uma versão não afetada por CVE-2026-40110 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-40110（Jupyter Server）",
   "NVD 说明（英文原文）：Jupyter Server is the backend for Jupyter web applications. In versions 2.17.0 and earlier, the Origin header validation uses Python's re.match() to check incoming origins against the allow_origin_pat configuration value. Because re.match() only anchors at the start of the string and does not require a full match, a pattern intended to match only a trusted domain (e.g., trusted.example.com) will also match any origin that begins with that domain followed by additional characters (e.g., trusted.e",
   "请尽快将 Jupyter Server 升级到不受 CVE-2026-40110 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-40110（Jupyter Server）",
   "NVD 說明（英文原文）：Jupyter Server is the backend for Jupyter web applications. In versions 2.17.0 and earlier, the Origin header validation uses Python's re.match() to check incoming origins against the allow_origin_pat configuration value. Because re.match() only anchors at the start of the string and does not require a full match, a pattern intended to match only a trusted domain (e.g., trusted.example.com) will also match any origin that begins with that domain followed by additional characters (e.g., trusted.e",
   "請儘快將 Jupyter Server 升級到不受 CVE-2026-40110 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:jupyter-noauth:CVE-2026-5422": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-5422 (Jupyter Server)",
   "NVD-Beschreibung (englischer Originaltext): A path traversal vulnerability exists in jupyter-server version 2.17.0 due to an incorrect root directory boundary check in the _get_os_path() function within jupyter_server/services/contents/fileio.py. The check uses startswith(root) without appending a trailing path separator, allowing sibling directories with names starting with the same prefix as root_dir to bypass the check. Additionally, the to_os_path() function in utils.py does not strip \"..\" from path parts, enabling traversal sequences",
   "Aktualisieren Sie Jupyter Server so schnell wie möglich auf eine Version, die von CVE-2026-5422 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-5422 (Jupyter Server)",
   "A path traversal vulnerability exists in jupyter-server version 2.17.0 due to an incorrect root directory boundary check in the _get_os_path() function within jupyter_server/services/contents/fileio.py. The check uses startswith(root) without appending a trailing path separator, allowing sibling directories with names starting with the same prefix as root_dir to bypass the check. Additionally, the to_os_path() function in utils.py does not strip \"..\" from path parts, enabling traversal sequences",
   "Upgrade Jupyter Server to a version not affected by CVE-2026-5422 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-5422 (Jupyter Server)",
   "Descripción de NVD (texto original en inglés): A path traversal vulnerability exists in jupyter-server version 2.17.0 due to an incorrect root directory boundary check in the _get_os_path() function within jupyter_server/services/contents/fileio.py. The check uses startswith(root) without appending a trailing path separator, allowing sibling directories with names starting with the same prefix as root_dir to bypass the check. Additionally, the to_os_path() function in utils.py does not strip \"..\" from path parts, enabling traversal sequences",
   "Actualice Jupyter Server lo antes posible a una versión no afectada por CVE-2026-5422 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-5422 (Jupyter Server)",
   "Description NVD (texte original en anglais) : A path traversal vulnerability exists in jupyter-server version 2.17.0 due to an incorrect root directory boundary check in the _get_os_path() function within jupyter_server/services/contents/fileio.py. The check uses startswith(root) without appending a trailing path separator, allowing sibling directories with names starting with the same prefix as root_dir to bypass the check. Additionally, the to_os_path() function in utils.py does not strip \"..\" from path parts, enabling traversal sequences",
   "Mettez à niveau Jupyter Server dès que possible vers une version non affectée par CVE-2026-5422 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-5422 (Jupyter Server)",
   "Descrizione NVD (testo originale in inglese): A path traversal vulnerability exists in jupyter-server version 2.17.0 due to an incorrect root directory boundary check in the _get_os_path() function within jupyter_server/services/contents/fileio.py. The check uses startswith(root) without appending a trailing path separator, allowing sibling directories with names starting with the same prefix as root_dir to bypass the check. Additionally, the to_os_path() function in utils.py does not strip \"..\" from path parts, enabling traversal sequences",
   "Aggiorna Jupyter Server il prima possibile a una versione non interessata da CVE-2026-5422 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-5422 (Jupyter Server)",
   "NVDの説明（英語原文）: A path traversal vulnerability exists in jupyter-server version 2.17.0 due to an incorrect root directory boundary check in the _get_os_path() function within jupyter_server/services/contents/fileio.py. The check uses startswith(root) without appending a trailing path separator, allowing sibling directories with names starting with the same prefix as root_dir to bypass the check. Additionally, the to_os_path() function in utils.py does not strip \"..\" from path parts, enabling traversal sequences",
   "Jupyter Server を CVE-2026-5422 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-5422 (Jupyter Server)",
   "NVD 설명(영어 원문): A path traversal vulnerability exists in jupyter-server version 2.17.0 due to an incorrect root directory boundary check in the _get_os_path() function within jupyter_server/services/contents/fileio.py. The check uses startswith(root) without appending a trailing path separator, allowing sibling directories with names starting with the same prefix as root_dir to bypass the check. Additionally, the to_os_path() function in utils.py does not strip \"..\" from path parts, enabling traversal sequences",
   "Jupyter Server을(를) CVE-2026-5422의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-5422 (Jupyter Server)",
   "Descrição do NVD (texto original em inglês): A path traversal vulnerability exists in jupyter-server version 2.17.0 due to an incorrect root directory boundary check in the _get_os_path() function within jupyter_server/services/contents/fileio.py. The check uses startswith(root) without appending a trailing path separator, allowing sibling directories with names starting with the same prefix as root_dir to bypass the check. Additionally, the to_os_path() function in utils.py does not strip \"..\" from path parts, enabling traversal sequences",
   "Atualize o Jupyter Server o quanto antes para uma versão não afetada por CVE-2026-5422 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-5422（Jupyter Server）",
   "NVD 说明（英文原文）：A path traversal vulnerability exists in jupyter-server version 2.17.0 due to an incorrect root directory boundary check in the _get_os_path() function within jupyter_server/services/contents/fileio.py. The check uses startswith(root) without appending a trailing path separator, allowing sibling directories with names starting with the same prefix as root_dir to bypass the check. Additionally, the to_os_path() function in utils.py does not strip \"..\" from path parts, enabling traversal sequences",
   "请尽快将 Jupyter Server 升级到不受 CVE-2026-5422 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-5422（Jupyter Server）",
   "NVD 說明（英文原文）：A path traversal vulnerability exists in jupyter-server version 2.17.0 due to an incorrect root directory boundary check in the _get_os_path() function within jupyter_server/services/contents/fileio.py. The check uses startswith(root) without appending a trailing path separator, allowing sibling directories with names starting with the same prefix as root_dir to bypass the check. Additionally, the to_os_path() function in utils.py does not strip \"..\" from path parts, enabling traversal sequences",
   "請儘快將 Jupyter Server 升級到不受 CVE-2026-5422 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:jupyter-noauth:CVE-2026-6657": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-6657 (Jupyter Server)",
   "NVD-Beschreibung (englischer Originaltext): A vulnerability in jupyter-server versions 1.12.0 through 2.17.0 allows an attacker to bypass CORS origin validation when the `allow_origin_pat` configuration is used. The issue arises from the use of `re.match()` for validating the `Origin` header, which only anchors at the start of the string. This allows attacker-controlled domains such as `trusted.example.com.evil.com` to pass validation against patterns intended to match `trusted.example.com`. The vulnerability affects multiple locations in",
   "Aktualisieren Sie Jupyter Server so schnell wie möglich auf eine Version, die von CVE-2026-6657 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-6657 (Jupyter Server)",
   "A vulnerability in jupyter-server versions 1.12.0 through 2.17.0 allows an attacker to bypass CORS origin validation when the `allow_origin_pat` configuration is used. The issue arises from the use of `re.match()` for validating the `Origin` header, which only anchors at the start of the string. This allows attacker-controlled domains such as `trusted.example.com.evil.com` to pass validation against patterns intended to match `trusted.example.com`. The vulnerability affects multiple locations in",
   "Upgrade Jupyter Server to a version not affected by CVE-2026-6657 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-6657 (Jupyter Server)",
   "Descripción de NVD (texto original en inglés): A vulnerability in jupyter-server versions 1.12.0 through 2.17.0 allows an attacker to bypass CORS origin validation when the `allow_origin_pat` configuration is used. The issue arises from the use of `re.match()` for validating the `Origin` header, which only anchors at the start of the string. This allows attacker-controlled domains such as `trusted.example.com.evil.com` to pass validation against patterns intended to match `trusted.example.com`. The vulnerability affects multiple locations in",
   "Actualice Jupyter Server lo antes posible a una versión no afectada por CVE-2026-6657 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-6657 (Jupyter Server)",
   "Description NVD (texte original en anglais) : A vulnerability in jupyter-server versions 1.12.0 through 2.17.0 allows an attacker to bypass CORS origin validation when the `allow_origin_pat` configuration is used. The issue arises from the use of `re.match()` for validating the `Origin` header, which only anchors at the start of the string. This allows attacker-controlled domains such as `trusted.example.com.evil.com` to pass validation against patterns intended to match `trusted.example.com`. The vulnerability affects multiple locations in",
   "Mettez à niveau Jupyter Server dès que possible vers une version non affectée par CVE-2026-6657 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-6657 (Jupyter Server)",
   "Descrizione NVD (testo originale in inglese): A vulnerability in jupyter-server versions 1.12.0 through 2.17.0 allows an attacker to bypass CORS origin validation when the `allow_origin_pat` configuration is used. The issue arises from the use of `re.match()` for validating the `Origin` header, which only anchors at the start of the string. This allows attacker-controlled domains such as `trusted.example.com.evil.com` to pass validation against patterns intended to match `trusted.example.com`. The vulnerability affects multiple locations in",
   "Aggiorna Jupyter Server il prima possibile a una versione non interessata da CVE-2026-6657 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-6657 (Jupyter Server)",
   "NVDの説明（英語原文）: A vulnerability in jupyter-server versions 1.12.0 through 2.17.0 allows an attacker to bypass CORS origin validation when the `allow_origin_pat` configuration is used. The issue arises from the use of `re.match()` for validating the `Origin` header, which only anchors at the start of the string. This allows attacker-controlled domains such as `trusted.example.com.evil.com` to pass validation against patterns intended to match `trusted.example.com`. The vulnerability affects multiple locations in",
   "Jupyter Server を CVE-2026-6657 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-6657 (Jupyter Server)",
   "NVD 설명(영어 원문): A vulnerability in jupyter-server versions 1.12.0 through 2.17.0 allows an attacker to bypass CORS origin validation when the `allow_origin_pat` configuration is used. The issue arises from the use of `re.match()` for validating the `Origin` header, which only anchors at the start of the string. This allows attacker-controlled domains such as `trusted.example.com.evil.com` to pass validation against patterns intended to match `trusted.example.com`. The vulnerability affects multiple locations in",
   "Jupyter Server을(를) CVE-2026-6657의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-6657 (Jupyter Server)",
   "Descrição do NVD (texto original em inglês): A vulnerability in jupyter-server versions 1.12.0 through 2.17.0 allows an attacker to bypass CORS origin validation when the `allow_origin_pat` configuration is used. The issue arises from the use of `re.match()` for validating the `Origin` header, which only anchors at the start of the string. This allows attacker-controlled domains such as `trusted.example.com.evil.com` to pass validation against patterns intended to match `trusted.example.com`. The vulnerability affects multiple locations in",
   "Atualize o Jupyter Server o quanto antes para uma versão não afetada por CVE-2026-6657 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-6657（Jupyter Server）",
   "NVD 说明（英文原文）：A vulnerability in jupyter-server versions 1.12.0 through 2.17.0 allows an attacker to bypass CORS origin validation when the `allow_origin_pat` configuration is used. The issue arises from the use of `re.match()` for validating the `Origin` header, which only anchors at the start of the string. This allows attacker-controlled domains such as `trusted.example.com.evil.com` to pass validation against patterns intended to match `trusted.example.com`. The vulnerability affects multiple locations in",
   "请尽快将 Jupyter Server 升级到不受 CVE-2026-6657 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-6657（Jupyter Server）",
   "NVD 說明（英文原文）：A vulnerability in jupyter-server versions 1.12.0 through 2.17.0 allows an attacker to bypass CORS origin validation when the `allow_origin_pat` configuration is used. The issue arises from the use of `re.match()` for validating the `Origin` header, which only anchors at the start of the string. This allows attacker-controlled domains such as `trusted.example.com.evil.com` to pass validation against patterns intended to match `trusted.example.com`. The vulnerability affects multiple locations in",
   "請儘快將 Jupyter Server 升級到不受 CVE-2026-6657 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:memcached-noauth:CVE-2016-8704": {
  "de": [
   "Bekannte Schwachstelle: CVE-2016-8704 (Memcached)",
   "NVD-Beschreibung (englischer Originaltext): An integer overflow in the process_bin_append_prepend function in Memcached, which is responsible for processing multiple commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "Aktualisieren Sie Memcached so schnell wie möglich auf eine Version, die von CVE-2016-8704 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2016-8704 (Memcached)",
   "An integer overflow in the process_bin_append_prepend function in Memcached, which is responsible for processing multiple commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "Upgrade Memcached to a version not affected by CVE-2016-8704 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2016-8704 (Memcached)",
   "Descripción de NVD (texto original en inglés): An integer overflow in the process_bin_append_prepend function in Memcached, which is responsible for processing multiple commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "Actualice Memcached lo antes posible a una versión no afectada por CVE-2016-8704 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2016-8704 (Memcached)",
   "Description NVD (texte original en anglais) : An integer overflow in the process_bin_append_prepend function in Memcached, which is responsible for processing multiple commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "Mettez à niveau Memcached dès que possible vers une version non affectée par CVE-2016-8704 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2016-8704 (Memcached)",
   "Descrizione NVD (testo originale in inglese): An integer overflow in the process_bin_append_prepend function in Memcached, which is responsible for processing multiple commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "Aggiorna Memcached il prima possibile a una versione non interessata da CVE-2016-8704 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2016-8704 (Memcached)",
   "NVDの説明（英語原文）: An integer overflow in the process_bin_append_prepend function in Memcached, which is responsible for processing multiple commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "Memcached を CVE-2016-8704 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2016-8704 (Memcached)",
   "NVD 설명(영어 원문): An integer overflow in the process_bin_append_prepend function in Memcached, which is responsible for processing multiple commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "Memcached을(를) CVE-2016-8704의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2016-8704 (Memcached)",
   "Descrição do NVD (texto original em inglês): An integer overflow in the process_bin_append_prepend function in Memcached, which is responsible for processing multiple commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "Atualize o Memcached o quanto antes para uma versão não afetada por CVE-2016-8704 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2016-8704（Memcached）",
   "NVD 说明（英文原文）：An integer overflow in the process_bin_append_prepend function in Memcached, which is responsible for processing multiple commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "请尽快将 Memcached 升级到不受 CVE-2016-8704 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2016-8704（Memcached）",
   "NVD 說明（英文原文）：An integer overflow in the process_bin_append_prepend function in Memcached, which is responsible for processing multiple commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "請儘快將 Memcached 升級到不受 CVE-2016-8704 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:memcached-noauth:CVE-2016-8705": {
  "de": [
   "Bekannte Schwachstelle: CVE-2016-8705 (Memcached)",
   "NVD-Beschreibung (englischer Originaltext): Multiple integer overflows in process_bin_update function in Memcached, which is responsible for processing multiple commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "Aktualisieren Sie Memcached so schnell wie möglich auf eine Version, die von CVE-2016-8705 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2016-8705 (Memcached)",
   "Multiple integer overflows in process_bin_update function in Memcached, which is responsible for processing multiple commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "Upgrade Memcached to a version not affected by CVE-2016-8705 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2016-8705 (Memcached)",
   "Descripción de NVD (texto original en inglés): Multiple integer overflows in process_bin_update function in Memcached, which is responsible for processing multiple commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "Actualice Memcached lo antes posible a una versión no afectada por CVE-2016-8705 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2016-8705 (Memcached)",
   "Description NVD (texte original en anglais) : Multiple integer overflows in process_bin_update function in Memcached, which is responsible for processing multiple commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "Mettez à niveau Memcached dès que possible vers une version non affectée par CVE-2016-8705 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2016-8705 (Memcached)",
   "Descrizione NVD (testo originale in inglese): Multiple integer overflows in process_bin_update function in Memcached, which is responsible for processing multiple commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "Aggiorna Memcached il prima possibile a una versione non interessata da CVE-2016-8705 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2016-8705 (Memcached)",
   "NVDの説明（英語原文）: Multiple integer overflows in process_bin_update function in Memcached, which is responsible for processing multiple commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "Memcached を CVE-2016-8705 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2016-8705 (Memcached)",
   "NVD 설명(영어 원문): Multiple integer overflows in process_bin_update function in Memcached, which is responsible for processing multiple commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "Memcached을(를) CVE-2016-8705의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2016-8705 (Memcached)",
   "Descrição do NVD (texto original em inglês): Multiple integer overflows in process_bin_update function in Memcached, which is responsible for processing multiple commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "Atualize o Memcached o quanto antes para uma versão não afetada por CVE-2016-8705 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2016-8705（Memcached）",
   "NVD 说明（英文原文）：Multiple integer overflows in process_bin_update function in Memcached, which is responsible for processing multiple commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "请尽快将 Memcached 升级到不受 CVE-2016-8705 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2016-8705（Memcached）",
   "NVD 說明（英文原文）：Multiple integer overflows in process_bin_update function in Memcached, which is responsible for processing multiple commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "請儘快將 Memcached 升級到不受 CVE-2016-8705 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:memcached-noauth:CVE-2016-8706": {
  "de": [
   "Bekannte Schwachstelle: CVE-2016-8706 (Memcached)",
   "NVD-Beschreibung (englischer Originaltext): An integer overflow in process_bin_sasl_auth function in Memcached, which is responsible for authentication commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "Aktualisieren Sie Memcached so schnell wie möglich auf eine Version, die von CVE-2016-8706 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2016-8706 (Memcached)",
   "An integer overflow in process_bin_sasl_auth function in Memcached, which is responsible for authentication commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "Upgrade Memcached to a version not affected by CVE-2016-8706 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2016-8706 (Memcached)",
   "Descripción de NVD (texto original en inglés): An integer overflow in process_bin_sasl_auth function in Memcached, which is responsible for authentication commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "Actualice Memcached lo antes posible a una versión no afectada por CVE-2016-8706 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2016-8706 (Memcached)",
   "Description NVD (texte original en anglais) : An integer overflow in process_bin_sasl_auth function in Memcached, which is responsible for authentication commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "Mettez à niveau Memcached dès que possible vers une version non affectée par CVE-2016-8706 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2016-8706 (Memcached)",
   "Descrizione NVD (testo originale in inglese): An integer overflow in process_bin_sasl_auth function in Memcached, which is responsible for authentication commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "Aggiorna Memcached il prima possibile a una versione non interessata da CVE-2016-8706 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2016-8706 (Memcached)",
   "NVDの説明（英語原文）: An integer overflow in process_bin_sasl_auth function in Memcached, which is responsible for authentication commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "Memcached を CVE-2016-8706 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2016-8706 (Memcached)",
   "NVD 설명(영어 원문): An integer overflow in process_bin_sasl_auth function in Memcached, which is responsible for authentication commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "Memcached을(를) CVE-2016-8706의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2016-8706 (Memcached)",
   "Descrição do NVD (texto original em inglês): An integer overflow in process_bin_sasl_auth function in Memcached, which is responsible for authentication commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "Atualize o Memcached o quanto antes para uma versão não afetada por CVE-2016-8706 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2016-8706（Memcached）",
   "NVD 说明（英文原文）：An integer overflow in process_bin_sasl_auth function in Memcached, which is responsible for authentication commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "请尽快将 Memcached 升级到不受 CVE-2016-8706 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2016-8706（Memcached）",
   "NVD 說明（英文原文）：An integer overflow in process_bin_sasl_auth function in Memcached, which is responsible for authentication commands of Memcached binary protocol, can be abused to cause heap overflow and lead to remote code execution.",
   "請儘快將 Memcached 升級到不受 CVE-2016-8706 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:memcached-noauth:CVE-2017-9951": {
  "de": [
   "Bekannte Schwachstelle: CVE-2017-9951 (Memcached)",
   "NVD-Beschreibung (englischer Originaltext): The try_read_command function in memcached.c in memcached before 1.4.39 allows remote attackers to cause a denial of service (segmentation fault) via a request to add/set a key, which makes a comparison between signed and unsigned int and triggers a heap-based buffer over-read. NOTE: this vulnerability exists because of an incomplete fix for CVE-2016-8705.",
   "Aktualisieren Sie Memcached so schnell wie möglich auf eine Version, die von CVE-2017-9951 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2017-9951 (Memcached)",
   "The try_read_command function in memcached.c in memcached before 1.4.39 allows remote attackers to cause a denial of service (segmentation fault) via a request to add/set a key, which makes a comparison between signed and unsigned int and triggers a heap-based buffer over-read. NOTE: this vulnerability exists because of an incomplete fix for CVE-2016-8705.",
   "Upgrade Memcached to a version not affected by CVE-2017-9951 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2017-9951 (Memcached)",
   "Descripción de NVD (texto original en inglés): The try_read_command function in memcached.c in memcached before 1.4.39 allows remote attackers to cause a denial of service (segmentation fault) via a request to add/set a key, which makes a comparison between signed and unsigned int and triggers a heap-based buffer over-read. NOTE: this vulnerability exists because of an incomplete fix for CVE-2016-8705.",
   "Actualice Memcached lo antes posible a una versión no afectada por CVE-2017-9951 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2017-9951 (Memcached)",
   "Description NVD (texte original en anglais) : The try_read_command function in memcached.c in memcached before 1.4.39 allows remote attackers to cause a denial of service (segmentation fault) via a request to add/set a key, which makes a comparison between signed and unsigned int and triggers a heap-based buffer over-read. NOTE: this vulnerability exists because of an incomplete fix for CVE-2016-8705.",
   "Mettez à niveau Memcached dès que possible vers une version non affectée par CVE-2017-9951 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2017-9951 (Memcached)",
   "Descrizione NVD (testo originale in inglese): The try_read_command function in memcached.c in memcached before 1.4.39 allows remote attackers to cause a denial of service (segmentation fault) via a request to add/set a key, which makes a comparison between signed and unsigned int and triggers a heap-based buffer over-read. NOTE: this vulnerability exists because of an incomplete fix for CVE-2016-8705.",
   "Aggiorna Memcached il prima possibile a una versione non interessata da CVE-2017-9951 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2017-9951 (Memcached)",
   "NVDの説明（英語原文）: The try_read_command function in memcached.c in memcached before 1.4.39 allows remote attackers to cause a denial of service (segmentation fault) via a request to add/set a key, which makes a comparison between signed and unsigned int and triggers a heap-based buffer over-read. NOTE: this vulnerability exists because of an incomplete fix for CVE-2016-8705.",
   "Memcached を CVE-2017-9951 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2017-9951 (Memcached)",
   "NVD 설명(영어 원문): The try_read_command function in memcached.c in memcached before 1.4.39 allows remote attackers to cause a denial of service (segmentation fault) via a request to add/set a key, which makes a comparison between signed and unsigned int and triggers a heap-based buffer over-read. NOTE: this vulnerability exists because of an incomplete fix for CVE-2016-8705.",
   "Memcached을(를) CVE-2017-9951의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2017-9951 (Memcached)",
   "Descrição do NVD (texto original em inglês): The try_read_command function in memcached.c in memcached before 1.4.39 allows remote attackers to cause a denial of service (segmentation fault) via a request to add/set a key, which makes a comparison between signed and unsigned int and triggers a heap-based buffer over-read. NOTE: this vulnerability exists because of an incomplete fix for CVE-2016-8705.",
   "Atualize o Memcached o quanto antes para uma versão não afetada por CVE-2017-9951 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2017-9951（Memcached）",
   "NVD 说明（英文原文）：The try_read_command function in memcached.c in memcached before 1.4.39 allows remote attackers to cause a denial of service (segmentation fault) via a request to add/set a key, which makes a comparison between signed and unsigned int and triggers a heap-based buffer over-read. NOTE: this vulnerability exists because of an incomplete fix for CVE-2016-8705.",
   "请尽快将 Memcached 升级到不受 CVE-2017-9951 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2017-9951（Memcached）",
   "NVD 說明（英文原文）：The try_read_command function in memcached.c in memcached before 1.4.39 allows remote attackers to cause a denial of service (segmentation fault) via a request to add/set a key, which makes a comparison between signed and unsigned int and triggers a heap-based buffer over-read. NOTE: this vulnerability exists because of an incomplete fix for CVE-2016-8705.",
   "請儘快將 Memcached 升級到不受 CVE-2017-9951 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:memcached-noauth:CVE-2018-1000115": {
  "de": [
   "Bekannte Schwachstelle: CVE-2018-1000115 (Memcached)",
   "NVD-Beschreibung (englischer Originaltext): Memcached version 1.5.5 contains an Insufficient Control of Network Message Volume (Network Amplification, CWE-406) vulnerability in the UDP support of the memcached server that can result in denial of service via network flood (traffic amplification of 1:50,000 has been reported by reliable sources). This attack appear to be exploitable via network connectivity to port 11211 UDP. This vulnerability appears to have been fixed in 1.5.6 due to the disabling of the UDP protocol by default.",
   "Aktualisieren Sie Memcached so schnell wie möglich auf eine Version, die von CVE-2018-1000115 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2018-1000115 (Memcached)",
   "Memcached version 1.5.5 contains an Insufficient Control of Network Message Volume (Network Amplification, CWE-406) vulnerability in the UDP support of the memcached server that can result in denial of service via network flood (traffic amplification of 1:50,000 has been reported by reliable sources). This attack appear to be exploitable via network connectivity to port 11211 UDP. This vulnerability appears to have been fixed in 1.5.6 due to the disabling of the UDP protocol by default.",
   "Upgrade Memcached to a version not affected by CVE-2018-1000115 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2018-1000115 (Memcached)",
   "Descripción de NVD (texto original en inglés): Memcached version 1.5.5 contains an Insufficient Control of Network Message Volume (Network Amplification, CWE-406) vulnerability in the UDP support of the memcached server that can result in denial of service via network flood (traffic amplification of 1:50,000 has been reported by reliable sources). This attack appear to be exploitable via network connectivity to port 11211 UDP. This vulnerability appears to have been fixed in 1.5.6 due to the disabling of the UDP protocol by default.",
   "Actualice Memcached lo antes posible a una versión no afectada por CVE-2018-1000115 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2018-1000115 (Memcached)",
   "Description NVD (texte original en anglais) : Memcached version 1.5.5 contains an Insufficient Control of Network Message Volume (Network Amplification, CWE-406) vulnerability in the UDP support of the memcached server that can result in denial of service via network flood (traffic amplification of 1:50,000 has been reported by reliable sources). This attack appear to be exploitable via network connectivity to port 11211 UDP. This vulnerability appears to have been fixed in 1.5.6 due to the disabling of the UDP protocol by default.",
   "Mettez à niveau Memcached dès que possible vers une version non affectée par CVE-2018-1000115 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2018-1000115 (Memcached)",
   "Descrizione NVD (testo originale in inglese): Memcached version 1.5.5 contains an Insufficient Control of Network Message Volume (Network Amplification, CWE-406) vulnerability in the UDP support of the memcached server that can result in denial of service via network flood (traffic amplification of 1:50,000 has been reported by reliable sources). This attack appear to be exploitable via network connectivity to port 11211 UDP. This vulnerability appears to have been fixed in 1.5.6 due to the disabling of the UDP protocol by default.",
   "Aggiorna Memcached il prima possibile a una versione non interessata da CVE-2018-1000115 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2018-1000115 (Memcached)",
   "NVDの説明（英語原文）: Memcached version 1.5.5 contains an Insufficient Control of Network Message Volume (Network Amplification, CWE-406) vulnerability in the UDP support of the memcached server that can result in denial of service via network flood (traffic amplification of 1:50,000 has been reported by reliable sources). This attack appear to be exploitable via network connectivity to port 11211 UDP. This vulnerability appears to have been fixed in 1.5.6 due to the disabling of the UDP protocol by default.",
   "Memcached を CVE-2018-1000115 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2018-1000115 (Memcached)",
   "NVD 설명(영어 원문): Memcached version 1.5.5 contains an Insufficient Control of Network Message Volume (Network Amplification, CWE-406) vulnerability in the UDP support of the memcached server that can result in denial of service via network flood (traffic amplification of 1:50,000 has been reported by reliable sources). This attack appear to be exploitable via network connectivity to port 11211 UDP. This vulnerability appears to have been fixed in 1.5.6 due to the disabling of the UDP protocol by default.",
   "Memcached을(를) CVE-2018-1000115의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2018-1000115 (Memcached)",
   "Descrição do NVD (texto original em inglês): Memcached version 1.5.5 contains an Insufficient Control of Network Message Volume (Network Amplification, CWE-406) vulnerability in the UDP support of the memcached server that can result in denial of service via network flood (traffic amplification of 1:50,000 has been reported by reliable sources). This attack appear to be exploitable via network connectivity to port 11211 UDP. This vulnerability appears to have been fixed in 1.5.6 due to the disabling of the UDP protocol by default.",
   "Atualize o Memcached o quanto antes para uma versão não afetada por CVE-2018-1000115 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2018-1000115（Memcached）",
   "NVD 说明（英文原文）：Memcached version 1.5.5 contains an Insufficient Control of Network Message Volume (Network Amplification, CWE-406) vulnerability in the UDP support of the memcached server that can result in denial of service via network flood (traffic amplification of 1:50,000 has been reported by reliable sources). This attack appear to be exploitable via network connectivity to port 11211 UDP. This vulnerability appears to have been fixed in 1.5.6 due to the disabling of the UDP protocol by default.",
   "请尽快将 Memcached 升级到不受 CVE-2018-1000115 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2018-1000115（Memcached）",
   "NVD 說明（英文原文）：Memcached version 1.5.5 contains an Insufficient Control of Network Message Volume (Network Amplification, CWE-406) vulnerability in the UDP support of the memcached server that can result in denial of service via network flood (traffic amplification of 1:50,000 has been reported by reliable sources). This attack appear to be exploitable via network connectivity to port 11211 UDP. This vulnerability appears to have been fixed in 1.5.6 due to the disabling of the UDP protocol by default.",
   "請儘快將 Memcached 升級到不受 CVE-2018-1000115 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:memcached-noauth:CVE-2018-1000127": {
  "de": [
   "Bekannte Schwachstelle: CVE-2018-1000127 (Memcached)",
   "NVD-Beschreibung (englischer Originaltext): memcached version prior to 1.4.37 contains an Integer Overflow vulnerability in items.c:item_free() that can result in data corruption and deadlocks due to items existing in hash table being reused from free list. This attack appear to be exploitable via network connectivity to the memcached service. This vulnerability appears to have been fixed in 1.4.37 and later.",
   "Aktualisieren Sie Memcached so schnell wie möglich auf eine Version, die von CVE-2018-1000127 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2018-1000127 (Memcached)",
   "memcached version prior to 1.4.37 contains an Integer Overflow vulnerability in items.c:item_free() that can result in data corruption and deadlocks due to items existing in hash table being reused from free list. This attack appear to be exploitable via network connectivity to the memcached service. This vulnerability appears to have been fixed in 1.4.37 and later.",
   "Upgrade Memcached to a version not affected by CVE-2018-1000127 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2018-1000127 (Memcached)",
   "Descripción de NVD (texto original en inglés): memcached version prior to 1.4.37 contains an Integer Overflow vulnerability in items.c:item_free() that can result in data corruption and deadlocks due to items existing in hash table being reused from free list. This attack appear to be exploitable via network connectivity to the memcached service. This vulnerability appears to have been fixed in 1.4.37 and later.",
   "Actualice Memcached lo antes posible a una versión no afectada por CVE-2018-1000127 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2018-1000127 (Memcached)",
   "Description NVD (texte original en anglais) : memcached version prior to 1.4.37 contains an Integer Overflow vulnerability in items.c:item_free() that can result in data corruption and deadlocks due to items existing in hash table being reused from free list. This attack appear to be exploitable via network connectivity to the memcached service. This vulnerability appears to have been fixed in 1.4.37 and later.",
   "Mettez à niveau Memcached dès que possible vers une version non affectée par CVE-2018-1000127 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2018-1000127 (Memcached)",
   "Descrizione NVD (testo originale in inglese): memcached version prior to 1.4.37 contains an Integer Overflow vulnerability in items.c:item_free() that can result in data corruption and deadlocks due to items existing in hash table being reused from free list. This attack appear to be exploitable via network connectivity to the memcached service. This vulnerability appears to have been fixed in 1.4.37 and later.",
   "Aggiorna Memcached il prima possibile a una versione non interessata da CVE-2018-1000127 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2018-1000127 (Memcached)",
   "NVDの説明（英語原文）: memcached version prior to 1.4.37 contains an Integer Overflow vulnerability in items.c:item_free() that can result in data corruption and deadlocks due to items existing in hash table being reused from free list. This attack appear to be exploitable via network connectivity to the memcached service. This vulnerability appears to have been fixed in 1.4.37 and later.",
   "Memcached を CVE-2018-1000127 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2018-1000127 (Memcached)",
   "NVD 설명(영어 원문): memcached version prior to 1.4.37 contains an Integer Overflow vulnerability in items.c:item_free() that can result in data corruption and deadlocks due to items existing in hash table being reused from free list. This attack appear to be exploitable via network connectivity to the memcached service. This vulnerability appears to have been fixed in 1.4.37 and later.",
   "Memcached을(를) CVE-2018-1000127의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2018-1000127 (Memcached)",
   "Descrição do NVD (texto original em inglês): memcached version prior to 1.4.37 contains an Integer Overflow vulnerability in items.c:item_free() that can result in data corruption and deadlocks due to items existing in hash table being reused from free list. This attack appear to be exploitable via network connectivity to the memcached service. This vulnerability appears to have been fixed in 1.4.37 and later.",
   "Atualize o Memcached o quanto antes para uma versão não afetada por CVE-2018-1000127 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2018-1000127（Memcached）",
   "NVD 说明（英文原文）：memcached version prior to 1.4.37 contains an Integer Overflow vulnerability in items.c:item_free() that can result in data corruption and deadlocks due to items existing in hash table being reused from free list. This attack appear to be exploitable via network connectivity to the memcached service. This vulnerability appears to have been fixed in 1.4.37 and later.",
   "请尽快将 Memcached 升级到不受 CVE-2018-1000127 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2018-1000127（Memcached）",
   "NVD 說明（英文原文）：memcached version prior to 1.4.37 contains an Integer Overflow vulnerability in items.c:item_free() that can result in data corruption and deadlocks due to items existing in hash table being reused from free list. This attack appear to be exploitable via network connectivity to the memcached service. This vulnerability appears to have been fixed in 1.4.37 and later.",
   "請儘快將 Memcached 升級到不受 CVE-2018-1000127 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:memcached-noauth:CVE-2019-11596": {
  "de": [
   "Bekannte Schwachstelle: CVE-2019-11596 (Memcached)",
   "NVD-Beschreibung (englischer Originaltext): In memcached before 1.5.14, a NULL pointer dereference was found in the \"lru mode\" and \"lru temp_ttl\" commands. This causes a denial of service when parsing crafted lru command messages in process_lru_command in memcached.c.",
   "Aktualisieren Sie Memcached so schnell wie möglich auf eine Version, die von CVE-2019-11596 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2019-11596 (Memcached)",
   "In memcached before 1.5.14, a NULL pointer dereference was found in the \"lru mode\" and \"lru temp_ttl\" commands. This causes a denial of service when parsing crafted lru command messages in process_lru_command in memcached.c.",
   "Upgrade Memcached to a version not affected by CVE-2019-11596 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2019-11596 (Memcached)",
   "Descripción de NVD (texto original en inglés): In memcached before 1.5.14, a NULL pointer dereference was found in the \"lru mode\" and \"lru temp_ttl\" commands. This causes a denial of service when parsing crafted lru command messages in process_lru_command in memcached.c.",
   "Actualice Memcached lo antes posible a una versión no afectada por CVE-2019-11596 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2019-11596 (Memcached)",
   "Description NVD (texte original en anglais) : In memcached before 1.5.14, a NULL pointer dereference was found in the \"lru mode\" and \"lru temp_ttl\" commands. This causes a denial of service when parsing crafted lru command messages in process_lru_command in memcached.c.",
   "Mettez à niveau Memcached dès que possible vers une version non affectée par CVE-2019-11596 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2019-11596 (Memcached)",
   "Descrizione NVD (testo originale in inglese): In memcached before 1.5.14, a NULL pointer dereference was found in the \"lru mode\" and \"lru temp_ttl\" commands. This causes a denial of service when parsing crafted lru command messages in process_lru_command in memcached.c.",
   "Aggiorna Memcached il prima possibile a una versione non interessata da CVE-2019-11596 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2019-11596 (Memcached)",
   "NVDの説明（英語原文）: In memcached before 1.5.14, a NULL pointer dereference was found in the \"lru mode\" and \"lru temp_ttl\" commands. This causes a denial of service when parsing crafted lru command messages in process_lru_command in memcached.c.",
   "Memcached を CVE-2019-11596 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2019-11596 (Memcached)",
   "NVD 설명(영어 원문): In memcached before 1.5.14, a NULL pointer dereference was found in the \"lru mode\" and \"lru temp_ttl\" commands. This causes a denial of service when parsing crafted lru command messages in process_lru_command in memcached.c.",
   "Memcached을(를) CVE-2019-11596의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2019-11596 (Memcached)",
   "Descrição do NVD (texto original em inglês): In memcached before 1.5.14, a NULL pointer dereference was found in the \"lru mode\" and \"lru temp_ttl\" commands. This causes a denial of service when parsing crafted lru command messages in process_lru_command in memcached.c.",
   "Atualize o Memcached o quanto antes para uma versão não afetada por CVE-2019-11596 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2019-11596（Memcached）",
   "NVD 说明（英文原文）：In memcached before 1.5.14, a NULL pointer dereference was found in the \"lru mode\" and \"lru temp_ttl\" commands. This causes a denial of service when parsing crafted lru command messages in process_lru_command in memcached.c.",
   "请尽快将 Memcached 升级到不受 CVE-2019-11596 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2019-11596（Memcached）",
   "NVD 說明（英文原文）：In memcached before 1.5.14, a NULL pointer dereference was found in the \"lru mode\" and \"lru temp_ttl\" commands. This causes a denial of service when parsing crafted lru command messages in process_lru_command in memcached.c.",
   "請儘快將 Memcached 升級到不受 CVE-2019-11596 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:memcached-noauth:CVE-2019-15026": {
  "de": [
   "Bekannte Schwachstelle: CVE-2019-15026 (Memcached)",
   "NVD-Beschreibung (englischer Originaltext): memcached 1.5.16, when UNIX sockets are used, has a stack-based buffer over-read in conn_to_str in memcached.c.",
   "Aktualisieren Sie Memcached so schnell wie möglich auf eine Version, die von CVE-2019-15026 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2019-15026 (Memcached)",
   "memcached 1.5.16, when UNIX sockets are used, has a stack-based buffer over-read in conn_to_str in memcached.c.",
   "Upgrade Memcached to a version not affected by CVE-2019-15026 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2019-15026 (Memcached)",
   "Descripción de NVD (texto original en inglés): memcached 1.5.16, when UNIX sockets are used, has a stack-based buffer over-read in conn_to_str in memcached.c.",
   "Actualice Memcached lo antes posible a una versión no afectada por CVE-2019-15026 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2019-15026 (Memcached)",
   "Description NVD (texte original en anglais) : memcached 1.5.16, when UNIX sockets are used, has a stack-based buffer over-read in conn_to_str in memcached.c.",
   "Mettez à niveau Memcached dès que possible vers une version non affectée par CVE-2019-15026 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2019-15026 (Memcached)",
   "Descrizione NVD (testo originale in inglese): memcached 1.5.16, when UNIX sockets are used, has a stack-based buffer over-read in conn_to_str in memcached.c.",
   "Aggiorna Memcached il prima possibile a una versione non interessata da CVE-2019-15026 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2019-15026 (Memcached)",
   "NVDの説明（英語原文）: memcached 1.5.16, when UNIX sockets are used, has a stack-based buffer over-read in conn_to_str in memcached.c.",
   "Memcached を CVE-2019-15026 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2019-15026 (Memcached)",
   "NVD 설명(영어 원문): memcached 1.5.16, when UNIX sockets are used, has a stack-based buffer over-read in conn_to_str in memcached.c.",
   "Memcached을(를) CVE-2019-15026의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2019-15026 (Memcached)",
   "Descrição do NVD (texto original em inglês): memcached 1.5.16, when UNIX sockets are used, has a stack-based buffer over-read in conn_to_str in memcached.c.",
   "Atualize o Memcached o quanto antes para uma versão não afetada por CVE-2019-15026 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2019-15026（Memcached）",
   "NVD 说明（英文原文）：memcached 1.5.16, when UNIX sockets are used, has a stack-based buffer over-read in conn_to_str in memcached.c.",
   "请尽快将 Memcached 升级到不受 CVE-2019-15026 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2019-15026（Memcached）",
   "NVD 說明（英文原文）：memcached 1.5.16, when UNIX sockets are used, has a stack-based buffer over-read in conn_to_str in memcached.c.",
   "請儘快將 Memcached 升級到不受 CVE-2019-15026 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:memcached-noauth:CVE-2020-10931": {
  "de": [
   "Bekannte Schwachstelle: CVE-2020-10931 (Memcached)",
   "NVD-Beschreibung (englischer Originaltext): Memcached 1.6.x before 1.6.2 allows remote attackers to cause a denial of service (daemon crash) via a crafted binary protocol header to try_read_command_binary in memcached.c.",
   "Aktualisieren Sie Memcached so schnell wie möglich auf eine Version, die von CVE-2020-10931 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2020-10931 (Memcached)",
   "Memcached 1.6.x before 1.6.2 allows remote attackers to cause a denial of service (daemon crash) via a crafted binary protocol header to try_read_command_binary in memcached.c.",
   "Upgrade Memcached to a version not affected by CVE-2020-10931 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2020-10931 (Memcached)",
   "Descripción de NVD (texto original en inglés): Memcached 1.6.x before 1.6.2 allows remote attackers to cause a denial of service (daemon crash) via a crafted binary protocol header to try_read_command_binary in memcached.c.",
   "Actualice Memcached lo antes posible a una versión no afectada por CVE-2020-10931 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2020-10931 (Memcached)",
   "Description NVD (texte original en anglais) : Memcached 1.6.x before 1.6.2 allows remote attackers to cause a denial of service (daemon crash) via a crafted binary protocol header to try_read_command_binary in memcached.c.",
   "Mettez à niveau Memcached dès que possible vers une version non affectée par CVE-2020-10931 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2020-10931 (Memcached)",
   "Descrizione NVD (testo originale in inglese): Memcached 1.6.x before 1.6.2 allows remote attackers to cause a denial of service (daemon crash) via a crafted binary protocol header to try_read_command_binary in memcached.c.",
   "Aggiorna Memcached il prima possibile a una versione non interessata da CVE-2020-10931 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2020-10931 (Memcached)",
   "NVDの説明（英語原文）: Memcached 1.6.x before 1.6.2 allows remote attackers to cause a denial of service (daemon crash) via a crafted binary protocol header to try_read_command_binary in memcached.c.",
   "Memcached を CVE-2020-10931 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2020-10931 (Memcached)",
   "NVD 설명(영어 원문): Memcached 1.6.x before 1.6.2 allows remote attackers to cause a denial of service (daemon crash) via a crafted binary protocol header to try_read_command_binary in memcached.c.",
   "Memcached을(를) CVE-2020-10931의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2020-10931 (Memcached)",
   "Descrição do NVD (texto original em inglês): Memcached 1.6.x before 1.6.2 allows remote attackers to cause a denial of service (daemon crash) via a crafted binary protocol header to try_read_command_binary in memcached.c.",
   "Atualize o Memcached o quanto antes para uma versão não afetada por CVE-2020-10931 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2020-10931（Memcached）",
   "NVD 说明（英文原文）：Memcached 1.6.x before 1.6.2 allows remote attackers to cause a denial of service (daemon crash) via a crafted binary protocol header to try_read_command_binary in memcached.c.",
   "请尽快将 Memcached 升级到不受 CVE-2020-10931 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2020-10931（Memcached）",
   "NVD 說明（英文原文）：Memcached 1.6.x before 1.6.2 allows remote attackers to cause a denial of service (daemon crash) via a crafted binary protocol header to try_read_command_binary in memcached.c.",
   "請儘快將 Memcached 升級到不受 CVE-2020-10931 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:memcached-noauth:CVE-2020-22570": {
  "de": [
   "Bekannte Schwachstelle: CVE-2020-22570 (Memcached)",
   "NVD-Beschreibung (englischer Originaltext): Memcached 1.6.0 before 1.6.3 allows remote attackers to cause a denial of service (daemon crash) via a crafted meta command.",
   "Aktualisieren Sie Memcached so schnell wie möglich auf eine Version, die von CVE-2020-22570 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2020-22570 (Memcached)",
   "Memcached 1.6.0 before 1.6.3 allows remote attackers to cause a denial of service (daemon crash) via a crafted meta command.",
   "Upgrade Memcached to a version not affected by CVE-2020-22570 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2020-22570 (Memcached)",
   "Descripción de NVD (texto original en inglés): Memcached 1.6.0 before 1.6.3 allows remote attackers to cause a denial of service (daemon crash) via a crafted meta command.",
   "Actualice Memcached lo antes posible a una versión no afectada por CVE-2020-22570 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2020-22570 (Memcached)",
   "Description NVD (texte original en anglais) : Memcached 1.6.0 before 1.6.3 allows remote attackers to cause a denial of service (daemon crash) via a crafted meta command.",
   "Mettez à niveau Memcached dès que possible vers une version non affectée par CVE-2020-22570 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2020-22570 (Memcached)",
   "Descrizione NVD (testo originale in inglese): Memcached 1.6.0 before 1.6.3 allows remote attackers to cause a denial of service (daemon crash) via a crafted meta command.",
   "Aggiorna Memcached il prima possibile a una versione non interessata da CVE-2020-22570 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2020-22570 (Memcached)",
   "NVDの説明（英語原文）: Memcached 1.6.0 before 1.6.3 allows remote attackers to cause a denial of service (daemon crash) via a crafted meta command.",
   "Memcached を CVE-2020-22570 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2020-22570 (Memcached)",
   "NVD 설명(영어 원문): Memcached 1.6.0 before 1.6.3 allows remote attackers to cause a denial of service (daemon crash) via a crafted meta command.",
   "Memcached을(를) CVE-2020-22570의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2020-22570 (Memcached)",
   "Descrição do NVD (texto original em inglês): Memcached 1.6.0 before 1.6.3 allows remote attackers to cause a denial of service (daemon crash) via a crafted meta command.",
   "Atualize o Memcached o quanto antes para uma versão não afetada por CVE-2020-22570 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2020-22570（Memcached）",
   "NVD 说明（英文原文）：Memcached 1.6.0 before 1.6.3 allows remote attackers to cause a denial of service (daemon crash) via a crafted meta command.",
   "请尽快将 Memcached 升级到不受 CVE-2020-22570 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2020-22570（Memcached）",
   "NVD 說明（英文原文）：Memcached 1.6.0 before 1.6.3 allows remote attackers to cause a denial of service (daemon crash) via a crafted meta command.",
   "請儘快將 Memcached 升級到不受 CVE-2020-22570 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:memcached-noauth:CVE-2022-48571": {
  "de": [
   "Bekannte Schwachstelle: CVE-2022-48571 (Memcached)",
   "NVD-Beschreibung (englischer Originaltext): memcached 1.6.7 allows a Denial of Service via multi-packet uploads in UDP.",
   "Aktualisieren Sie Memcached so schnell wie möglich auf eine Version, die von CVE-2022-48571 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2022-48571 (Memcached)",
   "memcached 1.6.7 allows a Denial of Service via multi-packet uploads in UDP.",
   "Upgrade Memcached to a version not affected by CVE-2022-48571 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2022-48571 (Memcached)",
   "Descripción de NVD (texto original en inglés): memcached 1.6.7 allows a Denial of Service via multi-packet uploads in UDP.",
   "Actualice Memcached lo antes posible a una versión no afectada por CVE-2022-48571 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2022-48571 (Memcached)",
   "Description NVD (texte original en anglais) : memcached 1.6.7 allows a Denial of Service via multi-packet uploads in UDP.",
   "Mettez à niveau Memcached dès que possible vers une version non affectée par CVE-2022-48571 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2022-48571 (Memcached)",
   "Descrizione NVD (testo originale in inglese): memcached 1.6.7 allows a Denial of Service via multi-packet uploads in UDP.",
   "Aggiorna Memcached il prima possibile a una versione non interessata da CVE-2022-48571 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2022-48571 (Memcached)",
   "NVDの説明（英語原文）: memcached 1.6.7 allows a Denial of Service via multi-packet uploads in UDP.",
   "Memcached を CVE-2022-48571 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2022-48571 (Memcached)",
   "NVD 설명(영어 원문): memcached 1.6.7 allows a Denial of Service via multi-packet uploads in UDP.",
   "Memcached을(를) CVE-2022-48571의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2022-48571 (Memcached)",
   "Descrição do NVD (texto original em inglês): memcached 1.6.7 allows a Denial of Service via multi-packet uploads in UDP.",
   "Atualize o Memcached o quanto antes para uma versão não afetada por CVE-2022-48571 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2022-48571（Memcached）",
   "NVD 说明（英文原文）：memcached 1.6.7 allows a Denial of Service via multi-packet uploads in UDP.",
   "请尽快将 Memcached 升级到不受 CVE-2022-48571 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2022-48571（Memcached）",
   "NVD 說明（英文原文）：memcached 1.6.7 allows a Denial of Service via multi-packet uploads in UDP.",
   "請儘快將 Memcached 升級到不受 CVE-2022-48571 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:memcached-noauth:CVE-2023-46852": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-46852 (Memcached)",
   "NVD-Beschreibung (englischer Originaltext): In Memcached before 1.6.22, a buffer overflow exists when processing multiget requests in proxy mode, if there are many spaces after the \"get\" substring.",
   "Aktualisieren Sie Memcached so schnell wie möglich auf eine Version, die von CVE-2023-46852 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-46852 (Memcached)",
   "In Memcached before 1.6.22, a buffer overflow exists when processing multiget requests in proxy mode, if there are many spaces after the \"get\" substring.",
   "Upgrade Memcached to a version not affected by CVE-2023-46852 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-46852 (Memcached)",
   "Descripción de NVD (texto original en inglés): In Memcached before 1.6.22, a buffer overflow exists when processing multiget requests in proxy mode, if there are many spaces after the \"get\" substring.",
   "Actualice Memcached lo antes posible a una versión no afectada por CVE-2023-46852 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-46852 (Memcached)",
   "Description NVD (texte original en anglais) : In Memcached before 1.6.22, a buffer overflow exists when processing multiget requests in proxy mode, if there are many spaces after the \"get\" substring.",
   "Mettez à niveau Memcached dès que possible vers une version non affectée par CVE-2023-46852 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-46852 (Memcached)",
   "Descrizione NVD (testo originale in inglese): In Memcached before 1.6.22, a buffer overflow exists when processing multiget requests in proxy mode, if there are many spaces after the \"get\" substring.",
   "Aggiorna Memcached il prima possibile a una versione non interessata da CVE-2023-46852 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-46852 (Memcached)",
   "NVDの説明（英語原文）: In Memcached before 1.6.22, a buffer overflow exists when processing multiget requests in proxy mode, if there are many spaces after the \"get\" substring.",
   "Memcached を CVE-2023-46852 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-46852 (Memcached)",
   "NVD 설명(영어 원문): In Memcached before 1.6.22, a buffer overflow exists when processing multiget requests in proxy mode, if there are many spaces after the \"get\" substring.",
   "Memcached을(를) CVE-2023-46852의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-46852 (Memcached)",
   "Descrição do NVD (texto original em inglês): In Memcached before 1.6.22, a buffer overflow exists when processing multiget requests in proxy mode, if there are many spaces after the \"get\" substring.",
   "Atualize o Memcached o quanto antes para uma versão não afetada por CVE-2023-46852 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-46852（Memcached）",
   "NVD 说明（英文原文）：In Memcached before 1.6.22, a buffer overflow exists when processing multiget requests in proxy mode, if there are many spaces after the \"get\" substring.",
   "请尽快将 Memcached 升级到不受 CVE-2023-46852 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-46852（Memcached）",
   "NVD 說明（英文原文）：In Memcached before 1.6.22, a buffer overflow exists when processing multiget requests in proxy mode, if there are many spaces after the \"get\" substring.",
   "請儘快將 Memcached 升級到不受 CVE-2023-46852 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:memcached-noauth:CVE-2023-46853": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-46853 (Memcached)",
   "NVD-Beschreibung (englischer Originaltext): In Memcached before 1.6.22, an off-by-one error exists when processing proxy requests in proxy mode, if \\n is used instead of \\r\\n.",
   "Aktualisieren Sie Memcached so schnell wie möglich auf eine Version, die von CVE-2023-46853 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-46853 (Memcached)",
   "In Memcached before 1.6.22, an off-by-one error exists when processing proxy requests in proxy mode, if \\n is used instead of \\r\\n.",
   "Upgrade Memcached to a version not affected by CVE-2023-46853 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-46853 (Memcached)",
   "Descripción de NVD (texto original en inglés): In Memcached before 1.6.22, an off-by-one error exists when processing proxy requests in proxy mode, if \\n is used instead of \\r\\n.",
   "Actualice Memcached lo antes posible a una versión no afectada por CVE-2023-46853 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-46853 (Memcached)",
   "Description NVD (texte original en anglais) : In Memcached before 1.6.22, an off-by-one error exists when processing proxy requests in proxy mode, if \\n is used instead of \\r\\n.",
   "Mettez à niveau Memcached dès que possible vers une version non affectée par CVE-2023-46853 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-46853 (Memcached)",
   "Descrizione NVD (testo originale in inglese): In Memcached before 1.6.22, an off-by-one error exists when processing proxy requests in proxy mode, if \\n is used instead of \\r\\n.",
   "Aggiorna Memcached il prima possibile a una versione non interessata da CVE-2023-46853 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-46853 (Memcached)",
   "NVDの説明（英語原文）: In Memcached before 1.6.22, an off-by-one error exists when processing proxy requests in proxy mode, if \\n is used instead of \\r\\n.",
   "Memcached を CVE-2023-46853 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-46853 (Memcached)",
   "NVD 설명(영어 원문): In Memcached before 1.6.22, an off-by-one error exists when processing proxy requests in proxy mode, if \\n is used instead of \\r\\n.",
   "Memcached을(를) CVE-2023-46853의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-46853 (Memcached)",
   "Descrição do NVD (texto original em inglês): In Memcached before 1.6.22, an off-by-one error exists when processing proxy requests in proxy mode, if \\n is used instead of \\r\\n.",
   "Atualize o Memcached o quanto antes para uma versão não afetada por CVE-2023-46853 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-46853（Memcached）",
   "NVD 说明（英文原文）：In Memcached before 1.6.22, an off-by-one error exists when processing proxy requests in proxy mode, if \\n is used instead of \\r\\n.",
   "请尽快将 Memcached 升级到不受 CVE-2023-46853 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-46853（Memcached）",
   "NVD 說明（英文原文）：In Memcached before 1.6.22, an off-by-one error exists when processing proxy requests in proxy mode, if \\n is used instead of \\r\\n.",
   "請儘快將 Memcached 升級到不受 CVE-2023-46853 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:memcached-noauth:CVE-2026-47783": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-47783 (Memcached)",
   "NVD-Beschreibung (englischer Originaltext): In memcached before 1.6.42, username data for SASL password database authentication has a timing side channel because a loop exits as soon as a valid username is found by sasl_server_userdb_checkpass.",
   "Aktualisieren Sie Memcached so schnell wie möglich auf eine Version, die von CVE-2026-47783 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-47783 (Memcached)",
   "In memcached before 1.6.42, username data for SASL password database authentication has a timing side channel because a loop exits as soon as a valid username is found by sasl_server_userdb_checkpass.",
   "Upgrade Memcached to a version not affected by CVE-2026-47783 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-47783 (Memcached)",
   "Descripción de NVD (texto original en inglés): In memcached before 1.6.42, username data for SASL password database authentication has a timing side channel because a loop exits as soon as a valid username is found by sasl_server_userdb_checkpass.",
   "Actualice Memcached lo antes posible a una versión no afectada por CVE-2026-47783 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-47783 (Memcached)",
   "Description NVD (texte original en anglais) : In memcached before 1.6.42, username data for SASL password database authentication has a timing side channel because a loop exits as soon as a valid username is found by sasl_server_userdb_checkpass.",
   "Mettez à niveau Memcached dès que possible vers une version non affectée par CVE-2026-47783 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-47783 (Memcached)",
   "Descrizione NVD (testo originale in inglese): In memcached before 1.6.42, username data for SASL password database authentication has a timing side channel because a loop exits as soon as a valid username is found by sasl_server_userdb_checkpass.",
   "Aggiorna Memcached il prima possibile a una versione non interessata da CVE-2026-47783 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-47783 (Memcached)",
   "NVDの説明（英語原文）: In memcached before 1.6.42, username data for SASL password database authentication has a timing side channel because a loop exits as soon as a valid username is found by sasl_server_userdb_checkpass.",
   "Memcached を CVE-2026-47783 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-47783 (Memcached)",
   "NVD 설명(영어 원문): In memcached before 1.6.42, username data for SASL password database authentication has a timing side channel because a loop exits as soon as a valid username is found by sasl_server_userdb_checkpass.",
   "Memcached을(를) CVE-2026-47783의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-47783 (Memcached)",
   "Descrição do NVD (texto original em inglês): In memcached before 1.6.42, username data for SASL password database authentication has a timing side channel because a loop exits as soon as a valid username is found by sasl_server_userdb_checkpass.",
   "Atualize o Memcached o quanto antes para uma versão não afetada por CVE-2026-47783 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-47783（Memcached）",
   "NVD 说明（英文原文）：In memcached before 1.6.42, username data for SASL password database authentication has a timing side channel because a loop exits as soon as a valid username is found by sasl_server_userdb_checkpass.",
   "请尽快将 Memcached 升级到不受 CVE-2026-47783 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-47783（Memcached）",
   "NVD 說明（英文原文）：In memcached before 1.6.42, username data for SASL password database authentication has a timing side channel because a loop exits as soon as a valid username is found by sasl_server_userdb_checkpass.",
   "請儘快將 Memcached 升級到不受 CVE-2026-47783 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:memcached-noauth:CVE-2026-47784": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-47784 (Memcached)",
   "NVD-Beschreibung (englischer Originaltext): In memcached before 1.6.42, password data for SASL password database authentication has a timing side channel because memcmp is used by sasl_server_userdb_checkpass.",
   "Aktualisieren Sie Memcached so schnell wie möglich auf eine Version, die von CVE-2026-47784 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-47784 (Memcached)",
   "In memcached before 1.6.42, password data for SASL password database authentication has a timing side channel because memcmp is used by sasl_server_userdb_checkpass.",
   "Upgrade Memcached to a version not affected by CVE-2026-47784 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-47784 (Memcached)",
   "Descripción de NVD (texto original en inglés): In memcached before 1.6.42, password data for SASL password database authentication has a timing side channel because memcmp is used by sasl_server_userdb_checkpass.",
   "Actualice Memcached lo antes posible a una versión no afectada por CVE-2026-47784 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-47784 (Memcached)",
   "Description NVD (texte original en anglais) : In memcached before 1.6.42, password data for SASL password database authentication has a timing side channel because memcmp is used by sasl_server_userdb_checkpass.",
   "Mettez à niveau Memcached dès que possible vers une version non affectée par CVE-2026-47784 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-47784 (Memcached)",
   "Descrizione NVD (testo originale in inglese): In memcached before 1.6.42, password data for SASL password database authentication has a timing side channel because memcmp is used by sasl_server_userdb_checkpass.",
   "Aggiorna Memcached il prima possibile a una versione non interessata da CVE-2026-47784 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-47784 (Memcached)",
   "NVDの説明（英語原文）: In memcached before 1.6.42, password data for SASL password database authentication has a timing side channel because memcmp is used by sasl_server_userdb_checkpass.",
   "Memcached を CVE-2026-47784 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-47784 (Memcached)",
   "NVD 설명(영어 원문): In memcached before 1.6.42, password data for SASL password database authentication has a timing side channel because memcmp is used by sasl_server_userdb_checkpass.",
   "Memcached을(를) CVE-2026-47784의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-47784 (Memcached)",
   "Descrição do NVD (texto original em inglês): In memcached before 1.6.42, password data for SASL password database authentication has a timing side channel because memcmp is used by sasl_server_userdb_checkpass.",
   "Atualize o Memcached o quanto antes para uma versão não afetada por CVE-2026-47784 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-47784（Memcached）",
   "NVD 说明（英文原文）：In memcached before 1.6.42, password data for SASL password database authentication has a timing side channel because memcmp is used by sasl_server_userdb_checkpass.",
   "请尽快将 Memcached 升级到不受 CVE-2026-47784 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-47784（Memcached）",
   "NVD 說明（英文原文）：In memcached before 1.6.42, password data for SASL password database authentication has a timing side channel because memcmp is used by sasl_server_userdb_checkpass.",
   "請儘快將 Memcached 升級到不受 CVE-2026-47784 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2022-0736": {
  "de": [
   "Bekannte Schwachstelle: CVE-2022-0736 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): Insecure Temporary File in GitHub repository mlflow/mlflow prior to 1.23.1.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2022-0736 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2022-0736 (MLflow)",
   "Insecure Temporary File in GitHub repository mlflow/mlflow prior to 1.23.1.",
   "Upgrade MLflow to a version not affected by CVE-2022-0736 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2022-0736 (MLflow)",
   "Descripción de NVD (texto original en inglés): Insecure Temporary File in GitHub repository mlflow/mlflow prior to 1.23.1.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2022-0736 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2022-0736 (MLflow)",
   "Description NVD (texte original en anglais) : Insecure Temporary File in GitHub repository mlflow/mlflow prior to 1.23.1.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2022-0736 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2022-0736 (MLflow)",
   "Descrizione NVD (testo originale in inglese): Insecure Temporary File in GitHub repository mlflow/mlflow prior to 1.23.1.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2022-0736 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2022-0736 (MLflow)",
   "NVDの説明（英語原文）: Insecure Temporary File in GitHub repository mlflow/mlflow prior to 1.23.1.",
   "MLflow を CVE-2022-0736 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2022-0736 (MLflow)",
   "NVD 설명(영어 원문): Insecure Temporary File in GitHub repository mlflow/mlflow prior to 1.23.1.",
   "MLflow을(를) CVE-2022-0736의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2022-0736 (MLflow)",
   "Descrição do NVD (texto original em inglês): Insecure Temporary File in GitHub repository mlflow/mlflow prior to 1.23.1.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2022-0736 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2022-0736（MLflow）",
   "NVD 说明（英文原文）：Insecure Temporary File in GitHub repository mlflow/mlflow prior to 1.23.1.",
   "请尽快将 MLflow 升级到不受 CVE-2022-0736 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2022-0736（MLflow）",
   "NVD 說明（英文原文）：Insecure Temporary File in GitHub repository mlflow/mlflow prior to 1.23.1.",
   "請儘快將 MLflow 升級到不受 CVE-2022-0736 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2023-1177": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-1177 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.2.1.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2023-1177 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-1177 (MLflow)",
   "Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.2.1.",
   "Upgrade MLflow to a version not affected by CVE-2023-1177 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-1177 (MLflow)",
   "Descripción de NVD (texto original en inglés): Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.2.1.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2023-1177 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-1177 (MLflow)",
   "Description NVD (texte original en anglais) : Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.2.1.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2023-1177 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-1177 (MLflow)",
   "Descrizione NVD (testo originale in inglese): Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.2.1.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2023-1177 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-1177 (MLflow)",
   "NVDの説明（英語原文）: Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.2.1.",
   "MLflow を CVE-2023-1177 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-1177 (MLflow)",
   "NVD 설명(영어 원문): Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.2.1.",
   "MLflow을(를) CVE-2023-1177의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-1177 (MLflow)",
   "Descrição do NVD (texto original em inglês): Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.2.1.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2023-1177 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-1177（MLflow）",
   "NVD 说明（英文原文）：Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.2.1.",
   "请尽快将 MLflow 升级到不受 CVE-2023-1177 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-1177（MLflow）",
   "NVD 說明（英文原文）：Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.2.1.",
   "請儘快將 MLflow 升級到不受 CVE-2023-1177 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2023-2356": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-2356 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): Relative Path Traversal in GitHub repository mlflow/mlflow prior to 2.3.1.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2023-2356 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-2356 (MLflow)",
   "Relative Path Traversal in GitHub repository mlflow/mlflow prior to 2.3.1.",
   "Upgrade MLflow to a version not affected by CVE-2023-2356 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-2356 (MLflow)",
   "Descripción de NVD (texto original en inglés): Relative Path Traversal in GitHub repository mlflow/mlflow prior to 2.3.1.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2023-2356 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-2356 (MLflow)",
   "Description NVD (texte original en anglais) : Relative Path Traversal in GitHub repository mlflow/mlflow prior to 2.3.1.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2023-2356 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-2356 (MLflow)",
   "Descrizione NVD (testo originale in inglese): Relative Path Traversal in GitHub repository mlflow/mlflow prior to 2.3.1.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2023-2356 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-2356 (MLflow)",
   "NVDの説明（英語原文）: Relative Path Traversal in GitHub repository mlflow/mlflow prior to 2.3.1.",
   "MLflow を CVE-2023-2356 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-2356 (MLflow)",
   "NVD 설명(영어 원문): Relative Path Traversal in GitHub repository mlflow/mlflow prior to 2.3.1.",
   "MLflow을(를) CVE-2023-2356의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-2356 (MLflow)",
   "Descrição do NVD (texto original em inglês): Relative Path Traversal in GitHub repository mlflow/mlflow prior to 2.3.1.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2023-2356 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-2356（MLflow）",
   "NVD 说明（英文原文）：Relative Path Traversal in GitHub repository mlflow/mlflow prior to 2.3.1.",
   "请尽快将 MLflow 升级到不受 CVE-2023-2356 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-2356（MLflow）",
   "NVD 說明（英文原文）：Relative Path Traversal in GitHub repository mlflow/mlflow prior to 2.3.1.",
   "請儘快將 MLflow 升級到不受 CVE-2023-2356 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2023-2780": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-2780 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.3.1.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2023-2780 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-2780 (MLflow)",
   "Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.3.1.",
   "Upgrade MLflow to a version not affected by CVE-2023-2780 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-2780 (MLflow)",
   "Descripción de NVD (texto original en inglés): Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.3.1.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2023-2780 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-2780 (MLflow)",
   "Description NVD (texte original en anglais) : Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.3.1.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2023-2780 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-2780 (MLflow)",
   "Descrizione NVD (testo originale in inglese): Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.3.1.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2023-2780 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-2780 (MLflow)",
   "NVDの説明（英語原文）: Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.3.1.",
   "MLflow を CVE-2023-2780 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-2780 (MLflow)",
   "NVD 설명(영어 원문): Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.3.1.",
   "MLflow을(를) CVE-2023-2780의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-2780 (MLflow)",
   "Descrição do NVD (texto original em inglês): Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.3.1.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2023-2780 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-2780（MLflow）",
   "NVD 说明（英文原文）：Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.3.1.",
   "请尽快将 MLflow 升级到不受 CVE-2023-2780 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-2780（MLflow）",
   "NVD 說明（英文原文）：Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.3.1.",
   "請儘快將 MLflow 升級到不受 CVE-2023-2780 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2023-30172": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-30172 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): A directory traversal vulnerability in the /get-artifact API method of the mlflow platform up to v2.0.1 allows attackers to read arbitrary files on the server via the path parameter.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2023-30172 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-30172 (MLflow)",
   "A directory traversal vulnerability in the /get-artifact API method of the mlflow platform up to v2.0.1 allows attackers to read arbitrary files on the server via the path parameter.",
   "Upgrade MLflow to a version not affected by CVE-2023-30172 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-30172 (MLflow)",
   "Descripción de NVD (texto original en inglés): A directory traversal vulnerability in the /get-artifact API method of the mlflow platform up to v2.0.1 allows attackers to read arbitrary files on the server via the path parameter.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2023-30172 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-30172 (MLflow)",
   "Description NVD (texte original en anglais) : A directory traversal vulnerability in the /get-artifact API method of the mlflow platform up to v2.0.1 allows attackers to read arbitrary files on the server via the path parameter.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2023-30172 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-30172 (MLflow)",
   "Descrizione NVD (testo originale in inglese): A directory traversal vulnerability in the /get-artifact API method of the mlflow platform up to v2.0.1 allows attackers to read arbitrary files on the server via the path parameter.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2023-30172 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-30172 (MLflow)",
   "NVDの説明（英語原文）: A directory traversal vulnerability in the /get-artifact API method of the mlflow platform up to v2.0.1 allows attackers to read arbitrary files on the server via the path parameter.",
   "MLflow を CVE-2023-30172 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-30172 (MLflow)",
   "NVD 설명(영어 원문): A directory traversal vulnerability in the /get-artifact API method of the mlflow platform up to v2.0.1 allows attackers to read arbitrary files on the server via the path parameter.",
   "MLflow을(를) CVE-2023-30172의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-30172 (MLflow)",
   "Descrição do NVD (texto original em inglês): A directory traversal vulnerability in the /get-artifact API method of the mlflow platform up to v2.0.1 allows attackers to read arbitrary files on the server via the path parameter.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2023-30172 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-30172（MLflow）",
   "NVD 说明（英文原文）：A directory traversal vulnerability in the /get-artifact API method of the mlflow platform up to v2.0.1 allows attackers to read arbitrary files on the server via the path parameter.",
   "请尽快将 MLflow 升级到不受 CVE-2023-30172 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-30172（MLflow）",
   "NVD 說明（英文原文）：A directory traversal vulnerability in the /get-artifact API method of the mlflow platform up to v2.0.1 allows attackers to read arbitrary files on the server via the path parameter.",
   "請儘快將 MLflow 升級到不受 CVE-2023-30172 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2023-3765": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-3765 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): Absolute Path Traversal in GitHub repository mlflow/mlflow prior to 2.5.0.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2023-3765 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-3765 (MLflow)",
   "Absolute Path Traversal in GitHub repository mlflow/mlflow prior to 2.5.0.",
   "Upgrade MLflow to a version not affected by CVE-2023-3765 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-3765 (MLflow)",
   "Descripción de NVD (texto original en inglés): Absolute Path Traversal in GitHub repository mlflow/mlflow prior to 2.5.0.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2023-3765 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-3765 (MLflow)",
   "Description NVD (texte original en anglais) : Absolute Path Traversal in GitHub repository mlflow/mlflow prior to 2.5.0.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2023-3765 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-3765 (MLflow)",
   "Descrizione NVD (testo originale in inglese): Absolute Path Traversal in GitHub repository mlflow/mlflow prior to 2.5.0.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2023-3765 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-3765 (MLflow)",
   "NVDの説明（英語原文）: Absolute Path Traversal in GitHub repository mlflow/mlflow prior to 2.5.0.",
   "MLflow を CVE-2023-3765 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-3765 (MLflow)",
   "NVD 설명(영어 원문): Absolute Path Traversal in GitHub repository mlflow/mlflow prior to 2.5.0.",
   "MLflow을(를) CVE-2023-3765의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-3765 (MLflow)",
   "Descrição do NVD (texto original em inglês): Absolute Path Traversal in GitHub repository mlflow/mlflow prior to 2.5.0.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2023-3765 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-3765（MLflow）",
   "NVD 说明（英文原文）：Absolute Path Traversal in GitHub repository mlflow/mlflow prior to 2.5.0.",
   "请尽快将 MLflow 升级到不受 CVE-2023-3765 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-3765（MLflow）",
   "NVD 說明（英文原文）：Absolute Path Traversal in GitHub repository mlflow/mlflow prior to 2.5.0.",
   "請儘快將 MLflow 升級到不受 CVE-2023-3765 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2023-4033": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-4033 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): OS Command Injection in GitHub repository mlflow/mlflow prior to 2.6.0.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2023-4033 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-4033 (MLflow)",
   "OS Command Injection in GitHub repository mlflow/mlflow prior to 2.6.0.",
   "Upgrade MLflow to a version not affected by CVE-2023-4033 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-4033 (MLflow)",
   "Descripción de NVD (texto original en inglés): OS Command Injection in GitHub repository mlflow/mlflow prior to 2.6.0.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2023-4033 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-4033 (MLflow)",
   "Description NVD (texte original en anglais) : OS Command Injection in GitHub repository mlflow/mlflow prior to 2.6.0.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2023-4033 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-4033 (MLflow)",
   "Descrizione NVD (testo originale in inglese): OS Command Injection in GitHub repository mlflow/mlflow prior to 2.6.0.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2023-4033 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-4033 (MLflow)",
   "NVDの説明（英語原文）: OS Command Injection in GitHub repository mlflow/mlflow prior to 2.6.0.",
   "MLflow を CVE-2023-4033 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-4033 (MLflow)",
   "NVD 설명(영어 원문): OS Command Injection in GitHub repository mlflow/mlflow prior to 2.6.0.",
   "MLflow을(를) CVE-2023-4033의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-4033 (MLflow)",
   "Descrição do NVD (texto original em inglês): OS Command Injection in GitHub repository mlflow/mlflow prior to 2.6.0.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2023-4033 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-4033（MLflow）",
   "NVD 说明（英文原文）：OS Command Injection in GitHub repository mlflow/mlflow prior to 2.6.0.",
   "请尽快将 MLflow 升级到不受 CVE-2023-4033 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-4033（MLflow）",
   "NVD 說明（英文原文）：OS Command Injection in GitHub repository mlflow/mlflow prior to 2.6.0.",
   "請儘快將 MLflow 升級到不受 CVE-2023-4033 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2023-43472": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-43472 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): An issue in MLFlow versions 2.8.1 and before allows a remote attacker to obtain sensitive information via a crafted request to REST API.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2023-43472 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-43472 (MLflow)",
   "An issue in MLFlow versions 2.8.1 and before allows a remote attacker to obtain sensitive information via a crafted request to REST API.",
   "Upgrade MLflow to a version not affected by CVE-2023-43472 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-43472 (MLflow)",
   "Descripción de NVD (texto original en inglés): An issue in MLFlow versions 2.8.1 and before allows a remote attacker to obtain sensitive information via a crafted request to REST API.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2023-43472 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-43472 (MLflow)",
   "Description NVD (texte original en anglais) : An issue in MLFlow versions 2.8.1 and before allows a remote attacker to obtain sensitive information via a crafted request to REST API.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2023-43472 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-43472 (MLflow)",
   "Descrizione NVD (testo originale in inglese): An issue in MLFlow versions 2.8.1 and before allows a remote attacker to obtain sensitive information via a crafted request to REST API.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2023-43472 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-43472 (MLflow)",
   "NVDの説明（英語原文）: An issue in MLFlow versions 2.8.1 and before allows a remote attacker to obtain sensitive information via a crafted request to REST API.",
   "MLflow を CVE-2023-43472 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-43472 (MLflow)",
   "NVD 설명(영어 원문): An issue in MLFlow versions 2.8.1 and before allows a remote attacker to obtain sensitive information via a crafted request to REST API.",
   "MLflow을(를) CVE-2023-43472의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-43472 (MLflow)",
   "Descrição do NVD (texto original em inglês): An issue in MLFlow versions 2.8.1 and before allows a remote attacker to obtain sensitive information via a crafted request to REST API.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2023-43472 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-43472（MLflow）",
   "NVD 说明（英文原文）：An issue in MLFlow versions 2.8.1 and before allows a remote attacker to obtain sensitive information via a crafted request to REST API.",
   "请尽快将 MLflow 升级到不受 CVE-2023-43472 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-43472（MLflow）",
   "NVD 說明（英文原文）：An issue in MLFlow versions 2.8.1 and before allows a remote attacker to obtain sensitive information via a crafted request to REST API.",
   "請儘快將 MLflow 升級到不受 CVE-2023-43472 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2023-6015": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-6015 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): MLflow allowed arbitrary files to be PUT onto the server.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2023-6015 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-6015 (MLflow)",
   "MLflow allowed arbitrary files to be PUT onto the server.",
   "Upgrade MLflow to a version not affected by CVE-2023-6015 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-6015 (MLflow)",
   "Descripción de NVD (texto original en inglés): MLflow allowed arbitrary files to be PUT onto the server.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2023-6015 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-6015 (MLflow)",
   "Description NVD (texte original en anglais) : MLflow allowed arbitrary files to be PUT onto the server.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2023-6015 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-6015 (MLflow)",
   "Descrizione NVD (testo originale in inglese): MLflow allowed arbitrary files to be PUT onto the server.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2023-6015 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-6015 (MLflow)",
   "NVDの説明（英語原文）: MLflow allowed arbitrary files to be PUT onto the server.",
   "MLflow を CVE-2023-6015 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-6015 (MLflow)",
   "NVD 설명(영어 원문): MLflow allowed arbitrary files to be PUT onto the server.",
   "MLflow을(를) CVE-2023-6015의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-6015 (MLflow)",
   "Descrição do NVD (texto original em inglês): MLflow allowed arbitrary files to be PUT onto the server.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2023-6015 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-6015（MLflow）",
   "NVD 说明（英文原文）：MLflow allowed arbitrary files to be PUT onto the server.",
   "请尽快将 MLflow 升级到不受 CVE-2023-6015 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-6015（MLflow）",
   "NVD 說明（英文原文）：MLflow allowed arbitrary files to be PUT onto the server.",
   "請儘快將 MLflow 升級到不受 CVE-2023-6015 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2023-6018": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-6018 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): An attacker can overwrite any file on the server hosting MLflow without any authentication.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2023-6018 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-6018 (MLflow)",
   "An attacker can overwrite any file on the server hosting MLflow without any authentication.",
   "Upgrade MLflow to a version not affected by CVE-2023-6018 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-6018 (MLflow)",
   "Descripción de NVD (texto original en inglés): An attacker can overwrite any file on the server hosting MLflow without any authentication.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2023-6018 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-6018 (MLflow)",
   "Description NVD (texte original en anglais) : An attacker can overwrite any file on the server hosting MLflow without any authentication.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2023-6018 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-6018 (MLflow)",
   "Descrizione NVD (testo originale in inglese): An attacker can overwrite any file on the server hosting MLflow without any authentication.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2023-6018 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-6018 (MLflow)",
   "NVDの説明（英語原文）: An attacker can overwrite any file on the server hosting MLflow without any authentication.",
   "MLflow を CVE-2023-6018 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-6018 (MLflow)",
   "NVD 설명(영어 원문): An attacker can overwrite any file on the server hosting MLflow without any authentication.",
   "MLflow을(를) CVE-2023-6018의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-6018 (MLflow)",
   "Descrição do NVD (texto original em inglês): An attacker can overwrite any file on the server hosting MLflow without any authentication.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2023-6018 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-6018（MLflow）",
   "NVD 说明（英文原文）：An attacker can overwrite any file on the server hosting MLflow without any authentication.",
   "请尽快将 MLflow 升级到不受 CVE-2023-6018 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-6018（MLflow）",
   "NVD 說明（英文原文）：An attacker can overwrite any file on the server hosting MLflow without any authentication.",
   "請儘快將 MLflow 升級到不受 CVE-2023-6018 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2023-6709": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-6709 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): Improper Neutralization of Special Elements Used in a Template Engine in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2023-6709 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-6709 (MLflow)",
   "Improper Neutralization of Special Elements Used in a Template Engine in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "Upgrade MLflow to a version not affected by CVE-2023-6709 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-6709 (MLflow)",
   "Descripción de NVD (texto original en inglés): Improper Neutralization of Special Elements Used in a Template Engine in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2023-6709 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-6709 (MLflow)",
   "Description NVD (texte original en anglais) : Improper Neutralization of Special Elements Used in a Template Engine in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2023-6709 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-6709 (MLflow)",
   "Descrizione NVD (testo originale in inglese): Improper Neutralization of Special Elements Used in a Template Engine in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2023-6709 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-6709 (MLflow)",
   "NVDの説明（英語原文）: Improper Neutralization of Special Elements Used in a Template Engine in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "MLflow を CVE-2023-6709 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-6709 (MLflow)",
   "NVD 설명(영어 원문): Improper Neutralization of Special Elements Used in a Template Engine in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "MLflow을(를) CVE-2023-6709의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-6709 (MLflow)",
   "Descrição do NVD (texto original em inglês): Improper Neutralization of Special Elements Used in a Template Engine in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2023-6709 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-6709（MLflow）",
   "NVD 说明（英文原文）：Improper Neutralization of Special Elements Used in a Template Engine in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "请尽快将 MLflow 升级到不受 CVE-2023-6709 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-6709（MLflow）",
   "NVD 說明（英文原文）：Improper Neutralization of Special Elements Used in a Template Engine in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "請儘快將 MLflow 升級到不受 CVE-2023-6709 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2023-6753": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-6753 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): Path Traversal in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2023-6753 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-6753 (MLflow)",
   "Path Traversal in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "Upgrade MLflow to a version not affected by CVE-2023-6753 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-6753 (MLflow)",
   "Descripción de NVD (texto original en inglés): Path Traversal in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2023-6753 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-6753 (MLflow)",
   "Description NVD (texte original en anglais) : Path Traversal in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2023-6753 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-6753 (MLflow)",
   "Descrizione NVD (testo originale in inglese): Path Traversal in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2023-6753 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-6753 (MLflow)",
   "NVDの説明（英語原文）: Path Traversal in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "MLflow を CVE-2023-6753 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-6753 (MLflow)",
   "NVD 설명(영어 원문): Path Traversal in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "MLflow을(를) CVE-2023-6753의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-6753 (MLflow)",
   "Descrição do NVD (texto original em inglês): Path Traversal in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2023-6753 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-6753（MLflow）",
   "NVD 说明（英文原文）：Path Traversal in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "请尽快将 MLflow 升级到不受 CVE-2023-6753 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-6753（MLflow）",
   "NVD 說明（英文原文）：Path Traversal in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "請儘快將 MLflow 升級到不受 CVE-2023-6753 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2023-6831": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-6831 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2023-6831 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-6831 (MLflow)",
   "Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "Upgrade MLflow to a version not affected by CVE-2023-6831 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-6831 (MLflow)",
   "Descripción de NVD (texto original en inglés): Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2023-6831 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-6831 (MLflow)",
   "Description NVD (texte original en anglais) : Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2023-6831 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-6831 (MLflow)",
   "Descrizione NVD (testo originale in inglese): Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2023-6831 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-6831 (MLflow)",
   "NVDの説明（英語原文）: Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "MLflow を CVE-2023-6831 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-6831 (MLflow)",
   "NVD 설명(영어 원문): Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "MLflow을(를) CVE-2023-6831의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-6831 (MLflow)",
   "Descrição do NVD (texto original em inglês): Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2023-6831 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-6831（MLflow）",
   "NVD 说明（英文原文）：Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "请尽快将 MLflow 升级到不受 CVE-2023-6831 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-6831（MLflow）",
   "NVD 說明（英文原文）：Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "請儘快將 MLflow 升級到不受 CVE-2023-6831 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2023-6909": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-6909 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2023-6909 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-6909 (MLflow)",
   "Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "Upgrade MLflow to a version not affected by CVE-2023-6909 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-6909 (MLflow)",
   "Descripción de NVD (texto original en inglés): Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2023-6909 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-6909 (MLflow)",
   "Description NVD (texte original en anglais) : Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2023-6909 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-6909 (MLflow)",
   "Descrizione NVD (testo originale in inglese): Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2023-6909 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-6909 (MLflow)",
   "NVDの説明（英語原文）: Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "MLflow を CVE-2023-6909 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-6909 (MLflow)",
   "NVD 설명(영어 원문): Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "MLflow을(를) CVE-2023-6909의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-6909 (MLflow)",
   "Descrição do NVD (texto original em inglês): Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2023-6909 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-6909（MLflow）",
   "NVD 说明（英文原文）：Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "请尽快将 MLflow 升级到不受 CVE-2023-6909 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-6909（MLflow）",
   "NVD 說明（英文原文）：Path Traversal: '\\..\\filename' in GitHub repository mlflow/mlflow prior to 2.9.2.",
   "請儘快將 MLflow 升級到不受 CVE-2023-6909 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2023-6940": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-6940 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): with only one user interaction(download a malicious config), attackers can gain full command execution on the victim system.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2023-6940 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-6940 (MLflow)",
   "with only one user interaction(download a malicious config), attackers can gain full command execution on the victim system.",
   "Upgrade MLflow to a version not affected by CVE-2023-6940 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-6940 (MLflow)",
   "Descripción de NVD (texto original en inglés): with only one user interaction(download a malicious config), attackers can gain full command execution on the victim system.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2023-6940 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-6940 (MLflow)",
   "Description NVD (texte original en anglais) : with only one user interaction(download a malicious config), attackers can gain full command execution on the victim system.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2023-6940 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-6940 (MLflow)",
   "Descrizione NVD (testo originale in inglese): with only one user interaction(download a malicious config), attackers can gain full command execution on the victim system.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2023-6940 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-6940 (MLflow)",
   "NVDの説明（英語原文）: with only one user interaction(download a malicious config), attackers can gain full command execution on the victim system.",
   "MLflow を CVE-2023-6940 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-6940 (MLflow)",
   "NVD 설명(영어 원문): with only one user interaction(download a malicious config), attackers can gain full command execution on the victim system.",
   "MLflow을(를) CVE-2023-6940의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-6940 (MLflow)",
   "Descrição do NVD (texto original em inglês): with only one user interaction(download a malicious config), attackers can gain full command execution on the victim system.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2023-6940 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-6940（MLflow）",
   "NVD 说明（英文原文）：with only one user interaction(download a malicious config), attackers can gain full command execution on the victim system.",
   "请尽快将 MLflow 升级到不受 CVE-2023-6940 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-6940（MLflow）",
   "NVD 說明（英文原文）：with only one user interaction(download a malicious config), attackers can gain full command execution on the victim system.",
   "請儘快將 MLflow 升級到不受 CVE-2023-6940 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2023-6974": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-6974 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): A malicious user could use this issue to access internal HTTP(s) servers and in the worst case (ie: aws instance) it could be abuse to get a remote code execution on the victim machine.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2023-6974 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-6974 (MLflow)",
   "A malicious user could use this issue to access internal HTTP(s) servers and in the worst case (ie: aws instance) it could be abuse to get a remote code execution on the victim machine.",
   "Upgrade MLflow to a version not affected by CVE-2023-6974 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-6974 (MLflow)",
   "Descripción de NVD (texto original en inglés): A malicious user could use this issue to access internal HTTP(s) servers and in the worst case (ie: aws instance) it could be abuse to get a remote code execution on the victim machine.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2023-6974 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-6974 (MLflow)",
   "Description NVD (texte original en anglais) : A malicious user could use this issue to access internal HTTP(s) servers and in the worst case (ie: aws instance) it could be abuse to get a remote code execution on the victim machine.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2023-6974 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-6974 (MLflow)",
   "Descrizione NVD (testo originale in inglese): A malicious user could use this issue to access internal HTTP(s) servers and in the worst case (ie: aws instance) it could be abuse to get a remote code execution on the victim machine.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2023-6974 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-6974 (MLflow)",
   "NVDの説明（英語原文）: A malicious user could use this issue to access internal HTTP(s) servers and in the worst case (ie: aws instance) it could be abuse to get a remote code execution on the victim machine.",
   "MLflow を CVE-2023-6974 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-6974 (MLflow)",
   "NVD 설명(영어 원문): A malicious user could use this issue to access internal HTTP(s) servers and in the worst case (ie: aws instance) it could be abuse to get a remote code execution on the victim machine.",
   "MLflow을(를) CVE-2023-6974의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-6974 (MLflow)",
   "Descrição do NVD (texto original em inglês): A malicious user could use this issue to access internal HTTP(s) servers and in the worst case (ie: aws instance) it could be abuse to get a remote code execution on the victim machine.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2023-6974 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-6974（MLflow）",
   "NVD 说明（英文原文）：A malicious user could use this issue to access internal HTTP(s) servers and in the worst case (ie: aws instance) it could be abuse to get a remote code execution on the victim machine.",
   "请尽快将 MLflow 升级到不受 CVE-2023-6974 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-6974（MLflow）",
   "NVD 說明（英文原文）：A malicious user could use this issue to access internal HTTP(s) servers and in the worst case (ie: aws instance) it could be abuse to get a remote code execution on the victim machine.",
   "請儘快將 MLflow 升級到不受 CVE-2023-6974 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2023-6975": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-6975 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): A malicious user could use this issue to get command execution on the vulnerable machine and get access to data & models information.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2023-6975 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-6975 (MLflow)",
   "A malicious user could use this issue to get command execution on the vulnerable machine and get access to data & models information.",
   "Upgrade MLflow to a version not affected by CVE-2023-6975 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-6975 (MLflow)",
   "Descripción de NVD (texto original en inglés): A malicious user could use this issue to get command execution on the vulnerable machine and get access to data & models information.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2023-6975 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-6975 (MLflow)",
   "Description NVD (texte original en anglais) : A malicious user could use this issue to get command execution on the vulnerable machine and get access to data & models information.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2023-6975 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-6975 (MLflow)",
   "Descrizione NVD (testo originale in inglese): A malicious user could use this issue to get command execution on the vulnerable machine and get access to data & models information.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2023-6975 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-6975 (MLflow)",
   "NVDの説明（英語原文）: A malicious user could use this issue to get command execution on the vulnerable machine and get access to data & models information.",
   "MLflow を CVE-2023-6975 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-6975 (MLflow)",
   "NVD 설명(영어 원문): A malicious user could use this issue to get command execution on the vulnerable machine and get access to data & models information.",
   "MLflow을(를) CVE-2023-6975의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-6975 (MLflow)",
   "Descrição do NVD (texto original em inglês): A malicious user could use this issue to get command execution on the vulnerable machine and get access to data & models information.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2023-6975 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-6975（MLflow）",
   "NVD 说明（英文原文）：A malicious user could use this issue to get command execution on the vulnerable machine and get access to data & models information.",
   "请尽快将 MLflow 升级到不受 CVE-2023-6975 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-6975（MLflow）",
   "NVD 說明（英文原文）：A malicious user could use this issue to get command execution on the vulnerable machine and get access to data & models information.",
   "請儘快將 MLflow 升級到不受 CVE-2023-6975 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2023-6976": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-6976 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): This vulnerability is capable of writing arbitrary files into arbitrary locations on the remote filesystem in the context of the server process.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2023-6976 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-6976 (MLflow)",
   "This vulnerability is capable of writing arbitrary files into arbitrary locations on the remote filesystem in the context of the server process.",
   "Upgrade MLflow to a version not affected by CVE-2023-6976 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-6976 (MLflow)",
   "Descripción de NVD (texto original en inglés): This vulnerability is capable of writing arbitrary files into arbitrary locations on the remote filesystem in the context of the server process.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2023-6976 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-6976 (MLflow)",
   "Description NVD (texte original en anglais) : This vulnerability is capable of writing arbitrary files into arbitrary locations on the remote filesystem in the context of the server process.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2023-6976 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-6976 (MLflow)",
   "Descrizione NVD (testo originale in inglese): This vulnerability is capable of writing arbitrary files into arbitrary locations on the remote filesystem in the context of the server process.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2023-6976 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-6976 (MLflow)",
   "NVDの説明（英語原文）: This vulnerability is capable of writing arbitrary files into arbitrary locations on the remote filesystem in the context of the server process.",
   "MLflow を CVE-2023-6976 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-6976 (MLflow)",
   "NVD 설명(영어 원문): This vulnerability is capable of writing arbitrary files into arbitrary locations on the remote filesystem in the context of the server process.",
   "MLflow을(를) CVE-2023-6976의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-6976 (MLflow)",
   "Descrição do NVD (texto original em inglês): This vulnerability is capable of writing arbitrary files into arbitrary locations on the remote filesystem in the context of the server process.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2023-6976 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-6976（MLflow）",
   "NVD 说明（英文原文）：This vulnerability is capable of writing arbitrary files into arbitrary locations on the remote filesystem in the context of the server process.",
   "请尽快将 MLflow 升级到不受 CVE-2023-6976 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-6976（MLflow）",
   "NVD 說明（英文原文）：This vulnerability is capable of writing arbitrary files into arbitrary locations on the remote filesystem in the context of the server process.",
   "請儘快將 MLflow 升級到不受 CVE-2023-6976 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2023-6977": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-6977 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): This vulnerability enables malicious users to read sensitive files on the server.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2023-6977 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-6977 (MLflow)",
   "This vulnerability enables malicious users to read sensitive files on the server.",
   "Upgrade MLflow to a version not affected by CVE-2023-6977 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-6977 (MLflow)",
   "Descripción de NVD (texto original en inglés): This vulnerability enables malicious users to read sensitive files on the server.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2023-6977 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-6977 (MLflow)",
   "Description NVD (texte original en anglais) : This vulnerability enables malicious users to read sensitive files on the server.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2023-6977 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-6977 (MLflow)",
   "Descrizione NVD (testo originale in inglese): This vulnerability enables malicious users to read sensitive files on the server.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2023-6977 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-6977 (MLflow)",
   "NVDの説明（英語原文）: This vulnerability enables malicious users to read sensitive files on the server.",
   "MLflow を CVE-2023-6977 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-6977 (MLflow)",
   "NVD 설명(영어 원문): This vulnerability enables malicious users to read sensitive files on the server.",
   "MLflow을(를) CVE-2023-6977의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-6977 (MLflow)",
   "Descrição do NVD (texto original em inglês): This vulnerability enables malicious users to read sensitive files on the server.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2023-6977 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-6977（MLflow）",
   "NVD 说明（英文原文）：This vulnerability enables malicious users to read sensitive files on the server.",
   "请尽快将 MLflow 升级到不受 CVE-2023-6977 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-6977（MLflow）",
   "NVD 說明（英文原文）：This vulnerability enables malicious users to read sensitive files on the server.",
   "請儘快將 MLflow 升級到不受 CVE-2023-6977 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2024-0520": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-0520 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): A vulnerability in mlflow/mlflow version 8.2.1 allows for remote code execution due to improper neutralization of special elements used in an OS command ('Command Injection') within the `mlflow.data.http_dataset_source.py` module. Specifically, when loading a dataset from a source URL with an HTTP scheme, the filename extracted from the `Content-Disposition` header or the URL path is used to generate the final file path without proper sanitization. This flaw enables an attacker to control the fi",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2024-0520 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-0520 (MLflow)",
   "A vulnerability in mlflow/mlflow version 8.2.1 allows for remote code execution due to improper neutralization of special elements used in an OS command ('Command Injection') within the `mlflow.data.http_dataset_source.py` module. Specifically, when loading a dataset from a source URL with an HTTP scheme, the filename extracted from the `Content-Disposition` header or the URL path is used to generate the final file path without proper sanitization. This flaw enables an attacker to control the fi",
   "Upgrade MLflow to a version not affected by CVE-2024-0520 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-0520 (MLflow)",
   "Descripción de NVD (texto original en inglés): A vulnerability in mlflow/mlflow version 8.2.1 allows for remote code execution due to improper neutralization of special elements used in an OS command ('Command Injection') within the `mlflow.data.http_dataset_source.py` module. Specifically, when loading a dataset from a source URL with an HTTP scheme, the filename extracted from the `Content-Disposition` header or the URL path is used to generate the final file path without proper sanitization. This flaw enables an attacker to control the fi",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2024-0520 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-0520 (MLflow)",
   "Description NVD (texte original en anglais) : A vulnerability in mlflow/mlflow version 8.2.1 allows for remote code execution due to improper neutralization of special elements used in an OS command ('Command Injection') within the `mlflow.data.http_dataset_source.py` module. Specifically, when loading a dataset from a source URL with an HTTP scheme, the filename extracted from the `Content-Disposition` header or the URL path is used to generate the final file path without proper sanitization. This flaw enables an attacker to control the fi",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2024-0520 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-0520 (MLflow)",
   "Descrizione NVD (testo originale in inglese): A vulnerability in mlflow/mlflow version 8.2.1 allows for remote code execution due to improper neutralization of special elements used in an OS command ('Command Injection') within the `mlflow.data.http_dataset_source.py` module. Specifically, when loading a dataset from a source URL with an HTTP scheme, the filename extracted from the `Content-Disposition` header or the URL path is used to generate the final file path without proper sanitization. This flaw enables an attacker to control the fi",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2024-0520 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-0520 (MLflow)",
   "NVDの説明（英語原文）: A vulnerability in mlflow/mlflow version 8.2.1 allows for remote code execution due to improper neutralization of special elements used in an OS command ('Command Injection') within the `mlflow.data.http_dataset_source.py` module. Specifically, when loading a dataset from a source URL with an HTTP scheme, the filename extracted from the `Content-Disposition` header or the URL path is used to generate the final file path without proper sanitization. This flaw enables an attacker to control the fi",
   "MLflow を CVE-2024-0520 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-0520 (MLflow)",
   "NVD 설명(영어 원문): A vulnerability in mlflow/mlflow version 8.2.1 allows for remote code execution due to improper neutralization of special elements used in an OS command ('Command Injection') within the `mlflow.data.http_dataset_source.py` module. Specifically, when loading a dataset from a source URL with an HTTP scheme, the filename extracted from the `Content-Disposition` header or the URL path is used to generate the final file path without proper sanitization. This flaw enables an attacker to control the fi",
   "MLflow을(를) CVE-2024-0520의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-0520 (MLflow)",
   "Descrição do NVD (texto original em inglês): A vulnerability in mlflow/mlflow version 8.2.1 allows for remote code execution due to improper neutralization of special elements used in an OS command ('Command Injection') within the `mlflow.data.http_dataset_source.py` module. Specifically, when loading a dataset from a source URL with an HTTP scheme, the filename extracted from the `Content-Disposition` header or the URL path is used to generate the final file path without proper sanitization. This flaw enables an attacker to control the fi",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2024-0520 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-0520（MLflow）",
   "NVD 说明（英文原文）：A vulnerability in mlflow/mlflow version 8.2.1 allows for remote code execution due to improper neutralization of special elements used in an OS command ('Command Injection') within the `mlflow.data.http_dataset_source.py` module. Specifically, when loading a dataset from a source URL with an HTTP scheme, the filename extracted from the `Content-Disposition` header or the URL path is used to generate the final file path without proper sanitization. This flaw enables an attacker to control the fi",
   "请尽快将 MLflow 升级到不受 CVE-2024-0520 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-0520（MLflow）",
   "NVD 說明（英文原文）：A vulnerability in mlflow/mlflow version 8.2.1 allows for remote code execution due to improper neutralization of special elements used in an OS command ('Command Injection') within the `mlflow.data.http_dataset_source.py` module. Specifically, when loading a dataset from a source URL with an HTTP scheme, the filename extracted from the `Content-Disposition` header or the URL path is used to generate the final file path without proper sanitization. This flaw enables an attacker to control the fi",
   "請儘快將 MLflow 升級到不受 CVE-2024-0520 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2024-1483": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-1483 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): A path traversal vulnerability exists in mlflow/mlflow version 2.9.2, allowing attackers to access arbitrary files on the server. By crafting a series of HTTP POST requests with specially crafted 'artifact_location' and 'source' parameters, using a local URI with '#' instead of '?', an attacker can traverse the server's directory structure. The issue occurs due to insufficient validation of user-supplied input in the server's handlers.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2024-1483 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-1483 (MLflow)",
   "A path traversal vulnerability exists in mlflow/mlflow version 2.9.2, allowing attackers to access arbitrary files on the server. By crafting a series of HTTP POST requests with specially crafted 'artifact_location' and 'source' parameters, using a local URI with '#' instead of '?', an attacker can traverse the server's directory structure. The issue occurs due to insufficient validation of user-supplied input in the server's handlers.",
   "Upgrade MLflow to a version not affected by CVE-2024-1483 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-1483 (MLflow)",
   "Descripción de NVD (texto original en inglés): A path traversal vulnerability exists in mlflow/mlflow version 2.9.2, allowing attackers to access arbitrary files on the server. By crafting a series of HTTP POST requests with specially crafted 'artifact_location' and 'source' parameters, using a local URI with '#' instead of '?', an attacker can traverse the server's directory structure. The issue occurs due to insufficient validation of user-supplied input in the server's handlers.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2024-1483 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-1483 (MLflow)",
   "Description NVD (texte original en anglais) : A path traversal vulnerability exists in mlflow/mlflow version 2.9.2, allowing attackers to access arbitrary files on the server. By crafting a series of HTTP POST requests with specially crafted 'artifact_location' and 'source' parameters, using a local URI with '#' instead of '?', an attacker can traverse the server's directory structure. The issue occurs due to insufficient validation of user-supplied input in the server's handlers.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2024-1483 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-1483 (MLflow)",
   "Descrizione NVD (testo originale in inglese): A path traversal vulnerability exists in mlflow/mlflow version 2.9.2, allowing attackers to access arbitrary files on the server. By crafting a series of HTTP POST requests with specially crafted 'artifact_location' and 'source' parameters, using a local URI with '#' instead of '?', an attacker can traverse the server's directory structure. The issue occurs due to insufficient validation of user-supplied input in the server's handlers.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2024-1483 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-1483 (MLflow)",
   "NVDの説明（英語原文）: A path traversal vulnerability exists in mlflow/mlflow version 2.9.2, allowing attackers to access arbitrary files on the server. By crafting a series of HTTP POST requests with specially crafted 'artifact_location' and 'source' parameters, using a local URI with '#' instead of '?', an attacker can traverse the server's directory structure. The issue occurs due to insufficient validation of user-supplied input in the server's handlers.",
   "MLflow を CVE-2024-1483 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-1483 (MLflow)",
   "NVD 설명(영어 원문): A path traversal vulnerability exists in mlflow/mlflow version 2.9.2, allowing attackers to access arbitrary files on the server. By crafting a series of HTTP POST requests with specially crafted 'artifact_location' and 'source' parameters, using a local URI with '#' instead of '?', an attacker can traverse the server's directory structure. The issue occurs due to insufficient validation of user-supplied input in the server's handlers.",
   "MLflow을(를) CVE-2024-1483의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-1483 (MLflow)",
   "Descrição do NVD (texto original em inglês): A path traversal vulnerability exists in mlflow/mlflow version 2.9.2, allowing attackers to access arbitrary files on the server. By crafting a series of HTTP POST requests with specially crafted 'artifact_location' and 'source' parameters, using a local URI with '#' instead of '?', an attacker can traverse the server's directory structure. The issue occurs due to insufficient validation of user-supplied input in the server's handlers.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2024-1483 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-1483（MLflow）",
   "NVD 说明（英文原文）：A path traversal vulnerability exists in mlflow/mlflow version 2.9.2, allowing attackers to access arbitrary files on the server. By crafting a series of HTTP POST requests with specially crafted 'artifact_location' and 'source' parameters, using a local URI with '#' instead of '?', an attacker can traverse the server's directory structure. The issue occurs due to insufficient validation of user-supplied input in the server's handlers.",
   "请尽快将 MLflow 升级到不受 CVE-2024-1483 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-1483（MLflow）",
   "NVD 說明（英文原文）：A path traversal vulnerability exists in mlflow/mlflow version 2.9.2, allowing attackers to access arbitrary files on the server. By crafting a series of HTTP POST requests with specially crafted 'artifact_location' and 'source' parameters, using a local URI with '#' instead of '?', an attacker can traverse the server's directory structure. The issue occurs due to insufficient validation of user-supplied input in the server's handlers.",
   "請儘快將 MLflow 升級到不受 CVE-2024-1483 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2024-1558": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-1558 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): A path traversal vulnerability exists in the `_create_model_version()` function within `server/handlers.py` of the mlflow/mlflow repository, due to improper validation of the `source` parameter. Attackers can exploit this vulnerability by crafting a `source` parameter that bypasses the `_validate_non_local_source_contains_relative_paths(source)` function's checks, allowing for arbitrary file read access on the server. The issue arises from the handling of unquoted URL characters and the subseque",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2024-1558 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-1558 (MLflow)",
   "A path traversal vulnerability exists in the `_create_model_version()` function within `server/handlers.py` of the mlflow/mlflow repository, due to improper validation of the `source` parameter. Attackers can exploit this vulnerability by crafting a `source` parameter that bypasses the `_validate_non_local_source_contains_relative_paths(source)` function's checks, allowing for arbitrary file read access on the server. The issue arises from the handling of unquoted URL characters and the subseque",
   "Upgrade MLflow to a version not affected by CVE-2024-1558 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-1558 (MLflow)",
   "Descripción de NVD (texto original en inglés): A path traversal vulnerability exists in the `_create_model_version()` function within `server/handlers.py` of the mlflow/mlflow repository, due to improper validation of the `source` parameter. Attackers can exploit this vulnerability by crafting a `source` parameter that bypasses the `_validate_non_local_source_contains_relative_paths(source)` function's checks, allowing for arbitrary file read access on the server. The issue arises from the handling of unquoted URL characters and the subseque",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2024-1558 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-1558 (MLflow)",
   "Description NVD (texte original en anglais) : A path traversal vulnerability exists in the `_create_model_version()` function within `server/handlers.py` of the mlflow/mlflow repository, due to improper validation of the `source` parameter. Attackers can exploit this vulnerability by crafting a `source` parameter that bypasses the `_validate_non_local_source_contains_relative_paths(source)` function's checks, allowing for arbitrary file read access on the server. The issue arises from the handling of unquoted URL characters and the subseque",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2024-1558 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-1558 (MLflow)",
   "Descrizione NVD (testo originale in inglese): A path traversal vulnerability exists in the `_create_model_version()` function within `server/handlers.py` of the mlflow/mlflow repository, due to improper validation of the `source` parameter. Attackers can exploit this vulnerability by crafting a `source` parameter that bypasses the `_validate_non_local_source_contains_relative_paths(source)` function's checks, allowing for arbitrary file read access on the server. The issue arises from the handling of unquoted URL characters and the subseque",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2024-1558 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-1558 (MLflow)",
   "NVDの説明（英語原文）: A path traversal vulnerability exists in the `_create_model_version()` function within `server/handlers.py` of the mlflow/mlflow repository, due to improper validation of the `source` parameter. Attackers can exploit this vulnerability by crafting a `source` parameter that bypasses the `_validate_non_local_source_contains_relative_paths(source)` function's checks, allowing for arbitrary file read access on the server. The issue arises from the handling of unquoted URL characters and the subseque",
   "MLflow を CVE-2024-1558 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-1558 (MLflow)",
   "NVD 설명(영어 원문): A path traversal vulnerability exists in the `_create_model_version()` function within `server/handlers.py` of the mlflow/mlflow repository, due to improper validation of the `source` parameter. Attackers can exploit this vulnerability by crafting a `source` parameter that bypasses the `_validate_non_local_source_contains_relative_paths(source)` function's checks, allowing for arbitrary file read access on the server. The issue arises from the handling of unquoted URL characters and the subseque",
   "MLflow을(를) CVE-2024-1558의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-1558 (MLflow)",
   "Descrição do NVD (texto original em inglês): A path traversal vulnerability exists in the `_create_model_version()` function within `server/handlers.py` of the mlflow/mlflow repository, due to improper validation of the `source` parameter. Attackers can exploit this vulnerability by crafting a `source` parameter that bypasses the `_validate_non_local_source_contains_relative_paths(source)` function's checks, allowing for arbitrary file read access on the server. The issue arises from the handling of unquoted URL characters and the subseque",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2024-1558 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-1558（MLflow）",
   "NVD 说明（英文原文）：A path traversal vulnerability exists in the `_create_model_version()` function within `server/handlers.py` of the mlflow/mlflow repository, due to improper validation of the `source` parameter. Attackers can exploit this vulnerability by crafting a `source` parameter that bypasses the `_validate_non_local_source_contains_relative_paths(source)` function's checks, allowing for arbitrary file read access on the server. The issue arises from the handling of unquoted URL characters and the subseque",
   "请尽快将 MLflow 升级到不受 CVE-2024-1558 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-1558（MLflow）",
   "NVD 說明（英文原文）：A path traversal vulnerability exists in the `_create_model_version()` function within `server/handlers.py` of the mlflow/mlflow repository, due to improper validation of the `source` parameter. Attackers can exploit this vulnerability by crafting a `source` parameter that bypasses the `_validate_non_local_source_contains_relative_paths(source)` function's checks, allowing for arbitrary file read access on the server. The issue arises from the handling of unquoted URL characters and the subseque",
   "請儘快將 MLflow 升級到不受 CVE-2024-1558 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2024-1560": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-1560 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): A path traversal vulnerability exists in the mlflow/mlflow repository, specifically within the artifact deletion functionality. Attackers can bypass path validation by exploiting the double decoding process in the `_delete_artifact_mlflow_artifacts` handler and `local_file_uri_to_path` function, allowing for the deletion of arbitrary directories on the server's filesystem. This vulnerability is due to an extra unquote operation in the `delete_artifacts` function of `local_artifact_repo.py`, whic",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2024-1560 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-1560 (MLflow)",
   "A path traversal vulnerability exists in the mlflow/mlflow repository, specifically within the artifact deletion functionality. Attackers can bypass path validation by exploiting the double decoding process in the `_delete_artifact_mlflow_artifacts` handler and `local_file_uri_to_path` function, allowing for the deletion of arbitrary directories on the server's filesystem. This vulnerability is due to an extra unquote operation in the `delete_artifacts` function of `local_artifact_repo.py`, whic",
   "Upgrade MLflow to a version not affected by CVE-2024-1560 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-1560 (MLflow)",
   "Descripción de NVD (texto original en inglés): A path traversal vulnerability exists in the mlflow/mlflow repository, specifically within the artifact deletion functionality. Attackers can bypass path validation by exploiting the double decoding process in the `_delete_artifact_mlflow_artifacts` handler and `local_file_uri_to_path` function, allowing for the deletion of arbitrary directories on the server's filesystem. This vulnerability is due to an extra unquote operation in the `delete_artifacts` function of `local_artifact_repo.py`, whic",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2024-1560 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-1560 (MLflow)",
   "Description NVD (texte original en anglais) : A path traversal vulnerability exists in the mlflow/mlflow repository, specifically within the artifact deletion functionality. Attackers can bypass path validation by exploiting the double decoding process in the `_delete_artifact_mlflow_artifacts` handler and `local_file_uri_to_path` function, allowing for the deletion of arbitrary directories on the server's filesystem. This vulnerability is due to an extra unquote operation in the `delete_artifacts` function of `local_artifact_repo.py`, whic",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2024-1560 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-1560 (MLflow)",
   "Descrizione NVD (testo originale in inglese): A path traversal vulnerability exists in the mlflow/mlflow repository, specifically within the artifact deletion functionality. Attackers can bypass path validation by exploiting the double decoding process in the `_delete_artifact_mlflow_artifacts` handler and `local_file_uri_to_path` function, allowing for the deletion of arbitrary directories on the server's filesystem. This vulnerability is due to an extra unquote operation in the `delete_artifacts` function of `local_artifact_repo.py`, whic",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2024-1560 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-1560 (MLflow)",
   "NVDの説明（英語原文）: A path traversal vulnerability exists in the mlflow/mlflow repository, specifically within the artifact deletion functionality. Attackers can bypass path validation by exploiting the double decoding process in the `_delete_artifact_mlflow_artifacts` handler and `local_file_uri_to_path` function, allowing for the deletion of arbitrary directories on the server's filesystem. This vulnerability is due to an extra unquote operation in the `delete_artifacts` function of `local_artifact_repo.py`, whic",
   "MLflow を CVE-2024-1560 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-1560 (MLflow)",
   "NVD 설명(영어 원문): A path traversal vulnerability exists in the mlflow/mlflow repository, specifically within the artifact deletion functionality. Attackers can bypass path validation by exploiting the double decoding process in the `_delete_artifact_mlflow_artifacts` handler and `local_file_uri_to_path` function, allowing for the deletion of arbitrary directories on the server's filesystem. This vulnerability is due to an extra unquote operation in the `delete_artifacts` function of `local_artifact_repo.py`, whic",
   "MLflow을(를) CVE-2024-1560의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-1560 (MLflow)",
   "Descrição do NVD (texto original em inglês): A path traversal vulnerability exists in the mlflow/mlflow repository, specifically within the artifact deletion functionality. Attackers can bypass path validation by exploiting the double decoding process in the `_delete_artifact_mlflow_artifacts` handler and `local_file_uri_to_path` function, allowing for the deletion of arbitrary directories on the server's filesystem. This vulnerability is due to an extra unquote operation in the `delete_artifacts` function of `local_artifact_repo.py`, whic",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2024-1560 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-1560（MLflow）",
   "NVD 说明（英文原文）：A path traversal vulnerability exists in the mlflow/mlflow repository, specifically within the artifact deletion functionality. Attackers can bypass path validation by exploiting the double decoding process in the `_delete_artifact_mlflow_artifacts` handler and `local_file_uri_to_path` function, allowing for the deletion of arbitrary directories on the server's filesystem. This vulnerability is due to an extra unquote operation in the `delete_artifacts` function of `local_artifact_repo.py`, whic",
   "请尽快将 MLflow 升级到不受 CVE-2024-1560 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-1560（MLflow）",
   "NVD 說明（英文原文）：A path traversal vulnerability exists in the mlflow/mlflow repository, specifically within the artifact deletion functionality. Attackers can bypass path validation by exploiting the double decoding process in the `_delete_artifact_mlflow_artifacts` handler and `local_file_uri_to_path` function, allowing for the deletion of arbitrary directories on the server's filesystem. This vulnerability is due to an extra unquote operation in the `delete_artifacts` function of `local_artifact_repo.py`, whic",
   "請儘快將 MLflow 升級到不受 CVE-2024-1560 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2024-1593": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-1593 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): A path traversal vulnerability exists in the mlflow/mlflow repository due to improper handling of URL parameters. By smuggling path traversal sequences using the ';' character in URLs, attackers can manipulate the 'params' portion of the URL to gain unauthorized access to files or directories. This vulnerability allows for arbitrary data smuggling into the 'params' part of the URL, enabling attacks similar to those described in previous reports but utilizing the ';' character for parameter smugg",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2024-1593 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-1593 (MLflow)",
   "A path traversal vulnerability exists in the mlflow/mlflow repository due to improper handling of URL parameters. By smuggling path traversal sequences using the ';' character in URLs, attackers can manipulate the 'params' portion of the URL to gain unauthorized access to files or directories. This vulnerability allows for arbitrary data smuggling into the 'params' part of the URL, enabling attacks similar to those described in previous reports but utilizing the ';' character for parameter smugg",
   "Upgrade MLflow to a version not affected by CVE-2024-1593 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-1593 (MLflow)",
   "Descripción de NVD (texto original en inglés): A path traversal vulnerability exists in the mlflow/mlflow repository due to improper handling of URL parameters. By smuggling path traversal sequences using the ';' character in URLs, attackers can manipulate the 'params' portion of the URL to gain unauthorized access to files or directories. This vulnerability allows for arbitrary data smuggling into the 'params' part of the URL, enabling attacks similar to those described in previous reports but utilizing the ';' character for parameter smugg",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2024-1593 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-1593 (MLflow)",
   "Description NVD (texte original en anglais) : A path traversal vulnerability exists in the mlflow/mlflow repository due to improper handling of URL parameters. By smuggling path traversal sequences using the ';' character in URLs, attackers can manipulate the 'params' portion of the URL to gain unauthorized access to files or directories. This vulnerability allows for arbitrary data smuggling into the 'params' part of the URL, enabling attacks similar to those described in previous reports but utilizing the ';' character for parameter smugg",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2024-1593 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-1593 (MLflow)",
   "Descrizione NVD (testo originale in inglese): A path traversal vulnerability exists in the mlflow/mlflow repository due to improper handling of URL parameters. By smuggling path traversal sequences using the ';' character in URLs, attackers can manipulate the 'params' portion of the URL to gain unauthorized access to files or directories. This vulnerability allows for arbitrary data smuggling into the 'params' part of the URL, enabling attacks similar to those described in previous reports but utilizing the ';' character for parameter smugg",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2024-1593 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-1593 (MLflow)",
   "NVDの説明（英語原文）: A path traversal vulnerability exists in the mlflow/mlflow repository due to improper handling of URL parameters. By smuggling path traversal sequences using the ';' character in URLs, attackers can manipulate the 'params' portion of the URL to gain unauthorized access to files or directories. This vulnerability allows for arbitrary data smuggling into the 'params' part of the URL, enabling attacks similar to those described in previous reports but utilizing the ';' character for parameter smugg",
   "MLflow を CVE-2024-1593 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-1593 (MLflow)",
   "NVD 설명(영어 원문): A path traversal vulnerability exists in the mlflow/mlflow repository due to improper handling of URL parameters. By smuggling path traversal sequences using the ';' character in URLs, attackers can manipulate the 'params' portion of the URL to gain unauthorized access to files or directories. This vulnerability allows for arbitrary data smuggling into the 'params' part of the URL, enabling attacks similar to those described in previous reports but utilizing the ';' character for parameter smugg",
   "MLflow을(를) CVE-2024-1593의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-1593 (MLflow)",
   "Descrição do NVD (texto original em inglês): A path traversal vulnerability exists in the mlflow/mlflow repository due to improper handling of URL parameters. By smuggling path traversal sequences using the ';' character in URLs, attackers can manipulate the 'params' portion of the URL to gain unauthorized access to files or directories. This vulnerability allows for arbitrary data smuggling into the 'params' part of the URL, enabling attacks similar to those described in previous reports but utilizing the ';' character for parameter smugg",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2024-1593 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-1593（MLflow）",
   "NVD 说明（英文原文）：A path traversal vulnerability exists in the mlflow/mlflow repository due to improper handling of URL parameters. By smuggling path traversal sequences using the ';' character in URLs, attackers can manipulate the 'params' portion of the URL to gain unauthorized access to files or directories. This vulnerability allows for arbitrary data smuggling into the 'params' part of the URL, enabling attacks similar to those described in previous reports but utilizing the ';' character for parameter smugg",
   "请尽快将 MLflow 升级到不受 CVE-2024-1593 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-1593（MLflow）",
   "NVD 說明（英文原文）：A path traversal vulnerability exists in the mlflow/mlflow repository due to improper handling of URL parameters. By smuggling path traversal sequences using the ';' character in URLs, attackers can manipulate the 'params' portion of the URL to gain unauthorized access to files or directories. This vulnerability allows for arbitrary data smuggling into the 'params' part of the URL, enabling attacks similar to those described in previous reports but utilizing the ';' character for parameter smugg",
   "請儘快將 MLflow 升級到不受 CVE-2024-1593 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2024-1594": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-1594 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): A path traversal vulnerability exists in the mlflow/mlflow repository, specifically within the handling of the `artifact_location` parameter when creating an experiment. Attackers can exploit this vulnerability by using a fragment component `#` in the artifact location URI to read arbitrary files on the server in the context of the server's process. This issue is similar to CVE-2023-6909 but utilizes a different component of the URI to achieve the same effect.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2024-1594 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-1594 (MLflow)",
   "A path traversal vulnerability exists in the mlflow/mlflow repository, specifically within the handling of the `artifact_location` parameter when creating an experiment. Attackers can exploit this vulnerability by using a fragment component `#` in the artifact location URI to read arbitrary files on the server in the context of the server's process. This issue is similar to CVE-2023-6909 but utilizes a different component of the URI to achieve the same effect.",
   "Upgrade MLflow to a version not affected by CVE-2024-1594 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-1594 (MLflow)",
   "Descripción de NVD (texto original en inglés): A path traversal vulnerability exists in the mlflow/mlflow repository, specifically within the handling of the `artifact_location` parameter when creating an experiment. Attackers can exploit this vulnerability by using a fragment component `#` in the artifact location URI to read arbitrary files on the server in the context of the server's process. This issue is similar to CVE-2023-6909 but utilizes a different component of the URI to achieve the same effect.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2024-1594 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-1594 (MLflow)",
   "Description NVD (texte original en anglais) : A path traversal vulnerability exists in the mlflow/mlflow repository, specifically within the handling of the `artifact_location` parameter when creating an experiment. Attackers can exploit this vulnerability by using a fragment component `#` in the artifact location URI to read arbitrary files on the server in the context of the server's process. This issue is similar to CVE-2023-6909 but utilizes a different component of the URI to achieve the same effect.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2024-1594 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-1594 (MLflow)",
   "Descrizione NVD (testo originale in inglese): A path traversal vulnerability exists in the mlflow/mlflow repository, specifically within the handling of the `artifact_location` parameter when creating an experiment. Attackers can exploit this vulnerability by using a fragment component `#` in the artifact location URI to read arbitrary files on the server in the context of the server's process. This issue is similar to CVE-2023-6909 but utilizes a different component of the URI to achieve the same effect.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2024-1594 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-1594 (MLflow)",
   "NVDの説明（英語原文）: A path traversal vulnerability exists in the mlflow/mlflow repository, specifically within the handling of the `artifact_location` parameter when creating an experiment. Attackers can exploit this vulnerability by using a fragment component `#` in the artifact location URI to read arbitrary files on the server in the context of the server's process. This issue is similar to CVE-2023-6909 but utilizes a different component of the URI to achieve the same effect.",
   "MLflow を CVE-2024-1594 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-1594 (MLflow)",
   "NVD 설명(영어 원문): A path traversal vulnerability exists in the mlflow/mlflow repository, specifically within the handling of the `artifact_location` parameter when creating an experiment. Attackers can exploit this vulnerability by using a fragment component `#` in the artifact location URI to read arbitrary files on the server in the context of the server's process. This issue is similar to CVE-2023-6909 but utilizes a different component of the URI to achieve the same effect.",
   "MLflow을(를) CVE-2024-1594의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-1594 (MLflow)",
   "Descrição do NVD (texto original em inglês): A path traversal vulnerability exists in the mlflow/mlflow repository, specifically within the handling of the `artifact_location` parameter when creating an experiment. Attackers can exploit this vulnerability by using a fragment component `#` in the artifact location URI to read arbitrary files on the server in the context of the server's process. This issue is similar to CVE-2023-6909 but utilizes a different component of the URI to achieve the same effect.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2024-1594 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-1594（MLflow）",
   "NVD 说明（英文原文）：A path traversal vulnerability exists in the mlflow/mlflow repository, specifically within the handling of the `artifact_location` parameter when creating an experiment. Attackers can exploit this vulnerability by using a fragment component `#` in the artifact location URI to read arbitrary files on the server in the context of the server's process. This issue is similar to CVE-2023-6909 but utilizes a different component of the URI to achieve the same effect.",
   "请尽快将 MLflow 升级到不受 CVE-2024-1594 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-1594（MLflow）",
   "NVD 說明（英文原文）：A path traversal vulnerability exists in the mlflow/mlflow repository, specifically within the handling of the `artifact_location` parameter when creating an experiment. Attackers can exploit this vulnerability by using a fragment component `#` in the artifact location URI to read arbitrary files on the server in the context of the server's process. This issue is similar to CVE-2023-6909 but utilizes a different component of the URI to achieve the same effect.",
   "請儘快將 MLflow 升級到不受 CVE-2024-1594 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2024-27132": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-27132 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): Insufficient sanitization in MLflow leads to XSS when running an untrusted recipe.\n\nThis issue leads to a client-side RCE when running an untrusted recipe in Jupyter Notebook.\n\nThe vulnerability stems from lack of sanitization over template variables.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2024-27132 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-27132 (MLflow)",
   "Insufficient sanitization in MLflow leads to XSS when running an untrusted recipe.\n\nThis issue leads to a client-side RCE when running an untrusted recipe in Jupyter Notebook.\n\nThe vulnerability stems from lack of sanitization over template variables.",
   "Upgrade MLflow to a version not affected by CVE-2024-27132 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-27132 (MLflow)",
   "Descripción de NVD (texto original en inglés): Insufficient sanitization in MLflow leads to XSS when running an untrusted recipe.\n\nThis issue leads to a client-side RCE when running an untrusted recipe in Jupyter Notebook.\n\nThe vulnerability stems from lack of sanitization over template variables.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2024-27132 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-27132 (MLflow)",
   "Description NVD (texte original en anglais) : Insufficient sanitization in MLflow leads to XSS when running an untrusted recipe.\n\nThis issue leads to a client-side RCE when running an untrusted recipe in Jupyter Notebook.\n\nThe vulnerability stems from lack of sanitization over template variables.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2024-27132 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-27132 (MLflow)",
   "Descrizione NVD (testo originale in inglese): Insufficient sanitization in MLflow leads to XSS when running an untrusted recipe.\n\nThis issue leads to a client-side RCE when running an untrusted recipe in Jupyter Notebook.\n\nThe vulnerability stems from lack of sanitization over template variables.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2024-27132 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-27132 (MLflow)",
   "NVDの説明（英語原文）: Insufficient sanitization in MLflow leads to XSS when running an untrusted recipe.\n\nThis issue leads to a client-side RCE when running an untrusted recipe in Jupyter Notebook.\n\nThe vulnerability stems from lack of sanitization over template variables.",
   "MLflow を CVE-2024-27132 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-27132 (MLflow)",
   "NVD 설명(영어 원문): Insufficient sanitization in MLflow leads to XSS when running an untrusted recipe.\n\nThis issue leads to a client-side RCE when running an untrusted recipe in Jupyter Notebook.\n\nThe vulnerability stems from lack of sanitization over template variables.",
   "MLflow을(를) CVE-2024-27132의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-27132 (MLflow)",
   "Descrição do NVD (texto original em inglês): Insufficient sanitization in MLflow leads to XSS when running an untrusted recipe.\n\nThis issue leads to a client-side RCE when running an untrusted recipe in Jupyter Notebook.\n\nThe vulnerability stems from lack of sanitization over template variables.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2024-27132 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-27132（MLflow）",
   "NVD 说明（英文原文）：Insufficient sanitization in MLflow leads to XSS when running an untrusted recipe.\n\nThis issue leads to a client-side RCE when running an untrusted recipe in Jupyter Notebook.\n\nThe vulnerability stems from lack of sanitization over template variables.",
   "请尽快将 MLflow 升级到不受 CVE-2024-27132 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-27132（MLflow）",
   "NVD 說明（英文原文）：Insufficient sanitization in MLflow leads to XSS when running an untrusted recipe.\n\nThis issue leads to a client-side RCE when running an untrusted recipe in Jupyter Notebook.\n\nThe vulnerability stems from lack of sanitization over template variables.",
   "請儘快將 MLflow 升級到不受 CVE-2024-27132 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2024-27133": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-27133 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): Insufficient sanitization in MLflow leads to XSS when running a recipe that uses an untrusted dataset. This issue leads to a client-side RCE when running the recipe in Jupyter Notebook. The vulnerability stems from lack of sanitization over dataset table fields.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2024-27133 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-27133 (MLflow)",
   "Insufficient sanitization in MLflow leads to XSS when running a recipe that uses an untrusted dataset. This issue leads to a client-side RCE when running the recipe in Jupyter Notebook. The vulnerability stems from lack of sanitization over dataset table fields.",
   "Upgrade MLflow to a version not affected by CVE-2024-27133 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-27133 (MLflow)",
   "Descripción de NVD (texto original en inglés): Insufficient sanitization in MLflow leads to XSS when running a recipe that uses an untrusted dataset. This issue leads to a client-side RCE when running the recipe in Jupyter Notebook. The vulnerability stems from lack of sanitization over dataset table fields.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2024-27133 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-27133 (MLflow)",
   "Description NVD (texte original en anglais) : Insufficient sanitization in MLflow leads to XSS when running a recipe that uses an untrusted dataset. This issue leads to a client-side RCE when running the recipe in Jupyter Notebook. The vulnerability stems from lack of sanitization over dataset table fields.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2024-27133 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-27133 (MLflow)",
   "Descrizione NVD (testo originale in inglese): Insufficient sanitization in MLflow leads to XSS when running a recipe that uses an untrusted dataset. This issue leads to a client-side RCE when running the recipe in Jupyter Notebook. The vulnerability stems from lack of sanitization over dataset table fields.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2024-27133 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-27133 (MLflow)",
   "NVDの説明（英語原文）: Insufficient sanitization in MLflow leads to XSS when running a recipe that uses an untrusted dataset. This issue leads to a client-side RCE when running the recipe in Jupyter Notebook. The vulnerability stems from lack of sanitization over dataset table fields.",
   "MLflow を CVE-2024-27133 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-27133 (MLflow)",
   "NVD 설명(영어 원문): Insufficient sanitization in MLflow leads to XSS when running a recipe that uses an untrusted dataset. This issue leads to a client-side RCE when running the recipe in Jupyter Notebook. The vulnerability stems from lack of sanitization over dataset table fields.",
   "MLflow을(를) CVE-2024-27133의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-27133 (MLflow)",
   "Descrição do NVD (texto original em inglês): Insufficient sanitization in MLflow leads to XSS when running a recipe that uses an untrusted dataset. This issue leads to a client-side RCE when running the recipe in Jupyter Notebook. The vulnerability stems from lack of sanitization over dataset table fields.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2024-27133 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-27133（MLflow）",
   "NVD 说明（英文原文）：Insufficient sanitization in MLflow leads to XSS when running a recipe that uses an untrusted dataset. This issue leads to a client-side RCE when running the recipe in Jupyter Notebook. The vulnerability stems from lack of sanitization over dataset table fields.",
   "请尽快将 MLflow 升级到不受 CVE-2024-27133 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-27133（MLflow）",
   "NVD 說明（英文原文）：Insufficient sanitization in MLflow leads to XSS when running a recipe that uses an untrusted dataset. This issue leads to a client-side RCE when running the recipe in Jupyter Notebook. The vulnerability stems from lack of sanitization over dataset table fields.",
   "請儘快將 MLflow 升級到不受 CVE-2024-27133 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2024-27134": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-27134 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): Excessive directory permissions in MLflow leads to local privilege escalation when using spark_udf. This behavior can be exploited by a local attacker to gain elevated permissions by using a ToCToU attack. The issue is only relevant when the spark_udf() MLflow API is called.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2024-27134 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-27134 (MLflow)",
   "Excessive directory permissions in MLflow leads to local privilege escalation when using spark_udf. This behavior can be exploited by a local attacker to gain elevated permissions by using a ToCToU attack. The issue is only relevant when the spark_udf() MLflow API is called.",
   "Upgrade MLflow to a version not affected by CVE-2024-27134 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-27134 (MLflow)",
   "Descripción de NVD (texto original en inglés): Excessive directory permissions in MLflow leads to local privilege escalation when using spark_udf. This behavior can be exploited by a local attacker to gain elevated permissions by using a ToCToU attack. The issue is only relevant when the spark_udf() MLflow API is called.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2024-27134 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-27134 (MLflow)",
   "Description NVD (texte original en anglais) : Excessive directory permissions in MLflow leads to local privilege escalation when using spark_udf. This behavior can be exploited by a local attacker to gain elevated permissions by using a ToCToU attack. The issue is only relevant when the spark_udf() MLflow API is called.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2024-27134 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-27134 (MLflow)",
   "Descrizione NVD (testo originale in inglese): Excessive directory permissions in MLflow leads to local privilege escalation when using spark_udf. This behavior can be exploited by a local attacker to gain elevated permissions by using a ToCToU attack. The issue is only relevant when the spark_udf() MLflow API is called.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2024-27134 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-27134 (MLflow)",
   "NVDの説明（英語原文）: Excessive directory permissions in MLflow leads to local privilege escalation when using spark_udf. This behavior can be exploited by a local attacker to gain elevated permissions by using a ToCToU attack. The issue is only relevant when the spark_udf() MLflow API is called.",
   "MLflow を CVE-2024-27134 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-27134 (MLflow)",
   "NVD 설명(영어 원문): Excessive directory permissions in MLflow leads to local privilege escalation when using spark_udf. This behavior can be exploited by a local attacker to gain elevated permissions by using a ToCToU attack. The issue is only relevant when the spark_udf() MLflow API is called.",
   "MLflow을(를) CVE-2024-27134의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-27134 (MLflow)",
   "Descrição do NVD (texto original em inglês): Excessive directory permissions in MLflow leads to local privilege escalation when using spark_udf. This behavior can be exploited by a local attacker to gain elevated permissions by using a ToCToU attack. The issue is only relevant when the spark_udf() MLflow API is called.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2024-27134 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-27134（MLflow）",
   "NVD 说明（英文原文）：Excessive directory permissions in MLflow leads to local privilege escalation when using spark_udf. This behavior can be exploited by a local attacker to gain elevated permissions by using a ToCToU attack. The issue is only relevant when the spark_udf() MLflow API is called.",
   "请尽快将 MLflow 升级到不受 CVE-2024-27134 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-27134（MLflow）",
   "NVD 說明（英文原文）：Excessive directory permissions in MLflow leads to local privilege escalation when using spark_udf. This behavior can be exploited by a local attacker to gain elevated permissions by using a ToCToU attack. The issue is only relevant when the spark_udf() MLflow API is called.",
   "請儘快將 MLflow 升級到不受 CVE-2024-27134 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2024-2928": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-2928 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): A Local File Inclusion (LFI) vulnerability was identified in mlflow/mlflow, specifically in version 2.9.2, which was fixed in version 2.11.3. This vulnerability arises from the application's failure to properly validate URI fragments for directory traversal sequences such as '../'. An attacker can exploit this flaw by manipulating the fragment part of the URI to read arbitrary files on the local file system, including sensitive files like '/etc/passwd'. The vulnerability is a bypass to a previou",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2024-2928 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-2928 (MLflow)",
   "A Local File Inclusion (LFI) vulnerability was identified in mlflow/mlflow, specifically in version 2.9.2, which was fixed in version 2.11.3. This vulnerability arises from the application's failure to properly validate URI fragments for directory traversal sequences such as '../'. An attacker can exploit this flaw by manipulating the fragment part of the URI to read arbitrary files on the local file system, including sensitive files like '/etc/passwd'. The vulnerability is a bypass to a previou",
   "Upgrade MLflow to a version not affected by CVE-2024-2928 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-2928 (MLflow)",
   "Descripción de NVD (texto original en inglés): A Local File Inclusion (LFI) vulnerability was identified in mlflow/mlflow, specifically in version 2.9.2, which was fixed in version 2.11.3. This vulnerability arises from the application's failure to properly validate URI fragments for directory traversal sequences such as '../'. An attacker can exploit this flaw by manipulating the fragment part of the URI to read arbitrary files on the local file system, including sensitive files like '/etc/passwd'. The vulnerability is a bypass to a previou",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2024-2928 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-2928 (MLflow)",
   "Description NVD (texte original en anglais) : A Local File Inclusion (LFI) vulnerability was identified in mlflow/mlflow, specifically in version 2.9.2, which was fixed in version 2.11.3. This vulnerability arises from the application's failure to properly validate URI fragments for directory traversal sequences such as '../'. An attacker can exploit this flaw by manipulating the fragment part of the URI to read arbitrary files on the local file system, including sensitive files like '/etc/passwd'. The vulnerability is a bypass to a previou",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2024-2928 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-2928 (MLflow)",
   "Descrizione NVD (testo originale in inglese): A Local File Inclusion (LFI) vulnerability was identified in mlflow/mlflow, specifically in version 2.9.2, which was fixed in version 2.11.3. This vulnerability arises from the application's failure to properly validate URI fragments for directory traversal sequences such as '../'. An attacker can exploit this flaw by manipulating the fragment part of the URI to read arbitrary files on the local file system, including sensitive files like '/etc/passwd'. The vulnerability is a bypass to a previou",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2024-2928 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-2928 (MLflow)",
   "NVDの説明（英語原文）: A Local File Inclusion (LFI) vulnerability was identified in mlflow/mlflow, specifically in version 2.9.2, which was fixed in version 2.11.3. This vulnerability arises from the application's failure to properly validate URI fragments for directory traversal sequences such as '../'. An attacker can exploit this flaw by manipulating the fragment part of the URI to read arbitrary files on the local file system, including sensitive files like '/etc/passwd'. The vulnerability is a bypass to a previou",
   "MLflow を CVE-2024-2928 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-2928 (MLflow)",
   "NVD 설명(영어 원문): A Local File Inclusion (LFI) vulnerability was identified in mlflow/mlflow, specifically in version 2.9.2, which was fixed in version 2.11.3. This vulnerability arises from the application's failure to properly validate URI fragments for directory traversal sequences such as '../'. An attacker can exploit this flaw by manipulating the fragment part of the URI to read arbitrary files on the local file system, including sensitive files like '/etc/passwd'. The vulnerability is a bypass to a previou",
   "MLflow을(를) CVE-2024-2928의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-2928 (MLflow)",
   "Descrição do NVD (texto original em inglês): A Local File Inclusion (LFI) vulnerability was identified in mlflow/mlflow, specifically in version 2.9.2, which was fixed in version 2.11.3. This vulnerability arises from the application's failure to properly validate URI fragments for directory traversal sequences such as '../'. An attacker can exploit this flaw by manipulating the fragment part of the URI to read arbitrary files on the local file system, including sensitive files like '/etc/passwd'. The vulnerability is a bypass to a previou",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2024-2928 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-2928（MLflow）",
   "NVD 说明（英文原文）：A Local File Inclusion (LFI) vulnerability was identified in mlflow/mlflow, specifically in version 2.9.2, which was fixed in version 2.11.3. This vulnerability arises from the application's failure to properly validate URI fragments for directory traversal sequences such as '../'. An attacker can exploit this flaw by manipulating the fragment part of the URI to read arbitrary files on the local file system, including sensitive files like '/etc/passwd'. The vulnerability is a bypass to a previou",
   "请尽快将 MLflow 升级到不受 CVE-2024-2928 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-2928（MLflow）",
   "NVD 說明（英文原文）：A Local File Inclusion (LFI) vulnerability was identified in mlflow/mlflow, specifically in version 2.9.2, which was fixed in version 2.11.3. This vulnerability arises from the application's failure to properly validate URI fragments for directory traversal sequences such as '../'. An attacker can exploit this flaw by manipulating the fragment part of the URI to read arbitrary files on the local file system, including sensitive files like '/etc/passwd'. The vulnerability is a bypass to a previou",
   "請儘快將 MLflow 升級到不受 CVE-2024-2928 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2024-3573": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-3573 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): mlflow/mlflow is vulnerable to Local File Inclusion (LFI) due to improper parsing of URIs, allowing attackers to bypass checks and read arbitrary files on the system. The issue arises from the 'is_local_uri' function's failure to properly handle URIs with empty or 'file' schemes, leading to the misclassification of URIs as non-local. Attackers can exploit this by crafting malicious model versions with specially crafted 'source' parameters, enabling the reading of sensitive files within at least ",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2024-3573 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-3573 (MLflow)",
   "mlflow/mlflow is vulnerable to Local File Inclusion (LFI) due to improper parsing of URIs, allowing attackers to bypass checks and read arbitrary files on the system. The issue arises from the 'is_local_uri' function's failure to properly handle URIs with empty or 'file' schemes, leading to the misclassification of URIs as non-local. Attackers can exploit this by crafting malicious model versions with specially crafted 'source' parameters, enabling the reading of sensitive files within at least ",
   "Upgrade MLflow to a version not affected by CVE-2024-3573 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-3573 (MLflow)",
   "Descripción de NVD (texto original en inglés): mlflow/mlflow is vulnerable to Local File Inclusion (LFI) due to improper parsing of URIs, allowing attackers to bypass checks and read arbitrary files on the system. The issue arises from the 'is_local_uri' function's failure to properly handle URIs with empty or 'file' schemes, leading to the misclassification of URIs as non-local. Attackers can exploit this by crafting malicious model versions with specially crafted 'source' parameters, enabling the reading of sensitive files within at least ",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2024-3573 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-3573 (MLflow)",
   "Description NVD (texte original en anglais) : mlflow/mlflow is vulnerable to Local File Inclusion (LFI) due to improper parsing of URIs, allowing attackers to bypass checks and read arbitrary files on the system. The issue arises from the 'is_local_uri' function's failure to properly handle URIs with empty or 'file' schemes, leading to the misclassification of URIs as non-local. Attackers can exploit this by crafting malicious model versions with specially crafted 'source' parameters, enabling the reading of sensitive files within at least ",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2024-3573 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-3573 (MLflow)",
   "Descrizione NVD (testo originale in inglese): mlflow/mlflow is vulnerable to Local File Inclusion (LFI) due to improper parsing of URIs, allowing attackers to bypass checks and read arbitrary files on the system. The issue arises from the 'is_local_uri' function's failure to properly handle URIs with empty or 'file' schemes, leading to the misclassification of URIs as non-local. Attackers can exploit this by crafting malicious model versions with specially crafted 'source' parameters, enabling the reading of sensitive files within at least ",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2024-3573 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-3573 (MLflow)",
   "NVDの説明（英語原文）: mlflow/mlflow is vulnerable to Local File Inclusion (LFI) due to improper parsing of URIs, allowing attackers to bypass checks and read arbitrary files on the system. The issue arises from the 'is_local_uri' function's failure to properly handle URIs with empty or 'file' schemes, leading to the misclassification of URIs as non-local. Attackers can exploit this by crafting malicious model versions with specially crafted 'source' parameters, enabling the reading of sensitive files within at least ",
   "MLflow を CVE-2024-3573 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-3573 (MLflow)",
   "NVD 설명(영어 원문): mlflow/mlflow is vulnerable to Local File Inclusion (LFI) due to improper parsing of URIs, allowing attackers to bypass checks and read arbitrary files on the system. The issue arises from the 'is_local_uri' function's failure to properly handle URIs with empty or 'file' schemes, leading to the misclassification of URIs as non-local. Attackers can exploit this by crafting malicious model versions with specially crafted 'source' parameters, enabling the reading of sensitive files within at least ",
   "MLflow을(를) CVE-2024-3573의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-3573 (MLflow)",
   "Descrição do NVD (texto original em inglês): mlflow/mlflow is vulnerable to Local File Inclusion (LFI) due to improper parsing of URIs, allowing attackers to bypass checks and read arbitrary files on the system. The issue arises from the 'is_local_uri' function's failure to properly handle URIs with empty or 'file' schemes, leading to the misclassification of URIs as non-local. Attackers can exploit this by crafting malicious model versions with specially crafted 'source' parameters, enabling the reading of sensitive files within at least ",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2024-3573 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-3573（MLflow）",
   "NVD 说明（英文原文）：mlflow/mlflow is vulnerable to Local File Inclusion (LFI) due to improper parsing of URIs, allowing attackers to bypass checks and read arbitrary files on the system. The issue arises from the 'is_local_uri' function's failure to properly handle URIs with empty or 'file' schemes, leading to the misclassification of URIs as non-local. Attackers can exploit this by crafting malicious model versions with specially crafted 'source' parameters, enabling the reading of sensitive files within at least ",
   "请尽快将 MLflow 升级到不受 CVE-2024-3573 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-3573（MLflow）",
   "NVD 說明（英文原文）：mlflow/mlflow is vulnerable to Local File Inclusion (LFI) due to improper parsing of URIs, allowing attackers to bypass checks and read arbitrary files on the system. The issue arises from the 'is_local_uri' function's failure to properly handle URIs with empty or 'file' schemes, leading to the misclassification of URIs as non-local. Attackers can exploit this by crafting malicious model versions with specially crafted 'source' parameters, enabling the reading of sensitive files within at least ",
   "請儘快將 MLflow 升級到不受 CVE-2024-3573 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2024-3848": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-3848 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): A path traversal vulnerability exists in mlflow/mlflow version 2.11.0, identified as a bypass for the previously addressed CVE-2023-6909. The vulnerability arises from the application's handling of artifact URLs, where a '#' character can be used to insert a path into the fragment, effectively skipping validation. This allows an attacker to construct a URL that, when processed, ignores the protocol scheme and uses the provided path for filesystem access. As a result, an attacker can read arbitra",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2024-3848 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-3848 (MLflow)",
   "A path traversal vulnerability exists in mlflow/mlflow version 2.11.0, identified as a bypass for the previously addressed CVE-2023-6909. The vulnerability arises from the application's handling of artifact URLs, where a '#' character can be used to insert a path into the fragment, effectively skipping validation. This allows an attacker to construct a URL that, when processed, ignores the protocol scheme and uses the provided path for filesystem access. As a result, an attacker can read arbitra",
   "Upgrade MLflow to a version not affected by CVE-2024-3848 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-3848 (MLflow)",
   "Descripción de NVD (texto original en inglés): A path traversal vulnerability exists in mlflow/mlflow version 2.11.0, identified as a bypass for the previously addressed CVE-2023-6909. The vulnerability arises from the application's handling of artifact URLs, where a '#' character can be used to insert a path into the fragment, effectively skipping validation. This allows an attacker to construct a URL that, when processed, ignores the protocol scheme and uses the provided path for filesystem access. As a result, an attacker can read arbitra",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2024-3848 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-3848 (MLflow)",
   "Description NVD (texte original en anglais) : A path traversal vulnerability exists in mlflow/mlflow version 2.11.0, identified as a bypass for the previously addressed CVE-2023-6909. The vulnerability arises from the application's handling of artifact URLs, where a '#' character can be used to insert a path into the fragment, effectively skipping validation. This allows an attacker to construct a URL that, when processed, ignores the protocol scheme and uses the provided path for filesystem access. As a result, an attacker can read arbitra",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2024-3848 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-3848 (MLflow)",
   "Descrizione NVD (testo originale in inglese): A path traversal vulnerability exists in mlflow/mlflow version 2.11.0, identified as a bypass for the previously addressed CVE-2023-6909. The vulnerability arises from the application's handling of artifact URLs, where a '#' character can be used to insert a path into the fragment, effectively skipping validation. This allows an attacker to construct a URL that, when processed, ignores the protocol scheme and uses the provided path for filesystem access. As a result, an attacker can read arbitra",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2024-3848 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-3848 (MLflow)",
   "NVDの説明（英語原文）: A path traversal vulnerability exists in mlflow/mlflow version 2.11.0, identified as a bypass for the previously addressed CVE-2023-6909. The vulnerability arises from the application's handling of artifact URLs, where a '#' character can be used to insert a path into the fragment, effectively skipping validation. This allows an attacker to construct a URL that, when processed, ignores the protocol scheme and uses the provided path for filesystem access. As a result, an attacker can read arbitra",
   "MLflow を CVE-2024-3848 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-3848 (MLflow)",
   "NVD 설명(영어 원문): A path traversal vulnerability exists in mlflow/mlflow version 2.11.0, identified as a bypass for the previously addressed CVE-2023-6909. The vulnerability arises from the application's handling of artifact URLs, where a '#' character can be used to insert a path into the fragment, effectively skipping validation. This allows an attacker to construct a URL that, when processed, ignores the protocol scheme and uses the provided path for filesystem access. As a result, an attacker can read arbitra",
   "MLflow을(를) CVE-2024-3848의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-3848 (MLflow)",
   "Descrição do NVD (texto original em inglês): A path traversal vulnerability exists in mlflow/mlflow version 2.11.0, identified as a bypass for the previously addressed CVE-2023-6909. The vulnerability arises from the application's handling of artifact URLs, where a '#' character can be used to insert a path into the fragment, effectively skipping validation. This allows an attacker to construct a URL that, when processed, ignores the protocol scheme and uses the provided path for filesystem access. As a result, an attacker can read arbitra",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2024-3848 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-3848（MLflow）",
   "NVD 说明（英文原文）：A path traversal vulnerability exists in mlflow/mlflow version 2.11.0, identified as a bypass for the previously addressed CVE-2023-6909. The vulnerability arises from the application's handling of artifact URLs, where a '#' character can be used to insert a path into the fragment, effectively skipping validation. This allows an attacker to construct a URL that, when processed, ignores the protocol scheme and uses the provided path for filesystem access. As a result, an attacker can read arbitra",
   "请尽快将 MLflow 升级到不受 CVE-2024-3848 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-3848（MLflow）",
   "NVD 說明（英文原文）：A path traversal vulnerability exists in mlflow/mlflow version 2.11.0, identified as a bypass for the previously addressed CVE-2023-6909. The vulnerability arises from the application's handling of artifact URLs, where a '#' character can be used to insert a path into the fragment, effectively skipping validation. This allows an attacker to construct a URL that, when processed, ignores the protocol scheme and uses the provided path for filesystem access. As a result, an attacker can read arbitra",
   "請儘快將 MLflow 升級到不受 CVE-2024-3848 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2024-8859": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-8859 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): A path traversal vulnerability exists in mlflow/mlflow version 2.15.1. When users configure and use the dbfs service, concatenating the URL directly into the file protocol results in an arbitrary file read vulnerability. This issue occurs because only the path part of the URL is checked, while parts such as query and parameters are not handled. The vulnerability is triggered if the user has configured the dbfs service, and during usage, the service is mounted to a local directory.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2024-8859 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-8859 (MLflow)",
   "A path traversal vulnerability exists in mlflow/mlflow version 2.15.1. When users configure and use the dbfs service, concatenating the URL directly into the file protocol results in an arbitrary file read vulnerability. This issue occurs because only the path part of the URL is checked, while parts such as query and parameters are not handled. The vulnerability is triggered if the user has configured the dbfs service, and during usage, the service is mounted to a local directory.",
   "Upgrade MLflow to a version not affected by CVE-2024-8859 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-8859 (MLflow)",
   "Descripción de NVD (texto original en inglés): A path traversal vulnerability exists in mlflow/mlflow version 2.15.1. When users configure and use the dbfs service, concatenating the URL directly into the file protocol results in an arbitrary file read vulnerability. This issue occurs because only the path part of the URL is checked, while parts such as query and parameters are not handled. The vulnerability is triggered if the user has configured the dbfs service, and during usage, the service is mounted to a local directory.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2024-8859 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-8859 (MLflow)",
   "Description NVD (texte original en anglais) : A path traversal vulnerability exists in mlflow/mlflow version 2.15.1. When users configure and use the dbfs service, concatenating the URL directly into the file protocol results in an arbitrary file read vulnerability. This issue occurs because only the path part of the URL is checked, while parts such as query and parameters are not handled. The vulnerability is triggered if the user has configured the dbfs service, and during usage, the service is mounted to a local directory.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2024-8859 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-8859 (MLflow)",
   "Descrizione NVD (testo originale in inglese): A path traversal vulnerability exists in mlflow/mlflow version 2.15.1. When users configure and use the dbfs service, concatenating the URL directly into the file protocol results in an arbitrary file read vulnerability. This issue occurs because only the path part of the URL is checked, while parts such as query and parameters are not handled. The vulnerability is triggered if the user has configured the dbfs service, and during usage, the service is mounted to a local directory.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2024-8859 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-8859 (MLflow)",
   "NVDの説明（英語原文）: A path traversal vulnerability exists in mlflow/mlflow version 2.15.1. When users configure and use the dbfs service, concatenating the URL directly into the file protocol results in an arbitrary file read vulnerability. This issue occurs because only the path part of the URL is checked, while parts such as query and parameters are not handled. The vulnerability is triggered if the user has configured the dbfs service, and during usage, the service is mounted to a local directory.",
   "MLflow を CVE-2024-8859 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-8859 (MLflow)",
   "NVD 설명(영어 원문): A path traversal vulnerability exists in mlflow/mlflow version 2.15.1. When users configure and use the dbfs service, concatenating the URL directly into the file protocol results in an arbitrary file read vulnerability. This issue occurs because only the path part of the URL is checked, while parts such as query and parameters are not handled. The vulnerability is triggered if the user has configured the dbfs service, and during usage, the service is mounted to a local directory.",
   "MLflow을(를) CVE-2024-8859의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-8859 (MLflow)",
   "Descrição do NVD (texto original em inglês): A path traversal vulnerability exists in mlflow/mlflow version 2.15.1. When users configure and use the dbfs service, concatenating the URL directly into the file protocol results in an arbitrary file read vulnerability. This issue occurs because only the path part of the URL is checked, while parts such as query and parameters are not handled. The vulnerability is triggered if the user has configured the dbfs service, and during usage, the service is mounted to a local directory.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2024-8859 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-8859（MLflow）",
   "NVD 说明（英文原文）：A path traversal vulnerability exists in mlflow/mlflow version 2.15.1. When users configure and use the dbfs service, concatenating the URL directly into the file protocol results in an arbitrary file read vulnerability. This issue occurs because only the path part of the URL is checked, while parts such as query and parameters are not handled. The vulnerability is triggered if the user has configured the dbfs service, and during usage, the service is mounted to a local directory.",
   "请尽快将 MLflow 升级到不受 CVE-2024-8859 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-8859（MLflow）",
   "NVD 說明（英文原文）：A path traversal vulnerability exists in mlflow/mlflow version 2.15.1. When users configure and use the dbfs service, concatenating the URL directly into the file protocol results in an arbitrary file read vulnerability. This issue occurs because only the path part of the URL is checked, while parts such as query and parameters are not handled. The vulnerability is triggered if the user has configured the dbfs service, and during usage, the service is mounted to a local directory.",
   "請儘快將 MLflow 升級到不受 CVE-2024-8859 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2025-0453": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-0453 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): In mlflow/mlflow version 2.17.2, the `/graphql` endpoint is vulnerable to a denial of service attack. An attacker can create large batches of queries that repeatedly request all runs from a given experiment. This can tie up all the workers allocated by MLFlow, rendering the application unable to respond to other requests. This vulnerability is due to uncontrolled resource consumption.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2025-0453 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-0453 (MLflow)",
   "In mlflow/mlflow version 2.17.2, the `/graphql` endpoint is vulnerable to a denial of service attack. An attacker can create large batches of queries that repeatedly request all runs from a given experiment. This can tie up all the workers allocated by MLFlow, rendering the application unable to respond to other requests. This vulnerability is due to uncontrolled resource consumption.",
   "Upgrade MLflow to a version not affected by CVE-2025-0453 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-0453 (MLflow)",
   "Descripción de NVD (texto original en inglés): In mlflow/mlflow version 2.17.2, the `/graphql` endpoint is vulnerable to a denial of service attack. An attacker can create large batches of queries that repeatedly request all runs from a given experiment. This can tie up all the workers allocated by MLFlow, rendering the application unable to respond to other requests. This vulnerability is due to uncontrolled resource consumption.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2025-0453 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-0453 (MLflow)",
   "Description NVD (texte original en anglais) : In mlflow/mlflow version 2.17.2, the `/graphql` endpoint is vulnerable to a denial of service attack. An attacker can create large batches of queries that repeatedly request all runs from a given experiment. This can tie up all the workers allocated by MLFlow, rendering the application unable to respond to other requests. This vulnerability is due to uncontrolled resource consumption.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2025-0453 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-0453 (MLflow)",
   "Descrizione NVD (testo originale in inglese): In mlflow/mlflow version 2.17.2, the `/graphql` endpoint is vulnerable to a denial of service attack. An attacker can create large batches of queries that repeatedly request all runs from a given experiment. This can tie up all the workers allocated by MLFlow, rendering the application unable to respond to other requests. This vulnerability is due to uncontrolled resource consumption.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2025-0453 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-0453 (MLflow)",
   "NVDの説明（英語原文）: In mlflow/mlflow version 2.17.2, the `/graphql` endpoint is vulnerable to a denial of service attack. An attacker can create large batches of queries that repeatedly request all runs from a given experiment. This can tie up all the workers allocated by MLFlow, rendering the application unable to respond to other requests. This vulnerability is due to uncontrolled resource consumption.",
   "MLflow を CVE-2025-0453 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-0453 (MLflow)",
   "NVD 설명(영어 원문): In mlflow/mlflow version 2.17.2, the `/graphql` endpoint is vulnerable to a denial of service attack. An attacker can create large batches of queries that repeatedly request all runs from a given experiment. This can tie up all the workers allocated by MLFlow, rendering the application unable to respond to other requests. This vulnerability is due to uncontrolled resource consumption.",
   "MLflow을(를) CVE-2025-0453의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-0453 (MLflow)",
   "Descrição do NVD (texto original em inglês): In mlflow/mlflow version 2.17.2, the `/graphql` endpoint is vulnerable to a denial of service attack. An attacker can create large batches of queries that repeatedly request all runs from a given experiment. This can tie up all the workers allocated by MLFlow, rendering the application unable to respond to other requests. This vulnerability is due to uncontrolled resource consumption.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2025-0453 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-0453（MLflow）",
   "NVD 说明（英文原文）：In mlflow/mlflow version 2.17.2, the `/graphql` endpoint is vulnerable to a denial of service attack. An attacker can create large batches of queries that repeatedly request all runs from a given experiment. This can tie up all the workers allocated by MLFlow, rendering the application unable to respond to other requests. This vulnerability is due to uncontrolled resource consumption.",
   "请尽快将 MLflow 升级到不受 CVE-2025-0453 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-0453（MLflow）",
   "NVD 說明（英文原文）：In mlflow/mlflow version 2.17.2, the `/graphql` endpoint is vulnerable to a denial of service attack. An attacker can create large batches of queries that repeatedly request all runs from a given experiment. This can tie up all the workers allocated by MLFlow, rendering the application unable to respond to other requests. This vulnerability is due to uncontrolled resource consumption.",
   "請儘快將 MLflow 升級到不受 CVE-2025-0453 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2025-10279": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-10279 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): In mlflow version 2.20.3, the temporary directory used for creating Python virtual environments is assigned insecure world-writable permissions (0o777). This vulnerability allows an attacker with write access to the `/tmp` directory to exploit a race condition and overwrite `.py` files in the virtual environment, leading to arbitrary code execution. The issue is resolved in version 3.4.0.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2025-10279 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-10279 (MLflow)",
   "In mlflow version 2.20.3, the temporary directory used for creating Python virtual environments is assigned insecure world-writable permissions (0o777). This vulnerability allows an attacker with write access to the `/tmp` directory to exploit a race condition and overwrite `.py` files in the virtual environment, leading to arbitrary code execution. The issue is resolved in version 3.4.0.",
   "Upgrade MLflow to a version not affected by CVE-2025-10279 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-10279 (MLflow)",
   "Descripción de NVD (texto original en inglés): In mlflow version 2.20.3, the temporary directory used for creating Python virtual environments is assigned insecure world-writable permissions (0o777). This vulnerability allows an attacker with write access to the `/tmp` directory to exploit a race condition and overwrite `.py` files in the virtual environment, leading to arbitrary code execution. The issue is resolved in version 3.4.0.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2025-10279 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-10279 (MLflow)",
   "Description NVD (texte original en anglais) : In mlflow version 2.20.3, the temporary directory used for creating Python virtual environments is assigned insecure world-writable permissions (0o777). This vulnerability allows an attacker with write access to the `/tmp` directory to exploit a race condition and overwrite `.py` files in the virtual environment, leading to arbitrary code execution. The issue is resolved in version 3.4.0.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2025-10279 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-10279 (MLflow)",
   "Descrizione NVD (testo originale in inglese): In mlflow version 2.20.3, the temporary directory used for creating Python virtual environments is assigned insecure world-writable permissions (0o777). This vulnerability allows an attacker with write access to the `/tmp` directory to exploit a race condition and overwrite `.py` files in the virtual environment, leading to arbitrary code execution. The issue is resolved in version 3.4.0.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2025-10279 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-10279 (MLflow)",
   "NVDの説明（英語原文）: In mlflow version 2.20.3, the temporary directory used for creating Python virtual environments is assigned insecure world-writable permissions (0o777). This vulnerability allows an attacker with write access to the `/tmp` directory to exploit a race condition and overwrite `.py` files in the virtual environment, leading to arbitrary code execution. The issue is resolved in version 3.4.0.",
   "MLflow を CVE-2025-10279 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-10279 (MLflow)",
   "NVD 설명(영어 원문): In mlflow version 2.20.3, the temporary directory used for creating Python virtual environments is assigned insecure world-writable permissions (0o777). This vulnerability allows an attacker with write access to the `/tmp` directory to exploit a race condition and overwrite `.py` files in the virtual environment, leading to arbitrary code execution. The issue is resolved in version 3.4.0.",
   "MLflow을(를) CVE-2025-10279의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-10279 (MLflow)",
   "Descrição do NVD (texto original em inglês): In mlflow version 2.20.3, the temporary directory used for creating Python virtual environments is assigned insecure world-writable permissions (0o777). This vulnerability allows an attacker with write access to the `/tmp` directory to exploit a race condition and overwrite `.py` files in the virtual environment, leading to arbitrary code execution. The issue is resolved in version 3.4.0.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2025-10279 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-10279（MLflow）",
   "NVD 说明（英文原文）：In mlflow version 2.20.3, the temporary directory used for creating Python virtual environments is assigned insecure world-writable permissions (0o777). This vulnerability allows an attacker with write access to the `/tmp` directory to exploit a race condition and overwrite `.py` files in the virtual environment, leading to arbitrary code execution. The issue is resolved in version 3.4.0.",
   "请尽快将 MLflow 升级到不受 CVE-2025-10279 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-10279（MLflow）",
   "NVD 說明（英文原文）：In mlflow version 2.20.3, the temporary directory used for creating Python virtual environments is assigned insecure world-writable permissions (0o777). This vulnerability allows an attacker with write access to the `/tmp` directory to exploit a race condition and overwrite `.py` files in the virtual environment, leading to arbitrary code execution. The issue is resolved in version 3.4.0.",
   "請儘快將 MLflow 升級到不受 CVE-2025-10279 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2025-11200": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-11200 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): MLflow Weak Password Requirements Authentication Bypass Vulnerability. This vulnerability allows remote attackers to bypass authentication on affected installations of MLflow. Authentication is not required to exploit this vulnerability.\n\nThe specific flaw exists within the handling of passwords. The issue results from weak password requirements. An attacker can leverage this vulnerability to bypass authentication on the system. Was ZDI-CAN-26916.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2025-11200 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-11200 (MLflow)",
   "MLflow Weak Password Requirements Authentication Bypass Vulnerability. This vulnerability allows remote attackers to bypass authentication on affected installations of MLflow. Authentication is not required to exploit this vulnerability.\n\nThe specific flaw exists within the handling of passwords. The issue results from weak password requirements. An attacker can leverage this vulnerability to bypass authentication on the system. Was ZDI-CAN-26916.",
   "Upgrade MLflow to a version not affected by CVE-2025-11200 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-11200 (MLflow)",
   "Descripción de NVD (texto original en inglés): MLflow Weak Password Requirements Authentication Bypass Vulnerability. This vulnerability allows remote attackers to bypass authentication on affected installations of MLflow. Authentication is not required to exploit this vulnerability.\n\nThe specific flaw exists within the handling of passwords. The issue results from weak password requirements. An attacker can leverage this vulnerability to bypass authentication on the system. Was ZDI-CAN-26916.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2025-11200 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-11200 (MLflow)",
   "Description NVD (texte original en anglais) : MLflow Weak Password Requirements Authentication Bypass Vulnerability. This vulnerability allows remote attackers to bypass authentication on affected installations of MLflow. Authentication is not required to exploit this vulnerability.\n\nThe specific flaw exists within the handling of passwords. The issue results from weak password requirements. An attacker can leverage this vulnerability to bypass authentication on the system. Was ZDI-CAN-26916.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2025-11200 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-11200 (MLflow)",
   "Descrizione NVD (testo originale in inglese): MLflow Weak Password Requirements Authentication Bypass Vulnerability. This vulnerability allows remote attackers to bypass authentication on affected installations of MLflow. Authentication is not required to exploit this vulnerability.\n\nThe specific flaw exists within the handling of passwords. The issue results from weak password requirements. An attacker can leverage this vulnerability to bypass authentication on the system. Was ZDI-CAN-26916.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2025-11200 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-11200 (MLflow)",
   "NVDの説明（英語原文）: MLflow Weak Password Requirements Authentication Bypass Vulnerability. This vulnerability allows remote attackers to bypass authentication on affected installations of MLflow. Authentication is not required to exploit this vulnerability.\n\nThe specific flaw exists within the handling of passwords. The issue results from weak password requirements. An attacker can leverage this vulnerability to bypass authentication on the system. Was ZDI-CAN-26916.",
   "MLflow を CVE-2025-11200 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-11200 (MLflow)",
   "NVD 설명(영어 원문): MLflow Weak Password Requirements Authentication Bypass Vulnerability. This vulnerability allows remote attackers to bypass authentication on affected installations of MLflow. Authentication is not required to exploit this vulnerability.\n\nThe specific flaw exists within the handling of passwords. The issue results from weak password requirements. An attacker can leverage this vulnerability to bypass authentication on the system. Was ZDI-CAN-26916.",
   "MLflow을(를) CVE-2025-11200의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-11200 (MLflow)",
   "Descrição do NVD (texto original em inglês): MLflow Weak Password Requirements Authentication Bypass Vulnerability. This vulnerability allows remote attackers to bypass authentication on affected installations of MLflow. Authentication is not required to exploit this vulnerability.\n\nThe specific flaw exists within the handling of passwords. The issue results from weak password requirements. An attacker can leverage this vulnerability to bypass authentication on the system. Was ZDI-CAN-26916.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2025-11200 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-11200（MLflow）",
   "NVD 说明（英文原文）：MLflow Weak Password Requirements Authentication Bypass Vulnerability. This vulnerability allows remote attackers to bypass authentication on affected installations of MLflow. Authentication is not required to exploit this vulnerability.\n\nThe specific flaw exists within the handling of passwords. The issue results from weak password requirements. An attacker can leverage this vulnerability to bypass authentication on the system. Was ZDI-CAN-26916.",
   "请尽快将 MLflow 升级到不受 CVE-2025-11200 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-11200（MLflow）",
   "NVD 說明（英文原文）：MLflow Weak Password Requirements Authentication Bypass Vulnerability. This vulnerability allows remote attackers to bypass authentication on affected installations of MLflow. Authentication is not required to exploit this vulnerability.\n\nThe specific flaw exists within the handling of passwords. The issue results from weak password requirements. An attacker can leverage this vulnerability to bypass authentication on the system. Was ZDI-CAN-26916.",
   "請儘快將 MLflow 升級到不受 CVE-2025-11200 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2025-14279": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-14279 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): MLFlow versions up to and including 3.4.0 are vulnerable to DNS rebinding attacks due to a lack of Origin header validation in the MLFlow REST server. This vulnerability allows malicious websites to bypass Same-Origin Policy protections and execute unauthorized calls against REST endpoints. An attacker can query, update, and delete experiments via the affected endpoints, leading to potential data exfiltration, destruction, or manipulation. The issue is resolved in version 3.5.0.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2025-14279 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-14279 (MLflow)",
   "MLFlow versions up to and including 3.4.0 are vulnerable to DNS rebinding attacks due to a lack of Origin header validation in the MLFlow REST server. This vulnerability allows malicious websites to bypass Same-Origin Policy protections and execute unauthorized calls against REST endpoints. An attacker can query, update, and delete experiments via the affected endpoints, leading to potential data exfiltration, destruction, or manipulation. The issue is resolved in version 3.5.0.",
   "Upgrade MLflow to a version not affected by CVE-2025-14279 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-14279 (MLflow)",
   "Descripción de NVD (texto original en inglés): MLFlow versions up to and including 3.4.0 are vulnerable to DNS rebinding attacks due to a lack of Origin header validation in the MLFlow REST server. This vulnerability allows malicious websites to bypass Same-Origin Policy protections and execute unauthorized calls against REST endpoints. An attacker can query, update, and delete experiments via the affected endpoints, leading to potential data exfiltration, destruction, or manipulation. The issue is resolved in version 3.5.0.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2025-14279 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-14279 (MLflow)",
   "Description NVD (texte original en anglais) : MLFlow versions up to and including 3.4.0 are vulnerable to DNS rebinding attacks due to a lack of Origin header validation in the MLFlow REST server. This vulnerability allows malicious websites to bypass Same-Origin Policy protections and execute unauthorized calls against REST endpoints. An attacker can query, update, and delete experiments via the affected endpoints, leading to potential data exfiltration, destruction, or manipulation. The issue is resolved in version 3.5.0.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2025-14279 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-14279 (MLflow)",
   "Descrizione NVD (testo originale in inglese): MLFlow versions up to and including 3.4.0 are vulnerable to DNS rebinding attacks due to a lack of Origin header validation in the MLFlow REST server. This vulnerability allows malicious websites to bypass Same-Origin Policy protections and execute unauthorized calls against REST endpoints. An attacker can query, update, and delete experiments via the affected endpoints, leading to potential data exfiltration, destruction, or manipulation. The issue is resolved in version 3.5.0.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2025-14279 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-14279 (MLflow)",
   "NVDの説明（英語原文）: MLFlow versions up to and including 3.4.0 are vulnerable to DNS rebinding attacks due to a lack of Origin header validation in the MLFlow REST server. This vulnerability allows malicious websites to bypass Same-Origin Policy protections and execute unauthorized calls against REST endpoints. An attacker can query, update, and delete experiments via the affected endpoints, leading to potential data exfiltration, destruction, or manipulation. The issue is resolved in version 3.5.0.",
   "MLflow を CVE-2025-14279 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-14279 (MLflow)",
   "NVD 설명(영어 원문): MLFlow versions up to and including 3.4.0 are vulnerable to DNS rebinding attacks due to a lack of Origin header validation in the MLFlow REST server. This vulnerability allows malicious websites to bypass Same-Origin Policy protections and execute unauthorized calls against REST endpoints. An attacker can query, update, and delete experiments via the affected endpoints, leading to potential data exfiltration, destruction, or manipulation. The issue is resolved in version 3.5.0.",
   "MLflow을(를) CVE-2025-14279의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-14279 (MLflow)",
   "Descrição do NVD (texto original em inglês): MLFlow versions up to and including 3.4.0 are vulnerable to DNS rebinding attacks due to a lack of Origin header validation in the MLFlow REST server. This vulnerability allows malicious websites to bypass Same-Origin Policy protections and execute unauthorized calls against REST endpoints. An attacker can query, update, and delete experiments via the affected endpoints, leading to potential data exfiltration, destruction, or manipulation. The issue is resolved in version 3.5.0.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2025-14279 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-14279（MLflow）",
   "NVD 说明（英文原文）：MLFlow versions up to and including 3.4.0 are vulnerable to DNS rebinding attacks due to a lack of Origin header validation in the MLFlow REST server. This vulnerability allows malicious websites to bypass Same-Origin Policy protections and execute unauthorized calls against REST endpoints. An attacker can query, update, and delete experiments via the affected endpoints, leading to potential data exfiltration, destruction, or manipulation. The issue is resolved in version 3.5.0.",
   "请尽快将 MLflow 升级到不受 CVE-2025-14279 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-14279（MLflow）",
   "NVD 說明（英文原文）：MLFlow versions up to and including 3.4.0 are vulnerable to DNS rebinding attacks due to a lack of Origin header validation in the MLFlow REST server. This vulnerability allows malicious websites to bypass Same-Origin Policy protections and execute unauthorized calls against REST endpoints. An attacker can query, update, and delete experiments via the affected endpoints, leading to potential data exfiltration, destruction, or manipulation. The issue is resolved in version 3.5.0.",
   "請儘快將 MLflow 升級到不受 CVE-2025-14279 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2025-14287": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-14287 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): A command injection vulnerability exists in mlflow/mlflow versions before v3.7.0, specifically in the `mlflow/sagemaker/__init__.py` file at lines 161-167. The vulnerability arises from the direct interpolation of user-supplied container image names into shell commands without proper sanitization, which are then executed using `os.system()`. This allows attackers to execute arbitrary commands by supplying malicious input through the `--container` parameter of the CLI. The issue affects environme",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2025-14287 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-14287 (MLflow)",
   "A command injection vulnerability exists in mlflow/mlflow versions before v3.7.0, specifically in the `mlflow/sagemaker/__init__.py` file at lines 161-167. The vulnerability arises from the direct interpolation of user-supplied container image names into shell commands without proper sanitization, which are then executed using `os.system()`. This allows attackers to execute arbitrary commands by supplying malicious input through the `--container` parameter of the CLI. The issue affects environme",
   "Upgrade MLflow to a version not affected by CVE-2025-14287 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-14287 (MLflow)",
   "Descripción de NVD (texto original en inglés): A command injection vulnerability exists in mlflow/mlflow versions before v3.7.0, specifically in the `mlflow/sagemaker/__init__.py` file at lines 161-167. The vulnerability arises from the direct interpolation of user-supplied container image names into shell commands without proper sanitization, which are then executed using `os.system()`. This allows attackers to execute arbitrary commands by supplying malicious input through the `--container` parameter of the CLI. The issue affects environme",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2025-14287 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-14287 (MLflow)",
   "Description NVD (texte original en anglais) : A command injection vulnerability exists in mlflow/mlflow versions before v3.7.0, specifically in the `mlflow/sagemaker/__init__.py` file at lines 161-167. The vulnerability arises from the direct interpolation of user-supplied container image names into shell commands without proper sanitization, which are then executed using `os.system()`. This allows attackers to execute arbitrary commands by supplying malicious input through the `--container` parameter of the CLI. The issue affects environme",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2025-14287 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-14287 (MLflow)",
   "Descrizione NVD (testo originale in inglese): A command injection vulnerability exists in mlflow/mlflow versions before v3.7.0, specifically in the `mlflow/sagemaker/__init__.py` file at lines 161-167. The vulnerability arises from the direct interpolation of user-supplied container image names into shell commands without proper sanitization, which are then executed using `os.system()`. This allows attackers to execute arbitrary commands by supplying malicious input through the `--container` parameter of the CLI. The issue affects environme",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2025-14287 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-14287 (MLflow)",
   "NVDの説明（英語原文）: A command injection vulnerability exists in mlflow/mlflow versions before v3.7.0, specifically in the `mlflow/sagemaker/__init__.py` file at lines 161-167. The vulnerability arises from the direct interpolation of user-supplied container image names into shell commands without proper sanitization, which are then executed using `os.system()`. This allows attackers to execute arbitrary commands by supplying malicious input through the `--container` parameter of the CLI. The issue affects environme",
   "MLflow を CVE-2025-14287 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-14287 (MLflow)",
   "NVD 설명(영어 원문): A command injection vulnerability exists in mlflow/mlflow versions before v3.7.0, specifically in the `mlflow/sagemaker/__init__.py` file at lines 161-167. The vulnerability arises from the direct interpolation of user-supplied container image names into shell commands without proper sanitization, which are then executed using `os.system()`. This allows attackers to execute arbitrary commands by supplying malicious input through the `--container` parameter of the CLI. The issue affects environme",
   "MLflow을(를) CVE-2025-14287의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-14287 (MLflow)",
   "Descrição do NVD (texto original em inglês): A command injection vulnerability exists in mlflow/mlflow versions before v3.7.0, specifically in the `mlflow/sagemaker/__init__.py` file at lines 161-167. The vulnerability arises from the direct interpolation of user-supplied container image names into shell commands without proper sanitization, which are then executed using `os.system()`. This allows attackers to execute arbitrary commands by supplying malicious input through the `--container` parameter of the CLI. The issue affects environme",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2025-14287 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-14287（MLflow）",
   "NVD 说明（英文原文）：A command injection vulnerability exists in mlflow/mlflow versions before v3.7.0, specifically in the `mlflow/sagemaker/__init__.py` file at lines 161-167. The vulnerability arises from the direct interpolation of user-supplied container image names into shell commands without proper sanitization, which are then executed using `os.system()`. This allows attackers to execute arbitrary commands by supplying malicious input through the `--container` parameter of the CLI. The issue affects environme",
   "请尽快将 MLflow 升级到不受 CVE-2025-14287 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-14287（MLflow）",
   "NVD 說明（英文原文）：A command injection vulnerability exists in mlflow/mlflow versions before v3.7.0, specifically in the `mlflow/sagemaker/__init__.py` file at lines 161-167. The vulnerability arises from the direct interpolation of user-supplied container image names into shell commands without proper sanitization, which are then executed using `os.system()`. This allows attackers to execute arbitrary commands by supplying malicious input through the `--container` parameter of the CLI. The issue affects environme",
   "請儘快將 MLflow 升級到不受 CVE-2025-14287 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2025-1473": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-1473 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): A Cross-Site Request Forgery (CSRF) vulnerability exists in the Signup feature of mlflow/mlflow versions 2.17.0 to 2.20.1. This vulnerability allows an attacker to create a new account, which may be used to perform unauthorized actions on behalf of the malicious user.",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2025-1473 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-1473 (MLflow)",
   "A Cross-Site Request Forgery (CSRF) vulnerability exists in the Signup feature of mlflow/mlflow versions 2.17.0 to 2.20.1. This vulnerability allows an attacker to create a new account, which may be used to perform unauthorized actions on behalf of the malicious user.",
   "Upgrade MLflow to a version not affected by CVE-2025-1473 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-1473 (MLflow)",
   "Descripción de NVD (texto original en inglés): A Cross-Site Request Forgery (CSRF) vulnerability exists in the Signup feature of mlflow/mlflow versions 2.17.0 to 2.20.1. This vulnerability allows an attacker to create a new account, which may be used to perform unauthorized actions on behalf of the malicious user.",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2025-1473 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-1473 (MLflow)",
   "Description NVD (texte original en anglais) : A Cross-Site Request Forgery (CSRF) vulnerability exists in the Signup feature of mlflow/mlflow versions 2.17.0 to 2.20.1. This vulnerability allows an attacker to create a new account, which may be used to perform unauthorized actions on behalf of the malicious user.",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2025-1473 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-1473 (MLflow)",
   "Descrizione NVD (testo originale in inglese): A Cross-Site Request Forgery (CSRF) vulnerability exists in the Signup feature of mlflow/mlflow versions 2.17.0 to 2.20.1. This vulnerability allows an attacker to create a new account, which may be used to perform unauthorized actions on behalf of the malicious user.",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2025-1473 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-1473 (MLflow)",
   "NVDの説明（英語原文）: A Cross-Site Request Forgery (CSRF) vulnerability exists in the Signup feature of mlflow/mlflow versions 2.17.0 to 2.20.1. This vulnerability allows an attacker to create a new account, which may be used to perform unauthorized actions on behalf of the malicious user.",
   "MLflow を CVE-2025-1473 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-1473 (MLflow)",
   "NVD 설명(영어 원문): A Cross-Site Request Forgery (CSRF) vulnerability exists in the Signup feature of mlflow/mlflow versions 2.17.0 to 2.20.1. This vulnerability allows an attacker to create a new account, which may be used to perform unauthorized actions on behalf of the malicious user.",
   "MLflow을(를) CVE-2025-1473의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-1473 (MLflow)",
   "Descrição do NVD (texto original em inglês): A Cross-Site Request Forgery (CSRF) vulnerability exists in the Signup feature of mlflow/mlflow versions 2.17.0 to 2.20.1. This vulnerability allows an attacker to create a new account, which may be used to perform unauthorized actions on behalf of the malicious user.",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2025-1473 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-1473（MLflow）",
   "NVD 说明（英文原文）：A Cross-Site Request Forgery (CSRF) vulnerability exists in the Signup feature of mlflow/mlflow versions 2.17.0 to 2.20.1. This vulnerability allows an attacker to create a new account, which may be used to perform unauthorized actions on behalf of the malicious user.",
   "请尽快将 MLflow 升级到不受 CVE-2025-1473 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-1473（MLflow）",
   "NVD 說明（英文原文）：A Cross-Site Request Forgery (CSRF) vulnerability exists in the Signup feature of mlflow/mlflow versions 2.17.0 to 2.20.1. This vulnerability allows an attacker to create a new account, which may be used to perform unauthorized actions on behalf of the malicious user.",
   "請儘快將 MLflow 升級到不受 CVE-2025-1473 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2025-15031": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-15031 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): A vulnerability in MLflow's pyfunc extraction process allows for arbitrary file writes due to improper handling of tar archive entries. Specifically, the use of `tarfile.extractall` without path validation enables crafted tar.gz files containing `..` or absolute paths to escape the intended extraction directory. This issue affects the latest version of MLflow and poses a high/critical risk in scenarios involving multi-tenant environments or ingestion of untrusted artifacts, as it can lead to arb",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2025-15031 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-15031 (MLflow)",
   "A vulnerability in MLflow's pyfunc extraction process allows for arbitrary file writes due to improper handling of tar archive entries. Specifically, the use of `tarfile.extractall` without path validation enables crafted tar.gz files containing `..` or absolute paths to escape the intended extraction directory. This issue affects the latest version of MLflow and poses a high/critical risk in scenarios involving multi-tenant environments or ingestion of untrusted artifacts, as it can lead to arb",
   "Upgrade MLflow to a version not affected by CVE-2025-15031 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-15031 (MLflow)",
   "Descripción de NVD (texto original en inglés): A vulnerability in MLflow's pyfunc extraction process allows for arbitrary file writes due to improper handling of tar archive entries. Specifically, the use of `tarfile.extractall` without path validation enables crafted tar.gz files containing `..` or absolute paths to escape the intended extraction directory. This issue affects the latest version of MLflow and poses a high/critical risk in scenarios involving multi-tenant environments or ingestion of untrusted artifacts, as it can lead to arb",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2025-15031 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-15031 (MLflow)",
   "Description NVD (texte original en anglais) : A vulnerability in MLflow's pyfunc extraction process allows for arbitrary file writes due to improper handling of tar archive entries. Specifically, the use of `tarfile.extractall` without path validation enables crafted tar.gz files containing `..` or absolute paths to escape the intended extraction directory. This issue affects the latest version of MLflow and poses a high/critical risk in scenarios involving multi-tenant environments or ingestion of untrusted artifacts, as it can lead to arb",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2025-15031 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-15031 (MLflow)",
   "Descrizione NVD (testo originale in inglese): A vulnerability in MLflow's pyfunc extraction process allows for arbitrary file writes due to improper handling of tar archive entries. Specifically, the use of `tarfile.extractall` without path validation enables crafted tar.gz files containing `..` or absolute paths to escape the intended extraction directory. This issue affects the latest version of MLflow and poses a high/critical risk in scenarios involving multi-tenant environments or ingestion of untrusted artifacts, as it can lead to arb",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2025-15031 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-15031 (MLflow)",
   "NVDの説明（英語原文）: A vulnerability in MLflow's pyfunc extraction process allows for arbitrary file writes due to improper handling of tar archive entries. Specifically, the use of `tarfile.extractall` without path validation enables crafted tar.gz files containing `..` or absolute paths to escape the intended extraction directory. This issue affects the latest version of MLflow and poses a high/critical risk in scenarios involving multi-tenant environments or ingestion of untrusted artifacts, as it can lead to arb",
   "MLflow を CVE-2025-15031 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-15031 (MLflow)",
   "NVD 설명(영어 원문): A vulnerability in MLflow's pyfunc extraction process allows for arbitrary file writes due to improper handling of tar archive entries. Specifically, the use of `tarfile.extractall` without path validation enables crafted tar.gz files containing `..` or absolute paths to escape the intended extraction directory. This issue affects the latest version of MLflow and poses a high/critical risk in scenarios involving multi-tenant environments or ingestion of untrusted artifacts, as it can lead to arb",
   "MLflow을(를) CVE-2025-15031의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-15031 (MLflow)",
   "Descrição do NVD (texto original em inglês): A vulnerability in MLflow's pyfunc extraction process allows for arbitrary file writes due to improper handling of tar archive entries. Specifically, the use of `tarfile.extractall` without path validation enables crafted tar.gz files containing `..` or absolute paths to escape the intended extraction directory. This issue affects the latest version of MLflow and poses a high/critical risk in scenarios involving multi-tenant environments or ingestion of untrusted artifacts, as it can lead to arb",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2025-15031 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-15031（MLflow）",
   "NVD 说明（英文原文）：A vulnerability in MLflow's pyfunc extraction process allows for arbitrary file writes due to improper handling of tar archive entries. Specifically, the use of `tarfile.extractall` without path validation enables crafted tar.gz files containing `..` or absolute paths to escape the intended extraction directory. This issue affects the latest version of MLflow and poses a high/critical risk in scenarios involving multi-tenant environments or ingestion of untrusted artifacts, as it can lead to arb",
   "请尽快将 MLflow 升级到不受 CVE-2025-15031 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-15031（MLflow）",
   "NVD 說明（英文原文）：A vulnerability in MLflow's pyfunc extraction process allows for arbitrary file writes due to improper handling of tar archive entries. Specifically, the use of `tarfile.extractall` without path validation enables crafted tar.gz files containing `..` or absolute paths to escape the intended extraction directory. This issue affects the latest version of MLflow and poses a high/critical risk in scenarios involving multi-tenant environments or ingestion of untrusted artifacts, as it can lead to arb",
   "請儘快將 MLflow 升級到不受 CVE-2025-15031 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2025-15036": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-15036 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): A path traversal vulnerability exists in the `extract_archive_to_dir` function within the `mlflow/pyfunc/dbconnect_artifact_cache.py` file of the mlflow/mlflow repository. This vulnerability, present in versions before v3.7.0, arises due to the lack of validation of tar member paths during extraction. An attacker with control over the tar.gz file can exploit this issue to overwrite arbitrary files or gain elevated privileges, potentially escaping the sandbox directory in multi-tenant or shared c",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2025-15036 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-15036 (MLflow)",
   "A path traversal vulnerability exists in the `extract_archive_to_dir` function within the `mlflow/pyfunc/dbconnect_artifact_cache.py` file of the mlflow/mlflow repository. This vulnerability, present in versions before v3.7.0, arises due to the lack of validation of tar member paths during extraction. An attacker with control over the tar.gz file can exploit this issue to overwrite arbitrary files or gain elevated privileges, potentially escaping the sandbox directory in multi-tenant or shared c",
   "Upgrade MLflow to a version not affected by CVE-2025-15036 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-15036 (MLflow)",
   "Descripción de NVD (texto original en inglés): A path traversal vulnerability exists in the `extract_archive_to_dir` function within the `mlflow/pyfunc/dbconnect_artifact_cache.py` file of the mlflow/mlflow repository. This vulnerability, present in versions before v3.7.0, arises due to the lack of validation of tar member paths during extraction. An attacker with control over the tar.gz file can exploit this issue to overwrite arbitrary files or gain elevated privileges, potentially escaping the sandbox directory in multi-tenant or shared c",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2025-15036 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-15036 (MLflow)",
   "Description NVD (texte original en anglais) : A path traversal vulnerability exists in the `extract_archive_to_dir` function within the `mlflow/pyfunc/dbconnect_artifact_cache.py` file of the mlflow/mlflow repository. This vulnerability, present in versions before v3.7.0, arises due to the lack of validation of tar member paths during extraction. An attacker with control over the tar.gz file can exploit this issue to overwrite arbitrary files or gain elevated privileges, potentially escaping the sandbox directory in multi-tenant or shared c",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2025-15036 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-15036 (MLflow)",
   "Descrizione NVD (testo originale in inglese): A path traversal vulnerability exists in the `extract_archive_to_dir` function within the `mlflow/pyfunc/dbconnect_artifact_cache.py` file of the mlflow/mlflow repository. This vulnerability, present in versions before v3.7.0, arises due to the lack of validation of tar member paths during extraction. An attacker with control over the tar.gz file can exploit this issue to overwrite arbitrary files or gain elevated privileges, potentially escaping the sandbox directory in multi-tenant or shared c",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2025-15036 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-15036 (MLflow)",
   "NVDの説明（英語原文）: A path traversal vulnerability exists in the `extract_archive_to_dir` function within the `mlflow/pyfunc/dbconnect_artifact_cache.py` file of the mlflow/mlflow repository. This vulnerability, present in versions before v3.7.0, arises due to the lack of validation of tar member paths during extraction. An attacker with control over the tar.gz file can exploit this issue to overwrite arbitrary files or gain elevated privileges, potentially escaping the sandbox directory in multi-tenant or shared c",
   "MLflow を CVE-2025-15036 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-15036 (MLflow)",
   "NVD 설명(영어 원문): A path traversal vulnerability exists in the `extract_archive_to_dir` function within the `mlflow/pyfunc/dbconnect_artifact_cache.py` file of the mlflow/mlflow repository. This vulnerability, present in versions before v3.7.0, arises due to the lack of validation of tar member paths during extraction. An attacker with control over the tar.gz file can exploit this issue to overwrite arbitrary files or gain elevated privileges, potentially escaping the sandbox directory in multi-tenant or shared c",
   "MLflow을(를) CVE-2025-15036의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-15036 (MLflow)",
   "Descrição do NVD (texto original em inglês): A path traversal vulnerability exists in the `extract_archive_to_dir` function within the `mlflow/pyfunc/dbconnect_artifact_cache.py` file of the mlflow/mlflow repository. This vulnerability, present in versions before v3.7.0, arises due to the lack of validation of tar member paths during extraction. An attacker with control over the tar.gz file can exploit this issue to overwrite arbitrary files or gain elevated privileges, potentially escaping the sandbox directory in multi-tenant or shared c",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2025-15036 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-15036（MLflow）",
   "NVD 说明（英文原文）：A path traversal vulnerability exists in the `extract_archive_to_dir` function within the `mlflow/pyfunc/dbconnect_artifact_cache.py` file of the mlflow/mlflow repository. This vulnerability, present in versions before v3.7.0, arises due to the lack of validation of tar member paths during extraction. An attacker with control over the tar.gz file can exploit this issue to overwrite arbitrary files or gain elevated privileges, potentially escaping the sandbox directory in multi-tenant or shared c",
   "请尽快将 MLflow 升级到不受 CVE-2025-15036 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-15036（MLflow）",
   "NVD 說明（英文原文）：A path traversal vulnerability exists in the `extract_archive_to_dir` function within the `mlflow/pyfunc/dbconnect_artifact_cache.py` file of the mlflow/mlflow repository. This vulnerability, present in versions before v3.7.0, arises due to the lack of validation of tar member paths during extraction. An attacker with control over the tar.gz file can exploit this issue to overwrite arbitrary files or gain elevated privileges, potentially escaping the sandbox directory in multi-tenant or shared c",
   "請儘快將 MLflow 升級到不受 CVE-2025-15036 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2025-15379": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-15379 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): A command injection vulnerability exists in MLflow's model serving container initialization code, specifically in the `_install_model_dependencies_to_env()` function. When deploying a model with `env_manager=LOCAL`, MLflow reads dependency specifications from the model artifact's `python_env.yaml` file and directly interpolates them into a shell command without sanitization. This allows an attacker to supply a malicious model artifact and achieve arbitrary command execution on systems that deplo",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2025-15379 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-15379 (MLflow)",
   "A command injection vulnerability exists in MLflow's model serving container initialization code, specifically in the `_install_model_dependencies_to_env()` function. When deploying a model with `env_manager=LOCAL`, MLflow reads dependency specifications from the model artifact's `python_env.yaml` file and directly interpolates them into a shell command without sanitization. This allows an attacker to supply a malicious model artifact and achieve arbitrary command execution on systems that deplo",
   "Upgrade MLflow to a version not affected by CVE-2025-15379 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-15379 (MLflow)",
   "Descripción de NVD (texto original en inglés): A command injection vulnerability exists in MLflow's model serving container initialization code, specifically in the `_install_model_dependencies_to_env()` function. When deploying a model with `env_manager=LOCAL`, MLflow reads dependency specifications from the model artifact's `python_env.yaml` file and directly interpolates them into a shell command without sanitization. This allows an attacker to supply a malicious model artifact and achieve arbitrary command execution on systems that deplo",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2025-15379 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-15379 (MLflow)",
   "Description NVD (texte original en anglais) : A command injection vulnerability exists in MLflow's model serving container initialization code, specifically in the `_install_model_dependencies_to_env()` function. When deploying a model with `env_manager=LOCAL`, MLflow reads dependency specifications from the model artifact's `python_env.yaml` file and directly interpolates them into a shell command without sanitization. This allows an attacker to supply a malicious model artifact and achieve arbitrary command execution on systems that deplo",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2025-15379 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-15379 (MLflow)",
   "Descrizione NVD (testo originale in inglese): A command injection vulnerability exists in MLflow's model serving container initialization code, specifically in the `_install_model_dependencies_to_env()` function. When deploying a model with `env_manager=LOCAL`, MLflow reads dependency specifications from the model artifact's `python_env.yaml` file and directly interpolates them into a shell command without sanitization. This allows an attacker to supply a malicious model artifact and achieve arbitrary command execution on systems that deplo",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2025-15379 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-15379 (MLflow)",
   "NVDの説明（英語原文）: A command injection vulnerability exists in MLflow's model serving container initialization code, specifically in the `_install_model_dependencies_to_env()` function. When deploying a model with `env_manager=LOCAL`, MLflow reads dependency specifications from the model artifact's `python_env.yaml` file and directly interpolates them into a shell command without sanitization. This allows an attacker to supply a malicious model artifact and achieve arbitrary command execution on systems that deplo",
   "MLflow を CVE-2025-15379 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-15379 (MLflow)",
   "NVD 설명(영어 원문): A command injection vulnerability exists in MLflow's model serving container initialization code, specifically in the `_install_model_dependencies_to_env()` function. When deploying a model with `env_manager=LOCAL`, MLflow reads dependency specifications from the model artifact's `python_env.yaml` file and directly interpolates them into a shell command without sanitization. This allows an attacker to supply a malicious model artifact and achieve arbitrary command execution on systems that deplo",
   "MLflow을(를) CVE-2025-15379의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-15379 (MLflow)",
   "Descrição do NVD (texto original em inglês): A command injection vulnerability exists in MLflow's model serving container initialization code, specifically in the `_install_model_dependencies_to_env()` function. When deploying a model with `env_manager=LOCAL`, MLflow reads dependency specifications from the model artifact's `python_env.yaml` file and directly interpolates them into a shell command without sanitization. This allows an attacker to supply a malicious model artifact and achieve arbitrary command execution on systems that deplo",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2025-15379 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-15379（MLflow）",
   "NVD 说明（英文原文）：A command injection vulnerability exists in MLflow's model serving container initialization code, specifically in the `_install_model_dependencies_to_env()` function. When deploying a model with `env_manager=LOCAL`, MLflow reads dependency specifications from the model artifact's `python_env.yaml` file and directly interpolates them into a shell command without sanitization. This allows an attacker to supply a malicious model artifact and achieve arbitrary command execution on systems that deplo",
   "请尽快将 MLflow 升级到不受 CVE-2025-15379 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-15379（MLflow）",
   "NVD 說明（英文原文）：A command injection vulnerability exists in MLflow's model serving container initialization code, specifically in the `_install_model_dependencies_to_env()` function. When deploying a model with `env_manager=LOCAL`, MLflow reads dependency specifications from the model artifact's `python_env.yaml` file and directly interpolates them into a shell command without sanitization. This allows an attacker to supply a malicious model artifact and achieve arbitrary command execution on systems that deplo",
   "請儘快將 MLflow 升級到不受 CVE-2025-15379 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2025-15381": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-15381 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): In the latest version of mlflow/mlflow, when the `basic-auth` app is enabled, tracing and assessment endpoints are not protected by permission validators. This allows any authenticated user, including those with `NO_PERMISSIONS` on the experiment, to read trace information and create assessments for traces they should not have access to. This vulnerability impacts confidentiality by exposing trace metadata and integrity by allowing unauthorized creation of assessments. Deployments using `mlflow ",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2025-15381 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-15381 (MLflow)",
   "In the latest version of mlflow/mlflow, when the `basic-auth` app is enabled, tracing and assessment endpoints are not protected by permission validators. This allows any authenticated user, including those with `NO_PERMISSIONS` on the experiment, to read trace information and create assessments for traces they should not have access to. This vulnerability impacts confidentiality by exposing trace metadata and integrity by allowing unauthorized creation of assessments. Deployments using `mlflow ",
   "Upgrade MLflow to a version not affected by CVE-2025-15381 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-15381 (MLflow)",
   "Descripción de NVD (texto original en inglés): In the latest version of mlflow/mlflow, when the `basic-auth` app is enabled, tracing and assessment endpoints are not protected by permission validators. This allows any authenticated user, including those with `NO_PERMISSIONS` on the experiment, to read trace information and create assessments for traces they should not have access to. This vulnerability impacts confidentiality by exposing trace metadata and integrity by allowing unauthorized creation of assessments. Deployments using `mlflow ",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2025-15381 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-15381 (MLflow)",
   "Description NVD (texte original en anglais) : In the latest version of mlflow/mlflow, when the `basic-auth` app is enabled, tracing and assessment endpoints are not protected by permission validators. This allows any authenticated user, including those with `NO_PERMISSIONS` on the experiment, to read trace information and create assessments for traces they should not have access to. This vulnerability impacts confidentiality by exposing trace metadata and integrity by allowing unauthorized creation of assessments. Deployments using `mlflow ",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2025-15381 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-15381 (MLflow)",
   "Descrizione NVD (testo originale in inglese): In the latest version of mlflow/mlflow, when the `basic-auth` app is enabled, tracing and assessment endpoints are not protected by permission validators. This allows any authenticated user, including those with `NO_PERMISSIONS` on the experiment, to read trace information and create assessments for traces they should not have access to. This vulnerability impacts confidentiality by exposing trace metadata and integrity by allowing unauthorized creation of assessments. Deployments using `mlflow ",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2025-15381 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-15381 (MLflow)",
   "NVDの説明（英語原文）: In the latest version of mlflow/mlflow, when the `basic-auth` app is enabled, tracing and assessment endpoints are not protected by permission validators. This allows any authenticated user, including those with `NO_PERMISSIONS` on the experiment, to read trace information and create assessments for traces they should not have access to. This vulnerability impacts confidentiality by exposing trace metadata and integrity by allowing unauthorized creation of assessments. Deployments using `mlflow ",
   "MLflow を CVE-2025-15381 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-15381 (MLflow)",
   "NVD 설명(영어 원문): In the latest version of mlflow/mlflow, when the `basic-auth` app is enabled, tracing and assessment endpoints are not protected by permission validators. This allows any authenticated user, including those with `NO_PERMISSIONS` on the experiment, to read trace information and create assessments for traces they should not have access to. This vulnerability impacts confidentiality by exposing trace metadata and integrity by allowing unauthorized creation of assessments. Deployments using `mlflow ",
   "MLflow을(를) CVE-2025-15381의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-15381 (MLflow)",
   "Descrição do NVD (texto original em inglês): In the latest version of mlflow/mlflow, when the `basic-auth` app is enabled, tracing and assessment endpoints are not protected by permission validators. This allows any authenticated user, including those with `NO_PERMISSIONS` on the experiment, to read trace information and create assessments for traces they should not have access to. This vulnerability impacts confidentiality by exposing trace metadata and integrity by allowing unauthorized creation of assessments. Deployments using `mlflow ",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2025-15381 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-15381（MLflow）",
   "NVD 说明（英文原文）：In the latest version of mlflow/mlflow, when the `basic-auth` app is enabled, tracing and assessment endpoints are not protected by permission validators. This allows any authenticated user, including those with `NO_PERMISSIONS` on the experiment, to read trace information and create assessments for traces they should not have access to. This vulnerability impacts confidentiality by exposing trace metadata and integrity by allowing unauthorized creation of assessments. Deployments using `mlflow ",
   "请尽快将 MLflow 升级到不受 CVE-2025-15381 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-15381（MLflow）",
   "NVD 說明（英文原文）：In the latest version of mlflow/mlflow, when the `basic-auth` app is enabled, tracing and assessment endpoints are not protected by permission validators. This allows any authenticated user, including those with `NO_PERMISSIONS` on the experiment, to read trace information and create assessments for traces they should not have access to. This vulnerability impacts confidentiality by exposing trace metadata and integrity by allowing unauthorized creation of assessments. Deployments using `mlflow ",
   "請儘快將 MLflow 升級到不受 CVE-2025-15381 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2026-0545": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-0545 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): In mlflow/mlflow, the FastAPI job endpoints under `/ajax-api/3.0/jobs/*` are not protected by authentication or authorization when the `basic-auth` app is enabled. This vulnerability affects the latest version of the repository. If job execution is enabled (`MLFLOW_SERVER_ENABLE_JOB_EXECUTION=true`) and any job function is allowlisted, any network client can submit, read, search, and cancel jobs without credentials, bypassing basic-auth entirely. This can lead to unauthenticated remote code exec",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2026-0545 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-0545 (MLflow)",
   "In mlflow/mlflow, the FastAPI job endpoints under `/ajax-api/3.0/jobs/*` are not protected by authentication or authorization when the `basic-auth` app is enabled. This vulnerability affects the latest version of the repository. If job execution is enabled (`MLFLOW_SERVER_ENABLE_JOB_EXECUTION=true`) and any job function is allowlisted, any network client can submit, read, search, and cancel jobs without credentials, bypassing basic-auth entirely. This can lead to unauthenticated remote code exec",
   "Upgrade MLflow to a version not affected by CVE-2026-0545 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-0545 (MLflow)",
   "Descripción de NVD (texto original en inglés): In mlflow/mlflow, the FastAPI job endpoints under `/ajax-api/3.0/jobs/*` are not protected by authentication or authorization when the `basic-auth` app is enabled. This vulnerability affects the latest version of the repository. If job execution is enabled (`MLFLOW_SERVER_ENABLE_JOB_EXECUTION=true`) and any job function is allowlisted, any network client can submit, read, search, and cancel jobs without credentials, bypassing basic-auth entirely. This can lead to unauthenticated remote code exec",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2026-0545 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-0545 (MLflow)",
   "Description NVD (texte original en anglais) : In mlflow/mlflow, the FastAPI job endpoints under `/ajax-api/3.0/jobs/*` are not protected by authentication or authorization when the `basic-auth` app is enabled. This vulnerability affects the latest version of the repository. If job execution is enabled (`MLFLOW_SERVER_ENABLE_JOB_EXECUTION=true`) and any job function is allowlisted, any network client can submit, read, search, and cancel jobs without credentials, bypassing basic-auth entirely. This can lead to unauthenticated remote code exec",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2026-0545 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-0545 (MLflow)",
   "Descrizione NVD (testo originale in inglese): In mlflow/mlflow, the FastAPI job endpoints under `/ajax-api/3.0/jobs/*` are not protected by authentication or authorization when the `basic-auth` app is enabled. This vulnerability affects the latest version of the repository. If job execution is enabled (`MLFLOW_SERVER_ENABLE_JOB_EXECUTION=true`) and any job function is allowlisted, any network client can submit, read, search, and cancel jobs without credentials, bypassing basic-auth entirely. This can lead to unauthenticated remote code exec",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2026-0545 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-0545 (MLflow)",
   "NVDの説明（英語原文）: In mlflow/mlflow, the FastAPI job endpoints under `/ajax-api/3.0/jobs/*` are not protected by authentication or authorization when the `basic-auth` app is enabled. This vulnerability affects the latest version of the repository. If job execution is enabled (`MLFLOW_SERVER_ENABLE_JOB_EXECUTION=true`) and any job function is allowlisted, any network client can submit, read, search, and cancel jobs without credentials, bypassing basic-auth entirely. This can lead to unauthenticated remote code exec",
   "MLflow を CVE-2026-0545 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-0545 (MLflow)",
   "NVD 설명(영어 원문): In mlflow/mlflow, the FastAPI job endpoints under `/ajax-api/3.0/jobs/*` are not protected by authentication or authorization when the `basic-auth` app is enabled. This vulnerability affects the latest version of the repository. If job execution is enabled (`MLFLOW_SERVER_ENABLE_JOB_EXECUTION=true`) and any job function is allowlisted, any network client can submit, read, search, and cancel jobs without credentials, bypassing basic-auth entirely. This can lead to unauthenticated remote code exec",
   "MLflow을(를) CVE-2026-0545의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-0545 (MLflow)",
   "Descrição do NVD (texto original em inglês): In mlflow/mlflow, the FastAPI job endpoints under `/ajax-api/3.0/jobs/*` are not protected by authentication or authorization when the `basic-auth` app is enabled. This vulnerability affects the latest version of the repository. If job execution is enabled (`MLFLOW_SERVER_ENABLE_JOB_EXECUTION=true`) and any job function is allowlisted, any network client can submit, read, search, and cancel jobs without credentials, bypassing basic-auth entirely. This can lead to unauthenticated remote code exec",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2026-0545 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-0545（MLflow）",
   "NVD 说明（英文原文）：In mlflow/mlflow, the FastAPI job endpoints under `/ajax-api/3.0/jobs/*` are not protected by authentication or authorization when the `basic-auth` app is enabled. This vulnerability affects the latest version of the repository. If job execution is enabled (`MLFLOW_SERVER_ENABLE_JOB_EXECUTION=true`) and any job function is allowlisted, any network client can submit, read, search, and cancel jobs without credentials, bypassing basic-auth entirely. This can lead to unauthenticated remote code exec",
   "请尽快将 MLflow 升级到不受 CVE-2026-0545 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-0545（MLflow）",
   "NVD 說明（英文原文）：In mlflow/mlflow, the FastAPI job endpoints under `/ajax-api/3.0/jobs/*` are not protected by authentication or authorization when the `basic-auth` app is enabled. This vulnerability affects the latest version of the repository. If job execution is enabled (`MLFLOW_SERVER_ENABLE_JOB_EXECUTION=true`) and any job function is allowlisted, any network client can submit, read, search, and cancel jobs without credentials, bypassing basic-auth entirely. This can lead to unauthenticated remote code exec",
   "請儘快將 MLflow 升級到不受 CVE-2026-0545 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2026-0596": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-0596 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): A command injection vulnerability exists in mlflow/mlflow when serving a model with `enable_mlserver=True`. The `model_uri` is embedded directly into a shell command executed via `bash -c` without proper sanitization. If the `model_uri` contains shell metacharacters, such as `$()` or backticks, it allows for command substitution and execution of attacker-controlled commands. This vulnerability affects the latest version of mlflow/mlflow and can lead to privilege escalation if a higher-privileged",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2026-0596 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-0596 (MLflow)",
   "A command injection vulnerability exists in mlflow/mlflow when serving a model with `enable_mlserver=True`. The `model_uri` is embedded directly into a shell command executed via `bash -c` without proper sanitization. If the `model_uri` contains shell metacharacters, such as `$()` or backticks, it allows for command substitution and execution of attacker-controlled commands. This vulnerability affects the latest version of mlflow/mlflow and can lead to privilege escalation if a higher-privileged",
   "Upgrade MLflow to a version not affected by CVE-2026-0596 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-0596 (MLflow)",
   "Descripción de NVD (texto original en inglés): A command injection vulnerability exists in mlflow/mlflow when serving a model with `enable_mlserver=True`. The `model_uri` is embedded directly into a shell command executed via `bash -c` without proper sanitization. If the `model_uri` contains shell metacharacters, such as `$()` or backticks, it allows for command substitution and execution of attacker-controlled commands. This vulnerability affects the latest version of mlflow/mlflow and can lead to privilege escalation if a higher-privileged",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2026-0596 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-0596 (MLflow)",
   "Description NVD (texte original en anglais) : A command injection vulnerability exists in mlflow/mlflow when serving a model with `enable_mlserver=True`. The `model_uri` is embedded directly into a shell command executed via `bash -c` without proper sanitization. If the `model_uri` contains shell metacharacters, such as `$()` or backticks, it allows for command substitution and execution of attacker-controlled commands. This vulnerability affects the latest version of mlflow/mlflow and can lead to privilege escalation if a higher-privileged",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2026-0596 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-0596 (MLflow)",
   "Descrizione NVD (testo originale in inglese): A command injection vulnerability exists in mlflow/mlflow when serving a model with `enable_mlserver=True`. The `model_uri` is embedded directly into a shell command executed via `bash -c` without proper sanitization. If the `model_uri` contains shell metacharacters, such as `$()` or backticks, it allows for command substitution and execution of attacker-controlled commands. This vulnerability affects the latest version of mlflow/mlflow and can lead to privilege escalation if a higher-privileged",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2026-0596 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-0596 (MLflow)",
   "NVDの説明（英語原文）: A command injection vulnerability exists in mlflow/mlflow when serving a model with `enable_mlserver=True`. The `model_uri` is embedded directly into a shell command executed via `bash -c` without proper sanitization. If the `model_uri` contains shell metacharacters, such as `$()` or backticks, it allows for command substitution and execution of attacker-controlled commands. This vulnerability affects the latest version of mlflow/mlflow and can lead to privilege escalation if a higher-privileged",
   "MLflow を CVE-2026-0596 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-0596 (MLflow)",
   "NVD 설명(영어 원문): A command injection vulnerability exists in mlflow/mlflow when serving a model with `enable_mlserver=True`. The `model_uri` is embedded directly into a shell command executed via `bash -c` without proper sanitization. If the `model_uri` contains shell metacharacters, such as `$()` or backticks, it allows for command substitution and execution of attacker-controlled commands. This vulnerability affects the latest version of mlflow/mlflow and can lead to privilege escalation if a higher-privileged",
   "MLflow을(를) CVE-2026-0596의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-0596 (MLflow)",
   "Descrição do NVD (texto original em inglês): A command injection vulnerability exists in mlflow/mlflow when serving a model with `enable_mlserver=True`. The `model_uri` is embedded directly into a shell command executed via `bash -c` without proper sanitization. If the `model_uri` contains shell metacharacters, such as `$()` or backticks, it allows for command substitution and execution of attacker-controlled commands. This vulnerability affects the latest version of mlflow/mlflow and can lead to privilege escalation if a higher-privileged",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2026-0596 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-0596（MLflow）",
   "NVD 说明（英文原文）：A command injection vulnerability exists in mlflow/mlflow when serving a model with `enable_mlserver=True`. The `model_uri` is embedded directly into a shell command executed via `bash -c` without proper sanitization. If the `model_uri` contains shell metacharacters, such as `$()` or backticks, it allows for command substitution and execution of attacker-controlled commands. This vulnerability affects the latest version of mlflow/mlflow and can lead to privilege escalation if a higher-privileged",
   "请尽快将 MLflow 升级到不受 CVE-2026-0596 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-0596（MLflow）",
   "NVD 說明（英文原文）：A command injection vulnerability exists in mlflow/mlflow when serving a model with `enable_mlserver=True`. The `model_uri` is embedded directly into a shell command executed via `bash -c` without proper sanitization. If the `model_uri` contains shell metacharacters, such as `$()` or backticks, it allows for command substitution and execution of attacker-controlled commands. This vulnerability affects the latest version of mlflow/mlflow and can lead to privilege escalation if a higher-privileged",
   "請儘快將 MLflow 升級到不受 CVE-2026-0596 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2026-2393": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-2393 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): A Server-Side Request Forgery (SSRF) vulnerability exists in MLflow versions prior to 3.9.0. The `_create_webhook()` function in `mlflow/server/handlers.py` accepts a user-controlled `url` parameter without validation, and the `_send_webhook_request()` function in `mlflow/webhooks/delivery.py` sends HTTP POST requests to this attacker-controlled URL. This allows an authenticated attacker to force the MLflow backend to send HTTP requests to internal services, cloud metadata endpoints, or arbitrar",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2026-2393 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-2393 (MLflow)",
   "A Server-Side Request Forgery (SSRF) vulnerability exists in MLflow versions prior to 3.9.0. The `_create_webhook()` function in `mlflow/server/handlers.py` accepts a user-controlled `url` parameter without validation, and the `_send_webhook_request()` function in `mlflow/webhooks/delivery.py` sends HTTP POST requests to this attacker-controlled URL. This allows an authenticated attacker to force the MLflow backend to send HTTP requests to internal services, cloud metadata endpoints, or arbitrar",
   "Upgrade MLflow to a version not affected by CVE-2026-2393 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-2393 (MLflow)",
   "Descripción de NVD (texto original en inglés): A Server-Side Request Forgery (SSRF) vulnerability exists in MLflow versions prior to 3.9.0. The `_create_webhook()` function in `mlflow/server/handlers.py` accepts a user-controlled `url` parameter without validation, and the `_send_webhook_request()` function in `mlflow/webhooks/delivery.py` sends HTTP POST requests to this attacker-controlled URL. This allows an authenticated attacker to force the MLflow backend to send HTTP requests to internal services, cloud metadata endpoints, or arbitrar",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2026-2393 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-2393 (MLflow)",
   "Description NVD (texte original en anglais) : A Server-Side Request Forgery (SSRF) vulnerability exists in MLflow versions prior to 3.9.0. The `_create_webhook()` function in `mlflow/server/handlers.py` accepts a user-controlled `url` parameter without validation, and the `_send_webhook_request()` function in `mlflow/webhooks/delivery.py` sends HTTP POST requests to this attacker-controlled URL. This allows an authenticated attacker to force the MLflow backend to send HTTP requests to internal services, cloud metadata endpoints, or arbitrar",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2026-2393 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-2393 (MLflow)",
   "Descrizione NVD (testo originale in inglese): A Server-Side Request Forgery (SSRF) vulnerability exists in MLflow versions prior to 3.9.0. The `_create_webhook()` function in `mlflow/server/handlers.py` accepts a user-controlled `url` parameter without validation, and the `_send_webhook_request()` function in `mlflow/webhooks/delivery.py` sends HTTP POST requests to this attacker-controlled URL. This allows an authenticated attacker to force the MLflow backend to send HTTP requests to internal services, cloud metadata endpoints, or arbitrar",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2026-2393 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-2393 (MLflow)",
   "NVDの説明（英語原文）: A Server-Side Request Forgery (SSRF) vulnerability exists in MLflow versions prior to 3.9.0. The `_create_webhook()` function in `mlflow/server/handlers.py` accepts a user-controlled `url` parameter without validation, and the `_send_webhook_request()` function in `mlflow/webhooks/delivery.py` sends HTTP POST requests to this attacker-controlled URL. This allows an authenticated attacker to force the MLflow backend to send HTTP requests to internal services, cloud metadata endpoints, or arbitrar",
   "MLflow を CVE-2026-2393 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-2393 (MLflow)",
   "NVD 설명(영어 원문): A Server-Side Request Forgery (SSRF) vulnerability exists in MLflow versions prior to 3.9.0. The `_create_webhook()` function in `mlflow/server/handlers.py` accepts a user-controlled `url` parameter without validation, and the `_send_webhook_request()` function in `mlflow/webhooks/delivery.py` sends HTTP POST requests to this attacker-controlled URL. This allows an authenticated attacker to force the MLflow backend to send HTTP requests to internal services, cloud metadata endpoints, or arbitrar",
   "MLflow을(를) CVE-2026-2393의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-2393 (MLflow)",
   "Descrição do NVD (texto original em inglês): A Server-Side Request Forgery (SSRF) vulnerability exists in MLflow versions prior to 3.9.0. The `_create_webhook()` function in `mlflow/server/handlers.py` accepts a user-controlled `url` parameter without validation, and the `_send_webhook_request()` function in `mlflow/webhooks/delivery.py` sends HTTP POST requests to this attacker-controlled URL. This allows an authenticated attacker to force the MLflow backend to send HTTP requests to internal services, cloud metadata endpoints, or arbitrar",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2026-2393 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-2393（MLflow）",
   "NVD 说明（英文原文）：A Server-Side Request Forgery (SSRF) vulnerability exists in MLflow versions prior to 3.9.0. The `_create_webhook()` function in `mlflow/server/handlers.py` accepts a user-controlled `url` parameter without validation, and the `_send_webhook_request()` function in `mlflow/webhooks/delivery.py` sends HTTP POST requests to this attacker-controlled URL. This allows an authenticated attacker to force the MLflow backend to send HTTP requests to internal services, cloud metadata endpoints, or arbitrar",
   "请尽快将 MLflow 升级到不受 CVE-2026-2393 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-2393（MLflow）",
   "NVD 說明（英文原文）：A Server-Side Request Forgery (SSRF) vulnerability exists in MLflow versions prior to 3.9.0. The `_create_webhook()` function in `mlflow/server/handlers.py` accepts a user-controlled `url` parameter without validation, and the `_send_webhook_request()` function in `mlflow/webhooks/delivery.py` sends HTTP POST requests to this attacker-controlled URL. This allows an authenticated attacker to force the MLflow backend to send HTTP requests to internal services, cloud metadata endpoints, or arbitrar",
   "請儘快將 MLflow 升級到不受 CVE-2026-2393 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2026-2611": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-2611 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): In MLflow version 3.9.0, the MLflow Assistant feature introduced improper origin validation in its /ajax-api endpoints. This vulnerability allows a remote attacker to exploit cross-origin requests from a malicious webpage to interact with the MLflow Assistant running on a victim's local machine. By bypassing the loopback-only restriction, the attacker can modify the Assistant's configuration to enable full access, which in turn allows the execution of arbitrary commands via the Claude Code sub-a",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2026-2611 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-2611 (MLflow)",
   "In MLflow version 3.9.0, the MLflow Assistant feature introduced improper origin validation in its /ajax-api endpoints. This vulnerability allows a remote attacker to exploit cross-origin requests from a malicious webpage to interact with the MLflow Assistant running on a victim's local machine. By bypassing the loopback-only restriction, the attacker can modify the Assistant's configuration to enable full access, which in turn allows the execution of arbitrary commands via the Claude Code sub-a",
   "Upgrade MLflow to a version not affected by CVE-2026-2611 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-2611 (MLflow)",
   "Descripción de NVD (texto original en inglés): In MLflow version 3.9.0, the MLflow Assistant feature introduced improper origin validation in its /ajax-api endpoints. This vulnerability allows a remote attacker to exploit cross-origin requests from a malicious webpage to interact with the MLflow Assistant running on a victim's local machine. By bypassing the loopback-only restriction, the attacker can modify the Assistant's configuration to enable full access, which in turn allows the execution of arbitrary commands via the Claude Code sub-a",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2026-2611 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-2611 (MLflow)",
   "Description NVD (texte original en anglais) : In MLflow version 3.9.0, the MLflow Assistant feature introduced improper origin validation in its /ajax-api endpoints. This vulnerability allows a remote attacker to exploit cross-origin requests from a malicious webpage to interact with the MLflow Assistant running on a victim's local machine. By bypassing the loopback-only restriction, the attacker can modify the Assistant's configuration to enable full access, which in turn allows the execution of arbitrary commands via the Claude Code sub-a",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2026-2611 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-2611 (MLflow)",
   "Descrizione NVD (testo originale in inglese): In MLflow version 3.9.0, the MLflow Assistant feature introduced improper origin validation in its /ajax-api endpoints. This vulnerability allows a remote attacker to exploit cross-origin requests from a malicious webpage to interact with the MLflow Assistant running on a victim's local machine. By bypassing the loopback-only restriction, the attacker can modify the Assistant's configuration to enable full access, which in turn allows the execution of arbitrary commands via the Claude Code sub-a",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2026-2611 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-2611 (MLflow)",
   "NVDの説明（英語原文）: In MLflow version 3.9.0, the MLflow Assistant feature introduced improper origin validation in its /ajax-api endpoints. This vulnerability allows a remote attacker to exploit cross-origin requests from a malicious webpage to interact with the MLflow Assistant running on a victim's local machine. By bypassing the loopback-only restriction, the attacker can modify the Assistant's configuration to enable full access, which in turn allows the execution of arbitrary commands via the Claude Code sub-a",
   "MLflow を CVE-2026-2611 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-2611 (MLflow)",
   "NVD 설명(영어 원문): In MLflow version 3.9.0, the MLflow Assistant feature introduced improper origin validation in its /ajax-api endpoints. This vulnerability allows a remote attacker to exploit cross-origin requests from a malicious webpage to interact with the MLflow Assistant running on a victim's local machine. By bypassing the loopback-only restriction, the attacker can modify the Assistant's configuration to enable full access, which in turn allows the execution of arbitrary commands via the Claude Code sub-a",
   "MLflow을(를) CVE-2026-2611의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-2611 (MLflow)",
   "Descrição do NVD (texto original em inglês): In MLflow version 3.9.0, the MLflow Assistant feature introduced improper origin validation in its /ajax-api endpoints. This vulnerability allows a remote attacker to exploit cross-origin requests from a malicious webpage to interact with the MLflow Assistant running on a victim's local machine. By bypassing the loopback-only restriction, the attacker can modify the Assistant's configuration to enable full access, which in turn allows the execution of arbitrary commands via the Claude Code sub-a",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2026-2611 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-2611（MLflow）",
   "NVD 说明（英文原文）：In MLflow version 3.9.0, the MLflow Assistant feature introduced improper origin validation in its /ajax-api endpoints. This vulnerability allows a remote attacker to exploit cross-origin requests from a malicious webpage to interact with the MLflow Assistant running on a victim's local machine. By bypassing the loopback-only restriction, the attacker can modify the Assistant's configuration to enable full access, which in turn allows the execution of arbitrary commands via the Claude Code sub-a",
   "请尽快将 MLflow 升级到不受 CVE-2026-2611 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-2611（MLflow）",
   "NVD 說明（英文原文）：In MLflow version 3.9.0, the MLflow Assistant feature introduced improper origin validation in its /ajax-api endpoints. This vulnerability allows a remote attacker to exploit cross-origin requests from a malicious webpage to interact with the MLflow Assistant running on a victim's local machine. By bypassing the loopback-only restriction, the attacker can modify the Assistant's configuration to enable full access, which in turn allows the execution of arbitrary commands via the Claude Code sub-a",
   "請儘快將 MLflow 升級到不受 CVE-2026-2611 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2026-2614": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-2614 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): A vulnerability in the `_create_model_version()` handler of `mlflow/server/handlers.py` in mlflow/mlflow versions 3.9.0 and earlier allows an unauthenticated remote attacker to read arbitrary files from the server's filesystem. The issue arises when a `CreateModelVersion` request includes the tag `mlflow.prompt.is_prompt`, which bypasses source path validation. This enables an attacker to store an arbitrary local filesystem path as the model version source. The `get_model_version_artifact_handle",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2026-2614 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-2614 (MLflow)",
   "A vulnerability in the `_create_model_version()` handler of `mlflow/server/handlers.py` in mlflow/mlflow versions 3.9.0 and earlier allows an unauthenticated remote attacker to read arbitrary files from the server's filesystem. The issue arises when a `CreateModelVersion` request includes the tag `mlflow.prompt.is_prompt`, which bypasses source path validation. This enables an attacker to store an arbitrary local filesystem path as the model version source. The `get_model_version_artifact_handle",
   "Upgrade MLflow to a version not affected by CVE-2026-2614 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-2614 (MLflow)",
   "Descripción de NVD (texto original en inglés): A vulnerability in the `_create_model_version()` handler of `mlflow/server/handlers.py` in mlflow/mlflow versions 3.9.0 and earlier allows an unauthenticated remote attacker to read arbitrary files from the server's filesystem. The issue arises when a `CreateModelVersion` request includes the tag `mlflow.prompt.is_prompt`, which bypasses source path validation. This enables an attacker to store an arbitrary local filesystem path as the model version source. The `get_model_version_artifact_handle",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2026-2614 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-2614 (MLflow)",
   "Description NVD (texte original en anglais) : A vulnerability in the `_create_model_version()` handler of `mlflow/server/handlers.py` in mlflow/mlflow versions 3.9.0 and earlier allows an unauthenticated remote attacker to read arbitrary files from the server's filesystem. The issue arises when a `CreateModelVersion` request includes the tag `mlflow.prompt.is_prompt`, which bypasses source path validation. This enables an attacker to store an arbitrary local filesystem path as the model version source. The `get_model_version_artifact_handle",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2026-2614 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-2614 (MLflow)",
   "Descrizione NVD (testo originale in inglese): A vulnerability in the `_create_model_version()` handler of `mlflow/server/handlers.py` in mlflow/mlflow versions 3.9.0 and earlier allows an unauthenticated remote attacker to read arbitrary files from the server's filesystem. The issue arises when a `CreateModelVersion` request includes the tag `mlflow.prompt.is_prompt`, which bypasses source path validation. This enables an attacker to store an arbitrary local filesystem path as the model version source. The `get_model_version_artifact_handle",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2026-2614 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-2614 (MLflow)",
   "NVDの説明（英語原文）: A vulnerability in the `_create_model_version()` handler of `mlflow/server/handlers.py` in mlflow/mlflow versions 3.9.0 and earlier allows an unauthenticated remote attacker to read arbitrary files from the server's filesystem. The issue arises when a `CreateModelVersion` request includes the tag `mlflow.prompt.is_prompt`, which bypasses source path validation. This enables an attacker to store an arbitrary local filesystem path as the model version source. The `get_model_version_artifact_handle",
   "MLflow を CVE-2026-2614 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-2614 (MLflow)",
   "NVD 설명(영어 원문): A vulnerability in the `_create_model_version()` handler of `mlflow/server/handlers.py` in mlflow/mlflow versions 3.9.0 and earlier allows an unauthenticated remote attacker to read arbitrary files from the server's filesystem. The issue arises when a `CreateModelVersion` request includes the tag `mlflow.prompt.is_prompt`, which bypasses source path validation. This enables an attacker to store an arbitrary local filesystem path as the model version source. The `get_model_version_artifact_handle",
   "MLflow을(를) CVE-2026-2614의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-2614 (MLflow)",
   "Descrição do NVD (texto original em inglês): A vulnerability in the `_create_model_version()` handler of `mlflow/server/handlers.py` in mlflow/mlflow versions 3.9.0 and earlier allows an unauthenticated remote attacker to read arbitrary files from the server's filesystem. The issue arises when a `CreateModelVersion` request includes the tag `mlflow.prompt.is_prompt`, which bypasses source path validation. This enables an attacker to store an arbitrary local filesystem path as the model version source. The `get_model_version_artifact_handle",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2026-2614 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-2614（MLflow）",
   "NVD 说明（英文原文）：A vulnerability in the `_create_model_version()` handler of `mlflow/server/handlers.py` in mlflow/mlflow versions 3.9.0 and earlier allows an unauthenticated remote attacker to read arbitrary files from the server's filesystem. The issue arises when a `CreateModelVersion` request includes the tag `mlflow.prompt.is_prompt`, which bypasses source path validation. This enables an attacker to store an arbitrary local filesystem path as the model version source. The `get_model_version_artifact_handle",
   "请尽快将 MLflow 升级到不受 CVE-2026-2614 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-2614（MLflow）",
   "NVD 說明（英文原文）：A vulnerability in the `_create_model_version()` handler of `mlflow/server/handlers.py` in mlflow/mlflow versions 3.9.0 and earlier allows an unauthenticated remote attacker to read arbitrary files from the server's filesystem. The issue arises when a `CreateModelVersion` request includes the tag `mlflow.prompt.is_prompt`, which bypasses source path validation. This enables an attacker to store an arbitrary local filesystem path as the model version source. The `get_model_version_artifact_handle",
   "請儘快將 MLflow 升級到不受 CVE-2026-2614 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2026-2651": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-2651 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): A vulnerability in MLflow versions <=3.10.1.dev0 allows unauthorized access to multipart upload (MPU) endpoints when the `--serve-artifacts` mode is enabled. The authorization logic does not enforce resource-level permission checks for `/mlflow-artifacts/mpu/*` endpoints, enabling attackers to overwrite artifacts belonging to other users. This can lead to unauthorized cross-user writes, model supply chain poisoning, and arbitrary code execution when compromised models are loaded. The issue is re",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2026-2651 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-2651 (MLflow)",
   "A vulnerability in MLflow versions <=3.10.1.dev0 allows unauthorized access to multipart upload (MPU) endpoints when the `--serve-artifacts` mode is enabled. The authorization logic does not enforce resource-level permission checks for `/mlflow-artifacts/mpu/*` endpoints, enabling attackers to overwrite artifacts belonging to other users. This can lead to unauthorized cross-user writes, model supply chain poisoning, and arbitrary code execution when compromised models are loaded. The issue is re",
   "Upgrade MLflow to a version not affected by CVE-2026-2651 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-2651 (MLflow)",
   "Descripción de NVD (texto original en inglés): A vulnerability in MLflow versions <=3.10.1.dev0 allows unauthorized access to multipart upload (MPU) endpoints when the `--serve-artifacts` mode is enabled. The authorization logic does not enforce resource-level permission checks for `/mlflow-artifacts/mpu/*` endpoints, enabling attackers to overwrite artifacts belonging to other users. This can lead to unauthorized cross-user writes, model supply chain poisoning, and arbitrary code execution when compromised models are loaded. The issue is re",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2026-2651 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-2651 (MLflow)",
   "Description NVD (texte original en anglais) : A vulnerability in MLflow versions <=3.10.1.dev0 allows unauthorized access to multipart upload (MPU) endpoints when the `--serve-artifacts` mode is enabled. The authorization logic does not enforce resource-level permission checks for `/mlflow-artifacts/mpu/*` endpoints, enabling attackers to overwrite artifacts belonging to other users. This can lead to unauthorized cross-user writes, model supply chain poisoning, and arbitrary code execution when compromised models are loaded. The issue is re",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2026-2651 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-2651 (MLflow)",
   "Descrizione NVD (testo originale in inglese): A vulnerability in MLflow versions <=3.10.1.dev0 allows unauthorized access to multipart upload (MPU) endpoints when the `--serve-artifacts` mode is enabled. The authorization logic does not enforce resource-level permission checks for `/mlflow-artifacts/mpu/*` endpoints, enabling attackers to overwrite artifacts belonging to other users. This can lead to unauthorized cross-user writes, model supply chain poisoning, and arbitrary code execution when compromised models are loaded. The issue is re",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2026-2651 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-2651 (MLflow)",
   "NVDの説明（英語原文）: A vulnerability in MLflow versions <=3.10.1.dev0 allows unauthorized access to multipart upload (MPU) endpoints when the `--serve-artifacts` mode is enabled. The authorization logic does not enforce resource-level permission checks for `/mlflow-artifacts/mpu/*` endpoints, enabling attackers to overwrite artifacts belonging to other users. This can lead to unauthorized cross-user writes, model supply chain poisoning, and arbitrary code execution when compromised models are loaded. The issue is re",
   "MLflow を CVE-2026-2651 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-2651 (MLflow)",
   "NVD 설명(영어 원문): A vulnerability in MLflow versions <=3.10.1.dev0 allows unauthorized access to multipart upload (MPU) endpoints when the `--serve-artifacts` mode is enabled. The authorization logic does not enforce resource-level permission checks for `/mlflow-artifacts/mpu/*` endpoints, enabling attackers to overwrite artifacts belonging to other users. This can lead to unauthorized cross-user writes, model supply chain poisoning, and arbitrary code execution when compromised models are loaded. The issue is re",
   "MLflow을(를) CVE-2026-2651의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-2651 (MLflow)",
   "Descrição do NVD (texto original em inglês): A vulnerability in MLflow versions <=3.10.1.dev0 allows unauthorized access to multipart upload (MPU) endpoints when the `--serve-artifacts` mode is enabled. The authorization logic does not enforce resource-level permission checks for `/mlflow-artifacts/mpu/*` endpoints, enabling attackers to overwrite artifacts belonging to other users. This can lead to unauthorized cross-user writes, model supply chain poisoning, and arbitrary code execution when compromised models are loaded. The issue is re",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2026-2651 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-2651（MLflow）",
   "NVD 说明（英文原文）：A vulnerability in MLflow versions <=3.10.1.dev0 allows unauthorized access to multipart upload (MPU) endpoints when the `--serve-artifacts` mode is enabled. The authorization logic does not enforce resource-level permission checks for `/mlflow-artifacts/mpu/*` endpoints, enabling attackers to overwrite artifacts belonging to other users. This can lead to unauthorized cross-user writes, model supply chain poisoning, and arbitrary code execution when compromised models are loaded. The issue is re",
   "请尽快将 MLflow 升级到不受 CVE-2026-2651 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-2651（MLflow）",
   "NVD 說明（英文原文）：A vulnerability in MLflow versions <=3.10.1.dev0 allows unauthorized access to multipart upload (MPU) endpoints when the `--serve-artifacts` mode is enabled. The authorization logic does not enforce resource-level permission checks for `/mlflow-artifacts/mpu/*` endpoints, enabling attackers to overwrite artifacts belonging to other users. This can lead to unauthorized cross-user writes, model supply chain poisoning, and arbitrary code execution when compromised models are loaded. The issue is re",
   "請儘快將 MLflow 升級到不受 CVE-2026-2651 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2026-2652": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-2652 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): A vulnerability in mlflow/mlflow versions 3.9.0 and earlier allows unauthenticated access to certain FastAPI routes when the server is started with authentication enabled (`--app-name basic-auth`) and served via uvicorn (ASGI). The FastAPI permission middleware only enforces authentication on `/gateway/` routes, leaving other routes such as the Job API (`/ajax-api/3.0/jobs/*`) and the OpenTelemetry trace ingestion API (`/v1/traces`) unprotected. This allows unauthenticated remote attackers to su",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2026-2652 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-2652 (MLflow)",
   "A vulnerability in mlflow/mlflow versions 3.9.0 and earlier allows unauthenticated access to certain FastAPI routes when the server is started with authentication enabled (`--app-name basic-auth`) and served via uvicorn (ASGI). The FastAPI permission middleware only enforces authentication on `/gateway/` routes, leaving other routes such as the Job API (`/ajax-api/3.0/jobs/*`) and the OpenTelemetry trace ingestion API (`/v1/traces`) unprotected. This allows unauthenticated remote attackers to su",
   "Upgrade MLflow to a version not affected by CVE-2026-2652 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-2652 (MLflow)",
   "Descripción de NVD (texto original en inglés): A vulnerability in mlflow/mlflow versions 3.9.0 and earlier allows unauthenticated access to certain FastAPI routes when the server is started with authentication enabled (`--app-name basic-auth`) and served via uvicorn (ASGI). The FastAPI permission middleware only enforces authentication on `/gateway/` routes, leaving other routes such as the Job API (`/ajax-api/3.0/jobs/*`) and the OpenTelemetry trace ingestion API (`/v1/traces`) unprotected. This allows unauthenticated remote attackers to su",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2026-2652 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-2652 (MLflow)",
   "Description NVD (texte original en anglais) : A vulnerability in mlflow/mlflow versions 3.9.0 and earlier allows unauthenticated access to certain FastAPI routes when the server is started with authentication enabled (`--app-name basic-auth`) and served via uvicorn (ASGI). The FastAPI permission middleware only enforces authentication on `/gateway/` routes, leaving other routes such as the Job API (`/ajax-api/3.0/jobs/*`) and the OpenTelemetry trace ingestion API (`/v1/traces`) unprotected. This allows unauthenticated remote attackers to su",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2026-2652 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-2652 (MLflow)",
   "Descrizione NVD (testo originale in inglese): A vulnerability in mlflow/mlflow versions 3.9.0 and earlier allows unauthenticated access to certain FastAPI routes when the server is started with authentication enabled (`--app-name basic-auth`) and served via uvicorn (ASGI). The FastAPI permission middleware only enforces authentication on `/gateway/` routes, leaving other routes such as the Job API (`/ajax-api/3.0/jobs/*`) and the OpenTelemetry trace ingestion API (`/v1/traces`) unprotected. This allows unauthenticated remote attackers to su",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2026-2652 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-2652 (MLflow)",
   "NVDの説明（英語原文）: A vulnerability in mlflow/mlflow versions 3.9.0 and earlier allows unauthenticated access to certain FastAPI routes when the server is started with authentication enabled (`--app-name basic-auth`) and served via uvicorn (ASGI). The FastAPI permission middleware only enforces authentication on `/gateway/` routes, leaving other routes such as the Job API (`/ajax-api/3.0/jobs/*`) and the OpenTelemetry trace ingestion API (`/v1/traces`) unprotected. This allows unauthenticated remote attackers to su",
   "MLflow を CVE-2026-2652 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-2652 (MLflow)",
   "NVD 설명(영어 원문): A vulnerability in mlflow/mlflow versions 3.9.0 and earlier allows unauthenticated access to certain FastAPI routes when the server is started with authentication enabled (`--app-name basic-auth`) and served via uvicorn (ASGI). The FastAPI permission middleware only enforces authentication on `/gateway/` routes, leaving other routes such as the Job API (`/ajax-api/3.0/jobs/*`) and the OpenTelemetry trace ingestion API (`/v1/traces`) unprotected. This allows unauthenticated remote attackers to su",
   "MLflow을(를) CVE-2026-2652의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-2652 (MLflow)",
   "Descrição do NVD (texto original em inglês): A vulnerability in mlflow/mlflow versions 3.9.0 and earlier allows unauthenticated access to certain FastAPI routes when the server is started with authentication enabled (`--app-name basic-auth`) and served via uvicorn (ASGI). The FastAPI permission middleware only enforces authentication on `/gateway/` routes, leaving other routes such as the Job API (`/ajax-api/3.0/jobs/*`) and the OpenTelemetry trace ingestion API (`/v1/traces`) unprotected. This allows unauthenticated remote attackers to su",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2026-2652 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-2652（MLflow）",
   "NVD 说明（英文原文）：A vulnerability in mlflow/mlflow versions 3.9.0 and earlier allows unauthenticated access to certain FastAPI routes when the server is started with authentication enabled (`--app-name basic-auth`) and served via uvicorn (ASGI). The FastAPI permission middleware only enforces authentication on `/gateway/` routes, leaving other routes such as the Job API (`/ajax-api/3.0/jobs/*`) and the OpenTelemetry trace ingestion API (`/v1/traces`) unprotected. This allows unauthenticated remote attackers to su",
   "请尽快将 MLflow 升级到不受 CVE-2026-2652 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-2652（MLflow）",
   "NVD 說明（英文原文）：A vulnerability in mlflow/mlflow versions 3.9.0 and earlier allows unauthenticated access to certain FastAPI routes when the server is started with authentication enabled (`--app-name basic-auth`) and served via uvicorn (ASGI). The FastAPI permission middleware only enforces authentication on `/gateway/` routes, leaving other routes such as the Job API (`/ajax-api/3.0/jobs/*`) and the OpenTelemetry trace ingestion API (`/v1/traces`) unprotected. This allows unauthenticated remote attackers to su",
   "請儘快將 MLflow 升級到不受 CVE-2026-2652 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2026-4035": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-4035 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): A vulnerability in mlflow/mlflow versions prior to 3.11.0 allows for the resolution of environment variables in AI Gateway secrets, which can be exploited to exfiltrate sensitive server-side environment credentials to an attacker-controlled endpoint. This issue arises because the `api_key` field in gateway secrets can accept `$ENV_VAR` references, which are resolved against the MLflow server's environment during runtime. The resolved secrets are then sent in provider authentication headers to th",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2026-4035 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-4035 (MLflow)",
   "A vulnerability in mlflow/mlflow versions prior to 3.11.0 allows for the resolution of environment variables in AI Gateway secrets, which can be exploited to exfiltrate sensitive server-side environment credentials to an attacker-controlled endpoint. This issue arises because the `api_key` field in gateway secrets can accept `$ENV_VAR` references, which are resolved against the MLflow server's environment during runtime. The resolved secrets are then sent in provider authentication headers to th",
   "Upgrade MLflow to a version not affected by CVE-2026-4035 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-4035 (MLflow)",
   "Descripción de NVD (texto original en inglés): A vulnerability in mlflow/mlflow versions prior to 3.11.0 allows for the resolution of environment variables in AI Gateway secrets, which can be exploited to exfiltrate sensitive server-side environment credentials to an attacker-controlled endpoint. This issue arises because the `api_key` field in gateway secrets can accept `$ENV_VAR` references, which are resolved against the MLflow server's environment during runtime. The resolved secrets are then sent in provider authentication headers to th",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2026-4035 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-4035 (MLflow)",
   "Description NVD (texte original en anglais) : A vulnerability in mlflow/mlflow versions prior to 3.11.0 allows for the resolution of environment variables in AI Gateway secrets, which can be exploited to exfiltrate sensitive server-side environment credentials to an attacker-controlled endpoint. This issue arises because the `api_key` field in gateway secrets can accept `$ENV_VAR` references, which are resolved against the MLflow server's environment during runtime. The resolved secrets are then sent in provider authentication headers to th",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2026-4035 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-4035 (MLflow)",
   "Descrizione NVD (testo originale in inglese): A vulnerability in mlflow/mlflow versions prior to 3.11.0 allows for the resolution of environment variables in AI Gateway secrets, which can be exploited to exfiltrate sensitive server-side environment credentials to an attacker-controlled endpoint. This issue arises because the `api_key` field in gateway secrets can accept `$ENV_VAR` references, which are resolved against the MLflow server's environment during runtime. The resolved secrets are then sent in provider authentication headers to th",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2026-4035 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-4035 (MLflow)",
   "NVDの説明（英語原文）: A vulnerability in mlflow/mlflow versions prior to 3.11.0 allows for the resolution of environment variables in AI Gateway secrets, which can be exploited to exfiltrate sensitive server-side environment credentials to an attacker-controlled endpoint. This issue arises because the `api_key` field in gateway secrets can accept `$ENV_VAR` references, which are resolved against the MLflow server's environment during runtime. The resolved secrets are then sent in provider authentication headers to th",
   "MLflow を CVE-2026-4035 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-4035 (MLflow)",
   "NVD 설명(영어 원문): A vulnerability in mlflow/mlflow versions prior to 3.11.0 allows for the resolution of environment variables in AI Gateway secrets, which can be exploited to exfiltrate sensitive server-side environment credentials to an attacker-controlled endpoint. This issue arises because the `api_key` field in gateway secrets can accept `$ENV_VAR` references, which are resolved against the MLflow server's environment during runtime. The resolved secrets are then sent in provider authentication headers to th",
   "MLflow을(를) CVE-2026-4035의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-4035 (MLflow)",
   "Descrição do NVD (texto original em inglês): A vulnerability in mlflow/mlflow versions prior to 3.11.0 allows for the resolution of environment variables in AI Gateway secrets, which can be exploited to exfiltrate sensitive server-side environment credentials to an attacker-controlled endpoint. This issue arises because the `api_key` field in gateway secrets can accept `$ENV_VAR` references, which are resolved against the MLflow server's environment during runtime. The resolved secrets are then sent in provider authentication headers to th",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2026-4035 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-4035（MLflow）",
   "NVD 说明（英文原文）：A vulnerability in mlflow/mlflow versions prior to 3.11.0 allows for the resolution of environment variables in AI Gateway secrets, which can be exploited to exfiltrate sensitive server-side environment credentials to an attacker-controlled endpoint. This issue arises because the `api_key` field in gateway secrets can accept `$ENV_VAR` references, which are resolved against the MLflow server's environment during runtime. The resolved secrets are then sent in provider authentication headers to th",
   "请尽快将 MLflow 升级到不受 CVE-2026-4035 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-4035（MLflow）",
   "NVD 說明（英文原文）：A vulnerability in mlflow/mlflow versions prior to 3.11.0 allows for the resolution of environment variables in AI Gateway secrets, which can be exploited to exfiltrate sensitive server-side environment credentials to an attacker-controlled endpoint. This issue arises because the `api_key` field in gateway secrets can accept `$ENV_VAR` references, which are resolved against the MLflow server's environment during runtime. The resolved secrets are then sent in provider authentication headers to th",
   "請儘快將 MLflow 升級到不受 CVE-2026-4035 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2026-4137": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-4137 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): In mlflow/mlflow versions prior to 3.11.0, the `get_or_create_nfs_tmp_dir()` function in `mlflow/utils/file_utils.py` creates temporary directories with world-writable permissions (0o777), and the `_create_model_downloading_tmp_dir()` function in `mlflow/pyfunc/__init__.py` creates directories with group-writable permissions (0o770). These insecure permissions allow local attackers to tamper with model artifacts, such as cloudpickle-serialized Python objects, and achieve arbitrary code execution",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2026-4137 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-4137 (MLflow)",
   "In mlflow/mlflow versions prior to 3.11.0, the `get_or_create_nfs_tmp_dir()` function in `mlflow/utils/file_utils.py` creates temporary directories with world-writable permissions (0o777), and the `_create_model_downloading_tmp_dir()` function in `mlflow/pyfunc/__init__.py` creates directories with group-writable permissions (0o770). These insecure permissions allow local attackers to tamper with model artifacts, such as cloudpickle-serialized Python objects, and achieve arbitrary code execution",
   "Upgrade MLflow to a version not affected by CVE-2026-4137 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-4137 (MLflow)",
   "Descripción de NVD (texto original en inglés): In mlflow/mlflow versions prior to 3.11.0, the `get_or_create_nfs_tmp_dir()` function in `mlflow/utils/file_utils.py` creates temporary directories with world-writable permissions (0o777), and the `_create_model_downloading_tmp_dir()` function in `mlflow/pyfunc/__init__.py` creates directories with group-writable permissions (0o770). These insecure permissions allow local attackers to tamper with model artifacts, such as cloudpickle-serialized Python objects, and achieve arbitrary code execution",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2026-4137 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-4137 (MLflow)",
   "Description NVD (texte original en anglais) : In mlflow/mlflow versions prior to 3.11.0, the `get_or_create_nfs_tmp_dir()` function in `mlflow/utils/file_utils.py` creates temporary directories with world-writable permissions (0o777), and the `_create_model_downloading_tmp_dir()` function in `mlflow/pyfunc/__init__.py` creates directories with group-writable permissions (0o770). These insecure permissions allow local attackers to tamper with model artifacts, such as cloudpickle-serialized Python objects, and achieve arbitrary code execution",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2026-4137 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-4137 (MLflow)",
   "Descrizione NVD (testo originale in inglese): In mlflow/mlflow versions prior to 3.11.0, the `get_or_create_nfs_tmp_dir()` function in `mlflow/utils/file_utils.py` creates temporary directories with world-writable permissions (0o777), and the `_create_model_downloading_tmp_dir()` function in `mlflow/pyfunc/__init__.py` creates directories with group-writable permissions (0o770). These insecure permissions allow local attackers to tamper with model artifacts, such as cloudpickle-serialized Python objects, and achieve arbitrary code execution",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2026-4137 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-4137 (MLflow)",
   "NVDの説明（英語原文）: In mlflow/mlflow versions prior to 3.11.0, the `get_or_create_nfs_tmp_dir()` function in `mlflow/utils/file_utils.py` creates temporary directories with world-writable permissions (0o777), and the `_create_model_downloading_tmp_dir()` function in `mlflow/pyfunc/__init__.py` creates directories with group-writable permissions (0o770). These insecure permissions allow local attackers to tamper with model artifacts, such as cloudpickle-serialized Python objects, and achieve arbitrary code execution",
   "MLflow を CVE-2026-4137 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-4137 (MLflow)",
   "NVD 설명(영어 원문): In mlflow/mlflow versions prior to 3.11.0, the `get_or_create_nfs_tmp_dir()` function in `mlflow/utils/file_utils.py` creates temporary directories with world-writable permissions (0o777), and the `_create_model_downloading_tmp_dir()` function in `mlflow/pyfunc/__init__.py` creates directories with group-writable permissions (0o770). These insecure permissions allow local attackers to tamper with model artifacts, such as cloudpickle-serialized Python objects, and achieve arbitrary code execution",
   "MLflow을(를) CVE-2026-4137의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-4137 (MLflow)",
   "Descrição do NVD (texto original em inglês): In mlflow/mlflow versions prior to 3.11.0, the `get_or_create_nfs_tmp_dir()` function in `mlflow/utils/file_utils.py` creates temporary directories with world-writable permissions (0o777), and the `_create_model_downloading_tmp_dir()` function in `mlflow/pyfunc/__init__.py` creates directories with group-writable permissions (0o770). These insecure permissions allow local attackers to tamper with model artifacts, such as cloudpickle-serialized Python objects, and achieve arbitrary code execution",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2026-4137 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-4137（MLflow）",
   "NVD 说明（英文原文）：In mlflow/mlflow versions prior to 3.11.0, the `get_or_create_nfs_tmp_dir()` function in `mlflow/utils/file_utils.py` creates temporary directories with world-writable permissions (0o777), and the `_create_model_downloading_tmp_dir()` function in `mlflow/pyfunc/__init__.py` creates directories with group-writable permissions (0o770). These insecure permissions allow local attackers to tamper with model artifacts, such as cloudpickle-serialized Python objects, and achieve arbitrary code execution",
   "请尽快将 MLflow 升级到不受 CVE-2026-4137 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-4137（MLflow）",
   "NVD 說明（英文原文）：In mlflow/mlflow versions prior to 3.11.0, the `get_or_create_nfs_tmp_dir()` function in `mlflow/utils/file_utils.py` creates temporary directories with world-writable permissions (0o777), and the `_create_model_downloading_tmp_dir()` function in `mlflow/pyfunc/__init__.py` creates directories with group-writable permissions (0o770). These insecure permissions allow local attackers to tamper with model artifacts, such as cloudpickle-serialized Python objects, and achieve arbitrary code execution",
   "請儘快將 MLflow 升級到不受 CVE-2026-4137 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2026-64849": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-64849 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): MLflow is an open source AI engineering platform for agents, large language models, and machine learning models. Starting in 3.3.0 and prior to 3.15.0, the unauthenticated POST /api/2.0/mlflow/webhooks/{id}/test endpoint calls _validate_webhook_url() in mlflow/utils/validation.py only for the original URL while mlflow/webhooks/delivery.py follows redirects and re-resolves the hostname without pinning the validated address, allowing attackers to reach internal or cloud metadata services and recei",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2026-64849 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-64849 (MLflow)",
   "MLflow is an open source AI engineering platform for agents, large language models, and machine learning models. Starting in 3.3.0 and prior to 3.15.0, the unauthenticated POST /api/2.0/mlflow/webhooks/{id}/test endpoint calls _validate_webhook_url() in mlflow/utils/validation.py only for the original URL while mlflow/webhooks/delivery.py follows redirects and re-resolves the hostname without pinning the validated address, allowing attackers to reach internal or cloud metadata services and recei",
   "Upgrade MLflow to a version not affected by CVE-2026-64849 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-64849 (MLflow)",
   "Descripción de NVD (texto original en inglés): MLflow is an open source AI engineering platform for agents, large language models, and machine learning models. Starting in 3.3.0 and prior to 3.15.0, the unauthenticated POST /api/2.0/mlflow/webhooks/{id}/test endpoint calls _validate_webhook_url() in mlflow/utils/validation.py only for the original URL while mlflow/webhooks/delivery.py follows redirects and re-resolves the hostname without pinning the validated address, allowing attackers to reach internal or cloud metadata services and recei",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2026-64849 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-64849 (MLflow)",
   "Description NVD (texte original en anglais) : MLflow is an open source AI engineering platform for agents, large language models, and machine learning models. Starting in 3.3.0 and prior to 3.15.0, the unauthenticated POST /api/2.0/mlflow/webhooks/{id}/test endpoint calls _validate_webhook_url() in mlflow/utils/validation.py only for the original URL while mlflow/webhooks/delivery.py follows redirects and re-resolves the hostname without pinning the validated address, allowing attackers to reach internal or cloud metadata services and recei",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2026-64849 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-64849 (MLflow)",
   "Descrizione NVD (testo originale in inglese): MLflow is an open source AI engineering platform for agents, large language models, and machine learning models. Starting in 3.3.0 and prior to 3.15.0, the unauthenticated POST /api/2.0/mlflow/webhooks/{id}/test endpoint calls _validate_webhook_url() in mlflow/utils/validation.py only for the original URL while mlflow/webhooks/delivery.py follows redirects and re-resolves the hostname without pinning the validated address, allowing attackers to reach internal or cloud metadata services and recei",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2026-64849 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-64849 (MLflow)",
   "NVDの説明（英語原文）: MLflow is an open source AI engineering platform for agents, large language models, and machine learning models. Starting in 3.3.0 and prior to 3.15.0, the unauthenticated POST /api/2.0/mlflow/webhooks/{id}/test endpoint calls _validate_webhook_url() in mlflow/utils/validation.py only for the original URL while mlflow/webhooks/delivery.py follows redirects and re-resolves the hostname without pinning the validated address, allowing attackers to reach internal or cloud metadata services and recei",
   "MLflow を CVE-2026-64849 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-64849 (MLflow)",
   "NVD 설명(영어 원문): MLflow is an open source AI engineering platform for agents, large language models, and machine learning models. Starting in 3.3.0 and prior to 3.15.0, the unauthenticated POST /api/2.0/mlflow/webhooks/{id}/test endpoint calls _validate_webhook_url() in mlflow/utils/validation.py only for the original URL while mlflow/webhooks/delivery.py follows redirects and re-resolves the hostname without pinning the validated address, allowing attackers to reach internal or cloud metadata services and recei",
   "MLflow을(를) CVE-2026-64849의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-64849 (MLflow)",
   "Descrição do NVD (texto original em inglês): MLflow is an open source AI engineering platform for agents, large language models, and machine learning models. Starting in 3.3.0 and prior to 3.15.0, the unauthenticated POST /api/2.0/mlflow/webhooks/{id}/test endpoint calls _validate_webhook_url() in mlflow/utils/validation.py only for the original URL while mlflow/webhooks/delivery.py follows redirects and re-resolves the hostname without pinning the validated address, allowing attackers to reach internal or cloud metadata services and recei",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2026-64849 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-64849（MLflow）",
   "NVD 说明（英文原文）：MLflow is an open source AI engineering platform for agents, large language models, and machine learning models. Starting in 3.3.0 and prior to 3.15.0, the unauthenticated POST /api/2.0/mlflow/webhooks/{id}/test endpoint calls _validate_webhook_url() in mlflow/utils/validation.py only for the original URL while mlflow/webhooks/delivery.py follows redirects and re-resolves the hostname without pinning the validated address, allowing attackers to reach internal or cloud metadata services and recei",
   "请尽快将 MLflow 升级到不受 CVE-2026-64849 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-64849（MLflow）",
   "NVD 說明（英文原文）：MLflow is an open source AI engineering platform for agents, large language models, and machine learning models. Starting in 3.3.0 and prior to 3.15.0, the unauthenticated POST /api/2.0/mlflow/webhooks/{id}/test endpoint calls _validate_webhook_url() in mlflow/utils/validation.py only for the original URL while mlflow/webhooks/delivery.py follows redirects and re-resolves the hostname without pinning the validated address, allowing attackers to reach internal or cloud metadata services and recei",
   "請儘快將 MLflow 升級到不受 CVE-2026-64849 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:mlflow-noauth:CVE-2026-8147": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-8147 (MLflow)",
   "NVD-Beschreibung (englischer Originaltext): In MLflow versions prior to 3.14.0, when running with authentication enabled, the trace API endpoints lack proper authorization validators. This allows any authenticated user to bypass experiment-level authorization controls on all trace operations, including reading, deleting, and modifying traces on experiments they do not have permission to access. The issue arises from the `_before_request` handler, which does not register authorization validators for trace endpoints, resulting in requests p",
   "Aktualisieren Sie MLflow so schnell wie möglich auf eine Version, die von CVE-2026-8147 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-8147 (MLflow)",
   "In MLflow versions prior to 3.14.0, when running with authentication enabled, the trace API endpoints lack proper authorization validators. This allows any authenticated user to bypass experiment-level authorization controls on all trace operations, including reading, deleting, and modifying traces on experiments they do not have permission to access. The issue arises from the `_before_request` handler, which does not register authorization validators for trace endpoints, resulting in requests p",
   "Upgrade MLflow to a version not affected by CVE-2026-8147 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-8147 (MLflow)",
   "Descripción de NVD (texto original en inglés): In MLflow versions prior to 3.14.0, when running with authentication enabled, the trace API endpoints lack proper authorization validators. This allows any authenticated user to bypass experiment-level authorization controls on all trace operations, including reading, deleting, and modifying traces on experiments they do not have permission to access. The issue arises from the `_before_request` handler, which does not register authorization validators for trace endpoints, resulting in requests p",
   "Actualice MLflow lo antes posible a una versión no afectada por CVE-2026-8147 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-8147 (MLflow)",
   "Description NVD (texte original en anglais) : In MLflow versions prior to 3.14.0, when running with authentication enabled, the trace API endpoints lack proper authorization validators. This allows any authenticated user to bypass experiment-level authorization controls on all trace operations, including reading, deleting, and modifying traces on experiments they do not have permission to access. The issue arises from the `_before_request` handler, which does not register authorization validators for trace endpoints, resulting in requests p",
   "Mettez à niveau MLflow dès que possible vers une version non affectée par CVE-2026-8147 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-8147 (MLflow)",
   "Descrizione NVD (testo originale in inglese): In MLflow versions prior to 3.14.0, when running with authentication enabled, the trace API endpoints lack proper authorization validators. This allows any authenticated user to bypass experiment-level authorization controls on all trace operations, including reading, deleting, and modifying traces on experiments they do not have permission to access. The issue arises from the `_before_request` handler, which does not register authorization validators for trace endpoints, resulting in requests p",
   "Aggiorna MLflow il prima possibile a una versione non interessata da CVE-2026-8147 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-8147 (MLflow)",
   "NVDの説明（英語原文）: In MLflow versions prior to 3.14.0, when running with authentication enabled, the trace API endpoints lack proper authorization validators. This allows any authenticated user to bypass experiment-level authorization controls on all trace operations, including reading, deleting, and modifying traces on experiments they do not have permission to access. The issue arises from the `_before_request` handler, which does not register authorization validators for trace endpoints, resulting in requests p",
   "MLflow を CVE-2026-8147 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-8147 (MLflow)",
   "NVD 설명(영어 원문): In MLflow versions prior to 3.14.0, when running with authentication enabled, the trace API endpoints lack proper authorization validators. This allows any authenticated user to bypass experiment-level authorization controls on all trace operations, including reading, deleting, and modifying traces on experiments they do not have permission to access. The issue arises from the `_before_request` handler, which does not register authorization validators for trace endpoints, resulting in requests p",
   "MLflow을(를) CVE-2026-8147의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-8147 (MLflow)",
   "Descrição do NVD (texto original em inglês): In MLflow versions prior to 3.14.0, when running with authentication enabled, the trace API endpoints lack proper authorization validators. This allows any authenticated user to bypass experiment-level authorization controls on all trace operations, including reading, deleting, and modifying traces on experiments they do not have permission to access. The issue arises from the `_before_request` handler, which does not register authorization validators for trace endpoints, resulting in requests p",
   "Atualize o MLflow o quanto antes para uma versão não afetada por CVE-2026-8147 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-8147（MLflow）",
   "NVD 说明（英文原文）：In MLflow versions prior to 3.14.0, when running with authentication enabled, the trace API endpoints lack proper authorization validators. This allows any authenticated user to bypass experiment-level authorization controls on all trace operations, including reading, deleting, and modifying traces on experiments they do not have permission to access. The issue arises from the `_before_request` handler, which does not register authorization validators for trace endpoints, resulting in requests p",
   "请尽快将 MLflow 升级到不受 CVE-2026-8147 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-8147（MLflow）",
   "NVD 說明（英文原文）：In MLflow versions prior to 3.14.0, when running with authentication enabled, the trace API endpoints lack proper authorization validators. This allows any authenticated user to bypass experiment-level authorization controls on all trace operations, including reading, deleting, and modifying traces on experiments they do not have permission to access. The issue arises from the `_before_request` handler, which does not register authorization validators for trace endpoints, resulting in requests p",
   "請儘快將 MLflow 升級到不受 CVE-2026-8147 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:ollama-exposed:CVE-2024-12055": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-12055 (Ollama)",
   "NVD-Beschreibung (englischer Originaltext): A vulnerability in Ollama versions <=0.3.14 allows a malicious user to create a customized gguf model file that can be uploaded to the public Ollama server. When the server processes this malicious model, it crashes, leading to a Denial of Service (DoS) attack. The root cause of the issue is an out-of-bounds read in the gguf.go file.",
   "Aktualisieren Sie Ollama so schnell wie möglich auf eine Version, die von CVE-2024-12055 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-12055 (Ollama)",
   "A vulnerability in Ollama versions <=0.3.14 allows a malicious user to create a customized gguf model file that can be uploaded to the public Ollama server. When the server processes this malicious model, it crashes, leading to a Denial of Service (DoS) attack. The root cause of the issue is an out-of-bounds read in the gguf.go file.",
   "Upgrade Ollama to a version not affected by CVE-2024-12055 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-12055 (Ollama)",
   "Descripción de NVD (texto original en inglés): A vulnerability in Ollama versions <=0.3.14 allows a malicious user to create a customized gguf model file that can be uploaded to the public Ollama server. When the server processes this malicious model, it crashes, leading to a Denial of Service (DoS) attack. The root cause of the issue is an out-of-bounds read in the gguf.go file.",
   "Actualice Ollama lo antes posible a una versión no afectada por CVE-2024-12055 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-12055 (Ollama)",
   "Description NVD (texte original en anglais) : A vulnerability in Ollama versions <=0.3.14 allows a malicious user to create a customized gguf model file that can be uploaded to the public Ollama server. When the server processes this malicious model, it crashes, leading to a Denial of Service (DoS) attack. The root cause of the issue is an out-of-bounds read in the gguf.go file.",
   "Mettez à niveau Ollama dès que possible vers une version non affectée par CVE-2024-12055 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-12055 (Ollama)",
   "Descrizione NVD (testo originale in inglese): A vulnerability in Ollama versions <=0.3.14 allows a malicious user to create a customized gguf model file that can be uploaded to the public Ollama server. When the server processes this malicious model, it crashes, leading to a Denial of Service (DoS) attack. The root cause of the issue is an out-of-bounds read in the gguf.go file.",
   "Aggiorna Ollama il prima possibile a una versione non interessata da CVE-2024-12055 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-12055 (Ollama)",
   "NVDの説明（英語原文）: A vulnerability in Ollama versions <=0.3.14 allows a malicious user to create a customized gguf model file that can be uploaded to the public Ollama server. When the server processes this malicious model, it crashes, leading to a Denial of Service (DoS) attack. The root cause of the issue is an out-of-bounds read in the gguf.go file.",
   "Ollama を CVE-2024-12055 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-12055 (Ollama)",
   "NVD 설명(영어 원문): A vulnerability in Ollama versions <=0.3.14 allows a malicious user to create a customized gguf model file that can be uploaded to the public Ollama server. When the server processes this malicious model, it crashes, leading to a Denial of Service (DoS) attack. The root cause of the issue is an out-of-bounds read in the gguf.go file.",
   "Ollama을(를) CVE-2024-12055의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-12055 (Ollama)",
   "Descrição do NVD (texto original em inglês): A vulnerability in Ollama versions <=0.3.14 allows a malicious user to create a customized gguf model file that can be uploaded to the public Ollama server. When the server processes this malicious model, it crashes, leading to a Denial of Service (DoS) attack. The root cause of the issue is an out-of-bounds read in the gguf.go file.",
   "Atualize o Ollama o quanto antes para uma versão não afetada por CVE-2024-12055 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-12055（Ollama）",
   "NVD 说明（英文原文）：A vulnerability in Ollama versions <=0.3.14 allows a malicious user to create a customized gguf model file that can be uploaded to the public Ollama server. When the server processes this malicious model, it crashes, leading to a Denial of Service (DoS) attack. The root cause of the issue is an out-of-bounds read in the gguf.go file.",
   "请尽快将 Ollama 升级到不受 CVE-2024-12055 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-12055（Ollama）",
   "NVD 說明（英文原文）：A vulnerability in Ollama versions <=0.3.14 allows a malicious user to create a customized gguf model file that can be uploaded to the public Ollama server. When the server processes this malicious model, it crashes, leading to a Denial of Service (DoS) attack. The root cause of the issue is an out-of-bounds read in the gguf.go file.",
   "請儘快將 Ollama 升級到不受 CVE-2024-12055 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:ollama-exposed:CVE-2024-37032": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-37032 (Ollama)",
   "NVD-Beschreibung (englischer Originaltext): Ollama before 0.1.34 does not validate the format of the digest (sha256 with 64 hex digits) when getting the model path, and thus mishandles the TestGetBlobsPath test cases such as fewer than 64 hex digits, more than 64 hex digits, or an initial ../ substring.",
   "Aktualisieren Sie Ollama so schnell wie möglich auf eine Version, die von CVE-2024-37032 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-37032 (Ollama)",
   "Ollama before 0.1.34 does not validate the format of the digest (sha256 with 64 hex digits) when getting the model path, and thus mishandles the TestGetBlobsPath test cases such as fewer than 64 hex digits, more than 64 hex digits, or an initial ../ substring.",
   "Upgrade Ollama to a version not affected by CVE-2024-37032 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-37032 (Ollama)",
   "Descripción de NVD (texto original en inglés): Ollama before 0.1.34 does not validate the format of the digest (sha256 with 64 hex digits) when getting the model path, and thus mishandles the TestGetBlobsPath test cases such as fewer than 64 hex digits, more than 64 hex digits, or an initial ../ substring.",
   "Actualice Ollama lo antes posible a una versión no afectada por CVE-2024-37032 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-37032 (Ollama)",
   "Description NVD (texte original en anglais) : Ollama before 0.1.34 does not validate the format of the digest (sha256 with 64 hex digits) when getting the model path, and thus mishandles the TestGetBlobsPath test cases such as fewer than 64 hex digits, more than 64 hex digits, or an initial ../ substring.",
   "Mettez à niveau Ollama dès que possible vers une version non affectée par CVE-2024-37032 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-37032 (Ollama)",
   "Descrizione NVD (testo originale in inglese): Ollama before 0.1.34 does not validate the format of the digest (sha256 with 64 hex digits) when getting the model path, and thus mishandles the TestGetBlobsPath test cases such as fewer than 64 hex digits, more than 64 hex digits, or an initial ../ substring.",
   "Aggiorna Ollama il prima possibile a una versione non interessata da CVE-2024-37032 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-37032 (Ollama)",
   "NVDの説明（英語原文）: Ollama before 0.1.34 does not validate the format of the digest (sha256 with 64 hex digits) when getting the model path, and thus mishandles the TestGetBlobsPath test cases such as fewer than 64 hex digits, more than 64 hex digits, or an initial ../ substring.",
   "Ollama を CVE-2024-37032 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-37032 (Ollama)",
   "NVD 설명(영어 원문): Ollama before 0.1.34 does not validate the format of the digest (sha256 with 64 hex digits) when getting the model path, and thus mishandles the TestGetBlobsPath test cases such as fewer than 64 hex digits, more than 64 hex digits, or an initial ../ substring.",
   "Ollama을(를) CVE-2024-37032의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-37032 (Ollama)",
   "Descrição do NVD (texto original em inglês): Ollama before 0.1.34 does not validate the format of the digest (sha256 with 64 hex digits) when getting the model path, and thus mishandles the TestGetBlobsPath test cases such as fewer than 64 hex digits, more than 64 hex digits, or an initial ../ substring.",
   "Atualize o Ollama o quanto antes para uma versão não afetada por CVE-2024-37032 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-37032（Ollama）",
   "NVD 说明（英文原文）：Ollama before 0.1.34 does not validate the format of the digest (sha256 with 64 hex digits) when getting the model path, and thus mishandles the TestGetBlobsPath test cases such as fewer than 64 hex digits, more than 64 hex digits, or an initial ../ substring.",
   "请尽快将 Ollama 升级到不受 CVE-2024-37032 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-37032（Ollama）",
   "NVD 說明（英文原文）：Ollama before 0.1.34 does not validate the format of the digest (sha256 with 64 hex digits) when getting the model path, and thus mishandles the TestGetBlobsPath test cases such as fewer than 64 hex digits, more than 64 hex digits, or an initial ../ substring.",
   "請儘快將 Ollama 升級到不受 CVE-2024-37032 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:ollama-exposed:CVE-2024-39719": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-39719 (Ollama)",
   "NVD-Beschreibung (englischer Originaltext): An issue was discovered in Ollama through 0.3.14. File existence disclosure can occur via api/create. When calling the CreateModel route with a path parameter that does not exist, it reflects the \"File does not exist\" error message to the attacker, providing a primitive for file existence on the server.",
   "Aktualisieren Sie Ollama so schnell wie möglich auf eine Version, die von CVE-2024-39719 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-39719 (Ollama)",
   "An issue was discovered in Ollama through 0.3.14. File existence disclosure can occur via api/create. When calling the CreateModel route with a path parameter that does not exist, it reflects the \"File does not exist\" error message to the attacker, providing a primitive for file existence on the server.",
   "Upgrade Ollama to a version not affected by CVE-2024-39719 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-39719 (Ollama)",
   "Descripción de NVD (texto original en inglés): An issue was discovered in Ollama through 0.3.14. File existence disclosure can occur via api/create. When calling the CreateModel route with a path parameter that does not exist, it reflects the \"File does not exist\" error message to the attacker, providing a primitive for file existence on the server.",
   "Actualice Ollama lo antes posible a una versión no afectada por CVE-2024-39719 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-39719 (Ollama)",
   "Description NVD (texte original en anglais) : An issue was discovered in Ollama through 0.3.14. File existence disclosure can occur via api/create. When calling the CreateModel route with a path parameter that does not exist, it reflects the \"File does not exist\" error message to the attacker, providing a primitive for file existence on the server.",
   "Mettez à niveau Ollama dès que possible vers une version non affectée par CVE-2024-39719 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-39719 (Ollama)",
   "Descrizione NVD (testo originale in inglese): An issue was discovered in Ollama through 0.3.14. File existence disclosure can occur via api/create. When calling the CreateModel route with a path parameter that does not exist, it reflects the \"File does not exist\" error message to the attacker, providing a primitive for file existence on the server.",
   "Aggiorna Ollama il prima possibile a una versione non interessata da CVE-2024-39719 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-39719 (Ollama)",
   "NVDの説明（英語原文）: An issue was discovered in Ollama through 0.3.14. File existence disclosure can occur via api/create. When calling the CreateModel route with a path parameter that does not exist, it reflects the \"File does not exist\" error message to the attacker, providing a primitive for file existence on the server.",
   "Ollama を CVE-2024-39719 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-39719 (Ollama)",
   "NVD 설명(영어 원문): An issue was discovered in Ollama through 0.3.14. File existence disclosure can occur via api/create. When calling the CreateModel route with a path parameter that does not exist, it reflects the \"File does not exist\" error message to the attacker, providing a primitive for file existence on the server.",
   "Ollama을(를) CVE-2024-39719의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-39719 (Ollama)",
   "Descrição do NVD (texto original em inglês): An issue was discovered in Ollama through 0.3.14. File existence disclosure can occur via api/create. When calling the CreateModel route with a path parameter that does not exist, it reflects the \"File does not exist\" error message to the attacker, providing a primitive for file existence on the server.",
   "Atualize o Ollama o quanto antes para uma versão não afetada por CVE-2024-39719 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-39719（Ollama）",
   "NVD 说明（英文原文）：An issue was discovered in Ollama through 0.3.14. File existence disclosure can occur via api/create. When calling the CreateModel route with a path parameter that does not exist, it reflects the \"File does not exist\" error message to the attacker, providing a primitive for file existence on the server.",
   "请尽快将 Ollama 升级到不受 CVE-2024-39719 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-39719（Ollama）",
   "NVD 說明（英文原文）：An issue was discovered in Ollama through 0.3.14. File existence disclosure can occur via api/create. When calling the CreateModel route with a path parameter that does not exist, it reflects the \"File does not exist\" error message to the attacker, providing a primitive for file existence on the server.",
   "請儘快將 Ollama 升級到不受 CVE-2024-39719 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:ollama-exposed:CVE-2024-39720": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-39720 (Ollama)",
   "NVD-Beschreibung (englischer Originaltext): An issue was discovered in Ollama before 0.1.46. An attacker can use two HTTP requests to upload a malformed GGUF file containing just 4 bytes starting with the GGUF custom magic header. By leveraging a custom Modelfile that includes a FROM statement pointing to the attacker-controlled blob file, the attacker can crash the application through the CreateModel route, leading to a segmentation fault (signal SIGSEGV: segmentation violation).",
   "Aktualisieren Sie Ollama so schnell wie möglich auf eine Version, die von CVE-2024-39720 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-39720 (Ollama)",
   "An issue was discovered in Ollama before 0.1.46. An attacker can use two HTTP requests to upload a malformed GGUF file containing just 4 bytes starting with the GGUF custom magic header. By leveraging a custom Modelfile that includes a FROM statement pointing to the attacker-controlled blob file, the attacker can crash the application through the CreateModel route, leading to a segmentation fault (signal SIGSEGV: segmentation violation).",
   "Upgrade Ollama to a version not affected by CVE-2024-39720 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-39720 (Ollama)",
   "Descripción de NVD (texto original en inglés): An issue was discovered in Ollama before 0.1.46. An attacker can use two HTTP requests to upload a malformed GGUF file containing just 4 bytes starting with the GGUF custom magic header. By leveraging a custom Modelfile that includes a FROM statement pointing to the attacker-controlled blob file, the attacker can crash the application through the CreateModel route, leading to a segmentation fault (signal SIGSEGV: segmentation violation).",
   "Actualice Ollama lo antes posible a una versión no afectada por CVE-2024-39720 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-39720 (Ollama)",
   "Description NVD (texte original en anglais) : An issue was discovered in Ollama before 0.1.46. An attacker can use two HTTP requests to upload a malformed GGUF file containing just 4 bytes starting with the GGUF custom magic header. By leveraging a custom Modelfile that includes a FROM statement pointing to the attacker-controlled blob file, the attacker can crash the application through the CreateModel route, leading to a segmentation fault (signal SIGSEGV: segmentation violation).",
   "Mettez à niveau Ollama dès que possible vers une version non affectée par CVE-2024-39720 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-39720 (Ollama)",
   "Descrizione NVD (testo originale in inglese): An issue was discovered in Ollama before 0.1.46. An attacker can use two HTTP requests to upload a malformed GGUF file containing just 4 bytes starting with the GGUF custom magic header. By leveraging a custom Modelfile that includes a FROM statement pointing to the attacker-controlled blob file, the attacker can crash the application through the CreateModel route, leading to a segmentation fault (signal SIGSEGV: segmentation violation).",
   "Aggiorna Ollama il prima possibile a una versione non interessata da CVE-2024-39720 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-39720 (Ollama)",
   "NVDの説明（英語原文）: An issue was discovered in Ollama before 0.1.46. An attacker can use two HTTP requests to upload a malformed GGUF file containing just 4 bytes starting with the GGUF custom magic header. By leveraging a custom Modelfile that includes a FROM statement pointing to the attacker-controlled blob file, the attacker can crash the application through the CreateModel route, leading to a segmentation fault (signal SIGSEGV: segmentation violation).",
   "Ollama を CVE-2024-39720 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-39720 (Ollama)",
   "NVD 설명(영어 원문): An issue was discovered in Ollama before 0.1.46. An attacker can use two HTTP requests to upload a malformed GGUF file containing just 4 bytes starting with the GGUF custom magic header. By leveraging a custom Modelfile that includes a FROM statement pointing to the attacker-controlled blob file, the attacker can crash the application through the CreateModel route, leading to a segmentation fault (signal SIGSEGV: segmentation violation).",
   "Ollama을(를) CVE-2024-39720의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-39720 (Ollama)",
   "Descrição do NVD (texto original em inglês): An issue was discovered in Ollama before 0.1.46. An attacker can use two HTTP requests to upload a malformed GGUF file containing just 4 bytes starting with the GGUF custom magic header. By leveraging a custom Modelfile that includes a FROM statement pointing to the attacker-controlled blob file, the attacker can crash the application through the CreateModel route, leading to a segmentation fault (signal SIGSEGV: segmentation violation).",
   "Atualize o Ollama o quanto antes para uma versão não afetada por CVE-2024-39720 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-39720（Ollama）",
   "NVD 说明（英文原文）：An issue was discovered in Ollama before 0.1.46. An attacker can use two HTTP requests to upload a malformed GGUF file containing just 4 bytes starting with the GGUF custom magic header. By leveraging a custom Modelfile that includes a FROM statement pointing to the attacker-controlled blob file, the attacker can crash the application through the CreateModel route, leading to a segmentation fault (signal SIGSEGV: segmentation violation).",
   "请尽快将 Ollama 升级到不受 CVE-2024-39720 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-39720（Ollama）",
   "NVD 說明（英文原文）：An issue was discovered in Ollama before 0.1.46. An attacker can use two HTTP requests to upload a malformed GGUF file containing just 4 bytes starting with the GGUF custom magic header. By leveraging a custom Modelfile that includes a FROM statement pointing to the attacker-controlled blob file, the attacker can crash the application through the CreateModel route, leading to a segmentation fault (signal SIGSEGV: segmentation violation).",
   "請儘快將 Ollama 升級到不受 CVE-2024-39720 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:ollama-exposed:CVE-2024-39721": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-39721 (Ollama)",
   "NVD-Beschreibung (englischer Originaltext): An issue was discovered in Ollama before 0.1.34. The CreateModelHandler function uses os.Open to read a file until completion. The req.Path parameter is user-controlled and can be set to /dev/random, which is blocking, causing the goroutine to run infinitely (even after the HTTP request is aborted by the client).",
   "Aktualisieren Sie Ollama so schnell wie möglich auf eine Version, die von CVE-2024-39721 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-39721 (Ollama)",
   "An issue was discovered in Ollama before 0.1.34. The CreateModelHandler function uses os.Open to read a file until completion. The req.Path parameter is user-controlled and can be set to /dev/random, which is blocking, causing the goroutine to run infinitely (even after the HTTP request is aborted by the client).",
   "Upgrade Ollama to a version not affected by CVE-2024-39721 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-39721 (Ollama)",
   "Descripción de NVD (texto original en inglés): An issue was discovered in Ollama before 0.1.34. The CreateModelHandler function uses os.Open to read a file until completion. The req.Path parameter is user-controlled and can be set to /dev/random, which is blocking, causing the goroutine to run infinitely (even after the HTTP request is aborted by the client).",
   "Actualice Ollama lo antes posible a una versión no afectada por CVE-2024-39721 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-39721 (Ollama)",
   "Description NVD (texte original en anglais) : An issue was discovered in Ollama before 0.1.34. The CreateModelHandler function uses os.Open to read a file until completion. The req.Path parameter is user-controlled and can be set to /dev/random, which is blocking, causing the goroutine to run infinitely (even after the HTTP request is aborted by the client).",
   "Mettez à niveau Ollama dès que possible vers une version non affectée par CVE-2024-39721 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-39721 (Ollama)",
   "Descrizione NVD (testo originale in inglese): An issue was discovered in Ollama before 0.1.34. The CreateModelHandler function uses os.Open to read a file until completion. The req.Path parameter is user-controlled and can be set to /dev/random, which is blocking, causing the goroutine to run infinitely (even after the HTTP request is aborted by the client).",
   "Aggiorna Ollama il prima possibile a una versione non interessata da CVE-2024-39721 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-39721 (Ollama)",
   "NVDの説明（英語原文）: An issue was discovered in Ollama before 0.1.34. The CreateModelHandler function uses os.Open to read a file until completion. The req.Path parameter is user-controlled and can be set to /dev/random, which is blocking, causing the goroutine to run infinitely (even after the HTTP request is aborted by the client).",
   "Ollama を CVE-2024-39721 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-39721 (Ollama)",
   "NVD 설명(영어 원문): An issue was discovered in Ollama before 0.1.34. The CreateModelHandler function uses os.Open to read a file until completion. The req.Path parameter is user-controlled and can be set to /dev/random, which is blocking, causing the goroutine to run infinitely (even after the HTTP request is aborted by the client).",
   "Ollama을(를) CVE-2024-39721의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-39721 (Ollama)",
   "Descrição do NVD (texto original em inglês): An issue was discovered in Ollama before 0.1.34. The CreateModelHandler function uses os.Open to read a file until completion. The req.Path parameter is user-controlled and can be set to /dev/random, which is blocking, causing the goroutine to run infinitely (even after the HTTP request is aborted by the client).",
   "Atualize o Ollama o quanto antes para uma versão não afetada por CVE-2024-39721 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-39721（Ollama）",
   "NVD 说明（英文原文）：An issue was discovered in Ollama before 0.1.34. The CreateModelHandler function uses os.Open to read a file until completion. The req.Path parameter is user-controlled and can be set to /dev/random, which is blocking, causing the goroutine to run infinitely (even after the HTTP request is aborted by the client).",
   "请尽快将 Ollama 升级到不受 CVE-2024-39721 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-39721（Ollama）",
   "NVD 說明（英文原文）：An issue was discovered in Ollama before 0.1.34. The CreateModelHandler function uses os.Open to read a file until completion. The req.Path parameter is user-controlled and can be set to /dev/random, which is blocking, causing the goroutine to run infinitely (even after the HTTP request is aborted by the client).",
   "請儘快將 Ollama 升級到不受 CVE-2024-39721 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:ollama-exposed:CVE-2024-39722": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-39722 (Ollama)",
   "NVD-Beschreibung (englischer Originaltext): An issue was discovered in Ollama before 0.1.46. It exposes which files exist on the server on which it is deployed via path traversal in the api/push route.",
   "Aktualisieren Sie Ollama so schnell wie möglich auf eine Version, die von CVE-2024-39722 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-39722 (Ollama)",
   "An issue was discovered in Ollama before 0.1.46. It exposes which files exist on the server on which it is deployed via path traversal in the api/push route.",
   "Upgrade Ollama to a version not affected by CVE-2024-39722 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-39722 (Ollama)",
   "Descripción de NVD (texto original en inglés): An issue was discovered in Ollama before 0.1.46. It exposes which files exist on the server on which it is deployed via path traversal in the api/push route.",
   "Actualice Ollama lo antes posible a una versión no afectada por CVE-2024-39722 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-39722 (Ollama)",
   "Description NVD (texte original en anglais) : An issue was discovered in Ollama before 0.1.46. It exposes which files exist on the server on which it is deployed via path traversal in the api/push route.",
   "Mettez à niveau Ollama dès que possible vers une version non affectée par CVE-2024-39722 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-39722 (Ollama)",
   "Descrizione NVD (testo originale in inglese): An issue was discovered in Ollama before 0.1.46. It exposes which files exist on the server on which it is deployed via path traversal in the api/push route.",
   "Aggiorna Ollama il prima possibile a una versione non interessata da CVE-2024-39722 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-39722 (Ollama)",
   "NVDの説明（英語原文）: An issue was discovered in Ollama before 0.1.46. It exposes which files exist on the server on which it is deployed via path traversal in the api/push route.",
   "Ollama を CVE-2024-39722 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-39722 (Ollama)",
   "NVD 설명(영어 원문): An issue was discovered in Ollama before 0.1.46. It exposes which files exist on the server on which it is deployed via path traversal in the api/push route.",
   "Ollama을(를) CVE-2024-39722의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-39722 (Ollama)",
   "Descrição do NVD (texto original em inglês): An issue was discovered in Ollama before 0.1.46. It exposes which files exist on the server on which it is deployed via path traversal in the api/push route.",
   "Atualize o Ollama o quanto antes para uma versão não afetada por CVE-2024-39722 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-39722（Ollama）",
   "NVD 说明（英文原文）：An issue was discovered in Ollama before 0.1.46. It exposes which files exist on the server on which it is deployed via path traversal in the api/push route.",
   "请尽快将 Ollama 升级到不受 CVE-2024-39722 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-39722（Ollama）",
   "NVD 說明（英文原文）：An issue was discovered in Ollama before 0.1.46. It exposes which files exist on the server on which it is deployed via path traversal in the api/push route.",
   "請儘快將 Ollama 升級到不受 CVE-2024-39722 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:ollama-exposed:CVE-2024-45436": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-45436 (Ollama)",
   "NVD-Beschreibung (englischer Originaltext): extractFromZipFile in model.go in Ollama before 0.1.47 can extract members of a ZIP archive outside of the parent directory.",
   "Aktualisieren Sie Ollama so schnell wie möglich auf eine Version, die von CVE-2024-45436 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-45436 (Ollama)",
   "extractFromZipFile in model.go in Ollama before 0.1.47 can extract members of a ZIP archive outside of the parent directory.",
   "Upgrade Ollama to a version not affected by CVE-2024-45436 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-45436 (Ollama)",
   "Descripción de NVD (texto original en inglés): extractFromZipFile in model.go in Ollama before 0.1.47 can extract members of a ZIP archive outside of the parent directory.",
   "Actualice Ollama lo antes posible a una versión no afectada por CVE-2024-45436 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-45436 (Ollama)",
   "Description NVD (texte original en anglais) : extractFromZipFile in model.go in Ollama before 0.1.47 can extract members of a ZIP archive outside of the parent directory.",
   "Mettez à niveau Ollama dès que possible vers une version non affectée par CVE-2024-45436 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-45436 (Ollama)",
   "Descrizione NVD (testo originale in inglese): extractFromZipFile in model.go in Ollama before 0.1.47 can extract members of a ZIP archive outside of the parent directory.",
   "Aggiorna Ollama il prima possibile a una versione non interessata da CVE-2024-45436 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-45436 (Ollama)",
   "NVDの説明（英語原文）: extractFromZipFile in model.go in Ollama before 0.1.47 can extract members of a ZIP archive outside of the parent directory.",
   "Ollama を CVE-2024-45436 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-45436 (Ollama)",
   "NVD 설명(영어 원문): extractFromZipFile in model.go in Ollama before 0.1.47 can extract members of a ZIP archive outside of the parent directory.",
   "Ollama을(를) CVE-2024-45436의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-45436 (Ollama)",
   "Descrição do NVD (texto original em inglês): extractFromZipFile in model.go in Ollama before 0.1.47 can extract members of a ZIP archive outside of the parent directory.",
   "Atualize o Ollama o quanto antes para uma versão não afetada por CVE-2024-45436 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-45436（Ollama）",
   "NVD 说明（英文原文）：extractFromZipFile in model.go in Ollama before 0.1.47 can extract members of a ZIP archive outside of the parent directory.",
   "请尽快将 Ollama 升级到不受 CVE-2024-45436 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-45436（Ollama）",
   "NVD 說明（英文原文）：extractFromZipFile in model.go in Ollama before 0.1.47 can extract members of a ZIP archive outside of the parent directory.",
   "請儘快將 Ollama 升級到不受 CVE-2024-45436 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:ollama-exposed:CVE-2024-8063": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-8063 (Ollama)",
   "NVD-Beschreibung (englischer Originaltext): A divide by zero vulnerability exists in ollama/ollama version v0.3.3. The vulnerability occurs when importing GGUF models with a crafted type for `block_count` in the Modelfile. This can lead to a denial of service (DoS) condition when the server processes the model, causing it to crash.",
   "Aktualisieren Sie Ollama so schnell wie möglich auf eine Version, die von CVE-2024-8063 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-8063 (Ollama)",
   "A divide by zero vulnerability exists in ollama/ollama version v0.3.3. The vulnerability occurs when importing GGUF models with a crafted type for `block_count` in the Modelfile. This can lead to a denial of service (DoS) condition when the server processes the model, causing it to crash.",
   "Upgrade Ollama to a version not affected by CVE-2024-8063 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-8063 (Ollama)",
   "Descripción de NVD (texto original en inglés): A divide by zero vulnerability exists in ollama/ollama version v0.3.3. The vulnerability occurs when importing GGUF models with a crafted type for `block_count` in the Modelfile. This can lead to a denial of service (DoS) condition when the server processes the model, causing it to crash.",
   "Actualice Ollama lo antes posible a una versión no afectada por CVE-2024-8063 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-8063 (Ollama)",
   "Description NVD (texte original en anglais) : A divide by zero vulnerability exists in ollama/ollama version v0.3.3. The vulnerability occurs when importing GGUF models with a crafted type for `block_count` in the Modelfile. This can lead to a denial of service (DoS) condition when the server processes the model, causing it to crash.",
   "Mettez à niveau Ollama dès que possible vers une version non affectée par CVE-2024-8063 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-8063 (Ollama)",
   "Descrizione NVD (testo originale in inglese): A divide by zero vulnerability exists in ollama/ollama version v0.3.3. The vulnerability occurs when importing GGUF models with a crafted type for `block_count` in the Modelfile. This can lead to a denial of service (DoS) condition when the server processes the model, causing it to crash.",
   "Aggiorna Ollama il prima possibile a una versione non interessata da CVE-2024-8063 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-8063 (Ollama)",
   "NVDの説明（英語原文）: A divide by zero vulnerability exists in ollama/ollama version v0.3.3. The vulnerability occurs when importing GGUF models with a crafted type for `block_count` in the Modelfile. This can lead to a denial of service (DoS) condition when the server processes the model, causing it to crash.",
   "Ollama を CVE-2024-8063 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-8063 (Ollama)",
   "NVD 설명(영어 원문): A divide by zero vulnerability exists in ollama/ollama version v0.3.3. The vulnerability occurs when importing GGUF models with a crafted type for `block_count` in the Modelfile. This can lead to a denial of service (DoS) condition when the server processes the model, causing it to crash.",
   "Ollama을(를) CVE-2024-8063의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-8063 (Ollama)",
   "Descrição do NVD (texto original em inglês): A divide by zero vulnerability exists in ollama/ollama version v0.3.3. The vulnerability occurs when importing GGUF models with a crafted type for `block_count` in the Modelfile. This can lead to a denial of service (DoS) condition when the server processes the model, causing it to crash.",
   "Atualize o Ollama o quanto antes para uma versão não afetada por CVE-2024-8063 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-8063（Ollama）",
   "NVD 说明（英文原文）：A divide by zero vulnerability exists in ollama/ollama version v0.3.3. The vulnerability occurs when importing GGUF models with a crafted type for `block_count` in the Modelfile. This can lead to a denial of service (DoS) condition when the server processes the model, causing it to crash.",
   "请尽快将 Ollama 升级到不受 CVE-2024-8063 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-8063（Ollama）",
   "NVD 說明（英文原文）：A divide by zero vulnerability exists in ollama/ollama version v0.3.3. The vulnerability occurs when importing GGUF models with a crafted type for `block_count` in the Modelfile. This can lead to a denial of service (DoS) condition when the server processes the model, causing it to crash.",
   "請儘快將 Ollama 升級到不受 CVE-2024-8063 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:ollama-exposed:CVE-2025-0312": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-0312 (Ollama)",
   "NVD-Beschreibung (englischer Originaltext): A vulnerability in ollama/ollama versions <=0.3.14 allows a malicious user to create a customized GGUF model file that, when uploaded and created on the Ollama server, can cause a crash due to an unchecked null pointer dereference. This can lead to a Denial of Service (DoS) attack via remote network.",
   "Aktualisieren Sie Ollama so schnell wie möglich auf eine Version, die von CVE-2025-0312 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-0312 (Ollama)",
   "A vulnerability in ollama/ollama versions <=0.3.14 allows a malicious user to create a customized GGUF model file that, when uploaded and created on the Ollama server, can cause a crash due to an unchecked null pointer dereference. This can lead to a Denial of Service (DoS) attack via remote network.",
   "Upgrade Ollama to a version not affected by CVE-2025-0312 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-0312 (Ollama)",
   "Descripción de NVD (texto original en inglés): A vulnerability in ollama/ollama versions <=0.3.14 allows a malicious user to create a customized GGUF model file that, when uploaded and created on the Ollama server, can cause a crash due to an unchecked null pointer dereference. This can lead to a Denial of Service (DoS) attack via remote network.",
   "Actualice Ollama lo antes posible a una versión no afectada por CVE-2025-0312 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-0312 (Ollama)",
   "Description NVD (texte original en anglais) : A vulnerability in ollama/ollama versions <=0.3.14 allows a malicious user to create a customized GGUF model file that, when uploaded and created on the Ollama server, can cause a crash due to an unchecked null pointer dereference. This can lead to a Denial of Service (DoS) attack via remote network.",
   "Mettez à niveau Ollama dès que possible vers une version non affectée par CVE-2025-0312 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-0312 (Ollama)",
   "Descrizione NVD (testo originale in inglese): A vulnerability in ollama/ollama versions <=0.3.14 allows a malicious user to create a customized GGUF model file that, when uploaded and created on the Ollama server, can cause a crash due to an unchecked null pointer dereference. This can lead to a Denial of Service (DoS) attack via remote network.",
   "Aggiorna Ollama il prima possibile a una versione non interessata da CVE-2025-0312 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-0312 (Ollama)",
   "NVDの説明（英語原文）: A vulnerability in ollama/ollama versions <=0.3.14 allows a malicious user to create a customized GGUF model file that, when uploaded and created on the Ollama server, can cause a crash due to an unchecked null pointer dereference. This can lead to a Denial of Service (DoS) attack via remote network.",
   "Ollama を CVE-2025-0312 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-0312 (Ollama)",
   "NVD 설명(영어 원문): A vulnerability in ollama/ollama versions <=0.3.14 allows a malicious user to create a customized GGUF model file that, when uploaded and created on the Ollama server, can cause a crash due to an unchecked null pointer dereference. This can lead to a Denial of Service (DoS) attack via remote network.",
   "Ollama을(를) CVE-2025-0312의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-0312 (Ollama)",
   "Descrição do NVD (texto original em inglês): A vulnerability in ollama/ollama versions <=0.3.14 allows a malicious user to create a customized GGUF model file that, when uploaded and created on the Ollama server, can cause a crash due to an unchecked null pointer dereference. This can lead to a Denial of Service (DoS) attack via remote network.",
   "Atualize o Ollama o quanto antes para uma versão não afetada por CVE-2025-0312 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-0312（Ollama）",
   "NVD 说明（英文原文）：A vulnerability in ollama/ollama versions <=0.3.14 allows a malicious user to create a customized GGUF model file that, when uploaded and created on the Ollama server, can cause a crash due to an unchecked null pointer dereference. This can lead to a Denial of Service (DoS) attack via remote network.",
   "请尽快将 Ollama 升级到不受 CVE-2025-0312 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-0312（Ollama）",
   "NVD 說明（英文原文）：A vulnerability in ollama/ollama versions <=0.3.14 allows a malicious user to create a customized GGUF model file that, when uploaded and created on the Ollama server, can cause a crash due to an unchecked null pointer dereference. This can lead to a Denial of Service (DoS) attack via remote network.",
   "請儘快將 Ollama 升級到不受 CVE-2025-0312 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:ollama-exposed:CVE-2025-0315": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-0315 (Ollama)",
   "NVD-Beschreibung (englischer Originaltext): A vulnerability in ollama/ollama <=0.3.14 allows a malicious user to create a customized GGUF model file, upload it to the Ollama server, and create it. This can cause the server to allocate unlimited memory, leading to a Denial of Service (DoS) attack.",
   "Aktualisieren Sie Ollama so schnell wie möglich auf eine Version, die von CVE-2025-0315 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-0315 (Ollama)",
   "A vulnerability in ollama/ollama <=0.3.14 allows a malicious user to create a customized GGUF model file, upload it to the Ollama server, and create it. This can cause the server to allocate unlimited memory, leading to a Denial of Service (DoS) attack.",
   "Upgrade Ollama to a version not affected by CVE-2025-0315 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-0315 (Ollama)",
   "Descripción de NVD (texto original en inglés): A vulnerability in ollama/ollama <=0.3.14 allows a malicious user to create a customized GGUF model file, upload it to the Ollama server, and create it. This can cause the server to allocate unlimited memory, leading to a Denial of Service (DoS) attack.",
   "Actualice Ollama lo antes posible a una versión no afectada por CVE-2025-0315 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-0315 (Ollama)",
   "Description NVD (texte original en anglais) : A vulnerability in ollama/ollama <=0.3.14 allows a malicious user to create a customized GGUF model file, upload it to the Ollama server, and create it. This can cause the server to allocate unlimited memory, leading to a Denial of Service (DoS) attack.",
   "Mettez à niveau Ollama dès que possible vers une version non affectée par CVE-2025-0315 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-0315 (Ollama)",
   "Descrizione NVD (testo originale in inglese): A vulnerability in ollama/ollama <=0.3.14 allows a malicious user to create a customized GGUF model file, upload it to the Ollama server, and create it. This can cause the server to allocate unlimited memory, leading to a Denial of Service (DoS) attack.",
   "Aggiorna Ollama il prima possibile a una versione non interessata da CVE-2025-0315 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-0315 (Ollama)",
   "NVDの説明（英語原文）: A vulnerability in ollama/ollama <=0.3.14 allows a malicious user to create a customized GGUF model file, upload it to the Ollama server, and create it. This can cause the server to allocate unlimited memory, leading to a Denial of Service (DoS) attack.",
   "Ollama を CVE-2025-0315 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-0315 (Ollama)",
   "NVD 설명(영어 원문): A vulnerability in ollama/ollama <=0.3.14 allows a malicious user to create a customized GGUF model file, upload it to the Ollama server, and create it. This can cause the server to allocate unlimited memory, leading to a Denial of Service (DoS) attack.",
   "Ollama을(를) CVE-2025-0315의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-0315 (Ollama)",
   "Descrição do NVD (texto original em inglês): A vulnerability in ollama/ollama <=0.3.14 allows a malicious user to create a customized GGUF model file, upload it to the Ollama server, and create it. This can cause the server to allocate unlimited memory, leading to a Denial of Service (DoS) attack.",
   "Atualize o Ollama o quanto antes para uma versão não afetada por CVE-2025-0315 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-0315（Ollama）",
   "NVD 说明（英文原文）：A vulnerability in ollama/ollama <=0.3.14 allows a malicious user to create a customized GGUF model file, upload it to the Ollama server, and create it. This can cause the server to allocate unlimited memory, leading to a Denial of Service (DoS) attack.",
   "请尽快将 Ollama 升级到不受 CVE-2025-0315 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-0315（Ollama）",
   "NVD 說明（英文原文）：A vulnerability in ollama/ollama <=0.3.14 allows a malicious user to create a customized GGUF model file, upload it to the Ollama server, and create it. This can cause the server to allocate unlimited memory, leading to a Denial of Service (DoS) attack.",
   "請儘快將 Ollama 升級到不受 CVE-2025-0315 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:ollama-exposed:CVE-2025-0317": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-0317 (Ollama)",
   "NVD-Beschreibung (englischer Originaltext): A vulnerability in ollama/ollama versions <=0.3.14 allows a malicious user to upload and create a customized GGUF model file on the Ollama server. This can lead to a division by zero error in the ggufPadding function, causing the server to crash and resulting in a Denial of Service (DoS) attack.",
   "Aktualisieren Sie Ollama so schnell wie möglich auf eine Version, die von CVE-2025-0317 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-0317 (Ollama)",
   "A vulnerability in ollama/ollama versions <=0.3.14 allows a malicious user to upload and create a customized GGUF model file on the Ollama server. This can lead to a division by zero error in the ggufPadding function, causing the server to crash and resulting in a Denial of Service (DoS) attack.",
   "Upgrade Ollama to a version not affected by CVE-2025-0317 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-0317 (Ollama)",
   "Descripción de NVD (texto original en inglés): A vulnerability in ollama/ollama versions <=0.3.14 allows a malicious user to upload and create a customized GGUF model file on the Ollama server. This can lead to a division by zero error in the ggufPadding function, causing the server to crash and resulting in a Denial of Service (DoS) attack.",
   "Actualice Ollama lo antes posible a una versión no afectada por CVE-2025-0317 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-0317 (Ollama)",
   "Description NVD (texte original en anglais) : A vulnerability in ollama/ollama versions <=0.3.14 allows a malicious user to upload and create a customized GGUF model file on the Ollama server. This can lead to a division by zero error in the ggufPadding function, causing the server to crash and resulting in a Denial of Service (DoS) attack.",
   "Mettez à niveau Ollama dès que possible vers une version non affectée par CVE-2025-0317 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-0317 (Ollama)",
   "Descrizione NVD (testo originale in inglese): A vulnerability in ollama/ollama versions <=0.3.14 allows a malicious user to upload and create a customized GGUF model file on the Ollama server. This can lead to a division by zero error in the ggufPadding function, causing the server to crash and resulting in a Denial of Service (DoS) attack.",
   "Aggiorna Ollama il prima possibile a una versione non interessata da CVE-2025-0317 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-0317 (Ollama)",
   "NVDの説明（英語原文）: A vulnerability in ollama/ollama versions <=0.3.14 allows a malicious user to upload and create a customized GGUF model file on the Ollama server. This can lead to a division by zero error in the ggufPadding function, causing the server to crash and resulting in a Denial of Service (DoS) attack.",
   "Ollama を CVE-2025-0317 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-0317 (Ollama)",
   "NVD 설명(영어 원문): A vulnerability in ollama/ollama versions <=0.3.14 allows a malicious user to upload and create a customized GGUF model file on the Ollama server. This can lead to a division by zero error in the ggufPadding function, causing the server to crash and resulting in a Denial of Service (DoS) attack.",
   "Ollama을(를) CVE-2025-0317의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-0317 (Ollama)",
   "Descrição do NVD (texto original em inglês): A vulnerability in ollama/ollama versions <=0.3.14 allows a malicious user to upload and create a customized GGUF model file on the Ollama server. This can lead to a division by zero error in the ggufPadding function, causing the server to crash and resulting in a Denial of Service (DoS) attack.",
   "Atualize o Ollama o quanto antes para uma versão não afetada por CVE-2025-0317 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-0317（Ollama）",
   "NVD 说明（英文原文）：A vulnerability in ollama/ollama versions <=0.3.14 allows a malicious user to upload and create a customized GGUF model file on the Ollama server. This can lead to a division by zero error in the ggufPadding function, causing the server to crash and resulting in a Denial of Service (DoS) attack.",
   "请尽快将 Ollama 升级到不受 CVE-2025-0317 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-0317（Ollama）",
   "NVD 說明（英文原文）：A vulnerability in ollama/ollama versions <=0.3.14 allows a malicious user to upload and create a customized GGUF model file on the Ollama server. This can lead to a division by zero error in the ggufPadding function, causing the server to crash and resulting in a Denial of Service (DoS) attack.",
   "請儘快將 Ollama 升級到不受 CVE-2025-0317 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:ollama-exposed:CVE-2025-15514": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-15514 (Ollama)",
   "NVD-Beschreibung (englischer Originaltext): Ollama 0.11.5-rc0 through current version 0.13.5 contain a null pointer dereference vulnerability in the multi-modal model image processing functionality. When processing base64-encoded image data via the /api/chat endpoint, the application fails to validate that the decoded data represents valid media before passing it to the mtmd_helper_bitmap_init_from_buf function. This function can return NULL for malformed input, but the code does not check this return value before dereferencing the pointe",
   "Aktualisieren Sie Ollama so schnell wie möglich auf eine Version, die von CVE-2025-15514 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-15514 (Ollama)",
   "Ollama 0.11.5-rc0 through current version 0.13.5 contain a null pointer dereference vulnerability in the multi-modal model image processing functionality. When processing base64-encoded image data via the /api/chat endpoint, the application fails to validate that the decoded data represents valid media before passing it to the mtmd_helper_bitmap_init_from_buf function. This function can return NULL for malformed input, but the code does not check this return value before dereferencing the pointe",
   "Upgrade Ollama to a version not affected by CVE-2025-15514 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-15514 (Ollama)",
   "Descripción de NVD (texto original en inglés): Ollama 0.11.5-rc0 through current version 0.13.5 contain a null pointer dereference vulnerability in the multi-modal model image processing functionality. When processing base64-encoded image data via the /api/chat endpoint, the application fails to validate that the decoded data represents valid media before passing it to the mtmd_helper_bitmap_init_from_buf function. This function can return NULL for malformed input, but the code does not check this return value before dereferencing the pointe",
   "Actualice Ollama lo antes posible a una versión no afectada por CVE-2025-15514 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-15514 (Ollama)",
   "Description NVD (texte original en anglais) : Ollama 0.11.5-rc0 through current version 0.13.5 contain a null pointer dereference vulnerability in the multi-modal model image processing functionality. When processing base64-encoded image data via the /api/chat endpoint, the application fails to validate that the decoded data represents valid media before passing it to the mtmd_helper_bitmap_init_from_buf function. This function can return NULL for malformed input, but the code does not check this return value before dereferencing the pointe",
   "Mettez à niveau Ollama dès que possible vers une version non affectée par CVE-2025-15514 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-15514 (Ollama)",
   "Descrizione NVD (testo originale in inglese): Ollama 0.11.5-rc0 through current version 0.13.5 contain a null pointer dereference vulnerability in the multi-modal model image processing functionality. When processing base64-encoded image data via the /api/chat endpoint, the application fails to validate that the decoded data represents valid media before passing it to the mtmd_helper_bitmap_init_from_buf function. This function can return NULL for malformed input, but the code does not check this return value before dereferencing the pointe",
   "Aggiorna Ollama il prima possibile a una versione non interessata da CVE-2025-15514 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-15514 (Ollama)",
   "NVDの説明（英語原文）: Ollama 0.11.5-rc0 through current version 0.13.5 contain a null pointer dereference vulnerability in the multi-modal model image processing functionality. When processing base64-encoded image data via the /api/chat endpoint, the application fails to validate that the decoded data represents valid media before passing it to the mtmd_helper_bitmap_init_from_buf function. This function can return NULL for malformed input, but the code does not check this return value before dereferencing the pointe",
   "Ollama を CVE-2025-15514 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-15514 (Ollama)",
   "NVD 설명(영어 원문): Ollama 0.11.5-rc0 through current version 0.13.5 contain a null pointer dereference vulnerability in the multi-modal model image processing functionality. When processing base64-encoded image data via the /api/chat endpoint, the application fails to validate that the decoded data represents valid media before passing it to the mtmd_helper_bitmap_init_from_buf function. This function can return NULL for malformed input, but the code does not check this return value before dereferencing the pointe",
   "Ollama을(를) CVE-2025-15514의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-15514 (Ollama)",
   "Descrição do NVD (texto original em inglês): Ollama 0.11.5-rc0 through current version 0.13.5 contain a null pointer dereference vulnerability in the multi-modal model image processing functionality. When processing base64-encoded image data via the /api/chat endpoint, the application fails to validate that the decoded data represents valid media before passing it to the mtmd_helper_bitmap_init_from_buf function. This function can return NULL for malformed input, but the code does not check this return value before dereferencing the pointe",
   "Atualize o Ollama o quanto antes para uma versão não afetada por CVE-2025-15514 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-15514（Ollama）",
   "NVD 说明（英文原文）：Ollama 0.11.5-rc0 through current version 0.13.5 contain a null pointer dereference vulnerability in the multi-modal model image processing functionality. When processing base64-encoded image data via the /api/chat endpoint, the application fails to validate that the decoded data represents valid media before passing it to the mtmd_helper_bitmap_init_from_buf function. This function can return NULL for malformed input, but the code does not check this return value before dereferencing the pointe",
   "请尽快将 Ollama 升级到不受 CVE-2025-15514 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-15514（Ollama）",
   "NVD 說明（英文原文）：Ollama 0.11.5-rc0 through current version 0.13.5 contain a null pointer dereference vulnerability in the multi-modal model image processing functionality. When processing base64-encoded image data via the /api/chat endpoint, the application fails to validate that the decoded data represents valid media before passing it to the mtmd_helper_bitmap_init_from_buf function. This function can return NULL for malformed input, but the code does not check this return value before dereferencing the pointe",
   "請儘快將 Ollama 升級到不受 CVE-2025-15514 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:ollama-exposed:CVE-2025-1975": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-1975 (Ollama)",
   "NVD-Beschreibung (englischer Originaltext): A vulnerability in the Ollama server version 0.5.11 allows a malicious user to cause a Denial of Service (DoS) attack by customizing the manifest content and spoofing a service. This is due to improper validation of array index access when downloading a model via the /api/pull endpoint, which can lead to a server crash.",
   "Aktualisieren Sie Ollama so schnell wie möglich auf eine Version, die von CVE-2025-1975 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-1975 (Ollama)",
   "A vulnerability in the Ollama server version 0.5.11 allows a malicious user to cause a Denial of Service (DoS) attack by customizing the manifest content and spoofing a service. This is due to improper validation of array index access when downloading a model via the /api/pull endpoint, which can lead to a server crash.",
   "Upgrade Ollama to a version not affected by CVE-2025-1975 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-1975 (Ollama)",
   "Descripción de NVD (texto original en inglés): A vulnerability in the Ollama server version 0.5.11 allows a malicious user to cause a Denial of Service (DoS) attack by customizing the manifest content and spoofing a service. This is due to improper validation of array index access when downloading a model via the /api/pull endpoint, which can lead to a server crash.",
   "Actualice Ollama lo antes posible a una versión no afectada por CVE-2025-1975 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-1975 (Ollama)",
   "Description NVD (texte original en anglais) : A vulnerability in the Ollama server version 0.5.11 allows a malicious user to cause a Denial of Service (DoS) attack by customizing the manifest content and spoofing a service. This is due to improper validation of array index access when downloading a model via the /api/pull endpoint, which can lead to a server crash.",
   "Mettez à niveau Ollama dès que possible vers une version non affectée par CVE-2025-1975 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-1975 (Ollama)",
   "Descrizione NVD (testo originale in inglese): A vulnerability in the Ollama server version 0.5.11 allows a malicious user to cause a Denial of Service (DoS) attack by customizing the manifest content and spoofing a service. This is due to improper validation of array index access when downloading a model via the /api/pull endpoint, which can lead to a server crash.",
   "Aggiorna Ollama il prima possibile a una versione non interessata da CVE-2025-1975 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-1975 (Ollama)",
   "NVDの説明（英語原文）: A vulnerability in the Ollama server version 0.5.11 allows a malicious user to cause a Denial of Service (DoS) attack by customizing the manifest content and spoofing a service. This is due to improper validation of array index access when downloading a model via the /api/pull endpoint, which can lead to a server crash.",
   "Ollama を CVE-2025-1975 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-1975 (Ollama)",
   "NVD 설명(영어 원문): A vulnerability in the Ollama server version 0.5.11 allows a malicious user to cause a Denial of Service (DoS) attack by customizing the manifest content and spoofing a service. This is due to improper validation of array index access when downloading a model via the /api/pull endpoint, which can lead to a server crash.",
   "Ollama을(를) CVE-2025-1975의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-1975 (Ollama)",
   "Descrição do NVD (texto original em inglês): A vulnerability in the Ollama server version 0.5.11 allows a malicious user to cause a Denial of Service (DoS) attack by customizing the manifest content and spoofing a service. This is due to improper validation of array index access when downloading a model via the /api/pull endpoint, which can lead to a server crash.",
   "Atualize o Ollama o quanto antes para uma versão não afetada por CVE-2025-1975 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-1975（Ollama）",
   "NVD 说明（英文原文）：A vulnerability in the Ollama server version 0.5.11 allows a malicious user to cause a Denial of Service (DoS) attack by customizing the manifest content and spoofing a service. This is due to improper validation of array index access when downloading a model via the /api/pull endpoint, which can lead to a server crash.",
   "请尽快将 Ollama 升级到不受 CVE-2025-1975 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-1975（Ollama）",
   "NVD 說明（英文原文）：A vulnerability in the Ollama server version 0.5.11 allows a malicious user to cause a Denial of Service (DoS) attack by customizing the manifest content and spoofing a service. This is due to improper validation of array index access when downloading a model via the /api/pull endpoint, which can lead to a server crash.",
   "請儘快將 Ollama 升級到不受 CVE-2025-1975 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:ollama-exposed:CVE-2025-63389": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-63389 (Ollama)",
   "NVD-Beschreibung (englischer Originaltext): A critical authentication bypass vulnerability exists in Ollama platform's API endpoints in versions prior to and including v0.12.3. The platform exposes multiple API endpoints without requiring authentication, enabling remote attackers to perform unauthorized model management operations.",
   "Aktualisieren Sie Ollama so schnell wie möglich auf eine Version, die von CVE-2025-63389 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-63389 (Ollama)",
   "A critical authentication bypass vulnerability exists in Ollama platform's API endpoints in versions prior to and including v0.12.3. The platform exposes multiple API endpoints without requiring authentication, enabling remote attackers to perform unauthorized model management operations.",
   "Upgrade Ollama to a version not affected by CVE-2025-63389 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-63389 (Ollama)",
   "Descripción de NVD (texto original en inglés): A critical authentication bypass vulnerability exists in Ollama platform's API endpoints in versions prior to and including v0.12.3. The platform exposes multiple API endpoints without requiring authentication, enabling remote attackers to perform unauthorized model management operations.",
   "Actualice Ollama lo antes posible a una versión no afectada por CVE-2025-63389 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-63389 (Ollama)",
   "Description NVD (texte original en anglais) : A critical authentication bypass vulnerability exists in Ollama platform's API endpoints in versions prior to and including v0.12.3. The platform exposes multiple API endpoints without requiring authentication, enabling remote attackers to perform unauthorized model management operations.",
   "Mettez à niveau Ollama dès que possible vers une version non affectée par CVE-2025-63389 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-63389 (Ollama)",
   "Descrizione NVD (testo originale in inglese): A critical authentication bypass vulnerability exists in Ollama platform's API endpoints in versions prior to and including v0.12.3. The platform exposes multiple API endpoints without requiring authentication, enabling remote attackers to perform unauthorized model management operations.",
   "Aggiorna Ollama il prima possibile a una versione non interessata da CVE-2025-63389 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-63389 (Ollama)",
   "NVDの説明（英語原文）: A critical authentication bypass vulnerability exists in Ollama platform's API endpoints in versions prior to and including v0.12.3. The platform exposes multiple API endpoints without requiring authentication, enabling remote attackers to perform unauthorized model management operations.",
   "Ollama を CVE-2025-63389 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-63389 (Ollama)",
   "NVD 설명(영어 원문): A critical authentication bypass vulnerability exists in Ollama platform's API endpoints in versions prior to and including v0.12.3. The platform exposes multiple API endpoints without requiring authentication, enabling remote attackers to perform unauthorized model management operations.",
   "Ollama을(를) CVE-2025-63389의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-63389 (Ollama)",
   "Descrição do NVD (texto original em inglês): A critical authentication bypass vulnerability exists in Ollama platform's API endpoints in versions prior to and including v0.12.3. The platform exposes multiple API endpoints without requiring authentication, enabling remote attackers to perform unauthorized model management operations.",
   "Atualize o Ollama o quanto antes para uma versão não afetada por CVE-2025-63389 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-63389（Ollama）",
   "NVD 说明（英文原文）：A critical authentication bypass vulnerability exists in Ollama platform's API endpoints in versions prior to and including v0.12.3. The platform exposes multiple API endpoints without requiring authentication, enabling remote attackers to perform unauthorized model management operations.",
   "请尽快将 Ollama 升级到不受 CVE-2025-63389 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-63389（Ollama）",
   "NVD 說明（英文原文）：A critical authentication bypass vulnerability exists in Ollama platform's API endpoints in versions prior to and including v0.12.3. The platform exposes multiple API endpoints without requiring authentication, enabling remote attackers to perform unauthorized model management operations.",
   "請儘快將 Ollama 升級到不受 CVE-2025-63389 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:ollama-exposed:CVE-2025-66959": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-66959 (Ollama)",
   "NVD-Beschreibung (englischer Originaltext): An issue in ollama v.0.12.10 allows a remote attacker to cause a denial of service via the GGUF decoder",
   "Aktualisieren Sie Ollama so schnell wie möglich auf eine Version, die von CVE-2025-66959 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-66959 (Ollama)",
   "An issue in ollama v.0.12.10 allows a remote attacker to cause a denial of service via the GGUF decoder",
   "Upgrade Ollama to a version not affected by CVE-2025-66959 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-66959 (Ollama)",
   "Descripción de NVD (texto original en inglés): An issue in ollama v.0.12.10 allows a remote attacker to cause a denial of service via the GGUF decoder",
   "Actualice Ollama lo antes posible a una versión no afectada por CVE-2025-66959 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-66959 (Ollama)",
   "Description NVD (texte original en anglais) : An issue in ollama v.0.12.10 allows a remote attacker to cause a denial of service via the GGUF decoder",
   "Mettez à niveau Ollama dès que possible vers une version non affectée par CVE-2025-66959 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-66959 (Ollama)",
   "Descrizione NVD (testo originale in inglese): An issue in ollama v.0.12.10 allows a remote attacker to cause a denial of service via the GGUF decoder",
   "Aggiorna Ollama il prima possibile a una versione non interessata da CVE-2025-66959 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-66959 (Ollama)",
   "NVDの説明（英語原文）: An issue in ollama v.0.12.10 allows a remote attacker to cause a denial of service via the GGUF decoder",
   "Ollama を CVE-2025-66959 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-66959 (Ollama)",
   "NVD 설명(영어 원문): An issue in ollama v.0.12.10 allows a remote attacker to cause a denial of service via the GGUF decoder",
   "Ollama을(를) CVE-2025-66959의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-66959 (Ollama)",
   "Descrição do NVD (texto original em inglês): An issue in ollama v.0.12.10 allows a remote attacker to cause a denial of service via the GGUF decoder",
   "Atualize o Ollama o quanto antes para uma versão não afetada por CVE-2025-66959 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-66959（Ollama）",
   "NVD 说明（英文原文）：An issue in ollama v.0.12.10 allows a remote attacker to cause a denial of service via the GGUF decoder",
   "请尽快将 Ollama 升级到不受 CVE-2025-66959 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-66959（Ollama）",
   "NVD 說明（英文原文）：An issue in ollama v.0.12.10 allows a remote attacker to cause a denial of service via the GGUF decoder",
   "請儘快將 Ollama 升級到不受 CVE-2025-66959 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:ollama-exposed:CVE-2025-66960": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-66960 (Ollama)",
   "NVD-Beschreibung (englischer Originaltext): An issue in ollama v.0.12.10 allows a remote attacker to cause a denial of service via the fs/ggml/gguf.go, function readGGUFV1String reads a string length from untrusted GGUF metadata",
   "Aktualisieren Sie Ollama so schnell wie möglich auf eine Version, die von CVE-2025-66960 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-66960 (Ollama)",
   "An issue in ollama v.0.12.10 allows a remote attacker to cause a denial of service via the fs/ggml/gguf.go, function readGGUFV1String reads a string length from untrusted GGUF metadata",
   "Upgrade Ollama to a version not affected by CVE-2025-66960 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-66960 (Ollama)",
   "Descripción de NVD (texto original en inglés): An issue in ollama v.0.12.10 allows a remote attacker to cause a denial of service via the fs/ggml/gguf.go, function readGGUFV1String reads a string length from untrusted GGUF metadata",
   "Actualice Ollama lo antes posible a una versión no afectada por CVE-2025-66960 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-66960 (Ollama)",
   "Description NVD (texte original en anglais) : An issue in ollama v.0.12.10 allows a remote attacker to cause a denial of service via the fs/ggml/gguf.go, function readGGUFV1String reads a string length from untrusted GGUF metadata",
   "Mettez à niveau Ollama dès que possible vers une version non affectée par CVE-2025-66960 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-66960 (Ollama)",
   "Descrizione NVD (testo originale in inglese): An issue in ollama v.0.12.10 allows a remote attacker to cause a denial of service via the fs/ggml/gguf.go, function readGGUFV1String reads a string length from untrusted GGUF metadata",
   "Aggiorna Ollama il prima possibile a una versione non interessata da CVE-2025-66960 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-66960 (Ollama)",
   "NVDの説明（英語原文）: An issue in ollama v.0.12.10 allows a remote attacker to cause a denial of service via the fs/ggml/gguf.go, function readGGUFV1String reads a string length from untrusted GGUF metadata",
   "Ollama を CVE-2025-66960 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-66960 (Ollama)",
   "NVD 설명(영어 원문): An issue in ollama v.0.12.10 allows a remote attacker to cause a denial of service via the fs/ggml/gguf.go, function readGGUFV1String reads a string length from untrusted GGUF metadata",
   "Ollama을(를) CVE-2025-66960의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-66960 (Ollama)",
   "Descrição do NVD (texto original em inglês): An issue in ollama v.0.12.10 allows a remote attacker to cause a denial of service via the fs/ggml/gguf.go, function readGGUFV1String reads a string length from untrusted GGUF metadata",
   "Atualize o Ollama o quanto antes para uma versão não afetada por CVE-2025-66960 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-66960（Ollama）",
   "NVD 说明（英文原文）：An issue in ollama v.0.12.10 allows a remote attacker to cause a denial of service via the fs/ggml/gguf.go, function readGGUFV1String reads a string length from untrusted GGUF metadata",
   "请尽快将 Ollama 升级到不受 CVE-2025-66960 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-66960（Ollama）",
   "NVD 說明（英文原文）：An issue in ollama v.0.12.10 allows a remote attacker to cause a denial of service via the fs/ggml/gguf.go, function readGGUFV1String reads a string length from untrusted GGUF metadata",
   "請儘快將 Ollama 升級到不受 CVE-2025-66960 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:ollama-exposed:CVE-2026-15685": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-15685 (Ollama)",
   "NVD-Beschreibung (englischer Originaltext): Ollama downloadBlob Improper Validation of Array Index Denial-of-Service Vulnerability. This vulnerability allows remote attackers to create a denial-of-service condition on affected installations of Ollama. Authentication is not required to exploit this vulnerability.\n\nThe specific flaw exists within the downloadBlob function. The issue results from the lack of proper validation of user-supplied data, which can result in a memory access past the end of an allocated array. An attacker can levera",
   "Aktualisieren Sie Ollama so schnell wie möglich auf eine Version, die von CVE-2026-15685 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-15685 (Ollama)",
   "Ollama downloadBlob Improper Validation of Array Index Denial-of-Service Vulnerability. This vulnerability allows remote attackers to create a denial-of-service condition on affected installations of Ollama. Authentication is not required to exploit this vulnerability.\n\nThe specific flaw exists within the downloadBlob function. The issue results from the lack of proper validation of user-supplied data, which can result in a memory access past the end of an allocated array. An attacker can levera",
   "Upgrade Ollama to a version not affected by CVE-2026-15685 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-15685 (Ollama)",
   "Descripción de NVD (texto original en inglés): Ollama downloadBlob Improper Validation of Array Index Denial-of-Service Vulnerability. This vulnerability allows remote attackers to create a denial-of-service condition on affected installations of Ollama. Authentication is not required to exploit this vulnerability.\n\nThe specific flaw exists within the downloadBlob function. The issue results from the lack of proper validation of user-supplied data, which can result in a memory access past the end of an allocated array. An attacker can levera",
   "Actualice Ollama lo antes posible a una versión no afectada por CVE-2026-15685 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-15685 (Ollama)",
   "Description NVD (texte original en anglais) : Ollama downloadBlob Improper Validation of Array Index Denial-of-Service Vulnerability. This vulnerability allows remote attackers to create a denial-of-service condition on affected installations of Ollama. Authentication is not required to exploit this vulnerability.\n\nThe specific flaw exists within the downloadBlob function. The issue results from the lack of proper validation of user-supplied data, which can result in a memory access past the end of an allocated array. An attacker can levera",
   "Mettez à niveau Ollama dès que possible vers une version non affectée par CVE-2026-15685 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-15685 (Ollama)",
   "Descrizione NVD (testo originale in inglese): Ollama downloadBlob Improper Validation of Array Index Denial-of-Service Vulnerability. This vulnerability allows remote attackers to create a denial-of-service condition on affected installations of Ollama. Authentication is not required to exploit this vulnerability.\n\nThe specific flaw exists within the downloadBlob function. The issue results from the lack of proper validation of user-supplied data, which can result in a memory access past the end of an allocated array. An attacker can levera",
   "Aggiorna Ollama il prima possibile a una versione non interessata da CVE-2026-15685 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-15685 (Ollama)",
   "NVDの説明（英語原文）: Ollama downloadBlob Improper Validation of Array Index Denial-of-Service Vulnerability. This vulnerability allows remote attackers to create a denial-of-service condition on affected installations of Ollama. Authentication is not required to exploit this vulnerability.\n\nThe specific flaw exists within the downloadBlob function. The issue results from the lack of proper validation of user-supplied data, which can result in a memory access past the end of an allocated array. An attacker can levera",
   "Ollama を CVE-2026-15685 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-15685 (Ollama)",
   "NVD 설명(영어 원문): Ollama downloadBlob Improper Validation of Array Index Denial-of-Service Vulnerability. This vulnerability allows remote attackers to create a denial-of-service condition on affected installations of Ollama. Authentication is not required to exploit this vulnerability.\n\nThe specific flaw exists within the downloadBlob function. The issue results from the lack of proper validation of user-supplied data, which can result in a memory access past the end of an allocated array. An attacker can levera",
   "Ollama을(를) CVE-2026-15685의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-15685 (Ollama)",
   "Descrição do NVD (texto original em inglês): Ollama downloadBlob Improper Validation of Array Index Denial-of-Service Vulnerability. This vulnerability allows remote attackers to create a denial-of-service condition on affected installations of Ollama. Authentication is not required to exploit this vulnerability.\n\nThe specific flaw exists within the downloadBlob function. The issue results from the lack of proper validation of user-supplied data, which can result in a memory access past the end of an allocated array. An attacker can levera",
   "Atualize o Ollama o quanto antes para uma versão não afetada por CVE-2026-15685 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-15685（Ollama）",
   "NVD 说明（英文原文）：Ollama downloadBlob Improper Validation of Array Index Denial-of-Service Vulnerability. This vulnerability allows remote attackers to create a denial-of-service condition on affected installations of Ollama. Authentication is not required to exploit this vulnerability.\n\nThe specific flaw exists within the downloadBlob function. The issue results from the lack of proper validation of user-supplied data, which can result in a memory access past the end of an allocated array. An attacker can levera",
   "请尽快将 Ollama 升级到不受 CVE-2026-15685 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-15685（Ollama）",
   "NVD 說明（英文原文）：Ollama downloadBlob Improper Validation of Array Index Denial-of-Service Vulnerability. This vulnerability allows remote attackers to create a denial-of-service condition on affected installations of Ollama. Authentication is not required to exploit this vulnerability.\n\nThe specific flaw exists within the downloadBlob function. The issue results from the lack of proper validation of user-supplied data, which can result in a memory access past the end of an allocated array. An attacker can levera",
   "請儘快將 Ollama 升級到不受 CVE-2026-15685 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:ollama-exposed:CVE-2026-42248": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-42248 (Ollama)",
   "NVD-Beschreibung (englischer Originaltext): Ollama for Windows does not perform integrity or authenticity verification of downloaded update executables. Unlike other platforms, the Windows implementation of the update verification routine unconditionally returns success so no digital signature or trust validation is performed before staging or executing update payloads, enabling attacker‑supplied executables to be accepted and later executed by the application.\n\nCritically, Ollama for Windows performs silent automatic updates, so the mali",
   "Aktualisieren Sie Ollama so schnell wie möglich auf eine Version, die von CVE-2026-42248 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-42248 (Ollama)",
   "Ollama for Windows does not perform integrity or authenticity verification of downloaded update executables. Unlike other platforms, the Windows implementation of the update verification routine unconditionally returns success so no digital signature or trust validation is performed before staging or executing update payloads, enabling attacker‑supplied executables to be accepted and later executed by the application.\n\nCritically, Ollama for Windows performs silent automatic updates, so the mali",
   "Upgrade Ollama to a version not affected by CVE-2026-42248 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-42248 (Ollama)",
   "Descripción de NVD (texto original en inglés): Ollama for Windows does not perform integrity or authenticity verification of downloaded update executables. Unlike other platforms, the Windows implementation of the update verification routine unconditionally returns success so no digital signature or trust validation is performed before staging or executing update payloads, enabling attacker‑supplied executables to be accepted and later executed by the application.\n\nCritically, Ollama for Windows performs silent automatic updates, so the mali",
   "Actualice Ollama lo antes posible a una versión no afectada por CVE-2026-42248 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-42248 (Ollama)",
   "Description NVD (texte original en anglais) : Ollama for Windows does not perform integrity or authenticity verification of downloaded update executables. Unlike other platforms, the Windows implementation of the update verification routine unconditionally returns success so no digital signature or trust validation is performed before staging or executing update payloads, enabling attacker‑supplied executables to be accepted and later executed by the application.\n\nCritically, Ollama for Windows performs silent automatic updates, so the mali",
   "Mettez à niveau Ollama dès que possible vers une version non affectée par CVE-2026-42248 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-42248 (Ollama)",
   "Descrizione NVD (testo originale in inglese): Ollama for Windows does not perform integrity or authenticity verification of downloaded update executables. Unlike other platforms, the Windows implementation of the update verification routine unconditionally returns success so no digital signature or trust validation is performed before staging or executing update payloads, enabling attacker‑supplied executables to be accepted and later executed by the application.\n\nCritically, Ollama for Windows performs silent automatic updates, so the mali",
   "Aggiorna Ollama il prima possibile a una versione non interessata da CVE-2026-42248 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-42248 (Ollama)",
   "NVDの説明（英語原文）: Ollama for Windows does not perform integrity or authenticity verification of downloaded update executables. Unlike other platforms, the Windows implementation of the update verification routine unconditionally returns success so no digital signature or trust validation is performed before staging or executing update payloads, enabling attacker‑supplied executables to be accepted and later executed by the application.\n\nCritically, Ollama for Windows performs silent automatic updates, so the mali",
   "Ollama を CVE-2026-42248 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-42248 (Ollama)",
   "NVD 설명(영어 원문): Ollama for Windows does not perform integrity or authenticity verification of downloaded update executables. Unlike other platforms, the Windows implementation of the update verification routine unconditionally returns success so no digital signature or trust validation is performed before staging or executing update payloads, enabling attacker‑supplied executables to be accepted and later executed by the application.\n\nCritically, Ollama for Windows performs silent automatic updates, so the mali",
   "Ollama을(를) CVE-2026-42248의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-42248 (Ollama)",
   "Descrição do NVD (texto original em inglês): Ollama for Windows does not perform integrity or authenticity verification of downloaded update executables. Unlike other platforms, the Windows implementation of the update verification routine unconditionally returns success so no digital signature or trust validation is performed before staging or executing update payloads, enabling attacker‑supplied executables to be accepted and later executed by the application.\n\nCritically, Ollama for Windows performs silent automatic updates, so the mali",
   "Atualize o Ollama o quanto antes para uma versão não afetada por CVE-2026-42248 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-42248（Ollama）",
   "NVD 说明（英文原文）：Ollama for Windows does not perform integrity or authenticity verification of downloaded update executables. Unlike other platforms, the Windows implementation of the update verification routine unconditionally returns success so no digital signature or trust validation is performed before staging or executing update payloads, enabling attacker‑supplied executables to be accepted and later executed by the application.\n\nCritically, Ollama for Windows performs silent automatic updates, so the mali",
   "请尽快将 Ollama 升级到不受 CVE-2026-42248 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-42248（Ollama）",
   "NVD 說明（英文原文）：Ollama for Windows does not perform integrity or authenticity verification of downloaded update executables. Unlike other platforms, the Windows implementation of the update verification routine unconditionally returns success so no digital signature or trust validation is performed before staging or executing update payloads, enabling attacker‑supplied executables to be accepted and later executed by the application.\n\nCritically, Ollama for Windows performs silent automatic updates, so the mali",
   "請儘快將 Ollama 升級到不受 CVE-2026-42248 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:ollama-exposed:CVE-2026-42249": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-42249 (Ollama)",
   "NVD-Beschreibung (englischer Originaltext): Ollama for Windows contains a Remote Code Execution vulnerability in its update mechanism due to improper handling of attacker‑controlled HTTP response headers. When downloading updates, the application constructs local file paths using values derived from HTTP headers without validation. These values are passed directly to filepath.Join, allowing path traversal sequences (../) to be resolved and enabling files to be written outside the intended update staging directory.\nAn attacker who can infl",
   "Aktualisieren Sie Ollama so schnell wie möglich auf eine Version, die von CVE-2026-42249 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-42249 (Ollama)",
   "Ollama for Windows contains a Remote Code Execution vulnerability in its update mechanism due to improper handling of attacker‑controlled HTTP response headers. When downloading updates, the application constructs local file paths using values derived from HTTP headers without validation. These values are passed directly to filepath.Join, allowing path traversal sequences (../) to be resolved and enabling files to be written outside the intended update staging directory.\nAn attacker who can infl",
   "Upgrade Ollama to a version not affected by CVE-2026-42249 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-42249 (Ollama)",
   "Descripción de NVD (texto original en inglés): Ollama for Windows contains a Remote Code Execution vulnerability in its update mechanism due to improper handling of attacker‑controlled HTTP response headers. When downloading updates, the application constructs local file paths using values derived from HTTP headers without validation. These values are passed directly to filepath.Join, allowing path traversal sequences (../) to be resolved and enabling files to be written outside the intended update staging directory.\nAn attacker who can infl",
   "Actualice Ollama lo antes posible a una versión no afectada por CVE-2026-42249 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-42249 (Ollama)",
   "Description NVD (texte original en anglais) : Ollama for Windows contains a Remote Code Execution vulnerability in its update mechanism due to improper handling of attacker‑controlled HTTP response headers. When downloading updates, the application constructs local file paths using values derived from HTTP headers without validation. These values are passed directly to filepath.Join, allowing path traversal sequences (../) to be resolved and enabling files to be written outside the intended update staging directory.\nAn attacker who can infl",
   "Mettez à niveau Ollama dès que possible vers une version non affectée par CVE-2026-42249 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-42249 (Ollama)",
   "Descrizione NVD (testo originale in inglese): Ollama for Windows contains a Remote Code Execution vulnerability in its update mechanism due to improper handling of attacker‑controlled HTTP response headers. When downloading updates, the application constructs local file paths using values derived from HTTP headers without validation. These values are passed directly to filepath.Join, allowing path traversal sequences (../) to be resolved and enabling files to be written outside the intended update staging directory.\nAn attacker who can infl",
   "Aggiorna Ollama il prima possibile a una versione non interessata da CVE-2026-42249 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-42249 (Ollama)",
   "NVDの説明（英語原文）: Ollama for Windows contains a Remote Code Execution vulnerability in its update mechanism due to improper handling of attacker‑controlled HTTP response headers. When downloading updates, the application constructs local file paths using values derived from HTTP headers without validation. These values are passed directly to filepath.Join, allowing path traversal sequences (../) to be resolved and enabling files to be written outside the intended update staging directory.\nAn attacker who can infl",
   "Ollama を CVE-2026-42249 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-42249 (Ollama)",
   "NVD 설명(영어 원문): Ollama for Windows contains a Remote Code Execution vulnerability in its update mechanism due to improper handling of attacker‑controlled HTTP response headers. When downloading updates, the application constructs local file paths using values derived from HTTP headers without validation. These values are passed directly to filepath.Join, allowing path traversal sequences (../) to be resolved and enabling files to be written outside the intended update staging directory.\nAn attacker who can infl",
   "Ollama을(를) CVE-2026-42249의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-42249 (Ollama)",
   "Descrição do NVD (texto original em inglês): Ollama for Windows contains a Remote Code Execution vulnerability in its update mechanism due to improper handling of attacker‑controlled HTTP response headers. When downloading updates, the application constructs local file paths using values derived from HTTP headers without validation. These values are passed directly to filepath.Join, allowing path traversal sequences (../) to be resolved and enabling files to be written outside the intended update staging directory.\nAn attacker who can infl",
   "Atualize o Ollama o quanto antes para uma versão não afetada por CVE-2026-42249 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-42249（Ollama）",
   "NVD 说明（英文原文）：Ollama for Windows contains a Remote Code Execution vulnerability in its update mechanism due to improper handling of attacker‑controlled HTTP response headers. When downloading updates, the application constructs local file paths using values derived from HTTP headers without validation. These values are passed directly to filepath.Join, allowing path traversal sequences (../) to be resolved and enabling files to be written outside the intended update staging directory.\nAn attacker who can infl",
   "请尽快将 Ollama 升级到不受 CVE-2026-42249 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-42249（Ollama）",
   "NVD 說明（英文原文）：Ollama for Windows contains a Remote Code Execution vulnerability in its update mechanism due to improper handling of attacker‑controlled HTTP response headers. When downloading updates, the application constructs local file paths using values derived from HTTP headers without validation. These values are passed directly to filepath.Join, allowing path traversal sequences (../) to be resolved and enabling files to be written outside the intended update staging directory.\nAn attacker who can infl",
   "請儘快將 Ollama 升級到不受 CVE-2026-42249 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:ollama-exposed:CVE-2026-5757": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-5757 (Ollama)",
   "NVD-Beschreibung (englischer Originaltext): Unauthenticated remote information disclosure vulnerability in Ollama's model quantization engine allows an attacker to read and exfiltrate the server's heap memory, potentially leading to sensitive data exposure, further compromise, and stealthy persistence.",
   "Aktualisieren Sie Ollama so schnell wie möglich auf eine Version, die von CVE-2026-5757 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-5757 (Ollama)",
   "Unauthenticated remote information disclosure vulnerability in Ollama's model quantization engine allows an attacker to read and exfiltrate the server's heap memory, potentially leading to sensitive data exposure, further compromise, and stealthy persistence.",
   "Upgrade Ollama to a version not affected by CVE-2026-5757 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-5757 (Ollama)",
   "Descripción de NVD (texto original en inglés): Unauthenticated remote information disclosure vulnerability in Ollama's model quantization engine allows an attacker to read and exfiltrate the server's heap memory, potentially leading to sensitive data exposure, further compromise, and stealthy persistence.",
   "Actualice Ollama lo antes posible a una versión no afectada por CVE-2026-5757 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-5757 (Ollama)",
   "Description NVD (texte original en anglais) : Unauthenticated remote information disclosure vulnerability in Ollama's model quantization engine allows an attacker to read and exfiltrate the server's heap memory, potentially leading to sensitive data exposure, further compromise, and stealthy persistence.",
   "Mettez à niveau Ollama dès que possible vers une version non affectée par CVE-2026-5757 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-5757 (Ollama)",
   "Descrizione NVD (testo originale in inglese): Unauthenticated remote information disclosure vulnerability in Ollama's model quantization engine allows an attacker to read and exfiltrate the server's heap memory, potentially leading to sensitive data exposure, further compromise, and stealthy persistence.",
   "Aggiorna Ollama il prima possibile a una versione non interessata da CVE-2026-5757 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-5757 (Ollama)",
   "NVDの説明（英語原文）: Unauthenticated remote information disclosure vulnerability in Ollama's model quantization engine allows an attacker to read and exfiltrate the server's heap memory, potentially leading to sensitive data exposure, further compromise, and stealthy persistence.",
   "Ollama を CVE-2026-5757 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-5757 (Ollama)",
   "NVD 설명(영어 원문): Unauthenticated remote information disclosure vulnerability in Ollama's model quantization engine allows an attacker to read and exfiltrate the server's heap memory, potentially leading to sensitive data exposure, further compromise, and stealthy persistence.",
   "Ollama을(를) CVE-2026-5757의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-5757 (Ollama)",
   "Descrição do NVD (texto original em inglês): Unauthenticated remote information disclosure vulnerability in Ollama's model quantization engine allows an attacker to read and exfiltrate the server's heap memory, potentially leading to sensitive data exposure, further compromise, and stealthy persistence.",
   "Atualize o Ollama o quanto antes para uma versão não afetada por CVE-2026-5757 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-5757（Ollama）",
   "NVD 说明（英文原文）：Unauthenticated remote information disclosure vulnerability in Ollama's model quantization engine allows an attacker to read and exfiltrate the server's heap memory, potentially leading to sensitive data exposure, further compromise, and stealthy persistence.",
   "请尽快将 Ollama 升级到不受 CVE-2026-5757 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-5757（Ollama）",
   "NVD 說明（英文原文）：Unauthenticated remote information disclosure vulnerability in Ollama's model quantization engine allows an attacker to read and exfiltrate the server's heap memory, potentially leading to sensitive data exposure, further compromise, and stealthy persistence.",
   "請儘快將 Ollama 升級到不受 CVE-2026-5757 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:ollama-exposed:CVE-2026-7482": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-7482 (Ollama)",
   "NVD-Beschreibung (englischer Originaltext): Ollama before 0.17.1 contains a heap out-of-bounds read vulnerability in the GGUF model loader. The /api/create endpoint accepts an attacker-supplied GGUF file in which the declared tensor offset and size exceed the file's actual length; during quantization in fs/ggml/gguf.go and server/quantization.go (WriteTo()), the server reads past the allocated heap buffer. The leaked memory contents may include environment variables, API keys, system prompts, and concurrent users' conversation data, and c",
   "Aktualisieren Sie Ollama so schnell wie möglich auf eine Version, die von CVE-2026-7482 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-7482 (Ollama)",
   "Ollama before 0.17.1 contains a heap out-of-bounds read vulnerability in the GGUF model loader. The /api/create endpoint accepts an attacker-supplied GGUF file in which the declared tensor offset and size exceed the file's actual length; during quantization in fs/ggml/gguf.go and server/quantization.go (WriteTo()), the server reads past the allocated heap buffer. The leaked memory contents may include environment variables, API keys, system prompts, and concurrent users' conversation data, and c",
   "Upgrade Ollama to a version not affected by CVE-2026-7482 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-7482 (Ollama)",
   "Descripción de NVD (texto original en inglés): Ollama before 0.17.1 contains a heap out-of-bounds read vulnerability in the GGUF model loader. The /api/create endpoint accepts an attacker-supplied GGUF file in which the declared tensor offset and size exceed the file's actual length; during quantization in fs/ggml/gguf.go and server/quantization.go (WriteTo()), the server reads past the allocated heap buffer. The leaked memory contents may include environment variables, API keys, system prompts, and concurrent users' conversation data, and c",
   "Actualice Ollama lo antes posible a una versión no afectada por CVE-2026-7482 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-7482 (Ollama)",
   "Description NVD (texte original en anglais) : Ollama before 0.17.1 contains a heap out-of-bounds read vulnerability in the GGUF model loader. The /api/create endpoint accepts an attacker-supplied GGUF file in which the declared tensor offset and size exceed the file's actual length; during quantization in fs/ggml/gguf.go and server/quantization.go (WriteTo()), the server reads past the allocated heap buffer. The leaked memory contents may include environment variables, API keys, system prompts, and concurrent users' conversation data, and c",
   "Mettez à niveau Ollama dès que possible vers une version non affectée par CVE-2026-7482 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-7482 (Ollama)",
   "Descrizione NVD (testo originale in inglese): Ollama before 0.17.1 contains a heap out-of-bounds read vulnerability in the GGUF model loader. The /api/create endpoint accepts an attacker-supplied GGUF file in which the declared tensor offset and size exceed the file's actual length; during quantization in fs/ggml/gguf.go and server/quantization.go (WriteTo()), the server reads past the allocated heap buffer. The leaked memory contents may include environment variables, API keys, system prompts, and concurrent users' conversation data, and c",
   "Aggiorna Ollama il prima possibile a una versione non interessata da CVE-2026-7482 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-7482 (Ollama)",
   "NVDの説明（英語原文）: Ollama before 0.17.1 contains a heap out-of-bounds read vulnerability in the GGUF model loader. The /api/create endpoint accepts an attacker-supplied GGUF file in which the declared tensor offset and size exceed the file's actual length; during quantization in fs/ggml/gguf.go and server/quantization.go (WriteTo()), the server reads past the allocated heap buffer. The leaked memory contents may include environment variables, API keys, system prompts, and concurrent users' conversation data, and c",
   "Ollama を CVE-2026-7482 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-7482 (Ollama)",
   "NVD 설명(영어 원문): Ollama before 0.17.1 contains a heap out-of-bounds read vulnerability in the GGUF model loader. The /api/create endpoint accepts an attacker-supplied GGUF file in which the declared tensor offset and size exceed the file's actual length; during quantization in fs/ggml/gguf.go and server/quantization.go (WriteTo()), the server reads past the allocated heap buffer. The leaked memory contents may include environment variables, API keys, system prompts, and concurrent users' conversation data, and c",
   "Ollama을(를) CVE-2026-7482의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-7482 (Ollama)",
   "Descrição do NVD (texto original em inglês): Ollama before 0.17.1 contains a heap out-of-bounds read vulnerability in the GGUF model loader. The /api/create endpoint accepts an attacker-supplied GGUF file in which the declared tensor offset and size exceed the file's actual length; during quantization in fs/ggml/gguf.go and server/quantization.go (WriteTo()), the server reads past the allocated heap buffer. The leaked memory contents may include environment variables, API keys, system prompts, and concurrent users' conversation data, and c",
   "Atualize o Ollama o quanto antes para uma versão não afetada por CVE-2026-7482 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-7482（Ollama）",
   "NVD 说明（英文原文）：Ollama before 0.17.1 contains a heap out-of-bounds read vulnerability in the GGUF model loader. The /api/create endpoint accepts an attacker-supplied GGUF file in which the declared tensor offset and size exceed the file's actual length; during quantization in fs/ggml/gguf.go and server/quantization.go (WriteTo()), the server reads past the allocated heap buffer. The leaked memory contents may include environment variables, API keys, system prompts, and concurrent users' conversation data, and c",
   "请尽快将 Ollama 升级到不受 CVE-2026-7482 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-7482（Ollama）",
   "NVD 說明（英文原文）：Ollama before 0.17.1 contains a heap out-of-bounds read vulnerability in the GGUF model loader. The /api/create endpoint accepts an attacker-supplied GGUF file in which the declared tensor offset and size exceed the file's actual length; during quantization in fs/ggml/gguf.go and server/quantization.go (WriteTo()), the server reads past the allocated heap buffer. The leaked memory contents may include environment variables, API keys, system prompts, and concurrent users' conversation data, and c",
   "請儘快將 Ollama 升級到不受 CVE-2026-7482 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2021-32626": {
  "de": [
   "Bekannte Schwachstelle: CVE-2021-32626 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): Redis is an open source, in-memory database that persists on disk. In affected versions specially crafted Lua scripts executing in Redis can cause the heap-based Lua stack to be overflowed, due to incomplete checks for this condition. This can result with heap corruption and potentially remote code execution. This problem exists in all versions of Redis with Lua scripting support, starting from 2.6. The problem is fixed in versions 6.2.6, 6.0.16 and 5.0.14. For users unable to update an addition",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2021-32626 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2021-32626 (Redis)",
   "Redis is an open source, in-memory database that persists on disk. In affected versions specially crafted Lua scripts executing in Redis can cause the heap-based Lua stack to be overflowed, due to incomplete checks for this condition. This can result with heap corruption and potentially remote code execution. This problem exists in all versions of Redis with Lua scripting support, starting from 2.6. The problem is fixed in versions 6.2.6, 6.0.16 and 5.0.14. For users unable to update an addition",
   "Upgrade Redis to a version not affected by CVE-2021-32626 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2021-32626 (Redis)",
   "Descripción de NVD (texto original en inglés): Redis is an open source, in-memory database that persists on disk. In affected versions specially crafted Lua scripts executing in Redis can cause the heap-based Lua stack to be overflowed, due to incomplete checks for this condition. This can result with heap corruption and potentially remote code execution. This problem exists in all versions of Redis with Lua scripting support, starting from 2.6. The problem is fixed in versions 6.2.6, 6.0.16 and 5.0.14. For users unable to update an addition",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2021-32626 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2021-32626 (Redis)",
   "Description NVD (texte original en anglais) : Redis is an open source, in-memory database that persists on disk. In affected versions specially crafted Lua scripts executing in Redis can cause the heap-based Lua stack to be overflowed, due to incomplete checks for this condition. This can result with heap corruption and potentially remote code execution. This problem exists in all versions of Redis with Lua scripting support, starting from 2.6. The problem is fixed in versions 6.2.6, 6.0.16 and 5.0.14. For users unable to update an addition",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2021-32626 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2021-32626 (Redis)",
   "Descrizione NVD (testo originale in inglese): Redis is an open source, in-memory database that persists on disk. In affected versions specially crafted Lua scripts executing in Redis can cause the heap-based Lua stack to be overflowed, due to incomplete checks for this condition. This can result with heap corruption and potentially remote code execution. This problem exists in all versions of Redis with Lua scripting support, starting from 2.6. The problem is fixed in versions 6.2.6, 6.0.16 and 5.0.14. For users unable to update an addition",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2021-32626 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2021-32626 (Redis)",
   "NVDの説明（英語原文）: Redis is an open source, in-memory database that persists on disk. In affected versions specially crafted Lua scripts executing in Redis can cause the heap-based Lua stack to be overflowed, due to incomplete checks for this condition. This can result with heap corruption and potentially remote code execution. This problem exists in all versions of Redis with Lua scripting support, starting from 2.6. The problem is fixed in versions 6.2.6, 6.0.16 and 5.0.14. For users unable to update an addition",
   "Redis を CVE-2021-32626 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2021-32626 (Redis)",
   "NVD 설명(영어 원문): Redis is an open source, in-memory database that persists on disk. In affected versions specially crafted Lua scripts executing in Redis can cause the heap-based Lua stack to be overflowed, due to incomplete checks for this condition. This can result with heap corruption and potentially remote code execution. This problem exists in all versions of Redis with Lua scripting support, starting from 2.6. The problem is fixed in versions 6.2.6, 6.0.16 and 5.0.14. For users unable to update an addition",
   "Redis을(를) CVE-2021-32626의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2021-32626 (Redis)",
   "Descrição do NVD (texto original em inglês): Redis is an open source, in-memory database that persists on disk. In affected versions specially crafted Lua scripts executing in Redis can cause the heap-based Lua stack to be overflowed, due to incomplete checks for this condition. This can result with heap corruption and potentially remote code execution. This problem exists in all versions of Redis with Lua scripting support, starting from 2.6. The problem is fixed in versions 6.2.6, 6.0.16 and 5.0.14. For users unable to update an addition",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2021-32626 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2021-32626（Redis）",
   "NVD 说明（英文原文）：Redis is an open source, in-memory database that persists on disk. In affected versions specially crafted Lua scripts executing in Redis can cause the heap-based Lua stack to be overflowed, due to incomplete checks for this condition. This can result with heap corruption and potentially remote code execution. This problem exists in all versions of Redis with Lua scripting support, starting from 2.6. The problem is fixed in versions 6.2.6, 6.0.16 and 5.0.14. For users unable to update an addition",
   "请尽快将 Redis 升级到不受 CVE-2021-32626 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2021-32626（Redis）",
   "NVD 說明（英文原文）：Redis is an open source, in-memory database that persists on disk. In affected versions specially crafted Lua scripts executing in Redis can cause the heap-based Lua stack to be overflowed, due to incomplete checks for this condition. This can result with heap corruption and potentially remote code execution. This problem exists in all versions of Redis with Lua scripting support, starting from 2.6. The problem is fixed in versions 6.2.6, 6.0.16 and 5.0.14. For users unable to update an addition",
   "請儘快將 Redis 升級到不受 CVE-2021-32626 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2021-32627": {
  "de": [
   "Bekannte Schwachstelle: CVE-2021-32627 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): Redis is an open source, in-memory database that persists on disk. In affected versions an integer overflow bug in Redis can be exploited to corrupt the heap and potentially result with remote code execution. The vulnerability involves changing the default proto-max-bulk-len and client-query-buffer-limit configuration parameters to very large values and constructing specially crafted very large stream elements. The problem is fixed in Redis 6.2.6, 6.0.16 and 5.0.14. For users unable to upgrade a",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2021-32627 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2021-32627 (Redis)",
   "Redis is an open source, in-memory database that persists on disk. In affected versions an integer overflow bug in Redis can be exploited to corrupt the heap and potentially result with remote code execution. The vulnerability involves changing the default proto-max-bulk-len and client-query-buffer-limit configuration parameters to very large values and constructing specially crafted very large stream elements. The problem is fixed in Redis 6.2.6, 6.0.16 and 5.0.14. For users unable to upgrade a",
   "Upgrade Redis to a version not affected by CVE-2021-32627 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2021-32627 (Redis)",
   "Descripción de NVD (texto original en inglés): Redis is an open source, in-memory database that persists on disk. In affected versions an integer overflow bug in Redis can be exploited to corrupt the heap and potentially result with remote code execution. The vulnerability involves changing the default proto-max-bulk-len and client-query-buffer-limit configuration parameters to very large values and constructing specially crafted very large stream elements. The problem is fixed in Redis 6.2.6, 6.0.16 and 5.0.14. For users unable to upgrade a",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2021-32627 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2021-32627 (Redis)",
   "Description NVD (texte original en anglais) : Redis is an open source, in-memory database that persists on disk. In affected versions an integer overflow bug in Redis can be exploited to corrupt the heap and potentially result with remote code execution. The vulnerability involves changing the default proto-max-bulk-len and client-query-buffer-limit configuration parameters to very large values and constructing specially crafted very large stream elements. The problem is fixed in Redis 6.2.6, 6.0.16 and 5.0.14. For users unable to upgrade a",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2021-32627 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2021-32627 (Redis)",
   "Descrizione NVD (testo originale in inglese): Redis is an open source, in-memory database that persists on disk. In affected versions an integer overflow bug in Redis can be exploited to corrupt the heap and potentially result with remote code execution. The vulnerability involves changing the default proto-max-bulk-len and client-query-buffer-limit configuration parameters to very large values and constructing specially crafted very large stream elements. The problem is fixed in Redis 6.2.6, 6.0.16 and 5.0.14. For users unable to upgrade a",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2021-32627 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2021-32627 (Redis)",
   "NVDの説明（英語原文）: Redis is an open source, in-memory database that persists on disk. In affected versions an integer overflow bug in Redis can be exploited to corrupt the heap and potentially result with remote code execution. The vulnerability involves changing the default proto-max-bulk-len and client-query-buffer-limit configuration parameters to very large values and constructing specially crafted very large stream elements. The problem is fixed in Redis 6.2.6, 6.0.16 and 5.0.14. For users unable to upgrade a",
   "Redis を CVE-2021-32627 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2021-32627 (Redis)",
   "NVD 설명(영어 원문): Redis is an open source, in-memory database that persists on disk. In affected versions an integer overflow bug in Redis can be exploited to corrupt the heap and potentially result with remote code execution. The vulnerability involves changing the default proto-max-bulk-len and client-query-buffer-limit configuration parameters to very large values and constructing specially crafted very large stream elements. The problem is fixed in Redis 6.2.6, 6.0.16 and 5.0.14. For users unable to upgrade a",
   "Redis을(를) CVE-2021-32627의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2021-32627 (Redis)",
   "Descrição do NVD (texto original em inglês): Redis is an open source, in-memory database that persists on disk. In affected versions an integer overflow bug in Redis can be exploited to corrupt the heap and potentially result with remote code execution. The vulnerability involves changing the default proto-max-bulk-len and client-query-buffer-limit configuration parameters to very large values and constructing specially crafted very large stream elements. The problem is fixed in Redis 6.2.6, 6.0.16 and 5.0.14. For users unable to upgrade a",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2021-32627 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2021-32627（Redis）",
   "NVD 说明（英文原文）：Redis is an open source, in-memory database that persists on disk. In affected versions an integer overflow bug in Redis can be exploited to corrupt the heap and potentially result with remote code execution. The vulnerability involves changing the default proto-max-bulk-len and client-query-buffer-limit configuration parameters to very large values and constructing specially crafted very large stream elements. The problem is fixed in Redis 6.2.6, 6.0.16 and 5.0.14. For users unable to upgrade a",
   "请尽快将 Redis 升级到不受 CVE-2021-32627 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2021-32627（Redis）",
   "NVD 說明（英文原文）：Redis is an open source, in-memory database that persists on disk. In affected versions an integer overflow bug in Redis can be exploited to corrupt the heap and potentially result with remote code execution. The vulnerability involves changing the default proto-max-bulk-len and client-query-buffer-limit configuration parameters to very large values and constructing specially crafted very large stream elements. The problem is fixed in Redis 6.2.6, 6.0.16 and 5.0.14. For users unable to upgrade a",
   "請儘快將 Redis 升級到不受 CVE-2021-32627 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2021-32628": {
  "de": [
   "Bekannte Schwachstelle: CVE-2021-32628 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): Redis is an open source, in-memory database that persists on disk. An integer overflow bug in the ziplist data structure used by all versions of Redis can be exploited to corrupt the heap and potentially result with remote code execution. The vulnerability involves modifying the default ziplist configuration parameters (hash-max-ziplist-entries, hash-max-ziplist-value, zset-max-ziplist-entries or zset-max-ziplist-value) to a very large value, and then constructing specially crafted commands to c",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2021-32628 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2021-32628 (Redis)",
   "Redis is an open source, in-memory database that persists on disk. An integer overflow bug in the ziplist data structure used by all versions of Redis can be exploited to corrupt the heap and potentially result with remote code execution. The vulnerability involves modifying the default ziplist configuration parameters (hash-max-ziplist-entries, hash-max-ziplist-value, zset-max-ziplist-entries or zset-max-ziplist-value) to a very large value, and then constructing specially crafted commands to c",
   "Upgrade Redis to a version not affected by CVE-2021-32628 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2021-32628 (Redis)",
   "Descripción de NVD (texto original en inglés): Redis is an open source, in-memory database that persists on disk. An integer overflow bug in the ziplist data structure used by all versions of Redis can be exploited to corrupt the heap and potentially result with remote code execution. The vulnerability involves modifying the default ziplist configuration parameters (hash-max-ziplist-entries, hash-max-ziplist-value, zset-max-ziplist-entries or zset-max-ziplist-value) to a very large value, and then constructing specially crafted commands to c",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2021-32628 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2021-32628 (Redis)",
   "Description NVD (texte original en anglais) : Redis is an open source, in-memory database that persists on disk. An integer overflow bug in the ziplist data structure used by all versions of Redis can be exploited to corrupt the heap and potentially result with remote code execution. The vulnerability involves modifying the default ziplist configuration parameters (hash-max-ziplist-entries, hash-max-ziplist-value, zset-max-ziplist-entries or zset-max-ziplist-value) to a very large value, and then constructing specially crafted commands to c",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2021-32628 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2021-32628 (Redis)",
   "Descrizione NVD (testo originale in inglese): Redis is an open source, in-memory database that persists on disk. An integer overflow bug in the ziplist data structure used by all versions of Redis can be exploited to corrupt the heap and potentially result with remote code execution. The vulnerability involves modifying the default ziplist configuration parameters (hash-max-ziplist-entries, hash-max-ziplist-value, zset-max-ziplist-entries or zset-max-ziplist-value) to a very large value, and then constructing specially crafted commands to c",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2021-32628 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2021-32628 (Redis)",
   "NVDの説明（英語原文）: Redis is an open source, in-memory database that persists on disk. An integer overflow bug in the ziplist data structure used by all versions of Redis can be exploited to corrupt the heap and potentially result with remote code execution. The vulnerability involves modifying the default ziplist configuration parameters (hash-max-ziplist-entries, hash-max-ziplist-value, zset-max-ziplist-entries or zset-max-ziplist-value) to a very large value, and then constructing specially crafted commands to c",
   "Redis を CVE-2021-32628 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2021-32628 (Redis)",
   "NVD 설명(영어 원문): Redis is an open source, in-memory database that persists on disk. An integer overflow bug in the ziplist data structure used by all versions of Redis can be exploited to corrupt the heap and potentially result with remote code execution. The vulnerability involves modifying the default ziplist configuration parameters (hash-max-ziplist-entries, hash-max-ziplist-value, zset-max-ziplist-entries or zset-max-ziplist-value) to a very large value, and then constructing specially crafted commands to c",
   "Redis을(를) CVE-2021-32628의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2021-32628 (Redis)",
   "Descrição do NVD (texto original em inglês): Redis is an open source, in-memory database that persists on disk. An integer overflow bug in the ziplist data structure used by all versions of Redis can be exploited to corrupt the heap and potentially result with remote code execution. The vulnerability involves modifying the default ziplist configuration parameters (hash-max-ziplist-entries, hash-max-ziplist-value, zset-max-ziplist-entries or zset-max-ziplist-value) to a very large value, and then constructing specially crafted commands to c",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2021-32628 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2021-32628（Redis）",
   "NVD 说明（英文原文）：Redis is an open source, in-memory database that persists on disk. An integer overflow bug in the ziplist data structure used by all versions of Redis can be exploited to corrupt the heap and potentially result with remote code execution. The vulnerability involves modifying the default ziplist configuration parameters (hash-max-ziplist-entries, hash-max-ziplist-value, zset-max-ziplist-entries or zset-max-ziplist-value) to a very large value, and then constructing specially crafted commands to c",
   "请尽快将 Redis 升级到不受 CVE-2021-32628 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2021-32628（Redis）",
   "NVD 說明（英文原文）：Redis is an open source, in-memory database that persists on disk. An integer overflow bug in the ziplist data structure used by all versions of Redis can be exploited to corrupt the heap and potentially result with remote code execution. The vulnerability involves modifying the default ziplist configuration parameters (hash-max-ziplist-entries, hash-max-ziplist-value, zset-max-ziplist-entries or zset-max-ziplist-value) to a very large value, and then constructing specially crafted commands to c",
   "請儘快將 Redis 升級到不受 CVE-2021-32628 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2021-32675": {
  "de": [
   "Bekannte Schwachstelle: CVE-2021-32675 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): Redis is an open source, in-memory database that persists on disk. When parsing an incoming Redis Standard Protocol (RESP) request, Redis allocates memory according to user-specified values which determine the number of elements (in the multi-bulk header) and size of each element (in the bulk header). An attacker delivering specially crafted requests over multiple connections can cause the server to allocate significant amount of memory. Because the same parsing mechanism is used to handle authe",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2021-32675 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2021-32675 (Redis)",
   "Redis is an open source, in-memory database that persists on disk. When parsing an incoming Redis Standard Protocol (RESP) request, Redis allocates memory according to user-specified values which determine the number of elements (in the multi-bulk header) and size of each element (in the bulk header). An attacker delivering specially crafted requests over multiple connections can cause the server to allocate significant amount of memory. Because the same parsing mechanism is used to handle authe",
   "Upgrade Redis to a version not affected by CVE-2021-32675 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2021-32675 (Redis)",
   "Descripción de NVD (texto original en inglés): Redis is an open source, in-memory database that persists on disk. When parsing an incoming Redis Standard Protocol (RESP) request, Redis allocates memory according to user-specified values which determine the number of elements (in the multi-bulk header) and size of each element (in the bulk header). An attacker delivering specially crafted requests over multiple connections can cause the server to allocate significant amount of memory. Because the same parsing mechanism is used to handle authe",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2021-32675 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2021-32675 (Redis)",
   "Description NVD (texte original en anglais) : Redis is an open source, in-memory database that persists on disk. When parsing an incoming Redis Standard Protocol (RESP) request, Redis allocates memory according to user-specified values which determine the number of elements (in the multi-bulk header) and size of each element (in the bulk header). An attacker delivering specially crafted requests over multiple connections can cause the server to allocate significant amount of memory. Because the same parsing mechanism is used to handle authe",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2021-32675 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2021-32675 (Redis)",
   "Descrizione NVD (testo originale in inglese): Redis is an open source, in-memory database that persists on disk. When parsing an incoming Redis Standard Protocol (RESP) request, Redis allocates memory according to user-specified values which determine the number of elements (in the multi-bulk header) and size of each element (in the bulk header). An attacker delivering specially crafted requests over multiple connections can cause the server to allocate significant amount of memory. Because the same parsing mechanism is used to handle authe",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2021-32675 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2021-32675 (Redis)",
   "NVDの説明（英語原文）: Redis is an open source, in-memory database that persists on disk. When parsing an incoming Redis Standard Protocol (RESP) request, Redis allocates memory according to user-specified values which determine the number of elements (in the multi-bulk header) and size of each element (in the bulk header). An attacker delivering specially crafted requests over multiple connections can cause the server to allocate significant amount of memory. Because the same parsing mechanism is used to handle authe",
   "Redis を CVE-2021-32675 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2021-32675 (Redis)",
   "NVD 설명(영어 원문): Redis is an open source, in-memory database that persists on disk. When parsing an incoming Redis Standard Protocol (RESP) request, Redis allocates memory according to user-specified values which determine the number of elements (in the multi-bulk header) and size of each element (in the bulk header). An attacker delivering specially crafted requests over multiple connections can cause the server to allocate significant amount of memory. Because the same parsing mechanism is used to handle authe",
   "Redis을(를) CVE-2021-32675의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2021-32675 (Redis)",
   "Descrição do NVD (texto original em inglês): Redis is an open source, in-memory database that persists on disk. When parsing an incoming Redis Standard Protocol (RESP) request, Redis allocates memory according to user-specified values which determine the number of elements (in the multi-bulk header) and size of each element (in the bulk header). An attacker delivering specially crafted requests over multiple connections can cause the server to allocate significant amount of memory. Because the same parsing mechanism is used to handle authe",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2021-32675 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2021-32675（Redis）",
   "NVD 说明（英文原文）：Redis is an open source, in-memory database that persists on disk. When parsing an incoming Redis Standard Protocol (RESP) request, Redis allocates memory according to user-specified values which determine the number of elements (in the multi-bulk header) and size of each element (in the bulk header). An attacker delivering specially crafted requests over multiple connections can cause the server to allocate significant amount of memory. Because the same parsing mechanism is used to handle authe",
   "请尽快将 Redis 升级到不受 CVE-2021-32675 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2021-32675（Redis）",
   "NVD 說明（英文原文）：Redis is an open source, in-memory database that persists on disk. When parsing an incoming Redis Standard Protocol (RESP) request, Redis allocates memory according to user-specified values which determine the number of elements (in the multi-bulk header) and size of each element (in the bulk header). An attacker delivering specially crafted requests over multiple connections can cause the server to allocate significant amount of memory. Because the same parsing mechanism is used to handle authe",
   "請儘快將 Redis 升級到不受 CVE-2021-32675 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2021-32687": {
  "de": [
   "Bekannte Schwachstelle: CVE-2021-32687 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): Redis is an open source, in-memory database that persists on disk. An integer overflow bug affecting all versions of Redis can be exploited to corrupt the heap and potentially be used to leak arbitrary contents of the heap or trigger remote code execution. The vulnerability involves changing the default set-max-intset-entries configuration parameter to a very large value and constructing specially crafted commands to manipulate sets. The problem is fixed in Redis versions 6.2.6, 6.0.16 and 5.0.1",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2021-32687 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2021-32687 (Redis)",
   "Redis is an open source, in-memory database that persists on disk. An integer overflow bug affecting all versions of Redis can be exploited to corrupt the heap and potentially be used to leak arbitrary contents of the heap or trigger remote code execution. The vulnerability involves changing the default set-max-intset-entries configuration parameter to a very large value and constructing specially crafted commands to manipulate sets. The problem is fixed in Redis versions 6.2.6, 6.0.16 and 5.0.1",
   "Upgrade Redis to a version not affected by CVE-2021-32687 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2021-32687 (Redis)",
   "Descripción de NVD (texto original en inglés): Redis is an open source, in-memory database that persists on disk. An integer overflow bug affecting all versions of Redis can be exploited to corrupt the heap and potentially be used to leak arbitrary contents of the heap or trigger remote code execution. The vulnerability involves changing the default set-max-intset-entries configuration parameter to a very large value and constructing specially crafted commands to manipulate sets. The problem is fixed in Redis versions 6.2.6, 6.0.16 and 5.0.1",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2021-32687 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2021-32687 (Redis)",
   "Description NVD (texte original en anglais) : Redis is an open source, in-memory database that persists on disk. An integer overflow bug affecting all versions of Redis can be exploited to corrupt the heap and potentially be used to leak arbitrary contents of the heap or trigger remote code execution. The vulnerability involves changing the default set-max-intset-entries configuration parameter to a very large value and constructing specially crafted commands to manipulate sets. The problem is fixed in Redis versions 6.2.6, 6.0.16 and 5.0.1",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2021-32687 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2021-32687 (Redis)",
   "Descrizione NVD (testo originale in inglese): Redis is an open source, in-memory database that persists on disk. An integer overflow bug affecting all versions of Redis can be exploited to corrupt the heap and potentially be used to leak arbitrary contents of the heap or trigger remote code execution. The vulnerability involves changing the default set-max-intset-entries configuration parameter to a very large value and constructing specially crafted commands to manipulate sets. The problem is fixed in Redis versions 6.2.6, 6.0.16 and 5.0.1",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2021-32687 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2021-32687 (Redis)",
   "NVDの説明（英語原文）: Redis is an open source, in-memory database that persists on disk. An integer overflow bug affecting all versions of Redis can be exploited to corrupt the heap and potentially be used to leak arbitrary contents of the heap or trigger remote code execution. The vulnerability involves changing the default set-max-intset-entries configuration parameter to a very large value and constructing specially crafted commands to manipulate sets. The problem is fixed in Redis versions 6.2.6, 6.0.16 and 5.0.1",
   "Redis を CVE-2021-32687 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2021-32687 (Redis)",
   "NVD 설명(영어 원문): Redis is an open source, in-memory database that persists on disk. An integer overflow bug affecting all versions of Redis can be exploited to corrupt the heap and potentially be used to leak arbitrary contents of the heap or trigger remote code execution. The vulnerability involves changing the default set-max-intset-entries configuration parameter to a very large value and constructing specially crafted commands to manipulate sets. The problem is fixed in Redis versions 6.2.6, 6.0.16 and 5.0.1",
   "Redis을(를) CVE-2021-32687의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2021-32687 (Redis)",
   "Descrição do NVD (texto original em inglês): Redis is an open source, in-memory database that persists on disk. An integer overflow bug affecting all versions of Redis can be exploited to corrupt the heap and potentially be used to leak arbitrary contents of the heap or trigger remote code execution. The vulnerability involves changing the default set-max-intset-entries configuration parameter to a very large value and constructing specially crafted commands to manipulate sets. The problem is fixed in Redis versions 6.2.6, 6.0.16 and 5.0.1",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2021-32687 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2021-32687（Redis）",
   "NVD 说明（英文原文）：Redis is an open source, in-memory database that persists on disk. An integer overflow bug affecting all versions of Redis can be exploited to corrupt the heap and potentially be used to leak arbitrary contents of the heap or trigger remote code execution. The vulnerability involves changing the default set-max-intset-entries configuration parameter to a very large value and constructing specially crafted commands to manipulate sets. The problem is fixed in Redis versions 6.2.6, 6.0.16 and 5.0.1",
   "请尽快将 Redis 升级到不受 CVE-2021-32687 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2021-32687（Redis）",
   "NVD 說明（英文原文）：Redis is an open source, in-memory database that persists on disk. An integer overflow bug affecting all versions of Redis can be exploited to corrupt the heap and potentially be used to leak arbitrary contents of the heap or trigger remote code execution. The vulnerability involves changing the default set-max-intset-entries configuration parameter to a very large value and constructing specially crafted commands to manipulate sets. The problem is fixed in Redis versions 6.2.6, 6.0.16 and 5.0.1",
   "請儘快將 Redis 升級到不受 CVE-2021-32687 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2021-32762": {
  "de": [
   "Bekannte Schwachstelle: CVE-2021-32762 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): Redis is an open source, in-memory database that persists on disk. The redis-cli command line tool and redis-sentinel service may be vulnerable to integer overflow when parsing specially crafted large multi-bulk network replies. This is a result of a vulnerability in the underlying hiredis library which does not perform an overflow check before calling the calloc() heap allocation function. This issue only impacts systems with heap allocators that do not perform their own overflow checks. Most m",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2021-32762 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2021-32762 (Redis)",
   "Redis is an open source, in-memory database that persists on disk. The redis-cli command line tool and redis-sentinel service may be vulnerable to integer overflow when parsing specially crafted large multi-bulk network replies. This is a result of a vulnerability in the underlying hiredis library which does not perform an overflow check before calling the calloc() heap allocation function. This issue only impacts systems with heap allocators that do not perform their own overflow checks. Most m",
   "Upgrade Redis to a version not affected by CVE-2021-32762 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2021-32762 (Redis)",
   "Descripción de NVD (texto original en inglés): Redis is an open source, in-memory database that persists on disk. The redis-cli command line tool and redis-sentinel service may be vulnerable to integer overflow when parsing specially crafted large multi-bulk network replies. This is a result of a vulnerability in the underlying hiredis library which does not perform an overflow check before calling the calloc() heap allocation function. This issue only impacts systems with heap allocators that do not perform their own overflow checks. Most m",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2021-32762 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2021-32762 (Redis)",
   "Description NVD (texte original en anglais) : Redis is an open source, in-memory database that persists on disk. The redis-cli command line tool and redis-sentinel service may be vulnerable to integer overflow when parsing specially crafted large multi-bulk network replies. This is a result of a vulnerability in the underlying hiredis library which does not perform an overflow check before calling the calloc() heap allocation function. This issue only impacts systems with heap allocators that do not perform their own overflow checks. Most m",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2021-32762 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2021-32762 (Redis)",
   "Descrizione NVD (testo originale in inglese): Redis is an open source, in-memory database that persists on disk. The redis-cli command line tool and redis-sentinel service may be vulnerable to integer overflow when parsing specially crafted large multi-bulk network replies. This is a result of a vulnerability in the underlying hiredis library which does not perform an overflow check before calling the calloc() heap allocation function. This issue only impacts systems with heap allocators that do not perform their own overflow checks. Most m",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2021-32762 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2021-32762 (Redis)",
   "NVDの説明（英語原文）: Redis is an open source, in-memory database that persists on disk. The redis-cli command line tool and redis-sentinel service may be vulnerable to integer overflow when parsing specially crafted large multi-bulk network replies. This is a result of a vulnerability in the underlying hiredis library which does not perform an overflow check before calling the calloc() heap allocation function. This issue only impacts systems with heap allocators that do not perform their own overflow checks. Most m",
   "Redis を CVE-2021-32762 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2021-32762 (Redis)",
   "NVD 설명(영어 원문): Redis is an open source, in-memory database that persists on disk. The redis-cli command line tool and redis-sentinel service may be vulnerable to integer overflow when parsing specially crafted large multi-bulk network replies. This is a result of a vulnerability in the underlying hiredis library which does not perform an overflow check before calling the calloc() heap allocation function. This issue only impacts systems with heap allocators that do not perform their own overflow checks. Most m",
   "Redis을(를) CVE-2021-32762의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2021-32762 (Redis)",
   "Descrição do NVD (texto original em inglês): Redis is an open source, in-memory database that persists on disk. The redis-cli command line tool and redis-sentinel service may be vulnerable to integer overflow when parsing specially crafted large multi-bulk network replies. This is a result of a vulnerability in the underlying hiredis library which does not perform an overflow check before calling the calloc() heap allocation function. This issue only impacts systems with heap allocators that do not perform their own overflow checks. Most m",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2021-32762 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2021-32762（Redis）",
   "NVD 说明（英文原文）：Redis is an open source, in-memory database that persists on disk. The redis-cli command line tool and redis-sentinel service may be vulnerable to integer overflow when parsing specially crafted large multi-bulk network replies. This is a result of a vulnerability in the underlying hiredis library which does not perform an overflow check before calling the calloc() heap allocation function. This issue only impacts systems with heap allocators that do not perform their own overflow checks. Most m",
   "请尽快将 Redis 升级到不受 CVE-2021-32762 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2021-32762（Redis）",
   "NVD 說明（英文原文）：Redis is an open source, in-memory database that persists on disk. The redis-cli command line tool and redis-sentinel service may be vulnerable to integer overflow when parsing specially crafted large multi-bulk network replies. This is a result of a vulnerability in the underlying hiredis library which does not perform an overflow check before calling the calloc() heap allocation function. This issue only impacts systems with heap allocators that do not perform their own overflow checks. Most m",
   "請儘快將 Redis 升級到不受 CVE-2021-32762 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2021-41099": {
  "de": [
   "Bekannte Schwachstelle: CVE-2021-41099 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): Redis is an open source, in-memory database that persists on disk. An integer overflow bug in the underlying string library can be used to corrupt the heap and potentially result with denial of service or remote code execution. The vulnerability involves changing the default proto-max-bulk-len configuration parameter to a very large value and constructing specially crafted network payloads or commands. The problem is fixed in Redis versions 6.2.6, 6.0.16 and 5.0.14. An additional workaround to m",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2021-41099 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2021-41099 (Redis)",
   "Redis is an open source, in-memory database that persists on disk. An integer overflow bug in the underlying string library can be used to corrupt the heap and potentially result with denial of service or remote code execution. The vulnerability involves changing the default proto-max-bulk-len configuration parameter to a very large value and constructing specially crafted network payloads or commands. The problem is fixed in Redis versions 6.2.6, 6.0.16 and 5.0.14. An additional workaround to m",
   "Upgrade Redis to a version not affected by CVE-2021-41099 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2021-41099 (Redis)",
   "Descripción de NVD (texto original en inglés): Redis is an open source, in-memory database that persists on disk. An integer overflow bug in the underlying string library can be used to corrupt the heap and potentially result with denial of service or remote code execution. The vulnerability involves changing the default proto-max-bulk-len configuration parameter to a very large value and constructing specially crafted network payloads or commands. The problem is fixed in Redis versions 6.2.6, 6.0.16 and 5.0.14. An additional workaround to m",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2021-41099 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2021-41099 (Redis)",
   "Description NVD (texte original en anglais) : Redis is an open source, in-memory database that persists on disk. An integer overflow bug in the underlying string library can be used to corrupt the heap and potentially result with denial of service or remote code execution. The vulnerability involves changing the default proto-max-bulk-len configuration parameter to a very large value and constructing specially crafted network payloads or commands. The problem is fixed in Redis versions 6.2.6, 6.0.16 and 5.0.14. An additional workaround to m",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2021-41099 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2021-41099 (Redis)",
   "Descrizione NVD (testo originale in inglese): Redis is an open source, in-memory database that persists on disk. An integer overflow bug in the underlying string library can be used to corrupt the heap and potentially result with denial of service or remote code execution. The vulnerability involves changing the default proto-max-bulk-len configuration parameter to a very large value and constructing specially crafted network payloads or commands. The problem is fixed in Redis versions 6.2.6, 6.0.16 and 5.0.14. An additional workaround to m",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2021-41099 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2021-41099 (Redis)",
   "NVDの説明（英語原文）: Redis is an open source, in-memory database that persists on disk. An integer overflow bug in the underlying string library can be used to corrupt the heap and potentially result with denial of service or remote code execution. The vulnerability involves changing the default proto-max-bulk-len configuration parameter to a very large value and constructing specially crafted network payloads or commands. The problem is fixed in Redis versions 6.2.6, 6.0.16 and 5.0.14. An additional workaround to m",
   "Redis を CVE-2021-41099 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2021-41099 (Redis)",
   "NVD 설명(영어 원문): Redis is an open source, in-memory database that persists on disk. An integer overflow bug in the underlying string library can be used to corrupt the heap and potentially result with denial of service or remote code execution. The vulnerability involves changing the default proto-max-bulk-len configuration parameter to a very large value and constructing specially crafted network payloads or commands. The problem is fixed in Redis versions 6.2.6, 6.0.16 and 5.0.14. An additional workaround to m",
   "Redis을(를) CVE-2021-41099의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2021-41099 (Redis)",
   "Descrição do NVD (texto original em inglês): Redis is an open source, in-memory database that persists on disk. An integer overflow bug in the underlying string library can be used to corrupt the heap and potentially result with denial of service or remote code execution. The vulnerability involves changing the default proto-max-bulk-len configuration parameter to a very large value and constructing specially crafted network payloads or commands. The problem is fixed in Redis versions 6.2.6, 6.0.16 and 5.0.14. An additional workaround to m",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2021-41099 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2021-41099（Redis）",
   "NVD 说明（英文原文）：Redis is an open source, in-memory database that persists on disk. An integer overflow bug in the underlying string library can be used to corrupt the heap and potentially result with denial of service or remote code execution. The vulnerability involves changing the default proto-max-bulk-len configuration parameter to a very large value and constructing specially crafted network payloads or commands. The problem is fixed in Redis versions 6.2.6, 6.0.16 and 5.0.14. An additional workaround to m",
   "请尽快将 Redis 升级到不受 CVE-2021-41099 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2021-41099（Redis）",
   "NVD 說明（英文原文）：Redis is an open source, in-memory database that persists on disk. An integer overflow bug in the underlying string library can be used to corrupt the heap and potentially result with denial of service or remote code execution. The vulnerability involves changing the default proto-max-bulk-len configuration parameter to a very large value and constructing specially crafted network payloads or commands. The problem is fixed in Redis versions 6.2.6, 6.0.16 and 5.0.14. An additional workaround to m",
   "請儘快將 Redis 升級到不受 CVE-2021-41099 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2022-0543": {
  "de": [
   "Bekannte Schwachstelle: CVE-2022-0543 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): It was discovered, that redis, a persistent key-value database, due to a packaging issue, is prone to a (Debian-specific) Lua sandbox escape, which could result in remote code execution.",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2022-0543 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2022-0543 (Redis)",
   "It was discovered, that redis, a persistent key-value database, due to a packaging issue, is prone to a (Debian-specific) Lua sandbox escape, which could result in remote code execution.",
   "Upgrade Redis to a version not affected by CVE-2022-0543 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2022-0543 (Redis)",
   "Descripción de NVD (texto original en inglés): It was discovered, that redis, a persistent key-value database, due to a packaging issue, is prone to a (Debian-specific) Lua sandbox escape, which could result in remote code execution.",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2022-0543 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2022-0543 (Redis)",
   "Description NVD (texte original en anglais) : It was discovered, that redis, a persistent key-value database, due to a packaging issue, is prone to a (Debian-specific) Lua sandbox escape, which could result in remote code execution.",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2022-0543 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2022-0543 (Redis)",
   "Descrizione NVD (testo originale in inglese): It was discovered, that redis, a persistent key-value database, due to a packaging issue, is prone to a (Debian-specific) Lua sandbox escape, which could result in remote code execution.",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2022-0543 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2022-0543 (Redis)",
   "NVDの説明（英語原文）: It was discovered, that redis, a persistent key-value database, due to a packaging issue, is prone to a (Debian-specific) Lua sandbox escape, which could result in remote code execution.",
   "Redis を CVE-2022-0543 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2022-0543 (Redis)",
   "NVD 설명(영어 원문): It was discovered, that redis, a persistent key-value database, due to a packaging issue, is prone to a (Debian-specific) Lua sandbox escape, which could result in remote code execution.",
   "Redis을(를) CVE-2022-0543의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2022-0543 (Redis)",
   "Descrição do NVD (texto original em inglês): It was discovered, that redis, a persistent key-value database, due to a packaging issue, is prone to a (Debian-specific) Lua sandbox escape, which could result in remote code execution.",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2022-0543 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2022-0543（Redis）",
   "NVD 说明（英文原文）：It was discovered, that redis, a persistent key-value database, due to a packaging issue, is prone to a (Debian-specific) Lua sandbox escape, which could result in remote code execution.",
   "请尽快将 Redis 升级到不受 CVE-2022-0543 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2022-0543（Redis）",
   "NVD 說明（英文原文）：It was discovered, that redis, a persistent key-value database, due to a packaging issue, is prone to a (Debian-specific) Lua sandbox escape, which could result in remote code execution.",
   "請儘快將 Redis 升級到不受 CVE-2022-0543 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2022-24834": {
  "de": [
   "Bekannte Schwachstelle: CVE-2022-24834 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): Redis is an in-memory database that persists on disk. A specially crafted Lua script executing in Redis can trigger a heap overflow in the cjson library, and result with heap corruption and potentially remote code execution. The problem exists in all versions of Redis with Lua scripting support, starting from 2.6, and affects only authenticated and authorized users. The problem is fixed in versions 7.0.12, 6.2.13, and 6.0.20.",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2022-24834 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2022-24834 (Redis)",
   "Redis is an in-memory database that persists on disk. A specially crafted Lua script executing in Redis can trigger a heap overflow in the cjson library, and result with heap corruption and potentially remote code execution. The problem exists in all versions of Redis with Lua scripting support, starting from 2.6, and affects only authenticated and authorized users. The problem is fixed in versions 7.0.12, 6.2.13, and 6.0.20.",
   "Upgrade Redis to a version not affected by CVE-2022-24834 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2022-24834 (Redis)",
   "Descripción de NVD (texto original en inglés): Redis is an in-memory database that persists on disk. A specially crafted Lua script executing in Redis can trigger a heap overflow in the cjson library, and result with heap corruption and potentially remote code execution. The problem exists in all versions of Redis with Lua scripting support, starting from 2.6, and affects only authenticated and authorized users. The problem is fixed in versions 7.0.12, 6.2.13, and 6.0.20.",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2022-24834 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2022-24834 (Redis)",
   "Description NVD (texte original en anglais) : Redis is an in-memory database that persists on disk. A specially crafted Lua script executing in Redis can trigger a heap overflow in the cjson library, and result with heap corruption and potentially remote code execution. The problem exists in all versions of Redis with Lua scripting support, starting from 2.6, and affects only authenticated and authorized users. The problem is fixed in versions 7.0.12, 6.2.13, and 6.0.20.",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2022-24834 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2022-24834 (Redis)",
   "Descrizione NVD (testo originale in inglese): Redis is an in-memory database that persists on disk. A specially crafted Lua script executing in Redis can trigger a heap overflow in the cjson library, and result with heap corruption and potentially remote code execution. The problem exists in all versions of Redis with Lua scripting support, starting from 2.6, and affects only authenticated and authorized users. The problem is fixed in versions 7.0.12, 6.2.13, and 6.0.20.",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2022-24834 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2022-24834 (Redis)",
   "NVDの説明（英語原文）: Redis is an in-memory database that persists on disk. A specially crafted Lua script executing in Redis can trigger a heap overflow in the cjson library, and result with heap corruption and potentially remote code execution. The problem exists in all versions of Redis with Lua scripting support, starting from 2.6, and affects only authenticated and authorized users. The problem is fixed in versions 7.0.12, 6.2.13, and 6.0.20.",
   "Redis を CVE-2022-24834 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2022-24834 (Redis)",
   "NVD 설명(영어 원문): Redis is an in-memory database that persists on disk. A specially crafted Lua script executing in Redis can trigger a heap overflow in the cjson library, and result with heap corruption and potentially remote code execution. The problem exists in all versions of Redis with Lua scripting support, starting from 2.6, and affects only authenticated and authorized users. The problem is fixed in versions 7.0.12, 6.2.13, and 6.0.20.",
   "Redis을(를) CVE-2022-24834의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2022-24834 (Redis)",
   "Descrição do NVD (texto original em inglês): Redis is an in-memory database that persists on disk. A specially crafted Lua script executing in Redis can trigger a heap overflow in the cjson library, and result with heap corruption and potentially remote code execution. The problem exists in all versions of Redis with Lua scripting support, starting from 2.6, and affects only authenticated and authorized users. The problem is fixed in versions 7.0.12, 6.2.13, and 6.0.20.",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2022-24834 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2022-24834（Redis）",
   "NVD 说明（英文原文）：Redis is an in-memory database that persists on disk. A specially crafted Lua script executing in Redis can trigger a heap overflow in the cjson library, and result with heap corruption and potentially remote code execution. The problem exists in all versions of Redis with Lua scripting support, starting from 2.6, and affects only authenticated and authorized users. The problem is fixed in versions 7.0.12, 6.2.13, and 6.0.20.",
   "请尽快将 Redis 升级到不受 CVE-2022-24834 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2022-24834（Redis）",
   "NVD 說明（英文原文）：Redis is an in-memory database that persists on disk. A specially crafted Lua script executing in Redis can trigger a heap overflow in the cjson library, and result with heap corruption and potentially remote code execution. The problem exists in all versions of Redis with Lua scripting support, starting from 2.6, and affects only authenticated and authorized users. The problem is fixed in versions 7.0.12, 6.2.13, and 6.0.20.",
   "請儘快將 Redis 升級到不受 CVE-2022-24834 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2022-31144": {
  "de": [
   "Bekannte Schwachstelle: CVE-2022-31144 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): Redis is an in-memory database that persists on disk. A specially crafted `XAUTOCLAIM` command on a stream key in a specific state may result with heap overflow, and potentially remote code execution. This problem affects versions on the 7.x branch prior to 7.0.4. The patch is released in version 7.0.4.",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2022-31144 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2022-31144 (Redis)",
   "Redis is an in-memory database that persists on disk. A specially crafted `XAUTOCLAIM` command on a stream key in a specific state may result with heap overflow, and potentially remote code execution. This problem affects versions on the 7.x branch prior to 7.0.4. The patch is released in version 7.0.4.",
   "Upgrade Redis to a version not affected by CVE-2022-31144 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2022-31144 (Redis)",
   "Descripción de NVD (texto original en inglés): Redis is an in-memory database that persists on disk. A specially crafted `XAUTOCLAIM` command on a stream key in a specific state may result with heap overflow, and potentially remote code execution. This problem affects versions on the 7.x branch prior to 7.0.4. The patch is released in version 7.0.4.",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2022-31144 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2022-31144 (Redis)",
   "Description NVD (texte original en anglais) : Redis is an in-memory database that persists on disk. A specially crafted `XAUTOCLAIM` command on a stream key in a specific state may result with heap overflow, and potentially remote code execution. This problem affects versions on the 7.x branch prior to 7.0.4. The patch is released in version 7.0.4.",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2022-31144 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2022-31144 (Redis)",
   "Descrizione NVD (testo originale in inglese): Redis is an in-memory database that persists on disk. A specially crafted `XAUTOCLAIM` command on a stream key in a specific state may result with heap overflow, and potentially remote code execution. This problem affects versions on the 7.x branch prior to 7.0.4. The patch is released in version 7.0.4.",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2022-31144 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2022-31144 (Redis)",
   "NVDの説明（英語原文）: Redis is an in-memory database that persists on disk. A specially crafted `XAUTOCLAIM` command on a stream key in a specific state may result with heap overflow, and potentially remote code execution. This problem affects versions on the 7.x branch prior to 7.0.4. The patch is released in version 7.0.4.",
   "Redis を CVE-2022-31144 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2022-31144 (Redis)",
   "NVD 설명(영어 원문): Redis is an in-memory database that persists on disk. A specially crafted `XAUTOCLAIM` command on a stream key in a specific state may result with heap overflow, and potentially remote code execution. This problem affects versions on the 7.x branch prior to 7.0.4. The patch is released in version 7.0.4.",
   "Redis을(를) CVE-2022-31144의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2022-31144 (Redis)",
   "Descrição do NVD (texto original em inglês): Redis is an in-memory database that persists on disk. A specially crafted `XAUTOCLAIM` command on a stream key in a specific state may result with heap overflow, and potentially remote code execution. This problem affects versions on the 7.x branch prior to 7.0.4. The patch is released in version 7.0.4.",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2022-31144 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2022-31144（Redis）",
   "NVD 说明（英文原文）：Redis is an in-memory database that persists on disk. A specially crafted `XAUTOCLAIM` command on a stream key in a specific state may result with heap overflow, and potentially remote code execution. This problem affects versions on the 7.x branch prior to 7.0.4. The patch is released in version 7.0.4.",
   "请尽快将 Redis 升级到不受 CVE-2022-31144 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2022-31144（Redis）",
   "NVD 說明（英文原文）：Redis is an in-memory database that persists on disk. A specially crafted `XAUTOCLAIM` command on a stream key in a specific state may result with heap overflow, and potentially remote code execution. This problem affects versions on the 7.x branch prior to 7.0.4. The patch is released in version 7.0.4.",
   "請儘快將 Redis 升級到不受 CVE-2022-31144 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2022-33105": {
  "de": [
   "Bekannte Schwachstelle: CVE-2022-33105 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): Redis v7.0 was discovered to contain a memory leak via the component streamGetEdgeID.",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2022-33105 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2022-33105 (Redis)",
   "Redis v7.0 was discovered to contain a memory leak via the component streamGetEdgeID.",
   "Upgrade Redis to a version not affected by CVE-2022-33105 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2022-33105 (Redis)",
   "Descripción de NVD (texto original en inglés): Redis v7.0 was discovered to contain a memory leak via the component streamGetEdgeID.",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2022-33105 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2022-33105 (Redis)",
   "Description NVD (texte original en anglais) : Redis v7.0 was discovered to contain a memory leak via the component streamGetEdgeID.",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2022-33105 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2022-33105 (Redis)",
   "Descrizione NVD (testo originale in inglese): Redis v7.0 was discovered to contain a memory leak via the component streamGetEdgeID.",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2022-33105 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2022-33105 (Redis)",
   "NVDの説明（英語原文）: Redis v7.0 was discovered to contain a memory leak via the component streamGetEdgeID.",
   "Redis を CVE-2022-33105 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2022-33105 (Redis)",
   "NVD 설명(영어 원문): Redis v7.0 was discovered to contain a memory leak via the component streamGetEdgeID.",
   "Redis을(를) CVE-2022-33105의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2022-33105 (Redis)",
   "Descrição do NVD (texto original em inglês): Redis v7.0 was discovered to contain a memory leak via the component streamGetEdgeID.",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2022-33105 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2022-33105（Redis）",
   "NVD 说明（英文原文）：Redis v7.0 was discovered to contain a memory leak via the component streamGetEdgeID.",
   "请尽快将 Redis 升级到不受 CVE-2022-33105 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2022-33105（Redis）",
   "NVD 說明（英文原文）：Redis v7.0 was discovered to contain a memory leak via the component streamGetEdgeID.",
   "請儘快將 Redis 升級到不受 CVE-2022-33105 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2022-35951": {
  "de": [
   "Bekannte Schwachstelle: CVE-2022-35951 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): Redis is an in-memory database that persists on disk. Versions 7.0.0 and above, prior to 7.0.5 are vulnerable to an Integer Overflow. Executing an `XAUTOCLAIM` command on a stream key in a specific state, with a specially crafted `COUNT` argument may cause an integer overflow, a subsequent heap overflow, and potentially lead to remote code execution. This has been patched in Redis version 7.0.5. No known workarounds exist.",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2022-35951 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2022-35951 (Redis)",
   "Redis is an in-memory database that persists on disk. Versions 7.0.0 and above, prior to 7.0.5 are vulnerable to an Integer Overflow. Executing an `XAUTOCLAIM` command on a stream key in a specific state, with a specially crafted `COUNT` argument may cause an integer overflow, a subsequent heap overflow, and potentially lead to remote code execution. This has been patched in Redis version 7.0.5. No known workarounds exist.",
   "Upgrade Redis to a version not affected by CVE-2022-35951 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2022-35951 (Redis)",
   "Descripción de NVD (texto original en inglés): Redis is an in-memory database that persists on disk. Versions 7.0.0 and above, prior to 7.0.5 are vulnerable to an Integer Overflow. Executing an `XAUTOCLAIM` command on a stream key in a specific state, with a specially crafted `COUNT` argument may cause an integer overflow, a subsequent heap overflow, and potentially lead to remote code execution. This has been patched in Redis version 7.0.5. No known workarounds exist.",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2022-35951 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2022-35951 (Redis)",
   "Description NVD (texte original en anglais) : Redis is an in-memory database that persists on disk. Versions 7.0.0 and above, prior to 7.0.5 are vulnerable to an Integer Overflow. Executing an `XAUTOCLAIM` command on a stream key in a specific state, with a specially crafted `COUNT` argument may cause an integer overflow, a subsequent heap overflow, and potentially lead to remote code execution. This has been patched in Redis version 7.0.5. No known workarounds exist.",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2022-35951 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2022-35951 (Redis)",
   "Descrizione NVD (testo originale in inglese): Redis is an in-memory database that persists on disk. Versions 7.0.0 and above, prior to 7.0.5 are vulnerable to an Integer Overflow. Executing an `XAUTOCLAIM` command on a stream key in a specific state, with a specially crafted `COUNT` argument may cause an integer overflow, a subsequent heap overflow, and potentially lead to remote code execution. This has been patched in Redis version 7.0.5. No known workarounds exist.",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2022-35951 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2022-35951 (Redis)",
   "NVDの説明（英語原文）: Redis is an in-memory database that persists on disk. Versions 7.0.0 and above, prior to 7.0.5 are vulnerable to an Integer Overflow. Executing an `XAUTOCLAIM` command on a stream key in a specific state, with a specially crafted `COUNT` argument may cause an integer overflow, a subsequent heap overflow, and potentially lead to remote code execution. This has been patched in Redis version 7.0.5. No known workarounds exist.",
   "Redis を CVE-2022-35951 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2022-35951 (Redis)",
   "NVD 설명(영어 원문): Redis is an in-memory database that persists on disk. Versions 7.0.0 and above, prior to 7.0.5 are vulnerable to an Integer Overflow. Executing an `XAUTOCLAIM` command on a stream key in a specific state, with a specially crafted `COUNT` argument may cause an integer overflow, a subsequent heap overflow, and potentially lead to remote code execution. This has been patched in Redis version 7.0.5. No known workarounds exist.",
   "Redis을(를) CVE-2022-35951의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2022-35951 (Redis)",
   "Descrição do NVD (texto original em inglês): Redis is an in-memory database that persists on disk. Versions 7.0.0 and above, prior to 7.0.5 are vulnerable to an Integer Overflow. Executing an `XAUTOCLAIM` command on a stream key in a specific state, with a specially crafted `COUNT` argument may cause an integer overflow, a subsequent heap overflow, and potentially lead to remote code execution. This has been patched in Redis version 7.0.5. No known workarounds exist.",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2022-35951 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2022-35951（Redis）",
   "NVD 说明（英文原文）：Redis is an in-memory database that persists on disk. Versions 7.0.0 and above, prior to 7.0.5 are vulnerable to an Integer Overflow. Executing an `XAUTOCLAIM` command on a stream key in a specific state, with a specially crafted `COUNT` argument may cause an integer overflow, a subsequent heap overflow, and potentially lead to remote code execution. This has been patched in Redis version 7.0.5. No known workarounds exist.",
   "请尽快将 Redis 升级到不受 CVE-2022-35951 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2022-35951（Redis）",
   "NVD 說明（英文原文）：Redis is an in-memory database that persists on disk. Versions 7.0.0 and above, prior to 7.0.5 are vulnerable to an Integer Overflow. Executing an `XAUTOCLAIM` command on a stream key in a specific state, with a specially crafted `COUNT` argument may cause an integer overflow, a subsequent heap overflow, and potentially lead to remote code execution. This has been patched in Redis version 7.0.5. No known workarounds exist.",
   "請儘快將 Redis 升級到不受 CVE-2022-35951 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2023-31655": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-31655 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): redis v7.0.10 was discovered to contain a segmentation violation. This vulnerability allows attackers to cause a Denial of Service (DoS) via unspecified vectors.",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2023-31655 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-31655 (Redis)",
   "redis v7.0.10 was discovered to contain a segmentation violation. This vulnerability allows attackers to cause a Denial of Service (DoS) via unspecified vectors.",
   "Upgrade Redis to a version not affected by CVE-2023-31655 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-31655 (Redis)",
   "Descripción de NVD (texto original en inglés): redis v7.0.10 was discovered to contain a segmentation violation. This vulnerability allows attackers to cause a Denial of Service (DoS) via unspecified vectors.",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2023-31655 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-31655 (Redis)",
   "Description NVD (texte original en anglais) : redis v7.0.10 was discovered to contain a segmentation violation. This vulnerability allows attackers to cause a Denial of Service (DoS) via unspecified vectors.",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2023-31655 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-31655 (Redis)",
   "Descrizione NVD (testo originale in inglese): redis v7.0.10 was discovered to contain a segmentation violation. This vulnerability allows attackers to cause a Denial of Service (DoS) via unspecified vectors.",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2023-31655 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-31655 (Redis)",
   "NVDの説明（英語原文）: redis v7.0.10 was discovered to contain a segmentation violation. This vulnerability allows attackers to cause a Denial of Service (DoS) via unspecified vectors.",
   "Redis を CVE-2023-31655 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-31655 (Redis)",
   "NVD 설명(영어 원문): redis v7.0.10 was discovered to contain a segmentation violation. This vulnerability allows attackers to cause a Denial of Service (DoS) via unspecified vectors.",
   "Redis을(를) CVE-2023-31655의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-31655 (Redis)",
   "Descrição do NVD (texto original em inglês): redis v7.0.10 was discovered to contain a segmentation violation. This vulnerability allows attackers to cause a Denial of Service (DoS) via unspecified vectors.",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2023-31655 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-31655（Redis）",
   "NVD 说明（英文原文）：redis v7.0.10 was discovered to contain a segmentation violation. This vulnerability allows attackers to cause a Denial of Service (DoS) via unspecified vectors.",
   "请尽快将 Redis 升级到不受 CVE-2023-31655 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-31655（Redis）",
   "NVD 說明（英文原文）：redis v7.0.10 was discovered to contain a segmentation violation. This vulnerability allows attackers to cause a Denial of Service (DoS) via unspecified vectors.",
   "請儘快將 Redis 升級到不受 CVE-2023-31655 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2023-36824": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-36824 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): Redis is an in-memory database that persists on disk. In Redit 7.0 prior to 7.0.12, extracting key names from a command and a list of arguments may, in some cases, trigger a heap overflow and result in reading random heap memory, heap corruption and potentially remote code execution. Several scenarios that may lead to authenticated users executing a specially crafted `COMMAND GETKEYS` or `COMMAND GETKEYSANDFLAGS`and authenticated users who were set with ACL rules that match key names, executing ",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2023-36824 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-36824 (Redis)",
   "Redis is an in-memory database that persists on disk. In Redit 7.0 prior to 7.0.12, extracting key names from a command and a list of arguments may, in some cases, trigger a heap overflow and result in reading random heap memory, heap corruption and potentially remote code execution. Several scenarios that may lead to authenticated users executing a specially crafted `COMMAND GETKEYS` or `COMMAND GETKEYSANDFLAGS`and authenticated users who were set with ACL rules that match key names, executing ",
   "Upgrade Redis to a version not affected by CVE-2023-36824 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-36824 (Redis)",
   "Descripción de NVD (texto original en inglés): Redis is an in-memory database that persists on disk. In Redit 7.0 prior to 7.0.12, extracting key names from a command and a list of arguments may, in some cases, trigger a heap overflow and result in reading random heap memory, heap corruption and potentially remote code execution. Several scenarios that may lead to authenticated users executing a specially crafted `COMMAND GETKEYS` or `COMMAND GETKEYSANDFLAGS`and authenticated users who were set with ACL rules that match key names, executing ",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2023-36824 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-36824 (Redis)",
   "Description NVD (texte original en anglais) : Redis is an in-memory database that persists on disk. In Redit 7.0 prior to 7.0.12, extracting key names from a command and a list of arguments may, in some cases, trigger a heap overflow and result in reading random heap memory, heap corruption and potentially remote code execution. Several scenarios that may lead to authenticated users executing a specially crafted `COMMAND GETKEYS` or `COMMAND GETKEYSANDFLAGS`and authenticated users who were set with ACL rules that match key names, executing ",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2023-36824 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-36824 (Redis)",
   "Descrizione NVD (testo originale in inglese): Redis is an in-memory database that persists on disk. In Redit 7.0 prior to 7.0.12, extracting key names from a command and a list of arguments may, in some cases, trigger a heap overflow and result in reading random heap memory, heap corruption and potentially remote code execution. Several scenarios that may lead to authenticated users executing a specially crafted `COMMAND GETKEYS` or `COMMAND GETKEYSANDFLAGS`and authenticated users who were set with ACL rules that match key names, executing ",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2023-36824 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-36824 (Redis)",
   "NVDの説明（英語原文）: Redis is an in-memory database that persists on disk. In Redit 7.0 prior to 7.0.12, extracting key names from a command and a list of arguments may, in some cases, trigger a heap overflow and result in reading random heap memory, heap corruption and potentially remote code execution. Several scenarios that may lead to authenticated users executing a specially crafted `COMMAND GETKEYS` or `COMMAND GETKEYSANDFLAGS`and authenticated users who were set with ACL rules that match key names, executing ",
   "Redis を CVE-2023-36824 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-36824 (Redis)",
   "NVD 설명(영어 원문): Redis is an in-memory database that persists on disk. In Redit 7.0 prior to 7.0.12, extracting key names from a command and a list of arguments may, in some cases, trigger a heap overflow and result in reading random heap memory, heap corruption and potentially remote code execution. Several scenarios that may lead to authenticated users executing a specially crafted `COMMAND GETKEYS` or `COMMAND GETKEYSANDFLAGS`and authenticated users who were set with ACL rules that match key names, executing ",
   "Redis을(를) CVE-2023-36824의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-36824 (Redis)",
   "Descrição do NVD (texto original em inglês): Redis is an in-memory database that persists on disk. In Redit 7.0 prior to 7.0.12, extracting key names from a command and a list of arguments may, in some cases, trigger a heap overflow and result in reading random heap memory, heap corruption and potentially remote code execution. Several scenarios that may lead to authenticated users executing a specially crafted `COMMAND GETKEYS` or `COMMAND GETKEYSANDFLAGS`and authenticated users who were set with ACL rules that match key names, executing ",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2023-36824 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-36824（Redis）",
   "NVD 说明（英文原文）：Redis is an in-memory database that persists on disk. In Redit 7.0 prior to 7.0.12, extracting key names from a command and a list of arguments may, in some cases, trigger a heap overflow and result in reading random heap memory, heap corruption and potentially remote code execution. Several scenarios that may lead to authenticated users executing a specially crafted `COMMAND GETKEYS` or `COMMAND GETKEYSANDFLAGS`and authenticated users who were set with ACL rules that match key names, executing ",
   "请尽快将 Redis 升级到不受 CVE-2023-36824 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-36824（Redis）",
   "NVD 說明（英文原文）：Redis is an in-memory database that persists on disk. In Redit 7.0 prior to 7.0.12, extracting key names from a command and a list of arguments may, in some cases, trigger a heap overflow and result in reading random heap memory, heap corruption and potentially remote code execution. Several scenarios that may lead to authenticated users executing a specially crafted `COMMAND GETKEYS` or `COMMAND GETKEYSANDFLAGS`and authenticated users who were set with ACL rules that match key names, executing ",
   "請儘快將 Redis 升級到不受 CVE-2023-36824 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2023-41056": {
  "de": [
   "Bekannte Schwachstelle: CVE-2023-41056 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): Redis is an in-memory database that persists on disk. Redis incorrectly handles resizing of memory buffers which can result in integer overflow that leads to heap overflow and potential remote code execution. This issue has been patched in version 7.0.15 and 7.2.4.",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2023-41056 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2023-41056 (Redis)",
   "Redis is an in-memory database that persists on disk. Redis incorrectly handles resizing of memory buffers which can result in integer overflow that leads to heap overflow and potential remote code execution. This issue has been patched in version 7.0.15 and 7.2.4.",
   "Upgrade Redis to a version not affected by CVE-2023-41056 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2023-41056 (Redis)",
   "Descripción de NVD (texto original en inglés): Redis is an in-memory database that persists on disk. Redis incorrectly handles resizing of memory buffers which can result in integer overflow that leads to heap overflow and potential remote code execution. This issue has been patched in version 7.0.15 and 7.2.4.",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2023-41056 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2023-41056 (Redis)",
   "Description NVD (texte original en anglais) : Redis is an in-memory database that persists on disk. Redis incorrectly handles resizing of memory buffers which can result in integer overflow that leads to heap overflow and potential remote code execution. This issue has been patched in version 7.0.15 and 7.2.4.",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2023-41056 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2023-41056 (Redis)",
   "Descrizione NVD (testo originale in inglese): Redis is an in-memory database that persists on disk. Redis incorrectly handles resizing of memory buffers which can result in integer overflow that leads to heap overflow and potential remote code execution. This issue has been patched in version 7.0.15 and 7.2.4.",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2023-41056 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2023-41056 (Redis)",
   "NVDの説明（英語原文）: Redis is an in-memory database that persists on disk. Redis incorrectly handles resizing of memory buffers which can result in integer overflow that leads to heap overflow and potential remote code execution. This issue has been patched in version 7.0.15 and 7.2.4.",
   "Redis を CVE-2023-41056 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2023-41056 (Redis)",
   "NVD 설명(영어 원문): Redis is an in-memory database that persists on disk. Redis incorrectly handles resizing of memory buffers which can result in integer overflow that leads to heap overflow and potential remote code execution. This issue has been patched in version 7.0.15 and 7.2.4.",
   "Redis을(를) CVE-2023-41056의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2023-41056 (Redis)",
   "Descrição do NVD (texto original em inglês): Redis is an in-memory database that persists on disk. Redis incorrectly handles resizing of memory buffers which can result in integer overflow that leads to heap overflow and potential remote code execution. This issue has been patched in version 7.0.15 and 7.2.4.",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2023-41056 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2023-41056（Redis）",
   "NVD 说明（英文原文）：Redis is an in-memory database that persists on disk. Redis incorrectly handles resizing of memory buffers which can result in integer overflow that leads to heap overflow and potential remote code execution. This issue has been patched in version 7.0.15 and 7.2.4.",
   "请尽快将 Redis 升级到不受 CVE-2023-41056 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2023-41056（Redis）",
   "NVD 說明（英文原文）：Redis is an in-memory database that persists on disk. Redis incorrectly handles resizing of memory buffers which can result in integer overflow that leads to heap overflow and potential remote code execution. This issue has been patched in version 7.0.15 and 7.2.4.",
   "請儘快將 Redis 升級到不受 CVE-2023-41056 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2024-31449": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-31449 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): Redis is an open source, in-memory database that persists on disk. An authenticated user may use a specially crafted Lua script to trigger a stack buffer overflow in the bit library, which may potentially lead to remote code execution. The problem exists in all versions of Redis with Lua scripting. This problem has been fixed in Redis versions 6.2.16, 7.2.6, and 7.4.1. Users are advised to upgrade. There are no known workarounds for this vulnerability.",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2024-31449 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-31449 (Redis)",
   "Redis is an open source, in-memory database that persists on disk. An authenticated user may use a specially crafted Lua script to trigger a stack buffer overflow in the bit library, which may potentially lead to remote code execution. The problem exists in all versions of Redis with Lua scripting. This problem has been fixed in Redis versions 6.2.16, 7.2.6, and 7.4.1. Users are advised to upgrade. There are no known workarounds for this vulnerability.",
   "Upgrade Redis to a version not affected by CVE-2024-31449 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-31449 (Redis)",
   "Descripción de NVD (texto original en inglés): Redis is an open source, in-memory database that persists on disk. An authenticated user may use a specially crafted Lua script to trigger a stack buffer overflow in the bit library, which may potentially lead to remote code execution. The problem exists in all versions of Redis with Lua scripting. This problem has been fixed in Redis versions 6.2.16, 7.2.6, and 7.4.1. Users are advised to upgrade. There are no known workarounds for this vulnerability.",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2024-31449 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-31449 (Redis)",
   "Description NVD (texte original en anglais) : Redis is an open source, in-memory database that persists on disk. An authenticated user may use a specially crafted Lua script to trigger a stack buffer overflow in the bit library, which may potentially lead to remote code execution. The problem exists in all versions of Redis with Lua scripting. This problem has been fixed in Redis versions 6.2.16, 7.2.6, and 7.4.1. Users are advised to upgrade. There are no known workarounds for this vulnerability.",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2024-31449 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-31449 (Redis)",
   "Descrizione NVD (testo originale in inglese): Redis is an open source, in-memory database that persists on disk. An authenticated user may use a specially crafted Lua script to trigger a stack buffer overflow in the bit library, which may potentially lead to remote code execution. The problem exists in all versions of Redis with Lua scripting. This problem has been fixed in Redis versions 6.2.16, 7.2.6, and 7.4.1. Users are advised to upgrade. There are no known workarounds for this vulnerability.",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2024-31449 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-31449 (Redis)",
   "NVDの説明（英語原文）: Redis is an open source, in-memory database that persists on disk. An authenticated user may use a specially crafted Lua script to trigger a stack buffer overflow in the bit library, which may potentially lead to remote code execution. The problem exists in all versions of Redis with Lua scripting. This problem has been fixed in Redis versions 6.2.16, 7.2.6, and 7.4.1. Users are advised to upgrade. There are no known workarounds for this vulnerability.",
   "Redis を CVE-2024-31449 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-31449 (Redis)",
   "NVD 설명(영어 원문): Redis is an open source, in-memory database that persists on disk. An authenticated user may use a specially crafted Lua script to trigger a stack buffer overflow in the bit library, which may potentially lead to remote code execution. The problem exists in all versions of Redis with Lua scripting. This problem has been fixed in Redis versions 6.2.16, 7.2.6, and 7.4.1. Users are advised to upgrade. There are no known workarounds for this vulnerability.",
   "Redis을(를) CVE-2024-31449의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-31449 (Redis)",
   "Descrição do NVD (texto original em inglês): Redis is an open source, in-memory database that persists on disk. An authenticated user may use a specially crafted Lua script to trigger a stack buffer overflow in the bit library, which may potentially lead to remote code execution. The problem exists in all versions of Redis with Lua scripting. This problem has been fixed in Redis versions 6.2.16, 7.2.6, and 7.4.1. Users are advised to upgrade. There are no known workarounds for this vulnerability.",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2024-31449 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-31449（Redis）",
   "NVD 说明（英文原文）：Redis is an open source, in-memory database that persists on disk. An authenticated user may use a specially crafted Lua script to trigger a stack buffer overflow in the bit library, which may potentially lead to remote code execution. The problem exists in all versions of Redis with Lua scripting. This problem has been fixed in Redis versions 6.2.16, 7.2.6, and 7.4.1. Users are advised to upgrade. There are no known workarounds for this vulnerability.",
   "请尽快将 Redis 升级到不受 CVE-2024-31449 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-31449（Redis）",
   "NVD 說明（英文原文）：Redis is an open source, in-memory database that persists on disk. An authenticated user may use a specially crafted Lua script to trigger a stack buffer overflow in the bit library, which may potentially lead to remote code execution. The problem exists in all versions of Redis with Lua scripting. This problem has been fixed in Redis versions 6.2.16, 7.2.6, and 7.4.1. Users are advised to upgrade. There are no known workarounds for this vulnerability.",
   "請儘快將 Redis 升級到不受 CVE-2024-31449 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2024-46981": {
  "de": [
   "Bekannte Schwachstelle: CVE-2024-46981 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): Redis is an open source, in-memory database that persists on disk. An authenticated user may use a specially crafted Lua script to manipulate the garbage collector and potentially lead to remote code execution. The problem is fixed in 7.4.2, 7.2.7, and 6.2.17. An additional workaround to mitigate the problem without patching the redis-server executable is to prevent users from executing Lua scripts. This can be done using ACL to restrict EVAL and EVALSHA commands.",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2024-46981 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2024-46981 (Redis)",
   "Redis is an open source, in-memory database that persists on disk. An authenticated user may use a specially crafted Lua script to manipulate the garbage collector and potentially lead to remote code execution. The problem is fixed in 7.4.2, 7.2.7, and 6.2.17. An additional workaround to mitigate the problem without patching the redis-server executable is to prevent users from executing Lua scripts. This can be done using ACL to restrict EVAL and EVALSHA commands.",
   "Upgrade Redis to a version not affected by CVE-2024-46981 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2024-46981 (Redis)",
   "Descripción de NVD (texto original en inglés): Redis is an open source, in-memory database that persists on disk. An authenticated user may use a specially crafted Lua script to manipulate the garbage collector and potentially lead to remote code execution. The problem is fixed in 7.4.2, 7.2.7, and 6.2.17. An additional workaround to mitigate the problem without patching the redis-server executable is to prevent users from executing Lua scripts. This can be done using ACL to restrict EVAL and EVALSHA commands.",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2024-46981 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2024-46981 (Redis)",
   "Description NVD (texte original en anglais) : Redis is an open source, in-memory database that persists on disk. An authenticated user may use a specially crafted Lua script to manipulate the garbage collector and potentially lead to remote code execution. The problem is fixed in 7.4.2, 7.2.7, and 6.2.17. An additional workaround to mitigate the problem without patching the redis-server executable is to prevent users from executing Lua scripts. This can be done using ACL to restrict EVAL and EVALSHA commands.",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2024-46981 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2024-46981 (Redis)",
   "Descrizione NVD (testo originale in inglese): Redis is an open source, in-memory database that persists on disk. An authenticated user may use a specially crafted Lua script to manipulate the garbage collector and potentially lead to remote code execution. The problem is fixed in 7.4.2, 7.2.7, and 6.2.17. An additional workaround to mitigate the problem without patching the redis-server executable is to prevent users from executing Lua scripts. This can be done using ACL to restrict EVAL and EVALSHA commands.",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2024-46981 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2024-46981 (Redis)",
   "NVDの説明（英語原文）: Redis is an open source, in-memory database that persists on disk. An authenticated user may use a specially crafted Lua script to manipulate the garbage collector and potentially lead to remote code execution. The problem is fixed in 7.4.2, 7.2.7, and 6.2.17. An additional workaround to mitigate the problem without patching the redis-server executable is to prevent users from executing Lua scripts. This can be done using ACL to restrict EVAL and EVALSHA commands.",
   "Redis を CVE-2024-46981 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2024-46981 (Redis)",
   "NVD 설명(영어 원문): Redis is an open source, in-memory database that persists on disk. An authenticated user may use a specially crafted Lua script to manipulate the garbage collector and potentially lead to remote code execution. The problem is fixed in 7.4.2, 7.2.7, and 6.2.17. An additional workaround to mitigate the problem without patching the redis-server executable is to prevent users from executing Lua scripts. This can be done using ACL to restrict EVAL and EVALSHA commands.",
   "Redis을(를) CVE-2024-46981의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2024-46981 (Redis)",
   "Descrição do NVD (texto original em inglês): Redis is an open source, in-memory database that persists on disk. An authenticated user may use a specially crafted Lua script to manipulate the garbage collector and potentially lead to remote code execution. The problem is fixed in 7.4.2, 7.2.7, and 6.2.17. An additional workaround to mitigate the problem without patching the redis-server executable is to prevent users from executing Lua scripts. This can be done using ACL to restrict EVAL and EVALSHA commands.",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2024-46981 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2024-46981（Redis）",
   "NVD 说明（英文原文）：Redis is an open source, in-memory database that persists on disk. An authenticated user may use a specially crafted Lua script to manipulate the garbage collector and potentially lead to remote code execution. The problem is fixed in 7.4.2, 7.2.7, and 6.2.17. An additional workaround to mitigate the problem without patching the redis-server executable is to prevent users from executing Lua scripts. This can be done using ACL to restrict EVAL and EVALSHA commands.",
   "请尽快将 Redis 升级到不受 CVE-2024-46981 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2024-46981（Redis）",
   "NVD 說明（英文原文）：Redis is an open source, in-memory database that persists on disk. An authenticated user may use a specially crafted Lua script to manipulate the garbage collector and potentially lead to remote code execution. The problem is fixed in 7.4.2, 7.2.7, and 6.2.17. An additional workaround to mitigate the problem without patching the redis-server executable is to prevent users from executing Lua scripts. This can be done using ACL to restrict EVAL and EVALSHA commands.",
   "請儘快將 Redis 升級到不受 CVE-2024-46981 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2025-21605": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-21605 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): Redis is an open source, in-memory database that persists on disk. In versions starting at 2.6 and prior to 7.4.3, An unauthenticated client can cause unlimited growth of output buffers, until the server runs out of memory or is killed. By default, the Redis configuration does not limit the output buffer of normal clients (see client-output-buffer-limit). Therefore, the output buffer can grow unlimitedly over time. As a result, the service is exhausted and the memory is unavailable. When passwor",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2025-21605 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-21605 (Redis)",
   "Redis is an open source, in-memory database that persists on disk. In versions starting at 2.6 and prior to 7.4.3, An unauthenticated client can cause unlimited growth of output buffers, until the server runs out of memory or is killed. By default, the Redis configuration does not limit the output buffer of normal clients (see client-output-buffer-limit). Therefore, the output buffer can grow unlimitedly over time. As a result, the service is exhausted and the memory is unavailable. When passwor",
   "Upgrade Redis to a version not affected by CVE-2025-21605 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-21605 (Redis)",
   "Descripción de NVD (texto original en inglés): Redis is an open source, in-memory database that persists on disk. In versions starting at 2.6 and prior to 7.4.3, An unauthenticated client can cause unlimited growth of output buffers, until the server runs out of memory or is killed. By default, the Redis configuration does not limit the output buffer of normal clients (see client-output-buffer-limit). Therefore, the output buffer can grow unlimitedly over time. As a result, the service is exhausted and the memory is unavailable. When passwor",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2025-21605 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-21605 (Redis)",
   "Description NVD (texte original en anglais) : Redis is an open source, in-memory database that persists on disk. In versions starting at 2.6 and prior to 7.4.3, An unauthenticated client can cause unlimited growth of output buffers, until the server runs out of memory or is killed. By default, the Redis configuration does not limit the output buffer of normal clients (see client-output-buffer-limit). Therefore, the output buffer can grow unlimitedly over time. As a result, the service is exhausted and the memory is unavailable. When passwor",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2025-21605 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-21605 (Redis)",
   "Descrizione NVD (testo originale in inglese): Redis is an open source, in-memory database that persists on disk. In versions starting at 2.6 and prior to 7.4.3, An unauthenticated client can cause unlimited growth of output buffers, until the server runs out of memory or is killed. By default, the Redis configuration does not limit the output buffer of normal clients (see client-output-buffer-limit). Therefore, the output buffer can grow unlimitedly over time. As a result, the service is exhausted and the memory is unavailable. When passwor",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2025-21605 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-21605 (Redis)",
   "NVDの説明（英語原文）: Redis is an open source, in-memory database that persists on disk. In versions starting at 2.6 and prior to 7.4.3, An unauthenticated client can cause unlimited growth of output buffers, until the server runs out of memory or is killed. By default, the Redis configuration does not limit the output buffer of normal clients (see client-output-buffer-limit). Therefore, the output buffer can grow unlimitedly over time. As a result, the service is exhausted and the memory is unavailable. When passwor",
   "Redis を CVE-2025-21605 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-21605 (Redis)",
   "NVD 설명(영어 원문): Redis is an open source, in-memory database that persists on disk. In versions starting at 2.6 and prior to 7.4.3, An unauthenticated client can cause unlimited growth of output buffers, until the server runs out of memory or is killed. By default, the Redis configuration does not limit the output buffer of normal clients (see client-output-buffer-limit). Therefore, the output buffer can grow unlimitedly over time. As a result, the service is exhausted and the memory is unavailable. When passwor",
   "Redis을(를) CVE-2025-21605의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-21605 (Redis)",
   "Descrição do NVD (texto original em inglês): Redis is an open source, in-memory database that persists on disk. In versions starting at 2.6 and prior to 7.4.3, An unauthenticated client can cause unlimited growth of output buffers, until the server runs out of memory or is killed. By default, the Redis configuration does not limit the output buffer of normal clients (see client-output-buffer-limit). Therefore, the output buffer can grow unlimitedly over time. As a result, the service is exhausted and the memory is unavailable. When passwor",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2025-21605 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-21605（Redis）",
   "NVD 说明（英文原文）：Redis is an open source, in-memory database that persists on disk. In versions starting at 2.6 and prior to 7.4.3, An unauthenticated client can cause unlimited growth of output buffers, until the server runs out of memory or is killed. By default, the Redis configuration does not limit the output buffer of normal clients (see client-output-buffer-limit). Therefore, the output buffer can grow unlimitedly over time. As a result, the service is exhausted and the memory is unavailable. When passwor",
   "请尽快将 Redis 升级到不受 CVE-2025-21605 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-21605（Redis）",
   "NVD 說明（英文原文）：Redis is an open source, in-memory database that persists on disk. In versions starting at 2.6 and prior to 7.4.3, An unauthenticated client can cause unlimited growth of output buffers, until the server runs out of memory or is killed. By default, the Redis configuration does not limit the output buffer of normal clients (see client-output-buffer-limit). Therefore, the output buffer can grow unlimitedly over time. As a result, the service is exhausted and the memory is unavailable. When passwor",
   "請儘快將 Redis 升級到不受 CVE-2025-21605 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2025-32023": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-32023 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): Redis is an open source, in-memory database that persists on disk. From 2.8 to before 8.0.3, 7.4.5, 7.2.10, and 6.2.19, an authenticated user may use a specially crafted string to trigger a stack/heap out of bounds write on hyperloglog operations, potentially leading to remote code execution. The bug likely affects all Redis versions with hyperloglog operations implemented. This vulnerability is fixed in 8.0.3, 7.4.5, 7.2.10, and 6.2.19. An additional workaround to mitigate the problem without p",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2025-32023 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-32023 (Redis)",
   "Redis is an open source, in-memory database that persists on disk. From 2.8 to before 8.0.3, 7.4.5, 7.2.10, and 6.2.19, an authenticated user may use a specially crafted string to trigger a stack/heap out of bounds write on hyperloglog operations, potentially leading to remote code execution. The bug likely affects all Redis versions with hyperloglog operations implemented. This vulnerability is fixed in 8.0.3, 7.4.5, 7.2.10, and 6.2.19. An additional workaround to mitigate the problem without p",
   "Upgrade Redis to a version not affected by CVE-2025-32023 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-32023 (Redis)",
   "Descripción de NVD (texto original en inglés): Redis is an open source, in-memory database that persists on disk. From 2.8 to before 8.0.3, 7.4.5, 7.2.10, and 6.2.19, an authenticated user may use a specially crafted string to trigger a stack/heap out of bounds write on hyperloglog operations, potentially leading to remote code execution. The bug likely affects all Redis versions with hyperloglog operations implemented. This vulnerability is fixed in 8.0.3, 7.4.5, 7.2.10, and 6.2.19. An additional workaround to mitigate the problem without p",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2025-32023 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-32023 (Redis)",
   "Description NVD (texte original en anglais) : Redis is an open source, in-memory database that persists on disk. From 2.8 to before 8.0.3, 7.4.5, 7.2.10, and 6.2.19, an authenticated user may use a specially crafted string to trigger a stack/heap out of bounds write on hyperloglog operations, potentially leading to remote code execution. The bug likely affects all Redis versions with hyperloglog operations implemented. This vulnerability is fixed in 8.0.3, 7.4.5, 7.2.10, and 6.2.19. An additional workaround to mitigate the problem without p",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2025-32023 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-32023 (Redis)",
   "Descrizione NVD (testo originale in inglese): Redis is an open source, in-memory database that persists on disk. From 2.8 to before 8.0.3, 7.4.5, 7.2.10, and 6.2.19, an authenticated user may use a specially crafted string to trigger a stack/heap out of bounds write on hyperloglog operations, potentially leading to remote code execution. The bug likely affects all Redis versions with hyperloglog operations implemented. This vulnerability is fixed in 8.0.3, 7.4.5, 7.2.10, and 6.2.19. An additional workaround to mitigate the problem without p",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2025-32023 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-32023 (Redis)",
   "NVDの説明（英語原文）: Redis is an open source, in-memory database that persists on disk. From 2.8 to before 8.0.3, 7.4.5, 7.2.10, and 6.2.19, an authenticated user may use a specially crafted string to trigger a stack/heap out of bounds write on hyperloglog operations, potentially leading to remote code execution. The bug likely affects all Redis versions with hyperloglog operations implemented. This vulnerability is fixed in 8.0.3, 7.4.5, 7.2.10, and 6.2.19. An additional workaround to mitigate the problem without p",
   "Redis を CVE-2025-32023 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-32023 (Redis)",
   "NVD 설명(영어 원문): Redis is an open source, in-memory database that persists on disk. From 2.8 to before 8.0.3, 7.4.5, 7.2.10, and 6.2.19, an authenticated user may use a specially crafted string to trigger a stack/heap out of bounds write on hyperloglog operations, potentially leading to remote code execution. The bug likely affects all Redis versions with hyperloglog operations implemented. This vulnerability is fixed in 8.0.3, 7.4.5, 7.2.10, and 6.2.19. An additional workaround to mitigate the problem without p",
   "Redis을(를) CVE-2025-32023의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-32023 (Redis)",
   "Descrição do NVD (texto original em inglês): Redis is an open source, in-memory database that persists on disk. From 2.8 to before 8.0.3, 7.4.5, 7.2.10, and 6.2.19, an authenticated user may use a specially crafted string to trigger a stack/heap out of bounds write on hyperloglog operations, potentially leading to remote code execution. The bug likely affects all Redis versions with hyperloglog operations implemented. This vulnerability is fixed in 8.0.3, 7.4.5, 7.2.10, and 6.2.19. An additional workaround to mitigate the problem without p",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2025-32023 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-32023（Redis）",
   "NVD 说明（英文原文）：Redis is an open source, in-memory database that persists on disk. From 2.8 to before 8.0.3, 7.4.5, 7.2.10, and 6.2.19, an authenticated user may use a specially crafted string to trigger a stack/heap out of bounds write on hyperloglog operations, potentially leading to remote code execution. The bug likely affects all Redis versions with hyperloglog operations implemented. This vulnerability is fixed in 8.0.3, 7.4.5, 7.2.10, and 6.2.19. An additional workaround to mitigate the problem without p",
   "请尽快将 Redis 升级到不受 CVE-2025-32023 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-32023（Redis）",
   "NVD 說明（英文原文）：Redis is an open source, in-memory database that persists on disk. From 2.8 to before 8.0.3, 7.4.5, 7.2.10, and 6.2.19, an authenticated user may use a specially crafted string to trigger a stack/heap out of bounds write on hyperloglog operations, potentially leading to remote code execution. The bug likely affects all Redis versions with hyperloglog operations implemented. This vulnerability is fixed in 8.0.3, 7.4.5, 7.2.10, and 6.2.19. An additional workaround to mitigate the problem without p",
   "請儘快將 Redis 升級到不受 CVE-2025-32023 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2025-46817": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-46817 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): Redis is an open source, in-memory database that persists on disk. Versions 8.2.1 and below allow an authenticated user to use a specially crafted Lua script to cause an integer overflow and potentially lead to remote code execution The problem exists in all versions of Redis with Lua scripting. This issue is fixed in version 8.2.2.",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2025-46817 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-46817 (Redis)",
   "Redis is an open source, in-memory database that persists on disk. Versions 8.2.1 and below allow an authenticated user to use a specially crafted Lua script to cause an integer overflow and potentially lead to remote code execution The problem exists in all versions of Redis with Lua scripting. This issue is fixed in version 8.2.2.",
   "Upgrade Redis to a version not affected by CVE-2025-46817 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-46817 (Redis)",
   "Descripción de NVD (texto original en inglés): Redis is an open source, in-memory database that persists on disk. Versions 8.2.1 and below allow an authenticated user to use a specially crafted Lua script to cause an integer overflow and potentially lead to remote code execution The problem exists in all versions of Redis with Lua scripting. This issue is fixed in version 8.2.2.",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2025-46817 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-46817 (Redis)",
   "Description NVD (texte original en anglais) : Redis is an open source, in-memory database that persists on disk. Versions 8.2.1 and below allow an authenticated user to use a specially crafted Lua script to cause an integer overflow and potentially lead to remote code execution The problem exists in all versions of Redis with Lua scripting. This issue is fixed in version 8.2.2.",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2025-46817 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-46817 (Redis)",
   "Descrizione NVD (testo originale in inglese): Redis is an open source, in-memory database that persists on disk. Versions 8.2.1 and below allow an authenticated user to use a specially crafted Lua script to cause an integer overflow and potentially lead to remote code execution The problem exists in all versions of Redis with Lua scripting. This issue is fixed in version 8.2.2.",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2025-46817 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-46817 (Redis)",
   "NVDの説明（英語原文）: Redis is an open source, in-memory database that persists on disk. Versions 8.2.1 and below allow an authenticated user to use a specially crafted Lua script to cause an integer overflow and potentially lead to remote code execution The problem exists in all versions of Redis with Lua scripting. This issue is fixed in version 8.2.2.",
   "Redis を CVE-2025-46817 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-46817 (Redis)",
   "NVD 설명(영어 원문): Redis is an open source, in-memory database that persists on disk. Versions 8.2.1 and below allow an authenticated user to use a specially crafted Lua script to cause an integer overflow and potentially lead to remote code execution The problem exists in all versions of Redis with Lua scripting. This issue is fixed in version 8.2.2.",
   "Redis을(를) CVE-2025-46817의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-46817 (Redis)",
   "Descrição do NVD (texto original em inglês): Redis is an open source, in-memory database that persists on disk. Versions 8.2.1 and below allow an authenticated user to use a specially crafted Lua script to cause an integer overflow and potentially lead to remote code execution The problem exists in all versions of Redis with Lua scripting. This issue is fixed in version 8.2.2.",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2025-46817 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-46817（Redis）",
   "NVD 说明（英文原文）：Redis is an open source, in-memory database that persists on disk. Versions 8.2.1 and below allow an authenticated user to use a specially crafted Lua script to cause an integer overflow and potentially lead to remote code execution The problem exists in all versions of Redis with Lua scripting. This issue is fixed in version 8.2.2.",
   "请尽快将 Redis 升级到不受 CVE-2025-46817 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-46817（Redis）",
   "NVD 說明（英文原文）：Redis is an open source, in-memory database that persists on disk. Versions 8.2.1 and below allow an authenticated user to use a specially crafted Lua script to cause an integer overflow and potentially lead to remote code execution The problem exists in all versions of Redis with Lua scripting. This issue is fixed in version 8.2.2.",
   "請儘快將 Redis 升級到不受 CVE-2025-46817 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2025-48367": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-48367 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): Redis is an open source, in-memory database that persists on disk. An unauthenticated connection can cause repeated IP protocol errors, leading to client starvation and, ultimately, a denial of service. This vulnerability is fixed in 8.0.3, 7.4.5, 7.2.10, and 6.2.19.",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2025-48367 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-48367 (Redis)",
   "Redis is an open source, in-memory database that persists on disk. An unauthenticated connection can cause repeated IP protocol errors, leading to client starvation and, ultimately, a denial of service. This vulnerability is fixed in 8.0.3, 7.4.5, 7.2.10, and 6.2.19.",
   "Upgrade Redis to a version not affected by CVE-2025-48367 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-48367 (Redis)",
   "Descripción de NVD (texto original en inglés): Redis is an open source, in-memory database that persists on disk. An unauthenticated connection can cause repeated IP protocol errors, leading to client starvation and, ultimately, a denial of service. This vulnerability is fixed in 8.0.3, 7.4.5, 7.2.10, and 6.2.19.",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2025-48367 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-48367 (Redis)",
   "Description NVD (texte original en anglais) : Redis is an open source, in-memory database that persists on disk. An unauthenticated connection can cause repeated IP protocol errors, leading to client starvation and, ultimately, a denial of service. This vulnerability is fixed in 8.0.3, 7.4.5, 7.2.10, and 6.2.19.",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2025-48367 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-48367 (Redis)",
   "Descrizione NVD (testo originale in inglese): Redis is an open source, in-memory database that persists on disk. An unauthenticated connection can cause repeated IP protocol errors, leading to client starvation and, ultimately, a denial of service. This vulnerability is fixed in 8.0.3, 7.4.5, 7.2.10, and 6.2.19.",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2025-48367 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-48367 (Redis)",
   "NVDの説明（英語原文）: Redis is an open source, in-memory database that persists on disk. An unauthenticated connection can cause repeated IP protocol errors, leading to client starvation and, ultimately, a denial of service. This vulnerability is fixed in 8.0.3, 7.4.5, 7.2.10, and 6.2.19.",
   "Redis を CVE-2025-48367 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-48367 (Redis)",
   "NVD 설명(영어 원문): Redis is an open source, in-memory database that persists on disk. An unauthenticated connection can cause repeated IP protocol errors, leading to client starvation and, ultimately, a denial of service. This vulnerability is fixed in 8.0.3, 7.4.5, 7.2.10, and 6.2.19.",
   "Redis을(를) CVE-2025-48367의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-48367 (Redis)",
   "Descrição do NVD (texto original em inglês): Redis is an open source, in-memory database that persists on disk. An unauthenticated connection can cause repeated IP protocol errors, leading to client starvation and, ultimately, a denial of service. This vulnerability is fixed in 8.0.3, 7.4.5, 7.2.10, and 6.2.19.",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2025-48367 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-48367（Redis）",
   "NVD 说明（英文原文）：Redis is an open source, in-memory database that persists on disk. An unauthenticated connection can cause repeated IP protocol errors, leading to client starvation and, ultimately, a denial of service. This vulnerability is fixed in 8.0.3, 7.4.5, 7.2.10, and 6.2.19.",
   "请尽快将 Redis 升级到不受 CVE-2025-48367 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-48367（Redis）",
   "NVD 說明（英文原文）：Redis is an open source, in-memory database that persists on disk. An unauthenticated connection can cause repeated IP protocol errors, leading to client starvation and, ultimately, a denial of service. This vulnerability is fixed in 8.0.3, 7.4.5, 7.2.10, and 6.2.19.",
   "請儘快將 Redis 升級到不受 CVE-2025-48367 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2025-49844": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-49844 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): Redis is an open source, in-memory database that persists on disk. Versions 8.2.1 and below allow an authenticated user to use a specially crafted Lua script to manipulate the garbage collector, trigger a use-after-free and potentially lead to remote code execution. The problem exists in all versions of Redis with Lua scripting. This issue is fixed in version 8.2.2. To workaround this issue without patching the redis-server executable is to prevent users from executing Lua scripts. This can be d",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2025-49844 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-49844 (Redis)",
   "Redis is an open source, in-memory database that persists on disk. Versions 8.2.1 and below allow an authenticated user to use a specially crafted Lua script to manipulate the garbage collector, trigger a use-after-free and potentially lead to remote code execution. The problem exists in all versions of Redis with Lua scripting. This issue is fixed in version 8.2.2. To workaround this issue without patching the redis-server executable is to prevent users from executing Lua scripts. This can be d",
   "Upgrade Redis to a version not affected by CVE-2025-49844 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-49844 (Redis)",
   "Descripción de NVD (texto original en inglés): Redis is an open source, in-memory database that persists on disk. Versions 8.2.1 and below allow an authenticated user to use a specially crafted Lua script to manipulate the garbage collector, trigger a use-after-free and potentially lead to remote code execution. The problem exists in all versions of Redis with Lua scripting. This issue is fixed in version 8.2.2. To workaround this issue without patching the redis-server executable is to prevent users from executing Lua scripts. This can be d",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2025-49844 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-49844 (Redis)",
   "Description NVD (texte original en anglais) : Redis is an open source, in-memory database that persists on disk. Versions 8.2.1 and below allow an authenticated user to use a specially crafted Lua script to manipulate the garbage collector, trigger a use-after-free and potentially lead to remote code execution. The problem exists in all versions of Redis with Lua scripting. This issue is fixed in version 8.2.2. To workaround this issue without patching the redis-server executable is to prevent users from executing Lua scripts. This can be d",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2025-49844 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-49844 (Redis)",
   "Descrizione NVD (testo originale in inglese): Redis is an open source, in-memory database that persists on disk. Versions 8.2.1 and below allow an authenticated user to use a specially crafted Lua script to manipulate the garbage collector, trigger a use-after-free and potentially lead to remote code execution. The problem exists in all versions of Redis with Lua scripting. This issue is fixed in version 8.2.2. To workaround this issue without patching the redis-server executable is to prevent users from executing Lua scripts. This can be d",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2025-49844 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-49844 (Redis)",
   "NVDの説明（英語原文）: Redis is an open source, in-memory database that persists on disk. Versions 8.2.1 and below allow an authenticated user to use a specially crafted Lua script to manipulate the garbage collector, trigger a use-after-free and potentially lead to remote code execution. The problem exists in all versions of Redis with Lua scripting. This issue is fixed in version 8.2.2. To workaround this issue without patching the redis-server executable is to prevent users from executing Lua scripts. This can be d",
   "Redis を CVE-2025-49844 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-49844 (Redis)",
   "NVD 설명(영어 원문): Redis is an open source, in-memory database that persists on disk. Versions 8.2.1 and below allow an authenticated user to use a specially crafted Lua script to manipulate the garbage collector, trigger a use-after-free and potentially lead to remote code execution. The problem exists in all versions of Redis with Lua scripting. This issue is fixed in version 8.2.2. To workaround this issue without patching the redis-server executable is to prevent users from executing Lua scripts. This can be d",
   "Redis을(를) CVE-2025-49844의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-49844 (Redis)",
   "Descrição do NVD (texto original em inglês): Redis is an open source, in-memory database that persists on disk. Versions 8.2.1 and below allow an authenticated user to use a specially crafted Lua script to manipulate the garbage collector, trigger a use-after-free and potentially lead to remote code execution. The problem exists in all versions of Redis with Lua scripting. This issue is fixed in version 8.2.2. To workaround this issue without patching the redis-server executable is to prevent users from executing Lua scripts. This can be d",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2025-49844 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-49844（Redis）",
   "NVD 说明（英文原文）：Redis is an open source, in-memory database that persists on disk. Versions 8.2.1 and below allow an authenticated user to use a specially crafted Lua script to manipulate the garbage collector, trigger a use-after-free and potentially lead to remote code execution. The problem exists in all versions of Redis with Lua scripting. This issue is fixed in version 8.2.2. To workaround this issue without patching the redis-server executable is to prevent users from executing Lua scripts. This can be d",
   "请尽快将 Redis 升级到不受 CVE-2025-49844 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-49844（Redis）",
   "NVD 說明（英文原文）：Redis is an open source, in-memory database that persists on disk. Versions 8.2.1 and below allow an authenticated user to use a specially crafted Lua script to manipulate the garbage collector, trigger a use-after-free and potentially lead to remote code execution. The problem exists in all versions of Redis with Lua scripting. This issue is fixed in version 8.2.2. To workaround this issue without patching the redis-server executable is to prevent users from executing Lua scripts. This can be d",
   "請儘快將 Redis 升級到不受 CVE-2025-49844 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2025-62507": {
  "de": [
   "Bekannte Schwachstelle: CVE-2025-62507 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): Redis is an open source, in-memory database that persists on disk. In versions 8.2.0 and above, a user can run the XACKDEL command with multiple ID's and trigger a stack buffer overflow, which may potentially lead to remote code execution. This issue is fixed in version 8.2.3. To workaround this issue without patching the redis-server executable is to prevent users from executing XACKDEL operation. This can be done using ACL to restrict XACKDEL command.",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2025-62507 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2025-62507 (Redis)",
   "Redis is an open source, in-memory database that persists on disk. In versions 8.2.0 and above, a user can run the XACKDEL command with multiple ID's and trigger a stack buffer overflow, which may potentially lead to remote code execution. This issue is fixed in version 8.2.3. To workaround this issue without patching the redis-server executable is to prevent users from executing XACKDEL operation. This can be done using ACL to restrict XACKDEL command.",
   "Upgrade Redis to a version not affected by CVE-2025-62507 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2025-62507 (Redis)",
   "Descripción de NVD (texto original en inglés): Redis is an open source, in-memory database that persists on disk. In versions 8.2.0 and above, a user can run the XACKDEL command with multiple ID's and trigger a stack buffer overflow, which may potentially lead to remote code execution. This issue is fixed in version 8.2.3. To workaround this issue without patching the redis-server executable is to prevent users from executing XACKDEL operation. This can be done using ACL to restrict XACKDEL command.",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2025-62507 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2025-62507 (Redis)",
   "Description NVD (texte original en anglais) : Redis is an open source, in-memory database that persists on disk. In versions 8.2.0 and above, a user can run the XACKDEL command with multiple ID's and trigger a stack buffer overflow, which may potentially lead to remote code execution. This issue is fixed in version 8.2.3. To workaround this issue without patching the redis-server executable is to prevent users from executing XACKDEL operation. This can be done using ACL to restrict XACKDEL command.",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2025-62507 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2025-62507 (Redis)",
   "Descrizione NVD (testo originale in inglese): Redis is an open source, in-memory database that persists on disk. In versions 8.2.0 and above, a user can run the XACKDEL command with multiple ID's and trigger a stack buffer overflow, which may potentially lead to remote code execution. This issue is fixed in version 8.2.3. To workaround this issue without patching the redis-server executable is to prevent users from executing XACKDEL operation. This can be done using ACL to restrict XACKDEL command.",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2025-62507 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2025-62507 (Redis)",
   "NVDの説明（英語原文）: Redis is an open source, in-memory database that persists on disk. In versions 8.2.0 and above, a user can run the XACKDEL command with multiple ID's and trigger a stack buffer overflow, which may potentially lead to remote code execution. This issue is fixed in version 8.2.3. To workaround this issue without patching the redis-server executable is to prevent users from executing XACKDEL operation. This can be done using ACL to restrict XACKDEL command.",
   "Redis を CVE-2025-62507 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2025-62507 (Redis)",
   "NVD 설명(영어 원문): Redis is an open source, in-memory database that persists on disk. In versions 8.2.0 and above, a user can run the XACKDEL command with multiple ID's and trigger a stack buffer overflow, which may potentially lead to remote code execution. This issue is fixed in version 8.2.3. To workaround this issue without patching the redis-server executable is to prevent users from executing XACKDEL operation. This can be done using ACL to restrict XACKDEL command.",
   "Redis을(를) CVE-2025-62507의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2025-62507 (Redis)",
   "Descrição do NVD (texto original em inglês): Redis is an open source, in-memory database that persists on disk. In versions 8.2.0 and above, a user can run the XACKDEL command with multiple ID's and trigger a stack buffer overflow, which may potentially lead to remote code execution. This issue is fixed in version 8.2.3. To workaround this issue without patching the redis-server executable is to prevent users from executing XACKDEL operation. This can be done using ACL to restrict XACKDEL command.",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2025-62507 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2025-62507（Redis）",
   "NVD 说明（英文原文）：Redis is an open source, in-memory database that persists on disk. In versions 8.2.0 and above, a user can run the XACKDEL command with multiple ID's and trigger a stack buffer overflow, which may potentially lead to remote code execution. This issue is fixed in version 8.2.3. To workaround this issue without patching the redis-server executable is to prevent users from executing XACKDEL operation. This can be done using ACL to restrict XACKDEL command.",
   "请尽快将 Redis 升级到不受 CVE-2025-62507 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2025-62507（Redis）",
   "NVD 說明（英文原文）：Redis is an open source, in-memory database that persists on disk. In versions 8.2.0 and above, a user can run the XACKDEL command with multiple ID's and trigger a stack buffer overflow, which may potentially lead to remote code execution. This issue is fixed in version 8.2.3. To workaround this issue without patching the redis-server executable is to prevent users from executing XACKDEL operation. This can be done using ACL to restrict XACKDEL command.",
   "請儘快將 Redis 升級到不受 CVE-2025-62507 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2026-23479": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-23479 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): Redis is an in-memory data structure store. In redis-server from 7.2.0 until 8.6.3, the unblock client flow does not handle an error return from `processCommandAndResetClient` when re-executing a blocked command. If a blocked client is evicted during this flow, an authenticated attacker can trigger a use-after-free that may lead to remote code execution. This has been patched in version 8.6.3.",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2026-23479 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-23479 (Redis)",
   "Redis is an in-memory data structure store. In redis-server from 7.2.0 until 8.6.3, the unblock client flow does not handle an error return from `processCommandAndResetClient` when re-executing a blocked command. If a blocked client is evicted during this flow, an authenticated attacker can trigger a use-after-free that may lead to remote code execution. This has been patched in version 8.6.3.",
   "Upgrade Redis to a version not affected by CVE-2026-23479 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-23479 (Redis)",
   "Descripción de NVD (texto original en inglés): Redis is an in-memory data structure store. In redis-server from 7.2.0 until 8.6.3, the unblock client flow does not handle an error return from `processCommandAndResetClient` when re-executing a blocked command. If a blocked client is evicted during this flow, an authenticated attacker can trigger a use-after-free that may lead to remote code execution. This has been patched in version 8.6.3.",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2026-23479 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-23479 (Redis)",
   "Description NVD (texte original en anglais) : Redis is an in-memory data structure store. In redis-server from 7.2.0 until 8.6.3, the unblock client flow does not handle an error return from `processCommandAndResetClient` when re-executing a blocked command. If a blocked client is evicted during this flow, an authenticated attacker can trigger a use-after-free that may lead to remote code execution. This has been patched in version 8.6.3.",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2026-23479 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-23479 (Redis)",
   "Descrizione NVD (testo originale in inglese): Redis is an in-memory data structure store. In redis-server from 7.2.0 until 8.6.3, the unblock client flow does not handle an error return from `processCommandAndResetClient` when re-executing a blocked command. If a blocked client is evicted during this flow, an authenticated attacker can trigger a use-after-free that may lead to remote code execution. This has been patched in version 8.6.3.",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2026-23479 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-23479 (Redis)",
   "NVDの説明（英語原文）: Redis is an in-memory data structure store. In redis-server from 7.2.0 until 8.6.3, the unblock client flow does not handle an error return from `processCommandAndResetClient` when re-executing a blocked command. If a blocked client is evicted during this flow, an authenticated attacker can trigger a use-after-free that may lead to remote code execution. This has been patched in version 8.6.3.",
   "Redis を CVE-2026-23479 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-23479 (Redis)",
   "NVD 설명(영어 원문): Redis is an in-memory data structure store. In redis-server from 7.2.0 until 8.6.3, the unblock client flow does not handle an error return from `processCommandAndResetClient` when re-executing a blocked command. If a blocked client is evicted during this flow, an authenticated attacker can trigger a use-after-free that may lead to remote code execution. This has been patched in version 8.6.3.",
   "Redis을(를) CVE-2026-23479의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-23479 (Redis)",
   "Descrição do NVD (texto original em inglês): Redis is an in-memory data structure store. In redis-server from 7.2.0 until 8.6.3, the unblock client flow does not handle an error return from `processCommandAndResetClient` when re-executing a blocked command. If a blocked client is evicted during this flow, an authenticated attacker can trigger a use-after-free that may lead to remote code execution. This has been patched in version 8.6.3.",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2026-23479 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-23479（Redis）",
   "NVD 说明（英文原文）：Redis is an in-memory data structure store. In redis-server from 7.2.0 until 8.6.3, the unblock client flow does not handle an error return from `processCommandAndResetClient` when re-executing a blocked command. If a blocked client is evicted during this flow, an authenticated attacker can trigger a use-after-free that may lead to remote code execution. This has been patched in version 8.6.3.",
   "请尽快将 Redis 升级到不受 CVE-2026-23479 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-23479（Redis）",
   "NVD 說明（英文原文）：Redis is an in-memory data structure store. In redis-server from 7.2.0 until 8.6.3, the unblock client flow does not handle an error return from `processCommandAndResetClient` when re-executing a blocked command. If a blocked client is evicted during this flow, an authenticated attacker can trigger a use-after-free that may lead to remote code execution. This has been patched in version 8.6.3.",
   "請儘快將 Redis 升級到不受 CVE-2026-23479 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2026-23631": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-23631 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): Redis is an in-memory data structure store. In all versions of redis-server with Lua scripting, an authenticated attacker can exploit the master-replica synchronization mechanism to trigger a use-after-free on replicas where replica-read-only is disabled or can be disabled, which may lead to remote code execution. A workaround is to prevent users from executing Lua scripts or avoid using replicas where replica-read-only is disabled. This is patched in version 8.6.3.",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2026-23631 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-23631 (Redis)",
   "Redis is an in-memory data structure store. In all versions of redis-server with Lua scripting, an authenticated attacker can exploit the master-replica synchronization mechanism to trigger a use-after-free on replicas where replica-read-only is disabled or can be disabled, which may lead to remote code execution. A workaround is to prevent users from executing Lua scripts or avoid using replicas where replica-read-only is disabled. This is patched in version 8.6.3.",
   "Upgrade Redis to a version not affected by CVE-2026-23631 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-23631 (Redis)",
   "Descripción de NVD (texto original en inglés): Redis is an in-memory data structure store. In all versions of redis-server with Lua scripting, an authenticated attacker can exploit the master-replica synchronization mechanism to trigger a use-after-free on replicas where replica-read-only is disabled or can be disabled, which may lead to remote code execution. A workaround is to prevent users from executing Lua scripts or avoid using replicas where replica-read-only is disabled. This is patched in version 8.6.3.",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2026-23631 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-23631 (Redis)",
   "Description NVD (texte original en anglais) : Redis is an in-memory data structure store. In all versions of redis-server with Lua scripting, an authenticated attacker can exploit the master-replica synchronization mechanism to trigger a use-after-free on replicas where replica-read-only is disabled or can be disabled, which may lead to remote code execution. A workaround is to prevent users from executing Lua scripts or avoid using replicas where replica-read-only is disabled. This is patched in version 8.6.3.",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2026-23631 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-23631 (Redis)",
   "Descrizione NVD (testo originale in inglese): Redis is an in-memory data structure store. In all versions of redis-server with Lua scripting, an authenticated attacker can exploit the master-replica synchronization mechanism to trigger a use-after-free on replicas where replica-read-only is disabled or can be disabled, which may lead to remote code execution. A workaround is to prevent users from executing Lua scripts or avoid using replicas where replica-read-only is disabled. This is patched in version 8.6.3.",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2026-23631 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-23631 (Redis)",
   "NVDの説明（英語原文）: Redis is an in-memory data structure store. In all versions of redis-server with Lua scripting, an authenticated attacker can exploit the master-replica synchronization mechanism to trigger a use-after-free on replicas where replica-read-only is disabled or can be disabled, which may lead to remote code execution. A workaround is to prevent users from executing Lua scripts or avoid using replicas where replica-read-only is disabled. This is patched in version 8.6.3.",
   "Redis を CVE-2026-23631 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-23631 (Redis)",
   "NVD 설명(영어 원문): Redis is an in-memory data structure store. In all versions of redis-server with Lua scripting, an authenticated attacker can exploit the master-replica synchronization mechanism to trigger a use-after-free on replicas where replica-read-only is disabled or can be disabled, which may lead to remote code execution. A workaround is to prevent users from executing Lua scripts or avoid using replicas where replica-read-only is disabled. This is patched in version 8.6.3.",
   "Redis을(를) CVE-2026-23631의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-23631 (Redis)",
   "Descrição do NVD (texto original em inglês): Redis is an in-memory data structure store. In all versions of redis-server with Lua scripting, an authenticated attacker can exploit the master-replica synchronization mechanism to trigger a use-after-free on replicas where replica-read-only is disabled or can be disabled, which may lead to remote code execution. A workaround is to prevent users from executing Lua scripts or avoid using replicas where replica-read-only is disabled. This is patched in version 8.6.3.",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2026-23631 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-23631（Redis）",
   "NVD 说明（英文原文）：Redis is an in-memory data structure store. In all versions of redis-server with Lua scripting, an authenticated attacker can exploit the master-replica synchronization mechanism to trigger a use-after-free on replicas where replica-read-only is disabled or can be disabled, which may lead to remote code execution. A workaround is to prevent users from executing Lua scripts or avoid using replicas where replica-read-only is disabled. This is patched in version 8.6.3.",
   "请尽快将 Redis 升级到不受 CVE-2026-23631 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-23631（Redis）",
   "NVD 說明（英文原文）：Redis is an in-memory data structure store. In all versions of redis-server with Lua scripting, an authenticated attacker can exploit the master-replica synchronization mechanism to trigger a use-after-free on replicas where replica-read-only is disabled or can be disabled, which may lead to remote code execution. A workaround is to prevent users from executing Lua scripts or avoid using replicas where replica-read-only is disabled. This is patched in version 8.6.3.",
   "請儘快將 Redis 升級到不受 CVE-2026-23631 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "cve:redis-default-noauth:CVE-2026-25243": {
  "de": [
   "Bekannte Schwachstelle: CVE-2026-25243 (Redis)",
   "NVD-Beschreibung (englischer Originaltext): Redis is an in-memory data structure store. In versions of redis-server up to 8.6.3, the RESTORE command does not properly validate serialized values. An authenticated attacker with permission to execute RESTORE can supply a crafted serialized payload that triggers invalid memory access and may lead to remote code execution. A workaround is to restrict access to the RESTORE command with ACL rules. This is patched in version 8.6.3.",
   "Aktualisieren Sie Redis so schnell wie möglich auf eine Version, die von CVE-2026-25243 nicht betroffen ist, und beschränken Sie in der Zwischenzeit den unauthentifizierten Netzwerkzugriff darauf."
  ],
  "en": [
   "Known Vulnerability: CVE-2026-25243 (Redis)",
   "Redis is an in-memory data structure store. In versions of redis-server up to 8.6.3, the RESTORE command does not properly validate serialized values. An authenticated attacker with permission to execute RESTORE can supply a crafted serialized payload that triggers invalid memory access and may lead to remote code execution. A workaround is to restrict access to the RESTORE command with ACL rules. This is patched in version 8.6.3.",
   "Upgrade Redis to a version not affected by CVE-2026-25243 as soon as possible, and restrict unauthenticated network access to it in the meantime."
  ],
  "es": [
   "Vulnerabilidad conocida: CVE-2026-25243 (Redis)",
   "Descripción de NVD (texto original en inglés): Redis is an in-memory data structure store. In versions of redis-server up to 8.6.3, the RESTORE command does not properly validate serialized values. An authenticated attacker with permission to execute RESTORE can supply a crafted serialized payload that triggers invalid memory access and may lead to remote code execution. A workaround is to restrict access to the RESTORE command with ACL rules. This is patched in version 8.6.3.",
   "Actualice Redis lo antes posible a una versión no afectada por CVE-2026-25243 y, mientras tanto, restrinja el acceso de red sin autenticación."
  ],
  "fr": [
   "Vulnérabilité connue : CVE-2026-25243 (Redis)",
   "Description NVD (texte original en anglais) : Redis is an in-memory data structure store. In versions of redis-server up to 8.6.3, the RESTORE command does not properly validate serialized values. An authenticated attacker with permission to execute RESTORE can supply a crafted serialized payload that triggers invalid memory access and may lead to remote code execution. A workaround is to restrict access to the RESTORE command with ACL rules. This is patched in version 8.6.3.",
   "Mettez à niveau Redis dès que possible vers une version non affectée par CVE-2026-25243 et, en attendant, restreignez l'accès réseau non authentifié."
  ],
  "it": [
   "Vulnerabilità nota: CVE-2026-25243 (Redis)",
   "Descrizione NVD (testo originale in inglese): Redis is an in-memory data structure store. In versions of redis-server up to 8.6.3, the RESTORE command does not properly validate serialized values. An authenticated attacker with permission to execute RESTORE can supply a crafted serialized payload that triggers invalid memory access and may lead to remote code execution. A workaround is to restrict access to the RESTORE command with ACL rules. This is patched in version 8.6.3.",
   "Aggiorna Redis il prima possibile a una versione non interessata da CVE-2026-25243 e, nel frattempo, limita l'accesso di rete non autenticato."
  ],
  "ja": [
   "既知の脆弱性: CVE-2026-25243 (Redis)",
   "NVDの説明（英語原文）: Redis is an in-memory data structure store. In versions of redis-server up to 8.6.3, the RESTORE command does not properly validate serialized values. An authenticated attacker with permission to execute RESTORE can supply a crafted serialized payload that triggers invalid memory access and may lead to remote code execution. A workaround is to restrict access to the RESTORE command with ACL rules. This is patched in version 8.6.3.",
   "Redis を CVE-2026-25243 の影響を受けないバージョンへ早急にアップグレードし、それまでは認証なしでのネットワークアクセスを制限してください。"
  ],
  "ko": [
   "알려진 취약점: CVE-2026-25243 (Redis)",
   "NVD 설명(영어 원문): Redis is an in-memory data structure store. In versions of redis-server up to 8.6.3, the RESTORE command does not properly validate serialized values. An authenticated attacker with permission to execute RESTORE can supply a crafted serialized payload that triggers invalid memory access and may lead to remote code execution. A workaround is to restrict access to the RESTORE command with ACL rules. This is patched in version 8.6.3.",
   "Redis을(를) CVE-2026-25243의 영향을 받지 않는 버전으로 가능한 한 빨리 업그레이드하고, 그때까지는 인증 없는 네트워크 접근을 제한하세요."
  ],
  "pt-PT": [
   "Vulnerabilidade conhecida: CVE-2026-25243 (Redis)",
   "Descrição do NVD (texto original em inglês): Redis is an in-memory data structure store. In versions of redis-server up to 8.6.3, the RESTORE command does not properly validate serialized values. An authenticated attacker with permission to execute RESTORE can supply a crafted serialized payload that triggers invalid memory access and may lead to remote code execution. A workaround is to restrict access to the RESTORE command with ACL rules. This is patched in version 8.6.3.",
   "Atualize o Redis o quanto antes para uma versão não afetada por CVE-2026-25243 e, entretanto, restrinja o acesso de rede não autenticado."
  ],
  "zh-Hans": [
   "已知漏洞：CVE-2026-25243（Redis）",
   "NVD 说明（英文原文）：Redis is an in-memory data structure store. In versions of redis-server up to 8.6.3, the RESTORE command does not properly validate serialized values. An authenticated attacker with permission to execute RESTORE can supply a crafted serialized payload that triggers invalid memory access and may lead to remote code execution. A workaround is to restrict access to the RESTORE command with ACL rules. This is patched in version 8.6.3.",
   "请尽快将 Redis 升级到不受 CVE-2026-25243 影响的版本，在此之前请限制对其的未认证网络访问。"
  ],
  "zh-Hant": [
   "已知漏洞：CVE-2026-25243（Redis）",
   "NVD 說明（英文原文）：Redis is an in-memory data structure store. In versions of redis-server up to 8.6.3, the RESTORE command does not properly validate serialized values. An authenticated attacker with permission to execute RESTORE can supply a crafted serialized payload that triggers invalid memory access and may lead to remote code execution. A workaround is to restrict access to the RESTORE command with ACL rules. This is patched in version 8.6.3.",
   "請儘快將 Redis 升級到不受 CVE-2026-25243 影響的版本，在此之前請限制對其的未經驗證網路存取。"
  ]
 },
 "signature:caido-network-exposed": {
  "de": [
   "Caido (ein abfangender Proxy) ist aus dem Netzwerk erreichbar",
   "Caido ist ein Proxy für Web-Sicherheitstests, der Datenverkehr abfängt, aufzeichnet und verändert; das KI-Pentest-Tool Strix bringt ihn mit. Aufgezeichneter Verkehr enthält Logins und Sitzungs-Cookies, und bei erlaubtem Gastzugang (--allow-guests) kann ihn jeder im selben Netzwerk lesen.",
   "Falls Sie es nicht bewusst freigegeben haben, beschränken Sie den Listener auf 127.0.0.1 (--listen 127.0.0.1:Port) oder beenden Sie den Prozess. Nutzen Sie es nur in einem Test-Container oder einer VM und veröffentlichen Sie den Port nicht nach außen."
  ],
  "en": [
   "Caido (an intercepting proxy) is reachable from the network",
   "Caido is a web security testing proxy that intercepts, records and modifies traffic, and the AI penetration-testing tool Strix bundles it. Recorded traffic contains logins and session cookies, and with guest access allowed (--allow-guests) anyone on the same network can read it.",
   "If you did not mean to share it, limit the listener to 127.0.0.1 (--listen 127.0.0.1:port) or stop the process. Use it only inside a test container or VM and do not publish its port externally."
  ],
  "es": [
   "Caido (un proxy de intercepción) es accesible desde la red",
   "Caido es un proxy de pruebas de seguridad web que intercepta, registra y modifica el tráfico, y la herramienta de pruebas de intrusión con IA Strix lo incluye. El tráfico registrado contiene inicios de sesión y cookies de sesión, y con el acceso de invitados permitido (--allow-guests) cualquiera en la misma red puede leerlo.",
   "Si no lo compartió a propósito, limite la escucha a 127.0.0.1 (--listen 127.0.0.1:puerto) o detenga el proceso. Úselo solo dentro de un contenedor o una VM de pruebas y no publique su puerto hacia el exterior."
  ],
  "fr": [
   "Caido (un proxy d'interception) est joignable depuis le réseau",
   "Caido est un proxy de test de sécurité web qui intercepte, enregistre et modifie le trafic, et l'outil de test d'intrusion par IA Strix l'intègre. Le trafic enregistré contient des identifiants et des cookies de session ; avec l'accès invité autorisé (--allow-guests), n'importe qui sur le même réseau peut le lire.",
   "Si vous ne l'avez pas partagé volontairement, limitez l'écoute à 127.0.0.1 (--listen 127.0.0.1:port) ou arrêtez le processus. Utilisez-le uniquement dans un conteneur ou une VM de test, sans publier son port à l'extérieur."
  ],
  "it": [
   "Caido (un proxy di intercettazione) è raggiungibile dalla rete",
   "Caido è un proxy per i test di sicurezza web che intercetta, registra e modifica il traffico, e lo strumento di penetration test con IA Strix lo include. Il traffico registrato contiene credenziali e cookie di sessione e, con l'accesso ospite consentito (--allow-guests), chiunque sulla stessa rete può leggerlo.",
   "Se non l'hai condiviso di proposito, limita l'ascolto a 127.0.0.1 (--listen 127.0.0.1:porta) oppure termina il processo. Usalo solo dentro un container o una VM di test e non pubblicarne la porta all'esterno."
  ],
  "ja": [
   "Caido（傍受プロキシ）がネットワークから到達できる状態です",
   "Caido は通信を傍受・記録・書き換える Web セキュリティ検査用のプロキシで、AI ペネトレーションテストツールの Strix もこれを内蔵しています。記録された通信にはログイン情報やセッション Cookie が含まれ、ゲストアクセスを許可する設定（--allow-guests）では、同じネットワークの誰でもその内容を閲覧できてしまいます。",
   "意図して共有していない場合は、待ち受けを 127.0.0.1 に限定する（--listen 127.0.0.1:ポート）か、プロセスを停止してください。検査用のコンテナや VM の中だけで使い、外部へポートを公開しないでください。"
  ],
  "ko": [
   "Caido(가로채기 프록시)에 네트워크에서 접근할 수 있습니다",
   "Caido는 트래픽을 가로채고 기록하고 변경하는 웹 보안 점검용 프록시이며, AI 침투 테스트 도구 Strix에도 내장되어 있습니다. 기록된 트래픽에는 로그인 정보와 세션 쿠키가 들어 있고, 게스트 접근을 허용하는 설정(--allow-guests)에서는 같은 네트워크의 누구나 그 내용을 볼 수 있습니다.",
   "의도적으로 공유한 것이 아니라면 수신 주소를 127.0.0.1로 제한하거나(--listen 127.0.0.1:포트) 프로세스를 종료하세요. 점검용 컨테이너나 VM 안에서만 사용하고 포트를 외부에 공개하지 마세요."
  ],
  "pt-PT": [
   "O Caido (um proxy de interceção) está acessível a partir da rede",
   "O Caido é um proxy de testes de segurança web que interceta, regista e modifica o tráfego, e a ferramenta de testes de intrusão com IA Strix inclui-o. O tráfego registado contém credenciais e cookies de sessão e, com o acesso de convidados permitido (--allow-guests), qualquer pessoa na mesma rede pode lê-lo.",
   "Se não o partilhou de propósito, limite a escuta a 127.0.0.1 (--listen 127.0.0.1:porta) ou termine o processo. Use-o apenas dentro de um contentor ou VM de teste e não publique a porta para o exterior."
  ],
  "zh-Hans": [
   "Caido（拦截代理）可从网络访问",
   "Caido 是用于 Web 安全检测的代理，可拦截、记录并修改流量，AI 渗透测试工具 Strix 也内置了它。记录下来的流量包含登录信息和会话 Cookie；在允许访客访问的设置（--allow-guests）下，同一网络中的任何人都能查看。",
   "如果不是有意共享，请把监听地址限制为 127.0.0.1（--listen 127.0.0.1:端口），或停止该进程。只在测试用的容器或虚拟机内使用，不要把端口对外开放。"
  ],
  "zh-Hant": [
   "Caido（攔截代理）可從網路存取",
   "Caido 是用於 Web 安全檢測的代理，可攔截、記錄並修改流量，AI 滲透測試工具 Strix 也內建了它。記錄下來的流量包含登入資訊與工作階段 Cookie；在允許訪客存取的設定（--allow-guests）下，同一網路中的任何人都能檢視。",
   "如果不是有意分享，請把監聽位址限制為 127.0.0.1（--listen 127.0.0.1:連接埠），或停止該程序。只在測試用的容器或虛擬機內使用，不要把連接埠對外開放。"
  ]
 },
 "signature:couchdb-noauth": {
  "de": [
   "CouchDB: Zugriff ohne Authentifizierung",
   "CouchDB hat die Datenbankliste (_all_dbs) ohne Authentifizierung zurückgegeben. Ohne konfiguriertes Administratorkonto („Admin Party“) kann jeder Daten lesen und schreiben sowie Administratorrechte erlangen.",
   "Legen Sie ein Administratorkonto an, um Authentifizierung zu erzwingen, und beschränken Sie bind_address auf 127.0.0.1."
  ],
  "en": [
   "CouchDB Unauthenticated Exposure Risk",
   "CouchDB returned its database list (_all_dbs) without authentication. With no admin account configured (\"Admin Party\"), anyone can read and write data and gain administrator privileges.",
   "Create an admin account to require authentication, and restrict bind_address to 127.0.0.1."
  ],
  "es": [
   "Riesgo de exposición de CouchDB sin autenticación",
   "CouchDB devolvió su lista de bases de datos (_all_dbs) sin autenticación. Sin una cuenta de administrador configurada («Admin Party»), cualquiera puede leer y escribir datos y obtener privilegios de administrador.",
   "Crea una cuenta de administrador para exigir autenticación y limita bind_address a 127.0.0.1."
  ],
  "fr": [
   "Risque d'exposition de CouchDB sans authentification",
   "CouchDB a renvoyé sa liste de bases (_all_dbs) sans authentification. Sans compte administrateur configuré (« Admin Party »), n'importe qui peut lire et écrire des données et obtenir les droits d'administrateur.",
   "Créez un compte administrateur pour exiger l'authentification et limitez bind_address à 127.0.0.1."
  ],
  "it": [
   "Rischio di esposizione di CouchDB senza autenticazione",
   "CouchDB ha restituito l'elenco dei database (_all_dbs) senza autenticazione. Senza un account amministratore configurato («Admin Party»), chiunque può leggere e scrivere dati e ottenere privilegi di amministratore.",
   "Crea un account amministratore per richiedere l'autenticazione e limita bind_address a 127.0.0.1."
  ],
  "ja": [
   "CouchDB 認証なし公開リスク",
   "CouchDB が認証なしでデータベース一覧（_all_dbs）を返しました。管理者アカウントが未設定（Admin Party）のままだと、誰でもデータの読み書きと管理者権限の取得が可能です。",
   "管理者アカウントを作成して認証を必須にし、bind_address を 127.0.0.1 に限定してください。"
  ],
  "ko": [
   "CouchDB 인증 없는 노출 위험",
   "CouchDB가 인증 없이 데이터베이스 목록(_all_dbs)을 반환했습니다. 관리자 계정이 설정되지 않은 상태(Admin Party)라면 누구나 데이터를 읽고 쓰고 관리자 권한을 얻을 수 있습니다.",
   "관리자 계정을 만들어 인증을 필수로 하고 bind_address를 127.0.0.1로 제한하세요."
  ],
  "pt-PT": [
   "Risco de exposição do CouchDB sem autenticação",
   "O CouchDB devolveu a lista de bases de dados (_all_dbs) sem autenticação. Sem uma conta de administrador configurada («Admin Party»), qualquer pessoa pode ler e escrever dados e obter privilégios de administrador.",
   "Crie uma conta de administrador para exigir autenticação e restrinja bind_address a 127.0.0.1."
  ],
  "zh-Hans": [
   "CouchDB 未认证暴露风险",
   "CouchDB 在未认证的情况下返回了数据库列表（_all_dbs）。若未设置管理员账户（Admin Party），任何人都可以读写数据并获得管理员权限。",
   "请创建管理员账户以强制认证，并将 bind_address 限制为 127.0.0.1。"
  ],
  "zh-Hant": [
   "CouchDB 未驗證暴露風險",
   "CouchDB 在未驗證的情況下回傳了資料庫清單（_all_dbs）。若未設定管理員帳戶（Admin Party），任何人都能讀寫資料並取得管理員權限。",
   "請建立管理員帳戶以強制驗證，並將 bind_address 限制為 127.0.0.1。"
  ]
 },
 "signature:dockerd-tcp-noauth": {
  "de": [
   "Docker-Daemon-TCP-API-Expositionsrisiko (nicht standardmäßiger Port)",
   "dockerd lauscht über TCP. Ist keine gegenseitige TLS-Authentifizierung konfiguriert, kann jeder, der eine Verbindung herstellen kann, Operationen ausführen, die root-Rechten auf dem Host entsprechen.",
   "Aktivieren Sie die gegenseitige TLS-Authentifizierung oder verwenden Sie ausschließlich den Unix-Domain-Socket."
  ],
  "en": [
   "Docker Daemon TCP API Exposure Risk (Non-Standard Port)",
   "dockerd is listening over TCP. If mutual TLS authentication isn't configured, anyone who can connect gains operations equivalent to root privileges on the host.",
   "Enable mutual TLS authentication, or use only the Unix domain socket."
  ],
  "es": [
   "Riesgo de exposición de la API TCP del daemon de Docker (puerto no estándar)",
   "dockerd está escuchando por TCP. Si no se ha configurado la autenticación TLS mutua, cualquiera que pueda conectarse obtiene operaciones equivalentes a privilegios root en el host.",
   "Activa la autenticación TLS mutua o utiliza únicamente el socket de dominio Unix."
  ],
  "fr": [
   "Risque d'exposition de l'API TCP du démon Docker (port non standard)",
   "dockerd est à l'écoute via TCP. Si l'authentification TLS mutuelle n'est pas configurée, toute personne pouvant se connecter obtient des opérations équivalentes aux privilèges root sur l'hôte.",
   "Activez l'authentification TLS mutuelle ou utilisez uniquement le socket de domaine Unix."
  ],
  "it": [
   "Rischio di esposizione dell'API TCP del demone Docker (porta non standard)",
   "dockerd è in ascolto tramite TCP. Se l'autenticazione TLS reciproca non è configurata, chiunque possa connettersi ottiene operazioni equivalenti ai privilegi root sull'host.",
   "Abilita l'autenticazione TLS reciproca oppure utilizza solo il socket di dominio Unix."
  ],
  "ja": [
   "Docker デーモン TCP API 露出リスク（非標準ポート）",
   "dockerdがTCP経由で待ち受けています。TLS相互認証を設定していない場合、接続できる相手はホストのroot権限に相当する操作が可能になります。",
   "TLS相互認証を有効にするか、Unixドメインソケットのみを使用してください。"
  ],
  "ko": [
   "Docker 데몬 TCP API 노출 위험 (비표준 포트)",
   "dockerd가 TCP를 통해 대기 중입니다. 상호 TLS 인증이 구성되어 있지 않으면, 연결할 수 있는 누구나 호스트의 root 권한에 상당하는 작업을 수행할 수 있습니다.",
   "상호 TLS 인증을 활성화하거나 Unix 도메인 소켓만 사용하세요."
  ],
  "pt-PT": [
   "Risco de exposição da API TCP do daemon Docker (porta não padrão)",
   "O dockerd está à escuta via TCP. Se a autenticação TLS mútua não estiver configurada, qualquer pessoa que consiga ligar-se obtém operações equivalentes a privilégios root no anfitrião.",
   "Ative a autenticação TLS mútua ou utilize apenas o socket de domínio Unix."
  ],
  "zh-Hans": [
   "Docker 守护进程 TCP API 暴露风险（非标准端口）",
   "dockerd 正通过 TCP 监听。如果未配置双向 TLS 认证，任何能够连接的人都可执行相当于主机 root 权限的操作。",
   "请启用双向 TLS 认证，或仅使用 Unix 域套接字。"
  ],
  "zh-Hant": [
   "Docker 守護程序 TCP API 暴露風險（非標準連接埠）",
   "dockerd 正透過 TCP 監聽。若未設定雙向 TLS 驗證，任何能夠連線的人都可執行相當於主機 root 權限的操作。",
   "請啟用雙向 TLS 驗證，或僅使用 Unix 網域通訊端。"
  ]
 },
 "signature:elasticsearch-noauth": {
  "de": [
   "Elasticsearch: Zugriff ohne Authentifizierung",
   "Elasticsearch hat eine Cluster-Info-Anfrage ohne Authentifizierung beantwortet. Bei deaktivierter Sicherheit und erreichbarem Port kann jeder alle Indizes lesen, ändern oder löschen.",
   "Aktivieren Sie xpack.security.enabled: true, um Authentifizierung zu erzwingen, und beschränken Sie network.host auf 127.0.0.1 oder ein Verwaltungsnetz."
  ],
  "en": [
   "Elasticsearch Unauthenticated Exposure Risk",
   "Elasticsearch answered a cluster-info request without authentication. With security disabled and the port reachable, anyone can read, modify or delete every index.",
   "Enable xpack.security.enabled: true to require authentication, and restrict network.host to 127.0.0.1 or a management network."
  ],
  "es": [
   "Riesgo de exposición de Elasticsearch sin autenticación",
   "Elasticsearch respondió a una solicitud de información del clúster sin autenticación. Con la seguridad desactivada y el puerto accesible, cualquiera puede leer, modificar o eliminar todos los índices.",
   "Habilita xpack.security.enabled: true para exigir autenticación y limita network.host a 127.0.0.1 o a una red de administración."
  ],
  "fr": [
   "Risque d'exposition d'Elasticsearch sans authentification",
   "Elasticsearch a répondu à une requête d'informations du cluster sans authentification. Si la sécurité est désactivée et le port accessible, n'importe qui peut lire, modifier ou supprimer tous les index.",
   "Activez xpack.security.enabled: true pour exiger l'authentification, et limitez network.host à 127.0.0.1 ou à un réseau d'administration."
  ],
  "it": [
   "Rischio di esposizione di Elasticsearch senza autenticazione",
   "Elasticsearch ha risposto a una richiesta di informazioni sul cluster senza autenticazione. Con la sicurezza disattivata e la porta raggiungibile, chiunque può leggere, modificare o eliminare tutti gli indici.",
   "Abilita xpack.security.enabled: true per richiedere l'autenticazione e limita network.host a 127.0.0.1 o a una rete di gestione."
  ],
  "ja": [
   "Elasticsearch 認証なし公開リスク",
   "Elasticsearch が認証なしでクラスタ情報に応答しました。セキュリティ機能が無効のまま到達可能だと、全インデックスの読み取り・改ざん・削除が誰にでも可能です。",
   "xpack.security.enabled: true を有効にして認証を必須にし、network.host を 127.0.0.1 または管理用ネットワークに限定してください。"
  ],
  "ko": [
   "Elasticsearch 인증 없는 노출 위험",
   "Elasticsearch가 인증 없이 클러스터 정보 요청에 응답했습니다. 보안 기능이 꺼진 채 접근할 수 있으면 누구나 모든 인덱스를 읽고 수정하고 삭제할 수 있습니다.",
   "xpack.security.enabled: true를 활성화해 인증을 필수로 하고 network.host를 127.0.0.1 또는 관리 네트워크로 제한하세요."
  ],
  "pt-PT": [
   "Risco de exposição do Elasticsearch sem autenticação",
   "O Elasticsearch respondeu a um pedido de informações do cluster sem autenticação. Com a segurança desativada e a porta acessível, qualquer pessoa pode ler, modificar ou eliminar todos os índices.",
   "Ative xpack.security.enabled: true para exigir autenticação e restrinja network.host a 127.0.0.1 ou a uma rede de gestão."
  ],
  "zh-Hans": [
   "Elasticsearch 未认证暴露风险",
   "Elasticsearch 在未认证的情况下响应了集群信息请求。若安全功能未启用且端口可达，任何人都可以读取、修改或删除所有索引。",
   "启用 xpack.security.enabled: true 以强制认证，并将 network.host 限制为 127.0.0.1 或管理网络。"
  ],
  "zh-Hant": [
   "Elasticsearch 未驗證暴露風險",
   "Elasticsearch 在未驗證的情況下回應了叢集資訊請求。若安全功能未啟用且連接埠可達，任何人都能讀取、修改或刪除所有索引。",
   "啟用 xpack.security.enabled: true 以強制驗證，並將 network.host 限制為 127.0.0.1 或管理網路。"
  ]
 },
 "signature:etcd-noauth": {
  "de": [
   "etcd-Cluster-Store-Expositionsrisiko",
   "Sofern keine Client-Authentifizierung (z. B. --client-cert-auth) explizit aktiviert ist, erlaubt etcd standardmäßig unauthentifizierten Zugriff auf alle Schlüssel-Wert-Daten.",
   "Aktivieren Sie --client-cert-auth, oder lauschen Sie ausschließlich auf 127.0.0.1."
  ],
  "en": [
   "etcd Cluster Store Exposure Risk",
   "Unless client authentication (e.g. --client-cert-auth) is explicitly enabled, etcd allows unauthenticated access to all key-value data by default.",
   "Enable --client-cert-auth, or listen only on 127.0.0.1."
  ],
  "es": [
   "Riesgo de exposición del almacén de clúster etcd",
   "A menos que la autenticación de cliente (p. ej. --client-cert-auth) esté explícitamente habilitada, etcd permite de forma predeterminada el acceso no autenticado a todos los datos clave-valor.",
   "Activa --client-cert-auth, o escucha únicamente en 127.0.0.1."
  ],
  "fr": [
   "Risque d'exposition du magasin de cluster etcd",
   "Sauf si l'authentification client (par ex. --client-cert-auth) est explicitement activée, etcd autorise par défaut l'accès non authentifié à toutes les données clé-valeur.",
   "Activez --client-cert-auth, ou écoutez uniquement sur 127.0.0.1."
  ],
  "it": [
   "Rischio di esposizione dell'archivio cluster etcd",
   "A meno che l'autenticazione client (ad es. --client-cert-auth) non sia esplicitamente abilitata, etcd consente per impostazione predefinita l'accesso non autenticato a tutti i dati chiave-valore.",
   "Abilita --client-cert-auth, oppure ascolta solo su 127.0.0.1."
  ],
  "ja": [
   "etcd クラスタストア露出リスク",
   "etcdはクライアント認証（--client-cert-auth 等）を明示的に有効化しない限り、既定では未認証で全キーバリューデータへアクセスできます。",
   "--client-cert-auth を有効にするか、127.0.0.1 限定でリッスンしてください。"
  ],
  "ko": [
   "etcd 클러스터 스토어 노출 위험",
   "클라이언트 인증(--client-cert-auth 등)을 명시적으로 활성화하지 않으면 etcd는 기본적으로 인증 없이 모든 키-값 데이터에 접근할 수 있습니다.",
   "--client-cert-auth를 활성화하거나 127.0.0.1로만 수신 대기하세요."
  ],
  "pt-PT": [
   "Risco de exposição do armazenamento de cluster etcd",
   "A menos que a autenticação do cliente (por exemplo, --client-cert-auth) seja explicitamente ativada, o etcd permite, por predefinição, o acesso não autenticado a todos os dados de chave-valor.",
   "Ative --client-cert-auth, ou fique à escuta apenas em 127.0.0.1."
  ],
  "zh-Hans": [
   "etcd 集群存储暴露风险",
   "除非明确启用客户端认证（如 --client-cert-auth），否则 etcd 默认允许未认证访问所有键值数据。",
   "请启用 --client-cert-auth，或仅在 127.0.0.1 上监听。"
  ],
  "zh-Hant": [
   "etcd 叢集儲存暴露風險",
   "除非明確啟用用戶端驗證（如 --client-cert-auth），否則 etcd 預設允許未驗證存取所有鍵值資料。",
   "請啟用 --client-cert-auth，或僅在 127.0.0.1 上監聽。"
  ]
 },
 "signature:ftp-anonymous-login": {
  "de": [
   "FTP erlaubt anonyme Anmeldung",
   "Dieser FTP-Server akzeptiert eine anonyme Anmeldung ohne echte Zugangsdaten, sodass jeder Dateien durchsuchen oder herunterladen kann.",
   "Deaktivieren Sie die anonyme Anmeldung oder wechseln Sie zu einer verschlüsselten Alternative wie SFTP."
  ],
  "en": [
   "FTP Anonymous Login Allowed",
   "This FTP server accepts an anonymous login with no real credentials, letting anyone browse or download files.",
   "Disable anonymous login, or migrate to an encrypted alternative such as SFTP."
  ],
  "es": [
   "Inicio de sesión anónimo FTP permitido",
   "Este servidor FTP acepta un inicio de sesión anónimo sin credenciales reales, permitiendo que cualquiera explore o descargue archivos.",
   "Deshabilite el inicio de sesión anónimo, o migre a una alternativa cifrada como SFTP."
  ],
  "fr": [
   "Connexion anonyme FTP autorisée",
   "Ce serveur FTP accepte une connexion anonyme sans identifiants réels, permettant à quiconque de parcourir ou télécharger des fichiers.",
   "Désactivez la connexion anonyme, ou migrez vers une alternative chiffrée telle que SFTP."
  ],
  "it": [
   "Accesso anonimo FTP consentito",
   "Questo server FTP accetta un accesso anonimo senza credenziali reali, permettendo a chiunque di sfogliare o scaricare file.",
   "Disabilita l'accesso anonimo, oppure migra a un'alternativa cifrata come SFTP."
  ],
  "ja": [
   "FTP 匿名ログイン許可",
   "このFTPサーバーは、ユーザー名 anonymous での認証情報なしログインを許可しています。ファイル一覧の閲覧や取得が誰でも可能な状態です。",
   "匿名ログインを無効化するか、暗号化された代替手段（SFTP等）へ移行してください。"
  ],
  "ko": [
   "FTP 익명 로그인 허용",
   "이 FTP 서버는 사용자 이름 anonymous로 자격 증명 없이 로그인할 수 있도록 허용하며, 누구나 파일을 탐색하거나 다운로드할 수 있는 상태입니다.",
   "익명 로그인을 비활성화하거나 SFTP 등 암호화된 대안으로 이전하세요."
  ],
  "pt-PT": [
   "Início de sessão anónimo FTP permitido",
   "Este servidor FTP aceita um início de sessão anónimo sem credenciais reais, permitindo que qualquer pessoa navegue ou transfira ficheiros.",
   "Desative o início de sessão anónimo, ou migre para uma alternativa encriptada como o SFTP."
  ],
  "zh-Hans": [
   "FTP 允许匿名登录",
   "此 FTP 服务器允许使用用户名 anonymous 进行无凭据登录，任何人都可以浏览或下载文件。",
   "请禁用匿名登录，或迁移到 SFTP 等加密方案。"
  ],
  "zh-Hant": [
   "FTP 允許匿名登入",
   "此 FTP 伺服器允許使用使用者名稱 anonymous 進行無憑證登入，任何人都可以瀏覽或下載檔案。",
   "請停用匿名登入，或遷移至 SFTP 等加密方案。"
  ]
 },
 "signature:gradio-noauth": {
  "de": [
   "Eine Gradio-App ist ohne Authentifizierung erreichbar",
   "Die Konfiguration der Gradio-App (/config) wurde auf diesem Port ohne Anmeldung zurückgegeben. Ohne auth kann jeder eine Gradio-App bedienen, und alles, was sie kann (Dateien lesen und schreiben, Modelle oder externe Befehle ausführen usw.), steht ihm offen. Das passiert mit server_name auf 0.0.0.0 oder mit einem öffentlichen share=True-Link.",
   "Übergeben Sie launch() auth=(Benutzername, Passwort), lassen Sie server_name auf 127.0.0.1 und verwenden Sie keinen öffentlichen share=True-Link."
  ],
  "en": [
   "A Gradio app is exposed without authentication",
   "The Gradio app's configuration (/config) came back on this port without a login. Unless auth is set, anyone can operate a Gradio app, and whatever it can do (read and write files, run models or external commands, and so on) is available to them. This happens with server_name set to 0.0.0.0 or with a share=True public link.",
   "Pass auth=(username, password) to launch(), keep server_name at 127.0.0.1, and do not use a share=True public link."
  ],
  "es": [
   "Una aplicación Gradio está expuesta sin autenticación",
   "La configuración de la aplicación Gradio (/config) se devolvió en este puerto sin iniciar sesión. Si no se establece auth, cualquiera puede manejar una aplicación Gradio y todo lo que esta puede hacer (leer y escribir archivos, ejecutar modelos o comandos externos, etc.) queda a su alcance. Ocurre con server_name en 0.0.0.0 o con un enlace público share=True.",
   "Pase auth=(usuario, contraseña) a launch(), deje server_name en 127.0.0.1 y no use un enlace público share=True."
  ],
  "fr": [
   "Une application Gradio est exposée sans authentification",
   "La configuration de l'application Gradio (/config) a été renvoyée sur ce port sans connexion. Sans auth, n'importe qui peut utiliser une application Gradio, et tout ce qu'elle sait faire (lire et écrire des fichiers, exécuter des modèles ou des commandes externes, etc.) lui est ouvert. Cela arrive avec server_name sur 0.0.0.0 ou avec un lien public share=True.",
   "Passez auth=(utilisateur, mot de passe) à launch(), laissez server_name sur 127.0.0.1 et n'utilisez pas de lien public share=True."
  ],
  "it": [
   "Un'app Gradio è esposta senza autenticazione",
   "La configurazione dell'app Gradio (/config) è stata restituita su questa porta senza login. Se non è impostato auth, chiunque può usare un'app Gradio e tutto ciò che sa fare (leggere e scrivere file, eseguire modelli o comandi esterni, ecc.) gli è disponibile. Succede con server_name impostato su 0.0.0.0 o con un link pubblico share=True.",
   "Passa auth=(utente, password) a launch(), lascia server_name su 127.0.0.1 e non usare un link pubblico share=True."
  ],
  "ja": [
   "Gradio アプリが認証なしで公開されています",
   "このポートで Gradio アプリの設定(/config)がログインなしで返りました。Gradio は auth を指定しない限り誰でも操作でき、アプリが持つ機能(ファイルの読み書き、モデルや外部コマンドの実行など)がそのまま使われます。server_name を 0.0.0.0 にした場合や、share=True の公開リンクで起きる状態です。",
   "launch() に auth=(ユーザー名, パスワード) を指定し、server_name は 127.0.0.1 にしてください。share=True の公開リンクは使わないでください。"
  ],
  "ko": [
   "Gradio 앱이 인증 없이 공개되어 있습니다",
   "이 포트에서 Gradio 앱의 설정(/config)이 로그인 없이 반환되었습니다. auth를 지정하지 않으면 누구나 Gradio 앱을 조작할 수 있고, 앱이 가진 기능(파일 읽기·쓰기, 모델이나 외부 명령 실행 등)이 그대로 사용됩니다. server_name을 0.0.0.0으로 했거나 share=True 공개 링크를 쓰면 생기는 상태입니다.",
   "launch()에 auth=(사용자 이름, 비밀번호)를 지정하고 server_name은 127.0.0.1로 두세요. share=True 공개 링크는 쓰지 마세요."
  ],
  "pt-PT": [
   "Uma aplicação Gradio está exposta sem autenticação",
   "A configuração da aplicação Gradio (/config) foi devolvida neste porto sem início de sessão. Sem auth, qualquer pessoa pode usar uma aplicação Gradio e tudo o que ela sabe fazer (ler e escrever ficheiros, executar modelos ou comandos externos, etc.) fica ao seu alcance. Acontece com server_name definido como 0.0.0.0 ou com uma ligação pública share=True.",
   "Passe auth=(utilizador, palavra-passe) a launch(), mantenha server_name em 127.0.0.1 e não use uma ligação pública share=True."
  ],
  "zh-Hans": [
   "Gradio 应用在没有认证的情况下对外开放",
   "此端口上 Gradio 应用的配置（/config）无需登录就返回了。除非设置了 auth，否则任何人都能操作 Gradio 应用，应用具备的功能（读写文件、运行模型或外部命令等）都会被直接使用。把 server_name 设为 0.0.0.0，或使用 share=True 的公开链接时就会出现这种状态。",
   "请在 launch() 中指定 auth=(用户名, 密码)，并把 server_name 保持为 127.0.0.1。不要使用 share=True 的公开链接。"
  ],
  "zh-Hant": [
   "Gradio 應用程式在沒有驗證的情況下對外開放",
   "此連接埠上 Gradio 應用程式的設定（/config）無需登入就回傳了。除非設定了 auth，否則任何人都能操作 Gradio 應用程式，應用程式具備的功能（讀寫檔案、執行模型或外部指令等）都會被直接使用。把 server_name 設為 0.0.0.0，或使用 share=True 的公開連結時就會出現這種狀態。",
   "請在 launch() 中指定 auth=(使用者名稱, 密碼)，並把 server_name 保持為 127.0.0.1。不要使用 share=True 的公開連結。"
  ]
 },
 "signature:hexstrike-noauth": {
  "de": [
   "Eine unauthentifizierte Befehlsausführungs-API im Stil von HexStrike AI läuft",
   "Auf diesem Port hat die API von HexStrike AI geantwortet (ein MCP-Backend, mit dem eine KI Penetrationstest-Werkzeuge selbstständig ausführt). Der Server hat keine Authentifizierung und führt jede an /api/command gesendete Zeichenfolge unverändert in einer Shell aus. Der Standardstart (python3 hexstrike_server.py) lauscht auf allen Schnittstellen, daher kann jeder im selben Netzwerk beliebige Befehle auf diesem Host ausführen.",
   "Beenden Sie den Prozess, falls Sie ihn nicht absichtlich nutzen. Falls doch, beschränken Sie ihn auf eine vom vertrauenswürdigen Netzwerk getrennte Test-VM und sperren Sie diesen Port per Firewall nach außen."
  ],
  "en": [
   "A HexStrike AI-style unauthenticated command-execution API is running",
   "The HexStrike AI API (an MCP backend that lets an AI autonomously run penetration-testing tools) answered on this port. This server has no authentication and passes whatever string is sent to /api/command straight to a shell. Its standard launch (python3 hexstrike_server.py) listens on every interface, so anyone on the same network can run arbitrary commands on this host.",
   "If you are not using it on purpose, stop the process. If you are, confine it to an isolated test VM cut off from trusted networks and block this port from outside with a firewall."
  ],
  "es": [
   "Se está ejecutando una API de ejecución de comandos sin autenticación del tipo HexStrike AI",
   "La API de HexStrike AI (un backend MCP que permite a una IA ejecutar de forma autónoma herramientas de pruebas de penetración) respondió en este puerto. Este servidor no tiene autenticación y pasa tal cual a un shell cualquier cadena enviada a /api/command. Su inicio estándar (python3 hexstrike_server.py) escucha en todas las interfaces, por lo que cualquiera en la misma red puede ejecutar comandos arbitrarios en este equipo.",
   "Si no lo usa a propósito, detenga el proceso. Si lo usa, limítelo a una VM de pruebas aislada de las redes de confianza y bloquee este puerto desde el exterior con un cortafuegos."
  ],
  "fr": [
   "Une API d'exécution de commandes sans authentification de type HexStrike AI est en cours d'exécution",
   "L'API de HexStrike AI (un backend MCP qui laisse une IA exécuter de façon autonome des outils de test d'intrusion) a répondu sur ce port. Ce serveur n'a aucune authentification et transmet tel quel à un shell toute chaîne envoyée à /api/command. Son lancement standard (python3 hexstrike_server.py) écoute sur toutes les interfaces : n'importe qui sur le même réseau peut donc exécuter des commandes arbitraires sur cet hôte.",
   "Si vous ne l'utilisez pas volontairement, arrêtez le processus. Si vous l'utilisez, limitez-le à une VM de test isolée des réseaux de confiance et bloquez ce port depuis l'extérieur avec un pare-feu."
  ],
  "it": [
   "È in esecuzione un'API di esecuzione comandi senza autenticazione di tipo HexStrike AI",
   "L'API di HexStrike AI (un backend MCP che permette a un'IA di eseguire in autonomia strumenti di penetration test) ha risposto su questa porta. Il server non ha autenticazione e passa così com'è a una shell qualsiasi stringa inviata a /api/command. L'avvio standard (python3 hexstrike_server.py) è in ascolto su tutte le interfacce, quindi chiunque sulla stessa rete può eseguire comandi arbitrari su questo host.",
   "Se non lo stai usando di proposito, arresta il processo. Se lo usi, limitalo a una VM di test isolata dalle reti attendibili e blocca questa porta dall'esterno con un firewall."
  ],
  "ja": [
   "HexStrike AI 型の認証なしコマンド実行 API が稼働しています",
   "このポートで HexStrike AI(AI にペネトレーションテスト用ツールを自律実行させる MCP バックエンド)の API が応答しました。このサーバーには認証がなく、/api/command に送られた文字列をそのままシェルで実行します。標準の起動方法(python3 hexstrike_server.py)は全インターフェースで待ち受けるため、同じネットワークの誰でも、このホスト上で任意のコマンドを実行できる状態になります。",
   "意図して使っていない場合はプロセスを停止してください。使う場合は信頼できるネットワークから切り離した検証用の VM 内に限定し、このポートをファイアウォールで外部から遮断してください。"
  ],
  "ko": [
   "HexStrike AI 유형의 인증 없는 명령 실행 API가 동작하고 있습니다",
   "이 포트에서 HexStrike AI(AI가 침투 테스트 도구를 자율적으로 실행하게 하는 MCP 백엔드)의 API가 응답했습니다. 이 서버에는 인증이 없고 /api/command로 보낸 문자열을 그대로 셸에서 실행합니다. 기본 실행 방식(python3 hexstrike_server.py)은 모든 인터페이스에서 대기하므로, 같은 네트워크의 누구나 이 호스트에서 임의의 명령을 실행할 수 있는 상태가 됩니다.",
   "의도하지 않은 경우 프로세스를 중지하세요. 사용하는 경우에는 신뢰할 수 있는 네트워크와 분리된 검증용 VM 안으로 한정하고, 이 포트를 방화벽으로 외부에서 차단하세요."
  ],
  "pt-PT": [
   "Está em execução uma API de execução de comandos sem autenticação do tipo HexStrike AI",
   "A API do HexStrike AI (um backend MCP que permite a uma IA executar de forma autónoma ferramentas de testes de intrusão) respondeu neste porto. Este servidor não tem autenticação e passa tal como está para uma shell qualquer cadeia enviada para /api/command. O arranque padrão (python3 hexstrike_server.py) escuta em todas as interfaces, pelo que qualquer pessoa na mesma rede pode executar comandos arbitrários neste anfitrião.",
   "Se não o está a usar de propósito, termine o processo. Se o usa, limite-o a uma VM de testes isolada das redes de confiança e bloqueie este porto a partir do exterior com uma firewall."
  ],
  "zh-Hans": [
   "检测到 HexStrike AI 类型的无认证命令执行 API 正在运行",
   "此端口上有 HexStrike AI(让 AI 自主运行渗透测试工具的 MCP 后端)的 API 作出了响应。该服务器没有认证，会把发送到 /api/command 的字符串原样交给 shell 执行。其标准启动方式(python3 hexstrike_server.py)会监听所有网络接口，因此同一网络中的任何人都可以在这台主机上执行任意命令。",
   "如果不是有意使用，请停止该进程。如需使用，请仅在与可信网络隔离的测试虚拟机内运行，并用防火墙从外部封锁此端口。"
  ],
  "zh-Hant": [
   "偵測到 HexStrike AI 類型的無驗證命令執行 API 正在執行",
   "此連接埠上有 HexStrike AI(讓 AI 自主執行滲透測試工具的 MCP 後端)的 API 作出了回應。該伺服器沒有驗證，會把傳送到 /api/command 的字串原樣交給 shell 執行。其標準啟動方式(python3 hexstrike_server.py)會監聽所有網路介面，因此同一網路中的任何人都可以在這台主機上執行任意命令。",
   "如果不是有意使用，請停止該程序。如需使用，請僅在與可信網路隔離的測試虛擬機內執行，並用防火牆從外部封鎖此連接埠。"
  ]
 },
 "signature:jenkins-noauth": {
  "de": [
   "Jenkins: Zugriff ohne Authentifizierung",
   "Jenkins hat Job-Informationen (/api/json) ohne Authentifizierung zurückgegeben. Bei erlaubtem anonymem Zugriff lassen sich Build-Konfigurationen und Zugangsdaten einsehen, und Skriptausführung kann zur Übernahme des Servers führen.",
   "Aktivieren Sie unter Manage Jenkins > Security die Sicherheit und entziehen Sie anonymen Benutzern das Leserecht."
  ],
  "en": [
   "Jenkins Unauthenticated Exposure Risk",
   "Jenkins returned job information (/api/json) without authentication. If anonymous access is allowed, build configurations and credentials can be viewed, and script execution can lead to full server takeover.",
   "Enable security under Manage Jenkins > Security and remove read access for anonymous users."
  ],
  "es": [
   "Riesgo de exposición de Jenkins sin autenticación",
   "Jenkins devolvió información de trabajos (/api/json) sin autenticación. Si se permite el acceso anónimo, se pueden ver las configuraciones de compilación y las credenciales, y la ejecución de scripts puede llevar a la toma de control del servidor.",
   "Activa la seguridad en Manage Jenkins > Security y elimina el acceso de lectura a los usuarios anónimos."
  ],
  "fr": [
   "Risque d'exposition de Jenkins sans authentification",
   "Jenkins a renvoyé des informations sur les jobs (/api/json) sans authentification. Si l'accès anonyme est autorisé, les configurations de build et les identifiants peuvent être consultés, et l'exécution de scripts peut mener à la prise de contrôle du serveur.",
   "Activez la sécurité dans Manage Jenkins > Security et retirez le droit de lecture aux utilisateurs anonymes."
  ],
  "it": [
   "Rischio di esposizione di Jenkins senza autenticazione",
   "Jenkins ha restituito informazioni sui job (/api/json) senza autenticazione. Se l'accesso anonimo è consentito, è possibile vedere le configurazioni di build e le credenziali, e l'esecuzione di script può portare alla presa di controllo del server.",
   "Abilita la sicurezza in Manage Jenkins > Security e rimuovi l'accesso in lettura agli utenti anonimi."
  ],
  "ja": [
   "Jenkins 認証なし公開リスク",
   "Jenkins が認証なしでジョブ情報（/api/json）を返しました。匿名アクセスが許可されていると、ビルド設定や認証情報の閲覧、さらにスクリプト実行によるサーバー乗っ取りにつながります。",
   "「Manage Jenkins > Security」でセキュリティを有効にし、匿名ユーザーの読み取り権限も外してください。"
  ],
  "ko": [
   "Jenkins 인증 없는 노출 위험",
   "Jenkins가 인증 없이 작업 정보(/api/json)를 반환했습니다. 익명 접근이 허용되면 빌드 설정과 자격 증명을 볼 수 있고 스크립트 실행으로 서버가 장악될 수 있습니다.",
   "Manage Jenkins > Security에서 보안을 활성화하고 익명 사용자의 읽기 권한도 제거하세요."
  ],
  "pt-PT": [
   "Risco de exposição do Jenkins sem autenticação",
   "O Jenkins devolveu informações de tarefas (/api/json) sem autenticação. Se o acesso anónimo for permitido, é possível ver configurações de compilação e credenciais, e a execução de scripts pode levar à tomada de controlo do servidor.",
   "Ative a segurança em Manage Jenkins > Security e remova o acesso de leitura aos utilizadores anónimos."
  ],
  "zh-Hans": [
   "Jenkins 未认证暴露风险",
   "Jenkins 在未认证的情况下返回了任务信息（/api/json）。若允许匿名访问，可查看构建配置和凭据，并可能通过脚本执行接管服务器。",
   "请在「Manage Jenkins > Security」中启用安全设置，并移除匿名用户的读取权限。"
  ],
  "zh-Hant": [
   "Jenkins 未驗證暴露風險",
   "Jenkins 在未驗證的情況下回傳了工作資訊（/api/json）。若允許匿名存取，可檢視建置設定與憑證，並可能透過指令碼執行接管伺服器。",
   "請在「Manage Jenkins > Security」中啟用安全設定，並移除匿名使用者的讀取權限。"
  ]
 },
 "signature:jupyter-noauth": {
  "de": [
   "Jupyter Server ist ohne Token und Passwort erreichbar",
   "Die API von Jupyter Server (/api/status) hat auf diesem Port ohne Anmeldung geantwortet. Jupyter kann Code aus Notebooks und Terminals ausführen; ohne Authentifizierung kann daher jeder, der das Netzwerk-Ziel erreicht, beliebige Befehle mit den Rechten dieses Benutzers ausführen. Das passiert, wenn Token und Passwort beide deaktiviert sind und der Server nicht nur auf 127.0.0.1 lauscht.",
   "Aktivieren Sie Token oder Passwort wieder und lassen Sie den Server nur auf 127.0.0.1 lauschen. Wenn Sie ihn von einem anderen Gerät brauchen, gehen Sie über eine SSH-Portweiterleitung o. Ä."
  ],
  "en": [
   "Jupyter Server is exposed without a token or password",
   "Jupyter Server's API (/api/status) answered on this port without a login. Jupyter can run code from notebooks and terminals, so without authentication anyone who can reach it over the network can run arbitrary commands with this user's privileges. This happens when both the token and the password are disabled and the server listens on something other than 127.0.0.1.",
   "Turn the token or password back on and make it listen on 127.0.0.1 only. If you need it from another device, go through an SSH port forward or similar."
  ],
  "es": [
   "Jupyter Server está expuesto sin token ni contraseña",
   "La API de Jupyter Server (/api/status) respondió en este puerto sin iniciar sesión. Jupyter puede ejecutar código desde cuadernos y terminales, así que sin autenticación cualquiera que lo alcance por la red puede ejecutar comandos arbitrarios con los privilegios de este usuario. Ocurre cuando el token y la contraseña están desactivados y el servidor escucha en algo distinto de 127.0.0.1.",
   "Vuelva a activar el token o la contraseña y haga que escuche solo en 127.0.0.1. Si lo necesita desde otro dispositivo, pase por un reenvío de puertos SSH o similar."
  ],
  "fr": [
   "Jupyter Server est exposé sans jeton ni mot de passe",
   "L'API de Jupyter Server (/api/status) a répondu sur ce port sans connexion. Jupyter peut exécuter du code depuis des notebooks et des terminaux : sans authentification, toute personne qui peut l'atteindre par le réseau peut exécuter des commandes arbitraires avec les droits de cet utilisateur. Cela arrive quand le jeton et le mot de passe sont tous deux désactivés et que le serveur écoute ailleurs que sur 127.0.0.1.",
   "Réactivez le jeton ou le mot de passe et faites écouter le serveur uniquement sur 127.0.0.1. Si vous en avez besoin depuis un autre appareil, passez par une redirection de port SSH ou équivalent."
  ],
  "it": [
   "Jupyter Server è esposto senza token né password",
   "L'API di Jupyter Server (/api/status) ha risposto su questa porta senza login. Jupyter può eseguire codice da notebook e terminali, quindi senza autenticazione chiunque lo raggiunga dalla rete può eseguire comandi arbitrari con i privilegi di questo utente. Succede quando token e password sono entrambi disattivati e il server è in ascolto su un indirizzo diverso da 127.0.0.1.",
   "Riattiva il token o la password e fai ascoltare il server solo su 127.0.0.1. Se serve da un altro dispositivo, passa tramite un port forwarding SSH o simile."
  ],
  "ja": [
   "Jupyter Server がトークンもパスワードもなしで公開されています",
   "このポートで Jupyter Server の API(/api/status)がログインなしで応答しました。Jupyter はノートブックやターミナルからコードを実行できるため、認証がないと、ネットワークから届く相手は誰でもこのユーザーの権限で任意のコマンドを実行できます。トークンとパスワードの両方を無効にしたまま、127.0.0.1 以外で待ち受けると起きる状態です。",
   "トークンかパスワードを有効に戻し、待ち受けを 127.0.0.1 だけにしてください。別の端末から使う場合は、SSH のポートフォワードなどで通してください。"
  ],
  "ko": [
   "Jupyter Server가 토큰도 비밀번호도 없이 공개되어 있습니다",
   "이 포트에서 Jupyter Server의 API(/api/status)가 로그인 없이 응답했습니다. Jupyter는 노트북과 터미널에서 코드를 실행할 수 있으므로, 인증이 없으면 네트워크로 접근할 수 있는 누구나 이 사용자의 권한으로 임의의 명령을 실행할 수 있습니다. 토큰과 비밀번호를 모두 끈 채 127.0.0.1 이외의 주소에서 대기하면 생기는 상태입니다.",
   "토큰이나 비밀번호를 다시 켜고 127.0.0.1에서만 대기하도록 하세요. 다른 기기에서 써야 한다면 SSH 포트 포워딩 등을 통해 접속하세요."
  ],
  "pt-PT": [
   "O Jupyter Server está exposto sem token nem palavra-passe",
   "A API do Jupyter Server (/api/status) respondeu neste porto sem início de sessão. O Jupyter pode executar código a partir de cadernos e terminais, por isso, sem autenticação, qualquer pessoa que o alcance pela rede pode executar comandos arbitrários com os privilégios deste utilizador. Acontece quando o token e a palavra-passe estão ambos desativados e o servidor escuta noutro endereço que não 127.0.0.1.",
   "Volte a ativar o token ou a palavra-passe e faça-o escutar apenas em 127.0.0.1. Se precisar dele a partir de outro dispositivo, use um reencaminhamento de portos SSH ou semelhante."
  ],
  "zh-Hans": [
   "Jupyter Server 在没有令牌和密码的情况下对外开放",
   "此端口上的 Jupyter Server API（/api/status）无需登录就作出了响应。Jupyter 可以通过笔记本和终端运行代码，因此没有认证时，能通过网络访问到它的任何人都可以用该用户的权限执行任意命令。令牌和密码都被关闭且监听在 127.0.0.1 以外的地址时就会出现这种状态。",
   "请重新启用令牌或密码，并让它只监听 127.0.0.1。如需从其他设备使用，请通过 SSH 端口转发等方式访问。"
  ],
  "zh-Hant": [
   "Jupyter Server 在沒有權杖和密碼的情況下對外開放",
   "此連接埠上的 Jupyter Server API（/api/status）無需登入就作出了回應。Jupyter 可以透過筆記本和終端機執行程式碼，因此沒有驗證時，能透過網路存取到它的任何人都可以用該使用者的權限執行任意指令。權杖和密碼都被關閉且監聽在 127.0.0.1 以外的位址時就會出現這種狀態。",
   "請重新啟用權杖或密碼，並讓它只監聽 127.0.0.1。如需從其他裝置使用，請透過 SSH 連接埠轉送等方式存取。"
  ]
 },
 "signature:memcached-noauth": {
  "de": [
   "Memcached-Expositionsrisiko (nicht standardmäßiger Port)",
   "Memcached arbeitet mit einem Protokoll ohne Authentifizierungsmechanismus. Bei externer Exposition können Cache-Inhalte gelesen oder manipuliert werden, und im UDP-Modus kann es als DDoS-Verstärkungsvektor missbraucht werden.",
   "Starten Sie es mit -l 127.0.0.1 oder blockieren Sie die Erreichbarkeit von außen."
  ],
  "en": [
   "Memcached Exposure Risk (Non-Standard Port)",
   "Memcached operates on a protocol with no authentication mechanism. If exposed externally, its cache contents can be read or tampered with, and in UDP mode it can be abused as a DDoS amplification vector.",
   "Start it with -l 127.0.0.1, or block reachability from outside."
  ],
  "es": [
   "Riesgo de exposición de Memcached (puerto no estándar)",
   "Memcached funciona con un protocolo sin mecanismo de autenticación. Si se expone externamente, el contenido de la caché puede leerse o manipularse, y en modo UDP puede utilizarse como vector de amplificación DDoS.",
   "Inícialo con -l 127.0.0.1, o bloquea el acceso desde el exterior."
  ],
  "fr": [
   "Risque d'exposition Memcached (port non standard)",
   "Memcached fonctionne avec un protocole dépourvu de mécanisme d'authentification. En cas d'exposition externe, le contenu du cache peut être lu ou altéré, et en mode UDP, il peut être détourné comme vecteur d'amplification DDoS.",
   "Démarrez-le avec -l 127.0.0.1, ou bloquez son accessibilité depuis l'extérieur."
  ],
  "it": [
   "Rischio di esposizione Memcached (porta non standard)",
   "Memcached funziona con un protocollo privo di meccanismo di autenticazione. Se esposto esternamente, il contenuto della cache può essere letto o manomesso e, in modalità UDP, può essere sfruttato come vettore di amplificazione DDoS.",
   "Avvialo con -l 127.0.0.1, oppure blocca la raggiungibilità dall'esterno."
  ],
  "ja": [
   "Memcached 露出リスク（非標準ポート）",
   "Memcachedは認証機構を持たないプロトコルで動作します。外部公開されるとキャッシュ内容の読み取り・改ざんに加え、UDPモードではDDoS増幅の踏み台にされる恐れがあります。",
   "-l 127.0.0.1 を指定して起動するか、外部からの到達を遮断してください。"
  ],
  "ko": [
   "Memcached 노출 위험 (비표준 포트)",
   "Memcached는 인증 메커니즘이 없는 프로토콜로 동작합니다. 외부에 노출되면 캐시 내용을 읽거나 변조할 수 있으며, UDP 모드에서는 DDoS 증폭 공격의 발판으로 악용될 위험이 있습니다.",
   "-l 127.0.0.1을 지정하여 시작하거나 외부에서의 접근을 차단하세요."
  ],
  "pt-PT": [
   "Risco de exposição do Memcached (porta não padrão)",
   "O Memcached funciona com um protocolo sem mecanismo de autenticação. Se exposto externamente, o conteúdo da cache pode ser lido ou adulterado e, no modo UDP, pode ser utilizado como vetor de amplificação DDoS.",
   "Inicie-o com -l 127.0.0.1, ou bloqueie o acesso a partir do exterior."
  ],
  "zh-Hans": [
   "Memcached 暴露风险（非标准端口）",
   "Memcached 使用没有认证机制的协议运行。若对外暴露，缓存内容可能被读取或篡改，UDP 模式下还可能被滥用为 DDoS 放大攻击的跳板。",
   "请以 -l 127.0.0.1 启动，或阻断来自外部的可达性。"
  ],
  "zh-Hant": [
   "Memcached 暴露風險（非標準連接埠）",
   "Memcached 使用沒有驗證機制的通訊協定運作。若對外暴露，快取內容可能遭讀取或竄改，UDP 模式下還可能被濫用為 DDoS 放大攻擊的跳板。",
   "請以 -l 127.0.0.1 啟動，或封鎖來自外部的連線。"
  ]
 },
 "signature:mlflow-noauth": {
  "de": [
   "MLflow Tracking Server ist ohne Authentifizierung erreichbar",
   "Auf diesem Port wurde die Experimentliste von MLflow (/api/2.0/mlflow/experiments/search) ohne Anmeldung zurückgegeben. MLflow hat standardmäßig keine Authentifizierung: Wer es erreicht, kann Experimentnamen, Parameter, Metriken und Artefaktorte lesen sowie Experimente und registrierte Modelle anlegen oder löschen. Werden Artefakte wie trainierte Modelle ausgetauscht, kann bei dem, der sie lädt, Code ausgeführt werden.",
   "Starten Sie es mit --host 127.0.0.1 neu. Muss es im Netzwerk erreichbar sein, betreiben Sie es hinter MLflows basic-auth (--app-name basic-auth) oder einem Reverse-Proxy mit Authentifizierung."
  ],
  "en": [
   "MLflow Tracking Server is exposed without authentication",
   "MLflow's experiment list (/api/2.0/mlflow/experiments/search) came back on this port without a login. MLflow has no authentication by default, so anyone who can reach it can read experiment names, parameters, metrics and artifact locations, and can create or delete experiments and registered models. If artifacts such as trained models are swapped, code may run on whoever loads them.",
   "Restart it with --host 127.0.0.1. If it must be on the network, keep it behind MLflow's basic-auth (--app-name basic-auth) or a reverse proxy with authentication."
  ],
  "es": [
   "MLflow Tracking Server está expuesto sin autenticación",
   "La lista de experimentos de MLflow (/api/2.0/mlflow/experiments/search) se devolvió en este puerto sin iniciar sesión. MLflow no tiene autenticación por defecto, así que cualquiera que lo alcance puede leer nombres de experimentos, parámetros, métricas y ubicaciones de artefactos, y crear o eliminar experimentos y modelos registrados. Si se sustituyen artefactos como modelos entrenados, puede ejecutarse código en quien los cargue.",
   "Reinícielo con --host 127.0.0.1. Si debe estar en la red, manténgalo detrás del basic-auth de MLflow (--app-name basic-auth) o de un proxy inverso con autenticación."
  ],
  "fr": [
   "MLflow Tracking Server est exposé sans authentification",
   "La liste des expériences de MLflow (/api/2.0/mlflow/experiments/search) a été renvoyée sur ce port sans connexion. MLflow n'a pas d'authentification par défaut : toute personne qui peut l'atteindre peut lire les noms d'expériences, paramètres, métriques et emplacements d'artefacts, et créer ou supprimer des expériences et des modèles enregistrés. Si des artefacts comme des modèles entraînés sont remplacés, du code peut s'exécuter chez celui qui les charge.",
   "Relancez-le avec --host 127.0.0.1. S'il doit être sur le réseau, gardez-le derrière le basic-auth de MLflow (--app-name basic-auth) ou un reverse proxy avec authentification."
  ],
  "it": [
   "MLflow Tracking Server è esposto senza autenticazione",
   "L'elenco degli esperimenti di MLflow (/api/2.0/mlflow/experiments/search) è stato restituito su questa porta senza login. MLflow non ha autenticazione di default: chiunque lo raggiunga può leggere nomi degli esperimenti, parametri, metriche e posizioni degli artefatti, e creare o eliminare esperimenti e modelli registrati. Se vengono sostituiti artefatti come i modelli addestrati, può essere eseguito codice su chi li carica.",
   "Riavvialo con --host 127.0.0.1. Se deve stare in rete, tienilo dietro il basic-auth di MLflow (--app-name basic-auth) o un reverse proxy con autenticazione."
  ],
  "ja": [
   "MLflow Tracking Server が認証なしで公開されています",
   "このポートで MLflow の実験一覧(/api/2.0/mlflow/experiments/search)がログインなしで返りました。MLflow は既定では認証がなく、届く相手は誰でも実験名・パラメータ・指標・成果物の保存先を読め、実験やモデルの登録・削除もできます。成果物(学習済みモデルなど)を差し替えられると、それを読み込む側でコードが実行される恐れがあります。",
   "--host 127.0.0.1 で起動し直してください。ネットワークに出す必要がある場合は、MLflow の basic-auth(--app-name basic-auth)か、認証付きのリバースプロキシの内側に限定してください。"
  ],
  "ko": [
   "MLflow Tracking Server가 인증 없이 공개되어 있습니다",
   "이 포트에서 MLflow의 실험 목록(/api/2.0/mlflow/experiments/search)이 로그인 없이 반환되었습니다. MLflow는 기본적으로 인증이 없어, 접근할 수 있는 누구나 실험 이름·파라미터·지표·아티팩트 위치를 읽고 실험과 등록된 모델을 만들거나 삭제할 수 있습니다. 학습된 모델 같은 아티팩트가 바뀌면 그것을 불러오는 쪽에서 코드가 실행될 수 있습니다.",
   "--host 127.0.0.1로 다시 시작하세요. 네트워크에 내놓아야 한다면 MLflow의 basic-auth(--app-name basic-auth)나 인증을 붙인 리버스 프록시 안쪽으로 한정하세요."
  ],
  "pt-PT": [
   "O MLflow Tracking Server está exposto sem autenticação",
   "A lista de experiências do MLflow (/api/2.0/mlflow/experiments/search) foi devolvida neste porto sem início de sessão. O MLflow não tem autenticação por predefinição, por isso qualquer pessoa que o alcance pode ler nomes de experiências, parâmetros, métricas e localizações de artefactos, e criar ou eliminar experiências e modelos registados. Se artefactos como modelos treinados forem substituídos, pode ser executado código em quem os carregar.",
   "Reinicie-o com --host 127.0.0.1. Se tiver de estar na rede, mantenha-o atrás do basic-auth do MLflow (--app-name basic-auth) ou de um proxy inverso com autenticação."
  ],
  "zh-Hans": [
   "MLflow Tracking Server 在没有认证的情况下对外开放",
   "此端口上 MLflow 的实验列表（/api/2.0/mlflow/experiments/search）无需登录就返回了。MLflow 默认没有认证，能访问到它的任何人都可以读取实验名称、参数、指标和制品位置，也可以创建、删除实验和已注册的模型。如果训练好的模型等制品被替换，加载它的一方可能会被执行恶意代码。",
   "请用 --host 127.0.0.1 重新启动。如果必须放到网络上，请限制在 MLflow 的 basic-auth（--app-name basic-auth）或带认证的反向代理之内。"
  ],
  "zh-Hant": [
   "MLflow Tracking Server 在沒有驗證的情況下對外開放",
   "此連接埠上 MLflow 的實驗清單（/api/2.0/mlflow/experiments/search）無需登入就回傳了。MLflow 預設沒有驗證，能存取到它的任何人都可以讀取實驗名稱、參數、指標和成品位置，也可以建立、刪除實驗和已註冊的模型。如果訓練好的模型等成品被替換，載入它的一方可能會被執行惡意程式碼。",
   "請用 --host 127.0.0.1 重新啟動。如果必須放到網路上，請限制在 MLflow 的 basic-auth（--app-name basic-auth）或具驗證的反向代理之內。"
  ]
 },
 "signature:mongod-default-noauth": {
  "de": [
   "MongoDB-Datenbank-Expositionsrisiko (nicht standardmäßiger Port)",
   "MongoDB lauscht ohne Authentifizierung, sofern --auth nicht explizit aktiviert ist. Da es auf einem anderen Port als dem Standard 27017 läuft, würde eine portnummernbasierte Erkennung es übersehen.",
   "Geben Sie in mongod.conf bindIp: 127.0.0.1 an und aktivieren Sie --auth."
  ],
  "en": [
   "MongoDB Database Exposure Risk (Non-Standard Port)",
   "MongoDB listens without authentication unless --auth is explicitly enabled. It's running on a port other than the standard 27017, so port-number-based detection would miss it.",
   "Set bindIp: 127.0.0.1 in mongod.conf and enable --auth."
  ],
  "es": [
   "Riesgo de exposición de la base de datos MongoDB (puerto no estándar)",
   "MongoDB escucha sin autenticación a menos que se habilite explícitamente --auth. Como se ejecuta en un puerto distinto del estándar 27017, la detección basada en el número de puerto no lo detectaría.",
   "Especifica bindIp: 127.0.0.1 en mongod.conf y habilita --auth."
  ],
  "fr": [
   "Risque d'exposition de la base de données MongoDB (port non standard)",
   "MongoDB écoute sans authentification sauf si --auth est explicitement activé. Comme il fonctionne sur un port autre que le port standard 27017, une détection basée sur le numéro de port le manquerait.",
   "Indiquez bindIp: 127.0.0.1 dans mongod.conf et activez --auth."
  ],
  "it": [
   "Rischio di esposizione del database MongoDB (porta non standard)",
   "MongoDB è in ascolto senza autenticazione a meno che --auth non sia esplicitamente abilitato. Poiché è in esecuzione su una porta diversa dalla standard 27017, il rilevamento basato sul numero di porta non lo individuerebbe.",
   "Specifica bindIp: 127.0.0.1 in mongod.conf e abilita --auth."
  ],
  "ja": [
   "MongoDB データベース露出リスク（非標準ポート）",
   "MongoDBは --auth を明示的に有効化しない限り認証なしで待ち受けます。標準の27017以外のポートで動作しているため、ポート番号ベースの検知では見逃されます。",
   "mongod.conf で bindIp: 127.0.0.1 を指定し、--auth を有効にしてください。"
  ],
  "ko": [
   "MongoDB 데이터베이스 노출 위험 (비표준 포트)",
   "MongoDB는 --auth를 명시적으로 활성화하지 않으면 인증 없이 대기합니다. 표준 포트인 27017이 아닌 포트에서 동작 중이므로 포트 번호 기반 탐지로는 발견되지 않습니다.",
   "mongod.conf에서 bindIp: 127.0.0.1을 지정하고 --auth를 활성화하세요."
  ],
  "pt-PT": [
   "Risco de exposição da base de dados MongoDB (porta não padrão)",
   "O MongoDB fica à escuta sem autenticação, a menos que --auth seja explicitamente ativado. Como está a ser executado numa porta diferente da porta padrão 27017, a deteção baseada no número da porta não o detetaria.",
   "Especifique bindIp: 127.0.0.1 no mongod.conf e ative --auth."
  ],
  "zh-Hans": [
   "MongoDB 数据库暴露风险（非标准端口）",
   "除非明确启用 --auth，否则 MongoDB 会在无认证状态下监听。由于它运行在标准 27017 以外的端口，基于端口号的检测无法发现它。",
   "请在 mongod.conf 中指定 bindIp: 127.0.0.1，并启用 --auth。"
  ],
  "zh-Hant": [
   "MongoDB 資料庫暴露風險（非標準連接埠）",
   "除非明確啟用 --auth，否則 MongoDB 會在無驗證狀態下監聽。由於它運行在標準 27017 以外的連接埠，基於連接埠號碼的偵測無法發現它。",
   "請在 mongod.conf 中指定 bindIp: 127.0.0.1，並啟用 --auth。"
  ]
 },
 "signature:ollama-exposed": {
  "de": [
   "Ollama (ein lokaler LLM-Server) ist ohne Authentifizierung aus dem Netzwerk nutzbar",
   "Auf diesem Port hat die API von Ollama geantwortet. Ollama hat keine Authentifizierung: Wer das Netzwerk-Ziel erreicht, kann Modelle auflisten, herunterladen und löschen sowie Inferenz ausführen. Ihre GPU und andere Rechenleistung können ohne Ihre Zustimmung genutzt und die Festplatte gefüllt werden. Standardmäßig lauscht Ollama auf 127.0.0.1, aber eine Einstellung wie OLLAMA_HOST=0.0.0.0 macht es aus dem Netzwerk erreichbar.",
   "Setzen Sie OLLAMA_HOST wieder auf 127.0.0.1 und starten Sie Ollama neu. Falls andere Geräte darauf zugreifen müssen, beschränken Sie den Zugriff auf einen Reverse-Proxy mit Authentifizierung oder ein VPN."
  ],
  "en": [
   "Ollama (a local LLM server) is usable from the network without authentication",
   "Ollama's API answered on this port. Ollama has no authentication, so anyone who can reach it over the network can list, download and delete models and run inference. Your GPU and other compute can be used without your consent, and the disk can be filled. It listens on 127.0.0.1 by default, but a setting such as OLLAMA_HOST=0.0.0.0 has made it reachable from the network.",
   "Set OLLAMA_HOST back to 127.0.0.1 and restart Ollama. If other devices need it, restrict it to behind a reverse proxy with authentication or a VPN."
  ],
  "es": [
   "Ollama (un servidor LLM local) se puede usar desde la red sin autenticación",
   "La API de Ollama respondió en este puerto. Ollama no tiene autenticación, así que cualquiera que pueda alcanzarlo por la red puede listar, descargar y eliminar modelos y ejecutar inferencia. Su GPU y otros recursos de cómputo pueden usarse sin su consentimiento y el disco puede llenarse. Por defecto escucha en 127.0.0.1, pero un ajuste como OLLAMA_HOST=0.0.0.0 lo hace accesible desde la red.",
   "Vuelva a poner OLLAMA_HOST en 127.0.0.1 y reinicie Ollama. Si otros dispositivos lo necesitan, limite el acceso a un proxy inverso con autenticación o a una VPN."
  ],
  "fr": [
   "Ollama (un serveur LLM local) est utilisable depuis le réseau sans authentification",
   "L'API d'Ollama a répondu sur ce port. Ollama n'a pas d'authentification : toute personne qui peut l'atteindre par le réseau peut lister, télécharger et supprimer des modèles et lancer des inférences. Votre GPU et d'autres ressources de calcul peuvent être utilisés sans votre accord, et le disque peut être saturé. Par défaut, Ollama écoute sur 127.0.0.1, mais un réglage tel que OLLAMA_HOST=0.0.0.0 le rend accessible depuis le réseau.",
   "Remettez OLLAMA_HOST sur 127.0.0.1 et redémarrez Ollama. Si d'autres appareils en ont besoin, limitez l'accès à un reverse proxy avec authentification ou à un VPN."
  ],
  "it": [
   "Ollama (un server LLM locale) è utilizzabile dalla rete senza autenticazione",
   "L'API di Ollama ha risposto su questa porta. Ollama non ha autenticazione: chiunque lo raggiunga dalla rete può elencare, scaricare ed eliminare modelli ed eseguire inferenza. La GPU e altre risorse di calcolo possono essere usate senza il tuo consenso e il disco può essere riempito. Di default è in ascolto su 127.0.0.1, ma un'impostazione come OLLAMA_HOST=0.0.0.0 lo rende raggiungibile dalla rete.",
   "Riporta OLLAMA_HOST a 127.0.0.1 e riavvia Ollama. Se altri dispositivi ne hanno bisogno, limita l'accesso a un reverse proxy con autenticazione o a una VPN."
  ],
  "ja": [
   "Ollama(ローカル LLM サーバー)が認証なしでネットワークから使える状態です",
   "このポートで Ollama の API が応答しました。Ollama には認証の仕組みがなく、ネットワークから届く相手は誰でもモデルの一覧取得・ダウンロード・削除・推論の実行ができます。GPU などの計算資源を勝手に使われたり、ディスクを埋められたりします。既定の待ち受けは 127.0.0.1 ですが、OLLAMA_HOST=0.0.0.0 などの設定でネットワークから届く状態になっています。",
   "OLLAMA_HOST を 127.0.0.1 に戻して Ollama を再起動してください。他の端末から使う必要がある場合は、認証を付けたリバースプロキシか VPN の内側に限定してください。"
  ],
  "ko": [
   "Ollama(로컬 LLM 서버)를 인증 없이 네트워크에서 사용할 수 있습니다",
   "이 포트에서 Ollama의 API가 응답했습니다. Ollama에는 인증 기능이 없어, 네트워크로 접근할 수 있는 누구나 모델 목록 조회·다운로드·삭제와 추론 실행을 할 수 있습니다. GPU 같은 계산 자원을 마음대로 쓰거나 디스크를 가득 채울 수 있습니다. 기본 대기 주소는 127.0.0.1이지만 OLLAMA_HOST=0.0.0.0 같은 설정으로 네트워크에서 접근할 수 있는 상태입니다.",
   "OLLAMA_HOST를 다시 127.0.0.1로 되돌리고 Ollama를 재시작하세요. 다른 기기에서 사용해야 한다면 인증을 붙인 리버스 프록시나 VPN 안쪽으로 한정하세요."
  ],
  "pt-PT": [
   "O Ollama (um servidor LLM local) pode ser usado a partir da rede sem autenticação",
   "A API do Ollama respondeu neste porto. O Ollama não tem autenticação, por isso qualquer pessoa que o alcance pela rede pode listar, descarregar e eliminar modelos e executar inferência. A GPU e outros recursos de cálculo podem ser usados sem o seu consentimento e o disco pode ficar cheio. Por predefinição escuta em 127.0.0.1, mas uma definição como OLLAMA_HOST=0.0.0.0 torna-o acessível a partir da rede.",
   "Volte a definir OLLAMA_HOST como 127.0.0.1 e reinicie o Ollama. Se outros dispositivos precisarem de o usar, limite o acesso a um proxy inverso com autenticação ou a uma VPN."
  ],
  "zh-Hans": [
   "Ollama（本地 LLM 服务器）无需认证即可从网络访问",
   "此端口上有 Ollama 的 API 作出了响应。Ollama 没有认证机制，能通过网络访问到它的任何人都可以列出、下载、删除模型并运行推理，GPU 等计算资源可能被擅自使用，磁盘也可能被占满。默认只监听 127.0.0.1，但 OLLAMA_HOST=0.0.0.0 之类的设置使它可以从网络访问。",
   "请把 OLLAMA_HOST 改回 127.0.0.1 并重启 Ollama。如果其他设备需要使用，请将其限制在带认证的反向代理或 VPN 之内。"
  ],
  "zh-Hant": [
   "Ollama（本機 LLM 伺服器）無需驗證即可從網路存取",
   "此連接埠上有 Ollama 的 API 作出了回應。Ollama 沒有驗證機制，能透過網路存取到它的任何人都可以列出、下載、刪除模型並執行推論，GPU 等運算資源可能被擅自使用，磁碟也可能被占滿。預設只監聽 127.0.0.1，但 OLLAMA_HOST=0.0.0.0 之類的設定讓它可以從網路存取。",
   "請把 OLLAMA_HOST 改回 127.0.0.1 並重新啟動 Ollama。如果其他裝置需要使用，請將其限制在具驗證的反向代理或 VPN 之內。"
  ]
 },
 "signature:rdp-nla-missing": {
  "de": [
   "RDP erzwingt kein NLA",
   "Der RDP-Server verlangt weder TLS noch NLA (CredSSP). Große Teile des RDP-Protokolls sind vor der Authentifizierung erreichbar, und veraltete Verschlüsselung erlaubt Man-in-the-Middle-Angriffe – eine Angriffsfläche der BlueKeep-Klasse.",
   "Erzwingen Sie NLA und verwenden Sie die TLS-Sicherheitsschicht (bei xrdp security_layer in xrdp.ini auf negotiate oder tls setzen)."
  ],
  "en": [
   "RDP Does Not Enforce NLA",
   "The RDP server does not require TLS/NLA (CredSSP). Most of the RDP protocol is reachable before authentication, and legacy encryption allows man-in-the-middle attacks, forming a BlueKeep-class attack surface.",
   "Require NLA and use the TLS security layer (for xrdp, set security_layer to negotiate or tls in xrdp.ini)."
  ],
  "es": [
   "RDP no exige NLA",
   "El servidor RDP no exige TLS/NLA (CredSSP). Gran parte del protocolo RDP es accesible antes de autenticarse, y el cifrado heredado permite ataques de intermediario, lo que forma una superficie de ataque de la clase BlueKeep.",
   "Exige NLA y usa la capa de seguridad TLS (en xrdp, establece security_layer en negotiate o tls en xrdp.ini)."
  ],
  "fr": [
   "RDP n'impose pas NLA",
   "Le serveur RDP n'exige ni TLS ni NLA (CredSSP). Une grande partie du protocole RDP est accessible avant l'authentification, et le chiffrement hérité permet des attaques de l'homme du milieu, ce qui constitue une surface d'attaque de type BlueKeep.",
   "Exigez NLA et utilisez la couche de sécurité TLS (pour xrdp, définissez security_layer sur negotiate ou tls dans xrdp.ini)."
  ],
  "it": [
   "RDP non impone NLA",
   "Il server RDP non richiede TLS/NLA (CredSSP). Gran parte del protocollo RDP è raggiungibile prima dell'autenticazione e la cifratura legacy consente attacchi man-in-the-middle, formando una superficie d'attacco della classe BlueKeep.",
   "Richiedi NLA e usa il livello di sicurezza TLS (in xrdp, imposta security_layer su negotiate o tls in xrdp.ini)."
  ],
  "ja": [
   "RDP で NLA が強制されていません",
   "RDP サーバーが TLS/NLA（CredSSP）を必須にしていません。認証前に RDP プロトコルの大部分へ到達できるうえ、旧式の暗号方式では中間者攻撃も可能で、BlueKeep 型の攻撃面になります。",
   "NLA を必須にし、TLS のセキュリティレイヤーを使用してください（xrdp では xrdp.ini の security_layer を negotiate または tls に設定）。"
  ],
  "ko": [
   "RDP에서 NLA가 강제되지 않음",
   "RDP 서버가 TLS/NLA(CredSSP)를 필수로 요구하지 않습니다. 인증 전에 RDP 프로토콜 대부분에 접근할 수 있고 구형 암호화는 중간자 공격도 가능해 BlueKeep 유형의 공격 표면이 됩니다.",
   "NLA를 필수로 하고 TLS 보안 계층을 사용하세요(xrdp는 xrdp.ini의 security_layer를 negotiate 또는 tls로 설정)."
  ],
  "pt-PT": [
   "O RDP não impõe NLA",
   "O servidor RDP não exige TLS/NLA (CredSSP). Grande parte do protocolo RDP é acessível antes da autenticação, e a cifra legada permite ataques man-in-the-middle, formando uma superfície de ataque da classe BlueKeep.",
   "Exija NLA e use a camada de segurança TLS (no xrdp, defina security_layer como negotiate ou tls em xrdp.ini)."
  ],
  "zh-Hans": [
   "RDP 未强制使用 NLA",
   "RDP 服务器未强制要求 TLS/NLA（CredSSP）。在认证之前即可访问 RDP 协议的大部分功能，旧式加密还允许中间人攻击，构成 BlueKeep 类攻击面。",
   "请强制启用 NLA 并使用 TLS 安全层（xrdp 请在 xrdp.ini 中将 security_layer 设为 negotiate 或 tls）。"
  ],
  "zh-Hant": [
   "RDP 未強制使用 NLA",
   "RDP 伺服器未強制要求 TLS/NLA（CredSSP）。在驗證之前即可存取 RDP 協定的大部分功能，舊式加密還允許中間人攻擊，形成 BlueKeep 類攻擊面。",
   "請強制啟用 NLA 並使用 TLS 安全層（xrdp 請在 xrdp.ini 中將 security_layer 設為 negotiate 或 tls）。"
  ]
 },
 "signature:redis-default-noauth": {
  "de": [
   "Redis-Datenbank-Expositionsrisiko (nicht standardmäßiger Port)",
   "Redis akzeptiert standardmäßig unauthentifizierte Verbindungen, sofern bind / requirepass nicht explizit konfiguriert ist. Da es auf einem anderen Port als dem Standard 6379 lauscht, würde eine portnummernbasierte Erkennung es übersehen.",
   "Legen Sie in redis.conf bind 127.0.0.1 und requirepass fest."
  ],
  "en": [
   "Redis Database Exposure Risk (Non-Standard Port)",
   "Redis accepts unauthenticated connections by default unless bind / requirepass is explicitly configured. It's listening on a port other than the standard 6379, so port-number-based detection would miss it.",
   "Set bind 127.0.0.1 and requirepass in redis.conf."
  ],
  "es": [
   "Riesgo de exposición de la base de datos Redis (puerto no estándar)",
   "Redis acepta conexiones no autenticadas de forma predeterminada a menos que se configure explícitamente bind / requirepass. Como escucha en un puerto distinto del estándar 6379, la detección basada en el número de puerto no lo detectaría.",
   "Configura bind 127.0.0.1 y requirepass en redis.conf."
  ],
  "fr": [
   "Risque d'exposition de la base de données Redis (port non standard)",
   "Redis accepte les connexions non authentifiées par défaut, sauf si bind / requirepass est explicitement configuré. Comme il écoute sur un port autre que le port standard 6379, une détection basée sur le numéro de port le manquerait.",
   "Définissez bind 127.0.0.1 et requirepass dans redis.conf."
  ],
  "it": [
   "Rischio di esposizione del database Redis (porta non standard)",
   "Redis accetta connessioni non autenticate per impostazione predefinita a meno che bind / requirepass non sia configurato esplicitamente. Poiché è in ascolto su una porta diversa dalla standard 6379, il rilevamento basato sul numero di porta non lo individuerebbe.",
   "Imposta bind 127.0.0.1 e requirepass in redis.conf."
  ],
  "ja": [
   "Redis データベース露出リスク（非標準ポート）",
   "Redisは bind / requirepass を明示的に設定しない限り、既定で認証なしに接続を受け付けます。標準の6379以外のポートで待ち受けているため、ポート番号ベースの検知では見逃されます。",
   "redis.conf で bind 127.0.0.1 および requirepass を設定してください。"
  ],
  "ko": [
   "Redis 데이터베이스 노출 위험 (비표준 포트)",
   "Redis는 bind / requirepass를 명시적으로 설정하지 않으면 기본적으로 인증 없이 연결을 허용합니다. 표준 포트인 6379가 아닌 포트에서 대기 중이므로 포트 번호 기반 탐지로는 발견되지 않습니다.",
   "redis.conf에서 bind 127.0.0.1 및 requirepass를 설정하세요."
  ],
  "pt-PT": [
   "Risco de exposição da base de dados Redis (porta não padrão)",
   "O Redis aceita ligações não autenticadas por predefinição, a menos que bind / requirepass seja explicitamente configurado. Como está à escuta numa porta diferente da porta padrão 6379, a deteção baseada no número da porta não o detetaria.",
   "Defina bind 127.0.0.1 e requirepass no redis.conf."
  ],
  "zh-Hans": [
   "Redis 数据库暴露风险（非标准端口）",
   "除非明确设置 bind / requirepass，否则 Redis 默认接受无认证连接。由于它监听在标准 6379 以外的端口，基于端口号的检测无法发现它。",
   "请在 redis.conf 中设置 bind 127.0.0.1 和 requirepass。"
  ],
  "zh-Hant": [
   "Redis 資料庫暴露風險（非標準連接埠）",
   "除非明確設定 bind / requirepass，否則 Redis 預設接受無驗證連線。由於它監聽在標準 6379 以外的連接埠，基於連接埠號碼的偵測無法發現它。",
   "請在 redis.conf 中設定 bind 127.0.0.1 及 requirepass。"
  ]
 },
 "signature:smb-signing-not-required": {
  "de": [
   "SMB-Signierung ist nicht erforderlich",
   "Die SMB2+-Nachrichtensignierung ist nicht erforderlich. Ein Angreifer im selben LAN kann Authentifizierungen per NTLM-Relay an diesen Host weiterleiten und einen Benutzer imitieren.",
   "Erzwingen Sie die SMB-Signierung (bei Samba server signing = mandatory setzen)."
  ],
  "en": [
   "SMB Signing Is Not Required",
   "SMB2+ message signing is not required. An attacker on the same LAN can relay authentication to this host (NTLM relay) and impersonate a user.",
   "Require SMB signing (for Samba, set server signing = mandatory)."
  ],
  "es": [
   "La firma SMB no es obligatoria",
   "La firma de mensajes SMB2+ no es obligatoria. Un atacante en la misma LAN puede retransmitir la autenticación a este host (NTLM relay) y suplantar a un usuario.",
   "Exige la firma SMB (en Samba, establece server signing = mandatory)."
  ],
  "fr": [
   "La signature SMB n'est pas obligatoire",
   "La signature des messages SMB2+ n'est pas obligatoire. Un attaquant sur le même réseau local peut relayer l'authentification vers cet hôte (relais NTLM) et usurper un utilisateur.",
   "Exigez la signature SMB (pour Samba, définissez server signing = mandatory)."
  ],
  "it": [
   "La firma SMB non è obbligatoria",
   "La firma dei messaggi SMB2+ non è obbligatoria. Un attaccante nella stessa LAN può inoltrare l'autenticazione a questo host (NTLM relay) e impersonare un utente.",
   "Richiedi la firma SMB (in Samba, imposta server signing = mandatory)."
  ],
  "ja": [
   "SMB 署名が必須ではありません",
   "SMB2 以降で通信の署名が必須になっていません。同じLAN上の攻撃者が認証を中継する NTLM リレー攻撃で、このホストになりすませます。",
   "SMB 署名を必須にしてください（Samba では server signing = mandatory）。"
  ],
  "ko": [
   "SMB 서명이 필수가 아님",
   "SMB2 이상에서 메시지 서명이 필수가 아닙니다. 같은 LAN의 공격자가 NTLM 릴레이 공격으로 인증을 이 호스트에 중계해 사용자를 가장할 수 있습니다.",
   "SMB 서명을 필수로 하세요(Samba는 server signing = mandatory 설정)."
  ],
  "pt-PT": [
   "A assinatura SMB não é obrigatória",
   "A assinatura de mensagens SMB2+ não é obrigatória. Um atacante na mesma LAN pode retransmitir a autenticação para este anfitrião (NTLM relay) e fazer-se passar por um utilizador.",
   "Exija a assinatura SMB (no Samba, defina server signing = mandatory)."
  ],
  "zh-Hans": [
   "SMB 签名未被强制要求",
   "SMB2 及以上版本未强制要求消息签名。同一局域网内的攻击者可通过 NTLM 中继攻击将认证转发到此主机并冒充用户。",
   "请强制启用 SMB 签名（Samba 请设置 server signing = mandatory）。"
  ],
  "zh-Hant": [
   "SMB 簽章未被強制要求",
   "SMB2 及以上版本未強制要求訊息簽章。同一區域網路內的攻擊者可透過 NTLM 中繼攻擊將驗證轉送到此主機並冒充使用者。",
   "請強制啟用 SMB 簽章（Samba 請設定 server signing = mandatory）。"
  ]
 },
 "signature:smb1-enabled": {
  "de": [
   "SMBv1 ist aktiviert",
   "Der Server hat eine SMB-Negotiate-Anfrage mit einem SMBv1-Header beantwortet. SMBv1 ist das Protokoll, auf das Angriffe der EternalBlue/WannaCry-Klasse (MS17-010) zielen, und gilt seit 2017 als veraltet.",
   "Deaktivieren Sie SMBv1 (bei Samba min protocol = SMB2 in smb.conf setzen)."
  ],
  "en": [
   "SMBv1 Is Enabled",
   "The server answered an SMB negotiate request with an SMBv1 header. SMBv1 is the protocol targeted by EternalBlue/WannaCry-class attacks (MS17-010) and has been deprecated since 2017.",
   "Disable SMBv1 (for Samba, set min protocol = SMB2 in smb.conf)."
  ],
  "es": [
   "SMBv1 está habilitado",
   "El servidor respondió a una solicitud de negociación SMB con una cabecera SMBv1. SMBv1 es el protocolo objetivo de los ataques de la clase EternalBlue/WannaCry (MS17-010) y está obsoleto desde 2017.",
   "Deshabilita SMBv1 (en Samba, establece min protocol = SMB2 en smb.conf)."
  ],
  "fr": [
   "SMBv1 est activé",
   "Le serveur a répondu à une requête de négociation SMB avec un en-tête SMBv1. SMBv1 est le protocole visé par les attaques de type EternalBlue/WannaCry (MS17-010) et est obsolète depuis 2017.",
   "Désactivez SMBv1 (pour Samba, définissez min protocol = SMB2 dans smb.conf)."
  ],
  "it": [
   "SMBv1 è abilitato",
   "Il server ha risposto a una richiesta di negoziazione SMB con un'intestazione SMBv1. SMBv1 è il protocollo preso di mira dagli attacchi della classe EternalBlue/WannaCry (MS17-010) ed è deprecato dal 2017.",
   "Disabilita SMBv1 (in Samba, imposta min protocol = SMB2 in smb.conf)."
  ],
  "ja": [
   "SMBv1 が有効です",
   "SMB のネゴシエート要求に SMBv1 ヘッダーで応答しました。SMBv1 は EternalBlue/WannaCry 型攻撃（MS17-010）の標的となったプロトコルで、2017年から非推奨です。",
   "SMBv1 を無効化してください（Samba では smb.conf に min protocol = SMB2 を設定）。"
  ],
  "ko": [
   "SMBv1이 활성화되어 있음",
   "서버가 SMB 협상 요청에 SMBv1 헤더로 응답했습니다. SMBv1은 EternalBlue/WannaCry 유형 공격(MS17-010)의 표적이 된 프로토콜로 2017년부터 사용이 권장되지 않습니다.",
   "SMBv1을 비활성화하세요(Samba는 smb.conf에 min protocol = SMB2 설정)."
  ],
  "pt-PT": [
   "O SMBv1 está ativado",
   "O servidor respondeu a um pedido de negociação SMB com um cabeçalho SMBv1. O SMBv1 é o protocolo visado por ataques da classe EternalBlue/WannaCry (MS17-010) e está obsoleto desde 2017.",
   "Desative o SMBv1 (no Samba, defina min protocol = SMB2 em smb.conf)."
  ],
  "zh-Hans": [
   "SMBv1 已启用",
   "服务器以 SMBv1 报文头响应了 SMB 协商请求。SMBv1 是 EternalBlue/WannaCry 类攻击（MS17-010）所针对的协议，自 2017 年起已不推荐使用。",
   "请禁用 SMBv1（Samba 请在 smb.conf 中设置 min protocol = SMB2）。"
  ],
  "zh-Hant": [
   "SMBv1 已啟用",
   "伺服器以 SMBv1 標頭回應了 SMB 協商請求。SMBv1 是 EternalBlue/WannaCry 類攻擊（MS17-010）所針對的協定，自 2017 年起已不建議使用。",
   "請停用 SMBv1（Samba 請在 smb.conf 中設定 min protocol = SMB2）。"
  ]
 },
 "signature:smtp-open-relay": {
  "de": [
   "Offener SMTP-Relay",
   "Dieser SMTP-Server leitet E-Mails für einen nicht authentifizierten, unbeteiligten Dritten weiter. Er kann als Spam-Relay missbraucht werden, was in der Regel dazu führt, dass die IP-Adresse des Servers auf eine Blacklist gesetzt wird.",
   "Erfordern Sie eine SMTP-Authentifizierung (SMTP AUTH) oder beschränken Sie explizit, welche Absender weiterleiten dürfen."
  ],
  "en": [
   "SMTP Open Relay",
   "This SMTP server relays mail for an unauthenticated, unrelated third party. It can be abused as a spam relay, which typically gets the server's IP address blacklisted.",
   "Require SMTP authentication (SMTP AUTH), or explicitly restrict which senders are allowed to relay."
  ],
  "es": [
   "Retransmisión SMTP abierta",
   "Este servidor SMTP retransmite correo para un tercero no autenticado y no relacionado. Puede ser utilizado indebidamente como relé de spam, lo que suele hacer que la IP del servidor acabe en listas negras.",
   "Exija autenticación SMTP (SMTP AUTH) o restrinja explícitamente qué remitentes pueden retransmitir."
  ],
  "fr": [
   "Relais SMTP ouvert",
   "Ce serveur SMTP relaie le courrier pour un tiers non authentifié et sans rapport. Il peut être détourné comme relais de spam, ce qui entraîne généralement le blacklistage de l'adresse IP du serveur.",
   "Exigez l'authentification SMTP (SMTP AUTH), ou limitez explicitement les expéditeurs autorisés à relayer."
  ],
  "it": [
   "Relay SMTP aperto",
   "Questo server SMTP inoltra la posta per una terza parte non autenticata e non correlata. Può essere sfruttato come relay per spam, il che in genere porta all'inserimento dell'IP del server in una blacklist.",
   "Richiedi l'autenticazione SMTP (SMTP AUTH) oppure limita esplicitamente quali mittenti possono effettuare il relay."
  ],
  "ja": [
   "SMTPオープンリレー",
   "このSMTPサーバーは、認証なしで無関係な第三者宛のメールを中継（リレー）してしまいます。スパム送信の踏み台として悪用され、サーバーのIPアドレスがブラックリストに登録される原因になります。",
   "SMTP認証(SMTP AUTH)を必須化するか、中継を許可する送信元を明示的に制限してください。"
  ],
  "ko": [
   "SMTP 오픈 릴레이",
   "이 SMTP 서버는 인증 없이 관련 없는 제3자에게 메일을 중계합니다. 스팸 릴레이로 악용될 수 있으며, 일반적으로 서버 IP가 블랙리스트에 등록되는 원인이 됩니다.",
   "SMTP 인증(SMTP AUTH)을 필수로 설정하거나, 릴레이를 허용할 발신자를 명시적으로 제한하세요."
  ],
  "pt-PT": [
   "Retransmissão SMTP aberta",
   "Este servidor SMTP retransmite correio para terceiros não autenticados e não relacionados. Pode ser explorado como retransmissor de spam, o que normalmente leva à inclusão do IP do servidor em listas negras.",
   "Exija autenticação SMTP (SMTP AUTH) ou restrinja explicitamente que remetentes podem retransmitir."
  ],
  "zh-Hans": [
   "SMTP 开放中继",
   "此 SMTP 服务器允许在未经身份验证的情况下为无关第三方转发邮件。这可能被滥用为垃圾邮件中转站，导致服务器 IP 被列入黑名单。",
   "请启用强制 SMTP 身份验证 (SMTP AUTH)，或明确限制允许中继的发送方。"
  ],
  "zh-Hant": [
   "SMTP 開放中繼",
   "此 SMTP 伺服器允許在未經身分驗證的情況下為無關第三方轉發郵件。這可能被濫用為垃圾郵件中繼站，導致伺服器 IP 被列入黑名單。",
   "請啟用強制 SMTP 身分驗證 (SMTP AUTH)，或明確限制允許中繼的發送方。"
  ]
 },
 "signature:ssh-banner-exposed": {
  "de": [
   "SSH-Versionsbanner offengelegt",
   "Dieser SSH-Server gibt beim Verbindungsaufbau sein Versionsbanner preis. Das Banner selbst ist normales SSH-Verhalten, gibt einem Angreifer aber einen Ausgangspunkt, um bekannte Schwachstellen dieser Version nachzuschlagen.",
   "Halten Sie SSH auf dem neuesten Stand und minimieren Sie nach Möglichkeit den Detailgrad des Banners."
  ],
  "en": [
   "SSH Version Banner Disclosed",
   "This SSH server discloses its version banner on connect. This is normal SSH behavior, but the banner gives an attacker a starting point to look up known vulnerabilities for that version.",
   "Keep SSH updated to the latest version, and minimize the banner's detail if your SSH implementation allows it."
  ],
  "es": [
   "Banner de versión SSH divulgado",
   "Este servidor SSH revela su banner de versión al conectarse. El banner en sí es un comportamiento normal de SSH, pero le da a un atacante un punto de partida para buscar vulnerabilidades conocidas de esa versión.",
   "Mantenga SSH actualizado a la última versión y, si es posible, minimice el detalle del banner."
  ],
  "fr": [
   "Bannière de version SSH divulguée",
   "Ce serveur SSH divulgue sa bannière de version lors de la connexion. La bannière elle-même est un comportement SSH normal, mais elle donne à un attaquant un point de départ pour rechercher les vulnérabilités connues de cette version.",
   "Maintenez SSH à jour et réduisez si possible le niveau de détail de la bannière."
  ],
  "it": [
   "Banner di versione SSH esposto",
   "Questo server SSH espone il proprio banner di versione alla connessione. Il banner in sé è un comportamento normale di SSH, ma fornisce a un utente malintenzionato un punto di partenza per cercare vulnerabilità note di quella versione.",
   "Mantieni SSH aggiornato all'ultima versione e, se possibile, riduci al minimo il dettaglio del banner."
  ],
  "ja": [
   "SSH バージョンバナー公開",
   "このSSHサーバーは接続時にバージョンバナーを公開しています。バナー自体は正常な動作ですが、攻撃者が既知の脆弱性を絞り込む手がかりになります。",
   "SSHを最新版に更新し、必要に応じてバナーの内容を最小化してください。"
  ],
  "ko": [
   "SSH 버전 배너 노출",
   "이 SSH 서버는 연결 시 버전 배너를 노출합니다. 배너 자체는 정상적인 동작이지만, 공격자가 해당 버전의 알려진 취약점을 조사하는 단서가 될 수 있습니다.",
   "SSH를 최신 버전으로 유지하고, 가능하다면 배너 내용을 최소화하세요."
  ],
  "pt-PT": [
   "Banner de versão SSH divulgado",
   "Este servidor SSH divulga o seu banner de versão ao ligar. O banner em si é um comportamento normal do SSH, mas dá a um atacante um ponto de partida para procurar vulnerabilidades conhecidas dessa versão.",
   "Mantenha o SSH atualizado para a versão mais recente e, se possível, minimize o detalhe do banner."
  ],
  "zh-Hans": [
   "SSH 版本横幅已公开",
   "此 SSH 服务器在连接时会公开其版本横幅。横幅本身是正常行为，但会为攻击者提供查找该版本已知漏洞的线索。",
   "请将 SSH 保持更新到最新版本，如实现支持，可考虑精简横幅内容。"
  ],
  "zh-Hant": [
   "SSH 版本橫幅已公開",
   "此 SSH 伺服器在連線時會公開其版本橫幅。橫幅本身是正常行為，但會為攻擊者提供查找該版本已知弱點的線索。",
   "請將 SSH 保持更新至最新版本，如實作支援，可考慮精簡橫幅內容。"
  ]
 },
 "signature:telnet-exposed": {
  "de": [
   "Telnet-Klartext-Risiko",
   "Telnet überträgt sämtlichen Datenverkehr, einschließlich Anmeldedaten, unverschlüsselt im Klartext. Allein die Erreichbarkeit bedeutet bereits ein Risiko für das Abhören von Zugangsdaten und Man-in-the-Middle-Angriffe.",
   "Deaktivieren Sie Telnet und wechseln Sie zu einer verschlüsselten Alternative wie SSH."
  ],
  "en": [
   "Telnet Plaintext Exposure Risk",
   "Telnet transmits all traffic, including login credentials, unencrypted. Being reachable at all already means a risk of credential eavesdropping and man-in-the-middle attacks.",
   "Disable Telnet and switch to an encrypted alternative such as SSH."
  ],
  "es": [
   "Riesgo de comunicación en texto plano de Telnet",
   "Telnet transmite todo el tráfico, incluidas las credenciales de inicio de sesión, sin cifrar. El mero hecho de ser alcanzable ya implica un riesgo de interceptación de credenciales y ataques de intermediario.",
   "Deshabilite Telnet y cambie a una alternativa cifrada como SSH."
  ],
  "fr": [
   "Risque de communication en clair Telnet",
   "Telnet transmet tout le trafic, y compris les identifiants de connexion, en clair et non chiffré. Le simple fait d'être joignable représente déjà un risque d'interception des identifiants et d'attaque de l'homme du milieu.",
   "Désactivez Telnet et passez à une alternative chiffrée telle que SSH."
  ],
  "it": [
   "Rischio di comunicazione in chiaro Telnet",
   "Telnet trasmette tutto il traffico, incluse le credenziali di accesso, in chiaro e non cifrato. La sola raggiungibilità comporta già un rischio di intercettazione delle credenziali e attacchi man-in-the-middle.",
   "Disabilita Telnet e passa a un'alternativa cifrata come SSH."
  ],
  "ja": [
   "Telnet 平文通信リスク",
   "Telnetはすべての通信（ログイン情報を含む）を暗号化せず平文で送信します。到達可能な状態自体が、認証情報の盗聴・中間者攻撃のリスクを意味します。",
   "Telnetを無効化し、SSHなど暗号化された代替手段に切り替えてください。"
  ],
  "ko": [
   "Telnet 평문 통신 위험",
   "Telnet은 로그인 자격 증명을 포함한 모든 통신을 암호화하지 않고 평문으로 전송합니다. 도달 가능하다는 사실 자체가 자격 증명 도청 및 중간자 공격의 위험을 의미합니다.",
   "Telnet을 비활성화하고 SSH 등 암호화된 대안으로 전환하세요."
  ],
  "pt-PT": [
   "Risco de comunicação em texto simples Telnet",
   "O Telnet transmite todo o tráfego, incluindo credenciais de início de sessão, sem encriptação. O simples facto de estar acessível já representa um risco de interceção de credenciais e ataques man-in-the-middle.",
   "Desative o Telnet e mude para uma alternativa encriptada, como o SSH."
  ],
  "zh-Hans": [
   "Telnet 明文通信风险",
   "Telnet 以明文方式传输所有通信内容（包括登录凭据）。仅仅可达本身就意味着凭据窃听和中间人攻击的风险。",
   "请禁用 Telnet，改用 SSH 等加密方案。"
  ],
  "zh-Hant": [
   "Telnet 明文通訊風險",
   "Telnet 以明文方式傳輸所有通訊內容（包括登入憑證）。僅僅可達本身就意味著憑證竊聽和中間人攻擊的風險。",
   "請停用 Telnet，改用 SSH 等加密方案。"
  ]
 },
 "signature:vnc-noauth": {
  "de": [
   "VNC: Zugriff ohne Authentifizierung",
   "Der VNC-Server bietet „None“ als Sicherheitstyp an. Jeder, der ihn erreicht, kann diesen Bildschirm ohne Passwort ansehen und steuern.",
   "Erzwingen Sie die VNC-Passwortauthentifizierung oder beschränken Sie den Zugriff auf einen SSH-Tunnel, und geben Sie den Port nicht nach außen frei."
  ],
  "en": [
   "VNC Unauthenticated Exposure Risk",
   "The VNC server offered \"None\" as a security type. Anyone who can reach it can view and control this screen without a password.",
   "Require VNC password authentication, or restrict access to an SSH tunnel, and do not expose the port externally."
  ],
  "es": [
   "Riesgo de exposición de VNC sin autenticación",
   "El servidor VNC ofreció «None» como tipo de seguridad. Cualquiera que pueda alcanzarlo puede ver y controlar esta pantalla sin contraseña.",
   "Exige la autenticación por contraseña de VNC, o limita el acceso a un túnel SSH, y no expongas el puerto al exterior."
  ],
  "fr": [
   "Risque d'exposition de VNC sans authentification",
   "Le serveur VNC a proposé « None » comme type de sécurité. Toute personne pouvant l'atteindre peut voir et contrôler cet écran sans mot de passe.",
   "Exigez l'authentification par mot de passe VNC, ou limitez l'accès à un tunnel SSH, et n'exposez pas le port à l'extérieur."
  ],
  "it": [
   "Rischio di esposizione di VNC senza autenticazione",
   "Il server VNC ha offerto «None» come tipo di sicurezza. Chiunque possa raggiungerlo può vedere e controllare questo schermo senza password.",
   "Richiedi l'autenticazione con password VNC, oppure limita l'accesso a un tunnel SSH, e non esporre la porta all'esterno."
  ],
  "ja": [
   "VNC 認証なし公開リスク",
   "VNC サーバーが認証方式として「なし（None）」を受け付けました。到達できる相手は誰でも、パスワードなしでこの画面を閲覧・操作できます。",
   "VNC のパスワード認証を必須にするか、SSH トンネル経由に限定して、ポートを外部へ公開しないでください。"
  ],
  "ko": [
   "VNC 인증 없는 노출 위험",
   "VNC 서버가 인증 방식으로 '없음(None)'을 제시했습니다. 접근할 수 있는 사람은 누구나 비밀번호 없이 이 화면을 보고 조작할 수 있습니다.",
   "VNC 비밀번호 인증을 필수로 하거나 SSH 터널로만 접근하도록 제한하고 포트를 외부에 노출하지 마세요."
  ],
  "pt-PT": [
   "Risco de exposição do VNC sem autenticação",
   "O servidor VNC ofereceu «None» como tipo de segurança. Qualquer pessoa que o consiga alcançar pode ver e controlar este ecrã sem palavra-passe.",
   "Exija autenticação por palavra-passe do VNC, ou limite o acesso a um túnel SSH, e não exponha a porta ao exterior."
  ],
  "zh-Hans": [
   "VNC 未认证暴露风险",
   "VNC 服务器提供了「无（None）」作为认证方式。任何能够访问它的人无需密码即可查看和操作此屏幕。",
   "请强制启用 VNC 密码认证，或仅允许通过 SSH 隧道访问，且不要将端口暴露到外部。"
  ],
  "zh-Hant": [
   "VNC 未驗證暴露風險",
   "VNC 伺服器提供了「無（None）」作為驗證方式。任何能夠連線的人都無需密碼即可檢視並操作此畫面。",
   "請強制啟用 VNC 密碼驗證，或僅允許透過 SSH 通道存取，且不要將連接埠對外開放。"
  ]
 },
 "web:webvuln-cors": {
  "de": [
   "CORS-Fehlkonfiguration (Cross-Origin mit Anmeldedaten erlaubt)",
   "Das Senden eines beliebigen Origin-Headers führte dazu, dass dieser in Access-Control-Allow-Origin gespiegelt wurde (oder ein Platzhalter * zurückkam), zusammen mit Access-Control-Allow-Credentials: true. Diese Kombination ermöglicht es einer bösartigen Website, über den Browser eines Opfers authentifizierte Anfragen an diesen Server zu senden und die Antwort zu lesen.",
   "Beschränken Sie Access-Control-Allow-Origin auf eine spezifische, vertrauenswürdige Liste von Ursprüngen, und aktivieren Sie Access-Control-Allow-Credentials nur, wenn es wirklich erforderlich ist."
  ],
  "en": [
   "CORS Misconfiguration (Cross-Origin Allowed with Credentials)",
   "Sending an arbitrary Origin header caused it to be reflected in Access-Control-Allow-Origin (or answered with a wildcard *), together with Access-Control-Allow-Credentials: true. This combination lets a malicious website send authenticated requests to this server through a victim's browser and read the response.",
   "Restrict Access-Control-Allow-Origin to a specific, trusted allow-list of origins, and only enable Access-Control-Allow-Credentials when it's genuinely required."
  ],
  "es": [
   "Configuración CORS incorrecta (origen cruzado permitido con credenciales)",
   "El envío de un encabezado Origin arbitrario provocó que se reflejara en Access-Control-Allow-Origin (o se respondiera con un comodín *), junto con Access-Control-Allow-Credentials: true. Esta combinación permite que un sitio malicioso envíe solicitudes autenticadas a este servidor a través del navegador de una víctima y lea la respuesta.",
   "Restringe Access-Control-Allow-Origin a una lista específica de orígenes de confianza, y habilita Access-Control-Allow-Credentials solo cuando sea realmente necesario."
  ],
  "fr": [
   "Mauvaise configuration CORS (origine croisée autorisée avec identifiants)",
   "L'envoi d'un en-tête Origin arbitraire a été reflété dans Access-Control-Allow-Origin (ou a reçu un caractère générique *), avec Access-Control-Allow-Credentials: true. Cette combinaison permet à un site malveillant d'envoyer des requêtes authentifiées à ce serveur via le navigateur d'une victime et de lire la réponse.",
   "Limitez Access-Control-Allow-Origin à une liste précise d'origines de confiance, et n'activez Access-Control-Allow-Credentials que si c'est réellement nécessaire."
  ],
  "it": [
   "Configurazione CORS errata (origine incrociata consentita con credenziali)",
   "L'invio di un'intestazione Origin arbitraria ha fatto sì che venisse riflessa in Access-Control-Allow-Origin (oppure sia stato restituito un carattere jolly *), insieme ad Access-Control-Allow-Credentials: true. Questa combinazione consente a un sito dannoso di inviare richieste autenticate a questo server tramite il browser di una vittima e di leggerne la risposta.",
   "Limita Access-Control-Allow-Origin a un elenco specifico di origini attendibili e abilita Access-Control-Allow-Credentials solo quando è davvero necessario."
  ],
  "ja": [
   "CORS 設定ミス（認証情報付きクロスオリジン許可）",
   "任意のOriginヘッダを送信したところ、そのOriginがAccess-Control-Allow-Originに反映（または*が返却）され、かつAccess-Control-Allow-Credentials: trueが同時に返されました。この組み合わせは、悪意あるWebサイトが被害者のブラウザ経由でこのサーバーへ認証済みリクエストを送信し、レスポンスを読み取れることを意味します。",
   "Access-Control-Allow-Origin を信頼できる特定のオリジンのみに限定し、Access-Control-Allow-Credentials は本当に必要な場合のみ有効にしてください。"
  ],
  "ko": [
   "CORS 설정 오류(자격 증명 포함 크로스 오리진 허용)",
   "임의의 Origin 헤더를 전송했더니 해당 Origin이 Access-Control-Allow-Origin에 반영되거나(또는 와일드카드 *가 반환됨) Access-Control-Allow-Credentials: true가 함께 반환되었습니다. 이 조합은 악의적인 웹사이트가 피해자의 브라우저를 통해 이 서버로 인증된 요청을 보내고 응답을 읽을 수 있음을 의미합니다.",
   "Access-Control-Allow-Origin을 신뢰할 수 있는 특정 오리진 목록으로 제한하고, Access-Control-Allow-Credentials는 정말 필요한 경우에만 활성화하세요."
  ],
  "pt-PT": [
   "Configuração CORS incorreta (origem cruzada permitida com credenciais)",
   "O envio de um cabeçalho Origin arbitrário fez com que este fosse refletido em Access-Control-Allow-Origin (ou tenha sido respondido com um curinga *), juntamente com Access-Control-Allow-Credentials: true. Esta combinação permite que um site malicioso envie pedidos autenticados a este servidor através do navegador de uma vítima e leia a resposta.",
   "Restrinja o Access-Control-Allow-Origin a uma lista específica de origens fiáveis e ative o Access-Control-Allow-Credentials apenas quando for realmente necessário."
  ],
  "zh-Hans": [
   "CORS 配置错误（允许带凭据的跨域请求）",
   "发送任意 Origin 头后，该 Origin 被反射在 Access-Control-Allow-Origin 中（或返回通配符 *），并同时返回 Access-Control-Allow-Credentials: true。此组合意味着恶意网站可通过受害者浏览器向此服务器发送已认证请求并读取响应。",
   "请将 Access-Control-Allow-Origin 限定为可信的特定来源列表，仅在确实需要时启用 Access-Control-Allow-Credentials。"
  ],
  "zh-Hant": [
   "CORS 設定錯誤（允許帶憑證的跨網域請求）",
   "傳送任意 Origin 標頭後，該 Origin 被反射在 Access-Control-Allow-Origin 中（或回傳萬用字元 *），並同時回傳 Access-Control-Allow-Credentials: true。此組合意味著惡意網站可透過受害者瀏覽器向此伺服器傳送已驗證請求並讀取回應。",
   "請將 Access-Control-Allow-Origin 限定為可信的特定來源清單，僅在確實需要時啟用 Access-Control-Allow-Credentials。"
  ]
 },
 "web:webvuln-redirect": {
  "de": [
   "Offene Weiterleitung (unvalidierte externe Weiterleitung)",
   "Die Angabe einer externen Domain in einem bekannten Weiterleitungsparameter (redirect/url/next usw.) führte ohne jegliche Validierung zu einer Weiterleitung auf diese Domain. Dies kann bei Phishing-Angriffen missbraucht werden, die eine bösartige Website hinter einer scheinbar legitimen URL verbergen.",
   "Validieren Sie die Weiterleitungs-Ziel-URL anhand einer Positivliste (nur gleicher Ursprung oder vertrauenswürdige Domains)."
  ],
  "en": [
   "Open Redirect (Unvalidated External Redirect)",
   "Specifying an external domain in a known redirect parameter (redirect/url/next, etc.) caused a redirect to that domain without any validation. This can be abused in phishing attacks that disguise a malicious site behind what looks like a legitimate site's URL.",
   "Validate the redirect target URL against an allow-list (same origin or trusted domains only)."
  ],
  "es": [
   "Redirección abierta (redirección externa no validada)",
   "Especificar un dominio externo en un parámetro de redirección conocido (redirect/url/next, etc.) provocó una redirección a ese dominio sin ninguna validación. Esto puede explotarse en ataques de phishing que ocultan un sitio malicioso tras una URL que parece legítima.",
   "Valida la URL de destino de la redirección mediante una lista de permitidos (solo el mismo origen o dominios de confianza)."
  ],
  "fr": [
   "Redirection ouverte (redirection externe non validée)",
   "L'indication d'un domaine externe dans un paramètre de redirection connu (redirect/url/next, etc.) a provoqué une redirection vers ce domaine sans aucune validation. Cela peut être exploité dans des attaques de phishing dissimulant un site malveillant derrière une URL qui semble légitime.",
   "Validez l'URL de destination de la redirection à l'aide d'une liste blanche (même origine ou domaines de confiance uniquement)."
  ],
  "it": [
   "Reindirizzamento aperto (reindirizzamento esterno non convalidato)",
   "Specificando un dominio esterno in un parametro di reindirizzamento noto (redirect/url/next, ecc.) si è verificato un reindirizzamento a quel dominio senza alcuna convalida. Questo può essere sfruttato in attacchi di phishing che nascondono un sito dannoso dietro un URL apparentemente legittimo.",
   "Convalida l'URL di destinazione del reindirizzamento tramite una lista consentita (solo stessa origine o domini attendibili)."
  ],
  "ja": [
   "オープンリダイレクト（未検証の外部リダイレクト）",
   "既知のリダイレクトパラメータ（redirect/url/next 等）に外部ドメインを指定したところ、検証なしにそのドメインへリダイレクトされました。フィッシング詐欺で正規サイトのURLを装いつつ悪意あるサイトへ誘導する手口に悪用される危険があります。",
   "リダイレクト先URLを許可リスト（同一オリジンまたは信頼済みドメインのみ）で検証してください。"
  ],
  "ko": [
   "오픈 리다이렉트(검증되지 않은 외부 리다이렉트)",
   "알려진 리다이렉트 파라미터(redirect/url/next 등)에 외부 도메인을 지정했더니 검증 없이 해당 도메인으로 리다이렉트되었습니다. 정상 사이트의 URL처럼 위장하면서 악성 사이트로 유도하는 피싱 공격에 악용될 위험이 있습니다.",
   "리다이렉트 대상 URL을 허용 목록(동일 오리진 또는 신뢰할 수 있는 도메인만)으로 검증하세요."
  ],
  "pt-PT": [
   "Redirecionamento aberto (redirecionamento externo não validado)",
   "Especificar um domínio externo num parâmetro de redirecionamento conhecido (redirect/url/next, etc.) provocou um redirecionamento para esse domínio sem qualquer validação. Isto pode ser explorado em ataques de phishing que disfarçam um site malicioso atrás de um URL aparentemente legítimo.",
   "Valide o URL de destino do redirecionamento através de uma lista de permissões (apenas a mesma origem ou domínios fiáveis)."
  ],
  "zh-Hans": [
   "开放重定向（未验证的外部重定向）",
   "在已知的重定向参数（redirect/url/next 等）中指定外部域名后，未经任何验证即被重定向到该域名。此漏洞可能被用于钓鱼攻击，伪装成正规网站的 URL 从而诱导用户访问恶意网站。",
   "请使用允许列表（仅限同源或可信域名）验证重定向目标 URL。"
  ],
  "zh-Hant": [
   "開放重新導向（未驗證的外部重新導向）",
   "在已知的重新導向參數（redirect/url/next 等）中指定外部網域後，未經任何驗證即被重新導向至該網域。此漏洞可能被用於釣魚攻擊，偽裝成正規網站的 URL 從而誘導使用者造訪惡意網站。",
   "請使用允許清單（僅限同源或可信網域）驗證重新導向目標 URL。"
  ]
 },
 "web:webvuln-ssrf": {
  "de": [
   "SSRF (Server ruft eine vom Angreifer vorgegebene URL ab)",
   "Als eine URL, die auf einen Listener auf diesem Rechner zeigt, in einem Parameter übergeben wurde, der üblicherweise eine URL aufnimmt (url/uri/src/image/target usw.), hat der Server sich tatsächlich damit verbunden. Der Server ruft übergebene URLs ab, ohne zu prüfen, ob sie auf Adressen dieses Rechners zeigen. Ein Angreifer kann ihn so interne Dienste und die Cloud-Metadaten-Adresse (169.254.169.254) erreichen lassen und dort Zugangsdaten auslesen. Beobachtet wurde auch, dass Angreifer die URL ihres eigenen Servers übergeben, der mit einer Weiterleitung (302) auf eine interne Adresse antwortet, womit eine Prüfung umgangen wird, die nur die erste URL betrachtet.",
   "Erlauben Sie nur die Ziele, die die Funktion braucht (Positivliste). Lösen Sie den Hostnamen selbst auf und weisen Sie nach der Auflösung Loopback-, private und Link-Local-Adressen (einschließlich 169.254.169.254) ab. Folgen Sie Weiterleitungen entweder gar nicht oder prüfen Sie jedes Weiterleitungsziel genauso. Auf Cloud-Servern sollten Sie außerdem für den Metadatendienst IMDSv2 (Token erforderlich) verlangen."
  ],
  "en": [
   "SSRF (Server Fetches an Attacker-Supplied URL)",
   "When a URL pointing at a listener on this machine was passed in a parameter that commonly takes a URL (url/uri/src/image/target, etc.), the server actually connected to it. The server fetches the URLs it is given without checking whether they point at addresses on this machine, so an attacker can make it reach internal services and the cloud metadata address (169.254.169.254) and read credentials from them. Attackers have also been seen passing a URL on their own server that answers with a redirect (302) to an internal address, which gets past a check that only looks at the first URL.",
   "Allow only the destinations the feature needs (allow-list). Resolve the host name yourself and refuse loopback, private and link-local addresses (including 169.254.169.254) after resolving. Either do not follow redirects, or run the same check on every redirect destination. On cloud servers, also require IMDSv2 (token required) for the metadata service."
  ],
  "es": [
   "SSRF (el servidor solicita una URL indicada por el atacante)",
   "Al pasar una URL que apunta a un puerto de escucha de esta máquina en un parámetro que suele recibir una URL (url/uri/src/image/target, etc.), el servidor se conectó realmente a ella. El servidor solicita las URL que recibe sin comprobar si apuntan a direcciones de esta máquina, por lo que un atacante puede hacer que alcance servicios internos y la dirección de metadatos de la nube (169.254.169.254) y leer credenciales. También se han visto atacantes que pasan la URL de su propio servidor, que responde con una redirección (302) a una dirección interna, lo que elude una comprobación que solo mira la primera URL.",
   "Permita solo los destinos que la función necesita (lista de permitidos). Resuelve tú mismo el nombre de host y, tras resolverlo, rechaza las direcciones de bucle local, privadas y de enlace local (incluida 169.254.169.254). No sigas las redirecciones, o aplica la misma comprobación a cada destino de redirección. En servidores en la nube, exige además IMDSv2 (token obligatorio) para el servicio de metadatos."
  ],
  "fr": [
   "SSRF (le serveur requête une URL fournie par l'attaquant)",
   "Lorsqu'une URL pointant vers un port d'écoute de cette machine a été transmise dans un paramètre qui reçoit couramment une URL (url/uri/src/image/target, etc.), le serveur s'y est réellement connecté. Le serveur récupère les URL qu'on lui donne sans vérifier si elles désignent des adresses de cette machine : un attaquant peut ainsi lui faire atteindre des services internes et l'adresse des métadonnées cloud (169.254.169.254) et y lire des identifiants. On a aussi observé des attaquants transmettant l'URL de leur propre serveur, qui répond par une redirection (302) vers une adresse interne, ce qui contourne un contrôle ne regardant que la première URL.",
   "N'autorisez que les destinations dont la fonction a besoin (liste blanche). Résolvez vous-même le nom d'hôte et refusez, après résolution, les adresses de bouclage, privées et de lien local (y compris 169.254.169.254). Ne suivez pas les redirections, ou appliquez le même contrôle à chaque destination de redirection. Sur les serveurs cloud, exigez aussi IMDSv2 (jeton obligatoire) pour le service de métadonnées."
  ],
  "it": [
   "SSRF (il server richiede un URL indicato dall'aggressore)",
   "Passando un URL che punta a una porta in ascolto di questa macchina in un parametro che di solito riceve un URL (url/uri/src/image/target, ecc.), il server vi si è effettivamente connesso. Il server richiede gli URL ricevuti senza verificare se puntano a indirizzi di questa macchina, quindi un aggressore può fargli raggiungere servizi interni e l'indirizzo dei metadati cloud (169.254.169.254) e leggerne le credenziali. Sono stati osservati anche aggressori che passano l'URL del proprio server, che risponde con un reindirizzamento (302) verso un indirizzo interno, aggirando un controllo che guarda solo il primo URL.",
   "Consenti solo le destinazioni di cui la funzione ha bisogno (lista consentita). Risolvi tu il nome host e, dopo la risoluzione, rifiuta gli indirizzi di loopback, privati e link-local (incluso 169.254.169.254). Non seguire i reindirizzamenti, oppure applica lo stesso controllo a ogni destinazione di reindirizzamento. Sui server cloud, richiedi anche IMDSv2 (token obbligatorio) per il servizio di metadati."
  ],
  "ja": [
   "SSRF（サーバーが指定されたURLを取りに行く）",
   "URLを受け取りやすいパラメータ（url/uri/src/image/target など）に、このマシン上の待ち受けを指すURLを渡したところ、サーバーがそこへ実際に接続しました。サーバーが渡されたURLを、このマシン内のアドレスかどうかを確かめずに取りに行くため、攻撃者は内部のサービスやクラウドのメタデータ（169.254.169.254）へ到達させ、認証情報を読み出せます。攻撃者が自分のサーバーのURLを渡し、そこから内部アドレスへのリダイレクト（302）を返させて、最初のURLだけを調べる対策をすり抜ける手口も確認されています。",
   "取得してよい宛先を、必要なものだけの許可リストにしてください。ホスト名は自分で名前解決し、解決後のアドレスがループバック・プライベート・リンクローカル（169.254.169.254を含む）なら拒否します。リダイレクトは追わないか、追うたびに同じ検査をかけてください。クラウド上のサーバーでは、メタデータをIMDSv2（トークン必須）に切り替えることも有効です。"
  ],
  "ko": [
   "SSRF(서버가 공격자가 지정한 URL에 접속)",
   "URL을 받는 데 흔히 쓰이는 파라미터(url/uri/src/image/target 등)에 이 머신의 대기 포트를 가리키는 URL을 전달했더니 서버가 실제로 그곳에 접속했습니다. 서버가 전달받은 URL이 이 머신 내부 주소인지 확인하지 않고 가져오므로, 공격자는 내부 서비스와 클라우드 메타데이터(169.254.169.254)에 도달하여 인증 정보를 읽을 수 있습니다. 공격자가 자신의 서버 URL을 전달하고 그곳에서 내부 주소로의 리다이렉트(302)를 반환시켜, 첫 번째 URL만 검사하는 방어를 우회하는 수법도 확인되었습니다.",
   "접속을 허용할 대상을 기능에 필요한 것만 허용 목록으로 제한하세요. 호스트 이름은 직접 해석하고, 해석된 주소가 루프백·사설·링크 로컬(169.254.169.254 포함)이면 거부합니다. 리다이렉트는 따라가지 않거나, 따라갈 때마다 같은 검사를 적용하세요. 클라우드 서버에서는 메타데이터 서비스를 IMDSv2(토큰 필수)로 전환하는 것도 효과적입니다."
  ],
  "pt-PT": [
   "SSRF (o servidor pede um URL indicado pelo atacante)",
   "Ao passar um URL que aponta para uma porta em escuta desta máquina num parâmetro que costuma receber um URL (url/uri/src/image/target, etc.), o servidor ligou-se de facto a ele. O servidor pede os URL que recebe sem verificar se apontam para endereços desta máquina, pelo que um atacante pode fazê-lo alcançar serviços internos e o endereço de metadados da nuvem (169.254.169.254) e ler credenciais. Também já foram vistos atacantes a passar o URL do seu próprio servidor, que responde com um redirecionamento (302) para um endereço interno, contornando uma verificação que só olha para o primeiro URL.",
   "Permita apenas os destinos de que a funcionalidade precisa (lista de permissões). Resolva o nome do anfitrião por si e, depois de resolvido, recuse endereços de loopback, privados e de ligação local (incluindo 169.254.169.254). Não siga redirecionamentos, ou aplique a mesma verificação a cada destino de redirecionamento. Em servidores na nuvem, exija também IMDSv2 (token obrigatório) para o serviço de metadados."
  ],
  "zh-Hans": [
   "SSRF（服务器会请求攻击者指定的 URL）",
   "在常用于接收 URL 的参数（url/uri/src/image/target 等）中传入指向本机监听端口的 URL 后，服务器确实连接了该地址。服务器在请求所收到的 URL 时没有检查它是否指向本机内部地址，因此攻击者可以让它访问内部服务和云元数据地址（169.254.169.254）并读取其中的凭据。还有攻击者传入自己服务器上的 URL，由其返回指向内部地址的重定向（302），从而绕过只检查第一个 URL 的防护。",
   "请将允许请求的目标限定为功能所需的允许列表。自行解析主机名，解析后若为环回、私有或链路本地地址（包括 169.254.169.254）则拒绝。要么不跟随重定向，要么对每一次重定向的目标都执行相同检查。云服务器上还应将元数据服务切换为 IMDSv2（必须使用令牌）。"
  ],
  "zh-Hant": [
   "SSRF（伺服器會請求攻擊者指定的 URL）",
   "在常用於接收 URL 的參數（url/uri/src/image/target 等）中傳入指向本機監聽連接埠的 URL 後，伺服器確實連線了該位址。伺服器在請求所收到的 URL 時沒有檢查它是否指向本機內部位址，因此攻擊者可以讓它存取內部服務與雲端中繼資料位址（169.254.169.254）並讀取其中的憑證。也有攻擊者傳入自己伺服器上的 URL，由其回傳指向內部位址的重新導向（302），藉此繞過只檢查第一個 URL 的防護。",
   "請將允許請求的目標限定為功能所需的允許清單。自行解析主機名稱，解析後若為迴路、私有或鏈路本地位址（包括 169.254.169.254）則拒絕。要嘛不跟隨重新導向，要嘛對每一次重新導向的目標都執行相同檢查。雲端伺服器上還應將中繼資料服務切換為 IMDSv2（必須使用權杖）。"
  ]
 },
 "web:webvuln-system-files-served": {
  "de": [
   "Systemdateien werden ausgeliefert (Dokumentwurzel ist /)",
   "Eine Anfrage nach /etc/passwd ohne ../ lieferte dessen Inhalt. Dieser Server nutzt / als Dokumentwurzel und gibt jede Datei, die er lesen kann, an jeden heraus (keine Pfad-Traversierung: das ganze Dateisystem ist veröffentlicht).",
   "Machen Sie nur den Ordner, den Sie veröffentlichen wollen, zur Dokumentwurzel (starten Sie z. B. python3 -m http.server mit -d auf diesen Ordner, nie auf /)."
  ],
  "en": [
   "System Files Served (Document Root Is /)",
   "A request for /etc/passwd with no ../ returned its contents. This server uses / as its document root and hands every file it can read to anyone (not a path traversal: the whole filesystem is published).",
   "Make only the folder you mean to publish the document root (for example, start python3 -m http.server with -d pointing at that folder, never at /)."
  ],
  "es": [
   "Se sirven archivos del sistema (raíz de documentos = /)",
   "Una petición de /etc/passwd sin ../ devolvió su contenido. Este servidor usa / como raíz de documentos y entrega a cualquiera todos los archivos que puede leer (no es un recorrido de rutas: se publica todo el sistema de archivos).",
   "Use como raíz de documentos solo la carpeta que quiere publicar (por ejemplo, inicie python3 -m http.server con -d apuntando a esa carpeta, nunca a /)."
  ],
  "fr": [
   "Fichiers système servis (racine des documents = /)",
   "Une requête pour /etc/passwd sans ../ a renvoyé son contenu. Ce serveur utilise / comme racine des documents et remet à n'importe qui chaque fichier qu'il peut lire (ce n'est pas une traversée de chemin : tout le système de fichiers est publié).",
   "Ne prenez comme racine des documents que le dossier à publier (par exemple, lancez python3 -m http.server avec -d sur ce dossier, jamais sur /)."
  ],
  "it": [
   "File di sistema serviti (document root = /)",
   "Una richiesta di /etc/passwd senza ../ ha restituito il suo contenuto. Questo server usa / come document root e consegna a chiunque ogni file che può leggere (non è un path traversal: è pubblicato l'intero filesystem).",
   "Usare come document root solo la cartella da pubblicare (ad esempio, avviare python3 -m http.server con -d su quella cartella, mai su /)."
  ],
  "ja": [
   "システムのファイルを配信 (ドキュメントルートが /)",
   "../ を使わずに /etc/passwd を要求すると、その中身が返りました。このサーバーは / をドキュメントルートにしていて、読めるファイルをすべて誰にでも配信します(パストラバーサルではなく、ファイルシステム全体の公開です)。",
   "配信するフォルダーだけをドキュメントルートにしてください(例: python3 -m http.server は -d で配信するフォルダーを指定し、/ で起動しない)。"
  ],
  "ko": [
   "시스템 파일 제공 (문서 루트가 /)",
   "../ 없이 /etc/passwd 를 요청하자 그 내용이 반환되었습니다. 이 서버는 / 를 문서 루트로 사용하며 읽을 수 있는 모든 파일을 누구에게나 제공합니다(경로 탐색이 아니라 파일 시스템 전체가 공개된 상태입니다).",
   "공개할 폴더만 문서 루트로 지정하세요(예: python3 -m http.server 는 -d 로 그 폴더를 지정하고 / 에서 시작하지 마세요)."
  ],
  "pt-PT": [
   "Ficheiros do sistema servidos (raiz de documentos = /)",
   "Um pedido de /etc/passwd sem ../ devolveu o seu conteúdo. Este servidor usa / como raiz de documentos e entrega a qualquer pessoa todos os ficheiros que consegue ler (não é uma travessia de caminhos: todo o sistema de ficheiros está publicado).",
   "Use como raiz de documentos apenas a pasta que pretende publicar (por exemplo, inicie python3 -m http.server com -d a apontar para essa pasta, nunca para /)."
  ],
  "zh-Hans": [
   "正在提供系统文件 (文档根目录为 /)",
   "不使用 ../ 直接请求 /etc/passwd 时返回了其内容。此服务器以 / 为文档根目录,会把它能读取的所有文件提供给任何人(这不是路径遍历,而是整个文件系统被公开)。",
   "请只把要发布的文件夹设为文档根目录(例如 python3 -m http.server 用 -d 指定该文件夹,不要在 / 启动)。"
  ],
  "zh-Hant": [
   "正在提供系統檔案 (文件根目錄為 /)",
   "不使用 ../ 直接請求 /etc/passwd 時回傳了其內容。此伺服器以 / 為文件根目錄,會把它能讀取的所有檔案提供給任何人(這不是路徑遍歷,而是整個檔案系統被公開)。",
   "請只把要發布的資料夾設為文件根目錄(例如 python3 -m http.server 用 -d 指定該資料夾,不要在 / 啟動)。"
  ]
 },
 "web:webvuln-traversal": {
  "de": [
   "Path Traversal (Verzeichnisüberquerung)",
   "Das Senden einer Anfrage mit ../ an den Pfad für statische Dateien lieferte erfolgreich den Inhalt von /etc/passwd außerhalb des Web-Roots. Unzureichende Pfadnormalisierung/-validierung bedeutet, dass ein Angreifer beliebige Dateien außerhalb des Web-Roots lesen kann.",
   "Aktualisieren Sie Ihre Bibliothek zur Bereitstellung statischer Dateien auf die neueste Version, normalisieren Sie den Bereitstellungspfad und beschränken Sie ihn auf den Web-Root. Beschränken Sie nach Möglichkeit auch den Dateisystemzugriff selbst über einen Container oder chroot."
  ],
  "en": [
   "Path Traversal (Directory Traversal)",
   "Sending a request containing ../ to the static file path successfully retrieved the contents of /etc/passwd, outside the web root. Insufficient path normalization/validation means an attacker can read arbitrary files outside the web root.",
   "Update your static file serving library to the latest version, normalize the serving path, and restrict it to within the web root. Where possible, also restrict filesystem access itself via a container or chroot."
  ],
  "es": [
   "Recorrido de rutas (Path Traversal)",
   "El envío de una solicitud con ../ a la ruta de archivos estáticos permitió obtener el contenido de /etc/passwd, fuera de la raíz web. Una normalización/validación de rutas insuficiente significa que un atacante puede leer archivos arbitrarios fuera de la raíz web.",
   "Actualiza tu biblioteca de servicio de archivos estáticos a la última versión, normaliza la ruta de servicio y restríngela dentro de la raíz web. Si es posible, restringe también el acceso al propio sistema de archivos mediante un contenedor o chroot."
  ],
  "fr": [
   "Traversée de répertoire (Path Traversal)",
   "L'envoi d'une requête contenant ../ vers le chemin des fichiers statiques a permis de récupérer le contenu de /etc/passwd, en dehors de la racine web. Une normalisation/validation de chemin insuffisante signifie qu'un attaquant peut lire des fichiers arbitraires en dehors de la racine web.",
   "Mettez à jour votre bibliothèque de service de fichiers statiques vers la dernière version, normalisez le chemin de service et limitez-le à la racine web. Si possible, limitez également l'accès au système de fichiers lui-même via un conteneur ou chroot."
  ],
  "it": [
   "Path Traversal (Attraversamento di directory)",
   "L'invio di una richiesta contenente ../ al percorso dei file statici ha recuperato con successo il contenuto di /etc/passwd, al di fuori della radice web. Una normalizzazione/convalida del percorso insufficiente significa che un aggressore può leggere file arbitrari al di fuori della radice web.",
   "Aggiorna la libreria di distribuzione dei file statici all'ultima versione, normalizza il percorso di distribuzione e limitalo alla radice web. Se possibile, limita anche l'accesso al file system stesso tramite un container o chroot."
  ],
  "ja": [
   "パストラバーサル（ディレクトリトラバーサル）",
   "静的ファイル配信のパスに ../ を含むリクエストを送信したところ、Webルート外の /etc/passwd の内容が取得できました。ファイルパスの正規化・検証が不十分なため、Webルート外の任意のファイルを読み取られる危険があります。",
   "静的ファイル配信ライブラリを最新版に更新し、配信元パスを正規化したうえでWebルート内に限定してください。可能であればコンテナ/chrootでファイルシステムへのアクセス範囲自体を制限することも推奨します。"
  ],
  "ko": [
   "경로 탐색(디렉터리 탐색) 취약점",
   "정적 파일 경로에 ../ 를 포함한 요청을 전송했더니 웹 루트 외부의 /etc/passwd 내용을 가져올 수 있었습니다. 경로 정규화/검증이 불충분하여 공격자가 웹 루트 외부의 임의 파일을 읽을 수 있는 위험이 있습니다.",
   "정적 파일 제공 라이브러리를 최신 버전으로 업데이트하고, 제공 경로를 정규화하여 웹 루트 내로 제한하세요. 가능하다면 컨테이너나 chroot로 파일시스템 접근 범위 자체를 제한하는 것도 권장합니다."
  ],
  "pt-PT": [
   "Travessia de diretório (Path Traversal)",
   "O envio de um pedido contendo ../ para o caminho de ficheiros estáticos obteve com sucesso o conteúdo de /etc/passwd, fora da raiz web. Uma normalização/validação de caminho insuficiente significa que um atacante pode ler ficheiros arbitrários fora da raiz web.",
   "Atualize a sua biblioteca de distribuição de ficheiros estáticos para a versão mais recente, normalize o caminho de distribuição e restrinja-o à raiz web. Se possível, restrinja também o próprio acesso ao sistema de ficheiros através de um contentor ou chroot."
  ],
  "zh-Hans": [
   "路径穿越（目录穿越）",
   "向静态文件路径发送包含 ../ 的请求后，成功获取了 Web 根目录之外的 /etc/passwd 内容。路径规范化/校验不足意味着攻击者可以读取 Web 根目录之外的任意文件。",
   "请将静态文件服务库更新到最新版本，规范化服务路径并将其限制在 Web 根目录内。如可能，也建议通过容器或 chroot 限制文件系统访问范围。"
  ],
  "zh-Hant": [
   "路徑穿越（目錄穿越）",
   "向靜態檔案路徑傳送包含 ../ 的請求後，成功取得了 Web 根目錄之外的 /etc/passwd 內容。路徑正規化/驗證不足意味著攻擊者可讀取 Web 根目錄之外的任意檔案。",
   "請將靜態檔案服務庫更新到最新版本，正規化服務路徑並將其限制在 Web 根目錄內。如可能，也建議透過容器或 chroot 限制檔案系統存取範圍。"
  ]
 },
 "web:webvuln-xss": {
  "de": [
   "Reflektiertes XSS (Anfragewerte werden ungeschützt in die Seite geschrieben)",
   "Eine harmlose Zeichenfolge (sie enthält < > und Anführungszeichen, aber kein Skript) wurde in einem GET-Parameter gesendet, und die Seite hat sie ohne Maskierung ins HTML geschrieben. Wer einen bösartigen Link öffnet, könnte das Skript eines Angreifers im eigenen Browser ausführen.",
   "Maskieren Sie Werte, bevor Sie sie ins HTML schreiben: Lassen Sie die automatische Maskierung der Template-Engine aktiv und fügen Sie keine Rohstrings per innerHTML, dangerouslySetInnerHTML oder Ähnlichem ein. Ein Content-Security-Policy-Header begrenzt zusätzlich den Schaden, falls doch etwas durchrutscht."
  ],
  "en": [
   "Reflected XSS (request values are written into the page unescaped)",
   "A harmless test string (it contains < > and quotes but no script) was sent in a GET parameter, and the page wrote it into the HTML without escaping it. Someone who opens a malicious link could have an attacker's script run in their browser.",
   "Escape values when writing them into HTML: keep the template engine's auto-escaping on and do not insert raw strings with innerHTML, dangerouslySetInnerHTML and similar. A Content-Security-Policy header also limits the damage if one slips through."
  ],
  "es": [
   "XSS reflejado (los valores de la solicitud se escriben en la página sin escapar)",
   "Se envió una cadena de prueba inofensiva (contiene < > y comillas, pero ningún script) en un parámetro GET y la página la escribió en el HTML sin escaparla. Quien abra un enlace malicioso podría ejecutar el script de un atacante en su navegador.",
   "Escape los valores al escribirlos en HTML: mantenga activado el escape automático del motor de plantillas y no inserte cadenas sin procesar con innerHTML, dangerouslySetInnerHTML o similares. Una cabecera Content-Security-Policy también limita el daño si algo se cuela."
  ],
  "fr": [
   "XSS réfléchi (les valeurs de la requête sont écrites dans la page sans échappement)",
   "Une chaîne de test inoffensive (elle contient < > et des guillemets, mais aucun script) a été envoyée dans un paramètre GET, et la page l'a écrite dans le HTML sans l'échapper. Une personne qui ouvre un lien malveillant risque d'exécuter le script d'un attaquant dans son navigateur.",
   "Échappez les valeurs avant de les écrire dans le HTML : gardez l'échappement automatique du moteur de gabarits activé et n'insérez pas de chaînes brutes avec innerHTML, dangerouslySetInnerHTML ou équivalent. Un en-tête Content-Security-Policy limite aussi les dégâts si quelque chose passe à travers."
  ],
  "it": [
   "XSS riflesso (i valori della richiesta vengono scritti nella pagina senza escape)",
   "Una stringa di prova innocua (contiene < > e virgolette, ma nessuno script) è stata inviata in un parametro GET e la pagina l'ha scritta nell'HTML senza eseguire l'escape. Chi apre un link dannoso rischia di eseguire nel browser lo script di un attaccante.",
   "Esegui l'escape dei valori quando li scrivi nell'HTML: mantieni attivo l'escape automatico del motore di template e non inserire stringhe grezze con innerHTML, dangerouslySetInnerHTML o simili. Un'intestazione Content-Security-Policy limita inoltre i danni se qualcosa sfugge."
  ],
  "ja": [
   "反射型XSS（入力値が無害化されずにHTMLへ出力される）",
   "検証用の無害な文字列（< > と引用符を含み、スクリプトは含みません）をGETパラメータに入れて送ったところ、エスケープされないままHTMLに出力されました。悪意あるリンクを開いた利用者のブラウザで、攻撃者のスクリプトが実行される危険があります。",
   "出力時にHTMLエスケープしてください（テンプレートエンジンの自動エスケープを有効にし、innerHTML や dangerouslySetInnerHTML などで生の文字列を挿入しない）。あわせて Content-Security-Policy を設定すると、万一の被害を抑えられます。"
  ],
  "ko": [
   "반사형 XSS(요청 값이 이스케이프 없이 페이지에 출력됨)",
   "무해한 테스트 문자열(< >와 따옴표는 포함하지만 스크립트는 포함하지 않음)을 GET 매개변수로 보냈더니 이스케이프 없이 HTML에 그대로 출력되었습니다. 악성 링크를 연 사용자의 브라우저에서 공격자의 스크립트가 실행될 위험이 있습니다.",
   "HTML에 출력할 때 값을 이스케이프하세요. 템플릿 엔진의 자동 이스케이프를 켜 두고, innerHTML이나 dangerouslySetInnerHTML 등으로 원본 문자열을 삽입하지 마세요. Content-Security-Policy를 함께 설정하면 만일의 피해를 줄일 수 있습니다."
  ],
  "pt-PT": [
   "XSS refletido (os valores do pedido são escritos na página sem escape)",
   "Foi enviada uma cadeia de teste inofensiva (contém < > e aspas, mas nenhum script) num parâmetro GET e a página escreveu-a no HTML sem escape. Quem abrir uma ligação maliciosa pode executar o script de um atacante no seu navegador.",
   "Faça o escape dos valores ao escrevê-los no HTML: mantenha ativo o escape automático do motor de modelos e não insira cadeias em bruto com innerHTML, dangerouslySetInnerHTML ou semelhantes. Um cabeçalho Content-Security-Policy também limita os danos se algo escapar."
  ],
  "zh-Hans": [
   "反射型 XSS（请求参数未经转义即输出到页面）",
   "将一个无害的测试字符串（包含 < > 和引号，但不含脚本）放入 GET 参数发送后，页面未经转义就把它输出到了 HTML 中。打开恶意链接的用户，其浏览器中可能会执行攻击者的脚本。",
   "输出到 HTML 时请进行转义：保持模板引擎的自动转义开启，不要用 innerHTML、dangerouslySetInnerHTML 等方式插入原始字符串。再配置 Content-Security-Policy，可在万一漏网时降低危害。"
  ],
  "zh-Hant": [
   "反射型 XSS（請求參數未經跳脫即輸出至頁面）",
   "將一個無害的測試字串（包含 < > 與引號，但不含指令碼）放入 GET 參數送出後，頁面未經跳脫就把它輸出到了 HTML 中。開啟惡意連結的使用者，其瀏覽器中可能會執行攻擊者的指令碼。",
   "輸出到 HTML 時請進行跳脫：保持範本引擎的自動跳脫開啟，不要用 innerHTML、dangerouslySetInnerHTML 等方式插入原始字串。再設定 Content-Security-Policy，可在萬一漏網時降低危害。"
  ]
 }
}
"""#
}
