defmodule ACP.UsageUpdateTest do
  use ExUnit.Case, async: true

  alias ACP.UsageUpdate

  test "new/2 builds a usage update with used and size" do
    uu = UsageUpdate.new(50_000, 200_000)
    assert uu.used == 50_000
    assert uu.size == 200_000
    assert uu.cost == nil
  end

  test "new/3 accepts optional cost as {amount, currency}" do
    uu = UsageUpdate.new(50_000, 200_000, {0.42, "USD"})
    assert uu.cost == %{amount: 0.42, currency: "USD"}
  end

  test "SessionUpdate to_json emits usage_update with used/size" do
    uu = UsageUpdate.new(123, 456)
    json = ACP.SessionUpdate.to_json({:usage_update, uu})
    assert json["sessionUpdate"] == "usage_update"
    assert json["used"] == 123
    assert json["size"] == 456
    refute Map.has_key?(json, "cost")
  end

  test "SessionUpdate to_json includes cost when present" do
    uu = UsageUpdate.new(123, 456, {1.5, "EUR"})
    json = ACP.SessionUpdate.to_json({:usage_update, uu})
    assert json["cost"] == %{"amount" => 1.5, "currency" => "EUR"}
  end

  test "SessionUpdate from_json round-trips usage_update" do
    uu = UsageUpdate.new(999, 1_000_000, {0.01, "USD"})
    json = ACP.SessionUpdate.to_json({:usage_update, uu})
    assert {:usage_update, decoded} = ACP.SessionUpdate.from_json(json)
    assert decoded.used == 999
    assert decoded.size == 1_000_000
    assert decoded.cost == %{amount: 0.01, currency: "USD"}
  end

  test "SessionNotification round-trips usage_update" do
    notif = ACP.SessionNotification.new("s1", {:usage_update, UsageUpdate.new(10, 20)})
    json = ACP.SessionNotification.to_json(notif)
    assert json["update"]["sessionUpdate"] == "usage_update"
    {:ok, decoded} = ACP.SessionNotification.from_json(json)
    assert {:usage_update, uu} = decoded.update
    assert uu.used == 10
    assert uu.size == 20
  end

  test "Jason encodes usage_update via SessionUpdate" do
    json =
      {:usage_update, UsageUpdate.new(1, 2)}
      |> ACP.SessionUpdate.to_json()
      |> Jason.encode!()

    assert json =~ "\"usage_update\""
  end
end
