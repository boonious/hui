defmodule Hui.Query.FacetRange do
  @moduledoc """
  Struct related to [range faceting](http://lucene.apache.org/solr/guide/faceting.html#range-faceting) query.

  ### Example

      iex> x = %Hui.Query.FacetRange{range: "year", gap: "+10YEARS", start: 1700, end: 1799}
      %Hui.Query.FacetRange{
        end: 1799,
        gap: "+10YEARS",
        hardend: nil,
        include: nil,
        method: nil,
        other: nil,
        per_field: false,
        range: "year",
        start: 1700
      }
      iex> y = %Hui.Query.Facet{range: x, field: ["type", "year"], query: "year:[2000 TO NOW]"}
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
        range: %Hui.Query.FacetRange{
          end: 1799,
          gap: "+10YEARS",
          hardend: nil,
          include: nil,
          method: nil,
          other: nil,
          per_field: false,
          range: "year",
          start: 1700
        },
        sort: nil,
        threads: nil
      }
      iex> y |> Hui.Encoder.encode # render struct into URL query string with `facet` prefixes
      "facet=true&facet.field=type&facet.field=year&facet.query=year%3A%5B2000+TO+NOW%5D&facet.range.end=1799&facet.range.gap=%2B10YEARS&facet.range=year&facet.range.start=1700"

  ### Example - per field ranges, f.[fieldname].facet.range

      iex> x = %Hui.Query.FacetRange{range: "year", gap: "+10YEARS", start: 1700, end: 1799, per_field: true}
      %Hui.Query.FacetRange{
        end: 1799,
        gap: "+10YEARS",
        hardend: nil,
        include: nil,
        method: nil,
        other: nil,
        per_field: true,
        range: "year",
        start: 1700
      }
      iex> x |> Hui.Encoder.encode
      "f.year.facet.range.end=1799&f.year.facet.range.gap=%2B10YEARS&facet.range=year&f.year.facet.range.start=1700"
      # another range
      iex> y = %Hui.Query.FacetRange{range: "price", gap: "10", start: 0, end: 100, per_field: true} 
      %Hui.Query.FacetRange{
        end: 100,
        gap: "10",
        hardend: nil,
        include: nil,
        method: nil,
        other: nil,
        per_field: true,
        range: "price",
        start: 0
      }
      iex> z = %Hui.Query.Facet{field: "type", range: [x, y]} # field and multiple ranges faceting
      %Hui.Query.Facet{
        contains: nil,
        "contains.ignoreCase": nil,
        "enum.cache.minDf": nil,
        excludeTerms: nil,
        exists: nil,
        facet: true,
        field: "type",
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
        query: nil,
        range: [
          %Hui.Query.FacetRange{
            end: 1799,
            gap: "+10YEARS",
            hardend: nil,
            include: nil,
            method: nil,
            other: nil,
            per_field: true,
            range: "year",
            start: 1700
          },
          %Hui.Query.FacetRange{
            end: 100,
            gap: "10",
            hardend: nil,
            include: nil,
            method: nil,
            other: nil,
            per_field: true,
            range: "price",
            start: 0
          }
        ],
        sort: nil,
        threads: nil
      }
      iex> z |> Hui.Encoder.encode
      "facet=true&facet.field=type&f.year.facet.range.end=1799&f.year.facet.range.gap=%2B10YEARS&facet.range=year&f.year.facet.range.start=1700&f.price.facet.range.end=100&f.price.facet.range.gap=10&facet.range=price&f.price.facet.range.start=0"

  """
  defstruct [
    :end,
    :gap,
    :hardend,
    :include,
    :method,
    :other,
    :range,
    :start,
    per_field: false
  ]

  @typedoc """
  Struct for range faceting parameters, use in conjunction with
  the faceting struct -`t:Hui.Query.Facet.t/0`.
  """
  @type t :: %__MODULE__{
          end: binary,
          gap: binary,
          hardend: boolean,
          include: :lower | :upper | :edge | :outer | :all,
          method: :filter | :dv,
          other: :before | :after | :between | :none | :all,
          per_field: boolean,
          range: binary,
          start: binary
        }
end
