// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.10.0 (build 116).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

/// Static, English-only agentskills.io-style "skill" documents served over MCP
/// as `roamswitch://skills/<name>` resources (see `MCPServer.swift`'s
/// `resourceCatalog` and `resources/read` handling).
///
/// These are deliberately NOT routed through `RoamSwitchKnowledgeBase`'s
/// per-language machinery — agentskills.io skill content is conventionally
/// English-only (it's a procedure for an AI agent to follow, not user-facing
/// UI text), so this is an intentional, documented exception to this
/// project's usual "everything user-facing is localized" rule.
///
/// Each skill teaches an AI agent connected to roamswitch-mcp how to
/// correctly interpret one category of RoamSwitch's own read-only detection
/// output — the same tool/field names the live MCP tools actually return,
/// including the specific misreading traps already documented in those
/// tools' own descriptions (e.g. "a snapshot is not a timeline").
enum RoamSwitchMCPSkillsContent {
    static let skillsByURI: [String: String] = [
        "roamswitch://skills/triaging-port-anomaly-alerts": triagingPortAnomalyAlerts,
        "roamswitch://skills/prioritizing-active-vuln-scan-findings": prioritizingActiveVulnScanFindings,
        "roamswitch://skills/prioritizing-package-cve-findings": prioritizingPackageCveFindings,
        "roamswitch://skills/triaging-ransomware-and-incident-timeline": triagingRansomwareAndIncidentTimeline,
    ]

    static let catalogEntries: [(uri: String, name: String, description: String)] = [
        (
            "roamswitch://skills/triaging-port-anomaly-alerts",
            "Skill: Triaging RoamSwitch Port Anomaly Guard Alerts",
            "Step-by-step procedure for an AI agent to judge whether a newly-exposed listening port RoamSwitch reported is a real risk or a false alarm, using get_port_anomaly_incidents, get_process_tree, and search_exec_events."
        ),
        (
            "roamswitch://skills/prioritizing-active-vuln-scan-findings",
            "Skill: Prioritizing RoamSwitch Active Vulnerability Scan Findings",
            "Step-by-step procedure for an AI agent to rank run_active_vuln_scan findings for remediation when no CVSS/severity field exists, and to correctly handle the vulnerable/safe/inconclusive three-state model."
        ),
        (
            "roamswitch://skills/prioritizing-package-cve-findings",
            "Skill: Prioritizing RoamSwitch Package & Dependency CVE Findings",
            "Step-by-step procedure for an AI agent to rank run_package_cve_scan / run_package_cve_scan_languages findings by real CVSS score and confidence, distinct from the active-vuln-scan skill's heuristic-only approach."
        ),
        (
            "roamswitch://skills/triaging-ransomware-and-incident-timeline",
            "Skill: Triaging RoamSwitch Ransomware Canary & Incident Timeline Events",
            "Step-by-step procedure for an AI agent to assess a ransomware canary trigger, judge which recovery snapshot is safe to restore from, and correlate the wider cross-guard incident timeline — the recommended first stop for any RoamSwitch incident investigation."
        ),
    ]

    // MARK: - Skill 1

