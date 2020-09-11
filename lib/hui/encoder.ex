alias Hui.Encode
alias Hui.Encode.Options
alias Hui.Query

defprotocol Hui.Encoder do
  @moduledoc """
  A protocol that underpins Solr query encoding.
  """

  @type options :: map
  @type query :: Hui.Query.solr_query()

  @doc """
  Encode various Solr query types - `t:Hui.Query.solr_query/0` into IO list or string.

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
    |> Encode.sanitise()
    |> Encode.encode()
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
    options = %Options{prefix: prefix}

    query
    |> Map.to_list()
    |> Encode.sanitise()
    |> Encode.encode(options)
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

    options = %Options{
      prefix: prefix,
      per_field: if(query.per_field, do: per_field_field, else: nil)
    }

    query
    |> Map.to_list()
    |> Encode.sanitise()
    |> Encode.encode(options)
  end
end

# TODO: implement iolist option
defimpl Hui.Encoder, for: Query.Update do
  @fields_sequence_config [
    doc: {"add", [:commitWithin, :overwrite, :doc]},
    delete_id: {"delete", [:delete_id]},
    delete_query: {"delete", [:delete_query]},
    commit: {"commit", [:expungeDeletes, :waitSearcher]},
    optimize: {"optimize", [:maxSegments, :waitSearcher]},
    rollback: {"rollback", []}
  ]

  def encode(query, _options) do
    json_fragments =
      for {field, config} <- @fields_sequence_config, Map.get(query, field) != nil do
        Map.get(query, field) |> encode(query, config)
      end
      |> List.flatten()

    "{#{Enum.join(json_fragments, ",")}}"
  end

  def encode(value, query, config) when is_list(value) do
    Enum.map(value, &encode(&1, query, config))
  end

  def encode(false, _query, _config), do: []

  def encode(value, query, {key, subfields}) do
    [?", key, ?", ?:, encode_json(value, query, subfields)] |> IO.iodata_to_binary()
  end

  defp encode_json(value, query, fields) do
    for f <- fields, Map.get(query, f) != nil do
      case f do
        :doc -> {:doc, value}
        :delete_id -> {:id, value}
        :delete_query -> {:query, value}
        _ -> {f, Map.get(query, f)}
      end
    end
    |> Encode.encode_json(%Options{type: :json})
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
    |> Encode.encode()
  end
end

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

  def encode([x | y]) when is_tuple(x), do: Encode.encode([x | y])
  def encode([]), do: ""
end
