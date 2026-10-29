defmodule ACP.V2.Initialization do
  @moduledoc """
  ACP v2 `initialize` types.

  v2 replaces v1's role-split fields (`clientInfo`/`clientCapabilities` and
  `agentInfo`/`agentCapabilities`) with role-agnostic `info` and `capabilities`
  keys whose shape depends on which side is sending them.

  Support-marker convention: every capability marker is an **object, not a
  boolean**. A key that is absent or `null` means unsupported; a present object -
  even `%{}` - means supported. Markers are kept as verbatim maps so nested
  extension fields (and `_meta`) survive round-trips untouched.
  """
end

# Implementation (shared by both roles)
defmodule ACP.V2.Implementation do
  @moduledoc """
  Metadata about a client or agent implementation (`info` in v2 initialize).
  """

  @enforce_keys [:name, :version]
  defstruct [:name, :title, :version, :meta]

  @type t :: %__MODULE__{
          name: String.t(),
          title: String.t() | nil,
          version: String.t(),
          meta: map() | nil
        }

  def new(name, version), do: %__MODULE__{name: name, version: version}

  def to_json(%__MODULE__{} = impl) do
    map = %{"name" => impl.name, "version" => impl.version}
    map = if impl.title, do: Map.put(map, "title", impl.title), else: map
    if impl.meta, do: Map.put(map, "_meta", impl.meta), else: map
  end

  def from_json(%{"name" => name, "version" => version} = map)
      when is_binary(name) and is_binary(version) do
    {:ok,
     %__MODULE__{
       name: name,
       version: version,
       title: map["title"],
       meta: map["_meta"]
     }}
  end

  def from_json(_), do: {:error, :invalid_implementation}
end

defimpl Jason.Encoder, for: ACP.V2.Implementation do
  def encode(val, opts), do: ACP.V2.Implementation.to_json(val) |> Jason.Encoder.encode(opts)
end

# Plain support markers (session/delete, additionalDirectories, prompt
# image/audio/embeddedContext, mcp stdio/http, auth terminal) are modeled as
# `nil | map()` per the v2 schema and need no dedicated structs.

# PromptCapabilities (nested under capabilities.session.prompt)
defmodule ACP.V2.PromptCapabilities do
  @moduledoc """
  Prompt content-type extensions the agent supports in `session/prompt`.

  Each marker is `nil` (unsupported) or a verbatim map (supported; `%{}` is the
  canonical "supported, no extras" form).
  """

  defstruct [:image, :audio, :embedded_context, :meta]

  @type marker :: map() | nil
  @type t :: %__MODULE__{
          image: marker(),
          audio: marker(),
          embedded_context: marker(),
          meta: marker()
        }

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = c) do
    ACP.V2.CapabilityHelpers.encode(
      image: c.image,
      audio: c.audio,
      embedded_context: c.embedded_context,
      meta: c.meta
    )
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       image: ACP.V2.CapabilityHelpers.marker(map["image"]),
       audio: ACP.V2.CapabilityHelpers.marker(map["audio"]),
       embedded_context: ACP.V2.CapabilityHelpers.marker(map["embeddedContext"]),
       meta: map["_meta"]
     }}
  end

  def from_json(_), do: {:error, :invalid_prompt_capabilities}
end

defimpl Jason.Encoder, for: ACP.V2.PromptCapabilities do
  def encode(val, opts), do: ACP.V2.PromptCapabilities.to_json(val) |> Jason.Encoder.encode(opts)
end

# McpCapabilities (nested under capabilities.session.mcp)
defmodule ACP.V2.McpCapabilities do
  @moduledoc """
  MCP server transports the agent supports for session lifecycle requests.
  """

  defstruct [:stdio, :http, :meta]

  @type t :: %__MODULE__{stdio: map() | nil, http: map() | nil, meta: map() | nil}

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = c) do
    ACP.V2.CapabilityHelpers.encode(stdio: c.stdio, http: c.http, meta: c.meta)
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       stdio: ACP.V2.CapabilityHelpers.marker(map["stdio"]),
       http: ACP.V2.CapabilityHelpers.marker(map["http"]),
       meta: map["_meta"]
     }}
  end

  def from_json(_), do: {:error, :invalid_mcp_capabilities}
end

defimpl Jason.Encoder, for: ACP.V2.McpCapabilities do
  def encode(val, opts), do: ACP.V2.McpCapabilities.to_json(val) |> Jason.Encoder.encode(opts)
end