    private static let triagingPortAnomalyAlerts = """
    ---
    name: triaging-roamswitch-port-anomaly-alerts
    description: >-
      Judge whether a newly-exposed listening port that RoamSwitch's Port
      Anomaly Guard reported is a real risk (an attacker or malware opening a
      backdoor/C2 listener) or a benign false alarm (a dev server, a package
      manager, a legitimate app update), using RoamSwitch's own read-only MCP
      tools. Use this whenever the user shares a Port Anomaly Guard
      notification or asks "is this port thing RoamSwitch flagged okay?".
    domain: cybersecurity
    subdomain: endpoint-security
    tags: [roamswitch, port-anomaly, triage, mcp, endpoint]
    version: "1.0"
    author: roamswitch
    license: Apache-2.0
    ---

    ## When to Use

    The user has RoamSwitch's Port Anomaly Guard notification in front of
    them (a new local listening port appeared that wasn't part of the
    established baseline), or asks you to check whether currently-isolated
    ports are something to worry about.

    ## Prerequisites

    - roamswitch-mcp connected and reachable (`get_guard_status` shows
      `port_anomaly` enabled).
    - This tool family is read-only: nothing here can re-open a port,
      isolate a new one, or change protection level. Your job ends at a
      clear recommendation for the human to act on.

    ## Workflow

    1. Call `get_port_anomaly_incidents`. Read `isEnabled` and
       `baselineCaptured` first — if either is false, the absence of
       incidents means "not being watched," not "verified clean." Say so
       explicitly rather than reporting a clean bill of health.
    2. **Do not conflate the two lists.** `autoIsolatedPorts` is a live
       snapshot of ports currently blocked *right now* — it is NOT a
       timeline and must never be matched to an `incidents` entry unless
       the incident's `timestamp` is recent enough to plausibly be the same
       event. An old incident and a currently-isolated port can be
       completely unrelated.
    3. For each incident of interest, note `port`, `processName`, `pid`,
       and `executablePath`. A `pid`/`executablePath` that no longer exists
       (process already exited) is common and not itself suspicious.
    4. Cross-reference with process context:
       - `get_process_tree` with the incident's `pid` (if still running, or
         at the incident's `timestamp` via the `at` parameter) to see the
         parent chain. A dev tool (`node`, `python`, `ruby`, IDE-launched
         servers) spawned from a shell/IDE the user recognizes is the
         common benign case.
       - `search_exec_events` filtered by the same `pid`/time window for
         corroborating detail (what launched it, with what arguments).
    5. Weigh toward "likely benign" when: `executablePath` is inside a
       known dev-tool/package-manager install location, the process is a
       well-known interpreter/build tool, and `get_process_tree` shows a
       normal, explicable parent chain the user set up themselves.
    6. Weigh toward "investigate further / do not dismiss" when:
       `executablePath` is in an unusual location (`/tmp`, a hidden
       dotfile directory, a downloads folder), the process name doesn't
       match its actual binary path, the parent chain is unfamiliar, or
       multiple incidents cluster in a short window.
    7. Present your conclusion as a recommendation, never as an action you
       took: e.g. "this looks like your local dev server restarting — safe
       to leave isolated-off, or add an allowlist entry if you'll keep
       running it" vs. "this doesn't match any tool you'd recognize —
       leave it isolated and consider a fuller `get_incident_timeline` /
       `get_guard_status` review before allowing it."

    ## Verification

    Before answering, confirm you have: (a) checked `isEnabled` /
    `baselineCaptured` rather than assuming coverage, (b) not attributed an
    `autoIsolatedPorts` entry to an unrelated-in-time `incidents` entry, and
    (c) phrased the output as a recommendation for the human, since no tool
    in this family can change RoamSwitch's protection state.
    """

    // MARK: - Skill 2

    private static let prioritizingActiveVulnScanFindings = """
    ---
    name: prioritizing-roamswitch-active-vuln-scan-findings
    description: >-
      Rank the findings from RoamSwitch's proof-of-concept-based
      run_active_vuln_scan (network service probes: default credentials,
      unauthenticated access, common misconfigurations) for remediation
      priority, when the finding objects carry no CVSS/severity field at
      all. Also covers correctly handling the vulnerable/safe/inconclusive
      three-state probe model so an inconclusive result is never reported
      as "safe." Use this whenever the user asks "what should I fix first"
      after an active vulnerability scan, or shares scan output to review.
    domain: cybersecurity
    subdomain: vulnerability-management
    tags: [roamswitch, vulnerability-scan, prioritization, mcp, triage]
    version: "1.0"
    author: roamswitch
    license: Apache-2.0
    ---

    ## When to Use

    The user has run (or asks you to run) `run_active_vuln_scan` and wants
    to know which of the results matter most, or wants help reading a scan
    that returned a mix of findings, confirmed-safe checks, and
    inconclusive checks.

    ## Prerequisites

    - `run_active_vuln_scan` is opt-in; if the tool reports it disabled,
      say so rather than treating an empty result as "nothing wrong."
    - Know the three-state model before reading any output: every probe
      reports exactly one of `vulnerable` (a `Finding`), `safe` (a
      `CheckOutcome` — the probe ran to completion and found nothing), or
      `inconclusive` (a `CheckOutcome` — the probe itself couldn't
      complete: timeout, connection refused, etc.). **`inconclusive` is
      never usable as evidence of safety** — a port that never opened is
      not the same as a port that opened and passed.

    ## Workflow

    1. Call `run_active_vuln_scan`. Separate the response into its three
       buckets before doing anything else.
    2. Read every `inconclusive` entry aloud (to the user) as "not
       actually checked" — recommend re-running the scan under conditions
       where the probe can complete (service running, firewall/VPN not
       blocking the loopback probe, etc.) rather than letting the user
       assume it's fine.
    3. For `vulnerable` findings: each `Finding` has only `port`,
       `processName`, `title`, `description`, `recommendation` — **no
       numeric severity field exists to sort by**. Build your own ranking
       from the text itself using this heuristic, most urgent first:
       - Findings whose `title`/`description` indicate the check
         positively confirmed unauthenticated data/command access (e.g. "no
         auth required", "default credentials accepted", "arbitrary command
         execution") outrank ones describing only a configuration weakness
         or information disclosure.
       - A finding on a port/service reachable from outside the local
         machine (cross-reference with `get_exposed_ports` —
         `includeLocalOnly: false`) outranks the same class of finding on a
         loopback-only service.
       - Multiple findings on the same `processName`/`port` suggest one
         root cause (e.g. one exposed service with several weaknesses) —
         group them in your answer rather than listing them as unrelated
         items of equal weight.
    4. Always relay the finding's own `recommendation` text verbatim as
       part of your answer — it is written by the probe author with the
       specific check in mind and should not be paraphrased away.
    5. If the user also has `run_package_cve_scan` results to weigh
       against these, do not merge the two into one ranking — use the
       companion skill `prioritizing-roamswitch-package-cve-findings`, since
       that data model has a real CVSS field and a different, sounder
       ranking method. Mixing a text-heuristic ranking with a CVSS-based one
       in a single list will misrepresent confidence levels.

    ## Verification

    Before answering, confirm you have: (a) called out every
    `inconclusive` result as unverified rather than silently dropping it,
    (b) not invented a numeric severity for a `Finding` that doesn't carry
    one, and (c) kept this ranking separate from any `run_package_cve_scan`
    ranking rather than blending the two heuristics together.
    """

