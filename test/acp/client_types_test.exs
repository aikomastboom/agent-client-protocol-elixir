defmodule ACP.ClientTypesTest do
  use ExUnit.Case, async: true

  test "SessionNotification to_json/from_json with agent_message_chunk" do
    chunk = ACP.V1.ContentChunk.new({:text, %ACP.V1.TextContent{text: "Hello"}})
    update = {:agent_message_chunk, chunk}
    notif = ACP.V1.SessionNotification.new("s1", update)
    json = ACP.V1.SessionNotification.to_json(notif)
    assert json["sessionId"] == "s1"
    assert json["update"]["sessionUpdate"] == "agent_message_chunk"
    {:ok, decoded} = ACP.V1.SessionNotification.from_json(json)
    assert decoded.session_id == "s1"
    assert {:agent_message_chunk, _} = decoded.update
  end

  test "SessionUpdate plan" do
    plan = ACP.V1.Plan.new([ACP.V1.PlanEntry.new("Do thing", :high, :pending)])
    update = {:plan, plan}
    json = ACP.V1.SessionUpdate.to_json(update)
    assert json["sessionUpdate"] == "plan"
    assert length(json["entries"]) == 1
  end

  test "SessionUpdate current_mode_update" do
    cmu = ACP.V1.CurrentModeUpdate.new("architect")
    json = ACP.V1.SessionUpdate.to_json({:current_mode_update, cmu})
    assert json["sessionUpdate"] == "current_mode_update"
    assert json["currentModeId"] == "architect"
  end

  test "PermissionOption to_json/from_json" do
    opt = ACP.V1.PermissionOption.new("allow-once", "Allow Once", :allow_once)
    json = ACP.V1.PermissionOption.to_json(opt)
    assert json["optionId"] == "allow-once"
    assert json["kind"] == "allow_once"
    {:ok, decoded} = ACP.V1.PermissionOption.from_json(json)
    assert decoded.kind == :allow_once
  end

  test "RequestPermissionOutcome cancelled" do
    json = ACP.V1.RequestPermissionOutcome.to_json(:cancelled)
    assert json == %{"outcome" => "cancelled"}
    assert :cancelled = ACP.V1.RequestPermissionOutcome.from_json(json)
  end

  test "RequestPermissionOutcome selected" do
    outcome = {:selected, ACP.V1.SelectedPermissionOutcome.new("opt-1")}
    json = ACP.V1.RequestPermissionOutcome.to_json(outcome)
    assert json["outcome"] == "selected"
    assert json["optionId"] == "opt-1"
    decoded = ACP.V1.RequestPermissionOutcome.from_json(json)
    assert {:selected, s} = decoded
    assert s.option_id == "opt-1"
  end

  test "WriteTextFileRequest to_json/from_json" do
    req = ACP.V1.WriteTextFileRequest.new("s1", "/tmp/test.txt", "hello world")
    json = ACP.V1.WriteTextFileRequest.to_json(req)
    assert json["path"] == "/tmp/test.txt"
    assert json["content"] == "hello world"
    {:ok, decoded} = ACP.V1.WriteTextFileRequest.from_json(json)
    assert decoded.content == "hello world"
  end

  test "ReadTextFileRequest with line/limit" do
    req = %ACP.V1.ReadTextFileRequest{session_id: "s1", path: "/test", line: 10, limit: 50}
    json = ACP.V1.ReadTextFileRequest.to_json(req)
    assert json["line"] == 10
    assert json["limit"] == 50
  end

  test "CreateTerminalRequest to_json/from_json" do
    req = ACP.V1.CreateTerminalRequest.new("s1", "echo")
    json = ACP.V1.CreateTerminalRequest.to_json(req)
    assert json["command"] == "echo"
    {:ok, decoded} = ACP.V1.CreateTerminalRequest.from_json(json)
    assert decoded.command == "echo"
  end

  test "TerminalExitStatus to_json/from_json" do
    status = ACP.V1.TerminalExitStatus.new(0)
    json = ACP.V1.TerminalExitStatus.to_json(status)
    assert json["exitCode"] == 0
    {:ok, decoded} = ACP.V1.TerminalExitStatus.from_json(json)
    assert decoded.exit_code == 0
  end

  test "ClientCapabilities defaults" do
    caps = ACP.V1.ClientCapabilities.new()
    assert caps.terminal == false
    assert caps.file_system == nil
  end

  test "FileSystemCapability to_json/from_json" do
    fs = %ACP.V1.FileSystemCapability{write_text_file: true, read_text_file: true}
    json = ACP.V1.FileSystemCapability.to_json(fs)
    assert json["writeTextFile"] == true
    {:ok, decoded} = ACP.V1.FileSystemCapability.from_json(json)
    assert decoded.write_text_file == true
  end

  test "AvailableCommand to_json/from_json" do
    cmd = ACP.V1.AvailableCommand.new("commit", "Commit changes")
    json = ACP.V1.AvailableCommand.to_json(cmd)
    assert json["name"] == "commit"
    {:ok, decoded} = ACP.V1.AvailableCommand.from_json(json)
    assert decoded.description == "Commit changes"
  end

  describe "ACP.V1.ElicitationCapability" do
    test "to_json/from_json round-trip with form and url" do
      capability = %ACP.V1.ElicitationCapability{
        form: ACP.V1.ElicitationFormCapability.new(),
        url: ACP.V1.ElicitationUrlCapability.new()
      }

      json = ACP.V1.ElicitationCapability.to_json(capability)
      assert json == %{"form" => %{}, "url" => %{}}

      {:ok, decoded} = ACP.V1.ElicitationCapability.from_json(json)
      assert %ACP.V1.ElicitationFormCapability{} = decoded.form
      assert %ACP.V1.ElicitationUrlCapability{} = decoded.url
    end

    test "to_json omits absent modes" do
      capability = %ACP.V1.ElicitationCapability{form: ACP.V1.ElicitationFormCapability.new()}

      assert ACP.V1.ElicitationCapability.to_json(capability) == %{"form" => %{}}
    end
  end

  describe "ACP.V1.ClientCapabilities with elicitation" do
    test "from_json without elicitation key returns nil" do
      {:ok, caps} = ACP.V1.ClientCapabilities.from_json(%{"terminal" => true})
      assert caps.elicitation == nil
    end

    test "to_json includes elicitation when present" do
      caps = %ACP.V1.ClientCapabilities{
        terminal: true,
        elicitation: %ACP.V1.ElicitationCapability{form: ACP.V1.ElicitationFormCapability.new()}
      }

      assert ACP.V1.ClientCapabilities.to_json(caps) == %{
               "terminal" => true,
               "elicitation" => %{"form" => %{}}
             }
    end
  end

  describe "ACP.V1.ElicitationCreateResponse" do
    test "from_json accept with content" do
      {:ok, response} =
        ACP.V1.ElicitationCreateResponse.from_json(%{
          "action" => "accept",
          "content" => %{"foo" => "bar"}
        })

      assert response.action == :accept
      assert response.content == %{"foo" => "bar"}
    end

    test "from_json decline" do
      {:ok, response} = ACP.V1.ElicitationCreateResponse.from_json(%{"action" => "decline"})
      assert response.action == :decline
    end

    test "from_json cancel" do
      {:ok, response} = ACP.V1.ElicitationCreateResponse.from_json(%{"action" => "cancel"})
      assert response.action == :cancel
    end
  end
end