# SessionCapabilities (nested under agent capabilities.session)
defmodule ACP.V2.SessionCapabilities do
  @moduledoc """
  Agent session-surface capabilities.

  A present `session` object with no nested markers means baseline session
  support; nested markers opt into extensions.
  """

  defstruct [:prompt, :mcp, :delete, :additional_directories, :meta]

  @type t :: %__MODULE__{
          prompt: ACP.V2.PromptCapabilities.t() | nil,
          mcp: ACP.V2.McpCapabilities.t() | nil,
          delete: map() | nil,
          additional_directories: map() | nil,
          meta: map() | nil
        }

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = c) do
    ACP.V2.CapabilityHelpers.encode(
      prompt: encode_opt(c.prompt, &ACP.V2.PromptCapabilities.to_json/1),
      mcp: encode_opt(c.mcp, &ACP.V2.McpCapabilities.to_json/1),
      delete: c.delete,
      additional_directories: c.additional_directories,
      meta: c.meta
    )
  end

  def from_json(map) when is_map(map) do
    with {:ok, prompt} <- decode_opt(map["prompt"], &ACP.V2.PromptCapabilities.from_json/1),
         {:ok, mcp} <- decode_opt(map["mcp"], &ACP.V2.McpCapabilities.from_json/1) do
      {:ok,
       %__MODULE__{
         prompt: prompt,
         mcp: mcp,
         delete: ACP.V2.CapabilityHelpers.marker(map["delete"]),
         additional_directories: ACP.V2.CapabilityHelpers.marker(map["additionalDirectories"]),
         meta: map["_meta"]
       }}
    end
  end

  def from_json(_), do: {:error, :invalid_session_capabilities}

  defp encode_opt(nil, _fun), do: nil
  defp encode_opt(value, fun), do: fun.(value)

  defp decode_opt(nil, _fun), do: {:ok, nil}
  defp decode_opt(value, _fun) when not is_map(value), do: {:ok, nil}
  defp decode_opt(value, fun), do: fun.(value)
end

defimpl Jason.Encoder, for: ACP.V2.SessionCapabilities do
  def encode(val, opts), do: ACP.V2.SessionCapabilities.to_json(val) |> Jason.Encoder.encode(opts)
end

# ClientAuthCapabilities
defmodule ACP.V2.ClientAuthCapabilities do
  @moduledoc """
  Client authentication-extension capabilities.

  `terminal` is a support marker: `{}` means the client can reproduce the agent
  invocation in an interactive terminal.
  """

  defstruct [:terminal, :meta]

  @type t :: %__MODULE__{terminal: map() | nil, meta: map() | nil}

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = c) do
    ACP.V2.CapabilityHelpers.encode(terminal: c.terminal, meta: c.meta)
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       terminal: ACP.V2.CapabilityHelpers.marker(map["terminal"]),
       meta: map["_meta"]
     }}
  end

  def from_json(_), do: {:error, :invalid_client_auth_capabilities}
end

defimpl Jason.Encoder, for: ACP.V2.ClientAuthCapabilities do
  def encode(val, opts) do
    ACP.V2.ClientAuthCapabilities.to_json(val) |> Jason.Encoder.encode(opts)
  end
end

# ElicitationCapabilities belongs to a later phase; it round-trips as a raw map.

# ClientCapabilities (client role side of `capabilities`)
defmodule ACP.V2.ClientCapabilities do
  @moduledoc "Capabilities advertised by the client in a v2 `initialize` request."

  defstruct [:auth, :elicitation, :meta]

  @type t :: %__MODULE__{
          auth: ACP.V2.ClientAuthCapabilities.t() | nil,
          elicitation: map() | nil,
          meta: map() | nil
        }

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = c) do
    ACP.V2.CapabilityHelpers.encode(
      auth: encode_opt(c.auth, &ACP.V2.ClientAuthCapabilities.to_json/1),
      elicitation: c.elicitation,
      meta: c.meta
    )
  end

  def from_json(map) when is_map(map) do
    with {:ok, auth} <- decode_opt(map["auth"], &ACP.V2.ClientAuthCapabilities.from_json/1) do
      {:ok,
       %__MODULE__{
         auth: auth,
         elicitation: ACP.V2.CapabilityHelpers.marker(map["elicitation"]),
         meta: map["_meta"]
       }}
    end
  end

  def from_json(_), do: {:error, :invalid_client_capabilities}

  defp encode_opt(nil, _fun), do: nil
  defp encode_opt(value, fun), do: fun.(value)

  defp decode_opt(nil, _fun), do: {:ok, nil}
  defp decode_opt(value, _fun) when not is_map(value), do: {:ok, nil}
  defp decode_opt(value, fun), do: fun.(value)
end

