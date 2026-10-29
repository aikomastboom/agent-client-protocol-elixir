defmodule ACP.V2.Negotiation do
  @moduledoc """
  Version negotiation for the `initialize` handshake.

  The agent side **selects** a version from the peer's request; the client side
  **checks** the version the agent selected. Both rules come from the v2
  protocol's "Version Negotiation" section:

    * `protocolVersion` is read before any other parameter. Missing,
      non-integer, or out-of-range values are malformed params: `-32602`.
    * The agent selects the highest version it supports that is at or below the
      requested version.
    * If no supported version is at or below the request, the agent rejects with
      `-32022` and structured `requested`/`supported` data.
  """

  alias ACP.{Error, ProtocolVersion}

  @doc """
  Select the version to use for a connection, given an incoming `initialize`
  request's params and the versions this side supports.

  Returns `{:ok, version}` or `{:error, %ACP.Error{}}`.
  """
  @spec select(map() | nil, [non_neg_integer()]) :: {:ok, non_neg_integer()} | {:error, Error.t()}
  def select(params, supported \\ ProtocolVersion.supported())

  def select(%{"protocolVersion" => requested}, supported) do
    if ProtocolVersion.valid?(requested) do
      case supported |> Enum.filter(&(&1 <= requested)) |> Enum.sort() do
        [] -> {:error, Error.unsupported_protocol_version(requested, supported)}
        candidates -> {:ok, List.last(candidates)}
      end
    else
      {:error, invalid_params(requested)}
    end
  end

  # Missing protocolVersion entirely.
  def select(_params, _supported) do
    {:error, invalid_params(nil)}
  end

  @doc """
  Check a version an agent selected in its `initialize` response.

  Unlike `select/2` this does not fall back: a client must use exactly the
  version the agent chose, or close the connection.
  """
  @spec check_selected(term(), [non_neg_integer()]) ::
          {:ok, non_neg_integer()} | {:error, Error.t()}
  def check_selected(version, supported \\ ProtocolVersion.supported())

  def check_selected(version, supported) do
    cond do
      not ProtocolVersion.valid?(version) ->
        {:error, invalid_params(version)}

      version in supported ->
        {:ok, version}

      true ->
        {:error, Error.unsupported_protocol_version(version, supported)}
    end
  end

  defp invalid_params(requested) do
    Error.with_data(Error.invalid_params(), %{
      "reason" => "protocolVersion must be an integer in 0..65535, got: #{inspect(requested)}"
    })
  end
end
