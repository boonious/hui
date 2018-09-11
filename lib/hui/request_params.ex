defmodule Hui.Q do
  @moduledoc """
  Struct and functions related to standard and common request parameters.

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

  @typedoc """
  Use this struct to specify standard and common request parameters.

  ## Example
      iex> %Hui.Q{q: "edinburgh", fl: "id,title", fq: ["type:image"], rows: 15}
      %Hui.Q{
        cache: nil,
        debug: nil,
        debugQuery: nil,
        defType: nil,
        df: nil,
        echoParams: nil,
        explainOther: nil,
        facet: nil,
        fl: "id,title",
        fq: ["type:image"],
        logParamsList: nil,
        omitHeader: nil,
        q: "edinburgh",
        "q.op": nil,
        rows: 15,
        segmentTerminateEarly: nil,
        sort: nil,
        sow: nil,
        start: nil,
        timeAllowed: nil,
        wt: nil
      }
  """
  @type t :: %__MODULE__{q: binary, "q.op": binary, df: binary, sow: boolean,
                         defType: binary, sort: binary, start: number, rows: integer, fl: binary,
                         debug: binary, debugQuery: boolean, explainOther: binary, timeAllowed: number,
                         segmentTerminateEarly: boolean, omitHeader: boolean, wt: binary,
                         cache: boolean, omitHeader: binary, echoParams: binary, facet: Hui.F.t,
                         fq: binary | list(binary)}

  @doc """
  Encodes `t:Hui.Q.t/0`, `t:Hui.F.t/0` structs into a query string.

  ## Example
      iex> x = %Hui.Q{q: "edinburgh", fl: "id,title", fq: ["type:image"], rows: 15}
      %Hui.Q{
        cache: nil,
        debug: nil,
        debugQuery: nil,
        defType: nil,
        df: nil,
        echoParams: nil,
        explainOther: nil,
        facet: nil,
        fl: "id,title",
        fq: ["type:image"],
        logParamsList: nil,
        omitHeader: nil,
        q: "edinburgh",
        "q.op": nil,
        rows: 15,
        segmentTerminateEarly: nil,
        sort: nil,
        sow: nil,
        start: nil,
        timeAllowed: nil,
        wt: nil
      }
      iex> x |> Hui.Q.encode_query
      "fl=id%2Ctitle&fq=type%3Aimage&q=edinburgh&rows=15"

  """
  def encode_query(query_struct) when is_map(query_struct), do: Hui.URL.encode_query(query_struct |> Map.to_list)

end

defmodule Hui.F do
  @moduledoc """
  Struct and functions related to faceting parameters.

  See [Solr faceting](http://lucene.apache.org/solr/guide/7_4/faceting.html).
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
  Use this struct to specify faceting parameters.

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

defmodule Hui.F.Range do
  @moduledoc """
  Struct and functions related to range faceting parameters.

  See [Solr range faceting](http://lucene.apache.org/solr/guide/7_4/faceting.html#range-faceting).
  """

  defstruct [:range, :"range.start", :"range.end", :"range.gap"]
         ++ [:"range.hardend", :"range.include", :"range.other", :"range.method", per_field: false]

  @typedoc """
  Use this struct to specify range faceting parameters in conjunction with
  the main `t:Hui.F.t/0` struct.

  ## Example
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
      iex> %Hui.F{range: x, field: ["type", "year"], query: "year:[2000 TO NOW]"}
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
  """
  @type t :: %__MODULE__{range: binary, "range.start": binary, "range.end": binary, "range.gap": binary,
                         "range.hardend": boolean, "range.include": binary,
                         "range.other": binary, "range.method": binary,
                         per_field: boolean}

end

defmodule Hui.F.Interval do
  @moduledoc """
  Struct and functions related to interval faceting parameters.

  See [Solr interval faceting](http://lucene.apache.org/solr/guide/7_4/faceting.html#interval-faceting).
  """
  defstruct [:interval, "interval.set": [], per_field: false]

  @typedoc """
  Use this struct to specify interval faceting parameters in conjunction with
  the main `t:Hui.F.t/0` struct.

  ## Example
      iex> x = %Hui.F.Interval{interval: "price", "interval.set": ["[0,10]", "(10,100]"]}
      %Hui.F.Interval{
        interval: "price",
        "interval.set": ["[0,10]", "(10,100]"],
        per_field: false
      }
      iex> %Hui.F{interval: x, field: ["type", "year"]}
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
  """
  @type t :: %__MODULE__{interval: binary, "interval.set": binary | list(binary), per_field: boolean}

end