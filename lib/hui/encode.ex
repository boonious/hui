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
    |> Enum.reject(fn {_,v} -> is_nil(v) or v == "" end)
    |> _encode
  end

  defp _encode([head|[]]), do: [_encode(head, "")]
  defp _encode([head|tail]), do: [_encode(head) | _encode(tail)]

  defp _encode({k,v}, separator \\ "&"), do: [to_string(k), "=", URI.encode_www_form(to_string(v)), separator]

end