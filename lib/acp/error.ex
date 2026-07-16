defmodule ACP.Error do
  @moduledoc "JSON-RPC error object."

  alias ACP.JSONHelpers

  @type t :: %__MODULE__{
          code: integer(),
          message: String.t(),
          data: any() | nil
        }

  @enforce_keys [:code, :message]
  defstruct [:code, :message, :data]

  # Error code constants
  def parse_error_code, do: -32700
  def invalid_request_code, do: -32600
  def method_not_found_code, do: -32601
  def invalid_params_code, do: -32602
  def internal_error_code, do: -32603
  def auth_required_code, do: -32000
  def resource_not_found_code, do: -32002

  # Convenience constructors
  def parse_error, do: %__MODULE__{code: -32700, message: "Parse error"}
  def invalid_request, do: %__MODULE__{code: -32600, message: "Invalid request"}
  def method_not_found, do: %__MODULE__{code: -32601, message: "Method not found"}
  def invalid_params, do: %__MODULE__{code: -32602, message: "Invalid params"}
  def internal_error, do: %__MODULE__{code: -32603, message: "Internal error"}
  def auth_required, do: %__MODULE__{code: -32000, message: "Authentication required"}

  def resource_not_found(uri \\ nil) do
    err = %__MODULE__{code: -32002, message: "Resource not found"}
    if uri, do: %{err | data: %{"uri" => uri}}, else: err
  end

  def new(code, message), do: %__MODULE__{code: code, message: message}

  def with_data(%__MODULE__{} = err, data), do: %{err | data: data}

  @doc "Convert an ErrorCode integer to its name atom."
  def code_name(-32700), do: :parse_error
  def code_name(-32600), do: :invalid_request
  def code_name(-32601), do: :method_not_found
  def code_name(-32602), do: :invalid_params
  def code_name(-32603), do: :internal_error
  def code_name(-32000), do: :auth_required
  def code_name(-32002), do: :resource_not_found
  def code_name(code) when is_integer(code), do: {:other, code}

  def to_json(%__MODULE__{} = err) do
    JSONHelpers.encode_struct(err, [:code, :message, :data])
  end

  def from_json(%{"code" => code, "message" => message} = map) do
    {:ok,
     %__MODULE__{
       code: code,
       message: message,
       data: Map.get(map, "data")
     }}
  end

  def from_json(_), do: {:error, :invalid_error}
end

defimpl Jason.Encoder, for: ACP.Error do
  def encode(err, opts) do
    ACP.Error.to_json(err) |> Jason.Encoder.encode(opts)
  end
end
