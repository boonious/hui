alias Hui.Query
alias Hui.Encode
alias Hui.Encode.Options

alias Hui.EncodeNew

defprotocol Hui.Encoder do
  @moduledoc """
  A protocol that underpins Solr query encoding.
  """

  @type options :: map
  @type query :: Hui.Query.solr_query()

  @doc """
  Transform various Solr query types - `t:Hui.Query.solr_query/0` into string.

  The argument `opts` will be used to specify encoding format
  (not used currently).

  ## Example - encoding keyword list

      iex> Hui.Encoder.encode(q: "loch", start: 10, rows: 10, fq: ["type:image", "year:[2001 TO 2007]"])
      "q=loch&start=10&rows=10&fq=type%3Aimage&fq=year%3A%5B2001+TO+2007%5D"

      iex> Hui.Encoder.encode(q: "loch", facet: true, "facet.field": ["type", "year"])
      "q=loch&facet=true&facet.field=type&facet.field=year"

  ## Example - encoding query structs

      iex> %Hui.Query.DisMax{q: "loch", qf: "description^2.3 title", mm: "2<-25% 9<-3"} |> Hui.Encoder.encode
      "mm=2%3C-25%25+9%3C-3&q=loch&qf=description%5E2.3+title"

      iex> %Hui.Query.Highlight{fl: "title,words", usePhraseHighlighter: true, fragsize: 250} |> Hui.Encoder.encode
      "hl.fl=title%2Cwords&hl.fragsize=250&hl=true&hl.usePhraseHighlighter=true"

  See `Hui.Query.Facet`, `Hui.Query.FacetRange`, `Hui.Query.FacetInterval` for more examples.
  """
  @spec encode(query, options) :: iodata
  def encode(query, options \\ %{format: :binary})
end

defimpl Hui.Encoder, for: [Query.Standard, Query.Common, Query.DisMax] do
  def encode(query, %{format: format}) do
    case format do
      :iolist -> encode(query)
      _ -> encode(query) |> IO.iodata_to_binary()
    end
  end

  def encode(query) do
    query
    |> Map.to_list()
    |> EncodeNew.sanitise()
    |> EncodeNew.encode()
  end
end

# for structs without per-field encoding requirement
defimpl Hui.Encoder, for: [Query.Facet, Query.MoreLikeThis, Query.SpellCheck, Query.Suggest] do
  def encode(query, %{format: format}) do
    case format do
      :iolist -> encode(query)
      _ -> encode(query) |> IO.iodata_to_binary()
    end
  end

  def encode(query) do
    {prefix, _} = Hui.URLPrefixField.prefix_field()[query.__struct__]
    options = %Encode.Options{prefix: prefix}

    query
    |> Map.to_list()
    |> EncodeNew.sanitise()
    |> EncodeNew.encode(options)
  end
end

# for structs with per-field encoding requirement
defimpl Hui.Encoder,
  for: [
    Query.FacetRange,
    Query.FacetInterval,
    Query.Highlight,
    Query.HighlighterUnified,
    Query.HighlighterOriginal,
    Query.HighlighterFastVector
  ] do
  def encode(query, %{format: format}) do
    case format do
      :iolist -> encode(query)
      _ -> encode(query) |> IO.iodata_to_binary()
    end
  end

  def encode(query) do
    {prefix, field_key} = Hui.URLPrefixField.prefix_field()[query.__struct__]
    per_field_field = query |> Map.get(field_key)

    options = %Encode.Options{
      prefix: prefix,
      per_field: if(query.per_field, do: per_field_field, else: nil)
    }

    query
    |> Map.to_list()
    |> EncodeNew.sanitise()
    |> EncodeNew.encode(options)
  end
end

# TODO: implement iolist option
defimpl Hui.Encoder, for: Query.Update do
  def encode(query, _options) do
    # TODO: rename :format option, :content_type
    opts = %Options{format: :json}
    transforms = Encode.transform(query, opts)

    json_fragments =
      for t <- transforms do
        t
        |> Encode.encode(opts)
        |> IO.iodata_to_binary()
      end

    "{#{Enum.join(json_fragments, ",")}}"
  end
end

defimpl Hui.Encoder, for: Map do
  def encode(query, %{format: format}) do
    case format do
      :iolist -> encode(query)
      _ -> encode(query) |> IO.iodata_to_binary()
    end
  end

  def encode(query) do
    query
    |> Map.to_list()
    |> EncodeNew.encode()
  end
end

# TODO: implement iolist option
defimpl Hui.Encoder, for: List do
  # encode a list of map or structs
  def encode([x | y], %{format: format}) when is_map(x) do
    case format do
      :iolist -> [x | y] |> Enum.map(&Hui.Encoder.encode(&1))
      _ -> [x | y] |> Enum.map_join("&", &Hui.Encoder.encode(&1))
    end
  end

  # encode params in arbitrary keyword list
  def encode(query, %{format: format}) do
    case format do
      :iolist -> encode(query)
      _ -> encode(query) |> IO.iodata_to_binary()
    end
  end

  def encode([x | y]) when is_tuple(x), do: EncodeNew.encode([x | y])
  def encode([]), do: ""
end
