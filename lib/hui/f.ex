defmodule Hui.F do
  @moduledoc """
  Struct and functions related to [faceting](http://lucene.apache.org/solr/guide/7_4/faceting.html).
  """

  defstruct [facet: true, field: [], query: []]
         ++ [:"pivot.mincount", pivot: []]
         ++ [:prefix, :contains, :"contains.ignoreCase", :matches]
         ++ [:sort, :limit, :offset, :mincount,
             :missing, :method, :"enum.cache.minDf", :exists]
         ++ [:excludeTerms, :"overrequest.count", :"overrequest.ratio",
             :threads]
         ++ [:interval, :range]

  @typedoc """
  Struct for faceting.

  `Hui.URL.encode_query/1` renders this struct into URL query string.

  ## Example

      iex> %Hui.F{field: ["type", "year"], query: "year:[2000 TO NOW]"}
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
        range: nil,
        sort: nil,
        threads: nil
      }
  """
  @type t :: %__MODULE__{facet: boolean, field: binary | list(binary), query: binary | list(binary),
                         "pivot.mincount": number, pivot: binary | list(binary),
                         prefix: binary, contains: binary, "contains.ignoreCase": binary, matches: binary,
                         sort: binary, limit: number, offset: number, mincount: number,
                         missing: boolean, method: binary, "enum.cache.minDf": number, exists: boolean,
                         excludeTerms: binary, "overrequest.count": number, "overrequest.ratio": number,
                         threads: binary,
                         interval: Hui.F.Interval.t | list(Hui.F.Range.t),
                         range: Hui.F.Range.t | list(Hui.F.Range.t)}

end