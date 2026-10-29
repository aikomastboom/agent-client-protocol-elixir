# Changelog

## 0.3.0

- Vendored the ACP v2 JSON Schema (pinned commit, see `priv/schema/v2/SOURCE.md`) as the
  canonical reference for upcoming v2 support, alongside the upstream v2 changelog for
  cross-checking. `priv/` is now included in the package, so the schemas ship with the
  Hex artifact.
- Hardened `ACP.MaybeUndefined` patch semantics for v2 upserts: added `patch_map/2` for
  the `_meta` metadata patch rule (omit leaves stored metadata unchanged, `null` clears
  it, an object patches one top-level key at a time with no nested merging), `append_to/2`
  for chunk semantics that accumulate instead of replacing, and `from_json/2`, which
  decodes a non-conforming value as omitted rather than as a value.
- Added `ACP.ProtocolVersion.v2/0`. No wire-level or behavioral change yet;
  `ACP.ProtocolVersion.latest/0` still returns v1.
- Added `ACP.V2.Negotiation`: `select/2` picks the highest locally supported
  version at or below the peer's request and `check_selected/2` validates the
  version an agent chose, both rejecting malformed `protocolVersion` values with
  `-32602` and unsatisfiable requests with the spec's `-32022` plus structured
  `requested`/`supported` data.
- Added v2 `initialize` types: `ACP.V2.Implementation`,
  `ACP.V2.{Client,Agent}Capabilities`, `ACP.V2.SessionCapabilities`,
  `ACP.V2.PromptCapabilities`, `ACP.V2.McpCapabilities`,
  `ACP.V2.ClientAuthCapabilities`, `ACP.V2.Capabilities` (role dispatch for the
  single `capabilities` wire key), `ACP.V2.InitializeRequest` and
  `ACP.V2.InitializeResponse`. v2 capability markers are object-valued support
  markers, modelled as `nil | map()`, so a present `%{}` means supported and
  nested extension fields survive round-trips.
- `ACP.Connection` now negotiates once per connection: `initialize` params are
  read before any other field, the selected version is stored in connection
  state, and later messages are decoded by the matching side module. `ACP.V2.Side`
  plus `ACP.V2.{Agent,Client}Side` decode v2 traffic; v2 only implements
  `initialize` so far, and any other method answers `method_not_found`.
  Negotiation is opt-in via the new `:supported_versions` option, which defaults
  to v1 only, so existing connections behave exactly as before.
- Added `ACP.ProtocolVersion.supported/0` and `valid?/1`, and
  `ACP.Error.unsupported_protocol_version/2` for the `-32022` response shape.
  `latest/0` still returns v1: no v2 session surface is implemented yet.
- Test coverage for this work: `mix test --cover` total went 46.06% (pre-v2 baseline) to
  52.55%. The library has no coverage threshold configured, so the number is reported, not
  enforced.

## 0.2.0

- Renamed all ACP v1 protocol modules to the `ACP.V1` namespace in preparation for
  ACP v2 support. `ACP.*` is now reserved for version-agnostic shared infrastructure
  (`Connection`, `Error`, `MaybeUndefined`, `ProtocolVersion`, `RPC`, `StreamBroadcast`,
  `Ext*`, `MessageHandler`, `JSONHelpers`). This is a breaking change for any code
  referencing the old `ACP.*` type names directly; there are no compatibility aliases.
  No protocol behavior changed.
