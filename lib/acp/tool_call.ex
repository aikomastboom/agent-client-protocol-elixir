defmodule ACP.ToolKind do
  @moduledoc "Categories of tools that can be invoked."

  @type t ::
          :read
          | :edit
          | :delete
          | :move
          | :search
          | :execute
          | :think
          | :fetch
          | :switch_mode
          | :other

  def encode(:read), do: "read"
  def encode(:edit), do: "edit"
  def encode(:delete), do: "delete"
  def encode(:move), do: "move"
  def encode(:search), do: "search"
  def encode(:execute), do: "execute"
  def encode(:think), do: "think"
  def encode(:fetch), do: "fetch"
  def encode(:switch_mode), do: "switch_mode"
  def encode(:other), do: "other"

  def decode("read"), do: :read
  def decode("edit"), do: :edit
  def decode("delete"), do: :delete
  def decode("move"), do: :move
  def decode("search"), do: :search
  def decode("execute"), do: :execute
  def decode("think"), do: :think
  def decode("fetch"), do: :fetch
  def decode("switch_mode"), do: :switch_mode
  def decode(_), do: :other

  def default, do: :other
  def is_default?(:other), do: true
  def is_default?(_), do: false
end

defmodule ACP.ToolCallStatus do
  @moduledoc "Execution status of a tool call."

  @type t :: :pending | :in_progress | :completed | :failed

  def encode(:pending), do: "pending"
  def encode(:in_progress), do: "in_progress"
  def encode(:completed), do: "completed"
  def encode(:failed), do: "failed"

  def decode("pending"), do: :pending
  def decode("in_progress"), do: :in_progress
  def decode("completed"), do: :completed
  def decode("failed"), do: :failed

  def default, do: :pending
  def is_default?(:pending), do: true
  def is_default?(_), do: false
end

defmodule ACP.ToolCallLocation do
  @moduledoc "A file location being accessed or modified by a tool."

  @type t :: %__MODULE__{
          path: String.t(),
          line: non_neg_integer() | nil,
          meta: map() | nil
        }

  @enforce_keys [:path]
  defstruct [:path, :line, :meta]

  def new(path), do: %__MODULE__{path: path}

  def to_json(%__MODULE__{} = loc) do
    map = %{"path" => loc.path}
    map = if loc.line, do: Map.put(map, "line", loc.line), else: map
    if loc.meta, do: Map.put(map, "_meta", loc.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       path: Map.fetch!(map, "path"),
       line: Map.get(map, "line"),
       meta: Map.get(map, "_meta")
     }}
  end
end

defmodule ACP.Diff do
  @moduledoc "A diff representing file modifications."

  @type t :: %__MODULE__{
          path: String.t(),
          old_text: String.t() | nil,
          new_text: String.t(),
          meta: map() | nil
        }

  @enforce_keys [:path, :new_text]
  defstruct [:path, :old_text, :new_text, :meta]

  def new(path, new_text), do: %__MODULE__{path: path, new_text: new_text}

  def to_json(%__MODULE__{} = diff) do
    map = %{"path" => diff.path, "oldText" => diff.old_text, "newText" => diff.new_text}
    if diff.meta, do: Map.put(map, "_meta", diff.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       path: Map.fetch!(map, "path"),
       old_text: Map.get(map, "oldText"),
       new_text: Map.fetch!(map, "newText"),
       meta: Map.get(map, "_meta")
     }}
  end
end

defmodule ACP.ToolCallTerminal do
  @moduledoc "Embed a terminal created with terminal/create by its id."

  @type t :: %__MODULE__{
          terminal_id: String.t(),
          meta: map() | nil
        }

  @enforce_keys [:terminal_id]
  defstruct [:terminal_id, :meta]

  def new(terminal_id), do: %__MODULE__{terminal_id: terminal_id}

  def to_json(%__MODULE__{} = t) do
    map = %{"terminalId" => t.terminal_id}
    if t.meta, do: Map.put(map, "_meta", t.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       terminal_id: Map.fetch!(map, "terminalId"),
       meta: Map.get(map, "_meta")
     }}
  end
end

defmodule ACP.ToolCallContentWrapper do
  @moduledoc "Standard content block wrapper for tool call content."

  @type t :: %__MODULE__{
          content: ACP.ContentBlock.t(),
          meta: map() | nil
        }

  @enforce_keys [:content]
  defstruct [:content, :meta]

  def new(content), do: %__MODULE__{content: content}

  def to_json(%__MODULE__{} = c) do
    map = %{"content" => ACP.ContentBlock.to_json(c.content)}
    if c.meta, do: Map.put(map, "_meta", c.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok, cb} = ACP.ContentBlock.from_json(Map.fetch!(map, "content"))

    {:ok,
     %__MODULE__{
       content: cb,
       meta: Map.get(map, "_meta")
     }}
  end
