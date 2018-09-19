defmodule Hui.Q do
  @moduledoc """
  Struct and functions related to the standard query parser and common request parameters.

  Correspond to the default standard query parser known as the `lucene` parser,
  and common parameters such as `rows`, `sort`, `start` etc.

  See below for more details: 
   - [Standard Query parser](http://lucene.apache.org/solr/guide/7_4/the-standard-query-parser.html)
   - [Common request parameters](http://lucene.apache.org/solr/guide/7_4/common-query-parameters.html)

  """
  defstruct [:q, :"q.op", :df, :sow, # standard parser
             :defType, :sort, :start, :rows, :fl,
             :debug, :debugQuery, :explainOther, :timeAllowed, :segmentTerminateEarly,
             :omitHeader, :wt, :cache, :logParamsList, :echoParams,
             :"json.nl", :"json.wrf", :tr, fq: []]

  @typedoc """
  Struct for the standard query
  and common request parameters.

  `Hui.URL.encode_query/1` renders this struct into URL query string.
  """
  @type t :: %__MODULE__{q: binary, "q.op": binary, df: binary, sow: boolean,
                         defType: binary, sort: binary, start: number, rows: integer, fl: binary,
                         debug: binary, debugQuery: boolean, explainOther: binary, timeAllowed: number,
                         segmentTerminateEarly: boolean, omitHeader: boolean, wt: binary,
                         cache: boolean, omitHeader: binary, echoParams: binary,
                         "json.nl": binary, "json.wrf": binary, tr: binary,
                         fq: binary | list(binary)}

end