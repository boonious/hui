alias Hui.Query
alias Hui.Encode

defprotocol Hui.Encoder do
  @moduledoc """
  A protocol that underpins Solr query encoding.
  """

  @type options :: keyword
  @type solr_struct :: Query.Standard.t | Query.Common.t
  @type query :: map | solr_struct

  @doc """
  Transform `query` into IO data.

  The argument `opts` can be used to control encoding, e.g. specifying output formats.
  """
  @spec encode(query, options) :: iodata
  def encode(query, opts \\ [])

end

defimpl Hui.Encoder, for: [Query.Standard, Query.Common] do
  def encode(query, _opts), do: Encode.encode( query|> Map.to_list ) |> IO.iodata_to_binary
end

defimpl Hui.Encoder, for: Map do
  def encode(query, _opts), do: URI.encode_query(query)
end

defimpl Hui.Encoder, for: List do
  # encode a list of map or structs
  def encode([x|y], _opts) when is_map(x) do
    [x|y] |> Enum.map_join("&", &Hui.Encoder.encode(&1))
  end

  # encode params in arbitrary keyword list
  def encode([x|y], _opts) when is_tuple(x) do
    URI.encode_query([x|y])
  end
end