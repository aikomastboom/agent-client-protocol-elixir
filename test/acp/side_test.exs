defmodule ACP.SideTest do
  use ExUnit.Case, async: true

  describe "AgentSide" do
    test "decode_request initialize" do
      params = %{"protocolVersion" => 1}
      {:ok, {:initialize, req}} = ACP.AgentSide.decode_request("initialize", params)
      assert req.protocol_version == 1
    end

    test "decode_request session/new" do
      params = %{"cwd" => "/home/user", "mcpServers" => []}
      {:ok, {:new_session, req}} = ACP.AgentSide.decode_request("session/new", params)
      assert req.cwd == "/home/user"
    end

    test "decode_request session/prompt" do
      params = %{"sessionId" => "s1", "prompt" => [%{"type" => "text", "text" => "hello"}]}
      {:ok, {:prompt, req}} = ACP.AgentSide.decode_request("session/prompt", params)
      assert req.session_id == "s1"
    end

    test "decode_request unknown method" do
      {:error, err} = ACP.AgentSide.decode_request("unknown", %{})
      assert err.code == -32601
    end

    test "decode_request extension method" do
      {:ok, {:ext_method, ext}} = ACP.AgentSide.decode_request("_custom", %{"data" => 42})
      assert ext.method == "custom"
    end

    test "decode_request nil params" do
      {:error, err} = ACP.AgentSide.decode_request("initialize", nil)
      assert err.code == -32602
    end

    test "decode_notification session/cancel" do
      params = %{"sessionId" => "s1"}
      {:ok, {:cancel, notif}} = ACP.AgentSide.decode_notification("session/cancel", params)
      assert notif.session_id == "s1"
    end

    test "decode_request session/close" do
      params = %{"sessionId" => "s1"}
      {:ok, {:close, req}} = ACP.AgentSide.decode_request("session/close", params)
      assert req.session_id == "s1"
    end

    test "decode_request session/close missing sessionId" do
      {:error, err} = ACP.AgentSide.decode_request("session/close", %{})
      assert err.code == -32602
    end

    test "decode_notification extension" do
      {:ok, {:ext_notification, ext}} = ACP.AgentSide.decode_notification("_custom", %{"x" => 1})
      assert ext.method == "custom"
    end

    test "decode_notification unknown" do
      {:error, err} = ACP.AgentSide.decode_notification("unknown", %{})
      assert err.code == -32601
    end
  end

  describe "ClientSide" do
    test "decode_request session/request_permission" do
      params = %{
        "sessionId" => "s1",
        "toolCall" => %{"toolCallId" => "tc1", "toolName" => "bash", "status" => "pending"},
        "options" => [%{"optionId" => "allow", "name" => "Allow", "kind" => "allow_once"}]
      }

      {:ok, {:request_permission, req}} =
        ACP.ClientSide.decode_request("session/request_permission", params)

      assert req.session_id == "s1"
    end

    test "decode_request fs/write_text_file" do
      params = %{"sessionId" => "s1", "path" => "/tmp/test.txt", "content" => "hello"}
      {:ok, {:write_text_file, req}} = ACP.ClientSide.decode_request("fs/write_text_file", params)
      assert req.path == "/tmp/test.txt"
    end

    test "decode_request unknown" do
      {:error, err} = ACP.ClientSide.decode_request("unknown", %{})
      assert err.code == -32601
    end

    test "decode_notification session/update" do
      params = %{
        "sessionId" => "s1",
        "update" => %{
          "sessionUpdate" => "agent_message_chunk",
          "content" => %{"type" => "text", "text" => "Hello"}
        }
      }

      {:ok, {:session_notification, notif}} =
        ACP.ClientSide.decode_notification("session/update", params)

      assert notif.session_id == "s1"
    end
  end
end
