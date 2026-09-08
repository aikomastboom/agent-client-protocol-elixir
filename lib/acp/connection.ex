defmodule ACP.Connection do
  @moduledoc """
  GenServer managing a bidirectional JSON-RPC 2.0 connection over IO streams.

  Handles line-delimited JSON over stdin/stdout (or any IO streams).
  Manages request/response correlation and message routing via a Side module.
  """

  use GenServer

  require Logger

  defstruct [
    :side_module,
    :handler_module,
    :handler_state,
    :input_port,
    :output_io,
    :pending_responses,
    :next_id,
    :subscribers
  ]

  @type t :: %__MODULE__{}

  # -- Public API --

  @doc """
  Start a connection GenServer.

  Options:
    - `:side` - The side module (ACP.ClientSide or ACP.AgentSide)
    - `:handler` - Module implementing ACP.MessageHandler
    - `:handler_state` - State passed to handler callbacks
    - `:input` - Input IO device or port (default: :stdio)
    - `:output` - Output IO device (default: :stdio)
    - `:name` - Optional GenServer name
  """
  def start_link(opts) do
    name = Keyword.get(opts, :name)
    gen_opts = if name, do: [name: name], else: []
    GenServer.start_link(__MODULE__, opts, gen_opts)
  end

  @doc "Send a request and wait for a response."
  def request(conn, method, params, timeout \\ 30_000) do
    GenServer.call(conn, {:request, method, params}, timeout)
  end

  @doc "Send a notification (no response expected)."
  def notify(conn, method, params) do
    GenServer.cast(conn, {:notify, method, params})
  end

  @doc "Send a response to a received request."
  def respond(conn, id, result) do
    GenServer.cast(conn, {:respond, id, result})
  end

  @doc "Subscribe to stream messages. Returns a reference."
  def subscribe(conn) do
    GenServer.call(conn, :subscribe)
  end

  @doc "Stop the connection."
  def stop(conn) do
    GenServer.stop(conn, :normal)
  end

  # -- GenServer callbacks --

  @impl true
  def init(opts) do
    side = Keyword.fetch!(opts, :side)
    handler = Keyword.get(opts, :handler)
    handler_state = Keyword.get(opts, :handler_state)
    output = Keyword.get(opts, :output, :stdio)

    state = %__MODULE__{
      side_module: side,
      handler_module: handler,
      handler_state: handler_state,
      output_io: output,
      pending_responses: %{},
      next_id: 0,
      subscribers: []
    }

    # Start reading input in a separate process
    input = Keyword.get(opts, :input, :stdio)
    parent = self()
    spawn_link(fn -> read_loop(input, parent) end)

    {:ok, state}
  end

  @impl true
  def handle_call({:request, method, params}, from, state) do
    id = state.next_id
    state = %{state | next_id: id + 1}

    # Build and send the request
    request_map = %{"id" => id, "method" => method}
    request_map = if params, do: Map.put(request_map, "params", params), else: request_map
    send_json(state.output_io, request_map)

    broadcast(state, {:outgoing, :request, id, method, params})

    # Track pending response
    state = %{state | pending_responses: Map.put(state.pending_responses, id, from)}
    {:noreply, state}
  end

  def handle_call(:subscribe, {pid, _ref}, state) do
    ref = Process.monitor(pid)
    state = %{state | subscribers: [{pid, ref} | state.subscribers]}
    {:reply, ref, state}
  end

  @impl true
  def handle_cast({:notify, method, params}, state) do
    notif_map = %{"method" => method}
    notif_map = if params, do: Map.put(notif_map, "params", params), else: notif_map
    send_json(state.output_io, notif_map)

    broadcast(state, {:outgoing, :notification, method, params})
    {:noreply, state}
  end

  def handle_cast({:respond, id, result}, state) do
    response_map =
      case result do
        {:ok, value} -> %{"id" => id, "result" => value}
        {:error, error} -> %{"id" => id, "error" => ACP.Error.to_json(error)}
      end

    send_json(state.output_io, response_map)
    broadcast(state, {:outgoing, :response, id, result})
    {:noreply, state}
  end

  @impl true
  def handle_info({:incoming_line, line}, state) do
    state = handle_incoming_line(line, state)
    {:noreply, state}
  end

  def handle_info({:input_closed}, state) do
    {:stop, :normal, state}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    state = %{state | subscribers: Enum.reject(state.subscribers, fn {_p, r} -> r == ref end)}
    {:noreply, state}
  end

  # -- Internal --

  defp read_loop(io_device, parent) do
    case read_line(io_device) do
      {:ok, line} ->
        line = String.trim_trailing(line, "\n")

        if line != "" do
          Logger.debug("[ACP.Connection] Received line: #{line}")
          send(parent, {:incoming_line, line})
        end

        read_loop(io_device, parent)

      :eof ->
        send(parent, {:input_closed})

      {:error, reason} ->
        Logger.debug("[ACP.Connection] Received error: #{inspect(reason)}")
        send(parent, {:input_closed})
    end
  end

  defp read_line(:stdio), do: IO.read(:stdio, :line)

  defp read_line(device) when is_pid(device) do
    case IO.read(device, :line) do
      :eof -> :eof
      {:error, _} = err -> err
      data -> {:ok, data}
    end
  end

  defp read_line(device), do: IO.read(device, :line) |> wrap_read()

  defp wrap_read(:eof), do: :eof
  defp wrap_read({:error, _} = err), do: err
  defp wrap_read(data) when is_binary(data), do: {:ok, data}

  defp handle_incoming_line(line, state) do
    case Jason.decode(line) do
      {:ok, %{"jsonrpc" => "2.0"} = msg} ->
        handle_decoded_message(msg, state)

      {:ok, msg} when is_map(msg) ->
        # Allow messages without jsonrpc field for flexibility
        handle_decoded_message(msg, state)

      {:error, reason} ->
        Logger.error("[ACP.Connection] Failed to parse incoming JSON-RPC message: #{inspect(reason)}")
        state
    end
  end

  defp handle_decoded_message(msg, state) do
    cond do
      # Request: has id + method
      Map.has_key?(msg, "id") and Map.has_key?(msg, "method") ->
        handle_incoming_request(msg, state)

      # Response: has id + (result or error), no method
      Map.has_key?(msg, "id") and (Map.has_key?(msg, "result") or Map.has_key?(msg, "error")) ->
        handle_incoming_response(msg, state)

      # Notification: has method, no id
      Map.has_key?(msg, "method") and not Map.has_key?(msg, "id") ->
        handle_incoming_notification(msg, state)

      true ->
        Logger.error("[ACP.Connection] Unrecognized JSON-RPC message: #{inspect(msg)}")
        state
    end
  end

  defp handle_incoming_request(%{"id" => id, "method" => method} = msg, state) do
    params = Map.get(msg, "params")

    case state.side_module.decode_request(method, params) do
      {:ok, decoded_request} ->
        broadcast(state, {:incoming, :request, id, method, decoded_request})

        # Dispatch to handler asynchronously
        if state.handler_module do
          conn = self()

          Task.start(fn ->
            result =
              if function_exported?(state.handler_module, :handle_request, 1) do
                state.handler_module.handle_request(decoded_request)
              else
                state.handler_module.handle_request(decoded_request, state.handler_state)
              end

            # Encode the response value
            response_value =
              case result do
                {:ok, value} -> {:ok, encode_response_value(value)}
                {:error, _} = err -> err
              end

            ACP.Connection.respond(conn, id, response_value)
          end)
        end

        state

      {:error, error} ->
        # Send error response immediately
        error_response = %{"id" => id, "error" => ACP.Error.to_json(error)}
        send_json(state.output_io, error_response)
        broadcast(state, {:outgoing, :response, id, {:error, error}})
        state
    end
  end

  defp handle_incoming_response(%{"id" => id} = msg, state) do
    case Map.pop(state.pending_responses, id) do
      {nil, _} ->
        Logger.error("[ACP.Connection] Received response for unknown request id: #{inspect(id)}")
        state

      {from, pending} ->
        result =
          cond do
            Map.has_key?(msg, "result") ->
              {:ok, Map.get(msg, "result")}

            Map.has_key?(msg, "error") ->
              {:ok, err} = ACP.Error.from_json(Map.get(msg, "error"))
              {:error, err}

            true ->
              {:ok, nil}
          end

        broadcast(state, {:incoming, :response, id, result})
        GenServer.reply(from, result)
        %{state | pending_responses: pending}
    end
  end

  defp handle_incoming_notification(%{"method" => method} = msg, state) do
    params = Map.get(msg, "params")

    case state.side_module.decode_notification(method, params) do
      {:ok, decoded_notification} ->
        broadcast(state, {:incoming, :notification, method, decoded_notification})

        if state.handler_module do
          Task.start(fn ->
            if function_exported?(state.handler_module, :handle_notification, 1) do
              state.handler_module.handle_notification(decoded_notification)
            else
              state.handler_module.handle_notification(decoded_notification, state.handler_state)
            end
          end)
        end

        state

      {:error, error} ->
        Logger.error("[ACP.Connection] Failed to decode notification #{method}: #{inspect(error)}")
        state
    end
  end

  defp send_json(output, map) do
    json_map = Map.put(map, "jsonrpc", "2.0")
    line = Jason.encode!(json_map) <> "\n"

    # Use IO.binwrite to emit raw UTF-8 bytes. IO.write routes through
    # Erlang's unicode encoding layer which converts non-ASCII codepoints
    # (e.g. em dash U+2014) to \x{NNNN} escapes — invalid JSON.
    case output do
      :stdio -> IO.binwrite(:stdio, line)
      device -> IO.binwrite(device, line)
    end
  end

  defp encode_response_value(value) when is_map(value) do
    if Map.has_key?(value, :__struct__) do
      # Try to call to_json on the struct's module
      module = value.__struct__

      if function_exported?(module, :to_json, 1) do
        module.to_json(value)
      else
        value
      end
    else
      value
    end
  end

  defp encode_response_value(value), do: value

  defp broadcast(state, message) do
    for {pid, _ref} <- state.subscribers do
      send(pid, {:acp_stream, message})
    end
  end
end
