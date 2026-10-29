defmodule ACP.V1.Plan do
  @moduledoc "Execution plan for complex tasks."

  @type t :: %__MODULE__{
          entries: [ACP.V1.PlanEntry.t()],
          meta: ACP.Ext.meta()
        }

  @enforce_keys [:entries]
  defstruct [:entries, :meta]

  def new(entries), do: %__MODULE__{entries: entries}

  def to_json(%__MODULE__{} = plan) do
    map = %{"entries" => Enum.map(plan.entries, &ACP.V1.PlanEntry.to_json/1)}
    if plan.meta, do: Map.put(map, "_meta", plan.meta), else: map
  end

  def from_json(%{"entries" => entries} = map) do
    {:ok,
     %__MODULE__{
       entries:
         Enum.map(entries, fn e ->
           {:ok, pe} = ACP.V1.PlanEntry.from_json(e)
           pe
         end),
       meta: Map.get(map, "_meta")
     }}
  end
end

defmodule ACP.V1.PlanEntry do
  @moduledoc "A single entry in the execution plan."

  @type t :: %__MODULE__{
          content: String.t(),
          priority: ACP.V1.PlanEntry.priority(),
          status: ACP.V1.PlanEntry.status(),
          meta: ACP.Ext.meta()
        }

  @type priority :: :high | :medium | :low
  @type status :: :pending | :in_progress | :completed

  @enforce_keys [:content, :priority, :status]
  defstruct [:content, :priority, :status, :meta]

  def new(content, priority, status) do
    %__MODULE__{content: content, priority: priority, status: status}
  end

  def to_json(%__MODULE__{} = entry) do
    map = %{
      "content" => entry.content,
      "priority" => encode_priority(entry.priority),
      "status" => encode_status(entry.status)
    }

    if entry.meta, do: Map.put(map, "_meta", entry.meta), else: map
  end

  def from_json(%{"content" => content, "priority" => priority, "status" => status} = map) do
    {:ok,
     %__MODULE__{
       content: content,
       priority: decode_priority(priority),
       status: decode_status(status),
       meta: Map.get(map, "_meta")
     }}
  end

  defp encode_priority(:high), do: "high"
  defp encode_priority(:medium), do: "medium"
  defp encode_priority(:low), do: "low"

  defp decode_priority("high"), do: :high
  defp decode_priority("medium"), do: :medium
  defp decode_priority("low"), do: :low

  defp encode_status(:pending), do: "pending"
  defp encode_status(:in_progress), do: "in_progress"
  defp encode_status(:completed), do: "completed"

  defp decode_status("pending"), do: :pending
  defp decode_status("in_progress"), do: :in_progress
  defp decode_status("completed"), do: :completed
end

defimpl Jason.Encoder, for: ACP.V1.Plan do
  def encode(plan, opts), do: ACP.V1.Plan.to_json(plan) |> Jason.Encoder.encode(opts)
end

defimpl Jason.Encoder, for: ACP.V1.PlanEntry do
  def encode(entry, opts), do: ACP.V1.PlanEntry.to_json(entry) |> Jason.Encoder.encode(opts)
end
