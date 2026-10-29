defmodule ACP.MaybeUndefined do
  @moduledoc """
  A three-state value type: `:undefined`, `nil` (null), or `{:value, term}`.

  Similar to `Option<T>`, but distinguishes between a missing field (undefined)
  and an explicitly null field. This is important for partial update semantics
  where omitting a field means "don't change" and setting it to null means "clear".

  ## JSON Serialization

  - `:undefined` → field is omitted from JSON output
  - `nil` → `null`
  - `{:value, x}` → the JSON encoding of `x`

  ## Examples

      iex> ACP.MaybeUndefined.is_undefined(:undefined)
      true

      iex> ACP.MaybeUndefined.is_undefined(nil)
      false

      iex> ACP.MaybeUndefined.is_undefined({:value, "hello"})
      false
  """

  @type t(value) :: :undefined | nil | {:value, value}

  @doc "Returns true if the value is undefined."
  def is_undefined(:undefined), do: true
  def is_undefined(_), do: false

  @doc "Returns true if the value is null."
  def is_null(nil), do: true
  def is_null(_), do: false

  @doc "Returns true if the value contains a value."
  def is_value({:value, _}), do: true
  def is_value(_), do: false

  @doc "Returns the inner value, or nil if undefined or null."
  def value({:value, v}), do: v
  def value(_), do: nil

  @doc "Converts to `Option<Option<T>>` equivalent: nil | {:some, nil} | {:some, value}."
  def as_opt_ref(:undefined), do: nil
  def as_opt_ref(nil), do: {:some, nil}
  def as_opt_ref({:value, v}), do: {:some, v}

  @doc "Converts from a nested option back to MaybeUndefined."
  def from_opt(nil), do: :undefined
  def from_opt({:some, nil}), do: nil
  def from_opt({:some, v}), do: {:value, v}

  @doc "Maps a function over the value, preserving undefined/null."
  def map_value(:undefined, _fun), do: :undefined
  def map_value(nil, _fun), do: nil
  def map_value({:value, v}, fun), do: {:value, fun.(v)}

  @doc """
  Updates a target value if the MaybeUndefined is not undefined.

  - `:undefined` → returns the current value unchanged
  - `nil` → returns nil (clear)
  - `{:value, v}` → returns v (set)
  """
  def update_to(:undefined, current), do: current
  def update_to(nil, _current), do: nil
  def update_to({:value, v}, _current), do: v

  @doc """
  Encodes a MaybeUndefined value for JSON serialization.
  Returns `{:skip}` for undefined (caller should omit the field),
  `nil` for null, or the value itself.
  """
  def to_json(:undefined), do: {:skip}
  def to_json(nil), do: nil
  def to_json({:value, v}), do: v

  @doc """
  Decodes a MaybeUndefined value from JSON deserialization.
  Call with `:missing` if the key was not present, or the value if it was.
  """
  def from_json(:missing), do: :undefined
  def from_json(nil), do: nil
  def from_json(v), do: {:value, v}

  @doc """
  Decodes a field that must additionally conform to a shape validator.

  v2 requires strict typing on some optional fields: a `_meta` that is not an
  object, for example, must be treated as omitted rather than as a value.
  A non-conforming value therefore decodes to `:undefined`, which keeps it from
  replacing or clearing stored data downstream. A missing key and an explicit
  `null` keep their usual meaning and ignore the validator.
  """
  @spec from_json(term(), (term() -> boolean())) :: t(term())
  def from_json(:missing, _validator), do: :undefined
  def from_json(nil, _validator), do: nil

  def from_json(value, validator) do
    if validator.(value), do: {:value, value}, else: :undefined
  end

  @doc """
  Applies a `_meta` metadata patch to stored metadata.

  This is the v2 Metadata Patches rule
  (https://agentclientprotocol.com/protocol/v2/extensibility#metadata-patches),
  used by upsert updates: `tool_call_update`, `terminal_update`, `user_message`,
  `agent_message`, `agent_thought`, `session_info_update`, and
  `compaction_update`. Patches act on one top-level key at a time:

  - `:undefined` (omitted) leaves the stored metadata unchanged
  - `nil` clears all stored metadata
  - `{:value, map}` patches the stored metadata:
      - keys the patch omits keep their stored values, so `%{}` changes nothing
      - a key set to `nil` is removed; removing an unstored key does nothing
      - any other value replaces that key's stored value whole; nested objects
        are never merged, and a `nil` nested inside a value is ordinary data

  A non-map value is treated as omitted, per the rule that receivers treat any
  non-object `_meta` as absent. Stored metadata left with no keys is returned as
  `nil`, since metadata with no keys is the same as no metadata.
  """
  @spec patch_map(t(term()), map() | nil) :: map() | nil
  def patch_map(:undefined, stored), do: stored
  def patch_map(nil, _stored), do: nil
  def patch_map({:value, patch}, stored) when not is_map(patch), do: stored

  def patch_map({:value, patch}, stored) do
    stored = stored || %{}

    patched =
      Enum.reduce(patch, stored, fn
        {key, nil}, acc -> Map.delete(acc, key)
        {key, value}, acc -> Map.put(acc, key, value)
      end)

    if patched == %{}, do: nil, else: patched
  end

  @doc """
  Applies chunk semantics: content accumulates instead of being replaced.

  Chunks carrying the same `messageId` append to the content already accumulated
  for that message. Contrast with `update_to/2`, which models whole-replace
  upsert fields such as a message upsert's `content`.

  - `:undefined` (omitted) leaves the current content unchanged
  - `nil` clears it
  - `{:value, items}` appends `items` to the current content
  """
  @spec append_to(t([term()]), [term()] | nil) :: [term()]
  def append_to(:undefined, current), do: List.wrap(current)
  def append_to(nil, _current), do: []
  def append_to({:value, items}, current), do: List.wrap(current) ++ List.wrap(items)
end
