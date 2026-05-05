# ContentBlock is defined in content.ex
# EnvVariable is defined in agent_types.ex

# --- Session Notification ---

defmodule ACP.SessionNotification do
  @moduledoc "Notification about a session update."

  @enforce_keys [:session_id, :update]
  defstruct [:session_id, :update, :meta]

  def new(session_id, update), do: %__MODULE__{session_id: session_id, update: update}

  def to_json(%__MODULE__{} = n) do
    map = %{"sessionId" => n.session_id, "update" => ACP.SessionUpdate.to_json(n.update)}
    if n.meta, do: Map.put(map, "_meta", n.meta), else: map
  end

  def from_json(%{"sessionId" => sid, "update" => update} = map) do
    {:ok,
     %__MODULE__{
       session_id: sid,
       update: ACP.SessionUpdate.from_json(update),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.SessionNotification do
  def encode(val, opts), do: ACP.SessionNotification.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Session Update (tagged union by "sessionUpdate" field) ---

defmodule ACP.SessionUpdate do
  @moduledoc "Tagged union representing different session update types."

  @type t ::
          {:user_message_chunk, ACP.ContentChunk.t()}
          | {:agent_message_chunk, ACP.ContentChunk.t()}
          | {:agent_thought_chunk, ACP.ContentChunk.t()}
          | {:tool_call, ACP.ToolCall.t()}
          | {:tool_call_update, ACP.ToolCallUpdate.t()}
          | {:plan, ACP.Plan.t()}
          | {:available_commands_update, ACP.AvailableCommandsUpdate.t()}
          | {:current_mode_update, ACP.CurrentModeUpdate.t()}
          | {:config_option_update, ACP.ConfigOptionUpdate.t()}
          | {:session_info_update, ACP.SessionInfoUpdate.t()}

  def to_json({:user_message_chunk, chunk}) do
    ACP.ContentChunk.to_json(chunk) |> Map.put("sessionUpdate", "user_message_chunk")
  end

  def to_json({:agent_message_chunk, chunk}) do
    ACP.ContentChunk.to_json(chunk) |> Map.put("sessionUpdate", "agent_message_chunk")
  end

  def to_json({:agent_thought_chunk, chunk}) do
    ACP.ContentChunk.to_json(chunk) |> Map.put("sessionUpdate", "agent_thought_chunk")
  end

  def to_json({:tool_call, tc}) do
    ACP.ToolCall.to_json(tc) |> Map.put("sessionUpdate", "tool_call")
  end

  def to_json({:tool_call_update, tcu}) do
    ACP.ToolCallUpdate.to_json(tcu) |> Map.put("sessionUpdate", "tool_call_update")
  end

  def to_json({:plan, plan}) do
    ACP.Plan.to_json(plan) |> Map.put("sessionUpdate", "plan")
  end

  def to_json({:available_commands_update, acu}) do
    ACP.AvailableCommandsUpdate.to_json(acu)
    |> Map.put("sessionUpdate", "available_commands_update")
  end

  def to_json({:current_mode_update, cmu}) do
    ACP.CurrentModeUpdate.to_json(cmu) |> Map.put("sessionUpdate", "current_mode_update")
  end

  def to_json({:config_option_update, cou}) do
    ACP.ConfigOptionUpdate.to_json(cou) |> Map.put("sessionUpdate", "config_option_update")
  end

  def to_json({:session_info_update, siu}) do
    ACP.SessionInfoUpdate.to_json(siu) |> Map.put("sessionUpdate", "session_info_update")
  end

  def from_json(%{"sessionUpdate" => "user_message_chunk"} = map) do
    {:ok, chunk} = ACP.ContentChunk.from_json(map)
    {:user_message_chunk, chunk}
  end

  def from_json(%{"sessionUpdate" => "agent_message_chunk"} = map) do
    {:ok, chunk} = ACP.ContentChunk.from_json(map)
    {:agent_message_chunk, chunk}
  end

  def from_json(%{"sessionUpdate" => "agent_thought_chunk"} = map) do
    {:ok, chunk} = ACP.ContentChunk.from_json(map)
    {:agent_thought_chunk, chunk}
  end

  def from_json(%{"sessionUpdate" => "tool_call"} = map) do
    {:ok, tc} = ACP.ToolCall.from_json(map)
    {:tool_call, tc}
  end

  def from_json(%{"sessionUpdate" => "tool_call_update"} = map) do
    {:ok, tcu} = ACP.ToolCallUpdate.from_json(map)
    {:tool_call_update, tcu}
  end

  def from_json(%{"sessionUpdate" => "plan"} = map) do
    {:ok, plan} = ACP.Plan.from_json(map)
    {:plan, plan}
  end

  def from_json(%{"sessionUpdate" => "available_commands_update"} = map) do
    {:ok, acu} = ACP.AvailableCommandsUpdate.from_json(map)
    {:available_commands_update, acu}
  end

  def from_json(%{"sessionUpdate" => "current_mode_update"} = map) do
    {:ok, cmu} = ACP.CurrentModeUpdate.from_json(map)
    {:current_mode_update, cmu}
  end

  def from_json(%{"sessionUpdate" => "config_option_update"} = map) do
    {:ok, cou} = ACP.ConfigOptionUpdate.from_json(map)
    {:config_option_update, cou}
  end

  def from_json(%{"sessionUpdate" => "session_info_update"} = map) do
    {:ok, siu} = ACP.SessionInfoUpdate.from_json(map)
    {:session_info_update, siu}
  end
end

# --- Content Chunk ---

defmodule ACP.ContentChunk do
  @moduledoc "A chunk of content in a session update."

  @enforce_keys [:content]
  defstruct [:content, :meta]

  @type t :: %__MODULE__{}

  def new(content), do: %__MODULE__{content: content}

  def to_json(%__MODULE__{} = c) do
    map = %{"content" => ACP.ContentBlock.to_json(c.content)}
    if c.meta, do: Map.put(map, "_meta", c.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok, content} = ACP.ContentBlock.from_json(Map.get(map, "content", map))
    {:ok, %__MODULE__{content: content, meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.ContentChunk do
  def encode(val, opts), do: ACP.ContentChunk.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Current Mode Update ---

defmodule ACP.CurrentModeUpdate do
  @moduledoc "Update indicating the current mode has changed."

  @enforce_keys [:current_mode_id]
  defstruct [:current_mode_id, :meta]

  @type t :: %__MODULE__{current_mode_id: String.t(), meta: map() | nil}

  def new(current_mode_id), do: %__MODULE__{current_mode_id: current_mode_id}

  def to_json(%__MODULE__{} = c) do
    map = %{"currentModeId" => c.current_mode_id}
    if c.meta, do: Map.put(map, "_meta", c.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       current_mode_id: Map.fetch!(map, "currentModeId"),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.CurrentModeUpdate do
  def encode(val, opts), do: ACP.CurrentModeUpdate.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Available Commands Update ---

defmodule ACP.AvailableCommandsUpdate do
  @moduledoc "Update indicating the set of available commands has changed."

  @enforce_keys [:available_commands]
  defstruct [:available_commands, :meta]

  @type t :: %__MODULE__{available_commands: [ACP.AvailableCommand.t()], meta: map() | nil}

  def new(cmds), do: %__MODULE__{available_commands: cmds}

  def to_json(%__MODULE__{} = a) do
    map = %{
      "availableCommands" => Enum.map(a.available_commands, &ACP.AvailableCommand.to_json/1)
    }

    if a.meta, do: Map.put(map, "_meta", a.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       available_commands:
         Enum.map(Map.get(map, "availableCommands", []), fn c ->
           {:ok, v} = ACP.AvailableCommand.from_json(c)
           v
         end),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.AvailableCommandsUpdate do
  def encode(val, opts),
    do: ACP.AvailableCommandsUpdate.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Available Command ---

defmodule ACP.AvailableCommand do
  @moduledoc "A command available to the user."

  @enforce_keys [:name, :description]
  defstruct [:name, :description, :input, :meta]

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          input: ACP.AvailableCommandInput.t() | nil,
          meta: map() | nil
        }

  def new(name, description), do: %__MODULE__{name: name, description: description}

  def to_json(%__MODULE__{} = c) do
    map = %{"name" => c.name, "description" => c.description}

    map =
      if c.input, do: Map.put(map, "input", ACP.AvailableCommandInput.to_json(c.input)), else: map

    if c.meta, do: Map.put(map, "_meta", c.meta), else: map
  end

  def from_json(%{"name" => name, "description" => desc} = map) do
    {:ok,
     %__MODULE__{
       name: name,
       description: desc,
       input:
         case Map.get(map, "input") do
           nil -> nil
           i -> ACP.AvailableCommandInput.from_json(i)
         end,
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.AvailableCommand do
  def encode(val, opts), do: ACP.AvailableCommand.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Available Command Input (untagged union, currently only Unstructured) ---

defmodule ACP.AvailableCommandInput do
  @moduledoc "Input specification for an available command."

  @type t :: {:unstructured, ACP.UnstructuredCommandInput.t()}

  def to_json({:unstructured, input}), do: ACP.UnstructuredCommandInput.to_json(input)

  def from_json(%{"hint" => _} = map) do
    {:ok, val} = ACP.UnstructuredCommandInput.from_json(map)
    {:unstructured, val}
  end

  def from_json(map) when is_map(map) do
    {:unstructured, ACP.UnstructuredCommandInput.new(Map.get(map, "hint", ""))}
  end
end

# --- Unstructured Command Input ---

defmodule ACP.UnstructuredCommandInput do
  @moduledoc "Unstructured input with a hint."

  @enforce_keys [:hint]
  defstruct [:hint, :meta]

  @type t :: %__MODULE__{}

  def new(hint), do: %__MODULE__{hint: hint}

  def to_json(%__MODULE__{} = u) do
    map = %{"hint" => u.hint}
    if u.meta, do: Map.put(map, "_meta", u.meta), else: map
  end

  def from_json(%{"hint" => hint} = map) do
    {:ok, %__MODULE__{hint: hint, meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.UnstructuredCommandInput do
  def encode(val, opts),
    do: ACP.UnstructuredCommandInput.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Request Permission Request ---

defmodule ACP.RequestPermissionRequest do
  @moduledoc "Request from the agent asking the client for permission to perform a tool call."

  @enforce_keys [:session_id, :tool_call, :options]
  defstruct [:session_id, :tool_call, :options, :meta]

  def new(session_id, tool_call, options) do
    %__MODULE__{session_id: session_id, tool_call: tool_call, options: options}
  end

  def to_json(%__MODULE__{} = r) do
    map = %{
      "sessionId" => r.session_id,
      "toolCall" => ACP.ToolCallUpdate.to_json(r.tool_call),
      "options" => Enum.map(r.options, &ACP.PermissionOption.to_json/1)
    }

    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"sessionId" => sid, "toolCall" => tc, "options" => opts} = map) do
    {:ok, tc_val} = ACP.ToolCallUpdate.from_json(tc)

    {:ok,
     %__MODULE__{
       session_id: sid,
       tool_call: tc_val,
       options:
         Enum.map(opts, fn o ->
           {:ok, v} = ACP.PermissionOption.from_json(o)
           v
         end),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.RequestPermissionRequest do
  def encode(val, opts),
    do: ACP.RequestPermissionRequest.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Permission Option ---

defmodule ACP.PermissionOption do
  @moduledoc "An option presented to the user for a permission request."

  @enforce_keys [:option_id, :name, :kind]
  defstruct [:option_id, :name, :kind, :meta]

  def new(option_id, name, kind), do: %__MODULE__{option_id: option_id, name: name, kind: kind}

  def to_json(%__MODULE__{} = p) do
    map = %{
      "optionId" => p.option_id,
      "name" => p.name,
      "kind" => ACP.PermissionOptionKind.to_json(p.kind)
    }

    if p.meta, do: Map.put(map, "_meta", p.meta), else: map
  end

  def from_json(%{"optionId" => oid, "name" => name, "kind" => kind} = map) do
    {:ok,
     %__MODULE__{
       option_id: oid,
       name: name,
       kind: ACP.PermissionOptionKind.from_json(kind),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.PermissionOption do
  def encode(val, opts), do: ACP.PermissionOption.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Permission Option Kind ---

defmodule ACP.PermissionOptionKind do
  @moduledoc "The kind of permission option."

  @type t :: :allow_once | :allow_always | :reject_once | :reject_always

  def to_json(:allow_once), do: "allow_once"
  def to_json(:allow_always), do: "allow_always"
  def to_json(:reject_once), do: "reject_once"
  def to_json(:reject_always), do: "reject_always"

  def from_json("allow_once"), do: :allow_once
  def from_json("allow_always"), do: :allow_always
  def from_json("reject_once"), do: :reject_once
  def from_json("reject_always"), do: :reject_always
end

# --- Request Permission Response ---

defmodule ACP.RequestPermissionResponse do
  @moduledoc "Response from the client to a permission request."

  @enforce_keys [:outcome]
  defstruct [:outcome, :meta]

  def new(outcome), do: %__MODULE__{outcome: outcome}

  def to_json(%__MODULE__{} = r) do
    map = %{"outcome" => ACP.RequestPermissionOutcome.to_json(r.outcome)}
    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"outcome" => outcome} = map) do
    {:ok,
     %__MODULE__{
       outcome: ACP.RequestPermissionOutcome.from_json(outcome),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.RequestPermissionResponse do
  def encode(val, opts),
    do: ACP.RequestPermissionResponse.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Request Permission Outcome (tagged by "outcome") ---

defmodule ACP.RequestPermissionOutcome do
  @moduledoc "The outcome of a permission request."

  @type t :: :cancelled | {:selected, ACP.SelectedPermissionOutcome.t()}

  def to_json(:cancelled), do: %{"outcome" => "cancelled"}

  def to_json({:selected, s}) do
    ACP.SelectedPermissionOutcome.to_json(s) |> Map.put("outcome", "selected")
  end

  def from_json(%{"outcome" => "cancelled"}), do: :cancelled

  def from_json(%{"outcome" => "selected"} = map) do
    {:ok, val} = ACP.SelectedPermissionOutcome.from_json(map)
    {:selected, val}
  end
end

# --- Selected Permission Outcome ---

defmodule ACP.SelectedPermissionOutcome do
  @moduledoc "A selected permission outcome containing the chosen option."

  @enforce_keys [:option_id]
  defstruct [:option_id, :meta]

  @type t :: %__MODULE__{}

  def new(option_id), do: %__MODULE__{option_id: option_id}

  def to_json(%__MODULE__{} = s) do
    map = %{"optionId" => s.option_id}
    if s.meta, do: Map.put(map, "_meta", s.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       option_id: Map.fetch!(map, "optionId"),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.SelectedPermissionOutcome do
  def encode(val, opts),
    do: ACP.SelectedPermissionOutcome.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Write Text File Request ---

defmodule ACP.WriteTextFileRequest do
  @moduledoc "Request to write a text file."

  @enforce_keys [:session_id, :path, :content]
  defstruct [:session_id, :path, :content, :meta]

  def new(session_id, path, content) do
    %__MODULE__{session_id: session_id, path: path, content: content}
  end

  def to_json(%__MODULE__{} = r) do
    map = %{"sessionId" => r.session_id, "path" => r.path, "content" => r.content}
    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"sessionId" => sid, "path" => path, "content" => content} = map) do
    {:ok, %__MODULE__{session_id: sid, path: path, content: content, meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.WriteTextFileRequest do
  def encode(val, opts), do: ACP.WriteTextFileRequest.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Write Text File Response ---

defmodule ACP.WriteTextFileResponse do
  @moduledoc "Response to a write text file request."

  defstruct [:meta]

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = r) do
    if r.meta, do: %{"_meta" => r.meta}, else: %{}
  end

  def from_json(map) when is_map(map) do
    {:ok, %__MODULE__{meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.WriteTextFileResponse do
  def encode(val, opts), do: ACP.WriteTextFileResponse.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Read Text File Request ---

defmodule ACP.ReadTextFileRequest do
  @moduledoc "Request to read a text file."

  @enforce_keys [:session_id, :path]
  defstruct [:session_id, :path, :line, :limit, :meta]

  def new(session_id, path), do: %__MODULE__{session_id: session_id, path: path}

  def to_json(%__MODULE__{} = r) do
    map = %{"sessionId" => r.session_id, "path" => r.path}
    map = if r.line, do: Map.put(map, "line", r.line), else: map
    map = if r.limit, do: Map.put(map, "limit", r.limit), else: map
    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"sessionId" => sid, "path" => path} = map) do
    {:ok,
     %__MODULE__{
       session_id: sid,
       path: path,
       line: Map.get(map, "line"),
       limit: Map.get(map, "limit"),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.ReadTextFileRequest do
  def encode(val, opts), do: ACP.ReadTextFileRequest.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Read Text File Response ---

defmodule ACP.ReadTextFileResponse do
  @moduledoc "Response to a read text file request."

  @enforce_keys [:content]
  defstruct [:content, :meta]

  def new(content), do: %__MODULE__{content: content}

  def to_json(%__MODULE__{} = r) do
    map = %{"content" => r.content}
    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"content" => content} = map) do
    {:ok, %__MODULE__{content: content, meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.ReadTextFileResponse do
  def encode(val, opts), do: ACP.ReadTextFileResponse.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Create Terminal Request ---

defmodule ACP.CreateTerminalRequest do
  @moduledoc "Request to create a terminal session."

  @enforce_keys [:session_id, :command]
  defstruct [:session_id, :command, :args, :cwd, :env, :timeout_ms, :meta]

  def new(session_id, command) do
    %__MODULE__{session_id: session_id, command: command, args: [], env: []}
  end

  def to_json(%__MODULE__{} = r) do
    map = %{"sessionId" => r.session_id, "command" => r.command}
    map = Map.put(map, "args", r.args || [])
    map = if r.cwd, do: Map.put(map, "cwd", r.cwd), else: map
    map = Map.put(map, "env", Enum.map(r.env || [], &ACP.EnvVariable.to_json/1))
    map = if r.timeout_ms, do: Map.put(map, "timeoutMs", r.timeout_ms), else: map
    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"sessionId" => sid, "command" => cmd} = map) do
    {:ok,
     %__MODULE__{
       session_id: sid,
       command: cmd,
       args: Map.get(map, "args", []),
       cwd: Map.get(map, "cwd"),
       env:
         Enum.map(Map.get(map, "env", []), fn e ->
           {:ok, v} = ACP.EnvVariable.from_json(e)
           v
         end),
       timeout_ms: Map.get(map, "timeoutMs"),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.CreateTerminalRequest do
  def encode(val, opts), do: ACP.CreateTerminalRequest.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Create Terminal Response ---

defmodule ACP.CreateTerminalResponse do
  @moduledoc "Response to a create terminal request."

  @enforce_keys [:terminal_id]
  defstruct [:terminal_id, :meta]

  def new(terminal_id), do: %__MODULE__{terminal_id: terminal_id}

  def to_json(%__MODULE__{} = r) do
    map = %{"terminalId" => r.terminal_id}
    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"terminalId" => tid} = map) do
    {:ok, %__MODULE__{terminal_id: tid, meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.CreateTerminalResponse do
  def encode(val, opts), do: ACP.CreateTerminalResponse.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Terminal Output Request ---

defmodule ACP.TerminalOutputRequest do
  @moduledoc "Request to get output from a terminal."

  @enforce_keys [:session_id, :terminal_id]
  defstruct [:session_id, :terminal_id, :meta]

  def new(session_id, terminal_id) do
    %__MODULE__{session_id: session_id, terminal_id: terminal_id}
  end

  def to_json(%__MODULE__{} = r) do
    map = %{"sessionId" => r.session_id, "terminalId" => r.terminal_id}
    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"sessionId" => sid, "terminalId" => tid} = map) do
    {:ok, %__MODULE__{session_id: sid, terminal_id: tid, meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.TerminalOutputRequest do
  def encode(val, opts), do: ACP.TerminalOutputRequest.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Terminal Output Response ---

defmodule ACP.TerminalOutputResponse do
  @moduledoc "Response containing terminal output."

  @enforce_keys [:output]
  defstruct [:output, :exit_status, :meta]

  def new(output), do: %__MODULE__{output: output}

  def to_json(%__MODULE__{} = r) do
    map = %{"output" => r.output}

    map =
      if r.exit_status,
        do: Map.put(map, "exitStatus", ACP.TerminalExitStatus.to_json(r.exit_status)),
        else: map

    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"output" => output} = map) do
    {:ok,
     %__MODULE__{
       output: output,
       exit_status:
         case Map.get(map, "exitStatus") do
           nil ->
             nil

           es ->
             {:ok, v} = ACP.TerminalExitStatus.from_json(es)
             v
         end,
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.TerminalOutputResponse do
  def encode(val, opts), do: ACP.TerminalOutputResponse.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Terminal Exit Status ---

defmodule ACP.TerminalExitStatus do
  @moduledoc "Exit status of a terminal command."

  defstruct [:exit_code, :meta]

  def new(exit_code), do: %__MODULE__{exit_code: exit_code}

  def to_json(%__MODULE__{} = s) do
    map = %{"exitCode" => s.exit_code}
    if s.meta, do: Map.put(map, "_meta", s.meta), else: map
  end

  def from_json(%{"exitCode" => ec} = map) do
    {:ok, %__MODULE__{exit_code: ec, meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.TerminalExitStatus do
  def encode(val, opts), do: ACP.TerminalExitStatus.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Release Terminal Request ---

defmodule ACP.ReleaseTerminalRequest do
  @moduledoc "Request to release a terminal."

  @enforce_keys [:session_id, :terminal_id]
  defstruct [:session_id, :terminal_id, :meta]

  def new(session_id, terminal_id) do
    %__MODULE__{session_id: session_id, terminal_id: terminal_id}
  end

  def to_json(%__MODULE__{} = r) do
    map = %{"sessionId" => r.session_id, "terminalId" => r.terminal_id}
    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"sessionId" => sid, "terminalId" => tid} = map) do
    {:ok, %__MODULE__{session_id: sid, terminal_id: tid, meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.ReleaseTerminalRequest do
  def encode(val, opts), do: ACP.ReleaseTerminalRequest.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Release Terminal Response ---

defmodule ACP.ReleaseTerminalResponse do
  @moduledoc "Response to a release terminal request."

  defstruct [:meta]

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = r) do
    if r.meta, do: %{"_meta" => r.meta}, else: %{}
  end

  def from_json(map) when is_map(map) do
    {:ok, %__MODULE__{meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.ReleaseTerminalResponse do
  def encode(val, opts),
    do: ACP.ReleaseTerminalResponse.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Wait For Terminal Exit Request ---

defmodule ACP.WaitForTerminalExitRequest do
  @moduledoc "Request to wait for a terminal command to exit."

  @enforce_keys [:session_id, :terminal_id]
  defstruct [:session_id, :terminal_id, :meta]

  def new(session_id, terminal_id) do
    %__MODULE__{session_id: session_id, terminal_id: terminal_id}
  end

  def to_json(%__MODULE__{} = r) do
    map = %{"sessionId" => r.session_id, "terminalId" => r.terminal_id}
    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"sessionId" => sid, "terminalId" => tid} = map) do
    {:ok, %__MODULE__{session_id: sid, terminal_id: tid, meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.WaitForTerminalExitRequest do
  def encode(val, opts),
    do: ACP.WaitForTerminalExitRequest.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Wait For Terminal Exit Response ---

defmodule ACP.WaitForTerminalExitResponse do
  @moduledoc "Response containing terminal exit status."

  @enforce_keys [:exit_status]
  defstruct [:exit_status, :meta]

  def new(exit_status), do: %__MODULE__{exit_status: exit_status}

  def to_json(%__MODULE__{} = r) do
    map = %{"exitStatus" => ACP.TerminalExitStatus.to_json(r.exit_status)}
    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"exitStatus" => es} = map) do
    {:ok, es_val} = ACP.TerminalExitStatus.from_json(es)
    {:ok, %__MODULE__{exit_status: es_val, meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.WaitForTerminalExitResponse do
  def encode(val, opts),
    do: ACP.WaitForTerminalExitResponse.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Kill Terminal Command Request ---

defmodule ACP.KillTerminalCommandRequest do
  @moduledoc "Request to kill a terminal command."

  @enforce_keys [:session_id, :terminal_id]
  defstruct [:session_id, :terminal_id, :meta]

  def new(session_id, terminal_id) do
    %__MODULE__{session_id: session_id, terminal_id: terminal_id}
  end

  def to_json(%__MODULE__{} = r) do
    map = %{"sessionId" => r.session_id, "terminalId" => r.terminal_id}
    if r.meta, do: Map.put(map, "_meta", r.meta), else: map
  end

  def from_json(%{"sessionId" => sid, "terminalId" => tid} = map) do
    {:ok, %__MODULE__{session_id: sid, terminal_id: tid, meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.KillTerminalCommandRequest do
  def encode(val, opts),
    do: ACP.KillTerminalCommandRequest.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Kill Terminal Command Response ---

defmodule ACP.KillTerminalCommandResponse do
  @moduledoc "Response to a kill terminal command request."

  defstruct [:meta]

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = r) do
    if r.meta, do: %{"_meta" => r.meta}, else: %{}
  end

  def from_json(map) when is_map(map) do
    {:ok, %__MODULE__{meta: Map.get(map, "_meta")}}
  end
end

defimpl Jason.Encoder, for: ACP.KillTerminalCommandResponse do
  def encode(val, opts),
    do: ACP.KillTerminalCommandResponse.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Client Capabilities ---

defmodule ACP.ClientCapabilities do
  @moduledoc "Capabilities declared by the client."

  defstruct terminal: false,
            file_system: nil,
            meta: nil

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = c) do
    map = %{"terminal" => c.terminal}

    map =
      if c.file_system,
        do: Map.put(map, "fileSystem", ACP.FileSystemCapability.to_json(c.file_system)),
        else: map

    if c.meta, do: Map.put(map, "_meta", c.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       terminal: Map.get(map, "terminal", false),
       file_system:
         case Map.get(map, "fileSystem") do
           nil ->
             nil

           fs ->
             {:ok, v} = ACP.FileSystemCapability.from_json(fs)
             v
         end,
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.ClientCapabilities do
  def encode(val, opts), do: ACP.ClientCapabilities.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- File System Capability ---

defmodule ACP.FileSystemCapability do
  @moduledoc "File system capabilities supported by the client."

  defstruct write_text_file: false,
            read_text_file: false,
            meta: nil

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = c) do
    map = %{"writeTextFile" => c.write_text_file, "readTextFile" => c.read_text_file}
    if c.meta, do: Map.put(map, "_meta", c.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       write_text_file: Map.get(map, "writeTextFile", false),
       read_text_file: Map.get(map, "readTextFile", false),
       meta: Map.get(map, "_meta")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.FileSystemCapability do
  def encode(val, opts), do: ACP.FileSystemCapability.to_json(val) |> Jason.Encoder.encode(opts)
end

# --- Agent Request (routing enum) ---

defmodule ACP.AgentRequest do
  @moduledoc "Enum of all possible requests from the agent to the client."

  @type t ::
          {:write_text_file, ACP.WriteTextFileRequest.t()}
          | {:read_text_file, ACP.ReadTextFileRequest.t()}
          | {:request_permission, ACP.RequestPermissionRequest.t()}
          | {:create_terminal, ACP.CreateTerminalRequest.t()}
          | {:terminal_output, ACP.TerminalOutputRequest.t()}
          | {:release_terminal, ACP.ReleaseTerminalRequest.t()}
          | {:wait_for_terminal_exit, ACP.WaitForTerminalExitRequest.t()}
          | {:kill_terminal_command, ACP.KillTerminalCommandRequest.t()}
          | {:ext_method, ACP.ExtRequest.t()}

  def method({:write_text_file, _}), do: "fs/write_text_file"
  def method({:read_text_file, _}), do: "fs/read_text_file"
  def method({:request_permission, _}), do: "session/request_permission"
  def method({:create_terminal, _}), do: "terminal/create"
  def method({:terminal_output, _}), do: "terminal/output"
  def method({:release_terminal, _}), do: "terminal/release"
  def method({:wait_for_terminal_exit, _}), do: "terminal/wait_for_exit"
  def method({:kill_terminal_command, _}), do: "terminal/kill"
  def method({:ext_method, req}), do: req.method
end

# --- Client Response (routing enum) ---

defmodule ACP.ClientResponse do
  @moduledoc "Enum of all possible responses from the client to the agent."

  @type t ::
          {:write_text_file, ACP.WriteTextFileResponse.t()}
          | {:read_text_file, ACP.ReadTextFileResponse.t()}
          | {:request_permission, ACP.RequestPermissionResponse.t()}
          | {:create_terminal, ACP.CreateTerminalResponse.t()}
          | {:terminal_output, ACP.TerminalOutputResponse.t()}
          | {:release_terminal, ACP.ReleaseTerminalResponse.t()}
          | {:wait_for_terminal_exit, ACP.WaitForTerminalExitResponse.t()}
          | {:kill_terminal_command, ACP.KillTerminalCommandResponse.t()}
          | {:ext_method, ACP.ExtResponse.t()}
end

# --- Agent Notification (routing enum) ---

defmodule ACP.AgentNotification do
  @moduledoc "Enum of all possible notifications from the agent to the client."

  @type t ::
          {:session_notification, ACP.SessionNotification.t()}
          | {:ext_notification, ACP.ExtNotification.t()}

  def method({:session_notification, _}), do: "session/update"
  def method({:ext_notification, notif}), do: notif.method
end
