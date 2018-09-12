defmodule Hui.F.Range do
  @moduledoc """
  Struct and functions related to [range faceting](http://lucene.apache.org/solr/guide/7_4/faceting.html#range-faceting) parameters.

  ### Example

      iex> x = %Hui.F.Range{range: "year", gap: "+10YEARS", start: 1700, end: 1799}
      %Hui.F.Range{
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
      iex> y = %Hui.F{range: x, field: ["type", "year"], query: "year:[2000 TO NOW]"}
      %Hui.F{
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
        pivot: [],
        "pivot.mincount": nil,
        prefix: nil,
        query: "year:[2000 TO NOW]",
        range: %Hui.F.Range{
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
      iex> y |> Hui.URL.encode_query # render struct into URL query string with `facet` prefixes
      "facet=true&facet.field=type&facet.field=year&facet.query=year%3A%5B2000+TO+NOW%5D&facet.range.end=1799&facet.range.gap=%2B10YEARS&facet.range=year&facet.range.start=1700"

  ### Example - per field ranges, f.[fieldname].facet.range

      iex> x = %Hui.F.Range{range: "year", gap: "+10YEARS", start: 1700, end: 1799, per_field: true}
      %Hui.F.Range{
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
      iex> x |> Hui.URL.encode_query
      "f.year.facet.range.end=1799&f.year.facet.range.gap=%2B10YEARS&facet.range=year&f.year.facet.range.start=1700"
      # another range
      iex> y = %Hui.F.Range{range: "price", gap: "10", start: 0, end: 100, per_field: true} 
      %Hui.F.Range{
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
      iex> z = %Hui.F{field: "type", range: [x, y]} # field and multiple ranges faceting
      %Hui.F{
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
        pivot: [],
        "pivot.mincount": nil,
        prefix: nil,
        query: [],
        range: [
          %Hui.F.Range{
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
          %Hui.F.Range{
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
      iex> z |> Hui.URL.encode_query
      "facet=true&facet.field=type&f.year.facet.range.end=1799&f.year.facet.range.gap=%2B10YEARS&facet.range=year&f.year.facet.range.start=1700&f.price.facet.range.end=100&f.price.facet.range.gap=10&facet.range=price&f.price.facet.range.start=0"

  """
  defstruct [:range, :start, :end, :gap]
         ++ [:hardend, :include, :other, :method, per_field: false]

  @typedoc """
  Struct for range faceting parameters, use in conjunction with
  the main faceting `t:Hui.F.t/0` struct (range).

  `Hui.URL.encode_query/1` renders this struct into URL query string.
  """
  @type t :: %__MODULE__{range: binary, start: binary, end: binary, gap: binary,
                         hardend: boolean, include: binary,
                         other: binary, method: binary,
                         per_field: boolean}

end