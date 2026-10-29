# Changelog

## 0.2.0

- Renamed all ACP v1 protocol modules to the `ACP.V1` namespace in preparation for
  ACP v2 support. `ACP.*` is now reserved for version-agnostic shared infrastructure
  (`Connection`, `Error`, `MaybeUndefined`, `ProtocolVersion`, `RPC`, `StreamBroadcast`,
  `Ext*`, `MessageHandler`, `JSONHelpers`). This is a breaking change for any code
  referencing the old `ACP.*` type names directly; there are no compatibility aliases.
  No protocol behavior changed.
