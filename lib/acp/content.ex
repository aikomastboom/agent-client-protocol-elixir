defmodule ACP.Role do
  @moduledoc "The sender or recipient of messages and data in a conversation."

  @type t :: :assistant | :user

  def encode(:assistant), do: "assistant"
  def encode(:user), do: "user"

  def decode("assistant"), do: :assistant
  def decode("user"), do: :user
end

defmodule ACP.Annotations do
  @moduledoc "Optional annotations for the client."

  @type t :: %__MODULE__{
          audience: [ACP.Role.t()] | nil,
          last_modified: String.t() | nil,
          priority: float() | nil,
          meta: map() | nil
        }

  defstruct [:audience, :last_modified, :priority, :meta]

  def new, do: %__MODULE__{}

  def to_json(%__MODULE__{} = a) do
    map = %{}

    map =
      if a.audience,
        do: Map.put(map, "audience", Enum.map(a.audience, &ACP.Role.encode/1)),
        else: map

    map = if a.last_modified, do: Map.put(map, "lastModified", a.last_modified), else: map
    map = if a.priority, do: Map.put(map, "priority", a.priority), else: map
    map = if a.meta, do: Map.put(map, "_meta", a.meta), else: map
    map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       audience:
         case Map.get(map, "audience") do
           nil -> nil
           list -> Enum.map(list, &ACP.Role.decode/1)
         end,
       last_modified: Map.get(map, "lastModified"),
       priority: Map.get(map, "priority"),
       meta: Map.get(map, "_meta")
     }}
  end
end

defmodule ACP.TextContent do
  @moduledoc "Text provided to or from an LLM."

  @type t :: %__MODULE__{
          annotations: ACP.Annotations.t() | nil,
          text: String.t(),
          meta: map() | nil
        }

  @enforce_keys [:text]
  defstruct [:annotations, :text, :meta]

  def new(text), do: %__MODULE__{text: text}

  def to_json(%__MODULE__{} = tc) do
    map = %{"text" => tc.text}

    map =
      if tc.annotations,
        do: Map.put(map, "annotations", ACP.Annotations.to_json(tc.annotations)),
        else: map

    if tc.meta, do: Map.put(map, "_meta", tc.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       text: Map.fetch!(map, "text"),
       annotations:
         case Map.get(map, "annotations") do
           nil ->
             nil

           a ->
             {:ok, ann} = ACP.Annotations.from_json(a)
             ann
         end,
       meta: Map.get(map, "_meta")
     }}
  end
end

defmodule ACP.ImageContent do
  @moduledoc "An image provided to or from an LLM."

  @type t :: %__MODULE__{
          annotations: ACP.Annotations.t() | nil,
          data: String.t(),
          mime_type: String.t(),
          uri: String.t() | nil,
          meta: map() | nil
        }

  @enforce_keys [:data, :mime_type]
  defstruct [:annotations, :data, :mime_type, :uri, :meta]

  def new(data, mime_type), do: %__MODULE__{data: data, mime_type: mime_type}

  def to_json(%__MODULE__{} = ic) do
    map = %{"data" => ic.data, "mimeType" => ic.mime_type}

    map =
      if ic.annotations,
        do: Map.put(map, "annotations", ACP.Annotations.to_json(ic.annotations)),
        else: map

    map = if ic.uri, do: Map.put(map, "uri", ic.uri), else: map
    if ic.meta, do: Map.put(map, "_meta", ic.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       data: Map.fetch!(map, "data"),
       mime_type: Map.fetch!(map, "mimeType"),
       annotations:
         case Map.get(map, "annotations") do
           nil ->
             nil

           a ->
             {:ok, ann} = ACP.Annotations.from_json(a)
             ann
         end,
       uri: Map.get(map, "uri"),
       meta: Map.get(map, "_meta")
     }}
  end
end

