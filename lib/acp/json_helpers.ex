defmodule ACP.JSONHelpers do
  @moduledoc "JSON serialization helpers for ACP types."

  @doc "Convert an atom or string from snake_case to camelCase."
  def to_camel_case(key) when is_atom(key), do: to_camel_case(Atom.to_string(key))

  def to_camel_case(key) when is_binary(key) do
    case String.split(key, "_") do
      [first | rest] -> first <> Enum.map_join(rest, &String.capitalize/1)
      _ -> key
    end
  end

  @doc "Convert a string from camelCase to snake_case."
  def to_snake_case(key) when is_binary(key) do
    key
    |> String.replace(~r/([A-Z])/, "_\\1")
    |> String.downcase()
    |> String.trim_leading("_")
  end

  @doc "Convert a map with snake_case atom keys to camelCase string keys, dropping nil values."
  def to_json_map(map, opts \\ []) when is_map(map) do
    rename = Keyword.get(opts, :rename, %{})

    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.reject(fn {_k, v} -> v == [] and not Keyword.get(opts, :keep_empty_lists, false) end)
    |> Enum.map(fn {k, v} ->
      json_key = Map.get(rename, k, to_camel_case(k))
      {json_key, v}
    end)
    |> Map.new()
  end

  @doc "Convert a map with camelCase string keys to a keyword list or map with snake_case atom keys."
  def from_json_map(map, opts \\ []) when is_map(map) do
    rename = Keyword.get(opts, :rename, %{})
    # Build reverse rename map: json_key -> atom_key
    reverse = Map.new(rename, fn {atom_key, json_key} -> {json_key, atom_key} end)

    map
    |> Enum.map(fn {k, v} ->
      atom_key = Map.get(reverse, k, String.to_atom(to_snake_case(k)))
      {atom_key, v}
    end)
    |> Map.new()
  end

  @doc "Encode a value to JSON, dropping nil fields from structs."
  def encode_struct(struct, fields, opts \\ []) do
    rename = Keyword.get(opts, :rename, %{})
    keep_empty = Keyword.get(opts, :keep_empty_lists, false)

    struct
    |> Map.take(fields)
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.reject(fn {_k, v} -> v == [] and not keep_empty end)
    |> Enum.map(fn {k, v} ->
      json_key = Map.get(rename, k, to_camel_case(k))
      {json_key, v}
    end)
    |> Map.new()
  end
end
