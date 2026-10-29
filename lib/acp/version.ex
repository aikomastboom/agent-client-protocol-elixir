defmodule ACP.ProtocolVersion do
  @moduledoc """
  Protocol version identifier. Only bumped for breaking changes.

  `latest/0` is the version this library offers when a connection does not
  negotiate explicitly. It stays at `v1` until v2 negotiation is actually
  implemented, so knowing about v2 does not silently change the default behavior
  of existing connections.
  """

  @type t :: non_neg_integer()

  @v0 0
  @v1 1
  @v2 2
  @latest @v1

  def v0, do: @v0
  def v1, do: @v1
  def v2, do: @v2
  def latest, do: @latest

  @doc "Deserialize from JSON value. Integers pass through, strings become v0."
  def from_json(value) when is_integer(value) and value >= 0, do: {:ok, value}
  def from_json(value) when is_binary(value), do: {:ok, @v0}
  def from_json(_), do: {:error, :invalid_protocol_version}
end