    // MARK: - Skill 3

    private static let prioritizingPackageCveFindings = """
    ---
    name: prioritizing-roamswitch-package-cve-findings
    description: >-
      Rank findings from RoamSwitch's package/dependency CVE scanners
      (run_package_cve_scan, run_package_cve_scan_languages) by real CVSS
      score and match confidence. Distinct from
      prioritizing-roamswitch-active-vuln-scan-findings because this finding
      type DOES carry a numeric cvssScore and a confirmed/gray confidence
      field — use the real numbers here instead of a text heuristic. Use
      this whenever the user asks which installed package or dependency to
      patch first.
    domain: cybersecurity
    subdomain: vulnerability-management
    tags: [roamswitch, cve, package-scan, prioritization, mcp, triage]
    version: "1.0"
    author: roamswitch
    license: Apache-2.0
    ---

    ## When to Use

    The user has run (or asks you to run) `run_package_cve_scan` (Homebrew
    formulae) or `run_package_cve_scan_languages` (project lockfiles: npm,
    pip, cargo, etc., via `watchedFolders`) and wants a patch-priority
    ranking.

    ## Prerequisites

    - `run_package_cve_scan_languages` and `run_typosquat_scan`/
      `run_package_lifecycle_script_scan` require a `watchedFolders` array
      of real paths — confirm the user has told you (or told RoamSwitch's
      settings) which project directories to scan; an empty/wrong list
      silently means nothing was scanned, not that the project is clean.

    ## Workflow

    1. Call the appropriate tool(s) and collect every finding. Each
       carries `cvssScore: Double` and `confidence: String`
       (`"confirmed"` or `"gray"`) — use these directly rather than
       inventing a text-based heuristic (contrast with the active-vuln-scan
       skill, which must invent one because that data model has no such
       fields).
    2. Primary sort key: `cvssScore` descending. Treat 9.0+ as critical,
       7.0-8.9 as high, 4.0-6.9 as medium, below 4.0 as low — standard CVSS
       severity bands.
    3. Secondary consideration: **down-weight `confidence: "gray"`
       findings relative to `"confirmed"` ones of the same score band** —
       a gray match means the scanner's version/identity match for that
       package was less certain (possible false positive), so recommend
       the user manually confirm the installed version before treating it
       with the same urgency as a confirmed high-CVSS finding.
    4. When a package/formula shows up in both `run_package_cve_scan`
       (Homebrew) and `run_package_cve_scan_languages` (a project
       lockfile) with different scores, report both — they may be
       different versions in different contexts and neither is more
       "correct" than the other by default.
    5. Present the final list sorted by (severity band, then confidence,
       then score) with the package name, installed context (Homebrew vs.
       which lockfile/project), and the CVE identifier if present in the
       finding's fields, so the user can act without re-deriving the
       ranking themselves.

    ## Verification

    Before answering, confirm you have: (a) used the real `cvssScore`
    field rather than a text-based guess, (b) explicitly flagged
    `confidence: "gray"` findings as needing manual confirmation rather
    than presenting them with the same certainty as confirmed ones, and (c)
    not silently merged this ranking with an unrelated
    `run_active_vuln_scan` ranking that uses a different (heuristic-only)
    method.
    """

