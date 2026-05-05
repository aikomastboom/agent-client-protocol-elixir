defmodule ACP.ClientSideConnection do
  @moduledoc """
  A client-side connection to an agent.

  Wraps an ACP.Connection with the ClientSide decoder, providing
  convenience functions that implement the Agent interface (initialize, prompt, etc.)
  for making requests to the agent from the client side.
  """

  defstruct [:conn]

  @type t :: %__MODULE__{conn: pid()}

  @doc """
  Start a client-side connection.

  Options:
    - `:handler` - Module implementing ACP.Client behaviour (handles incoming agent requests)
    - `:handler_state` - State passed to handler
    - `:input` - Input IO device (default: :stdio)
    - `:output` - Output IO device (default: :stdio)
    - `:name` - Optional GenServer name
  """
  def start_link(opts) do
    conn_opts =
      Keyword.merge(opts, side: ACP.ClientSide)

    case ACP.Connection.start_link(conn_opts) do
      {:ok, pid} -> {:ok, %__MODULE__{conn: pid}}
      error -> error
    end
  end

  def subscribe(%__MODULE__{conn: conn}), do: ACP.Connection.subscribe(conn)
  def stop(%__MODULE__{conn: conn}), do: ACP.Connection.stop(conn)

  # Agent interface - requests sent to the agent

  def initialize(%__MODULE__{} = c, req) do
    ACP.Connection.request(c.conn, "initialize", ACP.InitializeRequest.to_json(req))
  end

  def authenticate(%__MODULE__{} = c, req) do
    ACP.Connection.request(c.conn, "authenticate", ACP.AuthenticateRequest.to_json(req))
  end

  def new_session(%__MODULE__{} = c, req) do
    ACP.Connection.request(c.conn, "session/new", ACP.NewSessionRequest.to_json(req))
  end

  def load_session(%__MODULE__{} = c, req) do
    ACP.Connection.request(c.conn, "session/load", ACP.LoadSessionRequest.to_json(req))
  end

  def set_session_mode(%__MODULE__{} = c, req) do
    ACP.Connection.request(c.conn, "session/set_mode", ACP.SetSessionModeRequest.to_json(req))
  end

  def prompt(%__MODULE__{} = c, req) do
    ACP.Connection.request(c.conn, "session/prompt", ACP.PromptRequest.to_json(req))
  end

  def cancel(%__MODULE__{} = c, notif) do
    ACP.Connection.notify(c.conn, "session/cancel", ACP.CancelNotification.to_json(notif))
  end

  def ext_method(%__MODULE__{} = c, req) do
    ACP.Connection.request(c.conn, "_#{req.method}", req.params)
  end

  def ext_notification(%__MODULE__{} = c, notif) do
    ACP.Connection.notify(c.conn, "_#{notif.method}", notif.params)
  end
end
