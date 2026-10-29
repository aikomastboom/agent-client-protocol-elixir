defmodule ACP.SerializationTest do
  use ExUnit.Case, async: true
  @moduledoc "Cross-cutting JSON serialization tests matching Rust test cases."

  test "McpServer stdio serialization matches Rust" do
    server =
      {:stdio,
       %ACP.V1.McpServerStdio{
         name: "test-server",
         command: "/usr/bin/server",
         args: ["--port", "3000"],
         env: [ACP.V1.EnvVariable.new("API_KEY", "secret123")]
       }}

    json = ACP.V1.McpServer.to_json(server)

    assert json == %{
             "name" => "test-server",
             "command" => "/usr/bin/server",
             "args" => ["--port", "3000"],
             "env" => [%{"name" => "API_KEY", "value" => "secret123"}]
           }

    {:ok, decoded} = ACP.V1.McpServer.from_json(json)
    assert {:stdio, stdio} = decoded
    assert stdio.name == "test-server"
    assert stdio.command == "/usr/bin/server"
    assert stdio.args == ["--port", "3000"]
    assert length(stdio.env) == 1
    assert hd(stdio.env).name == "API_KEY"
  end

  test "McpServer http serialization matches Rust" do
    server =
      {:http,
       %ACP.V1.McpServerHttp{
         name: "http-server",
         url: "https://api.example.com",
         headers: [
           ACP.V1.HttpHeader.new("Authorization", "Bearer token123"),
           ACP.V1.HttpHeader.new("Content-Type", "application/json")
         ]
       }}

    json = ACP.V1.McpServer.to_json(server)
    assert json["type"] == "http"
    assert json["name"] == "http-server"
    assert json["url"] == "https://api.example.com"
    assert length(json["headers"]) == 2

    {:ok, decoded} = ACP.V1.McpServer.from_json(json)
    assert {:http, http} = decoded
    assert http.name == "http-server"
    assert length(http.headers) == 2
  end

  test "McpServer sse serialization matches Rust" do
    server =
      {:sse,
       %ACP.V1.McpServerSse{
         name: "sse-server",
         url: "https://sse.example.com/events",
         headers: [ACP.V1.HttpHeader.new("X-API-Key", "apikey456")]
       }}

    json = ACP.V1.McpServer.to_json(server)
    assert json["type"] == "sse"
    assert json["name"] == "sse-server"

    {:ok, decoded} = ACP.V1.McpServer.from_json(json)
    assert {:sse, sse} = decoded
    assert sse.url == "https://sse.example.com/events"
  end

  test "full initialize round-trip" do
    req = ACP.V1.InitializeRequest.new(1)
    json = ACP.V1.InitializeRequest.to_json(req)
    encoded = Jason.encode!(json)
    decoded_json = Jason.decode!(encoded)
    {:ok, decoded} = ACP.V1.InitializeRequest.from_json(decoded_json)
    assert decoded.protocol_version == 1
  end

  test "notification wire format" do
    notif = ACP.V1.CancelNotification.new("test-123")
    json = ACP.V1.CancelNotification.to_json(notif)
    assert json == %{"sessionId" => "test-123"}
  end

  test "close session request serialization" do
    req = ACP.V1.CloseSessionRequest.new("session-456")
    json = ACP.V1.CloseSessionRequest.to_json(req)
    assert json == %{"sessionId" => "session-456"}

    {:ok, decoded} = ACP.V1.CloseSessionRequest.from_json(json)
    assert decoded.session_id == "session-456"
  end

  test "close session response serialization" do
    resp = ACP.V1.CloseSessionResponse.new()
    json = ACP.V1.CloseSessionResponse.to_json(resp)
    assert json == %{}

    {:ok, decoded} = ACP.V1.CloseSessionResponse.from_json(json)
    assert decoded == %ACP.V1.CloseSessionResponse{meta: nil}
  end

  test "nil fields omitted from JSON" do
    impl = ACP.V1.Implementation.new("test", "1.0")
    json = ACP.V1.Implementation.to_json(impl)
    refute Map.has_key?(json, "title")
    refute Map.has_key?(json, "_meta")
  end

  test "meta field uses _meta key" do
    impl = %ACP.V1.Implementation{name: "test", version: "1.0", meta: %{"custom" => true}}
    json = ACP.V1.Implementation.to_json(impl)
    assert json["_meta"] == %{"custom" => true}
    {:ok, decoded} = ACP.V1.Implementation.from_json(json)
    assert decoded.meta == %{"custom" => true}
  end
end
