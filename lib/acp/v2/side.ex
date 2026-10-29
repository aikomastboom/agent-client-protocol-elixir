defmodule ACP.V2.Side do
  @moduledoc """
  Side behaviour for decoding v2 JSON-RPC messages into typed structs.

  Same contract as `ACP.V1.Side`: each side knows how to decode the requests and
  notifications it expects to receive. `ACP.Connection` selects the side module
  per message from the version negotiated during `initialize`, so a v1
  connection never reaches these modules and a v2 connection never reaches
  `ACP.V1.Side`.
  """

  @callback decode_request(method :: String.t(), params :: map() | nil) ::
              {:ok, any()} | {:error, ACP.Error.t()}

  @callback decode_notification(method :: String.t(), params :: map() | nil) ::
              {:ok, any()} | {:error, ACP.Error.t()}
end

defmodule ACP.V2.ClientSide do
  @moduledoc """
  Client side of a v2 ACP connection.

  Reserved for the phases that add v2 client-side methods; every method is
  `method_not_found` for now.
  """

  @behaviour ACP.V2.Side

  @impl true
  def decode_request(_method, _params), do: {:error, ACP.Error.method_not_found()}

  @impl true
  def decode_notification(_method, _params), do: {:error, ACP.Error.method_not_found()}
end

defmodule ACP.V2.AgentSide do
  @moduledoc """
  Agent side of a v2 ACP connection.

  Decodes `initialize` in its v2 shape. Everything else returns
  `method_not_found` until the phase that implements it adds a branch here — a
  v2-negotiated connection can complete `initialize` and nothing more, by
  design (see the migration phase plan).
  """

  @behaviour ACP.V2.Side

  @impl true
  def decode_request(_method, nil),
    do: {:error, invalid_params_with_reason("Missing request params")}

  def decode_request("initialize", params) do
    case ACP.V2.InitializeRequest.from_json(params) do
      {:ok, request} -> {:ok, {:initialize, request}}
      {:error, _error} -> {:error, invalid_params_with_reason("Invalid v2 initialize params")}
    end
  end

  def decode_request(_method, _params), do: {:error, ACP.Error.method_not_found()}

  @impl true
  def decode_notification(_method, _params), do: {:error, ACP.Error.method_not_found()}

  defp invalid_params_with_reason(reason) do
    ACP.Error.with_data(ACP.Error.invalid_params(), %{"reason" => reason})
  end
end
