defmodule ACP.AgentSideConnection do
  @moduledoc """
  An agent-side connection to a client.

  Wraps an ACP.Connection with the AgentSide decoder, providing
  convenience functions that implement the Client interface (request_permission,
  write_text_file, session_notification, etc.) for making requests to the client
  from the agent side.
  """

  defstruct [:conn]

  @doc """
  Start an agent-side connection.

  Options:
    - `:handler` - Module implementing ACP.Agent behaviour (handles incoming client requests)
    - `:handler_state` - State passed to handler
    - `:input` - Input IO device (default: :stdio)
    - `:output` - Output IO device (default: :stdio)
    - `:name` - Optional GenServer name
  """
  def start_link(opts) do
    conn_opts =
      Keyword.merge(opts, side: ACP.AgentSide)

    case ACP.Connection.start_link(conn_opts) do
      {:ok, pid} -> {:ok, %__MODULE__{conn: pid}}
      error -> error
    end
  end

  def subscribe(%__MODULE__{conn: conn}), do: ACP.Connection.subscribe(conn)
  def stop(%__MODULE__{conn: conn}), do: ACP.Connection.stop(conn)

  # Client interface - requests sent to the client

  def request_permission(%__MODULE__{} = c, req) do
    ACP.Connection.request(
      c.conn,
      "session/request_permission",
      ACP.RequestPermissionRequest.to_json(req)
    )
  end

  def elicit_form(%__MODULE__{} = c, req, timeout \\ 30_000) do
    case ACP.Connection.request(
           c.conn,
           "elicitation/create",
           ACP.ElicitationCreateRequest.to_json(req),
           timeout
         ) do
      {:ok, resp_map} -> ACP.ElicitationCreateResponse.from_json(resp_map)
      {:error, _} = err -> err
    end
  end

  def elicit_url(%__MODULE__{} = c, req, timeout \\ 30_000) do
    elicit_form(c, req, timeout)
  end

  def write_text_file(%__MODULE__{} = c, req) do
    ACP.Connection.request(c.conn, "fs/write_text_file", ACP.WriteTextFileRequest.to_json(req))
  end

  def read_text_file(%__MODULE__{} = c, req) do
    ACP.Connection.request(c.conn, "fs/read_text_file", ACP.ReadTextFileRequest.to_json(req))
  end

  def create_terminal(%__MODULE__{} = c, req) do
    ACP.Connection.request(c.conn, "terminal/create", ACP.CreateTerminalRequest.to_json(req))
  end

  def terminal_output(%__MODULE__{} = c, req) do
    ACP.Connection.request(c.conn, "terminal/output", ACP.TerminalOutputRequest.to_json(req))
  end

  def release_terminal(%__MODULE__{} = c, req) do
    ACP.Connection.request(c.conn, "terminal/release", ACP.ReleaseTerminalRequest.to_json(req))
  end

  def wait_for_terminal_exit(%__MODULE__{} = c, req) do
    ACP.Connection.request(
      c.conn,
      "terminal/wait_for_exit",
      ACP.WaitForTerminalExitRequest.to_json(req)
    )
  end

  def kill_terminal_command(%__MODULE__{} = c, req) do
    ACP.Connection.request(c.conn, "terminal/kill", ACP.KillTerminalCommandRequest.to_json(req))
  end

  def session_notification(%__MODULE__{} = c, notif) do
    ACP.Connection.notify(c.conn, "session/update", ACP.SessionNotification.to_json(notif))
  end

  def ext_method(%__MODULE__{} = c, req) do
    ACP.Connection.request(c.conn, "_#{req.method}", req.params)
  end

  def ext_notification(%__MODULE__{} = c, notif) do
    ACP.Connection.notify(c.conn, "_#{notif.method}", notif.params)
  end
end