defimpl Jason.Encoder, for: ACP.V2.ClientCapabilities do
  def encode(val, opts), do: ACP.V2.ClientCapabilities.to_json(val) |> Jason.Encoder.encode(opts)
end

# AgentCapabilities (agent role side of `capabilities`)
defmodule ACP.V2.AgentCapabilities do
  @moduledoc """
  Capabilities advertised by the agent in a v2 `initialize` response.

  `session` gates the whole `session/*` surface: omitted or `null` means no
  session support; a present object means the baseline methods, with nested
  markers opting into extensions. `auth` carries authentication-related
  extensions and passes through as a raw map; the `auth/login`/`auth/logout`
  surface is advertised separately by a non-empty `authMethods` list and lands
  in a later phase.
  """

  defstruct [:session, :auth, :meta]

  @type t :: %__MODULE__{
          session: ACP.V2.SessionCapabilities.t() | nil,
          auth: map() | nil,
          meta: map() | nil
        }

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = c) do
    ACP.V2.CapabilityHelpers.encode(
      session: encode_opt(c.session, &ACP.V2.SessionCapabilities.to_json/1),
      auth: c.auth,
      meta: c.meta
    )
  end

  def from_json(map) when is_map(map) do
    with {:ok, session} <- decode_opt(map["session"], &ACP.V2.SessionCapabilities.from_json/1) do
      {:ok,
       %__MODULE__{
         session: session,
         auth: ACP.V2.CapabilityHelpers.marker(map["auth"]),
         meta: map["_meta"]
       }}
    end
  end

  def from_json(_), do: {:error, :invalid_agent_capabilities}

  defp encode_opt(nil, _fun), do: nil
  defp encode_opt(value, fun), do: fun.(value)

  defp decode_opt(nil, _fun), do: {:ok, nil}
  defp decode_opt(value, _fun) when not is_map(value), do: {:ok, nil}
  defp decode_opt(value, fun), do: fun.(value)
end

defimpl Jason.Encoder, for: ACP.V2.AgentCapabilities do
  def encode(val, opts), do: ACP.V2.AgentCapabilities.to_json(val) |> Jason.Encoder.encode(opts)
end

# Role dispatch for the shared `capabilities` key.
defmodule ACP.V2.Capabilities do
  @moduledoc """
  Role-aware decode/encode for the v2 `capabilities` field.

  v2 uses one wire key (`capabilities`) for both roles, so the decoded type
  depends on who is sending: `:client` decodes to `ACP.V2.ClientCapabilities`,
  `:agent` to `ACP.V2.AgentCapabilities`.
  """

  @doc "Decode a `capabilities` payload for the given role."
  def from_json(role, json) when role in [:client, :agent] do
    module(role).from_json(json || %{})
  end

  def from_json(_role, _json), do: {:error, :unknown_role}

  @doc "Encode a role's capability struct back to its JSON object."
  def to_json(role, value) when role in [:client, :agent] do
    module(role).to_json(value)
  end

  def to_json(_role, _value), do: {:error, :unknown_role}

  defp module(:client), do: ACP.V2.ClientCapabilities
  defp module(:agent), do: ACP.V2.AgentCapabilities
end

# Shared support-marker helpers.
defmodule ACP.V2.CapabilityHelpers do
  @moduledoc """
  Helpers for v2's object-shaped support markers.

  `nil`/absent means unsupported, a map (including `%{}`) means supported, and
  any other JSON type is treated as absent, matching the schema's
  `x-deserialize-default-on-error` convention.
  """

  @doc "Normalize a decoded support marker to `nil` or a verbatim map."
  def marker(nil), do: nil
  def marker(value) when is_map(value), do: value
  def marker(_other), do: nil

  @doc """
  Encode `field => value` pairs into a JSON object, emitting only non-nil values.

  Atom keys become camelCase; `:meta` maps to `"_meta"`.
  """
  def encode(fields) do
    fields
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.map(fn {k, v} -> {json_key(k), v} end)
    |> Map.new()
  end

  defp json_key(:meta), do: "_meta"
  defp json_key(key) when is_atom(key), do: ACP.JSONHelpers.to_camel_case(key)
end