end

defmodule ACP.ToolCallContent do
  @moduledoc "Content produced by a tool call. Tagged union with type discriminator."

  @type t ::
          {:content, ACP.ToolCallContentWrapper.t()}
          | {:diff, ACP.Diff.t()}
          | {:terminal, ACP.ToolCallTerminal.t()}

  def content(wrapper), do: {:content, wrapper}
  def diff(diff), do: {:diff, diff}
  def terminal(terminal), do: {:terminal, terminal}

  def to_json({:content, c}),
    do: Map.put(ACP.ToolCallContentWrapper.to_json(c), "type", "content")

  def to_json({:diff, d}), do: Map.put(ACP.Diff.to_json(d), "type", "diff")
  def to_json({:terminal, t}), do: Map.put(ACP.ToolCallTerminal.to_json(t), "type", "terminal")

  def from_json(%{"type" => "content"} = map) do
    {:ok, c} = ACP.ToolCallContentWrapper.from_json(Map.delete(map, "type"))
    {:ok, {:content, c}}
  end

  def from_json(%{"type" => "diff"} = map) do
    {:ok, d} = ACP.Diff.from_json(Map.delete(map, "type"))
    {:ok, {:diff, d}}
  end

  def from_json(%{"type" => "terminal"} = map) do
    {:ok, t} = ACP.ToolCallTerminal.from_json(Map.delete(map, "type"))
    {:ok, {:terminal, t}}
  end
end

defmodule ACP.ToolCallUpdateFields do
  @moduledoc "Optional fields that can be updated in a tool call."

  @type t :: %__MODULE__{
          kind: ACP.ToolKind.t() | nil,
          status: ACP.ToolCallStatus.t() | nil,
          title: String.t() | nil,
          content: [ACP.ToolCallContent.t()] | nil,
          locations: [ACP.ToolCallLocation.t()] | nil,
          raw_input: any() | nil,
          raw_output: any() | nil
        }

  defstruct [:kind, :status, :title, :content, :locations, :raw_input, :raw_output]

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = f) do
    map = %{}
    map = if f.kind, do: Map.put(map, "kind", ACP.ToolKind.encode(f.kind)), else: map
    map = if f.status, do: Map.put(map, "status", ACP.ToolCallStatus.encode(f.status)), else: map
    map = if f.title, do: Map.put(map, "title", f.title), else: map

    map =
      if f.content,
        do: Map.put(map, "content", Enum.map(f.content, &ACP.ToolCallContent.to_json/1)),
        else: map

    map =
      if f.locations,
        do: Map.put(map, "locations", Enum.map(f.locations, &ACP.ToolCallLocation.to_json/1)),
        else: map

    map = if f.raw_input, do: Map.put(map, "rawInput", f.raw_input), else: map
    map = if f.raw_output, do: Map.put(map, "rawOutput", f.raw_output), else: map
    map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       kind:
         case Map.get(map, "kind") do
           nil -> nil
           k -> ACP.ToolKind.decode(k)
         end,
       status:
         case Map.get(map, "status") do
           nil -> nil
           s -> ACP.ToolCallStatus.decode(s)
         end,
       title: Map.get(map, "title"),
       content:
         case Map.get(map, "content") do
           nil ->
             nil

           list ->
             Enum.map(list, fn c ->
               {:ok, v} = ACP.ToolCallContent.from_json(c)
               v
             end)
         end,
       locations:
         case Map.get(map, "locations") do
           nil ->
             nil

           list ->
             Enum.map(list, fn l ->
               {:ok, v} = ACP.ToolCallLocation.from_json(l)
               v
             end)
         end,
       raw_input: Map.get(map, "rawInput"),
       raw_output: Map.get(map, "rawOutput")
     }}
  end
end

defmodule ACP.ToolCallUpdate do
  @moduledoc "An update to an existing tool call."

  @type t :: %__MODULE__{
          tool_call_id: String.t(),
          fields: ACP.ToolCallUpdateFields.t(),
          meta: map() | nil
        }

  @enforce_keys [:tool_call_id, :fields]
  defstruct [:tool_call_id, :fields, :meta]

  def new(tool_call_id, fields) do
    %__MODULE__{tool_call_id: tool_call_id, fields: fields}
  end

  def to_json(%__MODULE__{} = u) do
    # flatten fields into top-level map (like serde flatten)
    map = ACP.ToolCallUpdateFields.to_json(u.fields)
    map = Map.put(map, "toolCallId", u.tool_call_id)
    if u.meta, do: Map.put(map, "_meta", u.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok, fields} = ACP.ToolCallUpdateFields.from_json(map)

    {:ok,
     %__MODULE__{
       tool_call_id: Map.fetch!(map, "toolCallId"),
       fields: fields,
       meta: Map.get(map, "_meta")
     }}
  end
end

