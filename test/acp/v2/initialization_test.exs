defmodule ACP.V2.InitializationTest do
  use ExUnit.Case, async: true

  # Fixtures adapted from the v2 initialization docs' own worked examples.
  @request_json %{
    "protocolVersion" => 2,
    "capabilities" => %{"auth" => %{"terminal" => %{}}},
    "info" => %{"name" => "my-client", "title" => "My Client", "version" => "1.0.0"}
  }

  @response_json %{
    "protocolVersion" => 2,
    "capabilities" => %{
      "session" => %{
        "prompt" => %{"image" => %{}, "audio" => %{}, "embeddedContext" => %{}},
        "mcp" => %{"stdio" => %{}, "http" => %{}}
      }
    },
    "info" => %{"name" => "my-agent", "title" => "My Agent", "version" => "1.0.0"},
    "authMethods" => []
  }

  # -- Implementation --

  describe "Implementation" do
    test "round-trips required and optional fields" do
      {:ok, impl} = ACP.V2.Implementation.from_json(@request_json["info"])

      assert impl.name == "my-client"
      assert impl.title == "My Client"
      assert impl.version == "1.0.0"
      assert impl.meta == nil

      assert ACP.V2.Implementation.to_json(impl) == @request_json["info"]
    end

    test "requires name and version" do
      assert {:error, _} = ACP.V2.Implementation.from_json(%{"name" => "x"})
      assert {:error, _} = ACP.V2.Implementation.from_json(%{"version" => "1"})
      assert {:error, _} = ACP.V2.Implementation.from_json("nope")
    end

    test "omits title and _meta when unset, and treats null title as absent" do
      {:ok, impl} = ACP.V2.Implementation.from_json(%{"name" => "n", "version" => "1"})
      assert ACP.V2.Implementation.to_json(impl) == %{"name" => "n", "version" => "1"}

      {:ok, with_null} =
        ACP.V2.Implementation.from_json(%{
          "name" => "n",
          "version" => "1",
          "title" => nil,
          "_meta" => nil
        })

      assert with_null.title == nil
      assert ACP.V2.Implementation.to_json(with_null) == %{"name" => "n", "version" => "1"}
    end

    test "keeps _meta payload verbatim" do
      {:ok, impl} =
        ACP.V2.Implementation.from_json(%{
          "name" => "n",
          "version" => "1",
          "_meta" => %{"x" => 1}
        })

      assert impl.meta == %{"x" => 1}

      assert ACP.V2.Implementation.to_json(impl) == %{
               "name" => "n",
               "version" => "1",
               "_meta" => %{"x" => 1}
             }
    end
  end

  # -- Client capabilities --

  describe "ClientCapabilities" do
    test "decodes auth.terminal as a present marker" do
      {:ok, caps} = ACP.V2.ClientCapabilities.from_json(@request_json["capabilities"])

      assert %ACP.V2.ClientAuthCapabilities{terminal: %{}} = caps.auth
      assert ACP.V2.ClientCapabilities.to_json(caps) == @request_json["capabilities"]
    end

    test "absent and null capability fields both mean unsupported" do
      {:ok, absent} = ACP.V2.ClientCapabilities.from_json(%{})
      assert absent.auth == nil
      assert absent.elicitation == nil
      assert ACP.V2.ClientCapabilities.to_json(absent) == %{}

      {:ok, nulls} = ACP.V2.ClientCapabilities.from_json(%{"auth" => nil, "elicitation" => nil})
      assert nulls.auth == nil
      assert nulls.elicitation == nil
    end

    test "an empty terminal marker still advertises support" do
      {:ok, caps} = ACP.V2.ClientCapabilities.from_json(%{"auth" => %{"terminal" => %{}}})
      assert caps.auth.terminal == %{}
      assert ACP.V2.ClientCapabilities.to_json(caps) == %{"auth" => %{"terminal" => %{}}}
    end

    test "a populated marker object is preserved verbatim" do
      {:ok, caps} =
        ACP.V2.ClientCapabilities.from_json(%{
          "auth" => %{"terminal" => %{"_meta" => %{"k" => 1}}}
        })

      assert caps.auth.terminal == %{"_meta" => %{"k" => 1}}

      assert ACP.V2.ClientCapabilities.to_json(caps) == %{
               "auth" => %{"terminal" => %{"_meta" => %{"k" => 1}}}
             }
    end

    test "unknown capability fields are ignored, not treated as support" do
      {:ok, caps} = ACP.V2.ClientCapabilities.from_json(%{"auth" => %{"wat" => %{}}})
      assert caps.auth.terminal == nil
    end
  end

  # -- Agent capabilities --

  describe "AgentCapabilities" do
    test "round-trips the documented v2 response capabilities" do
      {:ok, caps} = ACP.V2.AgentCapabilities.from_json(@response_json["capabilities"])

      assert %ACP.V2.SessionCapabilities{} = caps.session

      assert %ACP.V2.PromptCapabilities{image: %{}, audio: %{}, embedded_context: %{}} =
               caps.session.prompt

      assert %ACP.V2.McpCapabilities{stdio: %{}, http: %{}} = caps.session.mcp

      assert ACP.V2.AgentCapabilities.to_json(caps) == @response_json["capabilities"]
    end

    test "session: {} means baseline session support and survives a round trip" do
      {:ok, caps} = ACP.V2.AgentCapabilities.from_json(%{"session" => %{}})

      assert %ACP.V2.SessionCapabilities{} = caps.session
      assert caps.session.prompt == nil
      assert caps.session.delete == nil
      assert ACP.V2.AgentCapabilities.to_json(caps) == %{"session" => %{}}
    end

    test "omitted session means no session surface at all" do
      {:ok, caps} = ACP.V2.AgentCapabilities.from_json(%{})
      assert caps.session == nil
      assert caps.auth == nil
      assert ACP.V2.AgentCapabilities.to_json(caps) == %{}
    end

    test "delete and additionalDirectories markers decode and re-encode" do
      json = %{
        "session" => %{"delete" => %{}, "additionalDirectories" => %{"_meta" => %{"a" => 1}}}
      }

      {:ok, caps} = ACP.V2.AgentCapabilities.from_json(json)

      assert caps.session.delete == %{}
      assert caps.session.additional_directories == %{"_meta" => %{"a" => 1}}
      assert ACP.V2.AgentCapabilities.to_json(caps) == json
    end

    test "null session is equivalent to omitted" do
      {:ok, caps} = ACP.V2.AgentCapabilities.from_json(%{"session" => nil, "auth" => nil})
      assert caps.session == nil
      assert caps.auth == nil
    end
  end

  # -- Initialize request/response --

  describe "InitializeRequest" do
    test "round-trips the documented v2 request" do
      {:ok, req} = ACP.V2.InitializeRequest.from_json(@request_json)

      assert req.protocol_version == 2
      assert req.info.name == "my-client"
      assert %ACP.V2.ClientCapabilities{} = req.capabilities
      assert ACP.V2.InitializeRequest.to_json(req) == @request_json
    end

    test "protocolVersion and info are required" do
      assert {:error, _} =
               ACP.V2.InitializeRequest.from_json(%{"info" => %{"name" => "n", "version" => "1"}})

      assert {:error, _} =
               ACP.V2.InitializeRequest.from_json(%{"protocolVersion" => 2})
    end

    test "capabilities default to none when absent" do
      {:ok, req} =
        ACP.V2.InitializeRequest.from_json(%{
          "protocolVersion" => 2,
          "info" => %{"name" => "n", "version" => "1"}
        })

      assert %ACP.V2.ClientCapabilities{auth: nil, elicitation: nil} = req.capabilities
    end

    test "carries _meta through" do
      json = Map.put(@request_json, "_meta", %{"trace" => "abc"})
      {:ok, req} = ACP.V2.InitializeRequest.from_json(json)
      assert req.meta == %{"trace" => "abc"}
      assert ACP.V2.InitializeRequest.to_json(req) == json
    end
  end

  describe "InitializeResponse" do
    test "round-trips the documented v2 response" do
      {:ok, res} = ACP.V2.InitializeResponse.from_json(@response_json)

      assert res.protocol_version == 2
      assert res.info.name == "my-agent"
      assert %ACP.V2.AgentCapabilities{} = res.capabilities
      assert res.auth_methods == []
      assert ACP.V2.InitializeResponse.to_json(res) == @response_json
    end

    test "protocolVersion and info are required" do
      assert {:error, _} =
               ACP.V2.InitializeResponse.from_json(%{
                 "info" => %{"name" => "n", "version" => "1"}
               })

      assert {:error, _} =
               ACP.V2.InitializeResponse.from_json(%{"protocolVersion" => 2})
    end

    test "authMethods is optional and passes through verbatim" do
      json =
        Map.put(@response_json, "authMethods", [
          %{"id" => "terminal", "type" => "terminal"}
        ])

      {:ok, res} = ACP.V2.InitializeResponse.from_json(json)
      assert res.auth_methods == [%{"id" => "terminal", "type" => "terminal"}]
      assert ACP.V2.InitializeResponse.to_json(res) == json
    end

    test "omitted authMethods stays absent, and an empty list stays present" do
      json = Map.delete(@response_json, "authMethods")
      {:ok, res} = ACP.V2.InitializeResponse.from_json(json)
      assert res.auth_methods == nil
      refute Map.has_key?(ACP.V2.InitializeResponse.to_json(res), "authMethods")

      {:ok, empty} = ACP.V2.InitializeResponse.from_json(@response_json)
      assert empty.auth_methods == []
      assert ACP.V2.InitializeResponse.to_json(empty)["authMethods"] == []
    end
  end

  # -- Role dispatch --

  describe "Capabilities role dispatch" do
    test "decodes and encodes per role" do
      {:ok, client} = ACP.V2.Capabilities.from_json(:client, @request_json["capabilities"])
      assert %ACP.V2.ClientCapabilities{} = client

      {:ok, agent} = ACP.V2.Capabilities.from_json(:agent, @response_json["capabilities"])
      assert %ACP.V2.AgentCapabilities{} = agent

      assert ACP.V2.Capabilities.to_json(:client, client) == @request_json["capabilities"]
      assert ACP.V2.Capabilities.to_json(:agent, agent) == @response_json["capabilities"]
    end

    test "nil and null decode to the empty capability struct for the role" do
      {:ok, client} = ACP.V2.Capabilities.from_json(:client, nil)
      assert %ACP.V2.ClientCapabilities{} = client

      {:ok, agent} = ACP.V2.Capabilities.from_json(:agent, %{})
      assert %ACP.V2.AgentCapabilities{} = agent
    end

    test "rejects an unknown role" do
      assert {:error, :unknown_role} = ACP.V2.Capabilities.from_json(:wizard, %{})
      assert {:error, :unknown_role} = ACP.V2.Capabilities.to_json(:wizard, %{})
    end
  end
end
