defmodule ACP.AgentTypesTest do
  use ExUnit.Case, async: true

  test "Implementation to_json/from_json" do
    impl = ACP.Implementation.new("test-agent", "1.0.0")
    json = ACP.Implementation.to_json(impl)
    assert json == %{"name" => "test-agent", "version" => "1.0.0"}
    {:ok, decoded} = ACP.Implementation.from_json(json)
    assert decoded.name == "test-agent"
    assert decoded.version == "1.0.0"
  end

  test "Implementation with title and meta" do
    impl = %ACP.Implementation{
      name: "test",
      version: "1.0",
      title: "Test Agent",
      meta: %{"x" => 1}
    }

    json = ACP.Implementation.to_json(impl)
    assert json["title"] == "Test Agent"
    assert json["_meta"] == %{"x" => 1}
  end

  test "AuthMethod to_json/from_json" do
    am = ACP.AuthMethod.new("oauth", "OAuth 2.0")
    json = ACP.AuthMethod.to_json(am)
    assert json == %{"id" => "oauth", "name" => "OAuth 2.0"}
    {:ok, decoded} = ACP.AuthMethod.from_json(json)
    assert decoded.id == "oauth"
  end

  test "InitializeRequest to_json/from_json" do
    req = ACP.InitializeRequest.new(1)
    json = ACP.InitializeRequest.to_json(req)
    assert json["protocolVersion"] == 1
    {:ok, decoded} = ACP.InitializeRequest.from_json(json)
    assert decoded.protocol_version == 1
  end

  test "InitializeResponse to_json/from_json" do
    resp = ACP.InitializeResponse.new(1)
    json = ACP.InitializeResponse.to_json(resp)
    assert json["protocolVersion"] == 1
    {:ok, decoded} = ACP.InitializeResponse.from_json(json)
    assert decoded.protocol_version == 1
  end

  test "NewSessionRequest to_json/from_json" do
    req = ACP.NewSessionRequest.new("/home/user")
    json = ACP.NewSessionRequest.to_json(req)
    assert json["cwd"] == "/home/user"
    assert json["mcpServers"] == []
    {:ok, decoded} = ACP.NewSessionRequest.from_json(json)
    assert decoded.cwd == "/home/user"
  end

  test "NewSessionResponse to_json/from_json" do
    resp = ACP.NewSessionResponse.new("session-123")
    json = ACP.NewSessionResponse.to_json(resp)
    assert json["sessionId"] == "session-123"
    {:ok, decoded} = ACP.NewSessionResponse.from_json(json)
    assert decoded.session_id == "session-123"
  end

  test "PromptResponse with stop_reason" do
    resp = ACP.PromptResponse.new(:end_turn)
    json = ACP.PromptResponse.to_json(resp)
    assert json["stopReason"] == "end_turn"
    {:ok, decoded} = ACP.PromptResponse.from_json(json)
    assert decoded.stop_reason == :end_turn
  end

  test "StopReason all values" do
    for {atom, str} <- [
          end_turn: "end_turn",
          max_tokens: "max_tokens",
          max_turn_requests: "max_turn_requests",
          refusal: "refusal",
          cancelled: "cancelled"
        ] do
      assert ACP.StopReason.to_json(atom) == str
      assert ACP.StopReason.from_json(str) == atom
    end
  end

  test "McpServer stdio to_json/from_json" do
    server = {:stdio, ACP.McpServerStdio.new("test-server", "/usr/bin/server")}
    json = ACP.McpServer.to_json(server)
    assert json["name"] == "test-server"
    assert json["command"] == "/usr/bin/server"
    refute Map.has_key?(json, "type")
    {:ok, decoded} = ACP.McpServer.from_json(json)
    assert {:stdio, stdio} = decoded
    assert stdio.name == "test-server"
  end

  test "McpServer http to_json/from_json" do
    server = {:http, ACP.McpServerHttp.new("http-server", "https://api.example.com")}
    json = ACP.McpServer.to_json(server)
    assert json["type"] == "http"
    assert json["url"] == "https://api.example.com"
    {:ok, decoded} = ACP.McpServer.from_json(json)
    assert {:http, http} = decoded
    assert http.url == "https://api.example.com"
  end

  test "McpServer sse to_json/from_json" do
    server = {:sse, ACP.McpServerSse.new("sse-server", "https://sse.example.com")}
    json = ACP.McpServer.to_json(server)
    assert json["type"] == "sse"
    {:ok, decoded} = ACP.McpServer.from_json(json)
    assert {:sse, sse} = decoded
    assert sse.name == "sse-server"
  end

  test "AgentCapabilities defaults" do
    caps = ACP.AgentCapabilities.new()
    assert caps.load_session == false
  end

  test "SessionCapabilities with close capability" do
    close_cap = ACP.SessionCloseCapabilities.new()
    caps = %ACP.SessionCapabilities{close: close_cap}
    json = ACP.SessionCapabilities.to_json(caps)
    assert Map.has_key?(json, "close")
    {:ok, decoded} = ACP.SessionCapabilities.from_json(json)
    assert decoded.close != nil
  end

  test "SessionCapabilities without close capability" do
    caps = ACP.SessionCapabilities.new()
    json = ACP.SessionCapabilities.to_json(caps)
    refute Map.has_key?(json, "close")
    {:ok, decoded} = ACP.SessionCapabilities.from_json(json)
    assert decoded.close == nil
  end

  test "CancelNotification to_json/from_json" do
    notif = ACP.CancelNotification.new("session-1")
    json = ACP.CancelNotification.to_json(notif)
    assert json["sessionId"] == "session-1"
    {:ok, decoded} = ACP.CancelNotification.from_json(json)
    assert decoded.session_id == "session-1"
  end

  test "SessionModeState to_json/from_json" do
    state =
      ACP.SessionModeState.new("code", [
        ACP.SessionMode.new("code", "Code"),
        ACP.SessionMode.new("ask", "Ask")
      ])

    json = ACP.SessionModeState.to_json(state)
    assert json["currentModeId"] == "code"
    assert length(json["availableModes"]) == 2
    {:ok, decoded} = ACP.SessionModeState.from_json(json)
    assert decoded.current_mode_id == "code"
    assert length(decoded.available_modes) == 2
  end
end
