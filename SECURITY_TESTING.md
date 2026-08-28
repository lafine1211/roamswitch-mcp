# Security testing

The server is read-only, unprivileged, and opens no socket, so the realistic
failure modes are **denial of service** — a trap (force-unwrap, overflow) or a
hang (unbounded loop, ReDoS, pathological allocation) triggered by input the
program doesn't fully control:

1. the JSON-RPC line coming in on stdin (the MCP client, and — via tool
   arguments — whatever an LLM decides to pass);
2. the text output of `lsof` / `arp` / `route` / `spctl` / … , parts of which
   an unprivileged local process can influence.

Swift is memory-safe, so none of this is a path to code execution or privilege
gain. The worst case is the server process dying and the client losing its
connection.

## What runs

Everything below runs in `swift test` and in [CI](.github/workflows/ci.yml) on
every push. Nothing here needs a special toolchain.

| Test file | What it does |
| --- | --- |
| `MCPServerRobustnessTests` | Feeds `MCPServer.handleLine` nesting bombs (array and object), 5 MB string arguments, pathological `get_app_help` queries, 10 k-element batches, and every shape of malformed `params`. Asserts each call returns within a wall-clock budget. |
| `ParserRobustnessTests` | Feeds `parseLsofOutput` / `parseMACAddress` crafted subprocess output — process names with spaces, PID values that overflow `Int`, non-ASCII, truncated lines, an `arp` line repeated 100 k times. Asserts no crash, and that a line the parser can't make sense of is dropped, never classified as a globally-exposed port. |
| `MutationFuzzTests` | Coverage-blind mutation fuzzing: takes a seed corpus of real JSON-RPC messages, applies random byte-level mutations (flips, inserts, deletes, chunk duplication, structural-byte injection), and runs `MCPServer.handleLine` on ~20 k mutants per run (`FUZZ_ITERATIONS` to change). Asserts every result returns and stays bounded. |
| `StdioSmokeTests` | Drives the built binary over stdio the way a client would, including a line of pure garbage followed by valid requests — the read loop must keep going. |

## Findings

| Date | Found by | Issue | Fix |
| --- | --- | --- | --- |
| 2026-08-28 | `MCPServerRobustnessTests` | `JSONSerialization.jsonObject` SIGBUS (stack overflow) on a deeply-nested JSON **object** (`{"a":{"a":{"a":…`). Deep **arrays** it rejects cleanly — the object path recurses without a guard. A single crafted line could kill the server. | `MCPServer.handleLine` now runs an O(n) nesting-depth pre-scan (limit 128; real MCP messages nest ~4) and a size cap before the parser ever sees the input. Regression test added. |

## What this is not

- **Not coverage-guided fuzzing.** libFuzzer (`-sanitize=fuzzer`) is not
  available on the Xcode toolchain for `arm64-apple-macos`. `MutationFuzzTests`
  is coverage-blind — it catches shallow traps and hangs reliably but won't
  reach deep states the way libFuzzer would. Coverage-guided fuzzing with a
  swift.org toolchain, and an independent security review of the privileged
  parts that are **not** in this repo (the helper, `pf` control, the XPC
  code-signing check), are tracked separately.
- **Not an audit or a certification.** It's the project showing its testing.
