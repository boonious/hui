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

  @typedoc """
    Query or facet struct.
  """
  @type query_struct :: t | Hui.F.t

  @doc """
  Encodes query (`t:t/0`) and facet (`t:Hui.F.t/0`) structs into a query string.

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

      iex> x = %Hui.F{field: ["year", "type"]}
      %Hui.F{
        contains: nil,
        "contains.ignoreCase": nil,
        "enum.cache.minDf": nil,
        excludeTerms: nil,
        exists: nil,
        facet: true,
        field: ["year", "type"],
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
        range: nil,
        sort: nil,
        threads: nil
      }
      iex> x |> Hui.Q.encode_query
      "facet=true&facet.field=year&facet.field=type"

  """
  @spec encode_query(query_struct) :: binary
  def encode_query(%__MODULE__{} = query_struct), do: Hui.URL.encode_query(query_struct |> Map.to_list)
  def encode_query(%Hui.F{} = query_struct), do: Hui.URL.encode_query(query_struct |> Map.to_list)
  def encode_query(_query_struct), do: ""

end