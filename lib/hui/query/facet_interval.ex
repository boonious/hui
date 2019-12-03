defmodule Hui.Query.FacetInterval do
  @moduledoc """
  Struct related to [interval faceting](http://lucene.apache.org/solr/guide/faceting.html#interval-faceting) query.

  ### Example

      iex> x = %Hui.Query.FacetInterval{interval: "price", set: ["[0,10]", "(10,100]"]}
      %Hui.Query.FacetInterval{
        interval: "price",
        set: ["[0,10]", "(10,100]"],
        per_field: false
      }
      iex> y = %Hui.Query.Facet{interval: x, field: ["type", "year"]}
      %Hui.Query.Facet{
        contains: nil,
        "contains.ignoreCase": nil,
        "enum.cache.minDf": nil,
        excludeTerms: nil,
        exists: nil,
        facet: true,
        field: ["type", "year"],
        interval: %Hui.Query.FacetInterval{
          interval: "price",
          set: ["[0,10]", "(10,100]"],
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
        pivot: nil,
        "pivot.mincount": nil,
        prefix: nil,
        query: nil,
        range: nil,
        sort: nil,
        threads: nil
      }
      iex> y |> Hui.Encoder.encode # render struct into URL query string with `facet` prefixes
      "facet=true&facet.field=type&facet.field=year&facet.interval=price&facet.interval.set=%5B0%2C10%5D&facet.interval.set=%2810%2C100%5D"

  ### Example - per field intervals, f.[fieldname].facet.interval

      iex> x = %Hui.Query.FacetInterval{interval: "price", set: ["[0,10]", "(10,100]"], per_field: true}
      %Hui.Query.FacetInterval{
        interval: "price",
        set: ["[0,10]", "(10,100]"],
        per_field: true
      }
      iex> y = %Hui.Query.Facet{field: "type", interval: x}
      %Hui.Query.Facet{
        contains: nil,
        "contains.ignoreCase": nil,
        "enum.cache.minDf": nil,
        excludeTerms: nil,
        exists: nil,
        facet: true,
        field: "type",
        interval: %Hui.Query.FacetInterval{
          interval: "price",
          set: ["[0,10]", "(10,100]"],
          per_field: true
        },
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
        range: nil,
        sort: nil,
        threads: nil
      }
      iex> y |> Hui.Encoder.encode
      "facet=true&facet.field=type&facet.interval=price&f.price.facet.interval.set=%5B0%2C10%5D&f.price.facet.interval.set=%2810%2C100%5D"

  """

  defstruct [:interval, set: [], per_field: false]

  @typedoc """
  Struct for interval faceting parameters, use in conjunction with
  the faceting struct - `t:Hui.Query.Facet.t/0`.
  """
  @type t :: %__MODULE__{interval: binary, set: binary | list(binary), per_field: boolean}

  @spec new :: t
  def new(), do: %__MODULE__{}
end
