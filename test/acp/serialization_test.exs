defmodule ACP.SerializationTest do
  use ExUnit.Case, async: true
  @moduledoc "Cross-cutting JSON serialization tests matching Rust test cases."

  test "McpServer stdio serialization matches Rust" do
    server =
      {:stdio,
       %ACP.McpServerStdio{
         name: "test-server",
         command: "/usr/bin/server",
         args: ["--port", "3000"],
         env: [ACP.EnvVariable.new("API_KEY", "secret123")]
       }}

    json = ACP.McpServer.to_json(server)

    assert json == %{
             "name" => "test-server",
             "command" => "/usr/bin/server",
             "args" => ["--port", "3000"],
             "env" => [%{"name" => "API_KEY", "value" => "secret123"}]
           }

    {:ok, decoded} = ACP.McpServer.from_json(json)
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
       %ACP.McpServerHttp{
         name: "http-server",
         url: "https://api.example.com",
         headers: [
           ACP.HttpHeader.new("Authorization", "Bearer token123"),
           ACP.HttpHeader.new("Content-Type", "application/json")
         ]
       }}

    json = ACP.McpServer.to_json(server)
    assert json["type"] == "http"
    assert json["name"] == "http-server"
    assert json["url"] == "https://api.example.com"
    assert length(json["headers"]) == 2

    {:ok, decoded} = ACP.McpServer.from_json(json)
    assert {:http, http} = decoded
    assert http.name == "http-server"
    assert length(http.headers) == 2
  end

  test "McpServer sse serialization matches Rust" do
    server =
      {:sse,
       %ACP.McpServerSse{
         name: "sse-server",
         url: "https://sse.example.com/events",
         headers: [ACP.HttpHeader.new("X-API-Key", "apikey456")]
       }}

    json = ACP.McpServer.to_json(server)
    assert json["type"] == "sse"
    assert json["name"] == "sse-server"

    {:ok, decoded} = ACP.McpServer.from_json(json)
    assert {:sse, sse} = decoded
    assert sse.url == "https://sse.example.com/events"
  end

  test "full initialize round-trip" do
    req = ACP.InitializeRequest.new(1)
    json = ACP.InitializeRequest.to_json(req)
    encoded = Jason.encode!(json)
    decoded_json = Jason.decode!(encoded)
    {:ok, decoded} = ACP.InitializeRequest.from_json(decoded_json)
    assert decoded.protocol_version == 1
  end

  test "notification wire format" do
    notif = ACP.CancelNotification.new("test-123")
    json = ACP.CancelNotification.to_json(notif)
    assert json == %{"sessionId" => "test-123"}
  end

  test "close session request serialization" do
    req = ACP.CloseSessionRequest.new("session-456")
    json = ACP.CloseSessionRequest.to_json(req)
    assert json == %{"sessionId" => "session-456"}

    {:ok, decoded} = ACP.CloseSessionRequest.from_json(json)
    assert decoded.session_id == "session-456"
  end

  test "close session response serialization" do
    resp = ACP.CloseSessionResponse.new()
    json = ACP.CloseSessionResponse.to_json(resp)
    assert json == %{}

    {:ok, decoded} = ACP.CloseSessionResponse.from_json(json)
    assert decoded == %ACP.CloseSessionResponse{meta: nil}
  end

  test "nil fields omitted from JSON" do
    impl = ACP.Implementation.new("test", "1.0")
    json = ACP.Implementation.to_json(impl)
    refute Map.has_key?(json, "title")
    refute Map.has_key?(json, "_meta")
  end

  test "meta field uses _meta key" do
    impl = %ACP.Implementation{name: "test", version: "1.0", meta: %{"custom" => true}}
    json = ACP.Implementation.to_json(impl)
    assert json["_meta"] == %{"custom" => true}
    {:ok, decoded} = ACP.Implementation.from_json(json)
    assert decoded.meta == %{"custom" => true}
  end
end
