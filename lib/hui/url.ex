defmodule Hui.URL do
  @moduledoc """
  Struct and utilities for working with Solr URLs and parameters.

  Use the `%Hui.URL{url: url, handler: handler}` struct to specify
  Solr URLs and request handlers.

  """

  defstruct [:url, :handler ]
  @type t :: %__MODULE__{url: nil | binary, handler: nil | binary}

  @doc """
  Encodes list (keywords) of Solr parameters into a query string.

  Some Solr parameters such as the filter query `fq`, `facet.field` can be set multiple times.
  These can be specified in a list (e.g. `fq: [filter1, filter]`). Dot-notated
  parameters (facet.field, hl.fl) can be specified with string keys, 
  e.g. `"facet.field": "type"`, `"hl.fl": "words"`.

  ## Example

      iex> Hui.URL.encode_query(q: "loch", start: 10, rows: 10)
      "q=loch&start=10&rows=10"

      iex> Hui.URL.encode_query(q: "loch", fq: ["type:image", "year:[2001 TO 2007]"])
      "q=loch&fq=type%3Aimage&fq=year%3A%5B2001+TO+2007%5D"

      iex> Hui.URL.encode_query(q: "loch", facet: true, "facet.field": ["type", "year"])
      "q=loch&facet=true&facet.field=type&facet.field=year"

      iex> Hui.URL.encode_query("not a valid parameter")
      ""

  """
  @spec encode_query(term) :: binary
  def encode_query(enumerable) when is_list(enumerable), do: Enum.map_join(enumerable, "&", &encode/1)
  def encode_query(_), do: ""

  @doc "Returns the default select path of a Solr core / collection from the given `Hui.URL` struct."
  @spec select_path(t) :: binary
  def select_path(%__MODULE__{url: url, handler: _handler}), do: "#{url}/select"

  @doc "Returns the default update path of a Solr core / collection from the given `Hui.URL` struct."
  @spec update_path(t) :: binary
  def update_path(%__MODULE__{url: url, handler: _handler}), do: "#{url}/update"

  @doc "Returns the string representation of the given `Hui.URL` struct."
  @spec to_string(t) :: binary
  def to_string(%__MODULE__{url: url, handler: handler}), do: "#{url}/#{handler}"

  defp encode({k,v}) when is_list(v), do: Enum.map_join(v, "&", &encode({k,&1}))
  defp encode({k,v}) when is_binary(v), do: "#{k}=#{URI.encode_www_form(v)}"
  defp encode({k,v}), do: "#{k}=#{v}"
  defp encode(v), do: v
  defp encode([]), do: ""

end
