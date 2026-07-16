defmodule ACP.AgentTypes do
  @moduledoc "Agent-side types for the Agent Client Protocol."
end

# Implementation struct
defmodule ACP.Implementation do
  @enforce_keys [:name, :version]
  defstruct [:name, :title, :version, :meta]

  def new(name, version), do: %__MODULE__{name: name, version: version}

  def to_json(%__MODULE__{} = impl) do
    map = %{"name" => impl.name, "version" => impl.version}
    map = if impl.title, do: Map.put(map, "title", impl.title), else: map
    if impl.meta, do: Map.put(map, "_meta", impl.meta), else: map
  end

  def from_json(%{"name" => name, "version" => version} = map) do
    {:ok,
     %__MODULE__{
       name: name,
       version: version,
       title: Map.get(map, "title"),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.Implementation do
  def encode(val, opts), do: ACP.Implementation.to_json(val) |> Jason.Encoder.encode(opts)
end

# AuthMethod
defmodule ACP.AuthMethod do
  @enforce_keys [:id, :name]
  defstruct [:id, :name, :description, :meta]

  def new(id, name), do: %__MODULE__{id: id, name: name}

  def to_json(%__MODULE__{} = m) do
    map = %{"id" => m.id, "name" => m.name}
    map = if m.description, do: Map.put(map, "description", m.description), else: map
    if m.meta, do: Map.put(map, "_meta", m.meta), else: map
  end

  def from_json(%{"id" => id, "name" => name} = map) do
    {:ok,
     %__MODULE__{
       id: id,
       name: name,
       description: Map.get(map, "description"),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.AuthMethod do
  def encode(val, opts), do: ACP.AuthMethod.to_json(val) |> Jason.Encoder.encode(opts)
end

# InitializeRequest
defmodule ACP.InitializeRequest do
  @enforce_keys [:protocol_version]
  defstruct [:protocol_version, :client_capabilities, :client_info, :meta]

  def new(protocol_version) do
    %__MODULE__{
      protocol_version: protocol_version,
      client_capabilities: ACP.ClientCapabilities.new()
    }
  end

  def to_json(%__MODULE__{} = r) do
    map = %{"protocolVersion" => r.protocol_version}

    map =
      if r.client_capabilities && r.client_capabilities != ACP.ClientCapabilities.new(),
        do:
          Map.put(
            map,
            "clientCapabilities",
            ACP.ClientCapabilities.to_json(r.client_capabilities)
          ),
        else: map

    map =
      if r.client_info,
        do: Map.put(map, "clientInfo", ACP.Implementation.to_json(r.client_info)),
        else: map

    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"protocolVersion" => pv} = map) do
    {:ok, pv} = ACP.ProtocolVersion.from_json(pv)

    client_info =
      case Map.get(map, "clientInfo") do
        nil ->
          nil

        ci ->
          {:ok, val} = ACP.Implementation.from_json(ci)
          val
      end

    {:ok,
     %__MODULE__{
       protocol_version: pv,
       client_capabilities:
         case Map.get(map, "clientCapabilities") do
           nil ->
             ACP.ClientCapabilities.new()

           cc ->
             {:ok, val} = ACP.ClientCapabilities.from_json(cc)
             val
         end,
       client_info: client_info,
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.InitializeRequest do
  def encode(val, opts), do: ACP.InitializeRequest.to_json(val) |> Jason.Encoder.encode(opts)
end

# InitializeResponse
defmodule ACP.InitializeResponse do
  @enforce_keys [:protocol_version]
  defstruct [:protocol_version, :agent_capabilities, :auth_methods, :agent_info, :meta]

  def new(protocol_version) do
    %__MODULE__{
      protocol_version: protocol_version,
      agent_capabilities: ACP.AgentCapabilities.new(),
      auth_methods: []
    }
  end

  def to_json(%__MODULE__{} = r) do
    map = %{"protocolVersion" => r.protocol_version}

    map =
      if r.agent_capabilities && r.agent_capabilities != ACP.AgentCapabilities.new(),
        do:
          Map.put(map, "agentCapabilities", ACP.AgentCapabilities.to_json(r.agent_capabilities)),
        else: map

    map =
      if r.auth_methods && r.auth_methods != [],
        do: Map.put(map, "authMethods", Enum.map(r.auth_methods, &ACP.AuthMethod.to_json/1)),
        else: map

    map =
      if r.agent_info,
        do: Map.put(map, "agentInfo", ACP.Implementation.to_json(r.agent_info)),
        else: map

    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"protocolVersion" => pv} = map) do
    {:ok, pv} = ACP.ProtocolVersion.from_json(pv)

    {:ok,
     %__MODULE__{
       protocol_version: pv,
       agent_capabilities:
         case Map.get(map, "agentCapabilities") do
           nil ->
             ACP.AgentCapabilities.new()

           ac ->
             {:ok, val} = ACP.AgentCapabilities.from_json(ac)
             val
         end,
       auth_methods:
         Map.get(map, "authMethods", [])
         |> Enum.map(fn am ->
           {:ok, v} = ACP.AuthMethod.from_json(am)
           v
         end),
       agent_info:
         case Map.get(map, "agentInfo") do
           nil ->
             nil

           ai ->
             {:ok, val} = ACP.Implementation.from_json(ai)
             val
         end,
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.InitializeResponse do
  def encode(val, opts), do: ACP.InitializeResponse.to_json(val) |> Jason.Encoder.encode(opts)
end

# AuthenticateRequest
defmodule ACP.AuthenticateRequest do
  @enforce_keys [:method_id]
  defstruct [:method_id, :meta]

  def new(method_id), do: %__MODULE__{method_id: method_id}

  def to_json(%__MODULE__{} = r) do
    map = %{"methodId" => r.method_id}
    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"methodId" => mid} = map) do
    {:ok, %__MODULE__{method_id: mid, meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.AuthenticateRequest do
  def encode(val, opts), do: ACP.AuthenticateRequest.to_json(val) |> Jason.Encoder.encode(opts)
end

# AuthenticateResponse
defmodule ACP.AuthenticateResponse do
  defstruct [:meta]

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = r) do
    if r.meta, do: %{"_meta" => r.meta}, else: %{}
  end

  def from_json(map) when is_map(map) do
    {:ok, %__MODULE__{meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.AuthenticateResponse do
  def encode(val, opts), do: ACP.AuthenticateResponse.to_json(val) |> Jason.Encoder.encode(opts)
end

# NewSessionRequest
defmodule ACP.NewSessionRequest do
  @enforce_keys [:cwd]
  defstruct [:cwd, :mcp_servers, :meta]

  def new(cwd), do: %__MODULE__{cwd: cwd, mcp_servers: []}

  def to_json(%__MODULE__{} = r) do
    map = %{"cwd" => r.cwd}

    map =
      if r.mcp_servers && r.mcp_servers != [],
        do: Map.put(map, "mcpServers", Enum.map(r.mcp_servers, &ACP.McpServer.to_json/1)),
        else: Map.put(map, "mcpServers", [])

    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"cwd" => cwd} = map) do
    {:ok,
     %__MODULE__{
       cwd: cwd,
       mcp_servers:
         Map.get(map, "mcpServers", [])
         |> Enum.map(fn s ->
           {:ok, v} = ACP.McpServer.from_json(s)
           v
         end),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.NewSessionRequest do
  def encode(val, opts), do: ACP.NewSessionRequest.to_json(val) |> Jason.Encoder.encode(opts)
end

# NewSessionResponse
defmodule ACP.NewSessionResponse do
  @enforce_keys [:session_id]
  defstruct [:session_id, :modes, :models, :config_options, :meta]

  def new(session_id), do: %__MODULE__{session_id: session_id}

  def to_json(%__MODULE__{} = r) do
    map = %{"sessionId" => r.session_id}
    map = if r.modes, do: Map.put(map, "modes", ACP.SessionModeState.to_json(r.modes)), else: map

    map =
      if r.models,
        do: Map.put(map, "models", ACP.SessionModelState.to_json(r.models)),
        else: map

    map =
      if r.config_options,
        do:
          Map.put(
            map,
            "configOptions",
            Enum.map(r.config_options, &ACP.SessionConfigOption.to_json/1)
          ),
        else: map

    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"sessionId" => sid} = map) do
    {:ok,
     %__MODULE__{
       session_id: sid,
       modes:
         case Map.get(map, "modes") do
           nil ->
             nil

           m ->
             {:ok, val} = ACP.SessionModeState.from_json(m)
             val
         end,
       models:
         case Map.get(map, "models") do
           nil ->
             nil

           m ->
             {:ok, val} = ACP.SessionModelState.from_json(m)
             val
         end,
       config_options:
         case Map.get(map, "configOptions") do
           nil ->
             nil

           opts ->
             Enum.map(opts, fn o ->
               {:ok, v} = ACP.SessionConfigOption.from_json(o)
               v
             end)
         end,
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.NewSessionResponse do
  def encode(val, opts), do: ACP.NewSessionResponse.to_json(val) |> Jason.Encoder.encode(opts)
end

# LoadSessionRequest
defmodule ACP.LoadSessionRequest do
  @enforce_keys [:session_id, :cwd]
  defstruct [:session_id, :cwd, :mcp_servers, :meta]

  def new(session_id, cwd), do: %__MODULE__{session_id: session_id, cwd: cwd, mcp_servers: []}

  def to_json(%__MODULE__{} = r) do
    map = %{"sessionId" => r.session_id, "cwd" => r.cwd}
    map = Map.put(map, "mcpServers", Enum.map(r.mcp_servers || [], &ACP.McpServer.to_json/1))
    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"sessionId" => sid, "cwd" => cwd} = map) do
    {:ok,
     %__MODULE__{
       session_id: sid,
       cwd: cwd,
       mcp_servers:
         Map.get(map, "mcpServers", [])
         |> Enum.map(fn s ->
           {:ok, v} = ACP.McpServer.from_json(s)
           v
         end),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.LoadSessionRequest do
  def encode(val, opts), do: ACP.LoadSessionRequest.to_json(val) |> Jason.Encoder.encode(opts)
end

# LoadSessionResponse
defmodule ACP.LoadSessionResponse do
  defstruct [:modes, :models, :config_options, :meta]

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = r) do
    map = %{}
    map = if r.modes, do: Map.put(map, "modes", ACP.SessionModeState.to_json(r.modes)), else: map

    map =
      if r.models,
        do: Map.put(map, "models", ACP.SessionModelState.to_json(r.models)),
        else: map

    map =
      if r.config_options,
        do:
          Map.put(
            map,
            "configOptions",
            Enum.map(r.config_options, &ACP.SessionConfigOption.to_json/1)
          ),
        else: map

    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       modes:
         case Map.get(map, "modes") do
           nil ->
             nil

           m ->
             {:ok, val} = ACP.SessionModeState.from_json(m)
             val
         end,
       models:
         case Map.get(map, "models") do
           nil ->
             nil

           m ->
             {:ok, val} = ACP.SessionModelState.from_json(m)
             val
         end,
       config_options:
         case Map.get(map, "configOptions") do
           nil ->
             nil

           opts ->
             Enum.map(opts, fn o ->
               {:ok, v} = ACP.SessionConfigOption.from_json(o)
               v
             end)
         end,
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.LoadSessionResponse do
  def encode(val, opts), do: ACP.LoadSessionResponse.to_json(val) |> Jason.Encoder.encode(opts)
end

# SessionModeState
defmodule ACP.SessionModeState do
  @enforce_keys [:current_mode_id, :available_modes]
  defstruct [:current_mode_id, :available_modes, :meta]

  def new(current_mode_id, available_modes) do
    %__MODULE__{current_mode_id: current_mode_id, available_modes: available_modes}
  end

  def to_json(%__MODULE__{} = s) do
    map = %{
      "currentModeId" => s.current_mode_id,
      "availableModes" => Enum.map(s.available_modes, &ACP.SessionMode.to_json/1)
    }

    if s.meta, do: Map.put(map, "_meta", s.meta), else: map
  end

  def from_json(%{"currentModeId" => cmid, "availableModes" => modes} = map) do
    {:ok,
     %__MODULE__{
       current_mode_id: cmid,
       available_modes:
         Enum.map(modes, fn m ->
           {:ok, v} = ACP.SessionMode.from_json(m)
           v
         end),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.SessionModeState do
  def encode(val, opts), do: ACP.SessionModeState.to_json(val) |> Jason.Encoder.encode(opts)
end

# SessionMode
defmodule ACP.SessionMode do
  @enforce_keys [:id, :name]
  defstruct [:id, :name, :description, :meta]

  def new(id, name), do: %__MODULE__{id: id, name: name}

  def to_json(%__MODULE__{} = m) do
    map = %{"id" => m.id, "name" => m.name}
    map = if m.description, do: Map.put(map, "description", m.description), else: map
    if m.meta, do: Map.put(map, "_meta", m.meta), else: map
  end

  def from_json(%{"id" => id, "name" => name} = map) do
    {:ok,
     %__MODULE__{
       id: id,
       name: name,
       description: Map.get(map, "description"),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.SessionMode do
  def encode(val, opts), do: ACP.SessionMode.to_json(val) |> Jason.Encoder.encode(opts)
end

# SetSessionModeRequest
defmodule ACP.SetSessionModeRequest do
  @enforce_keys [:session_id, :mode_id]
  defstruct [:session_id, :mode_id, :meta]

  def new(session_id, mode_id), do: %__MODULE__{session_id: session_id, mode_id: mode_id}

  def to_json(%__MODULE__{} = r) do
    map = %{"sessionId" => r.session_id, "modeId" => r.mode_id}
    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"sessionId" => sid, "modeId" => mid} = map) do
    {:ok, %__MODULE__{session_id: sid, mode_id: mid, meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.SetSessionModeRequest do
  def encode(val, opts), do: ACP.SetSessionModeRequest.to_json(val) |> Jason.Encoder.encode(opts)
end

# SetSessionModeResponse
defmodule ACP.SetSessionModeResponse do
  defstruct [:meta]

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = r) do
    if r.meta, do: %{"_meta" => r.meta}, else: %{}
  end

  def from_json(map) when is_map(map) do
    {:ok, %__MODULE__{meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.SetSessionModeResponse do
  def encode(val, opts), do: ACP.SetSessionModeResponse.to_json(val) |> Jason.Encoder.encode(opts)
end

# PromptRequest
defmodule ACP.PromptRequest do
  @enforce_keys [:session_id, :prompt]
  defstruct [:session_id, :prompt, :meta]

  def new(session_id, prompt), do: %__MODULE__{session_id: session_id, prompt: prompt}

  def to_json(%__MODULE__{} = r) do
    map = %{
      "sessionId" => r.session_id,
      "prompt" => Enum.map(r.prompt, &ACP.ContentBlock.to_json/1)
    }

    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"sessionId" => sid, "prompt" => prompt} = map) do
    {:ok,
     %__MODULE__{
       session_id: sid,
       prompt:
         Enum.map(prompt, fn cb ->
           {:ok, v} = ACP.ContentBlock.from_json(cb)
           v
         end),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.PromptRequest do
  def encode(val, opts), do: ACP.PromptRequest.to_json(val) |> Jason.Encoder.encode(opts)
end

# PromptResponse
defmodule ACP.PromptResponse do
  @enforce_keys [:stop_reason]
  defstruct [:stop_reason, :meta]

  def new(stop_reason), do: %__MODULE__{stop_reason: stop_reason}

  def to_json(%__MODULE__{} = r) do
    map = %{"stopReason" => ACP.StopReason.to_json(r.stop_reason)}
    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"stopReason" => sr} = map) do
    {:ok,
     %__MODULE__{
       stop_reason: ACP.StopReason.from_json(sr),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.PromptResponse do
  def encode(val, opts), do: ACP.PromptResponse.to_json(val) |> Jason.Encoder.encode(opts)
end

# StopReason
defmodule ACP.StopReason do
  @type t :: :end_turn | :max_tokens | :max_turn_requests | :refusal | :cancelled

  def to_json(:end_turn), do: "end_turn"
  def to_json(:max_tokens), do: "max_tokens"
  def to_json(:max_turn_requests), do: "max_turn_requests"
  def to_json(:refusal), do: "refusal"
  def to_json(:cancelled), do: "cancelled"

  def from_json("end_turn"), do: :end_turn
  def from_json("max_tokens"), do: :max_tokens
  def from_json("max_turn_requests"), do: :max_turn_requests
  def from_json("refusal"), do: :refusal
  def from_json("cancelled"), do: :cancelled
end

# CancelNotification
defmodule ACP.CancelNotification do
  @enforce_keys [:session_id]
  defstruct [:session_id, :meta]

  def new(session_id), do: %__MODULE__{session_id: session_id}

  def to_json(%__MODULE__{} = r) do
    map = %{"sessionId" => r.session_id}
    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"sessionId" => sid} = map) do
    {:ok, %__MODULE__{session_id: sid, meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.CancelNotification do
  def encode(val, opts), do: ACP.CancelNotification.to_json(val) |> Jason.Encoder.encode(opts)
end

# CloseSessionRequest
defmodule ACP.CloseSessionRequest do
  @enforce_keys [:session_id]
  defstruct [:session_id, :meta]

  def new(session_id), do: %__MODULE__{session_id: session_id}

  def to_json(%__MODULE__{} = r) do
    map = %{"sessionId" => r.session_id}
    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"sessionId" => sid} = map) do
    {:ok, %__MODULE__{session_id: sid, meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.CloseSessionRequest do
  def encode(val, opts), do: ACP.CloseSessionRequest.to_json(val) |> Jason.Encoder.encode(opts)
end

# CloseSessionResponse
defmodule ACP.CloseSessionResponse do
  defstruct [:meta]

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = r) do
    if r.meta, do: %{"_meta" => r.meta}, else: %{}
  end

  def from_json(map) when is_map(map) do
    {:ok, %__MODULE__{meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.CloseSessionResponse do
  def encode(val, opts), do: ACP.CloseSessionResponse.to_json(val) |> Jason.Encoder.encode(opts)
end

# AgentCapabilities
defmodule ACP.AgentCapabilities do
  defstruct load_session: false,
            prompt_capabilities: nil,
            mcp_capabilities: nil,
            session_capabilities: nil,
            meta: nil

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = c) do
    map = %{"loadSession" => c.load_session}

    map =
      if c.prompt_capabilities,
        do:
          Map.put(
            map,
            "promptCapabilities",
            ACP.PromptCapabilities.to_json(c.prompt_capabilities)
          ),
        else: map

    map =
      if c.mcp_capabilities,
        do: Map.put(map, "mcpCapabilities", ACP.McpCapabilities.to_json(c.mcp_capabilities)),
        else: map

    map =
      if c.session_capabilities,
        do:
          Map.put(
            map,
            "sessionCapabilities",
            ACP.SessionCapabilities.to_json(c.session_capabilities)
          ),
        else: map

    if c.meta, do: Map.put(map, "_meta", c.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       load_session: Map.get(map, "loadSession", false),
       prompt_capabilities:
         case Map.get(map, "promptCapabilities") do
           nil ->
             nil

           pc ->
             {:ok, v} = ACP.PromptCapabilities.from_json(pc)
             v
         end,
       mcp_capabilities:
         case Map.get(map, "mcpCapabilities") do
           nil ->
             nil

           mc ->
             {:ok, v} = ACP.McpCapabilities.from_json(mc)
             v
         end,
       session_capabilities:
         case Map.get(map, "sessionCapabilities") do
           nil ->
             nil

           sc ->
             {:ok, v} = ACP.SessionCapabilities.from_json(sc)
             v
         end,
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.AgentCapabilities do
  def encode(val, opts), do: ACP.AgentCapabilities.to_json(val) |> Jason.Encoder.encode(opts)
end

# PromptCapabilities
defmodule ACP.PromptCapabilities do
  defstruct image: false,
            audio: false,
            embedded_context: false,
            meta: nil

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = c) do
    map = %{"image" => c.image, "audio" => c.audio, "embeddedContext" => c.embedded_context}
    if c.meta, do: Map.put(map, "_meta", c.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       image: Map.get(map, "image", false),
       audio: Map.get(map, "audio", false),
       embedded_context: Map.get(map, "embeddedContext", false),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.PromptCapabilities do
  def encode(val, opts), do: ACP.PromptCapabilities.to_json(val) |> Jason.Encoder.encode(opts)
end

# McpCapabilities
defmodule ACP.McpCapabilities do
  defstruct http: false,
            sse: false,
            meta: nil

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = c) do
    map = %{"http" => c.http, "sse" => c.sse}
    if c.meta, do: Map.put(map, "_meta", c.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       http: Map.get(map, "http", false),
       sse: Map.get(map, "sse", false),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.McpCapabilities do
  def encode(val, opts), do: ACP.McpCapabilities.to_json(val) |> Jason.Encoder.encode(opts)
end

# SessionCapabilities
defmodule ACP.SessionCapabilities do
  defstruct modes: false,
            list: nil,
            fork: nil,
            resume: nil,
            close: nil,
            meta: nil

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = c) do
    map = %{"modes" => c.modes}

    map =
      if c.list,
        do: Map.put(map, "list", ACP.SessionListCapabilities.to_json(c.list)),
        else: map

    map =
      if c.fork,
        do: Map.put(map, "fork", ACP.SessionForkCapabilities.to_json(c.fork)),
        else: map

    map =
      if c.resume,
        do: Map.put(map, "resume", ACP.SessionResumeCapabilities.to_json(c.resume)),
        else: map

    map =
      if c.close,
        do: Map.put(map, "close", ACP.SessionCloseCapabilities.to_json(c.close)),
        else: map

    if c.meta, do: Map.put(map, "_meta", c.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       modes: Map.get(map, "modes", false),
       list:
         case Map.get(map, "list") do
           nil ->
             nil

           l ->
             {:ok, v} = ACP.SessionListCapabilities.from_json(l)
             v
         end,
       fork:
         case Map.get(map, "fork") do
           nil ->
             nil

           f ->
             {:ok, v} = ACP.SessionForkCapabilities.from_json(f)
             v
         end,
       resume:
         case Map.get(map, "resume") do
           nil ->
             nil

           r ->
             {:ok, v} = ACP.SessionResumeCapabilities.from_json(r)
             v
         end,
       close:
         case Map.get(map, "close") do
           nil ->
             nil

           c ->
             {:ok, v} = ACP.SessionCloseCapabilities.from_json(c)
             v
         end,
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.SessionCapabilities do
  def encode(val, opts), do: ACP.SessionCapabilities.to_json(val) |> Jason.Encoder.encode(opts)
end

# McpServer - tagged union: Http, Sse (tagged by "type"), Stdio (untagged)
defmodule ACP.McpServer do
  @type t ::
          {:http, ACP.McpServerHttp.t()}
          | {:sse, ACP.McpServerSse.t()}
          | {:stdio, ACP.McpServerStdio.t()}

  def to_json({:http, server}), do: Map.put(ACP.McpServerHttp.to_json(server), "type", "http")
  def to_json({:sse, server}), do: Map.put(ACP.McpServerSse.to_json(server), "type", "sse")
  def to_json({:stdio, server}), do: ACP.McpServerStdio.to_json(server)

  def from_json(%{"type" => "http"} = map),
    do: {:ok, {:http, elem(ACP.McpServerHttp.from_json(map), 1)}}

  def from_json(%{"type" => "sse"} = map),
    do: {:ok, {:sse, elem(ACP.McpServerSse.from_json(map), 1)}}

  def from_json(map) when is_map(map),
    do: {:ok, {:stdio, elem(ACP.McpServerStdio.from_json(map), 1)}}
end

# McpServerHttp
defmodule ACP.McpServerHttp do
  @enforce_keys [:name, :url]
  defstruct [:name, :url, :headers, :meta]

  @type t :: %__MODULE__{}

  def new(name, url), do: %__MODULE__{name: name, url: url, headers: []}

  def to_json(%__MODULE__{} = s) do
    map = %{
      "name" => s.name,
      "url" => s.url,
      "headers" => Enum.map(s.headers || [], &ACP.HttpHeader.to_json/1)
    }

    if s.meta, do: Map.put(map, "_meta", s.meta), else: map
  end

  def from_json(%{"name" => name, "url" => url} = map) do
    {:ok,
     %__MODULE__{
       name: name,
       url: url,
       headers:
         Map.get(map, "headers", [])
         |> Enum.map(fn h ->
           {:ok, v} = ACP.HttpHeader.from_json(h)
           v
         end),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.McpServerHttp do
  def encode(val, opts),
    do: Map.put(ACP.McpServerHttp.to_json(val), "type", "http") |> Jason.Encoder.encode(opts)
end

# McpServerSse
defmodule ACP.McpServerSse do
  @enforce_keys [:name, :url]
  defstruct [:name, :url, :headers, :meta]

  @type t :: %__MODULE__{}

  def new(name, url), do: %__MODULE__{name: name, url: url, headers: []}

  def to_json(%__MODULE__{} = s) do
    map = %{
      "name" => s.name,
      "url" => s.url,
      "headers" => Enum.map(s.headers || [], &ACP.HttpHeader.to_json/1)
    }

    if s.meta, do: Map.put(map, "_meta", s.meta), else: map
  end

  def from_json(%{"name" => name, "url" => url} = map) do
    {:ok,
     %__MODULE__{
       name: name,
       url: url,
       headers:
         Map.get(map, "headers", [])
         |> Enum.map(fn h ->
           {:ok, v} = ACP.HttpHeader.from_json(h)
           v
         end),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.McpServerSse do
  def encode(val, opts),
    do: Map.put(ACP.McpServerSse.to_json(val), "type", "sse") |> Jason.Encoder.encode(opts)
end

# McpServerStdio
defmodule ACP.McpServerStdio do
  @enforce_keys [:name, :command]
  defstruct [:name, :command, :args, :env, :meta]

  @type t :: %__MODULE__{}

  def new(name, command), do: %__MODULE__{name: name, command: command, args: [], env: []}

  def to_json(%__MODULE__{} = s) do
    map = %{
      "name" => s.name,
      "command" => s.command,
      "args" => s.args || [],
      "env" => Enum.map(s.env || [], &ACP.EnvVariable.to_json/1)
    }

    if s.meta, do: Map.put(map, "_meta", s.meta), else: map
  end

  def from_json(%{"name" => name, "command" => command} = map) do
    {:ok,
     %__MODULE__{
       name: name,
       command: command,
       args: Map.get(map, "args", []),
       env:
         Map.get(map, "env", [])
         |> Enum.map(fn e ->
           {:ok, v} = ACP.EnvVariable.from_json(e)
           v
         end),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.McpServerStdio do
  def encode(val, opts), do: ACP.McpServerStdio.to_json(val) |> Jason.Encoder.encode(opts)
end

# EnvVariable
defmodule ACP.EnvVariable do
  @enforce_keys [:name, :value]
  defstruct [:name, :value, :meta]

  def new(name, value), do: %__MODULE__{name: name, value: value}

  def to_json(%__MODULE__{} = e) do
    map = %{"name" => e.name, "value" => e.value}
    if e.meta, do: Map.put(map, "_meta", e.meta), else: map
  end

  def from_json(%{"name" => name, "value" => value} = map) do
    {:ok, %__MODULE__{name: name, value: value, meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.EnvVariable do
  def encode(val, opts), do: ACP.EnvVariable.to_json(val) |> Jason.Encoder.encode(opts)
end

# HttpHeader
defmodule ACP.HttpHeader do
  @enforce_keys [:name, :value]
  defstruct [:name, :value, :meta]

  def new(name, value), do: %__MODULE__{name: name, value: value}

  def to_json(%__MODULE__{} = h) do
    map = %{"name" => h.name, "value" => h.value}
    if h.meta, do: Map.put(map, "_meta", h.meta), else: map
  end

  def from_json(%{"name" => name, "value" => value} = map) do
    {:ok, %__MODULE__{name: name, value: value, meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.HttpHeader do
  def encode(val, opts), do: ACP.HttpHeader.to_json(val) |> Jason.Encoder.encode(opts)
end

# ClientRequest enum (for routing)
defmodule ACP.ClientRequest do
  @type t ::
          {:initialize, ACP.InitializeRequest.t()}
          | {:authenticate, ACP.AuthenticateRequest.t()}
          | {:new_session, ACP.NewSessionRequest.t()}
          | {:load_session, ACP.LoadSessionRequest.t()}
          | {:list_sessions, ACP.ListSessionsRequest.t()}
          | {:fork_session, ACP.ForkSessionRequest.t()}
          | {:resume_session, ACP.ResumeSessionRequest.t()}
          | {:set_session_mode, ACP.SetSessionModeRequest.t()}
          | {:set_session_config_option, ACP.SetSessionConfigOptionRequest.t()}
          | {:prompt, ACP.PromptRequest.t()}
          | {:set_session_model, ACP.SetSessionModelRequest.t()}
          | {:ext_method, ACP.ExtRequest.t()}

  def method({:initialize, _}), do: "initialize"
  def method({:authenticate, _}), do: "authenticate"
  def method({:new_session, _}), do: "session/new"
  def method({:load_session, _}), do: "session/load"
  def method({:list_sessions, _}), do: "session/list"
  def method({:fork_session, _}), do: "session/fork"
  def method({:resume_session, _}), do: "session/resume"
  def method({:set_session_mode, _}), do: "session/set_mode"
  def method({:set_session_config_option, _}), do: "session/set_config_option"
  def method({:prompt, _}), do: "session/prompt"
  def method({:set_session_model, _}), do: "session/set_model"
  def method({:ext_method, req}), do: req.method
end

# AgentResponse enum (for routing)
defmodule ACP.AgentResponse do
  @type t ::
          {:initialize, ACP.InitializeResponse.t()}
          | {:authenticate, ACP.AuthenticateResponse.t()}
          | {:new_session, ACP.NewSessionResponse.t()}
          | {:load_session, ACP.LoadSessionResponse.t()}
          | {:list_sessions, ACP.ListSessionsResponse.t()}
          | {:fork_session, ACP.ForkSessionResponse.t()}
          | {:resume_session, ACP.ResumeSessionResponse.t()}
          | {:set_session_mode, ACP.SetSessionModeResponse.t()}
          | {:set_session_config_option, ACP.SetSessionConfigOptionResponse.t()}
          | {:prompt, ACP.PromptResponse.t()}
          | {:set_session_model, ACP.SetSessionModelResponse.t()}
          | {:ext_method, ACP.ExtResponse.t()}
end

# ClientNotification enum (for routing)
defmodule ACP.ClientNotification do
  @type t ::
          {:cancel, ACP.CancelNotification.t()}
          | {:ext_notification, ACP.ExtNotification.t()}

  def method({:cancel, _}), do: "session/cancel"
  def method({:ext_notification, notif}), do: notif.method
end
