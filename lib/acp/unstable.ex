defmodule ACP.Unstable do
  @moduledoc """
  Unstable types that are not yet part of the ACP specification.

  These types correspond to Rust feature-gated types behind `#[cfg(feature = "unstable_*")]`.
  They may be removed or changed at any point.
  """
end

# --- Session Model Types ---

defmodule ACP.ModelInfo do
  @moduledoc "Information about a selectable model. (Unstable)"

  @enforce_keys [:model_id, :name]
  defstruct [:model_id, :name, :description, :meta]

  def new(model_id, name), do: %__MODULE__{model_id: model_id, name: name}

  def to_json(%__MODULE__{} = m) do
    map = %{"modelId" => m.model_id, "name" => m.name}
    map = if m.description, do: Map.put(map, "description", m.description), else: map
    if m.meta, do: Map.put(map, "_meta", m.meta), else: map
  end

  def from_json(%{"modelId" => mid, "name" => name} = map) do
    {:ok,
     %__MODULE__{
       model_id: mid,
       name: name,
       description: Map.get(map, "description"),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.ModelInfo do
  def encode(val, opts), do: ACP.ModelInfo.to_json(val) |> Jason.Encoder.encode(opts)
end

defmodule ACP.SessionModelState do
  @moduledoc "The set of models and the one currently active. (Unstable)"

  @enforce_keys [:current_model_id, :available_models]
  defstruct [:current_model_id, :available_models, :meta]

  def new(current_model_id, available_models) do
    %__MODULE__{current_model_id: current_model_id, available_models: available_models}
  end

  def to_json(%__MODULE__{} = s) do
    map = %{
      "currentModelId" => s.current_model_id,
      "availableModels" => Enum.map(s.available_models, &ACP.ModelInfo.to_json/1)
    }

    if s.meta, do: Map.put(map, "_meta", s.meta), else: map
  end

  def from_json(%{"currentModelId" => cmid, "availableModels" => models} = map) do
    {:ok,
     %__MODULE__{
       current_model_id: cmid,
       available_models:
         Enum.map(models, fn m ->
           {:ok, v} = ACP.ModelInfo.from_json(m)
           v
         end),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.SessionModelState do
  def encode(val, opts), do: ACP.SessionModelState.to_json(val) |> Jason.Encoder.encode(opts)
end

defmodule ACP.SetSessionModelRequest do
  @moduledoc "Request to set the model for a session. (Unstable)"

  @enforce_keys [:session_id, :model_id]
  defstruct [:session_id, :model_id, :meta]

  def new(session_id, model_id), do: %__MODULE__{session_id: session_id, model_id: model_id}

  def to_json(%__MODULE__{} = r) do
    map = %{"sessionId" => r.session_id, "modelId" => r.model_id}
    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"sessionId" => sid, "modelId" => mid} = map) do
    {:ok, %__MODULE__{session_id: sid, model_id: mid, meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.SetSessionModelRequest do
  def encode(val, opts), do: ACP.SetSessionModelRequest.to_json(val) |> Jason.Encoder.encode(opts)
end

defmodule ACP.SetSessionModelResponse do
  @moduledoc "Response to session/set_model. (Unstable)"

  defstruct [:meta]

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = r) do
    if r.meta, do: %{"_meta" => r.meta}, else: %{}
  end

  def from_json(map) when is_map(map) do
    {:ok, %__MODULE__{meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.SetSessionModelResponse do
  def encode(val, opts),
    do: ACP.SetSessionModelResponse.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Session Config Option Types ---

defmodule ACP.SessionConfigSelectOption do
  @moduledoc "A possible value for a session configuration option. (Unstable)"

  @enforce_keys [:value, :name]
  defstruct [:value, :name, :description, :meta]

  def new(value, name), do: %__MODULE__{value: value, name: name}

  def to_json(%__MODULE__{} = o) do
    map = %{"value" => o.value, "name" => o.name}
    map = if o.description, do: Map.put(map, "description", o.description), else: map
    if o.meta, do: Map.put(map, "_meta", o.meta), else: map
  end

  def from_json(%{"value" => value, "name" => name} = map) do
    {:ok,
     %__MODULE__{
       value: value,
       name: name,
       description: Map.get(map, "description"),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.SessionConfigSelectOption do
  def encode(val, opts),
    do: ACP.SessionConfigSelectOption.to_json(val) |> Jason.Encoder.encode(opts)
end

defmodule ACP.SessionConfigSelectGroup do
  @moduledoc "A group of possible values for a session configuration option. (Unstable)"

  @enforce_keys [:group, :name, :options]
  defstruct [:group, :name, :options, :meta]

  def new(group, name, options), do: %__MODULE__{group: group, name: name, options: options}

  def to_json(%__MODULE__{} = g) do
    map = %{
      "group" => g.group,
      "name" => g.name,
      "options" => Enum.map(g.options, &ACP.SessionConfigSelectOption.to_json/1)
    }

    if g.meta, do: Map.put(map, "_meta", g.meta), else: map
  end

  def from_json(%{"group" => group, "name" => name, "options" => options} = map) do
    {:ok,
     %__MODULE__{
       group: group,
       name: name,
       options:
         Enum.map(options, fn o ->
           {:ok, v} = ACP.SessionConfigSelectOption.from_json(o)
           v
         end),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.SessionConfigSelectGroup do
  def encode(val, opts),
    do: ACP.SessionConfigSelectGroup.to_json(val) |> Jason.Encoder.encode(opts)
end

defmodule ACP.SessionConfigSelectOptions do
  @moduledoc """
  Possible values for a session configuration option. (Unstable)

  Untagged union: either a flat list of options (ungrouped) or a list of groups.
  Represented as `{:ungrouped, [option]}` or `{:grouped, [group]}`.
  """

  @type t ::
          {:ungrouped, [ACP.SessionConfigSelectOption.t()]}
          | {:grouped, [ACP.SessionConfigSelectGroup.t()]}

  def to_json({:ungrouped, options}) do
    Enum.map(options, &ACP.SessionConfigSelectOption.to_json/1)
  end

  def to_json({:grouped, groups}) do
    Enum.map(groups, &ACP.SessionConfigSelectGroup.to_json/1)
  end

  def from_json([first | _] = list) when is_list(list) do
    if Map.has_key?(first, "group") do
      {:grouped,
       Enum.map(list, fn g ->
         {:ok, v} = ACP.SessionConfigSelectGroup.from_json(g)
         v
       end)}
    else
      {:ungrouped,
       Enum.map(list, fn o ->
         {:ok, v} = ACP.SessionConfigSelectOption.from_json(o)
         v
       end)}
    end
  end

  def from_json([]), do: {:ungrouped, []}
end

defmodule ACP.SessionConfigSelect do
  @moduledoc "A single-value selector (dropdown) session configuration option payload. (Unstable)"

  @enforce_keys [:current_value, :options]
  defstruct [:current_value, :options]

  def new(current_value, options), do: %__MODULE__{current_value: current_value, options: options}

  def to_json(%__MODULE__{} = s) do
    %{
      "currentValue" => s.current_value,
      "options" => ACP.SessionConfigSelectOptions.to_json(s.options)
    }
  end

  def from_json(%{"currentValue" => cv, "options" => opts}) do
    {:ok, %__MODULE__{current_value: cv, options: ACP.SessionConfigSelectOptions.from_json(opts)}}
  end
end

defimpl Jason.Encoder, for: ACP.SessionConfigSelect do
  def encode(val, opts), do: ACP.SessionConfigSelect.to_json(val) |> Jason.Encoder.encode(opts)
end

defmodule ACP.SessionConfigOptionCategory do
  @moduledoc "Semantic category for a session configuration option. (Unstable)"

  @type t :: :mode | :model | :thought_level | :other

  def to_json(:mode), do: "mode"
  def to_json(:model), do: "model"
  def to_json(:thought_level), do: "thought_level"
  def to_json(:other), do: "other"

  def from_json("mode"), do: :mode
  def from_json("model"), do: :model
  def from_json("thought_level"), do: :thought_level
  def from_json(_), do: :other
end

defmodule ACP.SessionConfigKind do
  @moduledoc """
  Type-specific session configuration option payload. (Unstable)

  Tagged union by "type" field. Currently only `:select`.
  """

  @type t :: {:select, ACP.SessionConfigSelect.t()}

  def to_json({:select, select}) do
    ACP.SessionConfigSelect.to_json(select) |> Map.put("type", "select")
  end

  def from_json(%{"type" => "select"} = map) do
    {:ok, val} = ACP.SessionConfigSelect.from_json(map)
    {:ok, {:select, val}}
  end
end

defmodule ACP.SessionConfigOption do
  @moduledoc "A session configuration option selector and its current state. (Unstable)"

  @enforce_keys [:id, :name, :kind]
  defstruct [:id, :name, :description, :category, :kind, :meta]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          description: String.t() | nil,
          category: term(),
          kind: term(),
          meta: map() | nil
        }

  def new(id, name, kind), do: %__MODULE__{id: id, name: name, kind: kind}

  def select(id, name, current_value, options) do
    new(id, name, {:select, ACP.SessionConfigSelect.new(current_value, options)})
  end

  def to_json(%__MODULE__{} = o) do
    # kind is flattened into the top-level map
    kind_map = ACP.SessionConfigKind.to_json(o.kind)
    map = Map.merge(kind_map, %{"id" => o.id, "name" => o.name})
    map = if o.description, do: Map.put(map, "description", o.description), else: map

    map =
      if o.category,
        do: Map.put(map, "category", ACP.SessionConfigOptionCategory.to_json(o.category)),
        else: map

    if o.meta, do: Map.put(map, "_meta", o.meta), else: map
  end

  def from_json(%{"id" => id, "name" => name} = map) do
    {:ok, kind} = ACP.SessionConfigKind.from_json(map)

    {:ok,
     %__MODULE__{
       id: id,
       name: name,
       description: Map.get(map, "description"),
       category:
         case Map.get(map, "category") do
           nil -> nil
           c -> ACP.SessionConfigOptionCategory.from_json(c)
         end,
       kind: kind,
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.SessionConfigOption do
  def encode(val, opts), do: ACP.SessionConfigOption.to_json(val) |> Jason.Encoder.encode(opts)
end

defmodule ACP.SetSessionConfigOptionRequest do
  @moduledoc "Request to set a session configuration option value. (Unstable)"

  @enforce_keys [:session_id, :config_id, :value]
  defstruct [:session_id, :config_id, :value, :meta]

  def new(session_id, config_id, value) do
    %__MODULE__{session_id: session_id, config_id: config_id, value: value}
  end

  def to_json(%__MODULE__{} = r) do
    map = %{"sessionId" => r.session_id, "configId" => r.config_id, "value" => r.value}
    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"sessionId" => sid, "configId" => cid, "value" => val} = map) do
    {:ok, %__MODULE__{session_id: sid, config_id: cid, value: val, meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.SetSessionConfigOptionRequest do
  def encode(val, opts),
    do: ACP.SetSessionConfigOptionRequest.to_json(val) |> Jason.Encoder.encode(opts)
end

defmodule ACP.SetSessionConfigOptionResponse do
  @moduledoc "Response to session/set_config_option. (Unstable)"

  @enforce_keys [:config_options]
  defstruct [:config_options, :meta]

  def new(config_options), do: %__MODULE__{config_options: config_options}

  def to_json(%__MODULE__{} = r) do
    map = %{"configOptions" => Enum.map(r.config_options, &ACP.SessionConfigOption.to_json/1)}
    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"configOptions" => opts} = map) do
    {:ok,
     %__MODULE__{
       config_options:
         Enum.map(opts, fn o ->
           {:ok, v} = ACP.SessionConfigOption.from_json(o)
           v
         end),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.SetSessionConfigOptionResponse do
  def encode(val, opts),
    do: ACP.SetSessionConfigOptionResponse.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Session Fork Types ---

defmodule ACP.ForkSessionRequest do
  @moduledoc "Request to fork an existing session. (Unstable)"

  @enforce_keys [:session_id, :cwd]
  defstruct [:session_id, :cwd, :mcp_servers, :meta]

  def new(session_id, cwd), do: %__MODULE__{session_id: session_id, cwd: cwd, mcp_servers: []}

  def to_json(%__MODULE__{} = r) do
    map = %{"sessionId" => r.session_id, "cwd" => r.cwd}

    map =
      if r.mcp_servers && r.mcp_servers != [],
        do: Map.put(map, "mcpServers", Enum.map(r.mcp_servers, &ACP.McpServer.to_json/1)),
        else: map

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

defimpl Jason.Encoder, for: ACP.ForkSessionRequest do
  def encode(val, opts), do: ACP.ForkSessionRequest.to_json(val) |> Jason.Encoder.encode(opts)
end

defmodule ACP.ForkSessionResponse do
  @moduledoc "Response from forking a session. (Unstable)"

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
             {:ok, v} = ACP.SessionModeState.from_json(m)
             v
         end,
       models:
         case Map.get(map, "models") do
           nil ->
             nil

           m ->
             {:ok, v} = ACP.SessionModelState.from_json(m)
             v
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

defimpl Jason.Encoder, for: ACP.ForkSessionResponse do
  def encode(val, opts), do: ACP.ForkSessionResponse.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Session Resume Types ---

defmodule ACP.ResumeSessionRequest do
  @moduledoc "Request to resume an existing session without replaying history. (Unstable)"

  @enforce_keys [:session_id, :cwd]
  defstruct [:session_id, :cwd, :mcp_servers, :meta]

  def new(session_id, cwd), do: %__MODULE__{session_id: session_id, cwd: cwd, mcp_servers: []}

  def to_json(%__MODULE__{} = r) do
    map = %{"sessionId" => r.session_id, "cwd" => r.cwd}

    map =
      if r.mcp_servers && r.mcp_servers != [],
        do: Map.put(map, "mcpServers", Enum.map(r.mcp_servers, &ACP.McpServer.to_json/1)),
        else: map

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

defimpl Jason.Encoder, for: ACP.ResumeSessionRequest do
  def encode(val, opts), do: ACP.ResumeSessionRequest.to_json(val) |> Jason.Encoder.encode(opts)
end

defmodule ACP.ResumeSessionResponse do
  @moduledoc "Response from resuming a session. (Unstable)"

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
             {:ok, v} = ACP.SessionModeState.from_json(m)
             v
         end,
       models:
         case Map.get(map, "models") do
           nil ->
             nil

           m ->
             {:ok, v} = ACP.SessionModelState.from_json(m)
             v
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

defimpl Jason.Encoder, for: ACP.ResumeSessionResponse do
  def encode(val, opts), do: ACP.ResumeSessionResponse.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Session List Types ---

defmodule ACP.SessionInfo do
  @moduledoc "Information about a session returned by session/list. (Unstable)"

  @enforce_keys [:session_id, :cwd]
  defstruct [:session_id, :cwd, :title, :updated_at, :meta]

  def new(session_id, cwd), do: %__MODULE__{session_id: session_id, cwd: cwd}

  def to_json(%__MODULE__{} = s) do
    map = %{"sessionId" => s.session_id, "cwd" => s.cwd}
    map = if s.title, do: Map.put(map, "title", s.title), else: map
    map = if s.updated_at, do: Map.put(map, "updatedAt", s.updated_at), else: map
    if s.meta, do: Map.put(map, "_meta", s.meta), else: map
  end

  def from_json(%{"sessionId" => sid, "cwd" => cwd} = map) do
    {:ok,
     %__MODULE__{
       session_id: sid,
       cwd: cwd,
       title: Map.get(map, "title"),
       updated_at: Map.get(map, "updatedAt"),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.SessionInfo do
  def encode(val, opts), do: ACP.SessionInfo.to_json(val) |> Jason.Encoder.encode(opts)
end

defmodule ACP.ListSessionsRequest do
  @moduledoc "Request to list existing sessions. (Unstable)"

  defstruct [:cwd, :cursor, :meta]

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = r) do
    map = %{}
    map = if r.cwd, do: Map.put(map, "cwd", r.cwd), else: map
    map = if r.cursor, do: Map.put(map, "cursor", r.cursor), else: map
    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       cwd: Map.get(map, "cwd"),
       cursor: Map.get(map, "cursor"),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.ListSessionsRequest do
  def encode(val, opts), do: ACP.ListSessionsRequest.to_json(val) |> Jason.Encoder.encode(opts)
end

defmodule ACP.ListSessionsResponse do
  @moduledoc "Response from listing sessions. (Unstable)"

  @enforce_keys [:sessions]
  defstruct [:sessions, :next_cursor, :meta]

  def new(sessions), do: %__MODULE__{sessions: sessions}

  def to_json(%__MODULE__{} = r) do
    map = %{"sessions" => Enum.map(r.sessions, &ACP.SessionInfo.to_json/1)}
    map = if r.next_cursor, do: Map.put(map, "nextCursor", r.next_cursor), else: map
    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"sessions" => sessions} = map) do
    {:ok,
     %__MODULE__{
       sessions:
         Enum.map(sessions, fn s ->
           {:ok, v} = ACP.SessionInfo.from_json(s)
           v
         end),
       next_cursor: Map.get(map, "nextCursor"),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.ListSessionsResponse do
  def encode(val, opts), do: ACP.ListSessionsResponse.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Session Capabilities (Unstable) ---

defmodule ACP.SessionListCapabilities do
  @moduledoc "Capabilities for session/list. (Unstable)"

  defstruct [:meta]

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = c) do
    if c.meta, do: %{"_meta" => c.meta}, else: %{}
  end

  def from_json(map) when is_map(map) do
    {:ok, %__MODULE__{meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.SessionListCapabilities do
  def encode(val, opts),
    do: ACP.SessionListCapabilities.to_json(val) |> Jason.Encoder.encode(opts)
end

defmodule ACP.SessionForkCapabilities do
  @moduledoc "Capabilities for session/fork. (Unstable)"

  defstruct [:meta]

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = c) do
    if c.meta, do: %{"_meta" => c.meta}, else: %{}
  end

  def from_json(map) when is_map(map) do
    {:ok, %__MODULE__{meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.SessionForkCapabilities do
  def encode(val, opts),
    do: ACP.SessionForkCapabilities.to_json(val) |> Jason.Encoder.encode(opts)
end

defmodule ACP.SessionResumeCapabilities do
  @moduledoc "Capabilities for session/resume. (Unstable)"

  defstruct [:meta]

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = c) do
    if c.meta, do: %{"_meta" => c.meta}, else: %{}
  end

  def from_json(map) when is_map(map) do
    {:ok, %__MODULE__{meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.SessionResumeCapabilities do
  def encode(val, opts),
    do: ACP.SessionResumeCapabilities.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Client-Side Unstable Types ---

defmodule ACP.ConfigOptionUpdate do
  @moduledoc "Session configuration options have been updated. (Unstable)"

  @enforce_keys [:config_options]
  defstruct [:config_options, :meta]

  @type t :: %__MODULE__{config_options: [ACP.SessionConfigOption.t()], meta: map() | nil}

  def new(config_options), do: %__MODULE__{config_options: config_options}

  def to_json(%__MODULE__{} = c) do
    map = %{"configOptions" => Enum.map(c.config_options, &ACP.SessionConfigOption.to_json/1)}
    if c.meta, do: Map.put(map, "_meta", c.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       config_options:
         Enum.map(Map.get(map, "configOptions", []), fn o ->
           {:ok, v} = ACP.SessionConfigOption.from_json(o)
           v
         end),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.ConfigOptionUpdate do
  def encode(val, opts), do: ACP.ConfigOptionUpdate.to_json(val) |> Jason.Encoder.encode(opts)
end

defmodule ACP.SessionInfoUpdate do
  @moduledoc """
  Update to session metadata. (Unstable)

  Uses MaybeUndefined for fields to support partial updates:
  - `:undefined` → field not included (no change)
  - `nil` → explicitly null (clear the value)
  - `{:value, v}` → set to v
  """

  defstruct title: :undefined, updated_at: :undefined, meta: nil

  @type t :: %__MODULE__{
          title: :undefined | nil | {:value, String.t()},
          updated_at: :undefined | nil | {:value, String.t()},
          meta: map() | nil
        }

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = s) do
    map = %{}

    map =
      case ACP.MaybeUndefined.to_json(s.title) do
        {:skip} -> map
        v -> Map.put(map, "title", v)
      end

    map =
      case ACP.MaybeUndefined.to_json(s.updated_at) do
        {:skip} -> map
        v -> Map.put(map, "updatedAt", v)
      end

    if s.meta, do: Map.put(map, "_meta", s.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       title:
         if Map.has_key?(map, "title") do
           ACP.MaybeUndefined.from_json(Map.get(map, "title"))
         else
           :undefined
         end,
       updated_at:
         if Map.has_key?(map, "updatedAt") do
           ACP.MaybeUndefined.from_json(Map.get(map, "updatedAt"))
         else
           :undefined
         end,
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.SessionInfoUpdate do
  def encode(val, opts), do: ACP.SessionInfoUpdate.to_json(val) |> Jason.Encoder.encode(opts)
end
