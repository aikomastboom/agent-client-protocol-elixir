defmodule ACP do
  @moduledoc """
  Agent Client Protocol (ACP) for Elixir.

  A standardized protocol for communication between code editors (clients)
  and AI coding agents. This library provides the schema types, JSON-RPC
  primitives, behaviours, and connection management for building ACP-compliant
  clients and agents.

  ## Schema Types

  - `ACP.ProtocolVersion` - Protocol version negotiation
  - `ACP.Error` - JSON-RPC error codes and constructors
  - `ACP.V1.ContentBlock` - Content blocks (text, image, audio, resource)
  - `ACP.V1.Plan` / `ACP.V1.PlanEntry` - Execution plans
  - `ACP.V1.ToolCall` / `ACP.V1.ToolCallUpdate` - Tool call tracking

  ## Agent Types

  - `ACP.V1.InitializeRequest` / `ACP.V1.InitializeResponse`
  - `ACP.V1.AuthenticateRequest` / `ACP.V1.AuthenticateResponse`
  - `ACP.V1.NewSessionRequest` / `ACP.V1.NewSessionResponse`
  - `ACP.V1.LoadSessionRequest` / `ACP.V1.LoadSessionResponse`
  - `ACP.V1.SetSessionModeRequest` / `ACP.V1.SetSessionModeResponse`
  - `ACP.V1.PromptRequest` / `ACP.V1.PromptResponse`
  - `ACP.V1.CancelNotification`
  - `ACP.V1.AgentCapabilities` / `ACP.V1.SessionCapabilities`

  ## Client Types

  - `ACP.V1.SessionNotification` / `ACP.V1.SessionUpdate`
  - `ACP.V1.RequestPermissionRequest` / `ACP.V1.RequestPermissionResponse`
  - `ACP.V1.WriteTextFileRequest` / `ACP.V1.ReadTextFileRequest`
  - `ACP.V1.CreateTerminalRequest` / `ACP.V1.TerminalOutputRequest`
  - `ACP.V1.ClientCapabilities`

  ## Behaviours

  - `ACP.V1.Agent` - Agent behaviour (initialize, prompt, cancel, etc.)
  - `ACP.V1.Client` - Client behaviour (request_permission, session_notification, etc.)

  ## Connections

  - `ACP.Connection` - Low-level JSON-RPC GenServer
  - `ACP.V1.ClientSideConnection` - Client-side connection wrapper
  - `ACP.V1.AgentSideConnection` - Agent-side connection wrapper

  ## RPC

  - `ACP.RPC.Request` / `ACP.RPC.Response` / `ACP.RPC.Notification`
  - `ACP.RPC.JsonRpcMessage` - JSON-RPC 2.0 message wrapper
  - `ACP.V1.ClientSide` / `ACP.V1.AgentSide` - Side implementations for message decoding

  ## Stream Broadcast

  - `ACP.StreamBroadcast` - PubSub for observing RPC message streams
  - `ACP.StreamMessage` - Stream message struct
  """

  @type session_id :: String.t()
end
