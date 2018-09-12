defmodule Hui.F.Range do
  @moduledoc """
  Struct and functions related to [range faceting](http://lucene.apache.org/solr/guide/7_4/faceting.html#range-faceting) parameters.

  ### Example
      iex> x = %Hui.F.Range{range: "year", "range.gap": "+10YEARS", "range.start": 1700, "range.end": 1799}
      %Hui.F.Range{
        per_field: false,
        range: "year",
        "range.end": 1799,
        "range.gap": "+10YEARS",
        "range.hardend": nil,
        "range.include": nil,
        "range.method": nil,
        "range.other": nil,
        "range.start": 1700
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
          per_field: false,
          range: "year",
          "range.end": 1799,
          "range.gap": "+10YEARS",
          "range.hardend": nil,
          "range.include": nil,
          "range.method": nil,
          "range.other": nil,
          "range.start": 1700
        },
        sort: nil,
        threads: nil
      }
      iex> y |> Hui.URL.encode_query # render struct into URL query string with `facet` prefixes
      "facet=true&facet.field=type&facet.field=year&facet.query=year%3A%5B2000+TO+NOW%5D&facet.range=year&facet.range.end=1799&facet.range.gap=%2B10YEARS&facet.range.start=1700"
  """
  defstruct [:range, :"range.start", :"range.end", :"range.gap"]
         ++ [:"range.hardend", :"range.include", :"range.other", :"range.method", per_field: false]

  @typedoc """
  Struct for range faceting parameters, use in conjunction with
  the main faceting `t:Hui.F.t/0` struct (range).

  `Hui.URL.encode_query/1` renders this struct into URL query string.
  """
  @type t :: %__MODULE__{range: binary, "range.start": binary, "range.end": binary, "range.gap": binary,
                         "range.hardend": boolean, "range.include": binary,
                         "range.other": binary, "range.method": binary,
                         per_field: boolean}

end