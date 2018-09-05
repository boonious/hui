defmodule Hui.Q do
  @moduledoc """
  Solr standard and common request parameters data structure and helper functions.

  These correspond to the default query parser known as the `lucene` parser for structured queries, 
  as well as the common parameters such as as sorting and pagination parameters (`rows`, `sort`, `start` etc). 
  
  See below for more details: 
   - [Standard Query parser](http://lucene.apache.org/solr/guide/7_4/the-standard-query-parser.html)
   - [Common request parameters](http://lucene.apache.org/solr/guide/7_4/common-query-parameters.html)
  
  """

  defstruct [:q, :"q.op", :df, :sow, :defType, :sort, :start, :rows, :fl,
             :debug, :debugQuery, :explainOther, :timeAllowed, :segmentTerminateEarly,
             :omitHeader, :wt, :cache, :logParamsList, :echoParams,
             :facet, fq: []]

  @type t :: %__MODULE__{q: binary, "q.op": binary, df: binary, sow: boolean,
                         defType: binary, sort: binary, start: number, rows: integer, fl: binary,
                         debug: binary, debugQuery: boolean, explainOther: binary, timeAllowed: number,
                         segmentTerminateEarly: boolean, omitHeader: boolean, wt: binary,
                         cache: boolean, omitHeader: binary, echoParams: binary, facet: Hui.F.t,
                         fq: binary | list(binary)}
end

defmodule Hui.F do
  @moduledoc """

  """

  defstruct [facet: true, field: [], query: []]
         ++ [:"pivot.mincount", pivot: []]
         ++ [:prefix, :contains, :"contains.ignoreCase", :matches]
         ++ [:sort, :limit, :offset, :mincount,
             :missing, :method, :"enum.cache.minDf", :exists]
         ++ [:excludeTerms, :"overrequest.count", :"overrequest.ratio",
             :threads]
         ++ [:interval, :range]

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

defmodule Hui.F.Range do

  defstruct [:range, :"range.start", :"range.end", :"range.gap"]
         ++ [:"range.hardend", :"range.include", :"range.other", :"range.method", per_field: false]
  @type t :: %__MODULE__{range: binary, "range.start": binary, "range.end": binary, "range.gap": binary,
                         "range.hardend": boolean, "range.include": binary, 
                         "range.other": binary, "range.method": binary,
                         per_field: boolean}

end

defmodule Hui.F.Interval do

  defstruct [:interval, "interval.set": [], per_field: false]
  @type t :: %__MODULE__{interval: binary, "interval.set": binary | list(binary), per_field: boolean}

end