defmodule ACP.AudioContent do
  @moduledoc "Audio provided to or from an LLM."

  @type t :: %__MODULE__{
          annotations: ACP.Annotations.t() | nil,
          data: String.t(),
          mime_type: String.t(),
          meta: map() | nil
        }

  @enforce_keys [:data, :mime_type]
  defstruct [:annotations, :data, :mime_type, :meta]

  def new(data, mime_type), do: %__MODULE__{data: data, mime_type: mime_type}

  def to_json(%__MODULE__{} = ac) do
    map = %{"data" => ac.data, "mimeType" => ac.mime_type}

    map =
      if ac.annotations,
        do: Map.put(map, "annotations", ACP.Annotations.to_json(ac.annotations)),
        else: map

    if ac.meta, do: Map.put(map, "_meta", ac.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       data: Map.fetch!(map, "data"),
       mime_type: Map.fetch!(map, "mimeType"),
       annotations:
         case Map.get(map, "annotations") do
           nil ->
             nil

           a ->
             {:ok, ann} = ACP.Annotations.from_json(a)
             ann
         end,
       meta: Map.get(map, "_meta")
     }}
  end
end

defmodule ACP.TextResourceContents do
  @moduledoc "Text-based resource contents."

  @type t :: %__MODULE__{
          mime_type: String.t() | nil,
          text: String.t(),
          uri: String.t(),
          meta: map() | nil
        }

  @enforce_keys [:text, :uri]
  defstruct [:mime_type, :text, :uri, :meta]

  def new(text, uri), do: %__MODULE__{text: text, uri: uri}

  def to_json(%__MODULE__{} = trc) do
    map = %{"text" => trc.text, "uri" => trc.uri}
    map = if trc.mime_type, do: Map.put(map, "mimeType", trc.mime_type), else: map
    if trc.meta, do: Map.put(map, "_meta", trc.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       text: Map.fetch!(map, "text"),
       uri: Map.fetch!(map, "uri"),
       mime_type: Map.get(map, "mimeType"),
       meta: Map.get(map, "_meta")
     }}
  end
end

defmodule ACP.BlobResourceContents do
  @moduledoc "Binary resource contents."

  @type t :: %__MODULE__{
          blob: String.t(),
          mime_type: String.t() | nil,
          uri: String.t(),
          meta: map() | nil
        }

  @enforce_keys [:blob, :uri]
  defstruct [:blob, :mime_type, :uri, :meta]

  def new(blob, uri), do: %__MODULE__{blob: blob, uri: uri}

  def to_json(%__MODULE__{} = brc) do
    map = %{"blob" => brc.blob, "uri" => brc.uri}
    map = if brc.mime_type, do: Map.put(map, "mimeType", brc.mime_type), else: map
    if brc.meta, do: Map.put(map, "_meta", brc.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       blob: Map.fetch!(map, "blob"),
       uri: Map.fetch!(map, "uri"),
       mime_type: Map.get(map, "mimeType"),
       meta: Map.get(map, "_meta")
     }}
  end
end

defmodule ACP.EmbeddedResourceResource do
  @moduledoc "Resource content that can be embedded in a message (untagged union)."

  @type t :: ACP.TextResourceContents.t() | ACP.BlobResourceContents.t()

  def to_json(%ACP.TextResourceContents{} = trc), do: ACP.TextResourceContents.to_json(trc)
  def to_json(%ACP.BlobResourceContents{} = brc), do: ACP.BlobResourceContents.to_json(brc)

  def from_json(%{"text" => _} = map), do: ACP.TextResourceContents.from_json(map)
  def from_json(%{"blob" => _} = map), do: ACP.BlobResourceContents.from_json(map)
end

defmodule ACP.EmbeddedResource do
  @moduledoc "The contents of a resource, embedded into a prompt or tool call result."

  @type t :: %__MODULE__{
          annotations: ACP.Annotations.t() | nil,
          resource: ACP.EmbeddedResourceResource.t(),
          meta: map() | nil
        }

  @enforce_keys [:resource]
  defstruct [:annotations, :resource, :meta]

  def new(resource), do: %__MODULE__{resource: resource}

  def to_json(%__MODULE__{} = er) do
    map = %{"resource" => ACP.EmbeddedResourceResource.to_json(er.resource)}

    map =
      if er.annotations,
        do: Map.put(map, "annotations", ACP.Annotations.to_json(er.annotations)),
        else: map

    if er.meta, do: Map.put(map, "_meta", er.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok, resource} = ACP.EmbeddedResourceResource.from_json(Map.fetch!(map, "resource"))

    {:ok,
     %__MODULE__{
       resource: resource,
       annotations:
         case Map.get(map, "annotations") do
           nil ->
             nil

           a ->
             {:ok, ann} = ACP.Annotations.from_json(a)
             ann
         end,
       meta: Map.get(map, "_meta")
     }}
  end
