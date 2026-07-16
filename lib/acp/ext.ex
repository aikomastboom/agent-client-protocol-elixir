defmodule ACP.Ext do
  @moduledoc "Extension types for protocol extensibility."

  @type meta :: %{optional(String.t()) => any()} | nil
end

defmodule ACP.ExtRequest do
  @moduledoc "Arbitrary request not part of the ACP spec."

  @type t :: %__MODULE__{
          method: String.t(),
          params: any()
        }

  @enforce_keys [:method, :params]
  defstruct [:method, :params]

  def new(method, params), do: %__MODULE__{method: method, params: params}
end

defmodule ACP.ExtResponse do
  @moduledoc "Response to an ExtRequest."

  @type t :: %__MODULE__{
          data: any()
        }

  defstruct [:data]

  def new(data), do: %__MODULE__{data: data}

  def to_json(%__MODULE__{data: data}), do: data

  def from_json(data), do: {:ok, %__MODULE__{data: data}}
end

defmodule ACP.ExtNotification do
  @moduledoc "Arbitrary notification not part of the ACP spec."

  @type t :: %__MODULE__{
          method: String.t(),
          params: any()
        }

  @enforce_keys [:method, :params]
  defstruct [:method, :params]

  def new(method, params), do: %__MODULE__{method: method, params: params}
end
