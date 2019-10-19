defmodule Hui.F do
  @moduledoc deprecated: """
  Please use Hui.Query.Facet instead.
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