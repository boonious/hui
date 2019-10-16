alias Hui.Query
alias Hui.Encode

defprotocol Hui.Encoder do
  @moduledoc """
  A protocol that underpins Solr query encoding.
  """

  @type options :: keyword
  @type query :: map

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

defimpl Hui.Encoder, for: [Map, List] do
  def encode(query, _opts), do: URI.encode_query(query)
end