end

defmodule ACP.ResourceLink do
  @moduledoc "A resource that the server is capable of reading."

  @type t :: %__MODULE__{
          annotations: ACP.Annotations.t() | nil,
          description: String.t() | nil,
          mime_type: String.t() | nil,
          name: String.t(),
          size: integer() | nil,
          title: String.t() | nil,
          uri: String.t(),
          meta: map() | nil
        }

  @enforce_keys [:name, :uri]
  defstruct [:annotations, :description, :mime_type, :name, :size, :title, :uri, :meta]

  def new(name, uri), do: %__MODULE__{name: name, uri: uri}

  def to_json(%__MODULE__{} = rl) do
    map = %{"name" => rl.name, "uri" => rl.uri}

    map =
      if rl.annotations,
        do: Map.put(map, "annotations", ACP.Annotations.to_json(rl.annotations)),
        else: map

    map = if rl.description, do: Map.put(map, "description", rl.description), else: map
    map = if rl.mime_type, do: Map.put(map, "mimeType", rl.mime_type), else: map
    map = if rl.size, do: Map.put(map, "size", rl.size), else: map
    map = if rl.title, do: Map.put(map, "title", rl.title), else: map
    if rl.meta, do: Map.put(map, "_meta", rl.meta), else: map
  end

  def from_json(map) when is_map(map) do
    {:ok,
     %__MODULE__{
       name: Map.fetch!(map, "name"),
       uri: Map.fetch!(map, "uri"),
       annotations:
         case Map.get(map, "annotations") do
           nil ->
             nil

           a ->
             {:ok, ann} = ACP.Annotations.from_json(a)
             ann
         end,
       description: Map.get(map, "description"),
       mime_type: Map.get(map, "mimeType"),
       size: Map.get(map, "size"),
       title: Map.get(map, "title"),
       meta: Map.get(map, "_meta")
     }}
  end
end

defmodule ACP.ContentBlock do
  @moduledoc "Content blocks represent displayable information in ACP."

  @type t ::
          {:text, ACP.TextContent.t()}
          | {:image, ACP.ImageContent.t()}
          | {:audio, ACP.AudioContent.t()}
          | {:resource_link, ACP.ResourceLink.t()}
          | {:resource, ACP.EmbeddedResource.t()}

  def text(text_content), do: {:text, text_content}
  def image(image_content), do: {:image, image_content}
  def audio(audio_content), do: {:audio, audio_content}
  def resource_link(rl), do: {:resource_link, rl}
  def resource(er), do: {:resource, er}

  @doc "Convenience: create a text content block from a string."
  def from_string(text), do: {:text, ACP.TextContent.new(text)}

  def to_json({:text, tc}), do: Map.put(ACP.TextContent.to_json(tc), "type", "text")
  def to_json({:image, ic}), do: Map.put(ACP.ImageContent.to_json(ic), "type", "image")
  def to_json({:audio, ac}), do: Map.put(ACP.AudioContent.to_json(ac), "type", "audio")

  def to_json({:resource_link, rl}),
    do: Map.put(ACP.ResourceLink.to_json(rl), "type", "resource_link")

  def to_json({:resource, er}), do: Map.put(ACP.EmbeddedResource.to_json(er), "type", "resource")

  def from_json(%{"type" => "text"} = map) do
    {:ok, tc} = ACP.TextContent.from_json(Map.delete(map, "type"))
    {:ok, {:text, tc}}
  end

  def from_json(%{"type" => "image"} = map) do
    {:ok, ic} = ACP.ImageContent.from_json(Map.delete(map, "type"))
    {:ok, {:image, ic}}
  end

  def from_json(%{"type" => "audio"} = map) do
    {:ok, ac} = ACP.AudioContent.from_json(Map.delete(map, "type"))
    {:ok, {:audio, ac}}
  end

  def from_json(%{"type" => "resource_link"} = map) do
    {:ok, rl} = ACP.ResourceLink.from_json(Map.delete(map, "type"))
    {:ok, {:resource_link, rl}}
  end

  def from_json(%{"type" => "resource"} = map) do
    {:ok, er} = ACP.EmbeddedResource.from_json(Map.delete(map, "type"))
    {:ok, {:resource, er}}
  end
end
