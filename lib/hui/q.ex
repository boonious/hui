defmodule Hui.Q do
  @moduledoc """
  Struct and functions related to standard and common request parameters.

  These correspond to the default query parser known as the `lucene` parser for structured queries,
  as well as the common parameters such as as sorting and pagination parameters (`rows`, `sort`, `start` etc).

  See below for more details: 
   - [Standard Query parser](http://lucene.apache.org/solr/guide/7_4/the-standard-query-parser.html)
   - [Common request parameters](http://lucene.apache.org/solr/guide/7_4/common-query-parameters.html)

  ### Example
      iex> %Hui.Q{q: "edinburgh", fl: "id,title", fq: ["type:image"], rows: 15}
      %Hui.Q{
        cache: nil,
        debug: nil,
        debugQuery: nil,
        defType: nil,
        df: nil,
        echoParams: nil,
        explainOther: nil,
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

  defstruct [:q, :"q.op", :df, :sow, :defType, :sort, :start, :rows, :fl,
             :debug, :debugQuery, :explainOther, :timeAllowed, :segmentTerminateEarly,
             :omitHeader, :wt, :cache, :logParamsList, :echoParams, fq: []]

  @typedoc """
  Struct for standard and common request parameters.

  `Hui.URL.encode_query/1` renders this struct into URL query string.
  """
  @type t :: %__MODULE__{q: binary, "q.op": binary, df: binary, sow: boolean,
                         defType: binary, sort: binary, start: number, rows: integer, fl: binary,
                         debug: binary, debugQuery: boolean, explainOther: binary, timeAllowed: number,
                         segmentTerminateEarly: boolean, omitHeader: boolean, wt: binary,
                         cache: boolean, omitHeader: binary, echoParams: binary,
                         fq: binary | list(binary)}

end