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

## 0.2.0

- Renamed all ACP v1 protocol modules to the `ACP.V1` namespace in preparation for
  ACP v2 support. `ACP.*` is now reserved for version-agnostic shared infrastructure
  (`Connection`, `Error`, `MaybeUndefined`, `ProtocolVersion`, `RPC`, `StreamBroadcast`,
  `Ext*`, `MessageHandler`, `JSONHelpers`). This is a breaking change for any code
  referencing the old `ACP.*` type names directly; there are no compatibility aliases.
  No protocol behavior changed.
