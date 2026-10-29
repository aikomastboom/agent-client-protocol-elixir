defmodule ACP.ProtocolVersionTest do
  use ExUnit.Case, async: true

  test "v0 is 0" do
    assert ACP.ProtocolVersion.v0() == 0
  end

  test "v1 is 1" do
    assert ACP.ProtocolVersion.v1() == 1
  end

  test "v2 is 2" do
    assert ACP.ProtocolVersion.v2() == 2
  end

  test "latest is v1" do
    assert ACP.ProtocolVersion.latest() == ACP.ProtocolVersion.v1()
  end

  test "latest stays v1 while v2 is not yet the default" do
    refute ACP.ProtocolVersion.latest() == ACP.ProtocolVersion.v2()
  end

  test "from_json integer passes through" do
    assert ACP.ProtocolVersion.from_json(1) == {:ok, 1}
    assert ACP.ProtocolVersion.from_json(0) == {:ok, 0}
    assert ACP.ProtocolVersion.from_json(2) == {:ok, 2}
  end

  test "v2 round-trips through from_json" do
    assert ACP.ProtocolVersion.from_json(ACP.ProtocolVersion.v2()) ==
             {:ok, ACP.ProtocolVersion.v2()}
  end

  test "from_json string becomes v0" do
    assert ACP.ProtocolVersion.from_json("anything") == {:ok, 0}
  end

  test "from_json invalid" do
    assert ACP.ProtocolVersion.from_json(-1) == {:error, :invalid_protocol_version}
  end
end
