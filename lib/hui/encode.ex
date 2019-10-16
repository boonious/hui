defmodule Hui.Encode do
  @moduledoc """
  Utilities for encoding Solr query and update data structures.
  """

  @doc """
  Encodes list of Solr query keywords to IO data.
  """
  @spec encode(list(keyword)) :: iodata
  def encode(query) when is_list(query) do
    query
    |> Enum.reject(fn {k,v} -> is_nil(v) or v == "" or v == [] or k == :__struct__ end)
    |> _encode
  end

  defp _encode([head|[]]), do: [_encode(head, "")]
  defp _encode([head|tail]), do: [_encode(head) | _encode(tail)]

  defp _encode(keyword, separator \\ "&")

  # encodes fq: [x, y] type keyword to "fq=x&fq=y"
  defp _encode({k,v}, sep) when is_list(v), do: [ v |> Enum.map_join("&", &_encode( {k,&1}, "" ) ), sep ]

  defp _encode({k,v}, sep), do: [to_string(k), "=", URI.encode_www_form(to_string(v)), sep]
  defp _encode([], _), do: ""

end