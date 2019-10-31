alias Hui.Query
alias Hui.Encode

defprotocol Hui.Encoder do
  @moduledoc """
  A protocol that underpins Solr query encoding.
  """

  @type options :: keyword
  @type query :: Hui.Query.solr_query()

  @doc """
  Transform `query` into IO data.

  The argument `opts` can be used to control encoding, e.g. specifying output formats.
  """
  @spec encode(query, options) :: iodata
  def encode(query, opts \\ [])
end

defimpl Hui.Encoder, for: [Query.Standard, Query.Common, Query.DisMax] do
  def encode(query, _opts), do: Encode.encode(query |> Map.to_list()) |> IO.iodata_to_binary()
end

# for structs without per-field encoding requirement
defimpl Hui.Encoder, for: [Query.Facet, Query.MoreLikeThis, Query.SpellCheck, Query.Suggest] do
  def encode(query, _opts) do
    {prefix, _} = Hui.URLPrefixField.prefix_field()[query.__struct__]
    options = %Encode.Options{prefix: prefix}

    Encode.encode(query, options) |> IO.iodata_to_binary()
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

    Encode.encode(query, options) |> IO.iodata_to_binary()
  end
end

# general map data struct encoding
defimpl Hui.Encoder, for: Map do
  def encode(query, _opts), do: Encode.encode(query) |> IO.iodata_to_binary()
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