# InitializeRequest (v2: required info, optional capabilities)
defmodule ACP.V2.InitializeRequest do
  @moduledoc """
  v2 `initialize` request from the client.

  Unlike v1, `info` is **required** and `capabilities` defaults to none when
  absent.
  """

  @enforce_keys [:protocol_version, :info]
  defstruct [:protocol_version, :info, :capabilities, :meta]

  @type t :: %__MODULE__{
          protocol_version: ACP.ProtocolVersion.t(),
          info: ACP.V2.Implementation.t(),
          capabilities: ACP.V2.ClientCapabilities.t() | nil,
          meta: map() | nil
        }

  def new(protocol_version, %ACP.V2.Implementation{} = info) do
    %__MODULE__{protocol_version: protocol_version, info: info}
  end

  def to_json(%__MODULE__{} = r) do
    map = %{
      "protocolVersion" => r.protocol_version,
      "info" => ACP.V2.Implementation.to_json(r.info)
    }

    map =
      if r.capabilities && r.capabilities != ACP.V2.ClientCapabilities.new() do
        Map.put(map, "capabilities", ACP.V2.ClientCapabilities.to_json(r.capabilities))
      else
        map
      end

    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"protocolVersion" => pv, "info" => info} = map) do
    with {:ok, version} <- ACP.ProtocolVersion.from_json(pv),
         {:ok, impl} <- ACP.V2.Implementation.from_json(info),
         {:ok, caps} <- decode_capabilities(map["capabilities"]) do
      {:ok,
       %__MODULE__{
         protocol_version: version,
         info: impl,
         capabilities: caps,
         meta: map["_meta"]
       }}
    end
  end

  def from_json(_), do: {:error, :invalid_initialize_request}

  defp decode_capabilities(nil), do: {:ok, ACP.V2.ClientCapabilities.new()}
  defp decode_capabilities(value), do: ACP.V2.ClientCapabilities.from_json(value)
end

defimpl Jason.Encoder, for: ACP.V2.InitializeRequest do
  def encode(val, opts), do: ACP.V2.InitializeRequest.to_json(val) |> Jason.Encoder.encode(opts)
end

# InitializeResponse (v2: required info, optional capabilities + authMethods)
defmodule ACP.V2.InitializeResponse do
  @moduledoc """
  v2 `initialize` response from the agent.

  `auth_methods` passes through as a list of raw maps: v2 makes `AuthMethod` a
  `type`-discriminated union, and unrecognized method types must be preserved
  verbatim by spec. The `auth/login`/`auth/logout` surface itself is a later
  phase. `nil` and `[]` are both valid on the wire and both mean "no auth
  surface"; decoding keeps them distinct so a peer's payload round-trips
  unchanged.
  """

  @enforce_keys [:protocol_version, :info]
  defstruct [:protocol_version, :info, :capabilities, :auth_methods, :meta]

  @type t :: %__MODULE__{
          protocol_version: ACP.ProtocolVersion.t(),
          info: ACP.V2.Implementation.t(),
          capabilities: ACP.V2.AgentCapabilities.t() | nil,
          auth_methods: [map()] | nil,
          meta: map() | nil
        }

  def new(protocol_version, %ACP.V2.Implementation{} = info) do
    %__MODULE__{protocol_version: protocol_version, info: info, auth_methods: []}
  end

  def to_json(%__MODULE__{} = r) do
    map = %{
      "protocolVersion" => r.protocol_version,
      "info" => ACP.V2.Implementation.to_json(r.info)
    }

    map =
      if r.capabilities && r.capabilities != ACP.V2.AgentCapabilities.new() do
        Map.put(map, "capabilities", ACP.V2.AgentCapabilities.to_json(r.capabilities))
      else
        map
      end

    map =
      if is_list(r.auth_methods), do: Map.put(map, "authMethods", r.auth_methods), else: map

    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"protocolVersion" => pv, "info" => info} = map) do
    with {:ok, version} <- ACP.ProtocolVersion.from_json(pv),
         {:ok, impl} <- ACP.V2.Implementation.from_json(info),
         {:ok, caps} <- decode_capabilities(map["capabilities"]) do
      {:ok,
       %__MODULE__{
         protocol_version: version,
         info: impl,
         capabilities: caps,
         auth_methods: auth_methods(map),
         meta: map["_meta"]
       }}
    end
  end

  def from_json(_), do: {:error, :invalid_initialize_response}

  defp decode_capabilities(nil), do: {:ok, ACP.V2.AgentCapabilities.new()}
  defp decode_capabilities(value), do: ACP.V2.AgentCapabilities.from_json(value)

  defp auth_methods(map) do
    case Map.get(map, "authMethods") do
      list when is_list(list) ->
        # `x-deserialize-skip-invalid-items`: drop non-object entries, keep the rest verbatim.
        Enum.filter(list, &is_map/1)

      _ ->
        nil
    end
  end
end

defimpl Jason.Encoder, for: ACP.V2.InitializeResponse do
  def encode(val, opts), do: ACP.V2.InitializeResponse.to_json(val) |> Jason.Encoder.encode(opts)
end
