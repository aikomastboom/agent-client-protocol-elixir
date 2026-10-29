defmodule ACP.V2.NegotiationTest do
  use ExUnit.Case, async: true

  alias ACP.V2.Negotiation

  describe "select/2" do
    test "picks the requested version when it is supported" do
      assert {:ok, 2} = Negotiation.select(%{"protocolVersion" => 2}, [1, 2])
      assert {:ok, 1} = Negotiation.select(%{"protocolVersion" => 1}, [1, 2])
    end

    test "falls back to the highest supported version at or below the request" do
      # Requesting a version newer than anything we know must select our best,
      # not fail - the peer said "2 or lower", we answer 2.
      assert {:ok, 2} = Negotiation.select(%{"protocolVersion" => 5}, [1, 2])
      assert {:ok, 1} = Negotiation.select(%{"protocolVersion" => 5}, [1])
      assert {:ok, 1} = Negotiation.select(%{"protocolVersion" => 1}, [1, 2, 3])
    end

    test "rejects a missing protocolVersion with -32602" do
      assert {:error, %ACP.Error{code: -32_602}} = Negotiation.select(%{}, [1, 2])
      assert {:error, %ACP.Error{code: -32_602}} = Negotiation.select(nil, [1, 2])

      assert {:error, %ACP.Error{code: -32_602}} =
               Negotiation.select(%{"protocolVersion" => nil}, [1, 2])
    end

    test "rejects a non-integer protocolVersion with -32602" do
      assert {:error, %ACP.Error{code: -32_602}} =
               Negotiation.select(%{"protocolVersion" => "2"}, [1, 2])

      assert {:error, %ACP.Error{code: -32_602}} =
               Negotiation.select(%{"protocolVersion" => 1.5}, [1, 2])
    end

    test "rejects an out-of-range protocolVersion with -32602" do
      assert {:error, %ACP.Error{code: -32_602}} =
               Negotiation.select(%{"protocolVersion" => -1}, [1, 2])

      # uint16 per the v2 schema
      assert {:error, %ACP.Error{code: -32_602}} =
               Negotiation.select(%{"protocolVersion" => 65_536}, [1, 2])

      assert {:ok, 2} = Negotiation.select(%{"protocolVersion" => 65_535}, [1, 2])
    end

    test "rejects with -32022 when no supported version is at or below the request" do
      assert {:error, %ACP.Error{code: -32_022} = err} =
               Negotiation.select(%{"protocolVersion" => 0}, [1, 2])

      assert err.data == %{"requested" => 0, "supported" => [1, 2]}
    end

    test "-32022 reports an empty supported list when nothing is configured" do
      assert {:error, %ACP.Error{code: -32_022} = err} =
               Negotiation.select(%{"protocolVersion" => 1}, [])

      assert err.data == %{"requested" => 1, "supported" => []}
    end

    test "the -32022 message and code name are the documented ones" do
      assert {:error, err} = Negotiation.select(%{"protocolVersion" => 0}, [1])
      assert err.message == "Unsupported protocol version"
      assert ACP.Error.code_name(-32_022) == :unsupported_protocol_version
      assert ACP.Error.unsupported_protocol_version_code() == -32_022
    end

    test "supported versions do not need to be pre-sorted" do
      assert {:ok, 2} = Negotiation.select(%{"protocolVersion" => 2}, [2, 1])
      assert {:ok, 1} = Negotiation.select(%{"protocolVersion" => 1}, [2, 1])
    end
  end

  describe "check_selected/2" do
    # The client half of negotiation: a client must use exactly the version the
    # agent selected, with no fallback.

    test "accepts a selected version this side supports" do
      assert {:ok, 1} = Negotiation.check_selected(1, [1, 2])
      assert {:ok, 2} = Negotiation.check_selected(2, [1, 2])
    end

    test "rejects a selected version this side does not support" do
      assert {:error, %ACP.Error{code: -32_022} = err} = Negotiation.check_selected(2, [1])
      assert err.data == %{"requested" => 2, "supported" => [1]}
    end

    test "does not fall back to a lower version" do
      # select/2 answers 1 here; check_selected must not.
      assert {:ok, _} = Negotiation.select(%{"protocolVersion" => 2}, [1])
      assert {:error, %ACP.Error{code: -32_022}} = Negotiation.check_selected(2, [1])
    end

    test "rejects a malformed selection with -32602" do
      assert {:error, %ACP.Error{code: -32_602}} = Negotiation.check_selected("2", [1, 2])
      assert {:error, %ACP.Error{code: -32_602}} = Negotiation.check_selected(nil, [1, 2])
      assert {:error, %ACP.Error{code: -32_602}} = Negotiation.check_selected(65_536, [1, 2])
    end
  end
end
