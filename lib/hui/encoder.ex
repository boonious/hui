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
      iex> alias Hui.Encoder

      iex> Encoder.encode(q: "loch", start: 10, rows: 10, fq: ["type:image", "year:[2001 TO 2007]"])
      "q=loch&start=10&rows=10&fq=type%3Aimage&fq=year%3A%5B2001+TO+2007%5D"

      iex> Encoder.encode(q: "loch", facet: true, "facet.field": ["type", "year"])
      "q=loch&facet=true&facet.field=type&facet.field=year"

  ## Example - encoding query structs
      iex> alias Hui.Query.{DisMax,Highlight}

      iex> %DisMax{q: "loch", qf: "description^2.3 title", mm: "2<-25% 9<-3"} |> Encoder.encode
      "mm=2%3C-25%25+9%3C-3&q=loch&qf=description%5E2.3+title"

      iex> %Highlight{fl: "title,words", usePhraseHighlighter: true, fragsize: 250} |> Encoder.encode
      "hl.fl=title%2Cwords&hl.fragsize=250&hl=true&hl.usePhraseHighlighter=true"

  See `Hui.Query.Facet`, `Hui.Query.FacetRange`, `Hui.Query.FacetInterval` for more examples.

  ## IO data encoding
  Hui provides an option that enables the built-in structs encoder to return either
  string (current default) or [IO list](https://hexdocs.pm/elixir/IO.html#module-io-data)
  which can be sent directly to IO functions or over the socket, to leverage Erlang runtime and
  some HTTP client features for lower memory usage and increased performance.

  * `:format` - controls how query structs are encoded. Possible values are: `:binary` and `:iolist`.

  The option should be provided via a Map:

      iex> alias Hui.Query.Update
      iex> %Update{delete_id: ["123", "456"]} |> Encoder.encode(%{format: :iolist})

  **Note**: forthcoming update of Hui Encoder protocol would provide `encode` and `encode_to_iodata`
  functions for String and IO data encoding respectively.
  """
  @spec encode(query, options) :: iodata
  def encode(query, options \\ %{format: :binary})
end

defimpl Hui.Encoder, for: [Query.Standard, Query.Common, Query.DisMax] do
  def encode(query, %{format: format}) do
    case format do
      :iolist -> encode(query)
      :binary -> encode(query) |> IO.iodata_to_binary()
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
      :binary -> encode(query) |> IO.iodata_to_binary()
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
      :binary -> encode(query) |> IO.iodata_to_binary()
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

defimpl Hui.Encoder, for: Query.Update do
  @fields_sequence_config [
    doc: {"add", [:commitWithin, :overwrite, :doc]},
    delete_id: {"delete", [:delete_id]},
    delete_query: {"delete", [:delete_query]},
    commit: {"commit", [:expungeDeletes, :waitSearcher]},
    optimize: {"optimize", [:maxSegments, :waitSearcher]},
    rollback: {"rollback", []}
  ]

  def encode(query, %{format: format}) do
    json_fragments =
      for {field, config} <- @fields_sequence_config, Map.get(query, field) != nil do
        encoded = Map.get(query, field) |> encode(query, config)

        cond do
          encoded == [] -> []
          is_list(hd(encoded)) -> encoded |> Enum.intersperse(?,)
          true -> encoded
        end
      end
      |> Enum.intersperse(?,)

    case format do
      :iolist -> [?{, json_fragments, ?}]
      :binary -> "{#{to_string(json_fragments)}}"
    end
  end

  def encode(value, query, config)

  def encode(false, _query, _config), do: []

  def encode(value, query, config) when is_list(value) do
    Enum.map(value, &encode(&1, query, config))
  end

  def encode(value, query, {key, subfields}) do
    [?", key, ?", ?:, encode_json(value, query, subfields)]
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
      :binary -> encode(query) |> IO.iodata_to_binary()
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
      :binary -> [x | y] |> Enum.map_join("&", &Hui.Encoder.encode(&1))
    end
  end

  # encode params in arbitrary keyword list
  def encode(query, %{format: format}) do
    case format do
      :iolist -> encode(query)
      :binary -> encode(query) |> IO.iodata_to_binary()
    end
  end

  def encode([x | y]) when is_tuple(x), do: Encode.encode([x | y])
  def encode([]), do: ""
end
