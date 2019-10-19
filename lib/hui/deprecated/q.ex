defmodule Hui.Q do
  @moduledoc deprecated: """
  Please use `Hui.Query.Standard` and `Hui.Query.Common` instead.
  """
  defstruct [:q, :"q.op", :df, :sow, # standard parser
             :defType, :sort, :start, :rows, :fl,
             :debug, :debugQuery, :explainOther, :timeAllowed, :segmentTerminateEarly,
             :omitHeader, :wt, :cache, :logParamsList, :echoParams,
             :"json.nl", :"json.wrf", :tr, :collection, :distrib,
             :shards, :"shards.info", :"shards.preference", :"shards.tolerant",
             :cursorMark, fq: []]

  @typedoc """
  Struct for the standard query and common request parameters.
  """
  @type t :: %__MODULE__{q: binary, "q.op": binary, df: binary, sow: boolean,
                         defType: binary, sort: binary, start: number, rows: integer, fl: binary,
                         debug: binary, debugQuery: boolean, explainOther: binary, timeAllowed: number,
                         segmentTerminateEarly: boolean, omitHeader: boolean, wt: binary,
                         cache: boolean, logParamsList: binary, omitHeader: binary, echoParams: binary,
                         "json.nl": binary, "json.wrf": binary, tr: binary,
                         collection: binary, distrib: boolean, shards: binary,
                         "shards.info": boolean, "shards.preference": binary, "shards.tolerant": boolean,
                         cursorMark: binary, fq: binary | list(binary)}

end