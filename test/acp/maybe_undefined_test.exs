defmodule ACP.MaybeUndefinedTest do
  use ExUnit.Case, async: true

  alias ACP.MaybeUndefined, as: MU

  # The three-state model itself is unchanged from v1: a field is either omitted
  # (`:undefined`), explicitly null (`nil`), or present (`{:value, term}`).
  describe "three-state model" do
    test "classifies each state" do
      assert MU.is_undefined(:undefined)
      refute MU.is_undefined(nil)
      refute MU.is_undefined({:value, 42})

      refute MU.is_null(:undefined)
      assert MU.is_null(nil)
      refute MU.is_null({:value, 42})

      refute MU.is_value(:undefined)
      refute MU.is_value(nil)
      assert MU.is_value({:value, 42})
    end

    test "round-trips through the nested-option representation" do
      assert MU.as_opt_ref(:undefined) == nil
      assert MU.as_opt_ref(nil) == {:some, nil}
      assert MU.as_opt_ref({:value, 1}) == {:some, 1}

      assert MU.from_opt(nil) == :undefined
      assert MU.from_opt({:some, nil}) == nil
      assert MU.from_opt({:some, 1}) == {:value, 1}
    end
  end

  # Whole-message upserts: "an omitted field leaves existing ... unchanged, `null`
  # clears the value, and a concrete array replaces the previous value."
  describe "update_to/2 (whole-replace patch)" do
    test "an omitted field leaves the current value unchanged" do
      assert MU.update_to(:undefined, "existing") == "existing"
      assert MU.update_to(:undefined, nil) == nil
    end

    test "an explicit null clears the value" do
      assert MU.update_to(nil, "existing") == nil
    end

    test "a concrete value replaces the current value whole" do
      assert MU.update_to({:value, [1, 2]}, [9, 9, 9]) == [1, 2]
      assert MU.update_to({:value, nil}, [9]) == nil
    end
  end

  # Metadata patches (protocol/v2/extensibility#metadata-patches). Applied one
  # top-level key at a time, with the same omit/null/value rule as other fields.
  describe "patch_map/2 (_meta metadata patch)" do
    @stored %{
      "com.example/progress" => 0.5,
      "org.example/review" => %{"state" => "pending"}
    }

    test "omitted _meta leaves the stored metadata unchanged" do
      assert MU.patch_map(:undefined, @stored) == @stored
    end

    test "omitted _meta also leaves nothing as nothing" do
      assert MU.patch_map(:undefined, nil) == nil
    end

    test "_meta null clears all stored metadata" do
      assert MU.patch_map(nil, @stored) == nil
    end

    test "_meta {} changes nothing" do
      assert MU.patch_map({:value, %{}}, @stored) == @stored
    end

    test "spec example: null removes a key, other values replace whole, new keys land" do
      patch = %{
        "com.example/progress" => nil,
        "org.example/review" => %{"reviewer" => "sam"},
        "net.example/route" => "edge"
      }

      assert MU.patch_map({:value, patch}, @stored) == %{
               "org.example/review" => %{"reviewer" => "sam"},
               "net.example/route" => "edge"
             }
    end

    test "keys the patch omits keep their stored values" do
      assert MU.patch_map({:value, %{"b" => 2}}, %{"a" => 1, "b" => 0}) == %{"a" => 1, "b" => 2}
    end

    test "nested objects are never merged" do
      assert MU.patch_map({:value, %{"k" => %{"b" => 2}}}, %{"k" => %{"a" => 1}}) ==
               %{"k" => %{"b" => 2}}
    end

    test "a null nested inside a value is ordinary data, not a removal" do
      assert MU.patch_map({:value, %{"k" => %{"inner" => nil}}}, %{"k" => "old"}) ==
               %{"k" => %{"inner" => nil}}
    end

    test "removing a key that is not stored does nothing" do
      assert MU.patch_map({:value, %{"absent" => nil}}, %{"a" => 1}) == %{"a" => 1}
      assert MU.patch_map({:value, %{"absent" => nil}}, nil) == nil
    end

    test "patching onto no stored metadata starts from an empty map" do
      assert MU.patch_map({:value, %{"a" => 1}}, nil) == %{"a" => 1}
    end

    test "stored metadata with no keys is the same as no metadata" do
      assert MU.patch_map({:value, %{"a" => nil}}, %{"a" => 1}) == nil
    end

    test "a non-object _meta value is treated as omitted" do
      assert MU.patch_map({:value, "nope"}, @stored) == @stored
      assert MU.patch_map({:value, [1, 2]}, @stored) == @stored
      assert MU.patch_map({:value, 7}, nil) == nil
    end
  end

  # Chunks append to the content accumulated for a message; an upsert replaces it
  # whole. Same three states, different application rule.
  describe "append_to/2 (chunk semantics)" do
    test "an omitted chunk leaves content unchanged" do
      assert MU.append_to(:undefined, ["a"]) == ["a"]
    end

    test "omitted chunk against no content is no content" do
      assert MU.append_to(:undefined, nil) == []
    end

    test "null clears the content" do
      assert MU.append_to(nil, ["a"]) == []
    end

    test "a value appends to the current content" do
      assert MU.append_to({:value, ["b", "c"]}, ["a"]) == ["a", "b", "c"]
    end

    test "an empty append leaves content unchanged" do
      assert MU.append_to({:value, []}, ["a"]) == ["a"]
    end
  end

  describe "to_json/1 and from_json/1" do
    test "to_json signals omission" do
      assert MU.to_json(:undefined) == {:skip}
      assert MU.to_json(nil) == nil
      assert MU.to_json({:value, 5}) == 5
    end

    test "from_json distinguishes a missing key from an explicit null" do
      assert MU.from_json(:missing) == :undefined
      assert MU.from_json(nil) == nil
      assert MU.from_json(5) == {:value, 5}
    end
  end

  # v2 requires strict typing on some optional fields: "_meta is an object with
  # string keys. Receivers treat any other value as omitted." A malformed value
  # must not become a value that later replaces stored data.
  describe "from_json/2 with a validator" do
    test "a conforming value decodes as a value" do
      assert MU.from_json(%{"a" => 1}, &is_map/1) == {:value, %{"a" => 1}}
    end

    test "a non-conforming value decodes as undefined" do
      assert MU.from_json("nope", &is_map/1) == :undefined
      assert MU.from_json([1], &is_map/1) == :undefined
      assert MU.from_json(7, &is_map/1) == :undefined
    end

    test "a missing key decodes as undefined regardless of the validator" do
      assert MU.from_json(:missing, &is_map/1) == :undefined
    end

    test "an explicit null decodes as null regardless of the validator" do
      assert MU.from_json(nil, &is_map/1) == nil
    end

    test "a validator can reject an item list" do
      list_of_strings = fn v -> is_list(v) and Enum.all?(v, &is_binary/1) end

      assert MU.from_json(["a"], list_of_strings) == {:value, ["a"]}
      assert MU.from_json([1, 2], list_of_strings) == :undefined
    end
  end

  describe "round trip: decode then apply" do
    test "a malformed _meta cannot clear stored metadata" do
      stored = @stored
      meta = MU.from_json("accidental string", &is_map/1)
      assert MU.patch_map(meta, stored) == stored
    end

    test "an explicit _meta null clears stored metadata" do
      meta = MU.from_json(nil, &is_map/1)
      assert MU.patch_map(meta, @stored) == nil
    end
  end
end
