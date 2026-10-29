defmodule ACP.ConnectionTest do
  use ExUnit.Case, async: true

  defmodule CrashingHandler do
    def handle_request(_request), do: raise("handler crashed")
  end

  defmodule OkHandler do
    def handle_request(_request), do: {:ok, %{ok: true}}
  end

  defp start_connection(handler, output) do
    ACP.Connection.start_link(
      side: ACP.V1.AgentSide,
      handler: handler,
      input: self(),
      output: output
    )
  end

  defp close_string_io(pid) do
    StringIO.close(pid)
  catch
    :exit, {:noproc, _} -> :ok
    :exit, {:shutdown, _} -> :ok
  end

  defp initialize_line,
    do:
      ~s({"jsonrpc":"2.0","id":"request-1","method":"initialize","params":{"protocolVersion":1}})

  test "returns an internal error when an inbound request handler crashes" do
    {:ok, output} = StringIO.open("")

    {:ok, connection} = start_connection(CrashingHandler, output)

    on_exit(fn ->
      if Process.alive?(connection), do: ACP.Connection.stop(connection)
      close_string_io(output)
    end)

    ACP.Connection.subscribe(connection)

    send(connection, {:incoming_line, initialize_line()})

    assert_receive {:acp_stream,
                    {:outgoing, :response, "request-1",
                     {:error, %ACP.Error{code: -32_603, message: "Internal error"}}}},
                   1_000

    # A crashing handler must not take the connection down with it.
    assert Process.alive?(connection)
  end

  test "still serves requests after a handler crash" do
    {:ok, output} = StringIO.open("")

    defmodule RecoverHandler do
      def handle_request(request) do
        case request do
          {:initialize, _} -> raise("handler crashed")
          _ -> {:ok, %{ok: true}}
        end
      end
    end

    {:ok, connection} = start_connection(RecoverHandler, output)

    on_exit(fn ->
      if Process.alive?(connection), do: ACP.Connection.stop(connection)
      close_string_io(output)
    end)

    ACP.Connection.subscribe(connection)

    send(connection, {:incoming_line, initialize_line()})

    assert_receive {:acp_stream, {:outgoing, :response, "request-1", {:error, %ACP.Error{}}}},
                   1_000

    send(
      connection,
      {:incoming_line,
       ~s({"jsonrpc":"2.0","id":"request-2","method":"session/new","params":{"cwd":"/tmp","mcpServers":[]}})}
    )

    assert_receive {:acp_stream, {:outgoing, :response, "request-2", {:ok, _}}}, 1_000
  end

  test "encodes a successful handler result as a response" do
    {:ok, output} = StringIO.open("")

    {:ok, connection} = start_connection(OkHandler, output)

    on_exit(fn ->
      if Process.alive?(connection), do: ACP.Connection.stop(connection)
      close_string_io(output)
    end)

    ACP.Connection.subscribe(connection)

    send(connection, {:incoming_line, initialize_line()})

    assert_receive {:acp_stream, {:outgoing, :response, "request-1", {:ok, _}}}, 1_000
  end
end
