defmodule ACP.V2.NegotiationConnectionTest do
  @moduledoc """
  Connection-level integration for `initialize` version negotiation.

  Sends raw JSON-RPC lines into a real agent-side `ACP.Connection` and asserts
  on the broadcast stream plus the bytes actually written, so the wire shape of
  the response is part of the assertion rather than only the decoded struct.
  """
  use ExUnit.Case, async: true

  # Mirrors a real agent: the response version and shape come from what the
  # connection negotiated, not from whatever the peer asked for. Echoing the
  # request would make the clamp-to-supported tests prove nothing.
  defmodule NegotiatingHandler do
    def handle_request({:initialize, %ACP.V2.InitializeRequest{protocol_version: 2}}) do
      {:ok,
       ACP.V2.InitializeResponse.new(2, ACP.V2.Implementation.new("negotiating-agent", "1.0.0"))}
    end

    def handle_request({:initialize, %ACP.V1.InitializeRequest{}}) do
      {:ok,
       %{
         "protocolVersion" => 1,
         "agentCapabilities" => %{"loadSession" => true},
         "agentInfo" => %{"name" => "negotiating-agent", "version" => "1.0.0"}
       }}
    end
  end

  setup do
    {:ok, output} = StringIO.open("")
    on_exit(fn -> close_string_io(output) end)
    {:ok, output: output}
  end

  defp start_connection(output, extra \\ []) do
    ACP.Connection.start_link(
      [
        side: ACP.V1.AgentSide,
        handler: NegotiatingHandler,
        input: self(),
        output: output
      ] ++ extra
    )
  end

  defp initialize_line(id, params) do
    Jason.encode!(%{
      "jsonrpc" => "2.0",
      "id" => id,
      "method" => "initialize",
      "params" => params
    })
  end

  defp out(output), do: StringIO.contents(output) |> elem(1)

  defp negotiated(conn), do: :sys.get_state(conn).protocol_version

  # A StringIO already closed by the test raises; swallow only that exit.
  defp close_string_io(pid) do
    StringIO.close(pid)
  catch
    :exit, _ -> :ok
  end

  describe "v2 negotiation" do
    test "v2 is not offered unless the caller opts in", %{output: output} do
      {:ok, conn} = start_connection(output)
      ACP.Connection.subscribe(conn)

      send(conn, {:incoming_line, initialize_line("r1", %{"protocolVersion" => 2})})

      # Default support is v1 only, so a v2 request falls back to v1 and is
      # decoded by the v1 side module.
      assert_receive {:acp_stream, {:outgoing, :response, "r1", {:ok, value}}}, 1_000
      assert value["protocolVersion"] == 1
      assert negotiated(conn) == 1
    end

    test "decodes the request with v2 modules and answers in the v2 shape", %{output: output} do
      {:ok, conn} = start_connection(output, supported_versions: [1, 2])
      ACP.Connection.subscribe(conn)

      params = %{"protocolVersion" => 2, "info" => %{"name" => "cli", "version" => "9"}}
      send(conn, {:incoming_line, initialize_line("r1", params)})

      assert_receive {:acp_stream,
                      {:incoming, :request, "r1", "initialize", {:initialize, request}}},
                     1_000

      assert %ACP.V2.InitializeRequest{protocol_version: 2} = request
      assert request.info.name == "cli"

      assert_receive {:acp_stream, {:outgoing, :response, "r1", {:ok, value}}}, 1_000
      assert value["protocolVersion"] == 2
      assert value["info"]["name"] == "negotiating-agent"
      refute Map.has_key?(value, "agentInfo")

      assert negotiated(conn) == 2
      assert out(output) =~ ~s("protocolVersion":2)
    end

    test "selects the highest supported version at or below the request", %{output: output} do
      {:ok, conn} = start_connection(output, supported_versions: [1])
      ACP.Connection.subscribe(conn)

      send(conn, {:incoming_line, initialize_line("r1", %{"protocolVersion" => 999})})

      assert_receive {:acp_stream, {:outgoing, :response, "r1", {:ok, value}}}, 1_000
      assert value["protocolVersion"] == 1
      assert negotiated(conn) == 1
    end
  end

  describe "v1 regression" do
    test "initialize keeps the v1 request and response shape", %{output: output} do
      {:ok, conn} = start_connection(output)
      ACP.Connection.subscribe(conn)

      params = %{"protocolVersion" => 1, "clientCapabilities" => %{}}
      send(conn, {:incoming_line, initialize_line("r1", params)})

      assert_receive {:acp_stream,
                      {:incoming, :request, "r1", "initialize", {:initialize, request}}},
                     1_000

      assert %ACP.V1.InitializeRequest{protocol_version: 1} = request

      assert_receive {:acp_stream, {:outgoing, :response, "r1", {:ok, value}}}, 1_000
      assert value["protocolVersion"] == 1
      assert value["agentCapabilities"]["loadSession"] == true
      assert negotiated(conn) == 1
      assert out(output) =~ ~s("protocolVersion":1)
    end

    test "a v1 initialize with only a protocolVersion still decodes", %{output: output} do
      {:ok, conn} = start_connection(output)
      ACP.Connection.subscribe(conn)

      send(conn, {:incoming_line, initialize_line("r1", %{"protocolVersion" => 1})})

      assert_receive {:acp_stream, {:outgoing, :response, "r1", {:ok, _value}}}, 1_000
    end
  end

  describe "rejection" do
    test "a version below everything supported is -32022", %{output: output} do
      {:ok, conn} = start_connection(output)
      ACP.Connection.subscribe(conn)

      # v0 predates version negotiation, so nothing at or below it is servable.
      send(conn, {:incoming_line, initialize_line("r1", %{"protocolVersion" => 0})})

      assert_receive {:acp_stream,
                      {:outgoing, :response, "r1", {:error, %ACP.Error{code: -32_022} = err}}},
                     1_000

      assert err.data == %{"requested" => 0, "supported" => [1]}
      assert out(output) =~ ~s("code":-32022)
    end

    test "leaves the connection uninitialized so the peer can retry", %{output: output} do
      {:ok, conn} = start_connection(output, supported_versions: [2])
      ACP.Connection.subscribe(conn)

      send(conn, {:incoming_line, initialize_line("r1", %{"protocolVersion" => 1})})

      assert_receive {:acp_stream,
                      {:outgoing, :response, "r1", {:error, %ACP.Error{code: -32_022}}}},
                     1_000

      assert negotiated(conn) == nil

      # A retry with a supported version now succeeds.
      params = %{"protocolVersion" => 2, "info" => %{"name" => "cli", "version" => "1"}}
      send(conn, {:incoming_line, initialize_line("r2", params)})

      assert_receive {:acp_stream, {:outgoing, :response, "r2", {:ok, value}}}, 1_000
      assert value["protocolVersion"] == 2
      assert negotiated(conn) == 2
    end

    test "a malformed protocolVersion is -32602 with reason data", %{output: output} do
      {:ok, conn} = start_connection(output, supported_versions: [1, 2])
      ACP.Connection.subscribe(conn)

      send(conn, {:incoming_line, initialize_line("r1", %{"protocolVersion" => "two"})})

      assert_receive {:acp_stream,
                      {:outgoing, :response, "r1", {:error, %ACP.Error{code: -32_602} = err}}},
                     1_000

      assert %{"reason" => reason} = err.data
      assert reason =~ "protocolVersion"
      refute_received {:acp_stream, {:incoming, :request, "r1", _, _}}
      assert out(output) =~ ~s("code":-32602)
    end

    test "a missing protocolVersion is -32602", %{output: output} do
      {:ok, conn} = start_connection(output, supported_versions: [1, 2])
      ACP.Connection.subscribe(conn)

      params = %{"info" => %{"name" => "c", "version" => "1"}}
      send(conn, {:incoming_line, initialize_line("r1", params)})

      assert_receive {:acp_stream,
                      {:outgoing, :response, "r1", {:error, %ACP.Error{code: -32_602}}}},
                     1_000
    end
  end
end
