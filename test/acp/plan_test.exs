defmodule ACP.PlanTest do
  use ExUnit.Case, async: true

  test "plan entry to_json/from_json" do
    entry = ACP.V1.PlanEntry.new("Write code", :high, :pending)
    json = ACP.V1.PlanEntry.to_json(entry)
    assert json == %{"content" => "Write code", "priority" => "high", "status" => "pending"}
    {:ok, decoded} = ACP.V1.PlanEntry.from_json(json)
    assert decoded.content == "Write code"
    assert decoded.priority == :high
    assert decoded.status == :pending
  end

  test "plan to_json/from_json" do
    plan =
      ACP.V1.Plan.new([
        ACP.V1.PlanEntry.new("Step 1", :high, :completed),
        ACP.V1.PlanEntry.new("Step 2", :medium, :in_progress)
      ])

    json = ACP.V1.Plan.to_json(plan)
    assert length(json["entries"]) == 2
    {:ok, decoded} = ACP.V1.Plan.from_json(json)
    assert length(decoded.entries) == 2
    assert hd(decoded.entries).status == :completed
  end

  test "plan with meta" do
    plan = %ACP.V1.Plan{entries: [], meta: %{"key" => "value"}}
    json = ACP.V1.Plan.to_json(plan)
    assert json["_meta"] == %{"key" => "value"}
  end
end