defmodule ACP.ToolCall do
  @moduledoc "Represents a tool call that the language model has requested."

  @type t :: %__MODULE__{
          tool_call_id: String.t(),
          title: String.t(),
          kind: ACP.ToolKind.t(),
          status: ACP.ToolCallStatus.t(),
          content: [ACP.ToolCallContent.t()],
          locations: [ACP.ToolCallLocation.t()],
          raw_input: any() | nil,
          raw_output: any() | nil,
          meta: map() | nil
        }

  @enforce_keys [:tool_call_id, :title]
  defstruct [
    :tool_call_id,
    :title,
    kind: :other,
    status: :pending,
    content: [],
    locations: [],
    raw_input: nil,
    raw_output: nil,
    meta: nil
  ]

  def new(tool_call_id, title) do
    %__MODULE__{tool_call_id: tool_call_id, title: title}
  end

  def update(%__MODULE__{} = tc, %ACP.ToolCallUpdateFields{} = fields) do
    tc = if fields.title, do: %{tc | title: fields.title}, else: tc
    tc = if fields.kind, do: %{tc | kind: fields.kind}, else: tc
    tc = if fields.status, do: %{tc | status: fields.status}, else: tc
    tc = if fields.content, do: %{tc | content: fields.content}, else: tc
    tc = if fields.locations, do: %{tc | locations: fields.locations}, else: tc
    tc = if fields.raw_input, do: %{tc | raw_input: fields.raw_input}, else: tc
    tc = if fields.raw_output, do: %{tc | raw_output: fields.raw_output}, else: tc
    tc
  end

  def to_json(%__MODULE__{} = tc) do
    map = %{"toolCallId" => tc.tool_call_id, "title" => tc.title}

    map =
      if not ACP.ToolKind.is_default?(tc.kind),
        do: Map.put(map, "kind", ACP.ToolKind.encode(tc.kind)),
        else: map

    map =
      if not ACP.ToolCallStatus.is_default?(tc.status),
        do: Map.put(map, "status", ACP.ToolCallStatus.encode(tc.status)),
        else: map

    map =
      if tc.content != [],
        do: Map.put(map, "content", Enum.map(tc.content, &ACP.ToolCallContent.to_json/1)),
        else: map

    map =
      if tc.locations != [],
        do: Map.put(map, "locations", Enum.map(tc.locations, &ACP.ToolCallLocation.to_json/1)),
        else: map

    map = if tc.raw_input, do: Map.put(map, "rawInput", tc.raw_input), else: map
    map = if tc.raw_output, do: Map.put(map, "rawOutput", tc.raw_output), else: map
    if tc.meta, do: Map.put(map, "_meta", tc.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       tool_call_id: Map.fetch!(map, "toolCallId"),
       title: Map.fetch!(map, "title"),
       kind:
         case Map.get(map, "kind") do
           nil -> :other
           k -> ACP.ToolKind.decode(k)
         end,
       status:
         case Map.get(map, "status") do
           nil -> :pending
           s -> ACP.ToolCallStatus.decode(s)
         end,
       content:
         case Map.get(map, "content") do
           nil ->
             []

           list ->
             Enum.map(list, fn c ->
               {:ok, v} = ACP.ToolCallContent.from_json(c)
               v
             end)
         end,
       locations:
         case Map.get(map, "locations") do
           nil ->
             []

           list ->
             Enum.map(list, fn l ->
               {:ok, v} = ACP.ToolCallLocation.from_json(l)
               v
             end)
         end,
       raw_input: Map.get(map, "rawInput"),
       raw_output: Map.get(map, "rawOutput"),
       meta: Map.get(map, "_meta")
     }}
  end

  def to_update(%__MODULE__{} = tc) do
    %ACP.ToolCallUpdate{
      tool_call_id: tc.tool_call_id,
      fields: %ACP.ToolCallUpdateFields{
        kind: tc.kind,
        status: tc.status,
        title: tc.title,
        content: tc.content,
        locations: tc.locations,
        raw_input: tc.raw_input,
        raw_output: tc.raw_output
      },
      meta: tc.meta
    }
  end
end

defimpl Jason.Encoder, for: ACP.ToolCall do
  def encode(tc, opts), do: ACP.ToolCall.to_json(tc) |> Jason.Encoder.encode(opts)
end

defimpl Jason.Encoder, for: ACP.ToolCallUpdate do
  def encode(u, opts), do: ACP.ToolCallUpdate.to_json(u) |> Jason.Encoder.encode(opts)
end

defimpl Jason.Encoder, for: ACP.Diff do
  def encode(d, opts), do: ACP.Diff.to_json(d) |> Jason.Encoder.encode(opts)
end

defimpl Jason.Encoder, for: ACP.ToolCallLocation do
  def encode(l, opts), do: ACP.ToolCallLocation.to_json(l) |> Jason.Encoder.encode(opts)
end
