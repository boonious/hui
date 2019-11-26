alias Hui.Query
alias Hui.Encode

defprotocol Hui.Encoder do
  @moduledoc """
  A protocol that underpins Solr query encoding.
  """

  @type options :: keyword
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
  def encode(query, opts \\ [])
end

defimpl Hui.Encoder, for: [Query.Standard, Query.Common, Query.DisMax] do
  def encode(query, _opts) do
    query
    |> Map.to_list()
    |> Encode.encode()
    |> IO.iodata_to_binary()
  end
end

# for structs without per-field encoding requirement
defimpl Hui.Encoder, for: [Query.Facet, Query.MoreLikeThis, Query.SpellCheck, Query.Suggest] do
  def encode(query, _opts) do
    {prefix, _} = Hui.URLPrefixField.prefix_field()[query.__struct__]
    options = %Encode.Options{prefix: prefix}

    query
    |> Encode.transform(options)
    |> Encode.encode(options)
    |> IO.iodata_to_binary()
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
  def encode(query, _opts) do
    {prefix, field_key} = Hui.URLPrefixField.prefix_field()[query.__struct__]
    per_field_field = query |> Map.get(field_key)

    options = %Encode.Options{
      prefix: prefix,
      per_field: if(query.per_field, do: per_field_field, else: nil)
    }

    query
    |> Encode.transform(options)
    |> Encode.encode(options)
    |> IO.iodata_to_binary()
  end
end

# TODO:
# - refactoring and move codes to Encode.encode utility module
# - use IO data (binary list) instead of string interoperation during encoding
defimpl Hui.Encoder, for: Query.Update do
  def encode(q, _opts) do
    a = "#{_encode(doc: q.doc, within: q.commitWithin, overwrite: q.overwrite)}"
    b = "#{_encode(delete_id: q.delete_id)}"
    c = "#{_encode(delete_query: q.delete_query)}"
    d = "#{_encode(commit: q.commit, wait: q.waitSearcher, expunge: q.expungeDeletes)}"
    e = "#{_encode(optimize: q.optimize, wait: q.waitSearcher, max: q.maxSegments)}"
    f = "#{_encode(rollback: q.rollback)}"

    x = [a, b, c, d, e, f] |> Enum.filter(fn x -> x != "" end)
    "{#{Enum.join(x, ",")}}"
  end

  defp _encode(doc) when is_map(doc), do: Poison.encode!(doc)

  defp _encode(doc: doc, within: w, overwrite: o) when is_map(doc),
    do: "\"add\":{#{_encode(within: w)}#{_encode(overwrite: o)}\"doc\":#{_encode(doc)}}"

  defp _encode(doc: [h | t], within: w, overwrite: o) when is_map(h),
    do: Enum.map_join([h] ++ t, ",", &_encode(doc: &1, within: w, overwrite: o))

  defp _encode(doc: _, within: _, overwrite: _), do: ""

  defp _encode(within: w) when is_integer(w), do: "\"commitWithin\":#{w},"
  defp _encode(within: _), do: ""

  defp _encode(overwrite: o) when is_boolean(o), do: "\"overwrite\":#{o},"
  defp _encode(overwrite: _), do: ""

  defp _encode(commit: true, wait: w, expunge: e) when is_boolean(w) and is_boolean(e),
    do: "\"commit\":{\"waitSearcher\":#{w},\"expungeDeletes\":#{e}}"

  defp _encode(commit: true, wait: w, expunge: nil) when is_boolean(w),
    do: "\"commit\":{\"waitSearcher\":#{w}}"

  defp _encode(commit: true, wait: nil, expunge: e) when is_boolean(e),
    do: "\"commit\":{\"expungeDeletes\":#{e}}"

  defp _encode(commit: true, wait: nil, expunge: nil), do: "\"commit\":{}"
  defp _encode(commit: _, wait: _, expunge: _), do: ""

  defp _encode(optimize: true, wait: w, max: m) when is_boolean(w) and is_integer(m),
    do: "\"optimize\":{\"waitSearcher\":#{w},\"maxSegments\":#{m}}"

  defp _encode(optimize: true, wait: w, max: nil) when is_boolean(w),
    do: "\"optimize\":{\"waitSearcher\":#{w}}"

  defp _encode(optimize: true, wait: nil, max: m) when is_integer(m),
    do: "\"optimize\":{\"maxSegments\":#{m}}"

  defp _encode(optimize: true, wait: nil, max: nil), do: "\"optimize\":{}"
  defp _encode(optimize: _, wait: _, max: _), do: ""

  defp _encode(delete_id: id) when is_binary(id), do: "\"delete\":{\"id\":\"#{id}\"}"

  defp _encode(delete_id: id) when is_list(id),
    do: Enum.map_join(id, ",", &_encode(delete_id: &1))

  defp _encode(delete_id: _), do: ""

  defp _encode(delete_query: q) when is_binary(q), do: "\"delete\":{\"query\":\"#{q}\"}"

  defp _encode(delete_query: q) when is_list(q),
    do: Enum.map_join(q, ",", &_encode(delete_query: &1))

  defp _encode(delete_query: _), do: ""

  defp _encode(rollback: true), do: "\"rollback\":{}"
  defp _encode(rollback: _), do: ""
end

# general map data struct encoding
defimpl Hui.Encoder, for: Map do
  def encode(query, _opts) do
    query
    |> Map.to_list()
    |> Encode.encode()
    |> IO.iodata_to_binary()
  end
end

defimpl Hui.Encoder, for: List do
  # encode a list of map or structs
  def encode([x | y], _opts) when is_map(x) do
    [x | y] |> Enum.map_join("&", &Hui.Encoder.encode(&1))
  end

  # encode params in arbitrary keyword list
  def encode([x | y], _opts) when is_tuple(x) do
    Encode.encode([x | y]) |> IO.iodata_to_binary()
  end

  def encode([], _opts), do: ""
end