    // MARK: - Skill 4

    private static let triagingRansomwareAndIncidentTimeline = """
    ---
    name: triaging-roamswitch-ransomware-and-incident-timeline
    description: >-
      Assess a RoamSwitch Ransomware Canary Guard trigger, judge which
      recovery snapshot (if any) is safe to restore from, and correlate the
      broader cross-guard incident timeline for MITRE ATT&CK context. This
      is the recommended starting point for any RoamSwitch incident
      investigation, including during an emergency Air-Gap network cutoff
      when only a locally-connected AI agent can reach the machine. Use
      this whenever the user reports a ransomware alert, an Air-Gap
      lockdown, or asks "what just happened."
    domain: cybersecurity
    subdomain: ransomware-defense
    tags: [roamswitch, ransomware, incident-timeline, mitre-attack, mcp, triage]
    version: "1.0"
    author: roamswitch
    license: Apache-2.0
    ---

    ## When to Use

    The user reports RoamSwitch triggered an emergency containment
    (network Air-Gap, a ransomware canary alert, a runtime-threat
    lockdown), or simply asks what RoamSwitch has flagged recently. This is
    also the intended entry point when you are reached over a local
    connection during an active Air-Gap, before wider network access is
    restored.

    ## Prerequisites

    - None of these tools can remediate anything — no lockdown toggle, no
      port isolation change, no device eject exists in this tool family.
      Your output must be a clear situation summary and recommendation for
      the human, never a claim that you've fixed something.
    - If running standalone (outside the app bundle), some tools may
      report "disabled"/empty rather than error — check the relevant
      `isEnabled` field before concluding "nothing happened."

    ## Workflow

    1. Start broad: call `get_incident_timeline` (default `limit: 50` is
       usually enough). Note `unresolvedCount` and read each event's
       `severity`, `source`, `attackTechnique` (a MITRE ATT&CK ID — only
       ever set when confidently mappable, so treat its *absence* as "not
       confident enough to tag," not "not an attack"), and `actionTaken`.
       The response's own `caveats` field may note that a `summary` was
       recorded in a different display language than your current one —
       don't be thrown by that.
    2. If a ransomware canary event appears (or the user specifically
       reports one), call `get_canary_status` for the fuller picture:
       `monitoredFilesCount` vs `expectedFilesCount` (a mismatch suggests
       bait files themselves were tampered with or removed),
       `recentIncidents` (each with `fileName`, `detectedAction`,
       `suspectedProcess`, `affectedFilePaths` — the suspected-process
       attribution is best-effort, since Mac has no EndpointSecurity
       entitlement here; treat it as a strong lead, not a certainty).
    3. Then call `get_ransomware_recovery_snapshots` before recommending
       any restore. Critical semantics: **only `kind: "pre_damage"`
       snapshots are safe recovery sources.** A `"detection"` snapshot may
       already contain post-encryption files — never recommend restoring
       from one. `retentionMode: true` means a detection snapshot is newer
       than the last good pre_damage one, and new snapshots/pruning are
       paused — flag this to the user as "recovery options are frozen,
       act on the newest good pre_damage snapshot before it's pruned
       elsewhere." Re-check `exists` per snapshot — macOS can auto-expire
       local snapshots within ~24h, so a snapshot listed a day ago may no
       longer be present.
    4. For deeper attribution, use `search_exec_events` and
       `get_process_tree` around the incident's timestamp/pid to build the
       fuller ancestry chain of the suspected process.
    5. Cross-check `get_quarantine_status` and `get_notification_history`
       for related activity (a quarantined download shortly before the
       canary trigger is a strong causal link worth surfacing).
    6. Summarize for the user in this order: (a) what triggered, with
       confidence level, (b) whether it's still ongoing/isolated right
       now vs. already resolved, (c) the single safest recovery snapshot
       to consider (if any pre_damage one exists and is still `exists:
       true`), (d) anything requiring their action RoamSwitch itself
       cannot do (e.g. manually releasing an Air-Gap lockdown, running a
       full malware scan, rotating credentials if a credential-adjacent
       guard also fired around the same time).

    ## Verification

    Before answering, confirm you have: (a) never recommended restoring
    from a `"detection"`-kind snapshot, (b) treated an absent
    `attackTechnique` as low-confidence rather than "not an attack," (c)
    re-checked snapshot `exists` rather than trusting a stale listing, and
    (d) phrased every recommendation as something for the human to do,
    since this tool family cannot itself remediate anything.
    """
}
