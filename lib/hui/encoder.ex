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

defimpl Hui.Encoder, for: Map do
  def encode(map, _opts), do: URI.encode_query(map)
end
