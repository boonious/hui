defmodule Hui.Query.Facet do
  @moduledoc """
  Struct related to [faceting](http://lucene.apache.org/solr/guide/faceting.html).

  ### Example
      iex> x = %Hui.Query.Facet{field: ["type", "year"], query: "year:[2000 TO NOW]"}
      %Hui.Query.Facet{
        contains: nil,
        "contains.ignoreCase": nil,
        "enum.cache.minDf": nil,
        excludeTerms: nil,
        exists: nil,
        facet: true,
        field: ["type", "year"],
        interval: nil,
        limit: nil,
        matches: nil,
        method: nil,
        mincount: nil,
        missing: nil,
        offset: nil,
        "overrequest.count": nil,
        "overrequest.ratio": nil,
        pivot: nil,
        "pivot.mincount": nil,
        prefix: nil,
        query: "year:[2000 TO NOW]",
        range: nil,
        sort: nil,
        threads: nil
      }
      iex> x |> Hui.Encoder.encode
      "facet=true&facet.field=type&facet.field=year&facet.query=year%3A%5B2000+TO+NOW%5D"

  """
  defstruct [
    :contains,
    :"contains.ignoreCase",
    :"enum.cache.minDf",
    :excludeTerms,
    :exists,
    :field,
    :interval,
    :limit,
    :matches,
    :method,
    :mincount,
    :missing,
    :offset,
    :"overrequest.count",
    :"overrequest.ratio",
    :pivot,
    :"pivot.mincount",
    :prefix,
    :query,
    :range,
    :sort,
    :threads,
    facet: true
  ]

  @typedoc """
  Struct for faceting.
  """
  @type t :: %__MODULE__{
          contains: binary,
          "contains.ignoreCase": binary,
          "enum.cache.minDf": number,
          excludeTerms: binary,
          exists: boolean,
          facet: boolean,
          field: binary | list(binary),
          interval: Hui.Query.FacetInterval.t() | list(Hui.Query.FacetInterval.t()),
          limit: number,
          matches: binary,
          method: :enum | :fc | :fcs,
          mincount: number,
          missing: boolean,
          offset: number,
          "overrequest.count": number,
          "overrequest.ratio": number,
          pivot: binary | list(binary),
          "pivot.mincount": number,
          prefix: binary,
          query: binary | list(binary),
          range: Hui.Query.FacetRange.t() | list(Hui.Query.FacetRange.t()),
          sort: :count | :index,
          threads: number
        }

  @spec new(binary | list(binary), binary | list(binary)) :: t
  def new(field, query \\ nil), do: %__MODULE__{field: field, query: query}

  @spec new :: t
  def new(), do: %__MODULE__{}
end
