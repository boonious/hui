defmodule Hui.Encode do
  @moduledoc """
  Utilities for encoding Solr query and update data structures.
  """

  alias Hui.Query

  @type solr_query :: Keyword.t | Query.Facet.t | Query.FacetRange.t | Query.FacetInterval.t

  @doc """
  Encodes list of Solr query keywords to IO data.
  """
  @spec encode(solr_query) :: iodata
  def encode(query) when is_list(query) do
    query
    |> Enum.reject(fn {k,v} -> is_nil(v) or v == "" or v == [] or k == :__struct__ end)
    |> _encode
  end

  # encode structs requiring facet and per field prefixes
  def encode(%Query.FacetInterval{} = query), do: encode(query, {"facet.interval", query.interval, query.per_field})
  def encode(%Query.FacetRange{} = query), do: encode(query, {"facet.range", query.range, query.per_field})
  def encode(%Query.Facet{} = query), do: encode(query, {"facet", "", false})

  def encode(query, info) when is_map(query) do
    query
    |> Map.to_list
    |> Enum.reject(fn {k,v} -> is_nil(v) or v == "" or v == [] or k == :__struct__ end)
    |> _transform(info)
    |> _encode
  end

  defp _encode([head|[]]), do: [_encode(head, "")]
  defp _encode([head|tail]), do: [_encode(head) | _encode(tail)]

  defp _encode(keyword, separator \\ "&")

  # do not render nil valued or empty keyword
  defp _encode({_,nil}, _), do: ""
  defp _encode([], _), do: ""

  # when value is a also struct, e.g. %Hui.Query.FacetRange/Interval{}
  defp _encode({_,v}, sep) when is_map(v), do: [ encode(v), sep ]

  # encodes fq: [x, y] type keyword to "fq=x&fq=y"
  defp _encode({k,v}, sep) when is_list(v), do: [ v |> Enum.map_join("&", &_encode( {k,&1}, "" ) ), sep ]
  defp _encode({k,v}, sep), do: [to_string(k), "=", URI.encode_www_form(to_string(v)), sep]

  # render keywords according to Solr prefix / per field syntax
  # e.g. transform `field: "year"` into `"facet.field": "year"`, `f.[field].facet.gap` etc.
  defp _transform([head|[]], info), do: [_transform(head, info)]
  defp _transform([head|tail], info), do: [_transform(head, info) | _transform(tail, info)]
  defp _transform({k,v}, {k_prefix, field, per_field}) do
    case {k, k_prefix, per_field} do
      {:facet, _, _} -> {:facet, v}
      {:range, "facet.range", _} -> {:"facet.range", v}
      {:interval, "facet.interval", _} -> {:"facet.interval", v}
      {:per_field, _, _} -> {k, nil} # set value to nil, do not render this field
      {_, _, true} -> {:"f.#{field}.#{k_prefix}.#{k}", v}
      {_, _, false} -> {:"#{k_prefix}.#{k}", v}
    end
  end

end