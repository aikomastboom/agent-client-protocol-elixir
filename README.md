# Agent Client Protocol (ACP) for Elixir

Elixir implementation of the [Agent Client Protocol](https://agentclientprotocol.com/) — a standardized protocol for communication between code editors (clients) and AI coding agents over JSON-RPC 2.0.

This library is a port of the Rust [`agent-client-protocol`](https://crates.io/crates/agent-client-protocol) and [`agent-client-protocol-schema`](https://crates.io/crates/agent-client-protocol-schema) crates.

## Installation

Add `agent_client_protocol` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:agent_client_protocol, "~> 0.3.0"}
  ]
end
```

## Protocol versions

This library currently implements **ACP v1**. Protocol-version-specific modules live under the `ACP.V1.*` namespace; the bare `ACP.*` namespace is reserved for version-agnostic shared infrastructure (`Connection`, `Error`, `MaybeUndefined`, `ProtocolVersion`, `RPC`, `StreamBroadcast`, `Ext*`, `MessageHandler`, `JSONHelpers`). v2 support is landing incrementally - see `CHANGELOG.md`.

The canonical ACP v2 JSON Schema is vendored under `priv/schema/v2/`, pinned to a specific upstream commit (see `priv/schema/v2/SOURCE.md`). `ACP.ProtocolVersion.v2/0` exists so v2 can be named, but `latest/0` still returns v1: connections do not negotiate v2 yet.

## Overview

The library has two layers:

### Schema Types

All ACP message types with JSON serialization (`to_json/1` and `from_json/1`):

- **Content** — `ContentBlock`, `TextContent`, `ImageContent`, `AudioContent`, `ResourceLink`, `EmbeddedResource`
- **Tool Calls** — `ToolCall`, `ToolCallUpdate`, `ToolKind`, `ToolCallStatus`, `ToolCallContent`
- **Plans** — `Plan`, `PlanEntry`
- **Agent Types** — `InitializeRequest/Response`, `AuthenticateRequest/Response`, `NewSessionRequest/Response`, `LoadSessionRequest/Response`, `SetSessionModeRequest/Response`, `PromptRequest/Response`, `CancelNotification`
- **Client Types** — `SessionNotification`, `SessionUpdate`, `RequestPermissionRequest/Response`, `WriteTextFileRequest/Response`, `ReadTextFileRequest/Response`, terminal operations
- **Capabilities** — `AgentCapabilities`, `ClientCapabilities`, `SessionCapabilities`, `PromptCapabilities`, `McpCapabilities`
- **MCP Servers** — `McpServer` (tagged union: Stdio, Http, Sse)
- **Extensions** — `ExtRequest`, `ExtResponse`, `ExtNotification`
- **Unstable** — `SessionModelState`, `SessionConfigOption`, `ForkSessionRequest/Response`, `ResumeSessionRequest/Response`, `ListSessionsRequest/Response`, `ConfigOptionUpdate`, `SessionInfoUpdate`, `MaybeUndefined`

### SDK Layer

- **`ACP.V1.Agent`** — Behaviour for implementing an ACP agent with callbacks for `initialize`, `authenticate`, `new_session`, `prompt`, `cancel`, etc.
- **`ACP.V1.Client`** — Behaviour for implementing an ACP client with callbacks for `request_permission`, `session_notification`, file/terminal operations, etc.
- **`ACP.Connection`** — GenServer for bidirectional JSON-RPC 2.0 over IO streams with request/response correlation
- **`ACP.V1.ClientSideConnection`** / **`ACP.V1.AgentSideConnection`** — High-level connection wrappers
- **`ACP.V1.Side`** — Behaviour with `ClientSide`/`AgentSide` implementations for message routing and decoding
- **`ACP.StreamBroadcast`** — PubSub GenServer for observing protocol messages

## Usage

### Implementing an Agent

```elixir
defmodule MyAgent do
  use ACP.V1.Agent

  @impl true
  def initialize(request) do
    {:ok, ACP.V1.InitializeResponse.new(ACP.ProtocolVersion.v1())}
  end

  @impl true
  def authenticate(_request) do
    {:ok, ACP.V1.AuthenticateResponse.new()}
  end

  @impl true
  def new_session(request) do
    {:ok, ACP.V1.NewSessionResponse.new("session-#{System.unique_integer()}")}
  end

  @impl true
  def prompt(request) do
    # Process the prompt and send session updates...
    {:ok, ACP.V1.PromptResponse.new(:end_turn)}
  end

  @impl true
  def cancel(_notification), do: :ok
end
```

### Implementing a Client

```elixir
defmodule MyClient do
  use ACP.V1.Client

  @impl true
  def request_permission(request) do
    # Present permission options to the user...
    option = hd(request.options)
    {:ok, ACP.V1.RequestPermissionResponse.new({:selected, ACP.V1.SelectedPermissionOutcome.new(option.option_id)})}
  end

  @impl true
  def session_notification(notification) do
    IO.inspect(notification.update, label: "Session update")
    :ok
  end
end
```

### Working with Types

```elixir
# Create and serialize a content block
text = ACP.V1.TextContent.new("Hello, world!")
json = ACP.V1.ContentBlock.to_json({:text, text})
# => %{"type" => "text", "text" => "Hello, world!"}

# Deserialize
{:ok, {:text, decoded}} = ACP.V1.ContentBlock.from_json(json)

# Session updates
update = {:agent_message_chunk, ACP.V1.ContentChunk.new({:text, ACP.V1.TextContent.new("Hi")})}
json = ACP.V1.SessionUpdate.to_json(update)

# JSON-RPC messages
request = %ACP.RPC.Request{id: 1, method: "initialize", params: %{"protocolVersion" => 1}}
encoded = ACP.RPC.JsonRpcMessage.encode!(request)
```

### Patch Semantics

`ACP.MaybeUndefined` models a field that is omitted, explicitly `null`, or present. v2
upserts apply those three states as patches:

```elixir
# Whole-replace field: omit leaves it alone, null clears it, a value replaces it
ACP.MaybeUndefined.update_to(:undefined, "existing")  #=> "existing"
ACP.MaybeUndefined.update_to(nil, "existing")         #=> nil
ACP.MaybeUndefined.update_to({:value, "new"}, "x")    #=> "new"

# _meta metadata patch: one top-level key at a time, never nested merges
ACP.MaybeUndefined.patch_map(:undefined, %{"a" => 1})            #=> %{"a" => 1}
ACP.MaybeUndefined.patch_map(nil, %{"a" => 1})                   #=> nil
ACP.MaybeUndefined.patch_map({:value, %{"a" => nil}}, %{"a" => 1}) #=> nil

# Chunks accumulate instead of replacing
ACP.MaybeUndefined.append_to({:value, ["b"]}, ["a"]) #=> ["a", "b"]

# A malformed optional field decodes as omitted, so it cannot clobber stored data
ACP.MaybeUndefined.from_json("nope", &is_map/1) #=> :undefined
```

See `priv/schema/v2/SOURCE.md` for the vendored v2 schema this was written against.

## Protocol Compatibility

This library targets ACP schema version 0.10.6. All stable types are fully implemented. Unstable features (session fork/resume/list, model selection, config options) are included but may change with future protocol versions.

## License

MIT
