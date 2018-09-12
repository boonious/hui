defmodule Hui.F.Interval do
  @moduledoc """
  Struct and functions related to 
  [interval faceting](http://lucene.apache.org/solr/guide/7_4/faceting.html#interval-faceting)
  parameters.

  ### Example
      iex> x = %Hui.F.Interval{interval: "price", "interval.set": ["[0,10]", "(10,100]"]}
      %Hui.F.Interval{
        interval: "price",
        "interval.set": ["[0,10]", "(10,100]"],
        per_field: false
      }
      iex> y = %Hui.F{interval: x, field: ["type", "year"]}
      %Hui.F{
        contains: nil,
        "contains.ignoreCase": nil,
        "enum.cache.minDf": nil,
        excludeTerms: nil,
        exists: nil,
        facet: true,
        field: ["type", "year"],
        interval: %Hui.F.Interval{
          interval: "price",
          "interval.set": ["[0,10]", "(10,100]"],
          per_field: false
        },
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
        range: nil,
        sort: nil,
        threads: nil
      }
      iex> y |> Hui.Q.encode_query # render struct into URL query string with `facet` prefixes
      "facet=true&facet.field=type&facet.field=year&facet.interval=price&facet.interval.set=%5B0%2C10%5D&facet.interval.set=%2810%2C100%5D"
  """
  defstruct [:interval, "interval.set": [], per_field: false]

  @typedoc """
  Use this struct to specify interval faceting parameters in conjunction with
  the main `t:Hui.F.t/0` struct.

  See `Hui.Q.encode_query/1` for rendering the struct into URL query string.
  """
  @type t :: %__MODULE__{interval: binary, "interval.set": binary | list(binary), per_field: boolean}

end