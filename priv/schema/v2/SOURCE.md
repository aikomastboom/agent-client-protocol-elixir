# Vendored ACP v2 JSON Schema

Canonical reference copies of the Agent Client Protocol v2 JSON Schema, vendored into
this library so v2 type work can proceed against a fixed, offline reference instead of
a moving `main`.

## Provenance

- **Upstream repository:** <https://github.com/agentclientprotocol/agent-client-protocol>
- **Pinned commit:** `0c90706c45ad0ca15aedffc8870ab383c7430233` (`main` at vendor time)
- **Upstream schema version:** `schema-v2.0.0-alpha.10` (2026-10-27), per
  `UPSTREAM_CHANGELOG.md`
- **Vendored:** 2026-10-29

## Files

| File | Upstream URL |
| --- | --- |
| `schema.json` | <https://raw.githubusercontent.com/agentclientprotocol/agent-client-protocol/0c90706c45ad0ca15aedffc8870ab383c7430233/schema/v2/schema.json> |
| `schema.unstable.json` | <https://raw.githubusercontent.com/agentclientprotocol/agent-client-protocol/0c90706c45ad0ca15aedffc8870ab383c7430233/schema/v2/schema.unstable.json> |
| `UPSTREAM_CHANGELOG.md` | <https://raw.githubusercontent.com/agentclientprotocol/agent-client-protocol/0c90706c45ad0ca15aedffc8870ab383c7430233/schema/v2/CHANGELOG.md> |

`schema.json` is the stable v2 schema (184 `$defs`). `schema.unstable.json` (221 `$defs`)
is vendored only for the `session/fork` definitions
(`ForkSessionRequest`, `ForkSessionResponse`, `SessionForkCapabilities`); per the v2
extensibility spec, negotiating `protocolVersion: 2` does **not** select the unstable
schema — there is no connection-wide unstable flag.

`UPSTREAM_CHANGELOG.md` is kept as a cross-check against the prose migration guide so
"what actually changed" is answerable without re-fetching.

## Updating

Never track `main`. Resolve the intended upstream commit explicitly, then re-download at
that SHA and update the pinned commit, upstream schema version, and vendor date above:

```bash
SHA=<full commit sha>
BASE=https://raw.githubusercontent.com/agentclientprotocol/agent-client-protocol
curl -fsSLO "$BASE/$SHA/schema/v2/schema.json"
curl -fsSLO "$BASE/$SHA/schema/v2/schema.unstable.json"
curl -fsSLO "$BASE/$SHA/schema/v2/CHANGELOG.md"
```

Check both files parse as JSON before committing, and diff `UPSTREAM_CHANGELOG.md` to see
what moved.
