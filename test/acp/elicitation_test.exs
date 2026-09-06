defmodule ACP.ElicitationTest do
  use ExUnit.Case, async: true

  describe "ACP.ElicitationCreateRequest.to_json" do
    test "form mode emits correct keys" do
      req = %ACP.ElicitationCreateRequest{
        session_id: "s1",
        tool_call_id: "tc1",
        mode: "form",
        message: "Need more input",
        requested_schema: %{
          "type" => "object",
          "properties" => %{"name" => %{"type" => "string"}}
        }
      }

      assert ACP.ElicitationCreateRequest.to_json(req) == %{
               "sessionId" => "s1",
               "toolCallId" => "tc1",
               "mode" => "form",
               "message" => "Need more input",
               "requestedSchema" => %{
                 "type" => "object",
                 "properties" => %{"name" => %{"type" => "string"}}
               }
             }
    end

    test "url mode emits elicitationId and url" do
      req = %ACP.ElicitationCreateRequest{
        session_id: "s1",
        mode: "url",
        message: "Authorize access",
        elicitation_id: "el1",
        url: "https://example.com/auth"
      }

      assert ACP.ElicitationCreateRequest.to_json(req) == %{
               "sessionId" => "s1",
               "mode" => "url",
               "message" => "Authorize access",
               "elicitationId" => "el1",
               "url" => "https://example.com/auth"
             }
    end

    test "optional fields omitted when nil" do
      req = %ACP.ElicitationCreateRequest{
        session_id: "s1",
        mode: "form",
        message: "Need more input"
      }

      json = ACP.ElicitationCreateRequest.to_json(req)
      refute Map.has_key?(json, "toolCallId")
      refute Map.has_key?(json, "requestedSchema")
      refute Map.has_key?(json, "elicitationId")
      refute Map.has_key?(json, "url")
      refute Map.has_key?(json, "_meta")
    end
  end

  describe "ACP.ClientSide.decode_request elicitation/create" do
    test "routes to {:elicitation_create, req}" do
      params = %{
        "sessionId" => "s1",
        "toolCallId" => "tc1",
        "mode" => "form",
        "message" => "Need more input",
        "requestedSchema" => %{"type" => "object"}
      }

      {:ok, {:elicitation_create, req}} =
        ACP.ClientSide.decode_request("elicitation/create", params)

      assert req.session_id == "s1"
      assert req.tool_call_id == "tc1"
      assert req.mode == "form"
      assert req.message == "Need more input"
      assert req.requested_schema == %{"type" => "object"}
    end

    test "returns method_not_found for unknown methods" do
      {:error, err} = ACP.ClientSide.decode_request("unknown", %{})
      assert err.code == -32601
    end
  end
end
